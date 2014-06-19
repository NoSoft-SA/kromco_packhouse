class Vehicle < ActiveRecord::Base

  #	===========================
  # 	Association declarations:
  #	===========================
  has_many :vehicle_jobs

  #	============================
  #	 Validations declarations:
  #	============================
  validates_presence_of :vehicle_code
  #validates_presence_of :vehicle_description
  #validates_presence_of :vehicle_registration_number
  #validates_uniqueness_of :vehicle_registration_number
  validates_uniqueness_of :vehicle_code

  #	=====================
  #	 Complex validations:
  #	=====================
  def validate
    # first check whether combo fields have been selected
    is_valid = true
  end

end