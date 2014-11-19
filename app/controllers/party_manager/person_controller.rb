class PartyManager::PersonController < ApplicationController
 
def program_name?
	"person"
end

def bypass_generic_security?
	true
end

def list_people
	return if authorise_for_web('person','read') == false 

 	if params[:page]!= nil 

 		session[:people_page] = params['page']

		 render_list_people

		 return 
	else
		session[:people_page] = nil
	end

	list_query = "@person_pages = Paginator.new self, Person.count, @@page_size,@current_page
	 @people = Person.find(:all,
				 :limit => @person_pages.items_per_page,
				 :offset => @person_pages.current.offset)"
	session[:query] = list_query
	render_list_people
end


def render_list_people
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:people_page] if session[:people_page]
	@current_page = params['page'] if params['page']
	@people =  eval(session[:query]) if !@people
	render :inline => %{
      <% grid            = build_person_grid(@people,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all people' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@person_pages) if @person_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_people_flat
	return if authorise_for_web('person','read')== false
	@is_flat_search = true 
	render_person_search_form
end

def render_person_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  people'"%> 

		<%= build_person_search_form(nil,'submit_people_search','submit_people_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_people_hierarchy
	return if authorise_for_web('person','read')== false
 
	@is_flat_search = false 
	render_person_search_form(true)
end

def render_person_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  people'"%> 

		<%= build_person_search_form(nil,'submit_people_search','submit_people_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_people_search
	if params['page']
		session[:people_page] =params['page']
	else
		session[:people_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @people = dynamic_search(params[:person] ,'people','Person')
	else
		@people = eval(session[:query])
	end
	if @people.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_person_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_people
		end

	else

		render_list_people
	end
end

 
def delete_person
  begin
	return if authorise_for_web('person','delete')== false
	if params[:page]
		session[:people_page] = params['page']
		render_list_people
		return
	end
	id = params[:id]
	if id && person = Person.find(id)
		person.destroy
		session[:alert] = " Record deleted."
		render_list_people
	end
  rescue
     handle_error("Person could not be deleted")
   end
end
 
def new_person
	return if authorise_for_web('person','create')== false
		render_new_person
end
 
def create_person
   begin
	 @person = Person.new(params[:person])
	 if @person.save
		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_person
	 end
   rescue
     handle_error("Person could not be created")
   end
end

def render_new_person
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new person'"%> 

		<%= build_person_form(@person,'create_person','create_person',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_person
	return if authorise_for_web('person','edit')==false 
	 id = params[:id]
	 if id && @person = Person.find(id)
		render_edit_person

	 end
end


def render_edit_person
  session[:editing_person]=@person
	render :inline => %{
		<% @content_header_caption = "'edit person'"%> 

		<%= build_person_form(@person,'update_person','update_person',true)%>

		}, :layout => 'content'
end
 
def update_person
  begin
	if params[:page]
		session[:people_page] = params['page']
		render_list_people
		return
	end

		@current_page = session[:people_page]
	 id = params[:person][:id]
	 if id && @person = Person.find(id)
     ActiveRecord::Base.transaction do
       @person.update_attributes(params[:person])
       old_party_name=session[:editing_person]['first_name'] + "_" + session[:editing_person]['last_name']
            parties_role = PartiesRole.find_by_party_name(old_party_name)
            if parties_role
              new_party_name=@person.party.party_name
              parties_role.party_name=new_party_name
              parties_role.update
            end
           end
		 if @person
			@people = eval(session[:query])
			render_list_people
	 else
			 render_edit_person

		 end
	 end
	rescue
     handle_error("Person could not be updated")
   end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: party_id
#	---------------------------------------------------------------------------------
def person_party_name_changed
	party_name = get_selected_combo_value(params)
	session[:person_form][:party_name_combo_selection] = party_name
	@party_type_ids = Person.party_type_ids_for_party_name(party_name)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('person','party_type_id',@party_type_ids)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(people)
#	-----------------------------------------------------------------------------------------------------------
def person_first_name_search_combo_changed
	first_name = get_selected_combo_value(params)
	session[:person_search_form][:first_name_combo_selection] = first_name
	@last_names = Person.find_by_sql("Select distinct last_name from people where first_name = '#{first_name}'").map{|g|[g.last_name]}
	@last_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('person','last_name',@last_names)%>

		}

end



end
