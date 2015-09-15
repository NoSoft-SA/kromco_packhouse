class RmtProcessing::BinLoadController < ApplicationController

  def program_name?
    "bin_order"
  end

  def bypass_generic_security?
    true
  end

def current_load

    @bin_load =  session[:bin_load]
    if (session[:edit_order_load] == "edit") &&  @bin_load!=nil

   redirect_to :controller => 'rmt_processing/bin_load', :action => 'edit_order_load', :id => @bin_load.id and return
    else
      render :inline=>%{<script> alert('no current load'); </script>}, :layout=>'content'
    end
  end


  def tripsheet
    report_unit ="reportUnit=/reports/MES/RMT/binsales_tripsheet&"
    report_parameters="output=pdf&bin_order_load_id=" +"#{params[:id].to_i}"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)
  end

  def  delivery_note

    report_unit ="reportUnit=/reports/MES/RMT/binsales_delivery_note&"
    report_parameters="output=pdf&bin_order_load_id=" +"#{params[:id].to_i}"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)
  end

  def delivery

     report_unit ="reportUnit=/reports/MES/RMT/binsales_delivery_note&"
    report_parameters="output=pdf&bin_order_load_id=" +"#{params[:id].to_i}"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)
  end

  def status_history
  bin_load_id = params[:id]
    @bin_load = BinLoad.find( bin_load_id)
    session[:status_history_status_type_code] =  "bin_load"
     session[:object_id]=@bin_load.id

    redirect_to :controller => 'inventory/status_type', :action => 'show_status_history', :status_type_code => session[:status_history_status_type_code]  ,:object_id=>session[:object_id]
end

  def order_loads
    session[:bin_order_id]    = params[:id]
    session[:bin_order_loads] = BinOrderLoad.find_by_sql("select
                      bin_loads.bin_load_number,
                      bin_loads.status,
                      parties_roles.party_name as haulier,
                      bin_loads.vehicle_license_number,
                      locations.location_code as weigh_bridge_location,
                      bin_loads.tare_mass_in,
                      bin_loads.tare_mass_out,
                      bin_loads.vehicle_empty_mass_in as vehicle_empty_mass,
                      bin_loads.id,
                      bin_loads.vehicle_full_mass_out as vehicle_full_mass,
                      bin_loads.created_on,
                      load_types.load_type_code as load_type
                      FROM
                      bin_order_loads
                      INNER JOIN bin_loads ON bin_order_loads.bin_load_id =bin_loads.id
                      INNER JOIN parties_roles ON bin_loads.haulier_party_role_id =parties_roles.id
                      INNER JOIN locations ON bin_loads.weigh_bridge_location_id = locations.id
                      INNER JOIN load_types ON bin_loads.load_type_id= load_types.id
                      where
                      bin_order_loads.bin_order_id = #{session[:bin_order_id] }")
    render_order_load_grid
  end

  def render_order_load_grid

    @can_edit       = authorise(program_name?, 'edit', session[:user_id])
    @can_delete     = authorise(program_name?, 'delete', session[:user_id])
    @id             = session[:bin_order_id]
    bin_order_loads=session[:bin_order_loads]
    @bin_order_loads=Array.new
    for bin_order_load in bin_order_loads
      bin_order_load_id =BinOrderLoad.find_by_bin_load_id(bin_order_load.id).id
      load_details=BinOrderLoadDetail.find_all_by_bin_order_load_id(bin_order_load_id)
      if !load_details.empty?
        bin_order_load['load_detail']="true"
      else
        bin_order_load['load_detail']="false"
      end
      @bin_order_loads << bin_order_load
    end


      render :inline => %{
        <% grid            = build_order_load_grid(@bin_order_loads,@can_edit,@can_delete)%>
        <% grid.caption    = 'list of all bin_order_loads' %>
        <% @header_content = grid.build_grid_data %>

        <% @pagination = pagination_links(@bin_order_load_pages) if @bin_load_pages != nil %>
        <%= grid.render_html %>
        <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def send_edi
      begin
      bin_order_load = BinOrderLoad.find(params[:id].to_i)
      bin_load       =BinLoad.find(bin_order_load.bin_load_id)

       EdiOutProposal.send_doc(bin_order_load,'hbs')
       render :inline => %{<script>
                                 alert('edi send successfully');
                                  window.close();
                        </script>}


        rescue
      @error = build_error_div($!.to_s)
      render :inline=>%{<%= @error %>},:layout=>'content'
       end
  end

  def complete_load
    begin
      ActiveRecord::Base.transaction do
        bin_load_id     = params[:id]
        @bin_load       =BinLoad.find(bin_load_id)
        @bin_order_load = BinOrderLoad.find_by_bin_load_id(bin_load_id)
        bin_order_id    = @bin_order_load.bin_order_id
        @bin_order      =BinOrder.find(bin_order_id)
        @bin_load_id = @bin_load.id
        mass_attrs      =@bin_load.attributes
        trading_partner_1st_letter = PartiesRole.find_by_sql("select party_name from parties_roles where id =#{@bin_order.trading_partner_party_role_id}")[0].party_name.split(//)
        order_type_code=OrderType.find_by_sql("select order_type_code from order_types where id = #{@bin_order.order_type_id}")[0].order_type_code
        if mass_attrs['vehicle_empty_mass_in']==nil || mass_attrs['tare_mass_out']==nil || mass_attrs['tare_mass_in']==nil || mass_attrs['vehicle_full_mass_out']==nil
          flash[:error] ="All the mass fields must be captured"
          redirect_to :controller => 'rmt_processing/bin_load', :action => 'edit_order_load', :id => @bin_load.id and return
        end

        #@bin_load.empty_bins_moved?
        location_to =PartiesRole.find(@bin_order.trading_partner_party_role_id).party_name
        bin_nums    =Bin.find_by_sql("select bin_number from bins
                    inner join stock_items on bins.bin_number = stock_items.inventory_reference
                    inner join bin_order_load_details on bin_order_load_details.id = bins.bin_order_load_detail_id
                    inner join bin_order_loads on bin_order_load_details.bin_order_load_id =bin_order_loads.id
                    where ((stock_items.destroyed is null OR stock_items.destroyed=false)and bin_order_loads.id =#{@bin_order_load.id} )").map{|b|b.bin_number}

        scrapped_time = Time.now

         if !bin_nums.empty?
           Bin.bulk_update({:exit_ref =>"'#{@bin_order_load.id}'"}, 'bin_number', bin_nums, nil)
           Bin.bulk_update({:exit_reference_date_time =>"'#{scrapped_time}'"}, 'bin_number', bin_nums, nil)

           Inventory.move_stock('BIN_SALES', @bin_order_load.id.to_s, location_to, bin_nums)
           Inventory.remove_stock(nil, 'BIN', 'BIN_SALES', @bin_order_load.id.to_s, location_to, bin_nums)


           #Inventory.remove_stock(truck_code,stock_type,trans_name,trans_id,location,stock_ids)
           StatusMan.set_status("COMPLETE", "bin_order_load", @bin_order_load,session[:user_id].user_name)
           StatusMan.set_status("COMPLETE","bin_load",@bin_load,session[:user_id].user_name)


           order_not_complete_query = "select count(*) from bin_order_loads where status <> 'COMPLETE' and bin_order_id = #{@bin_order_load.bin_order_id.to_s}"
           n_incomplete   = Bin.connection.select_one(order_not_complete_query)['count'].to_i

           StatusMan.set_status("COMPLETE","bin_order",@bin_order_load.bin_order,session[:user_id].user_name)  if  n_incomplete == 0
          if  order_type_code=="NS"|| trading_partner_1st_letter[0]== "2"
          else
             EdiOutProposal.send_doc(@bin_order_load,'hbs')
          end
         else
            flash[:error] = "Load_could not be completed- there are no bins to complete"
           redirect_to :controller => 'rmt_processing/bin_load', :action =>'edit_order_load', :id => @bin_load.id and return

         end

        if @bin_order_load.status == "COMPLETE"
#          flash[:notice] = "LOAD_COMPLETED"
#          redirect_to :controller => 'rmt_processing/bin_load', :action =>'edit_order_load', :id => @bin_load.id and return
          render :inline => %{<script>
                                    window.location.href= "/rmt_processing/bin_load/edit_order_load/<%=@bin_load_id.to_s%>";
                                    window.opener.location.reload(true);
                                    window.opener.opener.frames[1].frames[0].location.reload(true);
                                    window.opener.opener.frames[1].location.reload(true);
                                     </script>}




        else
          flash[:error] = "Load_could not be completed"
          redirect_to :controller => 'rmt_processing/bin_load', :action =>'edit_order_load', :id => @bin_load.id and return
        end
      end
    rescue
      @error = build_error_div($!.to_s)
      render :inline=>%{<%= @error %>},:layout=>'content'
    end
  end

def build_error_div(validations_error)
    valication_error_container = "
        <table id='validation_error_container' border='0' style='background: whitesmoke;font-family: verdana;font-size: 12px;border-collapse: collapse;width: 100%;height: 100px;width: 500px;border: red solid 2px;'>
          <tr style='font-weight: bold;color: white;height: 25px;background: #CC3333;'>
            <td> 1 error prohibited this record from being saved</td>
          </tr>
          <tr style='height: 10px;'>
            <td>&nbsp;&nbsp;&nbsp;There were problems with the following fields</td>
          </tr>
          <tr style='height: 75px;'>
            <td style='padding-left: 50px;'>
              <li>#{validations_error}</li>
            </td>
          </tr>
        </table>
        <script>
          flash = document.getElementById('validation_error_container').parentNode;
          flash.style.border = 'none';
          flash.style.background = 'white';
        </script>
      "
  end


  def add_load_details


    session[:bin_load_id]         = params[:id].to_i
    session[:order_bin_id]        =BinOrderLoad.find_by_bin_load_id(session[:bin_load_id]).bin_order_id.to_i
    bin_order_load_id             = BinOrderLoad.find_by_bin_load_id(session[:bin_load_id]).id.to_i

    @load_order_products          = OrderProduct.find_by_sql("select bin_order_products.*

                            from bin_order_products
                            where  bin_order_products.bin_order_id = #{session[:order_bin_id]} AND
                            bin_order_products.id  NOT IN
                            (select bin_order_load_details.bin_order_product_id
                            from bin_order_load_details
                            inner join bin_order_products ON bin_order_load_details.bin_order_product_id=bin_order_products.id
                            inner join bin_order_loads ON bin_order_load_details.bin_order_load_id=bin_order_loads.id
                            where bin_order_load_details.bin_order_load_id = #{bin_order_load_id} OR bin_order_products.status ='LOADED')
                            GROUP BY bin_order_products.id,bin_order_products.rmt_product_code,bin_order_products.commodity_code,bin_order_products.rmt_variety_code,
                            bin_order_products.product_class_code,bin_order_products.status,bin_order_products.pc_code,
                            bin_order_products.size_code,bin_order_products.location_code,bin_order_products.farm_code,bin_order_products.rmt_product_code,
                            bin_order_products.bin_order_id,bin_order_products.available_quantity,
                            bin_order_products.id,bin_order_products.required_quantity")
    session[:load_order_products] = @load_order_products


      @column_configs = []
      @column_configs << {:field_type=>'text', :field_name=>'rmt_product_code',:col_width=>272}
      @column_configs << {:field_type=>'text', :field_name=>'available_quantity',:column_caption=>'Available', :col_width => 100}
      @column_configs << {:field_type=>'text', :field_name=>'required_quantity',:column_caption=>'Required', :col_width => 100}
      @column_configs << {:field_type=>'text', :field_name=>'commodity_code',:column_caption=>'commodity', :col_width => 100}
      @column_configs << {:field_type=>'text', :field_name=>'variety_code',:column_caption=>'variety', :col_width => 81}
      @column_configs << {:field_type=>'text', :field_name=>'product_class_code',:column_caption=>'product_class', :col_width => 110}
      @column_configs << {:field_type=>'text', :field_name=>'size_code',:column_caption=>'size', :col_width => 75}
      @column_configs << {:field_type=>'text', :field_name=>'farm_code',:column_caption=>'farm', :col_width => 122}
      @column_configs << {:field_type=>'text', :field_name=>'location_code',:column_caption=>'location', :col_width => 138}
      @column_configs << {:field_type=>'text', :field_name=>'id'}
      @multi_select = "load_details_selected"

      render :inline => %{
        <% grid            = get_data_grid(@load_order_products,@column_configs,nil,true)%>
        <% grid.caption    = 'load_details' %>
        <% @header_content = grid.build_grid_data %>

        <% @pagination = pagination_links(@bin_order_pages) if @bin_order_pages != nil %>
        <%= grid.render_html %>
        <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def load_details_selected
    @id                     = session[:bin_load_id]
    @bin_load               = BinLoad.find(@id)
    load_detail_products    = session[:load_order_products]
    selected_order_products = selected_records?(load_detail_products, nil, nil)
    parameter_fields_values = dm_session[:parameter_fields_values]
    @bin_load.selected_load_details(selected_order_products, parameter_fields_values,session[:user_id].user_name)
    render :inline => %{<script>
                                 window.opener.location.reload(true);
                                  window.close();
                        </script>}

  end

  def list_bin_loads
    return if authorise_for_web(program_name?, 'read') == false

    if params[:page]!= nil

      session[:bin_loads_page] = params['page']

      render_list_bin_loads

      return
    else
      session[:bin_loads_page] = nil
    end

    list_query      = "@bin_load_pages = Paginator.new self, BinLoad.count, @@page_size,@current_page
	 @bin_loads = BinLoad.find(:all,
				 :limit => @bin_load_pages.items_per_page,
				 :offset => @bin_load_pages.current.offset)"
    session[:query] = list_query
    render_list_bin_loads
  end


  def render_list_bin_loads
    @pagination_server = "list_bin_loads"
    @can_edit          = authorise(program_name?, 'edit', session[:user_id])
    @can_delete        = authorise(program_name?, 'delete', session[:user_id])
    @current_page      = session[:bin_loads_page]
    @current_page      = params['page']||= session[:bin_loads_page]
    @bin_loads = eval(session[:query]) if !@bin_loads

      render :inline => %{
        <% grid            = build_bin_load_grid(@bin_loads,@can_edit,@can_delete)%>
        <% grid.caption    = 'list of all bin_loads' %>
        <% @header_content = grid.build_grid_data %>

        <% @pagination = pagination_links(@bin_load_pages) if @bin_load_pages != nil %>
        <%= grid.render_html %>
        <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_bin_loads_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_bin_load_search_form
  end

  def render_bin_load_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  bin_loads'"%>

		<%= build_bin_load_search_form(nil,'submit_bin_loads_search','submit_bin_loads_search',@is_flat_search)%>

		}, :layout => 'content'
  end


  def submit_bin_loads_search
    @bin_loads = dynamic_search(params[:bin_load], 'bin_loads', 'BinLoad')
    if @bin_loads.length == 0
      flash[:notice]  = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_bin_load_search_form
    else
      render_list_bin_loads
    end
  end


  def delete_bin_load
    begin
      ActiveRecord::Base.transaction do
        return if authorise_for_web(program_name?, 'delete')== false
        if params[:page]
          session[:bin_loads_page] = params['page']
          render_list_bin_loads
          return
        end
        id = params[:id]
        if id && bin_load = BinLoad.find(id)
          bin_order_load =BinOrderLoad.find_by_bin_load_id(id)
          bin_order_load_details =BinOrderLoadDetail.find_all_by_bin_order_load_id(bin_order_load.id)
          if !bin_order_load_details.empty?
            for @bin_order_load_detail in bin_order_load_details
              bins =Bin.find_all_by_bin_order_load_detail_id(@bin_order_load_detail.id)
              if !bins.empty?
                for @bin in bins
                  Bin.find_by_sql(ActiveRecord::Base.extend_update_sql_with_request("UPDATE bins SET bin_order_load_detail_id = null WHERE bin_order_load_detail_id= '#{ @bin_order_load_detail.id}'"))
                end
              end
              @bin_order_load_detail.destroy
            end
          end
        end
        BinOrderLoad.destroy
        bin_load.destroy
        session[:alert] = " Record deleted."
        render_list_bin_loads
      end


    end

  end

  def new_load_for_order
    return if authorise_for_web(program_name?, 'create')== false
    session[:bin_order_id] = session[:bin_order_id]
    render_new_bin_load
  end

  def render_new_bin_load

    render :inline => %{
             <% @content_header_caption = "'new_bin_order_load  '" %>

             <%= build_bin_load_form(@bin_load,'create_bin_load','create_bin_load',false,@is_create_retry)%>

             }, :layout => 'content'
  end

  def


  create_bin_load

    begin
      bin_order_id = session[:bin_order_id]
      ActiveRecord::Base.transaction do
        @bin_load                 = BinLoad.new(params[:bin_load])
        @bin_load.bin_load_number = MesControlFile.next_seq_web(9)
        @bin_load.created_on      = Time.now
        @bin_load.username        = session[:user_id].user_name
       if @bin_load.save
        StatusMan.set_status("LOAD_CREATED","bin_load",@bin_load,session[:user_id].user_name)
          @bin_order_load              =BinOrderLoad.new
          @bin_order_load.bin_order_id = session[:bin_order_id]
          @bin_order_load.bin_load_id  =@bin_load.id
           if @bin_order_load.save
           StatusMan.set_status("LOAD_CREATED", "bin_order_load", @bin_order_load,session[:user_id].user_name)
            @bin_load_id = @bin_load.id
            session[:bin_load] =@bin_load

            render :inline => %{<script>
                             window.location.href= "/rmt_processing/bin_load/edit_order_load/<%=@bin_load_id.to_s%>";
                              window.opener.location.reload(true);
                            </script>}

          end
        else

          @is_create_retry = true
          render_new_bin_load

        end

      end
    rescue
      handle_error('record could not be created')
    end
  end

  def edit_order_load
    return if authorise_for_web(program_name?,'edit')==false
     session[:edit_order_load] = "edit"
    session[:bin_load_id] =params[:id]
    @bin_load =BinLoad.find(session[:bin_load_id])
     session[:bin_load] = @bin_load
    @bin_load_number =@bin_load.bin_load_number
    @caption = "edit bin_order_load   #{@bin_load_number.to_s}  "

    render :inline => %{
		<% @content_header_caption = " '#{@caption}'"%>

		<%= build_bin_load_form(@bin_load,'update_bin_load','update_bin_load',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_bin_load

    begin
      ActiveRecord::Base.transaction do
        @bin_load_id = session[:bin_load_id]

        if @bin_load_id && @bin_load = BinLoad.find(@bin_load_id)
          if @bin_load.update_attributes(params[:bin_load])

            render :inline => %{<script>
                            window.location.href= "/rmt_processing/bin_load/edit_order_load/<%=@bin_load_id.to_s%>";
                           window.opener.location.reload(true);

                            </script>} and return
          else
                      render_new_bin_load
          end
        end

      end
    rescue
      handle_error('record could not be saved')
    end

  end


end
