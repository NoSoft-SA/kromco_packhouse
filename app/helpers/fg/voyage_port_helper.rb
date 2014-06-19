module Fg::VoyagePortHelper


  def build_voyage_port_form(voyage_port, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:voyage_port_form]= Hash.new

    voyage_port_types = VoyagePortType.find_by_sql('select distinct voyage_port_type_code, id from voyage_port_types').map { |g| [g.voyage_port_type_code, g.id] }
#    voyage_port_types.unshift("<empty>")

    port_codes = Port.find_by_sql('select distinct port_code, id from ports').map { |g| [g.port_code, g.id] }
    port_codes.unshift("<empty>")


#	vessel_ids = Vessel.find_by_sql('SELECT vessel_name FROM vessels').map{|g|[g.vessel_name]}
#	vessel_ids.unshift("<empty>")

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (port_id) on related table: ports
#	-----------------------------------------------------------------------------------------------------


    if is_edit
      # blah
    else
      @voyage_port = VoyagePort.new
      @voyage_port.voyage_id = params[:id]
    end


    field_configs[0] = {:field_type=>'HiddenField', :field_name=>'voyage_id'}

    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'port_id',
                         :settings => {:list => port_codes}}

    field_configs[2] = {:field_type => 'TextField',
                        :field_name => 'port_sequence'}

    field_configs[3] = {:field_type => 'TextField',
                        :field_name => 'quay'}

    field_configs[4] =  {:field_type => 'DropDownField',
                         :field_name => 'voyage_port_type_id',
                         :settings => {:list => voyage_port_types}}

    field_configs[5] = {:field_type => 'PopupDateSelector',
                        :field_name => 'arrival_date'}

    field_configs[6] = {:field_type => 'PopupDateSelector',
                        :field_name => 'departure_date'}

    field_configs[7] = {:field_type => 'PopupDateSelector',
                        :field_name => 'departure_open_stack'}

    field_configs[8] = {:field_type => 'PopupDateSelector',
                        :field_name => 'departure_close_stack'}


    build_form(voyage_port, field_configs, action, 'voyage_port', caption, is_edit)

  end


  def build_voyage_port_search_form(voyage_port, action, caption, is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:voyage_port_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["voyage_port_port_id"])
    #Observers for search combos

    voyage_port_types = VoyagePortType.find_by_sql('select distinct voyage_port_type_code, id from voyage_port_types').map { |g| [g.voyage_port_type_code, g.id] }


#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'port_id',
                         :settings => {:list => voyage_port_types}}

    build_form(voyage_port, field_configs, action, 'voyage_port', caption, false)

  end


  def build_voyage_port_grid(data_set, can_edit, can_delete)

    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'voyage_id'}
#    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'voyage_port_type_id'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'port_id'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'port_sequence'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'quay'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'departure_date'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'arrival_date'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'departure_open_stack'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'departure_close_stack'}
#	----------------------
#	define action columns
#	----------------------
    column_configs[column_configs.length()] = {
            :field_type => 'link_window',
            #           :field_type => 'action',
            :field_name => 'edit voyage_port',
            :settings => {
                    :link_text => 'edit',
                    :target_action => 'edit_voyage_port',
                    :id_column => 'id'
            }
    }
    column_configs[column_configs.length()] = {
            :field_type => 'action',
            :field_name => 'delete voyage_port',
            :settings => {
                    :link_text => 'delete',
                    :target_action => 'delete_voyage_port',
                    :id_column => 'id'
            }
    }
    return get_data_grid(data_set, column_configs)
  end

end
