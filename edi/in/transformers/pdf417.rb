class Pdf417 < DocEventHandlers

  
  def map_header(record,command)
    # log "* Entered map header."
    record.fields['account_code'].gsub!(/\A0+/, '') # Need to strip leading zeroes
    header = IntakeHeader.create_from_pdf417(record)
    #puts header.id.to_s
    record.fields['header_id'] = header.id
    @pallet_ids ||= []
  end

  def map_gtin(record,command)
    # log "* Entered map gtin."
    #puts "map gtin: running"
    gtin_code = record.fields['gtin']
    gtin = Gtin.get_gtin_by_code(gtin_code)  #todo include dates in query
    raise EdiInError, "gtin " + gtin_code.to_s + " not found in db" if !gtin
    record.fields['gtin_record'] = gtin
  end

  def map_pallet_test(record,command)
    #puts "map PALLET TEST: running"

  end

  def map_pallet(record,command)
    # log "* Entered map pallet."

    header_record = command.parent_record?().parent_record?()
    pallet = DepotPallet.new
    pallet.depot_pallet_number = record.fields['depot_pallet_number']
    pallet.intake_header_id = header_record.record.fields['header_id']

    pallet.pallet_base_code = record.fields['pallet_base_code']
    pfp = "X_S_WGN"
    pallet.pallet_format_product_code = pfp

    pallet.save!
    @pallet_ids << pallet.id
    record.fields['depot_pallet_id'] = pallet.id

  end

  def map_pallet_sequence(record,command)
    # log "* Entered map pallet sequence."
    gtin = command.parent_record?().parent_record?().record.fields['gtin_record']
    sequence = PalletSequence.new
    header = command.parent_record?().parent_record?().parent_record?()
    sequence.depot_pallet_id = command.parent_record?().record.fields['depot_pallet_id']
    sequence.depot_pallet_number = command.parent_record?().record.fields['depot_pallet_number']
    sequence.captured_date_time = Time.now()
    sequence.organization = header.record.fields['organization_code']
    sequence.commodity = gtin.commodity_code
    sequence.variety = gtin.marketing_variety_code
    sequence.grade = gtin.grade_code
    sequence.count = gtin.actual_count
    sequence.target_market = command.parent_record?().parent_record?().record.fields['target_market_name']
    sequence.inventory_code = gtin.inventory_code
    sequence.pick_reference = command.parent_record?().parent_record?().record.fields['pick_reference']
    sequence.brand = gtin.brand_code
    sequence.pack_type = gtin.old_pack_code
    sequence.channel = header.record.fields['channel']
    sequence.puc = record.fields['puc']
    pack_date = Time.new()

    if  header.record.fields['consignment_date']
      pack_date = header.record.fields['consignment_date']
    end

    sequence.pack_date_time = pack_date
    sequence.sell_by_date = command.parent_record?().record.fields['sell_by_code']
    sequence.product_characteristics = command.parent_record?().parent_record?().record.fields['product_characteristics']
    sequence.remarks = nil
    sequence.seq_ctn_qty = record.fields['seq_ctn_qty']
    sequence.pallet_sequence_number = record.fields['pallet_sequence_number']
    sequence.intake_header_id = header.record.fields['header_id']
    sequence.batch_code = record.fields['batch_code']
    class_char = sequence.grade.slice(0,1)
    class_code = "CL1"
    if class_char.is_numeric?
        class_code = "CL" + class_char
    end

    sequence.class_code = class_code
    # PickRef is already encrypted so the following is removed:
    # encrypted_pick_ref = Carton.encrypt_pick_ref(sequence.pick_reference,sequence.commodity)
    # sequence.pick_reference = encrypted_pick_ref
    sequence.save!
    
      
  end

  # After all transformations are done, update DepotPallet records with pallet_format_product_code.
  def doc_transformed(root)
    # log "* Entered doc_transformed."
    @pallet_ids.each do |pallet_id|
       depot_pallet = DepotPallet.find(pallet_id)
       new_pfp = get_pfp(depot_pallet.pallet_base_code,
                         pallet_id,
                         depot_pallet.pallet_format_product_code)
        # log "* Current pfp is #{depot_pallet.pallet_format_product_code} | New pfp will be #{new_pfp}."
       depot_pallet.update_attribute(:pallet_format_product_code, new_pfp)
    end
  end

  # Get the pallet_format_product_code for a given pallet_id and pallet_base_code.
  # Note: This method is identical in PO transformer.
  def get_pfp(pallet_base_code, pallet_id, existing_val)
    pallet_base             = PalletBase.find_by_edi_in_pallet_base(pallet_base_code)
    pallet_base_code        = pallet_base.pallet_base_code

    query = "SELECT SUM(pallet_sequences.seq_ctn_qty) as cnt FROM depot_pallets JOIN pallet_sequences ON pallet_sequences.depot_pallet_id = depot_pallets.id WHERE depot_pallets.id = #{pallet_id}"
    rec = DepotPallet.connection.select_one(query)
    cnt = rec.nil? || rec['cnt'].nil? ? 0 : rec['cnt']
    # log "* PFP query1 is <<#{query}>> . \nResult is #{cnt}"

    query = "SELECT pallet_format_product_code FROM cartons_per_pallets WHERE cartons_per_pallet = #{cnt} AND pallet_format_product_code LIKE 'X_%_#{pallet_base_code}' LIMIT 1"
    rec = DepotPallet.connection.select_one(query)
    # log "* PFP query2 is <<#{query}>> . \nResult is #{rec.nil? ? 'NULL' : rec['pallet_format_product_code']}"
    rec.nil? ? existing_val : rec['pallet_format_product_code']
  end

end


