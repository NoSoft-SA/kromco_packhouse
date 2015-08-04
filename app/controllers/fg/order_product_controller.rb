class Fg::OrderProductController < ApplicationController

  def program_name?
    "order"
  end

  def bypass_generic_security?
    true
  end

  def get_historic_pricing
    order_products= OrderProduct.find_by_sql("select * from order_products where order_id=#{session[:order].id}")
    order=session[:order]
    if !order_products.empty?
      order_products.each do |order_product|
        price_per_kg=nil
        price_per_carton=nil
        subtotal=0
        latest_shipped_similar_order_product=OrderProduct.find_by_sql("select op.* from order_products op
              join orders o on op.order_id=o.id
              where op.item_pack_product_code='#{order_product.item_pack_product_code}' and op.old_fg_code='#{order_product.old_fg_code}'  and o.consignee_party_role_id=#{order.consignee_party_role_id}
              and o.order_status='SHIPPED' order by o.id desc ")[0]

        if latest_shipped_similar_order_product
          price_per_kg=latest_shipped_similar_order_product.price_per_kg
          price_per_carton=latest_shipped_similar_order_product.price_per_carton
          subtotal =  price_per_carton * order_product.carton_count   if  price_per_carton  &&  order_product.carton_count
        end
        order_product.update_attributes(:price_per_kg=>price_per_kg ,:price_per_carton=>price_per_carton,:subtotal=> subtotal)
      end
    end

    @total = order.calculate_order_amount(order.id)
    if @total==0
      render :inline => %{
                          <script>
                            alert('Historic Price not found');
                            window.close();
                        </script>} and return
    else
      render :inline => %{
                          <script>
                            alert('Price set');
                            window.close();
                            window.opener.location.reload(true);
                            window.opener.frames[1].document.getElementById("total_order_amount_cell").innerHTML= '<%= @total%>';

                        </script>} and return
    end

  end

  def selected_order_products
    load_order=LoadOrder.find_by_load_id(session[:load_id])
    @order_id=load_order.order_id
    @load_id = session[:load_id]
    order_products = session[:products]
    selected_order_products = selected_records?(order_products)
    LoadDetail.create_load_details(selected_order_products,session[:load_id])
    render :inline => %{<script>
            alert('load_details created');
            window.opener.location.href = '/fg/load_detail/list_load_details/<%=@load_id%>';
            window.opener.opener.frames[1].location.href = '/fg/order/edit_order/<%=@order_id%>';
            window.close();
            </script>}
  end

  def prices_for_all_clients
    order_product=OrderProduct.find(params[:id])
    order=Order.find(order_product.order_id)
    list_query ="select parties_roles.party_name as customer,order_products.*
                from order_products
                join orders on order_products.order_id=orders.id
                join parties_roles on orders.customer_party_role_id=parties_roles.id
                where
                order_products.commodity_code='#{order_product.commodity_code}' and
                order_products.marketing_variety_code ='#{order_product.marketing_variety_code}' and
                order_products.size_ref = '#{order_product.size_ref}'and
                order_products.grade_code ='#{ order_product.grade_code}' and
                order_products.inventory_code = '#{order_product.inventory_code}'and
                order_products.target_market_code ='#{order_product.target_market_code}' and
                order_products.puc ='#{order_product.puc}' and
                order_products.old_fg_code ='#{ order_product.old_fg_code}' and
                order_products.pallet_format_product_code ='#{order_product.pallet_format_product_code}' and
                order_products.pc_code = '#{order_product.pc_code}'and
                order_products.season_code = '#{order_product.season_code}'and
                order_products.pick_reference ='#{order_product.pick_reference}' and
                order_products.extended_fg_code ='#{order_product.extended_fg_code}' and
                order_products.item_pack_product_code = '#{order_product.item_pack_product_code}'and
                order_products.basic_pack_code ='#{order_product.basic_pack_code}'and
                order_products.cosmetic_code_name ='#{order_product.cosmetic_code_name}' and
                order_products.product_class_code = '#{order_product.product_class_code}'
                and parties_roles.id <> #{order.customer_party_role_id}
                order by order_products.id desc "
      session[:query]="ActiveRecord::Base.connection.select_all(\"#{list_query}\")"
      order_product_prices = ActiveRecord::Base.connection.select_all(list_query)
      @order_product_prices =[]
    if !order_product_prices.empty?
      price_grps=order_product_prices.group(['customer'],nil,nil)
      for grp in price_grps
        maxi=4
        x=0
        for p in grp
          @order_product_prices << p if x <= maxi
          x =x + 1
        end
      end
      end
    if !@order_product_prices.empty?
          @product=@order_product_prices[0]['item_pack_product_code']
    end
        render_prices_for_all_clients
  end

  def render_prices_for_all_clients
      @use_jq_grid = true
          render :inline => %{
            <% grid            = build_order_product_prices_grid(@order_product_prices,@can_edit,@can_delete) %>
            <% grid.caption    = 'other customer prices' %>
            <% @header_content = grid.build_grid_data %>
            <% grid.group_fields = ['customer'] %>
            <% grid.groupable_fields    = ['customer'] %>
            <% grid.grouped      = true %>
            <% grid.height = '160' %>
            <% @pagination = pagination_links(@order_product_pages) if @order_product_pages != nil %>
            <%= grid.render_html %>
            <%= grid.render_grid %>
            }, :layout => 'content'
    end

  def client_order_product_prices
    order_product=OrderProduct.find(params[:id])
    order=Order.find(order_product.order_id)
    list_query ="select distinct parties_roles.party_name as customer,order_products.*
                from order_products
                join orders on order_products.order_id=orders.id
                join parties_roles on orders.customer_party_role_id=parties_roles.id
                where
                order_products.commodity_code='#{order_product.commodity_code}' and
                order_products.marketing_variety_code ='#{order_product.marketing_variety_code}' and
                order_products.size_ref = '#{order_product.size_ref}'and
                order_products.grade_code ='#{ order_product.grade_code}' and
                order_products.inventory_code = '#{order_product.inventory_code}'and
                order_products.target_market_code ='#{order_product.target_market_code}' and
                order_products.puc ='#{order_product.puc}' and
                order_products.old_fg_code ='#{ order_product.old_fg_code}' and
                order_products.pallet_format_product_code ='#{order_product.pallet_format_product_code}' and
                order_products.pc_code = '#{order_product.pc_code}'and
                order_products.season_code = '#{order_product.season_code}'and
                order_products.pick_reference ='#{order_product.pick_reference}' and
                order_products.extended_fg_code ='#{order_product.extended_fg_code}' and
                order_products.item_pack_product_code = '#{order_product.item_pack_product_code}'and
                order_products.basic_pack_code ='#{order_product.basic_pack_code}'and
                order_products.cosmetic_code_name ='#{order_product.cosmetic_code_name}' and
                order_products.product_class_code = '#{order_product.product_class_code}'
                and parties_roles.id=#{order.customer_party_role_id}
                order by order_products.id desc limit 5"

    session[:query]="ActiveRecord::Base.connection.select_all(\"#{list_query}\")"
    @order_product_prices = ActiveRecord::Base.connection.select_all(list_query)
    if !@order_product_prices.empty?
      @customer=@order_product_prices[0]['customer']
      @product=@order_product_prices[0]['item_pack_product_code']
    end
    render_client_order_product_prices
  end

  def render_client_order_product_prices
    @use_jq_grid = true
        render :inline => %{
          <% grid            = build_order_product_prices_grid(@order_product_prices,@can_edit,@can_delete) %>
          <% grid.caption    = '#{@customer} prices for #{@product}' %>
          <% @header_content = grid.build_grid_data %>
          <% grid.height = '160' %>
          <% @pagination = pagination_links(@order_product_pages) if @order_product_pages != nil %>
          <%= grid.render_html %>
          <%= grid.render_grid %>
          }, :layout => 'content'
  end

  def price_histories_report

  end

  def price_histories
    #return if authorise_for_web(program_name?, 'edit_product_price')==false

    @order_product=OrderProduct.find(params[:id])
    render_price_histories
  end

  def render_price_histories
    render :inline => %{
		<% @content_header_caption = "'price_histories'"%>

		<%= build_price_histories_form(@order_product,'update_order_product','update_order_product',true)%>

		}, :layout => 'content'
  end

  def render_list_order_products
    order_id = params[:id].to_i
    @order= Order.find(order_id)
    @pagination_server = "list_order_products"
    if session['order_products_editable']
      @can_edit = authorise(program_name?, 'edit', session[:user_id])
      @can_delete = authorise(program_name?, 'delete', session[:user_id])
    else
      @can_edit = false
      @can_delete = false
    end
    @current_page = session[:order_products_page]
    @current_page = params['page']||= session[:order_products_page]
    new_order_products = OrderProduct.find_by_sql("SELECT * FROM order_products WHERE order_id = '#{order_id}'")
    existing_order_products=OrderProduct.find_by_sql("
    select order_products.* from order_products
    inner join load_details on load_details.order_product_id=order_products.id
    inner join load_orders on load_details.load_order_id=load_orders.id
    where load_orders.order_id=#{order_id}
                                                     ")

    op={}
    order_products=[]
    if !new_order_products.empty?
      for product in new_order_products
        order_products << product if !op.has_key?(product['id'])
        op[product['id']]=product  if !op.has_key?(product['id'])
      end
    end
    if  !existing_order_products.empty?
      for o_product in existing_order_products
              order_products << o_product if !op.has_key?(o_product['id'])
              op[o_product['id']]= o_product  if !op.has_key?(o_product['id'])
            end
    end

    session[:order_id] = order_id
    @multi_select=session[:multi_select]
    @order_products=[]
    if @multi_select
      order_product_ids=LoadDetail.find_by_sql("select order_product_id from load_details where order_id=#{order_id}").map{|l|l.order_product_id}
      if !order_product_ids.empty?
        for order_product in order_products
          @order_products << order_product if !order_product_ids.include?(order_product.id)
        end
      else
        @order_products=order_products
      end
      @caption='Select order_products to create load_details'
    else
      @order_products=order_products
      @caption="Order Products for Order #{@order.order_number}"
    end
    session[:products] =  @order_products
    if session[:current_viewing_order]
      @view_order=true
    else
      @view_order=nil
    end
    render :template => "fg/order_products/list_order_products", :layout => "content"
  end

  def update_edited_order_products
    order=Order.find(session[:current_editing_order].id)
    updates = {}
    #subtotal=price_per_carton * carton_count
    #order_product.update_attribute(:subtotal, "#{subtotal}")
    order_product_ids=[]
    params[:order_product].each do |k,v|
      k = k.split('_')
      key = k.shift
      order_product_ids << key
      #if(v.to_s.strip.length > 0)
        if(!updates.keys.include?(key))
          updates.store(key,{k.join('_')=>v})
        else
          updates[key].store(k.join('_'),v)
        end
      #end
    end
    prices_per_carton={}
    old_prices_per_carton=[]
    if !order_product_ids.empty?
      order_product_ids=order_product_ids.join(",")
      ids_prices_per_carton=OrderProduct.find_by_sql("select id,price_per_carton from order_products where id in (#{order_product_ids})")
      old_prices_per_carton=ids_prices_per_carton.map{|l|l.price_per_carton}
      for product in ids_prices_per_carton
        prices_per_carton.store(product['id'],product['price_per_carton'])
      end
    end
    changed_prices=[]
    for product in prices_per_carton
      if updates[product[0].to_s ]['price_per_carton'].to_s == product[1].to_s
        else
        changed_prices << product[1]
      end

    end

    OrderProduct.transaction do
      updates.each do |update,cond|
        conditions = cond.map{|k,v|
          if(v.to_s.strip.length > 0)
            "#{k}='#{v}'"
          else
            "#{k}=NULL"
          end
        }
        for member in conditions
          if member.upcase.index("PRICE_PER_CARTON")
             price =member.split("=")[1]
             price  =price.gsub(/'/, '')
             if price != "NULL"
               carton_count = OrderProduct.find(update.to_i).carton_count
               subtotal= carton_count.to_i * price.to_f
               conditions << "subtotal" + "="  + subtotal.to_s
             end
          end
        end



        OrderProduct.update_all(ActiveRecord::Base.extend_set_sql_with_request(conditions.join(','),"order_products"),"id = '#{update}'")
      end
      old_prices_per_carton.delete(nil)
      changed_prices.delete(nil)
      if old_prices_per_carton.empty?
         order.price_check=true
         order.update
       else
         if order.price_check==true
           if !changed_prices.empty?
             order.price_check=false
             order.update
           end
         end
      end

    end
    @order_id=order.id
    @total = order.calculate_order_amount(order.id)

    session[:alert]  = "order products edited successfully"

    render :inline => %{
      <script>
       window.parent.document.getElementById("total_order_amount_cell").innerHTML= '<%= @total%>';
       window.location.href = "render_list_order_products/<%= session[:order].id %>";
      </script>}
  end

  def search_order_products_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_order_product_search_form
  end

  def render_order_product_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
    render :inline => %{
		<% @content_header_caption = "'search  order_products'"%>

		<%= build_order_product_search_form(nil,'submit_order_products_search','submit_order_products_search',@is_flat_search)%>

		}, :layout => 'content'
  end


  def submit_order_products_search
    @order_products = dynamic_search(params[:order_product], 'order_products', 'OrderProduct')
    if @order_products.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_order_product_search_form
    else
      session[:multi_select]=nil
      render_list_order_products
    end
  end


  def delete_order_product

    id = params[:id]
    order_product = OrderProduct.find(id)

    @order = Order.find(order_product.order_id)
    @order_id  = @order.id
    begin
      Order.transaction do
        return if authorise_for_web(program_name?, 'delete')== false
        if params[:page]
          session[:order_products_page] = params['page']
          session[:multi_select]=nil
          render_list_order_products
          return
        end

        @total = @order.calculate_order_amount(@order_id)
        if  order_product = OrderProduct.find(id)
          load_orders = LoadOrder.find_all_by_order_id(@order_id)
          if !load_orders.empty?
            @load_detail = LoadDetail.find_by_order_product_id(order_product.id)
            if @load_detail !=nil
              Pallet.find_by_sql(ActiveRecord::Base.extend_update_sql_with_request("UPDATE pallets SET load_detail_id = null WHERE load_detail_id  = '#{ @load_detail.id}'"))
              @load_detail.destroy
            end
            order_product.destroy
            @load = Load.find("#{load_orders[0]['load_id']}")
            if @load
            load_details_of_load =LoadDetail.find_all_by_load_id(@load.id)
            if load_details_of_load.empty?
              @load_status_history = LoadStatusHistory.find_by_load_id(@load.id)
              @load_status_history.destroy
              @load_order = load_orders[0]
              @load_order.destroy
              @load.destroy
            end
          end
          end
          order_product.destroy
        end

        render :inline => %{
                          <script>
                                alert('order product deleted');
                                parent.location.href = '/fg/order/edit_order/<%=  @order_id%>';
                        </script>}
      end

    rescue
      handle_error('record could not be deleted')
    end
  end


  def new_order_product
    return if authorise_for_web(program_name?, 'create')== false
    render_new_order_product
  end

  def create_order_product
    begin
      @order_product = OrderProduct.new(params[:order_product])
      if @order_product.save

        redirect_to_index("'new record created successfully'", "'create successful'")
      else
        @is_create_retry = true
        render_new_order_product
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_order_product
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new order_product'"%>

		<%= build_order_product_form(@order_product,'create_order_product','create_order_product',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_order_product
    #return if authorise_for_web(program_name?, 'edit_product_price')==false
    id = params[:id]
    if id && @order_product = OrderProduct.find(params[:id])
      session[:unedited_order_product]=@order_product
      render_edit_order_product
    end
  end

  def render_edit_order_product
    id = params[:id]
    @order_product = OrderProduct.find(params[:id])
    session[:price_per_carton]=@order_product.price_per_carton
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit order_product'"%>

		<%= build_order_product_form(@order_product,'update_order_product','update_order_product',true)%>

		}, :layout => 'content'
  end

  def update_order_product
    begin
      Order.transaction do
      id = params[:order_product][:id]
      @order_product = OrderProduct.find(id)
      @order= Order.find("#{@order_product.order_id}")
      old_price_per_carton=session[:price_per_carton]
      if  @order.order_status == "LOAD_CREATED"
        flash[:notice] = 'load already created'
        render :inline => %{
                          <script>
                            window.close();
                        </script>}
      else

        required_quantity = params[:order_product][:required_quantity].to_i
        available_quantities = @order_product.available_quantities
        if available_quantities != nil
          if required_quantity > available_quantities
            flash[:error] = "Order less quantity , required quantity not available"
            redirect_to :controller => 'fg/order_product', :action => 'render_edit_order_product', :id => @order_product.id and return

          end
        end
        #prices_changed=nil
        #if session[:unedited_order_product].price_per_carton  && (params[:order_product][:price_per_carton].to_s != session[:unedited_order_product].price_per_carton.to_s)
        #  prices_changed=true
        #elsif session[:unedited_order_product].price_per_kg && params[:order_product][:price_per_kg].to_s !=session[:unedited_order_product].price_per_kg.to_s
        #  prices_changed=true
        #elsif session[:unedited_order_product].order_product && params[:order_product][:fob] != session[:unedited_order_product].order_product.to_s
        #  prices_changed=true
        #end
        price_per_carton = params[:order_product][:price_per_carton].to_f
        carton_count =@order_product['carton_count'].to_i
        subtotal=price_per_carton * carton_count
#        @order_product.update_attribute(:required_quantity, "#{required_quantity}")
        @order_product.update_attribute(:subtotal, "#{subtotal}")
        @order_product.update_attribute(:price_per_carton, "#{params[:order_product][:price_per_carton]}")
        @order_product.update_attribute(:price_per_kg, "#{params[:order_product][:price_per_kg]}")
        @order_product.update_attribute(:fob, "#{params[:order_product][:fob]}")


        if  @order_product.save
          if !old_price_per_carton
            @order.price_check=true
            @order.update
          else
            if @order.price_check==true
              if old_price_per_carton !=@order_product.price_per_carton
                @order.price_check=false
                @order.update
              end
            end
          end


          session_order_id = @order_product['order_id'].to_i
          @total = @order.calculate_order_amount(session_order_id)
          render :inline => %{
                          <script>
                            alert('order product edited');

                            window.opener.frames[1].frames[0].location.reload(true);
                            window.opener.frames[1].document.getElementById("total_order_amount_cell").innerHTML= '<%= @total%>';
                            window.close();
                        </script>} and return
        else
          render_edit_order_product
        end
      end
      end
      end
  rescue
    handle_error('record could not be saved')
  end

  def selected_item_packs
    order_products = session[:products]
    @selected_item_packs = selected_records?(order_products)
    selected_item_packs
  end


  def order_product_order_number_changed
    order_number = get_selected_combo_value(params)
    session[:order_product_form][:order_number_combo_selection] = order_number
    @customer_party_role_ids = OrderProduct.customer_party_role_ids_for_order_number(order_number)
#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('order_product','customer_party_role_id',@customer_party_role_ids)%>

		}

  end


end
