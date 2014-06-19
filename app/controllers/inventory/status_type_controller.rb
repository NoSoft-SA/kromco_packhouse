class  Inventory::StatusTypeController < ApplicationController
 
def program_name?
	"status_type"
end

def bypass_generic_security?
	true
end
def list_status_types
	return if authorise_for_web(program_name?,'read') == false

	if params[:page]!= nil

		session[:status_types_page] = params['page']

		 render_list_status_types

		 return
	else
		session[:status_types_page] = nil
	end

	list_query = "@status_type_pages = Paginator.new self, StatusType.count, @@page_size,@current_page
	 @status_types = StatusType.find(:all,
				 :limit => @status_type_pages.items_per_page,
				 :offset => @status_type_pages.current.offset)"
	session[:query] = list_query
	render_list_status_types
end


def render_list_status_types
	@pagination_server = "list_status_types"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:status_types_page]
	@current_page = params['page']||= session[:status_types_page]
	@status_types =  eval(session[:query]) if !@status_types
	render :inline => %{
      <% grid            = build_status_type_grid(@status_types,@can_delete) %>
      <% grid.caption    = 'list of all status_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@status_type_pages) if @status_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_status_types_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_status_type_search_form
end

def render_status_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  status_types'"%> 

		<%= build_status_type_search_form(nil,'submit_status_types_search','submit_status_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_status_types_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_status_type_search_form(true)
end

 
def submit_status_types_search
	@status_types = dynamic_search(params[:status_type] ,'status_types','StatusType')
	if @status_types.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_status_type_search_form
		else
			render_list_status_types
	end
end


 
def new_status_type
	return if authorise_for_web(program_name?,'create')== false
		render_new_status_type
end
 
def create_status_type
 begin
	 @status_type = StatusType.new(params[:status_type])
	 if @status_type.save
     @status_type_code = @status_type['status_type_code']
     session[:status_type_code] = @status_type_code

      render :inline => %{
			  <script>
           alert('status type successfully saved');
           window.opener.frames[1].location.reload(true);
           window.close();
        </script>
   }
   else
     	@is_create_retry = true
		render_new_status_type
	 end
rescue
	 handle_error('record could not be created')
 end
end

def render_new_status_type
	render :inline => %{
		<% @content_header_caption = "'create new status_type'"%> 
		<%= build_status_type_form(@status_type,'create_status_type','create_status_type',false,@is_create_retry)%>
		}, :layout => 'content'
end
 
def edit_status_type
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @status_type = StatusType.find(id)
		render_edit_status_type

	 end
end


def render_edit_status_type
	render :inline => %{
		<% @content_header_caption = "'edit status_type'"%> 
		<%= build_status_type_form(@status_type,'update_status_type','update_status_type',true)%>
		}, :layout => 'content'
end
 
def update_status_type
 begin

	 id = params[:status_type][:id]
	 if id && @status_type = StatusType.find(id)
		 if @status_type.update_attributes(params[:status_type])
			@status_types = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_status_types
	 else
			 render_edit_status_type

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
end

def delete_status_type
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:status_types_page] = params['page']
		render_list_status_types
		return
	end
	id = params[:id].to_i
	if id && status_type = StatusType.find(id)
    transaction_status = TransactionStatus.find_by_sql("select * from transaction_statuses where transaction_statuses.status_type_code = '#{status_type.status_type_code}' ")
    if !transaction_status.empty?
      flash[:notice] =  "Cannot delete status_type_code" +  " :'#{status_type.status_type_code}' " + " record exists in status histories "
      render_list_status_types
    else

    status_type.destroy
		  render :inline => %{
			  <script>
           alert('Record deleted.');
           window.opener.frames[1].location.reload(true);
           window.close();
        </script>
   }
    end
    end

   rescue
    handle_error('record could not be deleted')
  end

end

def list_statuses
  return if authorise_for_web(program_name?,'read') == false
  id = params[:id]
  status_type = StatusType.find(id)
  status_type_code = status_type.status_type_code
  session[:status_type_code] = status_type_code
  @statuses = Status.find_by_sql("select * from  statuses where status_type_code = '#{status_type_code}'")
  render_list_statuses

end
def render_list_statuses
	@pagination_server = "list_statuses"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:statuses_page]
	@current_page = params['page']||= session[:statuses_page]
	@statuses =  eval(session[:query]) if !@statuses
	render :inline => %{
      <% grid            = build_status_grid(@statuses,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all statuses' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@status_pages) if @status_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end


def new_status
	return if authorise_for_web(program_name?,'create')== false
		render_new_status
end

def render_new_status
	render :inline => %{
		<% @content_header_caption = "'create new status'"%>
   	<%= build_status_form(@status,'create_status','create_status',false,@is_create_retry)%>

		}, :layout => 'content'
end

 def create_status
   begin
    status_type_code = session[:status_type_code]
    preceded_by = params[:status][:preceded_by]
    @preceded_by_split = preceded_by.split
    session[:preceded_by] = @preceded_by_split
    preceded_by_join = @preceded_by_split.join(",")
    params[:status][:preceded_by] =  preceded_by_join

    @status = Status.new(params[:status])
    @status.status_type_code = status_type_code

      if @status.save
       render :inline => %{
			  <script>
           alert('status successfully saved');
           window.opener.location.reload(true);
           window.close();
      </script>
   }

    else
     	@is_create_retry = true
      render_new_status
    end
#    end
rescue
	 handle_error('record could not be created')
  end
 end

def edit_status
	return if authorise_for_web(program_name?,'edit')==false

	 id = params[:id]
	 if id && @status = Status.find(id)

    preceded_by = @status.preceded_by
    preceded_by_new_line = preceded_by.gsub(",","\n")
    @status.preceded_by =  preceded_by_new_line


     status_code = @status.status_code
     status_type_code = @status.status_type_code
     transaction_status = TransactionStatus.find_by_sql("select * from transaction_statuses where transaction_statuses.status_code ='#{status_code}'
                                                  and transaction_statuses.status_type_code = '#{status_type_code}' ")

#     if !transaction_status.empty?
#    render :inline => %{
#			  <script>
#           alert('Cannot edit status record a status record exists in status histories ');
#           window.close();
#        </script>
#        }
#     else
 		render_edit_status
#     end
	 end
end

def render_edit_status
	render :inline => %{
		<% @content_header_caption = "'edit status'"%>
		<%= build_status_form(@status,'update_status','update_status',true)%>
		}, :layout => 'content'
end

def validate_preceded_by_values
   statuses = Status.find_all_by_status_type_code(session[:status_type_code]).map{|s| s.status_code}
   preceded_by =params[:status][:preceded_by]
   preceded_by = preceded_by.strip.gsub("\n",",")
    preceded_by_splits = preceded_by.split(",")
   for preceded_by_split in preceded_by_splits
       if !statuses.include?(preceded_by_split)
     flash[:notice] = "Invalid status code"
     end
   end
end




def update_status
 begin
	 id = params[:status][:id]
	 if id && @status = Status.find(id)
    preceded_by = params[:status][:preceded_by]     #taking actual value from text_field
    preceded_by = preceded_by.gsub(" ","")
    preceded_by = preceded_by.gsub("\n",",")
    preceded_by_splits = preceded_by.split(",")
    preceded_by_joined =  preceded_by_splits.join(",")
    params[:status][:preceded_by] =  preceded_by_joined
		 if @status.update_attributes(params[:status])
			@statuses = eval(session[:query])
      render :inline => %{
			  <script>
           alert('status successfully updated ');
           window.opener.location.reload(true);
           window.close();
      </script>
   }
	 else
			 render_edit_status
		 end
	 end
rescue
	 handle_error('record could not be saved')
end
end

def status_history_popup
    id = params[:id]
    status_type = StatusType.find(id)
    session[:status_history_status_type_code]  = status_type.status_type_code

    render :inline => %{

    <% @content_header_caption = "'Enter Object Id'"%>
    <%= build_status_history_search_form(@status_history,'submit_status_search','submit_status_search',true)%>
    }, :layout => 'content'

  end

  def status_history_submit
    status_history_object_id = params[:status_history][:object_id]
    session[:object_id] = status_history_object_id
    render_show_status_history()
  end

  def render_show_status_history
    show_status_history()
  end

  def show_status_history
     status_type_code = session[:status_history_status_type_code]
     object_id =   session[:object_id]
     @transaction_statuses = TransactionStatus.find_by_sql("select * from transaction_statuses where transaction_statuses.object_id = '#{object_id}' and transaction_statuses.status_type_code = '#{status_type_code}' order by transaction_statuses.id desc ")
     render_list_status_history
  end

  def render_list_status_history
	@pagination_server = "list_transaction_statuses"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:transaction_statuses_page]
	@current_page = params['page']||= session[:transaction_statuses_page]
	@transaction_statuses =  eval(session[:query]) if !@transaction_statuses
	render :inline => %{
      <% grid            = build_transaction_statuses(@transaction_statuses,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all transaction_statuses' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@transaction_status_pages) if @transaction_status_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def delete_status
    status_id = params[:id].to_i
    status = Status.find_by_sql("select * from statuses where statuses.id = ' #{status_id}' order by id desc")[0]
    status.destroy
    render :inline => %{
                  <script>
                      alert('status successfully  deleted');
                      window.opener.location.href = '/inventory/status_type/list_of_statuses ';
                      window.close();
                  </script>
                  }, :layout => 'content'
  end

  def list_of_statuses
    	return if authorise_for_web(program_name?,'read') == false
      @statuses = Status.find_by_sql("select * from statuses where  statuses.status_type_code = '#{session[:status_type_code]}' order by statuses.id")
      render_list_statuses
  end

  def render_list_statuses
	@pagination_server = "list_statuses"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:statuses_page]
	@current_page = params['page']||= session[:statuses_page]
	@statuses =  eval(session[:query]) if !@statuses
	render :inline => %{
      <% grid            = build_status_grid(@statuses,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all statuses' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@status_pages) if @status_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end




end
