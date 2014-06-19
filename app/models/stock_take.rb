class StockTake < ActiveRecord::Base
  has_many :location_error_stocks
  has_many :location_correct_stocks
  has_many :location_missing_stocks
  has_many :location_forced_moves
  has_many :location_before_stock_takes
  has_many :stock_take_scans

end
