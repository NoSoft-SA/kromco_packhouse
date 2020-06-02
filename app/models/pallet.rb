class Pallet < ActiveRecord::Base

  attr_accessor :facility_code, :location_code, :org_short_description, :load_no

  has_many :cartons, :order => "id"
  has_many :pallet_sequences
  belongs_to :pallet_format_product
  belongs_to :ppecb_inspection
  belongs_to :load_detail
  belongs_to :intake_header
  belongs_to :intake_headers_production


  attr_accessor :line_code, :production_schedule_name, :pallet_time_search, :completed_date_from, :completed_date_to,
                :item_pack_product_code, :unit_pack_product_code, :carton_pack_product_code, :production_run_code, :hold_over_date_time

  def Pallet.log_rev_eng_allocation(load_order_id,pallet_number)
    query = "insert into pallet_document_logs (pallet_id,document_number,document_type,program_name,user_name,created_at,load_order_id,action)
            select pallets.id, '#{pallet_number}','load','#{ActiveRequest.get_active_request.program}','#{ActiveRequest.get_active_request.user}',
            '#{Time.new().to_formatted_s(:db)}',#{load_order_id},'rev_eng_allocate_pallets'
            from pallets where pallets.pallet_number = '#{pallet_number}'"
    self.connection.execute(query)
  end


  def Pallet.log_deallocation(pallets,load_order_id)
    pallets.each do|pallet|
      query = "insert into pallet_document_logs (pallet_id,document_number,document_type,program_name,user_name,created_at,load_order_id,action)
            select pallets.id, '#{pallet['pallet_number']}','load','#{ActiveRequest.get_active_request.program}','#{ActiveRequest.get_active_request.user}',
             '#{Time.new().to_formatted_s(:db)}',#{load_order_id},'deallocate'
            from pallets where pallets.id = #{pallet['id']}"
      self.connection.execute(query)
    end

  end

  def Pallet.invalid_pallets_for_dispatch_import?(pallet_numbers, order)
    inspection_r_hash = Hash.new
    failed_pallets = Array.new
    order_type =OrderType.find(order.order_type_id).order_type_code
    if order_type.strip=="MO" || order_type.strip=="MQ"
      for pallet_number in pallet_numbers
        @pallet= Pallet.find_by_pallet_number(pallet_number.strip)
        stock_item =StockItem.find_by_inventory_reference(@pallet.pallet_number.to_s)
        if !@pallet
          if pallet_number.length > 18
            failed_pallets.push(pallet_number + "(lines should end with semi-colon)")
          else
            failed_pallets.push(pallet_number + "(not a valid pallet number: #{pallet_number})")
          end
          return failed_pallets
        end

        if @pallet.exit_ref
          failed_pallets.push(pallet_number + "(exit_ref: #{@pallet.exit_ref})")
        end

        if   @pallet.load_detail_id
          failed_pallets.push(pallet_number + "(pallet is on load)".to_s)
        end
        if stock_item
          if   stock_item.location_code.upcase.index("PART_PALLETS")
          failed_pallets.push(pallet_number + "(location_code has PART_PALLETS)".to_s)
          end
        end

        if @pallet.target_market_code=="P9_PART PALLETS"
          failed_pallets.push(pallet_number + "(target_market_code is P9_PART PALLETS)".to_s)
        end



      end
    else
      for pallet_number in pallet_numbers
        @pallet= Pallet.find_by_pallet_number(pallet_number.strip)
        stock_item =StockItem.find_by_inventory_reference(@pallet.pallet_number.to_s)

        if !@pallet
          if pallet_number.length > 18
            failed_pallets.push(pallet_number + "(lines should end with semi-colon)")
          else
            failed_pallets.push(pallet_number + "(not a valid pallet number: #{pallet_number})")
          end
          return failed_pallets
        end
        if @pallet.exit_ref
          failed_pallets.push(pallet_number + "(exit_ref: #{@pallet.exit_ref})")
        end
       # if   @pallet.consignment_note_number == nil
        #  failed_pallets.push(pallet_number + "(not on intake consignment)".to_s)
      #  end
        if   @pallet.load_detail_id
          failed_pallets.push(pallet_number + "(pallet is on load)".to_s)
        end

        if @pallet.qc_status_code == nil
          failed_pallets.push(pallet_number + "(qc status not inspected)".to_s)
        elsif @pallet.qc_status_code.upcase != "INSPECTED"
          failed_pallets.push(pallet_number + "(qc status not inspected)".to_s)
        end
        if @pallet.qc_result_status == nil
          if  order.is_export==true
            failed_pallets.push(pallet_number + "(qc result status must be passed)".to_s)
          end
        else
          if   @pallet.qc_result_status.upcase != "PASSED"
            if  order.is_export==true
              failed_pallets.push(pallet_number + "(qc result status must be passed)".to_s)
            end
          end
        end
        if stock_item  
            if   stock_item.location_code.upcase.index("PART_PALLETS")
              failed_pallets.push(pallet_number + "(location_code has PART_PALLETS)".to_s)
            end
        end

        if @pallet.target_market_code=="P9_PART PALLETS"
          failed_pallets.push(pallet_number + "(target_market_code is P9_PART PALLETS)".to_s)
        end
      end
    end

    ffailed_pallets=Array.new
    failed = Hash.new
    for f_pallet in failed_pallets
      num_reason = f_pallet.split("(")
      reason = num_reason[1].split(")")[0]
      if !failed.empty?
        if failed.has_key?(num_reason[0])
          failed[num_reason[0]] = failed[num_reason[0]] + "," + reason
        else
          failed[num_reason[0]]=reason
        end
      else
        failed[num_reason[0]]=reason
      end
    end
    for ele in failed
      ffailed_pallets << ele[0] + "(" + ele[1] + ")"
    end
    return ffailed_pallets
  end

  def Pallet.check_consignment_note_number(pallet_numbers)
    for pallet in pallet_numbers
      @pallet = Pallet.find_by_sql("SELECT * FROM pallets WHERE pallet_number = '#{pallet}'")
      @pallet =@pallet[0]
      consignment_note_number = @pallet.consignment_note_number
      if  consignment_note_number == nil
        return consignment_note_number_result = "null consignment_note_number on pallet " + " " + " " + "#{pallet}"
      end
    end

    return "not_null"
  end

  def unset_holdover

    self.holdover = nil
    self.load_detail_id = nil
    self.remarks1 = nil
    self.remarks2= nil
    self.remarks3 = nil
    self.remarks4 = nil
    self.remarks5 = nil
    self.update

  end


  def get_carton_count
    @carton_quantity_actual = self.connection.select_one("select count(*) from cartons where pallet_number = '#{self.pallet_number}'")['count'].to_i
    return @carton_quantity_actual
  end

  def Pallet.get_carton_count(pallet_num)
    @carton_quantity_actual = self.connection.select_one("select count(*) from cartons where pallet_number = '#{pallet_num.to_s}'")['count'].to_i
    return @carton_quantity_actual
  end

  def get_oldest_carton
    return Carton.find_by_sql("select  * from cartons where pallet_id = #{self.id.to_s} order by id asc ")[0]
  end

  def self.set_build_status(carton_pack_product_code, pallet)


    cpp = CartonsPerPallet.find_all_by_carton_pack_product_code_and_pallet_format_product_code(carton_pack_product_code, pallet.pallet_format_product_code, :order => "id")


    if cpp.length > 0
      if cpp[0].cartons_per_pallet > pallet.carton_quantity_actual||cpp[0].cartons_per_pallet < pallet.carton_quantity_actual
        status = "PARTIAL"
        pallet.cpp = cpp[0].cartons_per_pallet
      else
        status = "FULL"
        pallet.cpp = cpp[0].cartons_per_pallet
      end
      pallet.build_status = status
    else
      pallet.build_status = "PARTIAL"
      return "cpp not found for CPC: " + carton_pack_product_code + " and PFP: " + pallet.pallet_format_product_code
    end

    return nil

  end


  def edi_out_pallet_base
       return self.pallet_format_product.pallet_base.edi_out_pallet_base

  end

  def mixed_pallet?
    query = "select distinct variety_short_long,actual_size_count_code from cartons where pallet_number = '#{self.pallet_number}'"
    if Carton.find_by_sql(query).length() > 1
      return "Y"
    else
      return "N"
    end

  end


  def set_account(is_reworks = nil)

    cartons_table = "cartons"

    if is_reworks
      cartons_table = "rw_active_cartons"
    end

    query = " SELECT
       count(  distinct (#{cartons_table}.account_code)),pallet_number ,max (#{cartons_table}.account_code)as account_code
       FROM
       #{cartons_table}
       where
       pallet_number= '#{self.pallet_number}'
       group by pallet_number"


    result = ActiveRecord::Base.connection.select_one(query)
    if result['count'].to_i > 1
      self.account_code = '6512'
    else
      self.account_code = result['account_code']
    end

    self.update
    return self.account_code


  end


  def self.set_account(pallet_num, is_reworks = nil, force_update = nil)

    cartons_table = "cartons"

    if is_reworks
      cartons_table = "rw_active_cartons"
    end

    query = " SELECT
       count(  distinct (#{cartons_table}.account_code)),pallet_number ,max (#{cartons_table}.account_code)as account_code
       FROM
       #{cartons_table}
       where
       pallet_number= '#{pallet_num}'
       group by pallet_number"


    if  is_reworks
      pallet = RwActivePallet.find_by_pallet_number(pallet_num)
    else
      pallet = Pallet.find_by_pallet_number(pallet_num)

    end

    result = ActiveRecord::Base.connection.select_one(query)

    return pallet.account_code if ! result

    if result['count'].to_i > 1
      pallet.account_code = '6512'
    else
      pallet.account_code = result['account_code']
    end

    pallet.update
    return pallet.account_code


  end


  def set_build_status(carton_pack_product_code)


    cpp = CartonsPerPallet.find_all_by_carton_pack_product_code_and_pallet_format_product_code(carton_pack_product_code, self.pallet_format_product_code, :order => "id")


    if cpp.length > 0
      if cpp[0].cartons_per_pallet > self.carton_quantity_actual||cpp[0].cartons_per_pallet < self.carton_quantity_actual
        status = "PARTIAL"
        self.cpp = cpp[0].cartons_per_pallet
      else
        status = "FULL"
        self.cpp = cpp[0].cartons_per_pallet
      end
      self.build_status = status
    else
      self.build_status = "PARTIAL"
      return "cpp not found for CPC: " + carton_pack_product_code + " and PFP: " + self.pallet_format_product_code
    end

    return nil

  end


  def Pallet.build_and_exec_query(params, session=nil)


    query = "    SELECT  public.pallets.*,production_runs.production_run_code,production_runs.line_code FROM
           public.pallets
           INNER JOIN public.fg_products ON (public.pallets.fg_product_code = public.fg_products.fg_product_code)
           INNER JOIN public.production_runs ON (public.pallets.production_run_id = public.production_runs.id)
           INNER JOIN public.production_schedules ON (public.production_runs.production_schedule_id = public.production_schedules.id)
           WHERE (public.pallets.exit_ref is null AND not (upper(pallets.process_status) like '%PALLETIZING%') "

    #----------------
    #Add conditions
    #----------------

    #NB: look at 'execute_production_run_step3'
    #pack date
    from_time = nil
    to_time = nil
    started = true

    puts params.to_s
    if params.key?('completed_date_from(1i)')
      query += " AND " if started
      from_time = Time.local(params['completed_date_from(1i)'], params['completed_date_from(2i)'], params['completed_date_from(3i)'], params['completed_date_from(4i)']).to_formatted_s(:db)
      to_time = Time.local(params['completed_date_to(1i)'], params['completed_date_to(2i)'], params['completed_date_to(3i)'], params['completed_date_to(4i)']).to_formatted_s(:db)
      query += "public.pallets.date_time_completed > '#{from_time}' AND public.pallets.date_time_completed < '#{to_time}'"
      started = true
    end

    #iso_week_code (textbox)
    if params['iso_week_code'] && params['iso_week_code'].strip != ""
      query += " AND " if started
      query += " public.pallets.iso_week_code = '#{params[:iso_week_code]}' "
      started = true
    end

    #pallet_number (textbox)
    if params['pallet_number'] && params['pallet_number'].strip != ""
      query += " AND " if started
      query += " public.pallets.pallet_number = '#{params[:pallet_number]}' "
      started = true
    end

    #fg_product_code
    if params['fg_product_code'] != ""
      query += " AND " if started
      query += " public.pallets.fg_product_code = '#{params[:fg_product_code]}' "
      started = true
    end

    #item_pack_product_code
    if params['item_pack_product_code'] != ""
      query += " AND " if started
      query += " public.fg_products.item_pack_product_code = '#{params[:item_pack_product_code]}' "
      started = true
    end

    #marketing_variety_code
    if params['marketing_variety_code'] != ""
      query += " AND " if started
      query += " public.pallets.marketing_variety_code = '#{params[:marketing_variety_code]}' "
      started = true
    end

    #unit_pack_product
    if params['unit_pack_product_code'] != ""
      query += " AND " if started
      query += " public.fg_products.unit_pack_product_code = '#{params[:unit_pack_product_code]}' "
      started = true
    end

    #carton_pack_product_code
    if params['carton_pack_product_code'] != ""
      query += " AND " if started
      query += " public.fg_products.carton_pack_product_code = '#{params[:carton_pack_product_code]}' "
      started = true
    end

    #grade_code
    if params['grade_code'] != ""
      query += " AND " if started
      query += " public.pallets.grade_code = '#{params[:grade_code]}' "
      started = true
    end

    #pc_code
    if params['pc_code'] != ""
      query += " AND " if started
      query += " public.pallets.pc_code like 'PC#{params[:pc_code]}%' "
      started = true
    end

    #production_run_code
    if params['production_run_code'] != ""
      query += " AND " if started
      query += " public.production_runs.production_run_code = '#{params[:production_run_code]}' "
      started = true
    end

    #farm_code
    if params['farm_code'] != ""
      query += " AND " if started
      query += " public.production_runs.farm_code = '#{params[:farm_code]}' "
      started = true
    end

    #line_code
    if params['line_code'] != ""
      query += " AND " if started
      query += " public.production_runs.line_code = '#{params[:line_code]}' "
      started = true
    end

    #production_schedule_name
    if params['production_schedule_name'] != ""
      query += " AND " if started
      query += " public.production_runs.production_schedule_name = '#{params[:production_schedule_name]}' "
      started = true
    end

    #inventory_code
    if params['inventory_code'] != ""
      query += " AND " if started
      query += " public.pallets.inventory_code = '#{params[:inventory_code]}' "
      started = true
    end

    #organization_code
    if params['organization_code'] != ""
      query += " AND " if started
      query += " public.pallets.organization_code = '#{params[:organization_code]}' "
      started = true
    end

    #season_code (it's the 'season' field in seasons table)
    if params['season_code'] != ""
      query += " AND " if started
      query += " public.pallets.season_code = '#{params[:season_code]}' "
      started = true
    end

    if params['target_market_code'] != ""
      query += " AND " if started
      query += " public.pallets.target_market_code like '#{params['target_market_code']}%' "
      started = true
    end

    query += ") LIMIT 1000"
    puts query
    if started
      #:::::::::LUKS CHANGE - ADDED ALL THE FOOLWING LINE OF CODE:::::::::
      session[:cached_query] = "Pallet.find_by_sql(\"" + query + "\")" if session
      return Pallet.find_by_sql(query)
    else
      return nil
    end

  end

  ################ Henry added method ######################################


  #===========================================================
  # Happy's Method
  # :: This method is used to get the production_schedule_name
  #    based on the current values of 'season_code, farm_code,
  #    and rmt_variety_code'. It returns a list of
  #    production_schedule_names
  #===========================================================
  def self.get_production_schedule_names(fields_hash)
    puts "<<< Production Schedule Name Search Entered >>>"
    season_code = nil
    farm_code = nil
    rmt_variety_code = nil
    if fields_hash[:season_code]
      puts "YES SEASON CODE"
      season_code = fields_hash[:season_code].to_s
    end
    if fields_hash[:farm_code]
      puts "YES FARM CODE"
      farm_code = fields_hash[:farm_code].to_s
    end
    if fields_hash[:rmt_variety_code]
      puts "YES RMT VARIETY CODE"
      rmt_variety_code = fields_hash[:rmt_variety_code].to_s
    end
    query = "SELECT DISTINCT production_schedule_name FROM production_schedules"
    if season_code != nil && season_code.to_s != ""
      if query.index(" WHERE ") == nil
        query += " WHERE season_code='" + season_code + "'"
      else
        query += " AND season_code='" + season_code += "'"
      end
    end
    if farm_code != nil && farm_code != ""
      farm = Farm.find_by_farm_code(farm_code)
      if query.index(" WHERE ") == nil
        query += " WHERE farm_group_code='" + farm.farm_group.farm_group_code.to_s + "'"
      else
        query += " AND farm_group_code='" + farm.farm_group.farm_group_code.to_s + "'"
      end
    end
    if rmt_variety_code != nil && rmt_variety_code != ""
      if query.index(" WHERE ") == nil
        query += " WHERE variety_code='" + rmt_variety_code + "'"
      else
        query += " AND variety_code='" + rmt_variety_code + "'"
      end
    end

    # querying production_schedule_names table
    production_schedule_names = ProductionSchedule.find_by_sql(query).map { |g| [g.production_schedule_name] }
    production_schedule_names.unshift("<empty>")
    return production_schedule_names
  end


  def self.create_pallet_from_depot(mapped_pallet_sequences, header, depot_pallet_number)
    pallet = Pallet.new
    depot_pallet = DepotPallet.find_by_depot_pallet_number_and_intake_header_id(depot_pallet_number, header.id)
    mapped_pallet_sequences.sort! { |x, y| y[:pallet_sequence_number] <=> x[:pallet_sequence_number] }
    ctn_qty = 0
    mapped_pallet_sequences.each do |seq|
      ctn_qty += seq[:carton_count]
    end

    pallet.carton_quantity_actual = ctn_qty
    pallet.orig_cons = depot_pallet.orig_cons

    mapped_pallet_sequence = mapped_pallet_sequences.reverse[0]
    pallet.is_mapped = true
    pallet.consignment_note_number = header.consignment_note_number
    pallet.pallet_format_product_code = depot_pallet.pallet_format_product_code
    pallet.pallet_format_product_id = PalletFormatProduct.find_by_pallet_format_product_code(pallet.pallet_format_product_code).id
    pallet.inspect_type_code = header.inspection_type_code
    pallet.production_run_id = mapped_pallet_sequence[:production_run_id]
    pallet.erp_cultivar = mapped_pallet_sequence[:erp_cultivar]
    pallet.commodity_code = mapped_pallet_sequence[:commodity_code]
    pallet.class_code = mapped_pallet_sequence[:class_code]
    pallet.intake_header_id = header.id

    pallet.store_type_code = "storage"
    pallet.store_type_code = "cold_store" if header.recool_required

    pc_code_short = mapped_pallet_sequence[:pick_reference].slice(2, 1)
    pc_code_rec = PcCode.find_by_pc_code(pc_code_short)
    pallet.pc_code = pc_code_rec.pc_code + "_" + pc_code_rec.pc_name
    pallet.carton_mark_code = mapped_pallet_sequence[:carton_mark_code]
    target_market_rec = TargetMarket.find_by_target_market_name(mapped_pallet_sequence[:target_market_code])
    pallet.target_market_code = target_market_rec.target_market_code
    marketing_variety = MarketingVariety.find_by_marketing_variety_code_and_commodity_code(mapped_pallet_sequence[:marketing_variety_code], mapped_pallet_sequence[:commodity_code])
    pallet.marketing_variety_code = marketing_variety.marketing_variety_code
#      carton.variety_short_long = marketing_variety.marketing_variety_code + "_" + marketing_variety.marketing_variety_description
    pallet.fg_code_old = mapped_pallet_sequence[:fg_code_old]
    pallet.actual_size_count_code = mapped_pallet_sequence[:actual_size_count_code]
    pallet.grade_code = mapped_pallet_sequence[:grade_code]
    pallet.old_pack_code = mapped_pallet_sequence[:old_pack_code]
#      carton.product_class_code = ItemPackProduct.find_by_item_pack_product_code(mapped_pallet_sequence[:item_pack_product_code]).product_class_code
    variety_record = Variety.find_by_marketing_variety_code_and_commodity_code(mapped_pallet_sequence[:marketing_variety_code], mapped_pallet_sequence[:commodity_code])
    rmt_variety_record = RmtVariety.find_by_rmt_variety_code_and_commodity_code(variety_record.rmt_variety_code, mapped_pallet_sequence[:commodity_code])
    pallet.erp_cultivar = rmt_variety_record.rmt_variety_code + "_" + rmt_variety_record.rmt_variety_description
    inventory_rec = InventoryCode.find_by_inventory_code(mapped_pallet_sequence[:inventory_code])
    pallet.inventory_code = inventory_rec.inventory_code + "_" + inventory_rec.inventory_name
    pallet.pick_reference_code = mapped_pallet_sequence[:pick_reference]
    pallet.remark = mapped_pallet_sequence[:remarks]
    pallet.cold_store_code = 'NO'
    pallet.organization_code = mapped_pallet_sequence[:organization_code]
    pallet.iso_week_code = mapped_pallet_sequence[:pick_reference].slice(3, 1) + mapped_pallet_sequence[:pick_reference].slice(0, 1) if mapped_pallet_sequence[:pick_reference]
    pallet.season_code = header.season
    pallet.pallet_number = mapped_pallet_sequence[:pallet_number]
    pallet.fg_product_code = mapped_pallet_sequence[:fg_product_code]
    fg_product_rec = FgProduct.find_by_fg_product_code(pallet.fg_product_code)
    pallet.date_time_created = Time.now
    pallet.account_code = header.account_code
    pallet.pt_product_characteristics = mapped_pallet_sequence[:product_characteristics]
    pallet.build_status = "full"
    ipc_rec = ItemPackProduct.find_by_item_pack_product_code(mapped_pallet_sequence[:item_pack_product_code])
    pallet.size_count_code = ipc_rec.standard_size_count_value
    pallet.is_depot_pallet = true
    pallet.zero_printed_carton_labels = true
    pallet.oldest_pack_date_time = header.created_on

    #pallet.oldest_pack_date_time = mapped_seq.pack_date_time

    err = pallet.set_build_status(fg_product_rec.carton_pack_product_code)
    raise err if err
    pallet.create

    mapped_pallet_sequences.each do |mapped_pallet_seq|

      Carton.create_depot_cartons(mapped_pallet_seq, pallet.id, header)
    end


    oldest_pack_date = self.connection.select_one("select min(pack_date_time) as oldest_pack_date from mapped_pallet_sequences where depot_pallet_id = #{depot_pallet.id.to_s}")['oldest_pack_date']
    pallet.update_attribute(:oldest_pack_date_time, oldest_pack_date) if oldest_pack_date


    return pallet
  end

  def self.bulk_update(set_map, condition_attr, pallet_nums=nil, additional_criteria=nil)
    updates = ""
    for key in set_map.keys
      updates += key.to_s + "=" + set_map[key].to_s + ","
    end
    updates.chop!

    conditions = ""
    if (pallet_nums != nil)
      for pallet_num in pallet_nums
        conditions += condition_attr + "=" + pallet_num.to_s + " or "
      end
    end

    if (additional_criteria != nil)
      for ikey in additional_criteria.keys
        conditions += ikey.to_s + "=" + additional_criteria[ikey].to_s + " or "
      end
    end

    conditions.chop!.chop!.chop! if conditions.length > 3
    puts "NULK UPDATE STMT = set(" + updates +")\n " + "where (" + conditions + ")"
    Pallet.update_all(ActiveRecord::Base.extend_set_sql_with_request(updates, "pallets"), conditions)

  end

end


