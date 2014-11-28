# Pallet Movement (PM).
class PmOut < TextOutTransformer

  # Override the filenaming. Prefix the file with "PI" instead of "PM".
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
  # of a PpecbInspection model.
  #    Batch Header   -> BH
  #    Pallet records -> PM
  #    Batch Trailer  -> BT
  #
  def create_doc_records(proposal)

    # Initialise the record counts for use in the batch trailer record.
    @record_count = 0

    EdiHelper.transform_log.write "Transforming Pallet Movement (PM) for PpecbInspection #{@record_map['id']}.."

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
    # ----------
    # PM records
    # ----------
    begin
      ppecb_inspection = PpecbInspection.find(@record_map['id'])
    rescue ActiveRecord::RecordNotFound
      raise EdiOutError, "#{@err_prefix} - PpecbInspection with id #{@record_map['id']} not found."
    end
    begin
      insp_pallet = ppecb_inspection.pallet
    rescue ActiveRecord::RecordNotFound
      raise EdiOutError, "#{@err_prefix} - PpecbInspection pallet with id #{ppecb_inspection.pallet_id} not found."
    end

    intake_headers_production = IntakeHeadersProduction.find_by_consignment_note_number( insp_pallet.consignment_note_number )
    if intake_headers_production.nil?
      intake_headers_production = IntakeHeader.find_by_consignment_note_number( insp_pallet.consignment_note_number )
    end

    # --------------------------------------------------------------
    # Set the rules for what is to be validated against masterfiles.
    # --------------------------------------------------------------
    @to_validate = {}
    @to_validate[:product_code_target_market] = ['TI', 'CA'].include?(intake_headers_production.organization_code)
    @to_validate[:product_code]               = ['TI', 'CA'].include?(intake_headers_production.organization_code)

    # For cerain organizations, if the inventory code is 'UL', make it blank.
    @change_val_for = {}
    @change_val_for[:inventory_code_ul] = true if ['CA', 'XT'].include?(intake_headers_production.organization_code)

    pallets    = Pallet.find(:all,
                 :select => "count(cartons.*) as carton_count,
                  pallets.cpp, cartons.extended_fg_code, cartons.target_market_code, cartons.inventory_code,
                  cartons.puc, cartons.actual_size_count_code, pallets.pick_reference_code, cartons.gtin, cartons.sell_by_code,
                  pallets.pallet_number, cartons.organization_code, cartons.commodity_code, cartons.variety_short_long,
                  cartons.old_pack_code, cartons.grade_code, pallets.pt_product_characteristics, commodities.commodity_group_code,
                  marketing_varieties.variety_group_code, marks.brand_code,pallets.pallet_format_product_id, pallet_bases.edi_out_pallet_base",
                 :joins => "join cartons on cartons.pallet_id = pallets.id
                  join commodities on commodities.commodity_code = cartons.commodity_code
                  join marketing_varieties on marketing_varieties.marketing_variety_code = SUBSTRING(cartons.variety_short_long from 1 for 3)
                  join marks on marks.mark_code = pallets.carton_mark_code
                  join pallet_format_products on pallet_format_products.id = pallets.pallet_format_product_id
                  join pallet_bases on pallet_bases.pallet_base_code = pallet_format_products.pallet_base_code",
                 :group => "cartons.extended_fg_code, cartons.target_market_code, cartons.inventory_code,
                  cartons.puc, cartons.actual_size_count_code, pallets.pick_reference_code, cartons.gtin, cartons.sell_by_code,
                  pallets.pallet_number, cartons.organization_code, cartons.commodity_code, cartons.variety_short_long,
                  cartons.old_pack_code, cartons.grade_code, pallets.pt_product_characteristics, commodities.commodity_group_code,
                  marketing_varieties.variety_group_code, marks.brand_code, pallet_bases.edi_out_pallet_base, pallets.cpp",
                 :conditions => ["pallets.id = ?", insp_pallet.id]
                ).map {|m| [(m.pallet_number.length < 10 ? m.pallet_number : m.pallet_number[-10, 9]), m, m.carton_count.to_i, ((m.carton_count.to_i / m.cpp.to_f) * 100).to_i, 1]}.sort_by {|p| p[0]}

    raise EdiOutError, "#{@err_prefix} - No pallets." if pallets.empty?
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

    # If there are any pallet quantities that need to be adjusted, do that here:
    diffs.each do |k,v|
      new_tot = pallets[k][3]
      new_tot += v
      pallets[k][3] = new_tot
    end

    # Find all the pallet_ids that occur more than once. (Check for occurrence of seq_no == 2)
    mixed_pallet_ids = pallets.select {|a| a[4] == 2 }.map {|a| a[0] }

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

      @record_count += 1

       rec = HierarchicalRecordSet.new(
             {'document_number'      => intake_headers_production.consignment_note_number,
              'orig_pallet_id'       => pallet_id,
              'sequence_number'      => seq,
              'organisation'         => pallet.organization_code,
              'commodity_group'      => pallet.commodity_group_code,
              'commodity'            => pallet.commodity_code,
              'variety_group'        => pallet.variety_group_code,
              'variety'              => pallet.variety_short_long[0..2],
              'pack'                 => pallet.old_pack_code,
              'grade'                => pallet.grade_code,
              'mark'                 => pallet.brand_code,
              'count'                => pallet.actual_size_count_code,
              'inventory_code'       => inventory_code,
              'picking_reference'    => Carton.decrypt_pick_ref( pallet.pick_reference_code, pallet.commodity_code ),
              'farm_from_code'       => pallet.puc,
              'target_market'        => pallet.target_market_code[0..1],
              'carton_quantity'      => carton_quantity,
              'pallet_quantity'      => pallet_quantity,
              'mixed_indicator'      => mixed_pallet_ind,
              'intake_date'          => intake_headers_production.created_on,
              'intake_time'          => intake_headers_production.created_on,
              'original_intake_date' => intake_headers_production.created_on,
              'order_number'         => intake_headers_production.order_number,
              'transaction_date'     => Date.today,
              'transaction_time'     => Time.now,
              'pallet_base_type'     => pallet.edi_out_pallet_base,
              'cold_date'            => Date.today + 4,
              'sscc'                 => pallet.pallet_number,
              'new_sscc'             => pallet.pallet_number,
              'gtin'                 => pallet.gtin
       }, 'PM')
      rec_set.add_child rec

    end

    # ---------
    # BT record
    # ---------
    trailer = HierarchicalRecordSet.new({'trailer' => 'BT',
                                         'network_address'  => 31,
                                         'batch_number'     => @out_seq,
                                         'record_count'     => 2 + @record_count,
                                         'ic_record_count'  => 0,
                                         'is_record_count'  => 0,
                                         'ip_record_count'  => 0,
                                         'ev_record_count'  => 0,
                                         'total_ic_cartons' => 0,
                                         'total_ic_pallets' => 0,
                                         'total_dummy_ic_cartons' => 0,
                                         'total_dummy_ic_pallets' => 0,
                                         'total_is_cartons' => 0,
                                         'total_is_pallets' => 0,
                                         'total_ip_cartons' => 0,
                                         'total_ip_pallets' => 0
                                        }, 'BT')
    rec_set.add_child trailer
    rec_set
  end

end

