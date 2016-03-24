module Fg::VoyageHelper
  def build_clone_voyage_form(voyage,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
session[:voyage_form]= Hash.new
 field_configs=[]
field_configs[field_configs.length()] = {:field_type => 'TextField',
					:field_name => 'voyage_code'}





build_form(voyage,field_configs,action,'voyage',caption,is_edit)

 end
  def build_complete_voyage_form(voyage,action,caption,is_edit = nil,is_create_retry = nil)
    field_configs = Array.new
    field_configs[field_configs.length()] = {:field_type => 'TextField', :non_db_field=>true,
    						:field_name => 'complete_voyages_older_than_n_days'}
    build_form(nil,field_configs,action,'voyage',caption,is_edit)


  end


 def build_voyage_form(voyage,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:voyage_form]= Hash.new
	vessel_codes = Vessel.find_by_sql('select distinct vessel_code from vessels').map{|g|[g.vessel_code]}
	vessel_codes.unshift("<empty>")


#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (vessel_id) on related table: vessels
#	-----------------------------------------------------------------------------------------------------
#    if session[:edit_voyage]==nil
#      field_configs[field_configs.length()] = {:field_type => 'LabelField',
#      						:field_name => 'vessel_code'}
#      field_configs[field_configs.length()] = {:field_type => 'LabelField',
#      						:field_name => 'voyage_number'}
#      field_configs[field_configs.length()] = {:field_type => 'LabelField',
#            						:field_name => 'voyage_code'}
#      field_configs[field_configs.length()] = {:field_type => 'LabelField',
#      						:field_name => 'voyage_description'}
#    else
      field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
      						:field_name => 'vessel_code',
                              :settings=>{:label_caption=>'vessel_code',
                              :list => vessel_codes}}


      	field_configs[field_configs.length()] = {:field_type => 'TextField',
      						:field_name => 'voyage_number'}

          field_configs[field_configs.length()] = {:field_type => 'TextField',
      						:field_name => 'voyage_code'}


      	field_configs[field_configs.length()] = {:field_type => 'TextArea',
      						:field_name => 'voyage_description'}
    #end


    #================================================
    #voyages ports
    #================================================

    if voyage && !voyage.new_record?
    field_configs[field_configs.length()] = {:field_type=>'Screen',
                                             :field_name=> "child_form1",
                                             :settings=>{:target_action=>'list_voyage_ports',
                                                         :id_value=> voyage.id.to_s, :width=>1100,:height=>300,
                                                        :no_scroll => true }}


    field_configs[field_configs.length()] = {:field_type=>'Screen',
                                             :field_name=> "child_form2",
                                             :settings=>{:target_action=>'list_load_voyages',
                                                      :id_value=>voyage.id.to_s, :width=>1100,:height=>300,
                                                     :no_scroll => true  }}

    end

    @submit_button_align = "left"

    set_form_layout "2",nil,1,4
#
#if voyage && voyage.status && voyage.status.upcase=="COMPLETED"
#  build_form(voyage,field_configs,nil,'voyage',caption,is_edit)
#
#else
  build_form(voyage,field_configs,action,'voyage',caption,is_edit)

#end

end



  def build_voyage_grid(data_set, can_edit, can_delete)

   column_configs = Array.new
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'voyage_number',:col_width=>118}
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'vessel_code',:col_width=>211}
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'voyage_code',:col_width=>112}
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'status',:col_width=>118}
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'voyage_description',:col_width=>235}

     if can_edit

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit',:col_width=>45,
                                                 :settings =>
                                                         {:link_text => 'edit',
                                                          :target_action => 'edit_voyage',
                                                          :id_column => 'id'}}

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'complete_voyage',:col_width=>45,
                                                       :settings =>
                                                               {:link_text => '',
                                                                :target_action => 'complete_voyage',
                                                                :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete',:col_width=>50,
                                                 :settings =>
                                                         {:link_text => 'delete',
                                                          :target_action => 'delete_voyage',
                                                          :id_column => 'id'}}
    end
    return get_data_grid(data_set, column_configs,MesScada::GridPlugins::Fg::VoyageGridPlugin.new(self,request),true)
  end





 def build_voyage_search_form(voyage,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:voyage_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	vessel_names = Voyage.find_by_sql('select distinct vessel_code from voyages').map{|g|[g.vessel_code]}
	vessel_names.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'vessel_code',
						:settings => {:label_caption=>'vessel_code',
                                      :list => vessel_names}}

	build_form(voyage,field_configs,action,'voyage',caption,false)

end

 def build_load_voyage_grid(data_set, can_edit, can_delete)

#, :col_width=> 43

   column_configs = Array.new
   #if session[:edit_voyage]==true
      if can_edit

        column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'edit',:col_width=> 34,
                                                   :settings =>
                                                           {:link_text => 'edit',
                                                            :target_action => 'edit_load_voyage_from_popup',
                                                             :id_column => 'id'}}

        end

      if can_delete
        column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete',:col_width=> 48,
                                                   :settings =>
                                                           {:link_text => 'delete',
                                                            :target_action => 'delete_load_voyage',
                                                            :id_column => 'id'}}

      end
    #end

   column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'voyage_ports',:col_width=> 62,
                                                    :settings =>
                                                            {:link_text => 'voyage_ports',
                                                             :target_action => 'list_load_voyage_ports',
                                                             :id_column => 'id',
                                                             :no_scroll => true}}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'load_number', :column_caption=>'load_num',:col_width=> 76}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'customer_reference', :column_caption=>'customer_ref',:col_width=> 90}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'booking_reference', :column_caption=>'booking_ref',:col_width=> 102}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exporter_certificate_code',:col_width=> 103}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exporter',:col_width=> 103}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'shipper',:col_width=> 103}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'shipping_agent',:col_width=> 103}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'shipping_line',:col_width=> 103}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'memo_pad'}

    set_grid_min_height(200)
    set_grid_min_width(850)
     hide_grid_client_controls()
return get_data_grid(data_set,column_configs,nil,nil,nil)
  end

  #=================== load voyages form for popup============
 def build_load_voyage_form(load_voyage, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	----------------------------------------------------------------_----------------------------------
    session[:load_voyage_form]= Hash.new




#   trading_partners = PartiesRole.find_by_sql("SELECT id, party_name FROM parties_roles WHERE role_name = 'TRADING_PARTNER'").map { |g| [g.party_name, g.id] }
    exporter_party_role_ids = PartiesRole.find_by_sql("SELECT DISTINCT id,party_name FROM public.parties_roles WHERE parties_roles.role_name = 'EXPORTER'").map { |g| [g.party_name, g.id] }


    shipper_party_role_ids = PartiesRole.find_by_sql("SELECT DISTINCT id,party_name FROM public.parties_roles WHERE parties_roles.role_name = 'SHIPPER'").map { |g| [g.party_name, g.id] }


    shipping_agent_party_role_ids = PartiesRole.find_by_sql("SELECT DISTINCT id,party_name FROM public.parties_roles WHERE parties_roles.role_name = 'SHIPPING AGENT'").map { |g| [g.party_name, g.id] }


    shipping_line_party_role_ids = PartiesRole.find_by_sql("SELECT DISTINCT id,party_name FROM public.parties_roles WHERE parties_roles.role_name = 'SHIPPING LINE'").map { |g| [g.party_name, g.id] }

   loads = Load.find_by_sql("SELECT DISTINCT id,load_number FROM loads where upper(load_status) = 'LOAD_CREATED'").map {|s|[s.load_number,s.id]}

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (load_id) on related table: loads
#	-----------------------------------------------------------------------------------------------------

   if is_edit == true
   field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                             :field_name => 'load_number'}

    else

      field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                                :field_name => 'load_id',
                                                :settings => {:label_caption=>'load_number',
                                                :list => loads}}
    end


    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'customer_reference'}

    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'booking_reference'}

    field_configs[field_configs.length()] =  {:field_type => 'TextField', :field_name => 'exporter_certificate_code'}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name=> 'exporter_party_role_id',
                                              :settings => {:label_caption => 'exporter',:show_label=> true,
                                                            :list => exporter_party_role_ids}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'shipper_party_role_id',
                                              :settings => {:label_caption=>'shipper',:show_label=> true,
                                                      :list => shipper_party_role_ids}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'shipping_agent_party_role_id',
                                              :settings => {:label_caption=>'shipping_agent',:show_label => true,
                                                      :list => shipping_agent_party_role_ids}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                              :field_name => 'shipping_line_party_id',
                                              :settings => {:label_caption=>'shipping_line',:show_label=> true,
                                                      :list => shipping_line_party_role_ids}}

    field_configs[field_configs.length()] = {:field_type => 'TextArea', :field_name => 'memo_pad'}


    build_form(load_voyage, field_configs, action, 'load_voyage', caption, is_edit)

 end

  #additions to voyage port
  #============================ voyage port grid ======================
 def build_voyage_port_grid(data_set,can_edit,can_delete)
    column_configs = Array.new

      if can_edit
        #if session[:edit_voyage]==true
         column_configs <<  {:field_type => 'link_window', :field_name => 'edit',
                                                 :settings =>
                                                         {:link_text => 'edit',
                                                          :target_action => 'edit_voyage_port_from_popup',
                                                         :id_column => 'id'}}

      #end
end
	if can_delete
    #if session[:edit_voyage]==true
		column_configs << {:field_type => 'action',:field_name => 'delete',
			:settings =>
				 {:link_text => 'delete',
				:target_action => 'delete_voyage_port',
				:id_column => 'id'}}
  #end
      end

   column_configs << {:field_type => 'text',:field_name => 'port_type_code'}
   column_configs <<  {:field_type => 'text',:field_name => 'port_code'}
   column_configs << {:field_type => 'text',:field_name => 'quay'}
   column_configs << {:field_type => 'text',:field_name => 'departure_date'}
   column_configs << {:field_type => 'text',:field_name => 'arrival_date'}
   column_configs << {:field_type => 'text',:field_name => 'departure_open_stack'}
   column_configs << {:field_type => 'text',:field_name => 'departure_close_stack'}


    set_grid_min_height(150)
    set_grid_min_width(850)
    hide_grid_client_controls()
return get_data_grid(data_set,column_configs,nil,true)
end

  #========================== voyage port form =========================
 def build_voyage_port_form(voyage_port,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:voyage_port_form]= Hash.new
	voyage_port_codes = VoyagePortType.find_by_sql('select distinct id,voyage_port_type_code from voyage_port_types').map{|g|[g.voyage_port_type_code,g.id]}
	voyage_port_codes.unshift("<empty>")

	port_codes = Port.find_by_sql('select distinct id,port_code from ports').map{|g|[g.port_code, g.id]}
	port_codes.unshift("<empty>")

    voyage_ids = Voyage.find_by_sql('select distinct id,voyage_code from voyages').map{|g|[g.voyage_code,g.id]}
	voyage_ids.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
   combos_js_for_voyage_port_type               = gen_combos_clear_js_for_combos(["voyage_port_voyage_port_type_id", "voyage_port_is_destination_port"])
   voyage_port_type_observer                      = {:updated_field_id => "is_destination_port_cell",
                                                :remote_method    =>'voyage_port_type_changed',
                                                :on_completed_js  =>  combos_js_for_voyage_port_type["voyage_port_voyage_port_type_id"]
       }


	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'port_id',
						:settings => {:label_caption=>'port_code',
                                :list => port_codes}}


	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'quay'}


	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'voyage_port_type_id',
						:settings => {:label_caption => 'voyage_port_type',:show_label=> true,
                                :list => voyage_port_codes}}#,:observer   =>  voyage_port_type_observer}



    field_configs[field_configs.length()] = {:field_type => 'PopupDateSelector',
						:field_name => 'departure_date'}

	field_configs[field_configs.length()] = {:field_type => 'PopupDateSelector',
						:field_name => 'arrival_date'}

	field_configs[field_configs.length()] = {:field_type => 'PopupDateSelector',
						:field_name => 'departure_open_stack'}

	field_configs[field_configs.length()] = {:field_type => 'PopupDateSelector',
						:field_name => 'departure_close_stack'}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'port_sequence'}
   field_configs[field_configs.length] = {:field_type => "CheckBox",:field_name => "is_destination_port"}


   build_form(voyage_port,field_configs,action,'voyage_port',caption,is_edit)

end

 def build_found_voyages_grid(data_set,can_edit,can_delete=nil)

   column_configs = Array.new
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'voyage_number',:col_width=>118}
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'status',:col_width=>118}

   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'vessel_code',:col_width=>211}
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'voyage_code',:col_width=>112}
   column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'voyage_description',:col_width=>235}

     if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit',:col_width=>45,
                                                 :settings =>
                                                         {:link_text => 'edit',
                                                          :target_action => 'edit_voyage',
                                                          :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete',:col_width=>50,
                                                 :settings =>
                                                         {:link_text => 'delete',
                                                          :target_action => 'delete_voyage',
                                                          :id_column => 'id'}}
    end

   return get_data_grid(data_set,column_configs,nil,true)

  end


def build_load_voyage_port_grid(data_set,can_edit,can_delete)
   column_configs = Array.new
   #if session[:edit_voyage]==true
   column_configs << {:field_type => 'link_window', :field_name => 'remove_load_voyage',
                                                    :settings =>
                                                            {:link_text => 'remove voyage port',
                                                             :target_action => 'remove_voyage_port_from_popup',
                                                             :id_column => 'id'}}
   grid_command =    {:field_type=>'link_window_field',:field_name =>'new_voyage_port',
                          :settings =>
                         {
                          :host_and_port =>request.host_with_port.to_s,
                          :controller =>request.path_parameters['controller'].to_s ,
                          :target_action => 'add_new_voyage_ports',
                          :link_text => "add new voyage port"}}

          #end
   column_configs <<{:field_type => 'text',:field_name => 'port_type_code'}
   column_configs <<{:field_type => 'text',:field_name => 'port_code'}
   column_configs << {:field_type => 'text',:field_name => 'quay'}
   column_configs <<{:field_type => 'text',:field_name => 'departure_date'}
   column_configs << {:field_type => 'text',:field_name => 'arrival_date'}
   column_configs << {:field_type => 'text',:field_name => 'departure_open_stack'}
   column_configs << {:field_type => 'text',:field_name => 'departure_close_stack'}


    set_grid_min_height(317)
    set_grid_min_width(770)
#if session[:edit_voyage]==nil
#  return get_data_grid(data_set,column_configs,nil,nil,nil)
#
#  else

return get_data_grid(data_set,column_configs,nil,nil,grid_command)
  #end
end


#============ popup grid
  def build_load_voyage_port_popup_grid(data_set,can_edit,can_delete)
     column_configs = Array.new
     column_configs[0]= {:field_type => 'action', :field_name => 'select_voyage_port',
                                                      :settings =>
                                                              {:link_text => 'select voyage port',
                                                               :target_action => 'select_voyage_port',
                                                               :id_column => 'id'}}

     column_configs[1] = {:field_type => 'text',:field_name => 'port_type_code'}
     column_configs[2] = {:field_type => 'text',:field_name => 'port_code'}
     column_configs[3] = {:field_type => 'text',:field_name => 'quay'}
     column_configs[4] = {:field_type => 'text',:field_name => 'departure_date'}
     column_configs[5] = {:field_type => 'text',:field_name => 'arrival_date'}
     column_configs[6] = {:field_type => 'text',:field_name => 'departure_open_stack'}
     column_configs[7] = {:field_type => 'text',:field_name => 'departure_close_stack'}

    set_grid_min_height(330)
    set_grid_min_width(770)


  return get_data_grid(data_set,column_configs,nil,nil,nil)
  end






end
