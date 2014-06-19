class  Production::DowntimeDivisionController < ApplicationController
 
def program_name?
	"downtime_division"
end

def bypass_generic_security?
	true
end
def list_downtime_divisions
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:downtime_divisions_page] = params['page']

		 render_list_downtime_divisions

		 return 
	else
		session[:downtime_divisions_page] = nil
	end

	list_query = "@downtime_division_pages = Paginator.new self, DowntimeDivision.count, @@page_size,@current_page
	 @downtime_divisions = DowntimeDivision.find(:all,
				 :limit => @downtime_division_pages.items_per_page,
				 :offset => @downtime_division_pages.current.offset)"
	session[:query] = list_query
	render_list_downtime_divisions
end


def render_list_downtime_divisions
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:downtime_divisions_page] if session[:downtime_divisions_page]
	@current_page = params['page'] if params['page']
	@downtime_divisions =  eval(session[:query]) if !@downtime_divisions
	render :inline => %{
      <% grid            = build_downtime_division_grid(@downtime_divisions,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all downtime_divisions' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@downtime_division_pages) if @downtime_division_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_downtime_divisions_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_downtime_division_search_form
end

def render_downtime_division_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  downtime_divisions'"%> 

		<%= build_downtime_division_search_form(nil,'submit_downtime_divisions_search','submit_downtime_divisions_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_downtime_divisions_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_downtime_division_search_form(true)
end

def render_downtime_division_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  downtime_divisions'"%> 

		<%= build_downtime_division_search_form(nil,'submit_downtime_divisions_search','submit_downtime_divisions_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_downtime_divisions_search
	if params['page']
		session[:downtime_divisions_page] =params['page']
	else
		session[:downtime_divisions_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @downtime_divisions = dynamic_search(params[:downtime_division] ,'downtime_divisions','DowntimeDivision')
	else
		@downtime_divisions = eval(session[:query])
	end
	if @downtime_divisions.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_downtime_division_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_downtime_divisions
		end

	else

		render_list_downtime_divisions
	end
end

 
def delete_downtime_division
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:downtime_divisions_page] = params['page']
		render_list_downtime_divisions
		return
	end
	id = params[:id]
	if id && downtime_division = DowntimeDivision.find(id)
		downtime_division.destroy
		session[:alert] = " Record deleted."
		render_list_downtime_divisions
	end
end
 
def new_downtime_division
	return if authorise_for_web(program_name?,'create')== false
		render_new_downtime_division
end
 
def create_downtime_division
	 @downtime_division = DowntimeDivision.new(params[:downtime_division])
	 if @downtime_division.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_downtime_division
	 end
end

def render_new_downtime_division
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new downtime_division'"%> 

		<%= build_downtime_division_form(@downtime_division,'create_downtime_division','create_downtime_division',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_downtime_division
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @downtime_division = DowntimeDivision.find(id)
		render_edit_downtime_division

	 end
end


def render_edit_downtime_division
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit downtime_division'"%> 

		<%= build_downtime_division_form(@downtime_division,'update_downtime_division','update_downtime_division',true)%>

		}, :layout => 'content'
end
 
def update_downtime_division
	if params[:page]
		session[:downtime_divisions_page] = params['page']
		render_list_downtime_divisions
		return
	end

		@current_page = session[:downtime_divisions_page]
	 id = params[:downtime_division][:id]
	 if id && @downtime_division = DowntimeDivision.find(id)
		 if @downtime_division.update_attributes(params[:downtime_division])
			@downtime_divisions = eval(session[:query])
			render_list_downtime_divisions
	 else
			 render_edit_downtime_division

		 end
	 end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: downtime_category_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(downtime_divisions)
#	-----------------------------------------------------------------------------------------------------------
def downtime_division_downtime_category_code_search_combo_changed
	downtime_category_code = get_selected_combo_value(params)
	session[:downtime_division_search_form][:downtime_category_code_combo_selection] = downtime_category_code
	@downtime_division_codes = DowntimeDivision.find_by_sql("Select distinct downtime_division_code from downtime_divisions where downtime_category_code = '#{downtime_category_code}'").map{|g|[g.downtime_division_code]}
	@downtime_division_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('downtime_division','downtime_division_code',@downtime_division_codes)%>

		}

end



end
