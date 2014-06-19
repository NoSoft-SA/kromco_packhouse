class CreateItem < InventoryMethod
 
  def execute
   begin
    @inventory_item = InventoryItem.new
    @inventory_item.inventory_type_id = InventoryType.find_by_inventory_type_code(self.method_params["inventory_type_code"]).id
    @inventory_item.lot_id = self.method_params["lot_id"].to_i
    @inventory_item.party_role_id = self.method_params["owner_party_role_id"]
    @inventory_item.current_location = self.method_params["current_location_code"]
    @inventory_item.date_created = Time.now
    @inventory_item.inventory_status_code = self.method_params["inventory_status"]
    @inventory_item.inventory_transaction_id = self.inventory_transaction.id
    @inventory_item.inventory_type_code = self.method_params["inventory_type_code"]
    @inventory_item.owner_party_code = self.method_params["owner_party_code"]
    @inventory_item.object_id = self.method_params["object_id"]
    @inventory_item.inventory_quantity = self.method_params["inventory_quantity"]
    
     @inventory_item.save
    rescue
     raise "inventory item could not be created"
    end
  end
  
end