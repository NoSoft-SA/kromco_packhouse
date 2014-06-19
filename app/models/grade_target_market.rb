class GradeTargetMarket < ActiveRecord::Base
  belongs_to :grades
  belongs_to :target_markets

end