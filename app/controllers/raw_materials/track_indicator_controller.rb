class  RawMaterials::TrackIndicatorController < ApplicationController
 
def program_name?
	"track_indicator"
end

def bypass_generic_security?
	true
end

#===============
#OLD PACK CODE
#===============

def mark_code_changed
    mark_code = get_selected_combo_value(params)
	
	brand_code = Mark.find_by_mark_code(mark_code).brand_code
	@brand = ""
	@brand = brand_code
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
	<%= @brand %>

	}


end


def list_old_packs
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:old_packs_page] = params['page']

		 render_list_old_packs

		 return 
	else
		session[:old_packs_page] = nil
	end

	list_query = "@old_pack_pages = Paginator.new self, OldPack.count, @@page_size,@current_page
	 @old_packs = OldPack.find(:all,
				 :limit => @old_pack_pages.items_per_page,
				 :offset => @old_pack_pages.current.offset)"
	session[:query] = list_query
	render_list_old_packs
end


def render_list_old_packs
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:old_packs_page] if session[:old_packs_page]
	@current_page = params['page'] if params['page']
	@old_packs =  eval(session[:query]) if !@old_packs

  render :inline => %{
        <% grid            = build_old_pack_grid(@old_packs,@can_edit,@can_delete)%>
        <% grid.caption    = 'list of all old_packs' %>
        <% @header_content = grid.build_grid_data %>
		<% @pagination = pagination_links(@old_pack_pages) if @old_pack_pages != nil %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
end
 
def search_old_packs_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_old_pack_search_form
end

def render_old_pack_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  old_packs'"%> 

		<%= build_old_pack_search_form(nil,'submit_old_packs_search','submit_old_packs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_old_packs_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_old_pack_search_form(true)
end

def render_old_pack_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  old_packs'"%> 

		<%= build_old_pack_search_form(nil,'submit_old_packs_search','submit_old_packs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_old_packs_search
	if params['page']
		session[:old_packs_page] =params['page']
	else
		session[:old_packs_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @old_packs = dynamic_search(params[:old_pack] ,'old_packs','OldPack')
	else
		@old_packs = eval(session[:query])
	end
	if @old_packs.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_old_pack_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_old_packs
		end

	else

		render_list_old_packs
	end
end

 
def delete_old_pack
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:old_packs_page] = params['page']
		render_list_old_packs
		return
	end
	id = params[:id]
	if id && old_pack = OldPack.find(id)
		old_pack.destroy
		session[:alert] = " Record deleted."
		render_list_old_packs
	end
   rescue
   handle_error("old pack could not be deleted")
  end
end
 
def new_old_pack
	return if authorise_for_web(program_name?,'create')== false
		render_new_old_pack
end
 
def create_old_pack
  begin
	 @old_pack = OldPack.new(params[:old_pack])
	 if @old_pack.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_old_pack
	 end
   rescue
   handle_error("old pack could not be created")
  end
end

def render_new_old_pack
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new old_pack'"%> 

		<%= build_old_pack_form(@old_pack,'create_old_pack','create_old_pack',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_old_pack
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @old_pack = OldPack.find(id)
		render_edit_old_pack

	 end
end


def render_edit_old_pack
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit old_pack'"%> 

		<%= build_old_pack_form(@old_pack,'update_old_pack','update_old_pack',true)%>

		}, :layout => 'content'
end
 
def update_old_pack
  begin
	if params[:page]
		session[:old_packs_page] = params['page']
		render_list_old_packs
		return
	end

		@current_page = session[:old_packs_page]
	 id = params[:old_pack][:id]
	 if id && @old_pack = OldPack.find(id)
		 if @old_pack.update_attributes(params[:old_pack])
			@old_packs = eval(session[:query])
			render_list_old_packs
	 else
			 render_edit_old_pack

		 end
	 end
  rescue
   handle_error("old pack could not be updated")
  end
 end



#===============
#BASIC PACK CODE
#===============
def list_basic_packs
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:basic_packs_page] = params['page']

		 render_list_basic_packs

		 return 
	else
		session[:basic_packs_page] = nil
	end

	list_query = "@basic_pack_pages = Paginator.new self, BasicPack.count, @@page_size,@current_page
	 @basic_packs = BasicPack.find(:all,
				 :limit => @basic_pack_pages.items_per_page,
				 :offset => @basic_pack_pages.current.offset)"
	session[:query] = list_query
	render_list_basic_packs
end


def render_list_basic_packs
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:basic_packs_page] if session[:basic_packs_page]
	@current_page = params['page'] if params['page']
	@basic_packs =  eval(session[:query]) if !@basic_packs
	render :inline => %{
      <% grid            = build_basic_pack_grid(@basic_packs,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all basic_packs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@basic_pack_pages) if @basic_pack_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_basic_packs_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_basic_pack_search_form
end

def render_basic_pack_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  basic_packs'"%> 

		<%= build_basic_pack_search_form(nil,'submit_basic_packs_search','submit_basic_packs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_basic_packs_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_basic_pack_search_form(true)
end

def render_basic_pack_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  basic_packs'"%> 

		<%= build_basic_pack_search_form(nil,'submit_basic_packs_search','submit_basic_packs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_basic_packs_search
	if params['page']
		session[:basic_packs_page] =params['page']
	else
		session[:basic_packs_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @basic_packs = dynamic_search(params[:basic_pack] ,'basic_packs','BasicPack')
	else
		@basic_packs = eval(session[:query])
	end
	if @basic_packs.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_basic_pack_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_basic_packs
		end

	else

		render_list_basic_packs
	end
end

 
def delete_basic_pack
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:basic_packs_page] = params['page']
		render_list_basic_packs
		return
	end
	id = params[:id]
	if id && basic_pack = BasicPack.find(id)
		basic_pack.destroy
		session[:alert] = " Record deleted."
		render_list_basic_packs
	end
   rescue
   handle_error("basic pack could not be created")
  end
end
 
def new_basic_pack
	return if authorise_for_web(program_name?,'create')== false
		render_new_basic_pack
end
 
def create_basic_pack
  begin
	 @basic_pack = BasicPack.new(params[:basic_pack])
	 if @basic_pack.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_basic_pack
	 end
   rescue
   handle_error("basic pack could not be created")
  end
end

def render_new_basic_pack
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new basic_pack'"%> 

		<%= build_basic_pack_form(@basic_pack,'create_basic_pack','create_basic_pack',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_basic_pack
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @basic_pack = BasicPack.find(id)
		render_edit_basic_pack

	 end
end


def render_edit_basic_pack
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit basic_pack'"%> 

		<%= build_basic_pack_form(@basic_pack,'update_basic_pack','update_basic_pack',true)%>

		}, :layout => 'content'
end
 
def update_basic_pack
  begin
	if params[:page]
		session[:basic_packs_page] = params['page']
		render_list_basic_packs
		return
	end

		@current_page = session[:basic_packs_page]
	 id = params[:basic_pack][:id]
	 if id && @basic_pack = BasicPack.find(id)
		 if @basic_pack.update_attributes(params[:basic_pack])
			@basic_packs = eval(session[:query])
			render_list_basic_packs
	 else
			 render_edit_basic_pack

		 end
	 end
   rescue
   handle_error("basic pack could not be updated")
  end
 end


#=========
#GTIN CODE
#=========
def list_gtins
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:gtins_page] = params['page']

		 render_list_gtins

		 return 
	else
		session[:gtins_page] = nil
	end

	list_query = "@gtin_pages = Paginator.new self, Gtin.count, @@page_size,@current_page
	 @gtins = Gtin.find(:all,
				 :limit => @gtin_pages.items_per_page,
				 :offset => @gtin_pages.current.offset)"
	session[:query] = list_query
	render_list_gtins
end


def render_list_gtins
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:gtins_page] if session[:gtins_page]
	@current_page = params['page'] if params['page']
	@gtins =  eval(session[:query]) if !@gtins
  render :inline => %{
      <% grid            = build_gtin_grid(@gtins,@can_edit,@can_delete)%>
      <% grid.caption    = 'list of all gtins' %>
      <% @header_content = grid.build_grid_data %>

		<% @pagination = pagination_links(@gtin_pages) if @gtin_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_gtins_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true
  if(session[:gtin_search_criteria])
    @gtin = Gtin.new
    @gtin.organization_code = session[:gtin_search_criteria]["organization_code"]
    @gtin.commodity_code = session[:gtin_search_criteria]["commodity_code"]
    @gtin.marketing_variety_code = session[:gtin_search_criteria]["marketing_variety_code"]
    @gtin.old_pack_code = session[:gtin_search_criteria]["old_pack_code"]
    @gtin.actual_count = session[:gtin_search_criteria]["actual_count"]
    @gtin.grade_code = session[:gtin_search_criteria]["grade_code"]
    @gtin.brand_code = session[:gtin_search_criteria]["brand_code"]
    @gtin.inventory_code = session[:gtin_search_criteria]["inventory_code"]
    @actions = true
  end
	render_gtin_search_form
end

def remove_gtin_target_market
  @gtin_tm = GtinTargetMarket.find(params[:id])
  begin
    @gtin_tm.destroy
    params[:id] = session[:gtin].to_s
    gtin_target_markets
#    render :inline=>%{},:layout=>'content'
  rescue
    session[:alert] = "could not delete gtin_target_makert record"
#    puts "ERROR : " + $!.to_s
#    puts $!.backtrace.join("\n")
    params[:id] = session[:gtin].to_s 
    puts " 2 params[:id] = " +  params[:id]
    gtin_target_markets
  end
end

def render_gtin_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form  
	render :inline => %{
		<% @content_header_caption = "'search  gtins'"%> 

		<%= build_gtin_search_form(@gtin,'submit_gtins_search','submit_gtins_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_gtins_hierarchy
	return if authorise_for_web(program_name?,'read')== false

  if(session[:gtin_search_criteria])
    @gtin = Gtin.new
    @gtin.organization_code = session[:gtin_search_criteria]["organization_code"]
    @gtin.commodity_code = session[:gtin_search_criteria]["commodity_code"]
    @gtin.marketing_variety_code = session[:gtin_search_criteria]["marketing_variety_code"]
    @gtin.old_pack_code = session[:gtin_search_criteria]["old_pack_code"]
    @gtin.actual_count = session[:gtin_search_criteria]["actual_count"]
    @gtin.grade_code = session[:gtin_search_criteria]["grade_code"]
    @gtin.brand_code = session[:gtin_search_criteria]["brand_code"]
    @gtin.inventory_code = session[:gtin_search_criteria]["inventory_code"]
    @actions = true
  end
	@is_flat_search = false 
	render_gtin_search_form(true)
end

#def render_gtin_search_form(is_flat_search = nil)
#	session[:is_flat_search] = @is_flat_search
##	 render (inline) the search form
#	render :inline => %{
#		<% @content_header_caption = "'search  gtins'"%>
#
#		<%= build_gtin_search_form(nil,'submit_gtins_search','submit_gtins_search',@is_flat_search)%>
#
#		}, :layout => 'content'
#end
 
def submit_gtins_search
	if params['page']
		session[:gtins_page] =params['page']
	else
		session[:gtins_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @gtins = dynamic_search(params[:gtin] ,'gtins','Gtin')
	else
		@gtins = eval(session[:query])
	end
	if @gtins.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_gtin_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_gtins
		end

	else

		render_list_gtins
	end
end

 
def delete_gtin
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:gtins_page] = params['page']
		render_list_gtins
		return
	end
	id = params[:id]
	if id && gtin = Gtin.find(id)
		gtin.destroy
		session[:alert] = " Record deleted."
		render_list_gtins
	end
   rescue
   handle_error("gtin could not be deleted")
  end
end
  
def new_gtin
	return if authorise_for_web(program_name?,'create')== false
		render_new_gtin
end
 
def create_gtin
  begin
	 @gtin = Gtin.new(params[:gtin])
	 if @gtin.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_gtin
	 end
  rescue
   handle_error("gtin could not be created")
  end
end

def render_new_gtin
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new gtin'"%> 

		<%= build_gtin_form(@gtin,'create_gtin','create_gtin',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_gtin
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @gtin = Gtin.find(id)
		render_edit_gtin

	 end
end


def render_edit_gtin
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit gtin'"%> 

		<%= build_gtin_form(@gtin,'update_gtin','update_gtin',true)%>

		}, :layout => 'content'
end
 
def update_gtin
  begin
	if params[:page]
		session[:gtins_page] = params['page']
		render_list_gtins
		return
	end

		@current_page = session[:gtins_page]
	 id = params[:gtin][:id]
	 if id && @gtin = Gtin.find(id)
		 if @gtin.update_attributes(params[:gtin])
			@gtins = eval(session[:query])
			render_list_gtins
	 else
			 render_edit_gtin

		 end
	 end
  rescue
   handle_error("gtin could not be updated")
  end
 end
 
def gtin_org_combo_changed
    
    organization_code = get_selected_combo_value(params)
    @target_markets = TargetMarket.get_all_by_org(organization_code)
	@inventory_codes = InventoryCode.get_all_by_org(organization_code)
    
    render :inline => %{
    <% target_market_content = select('gtin','target_market_code',@target_markets) %>
    <% inventory_code_content = select('gtin','inventory_code',@inventory_codes) %>
   
   <script>
    <%= update_element_function(
        "target_market_code_cell", :action => :update,
        :content => target_market_content) %>
        
    <%= update_element_function(
        "inventory_code_cell", :action => :update,
        :content => inventory_code_content) %> 
        
   </script>
  }


end

def gtin_commodity_code_changed
	commodity_code = get_selected_combo_value(params)
	session[:gtin_form][:commodity_code_combo_selection] = commodity_code
	@old_pack_codes = Gtin.old_pack_codes_for_commodity_code(commodity_code)
	@marketing_variety_codes = MarketingVariety.find_all_by_commodity_code(commodity_code).map{|c|[c.marketing_variety_code]}
#	render (inline) the html to replace the contents of the td that contains the dropdown 
#	render :inline => %{
#		<%= select('gtin','old_pack_code',@old_pack_codes)%>
#		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_gtin_old_pack_code'/>
#		<%= observe_field('gtin_old_pack_code',:update => 'actual_count_cell',:url => {:action => session[:gtin_form][:old_pack_code_observer][:remote_method]},:loading => "show_element('img_gtin_old_pack_code');",:complete => session[:gtin_form][:old_pack_code_observer][:on_completed_js])%>
#		}

     render :inline => %{
	    <% m_varieties_content = select('gtin','marketing_variety_code',@marketing_variety_codes) %>
	     <%= select('gtin','old_pack_code',@old_pack_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_gtin_old_pack_code'/>
		<%= observe_field('gtin_old_pack_code',:update => 'actual_count_cell',:url => {:action => session[:gtin_form][:old_pack_code_observer][:remote_method]},:loading => "show_element('img_gtin_old_pack_code');",:complete => session[:gtin_form][:old_pack_code_observer][:on_completed_js])%>
		<script>
		<%= update_element_function(
        "marketing_variety_code_cell", :action => :update,
        :content => m_varieties_content) %>
        </script>
		
		}
  

end


def gtin_old_pack_code_changed
	old_pack_code = get_selected_combo_value(params)
	session[:gtin_form][:old_pack_code_combo_selection] = old_pack_code
	commodity_code = 	session[:gtin_form][:commodity_code_combo_selection]
	@actual_counts = Gtin.actual_counts_for_old_pack_code_and_commodity_code(old_pack_code,commodity_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('gtin','actual_count',@actual_counts)%>

		}

end


#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(gtins)
#	-----------------------------------------------------------------------------------------------------------
def gtin_organization_code_search_combo_changed
	organization_code = get_selected_combo_value(params)
	session[:gtin_search_form][:organization_code_combo_selection] = organization_code
	@commodity_codes = Gtin.find_by_sql("Select distinct commodity_code from gtins where organization_code = '#{organization_code}'").map{|g|[g.commodity_code]}
	@commodity_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('gtin','commodity_code',@commodity_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_gtin_commodity_code'/>
		<%= observe_field('gtin_commodity_code',:update => 'marketing_variety_code_cell',:url => {:action => session[:gtin_search_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_gtin_commodity_code');",:complete => session[:gtin_search_form][:commodity_code_observer][:on_completed_js])%>
		}

end


def gtin_commodity_code_search_combo_changed
	commodity_code = get_selected_combo_value(params)
	session[:gtin_search_form][:commodity_code_combo_selection] = commodity_code
	organization_code = 	session[:gtin_search_form][:organization_code_combo_selection]
	@marketing_variety_codes = Gtin.find_by_sql("Select distinct marketing_variety_code from gtins where commodity_code = '#{commodity_code}' and organization_code = '#{organization_code}'").map{|g|[g.marketing_variety_code]}
	@marketing_variety_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('gtin','marketing_variety_code',@marketing_variety_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_gtin_marketing_variety_code'/>
		<%= observe_field('gtin_marketing_variety_code',:update => 'old_pack_code_cell',:url => {:action => session[:gtin_search_form][:marketing_variety_code_observer][:remote_method]},:loading => "show_element('img_gtin_marketing_variety_code');",:complete => session[:gtin_search_form][:marketing_variety_code_observer][:on_completed_js])%>
		}

end


def gtin_marketing_variety_code_search_combo_changed
	marketing_variety_code = get_selected_combo_value(params)
	session[:gtin_search_form][:marketing_variety_code_combo_selection] = marketing_variety_code
	commodity_code = 	session[:gtin_search_form][:commodity_code_combo_selection]
	organization_code = 	session[:gtin_search_form][:organization_code_combo_selection]
	@old_pack_codes = Gtin.find_by_sql("Select distinct old_pack_code from gtins where marketing_variety_code = '#{marketing_variety_code}' and commodity_code = '#{commodity_code}' and organization_code = '#{organization_code}'").map{|g|[g.old_pack_code]}
	@old_pack_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('gtin','old_pack_code',@old_pack_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_gtin_old_pack_code'/>
		<%= observe_field('gtin_old_pack_code',:update => 'mark_code_cell',:url => {:action => session[:gtin_search_form][:old_pack_code_observer][:remote_method]},:loading => "show_element('img_gtin_old_pack_code');",:complete => session[:gtin_search_form][:old_pack_code_observer][:on_completed_js])%>
		}

end


def gtin_old_pack_code_search_combo_changed
	old_pack_code = get_selected_combo_value(params)
	session[:gtin_search_form][:old_pack_code_combo_selection] = old_pack_code
	marketing_variety_code = 	session[:gtin_search_form][:marketing_variety_code_combo_selection]
	commodity_code = 	session[:gtin_search_form][:commodity_code_combo_selection]
	organization_code = 	session[:gtin_search_form][:organization_code_combo_selection]
	@mark_codes = Gtin.find_by_sql("Select distinct mark_code from gtins where old_pack_code = '#{old_pack_code}' and marketing_variety_code = '#{marketing_variety_code}' and commodity_code = '#{commodity_code}' and organization_code = '#{organization_code}'").map{|g|[g.mark_code]}
	@mark_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('gtin','mark_code',@mark_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_gtin_mark_code'/>
		<%= observe_field('gtin_mark_code',:update => 'actual_count_cell',:url => {:action => session[:gtin_search_form][:mark_code_observer][:remote_method]},:loading => "show_element('img_gtin_mark_code');",:complete => session[:gtin_search_form][:mark_code_observer][:on_completed_js])%>
		}

end


def gtin_mark_code_search_combo_changed
	mark_code = get_selected_combo_value(params)
	session[:gtin_search_form][:mark_code_combo_selection] = mark_code
	old_pack_code = 	session[:gtin_search_form][:old_pack_code_combo_selection]
	marketing_variety_code = 	session[:gtin_search_form][:marketing_variety_code_combo_selection]
	commodity_code = 	session[:gtin_search_form][:commodity_code_combo_selection]
	organization_code = 	session[:gtin_search_form][:organization_code_combo_selection]
	@actual_counts = Gtin.find_by_sql("Select distinct actual_count from gtins where mark_code = '#{mark_code}' and old_pack_code = '#{old_pack_code}' and marketing_variety_code = '#{marketing_variety_code}' and commodity_code = '#{commodity_code}' and organization_code = '#{organization_code}'").map{|g|[g.actual_count]}
	@actual_counts.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('gtin','actual_count',@actual_counts)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_gtin_actual_count'/>
		<%= observe_field('gtin_actual_count',:update => 'grade_code_cell',:url => {:action => session[:gtin_search_form][:actual_count_observer][:remote_method]},:loading => "show_element('img_gtin_actual_count');",:complete => session[:gtin_search_form][:actual_count_observer][:on_completed_js])%>
		}

end


def gtin_actual_count_search_combo_changed
	actual_count = get_selected_combo_value(params)
	session[:gtin_search_form][:actual_count_combo_selection] = actual_count
	mark_code = 	session[:gtin_search_form][:mark_code_combo_selection]
	old_pack_code = 	session[:gtin_search_form][:old_pack_code_combo_selection]
	marketing_variety_code = 	session[:gtin_search_form][:marketing_variety_code_combo_selection]
	commodity_code = 	session[:gtin_search_form][:commodity_code_combo_selection]
	organization_code = 	session[:gtin_search_form][:organization_code_combo_selection]
	@grade_codes = Gtin.find_by_sql("Select distinct grade_code from gtins where actual_count = '#{actual_count}' and mark_code = '#{mark_code}' and old_pack_code = '#{old_pack_code}' and marketing_variety_code = '#{marketing_variety_code}' and commodity_code = '#{commodity_code}' and organization_code = '#{organization_code}'").map{|g|[g.grade_code]}
	@grade_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('gtin','grade_code',@grade_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_gtin_grade_code'/>
		<%= observe_field('gtin_grade_code',:update => 'inventory_code_cell',:url => {:action => session[:gtin_search_form][:grade_code_observer][:remote_method]},:loading => "show_element('img_gtin_grade_code');",:complete => session[:gtin_search_form][:grade_code_observer][:on_completed_js])%>
		}

end


def gtin_grade_code_search_combo_changed
	grade_code = get_selected_combo_value(params)
	session[:gtin_search_form][:grade_code_combo_selection] = grade_code
	actual_count = 	session[:gtin_search_form][:actual_count_combo_selection]
	mark_code = 	session[:gtin_search_form][:mark_code_combo_selection]
	old_pack_code = 	session[:gtin_search_form][:old_pack_code_combo_selection]
	marketing_variety_code = 	session[:gtin_search_form][:marketing_variety_code_combo_selection]
	commodity_code = 	session[:gtin_search_form][:commodity_code_combo_selection]
	organization_code = 	session[:gtin_search_form][:organization_code_combo_selection]
	@inventory_codes = Gtin.find_by_sql("Select distinct inventory_code from gtins where grade_code = '#{grade_code}' and actual_count = '#{actual_count}' and mark_code = '#{mark_code}' and old_pack_code = '#{old_pack_code}' and marketing_variety_code = '#{marketing_variety_code}' and commodity_code = '#{commodity_code}' and organization_code = '#{organization_code}'").map{|g|[g.inventory_code]}
	@inventory_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('gtin','inventory_code',@inventory_codes)%>

		}

end



#=====================
#TRACK INDICATORS CODE
#=====================
def list_track_indicators

 	if params[:page]!= nil 

 		session[:track_indicators_page] = params['page']

		 render_list_track_indicators

		 return 
	else
		session[:track_indicators_page] = nil
	end

	list_query = "@track_indicator_pages = Paginator.new self, TrackIndicator.count, @@page_size,@current_page
	 @track_indicators = TrackIndicator.find(:all,
				 :limit => @track_indicator_pages.items_per_page,
				 :offset => @track_indicator_pages.current.offset)"
	session[:query] = list_query
	render_list_track_indicators
end


def render_list_track_indicators
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:track_indicators_page] if session[:track_indicators_page]
	@current_page = params['page'] if params['page']
	@track_indicators =  eval(session[:query]) if !@track_indicators
	render :inline => %{
      <% grid            = build_track_indicator_grid(@track_indicators,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all track_indicators' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@track_indicator_pages) if @track_indicator_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_track_indicators_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_track_indicator_search_form
end

def render_track_indicator_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  track_indicators'"%> 

		<%= build_track_indicator_search_form(nil,'submit_track_indicators_search','submit_track_indicators_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_track_indicators_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_track_indicator_search_form(true)
end

def render_track_indicator_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  track_indicators'"%> 

		<%= build_track_indicator_search_form(nil,'submit_track_indicators_search','submit_track_indicators_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_track_indicators_search
	if params['page']
		session[:track_indicators_page] =params['page']
	else
		session[:track_indicators_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @track_indicators = dynamic_search(params[:track_indicator] ,'track_indicators','TrackIndicator')
	else
		@track_indicators = eval(session[:query])
	end
	if @track_indicators.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_track_indicator_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_track_indicators
		end

	else

		render_list_track_indicators
	end
end

 
def delete_track_indicator
  begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:track_indicators_page] = params['page']
		render_list_track_indicators
		return
	end
	id = params[:id]
	if id && track_indicator = TrackIndicator.find(id)
		track_indicator.destroy
		session[:alert] = " Record deleted."
		render_list_track_indicators
	end
  rescue
   handle_error("track indicator could not be deleted")
  end
end
 
def new_track_indicator
	return if authorise_for_web(program_name?,'create')== false
		render_new_track_indicator
end
 
def create_track_indicator
   begin
	 @track_indicator = TrackIndicator.new(params[:track_indicator])
	 @track_indicator.rmt_variety_id = RmtVariety.find_by_rmt_variety_code(params[:track_indicator][:rmt_variety_code]).id
	 if @track_indicator.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_track_indicator
	 end
   rescue
   handle_error("track indicator could not be created")
  end
end

def render_new_track_indicator
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new track_indicator'"%> 

		<%= build_track_indicator_form(@track_indicator,'create_track_indicator','create_track_indicator',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_track_indicator
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @track_indicator = TrackIndicator.find(id)
		render_edit_track_indicator

	 end
end


def render_edit_track_indicator
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit track_indicator'"%> 

		<%= build_track_indicator_form(@track_indicator,'update_track_indicator','update_track_indicator',true)%>

		}, :layout => 'content'
end
 
def update_track_indicator
  begin
	if params[:page]
		session[:track_indicators_page] = params['page']
		render_list_track_indicators
		return
	end

		@current_page = session[:track_indicators_page]
	 id = params[:track_indicator][:id]
	 if id && @track_indicator = TrackIndicator.find(id)
		 if @track_indicator.update_attributes(params[:track_indicator])
			@track_indicators = eval(session[:query])
			render_list_track_indicators
	 else
			 render_edit_track_indicator

		 end
	 end
  rescue
   handle_error("track indicator could not be updated")
  end
 end
 
 
def track_indicator_commodity_group_combo_changed
	
	commodity_group_code = get_selected_combo_value(params)
	session[:track_indicator_form][:commodity_group_code_combo_selection] = commodity_group_code
	@commodity_codes = RmtVariety.find_by_sql("Select distinct commodity_code from rmt_varieties where commodity_group_code = '#{commodity_group_code}'").map{|g|[g.commodity_code]}
	@commodity_codes.unshift("<empty>")
   
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('track_indicator','commodity_code',@commodity_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_track_indicator_commodity_code'/>
		<%= observe_field('track_indicator_commodity_code',:update => 'rmt_variety_code_cell',:url => {:action => 'track_indicator_commodity_combo_changed'},:loading => "show_element('img_track_indicator_commodity_code');",:complete => session[:track_indicator_form][:commodity_code_observer][:on_completed_js])%>
		}

end


def track_indicator_commodity_combo_changed

	commodity_code = get_selected_combo_value(params)
	session[:track_indicator_form][:commodity_code_combo_selection] = commodity_code
	commodity_group_code = 	session[:track_indicator_form][:commodity_group_code_combo_selection]
	@rmt_variety_codes = RmtVariety.find_by_sql("Select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.rmt_variety_code]}
	@rmt_variety_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('track_indicator','rmt_variety_code',@rmt_variety_codes)%>

		}

end

#============
#TRACK SLMS INDICATORS CODE/Happymore
#=============

def list_track_slms_indicators
 	if params[:page]!= nil 

 		session[:track_slms_indicators_page] = params['page']

		 render_list_track_slms_indicators

		 return 
	else
		session[:track_slms_indicators_page] = nil
	end

	list_query = "@track_slms_indicator_pages = Paginator.new self, TrackSlmsIndicator.count, @@page_size,@current_page
	 @track_slms_indicators = TrackSlmsIndicator.find(:all,
				 :limit => @track_slms_indicator_pages.items_per_page,
				 :offset => @track_slms_indicator_pages.current.offset)"
	session[:query] = list_query
	render_list_track_slms_indicators
end


def render_list_track_slms_indicators
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:track_slms_indicators_page] if session[:track_slms_indicators_page]
	@current_page = params['page'] if params['page']
	@track_slms_indicators =  eval(session[:query]) if !@track_slms_indicators
	render :inline => %{
      <% grid            = build_track_slms_indicator_grid(@track_slms_indicators,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all track_slms_indicators' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@track_slms_indicator_pages) if @track_slms_indicator_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_track_slms_indicators_flat
	return if authorise_for_web(program_name?,'read')== false
	
	@is_flat_search = true 
	render_track_slms_indicator_search_form
end

def search_track_slms_indicators_hierarchy
	return if authorise_for_web(program_name?,'read')== false
	
	@is_flat_search = false 
	render_track_slms_indicator_search_form(true)
end

def render_track_slms_indicator_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  track_slms_indicators'"%> 

		<%= build_track_slms_indicator_search_form(nil,'submit_track_slms_indicators_search','submit_track_slms_indicators_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_track_slms_indicators_search
	if params['page']
		session[:track_slms_indicators_page] =params['page']
	else
		session[:track_slms_indicators_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @track_slms_indicators = dynamic_search(params[:track_slms_indicator] ,'track_slms_indicators','TrackSlmsIndicator')
	else
		@track_slms_indicators = eval(session[:query])
	end
	if @track_slms_indicators.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_track_slms_indicator_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_track_slms_indicators
		end

	else

		render_list_track_slms_indicators
	end
end

 
def delete_track_slms_indicator
 begin
	#return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:track_slms_indicators_page] = params['page']
		render_list_track_slms_indicators
		return
	end
	id = params[:id]
	if id && track_slms_indicator = TrackSlmsIndicator.find(id)
		track_slms_indicator.destroy
		session[:alert] = " Record deleted."
		render_list_track_slms_indicators
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_track_slms_indicator
	return if authorise_for_web(program_name?,'create')== false
  
  @track_slms_indicator = TrackSlmsIndicator.new
  @track_slms_indicator.track_variable_2 = true
  @is_create_retry = false

		render_new_track_slms_indicator
end
 
def create_track_slms_indicator
 begin
	 @track_slms_indicator = TrackSlmsIndicator.new#(params[:track_slms_indicator])
   params[:track_slms_indicator][:variety_type] = session[:track_slms_indicator_form][:variety_type_combo_selection]
   @track_slms_indicator.track_indicator_type_code = params[:track_slms_indicator][:track_indicator_type_code]
   @track_slms_indicator.variety_type = params[:track_slms_indicator][:variety_type]
   @track_slms_indicator.commodity_code = params[:track_slms_indicator][:commodity_code]
   @track_slms_indicator.variety_code = params[:track_slms_indicator][:variety_code]
   @track_slms_indicator.season_code = params[:track_slms_indicator][:season_code]
   @track_slms_indicator.track_slms_indicator_code = params[:track_slms_indicator][:track_slms_indicator_code]
   @track_slms_indicator.track_slms_indicator_description = params[:track_slms_indicator][:track_slms_indicator_description]
   @track_slms_indicator.date_from = params[:track_slms_indicator][:date_from]
   @track_slms_indicator.date_to = params[:track_slms_indicator][:date_to]
   @track_slms_indicator.track_variable_1 = params[:track_slms_indicator][:track_variable_1]
   @track_slms_indicator.track_variable_2 = params[:track_slms_indicator][:track_variable_2]
	 #@track_slms_indicator.variety_id = TrackSlmsIndicator.get_variety_id(@track_slms_indicator.variety_type,@track_slms_indicator.variety_code)
   if(params[:track_slms_indicator][:variety_type] == "rmt_variety")
     puts "rmt_variety"
     @track_slms_indicator.marketing_variety_code = params[:track_slms_indicator][:marketing_variety_code] #OR params[:track_slms_indicator][:variety_code]
     @track_slms_indicator.rmt_variety_code = params[:track_slms_indicator][:variety_code]
   elsif(params[:track_slms_indicator][:variety_type] == "marketing_variety")
     puts "marketing_variety"
     @track_slms_indicator.marketing_variety_code = params[:track_slms_indicator][:variety_code]
     @track_slms_indicator.rmt_variety_code = nil#can lookup using params[:track_slms_indicator][:variety_code]
   end
	 if @track_slms_indicator.save
    	 if params[:track_slms_indicator][:variety_type] == "rmt_variety"
    	     if params[:track_slms_indicator][:marketing_variety_code] != ""
             @track_slms_indicator.set_track_slms_variety
#    	         @track_slms_variety = TrackSlmsVariety.new
#    	         @track_slms_variety.rmt_variety_id = @track_slms_indicator.variety.id
#    	         @track_slms_variety.marketing_variety_id = TrackSlmsIndicator.get_required_marketing_variety_id(@track_slms_indicator.marketing_variety_code)
#    	         @track_slms_variety.season_id = @track_slms_indicator.season.id
#    	         @track_slms_variety.track_indicator_type_id = @track_slms_indicator.track_indicator_type.id
#    	         @track_slms_variety.track_slms_indicator_id = @track_slms_indicator.id
#    	         @track_slms_variety.save
    	     end
    	 end
		 redirect_to_index("'new record created successfully'","'create successful'")
	else 
		@is_create_retry = true
		render_new_track_slms_indicator
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_track_slms_indicator
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new track_slms_indicator'"%> 

		<%= build_track_slms_indicator_form(@track_slms_indicator,'create_track_slms_indicator','create_track_slms_indicator',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_track_slms_indicator
	 id = params[:id]
	 if id && @track_slms_indicator = TrackSlmsIndicator.find(id)
		render_edit_track_slms_indicator

	 end
end


def render_edit_track_slms_indicator
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit track_slms_indicator'"%> 

		<%= build_track_slms_indicator_form(@track_slms_indicator,'update_track_slms_indicator','update_track_slms_indicator',true)%>

		}, :layout => 'content'
end
 
def update_track_slms_indicator
 begin

	if params[:page]
		session[:track_slms_indicators_page] = params['page']
		render_list_track_slms_indicators
		return
	end
 
		@current_page = session[:track_slms_indicators_page]
	 id = params[:track_slms_indicator][:id]
	 if id && @track_slms_indicator = TrackSlmsIndicator.find(id)
     params[:track_slms_indicator][:variety_type] = session[:track_slms_indicator_form][:variety_type_combo_selection] if !params[:track_slms_indicator][:variety_type]
     @track_slms_indicator.track_indicator_type_code = params[:track_slms_indicator][:track_indicator_type_code]
     @track_slms_indicator.variety_type = params[:track_slms_indicator][:variety_type]
     @track_slms_indicator.commodity_code = params[:track_slms_indicator][:commodity_code]
     @track_slms_indicator.variety_code = params[:track_slms_indicator][:variety_code]
     @track_slms_indicator.season_code = params[:track_slms_indicator][:season_code]
     @track_slms_indicator.track_slms_indicator_code = params[:track_slms_indicator][:track_slms_indicator_code]
     @track_slms_indicator.track_slms_indicator_description = params[:track_slms_indicator][:track_slms_indicator_description]
     @track_slms_indicator.date_from = params[:track_slms_indicator][:date_from]
     @track_slms_indicator.date_to = params[:track_slms_indicator][:date_to]
     @track_slms_indicator.track_variable_1 = params[:track_slms_indicator][:track_variable_1]
     @track_slms_indicator.track_variable_2 = params[:track_slms_indicator][:track_variable_2]
     
      if(params[:track_slms_indicator][:variety_type] == "rmt_variety")
        puts "rmt_variety"
        @track_slms_indicator.marketing_variety_code = params[:track_slms_indicator][:marketing_variety_code] if params[:track_slms_indicator][:marketing_variety_code]
        @track_slms_indicator.rmt_variety_code = params[:track_slms_indicator][:variety_code]
      elsif(params[:track_slms_indicator][:variety_type] == "marketing_variety")
        puts "marketing_variety"
        @track_slms_indicator.marketing_variety_code = params[:track_slms_indicator][:variety_code]
        @track_slms_indicator.rmt_variety_code = nil#can lookup using params[:track_slms_indicator][:variety_code]
      end
      
		 if @track_slms_indicator.update #_attributes(params[:track_slms_indicator])
       if params[:track_slms_indicator][:variety_type] == "rmt_variety"
    	     if params[:track_slms_indicator][:marketing_variety_code] != ""
             @track_slms_indicator.set_track_slms_variety
#    	         @track_slms_variety = TrackSlmsVariety.find_by_track_slms_indicator_id(@track_slms_indicator.id)
#    	         @track_slms_variety.rmt_variety_id = @track_slms_indicator.variety.id
#    	         @track_slms_variety.marketing_variety_id = TrackSlmsIndicator.get_required_marketing_variety_id(@track_slms_indicator.marketing_variety_code)
#    	         @track_slms_variety.season_id = @track_slms_indicator.season.id
#    	         @track_slms_variety.track_indicator_type_id = @track_slms_indicator.track_indicator_type.id
#    	         @track_slms_variety.update
    	     end
    	 end
			@track_slms_indicators = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_track_slms_indicators
	 else
			 render_edit_track_slms_indicator

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
end

def track_slms_indicator_variety_type_changed
    @variety_type = get_selected_combo_value(params)
    session[:track_slms_indicator_form][:variety_type_combo_selection] = @variety_type
#    session[:variety_type] = Hash.new
#    session[:variety_type].store("v_type", variety_type)
#    @commodity_codes = Commodity.find_by_sql("select distinct commodity_code from commodities").map{|g| [g.commodity_code]}
#    @commodity_codes.unshift("<empty>")
#    @marketing_variety_codes = MarketingVariety.find_by_sql("select distinct marketing_variety_code from marketing_varieties").map{|g| [g.marketing_variety_code]}
#    @marketing_variety_codes.unshift("<empty>")
#
#     if variety_type == "rmt_variety"
#          render :inline => %{
#            		<%= select('track_slms_indicator','marketing_variety_code',@marketing_variety_codes)%>
#
#        		   }
#     else
#          render :inline => %{
#                    <font color = 'blue'><b>N/A :(must select rmt_variety)</b></font>
#                }
#     end
      render :inline=>%{
        <%@content = "<label class='label_field' style='width : 100px;'>#{@variety_type}</label>"%>
        <script>
          <%= update_element_function(
                  "variety_type_cell", :action=>:update,
                  :content=>@content)%>
        </script>
      }


end
 
def track_slms_indicator_commodity_code_changed
    commodity_code = get_selected_combo_value(params)
    session[:track_slms_indicator_form][:commodity_code_combo_selection] = commodity_code
    @season_codes = Season.get_season_codes_for_commodity_code(commodity_code)
    @variety_type = session[:track_slms_indicator_form][:variety_type_combo_selection]
    @marketing_variety_codes = MarketingVariety.find_by_sql("select distinct marketing_variety_code from marketing_varieties where commodity_code='#{commodity_code}'").map{|g| [g.marketing_variety_code]}
    @marketing_variety_codes.unshift(["<empty>"])

    @variety_codes = ["<empty>"]
    if @variety_type == "marketing_variety"
        @variety_codes = MarketingVariety.find_by_sql("select distinct marketing_variety_code from marketing_varieties where commodity_code = '#{commodity_code}'").map{|g| [g.marketing_variety_code]}        
    elsif @variety_type == "rmt_variety"
        @variety_codes = RmtVariety.find_by_sql("select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}'").map{|g| [g.rmt_variety_code]}        
    end
 
    #	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
                <% variety_code_content = select('track_slms_indicator', 'variety_code', @variety_codes)%>
                <% season_code_content = select('track_slms_indicator', 'season_code', @season_codes)%>
                <%
                  if(@variety_type == 'marketing_variety' || @variety_type == nil)
                    marketing_variety_code_content = "<font color = 'blue'><b>N/A :(must select rmt_variety)</b></font>"
                  elsif(@variety_type == 'rmt_variety')
                    marketing_variety_code_content = select('track_slms_indicator','marketing_variety_code',@marketing_variety_codes)
                  end
                %>

                <script>
                
                    <%= update_element_function(
                    'variety_code_cell', :action => :update,
                    :content => variety_code_content) %>
                    
                    <%= update_element_function(
                    'season_code_cell', :action => :update,
                    :content => season_code_content) %>

                    <%= update_element_function(
                    'marketing_variety_code_cell', :action => :update,
                    :content => marketing_variety_code_content) %>
                </script>
          }
end

#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(farms)
#	-----------------------------------------------------------------------------------------------------------
def track_slms_indicator_track_indicator_type_code_search_combo_changed
    track_indicator_type_code = get_selected_combo_value(params)
    session[:track_slms_indicator_search_form][:track_indicator_type_code_combo_selection] = track_indicator_type_code
    @variety_types = TrackSlmsIndicator.find_by_sql("select distinct variety_type from track_slms_indicators where track_indicator_type_code = '#{track_indicator_type_code}'").map{|g|[g.variety_type]}
    @variety_types.unshift("<empty>")
    
    #	render (inline) the html to replace the contents of the td that contains the dropdown 
    #puts session[:track_slms_indicator_search_form][:variety_type_observer].to_s
    render :inline => %{
                <%= select('track_slms_indicator', 'variety_type', @variety_types)%>
                <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_track_slms_indicator_variety_type'/>
                <%= observe_field('track_slms_indicator_variety_type',:update => 'commodity_code_cell',:url => {:action => session[:track_slms_indicator_search_form][:variety_type_observer][:remote_method]},:loading => "show_element('img_track_slms_indicator_variety_type');",:complete => session[:track_slms_indicator_search_form][:variety_type_observer][:on_completed_js])%>
              }
end

def track_slms_indicator_variety_type_search_combo_changed
    variety_type = get_selected_combo_value(params)
    session[:track_slms_indicator_search_form][:variety_type_combo_selection] = variety_type
    @commodity_codes = TrackSlmsIndicator.find_by_sql("select distinct commodity_code from track_slms_indicators where variety_type = '#{variety_type}'").map{|g|[g.commodity_code]}

    #	render (inline) the html to replace the contents of the td that contains the dropdown 
    render :inline => %{
            <%= select('track_slms_indicator', 'commodity_code', @commodity_codes)%>
            <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_track_slms_indicator_commodity_code'/>
            <%= observe_field('track_slms_indicator_commodity_code',:update => 'variety_code_cell',:url => {:action => session[:track_slms_indicator_search_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_track_slms_indicator_commodity_code');",:complete => session[:track_slms_indicator_search_form][:commodity_code_observer][:on_completed_js])%>
      }
end

def track_slms_indicator_commodity_code_search_combo_changed
    commodity_code = get_selected_combo_value(params)
    session[:track_slms_indicator_search_form][:commodity_code_combo_selection] = commodity_code
    @variety_codes = TrackSlmsIndicator.find_by_sql("select distinct variety_code from track_slms_indicators where commodity_code = '#{commodity_code}'").map{|g|[g.variety_code]}
    
    #	render (inline) the html to replace the contents of the td that contains the dropdown 
    render :inline => %{
            <%= select('track_slms_indicator', 'variety_code', @variety_codes)%>
            <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_track_slms_indicator_variety_code'/>
            <%= observe_field('track_slms_indicator_variety_code',:update => 'season_code_cell',:url => {:action => session[:track_slms_indicator_search_form][:variety_code_observer][:remote_method]},:loading => "show_element('img_track_slms_indicator_variety_code');",:complete => session[:track_slms_indicator_search_form][:variety_code_observer][:on_completed_js])%>
      }
end

def track_slms_indicator_variety_code_search_combo_changed
    variety_code = get_selected_combo_value(params)
    session[:track_slms_indicator_search_form][:variety_code_combo_selection] = variety_code
    @season_codes = TrackSlmsIndicator.find_by_sql("select distinct season_code from track_slms_indicators where variety_code = '#{variety_code}'").map{|g|[g.season_code]}

    #	render (inline) the html to replace the contents of the td that contains the dropdown 
    render :inline => %{
            <%= select('track_slms_indicator', 'season_code', @season_codes)%>
            <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_track_slms_indicator_season_code'/>
            <%= observe_field('track_slms_indicator_season_code',:update => 'track_slms_indicator_code_cell',:url => {:action => session[:track_slms_indicator_search_form][:season_code_observer][:remote_method]},:loading => "show_element('img_track_slms_indicator_season_code');",:complete => session[:track_slms_indicator_search_form][:season_code_observer][:on_completed_js])%>
      }
end

def track_slms_indicator_season_code_search_combo_changed
    season_code = get_selected_combo_value(params)
    session[:track_slms_indicator_search_form][:season_code_combo_selection] = season_code
    variety_code = session[:track_slms_indicator_search_form][:variety_code_combo_selection]
    commodity_code = session[:track_slms_indicator_search_form][:commodity_code_combo_selection]
    variety_type = session[:track_slms_indicator_search_form][:variety_type_combo_selection]
    track_indicator_type_code = session[:track_slms_indicator_search_form][:track_indicator_type_code_combo_selection]
    @track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql("select distinct track_slms_indicator_code from track_slms_indicators where season_code = '#{season_code}' and variety_code = '#{variety_code}' and commodity_code = '#{commodity_code}' and variety_type = '#{variety_type}' and track_indicator_type_code = '#{track_indicator_type_code}'").map{|g|[g.track_slms_indicator_code]}

    #	render (inline) the html to replace the contents of the td that contains the dropdown 
    render :inline => %{
            <%= select('track_slms_indicator', 'track_slms_indicator_code', @track_slms_indicator_codes)%>
       }
end


def run_productions_report
   build_remote_search_engine_form("production_runs.yml", "render_report_grid")
   dm_session[:redirect] = true
end

def render_report_grid
  render_generic_grid
end

#============
#END TRACK SLMS INDICATORS
#=============

def gtin_target_markets
  @gtin_target_markets = GtinTargetMarket.find_all_by_gtin_id(params[:id])
  gtin = Gtin.find(params[:id].to_i)
  session[:gtin] = gtin.id
  @actions = true
  if @gtin_target_markets.length == 0
    @gtin_target_markets = Array.new()
    @gtin_target_markets[0] = {"gtin_code"=>"","target_market_code"=>"","id"=>""}
    @actions = false
  end

  url =  request.host_with_port + "/" + request.path_parameters['controller'].to_s + "/new_gtin_target_market/" + gtin.id.to_s
  link = "<a style=\"text-decoration:underline;cursor:pointer;padding-bottom:200px\" id=\"#{url}\" onclick=\"javascript:parent.call_open_window(this);\" >new target market</a>"
  @content_header_caption = "'target markets for gtin : #{gtin.gtin_code} " + link + " '"
  render_list_gtin_target_markets
end

def render_list_gtin_target_markets
    render :inline => %{
      <% grid            = build_gtin_target_markets_grid(@gtin_target_markets,@actions) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def new_gtin_target_market
  gtin = Gtin.find(params[:id])
  session[:gtin] = gtin.id
  @gtin_code = gtin.gtin_code
  session[:gtin_code] = @gtin_code
  render :inline=>%{
                    <%= build_new_gtin_target_market_from(@gtin_target_market,'create_new_gtin_target_market','create',@gtin_code)%>
                    },:layout=>'content'
end

def create_new_gtin_target_market
  @gtin_target_market = GtinTargetMarket.find_by_gtin_code_and_target_market_code(session[:gtin_code],params[:gtin_target_market][:target_market_code])
  if(@gtin_target_market)
    render :inline=>%{
                      <script>
                        window.close();
                      </script>
                      },:layout=>'content'
  else
    @gtin_target_market = GtinTargetMarket.new(params[:gtin_target_market])
    @gtin_target_market.gtin_id = session[:gtin]
    @gtin_target_market.gtin_code = session[:gtin_code]
    @tm_url =  "http://" + request.host_with_port + "/" + request.path_parameters['controller'].to_s + "/gtin_target_markets/" + session[:gtin].to_s 
    puts @tm_url
    begin
      @gtin_target_market.save
      render :inline=>%{
                      <script>
                        window.close();
                        window.opener.location.href='<%=@tm_url%>';
                      </script>
                      },:layout=>'content'
    rescue
      raise $!
    end
  end
end

end
