module Production::TradeEnvironmentSetupHelper
 
 def build_trade_environment_setup_view(trade_environment_setup)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	

    field_configs = Array.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'trade_env_code'}
						
	field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'organization_marketing'}
						

	field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'organization_intake'}

	field_configs[3] = {:field_type => 'LabelField',
						:field_name => 'organization_retailer'}

	field_configs[4] = {:field_type => 'LabelField',
						:field_name => 'mark_fruit_description'}

	field_configs[5] = {:field_type => 'LabelField',
						:field_name => 'mark_retail_unit_description'}

	field_configs[6] = {:field_type => 'LabelField',
						:field_name => 'mark_trade_unit_description'}

	field_configs[7] = {:field_type => 'LabelField',
						:field_name => 'target_market_description'}

	field_configs[8] = {:field_type => 'LabelField',
						:field_name => 'qc_grade_description'}


	field_configs[9] =  {:field_type => 'LabelField',
						:field_name => 'qc_destination_country_code'}

 
	field_configs[10] = {:field_type => 'LabelField',
						:field_name => 'qc_inspection_type'}

	field_configs[11] = {:field_type => 'LabelField',
						:field_name => 'sell_by_code'}
  
  
	build_form(trade_environment_setup,field_configs,"view_paging_handler",'trade_environment_setup',"back")

end
 
 def build_trade_environment_setup_form(trade_environment_setup,action,caption,is_edit = nil,is_create_retry = nil,marketer = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:trade_environment_setup_form]= Hash.new
	on_complete_js =  "img_trade_environment_setup_organization_marketing"
	on_complete_js = "\n img = document.getElementById('img_trade_environment_setup_organization_marketing');"
	on_complete_js += "\n if(img != null)img.style.display = 'none';"
	
	#Observers for search combos
	marketer_org_observer  = {:updated_field_id => "ajax_distributor_cell",
					 :remote_method => 'marketer_org_combo_changed',
					 :on_completed_js => on_complete_js}
	
	retailer_org_js = "\n img = document.getElementById('img_trade_environment_setup_organization_retailer');"
	retailer_org_js += "\n if(img != null)img.style.display = 'none';"
					 
	retailer_org_observer  = {:updated_field_id => "empty_shell",
					 :remote_method => 'retailer_org_combo_changed',
					 :on_completed_js => retailer_org_js}
	
	grade_js = gen_combos_clear_js_for_combos(["trade_environment_setup_qc_grade_description","trade_environment_setup_qc_inspection_type"])				 
	grade_observer  = {:updated_field_id => "qc_inspection_type_cell",
					 :remote_method => 'grade_combo_changed',
					 :on_completed_js => grade_js["trade_environment_setup_qc_grade_description"]}
					 
					 
	intake_org_js = "\n img = document.getElementById('img_trade_environment_setup_organization_intake');"
	intake_org_js += "\n if(img != null)img.style.display = 'none';"
					 
	intake_org_observer  = {:updated_field_id => "empty_shell",
					 :remote_method => 'intake_org_combo_changed',
					 :on_completed_js => intake_org_js}
	
	
	
	destination_country_codes = DestinationCountry.find_by_sql('select distinct destination_country_code from destination_countries').map{|g|[g.destination_country_code]}
	destination_country_codes.unshift("<empty>")
	
	account_codes = ["select a value from marketing org"]
    
    marketing_org_codes = Organization.get_all_by_role("MARKETER")
    marketing_org_codes.unshift("<empty>")
    retail_org_codes = Organization.get_all_by_role("RETAILER")
    retail_org_codes.unshift("<empty>")
    intake_org_codes = Organization.get_all_by_role("SUPPLIER")
    intake_org_codes.unshift("<empty>")
    grade_codes = Grade.find(:all).map{|g| [g.grade_code]}
    grade_codes.unshift("<empty>")
    
    sell_by_codes = nil
    target_market_codes = nil
    fruit_marks = nil
    retail_marks = nil
    trade_unit_marks = nil
    
    if trade_environment_setup == nil
      sell_by_codes = ["select value from marketing org  and retailer org"]
      target_market_codes = ["select value from marketing org"]
      fruit_marks = ["select values from orgs: intake, retailer and marketing"]
      retail_marks = ["select values from orgs: intake, retailer and marketing"]
      trade_unit_marks = ["select values from orgs: intake, retailer and marketing"]
      inspection_type_codes = ["select a value from qc_qc_grade_description"]
    else
      sell_by_codes = Organization.get_sell_bys_by_org("RETAILER",trade_environment_setup.organization_retailer)
      target_market_codes = TargetMarket.get_all_by_org(trade_environment_setup.organization_marketing)
      fruit_marks = Mark.get_all_for_org(trade_environment_setup.organization_marketing)
      retail_marks = Mark.get_all_for_org(trade_environment_setup.organization_retailer)
      trade_unit_marks = Mark.get_all_for_org(trade_environment_setup.organization_marketing)
      inspection_type_codes = InspectionType.find_all_by_grade_code_and_for_internal_hg_inspections_only(trade_environment_setup.qc_grade_description,false).map{|g|[g.inspection_type_code]}
      account_codes = TradeEnvironmentSetup.accounts_for_role_and_org("MARKETER",trade_environment_setup.organization_marketing).map{|g|[g.account_code]}
      account_codes.unshift("<empty>")
    end

    field_configs = Array.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'trade_env_code'}
	
	field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'organization_intake',
						:settings => {:list => intake_org_codes},
						:observer => intake_org_observer}

	field_configs[2] = {:field_type => 'DropDownField',
						:field_name => 'organization_retailer',
						:settings => {:list => retail_org_codes},
						:observer => retailer_org_observer}
						
	field_configs[3] = {:field_type => 'DropDownField',
						:field_name => 'organization_marketing',
						:settings => {:list => marketing_org_codes},
						:observer => marketer_org_observer}
						

	field_configs[4] = {:field_type => 'DropDownField',
						:field_name => 'mark_fruit_description',
						:settings => {:list => fruit_marks}}

	field_configs[5] = {:field_type => 'DropDownField',
						:field_name => 'mark_retail_unit_description',
						:settings => {:list => retail_marks}}

	field_configs[6] = {:field_type => 'DropDownField',
						:field_name => 'mark_trade_unit_description',
						:settings => {:list => trade_unit_marks}}

	field_configs[7] = {:field_type => 'DropDownField',
						:field_name => 'target_market_description',
						:settings => {:list => target_market_codes}}

	field_configs[8] = {:field_type => 'DropDownField',
						:field_name => 'qc_grade_description',
						:settings => {:list => grade_codes},
						:observer => grade_observer}

#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (destination_country_id) on related table: destination_countries
#	-----------------------------------------------------------------------------------------------------
	field_configs[9] =  {:field_type => 'DropDownField',
						:field_name => 'qc_destination_country_code',
						:settings => {:list => destination_country_codes}}

	field_configs[10] = {:field_type => 'DropDownField',
						:field_name => 'qc_inspection_type',
						:settings => {:list => inspection_type_codes}}

	field_configs[11] = {:field_type => 'TextField',
						:field_name => 'sell_by_code'}
						
    field_configs[12] = {:field_type => 'DropDownField',
						:field_name => 'account_code',
						:settings => {:list => account_codes}}
  
  #workaround needed to effect multiple updates from a single observer
   field_configs[13] = {:field_type => 'HiddenField',
						:field_name => 'ajax_distributor',
						:non_db_field => true}
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (production_schedule_id) on related table: production_schedules
#	-----------------------------------------------------------------------------------------------------

 
	build_form(trade_environment_setup,field_configs,action,'trade_environment_setup',caption,is_edit)

end
 
 
 def build_trade_environment_setup_grid(data_set,can_edit,can_delete)

	column_configs = Array.new

	column_configs[0] = {:field_type => 'text',:field_name => 'trade_env_code',:col_width => 72}
	column_configs[1] = {:field_type => 'text',:field_name => 'organization_marketing',:col_width => 72,:column_caption => 'org_marketing'}
	column_configs[2] = {:field_type => 'text',:field_name => 'organization_intake',:col_width => 72,:column_caption => 'org_intake'}
	column_configs[3] = {:field_type => 'text',:field_name => 'organization_retailer',:col_width => 72,:column_caption => 'org_retailer'}
	column_configs[4] = {:field_type => 'text',:field_name => 'mark_fruit_description',:col_width => 72,:column_caption => 'mark_fruit'}
	column_configs[5] = {:field_type => 'text',:field_name => 'mark_retail_unit_description',:col_width => 72,:column_caption => 'mark_retailer'}
	column_configs[6] = {:field_type => 'text',:field_name => 'mark_trade_unit_description',:col_width => 72,:column_caption => 'mark_tu'}
	column_configs[7] = {:field_type => 'text',:field_name => 'target_market_description',:col_width => 72,:column_caption => 'tm'}
	column_configs[8] = {:field_type => 'text',:field_name => 'qc_grade_description',:col_width => 70}
	column_configs[9] = {:field_type => 'text',:field_name => 'qc_destination_country_code',:col_width => 72,:column_caption => 'country'}
	column_configs[10] = {:field_type => 'text',:field_name => 'qc_inspection_type',:col_width => 72,:column_caption => 'inspect_type'}
	column_configs[11] = {:field_type => 'text',:field_name => 'sell_by_code',:col_width => 72}
#	----------------------
#	define action columns
#	----------------------
    if @is_view
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view trade_environment_setup',:col_width => 55,
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_trade_environment_setup',
				:id_column => 'id'}}
    else
	 if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit trade_environment_setup', :col_width => 55,
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_trade_environment_setup',
				:id_column => 'id'}}
	 end

	 if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete trade_environment_setup',:col_width => 55,
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_trade_environment_setup',
				:id_column => 'id'}}
	 end
	end
	
 return get_data_grid(data_set,column_configs)
end

end
