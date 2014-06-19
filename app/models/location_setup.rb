class LocationSetup < ActiveRecord::Base



    belongs_to :location
 

    validates_presence_of :priority
    validates_numericality_of :priority
end