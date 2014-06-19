class ActiveCartonLink < ActiveRecord::Base

  belongs_to :production_run
  belongs_to :carton_setup
  belongs_to :carton_label_setup
  belongs_to :carton_template
  belongs_to :active_device
  belongs_to :pallet_template
  belongs_to :pallet_label_setup
  
  belongs_to :rebin_label_setup
  belongs_to :rebin_template
  belongs_to :rebin_setup
  


end
