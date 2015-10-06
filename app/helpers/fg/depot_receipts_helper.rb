module Fg::DepotReceiptsHelper


    def build_depot_pallets_grid(data_set,can_edit,can_delete)

    column_configs = Array.new

     column_configs << {:field_type => 'action',:field_name => 'remove_pallet',
			:settings =>
				 {:link_text => '',
				:target_action => '',
				:id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_quantity'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pallet_format_product_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pallet_base_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'depot_pallet_number'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pallet_sequence_number'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}

      @multi_select = "selected_pallets"


    set_grid_min_width(1200)
    return get_data_grid(data_set,column_configs)

  end

  def build_intake_header_form(intake_header, action, caption, is_edit=nil, is_create_retry=nil)
    field_configs                                           = Array.new

    session[:intake_header_form]                            = Hash.new

    on_complete_js                                          = "\n img = document.getElementById('img_intake_header_recool_required');"
    on_complete_js                                          += "\n if(img != null) img.style.display = 'none';"

    recool_required_observer                                = {:updated_field_id=>'ajax_distributor_cell',
                                                               :remote_method   =>'intake_header_recool_required_checked',
                                                               :on_completed_js =>on_complete_js}

    session[:intake_header_form][:recool_required_observer] = recool_required_observer

    season_codes = Season.find_by_sql("SELECT DISTINCT season FROM seasons").map { |g| "#{g.season}" }
    season_codes.unshift("<empty>")

    intake_type_codes                                       = IntakeType.find_by_sql("SELECT DISTINCT intake_type_code FROM intake_types").map { |g| [g.intake_type_code] }
    intake_type_codes.unshift("<empty>")

    depot_codes = Depot.find_by_sql("SELECT DISTINCT depot_code FROM depots").map { |g| [g.depot_code] }
    depot_codes.unshift("<empty>")

    puc_codes = Puc.find_by_sql("SELECT DISTINCT puc_code FROM pucs").map { |g| [g.puc_code] }
    puc_codes.unshift("<empty>")

    account_codes = Account.find_by_sql("SELECT DISTINCT account_code FROM accounts").map { |g| [g.account_code] }
    account_codes.unshift("<empty>")

    supplier_codes = PartiesRole.find_by_sql("SELECT DISTINCT party_name FROM parties_roles WHERE UPPER(role_name)='SUPPLIER'").map { |g| [g.party_name] }
    supplier_codes.unshift("<empty>")

    location_codes = Location.find_by_sql("SELECT DISTINCT location_code FROM locations WHERE UPPER(location_type_code)='COMPLEX'").map { |g| [g.location_code] }
    location_codes.unshift("<empty>")

    pallet_base_codes = PalletFormatProduct.find_by_sql("SELECT DISTINCT pallet_base_code FROM pallet_format_products").map { |g| [g.pallet_base_code] }
    pallet_base_codes.unshift("<empty>")

    organization_codes = PartiesRole.find_by_sql("SELECT DISTINCT party_name FROM parties_roles WHERE UPPER(party_type_name)='ORGANIZATION' AND UPPER(role_name)='MARKETER'").map { |g| [g.party_name] }
    organization_codes.unshift("<empty>")

    inspection_types =   InspectionType.find_by_sql("select distinct inspection_type_code from inspection_types").map{|i|i.inspection_type_code}

    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'consignment_note_number'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'order_number'}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'created_on'}
    #field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'season'}
    if is_edit
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'intake_header_number'}
    end

    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'season', :settings=>{:list=>season_codes}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'intake_type_code', :settings=>{:list=>intake_type_codes}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'depot_code', :settings=>{:list=>depot_codes}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'puc_code', :settings=>{:list=>puc_codes}}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'packhouse_code'}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'account_code', :settings=>{:list=>account_codes}}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'carrier'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'truck_number'}
    #field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'order_number'}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'supplier_code', :settings=>{:list=>supplier_codes}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'location_code', :settings=>{:list=>location_codes}}

    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'pack_order_number'}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'inspection_type_code', :settings=>{:list=> inspection_types}}

    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'inspector_number'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'inspection_point'}

    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'qty_pallets'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'qty_cartons'}
    field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'inspection_date'}
    field_configs[field_configs.length]   = {:field_type => "CheckBox", :field_name => "transfer_inspection_records"}

    field_configs[field_configs.length()] = {:field_type=>'CheckBox', :field_name=>'recool_required', :observer=>recool_required_observer}
    if intake_header != nil && intake_header.recool_required
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'recool_temperature'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'recool_average_temperature'}
    else
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'recool_temperature', :settings=>{:static_value=>"NO RECOOL TEMP REQUIRED!", :show_label=>true, :css_class=>'intake_label'}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'recool_average_temperature', :settings=>{:static_value=>"NO RECOOL AVG TEMP REQUIRED!", :show_label=>true, :css_class=>'intake_label'}}
    end

    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'pallet_base_code', :settings=>{:list=>pallet_base_codes}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'organization_code', :settings=>{:list=>organization_codes}}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'client_reference'}
    field_configs[field_configs.length()] = {:field_type=>'CheckBox', :field_name=>'edi_transfer_in'}

    pallets_captured                      = 0
    pallets_mapped                        = 0
    if intake_header != nil && !is_create_retry
      depot_pallets = DepotPallet.find_by_sql("SELECT COUNT(*) AS depot_pallets_count FROM depot_pallets WHERE intake_header_id='#{intake_header.id}'")
      if depot_pallets.length != 0
        pallets_captured = depot_pallets[0].depot_pallets_count.to_i
      end
      depot_pallets_mapped = DepotPallet.find_by_sql("SELECT distinct depot_pallet_number FROM mapped_pallet_sequences WHERE intake_header_id='#{intake_header.id}' AND extended_fg_code IS NOT NULL")
      if depot_pallets_mapped.length != 0
        pallets_mapped = depot_pallets_mapped.length #pallets_captured - depot_pallets_mapped[0].pallet_number_count.to_i
      end
      css_class_1 = "intake_green_label"
      if pallets_mapped < intake_header.qty_pallets
        css_class_1 = "intake_red_label"
      end
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'n_pallets_captured', :non_db_field=>true, :settings=>{:static_value=>pallets_captured.to_s, :show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'n_pallets_mapped', :non_db_field=>true, :settings=>{:static_value=>pallets_mapped.to_s, :show_label=>true, :css_class=>css_class_1}}
    end


    if intake_header != nil && !is_create_retry
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'stock', :settings=>{:static_value=>'CAPTURING & MAPPING', :is_separator=>false}}

      if(session[:invalid_pallet_sequences] && session[:invalid_pallet_sequences].length > 0)
        invalid_pick_ref_label_field = "<span id='show_missing_non_fruitspec' style='border: gray thin solid; color:red;font-weight: bold;padding: 2px;'> #{session[:invalid_pallet_sequences].length} sequences" + "</span>"
        field_config3                         = {
            :link_text     =>'show invalid pick ref pallet sequences',
            :controller    => 'fg/depot_receipts',
            :target_action =>'show_invalid_pick_ref_pallet_sequences'
        }
        invalid_pick_ref_link_popup_window_field3              = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', field_config3, true, nil, self)
        invalid_pick_ref_label_string                          = invalid_pick_ref_label_field + "&nbsp;&nbsp;" + invalid_pick_ref_link_popup_window_field3.build_control
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'invalid pick ref seqs', :non_db_field=>true, :settings=>{:static_value=>invalid_pick_ref_label_string, :is_separator=>false, :show_label=>true, :css_class=>'unbordered_label_field'}}
      end

      field_configs[field_configs.length()] =
          {:field_type=>'link_window_field', :field_name=>'pallet_sequences',
           :settings  =>
               {:id_value=>intake_header.id.to_s, :target_action => "pallet_sequences", :link_text => "pallet_sequences"}}

      if  !(intake_header.header_status.upcase == "MAPPING_COMPLETE"||intake_header.header_status.upcase == "LOAD_RECEIVED"||intake_header.header_status.upcase.index("EDI"))
     field_configs[field_configs.length()] =
          {:field_type=>'link_window_field', :field_name=>'depot_pallets',
           :settings  =>
               {:id_value=>intake_header.id.to_s, :target_action => "depot_pallets", :link_text => "depot_pallets"}}
    end


      depot_pallets                         = DepotPallet.find_by_sql("SELECT * FROM depot_pallets WHERE intake_header_id='#{intake_header.id}'")
      if depot_pallets.length != 0 && intake_header.header_status.upcase != "EDI_RECEIVED" && intake_header.header_status.upcase != "CANCELED"
        field_config2                         =
            {:link_text     =>'map by fruitspec',
             :host_and_port =>request.host_with_port.to_s,
             :controller    => 'fg/depot_receipts',
             :target_action =>'map_by_fruitspec'
            }
        link_popup_window_field2              = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', field_config2, true, nil, self)
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'map_by_fruitspec', :non_db_field=>true, :settings=>{:static_value=>link_popup_window_field2.build_control(), :is_separator=>false, :show_label=>true, :css_class=>'unbordered_label_field'}}
      end
      #label_field = ApplicationHelper::StaticField.new(nil, intake_header, 'missing_master_files', 'LabelField', 'intake_header', nil, true, nil)

      missing_mf = IntakeHeader.get_missing_master_files(session[:intake_header].id)
      if missing_mf == 0
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'missing_master_files', :non_db_field=>true, :settings=>{:static_value=>'none missing', :show_label=>true, :css_class=>'intake_green_label'}}
      else
        label_field                           = "<span id='show_missing_non_fruitspec' style='border: gray thin solid; color:red;'>" + missing_mf.to_s + " missing" + "</span>"
        field_config3                         = {
            :link_text     =>'show missing MF(non fruitspec)',
            :host_and_port =>request.host_with_port.to_s,
            :controller    => 'fg/depot_receipts',
            :target_action =>'show_missing_non_fruitspec'
        }
        link_popup_window_field3              = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', field_config3, true, nil, self)
        label_string                          = label_field + "&nbsp;&nbsp;" + link_popup_window_field3.build_control
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'missing_master_files', :non_db_field=>true, :settings=>{:static_value=>label_string, :is_separator=>false, :show_label=>true, :css_class=>'unbordered_label_field'}}
      end

    end

    if intake_header != nil && !is_create_retry
      if intake_header.header_status.to_s == "MAPPING_COMPLETE" || intake_header.header_status.to_s == "LOAD_RECEIVED" || intake_header.header_status.to_s.index("EDI_") != nil && intake_header.header_status != "EDI_RECEIVED" && intake_header.header_status != "CANCELED"
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'stock', :settings=>{:static_value=>'INTAKE PROCESS', :is_separator=>true}}

        if intake_header.transfer_inspection_records && (intake_header.header_status.to_s == "LOAD_RECEIVED" || intake_header.header_status.to_s.index("EDI_") != nil && intake_header.header_status != "EDI_RECEIVED" && intake_header.header_status != "CANCELED")
          field_configs[field_configs.length()] = {:field_type => 'LinkWindowField', :field_name => 'transfer_ppecb_inspection',
                                                   :settings   => {
                                                       :target_action => 'transfer_ppecb_inspection',
                                                       :link_text     => "transfer_ppecb_inspection",
                                                       :id_value      => intake_header.id
                                                   }}

        end


        field_configs[field_configs.length()] = {:field_type => 'LinkWindowField', :field_name => 'print_header_document',
                                                 :settings   => {
                                                     :target_action => 'print_depots_receipt',
                                                     :link_text     => "print_header_document",
                                                     :id_value      => intake_header.id
                                                 }}
      else
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'print_header_document', :non_db_field=>true, :settings=>{:static_value=>'mapping not complete', :is_separator=>false, :show_label=>true, :css_class=>'intake_red_label'}}
      end

      if intake_header.header_status.to_s == "LOAD_RECEIVED" || intake_header.header_status.to_s.index("EDI_") != nil && intake_header.header_status != "EDI_RECEIVED" && intake_header.header_status != "CANCELED"
        field_config5                         = {
            :link_text     =>'create edi flow',
            :host_and_port =>request.host_with_port.to_s,
            :controller    => 'fg/depot_receipts',
            :target_action =>'create_edi_flow',
            :id_column     => 'id'
        }
        link_popup_window_field5              = ApplicationHelper::LinkWindowField.new(nil, intake_header, 'none', 'none', 'none', field_config5, true, nil, self)
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'create_edi_flow', :non_db_field=>true, :settings=>{:static_value=>link_popup_window_field5.build_control(), :is_separator=>false, :show_label=>true, :css_class=>'unbordered_label_field'}}
      else
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'create_edi_flow', :non_db_field=>true, :settings=>{:static_value=>'load not yet received', :is_separator=>false, :show_label=>true, :css_class=>'intake_red_label'}}
      end

      label_field2 = ""
      if intake_header.header_status == "EDI_SENT"
        label_field2 = "<span id='intake_header_status_label' style='border:1px #ccc solid; color:green;'>EDI_SENT</span>"
      elsif intake_header.header_status == "MAPPING_COMPLETE"
        label_field2 = "<span id='intake_header_status_label' style='border:1px #ccc solid; color:orange;'>MAPPING_COMPLETE</span>"
      else
        label_field2 = "<span id='intake_header_status_label' style='border:1px #ccc solid; color:red;'>#{intake_header.header_status}</span>"
      end

      field_config6                         = {
          :link_text     =>'process history',
          :host_and_port =>request.host_with_port.to_s,
          :controller    => 'fg/depot_receipts',
          :target_action =>'process_history',
          :id_column     =>'id'
      }
      link_popup_window_field6              = ApplicationHelper::LinkWindowField.new(nil, intake_header, 'none', 'none', 'none', field_config6, true, nil, self)
      label_string1                         = label_field2 + "&nbsp;&nbsp;" + link_popup_window_field6.build_control
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'intake_header_status', :non_db_field=>true, :settings=>{:static_value=>label_string1, :is_separator=>false, :show_label=>true, :css_class=>'unbordered_label_field'}}
    end


    field_configs[field_configs.length()] = {:field_type=>'HiddenField', :field_name=>'ajax_distributor', :non_db_field=>true}

    build_form(intake_header, field_configs, action, 'intake_header', caption, is_edit)

  end


  def build_pallet_sequences_grid(data_set)

    require File.dirname(__FILE__) + "/../../../app/helpers/fg/depot_receipts_plugins.rb"

    data_set.each do |record|
      if record["mapped_date_time"] == nil || record["mapped_date_time"].strip == ""
        record["mapped?"] = "false"
      else
        record["mapped?"] = "true"
      end
      #record["id"] = record["commodity"].to_s + "!" + record["variety"].to_s + "!" + record["grade"] + "!" + record["count"].to_s + "!" + record["brand"].to_s + "!" + record["pack_type"].to_s + "!" + record["organization"].to_s
    end


    column_configs                        = Array.new

    if session[:intake_header].header_status != "LOAD_RECEIVED" && session[:intake_header].header_status != "EDI_REQUESTED" && session[:intake_header].header_status != "EDI_SENT"
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit', :col_width => 45,
                                                 :settings   =>
                                                     {:image     => 'edit',
                                                      :target_action => 'edit_pallet_sequence',
                                                      :id_column     => 'id'}}
    end

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'print_labels',:col_width=>34, :col_width=> 123,
                                               :settings   =>
                                                   {:image     => 'printer',
                                                    :target_action => 'print_pallet_labels',
                                                    :id_column     => 'id',
                                                    :null_test     => "['header_status'] != 'LOAD_RECEIVED'"}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'view',:col_width=>34, :col_width=> 123,
                                               :settings   =>
                                                   {:image     => 'view',
                                                    :target_action => 'view_pallet_sequence',
                                                    :id_column     => 'id'}}





    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'mapped?',:col_width => 60}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'depot_pallet_number',:col_width => 170}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'pallet_sequence_number',:col_width => 75,:column_caption => 'seq_nr'}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'commodity',:col_width => 35}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'variety',:col_width => 50}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'grade',:col_width => 44}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'class_code',:col_width => 44}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'count',:col_width => 60}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'brand',:col_width => 55}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'pack_type',:col_width => 70}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'organization',:col_width => 60,:column_caption => 'org'}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'puc',:col_width => 70}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'inventory_code',:col_width => 60}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'product_characteristics',:col_width => 60}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'remarks',:col_width => 60}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'target_market',:col_width => 70}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'sell_by_date',:col_width => 65}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'pick_reference',:col_width => 75}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'extended_fg_code',:col_width => 537}




    special_commands                        = {:settings =>
                                                   {:target_action => 'new_pallet_sequence',
                                                    :host_and_port => request.host_with_port.to_s,
                                                    :controller    => 'fg/depot_receipts',
                                                    :link_text     =>"new sequence", :link_type => "popup", :frame_id =>"child_form3_iframe"}}

    set_grid_min_height(325)
    set_grid_min_width(700)
    return get_data_grid(data_set, column_configs, MesScada::GridPlugins::DepotReceipts::PalletSequencePlugin.new(self, request), true, special_commands)

  end


  def build_intake_headers_search_form(intake_header, action, caption, is_flat_search=nil)

    session[:intake_header_search_form]                                    = Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js                                                       = gen_combos_clear_js_for_combos(["intake_header_consignment_note_number", "intake_header_intake_header_number", "intake_header_depot_code", "intake_header_puc_code"])

    consignment_note_number_observer                                       = {:updated_field_id=>'intake_header_number_cell',
                                                                              :remote_method   =>'intake_header_consignment_note_number_combo_changed',
                                                                              :on_completed_js =>search_combos_js["intake_header_consignment_note_number"]
    }
    session[:intake_header_search_form][:consignment_note_number_observer] = consignment_note_number_observer

    intake_header_number_observer                                          = {:updated_field_id=>'depot_code_cell',
                                                                              :remote_method   =>'intake_header_intake_header_number_combo_changed',
                                                                              :on_completed_js =>search_combos_js["intake_header_intake_header_number"]
    }
    session[:intake_header_search_form][:intake_header_number_observer]    = intake_header_number_observer

    depot_code_observer                                                    = {:updated_field_id=>'puc_code_cell',
                                                                              :remote_method   =>'intake_header_depot_code_combo_changed',
                                                                              :on_completed_js =>search_combos_js["intake_header_depot_code"]
    }
    session[:intake_header_search_form][:depot_code_observer]              = depot_code_observer

    consignment_note_numbers                                               = IntakeHeader.find_by_sql("SELECT DISTINCT consignment_note_number FROM intake_headers").map { |g| [g.consignment_note_number] }
    consignment_note_numbers.unshift("<empty>")

    intake_header_numbers = nil
    depot_codes           = nil
    pucs                  = nil

    if is_flat_search
      intake_header_numbers = IntakeHeader.find_by_sql("SELECT DISTINCT intake_header_number FROM intake_headers").map { |g| [g.intake_header_number] }
      intake_header_numbers.unshift("<empty>")
      depot_codes = IntakeHeader.find_by_sql("SELECT DISTINCT depot_code FROM intake_headers").map { |g| [g.depot_code] }
      depot_codes.unshift("<empty>")
      pucs = IntakeHeader.find_by_sql("SELECT DISTINCT puc_code FROM intake_headers").map { |g| [g.puc_code] }
      pucs.unshift("<empty>")
    else
      intake_header_numbers = ["Select a value from consignment_note_number"]
      depot_codes           = ["Select a value from intake_header_number"]
      pucs                  = ["Select a value from depot_code"]
    end

    #	----------------------------------------
    #	 Define search fields to build form from
    #	----------------------------------------
    field_configs    = Array.new
    #	----------------------------------------------------------------------------------------------
    #	Define search Combo fields to represent the unique index on this table
    #	----------------------------------------------------------------------------------------------
    field_configs[0] = {:field_type => 'DropDownField',
                        :field_name => 'consignment_note_number',
                        :settings   => {:list => consignment_note_numbers},
                        :observer   => consignment_note_number_observer}

    field_configs[1] = {:field_type => 'DropDownField',
                        :field_name => 'intake_header_number',
                        :settings   => {:list => intake_header_numbers},
                        :observer   => intake_header_number_observer}

    field_configs[2] = {:field_type => 'DropDownField',
                        :field_name => 'depot_code',
                        :settings   => {:list => depot_codes},
                        :observer   => depot_code_observer}

    field_configs[3] = {:field_type => 'DropDownField',
                        :field_name => 'puc_code',
                        :settings   => {:list => pucs}}

    build_form(intake_header, field_configs, action, 'intake_header', caption, false)

  end


  def build_process_history_form(intake_header, action, caption, is_edit=nil)
    field_configs          = Array.new

    intake_header_statuses = IntakeHeaderStatus.find_by_sql("SELECT DISTINCT intake_status_code, intake_status_date_time FROM intake_header_statuses WHERE intake_header_id='#{intake_header.id}'")

    if intake_header_statuses.length != 0
      status_hash = Hash.new
      intake_header_statuses.each do |status|
        if status.intake_status_code == "HEADER_CREATED"
          status_hash["HEADER_CREATED"] = status
        elsif status.intake_status_code == "CAPTURING_PALLETS"
          status_hash["CAPTURING_PALLETS"] = status
        elsif status.intake_status_code == "PALLETS_CAPTURED"
          status_hash["PALLETS_CAPTURED"] = status
        elsif status.intake_status_code == "MAPPING_COMPLETE"
          status_hash["MAPPING_COMPLETE"] = status
        elsif status.intake_status_code == "HEADER_PRINTED"
          status_hash["HEADER_PRINTED"] = status
        elsif status.intake_status_code == "LOAD_RECEIVED"
          status_hash["LOAD_RECEIVED"] = status
        elsif status.intake_status_code == "EDI_REQUESTED"
          status_hash["EDI_REQUESTED"] = status
        elsif status.intake_status_code == "EDI_SENT"
          status_hash["EDI_SENT"] = status
        elsif status.intake_status_code && status.intake_status_code.upcase == "EDI_RECEIVED"
          status_hash["EDI_RECEIVED"] = status
        elsif status.intake_status_code && status.intake_status_code.upcase == "CANCELED"
          status_hash["CANCELED"] = status
        end
      end


      if status_hash["EDI_RECEIVED"] != nil
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'edi received', :non_db_field=>true, :settings=>{:static_value=>'EDI_RECEIVED - ' + status_hash["EDI_RECEIVED"].intake_status_date_time.to_s, :css_class=>'intake_green_label'}}
      else
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'edi received', :non_db_field=>true, :settings=>{:static_value=>'EDI_RECEIVED', :css_class=>'label_field'}}
      end

      if status_hash["CANCELED"] != nil
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'canceled', :non_db_field=>true, :settings=>{:static_value=>'CANCELED - ' + status_hash["CANCELED"].intake_status_date_time.to_s, :css_class=>'intake_green_label'}}
      else
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'canceled', :non_db_field=>true, :settings=>{:static_value=>'CANCELED', :css_class=>'label_field'}}
      end

      if status_hash["HEADER_CREATED"] != nil
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'header_created', :non_db_field=>true, :settings=>{:static_value=>'HEADER_CREATED - ' + status_hash["HEADER_CREATED"].intake_status_date_time.to_s, :css_class=>'intake_green_label'}}
      else
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'header_created', :non_db_field=>true, :settings=>{:static_value=>'HEADER_CREATED', :css_class=>'intake_red_label'}}
      end


      if status_hash["CAPTURING_PALLETS"] != nil
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'pallets_captured', :non_db_field=>true, :settings=>{:static_value=>'CAPTURING_PALLETS - ' + status_hash["CAPTURING_PALLETS"].intake_status_date_time.to_s, :css_class=>'intake_green_label'}}
      else
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'capturing_pallets', :non_db_field=>true, :settings=>{:static_value=>'CAPTURING_PALLETS', :css_class=>'intake_red_label'}}
      end

      if status_hash["PALLETS_CAPTURED"] != nil
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'pallets_captured', :non_db_field=>true, :settings=>{:static_value=>'PALLETS_CAPTURED - ' + status_hash["PALLETS_CAPTURED"].intake_status_date_time.to_s, :css_class=>'intake_green_label'}}
      else
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'pallets_captured', :non_db_field=>true, :settings=>{:static_value=>'PALLETS_CAPTURED', :css_class=>'intake_red_label'}}
      end

      if status_hash["MAPPING_COMPLETE"] != nil
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'mapping_complete', :non_db_field=>true, :settings=>{:static_value=>'MAPPING_COMPLETE - ' + status_hash["MAPPING_COMPLETE"].intake_status_date_time.to_s, :css_class=>'intake_green_label'}}
      else
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'mapping_complete', :non_db_field=>true, :settings=>{:static_value=>'MAPPING_COMPLETE', :css_class=>'intake_red_label'}}
      end

      if status_hash["HEADER_PRINTED"] != nil
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'header_printed', :non_db_field=>true, :settings=>{:static_value=>'HEADER_PRINTED - ' + status_hash["HEADER_PRINTED"].intake_status_date_time.to_s, :css_class=>'intake_green_label'}}
      else
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'header_printed', :non_db_field=>true, :settings=>{:static_value=>'HEADER_PRINTED', :css_class=>'intake_red_label'}}
      end

      if status_hash["LOAD_RECEIVED"] != nil
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'load_received', :non_db_field=>true, :settings=>{:static_value=>'LOAD_RECEIVED - ' + status_hash["LOAD_RECEIVED"].intake_status_date_time.to_s, :css_class=>'intake_green_label'}}
      else
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'load_received', :non_db_field=>true, :settings=>{:static_value=>'LOAD_RECEIVED', :css_class=>'intake_red_label'}}
      end

      if status_hash["EDI_REQUESTED"] != nil
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'edi_requested', :non_db_field=>true, :settings=>{:static_value=>'EDI_REQUESTED - ' + status_hash["EDI_REQUESTED"].intake_status_date_time.to_s, :css_class=>'intake_green_label'}}
      else
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'edi_requested', :non_db_field=>true, :settings=>{:static_value=>'EDI_REQUESTED', :css_class=>'intake_red_label'}}
      end

      if status_hash["EDI_SENT"] != nil
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'edi_sent', :non_db_field=>true, :settings=>{:static_value=>'EDI_SENT - ' + status_hash["EDI_SENT"].intake_status_date_time.to_s, :css_class=>'intake_green_label'}}
      else
        field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'edi_sent', :non_db_field=>true, :settings=>{:static_value=>'EDI_SENT', :css_class=>'intake_red_label'}}
      end

    else
      field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'header_created', :non_db_field=>true, :settings=>{:static_value=>'HEADER_CREATED', :css_class=>'intake_red_label'}}
      field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'pallets_captured', :non_db_field=>true, :settings=>{:static_value=>'PALLETS_CAPTURED', :css_class=>'intake_red_label'}}
      field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'mapping_complete', :non_db_field=>true, :settings=>{:static_value=>'MAPPING_COMPLETE', :css_class=>'intake_red_label'}}
      field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'header_printed', :non_db_field=>true, :settings=>{:static_value=>'HEADER_PRINTED', :css_class=>'intake_red_label'}}
      field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'load_received', :non_db_field=>true, :settings=>{:static_value=>'LOAD_RECEIVED', :css_class=>'intake_red_label'}}
      field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'edi_requested', :non_db_field=>true, :settings=>{:static_value=>'EDI_REQUESTED', :css_class=>'intake_red_label'}}
      field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'edi_sent', :non_db_field=>true, :settings=>{:static_value=>'EDI_SENT', :css_class=>'intake_red_label'}}
    end

    field_config                        = {
        :link_text     =>'edi process history',
        :host_and_port =>request.host_with_port.to_s,
        :controller    => 'fg/depot_receipts',
        :target_action =>'edi_process_history',
        :id_column     =>"id"
    }
    link_popup_window_field             = ApplicationHelper::LinkWindowField.new(nil, intake_header, 'none', 'none', 'none', field_config, true, nil, self)

    field_configs[field_configs.length] = {:field_type=>'LabelField', :field_name=>'edi_process_history', :non_db_field=>true, :settings=>{:static_value=>link_popup_window_field.build_control}}

    build_form(intake_header, field_configs, action, 'intake_header_status', caption, is_edit)
  end


  def build_intake_headers_grid(data_set, can_edit, can_delete)

    column_configs = Array.new
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit',:col_width => 43,
                                                 :settings   =>
                                                     {:image     => 'edit',
                                                      :target_action => 'edit_intake_header',
                                                      :id_column     => 'id'}}
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'cancel',:col_width => 43,
                                                 :settings   =>
                                                     {:image     => 'cancel',
                                                      :target_action => 'cancel_intake_header',
                                                      :id_column     => 'id', :null_test => "['header_status'] != 'EDI_RECEIVED'"}}

       column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete', :col_width => 43,
                                                 :settings   =>
                                                     {:image     => 'delete',
                                                      :target_action => 'delete_intake_header',
                                                      :id_column     => 'id', :null_test => "['header_status'] == 'EDI_RECEIVED' ||active_record['header_status'] == 'LOAD_RECEIVED'  "}}
#       :id_column => 'id',:id_column => 'id',:null_test => "['order_status'].to_s =='LOADED'||active_record['order_status'] == 'COMPLETE'||active_record['order_status'] == 'LOADING'"}}

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'accept',:col_width => 43,
                                                 :settings   =>
                                                     {:image     => 'accept',
                                                      :target_action => 'accept_intake_header',
                                                      :id_column     => 'id',
                                                      :null_test     => "['header_status'] != 'EDI_RECEIVED'"}}

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'print', :col_width => 43,
                                                 :settings   =>
                                                     {:image     => 'printer',
                                                      :target_action => 'print_depots_receipt',
                                                      :id_column     => 'id'
                                                     }}

    end

    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'consignment_note_number',:col_width => 100}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'intake_header_number',:col_width => 55}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'doc_source',:col_width => 70}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'created_on',:col_width => 70}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'depot_code',:col_width => 47}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'puc_code',:col_width => 70}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'header_status',:col_width => 125}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'account_code',:col_width => 62}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'carrier',:col_width => 81}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'truck_number',:col_width => 90}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'supplier_code',:col_width => 45}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'organization_code', :column_caption => 'org',:col_width => 48}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'sell_by_code',:col_width => 48}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'recool_required',:col_width => 48}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'channel',:col_width => 50}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'pick_reference',:col_width => 72}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'location_code',:col_width => 96}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'order_number',:col_width => 96}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'edi_status',:col_width => 50}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'puc_code',:col_width => 80}


    return get_data_grid(data_set, column_configs, MesScada::GridPlugins::Fg::IntakeHeaderGridPlugin.new, true)
  end


  def build_pallet_sequence_frame(child_form, action, caption, is_edit)
    field_configs                         = Array.new

    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form1",
                                             :settings   =>{:target_action => 'pallet_sequences',
                                                            :id_column     => nil,
                                                            :request       => request,
                                                            :height        => 400, :width => 800}}

    build_form(child_form, field_configs, nil, 'pallet_sequences', caption)
  end


  def build_pallet_sequence_form(pallet_sequence, action, caption, is_edit=nil, is_create_retry=nil)
    field_configs = Array.new

    if is_edit && pallet_sequence.mapped_date_time != nil #// Editing of record
      mapped_sequence                       = MappedPalletSequence.find_by_pallet_sequence_id(pallet_sequence.id)
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'depot_pallet_number', :settings=>{:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'organization', :settings=>{:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'commodity', :settings=>{:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'variety', :settings=>{:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'grade', :settings=>{:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'count', :settings=>{:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'brand', :settings=>{:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'pack_type', :settings=>{:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'channel', :settings=>{:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'class_code'}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'fg_code_old', :settings=>{:static_value => mapped_sequence.fg_code_old, :show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'item_pack_product_code', :settings=>{:static_value => mapped_sequence.item_pack_product_code, :show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'extended_fg_code', :settings=>{:static_value => mapped_sequence.extended_fg_code, :show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'mark_code', :settings=>{:static_value => mapped_sequence.mark_code, :show_label=>true}}
    else
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'depot_pallet_number'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'organization'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'commodity'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'variety'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'grade'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'count'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'class_code'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'brand'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'pack_type'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'channel'}
    end
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'puc'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'target_market'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'pick_reference'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'inventory_code'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'sell_by_date'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'product_characteristics'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'remarks'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'seq_ctn_qty'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'pallet_ctn_qty'}

    build_form(pallet_sequence, field_configs, action, 'pallet_sequence', caption, is_edit)

  end

  def build_view_pallet_sequence_form(pallet_sequence, action, caption, is_edit=nil)
    field_configs                         = Array.new

    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'depot_pallet_number', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'organization', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'commodity', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'variety', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'grade', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'count', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'brand', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'pack_type', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'channel', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'puc', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'target_market', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'pick_reference', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'inventory_code', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'sell_by_date', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'product_characteristics', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'remarks', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'seq_ctn_qty', :settings=>{:show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'pallet_ctn_qty', :settings=>{:show_label=>true}}

    build_form(pallet_sequence, field_configs, action, 'pallet_sequence', caption, is_edit)
  end


  def build_mapped_pallet_sequences_grid(data_set)

    require File.dirname(__FILE__) + "/../../../app/helpers/fg/depot_receipts_plugins.rb"

    column_configs = Array.new

    data_set.each do |record|
      if record["extended_fg_code"] == nil || record["extended_fg_code"].strip == ""
        record["mapped?"] = "false"
      else
        record["mapped?"] = "true"
      end
      record["id"] = record["commodity"].to_s + "|" + record["variety"].to_s + "|" + record["grade"] + "|" + record["count"].to_s + "|" + record["brand"].to_s + "|" + record["pack_type"].to_s + "|" + record["organization"].to_s + "|" + record["mapped?"] + "|" + record["class_code"].to_s
    end


     if session[:intake_header].header_status != "LOAD_RECEIVED" && session[:intake_header].header_status != "EDI_REQUESTED" && session[:intake_header].header_status != "EDI_SENT"

       column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'map',:col_width=>34, :col_width=> 123,
                                                  :settings   =>
                                                      {:link_text     => 'map',
                                                       :target_action => 'map_pallet_sequences',
                                                       :id_column     => 'id'}}
    end

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'pallets',:col_width=>34, :col_width=> 123,
                                               :settings   =>
                                                   {:link_text     => 'pallets',
                                                    :target_action => 'show_intake_header_pallets',
                                                    :id_column     => 'id'}}


    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'mapped?',:col_width => 65}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'commodity',:col_width => 35}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'variety',:col_width => 43}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'class_code',:col_width => 43}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'grade',:col_width => 47}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'count',:col_width => 50}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'brand',:col_width => 60}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'pack_type',:col_width => 60}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'organization',:col_width => 47}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'extended_fg_code',:col_width => 513}



    set_grid_min_height(325)
    set_grid_min_width(700)
    return get_data_grid(data_set, column_configs, MesScada::GridPlugins::DepotReceipts::DepotReceiptPlugin.new(self, request), true)
  end


  def build_mapped_pallet_sequences_form(mapped_pallet_sequence, action, caption, is_edit=nil, is_create_retry=nil)

    field_configs                                                           = Array.new

    session[:mapped_pallet_sequence_form]                                   = Hash.new

    on_complete_mark_code_js                                                = "\n img = document.getElementById('img_mapped_pallet_sequence_mark_code');"
    on_complete_mark_code_js                                                += "\n if(img != null) img.style.display = 'none';"

    mark_code_observer                                                      = {:updated_field_id=>'extended_fg_code_cell',
                                                                               :remote_method   =>'mapped_pallet_sequence_mark_code_combo_changed',
                                                                               :on_completed_js =>on_complete_mark_code_js}

    session[:mapped_pallet_sequence_form][:mark_code_observer]              = mark_code_observer


    on_complete_js                                                          = "\n img = document.getElementById('img_mapped_pallet_sequence_item_pack_product_code');"
    on_complete_js                                                          += "\n if(img != null) img.style.display = 'none';"

    item_pack_product_code_observer                                         = {:updated_field_id=>'extended_fg_code_cell',
                                                                               :remote_method   =>'mapped_pallet_sequence_item_pack_product_code_combo_changed',
                                                                               :on_completed_js =>on_complete_js}

    session[:mapped_pallet_sequence_form][:item_pack_product_code_observer] = item_pack_product_code_observer

    mark_codes                                                              = Mark.find_by_sql("SELECT DISTINCT mark_code FROM marks WHERE brand_code = '#{mapped_pallet_sequence.brand}'").map { |g| [g.mark_code] }
    mark_codes.unshift("<empty>")

    count_where_clause = ""
    if (mapped_pallet_sequence.count.to_s.is_numeric?)
      count_where_clause = "AND (item_pack_products.size_ref='#{mapped_pallet_sequence.count}' or item_pack_products.actual_count = #{mapped_pallet_sequence.count})"
    else
      count_where_clause = "AND item_pack_products.size_ref= '#{mapped_pallet_sequence.count}' "
    end
    item_pack_product_codes = ItemPackProduct.find_by_sql("SELECT DISTINCT item_pack_product_code FROM item_pack_products WHERE commodity_code='#{mapped_pallet_sequence.commodity}' AND marketing_variety_code='#{mapped_pallet_sequence.variety}' AND grade_code='#{mapped_pallet_sequence.grade}' and product_class_code='#{mapped_pallet_sequence.class_code}' #{count_where_clause}").map { |g| [g.item_pack_product_code] }
    item_pack_product_codes.unshift("<empty>")

    if  mapped_pallet_sequence.item_pack_product_code
      extended_fg_codes = ExtendedFg.get_extended_fg_codes(mapped_pallet_sequence.fg_code_old, mapped_pallet_sequence.item_pack_product_code, mapped_pallet_sequence.organization, mapped_pallet_sequence.mark_code)
    else
      extended_fg_codes = ["Select values from item_pack_product_code"]
    end

    matching_pallets_query = "SELECT DISTINCT pallet_sequences.depot_pallet_id FROM pallet_sequences"
    matching_pallets_query += " WHERE "
    matching_pallets_query += " pallet_sequences.commodity='#{mapped_pallet_sequence.commodity}' AND pallet_sequences.variety='#{mapped_pallet_sequence.variety}'"
    matching_pallets_query += " AND pallet_sequences.grade='#{mapped_pallet_sequence.grade}' AND pallet_sequences.count='#{mapped_pallet_sequence.count}'"
    matching_pallets_query += " AND pallet_sequences.brand='#{mapped_pallet_sequence.brand}' AND pallet_sequences.pack_type='#{mapped_pallet_sequence.pack_type}' AND pallet_sequences.class_code = '#{mapped_pallet_sequence.class_code}'"

    matching_pallets       = ActiveRecord::Base.connection.select_all(matching_pallets_query)
    matching_pallets_count = 0
    if matching_pallets.length != 0
      matching_pallets_count = matching_pallets.length
    end

    if mapped_pallet_sequence.mapped == "false"
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'fruitspec_mapped?', :non_db_field=>true, :settings=>{:static_value=>mapped_pallet_sequence.mapped.to_s, :show_label=>true, :css_class=>"intake_red_label"}}
    else
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'fruitspec_mapped?', :non_db_field=>true, :settings=>{:static_value=>mapped_pallet_sequence.mapped.to_s, :show_label=>true, :css_class=>"intake_green_label"}}
    end

    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'intake_header_number', :non_db_field=>true, :settings=>{:static_value=>mapped_pallet_sequence.intake_header_number.to_s, :show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'matching_pallets', :non_db_field=>true, :settings=>{:static_value=>matching_pallets_count.to_s, :show_label=>true}}

    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'fruitspec_fields', :settings=>{:static_value=>'FRUITSPEC FIELDS', :is_separator=>true}}
    commodity                             = Commodity.find_by_commodity_code(mapped_pallet_sequence.commodity)
    variety                               = MarketingVariety.find_by_marketing_variety_code(mapped_pallet_sequence.variety)
    grade                                 = Grade.find_by_grade_code(mapped_pallet_sequence.grade)
    count                                 = mapped_pallet_sequence.count
    class_code                            = ProductClass.find_by_product_class_code(mapped_pallet_sequence.class_code)

#    if !count
#      count = ItemPackProduct.find_by_size_ref(mapped_pallet_sequence.count)
#    end
    brand                                 = Mark.find_by_brand_code(mapped_pallet_sequence.brand)
    pack_type                             = OldPack.find_by_old_pack_code(mapped_pallet_sequence.pack_type)
    if commodity
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'commodity', :settings=>{:static_value=>mapped_pallet_sequence.commodity.to_s, :show_label=>true, :css_class=>'intake_green_label'}}
    else
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'commodity', :settings=>{:static_value=>mapped_pallet_sequence.commodity.to_s, :show_label=>true, :css_class=>'intake_red_label'}}
    end
    if variety
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'variety', :settings=>{:static_value=>mapped_pallet_sequence.variety.to_s, :show_label=>true, :css_class=>'intake_green_label'}}
    else
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'variety', :settings=>{:static_value=>mapped_pallet_sequence.variety.to_s, :show_label=>true, :css_class=>'intake_red_label'}}
    end
    if grade
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'grade', :settings=>{:static_value=>mapped_pallet_sequence.grade.to_s, :show_label=>true, :css_class=>'intake_green_label'}}
    else
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'grade', :settings=>{:static_value=>mapped_pallet_sequence.grade.to_s, :show_label=>true, :css_class=>'intake_red_label'}}
    end

    if class_code
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'class_code', :settings=>{:static_value=>mapped_pallet_sequence.class_code.to_s, :show_label=>true, :css_class=>'intake_green_label'}}
    else
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'class_code', :settings=>{:static_value=>mapped_pallet_sequence.class_code.to_s, :show_label=>true, :css_class=>'intake_red_label'}}
    end
    if count
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'count', :settings=>{:static_value=>mapped_pallet_sequence.count.to_s, :show_label=>true, :css_class=>'intake_green_label'}}
    else
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'count', :settings=>{:static_value=>mapped_pallet_sequence.count.to_s, :show_label=>true, :css_class=>'intake_red_label'}}
    end
    if brand
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'brand', :settings=>{:static_value=>mapped_pallet_sequence.brand.to_s, :show_label=>true, :css_class=>'intake_green_label'}}
    else
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'brand', :settings=>{:static_value=>mapped_pallet_sequence.brand.to_s, :show_label=>true, :css_class=>'intake_red_label'}}
    end
    if pack_type
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'pack_type', :settings=>{:static_value=>mapped_pallet_sequence.pack_type.to_s, :show_label=>true, :css_class=>'intake_green_label'}}
    else
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'pack_type', :settings=>{:static_value=>mapped_pallet_sequence.pack_type.to_s, :show_label=>true, :css_class=>'intake_red_label'}}
    end

    if !commodity || !variety || !grade || !count || !brand || !pack_type
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'fruitspec_fields_to_map', :settings=>{:static_value=>'FRUITSPEC FIELDS TO MAP', :is_separator=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'mark_code', :settings=>{:static_value=>"missing masterfile entries", :show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'item_pack_product_code', :settings=>{:static_value=>"missing masterfile entries", :show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'organization', :settings=>{:static_value=>mapped_pallet_sequence.organization.to_s, :show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'extended_fg_code', :settings=>{:static_value=>"missing masterfile entries", :show_label=>true}}
    else
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'fruitspec_fields_to_map', :settings=>{:static_value=>'FRUITSPEC FIELDS TO MAP', :is_separator=>true}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'mark_code', :settings=>{:list=>mark_codes}, :observer=>mark_code_observer}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'item_pack_product_code', :settings=>{:list=>item_pack_product_codes}, :observer=>item_pack_product_code_observer}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'organization', :settings=>{:static_value=>mapped_pallet_sequence.organization.to_s, :show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'extended_fg_code', :settings=>{:list=>extended_fg_codes}}

      field_configs[field_configs.length()] = {:field_type=>'HiddenField', :field_name=>'ajax_distributor', :non_db_field=>true}
    end

    build_form(mapped_pallet_sequence, field_configs, action, 'mapped_pallet_sequence', caption, is_edit)

  end


  def build_intake_header_pallets_grid(data_set)
    column_configs                        = Array.new

    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'depot_pallet_number'}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'carton_quantity'}

    return get_data_grid(data_set, column_configs, nil, true)
  end


  def build_missing_master_files_form(pallet_sequence, action, caption, is_edit=nil, is_create_retry=nil)
    field_configs                         = Array.new

    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'consignment_note_number', :settings=>{:static_value=>pallet_sequence.consignment_note_number.to_s, :show_label=>true}}
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'intake_header_number', :settings=>{:static_value=>pallet_sequence.intake_header_number.to_s, :show_label=>true}}

    pucs                                  = pallet_sequence.pucs
    target_markets                        = pallet_sequence.target_markets
    inventory_codes                       = pallet_sequence.inventory_codes
    pallet_nums                           = pallet_sequence.pallet_nums

    if pallet_sequence.no_location
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'location', :settings=>{:css_class => "red_label_field", :static_value=>'LOCATION', :is_separator=>true}}

      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'missing 1', :non_db_field=>true, :settings=>{:static_value=>"No location specified on header", :show_label=>true}}

    end

    if pucs.length != 0
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'puc', :settings=>{:css_class => "red_label_field", :static_value=>'PUC', :is_separator=>true}}
      ind                                   = 1
      pucs.each do |puc|
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'missing ' + ind.to_s, :non_db_field=>true, :settings=>{:static_value=>puc.to_s, :show_label=>true}}
        ind                                   += 1
      end
    end

    if target_markets.length != 0
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'target_market', :settings=>{:css_class => "red_label_field", :static_value=>'TARGET MARKET', :is_separator=>true}}
      ind                                   = 1
      target_markets.each do |target_mark|
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'missing ' + ind.to_s, :non_db_field=>true, :settings=>{:static_value=>target_mark.to_s, :show_label=>true}}
        ind                                   += 1
      end
    end

    if inventory_codes.length != 0
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'inventory_code', :settings=>{:css_class => "red_label_field", :static_value=>'INVENTORY CODE', :is_separator=>true}}
      ind                                   = 1
      inventory_codes.each do |inventory|
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'missing ' + ind.to_s, :non_db_field=>true, :settings=>{:static_value=>inventory.to_s, :show_label=>true}}
        ind                                   += 1
      end
    end


    if pallet_nums.length != 0
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'pallet_nums', :settings=>{:css_class => "red_label_field", :static_value=>'PALLETS WITH NO PALLET FORMAT PRODUCT', :is_separator=>true}}
      ind                                   = 1
      pallet_nums.each do |pallet_num|
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'missing ' + ind.to_s, :non_db_field=>true, :settings=>{:static_value=>pallet_num.to_s, :show_label=>true}}
        ind                                   += 1
      end
    end

    build_form(pallet_sequence, field_configs, action, 'pallet_sequence', caption, is_edit)
  end


  def build_edi_process_history_grid(data_set)
    column_configs                        = Array.new
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'intake_status_code'}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'intake_status_date_time'}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'intake_status_description'}
    column_configs[column_configs.length] = {:field_type => 'text', :field_name => 'intake_status_username'}
    #column_configs[column_configs.length] = {:field_type => 'text',:field_name => 'intake_status_username'}

    return get_data_grid(data_set, column_configs)
  end


  def build_enter_amount_of_pallet_labels_to_print_form(pallet_amount, action, caption, is_edit=nil)
    field_configs                         = Array.new

    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'pallet_label_amount'}


    build_form(pallet_amount, field_configs, action, 'pallet_amount', caption, is_edit, nil, nil, true)
  end


end