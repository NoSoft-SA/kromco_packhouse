class  Reports::PrinterController < ApplicationController
 
def program_name?
	"printer"
end

def bypass_generic_security?
	true
end
def list_printers
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:printers_page] = params['page']

		 render_list_printers

		 return 
	else
		session[:printers_page] = nil
	end

	list_query = "@printer_pages = Paginator.new self, Printer.count, @@page_size,@current_page
	 @printers = Printer.find(:all,
				 :limit => @printer_pages.items_per_page,
				 :offset => @printer_pages.current.offset)"
	session[:query] = list_query
	render_list_printers
end


def render_list_printers
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:printers_page] if session[:printers_page]
	@current_page = params['page'] if params['page']
	@printers =  eval(session[:query]) if !@printers

  render :inline => %{
    <% grid            = build_printer_grid(@printers,@can_edit,@can_delete)%>
    <% grid.caption    = 'list of all printers' %>
    <% @header_content = grid.build_grid_data %>

    <%= grid.render_html %>
    <%= grid.render_grid %>
    }, :layout => 'content'
end
 
def search_printers_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_printer_search_form
end

def render_printer_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  printers'"%> 

		<%= build_printer_search_form(nil,'submit_printers_search','submit_printers_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_printers_search
	if params['page']
		session[:printers_page] =params['page']
	else
		session[:printers_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @printers = dynamic_search(params[:printer] ,'printers','Printer')
	else
		@printers = eval(session[:query])
	end
	if @printers.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_printer_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_printers
		end

	else

		render_list_printers
	end
end

 
def delete_printer
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:printers_page] = params['page']
		render_list_printers
		return
	end
	id = params[:id]
	if id && printer = Printer.find(id)
		printer.destroy
		session[:alert] = " Record deleted."
		render_list_printers
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_printer
	return if authorise_for_web(program_name?,'create')== false
		render_new_printer
end
 
def create_printer
 begin
	 @printer = Printer.new(params[:printer])
	 if @printer.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_printer
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_printer
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new printer'"%> 

		<%= build_printer_form(@printer,'create_printer','create_printer',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_printer
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @printer = Printer.find(id)
		render_edit_printer

	 end
end


def render_edit_printer
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit printer'"%> 

		<%= build_printer_form(@printer,'update_printer','update_printer',true)%>

		}, :layout => 'content'
end
 
def update_printer
 begin

	if params[:page]
		session[:printers_page] = params['page']
		render_list_printers
		return
	end

		@current_page = session[:printers_page]
	 id = params[:printer][:id]
	 if id && @printer = Printer.find(id)
		 if @printer.update_attributes(params[:printer])
			@printers = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_printers
	 else
			 render_edit_printer

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 

end
