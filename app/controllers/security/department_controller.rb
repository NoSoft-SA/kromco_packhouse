class  Security::DepartmentController < ApplicationController
 
def program_name?
	"department"
end

def bypass_generic_security?
  true
end

def list_departments
	return if authorise_for_web('department','read') == false 

	@department_pages = Paginator.new self, Department.count, 20,params['page']
	 @departments = Department.find(:all,
			 :limit => @department_pages.items_per_page,
			 :offset => @department_pages.current.offset)
	session[:departments] = @departments
	render_list_departments
end


def render_list_departments
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	render :inline => %{
      <% grid            = build_department_grid(@departments,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all departments' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@department_pages) if @department_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_departments_flat
	return if authorise_for_web('department','read')== false
	@is_flat_search = true 
	render_department_search_form
end

def render_department_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  departments'"%> 

		<%= build_department_search_form(nil,'submit_departments_search','submit_departments_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_departments_search
	session[:departments] = nil
	@department_pages = Paginator.new self, Department.count, 20,params['page']
	if params[:page]== nil
		 @departments = dynamic_search(params[:department] ,'departments','Department')
	else
		@departments = eval(session[:query])
	end
	if @departments.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_department_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_departments
		end
	else
		session[:departments] = @departments
		@departments = session[:departments]
		render_list_departments
	end
end

 
def delete_department
  return if authorise_for_web('department','delete')== false
  begin
	id = params[:id]
	if id && department = Department.find(id)
		department.destroy
		session[:alert] = " Record deleted."
#		 update in-memory recordset
		@departments = session[:departments]
		 delete_record(@departments,id)
		session[:departments] = @departments
		render_list_departments
	end
	rescue
	 handle_error("The Department could not be deleted")
	end
end
 
def new_department
	return if authorise_for_web('department','create')== false
		render_new_department
end
 
def create_department
	 @department = Department.new(params[:department])
	 if @department.save
	#update in-memory list- if it exists
		if session[:departments]
			 session[:departments].push @department
		end
		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_department
	 end
end

def render_new_department
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new department'"%> 

		<%= build_department_form(@department,'create_department','create_department',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_department
	return if authorise_for_web('department','edit')==false 
	 id = params[:id]
	 if id && @department = Department.find(id)
		render_edit_department

	 end
end


def render_edit_department
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit department'"%> 

		<%= build_department_form(@department,'update_department','update_department',true)%>

		}, :layout => 'content'
end
 
def update_department
	 id = params[:department][:id]
	 if id && @department = Department.find(id)
		 if @department.update_attributes(params[:department])
#		update the in-memory recordset- to save db call
			update_record(session[:departments],@department.attributes,id)
			@departments = session[:departments]
			render_list_departments
		else
			 render_edit_department

		 end
	 end
 end
 
 

end
