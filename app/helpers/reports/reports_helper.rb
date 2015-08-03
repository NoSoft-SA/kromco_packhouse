
module Reports::ReportsHelper

  #@host_and_port = "http://" + request.host_with_port + "/"

  def build_file_structure_form(tree,root_node_name)
   begin
      tree_builder = ReportTreeBuilder.new

      menu1 = ApplicationHelper::ContextMenu.new("leaf","reports")
      menu1.add_command("view_report_parameter_form",url_for(:action => "build_happymores_form"))

      root_node = ApplicationHelper::TreeNode.new(root_node_name,"reports",true,"reports")

      tree_builder.display_tree(tree,root_node)

      tree = ApplicationHelper::TreeView.new(root_node,"reports")
      tree.add_context_menu(menu1)

      tree.render

       rescue
        raise "The report tree could not be rendered. Exception reported is \n" + $!
      end
  end

  def build_generic_show_records_grid(recordset)
    column_configs = []
    keys           = recordset[0].keys

    keys.each do |key|
      column_configs << {:field_type => 'text',
                         :field_name => key.to_s }
    end

    if keys.include?( 'id') && recordset[0]['id'].is_numeric? && !recordset[0]['id'].include?('_')
      column_configs << {:field_type   => 'action',
                         :field_name   => 'view_details',
                         :column_width => 120,
                         :settings     => {:link_text     => 'view details',
                                           :target_action => 'view_details',
                                           :id_column     => 'id' }
                        }
    end

    get_data_grid(recordset, column_configs, nil, true)
  end


  def build_summary_grid(recordset)

    #require File.dirname(__FILE__) + "/../../../app/helpers/reports/search_engine_plugins.rb"

    column_configs = []
    keys           = recordset[0].keys

    summary_cols   = []
    if dm_session[:group_by_columns]
      summary_cols = dm_session[:group_by_columns].map {|c| c.split('.').last.split(' ').last }
      extra_cols   = keys - summary_cols
      # Do some acrobatics to get the function columns in the same sequence as they were added by the user.
      # NB This code is a bit brittle as it depends on the way columns are created in MesScada::DataMinerActions#add_group_by_columns_before_from_clause
      orig_extras  = extra_cols.map {|c| m = c.match(/\Acount|sum_|min_|max_|avg_/); "#{m[0].upcase.sub('_', '')}(#{m.post_match}"; }
      orig_seq     = dm_session[:functions].split(/,|\|/)
      new_keys     = orig_seq.map {|a| orig_extras.each_with_index {|o,i| if a.start_with?(o) then break i end; } }
      new_seq      = new_keys.map {|i| extra_cols[i] }
      summary_cols += new_seq
    else
      summary_cols = keys
    end

    summary_cols.each do |key|
      column_configs << {:field_type => 'text', :field_name => key.to_s}
    end

    #column_configs << {:field_type => 'text', :field_name => 'show_records'}
    column_configs << {:field_type => 'link_window', :field_name => 'show_records',
      :settings =>
    {:link_text => 'show_records',
      :target_action => 'show_recs_dummy',
      :id_value => 'id'}}

    get_data_grid(recordset, column_configs, MesScada::GridPlugins::SearchEngine::SearchEngineGridPlugin.new(self, request), true)

  end


  def build_child_records_grid(recordset)
    column_configs = []
    attributes     = recordset[0].attributes
    attributes.each do |key,val|
      column_configs << {:field_type => 'text', :field_name => key.to_s}
    end

    column_configs << {:field_type => 'action', :field_name => 'view_details', :column_width => 120,
                       :settings   => {:link_text => 'view details', :target_action => 'view_details_on_child_grid', :id_column => 'id'}}

    return get_data_grid(recordset, column_configs)
  end

  #================================================
  #  My View Code
  #================================================

  def build_tag_form(tag,action,caption,is_edit=nil,is_create_retry=nil)
    field_configs = []
    field_configs[0] << {:field_type => 'TextField', :field_name => 'tag_name'}
    build_form(tag, field_configs, action, 'tag', caption, is_edit)
  end

  def build_my_tags_grid(data_set,can_edit,can_delete)
    column_configs = []
    column_configs[0] << {:field_type => 'text', :field_name => 'tag_name'}

    if can_edit
      column_configs << {:field_type => 'action', :field_name => 'edit tag',
        :settings =>
      {:link_text      => 'edit',
        :target_action => 'edit_tag',
        :id_column     => 'id'}}
    end

    if can_delete
      column_configs << {:field_type => 'action', :field_name => 'delete tag',
        :settings =>
      {:link_text      => 'delete',
        :target_action => 'delete_tag',
        :id_column     => 'id'}}
    end

    return get_data_grid(data_set,column_configs)
  end

  def build_save_as_view_form(report,action,caption,is_edit=nil,is_create_retry=nil)
    field_configs = []
    field_configs << {:field_type => 'DropDownField', :field_name => 'tag1'}
  end

  def build_all_views_grid(data_set, can_edit, can_delete)
    column_configs = []
    # data_set.each do |record|
    #   record.create_tags
    # end
    column_configs << {:field_type=>'text', :field_name=>'code'}
    column_configs << {:field_type=>'text', :field_name=>'report_name'}
    column_configs << {:field_type=>'text', :field_name=>'user_defined_report_name', :column_caption => 'description', :col_width => 200}
    column_configs << {:field_type => 'link_window',:field_name => 'launch',
      :settings =>
    {:link_text => 'view',
      :target_action => 'launch_my_view',
      :id_column => 'id'}}
    column_configs << {:field_type=>'text', :field_name=>'ranking'}
    # column_configs << {:field_type=>'text', :field_name=>'tag1'}
    # column_configs << {:field_type=>'text', :field_name=>'tag2'}
    # column_configs << {:field_type=>'text', :field_name=>'tag3'}
    # column_configs << {:field_type=>'text', :field_name=>'tag4'}
    # column_configs << {:field_type=>'text', :field_name=>'tag5'}
    column_configs << {:field_type=>'text', :field_name=>'fieldlist'}
    column_configs << {:field_type=>'text', :field_name=>'group_name'}
    column_configs << {:field_type=>'text', :field_name=>'updated_at'}

    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit',
        :settings =>
      {:link_text => 'edit',
        :target_action => 'edit_all_view',
        :id_column => 'id'}}
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete',
        :settings =>
      {:link_text => 'delete',
        :target_action => 'delete_all_view',
        :id_column => 'id'}}
    end


    get_data_grid(data_set,column_configs)
  end

  def build_my_views_grid(data_set, can_edit, can_delete)
#    require File.dirname(__FILE__) + "/../../../app/helpers/reports/reports_plugins.rb"

    column_configs = []
    # data_set.each do |record|
    #   record.create_tags
    # end

    column_configs << {:field_type=>'text', :field_name=>'report_name'}
    column_configs << {:field_type=>'text', :field_name=>'code'}
    column_configs << {:field_type=>'text', :field_name=>'user_defined_report_name', :column_caption => 'description', :col_width => 200}
    column_configs << {:field_type => 'link_window',:field_name => 'launch',
      :settings =>
    {:link_text => 'view',
      :target_action => 'launch_my_view',
      :id_column => 'id',
      :null_test => "webquery_only"}}
    column_configs << {:field_type => 'link_window',:field_name => 'spreadsheet', :col_width => 80,
      :settings =>
    {:link_text => 'download',
      :target_action => 'download_my_view',
      :id_column => 'id',
      :null_test => "show_parameters"}}

    # column_configs << {:field_type => 'action', :field_name => 'webquery',
    #   :settings =>
    # {:link_text => 'copy',
    #  :host_and_port => request.host_with_port,
    #  :controller    => '' ,
    #   #:controller => 'application',
    #   :target_action => 'webquery',
    #   :id_column => 'id'},
    # :html_options => {:class => 'copy_webquery_link'}}

    column_configs << {:field_type => 'action', :field_name => 'webquery',
      :settings =>
    {:link_text => 'copy',
      :target_action => 'launch_my_view',
      :id_column => 'id'}}

    column_configs << {:field_type=>'text', :field_name=>'fieldlist'}
    column_configs << {:field_type=>'text', :field_name=>'ranking'}
    column_configs << {:field_type=>'text', :field_name=>'updated_at'}
    # column_configs << {:field_type=>'text', :field_name=>'tag1'}
    # column_configs << {:field_type=>'text', :field_name=>'tag2'}
    # column_configs << {:field_type=>'text', :field_name=>'tag3'}
    # column_configs << {:field_type=>'text', :field_name=>'tag4'}
    # column_configs << {:field_type=>'text', :field_name=>'tag5'}

    # column_configs << {:field_type => 'link_window', :field_name => 'webquery iqy',
    #   :settings =>
    # {:link_text => 'download',
    #   :target_action => 'download_iqy',
    #   :id_column => 'id'}}

    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit',
        :settings =>
      {:link_text => 'edit',
        :target_action => 'edit_my_view',
        :id_column => 'id',
        :null_test => "author_id.to_s != active_record.current_user_id.to_s"}}
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete',
        :settings =>
      {:link_text => 'delete',
        :target_action => 'delete_my_view',
        :id_column => 'id',
        :null_test => "author_id.to_s != active_record.current_user_id.to_s || active_record.users.count > 1"}}
    end

    # group_headers = [{:start_column_name => 'report_name', :number_of_columns => 3, :title_text => 'Report'},
    #                  {:start_column_name => 'fieldlist', :number_of_columns => 2, :title_text => 'Arbitrary'}]

    # Setting grid attributes from a helper: 
    # get_data_grid(data_set,column_configs, MesScada::GridPlugins::Reports::ListMyViews.new( @request ), nil, nil, {:group_headers => group_headers,
    # :caption => 'Try a different CAPTION'})

    get_data_grid(data_set,column_configs, MesScada::GridPlugins::Reports::ListMyViews.new( @request ))
  end

  #================================================
  #  End of My View Code
  #================================================


  def build_data_miner_reports_grid(data_set, can_edit, can_delete)
    column_configs = []
    column_configs << {:field_type=>'text', :field_name=>'code'}
    column_configs << {:field_type=>'text', :field_name=>'report_name', :col_width => 250}
    column_configs << {:field_type=>'action', :field_name=>'launch', :col_width => 50,
                       :settings => {:link_text => 'view',
                                     :target_action => 'build_report_parameters_form',
                                     :id_column => 'id' } }
    column_configs << {:field_type=>'text', :field_name=>'description', :col_width => 300}
    column_configs << {:field_type=>'text', :field_name=>'fieldlist'}
    column_configs << {:field_type=>'text', :field_name=>'group_name'}
    column_configs << {:field_type=>'text', :field_name=>'filename'}
    column_configs << {:field_type=>'text', :field_name=>'updated_at'}

    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit',
        :settings =>
      {:link_text => 'edit',
        :target_action => 'edit_data_miner_report',
        :id_column => 'id'}}
      column_configs << {:field_type => 'action',:field_name => 'column_order', :column_caption => 'Columns',
        :settings =>
      {:link_text => 'reorder',
        :target_action => 'reorder_data_miner_report_columns',
        :id_column => 'id'}}
    end

    get_data_grid(data_set, column_configs)
  end

  def build_data_miner_report_form(data_miner_report,action,caption,is_edit=nil,is_create_retry=nil)
     field_configs = []
     field_configs << {:field_type=>'TextField', :field_name=>'code'}
     field_configs << {:field_type=>'TextField', :field_name=>'report_name'}
     field_configs << {:field_type=>'TextField', :field_name=>'description'}
     field_configs << {:field_type=>'TextField', :field_name=>'fieldlist'}
     field_configs << {:field_type=>'TextField', :field_name=>'group_name'}
     build_form(data_miner_report,field_configs,action,'data_miner_report',caption,is_edit)
  end


  def build_search_archived_reports_form(hash_object,archived_report_types,action,caption)

    search_combos_js = gen_combos_clear_js_for_combos(["hash_object_report_type","hash_object_report_name"])
    #Observers for search combos
    report_type_observer  = {:updated_field_id => "hash_object_report_report_name",
             :remote_method => 'hash_object_report_type_search_combo_changed',
             :on_completed_js => search_combos_js["hash_object_report_type"]}

    field_configs = []

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'report_type?required',
                      :observer => report_type_observer,
                      :settings   => {:list=>archived_report_types}}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'report_name?required',
                      :settings   => {:size=>50,
                                      :readonly=>true,
                                      :lookup   =>true, :lookup_search_file=>"search_archived_reports",
                                      :select_column_name=>'report_name',
                                      :send_fields=>'report_type'}}

    build_form(hash_object, field_configs, action, 'hash_object', caption)
  end

  def build_list_archived_reports_grid(data_set)
    column_configs = []

    column_configs << {:field_type => 'action',:field_name => 'select',
      :settings =>
    {:link_text => 'select',
      :target_action => 'select_archived_report',
      :id_column => 'id'}}

    column_configs << {:field_type=>'text', :field_name=>'report_type'}
    column_configs << {:field_type=>'text', :field_name=>'report_name', :col_width => 300}
    column_configs << {:field_type=>'text', :field_name=>'created_on', :col_width => 200}

    get_data_grid(data_set, column_configs,nil,true)
  end

end
