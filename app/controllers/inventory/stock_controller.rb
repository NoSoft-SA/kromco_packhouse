class Inventory::StockController < ApplicationController

  def program_name?
    "stock"
  end
  
  def bypass_generic_security?
	true
  end
  
  def create_stock
     return if authorise_for_web(program_name?,'edit') == false
     render :inline=>%{
        <% @content_header_caption = "'create new stock'"%> 
        <%= build_stock_form(@stock_item,'execute_create_stock','create_stock')%>
        
     }, :layout=>'content'
  end
  
  def execute_create_stock
    vals = params[:stock_item]
    
    @stock_item_after = StockItem.new
    #stock_type = StockType.find_by_stock_type_code(vals[:stock_type])
    #if stock_type
      #@stock_item_after.stock_type_id = stock_type.id
    #end
    @stock_item_after.stock_type_code = vals[:stock_type]
    #location = Location.find_by_location_code(vals[:location])
    #if location
      #@stock_item_after.location_id = location.id
      #@stock_item_after.current_location = location.location_code
      #@stock_item_after.location_code = location.location_code
    #end
    @stock_item_after.location_code = vals[:location_code]
 
    if vals[:party_type_name].to_s != "" && vals[:party_name].to_s.upcase.index("SELECT A VALUE") == nil && vals[:party_name].to_s != "" && vals[:parties_role_name].to_s.upcase.index("SELECT A VALUE") == nil && vals[:parties_role_name].to_s == ""
       @stock_item_after.party_type_name = vals[:party_type_name]
       @stock_item_after.party_name = vals[:party_name]
       @stock_item_after.parties_role_name = vals[:parties_role_name]
#       if vals[:parties_role_name].to_s.upcase.index("SELECT A VALUE") == nil && vals[:parties_role_name].to_s.upcase.index("<EMPTY") == nil
#          parties_role = PartiesRole.find_by_role_name_and_party_name(vals[:parties_role_name],vals[:party_name])
#          if parties_role
#             @stock_item_after.parties_role_id = parties_role.id
#             @stock_item_after.parties_role_name = parties_role.role_name
#          end
#       end
    end
    
    @stock_item_after.inventory_reference = vals[:inventory_reference]
    #@stock_item_after.lot_id = vals[:object_id].to_i
    @stock_item_after.created_on = Time.now.to_formatted_s(:db)
    @stock_item_after.inventory_quantity = 1
    @stock_item_after.status_code = vals[:status_code]

    @stock_item_after.validate
    
#    @inventory_transaction = InventoryTransaction.new
#    location = Location.find_by_location_code(vals[:location])
#    if location
#      @inventory_transaction.location_id = location.id
#      @inventory_transaction.location_to = vals[:location]
#    end
#
#    @inventory_transaction.transaction_type_code = "create_stock"
#
#    @inventory_transaction.transaction_business_name_code = vals[:transaction_business_name]
#
#    @inventory_transaction.transaction_date_time = Time.now.to_formatted_s(:db)
#
#    @inventory_transaction.transaction_quantity_plus = 1
#
#    @inventory_transaction.transaction_quantity_minus = nil
#    @inventory_transaction.reference_number = vals[:reference_number]
#
#    @inventory_transaction.inventory_receipt_reference_number = vals[:inventory_receipt_reference_number]

    @inventory_transaction = InventoryTransaction.new_object("create_stock", vals[:transaction_business_name], vals[:reference_number], nil, nil, vals[:inventory_receipt_reference_number],nil)

#    @inventory_transaction.validate

    Inventory::CreateStock.new(@inventory_transaction,@stock_item_after).process
    
    session[:inventory_receipt] = nil if session[:inventory_receipt]
    redirect_to_index("stock created successifully!")
  end

  def lookup_receipt
     session[:inventory_receipt_lookup] = nil if session[:inventory_receipt_lookup] != nil
     session[:inventory_receipt_lookup] = true
     @href = "http://" + request.host_with_port.to_s +  "/inventory/inventory_receipts/search_inventory_receipts_hierarchy"
     render :inline=>%{
        <script>
            window.location.href = "<%= @href %>";
        </script>
     }
  end
  
  def find_stock
    #     return if authorise_for_web(program_name?,'edit') == false
    #     render :inline => %{
    #		<% @content_header_caption = "'find stock'"%> 
    #
    #		<%= build_find_stock_form(@stock_item,'execute_find_stock','find_stock',false,@is_create_retry)%>
    # 
    #		}, :layout => 'content'
    session[:selected_stock_items] = nil if session[:selected_stock_items]
    session[:show_summary_icon] = false
    session[:redirect] = true
    build_remote_search_engine_form("stock_search.yml", "render_se_stock_grid")
  end
  
  def render_se_stock_grid
    #render_generic_grid
    @stocks = ActiveRecord::Base.connection.select_all(session[:search_engine_query_definition])
    session[:stock_items] = nil if session[:stock_items] != nil
    session[:stock_items] = @stocks
    render :inline => %{
		<% grid            = build_stock_grid(@stocks)%>
		<% grid.caption    = 'stock items' %>
		<% @header_content = grid.build_grid_data %>

    <%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
  end
  
  def manage_stock
    return if authorise_for_web(program_name?,'edit') == false
    id = params[:id]
    puts id.to_s
    @stock_item = StockItem.find(id.to_i)
    session[:stock_item] = nil if session[:stock_item] != nil
    session[:stock_item] = @stock_item
    session[:current_location] = @stock_item.location_code
    session[:inventory_transaction] = nil if session[:inventory_transaction]
    session[:inventory_transaction] = @stock_item.inventory_transaction
    session[:inventory_receipt] = nil if session[:inventory_receipt]
    session[:inventory_receipt] = @stock_item.inventory_transaction.inventory_receipt
    render_manage_stock
  end
  
  def render_manage_stock
     render :inline => %{
		<% @content_header_caption = "'manage stock item'"%> 

		<%= build_manage_stock_item_form(@stock_item,'update_stock','update_stock',false,@is_create_retry)%>

		}, :layout => 'content'
  end
  
  def update_stock
     session[:stock_item].update_attributes_state(params[:stock_item])
     inventory_transaction_hash = Hash.new
     inventory_transaction_hash[:reference_number] = params[:stock_item][:reference_number]
     inventory_transaction_hash[:transaction_business_name_code] = params[:stock_item][:transaction_business_name_code]
     #inventory_transaction_hash[:transaction_type_code] = params[:stock_item][:transaction_type_code]
     session[:inventory_transaction].update_attributes_state(inventory_transaction_hash)
     
     #inventory_receipt_hash = Hash.new
     #inventory_receipt_hash[:farm_code] = params[:stock_item][:farm_code]
     #inventory_receipt_hash[:truck_code] = params[:stock_item][:truck_code]
     #session[:inventory_receipt].update_attributes_state(inventory_receipt_hash)
     session[:params_vals] = nil if session[:params_vals] != nil
     session[:params_vals] = params[:stock_item]
     #changed = session[:stock_item].changed_fields? 
     confirm_update_stock
  end
  
  def confirm_update_stock
     changed = session[:stock_item].changed_fields?
     changed_msg = build_changed_field_msg(changed)
     
     changed =  session[:inventory_transaction].changed_fields?
     changed_msg +=  build_changed_field_msg(changed)
     #changed =  session[:inventory_receipt].changed_fields?
     #changed_msg +=  build_changed_field_msg(changed)
     if session[:inventory_receipt].reference_number != session[:params_vals][:inventory_receipt_reference_number]
       changed_msg += "\\n inventory receipt ref_number : " + session[:inventory_receipt].reference_number + " to " + session[:params_vals][:inventory_receipt_reference_number]
     end
     
     if changed_msg == ""
       flash[:notice]= "You did not change anything"
       #rw_pallets
       render_se_stock_grid
       return
      end
    
    
    @msg = "Are you sure you want to submit the update? All the selected stock items will be updated as well. " + changed_msg
    
    
    render :inline => %{
       <script>
         if (confirm("<%=@msg%>") == true)
            {window.location.href = "/inventory/stock/stock_items_update_confirmed";}
         else
           {window.location.href = "/inventory/stock/stock_items_update_cancelled";}
      </script>
    }
  end
  
  def stock_items_update_confirmed
     if session[:inventory_transaction].changed_fields != nil && session[:inventory_transaction].changed_fields.length > 0
        session[:inventory_transaction].update_changed_fields
        #session[:inventory_transaction].inventory_receipt = session[:inventory_receipt]
     end
     if session[:stock_item].changed_fields != nil && session[:stock_item].changed_fields.length > 0
       puts "CHANGED STOCK ITEM FIELDS UPDATED !!!!!!!!!!"
       session[:stock_item].update_changed_fields
     end
     if (session[:stock_item].changed_fields != nil && session[:stock_item].changed_fields.length > 0) || (session[:inventory_transaction].changed_fields != nil && session[:inventory_transaction].changed_fields.length > 0) || (session[:inventory_receipt].reference_number != session[:params_vals][:inventory_receipt_reference_number])
       puts "BABA VEDU -- ISHE!"
       @inventory_transaction = InventoryTransaction.new
       session[:inventory_transaction].export_attributes(@inventory_transaction,nil,nil)
       @inventory_transaction.transaction_date_time = Time.now.to_formatted_s(:db)
       transaction_business_name = TransactionBusinessName.find_by_transaction_business_name_code(session[:params_vals][:transaction_business_name_code])
       if transaction_business_name
         @inventory_transaction.transaction_business_name_id = transaction_business_name.id
         @inventory_transaction.transaction_business_name_code = transaction_business_name.transaction_business_name_code
       end
       transaction_type = TransactionType.find_by_transaction_type_code("update_stock")
       if transaction_type
         @inventory_transaction.transaction_type_id = transaction_type.id
         @inventory_transaction.transaction_type_code = "update_stock"
       end
       inventory_receipt = InventoryReceipt.find_by_reference_number(session[:params_vals][:inventory_receipt_reference_number])
       if inventory_receipt
         @inventory_transaction.inventory_receipt = inventory_receipt
       end
       if session[:stock_item].changed_fields != nil && session[:stock_item].changed_fields.length > 0
         if session[:stock_item].changed_fields.has_key?("location_code")
           #@inventory_transaction.location_from = session[:current_location]
           #@inventory_transaction.location_to = session[:params_vals][:location_code]
           transaction_type = TransactionType.find_by_transaction_type_code("move_stock")
           if transaction_type
             @inventory_transaction.transaction_type_id = transaction_type.id
             @inventory_transaction.transaction_type_code = "move_stock"
           end
           #@inventory_transaction = InventoryTransaction.new_object("update_stock", session[:params_vals][:transaction_business_name_code], session[:inventory_transaction].reference_number, location_to, stock_item, receipt, issue)
           Inventory::MoveStock.new(@inventory_transaction, session[:stock_item]).process
           if session[:selected_stock_items]
              session[:selected_stock_items].each do |st|
                session[:stock_item].export_attributes(st,true,nil) #session[:stock_item].unchanged_fields
                Inventory::MoveStock(@inventory_transaction, st).process
              end
           end
         else
           Inventory::UpdateStock.new(@inventory_transaction, session[:stock_item]).process
           if session[:selected_stock_items]
              session[:selected_stock_items].each do |st|
                session[:stock_item].export_attributes(st,true,session[:stock_item].unchanged_fields)
                Inventory::UpdateStock(@inventory_transaction, st).process
              end
           end
         end
       else
         Inventory::UpdateStock.new(@inventory_transaction, session[:stock_item]).process
         if session[:selected_stock_items]
            session[:selected_stock_items].each do |st|
              #session[:stock_item].export_attributes(st,true,session[:stock_item].unchanged_fields)
              Inventory::UpdateStock(@inventory_transaction, st).process
            end
         end
       end
     end
     
     session[:inventory_receipt] = nil if session[:inventory_receipt]
     session[:inventory_transaction] = nil if session[:inventory_transaction]
     session[:stock_item] = nil if session[:stock_item]
     session[:selected_stock_items] = nil if session[:selected_stock_items]
     
     redirect_to_index("'stock items updated successfully'","'update successful'")
     
     #render :inline=>%{
     #   stock items updated
     #},:layout=>'content'
  end
  
  def stock_items_update_cancelled
    session[:stock_item] = nil
    flash[:notice]= "stock items update cancelled"
    #rw_pallets
    render_se_stock_grid
  end
  
  def view_object_details
    #puts "Object Details ID : " + params[:id].to_s
    id = params[:id]
    stock_type_code = session[:stock_item].stock_type_code
    @object = nil
    @model_name = nil
    if stock_type_code == "pallet"
       @object = Pallet.find_by_pallet_number(id)
       @model_name = "pallets"
    elsif stock_type_code == "rmt_bin"
       @object = Rebin.find_by_rebin_number(id)
       @model_name = "rebins"
    else
    
    end
    
    if @object != nil
      render :inline => %{
		<% @content_header_caption = "'manage stock item'"%> 

		<%= build_view_record_form(@object,'close_view_object_details_form','close',@model_name)%>

		}, :layout => 'content'
    else
      render :inline=>%{
         No record found
      }, :layout=>'content'
    end
  end
  
  def close_view_object_details_form
     render :inline=>%{
        <script>
          window.close();
        </script>
     }, :layout=>'content'
  end
  
  def view_transaction_history
    id = params[:id]
    @inventory_transaction_stocks = InventoryTransactionStock.find_by_sql("select * from inventory_transaction_stocks where stock_item_id = '#{id}'")
    render :inline => %{
		<% grid            = build_stock_inventory_transaction_history_grid(@inventory_transaction_stocks)%>
		<% grid.caption    = 'stock transaction history' %>
		<% @header_content = grid.build_grid_data %>

    <%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
  end
  
  def view_status_history
     id = params[:id]
    @stock_statuses = StockItemStatus.find_by_sql("select * from stock_item_statuses where stock_item_id = '#{id}'")
    render :inline => %{
		<% grid            = build_stock_item_statuses_history_grid(@stock_statuses)%>
		<% grid.caption    = 'stock item status history' %>
		<% @header_content = grid.build_grid_data %>

    <%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
  end
  
  def view_asset
     inventory_reference = params[:id]
     #puts "INV REFER == = : " + inventory_reference.to_s
     @asset_item = Inventory::StockTransaction.find_asset(inventory_reference)
     if @asset_item
        render :inline => %{
    		<% @content_header_caption = "'view asset item details'"%> 
    
    		<%= build_view_asset_item_form(@asset_item,'close_view_asset_form','close')%>
    
    	}, :layout => 'content'
     else
        render :inline=>%{
           <script>
              alert('No asset item found!');
              window.parent.close();
           </script>
        },:layout=>'content'
     end
  end
  
  def close_view_asset_form
     render :inline=>%{
        <script>
          window.close();
        </script>
     }, :layout=>'content'
  end
  
  def apply_to_list
     @stocks = session[:stock_items]
     render :inline => %{
		<% grid            = build_apply_to_list_grid(@stocks,true)%>
		<% grid.caption    = 'stock items' %>
		<% @header_content = grid.build_grid_data %>

    <%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'  
  end
  
  def selected_stock_items
     @selected_stock_items = selected_records?(session[:stock_items],nil,true)
     session[:selected_stock_items] = nil if session[:selected_stock_items] != nil
     session[:selected_stock_items] = @selected_stock_items
     redirect_to_index("stock items were successifully selected!");
  end
  
  def selected_items
     @stocks = session[:selected_stock_items]
     if @stocks != nil
         render :inline => %{
    		<% grid            = build_selected_items_grid(@stocks)%>
        <% grid.caption    = 'selected stock items' %>
    		<% @header_content = grid.build_grid_data %>
    
        <%= grid.render_html %>
    		<%= grid.render_grid %>
    	},:layout => 'content'
    else
       render :inline=>%{
             <script>
                alert('no items were selected!');
                window.parent.close();
             </script>
          },:layout=>'content'
    end
  end

  def remove_stock
    @id = params[:id]
    #puts " STOCK ID : " + @id.to_s
    @msg = "Are you sure you want to remove/delete this stock item?"
    render :inline => %{
       <script>
         if (confirm("<%=@msg%>") == true)
            {window.location.href = "/inventory/stock/remove_stock_confirmed";}
         else
           {window.location.href = "/inventory/stock/remove_stock_cancelled";}
      </script>
    }
  end

  def remove_stock_confirmed
    render :inline=> %{
        <% @content_header_caption = "'remove grouped asset'"%>

        <%= build_lookup_inventory_issue_form(@inventory_issue,'execute_remove_stock','remove stock',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def remove_stock_cancelled
    flash[:notice] = "remove stock was cancelled!"
    @stock_item = session[:stock_item]
    render_manage_stock
  end

  def execute_remove_stock
    @inventory_issue = nil
    if params[:inventory_issue][:reference_number] != nil || params[:inventory_issue][:reference_number].to_s.strip != ""
      #flash[:notice] = "inventory issue is required please!"
      #remove_asset_confirmed
      reference_number = params[:inventory_issue][:reference_number]
      @inventory_issue = InventoryIssue.find_by_reference_number(reference_number)
    end
    @inventory_transaction = InventoryTransaction.new
    session[:inventory_transaction].export_attributes(@inventory_transaction, nil, nil)
    transaction_type = TransactionType.find_by_transaction_type_code("remove_stock")
    if transaction_type
      @inventory_transaction.transaction_type_id = transaction_type.id
      @inventory_transaction.transaction_type_code = transaction_type.transaction_type_code
    end
    @inventory_transaction.transaction_business_name_id = session[:inventory_transaction].transaction_business_name_id
    @inventory_transaction.transaction_date_time = Time.now.to_formatted_s(:db)
    if @inventory_issue != nil
      @inventory_transaction.inventory_issue = @inventory_issue
    end
    #Inventory::RemoveAssetClass.new(session[:asset_item], @inventory_transaction).process
    Inventory::RemoveStock.new(@inventory_transaction, session[:stock_item]).process
    session[:inventory_receipt] = nil if session[:inventory_receipt]
    session[:inventory_transaction] = nil if session[:inventory_transaction]
    session[:asset_item] = nil if session[:asset_item]
    session[:inventory_issue] = nil if session[:inventory_issue]
    redirect_to_index("stock item removed successifully!", "stock item removed", true)
  end
  
  #=========================================
  # Inventory_Receipts creation
  #=========================================
  def new_receipt
     return if authorise_for_web(program_name?,'create') == false
     render_new_receipt
  end
  
  def render_new_receipt
     render :inline => %{
		<% @content_header_caption = "'create new receipt'"%> 

		<%= build_inventory_receipt_form(@inventory_receipt,'create_inventory_receipt','create_receipt',false,@is_create_retry)%>

		}, :layout => 'content'
  end
  
  def create_inventory_receipt
     #puts params[:inventory_receipt].to_s
     begin
    	 @inventory_receipt = InventoryReceipt.new(params[:inventory_receipt])
    	 if @inventory_receipt.save
    	     session[:inventory_receipt] = @inventory_receipt
    		 redirect_to_index("'new record created successfully'","'create successful'")
    	 else
    		@is_create_retry = true
    		render_new_receipt
    	 end
    rescue
       handle_error("inventory_receipt could not be created")
    end
    
  end
  
  
  #==================================================
  #  Observer Methods for the combo boxes for ajax
  #  calls to the server
  #==================================================

  def stock_item_party_type_name_combo_changed
    party_type_name = get_selected_combo_value(params)
    session[:stock_item_form][:party_type_name_combo_selection] = party_type_name
    @party_names = Party.find_by_sql("select distinct party_name from parties where party_type_name='#{party_type_name}'").map{|g|[g.party_name]}
    @party_names.unshift("<empty>")
    render :inline=>%{
      <%=select('stock_item','party_name',@party_names) %>
      <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_stock_item_party_name'/>
      <%= observe_field('stock_item_party_name', :update=>'parties_role_name_cell', :url => {:action=>session[:stock_item_form][:party_name_observer][:remote_method]}, :loading=>"show_element('img_stock_item_party_name');", :complete=>session[:stock_item_form][:party_name_observer][:on_completed_js])%>
    }
  end

  def stock_item_party_name_combo_changed
    party_name = get_selected_combo_value(params)
    session[:stock_item_form][:party_name_combo_selection] = party_name
    party_type_name = session[:stock_item_form][:party_type_name_combo_selection]
    @role_names = PartiesRole.find_by_sql("select distinct role_name from parties_roles where party_type_name='#{party_type_name}' and party_name='#{party_name}'").map{|g|[g.role_name]}
    @role_names.unshift("<empty>")
    render :inline=>%{
       <%=select('stock_item','parties_role_name',@role_names) %>
    }
  end
  
  def inventory_receipt_party_type_name_search_combo_changed
    party_type_name = get_selected_combo_value(params)
    session[:inventory_receipt_form][:party_type_name_combo_selection] = party_type_name
    @party_names = Party.find_by_sql("select distinct party_name from parties where party_type_name='#{party_type_name}'").map{|g|[g.party_name]}
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
    @pack_material_subtype_codes = PackMaterialSubType.find_by_sql("select distinct pack_material_subtype_code from pack_material_sub_types where pack_material_type_id='#{pack_material_type.id}'").map{|g|[g.pack_material_subtype_code]}
  	@pack_material_subtype_codes.unshift("<empty>")
  	render :inline=>%{
  	    <%=select('inventory_receipt','pack_material_subtype_code',@pack_material_subtype_codes) %>
  	    <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_inventory_receipt_pack_material_subtype_code'/>
        <%= observe_field('inventory_receipt_pack_material_subtype_code', :update=>'pack_material_product_code_cell', :url => {:action=>session[:inventory_receipt_form][:pack_material_subtype_code_observer][:remote_method]}, :loading=>"show_element('img_inventory_receipt_pack_material_subtype_code');", :complete=>session[:inventory_receipt_form][:pack_material_subtype_code_observer][:on_completed_js])%>
  	}
  end
  
  def inventory_receipt_pack_material_subtype_code_changed
    pack_material_subtype_code = get_selected_combo_value(params)
    session[:inventory_receipt_form][:pack_material_subtype_code_combo_selection] = pack_material_subtype_code
    pack_material_type = PackMaterialType.find_by_pack_material_type_code(session[:inventory_receipt_form][:pack_material_type_code_combo_selection])
    pack_material_subtype = PackMaterialSubType.find_by_pack_material_subtype_code(pack_material_subtype_code)
    @pack_material_product_codes = PackMaterialProduct.find_by_sql("select distinct pack_material_product_code from pack_material_products where pack_material_type_id='#{pack_material_type.id}' and pack_material_sub_type_id='#{pack_material_subtype.id}'").map{|g|[g.pack_material_product_code]}
  	@pack_material_product_codes.unshift("<empty>")
  	render :inline=>%{
  	    <%=select('inventory_receipt','pack_material_product_code',@pack_material_product_codes) %>
  	}
  end

end
