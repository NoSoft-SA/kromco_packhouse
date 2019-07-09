module RmtProcessing::GrowerGradingHelper

  def build_production_run_search_form(production_run,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    session[:pool_graded_summary_search_form]= Hash.new
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = []

    field_configs << {:field_type => 'TextField',
      :field_name => 'production_run_code',
      :settings => {:label_caption => 'Production run code like'}}
    build_form(production_run,field_configs,action,'production_run',caption,false)

  end



  def build_production_run_grid(data_set,can_edit,can_delete)

    column_configs = []
    column_configs << {:field_type => 'text',:field_name => 'production_schedule_name',:col_width=>200}
    column_configs << {:field_type => 'text',:field_name => 'production_run_code',:col_width=>150}
#    column_configs << {:field_type => 'text',:field_name => 'farm_code'}
#    column_configs << {:field_type => 'text',:field_name => 'track_slms_indicator_code'}
    column_configs << {:field_type => 'text',:field_name => 'season_code'}
    column_configs << {:field_type => 'text',:field_name => 'bin_count'}
    column_configs << {:field_type => 'text',:field_name => 'bin_mass'}
    column_configs << {:field_type => 'text',:field_name => 'status'}
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'grower grading',
        :settings =>
      {:link_text => 'create',
        :target_action => 'create_pool_graded_summary',
        :id_column => 'production_run_code',
        :null_test => "['status'] != nil"}}
    end

    get_data_grid(data_set,column_configs, nil, true)
  end

  def build_pool_graded_summary_search_form(pool_graded_summary,action,caption,is_flat_search = nil)
    session[:pool_graded_summary_search_form]= Hash.new

    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    search_combos_js_for_reports = gen_combos_clear_js_for_combos(["pool_graded_summary_season_code","pool_graded_summary_production_schedule_name"])
    season_observer  = {:updated_field_id => "production_schedule_name_cell",
                        :remote_method    => 'season_search_combo_changed',
                        :on_completed_js  => search_combos_js_for_reports["pool_graded_summary_season_code"]}

    session[:pool_graded_summary_search_form][:season_observer] = season_observer

    on_complete_js = "\n img = document.getElementById('img_pool_graded_summary_production_schedule_name');"
    on_complete_js += "\n if(img != null) img.style.display = 'none';"
    production_schedule_name_observer  = {:updated_field_id => "production_run_code_cell",
                                          :remote_method    => 'production_schedule_name_search_combo_changed',
                                          :on_completed_js  => on_complete_js}

    session[:pool_graded_summary_search_form][:production_schedule_name_observer] = production_schedule_name_observer

    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = []

    seasons = PoolGradedSummary.find(:all,
                                     :select => 'DISTINCT season_code',
                                     :order => 'season_code DESC').
                                     map {|r| r.season_code}.
                                     reject {|r| r.blank? || r == "" }
    seasons.unshift '<empty'

    production_schedule_names = ["Select a value from season"]
    production_run_codes = ["Select a value from production schedule name"]

    statuses = ["<empty>", PoolGradedSummary::STATUS_IN_PROGRESS, PoolGradedSummary::STATUS_GRADED, PoolGradedSummary::STATUS_COMPLETE]

    field_configs << {:field_type => 'DropDownField',
      :field_name => 'season_code',
      :settings => {:list => seasons},
                    :observer => season_observer}

    field_configs << {:field_type => 'DropDownField',
      :field_name => 'production_schedule_name',
      :settings => {:list => production_schedule_names},
                    :observer => production_schedule_name_observer}

    field_configs << {:field_type => 'DropDownField',
      :field_name => 'production_run_code',
      :settings => {:list => production_run_codes}}

    field_configs << {:field_type => 'DropDownField',
      :field_name => 'status',
      :settings => {:list => statuses}}

    build_form(pool_graded_summary,field_configs,action,'pool_graded_summary',caption,false)

  end

  def build_pool_graded_summary_grid(data_set,can_edit,can_delete)

    column_configs = []
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit',  :col_width=>55,
        :settings =>
      {:link_text => 'edit',
        :target_action => 'edit_pool_graded_summary',
        :id_column => 'id'}}
    end
    column_configs << {:field_type => 'text',:field_name => 'production_schedule_name',:col_width=>200}
    column_configs << {:field_type => 'text',:field_name => 'production_run_code',:col_width=>150}
    # column_configs << {:field_type => 'text',:field_name => 'farm_code'}
    # column_configs << {:field_type => 'text',:field_name => 'track_slms_indicator_code'}
    column_configs << {:field_type => 'text',:field_name => 'season_code'}
    column_configs << {:field_type => 'text',:field_name => 'status'}
    column_configs << {:field_type => 'text',:field_name => 'bin_count',:col_width=>100}
    column_configs << {:field_type => 'text',:field_name => 'bin_mass'}
    column_configs << {:field_type => 'text',:field_name => 'created_at'}

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete', :col_width=>55,
        :settings =>
      {:link_text => 'delete',
        :target_action => 'delete_pool_graded_summary',
        :id_column => 'id',
        :null_test => "status == '#{PoolGradedSummary::STATUS_COMPLETE}'"}}
    end
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'uncomplete pool_graded_summary', :col_width=>100,
        :settings =>
      {:link_text => 'uncomplete',
        :target_action => 'uncomplete_pool_graded_summary',
        :id_column => 'id',
        :null_test => "status != '#{PoolGradedSummary::STATUS_COMPLETE}'"}}
    end

    get_data_grid(data_set,column_configs)
  end

  def build_pool_graded_summary_form(pool_graded_summary,action,caption,is_edit = nil,is_create_retry = nil)

    session[:pool_graded_summary_form]= Hash.new
    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = []

    field_configs << {:field_type => 'LabelField',
      :field_name => 'production_schedule_name',
        :settings => {:show_label   => true}}

    field_configs << {:field_type => 'LabelField',
      :field_name => 'production_run_code',
        :settings => {:show_label   => true}}

    # field_configs << {:field_type => 'LabelField',
    #   :field_name => 'farm_code',
    #     :settings => {:show_label   => true}}

    # field_configs << {:field_type => 'LabelField',
    #   :field_name => 'track_slms_indicator_code',
    #     :settings => {:show_label   => true}}

    field_configs << {:field_type => 'LabelField',
      :field_name => 'season_code',
        :settings => {:show_label   => true}}

    field_configs << {:field_type => 'LabelField',
      :field_name => 'status',
        :settings => {:show_label   => true}}

    field_configs << {:field_type => 'LabelField',
      :field_name => 'bin_count',
        :settings => {:show_label   => true}}

    field_configs << {:field_type => 'LabelField',
      :field_name => 'bin_mass',
        :settings => {:show_label   => true}}

    # field_configs << {:field_type => 'LabelField',
    #   :field_name => 'created_at',
    #     :settings => {:show_label   => true}}

    field_configs << {:field_type    => 'LinkWindowField',
                      :field_name => '',
                      :settings => {:target_action => 'get_matched_cartons',
                                    :link_text     => "Apply Cartons Grading Rules",
                                    :id_value      => pool_graded_summary.id.to_s }}

    field_configs << {:field_type    => 'LinkWindowField',
                      :field_name => '',
                      :settings => {:target_action => 'apply_bin_grading_rules',
                                    :link_text     => "Apply Rebins Grading Rules",
                                    :id_value      => pool_graded_summary.id.to_s }}

    field_configs << {:field_type    => 'LinkWindowField',
      :field_name => '',
        :settings => {:target_action => 'summarise_cartons',
                      :window_height => 1000,
                      :window_width => 1800,
                      :link_text     => "Summarise Cartons",
                      :id_value      => pool_graded_summary.id.to_s }}

    field_configs << {:field_type    => 'LinkWindowField',
                      :field_name => '',
                      :settings => {:target_action => 'summarise_rebins',
                                    :link_text     => "Summarise Rebins",
                                    :window_width => 1500,
                                    :window_height => 500,
                                    :id_value      => pool_graded_summary.id.to_s }}

    field_configs << {:field_type    => 'LinkField',
      :field_name => '',
        :settings => {:target_action => 'complete_grading',
                      :link_text     => "Complete Grading",
                      :id_value      => pool_graded_summary.id.to_s }}

    field_configs << {:field_type    => 'LinkWindowField',
                      :field_name => '',
                      :settings => {:target_action => 'preview_grading',
                                    :link_text     => "Preview Grading",
                                    :id_value      => pool_graded_summary.id.to_s }}




    if PoolGradedSummary::STATUS_COMPLETE == pool_graded_summary.status
      field_configs << {:field_type    => 'LinkWindowField',
        :field_name => '',
          :settings => {:target_action => 'report_grading',
                        :link_text     => "Generate Report",
                        :id_value      => pool_graded_summary.id.to_s }}
    end
      field_configs << {:field_type => 'LabelField',
        :field_name => 'um',
        :settings => {:static_value => '</table><table>', :non_dbfield => true, :show_label => false, :css_class => 'unbordered_label_field'}}

    # Show farms:   list_pool_graded_farms
      field_configs << {:field_type => 'Screen',
                        :field_name => "child_form1", #2",
                        :settings   => {:target_action => 'list_pool_graded_farms',
                                        :id_value      => pool_graded_summary.id.to_s,
                                        :width         => 700,
                                        :height        => 160,
                                        :no_scroll     => true}
                                              }

    set_form_layout '2', false, 1, 11

    set_submit_button_align('left')

    build_form(pool_graded_summary,field_configs,action,'pool_graded_summary',caption,is_edit)

  end

  def build_pool_graded_farm_grid(data_set,can_edit,can_delete)

    column_configs = []
    column_configs << {:field_type => 'text',:field_name => 'farm_code'}
    column_configs << {:field_type => 'text',:field_name => 'track_slms_indicator_code' ,:col_width=>170}
    column_configs << {:field_type => 'text',:field_name => 'bin_count',:col_width=>120}
    column_configs << {:field_type => 'text',:field_name => 'bin_mass',:col_width=>120}

    set_grid_min_height(80)
    set_grid_min_width(300)
    hide_grid_client_controls

    return get_data_grid(data_set,column_configs)
  end

end
