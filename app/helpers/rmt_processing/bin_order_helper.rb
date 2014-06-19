module RmtProcessing::BinOrderHelper


  def build_bin_order_form(bin_order, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:bin_order_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = Array.new
    order_types = OrderType.find(:all).map { |g| [g.order_type_code, g.id] }
    customer_party_roles = PartiesRole.find_by_sql("SELECT id ,party_name FROM parties_roles WHERE role_name = 'CUSTOMER'").map { |g| [g.party_name, g.id] }
    trading_partners =PartiesRole.find_by_sql("SELECT id, party_name,remarks FROM parties_roles WHERE role_name = 'TRADING PARTNER'").map { |g|
      if g.remarks != nil
        [g.party_name + ":" +"     " + "     " + g.remarks, g.id]
      else
        [g.party_name, g.id]
      end }
    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'order_type_id',
                                             :settings=>{:list => order_types, :label_caption=>'order type code'}}

    #field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'bin_order_number'}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'trading_partner_party_role_id',
                                             :settings=>{:list =>trading_partners, :label_caption=>'trading_partner'}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'customer_party_role_id',
                                             :settings=>{:list =>customer_party_roles, :label_caption=>'customer party role'}}

    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'customer_order_number'}

    field_configs[field_configs.length()] = {:field_type => 'TextArea', :field_name => 'remarks_1'}

    field_configs[field_configs.length()] = {:field_type => 'TextArea', :field_name => 'remarks_2'}

    field_configs[field_configs.length()] = {:field_type=>'CheckBox', :field_name=>'match_on_size'}

    build_form(bin_order, field_configs, action, 'bin_order', caption, is_edit)

  end

  def build_edit_bin_order_form(bin_order, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:bin_order_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------

    if bin_order.attributes['customer_party_role_id'] != nil
      bin_order.customer_party_role_id = bin_order.attributes['customer_party_role_id']
    end
    order_types = OrderType.find(:all).map { |g| [g.order_type_code, g.id] }
    customer_party_roles = PartiesRole.find_by_sql("SELECT id ,party_name FROM parties_roles WHERE role_name = 'CUSTOMER'").map { |g| [g.party_name, g.id] }
    trading_partners =PartiesRole.find_by_sql("SELECT id, party_name,remarks FROM parties_roles WHERE role_name = 'TRADING PARTNER'").map { |g|
      if g.remarks != nil
        [g.party_name + ":" +"     " + "     " + g.remarks, g.id]
      else
        [g.party_name, g.id]
      end }
    field_configs = Array.new
    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'order_type_id',
                                             :settings=>{:list => order_types, :label_caption=>'order type code'}}

    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'bin_order_number'}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'trading_partner_party_role_id',
                                             :settings=>{:list =>trading_partners, :label_caption=>'trading partner'}}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField', :field_name => 'customer_party_role_id',
                                             :settings=>{:list =>customer_party_roles, :label_caption=>'customer party role'}}

    field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'customer_order_number'}

    field_configs[field_configs.length()]= {:field_type => 'TextArea', :field_name => 'remarks_1'}

    field_configs[field_configs.length()]= {:field_type => 'TextArea', :field_name => 'remarks_2'}

     field_configs[field_configs.length()]= {:field_type => 'LabelField', :field_name => 'status',:setings=> {:label_caption=>'order_status'}}

    field_configs[field_configs.length()] = {:field_type => 'LinkWindowField', :field_name => '',
                                             :settings => {:target_action => 'order_status_histories', :link_text => "order_status_histories", :id_value => bin_order.id}}

    field_configs[field_configs.length()] = {:field_type=>'CheckBox', :field_name=>'match_on_size'}

    order_products = BinOrderProduct.find_all_by_bin_order_id(bin_order.id)
    if !order_products.empty?
    field_configs[field_configs.length()] = {:field_type => 'LinkWindowField', :field_name => '',
                                             :settings => {
                                                     :controller =>"rmt_processing/bin_load",
                                                     :target_action => 'order_loads', :link_text => "order_loads",
                                                     :id_value => bin_order.id}}

    end
    if !(bin_order.status.upcase == 'LOADED'|| bin_order.status.upcase == 'COMPLETE')
   field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings => {
                                                       #:host_and_port =>request.host_with_port.to_s,
                                                       :controller =>"rmt_processing/bin_order",
                                                       #:target_action => 'new_line_item',
                                                       :target_action => 'add_order_product',
                                                       :link_text => "get order products",
                                                       #:width => 800
                                                       :id_value => bin_order.id } }

      end
    menu1 = ApplicationHelper::ContextMenu.new("reports", "bin_order", true)
    if bin_order.status.upcase =="COMPLETE"
       menu1.add_command("pool_payments_summary", "/rmt_processing/bin_order/pool_payments_summary")
    end
    menu1.add_command("bin_sale_tripsheet", "/rmt_processing/bin_order/bin_sale_tripsheet")
    menu1.add_command("empty_bins", "/rmt_processing/bin_order/empty_bins")



    js = "<script src = '/javascripts/context_menu.js'></script>"
    js += "<script>"
    js += menu1.render
    js +="build_context_menus();"
    js +="</script>"

    field_configb = {:link_text => "reports",
                     :link_value => bin_order.id.to_s,
                     :menu_name => "reports",
                     :css_class => "run_line_code_link_black"}
    popup_link = ApplicationHelper::PopupLink.new(nil, nil, 'none', 'none', 'none',field_configb, true, nil, self)

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name=>"",
                                             :non_db_field=>true,
                                             :settings=>{
                                                     :static_value=>js + popup_link.build_control,
                                                     :show_label=>true,
                                                     :css_class=>'unbordered_label_field'
                                             }
    }


        field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form2",
                                             :settings =>{
                                                     #:host_and_port => request.host_with_port.to_s,
                                                     :controller => 'rmt_processing/bin_order_product',
                                                     :target_action => 'list_bin_order_products',
                                                     :width => 1000,
                                                     :height => 250,
                                                     :id_value => bin_order.id,
                                                     :no_scroll => true}}
     @submit_button_align = "left"
    if !order_products.empty? && !(bin_order.status.upcase == 'LOADED'|| bin_order.status.upcase == 'COMPLETE')

      set_form_layout "1", nil, 0, 14

    else
      set_form_layout "1", nil, 0, 13
    end

     build_form(bin_order, field_configs, action, 'bin_order', caption, is_edit)

  end

   def build_order_status_histories_grid(data_set)
    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'bin_order_number'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'order_status'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'created_on'}
    return get_data_grid(data_set, column_configs)

   end

  def build_bin_order_search_form(bin_order, action, caption, is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:bin_order_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    #Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
    order_types = BinOrder.find_by_sql('select distinct order_type from bin_orders').map { |g| [g.order_type] }
    order_types.unshift("<empty>")
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'order_type',
                         :settings => {:list => order_types}}

    build_form(bin_order, field_configs, action, 'bin_order', caption, false)

  end


  def build_bin_order_grid(data_set, can_edit, can_delete,can_cancel)
    require File.dirname(__FILE__) + "/../../../app/helpers/rmt_processing/bin_order_plugin.rb"
    column_configs = Array.new
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit', :col_width=>30,
                                                 :settings =>
                                                         {:image => 'edit',
                                                          :target_action => 'edit_bin_order',
                                                          :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete', :col_width=>35,
                                                 :settings =>
                                                         {:image => 'delete',
                                                          :target_action => 'delete_bin_order',
                                                          :id_column => 'id',:id_column => 'id',:null_test => "['order_status'].to_s =='LOADED'||active_record['order_status'] == 'COMPLETE'||active_record['order_status'] == 'LOADING'"}}
    end
     if can_cancel

      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'cancel', :col_width=>36,
                                                 :settings =>
                                                         {:image => 'cancel',
                                                          :target_action => 'cancel_bin_order',
                                                          :id_column => 'id',:id_column => 'id',:null_test => "['order_status'].to_s =='LOADED'||active_record['order_status'] == 'BIN_ORDER_CREATED'||active_record['order_status'] == 'LOADING'"}}
#
    end


    column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'bin_order_number',:column_caption=>'order_num',:col_width=>70}
    column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'updated_at',:col_width=>121}
    column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'order_status',:col_width=>142}
    column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'load_status',:col_width=>108}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'order_type_code',:column_caption=>'order_type',:col_width=>68}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'customer_party_name',:column_caption=>'customer',:col_width=>80}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'customer_order_number',:column_caption=>'cust_order_num',:col_width=>105}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'trading_partner',:col_width=>203}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'user_name',:column_caption=>'user',:col_width=>84}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_on', :column_caption=>'order_date',:col_width=>118}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}
#	----------------------
#	define action columns
#	----------------------

    hide_grid_client_controls()
    set_grid_min_width(1200)
    return get_data_grid(data_set, column_configs,RmtProcessingPlugins::BinOrderGridPlugin.new, true)

  end

  def build_search_bin_order_grid(data_set, can_edit, can_delete)

     column_configs = Array.new
     if can_edit
       column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit', :col_width=>30,
                                                  :settings =>
                                                          {:link_text => 'edit',
                                                           :target_action => 'edit_bin_order',
                                                           :id_column => 'id'}}
     end

     if can_delete
       column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit', :col_width=>30,
                                                  :settings =>
                                                          {:link_text => 'delete',
                                                           :target_action => 'delete_bin_order',
                                                           :id_column => 'id'}}
     end
     column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'bin_order_number',:column_caption=>'order_num',:col_width=>70}
     column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'updated_at'}
     column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'order_status',:col_width=>142}
     column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'load_status',:col_width=>108}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'order_type_code',:column_caption=>'order_type',:col_width=>68}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'customer_party_name',:column_caption=>'customer',:col_width=>80}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'customer_order_number',:column_caption=>'cust_order_num',:col_width=>105}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'trading_partner',:col_width=>203}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'user_name',:column_caption=>'user',:col_width=>84}
     column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_on', :column_caption=>'order_date',:col_width=>118}
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}
 #	----------------------
 #	define action columns
 #	----------------------

     set_grid_min_width(1200)
     return get_data_grid(data_set, column_configs,nil, true)

   end


 end

