class  PartyManager::FarmController < ApplicationController
 
def program_name?
	"farm"
end

def bypass_generic_security?
	true
end

#================
#FARM PUC ACCOUNT
#================

def list_farm_puc_accounts
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:farm_puc_accounts_page] = params['page']

		 render_list_farm_puc_accounts

		 return 
	else
		session[:farm_puc_accounts_page] = nil
	end

	list_query = "@farm_puc_account_pages = Paginator.new self, FarmPucAccount.count, @@page_size,@current_page
	 @farm_puc_accounts = FarmPucAccount.find(:all,
				 :limit => @farm_puc_account_pages.items_per_page,
				 :offset => @farm_puc_account_pages.current.offset)"
	session[:query] = list_query
	render_list_farm_puc_accounts
end


def render_list_farm_puc_accounts
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:farm_puc_accounts_page] if session[:farm_puc_accounts_page]
	@current_page = params['page'] if params['page']
	@farm_puc_accounts =  eval(session[:query]) if !@farm_puc_accounts
	render :inline => %{
      <% grid            = build_farm_puc_account_grid(@farm_puc_accounts,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all farm_puc_accounts' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@farm_puc_account_pages) if @farm_puc_account_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_farm_puc_accounts_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_farm_puc_account_search_form
end

def render_farm_puc_account_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  farm_puc_accounts'"%> 

		<%= build_farm_puc_account_search_form(nil,'submit_farm_puc_accounts_search','submit_farm_puc_accounts_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_farm_puc_accounts_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_farm_puc_account_search_form(true)
end

def render_farm_puc_account_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  farm_puc_accounts'"%> 

		<%= build_farm_puc_account_search_form(nil,'submit_farm_puc_accounts_search','submit_farm_puc_accounts_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_farm_puc_accounts_search
	if params['page']
		session[:farm_puc_accounts_page] =params['page']
	else
		session[:farm_puc_accounts_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @farm_puc_accounts = dynamic_search(params[:farm_puc_account] ,'farm_puc_accounts','FarmPucAccount')
	else
		@farm_puc_accounts = eval(session[:query])
	end
	if @farm_puc_accounts.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_farm_puc_account_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_farm_puc_accounts
		end

	else

		render_list_farm_puc_accounts
	end
end

 
def delete_farm_puc_account
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:farm_puc_accounts_page] = params['page']
		render_list_farm_puc_accounts
		return
	end
	id = params[:id]
	if id && farm_puc_account = FarmPucAccount.find(id)
		farm_puc_account.destroy
		session[:alert] = " Record deleted."
		render_list_farm_puc_accounts
	end
  rescue
     handle_error("farm-puc-account association could not be deleted")
   end
end
 
def new_farm_puc_account
	return if authorise_for_web(program_name?,'create')== false
		render_new_farm_puc_account
end
 
def create_farm_puc_account
   begin
	 @farm_puc_account = FarmPucAccount.new(params[:farm_puc_account])
	 if @farm_puc_account.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_farm_puc_account
	 end
  rescue
     handle_error("farm-puc-account association could not be created")
   end
end

def render_new_farm_puc_account
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new farm_puc_account'"%> 

		<%= build_farm_puc_account_form(@farm_puc_account,'create_farm_puc_account','create_farm_puc_account',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_farm_puc_account
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @farm_puc_account = FarmPucAccount.find(id)
		render_edit_farm_puc_account

	 end
end


def render_edit_farm_puc_account
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit farm_puc_account'"%> 

		<%= build_farm_puc_account_form(@farm_puc_account,'update_farm_puc_account','update_farm_puc_account',true)%>

		}, :layout => 'content'
end
 
def update_farm_puc_account
  begin
	if params[:page]
		session[:farm_puc_accounts_page] = params['page']
		render_list_farm_puc_accounts
		return
	end

		@current_page = session[:farm_puc_accounts_page]
	 id = params[:farm_puc_account][:id]
	 if id && @farm_puc_account = FarmPucAccount.find(id)
		 if @farm_puc_account.update_attributes(params[:farm_puc_account])
			@farm_puc_accounts = eval(session[:query])
			render_list_farm_puc_accounts
	 else
			 render_edit_farm_puc_account

		 end
	 end
  rescue
     handle_error("farm-puc-account association not be updated")
   end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: farm_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: accounts_parties_role_id
#	---------------------------------------------------------------------------------
def farm_puc_account_party_type_name_changed
	party_type_name = get_selected_combo_value(params)
	session[:farm_puc_account_form][:party_type_name_combo_selection] = party_type_name
	@party_names = FarmPucAccount.party_names_for_party_type_name(party_type_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm_puc_account','party_name',@party_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_farm_puc_account_party_name'/>
		<%= observe_field('farm_puc_account_party_name',:update => 'role_name_cell',:url => {:action => session[:farm_puc_account_form][:party_name_observer][:remote_method]},:loading => "show_element('img_farm_puc_account_party_name');",:complete => session[:farm_puc_account_form][:party_name_observer][:on_completed_js])%>
		}

end


def farm_puc_account_party_name_changed
	party_name = get_selected_combo_value(params)
	session[:farm_puc_account_form][:party_name_combo_selection] = party_name
	party_type_name = 	session[:farm_puc_account_form][:party_type_name_combo_selection]
	@role_names = FarmPucAccount.role_names_for_party_name_and_party_type_name(party_name,party_type_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm_puc_account','role_name',@role_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_farm_puc_account_role_name'/>
		<%= observe_field('farm_puc_account_role_name',:update => 'account_code_cell',:url => {:action => session[:farm_puc_account_form][:role_name_observer][:remote_method]},:loading => "show_element('img_farm_puc_account_role_name');",:complete => session[:farm_puc_account_form][:role_name_observer][:on_completed_js])%>
		}

end


def farm_puc_account_role_name_changed
	role_name = get_selected_combo_value(params)
	session[:farm_puc_account_form][:role_name_combo_selection] = role_name
	party_name = 	session[:farm_puc_account_form][:party_name_combo_selection]
	party_type_name = 	session[:farm_puc_account_form][:party_type_name_combo_selection]
	@account_codes = FarmPucAccount.account_codes_for_role_name_and_party_name_and_party_type_name(role_name,party_name,party_type_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm_puc_account','account_code',@account_codes)%>

		}

end


#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: puc_id
#	---------------------------------------------------------------------------------
def farm_puc_account_puc_type_code_changed
	puc_type_code = get_selected_combo_value(params)
	session[:farm_puc_account_form][:puc_type_code_combo_selection] = puc_type_code
	@puc_codes = FarmPucAccount.puc_codes_for_puc_type_code(puc_type_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm_puc_account','puc_code',@puc_codes)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(farm_puc_accounts)
#	-----------------------------------------------------------------------------------------------------------
def farm_puc_account_party_type_name_search_combo_changed
	party_type_name = get_selected_combo_value(params)
	session[:farm_puc_account_search_form][:party_type_name_combo_selection] = party_type_name
	@party_names = FarmPucAccount.find_by_sql("Select distinct party_name from farm_puc_accounts where party_type_name = '#{party_type_name}'").map{|g|[g.party_name]}
	@party_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm_puc_account','party_name',@party_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_farm_puc_account_party_name'/>
		<%= observe_field('farm_puc_account_party_name',:update => 'role_name_cell',:url => {:action => session[:farm_puc_account_search_form][:party_name_observer][:remote_method]},:loading => "show_element('img_farm_puc_account_party_name');",:complete => session[:farm_puc_account_search_form][:party_name_observer][:on_completed_js])%>
		}

end


def farm_puc_account_party_name_search_combo_changed
	party_name = get_selected_combo_value(params)
	session[:farm_puc_account_search_form][:party_name_combo_selection] = party_name
	party_type_name = 	session[:farm_puc_account_search_form][:party_type_name_combo_selection]
	@role_names = FarmPucAccount.find_by_sql("Select distinct role_name from farm_puc_accounts where party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.role_name]}
	@role_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm_puc_account','role_name',@role_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_farm_puc_account_role_name'/>
		<%= observe_field('farm_puc_account_role_name',:update => 'account_code_cell',:url => {:action => session[:farm_puc_account_search_form][:role_name_observer][:remote_method]},:loading => "show_element('img_farm_puc_account_role_name');",:complete => session[:farm_puc_account_search_form][:role_name_observer][:on_completed_js])%>
		}

end


def farm_puc_account_role_name_search_combo_changed
	role_name = get_selected_combo_value(params)
	session[:farm_puc_account_search_form][:role_name_combo_selection] = role_name
	party_name = 	session[:farm_puc_account_search_form][:party_name_combo_selection]
	party_type_name = 	session[:farm_puc_account_search_form][:party_type_name_combo_selection]
	@account_codes = FarmPucAccount.find_by_sql("Select distinct account_code from farm_puc_accounts where role_name = '#{role_name}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.account_code]}
	@account_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm_puc_account','account_code',@account_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_farm_puc_account_account_code'/>
		<%= observe_field('farm_puc_account_account_code',:update => 'puc_type_code_cell',:url => {:action => session[:farm_puc_account_search_form][:account_code_observer][:remote_method]},:loading => "show_element('img_farm_puc_account_account_code');",:complete => session[:farm_puc_account_search_form][:account_code_observer][:on_completed_js])%>
		}

end


def farm_puc_account_account_code_search_combo_changed
	account_code = get_selected_combo_value(params)
	session[:farm_puc_account_search_form][:account_code_combo_selection] = account_code
	role_name = 	session[:farm_puc_account_search_form][:role_name_combo_selection]
	party_name = 	session[:farm_puc_account_search_form][:party_name_combo_selection]
	party_type_name = 	session[:farm_puc_account_search_form][:party_type_name_combo_selection]
	@puc_type_codes = FarmPucAccount.find_by_sql("Select distinct puc_type_code from farm_puc_accounts where account_code = '#{account_code}' and role_name = '#{role_name}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.puc_type_code]}
	@puc_type_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm_puc_account','puc_type_code',@puc_type_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_farm_puc_account_puc_type_code'/>
		<%= observe_field('farm_puc_account_puc_type_code',:update => 'puc_code_cell',:url => {:action => session[:farm_puc_account_search_form][:puc_type_code_observer][:remote_method]},:loading => "show_element('img_farm_puc_account_puc_type_code');",:complete => session[:farm_puc_account_search_form][:puc_type_code_observer][:on_completed_js])%>
		}

end


def farm_puc_account_puc_type_code_search_combo_changed
	puc_type_code = get_selected_combo_value(params)
	session[:farm_puc_account_search_form][:puc_type_code_combo_selection] = puc_type_code
	account_code = 	session[:farm_puc_account_search_form][:account_code_combo_selection]
	role_name = 	session[:farm_puc_account_search_form][:role_name_combo_selection]
	party_name = 	session[:farm_puc_account_search_form][:party_name_combo_selection]
	party_type_name = 	session[:farm_puc_account_search_form][:party_type_name_combo_selection]
	@puc_codes = FarmPucAccount.find_by_sql("Select distinct puc_code from farm_puc_accounts where puc_type_code = '#{puc_type_code}' and account_code = '#{account_code}' and role_name = '#{role_name}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.puc_code]}
	@puc_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm_puc_account','puc_code',@puc_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_farm_puc_account_puc_code'/>
		<%= observe_field('farm_puc_account_puc_code',:update => 'farm_code_cell',:url => {:action => session[:farm_puc_account_search_form][:puc_code_observer][:remote_method]},:loading => "show_element('img_farm_puc_account_puc_code');",:complete => session[:farm_puc_account_search_form][:puc_code_observer][:on_completed_js])%>
		}

end


def farm_puc_account_puc_code_search_combo_changed
	puc_code = get_selected_combo_value(params)
	session[:farm_puc_account_search_form][:puc_code_combo_selection] = puc_code
	puc_type_code = 	session[:farm_puc_account_search_form][:puc_type_code_combo_selection]
	account_code = 	session[:farm_puc_account_search_form][:account_code_combo_selection]
	role_name = 	session[:farm_puc_account_search_form][:role_name_combo_selection]
	party_name = 	session[:farm_puc_account_search_form][:party_name_combo_selection]
	party_type_name = 	session[:farm_puc_account_search_form][:party_type_name_combo_selection]
	@farm_codes = FarmPucAccount.find_by_sql("Select distinct farm_code from farm_puc_accounts where puc_code = '#{puc_code}' and puc_type_code = '#{puc_type_code}' and account_code = '#{account_code}' and role_name = '#{role_name}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.farm_code]}
	@farm_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm_puc_account','farm_code',@farm_codes)%>

		}

end


#==================
#FARM GROUP CODE
#==================
def list_farm_groups
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:farm_groups_page] = params['page']

		 render_list_farm_groups

		 return 
	else
		session[:farm_groups_page] = nil
	end

	list_query = "@farm_group_pages = Paginator.new self, FarmGroup.count, @@page_size,@current_page
	 @farm_groups = FarmGroup.find(:all,
				 :limit => @farm_group_pages.items_per_page,
				 :offset => @farm_group_pages.current.offset)"
	session[:query] = list_query
	render_list_farm_groups
end


def render_list_farm_groups
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:farm_groups_page] if session[:farm_groups_page]
	@current_page = params['page'] if params['page']
	@farm_groups =  eval(session[:query]) if !@farm_groups
	render :inline => %{
      <% grid            = build_farm_group_grid(@farm_groups,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all farm_groups' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@farm_group_pages) if @farm_group_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_farm_groups_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_farm_group_search_form
end

def render_farm_group_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  farm_groups'"%> 

		<%= build_farm_group_search_form(nil,'submit_farm_groups_search','submit_farm_groups_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_farm_groups_hierarchy
	return if authorise_for_web(program_name?,'read')== false

	@is_flat_search = false 
	render_farm_group_search_form(true)
end

def render_farm_group_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  farm_groups'"%> 

		<%= build_farm_group_search_form(nil,'submit_farm_groups_search','submit_farm_groups_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_farm_groups_search
	if params['page']
		session[:farm_groups_page] =params['page']
	else
		session[:farm_groups_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @farm_groups = dynamic_search(params[:farm_group] ,'farm_groups','FarmGroup')
	else
		@farm_groups = eval(session[:query])
	end
	if @farm_groups.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_farm_group_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_farm_groups
		end

	else

		render_list_farm_groups
	end
end

def delete_farm_group
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:farm_groups_page] = params['page']
		render_list_farm_groups
		return
	end
	id = params[:id]
	if id && farm_group = FarmGroup.find(id)
		farm_group.destroy
		session[:alert] = " Record deleted."
		render_list_farm_groups
	end
  rescue
     handle_error("farm group could not be deleted")
  end
end
 
 
def new_farm_group
	return if authorise_for_web(program_name?,'create')== false
		render_new_farm_group
end
 
def create_farm_group
  begin
	 @farm_group = FarmGroup.new(params[:farm_group])
	 if @farm_group.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_farm_group
	 end
   rescue
     handle_error("farm group could not be created")
   end
end

def render_new_farm_group
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new farm_group'"%> 

		<%= build_farm_group_form(@farm_group,'create_farm_group','create_farm_group',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_farm_group
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @farm_group = FarmGroup.find(id)
		render_edit_farm_group

	 end
end


def render_edit_farm_group
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit farm_group'"%> 

		<%= build_farm_group_form(@farm_group,'update_farm_group','update_farm_group',true)%>

		}, :layout => 'content'
end
 
def update_farm_group
  begin
	if params[:page]
		session[:farm_groups_page] = params['page']
		render_list_farm_groups
		return
	end

		@current_page = session[:farm_groups_page]
	 id = params[:farm_group][:id]
	 if id && @farm_group = FarmGroup.find(id)
		 if @farm_group.update_attributes(params[:farm_group])
			@farm_groups = eval(session[:query])
			render_list_farm_groups
	 else
			 render_edit_farm_group

		 end
	 end
  rescue
     handle_error("farm group could not be deleted")
   end
 end

#==================
#PUC CODE
#==================
def list_pucs
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:pucs_page] = params['page']

		 render_list_pucs

		 return 
	else
		session[:pucs_page] = nil
	end

	list_query = "@puc_pages = Paginator.new self, Puc.count, @@page_size,@current_page
	 @pucs = Puc.find(:all,
				 :limit => @puc_pages.items_per_page,
				 :offset => @puc_pages.current.offset)"
	session[:query] = list_query
	render_list_pucs
end


def render_list_pucs
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:pucs_page] if session[:pucs_page]
	@current_page = params['page'] if params['page']
	@pucs =  eval(session[:query]) if !@pucs
	render :inline => %{
      <% grid            = build_puc_grid(@pucs,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all pucs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@puc_pages) if @puc_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_pucs_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_puc_search_form
end

def render_puc_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  pucs'"%> 

		<%= build_puc_search_form(nil,'submit_pucs_search','submit_pucs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_pucs_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_puc_search_form(true)
end

def render_puc_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  pucs'"%> 

		<%= build_puc_search_form(nil,'submit_pucs_search','submit_pucs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_pucs_search
	if params['page']
		session[:pucs_page] =params['page']
	else
		session[:pucs_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @pucs = dynamic_search(params[:puc] ,'pucs','Puc')
	else
		@pucs = eval(session[:query])
	end
	if @pucs.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_puc_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_pucs
		end

	else

		render_list_pucs
	end
end

 
def delete_puc
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:pucs_page] = params['page']
		render_list_pucs
		return
	end
	id = params[:id]
	if id && puc = Puc.find(id)
		puc.destroy
		session[:alert] = " Record deleted."
		render_list_pucs
	end
  rescue
     handle_error("puc could not be deleted")
   end
end
 
def new_puc
	return if authorise_for_web(program_name?,'create')== false
		render_new_puc
end
 
def create_puc
  begin
	 @puc = Puc.new(params[:puc])
	 if @puc.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_puc
	 end
  rescue
     handle_error("puc could not be created")
   end
end

def render_new_puc
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new puc'"%> 

		<%= build_puc_form(@puc,'create_puc','create_puc',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_puc
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @puc = Puc.find(id)
		render_edit_puc

	 end
end


def render_edit_puc
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit puc'"%> 

		<%= build_puc_form(@puc,'update_puc','update_puc',true)%>

		}, :layout => 'content'
end
 
def update_puc
  begin
	if params[:page]
		session[:pucs_page] = params['page']
		render_list_pucs
		return
	end

		@current_page = session[:pucs_page]
	 id = params[:puc][:id]
	 if id && @puc = Puc.find(id)
		 if @puc.update_attributes(params[:puc])
			@pucs = eval(session[:query])
			render_list_pucs
	 else
			 render_edit_puc

		 end
	 end
  rescue
     handle_error("puc could not be updated")
   end
 end
 

#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(pucs)
#	-----------------------------------------------------------------------------------------------------------
def puc_puc_type_code_search_combo_changed
	puc_type_code = get_selected_combo_value(params)
	session[:puc_search_form][:puc_type_code_combo_selection] = puc_type_code
	@puc_codes = Puc.find_by_sql("Select distinct puc_code from pucs where puc_type_code = '#{puc_type_code}'").map{|g|[g.puc_code]}
	@puc_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('puc','puc_code',@puc_codes)%>

		}

end

#==================
#PUC TYPE CODE
#==================
def list_puc_types
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:puc_types_page] = params['page']

		 render_list_puc_types

		 return 
	else
		session[:puc_types_page] = nil
	end

	list_query = "@puc_type_pages = Paginator.new self, PucType.count, @@page_size,@current_page
	 @puc_types = PucType.find(:all,
				 :limit => @puc_type_pages.items_per_page,
				 :offset => @puc_type_pages.current.offset)"
	session[:query] = list_query
	render_list_puc_types
end


def render_list_puc_types
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:puc_types_page] if session[:puc_types_page]
	@current_page = params['page'] if params['page']
	@puc_types =  eval(session[:query]) if !@puc_types
	render :inline => %{
      <% grid            = build_puc_type_grid(@puc_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all puc_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@puc_type_pages) if @puc_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_puc_types_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_puc_type_search_form
end

def render_puc_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  puc_types'"%> 

		<%= build_puc_type_search_form(nil,'submit_puc_types_search','submit_puc_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_puc_types_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_puc_type_search_form(true)
end

def render_puc_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  puc_types'"%> 

		<%= build_puc_type_search_form(nil,'submit_puc_types_search','submit_puc_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_puc_types_search
	if params['page']
		session[:puc_types_page] =params['page']
	else
		session[:puc_types_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @puc_types = dynamic_search(params[:puc_type] ,'puc_types','PucType')
	else
		@puc_types = eval(session[:query])
	end
	if @puc_types.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_puc_type_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_puc_types
		end

	else

		render_list_puc_types
	end
end

 
def delete_puc_type
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:puc_types_page] = params['page']
		render_list_puc_types
		return
	end
	id = params[:id]
	if id && puc_type = PucType.find(id)
		puc_type.destroy
		session[:alert] = " Record deleted."
		render_list_puc_types
	end
  rescue
     handle_error("puc type could not be deleted")
   end
end
 
def new_puc_type
	return if authorise_for_web(program_name?,'create')== false
		render_new_puc_type
end
 
def create_puc_type
   begin
	 @puc_type = PucType.new(params[:puc_type])
	 if @puc_type.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_puc_type
	 end
  rescue
     handle_error("puc type could not be created")
   end
end

def render_new_puc_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new puc_type'"%> 

		<%= build_puc_type_form(@puc_type,'create_puc_type','create_puc_type',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_puc_type
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @puc_type = PucType.find(id)
		render_edit_puc_type

	 end
end


def render_edit_puc_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit puc_type'"%> 

		<%= build_puc_type_form(@puc_type,'update_puc_type','update_puc_type',true)%>

		}, :layout => 'content'
end
 
def update_puc_type
  begin
	if params[:page]
		session[:puc_types_page] = params['page']
		render_list_puc_types
		return
	end

		@current_page = session[:puc_types_page]
	 id = params[:puc_type][:id]
	 if id && @puc_type = PucType.find(id)
		 if @puc_type.update_attributes(params[:puc_type])
			@puc_types = eval(session[:query])
			render_list_puc_types
	 else
			 render_edit_puc_type

		 end
	 end
	rescue
     handle_error("puc type association not be updated")
   end
 end

#==========
#FARM CODE
#==========
def list_farms
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:farms_page] = params['page']

		 render_list_farms

		 return 
	else
		session[:farms_page] = nil
	end

	list_query = "@farm_pages = Paginator.new self, Farm.count, @@page_size,@current_page
	 @farms = Farm.find(:all,
         :select => \"farms.*, parties.party_name as farm_owner_code\",
         :joins => \"LEFT OUTER JOIN parties_roles ON parties_roles.id=farms.farm_owner LEFT OUTER JOIN parties on parties.id=parties_roles.party_id\" ,
				 :limit => @farm_pages.items_per_page,
         :order => \" farms.farm_code,farms.farm_description ASC \",
				 :offset => @farm_pages.current.offset)"
	session[:query] = list_query
	render_list_farms
end


def render_list_farms
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:farms_page] if session[:farms_page]
	@current_page = params['page'] if params['page']
	@farms =  eval(session[:query]) if !@farms
	render :inline => %{
      <% grid            = build_farm_grid(@farms,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all farms' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@farm_pages) if @farm_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_farms_flat
#	return if authorise_for_web(program_name?,'read')== false
#	@is_flat_search = true
#	render_farm_search_form
    dm_session[:parameter_fields_values] = nil
    dm_session['se_layout']              = 'content'
    @content_header_caption           = "'search farms'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form("search_farms.yml", "submit_farms_search")
end

def render_farm_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  farms'"%> 

		<%= build_farm_search_form(nil,'submit_farms_search','submit_farms_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_farms_hierarchy
#	return if authorise_for_web(program_name?,'read')== false
#
#	@is_flat_search = false
#	render_farm_search_form(true)
    search_farms_flat
end

def render_farm_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  farms'"%> 

		<%= build_farm_search_form(nil,'submit_farms_search','submit_farms_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_farms_search
	if params['page']
		session[:farms_page] =params['page']
	else
		session[:farms_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
#		 @farms = dynamic_search(params[:farm] ,'farms','Farm')
    session[:query] = "ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])"
    @farms = eval(session[:query])
	else
		@farms = eval(session[:query])
	end
	if @farms.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_farm_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_farms
		end

	else

		render_list_farms
	end
end

 
def delete_farm
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:farms_page] = params['page']
		render_list_farms
		return
	end
	id = params[:id]
	if id && farm = Farm.find(id)
		farm.destroy
		session[:alert] = " Record deleted."
		render_list_farms
	end
  rescue
     handle_error("farm could not be deleted")
   end
end
 
 
def new_farm
	return if authorise_for_web(program_name?,'create')== false
		render_new_farm
end
 
def create_farm
   begin
	 @farm = Farm.new(params[:farm])
	 if @farm.save
		 session[:farm_id_value] = {} if(!session[:farm_id_value])
		 session[:farm_id_value].store("my_farm_id", @farm.id)
		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_farm
	 end
  rescue
     handle_error("farm could not be created")
   end
end

def render_new_farm
	render :inline => %{
		<% @content_header_caption = "'create new farm'"%> 

		<%= build_farm_form(@farm,'create_farm','create_farm',nil,false,@is_create_retry)%>
		}, :layout => 'content'
end
 
def edit_farm
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
    
	 if id && @farm = Farm.find(id)
	    #-------------------------------
        #   Happymore's addition code
        #--------------------------------
         if session[:farm_id_value]== nil
            session[:farm_id_value] = Hash.new
         else
            session[:farm_id_value] = nil
            session[:farm_id_value] = Hash.new
         end
         session[:farm_id_value].store("my_farm_id", id)
         
         #@farm_orchards = Orchard.find(:all, :conditions=>["farm_id = ?", id])
         session[:farm_record] = @farm
        #--------------------------------
        #   End of Happymore's additional code
        #--------------------------------
		render_edit_farm

	 end
end


def render_edit_farm
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit farm'"%> 

		<%= build_farm_form(@farm,'update_farm','update_farm',@farm_orchards,true)%>

		}, :layout => 'content'
end

	def current_farm
		if(@farm = session[:farm_record])
			render_edit_farm
		else
			session[:alert] = 'no current farm'
			render :inline => %{}, :layout => 'content'
		end
	end
def update_farm
  begin
	if params[:page]
		session[:farms_page] = params['page']
		render_list_farms
		return
	end

		@current_page = session[:farms_page]
	 id = params[:farm][:id]
	 if id && @farm = Farm.find(id)
		 if @farm.update_attributes(params[:farm])
			@farms = eval(session[:query])
			render_list_farms
	 else
			 render_edit_farm

		 end
	 end
  rescue
     handle_error("farm could not be updated")
   end
 end
 
#-----------------------------------------------------------------------------------
#    Happymore's additional codes
#-----------------------------------------------------------------------------------

def new_orchard
    return if authorise_for_web(program_name?,'create')== false
		render_new_orchard
end

def render_new_orchard
    render :inline => %{
		<% @content_header_caption = "'create new orchard'"%> 

		<%= build_orchard_form(@orchard,'create_orchard','create_orchard',false,@is_create_retry)%>

		}, :layout => 'content'
end

def create_orchard
    begin
       if session[:farm_id_value].has_key?("my_farm_id")
          my_farm_id = session[:farm_id_value].fetch("my_farm_id")
       else
          my_farm_id = ""
       end

      #MM102014 - add Commodities and rmt varieties
      params[:orchard].delete("orchard_commodity_id")
      @orchard = Orchard.new(params[:orchard])
      @orchard.farm_id = my_farm_id
      if @orchard.save
          #redirect_to_index("'new record created successfully'","'create successful'")
          @farm = session[:farm_record]
          render_edit_farm
      else
          @is_create_retry =  true
          render_new_orchard
      end
  rescue
     handle_error("orchard could not be created")
   end
end

	def set_orchard_as_group
		begin
			id = params[:id]
			if id && @orchard = Orchard.find(id)
				if @orchard.update_attribute(:is_group, true)
					@orchard.integrate_representative_orchard_into_MAF('PST-01')
					@orchard.integrate_representative_orchard_into_MAF('PST-02')
					@farm = session[:farm_record]
					render_edit_farm
				end
			end
		rescue
			flash[:error] = "Orchard could not be set as group - #{$!.message}"
			@farm = session[:farm_record]
			render_edit_farm
		end
	end

	def view_child_orchards
		return if authorise_for_web(program_name?,'read') == false

		if params[:page]!= nil

			session[:orchards_page] = params['page']

			render_list_child_orchards

			return
		else
			session[:orchards_page] = nil
		end

		# , CASE parent_orchard_id WHEN #{params[:id]} THEN null ELSE parent_orchard_id END
		list_query = "@orchard_pages = Paginator.new self, Orchard.count, @@page_size,@current_page
	  @orchards = Orchard.find(:all,
				 :select=>\"distinct orchards.id,orchards.orchard_code,orchards.orchard_description,commodities.commodity_description_long as commodity, rmt_varieties.rmt_variety_description as rmt_variety
										, Null as parent_orchard_id, true as is_child_orchard\",
				 :conditions=>\"parent_orchard_id=#{params[:id]}\",
				 :joins=>\"left outer join rmt_varieties on orchards.orchard_rmt_variety_id = rmt_varieties.id
									 left outer join commodities on rmt_varieties.commodity_id = commodities.id\",
				 :limit => @orchard_pages.items_per_page,
				 :offset => @orchard_pages.current.offset)"
		@parent_orchard =Orchard.find(params[:id])
		session[:current_orchard] = params[:id]
		session[:query] = list_query
		render_list_child_orchards
	end

def edit_orchard
    return if authorise_for_web(program_name?,'edit')==false
    id = params[:id]
    if id && @orchard = Orchard.find(id)
        render_edit_orchard
    end
end

def render_edit_orchard
    render :inline => %{
		<% @content_header_caption = "'edit orchard'"%>

		<%= build_edit_orchard_form(@orchard,'update_orchard','update_orchard',true)%>

		}, :layout => 'content'
end

def update_orchard
    begin
        id = params[:orchard][:id]
        if id && @orchard = Orchard.find(id)
            if @orchard.update_attributes(params[:orchard])
                @farm = session[:farm_record]
                render_edit_farm
            end
        end 
    rescue
        handle_error("Orchard could not be updated")
    end  
end

def delete_orchard
    begin
        return if authorise_for_web(program_name?,'delete')==false
        id = params[:id]
        puts id.to_s
    	if id && orchard = Orchard.find(id)
    		orchard.destroy
    		session[:alert] = " Record deleted."
    		@farm = session[:farm_record]
    		render_edit_farm
    	end
    rescue
        handle_error("Orchard could not be deleted")
    end
end

  def orchard_parent_orchard_id_search_combo_changed
		orchard_parent_orchard_id = get_selected_combo_value(params)
		session[:orchard_parent_orchard_id] = orchard_parent_orchard_id
		if(orchard_parent_orchard_id)
			@rmt_variety = RmtVariety.find_by_sql("select r.*, c.commodity_description_long
																						 from rmt_varieties r
																						 join commodities c on c.id=r.commodity_id
																						 join orchards o on o.orchard_rmt_variety_id=r.id
																						 where o.id = #{orchard_parent_orchard_id}")[0]
			@commodities = [["#{@rmt_variety.commodity_code} - #{@rmt_variety.commodity_description_long}", @rmt_variety.commodity_id]]
			@rmt_varieties = [["#{@rmt_variety.rmt_variety_code} - #{@rmt_variety.rmt_variety_description}", @rmt_variety.id]]
		else
			@commodities = Commodity.find_by_sql("select * from commodities").map{|g|["#{g.commodity_code} - #{g.commodity_description_long}", g.id]}
			@commodities.unshift(['<empty>',nil])
			@rmt_varieties = ["Select a value from commodity_code"]
		end

		render :inline => %{
      <%= select('orchard','orchard_commodity_id', @commodities) %>
		  <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_orchard_orchard_commodity_id'/>
		  <%= observe_field('orchard_orchard_commodity_id',:update => 'orchard_rmt_variety_id_cell',:url => {:action => session[:orchard_form][:orchard_commodity_id_observer][:remote_method]},:loading => "show_element('img_orchard_orchard_commodity_id');",:complete => session[:orchard_form][:orchard_commodity_id_observer][:on_completed_js])%>


      <% orchard_rmt_variety_id_content = select('orchard','orchard_rmt_variety_id', @rmt_varieties) %>
			<script> <%= update_element_function("orchard_rmt_variety_id_cell", :action => :update,:content => orchard_rmt_variety_id_content) %> </script>
		}
	end

  def orchard_commodity_id_search_combo_changed

    orchard_commodity_id = get_selected_combo_value(params)
    session[:orchard_commodity_id] = orchard_commodity_id
		orchard_commodity_clause = orchard_commodity_id ? "commodity_id = '#{orchard_commodity_id}'" : "commodity_id is null"

		@orchard_rmt_variety_id = RmtVariety.find_by_sql("select * from rmt_varieties where #{orchard_commodity_clause}").map{|g|["#{g.rmt_variety_code} - #{g.rmt_variety_description}", g.id]}
		@orchard_rmt_variety_id.unshift(['<empty>',nil])

    render :inline => %{
      <%= select('orchard','orchard_rmt_variety_id',@orchard_rmt_variety_id) %>
		}

  end

#-----------------------------------------------------------------------------------
#    End of Happymore's additional codes
#-----------------------------------------------------------------------------------
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: farm_group_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: parties_role_id
#	---------------------------------------------------------------------------------
def farm_party_type_name_changed
	party_type_name = get_selected_combo_value(params)
	session[:farm_form][:party_type_name_combo_selection] = party_type_name
	@party_names = Farm.party_names_for_party_type_name(party_type_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm','party_name',@party_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_farm_party_name'/>
		<%= observe_field('farm_party_name',:update => 'role_name_cell',:url => {:action => session[:farm_form][:party_name_observer][:remote_method]},:loading => "show_element('img_farm_party_name');",:complete => session[:farm_form][:party_name_observer][:on_completed_js])%>
		}

end


def farm_party_name_changed
	party_name = get_selected_combo_value(params)
	session[:farm_form][:party_name_combo_selection] = party_name
	party_type_name = 	session[:farm_form][:party_type_name_combo_selection]
	@role_names = Farm.role_names_for_party_name_and_party_type_name(party_name,party_type_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm','role_name',@role_names)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(farms)
#	-----------------------------------------------------------------------------------------------------------
def farm_party_type_name_search_combo_changed
	party_type_name = get_selected_combo_value(params)
	session[:farm_search_form][:party_type_name_combo_selection] = party_type_name
	@party_names = Farm.find_by_sql("Select distinct party_name from farms where party_type_name = '#{party_type_name}'").map{|g|[g.party_name]}
	@party_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm','party_name',@party_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_farm_party_name'/>
		<%= observe_field('farm_party_name',:update => 'role_name_cell',:url => {:action => session[:farm_search_form][:party_name_observer][:remote_method]},:loading => "show_element('img_farm_party_name');",:complete => session[:farm_search_form][:party_name_observer][:on_completed_js])%>
		}

end


def farm_party_name_search_combo_changed
	party_name = get_selected_combo_value(params)
	session[:farm_search_form][:party_name_combo_selection] = party_name
	party_type_name = 	session[:farm_search_form][:party_type_name_combo_selection]
	@role_names = Farm.find_by_sql("Select distinct role_name from farms where party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.role_name]}
	@role_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm','role_name',@role_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_farm_role_name'/>
		<%= observe_field('farm_role_name',:update => 'farm_group_code_cell',:url => {:action => session[:farm_search_form][:role_name_observer][:remote_method]},:loading => "show_element('img_farm_role_name');",:complete => session[:farm_search_form][:role_name_observer][:on_completed_js])%>
		}

end


def farm_role_name_search_combo_changed
	role_name = get_selected_combo_value(params)
	session[:farm_search_form][:role_name_combo_selection] = role_name
	party_name = 	session[:farm_search_form][:party_name_combo_selection]
	party_type_name = 	session[:farm_search_form][:party_type_name_combo_selection]
	@farm_group_codes = Farm.find_by_sql("Select distinct farm_group_code from farms where role_name = '#{role_name}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.farm_group_code]}
	@farm_group_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm','farm_group_code',@farm_group_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_farm_farm_group_code'/>
		<%= observe_field('farm_farm_group_code',:update => 'farm_code_cell',:url => {:action => session[:farm_search_form][:farm_group_code_observer][:remote_method]},:loading => "show_element('img_farm_farm_group_code');",:complete => session[:farm_search_form][:farm_group_code_observer][:on_completed_js])%>
		}

end


def farm_farm_group_code_search_combo_changed
	farm_group_code = get_selected_combo_value(params)
	session[:farm_search_form][:farm_group_code_combo_selection] = farm_group_code
	role_name = 	session[:farm_search_form][:role_name_combo_selection]
	party_name = 	session[:farm_search_form][:party_name_combo_selection]
	party_type_name = 	session[:farm_search_form][:party_type_name_combo_selection]
	@farm_codes = Farm.find_by_sql("Select distinct farm_code from farms where farm_group_code = '#{farm_group_code}' and role_name = '#{role_name}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.farm_code]}
	@farm_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('farm','farm_code',@farm_codes)%>

		}

end

	def render_list_child_orchards
		@can_edit = authorise(program_name?,'edit',session[:user_id])
		@can_delete = authorise(program_name?,'delete',session[:user_id])
		@current_page = session[:orchards_page] if session[:orchards_page]
		@current_page = params['page'] if params['page']
		@orchards =  eval(session[:query]) if !@orchards

		@grid_selected_rows = @orchards
		@single_childed = (@orchards.size==1) ? true : false

		orchards =Orchard.find_by_sql("select distinct orchards.id,orchards.orchard_code,orchards.orchard_description,commodities.commodity_description_long as commodity,
																	 rmt_varieties.rmt_variety_description as rmt_variety
																	 , orchards.parent_orchard_id, false as is_child_orchard
																	 from orchards
																	 left outer join rmt_varieties on orchards.orchard_rmt_variety_id = rmt_varieties.id
																	 left outer join commodities on rmt_varieties.commodity_id = commodities.id
																	 where farm_id = #{session[:farm_record].id} and (parent_orchard_id<>#{params[:id]} or orchards.parent_orchard_id is null)
																	 and (orchards.is_group is null or orchards.is_group is false) and orchards.id<>#{params[:id]} and (orchards.orchard_rmt_variety_id=#{@parent_orchard.orchard_rmt_variety_id})
																	 group by orchards.id,orchard_code,orchard_description, commodity, rmt_variety, parent_orchard_id
																	 order by parent_orchard_id desc")
		@orchards += orchards

		render :inline => %{
      <% grid            = build_orchard_grid(@orchards,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all orchard groups' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@orchard_pages) if @orchard_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
	end

	def remove_orchard_as_parent
		ActiveRecord::Base.transaction do
			parent_orchard = Orchard.find(params[:id])
			parent_orchard.update_attribute(:is_group, false)
			Orchard.update_all(ActiveRecord::Base.extend_set_sql_with_request("parent_orchard_id=Null","orchards"),"parent_orchard_id=#{params[:id]}")
		end

		@farm = session[:farm_record]
		render_edit_farm
	end

	def selected_products
		child_orchards = Orchard.find_all_by_parent_orchard_id(session[:current_orchard]).map{|o| o.id}
		removed_orchards = child_orchards - (child_orchards & eval(params['selection']['list']))
		added_orchards = eval(params['selection']['list']) - child_orchards

		ActiveRecord::Base.transaction do
			if(!removed_orchards.empty?)
				removed_orchards_clause = "id=#{removed_orchards.join(" or id=")} "
				Orchard.update_all(ActiveRecord::Base.extend_set_sql_with_request("parent_orchard_id=Null","orchards"), removed_orchards_clause)
			end

			if(!added_orchards.empty?)
				added_orchards_clause = "id=#{added_orchards.join(" or id=")} "
				Orchard.update_all(ActiveRecord::Base.extend_set_sql_with_request("parent_orchard_id=#{session[:current_orchard]}","orchards"), added_orchards_clause)
			end
		end

		render_children_for_current_orchard
	end

	def render_children_for_current_orchard
		params[:id] = session[:current_orchard]
		view_child_orchards
	end

	def remove_child_orchard
		ActiveRecord::Base.transaction do
			Orchard.update_all(ActiveRecord::Base.extend_set_sql_with_request("parent_orchard_id=Null","orchards"),"id=#{params[:id]}")
		end
		render_children_for_current_orchard
	end

end
