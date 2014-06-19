class ShiftType < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
 
#	============================
#	 Validations declarations:
#	============================
     validates_uniqueness_of :shift_type_code
	validates_presence_of :shift_type_code
	validates_numericality_of :end_time
	validates_numericality_of :start_time
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = ShiftType.find_by_shift_type_code_and_start_time_and_end_time(self.shift_type_code,self.start_time,self.end_time)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'shift_type_code' and 'start_time' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================






  #shift codes for shift_type_codes
def self.shift_codes_for_shift_type_code(shift_type_code)

	start_times = ShiftType.find_by_sql("Select distinct start_time from shift_types where shift_type_code = '#{shift_type_code}'").map{|g|[g.start_time]}

	start_times.unshift("<empty>")
end


  #new change
  def self.shift_codes_for_shift_type_code(shift_type_code)

	end_times = ShiftType.find_by_sql("Select distinct end_time from shift_types where shift_type_code = '#{shift_type_code}'").map{|g|[g.end_time]}

	end_times.unshift("<empty>")
 end
  
end
