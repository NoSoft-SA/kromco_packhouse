class PartiesRole < ActiveRecord::Base

  #  ===========================
  #   Association declarations:
  #  ===========================


  belongs_to :role
  belongs_to :party

  # Roles that are created via their own CRUD functions (not the generic parties role CRUD functions)
  OWN_CRUD_ROLES = []

  #  ============================
  #   Validations declarations:
  #  ============================
  #  =====================
  #   Complex validations:
  #  =====================
  def validate
    #  first check whether combo fields have been selected
    is_valid = true
    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:role_name => self.role_name}],self)
    end

    #now check whether fk combos combine to form valid foreign keys
    if is_valid
      is_valid = set_role
    end
    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:party_type_name => self.party_type_name},{:party_name => self.party_name}],self)
    end
    #now check whether fk combos combine to form valid foreign keys
    if is_valid
      is_valid = set_party
    end
    #validates uniqueness for this record
    if self.new_record? && is_valid
      validate_uniqueness
    end
  end

  def validate_uniqueness
    exists = PartiesRole.find_by_party_type_name_and_party_name_and_role_name(self.party_type_name,self.party_name,self.role_name)
    if exists != nil
      errors.add_to_base("There already exists a record with the combined values of fields: 'party_type_name' and 'party_name' and 'role_name' ")
    end
  end
  #  ===========================
  #   foreign key validations:
  #  ===========================
  def set_role

    role = Role.find_by_role_name(self.role_name)
    if role != nil
      self.role = role
      return true
    else
      errors.add_to_base("combination of: 'role_name'  is invalid- it must be unique")
      return false
    end
  end

  def set_party

    party = Party.find_by_party_type_name_and_party_name(self.party_type_name,self.party_name)
    if party != nil
      self.party = party
      return true
    else
      errors.add_to_base("Party does not exist")
      return false
    end
  end

  #  ===========================
  #   lookup methods:
  #  ===========================
  #  ------------------------------------------------------------------------------------------
  #  Lookup methods for the foreign composite key of id field: role_id
  #  ------------------------------------------------------------------------------------------

  def self.get_all_role_names

    role_names = Role.find_by_sql('select distinct role_name from roles').map{|g|[g.role_name]}
  end



  #  ------------------------------------------------------------------------------------------
  #  Lookup methods for the foreign composite key of id field: party_id
  #  ------------------------------------------------------------------------------------------

  def self.get_all_party_type_names

    party_type_names = Party.find_by_sql('select distinct party_type_name from parties').map{|g|[g.party_type_name]}
  end



  def self.get_all_party_names

    party_names = Party.find_by_sql('select distinct party_name from parties').map{|g|[g.party_name]}
  end



  def self.party_names_for_party_type_name(party_type_name)

    party_names = Party.find_by_sql("Select distinct party_name from parties where party_type_name = '#{party_type_name}'").map{|g|[g.party_name]}

    party_names.unshift("<empty>")
  end

  # Return a Struct of a PartiesRole name and address.
  def self.postal_address_for(parties_role_id)
    qry =<<-EOQ
    SELECT parties_roles.party_name, postal_addresses.address1,
     postal_addresses.address2, postal_addresses.address3,
     postal_addresses.city, countries.country_name,
     contact_landline.contact_method_code AS landline,
     contact_fax.contact_method_code AS fax
    FROM parties_roles
     LEFT OUTER JOIN parties_postal_addresses ON (parties_roles.party_id = parties_postal_addresses.party_id)
                                             AND (parties_postal_addresses.postal_address_type_code = 'POSTAL')
     LEFT OUTER JOIN postal_addresses ON parties_postal_addresses.postal_address_id = postal_addresses.id
     LEFT OUTER JOIN countries ON postal_addresses.country_id = countries.id
     LEFT OUTER JOIN contact_methods_parties contact_landline ON (parties_roles.party_id = contact_landline.party_id)
                                                             AND (contact_landline.contact_method_type_code = 'LandLine')
     LEFT OUTER JOIN contact_methods_parties contact_fax ON (parties_roles.party_id = contact_fax.party_id)
                                                        AND (contact_fax.contact_method_type_code = 'Fax')
    WHERE parties_roles.id = #{parties_role_id}
    EOQ
    rec = ActiveRecord::Base.connection.select_one(qry)
    addr = Struct.new(:name, :address1, :address2, :address3, :city, :country, :landline, :fax) do
      def address_fields
        [address1, address2, address3, city, country].compact
      end
    end
    addr.new(rec['party_name'], rec['address1'],
             rec['address2'],   rec['address3'],
             rec['city'],       rec['country_name'],
             rec['landline'] || '',   rec['fax'] || '')
  end

  def self.for_select(role_name)
    PartiesRole.find(:all,
                     :select     => 'party_name, id',
                     :conditions => ["role_name = ?", role_name],
                     :order      => 'party_name').map {|r| [r.party_name, r.id] }
  end

  def self.get_employee_party_role_record(party_id,role_id)
    party_role = PartiesRole.find_by_sql("select id from parties_roles where party_id = #{party_id} and role_id = #{role_id}")
    if party_role.length > 0
      party_role_id = party_role[0].id
    else
      role_name = Role.find(role_id).role_name

      party = Party.find(party_id)
      party_name = party.party_name
      party_type_id = party.party_type_id

      party_type_name = PartyType.find(party_type_id).party_type_name

      party_role = PartiesRole.new
      party_role.party_id = party_id
      party_role.role_id = role_id
      party_role.role_name = role_name
      party_role.party_name = party_name
      party_role.party_type_name = party_type_name
      party_role.save

      party_role_id = party_role.id
    end
    return party_role_id
  end

end
