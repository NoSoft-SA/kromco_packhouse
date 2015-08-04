module PartyManager::OrganizationHelper

  #================
  #MARKS CODE
  #================

  def build_marks_organization_form(marks_organization,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:marks_organization_form]= Hash.new
    mark_codes = Mark.find_by_sql('select distinct mark_code from marks').map{|g|[g.mark_code]}
    mark_codes.unshift("<empty>")
    short_descriptions = Organization.find_by_sql('select distinct short_description from organizations').map{|g|[g.short_description]}
    short_descriptions.unshift("<empty>")
    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (organization_id) on related table: organizations
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'short_description',
                         :settings => {:list => short_descriptions,
                                       :label_caption => "org code"}}

    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (mark_id) on related table: marks
    #  ----------------------------------------------------------------------------------------------
    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'mark_code',
                         :settings => {:list => mark_codes}}

    build_form(marks_organization,field_configs,action,'marks_organization',caption,is_edit)

  end


  def build_marks_organization_search_form(marks_organization,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    session[:marks_organization_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["marks_organization_short_description","marks_organization_mark_code"])
    #Observers for search combos
    short_description_observer  = {:updated_field_id => "mark_code_cell",
                                   :remote_method => 'marks_organization_short_description_search_combo_changed',
                                   :on_completed_js => search_combos_js["marks_organization_short_description"]}

    session[:marks_organization_search_form][:short_description_observer] = short_description_observer


    short_descriptions = MarksOrganization.find_by_sql('select distinct short_description from marks_organizations').map{|g|[g.short_description]}
    short_descriptions.unshift("<empty>")
    if is_flat_search
      mark_codes = MarksOrganization.find_by_sql('select distinct mark_code from marks_organizations').map{|g|[g.mark_code]}
      mark_codes.unshift("<empty>")
      short_description_observer = nil
    else
      mark_codes = ["Select a value from short_description"]
    end
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Define search Combo fields to represent the unique index on this table
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'short_description',
                         :settings => {:list => short_descriptions,
                                       :label_caption => "org code"},
                                       :observer => short_description_observer}

    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'mark_code',
                         :settings => {:list => mark_codes}}

    build_form(marks_organization,field_configs,action,'marks_organization',caption,false)

  end



  def build_marks_organization_grid(data_set,can_edit,can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text',:field_name => 'short_description',:column_caption => "org code"}
    column_configs[1] = {:field_type => 'text',:field_name => 'mark_code'}
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit marks_organization',
                                                 :settings =>
      {:link_text => 'edit',
       :target_action => 'edit_marks_organization',
       :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete marks_organization',
                                                 :settings =>
      {:link_text => 'delete',
       :target_action => 'delete_marks_organization',
       :id_column => 'id'}}
    end
    return get_data_grid(data_set,column_configs)
  end


  #==================
  #INVENTORY CODES
  #==================
  def build_inventory_codes_organization_form(inventory_codes_organization,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:inventory_codes_organization_form]= Hash.new
    inventory_codes = InventoryCode.find_by_sql('select distinct inventory_code from inventory_codes').map{|g|[g.inventory_code]}
    inventory_codes.unshift("<empty>")
    short_descriptions = Organization.find_by_sql('select distinct short_description from organizations').map{|g|[g.short_description]}
    short_descriptions.unshift("<empty>")
    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (organization_id) on related table: organizations
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'short_description',
                         :settings => {:list => short_descriptions,
                                       :label_caption => "org code"}}

    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (inventory_code_id) on related table: inventory_codes
    #  ----------------------------------------------------------------------------------------------
    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'inv_code',
                         :settings => {:list => inventory_codes}}

    build_form(inventory_codes_organization,field_configs,action,'inventory_codes_organization',caption,is_edit)

  end


  def build_inventory_codes_organization_search_form(inventory_codes_organization,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------

    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["inventory_codes_organization_short_description","inventory_codes_organization_inventory_code"])
    #Observers for search combos
    short_description_observer  = {:updated_field_id => "inv_code_cell",
                                   :remote_method => 'inventory_codes_organization_short_description_search_combo_changed',
                                   :on_completed_js => search_combos_js["inventory_codes_organization_short_description"]}




    short_descriptions = InventoryCodesOrganization.find_by_sql('select distinct short_description from inventory_codes_organizations').map{|g|[g.short_description]}
    short_descriptions.unshift("<empty>")
    if is_flat_search
      inventory_codes = InventoryCodesOrganization.find_by_sql('select distinct inv_code from inventory_codes_organizations').map{|g|[g.inv_code]}
      inventory_codes.unshift("<empty>")
      short_description_observer = nil
    else
      inventory_codes = ["Select a value from short_description"]
    end
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Define search Combo fields to represent the unique index on this table
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'short_description',
                         :settings => {:list => short_descriptions,
                                       :label_caption => "org code"},
                                       :observer => short_description_observer}

    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'inv_code',
                         :settings => {:list => inventory_codes}}

    build_form(inventory_codes_organization,field_configs,action,'inventory_codes_organization',caption,false)

  end


  def build_inventory_codes_organization_grid(data_set,can_edit,can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text',:field_name => 'short_description',:column_caption => "org code"}
    column_configs[1] = {:field_type => 'text',:field_name => 'inv_code'}
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit inventory_codes_organization',
                                                 :settings =>
      {:link_text => 'edit',
       :target_action => 'edit_inventory_codes_organization',
       :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete inventory_codes_organization',
                                                 :settings =>
      {:link_text => 'delete',
       :target_action => 'delete_inventory_codes_organization',
       :id_column => 'id'}}
    end
    return get_data_grid(data_set,column_configs)
  end


  #==================
  #TARGET MARKET CODE
  #==================

  def build_organizations_target_market_form(organizations_target_market,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:organizations_target_market_form]= Hash.new
    short_descriptions = Organization.find_by_sql('select distinct short_description from organizations').map{|g|[g.short_description]}
    short_descriptions.unshift("<empty>")
    target_market_names = TargetMarket.find_by_sql('select distinct target_market_name from target_markets').map{|g|[g.target_market_name]}
    target_market_names.unshift("<empty>")
    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (organization_id) on related table: organizations
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'short_description',
                         :settings => {:list => short_descriptions,
                                       :label_caption => "org code"}}

    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (target_market_id) on related table: target_markets
    #  ----------------------------------------------------------------------------------------------
    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'target_market_name',
                         :settings => {:list => target_market_names,
                                       :label_caption => "target market code"}}

    build_form(organizations_target_market,field_configs,action,'organizations_target_market',caption,is_edit)

  end


  def build_organizations_target_market_search_form(organizations_target_market,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    session[:organizations_target_market_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["organizations_target_market_short_description","organizations_target_market_target_market_name"])
    #Observers for search combos
    short_description_observer  = {:updated_field_id => "target_market_name_cell",
                                   :remote_method => 'organizations_target_market_short_description_search_combo_changed',
                                   :on_completed_js => search_combos_js["organizations_target_market_short_description"]}

    session[:organizations_target_market_search_form][:short_description_observer] = short_description_observer


    short_descriptions = OrganizationsTargetMarket.find_by_sql('select distinct short_description from organizations_target_markets').map{|g|[g.short_description]}
    short_descriptions.unshift("<empty>")
    if is_flat_search
      target_market_names = OrganizationsTargetMarket.find_by_sql('select distinct target_market_name from organizations_target_markets').map{|g|[g.target_market_name]}
      target_market_names.unshift("<empty>")
      short_description_observer = nil
    else
      target_market_names = ["Select a value from short_description"]
    end
    #  ----------------------------------------
    #   Define search fields to build form from
    #  ----------------------------------------
    field_configs = Array.new
    #  ----------------------------------------------------------------------------------------------
    #  Define search Combo fields to represent the unique index on this table
    #  ----------------------------------------------------------------------------------------------
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'short_description',
                         :settings => {:list => short_descriptions,
                                       :label_caption => "org code"},
                                       :observer => short_description_observer,}

    field_configs[1] =  {:field_type => 'DropDownField',
                         :field_name => 'target_market_name',
                         :settings => {:list => target_market_names,
                                       :label_caption => "target maret code"}}

    build_form(organizations_target_market,field_configs,action,'organizations_target_market',caption,false)

  end



  def build_organizations_target_market_grid(data_set,can_edit,can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text',:field_name => 'target_market_name',:column_caption => "target_market_code"}
    column_configs[1] = {:field_type => 'text',:field_name => 'short_description',:column_caption => "org code"}
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit organizations_target_market',
                                                 :settings =>
      {:link_text => 'edit',
       :target_action => 'edit_organizations_target_market',
       :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete organizations_target_market',
                                                 :settings =>
      {:link_text => 'delete',
       :target_action => 'delete_organizations_target_market',
       :id_column => 'id'}}
    end
    return get_data_grid(data_set,column_configs)
  end


  #===================
  #ORGANIZATIONS CODE
  #===================
  def build_organization_form(organization,action,caption,is_edit,is_create_retry = nil,add_organization = nil)

    if !is_edit
      parent_organisation_short_descriptions = Organization.find_by_sql("select distinct short_description from organizations").map{|o|[o.short_description]}
    else
      parent_organisation_short_descriptions = Organization.find_by_sql("select distinct short_description from organizations where short_description != '#{organization.short_description.to_s}'").map{|o|[o.short_description]}
    end
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------

    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = Array.new
    if(!add_organization)
      field_configs << {:field_type => 'DropDownField',
                        :field_name => 'parent_org_short_description',
                        :settings=>{:label_caption=>'parent organization',:list=>parent_organisation_short_descriptions}}
    end

    field_configs << {:field_type => 'TextField',
                      :field_name => 'long_description'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'medium_description'}

    if organization.nil? || organization.new_record?
      field_configs << {:field_type => 'TextField',
                        :field_name => 'short_description',
                        :settings => {:label_caption => "org code"}}
    else
      field_configs << {:field_type => 'LabelField',
                        :field_name => 'short_description',
                        :settings => {:label_caption => "org code"}}
    end

    field_configs << {:field_type => 'TextField',
                      :field_name => 'gln'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'sell_by_algorithm'}

    field_configs << {:field_type => 'TextField',
                      :field_name => 'sell_by_description'}

    field_configs << {:field_type => 'CheckBox',
                      :field_name => 'receives_edi'}

    build_form(organization,field_configs,action,'organization',caption,is_edit)

  end


  def build_organization_search_form(organization,action,caption,is_flat_search = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define an observer for each index field
    #  --------------------------------------------------------------------------------------------------
    session[:organization_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["organization_short_description"])
    #Observers for search combos

    short_descriptions = Organization.find_by_sql('select distinct short_description from organizations').map{|g|[g.short_description]}
    short_descriptions.unshift("<empty>")
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
                         :field_name => 'short_description',
                         :settings => {:list => short_descriptions,
                                       :label_caption => "org code"}}

    build_form(organization,field_configs,action,'organization',caption,false)

  end


  def build_organization_grid(data_set,can_edit,can_delete)

    column_configs = []
    action_configs = []

    if can_edit
      action_configs << {:field_type => 'action',:field_name => 'edit organization',
                         :settings =>
      {:link_text => 'edit',
       :link_icon => 'edit',
       :target_action => 'edit_organization',
       :id_column => 'id'}}

      action_configs << {:field_type => 'action',:field_name => 'rename party',
                         :column_caption => 'rename',
                         :settings =>
      {:link_text => 'rename',
       :link_icon => 'exec2',
       :controller => 'party_manager/parties_role',
       :target_action => 'rename_party',
       :id_column => 'party_id'}}
    end

    if can_delete
      action_configs << {:field_type => 'action',:field_name => 'delete organization',
                         :settings =>
      {:link_text => 'delete',
       :link_icon => 'delete',
       :target_action => 'delete_organization',
       :id_column => 'id'}}
    end

    action_configs << {:field_type => 'separator'} if can_edit || can_delete

    action_configs << {:field_type => 'action',:field_name => 'parent_org',
                                               :settings =>
    {:link_text => 'parent',
     :link_icon => 'key',
     :target_action => 'parent_organization',
     :id_column => 'id'}}

    action_configs << {:field_type => 'action',:field_name => 'child_orgs',
                                               :settings =>
    {:link_text => 'children',
     :link_icon => 'clone',
     :target_action => 'child_organizations',
     :id_column => 'id'}}

    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?

    column_configs << {:field_type => 'text',:field_name => 'long_description',:col_width => 400}
    column_configs << {:field_type => 'text',:field_name => 'medium_description',:col_width => 200}
    column_configs << {:field_type => 'text',:field_name => 'short_description',:column_caption => "org code",:col_width => 200}
    column_configs << {:field_type => 'text',:field_name => 'gln'}
    column_configs << {:field_type => 'text',:field_name => 'sell_by_algorithm'}
    column_configs << {:field_type => 'text',:field_name => 'sell_by_description'}
    column_configs << {:field_type => 'text',:field_name => 'receives_edi', :data_type => 'boolean'}

    return get_data_grid(data_set,column_configs)
  end

  def build_organizations_tree(parent_organization)
    begin
      child_organizations = Organization.find_by_sql("select * from organizations where parent_org_short_description = '#{parent_organization.short_description.to_s}'")
      root_node = ApplicationHelper::TreeNode.new(parent_organization.short_description.to_s,"root_organization",true,"organizations",parent_organization.id.to_s)
      build_child_organization_tree(parent_organization.short_description.to_s, root_node)
      tree = ApplicationHelper::TreeView.new(root_node,"parent_organization")
      child_organizations_menu = ApplicationHelper::ContextMenu.new("organization","organizations")
      child_organizations_menu.add_command("add child",url_for(:action => "add_child_organization"))
      child_organizations_menu.add_command("remove",url_for(:action => "remove_from_parent"))
      child_organizations_menu.add_command("delete",url_for(:action => "delete_and_remove_organization"))
      child_organizations_menu.add_command("create child",url_for(:action => "create_and_add_organization"))

      root_organizations_menu = ApplicationHelper::ContextMenu.new("root_organization","organizations")
      root_organizations_menu.add_command("add child",url_for(:action => "add_child_organization"))
      root_organizations_menu.add_command("remove",url_for(:action => "remove_from_parent"))
      root_organizations_menu.add_command("delete",url_for(:action => "delete_and_remove_organization"))
      root_organizations_menu.add_command("create child",url_for(:action => "create_and_add_organization"))
      tree.add_context_menu(child_organizations_menu)
      tree.add_context_menu(root_organizations_menu)
      tree.render
    rescue
      raise "The parent_organization tree could not be rendered. Exception reported is \n" + $!
    end
  end

  def build_child_organization_tree(root_organization_short_description,root_organization_node)
    begin
      child_organizations = Organization.find_by_sql("select * from organizations where parent_org_short_description = '#{root_organization_short_description}'")

      child_organizations.each do |child_organization|
        grand_child_organization_node = root_organization_node.add_child(child_organization.short_description,"organization",child_organization.id.to_s)
        build_child_organization_tree(child_organization.short_description, grand_child_organization_node)
      end
    rescue
      raise "The parent_organization tree could not be rendered. Exception reported is \n" + $!
    end
  end

  def build_add_child_organization_form(organization,action,caption)
    short_descriptions = Organization.find_by_sql("select * from organizations where short_description != '#{organization.short_description}'").map{|loc|[loc.short_description]}
    field_configs = Array.new
    field_configs[field_configs.length] = {:field_name=>'short_description',:field_type=>'DropDownField',
                                           :settings=>{:label_caption=> 'organization_code',:list=>short_descriptions}}

    build_form(organization,field_configs,action,'organization',caption,false)
  end


end
