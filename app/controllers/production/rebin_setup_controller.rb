class  Production::RebinSetupController < ApplicationController
 
 #fix: paging fixed
 
def program_name?
	"rebin_setup"
end

def bypass_generic_security?
	true
end

def view_paging_handler

  if params[:page]
	session[:rebin_setups_page] = params['page']
  end
  render_list_rebin_setups
  
end

def delete_rebin_setup
 return if authorise_for_web('rebin_setup','rebin_setup')== false
	id = params[:id]
	if id && rebin_setup = RebinSetup.find(id)
	 begin
	   
		  rebin_setup.destroy
		  
		  session[:alert] = " Record deleted."
         
		
		render_list_rebin_setups
	  rescue
	   handle_error("Rebin setup cannot be deleted")
	  end
	end

end


def view_rebin_setup
     id = params[:id]
     @schedule = session[:current_prod_schedule].production_schedule_name
	 if id && @rebin_setup = RebinSetup.find(id)
        render :inline => %{
		<% @content_header_caption = "'view rebin_setup for schedule: " + @schedule + "'" %> 

		<%= build_rebin_setup_view(@rebin_setup)%>

		}, :layout => 'content'
    end
end

def split_counts

 if params[:page]
	session[:rebin_setups_page] = params['page']
	render_list_rebin_setups
	return
  end
  
 begin
  id = params[:id]
  session[:active_rebin]= id
  rebin_setup = RebinSetup.find(id)
  @min_count_value = rebin_setup.standard_size_count_from
  @max_count_value = rebin_setup.standard_size_count_to
  
  if rebin_setup.standard_size_count_from == -1
   rebin_setup.clone_setup
   flash[:notice] = "record cloned"
   render_list_rebin_setups
  else
   render :template => "production/split_counts",:layout => "content"
  end
 rescue
  handle_error("split or clone operation failed")
 end
end

def  save_size_counts
  
  if params[:page]
	session[:rebin_setups_page] = params['page']
	render_list_rebin_setups
	return
  end
  
  ranges = nil
  #the hidden field: 'txtranges' holds ruby code that defines an array of arrays
  #the outer array holds the size counts
  #the inner arrays holds the from and to range values (positions 0 and 1 respectively)
  #we need to 1) edit the original value with the range values of the first item and
  #2) create a new rebin setup record for each new range- in doing this we must copy
  #   all the values from rebin setup(original record) to the new records
  ranges = nil
  eval params[:size_counts][:size_counts_txtranges]
  rebin_setup = RebinSetup.find(session[:active_rebin])
  rebin_setup.split_size_counts(ranges)
  flash[:notice] = "split performed successfully"
  render_list_rebin_setups
  

end




def save_label_sequence
  # sequnce are stored as an an array (in ruby code) in the hidden field
  if params[:page]
	session[:rebin_setups_page] = params['page']
	render_list_rebin_setups
	return
  end
  
  sequence = nil
  if params[:label_sequence][:label_sequences_hidden_field] == ""
    flash[:notice] = "You have not set or changed anything"
    render_list_rebin_setups
    return
  end
  eval "sequence = " + (params[:label_sequence][:label_sequences_hidden_field])
  session[:label].set_fields_sequence(sequence)
  session[:label]== nil
  flash[:notice] = "Sequence was set successfully"
  render_list_rebin_setups
  #set_fields_sequence

end


def set_label_seq

  if params[:page]
	session[:rebin_setups_page] = params['page']
	render_list_rebin_setups
	return
  end
	
  @schedule = session[:current_prod_schedule].production_schedule_name
  id = params[:id]
  
  label_setup = RebinSetup.find(id).rebin_label_setup
   if !label_setup
  
    flash[:notice] = "Label setup not yet defined for this rebin setup"
    render_list_rebin_setups
    return
  end
  
  @label = label_setup.label
  session[:label] = @label
  if @label.label_fields == nil||@label.label_fields.length == 0
  
    flash[:notice] = "No label fields are defined in database for this label(" + @label.label_code + ")"
    render_list_rebin_setups
    return
  end
   render :inline => %{
		<% @content_header_caption = "'set fields sequence for label: " + @label.label_code + "(schedule: " + @schedule + ")'" %> 

		<%= build_label_seq_form(@label)%>

}, :layout => 'content'


end

def list_rebin_setups
	return if authorise_for_web('rebin_setup','read') == false 

 	if params[:page]!= nil 

 		session[:rebin_setups_page] = params['page']

		 render_list_rebin_setups

		 return 
	else
		session[:rebin_setups_page] = nil
	end
	
	is_view = nil
    if session[:current_prod_schedule]== nil
      msg = "You must first select or set a 'current' production schedule from the 'production schedules' tab"
      @freeze_flash = true
      redirect_to_index(msg)
      return
    end
    
    
    @current_prod_schedule = session[:current_prod_schedule].production_schedule_name 
    
    #----------------------------------------------------------------------------------
    #Rebin setup records are automatically created when processing setup records with a 
    #product_handling_type_code of 'rebin' are created: rebins and procc setups of 'rebin'
    #type is always 1:1
    #----------------------------------------------------------------------------------
	list_query = "@rebin_setup_pages = Paginator.new self, RebinSetup.count(\"production_schedule_code = '#{session[:current_prod_schedule].production_schedule_name}'\"), @@page_size,@current_page
	 @rebin_setups = RebinSetup.find_all_by_production_schedule_code(session[:current_prod_schedule].production_schedule_name,
				 :limit => @rebin_setup_pages.items_per_page,
				 :order => 'standard_size_count_from,standard_size_count_to,id',
				 :offset => @rebin_setup_pages.current.offset)"
	session[:query] = list_query
	render_list_rebin_setups
end


def render_list_rebin_setups

	session[:current_prod_schedule].reload
    @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed"||session[:current_prod_schedule].production_schedule_status_code == "completed")
    if !@is_view
      
      @is_view = !authorise(program_name?,'rebin_setup',session[:user_id])
    end
	
	@current_prod_schedule = session[:current_prod_schedule].production_schedule_name 
	
	@current_page = session[:rebin_setups_page] if session[:rebin_setups_page]
	@current_page = params['page'] if params['page']
	@rebin_setups =  eval(session[:query]) if !@rebin_setups
    render :inline => %{
      <% grid            = build_rebin_setup_grid(@rebin_setups) %>
      <% grid.caption    = 'list of rebin_setups for schedule: #{@current_prod_schedule}' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@rebin_setup_pages) if @rebin_setup_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 

def render_rebin_setup_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  rebin_setups'"%> 

		<%= build_rebin_setup_search_form(nil,'submit_rebin_setups_search','submit_rebin_setups_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def edit_rebin_setup
	return if authorise_for_web('rebin_setup','rebin_setup')==false 
	 id = params[:id]
	 if id && @rebin_setup = RebinSetup.find(id)
		render_edit_rebin_setup

	 end
end


def render_edit_rebin_setup
#	 render (inline) the edit template
  begin
    @schedule = session[:current_prod_schedule].production_schedule_name
	render :inline => %{
		<% @content_header_caption = "'edit rebin_setup for schedule: " + @schedule + "'" %>  

		<%= build_rebin_setup_form(@rebin_setup,'update_rebin_setup','update_rebin_setup',true)%>

		}, :layout => 'content'
  rescue
    handle_error("rebin setup form could not be rendered")
  end
end
 
def update_rebin_setup
  begin
	if params[:page]
		session[:rebin_setups_page] = params['page']
		render_list_rebin_setups
		return
	end

		@current_page = session[:rebin_setups_page]
	 id = params[:rebin_setup][:id]
	 if id && @rebin_setup = RebinSetup.find(id)
		 if @rebin_setup.update_attributes(params[:rebin_setup])
			@rebin_setups = eval(session[:query])
			render_list_rebin_setups
	 else
			 render_edit_rebin_setup

		 end
	 end
  rescue
    handle_error("rebin setup could not be saved")
  end
 end
 
 def label_code_combo_changed
	label_code = get_selected_combo_value(params)
	@printer_formats = PrinterFormat.formats_for_label(label_code).map{|l|l.printer_format_code}
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rebin_setup','printer_format',@printer_formats)%>

		}

end
 


end
