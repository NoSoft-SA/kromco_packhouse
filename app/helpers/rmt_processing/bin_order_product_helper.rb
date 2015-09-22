module RmtProcessing::BinOrderProductHelper


 def build_bin_order_product_form(bin_order_product,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:bin_order_product_form]= Hash.new
	ids = BinOrder.find_by_sql('select distinct id from bin_orders').map{|g|[g.id]}
	ids.unshift("<empty>")
	rmt_product_codes = RmtProduct.find_by_sql('select distinct rmt_product_code from rmt_products').map{|g|[g.rmt_product_code]}
	rmt_product_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (rmt_product_id) on related table: rmt_products
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'rmt_product_code',
						:settings => {:list => rmt_product_codes}}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'order_quantity'}

#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (bin_order_id) on related table: bin_orders
#	-----------------------------------------------------------------------------------------------------
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'id',
						:settings => {:list => ids}}


	build_form(bin_order_product,field_configs,action,'bin_order_product',caption,is_edit)

end


 def build_bin_order_product_search_form(bin_order_product,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:bin_order_product_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	order_quantities = BinOrderProduct.find_by_sql('select distinct order_quantity from bin_order_products').map{|g|[g.order_quantity]}
	order_quantities.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'order_quantity',
						:settings => {:list => order_quantities}}

	build_form(bin_order_product,field_configs,action,'bin_order_product',caption,false)

end



 def build_bin_order_product_grid(data_set,can_edit,can_delete)
   column_configs = Array.new


   if can_edit
     column_configs << {:field_type =>'link_window',:field_name => 'set_required_qty',
       :col_width => 145,
       :settings =>
     {:link_text => 'set_required_quantity',
       :target_action => 'set_required_quantity',
       :id_column => 'id',:null_test => "['status'].to_s =='LOADED'"}}
   end

   if can_delete
     column_configs << {:field_type => 'action',:field_name => 'delete',:col_width=>36,
       :settings =>
     {:image => 'delete',
       :target_action => 'delete_bin_order_product',
       :id_column => 'id',:null_test => "['status'].to_s =='LOADED'||active_record['status']== 'LOADING'"}}
   end

   column_configs << {:field_type => 'link_window',:field_name => 'status_history',
     :col_width => 105,
     :settings =>
   {:link_text => 'status_history',
     :target_action => 'status_history',
     :id_column => 'id'}}


   column_configs << {:field_type=>'text', :field_name=>'status',             :col_width => 181}
   column_configs << {:field_type=>'text', :field_name=>'available_quantity', :col_width => 90, :column_caption => 'Available'}
   column_configs << {:field_type=>'text', :field_name=>'selected_quantity',  :col_width => 90, :column_caption => 'Selected'}
   column_configs << {:field_type=>'text', :field_name=>'required_quantity',  :col_width => 90, :column_caption => 'Required'}
   column_configs << {:field_type=>'text', :field_name=>'commodity_code',:column_caption=>'commodity' ,    :col_width => 105}
   column_configs << {:field_type=>'text', :field_name=>'rmt_variety_code', :column_caption=>'rmt_variety' ,  :col_width => 125}
   column_configs << {:field_type=>'text', :field_name=>'product_class_code',:column_caption=>'product_class' , :col_width => 125}
   column_configs << {:field_type=>'text', :field_name=>'size_code',:column_caption=>'size', :col_width => 90 }
   column_configs << {:field_type=>'text', :field_name=>'farm_code',:column_caption=>'farm', :col_width => 122 }
   column_configs << {:field_type=>'text', :field_name=>'location_code',:column_caption=>'location', :col_width => 138}
   column_configs << {:field_type=>'text', :field_name=>'rmt_product_code',   :col_width => 272}
   column_configs << {:field_type=>'text', :field_name=>'id'}
   #	----------------------
   #	define action columns
   #	----------------------
   set_grid_min_height(230)
   set_grid_min_width(900)
   hide_grid_client_controls()

   get_data_grid(data_set, column_configs,MesScada::GridPlugins::RmtProcessing::BinOrderProductGridPlugin.new, true)
 end

 def  build_required_quantity_form(bin_order_product, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:order_product_form]= Hash.new

    field_configs = Array.new


     field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'required_quantity'}


    build_form(bin_order_product, field_configs, action, 'bin_order_product', caption, is_edit)

  end

end
