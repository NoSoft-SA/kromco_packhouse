class  Tools::SizerTemplateController < ApplicationController
 
def program_name?
	"sizer_template"
end

def bypass_generic_security?
	true
end


#========================
#PACK GROUP TEMPLATE CODE
#========================

def list_pack_groups
 begin

	list_query = "
	 @pack_group_templates = PackGroupTemplate.find_all_by_sizer_template_id('#{session[:current_sizer_template].id}')"
	 session[:pack_groups_query] = list_query
	 render_list_pack_groups
 rescue
  handle_error("Pack groups could not be listed")
 end
end


def render_list_pack_groups
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@template_name = session[:current_sizer_template].template_name
	
	@pack_group_templates =  eval(session[:pack_groups_query]) if !@pack_group_templates
  render :inline => %{
      <% grid            = build_pack_group_template_grid(@pack_group_templates,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all pack_group_templates for sizer template:  #{@template_name}' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def delete_pack_group_template
	return if authorise_for_web(program_name?,'delete')== false
	
	id = params[:id]
	if id && pack_group_template = PackGroupTemplate.find(id)
		pack_group_template.destroy
		session[:alert] = " Record deleted."
		render_list_pack_groups
	end
end
 
def new_pack_group
	return if authorise_for_web(program_name?,'create')== false
		render_new_pack_group_template
end
 
def create_pack_group_template
	 @pack_group_template = PackGroupTemplate.new(params[:pack_group_template])
	 @pack_group_template.sizer_template = session[:current_sizer_template]
	 if @pack_group_template.save

		 flash[:notice] = "new record created successfully"
		 active_template
	else
		@is_create_retry = true
		render_new_pack_group_template
	 end
end

def render_new_pack_group_template
#	 render (inline) the edit template
     @sizer_template = session[:current_sizer_template]
	render :inline => %{
		<% @content_header_caption = "'create new pack_group_template'"%> 

		<%= build_pack_group_template_form(@sizer_template,@pack_group_template,'create_pack_group_template','create_pack_group_template',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_pack_group_template
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @pack_group_template = PackGroupTemplate.find(id)
		render_edit_pack_group_template

	 end
end


def render_edit_pack_group_template
#	 render (inline) the edit template
    @sizer_template = session[:current_sizer_template]
	render :inline => %{
		<% @content_header_caption = "'edit pack_group_template'"%> 

		<%= build_pack_group_template_form(@sizer_template,@pack_group_template,'update_pack_group_template','update_pack_group_template',true)%>

		}, :layout => 'content'
end
 
def update_pack_group_template
	
	 id = params[:pack_group_template][:id]
	 if id && @pack_group_template = PackGroupTemplate.find(id)
		 if @pack_group_template.update_attributes(params[:pack_group_template])
			flash[:notice]= "updated"
			render_list_pack_groups
	 else
			 render_edit_pack_group_template

		 end
	 end
 end
 
 #============
 #OUTLETS CODE
 #============
 def set_drops_to_counts
  return if authorise_for_web(program_name?,'edit') == false 
    
    @pack_group_template = PackGroupTemplate.find(params[:id])
    session[:current_pack_group_template] = @pack_group_template
	list_query = "@pack_group_outlets = PackGroupTemplateOutlet.find_all_by_pack_group_template_id('#{params[:id]}',:order => 'id')"
	session[:outlets_query] = list_query
	
	 render_list_pack_group_outlets
 
 end
 
  def edit_drops_to_counts
    id = params[:id]
    @pack_group_outlet = PackGroupTemplateOutlet.find(id)
    if @pack_group_outlet.size_code
	   @size_count = @pack_group_outlet.size_code
    else
	  @size_count = @pack_group_outlet.standard_size_count_value.to_s
    end
	   render_edit_pack_group_outlet
  end
 
 def render_edit_pack_group_outlet
#	 render (inline) the edit template
   @template_name = session[:current_sizer_template].template_name
   @line_config = session[:current_sizer_template].line_config_code
	render :inline => %{
		<% @content_header_caption = "'allocate drops for count " + @size_count + ". Template: " + @template_name + ". Line config: " + @line_config + " '"%> 

		<%= build_pack_group_template_outlet_form(@pack_group_outlet,'update_pack_group_outlet','save',true)%>

		}, :layout => 'content'
end
 
def update_pack_group_outlet
  begin
	
	 id = params[:pack_group_outlet][:id]
	 if id && @pack_group_outlet = PackGroupTemplateOutlet.find(id)
		 if @pack_group_outlet.update_attributes(params[:pack_group_outlet])
		    flash[:notice] = "record saved"
			@pack_group_outlets = eval(session[:outlets_query])
			render_list_pack_group_outlets
	 else
			 render_edit_pack_group_outlet

		 end
	 end
  rescue
    handle_error("Drops could not be set to counts")
  end
 end
 
 
 def render_list_pack_group_outlets()

	@can_edit_run =  authorise(program_name?,'edit',session[:user_id])
	
	
	@pack_group_outlets =  eval(session[:outlets_query]) if !@pack_group_outlets
	
	
	
	@caption = "'<font color = \"brown\">Setup pack group " + session[:current_pack_group_template].pack_group_number.to_s + "(commodity: " + session[:current_pack_group_template].commodity_code + ",color percentage: " + session[:current_pack_group_template].color_sort_percentage.to_s + ", grade: " + session[:current_pack_group_template].grade_code.to_s + ")</font>'"
	
  render :inline => %{
      <% grid            = build_drops_to_counts_template_grid(@pack_group_outlets,@can_edit_run) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 

#===================================
#SIZER TEMPLATE CODE
#===================================

def active_template
 if !session[:current_sizer_template]
  redirect_to_index("you have not yet selected  sizer template from a list of templates")
 else
  @sizer_template = session[:current_sizer_template].reload
  render_edit_sizer_template
 end
end


def list_sizer_templates
	return if authorise_for_web('sizer_template','read') == false 

 	if params[:page]!= nil 

 		session[:sizer_templates_page] = params['page']

		 render_list_sizer_templates

		 return 
	else
		session[:sizer_templates_page] = nil
	end

	list_query = "@sizer_template_pages = Paginator.new self, SizerTemplate.count, @@page_size,@current_page
	 @sizer_templates = SizerTemplate.find(:all,
				 :limit => @sizer_template_pages.items_per_page,
				 :offset => @sizer_template_pages.current.offset)"
	session[:query] = list_query
	render_list_sizer_templates
end


def render_list_sizer_templates
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:sizer_templates_page] if session[:sizer_templates_page]
	@current_page = params['page'] if params['page']
	@sizer_templates =  eval(session[:query]) if !@sizer_templates
    render :inline => %{
        <% grid            = build_sizer_template_grid(@sizer_templates,@can_edit,@can_delete)%>
        <% grid.caption    = 'list of all sizer_templates' %>
        <% @header_content = grid.build_grid_data %>

        <% @pagination = pagination_links(@sizer_template_pages) if @sizer_template_pages != nil %>
        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
end
 
def search_sizer_templates_flat
	return if authorise_for_web('sizer_template','read')== false
	@is_flat_search = true 
	render_sizer_template_search_form
end

def render_sizer_template_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  sizer_templates'"%> 

		<%= build_sizer_template_search_form(nil,'submit_sizer_templates_search','submit_sizer_templates_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_sizer_templates_hierarchy
	return if authorise_for_web('sizer_template','read')== false
 
	@is_flat_search = false 
	render_sizer_template_search_form(true)
end

def render_sizer_template_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  sizer_templates'"%> 

		<%= build_sizer_template_search_form(nil,'submit_sizer_templates_search','submit_sizer_templates_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_sizer_templates_search
	if params['page']
		session[:sizer_templates_page] =params['page']
	else
		session[:sizer_templates_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @sizer_templates = dynamic_search(params[:sizer_template] ,'sizer_templates','SizerTemplate')
	else
		@sizer_templates = eval(session[:query])
	end
	if @sizer_templates.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_sizer_template_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_sizer_templates
		end

	else

		render_list_sizer_templates
	end
end

 
def delete_sizer_template
	return if authorise_for_web('sizer_template','delete')== false
	if params[:page]
		session[:sizer_templates_page] = params['page']
		render_list_sizer_templates
		return
	end
	id = params[:id]
	if id && sizer_template = SizerTemplate.find(id)
		sizer_template.destroy
		session[:alert] = " Record deleted."
		render_list_sizer_templates
	end
end
 
def new_sizer_template
	return if authorise_for_web('sizer_template','create')== false
		render_new_sizer_template
end
 
def create_sizer_template
	 @sizer_template = SizerTemplate.new(params[:sizer_template])
	 if @sizer_template.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_sizer_template
	 end
end

def render_new_sizer_template
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new sizer_template'"%> 

		<%= build_sizer_template_form(@sizer_template,'create_sizer_template','create_sizer_template',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_sizer_template
	return if authorise_for_web('sizer_template','edit')==false 
	 id = params[:id]
	 if id && @sizer_template = SizerTemplate.find(id)
	    session[:current_sizer_template] = @sizer_template
		render_edit_sizer_template

	 end
end


def render_edit_sizer_template
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit sizer_template'"%> 

		<%= build_sizer_template_form(@sizer_template,'update_sizer_template','update_sizer_template',true)%>

		}, :layout => 'content'
end
 
def update_sizer_template
  #begin
	if params[:page]
		session[:sizer_templates_page] = params['page']
		render_list_sizer_templates
		return
	end

		@current_page = session[:sizer_templates_page]
	 id = params[:sizer_template][:id]
	 if id && @sizer_template = SizerTemplate.find(id)
		 if @sizer_template.update_attributes(params[:sizer_template])
			flash[:notice]= "updated"
			#@sizer_templates = eval(session[:query])
			active_template
			#render_list_sizer_templates
	 else
			 render_edit_sizer_template

		 end
	 end
	#rescue
	 # handle_error("sizer template could not be saved")
	#end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: farm_group_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: rmt_variety_id
#	---------------------------------------------------------------------------------
def sizer_template_commodity_group_code_changed
	commodity_group_code = get_selected_combo_value(params)
	session[:sizer_template_form][:commodity_group_code_combo_selection] = commodity_group_code
	@commodity_codes = SizerTemplate.commodity_codes_for_commodity_group_code(commodity_group_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('sizer_template','commodity_code',@commodity_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_sizer_template_commodity_code'/>
		<%= observe_field('sizer_template_commodity_code',:update => 'rmt_variety_code_cell',:url => {:action => session[:sizer_template_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_sizer_template_commodity_code');",:complete => session[:sizer_template_form][:commodity_code_observer][:on_completed_js])%>
		}

end


def sizer_template_commodity_code_changed
	commodity_code = get_selected_combo_value(params)
	session[:sizer_template_form][:commodity_code_combo_selection] = commodity_code
	commodity_group_code = 	session[:sizer_template_form][:commodity_group_code_combo_selection]
	@rmt_variety_codes = SizerTemplate.rmt_variety_codes_for_commodity_code_and_commodity_group_code(commodity_code,commodity_group_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('sizer_template','rmt_variety_code',@rmt_variety_codes)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(sizer_templates)
#	-----------------------------------------------------------------------------------------------------------
def sizer_template_commodity_code_search_combo_changed
	commodity_code = get_selected_combo_value(params)
	session[:sizer_template_search_form][:commodity_code_combo_selection] = commodity_code
	@rmt_variety_codes = SizerTemplate.find_by_sql("Select distinct rmt_variety_code from sizer_templates where commodity_code = '#{commodity_code}'").map{|g|[g.rmt_variety_code]}
	@rmt_variety_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('sizer_template','rmt_variety_code',@rmt_variety_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_sizer_template_rmt_variety_code'/>
		<%= observe_field('sizer_template_rmt_variety_code',:update => 'fruit_size_cell',:url => {:action => session[:sizer_template_search_form][:rmt_variety_code_observer][:remote_method]},:loading => "show_element('img_sizer_template_rmt_variety_code');",:complete => session[:sizer_template_search_form][:rmt_variety_code_observer][:on_completed_js])%>
		}

end

 
def sizer_template_rmt_variety_code_search_combo_changed
	rmt_variety_code = get_selected_combo_value(params)
	session[:sizer_template_search_form][:rmt_variety_code_combo_selection] = rmt_variety_code
	commodity_code = 	session[:sizer_template_search_form][:commodity_code_combo_selection]
	@fruit_sizes = SizerTemplate.find_by_sql("Select distinct fruit_size from sizer_templates where rmt_variety_code = '#{rmt_variety_code}' and commodity_code = '#{commodity_code}'").map{|g|[g.fruit_size]}
	@fruit_sizes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('sizer_template','fruit_size',@fruit_sizes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_sizer_template_fruit_size'/>
		<%= observe_field('sizer_template_fruit_size',:update => 'color_sorting_cell',:url => {:action => session[:sizer_template_search_form][:fruit_size_observer][:remote_method]},:loading => "show_element('img_sizer_template_fruit_size');",:complete => session[:sizer_template_search_form][:fruit_size_observer][:on_completed_js])%>
		}

end


def sizer_template_fruit_size_search_combo_changed
	fruit_size = get_selected_combo_value(params)
	fruit_size = -1 if fruit_size == ""
	session[:sizer_template_search_form][:fruit_size_combo_selection] = fruit_size
	rmt_variety_code = 	session[:sizer_template_search_form][:rmt_variety_code_combo_selection]
	commodity_code = 	session[:sizer_template_search_form][:commodity_code_combo_selection]
	@color_sortings = SizerTemplate.find_by_sql("Select distinct color_sorting from sizer_templates where fruit_size = '#{fruit_size}' and rmt_variety_code = '#{rmt_variety_code}' and commodity_code = '#{commodity_code}'").map{|g|[g.color_sorting]}
	@color_sortings.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('sizer_template','color_sorting',@color_sortings)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_sizer_template_color_sorting'/>
		<%= observe_field('sizer_template_color_sorting',:update => 'line_code_cell',:url => {:action => session[:sizer_template_search_form][:color_sorting_observer][:remote_method]},:loading => "show_element('img_sizer_template_color_sorting');",:complete => session[:sizer_template_search_form][:color_sorting_observer][:on_completed_js])%>
		}

end


def sizer_template_color_sorting_search_combo_changed
	color_sorting = get_selected_combo_value(params)
	session[:sizer_template_search_form][:color_sorting_combo_selection] = color_sorting
	fruit_size = 	session[:sizer_template_search_form][:fruit_size_combo_selection]
	rmt_variety_code = 	session[:sizer_template_search_form][:rmt_variety_code_combo_selection]
	commodity_code = 	session[:sizer_template_search_form][:commodity_code_combo_selection]
	@line_codes = SizerTemplate.find_by_sql("Select distinct line_config_code from sizer_templates where color_sorting = '#{color_sorting}' and fruit_size = '#{fruit_size}' and rmt_variety_code = '#{rmt_variety_code}' and commodity_code = '#{commodity_code}'").map{|g|[g.line_config_code]}
	@line_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('sizer_template','line_config_code',@line_codes)%>

		}

end



end
