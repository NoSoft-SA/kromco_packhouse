class  Production::CartonSetupController < ApplicationController
 
 helper "products/item_pack_product"
 helper "products/unit_pack_product"
 helper "products/carton_pack_product"
 helper "products/pallet_format_product"
 helper "products/fg_product"
 
 
 
def program_name?
	"carton_setup"
end

def bypass_generic_security?
	true
end

 
 def check_test
 puts "WOW"
 end

 def selected_active_setups
   active_state_before_selection = session[:carton_setups_hash]
   carton_setups=session[:carton_setups]
   @selected_carton_setups = selected_records?(carton_setups,nil,nil)
   CartonSetup.set_carton_setups_activation(@selected_carton_setups,active_state_before_selection)
    list_carton_setups
 end

  def edit_extended_fg_code
   
    @extended_fg = ExtendedFg.find(params[:id])
    if session[:current_carton_setup].fg_setup
      session[:current_carton_setup].fg_setup.extended_fg_code = @extended_fg.extended_fg_code#session[:current_carton_setup].fg_setup.calc_extended_fg if !session[:current_carton_setup].fg_setup.extended_fg_code
    end
    
    render_edit_extended_fg
  
  end
  
  def render_edit_extended_fg
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit extended_fg'"%> 

		<%= build_extended_fg_form(@extended_fg,'update_extended_fg','update_extended_fg',true)%>

		}, :layout => 'content'
end
 
def update_extended_fg
	if params[:page]
		session[:extended_fgs_page] = params['page']
		render_list_extended_fgs
		return
	end

	 @current_page = session[:extended_fgs_page]
	 id = params[:extended_fg][:id]
	 if id && @extended_fg = ExtendedFg.find(id)
		 if @extended_fg.update_attributes(params[:extended_fg])
			#go back to current fg setup
			edit_fg_setup
	 else
			 render_edit_extended_fg

		 end
	 end
 end
  
  
#=================================
#RETAIL ITEM SETUP CONTROLLER CODE
#=================================

 def view_item_pack_product
    
    @item_pack_product = session[:current_carton_setup].retail_item_setup.item_pack_product
    render :inline => %{
		<% @content_header_caption = "'view item_pack_product'"%> 

		<%= view_item_pack_product(@item_pack_product,"edit_retail_item_setup")%>

	}, :layout => 'content'
    
 end

def view_retail_item_setup
  render :inline => %{
		<% @content_header_caption = "'view retail_item_setup'"%> 

		<%= view_retail_item_setup(@retail_item_setup)%>

		}, :layout => 'content'
end

def edit_retail_item_setup

    session[:current_prod_schedule].reload
    session[:current_carton_setup].reload
    
    @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed")
    
    if @is_view == false
      @is_view = !authorise(program_name?,'carton_setup',session[:user_id])
    end
    
	 @retail_item_setup = session[:current_carton_setup].retail_item_setup
	 if @is_view == false
		render_edit_retail_item_setup
     else
        view_retail_item_setup
	 end
end

def render_edit_retail_item_setup
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit retail_item_setup'"%> 

		<%= build_retail_item_setup_form(@retail_item_setup,'update_retail_item_setup','save',true,@is_create_retry)%>

		}, :layout => 'content'
end
 
def update_retail_item_setup
	
	 #-----------------------------------------------------------------------
	 # -> If retail_item_setup exists, update it, else create new and set ref
	 #    to carton_setup
	 # -> navigate back to carton setup form
	 #-----------------------------------------------------------------------
  # begin 
	 id = params[:retail_item_setup][:id]
	 if session[:current_carton_setup].retail_item_setup
	      
	      @retail_item_setup = session[:current_carton_setup].retail_item_setup
		  if session[:current_carton_setup].retail_item_setup.update_attributes(params[:retail_item_setup]) == false
		     render_edit_retail_item_setup
		     return
		  end
		  flash[:notice] = "retail item setup updated"
	 else
	     
		  @retail_item_setup = RetailItemSetup.new(params[:retail_item_setup])
		  
		  @retail_item_setup.production_schedule_code = session[:current_prod_schedule].production_schedule_name
		  @retail_item_setup.carton_setup_id = session[:current_carton_setup].id
		  #@retail_item_setup.carton_setup = session[:current_carton_setup]
		  #session[:current_carton_setup].retail_item_setup = @retail_item_setup
		   #BUGGER
		  #session[:current_carton_setup].retail_item_setup = @retail_item_setup
		  
		  if @retail_item_setup.save == true
		  
		    flash[:notice] = "retail item created"
		    #session[:current_carton_setup].retail_item_setup = @retail_item_setup
		    
		    #session[:current_carton_setup].save
		  else
		    puts "retry"
		    @is_create_retry = true
		    render_edit_retail_item_setup
		    return
		  end
	 end
	 @carton_setup = session[:current_carton_setup]
     render_edit_carton_setup
   # rescue
    #  handle_error("Retail item setup could not be updated")
   # end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: pack_material_product_id
#	---------------------------------------------------------------------------------
def retail_item_setup_pack_material_type_code_changed
	pack_material_type_code = get_selected_combo_value(params)
	session[:retail_item_setup_form][:pack_material_type_code_combo_selection] = pack_material_type_code
	@pack_material_product_codes = Product.find_all_by_product_type_code_and_product_subtype_code("PACK_MATERIAL",pack_material_type_code).map {|p|p.product_code}
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('retail_item_setup','pack_material_product_code',@pack_material_product_codes)%>

		}

end

def retail_item_setup_handling_product_changed

    handling_product_code = get_selected_combo_value(params)
	
	product = HandlingProduct.find_by_handling_product_code(handling_product_code)
	@message = ""
	@message = product.handling_message if product
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
	<%= @message %>

	}

end

#=====================
#PALLET CRITERIA CODE
#=====================
def get_existing_palletizing_criteria_setup
    #--------------------------------------------------------------------------
    #try to find an existing record, if not found create a new one by copying
    #the values from pallet_criteria_setup (setup for entire schedule)
    #--------------------------------------------------------------------------
  begin 
    criteria =  PalletizingCriterium.find_by_carton_setup_id(session[:current_carton_setup].id)
    if !criteria
      criteria = PalletizingCriterium.new
      schedule_criteria = PalletCriterium.find_by_production_schedule_id(session[:current_prod_schedule].id)
      schedule_criteria.export_attributes(criteria)
      criteria.carton_setup = session[:current_carton_setup]
      criteria.create
    end
    
    return criteria
   rescue
     raise "Palletizing criteria could not be fetched for the carton setup. Reported exception: " + $!
   
   end
end


def palletizing_criteria_setup
  
  session[:current_prod_schedule].reload
    @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed")
    
  if @is_view == false
    @is_view = !authorise(program_name?,'carton_setup',session[:user_id])
  end
  
  @palletizing_criteria_setup = get_existing_palletizing_criteria_setup
  
  
    render_edit_palletizing_criteria

end
 
 
def render_edit_palletizing_criteria

    @caption_action = " view"
    @caption_action = "edit " if !@is_view
    
	render :inline => %{
		<% @content_header_caption = "'" + @caption_action + " pallet setup criteria  for carton setup: " + session[:current_carton_setup].carton_setup_code + "'"%> 

		<%= build_palletizing_criterium_form(@palletizing_criteria_setup,'update_palletizing_criteria','update_palletizing_criteria',true,false,@is_view)%>

		}, :layout => 'content'
end
 
def update_palletizing_criteria
	
  begin
	 id = params[:palletizing_criteria_setup][:id]
	 puts "pc id: " + id.to_s
	 if id && @palletizing_criterium = PalletizingCriterium.find(id)
		 if @palletizing_criterium.update_attributes(params[:palletizing_criteria_setup])
			 flash[:notice] = "palletizing criteria updated successfully"
			 @carton_setup = session[:current_carton_setup]
             render_edit_carton_setup

		 end
	 end
	rescue
	  handle_error("palletizing criteria could not be updated for carton setup")
	end
 end


#==================================
#RETAIL UNIT SETUP CONTROLLER CODE
#==================================


 def view_unit_pack_product
    
    @unit_pack_product = session[:current_carton_setup].retail_unit_setup.unit_pack_product
    render :inline => %{
		<% @content_header_caption = "'view unit_pack_product'"%> 

		<%= view_unit_pack_product(@unit_pack_product,"edit_retail_unit_setup")%>

	}, :layout => 'content'
    


 end
 
def view_retail_unit_setup
  render :inline => %{
		<% @content_header_caption = "'view retail_unit_setup'"%> 

		<%= view_retail_unit_setup(@retail_unit_setup)%>

		}, :layout => 'content'
end

def edit_retail_unit_setup

    session[:current_prod_schedule].reload
    session[:current_carton_setup].reload
    
    @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed")
    
    if @is_view == false
      @is_view = !authorise(program_name?,'carton_setup',session[:user_id])
    end
    
	 @retail_unit_setup = session[:current_carton_setup].retail_unit_setup
	 if @is_view == false
		render_edit_retail_unit_setup
     else
        view_retail_unit_setup
	 end
end

def render_edit_retail_unit_setup
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit retail_unit_setup'"%> 

		<%= build_retail_unit_setup_form(@retail_unit_setup,'update_retail_unit_setup','save',true)%>

		}, :layout => 'content'
end
 
def update_retail_unit_setup
	
	 #-----------------------------------------------------------------------
	 # -> If retail_item_setup exists, update it, else create new and set ref
	 #    to carton_setup
	 # -> navigate back to carton setup form
	 #-----------------------------------------------------------------------
   begin 
	 id = params[:retail_unit_setup][:id]
	 if session[:current_carton_setup].retail_unit_setup
	      
	      @retail_unit_setup = session[:current_carton_setup].retail_unit_setup
		  if session[:current_carton_setup].retail_unit_setup.update_attributes(params[:retail_unit_setup]) == false
		     puts "invalid"
		     render_edit_retail_unit_setup
		     return
		  end
		  flash[:notice] = "retail unit setup updated"
	 else
		  @retail_unit_setup = RetailUnitSetup.new(params[:retail_unit_setup])
		  @retail_unit_setup.production_schedule_code = session[:current_prod_schedule].production_schedule_name
		  #@retail_unit_setup.carton_setup = session[:current_carton_setup]
		  #session[:current_carton_setup].retail_unit_setup = @retail_unit_setup
		  @retail_unit_setup.carton_setup_id = session[:current_carton_setup].id
		  if @retail_unit_setup.save == true
		    flash[:notice] = "retail unit created"
		    #session[:current_carton_setup].retail_unit_setup = @retail_unit_setup
		    #session[:current_carton_setup].save
		  else
		    puts "retry"
		    @is_create_retry = true
		    render_edit_retail_unit_setup
		    return
		  end
	 end
	 @carton_setup = session[:current_carton_setup]
     render_edit_carton_setup
    rescue
      handle_error("Retail unit setup could not be updated")
    end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: pack_material_product_id
#	---------------------------------------------------------------------------------
def retail_unit_setup_pack_material_type_code_changed
	pack_material_type_code = get_selected_combo_value(params)
	session[:retail_unit_setup_form][:pack_material_type_code_combo_selection] = pack_material_type_code
	@pack_material_product_codes = Product.find_all_by_product_type_code_and_product_subtype_code("PACK_MATERIAL",pack_material_type_code).map {|p|p.product_code}
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('retail_unit_setup','pack_material_product_code',@pack_material_product_codes)%>

		}

end

def retail_unit_setup_handling_product_changed

    handling_product_code = get_selected_combo_value(params)
	
	product = HandlingProduct.find_by_handling_product_code(handling_product_code)
	@message = ""
	@message = product.handling_message if product
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
	<%= @message %>

	}

end

def retail_item_setup_basic_pack_changed
   basic_pack = get_selected_combo_value(params)

   carton_setup = session[:current_carton_setup]
   std_count  = StandardSizeCount.find_by_standard_size_count_value_and_commodity_code_and_basic_pack_code(carton_setup.standard_size_count_value,carton_setup.commodity_code,basic_pack)
   if std_count
     @actual_count = std_count.actual_count.to_s
   else
     @actual_count = "NOT FOUND!"
   end
   render :inline => %{
	<%= @actual_count %>

	}

end

#==================================
#TRADE UNIT SETUP CONTROLLER CODE
#==================================
def view_carton_pack_product
    

    


 end

 def view_carton_pack_product
    
    @carton_pack_product = session[:current_carton_setup].trade_unit_setup.carton_pack_product
    render :inline => %{
		<% @content_header_caption = "'view carton_pack_product'"%> 

		<%= view_carton_pack_product(@carton_pack_product,"edit_trade_unit_setup")%>

	}, :layout => 'content'
    


 end

def view_trade_unit_setup
  render :inline => %{
		<% @content_header_caption = "'view trade_unit_setup'"%> 

		<%= view_trade_unit_setup(@trade_unit_setup)%>

		}, :layout => 'content'
end

def edit_trade_unit_setup

    session[:current_prod_schedule].reload
    session[:current_carton_setup].reload
    
    @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed")
    
    if @is_view == false
      @is_view = !authorise(program_name?,'carton_setup',session[:user_id])
    end
    
	 @trade_unit_setup = session[:current_carton_setup].trade_unit_setup
	 if @is_view == false
		render_edit_trade_unit_setup
     else
        view_trade_unit_setup
	 end
end

def render_edit_trade_unit_setup
#	 render (inline) the edit template
  @info = "<strong> The default value of carton fruit mass is calculated as follows: </strong>"
  @info += "<br><font color = brown><strong> IF </strong>you specified values for 'items_per_unit' and 'units_per_carton' (at 'retail_unit_setup'), then <br> "
  @info += " the mass(indicated by field 'calculated fruit mass') is calculated as : standard_count avg weight(i.e. fruit weight) X items per unit X units_per_carton<br>"	
  @info += "<strong> ELSE </strong>(IF you did not provide values for both 'items_per_unit' and 'units_per_carton'), then 'calculated_fruit_mass' = nett mass of carton_pack_product"

	render :inline => %{
		<% @content_header_caption = "'edit trade_unit_setup'"%> 

		<%= build_trade_unit_setup_form(@trade_unit_setup,'update_trade_unit_setup','save',true)%>

		}, :layout => 'content'
end
 
def update_trade_unit_setup
	
	 #-----------------------------------------------------------------------
	 # -> If retail_item_setup exists, update it, else create new and set ref
	 #    to carton_setup
	 # -> navigate back to carton setup form
	 #-----------------------------------------------------------------------
  # begin 
	 id = params[:trade_unit_setup][:id]
	 if session[:current_carton_setup].trade_unit_setup
	      
	      @trade_unit_setup = session[:current_carton_setup].trade_unit_setup
		  if session[:current_carton_setup].trade_unit_setup.update_attributes(params[:trade_unit_setup]) == false
		     puts "invalid"
		     render_edit_trade_unit_setup
		     return
		  end
		  flash[:notice] = "trade unit setup updated"
	 else
		  @trade_unit_setup = TradeUnitSetup.new(params[:trade_unit_setup])
		  @trade_unit_setup.production_schedule_code = session[:current_prod_schedule].production_schedule_name
		  #@trade_unit_setup.carton_setup = session[:current_carton_setup]
		  #session[:current_carton_setup].trade_unit_setup = @trade_unit_setup
		  @trade_unit_setup.carton_setup_id = session[:current_carton_setup].id
		  if @trade_unit_setup.save == true
		    flash[:notice] = "trade unit created"
		    #session[:current_carton_setup].trade_unit_setup = @trade_unit_setup
		    #session[:current_carton_setup].save
		  else
		    puts "retry"
		    @is_create_retry = true
		    render_edit_trade_unit_setup
		    return
		  end
	 end
	 @carton_setup = session[:current_carton_setup]
     render_edit_carton_setup
   # rescue
    #  handle_error("Trade unit setup could not be updated")
   # end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: pack_material_product_id
#	---------------------------------------------------------------------------------
def trade_unit_setup_pack_material_type_code_changed
	pack_material_type_code = get_selected_combo_value(params)
	
	@pack_material_product_codes = Product.find_all_by_product_type_code_and_product_subtype_code("PACK_MATERIAL",pack_material_type_code).map {|p|p.product_code}
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('trade_unit_setup','pack_material_product_code',@pack_material_product_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_trade_unit_setup_pack_material_product_code'/>
		<%= observe_field('trade_unit_setup_pack_material_product_code',:update => 'old_pack_code_cell',:url => {:action => session[:trade_unit_setup_form][:pack_material_product_code_observer][:remote_method]},:loading => "show_element('img_trade_unit_setup_pack_material_product_code');",:complete => session[:trade_unit_setup_form][:pack_material_product_code_observer][:on_completed_js])%>
		
		}

end

def trade_unit_setup_pack_material_product_code_changed
  puts "called!"
  pack_material_product_code = get_selected_combo_value(params)
  @old_packs = OldPack.find_by_sql('select distinct old_pack_code from old_packs').map{|g|[g.old_pack_code]}
  @old_packs.unshift("<empty>")
  prod  = PackMaterialProduct.find_by_pack_material_product_code(pack_material_product_code)
  old_pack = nil
  old_pack = prod.old_pack_code if prod
  @trade_unit_setup = TradeUnitSetup.new
  @trade_unit_setup.old_pack_code = old_pack if old_pack
  render :inline => %{
  <%= select('trade_unit_setup','old_pack_code',@old_packs)%>
  }
  
end


def trade_unit_setup_handling_product_changed

    handling_product_code = get_selected_combo_value(params)
	
	product = HandlingProduct.find_by_handling_product_code(handling_product_code)
	@message = ""
	@message = product.handling_message if product
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
	<%= @message %>

	}

end


def trade_unit_setup_cpc_changed
    #-------------------------------------------------------------------------------------------------------------
    #calculate carton mass as follows:
    #trade_unit nett mass default is: cpc nett mass, but if retail_unit has mass,
    #then trade unit nett mass = standard_count avg weight(i.e. fruit weight) * items per unit * units_per_carton
    #-------------------------------------------------------------------------------------------------------------
    product_code = get_selected_combo_value(params)
	
	carton_pack_product = CartonPackProduct.find_by_carton_pack_product_code(product_code)
	@carton_fruit_mass = carton_pack_product.nett_mass
	fruit_mass = StandardCount.find_by_standard_count_value(session[:current_carton_setup].standard_size_count_value).average_weight_gm.to_f
	puts fruit_mass.to_s
	
	if fruit_mass && fruit_mass > 0
	  fruit_mass = fruit_mass/1000
      
    end
    
	if fruit_mass && fruit_mass > 0  && session[:current_carton_setup].retail_unit_setup.units_per_carton && session[:current_carton_setup].retail_unit_setup.units_per_carton > 0 && session[:current_carton_setup].retail_unit_setup.items_per_unit && session[:current_carton_setup].retail_unit_setup.items_per_unit > 0 
	  
	  @carton_fruit_mass = fruit_mass * session[:current_carton_setup].retail_unit_setup.units_per_carton * session[:current_carton_setup].retail_unit_setup.items_per_unit
	  
	end
	
	#@carton_fruit_mass = Float.round_float(2,@carton_fruit_mass) if @carton_fruit_mass && @carton_fruit_mass > 0
	
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
	<%= @carton_fruit_mass.to_s %>

	}

end

#=========================
#FG SETUP CONTROLLER CODE
#=========================
 def view_fg_product
    
    @fg_product = session[:current_carton_setup].fg_setup.fg_product
    render :inline => %{
		<% @content_header_caption = "'view fg_product'"%> 

		<%= view_fg_product(@fg_product,"edit_fg_setup")%>

	}, :layout => 'content'
    


 end


def view_fg_setup
  render :inline => %{
		<% @content_header_caption = "'view fg_setup'"%> 

		<%= view_fg_setup(@fg_setup)%>

		}, :layout => 'content'
end

def edit_fg_setup
    
    session[:current_carton_setup].reload
    
    session[:current_prod_schedule].reload
    @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed")
    
    if @is_view == false
      @is_view = !authorise(program_name?,'carton_setup',session[:user_id])
    end
     
	 @fg_setup = session[:current_carton_setup].fg_setup
	 
	 if @is_view == false
		render_edit_fg_setup
     else
        view_fg_setup
	 end
end

def render_edit_fg_setup
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit fg_setup'"%> 

		<%= build_fg_setup_form(@fg_setup,'update_fg_setup','save',true)%>

		}, :layout => 'content'
end
 


def save_fg_background
  begin 
	 
	  session[:fg_setup].save
	  
    rescue
      handle_error("fg setup could not be updated")
    end


end




def update_fg_setup
	
   begin 
    
	 id = params[:fg_setup][:id]
	 if session[:current_carton_setup].fg_setup
	      
	      @fg_setup = session[:current_carton_setup].fg_setup
	    
		  if session[:current_carton_setup].fg_setup.update_attributes(params[:fg_setup]) == false
		    puts "invalid"
		     render_edit_fg_setup
		     return
		     
		  end
          
          
		  puts "fg updated"
		  flash[:notice] = "fg setup updated"
#		  task = {:task_type => "create_carton_templates_and_labels",:fg_setup_id => session[:current_carton_setup].fg_setup.id}
#		  TasksThread.get_mutex.synchronize {
#		  TasksThread.get_tasks_queue.push task}
#		  TasksThread.Process_tasks_queue
          
	 else
		  @fg_setup = FgSetup.new(params[:fg_setup])
		  @fg_setup.production_schedule_code = session[:current_prod_schedule].production_schedule_name
		  #@fg_setup.carton_setup = session[:current_carton_setup]
		  #session[:current_carton_setup].fg_setup = @fg_setup
		  @fg_setup.carton_setup_id = session[:current_carton_setup].id
		  if @fg_setup.save == true
		    flash[:notice] = "fg setup created"
		    #session[:current_carton_setup].fg_setup = @fg_setup
		    
#		     task = {:task_type => "create_carton_templates_and_labels",:fg_setup_id => session[:current_carton_setup].fg_setup.id}
#		     TasksThread.get_mutex.synchronize {
#		     TasksThread.get_tasks_queue.push task }
#		      TasksThread.Process_tasks_queue
             
		  else
		    
		    @is_create_retry = true
		    render_edit_fg_setup
		    return
		  end
	 end
	 @carton_setup = session[:current_carton_setup]
     render_edit_carton_setup
    rescue
      handle_error("fg setup could not be updated")
    end
 end

#=============================
#PALLET SETUP CONTROLLER CODE
#=============================

 def view_pallet_format_product
    
    @pallet_format_product = session[:current_carton_setup].pallet_setup.pallet_format_product
    render :inline => %{
		<% @content_header_caption = "'view pallet_format_product'"%> 

		<%= view_pallet_format_product(@pallet_format_product,"edit_pallet_setup")%>

	}, :layout => 'content'
    


 end

def view_pallet_setup
  render :inline => %{
		<% @content_header_caption = "'view pallet_setup'"%> 

		<%= view_pallet_setup(@pallet_setup)%>

		}, :layout => 'content'
end

def edit_pallet_setup

    session[:current_prod_schedule].reload
    session[:current_carton_setup].reload
    @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed")
    
    if @is_view == false
      @is_view = !authorise(program_name?,'carton_setup',session[:user_id])
    end
    
	 @pallet_setup = session[:current_carton_setup].pallet_setup
	 if @is_view == false
		render_edit_pallet_setup
     else
        view_pallet_setup
	 end
end

def render_edit_pallet_setup
#	 render (inline) the edit template
   @info = "<font color = 'red'><strong>On field 'no_of_cartons': </strong></font><br>"
   @info += "'Number of cartons' is the preset amount of cartons for the selected <font color = 'red'>'pallet_format_product_code' </font><br>"
   @info += " and the selected <font color = 'red'>'carton_pack_product_code'- which was set at 'trade_unit_setup' </font> <br>"
   @info += " IF none of the values from dropdown field 'pallet_format_product' populate field 'no_of_cartons' it means that <br>"
   @info += " a 'cpp' (cartons_per_pallet) record have not been created to set the amount of cartons (for cartons_pack_product) for the pallet (pallet_format_product)<br>"
   @info += " To solve, this problem, you must go to tab: 'products' (also under 'production') and sub-tab 'cpp'. Then select 'new' menu item to <br>"
   @info += " create a 'cartons_per_pallet' record. (You may be denied access in which case you must request access from IT)"

	render :inline => %{
		<% @content_header_caption = "'edit pallet_setup'"%> 

		<%= build_pallet_setup_form(@pallet_setup,'update_pallet_setup','save',true)%>

		}, :layout => 'content'
end
 
def update_pallet_setup
	
	 #-----------------------------------------------------------------------
	 # -> If retail_item_setup exists, update it, else create new and set ref
	 #    to carton_setup
	 # -> navigate back to carton setup form
	 #-----------------------------------------------------------------------
   begin 
	 id = params[:pallet_setup][:id]
	 if session[:current_carton_setup].pallet_setup
	      
	      @pallet_setup = session[:current_carton_setup].pallet_setup
		  if session[:current_carton_setup].pallet_setup.update_attributes(params[:pallet_setup]) == false
		    
		     render_edit_pallet_setup
		     return
		  end
		  flash[:notice] = "pallet setup updated"
	 else
		  @pallet_setup = PalletSetup.new(params[:pallet_setup])
		  @pallet_setup.production_schedule_code = session[:current_prod_schedule].production_schedule_name
		  #@pallet_setup.carton_setup = session[:current_carton_setup]
		  #session[:current_carton_setup].pallet_setup = @pallet_setup
		  @pallet_setup.carton_setup_id = session[:current_carton_setup].id
		  if @pallet_setup.save == true
		    flash[:notice] = "pallet setup created"

		  else
		    puts "retry"
		    @is_create_retry = true
		 
		    render_edit_pallet_setup
		    return
		  end
	 end
	 @carton_setup = session[:current_carton_setup]
     render_edit_carton_setup
    rescue
      handle_error("Pallet setup could not be updated")
    end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: pack_material_product_id
#	---------------------------------------------------------------------------------
def pallet_setup_pack_material_type_code_changed
	pack_material_type_code = get_selected_combo_value(params)
	session[:pallet_setup_form][:pack_material_type_code_combo_selection] = pack_material_type_code
	@pack_material_product_codes = Product.find_all_by_product_type_code_and_product_subtype_code("PACK_MATERIAL",pack_material_type_code).map {|p|p.product_code}
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('pallet_setup','pack_material_product_code',@pack_material_product_codes)%>

		}

end

#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for pallet format product combo
#	---------------------------------------------------------------------------------
def pallet_setup_pallet_format_product_code_changed
	pallet_format_product_code = get_selected_combo_value(params)
	pallet_setup = session[:current_carton_setup].pallet_setup
	@num_cartons_list = PalletFormatProduct.cartons_per_pallet_codes(session[:current_carton_setup].trade_unit_setup.carton_pack_product_code,pallet_format_product_code)
	
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('pallet_setup','no_of_cartons',@num_cartons_list)%>

		}

end

def pallet_setup_handling_product_changed

    handling_product_code = get_selected_combo_value(params)
	
	product = HandlingProduct.find_by_handling_product_code(handling_product_code)
	@message = ""
	@message = product.handling_message if product
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
	<%= @message %>

	}

end



  def active_carton_setups
  begin
	return if authorise_for_web('carton_setup','read') == false


	is_view = nil
    if session[:current_prod_schedule]== nil
      msg = "You must first select or set a 'current' production schedule from the 'production schedules' tab"
      @freeze_flash = true
      redirect_to_index(msg)
      return
    end

    @current_prod_schedule = session[:current_prod_schedule].production_schedule_name
	  query = "@carton_setups = CartonSetup.find_all_by_production_schedule_code_and_active(session[:current_prod_schedule].production_schedule_name ,true,
				 :include => [:retail_item_setup,:retail_unit_setup,:trade_unit_setup,:fg_setup,:pallet_setup],:order => 'carton_setups.color_percentage,carton_setups.standard_size_count_value') "

   session[:query] = query
   eval  query

	render_list_active_carton_setups
  rescue
   handle_error("Carton setups could not be listed")
  end
end


def list_carton_setups
  begin
	return if authorise_for_web('carton_setup','read') == false 

 	if params[:page]!= nil 

 		session[:carton_setups_page] = params['page']

		 render_list_carton_setups

		 return 
	else
		session[:carton_setups_page] = nil
	end

	is_view = nil
    if session[:current_prod_schedule]== nil
      msg = "You must first select or set a 'current' production schedule from the 'production schedules' tab"
      @freeze_flash = true
      redirect_to_index(msg)
      return
    end
    
    @current_prod_schedule = session[:current_prod_schedule].production_schedule_name 
	list_query = "@carton_setup_pages = Paginator.new self, CartonSetup.count(\"production_schedule_code = '#{session[:current_prod_schedule].production_schedule_name}'\"), @@page_size,@current_page
	 @carton_setups = CartonSetup.find_all_by_production_schedule_code(session[:current_prod_schedule].production_schedule_name , 
				 :include => [:retail_item_setup,:retail_unit_setup,:trade_unit_setup,:fg_setup,:pallet_setup],
				 :limit => @carton_setup_pages.items_per_page,
				 :order => 'color_percentage,standard_size_count_value,pack_order',
				 :offset => @carton_setup_pages.current.offset)"
	session[:query] = list_query
	puts "before render"
	render_list_carton_setups
  rescue
   handle_error("Carton setups could not be listed")
  end
end


  def render_list_active_carton_setups

	session[:current_prod_schedule].reload
    @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed"||session[:current_prod_schedule].production_schedule_status_code == "completed")
    if !@is_view

      @is_view = !authorise(program_name?,'carton_setup',session[:user_id])
    end


   @current_prod_schedule = session[:current_prod_schedule].production_schedule_name
	 @can_edit = !@is_view
	 @can_delete = !@is_view

	 session["custom_export_columns"] = [["color_percentage","color"],["standard_size_count_value","cnt"],"pack_order",["order_number","order_no"],["qty_required","order_qty_req"],["qty_produced","order_qty_produced"],["vr_tm","tm"],["vr_inv","inv"],["vr_extended_fg_code","extended_fg_code"],["vr_old_fg","old_fg_code"],["vr_marking","marking"],["vr_dia","dia"],["vr_palletizing","palletizing"],["vr_all_remarks","all_remarks"],"carton_setup_code"]

      render :inline => %{
      <% grid            = build_carton_setup_grid(@carton_setups,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of active carton_setups for schedule: #{@current_prod_schedule}' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end


def render_list_carton_setups
	
	session[:current_prod_schedule].reload
    @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed"||session[:current_prod_schedule].production_schedule_status_code == "completed")
    if !@is_view
      
      @is_view = !authorise(program_name?,'carton_setup',session[:user_id])
    end
     
     
   @current_prod_schedule = session[:current_prod_schedule].production_schedule_name
	 @can_edit = !@is_view
	 @can_delete = !@is_view
     
	 @current_page = session[:carton_setups_page] if session[:carton_setups_page]
	 @current_page = params['page'] if params['page']
	 
	 
	 @carton_setups =  eval(session[:query]) if !@carton_setups
	 session["custom_export_columns"] = [["color_percentage","color"],["standard_size_count_value","cnt"],"pack_order",["order_number","order_no"],["qty_required","order_qty_req"],["qty_produced","order_qty_produced"],["vr_tm","tm"],["vr_inv","inv"],["vr_extended_fg_code","extended_fg_code"],["vr_old_fg","old_fg_code"],["vr_marking","marking"],["vr_dia","dia"],["vr_palletizing","palletizing"],["vr_all_remarks","all_remarks"],"carton_setup_code"]
   session[:carton_setups]=@carton_setups
  if !@is_view
    carton_setups_hash=Hash.new
      @grid_selected_rows = Array.new()
         for carton in @carton_setups
            if carton.active == true
              @grid_selected_rows.push(carton)
            end
           carton_setups_hash[carton.id]=carton.active
         end     
      session[:carton_setups_hash]=carton_setups_hash
      @multi_select = true
  end

    render :inline => %{
      <% grid            = build_carton_setup_grid(@carton_setups,@can_edit,@can_delete,@multi_select) %>
      <% grid.caption    = 'list of carton_setups for schedule: #{@current_prod_schedule}' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@carton_setup_pages) if @carton_setup_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
 
def delete_carton_setup
  begin
	return if authorise_for_web('carton_setup','carton_setup')== false
	if params[:page]
		session[:carton_setups_page] = params['page']
		render_list_carton_setups
		return
	end
	id = params[:id]
	if id && carton_setup = CartonSetup.find(id)
	    color_perc = carton_setup.color_percentage
	    org = carton_setup.org
	    grade_code = carton_setup.grade_code
	    std_count = carton_setup.standard_size_count_value
	    ActiveRecord::Base.transaction do
		  carton_setup.destroy
		  #resequence grain group
		  CartonSetup.re_sequence_group(session[:current_prod_schedule].production_schedule_name,color_perc,grade_code,std_count,org)
		end
		session[:alert] = " Record deleted."
		render_list_carton_setups
	end
  rescue
   handle_error("carton setup could not be deleted")
  end
end
 
def new_carton_setup
	return if authorise_for_web('carton_setup','create')== false
		render_new_carton_setup
end
 
def create_carton_setup
	 @carton_setup = CartonSetup.new(params[:carton_setup])
	 if @carton_setup.save
         @carton_setup.update_time
		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_carton_setup
	 end
end

def render_new_carton_setup
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new carton_setup'"%> 

		<%= build_carton_setup_form(@carton_setup,'create_carton_setup','create_carton_setup',false,@is_create_retry)%>

		}, :layout => 'content'
end

def view_paging_handler

  if params[:page]
	session[:carton_setups_page] = params['page']
  end
  render_list_carton_setups
  
end

def view_carton_setup
  @carton_setup = nil
  id = params[:id]
  if id
    @carton_setup = CartonSetup.find(id)
  else
    @carton_setup = session[:current_carton_setup]
  end
  
  session[:current_carton_setup] = @carton_setup
  
  render :inline => %{
  <% @content_header_caption = "'view carton_setup'"%> 

  <%= view_carton_setup(@carton_setup)%>

 }, :layout => 'content'

end

def edit_carton_setup
	return if authorise_for_web('carton_setup','carton_setup')==false 
	 id = params[:id]
	 if id && @carton_setup = CartonSetup.find(id)
	    session[:current_carton_setup] = @carton_setup
		render_edit_carton_setup

	 end
end


def active_setup
  
  if !session[:current_carton_setup]||!CartonSetup.find_by_id(session[:current_carton_setup].id)
       
      redirect_to_index("You have not activated(selected) a carton setup yet")
    
    return
  end
  
  #session[:current_prod_schedule].reload
  @is_view = (session[:current_prod_schedule].production_schedule_status_code == "closed")
    
    if @is_view == false
      @is_view = !authorise(program_name?,'carton_setup',session[:user_id])
    end
  
  
  @carton_setup = session[:current_carton_setup].reload
 
  
  if @is_view
     render :inline => %{
     <% @content_header_caption = "'view carton_setup'"%> 

      <%= view_carton_setup(@carton_setup)%>

      }, :layout => 'content'
  else
    render_edit_carton_setup
  end
 #}
  

end

def render_edit_carton_setup
#	 render (inline) the edit template
    session[:current_carton_setup].reload
    @info = "<strong>If you change 'org'</strong>, you will have to redefine: <br> 1) entire fg_setup <br> 2) mark_codes of retail_item,retail unit and trade_unit "
    @info += "<br><br> <strong>If you change 'grade'</strong>, you must update 'retail_item_setup' to recalculate the 'item_pack_product' and <br>"
    @info += " you must update fg_setup, since it references the 'item_pack_product' of 'retail_item_setup'"               
	
	if  session[:current_prod_schedule].production_schedule_status_code == "re_opened"
	 @info = "<font color = 'red'><strong> Remember to complete 'fg_setup' to complete any carton_setup </strong></font>"
	end
	render :inline => %{
		<% @content_header_caption = "'edit carton_setup'"%> 

		<%= build_carton_setup_form(@carton_setup,'update_carton_setup','update_carton_setup',true)%>

		}, :layout => 'content'
end
 
def clone_carton_setup_to_count_submit
 
 if params[:page]
		session[:carton_setups_page] = params['page']
		render_list_carton_setups
		return
	end

 @current_page = session[:carton_setups_page]
   
 #------------------------------------------------------------------------------------------------
 # Two types of cloning is possible:
 # 1) Cloning to an existing carton_setup- if user selected an existing setup as target of clone
 # 2) Cloning to a new carton-setup - if user selected '<no existing carton setup>'
 #------------------------------------------------------------------------------------------------
 if params[:carton_setup][:standard_size_count_value]== ""
   render_list_carton_setups
   return
 end
 
 if params[:carton_setup][:carton_setup_code]== "<no existing carton setup>"||params[:carton_setup][:carton_setup_code].index("select")
   session[:clone_to_count_source].clone_setup_to_count(session[:selected_clone_count_target])
 else
   session[:clone_to_count_source].clone_setup_to_count(session[:selected_clone_count_target],params[:carton_setup][:carton_setup_code],session[:current_prod_schedule])
 end
 
   session[:clone_to_count_source] = nil
   session[:selected_clone_count_target] = nil
   flash[:notice]= "Carton setup cloned successfully"
   render_list_carton_setups
   return
  
 
end


def clone_carton_setup_to_count

  @carton_setup = CartonSetup.find(params[:id])
  session[:clone_to_count_source]= @carton_setup
  @info = "Remember 'clone_to_count' here means: <br><strong> CLONE FROM THE CLICKED ON CARTON SETUP(" + @carton_setup.carton_setup_code + ") <BR> TO THE COUNT THAT YOU SELECT FROM DROPDOWN <STRONG>"
  render :inline => %{
		<% @content_header_caption = "'clone carton_setup: " + @carton_setup.carton_setup_code + "   to a count'"%> 

		<%= build_clone_to_count_form(@carton_setup,'clone_carton_setup_to_count_submit','clone to count')%>

		}, :layout => 'content'


end
 
 def clone_to_count_changed
	count = get_selected_combo_value(params).to_i
	session[:selected_clone_count_target]= count
	query = "select * from
           public.carton_setups where (public.carton_setups.standard_size_count_value = '#{count}'
           and public.carton_setups.production_schedule_code = '#{session[:current_prod_schedule].production_schedule_name}')"
           
	@carton_setup_codes = CartonSetup.find_by_sql(query).map {|p|p.carton_setup_code}
	@carton_setup_codes.delete( session[:clone_to_count_source].carton_setup_code)
	@carton_setup_codes.unshift("<no existing carton setup>") if @carton_setup_codes.length == 0
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('carton_setup','carton_setup_code',@carton_setup_codes)%>

		}

end


def clone_carton_setup
  
  if params[:page]
		session[:carton_setups_page] = params['page']
		render_list_carton_setups
		return
	end

   @current_page = session[:carton_setups_page]
   carton_setup = CartonSetup.find(params[:id])
   
   carton_setup.clone_setup
   flash[:notice]= "carton setup cloned"
   list_carton_setups

end

def update_carton_setup
	if params[:page]
		session[:carton_setups_page] = params['page']
		render_list_carton_setups
		return
	end

	 @current_page = session[:carton_setups_page]
	 id = params[:carton_setup][:id]
	 if id && @carton_setup = CartonSetup.find(id)
		 if @carton_setup.update_attributes(params[:carton_setup])
			@carton_setup.update_time
			session[:current_carton_setup] = @carton_setup
			flash[:notice] = "carton setup updated"
			render_edit_carton_setup #keep unneeded if for moment- normally if- clause statement will redirect to listing, could do so again in future
	 else
			 render_edit_carton_setup

		 end
	 end
 end
 

#---------------------------------------------------------------------------------
#--------------- Luks code for season_order_quantities CRUD ----------------------
#---------------------------------------------------------------------------------
def carton_setup_order_number_look_up_combo_changed
  
   order_number = get_selected_combo_value(params)
   season_order_quantity = SeasonOrderQuantity.find_by_customer_order_number(order_number)
   @quantity_required = season_order_quantity.quantity_required.to_s if season_order_quantity != nil 
   @quantity_produced = season_order_quantity.quantity_produced.to_s if season_order_quantity != nil 

#puts "***********" + @quantity_produced
   render :inline => %{
	           <%= @quantity_required %> 

	           <script>
                 <%= update_element_function(
                   "qty_produced_cell", :action=>:update,
                    :content=> @quantity_produced
                    )%>
           
               </script> 
		        }
end

def list_season_order_quantities
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:season_order_quantities_page] = params['page']

		 render_list_season_order_quantities

		 return 
	else
		session[:season_order_quantities_page] = nil
	end

	list_query = "@season_order_quantity_pages = Paginator.new self, SeasonOrderQuantity.count, @@page_size,@current_page
	 @season_order_quantities = SeasonOrderQuantity.find(:all,
				 :limit => @season_order_quantity_pages.items_per_page,
				 :offset => @season_order_quantity_pages.current.offset)"
	session[:query] = list_query
	render_list_season_order_quantities
end

def render_list_season_order_quantities
	@can_edit = true #authorise(program_name?,'edit',session[:user_id]) #-----Luks
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:season_order_quantities_page] if session[:season_order_quantities_page]
	@current_page = params['page'] if params['page']
	@season_order_quantities =  eval(session[:query]) if !@season_order_quantities
	render :inline => %{
      <% grid            = build_season_order_quantity_grid(@season_order_quantities,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all season_order_quantities' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@season_order_quantity_pages) if @season_order_quantity_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def render_season_order_quantity_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  season_order_quantities'"%> 

		<%= build_season_order_quantity_search_form(nil,'submit_season_order_quantities_search','submit_season_order_quantities_search',@is_flat_search)%>

		}, :layout => 'content'
end

def search_season_order_quantities_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_season_order_quantity_search_form(true)
end

def submit_season_order_quantities_search
	if params['page']
		session[:season_order_quantities_page] =params['page']
	else
		session[:season_order_quantities_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @season_order_quantities = dynamic_search(params[:season_order_quantity] ,'season_order_quantities','SeasonOrderQuantity')
	else
		@season_order_quantities = eval(session[:query])
	end
	if @season_order_quantities.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_season_order_quantity_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_season_order_quantities
		end

	else

		render_list_season_order_quantities
	end
end

 
def delete_season_order_quantity
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:season_order_quantities_page] = params['page']
		render_list_season_order_quantities
		return
	end
	id = params[:id]
	if id && season_order_quantity = SeasonOrderQuantity.find(id)
		season_order_quantity.destroy
		session[:alert] = " Record deleted."
		render_list_season_order_quantities
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_season_order_quantity
	return if authorise_for_web(program_name?,'create')== false
		render_new_season_order_quantity
end
 
def create_season_order_quantity
 begin
	 @season_order_quantity = SeasonOrderQuantity.new(params[:season_order_quantity])
	 @season_order_quantity.quantity_produced = 0
	 if @season_order_quantity.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_season_order_quantity
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_season_order_quantity
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new season_order_quantity'"%> 

		<%= build_season_order_quantity_form(@season_order_quantity,'create_season_order_quantity','create_season_order_quantity',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_season_order_quantity
	#return if authorise_for_web(program_name?,'edit')==false #-----Luks
	@is_view = !authorise(program_name?,'edit',session[:user_id]) #-----Luks
	 id = params[:id]
	 if id && @season_order_quantity = SeasonOrderQuantity.find(id)
		render_edit_season_order_quantity

	 end
end


def render_edit_season_order_quantity
#	 render (inline) the edit template
#-----Luks
	render :inline => %{
		<% @content_header_caption = "'edit season_order_quantity'"%> 

		<%= build_season_order_quantity_form(@season_order_quantity,'update_season_order_quantity','update_season_order_quantity',true,false,@is_view)%>

		}, :layout => 'content'
end
 
def update_season_order_quantity
 begin

	if params[:page]
		session[:season_order_quantities_page] = params['page']
		render_list_season_order_quantities
		return
	end

		@current_page = session[:season_order_quantities_page]
	 id = params[:season_order_quantity][:id]
	 if id && @season_order_quantity = SeasonOrderQuantity.find(id)
		 if @season_order_quantity.update_attributes(params[:season_order_quantity])
			@season_order_quantities = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_season_order_quantities
	 else
			 render_edit_season_order_quantity

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(season_order_quantities)
#	-----------------------------------------------------------------------------------------------------------
def season_order_quantity_season_code_search_combo_changed
	season_code = get_selected_combo_value(params)
	session[:season_order_quantity_search_form][:season_code_combo_selection] = season_code
	@customer_order_numbers = SeasonOrderQuantity.find_by_sql("Select distinct customer_order_number from season_order_quantities where season_code = '#{season_code}'").map{|g|[g.customer_order_number]}
	@customer_order_numbers.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('season_order_quantity','customer_order_number',@customer_order_numbers)%>

		}

end

#---------------------------------------------------------------------------------
#--------------- End Luks code for season_order_quantities CRUD ------------------
#---------------------------------------------------------------------------------


##========================================================
## Luks' code for viewing a label for carton_setup =======
##========================================================
def view_label_for_carton_setup
   id = params[:id]
   @carton_setup = CartonSetup.find(id)
   @carton_label_preview = @carton_setup.fg_setup.get_carton_label_preview
   render :template => "/production/carton_setup/carton_label.rhtml", :layout => 'content'
end
##========================================================
end
