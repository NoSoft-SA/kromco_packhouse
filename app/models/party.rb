class Party < ActiveRecord::Base
  
  has_and_belongs_to_many :roles
  has_one :postal_address
  has_and_belongs_to_many :groups
  has_many :parties_roles,:dependent => :destroy
  has_many :persons,:dependent => :destroy


  ORGANIZATION = 'ORGANIZATION'

  def self.get_party_role_id_for(party_name, role_name, party_type_name=ORGANIZATION)
    query = "SELECT public.parties_roles.id from public.parties_roles
             WHERE public.parties_roles.party_name = '#{party_name}'
             AND public.parties_roles.party_type_name = '#{party_type_name}'
             AND public.parties_roles.role_name = '#{role_name}'"
    parties = Party.find_by_sql(query)
    if parties.empty?
        raise StandardError, "No party-role for Party: \"#{party_name}\" (#{party_type_name}), Role: \"#{role_name}\"."
    elsif parties.size > 1
        raise StandardError, "More than one party-role for Party: \"#{party_name}\" (#{party_type_name}), Role: \"#{role_name}\". Expecting only one."
    else
      parties.first.id
    end
  end

end
