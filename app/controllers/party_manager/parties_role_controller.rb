class  PartyManager::PartiesRoleController < ApplicationController
 
def program_name?
	"parties_role"
end

def bypass_generic_security?
	true
end

def list_roles
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:roles_page] = params['page']

		 render_list_roles

		 return 
	else
		session[:roles_page] = nil
	end

	list_query = "@role_pages = Paginator.new self, Role.count, @@page_size,@current_page
	 @roles = Role.find(:all,
				 :limit => @role_pages.items_per_page,
				 :offset => @role_pages.current.offset)"
	session[:query] = list_query
	render_list_roles
end


def render_list_roles
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:roles_page] if session[:roles_page]
	@current_page = params['page'] if params['page']
	@roles =  eval(session[:query]) if !@roles
	render :inline => %{
      <% grid            = build_role_grid(@roles,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all roles' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@role_pages) if @role_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_roles_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_role_search_form
end

def render_role_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  roles'"%> 

		<%= build_role_search_form(nil,'submit_roles_search','submit_roles_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_roles_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_role_search_form(true)
end

def render_role_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  roles'"%> 

		<%= build_role_search_form(nil,'submit_roles_search','submit_roles_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_roles_search
	if params['page']
		session[:roles_page] =params['page']
	else
		session[:roles_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @roles = dynamic_search(params[:role] ,'roles','Role')
	else
		@roles = eval(session[:query])
	end
	if @roles.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_role_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_roles
		end

	else

		render_list_roles
	end
end

 
def delete_role
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:roles_page] = params['page']
		render_list_roles
		return
	end
	id = params[:id]
	if id && role = Role.find(id)
		role.destroy
		session[:alert] = " Record deleted."
		render_list_roles
	end
  rescue
     handle_error("Role could not be deleted")
   end
end
 
def new_role
	return if authorise_for_web(program_name?,'create')== false
		render_new_role
end
 
def create_role
  begin
	 @role = Role.new(params[:role])
	 if @role.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_role
	 end
  rescue
     handle_error("Role could not be created")
   end
end

def render_new_role
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new role'"%> 

		<%= build_role_form(@role,'create_role','create_role',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_role
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @role = Role.find(id)
		render_edit_role

	 end
end


def render_edit_role
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit role'"%> 

		<%= build_role_form(@role,'update_role','update_role',true)%>

		}, :layout => 'content'
end
 
def update_role
  begin
	if params[:page]
		session[:roles_page] = params['page']
		render_list_roles
		return
	end

		@current_page = session[:roles_page]
	 id = params[:role][:id]
	 if id && @role = Role.find(id)
		 if @role.update_attributes(params[:role])
			@roles = eval(session[:query])
			render_list_roles
	 else
			 render_edit_role

		 end
	 end
	rescue
     handle_error("Role could not be updated")
   end
 end
 

#===================
#PARTIES ROLES CODE
#===================
def list_parties_roles
	return if authorise_for_web('parties_role','read') == false 

 	if params[:page]!= nil 

 		session[:parties_roles_page] = params['page']

		 render_list_parties_roles

		 return 
	else
		session[:parties_roles_page] = nil
	end

	# list_query = "@parties_role_pages = Paginator.new self, PartiesRole.count, @@page_size,@current_page
	#  @parties_roles = PartiesRole.find(:all,
	# 			 :limit => @parties_role_pages.items_per_page,
	# 			 :offset => @parties_role_pages.current.offset)"
	list_query = "@parties_roles = PartiesRole.find(:all, :order => 'party_name')"
	session[:query] = list_query
	render_list_parties_roles
end


def render_list_parties_roles
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:parties_roles_page] if session[:parties_roles_page]
	@current_page = params['page'] if params['page']
	@parties_roles =  eval(session[:query]) if !@parties_roles
	render :inline => %{
      <% grid            = build_parties_role_grid(@parties_roles,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all parties_roles' %>
      <% @header_content = grid.build_grid_data %>

      <%# @pagination = pagination_links(@parties_role_pages) if @parties_role_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_parties_roles_flat
	return if authorise_for_web('parties_role','read')== false
	@is_flat_search = true 
	render_parties_role_search_form
end

def render_parties_role_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  parties_roles'"%> 

		<%= build_parties_role_search_form(nil,'submit_parties_roles_search','submit_parties_roles_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_parties_roles_hierarchy
	return if authorise_for_web('parties_role','read')== false
 
	@is_flat_search = false 
	render_parties_role_search_form(true)
end

def render_parties_role_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  parties_roles'"%> 

		<%= build_parties_role_search_form(nil,'submit_parties_roles_search','submit_parties_roles_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_parties_roles_search
	if params['page']
		session[:parties_roles_page] =params['page']
	else
		session[:parties_roles_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @parties_roles = dynamic_search(params[:parties_role] ,'parties_roles','PartiesRole')
	else
		@parties_roles = eval(session[:query])
	end
	if @parties_roles.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_parties_role_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_parties_roles
		end

	else

		render_list_parties_roles
	end
end

 
def delete_parties_role
  begin
	return if authorise_for_web('parties_role','delete')== false
	if params[:page]
		session[:parties_roles_page] = params['page']
		render_list_parties_roles
		return
	end
	id = params[:id]
	if id && parties_role = PartiesRole.find(id)
		parties_role.destroy
		session[:alert] = " Record deleted."
		render_list_parties_roles
	end
  rescue
     handle_error("Party-role association could not be deleted")
   end
end
 
def new_parties_role
	return if authorise_for_web('parties_role','create')== false
		render_new_parties_role
end
 
def create_parties_role
  begin
	 @parties_role = PartiesRole.new(params[:parties_role])
	 if @parties_role.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_parties_role
	 end
  rescue
     handle_error("Party-role association could not be created")
   end
end

def render_new_parties_role
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new parties_role'"%> 

		<%= build_parties_role_form(@parties_role,'create_parties_role','create_parties_role',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_parties_role
	return if authorise_for_web('parties_role','edit')==false 
	 id = params[:id]
	 if id && @parties_role = PartiesRole.find(id)
		render_edit_parties_role

	 end
end


def render_edit_parties_role
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit parties_role'"%> 

		<%= build_parties_role_form(@parties_role,'update_parties_role','update_parties_role',true)%>

		}, :layout => 'content'
end
 
def update_parties_role
  begin
	if params[:page]
		session[:parties_roles_page] = params['page']
		render_list_parties_roles
		return
	end

		@current_page = session[:parties_roles_page]
	 id = params[:parties_role][:id]
	 if id && @parties_role = PartiesRole.find(id)
		 if @parties_role.update_attributes(params[:parties_role])
			@parties_roles = eval(session[:query])
			render_list_parties_roles
	 else
			 render_edit_parties_role

		 end
	 end
	rescue
     handle_error("Party-role association could not be updated")
   end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: role_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: party_id
#	---------------------------------------------------------------------------------
def parties_role_party_type_name_changed
	party_type_name = get_selected_combo_value(params)
	session[:parties_role_form][:party_type_name_combo_selection] = party_type_name
	@party_names = PartiesRole.party_names_for_party_type_name(party_type_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{

		<%val = select('parties_role','party_name',@party_names)

            return val %>
		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(parties_roles)
#	-----------------------------------------------------------------------------------------------------------
def parties_role_party_type_name_search_combo_changed
	party_type_name = get_selected_combo_value(params)
	session[:parties_role_search_form][:party_type_name_combo_selection] = party_type_name
	@party_names = PartiesRole.find_by_sql("Select distinct party_name from parties_roles where party_type_name = '#{party_type_name}'").map{|g|[g.party_name]}
	@party_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('parties_role','party_name',@party_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_parties_role_party_name'/>
		<%= observe_field('parties_role_party_name',:update => 'role_name_cell',:url => {:action => session[:parties_role_search_form][:party_name_observer][:remote_method]},:loading => "show_element('img_parties_role_party_name');",:complete => session[:parties_role_search_form][:party_name_observer][:on_completed_js])%>
		}

end


def parties_role_party_name_search_combo_changed
	party_name = get_selected_combo_value(params)
	session[:parties_role_search_form][:party_name_combo_selection] = party_name
	party_type_name = 	session[:parties_role_search_form][:party_type_name_combo_selection]
	@role_names = PartiesRole.find_by_sql("Select distinct role_name from parties_roles where party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.role_name]}
	@role_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('parties_role','role_name',@role_names)%>

		}

end

  def rename_party
    @party = Party.find(params[:id])
    @party.new_name = @party.party_name
    if 'PERSON' == @party.party_type_name
      person = Person.find_by_party_id(params[:id])
      @party.new_first_name = person.first_name
      @party.new_last_name  = person.last_name
    end
    render_rename_party
  end

  def render_rename_party
    render :inline => %{
      <% @content_header_caption = "'rename party'"%>

      <%= build_rename_party_form(@party,'save_new_party_name','save_new_party_name',true)%>

      }, :layout => 'content'
  end

  def save_new_party_name
    @party = Party.find(params[:party][:id])
    if Party.rename_party(@party.party_name, params[:party])
      @parties = eval(session[:query])
      if 'PERSON' == @party.party_type_name
        flash[:notice] = 'Person and party renamed'
      else
        flash[:notice] = "Organisation and party renamed. <br>NB. The organisation's medium and long descriptions have not been changed."
      end
      redirect_to_last_grid
#      list_parties
    else
      render_rename_party
    end
  rescue
    handle_error('record could not be saved')
  end



end
