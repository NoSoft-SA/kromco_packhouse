class RmtProcessing::BinOrderController < ApplicationController

def program_name?
	"bin_order"
end

def bypass_generic_security?
	true
end

def cancel_bin_order
  authorised = authorise("bin_order", 'bin_sales_supervisor',session[:user_id].user_name)

  if !authorised
    flash[:error] = "You do not have permission to perfom this function"
    list_bin_orders
  else
    begin
      ActiveRecord::Base.transaction do
        id= params[:id]
        bin_order = BinOrder.find(id)

#      bin_order.find_objects
        bin_order.archive_bin_order_objects(session[:user_id].user_name)

        session[:alert] = " Order canceled."
        list_bin_orders



      end
    rescue
      raise $!
    end
  end


end


def bin_sale_tripsheet
  bin_order_id = params[:id]

end



def list_bin_orders
	return if authorise_for_web(program_name?,'read') == false

 	if params[:page]!= nil

 		session[:bin_orders_page] = params['page']

		 render_list_bin_orders

		 return
	else
		session[:bin_orders_page] = nil
	end

	 @bin_orders = BinOrder.find_by_sql("select bin_orders.updated_at,parties_r.party_name AS trading_partner,parties_roles.party_name AS customer_party_name,

                                bin_orders.customer_order_number,bin_orders.remarks_1,bin_orders.remarks_2,bin_orders.user_name,bin_orders.created_on,bin_orders.status AS order_status,

                                bin_orders.bin_order_number,bin_orders.updated_at,bin_orders.id,


                                (SELECT bin_loads.status  FROM public.bin_order_loads,public.bin_loads

                                WHERE bin_order_loads.bin_load_id = bin_loads.id AND bin_order_loads.bin_order_id = bin_orders.id limit 1) as load_status

                                from bin_orders

                                inner join parties_roles AS parties_r on bin_orders. trading_partner_party_role_id = parties_r.id

                                inner join parties_roles on bin_orders.customer_party_role_id = parties_roles.id

                                 ORDER BY bin_orders.updated_at DESC limit 100")


    session[:query] = @bin_orders
	render_list_bin_orders
end


def render_list_bin_orders
  @pagination_server = "list_bin_orders"
  @can_edit = authorise(program_name?,'edit',session[:user_id])
  @can_delete = authorise(program_name?,'delete',session[:user_id])
  @can_cancel=  authorise(program_name?,'cancel',session[:user_id])
  @current_page = session[:bin_orders_page]
  @current_page = params['page']||= session[:bin_orders_page]
  @bin_orders =  session[:query]

    render :inline => %{
        <% grid            = build_bin_order_grid(@bin_orders,@can_edit,@can_delete,@can_cancel)%>
        <% grid.caption    = 'list of all bin_orders' %>
        <% @header_content = grid.build_grid_data %>

        <% @pagination = pagination_links(@bin_order_pages) if @bin_order_pages != nil %>
        <%= grid.render_html %>
        <%= grid.render_grid %>
    }, :layout => 'content'
end

def search_bin_orders_flat
	session['se_layout'] = 'content'
    @content_header_caption = "'search bin orders'"
    build_remote_search_engine_form("search_bin_order.yml","search_bin_orders_grid")
    dm_session[:redirect] = true
end

def remove_duplicate_orders(bin_orders)
   orders=[]
   bin_orders.group_by { |a| a.bin_order_number }.map { |p| orders << p[1][0] }
  return orders
end

def search_bin_orders_grid

  @bin_orders = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
  @bin_orders=remove_duplicate_orders(@bin_orders)
  @can_edit = authorise(program_name?,'edit',session[:user_id])
  @can_delete = authorise(program_name?,'delete',session[:user_id])
  @can_cancel=  authorise(program_name?,'cancel',session[:user_id])

    render :inline => %{
        <% grid            = build_bin_order_grid(@bin_orders,@can_edit,@can_delete, @can_cancel )%>
        <% grid.caption    = @caption %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
    }, :layout => 'content'
end

def current_order
    @bin_order =session[:bin_order]
    if (session[:edit_order] == "edit") && @bin_order!=nil

   redirect_to :controller => 'rmt_processing/bin_order', :action => 'edit_bin_order', :id => @bin_order.id and return
    else
      render :inline=>%{<script> alert('no current order'); </script>}, :layout=>'content'
    end
  end

def render_bin_order_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  bin_orders'"%>

		<%= build_bin_order_search_form(nil,'submit_bin_orders_search','submit_bin_orders_search',@is_flat_search)%>

		}, :layout => 'content'
end


def submit_bin_orders_search
	@bin_orders = dynamic_search(params[:bin_order] ,'bin_orders','BinOrder')
	if @bin_orders.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_bin_order_search_form
		else
			render_list_bin_orders
    end
end

def delete_bin_order
    begin
      BinOrder.transaction do
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:bin_orders_page] = params['page']
        render_list_bin_orders
        return
      end
      id = params[:id]
      if id && @bin_order = BinOrder.find(id)
       bin_order_loads =BinOrderLoad.find_all_by_bin_order_id(id)
      if !bin_order_loads.empty?
        for bin_order_load in bin_order_loads
          load_details = BinOrderLoadDetail.find_all_by_bin_order_load_id(bin_order_load.id)
          if !load_details.empty?
            for @load_detail in load_details
              bins_count = Bin.find_by_sql("select COUNT(*) from bins where bin_order_load_detail_id  = #{ @load_detail.id}")[0]['count']
              if bins_count.to_i > 0
                raise "Bins have already bin loaded to this order"
              end
              @load_detail.destroy
            end
          end
            bin_order_load.destroy
        end

      end

        order_products=BinOrderProduct.find_by_sql("SELECT * FROM bin_order_products WHERE bin_order_id = '#{id}'")
        if !order_products.empty?
        for @order_product in order_products
          @order_product.destroy
        end
        end

        if  @bin_order.destroy
          session[:alert] = " Order deleted."
          @bin_orders = BinOrder.find(:all)
          list_bin_orders
        else
          session[:alert] = " Record could not be deleted."
        end
      end
      end
    rescue
      handle_error('record could not be deleted')
    end
  end



def new_bin_order
	return if authorise_for_web(program_name?,'create')== false
		render_new_bin_order
end



def render_new_bin_order
#	 render (inline) the edit template
  @bin_order=BinOrder.new
  @bin_order.match_on_size=true
	render :inline => %{
		<% @content_header_caption = "'create new bin_order'"%>

		<%= build_bin_order_form(@bin_order,'create_bin_order','create_bin_order',false,@is_create_retry)%>

		}, :layout => 'content'
end

def create_bin_order
   session[:is_edit] = false
 begin
	    ActiveRecord::Base.transaction do
      if (params[:bin_order][:order_type_id] == "")
        params[:bin_order][:order_type_id] = nil
      end
      if (params[:bin_order][:trading_partner_party_role_id] == "")
        params[:bin_order][:trading_partner_party_role_id] = nil
      end
      if (params[:bin_order][:customer_party_role_id] == "")
        params[:bin_order][:customer_party_role_id] = nil
      end

      @bin_order = BinOrder.new(params[:bin_order])
      @bin_order.bin_order_number = MesControlFile.next_seq_web(MesControlFile::BIN_ORDER)
      @bin_order.created_on = Time.now
      if @bin_order.save

        StatusMan.set_status("BIN_ORDER_CREATED","bin_order",@bin_order,session[:user_id].user_name)
#
#        @bin_order.update_attribute(:status,status)
        session[:bin_order] = @bin_order

        @bin_order = BinOrder.find(:first, :conditions => "bin_order_number = '#{@bin_order.bin_order_number}'")
        params[:id] = @bin_order.id

        edit_bin_order
      else
        @is_create_retry = true
        render_new_bin_order
      end
      end
rescue
	 handle_error('record could not be created')
end
end

def edit_bin_order
	return if authorise_for_web(program_name?,'edit')==false
     session[:edit_order] = "edit"
	 id = params[:id]
	 if id && @bin_order = BinOrder.find(id)
        session['bin_order_id'] = id
        session['bin_order_number'] = @bin_order.bin_order_number
        session[:bin_order] = @bin_order
		render_edit_bin_order

	 end
end


def render_edit_bin_order
#	 render (inline) the edit template

	render :inline => %{
		<% @content_header_caption = "'edit bin_order'"%>

		<%= build_edit_bin_order_form(@bin_order,'update_bin_order','update_bin_order',true)%>

		}, :layout => 'content'
end

def update_bin_order
 begin
     ActiveRecord::Base.transaction do
	 id = params[:bin_order][:id]
     @bin_order_id = id
	 if id && @bin_order = BinOrder.find(id)
		 if @bin_order.update_attributes(params[:bin_order])
             flash[:notice] = 'record saved'
			 render :inline => %{<script>
                            window.location.href= "/rmt_processing/bin_order/edit_bin_order/<%= @bin_order_id.to_s%>";
                           </script>} and return
	 else
			 render_edit_bin_order

		 end
     end
     end
rescue
	 handle_error('record could not be saved')
end
 end

def order_status_histories
    bin_order_id = params[:id]
    @bin_order = BinOrder.find( bin_order_id)
    session[:status_history_status_type_code] =  "bin_order"
     session[:object_id]=@bin_order.id

    redirect_to :controller => 'inventory/status_type', :action => 'show_status_history', :status_type_code => session[:status_history_status_type_code]  ,:object_id=>session[:object_id]
end

def add_order_product
    session[:bin_order_id] = params[:id]
    dm_session['se_layout'] = 'content'
    @content_header_caption = "'add_order_products'"
    build_remote_search_engine_form("search_bin_order_products.yml", "select_order_products")
    dm_session[:redirect] = true
end

def select_order_products
  @pagination_server = "list_orders"
  @can_edit = authorise(program_name?, 'edit', session[:user_id])
  @can_delete = authorise(program_name?, 'delete', session[:user_id])
  @current_page = session[:bin_orders_page]
  @current_page = params['page']||= session[:bin_orders_page]
  rmt_products= ExtendedFg.connection.select_all(dm_session[:search_engine_query_definition])
  bin_order_id = session[:bin_order_id]
  @rmt_products = Array.new
  for rmt_product in  rmt_products
    count = BinOrderProduct.find_by_sql("select count(bin_order_products.id) as count from bin_order_products
                                          INNER JOIN rmt_products ON rmt_products.rmt_product_code = bin_order_products.rmt_product_code
                                          WHERE bin_order_products.bin_order_id =#{bin_order_id} AND rmt_products.id = #{rmt_product['id']} ")[0]['count']

                                          if count.to_i <= 0
                                            @rmt_products << rmt_product
                                          end
  end

  session[:rmt_products] = @rmt_products

    @column_configs = []
    @column_configs << {:field_type=>'text', :field_name=>'rmt_product_code',:col_width=>272}
    @column_configs << {:field_type=>'text', :field_name=>'available_quantity',:column_caption=>'Available',:col_width=>100}
    @column_configs << {:field_type=>'text', :field_name=>'commodity_code',:column_caption=>'commodity',:col_width=>100}
    @column_configs << {:field_type=>'text', :field_name=>'variety_code',:column_caption=>'variety',:col_width=>81}
    @column_configs << {:field_type=>'text', :field_name=>'product_class_code',:column_caption=>'product_class',:col_width=>110}
    @column_configs << {:field_type=>'text', :field_name=>'size_code',:column_caption=>'size',:col_width=>50}
    @column_configs << {:field_type=>'text', :field_name=>'farm_code',:column_caption=>'farm',:col_width=>122}
    @column_configs << {:field_type=>'text', :field_name=>'location_code',:column_caption=>'location',:col_width=>138}
    @column_configs << {:field_type=>'text', :field_name=>'id'}
    @multi_select = "order_products_selected"
    render :inline => %{
        <% grid            = get_data_grid(@rmt_products,@column_configs,nil,true)%>
        <% grid.caption    = 'rmt_products' %>
        <% @header_content = grid.build_grid_data %>

        <% @pagination = pagination_links(@bin_order_pages) if @bin_order_pages != nil %>
        <%= grid.render_html %>
        <%= grid.render_grid %>
    }, :layout => 'content'
end

def order_products_selected
    @id = session[:bin_order_id]
    @bin_order = BinOrder.find(@id)
    rmt_products= session[:rmt_products]
    selected_rmt_products = selected_records?(rmt_products,nil,true)
    parameter_fields_values = dm_session[:parameter_fields_values]
    @bin_order.selected_rmt_products(selected_rmt_products,parameter_fields_values,session[:user_id].user_name)

    render :inline => %{<script>
                                window.opener.frames[1].location.href ="/rmt_processing/bin_order/edit_bin_order/<%=@id%>";
                                window.close();
                        </script>}

end



end
