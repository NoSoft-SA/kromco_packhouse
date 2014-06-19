class DrenchStation < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :drench_line
	belongs_to :resource
	has_many :drench_concentrates
 
#	============================
#	 Validations declarations:
#	============================
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:drench_line_code => self.drench_line_code}],self) 
#	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_drench_line
	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:resource_code => self.resource_code}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_resource
#	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def set_drench_line

	drench_line = DrenchLine.find_by_drench_line_code(self.drench_line_code)
	 if drench_line != nil 
		 self.drench_line = drench_line
		 return true
	 else
		errors.add_to_base("value of field: 'drench_line_code' is invalid- it must be unique")
		 return false
	end
end
 
#def set_resource
#
#	resource = Resource.find_by_resource_code(self.resource_code)
#	 if resource != nil 
#		 self.resource = resource
#		 return true
#	 else
#		errors.add_to_base("combination of: 'resource_code'  is invalid- it must be unique")
#		 return false
#	end
#end
def before_create
   resource = Resource.new
#   drench_line_type = DrenchLineType.find_by_drench_line_type_code(self.drench_line_type_code)
   resource.resource_code = self.drench_station_code # OR IS IT drench_status_code ::::::::::::::::::: ASK HANS
   resource.resource_type_code = 'drench_station' #self.class.name
   #resource.resource_type_id = drench_line_type.id  #NOT in the original resources table
   resource.save
   self.resource = resource
end

def before_destroy
   #resource = Resource.find(self.resource_id)
   #begin
    # resource.destroy
     self.resource.destroy
     
#     if self.drench_concentrates != nil
#       for drench_concentrate in self.drench_concentrates
#         begin
#           drench_concentrate.destroy
#         rescue
#         end
#       end
#     end
   #rescue
    # errors.add_to_base("corresponding resource record for this station could not be deleted")
   #end
end 
def after_update

end
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: resource_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_resource_codes

	resource_codes = Resource.find_by_sql('select distinct resource_code from resources').map{|g|[g.resource_code]}
end






end
