class InventoryItem < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :location
	belongs_to :inventory_type
	belongs_to :inventory_transaction
	belongs_to :parties_role
	belongs_to :lot
 
#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :inventory_quantity
#	=====================
#	 Complex validations:
#	=====================
def validate 
##	first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:transaction_sub_type_id => self.transaction_sub_type_id}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_inventory_transaction
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:lot_number => self.lot_number}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_lot
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:inventory_type_code => self.inventory_type_code}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_inventory_type
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:party_type_name => self.party_type_name},{:party_name => self.party_name},{:role_name => self.role_name},{:id => self.id}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_parties_role
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:location_code => self.location_code}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_location
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
		errors.add_to_base("value of field: 'location_code' is invalid- it must be unique")
		 return false
	end
end
 
def set_inventory_type

	inventory_type = InventoryType.find_by_inventory_type_code(self.inventory_type_code)
	 if inventory_type != nil 
		 self.inventory_type = inventory_type
		 return true
	 else
		errors.add_to_base("value of field: 'inventory_type_code' is invalid- it must be unique")
		 return false
	end
end
 
def set_inventory_transaction

	inventory_transaction = InventoryTransaction.find_by_transaction_sub_type_id(self.transaction_sub_type_id)
	 if inventory_transaction != nil 
		 self.inventory_transaction = inventory_transaction
		 return true
	 else
		errors.add_to_base("value of field: 'transaction_sub_type_id' is invalid- it must be unique")
		 return false
	end
end
 
def set_parties_role

	parties_role = PartiesRole.find_by_party_type_name_and_party_name_and_role_name_and_id(self.party_type_name,self.party_name,self.role_name,self.id)
	 if parties_role != nil 
		 self.parties_role = parties_role
		 return true
	 else
		errors.add_to_base("combination of: 'party_type_name' and 'party_name' and 'role_name' and 'id'  is invalid- it must be unique")
		 return false
	end
end
 
def set_lot

	lot = Lot.find_by_lot_number(self.lot_number)
	 if lot != nil 
		 self.lot = lot
		 return true
	 else
		errors.add_to_base("value of field: 'lot_number' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: parties_role_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_party_type_names

	party_type_names = PartiesRole.find_by_sql('select distinct party_type_name from parties_roles').map{|g|[g.party_type_name]}
end



def self.get_all_party_names

	party_names = PartiesRole.find_by_sql('select distinct party_name from parties_roles').map{|g|[g.party_name]}
end



def self.party_names_for_party_type_name(party_type_name)

	party_names = PartiesRole.find_by_sql("Select distinct party_name from parties_roles where party_type_name = '#{party_type_name}'").map{|g|[g.party_name]}

	party_names.unshift("<empty>")
 end



def self.get_all_role_names

	role_names = PartiesRole.find_by_sql('select distinct role_name from parties_roles').map{|g|[g.role_name]}
end



def self.role_names_for_party_name_and_party_type_name(party_name, party_type_name)

	role_names = PartiesRole.find_by_sql("Select distinct role_name from parties_roles where party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.role_name]}

	role_names.unshift("<empty>")
 end



def self.get_all_ids

	ids = PartiesRole.find_by_sql('select distinct id from parties_roles').map{|g|[g.id]}
end



def self.ids_for_role_name_and_party_name_and_party_type_name(role_name, party_name, party_type_name)

	ids = PartiesRole.find_by_sql("Select distinct id from parties_roles where role_name = '#{role_name}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.id]}

	ids.unshift("<empty>")
 end






end
