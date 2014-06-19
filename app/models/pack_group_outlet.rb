class PackGroupOutlet < ActiveRecord::Base

 belongs_to :pack_group
 belongs_to :production_run
 
 attr_accessor :production_schedule_name,:commodity_code,:marketing_variety_code,
               :line_code,:color_sort_percentage,:grade_code,:production_run_number




end
