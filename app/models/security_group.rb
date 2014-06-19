class SecurityGroup < ActiveRecord::Base


  validates_presence_of :security_group_name
  
 has_and_belongs_to_many :security_permissions
 
 def self.permissions_for_group(group)
 
  query = "SELECT security_permissions.security_permission FROM security_groups_security_permissions " +
          " INNER JOIN security_permissions ON (security_groups_security_permissions.security_permission_id = security_permissions.id) " +
          " INNER JOIN security_groups ON (security_groups_security_permissions.security_group_id = security_groups.id)" +
          " WHERE (security_groups.security_group_name = '#{group}')"
 
  results = self.find_by_sql(query).map{|g|[g.security_permission]}
  
 end
 
end
