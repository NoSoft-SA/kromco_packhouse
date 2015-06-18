class PalletPrintCommand < LabelPrintCommand


  def set_print_data(*args)
    object_number = args[0]
    if object_number.to_s.length == 12
      identifier = "carton"
    else
      identifier = "pallet"
    end
    
    label_record = nil
    carton_record = nil

    if(identifier == "carton")
      carton_record = Carton.find_by_carton_number(object_number)
    else
      carton_record = Carton.find_by_sql("select * from cartons where pallet_number = '#{object_number}' order by id desc limit 1")[0]

    end

    set_print_field(1, "")


    marketing_variety_code = carton_record.variety_short_long.split("_")[0]
    marketing_variety = MarketingVariety.find_by_marketing_variety_code_and_commodity_code(marketing_variety_code,carton_record.commodity_code)
    if marketing_variety.marketing_variety_description.to_s.length > 10
      #--------------------------------------------------------------------------------------
      #If variety is 2 separate words, print first word on ist line and 2nd word on 2nd line
      #else: print first 10 chars on first line, rest of chars on 2nd line
      #---------------------------------------------------------------------------------------
      words = marketing_variety.marketing_variety_description.split(" ")
      word1 = words[0]
      words.delete_at(0)
      word2 = words.join(" ")
      
      if ! word1.eql?(word2)
        set_print_field(2, word1)
        set_print_field(32, word2)
      else

        marketing_var_code = marketing_variety.marketing_variety_description.to_s.slice(0,10)
        set_print_field(2, marketing_var_code)
        set_print_field(32, marketing_variety.marketing_variety_description.to_s.slice(10,marketing_variety.marketing_variety_description.to_s.length))
      end
    else
      set_print_field(2, marketing_variety.marketing_variety_description.to_s)
      set_print_field(32, "")
    end

    # brand_code
    mark = Mark.find_by_mark_code(carton_record.carton_mark_code)
    set_print_field(3, mark.brand_code.to_s)

    # grade_code
    set_print_field(4, carton_record.grade_code)

    # size_ref
    fg_product = FgProduct.find_by_fg_product_code(carton_record.fg_product_code)
    item_pack_product = ItemPackProduct.find_by_item_pack_product_code(fg_product.item_pack_product_code)
    size_ref = item_pack_product.size_ref
    if size_ref == "NOS"
      size_ref = item_pack_product.actual_count.to_s
    end
    set_print_field(5, size_ref)

    # old_pack_code
    set_print_field(6, carton_record.old_pack_code)

    # sell_by_code
    set_print_field(7, carton_record.sell_by_code)

    # batch_number
    production_run = ProductionRun.find(carton_record.production_run_id)
    set_print_field(8, production_run.batch_code)

    # target_market_code
    set_print_field(9, carton_record.target_market_code)

    # inventory_code
    set_print_field(10, carton_record.inventory_code)

    # pick_reference_code
    set_print_field(11, carton_record.pick_reference)

    # field 12- 19 and 29
    carton_groups = Carton.find_by_sql("SELECT puc, egap, count(*) AS puc_count FROM cartons where pallet_number = '#{carton_record.pallet_number}' GROUP BY puc, egap ORDER BY puc_count DESC LIMIT 9")
    field_no = 12
    if carton_groups.length != 0
      for carton in carton_groups
        #cartons_rep = Carton.find_by_sql("SELECT egap from cartons where puc = '#{carton.puc}' and pallet_number ='#{@pallet_number}' LIMIT 1")[0]
        #field_format = carton.puc.to_s + ": " + cartons_rep.egap.to_s + ": " + carton.puc_count.to_s
        field_format = carton.puc.to_s + ": " + carton.egap.to_s + ": " + carton.puc_count.to_s
        if field_no > 19
          set_print_field(29, field_format)
        end
        set_print_field(field_no, field_format)
        field_no += 1
      end
    end
    if field_no < 19
      while(field_no < 21)
        if field_no == 20
          set_print_field(29, "")
        else
          set_print_field(field_no, "")
        end
        field_no += 1
      end
    end

    # field 20
    set_print_field(20, "00" + carton_record.pallet_number.to_s)

    # field 21
    set_print_field(21, "(00)" + carton_record.pallet_number.to_s)

    # field 22
    set_print_field(22, "(00)" + carton_record.pallet_number.to_s)

    # field 23
    set_print_field(23, "00" + carton_record.pallet_number.to_s)

    # field 24
    set_print_field(24, "(00)" + carton_record.pallet_number.to_s)

    # field 25
    #organization = Organization.find_by_organization_code(label_record.organization_code)
    set_print_field(25, carton_record.organization_code)

    # field 26 and #### 33
    line = Line.find_by_line_code(carton_record.line_code)
    set_print_field(26, line.line_phc)
    #set_print_field(30, "")

    # field 27
    set_print_field(27, "00" + carton_record.pallet_number.to_s)

    # field 28
    set_print_field(28, "(00)" + carton_record.pallet_number.to_s)

    # field 29
    #### Done above with fields 12-19

    # field 30
    set_print_field(30, carton_record.pallet.pt_product_characteristics)

    # field 31 ???????
    set_print_field(31, "(00)" + carton_record.pallet_number.to_s)

    # field 32 Done at the top

    # field 33
    set_print_field(33, "(00)" + carton_record.pallet_number.to_s)

    # field 34
    set_print_field(34, "00" + carton_record.pallet_number.to_s)

    # field 35
    set_print_field(35, "(00)" + carton_record.pallet_number.to_s)

    # field 36
    gtin = carton_record.get_gtin(mark.brand_code.to_s)
    set_print_field(36, "01" + gtin.to_s + "10" + production_run.batch_code.to_s)

    # field 3
    gtin = carton_record.get_gtin(mark.brand_code.to_s)
    puts "GTIN :: " + gtin.to_s
    set_print_field(37, "(01)" + gtin.to_s + "(10)" + production_run.batch_code.to_s)

    set_print_field(38,Time.now.strftime("%Y-%m-%d %H:%M"))



  end



end
