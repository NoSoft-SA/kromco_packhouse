class  Diagnostics::IntegrationController < ApplicationController
  helper "production/runs"
  helper "production/carton_setup"
  helper "products/item_pack_product"
  helper "products/unit_pack_product"
  helper "products/carton_pack_product"
   helper "products/fg_product"
    helper "products/pallet_format_product"
    
    helper "production/rmt_setup"
helper "tools/sizer_template"


require "shift"                   #for some reason the new rails version(1.2.3) cannot cope well with the nested Shiftdetails class when
require "shift_details.rb"        #storing the shift object in session state. Workaround:
                                  #So requiring it here, soemwhow helps the issue
 

 def program_name?
	"diagnostics"
 end

 def bypass_generic_security?
	true
 end

 
 def overview
   @today = Time.now.strftime("%Y-%m-%d")#'2008/01/15'#'2008/04/07'#
   @tomorrow = 1.day.from_now.strftime("%Y-%m-%d")#'2008/01/16'#'2008/04/08'#
   
   
   @missing_flows = Diagnostics.missing_flows(@today,@tomorrow)
   @error_flows = Diagnostics.error_flows(@today,@tomorrow)
   render :template => "diagnostics/integration/overview", :layout => "content"
 end
 
 def problem_flows
   @flow_types = ["all","bin_tipped", "bin_tipped_invalid", "carton_deleted","carton_pallet_ref_change",
                 "carton_reclassified","pallet_carton_count_update","pallet_completed","pallet_deleted",
                 "pallet_new","pallet_rtb","pallet_update","ppecb_inspection","rebin_new","rebin_reclassified",
                 "rw_carton_new"]
   render :template => "diagnostics/integration/problem_flows", :layout => "content" 
 end
 

def list_problem_flows
@type_code = params[:flow_type]
  
#-------------------------------------------------------------------
    list_query = Diagnostics.problem_flows(@type_code)
	session[:query] = list_query
#------------------------------------------------------------------
	render_list_outbox_entries
  
end 

def view_paging_handler
  if params[:page]
	session[:list_outbox_entries] = params['page']
  end
  render_list_outbox_entries
end

def render_list_outbox_entries
    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:outbox_enties_page] if session[:outbox_enties_page]
	@current_page = params['page'] if params['page']
	@outbox_entries =  eval(session[:query]) if !@outbox_entries
	puts @outbox_entries[0].attributes

	render :inline => %{
      <% grid            = build_outbox_enties_grid(@outbox_entries,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of outbox entries' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@outbox_entry_pages) if @outbox_entry_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def view_pallet
  
   begin
     @retrieved_record = Pallet.find(params[:id])
      render :inline => %{
                         <% @content_header_caption = "'view pallet'"%>
                         <%= build_pallet_view(@retrieved_record,'view_paging_handler')%>
                         }, :layout => 'content'
    rescue
      @retrieved_record = Pallet.find(:first,:conditions=> ['pallet_number = ? ', params[:id] ])
      render :inline => %{
                         <% @content_header_caption = "'view pallet'"%>
                         <%= build_pallet_view(@retrieved_record,'view_paging_handler')%>
                         }, :layout => 'content'
    end                     
end

def view_carton
  
    if !session[:current_carton]
    @retrieved_record = Carton.find(params[:id])
    session[:current_carton] = @retrieved_record
    else
      @retrieved_record = session[:current_carton]
    end   
    
    render :inline => %{
                         <% @content_header_caption = "'view carton'"%>
                         <%= build_carton_view(@retrieved_record,'view_paging_handler')%>
                         }, :layout => 'content'         
end

def view_rebin

      if (session[:object_type].fetch(params[:id].to_s) == "Rebin")
        @retrieved_record = Rebin.find(params[:id])
      else
        @retrieved_record = RwReclassedRebin.find(params[:id])
      end 
    
    render :inline => %{
                         <% @content_header_caption = "'view rebin'"%>
                         <%= build_rebin_view(@retrieved_record,'view_paging_handler')%>
                         }, :layout => 'content'                  
end

def view_ppecb_inspection
    @retrieved_record = PpecbInspection.find(params[:id])
     render :inline => %{
                         <% @content_header_caption = "'view ppecb_inspection'"%>
                         <%= build_ppecb_inspection_view(@retrieved_record,'view_paging_handler')%>
                         }, :layout => 'content'  
end

def view_bin

    if (session[:object_type].fetch(params[:id].to_s) == "BinsTipped")
        @retrieved_record = BinsTipped.find(params[:id])
      else
        @retrieved_record = BinsTippedInvalid.find(params[:id])
      end 
    
    render :inline => %{
                         <% @content_header_caption = "'view bin'"%>
                         <%= build_bin_view(@retrieved_record,'view_paging_handler')%>
                         }, :layout => 'content'       
end

def view_record
   id = params[:id]
   entity = session[:object_type].fetch(id.to_s)

   if(entity == "Pallet") 
       view_pallet
   elsif(entity == "Carton")
       view_carton
   elsif(entity == "PalletTemplate")
       view_pallet_template
   elsif(entity == "Rebin" || entity == "RwReclassedRebin")
       view_rebin
   elsif(entity == "PpecbInspection")
       view_ppecb_inspection
   elsif(entity == "RwReclassedCarton")
       view_carton
   elsif(entity == "BinsTipped" || entity == "BinsTippedInvalid")
       view_bin
   else
   end
end

def view_record_hash

  id = params[:id]
   entity = session[:object_type].fetch(id.to_s)

   if(entity == "Pallet") 
       @retrieved_record = Pallet.find(params[:id])
       @record_hash = eval "@retrieved_record.attributes"
       @object_builder = ObjectBuilder.new
       @hash_object = @object_builder.build_hash_object(@record_hash)
       
        render :inline => %{
                        <%@content_header_caption = "'view pallet hash record'"%>
                        <%= build_pallet_view(@hash_object,'view_paging_handler')%>
                         }, :layout => 'content'      
   elsif(entity == "Carton")
      @retrieved_record = Carton.find(params[:id])
       @record_hash = eval "@retrieved_record.attributes"
       @object_builder = ObjectBuilder.new
       @hash_object = @object_builder.build_hash_object(@record_hash)
       
        render :inline => %{
                        <%@content_header_caption = "'view carton hash record'"%>
                        <%= build_carton_view(@hash_object,'view_paging_handler')%>
                         }, :layout => 'content'      
   elsif(entity == "PalletTemplate")
       @retrieved_record = PalletTemplate.find(params[:id])
       @record_hash = eval "@retrieved_record.attributes"
       @object_builder = ObjectBuilder.new
       @hash_object = @object_builder.build_hash_object(@record_hash)
       
        render :inline => %{
                        <%@content_header_caption = "'view carton hash record'"%>
                        <%= build_pallet_template_view(@hash_object,'view_paging_handler')%>
                         }, :layout => 'content'   
   elsif(entity == "PpecbInspection")
       @retrieved_record = PpecbInspection.find(params[:id])
       @record_hash = eval "@retrieved_record.attributes"
       @object_builder = ObjectBuilder.new
       @hash_object = @object_builder.build_hash_object(@record_hash)
       
        render :inline => %{
                        <%@content_header_caption = "'view carton hash record'"%>
                        <%= build_ppecb_inspection_view(@hash_object,'view_paging_handler')%>
                         }, :layout => 'content'   
   elsif(entity == "RwReclassedCarton")
       @retrieved_record = Carton.find(params[:id])
       @record_hash = eval "@retrieved_record.attributes"
       @object_builder = ObjectBuilder.new
       @hash_object = @object_builder.build_hash_object(@record_hash)
       
        render :inline => %{
                        <%@content_header_caption = "'view carton hash record'"%>
                        <%= build_carton_view(@hash_object,'view_paging_handler')%>
                         }, :layout => 'content'   
   elsif(entity == "BinsTipped")
       @retrieved_record = BinsTipped.find(params[:id])
       @record_hash = eval "@retrieved_record.attributes"
       @object_builder = ObjectBuilder.new
       @hash_object = @object_builder.build_hash_object(@record_hash)
       
        render :inline => %{
                        <%@content_header_caption = "'view bins tipped hash record'"%>
                        <%= build_bin_view(@hash_object,'view_paging_handler')%>
                         }, :layout => 'content'   
   elsif(entity == "BinsTippedInvalid")
       @retrieved_record = BinsTippedInvalid.find(params[:id])
       @record_hash = eval "@retrieved_record.attributes"
       @object_builder = ObjectBuilder.new
       @hash_object = @object_builder.build_hash_object(@record_hash)
       
        render :inline => %{
                        <%@content_header_caption = "'view bins tipped hash record'"%>
                        <%= build_bin_view(@hash_object,'view_paging_handler')%>
                         }, :layout => 'content'   
   elsif(entity == "Rebin")
       @retrieved_record = Rebin.find(params[:id])
       @record_hash = eval "@retrieved_record.attributes"
       @object_builder = ObjectBuilder.new
       @hash_object = @object_builder.build_hash_object(@record_hash)
       
        render :inline => %{
                        <%@content_header_caption = "'view bins tipped hash record'"%>
                        <%= build_rebin_view(@hash_object,'view_paging_handler')%>
                         }, :layout => 'content'   
   elsif(entity == "RwReclassedRebin")
        @retrieved_record = RwReclassedRebin.find(params[:id])
       @record_hash = eval "@retrieved_record.attributes"
       @object_builder = ObjectBuilder.new
       @hash_object = @object_builder.build_hash_object(@record_hash)
       
        render :inline => %{
                        <%@content_header_caption = "'view bins tipped hash record'"%>
                        <%= build_rebin_view(@hash_object,'view_paging_handler')%>
                         }, :layout => 'content'   
   else
   end
   
end


def view_pallet_template
  @pallet_template = PalletTemplate.find(params[:id])
  render :inline => %{
                     <% @content_header_caption = "'view pallet template'"%>
                     <%= build_pallet_template_view(@pallet_template)%>
                     }, :layout => 'content'
end
 
def view_run(back_action = nil)
     
     if !back_action
      back_action = session[:run_view_context]if !back_action
     end
     
	 id = params[:id]
	 @back_action = back_action
	 session[:run_view_context]= @back_action
	 
	 if !id
	  @production_run = session[:current_production_run] 
	 else
	   @production_run = ProductionRun.find(id)
	 end
	  
	    session[:current_production_run] = @production_run
	    session[:current_closed_schedule] = session[:current_production_run].production_schedule
	    
	    
		render :inline => %{
		<% @content_header_caption = "'view production_run'"%> 

		<%= build_production_run_view(@production_run,nil,true)%>

		}, :layout => 'content'

end

#.............................................

def view_production_run
  id = params[:id]
  #@production_run = ProductionRun.find_by_production_run_code(id)
  
  if !id
	  @production_run = session[:current_production_run] 
  else
	   @production_run = ProductionRun.find_by_production_run_code(id)
  end
	  
	    session[:current_production_run] = @production_run
    	render :inline => %{
		<% @content_header_caption = "'view production_run'"%> 

		<%= build_production_run_view(@production_run,nil,true)%>

		}, :layout => 'content'
end
#fg
def view_fg_products_side_a_allocation

  list_pack_stations "A",true

end

def view_fg_products_side_b_allocation

  list_pack_stations "B",true

end

def list_pack_stations(side_code = nil,is_view = nil)
  
   session[:current_side]= side_code if side_code
   
   side_code = session[:current_side]if !side_code
   
   line_id = session[:current_production_run].line.id
   session[:pack_stations_page]= 0 if !session[:pack_stations_page]
   
   count = CartonPackStation.count_stations_for_line_and_side(line_id,side_code)
 
#======================================
#KEEP FOR WHEN WE DECIDE TO NEED PAGING
#==================================================================================================================================================================================================================================================
#     query = "\"SELECT
#           public.carton_pack_stations.station_code,carton_pack_stations.id,
#           public.tables.table_code as table,
#           public.carton_drops.carton_drop_code as drop,
#           public.lines.line_code
#           FROM
#           public.lines
#           INNER JOIN public.line_configs ON (public.lines.line_config_id = public.line_configs.id)
#           INNER JOIN public.carton_drops ON (public.line_configs.id = public.carton_drops.line_config_id)
#           INNER JOIN public.tables ON (public.carton_drops.id = public.tables.carton_drop_id)
#           INNER JOIN public.carton_pack_stations ON (public.tables.id = public.carton_pack_stations.table_id)
#           WHERE
#           (public.lines.id = '#{line_id}' and public.carton_drops.carton_drop_side_code = '#{side_code}') order BY carton_drop_code,table_code,station_code LIMIT " + @@page_size.to_s + " OFFSET " + session[:pack_stations_page].to_s + "\""   
#===================================================================================================================================================================================================================================================	 		
 
 
   
   query = "\"SELECT
           public.carton_pack_stations.station_code,carton_pack_stations.id,
           public.tables.table_code as table_code,
           public.drops.drop_code as drop_code,
           public.drops.drop_side_code,
           public.lines.line_code
           FROM
           public.lines
           INNER JOIN public.line_configs ON (public.lines.line_config_id = public.line_configs.id)
           INNER JOIN public.drops ON (public.line_configs.id = public.drops.line_config_id)
           INNER JOIN public.tables ON (public.drops.id = public.tables.drop_id)
           INNER JOIN public.carton_pack_stations ON (public.tables.id = public.carton_pack_stations.table_id)
           WHERE
           (public.lines.id = '#{line_id}') order BY drop_code,table_code,station_code \""   
		
	 @list_query = "@pack_stations = CartonPackStation.find_by_sql(" + query + ")"
	 session[:query]= @list_query
	 #=====================================================================================================	 
#	 @list_query = "@pack_stations_pages = Paginator.new self," + count.to_s + ", @@page_size,@current_page
#	 @pack_stations = CartonPackStation.find_by_sql(" + query + ")"
	#KEEP FOR WHEN WE NEED PAGING HERE=====================================================================
	render_list_pack_stations is_view
   #rescue
    # handle_error("pack stations could not be listed")
   #end

 end
 
 def render_list_pack_stations(is_view = nil)
    
    @outlets = PackGroupOutlet.find(:all,:conditions=> "pack_group_outlets.production_run_id = '#{session[:current_production_run].id}' and pack_group_outlets.size_code is null",
                     :include => "pack_group",:order => "pack_group_outlets.id")
    
    @carton_links = CartonLink.find_all_by_line_code_and_production_run_id(session[:current_production_run].line_code,session[:current_production_run].id)                 
     
    CartonPackStation.set_carton_links(@carton_links)
                     
	@can_edit =  authorise(program_name?,'production_run_setup',session[:user_id])
	@can_edit = false if is_view
	
	CartonPackStation.set_outlets(@outlets)
	CartonPackStation.set_production_run_id(session[:current_production_run].id)
	
	@pack_stations =  eval(@list_query) if !@pack_stations
	session[:current_pack_stations]= @pack_stations
	
	@caption = "'list of pack stations for line: " + session[:current_production_run].line_code +  "(schedule:  run: " + "\"#{session[:current_production_run].production_run_number}\"" + ")'"
	
    render :inline => %{
      <% grid            = build_pack_stations_grid(@pack_stations,@can_edit) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
#rmt
def view_rmt_products_side_a_allocation

 allocate_rmt_products_side_a true
end

def view_rmt_products_side_b_allocation

 allocate_rmt_products_side_b true
end

def allocate_rmt_products_side_a(is_view = nil)
  return if authorise_for_web('runs','production_run_setup') == false 
  
    if params[:page]!= nil 

 		session[:pack_stations_page] = params['page']

	else
		session[:pack_stations_page] = nil
	end

    list_binfill_stations "FRONT", is_view

end

def allocate_rmt_products_side_b(is_view = nil)
  return if authorise_for_web('runs','production_run_setup') == false 
  
    if params[:page]!= nil 

 		session[:pack_stations_page] = params['page']

	else
		session[:pack_stations_page] = nil
	end

    list_binfill_stations "BACK",is_view

end
def list_binfill_stations(side_code = nil,is_view = nil)
  
   session[:current_side]= side_code if side_code
   
   side_code = session[:current_side]if !side_code
   
   line_id = session[:current_production_run].line.id
   session[:pack_stations_page]= 0 if !session[:pack_stations_page]
   
 
#======================================
#KEEP FOR WHEN WE DECIDE TO NEED PAGING
#==================================================================================================================================================================================================================================================
#     query = "\"SELECT
#           public.carton_pack_stations.station_code,carton_pack_stations.id,
#           public.tables.table_code as table,
#           public.carton_drops.carton_drop_code as drop,
#           public.lines.line_code
#           FROM
#           public.lines
#           INNER JOIN public.line_configs ON (public.lines.line_config_id = public.line_configs.id)
#           INNER JOIN public.carton_drops ON (public.line_configs.id = public.carton_drops.line_config_id)
#           INNER JOIN public.tables ON (public.carton_drops.id = public.tables.carton_drop_id)
#           INNER JOIN public.carton_pack_stations ON (public.tables.id = public.carton_pack_stations.table_id)
#           WHERE
#           (public.lines.id = '#{line_id}' and public.carton_drops.carton_drop_side_code = '#{side_code}') order BY carton_drop_code,table_code,station_code LIMIT " + @@page_size.to_s + " OFFSET " + session[:pack_stations_page].to_s + "\""   
#===================================================================================================================================================================================================================================================	 		
 
 
   
   query = "\"SELECT
           public.binfill_stations.binfill_station_code,binfill_stations.id,
           public.drops.drop_code as drop_code,
           public.lines.line_code
           FROM
           public.lines
           INNER JOIN public.line_configs ON (public.lines.line_config_id = public.line_configs.id)
           INNER JOIN public.drops ON (public.line_configs.id = public.drops.line_config_id)
           INNER JOIN public.binfill_stations ON (public.binfill_stations.drop_id = public.drops.id)
           WHERE
           (public.lines.id = '#{line_id}' and public.drops.drop_side_code = '#{side_code}') order BY drop_code,binfill_station_code \""   
		 		 
	 
	 @list_query = "@binfill_stations = BinfillStation.find_by_sql(" + query + ")"
	
	render_list_binfill_stations is_view
   #rescue
    # handle_error("pack stations could not be listed")
   #end

 end
def render_list_binfill_stations(is_view = nil)
    
    
    @outlets = PackGroupOutlet.find(:all,:conditions=> "pack_group_outlets.production_run_id = '#{session[:current_production_run].id}' and pack_group_outlets.size_code is not null",
                     :include => "pack_group",:order => "pack_group_outlets.id")
    
    @rebin_links = RebinLink.find_all_by_line_code_and_production_run_id_and_is_sort_station(session[:current_production_run].line_code,session[:current_production_run].id,false)                 
     
    BinfillStation.set_rebin_links(@rebin_links)
    BinfillStation.set_production_run_id(session[:current_production_run].id)
                     
	@can_edit =  authorise(program_name?,'production_run_setup',session[:user_id])
	@can_edit = false if is_view
	
	BinfillStation.set_outlets(@outlets)
	@binfill_stations =  eval(@list_query) if !@binfill_stations
	session[:current_binfill_stations]= @binfill_stations
	
	@caption = "'list of binfill stations for line: " + session[:current_production_run].line_code + " :side " + session[:current_side] + "(schedule: " + "\"#{session[:current_closed_schedule].production_schedule_name}\", run: " + "\"#{session[:current_production_run].production_run_number}\"" + ")'"
	
    render :inline => %{
      <% grid            = build_binfill_stations_grid(@binfill_stations,@can_edit) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def view_rmt_products_sorts_allocation
   list_binfill_sort_stations true
 end
 

def allocate_rmt_products_sorts
  return if authorise_for_web('runs','production_run_setup') == false 
  
    list_binfill_sort_stations 

end

def list_binfill_sort_stations(is_view = nil)
  
  line_id = session[:current_production_run].line.id
   
   query = "\"SELECT
           public.binfill_sort_stations.binfill_sort_station_code,binfill_sort_stations.id,
           public.lines.line_code
           FROM
           public.lines
           INNER JOIN public.line_configs ON (public.lines.line_config_id = public.line_configs.id)
           INNER JOIN public.binfill_sort_stations ON (public.line_configs.id = public.binfill_sort_stations.line_config_id)
           WHERE
           (public.lines.id = '#{line_id}') order BY binfill_sort_station_code \""   
		 		 
	 
	 @list_query = "@binfill_sort_stations = BinfillSortStation.find_by_sql(" + query + ")"
	
	render_list_binfill_sort_stations is_view
   #rescue
    # handle_error("pack stations could not be listed")
   #end

 end

 def render_list_binfill_sort_stations(is_view = nil)
    
    @rebin_links = RebinLink.find_all_by_line_code_and_production_run_id_and_is_sort_station(session[:current_production_run].line_code,session[:current_production_run].id,true)                 
     
    BinfillSortStation.set_rebin_links(@rebin_links)
    
                     
	@can_edit =  authorise(program_name?,'production_run_setup',session[:user_id])
	@can_edit = false if is_view
	
	
	@binfill_sort_stations =  eval(@list_query) if !@binfill_sort_stations
	session[:current_binfill_sort_stations]= @binfill_sort_stations
	
	@caption = "'list of binfill sort stations for line: " + session[:current_production_run].line_code + "(schedule: " + "\"#{session[:current_closed_schedule].production_schedule_name}\", run: " + "\"#{session[:current_production_run].production_run_number}\"" + ")'"
	
    render :inline => %{
      <% grid            = build_binfill_sort_stations_grid(@binfill_sort_stations,@can_edit) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def view_bintip_criteria
  @bintip_criteria_setup = session[:current_production_run].run_bintip_criterium
  render_edit_bintip_criterium true
 
 end
 
 
 def render_edit_bintip_criterium(is_view = nil)
#	 render (inline) the edit template
    
    @caption_action = "edit "
    @caption_action = "view " if is_view
    @action = "update_bintip_criterium"
    @action = nil if is_view
    @caption = "update_bintip_criterium"
    @caption = "" if is_view
    
	render :inline => %{
		<% @content_header_caption = "'edit bintip criteria for schedule: " + session[:current_production_run].production_schedule_name + "  and run: " + session[:current_production_run].production_run_number.to_s + "'"%> 

		<%= build_bintip_criterium_form(@bintip_criteria_setup,@action,@caption,true,false,false)%>

		}, :layout => 'content'
end
 
def update_bintip_criterium
	 id = params[:bintip_criteria_setup][:id]
	 if id && @bintip_criteria_setup = RunBintipCriterium.find(id)
		 if @bintip_criteria_setup.update_attributes(params[:bintip_criteria_setup])
			flash[:notice]= "bin tip criteria updated successfully for run"
			active_run
		    return
		 end
	 end
 end
 
 def view_pack_materials
  list_query = "@pack_materials = ProductionRunPackMaterial.find_all_by_production_run_id('#{session[:current_production_run].id}',
				:order => 'fg_product_code')"
	
    @pack_materials =  eval(list_query) 
	
	@caption = "'list of addition pack material usages for run: " + "\"#{session[:current_production_run].production_run_code}\"" + "'"
	
    render :inline => %{
      <% grid            = build_pack_materials_grid(@pack_materials,false) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

end

def view_palletizing_criteria_setup

 session[:palletizing_view]= true
 render_edit_palletizing_criteria nil,true

end



def render_edit_pack_materials
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit pack material for production run'"%> 

		<%= build_fg_run_pack_materials_form(@production_run_pack_material,'create_production_run_pack_material','save')%>

		}, :layout => 'content'
end

def render_edit_palletizing_criteria(run_palletizing_criteria_setup = nil,is_view = nil)
  begin  
    @caption_action = "'edit palletizing criteria setup for run'"
    @run_palletizing_criteria_setup = run_palletizing_criteria_setup
    
    @is_edit = false
    
    if run_palletizing_criteria_setup && run_palletizing_criteria_setup.carton_setup
     @is_edit = true
     @caption_action = "'edit palletizing setup criteria  for carton setup: " + run_palletizing_criteria_setup.carton_setup.carton_setup_code + "'"
    
    end
    
    if is_view||session[:palletizing_view]
     @is_edit = false 
     @caption_action = "'view palletizing criteria for individual carton setups'"
     @action = nil
     @caption = ""
    else
      @action = 'update_palletizing_criteria'
     @caption = 'update_palletizing_criteria'
    end
    
	render :inline => %{
		<% @content_header_caption = @caption_action%> 

		<%= build_palletizing_criterium_form(@run_palletizing_criteria_setup,@action,@caption,@is_edit)%>

		}, :layout => 'content'
  rescue
    handle_error("palletizing criteria form could not be rendered")
  end
end


def view_drops_to_counts
 
   @pack_group = PackGroup.find(params[:id])
    session[:current_pack_group] = @pack_group
	list_query = "@pack_group_outlets = PackGroupOutlet.find_all_by_pack_group_id('#{params[:id]}',
				 :order => 'id')"
 
    @pack_group_outlets =  eval(list_query)
	
	@caption = "'<font color = \"brown\">Setup pack group " + session[:current_pack_group].pack_group_number.to_s + "(commodity: " + session[:current_pack_group].commodity_code + ",color percentage: " + session[:current_pack_group].color_sort_percentage.to_s + ", grade: " + session[:current_pack_group].grade_code.to_s + ")</font>'"
	
    render :inline => %{
      <% grid            = build_drops_to_counts_grid(@pack_group_outlets,false) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
 
 end
 


 
#............................................



def view_retail_item_setup
  @retail_item_setup = session[:current_carton_setup].retail_item_setup
  render :inline => %{
		<% @content_header_caption = "'view retail_item_setup'"%> 

		<%= view_retail_item_setup(@retail_item_setup)%>

		}, :layout => 'content'
end

def view_retail_unit_setup
  @retail_unit_setup = session[:current_carton_setup].retail_unit_setup
  render :inline => %{
		<% @content_header_caption = "'view retail_unit_setup'"%> 

		<%= view_retail_unit_setup(@retail_unit_setup)%>

		}, :layout => 'content'
end

def view_fg_product
    
    @fg_product = session[:current_carton_setup].fg_setup.fg_product
    render :inline => %{
		<% @content_header_caption = "'view fg_product'"%> 

		<%= view_fg_product(@fg_product,"view_fg_setup")%>

	}, :layout => 'content'
    


 end

def view_fg_setup
  @fg_setup = session[:current_carton_setup].fg_setup
  render :inline => %{
		<% @content_header_caption = "'view fg_setup'"%> 

		<%= view_fg_setup(@fg_setup)%>

		}, :layout => 'content'
end

def view_pallet_format_product
    
    @pallet_format_product = session[:current_carton_setup].pallet_setup.pallet_format_product
    render :inline => %{
		<% @content_header_caption = "'view pallet_format_product'"%> 

		<%= view_pallet_format_product(@pallet_format_product,"view_pallet_setup")%>

	}, :layout => 'content'
    


 end

def view_pallet_setup
  @pallet_setup = session[:current_carton_setup].pallet_setup
  render :inline => %{
		<% @content_header_caption = "'view pallet_setup'"%> 

		<%= view_pallet_setup(@pallet_setup)%>

		}, :layout => 'content'
end

def view_trade_unit_setup
  @trade_unit_setup = session[:current_carton_setup].trade_unit_setup
  render :inline => %{
		<% @content_header_caption = "'view trade_unit_setup'"%> 

		<%= view_trade_unit_setup(@trade_unit_setup)%>

		}, :layout => 'content'
end

 def view_item_pack_product
    
    @item_pack_product = session[:current_carton_setup].retail_item_setup.item_pack_product
    render :inline => %{
		<% @content_header_caption = "'view item_pack_product'"%> 

		<%= view_item_pack_product(@item_pack_product,"view_retail_item_setup")%>

	}, :layout => 'content'
    
 end
 
 def view_unit_pack_product
    
    @unit_pack_product = session[:current_carton_setup].retail_unit_setup.unit_pack_product
    render :inline => %{
		<% @content_header_caption = "'view unit_pack_product'"%> 

		<%= view_unit_pack_product(@unit_pack_product,"view_retail_unit_setup")%>

	}, :layout => 'content'
    


 end
 
 def view_carton_pack_product
    
    @carton_pack_product = session[:current_carton_setup].trade_unit_setup.carton_pack_product
    render :inline => %{
		<% @content_header_caption = "'view carton_pack_product'"%> 

		<%= view_carton_pack_product(@carton_pack_product,"view_trade_unit_setup")%>

	}, :layout => 'content'
    


 end

def view_pallet_cartons
  @pallet_number= params[:id]
  
#-------------------------------------------------------------------
    list_query = Diagnostics.pallet_cartons(@pallet_number)
	session[:pallet_cartons_query] = list_query
#------------------------------------------------------------------
	render_list_cartons
end

def view_carton_setup
#''''''''''Using carton_template_id(params[:id]) to get carton_setup_id
begin
  carton_template = CartonTemplate.find(params[:id])
  id = carton_template.carton_setup_id
rescue
  id = params[:id] 
end
#''''''''''
  @carton_setup = nil
  #id = params[:id]
  if id
    @carton_setup = CartonSetup.find(id)
  else
    @carton_setup = session[:current_carton_setup]
  end
  
  session[:current_carton_setup] = @carton_setup
    render :inline => %{
                     <% @content_header_caption = "'view carton setup'"%>
                     <%= carton_setup_view(@carton_setup,nil)%>
                     
                      },:layout => 'content'
end

def view_carton_label_setup 
#''''''''''Using carton_template_id(params[:id]) to get carton_setup_id,then using that to get @carton_label_setup object 
  carton_template = CartonTemplate.find(params[:id])
  carton_setup_id = carton_template.carton_setup_id
  @carton_label_setup = CartonLabelSetup.find(:first,:conditions =>['carton_setup_id = ? ', carton_setup_id])#NOT SURE
  render :inline => %{
                      <% @content_header_caption = "'view carton label set up'"%>
                     <%= carton_label_setup_view(@carton_label_setup,"view_carton")%>
                      }, :layout => 'content'
end

def render_list_cartons
    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:carton_page] if session[:carton_page]
	@current_page = params['page'] if params['page']
	@pallet_cartons =  eval(session[:pallet_cartons_query]) if !@outbox_entries
	render :inline => %{
      <% grid            = build_pallet_cartons_grid(@pallet_cartons,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of pallet cartons' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@carton_pages) if @carton_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def view_logged_error
  id = params[:id]
  @query_criterium = "Outbox entry: " + id + "(type: " +  session[:type_code].fetch(id.to_s) + ")%"
  @search_from = 3.day.ago.to_formatted_s(:db).to_s
  @rails_error_record = RailsError.find(:first,:conditions =>['error_type = ? and created_on > ? and description Like ? ', 'outbox_processor',@search_from, @query_criterium])
  render :inline => %{
                     <% @content_header_caption = "'view rails error record'"%>
                     <%if @rails_error_record%>
                     <%= build_rails_error_view(@rails_error_record,"view_paging_handler")%>
                     <%end%>
                     }, :layout => 'content'
end

#:::::::::::::::::::::::::::::::::::::::::::::::: HAPPYMORE'S CODE:::::::::::::::::::::::::

def list_missing_flows
    return if authorise_for_web('integration','read') == false 

 	if params[:page]!= nil 

 		session[:midware_error_log_page] = params['page']
		 render_list_missing_flows_errors

		 return 
	else
		session[:midware_error_log_page] = nil
	end
	
	t1 = Date.today
    t2 = Date.today + 1
    @t1 = t1.strftime("%Y-%m-%d")
    @t2 = t2.strftime("%Y-%m-%d")

    list_query = "@midware_pages = Paginator.new self, MidwareErrorLog.count, @@page_size,@current_page
	  @midware = MidwareErrorLog.find(:all, 
	         :conditions =>['mw_type = ? and error_date_time > ? and error_date_time < ? and short_description like ?', 'integration',@t1,@t2,'%Integration record of type%'],
			 :limit => @midware_pages.items_per_page,
			 :offset => @midware_pages.current.offset)"
	session[:query] = list_query
	render_list_missing_flows_errors
end

def render_list_missing_flows_errors
    @can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:midware_error_log_page] if session[:midware_error_log_page]
	
	@current_page = params['page'] if params['page']
	
	@midware =  eval(session[:query]) if !@midware
	if @midware.length() < 0 || @midware.length() > 0
    render :inline => %{
      <% grid            = build_missing_flows_grid(@midware,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of integration(missing flows) errors' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
	else
	   render :inline => %{
		<% @content_header_caption = "'no integration(missing flows) errors found'"%>
		
	},:layout => 'content'
	end
end

def view_details
    id = params[:id]
	 if id && @mid = MidwareErrorLog.find(id)
		render :inline => %{
		<% @content_header_caption = "'view complete stack trace'"%> 

		<%= view_missing_flows_error_log_form(@mid,'view_missing_flows_paging_handler')%>

		}, :layout => 'content'

	 end
end

def create_flow_details
    ids = params[:id].split("$")
    error_entry_id = ids[0]
    record_id = ids[1]
    flow_type = ids[2]
    
    object_type = case flow_type
         when "pallet_completed" then "Pallet"
         when "rebin_new" then "Rebin"
         when  "bin_tipped" "BinsTipped"
         when "pallet_rtb" then "Pallet"
         else  
          raise "Flow: " + flow_type + " not supported"               
       end
 
     
    if record_id && @out = OutboxEntry.find(:first, :conditions=>["record_id = ? and type_code = ?", record_id, flow_type])
        flash[:notice] = "flow already created"
        view_missing_flows_paging_handler
    else
        if record_id && @object = eval(object_type + ".find(:first, :conditions=>['id = ?', #{record_id}])")
            
            @new_record = NewOutboxRecord.new(flow_type,@object)
            if session[:flows_created_list]== nil
                 session[:flows_created_list]= Hash.new
            end
            
            if !session[:flows_created_list].has_key?(error_entry_id)
               session[:flows_created_list].store(error_entry_id,"yes")
            else
               session[:flows_created_list][:id]= "yes"
            end
            
            
            flash[:notice] = "Flow Created Successfully!"
            back_rendering
        else   
            render :inline=> %{}, :layout=>'content'
       
        end
    end
end

def create_flow_details_old
    ids = params[:id].split("$")
    error_entry_id = ids[0]
    record_id = ids[1]
    flow_type = ids[2]
    
     
    if record_id && @out = OutboxEntry.find(:first, :conditions=>["record_id = ? and type_code = ?", record_id, flow_type])
        flash[:notice] = "flow already created"
        view_missing_flows_paging_handler
    else
        if record_id && @object = Pallet.find(:first, :conditions=>["id = ?", record_id])
            
            @new_record = NewOutboxRecord.new(flow_type,@pal)
            if session[:flows_created_list]== nil
                 session[:flows_created_list]= Hash.new
            end
            
            if !session[:flows_created_list].has_key?(error_entry_id)
               session[:flows_created_list].store(error_entry_id,"yes")
            else
               session[:flows_created_list][:id]= "yes"
            end
            
            
            flash[:notice] = "Flow Created Successfully!"
            back_rendering
        else   
            render :inline=> %{}, :layout=>'content'
       
        end
    end
end

def back_rendering
    @midware =  eval(session[:query]) if !@midware
    @midware.each do |rec|
        if session[:flows_created_list].has_key?(rec.id.to_s)
          puts "ID: " + rec.id.to_s
          rec.missing = "no"
        else
          rec.missing = session[:flows_created_list][rec.id.to_s]
          puts "y"
        end
        
    end
    puts @midware.length().to_s
    
    render :inline => %{
      <% grid            = build_missing_flows_grid(@midware,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of integration(missing flows) errors' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def view_missing_flows_paging_handler

  if params[:page]
	session[:midware_error_log_page] = params['page']
  end
  render_list_missing_flows_errors
end
#:::::::::::::::::::::::::::::::::::::::::: END OF HAPPYMORE'S CODE :::::::::::::::::::::::::
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

end
