class RwActiveCarton < ActiveRecord::Base


  belongs_to :carton
  belongs_to :rw_run
  belongs_to :rw_receipt_pallet
  belongs_to :rw_active_pallet
  belongs_to :carton_template
  belongs_to :rw_receipt_carton
  belongs_to :production_run


  attr_accessor :item_pack_product_code, :carton_pack_product_code,
                :calculated_mass, :target_market_short,
                :inventory_code_short, :pc_code_short, :is_fg_carton, :marketing_variety_code, :address_line1, :address_line2 , :run_track_indicator_code,:label_data

  def is_valid_carton_sell_by_code?(carton,pallet)
    oldest_carton_sell_by_code=RwActiveCarton.find_by_sql("select sell_by_code from rw_active_cartons where pallet_number='#{pallet.pallet_number}' order by id asc limit 1")
    if oldest_carton_sell_by_code.empty?
      return  nil
    else
      carton_sell_by_code= carton.sell_by_code
      sell_by_code= oldest_carton_sell_by_code[0]['sell_by_code']
      if oldest_carton_sell_by_code[0]['sell_by_code']== "<empty>"  || oldest_carton_sell_by_code[0]['sell_by_code']==nil || oldest_carton_sell_by_code[0]['sell_by_code']=="_"
        sell_by_code=nil
      end
      if carton.sell_by_code== "<empty>"  || carton.sell_by_code==nil || carton.sell_by_code=="_"
        carton_sell_by_code =nil
      end
      if   sell_by_code != carton_sell_by_code
        return oldest_carton_sell_by_code[0]['sell_by_code']
      else
        return nil
      end
    end
  end


  def self.bulk_update(set_map, carton_nums=nil, additional_criteria=nil)
    updates = ""
    for key in set_map.keys
      if set_map[key] == "null"
        updates += key.to_s + "= " + set_map[key].to_s + ","
      else
        updates += key.to_s + "= '" + set_map[key].to_s + "',"
      end
    end
    updates.chop!

    conditions = "("
    if (carton_nums != nil)
      for carton_num in carton_nums
        conditions += "carton_number=" + carton_num.to_s + " or "
      end
    end

    conditions.chop!.chop!.chop!
    conditions += ")"

    if (additional_criteria != nil)
      conditions += " and ("
      for ikey in additional_criteria.keys
        conditions += ikey.to_s + "=" + additional_criteria[ikey].to_s + " and "
      end
    end
    puts "NULK UPDATE STMT = set(" + updates +")\n " + "where (" + conditions + ")"
    conditions.chop!.chop!.chop!.chop!
    conditions += ")"

    RwActiveCarton.update_all(ActiveRecord::Base.extend_set_sql_with_request(updates,"rw_active_cartons"), conditions)

  end


  #------------------------------------------------------------------------------------------------------------
  #This method will group all cartons in the run by unique combinations of fields that form groups with
  #other fields. From each group a representative carton will be used to derive fields from this carton's
  #changed(new) data. If fields could be derived without errors, all the cartons in the group will be updated
  #with a single bulk update statement- with the data of the representative carton
  #-------------------------------------------------------------------------------------------------------------
  def generic_bulk_carton_update(unchanged_fields)
    #-------------------------------------------------------------------------------
    #Find a unique list of all combinations of carton data that are dependent on other
    #data on same carton: e.g class,grade,size_count_code are dependent on each other
    #for a given combination must exist in the form as a fg_product_code. If we have
    #such a unique list, we can update each group as a whole, because each item
    #in the group will derive the exact same values as the group representative cartons
    #fields are: extended_fg_code,org_code,target_market_code,inventory_code,production_run_code
    #             inspection_type_code,sell_by_code,farm_code, puc
    #--------------------------------------------------------------------------------
    carton_group_defs      = RwActiveCarton.find_by_sql("select distinct sell_by_code, extended_fg_code,organization_code,target_market_code,inventory_code,production_run_code,
               inspection_type_code, track_indicator_code, erp_cultivar,spray_program_code,puc,farm_code from rw_active_cartons where
                        (rw_run_id = #{self.rw_run_id})")


    errs                   = ""
    representative_cartons = Array.new

    carton_group_defs.each do |group_def|
      carton = RwActiveCarton.find_all_by_extended_fg_code_and_puc_and_organization_code_and_target_market_code_and_inventory_code_and_production_run_code_and_inspection_type_code_and_sell_by_code_and_track_indicator_code_and_erp_cultivar_and_spray_program_code_and_farm_code(group_def.extended_fg_code,group_def.puc, group_def.organization_code, group_def.target_market_code, group_def.inventory_code, group_def.production_run_code, group_def.inspection_type_code, group_def.sell_by_code,
                                     group_def.track_indicator_code,group_def.erp_cultivar,group_def.spray_program_code,group_def.farm_code)[0]
      representative_cartons.push(carton)
    end

    #---------------------------------------------------------------------------------------------
    #Call update_from_pallet for each carton. Derived fields will be calculated in
    #this method and the 'derive_fields' method called within that method. Collect errors
    #returned by all representative cartons and raise exception. If no errors are returned, build
    #an update_all statement for each representative carton and execute. Raise exception if any
    #update statement failed
    # ---------------------------------------------------------------------------------------------
    puts "GROUPS: " + representative_cartons.length().to_s
    cartons_updated = 0
    representative_cartons.each do |repr_carton|
     # begin
        old_vals = {:farm_code => repr_carton.farm_code,:puc => repr_carton.puc,:spray_program_code => repr_carton.spray_program_code,:extended_fg_code => repr_carton.extended_fg_code, :organization_code => repr_carton.organization_code, :target_market_code => repr_carton.target_market_code, :inventory_code => repr_carton.inventory_code, :inspection_type_code => repr_carton.inspection_type_code, :production_run_code => repr_carton.production_run_code, :sell_by_code => repr_carton.sell_by_code,:erp_cultivar => repr_carton.erp_cultivar,:track_indicator_code => repr_carton.track_indicator_code }

        repr_carton.reworks_action = "reclassified" if repr_carton.reworks_action.upcase!= "ALT_PACKED"
        self.export_attributes(repr_carton, true, unchanged_fields)
        repr_carton.decompose_fields
        repr_carton.changed_fields?
        errs = repr_carton.derive_fields
        puts errs if errs != ""
        raise errs if errs != ""
        cartons_updated += update_group(repr_carton, old_vals)
        puts "group updated"
     # rescue
     #   raise "Group update from representative carton: " + repr_carton.carton_number.to_s + " failed. Reason:<BR>" + $!
    #  end
    end

    raise "No cartons were updated" if cartons_updated == 0
    return cartons_updated

  end



  def update_group(carton, old_vals)
    carton.reworks_action = "reclassified" if carton.reworks_action.upcase != "ALT_PACKED"
    carton.items_per_unit = 0 if !carton.items_per_unit
    carton.units_per_carton = 0 if !carton.units_per_carton



    set_str = "commodity_code = $$#{carton.commodity_code}$$,
                unit_pack_product_code = $$#{carton.unit_pack_product_code}$$,
                carton_mark_code = $$#{carton.carton_mark_code}$$,
                target_market_code = $$#{carton.target_market_code}$$,
                variety_short_long = $$#{carton.variety_short_long}$$,
                fg_code_old = $$#{carton.fg_code_old}$$,
                inspection_type_code = $$#{carton.inspection_type_code}$$,
                actual_size_count_code = $$#{carton.actual_size_count_code}$$,
                grade_code = $$#{carton.grade_code}$$,
                old_pack_code = $$#{carton.old_pack_code}$$,
                treatment_code = $$#{carton.treatment_code}$$,
                product_class_code = $$#{carton.product_class_code}$$,
                erp_cultivar = $$#{carton.erp_cultivar}$$,
                pc_code = $$#{carton.pc_code}$$,
                inventory_code = $$#{carton.inventory_code}$$,
                farm_code = $$#{carton.farm_code}$$,
                carton_fruit_nett_mass = $$#{carton.carton_fruit_nett_mass}$$,
                pick_reference = $$#{carton.pick_reference}$$,
                line_code = $$#{carton.line_code}$$,
                shift_code = $$#{carton.shift_code}$$,
                organization_code = $$#{carton.organization_code}$$,
                puc = $$#{carton.puc}$$,
                fg_product_code = $$#{carton.fg_product_code}$$,
                production_run_code = $$#{carton.production_run_code}$$,
                production_run_id = $$#{carton.production_run_id}$$,
                account_code = $$#{carton.account_code}$$,
                egap = $$#{carton.egap}$$,
                sell_by_code = $$#{carton.sell_by_code}$$,
                items_per_unit = #{carton.items_per_unit.to_s},
                units_per_carton = #{carton.units_per_carton.to_s},
                fg_mark_code = $$#{carton.fg_mark_code}$$,
                extended_fg_code = $$#{carton.extended_fg_code}$$,
                reworks_action = $$#{carton.reworks_action}$$,
                spray_program_code = $$#{carton.spray_program_code}$$,
                track_indicator_code = $$#{carton.track_indicator_code}$$"

    return RwActiveCarton.update_all(ActiveRecord::Base.extend_set_sql_with_request(set_str,"rw_active_cartons"), "rw_run_id = #{self.rw_run_id} AND sell_by_code = $$#{old_vals[:sell_by_code]}$$ AND extended_fg_code = $$#{old_vals[:extended_fg_code]}$$ AND
                               organization_code = $$#{old_vals[:organization_code]}$$ AND puc = $$#{old_vals[:puc]}$$ AND target_market_code = $$#{old_vals[:target_market_code]}$$ AND
                               inventory_code = $$#{old_vals[:inventory_code]}$$ AND production_run_code = $$#{old_vals[:production_run_code]}$$ AND
                               inspection_type_code = $$#{old_vals[:inspection_type_code]}$$ AND track_indicator_code = $$#{old_vals[:track_indicator_code]}$$ AND  spray_program_code = $$#{old_vals[:spray_program_code]}$$  AND
                               erp_cultivar = $$#{old_vals[:erp_cultivar]}$$ and rw_receipt_unit = 'carton' and farm_code = $$#{old_vals[:farm_code]}$$ ")
  end


  def scrap(reason, user)
    self.transaction do

      scrap_carton = RwScrapCarton.new
      self.rw_receipt_carton.export_attributes(scrap_carton, true)
      scrap_carton.rw_reason_id      = reason.id
      scrap_carton.user_name         = user.user_name
      now                            = Time.now
      scrap_carton.rw_scrap_datetime = now
      scrap_carton.person            = user.person.last_name + "," + user.person.first_name
      scrap_carton.rw_receipt_carton = self.rw_receipt_carton
      scrap_carton.create
      self.pallet_id     = nil
      self.pallet_number = nil
      self.destroy
    end

  end


  def check_target_market_validity_for_bulk_update
    #------------
    #pallet check
    #------------
    err_list    = Array.new

    carton_orgs = self.connection.select_all("select distinct organization_code from rw_active_cartons where rw_run_id = #{self.rw_run_id.to_s}")
    carton_orgs.each do |carton_org|
      if !TargetMarket.is_valid_for_org?(carton_org["organization_code"], self.target_market_short)
        err_list.push(["cartons", carton_org["organization_code"], self.target_market_short])
      end
    end

    return err_list

  end


  #-------------------------------------------------------------------------
  #This method does a bulk update of the target market of all cartons in the
  #reworks run
  #--------------------------------------------------------------------------
  def update_all_target_market()

    RwActiveCarton.update_all(ActiveRecord::Base.extend_set_sql_with_request("target_market_code ='#{self.target_market_code}',reworks_action = 'reclassified'","rw_active_cartons"), "rw_run_id =#{self.rw_run_id.to_s}")

  end

  #-------------------------------------------------------------------------
  #This method receives variables:
  #-> org
  #-> carton_mark_code
  #-> grade_code
  #-> class_code
  #-> inspect_type_code
  #-> target_market code
  #-> grade code
  #-> inventory code
  #
  #Process: 1) if class or grade changed, lookup the IPC with new class and grade
  #         2) if carton_mark_code changed, lookup the fg_mark_code with new carton_mark
  #         3) lookup extended_fg_code if 1) or 2)or org changed
  #         4) update inspect_type- validate if FK (grade + inspect type is correct)
  #         5) update inventory_code_short- validate FK (must exist for org)
  #         6) update target_market_short- validate FK (must exist for org)
  #-------------------------------------------------------------------------------------
  def update_from_pallet(params)
    #begin
    ipc_changed  = nil
    ipc          = nil
    mark_changed = nil
    org_changed  = nil
    extended_fg  = ExtendedFg.find_by_extended_fg_code(self.extended_fg_code)
    fg_product   = FgProduct.find_by_fg_product_code(extended_fg.fg_code)
    fg_code      = nil

    #---------------
    #Get correct IPC
    #---------------
    ipc          = fg_product.item_pack_product
    if params['grade_code'] && params['grade_code'] != self.grade_code
      self.grade_code = params['grade_code']
      ipc_changed     = true
    end
    if params['product_class_code'] && params['product_class_code'] != self.product_class_code
      self.product_class_code = params['product_class_code']
      ipc_changed             = true
    end


    if ipc_changed
      ipc = ItemPackProduct.find_by_commodity_code_and_marketing_variety_code_and_actual_count_and_product_class_code_and_grade_code_and_cosmetic_code_name_and_size_ref_and_basic_pack_code(ipc.commodity_code, ipc.marketing_variety_code, ipc.actual_count, self.product_class_code, self.grade_code, ipc.cosmetic_code_name, ipc.size_ref, ipc.basic_pack_code)
      if !ipc
        msg = "An Item Pack product could not be found for values: <BR>"
        msg += "commodity: " + ipc.commodity_code + "<BR>"
        msg += "marketing_variety: " + ipc.marketing_variety_code + "<BR>"
        msg += "actual count: " + ipc.actual_count + "<BR>"
        msg += "product_class_code: " + self.product_class_code + "<BR>"
        msg += "grade_code: " + self.grade_code + "<BR>"
        msg += "cosmetic code: " + ipc.cosmetic_code_name + "<BR>"
        msg += "size_ref: " + ipc.size_ref_code + "<BR>"
        msg += "basic_pack: " + ipc.basic_pack_code
        return send_message(msg)

      end

      fg_record = FgProduct.find_by_item_pack_product_code_and_unit_pack_product_code_and_carton_pack_product_code(ipc.item_pack_product_code, fg_product.unit_pack_product_code, fg_product.carton_pack_product_code)
      if !fg_record
        msg = "A finished good product could not be found for values: <BR>"
        msg += " Item pack product: " + ipc.item_pack_product_code + "<BR>"
        msg += " Unit pack product: " + fg_product.unit_pack_product_code + "<BR>"
        msg += " Item pack product: " + fg_product.carton_pack_product_code + "<BR>"
        return send_message(msg)
      end

      fg_code = fg_record.fg_product_code
    else
      fg_code = extended_fg.fg_code
    end


    #-------------------
    #Get correct Fg_Mark
    #-------------------
    fg_mark = FgMark.find_by_fg_mark_code(extended_fg.fg_mark_code)
    if params['carton_mark_code'] && params['carton_mark_code'] != self.carton_mark_code
      self.carton_mark_code = params['carton_mark_code']
      mark_changed          = true
    end

    if mark_changed
      temp_ru_mark = fg_mark.ru_mark_code
      temp_ri_mark = fg_mark.ri_mark_code
      fg_mark      = FgMark.find_by_tu_mark_code_and_ru_mark_code_and_ri_mark_code(self.carton_mark_code, fg_mark.ru_mark_code, fg_mark.ri_mark_code)
      if !fg_mark
        msg = "An FG Mark code could not be found for values: <BR>"
        msg += "Carton mark: " + self.carton_mark_code + "<BR>"
        msg += "Retail unit mark: " + temp_ru_mark + "<BR>"
        msg += "Retail item mark: " + temp_ri_mark + "<BR>"
        return send_message(msg)
      end
    end

    fg_mark_code = fg_mark.fg_mark_code

    if params['organization_code'] && params['organization_code'] != self.organization_code
      self.organization_code = params['organization_code']
      org_changed            = true
    end

    #----------------------------------------------
    #Get extended fg
    #----------------------------------------------
    if ipc_changed || mark_changed || org_changed
      extended_fg = ExtendedFg.find_by_fg_code_and_units_per_carton_and_fg_mark_code_and_marketing_org_code(fg_code, extended_fg.units_per_carton, fg_mark_code, self.organization_code)
      if !extended_fg
        msg = "An extended FG code could not be found for values: <BR>"
        msg += "FG code: " + fg_code + "<BR>"

        msg += "FG mark code: " + fg_mark_code + "<BR>"
        msg += "Marketing org: " + self.organization_code + "<BR>"
        return send_message(msg)
      end
      self.extended_fg_code = extended_fg.extended_fg_code
    end

    #-------------
    #Target market
    #-------------


    if params['target_market_code']
      params['target_market_code'] = params['target_market_code'].split("_")[0]
      if !OrganizationsTargetMarket.find_by_short_description_and_target_market_name(self.organization_code, params['target_market_code'])
        raise "Target market: " + params['target_market_code'] + " does not exist for org: " + self.organization_code
      else
        self.target_market_short = params['target_market_code']
      end
    end


    if params['inventory_code']
      params['inventory_code'] = params['inventory_code'].split("_")[0]
      if !InventoryCodesOrganization.find_by_short_description_and_inv_code(self.organization_code, params['inventory_code'])
        raise "Inentory code: " + params['inventory_code'] + " does not exist for org: " + self.organization_code
      else
        self.inventory_code_short = params['inventory_code']
      end
    end

    if params['inspection_type_code']
      if !InspectionType.find_by_inspection_type_code_and_grade_code(params['inspection_type_code'], ipc.grade_code)
        raise "Inspection type : " + params['inspection_type_code'] + " does not exist for grade: " + ipc.grade_code
      else
        self.inspection_type_code = params['inspection_type_code']
      end
    end

    return derive_fields
    #rescue
    # raise "Carton: " + self.carton_number.to_s + " could not be updated. Reason: <BR>" + $!
    #end
  end


  #-------------------------------------------------
  #This method stores the address result in a hash
  #If the hash contains an :error symbol, the address
  #could not be found
  #-------------------------------------------------
  def get_org_address

    result            = Hash.new

    #org = Organization.find_by_short_description(self.organization_code)
    #contact_method = ContactMethodsParty.find_by_party_name_and_contact_method_type_code(org.party.party_name,"CARTON_LABEL_ADDRESS").contact_method

    contact_method_id = self.connection.select_one("select contact_method_id from contact_methods_parties where (party_name = '#{self.organization_code}' and contact_method_type_code = 'CARTON_LABEL_ADDRESS')")


    if !contact_method_id
      result[:error] = "You must define a contact method of type 'CARTON_LABEL_ADDRESS' for the marketing org(" + self.organization_code + ")"
    else

      contact_method = self.connection.select_all("select * from contact_methods where id = #{contact_method_id['contact_method_id'].to_s}")[0]

      address_1      = contact_method['contact_method_code']
      address_2      = contact_method['contact_method_description']
      if (address_1 == nil||address_2 == nil)
        result[:error] = "You must define both address lines for the contact method of type: 'CARTON_LABEL_ADDRESS' for the marketing org(" + self.organization_code + ")"
      else
        result[:address1]= address_1
        result[:address2]= address_2
      end
    end
    return result
  end

  def print_label(http_conn,user_name = nil)

    @http_conn = http_conn
    address = get_org_address
    if !address[:error]
      self.address_line1 = address[:address1]
      self.address_line2 = address[:address2]

    else
      raise address[:error]
    end
    data              = build_label_data
    print_instruction = build_instruction(data)

    puts print_instruction

    http_conn.get("/" + print_instruction, nil)
    puts "label printed"
    self.n_labels_printed = 0 if !self.n_labels_printed
    self.n_labels_printed += 1
    if user_name
      self.reprint_acknowledged_by = user_name
      self.reprint_acknowledged_date_time = Time.now()
    end
    self.reworks_action = "RECLASSIFIED" if self.reworks_action.upcase() != "ALT_PACKED"
    self.update
    return print_instruction

  end

  def build_instruction(label_data)

    label_intruction = "<ProductLabel PID=\"223\" Status=\"true\" PrinterIP=\"#{@http_conn.address}\" RunNumber=\""
    label_intruction += self.production_run_code + "\" Code=\""
    label_intruction += "RW" + "\" F0=\"" + "E2" + "\" "

    for i in 1..label_data.length()
      key = "F" + i.to_s
      val = ""
      if label_data.has_key?(key)
        val              = label_data[key].to_s
        field            = key + "=\"" + val + "\""
        label_intruction += field + " "
      end
    end
    label_intruction += "Msg=\"OK\" />"

    return label_intruction

  end


  def build_label_data
    data         = Hash.new

    str_num      = self.carton_number.to_padded_s(12)
    gtin_barcode = nil

    gtin         = get_gtin()

    if gtin
      gtin_barcode = "^01" + gtin + "10" + self.production_run.batch_code().to_s
    else
      gtin_barcode = "0110" + self.production_run.batch_code().to_s
    end

    self.inventory_code_short = self.inventory_code.split("_")[0]

    data.store("F1", gtin_barcode)
    data.store("F2", str_num)

    long_variety = self.variety_short_long
    labeling_variety  = "(" + long_variety.slice(0,3) + ")" +  long_variety.slice(3,long_variety.length())

    data.store("F3", labeling_variety)
    data.store("F4", self.commodity_code)
    brand_code      = Mark.find_by_mark_code(self.carton_mark_code).brand_code

    commodity_descr = self.connection.select_one("select commodity_description_long from commodities where commodity_code = '#{self.commodity_code}'")['commodity_description_long']

    data.store("F5", commodity_descr)
    data.store("F6", brand_code)
    data.store("F7", self.old_pack_code)
    data.store("F8", self.actual_size_count_code)
    data.store("F9", self.inventory_code_short)
    data.store("F10", self.grade_code)
    data.store("F11", self.production_run.batch_code())
    data.store("F12", self.pick_reference)
    data.store("F13", self.puc)
    data.store("F14", self.egap.to_s)
    data.store("F15", self.target_market_code)
    class_code = ProductClass.find_by_product_class_code(self.product_class_code).product_class_description
    data.store("F16", class_code)

    data.store("F19", self.organization_code)
    line_phc = self.production_run.line.line_phc
    data.store("F20", line_phc)
    packer = ""
    packer = self.packer_number.slice(2, 8) if self.packer_number
    data.store("F21", packer)

    gtin_readable = nil
    if gtin
      #user batch number
      gtin_readable = "(01)" + gtin + "(10)" + self.production_run.batch_code().to_s
    else
      gtin_readable = "(01)(10)" + self.production_run.batch_code().to_s

    end

    data.store("F22", gtin_readable)
    data.store("F23", self.address_line1)
    data.store("F24", self.address_line2)

    print_count = false

    pm_type     = get_packmaterial_type_for_ru()
    if pm_type
      if pm_type == "T"
        print_count = true
      else
        print_count = false
      end
    end

    if print_count == true
      data.store("F25", "COUNT:")
    else
      data.store("F25", "")
    end

    marking         = ""
    diameter        = ""

    marking_heading = ""
    if self.marking && self.marking.strip != "" && self.marking != "*"
      marking_heading = "MARKING"
      marking         = self.marking
    end

    diameter_heading = ""
    if self.diameter && self.diameter.strip != "" && self.diameter != "*"
      diameter_heading = "DIAMETER/WEIGHT"
      diameter         = self.diameter
    end

    data.store("F17", marking)
    data.store("F18", diameter)

    data.store("F26", diameter_heading)
    data.store("F27", marking_heading)
    ntc = Puc.find_by_puc_code(self.puc).nature_choice_certificate_code
    ntc = "" if !ntc
    data.store("F28", ntc)
    pfp =""
    pfp = self.rw_active_pallet.pallet_format_product_code if self.rw_active_pallet
    data.store("F29", self.extended_fg_code)
    data.store("F30", pfp)
    data.store("F31", self.sell_by_code)

    orchard_printed = false

    if self.carton.bin
      if self.carton.bin.orchard_code && (self.target_market_code.split("_")[0].upcase == "NI"||self.target_market_code.split("_")[0].upcase == "FE")
        data.store("F32", "ORCHARD")
        data.store("F33", self.carton.bin.orchard_code)
        orchard_printed = true
      end
    end

    if !orchard_printed
      data.store("F32","")
      data.store("F33","")
    end

    if Globals.tms_for_tu_mass_printing.include?(self.target_market_code.split("_")[0])
      tu_mass = FgProduct.find_by_fg_product_code(self.fg_product_code).carton_pack_product.nett_mass
      if tu_mass && tu_mass != ""
       data.store("F34","Nett Mass")
       data.store("F35",tu_mass.to_s + " kg")
      end

    end



    @label_data = data
    return data

  end

  def get_gtin(brand_code = nil)


    inv_vals                  = self.inventory_code.split("_")
    self.inventory_code_short = inv_vals[0]
    brand_code = self.connection.select_one("select brand_code from marks where mark_code = '#{self.carton_mark_code}'")['brand_code'] if !brand_code
    variety_vals                = self.variety_short_long.split("_")
    self.marketing_variety_code = variety_vals[0]


    query                       = "SELECT
            public.gtins.gtin_code
            FROM
            public.gtins
            WHERE
            (now() < public.gtins.date_to and now() > public.gtins.date_from)AND
            (public.gtins.organization_code = '#{self.organization_code.to_s}') AND
            (public.gtins.commodity_code = '#{self.commodity_code.to_s}') AND
            (public.gtins.marketing_variety_code = '#{self.marketing_variety_code.to_s}') AND
            (public.gtins.old_pack_code = '#{self.old_pack_code.to_s}') AND
            (public.gtins.brand_code = '#{brand_code}') AND
            (public.gtins.actual_count = '#{self.actual_size_count_code.to_s}') AND
            (public.gtins.grade_code = '#{self.grade_code.to_s}' AND
            (public.gtins.inventory_code = '#{self.inventory_code_short.to_s}'))"

    gtin                        = self.connection.select_one(query)
    if gtin
      self.gtin = gtin['gtin_code']
    end

    return self.gtin


    return gtin

  end

  def get_packmaterial_type_for_ru()
    if !self.unit_pack_product_code
      fg_product                  = FgProduct.find_by_fg_product_code(self.fg_product_code)
      self.unit_pack_product_code = fg_product.unit_pack_product.unit_pack_product_code
    end

    if self.unit_pack_product_code
      return self.connection.select_one("select type_code from unit_pack_products where unit_pack_product_code = '#{self.unit_pack_product_code}'")['type_code']
    end
  end


  def get_packmaterial_type_for_ru_old(carton_setup_id)

    query = "SELECT
	         public.unit_pack_products.type_code
	         FROM
	         public.unit_pack_products
	         INNER JOIN public.retail_unit_setups ON (public.unit_pack_products.id = public.retail_unit_setups.unit_pack_product_id)
	         INNER JOIN public.carton_setups ON (public.retail_unit_setups.carton_setup_id = public.carton_setups.id)
	         WHERE
	         (public.carton_setups.id = '#{carton_setup_id}')"

    val   = connection.select_all(query)
    if val.length > 0
      return val[0]["type_code"]
    else
      return nil
    end
  end

  def get_calculated_mass(fg_product)
    #-------------------------------------------------------------------------------------------------------------
    #calculate carton mass as follows:
    #trade_unit nett mass default is: cpc nett mass, but if retail_unit has mass,
    #then trade unit nett mass = standard_count avg weight(i.e. fruit weight) * items per unit * units_per_carton
    #-------------------------------------------------------------------------------------------------------------
    carton_pack_product = fg_product.carton_pack_product
    carton_fruit_mass   = carton_pack_product.nett_mass
    fruit_mass          = fg_product.item_pack_product.standard_size_count.standard_count.average_weight_gm.to_f

    #fruit_mass = Float.round_float(2,fruit_mass/1000)
    if fruit_mass && fruit_mass > 0
      fruit_mass = fruit_mass/1000
    end

    if fruit_mass && fruit_mass > 0 && self.units_per_carton && self.units_per_carton.to_i > 0 && self.items_per_unit && self.items_per_unit.to_i > 0

      carton_fruit_mass = fruit_mass * self.items_per_unit.to_i

    end

    carton_fruit_mass = Float.round_float(2, carton_fruit_mass) if carton_fruit_mass && carton_fruit_mass > 0
    puts "mass: " + carton_fruit_mass.to_s
    return carton_fruit_mass

  end


  def derive_puc_account
    if !self.is_depot_carton

        fpa = FarmPucAccount.get_record_for_farm_and_marketer(self.farm_code, self.organization_code)
        if !fpa
          msg = "A farm_puc_account record does not exist for farm: " + self.farm_code + " and marketer: " + self.organization_code
          raise msg
        end

        puts "NON DP_DERIVING FARM-PUC"

        self.puc          = fpa.puc_code
        self.account_code = fpa.account_code
        puc               = Puc.find_by_puc_code(fpa.puc_code)
        self.egap         = puc.eurogap_code


    end


  end


  def send_message(msg)

    return "Carton: " + self.carton_number.to_s + " could not be updated. Trying to save new values created the following problem: <BR>" + msg
  end


  def derive_fields()
    require 'date'
    #----------------------------------------------------------------------------------------
    #Derived fields are: pick_ref,target_market_code,inventory_code, fg_product_code
    #                    fg_code_old,commodity_code,variety_short_long,actual size count code,
    #                    grade_code,product class code,erp_cultivar,treatment_code
    #----------------------------------------------------------------------------------------

    #------------
    #VALIDATIONS:
    #------------
    msg = ""

    if !self.changed_fields
      self.changed_fields?
    end

    changed = self.changed_fields

    if self.target_market_short == ""
      msg += "<BR>You must select a valid target market(target_market_short)"
    end

    if self.inventory_code_short == ""
      msg += "<BR>You must select a valid inventory code(inventory_code_short)"
    end

    return send_message(msg) if msg != ""


    extended_fg                   = ExtendedFg.find_by_extended_fg_code(self.extended_fg_code)

    self.organization_code        = extended_fg.marketing_org_code

    #--------------------------------------------------------------Prev impl
#   if self.commodity_code != extended_fg.commodity_code
#     msg = "You cannot change the commodity code of a carton(from: " + self.commodity_code + ", to: " + extended_fg.commodity_code + ")"
#     return send_message(msg)
#   end
#
#
#   input_variety_code = self.production_run.production_schedule.rmt_setup.variety_code
#   input_variety = RmtVariety.find_by_commodity_code_and_rmt_variety_code(self.commodity_code,input_variety_code)
#   if !input_variety
#     return send_message("input variety not found for commodity: " + self.commodity_code + " and input variety: " + input_variety_code)
#   end
#---------------------------------------------------


    run                           = ProductionRun.find_by_production_run_code(self.production_run_code)
    self.production_run           = run

    self.line_code                = run.line_code
    self.shift_code               = run.shift_code

    fg_product                    = FgProduct.find_by_fg_product_code(extended_fg.fg_code)

    self.item_pack_product_code   = fg_product.item_pack_product_code
    self.unit_pack_product_code   = fg_product.unit_pack_product_code
    self.carton_pack_product_code = fg_product.carton_pack_product_code

    self.units_per_carton         = extended_fg.units_per_carton

    self.fg_product_code          = fg_product.fg_product_code
    ipc                           = fg_product.item_pack_product
    self.commodity_code           = ipc.commodity_code

    marketing_variety_description = MarketingVariety.find_by_marketing_variety_code_and_commodity_code(ipc.marketing_variety_code, ipc.commodity_code).marketing_variety_description.to_s
    self.variety_short_long       = ipc.marketing_variety_code + "_" + marketing_variety_description

    self.grade_code               = ipc.grade_code
    #-------------------------------------------------
    #Do inspection type lookup- must exist for the inspect type
    #--------------------------------------------------
    if !InspectionType.find_by_inspection_type_code_and_grade_code(self.inspection_type_code, self.grade_code)
      return send_message("Inspection type: " + self.inspection_type_code + " does not exist for grade: " + self.grade_code)
    end

    self.product_class_code = ipc.product_class_code
    self.treatment_code     = ipc.treatment_code

    if self.target_market_short && self.target_market_short != ""
      if !TargetMarket.is_valid_for_org?(self.organization_code, self.target_market_short)
        return send_message("Target market: " + self.target_market_short + " does not exist for organization: " + self.organization_code)
      end
      target_market           = TargetMarket.find_by_target_market_name(self.target_market_short)
      self.target_market_code = target_market.target_market_name + "_" + target_market.target_market_description
    end

    #pick_ref = iso_week + carton_template.getPc_code_num() + iso_week.substring(1,2);
    pc_num = self.pc_code.slice(2, 1)
    if self.pc_code.slice(2..3)== "-1"
      pc_num = self.line_code
    end

    wday = Date.today.wday
    wday = 7 if wday == 0


    iso_week = self.iso_week_code

    if self.reworks_action && self.reworks_action.index("alt_packed")
      iso_week = Date.today.cweek.to_s
      #Gerrit Add on 30/12/2008
      iso_week = "0" + iso_week if iso_week.length() == 1
      self.pick_reference = iso_week.slice(1..1) + wday.to_s + pc_num + iso_week.slice(0..0)
    end


    #iso_week.substring(1,2) + String.valueOf(weekday) + pc_code + iso_week.substring(0,1);;


    if self.inventory_code_short && self.inventory_code_short != ""
      org_inv = nil
      if !(org_inv = InventoryCodesOrganization.find_by_short_description_and_inv_code(self.organization_code, self.inventory_code_short))
        return send_message("Inventory code: " + self.inventory_code_short + " does not exist for organization: " + self.organization_code)
      end
      self.inventory_code = self.inventory_code_short + "_" + org_inv.inventory_code.inventory_name
    end

    #---------------------------------------------
    #calculate carton_mark_code + extended fg_code
    #---------------------------------------------
    fg_mark               = FgMark.find_by_fg_mark_code(extended_fg.fg_mark_code)
    self.fg_mark_code     = extended_fg.fg_mark_code
    self.carton_mark_code = fg_mark.tu_mark_code
    units                 = "*"
    units = extended_fg.units_per_carton.to_s if self.units_per_carton && self.units_per_carton > 0

    #---------------------
    #calculate old fg code
    #---------------------

    @brand_code = Mark.find_by_mark_code(fg_mark.tu_mark_code).brand_code
    puts "BRAND: " + @brand_code
    size_count   = ipc.actual_count.to_s
    actual_count = size_count
    actual_count = ipc.size_ref if ipc.size_ref && ipc.size_ref.upcase != "NOS"
    self.fg_code_old            = extended_fg.old_fg_code
    self.actual_size_count_code = actual_count

    if !extended_fg.old_fg_code
      return send_message("Extended fg code: " + extended_fg.extended_fg_code + " does not have an old fg code defined!")
    end

    if !extended_fg.tu_nett_mass
      return send_message("Extended fg code: " + extended_fg.extended_fg_code + " has no tu nett mass defined!")
    end

    self.old_pack_code = extended_fg.old_fg_code.split(" ")[3]
    self.marking       = extended_fg.ru_description
    self.diameter      = extended_fg.ri_diameter_range
    self.diameter = nil if self.diameter && self.diameter.strip == ""
    self.diameter = extended_fg.ri_weight_range if !self.diameter


    self.carton_fruit_nett_mass = extended_fg.tu_nett_mass


    #--------------------------------------------------------------
    #Puc and account must be looked up from table farm_puc_accounts
    #egap must be looked up from pucs table
    #--------------------------------------------------------------

    farm_code = nil

    if self.bin_id
      farm_code = self.farm_code
    else
      farm_code = run.farm_code
    end



    if !self.is_depot_carton
      if self.changed_fields.has_key?('production_run_code')||self.changed_fields.has_key?('puc')||self.changed_fields.has_key?('farm_code')||self.changed_fields.has_key?('organization_code')||self.changed_fields.has_key?('extended_fg_code')
        fpa = FarmPucAccount.get_record_for_farm_and_marketer(farm_code, self.organization_code)
        if !fpa
          msg = "A farm_puc_account record does not exist for farm: " + farm_code + " and marketer: " + self.organization_code
          return send_message(msg)
        end

        puts "NON DP_DERIVING FARM-PUC"

        self.puc          = fpa.puc_code
        self.farm_code    = run.farm_code if !self.bin_id
        self.account_code = fpa.account_code
        puc               = Puc.find_by_puc_code(fpa.puc_code)
        self.egap         = puc.eurogap_code
      end

    end




    #-----------------------------------------
    #rule: rmt_variety cannot be changed ever
    #-----------------------------------------

    old_record           = RwActiveCarton.find(self.id)

    potential_rmt_change = old_record.production_run_code != self.production_run_code || old_record.extended_fg_code != self.extended_fg_code


    old_variety          = old_record.production_run.production_schedule.rmt_setup.variety_code
    old_commodity        = old_record.commodity_code
    old_erp_cultivar     = old_record.erp_cultivar

    rmt_setup            = self.production_run.production_schedule.rmt_setup
    new_variety          = rmt_setup.variety_code
    new_track_indicator = rmt_setup.output_track_indicator_code

    self.track_indicator_code =  new_track_indicator if old_record.production_run_code != self.production_run_code
    if old_record.production_run_code != self.production_run_code
      self.spray_program_code =  rmt_setup.treatment_code
        puts "NEW SPRAY: "  + rmt_setup.treatment_code
    end

    #----------------------------------------------------------------------
    #Commodity could have been changed from production run change by user or
    #by extended fg change. Check for both- neither is allowed
    #-----------------------------------------------------------------------
    new_commodity        = rmt_setup.commodity_code
    new_commodity = self.commodity_code if new_commodity == old_commodity

    from    = "from: " + old_commodity + ":" + old_variety
    to      = "to: " + new_commodity + ":" + new_variety
    from_to = from + "<BR>" + to


    if !(old_variety == new_variety && old_commodity == new_commodity) && potential_rmt_change
      #comment out line below to sidestep error
      return send_message("Raw material properties(commodity/input variety)cannot be changed for a carton.<BR>" + from_to + "<BR> propable cause: production run change in bulk update")
    end

    input_variety     = RmtVariety.find_by_commodity_code_and_rmt_variety_code(self.commodity_code, new_variety)
    self.erp_cultivar = input_variety.rmt_variety_code + "_" + input_variety.rmt_variety_description.to_s


    if  self.changed_fields.has_key?('pick_reference')
      pack_date = DepotPallet.calc_packdate_from_pick_ref(self.pick_reference,self.season_code)
      self.pack_date_time = pack_date.to_datetime

    end

    # if self.erp_cultivar != old_erp_cultivar  &&  potential_rmt_change
    #comment out line below to sidestep error
    #   return send_message(" You cannot change the raw material of a carton. From: " + old_erp_cultivar + ", to: " + self.erp_cultivar + "<BR>:propable cause: production run change in bulk update")
    #end


    get_gtin(@brand_code)



    return ""

  end

  def update_pallet(pallet,reset_ctn_qty = true,set_build_state_to_partial = true)

    self.decompose_fields

    self.export_attributes(pallet, true,['account_code','is_depot_pallet', 'consignment_note_number','exit_ref'])

    pallet.build_status             = "partial" if set_build_state_to_partial
    pallet_template                 = nil

    pallet.size_count_code          = self.actual_size_count_code
    pallet.marketing_variety_code   = self.marketing_variety_code
    pallet.carton_quantity_actual   = 0   if reset_ctn_qty
    pallet.country_origin_code      = "za"
    pallet.pick_reference_code      = self.pick_reference
    pallet.inspect_type_code        = self.inspection_type_code
    pallet.cold_store_code     = self.cold_store_code
    pallet.class_code               = self.product_class_code
    pallet.date_time_created        = Time.now
    pallet.pallet_template_id       = nil
   # pallet.process_status           = "palletizing"
    pallet.rw_run_id                = self.rw_run_id  if pallet.respond_to?('rw_run_id')
    pallet.carton_pack_product_code = self.carton_pack_product_code

    pallet.set_account true

    return pallet

  end


  def create_pallet(pallet_format_product_code)

    self.decompose_fields

    pallet = RwActivePallet.new
    self.export_attributes(pallet, true)
    format_product                    = PalletFormatProduct.find_by_pallet_format_product_code(pallet_format_product_code)
    pallet.pallet_format_product_id   = format_product.id
    #pallet.carton_setup_id = self.carton_template.carton_setup_id if self.carton_template
    pallet.pallet_format_product_code = pallet_format_product_code
    pallet.pallet_id                  = nil
    #TODO uncomment for live
    new_sequence                      = MesControlFile.next_seq(3)

    new_pallet_num_str                = new_sequence.to_s + RwActivePallet.calc_check_digit(new_sequence.to_s)
    pallet.pallet_number              = new_pallet_num_str
    pallet.build_status               = "partial"
    pallet_template                   = nil #self.carton_template.carton_setup.pallet_template
    #pallet.ca_cold_room_code = pallet_template.ca_cold_room_code
    pallet.size_count_code            = self.actual_size_count_code
    pallet.marketing_variety_code     = self.marketing_variety_code
    pallet.carton_quantity_actual     = 0
    pallet.country_origin_code        = "za"
    pallet.pick_reference_code        = self.pick_reference
    pallet.inspect_type_code          = self.inspection_type_code
    pallet.cold_store_code            = self.cold_store_code
    pallet.class_code                 = self.product_class_code
    pallet.date_time_created          = Time.now
    pallet.qc_status_code             = "UNINSPECTED"
    pallet.qc_result_status           = nil
    pallet.pallet_template_id         = nil
    pallet.process_status             = "palletizing"
    pallet.is_new_pallet              = true
    pallet.rw_run_id                  = self.rw_run_id
    pallet.reworks_action             = "new_pallet"
    pallet.carton_pack_product_code   = self.carton_pack_product_code
    pallet.oldest_pack_date_time = Time.now()
    pallet.ppecb_inspection_id = nil
    pallet.load_detail_id = self.rw_active_pallet.load_detail_id
    #NAE 20150428 - keep consignment_note_number
    pallet.consignment_note_number = self.rw_active_pallet.consignment_note_number

pallet.create
    return pallet

  end


  def decompose_fields
    #fg
    extended_fg                   = ExtendedFg.find_by_extended_fg_code(self.extended_fg_code)
    fg_code                       = FgProduct.find_by_fg_product_code(extended_fg.fg_code)
    self.item_pack_product_code   = fg_code.item_pack_product_code
    self.unit_pack_product_code   = fg_code.unit_pack_product_code
    self.carton_pack_product_code = fg_code.carton_pack_product_code
    self.units_per_carton         = extended_fg.units_per_carton

    self.marking                  = extended_fg.ru_description
    self.diameter                 = extended_fg.ri_diameter_range
    self.diameter = nil if self.diameter && self.diameter.strip == ""
    self.diameter = extended_fg.ri_weight_range if !self.diameter

    #target_market
    tm_vals = self.target_market_code.split("_")
    self.target_market_short = tm_vals[0] if !self.target_market_short

    #inventory_code

    inv_vals = self.inventory_code.split("_")
    self.inventory_code_short = inv_vals[0] if !self.inventory_code_short

    self.marketing_variety_code = fg_code.item_pack_product.marketing_variety_code


  end
end
