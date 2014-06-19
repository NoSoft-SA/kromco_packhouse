class  Production::ProcessingSetupController < ApplicationController
 
 #fix: paging fixed
 
def program_name?
	"processing_setup"
end

def bypass_generic_security?
	true
end

#-------------------------------------------------------------------------------------
#Pallet criteria code
#-------------------------------------------------------------------------------------
def get_existing_pallet_criteria_setup
   return if session[:current_prod_schedule]== nil
    sched_nr = session[:current_prod_schedule].id
  
    return PalletCriterium.find_by_production_schedule_id(sched_nr)

end

def pallet_criteria_setup
 return if authorise_for_web(program_name?,'read') == false 
  msg = nil
  @pallet_criteria_setup = get_existing_pallet_criteria_setup
  if session[:current_prod_schedule]== nil
    msg = "You must first select or set a 'current' production schedule from the 'production schedules' tab"
  end
  
  if msg != nil
    @freeze_flash = true
    redirect_to_index(msg)
    return
  end
  
  session[:current_prod_schedule].reload 
  @is_view = ! authorise(program_name?,'rmt_procc_setup',session[:user_id])
  
  if !@is_view
     @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed")
  end
  
  
  if @pallet_criteria_setup != nil
    render_edit_pallet_criteria
  elsif !@is_view
    render_new_pallet_criteria
  else
    @freeze_flash = true
    redirect_to_index("pallet setup criteria has not yet been defined for schedule: " + session[:current_prod_schedule].production_schedule_name + ", even though the schedule has been closed" )
    return
  end
end
 
 def set_output_tracking_indicator
 
 @rmt_setup = session[:current_prod_schedule].rmt_setup
  render :inline => %{
		<% @content_header_caption = "'update output tracking indicator'"%> 

		<%= build_output_tracking_indicator_form(@rmt_setup)%>

		}, :layout => 'content'
 
 
 end
 
 def update_output_tracking_indicator
  begin
    
    output_track_indicator = params[:rmt_setup][:output_track_indicator_code]
    rmt_setup = session[:current_prod_schedule].rmt_setup
    rmt_setup.output_track_indicator_code = output_track_indicator
   
    if rmt_setup.save
     redirect_to_index("output track indicator updated")
     return
    else
      raise rmt_setup.errors.full_messages.to_s
    end
  rescue
    handle_error("output track indicator could not be updated")
    return
  end
 
 end
 
 
def create_pallet_criteria
	 @pallet_criterium = PalletCriterium.new(params[:pallet_criteria_setup])
	 @pallet_criterium.production_schedule = session[:current_prod_schedule]
	 
	 if @pallet_criterium.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_pallet_criterium
	 end
end

def render_new_pallet_criteria
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'initial pallet criteria setup for schedule: " + session[:current_prod_schedule].production_schedule_name + "'"%> 

		<%= build_pallet_criterium_form(@pallet_criteria_setup,'create_pallet_criteria','create_pallet_criterium',false,@is_create_retry,@is_view)%>

		}, :layout => 'content'
end
 
def render_edit_pallet_criteria
#	 render (inline) the edit template
    @caption_action = " view"
    @caption_action = "edit " if !@is_view
    
	render :inline => %{
		<% @content_header_caption = "'" + @caption_action + " pallet setup criteria  for schedule: " + session[:current_prod_schedule].production_schedule_name + "'"%> 

		<%= build_pallet_criterium_form(@pallet_criteria_setup,'update_pallet_criteria','update_pallet_criterium',true,false,@is_view)%>

		}, :layout => 'content'
end
 
def update_pallet_criteria
	if params[:page]
		session[:pallet_criteria_page] = params['page']
		render_list_pallet_criteria
		return
	end

	@current_page = session[:pallet_criteria_page]
	 id = params[:pallet_criteria_setup][:id]
	 if id && @pallet_criterium = PalletCriterium.find(id)
		 if @pallet_criterium.update_attributes(params[:pallet_criteria_setup])
			 redirect_to_index("pallet criteria updated successfully")

		 end
	 end
 end



#------------------------------------------------------------------
#Rmt processing controller setup
#------------------------------------------------------------------

def view_paging_handler

  if params[:page]
	session[:processing_setups_page] = params['page']
  end
  render_list_processing_setups
  
end


def view_processing_setup
     id = params[:id]
     @schedule = session[:current_prod_schedule].production_schedule_name
	 if id && @processing_setup = ProcessingSetup.find(id)
        render :inline => %{
		<% @content_header_caption = "'view processing_setup for schedule: " + @schedule + "'" %> 

		<%= build_processing_setup_view(@processing_setup)%>

		}, :layout => 'content'
    end
end

def list_processing_setups
	return if authorise_for_web('processing_setup','read') == false 

 	if params[:page]!= nil 

 		session[:processing_setups_page] = params['page']

		 render_list_processing_setups

		 return 
	else
		session[:processing_setups_page] = nil
	end
    
    is_view = nil
    if session[:current_prod_schedule]== nil
      msg = "You must first select or set a 'current' production schedule from the 'production schedules' tab"
      @freeze_flash = true
      redirect_to_index(msg)
      return
    end
   
    
    @current_prod_schedule = session[:current_prod_schedule].production_schedule_name 
    
	list_query = "@processing_setup_pages = Paginator.new self, ProcessingSetup.count(\"production_schedule_code = '#{session[:current_prod_schedule].production_schedule_name}'\"), @@page_size,@current_page
	 @processing_setups = ProcessingSetup.find_all_by_production_schedule_code(session[:current_prod_schedule].production_schedule_name,
				 :limit => @processing_setup_pages.items_per_page,
				 :order => 'id',
				 :offset => @processing_setup_pages.current.offset)"
	session[:query] = list_query
	render_list_processing_setups
end


def render_list_processing_setups
	
	 session[:current_prod_schedule].reload
    @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed"||session[:current_prod_schedule].production_schedule_status_code == "completed")
    if !@is_view
      
      @is_view = !authorise(program_name?,'rmt_procc_setup',session[:user_id])
    end
	
	@current_prod_schedule = session[:current_prod_schedule].production_schedule_name 
	@current_page = session[:processing_setups_page] if session[:processing_setups_page]
	@current_page = params['page'] if params['page']
	@processing_setups =  eval(session[:query]) if !@processing_setups
    render :inline => %{
      <% grid            = build_processing_setup_grid(@processing_setups) %>
      <% grid.caption    = 'list of processing setups for schedule: #{@current_prod_schedule}' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@processing_setup_pages) if @processing_setup_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_processing_setups_flat
	return if authorise_for_web('processing_setup','read')== false
	@is_flat_search = true 
	render_processing_setup_search_form
end

def render_processing_setup_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  processing_setups'"%> 

		<%= build_processing_setup_search_form(nil,'submit_processing_setups_search','submit_processing_setups_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_processing_setups_search
	if params['page']
		session[:processing_setups_page] =params['page']
	else
		session[:processing_setups_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @processing_setups = dynamic_search(params[:processing_setup] ,'processing_setups','ProcessingSetup')
	else
		@processing_setups = eval(session[:query])
	end
	if @processing_setups.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_processing_setup_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_processing_setups
		end

	else

		render_list_processing_setups
	end
end

def render_delete_confirmation_pack
  render :inline => %{
   <script>
     if (confirm("Deleting this record will result in deletion of all carton_setups with size count values that fall in the size count range of this record.\\n Are you sure you want to perform this (cascading) delete operation? ") == true)
        {window.location.href = "/production/processing_setup/delete_confirmed";}
     else
       {window.location.href = "/production/processing_setup/list_processing_setups";}
  </script>
  }
  
end

def render_delete_confirmation_rebin
  render :inline => %{
   <script>
     if (confirm("You have already created rebin records with sub-size count ranges. \\n They will also be deleted (also their associated rebin label setups).\\n Are you sure you want to perform this (cascading) delete operation? ") == true)
        {window.location.href = "/production/processing_setup/delete_confirmed";}
     else
       {window.location.href = "/production/processing_setup/list_processing_setups";}
  </script>
  }
  
end

def delete_confirmed
   
  @del_confirmed = true
  delete_processing_setup
  
end


def delete_processing_setup
	return if authorise_for_web('processing_setup','rmt_procc_setup')== false
	begin
	if params[:page]
		session[:processing_setups_page] = params['page']
		render_list_processing_setups
		return
	end
	id = nil
	if session[:procc_setup_id]!= nil
	 id = session[:procc_setup_id]
	 session[:procc_setup_id]= nil
	else
	 id = params[:id]
	end
	
	if id && processing_setup = ProcessingSetup.find(id)
	    if ! @del_confirmed
	     if processing_setup.handling_product.handling_product_type_code.upcase == "REBIN"
	       if RebinSetup.siblings_created_for_processing_setup?(processing_setup,session[:current_prod_schedule].id)
	         session[:procc_setup_id]= id
	         render_delete_confirmation_rebin
	         return
	       end
	     else
	       session[:procc_setup_id]= id
	       render_delete_confirmation_pack
	       return
	     end
	    elsif @del_confirmed == false
	     return
	    end
		processing_setup.destroy
		session[:alert] = " Record deleted."
		render_list_processing_setups
		return
	end
	rescue
	  handle_error("Processing setup record could not be deleted")
	end
end
 
def new_processing_setup
	return if authorise_for_web('processing_setup','rmt_procc_setup')== false
	

   is_view = nil
   if session[:current_prod_schedule]== nil
    msg = "You must first select or set a 'current' production schedule from the 'production schedules' tab"
    @freeze_flash = true
    redirect_to_index(msg)
    return
   else
    session[:current_prod_schedule].reload
    is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed"||session[:current_prod_schedule].production_schedule_status_code == "completed")
    if is_view
       @freeze_flash = true
       redirect_to_index("The schedule has been closed.")
      return
    end
   end	
   
   if !session[:current_prod_schedule].rmt_setup.track_indicator_code
	  redirect_to_index("You must first define a track indicator at rmt_setup")
	  return
	end
   
   #make sure a rmt product has been created
   if !RmtSetup.find_by_production_schedule_id(session[:current_prod_schedule].id)
    @freeze_flash = true
     redirect_to_index("A raw material setup has not been created for the current schedule
                       <BR> You must first create a raw material setup.")
      return
   end
			
  render_new_processing_setup
  
end

#def check_for_all_option(form,record)
# if form[:standard_size_count_from]== "all"
#  record.standard_size_count_from = -1
#  form[:standard_size_count_from] = -1
# end
# if form[:standard_size_count_to]== "all"
#  record.standard_size_count_to = -1
#  form[:standard_size_count_to] = -1
# end
#end


def create_processing_setup_step1
 #begin
  @processing_setup = ProcessingSetup.new(params[:processing_setup])
  #check_for_all_option(params[:processing_setup],@processing_setup)
  
  @processing_setup.production_schedule =  session[:current_prod_schedule]
  if @processing_setup.valid? == false
     @is_create_retry = true
     
	 render_new_processing_setup
	 return
  end
  
  
  @org = nil
  
  
  if @processing_setup.handling_product.handling_product_type_code == "REBIN"
    create_processing_setup_step3
  else
    session[:procc_setup_form_vals]= params[:processing_setup]
    @orgs = TradeEnvironmentSetup.find_all_by_production_schedule_id(session[:current_prod_schedule].id).map{|org|org.trade_env_code}
    if @orgs.length == 0 
      @freeze_flash = true
      redirect_to_index("You must first create a trade environment record- to define a marketing org- before you can continue")
    else
     render :inline => %{
		<% @content_header_caption = "'select org for carton setup'"%> 

		<%= build_select_org_form(@orgs,'create_processing_setup_step2','next')%>

		}, :layout => 'content'
   end
  end
 #rescue
  # handle_error("processing setup record could not be created")
 #end
end

def create_processing_setup_step2
  @trade_env_code = params[:marketing_orgs][:trade_env_code]
  @commodity = session[:current_prod_schedule].rmt_setup.commodity_code
  params[:processing_setup] = session[:procc_setup_form_vals]
  session[:procc_setup_form_vals] = nil
  create_processing_setup_step3

end


def create_processing_setup_step3
   begin
	 @processing_setup = ProcessingSetup.new(params[:processing_setup])
	 
	 if @trade_env_code
	   @processing_setup.commodity_code = @commodity
	   @processing_setup.trade_env_code = @trade_env_code
	 end
	 @processing_setup.production_schedule =  session[:current_prod_schedule]
	 @processing_setup.production_schedule_code = session[:current_prod_schedule].production_schedule_name
	 
	 if @processing_setup.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_processing_setup
	 end
  rescue
    handle_error("processing setup could not be created")
   end
end

def render_new_processing_setup
#	 render (inline) the edit template
	@current_prod_schedule = session[:current_prod_schedule].production_schedule_name 
	#@commodity_code member var is needed by the helper to obtain a list of standard size count values
	#for the commodity defined in rmt_setup for this schedule
	@commodity_code = session[:current_prod_schedule].rmt_setup.commodity_code
	render :inline => %{
		<% @content_header_caption = "'create new processing setup for schedule: " + @current_prod_schedule + "'"%> 

		<%= build_processing_setup_form(@processing_setup,'create_processing_setup_step1','create_processing_setup',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_processing_setup
	return if authorise_for_web('processing_setup','rmt_procc_setup')==false 
	 id = params[:id]
	 if id && @processing_setup = ProcessingSetup.find(id)
	  #determine if any rebin setup siblings have been created and, if so, disallow edit
	    
	    
		if @processing_setup.handling_product_type_code == "REBIN" 
		 #if RebinSetup.siblings_created_for_processing_setup?(@processing_setup,session[:current_prod_schedule].id)== false
		    render_edit_processing_setup
		#  else
#		  @freeze_flash = true
#		  flash[:notice] = "You have already used the 'split_counts' feature to create <br>
#		                   sub size-count ranges for rebin records associated with this processing setup record <br>
#		                   Editing is not allowed in this context "
#		  view_processing_setup
#		 end
		else
		  render_edit_processing_setup
		end                  
  
	 end
end


def render_edit_processing_setup
#	 render (inline) the edit template
 begin
  @schedule = session[:current_prod_schedule].production_schedule_name
  @commodity_code = session[:current_prod_schedule].rmt_setup.commodity_code
  @handling_caption = "<font color = blue>Handling_type is: <strong>rebin</strong></font>"
  
  if @processing_setup.handling_product_type_code.upcase == "PACK"
    @handling_caption = "<font color = green>Handling_type is: <strong>pack</strong></font>"
  end
  
	render :inline => %{
		<% @content_header_caption = "'edit rmt processing_setup for schedule: " + @schedule + ". " + @handling_caption +  "'" %>  

		<%= build_processing_setup_form(@processing_setup,'update_processing_setup','update_processing_setup',true)%>

		}, :layout => 'content'
  rescue
   handle_error("edit form coulld not be rendered")
  end
end
 
def update_processing_setup
  begin
	if params[:page]
		session[:processing_setups_page] = params['page']
		render_list_processing_setups
		return
	end

		@current_page = session[:processing_setups_page]
	 id = params[:processing_setup][:id]
	 if id && @processing_setup = ProcessingSetup.find(id)
	     #check_for_all_option(params[:processing_setup],@processing_setup)
		 if @processing_setup.update_attributes(params[:processing_setup])
		   flash[:notice] =  "processing setup updated"
			@processing_setups = eval(session[:query])
			render_list_processing_setups
	     else
	         
			 render_edit_processing_setup

		 end
	 end
  rescue
    handle_error("processing setup could not be saved")
  end
 end
 
 #	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: pack_material_product_id
#	---------------------------------------------------------------------------------
def processing_setup_pack_material_type_code_changed
	pack_material_type_code = get_selected_combo_value(params)
	session[:processing_setup_form][:pack_material_type_code_combo_selection] = pack_material_type_code
	@pack_material_sub_type_codes = ProcessingSetup.pack_material_sub_type_codes_for_pack_material_type_code(pack_material_type_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('processing_setup','pack_material_sub_type_code',@pack_material_sub_type_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_processing_setup_pack_material_sub_type_code'/>
		<%= observe_field('processing_setup_pack_material_sub_type_code',:update => 'pack_material_product_code_cell',:url => {:action => session[:processing_setup_form][:pack_material_sub_type_code_observer][:remote_method]},:loading => "show_element('img_processing_setup_pack_material_sub_type_code');",:complete => session[:processing_setup_form][:pack_material_sub_type_code_observer][:on_completed_js])%>
		}

end

 def handling_code_changed
  
  handling_code = get_selected_combo_value(params)
  @type_code = HandlingProduct.find_by_handling_product_code(handling_code).handling_product_type_code
  treatment_type = "PRE_HARVEST"
  treatment_type = "PACKHOUSE" if @type_code.upcase == "PACK"
  puts @type_code
  @treatment_codes = Treatment.find_by_sql("select distinct treatment_code from treatments where treatment_type_code = '#{treatment_type}'").map{|g|[g.treatment_code]}
  @processing_setup = nil
  if @type_code.upcase == "REBIN"
   @processing_setup = ProcessingSetup.new
   @processing_setup.treatment_code = session[:current_prod_schedule].rmt_setup.treatment_code
   @pack_material_product_codes = ProcessingSetup.pack_material_product_codes_for_pack_material_type_code("RMU")
  else
   @pack_material_product_codes = ProcessingSetup.pack_material_product_codes_for_pack_material_sub_type_code_and_pack_material_type_code("FRUIT","LB")
  end
   
        
  render :inline => %{
    
    <% treatment_content = select('processing_setup','treatment_code',@treatment_codes) %>
    <% pm_content = select('processing_setup','pack_material_product_code',@pack_material_product_codes) %>
    <script>
    <%= update_element_function(
        "treatment_code_cell", :action => :update,
        :content => treatment_content)%>
     <%= update_element_function(
        "handling_product_type_code_cell", :action => :update,
        :content => @type_code)%>
     <%= update_element_function(
        "pack_material_product_code_cell", :action => :update,
        :content => pm_content)%>
    </script>
	}
 
 end


end
