class RwScrapBin < ActiveRecord::Base
  belongs_to :rw_reason
  belongs_to :rw_receipt_bin

end
