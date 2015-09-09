class Production::RmtSetupController < ApplicationController

#fix: paging fixed

 helper "products/rmt_product"
 
 def program_name?
	"rmt_setup"
end

def bypass_generic_security?
	true
end


#===============================================================
# Bin Tip Criteria controller code
#===============================================================

def get_existing_bintip_criteria_setup
   return if session[:current_prod_schedule]== nil
    sched_nr = session[:current_prod_schedule].id
    
    return BintipCriterium.find_by_production_schedule_id(sched_nr)

end


def bintip_criteria_setup
 return if authorise_for_web(program_name?,'read') == false 
  begin
  msg = nil
  @bintip_criteria_setup = get_existing_bintip_criteria_setup
  if session[:current_prod_schedule]== nil
    msg = "You must first select or set a 'current' production schedule from the 'production schedules' tab"
  end
  
  if msg != nil
    @freeze_flash = true
    redirect_to_index(msg)
    return
  end
  
  session[:current_prod_schedule].reload 
  @is_view = ! authorise(program_name?,'rmt_setup',session[:user_id])
  
  if !@is_view
     @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed")
  end
  
  
  if @bintip_criteria_setup != nil
    render_edit_bintip_criterium
  elsif !@is_view
    render_new_bintip_criterium
  else
    @freeze_flash = true
    redirect_to_index("bin tip criteria has not yet been defined for schedule: " + session[:current_prod_schedule].production_schedule_name )
    return
  end
  rescue
    handle_error("Bin tip criteria could not be fetched")
  end
end
 
def create_bintip_criterium
	 @bintip_criterium = BintipCriterium.new(params[:bintip_criteria_setup])
	 
	 @bintip_criterium.production_schedule = session[:current_prod_schedule]
	 if @bintip_criterium.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_bintip_criterium
	 end
end

def render_new_bintip_criterium
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'initial bintip_criteria setup for schedule: " + session[:current_prod_schedule].production_schedule_name + "'"%> 

		<%= build_bintip_criterium_form(@bintip_criteria_setup,'create_bintip_criterium','save',false,@is_create_retry)%>

		}, :layout => 'content'
end
 


def render_edit_bintip_criterium
#	 render (inline) the edit template
    @caption_action = " view"
    @caption_action = "edit " if !@is_view
    
    
	render :inline => %{
		<% @content_header_caption = "'" + @caption_action + " bintip_criteria setup for schedule: " + session[:current_prod_schedule].production_schedule_name + "'"%> 

		<%= build_bintip_criterium_form(@bintip_criteria_setup,'update_bintip_criterium','update_bintip_criterium',true,false,@is_view)%>

		}, :layout => 'content'
end
 
def update_bintip_criterium
	 id = params[:bintip_criteria_setup][:id]
	 if id && @bintip_criteria_setup = BintipCriterium.find(id)
		 if @bintip_criteria_setup.update_attributes(params[:bintip_criteria_setup])
			redirect_to_index("bin tip criteria updated successfully")
		 end
	 end
 end


#===============================================================
# RMT Setup controller code
#===============================================================

def copy_attributes(source_record,target_record)

  source_record.attributes.each do |name,attr|
    if !(name.index("_id") || name == "id")
      if target_record.has_attribute?(name)
     
        eval "target_record." + name + " = '#{attr}'"
      
      end
    end
  end


end
#----------------------------------------------------------------------------------------------
#This method is called as a result of a user selecting a rmt product from the rmt_products grid
#We have to display a form to allow for the creation of a new rmt_setup record (except if schedule
#has been closed- in which case there is nothing to show + we cannot allow create to proceed)
#We do have to make sure that the user has already selected a production schedule
#-----------------------------------------------------------------------------------------
def setup_new_rmt_product
    
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
       redirect_to_index("The schedule has been closed, even though a setup record has not yet been created")
      return
    end
   end
   
   #we are in a valid state. We need to:
   #create a new rmt_setup record, copying the values from the rmt_product to the 
   #rmt_setup, except any fkey values
   @rmt_setup = nil
   
 #  begin
    rmt_product = RmtProduct.find(params[:id].to_i)
    @rmt_setup = RmtSetup.new
    copy_attributes(rmt_product,@rmt_setup)
    @rmt_setup.production_schedule = session[:current_prod_schedule]
    @rmt_setup.production_schedule_name = session[:current_prod_schedule].production_schedule_name
    @rmt_setup.rmt_product = rmt_product
    
    @rmt_setup.pc_code = rmt_product.ripe_point.pc_code.pc_code
    @rmt_setup.rmt_product_code = rmt_product.rmt_product_code
    @rmt_setup.cold_store_code  = rmt_product.ripe_point.cold_store_type.cold_store_type_code
    @rmt_setup.create
    session[:current_prod_schedule].variety_code = @rmt_setup.variety_code
    session[:current_prod_schedule].add_variety_to_schedule_name(@rmt_setup.variety_code)
    session[:current_prod_schedule].save
    @info_sticker = "current production schedule is: '" + session[:current_prod_schedule].production_schedule_name + "'"
  # rescue
  #  handle_error("rmt_setup record could not be created")
  #  return
 #  end
   @freeze_flash = true
   flash[:notice]= "A rmt setup record has been created from the rmt product you selected <br> You can edit fields that have input controls provided "
   render :inline => %{
		<% @content_header_caption = "'edit rmt setup'"%> 

		<%= build_rmt_setup_form(@rmt_setup)%>

		}, :layout => 'content'
   
   

end


def save_rmt_setup
  begin
    ca_cold_room = params[:rmt_setup][:ca_cold_room_code]
    track_indicator = params[:rmt_setup][:track_indicator_code]
    id = params[:rmt_setup][:id].to_i
    rmt_setup = RmtSetup.find(id)
    rmt_setup.ca_cold_room_code = ca_cold_room
    rmt_setup.track_indicator_code = track_indicator
    rmt_setup.output_track_indicator_code = track_indicator
    if rmt_setup.save
     redirect_to_index("rmt setup record saved")
     return
    else
      raise rmt_setup.errors.full_messages.to_s
    end
  rescue
    handle_error("rmt setup could not be saved")
    return
  end

end


#------------------------------------------------------------------------------
#This method is called from a user clicking the menu item 'setup_rmt'
#This method is used to edit an existing setup. The following constraints/rules
#apply here:
# 1) The user must previously have selected a production schedule
# 2) The user must have the 'rmt_setup' permission
# 3) A rmt_setup record must be in existence
#------------------------------------------------------------------------------
def setup_rmt
  return if authorise_for_web(program_name?,'read') == false 
  msg = nil
  @rmt_setup = get_existing_rmt_setup
  if session[:current_prod_schedule]== nil
    msg = "You must first select or set a 'current' production schedule from the 'production schedules' tab"
  elsif @rmt_setup == nil
    msg = "A rmt setup has not yet been defined for the current schedule <br> Use the 'find' tab to search for and select a rmt_product for a new rmt setup"
  end
  
  if msg != nil
    @freeze_flash = true
    redirect_to_index(msg)
    return
  end
  
  session[:current_prod_schedule].reload 
  @is_view = ! authorise(program_name?,'rmt_setup',session[:user_id])
  puts "is view: " + @is_view.to_s
  if !@is_view
     @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed"||session[:current_prod_schedule].production_schedule_status_code == "completed")
  end
  
  @caption_action = " view"
  @caption_action = "edit " if !@is_view
  render :inline => %{
		<% @content_header_caption = "'" + @caption_action + " rmt setup'"%> 

		<%= build_rmt_setup_form(@rmt_setup,@is_view)%>

		}, :layout => 'content'
   
  
  
end


def get_existing_rmt_setup
  return if session[:current_prod_schedule]== nil
  sched_nr = session[:current_prod_schedule].id
  
  return RmtSetup.find_by_production_schedule_id(sched_nr)

end

def render_list_rmt_products

	@can_setup = authorise(program_name?,'rmt_setup',session[:user_id])
	
	if @can_setup #does rmt_setup record exists
	   if get_existing_rmt_setup != nil
	     @can_setup = false
	   end
	   @can_setup = false if session[:current_prod_schedule]== nil
	end

	render :inline => %{
      <% grid            = build_rmt_product_grid(@rmt_products,false,false,true,@can_setup) %>
      <% grid.caption    = 'list of found rmt_products' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@rmt_product_pages) if @rmt_product_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_rmt_products_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_rmt_product_search_form
end

def render_rmt_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  rmt_products'"%> 

		<%= build_rmt_product_search_form(nil,'submit_rmt_products_search','submit_rmt_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_rmt_products_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_rmt_product_search_form(true)
end

def render_rmt_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  rmt_products'"%> 

		<%= build_rmt_product_search_form(nil,'submit_rmt_products_search','submit_rmt_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_rmt_products_search
	
	if params['page']
		session[:rmt_products_page] =params['page']
	else
		session[:rmt_products_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @rmt_products = dynamic_search(params[:rmt_product] ,'rmt_products','RmtProduct',true, nil,'rmt_product_code')
	else
		@rmt_products = eval(session[:query])
	end
	
	if @rmt_products.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_rmt_product_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_rmt_products
		end
	else
		session[:rmt_products] = @rmt_products
		@rmt_products = session[:rmt_products]
		render_list_rmt_products
	end
end
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(rmt_products)
#	-----------------------------------------------------------------------------------------------------------
def rmt_product_commodity_group_code_search_combo_changed
	commodity_group_code = get_selected_combo_value(params)
	session[:rmt_product_search_form][:commodity_group_code_combo_selection] = commodity_group_code
	@commodity_codes = RmtProduct.find_by_sql("Select distinct commodity_code from rmt_products where commodity_group_code = '#{commodity_group_code}'").map{|g|[g.commodity_code]}
	@commodity_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','commodity_code',@commodity_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_product_commodity_code'/>
		<%= observe_field('rmt_product_commodity_code',:update => 'variety_code_cell',:url => {:action => session[:rmt_product_search_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_rmt_product_commodity_code');",:complete => session[:rmt_product_search_form][:commodity_code_observer][:on_completed_js])%>
		}

end


def rmt_product_commodity_code_search_combo_changed
	commodity_code = get_selected_combo_value(params)
	session[:rmt_product_search_form][:commodity_code_combo_selection] = commodity_code
	commodity_group_code = 	session[:rmt_product_search_form][:commodity_group_code_combo_selection]
	@variety_codes = RmtProduct.find_by_sql("Select distinct variety_code from rmt_products where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.variety_code]}
	@variety_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','variety_code',@variety_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_product_variety_code'/>
		<%= observe_field('rmt_product_variety_code',:update => 'size_code_cell',:url => {:action => session[:rmt_product_search_form][:variety_code_observer][:remote_method]},:loading => "show_element('img_rmt_product_variety_code');",:complete => session[:rmt_product_search_form][:variety_code_observer][:on_completed_js])%>
		}

end


def rmt_product_variety_code_search_combo_changed
	variety_code = get_selected_combo_value(params)
	session[:rmt_product_search_form][:variety_code_combo_selection] = variety_code
	commodity_code = 	session[:rmt_product_search_form][:commodity_code_combo_selection]
	commodity_group_code = 	session[:rmt_product_search_form][:commodity_group_code_combo_selection]
	@size_codes = RmtProduct.find_by_sql("Select distinct size_code from rmt_products where variety_code = '#{variety_code}' and commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.size_code]}
	@size_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','size_code',@size_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_product_size_code'/>
		<%= observe_field('rmt_product_size_code',:update => 'product_class_code_cell',:url => {:action => session[:rmt_product_search_form][:size_code_observer][:remote_method]},:loading => "show_element('img_rmt_product_size_code');",:complete => session[:rmt_product_search_form][:size_code_observer][:on_completed_js])%>
		}

end


def rmt_product_size_code_search_combo_changed
	size_code = get_selected_combo_value(params)
	session[:rmt_product_search_form][:size_code_combo_selection] = size_code
	variety_code = 	session[:rmt_product_search_form][:variety_code_combo_selection]
	commodity_code = 	session[:rmt_product_search_form][:commodity_code_combo_selection]
	commodity_group_code = 	session[:rmt_product_search_form][:commodity_group_code_combo_selection]
	@product_class_codes = RmtProduct.find_by_sql("Select distinct product_class_code from rmt_products where size_code = '#{size_code}' and variety_code = '#{variety_code}' and commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.product_class_code]}
	@product_class_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','product_class_code',@product_class_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_product_product_class_code'/>
		<%= observe_field('rmt_product_product_class_code',:update => 'ripe_point_code_cell',:url => {:action => session[:rmt_product_search_form][:product_class_code_observer][:remote_method]},:loading => "show_element('img_rmt_product_product_class_code');",:complete => session[:rmt_product_search_form][:product_class_code_observer][:on_completed_js])%>
		}

end


def rmt_product_product_class_code_search_combo_changed
	product_class_code = get_selected_combo_value(params)
	session[:rmt_product_search_form][:product_class_code_combo_selection] = product_class_code
	size_code = 	session[:rmt_product_search_form][:size_code_combo_selection]
	variety_code = 	session[:rmt_product_search_form][:variety_code_combo_selection]
	commodity_code = 	session[:rmt_product_search_form][:commodity_code_combo_selection]
	commodity_group_code = 	session[:rmt_product_search_form][:commodity_group_code_combo_selection]
	@ripe_point_codes = RmtProduct.find_by_sql("Select distinct ripe_point_code from rmt_products where product_class_code = '#{product_class_code}' and size_code = '#{size_code}' and variety_code = '#{variety_code}' and commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.ripe_point_code]}
	@ripe_point_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','ripe_point_code',@ripe_point_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_product_ripe_point_code'/>
		<%= observe_field('rmt_product_ripe_point_code',:update => 'treatment_code_cell',:url => {:action => session[:rmt_product_search_form][:ripe_point_code_observer][:remote_method]},:loading => "show_element('img_rmt_product_ripe_point_code');",:complete => session[:rmt_product_search_form][:ripe_point_code_observer][:on_completed_js])%>
		}

end


def rmt_product_ripe_point_code_search_combo_changed
	ripe_point_code = get_selected_combo_value(params)
	session[:rmt_product_search_form][:ripe_point_code_combo_selection] = ripe_point_code
	product_class_code = 	session[:rmt_product_search_form][:product_class_code_combo_selection]
	size_code = 	session[:rmt_product_search_form][:size_code_combo_selection]
	variety_code = 	session[:rmt_product_search_form][:variety_code_combo_selection]
	commodity_code = 	session[:rmt_product_search_form][:commodity_code_combo_selection]
	commodity_group_code = 	session[:rmt_product_search_form][:commodity_group_code_combo_selection]
	@treatment_codes = RmtProduct.find_by_sql("Select distinct treatment_code from rmt_products where ripe_point_code = '#{ripe_point_code}' and product_class_code = '#{product_class_code}' and size_code = '#{size_code}' and variety_code = '#{variety_code}' and commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.treatment_code]}
	@treatment_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_product','treatment_code',@treatment_codes)%>

		}

end



end
