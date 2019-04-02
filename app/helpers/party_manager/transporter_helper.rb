module PartyManager::TransporterHelper


  def build_transporter_form(transporter,action,caption,is_edit = nil,is_create_retry = nil)
#  --------------------------------------------------------------------------------------------------
#  Define a set of observers for each composite foreign key- in effect an observer per combo involved
#  in a composite foreign key
#  --------------------------------------------------------------------------------------------------
    search_combos_js = gen_combos_clear_js_for_combos(["transporter_haulier_parties_role_id","transporter_contact_number"])
    haulier_observer = {:updated_field_id => "contact_number_cell",
                        :remote_method => 'haulier_search_combo_changed',
                        :on_completed_js => search_combos_js["transporter_haulier_parties_role_id"]
    }

    session[:transporter_form]= Hash.new

    hauliers = PartiesRole.find(:all, :conditions => "role_name='HAULIER'").map{|g| [g.party_name, g.id]}
#  ---------------------------------
#   Define fields to build form from
#  ---------------------------------
    field_configs = []
    field_configs << {:field_type => 'DropDownField',
                      :observer => haulier_observer,
                      :field_name => 'haulier_parties_role_id',
                      :settings=>{:label_caption=>'haulier', :list=>hauliers}}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'contact_person'}

    field_configs << {:field_type => 'LabelField',
                      :field_name => 'contact_number'}

    if(is_edit)
      field_configs << {:field_type=>'link_window_field',:field_name =>'rate_change_logs',
                        :settings =>{:target_action => 'view_rate_change_logs',
                                     :id_column=>'id',
                                     :link_text => 'view'}}

      field_configs << {:field_type => 'Screen',
                        :field_name => "rates",
                        :settings =>{
                            :controller => 'party_manager/transporter',
                            :target_action => 'list_transporter_rates',
                            :width => 1200,
                            :height => 250,
                            :id_value => transporter.id,
                            :no_scroll => true
                        }
      }
      set_form_layout('1',nil,nil,4)
      set_submit_button_align('left')
    end

    construct_form(transporter,field_configs,action,'transporter',caption,is_edit)

  end


  def build_transporter_search_form(transporter,action,caption,is_flat_search = nil)
#  --------------------------------------------------------------------------------------------------
#  Define an observer for each index field
#  --------------------------------------------------------------------------------------------------
    session[:transporter_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    #Observers for search combos
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = []
    contact_people = Transporter.find_by_sql('select distinct contact_person from transporters').map{|g|[g.contact_person]}
    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'contact_person',
                      :settings => {:list => contact_people}}

    construct_form(transporter,field_configs,action,'transporter',caption,false)

  end



  def build_transporter_grid(data_set,can_edit,can_delete)

    column_configs = []
    action_configs = []
#  ----------------------
#  define action columns
#  ----------------------
    if can_edit
      action_configs << {:field_type => 'action',:field_name => 'edit transporter',
                         :column_caption => 'Edit',
                         :settings =>
                             {:link_text => 'edit',
                              :link_icon => 'edit',
                              :target_action => 'edit_transporter',
                              :id_column => 'id'}}
    end

    if can_delete
      action_configs << {:field_type => 'action',:field_name => 'delete transporter',
                         :column_caption => 'Delete',
                         :settings =>
                             {:link_text => 'delete',
                              :link_icon => 'delete',
                              :target_action => 'delete_transporter',
                              :id_column => 'id'}}
    end

#action_configs << {:field_type => 'separator'} if can_edit || can_delete

    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?

    column_configs << {:field_type => 'text', :field_name => 'haulier', :column_caption => 'haulier', :col_width => 140}
    column_configs << {:field_type => 'text', :field_name => 'contact_person', :column_caption => 'contact person', :col_width => 140}
    column_configs << {:field_type => 'text', :field_name => 'contact_number',:col_width => 140}
    column_configs << {:field_type => 'text', :field_name => 'created_by', :column_caption => 'created by', :col_width => 140}
    column_configs << {:field_type => 'text', :field_name => 'updated_by', :column_caption => 'updated by', :col_width => 140}
    column_configs << {:field_type => 'text', :field_name => 'created_at', :col_width => 140}

    grid_command = {:field_type => 'action', :field_name => 'new_transporter',
                    :settings =>
                        {
                            :host_and_port => request.host_with_port.to_s,
                            :controller => request.path_parameters['controller'].to_s,
                            :target_action => 'new_transporter',
                            :link_text => 'new transporter'
                        }}

    get_data_grid(data_set,column_configs, nil, true, grid_command)
  end



  def build_transporter_dm_grid(data_set, stat, columns_list, can_edit, can_delete, grid_configs)

    column_configs = []
    action_configs = []

    # ----------------------
    # define action columns
    # ----------------------
    if can_edit
      action_configs << {:field_type => 'action',:field_name => 'edit transporter',
                         :column_caption => 'Edit',
                         :settings =>
                             {:link_text => 'edit',
                              :link_icon => 'edit',
                              :target_action => 'edit_transporter',
                              :id_column => 'id'}}
    end

    if can_delete
      action_configs << {:field_type => 'action',:field_name => 'delete transporter',
                         :column_caption => 'Delete',
                         :settings =>
                             {:link_text => 'delete',
                              :link_icon => 'delete',
                              :target_action => 'delete_transporter',
                              :id_column => 'id'}}
    end

    #action_configs << {:field_type => 'separator'} if can_edit || can_delete
    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?

    # Build all other columns from the dataminer yml file.
    build_generic_column_configs(data_set, column_configs, stat, columns_list, grid_configs)

    # Get any other datagrid options from the grid_configs...
    opts = build_grid_options_from_grid_configs(grid_configs)

    get_data_grid(data_set, column_configs, nil, true, nil, opts)
  end

  def build_transporter_rate_grid(data_set,can_edit,can_delete)

    column_configs = []
    action_configs = []
#  ----------------------
#  define action columns
#  ----------------------
    if can_edit
      action_configs << {:field_type => 'link_window',:field_name => 'edit transporter_rate',
                         :column_caption => 'Edit',
                         :settings =>
                             {:link_text => 'edit',
                              :link_icon => 'edit',
                              :target_action => 'edit_transporter_rate',
                              :id_column => 'id'}}
    end

    if can_delete
      action_configs << {:field_type => 'action',:field_name => 'delete transporter_rate',
                         :column_caption => 'Delete',
                         :settings =>
                             {:link_text => 'delete',
                              :link_icon => 'delete',
                              :target_action => 'delete_transporter_rate',
                              :id_column => 'id'}}
    end

#action_configs << {:field_type => 'separator'} if can_edit || can_delete

    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?

    column_configs << {:field_type => 'text', :field_name => 'rate'}
    column_configs << {:field_type => 'text', :field_name => 'city_code', :column_caption => 'destination_code', :col_width => 140}
    column_configs << {:field_type => 'text', :field_name => 'city_name', :column_caption => 'destination_name', :col_width => 140}
# column_configs << {:field_type => 'text', :field_name => 'updated_by'}

    grid_command = {:field_type => 'action', :field_name => 'new_transporter_rate',
                    :settings =>
                        {
                            :host_and_port => request.host_with_port.to_s,
                            :controller => request.path_parameters['controller'].to_s,
                            :target_action => 'new_transporter_rate',
                            :link_text => 'new transporter rate',
                            :id_value      =>params[:id]
                        }}

    get_data_grid(data_set,column_configs, nil, true, grid_command)
  end

  def build_rate_change_logs_grid(data_set)

    column_configs = []
    column_configs << {:field_type => 'text', :field_name => 'city_code', :column_caption => 'destination_code', :col_width => 140}
    column_configs << {:field_type => 'text', :field_name => 'city_name', :column_caption => 'destination_name', :col_width => 140}
    column_configs << {:field_type => 'text', :field_name => 'rate_from'}
    column_configs << {:field_type => 'text', :field_name => 'rate_to'}
    column_configs << {:field_type => 'text', :field_name => 'created_at', :col_width => 120}

    get_data_grid(data_set,column_configs, nil, true)
  end

  def build_transporter_rate_form(transporter_rate,action,caption,is_edit = nil,is_create_retry = nil)
#  --------------------------------------------------------------------------------------------------
#  Define a set of observers for each composite foreign key- in effect an observer per combo involved
#  in a composite foreign key
#  --------------------------------------------------------------------------------------------------
    session[:transporter_rate_form]= Hash.new

    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = []
    #  ----------------------------------------------------------------------------------------------------
    #  Combo field to represent foreign key (transporter_id) on related table: transporters
    #  -----------------------------------------------------------------------------------------------------
    field_configs << {:field_type => 'HiddenField',
                      :field_name => 'transporter_id'}


    field_configs << {:field_type => 'TextField',
                      :field_name => 'rate'}

    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (city_id) on related table: cities
    #  ----------------------------------------------------------------------------------------------
    if(!is_edit)
      city_codes = City.find_by_sql("select * from cities where id not in(select city_id from transporter_rates where transporter_id=#{transporter_rate.transporter_id})").map{|g|[g.city_code,g.id]}
      # city_codes = [[transporter_rate.city.city_code,transporter_rate.city.id]]

      field_configs << {:field_type => 'DropDownField',
                        :field_name => 'city_id',
                        :settings => {:label_caption=>'city_code',:list => city_codes}}
    else
      field_configs << {:field_type => 'LabelField',
                        :field_name => 'city_code'}
    end

    construct_form(transporter_rate,field_configs,action,'transporter_rate',caption,is_edit)

  end


end
