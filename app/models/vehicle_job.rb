class VehicleJob < ActiveRecord::Base

  #	===========================
  # 	Association declarations:
  #	===========================
  belongs_to :vehicle
  belongs_to :vehicle_job_type
  has_many :vehicle_job_units


  #	============================
  #	 Validations declarations:
  #	============================
  validates_presence_of :vehicle_job_number
  #validates_uniqueness_of :vehicle_job_number

  #	=====================
  #	 Complex validations:
  #	=====================
  def validate
    # first check whether combo fields have been selected
    is_valid = true
  end

end