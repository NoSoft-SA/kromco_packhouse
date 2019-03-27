class  PartyManager::CityController < ApplicationController
 
def program_name?
	"farm"
end

def bypass_generic_security?
	true
end
def list_cities
	return if authorise_for_web(program_name?,'read') == false

 	if params[:page]!= nil

 		session[:cities_page] = params['page']

		 render_list_cities

		 return
	else
		session[:cities_page] = nil
	end

	sql = "select ci.*,co.country_code
                from cities ci
                join countries co on ci.country_id=co.id where ci.active=true"

	list_query ="City.find_by_sql(\"#{sql}\") "
	session[:query] = list_query
	render_list_cities
end


def render_list_cities
	@pagination_server = "list_cities"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:cities_page]
	@current_page = params['page']||= session[:cities_page]
	@cities =  eval(session[:query]) if !@cities
  	render :inline => %{
		<% grid = build_city_grid(@cities,@can_edit,@can_delete)%>
		<% grid.caption = 'list of all cities'%>
		<% @header_content = grid.build_grid_data %>

		<% @pagination = pagination_links(@city_pages) if @city_pages != nil %>
		<%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_cities_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true
	render_city_search_form
end

def render_city_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  cities'"%>

		<%= build_city_search_form(nil,'submit_cities_search','submit_cities_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_cities_search
	@cities = dynamic_search(params[:city] ,'cities','City')
	if @cities.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_city_search_form
		else
			render_list_cities
	end
end

 
def delete_city
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:cities_page] = params['page']
		render_list_cities
		return
	end
	id = params[:id]
	if id && city = City.find(id)
		city.destroy
		session[:alert] = ' Record deleted.'
		render_list_cities
	end
	rescue
		handle_error('record could not be deleted')
end
end
 
def new_city
	return if authorise_for_web(program_name?,'create')== false
		render_new_city
end
 
def create_city
 begin
	 @city = City.new(params[:city])
	 if @city.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_city
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_city
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new city'"%>

		<%= build_city_form(@city,'create_city','create_city',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_city
	return if authorise_for_web(program_name?,'edit')==false
	 id = params[:id]
	 if id && @city = City.find(id)
		render_edit_city

	 end
end


def render_edit_city
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit city'"%>

		<%= build_city_form(@city,'update_city','update_city',true)%>

		}, :layout => 'content'
end
 
def update_city
 begin

	 id = params[:city][:id]
	 if id && @city = City.find(id)
		 if @city.update_attributes(params[:city])
			@cities = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_cities
	 else
			 render_edit_city

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
