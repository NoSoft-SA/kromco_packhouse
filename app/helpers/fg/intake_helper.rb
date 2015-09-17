module Fg::IntakeHelper
 

  def build_printer_selection_form

    printers = Printer.find(:all).map { |p| [p.friendly_name] }

    field_configs = Array.new

    @printer = Printer.new
    if session[:intake_printer]
      printer = Printer.find_by_system_name(session[:intake_printer])
      @printer.friendly_name = printer.friendly_name
    end


    field_configs[0] = {:field_type => 'DropDownField',
                        :field_name => 'friendly_name',
                        :settings => {:list => printers}}

    build_form(@printer, field_configs, 'set_printer_submit', 'printer', 'save')


  end


  def build_intake_form(intake_headers_production,action,caption,is_edit,is_create_retry=nil)
    end_pos = 0
    #	--------------------------------------------------------------------------------------------------
    #	Define an observer for each index field
    #	--------------------------------------------------------------------------------------------------
    session[:intake_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    location_type_on_complete_js = "\n img = document.getElementById('img_intake_headers_production_location_type_code');"
    location_type_on_complete_js += "\n if(img != null)img.style.display = 'none';"

    #Observers for search combos
    location_type_code_observer  = {:updated_field_id => "location_code_cell",
             :remote_method => 'intake_location_type_code_search_combo_changed',
             :on_completed_js => location_type_on_complete_js}

    session[:intake_search_form][:location_type_code_observer] = location_type_code_observer

    org_codes = Organization.get_all_by_role('MARKETER',true).map{|o|[o.short_description]}
    org_codes.unshift("<empty>")

    location_types = LocationType.find_by_sql("select distinct location_type_code from location_types").map{|l|[l.location_type_code]}
    location_types.unshift("<empty>")

    if is_edit
      location_codes = [intake_headers_production.location_code]
    else
      location_codes = ["Select a value from location type above"]
    end

    field_configs = Array.new
    field_configs[field_configs.length] = {:field_type => "DropDownField",:field_name => "organization_code",
                                          :settings =>{:label_caption => "marketing org",:list =>org_codes}}
    field_configs[field_configs.length] = {:field_type => "TextField",:field_name => "order_number"}
    if is_edit
      field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "depot_pallet"}
    else
      field_configs[field_configs.length] = {:field_type => "CheckBox",:field_name => "depot_pallet"}
    end
    field_configs[field_configs.length] = {:field_type => "TextField",:field_name => "client_reference"}
    field_configs[field_configs.length] = {:field_type => "DropDownField",:field_name => "location_type_code",
                                          :observer => location_type_code_observer,
                                          :settings =>{:label_caption=> "location type",:list =>location_types}}
    field_configs[field_configs.length] = {:field_type => "DropDownField",:field_name => "location_code",
                                          :settings =>{:label_caption=> "location code",:list =>location_codes}}
    field_configs[field_configs.length] = {:field_type => "TextField",:field_name => "phytowaybill"}
    field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "header_status"}
    field_configs[field_configs.length] = {:field_type => "TextField",:field_name => "account_code"}
    if is_edit
      field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "consignment_note_number"}
      field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "inspector_number"}
      field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "inspection_point"}


      field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'',
                       :settings =>
                      {:show_label=>false,
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'process_history',
                       :id_column=>'id',
                       :link_text => 'process_history'}}

#    end_pos = field_configs.length()
      if intake_headers_production.representative_carton_number
         field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'representative_carton_number',
                       :settings =>
                      {
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'view_representative_carton',
                       :id_column=>'representative_carton_number',
                       :link_text => intake_headers_production.representative_carton_number.to_s,
                       :css_class=>'indicator_link'}}
      end

      if(IntakeHeadersProduction.can_print?(intake_headers_production.header_status))
        field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'print_intake',
                       :settings =>
                      {
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'print_intake',
                       :id_column=>'id',
                       :link_text => 'print_intake'}}

        field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'intake_report',
                       :settings =>
                      {
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'get_intake_report',
                       :id_column=>'id',
                       :link_text => 'get intake report'}}
      end

      if(IntakeHeadersProduction.can_send_edi?(intake_headers_production.header_status))
        field_configs[field_configs.length()] = {:field_type =>'LinkField',  :field_name =>'send_edi',
                            :settings =>{:link_text =>'send_edi' ,
                                         :target_action =>'send_edi',
                                         :id_column =>"id"}}
    end

      if intake_headers_production.representative_pallet_number
         flash[:error] = "Representative pallet with number: #{intake_headers_production.representative_pallet_number} no longer exists!" if ! Pallet.find_by_pallet_number(intake_headers_production.representative_pallet_number.to_s)
        field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'view_rep_pallet',
                       :settings =>
                      {
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'view_representative_pallet',
                       :id_column=>'representative_pallet_number',
                       :link_text => intake_headers_production.representative_pallet_number}}

        field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'representative_pallet',
                       :settings =>
                      {
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'representative_pallet_search',
                       :id_column=>'id',
                       :link_text => "get"}}#WRONG-FIX
        end_pos = field_configs.length()
        field_configs[field_configs.length()] = {:field_type => 'Screen',:field_name => "consignment_pallets",
                                                  :settings =>{:target_action => 'show_representative_pallets',
                                                               :id_value => intake_headers_production.consignment_note_number,#send correct id
                                                               :width => 980,
                                                               :request => request,
                                                               :no_scroll => true}}
      else
        field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'representative_pallet',
                       :settings =>
                      {
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'representative_pallet_search',
                       :id_column=>'id',
                       :link_text => "get"}}

        end_pos = field_configs.length()
      end
    end
    
    set_form_layout('1',nil,nil,end_pos)
    set_submit_button_align('left')

    build_form(intake_headers_production,field_configs,action,'intake_headers_production',caption,is_edit)
  end

 
  def build_view_intake_form(intake_headers_production,action,caption)

    
    field_configs = Array.new
    field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "organization_code"}
    field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "order_number"}
    field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "depot_pallet"}
    field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "client_reference"}
    field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "location_type_code"}
    field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "location_code"}
    field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "phytowaybill"}
    field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "header_status"}
    field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "consignment_note_number"}
    field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "inspector_number"}
    field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => "inspection_point"}
    field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'',
                       :settings =>
                      {:show_label=>false,
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'process_history',
                       :id_column=>'id',
                       :link_text => 'process_history'}}

    if intake_headers_production.representative_carton_number
       field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'representative_carton_number',
                     :settings =>
                    {
                     :host_and_port =>request.host_with_port.to_s,
                     :controller =>request.path_parameters['controller'].to_s ,
                     :target_action => 'view_representative_carton',
                     :id_column=>'representative_carton_number',
                     :link_text => intake_headers_production.representative_carton_number.to_s,
                     :css_class=>'indicator_link'}}
    end

    if(IntakeHeadersProduction.can_print?(intake_headers_production.header_status))
        field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'print_intake',
                       :settings =>
                      {
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'print_intake',
                       :id_column=>'id',
                       :link_text => 'print_intake'}}

        field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'intake_report',
                       :settings =>
                      {
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'get_intake_report',
                       :id_column=>'id',
                       :link_text => 'get_intake_report'}}
    end

    if(IntakeHeadersProduction.can_send_edi?(intake_headers_production.header_status))
      field_configs[field_configs.length()] = {:field_type =>'LinkField',  :field_name =>'send_edi',
                            :settings =>{:link_text =>'send_edi' ,
                                         :target_action =>'send_edi',
                                         :id_column =>"id"}}
    end

    if intake_headers_production.representative_pallet_number
      field_configs[ field_configs.length()]={:field_type=>'link_window_field',:field_name =>'view_rep_pallet',
                     :settings =>
                    {
                     :host_and_port =>request.host_with_port.to_s,
                     :controller =>request.path_parameters['controller'].to_s ,
                     :target_action => 'view_representative_pallet',
                     :id_column=>'representative_pallet_number',
                     :link_text => intake_headers_production.representative_pallet_number}}
       end_pos = field_configs.length()
      field_configs[field_configs.length()] = {:field_type => 'Screen',:field_name => "consignment_pallets",
                                                :settings =>{:target_action => 'show_representative_pallets',
                                                             :id_value => intake_headers_production.consignment_note_number,
                                                             :width => 980,
                                                             :request => request,
                                                             :no_scroll => true}}

      set_form_layout('1',nil,nil,end_pos)
      set_submit_button_align('left')
    end


    
    build_form(intake_headers_production,field_configs,action,'intake_headers_production',caption)
  end
 #_________________________________
  def build_view_carton_pallet_form(view_object,action,caption)

    field_configs = Array.new
    view_object.attributes.each do |key,val|
      field_configs[field_configs.length] = {:field_type => "LabelField",:field_name => key}
    end

    build_form(view_object,field_configs,action,'carton',caption,false)
  end

  def build_consigment_pallet_s_grid(data_set,multi_select)
    column_configs = Array.new

    if(!multi_select)
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'select',
			:settings =>
				 {:link_text => 'select',
				:target_action => 'select_representative_pallet',
				:id_column => 'pallet_number'}}
    end

    data_set[0].keys.each do |key|
      column_configs[column_configs.length()] = {:field_type => 'text',:field_name => key} if key != "id"
    end        
    
    if(multi_select)
      column_configs[column_configs.length()] = {:field_type => 'text',:field_name => "id"}
      @multi_select = "submit_selected_pallets"
    end

    return get_data_grid(data_set,column_configs,nil,true)
  end


  def build_list_intake_headers_production_grid(data_set)

    column_configs = Array.new
    puts "data_set[0]=" + data_set[0].class.to_s
     column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'change', :col_width => 44,
			:settings =>
				 {:image => 'edit_intake',
				:target_action => 'change_intake',
				:id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'cancel',:col_width => 44,
			:settings =>
				 {:image => 'cancel',
				:target_action => 'cancel_intake',
				:id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'mark_for_delete',:col_width => 44,
			:settings =>
				 {:image => 'mark_for_delete',
				:target_action => 'mark_for_delete',
				:id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete',:col_width => 44,
			:settings =>
				 {:image => 'delete_intake',
				:target_action => 'delete_intake',
				:id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'send_edi',:col_width => 44,
			:settings =>
				 {:image => 'send_edi',
				:target_action => 'send_edi',
				:id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'print',:col_width => 44,
                                                 :settings => {
                                                         :image => 'printer',
                                                         :target_action => 'print_intake_from_grid',
                                                         :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'report',:col_width => 44,
                                                     :settings => {
                                                             :image => 'report',
                                                             :target_action => 'get_intake_report',
                                                             :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit', :col_width => 44,
			:settings =>
				 {:image => 'edit',
				:target_action => 'edit_intake',
				:id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view',  :col_width => 44,
			:settings =>
				 {:image => 'view_intake',
				:target_action => 'view_intake',
				:id_column => 'id'}}
          
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'representative_carton',:col_width => 113,:column_caption => 'rep_carton'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'depot_pallet',:col_width => 60,:column_caption => 'is_depot_plt'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'created_on',:col_width => 136}
     column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'location_code',:col_width => 90}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'revision_number',:col_width => 42}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'intake_type_code',:col_width => 42}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'account_code',:col_width => 65}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'updated_on',:col_width => 132}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'organization_code',:column_caption => 'org',:col_width => 55}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'header_status',:col_width => 200}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'id',:col_width => 65}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'client_reference',:col_width => 65}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'inspector_number',:col_width => 60}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'exit_ref',:col_width => 80}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'exit_date_time',:col_width => 90}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'phytowaybill',:col_width => 97}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'order_number',:col_width => 72}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'location_type_code',:col_width => 87}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'intake_header_number',:column_caption => 'header_num',:col_width => 110}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'rw_run_id',:col_width => 100}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'inpsection_point',:col_width => 62}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'consignment_note_number',:column_caption => 'cons_num',:col_width => 100}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'representative_pallet_number',:col_width => 155}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'intake_header_edi_status',:col_width => 160}




    return get_data_grid(data_set,column_configs,MesScada::GridPlugins::Fg::ListIntakeHeaderGridPlugin.new,true)
  end

  def build_list_intake_header_pallets_grid(intake_header_pallets,is_view,has_gtin_check_rule=nil)

    require File.dirname(__FILE__) + "/../../../app/helpers/fg/intake_plugins.rb"
    
    column_configs = Array.new
    intake_header_pallets[0].keys.each do |key|
      column_configs[column_configs.length()] = {:field_type => 'text',:field_name => key}
    end

    if(!is_view)
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'remove',
        :settings =>
           {:link_text => 'remove',
          :target_action => 'remove_intake_header_pallet',
          :id_column => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'find_gtin',
        :settings =>
           {:link_text => 'find gtin',
          :target_action => 'find_gtin',
          :id_column => 'id'}}
    end

    hide_grid_client_controls
    set_grid_min_height(145)
    set_grid_min_width(900)
    if(has_gtin_check_rule)
      return get_data_grid(intake_header_pallets,column_configs,MesScada::GridPlugins::Fg::GtinCheckGridPlugin.new,true)
    else
      return get_data_grid(intake_header_pallets,column_configs,nil,true)
    end
  end

  def build_list_intake_header_productions_statusses_grid(data_set)

    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'intake_status_code'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'intake_status_date_time'}

    set_grid_min_height(340)
    set_grid_min_width(700)
    return get_data_grid(data_set,column_configs,nil,true)#,IntakePlugins::ListIntakeHeaderGridPlugin.new
  end
end
