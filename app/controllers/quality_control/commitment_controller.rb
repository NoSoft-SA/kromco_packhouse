class  QualityControl::CommitmentController < ApplicationController
 
def program_name?
	"grower_commitment"
end

def bypass_generic_security?
	true
end
def list_commitments
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:commitments_page] = params['page']

		 render_list_commitments

		 return 
	else
		session[:commitments_page] = nil
	end

	list_query = "@commitment_pages = Paginator.new self, Commitment.count, @@page_size,@current_page
	 @commitments = Commitment.find(:all,
				 :limit => @commitment_pages.items_per_page,
				 :offset => @commitment_pages.current.offset)"
	session[:query] = list_query
	render_list_commitments
end


def render_list_commitments
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:commitments_page] if session[:commitments_page]
	@current_page = params['page'] if params['page']
	@commitments =  eval(session[:query]) if !@commitments
	render :inline => %{
      <% grid            = build_commitment_grid(@commitments,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all commitments' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@commitment_pages) if @commitment_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_commitments_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_commitment_search_form
end

def render_commitment_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  commitments'"%> 

		<%= build_commitment_search_form(nil,'submit_commitments_search','submit_commitments_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_commitments_search
	if params['page']
		session[:commitments_page] =params['page']
	else
		session[:commitments_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @commitments = dynamic_search(params[:commitment] ,'commitments','Commitment')
	else
		@commitments = eval(session[:query])
	end
	if @commitments.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_commitment_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_commitments
		end

	else

		render_list_commitments
	end
end

 
def delete_commitment
 begin
	return if authorise_for_web(program_name?,'grower_commitment_delete')== false
	if params[:page]
		session[:commitments_page] = params['page']
		render_list_commitments
		return
	end
	id = params[:id]
	if id && commitment = Commitment.find(id)
		commitment.destroy
		session[:alert] = " Record deleted."
		render_list_commitments
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_commitment
	return if authorise_for_web(program_name?,'grower_commitment_create')== false
		render_new_commitment
end
 
def create_commitment
 begin
	 @commitment = Commitment.new(params[:commitment])
	 if @commitment.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_commitment
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_commitment
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new commitment'"%> 

		<%= build_commitment_form(@commitment,'create_commitment','create_commitment',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_commitment
	return if authorise_for_web(program_name?,'grower_commitment_edit')==false
	 id = params[:id]
	 if id && @commitment = Commitment.find(id)
		render_edit_commitment

	 end
end


def render_edit_commitment
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit commitment'"%> 

		<%= build_commitment_form(@commitment,'update_commitment','update_commitment',true)%>

		}, :layout => 'content'
end
 
def update_commitment
 begin

	if params[:page]
		session[:commitments_page] = params['page']
		render_list_commitments
		return
	end

		@current_page = session[:commitments_page]
	 id = params[:commitment][:id]
	 if id && @commitment = Commitment.find(id)
		 if @commitment.update_attributes(params[:commitment])
			@commitments = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_commitments
	 else
			 render_edit_commitment

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
