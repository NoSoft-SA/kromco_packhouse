# Intake Transmission (PI).
class PiOut < TextOutTransformer

  # Create a HierarchicalRecordSet from the EdiOutProposal record.
  #
  # The proposal's +record_map+ attribute contains the attributes
  # of an IntakeHeader/IntakeHeadersProduction model.
  #    Batch Header               -> BH
  #    IntakeHeadersProduction    -> IC (or from IntakeHeader)
  #      `-- Summary of IHP       -> IS
  #            `-- Pallet records -> IP
  #    Batch Trailer              -> BT
  #
  # Note that if the IntakeHeader/IntakeHeadersProduction model +revision_number+ is 99,
  # the PI represents a delete and no IS or IP records will be created.
  def create_doc_records(proposal)

    # Initialise the record counts for use in the batch trailer record.
    @ic_record_count,  @is_record_count,  @ip_record_count  = [0, 0, 0]
    @total_ic_cartons, @total_is_cartons, @total_ip_cartons = [0, 0, 0]
    @total_ic_pallets, @total_is_pallets, @total_ip_pallets = [0.0, 0.0, 0.0]

    @is_production = @record_map.keys.include? 'representative_pallet_number'
    @ih_name = @is_production ? 'IntakeHeadersProduction' : 'IntakeHeader'
    EdiHelper.transform_log.write "Transforming Intake Transmission (PI) for #{@ih_name} #{@record_map['id']}.."

    # Make several IC records.           IN CONSIGNMENT
    # for each, make several IS records. IN SUMMARY
    # for each, make several IP records. IN PALLET

    # ---------
    # BH record
    # ---------
    rec_set = HierarchicalRecordSet.new({'header' => 'BH',
                                         'network_address' => 31,
                                         'batch_number' => @out_seq,
                                         'create_date' => Date.today,
                                         'create_time' => Time.now,
                                         'version_number' => 'r'
                                        }, 'BH')
    # ---------
    # IC record
    # ---------
    begin
      if @is_production
        intake_headers_production = IntakeHeadersProduction.find(@record_map['id'])
      else
        intake_headers_production = IntakeHeader.find(@record_map['id'])
      end
    rescue ActiveRecord::RecordNotFound
      raise EdiOutError, "#{@err_prefix} - #{@ih_name} with id #{@record_map['id']} not found."
    end

    # --------------------------------------------------------------
    # Set the rules for what is to be validated against masterfiles.
    # --------------------------------------------------------------
    @to_validate = {}
    #@to_validate[:product_code_target_market] = ['TI', 'CA'].include?(intake_headers_production.organization_code)
    #@to_validate[:product_code]               = ['TI', 'CA'].include?(intake_headers_production.organization_code)

    # For cerain organizations, if the inventory code is 'UL', make it blank.
    @change_val_for = {}
    @change_val_for[:inventory_code_ul] = true if ['CA', 'XT'].include?(intake_headers_production.organization_code)

    # Special account code used for TI:
    if 'TI' == intake_headers_production.organization_code &&
       intake_headers_production.consignment_note_number   &&
       intake_headers_production.consignment_note_number.start_with?( 'L031' )
      @account_code = '8385'
    else
      @account_code = intake_headers_production.account_code
    end

    ic = HierarchicalRecordSet.new( build_ic_record( intake_headers_production ), 'IC')
    @ic_record_count += 1
    rec_set.add_child ic


    # ----------------------------------------
    # Check for delete flag on IntakeHeader...
    # ----------------------------------------
    if intake_headers_production.revision_number != 99 # PI Delete - only create IC records.

      # ----------
      # IS records
      # ----------

      make_is_groups( intake_headers_production ) do |is_keys|
        is = HierarchicalRecordSet.new( build_is_record( intake_headers_production, is_keys ), 'IS')
        @is_record_count += 1
        ic.add_child is

        # Get all the pallets for this summary, extract the 9-digit pallet_id from the pallet_number
        # and sort in pallet_id sequence.
        # Calculate the carton and pallet quantities.
        pallet_ids = is_keys.map {|k| k[1] }

        pallets    = Pallet.find(:all,
                     :select => "count(cartons.*) as carton_count,
                      pallets.cpp, cartons.extended_fg_code, cartons.target_market_code, cartons.inventory_code,
                      cartons.puc, cartons.actual_size_count_code, cartons.season_code,pallets.pick_reference_code, cartons.gtin, cartons.sell_by_code,
                      pallets.pallet_number, cartons.organization_code, cartons.commodity_code, cartons.variety_short_long,
                      cartons.old_pack_code, cartons.grade_code, pallets.pt_product_characteristics, commodities.commodity_group_code,
                      marketing_varieties.variety_group_code, marks.brand_code, pallet_bases.edi_out_pallet_base, pallets.pallet_format_product_id,
                      pallets.carton_quantity_actual",
                     :joins => "join cartons on cartons.pallet_id = pallets.id
                      join commodities on commodities.commodity_code = cartons.commodity_code
                      join marketing_varieties on marketing_varieties.marketing_variety_code = SUBSTRING(cartons.variety_short_long from 1 for 3)
                      join marks on marks.mark_code = pallets.carton_mark_code
                      join pallet_format_products on pallet_format_products.id = pallets.pallet_format_product_id
                      join pallet_bases on pallet_bases.pallet_base_code = pallet_format_products.pallet_base_code",
                     :group => "cartons.extended_fg_code, cartons.target_market_code, cartons.inventory_code,
                      cartons.puc,cartons.season_code, cartons.actual_size_count_code, pallets.pick_reference_code, cartons.gtin, cartons.sell_by_code,
                      pallets.pallet_number, cartons.organization_code, cartons.commodity_code, cartons.variety_short_long,
                      cartons.old_pack_code, cartons.grade_code, pallets.pt_product_characteristics, commodities.commodity_group_code,
                      marketing_varieties.variety_group_code, marks.brand_code, pallet_bases.edi_out_pallet_base, pallets.cpp, pallets.pallet_format_product_id,
                      pallets.carton_quantity_actual",
                     :conditions => "pallets.id in (#{pallet_ids.join(',')})"
                    ).map {|m| [(m.pallet_number.length < 10 ? m.pallet_number : m.pallet_number[-10, 9]), m, m.carton_count.to_i, ((m.carton_count.to_i / m.carton_quantity_actual.to_f) * 100).to_i, 1]}.sort_by {|p| p[0]}
                    #).map {|m| [(m.pallet_number.length < 10 ? m.pallet_number : m.pallet_number[-10, 9]), m, m.carton_count.to_i, ((m.carton_count.to_i / m.cpp.to_f) * 100).to_i, 1]}.sort_by {|p| p[0]}

        # If a pallet_id has more than one pallet, sum the pallet_counts, subtract from one and add
        # the difference to one of the records so that the total of all the pallets is always == 1.
        prev_id    = ''
        tot_pall   = 100
        diffs      = {}
        seq        = 1
        max_index  = 0
        max_pall   = 0
        pallets.each_with_index do |pallet_array, index|
          pallet_id = pallet_array[0]
          if pallet_id != prev_id
            if seq > 1 && tot_pall != 100
              diff = 100 - tot_pall
              diffs[max_index] = diff
            end
            seq = 1
            prev_id   = pallet_id
            max_pall  = pallet_array[3]
            max_index = index
            tot_pall  = pallet_array[3]
          else
            seq += 1
            tot_pall += pallet_array[3]
            if pallet_array[3] > max_pall
              max_pall  = pallet_array[3]
              max_index = index
            end
            pallet_array[4] = seq
          end
          # Check if the last record is part of a mixed pallet.
          if index == pallets.length-1
            if seq > 1 && tot_pall != 100
              diff = 100 - tot_pall
              diffs[max_index] = diff
            end
          end
        end

        diffs.each do |k,v|
          new_tot = pallets[k][3]
          new_tot += v
          pallets[k][3] = new_tot
        end

        # Find all the pallet_ids that occur more than once. (Check for occurrence of seq_no == 2)
        mixed_pallet_ids = pallets.select {|a| a[4] == 2 }.map {|a| a[0] }

        # ----------
        # IP records
        # ----------
        # For each pallet, create an ip
        prev_id = ''
        pallets.each do |pallet_array|
          pallet_id       = pallet_array[0]
          pallet          = pallet_array[1]
          carton_quantity = pallet_array[2]
          pallet_quantity = pallet_array[3] / 100.0
          seq             = pallet_array[4]

          if mixed_pallet_ids.include? pallet_id
            mixed_pallet_ind = 'Y'
          else
            mixed_pallet_ind = 'N'
          end
          ip = HierarchicalRecordSet.new( build_ip_record( intake_headers_production,
                                                           pallet, pallet_id, seq,
                                                           carton_quantity, pallet_quantity,
                                                           mixed_pallet_ind), 'IP')
          @ip_record_count += 1
          is.add_child ip
        end
      end

    end # IF revision_number != 99

    # ---------
    # BT record
    # ---------
    trailer = HierarchicalRecordSet.new({'trailer' => 'BT',
                                         'network_address'  => 31,
                                         'batch_number'     => @out_seq,
                                         'record_count'     => 2 + @ic_record_count + @is_record_count + @ip_record_count,
                                         'ic_record_count'  => @ic_record_count,
                                         'is_record_count'  => @is_record_count,
                                         'ip_record_count'  => @ip_record_count,
                                         'ev_record_count'  => 0,
                                         'total_ic_cartons' => @total_ic_cartons,
                                         'total_ic_pallets' => @total_ic_pallets,
                                         'total_dummy_ic_cartons' => 0,
                                         'total_dummy_ic_pallets' => 0,
                                         'total_is_cartons' => @total_is_cartons,
                                         'total_is_pallets' => @total_is_pallets,
                                         'total_ip_cartons' => @total_ip_cartons,
                                         'total_ip_pallets' => @total_ip_pallets
                                        }, 'BT')
    rec_set.add_child trailer
    rec_set
  end

  # Get the representative pallet from IntakeheadersProduction#representative_pallet_number
  # or get a random pallet from IntakeHeader#consignment_note_number.
  def representative_pallet( intake_headers_production )
    if @is_production
      pallet = Pallet.find(:first,
                           :conditions => ['pallet_number = ?',
                             intake_headers_production.representative_pallet_number] )
      raise EdiOutError, "#{@err_prefix} - No pallets for #{@ih_name} with representative_pallet_number: #{intake_headers_production.representative_pallet_number}." if pallet.nil?
    else
      # get random pallet
      pallet = Pallet.find(:first,
                           :conditions => ['consignment_note_number = ?',
                             intake_headers_production.consignment_note_number] )
      raise EdiOutError, "#{@err_prefix} - No pallets for #{@ih_name} with consignment_note_number: #{intake_headers_production.consignment_note_number}." if pallet.nil?
    end
    pallet
  end

  # Get the representative carton from IntakeheadersProduction#representative_carton_number
  # or get a random carton from the pallet returned from representative_pallet.
  def representative_carton( intake_headers_production, pallet )
    if @is_production
      carton = Carton.find(:first,
                           :conditions => ['carton_number = ?',
                             intake_headers_production.representative_carton_number] )
      raise EdiOutError, "#{@err_prefix} - No cartons for #{@ih_name} with representative_carton_number: #{intake_headers_production.representative_carton_number}." if carton.nil?
    else
      # get random carton
      carton = Carton.find(:first, :conditions => ['pallet_id = ?', pallet.id])
      raise EdiOutError, "#{@err_prefix} - No cartons for #{@ih_name}, pallet_number: #{pallet.pallet_number}." if carton.nil?
    end
    carton
  end

  # IC Intake Consignment record.
  #
  # Built up from IntakeHeader/IntakeHeadersProduction, representative Pallet and representative Carton.
  def build_ic_record( intake_headers_production )
    if intake_headers_production.revision_number == 99 # PI Delete - no representative pallet
      pallet              = nil
      carton              = nil
      inspection_datetime = nil
    else
      pallet = representative_pallet( intake_headers_production )
      carton = representative_carton( intake_headers_production, pallet )
      ppecb_inspection = pallet.ppecb_inspection
      if ppecb_inspection.nil? # Could be nil for an IntakeHeader record (not IHProduction)
        inspection_datetime = nil
      else
        inspection_datetime = ppecb_inspection.created_at
      end
    end

    # sum of all pallets.carton_quantity_actual on iph
    carton_quantity = Pallet.sum('carton_quantity_actual',
                                 :conditions => ['consignment_note_number = ?',
                                   intake_headers_production.consignment_note_number])
    carton_quantity = 0 if carton_quantity.nil?

    # Sum of all pallets.carton_quantity_actual / cpp
    # NB This must be cast to float:
    # pallet_quantity = Pallet.sum('cast(carton_quantity_actual as float) / cast(cpp as float)',
    #                              :conditions => ['consignment_note_number = ?',
    #                                intake_headers_production.consignment_note_number]).to_f
    # Count of all pallets
    pallet_quantity  = Pallet.count('id', :conditions => ["consignment_note_number = ?",
                                   intake_headers_production.consignment_note_number])

    pallet_quantity = 0 if pallet_quantity.nil?

    # Count of pallets with build_status == 'FULL'
    full_pallet     = Pallet.count('id',
                                 :conditions => ["consignment_note_number = ? AND build_status = 'FULL'",
                                   intake_headers_production.consignment_note_number])

    # Count of pallets with build_status == 'PARTIAL'
    inc_pallet      = Pallet.count('id',
                                 :conditions => ["consignment_note_number = ? AND build_status = 'PARTIAL'",
                                   intake_headers_production.consignment_note_number])
    @total_ic_cartons += carton_quantity
    @total_ic_pallets += pallet_quantity

    phc = @is_production ? nil : intake_headers_production.packhouse_code

    rec = {'load_id'          => intake_headers_production.consignment_note_number,
           'document_number'  => intake_headers_production.consignment_note_number,
           'organisation'     => intake_headers_production.organization_code,
           'document_type'    => intake_headers_production.intake_type_code,
           'document_date'    => intake_headers_production.created_on,
           'rail_date'        => intake_headers_production.created_on,
           'account'          => @account_code,
           'pro_no'           => intake_headers_production.id,
           'carton_quantity'  => carton_quantity,
           'pallet_quantity'  => pallet_quantity,
           'full_pallet'      => full_pallet,
           'inc_pallet'       => inc_pallet,
           'season'           => intake_headers_production.revision_number == 99 ? nil : pallet.season_code,
           'client_ref'       => intake_headers_production.order_number,
           'order_no'         => intake_headers_production.order_number,
           'inspector'        => intake_headers_production.inspector_number,
           'inspection_date'  => inspection_datetime,
           'inspection_time'  => inspection_datetime,
           'inspection_point' => intake_headers_production.inspection_point,
           'revision_number'  => intake_headers_production.revision_number,
           'transaction_date' => Date.today,
           'transaction_time' => Time.now,
           'arrival_date'     => intake_headers_production.created_on,
           'arrival_time'     => intake_headers_production.created_on,
           'carton_quantity_2'=> carton_quantity,
           'pallet_quantity_2'=> pallet_quantity,
           'reference_number' => intake_headers_production.order_number,
           'packh_code'       => phc,
           'sellbycode'       => intake_headers_production.revision_number == 99 ? nil : carton.sell_by_code,
           'channel'          => intake_headers_production.organization_code == 'TI' ? 'L' : 'E',
           'waybill_no'       => intake_headers_production.phytowaybill
    }
  end

  # Get all the pallets linked to the IntakeHeader/IntakeHeadersProduction.
  #
  # Group by:
  #   pallets.organization_code
  #   pallets.commodity_code
  #   pallets.marketing_variety_code
  #   pallets.old_pack_code
  #   pallets.grade_code
  #   marks.brand_code
  #   pallets.inventory_code
  #   pallets.target_market_code
  #   pallet_bases.edi_out_pallet_base
  #   size_ref
  #
  # Size_ref:
  #   CASE item_pack_products.size_ref
  #        WHEN 'NOS'::text THEN item_pack_products.actual_count::character varying
  #        ELSE item_pack_products.size_ref
  #   END
  #
  # Yield each set of pallets in a group.
  def make_is_groups( intake_headers_production )
    pallnos = Pallet.find(:all, :select => "distinct pallets.id, (pallets.organization_code ||
              pallets.commodity_code || pallets.marketing_variety_code || pallets.old_pack_code ||
              pallets.grade_code || marks.brand_code || pallets.pick_reference_code || 
              pallets.inventory_code || pallets.target_market_code ||
              pallet_bases.edi_out_pallet_base || 
              CASE item_pack_products.size_ref
                WHEN 'NOS'::text THEN item_pack_products.actual_count::character varying
                ELSE item_pack_products.size_ref
              END) controlbreak",
              :joins => 'join marks on marks.mark_code = pallets.carton_mark_code
               join pallet_format_products on pallet_format_products.id = pallets.pallet_format_product_id
               join pallet_bases on pallet_bases.pallet_base_code = pallet_format_products.pallet_base_code
                     AND pallet_bases.id = pallet_format_products.pallet_base_id
               join fg_products on fg_products.fg_product_code = pallets.fg_product_code
               join item_pack_products on item_pack_products.item_pack_product_code = fg_products.item_pack_product_code
                     AND item_pack_products.id = fg_products.item_pack_product_id',
              :conditions => ['pallets.consignment_note_number = ?',
                intake_headers_production.consignment_note_number]).map { |p| [p.controlbreak || "NULL", p.id] }.sort

    # Group sets of pallet nos
    groups = pallnos.group_by {|p| p[0]}
    # Yield each group back to the calling method
    groups.each { |group, content| yield content }
  end

  # IS Intake Summary record.
  #
  # Build from IntakeHeader/IntakeHeadersProduction and a pallet from the summarised group
  # of pallets.
  def build_is_record( intake_headers_production, is_keys )
    
    begin
      pallet      = Pallet.find(is_keys.first[1])
    rescue ActiveRecord::RecordNotFound
      raise EdiOutError, "#{@err_prefix} - Pallet with id #{is_keys.first[1]} not found."
    end

    commodity   = Commodity.find(:first, :conditions => ['commodity_code = ?', pallet.commodity_code])
    raise EdiOutError, "#{@err_prefix} - No commodity code: #{pallet.commodity_code}." if commodity.nil?
    
    variety     = MarketingVariety.find(:first, :conditions => ['marketing_variety_code = ?', pallet.marketing_variety_code])
    raise EdiOutError, "#{@err_prefix} - No variety code: #{pallet.marketing_variety_code}." if variety.nil?
    
    mark        = Mark.find(:first, :conditions => ['mark_code = ?', pallet.carton_mark_code])
    raise EdiOutError, "#{@err_prefix} - No mark code: #{pallet.carton_mark_code}." if mark.nil?
    
    pfp         = PalletFormatProduct.find(:first, :conditions => ['id = ?', pallet.pallet_format_product_id])
    raise EdiOutError, "#{@err_prefix} - No PalletFormatProduct code: #{pallet.pallet_format_product_id}." if pfp.nil?
    
    pallet_base = PalletBase.find(:first, :conditions => ['pallet_base_code = ?', pfp.pallet_base_code])
    raise EdiOutError, "#{@err_prefix} - No pallet_base code: #{pfp.pallet_base_code}." if pallet_base.nil?

    fgp         = FgProduct.find(:first, :conditions => ['fg_product_code = ?', pallet.fg_product_code])
    raise EdiOutError, "#{@err_prefix} - No FgProduct code: #{pallet.fg_product_code}." if fgp.nil?

    ipp         = ItemPackProduct.find(:first, :conditions => ['item_pack_product_code = ?', fgp.item_pack_product_code])
    raise EdiOutError, "#{@err_prefix} - No ItemPackProduct code: #{fgp.item_pack_product_code}." if ipp.nil?

    size_ref = ipp.size_ref == 'NOS' ? ipp.actual_count : ipp.size_ref

    prod_char = pallet.pt_product_characteristics.nil? ? nil : pallet.pt_product_characteristics[0..2]

    # Array of pallet ids
    pallet_ids = is_keys.map {|k| k[1] }

    # sum of all pallets.carton_quantity_actual on iph
    carton_quantity = Pallet.sum('carton_quantity_actual',
                                 :conditions => ['id IN (?)', pallet_ids])

    # Sum of all pallets.carton_quantity_actual / cpp
    # NB This must be cast to float:
    pallet_quantity = Pallet.sum('cast(carton_quantity_actual as float) / cast(cpp as float)',
                                 :conditions => ['id IN (?)', pallet_ids]).to_f
    @total_is_cartons += carton_quantity
    @total_is_pallets += pallet_quantity

    inventory_code = pallet.inventory_code[0..1]
    inventory_code = '  ' if @change_val_for[:inventory_code_ul] && 'UL' == inventory_code && ['PL','PZ'].include?( pallet.commodity_code )

    rec = {'load_id'                => intake_headers_production.consignment_note_number,
           'document_number'        => intake_headers_production.consignment_note_number,
           'organisation'           => pallet.organization_code,
           'commodity_group'        => commodity.commodity_group_code,
           'commodity'              => pallet.commodity_code,
           'variety_group'          => variety.variety_group_code,
           'variety'                => pallet.marketing_variety_code,
           'pack'                   => pallet.old_pack_code,
           'grade'                  => pallet.grade_code,
           'mark'                   => mark.brand_code,
           'count'                  => size_ref,
           'inventory_code'         => inventory_code,
           'picking_reference'      => Carton.decrypt_pick_ref( pallet.pick_reference_code, pallet.commodity_code ),
           'target_market'          => pallet.target_market_code[0..1],
           'cartons_on_document'    => carton_quantity,
           'intake_carton_quantity' => carton_quantity,
           'pallet_quantity'        => pallet_quantity,
           'product_characteristic' => prod_char,
           'transaction_date'       => Date.today,
           'transaction_time'       => Time.now,
           'channel'                => pallet.organization_code == 'TI' ? 'L' : 'E',
           'pallet_base_type'       => pallet_base.edi_out_pallet_base
    }
  end

  # IP Intake Pallet record.
  #
  # Build from IntakeHeader/IntakeHeadersProduction and Pallet.
  def build_ip_record( intake_headers_production, pallet, pallet_id,
                       seq, carton_quantity, pallet_quantity, mixed_pallet_ind )

    prod_char = pallet.pt_product_characteristics.nil? ? nil : pallet.pt_product_characteristics[0..2]

    # Masterfile validations
    # ======================
    if @to_validate[:product_code_target_market]
      mf_ok, mf_msg = MfProductCodeTargetMarket.masterfile_has?( 'mkt_gtin', [pallet.gtin, pallet.target_market_code[0..1]] )
      raise EdiOutError, "#{@err_prefix} - #{mf_msg} (pallet_id #{pallet_id}, carton.gtin #{pallet.gtin})" unless mf_ok
    end

    if @to_validate[:product_code]
      mf_ok, mf_msg = MfProductCode.masterfile_has?( 'gtin_by_date', [pallet.gtin,
                                                    intake_headers_production.created_on,
                                                    intake_headers_production.created_on] )
      raise EdiOutError, "#{@err_prefix} - #{mf_msg} (pallet #{pallet_id})" unless mf_ok
    end
    inventory_code = pallet.inventory_code[0..1]
    inventory_code = '  ' if @change_val_for[:inventory_code_ul] && 'UL' == inventory_code && ['PL','PZ'].include?( pallet.commodity_code )

    @total_ip_cartons += carton_quantity
    @total_ip_pallets += pallet_quantity

    if @is_production
      phc = nil
      carton = Carton.find(:first, :conditions => ['pallet_number = ?', pallet.pallet_number])
      unless carton.nil?
        line = Line.find(:first, :conditions => ['line_code = ?', carton.line_code])
        phc  = line.line_phc unless line.nil?
      end
    else
      phc = intake_headers_production.packhouse_code
    end
    

    # Special account code used for TI:
    if @account_code == '8385'
	    if pallet.puc.start_with?('C')
	       orig_account_code = 'CFG'
	    else
	       orig_account_code = @account_code
	    end
    else
      orig_account_code = @account_code
    end    

    rec = {'load_id'                => intake_headers_production.consignment_note_number,
           'document_number'        => intake_headers_production.consignment_note_number,
           'pallet_id'              => pallet_id,
           'sequence_number'        => seq,
           'organisation'           => pallet.organization_code,
           'commodity_group'        => pallet.commodity_group_code,
           'commodity'              => pallet.commodity_code,
           'variety_group'          => pallet.variety_group_code,
           'variety'                => pallet.variety_short_long[0..2],
           'pack'                   => pallet.old_pack_code,
           'grade'                  => pallet.grade_code,
           'mark'                   => pallet.brand_code,
           'count'                  => pallet.actual_size_count_code,
           'inventory_code'         => inventory_code,
           'picking_reference'      => Carton.decrypt_pick_ref( pallet.pick_reference_code, pallet.commodity_code ),
           'farm_from_code'         => pallet.puc,
           'product_characteristic' => prod_char,
           'target_market'          => pallet.target_market_code[0..1],
           'carton_quantity'        => carton_quantity,
           'pallet_quantity'        => pallet_quantity,
           'mixed_indicator'        => mixed_pallet_ind,
           'intake_date'            => intake_headers_production.created_on,
           'intake_time'            => intake_headers_production.created_on,
           'original_intake_date'   => intake_headers_production.created_on,
           'order_number'           => intake_headers_production.order_number,
           'transaction_date'       => Date.today,
           'transaction_time'       => Time.now,
           'pallet_base_type'       => pallet.edi_out_pallet_base,
           'sscc'                   => pallet.pallet_number,
           'orig_account'           => orig_account_code,
           'waybill_no'             => intake_headers_production.phytowaybill,
           'gtin'                   => pallet.gtin,
           'packh_code'             => phc,
           'sellbycode'             => pallet.sell_by_code,
           'channel'                => pallet.organization_code == 'TI' ? 'L' : 'E',
           'season'                 => pallet.season_code
    }
  end

end

