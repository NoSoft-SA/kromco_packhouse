class Fg::LoadDetailController < ApplicationController

  def program_name?
    "load"
  end

  def bypass_generic_security?
    true
  end

  def update_edited_load_detail_pallets
    updates = {}
    params[:load_pallet].each do |k,v|
      k = k.split('_')
      key = k.shift
      if(!updates.keys.include?(key))
        updates.store(key,{k.join('_')=>v})
      else
        updates[key].store(k.join('_'),v)
      end
    end

    Pallet.transaction do
      updates.each do |update,cond|
        conditions = cond.map{|k,v|
          if(v.to_s.strip.length > 0)
            "#{k}='#{v}'"
          else
            "#{k}=NULL"
          end
        }
        Pallet.update_all(ActiveRecord::Base.extend_set_sql_with_request(conditions.join(','),"pallets"),"id = '#{update}'")
      end
    end
    @load_detail_id=session[:load_detail_id]
    session[:alert]  = "load detail pallets edited successfully"
    render :inline => %{
      <script>
        window.location.href = '/fg/load_detail/view_pallets/<%=@load_detail_id%>';
      </script>}, :layout => 'content'
  end

  def create_load_details
    load_order=LoadOrder.find_by_load_id(session[:load_id])
    session[:multi_select]="selected_order_products"
    redirect_to :controller => 'fg/order_product', :action => 'render_list_order_products', :id => load_order.order_id
  end

  def edit_pallet
    id = params[:id].to_i
    @pallet = Pallet.find("#{id}")
    session[:pallet_id]= id
    render :inline => %{
  		<% @content_header_caption = "'edit pallet'"%>

  		<%= build_edit_pallet_form(@pallet,'update_pallet','update_pallet',false,@is_create_retry)%>

  		}, :layout => 'content'
  end

  def update_pallet
    id = session[:pallet_id].to_i
    @pallet = Pallet.find("#{id}")
    @pallet.update_attributes({:remarks1, "#{params[:pallet][:remarks1]}",
                               :remarks2, "#{params[:pallet][:remarks2]}",
                               :remarks3, "#{params[:pallet][:remarks3]}",
                               :remarks4, "#{params[:pallet][:remarks4]}",
                               :remarks5, "#{params[:pallet][:remarks5]}"})
    if @pallet.save
      render :inline => %{<script>
                              alert('pallet_edited');
                              window.opener.location.reload(true);
                              window.close();

                        </script>}

    end

  end

  def set_required_quantity
    id = params[:id].to_i
    session[:load_detail_id]= id
    render_set_required_quantity
  end

  def render_set_required_quantity
    id = params[:id].to_i
    @load_detail = LoadDetail.find(id)

    render :inline => %{
          <% @content_header_caption = "'set required quantity'"%>
          <%= build_required_quantity_form(@load_detail,'update_quantity','update_quantity',true)%>
          }, :layout => 'content'
  end

  def update_quantity
    @load_id=session[:active_load]['id']
    begin
      id = session[:load_detail_id]
      required_quantity = params[:load_detail][:required_quantity].to_i
      if id && @load_detail = LoadDetail.find(id)
        @load_detail.update_attribute(:required_quantity, "#{required_quantity}")

        @order_id = @load_detail['order_id']
        flash[:notice] = 'record saved'
        render :inline => %{<script>
                                  alert('required_quantity_set');
                                  window.opener.location.href = '/fg/load_detail/list_load_details/<%=@load_id%>';
                                  window.close();
                            </script>}
      end
    end
  end

  def select_load_pallets
    id = params[:id].to_i
    session[:load_detail_id]=id
    @load_details = LoadDetail.find(id)

    dm_session["select_load_pallets_default_values"] = Hash.new()
    dm_session["select_load_pallets_default_values"]["item_pack_products.commodity_code"] =@load_details.commodity_code
    dm_session["select_load_pallets_default_values"]["extended_fgs.old_fg_code"] = @load_details.old_fg_code
    dm_session["select_load_pallets_default_values"]["cartons.target_market_code"] = @load_details.target_market_code
    dm_session["select_load_pallets_default_values"]["item_pack_products.grade_code"] = @load_details.grade_code
    dm_session["select_load_pallets_default_values"]["cartons.inventory_code"] = @load_details.inventory_code
    dm_session["select_load_pallets_default_values"]["cartons.puc"] = @load_details.puc
    dm_session["select_load_pallets_default_values"]["cartons.iso_week_code"] = @load_details.iso_week_code
    dm_session["select_load_pallets_default_values"]["cartons.season_code"] = @load_details.season_code
    dm_session["select_load_pallets_default_values"]["cartons.inspection_type_code"] = @load_details.inspection_type_code
    dm_session["select_load_pallets_default_values"]["cartons.pick_reference"] = @load_details.pick_reference
    dm_session["select_load_pallets_default_values"]["pallets.pallet_format_product_code"] = @load_details.pallet_format_product_code
    dm_session["select_load_pallets_default_values"][" cartons.pc_code"] =@load_details.pc_code
    dm_session["select_load_pallets_default_values"]["extended_fgs.old_fg_code"] = @load_details.old_fg_code
    dm_session["select_load_pallets_default_values"]["cartons.pc_code"] = @load_details.pc_code
    dm_session["select_load_pallets_default_values"][" item_pack_products.size_ref"] = @load_details.size_ref
    dm_session['se_layout'] = 'content'
    dm_session[:redirect] = true
    @content_header_caption = "'select_load_pallets'"
    order_type =OrderType.find(session[:order].order_type_id).order_type_code
    if order_type=="MO" || order_type=="MQ"
      build_remote_search_engine_form("select_mo_mq_load_pallets.yml", "select_pallets") and return
    else
      build_remote_search_engine_form("select_load_pallets.yml", "select_pallets") and return

    end

    dm_session[:redirect] = true
  end


  def select_pallets

    load_detail_id = session[:load_detail_id]
    load_detail=LoadDetail.find(load_detail_id)
    order= Order.find(load_detail.order_id)

    @pagination_server = "list_orders"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:orders_page]
    @current_page = params['page']||= session[:orders_page]
    pallets = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])

    session[:pallets]=pallets
    size = pallets.size
    @grid_selected_rows = Array.new()
    @pallets =Array.new
    for i in 0...size

      if order.is_export==true
        if  pallets[i]['qc_result_status']==nil

        elsif pallets[i]['qc_result_status'].upcase != "PASSED"

        else
          if pallets[i]['load_detail_id'].to_i == load_detail_id
            @grid_selected_rows.push(pallets[i])
          end
          @pallets << pallets[i]
        end
      else
        if pallets[i]['load_detail_id'].to_i == load_detail_id
          @grid_selected_rows.push(pallets[i])
        end
        @pallets << pallets[i]
      end
    end

    render :inline => %{
             <%
               column_configs = []
               column_configs << {:field_type=>'text', :field_name=>'pallet_number',:col_width=>140}
               column_configs << {:field_type=>'text', :field_name=>'oldest_pack_date_time',:col_width=>160}
               column_configs << {:field_type=>'text', :field_name=>'build_status',:col_width=>100}
               column_configs << {:field_type=>'text', :field_name=>'commodity_code',:column_caption=>'commodity',:col_width=>100}
               column_configs << {:field_type=>'text', :field_name=>'marketing_variety_code',:col_width=>105}
               column_configs << {:field_type=>'text', :field_name=>'target_market_code',:column_caption=>'target_market',:col_width=>215}
               column_configs << {:field_type=>'text', :field_name=>'grade_code',:column_caption=>'grade',:col_width=>90}
               column_configs << {:field_type=>'text', :field_name=>'iso_week_code',:col_width=>100}
               column_configs << {:field_type=>'text', :field_name=>'season_code',:column_caption=>'season',:col_width=>100}
               column_configs << {:field_type=>'text', :field_name=>'pallet_format_product_code',:col_width=>130}
               column_configs << {:field_type=>'text', :field_name=>'pc_code',:col_width=>160}
               column_configs << {:field_type=>'text', :field_name=>'inventory_code',:column_caption=>'inventory',:col_width=>110}
               column_configs << {:field_type=>'text', :field_name=>'carton_quantity_actual',:column_caption=>'actual_qty',:col_width=>89}
               column_configs << {:field_type=>'text', :field_name=>'puc',:col_width=>50}
               column_configs << {:field_type=>'text', :field_name=>'inspection_type_code',:column_caption=>'inspection_type',:col_width=>160}
               column_configs << {:field_type=>'text', :field_name=>'pick_reference',:column_caption=>'pick_ref',:col_width=>98}
               column_configs << {:field_type=>'text', :field_name=>'old_fg_code',:col_width=>188}
               column_configs << {:field_type=>'text', :field_name=>'actual_count',:col_width=>100}
               column_configs << {:field_type=>'text', :field_name=>'size_ref',:col_width=>100}
               column_configs << {:field_type=>'text', :field_name=>'extended_fg_code',:col_width=>590}
               column_configs << {:field_type=>'text', :field_name=>'id'}
               @multi_select = "selected_pallets"             %>
      <% grid            = get_data_grid(@pallets,column_configs,nil,true) %>
      <% grid.caption    = 'select load pallets' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@order_pages) if @order_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end

  def selected_pallets
    @load_id=session[:active_load].id
    parameter_field_values = dm_session[:parameter_fields_values]
    pallets = session[:pallets]
    load_detail_id = session[:load_detail_id].to_i
    @load_detail=LoadDetail.find("#{load_detail_id}")
    @selected_pallets = selected_records?(pallets, nil, true)

    @load_detail.selected_pallets(@selected_pallets, parameter_field_values)
    @load_detail.calc_available_quantities(pallets)
    @order_id = @load_detail['order_id'].to_i
    render :inline => %{<script>
                                alert('pallets added');
                                window.opener.location.href = '/fg/load_detail/list_load_details/<%=@load_id%>';
                                window.opener.opener.location.href = '/fg/order/edit_order/<%=@order_id%>';
                                window.close();
                          </script>}

  end


  def view_pallets
    id = params[:id].to_i
    load_detail_id = id
    @pallets = Pallet.find_by_sql("SELECT * FROM pallets WHERE load_detail_id = '#{load_detail_id}'")
    session[:query]= @pallets
    session[:load_detail_id] = id
    render_view_pallets
  end

  def render_view_pallets
    @pagination_server = "list_load_details"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:load_details_page]
    @current_page = params['page']||= session[:load_details_page]

    @use_jq_grid = true
  if @use_jq_grid
          render :template => "fg/load_details/list_load_detail_pallets", :layout => "content"
  else
    render :inline => %{
      <% grid            = build_pallets_grid(@pallets ,@can_edit,@can_delete) %>
      <% grid.caption    = 'pallets' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@load_detail_pages) if @load_detail_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end
  end

  def remove_load_detail_id
    @load_id=session[:active_load].id
    @id = params[:id].to_i
    @pallet = Pallet.find("#{@id}")
    @load_detail_id = session[:load_detail_id]
    @load_detail = LoadDetail.find(@load_detail_id)

    order=Order.find_by_sql("select orders.* from orders
                            inner join load_orders on load_orders.order_id=orders.id
                            where load_orders.id=#{@load_detail.load_order_id}")[0]

    Pallet.find_by_sql(ActiveRecord::Base.extend_update_sql_with_request("UPDATE pallets SET load_detail_id = null,remarks1 = null,  remarks2 = null,  remarks3 = null,  remarks4 = null,  remarks5 = null WHERE id = '#{@id}'"))

    order_pallet_nums=Pallet.find_by_sql("select pallets.* from pallets
                                         join load_details on (pallets.load_detail_id = load_details.id)
                                         join loads on (loads.id = load_details.load_id)
                                         join load_orders on (loads.id = load_orders.load_id)
                                         where load_orders.order_id = '#{order.id}'").map { |p| p.pallet_number }

    if order_pallet_nums.empty?
      order.downgrade_orders([order])
    end


    li_pallets =Pallet.find_all_by_load_detail_id(@load_detail.id)
    @order_id = order.id
    if li_pallets.empty?
      @load_detail.destroy
      render :inline => %{
                               <script>
                                 alert('pallet removed and load_detail destroyed');
                                 window.opener.location.href = '/fg/load_detail/re_render_list_load_details/<%=@load_id%>';
                                 window.opener.opener.location.href = '/fg/order/edit_order/<%=@order_id%>';
                                 window.close();
                               </script>
                                 }, :layout => 'content'
    else
      render :inline => %{
                               <script>
                                 alert('pallet removed');
                                 window.location.href = '/fg/load_detail/view_pallets/<%= @load_detail_id.to_s%>';
                                 window.opener.location.href = '/fg/load_detail/re_render_list_load_details/<%=@load_id%>';
                                 window.opener.opener.location.href = '/fg/order/edit_order/<%=@order_id%>';

                               </script>
                                 }, :layout => 'content'
    end


  end

  def calc_quantities(load_detail)
    required_quantity =Pallet.find_by_sql("select sum(carton_quantity) from pallets where load_detail_id=#{load_detail.id}")

  end

  def re_render_list_load_details
    load_details=LoadDetail.find_all_by_load_id(params[:id]).map { |o| o.id }
    @load_details=[]
    if !load_details.empty?
      for l_detail in session[:load_detailz]
        @load_details << l_detail if load_details.include?(l_detail.id)
      end
    end

    render_list_load_details
  end

  def set_holdover
    id = params[:id].to_i
    @pallet = Pallet.find("#{id}")
    session[:id]= id
    render :inline => %{
		<% @content_header_caption = "'holdover'"%>

		<%= build_hold_over_form(@pallet,'update_pallet_holdover','update_pallet',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_pallet_holdover
    id = session[:id].to_i
    @pallet = Pallet.find("#{id}")
    @load_detail=LoadDetail.find("#{@pallet.load_detail_id}")
    load_detail_id = session[:load_detail_id]
    holdover = params[:pallet][:holdover]
    holdover_quantity = params[:pallet][:holdover_quantity].to_i
    carton_quantity = @load_detail.set_actual_carton_count
    if carton_quantity != nil
      if holdover_quantity > carton_quantity.to_i
        flash[:error] = "'Order less quantity , required quantity not available'"
        redirect_to :controller => 'fg/load_detail', :action => 'set_holdover', :id => @pallet.id and return

      end
    end

    if   (holdover_quantity > 0 && holdover == (false || "0"))
      flash[:error] = "If holdover_quantity is greater than zero tick  holdover"
      redirect_to :controller => 'fg/load_detail', :action => 'set_holdover', :id => @pallet.id and return
    end

    if   (holdover == "1" && holdover_quantity == 0)
      flash[:error] = "If holdover_quantity is not set , untick holdover"
      redirect_to :controller => 'fg/load_detail', :action => 'set_holdover', :id => @pallet.id and return
    end


    @pallet.update_attribute(:holdover, "#{holdover}")
    @pallet.update_attribute(:holdover_quantity, "#{holdover_quantity}")
    @order_id =LoadDetail.find("#{@pallet['load_detail_id']}")['order_id']

    #holdover_quantity = @load_detail.set_holdover_quantity
    @load_detail.update_attribute(:holdover_quantity, "#{holdover_quantity}")
    if @pallet.save

      render :inline => %{<script>
                             alert('hold over changed');
                             window.opener.location.reload(true);
                             window.opener.opener.location.reload(true);
                             window.close();

                       </script>}

    end

  end


  def list_load_details
    session[:active_load]=Load.find(params[:id])
    return if authorise_for_web(program_name?, 'read') == false
    if params[:page]!= nil
      session[:load_details_page] = params['page']
      render_list_load_details
      return
    else
      session[:load_details_page] = nil
    end
    load_details = LoadDetail.find_by_sql("SELECT load_details.* FROM load_details
                    inner join load_orders on load_details.load_order_id=load_orders.id
                    inner join loads on load_orders.load_id=loads.id
                    WHERE load_orders.load_id = #{params[:id]}")
    session[:load_id]=params[:id]
    @load_details =[]
    if !load_details.empty?

      oderz ={}
      for o in load_details
        @load_details << o if !oderz.has_key?(o['id'])
        oderz[o['id']]=[o['id']]
      end

      #for li in @load_details
      #  order_product=OrderProduct.find(li.order_product_id)
      #  quantity = 0
      #  pallets=Pallet.find_all_by_load_detail_id(li.id)
      #  for pallet in pallets
      #   quantity += pallet.carton_quantity_actual.to_i
      #  end
      #  order_product.update_attributes!(:required_quantity=>quantity,:available_quantities=>quantity) if order_product.required_quantity.to_i !=quantity.to_i || order_product.available_quantities !=quantity.to_i
      #
      #  li.update_attributes!({:required_quantity => quantity,:available_quantities=> quantity
      #                                              }) if order_product.required_quantity.to_i !=quantity.to_i || order_product.available_quantities !=quantity.to_i
      #end
      session[:load_detailz]=@load_details
      session[:query] = @load_details
      session[:load_order_id] = @load_details[0].load_order_id if !@load_details.empty?


    end

    render_list_load_details
  end


  def render_list_load_details
    @pagination_server = "list_load_details"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:load_details_page]
    @current_page = params['page']||= session[:load_details_page]
    @load_details = @load_details
    if session[:load_order_id]
      load_number = Load.find_by_sql("SELECT loads.load_number FROM loads inner join load_orders on load_orders.load_id = loads.id where load_orders.id= #{session[:load_order_id].to_i} ")
      if !load_number.empty?
        load_number=load_number[0]['load_number']
      else
        load_number=""
      end
    else
      load_number=""
    end

    render :inline => %{
      <% grid            = build_load_detail_grid(@load_details,@can_edit,@can_delete) %>
      <% grid.caption    = 'Load details for load' + " " + " " +  '#{load_number}'  %>
      <% @header_content = grid.build_grid_data %>
      <% grid.height = '560' %>
      <% @pagination = pagination_links(@load_detail_pages) if @load_detail_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_load_details_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_load_detail_search_form
  end

  def render_load_detail_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  load_detail'"%>

		<%= build_load_detail_search_form(nil,'submit_load_details_search','submit_load_details_search',@is_flat_search)%>

		}, :layout => 'content'
  end


  def submit_load_details_search
    @load_details = dynamic_search(params[:load_detail], 'load_detail', 'LoadDetail')
    if @load_details.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_load_detail_search_form
    else
      render_list_load_details
    end
  end


  def delete_load_detail
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:load_details_page] = params['page']
        render_list_load_details
        return
      end
      id = params[:id]
      if id && load_detail = LoadDetail.find(id)
        load_detail.destroy
        session[:alert] = " Record deleted."
        render_list_load_details
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_load_detail
    return if authorise_for_web(program_name?, 'create')== false
    render_new_load_detail
  end

  def create_load_detail
    begin
      @load_detail = LoadDetail.new(params[:load_detail])
      if @load_detail.save

        redirect_to_index("'new record created successfully'", "'create successful'")
      else
        @is_create_retry = true
        render_new_load_detail
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_load_detail
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new load_detail'"%>

		<%= build_load_detail_form(@load_detail,'create_load_detail','create_load_detail',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_load_detail
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    if id && @load_detail = LoadDetail.find(id)
      render_edit_load_detail

    end
  end


  def render_edit_load_detail
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit load_detail'"%>

		<%= build_load_detail_form(@load_detail,'update_load_detail','update_load_detail',true)%>

		}, :layout => 'content'
  end

  def update_load_detail
    begin

      id = params[:load_detail][:id]
      if id && @load_detail = LoadDetail.find(id)
        if @load_detail.update_attributes(params[:load_detail])
          @load_details = eval(session[:query])
          flash[:notice] = 'record saved'
          render_list_load_details
        else
          render_edit_load_detail

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

  def load_detail_order_number_changed
    order_number = get_selected_combo_value(params)
    session[:load_detail_form][:order_number_combo_selection] = order_number
    @customer_party_role_ids = LoadDetail.customer_party_role_ids_for_order_number(order_number)
#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('load_detail','customer_party_role_id',@customer_party_role_ids)%>

		}

  end


end
