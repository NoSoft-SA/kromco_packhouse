class  Inventory::TransactionStatusController < ApplicationController
 
def program_name?
	"transaction_status"
end

def bypass_generic_security?
	true
end
def list_transaction_statuses
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:transaction_statuses_page] = params['page']

		 render_list_transaction_statuses

		 return 
	else
		session[:transaction_statuses_page] = nil
	end

	list_query = "@transaction_status_pages = Paginator.new self, TransactionStatus.count, @@page_size,@current_page
	 @transaction_statuses = TransactionStatus.find(:all,
				 :limit => @transaction_status_pages.items_per_page,
				 :offset => @transaction_status_pages.current.offset)"
	session[:query] = list_query
	render_list_transaction_statuses
end


def render_list_transaction_statuses
	@pagination_server = "list_transaction_statuses"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:transaction_statuses_page]
	@current_page = params['page']||= session[:transaction_statuses_page]
	@transaction_statuses =  eval(session[:query]) if !@transaction_statuses
	render :inline => %{
      <% grid            = build_transaction_status_grid(@transaction_statuses,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all transaction_statuses' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@transaction_status_pages) if @transaction_status_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_transaction_statuses_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_transaction_status_search_form
end

def render_transaction_status_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  transaction_statuses'"%> 

		<%= build_transaction_status_search_form(nil,'submit_transaction_statuses_search','submit_transaction_statuses_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_transaction_statuses_search
	@transaction_statuses = dynamic_search(params[:transaction_status] ,'transaction_statuses','TransactionStatus')
	if @transaction_statuses.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_transaction_status_search_form
		else
			render_list_transaction_statuses
	end
end

 
def delete_transaction_status
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:transaction_statuses_page] = params['page']
		render_list_transaction_statuses
		return
	end
	id = params[:id]
	if id && transaction_status = TransactionStatus.find(id)
		transaction_status.destroy
		session[:alert] = " Record deleted."
		render_list_transaction_statuses
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_transaction_status
	return if authorise_for_web(program_name?,'create')== false
		render_new_transaction_status
end
 
def create_transaction_status
 begin
	 @transaction_status = TransactionStatus.new(params[:transaction_status])
	 if @transaction_status.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_transaction_status
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_transaction_status
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new transaction_status'"%> 

		<%= build_transaction_status_form(@transaction_status,'create_transaction_status','create_transaction_status',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_transaction_status
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @transaction_status = TransactionStatus.find(id)
		render_edit_transaction_status

	 end
end


def render_edit_transaction_status
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit transaction_status'"%> 

		<%= build_transaction_status_form(@transaction_status,'update_transaction_status','update_transaction_status',true)%>

		}, :layout => 'content'
end
 
def update_transaction_status
 begin

	 id = params[:transaction_status][:id]
	 if id && @transaction_status = TransactionStatus.find(id)
		 if @transaction_status.update_attributes(params[:transaction_status])
			@transaction_statuses = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_transaction_statuses
	 else
			 render_edit_transaction_status

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
