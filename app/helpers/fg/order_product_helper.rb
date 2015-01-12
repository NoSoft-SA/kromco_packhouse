module Fg::OrderProductHelper
  def  build_order_product_prices_grid(data_set, can_edit, can_delete)
    #require File.dirname(__FILE__) + "/../../../app/helpers/fg/order_product_plugins.rb"

      column_configs = Array.new
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'customer' }
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'price_per_kg' }
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'price_per_carton' }
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'nett_price_per_kg' }
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'fob' }
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'updated_at',:col_width=>120}
      column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'id' }

       set_grid_min_height(230)
       set_grid_min_width(900)
       hide_grid_client_controls()

        get_data_grid(data_set,column_configs,nil,true)

    end

  def build_price_histories_form(order_product, action, caption, is_edit = nil, is_create_retry = nil)
 #	--------------------------------------------------------------------------------------------------
 #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
 #	in a composite foreign key
 #	--------------------------------------------------------------------------------------------------
     session[:order_product_form]= Hash.new

     field_configs = Array.new

     field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form22",
                                             :settings =>{
                                                     #:host_and_port => request.host_with_port.to_s,
                                                     :controller => 'fg/order_product',
                                                     :target_action => 'client_order_product_prices',
                                                     :width => 1200,
                                                     :height => 250,
                                                     :id_value => order_product.id,
                                                     :no_scroll => true
                                             }
    }
    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                                     :field_name => "child_form33",
                                                     :settings =>{
                                                             #:host_and_port => request.host_with_port.to_s,
                                                             :controller => 'fg/order_product',
                                                             :target_action => 'prices_for_all_clients',
                                                             :width => 1200,
                                                             :height => 250,
                                                             :id_value => order_product.id,
                                                             :no_scroll => true
                                                     }
            }
     @submit_button_align = "left"
     build_form(order_product, field_configs, action, 'order_product', caption, is_edit)

   end


  def build_order_product_form(order_product, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    session[:order_product_form]= Hash.new
#    uom_codes = Uom.find_by_sql('select distinct id, uom_code from uoms').map{|g|[g.uom_code, g.id]}
#    fg_product_codes = FgProduct.find_by_sql('select distinct fg_product_code from fg_products').map { |g| [g.fg_product_code] }
#    extended_fg_codes = ExtendedFg.find_by_sql('select distinct id, extended_fg_code from extended_fgs').map{|g|[g.extended_fg_code, g.id]}

    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'available_quantities'}

      load_status = @order_product.attributes['load_status']
      required_quantity = @order_product.attributes['required_quantity']
      if   load_status == "LOAD_CREATED" || required_quantity != nil
            field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                            :field_name => 'required_quantity'}
      else
            field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'required_quantity'}
       end


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'extended_fg_code'}


    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'marketing_org'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'commodity_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'marketing_variety_code'}

    field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'old_pack_code'}

    field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'brand_code'}

    field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'size_ref'}

    field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'grade_code'}

    field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'inventory_code'}

    field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'target_market_code'}

    field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'puc'}

    field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'old_fg_code'}

       field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'iso_week_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'season_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'pick_reference'}

    field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'inspection_type_code'}

#    field_configs[field_configs.length()] = {:field_type =>  'LabelField',
#                                             :field_name => 'price'}

    field_configs[field_configs.length()] = {:field_type =>  'TextField',
                                             :field_name => 'price_per_carton'}

       field_configs[field_configs.length()] = {:field_type =>  'TextField',
                                             :field_name => 'price_per_kg'}

    field_configs[field_configs.length()] = {:field_type =>  'TextField',
                                                 :field_name => 'fob'}

    build_form(order_product, field_configs, action, 'order_product', caption, is_edit)

  end


  def build_order_product_search_form(order_product, action, caption, is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:order_product_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    #Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
    order_numbers = OrderProduct.find_by_sql('select distinct order_number from order_products').map { |g| [g.order_number] }
    field_configs[0] = {:field_type => 'DropDownField',
                        :field_name => 'order_number',
                        :settings => {:list => order_numbers}}

    build_form(order_product, field_configs, action, 'order_product', caption, false)

  end


  def build_order_product_grid(data_set, can_edit, can_delete,multi_select)


    column_configs = Array.new
    require File.dirname(__FILE__) + "/../../../app/helpers/fg/order_product_plugins.rb"
    if !session[:current_viewing_order]
    if multi_select
    else
      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'edit',
                                                           :col_width=>30,
                                                          :settings =>
                                                                  {:image => 'edit',
                                                                   :target_action => 'edit_order_product',
                                                                   :id_column => 'id'}}


       column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete',:col_width=>36,
                                                  :settings =>
                                                          {:link_text => '',
                                                           :target_action => 'delete_order_product',
                                                           :id_column => 'id'}}

    end
    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'get_historic_pricing',:col_width=>150,
                                               :settings =>
                                                   {:link_text => '',
                                                    :target_action => 'get_historic_pricing',
                                                    :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'price_histories',
                                                        :col_width=>30,
                                                       :settings =>
                                                               {:link_text => '',
                                                                :target_action => 'price_histories',
                                                                :id_column => 'id'}}
    end

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'price_per_kg',:column_caption=>'price/kg',:format => 'currency_default',:col_width=>50}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'price_per_carton',:column_caption=>'price/carton',:format => 'currency_default',:col_width=>50}
    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'fob',:col_width=>50}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'old_fg_code',:col_width=>200}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'extended_fg_code',:col_width=>250}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'item_pack_product_code',:col_width=>250}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'old_pack_code',:col_width=>100}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'required_quantity',:column_caption=>'Required',:col_width=>66}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'available_quantities',:column_caption=>'Available',:col_width=>66}

    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'sequence_number',:column_caption=>'seq_num',:col_width=>49}
    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'marketing_org',:col_width=>90}
    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'commodity_code',:column_caption=>'commodity',:col_width=>40}
    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'marketing_variety_code',:column_caption=>'marketing_variety',:col_width=>97}
    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'brand_code',:column_caption=>'brand',:col_width=>100}
    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'size_ref',:col_width=>50}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'grade_code',:column_caption=>'grade',:col_width=>36}
    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inventory_code',:column_caption=>'inventory',:col_width=>105}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'target_market_code',:column_caption=>'target_market',:col_width=>215}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'puc',:col_width=>49}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pallet_format_product_code',:col_width=>79}
    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pc_code',:col_width=>160}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'iso_week_code',:column_caption=>'iso_week',:col_width=>37}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'season_code',:column_caption=>'season',:col_width=>44}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pick_reference',:column_caption=>'pick_ref',:col_width=>44}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'inspection_type_code',:column_caption=>'inspection_type',:col_width=>67}

    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location',:col_width=>95}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_count',:column_caption=>'ctn_qty',:col_width=>56}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'carton_weight',:column_caption=>'ctn_weight',:col_width=>56}

    #column_configs[column_configs.length()]= {:field_type => 'text', :field_name =>  'price', :format => 'currency_default'}
#    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'price_per_kg',:column_caption=>'price/kg',:format => 'currency_default',:col_width=>53}
#    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'price_per_carton',:column_caption=>'price/ctn',:format => 'currency_default',:col_width=>56}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'subtotal', :col_width=>115 }

    column_configs[column_configs.length()]= {:field_type => 'text', :field_name => 'id' }
    @multi_select = multi_select if multi_select
     set_grid_min_height(230)
     set_grid_min_width(900)
     hide_grid_client_controls()

      get_data_grid(data_set,column_configs,FgPlugins::OrderProductGridPlugin.new(self,request))

  end

end
