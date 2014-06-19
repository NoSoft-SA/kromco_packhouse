class Inventory::InventoryReceiptsController < ApplicationController

  def program_name?
    "inventory_receipts"
  end
  
  def bypass_generic_security?
	 true
  end
  
  def new_inventory_receipt
     return if authorise_for_web(program_name?,'create') == false
     render_new_inventory_receipt
  end
  
  def render_new_inventory_receipt
     render :inline => %{
		<% @content_header_caption = "'create new inventory receipt'"%> 

		<%= build_inventory_receipt_form(@inventory_receipt,'create_inventory_receipt','create_receipt',false,@is_create_retry)%>

		}, :layout => 'content'
  end
  
  def create_inventory_receipt
     #puts params[:inventory_receipt].to_s
     begin
    	 @inventory_receipt = InventoryReceipt.new(params[:inventory_receipt])
    	 if @inventory_receipt.save
    	     #session[:inventory_receipt] = @inventory_receipt
    		 redirect_to_index("'new record created successfully'","'create successful'")
    	 else
    		@is_create_retry = true
    		render_new_inventory_receipt
    	 end
    rescue
       handle_error("inventory_receipt could not be created")
    end
    
  end
  
  def list_inventory_receipts
    return if authorise_for_web(program_name?,'read') == false 
    
 	if params[:page]!= nil 

 		session[:inventory_receipts_page] = params['page']

		 render_list_inventory_receipts

		 return 
	else
		session[:inventory_receipts_page] = nil
	end

	list_query = "@inventory_receipts_pages = Paginator.new self, InventoryReceipt.count, @@page_size,@current_page
	 @inventory_receipts = InventoryReceipt.find(:all,
				 :limit => @inventory_receipts_pages.items_per_page,
				 :offset => @inventory_receipts_pages.current.offset)"
	session[:query] = list_query
	render_list_inventory_receipts
  end
  
  def render_list_inventory_receipts
  	@can_edit = authorise(program_name?,'edit',session[:user_id])
  	@can_delete = authorise(program_name?,'delete',session[:user_id])
  	@current_page = session[:inventory_receipts_page] if session[:inventory_receipts_page]
  	@current_page = params['page'] if params['page']
  	@inventory_receipts =  eval(session[:query]) if !@inventory_receipts
  	if session[:inventory_receipt_lookup]
  	   @receipt_lookup = true
  	else
  	   @receipt_lookup = false
  	end
  	render :inline => %{
      		<% grid            = build_inventory_receipts_grid(@inventory_receipts,@can_edit,@can_delete,@receipt_lookup)%>
      		<% grid.caption    = 'list of all inventory receipts' %>
      		<% @header_content = grid.build_grid_data %>
      
      		<% @pagination = pagination_links(@inventory_receipts_pages) if @inventory_receipts_pages != nil %>
          <%= grid.render_html %>
      		<%= grid.render_grid %>
    	},:layout => 'content'
    	
    session[:inventory_receipt_lookup] = nil if session[:inventory_receipt_lookup] != nil
  end
  
  def edit_inventory_receipt
     return if authorise_for_web(program_name?,'edit')==false 
     id = params['id']
     if id && @inventory_receipt = InventoryReceipt.find(id)
        render_edit_inventory_receipt
     else
     
     end
  end
  
  def render_edit_inventory_receipt
     render :inline => %{
		<% @content_header_caption = "'edit inventory receipt'"%> 

		<%= build_inventory_receipt_form(@inventory_receipt,'update_inventory_receipt','update_receipt',true,@is_create_retry)%>

		}, :layout => 'content'
  end
  
  def update_inventory_receipt
      begin
    	if params[:page]
    		session[:inventory_receipts_page] = params['page']
    		render_list_inventory_receipts
    		return
    	end
    
    		@current_page = session[:inventory_receipts_page]
    	 id = params[:inventory_receipt][:id]
    	 if id && @inventory_receipt = InventoryReceipt.find(id)
    		 if @inventory_receipt.update_attributes(params[:inventory_receipt])
    			@inventory_receipt = eval(session[:query])
    			flash[:notice] = 'inventory_receipt record updated!'
    			render_list_inventory_receipts
        	 else
        	     render_edit_inventory_receipt
             end
    	 end
      rescue
         handle_error("inventory_receipt not be updated")
       end
  end
  
  def delete_inventory_receipt
     begin
    	return if authorise_for_web(program_name?,'delete')== false
    	if params[:page]
    		session[:inventory_receipts_page] = params['page']
    		render_list_inventory_receipts
    		return
    	end
    	id = params[:id]
    	if id && inventory_receipt = InventoryReceipt.find(id)
    		inventory_receipt.destroy
    		session[:alert] = " Record deleted."
    		render_list_inventory_receipts
    	end
      rescue
         handle_error("inventory_receipt record could not be deleted")
      end
  end
  
  def search_inventory_receipts_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_inventory_receipt_search_form
end
  
  def search_inventory_receipts_hierarchy
  	return if authorise_for_web(program_name?,'read')== false
   
  	@is_flat_search = false 
  	render_inventory_receipt_search_form(true)
  end
  
  def render_inventory_receipt_search_form(is_flat_search = nil)
  	session[:is_flat_search] = @is_flat_search
    # render (inline) the search form
  	render :inline => %{
  		<% @content_header_caption = "'search  inventory receipts'"%> 
  
  		<%= build_inventory_receipt_search_form(nil,'submit_inventory_receipts_search','submit_inventory_receipts_search',@is_flat_search)%>
  
  		}, :layout => 'content'
  end
  
  def submit_inventory_receipts_search
  	if params['page']
  		session[:inventory_receipts_page] =params['page']
  	else
  		session[:inventory_receipts_page] = nil
  	end
  	@current_page = params['page']
  	if params[:page]== nil
  		 @inventory_receipts = dynamic_search(params[:inventory_receipt] ,'inventory_receipts','InventoryReceipt')
  	else
  		@inventory_receipts = eval(session[:query])
  	end
  	if @inventory_receipts.length == 0
  		if params[:page] == nil
  			flash[:notice] = 'no records were found for the query'
  			@is_flat_search = session[:is_flat_search].to_s
  			render_inventory_receipt_search_form
  		else
  			flash[:notice] = 'There are no more records'
  			render_list_inventory_receipts
  		end
  
  	else
  
  		render_list_inventory_receipts
  	end
  end
  
  
  def select_inventory_receipt
     return if authorise_for_web(program_name?,'edit')==false 
     id = params['id']
     if id && @inventory_receipt = InventoryReceipt.find(id)
        #render_edit_inventory_receipt
        @ref_number = @inventory_receipt.reference_number
        render :inline=> %{
            <script>
               if(window.opener)
               {
                   //alert(window.opener.frames.length);
                   //window.opener.frames[1].document.getElementById('asset_location_inventory_receipt')
                   if(window.opener.document.getElementById('asset_location_inventory_receipt'))
                   {
                      //alert("element found!");
                      //window.opener.frames[1].document.getElementById('asset_location_inventory_receipt').value = "<%= @ref_number %>";
                      window.opener.document.getElementById('asset_location_inventory_receipt').value = "<%= @ref_number %>";
                   }
                   else
                   {
                      if(window.opener.frames[1].document.getElementById('asset_item_receipt_reference_number'))
                      {
                        window.opener.frames[1].document.getElementById('asset_item_receipt_reference_number').value = "<%= @ref_number %>";
                      }
                      else
                      {
                         if(window.opener.frames[1].document.getElementById('stock_item_inventory_receipt_reference_number'))
                         {
                             window.opener.frames[1].document.getElementById('stock_item_inventory_receipt_reference_number').value = "<%= @ref_number %>";
                         }
                         else
                         {
                            alert("element not found!");
                         }
                      }
                   }
               }
               else
               {
                  alert("no support for this operation!");
               }
               window.close();
            </script>
        }
     else
     
     end
  end
  
  
  #==================================================
  #  Observer Methods for the combo boxes for ajax
  #  calls to the server
  #==================================================
  
  def inventory_receipt_party_type_name_search_combo_changed
    party_type_name = get_selected_combo_value(params)
    session[:inventory_receipt_form][:party_type_name_combo_selection] = party_type_name
    @party_names = PartiesRole.find_by_sql("select distinct party_name from parties where party_type_name='#{party_type_name}'").map{|g|[g.party_name]}
	@party_names.unshift("<empty>")
	render :inline=>%{
	    <%=select('inventory_receipt','party_name',@party_names) %>
	    <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_inventory_receipt_party_name'/>
            <%= observe_field('inventory_receipt_party_name', :update=>'parties_role_name_cell', :url => {:action=>session[:inventory_receipt_form][:party_name_observer][:remote_method]}, :loading=>"show_element('img_inventory_receipt_party_name');", :complete=>session[:inventory_receipt_form][:party_name_observer][:on_completed_js])%>
	}
  end
  
  def inventory_receipt_party_name_search_combo_changed
    party_name = get_selected_combo_value(params)
    session[:inventory_receipt_form][:party_name_combo_selection] = party_name
    party_type_name = session[:inventory_receipt_form][:party_type_name_combo_selection]
    @role_names = PartiesRole.find_by_sql("select distinct role_name from parties_roles where party_type_name='#{party_type_name}' and party_name='#{party_name}'").map{|g|[g.role_name]}
	@role_names.unshift("<empty>")
	render :inline=>%{
	    <%=select('inventory_receipt','parties_role_name',@role_names) %>
	}
  end
  
  def inventory_receipt_pack_material_type_code_changed
    pack_material_type_code = get_selected_combo_value(params)
    session[:inventory_receipt_form][:pack_material_type_code_combo_selection] = pack_material_type_code
    pack_material_type = PackMaterialType.find_by_pack_material_type_code(pack_material_type_code)
    @pack_material_sub_type_codes = PackMaterialSubType.find_by_sql("select distinct pack_material_subtype_code from pack_material_sub_types where pack_material_type_id='#{pack_material_type.id}'").map{|g|[g.pack_material_subtype_code]}
  	@pack_material_sub_type_codes.unshift("<empty>")
  	render :inline=>%{
  	    <%=select('inventory_receipt','pack_material_sub_type_code',@pack_material_sub_type_codes) %>
  	    <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_inventory_receipt_pack_material_sub_type_code'/>
        <%= observe_field('inventory_receipt_pack_material_sub_type_code', :update=>'pack_material_product_code_cell', :url => {:action=>session[:inventory_receipt_form][:pack_material_sub_type_code_observer][:remote_method]}, :loading=>"show_element('img_inventory_receipt_pack_material_sub_type_code');", :complete=>session[:inventory_receipt_form][:pack_material_sub_type_code_observer][:on_completed_js])%>
  	}
  end
  
  def inventory_receipt_pack_material_sub_type_code_changed
    pack_material_sub_type_code = get_selected_combo_value(params)
    session[:inventory_receipt_form][:pack_material_sub_type_code_combo_selection] = pack_material_sub_type_code
    pack_material_type = PackMaterialType.find_by_pack_material_type_code(session[:inventory_receipt_form][:pack_material_type_code_combo_selection])
    pack_material_sub_type = PackMaterialSubType.find_by_pack_material_subtype_code(pack_material_sub_type_code)
    @pack_material_product_codes = PackMaterialProduct.find_by_sql("select distinct pack_material_product_code from pack_material_products where pack_material_type_id='#{pack_material_type.id}' and pack_material_sub_type_id='#{pack_material_sub_type.id}'").map{|g|[g.pack_material_product_code]}
  	@pack_material_product_codes.unshift("<empty>")
  	render :inline=>%{
  	    <%=select('inventory_receipt','pack_material_product_code',@pack_material_product_codes) %>
  	}
  end
  
  def inventory_receipt_inventory_receipt_type_code_search_combo_changed
     puts "....PARAMS : " + params.to_s
     inventory_receipt_type_code = get_selected_combo_value(params)
     session[:inventory_receipt_search_form][:inventory_receipt_type_code_combo_selection] = inventory_receipt_type_code
     @reference_numbers = InventoryReceipt.find_by_sql("select distinct reference_number from inventory_receipts where inventory_receipt_type_code='#{inventory_receipt_type_code}'").map{|g|[g.reference_number]}
     @reference_numbers.unshift("<empty>")
     render :inline => %{
         <%= select('inventory_receipt','reference_number',@reference_numbers) %>
         <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_inventory_receipt_reference_number'/>
         <%= observe_field('inventory_receipt_reference_number', :update=>'farm_code_cell', :url=> {:action => session[:inventory_receipt_search_form][:reference_number_observer][:remote_method]}, :loading=>"show_element('img_inventory_receipt_reference_number');", :complete=>session[:inventory_receipt_search_form][:reference_number_observer][:on_completed_js]) %>
     }
  end
  
  def inventory_receipt_reference_number_search_combo_changed
     reference_number = get_selected_combo_value(params)
     session[:inventory_receipt_search_form][:reference_number_combo_selection] = reference_number
     inventory_receipt_type_code = session[:inventory_receipt_search_form][:inventory_receipt_type_code_combo_selection]
     @farm_codes = InventoryReceipt.find_by_sql("select distinct farm_code from inventory_receipts where inventory_receipt_type_code='#{inventory_receipt_type_code}' and reference_number='#{reference_number}'").map{|g|[g.farm_code]}
     @farm_codes.unshift("<empty>");
     render :inline => %{
         <%= select('inventory_receipt','farm_code',@farm_codes) %>
         <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_inventory_receipt_farm_code'/>
         <%= observe_field('inventory_receipt_farm_code', :update=>'truck_code_cell', :url=> {:action => session[:inventory_receipt_search_form][:farm_code_observer][:remote_method]}, :loading=>"show_element('img_inventory_receipt_farm_code');", :complete=>session[:inventory_receipt_search_form][:farm_code_observer][:on_completed_js]) %>
     }
  end
  
  def inventory_receipt_farm_code_search_combo_changed
     farm_code = get_selected_combo_value(params)
     inventory_receipt_type_code = session[:inventory_receipt_search_form][:inventory_receipt_type_code_combo_selection]
     reference_number = session[:inventory_receipt_search_form][:reference_number_combo_selection]
     @truck_codes = InventoryReceipt.find_by_sql("select distinct truck_code from inventory_receipts where inventory_receipt_type_code='#{inventory_receipt_type_code}' and reference_number='#{reference_number}' and farm_code='#{farm_code}'").map{|g|[g.truck_code]}
     @truck_codes.unshift("<empty>")
     render :inline => %{
          <%= select('inventory_receipt','truck_code',@truck_codes) %>
     }
  end

end
