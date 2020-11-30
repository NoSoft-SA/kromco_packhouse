class Services::IntegrationController < ApplicationController


  #format example: http://localhost:3000/services/integration/integrate?type=bin_tipped&record_id=25&model=BinsTipped

  # http://localhost:3000/services/integration/integrate?type=rebin_new&record_id=10000000198476&model=Rebin

  require File.dirname(__FILE__) + '/../../../app/models/user.rb'
  require 'json'

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

  def get_bin_info
    if mes_bin = Bin.find_by_sql("select vb.*, f.remark1_ptlocation as puc_code
    from vwbins vb
    join farms f on f.farm_code=vb.farm_code
    where vb.bin_number='#{params[:bin_number]}'")[0]
      result = mes_bin.attributes
    else
      result = {:error => "Bin #{params[:bin_number]} not found in external system"}
    end
    render :json => result.to_json
  end

  def get_delivery_info
    if mes_delivery = Delivery.find_by_sql("select o.orchard_code
    ,d.farm_code,d.puc_code,d.rmt_variety_code,d.commodity_code,d.delivery_number_preprinted,d.delivery_number,d.delivery_description
    ,d.pack_material_product_code,d.date_delivered,d.date_time_picked,d.quantity_full_bins,d.quantity_empty_units,d.quantity_damaged_units
    ,d.drench_delivery,d.sample_bins,d.mrl_required,d.truck_registration_number,d.delivery_status,d.season_code,d.residue_free
    ,d.mrl_result_type,d.rmt_product_id,d.destination_complex, f.remark1_ptlocation as puc_code
    from deliveries d
    join orchards o on o.id=d.orchard_id
    join farms f on f.id=d.farm_id
    where d.delivery_number='#{params[:delivery_number]}'")[0]
      result = mes_delivery.attributes
    else
      result = {:error => "Delivery #{params[:delivery_number]} not found in external system"}
    end

    render :json => result.to_json
  end

  def can_bin_be_tipped
    result = {:can_tip_bin => true, :msg => 'ok'}

    if !(bin = Bin.find_by_bin_number(params[:bin_number]))
      result = {:can_tip_bin => false, :msg => "Bin #{params[:bin_number]} not found in external system"}
    elsif !bin.weight
      result = {:can_tip_bin => false, :msg => 'Bin has not been weighed'}
    elsif(VehicleJob.find(:first, :select => 'vehicle_jobs.vehicle_job_number',
                      :conditions => "bins.bin_number='#{params[:bin_number]}' and vehicle_jobs.date_time_offloaded is null",
                      :joins => 'join vehicle_job_units on vehicle_job_units.vehicle_job_id=vehicle_jobs.id
                                join bins on vehicle_job_units.unit_reference_id=bins.bin_number',
                      :order => 'vehicle_jobs.id DESC'))
      result = {:can_tip_bin => false, :msg => 'Bin is on an active tripsheet'}
    elsif !mrl_passed?(params[:bin_number])
      result = {:can_tip_bin => false, :msg => 'Failed mrl results'}
    end

    render :json => result.to_json
  end

  def mrl_passed?(bin_number)
    bin = Bin.find_by_sql("SELECT
    	bins.bin_number AS bin_id,
    	bins.season_code,
      bins.orchard_code,
    	bins.weight AS bin_weight,
    	bins.delivery_id,
    	bins.production_run_tipped_id,
    	farms.farm_code,
    	bins.exit_ref,
    	track_slms_indicators.track_slms_indicator_code AS track_indicator_code,
    	concat('PC',pc_codes.pc_code,'_',pc_codes.pc_name) as pc_code,
    	pc_codes.pc_code as pc_code_num,
    	rmt_products.variety_code,
    	rmt_products.commodity_code,
    	rmt_products.treatment_code,
    	rmt_products.product_class_code AS class_code,
    	ripe_points.cold_store_type_code AS cold_store_code,
    	bins.id, commodities.grower_commitment_required,
    	rmt_products.rmt_product_type_code,
    	rmt_products.size_code,
    	ripe_points.ripe_point_code
    	FROM
    	public.bins,
    	public.rmt_products,
    	public.ripe_points,
    	public.pc_codes,
    	public.farms,
    	public.track_slms_indicators,
    	public.commodities
    	WHERE
    	bins.rmt_product_id = rmt_products.id AND
    	bins.farm_id = farms.id AND
    	bins.track_indicator1_id = track_slms_indicators.id AND
    	rmt_products.ripe_point_id = ripe_points.id AND
    	pc_codes.pc_code = ripe_points.pc_code_code AND
    	rmt_products.commodity_code = commodities.commodity_code and
    	bins.bin_number = '#{bin_number}'")[0]

    if bin && (bin.grower_commitment_required == true|| bin.grower_commitment_required == 't')
      Set.new(Delivery.find_by_sql("SELECT
                              mrl_results.mrl_result
                              FROM
                              public.deliveries,
                              public.grower_commitments,
                              public.spray_program_results,
                              public.mrl_results,
                              public.seasons
                              WHERE
                              deliveries.farm_code = grower_commitments.farm_code AND
                              deliveries.rmt_variety_code = spray_program_results.rmt_variety_code AND
                              deliveries.season_code = seasons.season_code AND
                              spray_program_results.grower_commitment_id = grower_commitments.id AND
                              mrl_results.spray_program_result_id = spray_program_results.id AND
                              seasons.season = grower_commitments.season AND
                              deliveries.id = #{bin.delivery_id} and
                              spray_program_results.cancelled is not true and
                              upper(spray_program_results.spray_result) = 'PASSED'").map { |r| r.mrl_result}).subset?(Set.new %w[PENDING PASSED])
    else
      false
    end
  end

  def get_run_treatment_codes
    treatment_codes = Treatment.find_by_sql("select treatment_code from treatments").map { |t| t.treatment_code }
    render :json => treatment_codes.to_json
  end

  def get_run_track_indicator_codes
    track_indicator_codes = TrackIndicator.find_by_sql("select  id,track_indicator_code from track_indicators ").map { |t| t.track_indicator_code }
    render :json => track_indicator_codes.to_json
  end

  def get_run_ripe_point_codes
    condition = " where ripe_point_code='#{params['ripe_point_code']}'" if params['ripe_point_code']
    ripe_points = RipePoint.find_by_sql("select ripe_point_code, pc_codes.pc_name from pc_codes join ripe_points on ripe_points.pc_code_id=pc_codes.id #{condition}").map { |r| [r.ripe_point_code, r.pc_name] }
    render :json => ripe_points.to_json
  end
end
