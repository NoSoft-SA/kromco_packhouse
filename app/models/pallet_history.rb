class PalletHistory < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :pallet_label_setup
	belongs_to :pallet_template
	belongs_to :pallet_format_product
 
#	============================
#	 Validations declarations:
#	============================
	validates_numericality_of :rw_counter
	validates_numericality_of :carton_quantity_actual
	validates_numericality_of :cpp
	validates_numericality_of :consigment_note_number
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:variety_plusten_part_1 => self.variety_plusten_part_1}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_pallet_label_setup
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:pallet_number => self.pallet_number}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_pallet_template
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:pallet_format_product_code => self.pallet_format_product_code},{:id => self.id}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_pallet_format_product
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_pallet_label_setup

	pallet_label_setup = PalletLabelSetup.find_by_variety_plusten_part_1(self.variety_plusten_part_1)
	 if pallet_label_setup != nil 
		 self.pallet_label_setup = pallet_label_setup
		 return true
	 else
		errors.add_to_base("value of field: 'variety_plusten_part_1' is invalid- it must be unique")
		 return false
	end
end
 
def set_pallet_template

	pallet_template = PalletTemplate.find_by_pallet_number(self.pallet_number)
	 if pallet_template != nil 
		 self.pallet_template = pallet_template
		 return true
	 else
		errors.add_to_base("value of field: 'pallet_number' is invalid- it must be unique")
		 return false
	end
end
 
def set_pallet_format_product

	pallet_format_product = PalletFormatProduct.find_by_pallet_format_product_code_and_id(self.pallet_format_product_code,self.id)
	 if pallet_format_product != nil 
		 self.pallet_format_product = pallet_format_product
		 return true
	 else
		errors.add_to_base("combination of: 'pallet_format_product_code' and 'id'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: pallet_format_product_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_pallet_format_product_codes

	pallet_format_product_codes = PalletFormatProduct.find_by_sql('select distinct pallet_format_product_code from pallet_format_products').map{|g|[g.pallet_format_product_code]}
end



def self.get_all_ids

	ids = PalletFormatProduct.find_by_sql('select distinct id from pallet_format_products').map{|g|[g.id]}
end



def self.ids_for_pallet_format_product_code(pallet_format_product_code)

	ids = PalletFormatProduct.find_by_sql("Select distinct id from pallet_format_products where pallet_format_product_code = '#{pallet_format_product_code}'").map{|g|[g.id]}

	ids.unshift("<empty>")
 end






end
