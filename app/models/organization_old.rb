class Organization < ActiveRecord::Base

has_many :facilities
belongs_to :party
  
 
 
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

end
