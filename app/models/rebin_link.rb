class RebinLink < ActiveRecord::Base

  belongs_to :production_run
  belongs_to :rebin_setup
  belongs_to :rebin_label_setup
  belongs_to :rebin_template
  belongs_to :active_device
  
  belongs_to :carton_setup
  belongs_to :carton_label_setup
  belongs_to :carton_template
  belongs_to :pallet_setup
   belongs_to :pallet_template
  belongs_to :pallet_label_setup
  
  def after_create
   self.day_line_batch_number = self.id.to_s + "xxxxx" 
   self.update
  
  end
  
 
end
