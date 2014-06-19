class  Tools::ShiftController < ApplicationController
 
def program_name?
	"shift"
end

def bypass_generic_security?
	true
end
def list_shifts
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:shifts_page] = params['page']

		 render_list_shifts

		 return 
	else
		session[:shifts_page] = nil
	end

	list_query = "@shift_pages = Paginator.new self, Shift.count, 500,@current_page
	 @shifts = Shift.find(:all,
				 :limit => @shift_pages.items_per_page,
				 :offset => @shift_pages.current.offset)"
	session[:query] = list_query
	render_list_shifts
end


def render_list_shifts
	@pagination_server = "list_shifts"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:shifts_page]
	@current_page = params['page']||= session[:shifts_page]
	@shifts =  eval(session[:query]) if !@shifts
	render :inline => %{
      <% grid            = build_shift_grid(@shifts,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all shifts' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@shift_pages) if @shift_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end



#================ use it to search for date range ie very important code ======================
def search_shifts_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_shift_search_form
end

def render_shift_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  shifts'"%> 

		<%= build_shift_search_form(nil,'submit_shifts_search','submit_shifts_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_shifts_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_shift_search_form(true)
end

def render_shift_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  shifts'"%> 

		<%= build_shift_search_form(nil,'submit_shifts_search','submit_shifts_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_shifts_search
	@shifts = dynamic_search(params[:shift] ,'shifts','Shift',true,nil,nil, 3)
	if @shifts.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_shift_search_form
		else
			render_list_shifts
	end
end

 
def delete_shift
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:shifts_page] = params['page']
		render_list_shifts
		return
	end
	id = params[:id]
	if id && shift = Shift.find(id)
		shift.destroy
		session[:alert] = " Record deleted."
		render_list_shifts
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_shift
	return if authorise_for_web(program_name?,'create')== false
		render_new_shift
end
 
def create_shift
 begin
	 @shift = Shift.new(params[:shift])
	 if @shift.save

		
       @freeze_flash = true
       redirect_to_index("Created shift:<br> #{@shift.shift_code} ") 
	else
		@is_create_retry = true
		render_new_shift
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_shift
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new shift'"%> 

		<%= build_shift_form(@shift,'create_shift','create_shift',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_shift
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @shift = Shift.find(id)
		render_edit_shift
	 end
end


def render_edit_shift
	render :inline => %{
		<% @content_header_caption = "'edit shift'"%> 

		<%=  build_edit_form_2(@shift,'update_shift','update_shift',true)%>

		}, :layout => 'content'
end
 
def update_shift
 begin

	 id = params[:shift][:id]
	 if id && @shift = Shift.find(id)
		 if @shift.update_attributes(params[:shift])
			@shifts = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_shifts
	 else
			 render_edit_shift

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: shift_type_id
#	---------------------------------------------------------------------------------
def shift_shift_type_code_changed
	shift_type_code = get_selected_combo_value(params)
	@shift_type = ShiftType.find_by_shift_type_code(shift_type_code)

  #render (inline) the html to replace the contents of the td that contains the drop_down
	render :inline => %{
	<script>
		 <%= update_element_function(
        "start_time_cell", :action => :update,
        :content => @shift_type.start_time.to_s) %>

          <%= update_element_function(
        "end_time_cell", :action => :update,
        :content => @shift_type.end_time.to_s) %>
         </script>
		}


end

  #========================= combo selection ==========================
  def shift_start_time_combo_changed

    start_time = get_selected_combo_value(params)
    session[:shift_form][:start_date_time_combo_selection]  = start_time
    shift_type_code = session[:shift_form][:shift_type_code_combo_selection]

    @end_times = ShiftType.find_by_sql("select distinct end_time from shift_types where start_time =  '#{start_time}' and shift_type_code = '#{shift_type_code}'").map {|s| [s.end_time]}
    @end_times.unshift("<empty>")

    render :inline =>  %{

      <%= select('shift','end_time',@end_times) %>
    }
  end

#================== find shift================
  def find_shift
    render :inline => %{
            <% @content_header_caption = "'find shifts'"%>

            <%= build_shift_search_form()%>                                                           `

            }, :layout => 'content'

  end

  #================ submit search=================
   def shifts_submit
     @shifts = Shift.build_and_exec_query(params['shifts'],session)
        if !@shifts || @shifts.length == 0
          redirect_to_index("No rows returned")
          return
        end
        if @shifts.length == 100
         flash[:notice]= "The result set was limited to 100 rows!"
        end
        session[:active_search] = "render_shifts"
        render_shifts @shifts

   end

  #================= render shifts ==================
  def render_shifts(shifts)
    @shifts = shifts
      @caption = "'list of found shifts'"
    render :inline => %{
      <% grid            = build_shift_grid(@shifts,@can_edit,@can_delete) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end



end
