class SellByCode < ActiveRecord::Base

  def SellByCode.get_all_by_org(role,org_name)
  
    query = "SELECT  public.organizations.sell_by_description
             FROM
             public.parties_roles
             INNER JOIN public.roles ON (public.parties_roles.role_id = public.roles.id)
             INNER JOIN public.organizations ON (public.parties_roles.party_id = public.organizations.party_id)
             WHERE
             (public.roles.role_name = '#{role}') AND public.organizations.short_description = '#{org_name}'"  

   return SellByCode.find_by_sql(query).map{|o| [o.sell_by_description]}
  end
  
end
