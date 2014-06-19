module Fg::OrderProductTypeHelper


  def build_order_product_type_form(order_product_type, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:order_product_type_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
    field_configs[0] = {:field_type => 'TextField',
                        :field_name => 'order_product_code'}

    field_configs[1] = {:field_type => 'TextField',
                        :field_name => 'order_product_description'}

    build_form(order_product_type, field_configs, action, 'order_product_type', caption, is_edit)

  end


  def build_order_product_type_search_form(order_product_type, action, caption, is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:order_product_type_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    #Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
    order_product_codes = OrderProductType.find_by_sql('select distinct order_product_code from order_product_types').map { |g| [g.order_product_code] }
    order_product_codes.unshift("<empty>")
    field_configs[0] = {:field_type => 'DropDownField',
                        :field_name => 'order_product_code',
                        :settings => {:list => order_product_codes}}

    build_form(order_product_type, field_configs, action, 'order_product_type', caption, false)

  end


  def build_order_product_type_grid(data_set, can_edit, can_delete)

    column_configs = Array.new
    column_configs[0] = {:field_type => 'text', :field_name => 'order_product_code'}
    column_configs[1] = {:field_type => 'text', :field_name => 'order_product_description'}
#	----------------------
#	define action columns
#	----------------------
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit order_product_type',
                                                 :settings =>
                                                         {:link_text => 'edit',
                                                          :target_action => 'edit_order_product_type',
                                                          :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete order_product_type',
                                                 :settings =>
                                                         {:link_text => 'delete',
                                                          :target_action => 'delete_order_product_type',
                                                          :id_column => 'id'}}
    end
    return get_data_grid(data_set, column_configs)
  end

end
