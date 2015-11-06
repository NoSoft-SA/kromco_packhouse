class Carton < ActiveRecord::Base

  belongs_to :pallet
  belongs_to :bin

  attr_accessor :pack_date_from,:pack_date_to,:item_pack_product_code,:carton_pack_product_code,
                :production_schedule_name,:time_search

  attr_accessor :marketing_variety_code, :inventory_code_short, :facility_code, :location_code

  def get_inspection_cartons

    query = "select cartons.carton_number from cartons where pallet_number = '#{self.pallet_number}' and is_inspection_carton = true"
    nums = Carton.find_by_sql(query).map{|c|c.carton_number.to_s}
    if nums.delete(self.carton_number.to_s)
      nums.unshift(self.carton_number.to_s) #if this carton is inspection carton, make it first item in list
    end

     return nums

  end


   def Carton.encrypt_pick_ref(decrypted_pick_ref,commodity_code)
         pc_code =  decrypted_pick_ref.slice(0,1)
         pc_code = "2"  if  commodity_code.upcase()== "PL"

         iso_week_code = decrypted_pick_ref.slice(1,2)
         wday =  decrypted_pick_ref.slice(3,1)

         encrypted = iso_week_code.slice(1,1) + wday + pc_code + iso_week_code.slice(0,1)
         return encrypted


   end

   # Decrypt a pick reference number. Reversal of encrypt_pick_ref.
   #
   #   Pick ref (1234) ==> encrypt ==> (3412) ==> decrypt ==> (1234)
   #   If commodity_code is PL, encrypt ==> (3422) ==> decrypt ==> (2234)
   def self.decrypt_pick_ref(encrypted_pick_ref, commodity_code)
     encrypted_pick_ref[2,1] << encrypted_pick_ref[3,1] << encrypted_pick_ref[0,1] << encrypted_pick_ref[1,1]
   end


    def get_load_no
        stock_item = StockItem.find_by_inventory_reference(self.pallet_number)
        if stock_item && stock_item.stock_type_code
          return  stock_item.stock_type_code  #stock type code is temporarily being set to load_no
        end
        return nil
    end

    def create_pallet(pallet_format_product_code,set_load_no = nil,in_memory_only = nil)


    pallet = Pallet.new
    self.export_attributes(pallet,true)
    if set_load_no && load_no = get_load_no
      pallet.load_no = load_no
    end
    format_product = PalletFormatProduct.find_by_pallet_format_product_code(pallet_format_product_code)
    pallet.pallet_format_product_id = format_product.id
    #pallet.carton_setup_id = self.carton_template.carton_setup_id if self.carton_template
    pallet.pallet_format_product_code = pallet_format_product_code
    ### pallet.pallet_id = nil
    ### new_sequence = MesControlFile.next_seq(3)
    ### new_pallet_num_str = new_sequence.to_s + RwActivePallet.calc_check_digit(new_sequence.to_s)
    ### pallet.pallet_number = new_pallet_num_str.to_i
    # Happy
    new_sequence = MesControlFile.next_seq(3)
    new_pallet_num_str = new_sequence.to_s + RwActivePallet.calc_check_digit(new_sequence.to_s)
    pallet.pallet_number = new_pallet_num_str
    # end Happy
    #pallet.build_status = "partial"
    pallet_template = nil #self.carton_template.carton_setup.pallet_template
    #pallet.ca_cold_room_code = pallet_template.ca_cold_room_code
    pallet.size_count_code = self.actual_size_count_code
    fg_product = FgProduct.find_by_fg_product_code(self.fg_product_code)

    pallet.marketing_variety_code = fg_product.item_pack_product.marketing_variety_code
    pallet.carton_quantity_actual = 0
    pallet.country_origin_code = "za"
    pallet.pick_reference_code = self.pick_reference
    pallet.inspect_type_code = self.inspection_type_code
    pallet.cold_store_code = self.cold_store_code
    pallet.class_code = self.product_class_code
    pallet.date_time_created = Time.now
    pallet.qc_status_code = self.qc_status_code
    pallet.qc_result_status =  self.qc_result_status
    pallet.pallet_template_id = nil
    pallet.fg_code_old = self.fg_code_old
    pallet.fg_product_code = self.fg_product_code
    pallet.process_status = "palletized"
    pallet.is_new_pallet = true
    pallet.is_mapped = true


    err = Pallet.set_build_status(fg_product.carton_pack_product_code, pallet)
    raise err if err

    pallet.create  if !in_memory_only
    return pallet

    end

   def Carton.get_by_pallet_numbers(query, pallet_numbers)
#      if query.upcase().index("WHERE")!=nil
#          query = query.gsub!("where","WHERE")
#       else
#         query = query
#       end

     pallet_nums = Array.new
    for pallet_number in pallet_numbers
      pallet_number =  "\'" + pallet_number.to_s + "\'"
      pallet_nums <<  pallet_number
    end

     if query.index("WHERE")==nil
             from_split = query.split(/where/)
           else
             from_split = query.split(/WHERE/)
           end

         from_clause =from_split[0]

         where_split=from_split[1].split(/GROUP/)
         old_where_clause =  where_split[0]

         old_where_clause_clean= old_where_clause .gsub("((" , "").gsub("))","")
         old_where_clause_clean_split= old_where_clause_clean.split(/=/)
         where_left = old_where_clause_clean_split[0] + "="
         where_left =  where_left.gsub("(","")

         to_be_substituted =  old_where_clause_clean_split[1]
         str =  pallet_nums.join("  " + "OR"+ "  "+"#{where_left}" )
         str = str.gsub(")" , "")
         to_be_substituted = str
         #or_clause =to_be_substituted.gsub(/"#{to_be_substituted}" /,str)
         where_or_clause =   where_left + to_be_substituted

         closing_clause= "GROUP"+where_split[1]
         str_sql= from_clause + "where"   +"("  + where_or_clause + ")" +  closing_clause

      return str_sql


  end

  def Carton.get_by_pallet_numbers2(query, pallet_numbers)
#      if query.upcase().index("WHERE")!=nil
#          query = query.gsub!("where","WHERE")
#       else
#         query = query
#       end

     pallet_nums = Array.new
    for pallet_number in pallet_numbers
      pallet_number =  "\'" + pallet_number.to_s + "\'"
      pallet_nums <<  pallet_number
    end

     if query.index("WHERE")==nil
             from_split = query.split(/where/)
           else
             from_split = query.split(/WHERE/)
           end

         from_clause =from_split[0]

         where_split=from_split[1].split(/GROUP/)
         old_where_clause =  where_split[0]

         old_where_clause_clean= old_where_clause .gsub("((" , "").gsub("))","")
         old_where_clause_clean_split= old_where_clause_clean.split(/=/)
         where_left = old_where_clause_clean_split[0] + "="
         where_left =  where_left.gsub("(","")

         to_be_substituted =  old_where_clause_clean_split[1]
         str =  pallet_nums.join("  " + "OR"+ "  "+"#{where_left}" )
         str = str.gsub(")" , "")
         to_be_substituted = str
         #or_clause =to_be_substituted.gsub(/"#{to_be_substituted}" /,str)
         where_or_clause =   where_left + to_be_substituted


         str_sql= from_clause + "where"   +"("  + where_or_clause + ")"

      return str_sql


   end

  def Carton.build_and_exec_query(params,session = nil)


     query = "    SELECT  public.cartons.* FROM
           public.cartons
           INNER JOIN public.fg_products ON (public.cartons.fg_product_code = public.fg_products.fg_product_code)
           INNER JOIN public.production_runs ON (public.cartons.production_run_id = public.production_runs.id)
           INNER JOIN public.production_schedules ON (public.production_runs.production_schedule_id = public.production_schedules.id)
           WHERE (public.cartons.exit_reference is null "

      #----------------
      #Add conditions
      #----------------

      #NB: look at 'execute_production_run_step3'
      #pack date
      from_time = nil
      to_time = nil
      started = true

      puts params.to_s
      if params.key?('pack_date_from(1i)')
        query += " AND " if started
         from_time = Time.local(params['pack_date_from(1i)'],params['pack_date_from(2i)'],params['pack_date_from(3i)'],params['pack_date_from(4i)'],params['pack_date_from(5i)']).to_formatted_s(:db)
         to_time = Time.local(params['pack_date_to(1i)'],params['pack_date_to(2i)'],params['pack_date_to(3i)'],params['pack_date_to(4i)'],params['pack_date_to(5i)']).to_formatted_s(:db)
         query += "public.cartons.pack_date_time > '#{from_time}' AND public.cartons.pack_date_time < '#{to_time}'"
         started = true
      end

      #carton_number(textbox)
      if params['carton_number'] && params['carton_number'].strip != ""
        query += " AND " if started
        query += " public.cartons.carton_number = '#{params[:carton_number]}' "
        started = true
      end

       #iso_week_code (textbox)
      if params['iso_week_code'] && params['iso_week_code'].strip != ""
        query += " AND " if started
        query += " public.cartons.iso_week_code = '#{params[:iso_week_code]}' "
        started = true
      end

       #pallet_number (textbox)
      if params['pallet_number'] && params['pallet_number'].strip != ""
        query += " AND " if started
        query += " public.cartons.pallet_number = '#{params[:pallet_number]}' "
        started = true
      end

      #fg_product_code
       if params['fg_product_code']  != ""
        query += " AND " if started
        query += " public.cartons.fg_product_code = '#{params[:fg_product_code]}' "
        started = true
      end

      #item_pack_product_code
       if params['item_pack_product_code']  != ""
        query += " AND " if started
        query += " public.fg_products.item_pack_product_code = '#{params[:item_pack_product_code]}' "
        started = true
      end

      #unit_pack_product
      if params['unit_pack_product_code']  != ""
        query += " AND " if started
        query += " public.fg_products.unit_pack_product_code = '#{params[:unit_pack_product_code]}' "
        started = true
      end

      #carton_pack_product_code
      if params['carton_pack_product_code']  != ""
        query += " AND " if started
        query += " public.fg_products.carton_pack_product_code = '#{params[:carton_pack_product_code]}' "
        started = true
      end

       #grade_code
      if params['grade_code']  != ""
        query += " AND " if started
        query += " public.cartons.grade_code = '#{params[:grade_code]}' "
        started = true
      end

       #pc_code
      if params['pc_code']  != ""
        query += " AND " if started
        query += " public.cartons.pc_code like 'PC#{params[:pc_code]}%' "
        started = true
      end

      #track_indicator_code
      if params['track_indicator_code']  != ""
        query += " AND " if started
        query += " public.cartons.track_indicator_code = '#{params[:track_indicator_code]}' "
        started = true
      end

      #production_run_code
      if params['production_run_code']  != ""
        query += " AND " if started
        query += " public.production_runs.production_run_code = '#{params[:production_run_code]}' "
        started = true
      end

       #farm_code
      if params['farm_code']  != ""
        query += " AND " if started
        query += " public.production_runs.farm_code = '#{params[:farm_code]}' "
        started = true
      end

        #line_code
      if params['line_code']  != ""
        query += " AND " if started
        query += " public.production_runs.line_code = '#{params[:line_code]}' "
        started = true
      end

      #production_schedule_name
      if params['production_schedule_name']  != ""
        query += " AND " if started
        query += " public.production_runs.production_schedule_name = '#{params[:production_schedule_name]}' "
        started = true
      end

      #inventory_code
      if params['inventory_code']  != ""
        query += " AND " if started
        query += " public.cartons.inventory_code like '#{params[:inventory_code]}%' "
        started = true
      end

       #fg mark code
      if params['fg_mark_code']  != ""
        query += " AND " if started
        query += " public.cartons.fg_mark_code = '#{params[:fg_mark_code]}' "
        started = true
      end

      #organization_code
      if params['organization_code']  != ""
        query += " AND " if started
        query += " public.cartons.organization_code = '#{params[:organization_code]}' "
        started = true
      end

       #season_code (it's the 'season' field in seasons table)
      if params['season_code']  != ""
        query += " AND " if started
        query += " public.cartons.season_code = '#{params[:season_code]}' "
        started = true
      end

      if params['target_market_code']  != ""
        query += " AND " if started
        query += " public.cartons.target_market_code like '#{params[:target_market_code]}%' "
        started = true
      end

      query += ") LIMIT 1000"

      puts query
      if started
        #:::::::::LUKS CHANGE - ADDED ALL THE FOOLWING LINE OF CODE:::::::::
        session[:cached_query] = "Carton.find_by_sql(\"" + query + "\")"  if session
        return Carton.find_by_sql(query)
      else
       return nil
      end

  end


  def get_gtin(brand_code = nil)


        inv_vals = self.inventory_code.split("_")
        self.inventory_code_short = inv_vals[0]
        brand_code = self.connection.select_one("select brand_code from marks where mark_code = '#{self.carton_mark_code}'")['brand_code'] if !brand_code
        variety_vals = self.variety_short_long.split("_")
        self.marketing_variety_code = variety_vals[0]


        query = "SELECT
            public.gtins.gtin_code
            FROM
            public.gtins
            WHERE
            (now() < public.gtins.date_to and now() > public.gtins.date_from)AND
            (public.gtins.organization_code = '#{self.organization_code}') AND
            (public.gtins.commodity_code = '#{self.commodity_code}') AND
            (public.gtins.marketing_variety_code = '#{self.marketing_variety_code}') AND
            (public.gtins.old_pack_code = '#{self.old_pack_code}') AND
            (public.gtins.brand_code = '#{brand_code}') AND
            (public.gtins.actual_count = '#{self.actual_size_count_code}') AND
            (public.gtins.grade_code = '#{self.grade_code}' AND
            (public.gtins.inventory_code = '#{self.inventory_code_short}'))"


            gtin = self.connection.select_one(query)
            if gtin
              self.gtin = gtin['gtin_code']
            end

            return self.gtin


    return gtin

  end

   def Carton.get_gtin(organization_code,commodity_code,marketing_variety_code,old_pack_code,actual_size_count_code,grade_code,inventory_code_short,brand_code)

        query = "SELECT
            public.gtins.gtin_code
            FROM
            public.gtins
            WHERE
            (now() < public.gtins.date_to and now() > public.gtins.date_from)AND
            (public.gtins.organization_code = '#{organization_code}') AND
            (public.gtins.commodity_code = '#{commodity_code}') AND
            (public.gtins.marketing_variety_code = '#{marketing_variety_code}') AND
            (public.gtins.old_pack_code = '#{old_pack_code}') AND
            (public.gtins.brand_code = '#{brand_code}') AND
            (public.gtins.actual_count = '#{actual_size_count_code}') AND
            (public.gtins.grade_code = '#{grade_code}' AND
            (public.gtins.inventory_code = '#{inventory_code_short}'))"



            gtin = Carton.connection.select_one(query)
            if gtin
              gtin = gtin['gtin_code']
            end

            return gtin


    return gtin

  end


  def self.bulk_update(set_map,carton_nums=nil,additional_criteria=nil)
    updates = ""


    for key in set_map.keys
      updates += key.to_s + "=" + set_map[key].to_s + ","
    end
    updates.chop!

    conditions = ""
    if(carton_nums != nil)
      for carton_num in carton_nums
        conditions += "carton_number=" + carton_num.to_s + " or "
      end
    end

    if(additional_criteria != nil)
      for ikey in additional_criteria.keys
        conditions += ikey.to_s + "=" + additional_criteria[ikey].to_s + " or "
      end
    end
    puts "NULK UPDATE STMT = set(" + updates +")\n " + "where (" + conditions + ")"
    conditions.chop!.chop!.chop! if conditions.length > 3

    Carton.update_all(ActiveRecord::Base.extend_set_sql_with_request(updates,"cartons"), conditions )

  end


  def Carton.print_depot_labels(mapped_pallet_sequence_id,amount)
    puts " ==== In carton print function ===="
    cartons = Carton.find_by_sql("SELECT * FROM cartons WHERE mapped_pallet_sequence_id = '#{mapped_pallet_sequence_id}' LIMIT #{amount}")
    http_conn = Net::HTTP.new(Globals.get_label_printing_server_url, Globals.get_label_printing_server_port)
    n_printed = 0
    ActiveRecord::Base.transaction do
      cartons.each do |carton|
        carton.print_depot_label(http_conn)
        n_printed += 1
      end
    end
    if n_printed == amount
      return true
    else
      return false
    end
  end

  def print_depot_label(http_conn)
    address = get_org_address
    if !address[:error]
      self.address_line1 = address[:address1]
      self.address_line2 = address[:address2]

    else
     raise address[:error]
    end
    data = build_depot_label_data
    print_instruction = build_instruction(data)

    puts " ::: MY PRINT INSTR :: " + print_instruction.to_s

    response = http_conn.request_get("/" + print_instruction.to_s)
    #puts "label printed"
    if response.body.to_s.strip == ""
      self.n_labels_printed = 0 if !self.n_labels_printed
      self.n_labels_printed += 1
      self.update
    else
      raise "pallet labels could not be printed!"
    end
    #return print_instruction
  end

  #-------------------------------------------------
  #This method stores the address result in a hash
  #If the hash contains an :error symbol, the address
  #could not be found
  #-------------------------------------------------
  def get_org_address
     result = Hash.new

     #org = Organization.find_by_short_description(self.organization_code)
     #contact_method = ContactMethodsParty.find_by_party_name_and_contact_method_type_code(org.party.party_name,"CARTON_LABEL_ADDRESS").contact_method

     contact_method_id = ActiveRecord::Base.connection.select_one("select contact_method_id from contact_methods_parties where (party_name = '#{self.organization_code}' and contact_method_type_code = 'CARTON_LABEL_ADDRESS')")


       if !contact_method_id
         result[:error] = "You must define a contact method of type 'CARTON_LABEL_ADDRESS' for the marketing org(" + self.organization_code + ")"
       else

       contact_method = ActiveRecord::Base.connection.select_all("select * from contact_methods where id = #{contact_method_id['contact_method_id'].to_s}")[0]

        address_1 = contact_method['contact_method_code']
        address_2 = contact_method['contact_method_description']
        if(address_1 == nil||address_2 == nil)
          result[:error] = "You must define both address lines for the contact method of type: 'CARTON_LABEL_ADDRESS' for the marketing org(" + self.organization_code + ")"
        else
          result[:address1]= address_1
          result[:address2]= address_2
        end
     end
     return result
  end


  def build_instruction(label_data)

	 label_intruction = "<ProductLabel Status=\"true\" RunNumber=\""
	 label_intruction += self.production_run_code + "\" Code=\""
	 label_intruction += "RW" + "\" F0=\"" + "E2" + "\" "

			for i in 1..label_data.length()
			   key = "F" +  i.to_s
			   val = ""
			   if label_data.has_key?(key)
					val = label_data[key].to_s
				    field = key + "=\"" + val + "\""
				    label_intruction += field + " "
			   end
			end
	 label_intruction += "Msg=\"OK\" />"

      return label_intruction

  end


  def build_depot_label_data
    data = Hash.new

    str_num = self.carton_number.to_padded_s(12)
    gtin_barcode = nil

    gtin = get_gtin()

    if gtin
       gtin_barcode = "^01" + gtin + "10" +  "batch_code"
    else
      gtin_barcode = "0110" +  "batch_code"
    end

    self.inventory_code_short = self.inventory_code.split("_")[0]

    data.store("F1",gtin_barcode)
    data.store("F2",str_num)
    data.store("F3",self.variety_short_long)
    data.store("F4",self.commodity_code)
    brand_code = Mark.find_by_mark_code(self.carton_mark_code).brand_code

    commodity_descr = ActiveRecord::Base.connection.select_one("select commodity_description_long from commodities where commodity_code = '#{self.commodity_code}'")['commodity_description_long']

    data.store("F5",commodity_descr)
    data.store("F6",brand_code)
    data.store("F7",self.old_pack_code)
    data.store("F8",self.actual_size_count_code)
    data.store("F9",self.inventory_code_short)
    data.store("F10",self.grade_code)
    data.store("F11","batch_code")
    data.store("F12",self.pick_reference.to_s)
    data.store("F13",self.puc.to_s)
    data.store("F14",self.egap.to_s)
    data.store("F15",self.target_market_code.to_s)
    class_code = ProductClass.find_by_product_class_code(self.product_class_code).product_class_description
    data.store("F16",class_code)

    data.store("F19",self.organization_code)
    line_phc = ""     #self.production_run.line.line_phc
    data.store("F20",line_phc)
    packer = ""
    packer = ""   #self.packer_number.slice(2,8) if self.packer_number
    data.store("F21",packer)

    gtin_readable = nil
    if gtin
	 #user batch number
      gtin_readable = "(01)" + gtin + "(10)" + "batch_code"
    else
      gtin_readable = "(01)(10)" + "batch_code"

    end

    data.store("F22",gtin_readable)
    data.store("F23",self.address_line1)
    data.store("F24",self.address_line2)

    print_count = false

    pm_type = get_packmaterial_type_for_ru()
    if pm_type
      if pm_type == "T"
        print_count = true
      else
        print_count = false
      end
    end

    if print_count == true
      data.store("F25","COUNT:")
    else
       data.store("F25","")
    end

    marking = ""
    diameter = ""

    marking_heading = ""
    if self.marking && self.marking.strip != "" && self.marking != "*"
     marking_heading = "MARKING"
     marking = self.marking
    end

    diameter_heading = ""
    if self.diameter && self.diameter.strip != "" && self.diameter != "*"
     diameter_heading = "DIAMETER"
     diameter = self.diameter
    end

    data.store("F17",marking)
      data.store("F18",diameter)

    data.store("F26",diameter_heading)
    data.store("F27",marking_heading)
    ntc = Puc.find_by_puc_code(self.puc).nature_choice_certificate_code
    ntc = "" if !ntc
    data.store("F28",ntc)
    pfp =""
    #pfp = self.rw_active_pallet.pallet_format_product_code if self.rw_active_pallet
    data.store("F29",self.extended_fg_code)
    data.store("F30",pfp)
    data.store("F31",self.sell_by_code)


    return data

  end

  def get_packmaterial_type_for_ru()
   if !self.unit_pack_product_code
     fg_product = FgProduct.find_by_fg_product_code(self.fg_product_code)
     self.unit_pack_product_code = fg_product.unit_pack_product.unit_pack_product_code
   end

   if self.unit_pack_product_code
    return self.connection.select_one("select type_code from unit_pack_products where unit_pack_product_code = '#{self.unit_pack_product_code}'")['type_code']
   end
  end


  def self.create_depot_cartons(mapped_pallet_sequence,pallet_id,header)
    mapped_cartons = RwRun.get_object_nums('CARTON', mapped_pallet_sequence[:carton_count])

    target_market_rec = TargetMarket.find_by_target_market_name(mapped_pallet_sequence[:target_market_code])
    variety_record = Variety.find_by_marketing_variety_code_and_commodity_code(mapped_pallet_sequence[:marketing_variety_code],mapped_pallet_sequence[:commodity_code])
    rmt_variety_record = RmtVariety.find_by_rmt_variety_code(variety_record.rmt_variety_code)
    inventory_rec = InventoryCode.find_by_inventory_code(mapped_pallet_sequence[:inventory_code])
    gtin = Carton.get_gtin( mapped_pallet_sequence[:organization_code], mapped_pallet_sequence[:commodity_code], mapped_pallet_sequence[:marketing_variety_code], mapped_pallet_sequence[:old_pack_code], mapped_pallet_sequence[:actual_size_count_code], mapped_pallet_sequence[:grade_code], mapped_pallet_sequence[:inventory_code_short],mapped_pallet_sequence[:brand])
    ext_fg_rec = ExtendedFg.find_by_extended_fg_code(mapped_pallet_sequence[:extended_fg_code])
    fg_product_rec = FgProduct.find_by_fg_product_code(ext_fg_rec.fg_code)
    marketing_variety = MarketingVariety.find_by_marketing_variety_code_and_commodity_code(mapped_pallet_sequence[:marketing_variety_code],mapped_pallet_sequence[:commodity_code])
    egap = Puc.find_by_puc_code(mapped_pallet_sequence[:puc]).eurogap_code
    item_pack = fg_product_rec.item_pack_product
    actual_count =  item_pack.actual_count.to_s
    actual_count =     item_pack.size_ref if item_pack.size_ref && item_pack.size_ref != "NOS"
    run = ProductionRun.find(mapped_pallet_sequence[:production_run_id])
    pc_code_short =  mapped_pallet_sequence[:pick_reference].slice(2,1)
    pc_code_rec = PcCode.find_by_pc_code(pc_code_short)

    track_indicator = TrackIndicator.find_by_track_indicator_code(variety_record.rmt_variety_code)
    if ! track_indicator
      track_indicator = TrackIndicator.new
      track_indicator.commodity_code =  mapped_pallet_sequence[:commodity_code]
      track_indicator.commodity_group_code = Commodity.find_by_commodity_code(mapped_pallet_sequence[:commodity_code]).commodity_group_code
      track_indicator.rmt_variety_code = rmt_variety_record.rmt_variety_code
      track_indicator.rmt_variety_id =  rmt_variety_record.id
      track_indicator.track_indicator_code =  rmt_variety_record.rmt_variety_code
      track_indicator.create

    end

    mapped_seq_rec = MappedPalletSequence.find(mapped_pallet_sequence[:id].to_i)

    grade = mapped_pallet_sequence[:grade_code]
    inspect_type = nil
    inspect_type_rec = InspectionType.find_by_grade_code(grade)
    inspect_type =  inspect_type_rec.inspection_type_code  if inspect_type_rec
    if  !inspect_type||inspect_type == 'LOCAL'
      inspect_type = 'KROMCO'
    end
    if  grade == '1R'
      inspect_type = 'PPECB'
    end

    mapped_cartons.each do |carton_number|
      carton = Carton.new
      carton.cold_store_code = 'NO'

      carton.inspection_type_code = inspect_type
      carton.units_per_carton =   ext_fg_rec.units_per_carton.to_i if ext_fg_rec.units_per_carton && ext_fg_rec.units_per_carton != ""
      carton.actual_size_count_code=  actual_count
      carton.treatment_code = item_pack.treatment_code
      carton.carton_fruit_nett_mass = ext_fg_rec.tu_nett_mass.to_f if ext_fg_rec.tu_nett_mass && ext_fg_rec.tu_nett_mass != ""
      carton.quantity= 1
      carton.pack_date_time = DepotPallet.calc_packdate_from_pick_ref(mapped_pallet_sequence[:pick_reference],header.created_on.year.to_s)

      carton.intake_header_number =   header.intake_header_number
      carton.carton_number = carton_number
      carton.commodity_code = mapped_pallet_sequence[:commodity_code]
      carton.carton_mark_code = mapped_pallet_sequence[:carton_mark_code]
      shift = Shift.find_by_shift_code('UNKNOWN')
      carton.shift_id = shift.id

      carton.target_market_code = target_market_rec.target_market_code

      carton.variety_short_long = marketing_variety.marketing_variety_code + "_" + marketing_variety.marketing_variety_description
      carton.fg_code_old = mapped_pallet_sequence[:fg_code_old]

      carton.grade_code = mapped_pallet_sequence[:grade_code]
      carton.old_pack_code = mapped_pallet_sequence[:old_pack_code]
      carton.product_class_code = mapped_pallet_sequence[:class_code]

      carton.erp_cultivar = rmt_variety_record.rmt_variety_code + "_" + rmt_variety_record.rmt_variety_description
      carton.track_indicator_code = track_indicator.track_indicator_code
      carton.season_code = header.season
      carton.pick_reference = mapped_pallet_sequence[:pick_reference]
      carton.farm_code = "DEPOT_UNKNOWN"
      carton.is_depot_carton = true
      carton.spray_program_code = 'STD'
      carton.erp_cultivar =   mapped_pallet_sequence[:erp_cultivar]
      carton.production_run_code = mapped_pallet_sequence[:production_run_code]
      carton.production_run_id = mapped_pallet_sequence[:production_run_id]
      carton.line_code = run.line_code
      carton.is_depot_carton = true
      carton.intake_header_id = header.id

      carton.pc_code = "PC" + pc_code_rec.pc_code + "_" + pc_code_rec.pc_name
      carton.iso_week_code = mapped_pallet_sequence[:pick_reference].slice(3,1) + mapped_pallet_sequence[:pick_reference].slice(0,1) if mapped_pallet_sequence[:pick_reference]

      carton.inventory_code = inventory_rec.inventory_code + "_" + inventory_rec.inventory_name
      carton.pick_reference = mapped_pallet_sequence[:pick_reference]
      carton.remarks  = mapped_pallet_sequence[:remarks]
      carton.organization_code = mapped_pallet_sequence[:organization_code]
      carton.mapped_pallet_sequence_id = mapped_pallet_sequence[:id]
      carton.puc = mapped_pallet_sequence[:puc]
      carton.pallet_sequence_number = mapped_pallet_sequence[:pallet_sequence_number].to_i
      carton.pallet_number = mapped_pallet_sequence[:pallet_number]
      carton.pallet_id = pallet_id
      carton.fg_product_code = mapped_pallet_sequence[:fg_product_code]
      carton.date_time_created = Time.now
      carton.account_code = header.account_code
      carton.egap = Puc.find_by_puc_code(mapped_pallet_sequence[:puc]).eurogap_code
      carton.sell_by_code = mapped_pallet_sequence[:sell_by_date]
      carton.sell_by_code = "-" if !carton.sell_by_code


      carton.fg_mark_code = ext_fg_rec.fg_mark_code
      carton.extended_fg_code = mapped_pallet_sequence[:extended_fg_code]

      carton.unit_pack_product_code = fg_product_rec.unit_pack_product_code
      carton.gtin = gtin.gtin_code if gtin
      carton.mapped_pallet_sequence_id = pallet_id
     # carton.pack_date_time = mapped_seq_rec.pack_date_time
      carton.create
    end
  end

end
