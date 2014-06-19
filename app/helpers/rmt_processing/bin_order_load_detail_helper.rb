module RmtProcessing::BinOrderLoadDetailHelper

   def build_bins_grid(data_set,can_edit,can_delete)
     require File.dirname(__FILE__) + "/../../../app/helpers/rmt_processing/bin_plugins.rb"
    column_configs = Array.new

     column_configs << {:field_type => 'action',:field_name => 'remove_bin',:col_width=>74,
			:settings =>
				 {:link_text => '',
				:target_action => '',
				:id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_number',:col_width=>114}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exit_ref',:col_width=>62}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exit_reference_date_time',:col_width=>126}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'destroyed',:col_width=>66}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'tipped_date_time',:col_width=>118}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'delivery_number',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_product_code',:col_width=>272}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code',:column_caption=>'farm',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_code',:col_width=>209}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pack_material_product_code',:col_width=>113}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_receive_date_time',:col_width=>119}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_status',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_track_indicator_code',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code1',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code2',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code3',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code4',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code5',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_date_time',:col_width=>121}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'user_name',:col_width=>105}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'print_number',:column_caption=>'print_num',:col_width=>68}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_order_load_detail_id',:col_width=>141}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id',:col_width=>66}
      @multi_select = "remove_bins"


    set_grid_min_width(1200)
    return get_data_grid(data_set,column_configs,RmtProcessingPlugins::BinGridPlugin.new,true)

  end

  def  build_required_quantity_form(bin_order_load_detail, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:order_product_form]= Hash.new

    field_configs = Array.new


     field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'required_quantity'}


    build_form(bin_order_load_detail, field_configs, action, 'bin_order_load_detail', caption, is_edit)

  end




 def build_bin_order_load_detail_search_form(bin_order_load_detail,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:bin_order_load_detail_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	bin_order_loads = BinOrderLoadDetail.find_by_sql('select distinct bin_order_load from bin_order_load_details').map{|g|[g.bin_order_load]}
	bin_order_loads.unshift("<empty>")
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'bin_order_load',
						:settings => {:list => bin_order_loads}}

	build_form(bin_order_load_detail,field_configs,action,'bin_order_load_detail',caption,false)

end



 def build_bin_order_load_detail_grid(data_set,can_edit,can_delete)
   require File.dirname(__FILE__) + "/../../../app/helpers/rmt_processing/bin_order_load_detail_plugins.rb"
	column_configs = Array.new


	if can_delete
		column_configs << {:field_type => 'action',:field_name => 'delete', :col_width=>36,
			:settings =>
				 {:image => 'delete',
				:target_action => 'delete_bin_order_load_detail',
				:id_column => 'id',:null_test => "status == 'LOADED'||active_record['status']== 'LOADING'"}}
    end


  column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'status_history', :col_width=>75,
             :settings =>
                {:link_text => 'status_history',
               :target_action => 'status_history',
               :id_column => 'id'}}


    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'status' ,:col_width=>153}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'available_quantity',:column_caption=>'Available',:col_width=>58}
    column_configs[column_configs.length()] = {:field_type=>'link_window', :field_name=>'selected_quantity',:column_caption=>'Selected',:col_width=>58,
                                              :settings =>
                                                 {
                                                 :non_db_field => true,
                                                :target_action => 'selected_quantity',
                                                :id_column => 'id',:null_test => "selected_quantity == 0"}}

    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'required_quantity',:column_caption=>'Required',:col_width=>61}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'commodity_code',:column_caption=>'commodity',:col_width=>72}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'rmt_variety_code',:column_caption=>'rmt_variety',:col_width=>73}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'product_class_code',:column_caption=>'product_class',:col_width=>90}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'size_code',:column_caption=>'size',:col_width=>50}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'farm_code',:column_caption=>'farm',:col_width=>122}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'location_code',:column_caption=>'location',:col_width=>138}
     column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'rmt_product_code',:col_width=>272}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'id'}

#	----------------------
#	define action columns
#	----------------------
  set_grid_min_height(230)
     set_grid_min_width(900)
     hide_grid_client_controls()
 return get_data_grid(data_set,column_configs,RmtProcessingPlugins::BinOrderLoadDetailGridPlugin.new,nil)

end

#    key_based_access = @key_based_access if @key_based_access
#
#    set_grid_min_width(1200)
#    return get_data_grid(data_set, column_configs, nil, key_based_access)
end
