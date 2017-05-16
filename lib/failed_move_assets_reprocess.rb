require "lib/globals.rb"
require "lib/inventory.rb"
require "lib/extensions.rb"
require "lib/model_helper.rb"
require "lib/masterfile_validator"

include Inventory

time_interval = (!ARGV[2]) ? 5 : ARGV[2].to_i

raise"invalid run mode: #{ARGV[3]}" if(ARGV[3] &&(ARGV[3]!='true' && ARGV[3]!='false'))

run_continuously = (ARGV[3]=='true') ? true : false
line_break_formatting = !run_continuously ? '<br>' : nil

puts "ARGV[3] = #{ARGV[3]}"
puts "running script continuously? #{run_continuously}"
puts("Script initiated[#{Time.now}]")

while (true)
  asset_move_requests_reprocess = AssetMoveRequest.find(:all,:conditions=>"process_attempts > 0")
  puts("Processing #{asset_move_requests_reprocess.size} records[#{Time.now}]")
  asset_move_requests_reprocess.each do |mv_asset_req|
    begin
      ActiveRecord::Base.transaction do
        asset_item = AssetItem.find_by_asset_number(mv_asset_req.pack_material_product_code)
        inventory_transaction = InventoryTransaction.new({:transaction_type_code => mv_asset_req.transaction_type_code,:transaction_type_id => mv_asset_req.transaction_type_id,
                                                          :location_from => mv_asset_req.location_from,:location_to => mv_asset_req.location_to,
                                                          :transaction_business_name_code => mv_asset_req.transaction_business_name_code, :transaction_business_name_id => mv_asset_req.transaction_business_name_id,
                                                          :transaction_date_time => Time.now.to_formatted_s(:db), :reference_number => mv_asset_req.reference_number,
                                                          :parent_inventory_transaction_id => mv_asset_req.parent_inventory_transaction_id,:is_stock_asset_move=>true,

                                                          :transaction_quantity_plus => (mv_asset_req.transaction_quantity_plus ? mv_asset_req.transaction_quantity_plus : 1),
                                                          :truck_licence_number => mv_asset_req.truck_licence_number,:comments => mv_asset_req.comments})

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

  puts
  break if(!run_continuously)
  sleep(time_interval.minutes)
end
puts("Script terminated[#{Time.now}]")