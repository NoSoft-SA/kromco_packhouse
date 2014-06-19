module RmtProcessing::BinLoadHelper
 
 
 def build_bin_load_form(bin_load,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:bin_load_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    load_types = LoadType.find(:all).map {|r|[r.load_type_code,r.id]}
    hauliers= PartiesRole.find_by_sql("SELECT id ,party_name FROM parties_roles WHERE role_name = 'HAULIER'").map { |g| [g.party_name, g.id] }
    locations =Location.find(:all).map{|g|[g.location_code,g.id]}

	 field_configs = Array.new
    if bin_load && !is_create_retry
    bin_load.bin_order_load_id = BinOrderLoad.find_by_bin_load_id(bin_load.id).id
    end
       field_configs[field_configs.length()] = {:field_type => 'LabelField',
                   :field_name => 'bin_order_load_id',:non_db_field=>true}

     field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'load_type_id',:settings =>{:list=>load_types,:label_caption=>'load type'}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'haulier_party_role_id',:settings=>{:list=>hauliers,:label_caption=>'haulier'}}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'vehicle_license_number'}
                                                                   
	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'weigh_bridge_location_id',:settings=>{:list=>locations,:label_caption=>'weigh bridge location'}}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'tare_mass_in'}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'tare_mass_out'}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'vehicle_empty_mass_in'}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'vehicle_full_mass_out'}

        if !is_create_retry && bin_load
       bin_load.status = BinOrderLoad.find_by_bin_load_id(bin_load.id).status
      field_configs[field_configs.length()] ={:field_type => 'TextField',
						:field_name => 'status'}

       field_configs[field_configs.length()] = {:field_type => 'LabelField',
                   :field_name => 'created_on'}


       stat =  bin_load.status.strip
      if stat.upcase =="LOADED"

    field_configs[field_configs.length()] = {:field_type => 'LinkField', :field_name => '',
                                             :settings => {:target_action => 'complete_load', :link_text => "complete_load", :id_value => bin_load.id}}
      end

       if  (stat.upcase == "LOADING"||stat.upcase =="LOAD_CREATED")

	field_configs[field_configs.length()] ={:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings => {
                                                       #:host_and_port =>request.host_with_port.to_s,
                                                       :controller =>"rmt_processing/bin_load",
                                                       #:target_action => 'new_line_item',
                                                       :target_action => 'add_load_details',
                                                       :link_text => "add_load_details",
                                                       #:width => 800
                                                       :id_value => bin_load.id } }

    end
    bin_order=BinOrder.find_by_sql("select order_types.order_type_code, parties_roles.party_name from order_types
                              inner join bin_orders on bin_orders.order_type_id= order_types.id
                              inner join bin_order_loads on bin_order_loads.bin_order_id=bin_orders.id
                              inner join bin_loads on bin_order_loads.bin_load_id=bin_loads.id
                              inner join parties_roles on bin_orders.trading_partner_party_role_id=parties_roles.id
                              where bin_loads.id=#{bin_load.id}")
    trading_partner_1st_letter = bin_order[0].party_name.split(//)

    menu1 = ApplicationHelper::ContextMenu.new("print_docs", "bin_load", true)

    if bin_load.status.upcase =="COMPLETE"

    menu1.add_command("delivery", "/rmt_processing/bin_load/delivery")
    menu1.add_command("pool_payments", "/rmt_processing/bin_load/pool_payments")
    if  bin_order[0].order_type_code=="NS" || trading_partner_1st_letter[0]== "2"
      else
      menu1.add_command("send_edi", "/rmt_processing/bin_load/send_edi")
    end
    end
    menu1.add_command("tripsheet", "/rmt_processing/bin_load/tripsheet")

    menu1.add_command("empty_bins", "/rmt_processing/bin_load/empty_bins")

    menu1.add_command("delivery_note", "/rmt_processing/bin_load/delivery_note")


    js = "<script src = '/javascripts/context_menu.js'></script>"
    js += "<script>"
    js += menu1.render
    js +="build_context_menus();"
    js +="</script>"

    field_configb = {:link_text => "print_docs",
                     :link_value => bin_load.bin_order_load_id.to_s,
                     :menu_name => "print_docs",
                     :css_class => "run_line_code_link_black"}
    popup_link = ApplicationHelper::PopupLink.new(nil, nil, 'none', 'none', 'none',field_configb, true, nil, self)

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name=>"",
                                             :non_db_field=>true,
                                             :settings=>{
                                                     :static_value=>js + popup_link.build_control,
                                                     :show_label=>true,
                                                     :css_class=>'unbordered_label_field'
                                             }
    }



    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form2",
                                             :settings =>{
                                                     #:host_and_port => request.host_with_port.to_s,
                                                     :controller => 'rmt_processing/bin_order_load_detail',
                                                     :target_action => 'list_bin_order_load_details',
                                                     :width => 1000,
                                                     :height => 250,
                                                     :id_value => bin_load.id,
                                                     :no_scroll => true}}


   end

   @submit_button_align = "left"
    if bin_load && bin_load.status == "LOADED"
      set_form_layout "1", nil, 0, 14

    elsif bin_load && (bin_load.status == "LOADING"  || bin_load.status =="LOAD_CREATED")
      set_form_layout "1", nil, 0, 14

    elsif bin_load &&  bin_load.status =="COMPLETE"
      set_form_layout "1", nil, 0, 13

    elsif !is_create_retry && bin_load
        set_form_layout "1", nil, 0, 14
   else
      set_form_layout "1", nil, 0,10
    end

	build_form(bin_load,field_configs,action,'bin_load',caption,is_edit)

end
 
 
 def build_bin_load_search_form(bin_load,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:bin_load_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	haulier_party_roles = BinLoad.find_by_sql('select distinct haulier_party_role from bin_loads').map{|g|[g.haulier_party_role]}
	haulier_party_roles.unshift("<empty>")
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'haulier_party_role',
						:settings => {:list => haulier_party_roles}}

	build_form(bin_load,field_configs,action,'bin_load',caption,false)

end



 def  build_order_load_grid(data_set,can_edit,can_delete)
    require File.dirname(__FILE__) + "/../../../app/helpers/rmt_processing/bin_load_plugins.rb"
	column_configs = Array.new


    grid_command =    {:field_type=>'link_window_field',:field_name =>'new_load_for_order',
                       :settings =>
                      {
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'new_load_for_order',
                       :link_text => "new_load_for_order"
                       }}

    if can_edit
		column_configs << {:field_type => 'link_window',:field_name => 'edit',:col_width=>30,
			:settings =>
				 {:image => 'edit',
				:target_action => 'edit_order_load',
				:id_column => 'id'}}
    end
      column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'status_history',:col_width=>68,
             :settings =>
                {:link_text => 'status_history',
               :target_action => 'status_history',
               :id_column => 'id'}}


#	if can_delete
#		column_configs << {:field_type => 'action',:field_name => 'delete bin_load',
#			:settings =>
#				 {:link_text => 'delete',
#				:target_action => 'delete_bin_load',
#				:id_column => 'id'}}
#	end
	column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'bin_load_num',:col_width=>89}
    column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'status',:col_width=>130}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'haulier',:col_width=>208}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'vehicle_license_number',:col_width=>105}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'weigh_bridge_location',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'tare_mass_in',:col_width=>92}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'tare_mass_out',:col_width=>98}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'vehicle_empty_mass',:col_width=>129}
    column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'vehicle_full_mass',:col_width=>110}
    column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'created_on',:col_width=>134}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'load_type',:col_width=>125}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}
#	----------------------
#	define action columns
#	----------------------

 return get_data_grid(data_set,column_configs,RmtProcessingPlugins::BinOrderLoadGridPlugin.new, true,grid_command)
end

end
