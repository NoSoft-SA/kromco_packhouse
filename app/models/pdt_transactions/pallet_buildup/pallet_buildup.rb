class PalletBuildup < PDTTransaction
  attr_accessor :labeled_pallets, :to_pallet_no, :qty_to_move, :qty_moved, :unlabeled_pallets, :from_pallet_nums #,:new_pallet?

  def initialize()
    super
    @labeled_pallets = Hash.new
    @to_pallet_no = nil
    @qty_to_move = 0
    @qty_moved = 0
    @unlabeled_pallets = Hash.new
    @from_pallet_nums = Array.new
  end

  def buildup_pallet
    build_default_screen
  end

  def show_moved_cartons
    build_default_screen

  end

  def is_carton_of_source_pallet(carton)

    sql = "select count(*) from cartons where carton_number = #{carton.carton_number.to_s} and ("
    or_clause = ""
    self.from_pallet_nums.each do |pallet_num|
      or_clause += "cartons.pallet_number = '#{pallet_num.to_s}' OR "

    end

    sql = sql + or_clause.slice(0, or_clause.length() -3) +  ")"

    return  Carton.connection.select_one(sql)['count'].to_i > 0



  end

  def build_default_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'qty_cartons', :label=>'qty cartons', :is_required=>'true', :required_type=>"number"}
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'to_pallet', :label=>'to pallet', :is_required=>'true',:scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'from_pallet_1', :label=>'from pallet 1',:scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'from_pallet_2', :label=>'from pallet 2',:scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'from_pallet_3', :label=>'from pallet 3',:scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'from_pallet_4', :label=>'from pallet 4',:scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'from_pallet_5', :label=>'from pallet 5',:scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'from_pallet_6', :label=>'from pallet 6',:scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'from_pallet_7', :label=>'from pallet 7',:scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'from_pallet_8', :label=>'from pallet 8',:scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'from_pallet_9', :label=>'from pallet 9',:scan_field => true}
    field_configs[field_configs.length] = {:type=>'text_box', :name=>'from_pallet_10', :label=>'from pallet 10',:scan_field => true}

    buttons = {:B1Label=>"Submit", :B1Enable=>"true", :B1Submit=>"buildup_pallet_submit", :B2Label=>"", :B2Enable=>"false", :B2Submit=>"", :B3Label=>"", :B3Enable=>"false", :B3Submit=>""}
    screen_attributes ={:content_header_caption=>"pallet build up", :auto_submit=>"false"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
  end


  def validate_input
    from_pallets_have_zero_printed_carton_labels = "NOT SET"
    for control in self.pdt_screen_def.controls
      if control["name"] != "qty_cartons" && control["value"].strip != ""
        pallet_number = PDTFunctions.extract_pallet_num(control["value"])
        if !pallet_number.upcase.include?("INVALID")
          if (self.pdt_screen_def.controls.index(control) > 1)
            @from_pallet_nums.push(pallet_number)
          else
            @to_pallet_no = pallet_number
          end
          pallet = Pallet.find_by_pallet_number(pallet_number)
          
          #1. from_pallets type check - they all must be of the same type
          from_pallets_have_zero_printed_carton_labels = pallet.zero_printed_carton_labels if(from_pallets_have_zero_printed_carton_labels=="NOT SET")
          return ["Error:","from_pallets and to_pallet must all be of the same type"] if(pallet.zero_printed_carton_labels != from_pallets_have_zero_printed_carton_labels)
          #1. from_pallets type check - they all must be of the same type
          
          if (pallet == nil || pallet.exit_ref != nil)
            #Pallet not found OR exit_ref != nil
            error = ["invalid pallet : ", "pallet not found OR pallet pallet.exit_ref != nil", control["name"].to_s + " = " + control["value"].to_s]
            return error
          elsif pallet.process_status && pallet.process_status.upcase().index("PALLETIZING")
             return ["invalid pallet : ", "pallet #{pallet_number}", "is on palletizing bay"]
          end
        else
          #Invalid pallet_numeber entered
          error = ["Invalid pallet_number [" + pallet_number +"] entered!"]
          return error
        end
      elsif control["name"] == "qty_cartons"
        quantity_to_move = control["value"].to_i
      end
    end
#
#    #2. from_pallets type check - they all must be of the same type as the to pallet
#    return ["Error:","from_pallets must be of the same type as the to_pallet"] if((to_pallet=Pallet.find_by_pallet_number(@to_pallet_no)) && to_pallet.zero_printed_carton_labels != from_pallets_have_zero_printed_carton_labels)
#    #2. from_pallets type check - they all must be of the same type as the to pallet
#
    if org_err = validate_one_org_for_to_pallet()
      return org_err
    end
    @qty_to_move = quantity_to_move
    return nil
  end

  def validate_one_org_for_to_pallet()

    orgs_on_pallet = Pallet.connection.select_one("select count(distinct(organization_code)) as org_count from cartons where pallet_number = '#{@to_pallet_no}'")
    if orgs_on_pallet['org_count'].to_i > 1
      return ["destination pallet has ", "more than one org"]
    else
      return nil
    end
  end
 
  def buildup_pallet_submit
    if (error = validate_input) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, error)
      return result_screen
    else
      for pallet_num in @from_pallet_nums
        pallet = Pallet.find_by_pallet_number(pallet_num)
        if ! pallet.zero_printed_carton_labels
          @labeled_pallets.store(pallet_num, Array.new)
        else
          @unlabeled_pallets.store(pallet_num, MoveUnlabeledCartons.new(self, pallet_num))
        end
      end

      if @labeled_pallets.keys.length > 0
        next_state = MoveLabeledCartons.new(self)
        result_screen = next_state.build_default_screen
        self.set_active_state(next_state)
        return result_screen
      else
        #next_state = @unlabeled_pallets[@unlabeled_pallets.keys[0]]
        next_state = EnterUnlabeledPalletNumber.new(self)
        result_screen = next_state.build_default_screen
        self.set_active_state(next_state)
        return result_screen
      end

    end
  end

  def org_rules_passed?(from_pallet_ctn_or_seq )

    pallet_cartons = Carton.find_by_sql("SELECT * from cartons where pallet_number='#{@to_pallet_no}' order by id asc limit 1")
#    puts "pallet["+@to_pallet_no.to_s+"] has = " + pallet_cartons.size.to_s
    if (pallet_cartons.size  > 0)      #USE OLDEST CARTON INSTEAD - IF PALLET HAS ONE
      pallet_carton = pallet_cartons[0]
      organization_code = pallet_carton.organization_code
      organization = Organization.find_by_short_description(organization_code)
      organization_rules = organization.organization_rules
    else
      return nil
    end
    #---------------
    #orgs must match
    #---------------
    if from_pallet_ctn_or_seq['organization_code'].to_s != pallet_carton.organization_code.to_s
      return ["carton: " + from_pallet_ctn_or_seq['carton_number'].to_s, "has different org:", from_pallet_ctn_or_seq['organization_code'], " It must be same as dest org:", organization_code]
    end

    for organization_rule in organization_rules
      if (organization_rule.rule.rule_type.rule_type_code.to_s == "build_up")
        field_to_match = organization_rule.rule.rule_code
        if (from_pallet_ctn_or_seq[field_to_match].to_s != pallet_carton.send(field_to_match).to_s)
          return ["Cannot add carton to pallet: " + @to_pallet_no.to_s, "Carton failed '" + field_to_match + "' rule"]
        end
      end
    end
    return nil
  end

  def move_trans
    begin
      puts "STARTS = " + Time.now.to_s
      ActiveRecord::Base.transaction do
        to_pallet = Pallet.find_by_pallet_number(@to_pallet_no)

        from_pallet_nums = ""
        carton_quantity = 0
        for pallet_num in @labeled_pallets.keys
          if @labeled_pallets[pallet_num].length > 0
            carton_quantity += @labeled_pallets[pallet_num].length
            from_pallet_nums += pallet_num.to_s + ","
          end
        end

        for pallet_no in @unlabeled_pallets.keys
          for sequence in @unlabeled_pallets[pallet_no].sequences
            if (sequence[:qty_moved] != nil && sequence[:qty_moved] > 0)
              carton_quantity += sequence[:qty_moved].to_i
              from_pallet_nums += pallet_no.to_s + ","
            end
          end
        end

        from_pallet_nums.chop!
        build_ups = BuildUp.new
        build_ups.buildup_timestamp = Time.now.strftime("%Y/%m/%d/%H:%M:%S")
        build_ups.carton_quantity = carton_quantity#---HANS : CORRECT?
        build_ups.from_pallet_numbers = from_pallet_nums
        build_ups.to_pallet_id = to_pallet.id
        build_ups.save
        self.set_temp_record("build_ups_record", build_ups)
        move_labeled_cartons_trans()
        move_unlabeled_cartons_trans
        oldest_carton =  to_pallet.get_oldest_carton #Carton.find_by_sql("select fg_product_code from cartons where pallet_number = '#{@to_pallet_no.to_s}' order by id asc ")[0]

        fg_product_code = oldest_carton.fg_product_code
        to_pallet.oldest_pack_date_time = oldest_carton.pack_date_time
        carton_pack_product_code = FgProduct.find_by_fg_product_code(fg_product_code).carton_pack_product_code
        to_pallet.carton_quantity_actual = to_pallet.get_carton_count()
        err = to_pallet.set_build_status(carton_pack_product_code)
        raise err if err


        to_pallet.set_account #will update complete current state to pallets table, not only account

        #NewOutboxRecord.new("pallet_new", to_pallet) if to_pallet.is_new_pallet
        
        puts "end = " + Time.now.to_s
      end
    rescue

      if $!.to_s.index("cpp not found")
        result_screen = PDTTransaction.build_msg_screen_definition($!, 4)
        return result_screen
      else
              raise $!


      end



    end
  end


  def move_labeled_cartons_trans
    begin
      to_pallet = Pallet.find_by_pallet_number(@to_pallet_no)
      cart_nums = Array.new
      for pallet_num in @labeled_pallets.keys
        labeled_pallet = Pallet.find_by_pallet_number(pallet_num)

        for carton_num in @labeled_pallets[pallet_num]
          cart_nums.push(carton_num)
          carton = Carton.find_by_carton_number(carton_num)
          carton.pallet_number = to_pallet.pallet_number
          #NewOutboxRecord.new("carton_pallet_ref_change", carton)


          build_up_carton = BuildUpCarton.new
          build_up_carton.carton_id = carton.id.to_s
          build_up_carton.from_pallet_number = labeled_pallet.pallet_number.to_s
          build_up_carton.to_pallet_number = to_pallet.pallet_number.to_s
          build_up_carton.carton_number = carton.carton_number.to_s
          build_up_carton.build_up_id =  self.scratch_pad["build_ups_record"].id
          build_up_carton.save
        end

      end


      Carton.bulk_update({:pallet_id=>to_pallet.id, :pallet_number => "'#{to_pallet.pallet_number}'"}, cart_nums, nil) if cart_nums.length > 0
      for pallet_num in @labeled_pallets.keys
        labeled_pallet = Pallet.find_by_pallet_number(pallet_num)
        labeled_pallet.update_attribute(:carton_quantity_actual, labeled_pallet.get_carton_count())
        oldest_carton =  labeled_pallet.get_oldest_carton #Carton.find_by_sql("select fg_product_code from cartons where pallet_number = '#{pallet_num.to_s}' order by id asc ")[0]
        if !oldest_carton
          labeled_pallet.build_status = "PARTIAL"  #for new pallet
        else
          labeled_pallet.oldest_pack_date_time = oldest_carton.pack_date_time
          fg_product_code = oldest_carton.fg_product_code
          carton_pack_product_code = FgProduct.find_by_fg_product_code(fg_product_code).carton_pack_product_code
          err = labeled_pallet.set_build_status(carton_pack_product_code)
          Pallet.set_account(pallet_num,false,false)
          labeled_pallet.update
          raise err if err
        end

      end



    rescue
      raise $!
    end
  end

  def move_unlabeled_cartons_trans
    begin
      to_pallet = Pallet.find_by_pallet_number(@to_pallet_no)
      cart_nums = Array.new
      for pallet_number in @unlabeled_pallets.keys
        move_unlabelled_carton = @unlabeled_pallets[pallet_number]#State object
        unlabeled_pallet = Pallet.find_by_pallet_number(pallet_number)
        pallet_moved_cartons = 0
        for sequence in move_unlabelled_carton.sequences
          if (sequence[:qty_moved] != nil && sequence[:qty_moved] > 0)
            pallet_moved_cartons += sequence[:qty_moved]
            carton_nums = move_unlabelled_carton.carton_nums_for_sequence(sequence, pallet_number)
            count = 0
            sequence[:qty_moved].times do
              cart_nums.push(carton_nums[count])
              carton = Carton.find_by_carton_number(carton_nums[count])
              carton.pallet_number = to_pallet.pallet_number
##                carton.pallet_id = to_pallet.id
#                carton.update

              build_up_carton = BuildUpCarton.new
              build_up_carton.carton_id = carton.id.to_s
              build_up_carton.from_pallet_number = unlabeled_pallet.pallet_number.to_s
              build_up_carton.to_pallet_number = to_pallet.pallet_number.to_s
              build_up_carton.carton_number = carton.carton_number.to_s
              build_up_carton.build_up_id =  self.scratch_pad["build_ups_record"].id
              build_up_carton.save
              count += 1
            end
          end
        end

        unlabeled_pallet.carton_quantity_actual -= pallet_moved_cartons
        Pallet.set_account(pallet_number, false, false)
        unlabeled_pallet.update
      end
      Carton.bulk_update({:pallet_id=>to_pallet.id, :pallet_number => "'#{to_pallet.pallet_number}'"}, cart_nums, nil) if cart_nums.length > 0
      for pallet_number in @unlabeled_pallets.keys
        unlabeled_pallet = Pallet.find_by_pallet_number(pallet_number)
        oldest_carton = unlabeled_pallet.get_oldest_carton
        unlabeled_pallet.update_attribute(:oldest_pack_date_time,oldest_carton.pack_date_time) if(oldest_carton)
      end

      Pallet.set_account(@to_pallet_no,false,true)
      
    rescue
      #WHAT TO DO
      raise $!
    end
  end

  def move_unlabeled_cartons_submit
    pallet_number = PDTFunctions.extract_pallet_num(self.pdt_screen_def.get_input_control_value("pallet_num"))
    #if(pallet_number.kind_of?(Fixnum) || pallet_number.kind_of?(Bignum))
    if !pallet_number.upcase.include?("INVALID")
      for pallet_num in @unlabeled_pallets.keys
        if (pallet_num == pallet_number)
          current_state = @unlabeled_pallets[pallet_num]
          self.set_active_state(current_state)
          return current_state.build_default_screen
        end
      end
      result_screen = PDTTransaction.build_msg_screen_definition('PALLET NOT FOUND IN SCANNED LIST', nil, nil, nil)
      return result_screen
    else
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, [pallet_number])
      return result_screen
    end
  end

  def build_completed_screen()
    outputs = Array.new
    outputs.push("CARTONS MOVED")
    for pallet_numero in @labeled_pallets.keys
      if @labeled_pallets[pallet_numero].length > 0
        outputs.push("FROM PALLET: " + pallet_numero.to_s)
      end
    end

    for pallet_numsa in @unlabeled_pallets.keys
      for sequence in @unlabeled_pallets[pallet_numsa].sequences
        if (sequence[:qty_moved] != nil && sequence[:qty_moved] > 0)
          outputs.push("FROM PALLET: " + pallet_numsa.to_s)
        end
      end
    end

    outputs.push(" ")
    outputs.push("TO PALLET: " + @to_pallet_no.to_s)
    result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, outputs)
    return result_screen
  end

  def qty_cartons_remaining
    moved_qty = 0
    for pallet_num in @labeled_pallets.keys
      moved_qty += @labeled_pallets[pallet_num].length
    end

    for pallet_no in @unlabeled_pallets.keys
      for sequence in @unlabeled_pallets[pallet_no].sequences
        moved_qty += sequence[:qty_moved].to_i if  sequence[:qty_moved] != nil
      end
    end

    puts "@qty_to_move - @qty_moved = " + @qty_to_move.to_s + " - " + moved_qty.to_s
    @qty_to_move - moved_qty
  end

end
