class  RmtProcessing::BinOrderProductController < ApplicationController
 
def program_name?
	"bin_order"
end

def bypass_generic_security?
	true
end

def status_history
  bin_order_product_id = params[:id]
    @bin_order_product = BinOrderProduct.find( bin_order_product_id)
    session[:status_history_status_type_code] =  "bin_order_product"
     session[:object_id]=@bin_order_product.id

    redirect_to :controller => 'inventory/status_type', :action => 'show_status_history', :status_type_code => session[:status_history_status_type_code]  ,:object_id=>session[:object_id]
end
def list_bin_order_products
	return if authorise_for_web(program_name?,'read') == false 
    session[:bin_order_id]=params[:id]

     bin_order_id = params[:id].to_i
#	list_query = "@bin_order_product_pages = Paginator.new self, BinOrderProduct.count, @@page_size,@current_page
#	 @bin_order_products = BinOrderProduct.find(:all,
#				 :limit => @bin_order_product_pages.items_per_page,
#				 :offset => @bin_order_product_pages.current.offset)"
    @bin_order_products =BinOrderProduct.find_by_sql("select * from bin_order_products  where bin_order_products.bin_order_id=#{bin_order_id}")
    session[:bin_order_products] = @bin_order_products
	render_list_bin_order_products
end
          

def render_list_bin_order_products
	@pagination_server = "list_bin_order_products"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:bin_order_products_page]
	@current_page = params['page']||= session[:bin_order_products_page]
    bin_order_number =BinOrder.find(session[:bin_order_id]).bin_order_number
	bin_order_products = session[:bin_order_products]
    @bin_order_products = Array.new
  for @bin_order_product in bin_order_products

      selected_quantity = Bin.find_by_sql(" select count(bins.id) as selected_quantity from bins
                                            INNER JOIN bin_order_load_details ON bins.bin_order_load_detail_id = bin_order_load_details.id
                                            INNER JOIN bin_order_loads ON bin_order_load_details.bin_order_load_id =bin_order_loads.id
                                            INNER JOIN bin_orders ON bin_order_loads.bin_order_id =bin_orders.id
                                            INNER JOIN bin_order_products on bin_order_products.bin_order_id = bin_orders.id
                                            WHERE bin_order_products.id = #{@bin_order_product.id} and bin_orders.id = #{@bin_order_product.bin_order_id} and
                                            bin_order_load_details.bin_order_product_id=#{@bin_order_product.id}
                                            ")[0]['selected_quantity']


      @bin_order_product['selected_quantity'] =selected_quantity.to_i
      @bin_order_products << @bin_order_product
  end

      render :inline => %{
        <% grid            = build_bin_order_product_grid(@bin_order_products,@can_edit,@can_delete)%>
        <% grid.caption    = "Order Products for Order #{bin_order_number}" %>
        <% grid.height     = 150 %>
        <% @header_content = grid.build_grid_data %>

        <% @pagination = pagination_links(@bin_order_product_pages) if @bin_order_product_pages != nil %>
        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
end

def set_required_quantity
    id = params[:id].to_i

    render_set_required_quantity
  end

  def render_set_required_quantity
      id = params[:id].to_i
      session[:bin_order_product_id]= id
     @bin_order_product = BinOrderProduct.find(id)

    render :inline => %{
          <% @content_header_caption = "'set required quantity'"%>
          <%= build_required_quantity_form(@bin_order_product,'update_quantity','update_quantity',true)%>
          }, :layout => 'content'
  end

  def update_quantity

    begin
      ActiveRecord::Base.transaction do
      bin_order_product_id = session[:bin_order_product_id]
      bin_order_product =BinOrderProduct.find(bin_order_product_id)
      required_quantity = params[:bin_order_product][:required_quantity].to_i

      bin_order_product_required_quantity = bin_order_product.required_quantity
      if bin_order_product_required_quantity && (bin_order_product_required_quantity >= required_quantity &&  (bin_order_product.status =="LOADING"||bin_order_product.status =="ORDER_PRODUCT_CREATED"))
         bin_order_product.calc_and_change_statuses(required_quantity,session[:user_id].user_name)
      end
      if bin_order_product_id && @bin_order_product = BinOrderProduct.find(bin_order_product_id)
        available_quantity = @bin_order_product.available_quantity
        if available_quantity.to_i <  required_quantity
          flash[:error] = 'REQUIRED QUANTITY EXCEEDS AVAILABLE QUANTITY'
          redirect_to :controller => 'rmt_processing/bin_order_product', :action => 'set_required_quantity', :id => bin_order_product_id and return
        end
      @bin_order_product.update_attribute(:required_quantity,"#{required_quantity}")
               @bin_order_id = @bin_order_product['bin_order_id']
               flash[:notice] = 'record saved'
                render :inline => %{
                          <script>
                           window.opener.frames[1].frames[0].location.reload(true);
                           window.opener.frames[1].location.reload(true);
                            window.close();
                        </script>} and return
        end
     end
    end
 end

  
def search_bin_order_products_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_bin_order_product_search_form
end

def render_bin_order_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  bin_order_products'"%> 

		<%= build_bin_order_product_search_form(nil,'submit_bin_order_products_search','submit_bin_order_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_bin_order_products_search
	@bin_order_products = dynamic_search(params[:bin_order_product] ,'bin_order_products','BinOrderProduct')
	if @bin_order_products.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_bin_order_product_search_form
		else
			render_list_bin_order_products
	end
end

 
def delete_bin_order_product
 begin
   ActiveRecord::Base.transaction do
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:bin_order_products_page] = params['page']
		render_list_bin_order_products
		return
	end
	id = params[:id]

	if id && bin_order_product = BinOrderProduct.find(id)
       @bin_order_id = bin_order_product.bin_order_id
      bin_order_id = bin_order_product.bin_order_id
      bin_order_loads =BinOrderLoad.find_all_by_bin_order_id(bin_order_id)
      if !bin_order_loads.empty?
        for bin_order_load in bin_order_loads
          load_details = BinOrderLoadDetail.find_all_by_bin_order_load_id(bin_order_load.id)
          if !load_details.empty?
            for load_detail in load_details
              load_d = BinOrderLoadDetail.find_by_bin_order_product_id(bin_order_product.id)
              if load_d != nil
                flash[:error] = "order product cannot be deleted it is referenced by load details"
                 redirect_to :controller => 'rmt_processing/bin_order_product', :action => 'list_bin_order_products', :id => @bin_order_id  and return
              end
            end

          end
        end

      end

		bin_order_product.destroy
				 render :inline => %{
                          <script>
                                parent.location.href = '/rmt_processing/bin_order/edit_bin_order/<%= @bin_order_id.to_s%>';
                        </script>}
    end
    end
 end
rescue #handle_error('record could not be deleted')
  raise $!
end
 
def new_bin_order_product
	return if authorise_for_web(program_name?,'create')== false
		render_new_bin_order_product
end
 
def create_bin_order_product
 begin
   ActiveRecord::Base.transaction do
	 @bin_order_product = BinOrderProduct.new(params[:bin_order_product])
	 if @bin_order_product.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_bin_order_product
	 end

   end
   rescue
	 raise $!
end
end

def render_new_bin_order_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new bin_order_product'"%> 

		<%= build_bin_order_product_form(@bin_order_product,'create_bin_order_product','create_bin_order_product',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_bin_order_product
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @bin_order_product = BinOrderProduct.find(id)
		render_edit_bin_order_product

	 end
end


def render_edit_bin_order_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit bin_order_product'"%> 

		<%= build_bin_order_product_form(@bin_order_product,'update_bin_order_product','update_bin_order_product',true)%>

		}, :layout => 'content'
end
 
def update_bin_order_product
 begin
     ActiveRecord::Base.transaction do
	 id = params[:bin_order_product][:id]
	 if id && @bin_order_product = BinOrderProduct.find(id)
		 if @bin_order_product.update_attributes(params[:bin_order_product])
			@bin_order_products = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_bin_order_products
	 else
			 render_edit_bin_order_product

		 end
     end
     end
rescue
	 raise $!
end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: rmt_product_id
#	---------------------------------------------------------------------------------
 

end
