class  Production::DowntimeTypeController < ApplicationController
 
def program_name?
	"downtime_type"
end

def bypass_generic_security?
	true
end
def list_downtime_types
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:downtime_types_page] = params['page']

		 render_list_downtime_types

		 return 
	else
		session[:downtime_types_page] = nil
	end

	list_query = "@downtime_type_pages = Paginator.new self, DowntimeType.count, @@page_size,@current_page
	 @downtime_types = DowntimeType.find(:all,
				 :limit => @downtime_type_pages.items_per_page,
				 :offset => @downtime_type_pages.current.offset)"
	session[:query] = list_query
	render_list_downtime_types
end


def render_list_downtime_types
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:downtime_types_page] if session[:downtime_types_page]
	@current_page = params['page'] if params['page']
	@downtime_types =  eval(session[:query]) if !@downtime_types
	render :inline => %{
      <% grid            = build_downtime_type_grid(@downtime_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all downtime_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@downtime_type_pages) if @downtime_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_downtime_types_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_downtime_type_search_form
end

def render_downtime_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  downtime_types'"%> 

		<%= build_downtime_type_search_form(nil,'submit_downtime_types_search','submit_downtime_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_downtime_types_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_downtime_type_search_form(true)
end

def render_downtime_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  downtime_types'"%> 

		<%= build_downtime_type_search_form(nil,'submit_downtime_types_search','submit_downtime_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_downtime_types_search
	if params['page']
		session[:downtime_types_page] =params['page']
	else
		session[:downtime_types_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @downtime_types = dynamic_search(params[:downtime_type] ,'downtime_types','DowntimeType')
	else
		@downtime_types = eval(session[:query])
	end
	if @downtime_types.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_downtime_type_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_downtime_types
		end

	else

		render_list_downtime_types
	end
end

 
def delete_downtime_type
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:downtime_types_page] = params['page']
		render_list_downtime_types
		return
	end
	id = params[:id]
	if id && downtime_type = DowntimeType.find(id)
		downtime_type.destroy
		session[:alert] = " Record deleted."
		render_list_downtime_types
	end
end
 
def new_downtime_type
	return if authorise_for_web(program_name?,'create')== false
		render_new_downtime_type
end
 
def create_downtime_type
	 @downtime_type = DowntimeType.new(params[:downtime_type])
	 if @downtime_type.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_downtime_type
	 end
end

def render_new_downtime_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new downtime_type'"%> 

		<%= build_downtime_type_form(@downtime_type,'create_downtime_type','create_downtime_type',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_downtime_type
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @downtime_type = DowntimeType.find(id)
		render_edit_downtime_type

	 end
end


def render_edit_downtime_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit downtime_type'"%> 

		<%= build_downtime_type_form(@downtime_type,'update_downtime_type','update_downtime_type',true)%>

		}, :layout => 'content'
end
 
def update_downtime_type
	if params[:page]
		session[:downtime_types_page] = params['page']
		render_list_downtime_types
		return
	end

		@current_page = session[:downtime_types_page]
	 id = params[:downtime_type][:id]
	 if id && @downtime_type = DowntimeType.find(id)
		 if @downtime_type.update_attributes(params[:downtime_type])
			@downtime_types = eval(session[:query])
			render_list_downtime_types
	 else
			 render_edit_downtime_type

		 end
	 end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: downtime_division_id
#	---------------------------------------------------------------------------------
def downtime_type_downtime_category_code_changed
	downtime_category_code = get_selected_combo_value(params)
	session[:downtime_type_form][:downtime_category_code_combo_selection] = downtime_category_code
	@downtime_division_codes = DowntimeType.downtime_division_codes_for_downtime_category_code(downtime_category_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('downtime_type','downtime_division_code',@downtime_division_codes)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(downtime_types)
#	-----------------------------------------------------------------------------------------------------------
def downtime_type_downtime_category_code_search_combo_changed
	downtime_category_code = get_selected_combo_value(params)
	session[:downtime_type_search_form][:downtime_category_code_combo_selection] = downtime_category_code
	@downtime_division_codes = DowntimeType.find_by_sql("Select distinct downtime_division_code from downtime_types where downtime_category_code = '#{downtime_category_code}'").map{|g|[g.downtime_division_code]}
	@downtime_division_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('downtime_type','downtime_division_code',@downtime_division_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_downtime_type_downtime_division_code'/>
		<%= observe_field('downtime_type_downtime_division_code',:update => 'downtime_type_code_cell',:url => {:action => session[:downtime_type_search_form][:downtime_division_code_observer][:remote_method]},:loading => "show_element('img_downtime_type_downtime_division_code');",:complete => session[:downtime_type_search_form][:downtime_division_code_observer][:on_completed_js])%>
		}

end


def downtime_type_downtime_division_code_search_combo_changed
	downtime_division_code = get_selected_combo_value(params)
	session[:downtime_type_search_form][:downtime_division_code_combo_selection] = downtime_division_code
	downtime_category_code = 	session[:downtime_type_search_form][:downtime_category_code_combo_selection]
	@downtime_type_codes = DowntimeType.find_by_sql("Select distinct downtime_type_code from downtime_types where downtime_division_code = '#{downtime_division_code}' and downtime_category_code = '#{downtime_category_code}'").map{|g|[g.downtime_type_code]}
	@downtime_type_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('downtime_type','downtime_type_code',@downtime_type_codes)%>

		}

end



end
