module Production::ReworksHelper



  def build_add_carton_form(count)

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => "", :settings =>
                    {:static_value => "carton count: " + count.to_s, :is_separator => false}}

    field_configs[1] =  {:field_type => 'TextField',
                         :field_name => "carton_number"}


    build_form(nil, field_configs, 'carton_added', 'carton', 'add carton')

  end

  def build_remove_carton_form(count)

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => "", :settings =>
                    {:static_value => "carton count: " + count.to_s, :is_separator => false}}

    field_configs[1] =  {:field_type => 'TextField',
                         :field_name => "carton_number"}


    build_form(nil, field_configs, 'carton_removed', 'carton', 'remove carton')

  end

  def allocate_rebin_num

    on_complete_js = "img = document.getElementById('img_rebin_allocation_production_run_code');"
    on_complete_js += "\n if(img != null)img.style.display = 'none';"

    #Observers for search combos
    observer  = {:updated_field_id => "valid_station_codes_cell",
                 :remote_method => 'rebin_allocation_run_changed',
                 :on_completed_js => on_complete_js}


    @rebin_allocation = RebinAllocation.new
   # @rebin_allocation.production_run_code = "<empty>"

    field_configs = Array.new

    run_codes = ProductionRun.find_by_sql("select production_run_code from production_runs where (production_run_status = 'reconfiguring' or production_run_status = 'active')").map { |p| p.production_run_code }
    run_codes.unshift("<empty>")

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => "production_run_code", :settings =>
                    {:list => run_codes},
                                             :observer => observer}

    field_configs[1] =  {:field_type => 'LabelField',
                         :field_name => "run_stage"}

    field_configs[2] =  {:field_type => 'LabelField',
                         :field_name => "run_status"}


    field_configs[3] =  {:field_type => 'TextField',
                         :field_name => "scancode"}


    field_configs[4] = {:field_type => 'LabelField',
                        :field_name => 'group_menu', :settings =>
                    {:static_value => "INFORMATIONAL FIELDS", :is_separator => false, :css_class => 'blue_label_field'}}

    field_configs[5] =  {:field_type => 'DropDownField',
                         :field_name => "valid_station_codes", :settings =>
                    {:list => ["select a run to populate this list"]}}

    field_configs[6] =  {:field_type => 'LabelField',
                         :field_name => "rmt_product_for_station"}


    build_form(nil, field_configs, 'rebin_allocation_submit', 'rebin_allocation', 'submit', nil, nil, nil, true)

  end

  def tip_bin

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => "production_run_code"}

    field_configs[1] =  {:field_type => 'TextField',
                         :field_name => "bin_id"}


    build_form(nil, field_configs, 'tip_bin_submit', 'tip_bin', 'tip bin')

  end

  def build_scrap_reason_form(action)

    field_configs = Array.new

    reasons = RwReason.find(:all).map { |r| [r.rw_reason_description] }

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'reason',
                                              :settings => {:list => reasons}}

    build_form(nil, field_configs, action, 'item', 'scrap')


  end


  def build_printer_selection_form

    printers = CartonLabelStation.find_all_by_is_reworks_station(true).map { |p| [p.carton_label_station_code] }

    field_configs = Array.new

    field_configs[0] = {:field_type => 'DropDownField',
                        :field_name => 'printer_name',
                        :settings => {:list => printers}}

    build_form(nil, field_configs, 'set_carton_label_printer_submit', 'printer', 'save')


  end

  def build_receive_form

    field_configs = Array.new

    field_configs[0] = {:field_type => 'LinkField', :field_name => 'receive carton',
                        :settings =>
                                {:image => 'receive carton',
                                 :target_action => 'receive_carton'}}



    field_configs[1] = {:field_type => 'LinkField', :field_name => 'receive pallet',
                        :settings =>
                                {:image => 'receive pallet',
                                 :target_action => 'receive_pallet'}}

    field_configs[2] = {:field_type => 'LinkField', :field_name => 'receive bin',
                        :settings =>
                                {:image => 'receive bin',
                                 :target_action => 'receive_bin'}}
    if @can_receive_loaded_cartons
       field_configs[3] = {:field_type => 'LinkField', :field_name => 'receive loaded cartons',
                        :settings =>
                                {:image => 'LORRY_GO',
                                 :target_action => 'receive_loaded_carton'}}

    end

    build_form(nil, field_configs, nil, 'receive_run', 'l')


  end

  def build_runs_grid

    runs = RwRun.find_by_sql("select * from rw_runs where rw_run_status_code = 'editing'  and (username = '#{session[:user_id].user_name}' or username is null) ")
    column_configs = Array.new


#	----------------------
#	define action columns
#	----------------------
    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'set current', :col_width =>  84,
                                               :settings =>
                                                       {:link_text => "set as current run", :target_action => 'set_current_run',
                                                        :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'cancel',:col_width =>  84,
                                               :settings =>
                                                       {:link_text => "cancel run", :target_action => 'cancel_run',
                                                        :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'run_stats',:col_width =>  107,
                                               :settings =>
                                                       {:link_text => "completion progress", :target_action => 'view_completing_run_stats',
                                                        :id_column => 'id'}}

    column_configs[3] = {:field_type => 'text', :field_name => 'rw_run_name',:col_width =>  220}

    return get_data_grid(runs, column_configs)

  end

  def build_completed_runs_grid

    runs = RwRun.find_by_sql("select * from rw_runs where rw_run_status_code = 'complete' and (username = '#{session[:user_id].user_name}' or username is null) and rw_run_start_datetime > '#{20.days.ago.to_formatted_s(:db)}' ")
    column_configs = Array.new


#	----------------------
#	define action columns
#	----------------------
    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'set current',
                                               :settings =>
                                                       {:link_text => "view stats", :target_action => 'view_stats',
                                                        :id_column => 'id'}}

    column_configs[1] = {:field_type => 'text', :field_name => 'rw_run_name'}

    column_configs[2] = {:field_type => 'text', :field_name => 'rw_run_start_datetime'}
    return get_data_grid(runs, column_configs)

  end


  def build_new_pallet_form()

    product_codes = PalletFormatProduct.find(:all).map { |u| u.pallet_format_product_code }

    field_configs = Array.new

    field_configs[0] =  {:field_type => 'TextField',
                         :field_name => "carton_number"}

    field_configs[1] = {:field_type => 'DropDownField',
                        :field_name => 'pallet_format_product_code',
                        :settings => {:list => product_codes}}

    build_form(nil, field_configs, 'new_pallet_submit', 'carton', 'create')

  end

  def view_stats


  end


  def build_bulk_update_carton_form(carton, action, caption)

    session[:carton_edit_form]= Hash.new

    #-----------------------------------------------------------------------------
    #Marketing org observer: dependent fields are: target market,carton_mark_code
    #                        and inventory_code
    #------------------------------------------------------------------------------
    on_complete_js = "\n img = document.getElementById('img_carton_edit_organization_code');"
    on_complete_js += "\n if(img != null)img.style.display = 'none';"

    #Observers for search combos
    marketer_org_observer  = {:updated_field_id => "target_market_short_cell",
                              :remote_method => 'marketer_org_combo_changed',
                              :on_completed_js => on_complete_js}


    run_js = "\n img = document.getElementById('img_carton_edit_production_run_code');"
    run_js += "\n if(img != null)img.style.display = 'none';"

    #Observers for search combos
    marketer_org_observer  = {:updated_field_id => "target_market_short_cell",
                              :remote_method => 'marketer_org_combo_changed',
                              :on_completed_js => on_complete_js}


    ext_fg_js = "\n img = document.getElementById('img_carton_edit_extended_fg_code');"
    ext_fg_js += "\n if(img != null)img.style.display = 'none';"


    extended_fg_observer  = {:updated_field_id => "ajax_distributor_cell",
                             :remote_method => 'extended_fg_combo_changed',
                             :on_completed_js => ext_fg_js}


    run_observer  = {:updated_field_id => "ajax_distributor_cell",
                     :remote_method => 'run_combo_changed',
                     :on_completed_js => run_js}


    input_variety = carton.production_run.production_schedule.rmt_setup

    runs = ProductionRun.runs_for_input_rmt(input_variety.commodity_code, input_variety.variety_code).map { |r| [r.production_run_code] }
    #--------------------------
    #Get lists for all combos:
    #--------------------------

    org_codes = Organization.get_all_by_role("MARKETER")
    #marks = Mark.get_all_for_org(carton.organization_code)
    target_market_codes = TargetMarket.get_all_by_org(carton.organization_code)
    target_market_codes.unshift("<empty>")
    inventory_codes = InventoryCode.get_all_by_org(carton.organization_code)
    inventory_codes.unshift("<empty>")

    pc_codes = PcCode.find(:all).map { |p| ["PC" + p.pc_code + "_" + p.pc_name] if p }


    rmt_variety = carton.production_run.production_schedule.rmt_setup.variety_code
    carton.run_track_indicator_code =   carton.production_run.production_schedule.rmt_setup.output_track_indicator_code

    extended_fg_codes = ExtendedFg.get_all_by_commodity_and_rmt_variety(carton.commodity_code, rmt_variety).map { |g| [g.extended_fg_code] }

    pucs = Puc.find(:all).map { |g| [g.puc_code] }


    carton.decompose_fields

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'carton_number'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'pallet_number'}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'production_run_code', :settings => {
                    :list => runs},
                                             :observer => run_observer}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'farm_code',
                                             :settings => {:css_class => "derived_field"}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'puc',
                                             :settings => {:css_class => "derived_field"}}

    depot_and_dp_ctns = Carton.connection.select_one("select count(*) from rw_active_cartons where rw_run_id = #{carton.rw_run_id} and (( is_depot_carton is not null or is_depot_carton = true) or bin_id is not null)")['count'].to_i
    if depot_and_dp_ctns > 0
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'no_puc_update', :settings =>
              {:static_value => "PUC EDIT DISABLED. THERE ARE #{depot_and_dp_ctns} DEPOT OR DEDICATED PACK CARTONS", :is_separator => false,:css_class => 'blue_label_field'}}
    else

        field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'puc',
                                             :settings => {:list => pucs}}
    end


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'account_code',
                                             :settings => {:css_class => "derived_field"}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'egap',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'run_track_indicator_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'n_labels_printed'}

    #---------------
    #RUN EXC DETAILS
    #---------------
    group_menu = "collapse all <img src = '/images/collapse_groups.png' onclick = 'collapse_all();' </img>&nbsp;&nbsp;&nbsp;expand all<img src = '/images/expand_groups.png' onclick = 'expand_all();' </img>"
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'group_menu', :settings =>
                    {:static_value => group_menu, :is_separator => false, :css_class => 'blue_label_field'}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'run exec', :settings =>
                    {:static_value => 'production execution details', :is_separator => false}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'line_code'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'shift_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'carton_label_station_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'erp_station'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'erp_pack_point'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'carton_pack_station_code'}

    #-------------
    #PRODUCT CODES
    #-------------
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'product codes', :settings =>
                    {:static_value => 'FG component codes', :is_separator => false}}


    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'extended_fg_code',
                                             :settings => {:list => extended_fg_codes},
                                             :observer => extended_fg_observer}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'extended_fg_code',
                                             :settings => {:css_class => "old_value", :label_caption => "current extended fg"}}

    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                              :field_name => 'item_pack_product_code',
                                              :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                              :field_name => 'unit_pack_product_code',
                                              :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                              :field_name => 'carton_pack_product_code',
                                              :settings => {:css_class => "derived_field"}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'fg_product_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'fg_code_old',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'extended_fg_code',
                                             :settings => {:css_class => "derived_field"}}

    #-------------
    #WEIGHT FIELDS
    #-------------
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'weight fields', :settings =>
                    {:static_value => 'weight related fields', :is_separator => false}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'carton_fruit_nett_mass'}


    #---------------------
    #FRUIT RELATED FIELDS
    #---------------------
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'ipc fields', :settings =>
                    {:static_value => 'IPC(fruit) related fields', :is_separator => false}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'commodity_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'variety_short_long',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'actual_size_count_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'grade_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'product_class_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'erp_cultivar',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'treatment_code',
                                             :settings => {:css_class => "derived_field"}}


    #----------------
    #MARKETING FIELDS
    #----------------
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'marketing fields', :settings =>
                    {:static_value => 'Marketing related fields', :is_separator => false}}

#	 field_configs[field_configs.length()] = {:field_type => 'DropDownField',
#						:field_name => 'organization_code',
#						:settings => {:list => org_codes},
#						:observer => marketer_org_observer}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'organization_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'target_market_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'target_market_short',
                                             :settings => {:list => target_market_codes}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'fg_mark_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'carton_mark_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'inventory_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'inventory_code_short',
                                             :settings => {:list => inventory_codes}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'marking'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'diameter'}
    #----------------------
    #QUALITY RELATED FIELDS
    #----------------------
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'QA fields', :settings =>
                    {:static_value => 'quality related fields', :is_separator => false}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'season_code'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'iso_week_code'}


    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'quarantine'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'inspection_type_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'qc_status_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'chemical_status_code'}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'pc_code',
                                             :settings => {:list => pc_codes}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'cold_store_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'spray_program_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'pi'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'pick_reference'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'egap'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'is_inspection_carton'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'qc_datetime_out'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'qc_datetime_in'}


    #----------------------
    #MISC FIELDS
    #----------------------
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'misc fields', :settings =>
                    {:static_value => 'miscellaneous fields', :is_separator => false}}

    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                              :field_name => 'old_pack_code'}

    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                              :field_name => 'track_indicator_code'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'remarks'}


    field_configs[field_configs.length()] = {:field_type => 'HiddenField',
                                             :field_name => 'ajax_distributor',
                                             :non_db_field => true}

    build_form(carton, field_configs, action, 'carton_edit', caption)


  end


  def build_receive_item_form(action, caption, field_name)

    caption +=  " single " + field_name.split("_")[0]
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
    if  field_name.index("pallet")

       field_configs[0] =  {:field_type => 'TextArea',
                           :field_name => field_name, :settings =>
                      {:rows=> 15, :cols => 20, :label_caption => "enter pallet number(s)"}}
      caption = "receive pallet(s)"

    elsif field_name.index("bin")
         field_configs[0] =  {:field_type => 'TextArea',
                           :field_name => field_name, :settings =>
                      {:rows=> 15, :cols => 20, :label_caption => "enter bin number(s)"}}
          caption = "receive bin(s)"
    else
       field_configs[0] =  {:field_type => 'TextField',
                           :field_name => field_name, :settings =>
                           {:label_caption => "enter " + field_name.gsub("_", " ")}}
    end

    search_action = field_name.split("_")[0] + "_search"

    field_configs[1] = {:field_type => 'LinkField', :field_name => 'go to search form',
                        :settings =>
                                {:image => 'search',
                                 :target_action => search_action}}

    build_form(nil, field_configs, action, 'received_item', caption)

  end

  def build_new_run_form(new_run = nil)


    run_types = RwRunType.find_all().map { |g| [g.rw_run_type_code] }
    run_types.unshift("<empty>")

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new

    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'rw_run_type_code',
                         :settings => {:list => run_types}}


    build_form(new_run, field_configs, 'create_rw_run', 'rw_run', 'create')

  end



  def build_weigh_bin_form(bin)

    field_configs = Array.new

    field_configs[0] =  {:field_type => 'LabelField',
                         :field_name => 'original_weight',:settings => {:static_value => Bin.find_by_bin_number(bin.bin_number).weight.to_s,:show_label => true}}

    field_configs[1] =  {:field_type => 'TextField',
                         :field_name => 'weight'}


    build_form(bin, field_configs, 'weigh_bin_submit', 'rw_bin', 'set weight',true)



  end

#==============
#RECEIVED GRIDS
#==============

  def build_cartons_grid(data_set, is_multi_select = nil)

    column_configs = Array.new


    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_number', :col_width => 120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pallet_number', :col_width => 150}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rw_receipt_unit'} if is_multi_select
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_code', :col_width => 158}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'fg_product_code', :col_width => 294}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'fg_mark_code', :col_width => 170}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "attributes['farm_code']", :column_caption => "farm_code", :col_width => 76}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'puc', :col_width => 76}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'fg_code_old', :col_width => 161}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'organization_code', :col_width => 40}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'grade_code', :col_width => 40}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inventory_code', :col_width => 140}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'target_market_code', :col_width => 130}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'extended_fg_code', :col_width => 516}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "attributes['line_code']", :column_caption => "line_code", :col_width => 47}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'order_number', :col_width => 150}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pack_date_time', :col_width => 162}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pick_reference', :col_width => 56}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'is_inspection_carton', :col_width => 45}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_fruit_nett_mass', :col_width => 60,:column_caption => 'mass'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_id'}

    if !@multi_select
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'carton',
                                                 :settings =>
                                                         {:link_text => 'view_carton',
                                                          :target_action => 'view_carton',
                                                          :id_column => 'id'}}
    end


    key_based_access = true
    key_based_access = @key_based_access if @key_based_access


    return get_data_grid(data_set, column_configs, nil, key_based_access)

  end

  def build_bins_grid(data_set, is_multi_select = nil)

    column_configs = Array.new

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_number',:col_width => 150}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'tipped_date_time',:col_width => 140}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'status_code', :column_caption=>'status',:col_width => 75}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'delivery_number',:col_width => 75}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_product_code',:col_width => 258}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'weight',:col_width => 70}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_on',:col_width => 142}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_tipped',:col_width => 170}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_rebin',:col_width => 170}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code',:col_width => 60}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'season_code',:col_width => 78}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'variety_code',:col_width => 50}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pack_material_product_code',:col_width => 72}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_receive_date_time',:col_width => 136}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_status',:col_width => 67}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'product_class_code',:col_width => 47,:column_caption => 'class'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_code',:col_width => 79}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'ripe_point_code',:col_width => 43}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'size_code',:col_width => 57}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'stock_type_code',:col_width => 68}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'sealed_ca_location_code',:col_width => 150}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'cold_store_type_code',:col_width => 47}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_track_indicator_code',:col_width => 63}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code1',:col_width => 63}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code2',:col_width => 63}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_date_time',:col_width => 157}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'user_name',:col_width => 73}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'print_number',:col_width => 73}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exit_reference_date_time',:col_width => 180}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id',:col_width => 100}


    if controller.controller_name != "reworks"
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'bin',
                                                 :settings =>
                                                         {:link_text => 'view_bin',
                                                          :target_action => 'view_bin',
                                                          :id_column => 'id'}}
    end
    @multi_select = "selected_bins"
    key_based_access = true
    key_based_access = @key_based_access if @key_based_access


    return get_data_grid(data_set, column_configs, nil, key_based_access)

  end

  def build_rebins_grid(data_set, multi_select=nil)

    column_configs = Array.new

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_number'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'username'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exit_ref'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'binfill_station_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'print_number'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "attributes['input_variety']", :column_caption => "input_variety"}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_product_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'weight'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "attributes['line_code']", :column_caption => 'line_code'}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_date'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "attributes['pc_code']", :column_caption => 'pc_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'track_indicator_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "attributes['season_code']", :column_caption => 'season_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}
    #:::::::::::: LUKS CHANGE - added the action column::::
    #:::::::::::: LUKS CHANGE - added the action column::::
    if controller.controller_name != "reworks"
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'rebin',
                                                 :settings =>
                                                         {:link_text => 'view_rebin',
                                                          :target_action => 'view_rebin',
                                                          :id_column => 'id'}}
    end
    @multi_select = "selected_rebins" if multi_select


    return get_data_grid(data_set, column_configs)

  end


  def build_bulk_edit_rebins_form(rebin, action, caption)

    #rmt_product_codes = RmtProduct.find_all_by_rmt_product_type_code("rebin").map {|r|[r.rmt_product_code]}
    rmt_product_codes = RmtProduct.find(:all).map { |r| [r.rmt_product_code] }
    production_run_codes =ProductionRun.find(:all).map { |p| [p.production_run_code] }
    query = "SELECT
             public.pack_material_products.pack_material_product_code
             FROM
             public.pack_material_sub_types
             INNER JOIN public.pack_material_types ON (public.pack_material_sub_types.pack_material_type_id = public.pack_material_types.id)
             INNER JOIN public.pack_material_products ON (public.pack_material_sub_types.id = public.pack_material_products.pack_material_sub_type_id)
             WHERE
            (public.pack_material_types.pack_material_type_code = 'RMU')"


    bin_products = PackMaterialProduct.find_by_sql(query).map { |b| b.pack_material_product_code }


    rebin.season_code = rebin.production_run.production_schedule.season_code
    rebin.line_code = rebin.production_run.line_code
    rebin.farm_code = rebin.farm_code
    rebin.pc_code = RmtProduct.find_by_rmt_product_code(rebin.rmt_product_code).ripe_point.pc_code_code
    rebin.input_variety = rebin.production_run.production_schedule.rmt_setup.variety_code
    track_indicator_codes = TrackIndicator.find(:all).map { |t| [t.track_indicator_code] }

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'rebin_number'}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'rmt_product_code',
                                             :settings => {:list => rmt_product_codes}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'product_code_pm_bintype',
                                             :settings => {:list => bin_products}, :label_caption => "bin type"}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'production_run_code',
                                             :settings => {:list => production_run_codes}}


    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'track_indicator_code',
                                             :settings => {:list => track_indicator_codes}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'username'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "input_variety"}


    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'line_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'transaction_date'}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'pc_code'}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'track_indicator_code'}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "weight"}

    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "orchard_code"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "size_code"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "ripe_point_code"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "class_code"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "commodity_code"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "binfill_station_code"}

    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "rebin_label_station_code"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "marketing_variety_code"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "season_code"}

    build_form(rebin, field_configs, action, 'rebin_edit', caption)

  end




  def build_bulk_edit_bins_form(bin, action, caption, is_edit=nil, is_create_retry=nil)



    session[:bulk_edit_bins_form]= Hash.new
    query = "SELECT
              public.pack_material_products.id,public.pack_material_products.pack_material_product_code
             FROM
             public.pack_material_sub_types
             INNER JOIN public.pack_material_types ON (public.pack_material_sub_types.pack_material_type_id = public.pack_material_types.id)
             INNER JOIN public.pack_material_products ON (public.pack_material_sub_types.id = public.pack_material_products.pack_material_sub_type_id)
             WHERE
            (public.pack_material_types.pack_material_type_code = 'RMU')"

      commodity_code_variety_code = RmtProduct.find_by_sql("select commodity_code,variety_code from rmt_products where id ='#{bin.rmt_product_id.to_s}' ")
      commodity_code=commodity_code_variety_code[0]['commodity_code'].to_s
      variety_code=commodity_code_variety_code[0]['variety_code']

       production_run_codes =ProductionRun.find_by_sql("select production_runs.* from production_runs
                            inner join production_schedules on production_runs.production_schedule_id = production_schedules.id
                            inner join rmt_setups on rmt_setups.production_schedule_id = production_schedules.id
                            where rmt_setups.commodity_code = '#{commodity_code}' AND  rmt_setups.variety_code = '#{variety_code}'order by production_runs.id desc ").map { |p| [p.production_run_code,p.id ] }

    combos_js_for_rmt_product_on_complete_js = "\n img = document.getElementById('img_bin_rmt_product_id');"
     combos_js_for_rmt_product_on_complete_js+= "\n if(img != null)img.style.display = 'none';"

    combos_js_for_rmt_product = gen_combos_clear_js_for_combos(["bin_rmt_product_id", "bin_track_indicator1_id"])
    rmt_product_observer = {:updated_field_id => "track_indicator1_id_cell",
                           :remote_method =>'rmt_product_code_changed',
#                            :on_completed_js => combos_js_for_rmt_product["bin_rmt_product_id"]
                           :on_completed_js => combos_js_for_rmt_product_on_complete_js}

    session[:bulk_edit_bins_form][:rmt_product_observer ] = rmt_product_observer

    track_indicator_codes =TrackIndicator.find_by_sql("select  track_indicator_code from track_indicators").map { |q| [q.track_indicator_code] }
    coldstore_type_codes = ColdStoreType.find(:all).map{|c|c.cold_store_type_code}


    farm_ids=Farm.find(:all).map{|s|[s.farm_code,s.id]}
    orchard_codes =Orchard.find(:all).map{|s|[s.id,s.orchard_code]}
    rmt_product_ids = RmtProduct.find_by_sql('select id, rmt_product_code from rmt_products').map { |r| [r.rmt_product_code, r.id ] }
    track_slms_indicator_ids = TrackSlmsIndicator.find_by_sql('select  id,track_slms_indicator_code from track_slms_indicators').map { |t| [t.track_slms_indicator_code,t.id] }
    if bin.delivery_id
    bin.delivery_number = Delivery.find(bin.delivery_id).delivery_number
    end

    pack_material_product_codes =PackMaterialProduct.find_by_sql("select id ,pack_material_product_code from pack_material_products").map { |r| [r.pack_material_product_code, r.id ] }

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'bin_number'}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => "production_run_tipped_id",

                                              :settings=>{
                                                  :list => production_run_codes,
                                                  :label_caption => 'production run tipped code'}
                                               }

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                            :field_name => 'pack_material_product_id',

                                             :settings => {
                                              :list=>pack_material_product_codes,
                                             :label_caption =>"pack material product code",:show_label=> true}
                                            }

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'production_run_rebin_id',
#
                                             :settings => {
                                            :list=>production_run_codes,
                                            :label_caption =>'production run rebin code',:show_label=> true}
                                             }

    field_configs[field_configs.length()] = {:field_type=>'DropDownField',
                                             :field_name=>'rmt_product_id',

                                             :settings=>{
                                                 :list =>rmt_product_ids,
                                                 :label_caption => "rmt product code",:show_label=> true,},
                                             :observer =>  rmt_product_observer
                                            }


    field_configs[field_configs.length()] = {:field_type=>'DropDownField',
                                             :field_name=>'coldstore_type',

                                             :settings=>{
                                                 :list =>coldstore_type_codes}
    }


    field_configs[field_configs.length()] = {:field_type=>'DropDownField',:field_name=>'track_indicator1_id',
                                            :settings=>{:list=>track_slms_indicator_ids, :label_caption =>'track indicator1 code'}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',:field_name => 'track_indicator2_id',
                                             :settings => {:list => track_slms_indicator_ids,:label_caption =>'track indicator2 code'}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',:field_name => 'track_indicator3_id',
                                             :settings => {:list => track_slms_indicator_ids, :label_caption =>'track indicator3 code'}}


    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'track_indicator4_id',
                                              :settings => {:list => track_slms_indicator_ids, :label_caption =>'track indicator4 code'}}


    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'track_indicator5_id',
                                              :settings => {:list => track_slms_indicator_ids,:label_caption=> 'track indicator5 code'}}


     field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'rebin_track_indicator_code', :settings => {:list => track_indicator_codes}}



     field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name =>"farm_id",:settings=>{:list =>farm_ids,:label_caption=>'farm_code'}}


     field_configs[field_configs.length()] = {:field_type => 'TextField',
                                              :field_name => "orchard_code"
                                              #:settings=>{:list =>orchard_codes,:label_caption=>'orchard_code'}
                                               }

      field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "is_sample_bin"}
     field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "is_half_bin"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'weight'}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'season_code'}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "bin_receive_date_time"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "rebin_status"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "binfill_station_code"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => "rebin_label_station_code"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField',:field_name => "rebin_date_time"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField',:field_name => "delivery_number"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField',:field_name => "print_number"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField',:field_name => "exit_ref"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField',:field_name => "exit_reference_date_time"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField',:field_name => "tipped_date_time"}
    field_configs[field_configs.length()] = {:field_type => 'LabelField',:field_name => "user_name"}

    build_form(bin, field_configs, action, 'bin', caption, is_edit)
  end

  def build_bulk_tip_bin_form(bin, action, caption, is_edit=nil, is_create_retry=nil)
#        commodity_code_variety_code = RmtProduct.find_by_sql("select commodity_code,variety_code from rmt_products where id ='#{bin.rmt_product_id.to_s}' ")
#       commodity_code=commodity_code_variety_code[0]['commodity_code'].to_s
#       variety_code=commodity_code_variety_code[0]['variety_code']
#       bin_farm_group_code=Farm.find_by_sql("select farm_group_code from farms where id = #{bin.farm_id}")[0]['farm_group_code']

        production_run_codes =ProductionRun.find_by_sql("select production_runs.* from production_runs
         inner join production_schedules on production_runs.production_schedule_id = production_schedules.id
         inner join rmt_setups on rmt_setups.production_schedule_id = production_schedules.id
         inner join farms on production_runs.farm_code=farms.farm_code
         inner join farm_groups on farms.farm_group_id=farm_groups.id
         order by production_runs.production_run_code desc limit 2000").map { |p| [p.production_run_code,p.id ] }

      field_configs = Array.new

      field_configs[field_configs.length()] = {:field_type=>'HiddenField',:field_name=>'bin_id'}



      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                                :field_name => "production_run_tipped_id",

                                               :settings=>{
                                                   :list => production_run_codes,
                                                   :label_caption => 'production run code'}
                                                }
      build_form(bin,field_configs,action,'bin',caption,is_edit)
   end


  def build_tip_bin_form(bin, action, caption, is_edit=nil, is_create_retry=nil)
       commodity_code_variety_code = RmtProduct.find_by_sql("select commodity_code,variety_code from rmt_products where id ='#{bin.rmt_product_id.to_s}' ")
      commodity_code=commodity_code_variety_code[0]['commodity_code'].to_s
      variety_code=commodity_code_variety_code[0]['variety_code']
      bin_farm_group_code=Farm.find_by_sql("select farm_group_code from farms where id = #{bin.farm_id}")[0]['farm_group_code']

       production_run_codes =ProductionRun.find_by_sql("select production_runs.* from production_runs
        inner join production_schedules on production_runs.production_schedule_id = production_schedules.id
        inner join rmt_setups on rmt_setups.production_schedule_id = production_schedules.id
        where production_schedules.season_code='#{bin.season_code}' and rmt_setups.commodity_code = '#{commodity_code}' AND  rmt_setups.variety_code = '#{variety_code}'
        order by production_runs.production_run_code desc limit 2000").map { |p| [p.production_run_code,p.id ] }

     field_configs = Array.new

     field_configs[field_configs.length()] = {:field_type=>'HiddenField',:field_name=>'bin_id'}



     field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => "production_run_tipped_id",

                                              :settings=>{
                                                  :list => production_run_codes,
                                                  :label_caption => 'production run code'}
                                               }
     build_form(bin,field_configs,action,'bin',caption,is_edit)
  end

  def build_rw_rebins_grid(data_set)

    #require File.dirname(__FILE__) + "/../../../app/helpers/production/reworks_received_items_plugin.rb"

    column_configs = Array.new
    if @bulk_rebin_update_permission||@bulk_rebin_update_permission_ltd
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'bulk update',
                                                 :settings =>
                                                         {:image => 'bulk_update',
                                                          :target_action => 'bulk_rebin_update',
                                                          :id_column => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'reworks_remove',
                                                 :settings =>
                                                         {:image => 'reworks_remove',
                                                          :target_action => 'remove_rebin_from_reworks',
                                                          :id_column => 'id'}, :html_options => {:prompt => "Are you sure you want to cancel the reception of this rebin?"}}


      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'scrap rebin',
                                                 :settings =>
                                                         {:image => 'delete',
                                                          :target_action => 'scrap_rebin',
                                                          :id_column => 'id'}, :html_options => {:prompt => "Are you sure you want to scrap this rebin?"}}

    end
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_number'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'username'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exit_ref'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run.production_run_code', :column_caption => "production_run_code"}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "production_run.production_schedule.rmt_setup.variety_code", :column_caption => "input_variety"}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_product_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'weight'}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "production_run.line_code", :column_caption => 'line_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "production_run.farm_code", :column_caption => 'farm_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'transaction_date'}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'track_indicator_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "production_run.production_schedule.season_code", :column_caption => 'season_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}


    set_grid_min_width(1200)
    return get_data_grid(data_set, column_configs, MesScada::GridPlugins::Production::ReworksReceivedRebinsGridPlugin.new)

  end


  def build_rw_bins_grid(data_set,tip_bins=nil,scrap_bins=nil)

    #require File.dirname(__FILE__) + "/../../../app/helpers/production/reworks_received_items_plugin.rb"

    column_configs = Array.new
    if @bulk_bin_update_permission||@bulk_bin_update_permission_ltd
      if tip_bins==nil && scrap_bins==nil
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'bulk_update', :col_width => 43,
                                                 :settings =>
                                                         {:image => 'bulk_update',
                                                          :target_action => 'bulk_bin_update',
                                                          :id_column => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'reworks_remove',  :col_width => 43,
                                                 :settings =>
                                                         {:image => 'reworks_remove',
                                                          :target_action => 'remove_bin_from_reworks',
                                                          :id_column => 'id'}, :html_options => {:prompt => "Are you sure you want to cancel the reception of this bin?"}}



      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'weigh_bin', :col_width => 43,
                                                 :settings =>
                                                     {:image => 'scale',
                                                      :target_action => 'weigh_bin',
                                                      :id_column => 'id'}}


      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'scrap_bin', :col_width => 43,
                                                 :settings =>
                                                         {:image => 'delete',
                                                          :target_action => 'scrap_bin',
                                                          :id_column => 'id'}, :html_options => {:prompt => "Are you sure you want to scrap this bin?"}}

      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'tip_bin', :col_width => 43,
                                                 :settings =>
                                                         {:image => 'tip_bin',
                                                          :target_action => 'tip_bins',
                                                          :id_column => 'id'}}

        column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'bulk_tip_bin', :col_width => 43,
                                                 :settings =>
                                                         {:image => 'tip_bin',
                                                          :target_action => 'bulk_tip_bins',
                                                          :id_column => 'id'}}
      end
      if tip_bins!=nil
         @multi_select = "receceive_tip_bins"
      elsif scrap_bins!= nil
       #  column_configs << {:field_type => 'action',:field_name => 'scrap_bin',  :col_width => 43,
			#:settings =>
			#	 {:link_text => '',
			#	:target_action => '',
			#	:id_column => 'id'}}
         @multi_select = "receive_scrap_bins"
      end

    end
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_number', :col_width => 124}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_product_code', :col_width => 255}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'weight', :col_width => 68}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_on', :col_width => 133}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_tipped', :col_width => 155}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'reworks_action', :column_caption=>'bin_tip_status', :col_width => 71}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_rebin', :col_width => 155}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code1',:column_caption =>'ti_1', :col_width => 50}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_status', :col_width => 66}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code', :col_width => 66}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'product_class_code', :col_width => 50,:column_caption => 'class'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_code', :col_width => 136}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'ripe_point_code', :col_width => 57}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'size_code', :col_width => 57}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'stock_type_code', :col_width => 60}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'sealed_ca_location_code', :col_width => 119}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'cold_store_type_code', :col_width => 50}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_receive_date_time', :col_width => 136}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pack_material_product_code', :col_width => 66}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_track_indicator_code', :col_width => 80,:column_caption => 'rebin_ti'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code2',:column_caption =>'track_slms_indicator2', :col_width => 80,:column_caption => 'ti_2'}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'orchard_code', :col_width => 92}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'season_code', :col_width => 88}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'binfill_station_code', :col_width => 70}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_date_time', :col_width => 134}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exit_ref', :col_width => 80}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'tipped_date_time', :col_width => 140}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exit_reference_date_time', :col_width => 140}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'print_number', :col_width => 90}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'user_name', :col_width => 90}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}

    set_grid_min_width(1200)
     return get_data_grid(data_set, column_configs, MesScada::GridPlugins::Production::ReworksReceivedBinsGridPlugin.new,true)

  end


  def build_pallets_grid(data_set, multi_select=nil)

    column_configs = Array.new


    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pallet_number',:col_width => 155}


    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "attributes['production_run_code']", :column_caption => "run_code", :col_width => 155}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'fg_product_code',:col_width => 280}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "attributes['farm_code']", :column_caption => "farm_code",:col_width => 100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'fg_code_old', :col_width => 135}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_quantity_actual',:col_width => 90,:column_caption => 'ctn_qty'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'organization_code',:col_width => 120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'grade_code',:col_width => 110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inventory_code', :col_width => 125}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'target_market_code',:col_width => 125}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => "attributes['line_code']", :column_caption => "line_code",:col_width => 100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'order_number',:col_width => 110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'date_time_completed',:col_width => 135}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'date_time_created',:col_width => 135}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'oldest_pack_date_time',:col_width => 135}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pick_reference_code',:col_width => 130}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'qc_status_code',:col_width => 130}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}


    if controller.controller_name != "reworks"
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'pallet_view',
                                                 :settings =>
                                                         {:link_text => 'view_pallet',
                                                          :target_action => 'view_pallet',
                                                          :id_column => 'id'}}
    end
    #:::::::::::: LUKS CHANGE - removing the multiselect option from the pallets form::::
    @multi_select = "selected_pallets" if multi_select


    return get_data_grid(data_set, column_configs)

  end

  def build_rw_cartons_grid(data_set, is_pallet_cartons = nil)

    column_configs = Array.new
    #require File.dirname(__FILE__) + "/../../../app/helpers/production/reworks_received_items_plugin.rb"
    if @can_control_run == true
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'reclassify',:col_width =>  50,
                                                 :settings =>
                                                         {:image => 'reclassify',
                                                          :target_action => 'reclassify_carton',
                                                          :id_column => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'print',:col_width => 50,
                                                 :settings =>
                                                         {:image => 'label_print',
                                                          :target_action => 'print_carton_label',
                                                          :id_column => 'id'}}


      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'n_labels_printed',:column_caption => "print_count",:col_width => 80,}



      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'view',:col_width =>  35,
                                                 :settings =>
                                                         {:image => 'view',
                                                          :target_action => 'view_carton',
                                                          :id_column => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'repack', :col_width =>  35,
                                                 :settings =>
                                                         {:image => 'repack',
                                                          :target_action => 'repack_carton',
                                                          :id_column => 'id'}}
      if !is_pallet_cartons
        column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'reworks_remove',:col_width =>  35,
                                                   :settings =>
                                                           {:image => 'reworks_remove',
                                                            :target_action => 'remove_carton_from_reworks',
                                                            :id_column => 'id'}, :html_options => {:prompt => "Are you sure you want to cancel the reception of this carton?"}}


        column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'scrap', :col_width =>  35,
                                                   :settings =>
                                                           {:image => 'delete',
                                                            :target_action => 'scrap_carton',
                                                            :id_column => 'id'}, :html_options => {:prompt => "Are you sure you want to scrap this carton?"}}


        if @bulk_carton_update_permission
          column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'bulk update',:col_width =>  35,
                                                     :settings =>
                                                             {:image => 'bulk_update',
                                                              :target_action => 'bulk_carton_update',
                                                              :id_column => 'id'}}
        end

      end

      if is_pallet_cartons
        column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'remove_carton', :col_width =>  35,
                                                   :settings =>
                                                           {:image => 'remove_carton',
                                                            :target_action => 'remove_carton',
                                                            :id_column => 'id'}, :html_options => {:prompt => "Are you sure you want to remove this carton from the pallet?"}}
      end

    end
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_number',:col_width =>  104,}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pallet_number',:col_width =>  146,}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'reworks_action',:col_width =>  130,:column_caption => 'rw_action'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rw_receipt_unit',:col_width =>  115}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rw_pallet_action',:col_width =>  64}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_code',:col_width =>  160}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'erp_cultivar',:col_width =>  160}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'track_indicator_code', :column_caption => "ti",:col_width =>  40}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code',:col_width =>  100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'puc',:col_width =>  55}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'account_code',:col_width =>  110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'fg_code_old',:col_width =>  135}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'organization_code',:col_width =>  120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'grade_code',:col_width =>  100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inspection_type_code',:col_width =>  55,:column_caption => 'inspect_type'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inventory_code',:col_width =>  110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'target_market_code',:col_width =>  120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'fg_mark_code',:col_width =>  160}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'extended_fg_code',:col_width =>  529}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'line_code',:col_width =>  100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'order_number',:col_width =>  136}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pack_date_time',:col_width =>  142}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pick_reference',:col_width =>  110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pc_code',:col_width =>  80}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'is_inspection_carton',:col_width =>  180}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'shift_id',:col_width =>  100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'packer_number',:col_width =>  120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'marking',:col_width =>  94}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'diameter',:col_width =>  94}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_fruit_nett_mass',:col_width =>  63,:column_caption => 'mass'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'n_labels_printed'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'remarks'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_id'}
#	----------------------
#	define action columns
#	----------------------



    return get_data_grid(data_set, column_configs) #,ReworksPlugins::ReworksReceivedCartonsPlugin.new)

  end


  def build_select_carton_grid(cartons, action)

    column_configs = Array.new

    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'select carton',
                                               :settings =>
                                                       {:link_text => 'select',
                                                        :target_action => action,
                                                        :id_column => 'id'}}


    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_number'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'reworks_action'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rw_pallet_action'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'fg_product_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'track_indicator_code', :column_caption => "ti"}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inventory_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'line_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'order_number'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pack_date_time'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'is_inspection_carton'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pallet_number'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'is_inspection_carton'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'qc_datetime_in'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'qc_datetime_out'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'shift_code'}

#	----------------------
#	define action columns
#	----------------------


    return get_data_grid(cartons, column_configs)


  end


  def build_print_pallet_form(pallet_update)


    field_configs = Array.new
    group_num = 0



    pallet_update.puc_groups.each do |run_name, run_group|
      group_num += 1
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => "group_" + group_num.to_s, :settings =>
                      {:static_value => "run group: " + run_name, :is_separator => false}}

      count = run_group[:cartons].length.to_s


      css_class =  'selected_group_carton'
     if session[:last_printed_group] &&  session[:last_printed_group] == run_name
          css_class = 'last_printed_group'
     end


      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => "group_count" + group_num.to_s, :settings =>
                      {:static_value => "carton count: " + count, :is_separator => false,
                       :css_class => 'selected_group_carton'}}

      print_url  = "http://" + request.host_with_port + "/production/reworks/print_group/" + run_name

      load_image = image_tag('loading.gif', :id => 'loading' + group_num.to_s, :align => 'absmiddle', :border=> 0, :style=>'visibility: hidden')
      onclick = "if(!confirm(\"Are you sure you want to print labels for all " + count.to_s + " cartons in this group?\"))return false; else {show_action_image(this);}"
      print_link = link_to_remote(image_tag("label_print.png"), {:update => "result" + group_num.to_s + "_cell", :url => print_url}, {:onclick => onclick})

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => "result" + group_num.to_s, :settings =>
                      {:static_value => print_link + load_image, :is_separator => false,
                       :css_class =>  css_class}}


    end

    build_form(nil, field_configs, nil, 'update_pallet', "update all groups")

  end

  def build_batch_update_pallet_form(pallet_update)

    #--------------------------------------------------------------------------------------------
    #This form needs to display the following:
    # for each production run
    #   -> a link represebting the run, which when clicked, provides the user with a
    #     list of cartons for that run, from which the user must select one
    #   -> a link, representing the selected carton, which, when clicked, provides the
    #      user with an edit form for the selected carton
    #A 'save' button' which will batch-update the entire pallet
    #--------------------------------------------------------------------------------------------
    field_configs = Array.new
    group_num = 0


    pallet_update.puc_groups.each do |run_name, run_group|
      group_num += 1
      run_group[:group_num]= group_num
      run_group[:main_group]= true if group_num == 1

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => "group_" + group_num.to_s, :settings =>
                      {:static_value => "run group: " + run_name, :is_separator => false}}

      count = run_group[:cartons].length.to_s

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => "group_count" + group_num.to_s, :settings =>
                      {:static_value => "carton count: " + count, :is_separator => false,
                       :css_class => 'selected_group_carton'}}

      selected_carton = " [not yet selected] "

      selected_carton_url = "http://" + request.host_with_port + "/production/reworks/edit_repr_carton/" + run_name if run_group[:representative_carton]
      selected_carton = link_to(run_group[:representative_carton].carton_number.to_s + "&nbsp;&nbsp", selected_carton_url) if run_group[:representative_carton]

      select_url = "http://" + request.host_with_port + "/production/reworks/select_carton_for_run_group/" + run_name

      select_link = link_to("select carton", select_url, {:class => "action_link"})

      selected_carton_label = "selected carton: " + selected_carton + "&nbsp;&nbsp;"


      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => " ", :settings =>
                      {:static_value => selected_carton_label + select_link, :is_separator => false,
                       :css_class => 'selected_group_carton'}}


      if group_num == 1
        select_pfp_url = "http://" + request.host_with_port + "/production/reworks/set_pallet_format_product/"
        cpp_details = ""
        if pallet_update.fg_carton
          if !pallet_update.fg_carton.carton_pack_product_code
            pallet_update.fg_carton.decompose_fields
          end
          cpp = CartonsPerPallet.find_by_pallet_format_product_code_and_carton_pack_product_code(pallet_update.pallet.pallet_format_product_code, pallet_update.fg_carton.carton_pack_product_code)

          puts "OO: PFP: " + pallet_update.pallet.pallet_format_product_code + "CPP: " + pallet_update.fg_carton.carton_pack_product_code
          if cpp
            cpp_details = "<BR><strong>Cartons Per Pallet detail: </strong> <BR>"
            cpp_details += "<font size = 'smallest'>cartons per pallet: " + cpp.cartons_per_pallet.to_s + "<BR>"
            cpp_details += "layers per pallet: " + cpp.layers_per_pallet.to_s + "<BR>"
            cpp_details += "cartons per layer: " + cpp.cartons_per_layer.to_s + "<BR>"
            cpp_details += "cpp code: " + cpp.cpp_code.to_s + "<BR>"
            cpp_details += "cpp description: " + cpp.description.to_s + "<BR>"
            cpp_details += "carton pack product code: " + pallet_update.fg_carton.carton_pack_product_code + "</font>"
          else
            cpp_details = "Cartons per pallet record not found"
          end
          selected_pfp = link_to(pallet_update.pallet.pallet_format_product_code, select_pfp_url)
        else
          selected_pfp = "[FG carton not yet selected]"
        end


        field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                 :field_name => " ", :settings =>
                        {:static_value => "pallet format product: " + selected_pfp + cpp_details, :is_separator => false,
                         :css_class => 'selected_group_field_blue'}}

      end

    end

    build_form(nil, field_configs, "batch_update_pallet_submit", 'update_pallet', "update all groups")

  end


  def build_set_pfp_form(pallet_transaction)

    on_complete_js = "\n img = document.getElementById('img_pallet_pallet_format_product_code');"
    on_complete_js += "\n if(img != null)img.style.display = 'none';"

    on_complete_js = ""
    pfp_observer  = {:updated_field_id => "cpp_details_cell",
                     :remote_method => 'pallet_pfp_changed',
                     :on_complete_js => on_complete_js}

    @pallet = pallet_transaction.pallet


    cpp = CartonsPerPallet.find_by_pallet_format_product_code_and_carton_pack_product_code(@pallet.pallet_format_product_code, pallet_transaction.fg_carton.carton_pack_product_code)

    puts "PFP: " + pallet_transaction.pallet.pallet_format_product_code + "CPP: " + pallet_transaction.fg_carton.carton_pack_product_code
    if cpp
      cpp_details = "<BR><strong>Cartons Per Pallet detail: </strong> <BR>"
      cpp_details += "<font size = 'smallest'>cartons per pallet: " + cpp.cartons_per_pallet.to_s + "<BR>"
      cpp_details += "layers per pallet: " + cpp.layers_per_pallet.to_s + "<BR>"
      cpp_details += "cartons per layer: " + cpp.cartons_per_layer.to_s + "<BR>"
      cpp_details += "cpp code: " + cpp.cpp_code.to_s + "<BR>"
      cpp_details += "cpp description: " + cpp.description.to_s + "<BR>"
      cpp_details += "carton pack product code: " + pallet_transaction.fg_carton.carton_pack_product_code + "</font>"
    else
      cpp_details = "Cartons per pallet record not found for pfp: " + @pallet.pallet_format_product_code
    end


    cpp_codes = CartonsPerPallet.find_all_by_carton_pack_product_code(pallet_transaction.fg_carton.carton_pack_product_code).map { |p| [p.pallet_format_product_code] }
    if cpp_codes.length() == 0
      cpp_details = "No cartons per pallet records found for carton pack product code: " + pallet_transaction.fg_carton.carton_pack_product_code
    end

    @pallet.cpp_details = cpp_details
    field_configs = Array.new

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'pallet_format_product_code',
                                              :settings => {:list => cpp_codes},
                                              :observer => pfp_observer}

    field_configs[1] =  {:field_type => 'LabelField',
                         :field_name => 'cpp_details'}

    build_form(@pallet, field_configs, 'set_pfp_submit', 'pallet', 'save')

  end


  def build_pallet_repack_commit_form(need_reason = true)


#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new


    field_configs[field_configs.length()] =  {:field_type => 'TextArea',
                                              :field_name => "reason", :settings => {:cols =>40, :label_caption => ""}} if need_reason


    build_form(nil, field_configs, 'pallet_repack_commit_confirmed', 'repack_commit', 'commit')

  end


  def build_repack_pallet_form(pallet_update, repack_info)

    #--------------------------------------------------------------------------------------------
    #This form needs to display the following:
    # for each production run
    #   -> a link representing the run, which when clicked, provides the user with a
    #     list of cartons for that run, from which the user must select one
    #   -> a link, representing the selected carton, which, when clicked, provides the
    #      user with an edit form for the selected carton
    #   -> Labels, depicting the following info:
    #      -> total weight
    #      -> (n) of original cartons
    #      -> ratio (as % of total)
    #      THE ABOVE 3 PIECES OF INFO NEED TO BE CALCULATED
    #   -> a textBox that allows the user to override the calculated amount of cartons
    #
    # The first group need to act as the fg defining group, i.e it's representative carton
    # needs to act as the single place for defining the fg-and-weight-related fields for all
    # the cartons on the pallet. Following points are relavant:
    # -> On every save action of the repr. carton of this group, the in-memory state of all the cartons on the
    #    pallet needs to be updated (using the pallet_update class' 'set_carton_fg_data (carton)' method
    #
    # The system-calculated amounts and ratios will be calculated  once, on the initial creation
    # of the pallet_update class. These initially calculated ratios will be used throughout, except
    # if the user overrided the amounts per group
    #
    #A dropdown allowing the user to select a new new pallet, instead of the old pallet
    #A 'save' button' which will batch-update the entire pallet
    #--------------------------------------------------------------------------------------------
    field_configs = Array.new

    group_num = 0
    pallet_update.puc_groups.each do |run_name, run_group|
      group_num += 1
      run_group[:group_num]= group_num

      css_class = "heading_field"
      css_class = "dark_heading_field" if group_num == 1


      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => " ", :settings =>
                      {:static_value => "run group: " + run_name, :is_separator => false,
                       :css_class => css_class}}

      count = run_group[:cartons].length.to_s

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => "group_count" + group_num.to_s, :settings =>
                      {:static_value => "original carton count: " + count, :is_separator => false,
                       :css_class => 'selected_group_carton'}}

      selected_carton = " [not yet selected] "
      selected_carton_url = "http://" + request.host_with_port + "/production/reworks/edit_repr_repack_carton/" + run_name
      selected_carton = link_to("<font color = 'blue'>" + run_group[:representative_carton].carton_number.to_s + "</font>&nbsp;&nbsp", selected_carton_url) if run_group[:representative_carton]


      selected_carton_label = "selected carton: " + selected_carton + "&nbsp;&nbsp;"
      select_url = "http://" + request.host_with_port + "/production/reworks/select_carton_for_repack/" + run_name

      select_link = link_to("select carton", select_url, {:class => "action_link"})

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => " ", :settings =>
                      {:static_value => selected_carton_label + select_link, :is_separator => false,
                       :css_class => 'selected_group_carton'}}

      total_orig_weight = run_group[:weight]
      ratio = Float.round_float(2, run_group[:ratio].to_f).to_s

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => " ", :settings =>
                      {:static_value => "original weight of group: " + total_orig_weight.to_s, :is_separator => false,
                       :css_class => 'selected_group_carton'}}

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => " ", :settings =>
                      {:static_value => "group weight ratio(% of total): " + ratio, :is_separator => false,
                       :css_class => 'selected_group_carton'}}

      field_configs[field_configs.length()] = {:field_type => 'TextField',
                                               :field_name => "txt_" + run_name.gsub(" ", "_"), :settings =>
                      {:label_caption => "override count"}}

      if group_num == 1
        select_pfp_url = "http://" + request.host_with_port + "/production/reworks/set_pallet_format_product/"
        cpp_details = ""
        if pallet_update.fg_carton
          if !pallet_update.fg_carton.carton_pack_product_code
            pallet_update.fg_carton.decompose_fields
          end
          cpp = CartonsPerPallet.find_by_pallet_format_product_code_and_carton_pack_product_code(pallet_update.pallet.pallet_format_product_code, pallet_update.fg_carton.carton_pack_product_code)

          puts "OO: PFP: " + pallet_update.pallet.pallet_format_product_code + "CPP: " + pallet_update.fg_carton.carton_pack_product_code
          if cpp
            cpp_details = "<BR><strong>Cartons Per Pallet detail: </strong> <BR>"
            cpp_details += "<font size = 'smallest'>cartons per pallet: " + cpp.cartons_per_pallet.to_s + "<BR>"
            cpp_details += "layers per pallet: " + cpp.layers_per_pallet.to_s + "<BR>"
            cpp_details += "cartons per layer: " + cpp.cartons_per_layer.to_s + "<BR>"
            cpp_details += "cpp code: " + cpp.cpp_code.to_s + "<BR>"
            cpp_details += "cpp description: " + cpp.description.to_s + "<BR>"
            cpp_details += "carton pack product code: " + pallet_update.fg_carton.carton_pack_product_code + "</font>"
          else
            cpp_details = "Cartons per pallet record not found"
          end
          selected_pfp = link_to(pallet_update.pallet.pallet_format_product_code, select_pfp_url)
        else
          selected_pfp = "[FG carton not yet selected]"
        end


        field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                 :field_name => " ", :settings =>
                        {:static_value => "pallet format product: " + selected_pfp + cpp_details, :is_separator => false,
                         :css_class => 'selected_group_field_blue'}}

      end
    end


    new_pallets = RwActivePallet.find_all_by_is_new_pallet_and_rw_run_id(true, pallet_update.pallet.rw_run_id).map { |p| [p.pallet_number] }
    new_pallets.unshift("<use existing pallet>")

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => " ", :settings =>
                    {:static_value => "total pallet info", :is_separator => false}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'target_pallet',
                                              :settings => {:list => new_pallets, :no_empty => true}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => " ", :settings =>
                    {:static_value => "total original weight: " + pallet_update.total_weight.to_s, :is_separator => false,
                     :css_class => 'selected_group_carton'}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => " ", :settings =>
                    {:static_value => "total original carton count: " + pallet_update.total_count.to_s, :is_separator => false,
                     :css_class => 'selected_group_carton'}}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => "total_cartons", :settings =>
                    {:label_caption => "override total count"}}


    build_form(repack_info, field_configs, "repack_pallet_submit", 'repack_pallet_info', "continue >>", nil, nil, nil, true)

  end


  def build_rw_pallets_grid(data_set)

    column_configs = Array.new
    action_links=[]
    action_configs=[]
     if @can_do_buildup
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'buildup',:col_width =>  39,
                                                 :settings =>
                                                         {:image => 'buildup',
                                                          :target_action => 'buildup',
                                                          :id_column => 'id'}}

    end

    if @can_control_run == true
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'reclassify', :col_width =>  39,
                                                 :settings =>
                                                         {:image => 'reclassify',
                                                          :target_action => 'reclassify_pallet',
                                                          :id_column => 'id'}}


      if @bulk_pallet_update_permission||@bulk_pallet_update_permission_ltd
        column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'bulk update', :col_width =>  39,
                                                   :settings =>
                                                           {:image => 'bulk_update',
                                                            :target_action => 'bulk_pallet_update',
                                                            :id_column => 'id'}}
      end

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'repack',:col_width =>  39,
                                                 :settings =>
                                                         {:image => 'repack',
                                                          :target_action => 'repack_pallet',
                                                          :id_column => 'id'}}


      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'print',:col_width =>  39,
                                                 :settings =>
                                                         {:image => 'label_print',
                                                          :target_action => 'print_pallet',
                                                          :id_column => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'add cartons',:col_width =>  39,
                                                 :settings =>
                                                         {:image => 'add_carton',
                                                          :target_action => 'add_carton_to_pallet',
                                                          :id_column => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'scrap cartons',:col_width =>  39,
                                                 :settings =>
                                                         {:image => 'scrap_ctns',
                                                          :target_action => 'scrap_pallet_cartons',
                                                          :id_column => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'remove_cartons',:col_width =>  39,
                                                 :settings =>
                                                         {:image => 'remove_carton',
                                                          :target_action => 'remove_cartons',
                                                          :id_column => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'scrap pallet',:col_width =>  39,
                                                 :settings =>
                                                         {:image => 'delete',
                                                          :target_action => 'scrap_pallet',
                                                          :id_column => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'view cartons',:col_width =>  39, :column_caption => 'cartons',
                                                 :settings =>
                                                         {:image => 'list_cartons',
                                                          :target_action => 'list_pallet_cartons',
                                                          :id_column => 'id'}}

    end
    #action_configs << {:field_type => 'sub_menu', :field_name => 'sub_menu', :column_caption => 'Action', :settings => {:actions => action_links}}
    #column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pallet_number',:col_width =>  146}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'reworks_action',:col_width =>  140}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'build_up_balance',:col_width =>  160}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'account_code',:col_width =>  120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'build_status',:col_width =>  120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_quantity_actual',:col_width =>  64,:column_caption => 'ctn_qty'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run.production_run_code',:col_width =>  140,:column_caption => 'run_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'fg_product_code',:col_width =>  305}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'class_code',:col_width =>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'grade_code',:col_width =>  100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code',:col_width => 120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inventory_code',:col_width =>  104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_mark_code',:column_caption => 'mark',:col_width =>  110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'target_market_code',:col_width =>  130}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pallet_format_product_code',:col_width => 160}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'oldest_pack_date_time',:col_width =>  180}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'organization_code',:col_width =>  150}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inspect_type_code',:col_width =>  150}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'qc_status_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'date_time_completed'}
    #column_configs[17] = {:field_type => 'text',:field_name => 'rejected'}


#	----------------------
#	define action columns
#	----------------------




    return get_data_grid(data_set, column_configs, MesScada::GridPlugins::Production::ReworksReceivedPalletsGridPlugin.new)

  end

  def build_carton_search_form

    on_complete_js = "\n img = document.getElementById('img_carton_time_search');"
    on_complete_js += "\n if(img != null)img.style.display = 'none';"

    time_search_observer  = {:updated_field_id => "ajax_distributor_cell",
                             :remote_method => 'time_search_enabled',
                             :on_complete_js => on_complete_js}

    @carton = Carton.new
    #@carton.fg_product_code = "<empty>"
    #@carton.unit_pack_product_code = "<empty>"
    #@carton.item_pack_product_code = "<empty>"
    #@carton.carton_pack_product_code = "<empty>"
    #@carton.grade_code = "<empty>"
    #@carton.pc_code = "<empty>"
    #@carton.track_indicator_code = "<empty>"
    #@carton.line_code = "<empty>"
    #@carton.farm_code = "<empty>"
    #@carton.production_schedule_name = "<empty>"
    #@carton.production_run_code = "<empty>"
    #@carton.inventory_code = "<empty>"
    #@carton.target_market_code = "<empty>"
    #@carton.organization_code = "<empty>"
    #@carton.fg_mark_code = "<empty>"

    fg_product_codes = FgProduct.find(:all).map { |f| [f.fg_product_code] }
    fg_mark_codes = FgMark.find(:all).map { |f| [f.fg_mark_code] }
    fg_mark_codes.unshift("<empty>")
    fg_product_codes.unshift("<empty>")
    unit_pack_product_codes = UnitPackProduct.find(:all).map { |f| [f.unit_pack_product_code] }
    unit_pack_product_codes.unshift("<empty>")
    carton_pack_product_codes = CartonPackProduct.find(:all).map { |f| [f.carton_pack_product_code] }
    carton_pack_product_codes.unshift("<empty>")
    item_pack_product_codes = ItemPackProduct.find(:all).map { |f| [f.item_pack_product_code] }
    item_pack_product_codes.unshift("<empty>")
    grade_codes = Grade.find(:all).map { |f| [f.grade_code] }
    grade_codes.unshift("<empty>")
    pc_codes = PcCode.find(:all).map { |f| [f.pc_code] }
    pc_codes.unshift("<empty>")
    track_indicator_codes = TrackIndicator.find(:all).map { |f| [f.track_indicator_code] }
    track_indicator_codes.unshift("<empty>")
    production_run_codes = ProductionRun.find_by_sql("select distinct production_run_code from production_runs").map { |f| [f.production_run_code] }
    production_run_codes.unshift("<empty>")
    farm_codes = Farm.find(:all).map { |f| [f.farm_code] }
    farm_codes.unshift("<empty>")
    target_market_codes = TargetMarket.find(:all).map { |f| [f.target_market_name] }
    target_market_codes.unshift("<empty>")
    line_codes = Line.find(:all).map { |f| [f.line_code] }
    line_codes.unshift("<empty>")
    production_schedule_names = ProductionSchedule.find(:all).map { |f| [f.production_schedule_name] }
    production_schedule_names.unshift("<empty>")
    inventory_codes = InventoryCode.find(:all).map { |f| [f.inventory_code] }
    inventory_codes.unshift("<empty>")
    organization_codes =  Organization.get_all_by_role("MARKETER")
    organization_codes.unshift("<empty>")
    season_codes = Season.find_by_sql("Select distinct season from seasons").map { |f| [f.season] }
    season_codes.unshift("<empty>")

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'carton_number'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'pallet_number'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'iso_week_code'}

    field_configs[field_configs.length()] = {:field_type => 'CheckBox',
                                             :field_name => 'time_search',
                                             :observer => time_search_observer}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'pack_date_from'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'pack_date_to'}


    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'fg_product_code',
                                              :settings => {:list => fg_product_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'fg_mark_code',
                                              :settings => {:list => fg_mark_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'item_pack_product_code',
                                              :settings => {:list => item_pack_product_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'unit_pack_product_code',
                                              :settings => {:list => unit_pack_product_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'carton_pack_product_code',
                                              :settings => {:list => carton_pack_product_codes}}


    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'grade_code',
                                              :settings => {:list => grade_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'pc_code',
                                              :settings => {:list => pc_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'track_indicator_code',
                                              :settings => {:list => track_indicator_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'farm_code',
                                              :settings => {:list => farm_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'line_code',
                                              :settings => {:list => line_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'production_schedule_name',
                                              :settings => {:list => production_schedule_names}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'production_run_code',
                                              :settings => {:list => production_run_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'inventory_code',
                                              :settings => {:list => inventory_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'season_code',
                                              :settings => {:list => season_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'target_market_code',
                                              :settings => {:list => target_market_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'organization_code',
                                              :settings => {:list => organization_codes}}


    field_configs[field_configs.length()] = {:field_type => 'HiddenField',
                                             :field_name => 'ajax_distributor',
                                             :non_db_field => true}

    build_form(@carton, field_configs, "carton_search_submit", 'carton', 'search')

  end


  def build_rebin_search_form

    on_complete_js = "\n img = document.getElementById('img_rebin_time_search');"
    on_complete_js += "\n if(img != null)img.style.display = 'none';"

    time_search_observer  = {:updated_field_id => "ajax_distributor_cell",
                             :remote_method => 'rebin_time_search_enabled',
                             :on_complete_js => on_complete_js}


    rmt_product_codes = RmtProduct.find_all_by_rmt_product_type_code('rebin').map { |f| [f.rmt_product_code] }
    rmt_product_codes.unshift("<empty>")

    pc_codes = PcCode.find(:all).map { |f| [f.pc_code] }
    pc_codes.unshift("<empty>")
    track_indicator_codes = TrackIndicator.find(:all).map { |f| [f.track_indicator_code] }
    track_indicator_codes.unshift("<empty>")
    production_run_codes = ProductionRun.find_by_sql("select distinct production_run_code from production_runs").map { |f| [f.production_run_code] }
    production_run_codes.unshift("<empty>")
    farm_codes = Farm.find(:all).map { |f| [f.farm_code] }
    farm_codes.unshift("<empty>")

    line_codes = Line.find(:all).map { |f| [f.line_code] }
    line_codes.unshift("<empty>")
    production_schedule_names = ProductionSchedule.find(:all).map { |f| [f.production_schedule_name] }
    production_schedule_names.unshift("<empty>")

    usernames = User.find_by_sql("select distinct user_name from users").map { |f| [f.user_name] }
    usernames.unshift("<empty>")

    input_varieties = RmtVariety.find(:all).map { |f| [f.rmt_variety_code] }
    input_varieties.unshift("<empty>")

    season_codes = Season.find_by_sql("Select distinct season_code from seasons").map { |f| [f.season_code] }
    season_codes.unshift("<empty>")


    @rebin = Rebin.new
    #@rebin.username = "<empty>"
    #@rebin.rmt_product_code = "<empty>"
    #@rebin.input_variety = "<empty>"
    #@rebin.pc_code = "<empty>"
    #@rebin.track_indicator_code = "<empty>"
    #@rebin.line_code = "<empty>"
    #@rebin.production_schedule_name = "<empty>"
    #@rebin.production_run_code = "<empty>"
    #@rebin.season_code = "<empty>"
    #@rebin.farm_code = "<empty>"

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'rebin_number'}

    field_configs[field_configs.length()] = {:field_type => 'CheckBox',
                                             :field_name => 'rebin_time_search',
                                             :observer => time_search_observer}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'trans_date_from'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'trans_date_to'}


    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'rmt_product_code',
                                              :settings => {:list => rmt_product_codes}}


    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'pc_code',
                                              :settings => {:list => pc_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'track_indicator_code',
                                              :settings => {:list => track_indicator_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'farm_code',
                                              :settings => {:list => farm_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'line_code',
                                              :settings => {:list => line_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'production_schedule_name',
                                              :settings => {:list => production_schedule_names}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'production_run_code',
                                              :settings => {:list => production_run_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'username',
                                              :settings => {:list => usernames, :label_caption => 'operator'}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'season_code',
                                              :settings => {:list => season_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'input_variety',
                                              :settings => {:list => input_varieties}}


    field_configs[field_configs.length()] = {:field_type => 'HiddenField',
                                             :field_name => 'ajax_distributor',
                                             :non_db_field => true}

    build_form(@rebin, field_configs, "rebin_search_submit", 'rebin', 'search')

  end


  def build_pallet_search_form

    on_complete_js = "\n img = document.getElementById('img_pallet_time_search');"
    on_complete_js += "\n if(img != null)img.style.display = 'none';"

    time_search_observer  = {:updated_field_id => "ajax_distributor_cell",
                             :remote_method => 'pallet_time_search_enabled',
                             :on_complete_js => on_complete_js}

    @pallet = Pallet.new
    #@pallet.fg_product_code = "<empty>"
    #@pallet.unit_pack_product_code = "<empty>"
    #@pallet.item_pack_product_code = "<empty>"
    #@pallet.carton_pack_product_code = "<empty>"
    #@pallet.grade_code = "<empty>"
    #@pallet.pc_code = "<empty>"
    #@pallet.line_code = "<empty>"
    #@pallet.production_schedule_name = "<empty>"
    #@pallet.production_run_code = "<empty>"
    #@pallet.inventory_code = "<empty>"
    #@pallet.farm_code = "<empty>"
    #@pallet.marketing_variety_code = "<empty>"
    #@pallet.organization_code = "<empty>"
    #@pallet.target_market_code = "<empty>"


    fg_product_codes = FgProduct.find(:all).map { |f| [f.fg_product_code] }
    fg_product_codes.unshift("<empty>")
    unit_pack_product_codes = UnitPackProduct.find(:all).map { |f| [f.unit_pack_product_code] }
    unit_pack_product_codes.unshift("<empty>")
    carton_pack_product_codes = CartonPackProduct.find(:all).map { |f| [f.carton_pack_product_code] }
    carton_pack_product_codes.unshift("<empty>")
    item_pack_product_codes = ItemPackProduct.find(:all).map { |f| [f.item_pack_product_code] }
    item_pack_product_codes.unshift("<empty>")
    grade_codes = Grade.find(:all).map { |f| [f.grade_code] }
    grade_codes.unshift("<empty>")
    pc_codes = PcCode.find(:all).map { |f| [f.pc_code] }
    pc_codes.unshift("<empty>")


    farm_codes = Farm.find(:all).map { |f| [f.farm_code] }
    farm_codes.unshift("<empty>")
    target_market_codes = TargetMarket.find(:all).map { |f| [f.target_market_name] }
    target_market_codes.unshift("<empty>")
    line_codes = Line.find(:all).map { |f| [f.line_code] }
    line_codes.unshift("<empty>")

    #inventory_codes = InventoryCode.find(:all).map { |f| [f.inventory_code] }
    inventory_codes = InventoryCode.find_by_sql("Select inventory_code||'_'||inventory_name as inventory_code from inventory_codes").map { |f| [f.inventory_code] }
    inventory_codes.unshift("<empty>")
    organization_codes =  Organization.get_all_by_role("MARKETER")
    organization_codes.unshift("<empty>")
    season_codes = Season.find_by_sql("Select distinct season from seasons").map { |f| [f.season] }
    marketing_variety_codes = MarketingVariety.find_by_sql("Select distinct marketing_variety_code from marketing_varieties").map { |f| [f.marketing_variety_code] }
    season_codes.unshift("<empty>")
    marketing_variety_codes.unshift("<empty>")

    field_configs = Array.new


    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'pallet_number'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'iso_week_code'}

    field_configs[field_configs.length()] = {:field_type => 'CheckBox',
                                             :field_name => 'pallet_time_search',
                                             :observer => time_search_observer}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'completed_date_from'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'completed_date_to'}


    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'fg_product_code',
                                              :settings => {:list => fg_product_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'marketing_variety_code',
                                              :settings => {:list => marketing_variety_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'item_pack_product_code',
                                              :settings => {:list => item_pack_product_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'unit_pack_product_code',
                                              :settings => {:list => unit_pack_product_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'carton_pack_product_code',
                                              :settings => {:list => carton_pack_product_codes}}


    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'grade_code',
                                              :settings => {:list => grade_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'pc_code',
                                              :settings => {:list => pc_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'farm_code',
                                              :settings => {:list => farm_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'line_code',
                                              :settings => {:list => line_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'TextField',
                                              :field_name => 'production_schedule_name'}

    field_configs[field_configs.length()] =  {:field_type => 'TextField',
                                              :field_name => 'production_run_code'}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'inventory_code',
                                              :settings => {:list => inventory_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'season_code',
                                              :settings => {:list => season_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'target_market_code',
                                              :settings => {:list => target_market_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'organization_code',
                                              :settings => {:list => organization_codes}}


    field_configs[field_configs.length()] = {:field_type => 'HiddenField',
                                             :field_name => 'ajax_distributor',
                                             :non_db_field => true}

    build_form(@pallet, field_configs, "pallet_search_submit", 'pallet', 'search')

  end


  def build_pallet_bulk_edit_form(pallet, action, caption)

    on_complete_js = "\n img = document.getElementById('img_pallet_edit_organization_code');"
    on_complete_js += "\n if(img != null)img.style.display = 'none';"

    #Observers for search combos
    marketer_org_observer  = {:updated_field_id => "target_market_short_cell",
                              :remote_method => 'pallet_marketer_org_combo_changed',
                              :on_completed_js => on_complete_js}


    org_codes = Organization.get_all_by_role("MARKETER")
    #marks = Mark.get_all_for_org(carton.organization_code)
    target_market_codes = TargetMarket.get_all_by_org(pallet.organization_code)
    inventory_codes = InventoryCode.get_all_by_org(pallet.organization_code)
    product_codes = PalletFormatProduct.find(:all).map { |u| u.pallet_format_product_code }
    mark_codes = Mark.get_all_for_org(pallet.organization_code)
    grade_codes = Grade.find(:all).map { |g| g.grade_code }
    class_codes = ProductClass.find(:all).map { |c| c.product_class_code }
    inspect_type_codes = InspectionType.find_by_sql("select distinct inspection_type_code from inspection_types").map { |i| i.inspection_type_code }

    pallet.production_run_code = pallet.production_run.production_run_code

    pallet.decompose_fields


    field_configs = Array.new


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'pallet_number'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'remark'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'pt_product_characteristics'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'production_run_code'}

    if @bulk_pallet_update_permission
      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'organization_code',
                                               :settings => {:list => org_codes},
                                               :observer => marketer_org_observer}
    else
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'organization_code'}

    end

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'target_market_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'target_market_short',
                                             :settings => {:list => target_market_codes}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'inventory_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'inventory_code_short',
                                             :settings => {:list => inventory_codes}}
    if @bulk_pallet_update_permission
      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'pallet_format_product_code',
                                               :settings => {:list => product_codes}}

      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'carton_mark_code',
                                               :settings => {:list => mark_codes}}

    else

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'pallet_format_product_code'}

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'pallet_format_product_code'}

    end

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'farm_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'reworks_action'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'build_up_balance'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'build_status'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'carton_quantity_actual'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'production_run.production_run_code',
                                             :settings => {:label_caption => "production run code"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'fg_product_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'fg_code_old'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'target_market_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'oldest_pack_date_time'}


    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'inspect_type_code',
                                             :settings => {:list => inspect_type_codes}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'class_code',
                                             :settings => {:list => class_codes}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'grade_code',
                                             :settings => {:list => grade_codes}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'qc_status_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'date_time_completed'}


    build_form(pallet, field_configs, action, 'pallet_edit', caption)


  end

  def build_edit_carton_form(carton, action, caption, disallow_fg_edit = nil)

    if(carton && carton.shift_id)
      shift = Shift.find(carton.shift_id)
      if(shift.user)
        user = shift.user
      else
        user = " "
      end

      default_shift_code = "#{shift.shift_type_code}_#{shift.line_code}_#{user}_#{shift.start_date_time.strftime("%Y/%m/%d")}"
    end

    session[:carton_edit_form]= Hash.new
    is_pallet_update = action == 'edit_repr_carton_submit'

    #-----------------------------------------------------------------------------
    #Marketing org observer: dependent fields are: target market,carton_mark_code
    #                        and inventory_code
    #------------------------------------------------------------------------------
    on_complete_js = "\n img = document.getElementById('img_carton_edit_organization_code');"
    on_complete_js += "\n if(img != null)img.style.display = 'none';"

    #Observers for search combos
    marketer_org_observer  = {:updated_field_id => "target_market_short_cell",
                              :remote_method => 'marketer_org_combo_changed',
                              :on_completed_js => on_complete_js}

    marketer_org_observer  = {:updated_field_id => "target_market_short_cell",
                              :remote_method => 'marketer_org_combo_changed',
                              :on_completed_js => on_complete_js}


    on_complete_js_pick_ref = "\n img = document.getElementById('img_carton_edit_pick_reference');"
    on_complete_js_pick_ref += "\n if(img != null)img.style.display = 'none';"

    pick_ref_observer  = {:updated_field_id => "pack_date_time_cell",
                              :remote_method => 'pick_ref_changed',
                              :on_completed_js => on_complete_js_pick_ref}


    run_js = "\n img = document.getElementById('img_carton_edit_production_run_code');"
    run_js += "\n if(img != null)img.style.display = 'none';"


    ext_fg_js = "\n img = document.getElementById('img_carton_edit_extended_fg_code');"
    ext_fg_js += "\n if(img != null)img.style.display = 'none';"


    extended_fg_observer  = {:updated_field_id => "ajax_distributor_cell",
                             :remote_method => 'extended_fg_combo_changed',
                             :on_completed_js => ext_fg_js}


    run_observer  = {:updated_field_id => "ajax_distributor_cell",
                     :remote_method => 'run_combo_changed',
                     :on_completed_js => run_js}


    #--------------------------
    #Get lists for all combos:
    #--------------------------

    org_codes = Organization.get_all_by_role("MARKETER")
    #marks = Mark.get_all_for_org(carton.organization_code)
    target_market_codes = TargetMarket.get_all_by_org(carton.organization_code)
    target_market_codes.unshift("<empty>")
    inventory_codes = InventoryCode.get_all_by_org(carton.organization_code)
    inventory_codes.unshift("<empty>")
    #old_packs = OldPack.find_by_sql('select distinct old_pack_code from old_packs').map{|g|[g.old_pack_code]}
    tracking_indicators = TrackIndicator.find(:all).map { |t| t.track_indicator_code }


    rmt_variety = carton.production_run.production_schedule.rmt_setup.variety_code
    extended_fg_codes = ExtendedFg.get_all_by_commodity_and_rmt_variety(carton.commodity_code, rmt_variety).map { |g| [g.extended_fg_code] }


    inspection_types = InspectionType.find_all_by_grade_code_and_for_internal_hg_inspections_only(carton.grade_code,false).map { |g| [g.inspection_type_code] }
    #season_codes = Season.find_by_sql('select distinct season_code from seasons').map{|g|[g.season_code]}
    pc_codes = PcCode.find(:all).map { |p| ["PC" + p.pc_code + "_" + p.pc_name] if p }
    cold_store_codes = ColdStoreType.find(:all, :order => "cold_store_type_code").map { |g| [g.cold_store_type_code] }


    carton.decompose_fields
    #--------------------
    #marking and diameter
    #--------------------
    #ipc = FgProduct.find_by_fg_product_code(carton.fg_product_code).item_pack_product


    #carton.diameter = diameter if !carton.diameter
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'carton_number'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'pallet_number'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'production_run_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'farm_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'puc'}



    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'n_labels_printed'}

    #---------------
    #RUN EXC DETAILS
    #---------------
#	 group_menu = "collapse all <img src = '/images/collapse_groups.png' onclick = 'collapse_all();' </img>&nbsp;&nbsp;&nbsp;expand all<img src = '/images/expand_groups.png' onclick = 'expand_all();' </img>"
#    field_configs[field_configs.length()] = {:field_type => 'LabelField',
#						:field_name => 'group_menu', :settings =>
#						 {:static_value => group_menu,:is_separator => false,:css_class => 'blue_label_field'}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'run exec', :settings =>
                    {:static_value => 'production execution details', :is_separator => false}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'line_code'}


    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'shift_id',
                                             :non_db_field=>true,
                                             :settings => {:lookup=>true,:lookup_search_file=>"search_shifts",:select_column_name=>'id',
                                                           :submit_to=>'/production/reworks/shift_id_text_changed'}}

    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'shift', :non_db_field=>true, :settings=>{:static_value=>default_shift_code.to_s, :show_label=>true}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'carton_label_station_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'erp_station'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'erp_pack_point'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'carton_pack_station_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'packer_number'}
    #-------------
    #PRODUCT CODES
    #-------------
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'product codes', :settings =>
                    {:static_value => 'FG component codes', :is_separator => false}}


    if !disallow_fg_edit


      #if  !@is_reclassification


      field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                                :field_name => 'extended_fg_code',
                                                :settings => {:list => extended_fg_codes},
                                                :observer => extended_fg_observer}

      #end
    end

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'extended_fg_code',
                                             :settings => {:css_class => "old_value", :label_caption => "current extended fg"}}

    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                              :field_name => 'item_pack_product_code',
                                              :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'carton_fruit_nett_mass',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                              :field_name => 'unit_pack_product_code',
                                              :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                              :field_name => 'carton_pack_product_code',
                                              :settings => {:css_class => "derived_field"}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'fg_product_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'fg_code_old',
                                             :settings => {:css_class => "derived_field"}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'units_per_carton',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'items_per_unit'}


    #---------------------
    #FRUIT RELATED FIELDS
    #---------------------
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'ipc fields', :settings =>
                    {:static_value => 'IPC(fruit) related fields', :is_separator => false}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'commodity_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'variety_short_long',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'actual_size_count_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'grade_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'product_class_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'erp_cultivar',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'treatment_code',
                                             :settings => {:css_class => "derived_field"}}


    #----------------
    #MARKETING FIELDS
    #----------------
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'marketing fields', :settings =>
                    {:static_value => 'Marketing related fields', :is_separator => false}}

#	 field_configs[field_configs.length()] = {:field_type => 'DropDownField',
#						:field_name => 'organization_code',
#						:settings => {:list => org_codes},
#						:observer => marketer_org_observer}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'organization_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'target_market_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'target_market_short',
                                             :settings => {:list => target_market_codes}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'fg_mark_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'carton_mark_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'inventory_code',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'inventory_code_short',
                                             :settings => {:list => inventory_codes}}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'sell_by_code'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'order_number'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'quantity'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'account_code'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'marking'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'diameter'}
    #----------------------
    #QUALITY RELATED FIELDS
    #----------------------
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'QA fields', :settings =>
                    {:static_value => 'quality related fields', :is_separator => false}}

#	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
#						:field_name => 'season_code',
#						:settings => {:list => season_codes}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'season_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'iso_week_code'}


    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'quarantine'}


    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'inspection_type_code',
                                             :settings => {:list => inspection_types}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'qc_status_code'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'chemical_status_code'}

    if !is_pallet_update
      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'pc_code',
                                               :settings => {:list => pc_codes}}
    else

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'pc_code'}
    end

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'cold_store_code',
                                             :settings => {:list => cold_store_codes}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'spray_program_code'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'pi'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'pick_reference',
                                             :settings => {:css_class => "derived_field"},:observer => pick_ref_observer}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'pack_date_time',
                                             :settings => {:css_class => "derived_field"}}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'egap'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'is_inspection_carton'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'qc_datetime_out'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'qc_datetime_in'}


    #----------------------
    #MISC FIELDS
    #----------------------
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'misc fields', :settings =>
                    {:static_value => 'miscellaneous fields', :is_separator => false}}

    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                              :field_name => 'old_pack_code'}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'track_indicator_code',
                                              :settings => {:list => tracking_indicators}}


    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'remarks'}


    field_configs[field_configs.length()] = {:field_type => 'HiddenField',
                                             :field_name => 'ajax_distributor',
                                             :non_db_field => true}

    build_form(carton, field_configs, action, 'carton_edit', caption)

  end

  #==========================
#   Luks' code    =========
#==========================
  def build_bins_tipped_search_form(bin_tipped, action, caption, is_flat_search = nil, is_multi_select = nil)
    #@bin_tipped = BinsTipped.new
    #@bin_tipped.tipped_in_reworks = nil
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:bins_tipped_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["bin_tipped_production_schedule_name", "bin_tipped_production_run_code", "bin_tipped_line_code", "bin_tipped_farm_code", "bin_tipped_track_indicator_code"])
    #Observers for search combos
    production_schedule_name_observer  = {:updated_field_id => "production_run_code_cell",
                                          :remote_method => 'bins_tipped_production_schedule_name_search_combo_changed',
                                          :on_completed_js => search_combos_js["bin_tipped_production_schedule_name"]}

    session[:bins_tipped_search_form][:production_schedule_name_observer] = production_schedule_name_observer


    production_run_code_observer  = {:updated_field_id => "line_code_cell",
                                     :remote_method => 'bins_tipped_production_run_code_search_combo_changed',
                                     :on_completed_js => search_combos_js["bin_tipped_production_run_code"]}

    session[:bins_tipped_search_form][:production_run_code_observer] = production_run_code_observer

    line_code_observer  = {:updated_field_id => "farm_code_cell",
                           :remote_method => 'bins_tipped_line_code_search_combo_changed',
                           :on_completed_js => search_combos_js["bin_tipped_line_code"]}

    session[:bins_tipped_search_form][:line_code_observer] = line_code_observer

    production_schedule_names = BinsTipped.find_by_sql('select production_schedule_name from production_schedules').map { |g| [g.production_schedule_name] }
    production_schedule_names.unshift("<empty>")


    #weights = BinsTipped.find_by_sql('select distinct weight from bins_tipped ').map{|e|[e.weight]}
    #weights.unshift("<empty>")

    delivery_numbers = BinsTipped.find_by_sql('select distinct delivery_no from bins_tipped where delivery_no is not null').map { |d| [d.delivery_no] }
    delivery_numbers.unshift("<empty>")

    class_descriptions = BinsTipped.find_by_sql('select distinct class_description from bins_tipped where class_description is not null').map { |d| [d.class_description] }
    class_descriptions.unshift("<empty>")

    production_run_codes = ["Select a value from production_schedule_name"]
    line_codes = ["Select a value from production_run_code"]
    farm_codes = ["Select a value from line_code"]


    @bin_tipped = BinsTipped.new
    #@bin_tipped.production_schedule_name = "<empty>"
    #@bin_tipped.production_run_code = "<empty>"
    #@bin_tipped.line_code = "<empty>"
    #@bin_tipped.farm_code = "<empty>"
    #@bin_tipped.track_indicator_code = "<empty>"
    #@bin_tipped.bin_id = "<empty>"
    #@bin_tipped.delivery_no = "<empty>"
    #@bin_tipped.class_description = "<empty>"

#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table
#	----------------------------------------------------------------------------------------------
    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'production_schedule_name',
                                            :settings => {:list => production_schedule_names},
                                            :observer => production_schedule_name_observer}

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'production_run_code',
                                            :settings => {:list => production_run_codes},
                                            :observer => production_run_code_observer}

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'line_code',
                                            :settings => {:list => line_codes},
                                            :observer => line_code_observer}

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'farm_code',
                                            :settings => {:list => farm_codes}}

    field_configs[field_configs.length] =  {:field_type => 'LabelField',
                                            :field_name => 'track_indicator_code'}

    field_configs[field_configs.length] =  {:field_type => 'TextField',
                                            :field_name => 'bin_id'} #,
#						:settings => {:list => bin_ids}}


    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'delivery_no',
                                            :settings => {:list => delivery_numbers}}

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'class_description',
                                            :settings => {:list => class_descriptions}}

    field_configs[field_configs.length] =  {:field_type => 'CheckBox',
                                            :field_name => 'tipped_in_reworks'}

    field_configs[field_configs.length] = {:field_type => "PopupDateSelector", :field_name => "tipped_date_time",
                                           :settings => {:date_textfield_id=>'tipped_date_time_date2from', :label_caption => "tipped_date_time:from"}}

    field_configs[field_configs.length] = {:field_type => "PopupDateSelector", :field_name => "tipped_date_time",
                                           :settings => {:date_textfield_id=>'tipped_date_time_date2to', :label_caption => "tipped_date_time:to"}}

    field_configs[field_configs.length] = {:field_type => "PopupDateSelector", :field_name => "bin_receive_datetime",
                                           :settings => {:date_textfield_id=>'bin_receive_datetime_date2from', :label_caption => "received_date_time:from"}}

    field_configs[field_configs.length] = {:field_type => "PopupDateSelector", :field_name => "bin_receive_datetime",
                                           :settings => {:date_textfield_id=>'bin_receive_datetime_date2to', :label_caption => "received_date_time:to"}}

    build_form(bin_tipped, field_configs, action, 'bin_tipped', caption, false, nil, nil, true)

  end


  def build_bins_tipped_grid(data_set, can_edit, can_delete, is_multi_select = nil)

    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_id'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_schedule_name'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'line_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'tipped_date_time'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'weight'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'class_description'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'delivery_no'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'track_indicator_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_receive_datetime'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'tipped_in_reworks'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}
#	----------------------
#	define action columns
#	----------------------
#	if can_edit
#		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit bins_tipped',
#			:settings =>
#				 {:link_text => 'edit',
#				:target_action => 'edit_bins_tipped',
#				:id_column => 'id'}}
#	end
#
#	if can_delete
#		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete bins_tipped',
#			:settings =>
#				 {:link_text => 'delete',
#				:target_action => 'delete_bins_tipped',
#				:id_column => 'id'}}
#	end

    @multi_select = "selected_tipped_bins" if is_multi_select
    return get_data_grid(data_set, column_configs)
  end

  def build_rw_tipped_bins_grid(data_set)

    column_configs = Array.new
    #require File.dirname(__FILE__) + "/../../../app/helpers/production/reworks_received_items_plugin.rb"

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_id'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_schedule_name'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'line_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rw_reworks_action'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'tipped_date_time'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'weight'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'class_description'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'delivery_no'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'track_indicator_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_receive_datetime'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'tipped_in_reworks'}


    if @bulk_tipped_bin_update_permission
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'bulk update',
                                                 :settings =>
                                                         {:image => 'bulk_update',
                                                          :target_action => 'bulk_tipped_bin_update',
                                                          :id_column => 'id'}}
    end

    return get_data_grid(data_set, column_configs, MesScada::GridPlugins::Production::ReworksReceivedTippedBinsGridPlugin.new)

  end

  def build_bulk_update_tipped_bin_form(tipped_bin_edit, action, caption)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:tipped_bin_edit_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["tipped_bin_edit_production_schedule_name", "tipped_bin_edit_production_run_code", "tipped_bin_edit_line_code"])
    #Observers for search combos
    production_schedule_name_observer  = {:updated_field_id => "production_run_code_cell",
                                          :remote_method => 'tipped_bin_edit_production_schedule_name_search_combo_changed',
                                          :on_completed_js => search_combos_js["tipped_bin_edit_production_schedule_name"]}

    session[:tipped_bin_edit_form][:production_schedule_name_observer] = production_schedule_name_observer

    production_run_code_observer  = {:updated_field_id => "line_code_cell",
                                     :remote_method => 'tipped_bin_edit_production_run_code_search_combo_changed',
                                     :on_completed_js => search_combos_js["tipped_bin_edit_production_run_code"]}

    session[:tipped_bin_edit_form][:production_run_code_observer] = production_run_code_observer

    production_schedule_names = BinsTipped.find_by_sql('select distinct production_schedule_name from bins_tipped ').map { |g| [g.production_schedule_name] } #where production_schedule_name is not null

    #production_run_codes = BinsTipped.find_by_sql('select distinct production_run_code from bins_tipped ').map{|g|[g.production_run_code]}
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
    field_configs[field_configs.length] = {:field_type => 'DropDownField',
                                           :field_name => 'production_schedule_name',
                                           :settings => {:list => production_schedule_names},
                                           :observer => production_schedule_name_observer}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'production_run_code',
                                           :observer => production_run_code_observer}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'line_code'}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'tipped_date_time'}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'weight'}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'class_description'}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'farm_code'}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'delivery_no'}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'track_indicator_code'}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'bin_receive_datetime'}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'tipped_in_reworks'}


    build_form(tipped_bin_edit, field_configs, action, 'tipped_bin_edit', caption)

  end

#==========================

  def build_search_pallet_histories_form(hash_object,action,caption)
  #	--------------------------------------------------------------------------------------------------
  #	Define an observer for each index field
  #	--------------------------------------------------------------------------------------------------

  #	----------------------------------------
  #	 Define search fields to build form from
  #	----------------------------------------
      field_configs = Array.new
  #	----------------------------------------------------------------------------------------------
  #	Define search Combo fields to represent the unique index on this table
  #	----------------------------------------------------------------------------------------------
    field_configs[field_configs.length] =  {:field_type => 'TextField',
                                            :field_name => 'pallet_number'}
    #field_configs[field_configs.length] =  {:field_type => 'TextField',
    #                                        :field_name => 'user_name'}
    #field_configs[field_configs.length] =  {:field_type => 'TextField',
    #                                        :field_name => 'season'}
    #field_configs << {:field_type=>'PopupDateRangeSelector', :field_name=>'rw_run_end_datetime'}

    build_form(hash_object, field_configs, action, 'hash_object', caption, nil, nil, nil, true)
  end

  def build_search_carton_histories_form(hash_object,action,caption)
  #	--------------------------------------------------------------------------------------------------
  #	Define an observer for each index field
  #	--------------------------------------------------------------------------------------------------

  #	----------------------------------------
  #	 Define search fields to build form from
  #	----------------------------------------
      field_configs = Array.new
  #	----------------------------------------------------------------------------------------------
  #	Define search Combo fields to represent the unique index on this table
  #	----------------------------------------------------------------------------------------------
    field_configs[field_configs.length] =  {:field_type => 'TextField',
                                            :field_name => 'pallet_number'}
    field_configs[field_configs.length] =  {:field_type => 'TextField',
                                            :field_name => 'carton_number'}
    #field_configs[field_configs.length] =  {:field_type => 'TextField',
    #                                        :field_name => 'user_name'}
    #field_configs[field_configs.length] =  {:field_type => 'TextField',
    #                                        :field_name => 'season'}
    #field_configs << {:field_type=>'PopupDateRangeSelector', :field_name=>'rw_run_end_datetime'}

    build_form(hash_object, field_configs, action, 'hash_object', caption, false, nil, nil, true)
  end

  def build_search_bin_histories_form(hash_object,action,caption)
  #	--------------------------------------------------------------------------------------------------
  #	Define an observer for each index field
  #	--------------------------------------------------------------------------------------------------

  #	----------------------------------------
  #	 Define search fields to build form from
  #	----------------------------------------
      field_configs = Array.new
  #	----------------------------------------------------------------------------------------------
  #	Define search Combo fields to represent the unique index on this table
  #	----------------------------------------------------------------------------------------------
    field_configs[field_configs.length] =  {:field_type => 'TextField',
                                            :field_name => 'bin_number'}
    #field_configs[field_configs.length] =  {:field_type => 'TextField',
    #                                        :field_name => 'user_name'}
    #field_configs[field_configs.length] =  {:field_type => 'TextField',
    #                                        :field_name => 'season'}
    #field_configs << {:field_type=>'PopupDateRangeSelector', :field_name=>'rw_run_end_datetime'}

    build_form(hash_object, field_configs, action, 'hash_object', caption, false, nil, nil, true)
  end

  def build_pallet_histories_grid(data_set)
    #require File.dirname(__FILE__) + "/../../../app/helpers/production/reworks_received_items_plugin.rb"
    column_configs = []

    column_configs << {:field_type => 'link_window',:field_name => 'diff',
                                      :settings =>
                                      {:link_text =>'',
                                       :target_action => 'view_pallet_history_diff',
                                       :id_column => "record_id",
                                       :window_width=>1100,
                                       :window_height=>800}}

    column_configs << {:field_type => 'link_window',:field_name => 'diff_to_pallet',:column_width=>80,
                                      :settings =>
                                      {:link_text =>'',
                                       :target_action => 'view_pallet_history_diff_to_pallet',
                                       :id_column => "record_id",
                                       :window_width=>1100,
                                       :window_height=>800}}

    column_configs << {:field_type => 'text', :field_name => 'tablename',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'pallet_number',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'account_code'}
    column_configs << {:field_type => 'text', :field_name => 'actual_size_count_code',:column_width=>160}
    column_configs << {:field_type => 'text', :field_name => 'affected_by_env',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'affected_by_function',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'affected_by_program',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'build_status'}
    column_configs << {:field_type => 'text', :field_name => 'carton_mark_code',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'carton_quantity_actual',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'carton_setup_id',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'class_code'}
    column_configs << {:field_type => 'text', :field_name => 'cold_store_code',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'commodity_code',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'consignment_note_number',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'country_origin_code',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'cpp'}
    column_configs << {:field_type => 'text', :field_name => 'created_at'}
    column_configs << {:field_type => 'text', :field_name => 'created_by'}
    column_configs << {:field_type => 'text', :field_name => 'date_time_completed',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'date_time_created',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'erp_cultivar'}
    column_configs << {:field_type => 'text', :field_name => 'exit_ref'}
    column_configs << {:field_type => 'text', :field_name => 'farm_code'}
    column_configs << {:field_type => 'text', :field_name => 'fg_code_old'}
    column_configs << {:field_type => 'text', :field_name => 'fg_product_code'}
    column_configs << {:field_type => 'text', :field_name => 'grade_code'}
    column_configs << {:field_type => 'text', :field_name => 'holdover'}
    column_configs << {:field_type => 'text', :field_name => 'holdover_quantity',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'id'}
    column_configs << {:field_type => 'text', :field_name => 'inspect_type_code',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'intake_header_id'}
    column_configs << {:field_type => 'text', :field_name => 'intake_headers_production_id',:column_width=>160}
    column_configs << {:field_type => 'text', :field_name => 'inventory_code'}
    column_configs << {:field_type => 'text', :field_name => 'is_depot_pallet'}
    column_configs << {:field_type => 'text', :field_name => 'is_mapped'}
    column_configs << {:field_type => 'text', :field_name => 'is_new_pallet'}
    column_configs << {:field_type => 'text', :field_name => 'iso_week_code'}
    column_configs << {:field_type => 'text', :field_name => 'load_detail_id'}
    column_configs << {:field_type => 'text', :field_name => 'marketing_variety_code',:column_width=>160}
    column_configs << {:field_type => 'text', :field_name => 'n_labels_printed',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'oldest_pack_date_time'}
    column_configs << {:field_type => 'text', :field_name => 'old_pack_code'}
    column_configs << {:field_type => 'text', :field_name => 'order_number'}
    column_configs << {:field_type => 'text', :field_name => 'organization_code',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'pallet_format_product_code',:column_width=>180}
    column_configs << {:field_type => 'text', :field_name => 'pallet_format_product_id',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'pallet_id'}
    column_configs << {:field_type => 'text', :field_name => 'pallet_label_code',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'pallet_reno_ref'}
    column_configs << {:field_type => 'text', :field_name => 'pallet_template_id',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'pallet_type_code',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'party_name'}
    column_configs << {:field_type => 'text', :field_name => 'pc_code'}
    column_configs << {:field_type => 'text', :field_name => 'pick_reference_code',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'ppecb_inspection_id'}
    column_configs << {:field_type => 'text', :field_name => 'process_status'}
    column_configs << {:field_type => 'text', :field_name => 'production_run_id',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'pt_product_characteristics'}
    column_configs << {:field_type => 'text', :field_name => 'qc_result_status',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'qc_status_code',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'remark'}
    column_configs << {:field_type => 'text', :field_name => 'reprint_acknowledged_by',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'reprint_acknowledged_date_time',:column_width=>180}
    column_configs << {:field_type => 'text', :field_name => 'rw_create_datetime',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'rw_receipt_datetime',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'rw_receipt_intake_headers_production_id',:column_width=>180}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_id'}
    column_configs << {:field_type => 'text', :field_name => 'season_code'}
    column_configs << {:field_type => 'text', :field_name => 'size_count_code'}
    column_configs << {:field_type => 'text', :field_name => 'store_type_code'}
    column_configs << {:field_type => 'text', :field_name => 'target_market_code',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'updated_at'}
    column_configs << {:field_type => 'text', :field_name => 'updated_by'}
    column_configs << {:field_type => 'text', :field_name => 'zero_printed_carton_labels',:column_width=>180}
    column_configs << {:field_type => 'text', :field_name => 'reworks_action'}
    column_configs << {:field_type => 'text', :field_name => 'person'}
    column_configs << {:field_type => 'text', :field_name => 'rw_reason_id'}
    column_configs << {:field_type => 'text', :field_name => 'rw_scrap_datetime',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'user_name'}
    column_configs << {:field_type => 'text', :field_name => 'id'}


    return get_data_grid(data_set, column_configs, MesScada::GridPlugins::Production::ReworksPalletHistoriesGridPlugin.new(self,request), true)
  end

  def build_carton_histories_grid(data_set)
    #require File.dirname(__FILE__) + "/../../../app/helpers/production/reworks_received_items_plugin.rb"
    column_configs = []

    column_configs << {:field_type => 'link_window',:field_name => 'diff',
                                  :settings =>
                                  {:link_text =>'',
                                   :target_action => 'view_carton_history_diff',
                                   :id_column => "record_id",
                                   :window_width=>1100,
                                   :window_height=>800}}

    column_configs << {:field_type => 'link_window',:field_name => 'diff_to_carton',:column_width=>80,
                                      :settings =>
                                      {:link_text =>'',
                                       :target_action => 'view_pallet_history_diff_to_carton',
                                       :id_column => "record_id",
                                       :window_width=>1100,
                                       :window_height=>800}}


    column_configs << {:field_type => 'text', :field_name => 'tablename',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'pallet_number',:column_width=>180}
    column_configs << {:field_type => 'text', :field_name => 'carton_number',:column_width=>180}
    column_configs << {:field_type => 'text', :field_name => 'rw_reclassed_intake_headers_production_id',:column_width=>250}
    column_configs << {:field_type => 'text', :field_name => 'rw_create_datetime',:column_width=>120}
    column_configs << {:field_type => 'text', :field_name => 'intake_header_id',:column_width=>120}
    column_configs << {:field_type => 'text', :field_name => 'created_at'}
    column_configs << {:field_type => 'text', :field_name => 'exit_date_time'}
    column_configs << {:field_type => 'text', :field_name => 'is_inspection_carton',:column_width=>120}
    column_configs << {:field_type => 'text', :field_name => 'carton_fruit_nett_mass',:column_width=>160}
    column_configs << {:field_type => 'text', :field_name => 'n_labels_printed',:column_width=>130}
    column_configs << {:field_type => 'text', :field_name => 'production_run_code',:column_width=>180}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_name'}
    column_configs << {:field_type => 'text', :field_name => 'line_code'}
    column_configs << {:field_type => 'text', :field_name => 'carton_mark_code',:column_width=>130}
    column_configs << {:field_type => 'text', :field_name => 'quantity'}
    column_configs << {:field_type => 'text', :field_name => 'carton_pack_station_code',:column_width=>220}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_end_datetime',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'affected_by_function',:column_width=>140}
    column_configs << {:field_type => 'text', :field_name => 'account_code'}
    column_configs << {:field_type => 'text', :field_name => 'updated_by'}
    column_configs << {:field_type => 'text', :field_name => 'reprint_acknowledged_by'}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_type_code'}
    column_configs << {:field_type => 'text', :field_name => 'busy'}
    column_configs << {:field_type => 'text', :field_name => 'exit_reference'}
    column_configs << {:field_type => 'text', :field_name => 'organization_code'}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_id'}
    column_configs << {:field_type => 'text', :field_name => 'rw_receipt_datetime'}
    column_configs << {:field_type => 'text', :field_name => 'run_track_indicator_code'}
    column_configs << {:field_type => 'text', :field_name => 'reprint_acknowledged_date_time'}
    column_configs << {:field_type => 'text', :field_name => 'qc_result_status'}
    column_configs << {:field_type => 'text', :field_name => 'cold_store_code'}
    column_configs << {:field_type => 'text', :field_name => 'pallet_sequence_number'}
    column_configs << {:field_type => 'text', :field_name => 'product_class_code'}
    column_configs << {:field_type => 'text', :field_name => 'username'}
    column_configs << {:field_type => 'text', :field_name => 'user_name'}
    column_configs << {:field_type => 'text', :field_name => 'rw_scrap_datetime'}
    column_configs << {:field_type => 'text', :field_name => 'shift_code'}
    column_configs << {:field_type => 'text', :field_name => 'egap'}
    column_configs << {:field_type => 'text', :field_name => 'erp_pack_point'}
    column_configs << {:field_type => 'text', :field_name => 'pick_reference'}
    column_configs << {:field_type => 'text', :field_name => 'erp_station'}
    column_configs << {:field_type => 'text', :field_name => 'commodity_code'}
    column_configs << {:field_type => 'text', :field_name => 'date_time_created'}
    column_configs << {:field_type => 'text', :field_name => 'treatment_type_code'}
    column_configs << {:field_type => 'text', :field_name => 'target_market_code'}
    column_configs << {:field_type => 'text', :field_name => 'spray_program_code'}
    column_configs << {:field_type => 'text', :field_name => 'rw_receipt_unit'}
    column_configs << {:field_type => 'text', :field_name => 'reworks_action'}
    column_configs << {:field_type => 'text', :field_name => 'intake_header_number'}
    column_configs << {:field_type => 'text', :field_name => 'carton_template_id'}
    column_configs << {:field_type => 'text', :field_name => 'treatment_code'}
    column_configs << {:field_type => 'text', :field_name => 'rw_receipt_pallet_id'}
    column_configs << {:field_type => 'text', :field_name => 'rw_receipt_intake_headers_production_id'}
    column_configs << {:field_type => 'text', :field_name => 'erp_cultivar'}
    column_configs << {:field_type => 'text', :field_name => 'inspection_type_code'}
    column_configs << {:field_type => 'text', :field_name => 'pc_code'}
    column_configs << {:field_type => 'text', :field_name => 'updated_at'}
    column_configs << {:field_type => 'text', :field_name => 'units_per_carton'}
    column_configs << {:field_type => 'text', :field_name => 'fg_code_old'}
    column_configs << {:field_type => 'text', :field_name => 'gtin'}
    column_configs << {:field_type => 'text', :field_name => 'qc_datetime_out'}
    column_configs << {:field_type => 'text', :field_name => 'old_pack_code'}
    column_configs << {:field_type => 'text', :field_name => 'inventory_code'}
    column_configs << {:field_type => 'text', :field_name => 'grade_code'}
    column_configs << {:field_type => 'text', :field_name => 'track_indicator_code'}
    column_configs << {:field_type => 'text', :field_name => 'pack_date_time'}
    column_configs << {:field_type => 'text', :field_name => 'puc'}
    column_configs << {:field_type => 'text', :field_name => 'carton_printing_ip'}
    column_configs << {:field_type => 'text', :field_name => 'order_number'}
    column_configs << {:field_type => 'text', :field_name => 'packer_number'}
    column_configs << {:field_type => 'text', :field_name => 'unit_pack_product_code'}
    column_configs << {:field_type => 'text', :field_name => 'items_per_unit'}
    column_configs << {:field_type => 'text', :field_name => 'affected_by_env'}
    column_configs << {:field_type => 'text', :field_name => 'carton_label_station_code'}
    column_configs << {:field_type => 'text', :field_name => 'production_run_id'}
    column_configs << {:field_type => 'text', :field_name => 'carton_fruit_nett_mass_actual'}
    column_configs << {:field_type => 'text', :field_name => 'mapped_pallet_sequence_id'}
    column_configs << {:field_type => 'text', :field_name => 'created_by'}
    column_configs << {:field_type => 'text', :field_name => 'farm_code'}
    column_configs << {:field_type => 'text', :field_name => 'variety_short_long'}
    column_configs << {:field_type => 'text', :field_name => 'season_code'}
    column_configs << {:field_type => 'text', :field_name => 'qc_status_code'}
    column_configs << {:field_type => 'text', :field_name => 'qc_datetime_in'}
    column_configs << {:field_type => 'text', :field_name => 'tablename'}
    column_configs << {:field_type => 'text', :field_name => 'carton_id'}
    column_configs << {:field_type => 'text', :field_name => 'extended_fg_code'}
    column_configs << {:field_type => 'text', :field_name => 'carton_label_code'}
    column_configs << {:field_type => 'text', :field_name => 'is_depot_carton'}
    column_configs << {:field_type => 'text', :field_name => 'remarks'}
    column_configs << {:field_type => 'text', :field_name => 'ppecb_inspection_id'}
    column_configs << {:field_type => 'text', :field_name => 'shift_id'}
    column_configs << {:field_type => 'text', :field_name => 'fg_mark_code'}
    column_configs << {:field_type => 'text', :field_name => 'person'}
    column_configs << {:field_type => 'text', :field_name => 'rw_reclassed_datetime'}
    column_configs << {:field_type => 'text', :field_name => 'sell_by_code'}
    column_configs << {:field_type => 'text', :field_name => 'affected_by_program'}
    column_configs << {:field_type => 'text', :field_name => 'fg_product_code'}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_status_code'}
    column_configs << {:field_type => 'text', :field_name => 'rw_reason_id'}
    column_configs << {:field_type => 'text', :field_name => 'iso_week_code'}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_start_datetime'}
    column_configs << {:field_type => 'text', :field_name => 'actual_size_count_code'}
    column_configs << {:field_type => 'text', :field_name => 'id'}


    return get_data_grid(data_set, column_configs, MesScada::GridPlugins::Production::ReworksPalletHistoriesGridPlugin.new(self,request), true)
  end

  def build_bin_histories_grid(data_set)
                                           #957568
    column_configs = []

    column_configs << {:field_type => 'text', :field_name => 'tablename'}
    column_configs << {:field_type => 'text', :field_name => 'bin_number'}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_id'}
    column_configs << {:field_type => 'text', :field_name => 'rebin_status'}
    column_configs << {:field_type => 'text', :field_name => 'pack_material_product_id'}
    column_configs << {:field_type => 'text', :field_name => 'exit_reference_date_time'}
    column_configs << {:field_type => 'text', :field_name => 'created_at'}
    column_configs << {:field_type => 'text', :field_name => 'remarks'}
    column_configs << {:field_type => 'text', :field_name => 'track_indicator5_id'}
    column_configs << {:field_type => 'text', :field_name => 'track_indicator3_id'}
    column_configs << {:field_type => 'text', :field_name => 'production_run_rebin_id'}
    column_configs << {:field_type => 'text', :field_name => 'created_on'}
    column_configs << {:field_type => 'text', :field_name => 'updated_at'}
    column_configs << {:field_type => 'text', :field_name => 'track_indicator4_id'}
    column_configs << {:field_type => 'text', :field_name => 'track_indicator2_id'}
    column_configs << {:field_type => 'text', :field_name => 'bin_receive_date_time'}
    column_configs << {:field_type => 'text', :field_name => 'affected_by_function'}
    column_configs << {:field_type => 'text', :field_name => 'busy'}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_status_code'}
    column_configs << {:field_type => 'text', :field_name => 'weight'}
    column_configs << {:field_type => 'text', :field_name => 'shift_id'}
    column_configs << {:field_type => 'text', :field_name => 'binfill_station_code'}
    column_configs << {:field_type => 'text', :field_name => 'username'}
    column_configs << {:field_type => 'text', :field_name => 'rebin_label_station_code'}
    column_configs << {:field_type => 'text', :field_name => 'orchard_code'}
    column_configs << {:field_type => 'text', :field_name => 'created_by'}
    column_configs << {:field_type => 'text', :field_name => 'id'}
    column_configs << {:field_type => 'text', :field_name => 'reworks_action'}
    column_configs << {:field_type => 'text', :field_name => 'rebin_track_indicator_code'}
    column_configs << {:field_type => 'text', :field_name => 'pack_material_product_code'}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_type_code'}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_end_datetime'}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_start_datetime'}
    column_configs << {:field_type => 'text', :field_name => 'user_name'}
    column_configs << {:field_type => 'text', :field_name => 'updated_by'}
    column_configs << {:field_type => 'text', :field_name => 'is_sample_bin'}
    column_configs << {:field_type => 'text', :field_name => 'is_half_bin'}
    column_configs << {:field_type => 'text', :field_name => 'exit_ref'}
    column_configs << {:field_type => 'text', :field_name => 'bin_order_load_detail_id'}
    column_configs << {:field_type => 'text', :field_name => 'affected_by_program'}
    column_configs << {:field_type => 'text', :field_name => 'affected_by_env'}
    column_configs << {:field_type => 'text', :field_name => 'rw_run_name'}
    column_configs << {:field_type => 'text', :field_name => 'track_indicator1_id'}
    column_configs << {:field_type => 'text', :field_name => 'rw_reason_id'}
    column_configs << {:field_type => 'text', :field_name => 'rmt_product_id'}
    column_configs << {:field_type => 'text', :field_name => 'farm_id'}
    column_configs << {:field_type => 'text', :field_name => 'season_code'}
    column_configs << {:field_type => 'text', :field_name => 'sealed_ca_location_id'}
    column_configs << {:field_type => 'text', :field_name => 'print_number'}
    column_configs << {:field_type => 'text', :field_name => 'tipped_date_time'}
    column_configs << {:field_type => 'text', :field_name => 'rebin_date_time'}
    column_configs << {:field_type => 'text', :field_name => 'production_run_tipped_id'}
    column_configs << {:field_type => 'text', :field_name => 'delivery_id'}
    column_configs << {:field_type => 'text', :field_name => 'bin_id'}
    column_configs << {:field_type => 'text', :field_name => 'carton_printing_ip'}

    return get_data_grid(data_set, column_configs, nil, true)
  end

  def build_search_build_ups_histories_form(hash_object,action,caption)
  #	--------------------------------------------------------------------------------------------------
  #	Define an observer for each index field
  #	--------------------------------------------------------------------------------------------------

  #	----------------------------------------
  #	 Define search fields to build form from
  #	----------------------------------------
    field_configs = Array.new
  #	----------------------------------------------------------------------------------------------
  #	Define search Combo fields to represent the unique index on this table
  #	----------------------------------------------------------------------------------------------
    field_configs << {:field_type=>'PopupDateRangeSelector', :field_name=>'buildup_timestamp',
                      :settings=>{:label_caption=>'date'}}
    field_configs << {:field_type => 'TextField',:field_name => 'to_pallet'}
    field_configs << {:field_type => 'TextField',:field_name => 'carton'}
    field_configs << {:field_type => 'TextField',:field_name => 'from_pallet'}
    field_configs << {:field_type => 'TextField',:field_name => 'user'}

    build_form(hash_object, field_configs, action, 'hash_object', caption, false, nil, nil, true)
  end

  def build_build_up_histories_grid(data_set)

    column_configs = Array.new
    column_configs << {:field_type => 'text', :field_name => 'buildup_timestamp', :col_width => 158}
    column_configs << {:field_type => 'text', :field_name => 'carton_quantity'}
    column_configs << {:field_type => 'text', :field_name => 'from_pallet_numbers', :col_width => 158}
    column_configs << {:field_type => 'text', :field_name => 'to_pallet_number', :col_width => 158}
    column_configs << {:field_type => 'text', :field_name => 'updated_by'}

    column_configs << {:field_type => 'link_window',:field_name => 'cartons',
                                      :settings =>
                                      {:link_text =>'view_details',
                                       :target_action => 'view_build_ups_cartons',
                                       :id_column => "id",
                                       :window_width=>1100,
                                       :window_height=>800}}

    return get_data_grid(data_set, column_configs, nil, true)

  end

  def build_build_up_cartons_grid(data_set)

    column_configs = Array.new
    column_configs << {:field_type => 'text', :field_name => 'carton_number', :col_width => 158}
    column_configs << {:field_type => 'text', :field_name => 'from_pallet_number', :col_width => 158}
    #column_configs << {:field_type => 'text', :field_name => 'to_pallet_number', :col_width => 158}

    return get_data_grid(data_set, column_configs, nil, true)

  end
end
