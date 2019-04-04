module Tools::EdiHelper
 
  def build_edi_org_hub_grid(data_set,can_edit,can_delete)

    column_configs = Array.new
    column_configs << {:field_type => 'text',:field_name => 'organization_code'}
    column_configs << {:field_type => 'text',:field_name => 'flow_type'}
    column_configs << {:field_type => 'text',:field_name => 'hub_address'}
#	----------------------
#	define action columns
#	----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit',
      :settings => {
        :link_text => 'edit',
        :target_action => 'edit_edi_org_hub',
        :id_column => 'id'
        }
      }
    end
    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete',
      :settings => {
        :link_text => 'delete',
        :target_action => 'delete_edi_org_hub',
        :id_column => 'id'}}
    end

    get_data_grid(data_set,column_configs)
  end
 
  def build_edi_org_flow_grid(data_set,can_edit,can_delete)

    column_configs = Array.new
    column_configs << {:field_type => 'text',:field_name => 'organization_code'}
    column_configs << {:field_type => 'text',:field_name => 'flow_type'}
    column_configs << {:field_type => 'text',:field_name => 'active',:data_type => 'boolean'}
#	----------------------
#	define action columns
#	----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit',
      :settings => {
        :link_text => 'edit',
        :target_action => 'edit_edi_org_flow',
        :id_column => 'id'
        }
      }
    end
    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete',
      :settings => {
        :link_text => 'delete',
        :target_action => 'delete_edi_org_flow',
        :id_column => 'id'}}
    end

    get_data_grid(data_set,column_configs)
  end

  def build_edi_out_destination_grid(data_set,can_edit,can_delete)

    column_configs = Array.new
    column_configs << {:field_type => 'text',:field_name => 'organization_code'}
    column_configs << {:field_type => 'text',:field_name => 'flow_type'}
    column_configs << {:field_type => 'text',:field_name => 'hub_address'}
    column_configs << {:field_type => 'text',:field_name => 'out_destination_dir'}
    column_configs << {:field_type => 'text',:field_name => 'transfer_mechanism'}
#	----------------------
#	define action columns
#	----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit',
      :settings => {
        :link_text => 'edit',
        :target_action => 'edit_edi_out_destination',
        :id_column => 'id'
        }
      }
    end
    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete',
      :settings => {
        :link_text => 'delete',
        :target_action => 'delete_edi_out_destination',
        :id_column => 'id'}}
    end

    get_data_grid(data_set,column_configs)
  end

  def build_edi_out_destination_form(edi_out_destination,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:edi_out_destination_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------

    field_configs = Array.new
    field_configs << {:field_type => 'TextField',
      :field_name => 'flow_type', :settings => {:size => 4}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'organization_code', :settings => {:size => 4}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'hub_address', :settings => {:size => 4}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'out_destination_dir'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'transfer_mechanism'}

    build_form(edi_out_destination,field_configs,action,'edi_out_destination',caption,is_edit)
  end
 
  def build_edi_out_destination_search_form(edi_out_destination,action,caption,is_flat_search = nil)
    #	--------------------------------------------------------------------------------------------------
    #	Define an observer for each index field
    #	--------------------------------------------------------------------------------------------------
    session[:edi_out_destination_search_form]= Hash.new 
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["edi_out_destination_flow_type","edi_out_destination_organization_code"])

    flow_types = EdiOutDestination.find_by_sql('select distinct flow_type from edi_out_destinations').map{|g|[g.flow_type]}
    flow_types.unshift("<empty>")
    organization_codes = EdiOutDestination.find_by_sql('select distinct organization_code from edi_out_destinations').map{|g|[g.organization_code]}
    organization_codes.unshift("<empty>")
    #	----------------------------------------
    #	 Define search fields to build form from
    #	----------------------------------------
    field_configs = []
    #	----------------------------------------------------------------------------------------------
    #	Define search Combo fields to represent the unique index on this table 
    #	----------------------------------------------------------------------------------------------
    field_configs << {:field_type => 'DropDownField',
      :field_name => 'flow_type',
      :settings => {:list => flow_types}}

    field_configs << {:field_type => 'DropDownField',
      :field_name => 'organization_code',
      :settings => {:list => organization_codes}}

    build_form(edi_out_destination,field_configs,action,'edi_out_destination',caption,false)

  end

  def build_edi_org_hub_form(edi_org_hub,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:edi_org_hub_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------

    field_configs = Array.new
    field_configs << {:field_type => 'TextField',
      :field_name => 'flow_type', :settings => {:size => 4}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'organization_code', :settings => {:size => 4}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'hub_address', :settings => {:size => 4}}

    build_form(edi_org_hub,field_configs,action,'edi_org_hub',caption,is_edit)
  end

  def build_edi_org_flow_form(edi_org_flow,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:edi_org_flow_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------

    field_configs = Array.new
    field_configs << {:field_type => 'TextField',
      :field_name => 'flow_type', :settings => {:size => 4}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'organization_code', :settings => {:size => 4}}

    field_configs << {:field_type => 'CheckBox',
      :field_name => 'active'}

    build_form(edi_org_flow,field_configs,action,'edi_org_flow',caption,is_edit)
  end

  #MM052016 - Create web tool to search files by name or contents
  def build_search_edi_file_by_name_form(edi_files, action, caption, is_edit = nil)
    field_configs = Array.new

    field_configs << {:field_type => 'TextField',:field_name => 'file_name'}

    build_form(edi_files, field_configs, action, 'edi_files', caption, is_edit)
  end

  def build_search_edi_file_by_contents_form(edi_file_contents, action, caption, is_edit = nil)
    field_configs = Array.new

    field_configs << {:field_type => 'TextField',:field_name => 'file_contents'}

    build_form(edi_file_contents, field_configs, action, 'edi_file_contents', caption, is_edit)
  end

  def build_edi_files_grid(data_set)

    action_configs = []
    column_configs = []


    action_configs << {:field_type => 'action',
                       :field_name => 'view_file',
                       :column_caption => 'view',
                       :col_width => 120,
                       :settings =>{:link_icon => 'view',
                                    :link_text => 'view',
                                    :host_and_port => request.host_with_port.to_s,
                                    :controller    => request.path_parameters['controller'].to_s ,
                                    :target_action => 'view_file',
                                    :id_column => 'id',
                                    :null_test => "['file_type'] == 'MTDP'"
                       }
    }

    action_configs << {:field_type => 'action',
                       :field_name => 'download_file',
                       :column_caption => 'download',
                       :col_width => 120,
                       :settings =>{:link_icon => 'download',
                                    :link_text => 'download',
                                    :host_and_port => request.host_with_port.to_s,
                                    :controller    => request.path_parameters['controller'].to_s ,
                                    :target_action => 'download_file',
                                    :id_column => 'id'
                       }
    }

    action_configs << {:field_type => 'action',
                       :field_name => 'view_raw_file',
                       :column_caption => 'view_raw_file',
                       :col_width => 120,
                       :settings =>{:link_icon => 'view_raw_file',
                                    :link_text => 'view_raw_file',
                                    :host_and_port => request.host_with_port.to_s,
                                    :controller    => request.path_parameters['controller'].to_s ,
                                    :target_action => 'view_raw_file',
                                    :id_column => 'id'
                       }
    }

    #MM082017 - edi file search tools: results grid: add 2 menu items:
    # 1] copy_file_to_tmp (onclick copy file to 'temp' directory 2 levels upward from current directory- create temp dir if not existing)
    # 2] re_drop_file(copy file to 'receive' dir- use a configured path in globals)
    action_configs << {:field_type => 'action',
                       :field_name => 'copy_file_to_tmp',
                       :column_caption => 'copy_file_to_tmp',
                       :col_width => 120,
                       :settings =>{:link_icon => 'copy_file_to_tmp',
                                    :link_text => 'copy_file_to_tmp',
                                    :host_and_port => request.host_with_port.to_s,
                                    :controller    => request.path_parameters['controller'].to_s ,
                                    :target_action => 'copy_file_to_tmp',
                                    :id_column => 'id'
                       }
    }

    action_configs << {:field_type => 'action',
                       :field_name => 're_drop_file',
                       :column_caption => 're_drop_file',
                       :col_width => 120,
                       :settings =>{:link_icon => 're_drop_file',
                                    :link_text => 're_drop_file',
                                    :host_and_port => request.host_with_port.to_s,
                                    :controller    => request.path_parameters['controller'].to_s ,
                                    :target_action => 're_drop_file',
                                    :id_column => 'id'
                       }
    }

    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?
    column_configs << {:field_type => 'text',:field_name => 'file_path',:col_width => 600}
    column_configs << {:field_type => 'text',:field_name => 'file_name',:col_width => 300}
    column_configs << {:field_type => 'text',:field_name => 'folder_type',:col_width => 150}
    column_configs << {:field_type => 'text',:field_name => 'file_type',:col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'modified_date', :col_width => 150}
    column_configs << {:field_type => 'text',:field_name => 'file_size', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'id',:col_width => 100 ,:hide => true}

    return get_data_grid(data_set, column_configs,nil,true)
  end

  def build_edi_contents_grid(data_set)

    action_configs = []
    column_configs = []

    action_configs << {:field_type => 'action',
                       :field_name => 'view_file',
                       :column_caption => 'view',
                       :col_width => 120,
                       :settings =>{:link_icon => 'view',
                                    :link_text => 'view',
                                    :host_and_port => request.host_with_port.to_s,
                                    :controller    => request.path_parameters['controller'].to_s ,
                                    :target_action => 'view_file',
                                    :id_column => 'id',
                                    :null_test => "['file_type'] == 'MTDP'"
                       }
    }

    action_configs << {:field_type => 'action',
                       :field_name => 'download_file',
                       :column_caption => 'download',
                       :col_width => 120,
                       :settings =>{:link_icon => 'download',
                                    :link_text => 'download',
                                    :host_and_port => request.host_with_port.to_s,
                                    :controller    => request.path_parameters['controller'].to_s ,
                                    :target_action => 'download_file',
                                    :id_column => 'id'
                       }
    }

    action_configs << {:field_type => 'action',
                       :field_name => 'view_raw_file',
                       :column_caption => 'view_raw_file',
                       :col_width => 120,
                       :settings =>{:link_icon => 'view_raw_file',
                                    :link_text => 'view_raw_file',
                                    :host_and_port => request.host_with_port.to_s,
                                    :controller    => request.path_parameters['controller'].to_s ,
                                    :target_action => 'view_raw_file',
                                    :id_column => 'id'
                       }
    }

    #MM082017 - edi file search tools: results grid: add 2 menu items:
    # 1] copy_file_to_tmp (onclick copy file to 'temp' directory 2 levels upward from current directory- create temp dir if not existing)
    # 2] re_drop_file(copy file to 'receive' dir- use a configured path in globals)
    action_configs << {:field_type => 'action',
                       :field_name => 'copy_file_to_tmp',
                       :column_caption => 'copy_file_to_tmp',
                       :col_width => 120,
                       :settings =>{:link_icon => 'copy_file_to_tmp',
                                    :link_text => 'copy_file_to_tmp',
                                    :host_and_port => request.host_with_port.to_s,
                                    :controller    => request.path_parameters['controller'].to_s ,
                                    :target_action => 'copy_file_to_tmp',
                                    :id_column => 'id'
                       }
    }

    action_configs << {:field_type => 'action',
                       :field_name => 're_drop_file',
                       :column_caption => 're_drop_file',
                       :col_width => 120,
                       :settings =>{:link_icon => 're_drop_file',
                                    :link_text => 're_drop_file',
                                    :host_and_port => request.host_with_port.to_s,
                                    :controller    => request.path_parameters['controller'].to_s ,
                                    :target_action => 're_drop_file',
                                    :id_column => 'id'
                       }
    }

    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?
    column_configs << {:field_type => 'text',:field_name => 'file_path',:col_width => 600}
    column_configs << {:field_type => 'text',:field_name => 'file_name',:col_width => 300}
    column_configs << {:field_type => 'text',:field_name => 'folder_type',:col_width => 150}
    column_configs << {:field_type => 'text',:field_name => 'file_type',:col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'modified_date', :col_width => 200}
    column_configs << {:field_type => 'text',:field_name => 'id',:col_width => 100 ,:hide => true}

    return get_data_grid(data_set, column_configs,nil,true)
  end

end

