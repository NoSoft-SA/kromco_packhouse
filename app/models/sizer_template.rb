class SizerTemplate < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
    
	belongs_to :farm_group
	belongs_to :rmt_variety
	belongs_to :line_config
	has_many :pack_group_templates,:dependent => :destroy
 
 
   attr_accessor :template_names
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :template_name
	
	
#	=====================
#	 Complex validations:
#	=====================


def before_update
  #determine if rmt varietry changed, if so: dependent pack groups need to their
  #1) commodity_code and rmt_variety_code
  #same with template name
  
  old_record = SizerTemplate.find(self.id)
  if old_record.rmt_variety_code != self.rmt_variety_code||old_record.template_name != self.template_name
    
    self.pack_group_templates.each do |group|
     group.bypass_before_save = true
     group.commodity_code = self.commodity_code
     group.rmt_variety_code = self.rmt_variety_code
     group.sizer_template_code = self.template_name
     group.save
    end
    
  end
  
  
end


def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_group_code => self.commodity_group_code},{:commodity_code => self.commodity_code},{:rmt_variety_code => self.rmt_variety_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_rmt_variety
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:farm_group_code => self.farm_group_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_farm_group
	 end
	 
	if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:fruit_size => self.fruit_size}],self) 
	end
	
	if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:line_config_code => self.line_config_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_line_config
	 end
	 
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = SizerTemplate.find_by_commodity_code_and_rmt_variety_code_and_fruit_size_and_color_sorting_and_line_config_code(self.commodity_code,self.rmt_variety_code,self.fruit_size,self.color_sorting,self.line_config_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'commodity_code' and 'rmt_variety_code' and 'fruit_size' and 'color_sorting' and 'line_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_farm_group

	farm_group = FarmGroup.find_by_farm_group_code(self.farm_group_code)
	 if farm_group != nil 
		 self.farm_group = farm_group
		 return true
	 else
		errors.add_to_base("'farm_group_code'  is invalid- not found")
		 return false
	end
end

def set_line_config

	line_config = LineConfig.find_by_line_config_code(self.line_config_code)
	 if line_config != nil 
		 self.line_config = line_config
		 return true
	 else
		errors.add_to_base("'line_config_code is invalid- it must be unique")
		 return false
	end
end

 
def set_rmt_variety

	rmt_variety = RmtVariety.find_by_commodity_group_code_and_commodity_code_and_rmt_variety_code(self.commodity_group_code,self.commodity_code,self.rmt_variety_code)
	 if rmt_variety != nil 
		 self.rmt_variety = rmt_variety
		 return true
	 else
		errors.add_to_base("combination of: 'commodity_group_code' and 'commodity_code' and 'rmt_variety_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: farm_group_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_farm_group_codes

	farm_group_codes = FarmGroup.find_by_sql('select distinct farm_group_code from farm_groups').map{|g|[g.farm_group_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: rmt_variety_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_group_codes

	commodity_group_codes = RmtVariety.find_by_sql('select distinct commodity_group_code from rmt_varieties').map{|g|[g.commodity_group_code]}
end



def self.get_all_commodity_codes

	commodity_codes = RmtVariety.find_by_sql('select distinct commodity_code from rmt_varieties').map{|g|[g.commodity_code]}
end



def self.commodity_codes_for_commodity_group_code(commodity_group_code)

	commodity_codes = RmtVariety.find_by_sql("Select distinct commodity_code from rmt_varieties where commodity_group_code = '#{commodity_group_code}'").map{|g|[g.commodity_code]}

	commodity_codes.unshift("<empty>")
 end



def self.get_all_rmt_variety_codes

	rmt_variety_codes = RmtVariety.find_by_sql('select distinct rmt_variety_code from rmt_varieties').map{|g|[g.rmt_variety_code]}
end



def self.rmt_variety_codes_for_commodity_code_and_commodity_group_code(commodity_code, commodity_group_code)

	rmt_variety_codes = RmtVariety.find_by_sql("Select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.rmt_variety_code]}

	rmt_variety_codes.unshift("<empty>")
 end






end
