class ProgramFunction < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :program
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :name
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:program_name => self.program_name},{:functional_area_name => self.functional_area_name}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_program
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = ProgramFunction.find_by_functional_area_name_and_program_name_and_name(self.functional_area_name,self.program_name,self.name)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'functional_area_name' and 'program_name' and 'name' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_program

	program = Program.find_by_program_name_and_functional_area_name(self.program_name,self.functional_area_name)
	 if program != nil 
		 self.program = program
		 return true
	 else
		errors.add_to_base("combination of: 'program_name' and 'functional_area_name'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: program_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_program_names

	program_names = Program.find_by_sql('select distinct program_name from programs').map{|g|[g.program_name]}
end



def self.get_all_functional_area_names

	functional_area_names = Program.find_by_sql('select distinct functional_area_name from programs').map{|g|[g.functional_area_name]}
end



def self.functional_area_names_for_program_name(program_name)

	functional_area_names = Program.find_by_sql("Select distinct functional_area_name from programs where program_name = '#{program_name}'").map{|g|[g.functional_area_name]}


 end

  # GENERIC PROGRAMS:

  # Get the list of url_param => program names for a function.
  # Raises an error if there is a url_param pointing to two different program_names.
  def self.generic_program_list( function_name )
    list = ProgramFunction.find(:all,
                                :select     => 'distinct program_name, url_param',
                                :conditions => ['UPPER(functional_area_name) = ? AND url_param is not null', function_name.upcase]).
                                map {|r| [r.url_param, r.program_name] }.sort

    # Check for duplicate url params:
    keys = list.map{|a| a[0] }
    if keys.uniq.size < list.size
      dup_keys = keys.uniq.map {|v| (keys - [v]).size < (keys.size - 1) ? v : nil}.compact # Find duplicates
      dups     = list.select{|a| dup_keys.include? a[0] }
      raise "Security setup for function '#{function_name}' has at least one url param pointing to two different programs: #{dups.map{|a| a.join(' => ')}.join(', ')}."
    end

    # Return the list as a Hash for easy lookup:
    Hash[*list.flatten]
  end

  # Get the program name for a function / url_param combination.
  # Gets a hash of generic program names from generic_program_list.
  # Matches on the url_param.
  def self.generic_program_name( function_name, url_param )
    program_name = generic_program_list( function_name )[url_param]
    raise "Security setup does not include a generic program for function '#{function_name}', url_param '#{url_param}'." if program_name.nil?
    program_name
  end

#=============
#Luks' Code ==
#=============
def before_save
  self.is_non_web_program = self.program.is_non_web_program
  if self.program.disabled == true
    self.disabled = self.program.disabled
  end
 end

def before_update
  if self.program.disabled == true
    self.disabled = self.program.disabled
  end
#=============
end




end
