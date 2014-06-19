class Orchard < ActiveRecord::Base
    
    belongs_to :farm
 
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
        exists = Orchard.find_by_orchard_code(self.orchard_code)
        if exists != nil
            errors.add_to_base("There already exists a record with the combined values of fields: 'orchard_code'")
        end
    end
    
end