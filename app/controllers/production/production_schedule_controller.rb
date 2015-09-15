class  Production::ProductionScheduleController < ApplicationController
 
 #fix: pagination fixed
 
def program_name?
	"production_schedule"
end

def bypass_generic_security?
	true
end

 
def save_as_template
  return if authorise_for_web('production_schedule','edit')== false
  
  @schedule = ProductionSchedule.find(params[:id])
  session[:template_schedule_base]= @schedule
  
  render :inline => %{
     <script>
     val = prompt("Please enter a name for the template created from schedule : <%= @schedule.production_schedule_name %>");
     window.location.href = "/production/production_schedule/submit_save_as_template/" + val;
     </script>
     }

end


def submit_save_as_template
  return if authorise_for_web('production_schedule','edit')== false
	template_name = params[:id].to_s
	production_schedule = session[:template_schedule_base]
	session[:template_schedule_base]= nil
	if template_name != "null"
	   if production_schedule.production_schedule_status_code != "closed" && production_schedule.production_schedule_status_code != "completed" && production_schedule.production_schedule_status_code != "re_opened"
        production_schedule.production_schedule_status_code = "template" 
       end
        production_schedule.template_name = template_name
        production_schedule.update
        flash[:notice]= "production schedule saved as  a template"
     end
  
  render_list_production_schedules
  
 end

def re_open_production_schedule
  return if authorise_for_web('production_schedule','edit')== false
	id = params[:id]
	if id && production_schedule = ProductionSchedule.find(id)
	  if production_schedule.production_schedule_status_code == "re_opened"|| production_schedule.production_schedule_status_code == "active"
        flash[:notice]= "production schedule is already open"
      elsif production_schedule.production_schedule_status_code == "completed"
        flash[:notice]= "completed schedules cannot be re-opened"
      else
        production_schedule.production_schedule_status_code = "re_opened"
        production_schedule.update
        session[:current_prod_schedule]= production_schedule
        @info_sticker = "current production schedule is: '" + production_schedule.production_schedule_name + "'"
        flash[:notice]= "production schedule re-opened"
     end
    end
  
  render_list_production_schedules
  
 end
  

def close_schedule
 #begin
 
  if session[:current_prod_schedule]== nil
      msg = "You must first select or set a 'current' production schedule from the 'production schedules' tab"
      @freeze_flash = true
      redirect_to_index(msg)
      return
  end
  
  return if authorise_for_web('production_schedule','edit')== false
  
  session[:current_prod_schedule].reload
  #-------------------------------------------------------------------------
  #A schedule can only be closed, if 
  #1) status is not 'completed' or 'template'
  #2) fg products have been defined for all
  #   its carton setups
  #3) Carton templates and labels have been created
  #4) rebin labels have been created for rebin records (if labels were created
  #   it means templates have also been created
  #5) bintip criteria and pallet criteria have been defined   
  #-------------------------------------------------------------------------
  
   if session[:current_prod_schedule].production_schedule_status_code == "template"
    redirect_to_index("Template schedules cannot be closed")
    return
   elsif session[:current_prod_schedule].production_schedule_status_code == "completed"
    redirect_to_index("Completed schedules cannot be closed")
    return
  end
  
  can_close = true
  msg = ""
  
  if session[:current_prod_schedule].carton_setups.length == 0
    can_close = false
    msg = "You have not defined any carton setups yet"
  else
    session[:current_prod_schedule].carton_setups.each do |carton_setup|
      if !carton_setup.fg_setup ||!carton_setup.fg_setup.fg_product
        can_close = false
         msg = "You have not done a FG setup for carton setup: '#{carton_setup.carton_setup_code}'"
         break
     end
     
     if !carton_setup.pallet_setup
      can_close = false
        msg = "You have not done a pallet setup for carton setup: '#{carton_setup.carton_setup_code}'"
         break
     end
   end
   
   #check if rebin labels have been created
   session[:current_prod_schedule].rebin_setups.each do |rebin_setup|
      if !rebin_setup.rebin_label_setup
        can_close = false
         msg = "You have not define a rebin label setup for rebin setup of size: '#{rebin_setup.size}' and rmt_product: '#{rebin_setup.rmt_product_code}'"
         break
     end
   end
   
  end
  
  if msg == ""
    if !session[:current_prod_schedule].bintip_criterium
      msg = "You have not defined bintip criteria"
      can_close = false
    elsif !session[:current_prod_schedule].pallet_criterium
      can_close = false
      msg = "You have not defined pallet criteria"
    end
   end
   
   if can_close == false
      @freeze_flash = true
      redirect_to_index("The active schedule cannot be closed- something is incomplete, specifically : <br>" + msg)
      return 
   end  
  
 
  n_templates_built = session[:current_prod_schedule].update_all_carton_setups_templates_and_labels
  session[:current_prod_schedule].production_schedule_status_code = "closed"
  session[:current_prod_schedule].save!
  msg = "schedule closed. " + "<br><font color = 'green'>" + n_templates_built.to_s + " sets of carton templates built </font>"
  
  if session[:schedules_query] == nil
	 @freeze_flash = true
	 redirect_to_index(msg + "<BR> You don't have any cached schedules")
  else
     flash[:notice] = msg
     render_list_production_schedules
  end
 #rescue
   #handle_error("schedule could not be closed")
 #end
end

 
#this action is displayed as 'cached schedules' to the user
def list_production_schedules

      
	return if authorise_for_web('production_schedule','read') == false 
    
   
    
    if params[:page]!= nil 

 		session[:schedules_page] = params['page']
		 render_list_production_schedules

		 return 
	else
		session[:schedules_page] = nil
	end
		 		 
	if session[:schedules_query] == nil
	 @freeze_flash = true
	 redirect_to_index(" You don't have any cached schedules. Use the 'search' or 'find' menu actions to fetch schedules. <br> The results will be cached for quick retrieval later on")
	else
	 
	 render_list_production_schedules("'List of cached schedules'")
	end
	
end

def set_active_schedule

  prod_schedule = ProductionSchedule.find(params[:id].to_i)
  session[:current_prod_schedule]= prod_schedule
  @content_header_caption = "'current schedule set'"
  #@freeze_flash = true
  @info_sticker = "current production schedule is: '" + prod_schedule.production_schedule_name + "'"
  redirect_to_index(" You have set the current production schedule for setup tasks to: " + prod_schedule.production_schedule_name)
  
end

#needed for schedules returned by an extended search which returned records joined wit
#trade environments: so we must get reid of the duplicates in the schedules resultset

def make_unique(schedules)
  scheds = Array.new
  unique_list = Hash.new
  schedules.each do |schedule|
    if unique_list.has_key?(schedule.id)==false
     scheds.push schedule
     unique_list.store(schedule.id,1)
    end
  end
  
  return scheds
  
end

def complete_production_schedule
  return if authorise_for_web('production_schedule','edit')== false
	id = params[:id]
	if id && production_schedule = ProductionSchedule.find(id)
	    if production_schedule.production_schedule_status_code == "template"
	      flash[:notice]= "template schedules cannot be completed"
	    elsif production_schedule.production_schedule_status_code != "closed"
          flash[:notice]= "only 'closed' schedules can be completed"
        else
          production_schedule.production_schedule_status_code = "completed" 
          production_schedule.update
          flash[:notice]= "production schedule completed"
       end
     end
  
  render_list_production_schedules

end

def clone_schedule
  return if authorise_for_web('production_schedule','edit')==false 
	 id = params[:id]
	begin 
	 if id && @production_schedule = ProductionSchedule.find(id)
	    session[:template_schedule]= @production_schedule
	    if @production_schedule.production_schedule_status_code != "active"
	      flash[:notice] = "PLEASE NOTE: Cloning a schedule involves extensive database reading and writing and will take some time to complete"
		  @freeze_flash = true
		  
		  render :inline => %{
		<% @content_header_caption = "'create new production_schedule'"%> 

		<%= build_production_schedule_form(@production_schedule,'create_new_schedule_from_template','create new schedule from_template',false,nil,true)%>

		}, :layout => 'content'
        else
          flash[:notice]= "You cannot create an incomplete schedule as template- it's status cannot be 'active'"
          render_list_production_schedules
        end
	 end
  rescue
    handle_error("cloning failed")
  end
end

def create_new_schedule_from_template
 
 begin
  
   template_schedule = session[:template_schedule]
   template_schedule.class_code = params[:production_schedule]['class_code']
   template_schedule.ripe_point_code = params[:production_schedule]['ripe_point_code']
   template_schedule.size_code = params[:production_schedule]['size_code']
   template_schedule.rmt_type = params[:production_schedule]['rmt_type']
   template_schedule.bin_type = params[:production_schedule]['bin_type']

   #NAE 2015-05-14 add treatment_code
   template_schedule.treatment_code = params[:production_schedule]['treatment_code']
   
   session[:template_schedule] = nil
   new_schedule = template_schedule.create_from_template(params[:production_schedule])

   flash[:notice]= "new schedule ceated successfully"
   session[:schedules_query]= "ProductionSchedule.find_all_by_id('#{new_schedule.id}')"
   session[:current_prod_schedule]= new_schedule
   @info_sticker = "current production schedule is: '" + new_schedule.production_schedule_name + "'"
   render_list_production_schedules
 rescue
  handle_error("New schedule could not be created from the template")
 end
end


def render_list_production_schedules(form_caption = nil)

	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	
	@current_page = session[:schedules_page] if session[:schedules_page]
	
	@current_page = params['page'] if params['page']
	
	@production_schedules =  eval(session[:schedules_query]) if !@production_schedules

  if  @production_schedules.length() == 0
    redirect_to_index("no schedules to display")
    return
  end

	@production_schedules = make_unique(@production_schedules)
	session[:query]= session[:schedules_query]if session[:schedules_query]
	
	@caption = "'list of found production_schedules'"
	@caption = form_caption if form_caption != nil
    render :inline => %{
      <% grid            = build_production_schedule_grid(@production_schedules,@can_edit,@can_delete) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@production_schedule_pages) if @production_schedule_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_production_schedules_flat
	return if authorise_for_web('production_schedule','read')== false
	render :inline => %{
		<% @content_header_caption = "'search  production_schedules'"%> 

		<%= build_extended_search_form()%>

		}, :layout => 'content'
end

def render_production_schedule_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  production_schedules'"%> 

		<%= build_production_schedule_search_form(nil,'submit_production_schedules_search','submit_production_schedules_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_production_schedules_hierarchy
	return if authorise_for_web('production_schedule','read')== false
 
	@is_flat_search = false 
	render_production_schedule_search_form(true)
end

def render_production_schedule_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  production_schedules'"%> 

		<%= build_production_schedule_search_form(nil,'submit_production_schedules_search','submit_production_schedules_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
 def submit_extended_search
    
	extended_search_query = build_extended_search_query(params[:production_schedule]) 
	     
	 puts extended_search_query
    list_query = "@production_schedules = ProductionSchedule.find_by_sql(\"" + extended_search_query  + "\")"
	session[:query] = list_query
	session[:schedules_query] = list_query
	@production_schedules = eval(session[:query]) 
	     
	if @production_schedules.length == 0
		
		flash[:notice] = 'no records were found for the query'
		search_production_schedules_flat
		
	else
		
		render_list_production_schedules
	end
 

 end
 #FOR PAGINATION: BUT PROBLEMATIC
# def submit_extended_search
#    
#    if params['page']
#		session[:schedules_page] =params['page']
#		session[:schedules_query]
#	else
#		session[:schedules_page] = nil
#	end
#	@current_page = params['page']||session[:schedules_page]
#	if params[:page]== nil
#	     
#	     extended_count_query = build_extended_count_query(params[:production_schedule])
#	     extended_search_query = build_extended_search_query(params[:production_schedule]) 
#	     
#	    # puts extended_count_query
#	     list_query = "@production_schedule_pages = Paginator.new self, ProductionSchedule.count_by_sql(\"" + extended_count_query +  "\"), @@page_size,@current_page
#	             @production_schedules = ProductionSchedule.find_by_sql(\"" + extended_search_query 
#	    session[:query] = list_query
#	
#	     puts session[:query]
#		 @production_schedules = eval(session[:query] + " OFFSET '#{params[:page]||0}'\")")
#	     session[:extended_schedules_search_query]= session[:query]
#	     session[:query]= nil
#	else
#	    puts session[:schedules_query]
#		@production_schedules = eval(session[:extended_schedules_search_query] + " OFFSET '#{params[:page]||0}'\")")
#	end
#	
#	if @production_schedules.length == 0
#		if params[:page] == nil
#			flash[:notice] = 'no records were found for the query'
#			render_production_schedule_search_form
#		else
#			flash[:notice] = 'There are no more records'
#			render_list_production_schedules
#		end
#	else
#		
#		render_list_production_schedules
#	end
# 
# 
# end
 
def submit_production_schedules_search
	
	if params['page']
		session[:schedules_page] =params['page']
	else
		session[:schedules_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @production_schedules = dynamic_search(params[:production_schedule] ,'production_schedules','ProductionSchedule',true, nil,'production_schedule_name')
	     session[:schedules_query]= session[:query]
	     session[:query]= nil
	else
		@production_schedules = eval(session[:schedules_query])
	end
	
	if @production_schedules.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_production_schedule_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_production_schedules
		end
	else
		
		render_list_production_schedules
	end
end

 
def delete_production_schedule
	return if authorise_for_web('production_schedule','delete')== false
	id = params[:id]
	if id && production_schedule = ProductionSchedule.find(id)
	 begin
	    if production_schedule.production_schedule_status_code != "closed" && production_schedule.production_schedule_status_code != "completed"
	      if session[:current_prod_schedule]
	       session[:current_prod_schedule] = nil if session[:current_prod_schedule].production_schedule_name == production_schedule.production_schedule_name
	       @info_sticker = ""
	      end
		  production_schedule.destroy
		  
		  session[:alert] = " Record deleted."
         
		else
		 
		  flash[:notice] = "This schedule(" + production_schedule.production_schedule_name + ")  has been closed or completed and cannot be deleted"
		end
		render_list_production_schedules
	  rescue
	   handle_error("Production schedule cannot be deleted. There are setup data dependant on this schedule")
	  end
	end
end
 
def new_production_schedule
	return if authorise_for_web('production_schedule','create')== false
		render_new_production_schedule
end
 
def create_production_schedule
   begin
	 @production_schedule = ProductionSchedule.new(params[:production_schedule])
	 if @production_schedule.save
	      session[:current_prod_schedule]= @production_schedule
          @info_sticker = "current production schedule is: '" + @production_schedule.production_schedule_name + "'"
		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_production_schedule
	 end
	rescue
	  handle_error("schedule could not be created")
	end
end

def render_new_production_schedule
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new production_schedule'"%> 

		<%= build_production_schedule_form(@production_schedule,'create_production_schedule','create_production_schedule',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_production_schedule
	return if authorise_for_web('production_schedule','edit')==false 
	 id = params[:id]
	 @cancel_action = "render_list_production_schedules"
	 if id && @production_schedule = ProductionSchedule.find(id)
	    if @production_schedule.production_schedule_status_code != "closed" && @production_schedule.production_schedule_status_code != "completed"
		  render_edit_production_schedule
        else
          render_view_production_schedule
        end
	 end
end

def render_view_production_schedule
  flash[:notice]= "This schedule has been closed or completed. You can only view it"
  render :inline => %{
		<% @content_header_caption = "'view production_schedule'"%> 

		<%= build_production_schedule_view_form(@production_schedule)%>

		}, :layout => 'content'

end


def render_edit_production_schedule
#	 render (inline) the edit template
   
	render :inline => %{
		<% @content_header_caption = "'edit production_schedule'"%> 

		<%= build_production_schedule_form(@production_schedule,'update_production_schedule','update_production_schedule',true)%>

		}, :layout => 'content'
end
 
def update_production_schedule

    if params[:page]
		session[:schedules_page] = params['page']
		render_list_production_schedules
		return
	end

		@current_page = session[:scedules_page]

	 id = params[:production_schedule][:id]
	 if id && @production_schedule = ProductionSchedule.find(id)
		 if @production_schedule.update_attributes(params[:production_schedule])
		    flash[:notice]= "schedule updated"
			@production_schedules = session[:production_schedules]
			render_list_production_schedules
		else
			 render_edit_production_schedule

		 end
	 end
 end
 

#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(production_schedules)
#	-----------------------------------------------------------------------------------------------------------
def production_schedule_season_code_search_combo_changed
	season_code = get_selected_combo_value(params)
	session[:production_schedule_search_form][:season_code_combo_selection] = season_code
	@iso_week_codes = ProductionSchedule.find_by_sql("Select distinct iso_week_code from production_schedules where season_code = '#{season_code}'").map{|g|[g.iso_week_code]}
	@iso_week_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('production_schedule','iso_week_code',@iso_week_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_production_schedule_iso_week_code'/>
		<%= observe_field('production_schedule_iso_week_code',:update => 'variety_code_cell',:url => {:action => session[:production_schedule_search_form][:iso_week_code_observer][:remote_method]},:loading => "show_element('img_production_schedule_iso_week_code');",:complete => session[:production_schedule_search_form][:iso_week_code_observer][:on_completed_js])%>
		}

end


def production_schedule_iso_week_code_search_combo_changed
    puts "hello varieties"
	iso_week_code = get_selected_combo_value(params)
	session[:production_schedule_search_form][:iso_week_code_combo_selection] = iso_week_code
	season_code = 	session[:production_schedule_search_form][:season_code_combo_selection]
	#@varieties = RmtSetup.varieties_for_season(season_code)
	@varieties = ProductionSchedule.find_all_by_season_code_and_iso_week_code(season_code,iso_week_code).map{|g|[g.variety_code]}
	@varieties.unshift("<empty>")
    
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('production_schedule','variety_code',@varieties)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_production_schedule_variety'/>
		<%= observe_field('production_schedule_variety_code',:update => 'farm_group_code_cell',:url => {:action => session[:production_schedule_search_form][:variety_observer][:remote_method]},:loading => "show_element('img_production_schedule_variety');",:complete => session[:production_schedule_search_form][:variety_observer][:on_completed_js])%>
		}

end


def production_schedule_variety_search_combo_changed
	variety_code = get_selected_combo_value(params)
	session[:production_schedule_search_form][:variety_combo_selection] = variety_code
	iso_week_code = 	session[:production_schedule_search_form][:iso_week_code_combo_selection]
	season_code = 	session[:production_schedule_search_form][:season_code_combo_selection]
	@farm_group_codes = ProductionSchedule.find_by_sql("Select distinct farm_group_code from production_schedules where variety_code = '#{variety_code}' and iso_week_code = '#{iso_week_code}' and season_code = '#{season_code}'").map{|g|[g.farm_group_code]}
	@farm_group_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('production_schedule','farm_group_code',@farm_group_codes)%>

		}

end


#---------------------------------------------------------------------------------------------------
#Extended search code: this method builds a query that include trade environment parameters in the
#schedule search query
#---------------------------------------------------------------------------------------------------

def build_extended_count_query(query_params)
  
 farm_group_code = "like '%'"
 farm_group_code = " = '#{query_params[:farm_group_code]}'" if query_params[:farm_group_code]!= ""
 
 iso_week_code = "like '%'"
 iso_week_code = " = '#{query_params[:iso_week_code]}'" if query_params[:iso_week_code]!= ""
 
 season_code = "like '%'"
 season_code = " = '#{query_params[:season_code]}'" if query_params[:season_code]!= ""
  
 production_schedule_status_code = "like '%'"
 production_schedule_status_code = " = '#{query_params[:production_schedule_status_code]}'" if query_params[:production_schedule_status_code]!= ""
 
 variety_code = "like '%'"
 season_code = " = '#{query_params[:variety_code]}'" if query_params[:variety_code]!= ""
 
 organization_marketing = "like '%'"
 organization_marketing = " = '#{query_params[:organization_marketing]}'" if query_params[:organization_marketing]!= ""
  
 organization_retailer = "like '%'"
 organization_retailer = " = '#{query_params[:organization_retailer]}'" if query_params[:organization_retailer]!= ""
 
 mark_retail_unit_description = "like '%'"
 mark_retail_unit_description = " = '#{query_params[:mark_retail_unit_description]}'" if query_params[:mark_retail_unit_description]!= ""
 
 target_market_description = "like '%'"
 target_market_description = " = '#{query_params[:target_market_description]}'" if query_params[:target_market_description]!= ""
  
 
  query = "SELECT COUNT(*)
          FROM
          public.trade_environment_setups
          INNER JOIN public.production_schedules ON (public.trade_environment_setups.production_schedule_id = public.production_schedules.id)
          INNER JOIN public.rmt_setups ON (public.production_schedules.id = public.rmt_setups.production_schedule_id)
          WHERE
            public.production_schedules.production_schedule_name IN
            (SELECT public.trade_environment_setups.production_schedule_code FROM public.trade_environment_setups WHERE(
                (public.trade_environment_setups.organization_marketing " + organization_marketing + ") AND 
                (public.trade_environment_setups.organization_retailer " + organization_retailer + ") AND  
                (public.trade_environment_setups.mark_retail_unit_description " + mark_retail_unit_description + ") AND 
                (public.trade_environment_setups.target_market_description " + target_market_description + " ))) AND
            (public.rmt_setups.pc_code " + pc_code + ") AND 
            (public.rmt_setups.track_indicator_code " + track_indicator_code + ") AND
            (public.production_schedules.farm_group_code " + farm_group_code + ") AND 
            (public.production_schedules.iso_week_code " + iso_week_code + ") AND 
            (public.production_schedules.season_code " + season_code + ") AND 
            (public.production_schedules.production_schedule_status_code " + production_schedule_status_code + ") AND 
            (public.production_schedules.variety_code " + variety_code + ") AND 
            (public.trade_environment_setups.organization_marketing " + organization_marketing + ") AND 
            (public.trade_environment_setups.organization_retailer " + organization_retailer + ") AND  
            (public.trade_environment_setups.mark_retail_unit_description " + mark_retail_unit_description + ") AND 
            (public.trade_environment_setups.target_market_description " + target_market_description + 
            ") ORDER BY public.production_schedules.production_schedule_name "
          


  return query



end

def build_extended_search_query(query_params)

 farm_group_code = "like '%'"
 farm_group_code = " = '#{query_params[:farm_group_code]}'" if query_params[:farm_group_code]!= ""
 
 iso_week_code = "like '%'"
 iso_week_code = " = '#{query_params[:iso_week_code]}'" if query_params[:iso_week_code]!= ""
 
 season_code = "like '%'"
 season_code = " = '#{query_params[:season_code]}'" if query_params[:season_code]!= ""
  
 production_schedule_status_code = "like '%'"
 production_schedule_status_code = " = '#{query_params[:production_schedule_status_code]}'" if query_params[:production_schedule_status_code]!= ""
 
 variety_code = "like '%'"
 variety_code = " = '#{query_params[:variety_code]}'" if query_params[:variety_code]!= ""
 
 organization_marketing = "like '%'"
 organization_marketing = " = '#{query_params[:organization_marketing]}'" if query_params[:organization_marketing]!= ""
  
 organization_retailer = "like '%'"
 organization_retailer = " = '#{query_params[:organization_retailer]}'" if query_params[:organization_retailer]!= ""
 
 mark_retail_unit_description = "like '%'"
 mark_retail_unit_description = " = '#{query_params[:mark_retail_unit_description]}'" if query_params[:mark_retail_unit_description]!= ""

 target_market_description = "like '%'"
 target_market_description = " = '#{query_params[:target_market_description]}'" if query_params[:target_market_description]!= ""
 
 pc_code = "like '%'"
 pc_code = " = '#{query_params[:pc_code]}'" if query_params[:pc_code]!= ""
 
 track_indicator_code = "like '%'"
 track_indicator_code = " = '#{query_params[:track_indicator_code]}'" if query_params[:track_indicator_code]!= ""
 
  query = "SELECT 
                public.production_schedules.season_id,
                public.production_schedules.id,
                public.production_schedules.iso_week_id,
                public.production_schedules.production_schedule_name,
                public.production_schedules.planned_start_date,
                public.production_schedules.planned_end_date,
                public.production_schedules.farm_group_code,
                public.production_schedules.iso_week_code,
                public.production_schedules.season_code,
                public.production_schedules.production_schedule_status_code,
                public.production_schedules.farm_pack,
                public.production_schedules.variety_code,
                public.rmt_setups.pc_code,
                public.rmt_setups.track_indicator_code,
                public.rmt_setups.product_class_code
          FROM
          public.trade_environment_setups
          INNER JOIN public.production_schedules ON (public.trade_environment_setups.production_schedule_id = public.production_schedules.id)
          INNER JOIN public.rmt_setups ON (public.production_schedules.id = public.rmt_setups.production_schedule_id)
          WHERE
            public.production_schedules.production_schedule_name IN
            (SELECT public.trade_environment_setups.production_schedule_code FROM public.trade_environment_setups WHERE(
                (public.trade_environment_setups.organization_marketing " + organization_marketing + ") AND 
                (public.trade_environment_setups.organization_retailer " + organization_retailer + ") AND  
                (public.trade_environment_setups.mark_retail_unit_description " + mark_retail_unit_description + ") AND 
                (public.trade_environment_setups.target_market_description " + target_market_description + " ))) AND
            (public.rmt_setups.pc_code " + pc_code + ") AND 
            (public.rmt_setups.track_indicator_code " + track_indicator_code + ") AND
            (public.production_schedules.farm_group_code " + farm_group_code + ") AND 
            (public.production_schedules.iso_week_code " + iso_week_code + ") AND 
            (public.production_schedules.season_code " + season_code + ") AND 
            (public.production_schedules.production_schedule_status_code " + production_schedule_status_code + ") AND 
            (public.production_schedules.variety_code " + variety_code + ") AND 
            (public.trade_environment_setups.organization_marketing " + organization_marketing + ") AND 
            (public.trade_environment_setups.organization_retailer " + organization_retailer + ") AND  
            (public.trade_environment_setups.mark_retail_unit_description " + mark_retail_unit_description + ") AND 
            (public.trade_environment_setups.target_market_description " + target_market_description + 
            ") ORDER BY public.production_schedules.production_schedule_name "

 
  return query
  
end


end
