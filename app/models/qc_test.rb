class QcTest < ActiveRecord::Base

  #	===========================
  # 	Association declarations:
  #	===========================
  has_many :qc_inspection_types, :through => :qc_inspection_type_test
  has_many :qc_measurement_types, :dependent => :destroy
  has_many :qc_results

  validates_presence_of :qc_test_code, :qc_test_description

end
