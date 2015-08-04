class  Production::ClothingTransactionTypeController < ApplicationController
 
def program_name?
	"clothing_transaction_type"
end

def bypass_generic_security?
	true
end
def list_clothing_transaction_types
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:clothing_transaction_types_page] = params['page']

		 render_list_clothing_transaction_types

		 return 
	else
		session[:clothing_transaction_types_page] = nil
	end

	list_query = "@clothing_transaction_type_pages = Paginator.new self, ClothingTransactionType.count, @@page_size,@current_page
	 @clothing_transaction_types = ClothingTransactionType.find(:all,
				 :limit => @clothing_transaction_type_pages.items_per_page,
				 :offset => @clothing_transaction_type_pages.current.offset)"
	session[:query] = list_query
	render_list_clothing_transaction_types
end


def render_list_clothing_transaction_types
	@pagination_server = "list_clothing_transaction_types"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:clothing_transaction_types_page]
	@current_page = params['page']||= session[:clothing_transaction_types_page]
	@clothing_transaction_types =  eval(session[:query]) if !@clothing_transaction_types
	render :inline => %{
		<% grid = build_clothing_transaction_type_grid(@clothing_transaction_types,@can_edit,@can_delete)%>
		<% grid.caption = 'list of all clothing_transaction_types'%>
		<% @header_content = grid.build_grid_data %>

		<% @pagination = pagination_links(@clothing_transaction_type_pages) if @clothing_transaction_type_pages != nil %>
		<%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_clothing_transaction_types_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_clothing_transaction_type_search_form
end

def render_clothing_transaction_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  clothing_transaction_types'"%> 

		<%= build_clothing_transaction_type_search_form(nil,'submit_clothing_transaction_types_search','submit_clothing_transaction_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_clothing_transaction_types_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_clothing_transaction_type_search_form(true)
end

 
def submit_clothing_transaction_types_search
	@clothing_transaction_types = dynamic_search(params[:clothing_transaction_type] ,'clothing_transaction_types','ClothingTransactionType')
	if @clothing_transaction_types.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_clothing_transaction_type_search_form
		else
			render_list_clothing_transaction_types
	end
end

 
def delete_clothing_transaction_type
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:clothing_transaction_types_page] = params['page']
		render_list_clothing_transaction_types
		return
	end
	id = params[:id]
	if id && clothing_transaction_type = ClothingTransactionType.find(id)
		clothing_transaction_type.destroy
		session[:alert] = ' Record deleted.'
		render_list_clothing_transaction_types
	end
	rescue
		handle_error('record could not be deleted')
end
end
 
def new_clothing_transaction_type
	return if authorise_for_web(program_name?,'create')== false
		render_new_clothing_transaction_type
end
 
def create_clothing_transaction_type
 begin
	 @clothing_transaction_type = ClothingTransactionType.new(params[:clothing_transaction_type])
	 if @clothing_transaction_type.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_clothing_transaction_type
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_clothing_transaction_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new clothing_transaction_type'"%> 

		<%= build_clothing_transaction_type_form(@clothing_transaction_type,'create_clothing_transaction_type','create_clothing_transaction_type',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_clothing_transaction_type
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @clothing_transaction_type = ClothingTransactionType.find(id)
		render_edit_clothing_transaction_type

	 end
end


def render_edit_clothing_transaction_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit clothing_transaction_type'"%> 

		<%= build_clothing_transaction_type_form(@clothing_transaction_type,'update_clothing_transaction_type','update_clothing_transaction_type',true)%>

		}, :layout => 'content'
end
 
def update_clothing_transaction_type
 begin

	 id = params[:clothing_transaction_type][:id]
	 if id && @clothing_transaction_type = ClothingTransactionType.find(id)
		 if @clothing_transaction_type.update_attributes(params[:clothing_transaction_type])
			@clothing_transaction_types = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_clothing_transaction_types
	 else
			 render_edit_clothing_transaction_type

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(clothing_transaction_types)
#	-----------------------------------------------------------------------------------------------------------

end
