class Program < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
  has_many :program_users,:dependent => :destroy
  belongs_to :functional_area
  has_many :program_functions,:dependent => :destroy,:order => "position,id"
 
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
		 is_valid = ModelHelper::Validations.validate_combos([{:functional_area_name => self.functional_area_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_functional_area
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Program.find_by_program_name_and_functional_area_name(self.program_name,self.functional_area_name)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'program_name' and 'functional_area_name' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_functional_area

	functional_area = FunctionalArea.find_by_functional_area_name(self.functional_area_name)
	 if functional_area != nil 
		 self.functional_area_id = functional_area.id
		 return true
	 else
		errors.add_to_base("value of field: 'functional_area_name' is invalid- it must be unique")
		 return false
	end
end

def before_update
#=============
#Luks' Code ==
#=============
  if self.functional_area.disabled == true
    self.disabled = self.functional_area.disabled
  end
  
  if self.functional_area.is_non_web_program == false
    self.class_name = nil
  end
#=============
  self.program_functions.each do |func|
      func.functional_area_name = self.functional_area_name
      func.program_name = self.program_name
      func.is_non_web_program = self.is_non_web_program #Luks
      func.disabled = self.disabled #Luks
      func.update
  end
end

#=============
#Luks' Code ==
#=============
def before_save
  functional_area = FunctionalArea.find_by_functional_area_name(self.functional_area_name)
  self.is_non_web_program = functional_area.is_non_web_program
  if self.functional_area.disabled == true
    self.disabled = self.functional_area.disabled
  end
  
  #if self.functional_area.is_non_web_program == true
  #  self.class_name = self.class.name
  #end
end
#============	
 
#	===========================
#	 lookup methods:
#	===========================



end
