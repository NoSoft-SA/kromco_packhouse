module Production::ProductionScheduleHelper
 
     
 def build_production_schedule_view_form(production_schedule)
    
     field_configs = Array.new
     
	 field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_name'}
	
	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'season_code'}
  
#	-------------------------------------------------------------------------------
#	Combo fields to represent foreign key (iso_week_id) on related table: iso_weeks
#	-------------------------------------------------------------------------------

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'iso_week_code'}


	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'planned_start_date'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'planned_end_date'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'farm_group_code'}


	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'farm_pack'}
	

	build_form(production_schedule,field_configs,"list_production_schedules",'production_schedule',"back")
  
 end
 
 def build_production_schedule_form(production_schedule,action,caption,is_edit = nil,is_create_retry = nil,cloning = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:production_schedule_form]= Hash.new
	iso_week_codes = IsoWeek.find_by_sql('select distinct iso_week_code from iso_weeks order by iso_week_code asc').map{|g|[g.iso_week_code]}
	
	season_codes = Season.find_by_sql('select distinct season_code from seasons').map{|g|[g.season_code]}
	
	farm_group_codes = FarmGroup.find_by_sql('select distinct farm_group_code from farm_groups').map{|g|[g.farm_group_code]}
	 
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new

    if is_edit
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_name'}
	end
#	----------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (season_id) on related table: seasons
#	----------------------------------------------------------------------------------------------
	if !is_edit 
	   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'season_code',
						:settings => {:list => season_codes}}
 
#	----------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (iso_week_id) on related table: iso_weeks
#	----------------------------------------------------------------------------------------------
	   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'iso_week_code',
						:settings => {:list => iso_week_codes}}
    end

	field_configs[field_configs.length()] = {:field_type => 'PopupDateSelector',
						:field_name => 'planned_start_date'}

	field_configs[field_configs.length()] = {:field_type => 'PopupDateSelector',
						:field_name => 'planned_end_date'}
    
    if !production_schedule||cloning
	  field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'farm_group_code',
						:settings => {:list => farm_group_codes}}
	else
	
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'farm_group_code'}
	
	end
    
   
    production_schedule = ProductionSchedule.new if ! production_schedule
    @production_schedule = production_schedule
    production_schedule.farm_pack = true

	field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'farm_pack'}
						
	
	if cloning
	 #add controls for ripe_point_code,class_code and size_code
	 size_codes = Size.find_by_sql('select distinct size_code from sizes').map{|g|[g.size_code]}
	 size_codes.unshift("<empty>")
	
	 ripe_point_codes = RipePoint.find_by_sql('select distinct ripe_point_code from ripe_points').map{|g|[g.ripe_point_code]}
	 ripe_point_codes.unshift("<empty>")
	 product_class_codes = ProductClass.find_by_sql('select distinct product_class_code from product_classes').map{|g|[g.product_class_code]}
	 product_class_codes.unshift("<empty>")
	 
	 #NAE 2015-05-14 add treatment_codes dropdown
	 treatment_codes = Treatment.find_by_sql('select distinct treatment_code from treatments').map{|g|[g.treatment_code]}
	 treatment_codes.unshift("<empty>")
	 
	 production_schedule.class_code = production_schedule.rmt_setup.product_class_code
	 production_schedule.ripe_point_code = production_schedule.rmt_setup.ripe_point_code
	 production_schedule.size_code = production_schedule.rmt_setup.size_code 
	 production_schedule.rmt_type = production_schedule.rmt_setup.rmt_product.rmt_product_type_code
	 production_schedule.source_rmt_product = production_schedule.rmt_setup.rmt_product.rmt_product_code
	 
	 #NAE 2015-05-14 add treatment_codes dropdown
         production_schedule.treatment_code = production_schedule.rmt_setup.rmt_product.treatment_code
	 
	 query = "SELECT 
             public.pack_material_products.pack_material_product_code
             FROM
             public.pack_material_sub_types
             INNER JOIN public.pack_material_types ON (public.pack_material_sub_types.pack_material_type_id = public.pack_material_types.id)
             INNER JOIN public.pack_material_products ON (public.pack_material_sub_types.id = public.pack_material_products.pack_material_sub_type_id)
             WHERE
            (public.pack_material_types.pack_material_type_code = 'RMU')"
	
	
	 bin_types = PackMaterialProduct.find_by_sql(query).map{|b|b.pack_material_product_code}
	 
	 rmt_types = ["orchard_run","rebin","presort"]
	 
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_name',:settings => {:label_caption => "source_schedule"}}
	 
	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'source_rmt_product'}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'rmt_type',:settings => {:label_caption => "source rmt type"}}
						
	 field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'ripe_point_code',
						:settings => {:list => ripe_point_codes}}
	
	 field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'class_code',
						:settings => {:list => product_class_codes}}
						
	  field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'size_code',
						:settings => {:list => size_codes}}
	
	  field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'rmt_type',
						:settings => {:list => rmt_types}}
						
	 field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'bin_type',
						:settings => {:list => bin_types}}
	#NAE 2015-05-14 add treatment_codes dropdown
	 field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'treatment_code',
						:settings => {:list => treatment_codes}}						
																
	end
	

	build_form(production_schedule,field_configs,action,'production_schedule',caption,is_edit)

end
 
 
 def build_extended_search_form
  
  @production_schedule = ProductionSchedule.new

  season_codes = []
	season_codes.concat ProductionSchedule.find_by_sql('select distinct season_code from production_schedules').map{|g|[g.season_code]}

	
  iso_week_codes = []
	iso_week_codes.concat ProductionSchedule.find_by_sql('select distinct iso_week_code from production_schedules').map{|g|[g.iso_week_code]}
	
	varieties = []
	varieties.concat RmtSetup.find_by_sql('select distinct variety_code from rmt_setups').map{|g|[g.variety_code]}
	
	pc_codes = []
	pc_codes.concat RmtSetup.find_by_sql('select distinct pc_code from rmt_setups').map{|g|[g.pc_code]}
	
	indicators = []
	indicators.concat RmtSetup.find_by_sql('select distinct track_indicator_code from rmt_setups where track_indicator_code is not null' ).map{|g|[g.track_indicator_code]}
	
	farm_groups = []
	farm_groups.concat ProductionSchedule.find_by_sql('select farm_group_code from farm_groups').map{|g|[g.farm_group_code]}
	
	production_schedule_status_codes = []
	production_schedule_status_codes.concat ProductionSchedule.find_by_sql('select distinct production_schedule_status_code from production_schedules').map{|g|[g.production_schedule_status_code]}
    
    organization_marketing_codes = []
    organization_marketing_codes.concat TradeEnvironmentSetup.find_by_sql('select distinct organization_marketing from trade_environment_setups').map{|g|[g.organization_marketing]}
	
	organization_retailer_codes = []
	organization_retailer_codes.concat TradeEnvironmentSetup.find_by_sql('select distinct organization_retailer from trade_environment_setups').map{|g|[g.organization_retailer]}
	
	mark_retail_unit_description_codes = []
	mark_retail_unit_description_codes.concat TradeEnvironmentSetup.find_by_sql('select distinct mark_retail_unit_description from trade_environment_setups').map{|g|[g.mark_retail_unit_description]}
	
	target_market_description_codes = []
	target_market_description_codes.concat TradeEnvironmentSetup.find_by_sql('select distinct target_market_description from trade_environment_setups').map{|g|[g.target_market_description]}
	
	template_names = []
	template_names.concat ProductionSchedule.find_by_sql('select distinct template_name from production_schedules').map{|g|[g.template_name]}
	template_names.each do |t| puts t.class.to_s end





#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'season_code',
						:settings => {:list => season_codes}}

 
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'iso_week_code',
						:settings => {:list => iso_week_codes}}

 
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'variety_code',
						:settings => {:list => varieties}}

						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'pc_code',
						:settings => {:list => pc_codes}}

						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'track_indicator_code',
						:settings => {:list => indicators}}

 
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'farm_group_code',
						:settings => {:list => farm_groups}}

						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'production_schedule_status_code',
						:settings => {:list => production_schedule_status_codes}}

						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'organization_marketing',
						:settings => {:list => organization_marketing_codes}}

						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'organization_retailer',
						:settings => {:list => organization_retailer_codes}}

						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'mark_retail_unit_description',
						:settings => {:list => mark_retail_unit_description_codes}}

						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'target_market_description',
						:settings => {:list => target_market_description_codes}}

						
						
 
	build_form(nil,field_configs,'submit_extended_search','production_schedule','search',false)
 
 
 end
 
 
 def build_production_schedule_search_form(production_schedule,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:production_schedule_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["production_schedule_season_code","production_schedule_iso_week_code","production_schedule_variety","production_schedule_farm_group"])
	#Observers for search combos
	season_code_observer  = {:updated_field_id => "iso_week_code_cell",
					 :remote_method => 'production_schedule_season_code_search_combo_changed',
					 :on_completed_js => search_combos_js["production_schedule_season_code"]}

	session[:production_schedule_search_form][:season_code_observer] = season_code_observer

	iso_week_code_observer  = {:updated_field_id => "variety_cell",
					 :remote_method => 'production_schedule_iso_week_code_search_combo_changed',
					 :on_completed_js => search_combos_js["production_schedule_iso_week_code"]}

	session[:production_schedule_search_form][:iso_week_code_observer] = iso_week_code_observer

	variety_observer  = {:updated_field_id => "farm_group_cell",
					 :remote_method => 'production_schedule_variety_search_combo_changed',
					 :on_completed_js => search_combos_js["production_schedule_variety"]}

	session[:production_schedule_search_form][:variety_observer] = variety_observer

 
	season_codes = ProductionSchedule.find_by_sql('select distinct season_code from production_schedules').map{|g|[g.season_code]}
	season_codes.unshift("<empty>")
	if is_flat_search
		iso_week_codes = ProductionSchedule.find_by_sql('select distinct iso_week_code from production_schedules').map{|g|[g.iso_week_code]}
		iso_week_codes.unshift("<empty>")
		varieties = RmtSetup.find_by_sql('select distinct variety_code from rmt_setups').map{|g|[g.variety_code]}
		varieties.unshift("<empty>")
		farm_groups = ProductionSchedule.find_by_sql('select distinct farm_group_code from production_schedules').map{|g|[g.farm_group_code]}
		farm_groups.unshift("<empty>")
		season_code_observer = nil
		iso_week_code_observer = nil
		variety_observer = nil
	else
		 iso_week_codes = ["Select a value from season_code"]
		 varieties = ["Select a value from iso_week_code"]
		 farm_groups = ["Select a value from variety"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'season_code',
						:settings => {:list => season_codes},
						:observer => season_code_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'iso_week_code',
						:settings => {:list => iso_week_codes},
						:observer => iso_week_code_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'variety_code',
						:settings => {:list => varieties},
						:observer => variety_observer}

   field_configs[field_configs.length()] = {:field_type =>'PopupDateRangeSelector',
              :field_name =>'planned_start_date'}
 
	field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'farm_group_code',
						:settings => {:list => farm_groups}}
                    
     field_configs[5] =  {:field_type => 'TextField',
						:field_name => 'production_schedule_name'}

     
 
	build_form(production_schedule,field_configs,action,'production_schedule',caption,false)

end

def build_production_schedule_grid(data_set,can_edit,can_delete)

   # require File.dirname(__FILE__) + "/../../../app/helpers/production/schedule_setup_plugin.rb"

   column_configs = Array.new
   #if can_edit
   column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'production_schedule_name',:col_width => 207,
                                              :settings =>
                                                  {:target_action => 'set_active_schedule',
                                                   :id_column => 'id'}}
   #else
   # column_configs[0] = {:field_type => 'text',:field_name => 'production_schedule_name'}
   #end

   is_extended_search = data_set[0].has_attribute?('pc_code')
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'planned_start_date',:col_width => 138}
   if is_extended_search
     column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'variety',:col_width => 65}
     column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'track_indicator_code',:col_width => 72,:column_caption => 'ti'}
     column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'pc_code',:col_width => 65}
     column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'product_class_code',:column_caption => 'class_code',:col_width => 50}
   end
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'production_schedule_status_code',:col_width => 82,:column_caption => 'status'}

#	----------------------
#	define action columns
#	----------------------
   if can_edit
     column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit', :col_width => 50,
                                                :settings =>
                                                    {:image => 'edit',
                                                     :target_action => 'edit_production_schedule',
                                                     :id_column => 'id'}}


     column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'clone',:col_width => 50,
                                                :settings =>
                                                    {:image => 'clone_schedule',
                                                     :target_action => 'clone_schedule',
                                                     :id_column => 'id'}}

#		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'make template',
#			:settings =>
#				 {:image => 'save_as_template',
#				:target_action => 'save_as_template',
#				:id_column => 'id'}}

     column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 're-open',:col_width => 50,
                                                :settings =>
                                                    {:image => 'folder_open',
                                                     :target_action => 're_open_production_schedule',
                                                     :id_column => 'id'}}

     column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'complete',:col_width => 50,
                                                :settings =>
                                                    {:image => 'complete',
                                                     :target_action => 'complete_production_schedule',
                                                     :id_column => 'id'},:html_options => {:prompt => "Are you sure you want to complete this schedule?"}}
   end

   if can_delete
     column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete',:col_width => 50,
                                                :settings =>
                                                    {:image => 'delete',
                                                     :target_action => 'delete_production_schedule',
                                                     :id_column => 'id'},:html_options => {:prompt => "This delete will cascade to all data associated with the schedule. Are you sure you want to do this?"}}
   end

   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'farm_group_code',:col_width => 135}
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'iso_week_code',:col_width => 50,:column_caption => '50'}
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'season_code',:col_width => 78}
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'farm_pack',:col_width => 80}

   set_grid_min_height(10325)
   set_grid_min_width(7000)
   return get_data_grid(data_set, column_configs, MesScada::GridPlugins::Production::ScheduleSetupGridPlugin.new,true)

end

end
