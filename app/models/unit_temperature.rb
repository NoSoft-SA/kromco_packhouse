class UnitTemperature < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :temperature_device_type
	belongs_to :unit_type
 
#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:temperature_device_type_code => self.temperature_device_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_temperature_device_type
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:unit_type_code => self.unit_type_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_unit_type
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_temperature_device_type

	temperature_device_type = TemperatureDeviceType.find_by_temperature_device_type_code(self.temperature_device_type_code)
	 if temperature_device_type != nil 
		 self.temperature_device_type = temperature_device_type
		 return true
	 else
		errors.add_to_base("value of field: 'temperature_device_type_code' is invalid- it must be unique")
		 return false
	end
end
 
def set_unit_type

	unit_type = UnitType.find_by_unit_type_code(self.unit_type_code)
	 if unit_type != nil 
		 self.unit_type = unit_type
		 return true
	 else
		errors.add_to_base("value of field: 'unit_type_code' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================



end
