class  RawMaterials::CountsController < ApplicationController
 
def program_name?
	"counts"
end

def bypass_generic_security?
	true
end

#===================
#Size ref controller
#===================

def list_size_refs
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:size_refs_page] = params['page']

		 render_list_size_refs

		 return 
	else
		session[:size_refs_page] = nil
	end

	list_query = "@size_ref_pages = Paginator.new self, SizeRef.count, @@page_size,@current_page
	 @size_refs = SizeRef.find(:all,
				 :limit => @size_ref_pages.items_per_page,
				 :offset => @size_ref_pages.current.offset)"
	session[:query] = list_query
	render_list_size_refs
end


def render_list_size_refs
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:size_refs_page] if session[:size_refs_page]
	@current_page = params['page'] if params['page']
	@size_refs =  eval(session[:query]) if !@size_refs
	render :inline => %{
      <% grid            = build_size_ref_grid(@size_refs,@can_edit,@can_delete) %>
      <% grid.caption    = 'List of all size_refs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@size_ref_pages) if @size_ref_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_size_refs_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_size_ref_search_form
end

def render_size_ref_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  size_refs'"%> 

		<%= build_size_ref_search_form(nil,'submit_size_refs_search','submit_size_refs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_size_ref_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_size_ref_search_form(true)
end

def render_size_ref_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  size_refs'"%> 

		<%= build_size_ref_search_form(nil,'submit_size_refs_search','submit_size_refs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_size_refs_search
	if params['page']
		session[:size_refs_page] =params['page']
	else
		session[:size_refs_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @size_refs = dynamic_search(params[:size_ref] ,'size_refs','SizeRef')
	else
		@size_refs = eval(session[:query])
	end
	if @size_refs.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_size_ref_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_size_refs
		end

	else

		render_list_size_refs
	end
end

 
def delete_size_ref
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:size_refs_page] = params['page']
		render_list_size_refs
		return
	end
	id = params[:id]
	if id && size_ref = SizeRef.find(id)
		size_ref.destroy
		session[:alert] = " Record deleted."
		render_list_size_refs
	end
  rescue
   handle_error("size-ref could not be deleted")
  end
end
 
def new_size_ref
	return if authorise_for_web(program_name?,'create')== false
		render_new_size_ref
end
 
def create_size_ref
  begin
    
	 @size_ref = SizeRef.new(params[:size_ref])
	 if @size_ref.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_size_ref
	 end
 rescue
    handle_error("size ref could not be created")
  end
end

def render_new_size_ref
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new size_ref'"%> 

		<%= build_size_ref_form(@size_ref,'create_size_ref','create_size_ref',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_size_ref
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @size_ref = SizeRef.find(id)
		render_edit_size_ref

	 end
end


def render_edit_size_ref
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit size_ref'"%> 

		<%= build_size_ref_form(@size_ref,'update_size_ref','update_size_ref',true)%>

		}, :layout => 'content'
end
 
def update_size_ref
  begin
	if params[:page]
		session[:size_refs_page] = params['page']
		render_list_size_refs
		return
	end

		@current_page = session[:size_refs_page]
	 id = params[:size_ref][:id]
	 if id && @size_ref = SizeRef.find(id)
		 if @size_ref.update_attributes(params[:size_ref])
			@size_refs = eval(session[:query])
			render_list_size_refs
	 else
			 render_edit_size_ref

		 end
	 end
  rescue
   handle_error("size ref could not be updated")
  end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: commodity_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(size_refs)
#	-----------------------------------------------------------------------------------------------------------
def size_ref_commodity_code_search_combo_changed
	commodity_code = get_selected_combo_value(params)
	session[:size_ref_search_form][:commodity_code_combo_selection] = commodity_code
	@size_ref_codes = SizeRef.find_by_sql("Select distinct size_ref_code from size_refs where commodity_code = '#{commodity_code}'").map{|g|[g.size_ref_code]}
	@size_ref_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('size_ref','size_ref_code',@size_ref_codes)%>

		}

end


#=====================
#size controller
#=====================
def list_sizes
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:sizes_page] = params['page']

		 render_list_sizes

		 return 
	else
		session[:sizes_page] = nil
	end

	list_query = "@size_pages = Paginator.new self, Size.count, @@page_size,@current_page
	 @sizes = Size.find(:all,
				 :limit => @size_pages.items_per_page,
				 :offset => @size_pages.current.offset)"
	session[:query] = list_query
	render_list_sizes
end


def render_list_sizes
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:sizes_page] if session[:sizes_page]
	@current_page = params['page'] if params['page']
	@sizes =  eval(session[:query]) if !@sizes
	render :inline => %{
      <% grid            = build_size_grid(@sizes,@can_edit,@can_delete) %>
      <% grid.caption    = 'List of all sizes' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@size_pages) if @size_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_sizes_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_size_search_form
end

def render_size_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  sizes'"%> 

		<%= build_size_search_form(nil,'submit_sizes_search','submit_sizes_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_sizes_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_size_search_form(true)
end

def render_size_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  sizes'"%> 

		<%= build_size_search_form(nil,'submit_sizes_search','submit_sizes_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_sizes_search
	if params['page']
		session[:sizes_page] =params['page']
	else
		session[:sizes_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @sizes = dynamic_search(params[:size] ,'sizes','Size')
	else
		@sizes = eval(session[:query])
	end
	if @sizes.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_size_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_sizes
		end

	else

		render_list_sizes
	end
end

 
def delete_size
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:sizes_page] = params['page']
		render_list_sizes
		return
	end
	id = params[:id]
	if id && size = Size.find(id)
		size.destroy
		session[:alert] = " Record deleted."
		render_list_sizes
	end
  rescue
   handle_error("size could not be deleted")
  end
end
 
def new_size
	return if authorise_for_web(program_name?,'create')== false
		render_new_size
end
 
def create_size
  begin
	 @size = Size.new(params[:size])
	 if @size.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_size
	 end
  rescue
    handle_error("size could not be created")
  end
end

def render_new_size
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new size'"%> 

		<%= build_size_form(@size,'create_size','create_size',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_size
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @size = Size.find(id)
		render_edit_size

	 end
end


def render_edit_size
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit size'"%> 

		<%= build_size_form(@size,'update_size','update_size',true)%>

		}, :layout => 'content'
end
 
def update_size
  begin
	if params[:page]
		session[:sizes_page] = params['page']
		render_list_sizes
		return
	end

		@current_page = session[:sizes_page]
	 id = params[:size][:id]
	 if id && @size = Size.find(id)
		 if @size.update_attributes(params[:size])
			@sizes = eval(session[:query])
			render_list_sizes
	 else
			 render_edit_size

		 end
	 end
  rescue
   handle_error("size could not be updated")
  end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: commodity_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(sizes)
#	-----------------------------------------------------------------------------------------------------------
def size_commodity_code_search_combo_changed
	commodity_code = get_selected_combo_value(params)
	session[:size_search_form][:commodity_code_combo_selection] = commodity_code
	@size_codes = Size.find_by_sql("Select distinct size_code from sizes where commodity_code = '#{commodity_code}'").map{|g|[g.size_code]}
	@size_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('size','size_code',@size_codes)%>

		}
end


def size_commodity_code_changed
  
  commodity_code = get_selected_combo_value(params).strip
  
  @count_codes = StandardCount.find_all_by_commodity_code(commodity_code).map{|c|[c.standard_count_value]}
  
   render :inline => %{
    <% equivalent_count_from_content = select('size','equivalent_count_from',@count_codes) %>
     <% equivalent_count_to_content = select('size','equivalent_count_to',@count_codes) %>
   <script>
    <%= update_element_function(
        "equivalent_count_from_cell", :action => :update,
        :content => equivalent_count_from_content) %>
    
    <%= update_element_function(
        "equivalent_count_to_cell", :action => :update,
        :content => equivalent_count_to_content) %>    
   
   </script>
  }
  
  end

#================================
#Standard size count (conversion)
#================================
def list_standard_size_counts
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:standard_size_counts_page] = params['page']

		 render_list_standard_size_counts

		 return 
	else
		session[:standard_size_counts_page] = nil
	end

	list_query = "@standard_size_count_pages = Paginator.new self, StandardSizeCount.count, @@page_size,@current_page
	 @standard_size_counts = StandardSizeCount.find(:all,
				 :limit => @standard_size_count_pages.items_per_page,
				 :offset => @standard_size_count_pages.current.offset)"
	session[:query] = list_query
	render_list_standard_size_counts
end


def render_list_standard_size_counts
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:standard_size_counts_page] if session[:standard_size_counts_page]
	@current_page = params['page'] if params['page']
	@standard_size_counts =  eval(session[:query]) if !@standard_size_counts
	render :inline => %{
      <% grid            = build_standard_size_count_grid(@standard_size_counts,@can_edit,@can_delete) %>
      <% grid.caption    = 'List of all standard_size_counts' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@standard_size_count_pages) if @standard_size_count_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_standard_size_counts_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_standard_size_count_search_form
end

def render_standard_size_count_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  standard_size_counts'"%> 

		<%= build_standard_size_count_search_form(nil,'submit_standard_size_counts_search','submit_standard_size_counts_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_standard_size_counts_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_standard_size_count_search_form(true)
end

def render_standard_size_count_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  standard_size_counts'"%> 

		<%= build_standard_size_count_search_form(nil,'submit_standard_size_counts_search','submit_standard_size_counts_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_standard_size_counts_search
	if params['page']
		session[:standard_size_counts_page] =params['page']
	else
		session[:standard_size_counts_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @standard_size_counts = dynamic_search(params[:standard_size_count] ,'standard_size_counts','StandardSizeCount')
	else
		@standard_size_counts = eval(session[:query])
	end
	if @standard_size_counts.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_standard_size_count_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_standard_size_counts
		end

	else

		render_list_standard_size_counts
	end
end

 
def delete_standard_size_count
   begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:standard_size_counts_page] = params['page']
		render_list_standard_size_counts
		return
	end
	id = params[:id]
	if id && standard_size_count = StandardSizeCount.find(id)
		standard_size_count.destroy
		session[:alert] = " Record deleted."
		render_list_standard_size_counts
	end
  rescue
   handle_error("standard size count not be deleted")
  end
end
 
def new_standard_size_count
	return if authorise_for_web(program_name?,'create')== false
		render_new_standard_size_count
end
 
def create_standard_size_count
  begin
	 @standard_size_count = StandardSizeCount.new(params[:standard_size_count])
	 if @standard_size_count.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_standard_size_count
	 end
  rescue
    handle_error("standard size count group could not be created")
  end
end

def render_new_standard_size_count
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new standard_size_count'"%> 

		<%= build_standard_size_count_form(@standard_size_count,'create_standard_size_count','create_standard_size_count',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_standard_size_count
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @standard_size_count = StandardSizeCount.find(id)
		render_edit_standard_size_count

	 end
end


def render_edit_standard_size_count
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit standard_size_count'"%> 

		<%= build_standard_size_count_form(@standard_size_count,'update_standard_size_count','update_standard_size_count',true)%>

		}, :layout => 'content'
end
 
def update_standard_size_count
  begin
	if params[:page]
		session[:standard_size_counts_page] = params['page']
		render_list_standard_size_counts
		return
	end

		@current_page = session[:standard_size_counts_page]
	 id = params[:standard_size_count][:id]
	 if id && @standard_size_count = StandardSizeCount.find(id)
		 if @standard_size_count.update_attributes(params[:standard_size_count])
			@standard_size_counts = eval(session[:query])
			render_list_standard_size_counts
	 else
			 render_edit_standard_size_count

		 end
	 end
  rescue
   handle_error("standard size count could not be updated")
  end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: standard_count_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: commodity_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: basic_pack_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: old_pack_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(standard_size_counts)
#	-----------------------------------------------------------------------------------------------------------
def standard_size_count_commodity_code_search_combo_changed
	commodity_code = get_selected_combo_value(params)
	session[:standard_size_count_search_form][:commodity_code_combo_selection] = commodity_code
	@standard_size_count_values = StandardSizeCount.find_by_sql("Select distinct standard_size_count_value from standard_size_counts where commodity_code = '#{commodity_code}'").map{|g|[g.standard_size_count_value]}
	@standard_size_count_values.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('standard_size_count','standard_size_count_value',@standard_size_count_values)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_standard_size_count_standard_size_count_value'/>
		<%= observe_field('standard_size_count_standard_size_count_value',:update => 'basic_pack_code_cell',:url => {:action => session[:standard_size_count_search_form][:standard_size_count_value_observer][:remote_method]},:loading => "show_element('img_standard_size_count_standard_size_count_value');",:complete => session[:standard_size_count_search_form][:standard_size_count_value_observer][:on_completed_js])%>
		}

end


def standard_size_count_standard_size_count_value_search_combo_changed
	standard_size_count_value = get_selected_combo_value(params)
	session[:standard_size_count_search_form][:standard_size_count_value_combo_selection] = standard_size_count_value
	commodity_code = 	session[:standard_size_count_search_form][:commodity_code_combo_selection]
	@basic_pack_codes = StandardSizeCount.find_by_sql("Select distinct basic_pack_code from standard_size_counts where standard_size_count_value = '#{standard_size_count_value}' and commodity_code = '#{commodity_code}'").map{|g|[g.basic_pack_code]}
	@basic_pack_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('standard_size_count','basic_pack_code',@basic_pack_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_standard_size_count_basic_pack_code'/>
		<%= observe_field('standard_size_count_basic_pack_code',:update => 'actual_count_cell',:url => {:action => session[:standard_size_count_search_form][:basic_pack_code_observer][:remote_method]},:loading => "show_element('img_standard_size_count_basic_pack_code');",:complete => session[:standard_size_count_search_form][:basic_pack_code_observer][:on_completed_js])%>
		}

end


def standard_size_count_basic_pack_code_search_combo_changed
	basic_pack_code = get_selected_combo_value(params)
	session[:standard_size_count_search_form][:basic_pack_code_combo_selection] = basic_pack_code
	standard_size_count_value = 	session[:standard_size_count_search_form][:standard_size_count_value_combo_selection]
	commodity_code = 	session[:standard_size_count_search_form][:commodity_code_combo_selection]
	@actual_counts = StandardSizeCount.find_by_sql("Select distinct actual_count from standard_size_counts where basic_pack_code = '#{basic_pack_code}' and standard_size_count_value = '#{standard_size_count_value}' and commodity_code = '#{commodity_code}'").map{|g|[g.actual_count]}
	@actual_counts.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('standard_size_count','actual_count',@actual_counts)%>

		}

end

#=====================
#Standard counts table
#=====================

def list_standard_counts
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:standard_counts_page] = params['page']

		 render_list_standard_counts

		 return 
	else
		session[:standard_counts_page] = nil
	end

	list_query = "@standard_count_pages = Paginator.new self, StandardCount.count, @@page_size,@current_page
	 @standard_counts = StandardCount.find(:all,
				 :limit => @standard_count_pages.items_per_page,
				 :order => 'standard_count_value',
				 :offset => @standard_count_pages.current.offset)"
	session[:query] = list_query
	render_list_standard_counts
end


def render_list_standard_counts
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:standard_counts_page] if session[:standard_counts_page]
	@current_page = params['page'] if params['page']
	@standard_counts =  eval(session[:query]) if !@standard_counts
	render :inline => %{
      <% grid            = build_standard_count_grid(@standard_counts,@can_edit,@can_delete) %>
      <% grid.caption    = 'List of all standard_counts' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@standard_count_pages) if @standard_count_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_standard_counts_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_standard_count_search_form
end

def render_standard_count_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  standard_counts'"%> 

		<%= build_standard_count_search_form(nil,'submit_standard_counts_search','submit_standard_counts_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_standard_counts_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_standard_count_search_form(true)
end

def render_standard_count_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  standard_counts'"%> 

		<%= build_standard_count_search_form(nil,'submit_standard_counts_search','submit_standard_counts_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_standard_counts_search
	if params['page']
		session[:standard_counts_page] =params['page']
	else
		session[:standard_counts_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @standard_counts = dynamic_search(params[:standard_count] ,'standard_counts','StandardCount',nil,nil,"standard_count_value")
	else
		@standard_counts = eval(session[:query])
	end
	if @standard_counts.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_standard_count_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_standard_counts
		end

	else

		render_list_standard_counts
	end
end

 
def delete_standard_count
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:standard_counts_page] = params['page']
		render_list_standard_counts
		return
	end
	id = params[:id]
	if id && standard_count = StandardCount.find(id)
		standard_count.destroy
		session[:alert] = " Record deleted."
		render_list_standard_counts
	end
  rescue
   handle_error("standard count not be deleted")
  end
end
 
def new_standard_count
	return if authorise_for_web(program_name?,'create')== false
		render_new_standard_count
end
 
def create_standard_count
  begin
	 @standard_count = StandardCount.new(params[:standard_count])
	 if @standard_count.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_standard_count
	 end
  rescue
    handle_error("standard count not be created")
  end
end

def render_new_standard_count
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new standard_count'"%> 

		<%= build_standard_count_form(@standard_count,'create_standard_count','create_standard_count',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_standard_count
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @standard_count = StandardCount.find(id)
		render_edit_standard_count

	 end
end


def render_edit_standard_count
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit standard_count'"%> 

		<%= build_standard_count_form(@standard_count,'update_standard_count','update_standard_count',true)%>

		}, :layout => 'content'
end
 
def update_standard_count
  begin
	if params[:page]
		session[:standard_counts_page] = params['page']
		render_list_standard_counts
		return
	end

		@current_page = session[:standard_counts_page]
	 id = params[:standard_count][:id]
	 if id && @standard_count = StandardCount.find(id)
		 if @standard_count.update_attributes(params[:standard_count])
			@standard_counts = eval(session[:query])
			render_list_standard_counts
	 else
			 render_edit_standard_count

		 end
	 end
  rescue
   handle_error("standard count could not be updated")
  end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: commodity_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(standard_counts)
#	-----------------------------------------------------------------------------------------------------------

end
