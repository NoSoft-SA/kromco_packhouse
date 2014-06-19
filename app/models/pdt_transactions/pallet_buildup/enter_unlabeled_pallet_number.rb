class EnterUnlabeledPalletNumber < PDTTransactionState

  def initialize(parent)
    @parent = parent
    @moved_pallets_count = 0
    @moved_cartons_count = 0
  end

  def build_default_screen
    get_unlabeled_buildup_stats
    field_configs = Array.new
     field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>@moved_cartons_count.to_s + ' unlabeled cartons moved from ' + @moved_pallets_count.to_s + ' pallets'}
     field_configs[field_configs.length] = {:type=>"text_box",:name=>"scan_pallet"}
     screen_attributes = {:auto_submit=>"true",:content_header_caption=>"move unlabeled cartons",:auto_submit_to=>"move_unlabeled_cartons_submit"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Label"=>"Submit","B1Submit"=>"pallet_number_entered","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = Array.new
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end

  def move_unlabeled_cartons_submit
    extracted_pallet_num = PDTFunctions.extract_pallet_num(self.parent.pdt_screen_def.get_input_control_value("scan_pallet"))
    #if(extracted_pallet_num.kind_of?(Fixnum) || extracted_pallet_num.kind_of?(Bignum))
    if !extracted_pallet_num.upcase.include?("INVALID")
      if(self.parent.unlabeled_pallets.has_key?(extracted_pallet_num))
        next_state = self.parent.unlabeled_pallets[extracted_pallet_num]
        self.parent.set_active_state(next_state)
        next_state.build_default_screen
      else
        result_screen = PDTTransaction.build_msg_screen_definition("Pallet is not in list of scanned from pallets",nil,nil,nil)
      return result_screen
      end
    else
      result_screen = PDTTransaction.build_msg_screen_definition(extracted_pallet_num,nil,nil,nil)
      return result_screen
    end
  end

  def get_unlabeled_buildup_stats
    current_pallet = nil
    @moved_pallets_count = 0
    @moved_cartons_count = 0
    for pallet_no in self.parent.unlabeled_pallets.keys
      for sequence in self.parent.unlabeled_pallets[pallet_no].sequences
        if  sequence[:qty_moved] != nil
          @moved_pallets_count += 1 if current_pallet != pallet_no || current_pallet == nil
          @moved_cartons_count += sequence[:qty_moved].to_i
        end
      end
      current_pallet = pallet_no
    end
  end

  def move_unlabeled_cartons
    build_default_screen
  end

  def move_labeled_cartons
    next_state = MoveLabeledCartons.new(self.parent)
    self.parent.set_active_state(next_state)
    return next_state.build_default_screen
  end
  
end