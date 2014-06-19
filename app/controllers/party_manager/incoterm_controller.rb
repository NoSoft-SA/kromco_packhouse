class  PartyManager::IncotermController < ApplicationController
 
def program_name?
	"trade"
end

def bypass_generic_security?
	true
end
def list_incoterms
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:incoterms_page] = params['page']

		 render_list_incoterms

		 return 
	else
		session[:incoterms_page] = nil
	end

	list_query = "@incoterm_pages = Paginator.new self, Incoterm.count, @@page_size,@current_page
	 @incoterms = Incoterm.find(:all,
				 :limit => @incoterm_pages.items_per_page,
				 :offset => @incoterm_pages.current.offset)"
	session[:query] = list_query
	render_list_incoterms
end


def render_list_incoterms
	@pagination_server = "list_incoterms"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:incoterms_page]
	@current_page = params['page']||= session[:incoterms_page]
	@incoterms =  eval(session[:query]) if !@incoterms
  @use_jq_grid = true

	render :inline => %{
		<% grid = build_incoterm_grid(@incoterms,@can_edit,@can_delete)%>
		<% grid.caption = 'list of all incoterms'%>
		<% @header_content = grid.build_grid_data %>

		<% @pagination = pagination_links(@incoterm_pages) if @incoterm_pages != nil %>
		<%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
end
 
def search_incoterms_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_incoterm_search_form
end

def render_incoterm_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  incoterms'"%> 

		<%= build_incoterm_search_form(nil,'submit_incoterms_search','submit_incoterms_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_incoterms_search
	@incoterms = dynamic_search(params[:incoterm] ,'incoterms','Incoterm')
	if @incoterms.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_incoterm_search_form
		else
			render_list_incoterms
	end
end

 
def delete_incoterm
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:incoterms_page] = params['page']
		render_list_incoterms
		return
	end
	id = params[:id]
	if id && incoterm = Incoterm.find(id)
    t_partner=TradingPartner.find_by_incoterm_id(id)
        if t_partner
          session[:alert] = 'record is referenced by a trading partner ,it cannot be deleted'
        else
          incoterm.destroy
          		session[:alert] = ' Record deleted.'
          end

		render_list_incoterms
	end
	rescue
		handle_error('record could not be deleted')
end
end
 
def new_incoterm
	return if authorise_for_web(program_name?,'create')== false
		render_new_incoterm
end
 
def create_incoterm
 begin
	 @incoterm = Incoterm.new(params[:incoterm])
	 if @incoterm.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_incoterm
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_incoterm
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new incoterm'"%> 

		<%= build_incoterm_form(@incoterm,'create_incoterm','create_incoterm',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_incoterm
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @incoterm = Incoterm.find(id)
		render_edit_incoterm

	 end
end


def render_edit_incoterm
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit incoterm'"%> 

		<%= build_incoterm_form(@incoterm,'update_incoterm','update_incoterm',true)%>

		}, :layout => 'content'
end
 
def update_incoterm
 begin

	 id = params[:incoterm][:id]
	 if id && @incoterm = Incoterm.find(id)
		 if @incoterm.update_attributes(params[:incoterm])
			@incoterms = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_incoterms
	 else
			 render_edit_incoterm

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
