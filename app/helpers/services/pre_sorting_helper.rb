module Services::PreSortingHelper
  def build_manual_integation_form(action,caption)
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table
#	----------------------------------------------------------------------------------------------
    field_configs << {:field_type =>'LabelField',:field_name =>'example',
                      :settings=>{:static_value=>'bin_tipped?bin=635140<br>,bin_created?bin=635134',:label_caption=>'e.g.',:show_label=>true}}
    field_configs <<  {:field_type => 'TextArea',
                         :field_name => 'integration_params'}
    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'presort_unit',
                      :settings => {:list =>['<empty>','PST-01', 'PST-02']}}


    build_form(nil,field_configs,action,'bin',caption)

  end

  def build_forced_staging_form(action, caption)

    #	---------------------------------
    #	 Define fields to build form from
    #	---------------------------------
    field_configs = Array.new


    field_configs << {:field_type => 'TextField',:field_name => 'bin1'}
    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'presort_unit',
                      :settings => {:list =>['<empty>','PST-01', 'PST-02']}}
    # field_configs << {:field_type => 'TextField',:field_name => 'bin2'}
    # field_configs << {:field_type => 'TextField',:field_name => 'bin3'}

    build_form(nil, field_configs, action, 'staging', caption)

  end

  def build_presort_staging_run_grid(data_set,can_edit,can_delete)
    # require File.dirname(__FILE__) + "/../../../app/helpers/rmt_processing/presort_staging_run_plugin.rb"
    column_configs = []
#	----------------------
#	define action columns
#	----------------------
    column_configs << {:field_type => 'action',:field_name => 'select presort_staging_run',
                       :column_caption => 'select',
                       :settings =>
                           {:link_text => 'select',
                            :target_action => 'select_presort_staging_run',
                            :id_column => 'id'}}

    column_configs << {:field_type => 'text', :field_name => 'presort_run_code', :column_caption => 'Pre sort run code',:col_width=>180}
    column_configs << {:field_type => 'text', :field_name => 'status', :column_caption => 'Status'}
    column_configs << {:field_type => 'text', :field_name => 'rmt_variety_code'}
    column_configs << {:field_type => 'text', :field_name => 'ripe_point_code',:col_width=>50}
    column_configs << {:field_type => 'text', :field_name => 'track_slms_indicator_code'}
    column_configs << {:field_type => 'text', :field_name => 'farm_group_code'}
    column_configs << {:field_type => 'text', :field_name => 'season_code'}
    column_configs << {:field_type => 'text', :field_name => 'product_class_code'}
    column_configs << {:field_type => 'text', :field_name => 'treatment_code'}
    column_configs << {:field_type => 'text', :field_name => 'size_code'}
    column_configs << {:field_type => 'text', :field_name => 'created_on', :data_type => 'date', :column_caption => 'Created on'}
    column_configs << {:field_type => 'text', :field_name => 'completed_on', :data_type => 'date', :column_caption => 'Completed on'}
    column_configs << {:field_type => 'text', :field_name => 'created_by', :column_caption => 'Created by'}

    get_data_grid(data_set,column_configs,nil)

  end

  def build_presort_staging_run_child_grid(data_set)
    column_configs = []
    column_configs << {:field_type => 'action',:field_name => 'select presort_staging_run_child',
                       :column_caption => 'select',
                       :settings =>
                           {:link_text => 'select',
                            :target_action => 'force_stage_bin',
                            :id_column => 'id'}}
    column_configs << {:field_type => 'text', :field_name => 'presort_staging_run_child_code',:col_width=>250}
    column_configs << {:field_type => 'text', :field_name => 'farm_code', :column_caption => 'Farm code'}
    column_configs << {:field_type => 'text', :field_name => 'status',:settings =>{:target_action => 'edit_child_status', :id_column => 'id'}, :column_caption => 'Status'}
    column_configs << {:field_type => 'text', :field_name => 'created_on', :data_type => 'date', :column_caption => 'Created on'}
    column_configs << {:field_type => 'text', :field_name => 'updated_on', :data_type => 'date', :column_caption => 'Updated on'}
    column_configs << {:field_type => 'text', :field_name => 'created_by', :column_caption => 'Created by'}
    column_configs << {:field_type => 'text', :field_name => 'completed_on', :data_type => 'date', :column_caption => 'Completed on'}
    column_configs << {:field_type => 'text', :field_name => 'updated_by', :column_caption => 'Updated by'}
    column_configs << {:field_type => 'text', :field_name => 'id'}

    get_data_grid(data_set,column_configs,nil)
  end


end