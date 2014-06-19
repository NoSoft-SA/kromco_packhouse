class  QualityControl::MrlResultController < ApplicationController
 
def program_name?
	"mrl_result"
end

def bypass_generic_security?
	true
end
def list_mrl_results
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:mrl_results_page] = params['page']

		 render_list_mrl_results

		 return 
	else
		session[:mrl_results_page] = nil
	end

	list_query = "@mrl_result_pages = Paginator.new self, MrlResult.count, @@page_size,@current_page
	 @mrl_results = MrlResult.find(:all,
				 :limit => @mrl_result_pages.items_per_page,
				 :offset => @mrl_result_pages.current.offset)"
	session[:query] = list_query
	render_list_mrl_results
end


def render_list_mrl_results
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:mrl_results_page] if session[:mrl_results_page]
	@current_page = params['page'] if params['page']
	@mrl_results =  eval(session[:query]) if !@mrl_results
	render :inline => %{
      <% grid            = build_mrl_result_grid(@mrl_results,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all mrl_results' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@mrl_result_pages) if @mrl_result_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_mrl_results_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_mrl_result_search_form
end

def render_mrl_result_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  mrl_results'"%> 

		<%= build_mrl_result_search_form(nil,'submit_mrl_results_search','submit_mrl_results_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_mrl_results_search
	if params['page']
		session[:mrl_results_page] =params['page']
	else
		session[:mrl_results_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @mrl_results = dynamic_search(params[:mrl_result] ,'mrl_results','MrlResult')
	else
		@mrl_results = eval(session[:query])
	end
	if @mrl_results.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_mrl_result_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_mrl_results
		end

	else

		render_list_mrl_results
	end
end

 
def delete_mrl_result
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:mrl_results_page] = params['page']
		render_list_mrl_results
		return
	end
	id = params[:id]
	if id && mrl_result = MrlResult.find(id)
		mrl_result.destroy
		session[:alert] = " Record deleted."
		render_list_mrl_results
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_mrl_result
	return if authorise_for_web(program_name?,'create')== false
		render_new_mrl_result
end
 
def create_mrl_result
 begin
	 @mrl_result = MrlResult.new(params[:mrl_result])
	 if @mrl_result.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_mrl_result
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_mrl_result
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new mrl_result'"%> 

		<%= build_mrl_result_form(@mrl_result,'create_mrl_result','create_mrl_result',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_mrl_result
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @mrl_result = MrlResult.find(id)
		render_edit_mrl_result

	 end
end


def render_edit_mrl_result
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit mrl_result'"%> 

		<%= build_mrl_result_form(@mrl_result,'update_mrl_result','update_mrl_result',true)%>

		}, :layout => 'content'
end
 
def update_mrl_result
 begin

	if params[:page]
		session[:mrl_results_page] = params['page']
		render_list_mrl_results
		return
	end

		@current_page = session[:mrl_results_page]
	 id = params[:mrl_result][:id]
	 if id && @mrl_result = MrlResult.find(id)
		 if @mrl_result.update_attributes(params[:mrl_result])
			@mrl_results = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_mrl_results
	 else
			 render_edit_mrl_result

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
