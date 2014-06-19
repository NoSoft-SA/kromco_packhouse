require "lib/globals.rb"
require "lib/inventory.rb"
require "lib/extensions.rb"
require "lib/model_helper.rb"
require "lib/masterfile_validator"

include Inventory

time_interval = (!ARGV[0]) ? 5 : ARGV[0].to_i

config = YAML.load(File.read('config/database.yml'))['production']
ActiveRecord::Base.establish_connection({:adapter => config['adapter'],
        :host => config['host'],
        :database => config['database'],
        :username => config['username'],
        :password => config['password'],
        :port => config['port']})

raise"invalid run mode: #{ARGV[1]}" if(ARGV[1] &&(ARGV[1]!='true' && ARGV[1]!='false'))

run_continuously = (ARGV[1]=='true') ? true : false
line_break_formatting = !run_continuously ? '<br>' : nil

while (true)
  asset_move_requests_reprocess = AssetMoveRequest.find(:all,:conditions=>"process_attempts > 0")
  asset_move_requests_reprocess.each do |mv_asset_req|
    begin
      ActiveRecord::Base.transaction do
        asset_item = AssetItem.find_by_asset_number(mv_asset_req.pack_material_product_code)
        inventory_transaction = InventoryTransaction.new({:transaction_type_code => mv_asset_req.transaction_type_code,:transaction_type_id => mv_asset_req.transaction_type_id,
                                                          :location_from => mv_asset_req.location_from,:location_to => mv_asset_req.location_to,:transaction_quantity_plus => 1,
                                                          :transaction_business_name_code => mv_asset_req.transaction_business_name_code, :transaction_business_name_id => mv_asset_req.transaction_business_name_id,
                                                          :transaction_date_time => Time.now.to_formatted_s(:db), :reference_number => mv_asset_req.inventory_reference,
                                                          :parent_inventory_transaction_id => mv_asset_req.parent_inventory_transaction_id,:is_stock_asset_move=>true})

        MoveAssetClass.new(asset_item, inventory_transaction).process

        processed_mv_asset_req = ProcessedAssetMoveRequest.new()
        mv_asset_req.export_attributes(processed_mv_asset_req, true)
        processed_mv_asset_req.save!

        mv_asset_req.destroy
      end
    rescue
      err_entry = RailsError.new
      err_entry.description = $!.message
      err_entry.stack_trace = $!.backtrace.join("\n").to_s if $!
      err_entry.logged_on_user = 'move_asset'
      err_entry.error_type = 'move_asset'
      err_entry.create
      mv_asset_req.update_attributes({:process_attempts=>mv_asset_req.process_attempts+1,:rails_error_id=>err_entry.id})

      puts "#{(!run_continuously ? "<label style='color: red;font-weight: bold;'/>" : nil)}MOVE ASSET REPROCESS FAILED#{(!run_continuously ? "</label>" : nil)} for bin[ #{(!run_continuously ? "<label style='font-weight: bold;'/>" : nil)}#{mv_asset_req.reference_number}#{(!run_continuously ? "</label>" : nil)} ] (Error_id=#{err_entry.id})#{line_break_formatting}"
    end
  end

  break if(!run_continuously)
  sleep(time_interval.minutes)
end

ActiveRecord::Base.connection.disconnect!()
ActiveRecord::Base.remove_connection



