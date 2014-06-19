class Downtime < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :downtime_sub_type
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :downtime_type_code
	validates_presence_of :downtime_minute
	validates_presence_of :to_time
	validates_presence_of :from_time
	validates_presence_of :downtime_sub_type_code
	validates_presence_of :to_date
	validates_presence_of :from_date
	validates_presence_of :downtime_division_code
	validates_presence_of :downtime_category_code
	validates_numericality_of :line
	validates_numericality_of :downtime_minute
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:downtime_category_code => self.downtime_category_code},{:downtime_division_code => self.downtime_division_code},{:downtime_type_code => self.downtime_type_code},{:downtime_sub_type_code => self.downtime_sub_type_code},{:external_ref => self.external_ref}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_downtime_sub_type
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		# validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = Downtime.find_by_downtime_category_code_and_downtime_division_code_and_downtime_type_code_and_downtime_sub_type_code_and_external_ref(self.downtime_category_code,self.downtime_division_code,self.downtime_type_code,self.downtime_sub_type_code,self.external_ref)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'downtime_category_code' and 'downtime_division_code' and 'downtime_type_code' and 'downtime_sub_type_code' and 'external_ref' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_downtime_sub_type

	downtime_sub_type = DowntimeSubType.find_by_downtime_category_code_and_downtime_division_code_and_downtime_type_code_and_downtime_sub_type_code_and_external_ref(self.downtime_category_code,self.downtime_division_code,self.downtime_type_code,self.downtime_sub_type_code,self.external_ref)
	 if downtime_sub_type != nil 
		 self.downtime_sub_type = downtime_sub_type
		 return true
	 else
		errors.add_to_base("combination of: 'downtime_category_code' and 'downtime_division_code' and 'downtime_type_code' and 'downtime_sub_type_code' and 'external_ref'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: downtime_sub_type_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_downtime_category_codes

	downtime_category_codes = DowntimeSubType.find_by_sql('select distinct downtime_category_code from downtime_sub_types').map{|g|[g.downtime_category_code]}
end



def self.get_all_downtime_division_codes

	downtime_division_codes = DowntimeSubType.find_by_sql('select distinct downtime_division_code from downtime_sub_types').map{|g|[g.downtime_division_code]}
end



def self.downtime_division_codes_for_downtime_category_code(downtime_category_code)

	downtime_division_codes = DowntimeSubType.find_by_sql("Select distinct downtime_division_code from downtime_sub_types where downtime_category_code = '#{downtime_category_code}'").map{|g|[g.downtime_division_code]}

	downtime_division_codes.unshift("<empty>")
 end



def self.get_all_downtime_type_codes

	downtime_type_codes = DowntimeSubType.find_by_sql('select distinct downtime_type_code from downtime_sub_types').map{|g|[g.downtime_type_code]}
end



def self.downtime_type_codes_for_downtime_division_code_and_downtime_category_code(downtime_division_code, downtime_category_code)

	downtime_type_codes = DowntimeSubType.find_by_sql("Select distinct downtime_type_code from downtime_sub_types where downtime_division_code = '#{downtime_division_code}' and downtime_category_code = '#{downtime_category_code}'").map{|g|[g.downtime_type_code]}

	downtime_type_codes.unshift("<empty>")
 end



def self.get_all_downtime_sub_type_codes

	downtime_sub_type_codes = DowntimeSubType.find_by_sql('select distinct downtime_sub_type_code from downtime_sub_types').map{|g|[g.downtime_sub_type_code]}
end



def self.downtime_sub_type_codes_for_downtime_type_code_and_downtime_division_code_and_downtime_category_code(downtime_type_code, downtime_division_code, downtime_category_code)

	downtime_sub_type_codes = DowntimeSubType.find_by_sql("Select distinct downtime_sub_type_code from downtime_sub_types where downtime_type_code = '#{downtime_type_code}' and downtime_division_code = '#{downtime_division_code}' and downtime_category_code = '#{downtime_category_code}'").map{|g|[g.downtime_sub_type_code]}

	downtime_sub_type_codes.unshift("<empty>")
 end



def self.get_all_external_refs

	external_refs = DowntimeSubType.find_by_sql('select distinct external_ref from downtime_sub_types').map{|g|[g.external_ref]}
end



def self.external_refs_for_downtime_sub_type_code_and_downtime_type_code_and_downtime_division_code_and_downtime_category_code(downtime_sub_type_code, downtime_type_code, downtime_division_code, downtime_category_code)

	external_refs = DowntimeSubType.find_by_sql("Select distinct external_ref from downtime_sub_types where downtime_sub_type_code = '#{downtime_sub_type_code}' and downtime_type_code = '#{downtime_type_code}' and downtime_division_code = '#{downtime_division_code}' and downtime_category_code = '#{downtime_category_code}'").map{|g|[g.external_ref]}

	external_refs.unshift("<empty>")
 end






end
