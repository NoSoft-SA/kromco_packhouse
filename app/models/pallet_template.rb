class PalletTemplate < ActiveRecord::Base
  belongs_to :carton_setup
  belongs_to :pallet_format_product
  belongs_to :pallet_label_setup
  belongs_to :pallet_type
end
