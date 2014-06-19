class  RawMaterials::VarietiesController < ApplicationController
 
def program_name?
	"varieties"
end

def bypass_generic_security?
	true
end

#=========================
#VARIETY (INPUT OUTPUT MAP
#=========================

def list_varieties
	return if authorise_for_web('varieties','read') == false 

 	if params[:page]!= nil 

 		session[:varieties_page] = params['page']

		 render_list_varieties

		 return 
	else
		session[:varieties_page] = nil
	end

	list_query = "@variety_pages = Paginator.new self, Variety.count, @@page_size,@current_page
	 @varieties = Variety.find(:all,
				 :limit => @variety_pages.items_per_page,
				 :offset => @variety_pages.current.offset)"
	session[:query] = list_query
	render_list_varieties
end


def render_list_varieties
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:varieties_page] if session[:varieties_page]
	@current_page = params['page'] if params['page']
	@varieties =  eval(session[:query]) if !@varieties
	render :inline => %{
      <% grid            = build_variety_grid(@varieties,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all variety maps' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@variety_pages) if @variety_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_varieties_flat
	return if authorise_for_web('variety','read')== false
	@is_flat_search = true 
	render_variety_search_form
end

def render_variety_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  varieties'"%> 

		<%= build_variety_search_form(nil,'submit_varieties_search','submit_marketing_varieties_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def find_variety
	return if authorise_for_web('varieties','read')== false
 
	@is_flat_search = false 
	render_variety_search_form(true)
end

def render_variety_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  variety maps'"%> 

		<%= build_variety_search_form(nil,'submit_varieties_search','submit_varieties_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_varieties_search
	if params['page']
		session[:varieties_page] =params['page']
	else
		session[:varieties_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @varieties = dynamic_search(params[:variety] ,'varieties','Variety')
	else
		@varieties = eval(session[:query])
	end
	if @varieties.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_variety_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_varieties
		end

	else

		render_list_varieties
	end
end

 
def delete_variety
  begin
	return if authorise_for_web('varieties','delete')== false
	if params[:page]
		session[:varieties_page] = params['page']
		render_list_varieties
		return
	end
	id = params[:id]
	if id && variety = Variety.find(id)
		variety.destroy
		session[:alert] = " Record deleted."
		render_list_varieties
	end
 rescue
   handle_error("variety-map could not be deleted")
  end
end
 
def new_variety
	return if authorise_for_web('varieties','create')== false
		render_new_variety
end
 
def create_variety
  begin
	 @variety = Variety.new(params[:variety])
	 if @variety.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_variety
	 end
  rescue
   handle_error("variety-map could not be created")
  end
end

def render_new_variety
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new variety map'"%> 

		<%= build_variety_form(@variety,'create_variety','create_variety',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_variety
	return if authorise_for_web('varieties','edit')==false 
	 id = params[:id]
	 if id && @variety = Variety.find(id)
		render_edit_variety

	 end
end


def render_edit_variety
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit variety map'"%> 

		<%= build_variety_form(@variety,'update_variety','update_variety',true)%>

		}, :layout => 'content'
end
 
def update_variety
  begin
	if params[:page]
		session[:varieties_page] = params['page']
		render_list_varieties
		return
	end

		@current_page = session[:varieties_page]
	 id = params[:variety][:id]
	 if id && @variety = Variety.find(id)
		 if @variety.update_attributes(params[:variety])
			@varieties = eval(session[:query])
			render_list_varieties
	 else
			 render_edit_variety

		 end
	 end
  rescue
   handle_error("variety-map could not be updated")
  end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: commodity_id
#	---------------------------------------------------------------------------------
def variety_commodity_group_code_changed
	commodity_group_code = get_selected_combo_value(params)
	session[:variety_form][:commodity_group_code_combo_selection] = commodity_group_code
	@commodity_codes = Variety.commodity_codes_for_commodity_group_code(commodity_group_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('variety','commodity_code',@commodity_codes)%>
        <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_variety_commodity_code'/>
		<%= observe_field('variety_commodity_code',:update => 'ajax_distributor_cell',:url => {:action => session[:variety_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_variety_commodity_code');",:complete => session[:variety_form][:commodity_code_observer][:on_completed_js])%>
		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(varieties)
#	-----------------------------------------------------------------------------------------------------------
def variety_commodity_group_code_search_combo_changed
	commodity_group_code = get_selected_combo_value(params)
	session[:variety_search_form][:commodity_group_code_combo_selection] = commodity_group_code
	@commodity_codes = Variety.find_by_sql("Select distinct commodity_code from varieties where commodity_group_code = '#{commodity_group_code}'").map{|g|[g.commodity_code]}
	@commodity_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('variety','commodity_code',@commodity_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_variety_commodity_code'/>
		<%= observe_field('variety_commodity_code',:update => 'rmt_variety_code_cell',:url => {:action => session[:variety_search_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_variety_commodity_code');",:complete => session[:variety_search_form][:commodity_code_observer][:on_completed_js])%>
		}

end

 def variety_commodity_code_changed
  
  commodity_code = get_selected_combo_value(params)
  @rmt_variety_codes = Variety.find_by_sql("select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}'").map{|v|[v.rmt_variety_code]}
  @marketing_variety_codes = Variety.find_by_sql("select distinct marketing_variety_code from marketing_varieties where commodity_code = '#{commodity_code}'").map{|v|[v.marketing_variety_code]}
  
  
   render :inline => %{
    <% rmt_variety_content = select('variety','rmt_variety_code',@rmt_variety_codes) %>
    <% marketing_variety_content = select('variety','marketing_variety_code',@marketing_variety_codes) %>
   <script>
    <%= update_element_function(
        "rmt_variety_code_cell", :action => :update,
        :content => rmt_variety_content) %>
    
    <%= update_element_function(
        "marketing_variety_code_cell", :action => :update,
        :content => marketing_variety_content) %>    
   
   </script>
  }
  
  end

def variety_commodity_code_search_combo_changed
	commodity_code = get_selected_combo_value(params)
	session[:variety_search_form][:commodity_code_combo_selection] = commodity_code
	commodity_group_code = 	session[:variety_search_form][:commodity_group_code_combo_selection]
	@rmt_variety_codes = Variety.find_by_sql("Select distinct rmt_variety_code from varieties where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.rmt_variety_code]}
	@rmt_variety_codes.unshift("<empty>")
    
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('variety','rmt_variety_code',@rmt_variety_codes)%>

		}

end





#===================
#RMT VARIETIES
#===================
def list_rmt_varieties
	return if authorise_for_web('varieties','read') == false 

 	if params[:page]!= nil 

 		session[:rmt_varieties_page] = params['page']

		 render_list_rmt_varieties

		 return 
	else
		session[:rmt_varieties_page] = nil
	end

	list_query = "@rmt_variety_pages = Paginator.new self, RmtVariety.count, @@page_size,@current_page
	 @rmt_varieties = RmtVariety.find(:all,
				 :limit => @rmt_variety_pages.items_per_page,
				 :offset => @rmt_variety_pages.current.offset)"
	session[:query] = list_query
	render_list_rmt_varieties
end


def render_list_rmt_varieties
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:rmt_varieties_page] if session[:rmt_varieties_page]
	@current_page = params['page'] if params['page']
	@rmt_varieties =  eval(session[:query]) if !@rmt_varieties
	render :inline => %{
      <% grid            = build_rmt_variety_grid(@rmt_varieties,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all rmt_varieties' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@rmt_variety_pages) if @rmt_variety_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_rmt_varieties_flat
	return if authorise_for_web('rmt_variety','read')== false
	@is_flat_search = true 
	render_rmt_variety_search_form
end

def render_rmt_variety_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  rmt_varieties'"%> 

		<%= build_rmt_variety_search_form(nil,'submit_rmt_varieties_search','submit_marketing_varieties_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def find_rmt_variety
	return if authorise_for_web('varieties','read')== false
 
	@is_flat_search = false 
	render_rmt_variety_search_form(true)
end

def render_rmt_variety_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  rmt_varieties'"%> 

		<%= build_rmt_variety_search_form(nil,'submit_rmt_varieties_search','submit_rmt_varieties_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_rmt_varieties_search
	if params['page']
		session[:rmt_varieties_page] =params['page']
	else
		session[:rmt_varieties_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @rmt_varieties = dynamic_search(params[:rmt_variety] ,'rmt_varieties','RmtVariety')
	else
		@rmt_varieties = eval(session[:query])
	end
	if @rmt_varieties.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_rmt_variety_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_rmt_varieties
		end

	else

		render_list_rmt_varieties
	end
end

 
def delete_rmt_variety
  begin
	return if authorise_for_web('varieties','delete')== false
	if params[:page]
		session[:rmt_varieties_page] = params['page']
		render_list_rmt_varieties
		return
	end
	id = params[:id]
	if id && rmt_variety = RmtVariety.find(id)
		rmt_variety.destroy
		session[:alert] = " Record deleted."
		render_list_rmt_varieties
	end
  rescue
   handle_error("raw material variety could not be deleted")
  end
end
 
def new_rmt_variety
	return if authorise_for_web('varieties','create')== false
		render_new_rmt_variety
end
 
def create_rmt_variety
  begin
	 @rmt_variety = RmtVariety.new(params[:rmt_variety])
	 if @rmt_variety.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_rmt_variety
	 end
  rescue
   handle_error("raw material variety could not be created")
  end
end

def render_new_rmt_variety
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new rmt_variety'"%> 

		<%= build_rmt_variety_form(@rmt_variety,'create_rmt_variety','create_rmt_variety',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_rmt_variety
	return if authorise_for_web('varieties','edit')==false 
	 id = params[:id]
	 if id && @rmt_variety = RmtVariety.find(id)
		render_edit_rmt_variety

	 end
end


def render_edit_rmt_variety
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit rmt_variety'"%> 

		<%= build_rmt_variety_form(@rmt_variety,'update_rmt_variety','update_rmt_variety',true)%>

		}, :layout => 'content'
end
 
def update_rmt_variety
  begin
	if params[:page]
		session[:rmt_varieties_page] = params['page']
		render_list_rmt_varieties
		return
	end

		@current_page = session[:rmt_varieties_page]
	 id = params[:rmt_variety][:id]
	 if id && @rmt_variety = RmtVariety.find(id)
		 if @rmt_variety.update_attributes(params[:rmt_variety])
			@rmt_varieties = eval(session[:query])
			render_list_rmt_varieties
	 else
			 render_edit_rmt_variety

		 end
	 end
  rescue
   handle_error("raw material variety could not be updated")
  end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: commodity_id
#	---------------------------------------------------------------------------------
def rmt_variety_commodity_group_code_changed
	commodity_group_code = get_selected_combo_value(params)
	session[:rmt_variety_form][:commodity_group_code_combo_selection] = commodity_group_code
	@commodity_codes = RmtVariety.commodity_codes_for_commodity_group_code(commodity_group_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_variety','commodity_code',@commodity_codes)%>

   <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_variety_commodity_code'/>
    <%= observe_field('rmt_variety_commodity_code',:update => 'variety_group_code_cell',:url => {:action => session[:rmt_variety_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_rmt_variety_commodity_code');",:complete => session[:rmt_variety_form][:commodity_code_observer][:on_completed_js])%>
		}
end

def rmt_variety_commodity_code_changed
  commodity_group_code = get_selected_combo_value(params)
	session[:rmt_variety_form][:commodity_group_code_combo_selection] = commodity_group_code
  @variety_group_codes = VarietyGroup.find_by_sql("Select distinct variety_group_code from variety_groups where commodity_code = '#{commodity_group_code}'").map{|g|[g.variety_group_code]}
	@variety_group_codes.unshift("<empty>")
  render :inline => %{
		<%= select('rmt_variety','variety_group_code',@variety_group_codes)%>
}
end

 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(rmt_varieties)
#	-----------------------------------------------------------------------------------------------------------
def rmt_variety_commodity_group_code_search_combo_changed
	commodity_group_code = get_selected_combo_value(params)
	session[:rmt_variety_search_form][:commodity_group_code_combo_selection] = commodity_group_code
	@commodity_codes = RmtVariety.find_by_sql("Select distinct commodity_code from rmt_varieties where commodity_group_code = '#{commodity_group_code}'").map{|g|[g.commodity_code]}
	@commodity_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_variety','commodity_code',@commodity_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rmt_variety_commodity_code'/>
		<%= observe_field('rmt_variety_commodity_code',:update => 'rmt_variety_code_cell',:url => {:action => session[:rmt_variety_search_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_rmt_variety_commodity_code');",:complete => session[:rmt_variety_search_form][:commodity_code_observer][:on_completed_js])%>
		}

end

 
def rmt_variety_commodity_code_search_combo_changed
	commodity_code = get_selected_combo_value(params)
	session[:rmt_variety_search_form][:commodity_code_combo_selection] = commodity_code
	commodity_group_code = 	session[:rmt_variety_search_form][:commodity_group_code_combo_selection]
	@rmt_variety_codes = RmtVariety.find_by_sql("Select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.rmt_variety_code]}
	@rmt_variety_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('rmt_variety','rmt_variety_code',@rmt_variety_codes)%>

		}

end
#======================
#MARKETING VARIETY CODE
#======================

def list_marketing_varieties
	return if authorise_for_web('varieties','read') == false 

 	if params[:page]!= nil 

 		session[:marketing_varieties_page] = params['page']

		 render_list_marketing_varieties

		 return 
	else
		session[:marketing_varieties_page] = nil
	end

	list_query = "@marketing_variety_pages = Paginator.new self, MarketingVariety.count, @@page_size,@current_page
	 @marketing_varieties = MarketingVariety.find(:all,
				 :limit => @marketing_variety_pages.items_per_page,
				 :offset => @marketing_variety_pages.current.offset)"
	session[:query] = list_query
	render_list_marketing_varieties
end


def render_list_marketing_varieties
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:marketing_varieties_page] if session[:marketing_varieties_page]
	@current_page = params['page'] if params['page']
	@marketing_varieties =  eval(session[:query]) if !@marketing_varieties
	render :inline => %{
      <% grid            = build_marketing_variety_grid(@marketing_varieties,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all marketing_varieties' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@marketing_variety_pages) if @marketing_variety_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_marketing_varieties_flat
	return if authorise_for_web('marketing_variety','read')== false
	@is_flat_search = true 
	render_marketing_variety_search_form
end

def render_marketing_variety_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  marketing_varieties'"%> 

		<%= build_marketing_variety_search_form(nil,'submit_marketing_varieties_search','submit_marketing_varieties_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def find_marketing_variety
	return if authorise_for_web('varieties','read')== false
 
	@is_flat_search = false 
	render_marketing_variety_search_form(true)
end

def render_marketing_variety_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  marketing_varieties'"%> 

		<%= build_marketing_variety_search_form(nil,'submit_marketing_varieties_search','submit_marketing_varieties_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_marketing_varieties_search
	if params['page']
		session[:marketing_varieties_page] =params['page']
	else
		session[:marketing_varieties_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @marketing_varieties = dynamic_search(params[:marketing_variety] ,'marketing_varieties','MarketingVariety')
	else
		@marketing_varieties = eval(session[:query])
	end
	if @marketing_varieties.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_marketing_variety_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_marketing_varieties
		end

	else

		render_list_marketing_varieties
	end
end

 
def delete_marketing_variety
  begin
	return if authorise_for_web('varieties','delete')== false
	if params[:page]
		session[:marketing_varieties_page] = params['page']
		render_list_marketing_varieties
		return
	end
	id = params[:id]
	if id && marketing_variety = MarketingVariety.find(id)
		marketing_variety.destroy
		session[:alert] = " Record deleted."
		render_list_marketing_varieties
	end
 rescue
   handle_error("marketing variety could not be deleted")
  end
end
 
def new_marketing_variety
	return if authorise_for_web('varieties','create')== false
		render_new_marketing_variety
end
 
def create_marketing_variety
  begin
	 @marketing_variety = MarketingVariety.new(params[:marketing_variety])
	 if @marketing_variety.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_marketing_variety
	 end
  rescue
   handle_error("marketing variety could not be created")
  end
end

def render_new_marketing_variety
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new marketing_variety'"%> 

		<%= build_marketing_variety_form(@marketing_variety,'create_marketing_variety','create_marketing_variety',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_marketing_variety
	return if authorise_for_web('varieties','edit')==false 
	 id = params[:id]
	 if id && @marketing_variety = MarketingVariety.find(id)
		render_edit_marketing_variety

	 end
end


def render_edit_marketing_variety
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit marketing_variety'"%> 

		<%= build_marketing_variety_form(@marketing_variety,'update_marketing_variety','update_marketing_variety',true)%>

		}, :layout => 'content'
end
 
def update_marketing_variety
  begin
  puts params.to_s
	if params[:page]
		session[:marketing_varieties_page] = params['page']
		render_list_marketing_varieties
		return
	end

		@current_page = session[:marketing_varieties_page]
	 id = params[:marketing_variety][:id]
	 if id && @marketing_variety = MarketingVariety.find(id)
		 if @marketing_variety.update_attributes(params[:marketing_variety])
			@marketing_varieties = eval(session[:query])
			render_list_marketing_varieties
	 else
			 render_edit_marketing_variety

		 end
	 end
  rescue
   handle_error("marketing variety could not be updated")
  end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: commodity_id
#	---------------------------------------------------------------------------------
def marketing_variety_commodity_group_code_changed
	commodity_group_code = get_selected_combo_value(params)
	session[:marketing_variety_form][:commodity_group_code_combo_selection] = commodity_group_code
	@commodity_codes = MarketingVariety.commodity_codes_for_commodity_group_code(commodity_group_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('marketing_variety','commodity_code',@commodity_codes)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(marketing_varieties)
#	-----------------------------------------------------------------------------------------------------------
def marketing_variety_commodity_group_code_search_combo_changed
	commodity_group_code = get_selected_combo_value(params)
	session[:marketing_variety_search_form][:commodity_group_code_combo_selection] = commodity_group_code
	@commodity_codes = MarketingVariety.find_by_sql("Select distinct commodity_code from marketing_varieties where commodity_group_code = '#{commodity_group_code}'").map{|g|[g.commodity_code]}
	@commodity_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('marketing_variety','commodity_code',@commodity_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_marketing_variety_commodity_code'/>
		<%= observe_field('track_indicator_commodity_code',:update => 'marketing_variety_code_cell',:url => {:action => session[:marketing_variety_search_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_marketing_variety_commodity_code');",:complete => session[:marketing_variety_search_form][:commodity_code_observer][:on_completed_js])%>
		}

end

#
#def marketing_variety_commodity_code_search_combo_changed
#	commodity_code = get_selected_combo_value(params)
#	session[:marketing_variety_search_form][:commodity_code_combo_selection] = commodity_code
#	commodity_group_code = 	session[:marketing_variety_search_form][:commodity_group_code_combo_selection]
#	@marketing_variety_codes = MarketingVariety.find_by_sql("Select distinct marketing_variety_code from marketing_varieties where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map{|g|[g.marketing_variety_code]}
#	@marketing_variety_codes.unshift("<empty>")
#
##	render (inline) the html to replace the contents of the td that contains the dropdown 
#	render :inline => %{
#		<%= select('marketing_variety','marketing_variety_code',@marketing_variety_codes)%>
#
#		}
#
#end



end
