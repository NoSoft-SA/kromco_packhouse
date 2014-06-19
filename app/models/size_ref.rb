class SizeRef < ActiveRecord::Base

   #	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :commodity
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :size_ref_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_commodity
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = SizeRef.find_by_commodity_code_and_size_ref_code(self.commodity_code,self.size_ref_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_code' and 'size_ref_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_commodity

	commodity = Commodity.find_by_commodity_code(self.commodity_code)
	 if commodity != nil 
		 self.commodity = commodity
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: commodity_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_codes

	commodity_codes = Commodity.find_by_sql('select distinct commodity_code from commodities').map{|g|[g.commodity_code]}
end
   
   
   
   
   def SizeRef.sizes_for_commodity(commodity)
   
    query = "SELECT 
            public.size_refs.size_ref_code
             FROM
             public.size_refs
             INNER JOIN public.commodities ON (public.size_refs.commodity_id = public.commodities.id)
             WHERE
             (public.commodities.commodity_code = '#{commodity}')"
   
    return SizeRef.find_by_sql(query).map{|s|s.size_ref_code}
   
   end
   
   
   
   
end
