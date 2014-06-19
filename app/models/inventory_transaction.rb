class InventoryTransaction < ActiveRecord::Base 

  attr_accessor :inventory_receipt_reference_number
#	===========================
# 	Association declarations:
#	===========================
 
 
	#belongs_to :route_step
	belongs_to :transaction_type
	#belongs_to :serialised_container
	belongs_to :location
	belongs_to :transaction_business_name
	belongs_to :inventory_receipt
	belongs_to :inventory_issue
 
#	============================
#	 Validations declarations:
#	============================
    #validates_presence_of :transaction_type_code
    #validates_presence_of :transaction_business_name_code
#  validates_presence_of :transaction_date_time
#  validates_presence_of :reference_number
#	validates_numericality_of :transaction_quantity_minus
#	validates_numericality_of :transaction_quantity_plus
	
#	=====================
#	 Complex validations:
#	=====================

  #---------------------------------------------------------------------------------------------------------
  #This static method attempts to simply the creation and population of a new inventory_transaction object
  #returns: a new in-memory inventory_transaction object
  #----------------------------------------------------------------------------------------------------------
  def self.new_object(transaction_type,business_procc_name,ref_number,location_to = nil,stock_item = nil,receipt = nil,issue = nil)
    #implementation: lookup all records using the passed-in values- raise an exception if any record could not be found
    #location_to: lookup location_from using current_location of passed_in stock_item; stock_item and location_to must be
    # passed-in together
    inventory_transaction = InventoryTransaction.new

    transaction_type_record = TransactionType.find_by_transaction_type_code(transaction_type)
    if transaction_type_record != nil
       inventory_transaction.transaction_type_code = transaction_type
       inventory_transaction.transaction_type_id = transaction_type_record.id
    else
      raise "transaction type could not be set properly!"
    end
    transaction_business_name = TransactionBusinessName.find_by_transaction_business_name_code(business_procc_name)
    if transaction_business_name != nil 
      inventory_transaction.transaction_business_name_code = business_procc_name
      inventory_transaction.transaction_business_name_id = transaction_business_name.id
    else
      raise "transaction business name could not be set properly!"
    end
    if location_to != nil && stock_item != nil
      location = Location.find_by_location_code(location_to)
      if location
        inventory_transaction.location_to = location_to
        inventory_transaction.location_id = location.id
        inventory_transaction.location_from = stock_item.location_code
      end
    end
    inventory_transaction.reference_number = ref_number
    if receipt
      inventory_receipt = InventoryReceipt.find_by_reference_number(receipt)
      if inventory_receipt != nil
        inventory_transaction.inventory_receipt_id = inventory_receipt.id
      else
        raise "inventory_receipt is invalid"
      end
    end
    if issue
      inventory_issue = InventoryIssue.find_by_inventory_issue_code(issue)
      if inventory_issue != nil
        inventory_transaction.inventory_issue_id = inventory_issue.id
      else
        raise "inventory_issue is invalid"
      end
    end
    return inventory_transaction
  end


def validate 
#	first check whether combo fields have been selected
##	 is_valid = true
##	 if is_valid
##	   is_valid = set_transaction_type
##	 end
##   if is_valid
##     is_valid = set_transaction_business_name
##   end
##   if is_valid
##     is_valid = set_inventory_receipt
##   end
##   if is_valid
##     is_valid = set_location
##   end
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
#	 end
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
def set_transaction_type

	transaction_type = TransactionType.find_by_transaction_type_code(self.transaction_type_code)
	 if transaction_type != nil 
		 self.transaction_type = transaction_type
		 return true
	 else
		errors.add_to_base("value of field: 'transaction_type_code' is invalid- it must be unique")
		 return false
	end
end
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
def set_location
	location = Location.find_by_location_code(self.location_to)
	 if location != nil 
		 self.location = location
		 return true
	 else
		errors.add_to_base("value of field: 'location_code' is invalid- it must be unique")
		 return false
	end
end

def set_transaction_business_name
     transaction_business_name = TransactionBusinessName.find_by_transaction_business_name_code(self.transaction_business_name_code)
	 if transaction_business_name != nil 
		 self.transaction_business_name = transaction_business_name
		 return true
	 else
		errors.add_to_base("value of field: 'transaction_business_name_code' is invalid- it must be unique")
		 return false
	end
end

def set_inventory_receipt
  inventory_receipt = InventoryReceipt.find_by_reference_number(self.inventory_receipt_reference_number)
  if inventory_receipt != nil
    self.inventory_receipt = inventory_receipt
    return true
  else
    errors.add_to_base("value of field: 'inventory_receipt_code' is invalid- it must be unique")
    return false
  end
end

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

def update_changed_fields
  changed_fields = self.changed_fields
  if changed_fields != nil && changed_fields.length > 0
    if changed_fields.has_key?("transaction_business_name_code")
      transaction_business_name_code = changed_fields.fetch("transaction_business_name_code")[1]
      trans_business_name = TransactionBusinessName.find_by_transaction_business_name_code(transaction_business_name_code)
      if trans_business_name
        self.transaction_business_name_id = trans_business_name.id
        self.transaction_business_name_code = trans_business_name.transaction_business_name_code
      end
    end

  #  if changed_fields.has_key?("transaction_type_code")
  #    transaction_type_code = changed_fields.fetch("transaction_type_code")[1]
  #    trans_type = TransactionType.find_by_transaction_type_code(transaction_type_code)
  #    if trans_type
  #      self.transaction_type_id = trans_type.id
  #      self.transaction_type_code = trans_type.transaction_type_code
  #    end
  #  end

    if changed_fields.has_key?("reference_number")
      reference_number = changed_fields.fetch("reference_number")[1]
      self.reference_number = reference_number
    end
  end
  #self.update
end


end
