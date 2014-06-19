class PackGroupTemplateOutlet < ActiveRecord::Base

 belongs_to :pack_group_template
 
 attr_accessor :rmt_variety_code,:commodity_code,:line_config_code,:sizer_template_name,
               :color_sort_percentage,:grade_code,:pack_group_number
 
end
