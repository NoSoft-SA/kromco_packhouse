module Fg::WipPalletsHelper

  def build_filter_by_fruitspec_form(pallet,action,caption,is_edit, is_create_retry=nil)
    
    session[:filter_by_fruitspec_form] = Hash.new

    search_combos_js_for_commodity_variety = gen_combos_clear_js_for_combos(["pallet_commodity_code", "pallet_marketing_variety_code"])

    search_combos_js_for_facility_location = gen_combos_clear_js_for_combos(["pallet_facility_code", "pallet_location_code"])

    commodity_code_observer = {:updated_field_id=>'marketing_variety_code_cell',
                               :remote_method =>'pallet_commodity_code_combo_changed',
                               :on_completed_js => search_combos_js_for_commodity_variety["pallet_commodity_code"]
    }

    session[:filter_by_fruitspec_form][:commodity_code_observer] = commodity_code_observer

    facility_code_observer = {:updated_field_id=>'location_code_cell',
                              :remote_method =>'pallet_facility_code_combo_changed',
                              :on_completed_js =>search_combos_js_for_facility_location["pallet_facility_code"]
    }

    session[:filter_by_fruitspec_form][:facility_code_observer] = facility_code_observer

    field_configs = Array.new

    commodity_codes = Commodity.find_by_sql("SELECT DISTINCT commodity_code FROM commodities").map{|g|[g.commodity_code]}
    commodity_codes.unshift("<empty>")

    marketing_variety_codes = nil

    organizations = Organization.find_by_sql("SELECT DISTINCT short_description FROM organizations").map{|g|[g.short_description]}
    organizations.unshift("<empty>")

    target_markets = TargetMarket.find_by_sql("SELECT DISTINCT target_market_code FROM target_markets").map{|g|[g.target_market_code]}
    target_markets.unshift("<empty>")

    facility_codes = Facility.find_by_sql("SELECT DISTINCT facility_code FROM facilities").map{|g|[g.facility_code]}
    facility_codes.unshift("<empty>")

    location_codes = nil

    if pallet == nil || is_create_retry
      marketing_variety_codes = ["Select a value from commodity_code"]
      location_codes = ["Select a value from facility_code"]
    else
      marketing_variety_codes = Pallet.find_by_sql("SELECT DISTINCT marketing_variety_code FROM marketing_varieties WHERE commodity_code ='#{pallet.commodity_code}'").map{|g|[g.marketing_variety_code]}
      marketing_variety_codes.unshift("<empty>")
      facility = Facility.find_by_facility_code(pallet.facility_code)
      location_codes = Location.find_by_sql("SELECT DISTINCT location_code FROM locations WHERE facility_id='#{facility.id}").map{|g|[g.location_code]}
    end

    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'commodity_code', :settings=>{:list=>commodity_codes}, :observer=>commodity_code_observer}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'marketing_variety_code', :settings=>{:list=>marketing_variety_codes}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'org_short_description', :settings=>{:list=>organizations}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'target_market_code', :settings=>{:list=>target_markets}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'facility_code', :settings=>{:list=>facility_codes}, :observer=>facility_code_observer}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'location_code', :settings=>{:list=>location_codes}}

    build_form(pallet,field_configs,action,'pallet',caption,is_edit)

  end

  def build_filter_by_fruitspec_grid(data_set, is_multi_select=nil)
    column_configs = Array.new

    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'pallet_number'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'commodity_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'variety_short_long'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'target_market_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'organization_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'location_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => "facility_code"}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'fg_product_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'farm_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'id'}

    @multi_select = "selected_pallets" if is_multi_select


    return get_data_grid(data_set,column_configs,nil,true)

  end


  def build_filter_by_schedule_form(pallet, action,caption,is_edit, is_create_retry=nil)
    session[:filter_by_schedule_form] = Hash.new

    search_combos_js_for_season_schedule = gen_combos_clear_js_for_combos(["pallet_season_code", "pallet_production_schedule_name"])

    search_combos_js_for_farm_schedule = gen_combos_clear_js_for_combos(["pallet_farm_code", "pallet_production_schedule_name"])

    search_combos_js_for_rmt_variety_schedule = gen_combos_clear_js_for_combos(["pallet_rmt_variety_code", "pallet_production_schedule_name"])

    search_combos_js_for_facility_location = gen_combos_clear_js_for_combos(["pallet_facility_code", "pallet_location_code"])

    season_code_observer = {:updated_field_id=>'production_schedule_name_cell',
                               :remote_method =>'pallet_season_code_combo_changed',
                               :on_completed_js => search_combos_js_for_season_schedule["pallet_season_code"]
    }

    session[:filter_by_schedule_form][:season_code_observer] = season_code_observer

    farm_code_observer = {:updated_field_id=>'production_schedule_name_cell',
                              :remote_method =>'pallet_farm_code_combo_changed',
                              :on_completed_js =>search_combos_js_for_farm_schedule["pallet_farm_code"]
    }

    session[:filter_by_schedule_form][:farm_code_observer] = farm_code_observer

    rmt_variety_code_observer = {:updated_field_id=>'production_schedule_name_cell',
                               :remote_method =>'pallet_rmt_variety_code_combo_changed',
                               :on_completed_js => search_combos_js_for_rmt_variety_schedule["pallet_rmt_variety_code"]
    }

    session[:filter_by_schedule_form][:rmt_variety_code_observer] = rmt_variety_code_observer

    facility_code_observer = {:updated_field_id=>'location_code_cell',
                              :remote_method =>'pallet_facility_two_code_combo_changed',
                              :on_completed_js =>search_combos_js_for_facility_location["pallet_facility_code"]
    }

    session[:filter_by_schedule_form][:facility_code_observer] = facility_code_observer

    field_configs = Array.new

    season_codes = Season.find_by_sql("SELECT DISTINCT season_code FROM seasons").map{|g|[g.season_code]}
    season_codes.unshift("<empty>")

    farm_codes = Farm.find_by_sql("SELECT DISTINCT farm_code FROM farms").map{|g|[g.farm_code]}
    farm_codes.unshift("<empty>")

    rmt_variety_codes = RmtVariety.find_by_sql("SELECT DISTINCT rmt_variety_code FROM rmt_varieties").map{|g|[g.rmt_variety_code]}
    rmt_variety_codes.unshift("<empty>")

    production_schedule_names = ProductionSchedule.find_by_sql("SELECT DISTINCT production_schedule_name FROM production_schedules").map{|g|[g.production_schedule_name]}
    production_schedule_names.unshift("<empty>")

    facility_codes = Facility.find_by_sql("SELECT DISTINCT facility_code FROM facilities").map{|g|[g.facility_code]}
    facility_codes.unshift("<empty>")

    location_codes = nil

    if pallet == nil || is_create_retry
      location_codes = ["Select a value from facility_code"]
    else
      facility = Facility.find_by_facility_code(pallet.facility_code)
      location_codes = Location.find_by_sql("SELECT DISTINCT location_code FROM locations WHERE facility_id='#{facility.id}").map{|g|[g.location_code]}
    end


    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'season_code', :settings=>{:list=>season_codes}, :observer=>season_code_observer}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'farm_code', :settings=>{:list=>farm_codes}, :observer=>farm_code_observer}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'rmt_variety_code', :settings=>{:list=>rmt_variety_codes}, :observer=>rmt_variety_code_observer}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'production_schedule_name', :settings=>{:list=>production_schedule_names}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'facility_code', :settings=>{:list=>facility_codes}, :observer=>facility_code_observer}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'location_code', :settings=>{:list=>location_codes}}

    build_form(pallet,field_configs,action,'pallet',caption,is_edit)

  end

  def build_filter_by_schedule_grid(data_set, is_multi_select=nil)
    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'pallet_number'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'commodity_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'variety_short_long'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'target_market_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'organization_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'location_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'facility_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'fg_code_old'}
    #column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'farm_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'production_schedule_name'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'id'}

    @multi_select = "selected_pallets" if is_multi_select


    return get_data_grid(data_set,column_configs,nil,true)

  end

end
