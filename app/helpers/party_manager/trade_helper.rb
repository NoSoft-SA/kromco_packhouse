module PartyManager::TradeHelper

  def build_grade_grid(data_set,can_edit,can_delete,multi_select)

  	column_configs = Array.new
    if !multi_select
      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'remove',:col_width=>50,
                                                                 :settings => {
                                                                     :link_text => 'remove',
                                                                         :target_action => 'remove_grade',
                                                                         :id_column => 'id'
                                                                         }}
    end
    grid_command = {:field_type=>'link_window_field', :field_name =>'link_grade',
                              :settings  =>
                                  {
                                      :host_and_port =>request.host_with_port.to_s,
                                      :controller    =>request.path_parameters['controller'].to_s,
                                      :target_action =>'new_grade_target_market',
                                      :link_text     => 'add grades',
                                      :id_value      =>'id'
                                  }}
  	column_configs <<  {:field_type => 'text',:field_name => 'grade_code'}
  	column_configs << {:field_type => 'text',:field_name => 'grade_description'}
  	column_configs << {:field_type => 'text',:field_name => 'qa_level'}
    column_configs << {:field_type => 'text',:field_name => 'has_recooling_fees'}
    column_configs << {:field_type => 'text',:field_name => 'has_carton_manufacturing_fees'}
    column_configs << {:field_type => 'text',:field_name => 'has_handling_dispatch_fees'}
    column_configs << {:field_type => 'text',:field_name => 'id'}

   if multi_select

     @multi_select = "selected_grades"
     return get_data_grid(data_set,column_configs,nil,true)
   else
     #column_configs[6] = {:field_type => 'text',:field_name => 'remove'}
     return get_data_grid(data_set,column_configs,nil,true,grid_command)
   end


   return get_data_grid(data_set,column_configs,nil,true,grid_command)
  end

  def build_grade_form(grade,action,caption,is_edit = nil,is_create_retry = nil)
 #	--------------------------------------------------------------------------------------------------
 #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
 #	in a composite foreign key
 #	--------------------------------------------------------------------------------------------------
 	session[:grade_form]= Hash.new
 #	---------------------------------
 #	 Define fields to build form from
 #	---------------------------------
 	 field_configs = Array.new
 	field_configs[0] = {:field_type => 'TextField',
 						:field_name => 'grade_code'}

 	field_configs[1] = {:field_type => 'TextField',
 						:field_name => 'grade_description'}

 	field_configs[2] = {:field_type => 'TextField',
 						:field_name => 'qa_level'}

     field_configs[3] = {:field_type => 'CheckBox',
     						:field_name => 'has_recooling_fees'}

     field_configs[4] = {:field_type => 'CheckBox',
      						:field_name => 'has_carton_manufacturing_fees'}

     field_configs[5] = {:field_type => 'CheckBox',
         						:field_name => 'has_handling_dispatch_fees'}

 	build_form(grade,field_configs,action,'grade',caption,is_edit)

 end

 def build_destination_country_form(destination_country,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:destination_country_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'destination_country_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'country_name_long'}

	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'country_name_short'}

	build_form(destination_country,field_configs,action,'destination_country',caption,is_edit)

end


 def build_destination_country_search_form(destination_country,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:destination_country_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["destination_country_destination_country_code"])
	#Observers for search combos

	destination_country_codes = DestinationCountry.find_by_sql('select distinct destination_country_code from destination_countries').map{|g|[g.destination_country_code]}
	destination_country_codes.unshift("<empty>")
	if is_flat_search
	else
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'destination_country_code',
						:settings => {:list => destination_country_codes}}

	build_form(destination_country,field_configs,action,'destination_country',caption,false)

end



 def build_destination_country_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'destination_country_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'country_name_long'}
	column_configs[2] = {:field_type => 'text',:field_name => 'country_name_short'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit destination_country',
			:settings =>
				 {:link_text => 'edit',
				:target_action => 'edit_destination_country',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete destination_country',
			:settings =>
				 {:link_text => 'delete',
				:target_action => 'delete_destination_country',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

 #===========
 #MARKS CODE
 #===========
 def build_mark_form(mark,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:mark_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'mark_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'mark_name'}

	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'brand_code'}

   field_configs[3] = {:field_type => 'TextField',
						:field_name => 'external_description'}

	build_form(mark,field_configs,action,'mark',caption,is_edit)

end


 def build_mark_search_form(mark,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:mark_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["mark_mark_code"])
	#Observers for search combos

	mark_codes = Mark.find_by_sql('select distinct mark_code from marks').map{|g|[g.mark_code]}
	mark_codes.unshift("<empty>")
	if is_flat_search
	else
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'mark_code',
						:settings => {:list => mark_codes}}

     field_configs[1] = {:field_type => 'TextField',
						:field_name => 'external_description'}




	build_form(mark,field_configs,action,'mark',caption,false)

end



 def build_mark_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'mark_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'mark_name'}
	column_configs[2] = {:field_type => 'text',:field_name => 'brand_code'}
  column_configs[3] = {:field_type => 'text',:field_name => 'external_description'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit mark',
			:settings =>
				 {:link_text => 'edit',
				:target_action => 'edit_mark',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete mark',
			:settings =>
				 {:link_text => 'delete',
				:target_action => 'delete_mark',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

 #=====================
 #INVENTORY CODES CODE
 #=====================
 def build_inventory_code_form(inventory_code,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:inventory_code_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'inventory_code'}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'inventory_name'}

	build_form(inventory_code,field_configs,action,'inventory_code',caption,is_edit)

end


 def build_inventory_code_search_form(inventory_code,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:inventory_code_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["inventory_code_inventory_code"])
	#Observers for search combos

	inventory_codes = InventoryCode.find_by_sql('select distinct inventory_code from inventory_codes').map{|g|[g.inventory_code]}
	inventory_codes.unshift("<empty>")
	if is_flat_search
	else
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'inventory_code',
						:settings => {:list => inventory_codes}}

	build_form(inventory_code,field_configs,action,'inventory_code',caption,false)

end



 def build_inventory_code_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'inventory_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'inventory_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit inventory_code',
			:settings =>
				 {:link_text => 'edit',
				:target_action => 'edit_inventory_code',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete inventory_code',
			:settings =>
				 {:link_text => 'delete',
				:target_action => 'delete_inventory_code',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

 #===================
 #TARGET MARKET CODE
 #===================
 def build_target_market_form(target_market,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:target_market_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
  field_configs = Array.new
    field_configs[field_configs.length] = {:field_type => 'LabelField',
        :field_name => 'target_market_code'}

  field_configs[field_configs.length] = {:field_type => 'TextField',
        :field_name => 'target_market_name'}

  field_configs[field_configs.length] = {:field_type => 'TextField',
        :field_name => 'target_market_description'}

    field_configs[field_configs.length] = {:field_type => 'TextField',
    :field_name => 'target_market_country_code'}

  field_configs[field_configs.length] = {:field_type => 'TextField',
    :field_name => 'target_market_region_code'}

   field_configs[field_configs.length] = {:field_type => 'TextField',
    :field_name => 'sector_code'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'du', :non_db_field => true, :settings => {:is_separator => false, :static_value => '', :css_class => "borderless_label_field"}}


    field_configs[field_configs.length] = {:field_type => 'CheckBox',
                                           :field_name => 'is_specific'}

    field_configs[field_configs.length] = {:field_type => 'CheckBox',
                                           :field_name => 'is_supermarket'}
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'du', :non_db_field => true, :settings => {:is_separator => false, :static_value => '', :css_class => "borderless_label_field"}}

    if is_edit
     field_configs[field_configs.length()] = {:field_type => 'Screen',
                                                     :field_name =>"child_form1",
                                                     :settings   =>{
                                                         #:host_and_port => request.host_with_port.to_s,
                                                         :controller    =>"party_manager/trade",
                                                         :target_action => 'list_grades',
                                                         :width         => 1000,
                                                         :height        => 225,
                                                         :id_value      => target_market.id.to_s,
                                                         :no_scroll     => true}}
     @submit_button_align = "left"
     set_form_layout "2", nil, 0, 10
   end

	build_form(target_market,field_configs,action,'target_market',caption,is_edit)

end


 def build_target_market_search_form(target_market,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:target_market_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["target_market_target_market_name"])
	#Observers for search combos

	target_market_names = TargetMarket.find_by_sql('select distinct target_market_name from target_markets').map{|g|[g.target_market_name]}
	target_market_names.unshift("<empty>")
	if is_flat_search
	else
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'target_market_name',
						:settings => {:list => target_market_names,
						 :label_caption => "target maket code"}}


   field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'is_supermarket',
						:settings => {:list => [['true',1],['false',0]]}}

	build_form(target_market,field_configs,action,'target_market',caption,false)

end


 def build_target_market_grid(data_set,can_edit,can_delete)

	column_configs = Array.new

	column_configs[0] = {:field_type => 'text',:field_name => 'target_market_name',:column_caption =>"target_market_code"}
	column_configs[1] = {:field_type => 'text',:field_name => 'target_market_description'}
  column_configs[2] = {:field_type => 'text',:field_name => 'target_market_code'}
  column_configs[3] = {:field_type => 'text',:field_name => 'sector_code'}
  column_configs[4] = {:field_type => 'text',:field_name => 'is_supermarket'}

#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit target_market',
			:settings =>
				 {:link_text => 'edit',
				:target_action => 'edit_target_market',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete target_market',
			:settings =>
				 {:link_text => 'delete',
				:target_action => 'delete_target_market',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

  #================================================
  # DIRECT SALES TARGET MARKET
  #================================================
  def build_direct_sales_target_market_form(direct_sales_tm,action,caption, is_edit=nil,is_create_retry=nil)
    target_market_codes = TargetMarket.find_by_sql("select distinct target_market_name from target_markets").map{|g|[g.target_market_name]}
    target_market_codes.unshift("<empty>")
    field_configs = Array.new

#    if is_edit
#      direct_sales_tm.direct_sales_target_market_code = direct_sales_tm.target_market.target_market_code
#    end

	  field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'direct_sales_target_market_code', :settings=>{:list=>target_market_codes}}
#	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'direct_sales_target_market_code'}
    field_configs[field_configs.length()] = {:field_type=>'TextArea', :field_name=>'direct_sales_target_market_description'}
#    field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'date_created', :settings => {:date_textfield_id=>'date_created'}}

    build_form(direct_sales_tm,field_configs,action,'direct_sales_tm',caption,is_edit)
  end

  def build_direct_sales_target_markets_grid(data_set,can_edit,can_delete)
      column_configs = Array.new
#      data_set.each do |record|
#        record.target_market_code = record.target_market.target_market_code
#      end
#    	column_configs[0] = {:field_type => 'text',:field_name => 'target_market_code'}
    	column_configs[0] = {:field_type => 'text',:field_name => 'direct_sales_target_market_code'}
    	column_configs[1] = {:field_type => 'text',:field_name => 'direct_sales_target_market_description'}
    	column_configs[2] = {:field_type => 'text',:field_name => 'created_on'}

      #	----------------------
      #	define action columns
      #	----------------------

      if can_edit
        column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit direct sales tm',
          :settings =>
             {:link_text => 'edit',
            :target_action => 'edit_direct_sales_target_market',
            :id_column => 'id'}}
      end

      if can_delete
        column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete direct sales tm',
          :settings =>
             {:link_text => 'delete',
            :target_action => 'delete_direct_sales_target_market',
            :id_column => 'id'}}
      end

       return get_data_grid(data_set,column_configs)
  end

end
