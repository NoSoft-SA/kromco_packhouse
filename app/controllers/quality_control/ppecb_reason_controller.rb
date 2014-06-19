class  QualityControl::PpecbReasonController < ApplicationController
 
def program_name?
	"ppecb_reason"
end

def bypass_generic_security?
	true
end
def list_ppecb_reasons
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:ppecb_reasons_page] = params['page']

		 render_list_ppecb_reasons

		 return 
	else
		session[:ppecb_reasons_page] = nil
	end

	list_query = "@ppecb_reason_pages = Paginator.new self, PpecbReason.count, @@page_size,@current_page
	 @ppecb_reasons = PpecbReason.find(:all,
				 :limit => @ppecb_reason_pages.items_per_page,
				 :offset => @ppecb_reason_pages.current.offset)"
	session[:query] = list_query
	render_list_ppecb_reasons
end


def render_list_ppecb_reasons
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:ppecb_reasons_page] if session[:ppecb_reasons_page]
	@current_page = params['page'] if params['page']
	@ppecb_reasons =  eval(session[:query]) if !@ppecb_reasons
	render :inline => %{
      <% grid            = build_ppecb_reason_grid(@ppecb_reasons,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all ppecb_reasons' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@ppecb_reason_pages) if @ppecb_reason_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_ppecb_reasons_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_ppecb_reason_search_form
end

def render_ppecb_reason_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  ppecb_reasons'"%> 

		<%= build_ppecb_reason_search_form(nil,'submit_ppecb_reasons_search','submit_ppecb_reasons_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_ppecb_reasons_search
	if params['page']
		session[:ppecb_reasons_page] =params['page']
	else
		session[:ppecb_reasons_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @ppecb_reasons = dynamic_search(params[:ppecb_reason] ,'ppecb_reasons','PpecbReason')
	else
		@ppecb_reasons = eval(session[:query])
	end
	if @ppecb_reasons.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_ppecb_reason_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_ppecb_reasons
		end

	else

		render_list_ppecb_reasons
	end
end

 
def delete_ppecb_reason
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:ppecb_reasons_page] = params['page']
		render_list_ppecb_reasons
		return
	end
	id = params[:id]
	if id && ppecb_reason = PpecbReason.find(id)
		ppecb_reason.destroy
		session[:alert] = " Record deleted."
		render_list_ppecb_reasons
	end
end
 
def new_ppecb_reason
	return if authorise_for_web(program_name?,'create')== false
		render_new_ppecb_reason
end
 
def create_ppecb_reason
	 @ppecb_reason = PpecbReason.new(params[:ppecb_reason])
	 if @ppecb_reason.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_ppecb_reason
	 end
end

def render_new_ppecb_reason
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new ppecb_reason'"%> 

		<%= build_ppecb_reason_form(@ppecb_reason,'create_ppecb_reason','create_ppecb_reason',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_ppecb_reason
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @ppecb_reason = PpecbReason.find(id)
		render_edit_ppecb_reason

	 end
end


def render_edit_ppecb_reason
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit ppecb_reason'"%> 

		<%= build_ppecb_reason_form(@ppecb_reason,'update_ppecb_reason','update_ppecb_reason',true)%>

		}, :layout => 'content'
end
 
def update_ppecb_reason
	if params[:page]
		session[:ppecb_reasons_page] = params['page']
		render_list_ppecb_reasons
		return
	end

		@current_page = session[:ppecb_reasons_page]
	 id = params[:ppecb_reason][:id]
	 if id && @ppecb_reason = PpecbReason.find(id)
		 if @ppecb_reason.update_attributes(params[:ppecb_reason])
			@ppecb_reasons = eval(session[:query])
			render_list_ppecb_reasons
	 else
			 render_edit_ppecb_reason

		 end
	 end
 end
 
 

end
