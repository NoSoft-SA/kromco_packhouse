class  Diagnostics::PdtLogController < ApplicationController

def program_name?
	"pdt_log"
end

def bypass_generic_security?
	true
end

  #--------------------------------list pdt logs--------------------------------
  def list_pdt_logs
	return if authorise_for_web(program_name?,'read') == false
 	if params[:page]!= nil
 		session[:pdt_logs_page] = params['page']
		 render_list_pdt_logs
		 return
	else
		session[:pdt_logs_page] = nil
	end

	list_query = "@pdt_log_pages = Paginator.new self, PdtLog.count, @@page_size,@current_page
	 @pdt_logs = PdtLog.find(:all,
                 :limit => @pdt_log_pages.items_per_page,:order=>'id desc',
				 :offset => @pdt_log_pages.current.offset)"
	session[:query] = list_query
	render_list_pdt_logs
end

  def render_list_pdt_logs
    load_menu_items_friendly_names
    @pagination_server = "list_pdt_logs"
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:pdt_logs_page]
    @current_page = params['page']||= session[:pdt_logs_page]
    @pdt_logs =  eval(session[:query]) if !@pdt_logs

    render :inline => %{
          <% grid            = build_pdt_log_grid(@pdt_logs,@can_edit,@can_delete)%>
          <% grid.caption    = 'list of all pdt_logs' %>
          <% @header_content = grid.build_grid_data %>

          <% @pagination = pagination_links(@pdt_log_pages) if @pdt_log_pages != nil %>
          <%= grid.render_html %>
          <%= grid.render_grid %>
          }, :layout => 'content'
  end

# def render_lookup_menu_items_popup
#     render :inline => %{
# 		<% @content_header_caption = "'search  program_functions'"%>
# 
# 		<%= build_look_up_menu_items_form(nil,'submit_program_functions','submit_program_functions',@is_flat_search)%>
# 
#    }, :layout => 'content'
# end

def program_function_functional_area_name_search_combo_changed
	functional_area_name = get_selected_combo_value(params)
	session[:program_function_search_form][:functional_area_name_combo_selection] = functional_area_name
	@program_names = ProgramFunction.find_by_sql("Select distinct program_name,display_name,is_non_web_program from programs where functional_area_name = '#{functional_area_name}'").map{|s| s.program_name + (("[" + s.display_name + "]") if s.is_non_web_program).to_s }
	@program_names.unshift("<empty>")

    @program_function = ProgramFunction.new
    #@program_function.program_name = "<empty>"

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
	@names = ProgramFunction.find_by_sql("Select distinct name,display_name,is_non_web_program from program_functions where program_name = '#{program_name}' and functional_area_name = '#{functional_area_name}'").map{|s| s.name + (("[" + s.display_name + "]") if s.is_non_web_program).to_s }
	@names.unshift("<empty>")

    @program_function = ProgramFunction.new
    #@program_function.name = "<empty>"

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
    @fn =  params[:program_function][:functional_area_name]
    @pn =  params[:program_function][:program_name]
    @name=  params[:program_function][:name]

    if @fn != "<empty" && @pn != "" && @name == "select a value from: 'program_function_program_name' to populate this list"
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

    window.opener.frames[1].document.getElementById('pdt_logs_menu_item').value = '<%= @selected_item%>';

    </script>


	},:layout => 'content'

    end


def delete_pdt_log
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:pdt_logs_page] = params['page']
		render_list_pdt_logs
		return
	end
	id = params[:id]
	if id && @pdt_log = PdtLog.find(id)
		@pdt_log.destroy
		session[:alert] = " Record deleted."
		render_list_pdt_logs
	end
rescue handle_error('record could not be deleted')
end
end

def edit_pdt_log
	return if authorise_for_web(program_name?,'edit')==false
	 id = params[:id]
	 if id && @pdt_log = PdtLog.find(id)
		render_edit_pdt_log

	 end
end

def render_edit_pdt_log
	render :inline => %{
		<% @content_header_caption = "'edit pdt_log'"%>

		<%= build_pdt_log_form(@pdt_log,'update_pdt_log','update_pdt_log',true)%>

		}, :layout => 'content'
end

def update_pdt_log
 begin
    id = params[:pdt_log][:id]
	 if id && @pdt_log = PdtLog.find(id)
		 if @pdt_log.update_attributes(params[:pdt_log])
			@pdt_logs = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_pdt_logs
	 else
			 render_edit_pdt_log

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end

  def last_10_pdt_logs
    load_menu_items_friendly_names
    if params[:pdt_logs_page] != nil
      session[:pdt_logs_page] = params['page']
      render_last_10_pdt_logs
      return
    else
      session[:pdt_logs_page] = nil
    end

    t1 = Time.now.last_month().to_formatted_s(:db)
    t2 = Time.now.at_beginning_of_day().to_formatted_s(:db)

    @start_day = t1
    @end_day = t2

    list_query = " @pdt_logs = PdtLog.find(:all,
                   :limit=>10,:order => 'id desc')"

    session[:query] = list_query
    render_last_10_pdt_logs

  end

  def render_last_10_pdt_logs
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:pdt_logs_page] if session[:pdt_logs_page]
    @current_page = params['page'] if params['page']
    @pdt_logs = eval(session[:query]) if !@pdt_logs

      render :inline => %{
        <% grid            = build_last_10_pdt_logs_grid(@pdt_logs,@can_edit,@can_delete)%>
        <% grid.caption    = 'list of last 10 pdt_logs' %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
      }, :layout => 'content'
  end

def pdt_logs_submit
  @pdt_logs = PdtLog.build_and_exec_query(params['pdt_logs'],session)
   if !@pdt_logs || @pdt_logs.length == 0
     redirect_to_index("No rows returned")
     return
   end

   session[:active_search] = "render_pdt_logs"
   render_pdt_logs @pdt_logs

  end

  def render_pdt_logs(pdt_logs)
    load_menu_items_friendly_names
    @pdt_logs = pdt_logs

      render :inline => %{
          <% grid            = build_pdt_log_grid(@pdt_logs,@can_edit,@can_delete)%>
          <% grid.caption    = 'list of found pdt logs' %>
          <% @header_content = grid.build_grid_data %>

          <%= grid.render_html %>
          <%= grid.render_grid %>
      }, :layout => 'content'
  end

#def load_menu_items_friendly_names
#  if(!session[:menu_items_friendly_names])
#    session[:menu_items_friendly_names] = {'1a'=>'Refresh','1b'=>'Undo','1c'=>'Cancel','1d'=>'Save Process','1d.1'=>'Save Process Submit','1e'=>'Load Process','1e.1'=>'Load Process Submit','1f'=>'Redo','1g'=>'Exit Process','1g.1'=>'Confirm Exit Process'}
#    functional_areas = FunctionalArea.find_by_sql("select functional_area_name,display_name from functional_areas where is_non_web_program is true").map{|g| session[:menu_items_friendly_names].store(g.functional_area_name,g.display_name)}
#    programs = Program.find_by_sql("select program_name,display_name from programs where is_non_web_program is true").map{|g| session[:menu_items_friendly_names].store(g.program_name,g.display_name)}
#    program_functions = ProgramFunction.find_by_sql("select name,display_name from program_functions where is_non_web_program is true").map{|g| session[:menu_items_friendly_names].store(g.name,g.display_name)}
#  end
#end

def view_details_logs
    id = params[:id]
	 if id && @pdt_log = PdtLog.find(id)
     load_menu_items_friendly_names

     @input_screen = PdtScreenDefinition.new(@pdt_log.input_xml,nil,nil,@pdt_log.user_name,@pdt_log.ip) if(@pdt_log.input_xml)
     @output_screen = PdtScreenDefinition.new(@pdt_log.output_xml,@pdt_log.menu_item,@pdt_log.mode,@pdt_log.user_name,@pdt_log.ip) if(@pdt_log.output_xml)
     @input_menu_tree = extract_menu_tree(@input_screen.screen_attributes["current_menu_item"].to_s)
     @output_menu_tree = extract_menu_tree(@pdt_log.menu_item.to_s)
  #   puts"@menu_tree : " + @menu_tree.map{|key,value| "[" + key.to_s + "=>" + value.to_s + "],"}.to_s
     render :template=>"diagnostics/pdt_logs/view_pdt_logs_details.rhtml",:layout => 'content'
	 end
end

#def extract_menu_tree(menu_item)
#  menu_item_components = menu_item.split('.')
#  level = menu_item_components.length - 1
#  tree = {}
#  case level
#    when 0
#      tree.store(:functional_area,"&#060 empty &#062")
#      tree.store(:program,"&#060 empty &#062")
#      tree.store(:program_function,"&#060 empty &#062")
#      tree.store(:special_menu,menu_item)
#    when 2
#      tree.store(:functional_area,"#{menu_item_components[0]}.#{menu_item_components[1]}")
#      tree.store(:program,menu_item)
#      tree.store(:program_function,"&#060 empty &#062")
#      tree.store(:special_menu,"&#060 empty &#062")
#    when 3
#      tree.store(:functional_area,level = "#{menu_item_components[0]}.#{menu_item_components[1]}")
#      tree.store(:program,"#{menu_item_components[0]}.#{menu_item_components[1]}.#{menu_item_components[2]}")
#      tree.store(:program_function,menu_item)
#      tree.store(:special_menu,"&#060 empty &#062")
#    else
#      tree.store(:functional_area,"&#060 empty &#062")
#      tree.store(:program,"&#060 empty &#062")
#      tree.store(:program_function,"&#060 empty &#062")
#      tree.store(:special_menu,"&#060 empty &#062")
#  end
#  return tree
#end

def view_paging_handler_pdt_logs
    if params[:page]
  	   session[:pdt_logs_page] = params['page']
  	end
    render_list_pdt_logs
end

  def look_up_menu_items
    render_lookup_menu_items_logs
  end

  def pdt_logs_today
    if params[:page]!= nil
      session[:pdt_logs_page] = params['page']
	    render_pdt_logs_today
      return
	else
		session[:pdt_logs_page] = nil
    end

    time_1 = Time.now.at_beginning_of_day().to_formatted_s(:db)
    time_2 = Time.now.tomorrow().to_formatted_s(:db)
	@start_day = time_1
	@end_day = time_2

	list_query ="@pdt_logs = PdtLog.find(:all,
                     :conditions=>['created_on >= ? and created_on <= ?','#{@start_day}', '#{@end_day}'],
                      :limit=> 100, :order=> 'id desc')"
    session[:query] = list_query
   render_pdt_logs_today

  end

  def render_pdt_logs_today
    load_menu_items_friendly_names
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:pdt_logs_page] if session[:pdt_logs_page]
    @current_page = params['page'] if params['page']
    @pdt_logs = eval(session[:query]) if !@pdt_logs

      render :inline => %{
          <% grid            = build_last_10_pdt_logs_grid(@pdt_logs,@can_edit,@can_delete)%>
          <% grid.caption    = 'list of pdt logs today' %>
          <% @header_content = grid.build_grid_data %>

          <%= grid.render_html %>
          <%= grid.render_grid %>
      }, :layout => 'content'
  end

def pdt_logs_by_user
    return if authorise_for_web(program_name?,'read') == false
    @usernames = User.find_by_sql("select distinct user_name from users").map{|s| [s.user_name]}
    @usernames.unshift("<empty>")

    @pdt_logs = PdtLog.new
    #@pdt_logs.user_names = "<empty>"
    render :template=>'/diagnostics/pdt_logs/errors_by_user.rhtml', :layout=>'content'
end

  def list_errors_by_user1
     @user_name= params[:username]
      if params[:page]!= nil
     	session[:pdt_logs_page] = params['page']
		 render_list_rails_errors
     return
	else
	 session[:pdt_logs_page] = nil
	end
   t1 = Time.now.last_month().to_formatted_s(:db)
   t2 = Time.now.at_beginning_of_day().to_formatted_s(:db)

    @start_day = t1
    @end_day = t2

     @name = params[:pdt_logs][:username]
    list_query = " @pdt_logs = PdtLog.find_by_sql(select * from pdt_logs where user_name= '#{@name}',
                   :conditions=>['created_on >= ? and created_on <= ?','#{@start_day}','#{@end_day}'],
                   :limit=>100,:order => 'id desc')"
    session[:query] = list_query
    render_list_pdt_errors_by_user
  end

  def render_list_pdt_errors_by_user
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:pdt_logs_page] if session[:pdt_logs_page]
    @current_page = params['page'] if params['page']

    @pdt_logs =  eval(session[:query]) if !@pdt_logs

      render :inline => %{
          <% grid            = build_last_10_pdt_logs_grid(@pdt_logs,@can_edit,@can_delete)%>
          <% grid.caption    = 'list of pdt errors by user' %>
          <% @header_content = grid.build_grid_data %>

          <%= grid.render_html %>
          <%= grid.render_grid %>
      }, :layout => 'content'
  end

def look_up_menu_items_logs
 render_lookup_menu_items_logs
end

def render_lookup_menu_items_logs
    render :inline => %{
		<% @content_header_caption = "'search  program_functions'"%>

		<%= build_look_up_menu_items_logs_form(nil,'submit_program_functions','submit_program_function',@is_flat_search)%>

   }, :layout => 'content'
end

  def list_logs_by_user
    render :inline => %{

        <% @content_header_caption = "'list pdt logs by user name'"%>
        <%= build_user_search_form()%>
        }, :layout => 'content'

  end

 def user_name_submit
    @user_name = params[:pdt_logs][:user_name]
    @pdt_logs = PdtLog.find_by_sql("select * from pdt_logs where pdt_logs.user_name= '#{@user_name}' order by pdt_logs.id desc limit 20")
    session[:query] = @pdt_logs
    render_list_pdt_errors_by_user
  end

def find_logs
  render :inline => %{

          <% @content_header_caption = "'find pdt logs'"%>
          <%=  build_pdt_log_search_form%>
          }, :layout => 'content'

end

end
