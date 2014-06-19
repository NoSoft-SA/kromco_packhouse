class LocationMissingStock < ActiveRecord::Base
  belongs_to :stock_take
end
