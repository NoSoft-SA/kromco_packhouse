module QualityControl::QcBarcodesHelper

  def build_qc_barcode_form(qc_barcode,action,caption, is_edit=nil,is_create_retry=nil)
    field_configs = Array.new
	  
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'pass_fail_barcode'}
	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'operator'}
	  field_configs[field_configs.length()] = {:field_type=>'CheckBox', :field_name=>'pass_fail_boolean'}
	  field_configs[field_configs.length()] = {:field_type=>'TextArea', :field_name=>'qc_description'}
	 
	  build_form(qc_barcode,field_configs,action,'qc_barcode',caption,is_edit)
  end

  def build_qc_barcodes_grid(data_set,can_edit,can_delete)
    column_configs = Array.new
    column_configs[0] = {:field_type => 'text',:field_name => 'pass_fail_barcode'}
    column_configs[1] = {:field_type => 'text',:field_name => 'operator'}
    column_configs[2] = {:field_type => 'text',:field_name => 'pass_fail_boolean'}
    column_configs[3] = {:field_type => 'text',:field_name => 'qc_description'}

    #	----------------------
    #	define action columns
    #	----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit qc_barcode',
        :settings =>
           {:link_text => 'edit',
          :target_action => 'edit_qc_barcode',
          :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete qc_barcode',
        :settings =>
           {:link_text => 'delete',
          :target_action => 'delete_qc_barcode',
          :id_column => 'id'}}
    end

    return get_data_grid(data_set,column_configs)
  end

end