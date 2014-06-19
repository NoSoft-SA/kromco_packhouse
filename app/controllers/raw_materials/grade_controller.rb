class  RawMaterials::GradeController < ApplicationController
 
def program_name?
	"grade"
end

def bypass_generic_security?
	true
end
def list_grades
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:grades_page] = params['page']

		 render_list_grades

		 return 
	else
		session[:grades_page] = nil
	end

	list_query = "@grade_pages = Paginator.new self, Grade.count, @@page_size,@current_page
	 @grades = Grade.find(:all,
				 :limit => @grade_pages.items_per_page,
				 :offset => @grade_pages.current.offset)"
	session[:query] = list_query
	render_list_grades
end


def render_list_grades
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:grades_page] if session[:grades_page]
	@current_page = params['page'] if params['page']
	@grades =  eval(session[:query]) if !@grades
	render :inline => %{
      <% grid            = build_grade_grid(@grades,@can_edit,@can_delete) %>
      <% grid.caption    = 'List of all grades' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@grade_pages) if @grade_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_grades_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_grade_search_form
end

def render_grade_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  grades'"%> 

		<%= build_grade_search_form(nil,'submit_grades_search','submit_grades_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_grades_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_grade_search_form(true)
end

def render_grade_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  grades'"%> 

		<%= build_grade_search_form(nil,'submit_grades_search','submit_grades_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_grades_search
	if params['page']
		session[:grades_page] =params['page']
	else
		session[:grades_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @grades = dynamic_search(params[:grade] ,'grades','Grade')
	else
		@grades = eval(session[:query])
	end
	if @grades.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_grade_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_grades
		end

	else

		render_list_grades
	end
end

 
def delete_grade
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:grades_page] = params['page']
		render_list_grades
		return
	end
	id = params[:id]
	if id && grade = Grade.find(id)
		grade.destroy
		session[:alert] = " Record deleted."
		render_list_grades
	end
  rescue
   handle_error("grade could not be deleted")
  end
end
 
def new_grade
	return if authorise_for_web(program_name?,'create')== false
		render_new_grade
end
 
def create_grade
  begin
	 @grade = Grade.new(params[:grade])
	 if @grade.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_grade
	 end
  rescue
   handle_error("grade could not be created")
  end
end

def render_new_grade
@grade=Grade.new
@grade.has_recooling_fees = true
@grade.has_carton_manufacturing_fees = true
@grade.has_handling_dispatch_fees boolean = true
	render :inline => %{
		<% @content_header_caption = "'create new grade'"%> 

		<%= build_grade_form(@grade,'create_grade','create_grade',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_grade
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @grade = Grade.find(id)
		render_edit_grade

	 end
end


def render_edit_grade
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit grade'"%> 

		<%= build_grade_form(@grade,'update_grade','update_grade',true)%>

		}, :layout => 'content'
end
 
def update_grade
  begin
	if params[:page]
		session[:grades_page] = params['page']
		render_list_grades
		return
	end

		@current_page = session[:grades_page]
	 id = params[:grade][:id]
	 if id && @grade = Grade.find(id)
		 if @grade.update_attributes(params[:grade])
			@grades = eval(session[:query])
			render_list_grades
	 else
			 render_edit_grade

		 end
	 end
  rescue
   handle_error("grade could not be updated")
  end
 end
 
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(grades)
#	-----------------------------------------------------------------------------------------------------------

end
