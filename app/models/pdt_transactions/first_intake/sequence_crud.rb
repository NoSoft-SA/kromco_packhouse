class SequenceCrud < PDTTransactionState


  def initialize(parent)
    @parent = parent
    #@pallet_number = @parent.pallet_number
    @pallet_sequences = Array.new
    populate_pallet_sequences
    @current_sequence_index = 0
    @new_record = false
    @current_pallet_sequence = nil
    @default_values_pallet_sequence = nil
    if @pallet_sequences.length != 0
      @default_values_pallet_sequence = @pallet_sequences[@current_sequence_index]
      @current_pallet_sequence = @pallet_sequences[@current_sequence_index]
    else
      #@current_pallet_sequence = nil
      @default_values_pallet_sequence = get_pallet_sequence_for_default_values
    end
    #@current_pallet_sequence = get_pallet_sequence_for_default_values
    if @current_pallet_sequence == nil
      @new_record = true
    end
  end


  def edit_pallet

    pallet_format_codes = PalletFormatProduct.find(:all).map{|p|p.pallet_format_product_code}.join(",")
    pallet_format_codes = ", ," +  pallet_format_codes
    
    field_configs = Array.new

    pallet = DepotPallet.find_by_depot_pallet_number_and_intake_header_id(self.parent.pallet_number,self.parent.intake_header_id)
    pallet_format_code = pallet.pallet_format_product_code
    pallet_format_code = "" if !pallet_format_code

    field_configs[field_configs.length] = {:type=>"drop_down",:name=>"pallet_format",:is_required=>"true",:list => pallet_format_codes,:value=> pallet_format_code}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"pallet_base",:value=>pallet.pallet_base_code}

    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"edit pallet"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"edit_pallet_submit","B1Label"=>"Submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
  end

  def edit_pallet_submit
    
     pallet_format = self.pdt_screen_def.get_control_value("pallet_format").to_s.strip
     pallet = DepotPallet.find_by_depot_pallet_number_and_intake_header_id(self.parent.pallet_number,self.parent.intake_header_id)
     pallet.update_attribute("pallet_format_product_code",pallet_format)
     return  build_default_screen

  end

  def new_pallet
    self.parent.clear_active_state
    self.parent.new_pallet
  end

  def populate_pallet_sequences()
    pal_sequences = PalletSequence.find_by_sql("SELECT * FROM pallet_sequences WHERE depot_pallet_number = '#{@parent.pallet_number}' and intake_header_id = #{parent.intake_header_id}ORDER BY pallet_sequence_number ASC")
    if pal_sequences.length != 0
      pal_sequences.each do |pal_seq|
        @pallet_sequences.push(pal_seq.to_map)
      end
    end
  end

  def get_pallet_sequence_for_default_values()
    if @pallet_sequences.length > 0
      return @pallet_sequences[@current_sequence_index - 1]
    else
      # GET DEFAULT VALUES FROM DATABASE
      pal_sequences = PalletSequence.find_by_sql("SELECT * FROM pallet_sequences ORDER BY id DESC LIMIT 1")
      if pal_sequences.length != 0
        pal_sequences[0][:pallet_sequence_number] = 0
        return pal_sequences[0].to_map
      else
        return nil
      end
    end
  end

  def get_next_pallet_sequence()
    if @pallet_sequences.length > @current_sequence_index
      @current_pallet_sequence = @pallet_sequences[@current_sequence_index]
      if @new_record == true
        @default_values_pallet_sequence = get_pallet_sequence_for_default_values

      else
        @default_values_pallet_sequence = @pallet_sequences[@current_sequence_index]
      end
    else
      @current_pallet_sequence = nil
      if @new_record == true
        @default_values_pallet_sequence = get_pallet_sequence_for_default_values
       
      else
        @default_values_pallet_sequence = @pallet_sequences[@current_sequence_index]
      end
    end
  end

  def get_previous_pallet_sequence()
    @current_pallet_sequence = @pallet_sequences[@current_sequence_index]
    @default_values_pallet_sequence = @pallet_sequences[@current_sequence_index]
  end

  def build_default_screen()
    pallet_sequence_number = ""
    organization = ""
    commodity = ""
    variety = ""
    grade = ""
    count = ""
    brand = ""
    channel = ""
    puc = ""
    target_market_code = ""
    pick_reference = ""
    inventory_code = ""
    sell_by_date = ""
    product_characteristics = ""
    remarks = ""
    seq_ctn_qty = ""
    pallet_ctn_qty = ""
    pack_type = ""
    class_str = ""


    seq_nr =  @current_sequence_index + 1

    #if @pallet_sequences.length != 0 && @current_sequence_index <= @pallet_sequences.length - 1
    has_been_mapped = false
    if @default_values_pallet_sequence != nil
      has_been_mapped = true if(@default_values_pallet_sequence["id"] && MappedPalletSequence.find_by_pallet_sequence_id(@default_values_pallet_sequence["id"])) && !@new_record
      #current_pallet_seq = @pallet_sequences[@current_sequence_index]
      pallet_sequence_number = seq_nr.to_s
      organization = @default_values_pallet_sequence["organization"].to_s
      commodity = @default_values_pallet_sequence["commodity"].to_s
      variety = @default_values_pallet_sequence["variety"]
      grade = @default_values_pallet_sequence["grade"].to_s
      count = @default_values_pallet_sequence["count"].to_s
      brand = @default_values_pallet_sequence["brand"].to_s
      channel = @default_values_pallet_sequence["channel"].to_s
      sell_by_date = @default_values_pallet_sequence["sell_by_date"].to_s
      product_characteristics = @default_values_pallet_sequence["product_characteristics"].to_s
      remarks = @default_values_pallet_sequence["remarks"].to_s
      puc = @default_values_pallet_sequence["puc"].to_s
      target_market_code = @default_values_pallet_sequence["target_market"].to_s
      pick_reference = @default_values_pallet_sequence["pick_reference"].to_s
      inventory_code = @default_values_pallet_sequence["inventory_code"].to_s
      seq_ctn_qty = @default_values_pallet_sequence["seq_ctn_qty"].to_s
      pallet_ctn_qty = @default_values_pallet_sequence["pallet_ctn_qty"].to_s
      pack_type =  @default_values_pallet_sequence["pack_type"].to_s
      class_str =  @default_values_pallet_sequence["class_code"].to_s
      #@new_record = false
    end

    content_header_caption = ""
    field_set_type = "text_box"
    b3_enabled = true
    if @new_record == true
      content_header_caption = "create new pallet sequence"
    else
      if has_been_mapped
        content_header_caption = "view mapped sequence"
        field_set_type = "static_text"
        b3_enabled = false
      else
        content_header_caption = "update pallet sequence"
      end
    end
    
    field_configs = Array.new

    field_configs[field_configs.length] = {:type=>"static_text",:name=>"pallet_number",:value=>@parent.pallet_number.to_s, :is_required => "true"}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"pallet_sequence_number",:value=>pallet_sequence_number}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"organization",:value=>organization, :is_required => "true"}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"commodity",:value=>commodity, :is_required => "true"}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"variety",:value=>variety, :is_required => "true"}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"grade",:value=>grade, :is_required => "true"}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"count",:value=>count, :is_required => "true"}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"brand",:value=>brand, :is_required => "true"}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"channel",:value=>channel, :is_required => "true"}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"pack_type",:value=>pack_type, :is_required => "true"}
    #field_configs[field_configs.length] = {:type=>field_set_type,:name=>"class_code",:value=>class_str}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"puc",:value=>puc, :is_required => "true"}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"target_market_code",:value=>target_market_code, :is_required => "true"}

    #-------------------------------------
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"pick_reference",:value=>pick_reference, :is_required => "true",
                                             :cascades=>{:type=>'replace_control',
                                                       :settings=>{:target_control_name=>'pack_date',:remote_method=>'calc_pallet_pack_date_time',:filter_fields=>'pick_reference'}}}
    field_configs[field_configs.length] = {:name=>'pack_date',:type=>'static_text',:value=> '',:is_required=>'false'}
    #-------------------------------------
    
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"inventory_code",:value=>inventory_code, :is_required => "true"}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"sell_by_date",:value=>sell_by_date}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"product_characteristics",:value=>product_characteristics}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"remarks",:value=>remarks}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"seq_ctn_qty",:value=>seq_ctn_qty}
    field_configs[field_configs.length] = {:type=>field_set_type,:name=>"pallet_ctn_qty",:value=>pallet_ctn_qty}
    
    screen_attributes = {:auto_submit=>"false",:content_header_caption=>content_header_caption,:cache_screen => true}  
    if @current_sequence_index == 0
         buttons = {"B3Label"=>"save", "B3Submit"=>"save", "B2Label"=>"prev", "B2Submit"=>"previous_sequence", "B1Submit"=>"next_sequence","B1Label"=>"next","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>b3_enabled }
    elsif @current_sequence_index == @pallet_sequences.length - 1
       buttons = {"B3Label"=>"save","B3Submit"=>"save", "B2Label"=>"prev", "B2Submit"=>"previous_sequence", "B1Submit"=>"next_sequence","B1Label"=>"next","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>b3_enabled }
    else
       buttons = {"B3Label"=>"save","B3Submit"=>"save","B2Label"=>"prev", "B2Submit"=>"previous_sequence", "B1Submit"=>"next_sequence","B1Label"=>"next","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>b3_enabled }
    end
    #buttons = {"B3Label"=>"Clear" ,"B2Label"=>"next", "B2Submit"=>"next_seq", "B1Submit"=>"prev_seq","B1Label"=>"prev","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
  end

  def calc_pallet_pack_date_time
    #--------------------------
    intake_header = IntakeHeader.find(self.parent.intake_header_id)
    pack_date_time = DepotPallet.calc_packdate_from_pick_ref(self.parent.params[:pick_reference],intake_header.created_on.year.to_s)
    #--------------------------
    field_configs = {:name=>'pack_date',:type=>'static_text',:value=> pack_date_time.to_formatted_s(:db).to_s,:is_required=>'false'}

    return PdtScreenDefinition.gen_controls_list_xml(field_configs)
  end

  def save()


    if @new_record == true
      #@current_pallet_sequence = PalletSequence.new
      @current_pallet_sequence = Hash.new
      @current_pallet_sequence["pallet_sequence_number"] = @current_sequence_index
      @current_pallet_sequence["depot_pallet_number"] = @parent.pallet_number
      @current_pallet_sequence["depot_pallet_id"] = DepotPallet.find_by_depot_pallet_number_and_intake_header_id(@parent.pallet_number,self.parent.intake_header_id).id
      @current_pallet_sequence["organization"] = self.pdt_screen_def.get_control_value("organization").to_s
      @current_pallet_sequence["commodity"] = self.pdt_screen_def.get_control_value("commodity").to_s
      @current_pallet_sequence["variety"] = self.pdt_screen_def.get_control_value("variety").to_s
      @current_pallet_sequence["grade"] = self.pdt_screen_def.get_control_value("grade").to_s
      @current_pallet_sequence["count"] = self.pdt_screen_def.get_control_value("count").to_s
      @current_pallet_sequence["brand"] = self.pdt_screen_def.get_control_value("brand").to_s
      @current_pallet_sequence["channel"] = self.pdt_screen_def.get_control_value("channel").to_s
      @current_pallet_sequence["puc"] = self.pdt_screen_def.get_control_value("puc").to_s
      #@current_pallet_sequence["class_code"] = self.pdt_screen_def.get_control_value("class_code").to_s
      @current_pallet_sequence["pack_type"] = self.pdt_screen_def.get_control_value("pack_type").to_s
      @current_pallet_sequence["target_market"] = self.pdt_screen_def.get_control_value("target_market_code").to_s
      @current_pallet_sequence["pick_reference"] = self.pdt_screen_def.get_control_value("pick_reference").to_s
      @current_pallet_sequence["inventory_code"] = self.pdt_screen_def.get_control_value("inventory_code").to_s
      @current_pallet_sequence["sell_by_date"] = self.pdt_screen_def.get_control_value("sell_by_date").to_s
      @current_pallet_sequence["product_characteristics"] = self.pdt_screen_def.get_control_value("product_characteristics").to_s
      @current_pallet_sequence["remarks"] = self.pdt_screen_def.get_control_value("remarks").to_s
      @current_pallet_sequence["seq_ctn_qty"] = self.pdt_screen_def.get_control_value("seq_ctn_qty").to_s
      @current_pallet_sequence["pallet_ctn_qty"] = self.pdt_screen_def.get_control_value("pallet_ctn_qty").to_s

      class_char =  @current_pallet_sequence["grade"].slice(0,1)
      class_code = "CL1"
      if class_char.is_numeric?
          class_code = "CL" + class_char
      end

      @current_pallet_sequence["class_code"] = class_code

  

      #@current_pallet_sequence.create
      pal_seq = PalletSequence.new(@current_pallet_sequence)
      pal_seq.intake_header_id =  self.parent.intake_header_id
      #-------------------
      intake_header = IntakeHeader.find(self.parent.intake_header_id)
      pal_seq.pack_date_time = DepotPallet.calc_packdate_from_pick_ref(@current_pallet_sequence["pick_reference"],intake_header.season.to_s).to_formatted_s(:db).to_s
      #-------------------
      pal_seq.create
      @pallet_sequences.push(pal_seq.to_map)
      @new_record = false
      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"Pallet sequence created successifully!"}
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"transaction complete"}
      if @current_sequence_index > 0
        buttons = {"B3Label"=>"Clear" ,"B2Label"=>"prev","B1Submit"=>"next_sequence","B1Label"=>"next", "B2Submit" =>"previous_sequence", "B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }
      else
        buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"next_sequence","B1Label"=>"next", "B2Submit" =>"previous_sequence", "B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
      end
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)

    else
      #pallet_sequence = @pallet_sequences[@current_sequence_index]
      @current_pallet_sequence["pallet_sequence_number"] = @current_sequence_index 
      @current_pallet_sequence["depot_pallet_number"] = @parent.pallet_number
      @current_pallet_sequence["depot_pallet_id"] = DepotPallet.find_by_depot_pallet_number_and_intake_header_id(@parent.pallet_number,self.parent.intake_header_id).id
      @current_pallet_sequence["organization"] = self.pdt_screen_def.get_control_value("organization").to_s
      @current_pallet_sequence["commodity"] = self.pdt_screen_def.get_control_value("commodity").to_s
      @current_pallet_sequence["variety"] = self.pdt_screen_def.get_control_value("variety").to_s
      @current_pallet_sequence["grade"] = self.pdt_screen_def.get_control_value("grade").to_s
      @current_pallet_sequence["count"] = self.pdt_screen_def.get_control_value("count").to_s
      @current_pallet_sequence["brand"] = self.pdt_screen_def.get_control_value("brand").to_s
      @current_pallet_sequence["channel"] = self.pdt_screen_def.get_control_value("channel").to_s
      @current_pallet_sequence["puc"] = self.pdt_screen_def.get_control_value("puc").to_s
      @current_pallet_sequence["pack_type"] = self.pdt_screen_def.get_control_value("pack_type").to_s
      #@current_pallet_sequence["class_code"] = self.pdt_screen_def.get_control_value("class_code").to_s
      @current_pallet_sequence["target_market"] = self.pdt_screen_def.get_control_value("target_market_code").to_s
      @current_pallet_sequence["pick_reference"] = self.pdt_screen_def.get_control_value("pick_reference").to_s
      @current_pallet_sequence["inventory_code"] = self.pdt_screen_def.get_control_value("inventory_code").to_s
      @current_pallet_sequence["sell_by_date"] = self.pdt_screen_def.get_control_value("sell_by_date").to_s
      @current_pallet_sequence["product_characteristics"] = self.pdt_screen_def.get_control_value("product_characteristics").to_s
      @current_pallet_sequence["remarks"] = self.pdt_screen_def.get_control_value("remarks").to_s
      @current_pallet_sequence["seq_ctn_qty"] = self.pdt_screen_def.get_control_value("seq_ctn_qty").to_s
      @current_pallet_sequence["pallet_ctn_qty"] = self.pdt_screen_def.get_control_value("pallet_ctn_qty").to_s
      #@current_pallet_sequence.update
      class_char =  @current_pallet_sequence["grade"].slice(0,1)
      class_code = "CL1"
      if class_char.is_numeric?
        class_code = "CL" + class_char
       end

     @current_pallet_sequence["class_code"] = class_code


      pal_seq = PalletSequence.find(@current_pallet_sequence["id"])
      #-------------------
      intake_header = IntakeHeader.find(self.parent.intake_header_id)
      @current_pallet_sequence["pack_date_time"] = DepotPallet.calc_packdate_from_pick_ref(@current_pallet_sequence["pick_reference"],intake_header.created_on.year.to_s).to_formatted_s(:db).to_s
      #-------------------
      pal_seq.update_attributes!(@current_pallet_sequence)
     

      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output",:value=>"Pallet sequence updated successifully!"}
      screen_attributes = {:auto_submit=>"false",:content_header_caption=>"transaction complete"}
      if @current_sequence_index > 0
        buttons = {"B3Label"=>"Clear" ,"B2Label"=>"prev","B1Submit"=>"next_sequence","B1Label"=>"next", "B2Submit" =>"previous_sequence", "B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }
      else
        buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Submit"=>"next_sequence","B1Label"=>"next", "B2Submit" =>"previous_sequence", "B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
      end
      return PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)      
    end
    # SCREEN
    
  end

  def next_sequence()
    puts "NEXT HIT .. "
#    @current_sequence_index += 1
#    if @pallet_sequences.length - 1 == @current_sequence_index || @pallet_sequences.length - 1 < @current_sequence_index
#      #@pallet_sequences[@current_sequence_index] = @current_pallet_sequence
#      @new_record = true
#    else
#      @new_record = false
#    end
   
    if @new_record == true

    else
      @current_sequence_index += 1
      if @pallet_sequences.length == @current_sequence_index || @pallet_sequences.length < @current_sequence_index
        @new_record = true
      end
    end
    get_next_pallet_sequence


    build_default_screen
  end

  def previous_sequence()
    @new_record = false
    @current_sequence_index -= 1
    get_previous_pallet_sequence
    build_default_screen
  end

end