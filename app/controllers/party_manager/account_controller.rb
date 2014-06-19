class  PartyManager::AccountController < ApplicationController
 
def program_name?
	"account"
end

def bypass_generic_security?
	true
end

#==========================
#ACCOUNTS PARTIES ROLE CODE
#==========================
def list_accounts_parties_roles
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:accounts_parties_roles_page] = params['page']

		 render_list_accounts_parties_roles

		 return 
	else
		session[:accounts_parties_roles_page] = nil
	end

	list_query = "@accounts_parties_role_pages = Paginator.new self, AccountsPartiesRole.count, @@page_size,@current_page
	 @accounts_parties_roles = AccountsPartiesRole.find(:all,
				 :limit => @accounts_parties_role_pages.items_per_page,
				 :offset => @accounts_parties_role_pages.current.offset)"
	session[:query] = list_query
	render_list_accounts_parties_roles
end


def render_list_accounts_parties_roles
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:accounts_parties_roles_page] if session[:accounts_parties_roles_page]
	@current_page = params['page'] if params['page']
	@accounts_parties_roles =  eval(session[:query]) if !@accounts_parties_roles
	render :inline => %{
      <% grid            = build_accounts_parties_role_grid(@accounts_parties_roles,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all accounts_parties_roles' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@accounts_parties_role_pages) if @accounts_parties_role_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_accounts_parties_roles_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_accounts_parties_role_search_form
end

def render_accounts_parties_role_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  accounts_parties_roles'"%> 

		<%= build_accounts_parties_role_search_form(nil,'submit_accounts_parties_roles_search','submit_accounts_parties_roles_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def find_account_party_role
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_accounts_parties_role_search_form(true)
end

def render_accounts_parties_role_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  accounts_parties_roles'"%> 

		<%= build_accounts_parties_role_search_form(nil,'submit_accounts_parties_roles_search','submit_accounts_parties_roles_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_accounts_parties_roles_search
	if params['page']
		session[:accounts_parties_roles_page] =params['page']
	else
		session[:accounts_parties_roles_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @accounts_parties_roles = dynamic_search(params[:accounts_parties_role] ,'accounts_parties_roles','AccountsPartiesRole')
	else
		@accounts_parties_roles = eval(session[:query])
	end
	if @accounts_parties_roles.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_accounts_parties_role_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_accounts_parties_roles
		end

	else

		render_list_accounts_parties_roles
	end
end

 
def delete_accounts_parties_role
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:accounts_parties_roles_page] = params['page']
		render_list_accounts_parties_roles
		return
	end
	id = params[:id]
	if id && accounts_parties_role = AccountsPartiesRole.find(id)
		accounts_parties_role.destroy
		session[:alert] = " Record deleted."
		render_list_accounts_parties_roles
	end
   rescue
     handle_error("account for party role could not be deleted")
   end
end
 
def add_account_party_role
	return if authorise_for_web(program_name?,'create')== false
		render_new_accounts_parties_role
end
 
def create_accounts_parties_role
   begin
	 @accounts_parties_role = AccountsPartiesRole.new(params[:accounts_parties_role])
	 if @accounts_parties_role.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_accounts_parties_role
	 end
	rescue
     handle_error("account for party-role could not be created")
   end
	
end

def render_new_accounts_parties_role
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new accounts_parties_role'"%> 

		<%= build_accounts_parties_role_form(@accounts_parties_role,'create_accounts_parties_role','create_accounts_parties_role',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_accounts_parties_role
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @accounts_parties_role = AccountsPartiesRole.find(id)
		render_edit_accounts_parties_role

	 end
end


def render_edit_accounts_parties_role
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit accounts_parties_role'"%> 

		<%= build_accounts_parties_role_form(@accounts_parties_role,'update_accounts_parties_role','update_accounts_parties_role',true)%>

		}, :layout => 'content'
end
 
def update_accounts_parties_role
  begin
	if params[:page]
		session[:accounts_parties_roles_page] = params['page']
		render_list_accounts_parties_roles
		return
	end

		@current_page = session[:accounts_parties_roles_page]
	 id = params[:accounts_parties_role][:id]
	 if id && @accounts_parties_role = AccountsPartiesRole.find(id)
		 if @accounts_parties_role.update_attributes(params[:accounts_parties_role])
			@accounts_parties_roles = eval(session[:query])
			render_list_accounts_parties_roles
	 else
			 render_edit_accounts_parties_role

		 end
	 end
   rescue
     handle_error("account for party role could not be updated")
   end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: account_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: parties_role_id
#	---------------------------------------------------------------------------------
def accounts_parties_role_party_type_name_changed
	party_type_name = get_selected_combo_value(params)
	session[:accounts_parties_role_form][:party_type_name_combo_selection] = party_type_name
	@party_names = AccountsPartiesRole.party_names_for_party_type_name(party_type_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('accounts_parties_role','party_name',@party_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_accounts_parties_role_party_name'/>
		<%= observe_field('accounts_parties_role_party_name',:update => 'role_name_cell',:url => {:action => session[:accounts_parties_role_form][:party_name_observer][:remote_method]},:loading => "show_element('img_accounts_parties_role_party_name');",:complete => session[:accounts_parties_role_form][:party_name_observer][:on_completed_js])%>
		}

end


def accounts_parties_role_party_name_changed
	party_name = get_selected_combo_value(params)
	session[:accounts_parties_role_form][:party_name_combo_selection] = party_name
	party_type_name = 	session[:accounts_parties_role_form][:party_type_name_combo_selection]
	@role_names = AccountsPartiesRole.role_names_for_party_name_and_party_type_name(party_name,party_type_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('accounts_parties_role','role_name',@role_names)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(accounts_parties_roles)
#	-----------------------------------------------------------------------------------------------------------
def accounts_parties_role_party_type_name_search_combo_changed
	party_type_name = get_selected_combo_value(params)
	session[:accounts_parties_role_search_form][:party_type_name_combo_selection] = party_type_name
	@party_names = AccountsPartiesRole.find_by_sql("Select distinct party_name from accounts_parties_roles where party_type_name = '#{party_type_name}'").map{|g|[g.party_name]}
	@party_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('accounts_parties_role','party_name',@party_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_accounts_parties_role_party_name'/>
		<%= observe_field('accounts_parties_role_party_name',:update => 'role_name_cell',:url => {:action => session[:accounts_parties_role_search_form][:party_name_observer][:remote_method]},:loading => "show_element('img_accounts_parties_role_party_name');",:complete => session[:accounts_parties_role_search_form][:party_name_observer][:on_completed_js])%>
		}

end


def accounts_parties_role_party_name_search_combo_changed
	party_name = get_selected_combo_value(params)
	session[:accounts_parties_role_search_form][:party_name_combo_selection] = party_name
	party_type_name = 	session[:accounts_parties_role_search_form][:party_type_name_combo_selection]
	@role_names = AccountsPartiesRole.find_by_sql("Select distinct role_name from accounts_parties_roles where party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.role_name]}
	@role_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('accounts_parties_role','role_name',@role_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_accounts_parties_role_role_name'/>
		<%= observe_field('accounts_parties_role_role_name',:update => 'account_code_cell',:url => {:action => session[:accounts_parties_role_search_form][:role_name_observer][:remote_method]},:loading => "show_element('img_accounts_parties_role_role_name');",:complete => session[:accounts_parties_role_search_form][:role_name_observer][:on_completed_js])%>
		}

end


def accounts_parties_role_role_name_search_combo_changed
	role_name = get_selected_combo_value(params)
	session[:accounts_parties_role_search_form][:role_name_combo_selection] = role_name
	party_name = 	session[:accounts_parties_role_search_form][:party_name_combo_selection]
	party_type_name = 	session[:accounts_parties_role_search_form][:party_type_name_combo_selection]
	@account_codes = AccountsPartiesRole.find_by_sql("Select distinct account_code from accounts_parties_roles where role_name = '#{role_name}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.account_code]}
	@account_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('accounts_parties_role','account_code',@account_codes)%>

		}

end



#==================
#ACCOUNT TYPE CODE
#==================

def list_account_types
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:account_types_page] = params['page']

		 render_list_account_types

		 return 
	else
		session[:account_types_page] = nil
	end

	list_query = "@account_type_pages = Paginator.new self, AccountType.count, @@page_size,@current_page
	 @account_types = AccountType.find(:all,
				 :limit => @account_type_pages.items_per_page,
				 :offset => @account_type_pages.current.offset)"
	session[:query] = list_query
	render_list_account_types
end


def render_list_account_types
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:account_types_page] if session[:account_types_page]
	@current_page = params['page'] if params['page']
	@account_types =  eval(session[:query]) if !@account_types
	render :inline => %{
      <% grid            = build_account_type_grid(@account_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all account_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@account_type_pages) if @account_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_account_types_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_account_type_search_form
end

def render_account_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  account_types'"%> 

		<%= build_account_type_search_form(nil,'submit_account_types_search','submit_account_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_account_types_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_account_type_search_form(true)
end

def render_account_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  account_types'"%> 

		<%= build_account_type_search_form(nil,'submit_account_types_search','submit_account_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_account_types_search
	if params['page']
		session[:account_types_page] =params['page']
	else
		session[:account_types_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @account_types = dynamic_search(params[:account_type] ,'account_types','AccountType')
	else
		@account_types = eval(session[:query])
	end
	if @account_types.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_account_type_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_account_types
		end

	else

		render_list_account_types
	end
end

 
def delete_account_type
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:account_types_page] = params['page']
		render_list_account_types
		return
	end
	id = params[:id]
	if id && account_type = AccountType.find(id)
		account_type.destroy
		session[:alert] = " Record deleted."
		render_list_account_types
	end
   rescue
     handle_error("account type could not be created")
   end
end
 
def new_account_type
	return if authorise_for_web(program_name?,'create')== false
		render_new_account_type
end
 
def create_account_type
   begin
	 @account_type = AccountType.new(params[:account_type])
	 if @account_type.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_account_type
	 end
    rescue
     handle_error("account type could not be created")
   end
   
   
end

def render_new_account_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new account_type'"%> 

		<%= build_account_type_form(@account_type,'create_account_type','create_account_type',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_account_type
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @account_type = AccountType.find(id)
		render_edit_account_type

	 end
end


def render_edit_account_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit account_type'"%> 

		<%= build_account_type_form(@account_type,'update_account_type','update_account_type',true)%>

		}, :layout => 'content'
end
 
def update_account_type
  begin
	if params[:page]
		session[:account_types_page] = params['page']
		render_list_account_types
		return
	end

		@current_page = session[:account_types_page]
	 id = params[:account_type][:id]
	 if id && @account_type = AccountType.find(id)
		 if @account_type.update_attributes(params[:account_type])
			@account_types = eval(session[:query])
			render_list_account_types
	 else
			 render_edit_account_type

		 end
	 end
   rescue
     handle_error("account type could not be updated")
   end
 end

#===================
#ACCOUNTS CODE
#===================

def list_accounts
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:accounts_page] = params['page']

		 render_list_accounts

		 return 
	else
		session[:accounts_page] = nil
	end

	list_query = "@account_pages = Paginator.new self, Account.count, @@page_size,@current_page
	 @accounts = Account.find(:all,
				 :limit => @account_pages.items_per_page,
				 :offset => @account_pages.current.offset)"
	session[:query] = list_query
	render_list_accounts
end


def render_list_accounts
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:accounts_page] if session[:accounts_page]
	@current_page = params['page'] if params['page']
	@accounts =  eval(session[:query]) if !@accounts
	render :inline => %{
      <% grid            = build_account_grid(@accounts,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all accounts' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@account_pages) if @account_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_accounts_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_account_search_form
end

def render_account_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  accounts'"%> 

		<%= build_account_search_form(nil,'submit_accounts_search','submit_accounts_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_accounts_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_account_search_form(true)
end

def render_account_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  accounts'"%> 

		<%= build_account_search_form(nil,'submit_accounts_search','submit_accounts_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_accounts_search
	if params['page']
		session[:accounts_page] =params['page']
	else
		session[:accounts_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @accounts = dynamic_search(params[:account] ,'accounts','Account')
	else
		@accounts = eval(session[:query])
	end
	if @accounts.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_account_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_accounts
		end

	else

		render_list_accounts
	end
end

 
def delete_account
  begin
	return if authorise_for_web(program_name?,'delete')== false
   
	if params[:page]
		session[:accounts_page] = params['page']
		render_list_accounts
		return
	end
	id = params[:id]
	if id && account = Account.find(id)
		account.destroy
		session[:alert] = " Record deleted."
		render_list_accounts
	end
   rescue
     handle_error("account could not be deleted")
   end
end
 
def new_account
	return if authorise_for_web(program_name?,'create')== false
		render_new_account
end
 
def create_account
   begin
   
	 @account = Account.new(params[:account])
	 if @account.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_account
	 end
   rescue
     handle_error("account could not be created")
   end
end

def render_new_account
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new account'"%> 

		<%= build_account_form(@account,'create_account','create_account',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_account
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @account = Account.find(id)
		render_edit_account

	 end
end


def render_edit_account
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit account'"%> 

		<%= build_account_form(@account,'update_account','update_account',true)%>

		}, :layout => 'content'
end
 
def update_account
  begin
	if params[:page]
		session[:accounts_page] = params['page']
		render_list_accounts
		return
	end

		@current_page = session[:accounts_page]
	 id = params[:account][:id]
	 if id && @account = Account.find(id)
		 if @account.update_attributes(params[:account])
			@accounts = eval(session[:query])
			render_list_accounts
	 else
			 render_edit_account

		 end
	 end
  rescue
     handle_error("account could not be updated")
   end
 end
 
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(accounts)
#	-----------------------------------------------------------------------------------------------------------

end
