module RawMaterials::RmtVarietyQcLevelHelper
 
 
 def build_rmt_variety_qc_level_form(rmt_variety_qc_level,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:rmt_variety_qc_level_form]= Hash.new
	
	season_codes = Season.find_by_sql('select distinct(season_code) ,id from seasons order by season_code desc').map{|g|[g.season_code,g.id]}
	season_codes.unshift("<empty>")
	rmt_variety_codes = RmtVariety.find_by_sql('select distinct rmt_variety_code ,id from rmt_varieties order by rmt_variety_code desc').map{|g|[g.rmt_variety_code,g.id]}
	rmt_variety_codes.unshift("<empty>")
	
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = []
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (season_id) on related table: seasons
#	----------------------------------------------------------------------------------------------
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'season_id',
						:settings => {:list => season_codes, :label_caption=>'season code'}}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (rmt_variety_id) on related table: seasons
#	----------------------------------------------------------------------------------------------
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'rmt_variety_id',
						:settings => {:list => rmt_variety_codes, :label_caption=>'rmt variety code'}}
	
	
	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'pressure_min'}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'sugar_min'}


	build_form(rmt_variety_qc_level,field_configs,action,'rmt_variety_qc_level',caption,is_edit)

end
 
 
 def build_rmt_variety_qc_level_search_form(rmt_variety_qc_level,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:rmt_variety_qc_level_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["rmt_variety_qc_level_id","rmt_variety_qc_level_season_id","rmt_variety_qc_level_rmt_variety_id"])
	#Observers for search combos
	id_observer  = {:updated_field_id => "season_id_cell",
					 :remote_method => 'rmt_variety_qc_level_id_search_combo_changed',
					 :on_completed_js => search_combos_js["rmt_variety_qc_level_id"]}

	session[:rmt_variety_qc_level_search_form][:id_observer] = id_observer

	season_id_observer  = {:updated_field_id => "rmt_variety_id_cell",
					 :remote_method => 'rmt_variety_qc_level_season_id_search_combo_changed',
					 :on_completed_js => search_combos_js["rmt_variety_qc_level_season_id"]}

	session[:rmt_variety_qc_level_search_form][:season_id_observer] = season_id_observer

 
	ids = RmtVarietyQcLevel.find_by_sql('select distinct id from rmt_variety_qc_levels').map{|g|[g.id]}
	ids.unshift("<empty>")
	if is_flat_search
		season_ids = RmtVarietyQcLevel.find_by_sql('select distinct season_id from rmt_variety_qc_levels').map{|g|[g.season_id]}
		season_ids.unshift("<empty>")
		rmt_variety_ids = RmtVarietyQcLevel.find_by_sql('select distinct rmt_variety_id from rmt_variety_qc_levels').map{|g|[g.rmt_variety_id]}
		rmt_variety_ids.unshift("<empty>")
		id_observer = nil
		season_id_observer = nil
	else
		 season_ids = ["Select a value from id"]
		 rmt_variety_ids = ["Select a value from season_id"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = []
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'id',
						:settings => {:list => ids},
						:observer => id_observer}
 
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'season_id',
						:settings => {:list => season_ids},
						:observer => season_id_observer}
 
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'rmt_variety_id',
						:settings => {:list => rmt_variety_ids}}
 
	build_form(rmt_variety_qc_level,field_configs,action,'rmt_variety_qc_level',caption,false)

end



 def build_rmt_variety_qc_level_grid(data_set,can_edit,can_delete)

	column_configs = []
	column_configs << {:field_type => 'text',:field_name => 'season_code'}
	column_configs << {:field_type => 'text',:field_name => 'rmt_variety_code'}	
	column_configs << {:field_type => 'text',:field_name => 'pressure_min'}
	column_configs << {:field_type => 'text',:field_name => 'sugar_min'}
        column_configs << {:field_type => 'text',:field_name => 'id'}
	column_configs << {:field_type => 'text',:field_name => 'commodity_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs << {:field_type => 'action',:field_name => 'edit rmt_variety_qc_level',
			:column_caption => 'Edit',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_rmt_variety_qc_level',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs << {:field_type => 'action',:field_name => 'delete rmt_variety_qc_level',
			:column_caption => 'Delete',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_rmt_variety_qc_level',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs,nil,true)
end

end


