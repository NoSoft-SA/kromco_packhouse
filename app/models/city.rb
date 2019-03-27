class City < ActiveRecord::Base
	belongs_to :country

  validates_presence_of :country_id

  # include MasterFileActivator

end
