class PartiesPostalAddress < ActiveRecord::Base
  attr_accessor :edited, :change_only_for_org
  #  ===========================
  #   Association declarations:
  #  ===========================


  belongs_to :postal_address
  belongs_to :party

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
      is_valid = ModelHelper::Validations.validate_combos([{:postal_address_type_code => self.postal_address_type_code},{:city => self.city},{:address1 => self.address1}],self)
    end
    #now check whether fk combos combine to form valid foreign keys
    if is_valid
      is_valid = set_postal_address
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
    exists = PartiesPostalAddress.find_by_party_type_name_and_party_name_and_postal_address_type_code_and_city_and_address1_and_address2(self.party_type_name,self.party_name,self.postal_address_type_code,self.city,self.address1,self.address2)
    if exists != nil
      errors.add_to_base("There already exists a record with the combined values of fields: 'party_type_name' and 'party_name' and 'postal_address_type_code' and 'city' and 'address1' and 'address2' ")
    end
  end
  #  ===========================
  #   foreign key validations:
  #  ===========================
  def set_postal_address

    postal_address = PostalAddress.find_by_postal_address_type_code_and_city_and_address1_and_address2(self.postal_address_type_code,self.city,self.address1,self.address2)
    if postal_address != nil
      self.postal_address = postal_address
      return true
    else
      errors.add_to_base("combination of: 'postal_address_type_code' and 'city' and 'address1' and 'address2'  is invalid- it must be unique")
      return false
    end
  end

  def set_party

    party = Party.find_by_party_type_name_and_party_name(self.party_type_name,self.party_name)
    if party != nil
      self.party = party
      return true
    else
      errors.add_to_base("combination of: 'party_type_name' and 'party_name'  is invalid- it must be unique")
      return false
    end
  end

  #  ===========================
  #   lookup methods:
  #  ===========================
  #  ------------------------------------------------------------------------------------------
  #  Lookup methods for the foreign composite key of id field: postal_address_id
  #  ------------------------------------------------------------------------------------------

  def self.get_all_postal_address_type_codes

    postal_address_type_codes = PostalAddress.find_by_sql('select distinct postal_address_type_code from postal_addresses').map{|g|[g.postal_address_type_code]}
  end



  def self.get_all_cities

    cities = PostalAddress.find_by_sql('select distinct city from postal_addresses').map{|g|[g.city]}
  end



  def self.cities_for_postal_address_type_code(postal_address_type_code)

    cities = PostalAddress.find_by_sql("Select distinct city from postal_addresses where postal_address_type_code = '#{postal_address_type_code}'").map{|g|[g.city]}

    cities.unshift("<empty>")
  end



  def self.get_all_address1s

    address1s = PostalAddress.find_by_sql('select distinct address1 from postal_addresses').map{|g|[g.address1]}
  end



  def self.address1s_for_city_and_postal_address_type_code(city, postal_address_type_code)

    address1s = PostalAddress.find_by_sql("Select distinct address1 from postal_addresses where city = '#{city}' and postal_address_type_code = '#{postal_address_type_code}'").map{|g|[g.address1]}

    address1s.unshift("<empty>")
  end



  def self.get_all_address2s

    address2s = PostalAddress.find_by_sql('select distinct address2 from postal_addresses').map{|g|[g.address2]}
  end

  def self.address2s_for_address1_and_city_and_postal_address_type_code(address1, city, postal_address_type_code)

    address2s = PostalAddress.find_by_sql("Select distinct address2 from postal_addresses where address1 = '#{address1}' and city = '#{city}' and postal_address_type_code = '#{postal_address_type_code}'").map{|g|[g.address2]}

    address2s.unshift("<empty>")
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


  def elements
    el = []
    el << self.address1    unless self.address1.nil?
    el << self.address2    unless self.address2.nil?
    el << self.city        unless self.city.nil?
    el << self.postal_address.postal_code unless self.postal_address.postal_code.nil?
    # el << self.postal_address.country.country_name unless self.postal_address.country_id.nil?
    el
  end

  def formatted_address
    "\n#{self.postal_address_type_code.humanize} address:\n#{elements.join("\n")}"
  end

end
