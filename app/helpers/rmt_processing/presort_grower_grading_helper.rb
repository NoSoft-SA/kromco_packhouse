module RmtProcessing::PresortGrowerGradingHelper

  def build_new_pool_graded_ps_bin_line_form(pool_graded_ps_bin,action,caption,is_edit = nil,is_create_retry = nil)

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    classes = ProductClass.find_by_sql("select product_class_code from product_classes order by product_class_code ").map{|p|p.product_class_code}
    colours = Treatment.find_by_sql("select treatment_code from treatments where treatment_type_code = 'PRESORT' order by treatment_code ").map{|p|p.treatment_code}
    counts = Size.find_by_sql("select size_code from sizes where commodity_code = 'AP' order by size_code").map{|p|p.size_code}

    field_configs = []
    field_configs << {:field_type => 'DropDownField',:field_name => 'maf_class?required', :settings => {:list =>classes}}
    field_configs << {:field_type => 'DropDownField',:field_name => 'maf_colour?required', :settings => {:list => colours}}
    field_configs << {:field_type => 'DropDownField',:field_name => 'maf_count?required', :settings => {:list =>counts}}
    field_configs << {:field_type => 'DropDownField',:field_name => 'maf_article_count?required', :settings => {:list =>counts}}
    field_configs << {:field_type => 'TextField',:field_name => 'maf_weight?required'}

   build_form(pool_graded_ps_bin,field_configs,action,'ps_bin',caption,is_edit)

  end

  def build_maf_ps_bins_grid(data_set)
    if session[:warning]
      flash[:error]=session[:warning]
    end
    column_configs=[]
    column_configs << {:field_type => 'text',:field_name => 'maf_farm_code',:col_width=>150}
    column_configs << {:field_type => 'text',:field_name => 'maf_rmt_code',:col_width=>150}
    column_configs << {:field_type => 'text',:field_name => 'maf_article'}
    column_configs << {:field_type => 'text',:field_name => 'maf_class'}
    column_configs << {:field_type => 'text',:field_name => 'maf_colour'}
    column_configs << {:field_type => 'text',:field_name => 'maf_article_count',:col_width=>150}
    column_configs << {:field_type => 'text',:field_name => 'maf_count',:col_width=>150}
    column_configs << {:field_type => 'text',:field_name => 'maf_weight',:col_width=>150}
    return get_data_grid(data_set,column_configs)
  end

  def build_maf_extracted_bins_form(pool_graded_ps_summary,action,caption,is_edit)
    field_configs=[]
    field_configs << {:field_type => 'TextField',:field_name => 'maf_lot_number'}
    field_configs << {:field_type => 'TextField',:field_name => 'maf_tipped_lot_qty',:settings=>{:readonly => true}}
    field_configs << {:field_type => 'TextField',:field_name => 'maf_total_lot_weight',:settings=>{:readonly => true}}
    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name =>"child_form2",
                                             :settings   =>{
                                                 :controller    =>"rmt_processing/presort_grower_grading",
                                                 :target_action => 'list_maf_ps_bins',
                                                 :width         => 1200, :height =>800,
                                                 :id_value      => ""}}
    @submit_button_align = "left"
    set_form_layout "3", nil,1,3
    #action=nil if is_edit
    build_form(pool_graded_ps_summary,field_configs,action,'pool_graded_ps_summary',caption)
  end

  def build_pool_graded_summary_grid(data_set,can_edit,can_delete)

    column_configs = []
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit',
                         :settings =>
                             {:link_text => 'edit',
                              :target_action => 'edit_pool_graded_ps_summary',
                              :id_column => 'id'}}
    end
    column_configs << {:field_type => 'text',:field_name =>'maf_lot_number',:col_width=>150}
    column_configs << {:field_type => 'text',:field_name => 'season_code'}
    column_configs << {:field_type => 'text',:field_name => 'status'}
    column_configs << {:field_type => 'text',:field_name => 'rmt_bin_count',:column_caption=> "bin_count",:col_width=>100}
    column_configs << {:field_type => 'text',:field_name => 'rmt_bin_weight',:column_caption=> "bin_weight",:col_width=>150}
    column_configs << {:field_type => 'text',:field_name => 'created_at'}
    column_configs << {:field_type => 'text',:field_name => 'id'}
    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete',
                         :settings =>
                             {:link_text => '',
                              :target_action => '',
                              :id_column => 'id'}}
    end
    if can_edit
      #column_configs << {:field_type => 'action',:field_name => 'uncomplete',:col_width=>150 ,
      #                   :settings =>
      #                       {:link_text => 'uncomplete',
      #                        :target_action => 'uncomplete_pool_graded_summary',
      #                        :id_column => 'id'}}
    end
    return get_data_grid(data_set,column_configs,MesScada::GridPlugins::RmtProcessing::PresortGrowerGradingSummaryPlugin.new(self,request) ) #
  end


  def build_pool_graded_ps_summary_search_form(pool_graded_summary,action,caption,is_flat_search = nil)
    session[:pool_graded_summary_search_form]= Hash.new


    field_configs = []

    seasons = Season.find(:all,
                                     :select => 'DISTINCT season_code',
                                     :order => 'season_code ASC').
        map {|r| r.season_code}.
        reject {|r| r.blank? || r == "" }
    seasons.unshift '<empty'


    statuses = ["<empty>", "STATUS_IN_PROGRESS", "GRADED", "UNGRADED"]

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'season_code',
                      :settings => {:list => seasons},
                      }

    field_configs << {:field_type => 'TextField',
                      :field_name => 'maf_lot_number',
                      :settings => {:label_caption=> "lot_number"}}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'status',
                      :settings => {:list => statuses}}

    build_form(pool_graded_summary,field_configs,action,'pool_graded_summary',caption,false)

  end

  def build_find_ps_lot_number_form (ps_lot,action,caption,is_flat_search = nil)


   field_configs = []

    field_configs << {:field_type => 'TextField',
                      :field_name => 'ps_lot_number'}


    build_form(nil,field_configs,action,'ps_lot',caption,false)
  end

  def  build_create_presort_grading_form(presort_grower_grading,action,caption,is_edit = nil)
    id_value = presort_grower_grading.id if is_edit
    field_configs = []
    field_configs << {:field_type => 'LabelField', :field_name => 'season_code'}
    field_configs << {:field_type => 'LabelField', :field_name => 'maf_lot_number'}
    field_configs << {:field_type => 'LabelField', :field_name => 'rmt_bin_count',:settings=>{:label_caption=>"bin_count"}}
    field_configs << {:field_type => 'LabelField', :field_name => 'status'}
    field_configs << {:field_type => 'LabelField', :field_name => 'rmt_bin_weight',:settings=>{:label_caption=>"bin_mass"}}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'du', :non_db_field => true, :settings => {:is_separator => false, :static_value => '', :css_class => "borderless_label_field"}}

    if is_edit
    field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',:field_name => '',
                                             :settings   => {:host_and_port =>request.host_with_port.to_s,:target_action => 'import_maf_ps_lot',:link_text     => 'import_maf_ps_lot',
                                             :window_width =>1200,:window_height =>1200, :id_value      => presort_grower_grading.id  } }

    if presort_grower_grading.status=="GRADED"
      field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'du', :non_db_field => true, :settings => {:is_separator => false, :static_value => '', :css_class => "borderless_label_field"}}

    else
      field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => '',
                                               :settings   => {:host_and_port =>request.host_with_port.to_s,:target_action => 'complete_grading',:link_text     => 'complete_grading',
                                                               :id_value      => presort_grower_grading.id   } }
    end

      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',:field_name => '',
                                             :settings   => {:host_and_port =>request.host_with_port.to_s,:target_action => 'crud_ps_bins',:link_text     => 'crud ps bins',
                                                             :id_value      => presort_grower_grading.id  , :window_width =>1500,:window_height =>1200 }}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'du', :non_db_field => true, :settings => {:is_separator => false, :static_value => '', :css_class => "borderless_label_field"}}

      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',:field_name => '',
                                             :settings   => {:host_and_port =>request.host_with_port.to_s,:target_action => 'preview_ps_grades',:link_text     => 'preview_ps_grades',
                                                             :id_value      => presort_grower_grading.id   } }
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'du', :non_db_field => true, :settings => {:is_separator => false, :static_value => '', :css_class => "borderless_label_field"}}

    end
    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name =>"child_form1",
                                             :settings   =>{
                                                 :controller    =>"rmt_processing/presort_grower_grading_farm",
                                                 :target_action => 'list_presort_grower_grading_farms',
                                                 :width         => 1000, :height =>300,
                                                 :id_value      => id_value,
                                                 :no_scroll     => true}}


    @submit_button_align = "left"
    if is_edit
      set_form_layout "2", nil,1,12
    else
      set_form_layout "2", nil,0,6
    end

    action = nil if is_edit
    build_form(presort_grower_grading,field_configs,action,'presort_grower_grading',caption,is_edit)
  end
end