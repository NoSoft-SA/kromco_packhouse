class MoveLabeledCartons < PDTTransactionState

  def initialize(parent)
    @parent = parent
    @moved_pallets_count = 0
    @moved_cartons_count = 0
  end
  

  def build_default_screen
    #puts "11. build_default_screen"
    get_labeled_buildup_stats
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=>@moved_cartons_count.to_s + ' labeled cartons moved from ' + @moved_pallets_count.to_s + ' pallets'}
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'carton_num', :label=>'carton number', :is_required=>'true'}

    buttons = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"move_labeled_cartons_submit", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=>"scan carton", :auto_submit=>"true",:auto_submit_to=>"move_labeled_cartons_submit",:cache_screen => true}#AUTO_SUBMIT
    plugins=nil
    #puts "12. build_default_screen"
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    #puts "result_screen = " + result_screen.to_s
    return result_screen
  end

  def move_labeled_carton
    build_default_screen
  end


  def move_labeled_cartons_submit
    #puts "1. get_carton"
    get_carton
    #puts "2. get_carton"
    if (error = validate_input) != nil
      #puts "3. error = validate_input"
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, error)
      return result_screen
    else
      #puts "4. error = validate_input"
      if self.parent.labeled_pallets[self.parent.scratch_pad["carton"].pallet_number].include?(self.parent.scratch_pad["carton"].carton_number)#-----[[[ NOT IN SPEC ]]] ----
        result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, ["Carton: " + self.parent.scratch_pad["carton"].carton_number.to_s, "has already been scanned"])
        return result_screen
      else#-----[[[ NOT IN SPEC ]]] ----
        #puts "5. error = validate_input"
        self.parent.labeled_pallets[self.parent.scratch_pad["carton"].pallet_number].push(self.parent.scratch_pad["carton"].carton_number)
      end

      #puts "6. self.parent.qty_cartons_remaining"
      if self.parent.qty_cartons_remaining == 0
        #puts "7. self.parent.qty_cartons_remaining"

        if trans_err = self.parent.move_trans()
          return trans_err
        else
          self.parent.set_transaction_complete_flag
          return self.parent.build_completed_screen()
        end
        #puts "8. self.parent.qty_cartons_remaining"
      else
        #puts "9. build_default_screen"
        build_default_screen
      end
    end
  end

  def validate_input
    if valid_carton? && valid_ctn_plt_assoc?
      if false#(error = self.parent.org_rules_passed?(self.parent.scratch_pad["carton"].attributes)) != nil
        return error
        #return nil #To bypass this check - for testing purposes
      else
        return nil
      end
    else
      return @error
    end
  end

  def valid_carton?
    if self.parent.scratch_pad["carton"] != nil
      if self.parent.scratch_pad["carton"].exit_ref
        @error = ["carton: " + self.parent.scratch_pad["carton"].carton_number.to_s, " has an exit ref"]
        return false
      else
        return true
      end
    else
      @error = ["invalid carton"]
      return false
    end
  end

  def valid_ctn_plt_assoc?
    if self.parent.scratch_pad["carton"].pallet_number == nil
      @error = ["carton: " + self.parent.scratch_pad["carton"].carton_number.to_s, " does not belong to any pallet"]
      return false
    elsif ! self.parent.labeled_pallets.keys.find{|p| p.to_s == self.parent.scratch_pad["carton"].pallet_number.to_s}
      @error = ["carton: " + self.parent.scratch_pad["carton"].carton_number.to_s, "does not belong to a source pallet", "carton pallet number is: ", self.parent.scratch_pad["carton"].pallet_number.to_s]
      return false
    else
      return true
    end
  end

  #  def move_labeled_cartons
  #    build_default_screen
  #  end

  def move_unlabeled_cartons #Transit to EnterUnlabeledPalletNumber state
    next_state = EnterUnlabeledPalletNumber.new(self.parent)
    self.parent.set_active_state(next_state)
    return next_state.build_default_screen
  end

  def move_labeled_cartons
    build_default_screen
  end

  def get_labeled_buildup_stats
    @moved_pallets_count = 0
    @moved_cartons_count = 0
    for pallet in self.parent.labeled_pallets.keys
      if (self.parent.labeled_pallets[pallet].length > 0)
        @moved_pallets_count += 1
        @moved_cartons_count += self.parent.labeled_pallets[pallet].length
      end
    end
  end


  def show_build_up_progress

    to_pallet = self.parent.to_pallet_no.to_s
    puts "TO PALLET: " + to_pallet   + "(orig qty: "    + Pallet.get_carton_count(to_pallet.to_i).to_s
    moved_ctns_list =   calc_moved_cartons
    req_ctns = self.parent.qty_to_move.to_s

    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=> "DEST PALLET: " + to_pallet.to_s + "(orig qty: "    + Pallet.get_carton_count(to_pallet.to_i).to_s + ")"}
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=> "REQ QTY: " + self.parent.qty_to_move.to_s}
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=> "MOVED QTY: " + moved_ctns_list.length().to_s}
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=> "SOURCE PALLETS:  "}

    self.parent.labeled_pallets.each do |key, carton_nums_array|
      actual_count = Pallet.get_carton_count(key).to_s
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=> key.to_s + "(" + carton_nums_array.length().to_s + " of max " + actual_count + ")"}
      puts "FROM PLT: " + key.to_s
    end



    buttons = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=>"build up progress", :auto_submit=>"true"}#AUTO_SUBMIT
    plugins=nil
    #puts "12. build_default_screen"
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    #puts "result_screen = " + result_screen.to_s
    return result_screen


  end


  def calc_moved_cartons
    moved_ctns = Array.new
    self.parent.labeled_pallets.each do |key, carton_nums_array|
      moved_ctns.concat(carton_nums_array)
    end

    return  moved_ctns
  end


  def calc_unmoved_cartons
    unmoved_ctns = Array.new
    self.parent.labeled_pallets.each do |key, carton_nums_array|
      all_ctns =  get_pallet_carton_nums(key)
      all_ctns = all_ctns -  carton_nums_array
      unmoved_ctns.concat(all_ctns)

    end
    return  unmoved_ctns
  end

  def get_pallet_carton_nums(pallet_num)

    nums = Carton.connection.select_all("select cartons.carton_number from cartons where cartons.pallet_number = '#{pallet_num.to_s}'").map{|c|c['carton_number'].to_i}


  end


  def show_moved_cartons

    moved_ctns =   calc_moved_cartons

    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=> "CARTONS ALREADY MOVED:"}
    moved_ctns.each do |ctn|
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=> ctn.to_s}
    end

    buttons = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=>"moved cartons", :auto_submit=>"true"}#AUTO_SUBMIT
    plugins=nil
    #puts "12. build_default_screen"
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    #puts "result_screen = " + result_screen.to_s
    return result_screen


  end


  def show_not_yet_moved_cartons

    moved_ctns =   calc_unmoved_cartons

    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=> "CARTONS NOT YET MOVED:"}
    moved_ctns.each do |ctn|
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=> ctn.to_s}
    end

    buttons = {:B1Label=>"Submit", :B1Enable=>"false", :B1Submit=>"", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=>"not yet moved cartons", :auto_submit=>"true"}#AUTO_SUBMIT
    plugins=nil
    #puts "12. build_default_screen"
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    #puts "result_screen = " + result_screen.to_s
    return result_screen


  end


  private
  def get_carton
    begin
      #      self.parent.scratch_pad["carton"] = Carton.find_by_carton_number(self.parent.pdt_screen_def.get_input_control_value("carton_num"))
      self.parent.scratch_pad["carton"] = Carton.find_by_carton_number(PDTFunctions.extract_carton_num(self.parent.pdt_screen_def.get_input_control_value("carton_num")))
    rescue
    end
  end
end