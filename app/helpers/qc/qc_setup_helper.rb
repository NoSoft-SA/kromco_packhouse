module Qc::QcSetupHelper


  #*****************************************************************************
  #--------------- QC INSPECTION TYPES ----------------------------------------*
  #*****************************************************************************

  def build_qc_inspection_type_form(qc_inspection_type,action,caption,is_edit = nil,is_create_retry = nil)
    #	--------------------------------------------------------------------------------------------------
    #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #	in a composite foreign key
    #	--------------------------------------------------------------------------------------------------
    session[:qc_inspection_type_form]= Hash.new
    field_types = %w{ <empty> TextField TextArea DropDownField CheckBox }
    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
    field_configs = []
    field_configs << {:field_type => 'TextField',
      :field_name => 'qc_inspection_type_code?required',
      :settings => {:size => 10, :label_caption => 'inspection type code'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'qc_inspection_type_description?required',
      :settings => {:label_caption => 'inspection type description'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'qc_business_context_search?required',
      :settings => {:label_caption => 'business context search'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'qc_business_context_type_table_name?required',
      :settings => {:label_caption => 'business context table name'}}

    field_configs << {:field_type => 'TextArea',
      :field_name => 'qc_filter_context_search?required',
      :settings => {:label_caption => "SQL for finding<br />selected record.<br />
        WHERE must include:<br />... = {business_object_id}.",
                    :cols => 30, :rows => 6}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'inspection_ref_column?required',
      :settings => {:label_caption => 'business context column for inspection reference'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'population_size?required',
      :settings => {:label_caption => 'default population size of sample'}}

    field_configs << {:field_type => 'CheckBox',
      :field_name => 'can_fail_for_target_market'}

    field_configs << {:field_type => 'CheckBox',
      :field_name => 'auto_pass_and_complete'}

    field_configs << {:field_type => 'CheckBox',
      :field_name => 'can_re_edit_inspection'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'information_list_label',
      :settings => {:label_caption => 'Label for information list (if reqd)'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'business_info_columns_list',
      :settings => {:label_caption => 'comma-separated list of columns for info'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'remark_1_label',
      :settings   => {:label_caption => 'Remark 1 label:'}}

    field_configs <<  {:field_type => 'DropDownField',
      :field_name => 'remark_1_field_type',
      :settings => {:list => field_types,
                    :label_caption => 'Type:'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'remark_1_possible_values',
      :settings   => {:label_caption => 'values:'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'remark_2_label',
      :settings   => {:label_caption => 'Remark 2 label:'}}

    field_configs <<  {:field_type => 'DropDownField',
      :field_name => 'remark_2_field_type',
      :settings => {:list => field_types,
                    :label_caption => 'Type:'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'remark_2_possible_values',
      :settings   => {:label_caption => 'values:'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'remark_3_label',
      :settings   => {:label_caption => 'Remark 3 label:'}}

    field_configs <<  {:field_type => 'DropDownField',
      :field_name => 'remark_3_field_type',
      :settings => {:list => field_types,
                    :label_caption => 'Type:'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'remark_3_possible_values',
      :settings   => {:label_caption => 'values:'}}


#    set_form_layout '2', false, 1, 5
    set_form_layout '3', false, 13

    build_form(qc_inspection_type,field_configs,action,'qc_inspection_type',caption,is_edit)

  end


  def build_qc_inspection_type_search_form(qc_inspection_type,action,caption,is_flat_search = nil)
    #	--------------------------------------------------------------------------------------------------
    #	Define an observer for each index field
    #	--------------------------------------------------------------------------------------------------
    session[:qc_inspection_type_search_form]= Hash.new 
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["qc_inspection_type_qc_inspection_type_code"])
    #Observers for search combos

    qc_inspection_type_codes = QcInspectionType.find_by_sql('select distinct qc_inspection_type_code from qc_inspection_types').map{|g|[g.qc_inspection_type_code]}
    qc_inspection_type_codes.unshift("<empty>")
    #	----------------------------------------
    #	 Define search fields to build form from
    #	----------------------------------------
    field_configs = Array.new
    #	----------------------------------------------------------------------------------------------
    #	Define search Combo fields to represent the unique index on this table 
    #	----------------------------------------------------------------------------------------------
    field_configs <<  {:field_type => 'DropDownField',
      :field_name => 'qc_inspection_type_code',
      :settings => {:list => qc_inspection_type_codes}}

    build_form(qc_inspection_type,field_configs,action,'qc_inspection_type',caption,false)

  end



  def build_qc_inspection_type_grid(data_set,can_edit,can_delete)

    column_configs = []
    #	----------------------
    #	define action columns
    #	----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit qc_inspection_type',
        :column_caption => 'Edit',
        :settings => 
      {:link_text => 'edit',
        :target_action => 'maintain_qc_inspection_type',
        :id_column => 'id'}}
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete qc_inspection_type',
        :column_caption => 'Delete',
        :settings => 
      {:link_text => 'delete',
        :target_action => 'delete_qc_inspection_type',
        :id_column => 'id'}}
    end
    column_configs << {:field_type => 'text',:field_name => 'qc_inspection_type_code', :col_width => 200}
    column_configs << {:field_type => 'text',:field_name => 'qc_inspection_type_description', :col_width => 200}
    column_configs << {:field_type => 'text',:field_name => 'qc_business_context_search', :col_width => 200}
    column_configs << {:field_type => 'text',:field_name => 'qc_business_context_type_table_name', :col_width => 250}
    column_configs << {:field_type => 'text',:field_name => 'population_size', :col_width => 100}

    grid_command = {:field_type => 'link_window_field', :field_name => 'new_inspection_type',
                    :settings   => {
                    :host_and_port => request.host_with_port.to_s,
                    :controller    => request.path_parameters['controller'].to_s ,
                    :target_action => 'new_qc_inspection_type',
                    :link_text     => "New Inspection Type"}
                   }

    return get_data_grid(data_set, column_configs, nil, nil, grid_command)
  end

  def maintain_qc_inspection_type(id)
    field_configs = []
    field_configs << {:field_type => 'Screen',
                      :field_name => "child_form1",
                      :settings   => {:target_action => 'edit_qc_inspection_type',
                                      :id_value      => id,
                                      :width         => 900, :height => 300}
    }
    field_configs << {:field_type => 'Screen',
                      :field_name => "child_form2",
                      :settings   => {:target_action => 'list_qc_reasons',
                                      :id_value      => id,
                                      :width         => 900, :height => 200,
                                      :no_scroll     => true}
    }
    field_configs << {:field_type => 'Screen',
                      :field_name => "child_form3",
                      :settings   => {:target_action => 'list_qc_inspection_type_tests',
                                      :id_value      => id,
                                      :width         => 900, :height => 200,
                                      :no_scroll     => true}
    }
    field_configs << {:field_type => 'Screen',
                      :field_name => "child_form4",
                      :settings   => {:target_action => 'list_qc_inspection_type_reports',
                                      :id_value      => id,
                                      :width         => 900, :height => 200,
                                      :no_scroll     => true}
    }

    build_form(nil, field_configs, nil, 'edit_qc_inspection_type', 'edit inspection type')
  end

  #*****************************************************************************
  #--------------- QC REASONS -------------------------------------------------*
  #*****************************************************************************

  def build_qc_reason_form(qc_reason,action,caption,is_edit = nil,is_create_retry = nil)
    #	--------------------------------------------------------------------------------------------------
    #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #	in a composite foreign key
    #	--------------------------------------------------------------------------------------------------
    session[:qc_reason_form]= Hash.new
    qc_inspection_type_codes = QcInspectionType.find_by_sql('select distinct id, qc_inspection_type_code, qc_inspection_type_description from qc_inspection_types').map{|g|["#{g.qc_inspection_type_code} - #{g.qc_inspection_type_description}", g.id]}
    qc_inspection_type_codes.unshift(["<empty>", nil])

    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
    field_configs = []
    #	----------------------------------------------------------------------------------------------
    #	Combo fields to represent foreign key (qc_inspection_type_ids) on related table: qc_inspection_types
    #	----------------------------------------------------------------------------------------------
    if @qc_inspection_type_id
      field_configs << {:field_type => 'HiddenField',
        :field_name => 'qc_inspection_type_id',
        :settings   => {:hidden_field_data => @qc_inspection_type_id}}
      # hidden field: in_child...
      field_configs <<  {:field_type => 'LabelField',
        :field_name => 'qc_inspection_type_code',
        :settings => {:static_value => qc_inspection_type_codes.rassoc(@qc_inspection_type_id.to_i),
                      :show_label   => true}}
      is_child = 'Y'
    else
      field_configs <<  {:field_type => 'DropDownField',
        :field_name => 'qc_inspection_type_id?required',
        :settings => {:list => qc_inspection_type_codes, :label_caption => 'qc_inspection_type'}}
      is_child = 'N'
    end
    field_configs << {:field_type => 'HiddenField',
      :field_name => 'is_child_form',
      :settings   => {:hidden_field_data => is_child,
                      :non_db_field => true}}
    field_configs << {:field_type => 'TextField',
      :field_name => 'qc_reason_code?required'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'qc_reason_description?required'}

    build_form(qc_reason,field_configs,action,'qc_reason',caption,is_edit)

  end


  def build_qc_reason_search_form(qc_reason,action,caption,is_flat_search = nil)
    #	--------------------------------------------------------------------------------------------------
    #	Define an observer for each index field
    #	--------------------------------------------------------------------------------------------------
    session[:qc_reason_search_form]= Hash.new 
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["qc_reason_qc_reason_code", "qc_reason_qc_inspection_type_id"])
    #Observers for search combos

    qc_reason_codes = QcReason.find_by_sql('select distinct qc_reason_code from qc_reasons').map{|g|[g.qc_reason_code]}
    qc_reason_codes.unshift("<empty>")
    qc_inspection_type_codes = QcInspectionType.find_by_sql('select distinct id, qc_inspection_type_code from qc_inspection_types').map{|g|[g.qc_inspection_type_code, g.id]}
    qc_inspection_type_codes.unshift("<empty>")
    #	----------------------------------------
    #	 Define search fields to build form from
    #	----------------------------------------
    field_configs = []
    #	----------------------------------------------------------------------------------------------
    #	Define search Combo fields to represent the unique index on this table 
    #	----------------------------------------------------------------------------------------------
    field_configs <<  {:field_type => 'DropDownField',
      :field_name => 'qc_reason_code',
      :settings => {:list => qc_reason_codes}}
    field_configs <<  {:field_type => 'DropDownField',
      :field_name => 'qc_inspection_type_id',
      :settings => {:list => qc_inspection_type_codes}}

    build_form(qc_reason,field_configs,action,'qc_reason',caption,false)

  end



  def build_qc_reason_grid(data_set,can_edit,can_delete)
    column_configs = []
    #	----------------------
    #	define action columns
    #	----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit qc_reason', :column_caption => 'Edit',
        :settings => 
       {:link_text     => 'edit',
        :target_action => "edit_qc_reason",
        :id_column     => 'id'}}
      column_configs.last[:settings][:id_value] = 'child' if @in_child
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete qc_reason', :column_caption => 'Delete',
        :settings => 
       {:link_text     => 'delete',
        :target_action => 'delete_qc_reason',
        :id_column     => 'id'}}
      column_configs.last[:settings][:id_value] = 'child' if @in_child
    end
    # If data set is a joined query, the model has the field as an attribute.
    # If it is from a search query, the model has the field on its included association.
    if data_set.first && data_set.first.has_attribute?( 'qc_inspection_type_code' )
      the_code = 'qc_inspection_type_code'
      the_desc = 'qc_inspection_type_description'
    else
      the_code = 'qc_inspection_type.qc_inspection_type_code'
      the_desc = 'qc_inspection_type.qc_inspection_type_description'
    end
    column_configs << {:field_type => 'text',:field_name => the_code,
                       :column_caption => 'qc_inspection_type_code',
                       :col_width   => 160}
    column_configs << {:field_type => 'text',:field_name => the_desc,
                       :column_caption => 'qc_inspection_type_description',
                       :col_width   => 200}
    column_configs << {:field_type => 'text',:field_name => 'qc_reason_code',
                       :col_width   => 120}
    column_configs << {:field_type => 'text',:field_name => 'qc_reason_description',
                       :col_width   => 220}

    grid_command = {:field_type => 'link_window_field', :field_name => 'new_reason',
                    :settings   => {
                    :host_and_port => request.host_with_port.to_s,
                    :controller    => request.path_parameters['controller'].to_s ,
                    :target_action => 'new_qc_reason',
                    :link_text     => "new reason"}
                   }
    grid_command[:settings][:id_value] = @qc_inspection_type_id if @in_child

    if @in_child
      set_grid_min_height(100)
      hide_grid_client_controls()
    end
    return get_data_grid(data_set, column_configs, nil, nil, grid_command)
  end

  #*****************************************************************************
  #--------------- QC INSPECTION TYPE TESTS -----------------------------------*
  #*****************************************************************************

  def build_qc_inspection_type_test_grid(data_set,can_edit,can_delete)

    column_configs = []
    #	----------------------
    #	define action columns
    #	----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit qc_inspection_type_test',
        :column_caption => 'Edit',
        :settings => 
      {:link_text => 'edit',
        :target_action => 'edit_qc_inspection_type_test',
        :id_column => 'id'}}
      column_configs.last[:settings][:id_value] = 'child' if @in_child
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete qc_inspection_type_test',
        :column_caption => 'Delete',
        :settings => 
      {:link_text => 'delete',
        :target_action => 'delete_qc_inspection_type_test',
        :id_column => 'id'}}
      column_configs.last[:settings][:id_value] = 'child' if @in_child
    end
    column_configs << {:field_type => 'text',:field_name => 'qc_test_code'}
    column_configs << {:field_type => 'text',:field_name => 'qc_test_description', :col_width => 200 }
    column_configs << {:field_type => 'text',:field_name => 'sample_size'}
    column_configs << {:field_type => 'text',:field_name => 'filter_column', :col_width => 150 }
    column_configs << {:field_type => 'text',:field_name => 'filter_value', :col_width => 150 }
    column_configs << {:field_type => 'text',:field_name => 'optional', :data_type => 'boolean' }

    grid_command = {:field_type => 'link_window_field', :field_name => 'new_test',
                    :settings   => {
                    :host_and_port => request.host_with_port.to_s,
                    :controller    => request.path_parameters['controller'].to_s ,
                    :target_action => 'new_qc_inspection_type_test',
                    :id_value      => @qc_inspection_type_id,
                    :link_text     => "New Test"}
                   }

    if @in_child
      set_grid_min_height(100)
      hide_grid_client_controls()
    end
    return get_data_grid(data_set,column_configs, nil, nil, grid_command)
  end

  def build_qc_inspection_type_test_form(qc_inspection_type_test,action,caption,is_edit = nil,is_create_retry = nil)
    #	--------------------------------------------------------------------------------------------------
    #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #	in a composite foreign key
    #	--------------------------------------------------------------------------------------------------
    session[:qc_inspection_type_test_form]= Hash.new
    qc_inspection_type_codes = QcInspectionType.find_by_sql('select distinct id, qc_inspection_type_code from qc_inspection_types').map{|g|[g.qc_inspection_type_code, g.id]}
    qc_inspection_type_codes.unshift(["<empty>", nil])
    qc_test_ids = QcTest.find_by_sql('select id, qc_test_code, qc_test_description from qc_tests order by qc_test_code').map{|g|["#{g.qc_test_code} - #{g.qc_test_description}", g.id]}
#    qc_test_ids.unshift(["<empty>", nil])
    # used_ids = QcInspectionTypeTest.find(:all, :conditions => ['qc_inspection_type_id = ?', @qc_inspection_type_id]).map {|m| m.qc_test_id }
    # qc_test_ids.reject! {|t| used_ids.include?( t[1] ) }

    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
    field_configs = []
    #	----------------------------------------------------------------------------------------------------
    #	Combo field to represent foreign key (qc_test_id) on related table: qc_tests
    #	-----------------------------------------------------------------------------------------------------
    if @qc_inspection_type_id
      field_configs << {:field_type => 'HiddenField',
        :field_name => 'qc_inspection_type_id',
        :settings   => {:hidden_field_data => @qc_inspection_type_id}}
      field_configs <<  {:field_type => 'LabelField',
        :field_name => 'qc_inspection_type_code',
        :settings => {:static_value => qc_inspection_type_codes.rassoc(@qc_inspection_type_id.to_i)[0],
                      :show_label   => true}}
      is_child = 'Y'
    else
      field_configs <<  {:field_type => 'DropDownField',
        :field_name => 'qc_inspection_type_id',
        :settings => {:list => qc_inspection_type_codes,
                      :label_caption => 'qc inspection type'}}
      is_child = 'N'
    end
    field_configs << {:field_type => 'HiddenField',
      :field_name => 'is_child_form',
      :settings   => {:hidden_field_data => is_child,
                      :non_db_field => true}}

    field_configs << {:field_type => 'DropDownField',
      :field_name => 'qc_test_id?required',
      :settings   => {:list => qc_test_ids,
                      :label_caption => 'qc test'}}


    #	----------------------------------------------------------------------------------------------
    #	Combo fields to represent foreign key (qc_inspection_type_id) on related table: qc_inspection_types
    #	----------------------------------------------------------------------------------------------

    field_configs << {:field_type => 'TextField',
      :field_name => 'sample_size?required'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'filter_column?required'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'filter_value?required'}

    field_configs << {:field_type => 'CheckBox',
      :field_name => 'optional'}

    field_configs << {:field_type => 'CheckBox',
      :field_name => 'cull_test'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'cull_columns'}

    build_form(qc_inspection_type_test,field_configs,action,'qc_inspection_type_test',caption,is_edit)

  end

  #*****************************************************************************
  #--------------- QC INSPECTION TYPE REPORTS ---------------------------------*
  #*****************************************************************************

  def build_qc_inspection_type_report_form(qc_inspection_type_report,action,caption,is_edit = nil,is_create_retry = nil)
    #	--------------------------------------------------------------------------------------------------
    #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #	in a composite foreign key
    #	--------------------------------------------------------------------------------------------------
    session[:qc_inspection_type_report_form]= Hash.new
    qc_inspection_type_codes = QcInspectionType.find_by_sql('select distinct id, qc_inspection_type_code, qc_inspection_type_description from qc_inspection_types').map{|g|["#{g.qc_inspection_type_code} - #{g.qc_inspection_type_description}", g.id]}
    qc_inspection_type_codes.unshift(["<empty>", nil])

    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
    field_configs = []
    #	----------------------------------------------------------------------------------------------
    #	Combo fields to represent foreign key (qc_inspection_type_ids) on related table: qc_inspection_types
    #	----------------------------------------------------------------------------------------------
    field_configs << {:field_type => 'HiddenField',
      :field_name => 'qc_inspection_type_id',
      :settings   => {:hidden_field_data => @qc_inspection_type_id}}
    # hidden field: in_child...
    field_configs <<  {:field_type => 'LabelField',
      :field_name => 'qc_inspection_type_code',
      :settings => {:static_value => qc_inspection_type_codes.rassoc(@qc_inspection_type_id.to_i),
                    :show_label   => true}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'report_name?required'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'report_description?required'}

    build_form(qc_inspection_type_report,field_configs,action,'qc_inspection_type_report',caption,is_edit)

  end

  def build_qc_inspection_type_report_grid(data_set,can_edit,can_delete)
    column_configs = []
    #	----------------------
    #	define action columns
    #	----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit qc_inspection_type_report', :column_caption => 'Edit',
        :settings => 
       {:link_text     => 'edit',
        :target_action => "edit_qc_inspection_type_report",
        :id_column     => 'id'}}
#      column_configs.last[:settings][:id_value] = 'child' if @in_child
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete qc_inspection_type_report', :column_caption => 'Delete',
        :settings => 
       {:link_text     => 'delete',
        :target_action => 'delete_qc_inspection_type_report',
        :id_column     => 'id'}}
#      column_configs.last[:settings][:id_value] = 'child' if @in_child
    end
    # If data set is a joined query, the model has the field as an attribute.
    # If it is from a search query, the model has the field on its included association.
    # if data_set.first && data_set.first.has_attribute?( 'qc_inspection_type_code' )
    #   the_code = 'qc_inspection_type_code'
    #   the_desc = 'qc_inspection_type_description'
    # else
    #   the_code = 'qc_inspection_type.qc_inspection_type_code'
    #   the_desc = 'qc_inspection_type.qc_inspection_type_description'
    # end
    # column_configs << {:field_type => 'text',:field_name => the_code,
    #                    :column_caption => 'qc_inspection_type_code',
    #                    :col_width   => 160}
    # column_configs << {:field_type => 'text',:field_name => the_desc,
    #                    :column_caption => 'qc_inspection_type_description',
    #                    :col_width   => 200}
    column_configs << {:field_type => 'text',:field_name => 'qc_inspection_type_code',
                       :column_caption => 'qc_inspection_type_code',
                       :col_width   => 160}
    column_configs << {:field_type => 'text',:field_name => 'qc_inspection_type_description',
                       :column_caption => 'qc_inspection_type_description',
                       :col_width   => 200}
    column_configs << {:field_type => 'text',:field_name => 'report_name',
                       :col_width   => 120}
    column_configs << {:field_type => 'text',:field_name => 'report_description',
                       :col_width   => 220}

    grid_command = {:field_type => 'link_window_field', :field_name => 'new_report',
                    :settings   => {
                    :host_and_port => request.host_with_port.to_s,
                    :controller    => request.path_parameters['controller'].to_s ,
                    :target_action => 'new_qc_inspection_type_report',
                    :link_text     => "new report",
                    :id_value      => @qc_inspection_type_id}
                   }
#    grid_command[:settings][:id_value] = @qc_inspection_type_id if @in_child

#    if @in_child
      set_grid_min_height(100)
#      hide_grid_client_controls()
#    end
    return get_data_grid(data_set, column_configs, nil, nil, grid_command)
  end

  #*****************************************************************************
  #--------------- QC TESTS ---------------------------------------------------*
  #*****************************************************************************
 
  def build_qc_test_form(qc_test,action,caption,is_edit = nil,is_create_retry = nil)
    #	--------------------------------------------------------------------------------------------------
    #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #	in a composite foreign key
    #	--------------------------------------------------------------------------------------------------
    session[:qc_test_form]= Hash.new
    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
    field_configs = []

    field_configs << {:field_type => 'TextField',
      :field_name => 'qc_test_code?required'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'qc_test_description?required'}

    build_form(qc_test,field_configs,action,'qc_test',caption,is_edit)

  end


  def build_qc_test_search_form(qc_test,action,caption,is_flat_search = nil)
    #	--------------------------------------------------------------------------------------------------
    #	Define an observer for each index field
    #	--------------------------------------------------------------------------------------------------
    session[:qc_test_search_form]= Hash.new 
    #generate javascript for the on_complete ajax event for each combo
    #Observers for search combos
    #	----------------------------------------
    #	 Define search fields to build form from
    #	----------------------------------------
    field_configs = Array.new
    qc_test_codes = QcTest.find_by_sql('select distinct qc_test_code from qc_tests').map{|g|[g.qc_test_code]}
    qc_test_codes.unshift("<empty>")
    field_configs << {:field_type => 'DropDownField',
      :field_name => 'qc_test_code',
      :settings => {:list => qc_test_codes}}

    build_form(qc_test,field_configs,action,'qc_test',caption,false)

  end



  def build_qc_test_grid(data_set,can_edit,can_delete)

    column_configs = []
    #	----------------------
    #	define action columns
    #	----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit qc_test',
        :column_caption => 'Edit',
        :settings => 
      {:link_text => 'edit',
        :target_action => 'maintain_qc_test',
        :id_column => 'id'}}
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete qc_test',
        :column_caption => 'Delete',
        :settings => 
      {:link_text => 'delete',
        :target_action => 'delete_qc_test',
        :id_column => 'id'}}
    end
    column_configs << {:field_type => 'text',:field_name => 'qc_test_code'}
    column_configs << {:field_type => 'text',:field_name => 'qc_test_description', :col_width => 250}

    grid_command = {:field_type => 'link_window_field', :field_name => 'new_test',
                    :settings   => {
                    :host_and_port => request.host_with_port.to_s,
                    :controller    => request.path_parameters['controller'].to_s ,
                    :target_action => 'new_qc_test',
                    :link_text     => "New Test"}
                   }

    return get_data_grid(data_set,column_configs, nil, nil, grid_command)
  end

  def maintain_qc_test(id)
    field_configs = []
    field_configs << {:field_type => 'Screen',
                      :field_name => "child_form1",
                      :settings   => {:target_action => 'edit_qc_test',
                                      :id_value      => id,
                                      :width         => 900, :height => 150}
    }
    field_configs << {:field_type => 'Screen',
                      :field_name => "child_form2",
                      :settings   => {:target_action => 'list_qc_measurement_types',
                                      :id_value      => id,
                                      :width         => 900, :height => 250,
                                      :no_scroll     => true}
    }
#TODO: Inspection_types that use this test
    # field_configs << {:field_type => 'Screen',
    #                   :field_name => "child_form3",
    #                   :settings   => {:target_action => 'list_qc_inspection_type_tests',
    #                                   :id_value      => id,
    #                                   :width         => 900}
    # }

    build_form(nil, field_configs, nil, 'edit_qc_test', 'edit test')
  end

  #*****************************************************************************
  #--------------- QC MEASUREMENT TYPES ---------------------------------------*
  #*****************************************************************************

  def build_qc_measurement_type_form(qc_measurement_type,action,caption,is_edit = nil,is_create_retry = nil)
    #	--------------------------------------------------------------------------------------------------
    #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #	in a composite foreign key
    #	--------------------------------------------------------------------------------------------------
    session[:qc_measurement_type_form]= Hash.new
    qc_test_codes = QcTest.find_by_sql('select distinct id, qc_test_code from qc_tests').map{|g|[g.qc_test_code, g.id]}
    qc_test_codes.unshift(["<empty>", nil])
    field_types = %w{ <empty> TextField DropDownField CheckBox }

    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
    field_configs = []
    #	----------------------------------------------------------------------------------------------
    #	Combo fields to represent foreign key (qc_test_ids) on related table: qc_tests
    #	----------------------------------------------------------------------------------------------
    if @qc_test_id
      field_configs << {:field_type => 'HiddenField',
        :field_name => 'qc_test_id',
        :settings   => {:hidden_field_data => @qc_test_id}}
      # hidden field: in_child...
      field_configs <<  {:field_type => 'LabelField',
        :field_name => 'qc_test_code',
        :settings => {:static_value => qc_test_codes.rassoc(@qc_test_id.to_i)[0],
                      :show_label   => true}}
      is_child = 'Y'
    else
      field_configs <<  {:field_type => 'DropDownField',
        :field_name => 'qc_test_id',
        :settings => {:list => qc_test_codes}}
      is_child = 'N'
    end
    field_configs << {:field_type => 'HiddenField',
      :field_name => 'is_child_form',
      :settings   => {:hidden_field_data => is_child,
                      :non_db_field => true}}
    field_configs << {:field_type => 'TextField',
      :field_name => 'qc_measurement_code?required'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'qc_measurement_description?required'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'test_uom?required'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'test_criteria?required'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'test_method?required'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'annotation_1_label',
      :settings   => {:label_caption => 'Annotation 1 label:'}}

    field_configs <<  {:field_type => 'DropDownField',
      :field_name => 'annotation_1_field_type',
      :settings => {:list => field_types,
                    :label_caption => 'Type:'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'annotation_1_possible_values',
      :settings   => {:label_caption => 'values:'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'annotation_2_label',
      :settings   => {:label_caption => 'Annotation 2 label:'}}

    field_configs <<  {:field_type => 'DropDownField',
      :field_name => 'annotation_2_field_type',
      :settings => {:list => field_types,
                    :label_caption => 'Type:'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'annotation_2_possible_values',
      :settings   => {:label_caption => 'values:'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'annotation_3_label',
      :settings   => {:label_caption => 'Annotation 3 label:'}}

    field_configs <<  {:field_type => 'DropDownField',
      :field_name => 'annotation_3_field_type',
      :settings => {:list => field_types,
                    :label_caption => 'Type:'}}

    field_configs << {:field_type => 'TextField',
      :field_name => 'annotation_3_possible_values',
      :settings   => {:label_caption => 'values:'}}

    #set_form_layout '4', false, 1, 8 # This does nothing!
    set_form_layout '2', false, nil, 8 # This does nothing!
    set_form_layout '3', false, 9

    build_form(qc_measurement_type,field_configs,action,'qc_measurement_type',caption,is_edit)

  end



  def build_qc_measurement_type_grid(data_set,can_edit,can_delete)
    column_configs = []
    #	----------------------
    #	define action columns
    #	----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit qc_measurement_type',
        :column_caption => 'Edit',
        :settings => 
       {:link_text     => 'edit',
        :target_action => "edit_qc_measurement_type",
        :id_column     => 'id'}}
      column_configs.last[:settings][:id_value] = 'child' if @in_child
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete qc_measurement_type',
        :column_caption => 'Delete',
        :settings => 
       {:link_text     => 'delete',
        :target_action => 'delete_qc_measurement_type',
        :id_column     => 'id'}}
      column_configs.last[:settings][:id_value] = 'child' if @in_child
    end
    # If data set is a joined query, the model has the field as an attribute.
    # If it is from a search query, the model has the field on its included association.
    if data_set.first && data_set.first.has_attribute?( 'qc_test_code' )
      the_code = 'qc_test_code'
      the_desc = 'qc_test_description'
    else
      the_code = 'qc_test.qc_test_code'
      the_desc = 'qc_test.qc_test_description'
    end
    column_configs << {:field_type => 'text',:field_name => the_code,
                       :column_caption => 'Test Code' }
    column_configs << {:field_type => 'text',:field_name => the_desc,
                       :column_caption => 'Test Description',
                       :col_width => 200 }
    column_configs << {:field_type => 'text',:field_name => 'qc_measurement_code',
                       :column_caption => 'Measurement Code',
                       :col_width => 150}
    column_configs << {:field_type => 'text',:field_name => 'qc_measurement_description',
                       :column_caption => 'Measurement Description',
                       :col_width => 200 }
    column_configs << {:field_type => 'text',:field_name => 'test_uom'}
    column_configs << {:field_type => 'text',:field_name => 'test_criteria'}
    column_configs << {:field_type => 'text',:field_name => 'test_method'}
    column_configs << {:field_type => 'text',:field_name => 'annotation_1_label'}
    column_configs << {:field_type => 'text',:field_name => 'annotation_1_field_type'}
#    column_configs << {:field_type => 'text',:field_name => 'annotation_1_possible_values'}
    column_configs << {:field_type => 'text',:field_name => 'annotation_2_label'}
    column_configs << {:field_type => 'text',:field_name => 'annotation_2_field_type'}
#    column_configs << {:field_type => 'text',:field_name => 'annotation_2_possible_values'}
    column_configs << {:field_type => 'text',:field_name => 'annotation_3_label'}
    column_configs << {:field_type => 'text',:field_name => 'annotation_3_field_type'}
#    column_configs << {:field_type => 'text',:field_name => 'annotation_3_possible_values'}

    grid_command = {:field_type => 'link_window_field', :field_name => 'new_measurement_type',
                    :settings   => {
                    :host_and_port => request.host_with_port.to_s,
                    :controller    => request.path_parameters['controller'].to_s ,
                    :target_action => 'new_qc_measurement_type',
                    :link_text     => "New Measurement Type"}
                   }
    grid_command[:settings][:id_value] = @qc_test_id if @in_child

    if @in_child
      set_grid_min_height(150)
      hide_grid_client_controls()
    end
    return get_data_grid(data_set, column_configs, nil, nil, grid_command)
  end

end
