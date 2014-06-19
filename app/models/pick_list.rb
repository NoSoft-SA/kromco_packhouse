class PickList < ActiveRecord::Base

  belongs_to :pick_list_type
  has_many :pick_list_items

end
