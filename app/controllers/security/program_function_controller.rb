class  Security::ProgramFunctionController < ApplicationController
 
def program_name?
	"program_function"
end

#==============================================================================
#Paging model Fixes: 
#NB: Any list producing method, typically, a search_submit function and a list_all
#    function must reset the 'session[:program_functions_page]' variable IF
#    that function is called from a paging link.(check is whether params['page'] exists).
#    The reason is that the web_request method, e.g. update_something or search_submit
#    that renders a list and that generates the paging_links, will render the links with
#    itself as the paging source, e.g. 'update something' (that calls list_something internally
#    after updating) will render paging links with url like: 'update_something?page = 2'.So
#    the 'update_something' method (as with any method that renders a list that uses paging links)
#    must first see if it was called from a 'paging' context (by checking whether params['page'] exists
#    If so, it should reset the session[x_page]variable to the current value of params['page'] and,
#    per strategy used in this code-base, call
#    the 'render_list' method of the controller. It should not directly call the 'list' method as this
#    will clear the session variable- the list method is mostly launched directly by the user from a 
#    menu item, so it must create a fresh list with link 1 as the active link every time- so NEVER
#    CALL LIST_SOMETHING FROM CODE TO REDIRECT BACK TO A LIST, CALL THE RENDER_LIST METHOD
#    
#==============================================================================

def list_program_functions
	return if authorise_for_web('program_function','read') == false 
    
    if params[:page]!= nil
      session[:program_functions_page]= params['page']
      render_list_program_functions()
      return
     else
       session[:program_functions_page]=nil
     end
    
	#@program_function_pages = Paginator.new self, ProgramFunction.count, 20,params['page']
	#session[:program_function_pages] = "@program_function_pages = Paginator.new self, ProgramFunction.count, 20,params['page']" 

	list_query = "@program_function_pages = Paginator.new self, ProgramFunction.count, @@page_size,@current_page\n"
	list_query +=  "@program_functions =@program_functions = ProgramFunction.find(:all,
			     :limit => @program_function_pages.items_per_page,
			     :order => 'id',
			     :offset => @program_function_pages.current.offset)"
	session[:query] = list_query		     
	#session[:program_functions] = @program_functions
#	@program_functions = ProgramFunction.find(:all,
#			 :limit => @program_function_pages.items_per_page,
#			 :offset => @program_function_pages.current.offset)
#	session[:program_functions] = @program_functions
	render_list_program_functions
end

def render_list_program_functions()
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	
	### CHANGED
	
	@current_page = session[:program_functions_page] if session[:program_functions_page]
	@current_page = params['page'] if params['page']
	
	
	@program_functions = eval(session[:query]) if !@program_functions

	#@window_size
	#@window_size = @@page_size
	
	
	#session[:program_functions] = @program_functions
	
	render :inline => %{
      <% grid            = build_program_function_grid(@program_functions,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all program_functions' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@program_function_pages) if @program_function_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_program_functions_flat
	return if authorise_for_web('program_function','read')== false
	@is_flat_search = true 
	render_program_function_search_form
end

def render_program_function_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  program_functions'"%> 

		<%= build_program_function_search_form(nil,'submit_program_functions_search','submit_program_functions_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_program_functions_hierarchy
	return if authorise_for_web('program_function','read')== false
	
	@is_flat_search = false 
	render_program_function_search_form(true)
end

def render_program_function_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  program_functions'"%> 

		<%= build_program_function_search_form(nil,'submit_program_functions_search','submit_program_functions_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_program_functions_search
    
    ###Changed
     if params['page']
      session[:program_functions_page] = params['page']
     else
       session[:program_functions_page]=nil
     end
    
	session[:program_functions] = nil
	@current_page = params['page']
	#@program_function_pages = Paginator.new self, ProgramFunction.count, 20,params['page']
	if params[:page]== nil
		 @program_functions = dynamic_search(params[:program_function] ,'program_functions','ProgramFunction',true, nil,'id')
	else
		@program_functions = eval(session[:query])
	end
	if @program_functions.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_program_function_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_program_functions
		end
	else
		#session[:program_functions] = @program_functions
		#@program_functions = session[:program_functions]
		render_list_program_functions
	end
end

 
def delete_program_function
	return if authorise_for_web('program_function','delete')== false
	
	if params[:page]
	 session[:program_functions_page] = params['page']
	 render_list_program_functions 
	 return
	end
	
	id = params[:id]
	if id && program_function = ProgramFunction.find(id)
		program_function.destroy
		session[:alert] = " Record deleted."
#		 update in-memory recordset
		#@program_functions = session[:program_functions]
		 #delete_record(@program_functions,id)
		#session[:program_functions] = @program_functions
		render_list_program_functions
	end
end
 
def new_program_function
	return if authorise_for_web('program_function','create')== false
		render_new_program_function
end
 
def create_program_function
	 @program_function = ProgramFunction.new(params[:program_function])
	 if @program_function.save
	#update in-memory list- if it exists
		#if session[:program_functions]
		#	 session[:program_functions].push @program_function
		#end
		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_program_function
	 end
end

def render_new_program_function
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new program_function'"%> 

		<%= build_program_function_form(@program_function,'create_program_function','create_program_function',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_program_function
	return if authorise_for_web('program_function','edit')==false 
	 id = params[:id]
	 if id && @program_function = ProgramFunction.find(id)
		render_edit_program_function

	 end
end


def render_edit_program_function
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit program_function'"%> 

		<%= build_program_function_form(@program_function,'update_program_function','update_program_function',true)%>

		}, :layout => 'content'
end
 
def update_program_function
    
    ### CHANGED
    
    #================================================================================================
    #This code block is needed to cater for paging (user clicking a page nr link)links
    #that were created from this method- it simply transfers control to the 'render_lists...' method 
    #================================================================================================
     if params[:page]!= nil
      session[:program_functions_page]= params['page']
      render_list_program_functions()
      return
     end
     
	 id = params[:program_function][:id]
	 @current_page = session[:program_functions_page]#params[:page] will always be null in this context
	 
	 ### CHANGED
	 #@program_function_pages = Paginator.new self, ProgramFunction.count, 20,params['page']
	 
	 if id && @program_function = ProgramFunction.find(id)
		 if @program_function.update_attributes(params[:program_function])
#		 update the in-memory recordset- to save db call
			#update_record(session[:program_functions],@program_function.attributes,id)
			@program_functions = eval(session[:query])
			render_list_program_functions
		else
			 render_edit_program_function

		 end
	 end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: program_id
#	---------------------------------------------------------------------------------
def program_function_program_name_changed
	program_name = get_selected_combo_value(params)
	session[:program_function_form][:program_name_combo_selection] = program_name
	@functional_area_names = ProgramFunction.functional_area_names_for_program_name(program_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('program_function','functional_area_name',@functional_area_names)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(program_functions)
#	-----------------------------------------------------------------------------------------------------------
def program_function_functional_area_name_search_combo_changed
	functional_area_name = get_selected_combo_value(params)
	session[:program_function_search_form][:functional_area_name_combo_selection] = functional_area_name
	@program_names = ProgramFunction.find_by_sql("Select distinct program_name from program_functions where functional_area_name = '#{functional_area_name}'").map{|g|[g.program_name]}
	@program_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
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
	@names = ProgramFunction.find_by_sql("Select distinct name from program_functions where program_name = '#{program_name}' and functional_area_name = '#{functional_area_name}'").map{|g|[g.name]}
	@names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('program_function','name',@names)%>

		}

end



end
