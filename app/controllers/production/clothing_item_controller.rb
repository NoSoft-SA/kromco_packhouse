class  Production::ClothingItemController < ApplicationController
 
def program_name?
	"clothing_item"
end

def bypass_generic_security?
	true
end
def list_clothing_items
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:clothing_items_page] = params['page']

		 render_list_ClothingItems

		 return 
	else
		session[:clothing_items_page] = nil
	end

	list_query = "@clothing_item_pages = Paginator.new self, ClothingItem.count, @@page_size,@current_page
	 @ClothingItems = ClothingItem.find(:all,
				 :limit => @clothing_item_pages.items_per_page,
				 :offset => @clothing_item_pages.current.offset)"
	session[:query] = list_query
	render_list_clothing_items
end


def render_list_clothing_items
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:clothing_items_page] if session[:clothing_items_page]
	@current_page = params['page'] if params['page']
	@clothing_items =  eval(session[:query]) if !@clothing_items
    @use_jq_grid = true
    if @use_jq_grid
	render :inline => %{
      <% grid            = build_clothing_item_grid(@clothing_items,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all clothing_items' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@clothing_item_pages) if @clothing_item_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    else
	render :inline => %{
		<% @content_header_caption = "'list of all clothing_items'"%>
		<% grid = build_clothing_item_grid(@clothing_items,@can_edit,@can_delete)%>
		<% @header_content = grid.build_grid_style %>
		<% @header_content += grid.build_grid_data %>

		<% @pagination = pagination_links(@clothing_item_pages) if @clothing_item_pages != nil %>
		<script>
		<%= grid.render_grid %>
		</script>
	},:layout => 'content'
    end
end
 
def search_clothing_items_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_clothing_item_search_form
end

def render_clothing_item_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  clothing_items'"%> 

		<%= build_clothing_item_search_form(nil,'submit_clothing_items_search','submit_clothing_items_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_clothing_items_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_clothing_item_search_form(true)
end

 
def submit_clothing_items_search
	@clothing_items = dynamic_search(params[:clothing_item] ,'clothing_items','ClothingItem')
	if @clothing_items.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_clothing_item_search_form
		else
			render_list_clothing_items
	end
end

 
def delete_clothing_item
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:clothing_items_page] = params['page']
		render_list_clothing_items
		return
	end
	id = params[:id]
	if id && clothing_item = ClothingItem.find(id)
		clothing_item.destroy
		session[:alert] = ' Record deleted.'
		render_list_clothing_items
	end
	rescue
		handle_error('record could not be deleted')
end
end
 
def new_clothing_item
	return if authorise_for_web(program_name?,'create')== false
		render_new_clothing_item
end
 
def create_clothing_item
 begin
	 @clothing_item = ClothingItem.new(params[:clothing_item])
	 if @clothing_item.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_clothing_item
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_clothing_item
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new clothing_item'"%> 

		<%= build_clothing_item_form(@clothing_item,'create_clothing_item','create_clothing_item',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_clothing_item
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @clothing_item = ClothingItem.find(id)
		render_edit_clothing_item

	 end
end


def render_edit_clothing_item
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit clothing_item'"%> 

		<%= build_clothing_item_form(@clothing_item,'update_clothing_item','update_clothing_item',true)%>

		}, :layout => 'content'
end
 
def update_clothing_item
 begin

	 id = params[:clothing_item][:id]
	 if id && @clothing_item = ClothingItem.find(id)
		 if @clothing_item.update_attributes(params[:clothing_item])
			@clothing_items = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_clothing_items
	 else
			 render_edit_clothing_item

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: clothing_transaction_type_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: clothable_person_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: clothing_type_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(clothing_items)
#	-----------------------------------------------------------------------------------------------------------

end
