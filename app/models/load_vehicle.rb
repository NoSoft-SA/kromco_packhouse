class LoadVehicle < ActiveRecord::Base
  attr_accessor :haulier
#	===========================
# 	Association declarations:
#	===========================


  belongs_to :load

#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
#  def validate
##	first check whether combo fields have been selected
#    is_valid = true
#    if is_valid
#      is_valid = ModelHelper::Validations.validate_combos([{:load_number => self.load_number}], self)
#    end
#    #now check whether fk combos combine to form valid foreign keys
#    if is_valid
#      is_valid = set_load
#    end
#  end

#	===========================
#	 foreign key validations:
#	===========================
#  def set_load
#
#    load = Load.find_by_load_number(self.load_number)
#    if load != nil
#      self.load = load
#      return true
#    else
#      errors.add_to_base("value of field: 'load_number' is invalid- it must be unique")
#      return false
#    end
#  end

#	===========================
#	 lookup methods:
#	===========================


end
