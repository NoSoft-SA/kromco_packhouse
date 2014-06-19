class  Tools::ShiftTypeController < ApplicationController
 
def program_name?
	"shift_type"
end

def bypass_generic_security?
	true
end
def list_shift_types
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:shift_types_page] = params['page']

		 render_list_shift_types

		 return 
	else
		session[:shift_types_page] = nil
	end

	list_query = "@shift_type_pages = Paginator.new self, ShiftType.count, @@page_size,@current_page
	 @shift_types = ShiftType.find(:all,
				 :limit => @shift_type_pages.items_per_page,
				 :offset => @shift_type_pages.current.offset)"
	session[:query] = list_query
	render_list_shift_types
end


def render_list_shift_types
	@pagination_server = "list_shift_types"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:shift_types_page]
	@current_page = params['page']||= session[:shift_types_page]
	@shift_types =  eval(session[:query]) if !@shift_types
	render :inline => %{
      <% grid            = build_shift_type_grid(@shift_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all shift_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@shift_type_pages) if @shift_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_shift_types_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_shift_type_search_form
end

def render_shift_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  shift_types'"%> 

		<%= build_shift_type_search_form(nil,'submit_shift_types_search','submit_shift_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_shift_types_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_shift_type_search_form(true)
end

def render_shift_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  shift_types'"%> 

		<%= build_shift_type_search_form(nil,'submit_shift_types_search','submit_shift_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_shift_types_search
	@shift_types = dynamic_search(params[:shift_type] ,'shift_types','ShiftType')
	if @shift_types.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_shift_type_search_form
		else
			render_list_shift_types
	end
end

 
def delete_shift_type
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:shift_types_page] = params['page']
		render_list_shift_types
		return
	end
	id = params[:id]
	if id && shift_type = ShiftType.find(id)
		shift_type.destroy
		session[:alert] = " Record deleted."
		render_list_shift_types
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_shift_type
	return if authorise_for_web(program_name?,'create')== false
		render_new_shift_type
end
 
def create_shift_type
 begin
	 @shift_type = ShiftType.new(params[:shift_type])
	 if @shift_type.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_shift_type
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_shift_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new shift_type'"%> 

		<%= build_shift_type_form(@shift_type,'create_shift_type','create_shift_type',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_shift_type
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @shift_type = ShiftType.find(id)
		render_edit_shift_type

	 end
end


def render_edit_shift_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit shift_type'"%> 

		<%= build_shift_type_form(@shift_type,'update_shift_type','update_shift_type',true)%>

		}, :layout => 'content'
end
 
def update_shift_type
 begin

	 id = params[:shift_type][:id]
	 if id && @shift_type = ShiftType.find(id)
		 if @shift_type.update_attributes(params[:shift_type])
			@shift_types = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_shift_types
	 else
			 render_edit_shift_type

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 
#	-----------------------------------------------w------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(shift_types)
#	-----------------------------------------------------------------------------------------------------------
def shift_type_shift_type_code_search_combo_changed
	shift_type_code = get_selected_combo_value(params)
	session[:shift_type_search_form][:shift_type_code_combo_selection] = shift_type_code
	@start_times = ShiftType.find_by_sql("Select distinct start_time from shift_types where shift_type_code = '#{shift_type_code}'").map{|g|[g.start_time]}
	@start_times.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('shift_type','start_time',@start_times)%>

		}

end

#def get_shift_type(type)
#    @type = type
#    @shift_type = nil
#    @shift_types = ShiftType.find(:all)
#    for element in @shift_types
#      if element.shift_type_code == @type
#         @shift_type = element
#         break
#      end
#    end
#    return @shift_type
#end
##
#def get_shift_start_times
#
#    if (@shift_type.shift_type_code == "D")
#      @night_shift = get_shift_type("N")
#      @day_night = get_shift_type("C")
#
#      if @night_shift != nil and @day_night!=nil
#        @start_time = [@night_shift.end ...@day_night.start]
#      elsif @night_shift == nil and @day_night!=nil
#         @start_time = [8...@day_night]
#      end
#    end
#end

#============================ shft control =========================
#  def shift_control
#    shift_type = params[:shift_type][:shift_type_code]
#    start_time = (params[:shift_type][:start_time]).to_i
#    end_time = (params[:shift_type][:end_time]).to_i
#
#  duration = end_time - start_time
#    if shift_type == "D"
#      @night_shift = get_shift_type("N")
#      @day_night = get_shift_type("C")
#
#      if @night_shift != nil && @day_night != nil
#        @start_time =  [@night_shift.end ...@day_night.start]
#         @start_time = [8...@day_night]
#      end
#    end
#
#    redirect_to_index("'new record created successfully'","'create successful'")
#
#  end


end
