require "app/models/pdt_transactions/iw_load_vehicle/load_vehicle_lists.rb"

class IwLoadVehicle < PDTTransaction
  
  attr_accessor :vehicle, :scanned_pallets,:scanned_cartons
#  attr_accessor :vehicle_job_no

  def initialize()

  end

  def cancel
    scanned_cartons.clear if(scanned_cartons)
    scanned_pallets.clear if(scanned_pallets)
    LoadVehiclesProcessVar.destroy_all("vehicle_number='#{@vehicle}' ")
  end

  def finished_scanning_pallets?
    qty_pallets_scanned == qty_pallets_required
  end

  def confirm_print_tripsheet
    next_state = ConfirmPrintTripsheet.new(self)
    result_screen = next_state.build_default_screen
    self.set_active_state(next_state)
    result_screen
  end
  
  def refresh
    #----------------------------------------
    if(load_vehicle_completed?)
      return build_complete_screen
    end
    #----------------------------------------
    
    if(self.vehicle)
      process_vars = LoadVehiclesProcessVar.find_by_vehicle_number(vehicle)
      return if(!process_vars)

      #............................................
      return confirm_print_tripsheet if(finished_scanning_pallets?)
      #.............................................
      
      return ScanPallet.new(self).build_default_screen
    end    
    
#    @scanned_pallets = LoadVehicleLists::PalletsList.new(@vehicle)#Array.new
#    @scanned_cartons = LoadVehicleLists::CartonsList.new(@vehicle)#Array.new
#    next_state = ScanPallet.new(self)
#    result_screen = next_state.build_default_screen
#    self.set_active_state(next_state)
#    return result_screen
  end

  def qty_pallets_required=(arg)
    if(self.vehicle)
      process_var = LoadVehiclesProcessVar.find_by_vehicle_number(self.vehicle)
      if(process_var)
        process_var.update_attribute('qty_pallets_required',arg.to_i) if(!process_var.qty_pallets_required)
      else
        process_var = LoadVehiclesProcessVar.new({:vehicle_number=>vehicle,:qty_pallets_required=>arg.to_i})
        process_var.save!
      end
    end
  end

  def qty_pallets_required
    process_var = LoadVehiclesProcessVar.find_by_vehicle_number(self.vehicle)
    return process_var.qty_pallets_required.to_i
  end

  def destination=(arg)
    if(self.vehicle)
      process_var = LoadVehiclesProcessVar.find_by_vehicle_number(self.vehicle)
      if(process_var)
        process_var.update_attribute('destination_location',arg) if(!process_var.destination_location)
      else
        process_var = LoadVehiclesProcessVar.new({:vehicle_number=>vehicle,:destination_location=>arg})
        process_var.save!
      end
    end
  end

  def destination
    process_var = LoadVehiclesProcessVar.find_by_vehicle_number(self.vehicle)
    return process_var.destination_location
  end

  def vehicle_job_no=(arg)
    if(self.vehicle)
      process_var = LoadVehiclesProcessVar.find_by_vehicle_number(self.vehicle)
      if(process_var)
        process_var.update_attribute('vehicle_job_no',arg) if(!process_var.vehicle_job_no) # can only be set once in this entire
                                                                                           # process for many users i.e.once 1st user
                                                                                           # creates it,it cannot be updated
      else
        process_var = LoadVehiclesProcessVar.new({:vehicle_number=>vehicle,:vehicle_job_no=>arg})
        process_var.save!
      end
    end
  end

  def vehicle_job_no
    process_var = LoadVehiclesProcessVar.find_by_vehicle_number(self.vehicle)
    return process_var.vehicle_job_no
  end

  def qty_pallets_scanned=(arg)
    if(self.vehicle)
      process_var = LoadVehiclesProcessVar.find_by_vehicle_number(self.vehicle)
      if(process_var)
        process_var.update_attribute('qty_pallets_scanned',arg.to_i)
      else
        process_var = LoadVehiclesProcessVar.new({:vehicle_number=>vehicle,:qty_pallets_scanned=>arg.to_i})
        process_var.save!
      end
    end
  end

  def qty_pallets_scanned
    process_var = LoadVehiclesProcessVar.find_by_vehicle_number(self.vehicle)
    return process_var.qty_pallets_scanned.to_i
  end

  def load_vehicle
    if self.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("MENUSELECT").to_s
      build_default_screen
    else
      load_vehicle_submit
    end
  end

  def scan_pallet
    if(self.vehicle)
      next_state = ScanPallet.new(self)
      result_screen = next_state.scan_pallet
      self.set_active_state(next_state)
      return result_screen
    end

    field_configs = []
    field_configs << {:type=>"text_line", :name=>"output",:value=>"You must first scan a vehicle"}
    screen_attributes = {:auto_submit=>"false",:content_header_caption=>""}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"load_vehicle_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end

  def build_default_screen
     field_configs = Array.new
     field_configs[field_configs.length] = {:type=>"text_box",:name=>"vehicle",:is_required=>"true"}
     field_configs[field_configs.length] = {:type=>"text_box",:name=>"qty_pallets",:is_required=>"true", :required_type=>"number"}
     field_configs[field_configs.length] = {:type=>"drop_down",:name=>"destination",:is_required=>"true",:list => ", ,PACKHSE,RA_10,RA_1TO5,RA_6AND7,RA_8AND9,REWORKS,BAGGING,PART_PALLETS,CA_CDE_CA_D_35"}
     
     screen_attributes = {:auto_submit=>"true",:content_header_caption=>"load vehicle"}
     buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"load_vehicle_submit","B1Label"=>"Submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
     plugins = nil
     result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
     
     return result_screen_def
  end

  def join_load_vehicle_process
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"drop_down",:name=>"vehicle", :label=>"vehicle",:is_required=>'true',:get_list=>'get_loading_vehicle_numbers',:list_field=>'vehicle_number',:run_at_server=>true}
    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"join load vehicle process"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"join_process","B1Label"=>"join","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,nil)

    return result_screen_def
  end

  def join_process
    self.vehicle = self.pdt_screen_def.get_input_control_value("vehicle").to_s.strip
    if (!(veh = Vehicle.find_by_vehicle_code(self.vehicle)))
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, ["vehicle[#{self.vehicle}] does not exist."])
      return result_screen
    end

    #----------------------------------------
    if(load_vehicle_completed?)
      return build_complete_screen
    end
    #----------------------------------------

    #.............................................
      return confirm_print_tripsheet if(finished_scanning_pallets?)
    #.............................................
    
    @scanned_pallets = LoadVehicleLists::PalletsList.new(vehicle)#Array.new
    @scanned_cartons = LoadVehicleLists::CartonsList.new(vehicle)#Array.new
    next_state = ScanPallet.new(self)
    result_screen = next_state.build_default_screen
    self.set_active_state(next_state)
    return result_screen
  end

  def load_vehicle_submit
    @vehicle = self.pdt_screen_def.get_input_control_value("vehicle").to_s.strip

    if (process_var = LoadVehiclesProcessVar.find_by_vehicle_number(self.vehicle))
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, ["vehicle[#{process_var.vehicle_number}] is already being loaded."])
      @vehicle = nil
      return result_screen
    end
    self.qty_pallets_required = self.pdt_screen_def.get_input_control_value("qty_pallets").to_i
    validation_error = validate_input
    if validation_error.to_s.strip != ""
      # build error screen
      puts  " Validation Errors :: " + validation_error.to_s
      field_configs = Array.new
      error_lines = validation_error.to_s.split("!")
      error_lines.each do |err_line|
        field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>err_line}
      end
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"error messages"}
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"load_vehicle_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    else
      @scanned_pallets = LoadVehicleLists::PalletsList.new(@vehicle)#Array.new
      @scanned_cartons = LoadVehicleLists::CartonsList.new(@vehicle)#Array.new
      self.qty_pallets_scanned = 0
#      self.destination = self.pdt_screen_def.get_input_control_value("destination")
      next_state = ScanPallet.new(self)
      result_screen = next_state.build_default_screen
      self.set_active_state(next_state)
      return result_screen
    end
  end

  def validate_input
    validation_error = ""
    veh = Vehicle.find_by_vehicle_code(@vehicle)
    if veh == nil
      validation_error += "vehicle specified does not exist.!"
    end    
    location = Location.find_by_location_code(self.pdt_screen_def.get_input_control_value("destination").strip)
    if location
#      @location_code = location.location_code
      self.destination = location.location_code
    else
      validation_error += "location does not exist.!"
    end
    if self.qty_pallets_required.to_i == 0
      validation_error += "qty_pallets must be greater than 0!"
    end
    validation_error += " " + validate_vehicle_in_use
    return validation_error
  end

  def validate_vehicle_in_use
    #@vehicle = self.pdt_screen_def.get_input_control_value("vehicle")
    veh = Vehicle.find_by_vehicle_code(@vehicle)
    exists = false
    ret = ""
    if veh
      if veh.in_use
        exists = true
      end
    else
       return "vehicle not found"
    end
    if exists == true
      ret += "vehicle already in use"
    end
    return ret
  end

  def complete_trans(repeat=false)
    ActiveRecord::Base.transaction do
      #creating vehicle_jobs record
      vehicle = Vehicle.find_by_vehicle_code(@vehicle)
      vehicle.in_use = true
      vehicle.update
      vehicle_job = VehicleJob.new
      
      self.vehicle_job_no = "TRP" + MesControlFile.next_seq_web(4).to_s
      vehicle_job.vehicle_job_number = self.vehicle_job_no
      vehicle_job.date_time_loaded = Time.now.to_formatted_s(:db)
      vehicle_job.vehicle_id = vehicle.id if vehicle
      vehicle_job.operator = self.pdt_screen_def.user
      vehicle_job.planned_location = self.destination#@location_code
      if vehicle_job.save
        #creating vehicle_job_units records
        self.scanned_pallets.each do |pallet_number|
          puts "SCANNED PALLETS ENTERED"
          vehicle_job_unit = VehicleJobUnit.new
          vehicle_job_unit.unit_reference_id = pallet_number
          vehicle_job_unit.vehicle_job_id = vehicle_job.id
          vehicle_job_unit.date_time_loaded = Time.now.to_formatted_s(:db)
          vehicle_job_unit.create
        end
        
        # do inventory_transaction for each pallet
        Inventory.move_stock('LOAD_VEHICLE',vehicle_job.id.to_s,'IN_TRANSIT_' + self.destination ,@scanned_pallets)
      end

      if(repeat)
        set_repeat_process_flag
#        return nil
      end

      scanned_cartons.clear
      scanned_pallets.clear
      LoadVehiclesProcessVar.destroy_all("vehicle_number='#{@vehicle}' ")
#      self.vehicle_job_no = vehicle_job.vehicle_job_number.to_s
      set_temp_record(:vehicle_job_no,vehicle_job.vehicle_job_number.to_s)
    end
  end

  def get_stock_item_current_location(stock_item)
    location = nil
    stocks = InventoryTransactionStock.find_by_sql("SELECT * FROM inventory_transaction_stocks where stock_item_id = '#{stock_item.id}' order by id desc")
    if stocks.length > 0
      location = stocks[0].location_to
    else
      location = stock_item.location_code
    end
    return location
  end

  def load_vehicle_completed?
    if(tripsheet = VehicleJob.find_by_sql(" select *
                                            from vehicle_jobs
                                            join vehicles on vehicles.id=vehicle_jobs.vehicle_id
                                            where vehicles.vehicle_code='#{@vehicle}' and vehicles.in_use is true")[0])
      set_temp_record(:operator,tripsheet.operator)
      return true
    end

    if(!(process_var = LoadVehiclesProcessVar.find_by_vehicle_number(self.vehicle)))
      set_temp_record(:cancelled,true)
      return true
    end
    return false
  end

  def build_complete_screen
    set_transaction_complete_flag
    field_configs = Array.new
    if(get_temp_record(:operator))
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"operator:#{get_temp_record(:operator)}"}
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"has completed the transaction successfully"}
    elsif(get_temp_record(:cancelled))
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=>"process was terminated by another user"}
    end
    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"transaction complete"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"load_vehicle_submit","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end

end