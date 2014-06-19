class  Diagnostics::PdtErrorController < ApplicationController

def program_name?
	"pdt_error"
end

def bypass_generic_security?
	true
end

def list_pdt_errors
	return if authorise_for_web(program_name?,'read') == false
  load_menu_items_friendly_names
 	if params[:page]!= nil
 		session[:pdt_errors_page] = params['page']
		 render_list_pdt_errors
		 return
	else
		session[:pdt_errors_page] = nil
	end

	list_query = "@pdt_error_pages = Paginator.new self, PdtError.count, @@page_size,@current_page
	 @pdt_errors = PdtError.find(:all,
				 :limit => @pdt_error_pages.items_per_page,:order=>'id desc',
				 :offset => @pdt_error_pages.current.offset)"
	session[:query] = list_query
	render_list_pdt_errors
end

def render_list_pdt_errors
	@pagination_server = "list_pdt_errors"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:pdt_errors_page]
	@current_page = params['page']||= session[:pdt_errors_page]
	@pdt_errors =  eval(session[:query]) if !@pdt_errors

    render :inline => %{
      <% grid            = build_pdt_error_grid(@pdt_errors,@can_edit,@can_delete)%>
      <% grid.caption    = 'list of all pdt_errors' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@pdt_error_pages) if @pdt_error_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def view_details
    id = params[:id]
	 if id && @pdt_error = PdtError.find(id)
     @input_screen = PdtScreenDefinition.new(@pdt_error.input_xml,nil,nil,@pdt_error.user_name,@pdt_error.ip) if(@pdt_error.input_xml)
     @input_menu_tree = extract_menu_tree(@input_screen.screen_attributes["current_menu_item"].to_s)
		render :template=>"diagnostics/pdt_error/view_pdt_errors_details.rhtml",:layout => 'content'
	 end
end

def view_paging_handler_pdt_errors
    if params[:page]
  	   session[:pdt_error_log_page] = params['page']
  	end
    render_list_pdt_errors
end

def find_errors

     render :inline => %{
		<% @content_header_caption = "'find pdt errors'"%>
        <%= build_pdt_error_search_form()%>

		}, :layout => 'content'

end

 def pdt_errors_submit
   load_menu_items_friendly_names
  @pdt_errors = PdtError.build_and_exec_query(params['pdt_errors'],session)
   if !@pdt_errors || @pdt_errors.length == 0
     redirect_to_index("No rows returned")
     return
   end
   
   session[:active_search] = "render_pdt_errors"
   render_pdt_errors @pdt_errors

  end

def look_up_menu_items
 render_lookup_menu_items_popup
end

# def render_lookup_menu_items_popup
#     render :inline => %{
# 		<% @content_header_caption = "'search  program_functions'"%>
#        	<%= build_look_up_menu_items_form(nil,'submit_program_functions','submit_program_functions',@is_flat_search)%>
# 
#    }, :layout => 'content'
# end

  def program_function_functional_area_name_search_combo_changed
	functional_area_name = get_selected_combo_value(params)
	session[:program_function_search_form][:functional_area_name_combo_selection] = functional_area_name
	@program_names = Program.find_by_sql("Select distinct program_name,display_name,is_non_web_program from programs where functional_area_name = '#{functional_area_name}'").map{|s| s.program_name + (("[" + s.display_name + "]") if s.is_non_web_program).to_s}
	@program_names.unshift("<empty>")

    @program_function = ProgramFunction.new       #==> binding the combo to empty


	render :inline => %{
		<%= select('program_function','program_name',@program_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_program_function_program_name'/>
		<%= observe_field('program_function_program_name',:update => 'name_cell',:url => {:action => session[:program_function_search_form][:program_name_observer][:remote_method]},:loading => "show_element('img_program_function_program_name');",:complete => session[:program_function_search_form][:program_name_observer][:on_completed_js])%>
		}

end

def program_function_program_name_search_combo_changed
	program_name = get_selected_combo_value(params)
	session[:program_function_search_form][:program_name_combo_selection] = program_name
	functional_area_name = 	session[:program_function_search_form][:functional_area_name_combo_selection]
	@names = ProgramFunction.find_by_sql("Select distinct name,display_name, is_non_web_program from program_functions where program_name = '#{program_name}' and functional_area_name = '#{functional_area_name}'").map{|s| s.name + (("[" + s.display_name + "]") if s.is_non_web_program).to_s}
	@names.unshift("<empty>")

    @program_function = ProgramFunction.new
   # @program_function.name = "<empty>"


	render :inline => %{
		<%= select('program_function','name',@names)%>
		}
end

def program_function_program_name_changed
	program_name = get_selected_combo_value(params)
	session[:program_function_form][:program_name_combo_selection] = program_name
	@functional_area_names = ProgramFunction.functional_area_names_for_program_name(program_name)

	render :inline => %{
    	<%= select('program_function','functional_area_name',@functional_area_names)%>
       }
end

def render_lookup_menu_items_popup(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
	render :inline => %{

		<% @content_header_caption = "'search  program_functions'"%>
		<%= build_look_up_menu_items_form(nil,'submit_program_functions','submit_program_functions',@is_flat_search)%>
		}, :layout => 'content'
end

def search_program_functions_hierarchy
	return if authorise_for_web('program_function','read')== false
	@is_flat_search = false
	render_lookup_menu_items_popup(true)
end

def submit_program_functions
  @fn = params[:program_function][:functional_area_name]
  @pn = params[:program_function][:program_name]
  @name = params[:program_function][:name]

    if @fn != "" && @pn != "" && @name == "select a value from: 'program_function_program_name' to populate this list"
     @selected_item = @pn
    else if @name != "" && @pn != "" && @fn != ""
     @selected_item = @name
    else if @pn != "" && @name == ""
     @selected_item = @pn
    else if @fn != "" && @pn != "" || @name != ""
     @selected_item = @fn
    else if @name == "" && @pn == "" && @fn == ""
    @selected_item = ""
     else
      render_program_functions
      end
    end
    end
   end
  end
   render_program_functions
end
  
def render_program_functions
 render :inline => %{
  <script>
   alert('search submitted');
    window.close();
    window.opener.frames[1].document.getElementById('pdt_errors_menu_item').value = '<%= @selected_item%>';

  </script >
	},:layout => 'content'
 end

# def pdt_errors_submit
#   @pdt_errors = PdtError.build_and_exec_query(params['pdt_errors'],session)
#    if !@pdt_errors || @pdt_errors.length == 0
#      redirect_to_index("No rows returned")
#      return
#    end
#   session[:active_search] = "render_pdt_errors"
#   render_pdt_errors @pdt_errors
# 
#   end

 def render_pdt_errors(pdt_errors)
    @pdt_errors = pdt_errors

    render :inline => %{
        <% grid            = build_pdt_error_grid(@pdt_errors,@can_edit,@can_delete)%>
        <% grid.caption    = 'list of found pdt errors' %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
  end

   def last_10_pdt_errors
    load_menu_items_friendly_names
    if params[:page]!= nil
      session[:pdt_errors_page] = params['page']
	  render_last_10_pdt_errors
      return
	else
		session[:pdt_errors_page] = nil
    end

   	time_1 = Time.now.at_beginning_of_day().to_formatted_s(:db)
    time_2 = Time.now.tomorrow().to_formatted_s(:db)

	@start_day = time_1
	@end_day = time_2

	list_query ="@pdt_errors = PdtError.find(:all,
                     :conditions=>['created_on >= ? and created_on <= ?','#{@start_day}','#{@end_day}'],
                     :limit=>10,:order => 'id desc')"
    session[:query] = list_query
    render_last_10_pdt_errors
 end

  def render_last_10_pdt_errors
    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:pdt_errors_page] if session[:pdt_errors_page]
    @current_page = params['page'] if params['page']
    @pdt_errors = eval(session[:query]) if !@pdt_errors

    render :inline => %{
        <% grid            = build_last_10_pdt_errors_grid(@pdt_errors,@can_edit,@can_delete)%>
        <% grid.caption    = 'list of last 10 pdt errors' %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
  end

  def pdt_errors_today
    load_menu_items_friendly_names
    if params[:page]!= nil
      session[:pdt_errors_page] = params['page']
	    render_pdt_errors_today
      return
	else
		session[:pdt_errors_page] = nil
	end

	time_1 = Time.now.at_beginning_of_day().to_formatted_s(:db)
    time_2 = Time.now.tomorrow().to_formatted_s(:db)

	@start_day = time_1
	@end_day = time_2

	list_query ="@pdt_errors = PdtError.find(:all,
                     :conditions=>['created_on >= ? and created_on <= ?','#{@start_day}', '#{@end_day}'],
                      :limit=> 100, :order=> 'id desc')"
   session[:query] = list_query
   render_pdt_errors_today
 end

  def render_pdt_errors_today
    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:pdt_errors_page] if session[:pdt_errors_page]
    @current_page = params['page'] if params['page']
    @pdt_errors = eval(session[:query]) if !@pdt_errors

    render :inline => %{
        <% grid            = build_last_10_pdt_errors_grid(@pdt_errors,@can_edit,@can_delete)%>
        <% grid.caption    = 'list of pdt errors today' %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
  end

end


