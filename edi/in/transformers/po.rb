class Po   < DocEventHandlers
  
  def map_header(record,command)
    header = IntakeHeader.new
    header.intake_header_number = MesControlFile.next_seq_web(5)
    header.intake_type_code = "TI"
    header.header_status = "EDI_RECEIVED"
    header.doc_source = "po"
    header.import(record.fields)

    # Get the depot code from the file name.
    depot = Depot.find_by_depot_code(EdiHelper.edi_in_process_file[2..4])
    # Create the Depot if it does not exist.
    if depot.nil?
      location = Location.find_by_location_code('IN_TRANSIT')
      raise EdiInError, "Cannot create a Depot - unable to find 'IN_TRANSIT' location." if location.nil?

      # Note seriously smelly logic here: Party/Role hard-coded to match a person's name!
      party_role = PartiesRole.find(:first,
                                    :conditions => ['party_name = ? AND party_type_name = ? AND role_name = ?',
                                                   'Lionel_Booysen', 'PERSON', 'EMPLOYEE'])
      raise EdiInError, "Cannot create a Depot - unable to find 'Lionel_Booysen' PartyRole." if party_role.nil?

      depot = Depot.new :depot_code        => EdiHelper.edi_in_process_file[2..4],
                        :depot_description => EdiHelper.edi_in_process_file[2..4],
                        :location          => location,
                        :parties_role      => party_role
      depot.set_location_code_and_party_name
      depot.save!
    end
    header.depot_id   = depot.id
    header.depot_code = depot.depot_code

    header.save!
    record.fields['header_id'] = header.id

  end


  def map_pallet_sequence(record,command)
    header_id = command.parent_record?().record.fields['header_id']

    depot_pallet = DepotPallet.find_by_intake_header_id_and_depot_pallet_number(header_id,record.fields['depot_pallet_number'])
    if !depot_pallet
      depot_pallet = DepotPallet.new
      depot_pallet.depot_pallet_number = record.fields['depot_pallet_number']
      depot_pallet.intake_header_id = header_id
      depot_pallet.pallet_base_code = record.fields['pallet_base_code']
      kromco_base_code_rec = PalletBase.find_by_edi_in_pallet_base(depot_pallet.pallet_base_code)
      raise EdiInError, "A kromco pallet base code does not exist for edi-in base code: " + depot_pallet.pallet_base_code if !kromco_base_code_rec
      pfp = "X_S_" +  kromco_base_code_rec.pallet_base_code
      depot_pallet.pallet_format_product_code = pfp
      depot_pallet.orig_cons = record.fields['orig_cons']
      depot_pallet.save #create
    end

    #accumulate the sequence carton quantity in a global variable (pallet num as key), so that we can
    #update the quantities of all depot pallets in the 'doc_transformed' event handler
    if command.root.user_variables[depot_pallet.id]
        command.root.user_variables[depot_pallet.id] += record.fields['seq_ctn_qty']
    else
      command.root.user_variables[depot_pallet.id] = record.fields['seq_ctn_qty']
    end

    encrypted_pick_ref = Carton.encrypt_pick_ref(record.fields['pick_reference'],record.fields['commodity'])



    sequence = PalletSequence.new
    sequence.depot_pallet_id = depot_pallet.id
    sequence.depot_pallet_number = depot_pallet.depot_pallet_number
    sequence.captured_date_time = Time.now()
    sequence.intake_header_id = header_id
    sequence.import(record.fields)
    #deduce class
    class_char = sequence.grade.slice(0,1)
    class_code = "CL1"
    if class_char.is_numeric?
        class_code = "CL" + class_char
    end

    encrypted_pick_ref = Carton.encrypt_pick_ref(record.fields['pick_reference'],record.fields['commodity'])
    sequence.pick_reference = encrypted_pick_ref

    pack_date = Time.new()
    if record.fields["intake_date"]
      pack_date = record.fields["intake_date"]
    else
      pack_date = record.fields["orig_intake"]
    end
    sequence.pack_date_time = pack_date

    sequence.class_code = class_code
    sequence.inventory_code = "UL"  if sequence.inventory_code.nil? || sequence.inventory_code.strip() == ""
    sequence.save!

  end

  # Callback intercept: update the carton quantities of all depot pallets
  # and update DepotPallet records with pallet_format_product_code.
  def doc_transformed(root)

       #root.user_variables is a hash in which we stored the pallet ids as keys as values as their ctn quantities
       root.user_variables.each do |pallet_id,ctn_qty|
           depot_pallet = DepotPallet.find(pallet_id)
           depot_pallet.update_attribute(:carton_quantity,ctn_qty)
           depot_pallet.update_attribute(:pallet_format_product_code, get_pfp(depot_pallet.pallet_base_code,
                                                                              pallet_id,
                                                                              depot_pallet.pallet_format_product_code))
           log "pallet: " + pallet_id.to_s + " QTY: " + ctn_qty.to_s
       end
  end

  # Get the pallet_format_product_code for a given pallet_id and pallet_base_code.
  # Note: This method is identical in PDF417 transformer.
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

  # def get_pfp(pallet_base_code, pallet_id, existing_val)
  #   query = "select pallet_format_products.pallet_format_product_code 
  #           from pallet_sequences,extended_fgs, fg_products,depot_pallets, cartons_per_pallets,pallet_format_products
  #           where fg_products.carton_pack_product_code = cartons_per_pallets.carton_pack_product_code
  #           and depot_pallets.carton_quantity = cartons_per_pallets.cartons_per_pallet 
  #           and pallet_sequences.depot_pallet_id = depot_pallets.id 
  #           and fg_code = fg_product_code 
  #           and extended_fgs.OLD_fg_code = pallet_sequences.commodity||' '||pallet_sequences.variety||' '|| pallet_sequences.brand||' '|| pallet_sequences.pack_type||' '|| pallet_sequences.count 
  #           and pallet_format_products.pallet_format_product_code = cartons_per_pallets.pallet_format_product_code 
  #           and pallet_format_products.pallet_base_code = '#{pallet_base_code}'
  #           and depot_pallets.id = '#{pallet_id}' limit 1"
  #   rec = DepotPallet.connection.select_one(query)
  #   rec.nil? || rec['pallet_format_product_code'].nil? ? existing_val : rec['pallet_format_product_code']
  # end

end

