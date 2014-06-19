module Fg::RuleHelper
 
 
 def build_rule_form(rule,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:rule_form]= Hash.new
	rule_type_codes = RuleType.find_by_sql('select distinct rule_type_code from rule_types').map{|g|[g.rule_type_code]}
    if rule
      rule.rule_type_code = RuleType.find(rule.rule_type_id).rule_type_code
    end
	rule_type_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (rule_type_id) on related table: rule_types
#	-----------------------------------------------------------------------------------------------------
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'rule_type_code',
						:settings => {:list => rule_type_codes}}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'rule_code'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'rule_description'}

	field_configs[field_configs.length] = {:field_type => 'DateTimeField',
						:field_name => 'date_from'}

	field_configs[field_configs.length] = {:field_type => 'DateTimeField',
						:field_name => 'date_to'}

 
	build_form(rule,field_configs,action,'rule',caption,is_edit)

end
 
 
 def build_rule_search_form(rule,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:rule_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["rule_rule_code"])
	#Observers for search combos
 
	rule_codes = Rule.find_by_sql('select distinct rule_code from rules').map{|g|[g.rule_code]}
	rule_codes.unshift("<empty>")
	if is_flat_search
	else
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'rule_code',
						:settings => {:list => rule_codes}}
 
	build_form(rule,field_configs,action,'rule',caption,false)

end



 def build_rule_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'rule_code'}
    column_configs[1] = {:field_type => 'text',:field_name => 'rule_type.rule_type_code',:column_caption => 'rule_type'}
	column_configs[2] = {:field_type => 'text',:field_name => 'rule_description'}
	column_configs[3] = {:field_type => 'text',:field_name => 'date_from'}
	column_configs[4] = {:field_type => 'text',:field_name => 'date_to'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit rule',
			:settings =>
				 {:link_text => 'edit',
				:target_action => 'edit_rule',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete rule',
			:settings =>
				 {:link_text => 'delete',
				:target_action => 'delete_rule',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

 def build_organization_rule_form(organization_rule,action,caption)
   rule_type_codes = RuleType.find_by_sql('select distinct rule_type_code from rule_types').map{|g|[g.rule_type_code]}
	 rule_type_codes.unshift("<empty>")

   short_descriptions = Organization.find_by_sql("select distinct short_description from organizations").map {|o|[o.short_description]}
   short_descriptions.unshift("<empty>")
   
   rule_codes = ["Select a value from rule_type_codes"]

#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:organization_rule_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	on_complete_js = "\n img = document.getElementById('img_organization_rule_rule_type');"
    on_complete_js += "\n if(img != null)img.style.display = 'none';"
	#Observers for search combos
	rule_type_code_observer  = {:updated_field_id => "rule_code_cell",
					 :remote_method => 'rule_type_code_search_combo_changed',
					 :on_completed_js => on_complete_js}

	session[:organization_rule_form][:rule_type_code_observer] = rule_type_code_observer
  


   field_configs = Array.new
   field_configs[field_configs.length] = {:field_type => 'DropDownField',:field_name => 'rule_type',
						:settings => {:list => rule_type_codes},
						:observer => rule_type_code_observer}

   field_configs[field_configs.length] =  {:field_type => 'DropDownField',:field_name => 'rule_code',
						:settings => {:list => rule_codes}}

   field_configs[field_configs.length] =  {:field_type => 'DropDownField',:field_name => 'short_description',
						:settings => {:list => short_descriptions}}

   field_configs[field_configs.length] = {:field_type => 'DateTimeField',
						:field_name => 'date_from'}

	field_configs[field_configs.length] = {:field_type => 'DateTimeField',
						:field_name => 'date_to'}

   build_form(organization_rule,field_configs,action,'organization_rule',caption,false)
 end

 def find_assigned_rules_form(organization_rule,action,caption)
   rule_type_codes = RuleType.find_by_sql('select distinct rule_type_code from rule_types').map{|g|[g.rule_type_code]}
	 rule_type_codes.unshift("<empty>")

   short_descriptions = Organization.find_by_sql("select distinct short_description from organizations").map {|o|[o.short_description]}
   short_descriptions.unshift("<empty>")

   rule_codes = Rule.find_by_sql('select distinct rule_code from rules').map{|g|[g.rule_code]}
   rule_codes.unshift("<empty>")
   
   field_configs = Array.new
   field_configs[field_configs.length] = {:field_type => 'DropDownField',:field_name => 'rule_type',
						:settings => {:list => rule_type_codes}}

   field_configs[field_configs.length] =  {:field_type => 'DropDownField',:field_name => 'rule_code',
						:settings => {:list => rule_codes}}

   field_configs[field_configs.length] =  {:field_type => 'DropDownField',:field_name => 'short_description',
						:settings => {:list => short_descriptions}}

    field_configs[field_configs.length()] =  {:field_type => 'PopupDateSelector',
	                     :field_name => 'date_from',
	                     :settings => {:date_textfield_id=>'date_from_date2from'}}

    field_configs[field_configs.length()] =  {:field_type => 'PopupDateSelector',
	                     :field_name => 'date_to',
	                     :settings => {:date_textfield_id=>'date_to_date2to'}}
   build_form(organization_rule,field_configs,action,'organization_rule',caption,false)
 end

 def build_assigned_rule_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'organization.short_description',:column_caption => 'org'}
	column_configs[1] = {:field_type => 'text',:field_name => 'rule.rule_code',:column_caption => 'rule_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'date_from'}
	column_configs[3] = {:field_type => 'text',:field_name => 'date_to'}
#	----------------------
#	define action columns
#	----------------------
#	if can_edit
#		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit rule',
#			:settings =>
#				 {:link_text => 'edit',
#				:target_action => 'edit_rule',
#				:id_column => 'id'}}
#	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete rule',
			:settings =>
				 {:link_text => 'delete',
				:target_action => 'delete_assigned_rule',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end


 ##################################            ###################################
 ################################## HENRYS's   ###################################
 ##################################            ###################################
  def build_force_location_rule_form(force_location_rule,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:force_location_rule_form]= Hash.new
	locations_rules = Location.find_by_sql('select distinct location_code from locations').map{|g|[g.location_code]}
	locations_rules.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'force_from',
						:settings => {:list => locations_rules}}

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'force_to',
						:settings => {:list => locations_rules}}


	build_form(force_location_rule,field_configs,action,'force_location_rule',caption,is_edit)

  end

  def build_force_location_rule_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'force_from'}
	column_configs[1] = {:field_type => 'text',:field_name => 'force_to'}


	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit rule',
			:settings =>
				 {:link_text => 'edit',
				:target_action => 'edit_force_location_rule',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete rule',
			:settings =>
				 {:link_text => 'delete',
				:target_action => 'delete_force_location_rule',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
  end
end
