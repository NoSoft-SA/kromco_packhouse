class CartonLabelSetup < ActiveRecord::Base

  belongs_to :carton_setup
  has_one :carton_link,:dependent => :destroy
  
  attr_accessor :pc_code_num,:pc_code,:marking_heading,:diameter_heading,:print_count,:gtin_readable,:pick_ref,:puc_code,:egap,:phc,
                :nature_choice_certificate,:batch_code,:extended_fg_code
end
