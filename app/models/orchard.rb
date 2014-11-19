class Orchard < ActiveRecord::Base
    
    belongs_to :farm

    #MM102014-add virtual variable commodity id
    attr_accessor :orchard_commodity_id, :commodity_code#, :commodity_description_long
#===================================
#   Validations
#===================================
    validates_presence_of :orchard_code
    validates_uniqueness_of :orchard_code
    
    def validate
        if self.new_record?
            validate_uniqueness
        end
    end
    
    def validate_uniqueness
        exists = Orchard.find_by_farm_id_and_orchard_code(self.farm_id,self.orchard_code)
        if exists != nil
            errors.add_to_base("There already exists a record with the combined values of fields: 'orchard_code'")
        end
    end

end