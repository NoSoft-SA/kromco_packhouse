class Inventory::InventoryIssuesController < ApplicationController

  def program_name?
    "inventory_issues"
  end
  
  def bypass_generic_security?
	 true
  end
  
  def new_inventory_issue
     return if authorise_for_web(program_name?,'create') == false
     render_new_inventory_issue
  end
  
  def render_new_inventory_issue
     render :inline => %{
		<% @content_header_caption = "'create new inventory issue'"%> 

		<%= build_inventory_issue_form(@inventory_issue,'create_inventory_issue','create_inventory_issue',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def select_inventory_issue
    return if authorise_for_web(program_name?,'edit')==false
     id = params['id']
     if id && @inventory_issue = InventoryIssue.find(id)
        @ref_number = @inventory_issue.reference_number
        render :inline=> %{
            <script>
               if(window.opener)
               {
                   //alert(window.opener.frames.length);
                   //window.opener.frames[1].document.getElementById('asset_location_inventory_receipt')
                   if(window.opener.frames[1].document.getElementById('inventory_issue_reference_number'))
                   {
                      //alert("element found!");
                      //window.opener.frames[1].document.getElementById('asset_location_inventory_receipt').value = "<%= @ref_number %>";
                      window.opener.frames[1].document.getElementById('inventory_issue_reference_number').value = "<%= @ref_number %>";
                   }
                   else
                   {
                      alert("element not found!");
                   }
               }
               else
               {
                  alert("no support for this operation!");
               }
               window.close();
            </script>
        }
     end
  end
  
  def create_inventory_issue
     #puts params[:inventory_receipt].to_s
     begin
    	 @inventory_issue = InventoryIssue.new(params[:inventory_issue])
    	 if @inventory_issue.save
    	     #session[:inventory_receipt] = @inventory_receipt
    		 redirect_to_index("'new record created successfully'","'create successful'")
    	 else
    		@is_create_retry = true
    		render_new_inventory_issue
    	 end
    rescue
       handle_error("inventory_issue could not be created")
    end
    
  end
  
  def list_inventory_issues
    return if authorise_for_web(program_name?,'read') == false 
    
 	if params[:page]!= nil 

 		session[:inventory_issues_page] = params['page']

		 render_list_inventory_issues

		 return 
	else
		session[:inventory_issues_page] = nil
	end

	list_query = "@inventory_issues_pages = Paginator.new self, InventoryIssue.count, @@page_size,@current_page
	 @inventory_issues = InventoryIssue.find(:all,
				 :limit => @inventory_issues_pages.items_per_page,
				 :offset => @inventory_issues_pages.current.offset)"
	session[:query] = list_query
	render_list_inventory_issues
  end
  
  def render_list_inventory_issues
  	@can_edit = authorise(program_name?,'edit',session[:user_id])
  	@can_delete = authorise(program_name?,'delete',session[:user_id])
  	@current_page = session[:inventory_issues_page] if session[:inventory_issues_page]
  	@current_page = params['page'] if params['page']
  	@inventory_issues =  eval(session[:query]) if !@inventory_issues
    if session[:inventory_issue_lookup]
  	   @issue_lookup = true
  	else
  	   @issue_lookup = false
  	end
  	render :inline => %{
      		<% grid            = build_inventory_issues_grid(@inventory_issues,@can_edit,@can_delete, @issue_lookup)%>
      		<% grid.caption    = 'list of all inventory issues' %>
      		<% @header_content = grid.build_grid_data %>
      
      		<% @pagination = pagination_links(@inventory_issues_pages) if @inventory_issues_pages != nil %>
          <%= grid.render_html %>
      		<%= grid.render_grid %>
    	},:layout => 'content'
      session[:inventory_issue_lookup] = nil if session[:inventory_issue_lookup] != nil
  end
  
  def edit_inventory_issue
     return if authorise_for_web(program_name?,'edit')==false 
     id = params['id']
     if id && @inventory_issue = InventoryIssue.find(id)
        render_edit_inventory_issue
     else
     
     end
  end
  
  def render_edit_inventory_issue
     render :inline => %{
		<% @content_header_caption = "'edit inventory issue'"%> 

		<%= build_inventory_issue_form(@inventory_issue,'update_inventory_issue','update_inventory_issue',true,@is_create_retry)%>

		}, :layout => 'content'
  end
  
  def update_inventory_issue
      begin
    	if params[:page]
    		session[:inventory_issues_page] = params['page']
    		render_list_inventory_issues
    		return
    	end
    
    		@current_page = session[:inventory_issues_page]
    	 id = params[:inventory_issue][:id]
    	 if id && @inventory_issue = InventoryIssue.find(id)
    		 if @inventory_issue.update_attributes(params[:inventory_issue])
    			@inventory_issue = eval(session[:query])
    			flash[:notice] = 'inventory_issue record updated!'
    			render_list_inventory_issues
        	 else
        	     render_edit_inventory_issue
             end
    	 end
      rescue
         handle_error("inventory_issue not be updated")
       end
  end
  
  def delete_inventory_issue
     begin
    	return if authorise_for_web(program_name?,'delete')== false
    	if params[:page]
    		session[:inventory_issues_page] = params['page']
    		render_list_inventory_issues
    		return
    	end
    	id = params[:id]
    	if id && inventory_issue = InventoryIssue.find(id)
    		inventory_issue.destroy
    		session[:alert] = " Record deleted."
    		render_list_inventory_issues
    	end
      rescue
         handle_error("inventory_issue record could not be deleted")
      end
  end
  
  def search_inventory_issues_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_inventory_issue_search_form
end
  
  def search_inventory_issues_hierarchy
  	return if authorise_for_web(program_name?,'read')== false
   
  	@is_flat_search = false 
  	render_inventory_issue_search_form(true)
  end
  
  def render_inventory_issue_search_form(is_flat_search = nil)
  	session[:is_flat_search] = @is_flat_search
    # render (inline) the search form
  	render :inline => %{
  		<% @content_header_caption = "'search  inventory issues'"%> 
  
  		<%= build_inventory_issue_search_form(nil,'submit_inventory_issues_search','submit_inventory_issues_search',@is_flat_search)%>
  
  		}, :layout => 'content'
  end
  
  def submit_inventory_issues_search
  	if params['page']
  		session[:inventory_issues_page] =params['page']
  	else
  		session[:inventory_issues_page] = nil
  	end
  	@current_page = params['page']
  	if params[:page]== nil
  		 @inventory_issues = dynamic_search(params[:inventory_issue] ,'inventory_issues','InventoryIssue')
  	else
  		@inventory_issues = eval(session[:query])
  	end
  	if @inventory_issues.length == 0
  		if params[:page] == nil
  			flash[:notice] = 'no records were found for the query'
  			@is_flat_search = session[:is_flat_search].to_s
  			render_inventory_issue_search_form
  		else
  			flash[:notice] = 'There are no more records'
  			render_list_inventory_issues
  		end
  
  	else
  
  		render_list_inventory_issues
  	end
  end
  
  
  #==================================================
  #  Observer Methods for the combo boxes for ajax
  #  calls to the server
  #==================================================
  
  def inventory_issue_party_type_name_search_combo_changed
    party_type_name = get_selected_combo_value(params)
    session[:inventory_issue_form][:party_type_name_combo_selection] = party_type_name
    @party_names = PartiesRole.find_by_sql("select distinct party_name from parties where party_type_name='#{party_type_name}'").map{|g|[g.party_name]}
	@party_names.unshift("<empty>")
	render :inline=>%{
	    <%=select('inventory_issue','party_name',@party_names) %>
	    <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_inventory_issue_party_name'/>
            <%= observe_field('inventory_issue_party_name', :update=>'parties_role_name_cell', :url => {:action=>session[:inventory_issue_form][:party_name_observer][:remote_method]}, :loading=>"show_element('img_inventory_issue_party_name');", :complete=>session[:inventory_issue_form][:party_name_observer][:on_completed_js])%>
	}
  end
  
  def inventory_issue_party_name_search_combo_changed
    party_name = get_selected_combo_value(params)
    session[:inventory_issue_form][:party_name_combo_selection] = party_name
    party_type_name = session[:inventory_issue_form][:party_type_name_combo_selection]
    @role_names = PartiesRole.find_by_sql("select distinct role_name from parties_roles where party_type_name='#{party_type_name}' and party_name='#{party_name}'").map{|g|[g.role_name]}
	@role_names.unshift("<empty>")
	render :inline=>%{
	    <%=select('inventory_issue','parties_role_name',@role_names) %>
	}
  end
  
  def inventory_issue_pack_material_type_code_changed
    pack_material_type_code = get_selected_combo_value(params)
    session[:inventory_issue_form][:pack_material_type_code_combo_selection] = pack_material_type_code
    pack_material_type = PackMaterialType.find_by_pack_material_type_code(pack_material_type_code)
    @pack_material_sub_type_codes = PackMaterialSubType.find_by_sql("select distinct pack_material_subtype_code from pack_material_sub_types where pack_material_type_id='#{pack_material_type.id}'").map{|g|[g.pack_material_subtype_code]}
  	@pack_material_sub_type_codes.unshift("<empty>")
  	render :inline=>%{
  	    <%=select('inventory_issue','pack_material_sub_type_code',@pack_material_sub_type_codes) %>
  	    <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_inventory_issue_pack_material_sub_type_code'/>
        <%= observe_field('inventory_issue_pack_material_sub_type_code', :update=>'pack_material_product_code_cell', :url => {:action=>session[:inventory_issue_form][:pack_material_sub_type_code_observer][:remote_method]}, :loading=>"show_element('img_inventory_issue_pack_material_sub_type_code');", :complete=>session[:inventory_issue_form][:pack_material_sub_type_code_observer][:on_completed_js])%>
  	}
  end
  
  def inventory_issue_pack_material_sub_type_code_changed
    pack_material_sub_type_code = get_selected_combo_value(params)
    session[:inventory_issue_form][:pack_material_sub_type_code_combo_selection] = pack_material_sub_type_code
    pack_material_type = PackMaterialType.find_by_pack_material_type_code(session[:inventory_issue_form][:pack_material_type_code_combo_selection])
    pack_material_sub_type = PackMaterialSubType.find_by_pack_material_subtype_code(pack_material_sub_type_code)
    @pack_material_product_codes = PackMaterialProduct.find_by_sql("select distinct pack_material_product_code from pack_material_products where pack_material_type_id='#{pack_material_type.id}' and pack_material_sub_type_id='#{pack_material_sub_type.id}'").map{|g|[g.pack_material_product_code]}
  	@pack_material_product_codes.unshift("<empty>")
  	render :inline=>%{
  	    <%=select('inventory_issue','pack_material_product_code',@pack_material_product_codes) %>
  	}
  end
  
  def inventory_issue_inventory_issue_type_code_search_combo_changed
     inventory_issue_type_code = get_selected_combo_value(params)
     session[:inventory_issue_search_form][:inventory_issue_type_code_combo_selection] = inventory_issue_type_code
     @reference_numbers = InventoryIssue.find_by_sql("select distinct reference_number from inventory_issues where inventory_issue_type_code='#{inventory_issue_type_code}'").map{|g|[g.reference_number]}
     @reference_numbers.unshift("<empty>")
     render :inline => %{
         <%= select('inventory_issue','reference_number',@reference_numbers) %>
         <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_inventory_issue_reference_number'/>
         <%= observe_field('inventory_issue_reference_number', :update=>'farm_code_cell', :url=> {:action => session[:inventory_issue_search_form][:reference_number_observer][:remote_method]}, :loading=>"show_element('img_inventory_issue_reference_number');", :complete=>session[:inventory_issue_search_form][:reference_number_observer][:on_completed_js]) %>
     }
  end
  
  def inventory_issue_reference_number_search_combo_changed
     reference_number = get_selected_combo_value(params)
     session[:inventory_issue_search_form][:reference_number_combo_selection] = reference_number
     inventory_issue_type_code = session[:inventory_issue_search_form][:inventory_issue_type_code_combo_selection]
     @farm_codes = InventoryIssue.find_by_sql("select distinct farm_code from inventory_issues where inventory_issue_type_code='#{inventory_issue_type_code}' and reference_number='#{reference_number}'").map{|g|[g.farm_code]}
     @farm_codes.unshift("<empty>");
     render :inline => %{
         <%= select('inventory_issue','farm_code',@farm_codes) %>
         <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_inventory_issue_farm_code'/>
         <%= observe_field('inventory_issue_farm_code', :update=>'truck_code_cell', :url=> {:action => session[:inventory_issue_search_form][:farm_code_observer][:remote_method]}, :loading=>"show_element('img_inventory_issue_farm_code');", :complete=>session[:inventory_issue_search_form][:farm_code_observer][:on_completed_js]) %>
     }
  end
  
  def inventory_issue_farm_code_search_combo_changed
     farm_code = get_selected_combo_value(params)
     inventory_issue_type_code = session[:inventory_issue_search_form][:inventory_issue_type_code_combo_selection]
     reference_number = session[:inventory_issue_search_form][:reference_number_combo_selection]
     @truck_codes = InventoryIssue.find_by_sql("select distinct truck_code from inventory_issues where inventory_issue_type_code='#{inventory_issue_type_code}' and reference_number='#{reference_number}' and farm_code='#{farm_code}'").map{|g|[g.truck_code]}
     @truck_codes.unshift("<empty>")
     render :inline => %{
          <%= select('inventory_issue','truck_code',@truck_codes) %>
     }
  end

end
