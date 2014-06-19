class Organization < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
	belongs_to :party,:dependent => :destroy
	has_many :facilities
  has_many :organization_rules, :dependent => :destroy
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :short_description
#	=====================
#	 Complex validations:
#	=====================
def validate 

	 if self.new_record? 
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Organization.find_by_short_description(self.short_description)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'short_description' ")
	end
end


def before_save
    party = nil
    if self.new_record?
      party = Party.new
    else
      party = self.party
    end
    party.party_type_id = 2
    party.party_type_name = "ORGANIZATION"
    party.party_name = self.short_description
    party.save
    self.party = party
 
 
 end

  def after_destroy
    self.party.destroy
  
  end

    
def Organization.get_all_by_role(role,return_records = nil)
  
    query = "SELECT  public.organizations.id,
             public.organizations.short_description
             FROM
             public.parties_roles
             INNER JOIN public.roles ON (public.parties_roles.role_id = public.roles.id)
             INNER JOIN public.organizations ON (public.parties_roles.party_id = public.organizations.party_id)
             WHERE
             (public.roles.role_name = '#{role}')"  
  
   orgs = Organization.find_by_sql(query)
   if return_records
    return orgs
   else
    return orgs.map{|o| [o.short_description]}
   end
   
  end
 
  def Organization.get_sell_bys_by_orgs(org1,org2)
  
    query = "SELECT  public.organizations.sell_by_description
             FROM
             public.organizations
             WHERE
             ( public.organizations.short_description = '#{org1}'
              OR public.organizations.short_description = '#{org2}')"  

   return Organization.find_by_sql(query).map{|o| [o.sell_by_description]}
  end
  
 def Organization.get_sell_bys_by_org(role,org_name)
  
    query = "SELECT  public.organizations.sell_by_description
             FROM
             public.parties_roles
             INNER JOIN public.roles ON (public.parties_roles.role_id = public.roles.id)
             INNER JOIN public.organizations ON (public.parties_roles.party_id = public.organizations.party_id)
             WHERE
             (public.roles.role_name = '#{role}') AND public.organizations.short_description = '#{org_name}'"  

   return Organization.find_by_sql(query).map{|o| [o.sell_by_description]}
  end

  def need_gtin_check?
    rule_type_rec = RuleType.find_by_rule_type_code('gtin')
    gtin_chech_rule = nil

    gtin_chech_rule = Rule.find_by_rule_code_and_rule_type_id('gtin', rule_type_rec.id) if rule_type_rec
    if (gtin_chech_rule)
      organization_rules = OrganizationRule.find(:all, :conditions => "organization_rules.organization_id = '#{self.id}' and rule_id='#{gtin_chech_rule.id}'")
      if (organization_rules.length > 0)
        return true
      end
    end
    return false
  end

end
