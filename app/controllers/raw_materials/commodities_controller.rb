class  RawMaterials::CommoditiesController < ApplicationController
 
def program_name?
	"commodities"
end

def bypass_generic_security?
	true
end

#=====================
#commodity groups code
#=====================
def list_commodity_groups
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:commodity_groups_page] = params['page']

		 render_list_commodity_groups

		 return 
	else
		session[:commodity_groups_page] = nil
	end

	list_query = "@commodity_group_pages = Paginator.new self, CommodityGroup.count, @@page_size,@current_page
	 @commodity_groups = CommodityGroup.find(:all,
				 :limit => @commodity_group_pages.items_per_page,
				 :offset => @commodity_group_pages.current.offset)"
	session[:query] = list_query
	render_list_commodity_groups
end


def render_list_commodity_groups
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:commodity_groups_page] if session[:commodity_groups_page]
	@current_page = params['page'] if params['page']
	@commodity_groups =  eval(session[:query]) if !@commodity_groups
	render :inline => %{
      <% grid            = build_commodity_group_grid(@commodity_groups,@can_edit,@can_delete) %>
      <% grid.caption    = 'List of all commodity_groups' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@commodity_group_pages) if @commodity_group_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_commodity_groups_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_commodity_group_search_form
end

def render_commodity_group_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  commodity_groups'"%> 

		<%= build_commodity_group_search_form(nil,'submit_commodity_groups_search','submit_commodity_groups_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_commodity_groups_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_commodity_group_search_form(true)
end

def render_commodity_group_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  commodity_groups'"%> 

		<%= build_commodity_group_search_form(nil,'submit_commodity_groups_search','submit_commodity_groups_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_commodity_groups_search
	if params['page']
		session[:commodity_groups_page] =params['page']
	else
		session[:commodity_groups_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @commodity_groups = dynamic_search(params[:commodity_group] ,'commodity_groups','CommodityGroup')
	else
		@commodity_groups = eval(session[:query])
	end
	if @commodity_groups.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_commodity_group_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_commodity_groups
		end

	else

		render_list_commodity_groups
	end
end

 
def delete_commodity_group
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:commodity_groups_page] = params['page']
		render_list_commodity_groups
		return
	end
	id = params[:id]
	if id && commodity_group = CommodityGroup.find(id)
		commodity_group.destroy
		session[:alert] = " Record deleted."
		render_list_commodity_groups
	end
  rescue
    handle_error("commodity group could not be deleted")
  end
end
 
def new_commodity_group
	return if authorise_for_web(program_name?,'create')== false
		render_new_commodity_group
end
 
def create_commodity_group
  begin
	 @commodity_group = CommodityGroup.new(params[:commodity_group])
	 if @commodity_group.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_commodity_group
	 end
   rescue
    handle_error("commodity group could not be created")
  end
end

def render_new_commodity_group
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new commodity_group'"%> 

		<%= build_commodity_group_form(@commodity_group,'create_commodity_group','create_commodity_group',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_commodity_group
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @commodity_group = CommodityGroup.find(id)
		render_edit_commodity_group

	 end
end


def render_edit_commodity_group
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit commodity_group'"%> 

		<%= build_commodity_group_form(@commodity_group,'update_commodity_group','update_commodity_group',true)%>

		}, :layout => 'content'
end
 
def update_commodity_group
  begin
	if params[:page]
		session[:commodity_groups_page] = params['page']
		render_list_commodity_groups
		return
	end

		@current_page = session[:commodity_groups_page]
	 id = params[:commodity_group][:id]
	 if id && @commodity_group = CommodityGroup.find(id)
		 if @commodity_group.update_attributes(params[:commodity_group])
			@commodity_groups = eval(session[:query])
			render_list_commodity_groups
	 else
			 render_edit_commodity_group

		 end
	 end
  rescue
    handle_error("commodity group could not be updated")
  end
 end

#================
#commodities code
#================


def list_commodities
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:commodities_page] = params['page']

		 render_list_commodities

		 return 
	else
		session[:commodities_page] = nil
	end

	list_query = "@commodity_pages = Paginator.new self, Commodity.count, @@page_size,@current_page
	 @commodities = Commodity.find(:all,
				 :limit => @commodity_pages.items_per_page,
				 :offset => @commodity_pages.current.offset)"
	session[:query] = list_query
	render_list_commodities
end


def render_list_commodities
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:commodities_page] if session[:commodities_page]
	@current_page = params['page'] if params['page']
	@commodities =  eval(session[:query]) if !@commodities
	render :inline => %{
      <% grid            = build_commodity_grid(@commodities,@can_edit,@can_delete) %>
      <% grid.caption    = 'List of all commodities' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@commodity_pages) if @commodity_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_commodities_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_commodity_search_form
end

def render_commodity_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  commodities'"%> 

		<%= build_commodity_search_form(nil,'submit_commodities_search','submit_commodities_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_commodities_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_commodity_search_form(true)
end

def render_commodity_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  commodities'"%> 

		<%= build_commodity_search_form(nil,'submit_commodities_search','submit_commodities_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_commodities_search
	if params['page']
		session[:commodities_page] =params['page']
	else
		session[:commodities_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @commodities = dynamic_search(params[:commodity] ,'commodities','Commodity')
	else
		@commodities = eval(session[:query])
	end
	if @commodities.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_commodity_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_commodities
		end

	else

		render_list_commodities
	end
end

 
def delete_commodity
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:commodities_page] = params['page']
		render_list_commodities
		return
	end
	id = params[:id]
	if id && commodity = Commodity.find(id)
		commodity.destroy
		session[:alert] = " Record deleted."
		render_list_commodities
	end
  rescue
    handle_error("commodity could not be deleted")
  end
	
end
 
def new_commodity
	return if authorise_for_web(program_name?,'create')== false
		render_new_commodity
end
 
def create_commodity
  begin
	 @commodity = Commodity.new(params[:commodity])
	 if @commodity.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_commodity
	 end
   rescue
    handle_error("commodity could not be created")
  end
end

def render_new_commodity
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new commodity'"%> 

		<%= build_commodity_form(@commodity,'create_commodity','create_commodity',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_commodity
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @commodity = Commodity.find(id)
		render_edit_commodity

	 end
end


def render_edit_commodity
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit commodity'"%> 

		<%= build_commodity_form(@commodity,'update_commodity','update_commodity',true)%>

		}, :layout => 'content'
end
 
def update_commodity
  begin
	if params[:page]
		session[:commodities_page] = params['page']
		render_list_commodities
		return
	end

		@current_page = session[:commodities_page]
	 id = params[:commodity][:id]
	 if id && @commodity = Commodity.find(id)
		 if @commodity.update_attributes(params[:commodity])
			@commodities = eval(session[:query])
			render_list_commodities
	 else
			 render_edit_commodity

		 end
	 end
 end
 rescue
    handle_error("commodity group could not be updated")
  end

end
