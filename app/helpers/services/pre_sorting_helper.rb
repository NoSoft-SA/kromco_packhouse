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

    build_form(nil,field_configs,action,'bin',caption)

  end
end