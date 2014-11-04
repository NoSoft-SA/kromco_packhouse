module Inventory::FacilitiesHelper

  def build_rmt_product_codes_grid(data_set)
    column_configs = []
    column_configs << {:field_type => 'text', :field_name => 'rmt_product_code',:col_width=>275}
    column_configs << {:field_type => 'text', :field_name => 'new_rmt_product_code',:col_width=>275}
    column_configs << {:field_type => 'text', :field_name => 'product_class_code',:col_width=>200}
    column_configs << {:field_type => 'text', :field_name => 'ripe_point_code'}
    column_configs << {:field_type => 'text', :field_name => 'new_ripe_point_code'}
    column_configs << {:field_type => 'text', :field_name => 'variety_code'}
    column_configs << {:field_type => 'text', :field_name => 'bins'}
    column_configs << {:field_type => 'text', :field_name => 'id'}

    grid_command =    {:field_type=>'link_window_field',:field_name =>'change_location_status',
                       :settings =>
                           {
                               :host_and_port =>request.host_with_port.to_s,
                               :controller =>request.path_parameters['controller'].to_s ,
                               :target_action => 'change_location_status',
                               :link_text => "change_location_status"
                           }}

    return get_data_grid(data_set,column_configs,nil,true,grid_command)
    set_grid_min_width(1200)
  end

  def build_set_ripe_point_code_form(ripe_point, action, caption, is_edit)


    field_configs = Array.new




     coldstore_type_codes =ColdStoreType.find(:all).map{|r|[r.cold_store_type_code,r.id]}
     coldstore_type_codes.unshift("<empty>")

     treatment_codes =Treatment.find_by_sql("select * from treatments where treatment_type_code='COLDSTORE'").map{|s|[s.treatment_code]}
     treatment_codes.unshift("<empty>")

       ripe_point.cold_store_type_id = nil
     combos_js_for_cold_store_type_code_on_complete_js = "\n img = document.getElementById('img_ripe_point_cold_store_type_id');"
     combos_js_for_cold_store_type_code_on_complete_js+= "\n if(img != null)img.style.display = 'none';"

    combos_js_for_cold_store_type_code = gen_combos_clear_js_for_combos(["ripe_point_cold_store_type_id", "new_ripe_point"])
    ripe_point_observer = {:updated_field_id => "new_ripe_point_code_cell",
                           :remote_method =>'create_new_ripe_point_code',
#                            :on_completed_js => combos_js_for_rmt_product["bin_rmt_product_id"]
                           :on_completed_js => combos_js_for_cold_store_type_code_on_complete_js}

    combos_js_for_treatment2_code_on_complete_js = "\n img = document.getElementById('img_ripe_point_treatment2_code');"
    combos_js_for_treatment2_code_on_complete_js+= "\n if(img != null)img.style.display = 'none';"

    combos_js_for_treatment2_code = gen_combos_clear_js_for_combos(["ripe_point_treatment2_code", "new_ripe_point"])
    treatment_code_observer = {:updated_field_id => "new_ripe_point_code_cell",
                           :remote_method =>'store_treatment_code',
#                            :on_completed_js => combos_js_for_rmt_product["bin_rmt_product_id"]
                           :on_completed_js => combos_js_for_treatment2_code_on_complete_js}

      treatment_code2=RipePoint.find(ripe_point).treatment2_code
      ripe_point.treatment_code2=treatment_code2
     field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "treatment_code2",
                                              :settings => {
                                              :label_caption =>'treatment2 code',:show_label=> true }
                                            }


     field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "cold_store_type_code"}
     field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "ripe_code"}
     field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "treatment_code"}




      ripe_point.treatment2_code = nil
      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                              :field_name => 'treatment2_code',
                                              :non_db_field=>true,
                                              :settings => {
                                              :list=>treatment_codes,
                                             :label_caption =>'new treatment2 code',:show_label=> true},
                                               :observer =>  treatment_code_observer
                                             }




      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                              :field_name => 'cold_store_type_id',
                                              :settings => {
                                              :list=>coldstore_type_codes,

                                              :label_caption =>'new cold store type code',:show_label=> true},
                                             :observer =>  ripe_point_observer
                                             }



      field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "new_ripe_point_code"}
      field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "new_rmt_product_code"}


    build_form(ripe_point, field_configs, action,'ripe_point',caption)

  end

#  def build_rmt_products_grid(data_set)
#
#    column_configs                          = Array.new
#    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_product_code'}
#    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'new_rmt_product_code'}
#    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'product_class_code'}
#    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'ripe_point_code',
#                                               :settings   =>{:target_action => 'set_ripe_point_code', :id_column => 'id'}}
#    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'new_ripe_point_code'}
#    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'variety_code'}
#    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bins'}
#    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}
#
#
#    set_grid_min_width(1200)
#    return get_data_grid(data_set, column_configs)
#
#  end


  def build_bins_grid(data_set)

    column_configs                          = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_number',:col_width=>114}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'tipped_date_time',:col_width=>126}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'sealed_ca_date_time',:col_width=>126}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'delivery_number',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_product_code',:col_width=>272}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code',:column_caption=>'farm',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_code',:col_width=>209}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pack_material_product_code',:col_width=>113}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_receive_date_time',:col_width=>119}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_status',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_track_indicator_code',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code1',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code2',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code3',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code4',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code5',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_date_time',:col_width=>121}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'user_name',:col_width=>105}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'print_number',:column_caption=>'print_num',:col_width=>68}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exit_reference_date_time',:col_width=>126}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}


    set_grid_min_width(1200)
    return get_data_grid(data_set, column_configs)

  end

  def build_pallets_grid(data_set)
    column_configs                          = Array.new

    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'pallet_number',:col_width=>140}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'oldest_pack_date_time',:col_width=>143}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'carton_quantity_actual ',:column_caption=>'actual_qty',:col_width=>60}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'build_status',:col_width=>73}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'commodity_code',:column_caption=>'commodity',:col_width=>53}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'holdover',:col_width=>55}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'holdover_quantity',:column_caption=>'holdover_qty',:col_width=>75}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'marketing_variety_code',:col_width=>93}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'target_market_code',:column_caption=>'target_market',:col_width=>215}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'grade_code',:column_caption=>'grade',:col_width=>38}

    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'iso_week_code',:col_width=>61}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'season_code',:column_caption=>'season',:col_width=>53}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'pallet_format_product_code',:col_width=>98}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'pc_code',:col_width=>160}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'id'}

    get_data_grid(data_set, column_configs)

  end

  def build_set_status_form(location, action, caption, is_edit = nil, is_create_retry = nil)
    statuses                              = StatusMan.next_statuses(location.location_type_code, location)
    field_configs                         = Array.new
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'location_status',
                                             :settings   => {
                                                 :show_label    => true,
                                                 :label_caption => "current location status",
                                                 :is_separator  => false}}

    field_configs[field_configs.length()] = {:field_type  =>'DropDownField',
                                             :non_db_field=>true,
                                             :field_name  =>'location_code',
                                             :non_db_field=>true,
                                             :settings    =>{
                                                 :list          =>statuses,
                                                 :label_caption =>'change_status_to'}}


    field_configs[field_configs.length()] = {:field_type=>'PopupDateTimeSelector', :field_name=>'status_changed_date_time',:settings=>{:label_caption=>'date_time'}}


    build_form(location, field_configs, action, 'location', caption, is_edit)

  end

  def build_facility_form(facility, action, caption, is_edit)

    facility_type_codes = FacilityType.find_by_sql("select * from facility_types").map { |g| [g.facility_type_code] }
    facility_type_codes.unshift("<empty>")

    organization_codes = Organization.find_by_sql("select * from organizations").map { |o| [o.short_description] }
    organization_codes.unshift("<empty>")

    field_configs                         = Array.new

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'facility_type_code',
                                             :settings   => {:list => facility_type_codes}}
    if is_edit
      puts "Org short_description = " + Organization.find(facility.organization_id).short_description
      #NB...NON_DB_FIELD CANNOT BE USED IN EDIT FORMS
      organization_code                     = Organization.find_by_sql("select * from organizations").map { |o| [o.id] }

      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'organization_id',
                                               :settings   => {:list => organization_code}}
    else
      field_configs[field_configs.length()] = {:field_type   => 'DropDownField',
                                               :field_name   => 'organization_code',
                                               :non_db_field => true,
                                               :settings     => {:list => organization_codes}}
    end

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'facility_code'}

    build_form(facility, field_configs, action, 'facility', caption)

  end


  def build_facilities_search_form(facility, action, caption, is_flat_search=nil)

#    session[:facility_search_form]= Hash.new
#    #generate javascript for the on_complete ajax event for each combo
#    search_combos_js = gen_combos_clear_js_for_combos(["facility_facility_type_code","facility_org"])
#    #Observers for search combos
#    facility_type_code_observer  = {:updated_field_id => "org_cell",
#             :remote_method => 'facility_type_code_search_combo_changed',
#             :on_completed_js => search_combos_js["facility_facility_type_code"]}
#
#    session[:facility_search_form][:facility_type_code_observer] = facility_type_code_observer

    facility_type_codes = FacilityType.find_by_sql("select distinct facility_type_code from facility_types").map { |g| [g.facility_type_code] }
    facility_type_codes.unshift("<empty>")

    if is_flat_search
      org_codes = Organization.find_by_sql("select distinct short_description from organizations").map { |g| [g.short_description] }
    else
      org_codes = ["Select a value from facility_type_code"]
    end

    org_codes.unshift("<empty>")

    #	----------------------------------------
    #	 Define search fields to build form from
    #	----------------------------------------
    field_configs    = Array.new
    #	----------------------------------------------------------------------------------------------
    #	Define search Combo fields to represent the unique index on this table
    #	----------------------------------------------------------------------------------------------
    field_configs[0] = {:field_type => 'DropDownField',
                        :field_name => 'facility_type_code',
                        :settings   => {:list => facility_type_codes}}
    #:observer => facility_type_code_observer}

    field_configs[1] = {:field_type => 'DropDownField',
                        :field_name => 'org',
                        :settings   => {:list => org_codes}}

    build_form(facility, field_configs, action, 'facility', caption, false)
  end


  def build_locations_search_form()


    location_type_codes = LocationType.find_by_sql("select distinct location_type_code from location_types").map { |g| [g.location_type_code] }
    location_type_codes.unshift("<empty>")


    #	----------------------------------------
    #	 Define search fields to build form from
    #	----------------------------------------
    field_configs                         = Array.new
    #	----------------------------------------------------------------------------------------------
    #	Define search Combo fields to represent the unique index on this table
    #	----------------------------------------------------------------------------------------------
    field_configs[0]                      = {:field_type => 'DropDownField',
                                             :field_name => 'location_type_code',
                                             :settings   => {:list => location_type_codes}}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'location_code'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'parent_location_code'}


    build_form(nil, field_configs, 'submit_locations_search', 'location', 'find', false)
  end


  def build_facilities_grid(data_set, can_edit, can_delete)
    column_configs                          = Array.new

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'facility_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'facility_type_code'}

    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit',
                                                 :settings   =>
                                                     {:image     => 'edit',
                                                      :target_action => 'edit_facility',
                                                      :id_column     => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete',
                                                 :settings   =>
                                                     {:image     => 'delete',
                                                      :target_action => 'delete_facility',
                                                      :id_column     => 'id'}}
    end

#  column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'locations',
#			:settings =>
#				 {:link_text => 'locations',
#				:target_action => 'list_locations_frames',
#				:id_column => 'id'}}

    return get_data_grid(data_set, column_configs)
  end

  def build_location_form(location, action, caption, is_edit, is_tree, can_control_availability)
    location_type_codes = LocationType.find_by_sql("select distinct location_type_code from location_types").map { |g| [g.location_type_code] }
    location_type_codes.unshift("<empty>")

    bay_codes = Bay.find_by_sql("select distinct bay_code from bays").map { |g| [g.bay_code] }
    bay_codes.unshift("<empty>")

    if (!is_tree)
      parent_location_codes = Location.find_by_sql("select distinct location_code from locations").map { |l| [l.location_code] }
      parent_location_codes.unshift("<empty>")
    else
#      parent_location_codes = Location.find_by_sql("select distinct location_code from locations where location_code !='#{location.location_code.to_s}'").map{|l|[l.location_code]}
#      parent_location_codes.unshift("<empty>")
    end

    field_configs                         = Array.new

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'location_type_code',
                                             :settings   =>{:list=>location_type_codes}}

    if (!is_tree)
      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'parent_location_code',
                                               :settings   => {:list => parent_location_codes}}
    end
    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'bay_code',
                                             :settings   => {:list => bay_codes}}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'location_code'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'location_barcode'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'gln'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'location_status'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'location_maximum_units'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'storage_type'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'assignment_type'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'row_number'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'column_number'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'level_number'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'section_number'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'units_in_location'}

    if (can_control_availability)
      field_configs[field_configs.length()] = {:field_type => 'CheckBox',
                                               :field_name => 'unavailable'}
    end

    build_form(location, field_configs, action, 'location', caption)
  end

  def build_locations_grid(data_set, can_edit, can_delete, can_view_locations_storage_rules, can_view_locations_parent_location, can_view_locations_child_locations, can_control_availability)
    require File.dirname(__FILE__) + "/../../../app/helpers/inventory/facility_plugins.rb"
    column_configs                          = Array.new

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'bins',:col_width=>34,
                                               :settings   =>
                                                   {:link_text     => 'bins',
                                                    :target_action => 'bins',
                                                    :id_column     => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'pallets',:col_width=>34,
                                               :settings   =>
                                                   {:link_text     => 'pallets',
                                                    :target_action => 'pallets',
                                                    :id_column     => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'set_status',:col_width=>52,
                                               :settings   =>
                                                   {:link_text     => 'set_status',
                                                    :target_action => 'set_status',
                                                    :id_column     => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'status_history',:col_width=>71,
                                               :settings   =>
                                                   {:link_text     => 'status_history',
                                                    :target_action => 'status_history',
                                                    :id_column     => 'id'}}

    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit',:col_width=>30,
                                                 :settings   =>
                                                     {:image     => 'edit',
                                                      :target_action => 'edit_location',
                                                      :id_column     => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete',:col_width=>30,
                                                 :settings   =>
                                                     {:image     => 'delete',
                                                      :target_action => 'delete_location',
                                                      :id_column     => 'id'}}
    end

    if (can_view_locations_storage_rules)
      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'location setup',:col_width=>63,
                                                 :settings   =>
                                                     {:link_text     => 'storage_rules',
                                                      :target_action => 'storage_rules',
                                                      :id_column     => 'id'}}
    end

    #if (can_view_locations_storage_rules)
      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'bin location setup',:col_width=>73,
                                                 :settings   =>
                                                     {:link_text     => 'bin_storage_rules',
                                                      :target_action => 'bin_storage_rules',
                                                      :id_column     => 'id'}}
    #end

    if (can_view_locations_parent_location)
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'parent_location',:col_width=>71,
                                                 :settings   =>
                                                     {:link_text     => 'parent location',
                                                      :target_action => 'parent_location',
                                                      :id_column     => 'id'}}
    end

   if (can_view_locations_child_locations)
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'child_locations',:col_width=>71,
                                                 :settings   =>
                                                     {:link_text     => 'child locations',
                                                      :target_action => 'child_locations',
                                                      :id_column     => 'id'}}
    end

    if (can_control_availability)
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'unavailable',:col_width=>42,
                                                 :settings   =>
                                                     {:target_action => 'control_location_availability',
                                                      :id_column     => 'id'}}
    end
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_code',:col_width=>145}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_type_code',:col_width=>120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bay_code',:col_width=>43}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_barcode',:col_width=>57}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'parent_location_code',:col_width=>111}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'units_in_location',:column_caption=>'units/location',:col_width=>62}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_status',:col_width=>152}
    set_grid_min_width(1200)
    return get_data_grid(data_set, column_configs, FacilityPlugins::LocationsGridPlugin.new(self, request))
  end

#  def build_locations_iframes(child_form,action,caption,is_edit,das)
#    field_configs = Array.new
#
#    field_configs[field_configs.length()] = {:field_type => 'ChildForm',
#						:field_name => "child_form2",
#						:settings =>{:target_action => 'list_locations',
#						             :id_column => das,
#						             :request => request}}
#
#     field_configs[field_configs.length()] = {:field_type => 'ChildForm',
#						:field_name => "child_form3",
#						:settings =>{:target_action => 'storage_rules',
#						             :id_column => nil,
#						             :request => request}}
#
#    build_form(child_form,field_configs,nil,'locations',caption)
#  end


  def build_location_setups_grid(data_set, can_edit, can_delete)
    column_configs = Array.new
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'edit', :col_width=>30,
                                                 :settings   =>
                                                     {:image     => 'edit',
                                                      :target_action => 'edit_location_setup',
                                                      :id_column     => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete', :col_width=>30,
                                                 :settings   =>
                                                     {:image     => 'delete',
                                                      :target_action => 'delete_location_setup',
                                                      :id_column     => 'id'}}
    end


    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'priority'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'commodity_code',:column_caption=>'commodity',:col_width=>53}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'variety_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'brand_code',:column_caption=>'brand',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'old_pack_code',:column_caption=>'old_pack',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'target_market_code',:column_caption=>'target_market',:col_width=>215}
#    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'extended_fg_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'order_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'size_ref_code',:column_caption=>'size_ref',:col_width=>55}
#    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'pallet_format_product_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inventory_code',:column_caption=>'inventory',:col_width=>110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'grade_code',:column_caption=>'grade',:col_width=>38}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'org_short_description'}
#    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'pallet_build_status'}
#    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'maximum_lots'}
#    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'unit_pack_product_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_pack_product_code'}
#    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'date_time_from'}
#    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'date_time_to'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'build_status',:col_width=>73}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'stack_type_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'assignment'}

    special_commands                        = {:settings =>
                                                   {:target_action => 'new_storage_rule',
                                                    :host_and_port => request.host_with_port.to_s,
                                                    :controller    => 'inventory/facilities',
                                                    :link_text     =>"new_storage_rule", :link_type => "popup", :frame_id =>"child_form3_iframe", }}

    return get_data_grid(data_set, column_configs, nil, nil, special_commands)

  end

  def build_bin_location_setups_grid(can_edit, can_delete)
    column_configs = Array.new
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'edit', :col_width=>30,
                                                 :settings   =>
                                                     {:image     => 'edit',
                                                      :target_action => 'edit_bin_location_setup',
                                                      :id_column     => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'clone', :col_width=>30,
                                                 :settings   =>
                                                     {:image     => 'clone',
                                                      :target_action => 'clone_bin_location_setup',
                                                      :id_column     => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete', :col_width=>30,
                                                 :settings   =>
                                                     {:image     => 'delete',
                                                      :target_action => 'delete_bin_location_setup',
                                                      :id_column     => 'id'}}
    end


    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'priority'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'commodity_code',:column_caption=>'commodity',:col_width=>73}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_variety_code',:column_caption=>'rmt_variety',:col_width=>73}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'season',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_product_code',:column_caption=>'rmt product',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'track_slms_indicator_code',:column_caption=>'track slms indicator',:col_width=>115}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code',:column_caption=>'farm'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_product_type_code',:column_caption=>'rmt product type',:col_width=>55}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'treatment_code',:column_caption=>'treatment',:col_width=>110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'product_class_code',:column_caption=>'product class',:col_width=>38}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'ripe_point_code',:column_caption=>'ripe_point'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'size_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'assignment_code',:col_width=>973}

    grid_command =    {:field_type=>'link_window_field',:field_name =>'new_bin_storage_rule',
                           :settings =>{:target_action => 'new_bin_storage_rule',
                                        :link_text => "new_bin_storage_rule",
                                        :id_value =>@location.id}}

    return get_data_grid(@location.bin_location_setups, column_configs, nil, nil, grid_command)

  end

  def build_location_setup_form(location_setup, action, caption, is_edit=nil, is_create_retry=nil)

    session[:location_setup_form]                        = Hash.new

    search_combos_js                                     = gen_combos_clear_js_for_combos(["location_setup_season_code", "location_setup_order_code"])

    season_code_observer                                 = {:updated_field_id => "order_code_cell",
                                                            :remote_method    =>'season_code_combo_changed',
                                                            :on_completed_js  =>search_combos_js["location_setup_season_code"]
    }
    session[:location_setup_form][:season_code_observer] = season_code_observer

    commodity_codes                                      = Commodity.find_by_sql("SELECT DISTINCT commodity_code from commodities").map { |g| [g.commodity_code] }
    commodity_codes.unshift("ALL")

    variety_codes = MarketingVariety.find_by_sql("SELECT DISTINCT marketing_variety_code from marketing_varieties").map { |g| [g.marketing_variety_code] }
    variety_codes.unshift("ALL")

    brand_codes = Mark.find_by_sql("SELECT DISTINCT brand_code from marks").map { |g| [g.brand_code] }
    brand_codes.unshift("ALL")

    stack_type_codes = StackType.find_by_sql("SELECT DISTINCT stack_type_code from stack_types").map { |g| [g.stack_type_code] }
    stack_type_codes.unshift("ALL")

    old_pack_codes = OldPack.find_by_sql("SELECT DISTINCT old_pack_code from old_packs").map { |g| [g.old_pack_code] }
    old_pack_codes.unshift("ALL")

    counts = StandardCount.find_by_sql("SELECT DISTINCT standard_count_value from standard_counts").map { |g| [g.standard_count_value.to_s] }.concat(SizeRef.find_by_sql("SELECT DISTINCT size_ref_code from size_refs").map { |g| [g.size_ref_code] })
    counts.unshift("ALL")

    carton_pack_product_codes = CartonPackProduct.find_by_sql("SELECT DISTINCT carton_pack_product_code from carton_pack_products").map { |g| [g.carton_pack_product_code] }
    carton_pack_product_codes.unshift("ALL")

    target_market_codes = TargetMarket.find_by_sql("SELECT DISTINCT target_market_code from target_markets").map { |g| [g.target_market_code] }
    target_market_codes.unshift("ALL")

    inventory_codes = InventoryCode.find_by_sql("SELECT DISTINCT inventory_code, inventory_name from inventory_codes").map { |g| [g.inventory_code.to_s + "_" + g.inventory_name.to_s] }
    inventory_codes.unshift("ALL")

    grade_codes = Grade.find_by_sql("SELECT DISTINCT grade_code from grades").map { |g| [g.grade_code] }
    grade_codes.unshift("ALL")

    org_short_descriptions = Organization.find_by_sql("select organizations.short_description,parties_roles.role_name
                                                        from organizations
                                                          JOIN parties_roles on organizations.party_id=parties_roles.party_id
                                                        where parties_roles.role_name='MARKETER'").map { |g| [g.short_description] }
    org_short_descriptions.unshift("ALL")

    build_statuses = ["ALL", "FULL", "PARTIAL"]

    assignments    = ["STORAGE", "RECOOL"]

    season_codes   = Season.find_by_sql("SELECT DISTINCT season_code from seasons").map { |g| [g.season_code] }
    season_codes.unshift("ALL")

    orders = nil
    if location_setup == nil || is_create_retry
      orders = ["Select a value from season_code"]
    else
       if location_setup.season_code.to_s == "ALL"
         orders = SeasonOrderQuantity.find_by_sql("SElECT DISTINCT customer_order_number from season_order_quantities").map { |g| [g.customer_order_number] }
       else
           orders = SeasonOrderQuantity.find_by_sql("SElECT DISTINCT customer_order_number from season_order_quantities where season_code = '#{location_setup.season_code}'").map { |g| [g.customer_order_number] }
        end
    end

    orders.unshift('ALL')

    if !location_setup
      @location_setup                          = LocationSetup.new
      @location_setup.commodity_code           = 'ALL'
      @location_setup.variety_code             = 'ALL'
      @location_setup.brand_code               = 'ALL'
      @location_setup.old_pack_code            = 'ALL'
      @location_setup.size_ref_code            = 'ALL'
      @location_setup.carton_pack_product_code = 'ALL'
      @location_setup.target_market_code       = 'ALL'
      @location_setup.inventory_code           = 'ALL'
      @location_setup.grade_code               = 'ALL'
      @location_setup.org_short_description    = 'ALL'
      @location_setup.build_status             = 'ALL'
      @location_setup.assignment               = 'ALL'
      @location_setup.season_code              = 'ALL'
      @location_setup.order_code               = 'ALL'
      @location_setup.stack_type_code          = 'ALL'
    end


    field_configs                         = Array.new

    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'priority'}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'commodity_code', :settings=>{:list=>commodity_codes, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'variety_code', :settings=>{:list=>variety_codes, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'brand_code', :settings=>{:list=>brand_codes, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'old_pack_code', :settings=>{:list=>old_pack_codes, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'size_ref_code', :settings=>{:label_caption=>'count', :list=>counts, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'carton_pack_product_code', :settings=>{:list=>carton_pack_product_codes, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'target_market_code', :settings=>{:list=>target_market_codes, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'inventory_code', :settings=>{:list=>inventory_codes, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'grade_code', :settings=>{:list=>grade_codes, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'org_short_description', :settings=>{:list=>org_short_descriptions, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'build_status', :settings=>{:list=>build_statuses, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'assignment', :settings=>{:list=>assignments, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'season_code', :settings=>{:list=>season_codes, :no_empty=>true}, :observer=>season_code_observer}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'order_code', :settings=>{:list=>orders, :no_empty=>true}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'stack_type_code', :settings=>{:list=>stack_type_codes, :no_empty=>true}}

    build_form(location_setup, field_configs, action, 'location_setup', caption, is_edit)

  end

  def build_bin_location_setup_form(bin_location_setup, action, caption, is_edit=nil, is_create_retry=nil)
    session[:bin_location_setup_form] = Hash.new
    #generate javascript for the on_complete ajax event for each combo
    combos_js_for_rmt_product_type_code = gen_combos_clear_js_for_combos(["bin_location_setup_rmt_product_type_code", "bin_location_setup_rmt_product_code"])
    rmt_product_type_code_observer  = {:updated_field_id => "rmt_product_code_cell",
                 :remote_method => 'rmt_product_type_code_combo_changed',
                 :on_completed_js => combos_js_for_rmt_product_type_code["bin_location_setup_rmt_product_type_code"]}

    session[:bin_location_setup_form][:rmt_product_type_code_observer] = rmt_product_type_code_observer

    season_codes   = Season.find_by_sql("SELECT DISTINCT season_code from seasons").map { |g| [g.season_code] }
    #season_codes.unshift("ALL")

    rmt_product_codes = RmtProduct.find(:all,:select=>'distinct rmt_product_code').map { |f| [f.rmt_product_code] }
    #rmt_product_codes.unshift("ALL")

    track_slms_indicator_codes = TrackSlmsIndicator.find_all_by_track_indicator_type_code("RMI").map { |t| [t.track_slms_indicator_code] }
    #track_slms_indicator_codes.unshift("ALL")

    farm_codes = Farm.find(:all,:select=>'distinct farm_code').map{|g|[g.farm_code]}
    #farm_codes.unshift("ALL")

    commodity_codes = Commodity.find(:all,:select=>'distinct commodity_code').map { |g| [g.commodity_code] }
    #commodity_codes.unshift("ALL")

    rmt_variety_codes = RmtVariety.find(:all,:select=>'distinct rmt_variety_code').map { |g| [g.rmt_variety_code] }
    #@rmt_variety_codes.unshift("ALL")


    treatment_codes = Treatment.find(:all,:select=>'distinct treatment_code').map{|g|[g.treatment_code]}
    #treatment_codes.unshift("ALL")

    product_class_codes = ProductClass.find(:all,:select=>'distinct product_class_code').map{|g|[g.product_class_code]}
    #product_class_codes.unshift("ALL")

    ripe_point_codes = RipePoint.find(:all,:select=>'distinct ripe_point_code').map{|g|[g.ripe_point_code]}
    #ripe_point_codes.unshift("ALL")

    size_codes = Size.find(:all,:select=>'distinct size_code').map{|g|[g.size_code]}
    #size_codes.unshift("ALL")

    assignment_codes = ['ALL','RA','CA','PRESORT']

    #bin_location_setup.rmt_product_type_code = 'PRESORT'
    rmt_product_type_codes = RmtProductType.find(:all,:select=>'distinct rmt_product_type_code').map{|g|[g.rmt_product_type_code]}
    #rmt_product_type_codes.unshift("ALL")

    field_configs = []

    field_configs << {:field_type=>'TextField', :field_name=>'priority'}
    field_configs << {:field_type=>'DropDownField', :field_name => 'commodity_code', :settings=>{:list=>commodity_codes, :prompt=>'ALL', :is_clearable=>true}}
    field_configs << {:field_type=>'DropDownField', :field_name => 'rmt_variety_code', :settings=>{:list=>rmt_variety_codes, :prompt=>'ALL', :is_clearable=>true}}
    field_configs << {:field_type=>'DropDownField', :field_name => 'season', :settings=>{:list=>season_codes, :prompt=>'ALL', :is_clearable=>true}}
    field_configs << {:field_type=>'DropDownField', :field_name => 'rmt_product_type_code', :settings=>{:list=>rmt_product_type_codes, :prompt=>'ALL', :is_clearable=>true},
                                                     :observer=>rmt_product_type_code_observer}
    field_configs << {:field_type=>'DropDownField', :field_name => 'rmt_product_code', :settings=>{:list=>rmt_product_codes, :prompt=>'ALL', :is_clearable=>true}}
    field_configs << {:field_type=>'DropDownField', :field_name => 'track_slms_indicator_code', :settings=>{:list=>track_slms_indicator_codes, :prompt=>'ALL', :is_clearable=>true}}
    field_configs << {:field_type=>'DropDownField', :field_name => 'farm_code', :settings=>{:list=>farm_codes, :prompt=>'ALL', :is_clearable=>true}}
    field_configs << {:field_type=>'DropDownField', :field_name => 'treatment_code', :settings=>{:list=>treatment_codes, :prompt=>'ALL', :is_clearable=>true}}
    field_configs << {:field_type=>'DropDownField', :field_name => 'product_class_code', :settings=>{:list=>product_class_codes, :prompt=>'ALL', :is_clearable=>true}}
    field_configs << {:field_type=>'DropDownField', :field_name => 'ripe_point_code', :settings=>{:list=>ripe_point_codes, :prompt=>'ALL', :is_clearable=>true}}
    field_configs << {:field_type=>'DropDownField', :field_name => 'size_code', :settings=>{:list=>size_codes, :prompt=>'ALL', :is_clearable=>true}}
    field_configs << {:field_type=>'DropDownField', :field_name => 'assignment_code', :settings=>{:list=>assignment_codes, :prompt=>'ALL', :is_clearable=>true}}

    if(@is_edit)
      field_configs << {:field_type => 'HiddenField',:field_name => 'location_id'}
      field_configs << {:field_type => 'HiddenField',:field_name => 'id'}
    else
      field_configs << {:field_type => 'HiddenField',:field_name => 'location_id',:settings=>{:hidden_field_data => @location_id}}
    end

    build_form(bin_location_setup, field_configs, action, 'bin_location_setup', caption, is_edit)

  end

  def build_locations_tree(parent_location)

    begin
      all_locations = Location.find(:all)
      root_node     = ApplicationHelper::TreeNode.new(parent_location.location_code, "root_location", true, "locations", parent_location.id.to_s)
      build_child_location_tree(parent_location.location_code, root_node, all_locations)
      tree                 = ApplicationHelper::TreeView.new(root_node, "parent_location")
      child_locations_menu = ApplicationHelper::ContextMenu.new("location", "locations")
      child_locations_menu.add_command("add child", url_for(:action => "add_child_location"))
      child_locations_menu.add_command("remove", url_for(:action => "remove_from_parent"))
      child_locations_menu.add_command("delete", url_for(:action => "delete_and_remove_location"))
      child_locations_menu.add_command("create child", url_for(:action => "create_and_add_location"))

      root_locations_menu = ApplicationHelper::ContextMenu.new("root_location", "locations")
      root_locations_menu.add_command("add child", url_for(:action => "add_child_location"))
      root_locations_menu.add_command("remove", url_for(:action => "remove_from_parent"))
      root_locations_menu.add_command("delete", url_for(:action => "delete_and_remove_location"))
      root_locations_menu.add_command("create child", url_for(:action => "create_and_add_location"))
      tree.add_context_menu(child_locations_menu)
      tree.add_context_menu(root_locations_menu)
      tree.render
    rescue
      raise "The parent_location tree could not be rendered. Exception reported is \n" + $!
    end
  end

  def build_child_location_tree(root_location_code, root_location_node, all_locations, added_children = {})
    begin


      # puts "PARENT IS: " +   root_location_code
      child_locations = all_locations.find_all { |loc| (loc.parent_location_code == root_location_code) }
      #puts "children: " + child_locations.length().to_s
#      child_locations = Location.find_by_sql("select * from locations where parent_location_code = '#{root_location_code}'")

      child_locations.each do |child_location|
        raise "node: " + child_location.location_code + " belongs to itself! (its parent_location_code it the same as its location_code)" if child_location.location_code == root_location_code
        if added_children.has_key?(child_location.location_code)

          raise "node: " + child_location.location_code + " already belongs to parent: " + added_children[child_location.location_code] + "<BR>. It is also, incorrectly, belongs to parent: " + root_location_code
        else
          added_children[child_location.location_code] = root_location_code
        end
        child_location_node = root_location_node.add_child(child_location.location_code, "location", child_location.id.to_s)
        if all_locations.find { |l| l.parent_location_code == child_location.location_code }
          #if Location.count(:conditions => ["parent_location_code=?",child_location.location_code]) > 0
          build_child_location_tree(child_location.location_code, child_location_node, all_locations, added_children)
        end

      end
    rescue
      raise "The parent_location tree could not be rendered. Exception reported is \n" + $!
    end
  end

  def build_add_child_location_form(location, action, caption)
    locations_codes                     = Location.find_by_sql("select * from locations where location_code != '#{location.location_code}' and parent_location_code is null").map { |loc| [loc.location_code] }
    field_configs                       = Array.new
    field_configs[field_configs.length] = {:field_name=>'location_code', :field_type=>'DropDownField',
                                           :settings  =>{:label_caption=> 'chid_location_code', :list=>locations_codes}}

    build_form(location, field_configs, action, 'location', caption, false)
  end

end