class  Production::DowntimeController < ApplicationController
 
def program_name?
	"downtime"
end

def bypass_generic_security?
	true
end
def list_downtimes
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:downtimes_page] = params['page']

		 render_list_downtimes

		 return 
	else
		session[:downtimes_page] = nil
	end

	list_query = "@downtime_pages = Paginator.new self, Downtime.count, @@page_size,@current_page
	 @downtimes = Downtime.find(:all,
				 :limit => @downtime_pages.items_per_page,
				 :offset => @downtime_pages.current.offset)"
	session[:query] = list_query
	render_list_downtimes
end


def render_list_downtimes
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:downtimes_page] if session[:downtimes_page]
	@current_page = params['page'] if params['page']
	@downtimes =  eval(session[:query]) if !@downtimes
	render :inline => %{
      <% grid            = build_downtime_grid(@downtimes,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all downtimes' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@downtime_pages) if @downtime_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_downtimes_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_downtime_search_form
end

def render_downtime_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  downtimes'"%> 

		<%= build_downtime_search_form(nil,'submit_downtimes_search','submit_downtimes_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_downtimes_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_downtime_search_form(true)
end

def render_downtime_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  downtimes'"%> 

		<%= build_downtime_search_form(nil,'submit_downtimes_search','submit_downtimes_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_downtimes_search
	if params['page']
		session[:downtimes_page] =params['page']
	else
		session[:downtimes_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @downtimes = dynamic_search(params[:downtime] ,'downtimes','Downtime')
	else
		@downtimes = eval(session[:query])
	end
	if @downtimes.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_downtime_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_downtimes
		end

	else

		render_list_downtimes
	end
end

 
def delete_downtime
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:downtimes_page] = params['page']
		render_list_downtimes
		return
	end
	id = params[:id]
	if id && downtime = Downtime.find(id)
		downtime.destroy
		session[:alert] = " Record deleted."
		render_list_downtimes
	end
end
 
def new_downtime
	return if authorise_for_web(program_name?,'create')== false
		render_new_downtime
end
 
def create_downtime
	 @downtime = Downtime.new(params[:downtime])
	 if @downtime.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_downtime
	 end
end

def render_new_downtime
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new downtime'"%> 

		<%= build_downtime_form(@downtime,'create_downtime','create_downtime',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_downtime
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @downtime = Downtime.find(id)
		render_edit_downtime

	 end
end


def render_edit_downtime
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit downtime'"%> 

		<%= build_downtime_form(@downtime,'update_downtime','update_downtime',true)%>

		}, :layout => 'content'
end
 
def update_downtime
	if params[:page]
		session[:downtimes_page] = params['page']
		render_list_downtimes
		return
	end

		@current_page = session[:downtimes_page]
	 id = params[:downtime][:id]
	 if id && @downtime = Downtime.find(id)
		 if @downtime.update_attributes(params[:downtime])
			@downtimes = eval(session[:query])
			render_list_downtimes
	 else
			 render_edit_downtime

		 end
	 end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: downtime_sub_type_id
#	---------------------------------------------------------------------------------
def downtime_downtime_category_code_changed
	downtime_category_code = get_selected_combo_value(params)
	session[:downtime_form][:downtime_category_code_combo_selection] = downtime_category_code
	@downtime_division_codes = Downtime.downtime_division_codes_for_downtime_category_code(downtime_category_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('downtime','downtime_division_code',@downtime_division_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_downtime_downtime_division_code'/>
		<%= observe_field('downtime_downtime_division_code',:update => 'downtime_type_code_cell',:url => {:action => session[:downtime_form][:downtime_division_code_observer][:remote_method]},:loading => "show_element('img_downtime_downtime_division_code');",:complete => session[:downtime_form][:downtime_division_code_observer][:on_completed_js])%>
		}

end


def downtime_downtime_division_code_changed
	downtime_division_code = get_selected_combo_value(params)
	session[:downtime_form][:downtime_division_code_combo_selection] = downtime_division_code
	downtime_category_code = 	session[:downtime_form][:downtime_category_code_combo_selection]
	@downtime_type_codes = Downtime.downtime_type_codes_for_downtime_division_code_and_downtime_category_code(downtime_division_code,downtime_category_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('downtime','downtime_type_code',@downtime_type_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_downtime_downtime_type_code'/>
		<%= observe_field('downtime_downtime_type_code',:update => 'downtime_sub_type_code_cell',:url => {:action => session[:downtime_form][:downtime_type_code_observer][:remote_method]},:loading => "show_element('img_downtime_downtime_type_code');",:complete => session[:downtime_form][:downtime_type_code_observer][:on_completed_js])%>
		}

end


def downtime_downtime_type_code_changed
	downtime_type_code = get_selected_combo_value(params)
	session[:downtime_form][:downtime_type_code_combo_selection] = downtime_type_code
	downtime_division_code = 	session[:downtime_form][:downtime_division_code_combo_selection]
	downtime_category_code = 	session[:downtime_form][:downtime_category_code_combo_selection]
	@downtime_sub_type_codes = Downtime.downtime_sub_type_codes_for_downtime_type_code_and_downtime_division_code_and_downtime_category_code(downtime_type_code,downtime_division_code,downtime_category_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('downtime','downtime_sub_type_code',@downtime_sub_type_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_downtime_downtime_sub_type_code'/>
		<%= observe_field('downtime_downtime_sub_type_code',:update => 'external_ref_cell',:url => {:action => session[:downtime_form][:downtime_sub_type_code_observer][:remote_method]},:loading => "show_element('img_downtime_downtime_sub_type_code');",:complete => session[:downtime_form][:downtime_sub_type_code_observer][:on_completed_js])%>
		}

end


def downtime_downtime_sub_type_code_changed
	downtime_sub_type_code = get_selected_combo_value(params)
	session[:downtime_form][:downtime_sub_type_code_combo_selection] = downtime_sub_type_code
	downtime_type_code = 	session[:downtime_form][:downtime_type_code_combo_selection]
	downtime_division_code = 	session[:downtime_form][:downtime_division_code_combo_selection]
	downtime_category_code = 	session[:downtime_form][:downtime_category_code_combo_selection]
	@external_refs = Downtime.external_refs_for_downtime_sub_type_code_and_downtime_type_code_and_downtime_division_code_and_downtime_category_code(downtime_sub_type_code,downtime_type_code,downtime_division_code,downtime_category_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('downtime','external_ref',@external_refs)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(downtimes)
#	-----------------------------------------------------------------------------------------------------------
def downtime_downtime_category_code_search_combo_changed
	downtime_category_code = get_selected_combo_value(params)
	session[:downtime_search_form][:downtime_category_code_combo_selection] = downtime_category_code
	@downtime_division_codes = Downtime.find_by_sql("Select distinct downtime_division_code from downtimes where downtime_category_code = '#{downtime_category_code}'").map{|g|[g.downtime_division_code]}
	@downtime_division_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('downtime','downtime_division_code',@downtime_division_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_downtime_downtime_division_code'/>
		<%= observe_field('downtime_downtime_division_code',:update => 'downtime_type_code_cell',:url => {:action => session[:downtime_search_form][:downtime_division_code_observer][:remote_method]},:loading => "show_element('img_downtime_downtime_division_code');",:complete => session[:downtime_search_form][:downtime_division_code_observer][:on_completed_js])%>
		}

end


def downtime_downtime_division_code_search_combo_changed
	downtime_division_code = get_selected_combo_value(params)
	session[:downtime_search_form][:downtime_division_code_combo_selection] = downtime_division_code
	downtime_category_code = 	session[:downtime_search_form][:downtime_category_code_combo_selection]
	@downtime_type_codes = Downtime.find_by_sql("Select distinct downtime_type_code from downtimes where downtime_division_code = '#{downtime_division_code}' and downtime_category_code = '#{downtime_category_code}'").map{|g|[g.downtime_type_code]}
	@downtime_type_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('downtime','downtime_type_code',@downtime_type_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_downtime_downtime_type_code'/>
		<%= observe_field('downtime_downtime_type_code',:update => 'downtime_sub_type_code_cell',:url => {:action => session[:downtime_search_form][:downtime_type_code_observer][:remote_method]},:loading => "show_element('img_downtime_downtime_type_code');",:complete => session[:downtime_search_form][:downtime_type_code_observer][:on_completed_js])%>
		}

end


def downtime_downtime_type_code_search_combo_changed
	downtime_type_code = get_selected_combo_value(params)
	session[:downtime_search_form][:downtime_type_code_combo_selection] = downtime_type_code
	downtime_division_code = 	session[:downtime_search_form][:downtime_division_code_combo_selection]
	downtime_category_code = 	session[:downtime_search_form][:downtime_category_code_combo_selection]
	@downtime_sub_type_codes = Downtime.find_by_sql("Select distinct downtime_sub_type_code from downtimes where downtime_type_code = '#{downtime_type_code}' and downtime_division_code = '#{downtime_division_code}' and downtime_category_code = '#{downtime_category_code}'").map{|g|[g.downtime_sub_type_code]}
	@downtime_sub_type_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('downtime','downtime_sub_type_code',@downtime_sub_type_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_downtime_downtime_sub_type_code'/>
		<%= observe_field('downtime_downtime_sub_type_code',:update => 'external_ref_cell',:url => {:action => session[:downtime_search_form][:downtime_sub_type_code_observer][:remote_method]},:loading => "show_element('img_downtime_downtime_sub_type_code');",:complete => session[:downtime_search_form][:downtime_sub_type_code_observer][:on_completed_js])%>
		}

end


def downtime_downtime_sub_type_code_search_combo_changed
	downtime_sub_type_code = get_selected_combo_value(params)
	session[:downtime_search_form][:downtime_sub_type_code_combo_selection] = downtime_sub_type_code
	downtime_type_code = 	session[:downtime_search_form][:downtime_type_code_combo_selection]
	downtime_division_code = 	session[:downtime_search_form][:downtime_division_code_combo_selection]
	downtime_category_code = 	session[:downtime_search_form][:downtime_category_code_combo_selection]
	@external_refs = Downtime.find_by_sql("Select distinct external_ref from downtimes where downtime_sub_type_code = '#{downtime_sub_type_code}' and downtime_type_code = '#{downtime_type_code}' and downtime_division_code = '#{downtime_division_code}' and downtime_category_code = '#{downtime_category_code}'").map{|g|[g.external_ref]}
	@external_refs.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('downtime','external_ref',@external_refs)%>

		}

end



end
