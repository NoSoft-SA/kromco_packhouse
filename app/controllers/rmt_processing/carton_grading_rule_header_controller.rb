class  RmtProcessing::CartonGradingRuleHeaderController < ApplicationController

def program_name?
  "grower_grading"
end

def bypass_generic_security?
  true
end

def list_carton_grading_rule_headers
  return if authorise_for_web(program_name?,'read') == false 
  store_last_grid_url

   if params[:page]!= nil 

     session[:carton_grading_rule_headers_page] = params['page']

     render_list_carton_grading_rule_headers

     return 
  else
    session[:carton_grading_rule_headers_page] = nil
  end

  list_query = "@carton_grading_rule_header_pages = Paginator.new self, CartonGradingRuleHeader.count, @@page_size,@current_page
   @carton_grading_rule_headers = CartonGradingRuleHeader.find(:all,
         :limit => @carton_grading_rule_header_pages.items_per_page,
         :offset => @carton_grading_rule_header_pages.current.offset)"
  session[:query] = list_query
  render_list_carton_grading_rule_headers
end


def render_list_carton_grading_rule_headers
  @pagination_server = "list_carton_grading_rule_headers"
  @can_edit = authorise(program_name?,'edit',session[:user_id])
  @can_delete = authorise(program_name?,'delete',session[:user_id])
  @current_page = session[:carton_grading_rule_headers_page]
  @current_page = params['page']||= session[:carton_grading_rule_headers_page]
  @carton_grading_rule_headers =  eval(session[:query]) if !@carton_grading_rule_headers
  render :inline => %{
    <% grid = build_carton_grading_rule_header_grid(@carton_grading_rule_headers,@can_edit,@can_delete)%>
    <% grid.caption = 'List of all carton_grading_rule_headers'%>
    <% @header_content = grid.build_grid_data %>

    <% @pagination = pagination_links(@carton_grading_rule_header_pages) if @carton_grading_rule_header_pages != nil %>
    <%= grid.render_html %>
    <%= grid.render_grid %>
  },:layout => 'content'
end

def search_carton_grading_rule_headers_flat
  return if authorise_for_web(program_name?,'read')== false
  @is_flat_search = true 
  render_carton_grading_rule_header_search_form
end

def render_carton_grading_rule_header_search_form(is_flat_search = nil)
  session[:is_flat_search] = @is_flat_search
#   render (inline) the search form
  render :inline => %{
    <% @content_header_caption = "'search  carton_grading_rule_headers'"%> 

    <%= build_carton_grading_rule_header_search_form(nil,'submit_carton_grading_rule_headers_search','submit_carton_grading_rule_headers_search',@is_flat_search)%>

    }, :layout => 'content'
end


def submit_carton_grading_rule_headers_search
  store_last_grid_url
  @carton_grading_rule_headers = dynamic_search(params[:carton_grading_rule_header] ,'carton_grading_rule_headers','CartonGradingRuleHeader')
  if @carton_grading_rule_headers.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_carton_grading_rule_header_search_form
    else
      render_list_carton_grading_rule_headers
  end
end


def delete_carton_grading_rule_header
  return if authorise_for_web(program_name?,'delete')== false
  if params[:page]
    session[:carton_grading_rule_headers_page] = params['page']
    render_list_carton_grading_rule_headers
    return
  end
  id = params[:id]
  if id && carton_grading_rule_header = CartonGradingRuleHeader.find(id)
    carton_grading_rule_header.destroy
    session[:alert] = ' Record deleted.'
    # render_list_carton_grading_rule_headers
    redirect_to_last_grid
  end
  rescue
    handle_error('record could not be deleted')
end

def new_carton_grading_rule_header
  return if authorise_for_web(program_name?,'create')== false
  # store_list_as_grid_url # UNCOMMENT if this action is called directly (i.e. from a menu, not from a grid)
  render_new_carton_grading_rule_header
end

def create_carton_grading_rule_header
   @carton_grading_rule_header = CartonGradingRuleHeader.new(params[:carton_grading_rule_header])
   if @carton_grading_rule_header.save
     # redirect_to_index("new record created successfully","'create successful'")
     flash[:notice] = 'new record created successfully'
     redirect_to_last_grid
  else
    @is_create_retry = true
    render_new_carton_grading_rule_header
   end
rescue
   handle_error('record could not be created')
end

def render_new_carton_grading_rule_header
#   render (inline) the edit template
  render :inline => %{
    <% @content_header_caption = "'create new carton_grading_rule_header'"%> 

    <%= build_carton_grading_rule_header_form(@carton_grading_rule_header,'create_carton_grading_rule_header','create_carton_grading_rule_header',false,@is_create_retry)%>

    }, :layout => 'content'
end

def edit_carton_grading_rule_header
  return if authorise_for_web(program_name?,'edit')==false 
   id = params[:id]
   if id && @carton_grading_rule_header = CartonGradingRuleHeader.find(id)
    render_edit_carton_grading_rule_header
   end
end


def render_edit_carton_grading_rule_header
#   render (inline) the edit template
  render :inline => %{
    <% @content_header_caption = "'edit carton_grading_rule_header'"%> 

    <%= build_carton_grading_rule_header_form(@carton_grading_rule_header,'update_carton_grading_rule_header','update_carton_grading_rule_header',true)%>

    }, :layout => 'content'
end

def update_carton_grading_rule_header
   id = params[:carton_grading_rule_header][:id]
   if id && @carton_grading_rule_header = CartonGradingRuleHeader.find(id)
     if @carton_grading_rule_header.update_attributes(params[:carton_grading_rule_header])
      # @carton_grading_rule_headers = eval(session[:query])
      flash[:notice] = 'record saved'
      # render_list_carton_grading_rule_headers
      redirect_to_last_grid
   else
       render_edit_carton_grading_rule_header
     end
   end
rescue
   handle_error('record could not be saved')
 end

  def search_dm_carton_grading_rule_headers
    return if authorise_for_web(program_name?,'read')== false
    dm_session['se_layout']              = 'content'
    @content_header_caption              = "'Search Carton grading rule headers'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form('search_carton_grading_rule_headers.yml', 'search_dm_carton_grading_rule_headers_grid')
  end


  def search_dm_carton_grading_rule_headers_grid
    store_last_grid_url
    @carton_grading_rule_headers = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    @can_edit        = authorise(program_name?, 'edit', session[:user_id])
    @can_delete      = authorise(program_name?, 'delete', session[:user_id])
    @stat            = dm_session[:search_engine_query_definition]
    @columns_list    = dm_session[:columns_list]
    @grid_configs    = dm_session[:grid_configs]

    render :inline => %{
      <% grid            = build_carton_grading_rule_header_dm_grid(@carton_grading_rule_headers, @stat, @columns_list, @can_edit, @can_delete, @grid_configs) %>
      <% grid.caption    = 'Carton grading rule headers' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end




end
