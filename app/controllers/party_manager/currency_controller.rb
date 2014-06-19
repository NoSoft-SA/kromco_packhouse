class  PartyManager::CurrencyController < ApplicationController
 
def program_name?
	"trade"
end

def bypass_generic_security?
	true
end
def list_currencies
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:currencies_page] = params['page']

		 render_list_currencies

		 return 
	else
		session[:currencies_page] = nil
	end

	list_query = "@currency_pages = Paginator.new self, Currency.count, @@page_size,@current_page
	 @currencies = Currency.find(:all,
				 :limit => @currency_pages.items_per_page,
				 :offset => @currency_pages.current.offset)"
	session[:query] = list_query
	render_list_currencies
end

def render_list_currencies
	@pagination_server = "list_currencies"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:currencies_page]
	@current_page = params['page']||= session[:currencies_page]
	@currencies =  eval(session[:query]) if !@currencies
  @use_jq_grid = true
	render :inline => %{
		<% grid = build_currency_grid(@currencies,@can_edit,@can_delete)%>
		<% grid.caption = 'list of all currencies'%>
		<% @header_content = grid.build_grid_data %>

		<% @pagination = pagination_links(@currency_pages) if @currency_pages != nil %>
		<%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_currencies_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_currency_search_form
end

def render_currency_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  currencies'"%> 

		<%= build_currency_search_form(nil,'submit_currencies_search','submit_currencies_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_currencies_search
	@currencies = dynamic_search(params[:currency] ,'currencies','Currency')
	if @currencies.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_currency_search_form
		else
			render_list_currencies
	end
end

 
def delete_currency
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:currencies_page] = params['page']
		render_list_currencies
		return
	end
	id = params[:id]
	if id && currency = Currency.find(id)
    t_partner=TradingPartner.find_by_currency_id(id)
    if t_partner
      session[:alert] = 'record is referenced by a trading partner ,it cannot be deleted'
    else
      currency.destroy
      session[:alert] = ' Record deleted.'
    end

		render_list_currencies
	end
	rescue
		handle_error('record could not be deleted')
end
end
 
def new_currency
	return if authorise_for_web(program_name?,'create')== false
		render_new_currency
end
 
def create_currency
 begin
	 @currency = Currency.new(params[:currency])
	 if @currency.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_currency
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_currency
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new currency'"%> 

		<%= build_currency_form(@currency,'create_currency','create_currency',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_currency
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @currency = Currency.find(id)
		render_edit_currency

	 end
end


def render_edit_currency
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit currency'"%> 

		<%= build_currency_form(@currency,'update_currency','update_currency',true)%>

		}, :layout => 'content'
end
 
def update_currency
 begin

	 id = params[:currency][:id]
	 if id && @currency = Currency.find(id)
		 if @currency.update_attributes(params[:currency])
			@currencies = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_currencies
	 else
			 render_edit_currency

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
