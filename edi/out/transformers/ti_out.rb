# Transfer In (TI).
class TiOut < TextOutTransformer

  # Override the filenaming. Prefix the file with "PI" instead of "TI".
  def make_paltrack_file_name( proposal )
    if EdiHelper.current_out_is_cumulative
      @filename = "PI#{EdiHelper.network_address}#{Time.now.strftime('%Y%m%d-%H%M%S')}.#{proposal.hub_address}"
    else
      @filename = "PI#{EdiHelper.network_address}#{@formatted_seq}.#{proposal.hub_address}"
    end
  end

  # Create a HierarchicalRecordSet from the EdiOutProposal record.
  #
  # The proposal's +record_map+ attribute contains the attributes
  # of an IntakeHeader model.
  #    Batch Header               -> BH
  #    IntakeHeadersProduction    -> IC
  #      `-- Pallet records       -> IP
  #    Batch Trailer              -> BT
  def create_doc_records(proposal)
    puts "create_doc_records in TI"

    # Initialise the record counts for use in the batch trailer record.
    @ic_record_count,  @ip_record_count  = [0, 0, 0]
    @total_ic_cartons, @total_ip_cartons = [0, 0, 0]
    @total_ic_pallets, @total_ip_pallets = [0.0, 0.0, 0.0]

    EdiHelper.transform_log.write "Transforming Transfer In (TI) for IntakeHeader #{@record_map['id']}.."

    # Make several IC records.           IN CONSIGNMENT
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
      intake_header = IntakeHeader.find(@record_map['id'])
    rescue ActiveRecord::RecordNotFound
      raise EdiOutError, "#{@err_prefix} - IntakeHeader with id #{@record_map['id']} not found."
    end

    # For cerain organizations, if the inventory code is 'UL', make it blank.
    @change_val_for = {}
    @change_val_for[:inventory_code_ul] = true if ['CA', 'XT'].include?(intake_header.organization_code)

    ic = HierarchicalRecordSet.new( build_ic_record( intake_header ), 'IC')
    @ic_record_count += 1
    rec_set.add_child ic

    # ----------
    # IS records
    # ----------

    make_is_groups( intake_header ) do |is_keys|
      # Get all the pallets for this summary, extract the 9-digit pallet_id from the pallet_number
      # and sort in pallet_id sequence.
      # Calculate the carton and pallet quantities.
      # NB Sometimes the pallet number is only 9 characters, not 18 - use the whole number instead of
      #    just the last 9 characters.
      pallet_ids = is_keys.map {|k| k[1] }
      pallets    = Pallet.find(pallet_ids).map do |m|
        #[m.pallet_number.length > 9 ? m.pallet_number[-10, 9] : m.pallet_number, m, m.cartons.count, ((m.cartons.count / m.cpp.to_f) * 100).to_i, 1]
        [m.pallet_number.length > 9 ? m.pallet_number[-10, 9] : m.pallet_number, m, m.cartons.count, ((m.cartons.count / m.carton_quantity_actual.to_f) * 100).to_i, 1]
      end.sort


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
        ip = HierarchicalRecordSet.new( build_ip_record( intake_header,
                                                         pallet, pallet_id, seq,
                                                         carton_quantity, pallet_quantity), 'IP')
        @ip_record_count += 1
        ic.add_child ip
      end
    end

    # ---------
    # BT record
    # ---------
    trailer = HierarchicalRecordSet.new({'trailer' => 'BT',
                                         'network_address'  => 31,
                                         'batch_number'     => @out_seq,
                                         'record_count'     => 2 + @ic_record_count + + @ip_record_count,
                                         'ic_record_count'  => @ic_record_count,
                                         'is_record_count'  => 0,
                                         'ip_record_count'  => @ip_record_count,
                                         'ev_record_count'  => 0,
                                         'total_ic_cartons' => @total_ic_cartons,
                                         'total_ic_pallets' => @total_ic_pallets,
                                         'total_dummy_ic_cartons' => 0,
                                         'total_dummy_ic_pallets' => 0,
                                         'total_is_cartons' => 0,
                                         'total_is_pallets' => 0,
                                         'total_ip_cartons' => @total_ip_cartons,
                                         'total_ip_pallets' => @total_ip_pallets
                                        }, 'BT')
    rec_set.add_child trailer
    rec_set
  end

  # IC Intake Consignment record.
  #
  # Built up from IntakeHeader, representative Pallet and representative Carton.
  def build_ic_record( intake_header )

    # sum of all pallets.carton_quantity_actual on iph
    carton_quantity = Pallet.sum('carton_quantity_actual',
                                 :conditions => ['consignment_note_number = ?',
                                   intake_header.consignment_note_number])
    carton_quantity ||= 0
    # Sum of all pallets.carton_quantity_actual / cpp
    # NB This must be cast to float:
    pallet_quantity = Pallet.sum('cast(carton_quantity_actual as float) / cast(cpp as float)',
                                 :conditions => ['consignment_note_number = ?',
                                   intake_header.consignment_note_number]).to_f
    pallet_quantity ||= 0.0

    # Count of pallets with build_status == 'FULL'
    full_pallet     = Pallet.count('id',
                                 :conditions => ["consignment_note_number = ? AND build_status = 'FULL'",
                                   intake_header.consignment_note_number])

    # Count of pallets with build_status == 'PARTIAL'
    inc_pallet      = Pallet.count('id',
                                 :conditions => ["consignment_note_number = ? AND build_status = 'PARTIAL'",
                                   intake_header.consignment_note_number])
    @total_ic_cartons += carton_quantity
    @total_ic_pallets += pallet_quantity
    
    EdiHelper.transform_log.write "depot_short_code: #{intake_header.depot.depot_short_code}"

    rec = {'load_id'          => intake_header.consignment_note_number,
           #'location_code'    => intake_header.depot.depot_short_code,
           'document_number'  => intake_header.consignment_note_number,
           'organisation'     => intake_header.organization_code,
           'document_type'    => intake_header.intake_type_code,
           'document_date'    => intake_header.created_on,
           'rail_date'        => intake_header.created_on,
           'account'          => intake_header.account_code,
           'pro_no'           => intake_header.id,
           'carton_quantity'  => carton_quantity,
           #'pallet_quantity'  => pallet_quantity,
	   'pallet_quantity'  => intake_header.qty_pallets,
           'full_pallet'      => full_pallet,
           'inc_pallet'       => inc_pallet,
           #'season'           => intake_header.season_code,
           'season'           => intake_header.season,
           'client_ref'       => intake_header.order_number,
           'order_no'         => intake_header.order_number,
	   'from_location_code' => intake_header.depot.depot_short_code,
           'inspector'        => intake_header.inspector_number,
           'inspection_date'  => intake_header.inspection_date,
           'inspection_time'  => intake_header.inspection_date,
           'inspection_point' => intake_header.inspection_point,
           'revision_number'  => intake_header.revision_number,
           'transaction_date' => Date.today,
           'transaction_time' => Time.now,
           'arrival_date'     => intake_header.created_on,
           'arrival_time'     => intake_header.created_on,
           'carton_quantity_2'=> carton_quantity,
           'pallet_quantity_2'=> pallet_quantity,
           'reference_number' => intake_header.order_number,
           'packh_code'       => intake_header.packhouse_code,
           'sellbycode'       => intake_header.sell_by_code,
           'waybill_no'       => intake_header.phytowaybill
    }
  end
  
      

  # Get all the pallets linked to the IntakeHeadersProduction.
  #
  # Group by:
  #   pallets.organization_code
  #   pallets.commodity_code
  #   pallets.marketing_variety_code
  #   pallets.old_pack_code
  #   pallets.grade_code
  #   marks.brand_code
  #   pallets.actual_size_count_code
  #   pallets.inventory_code
  #   pallets.target_market_code
  #   pallet_bases.edi_out_pallet_base
  #
  # Yield each set of pallets in a group.
  def make_is_groups( intake_header )
    # Query
    palls = Pallet.find(:all, :select => "pallets.id, (pallets.organization_code ||
              pallets.commodity_code || pallets.marketing_variety_code || pallets.old_pack_code ||
              pallets.grade_code || marks.brand_code || CASE item_pack_products.size_ref
                WHEN 'NOS'::text THEN item_pack_products.actual_count::character varying
                ELSE item_pack_products.size_ref
              END ||
              pallets.inventory_code || pallets.target_market_code ||
              pallet_bases.edi_out_pallet_base) controlbreak",
              :joins => 'join marks on marks.mark_code = pallets.carton_mark_code
              join pallet_format_products on pallet_format_products.id = pallets.pallet_format_product_id
              join pallet_bases on pallet_bases.pallet_base_code = pallet_format_products.pallet_base_code
                     AND pallet_bases.id = pallet_format_products.pallet_base_id
               join fg_products on fg_products.fg_product_code = pallets.fg_product_code
               join item_pack_products on item_pack_products.item_pack_product_code = fg_products.item_pack_product_code
                     AND item_pack_products.id = fg_products.item_pack_product_id',
              :conditions => ['pallets.consignment_note_number = ?',
                intake_header.consignment_note_number])

    if palls.nil? || palls.empty?
      raise EdiOutError, "#{@err_prefix} - No pallets for consignment note '#{intake_header.consignment_note_number}'."
    end

    if palls.any? {|p| p.controlbreak.nil? }
      raise EdiOutError, "#{@err_prefix} - A pallet controlbreak for consignment note '#{intake_header.consignment_note_number}' is null."
    end
    pallnos = palls.map { |p| [p.controlbreak, p.id] }.sort

    # Group sets of pallet nos
    groups = pallnos.group_by {|p| p[0]}
    # Yield each group back to the calling method
    groups.each { |group, content| yield content }
  end

  # IP Intake Pallet record.
  #
  # Build from IntakeHeadersProduction and Pallet.
  def build_ip_record( intake_header, pallet, pallet_id, seq, carton_quantity, pallet_quantity )
    
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

    carton      = pallet.cartons.find(:first)
    raise EdiOutError, "#{@err_prefix} - No cartons for pallet with id: #{pallet.id}." if carton.nil?


    prod_char = pallet.pt_product_characteristics.nil? ? nil : pallet.pt_product_characteristics[0..2]

    @total_ip_cartons += carton_quantity
    @total_ip_pallets += pallet_quantity

    inventory_code = pallet.inventory_code[0..1]
    inventory_code = '  ' if @change_val_for[:inventory_code_ul] && 'UL' == inventory_code && ['PL','PZ'].include?( pallet.commodity_code )

    rec = {'load_id'                => intake_header.consignment_note_number,
           'document_number'        => intake_header.consignment_note_number,
           'pallet_id'              => pallet_id,
           'sequence_number'        => seq,
           'organisation'           => pallet.organization_code, # MARKETING_org_code???
           'commodity_group'        => commodity.commodity_group_code,
           'commodity'              => pallet.commodity_code,
           'variety_group'          => variety.variety_group_code,
           'variety'                => pallet.marketing_variety_code,
           'pack'                   => pallet.old_pack_code,
           'grade'                  => pallet.grade_code,
           'mark'                   => mark.brand_code,
           'count'                  => carton.actual_size_count_code,
           'inventory_code'         => inventory_code,
           'picking_reference'      => carton.pick_reference,
           'farm_from_code'         => carton.product_class_code,
           'product_characteristic' => prod_char,
           'target_market'          => pallet.target_market_code[0..1],
           'carton_quantity'        => carton_quantity,
           'pallet_quantity'        => pallet_quantity,
           'intake_date'            => intake_header.created_on,
           'intake_time'            => intake_header.created_on,
           'original_intake_date'   => intake_header.created_on,
           'order_number'           => intake_header.order_number,
           'transaction_date'       => Date.today,
           'transaction_time'       => Time.now,
           'pallet_base_type'       => pallet_base.edi_out_pallet_base,
           'sscc'                   => pallet.pallet_number,
           'waybill_no'             => intake_header.phytowaybill,
           'gtin'                   => carton.gtin, # Currently blank in all cartons --> made non-required in schema
           'packh_code'             => intake_header.packhouse_code,
           'sellbycode'             => carton.sell_by_code,
	   'original_intake_depot' => intake_header.depot.depot_short_code
    }
  end

end


