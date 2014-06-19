class  Production::TradeEnvironmentSetupController < ApplicationController
 
 #fix: paging fixed
 
def program_name?
	"trade_environment_setup"
end

def bypass_generic_security?
	true
end

def list_trade_environment_setups
	return if authorise_for_web('trade_environment_setup','read') == false 
	

 	if params[:page]!= nil 

 		session[:trade_environment_setups_page] = params['page']

		 render_list_trade_environment_setups

		 return 
	else
		session[:trade_environment_setups_page] = nil
	end
  
    is_view = nil
    if session[:current_prod_schedule]== nil
      msg = "You must first select or set a 'current' production schedule from the 'production schedules' tab"
      @freeze_flash = true
      redirect_to_index(msg)
      return
    end
   

    @current_prod_schedule = session[:current_prod_schedule].production_schedule_name 
	list_query = "@trade_environment_setup_pages = Paginator.new self, TradeEnvironmentSetup.count(\"production_schedule_code = '#{session[:current_prod_schedule].production_schedule_name}'\"), @@page_size,@current_page
	 @trade_environment_setups = TradeEnvironmentSetup.find_all_by_production_schedule_code(session[:current_prod_schedule].production_schedule_name , 
				 :limit => @trade_environment_setup_pages.items_per_page,
				 :order => 'organization_marketing,id',
				 :offset => @trade_environment_setup_pages.current.offset)"
	session[:query] = list_query
	
	render_list_trade_environment_setups
end


def render_list_trade_environment_setups
    
    session[:current_prod_schedule].reload
    @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed"||session[:current_prod_schedule].production_schedule_status_code == "completed")
    if !@is_view
      
      @is_view = !authorise(program_name?,'trade_env_setup',session[:user_id])
    end
    
    @current_prod_schedule = session[:current_prod_schedule].production_schedule_name 
	@can_edit = !@is_view
	@can_delete = !@is_view
	
	@current_page = session[:trade_environment_setups_page] if session[:trade_environment_setups_page]
	@current_page = params['page'] if params['page']
	@trade_environment_setups =  eval(session[:query]) if !@trade_environment_setups
    render :inline => %{
      <% grid            = build_trade_environment_setup_grid(@trade_environment_setups,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of trade_environment_setups for schedule: #{@current_prod_schedule}' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@trade_environment_setup_pages) if @trade_environment_setup_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
 
def delete_trade_environment_setup
	return if authorise_for_web('trade_environment_setup','trade_env_setup')== false
	if params[:page]
		session[:trade_environment_setups_page] = params['page']
		render_list_trade_environment_setups
		return
	end
	id = params[:id]
	if id && trade_environment_setup = TradeEnvironmentSetup.find(id)
		trade_environment_setup.destroy
		session[:alert] = " Record deleted."
		render_list_trade_environment_setups
	end
end

#-------------------------------------------------------------------------
#Any amount of trade environment setup records can be created for the
#selected schedule, as longs as:
#1) a shedule has been selected 
#2) the schedule has not been closed
#3) the user has sufficient privileges
#-------------------------------------------------------------------------
def new_trade_environment_setup
	return if authorise_for_web('trade_environment_setup','trade_env_setup')== false
	
   is_view = nil
   if session[:current_prod_schedule]== nil
    msg = "You must first select or set a 'current' production schedule from the 'production schedules' tab"
    @freeze_flash = true
    redirect_to_index(msg)
    return
   else
    session[:current_prod_schedule].reload
    is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed")
    if is_view
       @freeze_flash = true
       redirect_to_index("The schedule has been closed.")
      return
    end
   end
	
	
		render_new_trade_environment_setup
end
 
def create_trade_environment_setup
    params[:trade_environment_setup].delete("ajax_distributor")
    params[:trade_environment_setup][:production_schedule_code]= session[:current_prod_schedule].production_schedule_name
	 @trade_environment_setup = TradeEnvironmentSetup.new(params[:trade_environment_setup])
	 if @trade_environment_setup.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_trade_environment_setup
	 end
end

def render_new_trade_environment_setup
#	 render (inline) the edit template
     @current_prod_schedule = session[:current_prod_schedule].production_schedule_name 
	render :inline => %{
		<% @content_header_caption = "'create new trade environment for schedule: " + @current_prod_schedule + "'"%> 

		<%= build_trade_environment_setup_form(@trade_environment_setup,'create_trade_environment_setup','create_trade_environment_setup',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_trade_environment_setup
	return if authorise_for_web('trade_environment_setup','trade_env_setup')==false 
	 id = params[:id]
	 if id && @trade_environment_setup = TradeEnvironmentSetup.find(id)
	    session[:current_trade_env]= @trade_environment_setup
		render_edit_trade_environment_setup

	 end
end

def view_paging_handler

  if params[:page]
	session[:trade_environment_setups_page] = params['page']
  end
  render_list_trade_environment_setups
  
end


def view_trade_environment_setup
     id = params[:id]
     @schedule = session[:current_prod_schedule].production_schedule_name
	 if id && @trade_environment_setup = TradeEnvironmentSetup.find(id)
        render :inline => %{
		<% @content_header_caption = "'view trade_environment_setup for schedule: " + @schedule + "'" %> 

		<%= build_trade_environment_setup_view(@trade_environment_setup)%>

		}, :layout => 'content'
    end
end

def render_edit_trade_environment_setup
#	 render (inline) the edit template
   @schedule = session[:current_prod_schedule].production_schedule_name
	render :inline => %{
    <% @content_header_caption = "'edit trade_environment_setup for schedule: " + @schedule + "'" %> 

		<%= build_trade_environment_setup_form(@trade_environment_setup,'update_trade_environment_setup','update_trade_environment_setup',true)%>

		}, :layout => 'content'
end
 
def update_trade_environment_setup
	if params[:page]
		session[:trade_environment_setups_page] = params['page']
		render_list_trade_environment_setups
		return
	end

	@current_page = session[:trade_environment_setups_page]
	 id = params[:trade_environment_setup][:id]
	 if id && @trade_environment_setup = TradeEnvironmentSetup.find(id)
		 if @trade_environment_setup.update_attributes(params[:trade_environment_setup])
			session[:current_trade_env]= nil
			@trade_environment_setups = eval(session[:query])
			render_list_trade_environment_setups
			
	 else
			 render_edit_trade_environment_setup

		 end
	 end
 end
 
 def retailer_org_combo_changed
  session[:selected_retailer]= get_selected_combo_value(params)
  render :inline => %{ 
  
  }
 end
 
 def intake_org_combo_changed
 
  session[:selected_intaker]= get_selected_combo_value(params)
  render :inline => %{ 
  }
  
 end
 

 def marketer_org_combo_changed
 
  intaker = nil
  retailer = nil
  
  single_org_query = false
  
  
  if session[:selected_retailer] && session[:selected_retailer] != ""
   retailer = session[:selected_retailer]
  else
    if session[:current_trade_env]
      retailer = session[:current_trade_env].organization_retailer
    else
      single_org_query = true
    end
  end
  
  if single_org_query == false
    if session[:selected_intaker] && session[:selected_intaker] != ""
       intaker = session[:selected_intaker]
    else
      if session[:current_trade_env]
        intaker = session[:current_trade_env].organization_intake
      else
        single_org_query = true
      end
    end
  end
 
  marketer = get_selected_combo_value(params)#the filter value
  @ri_marks = Mark.get_all_for_org(marketer)
  @retail_marks = Mark.get_all_for_org(retailer)
  @marks = Mark.get_all_for_org(marketer)
  
  #TODO REMEMBER TO REMOVE PUTS STATEMENTS IN NEW VERSION
  #@sell_by_codes = Organization.get_sell_bys_by_org("MARKETER",marketer)
  
  @sell_by_codes = Organization.get_sell_bys_by_org("RETAILER",retailer)
  @target_market_codes = TargetMarket.get_all_by_org(marketer)
  @account_codes = TradeEnvironmentSetup.accounts_for_role_and_org("MARKETER",marketer).map{|g|[g.account_code]}
  
  render :inline => %{
    <% sell_by_content = select('trade_environment_setup','sell_by_code',@sell_by_codes) %>
    <% target_market_content = select('trade_environment_setup','target_market_description',@target_market_codes) %>
    <% fruit_mark_content = select('trade_environment_setup','mark_fruit_description',@ri_marks) %>
    <% retail_mark_content = select('trade_environment_setup','mark_retail_unit_description',@retail_marks) %>
    <% trade_unit_content = select('trade_environment_setup','mark_trade_unit_description',@ri_marks) %>
    <% account_code_content = select('trade_environment_setup','account_code',@account_codes) %>
   <script>
    <%= update_element_function(
        "sell_by_code_cell", :action => :update,
        :content => sell_by_content) %>
        
     <%= update_element_function(
        "target_market_description_cell", :action => :update,
        :content => target_market_content) %>
        
     <%= update_element_function(
        "mark_fruit_description_cell", :action => :update,
        :content => fruit_mark_content) %>
        
     <%= update_element_function(
        "mark_retail_unit_description_cell", :action => :update,
        :content => retail_mark_content)%>
        
     <%= update_element_function(
        "mark_trade_unit_description_cell", :action => :update,
        :content => trade_unit_content)%>
        
     <%= update_element_function(
        "account_code_cell", :action => :update,
        :content => account_code_content)%>
        
   </script>
  }
  
 end
 
 def grade_combo_changed
 
    grade = get_selected_combo_value(params)
	@inspection_type_codes = InspectionType.find_all_by_grade_code_and_for_internal_hg_inspections_only(grade,false).map{|g|[g.inspection_type_code]}
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('trade_environment_setup','qc_inspection_type',@inspection_type_codes)%>

		}
  
 end
 
 
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(trade_environment_setups)
#	-----------------------------------------------------------------------------------------------------------
def trade_environment_setup_id_search_combo_changed
	id = get_selected_combo_value(params)
	session[:trade_environment_setup_search_form][:id_combo_selection] = id
	@production_schedule_ids = TradeEnvironmentSetup.find_by_sql("Select distinct production_schedule_id from trade_environment_setups where id = '#{id}'").map{|g|[g.production_schedule_id]}
	@production_schedule_ids.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('trade_environment_setup','production_schedule_id',@production_schedule_ids)%>

		}

end



end
