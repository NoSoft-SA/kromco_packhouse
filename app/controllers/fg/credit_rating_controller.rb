class Fg::CreditRatingController < ApplicationController

  def program_name?
    "credit_rating"
  end

  def bypass_generic_security?
    true
  end

  def list_credit_ratings
    return if authorise_for_web(program_name?, 'read') == false

    if params[:page]!= nil

      session[:credit_ratings_page] = params['page']

      render_list_credit_ratings

      return
    else
      session[:credit_ratings_page] = nil
    end

    list_query = "@credit_rating_pages = Paginator.new self, CreditRating.count, @@page_size,@current_page
	 @credit_ratings = CreditRating.find(:all,
				 :limit => @credit_rating_pages.items_per_page,
				 :offset => @credit_rating_pages.current.offset)"
    session[:query] = list_query
    render_list_credit_ratings
  end


  def render_list_credit_ratings
    @pagination_server = "list_credit_ratings"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:credit_ratings_page]
    @current_page = params['page']||= session[:credit_ratings_page]
    @credit_ratings =  eval(session[:query]) if !@credit_ratings
    render :inline => %{
      <% grid            = build_credit_rating_grid(@credit_ratings,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all credit_ratings' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@credit_rating_pages) if @credit_rating_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_credit_ratings_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_credit_rating_search_form
  end

  def render_credit_rating_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  credit_ratings'"%> 

		<%= build_credit_rating_search_form(nil,'submit_credit_ratings_search','submit_credit_ratings_search',@is_flat_search)%>

		}, :layout => 'content'
  end


  def submit_credit_ratings_search
    @credit_ratings = dynamic_search(params[:credit_rating], 'credit_ratings', 'CreditRating')
    if @credit_ratings.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_credit_rating_search_form
    else
      render_list_credit_ratings
    end
  end


  def delete_credit_rating
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:credit_ratings_page] = params['page']
        render_list_credit_ratings
        return
      end
      id = params[:id]
      if id && credit_rating = CreditRating.find(id)
        credit_rating.destroy
        session[:alert] = " Record deleted."
        render_list_credit_ratings
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_credit_rating
    return if authorise_for_web(program_name?, 'create')== false
    render_new_credit_rating
  end

  def create_credit_rating
    begin
      @credit_rating = CreditRating.new(params[:credit_rating])
      if @credit_rating.save

        redirect_to_index("'new record created successfully'", "'create successful'")
      else
        @is_create_retry = true
        render_new_credit_rating
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_credit_rating
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new credit_rating'"%> 

		<%= build_credit_rating_form(@credit_rating,'create_credit_rating','create_credit_rating',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_credit_rating
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    if id && @credit_rating = CreditRating.find(id)
      render_edit_credit_rating

    end
  end


  def render_edit_credit_rating
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit credit_rating'"%> 

		<%= build_credit_rating_form(@credit_rating,'update_credit_rating','update_credit_rating',true)%>

		}, :layout => 'content'
  end

  def update_credit_rating
    begin

      id = params[:credit_rating][:id]
      if id && @credit_rating = CreditRating.find(id)
        if @credit_rating.update_attributes(params[:credit_rating])
          @credit_ratings = eval(session[:query])
          flash[:notice] = 'record saved'
          render_list_credit_ratings
        else
          render_edit_credit_rating

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end


end
