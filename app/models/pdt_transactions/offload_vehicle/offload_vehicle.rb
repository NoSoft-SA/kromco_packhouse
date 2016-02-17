class OffloadVehicle < PDTTransaction
  attr_accessor :tripsheet_no, :pallets_for_trip, :validated_pallets, :not_yet_validated_pallets#, :destination, :current_pallet_index, :offload_trans, :unvalidated_scrolling, :pallets_for_trip, :validated_pallets

  def destination=(arg)
    if(self.tripsheet_no)
      process_var = OffloadVehiclesProcessVar.find_by_tripsheet_number(self.tripsheet_no)
      if(process_var)
        process_var.update_attribute('destination_location',arg) if(!process_var.destination_location)
      else
        process_var = OffloadVehiclesProcessVar.new({:tripsheet_number=>tripsheet_no,:destination_location=>arg})
        process_var.save!
      end
    end
  end

  def destination
    process_var = OffloadVehiclesProcessVar.find_by_tripsheet_number(self.tripsheet_no)
    return process_var.destination_location
  end

  def current_pallet_index=(arg)
    if(self.tripsheet_no)
      process_var = OffloadVehiclesProcessVar.find_by_tripsheet_number(self.tripsheet_no)
      if(process_var)
        process_var.update_attribute('current_pallet_index',arg.to_i)
      else
        process_var = OffloadVehiclesProcessVar.new({:tripsheet_number=>tripsheet_no,:current_pallet_index=>arg.to_i})
        process_var.save!
      end
    end
  end

  def current_pallet_index
    process_var = OffloadVehiclesProcessVar.find_by_tripsheet_number(self.tripsheet_no)
    return process_var.current_pallet_index.to_i
  end

  def offload_vehicle
    if self.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("MENUSELECT").to_s
      build_default_screen
    else
      offload_vehicle_submit
    end
  end

  def join_offload_vehicle_process
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"drop_down",:name=>"tripsheet_number", :label=>"tripsheet",:is_required=>'true',:get_list=>'get_offload_tripsheets',:list_field=>'tripsheet_number',:run_at_server=>"true"}
    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"join offload vehicle process"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"join_process","B1Label"=>"join","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,nil)

    return result_screen_def
  end

  def cancel
    pallets_for_trip.clear if(pallets_for_trip)
    validated_pallets.clear if(validated_pallets)
    not_yet_validated_pallets.clear if(not_yet_validated_pallets)
    OffloadVehiclesProcessVar.destroy_all("tripsheet_number='#{tripsheet_no}' ")
    self.set_transaction_complete_flag
  end

  def process_disrupted?
    if(!OffloadVehiclesProcessVar.find_by_tripsheet_number(self.tripsheet_no))
      self.set_transaction_complete_flag
      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=>"process was completed/terminated by another user"}
      screen_attributes = {:auto_submit=>"false", :content_header_caption=>"transaction complete"}
      buttons = {"B3Label"=>"Clear", "B2Label"=>"Cancel", "B1Submit"=>"offload_vehicle_submit", "B1Label"=>"Submit", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    end
  end
  
  def refresh
    #..........................................
    #..........................................
    if(masg_screen = process_disrupted?)
      return masg_screen
    end
    #..........................................
    #..........................................
    next_state = ValidatePallets.new(self)
    result_screen = next_state.build_default_screen
    self.set_active_state(next_state)
    return result_screen
  end
  
  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box", :name=>"tripsheet_no", :is_required=>"true"}
    field_configs[field_configs.length] = {:type=>"text_box", :name=>"location", :label=>"scan location", :is_required=>"true"}

    screen_attributes = {:auto_submit=>"false", :content_header_caption=>"offload vehicle"}
    buttons = {"B3Label"=>"Clear", "B2Label"=>"Cancel", "B1Submit"=>"offload_vehicle_submit", "B1Label"=>"Submit", "B1Enable"=>"true", "B2Enable"=>"false", "B3Enable"=>"false"}
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return result_screen_def
  end

  def join_process
    @tripsheet_no = self.pdt_screen_def.get_input_control_value("tripsheet_number").to_s.strip
    validation_msg = validate_input
    if validation_msg.to_s.strip != ""
      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=>validation_msg.to_s}
      screen_attributes = {:auto_submit=>"false", :content_header_caption=>"error messages"}
      buttons = {"B3Label"=>"Clear", "B2Label"=>"Cancel", "B1Submit"=>"offload_vehicle_submit", "B1Label"=>"Submit", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    else
      # next state
      vehicle_job = VehicleJob.find_by_vehicle_job_number(@tripsheet_no)
#      self.pallets_for_trip = OffloadVehicleLists::PalletsList.new(@tripsheet_no)#Array.new#
      self.pallets_for_trip = OffloadVehicleLists::PalletsList.new(0,@tripsheet_no,"tripsheet_pallets","tmp/persisted_lists/")#Array.new#
      self.not_yet_validated_pallets = OffloadVehicleLists::InvalidatedPalletsList.new(@tripsheet_no)#Array.new#
      self.validated_pallets = OffloadVehicleLists::ValidatedPalletsList.new(@tripsheet_no)#Array.new#
      self.set_cannot_undo
      next_state = ValidatePallets.new(self)
      result_screen = next_state.build_default_screen
      self.set_active_state(next_state)      
      return result_screen
    end
  end

  def offload_vehicle_submit()
    @tripsheet_no = self.pdt_screen_def.get_input_control_value("tripsheet_no").to_s.strip

    if (process_var = OffloadVehiclesProcessVar.find_by_tripsheet_number(@tripsheet_no))
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, ["tripsheet[#{@tripsheet_no}] is busy being offloaded."])
      @tripsheet_no = nil
      return result_screen
    end
    
    self.destination = self.pdt_screen_def.get_input_control_value("location").to_s.strip
    validation_msg = validate_input
    if validation_msg.to_s.strip != ""
      OffloadVehiclesProcessVar.destroy_all("tripsheet_number='#{tripsheet_no}' ")
      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=>validation_msg.to_s}
      screen_attributes = {:auto_submit=>"false", :content_header_caption=>"error messages"}
      buttons = {"B3Label"=>"Clear", "B2Label"=>"Cancel", "B1Submit"=>"offload_vehicle_submit", "B1Label"=>"Submit", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    else
      # next state
      vehicle_job = VehicleJob.find_by_vehicle_job_number(@tripsheet_no)
      pallets = VehicleJobUnit.find_by_sql("SELECT * FROM vehicle_job_units where vehicle_job_id = '#{vehicle_job.id}'").map { |g| [g.unit_reference_id] }
#      self.pallets_for_trip = OffloadVehicleLists::PalletsList.new(@tripsheet_no)#Array.new#
      self.pallets_for_trip = OffloadVehicleLists::PalletsList.new(0,@tripsheet_no,"tripsheet_pallets","tmp/persisted_lists/")#Array.new#
      self.not_yet_validated_pallets = OffloadVehicleLists::InvalidatedPalletsList.new(@tripsheet_no)#Array.new#
      pallets.each do |pallet_num|
        self.pallets_for_trip.push(pallet_num.to_s)
        self.not_yet_validated_pallets.push(pallet_num.to_s)
      end
      self.validated_pallets = OffloadVehicleLists::ValidatedPalletsList.new(@tripsheet_no)#Array.new#
      #@not_yet_validated_pallets = self.pallets_for_trip
      self.current_pallet_index = 0
      self.set_cannot_undo
      next_state = ValidatePallets.new(self)
      result_screen = next_state.build_default_screen
      self.set_active_state(next_state)
      return result_screen
    end
  end

  def validate_input
    validation_msg = ""
    if has_tripsheet?
      if correct_location?.kind_of?(String)
        # vehicle_job = VehicleJob.find_by_vehicle_job_number(@tripsheet_no)
        validation_msg = correct_location?
      else
        if tripsheet_canceled?
          validation_msg = "Tripsheet has been cancelled!"
        else
          if already_offloaded?
            validation_msg = "Vehicle already offloaded!"
          end
        end
      end
    else
      validation_msg = "Invalid tripsheet"
    end
    return validation_msg
  end

  def correct_location?()
    location = Location.find_by_location_barcode(self.destination)
    if location
      @dest_location_code = location.location_code
      vehicle_job = VehicleJob.find_by_vehicle_job_number(@tripsheet_no)
      #if vehicle_job.planned_location.to_s == self.destination.to_s
      if vehicle_job.planned_location.to_s == location.location_code.to_s
        return true
      else
        return "LOCATION " + self.destination.to_s + " IS NOT THE PLANNED LOCATION!"
      end
    else
      return "LOCATION " + self.destination.to_s + " NOT FOUND"
    end
    #return false
  end

  def has_tripsheet?()
    vehicle_job = VehicleJob.find_by_vehicle_job_number(@tripsheet_no)
    if vehicle_job
      return true
    end
    return false
  end

  def already_offloaded?
    vehicle_job = VehicleJob.find_by_vehicle_job_number(@tripsheet_no)
    if vehicle_job.date_time_offloaded != nil && vehicle_job.date_time_offloaded.to_s.strip != ""
      return true
    end
    return false
  end

  def tripsheet_canceled?()
    vehicle_job = VehicleJob.find_by_vehicle_job_number(@tripsheet_no)
    if vehicle_job.cancel_boolean.to_s.upcase == "TRUE"
      return true
    end
    return false
  end

  def next_pallet()
    self.current_pallet_index = (self.current_pallet_index + 1)
    puts "::::: CURRENT PALLET INDEX :: " + self.current_pallet_index.to_s
    if self.current_pallet_index > self.pallets_for_trip.length - 1
      self.current_pallet_index = self.pallets_for_trip.length - 1
    end
    puts "::::: CURRENT PALLET INDEX 2 :: " + self.current_pallet_index.to_s
    pallet_validation = getPalletValidation()
    return pallet_validation
  end

  def prev_pallet()
    self.current_pallet_index -= 1
    if self.current_pallet_index < 0
      self.current_pallet_index = 0
    end
    pallet_validation = getPalletValidation()
    return pallet_validation
  end

  def getPalletValidation(pallet_num = nil)
    if(self.pallets_for_trip.pallet_locked?(pallet_num))# && ((pallet_user=self.pallets_for_trip.get_pallet_user(pallet_num)) != (self.pdt_screen_def.user)))
      if(pallet_num.is_a?(PalletValidation))
        pallet_user=self.pallets_for_trip.get_pallet_user(pallet_num.pallet_no)
        raise PdtException.new(["user[#{pallet_user}] is busy with this pallet[#{pallet_num.pallet_no}]"])
      else
        pallet_user=self.pallets_for_trip.get_pallet_user(pallet_num)
        raise PdtException.new(["user[#{pallet_user}] is busy with this pallet[#{pallet_num}]"])
      end
    end

    #----------------------------------------------
    if(validated_pallets.include?(pallet_num))
      if(pallet_number.is_a?(PalletValidation))
        raise PdtException.new(["Pallet[#{pallet_num.pallet_no}] has already been validated"])
      else
        raise PdtException.new(["Pallet[#{pallet_num}] has already been validated"])
      end
    end
    #----------------------------------------------

    pallet_validation = nil
    if pallet_num != nil
      for item in self.pallets_for_trip
        if item.is_a?(PalletValidation)
          if item.pallet_no == pallet_num
            pallet_validation = item
            pallet_validation.parent = self #If not,then chaos
          end
        end
      end
      if pallet_validation == nil
        pallet_validation = PalletValidation.new(self, pallet_num)
        a1 = self.pallets_for_trip.slice(0..self.pallets_for_trip.index(pallet_num.to_s))
        a2 = self.pallets_for_trip.slice(self.pallets_for_trip.index(pallet_num.to_s) + 1..self.pallets_for_trip.length - 1)
        a1[a1.length - 1] = pallet_validation
#        self.pallets_for_trip = a1.concat(a2)
        self.pallets_for_trip.assign(a1.concat(a2))
      end
    else 
      pallet_num = self.pallets_for_trip[self.current_pallet_index]

      if(self.pallets_for_trip.pallet_locked?(pallet_num))# && ((pallet_user=self.pallets_for_trip.get_pallet_user(pallet_num)) != (self.pdt_screen_def.user)))
        if(pallet_num.is_a?(PalletValidation))
          pallet_user=self.pallets_for_trip.get_pallet_user(pallet_num.pallet_no)
          raise PdtException.new(["user[#{pallet_user}] is busy with this pallet[#{pallet_num.pallet_no}]"])
        else
          pallet_user=self.pallets_for_trip.get_pallet_user(pallet_num)
          raise PdtException.new(["user[#{pallet_user}] is busy with this pallet[#{pallet_num}]"])
        end
      end

      #----------------------------------------------
      if(validated_pallets.include?(pallet_num))
         if(pallet_num.is_a?(PalletValidation))
          raise PdtException.new(["Pallet[#{pallet_num.pallet_no}] has already been validated"])
         else
          raise PdtException.new(["Pallet[#{pallet_num}] has already been validated"])
         end
      end
      #----------------------------------------------
      
      if pallet_num.is_a?(PalletValidation)
        pallet_validation = pallet_num
        pallet_num = pallet_validation.pallet_no
        pallet_validation.parent = self #If not,then chaos
      else
        pallet_validation = PalletValidation.new(self, pallet_num)
        a1 = self.pallets_for_trip.slice(0..self.pallets_for_trip.index(pallet_num))
        a2 = self.pallets_for_trip.slice(self.pallets_for_trip.index(pallet_num) + 1..self.pallets_for_trip.length - 1)
        a1[a1.length - 1] = pallet_validation
#        self.pallets_for_trip = a1.concat(a2)
        self.pallets_for_trip.assign(a1.concat(a2))
      end
    end
    self.pallets_for_trip.lock_pallet(pallet_num,self.pdt_screen_def.user) if(pallet_num && pallet_validation.is_a?(PalletValidation))
    return pallet_validation
  end

  def pallet_validated(pallet_num)
    #..........................................
    #..........................................
    if(masg_screen = process_disrupted?)
      return masg_screen
    end
    #..........................................
    #..........................................
    self.validated_pallets.push(pallet_num.to_s)
    self.not_yet_validated_pallets.delete(pallet_num.to_s)

#    self.pallets_for_trip.unlock_pallet(pallet_num.to_s)
    
    if all_pallets_validated?
      offload_trans
      build_complete_screen
    else
      pal_val_index = get_pallet_or_pallet_validation_index
      if pal_val_index.index("pallet_number")
        next_state = ValidatePallets.new(self)
        result_screen = next_state.build_default_screen
        self.set_active_state(next_state)
        return result_screen
      else
        pv_index = pal_val_index.split("|")[0].to_i
        pallet_validation = self.pallets_for_trip[pv_index]

        if(self.pallets_for_trip.pallet_locked?(pallet_validation.pallet_no))# && ((pallet_user=self.pallets_for_trip.get_pallet_user(pallet_validation.pallet_no)) != (self.pdt_screen_def.user)))
#          raise "user[#{pallet_user}] is busy with this pallet"
          next_state = ValidatePallets.new(self)
          result_screen = next_state.build_default_screen
          self.set_active_state(next_state)
          return result_screen
        end
        self.pallets_for_trip.lock_pallet(pallet_validation.pallet_no,self.pdt_screen_def.user) if(pallet_validation.pallet_no && pallet_validation.is_a?(PalletValidation))
        pallet_validation.parent = self #If not,then chaos
        next_state = pallet_validation
        result_screen = next_state.validate_pallet()
        self.set_active_state(next_state)
        return result_screen
      end
    end
  end

  def all_pallets_validated?()
#    if @not_yet_validated_pallets.length == 0
#    #if self.validated_pallets.length == self.pallets_for_trip.length
#      return true
#    end
#    return false
    valid = true
    for pallet in self.pallets_for_trip
      if pallet.is_a?(PalletValidation)
        for seq in pallet.sequences
          if seq[:validated] == false
            valid = false
          end
        end
      else
        valid = false
      end
    end
    return valid
  end

  def offload_trans()
    vehicle_job =VehicleJob.find_by_vehicle_job_number(@tripsheet_no)
    vehicle = Vehicle.find(vehicle_job.vehicle_id)

    ActiveRecord::Base.transaction do
      if vehicle_job
        vehicle.in_use = false
        vehicle.save!
        vehicle_job.date_time_offloaded = Time.now.to_formatted_s(:db)
        vehicle_job.save!
        # set date_time_offloaded for vehicle_job_units
        vehicle_job_units = VehicleJobUnit.find_by_sql("SELECT * from vehicle_job_units where vehicle_job_id = '#{vehicle_job.id}'")

        pallets_for_move_stock = Array.new

        for vehicle_job_unit in vehicle_job_units
          vehicle_job_unit.date_time_offloaded = Time.now.to_formatted_s(:db)
          vehicle_job_unit.save!

          pallets_for_move_stock << vehicle_job_unit.unit_reference_id


        end


        Inventory.move_stock("OFFLOAD_VEHICLE", vehicle_job.id.to_s, @dest_location_code.to_s, pallets_for_move_stock) if pallets_for_move_stock.length() > 0

        set_temp_record(:destination,self.destination.to_s)
        set_temp_record(:num_pallets_for_trip,self.pallets_for_trip.length.to_s)
        pallets_for_trip.clear
        validated_pallets.clear
        OffloadVehiclesProcessVar.destroy_all("tripsheet_number='#{tripsheet_no}' ")
      end
    end
    self.set_transaction_complete_flag
  end

  def build_complete_screen()
    field_configs = Array.new
    val = get_temp_record(:num_pallets_for_trip) + " pallet(s) received at location " + get_temp_record(:destination).to_s#self.destination.to_s
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=>val}
    screen_attributes = {:auto_submit=>"false", :content_header_caption=>"transaction complete"}
    buttons = {"B3Label"=>"Clear", "B2Label"=>"Cancel", "B1Submit"=>"offload_vehicle_submit", "B1Label"=>"Submit", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
    return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end

  #===========================================
  # This method is used to get either pallet_number
  # pallet_validation object index in self.pallets_for_trip
  #===========================================
  def get_pallet_or_pallet_validation_index
    ret = ""
    for pallet in self.pallets_for_trip
      if pallet.is_a?(PalletValidation)
        for seq in pallet.sequences
          if seq[:validated] == false
            ret = self.pallets_for_trip.index(pallet).to_s + "|pallet_validation"
          end
        end
      else
        ret = self.pallets_for_trip.index(pallet).to_s + "|pallet_number"
      end
      if ret.strip != ""
        break
      end
    end
    return ret
  end

  def get_stock_item_current_location(inventory_reference)
    location = nil
    stock_item = StockItem.find_by_inventory_reference(inventory_reference)
    if stock_item
      stocks = InventoryTransactionStock.find_by_sql("SELECT * FROM inventory_transaction_stocks where stock_item_id = '#{stock_item.id}' order by id desc")
      if stocks.length > 0
        location = stocks[0].location_to
      else
        location = stock_item.location_code
      end
    end
    return location
  end

  def render_list_validated_pallets
    field_configs = Array.new
    screen_attributes = {:auto_submit=>"false", :content_header_caption=>"pallets already validated"}
    buttons = {"B3Label"=>"", "B2Label"=>"", "B1Submit"=>"", "B1Label"=>"", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}

    if(validated_pallets.length == 0)
      field_configs << {:type=>"text_line", :name=>"output", :value=>"no pallets have been validated"}
    else
      validated_pallets.each do |pallet_number|
        field_configs << {:type=>"text_line", :name=>"pallet", :value=>pallet_number.to_s}
      end
    end

    return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end

  def render_list_invalidated_pallets
    field_configs = Array.new
    screen_attributes = {:auto_submit=>"false", :content_header_caption=>"pallets still to be validated"}
    buttons = {"B3Label"=>"", "B2Label"=>"", "B1Submit"=>"", "B1Label"=>"", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}

    if(not_yet_validated_pallets.length == 0)
      field_configs << {:type=>"text_line", :name=>"output", :value=>"all pallets have been validated"}
    else
      not_yet_validated_pallets.each do |pallet_number|
        field_configs << {:type=>"text_line", :name=>"pallet", :value=>pallet_number.to_s}
      end
    end

    return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end

end