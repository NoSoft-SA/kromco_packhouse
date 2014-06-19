class PalletSequenceNavigator < PDTTransactionState

  attr_accessor :sequences, :pallet_no, :current_sequence, :current_sequence_index,:age,:pt_product_chars,:build_status,:cpp,:qc_status,:pfp,:current_location,:inspect_type,:carton_qty_actual,:main_error_screen

  def initialize(parent,pallet_no)
    @parent = parent
    @pallet_no = pallet_no
    @sequences = Array.new
    #@current_sequence = Hash.new
    @current_sequence_index = 0
    calc_sequences
    @current_sequence = @sequences[@current_sequence_index]
    pallet = Pallet.find_by_pallet_number(@pallet_no)
    self.pt_product_chars = pallet.pt_product_characteristics
    self.build_status = pallet.build_status
    self.qc_status = pallet.qc_result_status
    self.pfp = pallet.pallet_format_product_code
    stock_item = StockItem.find_by_inventory_reference(@pallet_no)
    self.current_location = stock_item.location_code if stock_item
    self.inspect_type = pallet.inspect_type_code
    self.carton_qty_actual = pallet.carton_quantity_actual
    #--------r---------------------------------------------------------
    #Display error screen if pallet has no cartons or has been scrapped
    #------------------------------------------------------------------
    if @sequences.length() == 0
      additonal_lines_array = ["pallet : " + @pallet_no.to_s,"has no sequences"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
    elsif pallet.exit_ref && pallet.exit_ref.upcase == "SCRAPPED"
      additonal_lines_array = ["pallet : " + @pallet_no.to_s,"has been scrapped"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
    end
    @main_error_screen = result_screen if result_screen
  end

  def build_default_screen()
    if(@main_error_screen)
      return @main_error_screen
    end
    build_sequence_screen    
  end

  def get_real_total_cartons
    total = 0
    self.sequences.each do |seq|
      total += seq[:carton_count].to_i
    end
    return total
  end

  def build_sequence_screen()
    
    field_configs = Array.new
    seq_value = (@current_sequence_index + 1).to_s + " of " + @sequences.length.to_s 
#    seq_value = @current_sequence[:pallet_sequence_number] if @current_sequence[:pallet_sequence_number] != nil

    pack_date_time = DateTime.parse(@current_sequence[:oldest_pack_date])

    age = (Time.now - pack_date_time.to_time).to_i/60/60/24

    fg_cold_old = @current_sequence[:fg_code_old].split(" ")
    count = fg_cold_old[fg_cold_old.length-1]

    tot_cartons = get_real_total_cartons

    seq_description = @current_sequence[:carton_count].to_s + "/" + tot_cartons.to_s + "(" + self.carton_qty_actual.to_s + ")"

    field_configs[field_configs.length] = {:type=>"static_text",:name=>"seq",:value=>seq_value}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"seq ctns/pallet",:value=>seq_description}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"req cartons",:value => @current_sequence[:cpp]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"final state",:value=>self.build_status}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"count",:value=>count.to_s}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"puc",:value=>@current_sequence[:puc]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"tmarket",:value=>@current_sequence[:target_market_code]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"pick ref",:value=>@current_sequence[:pick_reference]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"inv code",:value=>@current_sequence[:inventory_code]}

    field_configs[field_configs.length] = {:type=>"static_text",:name=>"brand",:value=>@current_sequence[:brand_code]}
    #    field_configs[field_configs.length] = {:type=>"static_text",:name=>"pallet_sequence_number",:value=>@current_sequence[:pallet_sequence_number]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"commodity",:value=>@current_sequence[:commodity_code]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"organization",:value=>@current_sequence[:organization_code]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"variety",:value=>@current_sequence[:variety_short_long]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"grade",:value=>@current_sequence[:grade_code]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"pack type",:value=>@current_sequence[:old_pack_code]}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"sell by date",:value=>@current_sequence[:sell_by_code]}

    field_configs[field_configs.length] = {:type=>"static_text",:name=>"remarks",:value=>@current_sequence[:remarks]}

    field_configs[field_configs.length] = {:type=>"static_text",:name=>"prod char",:value=>self.pt_product_chars}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"insp type",:value=>self.inspect_type}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"insp state",:value=>self.qc_status}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"plt frmt",:value=>self.pfp}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"location",:value=>self.current_location.to_s}

    screen_attributes = {:auto_submit=>"false",:content_header_caption=>@pallet_no.to_s + "(age =" + age.to_s + "days)"}
    if (on_first? && (@sequences.length > 1))
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"prev", "B2Submit"=>"prev_seq", "B1Submit"=>"next_seq","B1Label"=>"next","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
    elsif (on_last? && (@sequences.length > 1))
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"prev", "B2Submit"=>"prev_seq", "B1Submit"=>"next_seq","B1Label"=>"next","B1Enable"=>"false","B2Enable"=>"true","B3Enable"=>"false" }
    elsif (!on_first? && !on_last? && (@sequences.length > 2))
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"prev", "B2Submit"=>"prev_seq", "B1Submit"=>"next_seq","B1Label"=>"next","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }

    else
      buttons = {"B3Label"=>"Clear" ,"B2Label"=>"prev", "B2Submit"=>"prev_seq", "B1Submit"=>"next_seq","B1Label"=>"next","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    end
    #buttons = {"B3Label"=>"Clear" ,"B2Label"=>"next", "B2Submit"=>"next_seq", "B1Submit"=>"prev_seq","B1Label"=>"prev","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

    return result_screen_def
   
  end

  def calc_sequences()
   
    cartons = Carton.find_by_sql("SELECT count(*) as count, pallets.pt_product_characteristics as pt_product_characteristics,
      cartons.fg_code_old,cartons.puc, cartons.pick_reference, cartons.target_market_code, cartons.inventory_code, cartons.pallet_sequence_number,
      cartons.commodity_code, cartons.organization_code, cartons.variety_short_long, cartons.grade_code, cartons.old_pack_code, cartons.sell_by_code,
      cartons.remarks, marks.brand_code, min(pack_date_time) AS oldest_pack_date_time, public.cartons_per_pallets.cartons_per_pallet,
      pallets.build_status FROM cartons   INNER JOIN marks ON (cartons.carton_mark_code = marks.mark_code)
      INNER JOIN pallets ON (cartons.pallet_id = pallets.id)
      INNER JOIN public.fg_products ON (cartons.fg_product_code = public.fg_products.fg_product_code)
      LEFT OUTER JOIN public.cartons_per_pallets ON (public.fg_products.carton_pack_product_id = public.cartons_per_pallets.carton_pack_product_id)
      AND (pallets.pallet_format_product_code = public.cartons_per_pallets.pallet_format_product_code)
      WHERE pallets.pallet_number = '#{@pallet_no.to_s}' GROUP BY pallets.pt_product_characteristics,
      cartons.fg_code_old, cartons.puc, cartons.pick_reference, cartons.target_market_code, cartons.inventory_code,
      cartons.pallet_sequence_number, cartons.commodity_code, cartons.organization_code, cartons.variety_short_long,
      cartons.grade_code, cartons.old_pack_code, cartons.sell_by_code, cartons.remarks, marks.brand_code, public.cartons_per_pallets.cartons_per_pallet,
      pallets.build_status ORDER BY count(*) DESC")
    if cartons.length != 0
      cartons.each do |carton|
       
        @sequences[@sequences.length] = {:oldest_pack_date => carton.oldest_pack_date_time,:cpp => carton.cartons_per_pallet, :validated=>false, :carton_count=>carton.count,:fg_code_old=>carton.fg_code_old,:puc=>carton.puc,:pick_reference=>carton.pick_reference,:target_market_code=>carton.target_market_code,:inventory_code=>carton.inventory_code,:pallet_number=>@pallet_no ,:brand_code=>carton.brand_code,:pallet_sequence_number=>carton.pallet_sequence_number,:commodity_code=>carton.commodity_code,:organization_code=>carton.organization_code,:variety_short_long=>carton.variety_short_long,:grade_code=>carton.grade_code,:target_market_code=>carton.target_market_code,:inventory_code=>carton.inventory_code,:pick_reference=>carton.pick_reference,:old_pack_code=>carton.old_pack_code,:puc=>carton.puc,:sell_by_code=>carton.sell_by_code,:pt_product_characteristics=>carton.pt_product_characteristics,:remarks=>carton.remarks}
      end
    end
  end

  def prev_seq()
    @current_sequence_index -= 1
    if @current_sequence_index < 0
      @current_sequence_index = 0
    end
    @current_sequence = @sequences[@current_sequence_index]
    build_default_screen
  end

  def next_seq()
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

  def carton_nums_for_sequence(sequence,pallet_num)    
    cartons_sql = fetch_seq_cartons_where_clause?(sequence,pallet_num)
    puts " I-SEQUEL = " + "select carton_number from cartons where (" + cartons_sql + ") order by carton_number asc"
    cartons = Carton.find_by_sql("select carton_number from cartons where (" + cartons_sql + ") order by carton_number asc")
    cartons = cartons.map{|c| c.carton_number}  
  end

  def fetch_seq_cartons_where_clause?(sequence,pallet_num)
    fg_code_old = sequence[:fg_code_old]
    puc = sequence[:puc]
    pick_reference = sequence[:pick_reference]
    target_market_code = sequence[:target_market_code]
    inventory_code = sequence[:inventory_code]
    "pallet_number='#{pallet_num}' and fg_code_old='#{fg_code_old}' and puc='#{puc}' and pick_reference='#{pick_reference}' and target_market_code='#{target_market_code}' and inventory_code='#{inventory_code}'"
  end

end