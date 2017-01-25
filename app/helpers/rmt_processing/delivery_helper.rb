module RmtProcessing::DeliveryHelper

  def build_weigh_sample_bins_form

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'delivery_number'}


    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                                :field_name => 'weight'}


    build_form(nil, field_configs, 'weigh_delivery_submit', 'delivery', 'accept weight', nil)

  end

  def build_delivery_form(delivery, action, caption, show_100_fruit_sample_link, show_print_tripsheet_link, is_edit = nil, is_create_retry = nil)

    #delivery,action,caption,is_edit = nil,is_create_retry = nil

    #	--------------------------------------------------------------------------------------------------
    #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #	in a composite foreign key
    #	--------------------------------------------------------------------------------------------------
    session[:delivery_form]                             = Hash.new
    #generate javascript for the on_complete ajax event for each combo
    combos_js_for_delivery                              = gen_combos_clear_js_for_combos(["delivery_farm_code", "delivery_commodity_code", "delivery_rmt_product_code", "delivery_rmt_variety_code","delivery_commodity_id"])
    search_combos_js = gen_combos_clear_js_for_combos(["delivery_rmt_product_type_code","delivery_rmt_product_code"])
    #Observers for search combos
    rmt_product_type_code_observer  = {:updated_field_id => "rmt_product_id_cell",
                                       :remote_method => 'rmt_product_type_code_combo_changed',
                                       :on_completed_js => search_combos_js["delivery_rmt_product_type_code"]}

    farm_code_observer                                  = {:updated_field_id =>'puc_code_cell',
                                                           :remote_method    =>'farm_code_changed',
                                                           :on_completed_js  =>combos_js_for_delivery["delivery_farm_code"]}

    on_complete_js                                      = "\n img = document.getElementById('img_delivery_commodity_code');"
    on_complete_js                                      += "\n if(img != null) img.style.display = 'none';"
    commodity_code_observer                             = {:updated_field_id =>'rmt_variety_code_cell',
                                                           :remote_method    =>'commodity_code_changed',
                                                           :on_completed_js  =>on_complete_js}

    on_complete_rmt_variety_code_js                     = "\n img = document.getElementById('img_delivery_rmt_variety_code');"
    on_complete_rmt_variety_code_js                     += "\n if(img != null) img.style.display = 'none';"

    rmt_variety_code_observer                           = {:updated_field_id =>'orchard_id_cell',#'rmt_product_id_cell',#
                                                           :remote_method    =>'rmt_variety_code_changed',
                                                           :on_completed_js  =>on_complete_rmt_variety_code_js}

    #MM112014 - populate orchard description
    on_complete_orchard_id_js                     = "\n img = document.getElementById('img_delivery_orchard_id');"
    on_complete_orchard_id_js                     += "\n if(img != null) img.style.display = 'none';"

    orchard_id_observer                                 = {:updated_field_id =>'orchard_description_cell',
                                                           :remote_method    =>'orchard_id_changed',
                                                           :on_completed_js  =>on_complete_orchard_id_js}

    on_completed_js                                     = "\n img = document.getElementById('img_delivery_mrl_result_type');"
    on_completed_js                                     += "\n if(img != null) img.style.display = 'none';"
    mrl_result_type_observer                            = {:updated_field_id =>'ajax_distributor_cell',
                                                           :remote_method    =>'mrl_result_type_changed',
                                                           :on_completed_js  =>on_completed_js}

    session[:delivery_form][:farm_code_observer]        = farm_code_observer
    session[:delivery_form][:commodity_code_observer]   = commodity_code_observer
    session[:delivery_form][:rmt_product_type_code_observer]   = rmt_product_type_code_observer
    session[:delivery_form][:rmt_variety_code_observer] = rmt_variety_code_observer
    #MM112014 - add orchard id
    session[:delivery_form][:orchard_id_observer] = orchard_id_observer
    session[:delivery_form][:mrl_result_type_observer]  = mrl_result_type_observer

    combos_js_for_non_delivery_fields                   = gen_combos_clear_js_for_combos(["delivery_ripe_code","delivery_ripe_point_code"])#,"delivery_treatment_code"])
    ripe_code_observer                                  = {:updated_field_id =>'ripe_point_code_cell',
                                                           :remote_method    =>'ripe_code_changed',
                                                           :on_completed_js  =>combos_js_for_non_delivery_fields["delivery_ripe_code"]}

    on_completed_js                                     = "\n img = document.getElementById('img_delivery_ripe_point_code');"
    on_completed_js                                     += "\n if(img != null) img.style.display = 'none';"
    ripe_point_code_observer                                 = {:updated_field_id =>'rmt_product_id_cell',
                                                                :remote_method    =>'ripe_point_code_changed',
                                                                :on_completed_js  =>on_completed_js}

    on_completed_js                                     = "\n img = document.getElementById('img_delivery_treatment_code');"
    on_completed_js                                     += "\n if(img != null) img.style.display = 'none';"
    treatment_code_observer                             = {:updated_field_id =>'rmt_product_id_cell',
                                                           :remote_method    =>'treatment_code_changed',
                                                           :on_completed_js  =>on_completed_js}


    session[:delivery_form][:treatment_code_observer]  = treatment_code_observer
    session[:delivery_form][:ripe_code_observer]       = ripe_code_observer
    session[:delivery_form][:ripe_point_code_observer]       = ripe_point_code_observer

    farm_codes                                          = nil
    commodity_codes                                     = nil
    rmt_variety_codes                                   = nil
    #MM102014 - add  orchard id
    orchard_id = nil
    unit_type_codes                                     = nil
    season_codes                                        = nil

    commodity_code                                      = nil
    rmt_variety_code                                    = nil
    season_code                                         = nil
    mrl_result_types                                    = nil

    if session[:new_delivery]!= nil
      farm_codes = Farm.find_by_sql("select distinct farm_code from farms").map { |g| [g.farm_code] }
      farm_codes.delete(session[:new_delivery][:farm_code])
      farm_codes.unshift(session[:new_delivery][:farm_code])
    else
      farm_codes = Farm.find_by_sql("select distinct farm_code from farms").map { |g| [g.farm_code] }
    end

    if is_edit
      delivery_track_indicators = DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{delivery.id}'")
    end
    mrl_result_types  = MrlResultType.find_by_sql("select distinct mrl_result_type_code from mrl_result_types").map { |g| [g.mrl_result_type_code] }
    commodity_codes   = RmtVariety.find_by_sql("select distinct commodity_code from rmt_varieties").map { |g| [g.commodity_code] }
    rmt_product_type_codes   = RmtProductType.find(:all,:select=>"distinct rmt_product_type_code").map { |g| [g.rmt_product_type_code] }
    destination_process_vars = ['PRESORT','RA','CA']
    bin_products      = Delivery.get_unit_type_codes
    season_codes      = Season.find_by_sql("select distinct season_code from seasons").map { |g| [g.season_code] }

    rmt_variety_codes = ["select a value from commodity_code"]
    rmt_product_codes = ["select a value from commodity_code and rmt_variety_code and rmt_product_type_code"]

    #MM102014 - add orchard id
    orchards = ["select a value from farm_code and commodity_code and rmt_variety_code"]

    # orchard_id = Orchard.find_by_sql("select orchards.id,orchards.orchard_code,orchards.orchard_description from orchards inner join rmt_varieties on orchards.orchard_rmt_variety_id = rmt_varieties.id inner join commodities on rmt_varieties.commodity_id = commodities.id where rmt_varieties.commodity_code = '#{session[:delivery_form][:commodity_code_combo_selection]}' and rmt_varieties.rmt_variety_code = '#{session[:delivery_form][:rmt_variety_code_combo_selection]}'").map{|g|["#{g.orchard_code} - #{g.orchard_description}", g.id]} # farm_code = '#{session[:delivery_form][:farm_code_combo_selection]}' and puc_code = '#{session[:delivery_form][:puc_code]}' and
    # orchard_id.unshift(delivery.orchard_id)

    treatment_codes   = Treatment.find_by_sql("select distinct treatment_code from treatments where treatment_type_code = 'PRE_HARVEST'").map { |g| [g.treatment_code] }
    ripe_codes = RipeTime.find_by_sql("select distinct ripe_code from ripe_times").map { |r| [r.ripe_code] }
    ripe_codes.unshift("<empty>")
    ripe_point_codes = ["select a value from ripe_code"]
    if is_edit || is_create_retry
      session[:delivery_form][:commodity_code_combo_selection] = delivery.commodity_code
      rmt_variety_codes = RmtVariety.find_by_sql("select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{session[:delivery_form][:commodity_code_combo_selection]}' ORDER BY rmt_variety_code ASC").map{|g|[g.rmt_variety_code]}
      rmt_variety_codes.unshift(delivery.rmt_variety_code)

      orchards = Orchard.find_by_sql("select distinct orchards.id,orchards.orchard_code,orchards.orchard_description from orchards
                                      inner join rmt_varieties on orchards.orchard_rmt_variety_id = rmt_varieties.id
                                      inner join commodities on rmt_varieties.commodity_id = commodities.id
                                      inner join farms on orchards.farm_id = farms.id
                                      where farm_code = '#{delivery.farm_code}' and rmt_varieties.commodity_code = '#{delivery.commodity_code}' and rmt_varieties.rmt_variety_code = '#{delivery.rmt_variety_code}'").map{|g|["#{g.orchard_code} - #{g.orchard_description}", g.id]}


      #MM102014 - add orchard id
      # orchard_id = Orchard.find_by_sql("select orchards.id,orchards.orchard_code,orchards.orchard_description from orchards inner join rmt_varieties on orchards.orchard_rmt_variety_id = rmt_varieties.id inner join commodities on rmt_varieties.commodity_id = commodities.id where rmt_varieties.commodity_code = '#{session[:delivery_form][:commodity_code_combo_selection]}'").map{|g|["#{g.orchard_code} - #{g.orchard_description}", g.id]} # farm_code = '#{session[:delivery_form][:farm_code_combo_selection]}' and puc_code = '#{session[:delivery_form][:puc_code]}' and and rmt_varieties.rmt_variety_code = '#{session[:delivery_form][:rmt_variety_code_combo_selection]}'
      # orchard_id.unshift(delivery.orchard_id)

      ripe_point_codes = RipePoint.find_by_sql("select distinct ripe_point_code from ripe_points ORDER BY ripe_point_code ASC").map{|h| [h.ripe_point_code]}
      #      ripe_point_codes.unshift(delivery.ripe_point_code)
      #      ============
      session[:delivery_form][:rmt_variety_code_combo_selection] =  delivery.rmt_variety_code
      session[:delivery_form][:commodity_code_combo_selection] = delivery.commodity_code
      rmt_product_codes = RmtProduct.find_by_sql("select rmt_product_code,id from rmt_products where variety_code='#{session[:delivery_form][:rmt_variety_code_combo_selection]}' and commodity_code='#{session[:delivery_form][:commodity_code_combo_selection]}' and rmt_product_type_code='orchard_run' ORDER BY rmt_product_code").map{|g|[g.rmt_product_code,g.id]}
      rmt_product_codes.unshift([RmtProduct.find(delivery.rmt_product_id).rmt_product_code, delivery.rmt_product_id]) if(delivery.rmt_product_id && delivery.rmt_product_id > 0)
      rmt_product_codes.unshift("<empty>")
#       ============
    end

    track_slms_indicator = TrackSlmsIndicator.find_by_track_indicator_type_code("LOB")
    if track_slms_indicator != nil
      commodity_code                             = track_slms_indicator.commodity_code
      rmt_variety_code                           = track_slms_indicator.rmt_variety_code
      season_code                                = track_slms_indicator.season_code
      session[:delivery_form][:commodity_code]   = commodity_code
      session[:delivery_form][:rmt_variety_code] = rmt_variety_code
      session[:delivery_form][:season_code]      = season_code

    end

    destination_complexes = Location.find(:all,:conditions=>"location_type_code='COMPLEX'").map{|l| l.location_code}

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------

    field_configs                         = Array.new
    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'farm_code',
                                             :settings   =>{:list=>farm_codes},
                                             :observer   =>farm_code_observer}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'puc_code',
                                             :settings   =>{:css_class=>'delivery_label'}}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'pick_team'}

    #MM102014 - add orchard id
    # field_configs[field_configs.length()] = {:field_type => 'TextField',
    #                                          :field_name => 'orchard_description'}

    if !is_edit || (is_edit && delivery_track_indicators.length == 0)
      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'destination_process_var',
                                               :settings   =>{:list=>destination_process_vars}}

      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'commodity_code',
                                               :settings   =>{:list=>commodity_codes},
                                               :observer   =>commodity_code_observer}

      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'rmt_variety_code',
                                               :settings   =>{:list=>rmt_variety_codes, :no_empty => true},
                                               :observer   =>rmt_variety_code_observer}

      #MM102014 - add orchard id
      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'orchard_id',
                                               :settings   =>{:list=>orchards},
                                               :observer   =>orchard_id_observer}

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'orchard_description'}

      #field_configs[field_configs.length()] = {:field_type => 'DropDownField',
      #                                         :field_name => 'rmt_product_type_code',
      #                                         :settings   =>{:list=>rmt_product_type_codes},
      #                                         :observer   =>rmt_product_type_code_observer}
    else
      session[:delivery_form][:commodity_code_combo_selection] = delivery.commodity_code
      session[:delivery_form][:rmt_product_type_code_combo_selection] = delivery.rmt_product.rmt_product_type_code if(delivery.rmt_product)
      session[:delivery_form][:rmt_variety_code_combo_selection] = delivery.rmt_variety_code
      session[:delivery_form][:ripe_point_code_combo_selection] = delivery.ripe_point_code

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'destination_process_var',
                                               :settings   =>{:css_class=>'delivery_label'}}

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'commodity_code',
                                               :settings   =>{:css_class=>'delivery_label'}}

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'rmt_variety_code',
                                               :settings   =>{:css_class=>'delivery_label'}}

      if(@hundred_fruit_sample_completed && !delivery.rmt_product_type_code)
        field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                                 :field_name => 'rmt_product_type_code',
                                                 :settings   =>{:list=>rmt_product_type_codes},
                                                 :observer   =>rmt_product_type_code_observer}
      elsif(@hundred_fruit_sample_completed)
        field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                 :field_name => 'rmt_product_type_code',
                                                 :settings   =>{:css_class=>'delivery_label'}}
      end

    end

    # if is_edit || is_create_retry
    #   farm_code = session[:delivery_form][:farm_code_combo_selection]
    #   puc_code = session[:delivery_form][:puc_code]
    #   commodity_code = session[:delivery_form][:commodity_code_combo_selection]
    #
    #   orchard_id = Orchard.find_by_sql("select orchards.orchard_code,orchards.orchard_description from orchards").map { |g| [g.orchard_code] } # farm_code = '#{farm_code}' and
    #
    #   # orchard_id = Orchard.find_by_sql("select orchards.orchard_code,orchards.orchard_description from orchards
    #   #                                  inner join rmt_varieties on orchards.orchard_rmt_variety_id = rmt_varieties.id
    #   #                                  inner join commodities on rmt_varieties.commodity_id = commodities.id
    #   #                                  where puc_code = '#{puc_code}' and commodity_code = '#{commodity_code}' and rmt_variety_code = '#{rmt_variety_code}'").map { |g| [g.orchard_code] } # farm_code = '#{farm_code}' and
    #   orchard_id.unshift("<empty>")
    # else
    #   orchard_id = ["select a value from farm_code and commodity_code and rmt_variety_code"]
    # end

    #:observer   =>orchard_id_observer}

    #--------------------------------1------------------------
    #--------------------------------------------------------
    if(@hundred_fruit_sample_completed)
      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'ripe_code',
                                               :settings   =>{:list=>ripe_codes},#, :no_empty => true},
                                               :observer   =>ripe_code_observer}

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'advised_ripe_point_code',
                                               :settings   =>{:css_class=>'delivery_label'}}

      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'ripe_point_code',
                                               :settings   =>{:list=>ripe_point_codes},#, :no_empty => true},
                                               :observer   =>ripe_point_code_observer}

      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'treatment_code',
                                               :settings   =>{:list=>treatment_codes},
                                               :observer   =>treatment_code_observer}

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'advised_rmt_product_code',
                                               :settings   =>{:css_class=>'delivery_label',:show_label=>true}}

      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'rmt_product_id',
                                               :settings   =>{:label_caption=>'rmt product code',
                                                              :list         =>rmt_product_codes}}#, :no_empty => true}}
    end

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'destination_complex',
                                             :settings   =>{:list=>destination_complexes}}
    #-------------------------------1-------------------------
    #--------------------------------------------------------
    if !is_edit || (is_edit && delivery_track_indicators.length == 0)
      field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                               :field_name => 'season_code',
                                               :settings   =>{:list=>season_codes}}
    else

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'season_code',
                                               :settings   =>{:css_class=>'delivery_label'}}
    end

    field_configs[field_configs.length()] = {:field_type => 'CheckBox',
                                             :field_name => 'residue_free'}

    # field_configs[field_configs.length()] = {:field_type => 'TextField',
    #                                          :field_name => 'orchard_code'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'delivery_number_preprinted'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'delivery_number',
                                             :settings   =>{:css_class=>'delivery_label'}}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'delivery_description'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'truck_registration_number'}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'pack_material_product_code',
                                             :settings   =>{:list=>bin_products}}

    field_configs[field_configs.length()] = {:field_type => 'PopupDateTimeSelector',
                                             :field_name => 'date_delivered'}

    field_configs[field_configs.length()] = {:field_type => 'PopupDateTimeSelector',
                                             :field_name => 'date_time_picked'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'quantity_full_bins'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'quantity_partial_units'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'quantity_empty_units'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'quantity_damaged_units'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'remarks'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'operator_override',
                                             :settings   =>{:css_class=>'delivery_label'}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'date_override',
                                             :settings   =>{:css_class=>'delivery_label'}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'drench_delivery',
                                             :settings   =>{:css_class=>'delivery_label'}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'sample_bins',
                                             :settings   =>{:css_class=>'delivery_label'}}

    if delivery.delivery_sample_bins && delivery.delivery_sample_bins.length() > 0
      sequences =   format_delivery_sample_bin_sequences(delivery.delivery_sample_bins.map{|d|d.sample_bin_sequence_number.to_s})
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'sample sequences',
                                               :settings => {:static_value => sequences,:css_class => "blue_label_field", :show_label => true}}

    end

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'mrl_required',
                                             :settings   =>{:css_class=>'delivery_label'}}

    if session[:new_delivery]!= nil
      if session[:new_delivery].delivery_status != nil && session[:new_delivery].delivery_status != ""
        field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                 :field_name => 'delivery_status',
                                                 :settings   =>{:static_value =>session[:new_delivery].delivery_status, :show_label=>true}}
      else
        field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                 :field_name => 'delivery_status',
                                                 :settings   =>{:css_class    =>'delivery_status',
                                                                :static_value =>'capturing', :show_label=>true}}
      end
    else
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'delivery_status',
                                               :settings   =>{:css_class    =>'delivery_status',
                                                              :static_value =>'capturing', :show_label=>true}}
    end

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'mrl_result_type',
                                             :settings   =>{:list=>mrl_result_types, :label_caption=>'mrl analysis type'},
                                             :observer   =>mrl_result_type_observer}

    if is_edit
      field_configs[field_configs.length()] = {:field_type=>'LinkField',
                                               :field_name=>'drenching',
                                               :settings  =>{:link_text    =>'allocate drench',
                                                             :target_action=>'allocate_drench',
                                                             :css_class    =>'indicator_link'}}

      delivery_drench_stations              = DeliveryDrenchStation.find_all_by_delivery_id(delivery.id)
      drench_line = {:field_type => 'LabelField',
                     :field_name => 'delivery_drench_line',
                     :settings   =>{:static_value =>delivery_drench_stations[0].drench_station.drench_line.drench_line_code, :show_label=>true}} if delivery_drench_stations.length > 0
      count                          = 0
      delivery_drench_stations_array = Array.new
      delivery_drench_stations.each do |dds|
        count+=1
        delivery_drench_stations_array.push({:field_type => 'LabelField',
                                             :field_name => 'delivery_drench_station_' + count.to_s,
                                             :settings   =>{:static_value =>dds.drench_station.drench_station_code, :show_label=>true}})
      end
      field_configs.push(drench_line) if drench_line
      field_configs += delivery_drench_stations_array
    end

    if(!delivery.new_record?)
      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings   => {
                                                   :target_action => 'capture_summary_starch_results',
                                                   :link_text     => "capture summary starch results",
                                                   :id_value      => delivery.id.to_s
                                               }}
    end

    if (show_print_tripsheet_link)
      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings   => {
                                                   :target_action => 'print_tripsheet',
                                                   :link_text     => "print tripsheet",
                                                   :id_value      => delivery.id.to_s
                                               }}
    end

    field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                             :field_name => '',
                                             :settings   => {
                                                 :target_action => 'print_composite_report',
                                                 :link_text     => "print composite report",
                                                 :id_value      => delivery.delivery_number.to_s
                                             }}

    field_configs[field_configs.length()] = {:field_type  =>'HiddenField',
                                             :field_name  =>'ajax_distributor',
                                             :non_db_field=>true}

    build_form(delivery, field_configs, action, 'delivery', caption, is_edit)

  end

  def format_delivery_sample_bin_sequences(numeros)
    grp = ""
    count = 0
    numeros.each do |numero|
      count += 1
      grp << numero + ","
      if((count%10) == 0)
        grp << "<br>"
      end
    end
#    puts "PUTSA: " + grp.to_s
#    grp.slice!((grp.length-5),(grp.length-1))
#    puts "PUTSA: " + grp.to_s
    return grp
  end
  
  def build_uneditable_delivery_form(delivery, action, show_100_fruit_sample_link, show_print_tripsheet_link)

    field_configs                         = Array.new
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'farm_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'puc_code'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'pick_team'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'orchard_description'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'destination_process_var',
                                             :settings   =>{:css_class=>'delivery_label',:show_label=>true}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'commodity_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'rmt_variety_code'}
#------------------------------2--------------------------
#--------------------------------------------------------
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'ripe_code'}

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'rmt_product_type_code',
                                               :settings   =>{:css_class=>'delivery_label',:show_label=>true}}

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'advised_ripe_point_code',
                                               :settings   =>{:css_class=>'delivery_label',:show_label=>true}}

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'ripe_point_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                   :field_name => 'treatment_code'}
      
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'advised_rmt_product_code',
                                               :settings   =>{:css_class=>'delivery_label',:show_label=>true}}
#----------------------------2----------------------------
#--------------------------------------------------------
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'rmt_product_id',
                                             :settings   =>{:label_caption=>'rmt_product_code', :show_label => true, :static_value=>RmtProduct.find(delivery.rmt_product_id).rmt_product_code}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'destination_complex'}
    
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'delivery_number_preprinted'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'delivery_number'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'delivery_description'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'truck_registration_number'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'pack_material_product_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'season_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'date_delivered'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'date_time_picked'}

    #field_configs[field_configs.length()] = {:field_type => 'DateTimeField',
    #					                    :field_name => 'time_picked'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'quantity_full_bins'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'quantity_partial_units'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'quantity_empty_units'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'quantity_damaged_units'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'remarks'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'operator_override'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'date_override'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'drench_delivery'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'sample_bins'}


    if delivery.delivery_sample_bins && delivery.delivery_sample_bins.length() > 0
#       sequences =   format_delivery_sample_bin_sequences(delivery.delivery_sample_bins.map{|d|d.sample_bin_sequence_number.to_s})#.join(",")
      sequences =   format_delivery_sample_bin_sequences(delivery.delivery_sample_bins.map{|d|d.sample_bin_sequence_number.to_s})
       field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                :field_name => 'sample sequences',
                                                :settings => {:static_value => sequences,:css_class => "blue_label_field", :show_label => true}}

    end

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'mrl_required'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'delivery_status'}

#    if(show_100_fruit_sample_link)
#       field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
#                                                   :field_name => '',
#                                                   :settings => {
#                                                           :target_action => 'complete_100_fruit_sample',
#                                                           :link_text => "complete 100 fruit sample",
#                                                           :id_value => delivery.id.to_s
#                                                   }}
#     end

    accepted_at_complex = DeliveryRouteStep.find_by_route_step_code_and_delivery_id('accepted_at_complex',delivery.id)
    if (accepted_at_complex && !accepted_at_complex.date_completed)
      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings   => {
                                                   :target_action => 'edit_destination_complex',
                                                   :link_text     => "edit destination",
                                                   :id_value      => delivery.id.to_s
                                               }}
    end

    if(!delivery.new_record?)
      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings   => {
                                                   :target_action => 'capture_summary_starch_results',
                                                   :link_text     => "capture summary starch results",
                                                   :id_value      => delivery.id.to_s
                                               }}
    end

    if (show_print_tripsheet_link)
      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings   => {
                                                   :target_action => 'print_tripsheet',
                                                   :link_text     => "print tripsheet",
                                                   :id_value      => delivery.id.to_s
                                               }}
    end

    field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings   => {
                                                   :target_action => 'print_composite_report',
                                                   :link_text     => "print composite report",
                                                   :id_value      => delivery.delivery_number.to_s
                                               }}
#  field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'mrl_data',
#                       :settings =>
#                      {
#                       :host_and_port =>request.host_with_port.to_s,
#                       :controller =>request.path_parameters['controller'].to_s ,
#                       :target_action => 'mrl_popup_link',
#                       :link_text => 'print mrl label',
#                       :css_class=>'indicator_link'}}

    build_form(delivery, field_configs, action, 'delivery', "")

  end


  def build_delivery_search_form(delivery, action, caption, is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:delivery_search_form]                             = Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js                                           = gen_combos_clear_js_for_combos(["delivery_farm_code", "delivery_puc_code", "delivery_commodity_code", "delivery_rmt_variety_code", "delivery_season_code"])
    #Observers for search combos

    on_complete_js                                             = "\n img = document.getElementById('img_delivery_farm_code');"
    on_complete_js                                             += "\n if(img != null) img.style.display = 'none';"

    farm_code_observer                                         = {:updated_field_id =>"puc_code_cell",
                                                                  :remote_method    =>'delivery_farm_code_search_combo_changed',
                                                                  :on_completed_js  =>search_combos_js["delivery_farm_code"]}

    session[:delivery_search_form][:farm_code_observer]        = farm_code_observer


    puc_code_observer                                          = {:updated_field_id =>"commodity_code_cell",
                                                                  :remote_method    =>'delivery_puc_code_search_combo_changed',
                                                                  :on_completed_js  =>search_combos_js["delivery_puc_code"]}

    session[:delivery_search_form][:puc_code_observer]         = puc_code_observer

    commodity_code_observer                                    = {:updated_field_id=>"rmt_variety_code_cell",
                                                                  :remote_method   =>'delivery_commodity_code_search_combo_changed',
                                                                  :on_completed_js =>search_combos_js["delivery_commodity_code"]}

    session[:delivery_search_form][:commodity_code_observer]   = commodity_code_observer

    rmt_variety_code_observer                                  = {:updated_field_id=>"season_code_cell",
                                                                  :remote_method   =>'delivery_rmt_variety_code_search_combo_changed',
                                                                  :on_completed_js =>search_combos_js["delivery_rmt_variety_code"]}

    session[:delivery_search_form][:rmt_variety_code_observer] = rmt_variety_code_observer


    farm_codes                                                 = Delivery.find_by_sql("select distinct farm_code from deliveries").map { |g| [g.farm_code] }
    farm_codes.unshift("<empty>")
    if is_flat_search
      puc_codes = Delivery.find_by_sql('select distinct puc_code from deliveries').map { |g| [g.puc_code] }
      puc_codes.unshift("<empty>")
      commodity_codes = Delivery.find_by_sql("select distinct commodity_code from deliveries").map { |g| [g.commodity_code] }
      commodity_codes.unshift("<empty>")
      rmt_variety_codes = Delivery.find_by_sql("select distinct rmt_variety_code from deliveries").map { |g| [g.rmt_variety_code] }
      rmt_variety_codes.unshift("<empty>")
      season_codes = Delivery.find_by_sql("select distinct season_code from deliveries").map { |g| [g.season_code] }
      season_codes.unshift("<empty>")
      farm_code_observer        = nil
      puc_code_observer         = nil
      commodity_code_observer   = nil
      rmt_variety_code_observer = nil
    else
      puc_codes         = ["select a value from farm_code"]
      commodity_codes   =["select a value from puc_code"]
      rmt_variety_codes = ["select a value from commodity_code"]
      season_codes      = ["select a value from rmt_variety_code"]
    end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs    = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
    field_configs[0] = {:field_type => 'DropDownField',
                        :field_name => 'farm_code',
                        :settings   => {:list => farm_codes},
                        :observer   =>farm_code_observer}

    field_configs[1] = {:field_type=>'DropDownField',
                        :field_name=>'puc_code',
                        :settings  =>{:list=>puc_codes},
                        :observer  =>puc_code_observer}

    field_configs[2] = {:field_type=>'DropDownField',
                        :field_name=>'commodity_code',
                        :settings  =>{:list=>commodity_codes},
                        :observer  =>commodity_code_observer}

    field_configs[3] = {:field_type=>'DropDownField',
                        :field_name=>'rmt_variety_code',
                        :settings  =>{:list=>rmt_variety_codes},
                        :observer  =>rmt_variety_code_observer}

    field_configs[4] = {:field_type=>'DropDownField',
                        :field_name=>'season_code',
                        :settings  =>{:list=>season_codes}}

    field_configs[5] = {:field_type=>'DateTimeField',
                        :field_name=>'date_from'}
    #:non_db_field=>true}

    field_configs[6] = {:field_type=>'DateTimeField',
                        :field_name=>'date_to'}
    #:non_db_field=>true}

#    field_configs[field_configs.length()] = {:field_type=>'HiddenField',
#                                             :field_name=>'ajax_distributor',
#                                             :non_db_field=>true}


    build_form(delivery, field_configs, action, 'delivery', caption, false)

  end


  def build_delivery_grid(data_set, can_edit, can_delete)

    column_configs = Array.new

    #	----------------------
#	define action columns
#	----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit delivery', :col_width=> 35,
                                                 :settings   =>
                                                     {:image     => 'edit',
                                                      :target_action => 'edit_delivery',
                                                      :id_column     => 'id'}}

      #column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit delivery',
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'complete mrl', :col_width=> 35,
                                                 :settings   =>
                                                     {:image     => 'complete',
                                                      :target_action => 'set_mrl_done',
                                                      :id_column     => 'id'},
                                                      :html_options => {:prompt => "Are you sure you want to complete the mrl data capture route step)"}}

    else
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'view delivery', :col_width=> 35,
                                                 :settings   =>
                                                     {:image     => 'view',
                                                      :target_action => 'view_delivery',
                                                      :id_column     => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete delivery', :col_width=> 35,
                                                 :settings   =>
                                                     {:image     => 'delete',
                                                      :target_action => 'delete_delivery',
                                                      :id_column     => 'id'}}
    end

    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'allocate drench', :col_width=> 77,
                                               :settings   =>
                                                   {:link_text     => 'allocate drench',
                                                    :target_action => 'allocate_drench_from_grid',
                                                    :id_column     => 'id'}}

    if data_set[0].kind_of?(Hash)
      keys                                    = data_set[0].keys
    else
      keys                                    = data_set[0].attributes.keys
    end

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => keys[keys.index('farm_code')], :column_caption=>'farm', :col_width=> 37}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('delivery_number_preprinted')], :col_width=> 68}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('delivery_number')], :col_width=> 51}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('delivery_status')], :col_width=> 218}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('season_code')], :column_caption=>'season', :col_width=> 63}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('commodity_code')], :column_caption=>'commodity', :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('rmt_variety_code')], :column_caption=>'rmt_variety'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('orchard_code')], :column_caption=>'orchard', :col_width=> 65}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('date_delivered')], :col_width=> 134}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('quantity_full_bins')], :column_caption=>'qty_full_bins', :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('quantity_partial_units')], :column_caption=>'qty_partial_units', :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('quantity_empty_units')], :column_caption=>'qty_empty_units', :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('quantity_damaged_units')], :column_caption=>'qty_damaged_units', :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('pack_material_product_code')], :col_width=> 119}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('pick_team')], :col_width=> 45}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => keys[keys.index('updated_at')], :col_width=> 134}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('orchard_description')], :col_width=> 77}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('puc_code')], :column_caption=>'puc', :col_width=> 45}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('delivery_description')], :col_width=> 100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('date_time_picked')], :col_width=> 134}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('remarks')], :col_width=> 80}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('drench_delivery')], :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('sample_bins')], :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('operator_override')], :col_width=> 50}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('date_override')], :col_width=> 134}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('mrl_required')], :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('truck_registration_number')], :col_width=> 102}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('residue_free')], :col_width=> 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>keys[keys.index('mrl_result_type')], :col_width=> 145}
 
    return get_data_grid(data_set, column_configs, MesScada::GridPlugins::RmtProcessing::DeliveriesGridPlugin.new(), true)
  end


#===========================================================
#       add track indicator to delivery code
#===========================================================

  def build_add_track_indicator_form(delivery_track_indicator, action, caption, is_first_time, is_delivery_intake_supervisor, is_edit = nil, is_create_retry = nil)

#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:delivery_track_indicator_form]                                      = Hash.new
    #generate javascript for the on_complete ajax event for each combo
    combos_js_for_delivery_indicator                                             = gen_combos_clear_js_for_combos(["delivery_track_indicator_variety_type", "delivery_track_indicator_track_slms_indicator_code", "delivery_track_indicator_season_code"])

    track_slms_indicator_code_observer                                           = {:updated_field_id=>'track_variable_1_cell',
                                                                                    :remote_method   =>'delivery_track_indicator_track_slms_indicator_code_changed',
                                                                                    :on_completed_js =>combos_js_for_delivery_indicator["delivery_track_indicator_track_slms_indicator_code"]}

    on_complete_js                                      = "\n img = document.getElementById('img_delivery_track_indicator_track_indicator_type_code');"
    on_complete_js                                      += "\n if(img != null) img.style.display = 'none';"
    track_indicator_type_code_observer                                           = {:updated_field_id=>'track_slms_indicator_code_cell',
                                                                                    :remote_method   =>'indicator_track_indicator_type_code_changed',
                                                                                    :on_completed_js =>on_complete_js}

    session[:delivery_track_indicator_form][:track_slms_indicator_code_observer] = track_slms_indicator_code_observer

    variety_type_observer                                                        = {:updated_field_id=>'track_slms_indicator_code_cell',
                                                                                    :remote_method   =>'variety_type_changed',
                                                                                    :on_completed_js =>combos_js_for_delivery_indicator["delivery_track_indicator_variety_type"]}
    non_supervisor_variety_type_observer                                         = {:updated_field_id=>'track_slms_indicator_code_cell',
                                                                                    :remote_method   =>'non_supervisor_variety_type_changed',
                                                                                    :on_completed_js =>combos_js_for_delivery_indicator["delivery_track_indicator_variety_type"]}

#	on_complete_js_rmt_variety = "\n img = document.getElementById('img_delivery_track_indicator_rmt_variety_code');"
#	on_complete_js_rmt_variety += "\n if(img != null) img.style.display = 'none';"
    track_indicator_type_codes                                                   = TrackSlmsIndicator.find_by_sql("select distinct track_indicator_type_code from track_indicator_types").map { |g| [g.track_indicator_type_code] }
#    track_indicator_type_codes.unshift("<non_fruit>")

    variety_types              = ["<non_fruit>", "rmt_variety", "marketing_variety"]

    track_slms_indicator_codes = []


    @rmt_record                = RmtVariety.find_by_rmt_variety_code(session[:new_delivery].rmt_variety_code)
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs              = Array.new

    if  is_first_time
      session[:delivery_track_indicator_form][:first_time] = true
      variety_types                                        = ["<non_fruit>", "rmt_variety"]
    else
      session[:delivery_track_indicator_form][:first_time] = "false"
    end

    field_configs[field_configs.length] = {:field_type=>'DropDownField',
                                           :field_name=>'track_indicator_type_code',
                                           :settings  =>{:list=>track_indicator_type_codes},
                                           :observer  =>track_indicator_type_code_observer}
    if (is_delivery_intake_supervisor)
      field_configs[field_configs.length] = {:field_type=>'DropDownField',
                                             :field_name=>'variety_type',
                                             :settings  =>{:list=>variety_types},
                                             :observer  =>variety_type_observer}
    else
      field_configs[field_configs.length] = {:field_type=>'DropDownField',
                                             :field_name=>'variety_type',
                                             :settings  =>{:list=>variety_types},
                                             :observer  =>non_supervisor_variety_type_observer}
    end

    field_configs[field_configs.length] = {:field_type=>'LabelField',
                                           :field_name=>'commodity_code',
                                           :settings  =>{:static_value=>session[:new_delivery].commodity_code, :show_label=>true}}

    field_configs[field_configs.length] = {:field_type=>'LabelField',
                                           :field_name=>'rmt_variety_code',
                                           :settings  =>{:static_value=>session[:new_delivery].rmt_variety_code, :show_label=>true}}

    field_configs[field_configs.length] = {:field_type=>'LabelField',
                                           :field_name=>'season_code',
                                           :settings  =>{:static_value=>session[:new_delivery].season_code, :show_label=>true}}

    field_configs[field_configs.length] = {:field_type=>'DropDownField',
                                           :field_name=>'track_slms_indicator_code',
                                           :settings  =>{:list=>track_slms_indicator_codes}}

    @drench_rmt                         =""
    @sample_rmt                         = ""
    @drench_rmt_checked                 = ""
    @drench_rmt_checked_value           = ""
    @sample_percentage_checked          = ""
    @sample_percentage_checked_value    = ""

    if @rmt_record!=nil
      if @rmt_record.drench_rmt==true
        @drench_rmt = "Yes"
      else
        @drench_rmt = "No"
      end

      if (@rmt_record.sample_percentage != nil && @rmt_record.sample_percentage!="" && @rmt_record.sample_percentage > 0)
        @sample_rmt = "Yes"
      else
        @sample_rmt = "No"
      end
    end

    if session[:rmt_variables]!=nil
      session[:rmt_variables] = nil
    end

    session[:rmt_variables]              = Hash.new
    session[:rmt_variables][:drench_rmt] = @drench_rmt
    session[:rmt_variables][:sample_rmt] = @sample_rmt

    field_configs[field_configs.length]  = {:field_type=>'LabelField',
                                            :field_name=>'rmt_drench?',
                                            :settings  =>{:css_class=>'delivery_label', :static_value=>@drench_rmt, :show_label=>true}}

    field_configs[field_configs.length]  = {:field_type=>'LabelField',
                                            :field_name=>'rmt_sample_bins?',
                                            :settings  =>{:css_class=>'delivery_label', :static_value=>@sample_rmt, :show_label=>true}}

    if (is_delivery_intake_supervisor && is_first_time)
#      delivery_track_indicator.track_variable_2 = true
      field_configs[field_configs.length] = {:field_type=>'CheckBox',
                                             :field_name=>'track_variable_1'}

      field_configs[field_configs.length] = {:field_type=>'CheckBox',
                                             :field_name=>'track_variable_2'}
    elsif (!is_delivery_intake_supervisor)
      field_configs[field_configs.length] = {:field_type=>'LabelField',
                                             :field_name=>'track_variable_1',
                                             :settings  =>{:css_class=>'uneditable_check_box_label', :static_value=>"<input id='delivery_track_indicator_track_variable_1' name='delivery_track_indicator[track_variable_1]' type='checkbox' disabled='disabled'/>
                                <input name='delivery_track_indicator[track_variable_1]' type='hidden' value='0' />", :show_label=>true}}

      field_configs[field_configs.length] = {:field_type=>'LabelField',
                                             :field_name=>'track_variable_2',
                                             :settings  =>{:css_class=>'uneditable_check_box_label', :static_value=>"<input id='delivery_track_indicator_track_variable_2' name='delivery_track_indicator[track_variable_2]' type='checkbox' disabled='disabled'/>
                                <input name='delivery_track_indicator[track_variable_2]' type='hidden' value='0' />", :show_label=>true}}
    end

    field_configs[field_configs.length] = {:field_type  =>'HiddenField',
                                           :field_name  =>'ajax_distributor',
                                           :non_db_field=>true}

    field_configs[field_configs.length] = {:field_type  =>'HiddenField',
                                           :field_name  =>'ajax_distributor2',
                                           :non_db_field=>true}


    build_form(delivery_track_indicator, field_configs, action, 'delivery_track_indicator', caption, is_edit)

  end


  def build_edit_delivery_track_indicator_form(delivery_track_indicator, action, caption, is_delivery_intake_supervisor, is_edit=nil)

    field_configs                         = Array.new

    field_configs[0]                      = {:field_type=>'LabelField',
                                             :field_name=>'track_indicator_type_code'}

    field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                             :field_name=>'commodity_code'}

    field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                             :field_name=>'rmt_variety_code'}

    field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                             :field_name=>'season_code'}

    field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                             :field_name=>'track_slms_indicator_code'}

    @rmt_variety                          = RmtVariety.find_by_sql("select * from rmt_varieties where rmt_variety_code = '#{delivery_track_indicator.rmt_variety_code}'")

    if @rmt_variety.length()!=0
      if (@rmt_variety[0].drench_rmt!=nil && @rmt_variety[0].drench_rmt!="" && @rmt_variety[0].drench_rmt==true)
        field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                                 :field_name=>'rmt_drench?',
                                                 :settings  =>{:static_value=>'Yes', :show_label=>true}}
      else
        field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                                 :field_name=>'rmt_drench?',
                                                 :settings  =>{:static_value=>'No', :show_label=>true}}
      end

      if (@rmt_variety[0].sample_percentage!=nil && @rmt_variety[0].sample_percentage!="" && (@rmt_variety[0].sample_percentage > 0))
        field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                                 :field_name=>'rmt_sample_bins?',
                                                 :settings  =>{:static_value=>'Yes', :show_label=>true}}
      else
        field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                                 :field_name=>'rmt_sample_bins?',
                                                 :settings  =>{:static_value=>'No', :show_label=>true}}
      end
    end

    track_slms = TrackSlmsIndicator.find_by_sql("select * from track_slms_indicators where track_slms_indicator_code = '#{delivery_track_indicator.track_slms_indicator_code}'")
    if is_delivery_intake_supervisor && track_slms.length()!=0
      @track_variable_1 = ""
      @track_variable_2 = ""
      if track_slms[0].track_variable_1 == true
        @track_variable_1 = "true"
      else
        @track_variable_1 = "false"
      end

      if track_slms[0].track_variable_2 == true
        @track_variable_2 = "true"
      else
        @track_variable_2 = "false"
      end

      session[:track_slms_indicator]= nil if session[:track_slms_indicator]!= nil
      session[:track_slms_indicator]                    = Hash.new
      session[:track_slms_indicator][:track_variable_1] = track_slms[0].track_variable_1
      session[:track_slms_indicator][:track_variable_2] = track_slms[0].track_variable_2

    end

    if (is_delivery_intake_supervisor)
      field_configs[field_configs.length()] = {:field_type=>'CheckBox',
                                               :field_name=>'track_variable_1'}

      field_configs[field_configs.length()] = {:field_type=>'CheckBox',
                                               :field_name=>'track_variable_2'}
    end

    build_form(delivery_track_indicator, field_configs, action, 'delivery_track_indicator', caption, is_edit)

  end

#===========================================================
#      end add track indicator to delivery code
#===========================================================


#===========================================================
#      mrl result form - [print mrl labels]
#===========================================================

  def build_mrl_result_form(mrl_result, action, caption, is_edit = nil, is_create_retry = nil)
    #	--------------------------------------------------------------------------------------------------
    #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #	in a composite foreign key
    #	--------------------------------------------------------------------------------------------------
    session[:mrl_result_form]= Hash.new

    mrl_result_types_codes   = MrlResultType.find_by_sql("select  * from mrl_result_types ").map { |mrl_result_type| [mrl_result_type.mrl_result_type_code] }
    mrl_result_types_codes.unshift("<empty>")

    mrl_result_codes = ["passed", "failed"]
    mrl_result_codes.unshift("<empty>")

    #	---------------------------------|
    #	Define fields to build form from |
    #	---------------------------------|


    field_configs                         = Array.new
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => "farm_code"}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => "puc_code",
                                             :settings   => {:label_caption => "puc"}}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => "sample_no"}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => "orchard_code"}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => "mrl_result_type_code"}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'mrl_result'}


#    if session[:new_delivery] == nil
#    	 field_configs[field_configs.length()] = {:field_type => 'TextField',
#    						                      :field_name => 'orchard_code'}
#    
#    
#    
#    	 field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
#    						                       :field_name => 'mrl_result_type_code',
#    						                       :settings => {:list => mrl_result_types_codes,:label_caption =>"mrl_result_type"}}
#     else
#          field_configs[field_configs.length()] = {:field_type => 'LabelField',
#                          						   :field_name => "orchard_code"}
#                          						 
#          field_configs[field_configs.length()] = {:field_type => 'LabelField',
#                          						   :field_name => "mrl_result_type_code"}
#     
#     end
#     if mrl_result.mrl_result == nil 
#         field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
#    						                       :field_name => 'mrl_result',
#    						                       :settings => {:list => mrl_result_codes}}
#    	else
#    	                      						 
#          field_configs[field_configs.length()] = {:field_type => 'LabelField',
#                          						   :field_name => "mrl_result"}
#    	end 					                       
#    if mrl_result.mrl_label_text  == nil
#    
#    end


    build_form(mrl_result, field_configs, action, 'mrl_result', caption, is_edit)

  end

#===========================================================
#      end mrl result form - [print mrl labels]
#===========================================================

  def build_delivery_search_form(delivery,action,caption)
    destination_complexes = Location.find(:all,:conditions=>"location_type_code='COMPLEX'").map{|l| l.location_code}

    field_configs = []
    field_configs << {:field_type => 'DropDownField',
                     :field_name => 'destination_complex',
                     :settings   =>{:list=>destination_complexes}}

    build_form(delivery, field_configs, action, 'delivery', caption)
  end

  def build_capture_summary_starch_results_form(starch_summary_results)
    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'TextField',:field_name => 'cat1_value',
                                            :settings=>{:label_caption=>Globals.starch_result_categories[:cat1_value]}}
    field_configs[field_configs.length()] = {:field_type => 'TextField',:field_name => 'cat2_value',
                                             :settings=>{:label_caption=>Globals.starch_result_categories[:cat2_value]}}
    field_configs[field_configs.length()] = {:field_type => 'TextField',:field_name => 'cat3_value',
                                             :settings=>{:label_caption=>Globals.starch_result_categories[:cat3_value]}}
    field_configs[field_configs.length()] = {:field_type => 'TextField',:field_name => 'cat4_value',
                                             :settings=>{:label_caption=>Globals.starch_result_categories[:cat4_value]}}
    field_configs[field_configs.length()] = {:field_type => 'TextField',:field_name => 'cat5_value',
                                             :settings=>{:label_caption=>Globals.starch_result_categories[:cat5_value]}}
    field_configs[field_configs.length()] = {:field_type => 'TextField',:field_name => 'cat6_value',
                                             :settings=>{:label_caption=>Globals.starch_result_categories[:cat6_value]}}
    field_configs[field_configs.length()] = {:field_type => 'TextField',:field_name => 'cat7_value',
                                             :settings=>{:label_caption=>Globals.starch_result_categories[:cat7_value]}}
    field_configs[field_configs.length()] = {:field_type => 'TextField',:field_name => 'cat8_value',
                                             :settings=>{:label_caption=>Globals.starch_result_categories[:cat8_value]}}
    field_configs[field_configs.length()] = {:field_type => 'TextField',:field_name => 'cat9_value',
                                             :settings=>{:label_caption=>Globals.starch_result_categories[:cat9_value]}}


    build_form(starch_summary_results, field_configs, 'capture_summary_starch_results_submit', 'starch_summary_results', 'capture', nil)

  end
end
