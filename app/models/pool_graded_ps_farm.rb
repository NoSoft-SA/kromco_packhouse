class PoolGradedPsFarm < ActiveRecord::Base
  belongs_to :pool_graded_ps_summary

  attr_accessor :maf_lot_number
end