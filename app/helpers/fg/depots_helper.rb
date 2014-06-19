module Fg::DepotsHelper

  def build_depots_form(depot,action,caption, is_edit=nil,is_create_retry=nil)
    field_configs = Array.new

    location_codes = Location.find_by_sql("SELECT DISTINCT location_code FROM locations").map{|g|[g.location_code]}
    location_codes.unshift("<empty>")

    party_names = PartiesRole.find_by_sql("SELECT DISTINCT party_name FROM parties_roles").map{|g|[g.party_name]}
    party_names.unshift("<empty>")

    if is_edit
      depot.set_location_code_and_party_name
    end

    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'depot_code'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'depot_short_code'}
    field_configs[field_configs.length()] = {:field_type=>'TextArea', :field_name=>'depot_description'}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'location_code', :settings=>{:list=>location_codes}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'party_name', :settings=>{:list=>party_names}}


    build_form(depot,field_configs,action,'depot',caption,is_edit)

  end

  def build_depots_grid(data_set,can_edit,can_delete)
      column_configs = Array.new
      data_set.each do |record|
        record.set_location_code_and_party_name
      end
    	column_configs[0] = {:field_type => 'text',:field_name => 'depot_code'}
      column_configs[1] = {:field_type => 'text',:field_name => 'depot_short_code'}
    	column_configs[2] = {:field_type => 'text',:field_name => 'depot_description'}
    	column_configs[3] = {:field_type => 'text',:field_name => 'location_code'}
      column_configs[4] = {:field_type => 'text',:field_name => 'party_name'}

      #	----------------------
      #	define action columns
      #	----------------------
      if can_edit
        column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit depot',
          :settings =>
             {:link_text => 'edit',
            :target_action => 'edit_depot',
            :id_column => 'id'}}
      end

      if can_delete
        column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete depot',
          :settings =>
             {:link_text => 'delete',
            :target_action => 'delete_depot',
            :id_column => 'id'}}
      end

      return get_data_grid(data_set,column_configs)
  end

  def build_depots_search_form(depot,action,caption,is_flat_search=nil)
      #	--------------------------------------------------------------------------------------------------
      #	Define an observer for each index field
      #	--------------------------------------------------------------------------------------------------
      session[:depots_search_form]= Hash.new
      #generate javascript for the on_complete ajax event for each combo
      search_combos_js = gen_combos_clear_js_for_combos(["depot_location_code","depot_party_name", "depot_depot_code"])
      #Observers for search combos
      location_code_observer  = {:updated_field_id => "party_name_cell",
               :remote_method => 'depots_location_code_search_combo_changed',
               :on_completed_js => search_combos_js["depot_location_code"]}

      session[:depots_search_form][:location_code_observer] = location_code_observer

      party_name_observer = {:updated_field_id=>"depot_code_cell",
               :remote_method =>"depot_party_name_search_combo_changed",
               :on_completed_js => search_combos_js["depot_party_name"]}

      session[:depots_search_form][:party_name_observer] = party_name_observer

      location_codes = Location.find_by_sql("SELECT DISTINCT l.location_code FROM locations l, depots d WHERE d.location_id=l.id").map{|g|[g.location_code]}
      location_codes.unshift("<empty>")

      party_names = nil
      depot_codes = nil

      if is_flat_search
        party_names = PartiesRole.find_by_sql("SELECT DISTINCT p.party_name FROM parties_roles p, depots d WHERE p.id=d.parties_role_id").map{|g|[g.party_name]}
        party_names.unshift("<empty>")
        depot_codes = Depot.find_by_sql("SELECT DISTINCT depot_code FROM depots").map{|g|[g.depot_code]}
        depot_codes.unshift("<empty>")
      else
        party_names = ["Select a value from location_code"]
        depot_codes = ["Select a value from party_name"]
      end

      field_configs = Array.new

      field_configs[0] =  {:field_type => 'DropDownField',
              :field_name => 'location_code',
              :settings => {:list => location_codes},
              :observer => location_code_observer}

      field_configs[1] =  {:field_type => 'DropDownField',
              :field_name => 'party_name',
              :settings => {:list => party_names},
              :observer => party_name_observer}

      field_configs[2] =  {:field_type => 'DropDownField',
              :field_name => 'depot_code',
              :settings => {:list => depot_codes}}

    build_form(depot,field_configs,action,'depot',caption,false)

  end

end
