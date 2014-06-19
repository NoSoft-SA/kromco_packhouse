class  PartyManager::ContactMethodController < ApplicationController
 
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
 
 


end
