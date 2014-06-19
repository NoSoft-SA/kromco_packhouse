class  QualityControl::SprayProgramController < ApplicationController
 
def program_name?
	"spray_program"
end

def bypass_generic_security?
	true
end
def list_spray_programs
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:spray_programs_page] = params['page']

		 render_list_spray_programs

		 return 
	else
		session[:spray_programs_page] = nil
	end

	list_query = "@spray_program_pages = Paginator.new self, SprayProgram.count, @@page_size,@current_page
	 @spray_programs = SprayProgram.find(:all,
				 :limit => @spray_program_pages.items_per_page,
				 :offset => @spray_program_pages.current.offset)"
	session[:query] = list_query
	render_list_spray_programs
end


def render_list_spray_programs
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:spray_programs_page] if session[:spray_programs_page]
	@current_page = params['page'] if params['page']
	@spray_programs =  eval(session[:query]) if !@spray_programs
	render :inline => %{
      <% grid            = build_spray_program_grid(@spray_programs,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all spray_programs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@spray_program_pages) if @spray_program_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_spray_programs_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_spray_program_search_form
end

def render_spray_program_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  spray_programs'"%> 

		<%= build_spray_program_search_form(nil,'submit_spray_programs_search','submit_spray_programs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_spray_programs_search
	if params['page']
		session[:spray_programs_page] =params['page']
	else
		session[:spray_programs_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @spray_programs = dynamic_search(params[:spray_program] ,'spray_programs','SprayProgram')
	else
		@spray_programs = eval(session[:query])
	end
	if @spray_programs.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_spray_program_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_spray_programs
		end

	else

		render_list_spray_programs
	end
end

 
def delete_spray_program
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:spray_programs_page] = params['page']
		render_list_spray_programs
		return
	end
	id = params[:id]
	if id && spray_program = SprayProgram.find(id)
		spray_program.destroy
		session[:alert] = " Record deleted."
		render_list_spray_programs
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_spray_program
	return if authorise_for_web(program_name?,'create')== false
		render_new_spray_program
end
 
def create_spray_program
 begin
	 @spray_program = SprayProgram.new(params[:spray_program])
	 if @spray_program.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_spray_program
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_spray_program
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new spray_program'"%> 

		<%= build_spray_program_form(@spray_program,'create_spray_program','create_spray_program',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_spray_program
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @spray_program = SprayProgram.find(id)
		render_edit_spray_program

	 end
end


def render_edit_spray_program
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit spray_program'"%> 

		<%= build_spray_program_form(@spray_program,'update_spray_program','update_spray_program',true)%>

		}, :layout => 'content'
end
 
def update_spray_program
 begin

	if params[:page]
		session[:spray_programs_page] = params['page']
		render_list_spray_programs
		return
	end

		@current_page = session[:spray_programs_page]
	 id = params[:spray_program][:id]
	 if id && @spray_program = SprayProgram.find(id)
		 if @spray_program.update_attributes(params[:spray_program])
			@spray_programs = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_spray_programs
	 else
			 render_edit_spray_program

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
