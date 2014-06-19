module RmtProcessing::PresortGrowerGradingFarmHelper


  def build_presort_grower_grading_farms_grid(data_set)
    column_configs = []

    column_configs << {:field_type => 'text', :field_name => 'farm_code',:col_width=>250}
    column_configs << {:field_type => 'text', :field_name => 'track_slms_indicator_code', :column_caption => 'track_slms_indicator',:col_width=>250}
    column_configs << {:field_type => 'text', :field_name => 'farm_rmt_bin_count', :column_caption => 'bin_count',:col_width=>100}
    column_configs << {:field_type => 'text', :field_name => 'farm_rmt_bin_mass',  :column_caption => 'bin_mass',:col_width=>100}
    #column_configs << {:field_type => 'text', :field_name => 'id'}

    get_data_grid(data_set,column_configs,nil,true)
  end

end