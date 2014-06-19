class Services::SymbolPdt6800Controller < ApplicationController


  require File.dirname(__FILE__) + '/../../../app/models/user.rb'

  #format example: http://localhost:3000/services/symbol_pdt6800/handle_request?trans_type=Quality_Control&mode=1&scancode1=53

  def program_name?
    "symbol_pdt_6800"
  end

  def bypass_generic_security?
    true
  end

  def set_instruction(status, lcd1 = nil, lcd2 = nil, lcd3 = nil, lcd4 = nil, lcd5 = nil, lcd6 = nil)

    instruction = "<'#{@trans_type}' Status=\"'#{status}'\" LCD1=\"'#{lcd1}'\" LCD2=\"'#{lcd2}'\" LCD3=\"'#{lcd3}'\"  LCD4=\"'#{lcd4}'\"  LCD5=\"'#{lcd5}'\" LCD6=\"'#{lcd6}'\" />"

    return instruction.gsub("'", "")
  end

  def handle_request
    begin

      #@trans_type = "RequestServer"
      #render_result(set_instruction(true))
      #return

      @trans_type = params[:trans_type]
      @mode       = params[:mode]
      @scancode1  = params[:scancode1]

      @scancode2  = params[:scancode2]
      @mass       = params[:mass]
      @result     = nil
      @service    = ""
      @user = "system"

      if params[:user] && params[:user] != ""
         @user = params[:user]
      end

      if !@mode ||(@mode && @mode.strip == "")
        @result = set_instruction(true, "MODE ERROR:", "NO MODE SPECIFIED")
      end

      case @mode.to_i
        when 1
          if !@scancode1 ||(@scancode1 && @scancode1.strip == "")
            @result = set_instruction(true, "INVALID.  REASON:", "SCANCODE 1 IS EMPTY")
          else
            @service = "qc_out"
            qc_out
          end
        when 2
          if !@scancode1 ||(@scancode1 && @scancode1.strip == "")
            @result = set_instruction(true, "INVALID.  REASON:", "SCANCODE 1 IS EMPTY")
          elsif !@scancode2 ||(@scancode2 && @scancode2.strip == "")
            @result = set_instruction(true, "INVALID.  REASON:", "SCANCODE 2 IS EMPTY")
          else
            @service = "qc_in"
            qc_in
          end
        when 3

          @service = "enquiry"
          enquiry
        when 4
          if !@scancode1 ||(@scancode1 && @scancode1.strip == "")
            @result = set_instruction(true, "INVALID.  REASON:", "SCANCODE 1 IS EMPTY")
          else
            @service = "rebin_labeling"
            set_rebin_product_num
          end

        else
          @result = set_instruction(true, "MODE ERROR:", "UNSUPPORTED MODE: " + @mode)
      end

      puts "RETURNED: " + @result
      render_result(@result)
    rescue

      handle_error_silently(program_name? + " service: " + @service + " failed. Reported exception: " + $!)
      @result = set_instruction(true, "unexpected exception", "occurred", "contact IT")
      puts $!
      render_result(@result)
    ensure
      ActiveRequest.clear_active_request
    end

  end


  def set_rebin_product_num
    #example:
    #http://localhost:3000/services/symbol_pdt6800/handle_request?trans_type=RequestServer&mode=4&scancode1=3BFF34 _123456

    ActiveRequest.set_active_request(@user,"rebin_num_alloc","set_rebin_product_num","pdt_6800")

    puts "SCANCODE: " + @scancode1
    scans     = nil
    raw_scans = @scancode1.split(",")
    if raw_scans[1]
      scans = raw_scans
    else
      scans = raw_scans[0].split("_")
    end


    station_code = scans[0]
    unique_num   = scans[1]
    puts "UN:" + unique_num.to_s
    #----------
    #validation
    #----------
    if !station_code ||(station_code && station_code.strip == "")
      @result = set_instruction(true, "INVALID.  REASON:", "STATION CODE IS EMPTY")
      return
    elsif !unique_num||(unique_num && unique_num.strip == "")
      @result = set_instruction(true, "INVALID.  REASON:", "UNIQUE NUM IS EMPTY")
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
    devices = ActiveDevice.get_active_run_devices(station_code)
    if devices.length > 1
      @result = set_instruction(true, "INVALID.  REASON:", "MORE THAN ONE", "STATION IN ACTIVE", "DEVICES")
      return
    elsif devices.length == 0||(devices.length == 1 && devices[0].id == nil)
      @result = set_instruction(true, "INVALID.  REASON:", "STATION NOT FOUND", "IN ACTIVE DEVICES", "FOR PRE-REBINNING RUN")
      return
    end

    run_day_line_batch = devices[0].day_line_batch_number
    links              = nil

    links              = ActiveRebinLink.find_all_by_station_code_and_production_run_id(station_code, devices[0].production_run_id)
    if links.length > 1
      @result = set_instruction(true, "INVALID.  REASON:", "MORE THAN ONE", "REBIN LINK", "FOR DAY_LINE_BATCH")
      return
    elsif links.length == 0||(links.length == 1 && links[0].id == nil)
      @result = set_instruction(true, "INVALID.  REASON:", "NO REBIN LINK", "FOR DAY_LINE_BATCH")
      return
    end

    #-------------------
    #create rebin record
    #-------------------
    rebin    = nil
    err_type = Hash.new
    if ! rebin = Rebin.create_rebin(links[0], station_code, unique_num, err_type)
      if err_type[:err_type] == 2
        @result = set_instruction(true, "INVALID.  REASON:", "NUMBER", unique_num, "ALREADY ALLOCATED", "TO STATION FOR RUN:", devices[0].production_run_code.slice(0, 19))
      elsif  err_type[:err_type] == 1
        @result = set_instruction(true, "INVALID.  REASON:", "NUMBER", unique_num, "ALREADY ALLOCATED", "TO STATION AND NOT", "YET PRINTED REBIN")
      elsif  err_type[:err_type] == 3
        @result = set_instruction(true, "INVALID.  REASON:", "TRACK_SLMS_", "INDICATOR", links[0].rebin_template.track_indicator_code, "NOT FOUND", " ")
      elsif  err_type[:err_type] == 4
        @result = set_instruction(true, "INVALID.  REASON:", "NO SHIFT DEFINED FOR", "LINE: " + links[0].line_code, "AND DATE: ", Time.now.strftime("%d/%b/%Y %H:%M:%S"), " ")
      end
      return

    else
      rebin_link = links[0]

      #build return data string
      line1      = "station " + station_code + ":" + unique_num.to_s
      line2      = "run:" + devices[0].production_run_code.slice(0, 14)
      line3      = devices[0].production_run_code.slice(14, devices[0].production_run_code.length()-1)
      line4      = "product:" + rebin_link.rmt_product_code.slice(0, 11)
      line5      = rebin_link.rmt_product_code.slice(11, rebin_link.rmt_product_code.length()-1)
      line6      = "id: " + rebin.bin_number.to_s
      @result    = set_instruction(true, line1, line2, line3, line4, line5, line6)
    end
  end


  def qc_out

    ActiveRequest.set_active_request("system","qc_out","qc_out","pdt_6800")

    carton_num = @scancode1.to_i
    #--------------------
    #various validations
    #--------------------
    carton     = Carton.find_by_carton_number(carton_num)

    if !carton
      @result = set_instruction(true, "INVALID.  REASON:", "CTN:" + @scancode1, "NOT FOUND")
      return
    end

    if !carton.pallet
      @result = set_instruction(true, "INVALID.  REASON:", "NO PALLET FOR CARTON", @scancode1)
      return
    end

    pallet = carton.pallet
    if pallet.qc_status_code && pallet.qc_status_code.upcase == "INSPECTING"
      @result = set_instruction(true, "INVALID.  REASON:", "PALLET CTN", "ALREADY TO PPECB")
      return
    end

    if pallet.qc_status_code && pallet.qc_status_code.upcase == "INSPECTED"
      @result = set_instruction(true, "INVALID.  REASON:", "PALLET", "INSPECTED ALREADY")
      return
    end

    pallet.transaction do
      pallet.qc_status_code       = "INSPECTING"
      carton.qc_status_code       = "INSPECTING"
      carton.is_inspection_carton = true
      carton.qc_datetime_out      = Time.now
      pallet.update
      carton.update
    end

    @result = set_instruction(true, "QC OUT SUCCESSFUL")
    return

  end

  def qc_in

     ActiveRequest.set_active_request("system","qc_in","qc_in","pdt_6800")

    carton_num        = @scancode1.to_i
    carton2_num       = @scancode2.to_i
    inspection_carton = nil
    #--------------------
    #various validations
    #--------------------
    carton1           = Carton.find_by_carton_number(carton_num)
    if !carton1
      @result = set_instruction(true, "INVALID.  REASON:", "CTN 1:" + @scancode1, "NOT FOUND")
      return
    end

    carton2 = Carton.find_by_carton_number(carton2_num)
    if !carton2
      @result = set_instruction(true, "INVALID.  REASON:", "CTN 2:" + @scancode2, "NOT FOUND")
      return
    end

    if !carton1.pallet
      @result = set_instruction(true, "INVALID.  REASON:", "NO PALLET FOR CARTON 1:", @scancode1)
      return
    end

    if !carton2.pallet
      @result = set_instruction(true, "INVALID.  REASON:", "NO PALLET FOR CARTON 2:", @scancode2)
      return
    end

    if !carton1.is_inspection_carton && !carton2.is_inspection_carton
      @result = set_instruction(true, "INVALID.  REASON:", "NEITHER CARTON IS", "AN INSPECTION CARTON")
      return
    else
      if carton1.is_inspection_carton
        inspection_carton = carton1
      else
        inspection_carton = carton2
      end
    end

    if carton1.pallet.id != carton2.pallet.id
      @result = set_instruction(true, "INVALID.  REASON:", "2 CARTONS BELONG TO:", "DIFFERENT PALLETS")
      return
    end

    inspection_carton.transaction do
      inspection_carton.qc_datetime_in = Time.now
      if !inspection_carton.qc_status_code||inspection_carton.qc_status_code.upcase == "INSPECTING"
        inspection_carton.qc_status_code        =nil
        inspection_carton.is_inspection_carton  = false
        inspection_carton.pallet.qc_status_code = "UNINSPECTED"
        inspection_carton.update
        inspection_carton.pallet.update
      end
    end


    @result = set_instruction(true, "QC IN SUCCESSFUL", "PUT CTN: ", inspection_carton.carton_number.to_s, "BACK ON PALLET:", inspection_carton.pallet.pallet_number.to_s)
    return


  end

  def enquiry

    carton_num = @scancode1.to_i
    #--------------------
    #various validations
    #--------------------
    carton     = Carton.find_by_carton_number(carton_num)
    puts carton.to_s
    if !carton
      @result = set_instruction(true, "INVALID.  REASON:", "CTN:" + @scancode1, "NOT FOUND")
      return
    end

    if !carton.pallet
      @result = set_instruction(true, "INVALID.  REASON:", "NO PALLET FOR CARTON", @scancode1)
      return
    end


    pallet_no = carton.pallet.pallet_number.to_s
    @result   = set_instruction(true, "PALLET NO =", pallet_no)
    return
  end


  def render_result(result)
    @result = "<result><![CDATA[" + result
    @result += "]]></result>"
    render :inline => %{
   <%= @result%>
  }

  end


end
