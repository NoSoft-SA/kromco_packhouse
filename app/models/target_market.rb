class TargetMarket < ActiveRecord::Base
  has_many :trading_partners

  has_many :direct_sales_target_markets
 #	============================
#	 Validations declarations:
#	============================
	validates_presence_of :target_market_name
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

    self.target_market_code = self.target_market_name + "_" + self.target_market_description
end

def validate_uniqueness
	 exists = TargetMarket.find_by_target_market_name(self.target_market_name)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'target_market_name' ")
	end
end
  
  
  def TargetMarket.is_valid_for_org?(org_name,target_market_code)
  
   query = "SELECT public.target_markets.target_market_name
            FROM public.organizations_target_markets
            INNER JOIN public.target_markets ON (public.organizations_target_markets.target_market_id = public.target_markets.id)
            INNER JOIN public.organizations ON (public.organizations_target_markets.organization_id = public.organizations.id)
            WHERE
            (public.organizations.short_description = '#{org_name}' and public.target_markets.target_market_name = '#{target_market_code}' )"
  
     return TargetMarket.find_by_sql(query).length > 0
  
  end
  
  

   def TargetMarket.get_all_by_org(org_name)
  
    query = "SELECT public.target_markets.target_market_name
            FROM public.organizations_target_markets
            INNER JOIN public.target_markets ON (public.organizations_target_markets.target_market_id = public.target_markets.id)
            INNER JOIN public.organizations ON (public.organizations_target_markets.organization_id = public.organizations.id)
            WHERE
            (public.organizations.short_description = '#{org_name}')"
  
     return TargetMarket.find_by_sql(query).map{|o| [o.target_market_name]}
  end
end
