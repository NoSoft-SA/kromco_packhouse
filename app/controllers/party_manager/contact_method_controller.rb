class  PartyManager::ContactMethodController < ApplicationController
	require "csv"

def program_name?
	"contact_method"
end

def bypass_generic_security?
	true
end

#==========================
#ORGS POSTAL ADDRESSES CODE
#==========================

def list_parties_postal_addresses
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:parties_postal_addresses_page] = params['page']

		 render_list_parties_postal_addresses

		 return 
	else
		session[:parties_postal_addresses_page] = nil
	end

	list_query = "@parties_postal_address_pages = Paginator.new self, PartiesPostalAddress.count, @@page_size,@current_page
	 @parties_postal_addresses = PartiesPostalAddress.find(:all,
				 :limit => @parties_postal_address_pages.items_per_page,
				 :offset => @parties_postal_address_pages.current.offset)"
	session[:query] = list_query
	render_list_parties_postal_addresses
end


def render_list_parties_postal_addresses
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:parties_postal_addresses_page] if session[:parties_postal_addresses_page]
	@current_page = params['page'] if params['page']
	@parties_postal_addresses =  eval(session[:query]) if !@parties_postal_addresses
	render :inline => %{
      <% grid            = build_parties_postal_address_grid(@parties_postal_addresses,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all parties_postal_addresses' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@parties_postal_address_pages) if @parties_postal_address_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_parties_postal_addresses_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_parties_postal_address_search_form
end

def render_parties_postal_address_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  parties_postal_addresses'"%> 

		<%= build_parties_postal_address_search_form(nil,'submit_parties_postal_addresses_search','submit_parties_postal_addresses_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def find_party_address
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_parties_postal_address_search_form(true)
end

def render_parties_postal_address_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  parties_postal_addresses'"%> 

		<%= build_parties_postal_address_search_form(nil,'submit_parties_postal_addresses_search','submit_parties_postal_addresses_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_parties_postal_addresses_search
	if params['page']
		session[:parties_postal_addresses_page] =params['page']
	else
		session[:parties_postal_addresses_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @parties_postal_addresses = dynamic_search(params[:parties_postal_address] ,'parties_postal_addresses','PartiesPostalAddress')
	else
		@parties_postal_addresses = eval(session[:query])
	end
	if @parties_postal_addresses.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_parties_postal_address_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_parties_postal_addresses
		end

	else

		render_list_parties_postal_addresses
	end
end

 
def delete_parties_postal_address
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:parties_postal_addresses_page] = params['page']
		render_list_parties_postal_addresses
		return
	end
	id = params[:id]
	if id && parties_postal_address = PartiesPostalAddress.find(id)
		parties_postal_address.destroy
		session[:alert] = " Record deleted."
		render_list_parties_postal_addresses
	end
  rescue
     handle_error("contact method could not be removed from party")
   end
end
 
def add_party_address
	return if authorise_for_web(program_name?,'create')== false
		render_new_parties_postal_address
end
 
def create_parties_postal_address
  begin
	 @parties_postal_address = PartiesPostalAddress.new(params[:parties_postal_address])
	 if @parties_postal_address.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_parties_postal_address
	 end
   rescue
     handle_error("postal address could not be added to party")
   end
end

def render_new_parties_postal_address
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new parties_postal_address'"%> 

		<%= build_parties_postal_address_form(@parties_postal_address,'create_parties_postal_address','create_parties_postal_address',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_parties_postal_address
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @parties_postal_address = PartiesPostalAddress.find(id)
		render_edit_parties_postal_address

	 end
end


def render_edit_parties_postal_address
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit parties_postal_address'"%> 

		<%= build_parties_postal_address_form(@parties_postal_address,'update_parties_postal_address','update_parties_postal_address',true)%>

		}, :layout => 'content'
end
 
def update_parties_postal_address
  begin
	if params[:page]
		session[:parties_postal_addresses_page] = params['page']
		render_list_parties_postal_addresses
		return
	end

		@current_page = session[:parties_postal_addresses_page]
	 id = params[:parties_postal_address][:id]
	 if id && @parties_postal_address = PartiesPostalAddress.find(id)
		 if @parties_postal_address.update_attributes(params[:parties_postal_address])
			@parties_postal_addresses = eval(session[:query])
			render_list_parties_postal_addresses
	 else
			 render_edit_parties_postal_address

		 end
	 end
  rescue
     handle_error("postal address could not be updated for party")
   end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: postal_address_id
#	---------------------------------------------------------------------------------
def parties_postal_address_postal_address_type_code_changed
	postal_address_type_code = get_selected_combo_value(params)
	session[:parties_postal_address_form][:postal_address_type_code_combo_selection] = postal_address_type_code
	@cities = PartiesPostalAddress.cities_for_postal_address_type_code(postal_address_type_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('parties_postal_address','city',@cities)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_parties_postal_address_city'/>
		<%= observe_field('parties_postal_address_city',:update => 'address1_cell',:url => {:action => session[:parties_postal_address_form][:city_observer][:remote_method]},:loading => "show_element('img_parties_postal_address_city');",:complete => session[:parties_postal_address_form][:city_observer][:on_completed_js])%>
		}

end


def parties_postal_address_city_changed
	city = get_selected_combo_value(params)
	session[:parties_postal_address_form][:city_combo_selection] = city
	postal_address_type_code = 	session[:parties_postal_address_form][:postal_address_type_code_combo_selection]
	@address1s = PartiesPostalAddress.address1s_for_city_and_postal_address_type_code(city,postal_address_type_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('parties_postal_address','address1',@address1s)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_parties_postal_address_address1'/>
		<%= observe_field('parties_postal_address_address1',:update => 'address2_cell',:url => {:action => session[:parties_postal_address_form][:address1_observer][:remote_method]},:loading => "show_element('img_parties_postal_address_address1');",:complete => session[:parties_postal_address_form][:address1_observer][:on_completed_js])%>
		}

end


def parties_postal_address_address1_changed
	address1 = get_selected_combo_value(params)
	session[:parties_postal_address_form][:address1_combo_selection] = address1
	city = 	session[:parties_postal_address_form][:city_combo_selection]
	postal_address_type_code = 	session[:parties_postal_address_form][:postal_address_type_code_combo_selection]
	@address2s = PartiesPostalAddress.address2s_for_address1_and_city_and_postal_address_type_code(address1,city,postal_address_type_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('parties_postal_address','address2',@address2s)%>

		}

end


#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: party_id
#	---------------------------------------------------------------------------------
def parties_postal_address_party_type_name_changed
	party_type_name = get_selected_combo_value(params)
	session[:parties_postal_address_form][:party_type_name_combo_selection] = party_type_name
	@party_names = PartiesPostalAddress.party_names_for_party_type_name(party_type_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('parties_postal_address','party_name',@party_names)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(parties_postal_addresses)
#	-----------------------------------------------------------------------------------------------------------
def parties_postal_address_party_type_name_search_combo_changed
	party_type_name = get_selected_combo_value(params)
	session[:parties_postal_address_search_form][:party_type_name_combo_selection] = party_type_name
	@party_names = PartiesPostalAddress.find_by_sql("Select distinct party_name from parties_postal_addresses where party_type_name = '#{party_type_name}'").map{|g|[g.party_name]}
	@party_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('parties_postal_address','party_name',@party_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_parties_postal_address_party_name'/>
		<%= observe_field('parties_postal_address_party_name',:update => 'postal_address_type_code_cell',:url => {:action => session[:parties_postal_address_search_form][:party_name_observer][:remote_method]},:loading => "show_element('img_parties_postal_address_party_name');",:complete => session[:parties_postal_address_search_form][:party_name_observer][:on_completed_js])%>
		}

end


def parties_postal_address_party_name_search_combo_changed
	party_name = get_selected_combo_value(params)
	session[:parties_postal_address_search_form][:party_name_combo_selection] = party_name
	party_type_name = 	session[:parties_postal_address_search_form][:party_type_name_combo_selection]
	@postal_address_type_codes = PartiesPostalAddress.find_by_sql("Select distinct postal_address_type_code from parties_postal_addresses where party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.postal_address_type_code]}
	@postal_address_type_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('parties_postal_address','postal_address_type_code',@postal_address_type_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_parties_postal_address_postal_address_type_code'/>
		<%= observe_field('parties_postal_address_postal_address_type_code',:update => 'city_cell',:url => {:action => session[:parties_postal_address_search_form][:postal_address_type_code_observer][:remote_method]},:loading => "show_element('img_parties_postal_address_postal_address_type_code');",:complete => session[:parties_postal_address_search_form][:postal_address_type_code_observer][:on_completed_js])%>
		}

end


def parties_postal_address_postal_address_type_code_search_combo_changed
	postal_address_type_code = get_selected_combo_value(params)
	session[:parties_postal_address_search_form][:postal_address_type_code_combo_selection] = postal_address_type_code
	party_name = 	session[:parties_postal_address_search_form][:party_name_combo_selection]
	party_type_name = 	session[:parties_postal_address_search_form][:party_type_name_combo_selection]
	@cities = PartiesPostalAddress.find_by_sql("Select distinct city from parties_postal_addresses where postal_address_type_code = '#{postal_address_type_code}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.city]}
	@cities.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('parties_postal_address','city',@cities)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_parties_postal_address_city'/>
		<%= observe_field('parties_postal_address_city',:update => 'address1_cell',:url => {:action => session[:parties_postal_address_search_form][:city_observer][:remote_method]},:loading => "show_element('img_parties_postal_address_city');",:complete => session[:parties_postal_address_search_form][:city_observer][:on_completed_js])%>
		}

end


def parties_postal_address_city_search_combo_changed
	city = get_selected_combo_value(params)
	session[:parties_postal_address_search_form][:city_combo_selection] = city
	postal_address_type_code = 	session[:parties_postal_address_search_form][:postal_address_type_code_combo_selection]
	party_name = 	session[:parties_postal_address_search_form][:party_name_combo_selection]
	party_type_name = 	session[:parties_postal_address_search_form][:party_type_name_combo_selection]
	@address1s = PartiesPostalAddress.find_by_sql("Select distinct address1 from parties_postal_addresses where city = '#{city}' and postal_address_type_code = '#{postal_address_type_code}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.address1]}
	@address1s.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('parties_postal_address','address1',@address1s)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_parties_postal_address_address1'/>
		<%= observe_field('parties_postal_address_address1',:update => 'address2_cell',:url => {:action => session[:parties_postal_address_search_form][:address1_observer][:remote_method]},:loading => "show_element('img_parties_postal_address_address1');",:complete => session[:parties_postal_address_search_form][:address1_observer][:on_completed_js])%>
		}

end


def parties_postal_address_address1_search_combo_changed
	address1 = get_selected_combo_value(params)
	session[:parties_postal_address_search_form][:address1_combo_selection] = address1
	city = 	session[:parties_postal_address_search_form][:city_combo_selection]
	postal_address_type_code = 	session[:parties_postal_address_search_form][:postal_address_type_code_combo_selection]
	party_name = 	session[:parties_postal_address_search_form][:party_name_combo_selection]
	party_type_name = 	session[:parties_postal_address_search_form][:party_type_name_combo_selection]
	@address2s = PartiesPostalAddress.find_by_sql("Select distinct address2 from parties_postal_addresses where address1 = '#{address1}' and city = '#{city}' and postal_address_type_code = '#{postal_address_type_code}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.address2]}
	@address2s.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('parties_postal_address','address2',@address2s)%>

		}

end

#==========================
#POSTAL ADDRESS CODE
#==========================
def list_postal_addresses
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:postal_addresses_page] = params['page']

		 render_list_postal_addresses

		 return 
	else
		session[:postal_addresses_page] = nil
	end

	list_query = "@postal_address_pages = Paginator.new self, PostalAddress.count, @@page_size,@current_page
	 @postal_addresses = PostalAddress.find(:all,
				 :limit => @postal_address_pages.items_per_page,
				 :offset => @postal_address_pages.current.offset)"
	session[:query] = list_query
	render_list_postal_addresses
end


def render_list_postal_addresses
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:postal_addresses_page] if session[:postal_addresses_page]
	@current_page = params['page'] if params['page']
	@postal_addresses =  eval(session[:query]) if !@postal_addresses
	render :inline => %{
      <% grid            = build_postal_address_grid(@postal_addresses,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all postal_addresses' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@postal_address_pages) if @postal_address_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_postal_addresses_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_postal_address_search_form
end

def render_postal_address_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  postal_addresses'"%> 

		<%= build_postal_address_search_form(nil,'submit_postal_addresses_search','submit_postal_addresses_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_postal_addresses_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_postal_address_search_form(true)
end

def render_postal_address_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  postal_addresses'"%> 

		<%= build_postal_address_search_form(nil,'submit_postal_addresses_search','submit_postal_addresses_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_postal_addresses_search
	if params['page']
		session[:postal_addresses_page] =params['page']
	else
		session[:postal_addresses_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @postal_addresses = dynamic_search(params[:postal_address] ,'postal_addresses','PostalAddress')
	else
		@postal_addresses = eval(session[:query])
	end
	if @postal_addresses.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_postal_address_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_postal_addresses
		end

	else

		render_list_postal_addresses
	end
end

 
def delete_postal_address
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:postal_addresses_page] = params['page']
		render_list_postal_addresses
		return
	end
	id = params[:id]
	if id && postal_address = PostalAddress.find(id)
		postal_address.destroy
		session[:alert] = " Record deleted."
		render_list_postal_addresses
	end
  rescue
     handle_error("postal address could not be deleted")
   end
end
 
def new_postal_address
	return if authorise_for_web(program_name?,'create')== false
		render_new_postal_address
end
 
def create_postal_address
   begin
	 @postal_address = PostalAddress.new(params[:postal_address])
	 if @postal_address.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_postal_address
	 end
	rescue
     handle_error("postal address could not be created")
   end
end

def render_new_postal_address
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new postal_address'"%> 

		<%= build_postal_address_form(@postal_address,'create_postal_address','create_postal_address',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_postal_address
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @postal_address = PostalAddress.find(id)
		render_edit_postal_address

	 end
end


def render_edit_postal_address
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit postal_address'"%> 

		<%= build_postal_address_form(@postal_address,'update_postal_address','update_postal_address',true)%>

		}, :layout => 'content'
end
 
def update_postal_address
  begin
	if params[:page]
		session[:postal_addresses_page] = params['page']
		render_list_postal_addresses
		return
	end

		@current_page = session[:postal_addresses_page]
	 id = params[:postal_address][:id]
	 if id && @postal_address = PostalAddress.find(id)
		 if @postal_address.update_attributes(params[:postal_address])
			@postal_addresses = eval(session[:query])
			render_list_postal_addresses
	 else
			 render_edit_postal_address

		 end
	 end
	rescue
     handle_error("postal address could not be updated")
   end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: postal_address_type_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(postal_addresses)
#	-----------------------------------------------------------------------------------------------------------
def postal_address_postal_address_type_code_search_combo_changed
	postal_address_type_code = get_selected_combo_value(params)
	session[:postal_address_search_form][:postal_address_type_code_combo_selection] = postal_address_type_code
	@cities = PostalAddress.find_by_sql("Select distinct city from postal_addresses where postal_address_type_code = '#{postal_address_type_code}'").map{|g|[g.city]}
	@cities.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('postal_address','city',@cities)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_postal_address_city'/>
		<%= observe_field('postal_address_city',:update => 'address1_cell',:url => {:action => session[:postal_address_search_form][:city_observer][:remote_method]},:loading => "show_element('img_postal_address_city');",:complete => session[:postal_address_search_form][:city_observer][:on_completed_js])%>
		}

end


def postal_address_city_search_combo_changed
	city = get_selected_combo_value(params)
	session[:postal_address_search_form][:city_combo_selection] = city
	postal_address_type_code = 	session[:postal_address_search_form][:postal_address_type_code_combo_selection]
	@address1s = PostalAddress.find_by_sql("Select distinct address1 from postal_addresses where city = '#{city}' and postal_address_type_code = '#{postal_address_type_code}'").map{|g|[g.address1]}
	@address1s.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('postal_address','address1',@address1s)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_postal_address_address1'/>
		<%= observe_field('postal_address_address1',:update => 'address2_cell',:url => {:action => session[:postal_address_search_form][:address1_observer][:remote_method]},:loading => "show_element('img_postal_address_address1');",:complete => session[:postal_address_search_form][:address1_observer][:on_completed_js])%>
		}

end


def postal_address_address1_search_combo_changed
	address1 = get_selected_combo_value(params)
	session[:postal_address_search_form][:address1_combo_selection] = address1
	city = 	session[:postal_address_search_form][:city_combo_selection]
	postal_address_type_code = 	session[:postal_address_search_form][:postal_address_type_code_combo_selection]
	@address2s = PostalAddress.find_by_sql("Select distinct address2 from postal_addresses where address1 = '#{address1}' and city = '#{city}' and postal_address_type_code = '#{postal_address_type_code}'").map{|g|[g.address2]}
	@address2s.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('postal_address','address2',@address2s)%>

		}

end

#===================================
#POSTAL ADDRESS TYPE CODE
#===================================
def list_postal_address_types
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:postal_address_types_page] = params['page']

		 render_list_postal_address_types

		 return 
	else
		session[:postal_address_types_page] = nil
	end

	list_query = "@postal_address_type_pages = Paginator.new self, PostalAddressType.count, @@page_size,@current_page
	 @postal_address_types = PostalAddressType.find(:all,
				 :limit => @postal_address_type_pages.items_per_page,
				 :offset => @postal_address_type_pages.current.offset)"
	session[:query] = list_query
	render_list_postal_address_types
end


def render_list_postal_address_types
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:postal_address_types_page] if session[:postal_address_types_page]
	@current_page = params['page'] if params['page']
	@postal_address_types =  eval(session[:query]) if !@postal_address_types
	render :inline => %{
      <% grid            = build_postal_address_type_grid(@postal_address_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all postal_address_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@postal_address_type_pages) if @postal_address_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_postal_address_types_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_postal_address_type_search_form
end

def render_postal_address_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  postal_address_types'"%> 

		<%= build_postal_address_type_search_form(nil,'submit_postal_address_types_search','submit_postal_address_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_postal_address_types_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_postal_address_type_search_form(true)
end

def render_postal_address_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  postal_address_types'"%> 

		<%= build_postal_address_type_search_form(nil,'submit_postal_address_types_search','submit_postal_address_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_postal_address_types_search
	if params['page']
		session[:postal_address_types_page] =params['page']
	else
		session[:postal_address_types_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @postal_address_types = dynamic_search(params[:postal_address_type] ,'postal_address_types','PostalAddressType')
	else
		@postal_address_types = eval(session[:query])
	end
	if @postal_address_types.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_postal_address_type_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_postal_address_types
		end

	else

		render_list_postal_address_types
	end
end

 
def delete_postal_address_type
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:postal_address_types_page] = params['page']
		render_list_postal_address_types
		return
	end
	id = params[:id]
	if id && postal_address_type = PostalAddressType.find(id)
		postal_address_type.destroy
		session[:alert] = " Record deleted."
		render_list_postal_address_types
	end
  rescue
     handle_error("postal address type could not be deleted")
   end
end
 
def new_postal_address_type
	return if authorise_for_web(program_name?,'create')== false
		render_new_postal_address_type
end
 
def create_postal_address_type
   begin
	 @postal_address_type = PostalAddressType.new(params[:postal_address_type])
	 if @postal_address_type.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_postal_address_type
	 end
   rescue
     handle_error("postal address type could not be created")
   end
end

def render_new_postal_address_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new postal_address_type'"%> 

		<%= build_postal_address_type_form(@postal_address_type,'create_postal_address_type','create_postal_address_type',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_postal_address_type
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @postal_address_type = PostalAddressType.find(id)
		render_edit_postal_address_type

	 end
end


def render_edit_postal_address_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit postal_address_type'"%> 

		<%= build_postal_address_type_form(@postal_address_type,'update_postal_address_type','update_postal_address_type',true)%>

		}, :layout => 'content'
end
 
def update_postal_address_type
  begin
	if params[:page]
		session[:postal_address_types_page] = params['page']
		render_list_postal_address_types
		return
	end

		@current_page = session[:postal_address_types_page]
	 id = params[:postal_address_type][:id]
	 if id && @postal_address_type = PostalAddressType.find(id)
		 if @postal_address_type.update_attributes(params[:postal_address_type])
			@postal_address_types = eval(session[:query])
			render_list_postal_address_types
	 else
			 render_edit_postal_address_type

		 end
	 end
	rescue
     handle_error("postal address type could not be updated")
   end
 end

#================================
#CONTACT METHOD PARTY CONTROLLER
#================================
def list_contact_methods_parties
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:contact_methods_parties_page] = params['page']

		 render_list_contact_methods_parties

		 return 
	else
		session[:contact_methods_parties_page] = nil
	end

	list_query = "@contact_methods_party_pages = Paginator.new self, ContactMethodsParty.count, @@page_size,@current_page
	 @contact_methods_parties = ContactMethodsParty.find(:all,
				 :limit => @contact_methods_party_pages.items_per_page,
				 :offset => @contact_methods_party_pages.current.offset)"
	session[:query] = list_query
	render_list_contact_methods_parties
end


def render_list_contact_methods_parties
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:contact_methods_parties_page] if session[:contact_methods_parties_page]
	@current_page = params['page'] if params['page']
	@contact_methods_parties =  eval(session[:query]) if !@contact_methods_parties
	render :inline => %{
      <% grid            = build_contact_methods_party_grid(@contact_methods_parties,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all contact_methods_parties' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@contact_methods_party_pages) if @contact_methods_party_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_contact_methods_parties_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_contact_methods_party_search_form
end

def render_contact_methods_party_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  contact_methods_parties'"%> 

		<%= build_contact_methods_party_search_form(nil,'submit_contact_methods_parties_search','submit_contact_methods_parties_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def find_party_contact_methods
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_contact_methods_party_search_form(true)
end

def render_contact_methods_party_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  contact_methods_parties'"%> 

		<%= build_contact_methods_party_search_form(nil,'submit_contact_methods_parties_search','submit_contact_methods_parties_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_contact_methods_parties_search
	if params['page']
		session[:contact_methods_parties_page] =params['page']
	else
		session[:contact_methods_parties_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @contact_methods_parties = dynamic_search(params[:contact_methods_party] ,'contact_methods_parties','ContactMethodsParty')
	else
		@contact_methods_parties = eval(session[:query])
	end
	if @contact_methods_parties.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_contact_methods_party_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_contact_methods_parties
		end

	else

		render_list_contact_methods_parties
	end
end

 
def delete_contact_methods_party
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:contact_methods_parties_page] = params['page']
		render_list_contact_methods_parties
		return
	end
	id = params[:id]
	if id && contact_methods_party = ContactMethodsParty.find(id)
		contact_methods_party.destroy
		session[:alert] = " Record deleted."
		render_list_contact_methods_parties
	end
  rescue
     handle_error("contact method could not be removed from party")
   end
end
 
def add_party_contact_method
	return if authorise_for_web(program_name?,'create')== false
		render_new_contact_methods_party
end
 
def create_contact_methods_party
   begin
	 @contact_methods_party = ContactMethodsParty.new(params[:contact_methods_party])
	 if @contact_methods_party.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_contact_methods_party
	 end
   rescue
     handle_error("contact method not be added to party")
   end
end

def render_new_contact_methods_party
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new contact_methods_party'"%> 

		<%= build_contact_methods_party_form(@contact_methods_party,'create_contact_methods_party','create_contact_methods_party',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_contact_methods_party
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @contact_methods_party = ContactMethodsParty.find(id)
		render_edit_contact_methods_party

	 end
end


def render_edit_contact_methods_party
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit contact_methods_party'"%> 

		<%= build_contact_methods_party_form(@contact_methods_party,'update_contact_methods_party','update_contact_methods_party',true)%>

		}, :layout => 'content'
end
 
def update_contact_methods_party
  begin
	if params[:page]
		session[:contact_methods_parties_page] = params['page']
		render_list_contact_methods_parties
		return
	end

		@current_page = session[:contact_methods_parties_page]
	 id = params[:contact_methods_party][:id]
	 if id && @contact_methods_party = ContactMethodsParty.find(id)
		 if @contact_methods_party.update_attributes(params[:contact_methods_party])
			@contact_methods_parties = eval(session[:query])
			render_list_contact_methods_parties
	 else
			 render_edit_contact_methods_party

		 end
	 end
  rescue
     handle_error("contact method could not be updated for party")
   end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: contact_method_id
#	---------------------------------------------------------------------------------
def contact_methods_party_contact_method_type_code_changed
	contact_method_type_code = get_selected_combo_value(params)
	session[:contact_methods_party_form][:contact_method_type_code_combo_selection] = contact_method_type_code
	@contact_method_codes = ContactMethodsParty.contact_method_codes_for_contact_method_type_code(contact_method_type_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('contact_methods_party','contact_method_code',@contact_method_codes)%>

		}

end


#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: party_id
#	---------------------------------------------------------------------------------
def contact_methods_party_party_type_name_changed
	party_type_name = get_selected_combo_value(params)
	session[:contact_methods_party_form][:party_type_name_combo_selection] = party_type_name
	@party_names = ContactMethodsParty.party_names_for_party_type_name(party_type_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('contact_methods_party','party_name',@party_names)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(contact_methods_parties)
#	-----------------------------------------------------------------------------------------------------------
def contact_methods_party_party_type_name_search_combo_changed
	party_type_name = get_selected_combo_value(params)
	session[:contact_methods_party_search_form][:party_type_name_combo_selection] = party_type_name
	@party_names = ContactMethodsParty.find_by_sql("Select distinct party_name from contact_methods_parties where party_type_name = '#{party_type_name}'").map{|g|[g.party_name]}
	@party_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('contact_methods_party','party_name',@party_names)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_contact_methods_party_party_name'/>
		<%= observe_field('contact_methods_party_party_name',:update => 'contact_method_type_code_cell',:url => {:action => session[:contact_methods_party_search_form][:party_name_observer][:remote_method]},:loading => "show_element('img_contact_methods_party_party_name');",:complete => session[:contact_methods_party_search_form][:party_name_observer][:on_completed_js])%>
		}

end


def contact_methods_party_party_name_search_combo_changed
	party_name = get_selected_combo_value(params)
	session[:contact_methods_party_search_form][:party_name_combo_selection] = party_name
	party_type_name = 	session[:contact_methods_party_search_form][:party_type_name_combo_selection]
	@contact_method_type_codes = ContactMethodsParty.find_by_sql("Select distinct contact_method_type_code from contact_methods_parties where party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.contact_method_type_code]}
	@contact_method_type_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('contact_methods_party','contact_method_type_code',@contact_method_type_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_contact_methods_party_contact_method_type_code'/>
		<%= observe_field('contact_methods_party_contact_method_type_code',:update => 'contact_method_code_cell',:url => {:action => session[:contact_methods_party_search_form][:contact_method_type_code_observer][:remote_method]},:loading => "show_element('img_contact_methods_party_contact_method_type_code');",:complete => session[:contact_methods_party_search_form][:contact_method_type_code_observer][:on_completed_js])%>
		}

end


def contact_methods_party_contact_method_type_code_search_combo_changed
	contact_method_type_code = get_selected_combo_value(params)
	session[:contact_methods_party_search_form][:contact_method_type_code_combo_selection] = contact_method_type_code
	party_name = 	session[:contact_methods_party_search_form][:party_name_combo_selection]
	party_type_name = 	session[:contact_methods_party_search_form][:party_type_name_combo_selection]
	@contact_method_codes = ContactMethodsParty.find_by_sql("Select distinct contact_method_code from contact_methods_parties where contact_method_type_code = '#{contact_method_type_code}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.contact_method_code]}
	@contact_method_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('contact_methods_party','contact_method_code',@contact_method_codes)%>

		}

end

#=========================
#CONTACT METHOD TYPE CODE
#=========================
def list_contact_method_types
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:contact_method_types_page] = params['page']

		 render_list_contact_method_types

		 return 
	else
		session[:contact_method_types_page] = nil
	end

	list_query = "@contact_method_type_pages = Paginator.new self, ContactMethodType.count, @@page_size,@current_page
	 @contact_method_types = ContactMethodType.find(:all,
				 :limit => @contact_method_type_pages.items_per_page,
				 :offset => @contact_method_type_pages.current.offset)"
	session[:query] = list_query
	render_list_contact_method_types
end


def render_list_contact_method_types
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:contact_method_types_page] if session[:contact_method_types_page]
	@current_page = params['page'] if params['page']
	@contact_method_types =  eval(session[:query]) if !@contact_method_types
	render :inline => %{
      <% grid            = build_contact_method_type_grid(@contact_method_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all contact_method_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@contact_method_type_pages) if @contact_method_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_contact_method_types_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_contact_method_type_search_form
end

def render_contact_method_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  contact_method_types'"%> 

		<%= build_contact_method_type_search_form(nil,'submit_contact_method_types_search','submit_contact_method_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_contact_method_types_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_contact_method_type_search_form(true)
end

def render_contact_method_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  contact_method_types'"%> 

		<%= build_contact_method_type_search_form(nil,'submit_contact_method_types_search','submit_contact_method_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_contact_method_types_search
	if params['page']
		session[:contact_method_types_page] =params['page']
	else
		session[:contact_method_types_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @contact_method_types = dynamic_search(params[:contact_method_type] ,'contact_method_types','ContactMethodType')
	else
		@contact_method_types = eval(session[:query])
	end
	if @contact_method_types.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_contact_method_type_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_contact_method_types
		end

	else

		render_list_contact_method_types
	end
end

 
def delete_contact_method_type
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:contact_method_types_page] = params['page']
		render_list_contact_method_types
		return
	end
	id = params[:id]
	if id && contact_method_type = ContactMethodType.find(id)
		contact_method_type.destroy
		session[:alert] = " Record deleted."
		render_list_contact_method_types
	end
  rescue
     handle_error("contact method type could not be deleted")
   end
end
 
def new_contact_method_type
	return if authorise_for_web(program_name?,'create')== false
		render_new_contact_method_type
end
 
def create_contact_method_type
   begin
	 @contact_method_type = ContactMethodType.new(params[:contact_method_type])
	 if @contact_method_type.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_contact_method_type
	 end
  rescue
     handle_error("contact method type not be created")
   end
end

def render_new_contact_method_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new contact_method_type'"%> 

		<%= build_contact_method_type_form(@contact_method_type,'create_contact_method_type','create_contact_method_type',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_contact_method_type
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @contact_method_type = ContactMethodType.find(id)
		render_edit_contact_method_type

	 end
end


def render_edit_contact_method_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit contact_method_type'"%> 

		<%= build_contact_method_type_form(@contact_method_type,'update_contact_method_type','update_contact_method_type',true)%>

		}, :layout => 'content'
end
 
def update_contact_method_type
  begin
	if params[:page]
		session[:contact_method_types_page] = params['page']
		render_list_contact_method_types
		return
	end

		@current_page = session[:contact_method_types_page]
	 id = params[:contact_method_type][:id]
	 if id && @contact_method_type = ContactMethodType.find(id)
		 if @contact_method_type.update_attributes(params[:contact_method_type])
			@contact_method_types = eval(session[:query])
			render_list_contact_method_types
	 else
			 render_edit_contact_method_type

		 end
	 end
	rescue
     handle_error("contact method type could nt be updated")
   end
 end
 
#===================
#CONTACT METHOD CODE
#===================
def list_contact_methods
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:contact_methods_page] = params['page']

		 render_list_contact_methods

		 return 
	else
		session[:contact_methods_page] = nil
	end

	list_query = "@contact_method_pages = Paginator.new self, ContactMethod.count, @@page_size,@current_page
	 @contact_methods = ContactMethod.find(:all,
				 :limit => @contact_method_pages.items_per_page,
				 :offset => @contact_method_pages.current.offset)"
	session[:query] = list_query
	render_list_contact_methods
end


def render_list_contact_methods
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:contact_methods_page] if session[:contact_methods_page]
	@current_page = params['page'] if params['page']
	@contact_methods =  eval(session[:query]) if !@contact_methods
	render :inline => %{
      <% grid            = build_contact_method_grid(@contact_methods,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all contact_methods' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@contact_method_pages) if @contact_method_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_contact_methods_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_contact_method_search_form
end

def render_contact_method_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  contact_methods'"%> 

		<%= build_contact_method_search_form(nil,'submit_contact_methods_search','submit_contact_methods_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_contact_methods_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_contact_method_search_form(true)
end

def render_contact_method_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  contact_methods'"%> 

		<%= build_contact_method_search_form(nil,'submit_contact_methods_search','submit_contact_methods_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_contact_methods_search
	if params['page']
		session[:contact_methods_page] =params['page']
	else
		session[:contact_methods_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @contact_methods = dynamic_search(params[:contact_method] ,'contact_methods','ContactMethod')
	else
		@contact_methods = eval(session[:query])
	end
	if @contact_methods.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_contact_method_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_contact_methods
		end

	else

		render_list_contact_methods
	end
end

 
def delete_contact_method
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:contact_methods_page] = params['page']
		render_list_contact_methods
		return
	end
	id = params[:id]
	if id && contact_method = ContactMethod.find(id)
		contact_method.destroy
		session[:alert] = " Record deleted."
		render_list_contact_methods
	end
  rescue
     handle_error("contact method could not be deleted")
   end
end
 
def new_contact_method
	return if authorise_for_web(program_name?,'create')== false
		render_new_contact_method
end
 
def create_contact_method
   begin
	 @contact_method = ContactMethod.new(params[:contact_method])
	 if @contact_method.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_contact_method
	 end
  rescue
     handle_error("contact method not be created")
   end
end

def render_new_contact_method
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new contact_method'"%> 

		<%= build_contact_method_form(@contact_method,'create_contact_method','create_contact_method',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_contact_method
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @contact_method = ContactMethod.find(id)
		render_edit_contact_method

	 end
end


def render_edit_contact_method
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit contact_method'"%> 

		<%= build_contact_method_form(@contact_method,'update_contact_method','update_contact_method',true)%>

		}, :layout => 'content'
end
 
def update_contact_method
  begin
	if params[:page]
		session[:contact_methods_page] = params['page']
		render_list_contact_methods
		return
	end

		@current_page = session[:contact_methods_page]
	 id = params[:contact_method][:id]
	 if id && @contact_method = ContactMethod.find(id)
		 if @contact_method.update_attributes(params[:contact_method])
			@contact_methods = eval(session[:query])
			render_list_contact_methods
	 else
			 render_edit_contact_method

		 end
	 end
  rescue
     handle_error("contact method could nt be updated")
   end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: contact_method_type_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(contact_methods)
#	-----------------------------------------------------------------------------------------------------------
def contact_method_contact_method_type_code_search_combo_changed
	contact_method_type_code = get_selected_combo_value(params)
	session[:contact_method_search_form][:contact_method_type_code_combo_selection] = contact_method_type_code
	@contact_method_codes = ContactMethod.find_by_sql("Select distinct contact_method_code from contact_methods where contact_method_type_code = '#{contact_method_type_code}'").map{|g|[g.contact_method_code]}
	@contact_method_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('contact_method','contact_method_code',@contact_method_codes)%>

		}

end

 def postal_adress_type_changed
   
   type = get_selected_combo_value(params)
   
   if type.upcase != "CARTON_LABEL_ADDRESS"
     render :inline => %{ }
     return
   end
   
   
    render :inline => %{
   
   <script>
    <%= update_element_function(
        "city_cell", :action => :update,
        :content => "<font color = 'blue'>n.a: (must be part of line 1 or 2)</font>") %>
        
     <%= update_element_function(
        "postal_code_cell", :action => :update,
        :content => "<font color = 'blue'>n.a: (must be part of line 1 or 2)</font>") %>
        
     </script>
     }
 
 end

	def upload_org_addresses_and_contacts
		if params[:csv_file].blank?
			render :template => '/party_manager/contact_method/upload_file.rhtml', :layout => 'content'
			return
		end

		lines = CSV.parse(params[:csv_file].read)
		create_contacts_and_addresses(lines)
	end

	def display_contacts_and_addresses_error(error)
		flash[:error] = error
		render :inline => %{}, :layout => 'content'
	end

	def create_contacts_and_addresses(lines)

		if(lines.empty? || lines.length < 2)
			display_contacts_and_addresses_error("Your CSV file is blank. Please fill in data in the structure that is required")
			return
		end

		headers = lines.shift
		keys = Hash.new
		headers.map { |h| keys.store(h.to_s.strip, headers.index(h)) }

		or_clause = []
		ActiveRecord::Base.transaction do
			lines.each do |line|
				change_only_for_org = (keys['change_only_for_org'] ? line[keys['change_only_for_org']] : nil)
				if(keys['org_name'] && line[keys['org_name']].to_s.strip.empty?)
					error = "Error on line #{lines.index(line)+1}. org_name cannot be empty<br>"
					error << "<br>org_name,postal_address_type_code,city,address1,address2,postal_code,mobile,email,change_only_for_org"
					error << "<br><label style='color:red;'>insert org_name here</label>,#{line[keys['postal_address_type_code']]},#{line[keys['city']]},#{line[keys['address1']]},#{line[keys['address2']]},#{line[keys['postal_code']]},#{line[keys['mobile']]},#{line[keys['email']]}, #{change_only_for_org}"
				elsif(keys['postal_address_type_code'] && line[keys['postal_address_type_code']].to_s.strip.empty?)
					error = "Error on line #{lines.index(line)+1}. postal_address_type_code cannot be empty<br>"
					error << "<br>org_name,postal_address_type_code,city,address1,address2,postal_code,mobile,email,change_only_for_org"
					error << "<br>#{line[keys['org_name']]},<label style='color:red;'>insert postal_address_type_code here</label>,#{line[keys['city']]},#{line[keys['address1']]},#{line[keys['address2']]},#{line[keys['postal_code']]},#{line[keys['mobile']]},#{line[keys['email']]}, #{change_only_for_org}"
				elsif(keys['address1'] && line[keys['address1']].to_s.strip.empty?)
					error = "Error on line #{lines.index(line)+1}. address1 cannot be empty<br>"
					error << "<br>org_name,postal_address_type_code,city,address1,address2,address3,postal_code,mobile,email,change_only_for_org"
					error << "<br>#{line[keys['org_name']]},#{line[keys['postal_address_type_code']]},#{line[keys['city']]},<label style='color:red;'>insert address1 here</label>,#{line[keys['address2']]},#{line[keys['address3']]},#{line[keys['postal_code']]},#{line[keys['mobile']]},#{line[keys['email']]}, #{change_only_for_org}"
				end

				return display_contacts_and_addresses_error(error) if(error)

				puts "org_name,postal_address_type_code,city,address1,address2,postal_code,mobile,email,change_only_for_org"
				puts "#{line[keys['org_name']]},#{line[keys['postal_address_type_code']]},#{line[keys['city']]},#{line[keys['address1']]},#{line[keys['address2']]},#{line[keys['postal_code']]},#{line[keys['mobile']]},#{line[keys['email']]}, #{change_only_for_org}"
				Party.set_address_info(keys, line, change_only_for_org)
				or_clause << "ppa.party_name='#{line[keys['org_name']]}'"
			end
		end

		# where_clause = "and (#{or_clause.join(' or ')})" if(!or_clause.empty?)
		@parties = PartiesPostalAddress.find_by_sql("SELECT ppa.id,ppa.party_name as org_name, ppa.city,ppa.address1 ,ppa.address2 ,a.postal_code,a.postal_address_type_code
																								,(SELECT contact_methods_parties.contact_method_code
																								FROM contact_methods_parties
																								join contact_methods c on contact_methods_parties.contact_method_id=c.id
																								WHERE contact_methods_parties.contact_method_type_code='Mobile'
																								and contact_methods_parties.party_type_name=ppa.party_type_name
																								and contact_methods_parties.party_name=ppa.party_name
																								LIMIT 1
																								) as mobile
																								,(SELECT contact_methods_parties.contact_method_code
																								FROM contact_methods_parties
																								join contact_methods c on contact_methods_parties.contact_method_id=c.id
																								WHERE contact_methods_parties.contact_method_type_code='E-mail'
																								and contact_methods_parties.party_type_name=ppa.party_type_name
																								and contact_methods_parties.party_name=ppa.party_name
																								LIMIT 1
																								) as email, false as edited
																								FROM parties_postal_addresses ppa
																								join postal_addresses a on a.id=ppa.postal_address_id
																								WHERE ppa.party_type_name='ORGANIZATION'
																								and (#{or_clause.join(' or ')})")
		parties_contacts
	end

	def parties_contacts
		session[:current_parties_postal_addresses] = @parties
		render :inline => %{
	<% grid            = build_edit_parties_contacts_grid(@parties) %>
	<% grid.caption    = 'list of parties_postal_addresses' %>
	<% @header_content = grid.build_grid_data %>
	<% @pagination = pagination_links(@parties_postal_address_pages) if @parties_postal_address_pages != nil %>
	<%= grid.render_html %>
	<%= grid.render_grid %>
  }, :layout => 'content'
	end

	def add_org_address
		render :inline => %{
			<% @content_header_caption = "'add org address'"%>
			<%= build_edit_party_address_and_contacts_form(@party_postal_address,'submit_add_org_address','submit', false)%>
		}, :layout => 'content'
	end

	def party_postal_address_org_name_search_combo_changed
		org_name = get_selected_combo_value(params)
		parties = ContactMethodsParty.find(:all, :select=>"contact_methods_parties.*", :conditions=>"(contact_methods_parties.contact_method_type_code='Mobile' or contact_methods_parties.contact_method_type_code='E-mail') and contact_methods_parties.party_type_name='ORGANIZATION' and contact_methods_parties.party_name='#{org_name}'",
																			 :joins=>"join contact_methods c on contact_methods_parties.contact_method_id=c.id")
		@mobile = parties.find{|p| p.contact_method_type_code.to_s=='Mobile'}
		@email = parties.find{|p| p.contact_method_type_code.to_s=='E-mail'}

		render :inline => %{
			<%= text_field('party_postal_address', 'mobile', :value=>(@mobile ? @mobile.contact_method_code : '')) %>
			<% email_content = text_field('party_postal_address', 'email', :value=>(@email ? @email.contact_method_code : '')) %>

			<script>
			 jQuery(function() { jQuery( "#party_postal_address_mobile" ).catcomplete({ source: "/party_manager/contact_method/auto_complete_mobile", minLength: 2 }); });
			</script>

			<script>
          <%= update_element_function("email_cell", :action => :update,:content => email_content) %>
					jQuery(function() { jQuery( "#party_postal_address_email" ).catcomplete({ source: "/party_manager/contact_method/auto_complete_email", minLength: 2 }); });
      </script>
		}
	end

	def submit_add_org_address
		lines = []
		params[:party_postal_address][:change_only_for_org] = (params[:party_postal_address][:change_only_for_org]=='1')
		lines << params[:party_postal_address].keys
		lines << params[:party_postal_address].values
		create_contacts_and_addresses(lines)
	end

	def get_auto_complete_list(model, filter, extra_condition = nil)
		return eval "#{model}.find(:all,
															 :select => 'DISTINCT #{filter}',
															 :order => '#{filter}',
															 :conditions => \"(#{filter} LIKE '%#{params[:term]}%' OR #{filter} LIKE '%#{params[:term].upcase}%'
																								OR #{filter} LIKE '%#{Inflector.camelize(params[:term])}%') #{extra_condition}\").map {|r| r.#{filter} }"
	end

	def auto_complete_city
		render :json => get_auto_complete_list(PostalAddress, 'city').to_json
	end

	def auto_complete_address1
		render :json => get_auto_complete_list(PostalAddress, 'address1').to_json
	end

	def auto_complete_address2
		render :json => get_auto_complete_list(PostalAddress, 'address2').to_json
	end

	def auto_complete_postal_code
		render :json => get_auto_complete_list(PostalAddress, 'postal_code').to_json
	end

	def auto_complete_mobile
		render :json => get_auto_complete_list(ContactMethod, 'contact_method_code', " and contact_method_type_code='Mobile'").to_json
	end

	def auto_complete_email
		render :json => get_auto_complete_list(ContactMethod, 'contact_method_code', " and contact_method_type_code='E-mail'").to_json
	end

	def list_org_addresses

		# @parties = PartiesPostalAddress.find_by_sql("(SELECT distinct (ppa.id||'') as id,ppa.party_name as org_name, ppa.city,ppa.address1 ,ppa.address2 ,a.postal_code
		# ,a.postal_address_type_code
		# ,(SELECT contact_methods_parties.contact_method_code
		# FROM contact_methods_parties
		# join contact_methods c on contact_methods_parties.contact_method_id=c.id
		# WHERE contact_methods_parties.contact_method_type_code='Mobile'
		# and contact_methods_parties.party_type_name=ppa.party_type_name
		# and contact_methods_parties.party_name=ppa.party_name
		# LIMIT 1
		# ) as mobile
		# ,(SELECT contact_methods_parties.contact_method_code
		# FROM contact_methods_parties
		# join contact_methods c on contact_methods_parties.contact_method_id=c.id
		# WHERE contact_methods_parties.contact_method_type_code='E-mail'
		# and contact_methods_parties.party_type_name=ppa.party_type_name
		# and contact_methods_parties.party_name=ppa.party_name
		# LIMIT 1
		# ) as email, false as edited
		# FROM parties_postal_addresses ppa
		# join postal_addresses a on a.id=ppa.postal_address_id
		# left outer join parties_roles pr on (pr.party_type_name=ppa.party_type_name and pr.party_name=ppa.party_name)
		# WHERE ppa.party_type_name='ORGANIZATION')
    #
		# union
    #
		# (SELECT distinct
		# (select ('-'||rp.id) as id
		# from parties_roles rp
		# where rp.party_name=pr.party_name
		# limit 1),pr.party_name as org_name, ppa.city,ppa.address1 ,ppa.address2 ,ppa.postal_address_type_code
		# ,a.postal_code
		# ,(SELECT contact_methods_parties.contact_method_code
		# FROM contact_methods_parties
		# join contact_methods c on contact_methods_parties.contact_method_id=c.id
		# WHERE contact_methods_parties.contact_method_type_code='Mobile'
		# and contact_methods_parties.party_type_name=ppa.party_type_name
		# and contact_methods_parties.party_name=ppa.party_name
		# LIMIT 1
		# ) as mobile
		# ,(SELECT contact_methods_parties.contact_method_code
		# FROM contact_methods_parties
		# join contact_methods c on contact_methods_parties.contact_method_id=c.id
		# WHERE contact_methods_parties.contact_method_type_code='E-mail'
		# and contact_methods_parties.party_type_name=ppa.party_type_name
		# and contact_methods_parties.party_name=ppa.party_name
		# LIMIT 1
		# ) as email, false as edited
		# FROM parties_roles pr
		# left outer join parties_postal_addresses ppa on (pr.party_type_name=ppa.party_type_name and pr.party_name=ppa.party_name)
		# left outer join postal_addresses a on a.id=ppa.postal_address_id
		# WHERE pr.party_type_name='ORGANIZATION'
		# and pr.party_name NOT IN (SELECT distinct ippa.party_name as org_name
		# 								FROM parties_postal_addresses ippa
		# 								join postal_addresses ia on ia.id=ippa.postal_address_id
		# 								left outer join parties_roles ipr on (ipr.party_type_name=ippa.party_type_name and ipr.party_name=ippa.party_name)
		# 								WHERE ippa.party_type_name='ORGANIZATION')
		# order by id desc)").sort{|x,y| y.id <=> x.id}

		@parties = PartiesPostalAddress.find_by_sql("
			select case when postal_address_id is null then ('-'||id) else (''||ppa_id) end as id
			,org_name, city,address1 ,address2 ,postal_address_type_code,postal_code
			,mobile,email, edited
			from

			(SELECT distinct
			(select rp.id as id
			from parties_roles rp
			where rp.party_name=pr.party_name
			limit 1)
			,ppa.id as ppa_id
			,ppa.postal_address_id,pr.party_name as org_name, ppa.city,ppa.address1 ,ppa.address2  ,ppa.postal_address_type_code,a.postal_code
			,(SELECT contact_methods_parties.contact_method_code
			FROM contact_methods_parties
			join contact_methods c on contact_methods_parties.contact_method_id=c.id
			WHERE contact_methods_parties.contact_method_type_code='Mobile'
			and contact_methods_parties.party_type_name=ppa.party_type_name
			and contact_methods_parties.party_name=ppa.party_name
			LIMIT 1
			) as mobile
			,(SELECT contact_methods_parties.contact_method_code
			FROM contact_methods_parties
			join contact_methods c on contact_methods_parties.contact_method_id=c.id
			WHERE contact_methods_parties.contact_method_type_code='E-mail'
			and contact_methods_parties.party_type_name=ppa.party_type_name
			and contact_methods_parties.party_name=ppa.party_name
			LIMIT 1
			) as email, false as edited
			FROM parties_roles pr
			left outer join parties_postal_addresses ppa on (pr.party_type_name=ppa.party_type_name and pr.party_name=ppa.party_name)
			left outer join postal_addresses a on a.id=ppa.postal_address_id
			WHERE pr.party_type_name='ORGANIZATION'
			order by id desc)

			as set
			order by id desc
		").sort{|x,y| y.id <=> x.id}


		session[:change_only_for_org] = nil
		parties_contacts
	end

	def parties_contacts
		session[:current_parties_postal_addresses] = @parties
		render :inline => %{
	<% grid            = build_edit_parties_contacts_grid(@parties) %>
	<% grid.caption    = 'list of parties_postal_addresses' %>
	<% @header_content = grid.build_grid_data %>
	<% @pagination = pagination_links(@parties_postal_address_pages) if @parties_postal_address_pages != nil %>
	<%= grid.render_html %>
	<%= grid.render_grid %>
  }, :layout => 'content'
	end

	def edit_party_address_and_contacts
		@party_postal_address = session[:current_parties_postal_addresses].find{|p| p.id.to_s==params[:id]}
		render :inline => %{
			<% @content_header_caption = "'edit organization address and contacts'"%>
			<%= build_edit_party_address_and_contacts_form(@party_postal_address,'submit_edit_party_address_and_contacts','submit')%>
		}, :layout => 'content'
	end

	def submit_edit_party_address_and_contacts
		@parties = session[:current_parties_postal_addresses]
		@session_party = @parties.find{|p| p.id.to_s==params[:party_postal_address][:id]}
		@session_party.postal_code = params[:party_postal_address][:postal_code]
		@session_party.edited = true
		params[:party_postal_address].keys.each do |k|
			eval("@session_party.#{k} = params[:party_postal_address][:#{k}]")
		end

		session[:change_only_for_org] = Hash.new if(!session[:change_only_for_org])
		session[:change_only_for_org].store(params[:party_postal_address][:id].to_s, (params[:party_postal_address][:change_only_for_org]=='1'))

		parties_contacts
	end


	def update_parties_contacts_and_addresses
		submission = grid_edited_values_to_array(params)

		@parties = PartiesPostalAddress.find_by_sql("SELECT ppa.id,ppa.party_name as org_name, ppa.postal_address_type_code,ppa.city,ppa.address1 ,ppa.address2 ,a.postal_code
																								,(SELECT contact_methods_parties.contact_method_code
																								FROM contact_methods_parties
																								join contact_methods c on contact_methods_parties.contact_method_id=c.id
																								WHERE contact_methods_parties.contact_method_type_code='Mobile'
																								and contact_methods_parties.party_type_name=ppa.party_type_name
																								and contact_methods_parties.party_name=ppa.party_name
																								LIMIT 1
																								) as mobile
																								,(SELECT contact_methods_parties.contact_method_code
																								FROM contact_methods_parties
																								join contact_methods c on contact_methods_parties.contact_method_id=c.id
																								WHERE contact_methods_parties.contact_method_type_code='E-mail'
																								and contact_methods_parties.party_type_name=ppa.party_type_name
																								and contact_methods_parties.party_name=ppa.party_name
																								LIMIT 1
																								) as email, false as edited
																								FROM parties_postal_addresses ppa
																								join postal_addresses a on a.id=ppa.postal_address_id
																								WHERE #{eval(params['grid_values']).map{|g| "ppa.id=#{g[:id]}" }.join(" or ")}")

		@parties = @parties.group_by{ |a| a.id } if(!@parties.empty?)

		parties_roles = PartiesRole.find_by_sql("select (select ('-'||rp.id) as id
																						 from parties_roles rp
																						 where rp.party_name=pr.party_name
																						 limit 1),pr.party_name
																						 from parties_roles pr
																						 where pr.party_name NOT IN
																																			(SELECT ppa.party_name
																																			FROM parties_postal_addresses ppa
																																			join postal_addresses a on a.id=ppa.postal_address_id
																																			WHERE #{eval(params['grid_values']).map{|g| "ppa.id=#{g[:id]}" }.join(" or ")})").group_by{ |a| a.id }

		edited_lines = []
		new_lines = []
		headers = nil
		submission.map{|s|
			s.store(:change_only_for_org, session[:change_only_for_org][s[:id].to_s]) if(session[:change_only_for_org])
			if(s[:id]>0)
				s[:org_name] = @parties[s[:id]][0].org_name
				if((s[:org_name].to_s.strip != @parties[s[:id]][0].org_name.to_s.strip) || (s[:postal_code].to_s.strip != @parties[s[:id]][0].postal_code.to_s.strip) ||
						(s[:mobile].to_s.strip != @parties[s[:id]][0].mobile.to_s.strip) ||
						(s[:address2].to_s.strip != @parties[s[:id]][0].address2.to_s.strip) || (s[:address1].to_s.strip != @parties[s[:id]][0].address1.to_s.strip) ||
						(s[:postal_address_type_code].to_s.strip != @parties[s[:id]][0].postal_address_type_code.to_s.strip) ||
						(s[:email].to_s.strip != @parties[s[:id]][0].email.to_s.strip) || (s[:city].to_s.strip != @parties[s[:id]][0].city.to_s.strip) )
					headers = s.keys if(!headers)
					edited_lines << s.values
				end
			else
				s[:org_name] = parties_roles[s[:id]][0].party_name
				if((!s[:postal_code].to_s.empty?) ||	(!s[:mobile].to_s.empty?) ||  (!s[:address1].to_s.empty?) ||
						(!s[:email].to_s.empty?) || (!s[:city].to_s.empty?)  || (!s[:postal_address_type_code].to_s.empty?) )
					headers = s.keys if(!headers)
					new_lines << s.values
				end
			end
		}

		edited_lines += new_lines
		edited_lines.unshift(headers) if(headers)
		session[:change_only_for_org] = nil
		create_contacts_and_addresses(edited_lines)
	end

end
