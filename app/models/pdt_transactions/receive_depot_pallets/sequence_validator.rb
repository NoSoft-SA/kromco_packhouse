# To change this template, choose Tools | Templates
# and open the template in the editor.

class SequenceValidator  < PDTTransactionState

  attr_accessor :sequences, :pallet_no, :current_sequence, :current_sequence_index,:pt_product_chars,:main_error_screen

  def build_default_screen
    return build_sequence_screen
#    temp = PdtScreenDefinition.new(parent_sequence_screen,"1.10.3",PdtScreenDefinition.const_get("ENTERDATA"),self.parent.pdt_screen_def.user,self.parent.pdt_screen_def.ip)
#    temp.buttons["B3Enable"] = "true"
#    temp.buttons["B3Label"] = "next pallet"
#    temp.buttons["B3Submit"] = "next_pallet_submit"
#    temp.screen_attributes["content_header_caption"] = "validate sequence"
#    temp.screen_attributes["current_menu_item"] = "1.10.3"
#
#    #label = self.parent.validated_pallets.to_s + "out of " + self.parent.scanned_pallets.keys.length.to_s
#    label = self.parent.validated_pallets.to_s + "out of " + self.parent.depot_pallets.length.to_s#????????????
#    temp.controls[temp.controls.length()] = {:name=>'validated_pallet',:type=>'static_text',:label=>'validated pallets',:value=>label}
#    temp.controls[temp.controls.length()] = {:type=>"check_box",:name=>"valid",:value=>@current_sequence[:validated]}
#
#    result_screen = temp.get_output_xml()
  end

  def initialize(parent,pallet_no)

    @parent = parent
    @pallet_no = pallet_no
    @sequences = Array.new
    #@current_sequence = Hash.new
    @current_sequence_index = 0
    calc_sequences
    @current_sequence = @sequences[@current_sequence_index]

    #--------r---------------------------------------------------------
    #Display error screen if pallet has no cartons or has been scrapped
    #------------------------------------------------------------------
    if @sequences.length() == 0
      additonal_lines_array = ["pallet : " + @pallet_no.to_s,"has no sequences"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
   
    end
    @main_error_screen = result_screen if result_screen



  end

   def build_sequence_screen()

    field_configs = Array.new

    seq_value = (@current_sequence_index + 1).to_s + " of " + @sequences.length.to_s



    tot_cartons = get_real_total_cartons

    seq_description = @current_sequence[:carton_count].to_s + "/" + tot_cartons.to_s + "(" + tot_cartons.to_s + ")"

    field_configs[field_configs.length] = {:type=>"static_text",:name=>"seq",:value=>seq_value}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"seq ctns/pallet",:value=>seq_description}
   
    
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"count",:value=>@current_sequence[:actual_size_count]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"puc",:value=>@current_sequence[:puc]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"tmarket",:value=>@current_sequence[:target_market_code]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"pick ref",:value=>@current_sequence[:pick_reference]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"inv code",:value=>@current_sequence[:inventory_code]}

    field_configs[field_configs.length] = {:type=>"static_text",:name=>"brand",:value=>@current_sequence[:brand]}
    #    field_configs[field_configs.length] = {:type=>"static_text",:name=>"pallet_sequence_number",:value=>@current_sequence[:pallet_sequence_number]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"commodity",:value=>@current_sequence[:commodity_code]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"organization",:value=>@current_sequence[:organization_code]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"variety",:value=>@current_sequence[:marketing_variety_code]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"grade",:value=>@current_sequence[:grade_code]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"pack type",:value=>@current_sequence[:old_pack_code]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"sell by date",:value=>@current_sequence[:sell_by_code]}

    field_configs[field_configs.length] = {:type=>"static_text",:name=>"remarks",:value=>@current_sequence[:remarks]}

    field_configs[field_configs.length] = {:type=>"static_text",:name=>"prod char",:value=>self.pt_product_chars}
    field_configs[field_configs.length] = {:type=>"check_box",:name=>"valid",:value=>@current_sequence[:validated]}
    

    screen_attributes = {:auto_submit=>"false",:content_header_caption=>@pallet_no.to_s }
    if (on_first? && (@sequences.length > 1))
      buttons = {"B3Label"=>"next_pallet" ,"B2Label"=>"prev", "B2Submit"=>"prev_seq", "B1Submit"=>"next_seq","B1Label"=>"next","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"true","B3Submit" => "next_pallet_submit" }
    elsif (on_last? && (@sequences.length > 1))
      buttons = {"B3Label"=>"next_pallet" ,"B2Label"=>"prev", "B2Submit"=>"prev_seq", "B1Submit"=>"next_seq","B1Label"=>"next","B1Enable"=>"false","B2Enable"=>"true","B3Enable"=>"true","B3Submit" => "next_pallet_submit" }
    elsif (!on_first? && !on_last? && (@sequences.length > 2))
      buttons = {"B3Label"=>"next_pallet" ,"B2Label"=>"prev", "B2Submit"=>"prev_seq", "B1Submit"=>"next_seq","B1Label"=>"next","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }

    else
      buttons = {"B3Label"=>"next pallet" ,"B2Label"=>"prev", "B2Submit"=>"prev_seq", "B1Submit"=>"next_seq","B1Label"=>"next","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"true","B3Submit" => "next_pallet_submit"  }
    end
    #buttons = {"B3Label"=>"Clear" ,"B2Label"=>"next", "B2Submit"=>"next_seq", "B1Submit"=>"prev_seq","B1Label"=>"prev","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def

  end

  def calc_sequences()
    mapped_sequences = MappedPalletSequence.find_all_by_depot_pallet_number_and_intake_header_id(self.pallet_no,@parent.intake_header_id,:order => "pallet_sequence_number ASC")
    mapped_sequences.each do |seq|
      @sequences[@sequences.length] = {:id => seq.id,:class_code => seq.class_code,:carton_number =>nil, :validated=>false, :carton_count=>seq.seq_ctn_qty,:fg_code_old=>seq.fg_code_old,
                                       :puc=>seq.puc,:pick_reference=>seq.pick_reference,:target_market_code=>seq.target_market,
                                       :inventory_code=>seq.inventory_code,:pallet_sequence_number=>seq.pallet_sequence_number,
                                       :pallet_number=>@pallet_no,:mapped_pallet_sequence_id=>seq.id,:commodity_code=>seq.commodity,
                                       :carton_mark_code=>seq.mark_code,:actual_size_count=>seq.count,:grade_code=>seq.grade,
                                       :old_pack_code=>seq.pack_type,:inventory_code=>seq.inventory_code,:remarks=>seq.remarks,
                                       :organization_code=>seq.organization,:fg_product_code=>seq.fg_product_code,:sell_by_code=>seq.sell_by_date,
                                       :extended_fg_code=>seq.extended_fg_code,:item_pack_product_code=>seq.item_pack_product_code,:marketing_variety_code=>seq.variety,
                                       :brand=>seq.brand,:intake_header_id=>seq.intake_header_id,:product_characteristics=>seq.product_characteristics,
                                       :production_run_code => seq.production_run_code,:production_run_id => seq.production_run_id,:erp_cultivar => seq.erp_cultivar

                                       }
    end  
  end

  def prev_seq()
    @current_sequence[:validated] = self.pdt_screen_def.get_input_control_value("valid")
    @current_sequence_index -= 1
    if @current_sequence_index < 0
      @current_sequence_index = 0
    end
    @current_sequence = @sequences[@current_sequence_index]
    build_default_screen
  end

  def next_seq()
    @current_sequence[:validated] = self.pdt_screen_def.get_input_control_value("valid")
    @current_sequence_index += 1
    if @current_sequence_index > @sequences.length - 1
      @current_sequence_index = @sequences.length - 1
    end
    @current_sequence = @sequences[@current_sequence_index]
    build_default_screen
  end

  def on_first?()
    if @current_sequence_index == 0
      return true
    end
    return false
  end

  def on_last?()
    if @current_sequence_index == @sequences.length - 1
      return true
    end
    return false
  end

   def get_real_total_cartons
    total = 0
    self.sequences.each do |seq|
      total += seq[:carton_count].to_i
    end
    return total
   end

  def receive_depot_pallets
    next_pallet_submit #so that user can use this meunu item
  end

   def show_not_yet_validated_pallets
   
    if self.parent.all_pallets_validated?
      err = self.parent.receive_load_trans()
       return err if err
      self.parent.set_transaction_complete_flag
      self.parent.build_completed_screen()
    else
      return self.parent.show_not_yet_validated_pallets
    end
  end


  def show_validated_pallets

   if self.parent.all_pallets_validated?
      err = self.parent.receive_load_trans()
       return err if err
      self.parent.set_transaction_complete_flag
      self.parent.build_completed_screen()
    else
      return self.parent.show_validated_pallets
    end

  end

  def next_pallet_submit

      @current_sequence[:validated] = self.pdt_screen_def.get_input_control_value("valid")

    if self.parent.all_pallets_validated?
       err = self.parent.receive_load_trans()
       return err if err
       self.parent.set_transaction_complete_flag
       self.parent.build_completed_screen()
    else
      next_state = PalletReceiver.new(self.parent)
      self.parent.set_active_state(next_state)
      return next_state.build_default_screen
    end
  end
  
end
