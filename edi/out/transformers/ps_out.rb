# Pallet Stock (PS).
class PsOut < TextOutTransformer

  # Create a HierarchicalRecordSet from the EdiOutProposal record.
  #
  # The proposal's +record_map+ attribute contains the organisation code
  # for whom a pallet stock file is required.
  #    Batch Header               -> BH
  #    Pallet Stock records       -> PS
  #    Batch Trailer              -> BT
  def create_doc_records(proposal)
    puts "create_doc_records in PS"

    # Initialise the record counts for use in the batch trailer record.
    @ps_record_count = 0
    @total_cartons   = 0

    EdiHelper.transform_log.write "Transforming Pallet Stock (PS) for organization #{@record_map['organization_code']}.."

    # For cerain organizations, if the inventory code is 'UL', make it blank.
    @change_val_for = {}
    @change_val_for[:inventory_code_ul] = true if ['CA', 'XT'].include?(@record_map['organization_code'])

    # # Get the list of organizations to query:
    # org_codes = Organization.find(:all,
    #             :conditions => ['short_description = ? or parent_org_short_description = ?',
    #             @record_map['organization_code'],
    #             @record_map['organization_code']]).map {|c| c.short_description}

    # ---------
    # BH record
    # ---------
    rec_set = HierarchicalRecordSet.new({'header' => 'BH',
                                         'network_address' => 31,
                                         'batch_number' => @out_seq,
                                         'create_date' => Date.today,
                                         'create_time' => Time.now
                                        }, 'BH')
    
    # ---------
    # PS record
    # ---------
    pallets = Pallet.find(:all,
    :select => "pallets.id, pallets.consignment_note_number, pallets.is_depot_pallet,
                pallets.pallet_number, pallets.remark, pallet_bases.edi_out_pallet_base,
                pallets.marketing_variety_code, pallets.pt_product_characteristics,
                marks.brand_code, commodities.commodity_group_code,
                marketing_varieties.variety_group_code, stock_items.location_code,
                pallets.cpp, cartons.organization_code carton_org, cartons.gtin,
                cartons.target_market_code cart_tgt_marget,
                cartons.sell_by_code,cartons.season_code cart_season, pallets.pick_reference_code, cartons.puc,
                cartons.commodity_code cart_commodity_code,
                cartons.inventory_code cart_inventory_code,
                cartons.old_pack_code cart_pack,
                cartons.grade_code cart_grade,
                case item_pack_products.size_ref when 'NOS' then cast(item_pack_products.actual_count as varchar) else item_pack_products.size_ref end as cart_count,
                count(cartons.id) no_cartons,
                count(cartons.id) / cast(pallets.carton_quantity_actual as float) * 100 no_pallets, pallets.carton_quantity_actual,pallets.pallet_format_product_id",
    :joins => 'join stock_items on stock_items.inventory_reference = pallets.pallet_number
               join cartons on cartons.pallet_id = pallets.id
               join pallet_format_products on pallet_format_products.id = pallets.pallet_format_product_id
               join pallet_bases on pallet_bases.pallet_base_code = pallet_format_products.pallet_base_code
               join marks on marks.mark_code = cartons.carton_mark_code
               join commodities on commodities.commodity_code = cartons.commodity_code
               join marketing_varieties on marketing_varieties.marketing_variety_code = substring(cartons.variety_short_long from 1 for 3)
               join extended_fgs on extended_fgs.extended_fg_code = cartons.extended_fg_code
               join fg_products on fg_products.fg_product_code = extended_fgs.fg_code
               join item_pack_products on item_pack_products.item_pack_product_code = fg_products.item_pack_product_code',
#    :conditions => ["pallets.organization_code in (?)
    :conditions => ["pallets.organization_code = ?
                     AND pallets.consignment_note_number is not null
                     AND (stock_items.destroyed is null OR stock_items.destroyed = false)",
#                      org_codes],
                      @record_map['organization_code']],
    :order => 'pallets.pallet_number',
    :group => 'pallets.id, pallets.consignment_note_number, pallets.is_depot_pallet,
               pallets.pallet_number, pallets.remark, pallet_bases.edi_out_pallet_base,
               pallets.marketing_variety_code, pallets.pt_product_characteristics,
               marks.brand_code, commodities.commodity_group_code,
               marketing_varieties.variety_group_code, stock_items.location_code,
               pallets.cpp, pallets.carton_quantity_actual, cartons.organization_code, cartons.gtin, cartons.target_market_code,
               cartons.sell_by_code, pallets.pick_reference_code, cartons.puc,
               cartons.commodity_code, cartons.inventory_code,cartons.season_code,
               cartons.old_pack_code,
               cartons.grade_code, cartons.actual_size_count_code,item_pack_products.actual_count,item_pack_products.size_ref,pallets.carton_quantity_actual,pallets.pallet_format_product_id')

    # There might be no data for this organization:
    #raise EdiOutError, "#{@err_prefix} - No data for organization #{@record_map['organization_code']}." if pallets.empty?
    unless pallets.empty?

      # If a pallet occurs more than once, sum the pallet_counts, subtract from one and add
      # the difference to one of the records so that the total of all the pallets is always == 1.
      prev       = ''
      tot_pall   = 100
      diffs      = {}
      seq        = 1
      max_index  = 0
      max_pall   = 0
      pallets.each_with_index do |pallet, index|
        pallet.no_pallets = pallet.no_pallets.to_i
        if pallet.pallet_number != prev
          if seq > 1 && tot_pall != 100
            diff = 100 - tot_pall
            diffs[max_index] = diff
          end
          seq = 1
          prev      = pallet.pallet_number
          max_pall  = pallet.no_pallets
          max_index = index
          tot_pall  = pallet.no_pallets
        else
          seq += 1
          tot_pall += pallet.no_pallets
          if pallet.no_pallets > max_pall
            max_pall  = pallet.no_pallets
            max_index = index
          end
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
        new_tot = pallets[k].no_pallets
        new_tot += v
        pallets[k].no_pallets = new_tot
      end

      # Get a list of mixed pallets (those whose ids occur more than once)
      id_list = pallets.map {|p| p.id }                         # Get list of ids
      hs = Hash.new(0)
      id_list.inject(hs) {|hs,a| hs[a] += 1; hs; }              # Count each id
      mixed_pallet_ids = hs.select {|k,v| v > 1 }.map {|a|a[0]} # Select ids with count > 1

      # Now loop through the pallets again and create the PS records.
      prev_pallet = ''
      seq_no      = 0
      pallets.each do |pallet|
        if pallet.pallet_number != prev_pallet
          seq_no = 1
          prev_pallet = pallet.pallet_number
        else
          seq_no += 1
        end
        if mixed_pallet_ids.include? pallet.id
          mixed_ind = 'Y'
        else
          mixed_ind = 'N'
        end

        ps_rec = HierarchicalRecordSet.new( build_ps_record( pallet, seq_no, mixed_ind ), 'PS' )
        rec_set.add_child ps_rec
        @ps_record_count += 1
      end
    end

    # ---------
    # BT record
    # ---------
    trailer = HierarchicalRecordSet.new({'trailer' => 'BT',
                                         'network_address'  => 31,
                                         'batch_number'     => @out_seq,
                                         'record_count'     => 2 + @ps_record_count,
                                         'ps_record_count'  => @ps_record_count,
                                         'total_cartons'    => @total_cartons
                                        }, 'BT')
    rec_set.add_child trailer
    rec_set
  end

  def build_ps_record( pallet, seq_no, mixed_ind )

    @total_cartons   += pallet.no_cartons.to_i

    begin
      if pallet.is_depot_pallet
        ih_name = 'IntakeHeader'
        intake_header = IntakeHeader.find(:first,
                        :conditions => ['consignment_note_number = ?',
                                        pallet.consignment_note_number])
      else
        ih_name = 'IntakeHeadersProduction'
        intake_header = IntakeHeadersProduction.find(:first,
                        :conditions => ['consignment_note_number = ?',
                                        pallet.consignment_note_number])
      end
      raise EdiOutError, "#{@err_prefix} - #{ih_name} for consignment note no #{pallet.consignment_note_number} not found." if intake_header.nil?
    rescue ActiveRecord::RecordNotFound
      raise EdiOutError, "#{@err_prefix} - #{ih_name} for consignment note no #{pallet.consignment_note_number} not found."
    end

      # Special account code used for TI:
      if 'TI' == intake_header.organization_code &&
        intake_header.consignment_note_number   &&
        intake_header.consignment_note_number.start_with?( 'L031' )
        account_code = '8385'
	if pallet.puc.start_with?('C')
	   orig_account_code = 'CFG'
	else
	   orig_account_code = account_code
	end
      else
        account_code = intake_header.account_code
	orig_account_code = account_code
      end

    prod_char = pallet.pt_product_characteristics.nil? ? nil : pallet.pt_product_characteristics[0..2]

    temp_pallet_number = pallet.pallet_number[-10, 9]
    if(pallet.pallet_number.length == 9)
      temp_pallet_number = pallet.pallet_number
    end

    phc = nil
    carton = Carton.find(:first, :conditions => ['pallet_number = ?', pallet.pallet_number])
    unless carton.nil?
      line = Line.find(:first, :conditions => ['line_code = ?', carton.line_code])
      phc  = line.line_phc unless line.nil?
    end
    inventory_code = pallet.cart_inventory_code[0..1]
    inventory_code = '  ' if @change_val_for[:inventory_code_ul] && 'UL' == inventory_code && ['PL','PZ'].include?( pallet.cart_commodity_code )
    if(pallet.cpp == pallet.carton_quantity_actual)
      stack_variance = 'F'
    else 
      stack_variance = 'P'
    end
      
    rec = {
      'pallet_id'          => temp_pallet_number,
      'sequence_number'    => seq_no,
      'consignment_number' => pallet.consignment_note_number,
      'organisation'       => pallet.carton_org,
      'commodity_group'    => pallet.commodity_group_code,
      'commodity'          => pallet.cart_commodity_code,
      'variety_group'      => pallet.variety_group_code,
      'variety'            => pallet.marketing_variety_code,
      'pack'               => pallet.cart_pack,
      'grade'              => pallet.cart_grade,
      'size-count'         => pallet.cart_count,
      'mark'               => pallet.brand_code,
      'inventory_code'     => inventory_code,
      #'picking_reference'  => pallet.pick_reference_code,
      'picking_reference'      => Carton.decrypt_pick_ref( pallet.pick_reference_code,  pallet.cart_commodity_code ),
      'product_characteristic_code' => prod_char,
      'target_market'    => pallet.cart_tgt_marget[0..1],
      'farm'             => pallet.puc,
      'carton_quantity'  => pallet.no_cartons,
      'pallet_quantity'  => pallet.no_pallets / 100.0,
      'remarks'          => pallet.remark,
      'mixed_indicator'  => mixed_ind,
      'intake_date'      => intake_header.created_on,
      'original_intake'  => intake_header.created_on,
      #'cold_date'        => intake_header.created_on + (60*60*24*4), add 4 days to created_on date
      'cold_date'        => intake_header.created_on + (60*60*24*4),
      #'stock_pool'       => pallet.remark.nil? || pallet.remark.blank? ? 'CE' : 'HO',
      'stock_pool'       =>  'CE',
      'transaction_date' => Date.today,
      'transaction_time' => Time.now,
      'pallet_base_type' => pallet.edi_out_pallet_base,
      'order_no'         => intake_header.order_number,
      'sscc'             => pallet.pallet_number,
      'waybill_no'       => intake_header.phytowaybill,
      'gtin'             => pallet.gtin,
      'sellbycode'       => pallet.sell_by_code,
      'combo_sscc'       => pallet.pallet_number,
      'packh_code'       => phc,
      'original_account' => orig_account_code,
      'stack_variance' => stack_variance,
      'channel'        => pallet.carton_org == 'TI' ? 'L' : 'E',
      'season'         => pallet.cart_season
          }
  end

end

