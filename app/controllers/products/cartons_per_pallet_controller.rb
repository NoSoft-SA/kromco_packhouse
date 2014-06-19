class  Products::CartonsPerPalletController < ApplicationController
 
def program_name?
	"cartons_per_pallet"
end

def bypass_generic_security?
	true
end
def list_cartons_per_pallets
	return if authorise_for_web('cartons_per_pallet','read') == false 

 	if params[:page]!= nil 

 		session[:cartons_per_pallets_page] = params['page']

		 render_list_cartons_per_pallets

		 return 
	else
		session[:cartons_per_pallets_page] = nil
	end

	list_query = "@cartons_per_pallet_pages = Paginator.new self, CartonsPerPallet.count, @@page_size,@current_page
	 @cartons_per_pallets = CartonsPerPallet.find(:all,
				 :limit => @cartons_per_pallet_pages.items_per_page,
				 :offset => @cartons_per_pallet_pages.current.offset)"
	session[:query] = list_query
	render_list_cartons_per_pallets
end


def render_list_cartons_per_pallets
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:cartons_per_pallets_page] if session[:cartons_per_pallets_page]
	@current_page = params['page'] if params['page']
	@cartons_per_pallets =  eval(session[:query]) if !@cartons_per_pallets
	render :inline => %{
      <% grid            = build_cartons_per_pallet_grid(@cartons_per_pallets,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all cartons_per_pallets' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@cartons_per_pallet_pages) if @cartons_per_pallet_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_cartons_per_pallets_flat
	return if authorise_for_web('cartons_per_pallet','read')== false
	@is_flat_search = true 
	render_cartons_per_pallet_search_form
end

def render_cartons_per_pallet_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  cartons_per_pallets'"%> 

		<%= build_cartons_per_pallet_search_form(nil,'submit_cartons_per_pallets_search','submit_cartons_per_pallets_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_cartons_per_pallets_hierarchy
	return if authorise_for_web('cartons_per_pallet','read')== false
 
	@is_flat_search = false 
	render_cartons_per_pallet_search_form(true)
end

def render_cartons_per_pallet_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  cartons_per_pallets'"%> 

		<%= build_cartons_per_pallet_search_form(nil,'submit_cartons_per_pallets_search','submit_cartons_per_pallets_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_cartons_per_pallets_search
	if params['page']
		session[:cartons_per_pallets_page] =params['page']
	else
		session[:cartons_per_pallets_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @cartons_per_pallets = dynamic_search(params[:cartons_per_pallet] ,'cartons_per_pallets','CartonsPerPallet')
	else
		@cartons_per_pallets = eval(session[:query])
	end
	if @cartons_per_pallets.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_cartons_per_pallet_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_cartons_per_pallets
		end

	else

		render_list_cartons_per_pallets
	end
end

 
def delete_cartons_per_pallet
	return if authorise_for_web('cartons_per_pallet','delete')== false
	if params[:page]
		session[:cartons_per_pallets_page] = params['page']
		render_list_cartons_per_pallets
		return
	end
	id = params[:id]
	if id && cartons_per_pallet = CartonsPerPallet.find(id)
		cartons_per_pallet.destroy
		session[:alert] = " Record deleted."
		render_list_cartons_per_pallets
	end
end
 
def new_cartons_per_pallet
	return if authorise_for_web('cartons_per_pallet','create')== false
		render_new_cartons_per_pallet
end
 
def create_cartons_per_pallet
	 @cartons_per_pallet = CartonsPerPallet.new(params[:cartons_per_pallet])
	 if @cartons_per_pallet.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_cartons_per_pallet
	 end
end

def render_new_cartons_per_pallet
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new cartons_per_pallet'"%> 

		<%= build_cartons_per_pallet_form(@cartons_per_pallet,'create_cartons_per_pallet','create_cartons_per_pallet',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_cartons_per_pallet
	return if authorise_for_web('cartons_per_pallet','edit')==false 
	 id = params[:id]
	 if id && @cartons_per_pallet = CartonsPerPallet.find(id)
		render_edit_cartons_per_pallet

	 end
end


def render_edit_cartons_per_pallet
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit cartons_per_pallet'"%> 

		<%= build_cartons_per_pallet_form(@cartons_per_pallet,'update_cartons_per_pallet','update_cartons_per_pallet',true)%>

		}, :layout => 'content'
end
 
def update_cartons_per_pallet
	if params[:page]
		session[:cartons_per_pallets_page] = params['page']
		render_list_cartons_per_pallets
		return
	end

		@current_page = session[:cartons_per_pallets_page]
	 id = params[:cartons_per_pallet][:id]
	 if id && @cartons_per_pallet = CartonsPerPallet.find(id)
		 if @cartons_per_pallet.update_attributes(params[:cartons_per_pallet])
			@cartons_per_pallets = eval(session[:query])
			render_list_cartons_per_pallets
	 else
			 render_edit_cartons_per_pallet

		 end
	 end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: pallet_format_product_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: carton_pack_product_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(cartons_per_pallets)
#	-----------------------------------------------------------------------------------------------------------
def cartons_per_pallet_pallet_format_product_code_search_combo_changed
	pallet_format_product_code = get_selected_combo_value(params)
	session[:cartons_per_pallet_search_form][:pallet_format_product_code_combo_selection] = pallet_format_product_code
	@carton_pack_product_codes = CartonsPerPallet.find_by_sql("Select distinct carton_pack_product_code from cartons_per_pallets where pallet_format_product_code = '#{pallet_format_product_code}'").map{|g|[g.carton_pack_product_code]}
	@carton_pack_product_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('cartons_per_pallet','carton_pack_product_code',@carton_pack_product_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_cartons_per_pallet_carton_pack_product_code'/>
		<%= observe_field('cartons_per_pallet_carton_pack_product_code',:update => 'cartons_per_pallet_cell',:url => {:action => session[:cartons_per_pallet_search_form][:carton_pack_product_code_observer][:remote_method]},:loading => "show_element('img_cartons_per_pallet_carton_pack_product_code');",:complete => session[:cartons_per_pallet_search_form][:carton_pack_product_code_observer][:on_completed_js])%>
		}

end


def cartons_per_pallet_carton_pack_product_code_search_combo_changed
	carton_pack_product_code = get_selected_combo_value(params)
	session[:cartons_per_pallet_search_form][:carton_pack_product_code_combo_selection] = carton_pack_product_code
	pallet_format_product_code = 	session[:cartons_per_pallet_search_form][:pallet_format_product_code_combo_selection]
	@cartons_per_pallets = CartonsPerPallet.find_by_sql("Select distinct cartons_per_pallet from cartons_per_pallets where carton_pack_product_code = '#{carton_pack_product_code}' and pallet_format_product_code = '#{pallet_format_product_code}'").map{|g|[g.cartons_per_pallet]}
	@cartons_per_pallets.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('cartons_per_pallet','cartons_per_pallet',@cartons_per_pallets)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_cartons_per_pallet_cartons_per_pallet'/>
		<%= observe_field('cartons_per_pallet_cartons_per_pallet',:update => 'layers_per_pallet_cell',:url => {:action => session[:cartons_per_pallet_search_form][:cartons_per_pallet_observer][:remote_method]},:loading => "show_element('img_cartons_per_pallet_cartons_per_pallet');",:complete => session[:cartons_per_pallet_search_form][:cartons_per_pallet_observer][:on_completed_js])%>
		}

end


def cartons_per_pallet_cartons_per_pallet_search_combo_changed
	cartons_per_pallet = get_selected_combo_value(params)
	cartons_per_pallet = -1 if cartons_per_pallet == ""
	session[:cartons_per_pallet_search_form][:cartons_per_pallet_combo_selection] = cartons_per_pallet
	carton_pack_product_code = 	session[:cartons_per_pallet_search_form][:carton_pack_product_code_combo_selection]
	pallet_format_product_code = 	session[:cartons_per_pallet_search_form][:pallet_format_product_code_combo_selection]
	@layers_per_pallets = CartonsPerPallet.find_by_sql("Select distinct layers_per_pallet from cartons_per_pallets where cartons_per_pallet = '#{cartons_per_pallet}' and carton_pack_product_code = '#{carton_pack_product_code}' and pallet_format_product_code = '#{pallet_format_product_code}'").map{|g|[g.layers_per_pallet]}
	@layers_per_pallets.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('cartons_per_pallet','layers_per_pallet',@layers_per_pallets)%>

		}

end



end
