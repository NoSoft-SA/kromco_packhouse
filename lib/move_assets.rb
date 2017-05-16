require "lib/globals.rb"
require "lib/inventory.rb"
require "lib/extensions.rb"
require "lib/model_helper.rb"
require "lib/masterfile_validator"

include Inventory

time_interval = (!ARGV[2]) ? 5 : ARGV[2].to_i

while (true)
  asset_move_requests = AssetMoveRequest.find(:all,:conditions=>"process_attempts=0")
  asset_move_requests.each do |mv_asset_req|
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
    end
  end

  sleep(time_interval.minutes)
end
