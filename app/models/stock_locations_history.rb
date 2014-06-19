class StockLocationsHistory < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :location
	belongs_to :stock_item
	belongs_to :inventory_transaction
 
#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :units_in_location_before
	validates_numericality_of :units_in_location_after
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:location_id => self.location_id}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_inventory_transaction
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:location_code => self.location_code}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_location
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:inventory_reference => self.inventory_reference}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_stock_item
#	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_location

	location = Location.find_by_location_code(self.location_code)
	 if location != nil 
		 self.location = location
		 return true
	 else
		errors.add_to_base("combination of: 'location_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_stock_item

	stock_item = StockItem.find_by_inventory_reference(self.inventory_reference)
	 if stock_item != nil 
		 self.stock_item = stock_item
		 return true
	 else
		errors.add_to_base("combination of: 'inventory_reference'  is invalid- it must be unique")
		 return false
	end
end
 
def set_inventory_transaction

	inventory_transaction = InventoryTransaction.find_by_location_id(self.location_id)
	 if inventory_transaction != nil 
		 self.inventory_transaction = inventory_transaction
		 return true
	 else
		errors.add_to_base("value of field: 'location_id' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: location_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_location_codes

	location_codes = Location.find_by_sql('select distinct location_code from locations').map{|g|[g.location_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: stock_item_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_inventory_references

	inventory_references = StockItem.find_by_sql('select distinct inventory_reference from stock_items').map{|g|[g.inventory_reference]}
end






end
