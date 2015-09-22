module Tools::MesMafComparerHelper
  def build_mes_maf_bins_created_comparer_form(action,caption)

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type =>'PopupDateRangeSelector',
                                             :field_name =>'created_on'}

    build_form(nil,field_configs,action,'bin',caption)
  end

  def build_mes_maf_bins_created_comparer_grid(resultset)
    #require File.dirname(__FILE__) + "/../../../app/helpers/tools/mes_maf_comparer_plugins.rb"
    column_configs = []
    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'view_bin',:col_width=>34, :col_width=> 123,
                                               :settings   =>
                                                   {:image     => 'view',
                                                    :target_action => 'view_mes_bin',
                                                    :id_column     => 'mes_bin'}}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'mes_bin', :col_width=> 123}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'created_on', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'maf_bin', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'Nom_article', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'Palox_poids', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'Code_variete', :col_width=> 142}

    return get_data_grid(resultset,column_configs,MesScada::GridPlugins::Tools::MesMafBinsComparerGridPlugin.new,true)
  end

  def build_mes_maf_bins_tipped_comparer_form(action,caption)

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type =>'PopupDateRangeSelector',
                                             :field_name =>'tipped_at'}

    build_form(nil,field_configs,action,'bin',caption)
  end

  def build_mes_maf_bins_tipped_comparer_grid(resultset)
    #require File.dirname(__FILE__) + "/../../../app/helpers/tools/mes_maf_comparer_plugins.rb"
    column_configs = []
    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'view_bin',:col_width=>34, :col_width=> 123,
                                               :settings   =>
                                                   {:image     => 'view',
                                                    :target_action => 'view_mes_bin',
                                                    :id_column     => 'mes_bin'}}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'mes_bin', :col_width=> 123}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'maf_bin', :col_width=> 142}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'tipped_at', :col_width=> 142}

    return get_data_grid(resultset,column_configs,MesScada::GridPlugins::Tools::MesMafBinsComparerGridPlugin.new,true)
  end

end