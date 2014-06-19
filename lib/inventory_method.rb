class InventoryMethod
   attr_accessor :inventory_item, :inventory_transaction, :method_params
   
   def initialize(values)
     set_method_params(values)#DONE
     
     log_transaction#DONE
     execute #DONE 
     log_status #DONE
   end
   
   def execute
   end
   
  private
   def set_method_params(values_hash)
      
    required_params = ["inventory_type_code","object_id","current_location_code","owner_party_role_id","owner_party_code","inventory_quantity","transaction_type_code","transaction_sub_type_code"]

    for  required_param in required_params
       if values_hash[required_param] == nil
         raise " Construction error : parameter '" + required_param + "' is missing"
       end
     end
   
     @method_params = values_hash
   end
    
  private
   def log_transaction
    begin
     @inventory_transaction = InventoryTransaction.new
   #  @inventory_transaction.location_id = Location.find_by_location_code(@method_params["current_location_code"]).id #???????????????
     @inventory_transaction.transaction_sub_type_id = TransactionSubType.find_by_transaction_sub_type_code(@method_params["transaction_sub_type_code"]).id
     @inventory_transaction.transaction_date_time = Time.now
     @inventory_transaction.location_from = @method_params["location_from"]
     @inventory_transaction.location_to = @method_params["location_to"]
     @inventory_transaction.transaction_quantity_plus = @method_params["quantity_plus"].to_i
     @inventory_transaction.transaction_quantity_minus = @method_params["quantity_minus"].to_i 
     @inventory_transaction.reference_number_id = @method_params["transaction_reference_id"]
     @inventory_transaction.route_step_id = RouteStep.find_by_route_step_code(@method_params["route_step_code"]).id if @method_params["route_step_code"] != nil 
     @inventory_transaction.object_id = @method_params["object_id"]
    
     @inventory_transaction.save
    rescue
     raise "inventory transaction could not be created"
    end
   
   end
   
  private
   def log_status 
     if @method_params["inventory_status"] != nil && @method_params["inventory_status"] != @inventory_item.inventory_status_code
      begin
       @inventory_item.update_attribute('inventory_status_code',@method_params["inventory_status"])
      rescue
        raise "inventory_status could not be logged"
      end
     end
   end
   
end