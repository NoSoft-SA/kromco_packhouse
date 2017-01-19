module Production::MesscadaCrudHelper

  #MM122014 - messcada changes

  #mescada facilities

  def build_facility_form(facility,action,caption,is_edit,is_create_retry = nil)


    field_configs = Array.new

    if is_edit
      field_configs << {:field_type => 'LabelField',
                        :field_name => 'code?required'}
    else
      field_configs << {:field_type => 'TextField',
                        :field_name => 'code?required'}
    end

    field_configs << {:field_type => 'TextField',
                      :field_name => 'packhouse_number'}

    field_configs <<  {:field_type => 'TextField',
                       :field_name => 'puc_phc'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'gln'}

    field_configs << {:field_type => 'CheckBox',
                      :field_name => 'is_active'}

    field_configs <<  {:field_type => 'TextArea',
                       :field_name => 'desc_short?required'}

    field_configs <<  {:field_type => 'TextArea',
                       :field_name => 'desc_medium'}

    field_configs <<  {:field_type => 'TextArea',
                       :field_name => 'desc_long'}

    if is_edit
      field_configs << {:field_type => 'Screen',
                        :field_name => "messcada_servers",
                        :settings   => {:target_action => 'list_servers',
                                        :id_value      => facility.id,
                                        :width         => 1100,
                                        :height        => 300,
                                        :no_scroll     => true
                        }
      }

      session[:field_name] = "facility_code"
      session[:field_value] = facility.code

      field_configs << {:field_type => 'Screen',
                        :field_name => "messcada_peripherals",
                        :settings   => {:target_action => 'list_peripherals',
                                        :id_value      => facility.code,
                                        :width         => 1100,
                                        :height        => 300,
                                        :no_scroll     => true
                        }
      }


    end

    @submit_button_align = "left"
    set_form_layout '2',nil,1,8

    build_form(facility,field_configs,action,'facility',caption,is_edit)

  end


  def build_facilities_grid(data_set,can_edit,can_delete,is_select)

    column_configs = Array.new
    column_configs << {:field_type => 'text',:field_name => 'id', :col_width => 60}
    column_configs << {:field_type => 'text',:field_name => 'code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'packhouse_number', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'puc_phc', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'gln', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'is_active', :data_type => 'boolean', :col_width => 60}
    column_configs << {:field_type => 'text',:field_name => 'desc_short', :col_width => 200}
    column_configs << {:field_type => 'text',:field_name => 'desc_medium', :col_width => 250}
    column_configs << {:field_type => 'text',:field_name => 'desc_long', :col_width => 300}

    if can_edit
      column_configs <<  {:field_type => 'action',:field_name => 'edit facility',
                                                 :settings =>
                                                     {:link_text => 'edit',
                                                      :target_action => 'edit_facility',
                                                      :id_column => 'id',
                                                      :col_width => 100
                                                     }
      }
    end

    if can_delete
      column_configs <<  {:field_type => 'action',:field_name => 'delete facility',
                                                 :settings =>
                                                     {:link_text => 'delete',
                                                      :target_action => 'delete_facility',
                                                      :id_column => 'id',
                                                      :col_width => 100
                                                     }
      }
    end

    grid_command = {:field_type => 'link_window_field', :field_name => 'add_facilities',
                    :settings   => {
                        :host_and_port => request.host_with_port.to_s,
                        :controller    => request.path_parameters['controller'].to_s ,
                        :target_action => 'render_new_facility',
                        :link_text     => "add facilities"}
    }

    set_grid_min_height(150)
    set_grid_min_width(850)
    hide_grid_client_controls()
    return get_data_grid(data_set,column_configs,nil,nil,grid_command)

  end

  #messcada_servers

  def build_server_form(server,action,caption,is_edit,is_create_retry = nil)


    field_configs = Array.new

    if is_edit
      id = server.id
      link_values = MesscadaServer.find_by_sql("select * from  messcada_servers MS
                                                where MS.id = '#{id}'")
      if link_values.empty?
      else
        facility_code = link_values[0].facility_code
      end

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'facility_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_facility_code',
                             :id_value      => facility_code,
                             :link_text     => "#{facility_code}"
                            }
      }

      field_configs << {:field_type => 'LabelField',
                        :field_name => 'code?required'}
    else
      field_configs << {:field_type => 'TextField',
                        :field_name => 'code?required'}
    end

    field_configs << {:field_type => 'TextField',
                      :field_name => 'tcp_ip?required'}

    field_configs <<  {:field_type => 'TextField',
                       :field_name => 'tcp_port?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'web_ip?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'web_port?required'}

    field_configs << {:field_type => 'CheckBox',
                      :field_name => 'is_active'}

    field_configs <<  {:field_type => 'TextArea',
                       :field_name => 'desc_short?required'}

    field_configs <<  {:field_type => 'TextArea',
                       :field_name => 'desc_medium'}

    field_configs <<  {:field_type => 'TextArea',
                       :field_name => 'desc_long'}

    if is_edit
      field_configs << {:field_type => 'Screen',
                        :field_name => "messcada_clusters",
                        :settings   => {:target_action => 'list_clusters',
                                        :id_value      => server.id,
                                        :width         => 1100,
                                        :height        => 300,
                                        :no_scroll     => true
                        }
      }

      session[:field_name] = "server_code"
      session[:field_value] = server.code

      field_configs << {:field_type => 'Screen',
                        :field_name => "messcada_peripherals",
                        :settings   => {:target_action => 'list_peripherals',
                                        :id_value      => server.code,
                                        :width         => 1100,
                                        :height        => 300,
                                        :no_scroll     => true
                        }
      }

    end

    @submit_button_align = "left"
    set_form_layout '2',nil,1,10
    build_form(server,field_configs,action,'server',caption,is_edit)

  end

  def build_servers_grid(data_set,can_edit,can_delete,is_edit,is_select)

    column_configs = Array.new
    column_configs << {:field_type => 'text',:field_name => 'id', :col_width => 60}
    column_configs << {:field_type => 'text',:field_name => 'code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'facility_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'tcp_ip', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'tcp_port', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'web_ip', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'web_port', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'is_active', :data_type => 'boolean', :col_width => 60}
    column_configs << {:field_type => 'text',:field_name => 'desc_short', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'desc_medium', :col_width => 150}
    column_configs << {:field_type => 'text',:field_name => 'desc_long', :col_width => 200}
    column_configs << {:field_type => 'text',:field_name => 'id', :col_width => 60}

    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit server',
                                                 :settings =>
                                                     {:link_text => 'edit',
                                                      :target_action => 'render_edit_server',
                                                      :id_column => 'id',
                                                      :col_width => 100
                                                     }
      }
    end

    if can_delete
      column_configs <<  {:field_type => 'action',:field_name => 'delete server',
                                                 :settings =>
                                                     {:link_text => 'delete',
                                                      :target_action => 'delete_server',
                                                      :id_column => 'id',
                                                      :col_width => 100
                                                     }
      }
    end

    if is_edit
      grid_command = {:field_type => 'link_window_field', :field_name => 'add_servers',
                      :settings   => {
                          :host_and_port => request.host_with_port.to_s,
                          :controller    => request.path_parameters['controller'].to_s ,
                          :target_action => 'add_servers',
                          :link_text     => "add servers"
                      }
      }
    end

    if is_select
      @multi_select = "selected_servers"
    end

    set_grid_min_height(150)
    set_grid_min_width(850)
    hide_grid_client_controls()
    return get_data_grid(data_set,column_configs,nil,nil,grid_command)

  end


  #messcada_clusters

  def build_cluster_form(cluster,action,caption,is_edit,is_create_retry = nil)

    field_configs = Array.new

    if is_edit
      id = cluster.id
      link_values = MesscadaCluster.find_by_sql("select * from  messcada_clusters MC
                                                where MC.id = '#{id}'")
      if link_values.empty?
      else
        facility_code = link_values[0].facility_code
        server_code = link_values[0].server_code
      end


      field_configs << {:field_type => 'DropDownField',
                        :field_name => 'facility_id?required',
                        :settings => {:list => facilities,
                                      :prompt => 'select a facility'
                        }}


      field_configs << {:field_type =>'LinkWindowField', :field_name => 'facility_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_facility_code',
                             :id_value      => facility_code,
                             :link_text     => "#{facility_code}"
                            }
      }

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'server_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_server_code',
                             :id_value      => server_code,
                             :link_text     => "#{server_code}"
                            }
      }

      field_configs << {:field_type => 'LabelField',
                        :field_name => 'code?required'}
    else
      field_configs << {:field_type => 'TextField',
                        :field_name => 'code?required'}
    end

    field_configs << {:field_type => 'CheckBox',
                      :field_name => 'is_active'}

    field_configs <<  {:field_type => 'TextArea',
                       :field_name => 'desc_short?required'}

    field_configs <<  {:field_type => 'TextArea',
                       :field_name => 'desc_medium'}

    field_configs <<  {:field_type => 'TextArea',
                       :field_name => 'desc_long'}

    field_configs <<  {:field_type => 'LabelField',
                       :field_name => 'desc_long',
                       :static_value => '',
                       :non_db_field => true}

    if is_edit
      field_configs << {:field_type => 'Screen',
                        :field_name => "messcada_modules",
                        :settings   => {:target_action => 'list_modules',
                                        :id_value      => cluster.id,
                                        :width         => 1100,
                                        :height        => 300,
                                        :no_scroll     => true
                        }
      }

      session[:field_name] = "cluster_code"
      session[:field_value] = cluster.code

      field_configs << {:field_type => 'Screen',
                        :field_name => "messcada_peripherals",
                        :settings   => {:target_action => 'list_peripherals',
                                        :id_value      => cluster.code,
                                        :width         => 1100,
                                        :height        => 300,
                                        :no_scroll     => true
                        }
      }

    end

    @submit_button_align = "left"
    set_form_layout '2',nil,1,8
    build_form(cluster,field_configs,action,'cluster',caption,is_edit)

  end

  def build_clusters_grid(data_set,can_edit,can_delete,is_edit,is_select)

    column_configs = Array.new
    column_configs << {:field_type => 'text',:field_name => 'id', :col_width => 60}
    column_configs << {:field_type => 'text',:field_name => 'code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'facility_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'server_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'is_active', :data_type => 'boolean', :col_width => 60}
    column_configs << {:field_type => 'text',:field_name => 'desc_short', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'desc_medium', :col_width => 150}
    column_configs << {:field_type => 'text',:field_name => 'desc_long', :col_width => 200}

    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit cluster',
                                                 :settings =>
                                                     {:link_text => 'edit',
                                                      :target_action => 'render_edit_cluster',
                                                      :id_column => 'id', :col_width => 100
                                                     }
      }
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete cluster',
                                                 :settings =>
                                                     {:link_text => 'delete',
                                                      :target_action => 'delete_cluster',
                                                      :id_column => 'id', :col_width => 100
                                                     }
      }
    end

    if is_edit
      grid_command = {:field_type => 'link_window_field', :field_name => 'add_clusters',
                      :settings   => {
                          :host_and_port => request.host_with_port.to_s,
                          :controller    => request.path_parameters['controller'].to_s ,
                          :target_action => 'new_cluster',
                          :link_text     => "add clusters"
                      }
      }
    end

    set_grid_min_height(150)
    set_grid_min_width(850)
    hide_grid_client_controls()
    return get_data_grid(data_set,column_configs,nil,nil,grid_command)

  end


  #messcada_modules

  def build_module_form(modules,action,caption,is_edit,is_create_retry = nil)

    field_configs = Array.new

    module_function_types = ["Local","Demand","Tapout","Mobile", "Robot", "Dashboard", "MAF"]

    module_types = ["CLM","CMS","CSM","EDI","GEN","INT","MOB","PAL","REB","RFS","SRT","SRV","TIP","PRN","SCL","SCN","QUALITY-CONTROL","PRODUCT-WEIGHT","DASHBOARD","STAGING-CONTAINERS","PRESORT","TIP-AND-LABEL","CLM-GROUP","COLD-STORAGE"]

    if is_edit
      id = modules.id
      link_values = MesscadaModule.find_by_sql("select * from  messcada_modules MM
                                                where MM.id = '#{id}'")
      if link_values.empty?
      else
        facility_code = link_values[0].facility_code
        server_code = link_values[0].server_code
        cluster_code = link_values[0].cluster_code
      end

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'facility_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_facility_code',
                             :id_value      => facility_code,
                             :link_text     => "#{facility_code}"
                            }
      }

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'server_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_server_code',
                             :id_value      => server_code,
                             :link_text     => "#{server_code}"
                            }
      }

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'cluster_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_cluster_code',
                             :id_value      => cluster_code,
                             :link_text     => "#{cluster_code}"
                            }
      }

      field_configs << {:field_type => 'LabelField',
                        :field_name => 'code?required'}
    else
      field_configs << {:field_type => 'TextField',
                        :field_name => 'code?required'}
    end

    # field_configs <<  {:field_type => 'TextField',
    #                    :field_name => 'module_type_code?required'}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'module_type_code?required',
                      :settings => {:list => module_types,
                                    :prompt => 'select a module_type_code'
                      }
    }

    # field_configs << {:field_type => 'TextField',
    #                   :field_name => 'module_function_type_code?required'}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'module_function_type_code?required',
                      :settings => {:list => module_function_types,
                                    :prompt => 'select a module_function_type_code'
                      }
    }

    field_configs << {:field_type => 'TextField',
                      :field_name => 'ip?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'port?required'}

    field_configs << {:field_type => 'CheckBox',
                      :field_name => 'is_active'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'robot_printer_id'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'robot_printer_code'}

    field_configs <<  {:field_type => 'TextField',
                       :field_name => 'mac_address'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'name'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'parameters'}

    field_configs << {:field_type => 'CheckBox',
                      :field_name => 'button_multiples'}

    if is_edit
      field_configs << {:field_type => 'Screen',
                        :field_name => "messcada_peripherals",
                        :settings   => {:target_action => 'list_peripherals',
                                        :id_value      => modules.id,
                                        :width         => 1100,
                                        :height        => 300,
                                        :no_scroll     => true
                        }
      }

    end

    @submit_button_align = "left"
    set_form_layout '2',nil,1,14
    build_form(modules,field_configs,action,'modules',caption,is_edit)

  end

  def build_modules_grid(data_set,can_edit,can_delete,is_edit,is_select)

    column_configs = Array.new
    column_configs << {:field_type => 'text',:field_name => 'id', :col_width => 60}
    column_configs << {:field_type => 'text',:field_name => 'code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'facility_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'server_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'cluster_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'module_type_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'module_function_type_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'ip', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'port', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'is_active', :data_type => 'boolean', :col_width => 60}
    column_configs << {:field_type => 'text',:field_name => 'robot_printer_id', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'robot_printer_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'mac_address', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'name', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'parameters', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'button_multiples', :data_type => 'boolean', :col_width => 100}

    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit module',
                                                 :settings =>
                                                     {:link_text => 'edit',
                                                      :target_action => 'render_edit_module',
                                                      :id_column => 'id', :col_width => 100
                                                     }
      }
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete module',
                                                 :settings =>
                                                     {:link_text => 'delete',
                                                      :target_action => 'delete_module',
                                                      :id_column => 'id', :col_width => 100
                                                     }
      }
    end

    if is_edit
      grid_command = {:field_type => 'link_window_field', :field_name => 'add_modules',
                      :settings   => {
                          :host_and_port => request.host_with_port.to_s,
                          :controller    => request.path_parameters['controller'].to_s ,
                          :target_action => 'new_module',
                          :link_text     => "add modules"
                      }
      }
    end

    set_grid_min_height(150)
    set_grid_min_width(850)
    hide_grid_client_controls()
    return get_data_grid(data_set,column_configs,nil,nil,grid_command)

  end


  #messcada_peripherals

  def build_peripheral_form(peripheral,action,caption,is_edit,is_create_retry = nil)


    field_configs = Array.new

    comm_types = ["LAN","RS232","USB","KBDROBOT"]

    peripheral_types = ["DM","IM","Mark","Zebra","MS", "Metler", "Symbol", "IMP","Domino"]

    peripheral_group_types =["PRN","PRINTER","SCALE","SCANNER"]

    if is_edit
      id = peripheral.id
      link_values = MesscadaPeripheral.find_by_sql("select * from  messcada_peripherals MP
                                                    where MP.id = '#{id}'")
      if link_values.empty?
      else
        facility_code = link_values[0].facility_code
        server_code = link_values[0].server_code
        cluster_code = link_values[0].cluster_code
        module_code = link_values[0].module_code
      end

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'facility_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_facility_code',
                             :id_value      => facility_code,
                             :link_text     => "#{facility_code}"
                            }
      }

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'server_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_server_code',
                             :id_value      => server_code,
                             :link_text     => "#{server_code}"
                            }
      }

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'cluster_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_cluster_code',
                             :id_value      => cluster_code,
                             :link_text     => "#{cluster_code}"
                            }
      }

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'module_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_module_code',
                             :id_value      => module_code,
                             :link_text     => "#{module_code}"
                            }
      }

      field_configs << {:field_type => 'LabelField',
                        :field_name => 'code?required'}
    else
      field_configs << {:field_type => 'TextField',
                        :field_name => 'code?required'}
    end

    # field_configs << {:field_type => 'TextField',
    #                   :field_name => 'peripheral_type_id?required'}
    #
    # field_configs <<  {:field_type => 'TextField',
    #                    :field_name => 'peripheral_type_code?required'}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'peripheral_type_code?required',
                      :settings => {:list => peripheral_types,
                                    :prompt => 'select a peripheral_type'
                      }
    }

    # field_configs << {:field_type => 'TextField',
    #                   :field_name => 'peripheral_group_id?required'}
    #
    # field_configs << {:field_type => 'TextField',
    #                   :field_name => 'peripheral_group_code?required'}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'peripheral_group_code?required',
                      :settings => {:list => peripheral_group_types,
                                    :prompt => 'select a peripheral_group_type'
                      }
    }

    field_configs << {:field_type => 'CheckBox',
                      :field_name => 'is_active'}

    # field_configs << {:field_type => 'TextField',
    #                   :field_name => 'comms_type_id?required'}
    #
    # field_configs << {:field_type => 'TextField',
    #                   :field_name => 'comms_type_code?required'}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'comms_type_code?required',
                      :settings => {:list => comm_types#,
                                    #:prompt => 'select a comm_type'
                      }
    }

    field_configs << {:field_type => 'TextField',
                      :field_name => 'ip?required'}

    field_configs <<  {:field_type => 'TextField',
                       :field_name => 'port?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'baud?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'parity'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'databooleans?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'stopboolean?required'}

    field_configs <<  {:field_type => 'TextField',
                       :field_name => 'flow_control?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'start_of_input'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'end_of_input'}

    field_configs << {:field_type => 'CheckBox',
                      :field_name => 'messages'}

    field_configs << {:field_type => 'CheckBox',
                      :field_name => 'button'}

    field_configs <<  {:field_type => 'TextField',
                       :field_name => 'button_tooltip?required'}

    field_configs << {:field_type => 'CheckBox',
                      :field_name => 'keyboard_robot'}

    field_configs <<  {:field_type => 'TextArea',
                       :field_name => 'input_buffer_length?required'}

    field_configs <<  {:field_type => 'TextArea',
                       :field_name => 'output_buffer_length?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'timeout_milli_seconds?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'device_name?required'}

    field_configs <<  {:field_type => 'TextField',
                       :field_name => 'mac_address'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'parameters?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'communication_parameters?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'network_parameters?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'dbms_parameters?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'application_parameters?required'}

    if is_edit

      field_configs << {:field_type => 'Screen',
                        :field_name => "messcada_peripheral_printers",
                        :settings   => {:target_action => 'list_peripheral_printers',
                                        :id_value      => peripheral.id,
                                        :width         => 1100,
                                        :height        => 300,
                                        :no_scroll     => true
                        }
      }

    end

    @submit_button_align = "left"
    set_form_layout '2',nil,1,32
    build_form(peripheral,field_configs,action,'peripheral',caption,is_edit)

  end

  def build_peripherals_grid(data_set,can_edit,can_delete,is_edit,is_select)

    column_configs = Array.new
    column_configs << {:field_type => 'text',:field_name => 'id', :col_width => 60}
    column_configs << {:field_type => 'text',:field_name => 'code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'facility_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'server_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'cluster_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'module_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'peripheral_type_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'peripheral_group_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'is_active', :data_type => 'boolean', :col_width => 60}
    column_configs << {:field_type => 'text',:field_name => 'comms_type_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'ip', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'port', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'baud', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'parity', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'databooleans', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'stopboolean', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'flow_control', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'start_of_input', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'end_of_input', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'messages', :data_type => 'boolean', :col_width => 60} #boolean
    column_configs << {:field_type => 'text',:field_name => 'button', :data_type => 'boolean', :col_width => 60} #boolean
    column_configs << {:field_type => 'text',:field_name => 'button_tooltip', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'keyboard_robot', :data_type => 'boolean', :col_width => 60} #boolean
    column_configs << {:field_type => 'text',:field_name => 'input_buffer_length', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'output_buffer_length', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'timeout_milli_seconds', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'device_name', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'mac_address', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'parameters', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'communication_parameters', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'network_parameters', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'dbms_parameters', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'application_parameters', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'id', :col_width => 60}

    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit peripheral',
                                                 :settings =>
                                                     {:link_text => 'edit',
                                                      :target_action => 'render_edit_peripheral',
                                                      :id_column => 'id', :col_width => 100
                                                     }
      }
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete peripheral',
                                                 :settings =>
                                                     {:link_text => 'delete',
                                                      :target_action => 'delete_peripheral',
                                                      :id_column => 'id', :col_width => 100
                                                     }
      }
    end

    if is_edit
      grid_command = {:field_type => 'link_window_field', :field_name => 'add_peripheral',
                      :settings   => {
                          :host_and_port => request.host_with_port.to_s,
                          :controller    => request.path_parameters['controller'].to_s ,
                          :target_action => 'add_peripherals',
                          :link_text     => "add peripheral"
                      }
      }
    end

    if is_select
      @multi_select = "selected_peripherals"
    end

    set_grid_min_height(150)
    set_grid_min_width(850)
    hide_grid_client_controls()
    return get_data_grid(data_set,column_configs,nil,nil,grid_command)

  end


  #messcada_peripherals

  def build_peripheral_printer_form(peripheral_printer,action,caption,is_edit,is_create_retry = nil)


    field_configs = Array.new

    if is_edit
      id = peripheral_printer.id
      link_values = MesscadaPeripheral.find_by_sql("select MPP.*,MP.module_code,MP.cluster_code,MP.server_code,MP.facility_code from  messcada_peripheral_printers MPP
                                                    inner join messcada_peripherals MP on MPP.peripheral_id = MP.id
                                                    where MPP.id = #{id}")
      if link_values.empty?
      else
        facility_code = link_values[0].facility_code
        server_code = link_values[0].server_code
        cluster_code = link_values[0].cluster_code
        module_code = link_values[0].module_code
        peripheral_code = link_values[0].peripheral_code
      end

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'facility_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_facility_code',
                             :id_value      => facility_code,
                             :link_text     => "#{facility_code}"
                            }
      }

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'server_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_server_code',
                             :id_value      => server_code,
                             :link_text     => "#{server_code}"
                            }
      }

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'cluster_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_cluster_code',
                             :id_value      => cluster_code,
                             :link_text     => "#{cluster_code}"
                            }
      }

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'module_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_module_code',
                             :id_value      => module_code,
                             :link_text     => "#{module_code}"
                            }
      }

      field_configs << {:field_type =>'LinkWindowField', :field_name => 'peripheral_code',
                        :settings   =>
                            {:controller    => request.path_parameters['controller'].to_s ,
                             :target_action => 'link_to_peripheral_code',
                             :id_value      => peripheral_code,
                             :link_text     => "#{peripheral_code}"
                            }
      }

    end

    field_configs << {:field_type => 'TextField',
                      :field_name => 'internal_template_file'}

    field_configs <<  {:field_type => 'TextField',
                       :field_name => 'internal_font_file'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'label_template_file'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'label_mode?required'}

    # field_configs << {:field_type => 'CheckBox',
    #                   :field_name => 'is_active'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'gtin_mode?required'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'do_maximum_label?required'}

    field_configs << {:field_type => 'CheckBox',
                      :field_name => 'apply_maximum_label_use'}

    field_configs <<  {:field_type => 'TextField',
                       :field_name => 'render_amount?required'}

    # if is_edit
    #   field_configs << {:field_type => 'Screen',
    #                     :field_name => "messcada_servers",
    #                     :settings   => {:target_action => 'list_servers',
    #                                     :id_value      => peripheral_printer.id,
    #                                     # :width         => 1100,
    #                                     # :height        => 300,
    #                                     :no_scroll     => true}}
    # end

    @submit_button_align = "left"
    set_form_layout '2',nil,1,8
    build_form(peripheral_printer,field_configs,action,'peripheral_printer',caption,is_edit)

  end

  def build_peripheral_printers_grid(data_set,can_edit,can_delete,is_edit)

    column_configs = Array.new
    column_configs << {:field_type => 'text',:field_name => 'id', :col_width => 60}
    column_configs << {:field_type => 'text',:field_name => 'facility_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'server_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'cluster_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'module_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'peripheral_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'internal_template_file', :col_width => 100}
    # column_configs << {:field_type => 'text',:field_name => 'is_active', :data_type => 'boolean', :col_width => 60}
    column_configs << {:field_type => 'text',:field_name => 'internal_font_file', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'label_template_file', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'label_mode', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'gtin_mode', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'do_maximum_label', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'apply_maximum_label_use', :data_type => 'boolean', :col_width => 60} #boolean
    column_configs << {:field_type => 'text',:field_name => 'render_amount', :col_width => 100}

    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit peripheral printer',
                         :settings =>
                             {:link_text => 'edit',
                              :target_action => 'render_edit_peripheral_printer',
                              :id_column => 'id', :col_width => 100
                             }
      }
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete peripheral printer',
                         :settings =>
                             {:link_text => 'delete',
                              :target_action => 'delete_peripheral_printer',
                              :id_column => 'id', :col_width => 100
                             }
      }
    end

    if is_edit
      grid_command = {:field_type => 'link_window_field', :field_name => 'add_peripheral_printer',
                      :settings   => {
                          :host_and_port => request.host_with_port.to_s,
                          :controller    => request.path_parameters['controller'].to_s ,
                          :target_action => 'new_peripheral_printer',
                          :link_text     => "add peripheral printer"
                      }
      }
    end

    set_grid_min_height(150)
    set_grid_min_width(850)
    hide_grid_client_controls()
    return get_data_grid(data_set,column_configs,nil,nil,grid_command)

  end

end