class RwReclassedBin < ActiveRecord::Base
  belongs_to :bin
  belongs_to :rw_run
  belongs_to :rw_receipt_bin

end
