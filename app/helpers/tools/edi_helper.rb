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

end

