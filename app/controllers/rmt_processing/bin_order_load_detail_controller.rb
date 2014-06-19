class RmtProcessing::BinOrderLoadDetailController < ApplicationController

  def program_name?
    "bin_order"
  end

  def bypass_generic_security?
    true
  end

  def remove_bins
    begin
      ActiveRecord::Base.transaction do
        bin_order_load_detail=BinOrderLoadDetail.find(session[:bin_order_load_detail_id ])
        @bin_order_load_detail_id = bin_order_load_detail.id
        bin_order_load = BinOrderLoad.find(bin_order_load_detail.bin_order_load_id)
        @bin_order_id = BinOrder.find(bin_order_load.bin_order_id).id
        bins    = session[:bins]
        selected_bins = selected_records?(bins, nil, nil)
        Bin.remove_bin(selected_bins,bin_order_load.status,@bin_order_id,session[:user_id].user_name)
         render :inline => %{
                          <script>

                            window.location.href = '/rmt_processing/bin_order_load_detail/selected_quantity/<%= @bin_order_load_detail_id.to_s%>';
                            window.opener.location.reload(true);
                            window.opener.opener.location.reload(true);
                            window.opener.opener.opener.frames[1].frames[0].location.reload(true);
                            window.opener.opener.opener.frames[1].location.reload(true);
                          </script>
                            }, :layout => 'content'

      end
    rescue
      @error = build_error_div($!.to_s)
      render :inline=>%{<%= @error %>}, :layout=>'content'
    end
  end

  def bins_selected
     bins    = session[:bins]
    selected_bins = selected_records?(bins, nil, nil)
    parameter_fields_values = dm_session[:parameter_fields_values]
    BinOrderLoadDetail.remove_bins(selected_bins)
  end

  def status_history
    bin_order_load_detail_id                  = params[:id]
    @bin_order_load_detail                    = BinOrderLoadDetail.find(bin_order_load_detail_id)
    session[:status_history_status_type_code] = "bin_order_load_detail"
    session[:object_id]                       =@bin_order_load_detail.id

    redirect_to :controller => 'inventory/status_type', :action => 'show_status_history', :status_type_code => session[:status_history_status_type_code], :object_id=>session[:object_id]
  end

  def selected_quantity
    bin_order_load_detail_id = params[:id]
     session[:bin_order_load_detail_id ]= params[:id]
    @bins                    = Bin.find_by_sql("select  bins.*,deliveries.delivery_number,pack_material_products.pack_material_product_code,rmt_products.rmt_product_code,farms.farm_code ,
                               production.production_run_code ,production_runs.bins_tipped,track_slms1.track_slms_indicator_code as indicator_code1,track_slms2.track_slms_indicator_code as indicator_code2,
                               track_slms3.track_slms_indicator_code as indicator_code3,track_slms4.track_slms_indicator_code as indicator_code4,track_slms5.track_slms_indicator_code as indicator_code5,stock_items.destroyed
                               from bins
                               LEFT OUTER JOIN deliveries ON bins.delivery_id = deliveries.id
                               LEFT OUTER JOIN rmt_products ON bins.rmt_product_id = rmt_products.id
                               LEFT OUTER JOIN farms ON bins.farm_id = farms.id
                               LEFT OUTER JOIN production_runs production ON bins.production_run_rebin_id = production.id
                               LEFT OUTER JOIN production_runs ON bins.production_run_tipped_id = production_runs.id
                               LEFT OUTER JOIN pack_material_products ON bins.pack_material_product_id = pack_material_products.id
                               LEFT  JOIN track_slms_indicators track_slms1 ON bins.track_indicator1_id = track_slms1.id
                               LEFT  JOIN track_slms_indicators track_slms2 ON bins.track_indicator2_id = track_slms2.id
                               LEFT  JOIN track_slms_indicators track_slms3 ON bins.track_indicator3_id = track_slms3.id
                               LEFT  JOIN track_slms_indicators track_slms4 ON bins.track_indicator4_id = track_slms4.id
                               LEFT  JOIN track_slms_indicators track_slms5 ON bins.track_indicator5_id = track_slms5.id
                               INNER JOIN stock_items on bins.bin_number=stock_items.inventory_reference
                               WHERE
                               bins.bin_order_load_detail_id =#{bin_order_load_detail_id}")
     session[:bins] =@bins

     render :inline => %{
        <% grid            = build_bins_grid(@bins,@can_edit,@can_delete)%>
        <% grid.caption    = "bins for load detail:id #{bin_order_load_detail_id}" %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def set_required_quantity

    session[:load_detail_id]= params[:id].to_i
    render_set_required_quantity
  end

  def render_set_required_quantity

    @bin_order_load_detail = BinOrderLoadDetail.find(session[:load_detail_id])

    render :inline => %{
          <% @content_header_caption = "'set required quantity'"%>
          <%= build_required_quantity_form(@bin_order_load_detail,'update_quantity','update_quantity',true)%>
          }, :layout => 'content'
  end

  def update_quantity

    begin

      required_quantity = params[:bin_order_load_detail][:required_quantity].to_i
      if  @bin_order_load_detail = BinOrderLoadDetail.find(session[:load_detail_id])
        available_quantity = BinOrderProduct.find(@bin_order_load_detail.bin_order_product_id).available_quantity
        if available_quantity.to_i < required_quantity.to_i

          render :inline => %{
                          <script>
                            alert('REQUIRED QUANTITY EXCEEDS AVAILABLE QUANTITY');
                            window.close();
                        </script>} and return
        end

        @bin_order_load_detail.update_attribute(:required_quantity, "#{required_quantity}")
#               window.opener.location.reload(true);
#               window.opener.opener.location.reload(true);

        render :inline => %{
                          <script>
                            alert('required_quantity_set');
                            window.opener.location.reload(true);
                            window.close();
                        </script>} and return


      end

    end
  end


  def list_bin_order_load_details
    return if authorise_for_web(program_name?, 'read') == false
    session[:bin_load_id]      = params[:id].to_i
    session[:bin_order_load_id]=BinOrderLoad.find_by_bin_load_id(session[:bin_load_id]).id.to_i
    session[:order_bin_id]     =BinOrderLoad.find_by_bin_load_id(session[:bin_load_id]).bin_order_id.to_i
    if params[:page]!= nil


      session[:bin_order_load_details_page] = params['page']

      render_list_bin_order_load_details

      return
    else
      session[:bin_order_load_details_page] = nil
    end
    render_list_bin_order_load_details
  end


  def render_list_bin_order_load_details
    @pagination_server = "list_bin_order_load_details"
    @can_edit          = authorise(program_name?, 'edit', session[:user_id])
    @can_delete        = authorise(program_name?, 'delete', session[:user_id])
    @current_page      = session[:bin_order_load_details_page]
    @current_page      = params['page']||= session[:bin_order_load_details_page]
    bin_load_number    =BinLoad.find(session[:bin_load_id]).bin_load_number
    session[:bin_order_load_id]
    bin_order_load_details  = BinOrderLoadDetail.find_by_sql("select
                              bin_order_load_details.id,
                              bin_order_load_details.bin_order_product_id,
                              bin_order_products.rmt_product_code,
                              bin_order_products.available_quantity,
                              bin_order_products.commodity_code,
                              bin_order_load_details.required_quantity,
                              bin_order_products.rmt_variety_code,
                              bin_order_products.product_class_code,
                              bin_order_products.size_code,
                              bin_order_products.pc_code,
                              bin_order_products.farm_code,
                              bin_order_products.location_code,
                              bin_order_load_details.status
                              FROM bin_order_load_details
                              INNER JOIN bin_order_products ON bin_order_load_details.bin_order_product_id =bin_order_products.id
                              WHERE bin_order_load_details.bin_order_load_id =#{session[:bin_order_load_id]}")

    @bin_order_load_details = Array.new
    for @bin_order_load_detail in bin_order_load_details
      selected_quantity                           = Bin.find_by_sql("select count(bins.id) as selected_quantity
                                            from bins
                                            inner join bin_order_load_details ON bins.bin_order_load_detail_id = bin_order_load_details.id
                                            where bin_order_load_details.id = #{ @bin_order_load_detail.id}")[0]['selected_quantity']

      required_quantity                           = BinOrderProduct.find_by_sql("select required_quantity from bin_order_products where id= #{@bin_order_load_detail.bin_order_product_id}")[0]['required_quantity']

      @bin_order_load_detail['selected_quantity'] =selected_quantity.to_i
      @bin_order_load_detail['required_quantity'] =required_quantity.to_i
      @bin_order_load_details << @bin_order_load_detail
    end
    @child_form_caption = ["child_form2", "Load details for Load " + "#{bin_load_number}"]

    render :inline => %{
        <% grid            = build_bin_order_load_detail_grid(@bin_order_load_details,@can_edit,@can_delete)%>
        <% grid.caption    = 'list of all bin_order_load_details' %>
        <% @header_content = grid.build_grid_data %>

        <% @pagination = pagination_links(@bin_order_load_detail_pages) if @bin_order_load_detail_pages != nil %>
        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
  end


  def search_bin_order_load_details_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_bin_order_load_detail_search_form
  end

  def render_bin_order_load_detail_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  bin_order_load_details'"%> 

		<%= build_bin_order_load_detail_search_form(nil,'submit_bin_order_load_details_search','submit_bin_order_load_details_search',@is_flat_search)%>

		}, :layout => 'content'
  end


  def submit_bin_order_load_details_search
    @bin_order_load_details = dynamic_search(params[:bin_order_load_detail], 'bin_order_load_details', 'BinOrderLoadDetail')
    if @bin_order_load_details.length == 0
      flash[:notice]  = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_bin_order_load_detail_search_form
    else
      render_list_bin_order_load_details
    end
  end


  def delete_bin_order_load_detail
    begin
      return if authorise_for_web(program_name?, 'delete')== false
      if params[:page]
        session[:bin_order_load_details_page] = params['page']
        render_list_bin_order_load_details
        return
      end
      id = params[:id]

      if id && bin_order_load_detail = BinOrderLoadDetail.find(id)
        @bin_load_id = BinOrderLoad.find(bin_order_load_detail.bin_order_load_id).bin_load_id
        bins         = Bin.find_all_by_bin_order_load_detail_id(bin_order_load_detail.id)
        if !bins.empty?
          Bin.find_by_sql(ActiveRecord::Base.extend_update_sql_with_request("UPDATE bins SET bin_order_load_detail_id=null WHERE bin_order_load_detail_id=#{bin_order_load_detail.id}"))
        end
        bin_order_load_detail.destroy
        flash[:error] ="load detail destroyed"

        redirect_to :controller => 'rmt_processing/bin_order_load_detail', :action => 'list_bin_order_load_details', :id => @bin_load_id
      end

    end
  end

  def new_bin_order_load_detail
    return if authorise_for_web(program_name?, 'create')== false
    render_new_bin_order_load_detail
  end

  def create_bin_order_load_detail
    begin
      @bin_order_load_detail = BinOrderLoadDetail.new(params[:bin_order_load_detail])
      if @bin_order_load_detail.save

        redirect_to_index("'new record created successfully'", "'create successful'")
      else
        @is_create_retry = true
        render_new_bin_order_load_detail
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_bin_order_load_detail
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new bin_order_load_detail'"%> 

		<%= build_bin_order_load_detail_form(@bin_order_load_detail,'create_bin_order_load_detail','create_bin_order_load_detail',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_bin_order_load_detail
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    if id && @bin_order_load_detail = BinOrderLoadDetail.find(id)
      render_edit_bin_order_load_detail

    end
  end


  def render_edit_bin_order_load_detail
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit bin_order_load_detail'"%> 

		<%= build_bin_order_load_detail_form(@bin_order_load_detail,'update_bin_order_load_detail','update_bin_order_load_detail',true)%>

		}, :layout => 'content'
  end

  def update_bin_order_load_detail
    begin

      id = params[:bin_order_load_detail][:id]
      if id && @bin_order_load_detail = BinOrderLoadDetail.find(id)
        if @bin_order_load_detail.update_attributes(params[:bin_order_load_detail])
          @bin_order_load_details = eval(session[:query])
          flash[:notice]          = 'record saved'
          render_list_bin_order_load_details
        else
          render_edit_bin_order_load_detail

        end
      end
    rescue
      handle_error('record could not be saved')
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


end
