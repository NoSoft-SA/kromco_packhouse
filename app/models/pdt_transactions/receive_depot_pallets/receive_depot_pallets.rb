class ReceiveDepotPallets < PDTTransaction
  attr_accessor :scanned_pallets ,:intake_header_number ,:depot_pallets,:intake_header_id

  def initialize()
    @scanned_pallets = Hash.new
    @depot_pallets = Array.new
  end




  def get_validated_pallets
    valid_pallets = Array.new
    self.scanned_pallets.each do |key,value|
      valid_pallet = true
       value.sequences.each do |seq|
         if(seq[:validated].to_s == 'false')
           valid_pallet = false
         end
       end
       valid_pallets.push(key) if valid_pallet
     end
   return valid_pallets

  end

  def get_not_yet_validated_pallets

    return self.depot_pallets - get_validated_pallets()
    
  end

  def show_validated_pallets
     list = get_validated_pallets()
     
     return build_pallet_list_screen(list,"validated pallets")

  end

  def show_not_yet_validated_pallets
     list = get_not_yet_validated_pallets()
     return build_pallet_list_screen(list,"pallets not yet validated")
  end


  def build_pallet_list_screen(pallet_list,caption)
    field_configs = Array.new
    pallet_list.each do |pallet_num|
      field_configs[field_configs.length] = {:name=>'pallet_num',:type=>'text_line',:value=>pallet_num.to_s,:is_required=>'true'}
    end

    buttons = {:B1Label=>"Submit",:B1Enable=>"false",:B1Submit=>"",:B2Label=>"",:B2Enable=>"false",:B2Submit=>"",:B3Label=>"",:B3Enable=>"false",:B3Submit=>""}
    screen_attributes ={:content_header_caption=> caption,:auto_submit=>"false"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end


  def validated_pallets
    valid_pallet_count = 0
    self.scanned_pallets.each do |key,value|
      valid_pallet = true
       value.sequences.each do |seq|
         if(seq[:validated].to_s == 'false')
           valid_pallet = false
         end
       end
       valid_pallet_count += 1 if valid_pallet
     end
   return valid_pallet_count

  end

  def build_default_screen

    field_configs = Array.new
      field_configs[field_configs.length] = {:name=>'intake_header_number',:type=>'text_box',:label=>'scan intake header',:is_required=>'true',:scan_field => true, :submit_form => true}

    
    buttons = {:B1Label=>"Submit",:B1Enable=>"true",:B1Submit=>"receive_depot_pallets_submit",:B2Label=>"",:B2Enable=>"false",:B2Submit=>"",:B3Label=>"",:B3Enable=>"false",:B3Submit=>""}
    screen_attributes ={:content_header_caption=>"scan intake header",:auto_submit=>"false"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end

  def receive_depot_pallets
    build_default_screen
  end

  def receive_depot_pallets_submit
    if (error = validate_input) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,error)
      return result_screen
    else

      self.intake_header_number = self.get_temp_record(:intake_header_number)
      for depot_pallet in self.get_temp_record(:depot_pallets)
        #self.depot_pallets.push(depot_pallet.depot_pallet_number)
        self.scanned_pallets.store(depot_pallet.depot_pallet_number, SequenceValidator.new(self, depot_pallet.depot_pallet_number))

      end

      err_screen = receive_load_trans
      if err_screen
        return err_screen
      else
        return build_completed_screen
      end

      
#      next_state = PalletReceiver.new(self)
#      self.set_active_state(next_state)
#      return next_state.build_default_screen
    end
  end

  def validate_input
    scanned_intake_header_number = self.pdt_screen_def.get_input_control_value("intake_header_number")

    if !scanned_intake_header_number.is_numeric?
       error = [scanned_intake_header_number + " is not a number"]
        return error
    end

    intake_headers = IntakeHeader.find_by_sql("select * from intake_headers where intake_header_number='#{scanned_intake_header_number}'")

    
    if intake_headers.length > 0

      if(intake_headers[0].header_status.to_s == "MAPPING_COMPLETE")
        self.set_temp_record(:intake_header_number, scanned_intake_header_number)
        self.set_temp_record(:depot_pallets, intake_headers[0].depot_pallets)
        self.intake_header_id =  intake_headers[0].id
        return nil
      elsif(intake_headers[0].header_status.to_s == "LOAD_RECEIVED" || (intake_headers[0].header_status.to_s.index("EDI") != nil) && intake_headers[0].header_status.to_s.upcase != "EDI_RECEIVED" )
        error = ["Load already received "]
        return error
      else
        error = ["Mapping not complete "]
        return error
      end
    else
      error = ["Invalid intake header was scanned "]
      return error
    end
    
    return nil
  end

 def get_total_cartons
   total_ctns = 0
     self.scanned_pallets.each do |key,value|
      total_ctns +=   value.get_real_total_cartons()
     end
   return total_ctns
 end
  

  def all_scanned_pallets_validated?
     self.scanned_pallets.each do |key,value|
       value.sequences.each do |seq|
         if(seq[:validated].to_s == 'false')
           return false
         end
       end
     end
   return true
  end


  def all_pallets_validated?
       return all_pallets_scanned? && all_scanned_pallets_validated?
   end

  def all_pallets_scanned?
    return (self.depot_pallets.length() - validated_pallets()) == 0

  end
  
  def wrong_cartons_amount?(header)
         qty_cartons = get_total_cartons()
         if header.qty_cartons != qty_cartons
           return  PDTTransaction.build_msg_screen_definition(nil,nil,nil,["header specifies " + header.qty_cartons.to_s + " cartons"," but captured pallets contains " + qty_cartons.to_s] )
         else
           return nil
         end
  end

#  def resync_in_memory_sequences (persisted_sequences)
#     self.scanned_pallets.each do |key,value|
#          value.sequences.each do |seq|
#            persisted_seq = persisted_sequences.find{|s| s.id == seq[:id]}
#            seq[:production_run_id] = persisted_seq.production_run_id
#            seq[:production_run_code] = persisted_seq.production_run_code
#            seq[:erp_cultivar] = persisted_seq.erp_cultivar
#          end
#      end
#
#  end
  

  def receive_load_trans

     intake_header = IntakeHeader.find_by_intake_header_number(self.intake_header_number)
     wrong_ctns_amount_msg = wrong_cartons_amount?(intake_header)
     return  wrong_ctns_amount_msg if wrong_ctns_amount_msg

      ActiveRecord::Base.transaction do
        created_pallet = nil

        intake_header.user = self.pdt_screen_def.user

        #persisted_sequences = intake_header.reverse_engineer_schedules_and_runs

        #update the in-memory sequences with the production_run_id,code and erp_cultivar fields
        #resync_in_memory_sequences(persisted_sequences)
        pallets_for_create_stock = Array.new
        pallets_for_move_stock = Array.new
        self.scanned_pallets.each do |key,value|
          created_pallet = Pallet.create_pallet_from_depot(value.sequences,intake_header,key)
          if !StockItem.find_by_inventory_reference(created_pallet.pallet_number)
            pallets_for_create_stock << created_pallet.pallet_number
          else
            pallets_for_move_stock << created_pallet.pallet_number
          end
          
        end

        intake_header.update_attribute(:header_status, "LOAD_RECEIVED")

         Inventory.create_stock(nil, "PALLET", nil, nil, "DEPOT_RECEIPTS", intake_header.consignment_note_number.to_s, intake_header.location_code, pallets_for_create_stock) if  pallets_for_create_stock.length() > 0
         Inventory.move_stock("DEPOT_RECEIPTS", intake_header.consignment_note_number, intake_header.location_code, pallets_for_move_stock) if pallets_for_move_stock.length() > 0


         return nil

      end
      return nil
  end

  def build_completed_screen
    msgs = Array.new
    self.scanned_pallets.each do |key,value|
      msgs.push("pallet[" + key.to_s + "] was successfully received")
    end

    result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,msgs)
    return result_screen
  end
end
