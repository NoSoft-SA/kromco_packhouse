class Services::IntegrationController < ApplicationController


  #format example: http://localhost:3000/services/integration/integrate?type=bin_tipped&record_id=25&model=BinsTipped

  # http://localhost:3000/services/integration/integrate?type=rebin_new&record_id=10000000198476&model=Rebin

  require File.dirname(__FILE__) + '/../../../app/models/user.rb'

  def program_name?
    "integration"
  end

  def bypass_generic_security?
    true
  end

  def get_bin
    run_id = params[:run_id]
    bin_id = params[:bin_id]

    puts params.to_s
    err = false

    #----------
    #Validation
    #----------
    result = "<result>"
    error = ""
    if run_id == nil
      error += "run_id not specd"
      err = true
    end
    if bin_id == nil
      error += "bin_id not specd"
      err = true
    end


    if err == true
      result += error
      render_result(result)
      return
    end

    begin
      #-----------------------------------------------------------------------------------
      #Get the bin from legacy store and create a corresponding bin in our database
      #-----------------------------------------------------------------------------------
      integration_record = nil
      run = ProductionRun.find(run_id.to_i)
      failed_reason = ""
      if failed_reason = BinManager.new(run).get_bin(bin_id)
        result += failed_reason
      else
        result += "OK"
      end
      render_result(result)
    rescue

      err = "An unexpected service exception occured. Reported exception: \n" + $!
      handle_error_silently(err)
      err = "service exception"
      result += err.slice(0..18)
      render_result(result)

    end


  end


  #=====================================================================
  #This method handles requests from the mes world to create integration
  #records (outbox records) to be sent to kromco mes
  #The method call uses REST as the encoding  scheme
  #======================================================================


  def integrate

    type = params[:type]
    record_id = params[:record_id]
    model = params[:model]

    puts params.to_s
    err = false

    #----------
    #Validation
    #----------
    result = "<result>"
    error = ""
    if type == nil
      error += "type not specified. "
      err = true
    end
    if record_id == nil
      error += "record id not specified. "
      err = true
    end

    if model == nil
      error += "model not specified. "
      err = true
    end

    if err == true
      result += "<error>" + error + "</error>"
      render_result(result)
      return
    end

    begin
      ActiveRecord::Base.transaction do
        #-----------------------------------------------------------------------------------
        #Create the integration record, and call the outbox processor to physically send it
        #DEPRECATED
        #-----------------------------------------------------------------------------------
        #integration_record = nil
        #eval "integration_record = " + model + ".find(" + record_id + ")"
        #NewOutboxRecord.new type,integration_record
        #result += "OK"        d
        if type == "rebin_new"
          unless StockItem.find_by_inventory_reference_and_stock_type_code(record_id, 'REBIN')
            Inventory.create_stock(nil, "REBIN", "KROMCO", nil, "PRODUCTION",nil, "PACKHSE", [record_id])
          end

        elsif type == "bin_tipped"
          #Inventory.remove_stock(nil, 'BIN', 'RMT', @bin_order_load.id, location_to, bin_numbers)
          Inventory.move_stock("PRODUCTION", "", "PACKHSE", [record_id])
          Inventory.remove_stock(nil, 'BIN', "PRODUCTION", "", "PACKHSE", [record_id], "KROMCO")
        end
        result += "OK"
        render_result(result)
      end
    rescue

      err = "An unexpected service exception occured. Reported exception: \n" + $!
      puts err
      handle_error_silently(err)

      result += "<error>" + err + "</error>"
      render_result(result)

    end

  end

  def render_result(result)
    @result = result
    @result += "</result>"
    puts "result: " + @result
    render :inline => %{
   <%= @result%>
  }

  end


end
