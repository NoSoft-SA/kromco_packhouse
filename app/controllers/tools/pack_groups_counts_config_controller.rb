class  Tools::PackGroupsCountsConfigController < ApplicationController
 
def program_name?
	"pack_groups_counts_config"
end

def bypass_generic_security?
	true
end
def list_pack_groups_counts_configs
	return if authorise_for_web('pack_groups_counts_config','read') == false 

 	if params[:page]!= nil 

 		session[:pack_groups_counts_configs_page] = params['page']

		 render_list_pack_groups_counts_configs

		 return 
	else
		session[:pack_groups_counts_configs_page] = nil
	end

	list_query = "@pack_groups_counts_config_pages = Paginator.new self, PackGroupsCountsConfig.count, 30,@current_page
	 @pack_groups_counts_configs = PackGroupsCountsConfig.find(:all,
				 :limit => @pack_groups_counts_config_pages.items_per_page,
				 :order => 'commodity_code,position',
				 :offset => @pack_groups_counts_config_pages.current.offset)"
	session[:query] = list_query
	render_list_pack_groups_counts_configs
end


def render_list_pack_groups_counts_configs
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:pack_groups_counts_configs_page] if session[:pack_groups_counts_configs_page]
	@current_page = params['page'] if params['page']
	@pack_groups_counts_configs =  eval(session[:query]) if !@pack_groups_counts_configs
	render :inline => %{
      <% grid            = build_pack_groups_counts_config_grid(@pack_groups_counts_configs,@can_edit,@can_delete) %>
      <% grid.caption    = 'Sequence of all pack_groups_counts_configs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@pack_groups_counts_config_pages) if @pack_groups_counts_config_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_pack_groups_counts_configs_flat
	return if authorise_for_web('pack_groups_counts_config','read')== false
	@is_flat_search = true 
	render_pack_groups_counts_config_search_form
end

def render_pack_groups_counts_config_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  pack_groups_counts_configs'"%> 

		<%= build_pack_groups_counts_config_search_form(nil,'submit_pack_groups_counts_configs_search','submit_pack_groups_counts_configs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_pack_groups_counts_configs_hierarchy
	return if authorise_for_web('pack_groups_counts_config','read')== false
 
	@is_flat_search = false 
	render_pack_groups_counts_config_search_form(true)
end

def render_pack_groups_counts_config_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  pack_groups_counts_configs'"%> 

		<%= build_pack_groups_counts_config_search_form(nil,'submit_pack_groups_counts_configs_search','submit_pack_groups_counts_configs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_pack_groups_counts_configs_search
	if params['page']
		session[:pack_groups_counts_configs_page] =params['page']
	else
		session[:pack_groups_counts_configs_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @pack_groups_counts_configs = dynamic_search(params[:pack_groups_counts_config] ,'pack_groups_counts_configs','PackGroupsCountsConfig',true, nil,'commodity_code,position',30)
	else
		@pack_groups_counts_configs = eval(session[:query])
	end
	if @pack_groups_counts_configs.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_pack_groups_counts_config_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_pack_groups_counts_configs
		end

	else

		render_list_pack_groups_counts_configs
	end
end

 
def delete_pack_groups_counts_config
	return if authorise_for_web('pack_groups_counts_config','delete')== false
	if params[:page]
		session[:pack_groups_counts_configs_page] = params['page']
		render_list_pack_groups_counts_configs
		return
	end
	id = params[:id]
	if id && pack_groups_counts_config = PackGroupsCountsConfig.find(id)
		pack_groups_counts_config.destroy
		session[:alert] = " Record deleted."
		render_list_pack_groups_counts_configs
	end
end
 
def new_pack_groups_counts_config
	return if authorise_for_web('pack_groups_counts_config','create')== false
		render_new_pack_groups_counts_config
end
 
def create_pack_groups_counts_config
  #begin
	 @pack_groups_counts_config = PackGroupsCountsConfig.new(params[:pack_groups_counts_config])
	 if @pack_groups_counts_config.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_pack_groups_counts_config
	 end
  #rescue
  #  handle_error("record could not be created")
  #end
end

def render_new_pack_groups_counts_config
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new pack_groups_counts_config'"%> 

		<%= build_pack_groups_counts_config_form(@pack_groups_counts_config,'create_pack_groups_counts_config','create',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_pack_groups_counts_config
	return if authorise_for_web('pack_groups_counts_config','edit')==false 
	 id = params[:id]
	 if id && @pack_groups_counts_config = PackGroupsCountsConfig.find(id)
		render_edit_pack_groups_counts_config

	 end
end


def render_edit_pack_groups_counts_config
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit pack_groups_counts_config'"%> 

		<%= build_pack_groups_counts_config_form(@pack_groups_counts_config,'update_pack_groups_counts_config','update',true)%>

		}, :layout => 'content'
end
 
def update_pack_groups_counts_config
  begin
	if params[:page]
		session[:pack_groups_counts_configs_page] = params['page']
		render_list_pack_groups_counts_configs
		return
	end

		@current_page = session[:pack_groups_counts_configs_page]
	 id = params[:pack_groups_counts_config][:id]
	 if id && @pack_groups_counts_config = PackGroupsCountsConfig.find(id)
		 if @pack_groups_counts_config.update_attributes(params[:pack_groups_counts_config])
			@pack_groups_counts_configs = eval(session[:query])
			render_list_pack_groups_counts_configs
	 else
			 render_edit_pack_groups_counts_config

		 end
	 end
   rescue
     handle_error("record could not be updated")
   end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: standard_count_id
#	---------------------------------------------------------------------------------
def pack_groups_counts_config_commodity_code_changed
	commodity_code = get_selected_combo_value(params)
	session[:pack_groups_counts_config_form][:commodity_code_combo_selection] = commodity_code
	@standard_size_count_values = PackGroupsCountsConfig.standard_size_count_values_for_commodity_code(commodity_code)
    @size_codes = size_codes = Size.find_all_by_commodity_code(commodity_code).map{|s|s.size_code}
    @size_codes.unshift "<empty>"
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('pack_groups_counts_config','standard_size_count_value',@standard_size_count_values)%>
        <% size_code_content = select('pack_groups_counts_config','size_code',@size_codes) %>
		<script>
          <%= update_element_function(
            "size_code_cell", :action => :update,
            :content => size_code_content) %>
		</script> }

end



end
