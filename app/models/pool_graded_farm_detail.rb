class PoolGradedFarmDetail < ActiveRecord::Base 

  #	===========================
  # 	Association declarations:
  #	===========================


  belongs_to :pool_graded_summary
  belongs_to :pool_graded_farm

  #	============================
  #	 Validations declarations:
  #	============================
  validates_numericality_of :graded_size
  validates_numericality_of :graded_class

end
