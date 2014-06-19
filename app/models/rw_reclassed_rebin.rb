class RwReclassedRebin < ActiveRecord::Base

  belongs_to :rebin
  belongs_to :rw_run
  belongs_to :rw_receipt_rebin
  belongs_to :production_run
  
end


