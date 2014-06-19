class Incoterm < ActiveRecord::Base
  has_many :trading_partners

  validates_presence_of :incoterm_code
  validates_presence_of :medium_description


end
