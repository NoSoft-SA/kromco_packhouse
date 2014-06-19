class  QualityControl::InspectionTypeController < ApplicationController
 
def program_name?
	"inspection_type"
end

def bypass_generic_security?
	true
end
def list_inspection_types
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:inspection_types_page] = params['page']

		 render_list_inspection_types

		 return 
	else
		session[:inspection_types_page] = nil
	end

	list_query = "@inspection_type_pages = Paginator.new self, InspectionType.count, @@page_size,@current_page
	 @inspection_types = InspectionType.find(:all,
				 :limit => @inspection_type_pages.items_per_page,
				 :offset => @inspection_type_pages.current.offset)"
	session[:query] = list_query
	render_list_inspection_types
end


def render_list_inspection_types
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:inspection_types_page] if session[:inspection_types_page]
	@current_page = params['page'] if params['page']
	@inspection_types =  eval(session[:query]) if !@inspection_types
	render :inline => %{
      <% grid            = build_inspection_type_grid(@inspection_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all inspection_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@inspection_type_pages) if @inspection_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_inspection_types_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_inspection_type_search_form
end

def render_inspection_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  inspection_types'"%> 

		<%= build_inspection_type_search_form(nil,'submit_inspection_types_search','submit_inspection_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_inspection_types_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_inspection_type_search_form(true)
end

def render_inspection_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  inspection_types'"%> 

		<%= build_inspection_type_search_form(nil,'submit_inspection_types_search','submit_inspection_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_inspection_types_search
	if params['page']
		session[:inspection_types_page] =params['page']
	else
		session[:inspection_types_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @inspection_types = dynamic_search(params[:inspection_type] ,'inspection_types','InspectionType')
	else
		@inspection_types = eval(session[:query])
	end
	if @inspection_types.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_inspection_type_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_inspection_types
		end

	else

		render_list_inspection_types
	end
end

 
def delete_inspection_type
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:inspection_types_page] = params['page']
		render_list_inspection_types
		return
	end
	id = params[:id]
	if id && inspection_type = InspectionType.find(id)
		inspection_type.destroy
		session[:alert] = " Record deleted."
		render_list_inspection_types
	end
end
 
def new_inspection_type
	return if authorise_for_web(program_name?,'create')== false
		render_new_inspection_type
end
 
def create_inspection_type
	 @inspection_type = InspectionType.new(params[:inspection_type])
	 if @inspection_type.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_inspection_type
	 end
end

def render_new_inspection_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new inspection_type'"%> 

		<%= build_inspection_type_form(@inspection_type,'create_inspection_type','create_inspection_type',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_inspection_type
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @inspection_type = InspectionType.find(id)
		render_edit_inspection_type

	 end
end


def render_edit_inspection_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit inspection_type'"%> 

		<%= build_inspection_type_form(@inspection_type,'update_inspection_type','update_inspection_type',true)%>

		}, :layout => 'content'
end
 
def update_inspection_type
	if params[:page]
		session[:inspection_types_page] = params['page']
		render_list_inspection_types
		return
	end

		@current_page = session[:inspection_types_page]
	 id = params[:inspection_type][:id]
	 if id && @inspection_type = InspectionType.find(id)
		 if @inspection_type.update_attributes(params[:inspection_type])
			@inspection_types = eval(session[:query])
			render_list_inspection_types
	 else
			 render_edit_inspection_type

		 end
	 end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: grade_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(inspection_types)
#	-----------------------------------------------------------------------------------------------------------
def inspection_type_inspection_type_code_search_combo_changed
	inspection_type_code = get_selected_combo_value(params)
	session[:inspection_type_search_form][:inspection_type_code_combo_selection] = inspection_type_code
	@grade_codes = InspectionType.find_by_sql("Select distinct grade_code from inspection_types where inspection_type_code = '#{inspection_type_code}'").map{|g|[g.grade_code]}
	@grade_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('inspection_type','grade_code',@grade_codes)%>

		}

end



end
