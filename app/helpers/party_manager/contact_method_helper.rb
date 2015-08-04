module PartyManager::ContactMethodHelper


  #========================
  #ORGS POSTAL ADDRESS CODE
  #========================

  def build_parties_postal_address_form(parties_postal_address,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:parties_postal_address_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo for fk table: postal_addresses
    combos_js_for_postal_addresses = gen_combos_clear_js_for_combos(["parties_postal_address_postal_address_type_code","parties_postal_address_city","parties_postal_address_address1","parties_postal_address_address2"])
    combos_js_for_parties = gen_combos_clear_js_for_combos(["parties_postal_address_party_type_name","parties_postal_address_party_name"])
    #Observers for combos representing the key fields of fkey table: postal_address_id
    #generate javascript for the on_complete ajax event for each combo for fk table: parties
    combos_js_for_postal_addresses = gen_combos_clear_js_for_combos(["parties_postal_address_postal_address_type_code","parties_postal_address_city","parties_postal_address_address1","parties_postal_address_address2"])
    combos_js_for_parties = gen_combos_clear_js_for_combos(["parties_postal_address_party_type_name","parties_postal_address_party_name"])
    #Observers for combos representing the key fields of fkey table: party_id
    postal_address_type_code_observer  = {:updated_field_id => "city_cell",
                                          :remote_method => 'parties_postal_address_postal_address_type_code_changed',
                                          :on_completed_js => combos_js_for_postal_addresses ["parties_postal_address_postal_address_type_code"]}

    session[:parties_postal_address_form][:postal_address_type_code_observer] = postal_address_type_code_observer

    city_observer  = {:updated_field_id => "address1_cell",
                      :remote_method => 'parties_postal_address_city_changed',
                      :on_completed_js => combos_js_for_postal_addresses ["parties_postal_address_city"]}

    session[:parties_postal_address_form][:city_observer] = city_observer

    address1_observer  = {:updated_field_id => "address2_cell",
                          :remote_method => 'parties_postal_address_address1_changed',
                          :on_completed_js => combos_js_for_postal_addresses ["parties_postal_address_address1"]}

    session[:parties_postal_address_form][:address1_observer] = address1_observer

    #  combo lists for table: postal_addresses

    postal_address_type_codes = nil
    cities = nil
    address1s = nil
    address2s = nil

    #postal_address_type_codes = PartiesPostalAddress.get_all_postal_address_type_codes
    postal_address_type_codes = PostalAddressType.find_by_sql('select distinct postal_address_type_code from postal_address_types').map{|g|[g.postal_address_type_code]}
    postal_address_type_codes.unshift("<empty>")
    if parties_postal_address == nil||is_create_retry
      cities = ["Select a value from postal_address_type_code"]
      address1s = ["Select a value from city"]
      address2s = ["Select a value from address1"]
    else
      cities = PartiesPostalAddress.cities_for_postal_address_type_code(parties_postal_address.postal_address.postal_address_type_code)
      address1s = PartiesPostalAddress.address1s_for_city_and_postal_address_type_code(parties_postal_address.postal_address.city, parties_postal_address.postal_address.postal_address_type_code)
      address2s = PartiesPostalAddress.address2s_for_address1_and_city_and_postal_address_type_code(parties_postal_address.postal_address.address1, parties_postal_address.postal_address.city, parties_postal_address.postal_address.postal_address_type_code)
    end
    party_type_name_observer  = {:updated_field_id => "party_name_cell",
                                 :remote_method => 'parties_postal_address_party_type_name_changed',
                                 :on_completed_js => combos_js_for_parties ["parties_postal_address_party_type_name"]}

    session[:parties_postal_address_form][:party_type_name_observer] = party_type_name_observer

    #  combo lists for table: parties

    party_type_names = nil
    party_names = nil

    party_type_names = PartiesPostalAddress.get_all_party_type_names
    if parties_postal_address == nil||is_create_retry
      party_names = ["Select a value from party_type_name"]
    else
      party_names = PartiesPostalAddress.party_names_for_party_type_name(parties_postal_address.party.party_type_name)
    end
    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (postal_address_id) on related table: postal_addresses
    #  ----------------------------------------------------------------------------------------------
    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'postal_address_type_code',
                       :settings => {:list => postal_address_type_codes},
                       :observer => postal_address_type_code_observer}

    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'city',
                       :settings => {:list => cities},
                       :observer => city_observer}

    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'address1',
                       :settings => {:list => address1s},
                       :observer => address1_observer}

    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'address2',
                       :settings => {:list => address2s}}

    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (party_id) on related table: parties
    #  ----------------------------------------------------------------------------------------------
    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'party_type_name',
                       :settings => {:list => party_type_names},
                       :observer => party_type_name_observer}

    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'party_name',
                       :settings => {:list => party_names}}

    build_form(parties_postal_address,field_configs,action,'parties_postal_address',caption,is_edit)

  end


  def build_parties_postal_address_search_form(parties_postal_address,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    session[:parties_postal_address_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["parties_postal_address_party_type_name","parties_postal_address_party_name","parties_postal_address_postal_address_type_code","parties_postal_address_city","parties_postal_address_address1","parties_postal_address_address2"])
    #Observers for search combos
    party_type_name_observer  = {:updated_field_id => "party_name_cell",
                                 :remote_method => 'parties_postal_address_party_type_name_search_combo_changed',
                                 :on_completed_js => search_combos_js["parties_postal_address_party_type_name"]}

    session[:parties_postal_address_search_form][:party_type_name_observer] = party_type_name_observer

    party_name_observer  = {:updated_field_id => "postal_address_type_code_cell",
                            :remote_method => 'parties_postal_address_party_name_search_combo_changed',
                            :on_completed_js => search_combos_js["parties_postal_address_party_name"]}

    session[:parties_postal_address_search_form][:party_name_observer] = party_name_observer

    postal_address_type_code_observer  = {:updated_field_id => "city_cell",
                                          :remote_method => 'parties_postal_address_postal_address_type_code_search_combo_changed',
                                          :on_completed_js => search_combos_js["parties_postal_address_postal_address_type_code"]}

    session[:parties_postal_address_search_form][:postal_address_type_code_observer] = postal_address_type_code_observer

    city_observer  = {:updated_field_id => "address1_cell",
                      :remote_method => 'parties_postal_address_city_search_combo_changed',
                      :on_completed_js => search_combos_js["parties_postal_address_city"]}

    session[:parties_postal_address_search_form][:city_observer] = city_observer

    address1_observer  = {:updated_field_id => "address2_cell",
                          :remote_method => 'parties_postal_address_address1_search_combo_changed',
                          :on_completed_js => search_combos_js["parties_postal_address_address1"]}

    session[:parties_postal_address_search_form][:address1_observer] = address1_observer


    party_type_names = PartiesPostalAddress.find_by_sql('select distinct party_type_name from parties_postal_addresses').map{|g|[g.party_type_name]}
    party_type_names.unshift("<empty>")
    if is_flat_search
      party_names = PartiesPostalAddress.find_by_sql('select distinct party_name from parties_postal_addresses').map{|g|[g.party_name]}
      party_names.unshift("<empty>")
      postal_address_type_codes = PartiesPostalAddress.find_by_sql('select distinct postal_address_type_code from parties_postal_addresses').map{|g|[g.postal_address_type_code]}
      postal_address_type_codes.unshift("<empty>")
      cities = PartiesPostalAddress.find_by_sql('select distinct city from parties_postal_addresses').map{|g|[g.city]}
      cities.unshift("<empty>")
      address1s = PartiesPostalAddress.find_by_sql('select distinct address1 from parties_postal_addresses').map{|g|[g.address1]}
      address1s.unshift("<empty>")
      address2s = PartiesPostalAddress.find_by_sql('select distinct address2 from parties_postal_addresses').map{|g|[g.address2]}
      address2s.unshift("<empty>")
      party_type_name_observer = nil
      party_name_observer = nil
      postal_address_type_code_observer = nil
      city_observer = nil
      address1_observer = nil
    else
      party_names = ["Select a value from party_type_name"]
      postal_address_type_codes = ["Select a value from party_name"]
      cities = ["Select a value from postal_address_type_code"]
      address1s = ["Select a value from city"]
      address2s = ["Select a value from address1"]
    end
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Define search Combo fields to represent the unique index on this table
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'party_type_name',
                         :settings => {:list => party_type_names},
                         :observer => party_type_name_observer}

    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'party_name',
                         :settings => {:list => party_names},
                         :observer => party_name_observer}

    field_configs[2] =  {:field_type => 'DropDownField',
                         :field_name => 'postal_address_type_code',
                         :settings => {:list => postal_address_type_codes},
                         :observer => postal_address_type_code_observer}

    field_configs[3] =  {:field_type => 'DropDownField',
                         :field_name => 'city',
                         :settings => {:list => cities},
                         :observer => city_observer}

    field_configs[4] =  {:field_type => 'DropDownField',
                         :field_name => 'address1',
                         :settings => {:list => address1s},
                         :observer => address1_observer}

    field_configs[5] =  {:field_type => 'DropDownField',
                         :field_name => 'address2',
                         :settings => {:list => address2s}}

    build_form(parties_postal_address,field_configs,action,'parties_postal_address',caption,false)

  end



  def build_parties_postal_address_grid(data_set,can_edit,can_delete)

    column_configs = Array.new
    column_configs << {:field_type => 'text',:field_name => 'address1'}
    column_configs << {:field_type => 'text',:field_name => 'address2'}
    column_configs << {:field_type => 'text',:field_name => 'city'}
    column_configs << {:field_type => 'text',:field_name => 'postal_address_type_code'}
    column_configs << {:field_type => 'text',:field_name => 'party_name'}
    column_configs << {:field_type => 'text',:field_name => 'party_type_name'}
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit parties_postal_address',
                                                 :settings =>
      {:link_text => 'edit',
       :target_action => 'edit_parties_postal_address',
       :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete parties_postal_address',
                                                 :settings =>
      {:link_text => 'delete',
       :target_action => 'delete_parties_postal_address',
       :id_column => 'id'}}
    end
    return get_data_grid(data_set,column_configs)
  end

  #============================
  #POSTAL ADDRESS CODE
  #============================
  def build_postal_address_form(postal_address,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:postal_address_form]= Hash.new
    postal_address_type_codes = PostalAddressType.find_by_sql('select distinct postal_address_type_code from postal_address_types').map{|g|[g.postal_address_type_code]}
    postal_address_type_codes.unshift("<empty>")


    js = "\n img = document.getElementById('img_postal_address_postal_address_type_code');"
    js += "\n if(img != null)img.style.display = 'none';"

    type_observer  = {:updated_field_id => "ajax_distributor_cell",
                      :remote_method => 'postal_adress_type_changed',
                      :on_completed_js => js}

    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = Array.new

    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'postal_address_type_code',
                       :settings => {:list => postal_address_type_codes},
                       :observer => type_observer}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'address1',
                      :settings => {:size => 50}}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'address2',
                      :settings => {:size => 50}}

    if !postal_address||postal_address.postal_address_type_code.upcase != "CARTON_LABEL_ADDRESS"
      field_configs << {:field_type => 'TextField',
                        :field_name => 'city'}

      field_configs << {:field_type => 'TextField',
                        :field_name => 'postal_code'}
    end

    field_configs << {:field_type => 'HiddenField',
                      :field_name => 'ajax_distributor',
                      :non_db_field => true}

    build_form(postal_address,field_configs,action,'postal_address',caption,is_edit)

  end


  def build_postal_address_search_form(postal_address,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    session[:postal_address_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["postal_address_postal_address_type_code","postal_address_city","postal_address_address1","postal_address_address2"])
    #Observers for search combos
    postal_address_type_code_observer  = {:updated_field_id => "city_cell",
                                          :remote_method => 'postal_address_postal_address_type_code_search_combo_changed',
                                          :on_completed_js => search_combos_js["postal_address_postal_address_type_code"]}

    session[:postal_address_search_form][:postal_address_type_code_observer] = postal_address_type_code_observer

    city_observer  = {:updated_field_id => "address1_cell",
                      :remote_method => 'postal_address_city_search_combo_changed',
                      :on_completed_js => search_combos_js["postal_address_city"]}

    session[:postal_address_search_form][:city_observer] = city_observer

    address1_observer  = {:updated_field_id => "address2_cell",
                          :remote_method => 'postal_address_address1_search_combo_changed',
                          :on_completed_js => search_combos_js["postal_address_address1"]}

    session[:postal_address_search_form][:address1_observer] = address1_observer


    postal_address_type_codes = PostalAddress.find_by_sql('select distinct postal_address_type_code from postal_addresses').map{|g|[g.postal_address_type_code]}
    postal_address_type_codes.unshift("<empty>")
    if is_flat_search
      cities = PostalAddress.find_by_sql('select distinct city from postal_addresses').map{|g|[g.city]}
      cities.unshift("<empty>")
      address1s = PostalAddress.find_by_sql('select distinct address1 from postal_addresses').map{|g|[g.address1]}
      address1s.unshift("<empty>")
      address2s = PostalAddress.find_by_sql('select distinct address2 from postal_addresses').map{|g|[g.address2]}
      address2s.unshift("<empty>")
      postal_address_type_code_observer = nil
      city_observer = nil
      address1_observer = nil
    else
      cities = ["Select a value from postal_address_type_code"]
      address1s = ["Select a value from city"]
      address2s = ["Select a value from address1"]
    end
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Define search Combo fields to represent the unique index on this table
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'postal_address_type_code',
                         :settings => {:list => postal_address_type_codes},
                         :observer => postal_address_type_code_observer}

    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'city',
                         :settings => {:list => cities},
                         :observer => city_observer}

    field_configs[2] =  {:field_type => 'DropDownField',
                         :field_name => 'address1',
                         :settings => {:list => address1s},
                         :observer => address1_observer}

    field_configs[3] =  {:field_type => 'DropDownField',
                         :field_name => 'address2',
                         :settings => {:list => address2s}}

    build_form(postal_address,field_configs,action,'postal_address',caption,false)

  end



  def build_postal_address_grid(data_set,can_edit,can_delete)

    column_configs = []
    action_configs = []
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      action_configs << {:field_type => 'action',:field_name => 'edit postal_address',
                         :column_caption => 'Edit',
                         :settings =>
      {:link_text => 'edit',
       :link_icon => 'edit',
       :target_action => 'edit_postal_address',
       :id_column => 'id'}}
    end

    if can_delete
      action_configs << {:field_type => 'action',:field_name => 'delete postal_address',
                         :column_caption => 'Delete',
                         :settings =>
      {:link_text => 'delete',
       :link_icon => 'delete',
       :target_action => 'delete_postal_address',
       :id_column => 'id'}}
    end

    #action_configs << {:field_type => 'separator'} if can_edit || can_delete

    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?

    column_configs << {:field_type => 'text',:field_name => 'address1'}
    column_configs << {:field_type => 'text',:field_name => 'address2'}
    column_configs << {:field_type => 'text',:field_name => 'city'}
    column_configs << {:field_type => 'text',:field_name => 'postal_code'}
    column_configs << {:field_type => 'text',:field_name => 'postal_address_type_code'}
    column_configs << {:field_type => 'text',:field_name => 'country.country_name', :use_outer_join => true}

    get_data_grid(data_set,column_configs)
  end

  #=============================
  #POSTAL ADDRESS TYPE CODE
  #=============================
  def build_postal_address_type_form(postal_address_type,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:postal_address_type_form]= Hash.new
    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = Array.new
    field_configs[0] = {:field_type => 'TextField',
                        :field_name => 'postal_address_type_code'}

    field_configs[1] = {:field_type => 'TextField',
                        :field_name => 'address_type_code'}

    field_configs[2] = {:field_type => 'TextField',
                        :field_name => 'postal_address_type_description'}

    build_form(postal_address_type,field_configs,action,'postal_address_type',caption,is_edit)

  end


  def build_postal_address_type_search_form(postal_address_type,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    session[:postal_address_type_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["postal_address_type_postal_address_type_code"])
    #Observers for search combos

    postal_address_type_codes = PostalAddressType.find_by_sql('select distinct postal_address_type_code from postal_address_types').map{|g|[g.postal_address_type_code]}
    postal_address_type_codes.unshift("<empty>")
    if is_flat_search
    else
    end
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Define search Combo fields to represent the unique index on this table
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'postal_address_type_code',
                         :settings => {:list => postal_address_type_codes}}

    build_form(postal_address_type,field_configs,action,'postal_address_type',caption,false)

  end



  def build_postal_address_type_grid(data_set,can_edit,can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text',:field_name => 'postal_address_type_code'}
    column_configs[1] = {:field_type => 'text',:field_name => 'address_type_code'}
    column_configs[2] = {:field_type => 'text',:field_name => 'postal_address_type_description'}
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit postal_address_type',
                                                 :settings =>
      {:link_text => 'edit',
       :target_action => 'edit_postal_address_type',
       :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete postal_address_type',
                                                 :settings =>
      {:link_text => 'delete',
       :target_action => 'delete_postal_address_type',
       :id_column => 'id'}}
    end
    return get_data_grid(data_set,column_configs)
  end

  #===========================
  #CONTACT METHOD PARTY CODE
  #===========================
  def build_contact_methods_party_form(contact_methods_party,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:contact_methods_party_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo for fk table: contact_methods
    combos_js_for_contact_methods = gen_combos_clear_js_for_combos(["contact_methods_party_contact_method_type_code","contact_methods_party_contact_method_code"])
    combos_js_for_parties = gen_combos_clear_js_for_combos(["contact_methods_party_party_type_name","contact_methods_party_party_name"])
    #Observers for combos representing the key fields of fkey table: contact_method_id
    #generate javascript for the on_complete ajax event for each combo for fk table: parties
    combos_js_for_contact_methods = gen_combos_clear_js_for_combos(["contact_methods_party_contact_method_type_code","contact_methods_party_contact_method_code"])
    combos_js_for_parties = gen_combos_clear_js_for_combos(["contact_methods_party_party_type_name","contact_methods_party_party_name"])
    #Observers for combos representing the key fields of fkey table: party_id
    contact_method_type_code_observer  = {:updated_field_id => "contact_method_code_cell",
                                          :remote_method => 'contact_methods_party_contact_method_type_code_changed',
                                          :on_completed_js => combos_js_for_contact_methods ["contact_methods_party_contact_method_type_code"]}

    session[:contact_methods_party_form][:contact_method_type_code_observer] = contact_method_type_code_observer

    #  combo lists for table: contact_methods

    contact_method_type_codes = nil
    contact_method_codes = nil

    contact_method_type_codes = ContactMethodsParty.get_all_contact_method_type_codes
    if contact_methods_party == nil||is_create_retry
      contact_method_codes = ["Select a value from contact_method_type_code"]
    else
      contact_method_codes = ContactMethodsParty.contact_method_codes_for_contact_method_type_code(contact_methods_party.contact_method.contact_method_type_code)
    end
    party_type_name_observer  = {:updated_field_id => "party_name_cell",
                                 :remote_method => 'contact_methods_party_party_type_name_changed',
                                 :on_completed_js => combos_js_for_parties ["contact_methods_party_party_type_name"]}

    session[:contact_methods_party_form][:party_type_name_observer] = party_type_name_observer

    #  combo lists for table: parties

    party_type_names = nil
    party_names = nil

    party_type_names = ContactMethodsParty.get_all_party_type_names
    if contact_methods_party == nil||is_create_retry
      party_names = ["Select a value from party_type_name"]
    else
      party_names = ContactMethodsParty.party_names_for_party_type_name(contact_methods_party.party.party_type_name)
    end
    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = Array.new
    field_configs[0] = {:field_type => 'DateField',
                        :field_name => 'from_date'}

    field_configs[1] = {:field_type => 'DateField',
                        :field_name => 'thru_date'}

    field_configs[2] = {:field_type => 'TextField',
                        :field_name => 'remarks'}

    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (party_id) on related table: parties
    #  ----------------------------------------------------------------------------------------------
    field_configs[3] =  {:field_type => 'DropDownField',
                         :field_name => 'party_type_name',
                         :settings => {:list => party_type_names},
                         :observer => party_type_name_observer}

    field_configs[4] =  {:field_type => 'DropDownField',
                         :field_name => 'party_name',
                         :settings => {:list => party_names}}

    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (contact_method_id) on related table: contact_methods
    #  ----------------------------------------------------------------------------------------------
    field_configs[5] =  {:field_type => 'DropDownField',
                         :field_name => 'contact_method_type_code',
                         :settings => {:list => contact_method_type_codes},
                         :observer => contact_method_type_code_observer}

    field_configs[6] =  {:field_type => 'DropDownField',
                         :field_name => 'contact_method_code',
                         :settings => {:list => contact_method_codes}}

    build_form(contact_methods_party,field_configs,action,'contact_methods_party',caption,is_edit)

  end


  def build_contact_methods_party_search_form(contact_methods_party,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    session[:contact_methods_party_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["contact_methods_party_party_type_name","contact_methods_party_party_name","contact_methods_party_contact_method_type_code","contact_methods_party_contact_method_code"])
    #Observers for search combos
    party_type_name_observer  = {:updated_field_id => "party_name_cell",
                                 :remote_method => 'contact_methods_party_party_type_name_search_combo_changed',
                                 :on_completed_js => search_combos_js["contact_methods_party_party_type_name"]}

    session[:contact_methods_party_search_form][:party_type_name_observer] = party_type_name_observer

    party_name_observer  = {:updated_field_id => "contact_method_type_code_cell",
                            :remote_method => 'contact_methods_party_party_name_search_combo_changed',
                            :on_completed_js => search_combos_js["contact_methods_party_party_name"]}

    session[:contact_methods_party_search_form][:party_name_observer] = party_name_observer

    contact_method_type_code_observer  = {:updated_field_id => "contact_method_code_cell",
                                          :remote_method => 'contact_methods_party_contact_method_type_code_search_combo_changed',
                                          :on_completed_js => search_combos_js["contact_methods_party_contact_method_type_code"]}

    session[:contact_methods_party_search_form][:contact_method_type_code_observer] = contact_method_type_code_observer


    party_type_names = ContactMethodsParty.find_by_sql('select distinct party_type_name from contact_methods_parties').map{|g|[g.party_type_name]}
    party_type_names.unshift("<empty>")
    if is_flat_search
      party_names = ContactMethodsParty.find_by_sql('select distinct party_name from contact_methods_parties').map{|g|[g.party_name]}
      party_names.unshift("<empty>")
      contact_method_type_codes = ContactMethodsParty.find_by_sql('select distinct contact_method_type_code from contact_methods_parties').map{|g|[g.contact_method_type_code]}
      contact_method_type_codes.unshift("<empty>")
      contact_method_codes = ContactMethodsParty.find_by_sql('select distinct contact_method_code from contact_methods_parties').map{|g|[g.contact_method_code]}
      contact_method_codes.unshift("<empty>")
      party_type_name_observer = nil
      party_name_observer = nil
      contact_method_type_code_observer = nil
    else
      party_names = ["Select a value from party_type_name"]
      contact_method_type_codes = ["Select a value from party_name"]
      contact_method_codes = ["Select a value from contact_method_type_code"]
    end
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Define search Combo fields to represent the unique index on this table
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'party_type_name',
                         :settings => {:list => party_type_names},
                         :observer => party_type_name_observer}

    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'party_name',
                         :settings => {:list => party_names},
                         :observer => party_name_observer}

    field_configs[2] =  {:field_type => 'DropDownField',
                         :field_name => 'contact_method_type_code',
                         :settings => {:list => contact_method_type_codes},
                         :observer => contact_method_type_code_observer}

    field_configs[3] =  {:field_type => 'DropDownField',
                         :field_name => 'contact_method_code',
                         :settings => {:list => contact_method_codes}}

    build_form(contact_methods_party,field_configs,action,'contact_methods_party',caption,false)

  end



  def build_contact_methods_party_grid(data_set,can_edit,can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text',:field_name => 'party_name'}
    column_configs[1] = {:field_type => 'text',:field_name => 'contact_method_code'}
    column_configs[2] = {:field_type => 'text',:field_name => 'from_date'}
    column_configs[3] = {:field_type => 'text',:field_name => 'thru_date'}
    column_configs[4] = {:field_type => 'text',:field_name => 'remarks'}
    column_configs[5] = {:field_type => 'text',:field_name => 'contact_method_type_code'}
    column_configs[6] = {:field_type => 'text',:field_name => 'party_type_name'}
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit contact_methods_party',
                                                 :settings =>
      {:link_text => 'edit',
       :target_action => 'edit_contact_methods_party',
       :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete contact_methods_party',
                                                 :settings =>
      {:link_text => 'delete',
       :target_action => 'delete_contact_methods_party',
       :id_column => 'id'}}
    end
    return get_data_grid(data_set,column_configs)
  end


  #=============================
  #CONTACT METHOD TYPE CODE
  #=============================
  def build_contact_method_type_form(contact_method_type,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:contact_method_type_form]= Hash.new
    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = Array.new
    field_configs[0] = {:field_type => 'TextField',
                        :field_name => 'contact_method_type_code'}

    field_configs[1] = {:field_type => 'TextField',
                        :field_name => 'contact_method_type_description'}

    build_form(contact_method_type,field_configs,action,'contact_method_type',caption,is_edit)

  end


  def build_contact_method_type_search_form(contact_method_type,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    session[:contact_method_type_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["contact_method_type_contact_method_type_code"])
    #Observers for search combos

    contact_method_type_codes = ContactMethodType.find_by_sql('select distinct contact_method_type_code from contact_method_types').map{|g|[g.contact_method_type_code]}
    contact_method_type_codes.unshift("<empty>")
    if is_flat_search
    else
    end
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Define search Combo fields to represent the unique index on this table
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'contact_method_type_code',
                         :settings => {:list => contact_method_type_codes}}

    build_form(contact_method_type,field_configs,action,'contact_method_type',caption,false)

  end


  def build_contact_method_type_grid(data_set,can_edit,can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text',:field_name => 'contact_method_type_code'}
    column_configs[1] = {:field_type => 'text',:field_name => 'contact_method_type_description'}
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit contact_method_type',
                                                 :settings =>
      {:link_text => 'edit',
       :target_action => 'edit_contact_method_type',
       :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete contact_method_type',
                                                 :settings =>
      {:link_text => 'delete',
       :target_action => 'delete_contact_method_type',
       :id_column => 'id'}}
    end
    return get_data_grid(data_set,column_configs)
  end

  #========================
  #CONTACT METHOD TYPE CODE
  #========================

  def build_contact_method_type_form(contact_method_type,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:contact_method_type_form]= Hash.new
    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = Array.new
    field_configs[0] = {:field_type => 'TextField',
                        :field_name => 'contact_method_type_code'}

    field_configs[1] = {:field_type => 'TextField',
                        :field_name => 'contact_method_type_description'}

    build_form(contact_method_type,field_configs,action,'contact_method_type',caption,is_edit)

  end


  def build_contact_method_type_search_form(contact_method_type,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    session[:contact_method_type_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["contact_method_type_contact_method_type_code"])
    #Observers for search combos

    contact_method_type_codes = ContactMethodType.find_by_sql('select distinct contact_method_type_code from contact_method_types').map{|g|[g.contact_method_type_code]}
    contact_method_type_codes.unshift("<empty>")
    if is_flat_search
    else
    end
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Define search Combo fields to represent the unique index on this table
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'contact_method_type_code',
                         :settings => {:list => contact_method_type_codes}}

    build_form(contact_method_type,field_configs,action,'contact_method_type',caption,false)

  end

  def build_contact_method_type_grid(data_set,can_edit,can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text',:field_name => 'contact_method_type_code'}
    column_configs[1] = {:field_type => 'text',:field_name => 'contact_method_type_description'}
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit contact_method_type',
                                                 :settings =>
      {:link_text => 'edit',
       :target_action => 'edit_contact_method_type',
       :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete contact_method_type',
                                                 :settings =>
      {:link_text => 'delete',
       :target_action => 'delete_contact_method_type',
       :id_column => 'id'}}
    end
    return get_data_grid(data_set,column_configs)
  end


  #====================
  #CONTACT METHOD CODE
  #====================
  def build_contact_method_form(contact_method,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:contact_method_form]= Hash.new
    contact_method_type_codes = ContactMethodType.find_by_sql('select distinct contact_method_type_code from contact_method_types').map{|g|[g.contact_method_type_code]}
    contact_method_type_codes.unshift("<empty>")
    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = Array.new
    field_configs[0] = {:field_type => 'TextField',
                        :field_name => 'contact_method_code'}

    field_configs[1] = {:field_type => 'TextField',
                        :field_name => 'contact_method_description'}

    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (contact_method_type_id) on related table: contact_method_types
    #  ----------------------------------------------------------------------------------------------
    field_configs[2] =  {:field_type => 'DropDownField',
                         :field_name => 'contact_method_type_code',
                         :settings => {:list => contact_method_type_codes}}

    field_configs[3] = {:field_type => 'TextField',
                        :field_name => 'info_string'}

    build_form(contact_method,field_configs,action,'contact_method',caption,is_edit)

  end


  def build_contact_method_search_form(contact_method,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    session[:contact_method_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["contact_method_contact_method_type_code","contact_method_contact_method_code"])
    #Observers for search combos
    contact_method_type_code_observer  = {:updated_field_id => "contact_method_code_cell",
                                          :remote_method => 'contact_method_contact_method_type_code_search_combo_changed',
                                          :on_completed_js => search_combos_js["contact_method_contact_method_type_code"]}

    session[:contact_method_search_form][:contact_method_type_code_observer] = contact_method_type_code_observer


    contact_method_type_codes = ContactMethod.find_by_sql('select distinct contact_method_type_code from contact_methods').map{|g|[g.contact_method_type_code]}
    contact_method_type_codes.unshift("<empty>")
    if is_flat_search
      contact_method_codes = ContactMethod.find_by_sql('select distinct contact_method_code from contact_methods').map{|g|[g.contact_method_code]}
      contact_method_codes.unshift("<empty>")
      contact_method_type_code_observer = nil
    else
      contact_method_codes = ["Select a value from contact_method_type_code"]
    end
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Define search Combo fields to represent the unique index on this table
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'contact_method_type_code',
                         :settings => {:list => contact_method_type_codes},
                         :observer => contact_method_type_code_observer}

    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'contact_method_code',
                         :settings => {:list => contact_method_codes}}

    build_form(contact_method,field_configs,action,'contact_method',caption,false)

  end



  def build_contact_method_grid(data_set,can_edit,can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text',:field_name => 'contact_method_code'}
    column_configs[1] = {:field_type => 'text',:field_name => 'contact_method_description'}
    column_configs[2] = {:field_type => 'text',:field_name => 'contact_method_type_code'}
    column_configs[3] = {:field_type => 'text',:field_name => 'info_string'}
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit contact_method',
                                                 :settings =>
      {:link_text => 'edit',
       :target_action => 'edit_contact_method',
       :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete contact_method',
                                                 :settings =>
      {:link_text => 'delete',
       :target_action => 'delete_contact_method',
       :id_column => 'id'}}
    end
    return get_data_grid(data_set,column_configs)
  end

end
