class VehicleJobUnit < ActiveRecord::Base

  #	===========================
  # 	Association declarations:
  #	===========================
  belongs_to :vehicle_job

  #	============================
  #	 Validations declarations:
  #	============================

  #validates_uniqueness_of :vehicle_job_number

  #	=====================
  #	 Complex validations:
  #	=====================
  def validate
    # first check whether combo fields have been selected
    is_valid = true
  end

end