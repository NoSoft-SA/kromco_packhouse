class PalletFormatProduct < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :pallet_base
	belongs_to :pallet_format_market
    belongs_to :product
    belongs_to :stack_type
#	============================
#	 Validations declarations:
#	============================
	
#	=====================
#	 Complex validations:
#	=====================

def before_destroy

  self.product.destroy
  
end

 def PalletFormatProduct.cartons_per_pallet_codes(cpp_code,pfp_code)
 
  query = "SELECT 
          public.cartons_per_pallets.cartons_per_pallet
           FROM
           public.cartons_per_pallets
           INNER JOIN public.pallet_format_products ON (public.cartons_per_pallets.pallet_format_product_id = public.pallet_format_products.id)
           INNER JOIN public.carton_pack_products ON (public.cartons_per_pallets.carton_pack_product_id = public.carton_pack_products.id)
           WHERE
           (public.carton_pack_products.carton_pack_product_code = '#{cpp_code}') AND 
           (public.pallet_format_products.pallet_format_product_code = '#{pfp_code}')"
   
         return CartonsPerPallet.find_by_sql(query).map{|p|[p.cartons_per_pallet]}
 
 end

def before_create

 product = nil
 product = Product.find_by_product_code(self.pallet_format_product_code)
 if !product
  product = Product.new
  product.product_code = self.pallet_format_product_code
  product.product_type_code = "PALLET_FORMAT"
  product.product_type = ProductType.find_by_product_type_code("PALLET_FORMAT")
  product.create
 end
 
 self.product = product
end



def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:pallet_base_code => self.pallet_base_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_pallet_base
	 end
	 
	  if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:stack_type_code => self.stack_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_stack_type
	 end
	 
	 
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:market_code => self.market_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_pallet_format_market
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
	 
	 if self.market_code && self.stack_type_code && self.pallet_base_code
	   self.pallet_format_product_code = self.market_code + "_" + self.stack_type_code.to_s + "_" + self.pallet_base_code
	 end
end

def validate_uniqueness
	 exists = PalletFormatProduct.find_by_market_code_and_stack_type_code_and_pallet_base_code(self.market_code,self.stack_type_code,self.pallet_base_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'market_code' and 'stack_type_code' and 'pallet_base_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================


def set_pallet_base

	pallet_base = PalletBase.find_by_pallet_base_code(self.pallet_base_code)
	 if pallet_base != nil 
		 self.pallet_base = pallet_base
		 return true
	 else
		errors.add_to_base("combination of: 'pallet_base_code'  is invalid- it must be unique")
		 return false
	end
end

def set_stack_type

	stack_type = StackType.find_by_stack_type_code(self.stack_type_code)
	 if stack_type != nil 
		 self.stack_type = stack_type
		 return true
	 else
		errors.add_to_base("stack type code is invalid")
		 return false
	end
end
 
def set_pallet_format_market

	pallet_format_market = PalletFormatMarket.find_by_market_code(self.market_code)
	 if pallet_format_market != nil 
		 self.pallet_format_market = pallet_format_market
		 return true
	 else
		errors.add_to_base("combination of: 'market_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: pallet_base_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_pallet_base_codes

	pallet_base_codes = PalletBasis.find_by_sql('select distinct pallet_base_code from pallet_bases').map{|g|[g.pallet_base_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: pallet_format_market_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_market_codes

	market_codes = PalletFormatMarket.find_by_sql('select distinct market_code from pallet_format_markets').map{|g|[g.market_code]}
end






end
