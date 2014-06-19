class RmtProcessing::DrenchingController < ApplicationController

  def program_name?
    "drenching"
  end

  def bypass_generic_security?
    true
  end

#   ==============================
#                               ==
#   Drench line controller code ==
#                               ==
#   ==============================
  def drench_setups
    session[:user_actions] = nil # CLEARING session[:user_actions]

    @drench_lines = DrenchLine.find(:all)
    session[:drench_lines] = @drench_lines
    @content_header_caption = "'drench setups'"
    render :inline => %{
                      <% @tree_script = build_drenching_tree(@drench_lines) %>
                      }, :layout => 'tree'
  end

  def new_drench_line
    render_new_drench_line
  end

  def render_new_drench_line
#	 render (inline) the edit template
    if authorise(program_name?, 'drench_new', session[:user_id]) == false
      flash[:notice] = "You don't have permission to perform this action"
      render :inline => %{
               <% @hide_content_pane = true %>
               <% @is_menu_loaded_view = true %>
      }, :layout => 'tree_node_content'
      return
    end
    
    render :inline => %{
		               <% @tree_node_content_header = "create new drench line" -%>
                       <% @hide_content_pane = false %>
                       <% @is_menu_loaded_view = true %>

		               <%= build_drench_line_form(@drench_line,'create_drench_line','create_drench_line',false,@is_create_retry)%>

		                }, :layout => 'tree_node_content'
  end

  def create_drench_line
    begin
      @drench_line = DrenchLine.new(params[:drench_line])

      @drench_line.save!
      @node_name = @drench_line.drench_line_code
      @node_type = "drench_line"
      @node_id = @drench_line.id.to_s
      @tree_name = "drenching"
      flash[:notice] = "'new record created successfully'"

      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = false %>

                      <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>

                      }, :layout => 'tree_node_content'
    rescue

      flash[:notice] = 'record could not be created'
      @is_create_retry = true
      render_new_drench_line
    end
  end

  def delete_drench_line
    if authorise(program_name?, 'drench_delete', session[:user_id]) == false 
      flash[:notice] = "You don't have permission to perform this action"
      render :inline => %{
               <% @hide_content_pane = true %>
               <% @is_menu_loaded_view = true %>
      }, :layout => 'tree_node_content'
      return
    end
    begin
      id = params[:id]
      if id && drench_line = DrenchLine.find(id)
        drench_line.destroy

        flash[:notice] = " Drench Line deleted."
        render :inline => %{
                     <% @hide_content_pane = true %>
                     <% @is_menu_loaded_view = true %>
                     <% @tree_actions = "window.parent.RemoveNode(null);" %>
                     
                      }, :layout => 'tree_node_content'

      end
    rescue handle_error('record could not be deleted')
    end
  end

  def edit_drench_line
    if authorise(program_name?, 'drench_edit', session[:user_id]) == false #authorise_for_web(program_name?, 'Drench_new') == false
      flash[:notice] = "You don't have permission to perform this action"
      render :inline => %{
               <% @hide_content_pane = true %>
               <% @is_menu_loaded_view = true %>
      }, :layout => 'tree_node_content'
      return
    end
    id = params[:id]
    if id && @drench_line = DrenchLine.find(id)
      render_edit_drench_line
    end
  end

  def render_edit_drench_line
    render :inline => %{
		<% @tree_node_content_header = "edit drench line" -%> 
        <% @hide_content_pane = false %>
        <% @is_menu_loaded_view = true %>
		<%= build_drench_line_form(@drench_line,'update_drench_line','update_drench_line',true)%>

		}, :layout => 'tree_node_content'
  end

  def update_drench_line
    begin
      id = params[:drench_line][:id]
      if id && @drench_line = DrenchLine.find(id)
        if @drench_line.update_attributes(params[:drench_line])
          #@drench_lines = eval(session[:query])
          @new_text = @drench_line.drench_line_code
          flash[:notice] = 'drench line record edited successfully'

          render :inline => %{
		                       <% @hide_content_pane = true %>
                               <% @is_menu_loaded_view = false %>
                               <% @tree_actions = render_edit_node_js(@new_text) %>		                       
		                       }, :layout => 'tree_node_content'

        else
          render_edit_drench_line
        end
      else
        flash[:notice] = 'could not find such a record !!!'
        render :inline => %{
        }, :layout => 'tree_node_content'
      end
    rescue
      handle_error('record could not be saved')
    end
  end

#   =================================
#                                  ==
#   Drench station controller code ==
#                                  ==
#   =================================

  def add_drench_station
    if authorise(program_name?, 'drench_new', session[:user_id]) == false
      flash[:notice] = "You don't have permission to perform this action"
      render :inline => %{
               <% @hide_content_pane = true %>
               <% @is_menu_loaded_view = true %>
      }, :layout => 'tree_node_content'
      return
    end
    @id = params[:id]
    session[:drench_line] = params[:id]
    render_new_drench_station
  end

  def render_new_drench_station
    #	 render (inline) the edit template
    @drench_line = DrenchLine.find(@id)

    render :inline => %{
		<% @tree_node_content_header = "add station to drench line '" + @drench_line.drench_line_code + "'" %> 
        <% @hide_content_pane = false %>
        <% @is_menu_loaded_view = true %>

		<%= build_drench_station_form(@drench_station,'create_drench_station','create_drench_station',false,@is_create_retry)%>

		}, :layout => 'tree_node_content'
  end

  def activate_drench_station
    session[:drench_station] = params[:id]
    @drench_station = DrenchStation.find(params[:id])
    #@drench_station.drench_status_code = 'deactivated'

    begin
      @drench_station.update_attribute('drench_status_code', 'active')
      flash[:notice] = "station activated"

      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>
                      <script>
                            window.parent.location.href = "/rmt_processing/drenching/drench_setups";
                      </script>
                      }, :layout => 'content'
    rescue

      flash[:notice] = "could not activated station"
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>
                       }, :layout => 'tree_node_content'
    end
  end

  def deactivate_drench_station
    session[:drench_station] = params[:id]
    @drench_station = DrenchStation.find(params[:id])
    #@drench_station.drench_status_code = 'deactivated'

    begin
      @drench_station.update_attribute('drench_status_code', 'inactive')
      flash[:notice] = "station deactivated"

      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>
                      <script>
                            window.parent.location.href = "/rmt_processing/drenching/drench_setups";
                      </script>
                      }, :layout => 'content'
    rescue

      flash[:notice] = "could not deactivated station"
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>
                       }, :layout => 'tree_node_content'
    end
  end

  def drench_station_drench_status_code_combo_changed

    #@flash[:notice] = params.to_s.index("1")
    #breakpoint #params.keys => ["action", "deactivated", "controller"]
#    @drench_station = DrenchStation.new
    if params.keys.include?("deactivated") || params.keys.include?("inactive")
      render :inline => %{<script> document.getElementById('deactive_reason_cell').setAttribute('class', 'className');</script> <input id="drench_station_deactive_reason" name="drench_station[deactive_reason]" size="30" type="text"'/>}
    else
      render :inline => %{ }
    end

#   render :inline => %{
#
#
#   <script>
#     img = document.getElementById('img_drench_station_drench_status_code');
#     if(img != null)img.style.display = 'none';
#
#
#     <% if @drench_status_code == 'active'
#         from_time_active_content = datetime_select('drench_station', 'date_active_from')
#         to_time_active_content = datetime_select('drench_station', 'date_active_to')
#
#         from_time_deactive_content = "<label class='label_field' style='width : 100px;'>disabled</label>"
#         to_time_deactive_content = "<label class='label_field' style='width : 100px;'>disabled</label>"
#         deactivate_reason = "<label class='label_field' style='width : 100px;'>disabled</label>"
#
#         elsif @drench_status_code == 'deactivated'
#          from_time_deactive_content = datetime_select('drench_station', 'date_deactivated_from')
#          to_time_deactive_content = datetime_select('drench_station', 'date_deactivated_to')
#          deactivate_reason = text_field('drench_station', 'deactive_reason')
#
#         from_time_active_content = "<label class='label_field' style='width : 100px;'>disabled</label>"
#         to_time_active_content = "<label class='label_field' style='width : 100px;'>disabled</label>"
#
#          else
#         end
#     %>
#
#      <%= update_element_function(
#        "date_active_from_cell", :action => :update,
#        :content => from_time_active_content)%>
#
#      <%= update_element_function(
#        "date_active_to_cell", :action => :update,
#        :content => to_time_active_content)%>
#
#      <%= update_element_function(
#        "date_deactivated_from_cell", :action => :update,
#        :content => from_time_deactive_content)%>
#
#      <%= update_element_function(
#        "date_deactivated_to_cell", :action => :update,
#        :content => to_time_deactive_content)%>
#
#      <%= update_element_function(
#        "deactive_reason_cell", :action => :update,
#        :content => deactivate_reason)%>
#
#   </script>
#  }
  end

  def create_drench_station
    begin
      @drench_line = DrenchLine.find(session[:drench_line])

      @drench_station = DrenchStation.new #(params[:drench_station])
      @drench_station.drench_station_code = params[:drench_station][:drench_station_code]
      @drench_station.drench_status_code = params[:drench_station][:drench_status_code]
      @drench_station.drench_station_description = params[:drench_station][:drench_station_description]
      @drench_station.drench_line_type_code = @drench_line.drench_line_type_code
      @drench_station.drench_line_code = @drench_line.drench_line_code
      if params[:drench_station][:drench_status_code].to_s == 'active'
        @drench_station.date_active_from = params[:drench_station][:date_date2from]
        @drench_station.date_active_to = params[:drench_station][:date_date2to]
      else
        @drench_station.date_deactivated_from = params[:drench_station][:date_date2from]
        @drench_station.date_deactivated_to = params[:drench_station][:date_date2to]
      end

      if @drench_station.drench_line_type_code == "Drench Line"
        if @drench_station.save
          @node_name = @drench_station.drench_station_code.chomp
          if(@drench_station.drench_status_code == 'active')
            @node_type = "active_drench_station"
          else
            @node_type = "deactive_drench_station"
          end
          @node_id = @drench_station.id.to_s
          @tree_name = "drenching"

          flash[:notice] = "new record created successfully"

          render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = false %>

                      <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>

                      }, :layout => 'tree_node_content'

        else
          @is_create_retry = true
          render_new_drench_station
        end
      else
        flash[:notice] = "Sorry,line is not a drench line"
        drench_setups
      end
    rescue
      flash[:notice] = "record could not be created " + $!.to_s
      drench_setups
    end
  end

  def delete_drench_station
    if authorise(program_name?, 'drench_delete', session[:user_id]) == false #authorise_for_web(program_name?, 'Drench_new') == false
      flash[:notice] = "You don't have permission to perform this action"
      render :inline => %{
               <% @hide_content_pane = true %>
               <% @is_menu_loaded_view = true %>
      }, :layout => 'tree_node_content'
      return
    end
    begin
      id = params[:id]
      if id && drench_station = DrenchStation.find(id)
        drench_station.destroy
        flash[:notice] = " Drench satation has been removed"

        render :inline => %{
                     <% @hide_content_pane = true %>
                     <% @is_menu_loaded_view = true %>
                     <% @tree_actions = "window.parent.RemoveNode(null);" %>
                     
                      }, :layout => 'tree_node_content'
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def edit_drench_station
    if authorise(program_name?, 'drench_edit', session[:user_id]) == false #authorise_for_web(program_name?, 'Drench_new') == false
      flash[:notice] = "You don't have permission to perform this action"
      render :inline => %{
               <% @hide_content_pane = true %>
               <% @is_menu_loaded_view = true %>
      }, :layout => 'tree_node_content'
      return
    end
    id = params[:id]
    if id && @drench_station = DrenchStation.find(id)
      session[:drench_station_id] = id
      render :inline => %{
		<% @tree_node_content_header = "edit station '" + @drench_station.drench_station_code + "' to drench line '" + @drench_station.drench_line_code + "'" %> 
        <% @hide_content_pane = false %>
        <% @is_menu_loaded_view = true %>
        
		<%= build_drench_station_form(@drench_station,'update_drench_station','update_drench_station',true)%>

		}, :layout => 'tree_node_content'

    end
  end

  def update_drench_station
    begin

#--- before_update-----------------------------------------------------HANS
#if params[:drench_station][:drench_status_code] != @drench_station.drench_status_code
#   if params[:drench_station][:drench_status_code] == 'active'
#   
#     params[:drench_station][:date_deactivated_from] = nil
#     params[:drench_station][:date_deactivated_to] = nil
#     params[:drench_station][:deactive_reason] = nil
#
#   elsif params[:drench_station][:drench_status_code] == 'deactivated'
#
#     params[:drench_station][:date_active_from] = nil
#     params[:drench_station][:date_active_to] = nil
#
#   else
#     
#     params[:drench_station][:date_deactivated_from] = nil
#     params[:drench_station][:date_deactivated_to] = nil
#     params[:drench_station][:deactive_reason] = nil
#     params[:drench_station][:date_active_from] = nil
#     params[:drench_station][:date_active_to] = nil
#     
#   end
#end
#------------------------------------------------------------------
      @drench_station = DrenchStation.find(session[:drench_station_id])
      attributes = {:drench_station_description=>params[:drench_station][:drench_station_description]}
      if @drench_station.drench_status_code.to_s == 'active'
        attributes.store(:date_active_from, params[:drench_station][:date_date2from])
        attributes.store(:date_active_to, params[:drench_station][:date_date2to])
      else
        attributes.store(:date_deactivated_from, params[:drench_station][:date_date2from])
        attributes.store(:date_deactivated_to, params[:drench_station][:date_date2to])
        attributes.store(:deactive_reason, params[:drench_station][:deactive_reason])
      end
      DrenchStation.update(session[:drench_station_id], attributes)
      flash[:notice] = 'drench station record edited successfully  '

      render :inline => %{
                <% @hide_content_pane = true %>
                <% @is_menu_loaded_view = true %>
                <script>
                      window.parent.location.href = "/rmt_processing/drenching/drench_setups";
                </script>
                }, :layout => 'content'
    rescue
#	 handle_error('record could not be saved')
      flash[:notice] = 'drench station record could not be edited ' + $!.to_s
      render :inline => %{<% @hide_content_pane = true %>
                         <% @is_menu_loaded_view = false %>
	                    }, :layout => 'tree_node_content'
    end
  end

#   =======================================
#                                        ==
#   Concentrate products controller code ==
#                                        ==
#   =======================================
  def new_concentrate_product    
    render_new_concentrate_product
  end

  def render_new_concentrate_product
    #	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new concentrate_product'"%> 

		<%= build_concentrate_product_form(@concentrate_product,'create_concentrate_product','create_concentrate_product',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_concentrate_product
    begin
      @concentrate_product = ConcentrateProduct.new(params[:concentrate_product])
#------ before_create--------
      product_type = ProductType.find_by_product_type_code('DRENCH_CONCENTRATE') #'drench_concentrate'
      @product = Product.new
      @product.product_code = @concentrate_product.concentrate_code
      @product.product_type_code = product_type.product_type_code
      @product.product_type = product_type

      @product.save

#----------------------------

      @concentrate_product.product_type_code = product_type.product_type_code
      @concentrate_product.product = Product.find_by_product_code(@product.product_code)
      @concentrate_product.save
      list_concentrate_products
    rescue
      flash[:error] = 'concentrate product record could not be created ' + $!.to_s
      render_new_concentrate_product
    end
  end

  def list_concentrate_products
    if params[:page]!= nil

      session[:concentrate_products_page] = params['page']

      render_list_concentrate_products

      return
    else
      session[:concentrate_products_page] = nil
    end

    list_query = "@concentrate_product_pages = Paginator.new self, ConcentrateProduct.count, @@page_size,@current_page
	 @concentrate_products = ConcentrateProduct.find(:all,
				 :limit => @concentrate_product_pages.items_per_page,
				 :offset => @concentrate_product_pages.current.offset)"
    session[:query] = list_query
    render_list_concentrate_products
  end

  def render_list_concentrate_products
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @concentrate_products =  eval(session[:query]) if !@concentrate_products
    render :inline => %{
      <% grid            = build_concentrate_product_grid(@concentrate_products,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all concentrate_products' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@concentrate_product_pages) if @concentrate_product_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def delete_concentrate_product
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      id = params[:id]
      if id && concentrate_product = ConcentrateProduct.find(id)
        concentrate_product.product.destroy
        concentrate_product.destroy
        session[:alert] = " Record deleted."
        render_list_concentrate_products
      end
    rescue
      flash[:notice] = 'record could not be deleted'
      render_list_concentrate_products
    end
  end

  def edit_concentrate_product
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    if id && @concentrate_product = ConcentrateProduct.find(id)
      render_edit_concentrate_product

    end
  end


  def render_edit_concentrate_product
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit concentrate_product'"%> 

		<%= build_concentrate_product_form(@concentrate_product,'update_concentrate_product','update_concentrate_product',true)%>

		}, :layout => 'content'
  end

  def update_concentrate_product
    begin
      id = params[:concentrate_product][:id]
      if id && @concentrate_product = ConcentrateProduct.find(id)
        if @concentrate_product.update_attributes(params[:concentrate_product])
          flash[:notice] = 'record saved'
          render_list_concentrate_products
        else
          render_edit_concentrate_product

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

#   =====================================
#                                      ==
#   Drench Concentrate controller code ==
#                                      ==
#   =====================================

  def new_drench_concentrate
    if authorise(program_name?, 'drench_new', session[:user_id]) == false #authorise_for_web(program_name?, 'Drench_new') == false
      flash[:notice] = "You don't have permission to perform this action"
      render :inline => %{
               <% @hide_content_pane = true %>
               <% @is_menu_loaded_view = true %>
      }, :layout => 'tree_node_content'
      return
    end
    session[:drench_station] = params[:id]
    @tree_node_content_header = "'create new drench_concentrate'"
    render_new_drench_concentrate
  end

  def render_new_drench_concentrate
    #	 render (inline) the edit template
    if session[:user_actions] == nil || params[:id].to_s == session[:changed_drench_station].to_s
      render :inline => %{
		<% @hide_content_pane = false %>
        <% @is_menu_loaded_view = true %>

		<%= build_drench_concentrate_form(@drench_concentrate,'create_drench_concentrate','create_drench_concentrate',false,@is_create_retry)%>

		}, :layout => 'tree_node_content'
    else
      session[:alert] = "Changes for station " + DrenchStation.find(session[:changed_drench_station]).drench_station_code + " have not been commited yet!!!" #+ session[:drench_station].to_s + " -- " + session[:changed_drench_station].to_s
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>
                       }, :layout => 'tree_node_content'
    end
  end

  #
  def convert_to_drench_concentrate_histories_record(drench_concentrate)
    drench_concentrate_history = DrenchConcentrateHistory.new
    drench_concentrate_history.drench_station_id = drench_concentrate.drench_station_id
    drench_concentrate_history.drench_line_code = drench_concentrate.drench_line_code
    drench_concentrate_history.concentrate_code = drench_concentrate.concentrate_code
    drench_concentrate_history.concentrate_description = drench_concentrate.concentrate_description
    drench_concentrate_history.drench_status_code = "closed"
    drench_concentrate_history.concentrate_product = drench_concentrate.concentrate_product
    drench_concentrate_history.concentrate_quantity = drench_concentrate.concentrate_quantity
    drench_concentrate_history.uom = drench_concentrate.uom
    drench_concentrate_history.date_created = drench_concentrate.date_created
    #drench_concentrate_history.date_to_history = Time.now.to_formatted_s(:db).to_s # should be the same for all records saved to history in the same tranaction
    drench_concentrate_history.drench_concentrate = drench_concentrate
    drench_concentrate_history.drench_station_code = drench_concentrate.drench_station_code

    return drench_concentrate_history
  end

  def save_drench_concentrates_to_history(concentrate_mixture_constituents)
    date_to_history = Time.now.to_formatted_s(:db).to_s

    if concentrate_mixture_constituents != nil
      for constituent in concentrate_mixture_constituents
        drench_concentrate_history = convert_to_drench_concentrate_histories_record(constituent)
        drench_concentrate_history.date_to_history = date_to_history
        drench_concentrate_history.save
      end
    end
  end

  def create_drench_concentrate
    begin
      @drench_station = DrenchStation.find(session[:drench_station])
      @drench_concentrate = DrenchConcentrate.new(params[:drench_concentrate])
      @drench_concentrate.date_created = Time.now.to_formatted_s(:db)
      @concentrate_product = ConcentrateProduct.find_by_concentrate_code(params[:drench_concentrate][:concentrate_code])

      @drench_concentrate.drench_station = @drench_station
      @drench_concentrate.concentrate_product = @concentrate_product
      @drench_concentrate.drench_line_code = @drench_station.drench_line_code
      @drench_concentrate.concentrate_description = @concentrate_product.concentrate_description
      @drench_concentrate.drench_status_code = @drench_station.drench_status_code
      @drench_concentrate.uom = @concentrate_product.uom
      @drench_concentrate.drench_station_code = @drench_station.drench_station_code

      if params[:drench_concentrate][:concentrate_quantity].to_i >= @concentrate_product.min_quantity && params[:drench_concentrate][:concentrate_quantity].to_i <= @concentrate_product.max_quantity

        #$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
        #$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
        #$$$$$$$$ SAVING ACTION TO SESSION STATE $$$$$$
        action_detail_hash = Hash.new
        action_detail_hash["action_type"] = "add"
        action_detail_hash["object"] = @drench_concentrate
        if session[:user_actions]
          session[:user_actions].push(action_detail_hash)
        else
          user_action_list = Array.new
          session[:changed_drench_station] = @drench_station.id #session[:drench_station]
          session[:user_actions] = user_action_list
          session[:user_actions].push(action_detail_hash)
        end

        #$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
        #$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
        #$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


        @node_name = @drench_concentrate.concentrate_code.chomp + ": " + @drench_concentrate.concentrate_quantity.to_s + @drench_concentrate.uom
        @node_type = "drench_concentrate"
        @node_id = @drench_concentrate.id.to_s
        @tree_name = "drenching"

        flash[:notice] = 'drench concentrate record was successfully added to station'

        render :inline => %{
		                       <% @hide_content_pane = true %>
                               <% @is_menu_loaded_view = false %>

                               <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>
		                        
	                            }, :layout => 'tree_node_content'
      else
        flash[:notice] = "quantity is not within this product's quantity range (" + @drench_concentrate.concentrate_product.min_quantity.to_s + "," + @drench_concentrate.concentrate_product.max_quantity.to_s + ")"
        render_new_drench_concentrate
      end

    rescue

      flash[:notice] = 'record could not be created!!! '

      render_new_drench_concentrate
    end
  end

  def delete_drench_concentrate
    if authorise(program_name?, 'drench_delete', session[:user_id]) == false #authorise_for_web(program_name?, 'Drench_new') == false
      flash[:notice] = "You don't have permission to perform this action"
      render :inline => %{
               <% @hide_content_pane = true %>
               <% @is_menu_loaded_view = true %>
      }, :layout => 'tree_node_content'
      return
    end
    begin

      id = params[:id]
      if id && drench_concentrate = DrenchConcentrate.find(id)
        @drench_station = drench_concentrate.drench_station

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#$$$$$$$$ SAVING ACTION TO SESSION STATE $$$$$$
        action_detail_hash = Hash.new
        action_detail_hash["action_type"] = "delete"
        action_detail_hash["object"] = drench_concentrate
        if session[:user_actions]
          if @drench_station.id.to_s == session[:changed_drench_station].to_s
            session[:user_actions].push(action_detail_hash)
          else
            session[:alert] = "Changes for station " + DrenchStation.find(session[:changed_drench_station]).drench_station_code + " have not been commited yet!!!"
            render :inline => %{
                     <% @hide_content_pane = true %>
                     <% @is_menu_loaded_view = true %>
                     }, :layout => 'tree_node_content'
            return
          end

        else
          user_action_list = Array.new
          session[:changed_drench_station] = @drench_station.id
          session[:user_actions] = user_action_list
          session[:user_actions].push(action_detail_hash)
        end

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

        flash[:notice] = "Drench Concentrate Record deleted. "

        render :inline => %{
                     <% @hide_content_pane = true %>
                     <% @is_menu_loaded_view = true %>
                     <% @tree_actions = "window.parent.RemoveNode(null);" %>
                     
                      }, :layout => 'tree_node_content'

      else
        session[:alert] = "Concentrate cannot be deleted.The addition of this concentrate has not been commited yet!!"
        render :inline => %{
                     <% @hide_content_pane = true %>
                     <% @is_menu_loaded_view = true %>
                     }, :layout => 'tree_node_content'
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def edit_drench_concentrate
    if authorise(program_name?, 'drench_edit', session[:user_id]) == false #authorise_for_web(program_name?, 'Drench_new') == false
      flash[:notice] = "You don't have permission to perform this action"
      render :inline => %{
               <% @hide_content_pane = true %>
               <% @is_menu_loaded_view = true %>
      }, :layout => 'tree_node_content'
      return
    end
    id = params[:id]
    if id && @drench_concentrate = DrenchConcentrate.find(id)
      session[:drench_station] = @drench_concentrate.drench_station_id
      if session[:user_actions] == nil || @drench_concentrate.drench_station_id.to_s == session[:changed_drench_station].to_s
        render_edit_drench_concentrate
      else
        session[:alert] = "Changes for station " + DrenchStation.find(session[:changed_drench_station]).drench_station_code + " have not been commited yet!!!" #+ session[:drench_station].to_s + " -- " + session[:changed_drench_station].to_s
        render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>
                       }, :layout => 'tree_node_content'

      end
    else
      session[:alert] = "Concentrate cannot be edited.The addition of this concentrate has not been commited yet!!"
      render :inline => %{
                     <% @hide_content_pane = true %>
                     <% @is_menu_loaded_view = true %>
                     }, :layout => 'tree_node_content'
    end
  end

  def render_edit_drench_concentrate
#	 render (inline) the edit template
    render :inline => %{
		<% @tree_node_content_header = "'edit drench_concentrate'"%> 
	    <% @hide_content_pane = false %>
        <% @is_menu_loaded_view = true %>

		<%= build_drench_concentrate_form(@drench_concentrate,'update_drench_concentrate','update_drench_concentrate',true)%>

		}, :layout => 'tree_node_content'
  end

  def update_drench_concentrate
    begin
      id = params[:drench_concentrate][:id]
      @drench_station = DrenchStation.find(session[:drench_station])
      if id && @drench_concentrate = DrenchConcentrate.find(id) #old record

        if params[:drench_concentrate][:concentrate_quantity].to_i >= @drench_concentrate.concentrate_product.min_quantity && params[:drench_concentrate][:concentrate_quantity].to_i <= @drench_concentrate.concentrate_product.max_quantity

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#$$$$$$$$ SAVING ACTION TO SESSION STATE $$$$$$
          @drench_concentrate.date_created = Time.now.to_formatted_s(:db)
          edit_params_array = Array.new
          edit_params_array.push(@drench_concentrate)
          edit_params_array.push(params[:drench_concentrate])

          action_detail_hash = Hash.new
          action_detail_hash["action_type"] = "edit"
          action_detail_hash["edit_array"] = edit_params_array
          if session[:user_actions]

            session[:user_actions].push(action_detail_hash)

          else
            user_action_list = Array.new
            session[:changed_drench_station] = @drench_concentrate.drench_station_id #session[:drench_station]
            session[:user_actions] = user_action_list
            session[:user_actions].push(action_detail_hash)
          end

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


          flash[:notice] = 'drench_concentrate record updated '
          @new_text = @drench_concentrate.concentrate_code.chomp + ": " + params[:drench_concentrate][:concentrate_quantity].to_s + @drench_concentrate.uom

          render :inline => %{
		                       <% @hide_content_pane = true %>
                               <% @is_menu_loaded_view = false %>
                               <% @tree_actions = render_edit_node_js(@new_text) %>		                       
		                       }, :layout => 'tree_node_content'
        else
          flash[:notice] = "quantity is not within this product's quantity range (" + @drench_concentrate.concentrate_product.min_quantity.to_s + "," + @drench_concentrate.concentrate_product.max_quantity.to_s + ")"
          render_edit_drench_concentrate
        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

def commit_concentrate_changes
    @drench_station = DrenchStation.find(session[:changed_drench_station])

    if session[:user_actions] != nil && params[:id].to_s == session[:changed_drench_station].to_s
      #Take current mixture to histories table
      save_drench_concentrates_to_history(@drench_station.drench_concentrates)
      for action in session[:user_actions]
        if action["action_type"] == "add"
          eval_string = action["object"].concentrate_code + ".save"
          action["object"].save
          puts eval_string
          puts "________________________________"
        elsif action["action_type"] == "delete"
          eval_string = action["object"].concentrate_code + ".destroy"
          action["object"].destroy
          puts eval_string
          puts "________________________________"

        elsif action["action_type"] == "edit"
          eval_string = action["edit_array"][0].concentrate_code + ".update("+ action["edit_array"][1][:concentrate_quantity] + ")"
          action["edit_array"][0].update_attributes(action["edit_array"][1])
          puts eval_string
          puts "________________________________"

        else
        end
      end
      session[:user_actions] = nil # CLEARING session[:user_actions]
      flash[:notice] = "Changes have been commited"
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>
                      <script>
                            window.parent.location.href = "/rmt_processing/drenching/drench_setups";
                      </script>
                      }, :layout => 'content'

    else
      session[:alert] = "There are no changes to commit for this station"
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>
                       }, :layout => 'tree_node_content'
    end


end
  
  def cancel_concentrate_changes

    if session[:user_actions] != nil && params[:id].to_s == session[:changed_drench_station].to_s

      session[:user_actions] = nil # CLEARING session[:user_actions]
      flash[:notice] = "Changes cancelled!!!"

      render :inline => %{
                       <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>
                      <script>
                            window.parent.location.href = "/rmt_processing/drenching/drench_setups";
                      </script>
                      }, :layout => 'content'


    else
      session[:alert] = "There are no changes for this station"
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>
                      
                      }, :layout => 'tree_node_content'
    end
  end

  def search_drench_history
    render :inline => %{
                         <%  @content_header_caption = "'search concentrate changes for a given drench station'" %>
                         <%= build_search_drench_history_form(@drench_history_search,'view_drench_history','search') %>
                         }, :layout => 'content'
  end

  def drench_concentrate_history_drench_line_code_combo_changed
    drench_line_code = get_selected_combo_value(params)
    session[:drench_concentrate_history_search_form][:drench_line_code_combo_selection] = drench_line_code

    @drench_station_codes = DrenchStation.find_by_sql("Select distinct drench_station_code from drench_stations where drench_line_code = '#{drench_line_code}'").map { |g| [g.drench_station_code] }
    @drench_station_codes.unshift("<empty>")

    #	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('drench_concentrate_history','drench_station_code',@drench_station_codes)%>
		               }

  end

  def drench_history_search_validation_failure(field)
    flash[:notice] = "Field: '#{field}' - please select/enter a value"
    search_drench_history
  end

  def view_drench_history
    object_builder = ObjectBuilder.new
    @drench_history_search = object_builder.build_hash_object({:date_from=>params[:drench_concentrate_history][:from_date2from], :date_to=>params[:drench_concentrate_history][:to_date2to], :drench_station_code=>params[:drench_concentrate_history][:drench_station_code], :drench_line_code=>params[:drench_concentrate_history][:drench_line_code]})
    if !params[:drench_concentrate_history][:from_date2from] or params[:drench_concentrate_history][:from_date2from] == nil or params[:drench_concentrate_history][:from_date2from].to_s.strip == ""
      drench_history_search_validation_failure('date from')
      return
    elsif !params[:drench_concentrate_history][:to_date2to] or params[:drench_concentrate_history][:to_date2to] == nil or params[:drench_concentrate_history][:to_date2to].to_s.strip == ""
      drench_history_search_validation_failure('date to')
      return
    elsif !params[:drench_concentrate_history][:drench_station_code] or params[:drench_concentrate_history][:drench_station_code].strip == ""
      drench_history_search_validation_failure('drench_station_code')
      return
    end

    drench_station  = DrenchStation.find_by_drench_station_code(params[:drench_concentrate_history][:drench_station_code])
    @drench_concentrate_histories = DrenchConcentrateHistory.find_by_sql("select * from drench_concentrate_histories where drench_station_code = '#{drench_station.drench_station_code}' and date_to_history >='#{params[:drench_concentrate_history][:from_date2from]}' and date_to_history <='#{params[:drench_concentrate_history][:to_date2to]}' order by date_to_history desc ") #and date_created >='#{params[:from]}' and date_to_history <'#{params[:to]}'
    @current_drench_concentrate = DrenchConcentrate.find_by_sql("select * from drench_concentrates where drench_station_code = '#{drench_station.drench_station_code}'")
    @stations_for_earlier_dates = Array.new
    @delivery_drench_concentrates = DeliveryDrenchConcentrate.find_by_sql("select distinct (delivery_drench_station_id) from delivery_drench_concentrates where drench_station_code = '#{drench_station.drench_station_code}' ")
    @last_change_time = DrenchConcentrateHistory.find_by_sql("select max(date_to_history) as last_change_time from drench_concentrate_histories where drench_station_code = '#{drench_station.drench_station_code}'")

    @increment = 0

    @content_header_caption = "'drench station " + params[:drench_concentrate_history][:drench_station_code] + " (" + params[:drench_concentrate_history][:drench_line_code] + ") setup history (from "+params[:drench_concentrate_history][:from_date2from]+ " to "+params[:drench_concentrate_history][:to_date2to]+")'"
    render :template => "rmt_processing/drenching/view_drench_history", :layout => "content"
  end

  def search_delivery_drench_allocation
    render :inline => %{
                         <%  @content_header_caption = "'search deliveries applied by a given drench station'" %>
                         <%= build_search_drench_history_form(@delivery_drench_stations,'view_delivery_drench_allocation','search') %>
                         }, :layout => 'content'
  end

  def delivery_drench_allocation_search_validation_failure(field)
    flash[:notice] = "Field: '#{field}' - please select/enter a value"
    search_delivery_drench_allocation
  end

  def view_delivery_drench_allocation
    object_builder = ObjectBuilder.new
    @delivery_drench_stations = object_builder.build_hash_object({:date_from=>params[:drench_concentrate_history][:from_date2from], :date_to=>params[:drench_concentrate_history][:to_date2to], :drench_station_code=>params[:drench_concentrate_history][:drench_station_code], :drench_line_code=>params[:drench_concentrate_history][:drench_line_code]})
    if !params[:drench_concentrate_history][:from_date2from] or params[:drench_concentrate_history][:from_date2from] == nil or params[:drench_concentrate_history][:from_date2from].to_s.strip == ""
      delivery_drench_allocation_search_validation_failure('date from')
      return
    elsif !params[:drench_concentrate_history][:to_date2to] or params[:drench_concentrate_history][:to_date2to] == nil or params[:drench_concentrate_history][:to_date2to].to_s.strip == ""
      delivery_drench_allocation_search_validation_failure('date to')
      return
    elsif !params[:drench_concentrate_history][:drench_station_code] or params[:drench_concentrate_history][:drench_station_code].strip == ""
      delivery_drench_allocation_search_validation_failure('drench_station_code')
      return
    end

    @drench_station  = DrenchStation.find_by_drench_station_code(params[:drench_concentrate_history][:drench_station_code])
    @delivery_drench_stations = DeliveryDrenchStation.find_by_sql("select * from delivery_drench_stations where drench_station_id = '#{@drench_station.id}' and date_drenched >= '#{params[:drench_concentrate_history][:from_date2from]}' and date_drenched <= '#{params[:drench_concentrate_history][:to_date2to]}' ")
    @deliveries = Array.new

    for delivery_drench_station in @delivery_drench_stations
      @delivery = Delivery.find(delivery_drench_station.delivery_id)
      @deliveries.push(@delivery)
    end


    @content_header_caption = "'deliveries drenched by " + @drench_station.drench_line_code + ":" + @drench_station.drench_station_code + " between " + params[:drench_concentrate_history][:from_date2from] + " and " + params[:drench_concentrate_history][:from_date2from] +" '"

    render :inline => %{
      <% grid            = build_delivery_grid(@deliveries,true,nil) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>
    		
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def view_concentrates
    @delivery_drench_station  = DeliveryDrenchStation.find_by_delivery_id(params[:id])
    @delivery_drench_concentrates = DeliveryDrenchConcentrate.find_by_sql("select * from delivery_drench_concentrates where delivery_drench_station_id = '#{@delivery_drench_station.id}' ")
    @content_header_caption = "'concentrate setup for delivery'"
    render :inline => %{
      <% grid            = build_delivery_drench_concentrate_grid(@delivery_drench_concentrates) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>
    		
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

# --------------------------------------------------
#   Happymore's list delivery controller method ----
# --------------------------------------------------

  def view_deliveries_drenched
    #drench_concentrate_history = DrenchConcentrateHistory.find(params[:id])

#CATER FOR CURRENT DRENCH_SETUP********************************************************

    #@delivery_drench_concentrate = DeliveryDrenchConcentrate.find_by_sql("select * from delivery_drench_concentrates where drench_station_code = '#{drench_concentrate_history.drench_station_code}' and drench_line_code = '#{drench_concentrate_history.drench_line_code}' and concentrate_code = '#{drench_concentrate_history.concentrate_code}' and concentrate_quantity = '#{drench_concentrate_history.concentrate_quantity}' and date_created < '#{drench_concentrate_history.date_to_history}'")

# CHECK WITH HANS ABOUT date_created < '#{drench_concentrate_history.date_to_history}'
    delivery_station_ids = params[:id].split('-')
    @deliveries = Array.new
    i = 1
    (delivery_station_ids.length-1).times do
      delivery_drench_station = DeliveryDrenchStation.find(delivery_station_ids[i])
      puts "One Delivery " + delivery_drench_station.delivery_id.to_s
      @delivery = Delivery.find(delivery_drench_station.delivery_id)
      @deliveries.push(@delivery)
      i += 1
    end
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#first_delivery_drench_station = DeliveryDrenchStation.find(delivery_station_ids[1])
#@drench_station = DrenchStation.find(first_delivery_drench_station.drench_station_id)
#@content_header_caption = "'deliveries drenched by " + @drench_station.drench_line_code  + ":" +  @drench_station.drench_station_code  + " between " + "??" + " and " + "??" +" '"
#puts "Same Delivery id " + @deliveries[0].id.to_s
    render :inline => %{
      <% grid            = build_delivery_grid(@deliveries,false,nil) %>
      <% grid.caption    = 'deliveries drenched' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def view_delivery
    id = params[:id]
    if id && @delivery = Delivery.find(id)
      #Test for bin scanning
      bin_scanning_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("22", id)
      if bin_scanning_route_step!=nil && bin_scanning_route_step.date_activated!= nil
        flash[:notice] = "Editing of this delivery is not allowed since bins were scanned"
        render_list_deliveries
      else

        if session[:new_delivery]!=nil
          session[:new_delivery] = nil
        end
        session[:new_delivery] = @delivery

        #session[:new_delivery_track_indicator] = nil if session[:new_delivery_track_indicator]!= nil

        if session[:delivery_track_indicators]!=nil
          session[:delivery_track_indicators] = nil
        end
        @delivery_track_indicators = DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{id}'")
        session[:delivery_track_indicators] = @delivery_track_indicators

        if session[:delivery_route_steps]!=nil
          session[:delivery_route_steps] = nil
        end
        @delivery_route_steps = DeliveryRouteStep.find_by_sql("select * from delivery_route_steps where delivery_id = '#{id}'")
        session[:delivery_route_steps] = @delivery_route_steps

        #render_view_delivery
        render :template=>'rmt_processing/drenching/view_delivery.rhtml', :layout=>'content'
      end
    end
  end

  def view_delivery_track_indicator
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    puts id.to_s
    if id && @delivery_track_indicator = DeliveryTrackIndicator.find(id)
      #Testing for bin scanning
      bin_scanning_route_step = DeliveryRouteStep.find_by_delivery_id_and_route_step_code(session[:new_delivery].id, "22")
      if bin_scanning_route_step!=nil && bin_scanning_route_step.date_activated!=nil
        flash[:notice] = "Editing of the indicator is not allowed since bins were scanned against this delivery"
        render_existing_new_delivery
      else
        render_view_delivery_track_indicator
      end
    end

  end

  def render_view_delivery_track_indicator
    #	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'view delivery track indicator'"%> 

		<%= build_view_delivery_track_indicator_form(@delivery_track_indicator,'back_to_delivery_track_indicator','back',true)%>

		}, :layout => 'content'
  end

  def back_to_delivery_track_indicator
    @delivery = session[:new_delivery]

    render :template=>'rmt_processing/drenching/view_delivery.rhtml', :layout=>'content'
  end

# -----------------
#     Test Code ---
# -----------------

  def tests
    #jsession_test
    #inventory_method_test
    @url = "http://luxolo:8080/LuksCrystal/index.jsp?username=" + session[:user_id].user_name + "&reference_type=IT_records&reference_id=1&report_type=IT&printer_name=\\ACE\jmt_printer"
    @report_user = session[:user_id].user_name
    @params_hash =  {"report_type" => "IT", "reference_id" => 1, "reference_type" => "IT_records", "username" => @report_user}
    render :inline => %{
                     click :  <%   %>
                    <%= link_to(image_tag("/images/view.png", :border => 0),generate_report_parameters(@params_hash),:popup => true) %>
                     to view a your user profile report
                       }, :layout => 'content' #Finished Running all Tests
  end

  def jsession_test

#@jsession_folder = "tmp/jsessions/"
    # @jsession_store_key = "jsession101"

#_____________________________________________________________________________________________
#get_jsession_store
    #get_jsession_store.get_session[:active_state_test] = User.new({"user_name" => "mttlux002"})


#prog_funkshin = ProgramFunction.find(553)  
#prog = Program.find(152)
#pdt_tranxie = PDTTransaction.new

    pdt_screen_def = Services::PdtController.new.handle_request
    puts "RETURNED : " + pdt_screen_def.to_s

#puts "THIS IS THE RESULT SCREEN = " + pdt_tranxie.process_transaction(self,pdt_screen_def,get_jsession_store,prog,prog_funkshin,"hans").to_s #WORKS!!!
#
#  active_state = PDTTransactionState.new(PDTTransaction.new)
#  pdt_tranxie.set_active_state(active_state)

#_____________________________________________________________________________________________


    #  persist_jsession

  end


  def inventory_method_test
    params = {"inventory_type_code"=>"inventory_type_numero_UNO",
              "object_id"=>1, "current_location_code"=>"Cold_store_1", "owner_party_role_id"=>2,
              "owner_party_code"=>"EMPLOYEE", "inventory_quantity"=>58, "transaction_type_code"=>"xaction_type_1",
              "transaction_sub_type_code"=>"xaction_type_1_sub_1", "location_from"=>"CA_1", "location_to"=>"CA_3",
              "inventory_status"=>"created", "lot_id"=>25, "route_step_code"=>nil,
              "transaction_reference_id"=>1, "quantity_plus"=>2, "quantity_minus"=>1}
    inventory_item = CreateItem.new(params)

  end
#------------------------

end
