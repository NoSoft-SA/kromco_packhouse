class Depot < ActiveRecord::Base

  attr_accessor :location_code, :party_name

  has_many :intake_headers
  belongs_to :location
  belongs_to :parties_role

  #=============================
  # VALIDATIONS
  #=============================
  validates_presence_of :depot_code
  validates_uniqueness_of :depot_code

  def validate
    is_valid = true

    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:location_code=>self.location_code}], self)
    end
    if is_valid
      is_valid = set_location
    end

    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:party_name=>self.party_name}], self)
    end
    if is_valid
      is_valid = set_parties_role
    end
  end

  def set_location
    location = Location.find_by_location_code(self.location_code)
    if location
      self.location = location
      return true
    else
      errors.add_to_base("You must select 'location_code' please!")
      return false
    end
  end

  def set_parties_role
    parties_role = PartiesRole.find_by_party_name(self.party_name)
    if parties_role
      self.parties_role = parties_role
      return true
    else
      errors.add_to_base("You must select 'party_name' please!")
      return false
    end
  end

  def set_location_code_and_party_name
    location = Location.find(self.location_id)
    parties_role = PartiesRole.find(self.parties_role_id)
    if location
      self.location_code = location.location_code
    end
    if parties_role
      self.party_name = parties_role.party_name
    end
  end

end