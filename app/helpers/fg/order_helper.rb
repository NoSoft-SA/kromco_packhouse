module Fg::OrderHelper

  def build_load_pallets_consignment_note_numbers_grid(consignment_note_numbers)

      column_configs = []
      column_configs << {:field_type => 'text', :field_name => 'consignment_note_number',:col_width=> 180}
      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'view',:col_width=>50,:col_width=>180,
                                                                 :settings => {
                                                                     :image => 'view_intake',
                                                                         :target_action => 'view_signed_load_consignment',
                                                                         :id_column => 'consignment_note_number'
                                                                         }}

      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'print',:col_width=>50,:col_width=>180,
                                                                 :settings => {
                                                                     :image => 'print',
                                                                         :target_action => 'print_signed_load_consignment',
                                                                         :id_column => 'consignment_note_number'
                                                                         }}

      grid_command =    {:field_type=>'link_window_field',:field_name =>'new_voyage_port',
                                :settings =>
                               {:target_action => 'loads_signed_docs_print_all',
                                :link_text => "print_all",
                                :id_value=>params[:id]}}

      return get_data_grid(consignment_note_numbers, column_configs,MesScada::GridPlugins::Fg::SignedIntakeDocsPlugin.new(self,request),nil,grid_command)   #
    end
  def build_number_loads_form(load, action, caption, is_edit=nil, is_create_retry=nil)
        field_configs = Array.new
        field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'number_of_loads'}
        build_form(load, field_configs, action, 'load', caption, is_edit)
  end

  def build_upgrade_order_form(order, action, caption, is_edit=nil, is_create_retry=nil)
      field_configs = Array.new
      combos_js_for_depots = gen_combos_clear_js_for_combos(["order_order_type_id", "order_depot_code"])

      order_type_observer = {:updated_field_id => "depot_code_cell",
                           :remote_method =>'order_type_id_changed',
                           :on_completed_js => combos_js_for_depots["order_order_type_id"]
    }
      depot_codes = Depot.find_by_sql("SELECT DISTINCT * FROM depots").map { |g|
          if g.depot_code!= nil
            [g.depot_code + ":" +"     " + "     " + g.depot_description,g.id]
          else
            [g.depot_code,g.id]
            end}
      order_type_ids = OrderType.find_by_sql("SELECT DISTINCT id, order_type_code FROM order_types where order_type_code='DP' or order_type_code='CU' order by order_type_code desc").map { |g| [g.order_type_code, g.id] }

      field_configs[field_configs.length()] = {:field_type=>'DropDownField',
                                               :field_name=>'order_type_id',
                                               :settings=>{
                                                       :list=>order_type_ids,
                                                       :label_caption => 'order type'},:observer=>order_type_observer
      }
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'depot_id', :settings=>{:list=>depot_codes,:label_caption =>'depot code'}}

    build_form(order,field_configs,action,'order', caption, is_edit)
    end



  def build_order_form(order, action, caption, is_edit=nil, is_create_retry=nil)
    field_configs = Array.new

    combos_js_for_consignee_party_role_id = gen_combos_clear_js_for_combos(["order_consignee_party_role_id", "order_currency_id"])
    consignee_party_role_id_observer = {:updated_field_id => "currency_id_cell",
                           :remote_method =>'trading_partner_changed',
                           :on_completed_js =>  combos_js_for_consignee_party_role_id["order_consignee_party_role_id"]
    }

    combos_js_for_depots = gen_combos_clear_js_for_combos(["order_order_type_id", "order_depot_code"])
    order_type_observer = {:updated_field_id => "depot_code_cell",
                           :remote_method =>'order_type_id_changed',
                           :on_completed_js => combos_js_for_depots["order_order_type_id"]
    }
    currencies=Currency.find(:all).map{|c|[c.currency_code,c.id]}
    incoterms=Incoterm.find(:all).map{|i|[i.incoterm_code,i.id]}
    marketers=User.find_by_sql("select id,users.user_name from users where department_name='Marketing' order by user_name desc").map{|u|[u.user_name,u.id]}

    order_type_ids = OrderType.find_by_sql("SELECT DISTINCT id, order_type_code FROM order_types").map { |g| [g.order_type_code, g.id] }
    # -------------------------------------------------------------------------------------------------- #
    # only do query if user selects order_type 'DEPOT'
    depot_codes = Depot.find_by_sql("SELECT DISTINCT * FROM depots").map { |g|
          if g.depot_code!= nil
            [g.depot_description + ":" +"  " + "" + g.depot_code,g.id]
          else
            [g.depot_code,g.id]
          end}
    depot_codes.unshift("<empty>")
    # -------------------------------------------------------------------------------------------------- #
    line_of_business_codes = TrackSlmsIndicator.find_by_sql("SELECT track_slms_indicator_code FROM track_slms_indicators WHERE track_indicator_type_code = 'LOB'").map { |g| [g.track_slms_indicator_code] }
    trading_partners = PartiesRole.find_by_sql("SELECT parties_roles.id, parties_roles.party_name,trading_partners.remarks
                       FROM parties_roles
                       inner join trading_partners on trading_partners.parties_role_id=parties_roles.id
                       WHERE parties_roles.role_name = 'TRADING PARTNER' and trading_partners.active IS TRUE order by trading_partners.remarks,parties_roles.party_name ")

      trading_partners= trading_partners.map { |g|if g.remarks != nil
        [g.remarks + ":" + "" + "" +  g.party_name , g.id]
      else
        [g.party_name, g.id]
      end }
    trading_partners.unshift("<empty>")
    customer_party_role_ids = PartiesRole.find_by_sql("SELECT * FROM parties_roles WHERE role_name = 'CUSTOMER'").map { |g|
      if g.remarks != nil
              [g.party_name + ":" +"     " + "     " + g.remarks, g.id]
            else
              [g.party_name, g.id]
            end }
    credit_ratings = CreditRating.find(:all).map { |g| [g.credit_description] }
    field_configs[field_configs.length()] = {:field_type=>'DropDownField',
                                             :field_name=>'order_type_id?required',
                                             :settings=>{
                                                     :list=>order_type_ids,
                                                     :label_caption => 'order type'},
                                             :observer => order_type_observer
    }
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'depot_id?required', :settings=>{:list=>depot_codes,:label_caption =>'depot code'}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'line_of_business_code', :settings=>{:list=>line_of_business_codes}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'consignee_party_role_id?required', :settings=>{:list=>trading_partners,
                                             :label_caption => 'trading partner'},:observer=>consignee_party_role_id_observer}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'currency_id', :settings=>{:list=>currencies,:label_caption => 'currency'}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'incoterm_id', :settings=>{:list=>incoterms,:label_caption => 'incoterm'}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'marketer_user_id', :settings=>{:list=>marketers,:label_caption => 'marketer'}}

    field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'order_date'}
    field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'loading_date'}

    field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'promised_delivery_date'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'order_description'}
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => '',
                                             :settings => {
                                                     :is_seperator => false,
                                                     :static_value => "Customer Details"
                                             }
    }
    # ------------------------ #
    # Customer Details Section #
    # ------------------------ #
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_order_number'}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'customer_party_role_id?required', :settings=>{:list=>customer_party_role_ids, :label_caption => 'organization code'}}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_contact_name'}
    field_configs[field_configs.length()] = {:field_type=>'TextArea', :field_name=>'customer_memo_pad'}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'customer_credit_rating',
                                             :settings=>{
                                                     :list=>credit_ratings
                                             }
    }
    field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'customer_credit_rating_timestamp'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'discount_percentage'}
    field_configs[field_configs.length()] = {:field_type=>'CheckBox', :field_name=>'is_export'}

    build_form(order,field_configs,action,'order', caption, is_edit)
  end


  def build_edit_order_form(order, action, caption, is_edit=nil, is_create_retry=nil,is_view=nil)

    if order.attributes['customer_credit_rating_timestamp'] != nil
      order.customer_credit_rating_timestamp = order.attributes['customer_credit_rating_timestamp'].to_datetime
    end
    if order.attributes['customer_party_role_id'] != nil
      order.customer_party_role_id = order.attributes['customer_party_role_id']
     end

    field_configs = Array.new
    order_type_code=OrderType.find(order.order_type_id).order_type_code
    if order_type_code.strip=="MO" ||  order_type_code.strip=="MQ"
      order_type_ids = OrderType.find_by_sql("SELECT DISTINCT id, order_type_code FROM order_types where order_type_code in ('MO','MQ') ").map { |g| [g.order_type_code, g.id] }
    else
      order_type_ids = OrderType.find_by_sql("SELECT DISTINCT id, order_type_code FROM order_types where order_type_code not in ('MO','MQ')").map { |g| [g.order_type_code, g.id] }
    end
    combos_js_for_depots = gen_combos_clear_js_for_combos(["order_order_type_id", "order_depot_code"])
    order_type_observer = {:updated_field_id => "depot_code_cell",
                           :remote_method =>'order_type_id_changed',
                           :on_completed_js => combos_js_for_depots["order_order_type_id"]
    }
    combos_js_for_consignee_party_role_id = gen_combos_clear_js_for_combos(["order_consignee_party_role_id", "order_currency_id"])
        consignee_party_role_id_observer = {:updated_field_id => "currency_id_cell",
                               :remote_method =>'trading_partner_changed',
                               :on_completed_js =>  combos_js_for_consignee_party_role_id["order_consignee_party_role_id"]
        }
        currencies=Currency.find(:all).map{|c|[c.currency_code,c.id]}
        incoterms=Incoterm.find(:all).map{|i|[i.incoterm_code,i.id]}
    marketers=User.find_by_sql("select id,users.user_name from users where department_name='Marketing' order by user_name desc").map{|u|[u.user_name,u.id]}


    depot_codes = Depot.find_by_sql("SELECT DISTINCT * FROM depots").map { |g|
          if g.depot_code!= nil
            [g.depot_description + ":" +"  " + "" + g.depot_code,g.id]
          else
            [g.depot_code,g.id]
          end}
    depot_codes.unshift("<empty>")
    # -------------------------------------------------------------------------------------------------- #
    line_of_business_codes = TrackSlmsIndicator.find_by_sql("SELECT track_slms_indicator_code FROM track_slms_indicators WHERE track_indicator_type_code = 'LOB'").map { |g| [g.track_slms_indicator_code] }
    trading_partners = PartiesRole.find_by_sql("
                       SELECT parties_roles.id, parties_roles.party_name,trading_partners.remarks
                      FROM parties_roles
                      inner join trading_partners on trading_partners.parties_role_id=parties_roles.id
                      WHERE parties_roles.role_name = 'TRADING PARTNER'  and trading_partners.active IS TRUE ").map { |g|
      if g.remarks != nil
        [g.remarks + ":" +"  " + " " +g.party_name , g.id]
      else
        [g.party_name, g.id]
      end }
    trading_partners.unshift("<empty>")
    customer_party_role_ids = PartiesRole.find_by_sql("SELECT * FROM parties_roles WHERE role_name = 'CUSTOMER'").map { |g|

      if g.remarks != nil
                    [g.party_name + ":" +" " + "" + g.remarks, g.id]
                  else
                    [g.party_name, g.id]
                  end }
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                 :field_name => 'order_number',
                                                 :settings => {
                                                         :show_label => true,
                                                         :is_separator => false,
                                                         :static_value => order.order_number
                                                 }
        }


    if order.not_all_pallets_is_stock==true
  field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                   :field_name => 'not_all_pallets_is_stock',
                                                   :settings => {
                                                           :show_label => true,
                                                           :is_separator => false,
                                                           :css_class => "red_label_field"
                                                   }
          }
else
  field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                   :field_name => 'not_all_pallets_is_stock',
                                                   :settings => {
                                                           :show_label => true,
                                                           :is_separator => false

                                                   }
          }
end

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                 :field_name => 'orig_tm',
                                                 :settings => {
                                                         :show_label => true,
                                                         :is_separator => false

                                                 }
        }


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'order_status',
                                             :settings => {
                                                     :show_label => true,
                                                     :is_separator => false,
                                                     :static_value => order.order_status
                                             }
    }
    field_configs[field_configs.length()] = {:field_type=>'DropDownField',
                                             :field_name=>'order_type_id?required',
                                             :settings=>{
                                                     :list=>order_type_ids,
                                                      :label_caption => 'order type'
                                                  },
                                             :observer => order_type_observer
    }
    if is_view
      order_type_code=OrderType.find(order.order_type_id).order_type_code
      if order.currency_id
        currency=Currency.find(order.currency_id).currency_code
      else
        currency=""
      end
      if order.incoterm_id
        incoterm=Incoterm.find(order.incoterm_id).incoterm_code
      else
        incoterms=""
      end
      if order.marketer_user_id
        marketer=User.find(order.marketer_user_id).user_name
      else
        marketer=""
      end
      if order.depot_id
        depot_description=""
        depot = Depot.find(order.depot_id)
        depot_description =depot.depot_description
        depot_code=depot_description + depot.depot_code
      else
        depot_code=""
      end
      if order.line_of_business_code
      line_of_business_code = order.line_of_business_code
      else
        line_of_business_code = ""
      end
      trading_partner=PartiesRole.find_by_sql("
                      SELECT parties_roles.id, parties_roles.party_name,trading_partners.remarks
                      FROM parties_roles
                      inner join trading_partners on trading_partners.parties_role_id=parties_roles.id
                      WHERE parties_roles.id = #{order.consignee_party_role_id}")
      if trading_partner[0].remarks
        trading_partner = trading_partner[0].remarks + ":" + trading_partner[0].party_name
      else
        trading_partner = trading_partner[0].party_name
      end
      customer =PartiesRole.find(order.customer_party_role_id)
      if customer.remarks
        customer =customer.party_name + ":" + customer.remarks
      else
        customer=customer.party_name
      end

      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'depot_id?required', :settings=>{:label_caption =>'depot_code', :static_value =>depot_code, :show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'consignee_party_role_id?required', :settings=>{:static_value =>trading_partner, :show_label=>true, :label_caption => 'trading partner'}}

      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'line_of_business_code', :settings=>{:static_value =>line_of_business_code, :show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'currency_id', :settings=>{:static_value =>currency, :show_label=>true,:label_caption => 'currency'}}
      field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'loading_date'}

      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'incoterm_id', :settings=>{:static_value =>incoterm, :show_label=>true,:label_caption => 'incoterm'}}
      field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'order_date'}

      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'marketer_user_id', :settings=>{:static_value =>marketer, :show_label=>true,:label_caption => 'marketer'}}
      field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'promised_delivery_date'}
      field_configs[field_configs.length()] = {:field_type=>'TextArea', :field_name=>'order_description',:settings=>{:static_value =>order['customer_contact_name'],:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector',:field_name=>'customer_credit_rating_timestamp',:settings => {:caption => 'credit rating timestamp'}}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_order_number',:settings=>{:static_value =>order['customer_order_number'],:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'customer_party_role_id?required', :settings=>{:static_value =>customer, :show_label=>true, :label_caption => 'organization code'}}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_contact_name',:settings=>{:static_value =>order['customer_contact_name'],:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_memo_pad',:settings=>{:static_value =>order['customer_memo_pad'],:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_credit_rating',:settings=>{:static_value =>order['customer_credit_rating'],:show_label=>true}}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'discount_percentage',:settings=>{:static_value =>order['discount_percentage'],:show_label=>true}}

    else
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'depot_id?required', :settings=>{:list=>depot_codes,:label_caption =>'depot code'}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'consignee_party_role_id?required', :settings=>{:list=>trading_partners,:is_clearable => true, :label_caption => 'trading partner'},:observer=> consignee_party_role_id_observer}

      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'line_of_business_code', :settings=>{:list=>line_of_business_codes}}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'currency_id', :settings=>{:list=>currencies,:label_caption => 'currency'}}
      field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'loading_date'}

      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'incoterm_id', :settings=>{:list=>incoterms,:label_caption => 'incoterm'}}
      field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'order_date'}

      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'marketer_user_id', :settings=>{:list=>marketers,:label_caption => 'marketer'}}
      field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'promised_delivery_date'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'order_description'}
      field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector',:field_name=>'customer_credit_rating_timestamp',:settings => {:caption => 'credit rating timestamp'}}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_order_number'}
      field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'customer_party_role_id?required', :settings=>{:list=>customer_party_role_ids, :label_caption => 'organization code'}}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_contact_name'}
      field_configs[field_configs.length()] = {:field_type=>'TextArea', :field_name=>'customer_memo_pad'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_credit_rating'}
      field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'discount_percentage'}

    end

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'total_order_amount',
                                             :settings => {
                                                     :show_label => true,
                                                     :is_seperator => false,
                                                     :static_value => Globals.currency(self, order.order_amount)
                                             }

    }
    #field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'no_of_containers'}


    field_configs[field_configs.length()] = {:field_type=>'CheckBox', :field_name=>'is_export'}


    session[:order_number] = order.order_number
    qry = LoadOrder.find_by_sql("SELECT count(*) FROM load_orders WHERE order_id = '#{order.id }'")
    load_orders = qry[0].attributes['count'].to_i





    order_products=OrderProduct.find_by_order_id(order.id)
    if !is_view
    field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                                     :field_name => '',
                                                     :settings => {
                                                             :target_action => 'notify_price',
                                                             :link_text => "notify_price",
                                                             :id_value => order.id
                                                     }

            }
    field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                                   :field_name => '',
                                                   :settings => {
                                                           #:host_and_port =>request.host_with_port.to_s,
                                                           :controller =>"fg/order",
                                                           #:target_action => 'new_line_item',
                                                           :target_action => 'add_order_product',
                                                           :link_text => "add_order_product",
                                                           #:width => 800
                                                           :id_value => order.id
                                                   }
          }

    field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                             :field_name => '',
                                             :settings => {
                                                     :target_action => 'order_status_histories',
                                                     :link_text => "order_status_histories",
                                                     :id_value => order.id
                                             }

    }
    party_name=PartiesRole.find(order.customer_party_role_id).party_name
    order_tm_pallets =Pallet.find_by_sql("select pallets.*
                                       from pallets
                                       inner join load_details on pallets.load_detail_id=load_details.id
                                       inner join load_orders on load_details.load_order_id=load_orders.id
                                       inner join  orders on load_orders.order_id=orders.id
                                       where orders.id=#{order.id} and pallets.orig_target_market_code is null")
    order_pallets =Pallet.find_by_sql("select pallets.*
                                       from pallets
                                       inner join load_details on pallets.load_detail_id=load_details.id
                                       inner join load_orders on load_details.load_order_id=load_orders.id
                                       inner join  orders on load_orders.order_id=orders.id
                                       where orders.id=#{order.id}")
if (party_name=="KR" || party_name=="KM") && ((order.changed_tm==false || order.changed_tm==nil) && !order_tm_pallets.empty?) ||  (@order.changed_tm==true && !order_tm_pallets.empty?)

field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                             :field_name => '',
                                             :settings => {
                                                     :target_action => 'change_tm',
                                                     :link_text => "change_tm",
                                                     :id_value => order.id
                                             }

    }
elsif (party_name=="KR" || party_name=="KM") && (order.changed_tm==true || order.changed_tm=="t") && !order_pallets.empty?
  field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                             :field_name => '',
                                             :settings => {
                                                     :target_action => 'restore_orig_tm',
                                                     :link_text => "restore_orig_tm",
                                                     :id_value => order.id
                                             }

    }
else
   field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'edi',:settings  => {:show_label => false, :is_separator => false, :static_value => "", :css_class => "borderless_label_field"}}

end

    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'b',:settings  => {:show_label => false, :is_separator => false, :static_value => "", :css_class => "borderless_label_field"}}


    field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                                   :field_name => '',
                                                   :settings => {
                                                           :target_action => 'create_one_or_more_loads_and_import_pallets',
                                                           :link_text => "load import wizard",
                                                           :id_value => order.id
                                                   }
          }

    field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                                   :field_name => '',
                                                   :settings => {
                                                           :target_action => 'create_load_and_import_pallets',
                                                           :link_text => "import many loads",
                                                           :id_value => order.id
                                                   }
          }
else
    field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'c',:settings  => {:show_label => false, :is_separator => false, :static_value => "", :css_class => "borderless_label_field"}}

end
    load_id = LoadOrder.find_by_sql("SELECT load_id FROM load_orders WHERE order_id = '#{order.id}'")
    if load_id.empty?
      load_status = nil
    else
      @load = Load.find("#{load_id[0]['load_id']}")
      load_status = @load.load_status
    end

    menu1 = ApplicationHelper::ContextMenu.new("d_docs", "order", true)

    if load_status && load_status.upcase == "SHIPPED"

      menu1.add_command("print_export_certificate", "/fg/order/print_export_certificate")
      menu1.add_command("export_certificate_addenums", "/fg/order/export_certificate_addenums")
      menu1.add_command("print_mates_receipts", "/fg/order/print_mates_receipts")
      menu1.add_command("print_tracking_device_docs", "/fg/order/print_tracking_device_docs")
    else
      menu1.add_command("order not shipped", "/fg/order/order_not_shipped")
    end

    menu2 = ApplicationHelper::ContextMenu.new("reports_and_edis", "order", true)

    if load_status
      if load_status.upcase == "SHIPPED"
        menu2.add_command("print_delivery_detail", "/fg/order/delivery_detail")
        menu2.add_command("print_delivery_summary", "/fg/order/delivery_summary")
        menu2.add_command("return_delivery", "/fg/order/return_delivery")
        menu2.add_command("send_edi", "/fg/order/send_edi")
        menu2.add_command("resend_po", "/fg/order/resend_po")
        menu2.add_command("resend_hwe_sales", "/fg/order/resend_hwe_sales")
        party_name = PartiesRole.find_by_sql("select party_name from parties_roles where id = #{order.customer_party_role_id}")[0]['party_name']
        if party_name == "TI"
          menu2.add_command("resend_po_to_marketing_org", "/fg/order/resend_po_to_marketing")
          menu2.add_command("resend_pf", "/fg/order/resend_pf")
        end
      elsif load_status.upcase == "TRUCK_LOADED" || load_status.upcase == "RETURNED"
        menu2.add_command("ship_delivery", "/fg/order/ship_delivery")
      else
        menu2.add_command("not shipped or loaded", "/fg/order/order_not_shipped")
      end
    else
      menu2.add_command("not shipped or loaded", "/fg/order/order_not_shipped")
    end


    js = "<script src = '/javascripts/context_menu.js'></script>"
    js += "<script>"
    js += menu1.render
    js +="build_context_menus();"
    js +="</script>"

    js2 = "<script src = '/javascripts/context_menu.js'></script>"
    js2 += "<script>"
    js2 += menu2.render
    js2 +="build_context_menus();"
    js2 +="</script>"


    field_configb = {:link_text => "dispatch_docs",
                     :link_value => order.id.to_s,
                     :menu_name => "d_docs",
                     :css_class => "run_line_code_link_black"}

    field_config = {:link_text => "reports_and_edis",
                    :link_value => order.id.to_s,
                    :menu_name => "reports_and_edis",
                    :css_class => "run_line_code_link_black"
    }


    popup_link = ApplicationHelper::PopupLink.new(nil, nil, 'none', 'none', 'none', field_configb, true, nil, self)
    popup_linkk = ApplicationHelper::PopupLink.new(nil, nil, 'none', 'none', 'none', field_config, true, nil, self)

    session[:multi_select]=nil
    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form2",
                                             :settings =>{
                                                     #:host_and_port => request.host_with_port.to_s,
                                                     :controller => 'fg/order_product',
                                                     :target_action => 'list_order_products',
                                                     :width => 1200,
                                                     :height => 250,
                                                     :id_value => order.id,
                                                     :no_scroll => true
                                             }
    }
    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                                     :field_name => "child_form3",
                                                     :settings =>{
                                                             #:host_and_port => request.host_with_port.to_s,
                                                             :controller => 'fg/load',
                                                             :target_action => 'list_loads',
                                                             :width => 1200,
                                                             :height => 250,
                                                             :id_value => order.id,
                                                             :no_scroll => true
                                                     }
            }

    @submit_button_align = "left"
    if is_view
      set_form_layout "2", nil, 0, 26
    else
    if (party_name=="KR" || party_name=="KM") && (order.changed_tm==false || order.changed_tm==nil) && !order_pallets.empty?
      set_form_layout "2", nil, 0, 32
    elsif (party_name=="KR" || party_name=="KM") && (order.changed_tm==true || order.changed_tm=="t") && !order_pallets.empty?
      set_form_layout "2", nil, 0, 32
    else
      set_form_layout "2", nil, 0, 32
    end
    end

    if is_view
      field_configs=build_view_mode_form(field_configs)
      build_form(order, field_configs, nil, 'order', caption, is_edit)
    else
      build_form(order, field_configs, action, 'order', caption, is_edit)
    end

  end

  def build_import_pallets_form(order, action, caption, is_edit=nil, is_create_retry=nil)
    field_configs = Array.new
    field_configs[field_configs.length()] = {:field_type=>'TextArea', :field_name=>'pallet_number',
                                             :settings =>{
                                                     :cols=> 25,
                                                     :rows=> 20}}

    build_form(order, field_configs, action, 'order', caption, is_edit)
  end


  def build_search_order_grid(data_set, can_edit, can_delete)
    column_configs = Array.new
    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit order',
                                                 :settings =>
                                                         {:link_text => 'edit',
                                                          :target_action => 'edit_order',
                                                          :id_column => 'id'}}
    end
    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete order',
                                                 :settings =>
                                                         {:link_text => 'delete',
                                                          :target_action => 'delete_order',
                                                          :id_column => 'id'}}
    end

    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'order_number'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'booking_reference'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'order_status'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'depot_code'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'order_date'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'promised_delivery_date'}
    # ------------------------ #
    # Customer Details Section #
    # ------------------------ #

    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'customer_contact_name'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'customer_order_number'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'party_name', :column_caption=>'trading_partner'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'role_name', :column_caption=>' party name'}

    return get_data_grid(data_set, column_configs, MesScada::GridPlugins::Fg::SearchOrderGridPlugin.new, true)
  end


  def build_order_grid(data_set, can_edit, can_delete)
    column_configs = Array.new
    if can_edit
          column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit ',
                                                    :col_width=>30,
                                                     :settings =>
                                                             {:image => 'edit',
                                                              :target_action => 'edit_order',
                                                              :id_column => 'id'
                                                              }}
        end
    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'view ',
                                                    :col_width=>30,
                                                     :settings =>
                                                             {:link_text => 'view',
                                                              :target_action => 'view_order',
                                                              :id_column => 'id'
                                                              }}

    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'order_number',:column_caption=>'order_num',:col_width=>90}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'order_type_code',:col_width=>120}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'customer_contact_name',:column_caption=>'customer',:col_width=>212}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'customer_order_number',:column_caption=>'cust_order_num',:col_width=>120}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'consignee_party_name', :column_caption=>'trading_partner',:col_width=>120}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'created_by',:column_caption=>'username'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'booking_reference',:column_caption=>'booking_ref',:col_width=>110}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'depot_code',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'customer_party_name', :column_caption=>'party name',:col_width=>79}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'updated_at',:col_width=>124}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'order_status',:col_width=>103}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'load_status',:col_width=>109}
    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'test_upgrade',:col_width=>100,
                                               :settings =>
                                                   {:link_text => '',
                                                    :target_action => 'test_upgrade',
                                                    :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'upgrade_order',
                                                :col_width=>100,
                                                 :settings =>
                                                         {
                                                          :target_action => 'upgrade_order',
                                                          :id_column => 'id'}}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'order_date',:col_width=>125}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'loading_date'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'promised_delivery_date',:column_caption=>'delivery_date',:col_width=>122}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'marketer'}

#    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete ',
                                                :col_width=>36,
                                                 :settings =>
                                                         {:image => 'delete',
                                                          :target_action => 'delete_order',
                                                          :id_column => 'id'}}
#    end





    # ------------------------ #
    # Customer Details Section #
    # ------------------------ #



    set_grid_min_width(1200)
    return get_data_grid(data_set, column_configs,  MesScada::GridPlugins::Fg::OrderGridPlugin.new(self, request), true)

  end



  def build_order_status_histories_grid(data_set)
    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'order_number',:column_caption=>'order_num'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'order_status'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'date_created'}
    return get_data_grid(data_set, column_configs)
  end

  def build_item_pack_product_grid(data_set, can_edit, can_delete)
    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'item_pack_product_code'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'carton_count'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'carton_weight'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'price_per_kg'}
    return get_data_grid(data_set, column_configs)
  end


  def build_order_search_form(order, action, caption, is_flat_search=nil)
    session[:orders_search_form]= Hash.new
    field_configs = Array.new
    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'location_code',
                                             :settings => {
                                                     :list => location_codes
                                             },
                                             :observer => location_code_observer
    }

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'party_name',
                                             :settings => {:list => party_names},
                                             :observer => party_name_observer}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'order_code',
                                             :settings => {:list => order_codes}}

    build_form(order, field_configs, action, 'order', caption, false)

  end

  def build_new_line_item_grid(data_set, can_edit, can_delete)

    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'order_number'}

    if can_edit
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit order',
                                                 :settings =>
                                                         {:link_text => 'edit',
                                                          :target_action => 'edit_order',
                                                          :id_column => 'id'}}
    end

    if can_delete
      column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete order',
                                                 :settings =>
                                                         {:link_text => 'delete',
                                                          :target_action => 'delete_order',
                                                          :id_column => 'id'}}
    end

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}

    @multi_select = "selected_line_items"

    return get_data_grid(data_set, column_configs, nil, true)
  end


  def build_new_line_item_form(line_items, action, caption, is_flat_search=nil)

    session[:orders_search_form]= Hash.new


    depot_codes = Depot.find_by_sql("SELECT DISTINCT depot_code FROM depots").map { |g| [g.depot_code] }

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'location_code',
                                             :settings => {
                                                     :list => location_codes
                                             },
                                             :observer => location_code_observer
    }

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'party_name',
                                             :settings => {:list => party_names},
                                             :observer => party_name_observer}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'order_code',
                                             :settings => {:list => order_codes}}

    build_form(order, field_configs, action, 'order', caption, false)

  end


  def build_select_fg_form(order, action, caption, is_flat_search=nil)
    a =  dm_session[:search_engine_query_definition]
    #extended_fg_codes = ExtendedFg.find_by_sql(dm_session[:search_engine_query_definition]).map { |g| [g.extended_fg_code] }
    item_pack_products_codes= ExtendedFg.connection.select_all(dm_session[:search_engine_query_definition])
    #.map{ |g|g['carton_count']+ ": " +g['item_pack_product_code'] }


    field_configs = Array.new
    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'item_pack_product_code',
                                             :settings => {
                                                     :list => item_pack_products_codes
                                             }
    }

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'required_quantity'
    }


    render :inline => %{ <SCRIPT>history.back()</SCRIPT> }, :layout => 'content'


    build_form(order, field_configs, 'selected_line_item', 'order', caption, true)
  end


  def build_order_from_edi_form(order, action, caption, is_edit=nil, is_create_retry=nil)

    combos_js_for_depots = gen_combos_clear_js_for_combos(["order_order_type_id", "order_depot_code"])
    order_type_observer = {
            :updated_field_id => "depot_code_cell",
            :remote_method =>'order_type_id_changed',
            :on_completed_js => combos_js_for_depots["order_order_type_id"]
    }

    field_configs = Array.new

    order_type_ids = OrderType.find_by_sql("SELECT DISTINCT id, order_type_code FROM order_types").map { |g| [g.order_type_code, g.id] }
    # -------------------------------------------------------------------------------------------------- #
    # only do query if user selects order_type 'DEPOT'
    depot_codes = Depot.find_by_sql("SELECT DISTINCT depot_code FROM depots").map { |g| [g.depot_code] }
    # -------------------------------------------------------------------------------------------------- #
    line_of_business_codes = TrackSlmsIndicator.find_by_sql("SELECT track_slms_indicator_code FROM track_slms_indicators WHERE track_indicator_type_code = 'LOB'").map { |g| [g.track_slms_indicator_code] }
    trading_partners = PartiesRole.find_by_sql("SELECT id, party_name FROM parties_roles WHERE role_name = 'TRADING PARTNER'").map { |g| [g.party_name, g.id] }
    customer_party_role_ids = PartiesRole.find_by_sql("SELECT party_name, id FROM parties_roles WHERE role_name = 'CUSTOMER'").map { |g| [g.party_name, g.id] }


    field_configs[field_configs.length()] = {:field_type=>'DropDownField',
                                             :field_name=>'order_type_id',
                                             :settings=>{
                                                     :list=>order_type_ids,
                                                     },
                                             :observer => order_type_observer
    }
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'depot_code', :settings=>{:list=>depot_codes}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'line_of_business_code', :settings=>{:list=>line_of_business_codes}}
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'consignee_party_role_id', :settings=>{:list=>trading_partners, :label_caption => 'TRADING_PARTNER'}}
    field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'order_date'}
    field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'promised_delivery_date'}
    field_configs[field_configs.length()] = {:field_type=>'TextArea', :field_name=>'order_description'}
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => '',
                                             :settings => {
                                                     :is_seperator => false,
                                                     :static_value => "Customer Details"
                                             }
    }
    # ------------------------ #
    # Customer Details Section #
    # ------------------------ #
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'customer_party_role_id', :settings=>{:list=>customer_party_role_ids}}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_order_number'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_contact_name'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_order_number'}
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'customer_credit_rating'}
    field_configs[field_configs.length()] = {:field_type=>'TextField',
                                             :field_name=>'customer_credit_rating_timestamp',
                                             :settings => {
                                                     :caption => 'credit rating timestamp'
                                             }
    }
    field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'discount_percentage'}
    field_configs[field_configs.length()] = {:field_type=>'CheckBox', :field_name=>'is_export'}

    build_form(order, field_configs, action, 'order', caption, is_edit)

  end

  def build_returns_form(order, action, caption, is_edit=nil, is_create_retry=nil)
    field_configs = Array.new
    location_codes = PartiesRole.find_by_sql("SELECT locations.location_code ,locations.id FROM locations inner join location_types on locations.location_type_code =location_types.location_type_code where location_types.location_type_code = 'COMPLEX'  ").map { |g| [g.location_code, g.id] }
    field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'location_code', :settings=>{:list=>location_codes}}

    build_form(order, field_configs, action, 'order', caption, is_edit)
  end

  def build_printer_selection_form
    printers = Printer.find(:all).map { |p| [p.friendly_name] }
    field_configs = Array.new
    @printer = Printer.new
    if session[:intake_printer]
      printer = Printer.find_by_system_name(session[:intake_printer])
      @printer.friendly_name = printer.friendly_name
    end
    field_configs[0] = {:field_type => 'DropDownField',
                        :field_name => 'friendly_name',
                        :settings => {:list => printers}}
    build_form(@printer, field_configs, 'set_printer_submit', 'printer', 'save')
  end
end



