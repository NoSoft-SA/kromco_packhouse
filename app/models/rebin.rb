class Rebin



  #----------------------------------------------------------------
  #Map attribute readers from other colums to native fields on this class
  #----------------------------------------------------------------

  def Rebin.create_rebin(rebin_link, station_code, unique_num, result)
    require 'date'

    is_dp_line = false
    is_dp_line = true if station_code.slice(0,2).to_i >= 41 && station_code.slice(0,2).to_i <= 48



    if Bin.find_by_print_number_and_rebin_status_and_binfill_station_code(unique_num, "not printed", station_code)
      result[:err_type] = 1
      return nil
    end

    if Bin.find_by_print_number_and_production_run_rebin_id_and_binfill_station_code(unique_num, rebin_link.production_run_id, station_code)
      result[:err_type] = 2
      return nil
    end

    run = ProductionRun.find(rebin_link.production_run_id)


     rebin = Bin.new
     rebin_num   = MesControlFile.next_seq_web(MesControlFile::BIN)
     template    = rebin_link.rebin_template
     rebin.bin_number         = rebin_num
     rebin.binfill_station_code = station_code

     #default & for NON DP
     track_slms_indicator_rec = TrackSlmsIndicator.find_by_track_slms_indicator_code(rebin_link.rebin_template.track_indicator_code)

     if is_dp_line && run.track_indicator_id
       track_slms_indicator_rec = TrackSlmsIndicator.find(run.track_indicator_id)
     end

     if  track_slms_indicator_rec == nil
       result[:err_type] = 3
      return nil
     else
       rebin.track_indicator1_id = track_slms_indicator_rec.id
     end

    #default & for non DP
    rmt_product =    RmtProduct.find_by_rmt_product_code(rebin_link.rebin_template.rmt_product_code)
    ripe_point_code = rmt_product.ripe_point_code #default
    if run.ripe_point_id #for DP rebins
      ripe_point_code = run.ripe_point.ripe_point_code
    end

    if is_dp_line
      rmt_product = RmtProduct.create_if_needed("rebin",rmt_product.variety.commodity.commodity_group.commodity_group_code,
                                                rmt_product.commodity_code,
                                                rmt_product.variety_code,
                                                rmt_product.size_code,
                                                rmt_product.product_class_code,
                                                ripe_point_code,
                                                rmt_product.treatment_code,"KROMC")
    end

    rebin.rmt_product_id =   rmt_product.id
    farm = Farm.find_by_farm_code(rebin_link.production_run.farm_code)
    rebin.farm_id = farm.id
    rebin.production_run_rebin_id = rebin_link.production_run_id
    rebin.rebin_date_time = Time.now()
    pack_material_product = PackMaterialProduct.find_by_pack_material_product_code(rebin_link.rebin_template.product_code_pm_bintype)
    rebin.pack_material_product_id = pack_material_product.id
    rebin.rebin_track_indicator_code =  rebin_link.rebin_template.track_indicator_code
    rebin.season_code = rebin_link.production_run.production_schedule.season_code
    rebin.print_number = unique_num
    rebin.rebin_status = "not printed"
    #run.getFarm_code() + "_" + rebin_template.getTrack_indicator_code ();
    rebin.orchard_code = rebin_link.production_run.farm_code + "_" + template.track_indicator_code
    shift = Shift.current_shift?(rebin_link.line_code)

    #if shift == nil
    #  result[:err_type] = 4
    #  return nil
    #else
    #  rebin.shift_id = shift.id
    #end

    rebin.create
    return rebin

  end


  def Rebin.create_rebin_old(rebin_link, station_code, unique_num, result)
    require 'date'

#    if Rebin.find_by_print_number_and_rebin_status_and_binfill_station_code(unique_num,"not printed",station_code)
#      return nil
#    end
    if Rebin.find_by_print_number_and_rebin_status_and_binfill_station_code(unique_num, "not printed", station_code)
      result[:err_type] = 1
      return nil
    end

    if Rebin.find_by_print_number_and_production_run_id_and_binfill_station_code(unique_num, rebin_link.production_run_id, station_code)
      result[:err_type] = 2
      return nil
    end

    rebin       = Rebin.new
    rebin_num   = MesControlFile.next_seq_web(2)

    template    = rebin_link.rebin_template
    #set schedule time attributes
    label_setup = rebin_link.rebin_label_setup
    template.export_attributes(rebin)

    #runtime attributes
    rebin.rebin_number         = rebin_num

    rebin.binfill_station_code = station_code
    rebin.date_time_created    = Time.now
    rebin.transaction_date     = Time.now
    rebin.farm_id              = rebin_link.production_run.farm_code
    rebin.iso_week_code        = iso_week = Date.today.cweek.to_s
    rebin.production_run_code  = rebin_link.production_run.production_run_code
    rebin.production_run_id    = rebin_link.production_run_id
    rebin.rebin_status         = "not printed"
    rebin.line_code            = rebin_link.production_run.line_code
    rebin.erp_bin_type         = template.product_code_pm_bintype
    rebin.rmt_description      = label_setup.rmt_description
    rebin.rmt_code             = label_setup.rmt_code
    puts "LS: " + label_setup.id.to_s
    puts "LS: " + label_setup.pc_code.to_s

    rebin.pc_code = label_setup.pc_code.to_s
    puts "RB: " + rebin.pc_code
    rebin.print_number = unique_num
    #run.getFarm_code() + "_" + rebin_template.getTrack_indicator_code ();
    rebin.orchard_code = rebin_link.production_run.farm_code + "_" + template.track_indicator_code
    rebin.line_code    = rebin_link.production_run.line_code
    rebin.create

    return rebin

  end





end
