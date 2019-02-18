module RmtProcessing::ForecastHelper

#===========================
#   File Strucure Test   ===
#===========================

  def build_file_structure_form(tree, root_node_name)
    begin
      tree_builder = ReportTreeBuilder.new

      menu1 = ApplicationHelper::ContextMenu.new("leaf", "reports")
      menu1.add_command("view_report_parameter_form", url_for(:action => "build_happymores_form"))

      root_node = ApplicationHelper::TreeNode.new(root_node_name, "reports", true, "reports")

      tree_builder.display_tree(tree, root_node)

      tree = ApplicationHelper::TreeView.new(root_node, "reports")
      tree.add_context_menu(menu1)

      tree.render

    rescue
      raise "The report tree could not be rendered. Exception reported is \n" + $!
    end
  end

#=========================================

  def build_forecast_form(forecast, action, caption, is_edit = nil, is_create_retry = nil,is_view=nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:forecast_form]= Hash.new
    seasons = Season.find_by_sql('select distinct season from seasons').map { |g| [g.season] }
    farm_codes = Farm.find_by_sql('select distinct farm_code from farms').map { |g| [g.farm_code]}
    forecast_type_codes = ForecastType.find_by_sql('select distinct forecast_type_code from forecast_types').map { |g| [g.forecast_type_code] }
    pucs = ActiveRecord::Base.connection.select_all("select p.id ,p.puc_code
                                                     from pucs p").map{|x|[x['puc_code'],x['id']]}

    combos_js_for_farms = gen_combos_clear_js_for_combos(["forecast_farm_code", "forecast_puc_id"])
    farm_observer = {:updated_field_id => "puc_id_cell",
                    :remote_method => 'farm_changed',
                    :on_completed_js => combos_js_for_farms["forecast_farm_code"]
    }

# =======================
#   for new forecast record
#   =======================
#    if forecast == nil
#      forecast = Forecast.new
#      forecast.forecast_status_code = "new"
#      forecast.created_on = DateTime.now.to_formatted_s(:db)
#    end

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new

#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (forecast_type_id) on related table: forecast_types
#	-----------------------------------------------------------------------------------------------------
    if(is_edit)
      field_configs[field_configs.length] =  {:field_type => 'LabelField',
                                              :field_name => 'forecast_type_code',
                                              :settings => {:css_class => "dark_heading_field"}}
    else
      field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                              :field_name => 'forecast_type_code',
                                              :settings => {:list => forecast_type_codes}}
    end


    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'forecast_code',
                                           :settings => {:css_class => "dark_heading_field"}}

#	field_configs[field_configs.length] = {:field_type => 'LabelField',
#						:field_name => 'created_on'}
    if(!is_edit)
      field_configs[field_configs.length] = {:field_type => 'TextField',
                                           :field_name => 'forecast_description'}
      
      field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                              :field_name => 'farm_code',
                                              :settings => {:list => farm_codes},:observer => farm_observer}

      field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                              :field_name => 'puc_id',
                                              :settings => {:list => pucs,:column_caption => "puc"}}

      field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                              :field_name => 'season',
                                              :settings => {:list => seasons}}
      field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'delivery_date'}
    else
      if(forecast.forecast_status_code.to_s.upcase == "REVISED" || is_view)
        field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'forecast_description'}
      else
        field_configs[field_configs.length] = {:field_type => 'TextField',
                                           :field_name => 'forecast_description'}
      end
      field_configs[field_configs.length] =  {:field_type => 'LabelField',
                                              :field_name => 'farm_code'}

      field_configs[field_configs.length] =  {:field_type => 'LabelField',
                                              :field_name => 'puc_code'}

      field_configs[field_configs.length] =  {:field_type => 'LabelField',
                                              :field_name => 'season'}

      if(forecast.forecast_status_code.to_s.upcase == "REVISED" || is_view)
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'delivery_date'}
      else
        field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'delivery_date'}
      end
    end

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'forecast_status_code',
                                           :settings => {:css_class => "dark_heading_field"}}
    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                      :field_name => 'sequence_number',
                                      :settings => {:css_class => "dark_heading_field"}}

    if(is_edit)
      field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'forecast_report',
                         :settings =>
                        {
                         :host_and_port =>request.host_with_port.to_s,
                         :controller =>request.path_parameters['controller'].to_s ,
                         :target_action => 'print_forecast_report',
                         :image => '/images/view.png'}}
    end
    
    build_form(forecast, field_configs, action, 'forecast', caption, is_edit)

  end


  def build_forecast_search_form(forecast, action, caption, is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:forecast_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["forecast_season", "forecast_farm_code", "forecast_forecast_code", "forecast_forecast_status_code"])
    #Observers for search combos
    season_observer  = {:updated_field_id => "farm_code_cell",
                             :remote_method => 'forecast_season_search_combo_changed',
                             :on_completed_js => search_combos_js["forecast_season"]}

    session[:forecast_search_form][:season_observer] = season_observer

    farm_code_observer  = {:updated_field_id => "forecast_code_cell",
                           :remote_method => 'forecast_farm_code_search_combo_changed',
                           :on_completed_js => search_combos_js["forecast_farm_code"]}

    session[:forecast_search_form][:farm_code_observer] = farm_code_observer

    forecast_code_observer  = {:updated_field_id => "forecast_status_code_cell",
                               :remote_method => 'forecast_forecast_code_search_combo_changed',
                               :on_completed_js => search_combos_js["forecast_forecast_code"]}

    session[:forecast_search_form][:forecast_code_observer] = forecast_code_observer


    seasons = Forecast.find_by_sql('select distinct season from forecasts').map { |g| [g.season] }
    seasons.unshift("<empty>")
    if is_flat_search
      farm_codes = Forecast.find_by_sql('select distinct farm_code from forecasts').map { |g| [g.farm_code] }
      farm_codes.unshift("<empty>")
      forecast_codes = Forecast.find_by_sql('select distinct forecast_code from forecasts').map { |g| [g.forecast_code] }
      forecast_codes.unshift("<empty>")
      forecast_status_codes = Forecast.find_by_sql('select distinct forecast_status_code from forecasts').map { |g| [g.forecast_status_code] }
      forecast_status_codes.unshift("<empty>")
      season_observer = nil
      farm_code_observer = nil
      forecast_code_observer = nil
    else
      farm_codes = ["Select a value from season"]
      forecast_codes = ["Select a value from farm_code"]
      forecast_status_codes = ["Select a value from forecast_code"]
    end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'season',
                         :settings => {:list => seasons},
                         :observer => season_observer}

    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'farm_code',
                         :settings => {:list => farm_codes},
                         :observer => farm_code_observer}

    field_configs[2] =  {:field_type => 'DropDownField',
                         :field_name => 'forecast_code',
                         :settings => {:list => forecast_codes},
                         :observer => forecast_code_observer}

    field_configs[3] =  {:field_type => 'DropDownField',
                         :field_name => 'forecast_status_code',
                         :settings => {:list => forecast_status_codes}}

    build_form(forecast, field_configs, action, 'forecast', caption, false)

  end


  def build_forecast_grid(data_set, can_edit, can_delete)

    require "app/helpers/rmt_processing/forecast_plugins.rb"

    column_configs = Array.new
    #	----------------------
    #	define action columns
    #	----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit', :col_width => 35,
                                                 :settings =>
                                                         {:image => 'edit',
                                                          :target_action => 'edit_forecast',
                                                          :id_column => 'id'}}
     #NAE - remove revised hyperlink as not being used and according to ABK
     # column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'revise', :col_width => 35,
     #                                          :settings =>
     #                                                  {:image => 'revise',
     #                                                   :target_action => 'revise_forecast',
     #                                                   :id_column => 'id'}}
    
      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'clone', :col_width => 35,
                                               :settings =>
                                                       {:image => 'clone',
                                                        :target_action => 'clone_forecast',
                                                        :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete', :col_width => 35,
                                                 :settings =>
                                                         {:image => 'delete',
                                                          :target_action => 'delete_forecast',
                                                          :id_column => 'id'}}
    end

    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'view', :col_width => 35,
                                               :settings =>
                                                       {:image => 'view',
                                                        :target_action => 'view_forecast',
                                                        :id_column => 'id'}}
    
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'season', :col_width => 36}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code', :col_width => 45}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'forecast_status_code', :column_caption=>'status', :col_width => 47}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'forecast_code', :col_width => 154}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_on', :col_width => 117}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'forecast_description', :col_width => 117}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'delivery_date', :col_width => 117}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'forecast_type_code', :col_width => 70}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'sequence_number', :col_width => 35}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id', :col_width => 35}

    return get_data_grid(data_set, column_configs,nil,true)
  end

  def build_list_forecast_headers_grid(data_set, can_edit, can_delete)

  require "app/helpers/rmt_processing/forecast_plugins.rb"
 
    column_configs = Array.new
    if (can_edit)
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit', :col_width => 35,
                                                 :settings =>
                                                         {:image => 'edit',
                                                          :target_action => 'edit_forecast',
                                                          :id_column => 'id'}}
    end

    if (can_delete)
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete', :col_width => 35,
                                                 :settings =>
                                                         {:image => 'delete',
                                                          :target_action => 'delete_forecast',
                                                          :id_column => 'id'}}
    end

    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'view', :col_width => 35,
                                               :settings =>
                                                       {:image => 'view',
                                                        :target_action => 'view_forecast',
                                                        :id_column => 'id'}}
     #NAE - remove revised hyperlink as not being used and according to ABK
    #column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'revise', :col_width => 35,
    #                                           :settings =>
    #                                                   {:image => 'revise',
    #                                                    :target_action => 'revise_forecast',
    #                                                    :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'clone', :col_width => 35,
                                               :settings =>
                                                       {:image => 'clone',
                                                        :target_action => 'clone_forecast',
                                                        :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'season', :col_width => 36}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code', :col_width => 45}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'forecast_status_code', :column_caption=>'status', :col_width => 47}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'forecast_code', :col_width => 154}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_on', :col_width => 117}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'forecast_description', :col_width => 117}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'delivery_date', :col_width => 117}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'forecast_type_code', :col_width => 70}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'sequence_number', :col_width => 35}

    return get_data_grid(data_set, column_configs,nil,true)
  end

  def build_track_indicator_form(forecasts_track_slms_indicator, action, caption)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:forecasts_track_slms_indicator_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["forecasts_track_slms_indicator_commodity_code", "forecasts_track_slms_indicator_variety_code", "forecasts_track_slms_indicator_track_slms_indicator_code"])
    #Observers for search combos
    commodity_code_observer  = {:updated_field_id => "rmt_variety_code_cell",
                                :remote_method => 'forecasts_track_slms_indicator_commodity_code_search_combo_changed',
                                :on_completed_js => search_combos_js["forecasts_track_slms_indicator_commodity_code"]}

    session[:forecasts_track_slms_indicator_search_form][:commodity_code_observer] = commodity_code_observer

    variety_code_observer  = {:updated_field_id => "track_slms_indicator_code_cell",
                              :remote_method => 'forecasts_track_slms_indicator_variety_code_search_combo_changed',
                              :on_completed_js => search_combos_js["forecasts_track_slms_indicator_variety_code"]}

    session[:forecasts_track_slms_indicator_search_form][:variety_code_observer] = variety_code_observer

    #if forecasts_track_slms_indicator == nil
    commodity_codes = TrackSlmsIndicator.find_by_sql("select distinct commodity_code from track_slms_indicators where variety_type = 'rmt_variety'").map { |g| [g.commodity_code] }
    commodity_codes.unshift("<empty>")

    variety_codes = ["Select a value from commodity_code"]
#   else
#     commodity_code = forecasts_track_slms_indicator.forecast_variety_indicator.forecast_variety.commodity_code
#     variety_codes = TrackSlmsIndicator.find_by_sql("Select distinct variety_code from track_slms_indicators where commodity_code = '#{commodity_code}' and variety_type = 'rmt_variety'").map{|g|[g.variety_code]}
#	 variety_codes.unshift("<empty>")
#   end
    track_slms_indicator_codes = ["Select a value from variety_code"]

#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------

#  if forecasts_track_slms_indicator == nil
    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'commodity_code',
                                            :settings => {:list => commodity_codes},
                                            :observer => commodity_code_observer}
#  else
#    field_configs[field_configs.length] = {:field_type => 'LabelField',
#	                    :field_name => 'commodity_code',
#						:non_db_field => true,
#						:settings =>{:static_value => commodity_code,:show_label => true}}
#  end

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'rmt_variety_code',
                                            :settings => {:list => variety_codes},
                                            :observer => variety_code_observer}

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'track_slms_indicator_code',
                                            :settings => {:list => track_slms_indicator_codes}}
#   ----------------------------------------------------------------------------------

    build_form(forecasts_track_slms_indicator, field_configs, action, 'forecasts_track_slms_indicator', caption)
  end


  def build_forecast_variety_indicator_track_indicator_form(forecasts_variety_indicators_track_slms_indicator, action, caption)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:forecasts_variety_indicators_track_slms_indicator_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    #search_combos_js = gen_combos_clear_js_for_combos(["forecasts_variety_indicators_track_slms_indicator_commodity_code","forecasts_variety_indicators_track_slms_indicator_variety_code","forecasts_variety_indicators_track_slms_indicator_track_slms_indicator_code"])
    on_complete_js = "\n img = document.getElementById('img_forecasts_variety_indicators_track_slms_indicator_rmt_variety_code');"
    on_complete_js += "\n if(img != null)img.style.display = 'none';"

    #Observers for search combos

    variety_code_observer  = {:updated_field_id => "track_slms_indicator_code_cell",
                              :remote_method => 'forecasts_variety_indicators_track_slms_indicator_variety_code_search_combo_changed',
                              :on_completed_js => on_complete_js}
    #:on_completed_js => search_combos_js["forecasts_variety_indicators_track_slms_indicator_variety_code"]}

    session[:forecasts_variety_indicators_track_slms_indicator_search_form][:variety_code_observer] = variety_code_observer

    commodity_code = @commodity_code
    variety_codes = TrackSlmsIndicator.find_by_sql("Select distinct variety_code from track_slms_indicators where commodity_code = '#{commodity_code}' and variety_type = 'rmt_variety'").map { |g| [g.variety_code] }
    variety_codes.unshift("<empty>")

    track_slms_indicator_codes = ["Select a value from variety_code"]

#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'commodity_code',
                                           :settings =>{:static_value => commodity_code, :show_label => true}}


    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'rmt_variety_code',
                                            :settings => {:list => variety_codes},
                                            :observer => variety_code_observer}

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'track_slms_indicator_code',
                                            :settings => {:list => track_slms_indicator_codes}}
#   ----------------------------------------------------------------------------------

    build_form(forecasts_variety_indicators_track_slms_indicator, field_configs, action, 'forecasts_variety_indicators_track_slms_indicator', caption)
  end


  def build_forecast_variety_form(forecast_variety, action, caption)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:forecast_variety_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["forecast_variety_commodity_code", "forecast_variety_rmt_variety_code"])
    #Observers for search combos
    commodity_code_observer  = {:updated_field_id => "rmt_variety_code_cell",
                                :remote_method => 'forecast_variety_commodity_code_combo_changed',
                                :on_completed_js => search_combos_js["forecast_variety_commodity_code"]}

    session[:forecast_variety_form][:commodity_code_observer] = commodity_code_observer


    commodity_codes = RmtVariety.find_by_sql("select distinct commodity_code from rmt_varieties").map { |h| [h.commodity_code] }
    commodity_codes.unshift("<empty>")
    #rmt_variety_codes = ["Select a value from commodity_code"]
    farm_id = Forecast.find(session[:forecast_id]).farm_id


    forecast_type_code = @forecast.forecast_type_code
    if forecast_variety == nil
      rmt_variety_codes = ["Select a value from commodity_code"]
      forecast_variety = ForecastVariety.new
      forecast_variety.status_code = "unbalanced"
    else
      commodity_code = forecast_variety.commodity_code
      rmt_variety_codes = RmtVariety.find_by_sql("Select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}'").map { |g| [g.rmt_variety_code] }
      rmt_variety_codes.unshift("<empty>")
    end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'forecast_type_code',
                                           :non_db_field => true,
                                           :settings =>{:static_value => forecast_type_code, :show_label => true}}
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'commodity_code',
                                            :settings => {:list => commodity_codes},
                                            :observer => commodity_code_observer}

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'rmt_variety_code',
                                            :settings => {:list => rmt_variety_codes}}

    field_configs[field_configs.length] =  {:field_type => 'TextField',
                                            :field_name => 'orchard_code'}

    field_configs[field_configs.length] =  {:field_type => 'PopupDateSelector',
                                            :field_name => 'delivery_date_estimate'}

    field_configs[field_configs.length] =  {:field_type => 'TextField',
                                            :field_name => 'uom'}

    field_configs[field_configs.length] =  {:field_type => 'TextField',
                                            :field_name => 'quantity'}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'status_code'}

    build_form(forecast_variety, field_configs, action, 'forecast_variety', caption)
  end

  def build_forecast_variety_indicator_form(forecast_variety_indicator, action, caption)

    forecast_type_code = @forecast_variety.forecast.forecast_type_code
    commodity_code = @forecast_variety.commodity_code
    rmt_variety_code = @forecast_variety.rmt_variety_code

    track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql("select track_slms_indicator_code from track_slms_indicators where variety_type = 'rmt_variety' and  variety_code = '#{rmt_variety_code}'").map { |t| [t.track_slms_indicator_code] }
    track_slms_indicator_codes.unshift("<empty>")

#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'forecast_type_code',
                                           :non_db_field => true,
                                           :settings =>{:static_value => forecast_type_code, :show_label => true}}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'commodity_code',
                                           :non_db_field => true,
                                           :settings =>{:static_value => commodity_code, :show_label => true}}

    field_configs[field_configs.length] = {:field_type => 'LabelField',
                                           :field_name => 'rmt_variety_code',
                                           :non_db_field => true,
                                           :settings =>{:static_value => rmt_variety_code, :show_label => true}}

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                            :field_name => 'track_slms_indicator_code',
                                            :settings => {:list => track_slms_indicator_codes}}

    field_configs[field_configs.length] =  {:field_type => 'TextField',
                                            :field_name => 'quantity'}

    build_form(forecast_variety_indicator, field_configs, action, 'forecast_variety_indicator', caption)
  end

  def build_clone_forecast_form(forecast,action,caption)
  #	--------------------------------------------------------------------------------------------------
  #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
  #	in a composite foreign key
  #	--------------------------------------------------------------------------------------------------
    session[:forecast_form]= Hash.new
    seasons = Season.find_by_sql('select distinct season from seasons').map { |g| [g.season] }
    forecast_type_codes = ForecastType.find_by_sql('select distinct forecast_type_code from forecast_types').map { |g| [g.forecast_type_code] }

  #	---------------------------------
  #	 Define fields to build form from
  #	---------------------------------
    field_configs = Array.new

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                              :field_name => 'forecast_type_code',
                                              :settings => {:list => forecast_type_codes}}

    field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                              :field_name => 'season',
                                              :settings => {:list => seasons}}

    build_form(forecast, field_configs, action, 'forecast', caption, nil)
  end

  def build_print_screen_form(hash_object)
    printers = Globals.bin_ticket_printer_names
    field_configs = []
    field_configs << {:field_type => 'TextField',
                      :field_name => 'qty'}
    field_configs <<  {:field_type => 'DropDownField',
                                            :field_name => 'printer',
                                            :settings => {:list => printers}}
    field_configs << {:field_type=>'HiddenField', :field_name=>'id'}

    build_form(hash_object,field_configs,'print_bin_tickets_commit','hash_object','print',nil)
  end
end
