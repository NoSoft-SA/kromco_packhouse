class  PartyManager::TradeController < ApplicationController
 
def program_name?
	"trade"
end

def bypass_generic_security?
	true
end

def remove_grade
  grade_tm = GradeTargetMarket.find_by_sql("select * from grade_target_markets where grade_id=#{params[:id]} and target_market_id=#{session[:tm_id]}")[0]
  grade_tm.destroy

  render :inline => %{
                            <script>
                            alert('grade removed');
                            window.close();
                             window.opener.frames[1].frames[0].location.reload(true);
                            </script>
                               }, :layout => 'content'
end

def new_grade_target_market
  @multi_select=true
  @grades=Grade.find_by_sql("select grades.* from grades where id not in (select grade_id from grade_target_markets where target_market_id=#{session[:tm_id]})")
  session[:grades]=@grades
  render_list_grades
end

def selected_grades


  grades   = session[:grades]
  selected_grades = selected_records?(grades, nil, nil)
  for grade in selected_grades
    grade_tm=GradeTargetMarket.new
    grade_tm.grade_id=grade.id
    grade_tm.target_market_id=session[:tm_id]
    grade_tm.save
  end
  render :inline => %{
                          <script>
                          alert('grades added');
                          window.close();
                          window.opener.frames[0].location.reload(true);
                          </script>
                             }, :layout => 'content'
end

def list_grades
  grades=Grade.find_by_sql("select grades.* from grades inner join grade_target_markets on grade_target_markets.grade_id=grades.id
                            where grade_target_markets.target_market_id=#{params[:id]} ")
  @grades    =[]
      grds     ={}
      if !grades.empty?
        for o in grades
          @grades << o if !grds.has_key?(o['grade_code'])
          grds[o['grade_code']]=[o['grade_code']]
        end
      end
  @multi_select=nil
      render_list_grades
end

def render_list_grades
    @can_edit = authorise(program_name?,'edit',session[:user_id])
  	@can_delete = authorise(program_name?,'delete',session[:user_id])
  	@current_page = session[:grades_page] if session[:grades_page]
  	@current_page = params['page'] if params['page']
    if @multi_select
      render :inline => %{
              <% grid            = build_grade_grid(@grades,@can_edit,@can_delete,@multi_select) %>
              <% grid.caption    = ' grades' %>
              <% @header_content = grid.build_grid_data %>
              <% grid.height = '300' %>
              <% @pagination = pagination_links(@grade_pages) if @grade_pages != nil %>
              <%= grid.render_html %>
              <%= grid.render_grid %>
        	},:layout => 'content'
    else
      render :inline => %{
              <% grid            = build_grade_grid(@grades,@can_edit,@can_delete,@multi_select) %>
              <% grid.caption    = ' grades' %>
              <% @header_content = grid.build_grid_data %>
              <% grid.height = '100' %>
              <% @pagination = pagination_links(@grade_pages) if @grade_pages != nil %>
              <%= grid.render_html %>
              <%= grid.render_grid %>
        	},:layout => 'content'
    end

end

def new_trading_partner
   redirect_to :controller => "party_manager/trading_partner",:action => "new_trading_partner"
end

def list_trading_partners
   redirect_to :action => "list_trading_partners", :controller => "party_manager/trading_partner"
end

def new_incoterm
   redirect_to :controller => "party_manager/incoterm",:action => "new_incoterm"
end

def list_incoterms
   redirect_to :action => "list_incoterms", :controller => "party_manager/incoterm"
end

def new_currency
   redirect_to :controller => "party_manager/currency",:action => "new_currency"
end

def list_currencies
   redirect_to :action => "list_currencies", :controller => "party_manager/currency"
 end


#==========================
#DESTINATION COUNTRIES CODE
#==========================
def list_destination_countries
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:destination_countries_page] = params['page']

		 render_list_destination_countries

		 return 
	else
		session[:destination_countries_page] = nil
	end

	list_query = "@destination_country_pages = Paginator.new self, DestinationCountry.count, @@page_size,@current_page
	 @destination_countries = DestinationCountry.find(:all,
				 :limit => @destination_country_pages.items_per_page,
				 :offset => @destination_country_pages.current.offset)"
	session[:query] = list_query
	render_list_destination_countries
end


def render_list_destination_countries
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:destination_countries_page] if session[:destination_countries_page]
	@current_page = params['page'] if params['page']
	@destination_countries =  eval(session[:query]) if !@destination_countries
	render :inline => %{
	  <% grid = build_destination_country_grid(@destination_countries,@can_edit,@can_delete)%>
      <% grid.caption    = 'List of all destination_countries' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@destination_country_pages) if @destination_country_pages != nil %>
      <%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_destination_countries_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_destination_country_search_form
end

def render_destination_country_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  destination_countries'"%> 

		<%= build_destination_country_search_form(nil,'submit_destination_countries_search','submit_destination_countries_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_destination_countries_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_destination_country_search_form(true)
end

def render_destination_country_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  destination_countries'"%> 

		<%= build_destination_country_search_form(nil,'submit_destination_countries_search','submit_destination_countries_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_destination_countries_search
	if params['page']
		session[:destination_countries_page] =params['page']
	else
		session[:destination_countries_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @destination_countries = dynamic_search(params[:destination_country] ,'destination_countries','DestinationCountry')
	else
		@destination_countries = eval(session[:query])
	end
	if @destination_countries.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_destination_country_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_destination_countries
		end

	else

		render_list_destination_countries
	end
end

 
def delete_destination_country
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:destination_countries_page] = params['page']
		render_list_destination_countries
		return
	end
	id = params[:id]
	if id && destination_country = DestinationCountry.find(id)
		destination_country.destroy
		session[:alert] = " Record deleted."
		render_list_destination_countries
	end
  rescue
     handle_error("Destination country could not be deleted")
   end
end
 
def new_destination_country
	return if authorise_for_web(program_name?,'create')== false
		render_new_destination_country
end
 
def create_destination_country
  begin
	 @destination_country = DestinationCountry.new(params[:destination_country])
	 if @destination_country.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_destination_country
	 end
  rescue
     handle_error("Destination country could not be created")
   end
end

def render_new_destination_country
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new destination_country'"%> 

		<%= build_destination_country_form(@destination_country,'create_destination_country','create_destination_country',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_destination_country
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @destination_country = DestinationCountry.find(id)
		render_edit_destination_country

	 end
end


def render_edit_destination_country
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit destination_country'"%> 

		<%= build_destination_country_form(@destination_country,'update_destination_country','update_destination_country',true)%>

		}, :layout => 'content'
end
 
def update_destination_country
  begin
	if params[:page]
		session[:destination_countries_page] = params['page']
		render_list_destination_countries
		return
	end

		@current_page = session[:destination_countries_page]
	 id = params[:destination_country][:id]
	 if id && @destination_country = DestinationCountry.find(id)
		 if @destination_country.update_attributes(params[:destination_country])
			@destination_countries = eval(session[:query])
			render_list_destination_countries
	 else
			 render_edit_destination_country

		 end
	 end
	rescue
     handle_error("Destination country could not be updated")
   end
 end

#===========
#MARKS CODES
#===========
def list_marks
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:marks_page] = params['page']

		 render_list_marks

		 return 
	else
		session[:marks_page] = nil
	end

	list_query = "@mark_pages = Paginator.new self, Mark.count, @@page_size,@current_page
	 @marks = Mark.find(:all,
				 :limit => @mark_pages.items_per_page,
				 :offset => @mark_pages.current.offset)"
	session[:query] = list_query
	render_list_marks
end


def render_list_marks
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:marks_page] if session[:marks_page]
	@current_page = params['page'] if params['page']
	@marks =  eval(session[:query]) if !@marks
	render :inline => %{
	  <% grid = build_mark_grid(@marks,@can_edit,@can_delete)%>
      <% grid.caption    = 'List of all marks' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@mark_pages) if @mark_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
	},:layout => 'content'
end

def search_marks_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_mark_search_form
end

def render_mark_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  marks'"%> 

		<%= build_mark_search_form(nil,'submit_marks_search','submit_marks_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_marks_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_mark_search_form(true)
end

def render_mark_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  marks'"%> 

		<%= build_mark_search_form(nil,'submit_marks_search','submit_marks_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_marks_search
	if params['page']
		session[:marks_page] =params['page']
	else
		session[:marks_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @marks = dynamic_search(params[:mark] ,'marks','Mark')
	else
		@marks = eval(session[:query])
	end
	if @marks.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_mark_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_marks
		end

	else

		render_list_marks
	end
end

 
def delete_mark
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:marks_page] = params['page']
		render_list_marks
		return
	end
	id = params[:id]
	if id && mark = Mark.find(id)
		mark.destroy
		session[:alert] = " Record deleted."
		render_list_marks
	end
  rescue
     handle_error("Mark could not be deleted")
   end
end
 
def new_mark
	return if authorise_for_web(program_name?,'create')== false
		render_new_mark
end
 
def create_mark
  begin
	 @mark = Mark.new(params[:mark])
	 if @mark.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_mark
	 end
  rescue
     handle_error("Mark could not be created")
   end
end

def render_new_mark
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new mark'"%> 

		<%= build_mark_form(@mark,'create_mark','create_mark',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_mark
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @mark = Mark.find(id)
		render_edit_mark

	 end
end


def render_edit_mark
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit mark'"%> 

		<%= build_mark_form(@mark,'update_mark','update_mark',true)%>

		}, :layout => 'content'
end
 
def update_mark
  begin
	if params[:page]
		session[:marks_page] = params['page']
		render_list_marks
		return
	end

		@current_page = session[:marks_page]
	 id = params[:mark][:id]
	 if id && @mark = Mark.find(id)
		 if @mark.update_attributes(params[:mark])
			@marks = eval(session[:query])
			render_list_marks
	 else
			 render_edit_mark

		 end
	 end
	rescue
     handle_error("Mark could not be updated")
   end
 end
 


#====================
#INVENTORY CODES CODE
#====================
def list_inventory_codes
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:inventory_codes_page] = params['page']

		 render_list_inventory_codes

		 return 
	else
		session[:inventory_codes_page] = nil
	end

	list_query = "@inventory_code_pages = Paginator.new self, InventoryCode.count, @@page_size,@current_page
	 @inventory_codes = InventoryCode.find(:all,
				 :limit => @inventory_code_pages.items_per_page,
				 :offset => @inventory_code_pages.current.offset)"
	session[:query] = list_query
	render_list_inventory_codes
end


def render_list_inventory_codes
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:inventory_codes_page] if session[:inventory_codes_page]
	@current_page = params['page'] if params['page']
	@inventory_codes =  eval(session[:query]) if !@inventory_codes
	render :inline => %{
	  <% grid = build_inventory_code_grid(@inventory_codes,@can_edit,@can_delete)%>
      <% grid.caption    = 'List of all inventory_codes' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@inventory_code_pages) if @inventory_code_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
	},:layout => 'content'
end

def search_inventory_codes_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_inventory_code_search_form
end

def render_inventory_code_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  inventory_codes'"%> 

		<%= build_inventory_code_search_form(nil,'submit_inventory_codes_search','submit_inventory_codes_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_inventory_codes_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_inventory_code_search_form(true)
end

def render_inventory_code_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  inventory_codes'"%> 

		<%= build_inventory_code_search_form(nil,'submit_inventory_codes_search','submit_inventory_codes_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_inventory_codes_search
	if params['page']
		session[:inventory_codes_page] =params['page']
	else
		session[:inventory_codes_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @inventory_codes = dynamic_search(params[:inventory_code] ,'inventory_codes','InventoryCode')
	else
		@inventory_codes = eval(session[:query])
	end
	if @inventory_codes.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_inventory_code_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_inventory_codes
		end

	else

		render_list_inventory_codes
	end
end

 
def delete_inventory_code
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:inventory_codes_page] = params['page']
		render_list_inventory_codes
		return
	end
	id = params[:id]
	if id && inventory_code = InventoryCode.find(id)
		inventory_code.destroy
		session[:alert] = " Record deleted."
		render_list_inventory_codes
	end
 rescue
     handle_error("Inventory code could not be deleted")
   end
end
 
def new_inventory_code
	return if authorise_for_web(program_name?,'create')== false
		render_new_inventory_code
end
 
def create_inventory_code
  begin
	 @inventory_code = InventoryCode.new(params[:inventory_code])
	 if @inventory_code.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_inventory_code
	 end
   rescue
     handle_error("Inventory code could not be created")
   end
end

def render_new_inventory_code
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new inventory_code'"%> 

		<%= build_inventory_code_form(@inventory_code,'create_inventory_code','create_inventory_code',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_inventory_code
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @inventory_code = InventoryCode.find(id)
		render_edit_inventory_code

	 end
end


def render_edit_inventory_code
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit inventory_code'"%> 

		<%= build_inventory_code_form(@inventory_code,'update_inventory_code','update_inventory_code',true)%>

		}, :layout => 'content'
end
 
def update_inventory_code
  begin
	if params[:page]
		session[:inventory_codes_page] = params['page']
		render_list_inventory_codes
		return
	end

		@current_page = session[:inventory_codes_page]
	 id = params[:inventory_code][:id]
	 if id && @inventory_code = InventoryCode.find(id)
		 if @inventory_code.update_attributes(params[:inventory_code])
			@inventory_codes = eval(session[:query])
			render_list_inventory_codes
	 else
			 render_edit_inventory_code

		 end
	 end
  rescue
     handle_error("Inventory code could not be updated")
   end
 end
 

#=====================
#TARGET MARKETS CODE
#=====================
def list_target_markets
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:target_markets_page] = params['page']

		 render_list_target_markets

		 return 
	else
		session[:target_markets_page] = nil
	end

	list_query = "@target_market_pages = Paginator.new self, TargetMarket.count, @@page_size,@current_page
	 @target_markets = TargetMarket.find(:all,
				 :limit => @target_market_pages.items_per_page,
				 :offset => @target_market_pages.current.offset)"
	session[:query] = list_query
	render_list_target_markets
end


def render_list_target_markets
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:target_markets_page] if session[:target_markets_page]
	@current_page = params['page'] if params['page']
	@target_markets =  eval(session[:query]) if !@target_markets
	render :inline => %{
      <% grid            = build_target_market_grid(@target_markets,@can_edit,@can_delete) %>
      <% grid.caption    = 'List of all target_markets' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@target_market_pages) if @target_market_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def search_target_markets_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_target_market_search_form
end

def render_target_market_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  target_markets'"%> 

		<%= build_target_market_search_form(nil,'submit_target_markets_search','submit_target_markets_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_target_markets_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_target_market_search_form(true)
end

def render_target_market_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  target_markets'"%> 

		<%= build_target_market_search_form(nil,'submit_target_markets_search','submit_target_markets_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_target_markets_search
	if params['page']
		session[:target_markets_page] =params['page']
	else
		session[:target_markets_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @target_markets = dynamic_search(params[:target_market] ,'target_markets','TargetMarket')
	else
		@target_markets = eval(session[:query])
	end
	if @target_markets.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_target_market_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_target_markets
		end

	else

		render_list_target_markets
	end
end

 
def delete_target_market
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:target_markets_page] = params['page']
		render_list_target_markets
		return
	end
	id = params[:id]
	if id && target_market = TargetMarket.find(id)
		target_market.destroy
		session[:alert] = " Record deleted."
		render_list_target_markets
	end
  rescue
     handle_error("Target market could not be deleted")
   end
end
 
def new_target_market
	return if authorise_for_web(program_name?,'create')== false
		render_new_target_market
end
 
def create_target_market
  begin
	 @target_market = TargetMarket.new(params[:target_market])
	 if @target_market.save
     session[:alert]="'new record created successfully'"
     params[:id]=@target_market.id
     edit_target_market
		 #redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_target_market
	 end
  rescue
     handle_error("Target market could not be created")
   end
end

def render_new_target_market
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new target_market'"%> 

		<%= build_target_market_form(@target_market,'create_target_market','create_target_market',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_target_market
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @target_market = TargetMarket.find(id)
     session[:tm_id]=id
		render_edit_target_market

	 end
end


def render_edit_target_market
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit target_market'"%> 

		<%= build_target_market_form(@target_market,'update_target_market','update_target_market',true)%>

		}, :layout => 'content'
end
 
def update_target_market
  begin
	if params[:page]
		session[:target_markets_page] = params['page']
		render_list_target_markets
		return
	end

		@current_page = session[:target_markets_page]
	 id = params[:target_market][:id]
	 if id && @target_market = TargetMarket.find(id)
		 if @target_market.update_attributes(params[:target_market])
			@target_markets = eval(session[:query])
			render_list_target_markets
	 else
			 render_edit_target_market

		 end
	 end
  rescue
     handle_error("Target market could not be updated")
   end
 end
 
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(target_markets)
#	-----------------------------------------------------------------------------------------------------------

  #================================================
  # DIRECT SALES TARGET MARKET
  #================================================
  def new_direct_sales_tm
    return if authorise_for_web(program_name?,'create') == false
    render_new_direct_sales_tm
  end

  def render_new_direct_sales_tm
    render :inline => %{
		<% @content_header_caption = "'create new direct sales target market'"%>

		<%= build_direct_sales_target_market_form(@direct_sales_tm,'create_direct_sales_target_market','create direct sales tm',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_direct_sales_target_market
     #puts params[:inventory_receipt].to_s
     begin
    	 @direct_sales_tm = DirectSalesTargetMarket.new(params[:direct_sales_tm])
       #@direct_sales_tm.date_created = Time.now.to_formatted_s(:db)
    	 if @direct_sales_tm.save
    	     #session[:inventory_receipt] = @inventory_receipt
    		 redirect_to_index("'new record created successfully'","'create successful'")
    	 else
    		@is_create_retry = true
    		render_new_direct_sales_tm
    	 end
    rescue
       handle_error("direct sales target market could not be created")
    end

  end

  def list_direct_sales_tm
    return if authorise_for_web(program_name?,'read') == false

 	if params[:page]!= nil

 		session[:direct_sales_tms_page] = params['page']

		 render_list_direct_sales_target_markets

		 return
	else
		session[:direct_sales_tms_page] = nil
	end

	list_query = "@direct_sales_tms_pages = Paginator.new self, DirectSalesTargetMarket.count, @@page_size,@current_page
	 @direct_sales_tms = DirectSalesTargetMarket.find(:all,
				 :limit => @direct_sales_tms_pages.items_per_page,
				 :offset => @direct_sales_tms_pages.current.offset)"
	session[:query] = list_query
	render_list_direct_sales_target_markets
  end

  def render_list_direct_sales_target_markets
  	@can_edit = authorise(program_name?,'edit',session[:user_id])
  	@can_delete = authorise(program_name?,'delete',session[:user_id])
  	@current_page = session[:direct_sales_tms_page] if session[:direct_sales_tms_page]
  	@current_page = params['page'] if params['page']
  	@direct_sales_tms =  eval(session[:query]) if !@direct_sales_tms
  	
  	render :inline => %{
      <% grid = build_direct_sales_target_markets_grid(@direct_sales_tms,@can_edit,@can_delete)%>
      <% grid.caption    = 'List of all direct sales target markets' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@direct_sales_tms_pages) if @direct_sales_tms_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    	},:layout => 'content'
  end

  def edit_direct_sales_target_market
     return if authorise_for_web(program_name?,'edit')==false
     id = params['id']
     if id && @direct_sales_tm = DirectSalesTargetMarket.find(id)
       render_edit_direct_sales_target_market
     else

     end
  end

  def render_edit_direct_sales_target_market
     render :inline => %{
		<% @content_header_caption = "'edit direct sales target market'"%>

		<%= build_direct_sales_target_market_form(@direct_sales_tm,'update_direct_sales_target_market','update direct sales tm',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_direct_sales_target_market
      begin
    	if params[:page]
    		session[:direct_sales_tms_page] = params['page']
    		render_list_direct_sales_target_markets
    		return
    	end

    		@current_page = session[:direct_sales_tms_page]
    	 id = params[:direct_sales_tm][:id]
    	 if id && @direct_sales_tm = DirectSalesTargetMarket.find(id)
    		 if @direct_sales_tm.update_attributes(params[:direct_sales_tm])
    			@direct_sales_tm = eval(session[:query])
    			flash[:notice] = 'direct sales target market record updated!'
    			render_list_direct_sales_target_markets
        	 else
             render_edit_direct_sales_target_market
             end
    	 end
      rescue
         handle_error("direct sales target market could not be updated")
       end
  end

  def delete_direct_sales_target_market
     begin
    	return if authorise_for_web(program_name?,'delete')== false
    	if params[:page]
    		session[:direct_sales_tms_page] = params['page']
    		render_list_direct_sales_target_markets
    		return
    	end
    	id = params[:id]
    	if id && direct_sales_tm = DirectSalesTargetMarket.find(id)
    		direct_sales_tm.destroy
    		session[:alert] = " Record deleted."
    		render_list_direct_sales_target_markets
    	end
      rescue
         handle_error("direct sales target market record could not be deleted")
      end
  end


end
