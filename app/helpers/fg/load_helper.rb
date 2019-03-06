module Fg::LoadHelper


  def build_edit_pallets_grid(data_set)
    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'pallet_number',:col_width=>140}

    if !session[:current_viewing_order]

      column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'edit',:col_width=> 34,
                                                 :settings =>
                                                     {:link_text => 'edit',
                                                      :target_action => 'edit_pallet',
                                                      :id_column => 'id'}}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks1',:col_width=>160,  :editor => :text}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks2',:col_width=>160,  :editor => :text}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks3',:col_width=>160,  :editor => :text}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks4',:col_width=>170,  :editor => :text}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks5',:col_width=>170,  :editor => :text}
    else
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks1',:col_width=>160}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks2',:col_width=>160}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks3',:col_width=>160}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks4',:col_width=>170}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks5',:col_width=>170}
    end
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'carton_quantity_actual',:column_caption=>'actual_qty',:col_width=>100}

    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'holdover',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'holdover_quantity',:column_caption=>'holdover_qty',:col_width=>110}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'oldest_pack_date_time',:col_width=>150}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'build_status',:col_width=>110}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'commodity_code',:column_caption=>'commodity',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'marketing_variety_code',:col_width=>170}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'target_market_code',:column_caption=>'target_market',:col_width=>215}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'grade_code',:column_caption=>'grade',:col_width=>70}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'iso_week_code',:col_width=>110}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'season_code',:column_caption=>'season',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'pallet_format_product_code',:col_width=>170}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'pc_code',:col_width=>160}

    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'id'}

    return get_data_grid(data_set,column_configs,nil,true,nil,  :save_action => '/fg/load/update_edited_load_pallets')
  end

  def build_view_load_pallets_form(load)

    field_configs = Array.new
    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form8",
                                             :settings =>{
                                                 :controller => 'fg/load',
                                                 :target_action => 'view_list_load_pallets',
                                                 :width => 1200,
                                                 :height => 250,
                                                 :id_value => load.id,
                                                 :no_scroll => true
                                             }
    }
    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form9",
                                             :settings =>{
                                                 :controller => 'fg/load',
                                                 :target_action => 'edit_pallets_remarks',
                                                 :width => 1200,
                                                 :height => 250,
                                                 :id_value => load.id,
                                                 :no_scroll => true
                                             }
    }

    build_form(load, field_configs, nil, 'load', "kk", nil)

  end

  def build_load_reports_form(load, action, caption, is_edit = nil, is_create_retry = nil)
      field_configs = Array.new

      load_status = load.load_status
      load_order=LoadOrder.find_by_load_id(load.id)
      order=Order.find(load_order.order_id)
          menu1 = ApplicationHelper::ContextMenu.new("d_docs", "order", true)

         if load_status && load_status.upcase == "SHIPPED"

            menu1.add_command("print_export_certificate", "/fg/order/print_export_certificate")#dn
            menu1.add_command("export_certificate_addenums", "/fg/order/export_certificate_addenums")#dn
            menu1.add_command("print_mates_receipts", "/fg/order/print_mates_receipts")#dn
            menu1.add_command("print_tracking_device_docs", "/fg/order/print_tracking_device_docs")#dn
            menu1.add_command("signed intake docs", "/fg/order/list_signed_intake_docs")

         else
            menu1.add_command("signed intake docs", "/fg/order/list_signed_intake_docs")
            menu1.add_command("order not shipped", "/fg/order/order_not_shipped")#dn
         end

          menu2 = ApplicationHelper::ContextMenu.new("reports_and_edis", "order", true)

          if load_status
            if load_status.upcase == "SHIPPED"
              menu2.add_command("print_delivery_detail", "/fg/order/delivery_detail")#
              menu2.add_command("print_delivery_summary", "/fg/order/delivery_summary")#
              menu2.add_command("return_delivery", "/fg/order/return_delivery")#
              menu2.add_command("send_edi", "/fg/order/send_edi")#
              menu2.add_command("resend_po", "/fg/order/resend_po")#
              menu2.add_command("resend_hwe_sales", "/fg/order/resend_hwe_sales")#
              party_name = PartiesRole.find_by_sql("select party_name from parties_roles where id = #{order.customer_party_role_id}")[0]['party_name']
              if party_name == "TI"
                menu2.add_command("resend_po_to_marketing_org", "/fg/order/resend_po_to_marketing")#
                menu2.add_command("resend_pf", "/fg/order/resend_pf")#
              end
            elsif  !session[:current_viewing_order] && (load_status.upcase == "TRUCK_LOADED" || load_status.upcase == "RETURNED")
              menu2.add_command("ship_delivery", "/fg/order/ship_delivery")#
            else
              menu2.add_command("not shipped or loaded", "/fg/order/order_not_shipped")#
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
                           :link_value => load_order.id.to_s,
                           :menu_name => "d_docs",
                           :css_class => "run_line_code_link_black"}

          field_config = {:link_text => "reports_and_edis",
                          :link_value => load_order.id.to_s,
                          :menu_name => "reports_and_edis",
                          :css_class => "run_line_code_link_black"
          }


          popup_link = ApplicationHelper::PopupLink.new(nil, nil, 'none', 'none', 'none', field_configb, true, nil, self)
          popup_linkk = ApplicationHelper::PopupLink.new(nil, nil, 'none', 'none', 'none', field_config, true, nil, self)

          field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                   :field_name=>"",
                                                   :non_db_field=>true,
                                                   :settings=>{
                                                           :static_value=>js + popup_link.build_control,
                                                           :show_label=>true,
                                                           :css_class=>'unbordered_label_field'
                                                   }
          }

          field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                                   :field_name=>"",
                                                   :non_db_field=>true,
                                                   :settings=>{
                                                           :static_value=>js2 + popup_linkk.build_control,
                                                           :show_label=>true,
                                                           :css_class=>'unbordered_label_field'
                                                   }
          }


      build_form(load, field_configs, nil, 'load', caption, is_edit)

  end

  def build_edit_pallet_form(pallet, action, caption, is_edit = nil, is_create_retry = nil)

         field_configs = Array.new
         field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'pallet_number'}
         field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'remarks1',:settings=>{:label_caption=>Globals.get_column_captions['remarks1']} }
         field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'remarks2',:settings=>{:label_caption=>Globals.get_column_captions['remarks2']}}
         field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'remarks3',:settings=>{:label_caption=>Globals.get_column_captions['remarks3']}}
         field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'remarks4',:settings=>{:label_caption=>Globals.get_column_captions['remarks4']}}
         field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'remarks5',:settings=>{:label_caption=>Globals.get_column_captions['remarks5']}}

      build_form(pallet, field_configs, action, 'pallet', caption, is_edit)

    end

  def build_pallets_grid(data_set, can_edit, can_delete,multi_select)
       column_configs = Array.new

      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'pallet_number',:col_width=>140}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'carton_quantity_actual',:column_caption=>'actual_qty',:col_width=>100}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks1',:col_width=>160}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks2',:col_width=>160}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks3',:col_width=>160}


      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'holdover',:col_width=>100}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'holdover_quantity',:column_caption=>'holdover_qty',:col_width=>110}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'oldest_pack_date_time',:col_width=>150}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'build_status',:col_width=>110}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'commodity_code',:column_caption=>'commodity',:col_width=>100}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'marketing_variety_code',:col_width=>170}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'target_market_code',:column_caption=>'target_market',:col_width=>215}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'grade_code',:column_caption=>'grade',:col_width=>70}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'iso_week_code',:col_width=>110}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'season_code',:column_caption=>'season',:col_width=>100}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'pallet_format_product_code',:col_width=>170}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'pc_code',:col_width=>160}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks4',:col_width=>170}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'remarks5',:col_width=>170}
      column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'id'}
     @multi_select = "deallocated_pallets" if  @multi_select
           get_data_grid(data_set,column_configs)

     end


  def build_load_voyage_grid(data_set, can_edit, can_delete)

  #, :col_width=> 43

     column_configs = Array.new
      if can_edit

        column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'edit',:col_width=> 34,
                                                   :settings =>
                                                           {:link_text => 'edit',
                                                            :target_action => 'edit_load_voyage_from_popup',
                                                             :id_column => 'id'}}

        end

      if can_delete
        column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete',:col_width=> 48,
                                                   :settings =>
                                                           {:link_text => 'delete',
                                                            :target_action => 'delete_load_voyage',
                                                            :id_column => 'id'}}

      end

     column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'voyage_ports',:col_width=> 62,
                                                      :settings =>
                                                              {:link_text => 'voyage_ports',
                                                               :target_action => 'list_load_voyage_ports',
                                                               :id_column => 'id',
                                                               :no_scroll => true}}

      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'load_number', :column_caption=>'load_num',:col_width=> 76}
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'customer_reference', :column_caption=>'customer_ref',:col_width=> 90}
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'booking_reference', :column_caption=>'booking_ref',:col_width=> 102}
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exporter_certificate_code',:col_width=> 103}
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exporter',:col_width=> 103}
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'shipper',:col_width=> 103}
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'shipping_agent',:col_width=> 103}
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'shipping_line',:col_width=> 103}
      column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'memo_pad'}

      set_grid_min_height(200)
      set_grid_min_width(850)
       hide_grid_client_controls()
  return get_data_grid(data_set,column_configs,nil,nil,nil)
    end



   def build_edit_booking_ref_form(load_voyage, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
        field_configs = Array.new

      field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'booking_reference'}

       field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'exporter_certificate_code'}

      field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'memo_pad'}


    build_form(load_voyage, field_configs, action, 'load_voyage', caption, is_edit)

  end

  def  build_edit_vehicle_form(load_vehicle, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------

     hauliers= PartiesRole.find_by_sql("SELECT id ,party_name FROM parties_roles WHERE role_name = 'HAULIER'").map { |g| [g.party_name, g.id] }
#      if !haulier.empty?
#         load_vehicle.haulier=  haulier[0]['party_name']
#      end
      field_configs = Array.new
    if session[:current_viewing_order]
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'msg', :non_db_field=>true, :settings=>{:static_value=>"form is in view mode,changes won't be saved", :show_label=>false}}
   end
      field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'vehicle_number'}

         field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'vehicle_weight_out'}

     field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'haulier_party_id',:settings=>{:list=>hauliers,:label_caption=>'haulier'}}

    if !session[:current_viewing_order]
      build_form(load_vehicle, field_configs, action, 'load_vehicle', caption, is_edit)
    else
      build_form(load_vehicle, field_configs, nil, 'load_vehicle', caption, is_edit)
    end


  end
    def  build_edit_container_form(load_container, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
    stack_types=StackType.find(:all).map{|k|k.stack_type_code}
    stack_types.unshift("<empty>")
      field_configs = Array.new

    if session[:current_viewing_order]
       field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'msg', :non_db_field=>true, :settings=>{:static_value=>"form is in view mode,changes won't be saved", :show_label=>false}}
      end

      field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'container_code'}

    field_configs[field_configs.length()] = {:field_type =>  'TextField',
                                             :field_name => 'container_seal_code'}

     field_configs[field_configs.length()] = {:field_type =>  'TextField',
                                             :field_name => 'container_temperature_rhine'}


      field_configs[field_configs.length()] = {:field_type =>  'TextField',
                                             :field_name => 'container_temperature_rhine2'}

     field_configs[field_configs.length()] = {:field_type =>  'TextField',
                                             :field_name => 'cto_consec_code'}


    field_configs[field_configs.length()] = {:field_type =>  'DropDownField',
                                           :field_name => 'stack_type_code', :settings => {:list => stack_types}}

      field_configs[field_configs.length()] = {:field_type =>  'LabelField',
                                             :field_name => 'container_setting'}


      field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => 'container_vents'}

    if !session[:current_viewing_order]
    build_form(load_container, field_configs, action, 'load_container', caption, is_edit)
    else
      build_form(load_container, field_configs,nil, 'load_container', caption, is_edit)
      end

  end




  def build_choose_container_form(load, action, caption, is_edit = nil, is_create_retry = nil)
    field_configs = Array.new

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'container_code'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'container_description'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'container_vents'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'container_seal_code'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'container_temperature_rhine'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'container_temperature_rhine2'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => 'cto_consec_code'}
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                             :field_name => ''}


    build_form(load, field_configs, action, 'load_container', caption, true, nil, nil, true)
  end

  def build_choose_voyage_form(load, action, caption, is_edit = nil, is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:voyage_search_form]= Hash.new

    voyage_code = Voyage.find_by_sql('select distinct id,voyage_code from voyages').map { |g| [g.voyage_code, g.id] }
#      voyage_descriptions = Voyage.find_by_sql('select distinct voyage_description from voyages').map{|g|[g.voyage_description]}
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table
#	----------------------------------------------------------------------------------------------

    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'voyage_id',
                         :settings => {:list => voyage_code}}


    build_form(load, field_configs, action, 'voyage', caption, true, nil, nil, true)
#    build_form(load, field_configs, action, 'load', caption, true, nil, nil, true)
  end


  def build_loads_form(load, action, caption, is_edit=nil, is_create_retry=nil)

    session[:load_form]= Hash.new
    field_configs = Array.new
    id = params[:id].to_i

      session['order_id'] = id
    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form1",
                                             :settings =>{
                                                     #:host_and_port => request.host_with_port.to_s,
                                                     #:controller => 'fg/order_product',
                                                     :target_action => 'list_loads',
                                                     :width => 1800,
                                                     :height =>200,
                                                     :id_value => session['order_id'],
                                                     :no_scroll => true
                                             }
    }
    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form2",
                                             :settings =>{
                                                     :host_and_port => request.host_with_port.to_s,
                                                     :controller => 'fg/load_detail',
                                                     :target_action => 'list_load_details',
                                                     :width => 1800,
                                                     :height =>200,
                                                     :id_value =>session[:order_id],
                                                     :no_scroll => true
                                             }
    }


    @submit_button_align = "left"
    build_form(load, field_configs, nil, 'load', caption, is_edit)

  end


  def build_edit_load_form(load, action, caption, is_edit = nil, is_create_retry = nil)

    field_configs = Array.new

      field_configs[0] = {:field_type => 'LabelField',
                        :field_name => 'load_number',
                        :setting => {
                                :is_separator => false,
                                :show_label => true,
                                :static_value => load.load_number
                        }
                        }
     field_configs[1] = {:field_type => 'TextField',
                        :field_name => 'required_quantity'}


    build_form(load, field_configs, action, 'load', caption, is_edit)

  end


  def build_load_search_form(load, action, caption, is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    session[:load_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    #Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
    field_configs = Array.new
    load_numbers = Load.find_by_sql('select distinct load_number from loads').map { |g| [g.load_number] }
    field_configs[0] =  {:field_type => 'DropDownField',
                         :field_name => 'load_number',
                         :settings => {:list => load_numbers}}

    build_form(load, field_configs, action, 'load', caption, false)

  end


  def build_load_grid(data_set, can_edit, can_delete)

    column_configs = Array.new
    action_configs = []
    show_menu=[]
    action_menu=[]
    grid_command =    {:field_type=>'link_window_field',:field_name =>'create_loads',
                             :settings =>
                            {
                             :host_and_port =>request.host_with_port.to_s,
                             :controller =>request.path_parameters['controller'].to_s,
                             :target_action =>'create_loads',
                             :link_text => 'create_load',
                             :id_value=>'id'
                             }}

    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'load_number',:column_caption=>'load_num',:col_width=>80}



    action_menu <<  {:field_type => 'link_window',:field_name => 'edit_pallet_remarks',:column_caption=>'edit_pallet_remarks',:col_width=>60, :width => 1800,
                                              :height => 1500,:settings => {:width => 1800,
                                                                            :height => 1500,:link_icon=>'edit' ,:link_text => 'edit_pallets_remarks',:target_action => 'edit_pallets_remarks',:id_column => 'id'}}


    if !session[:current_viewing_order]
      action_menu <<  {:field_type => 'link_window', :field_name => 'delete_load',:column_caption=>'delete',:col_width=>50,
                                                           :settings => {:link_icon => 'delete',:link_text => 'delete',:target_action => 'delete_load',:id_column => 'id'}}
    end
    show_menu <<  {:field_type => 'link_window', :field_name => 'reports',:col_width=>50,
                                                       :settings => {
                                                           :link_text => 'reports',:link_icon=>'report',
                                                               :controller    =>'fg/load',
                                                               :target_action => 'reports_and_edis',
                                                               :id_column => 'id'
                                                               }}
    if !session[:current_viewing_order]
      action_menu  <<   {:field_type => 'link_window', :field_name => 'import_pallets',:col_width=>150,
                                                  :settings => {
                                                      :link_icon => 'pallets',:link_text=> 'import_pallets',
                                                          :controller    =>'fg/order',
                                                          :target_action => 'load_import_pallets',
                                                          :id_column => 'id'
                                                          }}

end
    show_menu << {:field_type => 'link_window', :field_name => 'load_details',:col_width=>72,
                                                    :settings => {
                                                        :link_text => 'load_details',:link_icon=>'pause',
                                                            :controller => 'fg/load_detail',
                                                            :target_action => 'list_load_details',
                                                            :id_column => 'id'}}

    action_menu <<   {:field_type => 'link_window', :field_name => 'print_pick_list',:col_width=>92,
                                                 :settings => {
                                                     :link_text => 'print_pick_list',:link_icon=>'printer',
                                                         :target_action => 'print_pick_list',
                                                         :id_column => 'id'}}

    action_menu <<   {:field_type => 'link_window', :field_name => 'edit_container',:col_width=>90,
                                               :settings => {
                                                   :link_text => 'edit_container', :link_icon=> 'containers',
                                                       :target_action => 'edit_container',
                                                       :order_number_column => 'order_number',
                                                       :id_column => 'id'
                                                       }}

    action_menu <<  {:field_type => 'link_window', :field_name => 'edit_vehicle',:col_width=>79,
                                               :settings => {
                                                   :link_text => 'edit_vehicle',:link_icon => 'edit',
                                                       :target_action => 'edit_vehicle',
                                                       :order_number_column => 'order_number',
                                                       :id_column => 'id'
                                                       }}

    action_menu <<  {:field_type => 'link_window', :field_name => 'link_edit_voyage',:col_width=>150,
                                                         :settings => {
                                                             :link_text => 'link_edit_voyage',:link_icon=>'ship',
                                                                 :target_action => 'voyage',
                                                                 :id_column => 'id'
                                                                 }}

    action_configs << {:field_type => 'sub_menu', :field_name => 'sub_menu', :column_caption => 'Show', :settings => {:actions => show_menu}}
    action_configs << {:field_type => 'sub_menu', :field_name => 'sub_menu', :column_caption => 'Action', :settings => {:actions => action_menu}}
    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name =>'load_status',:column_caption=>'status',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'pallets',:column_caption=>'pallets',:col_width=>60, :width => 1200,
                                               :height => 1500,:settings => {:link_icon=>'pallets' ,:link_text => '',:target_action => '',:id_column => 'id'}}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'voyage_code',:col_width=> 150}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'customer_reference', :column_caption=>'customer_ref',:col_width=> 100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'booking_reference', :column_caption=>'booking_ref',:col_width=> 135}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exporter_certificate_code',:col_width=> 160}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exporter',:col_width=> 103}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'shipper',:col_width=> 103}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'shipping_agent',:col_width=> 103}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'shipping_line',:col_width=> 103}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pol',:col_width=> 80}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pod',:col_width=> 80}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'memo_pad'}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pick_list_number',:col_width=> 100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id',:col_width=> 80}


    set_grid_min_height(150)
    set_grid_min_width(900)
    hide_grid_client_controls()
    if !session[:current_viewing_order]
    return get_data_grid(data_set, column_configs,MesScada::GridPlugins::Fg::LoadGridPlugin.new(self,request),true,grid_command)
    else
      return get_data_grid(data_set, column_configs,MesScada::GridPlugins::Fg::LoadGridPlugin.new(self,request),true)
    end
  end



  def build_load_status_histories_grid(data_set)

    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'load_number'}
    column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'status_code',:column_caption=>'load_status'}
     column_configs[column_configs.length()] = {:field_type=>'text', :field_name=>'created_on'}
       return get_data_grid(data_set, column_configs)

  end

  def build_load_voyage_form(load_voyage, action, caption, is_edit = nil, is_create_retry = nil)
  #	--------------------------------------------------------------------------------------------------
  #	Define a set of observers for each composite foreign key- in effect an observer per combo involved
  #	in a composite foreign key
  #	----------------------------------------------------------------_----------------------------------
      session[:load_voyage_form]= Hash.new




  #   trading_partners = PartiesRole.find_by_sql("SELECT id, party_name FROM parties_roles WHERE role_name = 'TRADING_PARTNER'").map { |g| [g.party_name, g.id] }
      exporter_party_role_ids = PartiesRole.find_by_sql("SELECT DISTINCT id,party_name FROM public.parties_roles WHERE parties_roles.role_name = 'EXPORTER'").map { |g| [g.party_name, g.id] }


      shipper_party_role_ids = PartiesRole.find_by_sql("SELECT DISTINCT id,party_name FROM public.parties_roles WHERE parties_roles.role_name = 'SHIPPER'").map { |g| [g.party_name, g.id] }


      shipping_agent_party_role_ids = PartiesRole.find_by_sql("SELECT DISTINCT id,party_name FROM public.parties_roles WHERE parties_roles.role_name = 'SHIPPING AGENT'").map { |g| [g.party_name, g.id] }


      shipping_line_party_role_ids = PartiesRole.find_by_sql("SELECT DISTINCT id,party_name FROM public.parties_roles WHERE parties_roles.role_name = 'SHIPPING LINE'").map { |g| [g.party_name, g.id] }

      voyage_ports                          = Port.find_by_sql("SELECT DISTINCT ports.port_code  ,voyage_ports.id FROM ports inner join voyage_ports on voyage_ports.port_id=ports.id").map { |g| [g.port_code, g.id] }
if is_create_retry
  pols    = Port.find_by_sql("select distinct ports.port_code,ports.id as pol_voyage_port_id
                from voyage_ports
                inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
                inner join ports on voyage_ports.port_id=ports.id
                inner join voyages on voyage_ports.voyage_id=voyages.id
                where (voyage_ports.voyage_id=#{load_voyage.voyage_id} and  voyage_port_types.voyage_port_type_code='Departure' and (voyages.status ='active' or voyages.status IS NULL))").map { |g| [g.port_code, g.pol_voyage_port_id] }
  pods    = Port.find_by_sql("select distinct ports.port_code,ports.id as pod_voyage_port_id
                from voyage_ports
                inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
                inner join ports on voyage_ports.port_id=ports.id
                inner join voyages on voyage_ports.voyage_id=voyages.id
                where (voyage_ports.voyage_id=#{load_voyage.voyage_id} and voyage_port_types.voyage_port_type_code='Arrival' and (voyages.status ='active' or voyages.status IS NULL))").map { |g| [g.port_code, g.pod_voyage_port_id] }
else

      pols    = Port.find_by_sql("select distinct ports.port_code,ports.id as pol_voyage_port_id
              from voyage_ports
              inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
              inner join ports on voyage_ports.port_id=ports.id
              inner join voyages on voyage_ports.voyage_id=voyages.id
              where ( voyage_port_types.voyage_port_type_code='Departure' and (voyages.status ='active' or voyages.status IS NULL))").map { |g| [g.port_code, g.pol_voyage_port_id] }
      pods    = Port.find_by_sql("select distinct ports.port_code,ports.id as pod_voyage_port_id
              from voyage_ports
              inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
              inner join ports on voyage_ports.port_id=ports.id
              inner join voyages on voyage_ports.voyage_id=voyages.id
              where ( voyage_port_types.voyage_port_type_code='Arrival' and (voyages.status ='active' or voyages.status IS NULL))").map { |g| [g.port_code, g.pod_voyage_port_id] }

 end
  #	---------------------------------
  #	 Define fields to build form from
  #	---------------------------------
      field_configs = Array.new
  #	----------------------------------------------------------------------------------------------------
  #	Combo field to represent foreign key (load_id) on related table: loads
  #	-----------------------------------------------------------------------------------------------------

      if session[:current_viewing_order]
    field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>'msg', :non_db_field=>true, :settings=>{:static_value=>"form is in view mode,changes won't be saved", :show_label=>false}}
   end

        field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'voyage_code',
                                                   :settings  => {:lookup   =>true, :lookup_search_file=>"load_search_voyages", :select_column_name=>'voyage_code',:submit_to=>"/fg/load/lookup_pol"}}
        field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'pol_voyage_port_id', :settings=>{:list=>pols, :label_caption => 'POL'}}
        field_configs[field_configs.length()] = {:field_type=>'DropDownField', :field_name=>'pod_voyage_port_id',  :settings=>{:list=>pods, :label_caption => 'POD'}}
      #end





      field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'customer_reference'}

      field_configs[field_configs.length()] = {:field_type => 'TextField', :field_name => 'booking_reference'}

      field_configs[field_configs.length()] =  {:field_type => 'TextField', :field_name => 'exporter_certificate_code'}

      field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                                :field_name=> 'exporter_party_role_id',
                                                :settings => {:label_caption => 'exporter',:show_label=> true,
                                                              :list => exporter_party_role_ids}}

      field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                                :field_name => 'shipper_party_role_id',
                                                :settings => {:label_caption=>'shipper',:show_label=> true,
                                                        :list => shipper_party_role_ids}}

      field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                                :field_name => 'shipping_agent_party_role_id',
                                                :settings => {:label_caption=>'shipping_agent',:show_label => true,
                                                        :list => shipping_agent_party_role_ids}}

      field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                                :field_name => 'shipping_line_party_id',
                                                :settings => {:label_caption=>'shipping_line',:show_label=> true,
                                                        :list => shipping_line_party_role_ids}}

      field_configs[field_configs.length()] = {:field_type => 'TextArea', :field_name => 'memo_pad'}

      if !session[:current_viewing_order]
      build_form(load_voyage,field_configs, action,'load_voyage', caption, is_edit)
      else
      build_form(load_voyage,field_configs,nil,'load_voyage', caption, is_edit)
      end

   end

end
