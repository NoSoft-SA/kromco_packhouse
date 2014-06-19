class InventoryTransactionStock < ActiveRecord::Base

  #	===========================
# 	Association declarations:
#	===========================
 
 
	#belongs_to :route_step
#	belongs_to :transaction_type
#	#belongs_to :serialised_container
	belongs_to :location
#	belongs_to :transaction_business_name
#	belongs_to :inventory_receipt
#	belongs_to :inventory_issue
    belongs_to :stock_item
 
#	============================
#	 Validations declarations:
#	============================
    #validates_presence_of :transaction_type_code
    #validates_presence_of :transaction_business_name_code
#    validates_presence_of :inventory_transaction_id
#    validates_presence_of :stock_item_id
#	validates_presence_of :location_id
#	validates_presence_of :location_code
#	validates_presence_of :transaction_type_code
#	validates_presence_of :transaction_business_name
#	validates_numericality_of :transaction_quantity_plus
#	validates_numericality_of :transaction_quantity_minus
#	validates_presence_of :reference_number
	#validates_numericality_of :object_id
	
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:serialised_container_code => self.serialised_container_code}],self) 
#	 end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_serialised_container
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:route_step_code => self.route_step_code}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_route_step
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:transaction_type_code => self.transaction_type_code}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_transaction_type
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:location_code => self.location_code}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_location
#	 end
#	 
#	 if is_valid
#	   is_valid = ModelHelper::Validations.validate_combos([{:transaction_business_name_code => self.transaction_business_name_code}],self) 
#	 end
#	 if is_valid
#	   is_valid = set_transaction_business_name
#	 end
#	 
#	 if is_valid
#	   is_valid = ModelHelper::Validations.validate_combos([{:inventory_receipt_code => self.inventory_receipt_code}],self) 
#	 end
#	 if is_valid
#	   is_valid = set_inventory_receipt
#	 end
#	 
#	 if is_valid
#	   is_valid = ModelHelper::Validations.validate_combos([{:inventory_issue_code => self.inventory_issue_code}],self)
#	 end
#	 if is_valid
#	   is_valid = set_inventory_issue
#	 end
end

#	===========================
#	 foreign key validations:
#	===========================
#def set_route_step
#
#	route_step = RouteStep.find_by_route_step_code(self.route_step_code)
#	 if route_step != nil 
#		 self.route_step = route_step
#		 return true
#	 else
#		errors.add_to_base("value of field: 'route_step_code' is invalid- it must be unique")
#		 return false
#	end
#end
# 
#def set_transaction_type
#
#	transaction_type = TransactionType.find_by_transaction_type_code(self.transaction_type_code)
#	 if transaction_type != nil 
#		 self.transaction_type = transaction_type
#		 return true
#	 else
#		errors.add_to_base("value of field: 'transaction_sub_type_code' is invalid- it must be unique")
#		 return false
#	end
#end
# 
#def set_serialised_container
#
#	serialised_container = SerialisedContainer.find_by_serialised_container_code(self.serialised_container_code)
#	 if serialised_container != nil 
#		 self.serialised_container = serialised_container
#		 return true
#	 else
#		errors.add_to_base("value of field: 'serialised_container_code' is invalid- it must be unique")
#		 return false
#	end
#end
# 
#def set_location
#	l ocation = Location.find_by_location_code(self.location_code)
#	 if location != nil 
#		 self.location = location
#		 return true
#	 else
#		errors.add_to_base("value of field: 'location_code' is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_transaction_business_name
#     transaction_business_name = TransactionBusinessName.find_by_transaction_business_name_code(self.transaction_business_name_code)
#	 if transaction_business_name != nil 
#		 self.transaction_business_name = transaction_business_name
#		 return true
#	 else
#		errors.add_to_base("value of field: 'transaction_business_name_code' is invalid- it must be unique")
#		 return false
#	end
#end
#
#def set_inventory_receipt
#  inventory_receipt = InventoryReceipt.find_by_inventory_receipt_code(self.inventory_receipt_code)
#  if inventory_receipt != nil
#    self.inventory_receipt = inventory_receipt
#    return true
#  else
#    errors.add_to_base("value of field: 'inventory_receipt_code' is invalid- it must be unique")
#    return false
#  end
#end
#
#def set_inventory_issue
#  inventory_issue = InventoryIssue.find_by_inventory_issue_code(self.inventory_issue_code)
#  if inventory_issue != nil
#    self.inventory_issue = inventory_issue
#    return true
#  else
#    errors.add_to_base("value of field: 'inventory_issue_code' is invalid- it must be unique")
#    return false
#  end
#end
 
#	===========================
#	 lookup methods:
#	===========================

end