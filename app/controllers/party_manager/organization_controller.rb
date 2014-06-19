class  PartyManager::OrganizationController < ApplicationController
 
def program_name?
	"organization"
end

def bypass_generic_security?
	true
end

#===========
#MARKS CODE
#===========
def list_marks_organizations
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:marks_organizations_page] = params['page']

		 render_list_marks_organizations

		 return 
	else
		session[:marks_organizations_page] = nil
	end

	list_query = "@marks_organization_pages = Paginator.new self, MarksOrganization.count, @@page_size,@current_page
	 @marks_organizations = MarksOrganization.find(:all,
				 :limit => @marks_organization_pages.items_per_page,
				 :offset => @marks_organization_pages.current.offset)"
	session[:query] = list_query
	render_list_marks_organizations
end


def render_list_marks_organizations
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:marks_organizations_page] if session[:marks_organizations_page]
	@current_page = params['page'] if params['page']
	@marks_organizations =  eval(session[:query]) if !@marks_organizations
	render :inline => %{
      <% grid            = build_marks_organization_grid(@marks_organizations,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all marks_organizations' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@marks_organization_pages) if @marks_organization_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_marks_organizations_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_marks_organization_search_form
end

def render_marks_organization_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  marks_organizations'"%> 

		<%= build_marks_organization_search_form(nil,'submit_marks_organizations_search','submit_marks_organizations_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def find_org_mark
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_marks_organization_search_form(true)
end

def render_marks_organization_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  marks_organizations'"%> 

		<%= build_marks_organization_search_form(nil,'submit_marks_organizations_search','submit_marks_organizations_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_marks_organizations_search
	if params['page']
		session[:marks_organizations_page] =params['page']
	else
		session[:marks_organizations_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @marks_organizations = dynamic_search(params[:marks_organization] ,'marks_organizations','MarksOrganization')
	else
		@marks_organizations = eval(session[:query])
	end
	if @marks_organizations.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_marks_organization_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_marks_organizations
		end

	else

		render_list_marks_organizations
	end
end

 
def delete_marks_organization
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:marks_organizations_page] = params['page']
		render_list_marks_organizations
		return
	end
	id = params[:id]
	if id && marks_organization = MarksOrganization.find(id)
		marks_organization.destroy
		session[:alert] = " Record deleted."
		render_list_marks_organizations
	end
   rescue
     handle_error("mark could not be removed from organization")
   end
end
 
def add_org_mark
	return if authorise_for_web(program_name?,'create')== false
		render_new_marks_organization
end
 
def create_marks_organization
  begin
	 @marks_organization = MarksOrganization.new(params[:marks_organization])
	 if @marks_organization.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_marks_organization
	 end
   rescue
     handle_error("Mark code could not be added to organization")
   end
end

def render_new_marks_organization
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new marks_organization'"%> 

		<%= build_marks_organization_form(@marks_organization,'create_marks_organization','create_marks_organization',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_marks_organization
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @marks_organization = MarksOrganization.find(id)
		render_edit_marks_organization

	 end
end


def render_edit_marks_organization
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit marks_organization'"%> 

		<%= build_marks_organization_form(@marks_organization,'update_marks_organization','update_marks_organization',true)%>

		}, :layout => 'content'
end
 
def update_marks_organization
   begin
	if params[:page]
		session[:marks_organizations_page] = params['page']
		render_list_marks_organizations
		return
	end

		@current_page = session[:marks_organizations_page]
	 id = params[:marks_organization][:id]
	 if id && @marks_organization = MarksOrganization.find(id)
		 if @marks_organization.update_attributes(params[:marks_organization])
			@marks_organizations = eval(session[:query])
			render_list_marks_organizations
	 else
			 render_edit_marks_organization

		 end
	 end
  rescue
     handle_error("Mark org association could not be updated")
   end
 end
 

def marks_organization_short_description_search_combo_changed
	short_description = get_selected_combo_value(params)
	session[:marks_organization_search_form][:short_description_combo_selection] = short_description
	@mark_codes = MarksOrganization.find_by_sql("Select distinct mark_code from marks_organizations where short_description = '#{short_description}'").map{|g|[g.mark_code]}
	@mark_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('marks_organization','mark_code',@mark_codes)%>

		}

end


#=======================
#INVENTORY CODES CODE
#=======================
def list_inventory_codes_organizations
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:inventory_codes_organizations_page] = params['page']

		 render_list_inventory_codes_organizations

		 return 
	else
		session[:inventory_codes_organizations_page] = nil
	end

	list_query = "@inventory_codes_organization_pages = Paginator.new self, InventoryCodesOrganization.count, @@page_size,@current_page
	 @inventory_codes_organizations = InventoryCodesOrganization.find(:all,
				 :limit => @inventory_codes_organization_pages.items_per_page,
				 :offset => @inventory_codes_organization_pages.current.offset)"
	session[:query] = list_query
	render_list_inventory_codes_organizations
end


def render_list_inventory_codes_organizations
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:inventory_codes_organizations_page] if session[:inventory_codes_organizations_page]
	@current_page = params['page'] if params['page']
	@inventory_codes_organizations =  eval(session[:query]) if !@inventory_codes_organizations
	render :inline => %{
      <% grid            = build_inventory_codes_organization_grid(@inventory_codes_organizations,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all inventory_codes_organizations' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@inventory_codes_organization_pages) if @inventory_codes_organization_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_inventory_codes_organizations_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_inventory_codes_organization_search_form
end

def render_inventory_codes_organization_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  inventory_codes_organizations'"%> 

		<%= build_inventory_codes_organization_search_form(nil,'submit_inventory_codes_organizations_search','submit_inventory_codes_organizations_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def find_org_inventory_code
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_inventory_codes_organization_search_form(true)
end

def render_inventory_codes_organization_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  inventory_codes_organizations'"%> 

		<%= build_inventory_codes_organization_search_form(nil,'submit_inventory_codes_organizations_search','submit_inventory_codes_organizations_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_inventory_codes_organizations_search
	if params['page']
		session[:inventory_codes_organizations_page] =params['page']
	else
		session[:inventory_codes_organizations_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @inventory_codes_organizations = dynamic_search(params[:inventory_codes_organization] ,'inventory_codes_organizations','InventoryCodesOrganization')
	else
		@inventory_codes_organizations = eval(session[:query])
	end
	if @inventory_codes_organizations.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_inventory_codes_organization_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_inventory_codes_organizations
		end

	else

		render_list_inventory_codes_organizations
	end
end

 
def delete_inventory_codes_organization
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:inventory_codes_organizations_page] = params['page']
		render_list_inventory_codes_organizations
		return
	end
	id = params[:id]
	if id && inventory_codes_organization = InventoryCodesOrganization.find(id)
		inventory_codes_organization.destroy
		session[:alert] = " Record deleted."
		render_list_inventory_codes_organizations
	end
   rescue
     handle_error("inventory code could not be removed from organization")
   end
end
 
def add_org_inventory_code
	return if authorise_for_web(program_name?,'create')== false
		render_new_inventory_codes_organization
end
 
def create_inventory_codes_organization
  begin
	 @inventory_codes_organization = InventoryCodesOrganization.new(params[:inventory_codes_organization])
	 if @inventory_codes_organization.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_inventory_codes_organization
	 end
  rescue
     handle_error("inventory code could not be added to organization")
   end
end

def render_new_inventory_codes_organization
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new inventory_codes_organization'"%> 

		<%= build_inventory_codes_organization_form(@inventory_codes_organization,'create_inventory_codes_organization','create_inventory_codes_organization',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_inventory_codes_organization
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @inventory_codes_organization = InventoryCodesOrganization.find(id)
		render_edit_inventory_codes_organization

	 end
end


def render_edit_inventory_codes_organization
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit inventory_codes_organization'"%> 

		<%= build_inventory_codes_organization_form(@inventory_codes_organization,'update_inventory_codes_organization','update_inventory_codes_organization',true)%>

		}, :layout => 'content'
end
 
def update_inventory_codes_organization
  begin
	if params[:page]
		session[:inventory_codes_organizations_page] = params['page']
		render_list_inventory_codes_organizations
		return
	end

		@current_page = session[:inventory_codes_organizations_page]
	 id = params[:inventory_codes_organization][:id]
	 if id && @inventory_codes_organization = InventoryCodesOrganization.find(id)
		 if @inventory_codes_organization.update_attributes(params[:inventory_codes_organization])
			@inventory_codes_organizations = eval(session[:query])
			render_list_inventory_codes_organizations
	 else
			 render_edit_inventory_codes_organization

		 end
	 end
  rescue
     handle_error("inventory code org association could not be updated")
   end
 end

#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(inventory_codes_organizations)
#	-----------------------------------------------------------------------------------------------------------
def inventory_codes_organization_short_description_search_combo_changed
	short_description = get_selected_combo_value(params)
	@inventory_codes = InventoryCodesOrganization.find_by_sql("Select distinct inv_code from inventory_codes_organizations where short_description = '#{short_description}'").map{|g|[g.inv_code]}
	@inventory_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('inventory_codes_organization','inv_code',@inventory_codes)%>

		}

end



#==================
#TARGET MARKET CODE
#==================
def list_organizations_target_markets
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:organizations_target_markets_page] = params['page']

		 render_list_organizations_target_markets

		 return 
	else
		session[:organizations_target_markets_page] = nil
	end

	list_query = "@organizations_target_market_pages = Paginator.new self, OrganizationsTargetMarket.count, @@page_size,@current_page
	 @organizations_target_markets = OrganizationsTargetMarket.find(:all,
				 :limit => @organizations_target_market_pages.items_per_page,
				 :offset => @organizations_target_market_pages.current.offset)"
	session[:query] = list_query
	render_list_organizations_target_markets
end


def render_list_organizations_target_markets
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:organizations_target_markets_page] if session[:organizations_target_markets_page]
	@current_page = params['page'] if params['page']
	@organizations_target_markets =  eval(session[:query]) if !@organizations_target_markets
	render :inline => %{
      <% grid            = build_organizations_target_market_grid(@organizations_target_markets,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all organizations_target_markets' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@organizations_target_market_pages) if @organizations_target_market_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_organizations_target_markets_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_organizations_target_market_search_form
end

def render_organizations_target_market_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  organizations_target_markets'"%> 

		<%= build_organizations_target_market_search_form(nil,'submit_organizations_target_markets_search','submit_organizations_target_markets_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def find_org_target_market
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_organizations_target_market_search_form(true)
end

def render_organizations_target_market_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  organizations_target_markets'"%> 

		<%= build_organizations_target_market_search_form(nil,'submit_organizations_target_markets_search','submit_organizations_target_markets_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_organizations_target_markets_search
	if params['page']
		session[:organizations_target_markets_page] =params['page']
	else
		session[:organizations_target_markets_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @organizations_target_markets = dynamic_search(params[:organizations_target_market] ,'organizations_target_markets','OrganizationsTargetMarket')
	else
		@organizations_target_markets = eval(session[:query])
	end
	if @organizations_target_markets.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_organizations_target_market_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_organizations_target_markets
		end

	else

		render_list_organizations_target_markets
	end
end

 
def delete_organizations_target_market
   begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:organizations_target_markets_page] = params['page']
		render_list_organizations_target_markets
		return
	end
	id = params[:id]
	if id && organizations_target_market = OrganizationsTargetMarket.find(id)
		organizations_target_market.destroy
		session[:alert] = " Record deleted."
		render_list_organizations_target_markets
	end
   rescue
     handle_error("target market could not be removed from organization")
   end
end
 
def add_org_target_market
	return if authorise_for_web(program_name?,'create')== false
		render_new_organizations_target_market
end
 
def create_organizations_target_market
  begin
	 @organizations_target_market = OrganizationsTargetMarket.new(params[:organizations_target_market])
	 if @organizations_target_market.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_organizations_target_market
	 end
  rescue
     handle_error("target market could not be added to organization")
   end
end

def render_new_organizations_target_market
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new organizations_target_market'"%> 

		<%= build_organizations_target_market_form(@organizations_target_market,'create_organizations_target_market','create_organizations_target_market',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_organizations_target_market
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @organizations_target_market = OrganizationsTargetMarket.find(id)
		render_edit_organizations_target_market

	 end
end


def render_edit_organizations_target_market
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit organizations_target_market'"%> 

		<%= build_organizations_target_market_form(@organizations_target_market,'update_organizations_target_market','update_organizations_target_market',true)%>

		}, :layout => 'content'
end
 
def update_organizations_target_market
  begin
	if params[:page]
		session[:organizations_target_markets_page] = params['page']
		render_list_organizations_target_markets
		return
	end

		@current_page = session[:organizations_target_markets_page]
	 id = params[:organizations_target_market][:id]
	 if id && @organizations_target_market = OrganizationsTargetMarket.find(id)
		 if @organizations_target_market.update_attributes(params[:organizations_target_market])
			@organizations_target_markets = eval(session[:query])
			render_list_organizations_target_markets
	 else
			 render_edit_organizations_target_market

		 end
	 end
  rescue
     handle_error("target market org association could not be updated")
   end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: organization_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: target_market_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(organizations_target_markets)
#	-----------------------------------------------------------------------------------------------------------
def organizations_target_market_short_description_search_combo_changed
	short_description = get_selected_combo_value(params)
	session[:organizations_target_market_search_form][:short_description_combo_selection] = short_description
	@target_market_names = OrganizationsTargetMarket.find_by_sql("Select distinct target_market_name from organizations_target_markets where short_description = '#{short_description}'").map{|g|[g.target_market_name]}
	@target_market_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('organizations_target_market','target_market_name',@target_market_names)%>

		}

end


#===================
#ORGANIZATIONS CODE
#===================
def list_organizations
	return if authorise_for_web('organization','read') == false 

 	if params[:page]!= nil 

 		session[:organizations_page] = params['page']

		 render_list_organizations

		 return 
	else
		session[:organizations_page] = nil
	end

	list_query = "@organization_pages = Paginator.new self, Organization.count, @@page_size,@current_page
	 @organizations = Organization.find(:all,
				 :limit => @organization_pages.items_per_page,
				 :offset => @organization_pages.current.offset)"
	session[:query] = list_query
	render_list_organizations
end


def render_list_organizations
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:organizations_page] if session[:organizations_page]
	@current_page = params['page'] if params['page']
	@organizations =  eval(session[:query]) if !@organizations
	render :inline => %{
      <% grid            = build_organization_grid(@organizations,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all organizations' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@organization_pages) if @organization_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_organizations_flat
	return if authorise_for_web('organization','read')== false
	@is_flat_search = true 
	render_organization_search_form
end

def render_organization_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  organizations'"%> 

		<%= build_organization_search_form(nil,'submit_organizations_search','submit_organizations_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_organizations_hierarchy
	return if authorise_for_web('organization','read')== false
 
	@is_flat_search = false 
	render_organization_search_form(true)
end

def render_organization_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  organizations'"%> 

		<%= build_organization_search_form(nil,'submit_organizations_search','submit_organizations_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_organizations_search
	if params['page']
		session[:organizations_page] =params['page']
	else
		session[:organizations_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @organizations = dynamic_search(params[:organization] ,'organizations','Organization')
	else
		@organizations = eval(session[:query])
	end
	if @organizations.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_organization_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_organizations
		end

	else

		render_list_organizations
	end
end

 
def delete_organization
  begin
    return if authorise_for_web('organization','delete')== false
    if params[:page]
      session[:organizations_page] = params['page']
      render_list_organizations
      return
    end

    id = params[:id]
    ActiveRecord::Base.transaction do
      if id && @organization = Organization.find(id)
        org_code = @organization.short_description
        @organization.destroy
        Organization.update_all(ActiveRecord::Base.extend_set_sql_with_request("parent_org_short_description = Null","organizations"),"parent_org_short_description = '#{org_code}'")
        if(@remove)
         @node_name = org_code
         @node_type = "organization"
         @node_id = id.to_s
         @tree_name = "organizations"
         @remove = false
         render :inline => %{
                          <% @hide_content_pane = true %>
                          <% @is_menu_loaded_view = true %>
                          <% @tree_actions = "window.parent.RemoveNode(null);" %>
                          }, :layout => 'tree_node_content'
        else
          @remove = false
          session[:alert] = " Record deleted."
          render_list_organizations
        end
      end
    end
   rescue
     if(@remove)
      @remove = false
      render :inline => %{
                        <% @hide_content_pane = true %>
                        <% @is_menu_loaded_view = false %>
                        }, :layout => 'tree_node_content'
     else
      handle_error("organization could not be deleted")
     end
   end
end
 
def new_organization
	return if authorise_for_web('organization','create')== false
		render_new_organization
end
 
def create_organization
   begin
	 @organization = Organization.new(params[:organization])
   if(session[:organization])
     parent_organization = Organization.find(session[:organization])
     @organization.parent_org_short_description = parent_organization.short_description
     #PARTY ID?????
    if @organization.save
      @node_name = @organization.short_description
      @node_type = "organization"
      @node_id = @organization.id.to_s
      @tree_name = "organizations"

      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = false %>

                      <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>

                      }, :layout => 'tree_node_content'
    else
      flash[:notice] = "'could not create organization'"
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = false %>
                      }, :layout => 'tree_node_content'
    end
   else
    if @organization.save
      redirect_to_index("'new record created successfully'","'create successful'")
    else
      @is_create_retry = true
      render_new_organization
    end
   end
  rescue
     handle_error("organization could not be created")
   end
end

def render_new_organization
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new organization'"%> 

		<%= build_organization_form(@organization,'create_organization','create_organization',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_organization
	return if authorise_for_web('organization','edit')==false 
	 id = params[:id]
	 if id && @organization = Organization.find(id)
		render_edit_organization

	 end
end


def render_edit_organization
#	 render (inline) the edit template
    session[:editing_org]=@organization
	render :inline => %{
		<% @content_header_caption = "'edit organization'"%> 

		<%= build_organization_form(@organization,'update_organization','update_organization',true)%>

		}, :layout => 'content'
end
 
def update_organization
  begin
	if params[:page]
		session[:organizations_page] = params['page']
		render_list_organizations
		return
	end

		@current_page = session[:organizations_page]
	 id = params[:organization][:id]
	 if id && @organization = Organization.find(id)
     ActiveRecord::Base.transaction do
       @organization.update_attributes(params[:organization])
       parties_role = PartiesRole.find_by_party_name(session[:editing_org]['short_description'])
       if parties_role
         parties_role.party_name=params[:organization][:short_description]
         parties_role.update
       end
      end
		 if @organization

			@organizations = eval(session[:query])
			flash[:notice] = "organization updated"
      session[:editing_org]=nil
			render_list_organizations
     else
       session[:editing_org]=nil
			 render_edit_organization
		 end
	 end
	rescue
	 handle_error("organization could not be updated")
	end
 end

#--------------------------------
#----- Luks' additional methods -
#--------------------------------
def parent_organization
   child_organization = Organization.find(params[:id])
   @parent_organization = Organization.find_by_short_description(child_organization.parent_org_short_description) if child_organization.parent_org_short_description
   if !@parent_organization
     flash[:notice] = "'organization[ " + child_organization.short_description + " ] does not have a parent'"
     render_list_organizations
   else
    @content_header_caption = "'organization tree for organization = " + child_organization.short_description + "'"
    render :inline => %{
                      <% @tree_script = build_organizations_tree(@parent_organization) %>
                      }, :layout => 'tree'
   end
 end

def add_child_organization
   session[:organization] = params[:id]
   @organization = Organization.find(params[:id])
   @tree_node_content_header = "select child organization"
   @hide_content_pane = false
   @is_menu_loaded_view = true
   render :inline => %{
                        <%= build_add_child_organization_form(@organization,'save_child_organization','add')%>
                        },:layout => "tree_node_content"
 end

def save_child_organization
  begin
     @parent_organization = Organization.find(session[:organization])
     @child_organization = Organization.find_by_short_description(params[:organization][:short_description])
     @child_organization.update_attribute(:parent_org_short_description,@parent_organization.short_description).to_s

     flash[:notice] = "organization added successfully"
     @node_name = @child_organization.short_description
     @node_type = "organization"
     @node_id = @child_organization.id.to_s
     @tree_name = "organizations"

		 render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = false %>

                      <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>

                      }, :layout => 'tree_node_content'

   rescue
     flash[:notice] = "could not add organization"
     render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = false %>
                      }, :layout => 'tree_node_content'
   end
end

def remove_from_parent
   begin
     @child_organization = Organization.find(params[:id])
     @child_organization.update_attribute(:parent_org_short_description,nil).to_s

     flash[:notice] = "organization removed from parent successfully"
		 render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>

                      <% @tree_actions = "window.parent.RemoveNode(null);" %>

                      }, :layout => 'tree_node_content'
   rescue
     flash[:notice] = "could not remove organization from parent"
     render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = false %>
                      }, :layout => 'tree_node_content'
   end
 end

def delete_and_remove_organization
  @remove = true
  delete_organization
end

def create_and_add_organization
   session[:organization] = params[:id]
   @add_organization = true
   @tree_node_content_header = "create new organisation"
   @hide_content_pane = false
   @is_menu_loaded_view = true
    render :inline=> %{
                       <%= build_organization_form(@organization,'create_organization','create_organization',false,false,@add_organization)  %>
                       }, :layout => 'tree_node_content'
end

def child_organizations
  session[:organization] = params[:id]
  @parent_organization = Organization.find(session[:organization])
  @content_header_caption = "'location tree for location = " + @parent_organization.short_description + "'"
  render :inline => %{
                      <% @tree_script = build_organizations_tree(@parent_organization) %>
                      }, :layout => 'tree'
end
#--------------------------------
#----- Luks' additional methods -
#--------------------------------

#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: party_id
#	---------------------------------------------------------------------------------
def organization_party_type_name_changed
	party_type_name = get_selected_combo_value(params)
	session[:organization_form][:party_type_name_combo_selection] = party_type_name
	@party_names = Organization.party_names_for_party_type_name(party_type_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('organization','party_name',@party_names)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(organizations)
#	-----------------------------------------------------------------------------------------------------------

end
