class  QualityControl::SprayProgramResultController < ApplicationController
 
def program_name?
	"spray_program_result"
end

def bypass_generic_security?
	true
end
def list_spray_program_results
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:spray_program_results_page] = params['page']

		 render_list_spray_program_results

		 return 
	else
		session[:spray_program_results_page] = nil
	end

	list_query = "@spray_program_result_pages = Paginator.new self, SprayProgramResult.count, @@page_size,@current_page
	 @spray_program_results = SprayProgramResult.find(:all,
				 :limit => @spray_program_result_pages.items_per_page,
				 :offset => @spray_program_result_pages.current.offset)"
	session[:query] = list_query
	render_list_spray_program_results
end


def render_list_spray_program_results
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:spray_program_results_page] if session[:spray_program_results_page]
	@current_page = params['page'] if params['page']
	@spray_program_results =  eval(session[:query]) if !@spray_program_results
	render :inline => %{
      <% grid            = build_spray_program_result_grid(@spray_program_results,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all spray_program_results' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@spray_program_result_pages) if @spray_program_result_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_spray_program_results_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_spray_program_result_search_form
end

def render_spray_program_result_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  spray_program_results'"%> 

		<%= build_spray_program_result_search_form(nil,'submit_spray_program_results_search','submit_spray_program_results_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_spray_program_results_search
	if params['page']
		session[:spray_program_results_page] =params['page']
	else
		session[:spray_program_results_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @spray_program_results = dynamic_search(params[:spray_program_result] ,'spray_program_results','SprayProgramResult')
	else
		@spray_program_results = eval(session[:query])
	end
	if @spray_program_results.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_spray_program_result_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_spray_program_results
		end

	else

		render_list_spray_program_results
	end
end

 
def delete_spray_program_result
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:spray_program_results_page] = params['page']
		render_list_spray_program_results
		return
	end
	id = params[:id]
	if id && spray_program_result = SprayProgramResult.find(id)
		spray_program_result.destroy
		session[:alert] = " Record deleted."
		render_list_spray_program_results
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_spray_program_result
	return if authorise_for_web(program_name?,'create')== false
		render_new_spray_program_result
end
 
def create_spray_program_result
 begin
	 @spray_program_result = SprayProgramResult.new(params[:spray_program_result])
	 if @spray_program_result.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_spray_program_result
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_spray_program_result
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new spray_program_result'"%> 

		<%= build_spray_program_result_form(@spray_program_result,'create_spray_program_result','create_spray_program_result',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_spray_program_result
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @spray_program_result = SprayProgramResult.find(id)
		render_edit_spray_program_result

	 end
end


def render_edit_spray_program_result
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit spray_program_result'"%> 

		<%= build_spray_program_result_form(@spray_program_result,'update_spray_program_result','update_spray_program_result',true)%>

		}, :layout => 'content'
end
 
def update_spray_program_result
 begin

	if params[:page]
		session[:spray_program_results_page] = params['page']
		render_list_spray_program_results
		return
	end

		@current_page = session[:spray_program_results_page]
	 id = params[:spray_program_result][:id]
	 if id && @spray_program_result = SprayProgramResult.find(id)
		 if @spray_program_result.update_attributes(params[:spray_program_result])
			@spray_program_results = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_spray_program_results
	 else
			 render_edit_spray_program_result

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: rmt_variety_id
#	---------------------------------------------------------------------------------
def spray_program_result_commodity_code_changed
	commodity_code = get_selected_combo_value(params)
	session[:spray_program_result_form][:commodity_code_combo_selection] = commodity_code
	@rmt_variety_codes = SprayProgramResult.rmt_variety_codes_for_commodity_code(commodity_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('spray_program_result','rmt_variety_code',@rmt_variety_codes)%>

		}

end


 

end
