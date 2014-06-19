class InventoryCode < ActiveRecord::Base

  #	============================
#	 Validations declarations:
#	============================
	validates_presence_of :inventory_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = InventoryCode.find_by_inventory_code(self.inventory_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'inventory_code' ")
	end
end


   def InventoryCode.get_all_by_org(org)
    query = "SELECT
              public.inventory_codes.inventory_code
              FROM
              public.inventory_codes_organizations
              INNER JOIN public.inventory_codes ON (public.inventory_codes_organizations.inventory_code_id = public.inventory_codes.id)
              INNER JOIN public.organizations ON (public.inventory_codes_organizations.organization_id = public.organizations.id)
              WHERE
              (public.organizations.short_description = '#{org}')"

   return InventoryCode.find_by_sql(query).map{|i|i.inventory_code}
   
   end

    
end
