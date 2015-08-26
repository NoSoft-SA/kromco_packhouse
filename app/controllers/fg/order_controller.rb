class Fg::OrderController < ApplicationController

  def program_name?
    "order"
  end

  def bypass_generic_security?
    true
  end

  def continue_with_pallet_import
    @order=Order.find(session[:active_doc]['order'])

    load=Load.find(session[:active_doc]['load'])  if  session[:active_doc] && session[:active_doc]['load']

    do_create_load_and_process_pallets if session[:create_load_and_import_pallets]

    do_create_one_or_more_loads_and_process_pallets if !session[:create_load_and_import_pallets] && !session[:load_id]

    load.import_pallets(session[:hash_of_pallet_numbers])  if session[:load_id]


    @total = @order.calculate_order_amount(@order.order_number)


      render :inline => %{<script>
                                      alert('order_product,load_detail,load and pallets added');
                                      window.opener.frames[1].location.href = '/fg/order/edit_order/<%=@order.id.to_s%>';
                                      window.close();
                              </script>}, :layout => "content"

  end

  def do_create_one_or_more_loads_and_process_pallets
    number_of_pallets=session[:hash_of_pallet_numbers].length
    if number_of_pallets < session[:number_of_loads]
      flash[:error]= "The number of pallets is less than the number of loads start again"
      redirect_to :controller => 'fg/order', :action => 'create_one_or_more_loads_and_import_pallets', :id => @order.id and return
    end
    pallets_per_load=number_of_pallets/session[:number_of_loads]
    remainder_pallets=number_of_pallets - (pallets_per_load * session[:number_of_loads])
    if remainder_pallets > 0
      number_of_loads =session[:number_of_loads].to_i + 1
    else
      number_of_loads = session[:number_of_loads].to_i
    end
    pallets_ary=[]
    for item in session[:hash_of_pallet_numbers]
      pallets_ary << item[0] +"=>" + item[1]
    end

    maxi=pallets_per_load
    number_of_loads=number_of_loads.to_i
    c=1
    pallet_index=0
    while c <= number_of_loads
      load_pallets={}
      y=1
      while  y <=maxi
        element=pallets_ary[pallet_index]
        element=element.split("=>")
        load_pallets[element[0]]=element[1]
        y=y+1
        pallet_index = pallet_index + 1
      end
      load = @order.create_loads
      load.import_pallets(load_pallets)
      c=c+1
    end
  end

  def do_create_load_and_process_pallets
    container_groups=session[:container_pallet_numbers].group(['container_number'], nil, true)
    for group in container_groups
      load_pallets={}
      for member in group
        load_pallets[member['pallet_number'].strip.to_s] = session[:hash_of_pallet_numbers][member['pallet_number'].strip].to_s
      end
      load = @order.create_loads
      load.import_pallets(load_pallets, true)
    end

  end


  def receive_pallets
    @order = session[:order]
    @order_id=@order.id
    @order.set_virtual_atrr
    @id = session[:load_id] if session[:load_id]
    load=Load.find(session[:load_id])    if session[:load_id]
    container_pallet_numbers=[]
    pallet_nums=params[:order][:pallet_number]
    if pallet_nums != ""
      if pallet_nums.index(",")
        pallet_numberz=pallet_nums.split(";")
      else
        pallet_numberz=pallet_nums.split()
      end
      pallet_numbers=[]
      pallet_num_hash={}
      for numm in pallet_numberz
        numm=numm.gsub(/'/, '')
        nums=numm.split(",")
        pallet_numbers << nums[0]
        container_pallet_numbers << {"pallet_number"=>nums[0],"container_number"=> nums[1]}   if session[:create_load_and_import_pallets]
        pallet_num_hash[nums[0].strip]=numm
      end
      msg = nil
      if msg = duplicate_pallets?(pallet_numbers)
        flash[:error]= "The following pallet occurs more than once in the list: <BR> #{msg.join("<BR>")} "
        redirect_to :controller => 'fg/order', :action => 'create_one_or_more_loads_and_import_pallets', :id => @order.id  if !session[:load_id] && !session[:create_load_and_import_pallets]
        redirect_to :controller => 'fg/order', :action => 'load_import_pallets', :id => @id  if session[:load_id]
        redirect_to :controller => 'fg/order', :action => 'create_load_and_import_pallets', :id => @id  if  session[:create_load_and_import_pallets]
        return
      end

      failed_pallets= Pallet.invalid_pallets_for_dispatch_import?(pallet_numbers, @order)
      if failed_pallets.length > 0
        flash[:error]= "The following pallets cannot be imported. Reasons are in brackets: <BR> #{failed_pallets.join("<BR>")}"
        redirect_to :controller => 'fg/order', :action => 'load_import_pallets', :id => @id and return   if session[:load_id]
        redirect_to :controller => 'fg/order', :action => 'create_one_or_more_loads_and_import_pallets', :id => @order.id  if !session[:load_id] && !session[:create_load_and_import_pallets]
        redirect_to :controller => 'fg/order', :action => 'create_load_and_import_pallets', :id => @id and return   if session[:create_load_and_import_pallets]
        return
      end
    else
      flash[:error]= "Pallet numbers required"
      redirect_to :controller => 'fg/order', :action => 'load_import_pallets', :id => @id and return
    end

    session[:pallets_imported]=pallet_numbers
    session[:container_pallet_numbers]=container_pallet_numbers
    session[:hash_of_pallet_numbers]=pallet_num_hash
    specific_target_markets_check(format_pallet_number(pallet_numbers))
  end

  def specific_target_markets_check(pallet_numbers)
    is_specific_target_markets=TargetMarket.find_by_sql("select tm.target_market_code
                                                         from target_markets tm   join pallets p on p.target_market_code=tm.target_market_code
                                                         where p.pallet_number in (#{pallet_numbers.join(',')}) and tm.is_specific = true limit 1")
    customer_order_detail=get_customer_order_detail

    if !is_specific_target_markets.empty? &&  customer_order_detail.customer_memo_pad != "SPECIAL TM - REQUIRES RE-INSPECTION"
      prompt_for_remarks
    else
      continue_with_pallet_import
    end

  end

  def prompt_for_remarks
    @msg = "Special Target Market - Must a Remark be added to the Order?"
    render :inline => %{
       <script>
         if (confirm("<%=@msg%>") == true)
            {window.location.href = "/fg/order/add_order_remarks";}
         else
           {window.location.href = "/fg/order/cancel_adding_remarks";}
      </script>
        }
  end

  def cancel_adding_remarks
    continue_with_pallet_import
  end

  def  add_order_remarks
    order_customer_detail=OrderCustomerDetail.find_by_order_id(session[:active_doc]['order'])
    if   order_customer_detail.customer_memo_pad
      customer_memo_pad = order_customer_detail.customer_memo_pad + " " +  "(SPECIAL TM, REQUIRES RE-INSPECTION)"
    else
      customer_memo_pad = "SPECIAL TM - REQUIRES RE-INSPECTION"
    end

    order_customer_detail.update_attributes(:customer_memo_pad=>customer_memo_pad)
    continue_with_pallet_import
  end

  def get_customer_order_detail
    order_customer_detail=OrderCustomerDetail.find_by_order_id(session[:active_doc]['order'])
    set_active_doc("order_customer_detail", order_customer_detail.id)
    return order_customer_detail
  end

  def format_pallet_number(pallet_numbers)
    pallet_nums=[]
    for p in pallet_numbers
      pallet_nums << "'#{p}'"
    end
    pallet_nums
  end

  def view_current_order
      @order =session[:order]
      if @order
        session[:current_viewing_order]=true
        @is_view=true
        @caption="view_order"
        render_edit_order
      else
        render :inline => %{<script> alert('no current viewing order'); </script>}, :layout => 'content'
      end
    end

  def view_order

    @order = Order.find_by_sql("select orders.*,order_customer_details.discount_percentage,
                                            order_customer_details.customer_contact_name,order_customer_details.customer_credit_rating,
                                            order_customer_details.customer_credit_rating_timestamp,
                                            order_customer_details.customer_memo_pad,order_customer_details.customer_order_number
                                            from orders JOIN order_customer_details ON orders.id=order_customer_details.order_id where orders.id=#{params[:id]}")[0]
    orig_tm=Pallet.find_by_sql("select pallets.orig_target_market_code
                         from pallets
                         inner join load_details on pallets.load_detail_id=load_details.id
                         inner join load_orders on load_details.load_order_id=load_orders.id
                         inner join  orders on load_orders.order_id=orders.id
                         where orders.id=#{@order.id}")
  if !orig_tm.empty?
    @order['orig_tm']=orig_tm[0].orig_target_market_code
  else
    @order['orig_tm']=nil
  end
    session[:current_viewing_order]=@order
    session[:order]=@order
    session['order_id'] = @order.id
    session['order_number'] = @order.order_number
    @is_view=true
    @caption="view_order"
    render_edit_order
  end

  def test_upgrade_prelim_order
    order=Order.find(params[:id])
    order_pallets =Pallet.find_by_sql("select pallets.*
                 from pallets
                 inner join load_details on pallets.load_detail_id=load_details.id
                 inner join load_orders on load_details.load_order_id=load_orders.id
                 inner join  orders on load_orders.order_id=orders.id
                 left join stock_items on stock_items.inventory_reference=pallets.pallet_number
                 where orders.id=#{order.id} ")
    if order_pallets.empty?
      flash[:notice]="order not ready for upgrade"
      mo_and_mq_orders_not_ready
    else
      pallet_numbers=order_pallets.map{|p|p.pallet_number}
          msg=Order.get_and_upgrade_prelim_orders(pallet_numbers,order_pallets,order)
          if msg
            flash[:notice]=msg
            mo_and_mq_orders_not_ready
          else
            session[:alert]="order ready for upgrade"
            mo_and_mq_orders_not_ready
          end
    end


  end

  def list_signed_intake_docs
    @consignment_note_numbers = Pallet.find_by_sql("select distinct pallets.consignment_note_number
                                    from pallets
                                    inner join load_details on pallets.load_detail_id=load_details.id
                                    inner join load_orders on load_details.load_order_id=load_orders.id
                                    inner join  loads on load_orders.load_id=loads.id
                                    where load_orders.id=#{params[:id]}
                                    GROUP BY pallets.consignment_note_number")

    render :inline => %{
            <% grid            = build_load_pallets_consignment_note_numbers_grid(@consignment_note_numbers) %>
            <% grid.caption    = 'signed load consignments' %>
            <% @header_content = grid.build_grid_data %>
            <%= grid.render_html %>
            <%= grid.render_grid %>
            }, :layout => 'content'
  end

  def view_signed_load_consignment

    @signed_intake_doc_src = "/downloads/signed_intake_docs/" + "#{params[:id]}.pdf"

    render :inline => %{
      <script>
        window.resizeTo(1200,800);
        window.location.href= "<%= @signed_intake_doc_src %>";
      </script>
    }
  end

  def notify_price
    order=Order.find(params[:id])
    order_products=OrderProduct.find_by_sql("
                   select order_products.* from order_products
                   where order_id=#{order.id} and (price_per_carton is not null and price_per_carton > 0.00 )
                  ")
    if !order_products.empty?
      send_price_notification(order)
      render :inline => %{
        <script>
           alert("price notification send");
          window.close();
        </script>
      }, :layout => 'content'
    else
      render :inline => %{
              <script>
                 alert("there are no order products with prices");
                window.close();
              </script>
            }, :layout => 'content'
    end
  end

  def send_price_notification(order)
    customer_party_name = PartiesRole.find(order.consignee_party_role_id).party_name
    customer_remarks = PartiesRole.find(order.consignee_party_role_id).remarks
    msg="order products for order : #{order.order_number} have a price.  Customer: #{customer_party_name} -  #{customer_remarks}"
    order.notify_price(msg)
  end

  def upgrade_order
    @order=Order.find(params[:id])
    session[:order] = @order
    render_upgrade_order
  end

  def render_upgrade_order

    render :inline => %{
          <% @content_header_caption = "'upgrade order'"%>

          <%= build_upgrade_order_form(@order,'complete_upgrade','upgrade',false,@is_create_retry)%>

          }, :layout => 'content'
  end

  def complete_upgrade
    order=session[:order]
    order.order_type_id=params[:order][:order_type_id]
    order.depot_id=params[:order][:depot_id]
    depot_code=Depot.find(params[:order][:depot_id].to_i).depot_code
    order.depot_code=depot_code
    order.update
    order_type_code=OrderType.find(params[:order][:order_type_id]).order_type_code
    order_status = order.set_status("ORDER_UPGRADED_TO_"+"#{order_type_code}")

    session[:alert]="order upgraded to #{order_type_code}"
    render :inline => %{
        <script>
           window.opener.frames[1].location.reload(true);
          window.close();
        </script>
      }, :layout => 'content'
  end

  def mo_and_mq_orders_not_ready
    return if authorise_for_web(program_name?, 'read') == false
    if params[:page]!= nil
      session[:orders_page] = params['page']
      mo_and_mq_orders_not_ready
      return
    else
      session[:orders_page] = nil
    end

    list_query="select orders.updated_at,parties_r.party_name AS consignee_party_name,parties_roles.party_name AS customer_party_name,

                                orders.*,order_customer_details.discount_percentage,

                                order_customer_details.customer_contact_name,order_customer_details.customer_credit_rating,

                                order_customer_details.customer_credit_rating_timestamp,depots.depot_code,

                                order_customer_details.customer_memo_pad,order_customer_details.customer_order_number,

                                 users.user_name as marketer,order_types.order_type_code,

                                (select load_voyages.booking_reference from load_voyages

                                inner join load_orders on load_orders.order_id=orders.id

                                inner join loads on load_orders.load_id =loads.id

                                where load_voyages.load_id = loads.id limit 1) as booking_reference,

                                (SELECT loads.load_status FROM public.load_orders,public.loads

                                WHERE load_orders.load_id = loads.id AND load_orders.order_id = orders.id limit 1) as load_status

                                from orders

                                inner join parties_roles AS parties_r on orders.consignee_party_role_id = parties_r.id

                                inner join parties_roles on orders.customer_party_role_id = parties_roles.id

                                inner join  order_customer_details ON orders.id=order_customer_details.order_id

                                inner join order_types on orders.order_type_id=order_types.id

                                left join depots on orders.depot_id=depots.id
                                left join users on orders.marketer_user_id = users.id

                                where (order_types.order_type_code ='MO' or order_types.order_type_code ='MQ')

                                and (orders.not_all_pallets_is_stock is true)

                                ORDER BY orders.updated_at DESC limit 500"
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{list_query}\")"

    orders = ActiveRecord::Base.connection.select_all(list_query)
    @orders =[]
    oderz ={}
    if !orders.empty?
      for o in orders
        @orders << o if !oderz.has_key?(o['order_number'])
        oderz[o['order_number']]=[o['order_number']]
      end
    end
    session[:mo_and_mq_orders_not_ready]=true
    @caption="mo_and_mq_orders_not_ready"
    render_list_orders
  end


  def mo_and_mq_orders_can_ugrade
    return if authorise_for_web(program_name?, 'read') == false
    if params[:page]!= nil
      session[:orders_page] = params['page']
      mo_and_mq_orders_can_ugrade
      return
    else
      session[:orders_page] = nil
    end

    list_query="select orders.updated_at,parties_r.party_name AS consignee_party_name,parties_roles.party_name AS customer_party_name,

                                orders.*,order_customer_details.discount_percentage,

                                order_customer_details.customer_contact_name,order_customer_details.customer_credit_rating,

                                order_customer_details.customer_credit_rating_timestamp,

                                order_customer_details.customer_memo_pad,order_customer_details.customer_order_number,

                                 users.user_name as marketer,order_types.order_type_code,depots.depot_code,

                                (select load_voyages.booking_reference from load_voyages

                                inner join load_orders on load_orders.order_id=orders.id

                                inner join loads on load_orders.load_id =loads.id

                                where load_voyages.load_id = loads.id limit 1) as booking_reference,

                                (SELECT loads.load_status FROM public.load_orders,public.loads

                                WHERE load_orders.load_id = loads.id AND load_orders.order_id = orders.id limit 1) as load_status

                                from orders

                                inner join parties_roles AS parties_r on orders.consignee_party_role_id = parties_r.id

                                inner join parties_roles on orders.customer_party_role_id = parties_roles.id

                                inner join  order_customer_details ON orders.id=order_customer_details.order_id

                                inner join order_types on orders.order_type_id=order_types.id

                                left join users on orders.marketer_user_id = users.id
                                left join depots on orders.depot_id=depots.id
                                where (order_types.order_type_code ='MO' or order_types.order_type_code ='MQ')

                                and (orders.not_all_pallets_is_stock is null or orders.not_all_pallets_is_stock is false)

                                ORDER BY orders.updated_at DESC limit 500"
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{list_query}\")"

    orders = ActiveRecord::Base.connection.select_all(list_query)
    @orders =[]
    oderz ={}
    if !orders.empty?
      for o in orders
        @orders << o if !oderz.has_key?(o['order_number'])
        oderz[o['order_number']]=[o['order_number']]
      end
    end
    session[:mo_and_mq_orders_not_ready]=nil
    @caption="mo_and_mq_orders_can_ugrade"
    render_list_orders
  end

  def mo_and_mq_orders_all
    return if authorise_for_web(program_name?, 'read') == false
    if params[:page]!= nil
      session[:orders_page] = params['page']
      mo_and_mq_orders_all
      return
    else
      session[:orders_page] = nil
    end

    list_query="select orders.updated_at,parties_r.party_name AS consignee_party_name,parties_roles.party_name AS customer_party_name,

                orders.*,order_customer_details.discount_percentage,order_types.order_type_code,

                order_customer_details.customer_contact_name,order_customer_details.customer_credit_rating,

                order_customer_details.customer_credit_rating_timestamp,

                order_customer_details.customer_memo_pad,order_customer_details.customer_order_number,

                 users.user_name as marketer,depots.depot_code,

                (select load_voyages.booking_reference from load_voyages

                inner join load_orders on load_orders.order_id=orders.id

                inner join loads on load_orders.load_id =loads.id

                where load_voyages.load_id = loads.id limit 1) as booking_reference,

                (SELECT loads.load_status FROM public.load_orders,public.loads

                WHERE load_orders.load_id = loads.id AND load_orders.order_id = orders.id limit 1) as load_status,

               order_types.order_type_code

                from orders

                inner join parties_roles AS parties_r on orders.consignee_party_role_id = parties_r.id

                inner join parties_roles on orders.customer_party_role_id = parties_roles.id

                inner join  order_customer_details ON orders.id=order_customer_details.order_id

                inner join order_types on orders.order_type_id=order_types.id

                left join users on orders.marketer_user_id = users.id

                left join depots on orders.depot_id=depots.id
                where order_types.order_type_code ='MO' or order_types.order_type_code ='MQ'

                ORDER BY orders.updated_at DESC limit 500"
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{list_query}\")"

    orders = ActiveRecord::Base.connection.select_all(list_query)
    @orders =[]
    oderz ={}
    if !orders.empty?
      for o in orders
        @orders << o if !oderz.has_key?(o['order_number'])
        oderz[o['order_number']]=[o['order_number']]
      end
    end
    @caption="mo_and_mq_orders_all"
    render_list_orders
  end

  def restore_orig_tm
    order=Order.find(params[:id])

    orig_tm=Pallet.find_by_sql("select pallets.orig_target_market_code
                     from pallets
                     inner join load_details on pallets.load_detail_id=load_details.id
                     inner join load_orders on load_details.load_order_id=load_orders.id
                     inner join  orders on load_orders.order_id=orders.id
                     where orders.id=#{order.id}")
    session[:orig_tm]=orig_tm[0].orig_target_market_code
    @msg = "should we change the TM of pallets and cartons back to  '#{orig_tm[0].orig_target_market_code}'? "
    render :inline => %{
       <script>
         if (confirm("<%=@msg%>") == true)
            {window.location.href = "/fg/order/render_restore_orig_tm_confirmed";}
         else
           {window.location.href = "/fg/order/update_canceled";}
      </script>
        }

  end

  def render_restore_orig_tm_confirmed
#    processing('update_tm_confirmed', nil)
    restore_orig_tm_confirmed
  end

  def restore_orig_tm_confirmed
    begin
      order =session[:order]
      @order_id=order.id
      target_market=session[:target_market]
      order.revert_tm
      session[:alert] ="tm successfully reverted"
      render :inline => %{
        <script>
          window.opener.frames[1].location.href = '/fg/order/edit_order/<%=@order_id.to_s%>';
          window.close();
        </script>
      }, :layout => 'content'
    rescue
      puts $!.backtrace.join("\n").to_s

      flash[:error] = $!
      render :inline => %{}, :layout => 'content'
    end
  end

  def change_tm
    order=Order.find(params[:id])
    target_market=TargetMarket.find_by_sql("select target_markets.* from target_markets
                                                join trading_partners on trading_partners.target_market_id=target_markets.id
                                                join parties_roles on trading_partners.parties_role_id=parties_roles.id
                                                where parties_roles.id=#{order.consignee_party_role_id}")
    if !target_market.empty?
      session[:target_market]=target_market[0]
      @msg = "should we change the TM of pallets to '#{target_market[0].target_market_code}'? "
      render :inline => %{
       <script>
         if (confirm("<%=@msg%>") == true)
            {window.location.href = "/fg/order/render_changing_tm_confirmed";}
         else
           {window.location.href = "/fg/order/update_tm_canceled";}
      </script>
        }
    else
      render :inline => %{
       <script>
        alert("Create Trading Partner record and link target market first");
        window.close();
      </script>
        }
    end
  end

  def render_changing_tm_confirmed
#    processing('update_tm_confirmed', nil)
    update_tm_confirmed
  end

  def update_tm_confirmed
    begin
      order =session[:order]
      @order_id=order.id
      target_market=session[:target_market]
      msg=order.change_tm(target_market)
      session[:alert] ="tm successfully changed"
      render :inline => %{
        <script>
          window.opener.frames[1].location.href = '/fg/order/edit_order/<%=@order_id.to_s%>';
          window.close();
        </script>
      }, :layout => 'content'
    rescue
      puts $!.backtrace.join("\n").to_s

      flash[:error] = $!
      render :inline => %{}, :layout => 'content'
    end


  end

  def update_tm_canceled
    render :inline => %{
         <script>
          alert(" update of tm cancelled");
          window.close();
        </script>
          }
  end

  def trading_partner_changed
    consignee_party_role_id = get_selected_combo_value(params)
    @currencies=Currency.find_by_sql("select * from currencies  ").map { |c| [c.currency_code, c.id] }
    @incoterms=Incoterm.find_by_sql("select * from incoterms ").map { |c| [c.incoterm_code, c.id] }
    @marketers=User.find_by_sql("select id,users.user_name from users where department_name='Marketing' order by user_name desc ").map { |c| [c.user_name, c.id] }
    @customer_contact_name= nil
    if consignee_party_role_id == "" or consignee_party_role_id == "<empty>"

    else
      trading_partner=TradingPartner.find_by_parties_role_id(consignee_party_role_id.to_i)
      if trading_partner
        if trading_partner.currency_id
          @currencies=Currency.find_by_sql("select * from currencies where id =#{trading_partner.currency_id}").map { |c| [c.currency_code, c.id] }
        else
          @currencies=Currency.find_by_sql("select * from currencies  ").map { |c| [c.currency_code, c.id] }
          @currencies.unshift("<empty>")
        end
        if trading_partner.incoterm_id
          @incoterms=Incoterm.find_by_sql("select * from incoterms where id=#{trading_partner.incoterm_id}").map { |c| [c.incoterm_code, c.id] }
        else
          @incoterms=Incoterm.find_by_sql("select * from incoterms ").map { |c| [c.incoterm_code, c.id] }
          @incoterms.unshift("<empty>")
        end
        if trading_partner.marketer_user_id
          @marketers=User.find_by_sql("select * from users where id=#{trading_partner.marketer_user_id}").map { |c| [c.user_name, c.id] }
        else
          @marketers=User.find_by_sql("select id,users.user_name from users where department_name='Marketing' order by user_name desc").map { |c| [c.user_name, c.id] }
          @marketers.unshift("<empty>")
        end
        if  trading_partner.contact_name
          @customer_contact_name=trading_partner.contact_name
        end

      end
    end


    render :inline => %{
             <% currency_content = select('order','currency_id',@currencies) %>
             <% incoterm_content = select('order','incoterm_id',@incoterms) %>
             <% marketer_content = select('order','marketer_user_id',@marketers) %>
             <% contact_content   = text_field('order','customer_contact_name', :value=>@customer_contact_name)%>
     <script>
       <%= update_element_function(
          "currency_id_cell", :action => :update,
          :content => currency_content) %>

      <%= update_element_function(
          "incoterm_id_cell", :action => :update,
          :content => incoterm_content) %>

       <%= update_element_function(
          "marketer_user_id_cell", :action => :update,
          :content => marketer_content) %>

       <%= update_element_function(
                 "customer_contact_name_cell", :action => :update,
                 :content =>contact_content) %>
    </script>
    }
  end

  def dispatch_docs
    @order_id = params[:id]
    render :template => "fg/dispatch_docs", :layout => "content"
  end

  def new_order
    return if authorise_for_web(program_name?, 'create')== false
    render_new_order
  end

  def render_new_order
    if @is_create_retry == true
    else
      user_name = session[:user_id].user_name
      department_name=User.find_by_user_name(user_name).department_name
      customer_party_role_id = PartiesRole.find_by_sql("select * from parties_roles where party_name='KR' and role_name = 'CUSTOMER'")[0].id
      @order=Order.new
      @order.is_export=true
      @order.order_type_id=OrderType.find_by_order_type_code("MO").id if department_name.upcase.strip=="PLANNING" || department_name.upcase.strip=="MARKETING"
      @order.depot_id=Depot.find_by_depot_code("031").id
      @order.order_date=Time.now
      @order.customer_party_role_id=customer_party_role_id
    end

    render :inline => %{
          <% @content_header_caption = "'create new order'"%>

          <%= build_order_form(@order,'create_order','create_order',false,@is_create_retry)%>

          }, :layout => 'content'
  end

  def create_order

    session[:is_edit] = false
    begin
      Order.transaction do
        if (params[:order][:order_type_id] == "")
          params[:order][:order_type_id] = nil
        end
        if (params[:order][:consignee_party_role_id] == "")
          params[:order][:consignee_party_role_id] = nil
        end
        if (params[:order][:customer_party_role_id] == "")
          params[:order][:customer_party_role_id] = nil
        end

        @order = Order.new(params[:order])
        @order.order_number = MesControlFile.next_seq_web(8)
        @order.created_at = Time.now
        if @order.save
          order_type =OrderType.find(@order.order_type_id).order_type_code
          if order_type.strip=="MO" || order_type.strip=="MQ"
            session[:mo_mq_order_type]=true
            order_status = @order.set_status("#{order_type}" + "_"+"Order Created")
            @order.order_status=order_status
            @order.not_all_pallets_is_stock=true
            @order.update
            customer=OrderCustomerDetail.find_by_order_id(@order.id)
            send_email(@order, order_type,customer)

          else
            session[:mo_mq_order_type]=false
            order_status = @order.set_status("Order Created")
            @order.update_attribute(:order_status, order_status)
          end
          notify_marketer(@order)
          session[:order] = @order

          @order = Order.find(:first, :conditions => "order_number = '#{@order.order_number}'")
          params[:id] = @order.id
          edit_order
        else
          @is_create_retry = true
          render_new_order
        end
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def notify_marketer(order)
    marketer=[]
    marketer=User.find_by_sql("select * from users where id=#{order.marketer_user_id}") if order.marketer_user_id

    if !marketer.empty?
     if session[:user_id].user_name.upcase != marketer[0].first_name.upcase
       marketer=marketer[0]
           trading_partner = PartiesRole.find_by_sql("SELECT parties_roles.id, parties_roles.party_name,trading_partners.remarks
                                      FROM parties_roles
                                      inner join trading_partners on trading_partners.parties_role_id=parties_roles.id
                                      WHERE parties_roles.role_name = 'TRADING PARTNER' and parties_roles.id=#{order.consignee_party_role_id} ")
           if !trading_partner.empty?
             trading_partner=trading_partner[0]
           else
             trading_partner=""
           end
           msg = "Order  has been created.<br> Order number:  #{order.order_number}.<br>"
           msg += " " + "Customer: #{trading_partner.party_name} - #{trading_partner.remarks}.<br>"
           msg += " " + "Load date:  #{order.loading_date.to_date if order.loading_date}.<br>"
           subj = "#{order.order_number} for Customer: #{trading_partner.party_name} - #{trading_partner.remarks}"
           order.notify_marketer_order_created(msg,subj,marketer.email_address)
     end
end
  end

  def send_email(order, order_type,customer)
    trading_partner = PartiesRole.find_by_sql("SELECT parties_roles.id, parties_roles.party_name,trading_partners.remarks
                           FROM parties_roles
                           inner join trading_partners on trading_partners.parties_role_id=parties_roles.id
                           WHERE parties_roles.role_name = 'TRADING PARTNER' and parties_roles.id=#{order.consignee_party_role_id} ")
    if !trading_partner.empty?
      trading_partner=trading_partner[0]
    else
      trading_partner=""
    end
    msg = "Order of type #{order_type} has been created.<br> Order number:  #{order.order_number}.<br>"
    msg += " " + "Customer: #{trading_partner.party_name} - #{trading_partner.remarks}.<br>"
    msg += " " + "Load date:  #{order.loading_date.to_date if order.loading_date}.<br>"
    msg += " " + "Memo pad:  #{customer.customer_memo_pad}"
    subj = "Early order: #{order.order_number} for Customer: #{trading_partner.party_name} - #{trading_partner.remarks}"
    order.notify_early_order_created(msg,subj)
  end


  def edit_order

    return if authorise_for_web(program_name?, 'edit')==false
    session[:edit_order] = "edit"
    id = params[:id]
    if id && @order = Order.find_by_sql("select orders.*,order_customer_details.discount_percentage,
                                        order_customer_details.customer_contact_name,order_customer_details.customer_credit_rating,
                                        order_customer_details.customer_credit_rating_timestamp,
                                        order_customer_details.customer_memo_pad,order_customer_details.customer_order_number
                                        from orders JOIN order_customer_details ON orders.id=order_customer_details.order_id where orders.id=#{id}")[0]


      orig_tm=Pallet.find_by_sql("select pallets.orig_target_market_code
                     from pallets
                     inner join load_details on pallets.load_detail_id=load_details.id
                     inner join load_orders on load_details.load_order_id=load_orders.id
                     inner join  orders on load_orders.order_id=orders.id
                     where orders.id=#{@order.id}")
      if !orig_tm.empty?
        @order['orig_tm']=orig_tm[0].orig_target_market_code

      else
        @order['orig_tm']=nil

      end

      session['order_id'] = id
      session['order_number'] = @order.order_number
      session[:order] = @order
      order_type =OrderType.find(session[:order].order_type_id).order_type_code
      if order_type=="MO" || order_type=="MQ"
        session[:mo_mq_order_type]=true
      else
        session[:mo_mq_order_type]=false
      end
      session[:current_editing_order]=@order
      session[:current_viewing_order]=nil
      @caption="edit order"
      @is_view=nil
      set_active_doc("order", @order.id)
      render_edit_order
    end
  end

  def render_edit_order
    render :inline => %{
            <% @content_header_caption = "'#{@caption}'" %>
            <%= build_edit_order_form(@order,'update_order','update_order',true,nil,@is_view)%>
            }, :layout => 'content'
  end

  def update_order

    id = session['order_id']
    @order = Order.find(id)
    @order_id = @order.id
    session[:order]=@order
    session[:params_order]=params[:order]
    order_pallets =Pallet.find_by_sql("select pallets.*
                                           from pallets
                                           inner join load_details on pallets.load_detail_id=load_details.id
                                           inner join load_orders on load_details.load_order_id=load_orders.id
                                           inner join  orders on load_orders.order_id=orders.id
                                           where orders.id=#{@order.id} and pallets.orig_target_market_code is null")
    party_name=PartiesRole.find(@order.customer_party_role_id).party_name
    session[:updating_order]=true
    if (party_name=="KR" || party_name=="KM") && ((@order.changed_tm==false || @order.changed_tm==nil) && !order_pallets.empty?) or (@order.changed_tm==true && !order_pallets.empty?)
      @msg = "Do you want to change the target market? "
      render :inline => %{
       <script>
         if (confirm("<%=@msg%>") == true)
            {window.location.href = '/fg/order/edit_change_tm';}
         else
           {window.location.href = "/fg/order/confirm_update_order";}
      </script>
        }
    else
      confirm_update_order

          order_type =OrderType.find(@order.order_type_id).order_type_code
	#RAILS_DEFAULT_LOGGER.info("EOE order type "+order_type.strip)
	    if !(order_type.strip=="MO" || order_type.strip=="MQ")
		user_name = session[:user_id].user_name
                department_name=User.find_by_user_name(user_name).department_name
           trading_partner = PartiesRole.find_by_sql("SELECT parties_roles.id, parties_roles.party_name,trading_partners.remarks
                                      FROM parties_roles
                                      inner join trading_partners on trading_partners.parties_role_id=parties_roles.id
                                      WHERE parties_roles.role_name = 'TRADING PARTNER' and parties_roles.id=#{@order.consignee_party_role_id} ")
           if !trading_partner.empty?
             trading_partner=trading_partner[0]
           else
             trading_partner=""
           end
		#RAILS_DEFAULT_LOGGER.info("EOE username/dept "+user_name+"/"+ department_name)
                if department_name.upcase.strip=="PLANNING" || department_name.upcase.strip=="MARKETING"

		    msg = "Order has been updated by #{user_name} .<br> Order number:  #{@order.order_number}.<br>"
		    subj = "Early order: #{@order.order_number} for Customer: #{trading_partner.party_name} - #{trading_partner.remarks} has been updated"
		    @order.notify_order_updated_by_marketer(msg,subj)

		end
	    end
    end
  end

  def edit_change_tm
    flash[:error]="Change target market"
    @order_id=session[:order].id
    render :inline => %{
           <script>
                window.location.href = '/fg/order/edit_order/<%= @order_id.to_s%>';
          </script>
            }
  end


    def confirm_update_order
    begin
      Order.transaction do
        id = session['order_id']
        @order = session[:order]
        @order_id = @order.id
        @order_customer_detail = OrderCustomerDetail.find_by_order_id(@order.id)
        params[:order]=session[:params_order]
        depot_code=Depot.find(params[:order][:depot_id].to_i).depot_code
        params[:order][:depot_code]=depot_code
        @order.update_attributes({ :depot_code => params[:order][:depot_code],
                                    :is_prelim => params[:order][:is_prelim],
                                   :incoterm_id => params[:order][:incoterm_id],
                                   :currency_id => params[:order][:currency_id],
                                   :order_type_id => params[:order][:order_type_id], :depot_id => params[:order][:depot_id],
                                   :line_of_business_code => params[:order][:line_of_business_code],
                                   :order_date => params[:order][:order_date], :order_description => params[:order][:order_description],
                                   :customer_party_role_id => params[:order][:customer_party_role_id],
                                   :order_credit_ratings => params[:order][:customer_credit_rating],
                                   :promised_delivery_date => params[:order][:promised_delivery_date],
                                   :consignee_party_role_id => params[:order][:consignee_party_role_id],
                                   :is_export => params[:order][:is_export],
                                   :marketer_user_id => params[:order][:marketer_user_id],
                                   :loading_date => params[:order][:loading_date]})

            @order_customer_detail.update_attributes({
                                                          :discount_percentage => params[:order][:discount_percentage],
                                                          :customer_credit_rating => params[:order][:customer_credit_rating],
                                                          :customer_credit_rating_timestamp => params[:order][:customer_credit_rating_timestamp],
                                                          :customer_order_number => params[:order][:customer_order_number],
                                                          :customer_contact_name => params[:order][:customer_contact_name],
                                                          :customer_memo_pad => params[:order][:customer_memo_pad]
                                                      })
        if session[:mo_mq_order_type]
          if session[:current_editing_order].order_type_id != @order.order_type_id
            order_type =OrderType.find(@order.order_type_id).order_type_code
            order_status = @order.set_status("#{order_type}" + "_"+"Order Created")
            @order.order_status=order_status
            @order.update
          end
        end
        order_products=OrderProduct.find_all_by_order_id(@order.id)
            order_products_prices=OrderProduct.find_by_sql("
             select order_products.* from order_products
             where order_id=#{@order.id} and (price_per_carton is not null and price_per_carton > 0.00 )
            ")
            if !order_products_prices.empty? #&& order_products_prices.length==order_products.length
              if @order.price_check==nil || @order.price_check==false || @order.price_check=="f"
                @order.price_check=true
                @order.update
                customer_party_name = PartiesRole.find(@order.consignee_party_role_id).party_name
	              customer_remarks = PartiesRole.find(@order.consignee_party_role_id).remarks
                msg="order_products : #{@order.order_number} have a price.  Customer: #{customer_party_name} -  #{customer_remarks}"
                @order.notify_price(msg)
              end

            end


        session[:updating_order]=nil
        session['order_id'] = id
        session['order_number'] = @order.order_number
        session[:order] = @order
        session[:alert] = "record successfuly  updated"
        render :inline => %{
                                <script>
                                    location.href = '/fg/order/edit_order/<%= @order_id.to_s%>';
                              </script>} and return

      end

    rescue
      return $!
    end

    render :inline => %{
                          <script>
                              location.href = '/fg/order/render_edit_order/<%= @order_id.to_s%>';
                        </script>}


  end

  def current_order
    @order = Order.find(session[:active_doc]['order'])   if session[:active_doc]!=nil
    if (session[:edit_order] == "edit") && @order!= nil
      set_active_doc("order", @order.id)
      session[:current_viewing_order]=nil
      @is_view=nil
      @caption="edit_order"
      params[:id] = @order.id
      edit_order
    else
      render :inline => %{<script> alert('no current order'); </script>}, :layout => 'content'
    end
  end


  def complete_order
    id =session['order_id']
    @order = Order.find(id)
    @order_status = @order.complete_order
    @order
    redirect_to :controller => 'fg/order', :action => 'edit_order', :id => @order.id and return
    render :inline => %{<script>
                         alert('<%="#{@order_status}"%>');
                        </script>}
  end

  def order_status_histories
    order_id = params[:id].to_i
    @order_status_histories = OrderStatusHistory.find_by_sql("select order_status_histories.date_created,orders.id,order_status_histories.order_status ,orders.order_number
                               from orders inner join order_status_histories on orders.id = order_status_histories.order_id
                               where orders.id ='#{order_id}' ORDER BY orders.id desc")
    render :inline => %{
      <% grid            = build_order_status_histories_grid(@order_status_histories) %>
      <% grid.caption    = 'order_status_histories' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@order_status_histories_pages) if @order_status_histories_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def list_orders
    return if authorise_for_web(program_name?, 'read') == false
    if params[:page]!= nil
      session[:orders_page] = params['page']
      render_list_orders
      return
    else
      session[:orders_page] = nil
    end

    list_query="select orders.updated_at,parties_r.party_name AS consignee_party_name,parties_roles.party_name AS customer_party_name,

                                orders.*,order_customer_details.discount_percentage,depots.depot_code,order_types.order_type_code,

                                order_customer_details.customer_contact_name,order_customer_details.customer_credit_rating,

                                order_customer_details.customer_credit_rating_timestamp,

                                order_customer_details.customer_memo_pad,order_customer_details.customer_order_number,

                                 users.user_name as marketer,

                                (select load_voyages.booking_reference from load_voyages

                                inner join load_orders on load_orders.order_id=orders.id

                                inner join loads on load_orders.load_id =loads.id

                                where load_voyages.load_id = loads.id limit 1) as booking_reference,

                                (SELECT loads.load_status FROM public.load_orders,public.loads

                                WHERE load_orders.load_id = loads.id AND load_orders.order_id = orders.id limit 1) as load_status,
                                order_types.order_type_code

                                from orders

                                inner join parties_roles AS parties_r on orders.consignee_party_role_id = parties_r.id

                                inner join parties_roles on orders.customer_party_role_id = parties_roles.id
                                left join depots on orders.depot_id=depots.id
                                inner join  order_customer_details ON orders.id=order_customer_details.order_id
                                inner join order_types on orders.order_type_id=order_types.id
                                left join users on orders.marketer_user_id = users.id


                                where orders.order_status NOT LIKE 'SHIPPED%' and order_types.order_type_code not in ('MO','MQ')

                                ORDER BY orders.updated_at DESC limit 500"
    session[:query]="ActiveRecord::Base.connection.select_all(\"#{list_query}\")"

    orders = ActiveRecord::Base.connection.select_all(list_query)
    @orders =[]
    oderz ={}
    if !orders.empty?
      for o in orders
        @orders << o if !oderz.has_key?(o['order_number'])
        oderz[o['order_number']]=[o['order_number']]
      end
    end
    session[:mo_and_mq_orders_not_ready]=nil
    @caption="orders"
    render_list_orders
  end


  def render_list_orders

    @pagination_server = "list_orders"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:orders_page]
    @current_page = params['page']||= session[:orders_page]
#    @orders = eval(session[:query]) if !@orders

    render :inline => %{
      <% grid            = build_order_grid(@orders,@can_edit,@can_delete) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@order_pages) if @order_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def add_order_product

    session[:order_id] = params[:id]
    dm_session['se_layout'] = 'content'
    @content_header_caption = "'add_order_products'"
    order=Order.find(session[:order_id])
    order_type =OrderType.find(order.order_type_id).order_type_code
    dm_session[:redirect] = true
    if order_type=="MO" || order_type=="MQ"
      build_remote_search_engine_form("search_mo_mq_order_products.yml", "submit_order_product_search")and return
      dm_session[:redirect] = true
    else
      build_remote_search_engine_form("search_order_products.yml", "submit_order_product_search") and return
      dm_session[:redirect] = true
    end
    dm_session[:redirect] = true

  end

  def submit_order_product_search
    @pagination_server = "list_orders"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:orders_page]
    @current_page = params['page']||= session[:orders_page]
    @item_pack_products_codes= ExtendedFg.connection.select_all(dm_session[:search_engine_query_definition])

    session[:order_id]
    session[:item_pack_products_codes] = @item_pack_products_codes

    render :inline => %{
      <% column_configs = []
         column_configs << {:field_type=>'text', :field_name=>'item_pack_product_code'}
         column_configs << {:field_type=>'text', :field_name=>'old_fg_code'}
         column_configs << {:field_type=>'text', :field_name=>'carton_count'}
         column_configs << {:field_type=>'text', :field_name=>'carton_weight'}
         column_configs << {:field_type=>'text', :field_name=>'price_per_kg'}
         column_configs << {:field_type=>'text', :field_name=>'price_per_carton'}
         column_configs << {:field_type=>'text', :field_name=>'id'}
         @multi_select = "selected_item_packs"
          %>
      <% grid            = get_data_grid(@item_pack_products_codes,column_configs,nil,true) %>
      <% grid.caption    = 'Item Packs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@order_pages) if @order_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end

  def selected_item_packs
    @id = session[:order_id]
    @order = Order.find(@id)
    item_packs = session[:item_pack_products_codes]
    selected_item_packs = selected_records?(item_packs, nil, true)
    parameter_fields_values =dm_session[:parameter_fields_values]
    @order.selected_items(selected_item_packs, parameter_fields_values)
    render :inline => %{<script>
                                alert('order_product added');

               window.opener.frames[1].location.href ="/fg/order/edit_order/<%=@id.to_s%>";

                                window.close();
                        </script>}
  end

  def search_orders_flat
    dm_session['se_layout'] = 'content'
    @content_header_caption = "'search orders'"
    build_remote_search_engine_form("search_order.yml", "search_orders_grid")
    dm_session[:redirect] = true
  end

  def search_orders_grid

    orders = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    @orders =[]
    oderz ={}
    if !orders.empty?
      for o in orders
        @orders << o if !oderz.has_key?(o['order_number'])
        oderz[o['order_number']]=[o['order_number']]
      end
    end
    render_list_orders
  end

     #words are powerful but the WORD is all powerful
   def  create_one_or_more_loads_and_import_pallets
     return if authorise_for_web(program_name?, 'create')==false
    session[:create_load_and_import_pallets]=nil
    order_id = params[:id]
    session[:order_id] = order_id
    session[:load_id]=nil
    render :inline => %{
      		<% @content_header_caption = "'Enter the number of loads'"%>

      		<%= build_number_loads_form(nil,'get_loads','submit_loads',false,@is_create_retry)%>

      		}, :layout => 'content'
  end

  def get_loads
      if params[:load][:number_of_loads]==nil || params[:load][:number_of_loads]=="" || params[:load][:number_of_loads]=="0"
            flash[:error]= "a numerical number is required"
      redirect_to :controller => 'fg/order', :action => 'create_one_or_more_loads_and_import_pallets', :id => session[:order_id]
            return
          end
          if (params[:load][:number_of_loads]).is_numeric?
          else
            flash[:error]= "a numerical number is required"
      redirect_to :controller => 'fg/order', :action => 'render_main_impocreate_one_or_more_loads_and_import_palletsrt_pallets', :id => session[:order_id]
            return
          end

          loads= params[:load][:number_of_loads].to_i
          session[:number_of_loads]=loads
      render_build_import_pallets_form
  end




  def create_load_and_import_pallets
      return if authorise_for_web(program_name?, 'create')==false
      session[:create_load_and_import_pallets]=true
      session[:load_id]=nil
      order_id = params[:id]
       session[:order_id] = order_id
      render_build_import_pallets_form
    end

  def load_import_pallets
    session[:load_id]=params[:id]
    set_active_doc("load", params[:id])
    session[:create_load_and_import_pallets]=nil
    render_build_import_pallets_form
  end

  def render_build_import_pallets_form
    render :inline => %{
  		<% @content_header_caption = "'Enter pallet numbers'"%>

  		<%= build_import_pallets_form(@order,'receive_pallets','submit_pallets',false,@is_create_retry)%>

  		}, :layout => 'content'
  end

  def duplicate_pallets?(pallet_numbers)
    nums = Hash.new
    duplicates=[]
    pallet_numbers.each do |n|
      if nums.has_key?(n)
        duplicates << n
      else
        nums.store(n, n)
      end

    end
    if duplicates.empty?
      return nil
    else
      return duplicates
    end
  end



  def order_from_edi
    render :inline => %{
		<% @content_header_caption = "'Order from edi'"%>

		<%= build_order_from_edi_form(@order,'create_order','create_order',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def delete_order
    return if authorise_for_web(program_name?, 'delete')== false

        id = params[:id]
        order = Order.find(id)
        session[:current_order]=order
        if  order.changed_tm==true ||  order.changed_tm=="t"
          pallet =Pallet.find_by_sql("select pallets.*
                                   from pallets
                                   inner join load_details on pallets.load_detail_id=load_details.id
                                   inner join load_orders on load_details.load_order_id=load_orders.id
                                   inner join  orders on load_orders.order_id=orders.id
                                   where orders.id=#{order.id} limit 1")
          if !pallet.empty?
            @msg = "should the TM of pallets restored to the original:'#{pallet[0].orig_target_market_code}'  from  '#{pallet[0].target_market_code}'? "
                      render :inline => %{
                       <script>
                         if (confirm("<%=@msg%>") == true)
                            {window.location.href = "/fg/order/confirm_delete_render_changing_tm_confirmed";}
                         else
                           {window.location.href = "/fg/order/delete_update_tm_canceled";}
                      </script>
                        }
          else
            session[:delete_and_restore_tm]=nil
            delete_render_changing_tm_confirmed
          end

        else
          session[:delete_and_restore_tm]=nil
          delete_render_changing_tm_confirmed
        end
  end

    def confirm_delete_render_changing_tm_confirmed
      session[:delete_and_restore_tm]=true
      delete_render_changing_tm_confirmed
    end

    def delete_update_tm_canceled
      session[:delete_and_restore_tm]=nil
      delete_render_changing_tm_confirmed
    end

      def delete_render_changing_tm_confirmed
        order=session[:current_order]
        @restore_tm=nil
        begin
        Order.transaction do
        if session[:delete_and_restore_tm]
          @restore_tm=true
        else
          load_details=LoadDetail.find_by_sql("SELECT * FROM load_details WHERE order_id = '#{order.id}'")
          if !load_details.empty?
            for load_detail in load_details
              Pallet.find_by_sql(ActiveRecord::Base.extend_update_sql_with_request("UPDATE pallets SET load_detail_id = null,remarks1=null ,remarks2=null,remarks3=null ,remarks4=null,remarks5=null WHERE load_detail_id  = '#{load_detail.id}'"))
              load_detail.destroy
            end
          end
        end
        order.restore_tm=@restore_tm
        order.update
        order.delete_order
        session[:alert] = " Record deleted."
        list_orders
      end
    rescue
      return $!
    end
  end


#--------------------------------------------------------------------------
# combo_changed event handlers for composite foreign key: commodity_id
#--------------------------------------------------------------------------
  def order_type_id_changed
    order_type_id = get_selected_combo_value(params)

    if order_type_id == ""
      render :inline => %{ Not used }
    else
      order_type_id = get_selected_combo_value(params)
      order_type = OrderType.find(order_type_id)

      if order_type.order_type_code == 'DP'|| order_type.order_type_code == 'CU'
        @depot_codes = Depot.find_by_sql("SELECT DISTINCT * FROM depots").map { |g|
          if g.depot_code!= nil
            [g.depot_code + ":" +"     " + "     " + g.depot_description]
          else
            [g.depot_code]
          end }
        @depot_codes.unshift("<empty>")
        render :inline => %{
          <%= select('order','depot_code',@depot_codes)%>
        }
        #elsif order_type.order_type_code == 'MO'|| order_type.order_type_code == 'MQ'
        #        @is_prelim =true
        #        render :inline => %{
        #            <%is_prelim_content = @is_prelim %>
        #
        #           <script>
        #        <%= update_element_function(
        #                "is_prelim_cell", :action => :update,
        #                :content => is_prelim_content) %>
        #           </script>
        #          }
      else
        render :inline => %{ Not used }
      end
    end

  end


  #def create_loads_og
  #  order_id = params[:id]
  #  @order = Order.find(order_id)
  #  order_products_ids= OrderProduct.find_by_sql("SELECT id FROM order_products WHERE order_id = '#{@order.id }'")
  #  if order_products_ids.empty?
  #    flash[:error]= "load can not be created ,create order_products first"
  #    redirect_to :controller => 'fg/order', :action =>'edit_order', :id => @order.id and return
  #  end
  #  @load = @order.create_loads
  #  if @load.load_status == "LOAD_CREATED"
  #    flash[:notice] = "LOAD_CREATED"
  #  else
  #    flash[:notice] = "Load_could not be created"
  #  end
  #  render_edit_order
  #end

  def print_export_certificate

    load_order_id = params[:id]
    report_unit ="reportUnit=/reports/MES/FG/ExportCertificate&"
    report_parameters="output=pdf&load_order_id=" +"#{load_order_id}"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)
  end

  def export_certificate_addenums

    load_order_id = params[:id]
    report_unit ="reportUnit=/reports/MES/FG/addendum&"
    report_parameters="output=pdf&load_order_id=" +"#{load_order_id}"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)

  end

  def print_mates_receipts
    render :text => "export_certificate"
  end

  def print_tracking_device_docs
    render :text => "export_certificate"
  end

  def ship_delivery
     # RAILS_DEFAULT_LOGGER.info("NAE SHIP DELIVERY - ORDER CONTROLLER")
    load_order=LoadOrder.find(params[:id])
    @order = Order.find("#{load_order.order_id}")
    @order.user = session[:user_id].user_name
    @order.ship_delivery(load_order.load_id)
    render :inline => %{<script>
                           alert('shipped');
                           window.close();
                          window.opener.close();
                           window.opener.opener.frames[1].location.reload(true);
                                 </script>}, :layout => "content"
  end


  def return_delivery
    load_order=LoadOrder.find(params[:id])
    session[:return_load_order]=load_order
    order_id = load_order.order_id
    session[:order_id] = order_id
    render :inline => %{
		<% @content_header_caption = "'Returns'"%>

		<%= build_returns_form(@order,'get_returns','return',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def get_returns
    order_id = session[:order_id]
    location = params[:order][:location_code]
    session[:location]=location
    render :inline => %{
                       <script>
                         if(confirm("Are you sure you want the delivery to be returned?") == true)
                            window.location = "/fg/order/undo_stork_destroy";
                         else
                            window.location = "/fg/order/cancel_delivery_return";
                         end
                       </script>}
  end

  def undo_stork_destroy
    Order.transaction do
      order_id = session[:order_id]
      location_code = Location.find(session[:location]).location_code
      load_order=session[:return_load_order]
      load_order_id=load_order.id
      pallet_nums=Pallet.find_by_sql("select pallet_number from pallets
                                    inner join load_details on load_details.id = pallets.load_detail_id
                                    inner join load_orders on load_details.load_order_id =load_orders.id
                                    where load_orders.load_id = #{load_order.load_id}")

      pallet_numbers=Array.new
      for pallet_num in pallet_nums
        pallet_numbers << pallet_num['pallet_number']
      end

      Inventory.undo_destroy_stock(pallet_numbers, 'DISPATCH_LOAD_RETURNED', load_order_id)

      Inventory.move_stock('DISPATCH_LOAD_RETURNED', load_order_id, location_code, pallet_numbers)

      #set exit_ref and load_detail_id to null
      Pallet.find_by_sql(ActiveRecord::Base.extend_update_sql_with_request("UPDATE pallets SET load_detail_id = null, exit_ref=null  where id IN (select pallets.id from pallets join load_details on (pallets.load_detail_id = load_details.id)
                         join loads on (loads.id = load_details.load_id)
                         join load_orders on (loads.id = load_orders.load_id)
                         where load_orders.load_id = #{load_order.load_id})"))
      status =Load.find(load_order.load_id).set_status("RETURNED")

      loads=Load.find_by_sql("select loads.* from loads
                            inner join load_orders on load_orders.load_id=loads.id
                            where load_orders.order_id=#{order_id}")
      if !loads.empty?
        load_statuses=loads.map { |l| l.load_status }

        other_statuses=[]
        for status in load_statuses
          other_statuses << status if status!="RETURNED"
        end
        if other_statuses.empty?
          Order.find(order_id).set_status("RETURNED")
        end
      end
      session[:return_load_order]=nil
      render :inline => %{<script>
                          alert("returned");
                          window.opener.opener.frames[1].location.reload(true);
                          window.opener.close();
                          window.close();
                          </script>
                          }

    end

  end

  def cancel_delivery_return
    render :inline => %{<script>
                          window.close();
                          </script>
                          }
  end


  def send_edi
    begin

      @load_order = LoadOrder.find(params[:id])
      if !@load_order
        flash[:error] = "create loads first"
        redirect_to :controller => 'fg/order', :action => 'edit_order', :id => @load_order.order_id
      end
      EdiOutProposal.send_doc(@load_order, 'PO')


      #rescue handle_error("This EDI proposal cannot be created: Unable to derive the EDI destination")
    end
    render :inline => %{<script>
                          alert("edi successful");

                          window.close();
                          </script>
                          }
  end


  def resend_po
      load_order = LoadOrder.find(params[:id])
      @order = Order.find("#{load_order.order_id}")
      @order.user = session[:user_id].user_name
      @order.resend_po(load_order)
      render :inline => %{<script>
                            alert("po_resend");

                            window.close();
                            </script>
                            }
  end

  def resend_hwe_sales
    load_order = LoadOrder.find(params[:id])
    @order = Order.find("#{load_order.order_id}")
    @order.user = session[:user_id].user_name
    @order.resend_hwe_sales(load_order)
    render :inline => %{<script>
                          alert("hwe_sales resend");

                          window.close();
                          </script>
                          }
  end


  def order_not_shipped

    render :inline => %{<script>
                          alert("Order must be shipped to print docs or send edi's");

                          window.close();
                          </script>
                          }

  end

  def resend_po_to_marketing
     load_order = LoadOrder.find(params[:id])
     @order = Order.find("#{load_order.order_id}")
     @order.user = session[:user_id].user_name
     @order.resend_po_to_marketing(load_order)
     render :inline => %{<script>
                           alert("resend_po_to_marketing");

                           window.close();
                           </script>
                           }
   end

  def resend_pf
   load_order = LoadOrder.find(params[:id])
   @order = Order.find("#{load_order.order_id}")
   @order.user = session[:user_id].user_name
   @order.resend_pf(load_order)
   render :inline => %{<script>
                         alert("pf _resend");

                         window.close();
                         </script>
                         }
 end

  def delivery_detail
    load_order_id = params[:id]
    load=Load.find_by_sql("select loads.* from loads inner join load_orders on load_orders.load_id=loads.id where load_orders.id=#{load_order_id}")[0]
    if load.dispatch_consignment_printed_date ==nil
     load.dispatch_consignment_printed_date=Time.now.to_formatted_s(:db)
     load.update
   end
    report_unit ="reportUnit=/reports/MES/FG/dispatch_consignment&"
    report_parameters="output=pdf&load_order_id=" +"#{load_order_id}" + "&pallet_report=detail"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)

  end

  def delivery_summary
    load_order_id = params[:id]
    load=Load.find_by_sql("select loads.* from loads inner join load_orders on load_orders.load_id=loads.id where load_orders.id=#{load_order_id}")[0]
    if load.dispatch_consignment_printed_date ==nil
     load.dispatch_consignment_printed_date=Time.now.to_formatted_s(:db)
     load.update
   end
    report_unit = "reportUnit=/reports/MES/FG/dispatch_consignment&"
    report_parameters = "output=pdf&load_order_id=" +"#{load_order_id}" + "&pallet_report=summary"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)

  end

  def set_printer
     @content_header_caption = "'select a printer'"
     render :inline => %{
                        <%= build_printer_selection_form()%>
                        }, :layout => 'content'
  end


  def set_printer_submit
    printer_name = params['printer']['friendly_name']
    printer = Printer.find_by_friendly_name(printer_name)
    session[:orders_printer] =  printer.system_name
    redirect_to_index("printer set to: " + printer_name + "   (system name is: " + printer.system_name + ")")
  end

  def loads_signed_docs_print_all

    if(!session[:orders_printer])
      flash[:error] = "Could not print Document : Printer not specified. Please set printer."
      redirect_to_index
      return
    end


    @consignment_note_numbers = Pallet.find_by_sql("select distinct pallets.consignment_note_number
                                        from pallets
                                        inner join load_details on pallets.load_detail_id=load_details.id
                                        inner join load_orders on load_details.load_order_id=load_orders.id
                                        inner join  loads on load_orders.load_id=loads.id
                                        where load_orders.id=#{params[:id]}
                                        GROUP BY pallets.consignment_note_number").map{|p| p.consignment_note_number}

    if(RUBY_PLATFORM.index('linux'))
      print_command_file_name = Globals.jasper_reports_printing_component + "/print_command_" + session[:user_id].user_name + "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".sh"
      file = File.new(print_command_file_name, "w")
      file.puts "cd #{Globals.jasper_reports_printing_component}"
      @consignment_note_numbers.each do |doc|
        file.puts "lp -d '#{session[:orders_printer]}' #{Globals.signed_intake_docs}#{doc}.pdf"
      end

      file.close

      result = eval "\` sh " + print_command_file_name + "\`"
      File.delete(print_command_file_name)
    else
      result = "WINDOWS: Could not print"
    end

    flash[:error] = result.to_s
    redirect_to_index
  end

  def print_signed_load_consignment

    if(!session[:orders_printer])
      flash[:error] = "Could not print Document : Printer not specified. Please set printer."
      redirect_to_index
      return
    end

    if(RUBY_PLATFORM.index('linux'))
      print_command_file_name = Globals.jasper_reports_printing_component + "/print_command_" + session[:user_id].user_name + "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".sh"
      file = File.new(print_command_file_name, "w")
      file.puts "cd #{Globals.jasper_reports_printing_component}"
      file.puts "lp -d '#{session[:orders_printer]}' #{Globals.signed_intake_docs}#{params[:id]}.pdf"
      file.close

      result = eval "\` sh " + print_command_file_name + "\`"
      File.delete(print_command_file_name)
    else
      result = "WINDOWS: Could not print"
    end

    flash[:error] = result.to_s
    redirect_to_index
  end

end
