class Fg::DepotReceiptsController < ApplicationController

  def program_name?
    "depot_receipts"
  end

  def bypass_generic_security?
    true
  end


  def delete_intake_header

     intake_header= IntakeHeader.find(params[:id].to_i)
    ActiveRecord::Base.transaction do
    if  intake_header.destroy
          session[:alert] = " intake_header deleted."
          @intake_headers = IntakeHeader.find(:all)
          recent_depot_intakes
        else
          session[:alert] = " Record could not be deleted."
        end
    end
  end

 def depot_pallets
   intake_header_id  = params[:id]
   @depot_pallets = DepotPallet.find_by_sql(
                  "select depot_pallets .*,
                  (select pallet_sequence_number from pallet_sequences where pallet_sequences.depot_pallet_id = depot_pallets.id and depot_pallets.intake_header_id = #{intake_header_id} order by id asc limit 1) as pallet_sequence_number
                  from depot_pallets
                  where depot_pallets.intake_header_id = #{intake_header_id}")

    session[:depot_pallets] =@depot_pallets
    render :inline => %{
      <% grid            = build_depot_pallets_grid(@depot_pallets,@can_edit,@can_delete) %>
      <% grid.caption    = 'depot_pallets' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

 end

  def selected_pallets
    depot_pallets =  session[:depot_pallets]
    selected_pallets  = selected_records?(depot_pallets, nil, nil)
    DepotPallet.remove_pallets(selected_pallets)
     render :inline => %{
                          <script>
                           alert("pallets removed!");
                            window.close();
                            window.opener.frames[1].location.reload(true);
                            </script>
                            }, :layout => 'content'
  end

  def new_header

    return if authorise_for_web(program_name?,'create') == false
    
    render_new_header
  end


  def transfer_ppecb_inspection

    header = IntakeHeader.find(params[:id].to_i)
    header.create_inspection_records

      render :inline => %{
        <script>
          alert ('done');
          window.close();
        </script>
		}, :layout => 'content'

  end

  def render_new_header
    render :inline => %{
		<% @content_header_caption = "'create new consignment(intake header)'"%>

		<%= build_intake_header_form(@intake_header,'create_intake_header','create intake header',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_intake_header
    begin
       @intake_header = IntakeHeader.new(params[:intake_header])
       @intake_header.intake_header_number = MesControlFile.next_seq_web(5)     #"18672722777"
       @intake_header.header_status = "HEADER_CREATED"
    	 if @intake_header.save
             session[:intake_header] =  @intake_header
    		 flash[:notice]= "'intake header record created successfully'"
             render_edit_intake_header
    	 else
    		@is_create_retry = true
    		render_new_header
    	 end
    rescue
       handle_error("intake header record could not be created")
    end
  end


  def edit_intake_header
    id = params[:id]
    if id && @intake_header = IntakeHeader.find(id)
        session[:intake_header] = @intake_header

        render_edit_intake_header
     else

     end
  end

  def render_edit_intake_header
    session[:invalid_pallet_sequences] = nil
    if(session[:intake_header])
      query = "SELECT pallet_sequences.id,pallet_sequences.class_code, pallet_sequences.depot_pallet_number,pallet_sequences.pallet_sequence_number, pallet_sequences.commodity,pallet_sequences.inventory_code, pallet_sequences.variety, pallet_sequences.grade,"
      query += "pallet_sequences.count, pallet_sequences.brand, pallet_sequences.pack_type, pallet_sequences.organization, pallet_sequences.puc,"
      query += "pallet_sequences.product_characteristics, pallet_sequences.remarks, pallet_sequences.target_market, pallet_sequences.sell_by_date,"
      query += "pallet_sequences.pick_reference, pallet_sequences.mapped_date_time, mapped_pallet_sequences.extended_fg_code, intake_headers.header_status, (substr(pallet_sequences.pick_reference,4,4) || substr(pallet_sequences.pick_reference,1,1)) as iso_week "
      query += "FROM ((pallet_sequences JOIN depot_pallets ON(pallet_sequences.depot_pallet_id = depot_pallets.id) JOIN intake_headers ON(intake_headers.id=depot_pallets.intake_header_id) LEFT JOIN mapped_pallet_sequences ON pallet_sequences.id=mapped_pallet_sequences.pallet_sequence_id)) "
      query += " WHERE intake_headers.id = '#{session[:intake_header].id}'"
      session[:invalid_pallet_sequences] = PalletSequence.connection.select_all(query).find_all{|p| (p && (((p['pick_reference'][3,4] + p['pick_reference'][0,1]).to_i < 1) || ((p['pick_reference'][3,4] + p['pick_reference'][0,1]).to_i > 52 )) )}
    end

    render :inline => %{
		<% @content_header_caption = "'edit intake header'"%>

		<%= build_intake_header_form(@intake_header,'update_intake_header','update intake header',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def show_invalid_pick_ref_pallet_sequences
    @pallet_sequences = session[:invalid_pallet_sequences]
    render_list_header_pallet_sequences_grid
  end

  def update_intake_header
    id = params[:intake_header][:id]
    intake_header = IntakeHeader.find(id)

    intake_header.order_number = params[:intake_header][:order_number]
    intake_header.intake_type_code = params[:intake_header][:intake_type_code]
    intake_header.depot_code = params[:intake_header][:depot_code]
    intake_header.puc_code = params[:intake_header][:puc_code]
    intake_header.account_code = params[:intake_header][:account_code]
    intake_header.carrier = params[:intake_header][:carrier]
    intake_header.truck_number = params[:intake_header][:truck_number]
    intake_header.supplier_code = params[:intake_header][:supplier_code]
    intake_header.location_code = params[:intake_header][:location_code]
    intake_header.qty_pallets = params[:intake_header][:qty_pallets]
    intake_header.qty_cartons = params[:intake_header][:qty_cartons]
    intake_header.season = params[:intake_header][:season]
    intake_header.packhouse_code = params[:intake_header][:packhouse_code]
    intake_header.inspection_type_code = params[:intake_header][:inspection_type_code]
    intake_header.inspector_number = params[:intake_header][:inspector_number]
    intake_header.inspection_point = params[:intake_header][:inspection_point]
    intake_header.inspection_date = params[:intake_header][:inspection_date]

    recool_required = params[:intake_header][:recool_required]
    required = recool_required.class.to_s == "String" && recool_required === "1"
    if required
      intake_header.recool_temperature = params[:intake_header][:recool_temperature]
      intake_header.recool_average_temperature = params[:intake_header][:recool_average_temperature]
    end
    intake_header.pallet_base_code = params[:intake_header][:pallet_base_code]
    intake_header.organization_code = params[:intake_header][:organization_code]
    intake_header.client_reference = params[:intake_header][:client_reference]
    intake_header.edi_transfer_in = params[:intake_header][:edi_transfer_in]
    intake_header.qty_cartons = params[:intake_header][:qty_cartons]
    intake_header.transfer_inspection_records = params[:intake_header][:transfer_inspection_records]

    if intake_header.update
      flash[:notice] = "intake header updated successifully!"
      session[:intake_header] = intake_header
      active_intake_header
    else
      raise("intake header could not be updated")
    end

  end


  def render_list_intake_headers
    @can_edit = authorise(program_name?,'edit',session[:user_id])
  	@can_delete = authorise(program_name?,'delete',session[:user_id])

  	@intake_headers =  Carton.connection.select_all(dm_session[:search_engine_query_definition])
    list_intake_headers
  end

  def list_intake_headers
    render :inline => %{
      <% grid            = build_intake_headers_grid(@intake_headers,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of intake headers' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@intake_headers_pages) if @intake_headers_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def print_depots_receipt
    intake_header_id = params[:id]
    report_unit ="reportUnit=/reports/MES/FG/depot_intake&"
    report_parameters= "output=pdf&intake_header_id=" + "#{intake_header_id}"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password +  report_parameters)
  end

  def find_intake_headers
  	return if authorise_for_web(program_name?,'read')== false
     dm_session['se_layout'] = 'content'
     @content_header_caption = "'search depot intake headers'"
     dm_session[:redirect] = true
  	 build_remote_search_engine_form("search_depot_intake_headers.yml", "render_list_intake_headers")

  end

  def accept_intake_header
     header = IntakeHeader.find(params[:id].to_i)
     header.header_status = "HEADER_CREATED"
     if header.unique?
           header.update
           flash[:notice] = "header accepted"

     else
       flash[:error] = "There already is an intake header with consignment number: " + header.consignment_note_number.to_s
     end

     render_list_intake_headers
  end


  def cancel_intake_header

    header = IntakeHeader.find(params[:id].to_i)
    header.header_status = "CANCELED"
    header.update
    flash[:notice] = "header canceled"
    render_list_intake_headers

  end

  def render_intake_headers_search_form(is_flat_search = nil)
  	session[:is_flat_search] = @is_flat_search
    # render (inline) the search form
  	render :inline => %{
  		<% @content_header_caption = "'search intake headers'"%>

  		<%= build_intake_headers_search_form(nil,'submit_intake_headers_search','submit_intake_headers_search',@is_flat_search)%>

  		}, :layout => 'content'
  end

  def submit_intake_headers_search
  	if params['page']
  		session[:intake_headers_page] =params['page']
  	else
  		session[:intake_headers_page] = nil
  	end
  	@current_page = params['page']
  	if params[:page]== nil
  		 @intake_headers = dynamic_search(params[:intake_header] ,'intake_headers','IntakeHeader')
  	else
  		@intake_headers = eval(session[:query])
  	end
  	if @intake_headers.length == 0
  		if params[:page] == nil
  			flash[:notice] = 'no records were found for the query'
  			@is_flat_search = session[:is_flat_search].to_s
  			render_intake_headers_search_form
  		else
  			flash[:notice] = 'There are no more records'
  			render_list_intake_headers
  		end

  	else
  		render_list_intake_headers
  	end
  end


  def process_history
    id = params[:id]
    puts "ID := " + id.to_s
    @intake_header = IntakeHeader.find(id)
    render :inline=>%{
      <% @content_header_caption = "'process history'"%>

  		<%= build_process_history_form(@intake_header,'close_process_history_form','close')%>
    }, :layout=>'content'
  end

  def close_process_history_form
    render :inline=>%{
        <script>
          window.close();
        </script>
    }
  end

  def edi_process_history
    id = params[:id]
    @intake_header_statuses = IntakeHeaderStatus.find_by_sql("SELECT * FROM intake_header_statuses WHERE intake_header_id='#{id}'")
    render :inline => %{
      <% grid            = build_edi_process_history_grid(@intake_header_statuses) %>
      <% grid.caption    = 'intake header statuses' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@intake_header_statuses_pages) if @intake_header_statuses_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end


  def pallet_sequence_frame
    render :inline => %{

        <%= build_pallet_sequence_frame(@child_form,'pallet_sequences','list pallet sequences',@is_edit)%>

      },:layout => 'content'
  end


  def pallet_sequences
    intake_header = session[:intake_header]
    query = "SELECT pallet_sequences.id,pallet_sequences.class_code, pallet_sequences.depot_pallet_number,pallet_sequences.pallet_sequence_number, pallet_sequences.commodity,pallet_sequences.inventory_code, pallet_sequences.variety, pallet_sequences.grade,"
    query += "pallet_sequences.count, pallet_sequences.brand, pallet_sequences.pack_type, pallet_sequences.organization, pallet_sequences.puc,"
    query += "pallet_sequences.product_characteristics, pallet_sequences.remarks, pallet_sequences.target_market, pallet_sequences.sell_by_date,"
    query += "pallet_sequences.pick_reference, pallet_sequences.mapped_date_time, mapped_pallet_sequences.extended_fg_code, intake_headers.header_status, (substr(pallet_sequences.pick_reference,4,4) || substr(pallet_sequences.pick_reference,1,1)) as iso_week "
    query += "FROM ((pallet_sequences JOIN depot_pallets ON(pallet_sequences.depot_pallet_id = depot_pallets.id) JOIN intake_headers ON(intake_headers.id=depot_pallets.intake_header_id) LEFT JOIN mapped_pallet_sequences ON pallet_sequences.id=mapped_pallet_sequences.pallet_sequence_id)) "
    query += " WHERE intake_headers.id = '#{intake_header.id}'"
    @pallet_sequences = PalletSequence.connection.select_all(query)
    render_list_header_pallet_sequences_grid
  end

  def render_list_header_pallet_sequences_grid
    render :inline => %{
      <% grid            = build_pallet_sequences_grid(@pallet_sequences) %>
      <% grid.caption    = 'pallet sequences' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@pallet_sequences_pages) if @pallet_sequences_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end

  def new_pallet_sequence
    return if authorise_for_web(program_name?,'create') == false
    render_new_pallet_sequence
  end

  def render_new_pallet_sequence
    render :inline => %{
		<% @content_header_caption = "'create new pallet sequence'"%>

		<%= build_pallet_sequence_form(@pallet_sequence,'create_pallet_sequence','save',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_pallet_sequence
    begin
       @pallet_sequence = PalletSequence.new(params[:pallet_sequence])
       if session[:intake_header]
          @pallet_sequence.intake_header_id = session[:intake_header].id
       end
       if @pallet_sequence.new_record?
         if @pallet_sequence.save
           @url_base = "http://" + request.host_with_port + "/" + "fg/depot_receipts/pallet_sequences"
           render :inline=>%{
              <%= close_popup_reload_main_window('pallet sequence record saved successfully') %>
            }, :layout => 'content'
             #<%= close_popup_reload_child_window_by_pos('location setup record saved successfully',1) %>
         else
          @is_create_retry = true
          render_new_pallet_sequence
         end
       else
         handle_error("pallet_sequence record already exists!")
       end
    rescue
       handle_error("pallet_sequence record could not be created")
    end
  end

  def edit_pallet_sequence
    render_edit_pallet_sequence
  end

  def render_edit_pallet_sequence
    id =params[:id]
    if !id
      id = session[:pallet_seq_id]
    end
    @pallet_sequence = PalletSequence.find(id)
    render_pallet_sequence_form
  end

  def render_pallet_sequence_form
    render :inline => %{
		<% @content_header_caption = "'edit pallet sequence'"%>
		<%= build_pallet_sequence_form(@pallet_sequence,'update_pallet_sequence','update',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_pallet_sequence
    begin
      id = params[:pallet_sequence][:id]
      if id && @pallet_sequence = PalletSequence.find(id)

        #if(params[:pallet_sequence][:pick_reference])
        #  iso_week = (params[:pallet_sequence][:pick_reference].to_s[3,4] + params[:pallet_sequence][:pick_reference].to_s[0,1]).to_i
        #  if(iso_week < 0 || iso_week > 52)
        #    @pallet_sequence.errors.add(:pick_reference,"is invalid : you entered a pick ref iso week #{iso_week}")
        #    render_pallet_sequence_form
        #    return
        #  end
        #end

         @mapped_pallet_sequence = MappedPalletSequence.find_by_pallet_sequence_id(@pallet_sequence.id)
        if @pallet_sequence.update_attributes(params[:pallet_sequence])#@pallet_sequence.update
          @mapped_pallet_sequence.update_attributes(params[:pallet_sequence]) if(@mapped_pallet_sequence)
          session[:alert] = 'pallet sequence record updated successfully'
          #pallet_sequences
          render :inline => %{
                <script>
                  window.opener.frames[1].location.href = 'active_intake_header';
                  window.location.href = 'pallet_sequences';
                </script>
              },:layout=>'content'
         else
           #session[:pallet_seq_id] = id
           render_pallet_sequence_form
         end
      end
    rescue
       handle_error("pallet sequence record could not be updated")
    end
  end

  def print_pallet_labels
    id = params[:id];
    render :inline => %{
      <% @url_base = "http://" + request.host_with_port + "/" + "fg/depot_receipts/render_print_pallet_labels/#{id}" %>
      <script>
        window.open("<%=@url_base%>", "pallet_seq","width=850,height=400,top=200,left=200,toolbar=1,menubar=1,status=1,scrollbars=1,resizable=1" );
        window.back();
      </script>
    }
  end

  def render_print_pallet_labels
    id = params[:id]
    session[:mapped_pallet_sequence_id] = id
    render :inline=>%{
       <% @content_header_caption = "'enter amount of labels to print'"%>

       <%= build_enter_amount_of_pallet_labels_to_print_form(@pallet_label_amount,'submit_amount_to_print','submit')%>
    }, :layout=>'content'
  end

  def submit_amount_to_print
    #puts "PALLET AMOUNT : " + params["pallet_amount"]["pallet_label_amount"].to_s
    amount = params["pallet_amount"]["pallet_label_amount"].to_s
    if amount.strip != ""
      if !amount.is_numeric?
        render :inline=>%{
           <% @content_header_caption = "'enter amount of labels to print'"%>

           <%= build_enter_amount_of_pallet_labels_to_print_form(@pallet_label_amount,'submit_amount_to_print','submit')%>
        }, :layout=>'content'
      else
        cartons = Carton.find_by_sql("SELECT * FROM cartons WHERE mapped_pallet_sequence_id ='#{session[:mapped_pallet_sequence_id]}'")
        if cartons.length == 0
          redirect_to_index("Carton labels could not be printed, There are no cartons for the mapped_pallet_sequence!")
        else
          if amount.to_i > cartons.length
            redirect_to_index("Carton labels could not be printed, The amount of labels to be printed is greater than available cartons!")
          else
            # PRINTING
            
          end
        end
        render :inline=>%{
           correct amount!
        }, :layout=>'content'
      end
    else
      render :inline=>%{
         <% @content_header_caption = "'enter amount of labels to print'"%>

         <%= build_enter_amount_of_pallet_labels_to_print_form(@pallet_label_amount,'submit_amount_to_print','submit')%>
      }, :layout=>'content'
    end
  end

  def view_pallet_sequence
    @id = params[:id];
    render :inline => %{
      <% @url_base = "http://" + request.host_with_port + "/" + "fg/depot_receipts/render_view_pallet_sequence/#{@id}" %>
      <script>
        window.open("<%=@url_base%>", "pallet_seq","width=850,height=400,top=200,left=200,toolbar=1,menubar=1,status=1,scrollbars=1,resizable=1" );
        window.back();
      </script>
    }
  end

  def render_view_pallet_sequence
    id = params[:id];
    @pallet_sequence = PalletSequence.find(id)
    render :inline=>%{
       <% @content_header_caption = "'view pallet sequence'"%>

       <%= build_view_pallet_sequence_form(@pallet_sequence,'close_view_pallet_sequence_form','close')%>
    }, :layout=>'content'
  end

  def close_view_pallet_sequence_form
    render :inline=>%{
        <script>
          window.close();
        </script>
    }
  end


  def map_by_fruitspec
    intake_header = session[:intake_header]
    query ="SELECT DISTINCT pallet_sequences.commodity, pallet_sequences.variety, pallet_sequences.grade, pallet_sequences.organization, pallet_sequences.count,
                   pallet_sequences.class_code,pallet_sequences.brand, pallet_sequences.pack_type,(select extended_fg_code from mapped_pallet_sequences where pallet_sequences.id = mapped_pallet_sequences.pallet_sequence_id)
                   as extended_fg_code,(select mapped_date_time from mapped_pallet_sequences where pallet_sequences.id = mapped_pallet_sequences.pallet_sequence_id)
                   as mapped_date_time FROM
                   pallet_sequences
                    WHERE pallet_sequences.intake_header_id = #{intake_header.id}"

    @mapped_pallet_sequences = MappedPalletSequence.connection.select_all(query)
    render :inline => %{
      <% grid            = build_mapped_pallet_sequences_grid(@mapped_pallet_sequences) %>
      <% grid.caption    = 'list of unique friutspecs for intake header: #{intake_header.id}' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@mapped_pallet_sequences_pages) if @mapped_pallet_sequences_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    
  end


  def map_pallet_sequences
    id = params[:id].to_s
    ids_array = id.split("!")
    commodity = ids_array[0]
    variety = ids_array[1]
    grade = ids_array[2]
    count = ids_array[3]
    brand = ids_array[4]
    pack_type = ids_array[5]
    organization = ids_array[6]
    mapped = ids_array[7]
    class_code = ids_array[8]
    @mapped_pallet_sequence = MappedPalletSequence.get_record_by_fruitspecs(commodity, variety, grade, count, brand, pack_type, organization,class_code,session[:intake_header].id)
#    if !@mapped_pallet_sequence
#      @mapped_pallet_sequence = MappedPalletSequence.new
#      @mapped_pallet_sequence.commodity = commodity
#      @mapped_pallet_sequence.variety = variety
#      @mapped_pallet_sequence.grade = grade
#      @mapped_pallet_sequence.count = count
#      @mapped_pallet_sequence.brand = brand
#      @mapped_pallet_sequence.pack_type = pack_type
#      @mapped_pallet_sequence.organization = organization
#    end
#    @mapped_pallet_sequence.mapped = mapped
#    @mapped_pallet_sequence.intake_header_number = session[:intake_header].intake_header_number
#
#    session[:mapped_pallet_sequence] = @mapped_pallet_sequence
    if !@mapped_pallet_sequence
      @mapped_pallet_sequence = MappedPalletSequence.new
      @mapped_pallet_sequence.commodity = commodity
      @mapped_pallet_sequence.variety = variety
      @mapped_pallet_sequence.grade = grade
      @mapped_pallet_sequence.count = count
      @mapped_pallet_sequence.brand = brand
      @mapped_pallet_sequence.pack_type = pack_type
      @mapped_pallet_sequence.organization = organization
      @mapped_pallet_sequence.class_code = class_code
      @mapped_pallet_sequence.mapped = mapped
    end

    session[:ids_array] = ids_array
    session[:mapped_pallet_sequence] = @mapped_pallet_sequence
    
    render_mapped_pallet_sequence_form
  end

  def render_mapped_pallet_sequence_form
    intake_header = session[:intake_header]
    render :inline => %{
		<% @content_header_caption = "'bulk map sequences for intake header: #{intake_header.id}'"%>

		<%= build_mapped_pallet_sequences_form(@mapped_pallet_sequence,'save_mapped_pallet_sequence','save',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def save_mapped_pallet_sequence
    begin


      if params[:mapped_pallet_sequence][:extended_fg_code]== ""||params[:mapped_pallet_sequence][:extended_fg_code]== nil
          flash[:error] = "You must select an extended fg"
          session[:mapped_pallet_sequence].update_attributes_state(params[:mapped_pallet_sequence])
          @mapped_pallet_sequence = session[:mapped_pallet_sequence]
          render_mapped_pallet_sequence_form
        return
      end

       ids_array = session[:ids_array]
       commodity = ids_array[0]
       variety = ids_array[1]
       grade = ids_array[2]
       count = ids_array[3]
       brand = ids_array[4]
       pack_type = ids_array[5]
       organization = ids_array[6]
       mapped = ids_array[7]
      class_code = ids_array[8]

       pallet_seq_query = "SELECT * FROM pallet_sequences WHERE commodity='#{commodity}' AND variety='#{variety}'"
       pallet_seq_query += " AND grade='#{grade}' AND count='#{count}' AND brand='#{brand}' AND pack_type='#{pack_type}' AND class_code='#{class_code}' AND intake_header_id='#{session[:intake_header].id}'"
       pallet_sequences = PalletSequence.find_by_sql(pallet_seq_query)

      ActiveRecord::Base.transaction do
       if pallet_sequences.length != 0
         no_error = 0
         @mapped_pallet_sequence = nil
         pallet_sequences.each do |pallet_seq|
             @mapped_pallet_sequence = MappedPalletSequence.find_by_pallet_sequence_id(pallet_seq.id)
             if @mapped_pallet_sequence
               @mapped_pallet_sequence.commodity = commodity
               @mapped_pallet_sequence.variety = variety
               @mapped_pallet_sequence.grade = grade
               @mapped_pallet_sequence.count = count
               @mapped_pallet_sequence.class_code = class_code
               @mapped_pallet_sequence.brand = brand
               @mapped_pallet_sequence.pack_type = pack_type
               @mapped_pallet_sequence.organization = organization
               @mapped_pallet_sequence.depot_pallet_number = pallet_seq.depot_pallet_number
               @mapped_pallet_sequence.depot_pallet_id = pallet_seq.depot_pallet_id
               @mapped_pallet_sequence.extended_fg_code = params[:mapped_pallet_sequence][:extended_fg_code]
               @mapped_pallet_sequence.fg_code_old = commodity.to_s + " " + variety.to_s + " " + brand.to_s + " " + pack_type.to_s + " " + count.to_s
               @mapped_pallet_sequence.intake_header_id = session[:intake_header].id
               @mapped_pallet_sequence.depot_pallet_id = pallet_seq.depot_pallet_id
               @mapped_pallet_sequence.depot_pallet_number = pallet_seq.depot_pallet_number
               @mapped_pallet_sequence.pallet_sequence_number = pallet_seq.pallet_sequence_number
               @mapped_pallet_sequence.mapped_date_time = Time.now.to_formatted_s(:db)
               @mapped_pallet_sequence.captured_date_time = pallet_seq.captured_date_time
               @mapped_pallet_sequence.target_market = pallet_seq.target_market
               @mapped_pallet_sequence.inventory_code = pallet_seq.inventory_code
               @mapped_pallet_sequence.puc = pallet_seq.puc
               @mapped_pallet_sequence.sell_by_date = pallet_seq.sell_by_date
               @mapped_pallet_sequence.product_characteristics = pallet_seq.product_characteristics
               @mapped_pallet_sequence.pallet_sequence_number = pallet_seq.pallet_sequence_number
               @mapped_pallet_sequence.remarks = pallet_seq.remarks
               @mapped_pallet_sequence.seq_ctn_qty = pallet_seq.seq_ctn_qty
               @mapped_pallet_sequence.pallet_sequence_id = pallet_seq.id
               @mapped_pallet_sequence.pick_reference = pallet_seq.pick_reference
               @mapped_pallet_sequence.pack_date_time =  pallet_seq.pack_date_time
               if @mapped_pallet_sequence.update
                 depot_pallet = DepotPallet.find(pallet_seq.depot_pallet_id)
                 depot_pallet.set_pallet_format_product  if !depot_pallet.pallet_format_product_code
                 #redirect_to_index("mapped_pallet_sequence record saved successifully!")
                 #break
               else
                 no_error = 1
                 break
               end
             else
               @mapped_pallet_sequence = MappedPalletSequence.new(params[:mapped_pallet_sequence])
               @mapped_pallet_sequence.mapped = mapped
               @mapped_pallet_sequence.commodity = commodity
               @mapped_pallet_sequence.variety = variety
               @mapped_pallet_sequence.grade = grade
               @mapped_pallet_sequence.count = count
               @mapped_pallet_sequence.brand = brand
               @mapped_pallet_sequence.pack_type = pack_type
               @mapped_pallet_sequence.class_code = class_code
               @mapped_pallet_sequence.organization = organization
               @mapped_pallet_sequence.depot_pallet_number = pallet_seq.depot_pallet_number
               @mapped_pallet_sequence.depot_pallet_id = pallet_seq.depot_pallet_id
               @mapped_pallet_sequence.fg_code_old = commodity.to_s + " " + variety.to_s + " " + brand.to_s + " " + pack_type.to_s + " " + count.to_s
               @mapped_pallet_sequence.intake_header_id = session[:intake_header].id
               @mapped_pallet_sequence.pallet_sequence_number = pallet_seq.pallet_sequence_number
               @mapped_pallet_sequence.mapped_date_time = Time.now.to_formatted_s(:db)
               @mapped_pallet_sequence.captured_date_time = pallet_seq.captured_date_time
               @mapped_pallet_sequence.target_market = pallet_seq.target_market
               @mapped_pallet_sequence.inventory_code = pallet_seq.inventory_code
               @mapped_pallet_sequence.puc = pallet_seq.puc
               @mapped_pallet_sequence.pallet_sequence_number = pallet_seq.pallet_sequence_number
               @mapped_pallet_sequence.remarks = pallet_seq.remarks
               @mapped_pallet_sequence.seq_ctn_qty = pallet_seq.seq_ctn_qty
               @mapped_pallet_sequence.sell_by_date = pallet_seq.sell_by_date
               @mapped_pallet_sequence.product_characteristics = pallet_seq.product_characteristics
               @mapped_pallet_sequence.pallet_sequence_id = pallet_seq.id
               @mapped_pallet_sequence.pack_date_time =  pallet_seq.pack_date_time
               @mapped_pallet_sequence.pick_reference = pallet_seq.pick_reference
               if @mapped_pallet_sequence.save
                 depot_pallet = DepotPallet.find(pallet_seq.depot_pallet_id)
                 depot_pallet.set_pallet_format_product  if !depot_pallet.pallet_format_product_code
                 #redirect_to_index("mapped_pallet_sequence record saved successifully!")
                 #break
               else
                 no_error = 1
                 break
                 #render_mapped_pallet_sequence_form
               end
             end
             pallet_seq.mapped_date_time = Time.now.to_formatted_s(:db)
             pallet_seq.update
         end
         #redirect_to_index("mapped_pallet_sequence record(s) saved successifully!")


         session[:intake_header].rmt_creatable?      #will raise exception if rmt cannot be created- which will roll back the mapping

         if no_error == 1
           render_mapped_pallet_sequence_form
         else

          session[:intake_header].update
          session[:alert] = "mapped_pallet_sequence record(s) saved successifully!"
           map_by_fruitspec
         end
       else
         raise "No pallet sequences found to match with the fruitspec"
       end



      end


         #redirect_to_index("mapped pallet sequence updated successifully!")
    rescue
       #handle_error("mapped_pallet_sequence record could not be saved")
      raise MesScada::InfoError, "mapped_pallet_sequence record could not be saved" + $!.to_s
    end
  end

  def active_intake_header
       if !session[:intake_header]
         redirect_to_index("You do not have an active header")
       else
        session[:intake_header].reload
        @intake_header =  session[:intake_header]
        render_edit_intake_header
       end

  end

  def show_intake_header_pallets
    id = params[:id].to_s
    ids_array = id.split("!")
    commodity = ids_array[0]
    variety = ids_array[1]
    grade = ids_array[2]
    count = ids_array[3]
    brand = ids_array[4]
    pack_type = ids_array[5]
    #organization = ids_array[6]
    intake_header = session[:intake_header]
    depot_pallets_query = "SELECT DISTINCT depot_pallets.depot_pallet_number, depot_pallets.carton_quantity FROM (depot_pallets JOIN pallet_sequences ON("
    depot_pallets_query += "depot_pallets.id=pallet_sequences.depot_pallet_id)) WHERE depot_pallets.intake_header_id='#{intake_header.id}' AND pallet_sequences.commodity='#{commodity}' AND pallet_sequences.variety='#{variety}'"
    depot_pallets_query += " AND pallet_sequences.grade='#{grade}' AND pallet_sequences.count='#{count}' AND pallet_sequences.brand='#{brand}' AND pallet_sequences.pack_type='#{pack_type}'"
    @depot_pallets = ActiveRecord::Base.connection.select_all(depot_pallets_query)
    render :inline => %{
      <% grid            = build_intake_header_pallets_grid(@depot_pallets) %>
      <% grid.caption    = 'list of depot pallets for intake header : #{intake_header.id}' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@depot_pallets_pages) if @depot_pallets_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end


  def intake_header_recool_required_checked
    recool_required = get_selected_combo_value(params)
    session[:intake_header_form][:recool_required] = recool_required
    required = recool_required.class.to_s == "String" && recool_required === "1"
    if required
      render :inline=>%{
        <% @recool_temperature = text_field('intake_header', 'recool_temperature') %>
        <% @recool_average_temperature = text_field('intake_header', 'recool_average_temperature') %>
        <script>
          <%= update_element_function(
            "recool_temperature_cell", :action=>:update, :content=>@recool_temperature
          ) %>
          <%= update_element_function(
            "recool_average_temperature_cell", :action=>:update, :content=>@recool_average_temperature
          ) %>
        </script>
      }
    else
      render :inline=>%{
        <% @recool_temperature = "NO RECOOL TEMP REQUIRED!" %>
        <% @recool_average_temperature = "NO RECOOL AVG TEMP REQUIRED!" %>
        <script>
          <%= update_element_function(
            "recool_temperature_cell", :action=>:update, :content=>@recool_temperature
          ) %>
          <%= update_element_function(
            "recool_average_temperature_cell", :action=>:update, :content=>@recool_average_temperature
          ) %>
        </script>
      }
    end
  end


  def print_header_document
    id = params[:id]
    intake_header = IntakeHeader.find(id)      #param: intake_header_number
    http_conn = Net::HTTP.new(Globals.get_crystal_reports_server_ip, Globals.get_crystal_reports_server_port)
    @printer = "PrimoPDF"
    report_parameters = "intake_header_number=#{intake_header.intake_header_number.to_s}&reference_type=intake_headers&reference_id=#{id}&report_type=depot_receipt&printer_name=" + @printer.to_s + "&report_user_ref=" + intake_header.id.to_s
    response = http_conn.request_get(Globals.get_crystal_reports_server + report_parameters)
    puts "Body : " + response.body.to_s
    puts "Response : " + response.to_s
    if response.body.to_s.strip == ""
      redirect_to_index("report printed successifully!")
    else
      error_msg = response.body.to_s.gsub("<error>", "").gsub("</error>","").gsub("<![CDATA[","").gsub("]]>","")
      raise error_msg
    end
  end


  def create_edi_flow
    header = IntakeHeader.find(params[:id].to_i)
    header.send_edi
    flash[:notice] = "edi proposal sent"
    active_intake_header

  end


  def show_missing_non_fruitspec
    missing_mf_hash = IntakeHeader.get_missing_master_files(session[:intake_header].id, true)
    @pallet_sequence = PalletSequence.new
    @pallet_sequence.consignment_note_number = session[:intake_header].consignment_note_number
    @pallet_sequence.intake_header_number = session[:intake_header].intake_header_number
    @pallet_sequence.pucs = missing_mf_hash["pucs"]
    @pallet_sequence.target_markets = missing_mf_hash["target_markets"]
    @pallet_sequence.inventory_codes = missing_mf_hash["inventory_codes"]
    @pallet_sequence.pallet_nums = missing_mf_hash["pallet_nums"]
    @pallet_sequence.no_location = missing_mf_hash['no_location']


    render :inline => %{
		<% @content_header_caption = "'missing non-fruitspec master file entries for intake header: #{session[:intake_header].id}'"%>

		<%= build_missing_master_files_form(@pallet_sequence,'back_to_main_form','back',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def back_to_main_form
    puts "BACK PUSHED .. "
    render :inline=>%{
      <script>
        window.close();
      </script>
    }, :layout=>'content'
  end



  def intake_header_consignment_note_number_combo_changed
    consignment_note_number = get_selected_combo_value(params)
    session[:intake_header_search_form][:consignment_note_number_selection] = consignment_note_number
    @intake_header_numbers = IntakeHeader.find_by_sql("SELECT DISTINCT intake_header_number FROM intake_headers WHERE consignment_note_number='#{consignment_note_number}'").map{|g|[g.intake_header_number]}
    @intake_header_numbers.unshift("<empty>")
    render :inline=>%{
        <%=select('intake_header','intake_header_number',@intake_header_numbers) %>
        <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_intake_header_intake_header_number'/>
        <%= observe_field('intake_header_intake_header_number', :update=>'depot_code_cell', :url => {:action=>session[:intake_header_search_form][:intake_header_number_observer][:remote_method]}, :loading=>"show_element('img_intake_header_intake_header_number');", :complete=>session[:intake_header_search_form][:intake_header_number_observer][:on_completed_js])%>
    }
  end

  def intake_header_intake_header_number_combo_changed
    intake_header_number = get_selected_combo_value(params)
    session[:intake_header_search_form][:intake_header_number_selection] = intake_header_number
    consignment_note_number = session[:intake_header_search_form][:consignment_note_number_selection]
    @depot_codes = IntakeHeader.find_by_sql("SELECT DISTINCT depot_code FROM intake_headers WHERE consignment_note_number='#{consignment_note_number}' AND intake_header_number='#{intake_header_number}'").map{|g|[g.depot_code]}
    @depot_codes.unshift("<empty>")
    render :inline=>%{
        <%=select('intake_header','depot_code',@depot_codes) %>
        <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_intake_header_depot_code'/>
        <%= observe_field('intake_header_depot_code', :update=>'puc_code_cell', :url => {:action=>session[:intake_header_search_form][:depot_code_observer][:remote_method]}, :loading=>"show_element('img_intake_header_depot_code');", :complete=>session[:intake_header_search_form][:depot_code_observer][:on_completed_js])%>
    }
  end

  def intake_header_depot_code_combo_changed
    depot_code = get_selected_combo_value(params)
    intake_header_number = session[:intake_header_search_form][:intake_header_number_selection]
    consignment_note_number = session[:intake_header_search_form][:consignment_note_number_selection]
    @pucs = IntakeHeader.find_by_sql("SELECT DISTINCT puc_code FROM intake_headers WHERE consignment_note_number='#{consignment_note_number}' AND intake_header_number='#{intake_header_number}' AND depot_code='#{depot_code}'").map{|g|[g.puc_code]}
    @pucs.unshift("<empty>")
    render :inline=>%{
        <%=select('intake_header','puc_code',@pucs) %>
    }
  end


  def mapped_pallet_sequence_mark_code_combo_changed
    mark_code = get_selected_combo_value(params)
    item_pack_product_code = session[:mapped_pallet_sequence_form][:ipc_selected]
    item_pack_product_code = "empty" if ! item_pack_product_code
    session[:mapped_pallet_sequence_form][:mark_code_selection] = mark_code
    fg_code_old = session[:mapped_pallet_sequence].commodity.to_s + " " + session[:mapped_pallet_sequence].variety.to_s + " " + session[:mapped_pallet_sequence].brand.to_s + " " + session[:mapped_pallet_sequence].pack_type.to_s + " " + session[:mapped_pallet_sequence].count.to_s
    organization = session[:mapped_pallet_sequence].organization.to_s
    @extended_fg_codes = ExtendedFg.get_extended_fg_codes(fg_code_old, item_pack_product_code, organization, mark_code)
    render :inline=>%{
        <%=select('mapped_pallet_sequence','extended_fg_code',@extended_fg_codes) %>
    }
  end

  def mapped_pallet_sequence_item_pack_product_code_combo_changed
    item_pack_product_code = get_selected_combo_value(params)
    session[:mapped_pallet_sequence_form][:ipc_selected] = item_pack_product_code
    carton_mark_code = session[:mapped_pallet_sequence_form][:mark_code_selection].to_s
    fg_code_old = session[:mapped_pallet_sequence].commodity.to_s + " " + session[:mapped_pallet_sequence].variety.to_s + " " + session[:mapped_pallet_sequence].brand.to_s + " " + session[:mapped_pallet_sequence].pack_type.to_s + " " + session[:mapped_pallet_sequence].count.to_s
    organization = session[:mapped_pallet_sequence].organization.to_s
    @extended_fg_codes = ExtendedFg.get_extended_fg_codes(fg_code_old, item_pack_product_code, organization, carton_mark_code)
    render :inline=>%{
        <%=select('mapped_pallet_sequence','extended_fg_code',@extended_fg_codes) %>
    }
  end

  def recent_depot_intakes
    @intake_headers = IntakeHeader.find(:all,:order=>"updated_on DESC limit 100")
    @can_edit = authorise(program_name?,'edit',session[:user_id])
  	@can_delete = authorise(program_name?,'delete',session[:user_id])
    list_intake_headers
  end
end
