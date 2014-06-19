class PoolGradedDetail < ActiveRecord::Base 

  #	===========================
  # 	Association declarations:
  #	===========================

  belongs_to :pool_graded_summary

  validates_numericality_of :graded_size, :graded_class, :allow_nil => true

end
