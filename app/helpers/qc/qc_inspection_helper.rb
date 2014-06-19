module Qc::QcInspectionHelper
 
  # Take a description and convert to a string suitable as a css class name.
  def classify_descr( desc )
    desc.downcase.gsub(' ', '_').gsub(/\W/,'')
  end

  def measure_formatted(val, for_integer=false)
    if val.nil?
      nil
    elsif val =~ /[a-zA-Z]/
      val
    elsif for_integer
      val.to_i
    else
      sprintf('%0.2f', val)
    end
  end

  def make_inspection_measure_field( measurement_rules, result_measurement, annotation_no )
    key_sample   = result_measurement.sample_no
    key_id       = result_measurement.id

    case annotation_no
    when 1
      curr_value = result_measurement.annotation_1
    when 2
      curr_value = result_measurement.annotation_2
    when 3
      curr_value = result_measurement.annotation_3
    end

    s = "<td>#{measurement_rules[:label]}</td>"

    if measurement_rules[:type] == 'CheckBox'
      s << '<td>'
      s <<  check_box_tag( "samples[#{key_sample}][annotation_#{annotation_no}_#{key_id}]", '1', curr_value == '1' )
      s << '</td>'
    end
    if measurement_rules[:type] == 'TextField'
      s << '<td>'
      s <<  text_field_tag( "samples[#{key_sample}][annotation_#{annotation_no}_#{key_id}]", curr_value, :size => 10 )
      s << '</td>'
    end
    if measurement_rules[:type] == 'DropDownField'
      values = measurement_rules[:values].split(/,\s*/)
      s << '<td>'
      s <<  select_tag( "samples[#{key_sample}][annotation_#{annotation_no}_#{key_id}]", options_for_select(values, curr_value) )
      s << '</td>'
    end

    s
  end

  # Called from _result_measurement partial
  def build_up_annotation_fields(result_measurement, max_cols, measurement_rules, for_view=false)
    code_key = result_measurement.qc_measurement_code
    s = ''
    if max_cols > 1
      if measurement_rules[code_key][:annotation_1][:active]
        if for_view
          s << "<td>#{measurement_rules[code_key][:annotation_1][:label]}</td>"
          s << "<td>#{measure_formatted( result_measurement.annotation_1 )}</td>"
        else
          s << make_inspection_measure_field( measurement_rules[code_key][:annotation_1], result_measurement, 1 )
        end
      else
        s << '<td colspan="2">&nbsp;</td>'
      end
    end
    if max_cols > 2
      if measurement_rules[code_key][:annotation_2][:active]
        if for_view
          s << "<td>#{measurement_rules[code_key][:annotation_2][:label]}</td>"
          s << "<td>#{measure_formatted( result_measurement.annotation_2 )}</td>"
        else
          s << make_inspection_measure_field( measurement_rules[code_key][:annotation_2], result_measurement, 2 )
        end
      else
        s << '<td colspan="2">&nbsp;</td>'
      end
    end
    if max_cols > 3
      if measurement_rules[code_key][:annotation_3][:active]
        if for_view
          s << "<td>#{measurement_rules[code_key][:annotation_3][:label]}</td>"
          s << "<td>#{measure_formatted( result_measurement.annotation_3 )}</td>"
        else
          s << make_inspection_measure_field( measurement_rules[code_key][:annotation_3], result_measurement, 3 )
        end
      else
        s << '<td colspan="2">&nbsp;</td>'
      end
    end
    s
  end
 
  def make_cull_inspection_measure_field( measurement_rules, result_measurement, annotation_no )
    key_sample   = result_measurement.sample_no
    key_id       = result_measurement.id

    case annotation_no
    when 2
      curr_value = result_measurement.annotation_2
    when 3
      curr_value = result_measurement.annotation_3
    end

    s = "<p>#{measurement_rules[:label]}"

      if measurement_rules[:type] == 'CheckBox'
        s <<  check_box_tag( "samples[#{key_sample}][annotation_#{annotation_no}_#{key_id}]", '1', curr_value == '1' )
      end
      if measurement_rules[:type] == 'TextField'
        s << '<br />'
        s <<  text_field_tag( "samples[#{key_sample}][annotation_#{annotation_no}_#{key_id}]", curr_value, :size => 10 )
      end
      if measurement_rules[:type] == 'DropDownField'
        values = measurement_rules[:values].split(/,\s*/)
        s << '<br />'
        s <<  select_tag( "samples[#{key_sample}][annotation_#{annotation_no}_#{key_id}]", options_for_select(values, curr_value) )
      end

    s << '</p>'
  end

  def build_up_cull_annotation_fields(result_measurement, max_cols, measurement_rules, for_view=false)
    code_key = result_measurement.qc_measurement_code
    # If a measurement code is renamed in the definition file, the exisiting result measurement will have the old code
    # and there will be a missmatch here.
    # We could match on ids, but the code is depended-upon in view code.
    raise "The measurement code for qc_measurement_type_id '#{result_measurement.qc_measurement_type_id}'
    has changed - no longer '#{code_key}'." unless measurement_rules[code_key]
    s = ''
    if measurement_rules[code_key][:annotation_2][:active]
      if for_view
        s << "<p>#{measurement_rules[code_key][:annotation_2][:label]}: #{measure_formatted( result_measurement.annotation_2 )}</p>"
      else
        s << make_cull_inspection_measure_field( measurement_rules[code_key][:annotation_2], result_measurement, 2 )
      end
    end
    if measurement_rules[code_key][:annotation_3][:active]
      if for_view
        s << "<p>#{measurement_rules[code_key][:annotation_3][:label]}: #{measure_formatted( result_measurement.annotation_3 )}</p>"
      else
        s << make_cull_inspection_measure_field( measurement_rules[code_key][:annotation_3], result_measurement, 3 )
      end
    end
    s
  end

  # Display the QcInspection business context information.
  # Displays in one or more columns based on +no_cols+ parameter.
  def display_inspection_business_info(qc_inspection, no_cols=1)
    cols=[]
    if qc_inspection.business_info
      hs = YAML.load(qc_inspection.business_info)
      hs.each do |k,v|
        cols << "<td>#{k}:</td><td class=\"heading_field\">#{v}</td>"
      end
    end
    cols.in_groups_of( no_cols ).map {|a| "<tr>#{a.to_s}</tr>" }.to_s
  end

  def build_list_business_context_grid(data_set, stat, columns_list, inspection_type_code, can_re_edit=false, grid_configs=nil)


    column_configs = []
    #  ----------------------
    #  define action columns
    #  ----------------------
    if @for_existing_inspections
      column_configs << {:field_type => 'action', :field_name => 'edit',
        :settings =>
      {:link_text      => 'edit',
        :target_action => 'edit_qc_inspection',
        :id_value      => inspection_type_code,
        :id_column     => 'id'}}
      if can_re_edit
        column_configs << {:field_type => 'action', :field_name => 're_edit',
          :settings =>
        {:link_text      => 're_edit',
          :target_action => 're_edit_qc_inspection',
          :id_value      => inspection_type_code,
          :id_column     => 'id'}}
      end
    else
      column_configs << {:field_type => 'action', :field_name => 'inspect', :column_width => 120,
        :settings =>
      {:link_text      => 'create inspection',
        :target_action => 'new_qc_inspection',
        :id_value      => inspection_type_code,
        :id_column     => 'business_object_id'}}
    end
    # Add columns to column_configs...
    build_generic_column_configs(data_set, column_configs, stat, columns_list, grid_configs)

    # Get any other datagrid options from the grid_configs...
    opts = build_grid_options_from_grid_configs(grid_configs)

    get_data_grid(data_set, column_configs, Qc::QcInspectionPlugins::ListBusinessContextGridPlugin.new, true, nil, opts)
  end
 
  def build_qc_inspection_form(qc_inspection,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:qc_inspection_form]= Hash.new
    # qc_inspection_type_codes = QcInspectionType.find_by_sql('select distinct qc_inspection_type_code from qc_inspection_types').map{|g|[g.qc_inspection_type_code]}
    # qc_inspection_type_codes.unshift("<empty>")
    if is_edit
      qc_inspection_type = QcInspectionType.find(qc_inspection.qc_inspection_type_id)
      qc_reports         = qc_inspection_type.qc_inspection_type_reports
    else
      qc_inspection_type = QcInspectionType.find(@qc_inspection_type_id)
      qc_reports         = []
    end

    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = []
    #  ----------------------------------------------------------------------------------------------
    #  Combo fields to represent foreign key (qc_inspection_type_id) on related table: qc_inspection_types
    #  ----------------------------------------------------------------------------------------------
    # field_configs << {:field_type => 'DropDownField',
    #   :field_name => 'qc_inspection_type_code',
    #   :settings => {:list => qc_inspection_type_codes}}

    field_configs <<  {:field_type => 'LabelField',
      :field_name => 'qc_inspection_type_code',
      :settings => {:static_value => qc_inspection_type.qc_inspection_type_code,
                    :show_label   => true}}

    if is_edit
      field_configs << {:field_type => 'LabelField',
        :field_name => 'inspection_number',
        :settings => {:show_label   => true}}
      field_configs << {:field_type => 'LabelField',
        :field_name => 'status',
        :settings => {:show_label   => true}}
      if qc_inspection.status == QcInspection::STATUS_COMPLETED
        pass_fail = qc_inspection.passed ? 'Passed' : 'Failed'
        pass_fail << " (for target market #{qc_inspection.failed_target_market})" if qc_inspection.failed_for_target_market
        field_configs << {:field_type => 'LabelField',
          :field_name => 'passed', 
          :settings => {:static_value => pass_fail, :label_caption => 'Pass/Fail',
            :show_label   => true}}
      end
    end

    field_configs << {:field_type => 'LabelField',
      :field_name => 'inspection_reference',
      :settings => {:show_label   => true}}
    # Could show caption as field name from inspection_type (inspection_ref_column)

    field_configs << {:field_type => 'TextField',
      :field_name => 'sample_reference'}

    field_configs << {:field_type => 'TextField',
      :field_name => 'population_size?required'}

    #TODO: pass/fail an inspection
    # if is_edit
    #   field_configs << {:field_type => 'CheckBox',
    #     :field_name => 'passed'}
    # end

    # Remark fields
    # - only show remarks that have a defined field_type.
    # - Remarks can be plain text, a checkbox or a drop-down.
    (1..3).each do |no|
      remark_type = qc_inspection_type.attributes["remark_#{no}_field_type"]
      case remark_type
      when 'CheckBox', 'TextField', 'TextArea'
        field_configs << {:field_type => remark_type,
          :field_name => "remark_#{no}",
          :settings   => {:label_caption => qc_inspection_type.attributes["remark_#{no}_label"]}}
      when 'DropDownField'
        field_configs << {:field_type => remark_type,
          :field_name => "remark_#{no}",
          :settings   => {:list => qc_inspection_type.attributes["remark_#{no}_possible_values"].split(/,\s*/),
                          :label_caption => qc_inspection_type.attributes["remark_#{no}_label"]}}
      end
    end

    if qc_inspection && qc_inspection.business_info
      s = qc_inspection.business_info
      hs = YAML.load(s)
      hs.each do |k,v|
        field_configs << {:field_type => 'LabelField',
          :field_name => k,
          :settings => {:static_value => (v || ' '), :show_label => true}}
      end
    end

    # NB Hidden fields affect the layout. So place them at the bottom!
    unless is_edit
      field_configs << {:field_type => 'HiddenField',
        :field_name => 'qc_inspection_type_id',
        :settings   => {:hidden_field_data => @qc_inspection_type_id}}

      field_configs << {:field_type => 'HiddenField',
        :field_name => 'business_object_id',
        :settings   => {:hidden_field_data => @business_object_id}}

    end

    unless qc_inspection_type.information_list_label.blank?
      field_configs << {:field_type => 'TextArea',
                        :field_name => 'information_list',
                        :settings   => {:rows => 6,
                                        :label_caption => qc_inspection_type.information_list_label}}
    end

    if is_edit
        field_configs << {:field_type=>'link_window_field',:field_name =>'summary',
                       :settings =>
                      {
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'complete_inspection',
                       :id_column=>'id',
                       :link_text => 'view/accept/reject'}} unless @show_back
      if @show_back
        field_configs << {:field_type    => 'LinkField',
          :field_name => '',
            :settings => {:controller     => @back_controller,
                          :target_action  => @back_action,
                          :link_text      => "Back",
                          :id_value       => @back_id.to_s }}
      end

      # Load extra field configs from plugin.
      if Qc::QcInspectionPlugins.const_defined?( "FormPlugin#{qc_inspection_type.qc_inspection_type_code.titlecase}" )
        klass = Qc::QcInspectionPlugins.const_get( "FormPlugin#{qc_inspection_type.qc_inspection_type_code.titlecase}" )
        klass.customize_configs( field_configs, qc_inspection, {:request => request} )
      end

      qc_reports.each do |report|
        field_configs << {:field_type => 'link_window_field', :field_name => 'Report',
                       :settings => {
                       :host_and_port => request.host_with_port.to_s,
                       :controller    => request.path_parameters['controller'].to_s ,
                       :target_action => 'send_qc_report',
                       :id_value      => "#{report.id}?qc_inspection_id=#{qc_inspection.id}",
                       :link_text     => report.report_description }}
      end

      field_configs << {:field_type => 'LabelField',
        :field_name => 'um',
        :settings => {:static_value => '</table><table>', :non_dbfield => true, :show_label => false, :css_class => 'unbordered_label_field'}}

      field_configs << {:field_type => 'Screen',
                        :field_name => "child_form1", #2",
                        :settings   => {:target_action => 'list_qc_inspection_tests',
                                        :id_value      => qc_inspection.id,
                                        :width         => 900,
                                        :height        => 180,
                                        :no_scroll     => true}
      }
    #   set_form_layout '2', false, 1, 4
    # else
    #   set_form_layout '2', false, 1, 2
    end
    set_form_layout '2'

    set_submit_button_align('left')

    build_form(qc_inspection,field_configs,action,'qc_inspection',caption,is_edit)

  end

  def build_qc_inspection_test_grid(data_set,can_edit,can_delete)

    column_configs = []
    #  ----------------------
    #  define action columns
    #  ----------------------
    if can_edit
      column_configs << {:field_type => 'link_window',:field_name => 'edit qc_inspection_test', :column_caption => 'Test', :col_width => 40,
        :settings => 
      {:link_text => 'test',
        :window_height => 600,
        :host_and_port => request.host_with_port.to_s,
        :controller    => request.path_parameters['controller'].to_s ,
        :target_action => 'edit_qc_inspection_test',
        :id_column => 'id'}}
      column_configs << {:field_type => 'link_window',:field_name => 're-edit qc_inspection_test', :column_caption => 'Re-edit',
        :settings => 
      {:link_text => 're-edit',
        :host_and_port => request.host_with_port.to_s,
        :controller    => request.path_parameters['controller'].to_s ,
        :target_action => 're_edit_qc_inspection_test',
        :id_column => 'id'}}
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete qc_inspection_test', :column_caption => 'Delete', :col_width => 50,
        :settings => 
      {:link_text => 'delete test',
        :host_and_port => request.host_with_port.to_s,
        :controller    => request.path_parameters['controller'].to_s ,
        :target_action => 'delete_qc_inspection_test',
        :id_column => 'id'}}
    end
    column_configs << {:field_type => 'link_window',:field_name => 'view qc_inspection_test', :column_caption => 'View', :col_width => 45,
      :settings => 
    {:link_text => 'view',
        :window_height => 600,
      :host_and_port => request.host_with_port.to_s,
      :controller    => request.path_parameters['controller'].to_s ,
      :target_action => 'view_qc_inspection_test',
      :id_column => 'id'}}
    column_configs << {:field_type => 'text',:field_name => 'inspection_test_number', :column_caption => 'Test #'}
    column_configs << {:field_type => 'text',:field_name => 'qc_inspection_type_test.qc_test.qc_test_code',
                       :column_caption => 'Test code', :col_width => 70}
    column_configs << {:field_type => 'text',:field_name => 'qc_inspection_type_test.qc_test.qc_test_description',
                       :column_caption => 'Test description'}
    column_configs << {:field_type => 'text',:field_name => 'status'}
    column_configs << {:field_type => 'text',:field_name => 'passed', :col_width => 70}
    column_configs << {:field_type => 'text',:field_name => 'username', :col_width => 70}
    column_configs << {:field_type => 'text',:field_name => 'created_on'}
    column_configs << {:field_type => 'text',:field_name => 'optional', :col_width => 65}

    set_grid_min_height(110)
    hide_grid_client_controls()

    return get_data_grid(data_set, column_configs, Qc::QcInspectionPlugins::ListQcInspectionTestGridPlugin.new)

  end

  def build_qc_inspection_test_form(qc_inspection_test,action,caption,is_edit = nil,is_create_retry = nil)
    #  --------------------------------------------------------------------------------------------------
    #  Define a set of observers for each composite foreign key- in effect an observer per combo involved
    #  in a composite foreign key
    #  --------------------------------------------------------------------------------------------------
    session[:qc_inspection_test_form]= Hash.new
    #  ---------------------------------
    #   Define fields to build form from
    #  ---------------------------------
    field_configs = []
    #  ----------------------------------------------------------------------------------------------------
    #  Combo field to represent foreign key (qc_inspection_id) on related table: qc_inspections
    #  -----------------------------------------------------------------------------------------------------

    field_configs << {:field_type => 'LabelField',
      :field_name => 'inspection_test_number',
      :settings => {:show_label => true}}

    field_configs << {:field_type => 'LabelField',
      :field_name => 'screen_layout',
      :settings => {:static_value => 'Use rhtml for this screen', :show_label => true}}

    #  ----------------------------------------------------------------------------------------------------
    #  Combo field to represent foreign key (qc_inspection_type_test_id) on related table: qc_inspection_type_tests
    #  -----------------------------------------------------------------------------------------------------


    build_form(qc_inspection_test,field_configs,action,'qc_inspection_test',caption,is_edit)

  end

  def build_list_tests_grid(data_set, stat, columns_list, inspection_type_code)

    column_configs = []
    #  ----------------------
    #  define action columns
    #  ----------------------
    column_configs << {:field_type => 'link_window',:field_name => 'edit qc_inspection_test', :column_caption => 'Test', :col_width => 40,
      :settings => 
    {:link_text => 'test',
      :host_and_port => request.host_with_port.to_s,
      :controller    => request.path_parameters['controller'].to_s ,
      :target_action => 'edit_qc_inspection_test_from_test_list',
      :id_column     => 'id'}}
    if (columns_list != nil && columns_list.length > 0) &&
      (stat.to_s.upcase().index("SUM(")   == nil &&
       stat.to_s.upcase().index("COUNT(") == nil &&
       stat.to_s.upcase().index("AVG(")   == nil &&
       stat.to_s.upcase().index("MAX(")   == nil &&
       stat.to_s.upcase().index("MIN(")   == nil) #&& stat.to_s.upcase.index("JOIN ") == nil)
      columns_list.each do |col|
        column_configs << {:field_type => 'text', :field_name => col.to_s.strip}
      end
    else
      data_set[0].keys.each do |key|
        column_configs << {:field_type => 'text', :field_name => key.to_s}
      end
    end

    return get_data_grid(data_set, column_configs, Qc::QcInspectionPlugins::ListQcInspectionTestGridPlugin.new, true)
  end
 
end
