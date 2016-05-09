class Production::ReworksController < ApplicationController

  class RwRepackInfo
    attr_accessor :override_reason, :overridden_amounts, :total_cartons, :target_pallet, :new_total
  end

  def program_name?
    "reworks"
  end


  def scrap_bin
    if !params[:item]
      session[:bin_to_scrap] = RwActiveBin.find(params[:id].to_i)

      @content_header_caption = "'Please provide a reason for scrapping bin: " + session[:bin_to_scrap].bin_number.to_s + "'"
      render :inline =>
                 %{

		<%= build_scrap_reason_form('scrap_bin')%>

      }, :layout => 'content'
      return

    else

      reason = RwReason.find_by_rw_reason_description(params[:item][:reason])

      bin = session[:bin_to_scrap]

      RwActiveBin.scrap([bin],reason,session[:user_id])

      flash[:notice] = "Bin: " + bin.bin_number.to_s + " scrapped."
      session[:bin_to_scrap] = nil
      rw_bins

    end
  end

  def submit_scrap_bins
    reason = RwReason.find_by_rw_reason_description(params[:item][:reason])

      bins = session[:bins_to_scrap]

      RwActiveBin.scrap(bins,reason,session[:user_id])

      flash[:notice] = "Bins scrapped."
      session[:bin_to_scrap] = nil
      rw_bins
  end


  def weigh_bin
    @rw_bin = RwActiveBin.find(params[:id])

    @content_header_caption = "'Override bin weight'"
      render :inline =>
                 %{

		<%= build_weigh_bin_form(@rw_bin)%>

      }, :layout => 'content'
      return


  end


  def weigh_bin_submit
    @rw_bin = RwActiveBin.find(params[:rw_bin][:id])

    new_weight = params[:rw_bin][:weight].to_f

    if new_weight > 0
      @rw_bin.weight = new_weight
      @rw_bin.reworks_action = "WEIGHT_CHANGED"
      @rw_bin.weight_changed = true
      @rw_bin.save!
      flash[:notice] = "New weight saved(#{new_weight})"
      rw_bins
    else
      flash[:error] = "You did not specify a value for weight"
      @params[:id] = @rw_bin.id
      weigh_bin
    end


  end

  def receive_scrap_bins
     bins    = session[:current_bin_list]
     selected_bins = selected_records?(bins, nil,nil)
     session[:bins_to_scrap]=selected_bins
    if !params[:item]


      @content_header_caption = "'Please provide a reason for scrapping bins' "
      render :inline =>
                 %{

		<%= build_scrap_reason_form('submit_scrap_bins')%>

      }, :layout => 'content'
      return

    end
    end



  def bulk_scrap_bins_grid
    @can_control_run = authorise(program_name?, 'rw_physical', session[:user_id])
        @bulk_bin_update_permission = authorise(program_name?, 'rw_bulk_bin_edit', session[:user_id])

        if !session[:current_rw_run]
          @freeze_flash = true
          redirect_to_index("You have not yet created or selected an active(editing) reworks run")
          return
        end

        #@active_bins = RwActiveBin.find_all_by_rw_run_id(session[:current_rw_run].id)
        @active_bins = RwActiveBin.find_by_sql("select transaction_statuses.status_code,
                        ripe_points.cold_store_type_code,locations.location_code as sealed_ca_location_code,stock_items.location_code,stock_items.stock_type_code,
                        rmt_products.product_class_code,rmt_products.ripe_point_code,rmt_products.size_code,
                        rw_active_bins.*,pack_material_products.pack_material_product_code,rmt_products.rmt_product_code,farms.farm_code,
                        rw_active_bins.rebin_track_indicator_code,rw_active_bins.season_code,
                        track_slms1.track_slms_indicator_code as indicator_code1,
                        track_slms2.track_slms_indicator_code as indicator_code2,
                        track_slms3.track_slms_indicator_code as indicator_code3,
                        track_slms4.track_slms_indicator_code as indicator_code4,
                        track_slms5.track_slms_indicator_code as indicator_code5,
                        rw_active_bins.bin_receive_date_time,
                        rw_active_bins.bin_id,rw_active_bins.exit_ref,deliveries.delivery_number,rw_active_bins.tipped_date_time, rw_active_bins.bin_number,
                        rw_active_bins.is_half_bin,rw_active_bins.is_sample_bin,
                        rw_active_bins.rebin_status,rw_active_bins.rebin_date_time,rw_active_bins.user_name,rw_active_bins.print_number,
                        rw_active_bins.exit_reference_date_time,
                        rw_active_bins.rw_run_id ,
                        production_rebin_runs.production_run_code as production_run_rebin,
                        production_tipped_runs.production_run_code as production_run_tipped
                        from
                        rw_active_bins
                        LEFT  JOIN track_slms_indicators track_slms1 ON rw_active_bins.track_indicator1_id = track_slms1.id
                        LEFT  JOIN track_slms_indicators track_slms2 ON rw_active_bins.track_indicator2_id = track_slms2.id
                        LEFT  JOIN track_slms_indicators track_slms3 ON rw_active_bins.track_indicator3_id = track_slms3.id
                        LEFT  JOIN track_slms_indicators track_slms4 ON rw_active_bins.track_indicator4_id = track_slms4.id
                        LEFT  JOIN track_slms_indicators track_slms5 ON rw_active_bins.track_indicator5_id = track_slms5.id
                        LEFT  JOIN deliveries ON rw_active_bins.delivery_id = deliveries.id
                        LEFT  JOIN  rmt_products ON rw_active_bins.rmt_product_id = rmt_products.id
                        LEFT  JOIN farms ON rw_active_bins.farm_id = farms.id
                        LEFT  JOIN pack_material_products ON rw_active_bins.pack_material_product_id = pack_material_products.id
                        LEFT  JOIN production_runs production_rebin_runs ON rw_active_bins.production_run_rebin_id = production_rebin_runs.id
                        LEFT  JOIN production_runs production_tipped_runs ON rw_active_bins.production_run_tipped_id = production_tipped_runs.id
                        LEFT JOIN stock_items ON rw_active_bins.bin_number=stock_items.inventory_reference
                        LEFT JOIN locations ON rw_active_bins.sealed_ca_location_id=locations.id
                        LEFT JOIN ripe_points ON  rmt_products.ripe_point_id=ripe_points.id
                        LEFT JOIN transaction_statuses ON rw_active_bins.bin_id=transaction_statuses.object_id
                        WHERE
                        rw_active_bins.rw_run_id =#{session[:current_rw_run].id}")

        session[:current_bin_list] = @active_bins

        if @active_bins.length == 0
          @freeze_flash = true
          redirect_to_index("No bins were received yet")
          return
        end

    render :inline => %{
      <% grid            = build_rw_bins_grid(@active_bins,nil,"scrap_bins") %>
      <% grid.caption    = 'bins in reworks' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end



  def tip_bins

    bin_id = params[:id]
    @bin = RwActiveBin.find(bin_id)
    if  @bin.reworks_action && (@bin.reworks_action.upcase == "TIPPED"|| @bin.reworks_action.upcase == "BULK_TIPPED")
      flash[:error] = "Bin: " +"  " + "#{@bin.bin_number}" + "ALREADY TIPPED"
      render :inline => %{<script>
                             window.close();
                          window.opener.frames[1].location.href = '/production/reworks/rw_bins';
                            </script>} and return
    end
    render :inline => %{
              <% @content_header_caption = "'tip_bin'"%>
             <%= build_tip_bin_form(@bin,'tip_bins_submit','tip',false,@is_create_retry)%>

             }, :layout => 'content'

  end

  def bulk_tip_bins
    bin_id = params[:id]
    @bin = RwActiveBin.find(bin_id)
    if  @bin.reworks_action && (@bin.reworks_action.upcase == "TIPPED"|| @bin.reworks_action.upcase == "BULK_TIPPED")
      flash[:error] = "Bin: " +"  " + "#{@bin.bin_number}" + "ALREADY TIPPED"
      render :inline => %{<script>
                             window.close();
                          window.opener.frames[1].location.href = '/production/reworks/rw_bins';
                            </script>} and return
    end
    render :inline => %{
              <% @content_header_caption = "'tip_bin'"%>
             <%= build_tip_bin_form(@bin,'bulk_tip_bins_submit','tip',false,@is_create_retry)%>

             }, :layout => 'content'
  end

  def tip_bins_submit

    bin_id =params[:bin][:bin_id]
    @bin = RwActiveBin.find_by_bin_id(bin_id)
    production_run_tipped_id =params[:bin][:production_run_tipped_id].to_i
    production_run = ProductionRun.find( production_run_tipped_id)
    reworks_action ="TIPPED"
    tipped_date_time =Time.now
    exit_reference_date_time =Time.now
    user_name = session[:user_id].user_name
    bins=Bin.find_by_sql("select * from bins where production_run_tipped_id=#{production_run_tipped_id} and shift_id IS NOT NULL order by id desc")
    shift_id=nil
    if !bins.empty?
      oldest_bin=bins[0]
      shift_id=oldest_bin.shift_id
    end

    begin
      ActiveRecord::Base.transaction do

        if shift_id
          @bin.production_run_tipped_id = production_run_tipped_id
          @bin.user_name = user_name
          @bin.shift_id = shift_id
          @bin.tipped_date_time = tipped_date_time
          @bin.reworks_action = reworks_action
          @bin.exit_reference_date_time =exit_reference_date_time
          RAILS_DEFAULT_LOGGER.info("SHIFT ID(#{shift_id}) LOGGED FOR :  #{production_run.production_run_code}")
          if @bin.update
          else
            session[:alert]="#{$!}"
            return $!
          end

        else
          @bin.production_run_tipped_id = production_run_tipped_id
          @bin.user_name = user_name
          @bin.tipped_date_time = tipped_date_time
          @bin.reworks_action = reworks_action
          @bin.exit_reference_date_time =exit_reference_date_time
          RAILS_DEFAULT_LOGGER.info("SHIFT ID NOT FOUND(no bins) FOR:  #{production_run.production_run_code}")
          if @bin.update
          else
            session[:alert]="#{$!}"
                      return $!
                    end

        end

      end
    rescue
              session[:alert]="#{$!}"
                  return $!

    end
      render :inline => %{<script>

                             alert('bin #{@bin.bin_number} was tipped successfully');
                              window.opener.frames[1].location.href = '/production/reworks/rw_bins';
                             window.close();
                            </script>}


  end

  def bulk_tip_bins_confirmed
    bin_id =session[:bin_id]
    @bin = RwActiveBin.find_by_bin_id(bin_id)
    #production_run_code = params[:bin][:production_run_tipped_id]
    production_run_tipped_id = session[:production_run_tipped_id]
    production_run = ProductionRun.find( production_run_tipped_id)
    reworks_action ="BULK_TIPPED"
    tipped_date_time =Time.now.to_formatted_s(:db)
    exit_reference_date_time =Time.now.to_formatted_s(:db)
    user_name = session[:user_id].user_name
    bins=Bin.find_by_sql("select * from bins where production_run_tipped_id=#{production_run_tipped_id} and shift_id is NOT NULL order by id desc")
    shift_id=nil
    if !bins.empty?
      oldest_bin=bins[0]
      shift_id=oldest_bin.shift_id
    end
    begin
      ActiveRecord::Base.transaction do
        bin_numbers=session[:current_bin_list].map { |l| "'#{l.bin_number}'" }
        bin_numbers=bin_numbers.join(",")


        if shift_id
          ActiveRecord::Base.connection.execute("update rw_active_bins set production_run_tipped_id=#{production_run_tipped_id},user_name ='#{user_name}',
             shift_id=#{shift_id},tipped_date_time= '#{tipped_date_time}',reworks_action ='#{reworks_action}',exit_reference_date_time='#{exit_reference_date_time}' where bin_number in (#{ bin_numbers})")
          RAILS_DEFAULT_LOGGER.info("SHIFT ID(#{shift_id}) LOGGED FOR THE RUN:  #{production_run.production_run_code}")
        else
          ActiveRecord::Base.connection.execute("update rw_active_bins set production_run_tipped_id=#{production_run_tipped_id},user_name ='#{user_name}',
                   tipped_date_time= '#{tipped_date_time}',reworks_action ='#{reworks_action}',exit_reference_date_time='#{exit_reference_date_time}' where bin_number in (#{ bin_numbers}) ")
          RAILS_DEFAULT_LOGGER.info("SHIFT ID NOT LOGGED:(no bins) for #{production_run.production_run_code}  ")
        end




      render :inline => %{<script>
                                 alert('bins successfully tipped ');
                                  window.opener.frames[1].location.href = '/production/reworks/rw_bins';
                                 window.close();

                                </script>}

    end
    rescue
      raise $!
    #flash[:error] = "bins where not tipped successfully"
    rw_bins
  end
  end

  def bulk_tip_bins_canceled
    session[:current_editing_bin] = nil
    flash[:error]= "Bulk tip bin cancelled"
    render :inline => %{
                          <script>
                           window.close();

                          </script>
                            }, :layout => 'content'
  end



  def bulk_tip_bins_submit
    session[:bin_id]=params[:bin][:bin_id]
    session[:production_run_tipped_id] =params[:bin][:production_run_tipped_id].to_i
    @msg = "Are you sure you want to submit the bulk update?  " + session[:current_bin_list].length().to_s + " bins in the workspace(current run) will be tipped "


    render :inline => %{
   <script>
     if (confirm("<%=@msg%>") == true)
        {window.location.href = "/production/reworks/bulk_tip_bins_confirmed";}
     else
       {window.location.href = "/production/reworks/bulk_tip_bins_canceled";}
  </script>
    }
  end

  def rmt_product_code_changed

    rmt_product_code = get_selected_combo_value(params)
    session[:bulk_edit_bins_form][:rmt_product_combo_selection] = rmt_product_code

    if rmt_product_code== ""
      render :inline => %{ Not used }
    else

      commodity_code_variety_code = RmtProduct.find_by_sql("select commodity_code,variety_code from rmt_products where id ='#{rmt_product_code.to_s}' ")
      commodity_code=commodity_code_variety_code[0]['commodity_code'].to_s
      variety_code=commodity_code_variety_code[0]['variety_code']


      @track_indicator1_id = TrackSlmsIndicator.find_by_sql("SELECT DISTINCT id,track_slms_indicator_code from track_slms_indicators where commodity_code = '#{commodity_code.to_s}' AND rmt_variety_code ='#{variety_code.to_s}'").map { |t| [t.track_slms_indicator_code, t.id] }
      @bin=session[:current_editing_bin]
      current_track_slms_indicator=TrackSlmsIndicator.find_by_sql("select  id,track_slms_indicator_code from track_slms_indicators where id =#{@bin.track_indicator1_id}").map { |t| [t.track_slms_indicator_code,t.id] }[0]
      @track_indicator1_id << current_track_slms_indicator
      render :inline => %{
          <%= select('bin','track_indicator1_id',@track_indicator1_id)%>
        }

    end

  end


  def test_conn
    BinManager.new("hello")
    conn = RwRun.connection
    query = "select * from users"
    results = conn.select_all(query)
    msg = ""
    results[0].keys.each do |key|
      msg += key + "<BR>"
    end
    redirect_to_index(msg)

  end

  def bypass_generic_security?
    true
  end


  def rebin_allocation
    return if authorise_for_web(program_name?, 'rebin_allocation') == false

    render :inline => %{
		<% @content_header_caption = "'Enter a rebin number allocation scancode and a production_run_code'"%>

		<%= allocate_rebin_num%>

		}, :layout => 'content'


  end


  #ajax
  def rebin_allocation_run_changed


    run_code = get_selected_combo_value(params)
    @rebin_allocation = RebinAllocation.new
    @rebin_allocation.production_run_code = run_code
    session[:rebin_allocation] = @rebin_allocation
    @run = ProductionRun.find_by_production_run_code(run_code)

    @station_codes = ActiveReworksDevice.find_by_sql("select active_device_code from active_reworks_devices where production_run_code = '#{run_code}' and (device_type_code = 'BS' OR device_type_code = 'BSS')").map { |c| [c.active_device_code] }
    @station_codes.unshift("<empty>")
    #	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('rebin_allocation','valid_station_codes',@station_codes)%>
        <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_rebin_allocation_valid_station_codes'/>
		<%= observe_field('rebin_allocation_valid_station_codes',:update => 'rmt_product_for_station_cell',:url => {:action => "rebin_allocation_station_changed"})%>
		<script>
		 <%= update_element_function(
          "rmt_product_for_station_cell", :action => :update,
        :content => "") %>
         <%= update_element_function(
          "run_status_cell", :action => :update,
        :content => @run.production_run_status) %>
         <%= update_element_function(
          "run_stage_cell", :action => :update,
        :content => @run.production_run_stage) %>

        </script>
		}

  end


  def rebin_allocation_station_changed

    station_code = get_selected_combo_value(params)
    if station_code == ""
      render :inline => %{

      }
      return
    end

    @rebin_allocation = session[:rebin_allocation]
    if station_code != ""
      device = ActiveReworksDevice.find_by_production_run_code_and_active_device_code(@rebin_allocation.production_run_code, station_code)
      link = ActiveRebinLink.find_by_station_code_and_day_line_batch_number_and_production_run_id(station_code, device.day_line_batch_number, device.production_run_id)
      if !link
        @rmt_code = "NO LINK FOUND IN ACTIVE REBIN LINKS!"
      else
        @rmt_code = link.rmt_product_code
      end
      @rebin_allocation.rmt_product_for_station = @rmt_code
    else
      @rmt_code = ""
    end
    #	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= @rmt_code %>
		}


  end


  def rebin_allocation_submit

    @scancode1 = params[:rebin_allocation][:scancode]

    if !@scancode1||@scancode1.strip == ""
      flash[:error] = "NO SCANCODE RECEIVED"
      rebin_allocation
      return
    end

    @result = nil
    run = ProductionRun.find_by_production_run_code(params[:rebin_allocation][:production_run_code])

    scans = @scancode1.split("_")
    station_code = scans[0]
    unique_num = scans[1]
    puts "UN:" + unique_num.to_s
    #----------
    #validation
    #----------
    if !station_code ||(station_code && station_code.strip == "")
      @result = "INVALID. REASON:STATION CODE IS EMPTY"
    elsif !unique_num||(unique_num && unique_num.strip == "")
      @result = "INVALID. REASON UNIQUE NUM IS EMPTY"

    end

    if @result
      flash[:error] = @result
      rebin_allocation
      return
    end
    #------------------------------------------------------------------------------------------------------------
    #WHAT TO DO:
    #-> Get list of active-devices where: binfill_station_code matches, run_stage(of associated production run) is
    #                                     NOT rebinning AND NOT bintipping_only
    #-> Throw exception IF more than one record is returned or IF no record is returned
    #-> Update the day_line batch number of active_device with the passed-in unique number
    #-> NB: Change production_runs' execution method(if needed) so that it does not overwrite active devices with
    #       such numbers)
    #-> Update rebin_link record's day_line_batch_number
    #-> Return (as a continuous string wrapping around 6 lines):
    #   -> production_run_code
    #   -> binfill_station_code
    #   -> class_code
    #   -> size_code
    #   -> commodity_code
    #   -> output_variety_code
    #   -> bin_type
    #   -> farm_code
    #------------------------------------------------------------------------------------------------------------

    #update active device
    devices = ActiveReworksDevice.find_all_by_production_run_code_and_active_device_code(run.production_run_code, station_code)
    if devices.length > 1
      @result = "INVALID.REASON: MORE THAN ONE STATION IN ACTIVE DEVICES"
    elsif devices.length == 0||(devices.length == 1 && devices[0].id == nil)
      @result = "INVALID.REASON: STATION NOT FOUND IN ACTIVE DEVICES"
    end

    if @result
      flash[:error] = @result
      rebin_allocation
      return
    end

    #update rebin link
    run_day_line_batch = devices[0].day_line_batch_number
    links = nil


    links = ActiveRebinLink.find_all_by_station_code_and_production_run_id(station_code, devices[0].production_run_id)
    if links.length > 1
      @result = "INVALID.  REASON: MORE THAN ONE REBIN LINK FOR DAY_LINE_BATCH"
    elsif links.length == 0||(links.length == 1 && links[0].id == nil)
      @result = "INVALID.  REASON: NO REBIN LINK FOR DAY_LINE_BATCH"
    end

    if @result
      flash[:error] = @result
      rebin_allocation
      return
    end

    err_type = Hash.new
    if Rebin.create_rebin(links[0], station_code, unique_num, err_type)

      @result = "Binfill station: " + station_code + " linked to number : " + unique_num.to_s + "<BR>"
      @result += "Production run code: " + devices[0].production_run_code + "<BR>"
      @result += "Rmt product code: " + links[0].rmt_product_code + "<BR>"
      @result += "Farm code: " + run.farm_code
    else
#      if err_type[:err_type]== 2
#        flash[:error] = "A  rebin is already allocated to this station and print number(" + unique_num + ") and run(" + devices[0].production_run_code + ")"
#      else
#        flash[:error] = "A not-yet-printed rebin is already allocated to this number(" + unique_num + ") and station"
#      end
      if err_type[:err_type] == 2
        flash[:error] = "INVALID.  REASON: NUMBER" + unique_num.to_s + " ALREADY ALLOCATED TO STATION FOR RUN:" + devices[0].production_run_code
      elsif  err_type[:err_type] == 1
        flash[:error] = "INVALID.  REASON:", "NUMBER: " + unique_num + " ALREADY ALLOCATED TO STATION AND NOT YET PRINTED REBIN"
      elsif  err_type[:err_type] == 3
        flash[:error] = "INVALID.  REASON: TRACK_SLMS_INDICATOR: " + links[0].rebin_template.track_indicator_code + " NOT FOUND"
      elsif  err_type[:err_type] == 4
        flash[:error] = "INVALID.  REASON: NO SHIFT DEFINED FOR LINE: " + links[0].line_code + "AND DATE: " + Time.now.strftime("%d/%b/%Y %H:%M:%S")
      end
      rebin_allocation
      return
    end

    @freeze_flash = true
    redirect_to_index(@result)
    return

  end


  def bintip_cancelled

    curr_tip_id = session[:current_tipping_bin_id]
    session[:current_tipping_bin_id]= nil
    session[:tip_reason] = nil
    session[:tip_run] = nil
    session[:prev_tipped_bin] = nil
    redirect_to_index("Bin tip cancelled for bin: " + curr_tip_id)

  end


  def invalid_bintip_confirmed
    #----------------------------------------------
    #A bin_tip is forced for a bin that was tipped
    #previously or that could not be found
    #-----------------------------------------------
    invalid_bin = nil
    BinsTippedInvalid.transaction do

      run = session[:tip_run]
      invalid_bin = BinsTippedInvalid.new
      invalid_bin.bin_id = session[:current_tipping_bin_id]
      invalid_bin.line_code = run.line_code
      invalid_bin.production_run_code = run.production_run_code
      invalid_bin.tipped_date_time = Time.now
      invalid_bin.authorisor_name = session[:user_id].user_name
      invalid_bin.weight = session[:prev_tipped_bin].weight if session[:prev_tipped_bin]
      invalid_bin.tipped_in_reworks = true
      invalid_bin.error_description = session[:tip_reason]

      invalid_bin.create

      NewOutboxRecord.new "bin_tipped_invalid", invalid_bin
    end

    redirect_to_index("Bin: " + invalid_bin.bin_id + " tipped(forced)")
  end


  def bintip_prompt(bin_id, reason, run, prev_tipped_bin = nil)
    @bin_id = bin_id
    @reason = reason

    session[:current_tipping_bin_id]= bin_id
    session[:tip_reason] = reason
    session[:tip_run] = run
    session[:prev_tipped_bin] = prev_tipped_bin

    render :inline => %{
          <script>
            if (confirm("Bin: <%= @bin_id %> <%= @reason %>. Do you want to tip the bin anyway?"))
              window.location.href = "/production/reworks/invalid_bintip_confirmed";
            else
              window.location.href = "/production/reworks/bintip_cancelled";
         </script>
    }

  end

  def tip_bin_submit
    #--------------------------------------------------------------------------------------------
    # Process:
    # -> Validate whether run exists
    # -> Call: BinManager.new(run).get_bin(bin_id)- it will fetch and create legacy bin
    # -> If bin is found in Bins table:
    #                                   -> Delete bin
    #                                   -> create tipped bin
    #    IF bin is NOT found:
    #                        -> determine reason ('not found' or 'previously valid/invalid tip')
    #                        -> Ask whethe bin should be tipped anyway
    #                        -> IF so:
    #                                 -> create invalid BIN
    #--------------------------------------------------------------------------------------------

    run_code = params[:tip_bin]['production_run_code']
    bin_id = params[:tip_bin]['bin_id']

    #----------------
    #Input validation
    #----------------
    if !run_code ||run_code.strip == ""
      flash[:error] = "You must provide a production_run_code"
      tip_bin
      return
    elsif !bin_id||bin_id.strip == ""
      flash[:error] = "You must provide a bin id"
      tip_bin
      return
    end

    run = ProductionRun.find_by_production_run_code(run_code)
    if !run
      flash[:error] = "Production run with run_code: " + run_code + " does not exists"
      tip_bin
      return
    end

    BinManager.new(run).get_bin(bin_id)
    bin = Bin.find_by_bin_id(bin_id)
    new_tipped_bin = nil
    if !bin
      #--------------------------------------------
      #Determine reason for bin bin not being found
      #--------------------------------------------
      reason = "Bin could not be found"
      prev_tipped = nil
      if prev_tipped = BinsTipped.find_by_bin_id(bin_id)
        reason = "This bin has already been tipped"
      elsif prev_tipped = BinsTippedInvalid.find_by_bin_id(bin_id)
        reason = "This bin has been tipped before with an override(as invalid bin)"
      end
      bintip_prompt(bin_id, reason, run, prev_tipped)
      return
    else
      Bin.transaction do
        new_tipped_bin = BinsTipped.new
        bin.export_attributes(new_tipped_bin)
        new_tipped_bin.bin_id = bin_id
        new_tipped_bin.tipped_in_reworks = true
        new_tipped_bin.tipped_date_time = Time.now
        new_tipped_bin.bin_receive_datetime = bin.bin_receive_datetime
        new_tipped_bin.create
        bin.destroy
        NewOutboxRecord.new "bin_tipped", new_tipped_bin
      end

    end

    redirect_to_index("Bin: " + new_tipped_bin.bin_id + " tipped successfully")

  end

  #======================================================================================
  # HAPPYMORE'S CODE: [5 May 2009 Changes]: Happymore changed the carton_search method
  # to use the generic search_engine's method to render the search
  # engine's form instead of the previous go to search form for cartons.
  # Happymore used the build_remote_search_form method to render the search engine
  # form remotely from cartons' point of view. Happymore didn't use the original
  # 'carton_search_submit' method to render the multi_select grid for the received cartons.
  # Happymore created another method 'render_se_cartons_grid' that will be
  # called by the search engine to render the grid.(He did this to avoid conflicts
  # with original code by HZ).
  #======================================================================================

  def carton_search
    #     render :inline => %{
    #		<% @content_header_caption = "'search cartons'"%>
    #
    #		<%= build_carton_search_form()%>
    #
    #		}, :layout => 'content'

    dm_session[:redirect] = true
    dm_session['se_layout']  = 'content'
    @content_header_caption = 'search cartons'

    build_remote_search_engine_form("receipt_cartons.yml", "render_se_cartons_grid")
    #session["receipt_cartons_default_values"] = Hash.new()
    #session["receipt_cartons_default_values"]["commodity_code"] = "AP"
    #session["receipt_cartons_default_values"]["carton_mark_code"] = "AP"


  end

  def receive_loaded_carton
    loaded_carton_search
  end

    def loaded_carton_search
       dm_session[:redirect] = true
       dm_session['se_layout']  = 'content'
       @content_header_caption = 'search cartons'

      build_remote_search_engine_form("receipt_loaded_cartons.yml", "render_se_cartons_grid")

    end


  def bin_search
    build_remote_search_engine_form("receipt_bins.yml", "render_se_bins_grid")
    dm_session[:redirect] = true
  end


  def render_se_bins_grid

    @bins= ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])

    @multi_select = "selected_bins"
    session[:bins_returned] = @bins
    render :inline => %{
      <% grid            = build_bins_grid(@bins) %>
      <% grid.caption    = @caption %>
     <% grid.height = '550' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end


  def buildup
    @dest_pallet = RwActivePallet.find(params[:id].to_i)
    source_pallets = session[:current_rw_run].rw_active_pallets
    source_pallets.delete_if { |p| p.id == @dest_pallet.id }

    all_cartons = @dest_pallet.rw_active_cartons.clone
    source_pallets.each do |pallet|
      all_cartons.concat(pallet.rw_active_cartons)
    end

    orphan_cartons = RwActiveCarton.find_by_sql("select * from rw_active_cartons where rw_run_id = #{session[:current_rw_run].id.to_s} and rw_active_pallet_id is null and rw_receipt_unit != 'carton'")
    all_cartons.concat(orphan_cartons)

    @buildup_cartons = all_cartons
    @grid_selected_rows = @dest_pallet.rw_active_cartons
    @multi_select = "selected_buildup_cartons"

    session[:all_buildup_cartons] = @buildup_cartons
    session[:buildup_dest_pallet] = @dest_pallet
    @key_based_access = nil

    render :inline => %{
      <% grid            = build_cartons_grid(@buildup_cartons) %>
      <% grid.caption    = 'select cartons to build up pallet: #{@dest_pallet.pallet_number}' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end


  def selected_buildup_cartons

    buildup_cartons = selected_records?(session[:all_buildup_cartons])
    dest_pallet = session[:buildup_dest_pallet]
    source_pallets = session[:current_rw_run].rw_active_pallets
    source_pallets.delete_if { |p| p.id == dest_pallet.id }

    #remove cartons already belonging to dest pallet
    selected_ctn_nums = buildup_cartons.map { |c| c.carton_number }
    orig_ctn_nums = dest_pallet.rw_active_cartons.map { |c| c.carton_number }

    removed_ctn_nums = orig_ctn_nums - selected_ctn_nums
    selected_ctn_nums = selected_ctn_nums - removed_ctn_nums - orig_ctn_nums

    Carton.transaction do
      #removed cartons, if any
      if removed_ctn_nums.length > 0
        RwActiveCarton.bulk_update({:pallet_number => "null", :pallet_id => "null", :rw_active_pallet_id => "null", :rw_pallet_action => "removed"}, removed_ctn_nums, {:rw_run_id => session[:current_rw_run].id.to_s})
        if dest_pallet.build_up_balance
          dest_pallet.build_up_balance -= removed_ctn_nums.length
        else
          dest_pallet.build_up_balance = -removed_ctn_nums.length
        end

        dest_pallet.build_up_balance += selected_ctn_nums.length

        dest_pallet.carton_quantity_actual -= removed_ctn_nums.length
        session[:current_rw_run].set_build_status(dest_pallet)
        dest_pallet.update
      end


      if dest_pallet.reworks_action.upcase == "NEW_PALLET"
        new_pallet_id = "null"
      else
        new_pallet_id = dest_pallet.pallet.id.to_s
      end


      if  selected_ctn_nums.length() > 0
        RwActiveCarton.bulk_update({:pallet_number => dest_pallet.pallet_number.to_s, :pallet_id => new_pallet_id, :rw_active_pallet_id => dest_pallet.id.to_s, :rw_pallet_action => "added"}, selected_ctn_nums, {:rw_run_id => session[:current_rw_run].id.to_s})


        #update each source pallet's quantities
        ctn_groups = buildup_cartons.group(["pallet_number"], nil, true)

        ctn_groups.each do |carton_group|
          if carton_group[0].pallet_number != dest_pallet.pallet_number
            if  carton_group[0].rw_active_pallet_id
              source_pallet = source_pallets.find(carton_group[0].rw_active_pallet_id)
              if source_pallet.build_up_balance
                source_pallet.build_up_balance -= carton_group.length
              else
                source_pallet.build_up_balance = -carton_group.length
              end
              source_pallet.carton_quantity_actual -= carton_group.length
              session[:current_rw_run].set_build_status(source_pallet)
              source_pallet.update
            end
          end
        end
      end

    end

    flash[:notice] = "buildup completed"
    rw_pallets

  end


  def render_se_cartons_grid
    #render_generic_grid
    @cartons = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    @multi_select = "selected_cartons"
    session[:cartons_returned] = @cartons
    @content_header_caption = nil

    render :inline => %{
        <% grid            = build_cartons_grid(@cartons)%>
        <% grid.caption    = 'select cartons to receive in reworks' %>
        <% grid.height = 550 %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
  end


  def pallet_search
    render :inline => %{
		<% @content_header_caption = "'search pallets'"%>

		<%= build_pallet_search_form()%>

		}, :layout => 'content'

  end


  def pallet_search_submit

    @pallets =Pallet.build_and_exec_query(params['pallet'])
    if !@pallets ||@pallets.length == 0
      redirect_to_index("No rows returned")
      return
    end

    if @pallets.length == 1000
      flash[:notice]= "The resulset was limited to 1000 rows!"
    end

    @caption = "'pallets retuned from query'"

    session[:pallets_returned]= @pallets

    render :inline => %{
      <% grid            = build_pallets_grid(@pallets,true) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end

  #------------------
  #BULK PALLET UPDATE
  #------------------
  def bulk_pallet_update(pallet = nil)


    @bulk_pallet_update_permission = authorise(program_name?, 'rw_bulk_pallet_edit', session[:user_id])


    if !pallet
      @pallet_edit = RwActivePallet.find(params[:id].to_i)
    else
      @pallet_edit = pallet
    end

    @content_header_caption = "'Edit pallet for bulk update'"
    session[:current_editing_pallet]= @pallet_edit

    render :inline => %{


		<%= build_pallet_bulk_edit_form(@pallet_edit,'bulk_update_pallet_submit','save')%>

		}, :layout => 'content'

  end

  def bulk_update_pallet_submit
    session[:current_editing_pallet].reload if session[:current_editing_pallet]
    #puts "COUNT B: " + session[:current_editing_pallet].actual_size_count_code
    session[:current_editing_pallet].update_attributes_state(params[:pallet_edit])
    #puts "COUNT A: " + session[:current_editing_pallet].actual_size_count_code
    session[:current_editing_pallet].proccess_virtual_fields
    changed = session[:current_editing_pallet].changed_fields?


    msg = session[:current_editing_pallet].derive_fields

    if msg!= ""
      flash[:error]= msg
      bulk_pallet_update(session[:current_editing_pallet])
      return
    else
      confirm_bulk_pallet_update
    end

  end

  def confirm_bulk_pallet_update


    changed = session[:current_editing_pallet].changed_fields
    changed_msg = build_changed_field_msg(changed)

    if changed_msg == ""
      flash[:notice]= "You did not change anything"
      rw_pallets
      return
    end


    @msg = "Are you sure you want to submit the bulk update? All " + session[:current_pallet_list].length().to_s + " pallets(with all their cartons) in the workspace(current run) will be updated. " + changed_msg


    render :inline => %{
   <script>
     if (confirm("<%=@msg%>") == true)
        {window.location.href = "/production/reworks/bulk_pallet_update_confirmed";}
     else
       {window.location.href = "/production/reworks/bulk_pallet_update_canceled";}
  </script>
    }

  end

  def tm_test
    redirect_to_index(TargetMarket.is_valid_for_org?("CE", "AI").to_s)
  end


  def bulk_pallet_update_confirmed
    n_cartons_updated = 0
    begin
      session[:current_editing_pallet].reworks_action = "reclassified" if session[:current_editing_pallet].reworks_action.upcase != "ALT_PACKED"
      session[:current_editing_pallet].transaction do
        session[:current_editing_pallet].save
        if session[:current_editing_pallet].errors.length > 0
          raise "Pallet could not be saved. Reported error(s): " + session[:current_editing_pallet].errors.full_messages.to_s
        end

        params = Hash.new
        session[:current_editing_pallet].changed_fields.each do |name, value|
          if name == "inspect_type_code"
            params.store('inspection_type_code', value[1])
          elsif name == "class_code"
            params.store('product_class_code', value[1])
          else
            params.store(name, value[1])
          end
        end


        #=============================================================
        #july 2008 changes: individual updates of pallets and all
        #cartons take too long, change to series of bulk updates
        #where cartons and pallets are not checked individually
        #=============================================================


        #--------------------------------------------------------------------
        #check if only target market has changed, if so:
        # get a unique list of orgs in all pallets and all cartons and
        # for each, check whether the org/target market combination is valid
        # If no errors occurred:
        # -> update all pallets in reworks run to changed target market
        # -> update all cartons in reworks run to changed target market
        #---------------------------------------------------------------------

        session[:current_editing_pallet].changed_fields.delete("reworks_action")


        if session[:current_editing_pallet].changed_fields.size == 1 && session[:current_editing_pallet].changed_fields.has_key?("target_market_code")
          puts "TARGET MARKET CHANGED: " + session[:current_editing_pallet].changed_fields["target_market_code"][1]
          #----------------------------
          #target market validity check
          #----------------------------
          err_list = session[:current_editing_pallet].check_target_market_validity_for_bulk_update
          if err_list.length > 0
            err_msg =[]
            err_list.each do |err|
              err_msg << "One or more " + err[0] + " have an organization : " + err[1] + ". This organization does not go with target_market: " + err[2]+ "<BR>"
            end
            flash[:error]= "Bulk update of target market could not be performed.Reasons: <BR> #{err_msg.join("<BR>")} "
            redirect_to :controller => 'production/reworks', :action => 'bulk_pallet_update', :id => session[:current_editing_pallet]['id']
            return
          end

          #err_list2= session[:current_editing_pallet].get_invalid_ctns_for_tm_grade("tm_changed",nil)
          #if  err_list2.length > 0
          #  err_msg=[]
          #  err_list2.each do |err|
          #    err_msg << "One or more " + err[0] + " have a grade : " + err[1] + ". This grade does not go with target_market: " + err[2]
          #  end
          #  flash[:error]= "Bulk update of target market could not be performed.Reasons: <BR> #{err_msg.join("<BR>")} "
          #  redirect_to :controller => 'production/reworks', :action => 'bulk_pallet_update', :id => session[:current_editing_pallet]['id']
          #  return
          #end


          session[:current_editing_pallet].update_all_target_market
          session[:current_pallet_list] = nil
          flash[:notice]= "Bulk update successful"
          rw_pallets
          return

        #elsif session[:current_editing_pallet].changed_fields.size == 1 && session[:current_editing_pallet].changed_fields.has_key?("grade_code")
        #           err_list2= session[:current_editing_pallet].get_invalid_ctns_for_tm_grade(nil,"grade_changed")
        #            if  err_list2.length > 0
        #              err_msg=[]
        #              err_list2.each do |err|
        #                err_msg << "One or more " + err[0] + " have a target_market : " + err[1] + ". This target_market does not go with grade: " + err[2]
        #              end
        #              flash[:error]= "Bulk update of grade_code could not be performed.Reasons: <BR> #{err_msg.join("<BR>")} "
        #              redirect_to :controller => 'production/reworks', :action => 'bulk_pallet_update', :id => session[:current_editing_pallet]['id']
        #              return
        #            end
        #
        #
        #            session[:current_editing_pallet].update_all_target_market
        #            session[:current_pallet_list] = nil
        #            flash[:notice]= "Bulk update successful"
        #            rw_pallets
        #            return
        end

        #if session[:current_editing_pallet].changed_fields.size >= 2 && session[:current_editing_pallet].changed_fields.has_key?("target_market_code") && session[:current_editing_pallet].changed_fields.has_key?("grade_code")
        #  err_list2= session[:current_editing_pallet].get_invalid_ctns_for_tm_grade("tm_changed","grade_changed")
        #  if  err_list2.length > 0
        #    err_msg=[]
        #    err_list2.each do |err|
        #      err_msg << "Target market:  " + err[2] + " and  " +  " Grade:   " + err[1] +" do not have a grade target market record"
        #    end
        #    flash[:error]= "Bulk update of grade_code and target market_code could not be performed.Reasons: <BR> #{err_msg.join("<BR>")} "
        #    redirect_to :controller => 'production/reworks', :action => 'bulk_pallet_update', :id => session[:current_editing_pallet]['id']
        #    return
        #  end
        #
        #
        #  session[:current_editing_pallet].update_all_target_market
        #  session[:current_pallet_list] = nil
        #  flash[:notice]= "Bulk update successful"
        #  rw_pallets
        #  return
        #end



        #================================================================================================================
        #Nov 2008 changes: Individual updates takes too long. Solution:
        #Use new optimized 'generic_bulk_carton_update' method to update cartons in groups with new
        #data on pallet. Then update each pallet separately
        #================================================================================================================
        n_cartons_updated = session[:current_editing_pallet].generic_bulk_carton_update params
        session[:current_pallet_list].each do |plt|
          if plt.id != session[:current_editing_pallet].id
            session[:current_editing_pallet].export_attributes(plt, true, session[:current_editing_pallet].unchanged_fields)
            plt.reworks_action = "reclassified" if plt.reworks_action.upcase != "ALT_PACKED"
            changed = plt.changed_fields?
            msg = plt.derive_fields
            if msg != ""

              flash[:error]= "Pallet: " + pallet.pallet_number.to_s + " could not be saved. Reason: <BR>" + msg
              bulk_pallet_update(session[:current_editing_pallet])
              return
            end
            if !plt.save
              raise "pallet: " + plt.pallet_number.to_s + " could not be updated. Reason: " + plt.errors.full_messages.to_s
            end
          end
        end
      end

      session[:current_pallet_list] = nil
      flash[:notice]= "Bulk update successful. " + n_cartons_updated.to_s + " cartons were updated"
      rw_pallets

    rescue

      handle_error("bulk update failed")
    end

  end

  def bulk_pallet_update_canceled

    session[:current_editing_pallet] = nil
    flash[:notice]= "Bulk pallet update cancelled"
    rw_pallets

  end


  def bulk_bin_update(bin = nil)

    @bulk_rebin_update_permission = authorise(program_name?, 'rw_bulk_bin_edit', session[:user_id])

    if !bin
      @bin = RwActiveBin.find(params[:id].to_i)
    else
      @bin = bin
    end

    @content_header_caption = "'Edit bin for bulk update'"
    session[:current_editing_bin]= @bin

    render :inline => %{


		<%= build_bulk_edit_bins_form(@bin,'bulk_update_bin_submit','save',false,@is_create_retry)%>

		}, :layout => 'content'

  end



  def complete_bin_run
    return if authorise_for_web(program_name?, 'rw_physical') == false
    begin

      if !session[:current_rw_run]
        @freeze_flash = true
        redirect_to_index("You do not have a current editing run")
        return
      end
      run = RwRun.find(session[:current_rw_run].id).complete
    rescue
      handle_error("reworks run could not be completed")
    end
  end

  def bulk_update_bin_submit

    if (params[:bin][:rmt_product_id] == "" || params[:bin][:rmt_product_id] == "")
      params[:bin][:rmt_product_id] = nil
#
    end

    if (params[:bin][:production_run_rebin_id] == "" || params[:bin][:production_run_rebin_id] == "")
      params[:bin][:production_run_rebin_id] = nil
#
    end

    if (params[:bin][:pack_material_product_id] == "" || params[:bin][:pack_material_product_id] == "")
      params[:bin][:pack_material_product_id] = nil
#
    end

    if (params[:bin][:rebin_track_indicator_code] == "" || params[:bin][:rebin_track_indicator_code] == "")
      params[:bin][:rebin_track_indicator_code] = nil
    end
    g = params[:bin][:track_indicator1_id]
    if (params[:bin][:track_indicator1_id] == "" || params[:bin][:track_indicator1_id] == "" || params[:bin][:track_indicator1_id] == 0.to_i || params[:bin][:track_indicator1_id] == nil)
      params[:bin][:track_indicator1_id] = ""
    end

    if (params[:bin][:track_indicator2_id] == "" || params[:bin][:track_indicator2_id] == ""|| params[:bin][:track_indicator2_id] == 0.to_i)
      params[:bin][:track_indicator2_id] = ""
    end

    if (params[:bin][:track_indicator3_id] == "" || params[:bin][:track_indicator3_id] == ""|| params[:bin][:track_indicator3_id] == 0.to_i)
      params[:bin][:track_indicator3_id] = ""
    end

    if (params[:bin][:track_indicator4_id] == "" || params[:bin][:track_indicator4_id] == ""|| params[:bin][:track_indicator4_id] == 0.to_i)
      params[:bin][:track_indicator4_id] = ""
    end

    if (params[:bin][:track_indicator5_id] == "" || params[:bin][:track_indicator5_id] == ""|| params[:bin][:track_indicator5_id] == 0.to_i)
      params[:bin][:track_indicator5_id] = ""
    end


    session[:current_editing_bin].update_attributes_state(params[:bin])


    confirm_bulk_bin_update

  end

  def confirm_bulk_bin_update


    #derivatives = ["orchard_code"]
    #----------------------------------------------------------------------------------------------------------------------
    #Get a list of all fields that have changed, excluding derived fields that are derived from more that one single source
    #----------------------------------------------------------------------------------------------------------------------


    changed = session[:current_editing_bin].changed_fields?
    changed_hash = Hash.new
    for change in changed
      to_change = change[0]
      changing = to_change.chomp("_id")
      if changing != "is_half_bin" || changing != "is_sample_bin" || changing != "orchard_code" || changing != "rebin_track_indicator_code"
        changing = changing + "_code"
      end
      changed_hash["#{changing}"] = change[1]
    end

    changed_msg = build_changed_bin_field_msg(changed_hash)


    if changed_msg == ""
      flash[:notice]= "You did not change anything"
      rw_bins
      return
    end
    @msg = "Are you sure you want to submit the bulk update?  " + session[:current_bin_list].length().to_s + " bins in the workspace(current run) will be updated. " + changed_msg


    render :inline => %{
   <script>
     if (confirm("<%=@msg%>") == true)
        {window.location.href = "/production/reworks/bulk_bin_update_confirmed";}
     else
       {window.location.href = "/production/reworks/bulk_bin_update_canceled";}
  </script>
    }

  end

  def bulk_bin_update_confirmed
    begin
      session[:current_editing_bin].reworks_action = "reclassified"
      unchanged = session[:current_editing_bin].unchanged_fields
      changed_fields = session[:current_editing_bin].changed_fields

      session[:current_editing_bin].transaction do
        #rw_receipt_bin = RwReceiptBin.find_by_bin_id(session[:current_editing_bin].bin_id)
        #session[:current_editing_bin].export_attributes(rw_receipt_bin, true, unchanged)
        #rw_receipt_bin.reworks_action = "reclassified"

        #rw_receipt_bin.save
        if !session[:current_editing_bin].save
          raise "Representative bin could not be saved. Reason: " + session[:current_editing_bin].errors.full_messages.to_s
        end

        session[:current_bin_list].each do |bin|
          if bin.id != session[:current_editing_bin].id
            session[:current_editing_bin].export_attributes(bin, true, unchanged)

            bin.reworks_action = "reclassified"


            if !bin.save
              raise "bin: " + bin.bin_number.to_s + " could not be updated. Reason: " + bin.errors.full_messages.to_s
            end
          end
        end

      end

      session[:current_bin_list] = nil
      flash[:notice]= "Bulk update successful"
      rw_bins

    rescue

      handle_error("bulk update failed")
    end
  end

  def bulk_bin_update_canceled
    session[:current_editing_bin] = nil
    flash[:notice]= "Bulk bin update cancelled"
    rw_bins
  end


  def remove_bin_from_reworks
    bin = RwActiveBin.find(params[:id])

    bin.transaction do
      bin.rw_receipt_bin.destroy
      bin.destroy
      session[:current_bin_list]= nil
    end

    flash[:notice]= "Bin removed from reworks"
    rw_bins
  end


  #-----------------
  #BULK CARON UPDATE
  #-----------------
  def bulk_carton_update(carton = nil)

    if !carton
      @carton_edit = RwActiveCarton.find(params[:id].to_i)
    else
      @carton_edit = carton
    end

    @content_header_caption = "'Edit carton for bulk update'"
    session[:current_editing_carton]= @carton_edit

    render :inline => %{


		<%= build_bulk_update_carton_form(@carton_edit,'bulk_update_carton_submit','save')%>

		}, :layout => 'content'

  end


  def bulk_update_carton_submit
    session[:current_editing_carton].reload
    session[:current_editing_carton].update_attributes_state(params[:carton_edit])
    msg = session[:current_editing_carton].derive_fields

    if msg!= ""
      flash[:error]= msg
      bulk_carton_update(session[:current_editing_carton])
      return
    else
      confirm_bulk_carton_update
    end

  end

  def confirm_bulk_carton_update

    #----------------------------------------------------------------------------------------------------------------------
    #Derivatives are fields that are dependent on other fields. Some derivatives,e.g. fg_code_old are derived from more
    #than one source field. Because of this, one cannot include this type of derivative in the changed list, because
    #another carton may derive it differently(only some of it's source fields may be the same in other carton)
    #---------------------------------------------------------------------------------------------------------------------
    derivatives = ["actual_size_count_code", "fg_mark_code", "fg_product_code", "commodity_code", "variety_short_long", "erp_cultivar", "grade_code", "product_class_code", "treatment_code", "fg_code_old", "old_pack_code", "marking", "diameter", "carton_fruit_nett_mass", "farm_code", "account_code", "egap", "units_per_carton", "production_run_id", "unit_pack_product_code"]
    #----------------------------------------------------------------------------------------------------------------------
    #Get a list of all fields that have changed, excluding derived fields that are derived from more that one single source
    #----------------------------------------------------------------------------------------------------------------------

    changed = session[:current_editing_carton].changed_fields? derivatives
    changed_msg = build_changed_field_msg(changed)

    if changed_msg == ""
      flash[:notice]= "You did not change anything"
      rw_cartons
      return
    end

    @msg = "Are you sure you want to submit the bulk update? All " + session[:current_carton_list].length().to_s + " cartons in the workspace(current run) will be updated. " + changed_msg


    render :inline => %{
   <script>
     if (confirm("<%=@msg%>") == true)
        {window.location.href = "/production/reworks/bulk_carton_update_confirmed";}
     else
       {window.location.href = "/production/reworks/bulk_carton_update_canceled";}
  </script>
    }

  end


  def bulk_carton_update_confirmed
    n_cartons_updated = 0
    begin
      session[:current_editing_carton].reworks_action = "reclassified"
      session[:current_editing_carton].transaction do


        unchanged_fields = session[:current_editing_carton].unchanged_fields
        if !session[:current_editing_carton].valid?
          raise "Representative carton could not be saved. Reason: " + session[:current_editing_carton].errors.full_messages.to_s
        end


        if session[:current_editing_carton].changed_fields.size == 1 && session[:current_editing_carton].changed_fields.has_key?("target_market_code")
          puts "TARGET MARKET CHANGED: " + session[:current_editing_carton].changed_fields["target_market_code"][1]

          err_list = session[:current_editing_carton].check_target_market_validity_for_bulk_update
          if err_list.length > 0
            err_msg = "Bulk update of target market could not be performed."
            err_msg += "Reason: <BR>"
            err_list.each do |err|
              err_msg += "One or more " + err[0] + " have an organization : " + err[1] + ". This organization does not go with target_market: " + err[2]+ "<BR>"
            end
            raise err_msg
          end


          session[:current_editing_carton].update_all_target_market
          session[:current_carton_list] = nil
          flash[:notice]= "Bulk update successful"
          rw_cartons
          return
        end
        #===========================================================
        #JULY 2008: CHANGES
        #Bulk update takes too long- due to the individual reads and update
        #for each carton. Various custom bulk updates that doesn't work
        #at the individual carton update will replace this
        #============================================================


        #------------------------------------------------------------------------------------------
        #Only Export attributes that have changed, BUT NOT derivative attributes, since
        #each carton need to calculate their own derivatives, they are:
        #-> fg_product_code, commodity_code,variety_short_long,erp_cultivar,grade_code
        #   product_class_code,treatment_code, extended_fg_code,fg_code_old,
        #   old_pack_code,marking,diameter,carton_fruit_nett_mass,puc,farm_code,account_code,egap
        #-------------------------------------------------------------------------------------------
        n_cartons_updated = session[:current_editing_carton].generic_bulk_carton_update(unchanged_fields)

      end

      session[:current_carton_list] = nil
      flash[:notice]= "Bulk update successful. " + n_cartons_updated.to_s + " cartons updated"
      rw_cartons

    rescue

      handle_error("bulk update failed")
    end

  end

  def bulk_carton_update_canceled

    session[:current_editing_carton] = nil
    flash[:notice]= "Bulk carton update cancelled"
    rw_cartons

  end


  def remove_carton_from_reworks
    carton = RwActiveCarton.find(params[:id])
    if carton.reworks_action != "received" ||carton.rw_pallet_action
      flash[:notice]= "Carton cannot be removed as Reworks actions have already been performed against it. You can, however, cancel the entire run"
      rw_cartons
      return
    end

    carton.transaction do
      carton.rw_receipt_carton.destroy
      carton.destroy
      session[:current_carton_list]= nil
    end

    flash[:notice]= "Carton removed from reworks"
    rw_cartons

  end


  def selected_cartons
    @selected_cartons = selected_records?(session[:cartons_returned], nil, true)




    session[:current_rw_run].transaction do
      @selected_cartons.each do |selected_carton|
        RwReceiptCarton.receive_carton(selected_carton, session[:current_rw_run], nil, true)
      end
    end

    session[:cartons_returned] = nil
    redirect_to_index("Cartons were successfully received")

  end

  def failed_multi_select_received_bins?(bin_numbers)

    failed_bins = Array.new
    for bin_number in bin_numbers
      @bin= Bin.find_by_bin_number(bin_number)
      received_bin = RwReceiptBin.find_by_bin_number_and_rw_run_id(bin_number, session[:current_rw_run].id)
      if @bin.rebin_status && @bin.rebin_status== "not printed"
        failed_bins.push(bin_number + "(rebin status not printed)")

      elsif   @bin.exit_ref && @bin.exit_ref == "scrapped"
        failed_bins.push(bin_number + "(has been scrapped)".to_s)

      elsif received_bin && received_bin.bin_number == bin_number
        failed_bins.push(bin_number + "(has already bin received in this run)".to_s)
      end

    end
    return failed_bins
  end


  def selected_bins
    @selected_bins = selected_records?(session[:bins_returned], nil, true)
      bin_numbers = Array.new
      @selected_bins.each do |selected_bin|
        bin_numbers << selected_bin.bin_number
      end


      failed_bins= failed_multi_select_received_bins?(bin_numbers)
      if failed_bins.length > 0
        flash[:error]= "The following bins cannot be received. Reasons are in brackets: <BR> #{failed_bins.join("<BR>")}"
        render_se_bins_grid
        return
      end

      received_bins_error=RwReceiptBin.receive_bin(@selected_bins, session[:current_rw_run])
      if received_bins_error==nil
        @freeze_flash = true
        flash[:notice]= "the following bins were received successfully : :<BR> #{bin_numbers.join("<BR>")}"
         receive_bin
        return
      else
        flash[:error]= received_bins_error
        return
         receive_bin  #?????
      end

  end

  def selected_pallets
    @selected_pallets = selected_records?(session[:pallets_returned])
    session[:current_rw_run].transaction do
      @selected_pallets.each do |selected_pallet|


        intake_headers_production_id=ActiveRecord::Base.connection.select_one("select intake_headers_production_id from pallets where pallet_number in ('#{selected_pallet.pallet_number.strip}')")['intake_headers_production_id']
        if intake_headers_production_id
          @freeze_flash = true
          flash[:error]=" The pallet  with number: " + selected_pallet.pallet_number.to_s + " is on an intake consignment"
          raise flash[:error]
        end
        RwReceiptPallet.receive_pallet(selected_pallet, session[:current_rw_run])
      end
      pallet_numbers_order_upgrade=nil
      if session[:current_rw_run].rw_active_pallets && session[:current_rw_run].rw_active_pallets.length > 0
         pallet_numbers_order_upgrade=session[:current_rw_run].rw_active_pallets.map{|p|p.pallet_number}
      end

    if pallet_numbers_order_upgrade
      Order.get_and_upgrade_prelim_orders(pallet_numbers_order_upgrade)
    end
    end

    session[:pallets_returned] = nil
    redirect_to_index("Pallets were successfully received")

  end


  def carton_search_submit

    @cartons =Carton.build_and_exec_query(params['carton'])
    if !@cartons ||@cartons.length == 0
      redirect_to_index("No rows returned")
      return
    end

    if @cartons.length == 1000
      flash[:notice]= "The resulset was limited to 1000 rows!"
    end

    session[:cartons_returned]= @cartons

    render :inline => %{
      <% grid            = build_cartons_grid(@cartons,true) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end


  def time_search_enabled

    @enabled = false
    @carton = Carton.new
    if params.to_s.index("1")
      @enabled = true
    end

    render :inline => %{


   <script>
     img = document.getElementById('img_carton_time_search');
     if(img != null)img.style.display = 'none';

     <% if @enabled
         from_time_content = datetime_select('carton', 'pack_date_from')
         to_time_content = datetime_select('carton', 'pack_date_to')
        else
         from_time_content = 'disabled'
         to_time_content = 'disabled'
        end %>


     <%= update_element_function(
        "pack_date_from_cell", :action => :update,
        :content => from_time_content)%>

      <%= update_element_function(
        "pack_date_to_cell", :action => :update,
        :content => to_time_content)%>

   </script>
    }

  end


  def pallet_time_search_enabled

    @enabled = false
    @pallet = Pallet.new
    if params.to_s.index("1")
      @enabled = true
    end

    render :inline => %{


   <script>
     img = document.getElementById('img_pallet_pallet_time_search');
     if(img != null)img.style.display = 'none';

     <% if @enabled
         from_time_content = datetime_select('pallet', 'completed_date_from')
         to_time_content = datetime_select('pallet', 'completed_date_to')
        else
         from_time_content = 'disabled'
         to_time_content = 'disabled'
        end %>


     <%= update_element_function(
        "completed_date_from_cell", :action => :update,
        :content => from_time_content)%>

      <%= update_element_function(
        "completed_date_to_cell", :action => :update,
        :content => to_time_content)%>

   </script>
    }

  end


  def bin_time_search_enabled

    @enabled = false
    @bin = Bin.new
    if params.to_s.index("1")
      @enabled = true
    end

    render :inline => %{


   <script>
     img = document.getElementById('img_bin_rebin_time_search');
     if(img != null)img.style.display = 'none';

     <% if @enabled
         from_time_content = datetime_select('bin', 'trans_date_from')
         to_time_content = datetime_select('bin', 'trans_date_to')
        else
         from_time_content = 'disabled'
         to_time_content = 'disabled'
        end %>


     <%= update_element_function(
        "trans_date_from_cell", :action => :update,
        :content => from_time_content)%>

      <%= update_element_function(
        "trans_date_to_cell", :action => :update,
        :content => to_time_content)%>

   </script>
    }

  end


  def reject_pallet

    pallet = RwActivePallet.find(params[:id])
    pallet.is_rejected = true
    pallet.update

  end

  def cancel_run
    return if authorise(program_name?, 'rw_physical', session[:user_id])== false
    run = RwRun.find(params[:id].to_i)

    run.cancel_run

    if session[:current_rw_run]&& run.id == session[:current_rw_run].id
      session[:current_rw_run]= nil
      @info_sticker = ""
    end

    run.destroy
    flash[:notice]= "run cancelled"
    editing_rw_runs
    return

  end


  def print_carton_label

    return if authorise(program_name?, 'rw_physical', session[:user_id])== false

    carton = RwActiveCarton.find(params[:id].to_i)
    n_labels_printed= carton.n_labels_printed.to_i
    @id =params[:id]
    if n_labels_printed.to_i >= 1
       @msg = "#{n_labels_printed.to_s}" +" " +  "carton labels have been printed for this carton are you sure you want to reprint them?"
       render :inline => %{
       <script>
         if (confirm("<%=@msg%>") == true)
            {window.location.href = '/production/reworks/reprint_carton_label/<%=@id%>';}
         else
           {window.location.href = '/production/reworks/carton_printing_cancelled';}
      </script>
        }
    else
      reprint_carton_label
    end


  end

  def reprint_carton_label

    return if authorise(program_name?, 'rw_physical', session[:user_id])== false

    carton = RwActiveCarton.find(params[:id].to_i)

    begin

      #    carton.build_label_data
      #    flash[:hello]
      #    return
      if !RUBY_PLATFORM.index('linux')
        file_name = session[:user_id].user_name + "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".bat"
        file = File.new(file_name, "w")
        file.puts "ruby \"app\\models\\carton_label_printing.rb\"" + " " + carton.id.to_s + " " +  session[:user_id].user_name
        file.close

        result = eval "\`" + "\"" + file_name + "\"" + "\"`"
      else
        file_name = session[:user_id].user_name + "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".sh"
        file = File.new(file_name, "w")
        file.puts "ruby  \"app/models/carton_label_printing.rb\"" + " " + carton.id.to_s + " " +  session[:user_id].user_name
        file.close

        result = eval "\` sh " + file_name + "\`"

      end

      if result.index("error")
        raise result
      end
      puts "print result: " + result
      #File.delete file_name

      @freeze_flash = true
      flash[:notice] = result
      render_cartons

      #redirect_to_index(result)
    rescue
      handle_error("Label could not be printed")
    end


  end


  #============
  #RECEIVE CODE
  #============
  def receive_carton

    render :inline => %{
		<% @content_header_caption = "'receive reworks items'"%>

		<%= build_receive_item_form("receive_carton_submit","receive","carton_number")%>
    <script>
		 document.getElementById('received_item_carton_number').focus();
		</script>

		}, :layout => 'content'

  end

  def new_pallet
    return if authorise_for_web(program_name?, 'rw_physical') == false

    if !session[:current_rw_run]
      @freeze_flash = true
      redirect_to_index("You have not yet created or selected an active(editing) reworks run")
      return
    end

    render :inline => %{
		<% @content_header_caption = "'create new pallet from carton'"%>

		<%= build_new_pallet_form()%>

		}, :layout => 'content'

  end


  def edit_repr_repack_carton_submit

    session[:current_editing_carton].update_attributes_state(params[:carton_edit])
    session[:current_editing_carton].reworks_action = "alt_packed"
    msg = session[:current_editing_carton].derive_fields

    if msg!= ""
      flash[:error]= msg
      edit_repr_repack_carton(session[:current_editing_carton])
      return
    end

    carton = session[:current_editing_carton]
    session[:current_pallet_repack].store_representative_carton(carton, carton.production_run_code + "__" + carton.farm_code + "__" + carton.puc)
    flash[:notice]= "representative carton saved"
    active_pallet_action


  end

  def edit_repr_carton_submit

    session[:current_editing_carton].update_attributes_state(params[:carton_edit])
    msg = session[:current_editing_carton].derive_fields

    if msg!= ""
      flash[:error]= msg
      edit_repr_carton(session[:current_editing_carton])
      return
    end


    carton = session[:current_editing_carton]
    session[:current_pallet_update].store_representative_carton(carton, carton.production_run_code + "__" + carton.farm_code + "__" + carton.puc, true)

    active_pallet_action


  end

  def batch_update_pallet_submit

    if !session[:current_pallet_update].fg_carton
      flash[:error]= "You must first select a representative carton!"
      active_pallet_action
      return
    end

    session[:current_pallet_update].update_pallet
    session[:current_editing_carton] = nil
    session[:current_pallet_update] = nil
    session[:active_pallet_action]= nil
    session[:selected_run_group]= nil
    #session[:current_carton_list]= nil
    redirect_to_index("All cartons of all groups were updated successfully")


  end


  def active_pallet_action

    begin

      if !session[:active_pallet_action]
        @freeze_flash = true
        redirect_to_index("There is no active pallet transaction")
      else
        eval(session[:active_pallet_action])

      end

    rescue
      handle_error("Active transaction load error occurred")
    end

  end




  def edit_repr_repack_carton(carton = nil)
    return if authorise(program_name?, 'rw_physical', session[:user_id])== false

    if !carton
      @carton_edit = session[:current_pallet_repack].puc_groups[params[:id]][:representative_carton]
    else
      @carton_edit = carton
    end

    if !params[:id]
      params[:id]= carton.production_run_code + "__" + carton.farm_code + "__" + carton.puc
    end

    @content_header_caption = "'edit carton to batch update all cartons of group: " + params[:id] + "(pallet: " + session[:current_pallet_repack].pallet.pallet_number.to_s + ")'"

    @disallow_fg_edit = nil
    if session[:current_pallet_repack].puc_groups[params[:id]][:group_num]> 1
      @disallow_fg_edit = true
    else
      @content_header_caption = "'edit carton to set Pallet FG values AND batch update group: " + params[:id] + "(pallet: " + session[:current_pallet_repack].pallet.pallet_number.to_s + ")'"
    end

    session[:current_editing_carton]= @carton_edit


    render :inline => %{


		<%= build_edit_carton_form(@carton_edit,'edit_repr_repack_carton_submit','save',@disallow_fg_edit)%>

		}, :layout => 'content'

  end


  def edit_repr_carton(carton = nil)
    return if authorise(program_name?, 'rw_physical', session[:user_id])== false

    if !carton
      @carton_edit = session[:current_pallet_update].puc_groups[params[:id]][:representative_carton]
    else
      @carton_edit = carton
    end

    if !params[:id]
      params[:id]= carton.production_run_code + "__" + carton.farm_code + "__" + carton.puc
    end

    session[:current_editing_carton]= @carton_edit
    @content_header_caption = "'edit carton to batch update all cartons of group: " + params[:id] + "(pallet: " + session[:current_pallet_update].pallet.pallet_number.to_s + ")'"
    @is_reclassification = true
    render :inline => %{


		<%= build_edit_carton_form(@carton_edit,'edit_repr_carton_submit','save')%>

		}, :layout => 'content'

  end


  def selected_repack_carton

    repr_carton = session[:selected_run_group][:cartons].find { |c| c.id.to_s == params[:id].to_s }

    session[:selected_run_group][:representative_carton]= repr_carton
    session[:current_pallet_repack].store_representative_carton(repr_carton, repr_carton.production_run_code + "__" + repr_carton.farm_code + "__" + repr_carton.puc)
    render_repack_pallet

  end


  def set_pfp_submit
    pfp = params[:pallet][:pallet_format_product_code]

    pallet_transaction = session[:current_pallet_update]
    pallet_transaction = session[:current_pallet_repack] if !pallet_transaction
    pallet = pallet_transaction.pallet

    pallet.pallet_format_product_code = pfp
    pallet.pallet_format_product_id = PalletFormatProduct.find_by_pallet_format_product_code(pfp).id
    flash[:notice] = "saved: " + pallet.pallet_format_product_code
    active_pallet_action

  end

  def set_pallet_format_product

    pallet_process = session[:current_pallet_update]
    pallet_process = session[:current_pallet_repack] if !pallet_process

    @content_header_caption = "'Set pallet format product(Carton pack product is: " + pallet_process.fg_carton.carton_pack_product_code + ")'"

    @pallet_update = pallet_process

    render :inline => %{

		<%= build_set_pfp_form(@pallet_update)%>

		}, :layout => 'content'

  end

  def pallet_pfp_changed

    pfp = get_selected_combo_value(params)
    pallet_transaction = session[:current_pallet_update]
    pallet_transaction = session[:current_pallet_repack] if !pallet_transaction
    pallet = pallet_transaction.pallet

    cpp = CartonsPerPallet.find_by_pallet_format_product_code_and_carton_pack_product_code(pfp, pallet_transaction.fg_carton.carton_pack_product_code)

    puts "PFP: " + pallet_transaction.pallet.pallet_format_product_code + "CPP: " + pallet_transaction.fg_carton.carton_pack_product_code
    if cpp
      cpp_details = "<BR><strong>Cartons Per Pallet detail: </strong> <BR>"
      cpp_details += "<font size = 'smallest'>cartons per pallet: " + cpp.cartons_per_pallet.to_s + "<BR>"
      cpp_details += "layers per pallet: " + cpp.layers_per_pallet.to_s + "<BR>"
      cpp_details += "cartons per layer: " + cpp.cartons_per_layer.to_s + "<BR>"
      cpp_details += "cpp code: " + cpp.cpp_code.to_s + "<BR>"
      cpp_details += "cpp description: " + cpp.description.to_s + "<BR>"
      cpp_details += "carton pack product code: " + pallet_transaction.fg_carton.carton_pack_product_code + "</font>"
    else
      cpp_details = "Cartons per pallet record not found for pfp: " + pallet.pallet_format_product_code
    end
    @cpp_details = cpp_details

    render :inline => %{
                          <script>
                           img = document.getElementById('img_pallet_pallet_format_product_code');
                           if(img != null)img.style.display = 'none';
                           else
                           alert('nf');
                           </script>
	                     <%=
                         @cpp_details
                         %>
		}


  end


  def selected_group_carton

    repr_carton = session[:selected_run_group][:cartons].find { |c| c.id.to_s == params[:id].to_s }
    session[:selected_run_group][:representative_carton]= repr_carton
    pallet = session[:current_pallet_update].pallet
    session[:current_pallet_update].store_representative_carton(repr_carton, repr_carton.production_run_code + "__" + repr_carton.farm_code + "__" + repr_carton.puc, true)
    puts "R CTN ID:" + repr_carton.id.to_s

    @pallet_update = session[:current_pallet_update]

    @content_header_caption = "'Batch update pallet cartons for pallet: " + pallet.pallet_number.to_s + "'"

    render :inline => %{

		<%= build_batch_update_pallet_form(@pallet_update)%>

		}, :layout => 'content'

  end

  def select_carton_for_run_group

    run_code = params[:id]
    session[:selected_run_group]= run_code
    @cartons = session[:current_pallet_update].puc_groups[run_code][:cartons]
    session[:selected_run_group]= session[:current_pallet_update].puc_groups[run_code]
    @content_header_caption = "'Select a representative carton for group: " + run_code + "'"
    render :inline => %{
      <% grid            = build_select_carton_grid(@cartons,"selected_group_carton") %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end

  def select_carton_for_repack

    run_code = params[:id]
    session[:selected_run_group]= run_code
    @cartons = session[:current_pallet_repack].puc_groups[run_code][:cartons]
    session[:selected_run_group]= session[:current_pallet_repack].puc_groups[run_code]
    @content_header_caption = "'Select a representative carton for group: " + run_code + "'"
    render :inline => %{
      <% grid            = build_select_carton_grid(@cartons,"selected_repack_carton") %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end

  def reclassify_pallet

    session[:current_pallet_update] = nil
    session[:current_pallet_repack] = nil

    pallet = RwActivePallet.find(params[:id].to_i)
    @pallet_update = PalletUpdate.new(pallet)
    session[:current_pallet_update] = @pallet_update
    session[:active_pallet_action]= "render_reclassify_pallet"
    render_reclassify_pallet


  end

  def print_pallet

    @pallet = RwActivePallet.find(params[:id].to_i)
    session[:print_pallet]=@pallet
    @pallet_update = PalletUpdate.new(@pallet)
    puts "pallet id: " + @pallet_update.pallet.id.to_s
    session[:current_pallet_print] = @pallet_update
    session[:active_pallet_action]= "render_print_pallet"



    render_print_pallet


  end


  def repack_pallet

    pallet = RwActivePallet.find(params[:id].to_i)

    session[:current_pallet_update] = nil
    session[:current_pallet_repack] = nil

    if  pallet.reworks_action == "new_pallet"
      @freeze_flash = true
      flash[:notice]= "You cannot perform an alt pack on a pallet created in reworks"
      rw_pallets
      return
    end


    if StockItem.find_by_inventory_reference(pallet.pallet_number).location_code.upcase.index("REWORKS")
      @freeze_flash = true
      flash[:notice]= "You cannot perform an alt pack on a pallet with location 'reworks'"
      rw_pallets
      return

    end

    #TODO uncomment
    stock_item = StockItem.find_by_inventory_reference(pallet.pallet_number)
    if stock_item && !(stock_item.location_code.upcase == "PACKHSE" ||stock_item.location_code.upcase == "REWORKS"||stock_item.location_code.upcase == "BAGGING"||stock_item.location_code.upcase == "BAGGING_REWORKS"||stock_item.location_code.upcase == "PART_PALLETS")
    flash[:error] = "Pallet is at location: " + stock_item.location_code + ". Only pallets in REWORKS or PACKHSE can be repacked"
    rw_pallets
    return
    end


    @pallet_repack = PalletUpdate.new(pallet, true)
    session[:current_pallet_repack] = @pallet_repack
    session[:active_pallet_action]= "render_repack_pallet"
    render_repack_pallet(@pallet_repack)


  end

  def add_repack_info_fields(pallet_update)

    code = "class RwRepackInfo\n"
    code += " attr_accessor :overridden_amounts,:new_total,:override_reason,:total_cartons,:target_pallet,"
    pallet_update.puc_groups.each do |run_code, run_group|
      code += ":txt_" + run_code.gsub(" ", "_") + ","
    end

    code = code.slice(0, code.length() -1)
    code += "\nend"

    puts code
    eval code

  end

  def pallet_repack_commit_confirmed

    if params[:repack_commit] && params[:repack_commit][:reason]
      if params[:repack_commit][:reason].strip == ""
        @content_header_caption = "'Repack summary for pallet: " + session[:current_pallet_repack].pallet.pallet_number.to_s + "'"
        render :inline => %{

           <% flash[:error]= "<font color = 'red'>You must provide a reason for overriding the system calculated ratios(amount of cartons per group)</font>" %>

		<%= session[:info_panel]%>

        <%= build_pallet_repack_commit_form(true)%>
        }, :layout => 'content'
        return
      else

        session[:current_pallet_repack].user = session[:user_id]
        session[:current_pallet_repack].override_amounts(params[:repack_commit][:reason], session[:pallet_repack_info].overridden_amounts)

      end

    end

    session[:current_pallet_repack].repack_pallet(session[:pallet_repack_info].new_total)
    new_pallet_str = ""
    new_pallet_str = " TO PALLET " + session[:current_pallet_repack].rw_pallet_id.to_s
    @freeze_flash = true
    #-------------------------------------------------------
    #clear all session info related to completed transaction
    #-------------------------------------------------------
    session[:current_pallet_repack] = nil
    session[:pallet_repack_info] = nil
    session[:info_panel] = nil
    session[:active_pallet_action]= nil

    redirect_to_index("PALLET '#{session[:current_pallet_repack]}ALT PACKED  " + new_pallet_str)
  end

  def repack_pallet_submit

    #--------------------------------------------------------------
    #Validations: make sure user selected a carton from all groups
    #--------------------------------------------------------------
    repr_carton = nil
    all_groups_has_repr_ctn = true
    has_fg_carton = false
    pallet_update = session[:current_pallet_repack]
    pallet_update.puc_groups.each do |run_code, group|
      if group[:group_num]== 1 && group[:representative_carton]
        repr_carton = group[:representative_carton]
        has_fg_carton = true
      elsif !group[:representative_carton]
        all_groups_has_repr_ctn =false

      end
    end



    if !has_fg_carton
      flash[:error] = "You must select a representative carton from the FIRST group"
      render_repack_pallet session[:current_pallet_repack]
      return
    elsif !all_groups_has_repr_ctn
      flash[:error] = "You must select a representative carton from EVERY group"
      render_repack_pallet session[:current_pallet_repack]
      return
    end

    if !session[:current_pallet_repack].fg_carton
      flash[:error] = "You must save the representative carton from the first group"
      render_repack_pallet session[:current_pallet_repack]
      return
    end

    @require_reason = nil
    session[:pallet_repack_info] = set_pallet_repack_info(params[:repack_pallet_info])
    @target_pallet_str = "<font color = \"blue\">(target pallet: existing pallet)</font>"
    @info_panel = build_repack_info(params[:repack_pallet_info], repr_carton)
    if params[:repack_pallet_info][:target_pallet]!= "<use existing pallet>"
      new_pallet = RwActivePallet.find_by_pallet_number(params[:repack_pallet_info][:target_pallet])
      session[:current_pallet_repack].rw_pallet_id = new_pallet.id
      session[:current_pallet_repack].use_new_pallet = true
      @target_pallet_str = "<font color = \"red\">(target pallet: new pallet: " + session[:current_pallet_repack].rw_pallet_id.to_s + ")</font>"

    else
      session[:current_pallet_repack].use_new_pallet = false
    end


    session[:info_panel]= @info_panel


    @content_header_caption = "'Repack summary for pallet: " + session[:current_pallet_repack].pallet.pallet_number.to_s + @target_pallet_str + "'"
    puts @content_header_caption
    render :inline => %{
		 <% if @require_reason
           flash[:error]= "Please provide a reason for overriding the system calculated ratios(amount of cartons per group)"
         end %>
		<%= @info_panel%>

        <%= build_pallet_repack_commit_form(@require_reason)%>
		}, :layout => 'content'

  end


  def build_repack_info(repack_info, repr_carton)

    new_total = 0
    new_total_weight = 0
    ignore_provided_total = true

    overridden_amounts = Hash.new

    repack = session[:current_pallet_repack]
    new_unit_weight = repr_carton.carton_fruit_nett_mass
    panel = "<table><tr><td class = 'old_heading'>groups</td><td class = 'old_heading'>old weight</td><td class = 'old_heading'>old count</td>"
    panel += "<td class = 'new_heading'>new weight</td><td class = 'new_heading'>new count</td></tr>"

    #------------------------------------------------
    #build old-new comparison rows for each run group
    #------------------------------------------------

    #--------------------------------------------------------------------------
    #determine if we should use the user-provided total(if given) or
    #whether user provided individual group totals(in which case we should
    #ignore any given global total. If we can use the given global total ,we
    #need to recalculated the group totals
    #--------------------------------------------------------------------------

    group_override = false
    repack.puc_groups.each do |run_code, group|
      repack_info["txt_" + run_code.gsub(" ", "_")]= "" if repack_info["txt_" + run_code.gsub(" ", "_")].to_i <= 0
      if repack_info["txt_" + run_code.gsub(" ", "_")]!= ""
        group_override = true
        @require_reason= true
        break
      end
    end

    calc_amounts = nil
    repack_info[:total_cartons]= "" if repack_info[:total_cartons].to_i <= 0

    if !group_override && repack_info[:total_cartons]!= ""
      calc_amounts = repack.calc_amounts(repack_info[:total_cartons].to_i, true)
      session[:pallet_repack_info].new_total = repack_info[:total_cartons].to_i
    end

    repack.puc_groups.each do |run_code, group|
      panel += "<tr><td class ='run_code'>" + run_code + "</td>"
      panel += "<td class ='old_val'>" + group[:weight].to_s + "</td>"
      panel += "<td class ='old_val'>" + group[:cartons].length.to_s + "</td>"

      new_count = 0
      new_count_css = ""

      repack_info["txt_" + run_code.gsub(" ", "_")]= "" if repack_info["txt_" + run_code.gsub(" ", "_")].to_i <= 0
      if repack_info["txt_" + run_code.gsub(" ", "_")]!= ""
        new_count = repack_info["txt_" + run_code.gsub(" ", "_")].to_i
        overridden_amounts[run_code]= new_count #to store in repack business object
        new_count_css = "new_val_overridden"
      else
        if calc_amounts
          new_count = calc_amounts[run_code]

        else
          new_count = group[:cartons].length
        end
        new_count_css = "new_val"
      end

      new_weight = new_unit_weight * new_count.round
      puts "new weight: " + new_weight.to_s
      new_total_weight += new_weight
      new_total += new_count

      panel += "<td class ='new_val'>" + new_weight.round.to_s + "</td>"
      panel += "<td class ='" + new_count_css + "'>" + new_count.round.to_s + "</td></tr>"
    end

    session[:pallet_repack_info].new_total = new_total
    panel += "</table><br>"
    #-----------------------
    #build totals comparison
    #-----------------------

    total_css = "new_val"
    total_css = "new_val_overridden" if calc_amounts && repack_info[:total_cartons]!= ""

    new_total_weight = new_total_weight.round
    new_total = new_total.round

    panel += "<table><tr><td class = 'old_heading'>Category</td><td class = 'old_heading'>old totals</td><td class = 'new_heading'>new totals</td></tr>"
    panel += "<tr><td class = 'neutral_heading'>weight</td><td class = 'old_val'>" + repack.total_weight.to_s + "</td>"
    panel += "<td class = 'new_val'>" + new_total_weight.to_s + "</td>"
    panel += "<tr><td class = 'neutral_heading'>carton count</td><td class = 'old_val'>" + repack.total_count.to_s + "</td>"
    panel += "<td class = '" + total_css + "'>" + new_total.to_s + "</td></tr></table><br>"

    panel += "<table><tr><td class = 'old_heading'>FG Product Code </td><td class = 'new_heading'>" + repr_carton.fg_product_code + "</td></tr>"
    panel += "<tr><td class = 'run_code'>Items Per Unit</td><td class = 'new_val'>" + repr_carton.items_per_unit.to_s + "</td></tr>"
    panel += "<tr><td class = 'run_code'>Units Per Carton</td><td class = 'new_val'>" + repr_carton.units_per_carton.to_s + "</td></tr>"
    panel += "<tr><td class = 'run_code'>Carton Fruit Nett Mass</td><td class = 'new_val'>" + repr_carton.carton_fruit_nett_mass.to_s + "</td></tr>"
    panel += "</table>"

    session[:pallet_repack_info].overridden_amounts = overridden_amounts
    return panel

  end


  def render_repack_pallet(pallet_repack = nil)

    @info = "<font color = 'green'><li>Use the selected carton of the first group to define FG (and weigh)related field values for the entire pallet </li>"
    @info += "<font color = 'green'><li>If you specify override values for carton counts for individual groups, the system will ignore an override value for total count(if you specified a value) </li>"
    @info += "<font color = 'green'><li>If you want all cartons on the pallet to be exact copies, select and edit a carton from the first group only</li>"

    @pallet_repack = pallet_repack
    @pallet_repack = session[:current_pallet_repack] if !pallet_repack

    add_repack_info_fields(session[:current_pallet_repack])
    @repack_pallet_info = nil
    @repack_pallet_info = session[:pallet_repack_info] if session[:pallet_repack_info]

    @repack_pallet_info = RwRepackInfo.new if !@repack_pallet_info


    pallet = @pallet_repack.pallet
    @content_header_caption = "'Manage alternate packing for pallet: " + pallet.pallet_number.to_s + "'"

    render :inline => %{

		<%= build_repack_pallet_form(@pallet_repack,@repack_pallet_info)%>

		}, :layout => 'content'


  end


  def set_carton_label_printer

    if !session[:current_rw_run]
      redirect_to_index("You must first set an active reworks run")
      return
    end

    @content_header_caption = "'Select a printer for carton labeling'"

    render :inline => %{
		<%= build_printer_selection_form()%>

		}, :layout => 'content'

  end

  def set_carton_label_printer_submit
    printer_name = params['printer']['printer_name']
    printer = CartonLabelStation.find_by_carton_label_station_code(printer_name)
    ip = printer.ip_address
    puts ip
    session[:current_rw_run].carton_printing_ip = ip
    session[:current_rw_run].update
    @freeze_flash = true
    redirect_to_index("printer set to: " + printer_name + "   (IP is: " + ip +")")

  end


  def complete_run

    return if authorise_for_web(program_name?, 'rw_physical') == false
    begin

      if !session[:current_rw_run]
        @freeze_flash = true
        redirect_to_index("You do not have a current editing run")
        return
      end

      #-------------------------------------------------------------------------------
      #If any active carton does not have a pallet_id, inform user and confirm whether
      #run must still be completed
      #-------------------------------------------------------------------------------
      err_msg = ""
      session[:current_rw_run].rw_active_cartons.each do |ctn|

        if !ctn.rw_active_pallet_id
          err_msg += ctn.carton_number.to_s + "<BR>"
        end

        #   render :inline => %{
        #   <script>
        #     if (confirm("Some cartons have no pallet ids. This could mean that you have not completed your build-up process\\n Are you sure you want to complete the run? ") == true)
        #          {window.location.href = "/production/reworks/complete_run_confirmed";}
        #     else
        #          {window.location.href = "/production/reworks/complete_run_cancelled";}
        #   </script>
        #   }
        #   return
        # end
      end

      if err_msg != ""
        err_msg = "Some cartons have no pallet ids. This could mean that you have not completed your build-up process. These cartons are: <BR>" + err_msg
        flash[:error] = err_msg
        rw_pallets
        return

      end


      #session[:current_rw_run].complete

      #session[:current_rw_run] = nil
      confirm_complete_run


    rescue

      handle_error("reworks run could not be completed")
    end

  end

  def confirm_complete_run


    run = RwRun.find(session[:current_rw_run].id)
    @run_progress = ReworksProgressManager.new(run, true)
    if @run_progress.no_required_actions?
      redirect_to_index("You have not done anything in this run")
      return
    end
    @content_header_caption = "'stats for run: " + run.rw_run_name + "'"

    @is_active_page = true
    @is_confirm_page = true
    render :template => "production/reworks/rw_complete_progress", :layout => "content"

  end

  def fork_complete_run
    if false #RUBY_PLATFORM.index('linux')
      rw_run_id = session[:current_rw_run].id.to_s
      child = fork do
        file_name = "fork_" + rw_run_id + "_rw_complete_run.sh"
        file = File.new(file_name, "w")
        file.puts "ruby  complete_rw_run.rb" + " " + rw_run_id
        file.close
        system "sh " + file_name

      end

      Process.detach(child) #getting rid of zombies

      render :inline => %{

      }, :layout => 'content'
    else #fork method(independent children) not supported on windows
      session[:current_rw_run].complete
      redirect_to_index('run completed successfully')
      return
    end

  end


  def complete_run_confirmed
    begin
      confirm_complete_run
    rescue
      handle_error("run could not be completed")
    end
  end

  def complete_run_cancelled
    begin

      redirect_to_index("Run NOT completed.")
    rescue

      handle_error("run could not be completed")
    end
  end

  def batch_printing_cancelled
  print_pallet
  end

  def carton_printing_cancelled
    flash[:notice]="printing cancelled"
    list_pallet_cartons
  end



  def print_group

    @group = params[:id].to_s

    run_code = @group.split("__")[0]
    farm_code = @group.split("__")[1]
    puc = @group.split("__")[2]



    pallet = session[:current_pallet_print].pallet
    @pallet_id =pallet.id
    n_labels_printed= ActiveRecord::Base.connection.select_one("select count(*) as n_labels_printed from rw_active_cartons where (production_run_code='#{run_code}' and farm_code = '#{farm_code}' and puc = '#{puc}' and pallet_id =#{pallet.pallet_id}  and (n_labels_printed IS NOT NULL OR  n_labels_printed > 1))")['n_labels_printed'].to_i

    if n_labels_printed.to_i >= 1
       @msg = "#{n_labels_printed.to_s}" +" " +  "carton labels have been printed for this pallet are you sure you want to reprint them?"
       render :inline => %{
       <script>
         if (confirm("<%=@msg%>") == true)
            {window.location.href = '/production/reworks/reprint_group/<%=@group%>';}
         else
           {window.location.href = '/production/reworks/batch_printing_cancelled/<%=@pallet_id%>';}
      </script>
        }
    else
      reprint_group
    end



  end

def reprint_group

    group = params[:id].to_s
    pallet = session[:current_pallet_print].pallet

    begin

      if !RUBY_PLATFORM.index('linux')
        file_name = session[:user_id].user_name + "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".bat"
        file = File.new(file_name, "w")
        file.puts "ruby \"app\\models\\carton_label_printing.rb\"" + " BATCH \"" + group + "\" " + pallet.id.to_s + " " +  session[:user_id].user_name
        file.close

        result = eval "\`" + "\"" + file_name + "\"" + "\"`"
      else
        file_name = session[:user_id].user_name + "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".sh"
        file = File.new(file_name, "w")
        file.puts "ruby \"app/models/carton_label_printing.rb\"" + " BATCH \"" + group + "\" " + pallet.id.to_s + " " +  session[:user_id].user_name
        file.close

        result = eval "\` sh " + file_name + "\`"
      end

      if result.index("error")
        raise result
      end
      puts "print result: " + result
      #File.delete file_name



      session[:alert] = "carton labels successfully reprinted!"
      session[:last_printed_group]  = group
      redirect_to :action => "print_pallet", :controller => "production/reworks" ,:id=>session[:print_pallet]


    rescue
      handle_error("Label could not be printed")
    end

end

  def render_print_pallet(pallet_print = nil)

    @pallet_print = pallet_print
    @pallet_print = session[:current_pallet_print] if !pallet_print


    pallet = @pallet_print.pallet
    @content_header_caption = "'Batch print carton labels for pallet: " + pallet.pallet_number.to_s + "'"

    render :inline => %{

		<%= build_print_pallet_form(@pallet_update)%>

		}, :layout => 'content'

  end


  def render_reclassify_pallet(pallet_update = nil)

    @pallet_update = pallet_update
    @pallet_update = session[:current_pallet_update] if !pallet_update


    pallet = @pallet_update.pallet
    @content_header_caption = "'Batch update pallet cartons for pallet: " + pallet.pallet_number.to_s + "'"

    render :inline => %{

		<%= build_batch_update_pallet_form(@pallet_update)%>

		}, :layout => 'content'


  end


  def new_pallet_submit

    carton_nr = params['carton']['carton_number'].to_i

    if carton_nr == 0
      @freeze_flash = true
      flash[:error]= "no number entered"
      new_pallet
      return
    end

    carton = RwActiveCarton.find_by_carton_number(carton_nr)
    if !carton
      @freeze_flash = true
      flash[:error]= "An active carton with number: " + carton_nr.to_s + " could not be found"
      new_pallet
      return
    end

    pallet = carton.create_pallet params[:carton][:pallet_format_product_code]
    @freeze_flash = true
    redirect_to_index("New pallet: " + pallet.pallet_number.to_s + " created successfully")
    return

  end

  #----------------
  #RECEIVED CARTONS
  #----------------

  def receive_carton_submit

    carton_nr = params['received_item']['carton_number'].to_i

    if carton_nr == 0
      @freeze_flash = true
      flash[:error]= "no number entered"
      receive_carton
      return
    end

    carton_nr = carton_nr.remove_right(1, 12)

    carton = Carton.find_by_carton_number(carton_nr)
    if !carton
      @freeze_flash = true
      flash[:error]= "A carton with number: " + carton_nr.to_s + " could not be found"
      receive_carton

      return
    end


    if carton.exit_reference && carton.exit_reference.upcase == "SCRAPPED"
      @freeze_flash = true
      flash[:error]= " This carton, with number: " + carton_nr.to_s + " has been scrapped"
      receive_carton

      return
    end

    #received in this run
    received_carton = RwReceiptCarton.find_by_carton_number_and_rw_run_id(carton_nr, session[:current_rw_run].id)
    if received_carton
      @freeze_flash = true
      flash[:error]= "A carton with number: " + carton_nr.to_s + " has already been received in this run"
      receive_carton
      return
    end

    #received in other editing run
    if err = session[:current_rw_run].carton_active_in_other_reworks_run?(carton_nr)
      @freeze_flash = true
      flash[:error]= err
      receive_carton
      return
    end

     if !carton.pallet
      @freeze_flash = true
      flash[:error]= "Carton does not belong to a pallet"
      receive_carton
      return

      end


    if carton.pallet.exit_ref
      @freeze_flash = true
      flash[:error]= "Carton's pallet has an exit ref (" + carton.pallet.exit_ref + ")"
      receive_carton
      return

    end


    if carton.pallet.process_status.upcase.gsub("S","Z").index("PALLETIZING")
      @freeze_flash = true
      flash[:error]= "Carton's pallet(#{carton.pallet_number}) is still on a palleizing bay"
      receive_carton
      return

    end


    RwReceiptCarton.receive_carton(carton, session[:current_rw_run], nil, true)
    @freeze_flash = true
    flash[:notice]= "carton: " + carton_nr.to_s + " received successfully"
    receive_carton
    return


  end


  def list_pallet_cartons(pallet = nil)
    @can_control_run = authorise(program_name?, 'rw_physical', session[:user_id])
    if pallet == nil
      session[:active_pallet]= RwActivePallet.find(params[:id].to_i) if params[:id]
    end

    @pallet_cartons = session[:active_pallet].rw_active_cartons


    if @pallet_cartons.length == 0
      @freeze_flash = true
      session[:current_carton_list] = nil
      session[:current_carton_list_caption] = nil
      redirect_to_index("Pallet has no cartons")
      return
    end


    @content_header_caption = "' cartons for pallet " + session[:active_pallet].pallet_number.to_s + "'"

    session[:current_carton_list] = @pallet_cartons
    session[:current_carton_list_caption]= @content_header_caption
    session[:carton_list_has_pallet] = true

    render :inline => %{
      <% grid            = build_rw_cartons_grid(@pallet_cartons,true) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end


  def rw_bins

    @can_control_run = authorise(program_name?, 'rw_physical', session[:user_id])
    @bulk_bin_update_permission = authorise(program_name?, 'rw_bulk_bin_edit', session[:user_id])

    if !session[:current_rw_run]
      @freeze_flash = true
      redirect_to_index("You have not yet created or selected an active(editing) reworks run")
      return
    end

    #@active_bins = RwActiveBin.find_all_by_rw_run_id(session[:current_rw_run].id)
    @active_bins = RwActiveBin.find_by_sql("select transaction_statuses.status_code,
                    rw_active_bins.coldstore_type as cold_store_type_code,locations.location_code as sealed_ca_location_code,stock_items.location_code,stock_items.stock_type_code,
                    rmt_products.product_class_code,rmt_products.ripe_point_code,rmt_products.size_code,
                    rw_active_bins.*,pack_material_products.pack_material_product_code,rmt_products.rmt_product_code,farms.farm_code,
                    rw_active_bins.rebin_track_indicator_code,rw_active_bins.season_code,
                    track_slms1.track_slms_indicator_code as indicator_code1,
                    track_slms2.track_slms_indicator_code as indicator_code2,
                    track_slms3.track_slms_indicator_code as indicator_code3,
                    track_slms4.track_slms_indicator_code as indicator_code4,
                    track_slms5.track_slms_indicator_code as indicator_code5,
                    rw_active_bins.bin_receive_date_time,
                    rw_active_bins.bin_id,rw_active_bins.exit_ref,deliveries.delivery_number,rw_active_bins.tipped_date_time, rw_active_bins.bin_number,
                    rw_active_bins.is_half_bin,rw_active_bins.is_sample_bin,
                    rw_active_bins.rebin_status,rw_active_bins.rebin_date_time,rw_active_bins.user_name,rw_active_bins.print_number,
                    rw_active_bins.exit_reference_date_time,
                    rw_active_bins.rw_run_id ,
                    production_rebin_runs.production_run_code as production_run_rebin,
                    production_tipped_runs.production_run_code as production_run_tipped
                    from
                    rw_active_bins
                    LEFT  JOIN track_slms_indicators track_slms1 ON rw_active_bins.track_indicator1_id = track_slms1.id
                    LEFT  JOIN track_slms_indicators track_slms2 ON rw_active_bins.track_indicator2_id = track_slms2.id
                    LEFT  JOIN track_slms_indicators track_slms3 ON rw_active_bins.track_indicator3_id = track_slms3.id
                    LEFT  JOIN track_slms_indicators track_slms4 ON rw_active_bins.track_indicator4_id = track_slms4.id
                    LEFT  JOIN track_slms_indicators track_slms5 ON rw_active_bins.track_indicator5_id = track_slms5.id
                    LEFT  JOIN deliveries ON rw_active_bins.delivery_id = deliveries.id
                    LEFT  JOIN  rmt_products ON rw_active_bins.rmt_product_id = rmt_products.id
                    LEFT  JOIN farms ON rw_active_bins.farm_id = farms.id
                    LEFT  JOIN pack_material_products ON rw_active_bins.pack_material_product_id = pack_material_products.id
                    LEFT  JOIN production_runs production_rebin_runs ON rw_active_bins.production_run_rebin_id = production_rebin_runs.id
                    LEFT  JOIN production_runs production_tipped_runs ON rw_active_bins.production_run_tipped_id = production_tipped_runs.id
                    LEFT JOIN stock_items ON rw_active_bins.bin_number=stock_items.inventory_reference
                    LEFT JOIN locations ON rw_active_bins.sealed_ca_location_id=locations.id
                    LEFT JOIN ripe_points ON  rmt_products.ripe_point_id=ripe_points.id
                    LEFT JOIN transaction_statuses ON rw_active_bins.bin_id=transaction_statuses.object_id
                    WHERE
                    rw_active_bins.rw_run_id =#{session[:current_rw_run].id}")

    session[:current_bin_list] = @active_bins

    if @active_bins.length == 0
      @freeze_flash = true
      redirect_to_index("No bins were received yet")
      return
    end

    render :inline => %{
      <% grid            = build_rw_bins_grid(@active_bins,nil,nil) %>
      <% grid.caption    = 'bins in reworks' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end


  def rw_pallets

    @can_control_run = authorise(program_name?, 'rw_physical', session[:user_id])
    @bulk_pallet_update_permission = authorise(program_name?, 'rw_bulk_pallet_edit', session[:user_id])
    @can_do_buildup = authorise(program_name?, 'rw_buildup', session[:user_id])


    @bulk_pallet_update_permission_ltd = nil
    @bulk_pallet_update_permission_ltd = authorise(program_name?, 'rw_bulk_pallet_edit_ltd', session[:user_id]) if !@bulk_pallet_update_permission


    if !session[:current_rw_run]
      @freeze_flash = true
      redirect_to_index("You have not yet created or selected an active(editing) reworks run")
      return
    end

    @active_pallets = RwActivePallet.find_all_by_rw_run_id(session[:current_rw_run].id, :include => [:production_run])
    session[:current_pallet_list] = @active_pallets

    if @active_pallets.length == 0
      @freeze_flash = true
      redirect_to_index("No pallets were received yet")
      return
    end

    @can_do_buildup = @active_pallets.length <= 10 if @can_do_buildup

    render :inline => %{
      <% grid            = build_rw_pallets_grid(@active_pallets) %>
      <% grid.caption    = 'pallets in reworks' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end


  def add_carton_to_pallet

    pallet = RwActivePallet.find(params[:id].to_i) if params[:id]

    session[:building_pallet]= pallet if pallet

    pallet = session[:building_pallet] if !pallet

    @count = pallet.rw_active_cartons.length.to_s

    @content_header_caption = "'Add cartons to pallet: " + pallet.pallet_number.to_s + "'"

    render :inline => %{
		<%= build_add_carton_form(@count)%>

		}, :layout => 'content'
  end

  def remove_cartons

    pallet = RwActivePallet.find(params[:id].to_i) if params[:id]

    session[:building_pallet]= pallet if pallet

    pallet = session[:building_pallet] if !pallet

    @count = pallet.rw_active_cartons.length.to_s

    @content_header_caption = "'Remove carton from pallet: " + pallet.pallet_number.to_s + "'"

    render :inline => %{
		<%= build_remove_carton_form(@count)%>

		}, :layout => 'content'
  end




  def carton_added

    #validation
    if params[:carton][:carton_number].strip.to_i <= 0
      flash[:error] = "Please scan or enter a valid carton number"
      add_carton_to_pallet
      return
    end

    num = params[:carton][:carton_number].strip.to_i

    num = num.remove_right(1, 12)

    pallet = session[:building_pallet]
    carton = RwActiveCarton.find_by_carton_number_and_rw_run_id(num, pallet.rw_run_id)

    if !carton
      flash[:error] = "There is no active reworks carton with number: " + num.to_s
      add_carton_to_pallet
      return
    end

    if carton.rw_active_pallet_id && carton.rw_active_pallet_id == pallet.id
      flash[:error] = "Carton with number: " + num.to_s + " already belongs to pallet!"
      add_carton_to_pallet
      return
    end

    if carton.pallet_number
      source_pallet = RwActivePallet.find_by_pallet_number(carton.pallet_number)
      if !source_pallet
        flash[:error] = "You can only move cartons from pallet received in reworks<BR>. Pallet: " + carton.pallet_number.to_s + " is not in reworks"
        add_carton_to_pallet
        return
      end
    end

    oldest_carton_sell_by_code = carton.is_valid_carton_sell_by_code?(carton,pallet)

    if oldest_carton_sell_by_code
      flash[:error] = "Carton cannot be added,its sell by date: (#{carton.sell_by_code}) is different from the oldest pallet's carton sell by date (#{oldest_carton_sell_by_code})"
      add_carton_to_pallet
      return
    end

    carton.transaction do
      pallet.carton_quantity_actual += 1
      if pallet.build_up_balance
        pallet.build_up_balance += 1
      else
        pallet.build_up_balance = 1
      end

      if  source_pallet
        source_pallet.carton_quantity_actual -= 1
        if source_pallet.build_up_balance
          source_pallet.build_up_balance -= 1
        else
          source_pallet.build_up_balance = -1
        end

        source_pallet.rw_run.set_build_status(source_pallet)
        source_pallet.update
      end
      pallet.rw_run.set_build_status(pallet)

      carton.rw_pallet_action = "Added"
      carton.rw_receipt_unit = "pallet"
      carton.pallet_number = pallet.pallet_number
      carton.pallet_id = pallet.pallet.id if pallet.reworks_action.upcase != "NEW PALLET" && pallet.pallet
      pallet.update

      carton.update
      pallet.rw_active_cartons.push carton
    end

    flash[:notice]= "carton: " + num.to_s + " added"
    add_carton_to_pallet

  end

  def carton_removed

    #validation
    if params[:carton][:carton_number].strip.to_i <= 0
      flash[:error] = "Please scan or enter a valid carton number"
      remove_cartons
      return
    end

    num = params[:carton][:carton_number].strip.to_i

    num = num.remove_right(1, 12)

    pallet = session[:building_pallet]
    carton = RwActiveCarton.find_by_carton_number_and_rw_run_id(num, pallet.rw_run_id)

    if !carton
      flash[:error] = "There is no active reworks carton with number: " + num.to_s
      remove_cartons
      return
    end

    if carton.rw_active_pallet_id && carton.rw_active_pallet_id != pallet.id
      flash[:error] = "Carton with number: " + num.to_s + " does not belong to current pallet!"
      remove_cartons
      return
    end

    carton.transaction do

      carton.rw_active_pallet.carton_quantity_actual -= 1
      if  carton.rw_active_pallet.build_up_balance
        carton.rw_active_pallet.build_up_balance -= 1
      else
        carton.rw_active_pallet.build_up_balance = -1
      end

      carton.rw_active_pallet.rw_run.set_build_status(pallet)
      carton.rw_active_pallet.update
      carton.rw_active_pallet_id = nil
      carton.pallet_number = nil
      carton.pallet_id = nil
      carton.rw_receipt_unit = "carton"
      carton.rw_pallet_action = "removed"
      carton.update
    end

    flash[:notice] = "carton removed"

    remove_cartons

  end


  def scrap_pallet_cartons

    if !params[:item]
      session[:pallet_to_scrap_ctns] = RwActivePallet.find(params[:id].to_i)

      if  session[:pallet_to_scrap_ctns].load_detail_id
        flash[:error] = "This pallet is on a load"
        rw_pallets
        return
      end


   stock_item = StockItem.find_by_inventory_reference(session[:pallet_to_scrap_ctns].pallet_number)
    if stock_item && !(stock_item.location_code.upcase == "PACKHSE" ||stock_item.location_code.upcase == "REWORKS"||stock_item.location_code.upcase == "BAGGING"||stock_item.location_code.upcase == "BAGGING_REWORKS"||stock_item.location_code.upcase == "PART_PALLETS")
      flash[:error] = "Pallet is at location: " + stock_item.location_code + ". Only pallets in REWORKS or PACKHSE can be scrapped"
      rw_pallets
      return
    end


      @content_header_caption = "'Please provide a reason for scrapping cartons of pallet: " + session[:pallet_to_scrap_ctns].pallet_number.to_s + "'"
      render :inline =>
                 %{

		<%= build_scrap_reason_form('scrap_pallet_cartons')%>

      }, :layout => 'content'
      return

    else

      reason = RwReason.find_by_rw_reason_description(params[:item][:reason])

      pallet = session[:pallet_to_scrap_ctns]

      pallet.scrap_cartons(reason, session[:user_id])

      flash[:notice] = "Cartons of Pallet: " + pallet.pallet_number.to_s + " scrapped."
      session[:pallet_to_scrap_ctns] = nil
      rw_pallets

    end

  end


  def scrap_carton


    if !params[:item]
      session[:carton_to_scrap] = RwActiveCarton.find(params[:id].to_i)

      if session[:carton_to_scrap].reworks_action.upcase == "ALT_PACKED"
        flash[:error] = "You can only scrap received cartons. This carton was created from alternative packing"
        render_cartons
        return
      end

      if session[:carton_to_scrap].rw_active_pallet
        flash[:error] = "You cannot scrap a carton that still belongs to a pallet. Use the 'remove_carton' action to <br> first dereference the carton from the pallet and then scrap the carton"
        render_cartons
        return
      end


    stock_item = StockItem.find_by_inventory_reference(session[:carton_to_scrap].rw_receipt_carton.pallet_number)
     if stock_item && !(stock_item.location_code.upcase == "PACKHSE" ||stock_item.location_code.upcase == "REWORKS"||stock_item.location_code.upcase == "BAGGING"||stock_item.location_code.upcase == "BAGGING_REWORKS"||stock_item.location_code.upcase == "PART_PALLETS")
      flash[:error] = "Carton is at location: " + stock_item.location_code + ". Only cartons in REWORKS or PACKHSE can be scrapped"
      render_cartons
      return
     end


      @content_header_caption = "'Please provide a reason for scrapping carton: " + session[:carton_to_scrap].carton_number.to_s + "'"
      render :inline =>
                 %{

		<%= build_scrap_reason_form('scrap_carton')%>

      }, :layout => 'content'
      return

    else

      reason = RwReason.find_by_rw_reason_description(params[:item][:reason])

      carton = session[:carton_to_scrap]

      carton.scrap(reason, session[:user_id])

      flash[:notice] = "Carton: " + carton.carton_number.to_s + " scrapped."
      render_cartons nil, nil, carton

    end


  end


  def scrap_pallet

    if !params[:item]
      session[:pallet_to_scrap] = RwActivePallet.find(params[:id].to_i)

      if session[:pallet_to_scrap].load_detail_id
        flash[:error] = "This pallet is on a load"
        rw_pallets  and return
      end

      stock_item = StockItem.find_by_inventory_reference(session[:pallet_to_scrap].pallet_number)
      if stock_item && !(stock_item.location_code.upcase == "PACKHSE" ||stock_item.location_code.upcase == "REWORKS")
        flash[:error] = "Pallet is at location: " + stock_item.location_code + ". Only pallets in REWORKS or PACKHSE can be scrapped"
        rw_pallets
        return
      end

      @content_header_caption = "'Please provide a reason for scrapping pallet: " + session[:pallet_to_scrap].pallet_number.to_s + "'"
      render :inline =>
                 %{

		<%= build_scrap_reason_form('scrap_pallet')%>

      }, :layout => 'content'
      return

    else

      reason = RwReason.find_by_rw_reason_description(params[:item][:reason])

      pallet = session[:pallet_to_scrap]

      pallet.scrap(reason, session[:user_id])

      flash[:notice] = "Pallet: " + pallet.pallet_number.to_s + " scrapped."
      session[:pallet_to_scrap] = nil
      rw_pallets

    end


  end




  def remove_carton

    carton = RwActiveCarton.find(params[:id].to_i)
    carton.transaction do

      carton.rw_active_pallet.carton_quantity_actual -= 1
      if  carton.rw_active_pallet.build_up_balance
        carton.rw_active_pallet.build_up_balance -= 1
      else
        carton.rw_active_pallet.build_up_balance = -1

      end
      carton.rw_active_pallet.rw_run.set_build_status(carton.rw_active_pallet)
      carton.rw_active_pallet.update
      carton.rw_active_pallet_id = nil
      carton.pallet_number = nil
      carton.pallet_id = nil
      carton.rw_receipt_unit = "carton"
      carton.rw_pallet_action = "removed"
      carton.update
    end

    flash[:notice] = "carton removed"
    params[:id]= nil #so that list pallet cartons do not think a pallet id is coming through
    list_pallet_cartons


  end


  def rw_cartons

    @can_control_run = authorise(program_name?, 'rw_physical', session[:user_id])
    @bulk_carton_update_permission = authorise(program_name?, 'rw_bulk_carton_edit', session[:user_id])

    if !session[:current_rw_run]
      @freeze_flash = true
      redirect_to_index("You do not have a current editing run")
      return
    end

    @cartons = RwActiveCarton.find_all_by_rw_run_id_and_rw_receipt_unit(session[:current_rw_run].id, "carton")
    session[:query]= "RwActiveCarton.find_all_by_rw_run_id_and_rw_receipt_unit(session[:current_rw_run].id,'carton')"

    if @cartons.length == 0
      @freeze_flash = true
      session[:current_carton_list] = nil
      redirect_to_index("There are no active cartons")
      return
    end

    session[:current_carton_list]= @cartons
    content_header_caption = "'active cartons'"
    session[:current_carton_list_caption]= content_header_caption
    session[:carton_list_has_pallet] = false
    render_cartons(content_header_caption, @cartons)


  end

  def render_cartons(caption = nil, cartons = nil, carton_to_remove = nil, carton_to_update = nil)

    @can_control_run = authorise(program_name?, 'rw_physical', session[:user_id])

    @caption = caption
    @cartons = cartons

    @cartons = session[:current_carton_list] if !@cartons
    @caption = session[:current_carton_list_caption] if !caption

    if carton_to_remove
      @cartons.delete carton_to_remove
      session[:current_carton_list] = @cartons if @cartons
    end

    if carton_to_update
      @cartons.each do |carton|
        if carton.id == carton_to_update.id
          carton_to_update.export_attributes(carton, true)
          break
        end
      end

      session[:current_carton_list] = @cartons if @cartons
    end


    render :inline => %{
      <% grid            = build_rw_cartons_grid(@cartons, session[:carton_list_has_pallet]) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end


  def reclassify_carton_submit
    begin
      session[:current_editing_carton].transaction do

        session[:current_editing_carton].update_attributes(params[:carton_edit])
        msg = session[:current_editing_carton].derive_fields
        if msg != ""
          flash[:error]= msg
          reclassify_carton(session[:current_editing_carton])
          return
        end

        session[:current_editing_carton].reworks_action = "reclassified" if session[:current_editing_carton].reworks_action != "alt_packed"
        session[:current_editing_carton].update
      end
      flash[:notice]= "carton saved"
      render_cartons nil, nil, nil, session[:current_editing_carton]
    rescue
      handle_error("carton could not be reclassified")
    end
  end

  def reclassify_carton(carton = nil)
    return if authorise(program_name?, 'rw_physical', session[:user_id])== false

    if !carton
      @carton_edit = RwActiveCarton.find(params[:id].to_i)
    else
      @carton_edit = carton
    end

    session[:current_editing_carton]= @carton_edit
    @is_reclassification = true
    render :inline => %{
		<% @content_header_caption = "'reclassify carton'"%>

		<%= build_edit_carton_form(@carton_edit,'reclassify_carton_submit','save')%>

		}, :layout => 'content'


  end

  def repack_carton(carton = nil)

    return if authorise(program_name?, 'rw_physical', session[:user_id])== false

    if !carton
      @carton_edit = RwActiveCarton.find(params[:id].to_i)
    else
      @carton_edit = carton
    end

    session[:current_editing_carton]= @carton_edit

    render :inline => %{
		<% @content_header_caption = "'repack carton'"%>

		<%= build_edit_carton_form(@carton_edit,'repack_carton_submit','save')%>

		}, :layout => 'content'


  end

  def repack_carton_submit

    session[:current_editing_carton].transaction do
      session[:current_editing_carton].update_attributes(params[:carton_edit])
      msg = session[:current_editing_carton].derive_fields
      if msg != ""
        flash[:error]= msg
        repack_carton(session[:current_editing_carton])
        return
      end

      new_sequence = MesControlFile.next_seq(1)
      session[:current_editing_carton].carton_number = new_sequence
      session[:current_editing_carton].reworks_action = "alt_packed_from_carton"
      session[:current_editing_carton].update
      #update the alt_packeddatetime on receipt carton and reworks action to carton_alt_packed
      receipt_carton = session[:current_editing_carton].rw_receipt_carton
      receipt_carton.alt_packed_datetime = Time.now
      receipt_carton.reworks_action = "alt_packed_from_carton"
      receipt_carton.update
    end
    flash[:notice]= "Alternate packing done successfully"
    render_cartons nil, nil, nil, session[:current_editing_carton]

  end


  def set_pallet_repack_info(repack_params)
    add_repack_info_fields(session[:current_pallet_repack])
    repack_info = RwRepackInfo.new

    repack_params.keys.each do |key|
      eval "repack_info." + key + "= '" + repack_params[key] + "'"
    end
    return repack_info
  end

  def items_per_unit_changed
    puts "wel wel"

  end

  #----------------
  #RECEIVED PALLETS
  #----------------


  def receive_single_pallet_submit

    pallet_nr = params['received_item']['pallet_number']

    if pallet_nr == 0
      @freeze_flash = true
      flash[:error]= "no number entered"
      receive_pallet
      return
    end

    pallet_nr = pallet_nr.remove_right(1, 18)

    pallet = Pallet.find_by_pallet_number(pallet_nr)
    if !pallet
      @freeze_flash = true
      flash[:error]= "A pallet with number: " + pallet_nr.to_s + " could not be found"
      receive_pallet
      return
    end

    #received in this run
    received_pallet = RwReceiptPallet.find_by_pallet_number_and_rw_run_id(pallet_nr, session[:current_rw_run].id)
    if received_pallet
      @freeze_flash = true
      flash[:error]= "A pallet with number: " + pallet_nr.to_s + " has already been received in this run"
      receive_pallet
      return
    end

    #received in other editing run
    if err = session[:current_rw_run].pallet_active_in_other_run?(pallet_nr)
      @freeze_flash = true
      flash[:error]= err
      receive_pallet
      return
    end

    if pallet.exit_ref
      @freeze_flash = true
      flash[:error]= " This pallet, with number: " + pallet_nr.to_s + " has an exit ref(" + pallet.exit_ref + ")"
      receive_pallet

      return
    end


    stats = RwReceiptPallet.receive_pallet(pallet, session[:current_rw_run])
    copied_cartons = stats[0].to_s
    already_received_cartons = stats[1].to_s
    @freeze_flash = true
    flash[:notice]= "pallet: " + pallet_nr.to_s + " received successfully- with it's cartons"
    flash[:notice] += "<br><font color = 'blue'> Cartons received: " + copied_cartons + "</font>"
    flash[:notice] += "<br><font color = 'red'>  " + already_received_cartons + " carton(s) were not received, because they were received previously</font>" if stats[1] > 0
    receive_pallet
    return


  end

  def invalid_pallets(pallet_nums)
    failed_pallets=[]
    pallet_nums.each do |pallet_number|
              pallet_nr = pallet_number
              if pallet_nr == 0
              failed_pallets.push(pallet_number + " is not a valid number")
              end

              pallet_nr = pallet_nr.remove_right(1, 18)
              pallet = Pallet.find_by_pallet_number(pallet_nr)
              if !pallet
                failed_pallets.push("A pallet with number: " + pallet_nr.to_s + " could not be found")
              end
              received_pallet = RwReceiptPallet.find_by_pallet_number_and_rw_run_id(pallet_nr, session[:current_rw_run].id)
              if received_pallet
                failed_pallets.push("A pallet with number: " + pallet_nr.to_s + " has already been received in this run")
              end

              #received in other editing run
              if err = session[:current_rw_run].pallet_active_in_other_run?(pallet_nr)
                failed_pallets.push(err)
              end

              if pallet.exit_ref
                failed_pallets.push(" This pallet, with number: " + pallet_nr.to_s + " has an exit ref(" + pallet.exit_ref + ")")
              end

               if pallet.process_status && pallet.process_status.upcase().index("PALLETIZING")
                 failed_pallets.push(" This pallet, with number: " + pallet_nr.to_s + " is on a palletizing bay")
               end

              intake_headers_production_id=Pallet.find_by_sql("select intake_headers_production_id from pallets where pallet_number='#{pallet_number}'").intake_headers_production_id
              if intake_headers_production_id
                failed_pallets.push(" This pallet, with number: " + pallet_nr.to_s + " is on an intake consignment")
              end

              end
  end

  def receive_pallet_submit

    pallet_nrs = params['received_item']['pallet_number'].split("\n")
    flash[:notice]= "PALLETS RECEIVED SUMMARY:<br>"
    begin
      if pallet_nrs.length == 0
        @freeze_flash = true
        flash[:error]= "no number entered"
        receive_pallet
        return
      end

      #failed_pallets= invalid_pallets(pallet_nrs)
      #if failed_pallets.length > 0
      #  flash[:error]= "The following pallets cannot be imported. Reasons are in brackets: <BR> #{failed_pallets.join("<BR>")}"
      #  return
      #end

      Pallet.transaction do
        pallet_nrs.each do |pallet_number|
          pallet_nr = pallet_number
          if pallet_nr == 0
            @freeze_flash = true
            flash[:error]= pallet_number + " is not a valid number"
            raise flash[:error]
            return
          end

          pallet_nr = pallet_nr.remove_right(1, 18).strip

          pallet = Pallet.find_by_pallet_number(pallet_nr)
          if !pallet
            @freeze_flash = true
            flash[:error]= "A pallet with number: " + pallet_nr.to_s + " could not be found"
            raise flash[:error]
            return
          end


          received_pallet = RwReceiptPallet.find_by_pallet_number_and_rw_run_id(pallet_nr, session[:current_rw_run].id)
          if received_pallet
            @freeze_flash = true
            flash[:error]= "A pallet with number: " + pallet_nr.to_s + " has already been received in this run"
            raise flash[:error]

          end

          #received in other editing run
          if err = session[:current_rw_run].pallet_active_in_other_run?(pallet_nr)
            @freeze_flash = true
            flash[:error]= err
            raise flash[:error]

          end

          if pallet.exit_ref
            @freeze_flash = true
            flash[:error]= " This pallet, with number: " + pallet_nr.to_s + " has an exit ref(" + pallet.exit_ref + ")"
            raise flash[:error]

          end

          if pallet.process_status && pallet.process_status.upcase().index("PALLETIZING")
            @freeze_flash = true
            flash[:error]= " This pallet, with number: " + pallet_nr.to_s + " is on a palletizing bay"
            raise flash[:error]
          end
          intake_headers_production_id=ActiveRecord::Base.connection.select_one("select intake_headers_production_id from pallets where pallet_number in ('#{pallet_number.strip}')")['intake_headers_production_id']
          if intake_headers_production_id
            @freeze_flash = true
            flash[:error]=" The pallet  with number: " + pallet_nr.to_s + " is on an intake consignment"
            raise flash[:error]
          end

          stats = RwReceiptPallet.receive_pallet(pallet, session[:current_rw_run])
          copied_cartons = stats[0].to_s
          already_received_cartons = stats[1].to_s
          @freeze_flash = true
          flash[:notice]+= "<br>pallet: " + pallet_nr.to_s + " received successfully- with it's cartons"
          flash[:notice] += "<br><font color = 'blue'> Cartons received: " + copied_cartons + "</font>"
          flash[:notice] += "<br><font color = 'red'>  " + already_received_cartons + " carton(s) were not received, because they were received previously</font>" if stats[1] > 0

        end
        pallet_numbers_order_upgrade=nil
          if session[:current_rw_run].rw_active_pallets && session[:current_rw_run].rw_active_pallets.length > 0
             pallet_numbers_order_upgrade=session[:current_rw_run].rw_active_pallets.map{|p|p.pallet_number}
          end

        if pallet_numbers_order_upgrade
          Order.get_and_upgrade_prelim_orders(pallet_numbers_order_upgrade)
        end


      end
    rescue
      flash[:error]= "An Unexpected exception occurred: <BR>" + $! if !flash[:error]
      flash[:notice]= nil
    end

    receive_pallet
    return
  end

  def receive_pallet
    return if authorise_for_web(program_name?, 'rw_physical') == false

    render :inline => %{
		<% @content_header_caption = "'receive reworks items'"%>

		<%= build_receive_item_form("receive_pallet_submit","receive","pallet_number")%>
     <script>
		 document.getElementById('received_item_pallet_number').focus();
		</script>


		}, :layout => 'content'

  end



  def receive_bin
        #return if authorise_for_web(program_name?,'receive_bin') == false
    render :inline => %{
		<% @content_header_caption = "'receive reworks items'"%>

		<%= build_receive_item_form("receive_bin_submit","receive","bin_number")%>
     <script>
		 document.getElementById('received_item_bin_number').focus();
		</script>


		}, :layout => 'content'

  end


  #-------------
  #RECEIVED BINS
  #-------------
  def duplicate_bins?(bin_numbers)
    nums = Hash.new
    bin_numbers.each do |n|
      if nums.has_key?(n)
        return n
      else
        nums.store(n, n)
      end

    end
    return nil
  end


   def failed_received_bins?(bin_numbers)
    failed_bins = Array.new
    for bin_number in bin_numbers
       stock_item = StockItem.find_by_inventory_reference(bin_number)
       bin= Bin.find_by_bin_number(bin_number)
       received_bin = RwReceiptBin.find_by_bin_number_and_rw_run_id(bin_number, session[:current_rw_run].id)

        if bin_number == 0
             failed_bins.push(bin_number + "(is not a valid number)")
        elsif !bin
          failed_bins.push(bin_number + "(could not be found)")
        elsif bin && bin.rebin_status== "not printed"
          failed_bins.push(bin_number + "(rebin status not printed)")
        elsif !stock_item
          failed_bins.push(bin_number + "(stock item not found)".to_s)
        elsif stock_item.destroyed
          failed_bins.push(bin_number + "(stock item has been destroyed)".to_s)
        elsif   bin && bin.exit_ref == "scrapped"
          failed_bins.push(bin_number + "(has been scrapped)".to_s)
        elsif received_bin && received_bin.bin_number == bin_number
          failed_bins.push(bin_number + "(has already bin received in this run)".to_s)
        end

    end
    return failed_bins
  end

  def receive_bin_submit

     bin_nrs = params['received_item']['bin_number'].split
     if bin_nrs.length == 0
        @freeze_flash = true
        flash[:error]= "no number entered"
        receive_bin
        return
     end

     msg = nil
      if msg = duplicate_bins?(bin_nrs)
        flash[:error]= "The following bin occurs more than once in the list: <BR>" + msg
        receive_bin
        return
      end

    failed_bins= failed_received_bins?(bin_nrs)
      if failed_bins.length > 0
        flash[:error]= "The following bins cannot be received. Reasons are in brackets: <BR> #{failed_bins.join("<BR>")}"
        receive_bin
        return
      end


       bins = Array.new
       bin_nrs.each do |bin_nr|
        bin = Bin.find_by_bin_number(bin_nr)
        bins << bin
       end

       received_bins_error= RwReceiptBin.receive_bin(bins, session[:current_rw_run])
        if received_bins_error==nil
          @freeze_flash = true
          flash[:notice]= "the following bins were received successfully : :<BR> #{bin_nrs.join("<BR>")}"
          receive_bin
          return
        else
          flash[:error]= received_bins_error
          receive_bin
          return
        end

  end


  def rw_receits
    return if authorise_for_web(program_name?, 'rw_physical') == false


    @can_receive_loaded_cartons = authorise(program_name?, 'rw_loaded_cartons', session[:user_id])

    if !session[:current_rw_run]
      @freeze_flash = true
      redirect_to_index("You must first set a current reworks run")
      return
    end

    render :inline => %{
		<% @content_header_caption = "'receive reworks items'"%>

		<%= build_receive_form%>

		}, :layout => 'content'


  end

  def new_rw_run
    return if authorise_for_web(program_name?, 'rw_physical') == false


    render :inline => %{
		<% @content_header_caption = "'please select reworks run type'"%>

		<%= build_new_run_form%>

		}, :layout => 'content'


  end

  def set_current_run

    id = params[:id]
    puts "id: " + id.to_s
    @current_rw_run = RwRun.find(id)
    session[:current_rw_run]= @current_rw_run
    @info_sticker = "current reworks run is: " + @current_rw_run.rw_run_name
    redirect_to_index("run: " + @current_rw_run.rw_run_name + " has been set as the current run")
    return

  end


  def editing_rw_runs
    begin

    render :inline => %{
      <% grid            = build_runs_grid %>
      <% grid.caption    = 'editing runs' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    rescue
      handle_error("failed...")
    end

  end

  def completed_runs
    begin

    render :inline => %{
      <% grid            = build_completed_runs_grid %>
      <% grid.caption    = 'completed runs' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    rescue
      handle_error("failed...")
    end

  end


  def view_completing_run_stats
    run = RwRun.find(params[:id])
    @run_progress = ReworksProgressManager.new(run)
    if !@run_progress.run_completion_stats.is_completing

      render :inline => %{
                <script>
                   alert('run is not completing');
                </script>
      }
      return
    end

    @content_header_caption = "'stats for run: " + run.rw_run_name + "'"

    @is_active_page = true
    render :template => "production/reworks/rw_complete_progress", :layout => "content"

  end

  def update_run_stats
    #run = RwRun.find(params[:run_id])
    if session[:current_rw_run]
      @run_progress = ReworksProgressManager.new(session[:current_rw_run])

      puts "ERR: " + @run_progress.run_completion_stats.error.to_s

      if @run_progress.run_completion_stats.error
        @stop_running = "Run not completed. Error occurred"
      elsif @run_progress.run_completion_stats.done
        @stop_running = "Run completed successfully"
        session[:current_rw_run] = nil
      end
      render :template => "production/reworks/rw_complete_progress_part"
    else
      render :inline => %{
         <script> var cd = null; </script>
       }
    end


  end

  def view_stats
    run = RwRun.find(params[:id])
    @content_header_caption = "'stats for run: " + run.rw_run_name + "'"
    @run_progress = ReworksProgressManager.new(run)
    if @run_progress.new_stats?
      flash[:notice] = "No stats are available for run: " + run.rw_run_name
      completed_runs
      return
    else
      render :template => "production/reworks/rw_complete_progress", :layout => "content"
    end
  end


  def create_rw_run
    begin
      params[:rw_run]['username'] = session[:user_id].user_name
      @rw_run = RwRun.new(params[:rw_run])
      if @rw_run.save
        @info_sticker = "current reworks run is: " + @rw_run.rw_run_name
        session[:current_rw_run]= @rw_run
        redirect_to_index("run: " + @rw_run.rw_run_name + " created. It is set as the current run")
        return
      else
        render :inline => %{
		<% @content_header_caption = "'please select reworks run type'"%>

		<%= build_new_run_form(@rw_run)%>

        }, :layout => 'content'

      end
    rescue
      handle_error("run could not be created")
    end

  end


  #========================
  #OBSERVER HANDLERS
  #========================

  def cpc_changed

    session[:selected_cpc]= get_selected_combo_value(params)
    set_calculated_mass

  end

  def items_per_unit_changed
    session[:selected_items_per_unit]= get_selected_combo_value(params)
    set_calculated_mass

  end

  def units_per_carton_changed
    session[:selected_units_per_carton]= get_selected_combo_value(params)
    set_calculated_mass

  end

  def ipc_changed

    session[:selected_ipc]= get_selected_combo_value(params)
    set_calculated_mass

  end


  def set_calculated_mass()
    #-------------------------------------------------------------------------------------------------------------
    #calculate carton mass as follows:
    #trade_unit nett mass default is: cpc nett mass, but if units_per_carton and items per unit is spesified then,
    #then trade unit nett mass = standard_count avg weight(i.e. fruit weight) * items per unit * units_per_carton
    #-------------------------------------------------------------------------------------------------------------

    ipc = session[:current_editing_carton].item_pack_product_code
    ipc = session[:selected_ipc] if session[:selected_ipc]

    cpc = session[:current_editing_carton].carton_pack_product_code
    cpc = session[:selected_cpc] if session[:selected_cpc]

    carton_pack_product = CartonPackProduct.find_by_carton_pack_product_code(cpc)
    @carton_fruit_mass = carton_pack_product.nett_mass
    fruit_mass = ItemPackProduct.find_by_item_pack_product_code(ipc).standard_size_count.standard_count.average_weight_gm.to_f


    puts fruit_mass.to_s
    if fruit_mass && fruit_mass > 0
      fruit_mass = fruit_mass/1000

    end

    if fruit_mass && fruit_mass > 0 && session[:selected_units_per_carton] && session[:selected_units_per_carton].to_i > 0 && session[:selected_items_per_unit] && session[:selected_items_per_unit].to_i > 0

      @carton_fruit_mass = fruit_mass * session[:selected_units_per_carton].to_i * session[:selected_items_per_unit].to_i

    end

    @carton_fruit_mass = Float.round_float(2, @carton_fruit_mass) if @carton_fruit_mass && @carton_fruit_mass > 0

    #	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
	<%= @carton_fruit_mass.to_s %>

    }

  end

  def fg_mark_changed

    puts "WEL HELLO"
    fg_mark = get_selected_combo_value(params)
    @carton_mark = FgMark.find_by_fg_mark_code(fg_mark).tu_mark_code
    render :inline => %{
	<%= @carton_mark.to_s %>

    }

  end


  def pallet_marketer_org_combo_changed


    org = get_selected_combo_value(params)
    @target_market_codes = TargetMarket.get_all_by_org(org)
    @target_market_codes.unshift("<empty>")
    @inventory_codes = InventoryCode.get_all_by_org(org)
    @inventory_codes.unshift("<empty>")
    @mark_codes = Mark.get_all_for_org(org)
    @pallet_edit = session[:current_editing_pallet]

    render :inline => %{

    <% inv_content = select('pallet_edit','inventory_code_short',@inventory_codes) %>
    <% mark_content = select('pallet_edit','carton_mark_code',@mark_codes) %>

    <%= select('pallet_edit','target_market_short',@target_market_codes) %>

   <script>

     <%= update_element_function(
        "inventory_code_short_cell", :action => :update,
        :content => inv_content) %>

    <%= update_element_function(
        "carton_mark_code_cell", :action => :update,
        :content => mark_content) %>

   </script>
    }


  end


  def run_combo_changed


    run_code = get_selected_combo_value(params)
    session[:current_editing_carton].production_run_code = run_code
    @carton_edit = session[:current_editing_carton]
    @msg = session[:current_editing_carton].derive_fields


    if @msg != ""
      @msg.gsub!("<BR>", "")
      render :inline => %{
      <script> alert('<%=@msg%>');</script>
      }
      return
    end

    @puc = @carton_edit.puc
    @account_code = @carton_edit.account_code
    @egap = @carton_edit.egap
    @farm = @carton_edit.farm_code
    @run_track_indicator_code =  @carton_edit.track_indicator_code #set to run's in 'derive_fields()'


    @carton_edit = session[:current_editing_carton]
    @puc = @carton_edit.puc if render :inline => %{

      <script>



      <%= update_element_function(
        "farm_code_cell", :action => :update,
        :content => @farm) %>

     <%= update_element_function(
        "puc_cell", :action => :update,
        :content => @puc) %>

      <%= update_element_function(
        "account_code_cell", :action => :update,
        :content => @account_code) %>

     <%= update_element_function(
        "egap_cell", :action => :update,
        :content => @egap) %>

      <%= update_element_function(
        "run_track_indicator_code_cell", :action => :update,
        :content => @run_track_indicator_code) %>


      </script>

    }


  end


  def extended_fg_combo_changed


    ext_fg = get_selected_combo_value(params)
    session[:current_editing_carton].extended_fg_code = ext_fg
    @carton_edit = session[:current_editing_carton]

    @msg = session[:current_editing_carton].derive_fields
    if @msg != ""
      @msg.gsub!("<BR>", "")
      puts @msg
      render :inline => %{
        <script>alert("<%=@msg%>");</script>

      }
      return
    end
    #---------------------------------------------------------------------------------------
    #Get list of orgs for current carton_mark_code, and set org value to that of extended fg
    #target market and inventory code lists must also be filtered for the org
    #---------------------------------------------------------------------------------------

    @carton_edit = session[:current_editing_carton]

    #@orgs = MarksOrganization.find_all_by_mark_code(@carton_edit.carton_mark_code).map{|o|[o.short_description]}
    @target_markets = OrganizationsTargetMarket.find_all_by_short_description(@carton_edit.organization_code).map { |o| [o.target_market_name] }
    #@target_markets = OrganizationsTargetMarket.find_by_sql("
    #                  SELECT DISTINCT public.target_markets.target_market_name
    #                  FROM public.organizations_target_markets
    #                  INNER JOIN public.target_markets ON (public.organizations_target_markets.target_market_id = public.target_markets.id)
    #                  INNER JOIN public.organizations ON (public.organizations_target_markets.organization_id = public.organizations.id)
    #                  JOIN grade_target_markets on grade_target_markets.target_market_id=target_markets.id
    #                  JOIN grades on grade_target_markets.grade_id=grades.id
    #                  JOIN item_pack_products on item_pack_products.grade_id=grades.id
    #                  JOIN fg_products on fg_products.item_pack_product_id=item_pack_products.id
    #                  JOIN extended_fgs on fg_products.fg_product_code=extended_fgs.fg_code
    #                  WHERE
    #                  (public.organizations_target_markets.short_description = '#{@carton_edit.organization_code}' and grades.grade_code='#{@carton_edit.grade_code}')
    #                  ").map { |o| [o.target_market_name] }
    @inventory_codes = InventoryCodesOrganization.find_all_by_short_description(@carton_edit.organization_code).map { |o| [o.inv_code] }

    #@inventory_codes = ['select']
    #@target_markets = ['select']

    render :inline => %{

      <script>


      <% inv_content = select('carton_edit','inventory_code_short',@inventory_codes) %>
      <% tm_content = select('carton_edit','target_market_short',@target_markets) %>


      <%= update_element_function(
        "organization_code_cell", :action => :update,
        :content => @carton_edit.organization_code) %>


      <%= update_element_function(
        "inventory_code_short_cell", :action => :update,
        :content => inv_content) %>


      <%= update_element_function(
        "target_market_short_cell", :action => :update,
        :content => tm_content) %>

      <%= update_element_function(
        "item_pack_product_code_cell", :action => :update,
        :content => @carton_edit.item_pack_product_code) %>

     <%= update_element_function(
        "unit_pack_product_code_cell", :action => :update,
        :content => @carton_edit.unit_pack_product_code) %>




      <%= update_element_function(
        "carton_pack_product_code_cell", :action => :update,
        :content => @carton_edit.carton_pack_product_code) %>

     <%= update_element_function(
        "fg_product_code_cell", :action => :update,
        :content => @carton_edit.fg_product_code) %>

     <%= update_element_function(
        "fg_code_old_cell", :action => :update,
        :content => @carton_edit.fg_code_old) %>


      <%= update_element_function(
        "carton_fruit_nett_mass_cell", :action => :update,
        :content => @carton_edit.carton_fruit_nett_mass.to_s) %>

       <%= update_element_function(
        "commodity_code_cell", :action => :update,
        :content => @carton_edit.commodity_code) %>

      <%= update_element_function(
        "variety_short_long_cell", :action => :update,
        :content => @carton_edit.variety_short_long) %>

      <%= update_element_function(
        "actual_size_count_code_cell", :action => :update,
        :content => @carton_edit.actual_size_count_code) %>


      <%= update_element_function(
        "grade_code_cell", :action => :update,
        :content => @carton_edit.grade_code) %>

      <%= update_element_function(
        "product_class_code_cell", :action => :update,
        :content => @carton_edit.product_class_code) %>

      <%= update_element_function(
        "erp_cultivar_cell", :action => :update,
        :content => @carton_edit.erp_cultivar) %>

      <%= update_element_function(
        "treatment_code_cell", :action => :update,
        :content => @carton_edit.treatment_code) %>

      <%= update_element_function(
        "marking_cell", :action => :update,
        :content => @carton_edit.marking) %>

      <%= update_element_function(
        "diameter_cell", :action => :update,
        :content => @carton_edit.diameter) %>

     <%= update_element_function(
        "fg_mark_code_cell", :action => :update,
        :content => @carton_edit.fg_mark_code) %>

     <%= update_element_function(
        "carton_mark_code_cell", :action => :update,
        :content => @carton_edit.carton_mark_code) %>




      </script>

    }


  end


 def pick_ref_changed

    year =  session[:current_editing_carton].season_code
    pick_ref = get_selected_combo_value(params)
    @pack_date = DepotPallet.calc_packdate_from_pick_ref(pick_ref,year)
    session[:current_editing_carton].pack_date_time = @pack_date


    render :inline => %{

      <%= @pack_date %>
   }

  end


  def marketer_org_combo_changed


    org = get_selected_combo_value(params)
    session[:current_editing_carton].organization_code = org
    @target_market_codes = TargetMarket.get_all_by_org(org)
    @target_market_codes.unshift("<empty>")
    @inventory_codes = InventoryCode.get_all_by_org(org)
    @inventory_codes.unshift("<empty>")
    @carton_edit = session[:current_editing_carton]


    render :inline => %{

    <% inv_content = select('carton_edit','inventory_code_short',@inventory_codes) %>


    <%= select('carton_edit','target_market_short',@target_market_codes) %>

   <script>

     <%= update_element_function(
        "inventory_code_short_cell", :action => :update,
        :content => inv_content) %>



   </script>
    }


  end


  #==========================
  #   Luks' code    =========
  #==========================

  def receive_tipped_bins
    search_bins_tipped_hierarchy
  end

  def list_bins_tipped
    return if authorise_for_web(program_name?, 'read') == false

    if params[:page]!= nil

      session[:bins_tipped_page] = params['page']

      render_list_bins_tipped

      return
    else
      session[:bins_tipped_page] = nil
    end

    list_query = "@bins_tipped_pages = Paginator.new self, BinsTipped.count, @@page_size,@current_page
	 @bins_tipped = BinsTipped.find(:all,
				 :limit => @bins_tipped_pages.items_per_page,
				 :offset => @bins_tipped_pages.current.offset)"
    session[:query] = list_query
    render_list_bins_tipped
  end

  def render_list_bins_tipped
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:bins_tipped_page] if session[:bins_tipped_page]
    @current_page = params['page'] if params['page']
    @bins_tipped = eval(session[:query]) if !@bins_tipped
    render :inline => %{
      <% grid            = build_bins_tipped_grid(@bins_tipped,@can_edit,@can_delete,true) %>
      <% grid.caption    = 'list of all bins_tipped' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@bins_tipped_pages) if @bins_tipped_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def render_bins_tipped_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
    #	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  bins_tipped'"%>

		<%= build_bins_tipped_search_form(nil,'submit_bins_tipped_search','submit_bins_tipped_search',@is_flat_search)%>

		}, :layout => 'content'
  end

  def search_bins_tipped_hierarchy
    #return if authorise_for_web(program_name?,'read')== false
    return if authorise_for_web(program_name?, 'rw_physical') == false #Confirm Hans

    @is_flat_search = false
    render_bins_tipped_search_form(true)
  end

  def submit_bins_tipped_search
    if params['page']
      session[:bins_tipped_page] =params['page']
    else
      session[:bins_tipped_page] = nil
    end
    @current_page = params['page']
    if params[:page]== nil
      params[:bin_tipped][:tipped_in_reworks] = nil if params[:bin_tipped][:tipped_in_reworks] == "0"
      #puts "tipped_in_reworks == " + params[:bin_tipped][:tipped_in_reworks].class.name
      @bins_tipped = dynamic_search(params[:bin_tipped], 'bins_tipped', 'BinsTipped')
      session[:tipped_bins_returned] = @bins_tipped
    else
      @bins_tipped = eval(session[:query])
    end
    if @bins_tipped.length == 0
      if params[:page] == nil
        flash[:notice] = 'no records were found for the query'
        @is_flat_search = session[:is_flat_search].to_s
        render_bins_tipped_search_form
      else
        flash[:notice] = 'There are no more records'
        render_list_bins_tipped
      end

    else
      render_list_bins_tipped
    end
  end

  #	-----------------------------------------------------------------------------------------------------------
  #	 search combo_changed event handlers for the unique index on this table(bins_tipped)
  #	-----------------------------------------------------------------------------------------------------------

  def bins_tipped_production_schedule_name_search_combo_changed
    production_schedule_name = get_selected_combo_value(params)
    session[:bins_tipped_search_form][:production_schedule_name_combo_selection] = production_schedule_name
    @production_run_codes = BinsTipped.find_by_sql("select distinct production_run_code from production_runs where production_schedule_name = '#{production_schedule_name}'").map { |p| [p.production_run_code] }
    @production_run_codes.unshift("<empty>")
    query = "SELECT track_indicator_code FROM  public.production_schedules, public.rmt_setups
            WHERE rmt_setups.production_schedule_id = production_schedules.id AND public.production_schedules.production_schedule_name = '#{production_schedule_name}'"
    @track_indicator_code = Carton.connection.select_one(query)['track_indicator_code']
    puts "HELLO KK"

    render :inline => %{
                       <%= select('bin_tipped','production_run_code',@production_run_codes)%>
                       <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_bin_tipped_production_run_code'/>
		               <%= observe_field('bin_tipped_production_run_code',:update => 'line_code_cell',:url => {:action => session[:bins_tipped_search_form][:production_run_code_observer][:remote_method]},:loading => "show_element('img_bin_tipped_production_run_code');",:complete => session[:bins_tipped_search_form][:production_run_code_observer][:on_completed_js])%>

                       <script>
                         <%=
                           update_element_function("track_indicator_code_cell",
                           :action=>:update,
                           :content=> @track_indicator_code)
                         %>
                       </script>
    }

  end


  def bins_tipped_production_run_code_search_combo_changed
    production_run_code = get_selected_combo_value(params)
    session[:bins_tipped_search_form][:production_run_code_combo_selection] = production_run_code
    production_schedule_name = session[:bins_tipped_search_form][:production_schedule_name_combo_selection]
    @line_codes = BinsTipped.find_by_sql("Select distinct line_code from production_runs where production_run_code = '#{production_run_code}' and production_schedule_name = '#{production_schedule_name}'").map { |g| [g.line_code] }
    @line_codes.unshift("<empty>")

    #	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('bin_tipped','line_code',@line_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_bin_tipped_line_code'/>
		<%= observe_field('bin_tipped_line_code',:update => 'farm_code_cell',:url => {:action => session[:bins_tipped_search_form][:line_code_observer][:remote_method]},:loading => "show_element('img_bin_tipped_line_code');",:complete => session[:bins_tipped_search_form][:line_code_observer][:on_completed_js])%>
		}

  end


  def bins_tipped_line_code_search_combo_changed
    line_code = get_selected_combo_value(params)
    session[:bins_tipped_search_form][:line_code_combo_selection] = line_code
    production_run_code = session[:bins_tipped_search_form][:production_run_code_combo_selection]
    production_schedule_name = session[:bins_tipped_search_form][:production_schedule_name_combo_selection]
    @farm_codes = BinsTipped.find_by_sql("Select distinct farm_code from production_runs where line_code = '#{line_code}' and production_run_code = '#{production_run_code}' and production_schedule_name = '#{production_schedule_name}'").map { |g| [g.farm_code] }
    @farm_codes.unshift("<empty>")

    #	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('bin_tipped','farm_code',@farm_codes)%>
		}

  end


  def selected_tipped_bins
    @selected_tipped_bins = selected_records?(session[:tipped_bins_returned])
    session[:current_rw_run].transaction do
      @selected_tipped_bins.each do |selected_tipped_bin|
        RwReceiptTippedBin.receive_tipped_bin(selected_tipped_bin, session[:current_rw_run])
      end
    end

    session[:tipped_bins_returned] = nil
    redirect_to_index("Tipped bins were successfully received")

  end

  def rw_tipped_bins

    @can_control_run = authorise(program_name?, 'rw_physical', session[:user_id])
    @bulk_tipped_bin_update_permission = authorise(program_name?, 'rw_bulk_tipped_bin_edit', session[:user_id])

    if !session[:current_rw_run]
      @freeze_flash = true
      redirect_to_index("You do not have a current editing run")
      return
    end

    @tipped_bins = RwActiveTippedBin.find_all_by_rw_run_id(session[:current_rw_run].id)
    session[:query]= "RwActiveTippedBin.find_all_by_rw_run_id(session[:current_rw_run].id)"

    if @tipped_bins.length == 0
      @freeze_flash = true
      session[:current_carton_list] = nil
      redirect_to_index("There are no active tipped bins")
      return
    end

    session[:current_tipped_bins_list]= @tipped_bins
    content_header_caption = "'active tipped bins'"
    session[:current_tipped_bins_list_caption]= content_header_caption
    render_tipped_bins(content_header_caption, @tipped_bins)

  end

  def render_tipped_bins(caption = nil, tipped_bins = nil)

    @can_control_run = authorise(program_name?, 'rw_physical', session[:user_id])
    #puts "Runs_methods == " + session[:current_rw_run].methods.to_s
    @caption = caption
    @tipped_bins = tipped_bins

    @tipped_bins = session[:current_tipped_bins_list] if !@tipped_bins
    @caption = session[:current_tipped_bins_list_caption] if !caption

    render :inline => %{
      <% grid            = build_rw_tipped_bins_grid(@tipped_bins) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end

  def bulk_tipped_bin_update

    @tipped_bin_edit = RwActiveTippedBin.find(params[:id])

    @content_header_caption = "'Edit tipped bin for bulk update'"
    session[:current_editing_carton]= @tipped_bin_edit

    render :inline => %{


		<%= build_bulk_update_tipped_bin_form(@tipped_bin_edit,'bulk_update_tipped_bin_submit','save')%>

		}, :layout => 'content'
  end

  def tipped_bin_edit_production_schedule_name_search_combo_changed
    production_schedule_name = get_selected_combo_value(params)
    session[:tipped_bin_edit_form][:production_schedule_name_combo_selection] = production_schedule_name
    @production_run_codes = ProductionRun.find_by_sql("select distinct production_run_code from production_runs where production_schedule_name = '#{production_schedule_name}'").map { |p| p.production_run_code }
    #list_top_production_run_code = @production_run_codes[0]
    @line_code = "select a run" #BinsTipped.find_by_sql("Select distinct line_code from bins_tipped where production_run_code = '#{list_top_production_run_code}' and production_schedule_name = '#{production_schedule_name}'").map{|g|[g.line_code]}[0][0]
    session[:tipped_bin_edit_form][:selected_line_code] = @line_code
    #@line_codes.unshift("<empty>")

    render :inline => %{
                      <script>
                        document.getElementById('production_run_code_cell').style.borderColor = "white";
                         document.getElementById('production_run_code_cell').style.backgroundColor = "white";
                      </script>
                       <%= select('tipped_bin_edit','production_run_code',@production_run_codes)%>
                       <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_tipped_bin_edit_production_run_code'/>
		               <%= observe_field('tipped_bin_edit_production_run_code',:update => 'line_code_cell',:url => {:action => session[:tipped_bin_edit_form][:production_run_code_observer][:remote_method]},:loading => "show_element('img_tipped_bin_edit_production_run_code');",:complete => session[:tipped_bin_edit_form][:production_run_code_observer][:on_completed_js])%>
                        <script>
                         <%=
                           update_element_function("line_code_cell",
                           :action=>:update,
                           :content=> @line_code)
                         %>
                       </script>
    }
  end


  def tipped_bin_edit_production_run_code_search_combo_changed
    production_run_code = get_selected_combo_value(params)
    session[:tipped_bin_edit_form][:production_run_code_combo_selection] = production_run_code
    production_schedule_name = session[:tipped_bin_edit_form][:production_schedule_name_combo_selection]
    @line_code = ProductionRun.find_by_sql("Select distinct line_code from production_runs where production_run_code = '#{production_run_code}' and production_schedule_name = '#{production_schedule_name}'").map { |g| g.line_code }[0]
    @line_code = "<strong><font color = 'red' >No tipped bins for this run</font></strong>" if !@line_code
    session[:tipped_bin_edit_form][:selected_line_code] = @line_code
    #	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
	                     <%=
                         @line_code
                         %>
		}

  end


  def bulk_update_tipped_bin_submit
    @line_code = session[:tipped_bin_edit_form][:selected_line_code].to_s

    @changed_fields = "rw_reworks_action = 'reclassified' ,production_schedule_name ='#{params[:tipped_bin_edit][:production_schedule_name]}'"
    @changed_fields += ",production_run_code = '#{params[:tipped_bin_edit][:production_run_code]}'" if params[:tipped_bin_edit][:production_run_code] != nil
    @changed_fields += ",line_code = '#{@line_code}'" if @line_code != nil
    #   puts "____________@changed_fields = " + @changed_fields
    begin
      RwActiveTippedBin.update_all(ActiveRecord::Base.extend_set_sql_with_request(@changed_fields,"rw_active_tipped_bins"), "rw_run_id =#{session[:current_rw_run].id}")
      flash[:notice] = "'Received Tipped Bins all updated successfully'"
    rescue
      handle_error("tipped bins could not be updated")
    end


    @tipped_bins = RwActiveTippedBin.find_all_by_rw_run_id(session[:current_rw_run].id)
    @run = session[:current_rw_run]
    render :inline => %{}, :layout => 'content'
  end
  #==========================

  def shift_id_text_changed
    shift = Shift.find(params[:id])
    if(shift.user)
      user = shift.user
    else
      user = " "
    end

    @shift_code = "#{shift.shift_type_code}_#{shift.line_code}_#{user}_#{shift.start_date_time.strftime("%Y/%m/%d")}"
    render :inline => %{
    <script>
    var shift = window.opener.frames[1].document.getElementById('shift_cell');
    shift.innerHTML = '<%= @shift_code %>';
    window.close();
    </script>

  }, :layout => 'content'
  end

  def search_pallet_histories
    @content_header_caption = "'search pallet histories'"
    render :inline => %{
    <%= build_search_pallet_histories_form(@hash_object,'submit_pallet_histories_search','search')%>
    }, :layout => 'content'
  end

  def submit_pallet_histories_search
    @object_builder = ObjectBuilder.new
    @hash_object = @object_builder.build_hash_object(params[:hash_object])
    if(@hash_object.pallet_number.to_s.strip == '')
      flash[:error] = 'pallet_number must have a value'
      search_pallet_histories
      return
    end
    query = "
        select * from (select * from rw_runs inner join (
        select 'rw_receipt_pallets_histories' as tablename,rw_receipt_pallets_histories.id as record_id, account_code,	actual_size_count_code,	affected_by_env,	affected_by_function,
        affected_by_program,	build_status,	carton_mark_code,	carton_quantity_actual,	carton_setup_id,	class_code,	cold_store_code,
        commodity_code,	\"substring\"(consignment_note_number, 1,10)  as consignment_note_number,	country_origin_code,	cpp,created_at,	created_by,
        date_time_completed,	date_time_created,		erp_cultivar,	exit_ref,	farm_code,	fg_code_old,fg_product_code, grade_code,
        holdover,	holdover_quantity,	id,		inspect_type_code,	intake_header_id,	intake_headers_production_id,	inventory_code,
        is_depot_pallet,	is_mapped,	is_new_pallet,	iso_week_code,		load_detail_id,	marketing_variety_code,	n_labels_printed,
        oldest_pack_date_time,	old_pack_code,	order_number,	organization_code,	pallet_format_product_code,	pallet_format_product_id,
        pallet_id,	pallet_label_code,	pallet_number,	pallet_reno_ref,	pallet_template_id,	pallet_type_code,
        party_name,	pc_code, pick_reference_code, ppecb_inspection_id,		process_status,	production_run_id,	pt_product_characteristics,
        qc_result_status,	qc_status_code,			remark,	reprint_acknowledged_by,	reprint_acknowledged_date_time,
        rw_create_datetime,	rw_receipt_datetime,	rw_receipt_intake_headers_production_id,rw_run_id,	season_code,	size_count_code,
        store_type_code,	target_market_code,	updated_at,	updated_by,	zero_printed_carton_labels, '' as reworks_action, '' as person,
        0 as rw_reason_id,'' as rw_scrap_datetime,'' as user_name
        from rw_receipt_pallets_histories where pallet_number= '#{@hash_object.pallet_number}'
        union
        select 'rw_receipt_pallets' as tablename,rw_receipt_pallets.id as record_id, account_code,	actual_size_count_code,	affected_by_env,affected_by_function,	affected_by_program,
        build_status,	carton_mark_code,	carton_quantity_actual,	carton_setup_id,	class_code,	cold_store_code,	commodity_code,
        \"substring\"(consignment_note_number, 1,10)  as consignment_note_number,	country_origin_code,	cpp,created_at,	created_by,
        date_time_completed,	date_time_created,		erp_cultivar,	exit_ref,	farm_code,	fg_code_old,	fg_product_code,		grade_code,
        holdover,	holdover_quantity,	id,		inspect_type_code,	intake_header_id,	intake_headers_production_id,	inventory_code,
        is_depot_pallet,	is_mapped,	is_new_pallet,	iso_week_code,		load_detail_id,	marketing_variety_code,	n_labels_printed,
        oldest_pack_date_time,	old_pack_code,	order_number,	organization_code,	pallet_format_product_code,	pallet_format_product_id,
        0 as pallet_id,	pallet_label_code,	pallet_number,	pallet_reno_ref,	pallet_template_id,
        '' as pallet_type_code,	party_name,	pc_code,		pick_reference_code, ppecb_inspection_id,		process_status,	production_run_id,
        pt_product_characteristics,	qc_result_status,	qc_status_code,			remark,	reprint_acknowledged_by,	reprint_acknowledged_date_time,
        rw_create_datetime,	null as rw_receipt_datetime,	null as rw_receipt_intake_headers_production_id,	rw_run_id,	season_code,
        size_count_code,	store_type_code,	target_market_code,		updated_at,	updated_by,	zero_printed_carton_labels, '' as reworks_action,
        '' as person, 0 as rw_reason_id, '' as rw_scrap_datetime, '' as user_name
        from rw_receipt_pallets where pallet_number= '#{@hash_object.pallet_number}'
        union
        select 'rw_reclassed_pallets' as tablename,rw_reclassed_pallets.id as record_id, account_code,	actual_size_count_code,	affected_by_env,	affected_by_function,
        affected_by_program,	build_status,	carton_mark_code,	carton_quantity_actual,	carton_setup_id,	class_code,	cold_store_code,
        commodity_code,	\"substring\"(consignment_note_number, 1,10)  as consignment_note_number,	country_origin_code,	cpp,
        created_at,	created_by,	date_time_completed,	date_time_created,		erp_cultivar,	exit_ref,	farm_code,	fg_code_old,
        fg_product_code,		grade_code,	holdover,	holdover_quantity,	id,		inspect_type_code,	intake_header_id,
        intake_headers_production_id,	inventory_code,	is_depot_pallet,	is_mapped,	is_new_pallet,	iso_week_code,		load_detail_id,
        marketing_variety_code,	n_labels_printed,	oldest_pack_date_time,	old_pack_code,	order_number,	organization_code,
        pallet_format_product_code,	pallet_format_product_id,	0 as pallet_id,	pallet_label_code,		pallet_number,
        pallet_reno_ref,	pallet_template_id,	'' as pallet_type_code,	party_name,
        pc_code,		pick_reference_code, ppecb_inspection_id,		process_status,	production_run_id,	pt_product_characteristics,
        qc_result_status,	qc_status_code,			remark,	reprint_acknowledged_by,	reprint_acknowledged_date_time,
        rw_create_datetime,	null as rw_receipt_datetime,	null as rw_receipt_intake_headers_production_id,rw_run_id,	season_code,
        size_count_code,	store_type_code,	target_market_code,		updated_at,	updated_by,	zero_printed_carton_labels,reworks_action,
        '' as person, 0 as rw_reason_id, '' as rw_scrap_datetime, '' as user_name
        from rw_reclassed_pallets where pallet_number= '#{@hash_object.pallet_number}'
        union
        select 'rw_scrap_pallets' as tablename,rw_scrap_pallets.id as record_id, '' as account_code,	actual_size_count_code,	'' as affected_by_env,	'' as affected_by_function,
        '' as affected_by_program,	build_status,	carton_mark_code,	carton_quantity_actual,	carton_setup_id,	class_code,	cold_store_code,
        commodity_code,	cast(consignment_note_number as varchar(10))  as consignment_note_number,	country_origin_code,	0 as cpp,
        null as created_at,	'' as created_by,	null as date_time_completed,	date_time_created,		erp_cultivar,	'' as exit_ref,	farm_code,
        fg_code_old,	fg_product_code,		grade_code,	holdover,	holdover_quantity,	id,		inspect_type_code,	intake_header_id,
        intake_headers_production_id,	inventory_code,	null  as is_depot_pallet,	is_mapped,	is_new_pallet,	null as iso_week_code,
        load_detail_id,	marketing_variety_code,	n_labels_printed,	oldest_pack_date_time,	old_pack_code,	'' as order_number,	organization_code,
        pallet_format_product_code,	pallet_format_product_id,	0 as pallet_id,	pallet_label_code,		pallet_number,
        pallet_reno_ref,	pallet_template_id,	'' as pallet_type_code,	'' as party_name,pc_code,pick_reference_code, 0 as ppecb_inspection_id,
        process_status,	production_run_id,	pt_product_characteristics,	qc_result_status,	qc_status_code,	remark,	reprint_acknowledged_by,
        reprint_acknowledged_date_time,	null as rw_create_datetime,	null as rw_receipt_datetime,	null as rw_receipt_intake_headers_production_id,
        rw_run_id,	'' as season_code,	size_count_code,	'' as store_type_code,	target_market_code,		null as updated_at,
        '' as updated_by,	zero_printed_carton_labels,'' as reworks_action,person, rw_reason_id,
        cast(rw_scrap_datetime as varchar) as rw_scrap_datetime,user_name
        from rw_scrap_pallets where pallet_number= '#{@hash_object.pallet_number}') rw_rec
        on rw_runs.id = rw_rec.rw_run_id
        union
        select id, null as rw_run_start_datetime, null as rw_run_end_datetime,  null as rw_run_status_code, null as rw_run_type_code,
        null as remarks, null as rw_run_name, null as username, null as carton_printing_ip, null as busy,'pallets' as tablename,pallets.id as record_id, account_code,
        actual_size_count_code,	affected_by_env,	affected_by_function,	affected_by_program,	build_status,	carton_mark_code,
        carton_quantity_actual,	carton_setup_id,	class_code,	cold_store_code,	commodity_code,
        \"substring\"(consignment_note_number, 1,10)  as consignment_note_number,	country_origin_code,	cpp,created_at,	created_by,	date_time_completed,
        date_time_created,		erp_cultivar,	exit_ref,	farm_code,	fg_code_old,
        fg_product_code,		grade_code,	holdover,	holdover_quantity,	id,		inspect_type_code,	intake_header_id,
        intake_headers_production_id,	inventory_code,	is_depot_pallet,	is_mapped,	is_new_pallet,	iso_week_code,		load_detail_id,
        marketing_variety_code,	n_labels_printed,	oldest_pack_date_time,	old_pack_code,	order_number,	organization_code,
        pallet_format_product_code,	pallet_format_product_id,	id as pallet_id,	pallet_label_code,		pallet_number,
        pallet_reno_ref,	pallet_template_id,	'' as pallet_type_code,	party_name,
        pc_code,		pick_reference_code, ppecb_inspection_id,		process_status,	production_run_id,	pt_product_characteristics,
        qc_result_status,	qc_status_code,			remark,	reprint_acknowledged_by,	reprint_acknowledged_date_time,
        rw_create_datetime,	null as rw_receipt_datetime,	null as rw_receipt_intake_headers_production_id,
        0 as rw_run_id,	season_code,	size_count_code,	store_type_code,	target_market_code,
        updated_at,	updated_by,	zero_printed_carton_labels,'' as reworks_action, '' as person, 0 as rw_reason_id, '' as rw_scrap_datetime,'' as user_name
        from pallets where pallet_number= '#{@hash_object.pallet_number}') rw
        order by rw_run_start_datetime asc
        "

    #puts "query : \n #{query}"
    session[:query]= "@pallets = ActiveRecord::Base.connection.select_all(\"#{query.gsub("\"","\\\"")}\")"

    @pallets = ActiveRecord::Base.connection.select_all(query)
    render :inline => %{
           <% grid            = build_pallet_histories_grid(@pallets) %>
          <% grid.caption    = 'pallet histories grid' %>

          <% @header_content = grid.build_grid_data %>

          <%= grid.render_html %>
          <%= grid.render_grid %>
        }, :layout => 'content'
  end

  def submit_bin_histories_search
    @object_builder = ObjectBuilder.new
    @hash_object = @object_builder.build_hash_object(params[:hash_object])
    if(@hash_object.bin_number.to_s.strip == '')
      flash[:error] = 'bin_number must have a value'
      search_bin_histories
      return
    end

    query = "
        select * from (select * from rw_runs inner join (
        select 'rw_receipt_bins_histories' as tablename,	affected_by_env,	affected_by_function,	affected_by_program,	bin_id,	bin_number,	bin_order_load_detail_id,	bin_receive_date_time,	binfill_station_code,	created_at,	created_by,	created_on,	delivery_id,	exit_ref,	exit_reference_date_time,	farm_id,	id,	is_half_bin,	is_sample_bin,	orchard_code,	pack_material_product_code,	pack_material_product_id,	print_number,	production_run_rebin_id,	production_run_tipped_id,	rebin_date_time,	rebin_label_station_code,	rebin_status,	rebin_track_indicator_code,	reworks_action,	rmt_product_id,	0 as rw_reason_id, rw_run_id,	sealed_ca_location_id,	season_code,	shift_id,	tipped_date_time,	track_indicator1_id,	track_indicator2_id,	track_indicator3_id,	track_indicator4_id,	track_indicator5_id,	updated_at,	updated_by,	user_name,	weight
        from rw_receipt_bins_histories	where bin_number = '#{@hash_object.bin_number}'
        union
        select 'rw_receipt_bins' as tablename,	affected_by_env,	affected_by_function,	affected_by_program,	bin_id,	bin_number,	bin_order_load_detail_id,	bin_receive_date_time,	binfill_station_code,	created_at,	created_by,	created_on,	delivery_id,	exit_ref,	exit_reference_date_time,	farm_id,	id,	is_half_bin,	is_sample_bin,	orchard_code,	pack_material_product_code,	pack_material_product_id,	print_number,	production_run_rebin_id,	production_run_tipped_id,	rebin_date_time,	rebin_label_station_code,	rebin_status,	rebin_track_indicator_code,	reworks_action,	rmt_product_id,	0 as rw_reason_id, rw_run_id,	sealed_ca_location_id,	season_code,	shift_id,	tipped_date_time,	track_indicator1_id,	track_indicator2_id,	track_indicator3_id,	track_indicator4_id,	track_indicator5_id,	updated_at,	updated_by,	user_name,	weight
        from rw_receipt_bins	where bin_number = '#{@hash_object.bin_number}'
        union
        select 'rw_reclassed_bins' as tablename,	'' as affected_by_env,	'' as affected_by_function,	'' as affected_by_program,	bin_id,	bin_number,	bin_order_load_detail_id,	bin_receive_date_time,	binfill_station_code,	created_on as  created_at,	'' as created_by,	created_on,	delivery_id,	exit_ref,	exit_reference_date_time,	farm_id,	id,	is_half_bin,	is_sample_bin,	orchard_code,	pack_material_product_code,	pack_material_product_id,	print_number,	production_run_rebin_id,	production_run_tipped_id,	rebin_date_time,	rebin_label_station_code,	rebin_status,	rebin_track_indicator_code,	reworks_action,	rmt_product_id,	0 as rw_reason_id, rw_run_id,	sealed_ca_location_id,	season_code,	shift_id,	tipped_date_time,	track_indicator1_id,	track_indicator2_id,	track_indicator3_id,	track_indicator4_id,	track_indicator5_id,	NULL as updated_at,	'' as updated_by,	user_name,	weight
        from rw_reclassed_bins	where bin_number = '#{@hash_object.bin_number}'
        union
        select 'rw_scrap_bins' as tablename,	'' as affected_by_env,	'' as affected_by_function,	'' as affected_by_program,	bin_id,	bin_number,	bin_order_load_detail_id,	bin_receive_date_time,	binfill_station_code,	created_on as created_at,	'' as created_by,	created_on,	delivery_id,	exit_ref,	exit_reference_date_time,	farm_id,	id,	is_half_bin,	is_sample_bin,	orchard_code,	pack_material_product_code,	pack_material_product_id,	print_number,	production_run_rebin_id,	production_run_tipped_id,	rebin_date_time,	rebin_label_station_code,	rebin_status,	rebin_track_indicator_code,	'' as reworks_action, rmt_product_id,	rw_reason_id,	rw_run_id,	sealed_ca_location_id,	season_code,	shift_id,	tipped_date_time,	track_indicator1_id,	track_indicator2_id,	track_indicator3_id,	track_indicator4_id,	track_indicator5_id,	null as updated_at,	'' as updated_by,	user_name,	weight
        from rw_scrap_bins	where bin_number = '#{@hash_object.bin_number}') rw_rec
        on rw_runs.id = rw_rec.rw_run_id
        union

        select 0 as id, null as rw_run_start_datetime, null as rw_run_end_datetime,  null as rw_run_status_code, null as rw_run_type_code,
        null as remarks, null as rw_run_name, null as username, null as carton_printing_ip, null as busy,
        'bins' as tablename,	affected_by_env,	affected_by_function,	affected_by_program,	0 as bin_id, bin_number,	bin_order_load_detail_id,	bin_receive_date_time,	binfill_station_code,	created_at,	created_by,	created_on,	delivery_id,	exit_ref,	exit_reference_date_time,	farm_id,	id,	is_half_bin,	is_sample_bin,	orchard_code,	'' as pack_material_product_code,	pack_material_product_id,	print_number,	production_run_rebin_id,	production_run_tipped_id,	rebin_date_time,	rebin_label_station_code,	rebin_status,	rebin_track_indicator_code,	'' as reworks_action,	rmt_product_id,	0 as rw_reason_id, 0 as rw_run_id,	sealed_ca_location_id,	season_code,	shift_id,	tipped_date_time,	track_indicator1_id,	track_indicator2_id,	track_indicator3_id,	track_indicator4_id,	track_indicator5_id,	updated_at,	updated_by,	user_name,	weight
        from bins	where bin_number = '#{@hash_object.bin_number}'
        ) rw
        order by rw_run_start_datetime asc
        "
    session[:query]= "@bins = ActiveRecord::Base.connection.select_all(\"#{query}\")"

    @bins = ActiveRecord::Base.connection.select_all(query)

    render :inline => %{
      <% grid            = build_bin_histories_grid(@bins) %>
      <% grid.caption    = 'bin histories grid' %>
      <% grid.group_fields = ['rw_run_name'] %>
      <% grid.groupable_fields    = ['rw_run_name'] %>
      <% grid.grouped      = true %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end

  def submit_carton_histories_search
    @object_builder = ObjectBuilder.new
    @hash_object = @object_builder.build_hash_object(params[:hash_object])
    if(@hash_object.carton_number.to_s.strip == '' && @hash_object.pallet_number.to_s.strip == '')
      flash[:error] = 'either carton_number or pallet_number must have a value'
      search_carton_histories
      return
    end

    pallet_number_cond = ""
    if(@hash_object.pallet_number.to_s.strip.length > 0)
      pallet_number_cond = " pallet_number='#{@hash_object.pallet_number}' "
    end

    carton_number_cond = ""
    if(@hash_object.pallet_number.to_s.strip.length > 0 && @hash_object.carton_number.to_s.strip.length > 0)
      carton_number_cond = " or carton_number='#{@hash_object.carton_number}' "
    elsif(@hash_object.carton_number.to_s.strip.length > 0)
      carton_number_cond = " carton_number='#{@hash_object.carton_number}' "
    end

    query = "
        select * from (select * from rw_runs inner join (
        select 'rw_receipt_cartons_histories' as tablename,rw_receipt_cartons_histories.id as record_id, account_code,actual_size_count_code,affected_by_env,affected_by_function,affected_by_program,
        carton_fruit_nett_mass,carton_fruit_nett_mass_actual,carton_id,carton_label_code,carton_label_station_code,carton_mark_code,carton_number,
        carton_pack_station_code,carton_template_id,cold_store_code,commodity_code,created_at,created_by,date_time_created,egap,
        erp_cultivar,erp_pack_point,erp_station,exit_date_time,exit_reference,extended_fg_code,farm_code,fg_code_old,
        fg_mark_code,fg_product_code,grade_code,gtin,id,inspection_type_code,intake_header_id,intake_header_number,inventory_code,is_depot_carton,
        is_inspection_carton,iso_week_code,items_per_unit,line_code,mapped_pallet_sequence_id,n_labels_printed,old_pack_code,order_number,organization_code,
        pack_date_time,packer_number,pallet_id,pallet_number,pallet_sequence_number,pc_code,pick_reference,ppecb_inspection_id,product_class_code,
        production_run_code,production_run_id,puc,qc_datetime_in,qc_datetime_out,qc_result_status,qc_status_code,quantity,
        remarks,reprint_acknowledged_by,reprint_acknowledged_date_time,reworks_action,run_track_indicator_code,rw_create_datetime,
        rw_receipt_datetime,rw_receipt_intake_headers_production_id,rw_receipt_pallet_id,rw_receipt_unit,
        rw_run_id,season_code,sell_by_code,shift_code,shift_id,spray_program_code,target_market_code,track_indicator_code,
        treatment_code,treatment_type_code,unit_pack_product_code,units_per_carton,updated_at,updated_by,variety_short_long ,
        '' as rw_reclassed_datetime,0 as rw_reclassed_intake_headers_production_id,'' as person,0 as rw_reason_id,'' as rw_scrap_datetime,'' as user_name
        from rw_receipt_cartons_histories where #{pallet_number_cond} #{carton_number_cond}
        union
        select 'rw_receipt_cartons' as tablename,rw_receipt_cartons.id as record_id, account_code,actual_size_count_code,affected_by_env,affected_by_function,affected_by_program,
        carton_fruit_nett_mass,carton_fruit_nett_mass_actual,carton_id,carton_label_code,carton_label_station_code,carton_mark_code,carton_number,
        carton_pack_station_code,carton_template_id,cold_store_code,commodity_code,created_at,created_by,date_time_created,egap,
        erp_cultivar,erp_pack_point,erp_station,exit_date_time,exit_reference,extended_fg_code,farm_code,fg_code_old,
        fg_mark_code,fg_product_code,grade_code,gtin,id,inspection_type_code,intake_header_id,intake_header_number,inventory_code,is_depot_carton,
        is_inspection_carton,iso_week_code,items_per_unit,line_code,mapped_pallet_sequence_id,n_labels_printed,old_pack_code,order_number,organization_code,
        pack_date_time,packer_number,pallet_id,pallet_number,pallet_sequence_number,pc_code,pick_reference,ppecb_inspection_id,product_class_code,
        production_run_code,production_run_id,puc,qc_datetime_in,qc_datetime_out,qc_result_status,qc_status_code,quantity,
        remarks,reprint_acknowledged_by,reprint_acknowledged_date_time,reworks_action,run_track_indicator_code,rw_create_datetime,
        rw_receipt_datetime,rw_receipt_intake_headers_production_id,rw_receipt_pallet_id,rw_receipt_unit,
        rw_run_id,season_code,sell_by_code,shift_code,shift_id,spray_program_code,target_market_code,track_indicator_code,
        treatment_code,treatment_type_code,unit_pack_product_code,units_per_carton,updated_at,updated_by,variety_short_long,
        '' as rw_reclassed_datetime,0 as rw_reclassed_intake_headers_production_id , '' as person,0 as rw_reason_id,'' as rw_scrap_datetime,'' as user_name
        from rw_receipt_cartons where #{pallet_number_cond} #{carton_number_cond}
        union
        select 'rw_reclassed_cartons' as tablename,rw_reclassed_cartons.id as record_id,account_code,actual_size_count_code,affected_by_env,affected_by_function,affected_by_program,
        carton_fruit_nett_mass,carton_fruit_nett_mass_actual,0 as carton_id,carton_label_code,carton_label_station_code,carton_mark_code,carton_number,
        carton_pack_station_code,carton_template_id,cold_store_code,commodity_code,created_at,created_by,date_time_created,egap,
        erp_cultivar,erp_pack_point,erp_station,exit_date_time,exit_reference,extended_fg_code,farm_code,fg_code_old,
        fg_mark_code,fg_product_code,grade_code,gtin,id,inspection_type_code,intake_header_id,intake_header_number,inventory_code,is_depot_carton,
        is_inspection_carton,iso_week_code,items_per_unit,line_code,mapped_pallet_sequence_id,n_labels_printed,old_pack_code,order_number,organization_code,
        pack_date_time,packer_number,pallet_id,pallet_number,pallet_sequence_number,pc_code,pick_reference,ppecb_inspection_id,product_class_code,
        production_run_code,production_run_id,puc,qc_datetime_in,qc_datetime_out,qc_result_status,qc_status_code,quantity,
        remarks,reprint_acknowledged_by,reprint_acknowledged_date_time,'' as reworks_action,'' as run_track_indicator_code,rw_create_datetime,
        null as rw_receipt_datetime,0 as rw_receipt_intake_headers_production_id,0 as rw_receipt_pallet_id,rw_receipt_unit,
        rw_run_id,season_code,sell_by_code,shift_code,shift_id,spray_program_code,target_market_code,track_indicator_code,treatment_code,treatment_type_code,
        unit_pack_product_code,units_per_carton,updated_at,updated_by,variety_short_long,cast(rw_reclassed_datetime as varchar) as rw_reclassed_datetime  ,
        rw_reclassed_intake_headers_production_id, '' as person,0 as rw_reason_id,'' as rw_scrap_datetime,'' as user_name
        from rw_reclassed_cartons where #{pallet_number_cond} #{carton_number_cond}
        union
        select 'rw_scrap_cartons' as tablename,rw_scrap_cartons.id as record_id, account_code,actual_size_count_code,'' as affected_by_env,'' as affected_by_function,'' as affected_by_program,
        carton_fruit_nett_mass,carton_fruit_nett_mass_actual,0 as carton_id,carton_label_code,carton_label_station_code,carton_mark_code,carton_number,
        carton_pack_station_code,carton_template_id,cold_store_code,commodity_code,null as created_at,'' as created_by,date_time_created,egap,
        erp_cultivar,erp_pack_point,erp_station,exit_date_time,exit_reference,extended_fg_code,farm_code,fg_code_old,fg_mark_code,fg_product_code,grade_code,
        gtin,id,inspection_type_code,intake_header_id,0 as intake_header_number,inventory_code,is_depot_carton,is_inspection_carton,iso_week_code,items_per_unit,
        line_code,mapped_pallet_sequence_id,n_labels_printed,old_pack_code,order_number,organization_code,pack_date_time,packer_number,pallet_id,pallet_number,
        pallet_sequence_number,pc_code,pick_reference,0 as ppecb_inspection_id,product_class_code,production_run_code,production_run_id,puc,qc_datetime_in,
        qc_datetime_out,qc_result_status,qc_status_code,quantity,remarks,reprint_acknowledged_by,reprint_acknowledged_date_time,'' as reworks_action,
        '' as run_track_indicator_code,null as rw_create_datetime,null as rw_receipt_datetime,0 as rw_receipt_intake_headers_production_id,
        0 as rw_receipt_pallet_id,'' as rw_receipt_unit,rw_run_id,season_code,sell_by_code,shift_code,shift_id,spray_program_code,target_market_code,
        track_indicator_code,treatment_code,'' as treatment_type_code,unit_pack_product_code,units_per_carton,null as updated_at,'' as updated_by,
        variety_short_long,'' as rw_reclassed_datetime,0 as rw_reclassed_intake_headers_production_id, person,rw_reason_id,
        cast(rw_scrap_datetime as varchar) as rw_scrap_datetime,user_name
        from rw_scrap_cartons where #{pallet_number_cond} #{carton_number_cond}) rw_rec
        on rw_runs.id = rw_rec.rw_run_id
        union
        select id, null as rw_run_start_datetime, null as rw_run_end_datetime,  null as rw_run_status_code, null as rw_run_type_code,
        null as remarks, null as rw_run_name, null as username, null as carton_printing_ip, null as busy,
        'cartons' as tablename,cartons.id as record_id, account_code,actual_size_count_code,affected_by_env,affected_by_function,affected_by_program,carton_fruit_nett_mass,
        carton_fruit_nett_mass_actual,id as carton_id,carton_label_code,carton_label_station_code,carton_mark_code,carton_number,carton_pack_station_code,
        carton_template_id,cold_store_code,commodity_code,created_at,created_by,date_time_created,egap,
        erp_cultivar,erp_pack_point,erp_station,exit_date_time,exit_reference,extended_fg_code,farm_code,fg_code_old,
        fg_mark_code,fg_product_code,grade_code,gtin,id,inspection_type_code,intake_header_id,intake_header_number,inventory_code,is_depot_carton,
        is_inspection_carton,iso_week_code,items_per_unit,line_code,mapped_pallet_sequence_id,n_labels_printed,old_pack_code,order_number,organization_code,
        pack_date_time,packer_number,pallet_id,pallet_number,pallet_sequence_number,pc_code,pick_reference,ppecb_inspection_id,product_class_code,
        production_run_code,production_run_id,puc,qc_datetime_in,qc_datetime_out,qc_result_status,qc_status_code,quantity,
        remarks,reprint_acknowledged_by,reprint_acknowledged_date_time,'' as reworks_action,'' as run_track_indicator_code,rw_create_datetime,
        null as rw_receipt_datetime,0 as rw_receipt_intake_headers_production_id,0 as rw_receipt_pallet_id,rw_receipt_unit,
        0 as rw_run_id,season_code,sell_by_code,shift_code,shift_id,spray_program_code,target_market_code,track_indicator_code,
        treatment_code,treatment_type_code,unit_pack_product_code,units_per_carton,updated_at,updated_by,variety_short_long,
        '' as rw_reclassed_datetime,0 as rw_reclassed_intake_headers_production_id, '' as person,0 as rw_reason_id,'' as rw_scrap_datetime,'' as user_name
        from cartons where #{pallet_number_cond} #{carton_number_cond}) rw
        order by rw_run_start_datetime asc
        "

    #puts "query : \n #{query}"

    session[:query]= "@cartons = ActiveRecord::Base.connection.select_all(\"#{query}\")"
    @cartons = ActiveRecord::Base.connection.select_all(query)

    render :inline => %{
      <% grid            = build_carton_histories_grid(@cartons) %>
      <% grid.caption    = 'carton histories grid' %>
      <% grid.group_fields = ['rw_run_name'] %>
      <% grid.groupable_fields    = ['rw_run_name','pallet_number'] %>
      <% grid.grouped      = true %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end

  def search_carton_histories
    @content_header_caption = "'search carton histories'"
    render :inline => %{
    <%= build_search_carton_histories_form(@hash_object,'submit_carton_histories_search','search')%>
    }, :layout => 'content'
  end

  def search_bin_histories
    @content_header_caption = "'search bin histories'"
    render :inline => %{
    <%= build_search_bin_histories_form(@hash_object,'submit_bin_histories_search','search')%>
    }, :layout => 'content'
  end

  def view_carton_history_diff
    rw_reclassed_carton = RwReclassedCarton.find_by_sql("select 'rw_reclassed_cartons' as tablename,rw_reclassed_cartons.id as record_id,account_code,actual_size_count_code,affected_by_env,affected_by_function,affected_by_program,
            carton_fruit_nett_mass,carton_fruit_nett_mass_actual,0 as carton_id,carton_label_code,carton_label_station_code,carton_mark_code,carton_number,
            carton_pack_station_code,carton_template_id,cold_store_code,commodity_code,created_at,created_by,date_time_created,egap,
            erp_cultivar,erp_pack_point,erp_station,exit_date_time,exit_reference,extended_fg_code,farm_code,fg_code_old,
            fg_mark_code,fg_product_code,grade_code,gtin,id,inspection_type_code,intake_header_id,intake_header_number,inventory_code,is_depot_carton,
            is_inspection_carton,iso_week_code,items_per_unit,line_code,mapped_pallet_sequence_id,n_labels_printed,old_pack_code,order_number,organization_code,
            pack_date_time,packer_number,pallet_id,pallet_number,pallet_sequence_number,pc_code,pick_reference,ppecb_inspection_id,product_class_code,
            production_run_code,production_run_id,puc,qc_datetime_in,qc_datetime_out,qc_result_status,qc_status_code,quantity,
            remarks,reprint_acknowledged_by,reprint_acknowledged_date_time,'' as reworks_action,'' as run_track_indicator_code,rw_create_datetime,
            null as rw_receipt_datetime,0 as rw_receipt_intake_headers_production_id,0 as rw_receipt_pallet_id,rw_receipt_unit,
            rw_run_id,season_code,sell_by_code,shift_code,shift_id,spray_program_code,target_market_code,track_indicator_code,treatment_code,treatment_type_code,
            unit_pack_product_code,units_per_carton,updated_at,updated_by,variety_short_long,cast(rw_reclassed_datetime as varchar) as rw_reclassed_datetime  ,
            rw_reclassed_intake_headers_production_id, '' as person,0 as rw_reason_id,'' as rw_scrap_datetime,'' as user_name
            from rw_reclassed_cartons where rw_reclassed_cartons.id=#{params[:id]}").map{|c|
      c.attributes.delete_if {|key, value| RwReclassedCarton.exclude_in_rw_histories_comparisons.include?(key)}
    }

    rw_receipt_carton = RwReceiptCarton.find_by_sql("select 'rw_receipt_cartons' as tablename,rw_receipt_cartons.id as record_id, account_code,actual_size_count_code,affected_by_env,affected_by_function,affected_by_program,
            carton_fruit_nett_mass,carton_fruit_nett_mass_actual,carton_id,carton_label_code,carton_label_station_code,carton_mark_code,carton_number,
            carton_pack_station_code,carton_template_id,cold_store_code,commodity_code,created_at,created_by,date_time_created,egap,
            erp_cultivar,erp_pack_point,erp_station,exit_date_time,exit_reference,extended_fg_code,farm_code,fg_code_old,
            fg_mark_code,fg_product_code,grade_code,gtin,id,inspection_type_code,intake_header_id,intake_header_number,inventory_code,is_depot_carton,
            is_inspection_carton,iso_week_code,items_per_unit,line_code,mapped_pallet_sequence_id,n_labels_printed,old_pack_code,order_number,organization_code,
            pack_date_time,packer_number,pallet_id,pallet_number,pallet_sequence_number,pc_code,pick_reference,ppecb_inspection_id,product_class_code,
            production_run_code,production_run_id,puc,qc_datetime_in,qc_datetime_out,qc_result_status,qc_status_code,quantity,
            remarks,reprint_acknowledged_by,reprint_acknowledged_date_time,reworks_action,run_track_indicator_code,rw_create_datetime,
            rw_receipt_datetime,rw_receipt_intake_headers_production_id,rw_receipt_pallet_id,rw_receipt_unit,
            rw_run_id,season_code,sell_by_code,shift_code,shift_id,spray_program_code,target_market_code,track_indicator_code,
            treatment_code,treatment_type_code,unit_pack_product_code,units_per_carton,updated_at,updated_by,variety_short_long,
            '' as rw_reclassed_datetime,0 as rw_reclassed_intake_headers_production_id , '' as person,0 as rw_reason_id,'' as rw_scrap_datetime,'' as user_name
            from rw_receipt_cartons where carton_number='#{rw_reclassed_carton[0].carton_number}' and rw_run_id=#{rw_reclassed_carton[0].rw_run_id}").map{|c|
      c.attributes.delete_if {|key, value| RwReclassedCarton.exclude_in_rw_histories_comparisons.include?(key)}
    }
    rhs_carton_header = "rw_receipt_carton"

    if(rw_receipt_carton.length == 0)
      rw_receipt_carton = RwReceiptCartonsHistory.find_by_sql("
            select 'rw_receipt_cartons_histories' as tablename,rw_receipt_cartons_histories.id as record_id, account_code,actual_size_count_code,affected_by_env,affected_by_function,affected_by_program,
            carton_fruit_nett_mass,carton_fruit_nett_mass_actual,carton_id,carton_label_code,carton_label_station_code,carton_mark_code,carton_number,
            carton_pack_station_code,carton_template_id,cold_store_code,commodity_code,created_at,created_by,date_time_created,egap,
            erp_cultivar,erp_pack_point,erp_station,exit_date_time,exit_reference,extended_fg_code,farm_code,fg_code_old,
            fg_mark_code,fg_product_code,grade_code,gtin,id,inspection_type_code,intake_header_id,intake_header_number,inventory_code,is_depot_carton,
            is_inspection_carton,iso_week_code,items_per_unit,line_code,mapped_pallet_sequence_id,n_labels_printed,old_pack_code,order_number,organization_code,
            pack_date_time,packer_number,pallet_id,pallet_number,pallet_sequence_number,pc_code,pick_reference,ppecb_inspection_id,product_class_code,
            production_run_code,production_run_id,puc,qc_datetime_in,qc_datetime_out,qc_result_status,qc_status_code,quantity,
            remarks,reprint_acknowledged_by,reprint_acknowledged_date_time,reworks_action,run_track_indicator_code,rw_create_datetime,
            rw_receipt_datetime,rw_receipt_intake_headers_production_id,rw_receipt_pallet_id,rw_receipt_unit,
            rw_run_id,season_code,sell_by_code,shift_code,shift_id,spray_program_code,target_market_code,track_indicator_code,
            treatment_code,treatment_type_code,unit_pack_product_code,units_per_carton,updated_at,updated_by,variety_short_long ,
            '' as rw_reclassed_datetime,0 as rw_reclassed_intake_headers_production_id,'' as person,0 as rw_reason_id,'' as rw_scrap_datetime,'' as user_name
            from rw_receipt_cartons_histories where carton_number='#{rw_reclassed_carton[0].carton_number}' and rw_run_id=#{rw_reclassed_carton[0].rw_run_id}").map{|c|
        c.attributes.delete_if {|key, value| RwReclassedCarton.exclude_in_rw_histories_comparisons.include?(key)}
      }
      rhs_carton_header = "rw_receipt_cartons_histories"
    end
    if(discrepancies = Comparer.calc_discrepancies(rw_reclassed_carton, rw_receipt_carton,"carton_number","pallet_sequence_number"))
      left_diffs = discrepancies['left_diffs']
      right_diffs = discrepancies['right_diffs']
    end
    @discrepancy_report_contents = to_discrep_htm(left_diffs, right_diffs,"rw_reclassed_carton",rhs_carton_header,"carton_number","pallet_sequence_number",nil,nil,nil)

    render :inline => %{
        <%= @discrepancy_report_contents %>
        }, :layout => 'content'

  end

  def view_pallet_history_diff

    rw_reclassed_pallet = RwReclassedPallet.find_by_sql("
        select 'rw_reclassed_pallets' as tablename, account_code,	actual_size_count_code,	affected_by_env,	affected_by_function,
        affected_by_program,	build_status,	carton_mark_code,	carton_quantity_actual,	carton_setup_id,	class_code,	cold_store_code,
        commodity_code,	\"substring\"(consignment_note_number, 1,10)  as consignment_note_number,	country_origin_code,	cpp,
        created_at,	created_by,	date_time_completed,	date_time_created,		erp_cultivar,	exit_ref,	farm_code,	fg_code_old,
        fg_product_code,		grade_code,	holdover,	holdover_quantity,	id,		inspect_type_code,	intake_header_id,
        intake_headers_production_id,	inventory_code,	is_depot_pallet,	is_mapped,	is_new_pallet,	iso_week_code,		load_detail_id,
        marketing_variety_code,	n_labels_printed,	oldest_pack_date_time,	old_pack_code,	order_number,	organization_code,
        pallet_format_product_code,	pallet_format_product_id,	0 as pallet_id,	pallet_label_code,		pallet_number,
        pallet_reno_ref,	pallet_template_id,	'' as pallet_type_code,	party_name,
        pc_code,		pick_reference_code, ppecb_inspection_id,		process_status,	production_run_id,	pt_product_characteristics,
        qc_result_status,	qc_status_code,			remark,	reprint_acknowledged_by,	reprint_acknowledged_date_time,
        rw_create_datetime,	null as rw_receipt_datetime,	null as rw_receipt_intake_headers_production_id,rw_run_id,	season_code,
        size_count_code,	store_type_code,	target_market_code,		updated_at,	updated_by,	zero_printed_carton_labels,reworks_action,
        '' as person, 0 as rw_reason_id, '' as rw_scrap_datetime, '' as user_name
        from rw_reclassed_pallets where rw_reclassed_pallets.id= '#{params[:id]}'
    ").map{|c| c.attributes.delete_if {|key, value| RwReclassedPallet.exclude_in_rw_histories_comparisons.include?(key)} }

    rw_reclassed_pallet_cartons = RwReclassedCarton.find_all_by_pallet_number_and_rw_run_id(rw_reclassed_pallet[0]['pallet_number'],rw_reclassed_pallet[0]['rw_run_id']).map{|c|
      c.attributes.delete_if {|key, value| RwReclassedCarton.exclude_in_rw_histories_comparisons.include?(key)}
    }
    rw_reclassed_pallet[0].store('children',rw_reclassed_pallet_cartons)

    rw_receipt_pallet = RwReceiptPallet.find_by_sql("
        select 'rw_receipt_pallets' as tablename,rw_receipt_pallets.id as record_id, rw_receipt_pallets.account_code,	rw_receipt_pallets.actual_size_count_code,	rw_receipt_pallets.affected_by_env,rw_receipt_pallets.affected_by_function
        ,rw_receipt_pallets.affected_by_program,rw_receipt_pallets.build_status,rw_receipt_pallets.carton_mark_code,rw_receipt_pallets.carton_quantity_actual
        ,rw_receipt_pallets.carton_setup_id,rw_receipt_pallets.class_code,rw_receipt_pallets.cold_store_code,commodity_code,
        \"substring\"(consignment_note_number, 1,10)  as consignment_note_number,	rw_receipt_pallets.country_origin_code,	rw_receipt_pallets.cpp
        ,rw_receipt_pallets.created_at,rw_receipt_pallets.created_by,rw_receipt_pallets.date_time_completed,rw_receipt_pallets.date_time_created
        ,rw_receipt_pallets.erp_cultivar,rw_receipt_pallets.exit_ref,rw_receipt_pallets.farm_code,rw_receipt_pallets.fg_code_old,rw_receipt_pallets.fg_product_code
        ,rw_receipt_pallets.grade_code,
        rw_receipt_pallets.holdover,rw_receipt_pallets.holdover_quantity,rw_receipt_pallets.id,rw_receipt_pallets.inspect_type_code,rw_receipt_pallets.intake_header_id,rw_receipt_pallets.intake_headers_production_id,rw_receipt_pallets.inventory_code,
        is_depot_pallet,rw_receipt_pallets.is_mapped,rw_receipt_pallets.is_new_pallet,rw_receipt_pallets.iso_week_code,rw_receipt_pallets.load_detail_id,rw_receipt_pallets.marketing_variety_code,rw_receipt_pallets.n_labels_printed,
        rw_receipt_pallets.oldest_pack_date_time,rw_receipt_pallets.old_pack_code,rw_receipt_pallets.order_number,rw_receipt_pallets.organization_code,rw_receipt_pallets.pallet_format_product_code,rw_receipt_pallets.pallet_format_product_id,
        0 as pallet_id,rw_receipt_pallets.pallet_label_code,rw_receipt_pallets.pallet_number,rw_receipt_pallets.pallet_reno_ref,rw_receipt_pallets.pallet_template_id,
        '' as pallet_type_code,rw_receipt_pallets.party_name,rw_receipt_pallets.pc_code,rw_receipt_pallets.pick_reference_code, rw_receipt_pallets.ppecb_inspection_id,rw_receipt_pallets.process_status,rw_receipt_pallets.production_run_id,
        rw_receipt_pallets.pt_product_characteristics,rw_receipt_pallets.qc_result_status,rw_receipt_pallets.qc_status_code,rw_receipt_pallets.remark,rw_receipt_pallets.reprint_acknowledged_by,rw_receipt_pallets.reprint_acknowledged_date_time,
        rw_receipt_pallets.rw_create_datetime,null as rw_receipt_datetime,null as rw_receipt_intake_headers_production_id,rw_receipt_pallets.rw_run_id,rw_receipt_pallets.season_code,
        rw_receipt_pallets.size_count_code,rw_receipt_pallets.store_type_code,rw_receipt_pallets.target_market_code,rw_receipt_pallets.updated_at,rw_receipt_pallets.updated_by,rw_receipt_pallets.zero_printed_carton_labels, '' as reworks_action,
        '' as person, 0 as rw_reason_id, '' as rw_scrap_datetime, '' as user_name
        from rw_receipt_pallets where rw_receipt_pallets.pallet_number= '#{rw_reclassed_pallet[0].pallet_number}' and rw_receipt_pallets.rw_run_id=#{rw_reclassed_pallet[0].rw_run_id}
    ").map{|c| c.attributes.delete_if {|key, value| RwReclassedPallet.exclude_in_rw_histories_comparisons.include?(key)} }
    rhs_pallet_header = "rw_receipt_pallet"
    if(rw_receipt_pallet.length > 0)
      rw_receipt_pallet_cartons = RwReceiptCarton.find_all_by_pallet_number_and_rw_run_id(rw_receipt_pallet[0]['pallet_number'],rw_receipt_pallet[0]['rw_run_id']).map{|c|
        c.attributes.delete_if {|key, value| RwReclassedCarton.exclude_in_rw_histories_comparisons.include?(key)}
      }
    end

    if(rw_receipt_pallet.length == 0)
      rw_receipt_pallet = RwReceiptPalletsHistory.find_by_sql("
          select 'rw_receipt_pallets_histories' as tablename,rw_receipt_pallets_histories.id as record_id, account_code,	actual_size_count_code,	affected_by_env,	affected_by_function,
          affected_by_program,	build_status,	carton_mark_code,	carton_quantity_actual,	carton_setup_id,	class_code,	cold_store_code,
          commodity_code,	\"substring\"(consignment_note_number, 1,10)  as consignment_note_number,	country_origin_code,	cpp,created_at,	created_by,
          date_time_completed,	date_time_created,		erp_cultivar,	exit_ref,	farm_code,	fg_code_old,fg_product_code, grade_code,
          holdover,	holdover_quantity,	id,		inspect_type_code,	intake_header_id,	intake_headers_production_id,	inventory_code,
          is_depot_pallet,	is_mapped,	is_new_pallet,	iso_week_code,		load_detail_id,	marketing_variety_code,	n_labels_printed,
          oldest_pack_date_time,	old_pack_code,	order_number,	organization_code,	pallet_format_product_code,	pallet_format_product_id,
          pallet_id,	pallet_label_code,	pallet_number,	pallet_reno_ref,	pallet_template_id,	pallet_type_code,
          party_name,	pc_code, pick_reference_code, ppecb_inspection_id,		process_status,	production_run_id,	pt_product_characteristics,
          qc_result_status,	qc_status_code,			remark,	reprint_acknowledged_by,	reprint_acknowledged_date_time,
          rw_create_datetime,	rw_receipt_datetime,	rw_receipt_intake_headers_production_id,rw_run_id,	season_code,	size_count_code,
          store_type_code,	target_market_code,	updated_at,	updated_by,	zero_printed_carton_labels, '' as reworks_action, '' as person,
          0 as rw_reason_id,'' as rw_scrap_datetime,'' as user_name
          from rw_receipt_pallets_histories where rw_receipt_pallets_histories.pallet_number= '#{rw_reclassed_pallet[0].pallet_number}' and rw_receipt_pallets_histories.rw_run_id=#{rw_reclassed_pallet[0].rw_run_id}
      ").map{|c| c.attributes.delete_if {|key, value| RwReclassedPallet.exclude_in_rw_histories_comparisons.include?(key)} }
      rhs_pallet_header = "rw_receipt_pallet_history"
      if(rw_receipt_pallet.length > 0)
        rw_receipt_pallet_cartons = RwReceiptCartonsHistory.find_all_by_pallet_number_and_rw_run_id(rw_receipt_pallet[0]['pallet_number'],rw_receipt_pallet[0]['rw_run_id']).map{|c|
          c.attributes.delete_if {|key, value| RwReclassedCarton.exclude_in_rw_histories_comparisons.include?(key)}
        }
      end
    end

    rw_receipt_pallet[0].store('children',rw_receipt_pallet_cartons) if(rw_receipt_pallet_cartons.length > 0)

    if(discrepancies = Comparer.calc_discrepancies(rw_reclassed_pallet, rw_receipt_pallet,"pallet_number","carton_number"))
      left_diffs = discrepancies['left_diffs']
      right_diffs = discrepancies['right_diffs']
    end

    @discrepancy_report_contents = to_discrep_htm(left_diffs, right_diffs,"rw_reclassed_pallet",rhs_pallet_header,"pallet_number","carton_number",nil,nil,nil)

    render :inline => %{
        <%= @discrepancy_report_contents %>
        }, :layout => 'content'
  end

  def view_pallet_history_diff_to_carton
    rw_reclassed_carton = RwReclassedCarton.find_by_sql("select 'rw_reclassed_cartons' as tablename,rw_reclassed_cartons.id as record_id,account_code,actual_size_count_code,affected_by_env,affected_by_function,affected_by_program,
            carton_fruit_nett_mass,carton_fruit_nett_mass_actual,0 as carton_id,carton_label_code,carton_label_station_code,carton_mark_code,carton_number,
            carton_pack_station_code,carton_template_id,cold_store_code,commodity_code,created_at,created_by,date_time_created,egap,
            erp_cultivar,erp_pack_point,erp_station,exit_date_time,exit_reference,extended_fg_code,farm_code,fg_code_old,
            fg_mark_code,fg_product_code,grade_code,gtin,id,inspection_type_code,intake_header_id,intake_header_number,inventory_code,is_depot_carton,
            is_inspection_carton,iso_week_code,items_per_unit,line_code,mapped_pallet_sequence_id,n_labels_printed,old_pack_code,order_number,organization_code,
            pack_date_time,packer_number,pallet_id,pallet_number,pallet_sequence_number,pc_code,pick_reference,ppecb_inspection_id,product_class_code,
            production_run_code,production_run_id,puc,qc_datetime_in,qc_datetime_out,qc_result_status,qc_status_code,quantity,
            remarks,reprint_acknowledged_by,reprint_acknowledged_date_time,'' as reworks_action,'' as run_track_indicator_code,rw_create_datetime,
            null as rw_receipt_datetime,0 as rw_receipt_intake_headers_production_id,0 as rw_receipt_pallet_id,rw_receipt_unit,
            rw_run_id,season_code,sell_by_code,shift_code,shift_id,spray_program_code,target_market_code,track_indicator_code,treatment_code,treatment_type_code,
            unit_pack_product_code,units_per_carton,updated_at,updated_by,variety_short_long,cast(rw_reclassed_datetime as varchar) as rw_reclassed_datetime  ,
            rw_reclassed_intake_headers_production_id, '' as person,0 as rw_reason_id,'' as rw_scrap_datetime,'' as user_name
            from rw_reclassed_cartons where rw_reclassed_cartons.id=#{params[:id]}").map{|c|
      c.attributes.delete_if {|key, value| RwReclassedCarton.exclude_in_rw_histories_comparisons.include?(key)}
    }
    rw_reclassed_carton[0].delete('rw_run_id')

    carton = Carton.find_by_sql("select id, null as rw_run_start_datetime, null as rw_run_end_datetime,  null as rw_run_status_code, null as rw_run_type_code,
                null as remarks, null as rw_run_name, null as username, null as carton_printing_ip, null as busy,
                'cartons' as tablename,cartons.id as record_id, account_code,actual_size_count_code,affected_by_env,affected_by_function,affected_by_program,carton_fruit_nett_mass,
                carton_fruit_nett_mass_actual,id as carton_id,carton_label_code,carton_label_station_code,carton_mark_code,carton_number,carton_pack_station_code,
                carton_template_id,cold_store_code,commodity_code,created_at,created_by,date_time_created,egap,
                erp_cultivar,erp_pack_point,erp_station,exit_date_time,exit_reference,extended_fg_code,farm_code,fg_code_old,
                fg_mark_code,fg_product_code,grade_code,gtin,id,inspection_type_code,intake_header_id,intake_header_number,inventory_code,is_depot_carton,
                is_inspection_carton,iso_week_code,items_per_unit,line_code,mapped_pallet_sequence_id,n_labels_printed,old_pack_code,order_number,organization_code,
                pack_date_time,packer_number,pallet_id,pallet_number,pallet_sequence_number,pc_code,pick_reference,ppecb_inspection_id,product_class_code,
                production_run_code,production_run_id,puc,qc_datetime_in,qc_datetime_out,qc_result_status,qc_status_code,quantity,
                remarks,reprint_acknowledged_by,reprint_acknowledged_date_time,'' as reworks_action,'' as run_track_indicator_code,rw_create_datetime,
                null as rw_receipt_datetime,0 as rw_receipt_intake_headers_production_id,0 as rw_receipt_pallet_id,rw_receipt_unit,
                0 as rw_run_id,season_code,sell_by_code,shift_code,shift_id,spray_program_code,target_market_code,track_indicator_code,
                treatment_code,treatment_type_code,unit_pack_product_code,units_per_carton,updated_at,updated_by,variety_short_long,
                '' as rw_reclassed_datetime,0 as rw_reclassed_intake_headers_production_id, '' as person,0 as rw_reason_id,'' as rw_scrap_datetime,'' as user_name
                from cartons where carton_number='#{rw_reclassed_carton[0].carton_number}'").map{|c|
          c.attributes.delete_if {|key, value| RwReclassedCarton.exclude_in_rw_histories_comparisons.include?(key)}
        }
    carton[0].delete('rw_run_id')

    if(discrepancies = Comparer.calc_discrepancies(rw_reclassed_carton, carton,"carton_number","carton_number"))
      left_diffs = discrepancies['left_diffs']
      right_diffs = discrepancies['right_diffs']
    end

    @discrepancy_report_contents = to_discrep_htm(left_diffs, right_diffs,"rw_reclassed_carton","carton","carton_number","carton_number",nil,nil,nil)

    render :inline => %{
        <%= @discrepancy_report_contents %>
        }, :layout => 'content'
  end

  def view_pallet_history_diff_to_pallet
    rw_reclassed_pallet = RwReclassedPallet.find_by_sql("
        select 'rw_reclassed_pallets' as tablename, account_code,	actual_size_count_code,	affected_by_env,	affected_by_function,
        affected_by_program,	build_status,	carton_mark_code,	carton_quantity_actual,	carton_setup_id,	class_code,	cold_store_code,
        commodity_code,	\"substring\"(consignment_note_number, 1,10)  as consignment_note_number,	country_origin_code,	cpp,
        created_at,	created_by,	date_time_completed,	date_time_created,		erp_cultivar,	exit_ref,	farm_code,	fg_code_old,
        fg_product_code,		grade_code,	holdover,	holdover_quantity,	id,		inspect_type_code,	intake_header_id,
        intake_headers_production_id,	inventory_code,	is_depot_pallet,	is_mapped,	is_new_pallet,	iso_week_code,		load_detail_id,
        marketing_variety_code,	n_labels_printed,	oldest_pack_date_time,	old_pack_code,	order_number,	organization_code,
        pallet_format_product_code,	pallet_format_product_id,	0 as pallet_id,	pallet_label_code,		pallet_number,
        pallet_reno_ref,	pallet_template_id,	'' as pallet_type_code,	party_name,
        pc_code,		pick_reference_code, ppecb_inspection_id,		process_status,	production_run_id,	pt_product_characteristics,
        qc_result_status,	qc_status_code,			remark,	reprint_acknowledged_by,	reprint_acknowledged_date_time,
        rw_create_datetime,	null as rw_receipt_datetime,	null as rw_receipt_intake_headers_production_id,rw_run_id,	season_code,
        size_count_code,	store_type_code,	target_market_code,		updated_at,	updated_by,	zero_printed_carton_labels,reworks_action,
        '' as person, 0 as rw_reason_id, '' as rw_scrap_datetime, '' as user_name
        from rw_reclassed_pallets where rw_reclassed_pallets.id= '#{params[:id]}'
    ").map{|c| c.attributes.delete_if {|key, value| RwReclassedPallet.exclude_in_rw_histories_comparisons.include?(key)} }

    rw_reclassed_pallet_cartons = RwReclassedCarton.find_all_by_pallet_number_and_rw_run_id(rw_reclassed_pallet[0]['pallet_number'],rw_reclassed_pallet[0]['rw_run_id']).map{|c|
      c.attributes.delete_if {|key, value| RwReclassedCarton.exclude_in_rw_histories_comparisons.include?(key)}
    }
    rw_reclassed_pallet[0].store('children',rw_reclassed_pallet_cartons)
    rw_reclassed_pallet[0].delete('rw_run_id')
    rw_reclassed_pallet[0].delete('pallet_id')

    pallet = Pallet.find_by_sql("select id, null as rw_run_start_datetime, null as rw_run_end_datetime,  null as rw_run_status_code, null as rw_run_type_code,
        null as remarks, null as rw_run_name, null as username, null as carton_printing_ip, null as busy,'pallets' as tablename,pallets.id as record_id, account_code,
        actual_size_count_code,	affected_by_env,	affected_by_function,	affected_by_program,	build_status,	carton_mark_code,
        carton_quantity_actual,	carton_setup_id,	class_code,	cold_store_code,	commodity_code,
        \"substring\"(consignment_note_number, 1,10)  as consignment_note_number,	country_origin_code,	cpp,created_at,	created_by,	date_time_completed,
        date_time_created,		erp_cultivar,	exit_ref,	farm_code,	fg_code_old,
        fg_product_code,		grade_code,	holdover,	holdover_quantity,	id,		inspect_type_code,	intake_header_id,
        intake_headers_production_id,	inventory_code,	is_depot_pallet,	is_mapped,	is_new_pallet,	iso_week_code,		load_detail_id,
        marketing_variety_code,	n_labels_printed,	oldest_pack_date_time,	old_pack_code,	order_number,	organization_code,
        pallet_format_product_code,	pallet_format_product_id,	id as pallet_id,	pallet_label_code,		pallet_number,
        pallet_reno_ref,	pallet_template_id,	'' as pallet_type_code,	party_name,
        pc_code,		pick_reference_code, ppecb_inspection_id,		process_status,	production_run_id,	pt_product_characteristics,
        qc_result_status,	qc_status_code,			remark,	reprint_acknowledged_by,	reprint_acknowledged_date_time,
        rw_create_datetime,	null as rw_receipt_datetime,	null as rw_receipt_intake_headers_production_id,
        0 as rw_run_id,	season_code,	size_count_code,	store_type_code,	target_market_code,
        updated_at,	updated_by,	zero_printed_carton_labels,'' as reworks_action, '' as person, 0 as rw_reason_id, '' as rw_scrap_datetime,'' as user_name
        from pallets where pallets.pallet_number= '#{rw_reclassed_pallet[0].pallet_number}'
    ").map{|c| c.attributes.delete_if {|key, value| RwReclassedPallet.exclude_in_rw_histories_comparisons.include?(key)} }

    if(pallet.length > 0)
      cartons = Carton.find_all_by_pallet_number(pallet[0]['pallet_number']).map{|c|
        c.attributes.delete_if {|key, value| RwReclassedCarton.exclude_in_rw_histories_comparisons.include?(key)}
      }
    end
    pallet[0].store('children',cartons) if(cartons.length > 0)
    pallet[0].delete('rw_run_id')
    pallet[0].delete('pallet_id')

    if(discrepancies = Comparer.calc_discrepancies(rw_reclassed_pallet, pallet,"pallet_number","carton_number"))
      left_diffs = discrepancies['left_diffs']
      right_diffs = discrepancies['right_diffs']
    end

    @discrepancy_report_contents = to_discrep_htm(left_diffs, right_diffs,"rw_reclassed_pallet","pallet","pallet_number","carton_number",nil,nil,nil)

    render :inline => %{
        <%= @discrepancy_report_contents %>
        }, :layout => 'content'
  end

  def build_up_histories
    @content_header_caption = "'search build ups histories'"

    #render :inline => %{
    #<%= build_search_build_ups_histories_form(@hash_object,'submit_build_ups_histories_search','search')%>
    #}, :layout => 'content'

    dm_session[:redirect] = true
    dm_session['se_layout']  = 'content'
    build_remote_search_engine_form("search_build_up_histories.yml", "render_build_up_histories_grid")
  end

  def render_build_up_histories_grid
    @build_ups = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    #@multi_select = "selected_cartons"
    #session[:cartons_returned] = @cartons

    render :inline => %{
        <% grid            = build_build_up_histories_grid(@build_ups)%>
        <% grid.caption    = 'build up histories' %>
        <% grid.height = 550 %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
  end

  def view_build_ups_cartons
    @cartons = BuildUpCarton.find_all_by_build_up_id(params[:id])
    render :inline => %{
            <% grid            = build_build_up_cartons_grid(@cartons)%>
            <% grid.caption    = 'build up cartons' %>
            <% grid.height = 550 %>
            <% grid.group_fields = ['from_pallet_number'] %>
             <% grid.groupable_fields    = ['from_pallet_number'] %>
             <% grid.grouped      = true %>
            <% @header_content = grid.build_grid_data %>

            <%= grid.render_html %>
            <%= grid.render_grid %>
            }, :layout => 'content'
  end

end
