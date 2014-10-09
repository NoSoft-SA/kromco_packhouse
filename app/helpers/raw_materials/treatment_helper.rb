module RawMaterials::TreatmentHelper
 
 
 #==================
 #SPRAY PROGRAM CODE
 #==================
 def build_spray_program_form(spray_program,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:spray_program_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'spray_program_code'}

	build_form(spray_program,field_configs,action,'spray_program',caption,is_edit)

end
 
 
 def build_spray_program_search_form(spray_program,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:spray_program_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	spray_program_codes = SprayProgram.find_by_sql('select distinct spray_program_code from spray_programs').map{|g|[g.spray_program_code]}
	spray_program_codes.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'spray_program_code',
						:settings => {:list => spray_program_codes}}

	build_form(spray_program,field_configs,action,'spray_program',caption,false)

end



 def build_spray_program_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'spray_program_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit spray_program',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_spray_program',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete spray_program',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_spray_program',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

 #=========
 #PC CODES
 #=========
 def build_pc_code_form(pc_code,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:pc_code_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'pc_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'pc_name'}

	build_form(pc_code,field_configs,action,'pc_code',caption,is_edit)

end
 
 
 def build_pc_code_search_form(pc_code,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:pc_code_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["pc_code_pc_code"])
	#Observers for search combos
 
	pc_codes = PcCode.find_by_sql('select distinct pc_code from pc_codes').map{|g|[g.pc_code]}
	pc_codes.unshift("<empty>")
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
						:field_name => 'pc_code',
						:settings => {:list => pc_codes}}
 
	build_form(pc_code,field_configs,action,'pc_code',caption,false)

end



 def build_pc_code_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'pc_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'pc_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit pc_code',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_pc_code',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete pc_code',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_pc_code',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 #===================
 #COSMETIC CODE
 #===================
 def build_cosmetic_code_form(cosmetic_code,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:cosmetic_code_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'cosmetic_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'cosmetic_description'}

	build_form(cosmetic_code,field_configs,action,'cosmetic_code',caption,is_edit)

end
 
 
 def build_cosmetic_code_search_form(cosmetic_code,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:cosmetic_code_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["cosmetic_code_cosmetic_code"])
	#Observers for search combos
 
	cosmetic_codes = CosmeticCode.find_by_sql('select distinct cosmetic_code from cosmetic_codes').map{|g|[g.cosmetic_code]}
	cosmetic_codes.unshift("<empty>")
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
						:field_name => 'cosmetic_code',
						:settings => {:list => cosmetic_codes}}
 
	build_form(cosmetic_code,field_configs,action,'cosmetic_code',caption,false)

end



 def build_cosmetic_code_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'cosmetic_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'cosmetic_description'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit cosmetic_code',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_cosmetic_code',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete cosmetic_code',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_cosmetic_code',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 #================
 #COLD STORE TYPE
 #================
 def build_cold_store_type_form(cold_store_type,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:cold_store_type_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'cold_store_type_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'cold_store_name'}

	build_form(cold_store_type,field_configs,action,'cold_store_type',caption,is_edit)

end
 
 
 def build_cold_store_type_search_form(cold_store_type,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:cold_store_type_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["cold_store_type_cold_store_type_code"])
	#Observers for search combos
 
	cold_store_type_codes = ColdStoreType.find_by_sql('select distinct cold_store_type_code from cold_store_types').map{|g|[g.cold_store_type_code]}
	cold_store_type_codes.unshift("<empty>")
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
						:field_name => 'cold_store_type_code',
						:settings => {:list => cold_store_type_codes}}
 
	build_form(cold_store_type,field_configs,action,'cold_store_type',caption,false)

end



 def build_cold_store_type_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'cold_store_type_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'cold_store_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit cold_store_type',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_cold_store_type',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete cold_store_type',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_cold_store_type',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 #=================
 #RIPE POINT CODE
 #=================
 def build_ripe_point_form(ripe_point,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:ripe_point_form]= Hash.new
	cold_store_type_codes = ColdStoreType.find_by_sql('select distinct cold_store_type_code from cold_store_types').map{|g|[g.cold_store_type_code]}
	cold_store_type_codes.unshift("<empty>")
	pc_codes = PcCode.find_by_sql('select distinct pc_code from pc_codes').map{|g|[g.pc_code]}
	pc_codes.unshift("<empty>")
	#generate javascript for the on_complete ajax event for each combo for fk table: treatments
	combos_js_for_treatments = gen_combos_clear_js_for_combos(["ripe_point_treatment_type_code","ripe_point_treatment_code"])
	#Observers for combos representing the key fields of fkey table: treatment_id
	treatment_type_code_observer  = {:updated_field_id => "treatment_code_cell",
					 :remote_method => 'ripe_point_treatment_type_code_changed',
					 :on_completed_js => combos_js_for_treatments ["ripe_point_treatment_type_code"]}

	session[:ripe_point_form][:treatment_type_code_observer] = treatment_type_code_observer
	
	combos_js_for_treatments2 = gen_combos_clear_js_for_combos(["ripe_point_treatment2_type_code","ripe_point_treatment2_code"])
	treatment2_type_code_observer  = {:updated_field_id => "treatment2_code_cell",
					 :remote_method => 'ripe_point_treatment2_type_code_changed',
					 :on_completed_js => combos_js_for_treatments2["ripe_point_treatment2_type_code"]}

#	combo lists for table: treatments

	treatment_type_codes = nil 
	treatment_codes = nil 
    treatment2_codes = nil
    
    ripe_times = RipeTime.find(:all).map {|r|r.ripe_code}
	ripe_times.unshift("<empty>")
    
	treatment_type_codes = RipePoint.get_all_treatment_type_codes
	treatment_type_codes.unshift("<empty>")
	if ripe_point == nil||is_create_retry
		 treatment_codes = ["Select a value from treatment_type_code"]
		 treatment2_codes = ["Select a value from treatment_type_code"]
	else
	    treatment_codes = RipePoint.treatment_codes_for_treatment_type_code(ripe_point.treatment.treatment_type_code)
		treatment2_codes = RipePoint.treatment_codes_for_treatment_type_code(ripe_point.treatment2_type_code)
	end
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'ripe_point_code'}


	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'ripe_point_description'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (pc_code_id) on related table: pc_codes
#	----------------------------------------------------------------------------------------------
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'pc_code_code',
						:settings => {:list => pc_codes,:label_caption => "pc_code"}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (cold_store_type_id) on related table: cold_store_types
#	----------------------------------------------------------------------------------------------
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'cold_store_type_code',
						:settings => {:list => cold_store_type_codes}}
 
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (treatment_id) on related table: treatments
#	----------------------------------------------------------------------------------------------
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'treatment_type_code',
						:settings => {:list => treatment_type_codes},
						:observer => treatment_type_code_observer}
 
	field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'treatment_code',
						:settings => {:list => treatment_codes}}
						
	field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'treatment2_type_code',
						:settings => {:list => treatment_type_codes},
						:observer => treatment2_type_code_observer}
 
	field_configs[7] =  {:field_type => 'DropDownField',
						:field_name => 'treatment2_code',
						:settings => {:list => treatment2_codes}}
						
	field_configs[8] =  {:field_type => 'DropDownField',
						:field_name => 'ripe_code',
						:settings => {:list => ripe_times,
						              :label_caption => "ripe_time"}}
 
	build_form(ripe_point,field_configs,action,'ripe_point',caption,is_edit)

 end

 def build_ripe_point_view_form(ripe_point)
   #	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[field_configs.length] = {:field_type => 'LabelField',
						:field_name => 'ripe_point_code'}


	field_configs[field_configs.length] = {:field_type => 'LabelField',
						:field_name => 'ripe_point_description'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (pc_code_id) on related table: pc_codes
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length] =  {:field_type => 'LabelField',
						:field_name => 'pc_code_code'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (cold_store_type_id) on related table: cold_store_types
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length] =  {:field_type => 'LabelField',
						:field_name => 'cold_store_type_code'}

	field_configs[field_configs.length] =  {:field_type => 'LabelField',
						:field_name => 'treatment_type_code'}

	field_configs[field_configs.length] =  {:field_type => 'LabelField',
						:field_name => 'treatment_code'}

	field_configs[field_configs.length] =  {:field_type => 'LabelField',
						:field_name => 'treatment2_type_code'}

	field_configs[field_configs.length] =  {:field_type => 'LabelField',
						:field_name => 'treatment2_code'}

	field_configs[field_configs.length] =  {:field_type => 'LabelField',
						:field_name => 'ripe_code'}

	build_form(ripe_point,field_configs,nil,'ripe_point','')
 end
 
 
 def build_ripe_point_search_form(ripe_point,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:ripe_point_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["ripe_point_treatment_code","ripe_point_cold_store_type_code","ripe_point_pc_code_code","ripe_point_ripe_point_code"])
	#Observers for search combos
	treatment_code_observer  = {:updated_field_id => "cold_store_type_code_cell",
					 :remote_method => 'ripe_point_treatment_code_search_combo_changed',
					 :on_completed_js => search_combos_js["ripe_point_treatment_code"]}

	session[:ripe_point_search_form][:treatment_code_observer] = treatment_code_observer

	cold_store_type_code_observer  = {:updated_field_id => "pc_code_code_cell",
					 :remote_method => 'ripe_point_cold_store_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["ripe_point_cold_store_type_code"]}

	session[:ripe_point_search_form][:cold_store_type_code_observer] = cold_store_type_code_observer

	pc_code_code_observer  = {:updated_field_id => "ripe_point_code_cell",
					 :remote_method => 'ripe_point_pc_code_code_search_combo_changed',
					 :on_completed_js => search_combos_js["ripe_point_pc_code_code"]}

	session[:ripe_point_search_form][:pc_code_code_observer] = pc_code_code_observer

 
	treatment_codes = RipePoint.find_by_sql('select distinct treatment_code from ripe_points').map{|g|[g.treatment_code]}
	treatment_codes.unshift("<empty>")
	if is_flat_search
		cold_store_type_codes = RipePoint.find_by_sql('select distinct cold_store_type_code from ripe_points').map{|g|[g.cold_store_type_code]}
		cold_store_type_codes.unshift("<empty>")
		pc_code_codes = RipePoint.find_by_sql('select distinct pc_code_code from ripe_points').map{|g|[g.pc_code_code]}
		pc_code_codes.unshift("<empty>")
		ripe_point_codes = RipePoint.find_by_sql('select distinct ripe_point_code from ripe_points').map{|g|[g.ripe_point_code]}
		ripe_point_codes.unshift("<empty>")
		treatment_code_observer = nil
		cold_store_type_code_observer = nil
		pc_code_code_observer = nil
	else
		 cold_store_type_codes = ["Select a value from treatment_code"]
		 pc_code_codes = ["Select a value from cold_store_type_code"]
		 ripe_point_codes = ["Select a value from pc_code_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'treatment_code',
						:settings => {:list => treatment_codes},
						:observer => treatment_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'cold_store_type_code',
						:settings => {:list => cold_store_type_codes},
						:observer => cold_store_type_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'pc_code_code',
						:settings => {:list => pc_code_codes,:label_caption => "pc_code"},
						:observer => pc_code_code_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'ripe_point_code',
						:settings => {:list => ripe_point_codes}}
 
	build_form(ripe_point,field_configs,action,'ripe_point',caption,false)

end



 def build_ripe_point_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'ripe_point_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'cold_store_type_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'treatment_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'pc_code_code'}
	column_configs[4] = {:field_type => 'text',:field_name => 'pc_code_code'}
	column_configs[5] = {:field_type => 'text',:field_name => 'ripe_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit ripe_point',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_ripe_point',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete ripe_point',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_ripe_point',
				:id_column => 'id'}}
  end

  column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view ripe_point',
    :settings =>
       {:link_text => 'view',
      :target_action => 'view_ripe_point',
      :id_column => 'id'}}
   
 return get_data_grid(data_set,column_configs)
end
 
 #======================
 #TREATMENT TYPE CODE
 #======================
 
 def build_treatment_type_form(treatment_type,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:treatment_type_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'treatment_type_code'}

	build_form(treatment_type,field_configs,action,'treatment_type',caption,is_edit)

end
 
 
 def build_treatment_type_search_form(treatment_type,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:treatment_type_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["treatment_type_treatment_type_code"])
	#Observers for search combos
 
	treatment_type_codes = TreatmentType.find_by_sql('select distinct treatment_type_code from treatment_types').map{|g|[g.treatment_type_code]}
	treatment_type_codes.unshift("<empty>")
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
						:field_name => 'treatment_type_code',
						:settings => {:list => treatment_type_codes}}
 
	build_form(treatment_type,field_configs,action,'treatment_type',caption,false)

end



 def build_treatment_type_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'treatment_type_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit treatment_type',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_treatment_type',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete treatment_type',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_treatment_type',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 #=======================
 #TREATMENTS CODE
 #=======================
 def build_treatment_form(treatment,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:treatment_form]= Hash.new
	treatment_type_codes = TreatmentType.find_by_sql('select distinct treatment_type_code from treatment_types').map{|g|[g.treatment_type_code]}
	treatment_type_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'treatment_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'description'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (treatment_type_id) on related table: treatment_types
#	----------------------------------------------------------------------------------------------
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'treatment_type_code',
						:settings => {:list => treatment_type_codes}}
						
	field_configs[3] = {:field_type => 'TextField',
						:field_name => 'ranking'}						
 
	build_form(treatment,field_configs,action,'treatment',caption,is_edit)

end
 
 
 def build_treatment_search_form(treatment,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:treatment_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["treatment_treatment_type_code","treatment_treatment_code"])
	#Observers for search combos
	treatment_type_code_observer  = {:updated_field_id => "treatment_code_cell",
					 :remote_method => 'treatment_treatment_type_code_search_combo_changed',
					 :on_completed_js => search_combos_js["treatment_treatment_type_code"]}

	session[:treatment_search_form][:treatment_type_code_observer] = treatment_type_code_observer

 
	treatment_type_codes = Treatment.find_by_sql('select distinct treatment_type_code from treatments').map{|g|[g.treatment_type_code]}
	treatment_type_codes.unshift("<empty>")
	if is_flat_search
		treatment_codes = Treatment.find_by_sql('select distinct treatment_code from treatments').map{|g|[g.treatment_code]}
		treatment_codes.unshift("<empty>")
		treatment_type_code_observer = nil
	else
		 treatment_codes = ["Select a value from treatment_type_code"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'treatment_type_code',
						:settings => {:list => treatment_type_codes},
						:observer => treatment_type_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'treatment_code',
						:settings => {:list => treatment_codes}}
 
	build_form(treatment,field_configs,action,'treatment',caption,false)

end



 def build_treatment_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'treatment_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'treatment_type_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'description'}
	column_configs[3] = {:field_type => 'text',:field_name => 'ranking'}	
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit treatment',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_treatment',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete treatment',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_treatment',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

end
