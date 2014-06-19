class RwScrapPallet < ActiveRecord::Base

  belongs_to :rw_reason
  belongs_to :rw_receipt_pallet

end
