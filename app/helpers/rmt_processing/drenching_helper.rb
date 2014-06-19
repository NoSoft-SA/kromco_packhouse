module RmtProcessing::DrenchingHelper

#   ==========================
#                           ==
#   Drench line helper code ==
#                           ==
#   ==========================
  def build_drenching_tree(drench_lines)
    begin

      menu1 = ApplicationHelper::ContextMenu.new("drench_lines", "drenching")
      #menu1.add_command("new drench line","/rmt_processing/drenching/new_drench_line")
      menu1.add_command("new drench line", url_for(:action => "new_drench_line"))

      menu2 = ApplicationHelper::ContextMenu.new("drench_line", "drenching")
      menu2.add_command("remove drench line", url_for(:action => "delete_drench_line"))
      menu2.add_command("add station", url_for(:action => "add_drench_station"))
      menu2.add_command("edit", url_for(:action => "edit_drench_line"))

# context menu for both drench_station node types
      menu3 = ApplicationHelper::ContextMenu.new("deactive_drench_station", "drenching")
      menu3.add_command("activate station", url_for(:action => "activate_drench_station"))
      menu3.add_command("add concentrate", url_for(:action => "new_drench_concentrate"))
      menu3.add_command("remove station", url_for(:action => "delete_drench_station"))
      menu3.add_command("edit", url_for(:action => "edit_drench_station"))
      menu3.add_command("cancel concentrate changes", url_for(:action => "cancel_concentrate_changes"))
      menu3.add_command("commit concentrate changes", url_for(:action => "commit_concentrate_changes"))

      menu5 = ApplicationHelper::ContextMenu.new("active_drench_station", "drenching")
      menu5.add_command("deactivate station", url_for(:action => "deactivate_drench_station"))
      menu5.add_command("add concentrate", url_for(:action => "new_drench_concentrate"))
      menu5.add_command("remove station", url_for(:action => "delete_drench_station"))
      menu5.add_command("edit", url_for(:action => "edit_drench_station"))
      menu5.add_command("cancel concentrate changes", url_for(:action => "cancel_concentrate_changes"))
      menu5.add_command("commit concentrate changes", url_for(:action => "commit_concentrate_changes"))
# -------------------------------------------------------------------------------------------------------
      menu4 = ApplicationHelper::ContextMenu.new("drench_concentrate", "drenching")
      menu4.add_command("remove", url_for(:action => "delete_drench_concentrate"))
      menu4.add_command("edit quantity", url_for(:action => "edit_drench_concentrate"))


      root_node = ApplicationHelper::TreeNode.new("drenching", "drench_lines", true, "drenching")
      drench_lines.each do |drench_line|
        drench_line_node = root_node.add_child(drench_line.drench_line_code.chomp, "drench_line", drench_line.id.to_s)
        drench_line.drench_stations.each do |drench_station|
          if drench_station.drench_status_code == 'active'
            drench_station_node = drench_line_node.add_child(drench_station.drench_station_code.chomp, "active_drench_station", drench_station.id.to_s)
          else
            drench_station_node = drench_line_node.add_child(drench_station.drench_station_code.chomp, "deactive_drench_station", drench_station.id.to_s)
          end
          drench_station.drench_concentrates.each do |drench_concentrate|
            drench_concentrate_node_name = drench_concentrate.concentrate_code.chomp + ": " + drench_concentrate.concentrate_quantity.to_s + drench_concentrate.uom
            drench_concentrate_node = drench_station_node.add_child(drench_concentrate_node_name, "drench_concentrate", drench_concentrate.id.to_s)
          end
        end

      end

      tree = ApplicationHelper::TreeView.new(root_node, "drenching")
      tree.add_context_menu(menu1)
      tree.add_context_menu(menu2)
      tree.add_context_menu(menu3)
      tree.add_context_menu(menu5)
      tree.add_context_menu(menu4)


      tree.render


    rescue
      raise "The drench_lines tree could not be rendered. Exception reported is \n" + $!
    end
  end

  def build_drench_line_form(drench_line, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:drench_line_form]= Hash.new
    drench_line_type_codes = DrenchLineType.find_by_sql('select distinct drench_line_type_code from drench_line_types').map { |g| [g.drench_line_type_code] }
    drench_line_type_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new

#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (drench_line_type_id) on related table: drench_line_types
#	-----------------------------------------------------------------------------------------------------
    if is_edit
      field_configs[field_configs.length] = {:field_type => 'LabelField',
                                             :field_name => 'drench_line_type_code'} #,
#						:non_db_field => true,
#						:settings =>{:static_value => drench_line.drench_line_type_code,:show_label => true}}
    else
      field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                              :field_name => 'drench_line_type_code',
                                              :settings => {:list => drench_line_type_codes}}
    end

    field_configs[field_configs.length] = {:field_type => 'TextField',
                                           :field_name => 'drench_line_code'}

    field_configs[field_configs.length] = {:field_type => 'TextField',
                                           :field_name => 'drench_line_description'}


    build_form(drench_line, field_configs, action, 'drench_line', caption, is_edit)

  end

#   =============================
#                              ==
#   Drench station helper code ==
#                              ==
#   =============================
  def build_drench_station_form(drench_station, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:drench_station_form]= Hash.new

    #generate javascript for the on_complete ajax event for each combo
#	search_combos_js = gen_combos_clear_js_for_combos(["drench_station_drench_status_code"])
#    puts ".......WTF........ " + search_combos_js["drench_station_drench_status_code"].to_s

    on_complete_js = "\n img = document.getElementById('img_drench_station_drench_status_code');"
    on_complete_js += "\n if(img != null)img.style.display = 'none';"
    #Observers for search combos
    drench_status_code_observer  = {:updated_field_id => "deactive_reason_cell",
                                    :remote_method => 'drench_station_drench_status_code_combo_changed',
                                    :on_completed_js => on_complete_js}


    session[:drench_station_form][:drench_status_code_observer] = drench_status_code_observer

    drench_status_codes = DrenchStatus.find_by_sql('select distinct drench_status_code from drench_statuses').map { |g| [g.drench_status_code] }
    drench_status_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
    if !is_edit
      field_configs[field_configs.length()] =  {:field_type => 'DropDownField', :field_name => 'drench_status_code',
                                                :settings => {:list => drench_status_codes}, :observer => drench_status_code_observer}

      field_configs[field_configs.length] = {:field_type => 'TextField', :field_name => 'drench_station_code'}
    else
      field_configs[field_configs.length()] =  {:field_type => 'LabelField', :field_name => 'drench_status_code'}

      field_configs[field_configs.length] = {:field_type => 'LabelField',
                                             :field_name => 'drench_station_code'}
    end

    field_configs[field_configs.length] = {:field_type => 'TextField',
                                           :field_name => 'drench_station_description'}

    field_configs[field_configs.length()] = {:field_type =>'PopupDateRangeSelector',
                                             :field_name =>'date'}

    if !is_edit
      field_configs[field_configs.length] = {:field_type => 'LabelField',
                                             :field_name => 'deactive_reason'}
    elsif drench_station.drench_status_code == "inactive"
      field_configs[field_configs.length] = {:field_type => 'TextField',
                                             :field_name => 'deactive_reason'}
    end

#else
#
#puts "iyangena ku-isEdit"
#puts "isEdit = " + is_edit.class.name.to_s
#
##	----------------------------------------------------------------------------------------------
##	Combo fields to represent foreign key (resource_id) on related table: resources
##	----------------------------------------------------------------------------------------------
#	field_configs[field_configs.length] =  {:field_type => 'LabelField',
#						:field_name => 'drench_status_code'}
##   ----------------------------------------------------------------------------------------------
#   field_configs[field_configs.length] = {:field_type => 'LabelField',
#						:field_name => 'drench_station_code'}
#
#   field_configs[field_configs.length] = {:field_type => 'TextField',
#						:field_name => 'drench_station_description'}
# if drench_station.drench_status_code == 'active'
#    field_configs[field_configs.length] = {:field_type => 'DateTimeField',
#						:field_name => 'date_active_from'}
#
#	field_configs[field_configs.length] = {:field_type => 'DateTimeField',
#						:field_name => 'date_active_to'}
#
#	field_configs[field_configs.length] = {:field_type => 'LabelField',
#						:field_name => 'date_deactivated_from'}
#
#	field_configs[field_configs.length] = {:field_type => 'LabelField',
#						:field_name => 'date_deactivated_to'}
#
#	field_configs[field_configs.length] = {:field_type => 'LabelField',
#						:field_name => 'deactive_reason'}
#
#  elsif drench_station.drench_status_code == 'deactivated'
#
#     field_configs[field_configs.length] = {:field_type => 'LabelField',
#						:field_name => 'date_active_from'}
#
#	field_configs[field_configs.length] = {:field_type => 'LabelField',
#						:field_name => 'date_active_to'}
#
#	field_configs[field_configs.length] = {:field_type => 'DateTimeField',
#						:field_name => 'date_deactivated_from'}
#
#	field_configs[field_configs.length] = {:field_type => 'DateTimeField',
#						:field_name => 'date_deactivated_to'}
#
#	field_configs[field_configs.length] = {:field_type => 'TextField',
#						:field_name => 'deactive_reason'}
#
#  else
#
#    field_configs[field_configs.length] = {:field_type => 'LabelField',
#						:field_name => 'date_active_from'}
#
#	field_configs[field_configs.length] = {:field_type => 'LabelField',
#						:field_name => 'date_active_to'}
#
#	field_configs[field_configs.length] = {:field_type => 'LabelField',
#						:field_name => 'date_deactivated_from'}
#
#	field_configs[field_configs.length] = {:field_type => 'LabelField',
#						:field_name => 'date_deactivated_to'}
#
#	field_configs[field_configs.length] = {:field_type => 'LabelField',
#						:field_name => 'deactive_reason'}
#  end
#end
#    field_configs[field_configs.length()] = {:field_type => 'HiddenField',
#						:field_name => 'ajax_distributor',
#						:non_db_field => true}

    build_form(drench_station, field_configs, action, 'drench_station', caption, is_edit)

  end


#   ===================================
#                                    ==
#   Concentrate products helper code ==
#                                    ==
#   ===================================

  def build_concentrate_product_form(concentrate_product, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:concentrate_product_form]= Hash.new
    product_codes = Product.find_by_sql('select distinct product_code from products').map { |g| [g.product_code] }
    product_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
    if is_edit
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'concentrate_code'}
    else
      field_configs[field_configs.length()] = {:field_type => 'TextField',
                                               :field_name => 'concentrate_code'}
    end

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'concentrate_description'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'uom'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'min_quantity'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'max_quantity'}

    field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'date_from'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (product_id) on related table: products
#	----------------------------------------------------------------------------------------------
#	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
#						:field_name => 'product_code',
#						:settings => {:list => product_codes}}

    build_form(concentrate_product, field_configs, action, 'concentrate_product', caption, is_edit)

  end

  def build_concentrate_product_grid(data_set, can_edit, can_delete)

    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'concentrate_code', :col_width=> 110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'product_type_code', :col_width=> 165}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'concentrate_description', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'uom', :col_width=> 126}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'min_quantity', :col_width=> 50}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'max_quantity', :col_width=> 53}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'date_from', :col_width=> 120}
#	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'date_to'}
#	----------------------
#	define action columns
#	----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit concentrate_product', :col_width=> 35,
                                                 :settings =>
                                                         {:image => 'edit',
                                                          :target_action => 'edit_concentrate_product',
                                                          :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete concentrate_product', :col_width=> 35,
                                                 :settings =>
                                                         {:image => 'delete',
                                                          :target_action => 'delete_concentrate_product',
                                                          :id_column => 'id'}}
    end


#-------------------------------Child Grid test-----------------------------------
#	  action_columns = Array.new
#      action_column = {:field_type => 'action',:field_name => 'list concentrate product',
#			:settings => 
#				 {:link_text => 'view',
#				:target_action => 'view_concentrate_product',
#				:id_column => 'id'}}
#      action_columns[0] = action_column
#	column_configs = gen_grid_column_configs(data_set[0],action_columns,nil,nil)
#	
#	
##	---------------------------------
##	 Define fields to build form from
##	---------------------------------
#	 field_configs = Array.new
#	 
#	 field_configs[field_configs.length()] = {:field_type => 'TextField',
#						:field_name => 'concentrate_description'}
#	 
#	 field_configs[field_configs.length()] = {:field_type => 'ChildForm',
#						:field_name => "child_form",
#						:settings =>{:target_action => 'Luks_method',
#						             :id_column => nil,
#						             :request => request}}
#   puts "URL == " + request.host_with_port + request.path
#						
#	 build_form(data_set[0],field_configs,"test caption",'concentrate_product',"test",nil)
#-----------------------------------------------------------------------------------

    return get_data_grid(data_set, column_configs)
  end

#   =================================
#                                  ==
#   Drench concenctate helper code ==
#                                  ==
#   =================================
  def build_drench_concentrate_form(drench_concentrate, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:drench_concentrate_form]= Hash.new
    concentrate_codes = ConcentrateProduct.find_by_sql('select distinct concentrate_code from concentrate_products').map { |g| [g.concentrate_code] }
    concentrate_codes.unshift("<empty>")
#	drench_line_type_codes = DrenchStation.find_by_sql('select distinct drench_line_type_code from drench_stations').map{|g|[g.drench_line_type_code]}
#	drench_line_type_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (drench_station_id) on related table: drench_stations
#	-----------------------------------------------------------------------------------------------------
#	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
#						:field_name => 'drench_line_type_code',
#						:settings => {:list => drench_line_type_codes}}
#

#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (concentrate_product_id) on related table: concentrate_products
#	-----------------------------------------------------------------------------------------------------
    if is_edit
      field_configs[field_configs.length] =  {:field_type => 'LabelField',
                                              :field_name => 'concentrate_code'}
    else
      field_configs[field_configs.length] =  {:field_type => 'DropDownField',
                                              :field_name => 'concentrate_code',
                                              :settings => {:list => concentrate_codes}}
    end

    field_configs[field_configs.length] = {:field_type => 'TextField',
                                           :field_name => 'concentrate_quantity'}

#    field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'date_created'}

    build_form(drench_concentrate, field_configs, action, 'drench_concentrate', caption, is_edit)

  end

  def build_search_drench_history_form(drench_history, action, caption)

    session[:drench_concentrate_history_search_form]= Hash.new

    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["drench_concentrate_history_drench_line_code"])
    on_complete_js = "\n img = document.getElementById('img_drench_concentrate_history_drench_line_code');"
    on_complete_js += "\n if(img != null)img.style.display = 'none';"

    drench_line_code_observer  = {:updated_field_id => "drench_station_code_cell",
                                  :remote_method => 'drench_concentrate_history_drench_line_code_combo_changed',
                                  :on_completed_js => on_complete_js} #search_combos_js["drench_concentrate_history_drench_line_code"]}

    session[:drench_concentrate_history_search_form][:drench_line_code_observer] = drench_line_code_observer

    drench_line_codes = DrenchLine.find_by_sql("select * from drench_lines").map { |g| [g.drench_line_code] }
    drench_line_codes.unshift("<empty>")

    drench_station_codes = ["Select a value from drench_line_code"]
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
#   ---------------------------------
    if drench_history
      drench_history.date_from = Time.parse(drench_history.date_from) if drench_history.date_from and drench_history.date_from != nil and drench_history.date_from.to_s.strip != ""
      drench_history.date_to = Time.parse(drench_history.date_to) if drench_history.date_to and drench_history.date_to != nil and drench_history.date_to.to_s.strip != ""
    end
    field_configs[field_configs.length()] =  {:field_type => 'PopupDateSelector',
                                              :field_name => 'date_from',
                                              :settings => {:date_textfield_id=>'from_date2from'}}

    field_configs[field_configs.length()] =  {:field_type => 'PopupDateSelector',
                                              :field_name => 'date_to',
                                              :settings => {:date_textfield_id=>'to_date2to'}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'drench_line_code',
                                              :settings => {:list => drench_line_codes},
                                              :observer => drench_line_code_observer}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'drench_station_code',
                                              :settings => {:list => drench_station_codes}}


    build_form(drench_history, field_configs, action, 'drench_concentrate_history', caption)
  end

  def get_drench_concentrate_histories_for_date(drench_concentrate_histories, for_date)
#puts "Doing it for date = " + for_date.strftime("%Y-%m-%d")
    for_date_drench_concentrate_histories = Array.new
    for drench_concentrate_history in drench_concentrate_histories
      #date = drench_concentrate_history.date_created.strftime("%Y-%m-%d")
      date_created = drench_concentrate_history.date_created.strftime("%Y-%m-%d")
      date_to_hist = drench_concentrate_history.date_to_history.strftime("%Y-%m-%d")
      #puts "::::::::::: (" + date +","+for_date.to_s + ")"
      #if date == for_date.strftime("%Y-%m-%d")
      if for_date.strftime("%Y-%m-%d") >= date_created && for_date.strftime("%Y-%m-%d") <= date_to_hist
        #puts "        (" +drench_concentrate_history.concentrate_code+","+date_created+","+date_to_hist+") ==== " + (for_date.strftime("%Y-%m-%d") <= date_to_hist).to_s
        for_date_drench_concentrate_histories.push(drench_concentrate_history)
      end
    end

    return for_date_drench_concentrate_histories
  end

  def group_by_date_to_history(drench_concentrate_histories)
    #prev_delivery_drench_station_ids = Array.new
    group_list = Array.new
    previous_record = drench_concentrate_histories[0]

    current_group_array = Array.new

    for drench_concentrate_history in drench_concentrate_histories
      #puts "====> [" + drench_concentrate_history.date_to_history.strftime("%Y-%m-%d") + " , "+ previous_record.date_to_history.strftime("%Y-%m-%d") + "]"
      if drench_concentrate_history.date_to_history == previous_record.date_to_history
        current_group_array.push(drench_concentrate_history)

      else
        group_list.push(current_group_array)
        current_group_array = Array.new
        current_group_array.push(drench_concentrate_history)
        previous_record = drench_concentrate_history
      end
    end
    group_list.push(current_group_array)

    return group_list
  end

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  def get_delivery_drench_concentrates(current_group_array)
    drench_concentrate_history = current_group_array[0] #current_group_array[0]
    delivery_drench_concentrates = DeliveryDrenchConcentrate.find_by_sql("select * from delivery_drench_concentrates where drench_station_code = '#{drench_concentrate_history.drench_station_code}' and drench_line_code = '#{drench_concentrate_history.drench_line_code}' and concentrate_code = '#{drench_concentrate_history.concentrate_code}' and concentrate_quantity = '#{drench_concentrate_history.concentrate_quantity}' and date_created > '#{drench_concentrate_history.date_created}' and date_created < '#{drench_concentrate_history.date_to_history}'")
    return delivery_drench_concentrates
  end

  def get_delivery_drench_concentrates_for_current_setup(current_setup)

  end

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


# --------------------------------------------------
#   Happymore's list delivery helper method --------
# --------------------------------------------------
  def build_delivery_grid(data_set, can_edit, can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text', :field_name => 'farm_code'}
    column_configs[1] = {:field_type => 'text', :field_name => 'pick_team'}
    column_configs[2] = {:field_type => 'text', :field_name => 'orchard_description'}
    column_configs[3] = {:field_type => 'text', :field_name => 'puc_code'}
    column_configs[4] = {:field_type => 'text', :field_name => 'rmt_variety_code'}
    column_configs[5] = {:field_type => 'text', :field_name => 'commodity_code'}
    column_configs[6] = {:field_type => 'text', :field_name => 'delivery_number_preprinted'}
    column_configs[7] = {:field_type => 'text', :field_name => 'delivery_number'}
    column_configs[8] = {:field_type => 'text', :field_name => 'delivery_description'}
    column_configs[9] = {:field_type => 'text', :field_name => 'pack_material_product_code'}
    column_configs[10] = {:field_type => 'text', :field_name => 'date_delivered'}
    column_configs[11] = {:field_type => 'text', :field_name => 'date_time_picked'}
    #column_configs[12] = {:field_type => 'text',:field_name => 'time_picked'}
    column_configs[12] = {:field_type => 'text', :field_name => 'quantity_full_bins'}
    column_configs[13] = {:field_type => 'text', :field_name => 'quantity_partial_units'}
    column_configs[14] = {:field_type => 'text', :field_name => 'quantity_empty_units'}
    column_configs[15] = {:field_type => 'text', :field_name => 'quantity_damaged_units'}
    column_configs[16] = {:field_type => 'text', :field_name => 'remarks'}
    column_configs[17] = {:field_type => 'text', :field_name => 'drench_delivery'}
    column_configs[18] = {:field_type => 'text', :field_name => 'sample_bins'}
    column_configs[19] = {:field_type => 'text', :field_name => 'operator_override'}
    column_configs[20] = {:field_type => 'text', :field_name => 'date_override'}
    column_configs[21] = {:field_type => 'text', :field_name => 'mrl_required'}
#	column_configs[22] = {:field_type => 'text',:field_name => 'grower_commitment_required'}
    column_configs[22] = {:field_type => 'text', :field_name => 'truck_registration_number'}
    column_configs[23] = {:field_type => 'text', :field_name => 'delivery_status'}
    column_configs[24] = {:field_type => 'text', :field_name => 'season_code'}
#	----------------------
#	define action columns
#	----------------------
    if can_edit == false
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'view delivery',
                                                 :settings =>
                                                         {:link_text => 'view',
                                                          :target_action => 'view_delivery',
                                                          :id_column => 'id'}}
    else
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'view concentrates',
                                                 :settings =>
                                                         {:link_text => 'view_concentrates',
                                                          :target_action => 'view_concentrates',
                                                          :id_column => 'id'}}
    end


    return get_data_grid(data_set, column_configs)
  end

  def build_delivery_form(delivery, action, caption, is_edit = nil, is_create_retry = nil)
    #	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:delivery_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    combos_js_for_delivery = gen_combos_clear_js_for_combos(["delivery_farm_code", "delivery_commodity_code"])

    on_complete_js_farm = "\n img = document.getElementById('img_delivery_farm_code');"
    on_complete_js_farm += "\n if(img != null) img.style.display = 'none';"

    farm_code_observer = {:updated_field_id =>'puc_code_cell',
                          :remote_method =>'farm_code_changed',
                          :on_completed_js =>combos_js_for_delivery["delivery_farm_code"]}

    on_complete_js = "\n img = document.getElementById('img_delivery_commodity_code');"
    on_complete_js += "\n if(img != null) img.style.display = 'none';"

    commodity_code_observer = {:updated_field_id =>'rmt_variety_code_cell',
                               :remote_method =>'commodity_code_changed',
                               :on_completed_js =>on_complete_js}

    session[:delivery_form][:farm_code_observer] = farm_code_observer
    session[:delivery_form][:commodity_code_observer] = commodity_code_observer

    farm_codes = nil
    commodity_codes = nil
    rmt_variety_codes = nil
    unit_type_codes = nil
    season_codes = nil

    commodity_code = nil
    rmt_variety_code =  nil
    season_code = nil

    if session[:new_delivery]!= nil
      farm_codes = Farm.find_by_sql("select distinct farm_code from farms").map { |g| [g.farm_code] }
      farm_codes.delete(session[:new_delivery][:farm_code])
      farm_codes.unshift(session[:new_delivery][:farm_code])
    else
      farm_codes = Farm.find_by_sql("select distinct farm_code from farms").map { |g| [g.farm_code] }
      farm_codes.unshift("<select>")
    end


    commodity_codes = RmtVariety.find_by_sql("select distinct commodity_code from rmt_varieties").map { |g| [g.commodity_code] }
    commodity_codes.unshift("<select>")

    bin_products = Delivery.get_unit_type_codes
    bin_products.unshift("<select>")

    season_codes = Season.find_by_sql("select distinct season_code from seasons").map { |g| [g.season_code] }
    season_codes.unshift("<select>")

    if delivery.farm_code!=nil
      rmt_variety_codes = ["select a value from commodity_code"]
      rmt_variety_codes.unshift(delivery.rmt_variety_code)
    else
      #find track slms indicator record with track_indicator_type_code = 'LOB'
      commodity_code_observer = nil
      track_slms_indicator = TrackSlmsIndicator.find_by_track_indicator_type_code("LOB")
      if track_slms_indicator != nil
        commodity_code = track_slms_indicator.commodity_code
        rmt_variety_code = track_slms_indicator.rmt_variety_code
        season_code = track_slms_indicator.season_code
        session[:delivery_form][:commodity_code] = commodity_code
        session[:delivery_form][:rmt_variety_code] = rmt_variety_code
        session[:delivery_form][:season_code] = season_code
        #update delivery commodity, rmt_variety, season codes attributes
        delivery.commodity_code = track_slms_indicator.commodity_code
        delivery.rmt_variety_code = track_slms_indicator.rmt_variety_code
        delivery.season_code = track_slms_indicator.season_code
      end
    end

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------

    field_configs = Array.new
    field_configs[0] = {:field_type => 'LabelField',
                        :field_name => 'farm_code'}

    field_configs[1] = {:field_type => 'LabelField',
                        :field_name => 'puc_code',
                        :settings =>{:css_class=>'delivery_label'}}

    field_configs[2] = {:field_type => 'LabelField',
                        :field_name => 'pick_team'}

    field_configs[3] = {:field_type => 'LabelField',
                        :field_name => 'orchard_description'}
    if delivery.farm_code!= nil
      field_configs[4] = {:field_type => 'LabelField',
                          :field_name => 'commodity_code'}

      field_configs[5] = {:field_type => 'LabelField',
                          :field_name => 'rmt_variety_code'}

      field_configs[6] = {:field_type => 'LabelField',
                          :field_name => 'season_code'}
    else
      field_configs[4] = {:field_type => 'LabelField',
                          :field_name => 'commodity_code',
                          :settings=>{:css_class=>'delivery_label'}}

      field_configs[5] = {:field_type => 'LabelField',
                          :field_name => 'rmt_variety_code',
                          :settings=>{:css_class=>'delivery_label'}}

      field_configs[6] = {:field_type => 'LabelField',
                          :field_name => 'season_code',
                          :settings=>{:css_class=>'delivery_label'}}
    end

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'delivery_number_preprinted'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'delivery_number',
                                             :settings=>{:css_class=>'delivery_label'}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'delivery_description'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'truck_registration_number'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'pack_material_product_code',
                                             :settings=>{:list=>bin_products}}

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
                                             :field_name => 'operator_override',
                                             :settings=>{:css_class=>'delivery_label'}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'date_override',
                                             :settings=>{:css_class=>'delivery_label'}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'drench_delivery',
                                             :settings=>{:css_class=>'delivery_label'}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'sample_bins',
                                             :settings=>{:css_class=>'delivery_label'}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'mrl_required',
                                             :settings=>{:css_class=>'delivery_label'}}

    if session[:new_delivery]!= nil
      if session[:new_delivery].delivery_status != nil && session[:new_delivery].delivery_status != ""
        field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                 :field_name => 'delivery_status',
                                                 :settings=>{:css_class =>'delivery_status',
                                                             :static_value =>session[:new_delivery].delivery_status, :show_label=>true}}
      else
        field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                 :field_name => 'delivery_status',
                                                 :settings=>{:css_class =>'delivery_status',
                                                             :static_value =>'capturing', :show_label=>true}}
      end
    else
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                               :field_name => 'delivery_status',
                                               :settings=>{:css_class =>'delivery_status',
                                                           :static_value =>'capturing', :show_label=>true}}
    end


#	field_configs[field_configs.length()] = {:field_type => 'CheckBox',
#						                    :field_name => 'grower_commitment_required'}

#	field_configs[field_configs.length()] = {:field_type=>'LinkField', :field_name=>'',
#                                             :settings=>{:link_text=>'Add track slms indicator',
#                                                         :target_action=>'add_delivery_track_indicator',
#                                                         :css_class=>'indicator_link', :show_label=>false}}

    if session[:new_delivery]!=nil
#        field_configs[field_configs.length()] = {:field_type=>'LinkField',
#                                                 :field_name=>'drenching',
#                                                 :settings=>{:link_text=>'allocate drench',
#                                                             :target_action=>'allocate_drench',
#                                                             :css_class=>'indicator_link'}}
#                                                             
#        field_configs[field_configs.length()] = {:field_type=>'LinkField',
#                                                 :field_name=>'mrl_data',
#                                                 :settings=>{:link_text=>'capture mrl',
#                                                             :target_action=>'capture_mrl_data',
#                                                             :css_class=>'indicator_link'}}

      field_configs[field_configs.length()] = {:field_type=>'LinkField',
                                               :field_name=>'grower_commitment',
                                               :settings=>{:link_text=>'grower commitment data',
                                                           :target_action=>'capture_grower_commitment_data',
                                                           :css_class=>'indicator_link'}}

    end


    build_form(delivery, field_configs, action, 'delivery', caption, is_edit)

  end

  def build_view_delivery_track_indicator_form(delivery_track_indicator, action, caption, is_edit=nil)

    field_configs = Array.new

    field_configs[0] = {:field_type=>'LabelField',
                        :field_name=>'track_indicator_type_code'}

    field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                             :field_name=>'commodity_code'}

    field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                             :field_name=>'rmt_variety_code'}

    field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                             :field_name=>'season_code'}

    field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                             :field_name=>'track_slms_indicator_code'}

    @rmt_variety = RmtVariety.find_by_sql("select * from rmt_varieties where rmt_variety_code = '#{delivery_track_indicator.rmt_variety_code}'")

    if @rmt_variety.length()!=0
      if @rmt_variety[0].drench_rmt!=nil || @rmt_variety[0].drench_rmt!=""
        field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                                 :field_name=>'rmt_variety:drench?',
                                                 :settings=>{:static_value=>'Yes', :show_label=>true}}
      else
        field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                                 :field_name=>'rmt_variety:drench?',
                                                 :settings=>{:static_value=>'No', :show_label=>true}}
      end

      if @rmt_variety[0].sample_percentage!=nil || @rmt_variety[0].sample_percentage!=""
        field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                                 :field_name=>'rmt_variety:sample bins?',
                                                 :settings=>{:static_value=>'Yes', :show_label=>true}}
      else
        field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                                 :field_name=>'rmt_variety:sample bins?',
                                                 :settings=>{:static_value=>'No', :show_label=>true}}
      end
    end

    track_slms = TrackSlmsIndicator.find_by_sql("select * from track_slms_indicators where track_slms_indicator_code = '#{delivery_track_indicator.track_slms_indicator_code}'")
    if track_slms.length()!=0
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
      session[:track_slms_indicator] = Hash.new
      session[:track_slms_indicator][:track_variable_1] = track_slms[0].track_variable_1
      session[:track_slms_indicator][:track_variable_2] = track_slms[0].track_variable_2

    end

    field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                             :field_name=>'track_variable_1'}

    field_configs[field_configs.length()] = {:field_type=>'LabelField',
                                             :field_name=>'track_variable_2'}

    build_form(delivery_track_indicator, field_configs, action, 'delivery_track_indicator', caption, is_edit)

  end

#===========================================================
#      end add track indicator to delivery code
#===========================================================


# --------------------------------------------------

  def build_delivery_drench_concentrate_grid(delivery_drench_concentrates)
    column_configs = Array.new

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'concentrate_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'concentrate_description'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'drench_status_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'concentrate_quantity'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'date_created'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'concentrate_quantity'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'uom'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'drench_station_code'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'drench_line_code'}

    grid = get_data_grid(delivery_drench_concentrates, column_configs)
  end

end