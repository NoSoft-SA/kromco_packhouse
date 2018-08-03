# Dispatch Transmission (PO).
class PoOut < TextOutTransformer

  # Create a HierarchicalRecordSet from the EdiOutProposal record.
  #
  # The proposal's +record_map+ attribute contains the attributes
  # of a LoadOrder model.
  #    Batch Header                -> BH
  #    Truck Header                -> OH
  #    Truck location from         -> LF (OL in final record)
  #    Truck location to           -> LT (OL in final record)
  #      `-- Container             -> OK (optional)
  #      `-- Intake Header         -> OC
  #            `-- Pallet sequence -> OP
  #    Batch Trailer               -> BT
  def create_doc_records(proposal)
    # Initialise the record counts for use in the batch trailer record.
    @oh_count, @ol_count, @oc_count, @ok_count, @op_count = [0,0,0,0,0]
    @total_carton_count, @total_pallet_count = [0,0]

    EdiHelper.transform_log.write "Transforming Dispatch Transmission (PO) for LoadOrder #{@record_map['id']}.."
    @load_id = "#{EdiHelper.network_address}-#{@record_map['load_id'].to_s.rjust(6, '0')}"

    begin
      @load_o  = LoadOrder.find(@record_map['id'])
      revision_number = @load_o.get_revision_number.to_i + 1
      @load_o.update_attribute(:revision_number,revision_number)



    rescue ActiveRecord::RecordNotFound
      raise EdiOutError, "#{@err_prefix} - LoadOrder with id #{@record_map['id']} not found."
    end

    begin
      @load    = Load.find(@record_map['load_id'])
    rescue ActiveRecord::RecordNotFound
      raise EdiOutError, "#{@err_prefix} - Load with id #{@record_map['load_id']} not found."
    end

    begin
      @order   = Order.find(@record_map['order_id'])
    rescue ActiveRecord::RecordNotFound
      raise EdiOutError, "#{@err_prefix} - Order with id #{@record_map['order_id']} not found."
    end
    ship_sender = PartiesRole.find(@order.customer_party_role_id).party_name[0,2]

    load_vehicle    = LoadVehicle.find_by_load_id(@record_map['load_id'])
    raise EdiOutError, "#{@err_prefix} - LoadVehicle with load_id #{@record_map['load_id']} not found." if load_vehicle.nil?

    load_voyage     = LoadVoyage.find_by_load_id(@record_map['load_id'])
    has_load_voyage = !load_voyage.nil?

    load_c          = LoadContainer.find_by_load_id(@record_map['load_id'])
    if load_c.nil? || load_c.container_code.nil? || load_c.container_code == ''
      load_type = 'F'
    else
      load_type = 'R'
    end

    if !has_load_voyage && !load_c.nil?
      raise EdiOutError, "#{@err_prefix} - Load with id #{@record_map['load_id']} has a LoadContainer but not a LoadVoyage."
    end

    # Get the load_detail ids associated with this load.
    ld_det_ids  = @load.load_detail_ids
    raise EdiOutError, "#{@err_prefix} - Unable to get a LoadDetail for Load with id #{@load.id}." if ld_det_ids.empty?

    # Using the load detail ids, find a random pallet from the first load detail that has pallets: 
    # (Some load_details might not have pallets - simply ignore them by checking the next load_detail)
    one_pallet = nil
    ld_det_ids.each do |ld_det_id|
      one_pallet = Pallet.find(:first, :conditions => ['load_detail_id = ?', ld_det_id])
      break unless one_pallet.nil?
    end
    raise EdiOutError, "#{@err_prefix} - No pallets for LoadDetail with ids: #{ld_det_ids.join(', ')}." if one_pallet.nil?

    pfp         = PalletFormatProduct.find(:first, :conditions => ['id = ?', one_pallet.pallet_format_product_id])
    raise EdiOutError, "#{@err_prefix} - No PalletFormatProduct with id: #{one_pallet.pallet_format_product_id}." if pfp.nil?

    pallet_base = PalletBase.find(:first, :conditions => ['pallet_base_code = ?', pfp.pallet_base_code])
    raise EdiOutError, "#{@err_prefix} - No PalletBase with pallet_base_code: #{pfp.pallet_base_code}." if pallet_base.nil?

    pallets = Pallet.find(:first, :select => 'count(pallets.id) plt_qty, sum(pallets.carton_quantity_actual) ctn_qty',
                          :joins  => 'join load_details on load_details.id = pallets.load_detail_id
                                      join loads on loads.id = load_details.load_id',
                          :conditions => ['loads.id = ?', @record_map['load_id']])
    if pallets.nil?
      @total_pallet_count = 0
      @total_carton_count = 0
    else
      @total_pallet_count = pallets.plt_qty.to_i
      @total_carton_count = pallets.ctn_qty.to_i
    end

    if has_load_voyage
      lv_sender       = PartiesRole.find(load_voyage.exporter_party_role_id).party_name[0,2]
      lv_agent        = PartiesRole.find(load_voyage.shipping_agent_party_role_id).party_name[0,2]
      lv_ship_sender  = PartiesRole.find(load_voyage.shipper_party_role_id).party_name[0,2]
      lv_ship_agent   = PartiesRole.find(load_voyage.shipping_agent_party_role_id).party_name[0,2]
      lv_ship_number  = load_voyage.voyage.vessel.vessel_registration_number
    else
      lv_sender       = nil
      lv_agent        = nil
      lv_ship_sender  = nil
      lv_ship_agent   = nil
      lv_ship_number  = nil
    end

    # For cerain organizations, if the inventory code is 'UL', make it blank.
    @change_val_for = {}
    @change_val_for[:inventory_code_ul] = true if ['CA', 'XT'].include?(one_pallet.organization_code)

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
    # OH record
    # ---------
        if 'DP' == @order.order_type.order_type_code
      #locn_code = @order.depot.depot_short_code
      #NB order.belongs_to :depot cannot be trusted - read via the code:
      next_code = Depot.find_by_depot_code(@order.depot_code).depot_short_code
    else
      next_code = PartiesRole.find(@order.customer_party_role_id).party_name[0,7]
    end
    
    
    ##next_code = Depot.find_by_depot_code(@order.depot_code).depot_short_code
    oh_rec = HierarchicalRecordSet.new({
             'load_id'     => @load_id,
             'load_ref'    => load_vehicle.vehicle_number,
             'load_type'   => load_type,
             'load_status' => @load.load_status[0,1],
             'tk_date'     => @load.shipped_date_time,
             'start_date'  => @load.shipped_date_time,
             'end_date'    => @load.shipped_date_time,
             'dep_date'    => @load.shipped_date_time,
             'carrier'     => PartiesRole.find(load_vehicle.haulier_party_id).party_name[0,8],
             'plt_qty'     => @total_pallet_count,
             'ctn_qty'     => @total_carton_count,
             'sub_load'    => load_vehicle.vehicle_number,
             'next_type'   => @order.order_type.order_type_code,
             'next_code'   => next_code,
             'master_ord'  => @order.order_customer_detail.customer_order_number,
             'season'      => one_pallet.season_code,
             'trip_no'     => @load.load_number,
             'revision'    => @load_o.revision_number,
             'tran_date'   => Date.today,
             'tran_time'   => Time.now}, 'OH')
    rec_set.add_child oh_rec
    @oh_count += 1

    # ---------
    # LF (OL) record
    # ---------
    lf_rec = HierarchicalRecordSet.new({
             'load_id'     => @load_id,
             'locn_type'   =>'DP',
         #'locn_type'   => @order.order_type.order_type_code, KROMCO BEING A DEPOT IT IS ALWAYS DP
             'arr_date'    => @load.shipped_date_time,
             'arr_time'    => @load.shipped_date_time,
             'dep_date'    => @load.shipped_date_time,
             'dep_time'    => @load.shipped_date_time,
             'load_status' => @load.load_status[0,1],
             'tran_date'   => Date.today,
             'revision'    => @load_o.revision_number,
             'tran_time'   => Time.now}, 'LF')
    rec_set.add_child lf_rec
    @ol_count += 1

    # ---------
    # LT (OL) record
    # -------
    if 'DP' == @order.order_type.order_type_code
      #locn_code = @order.depot.depot_short_code
      #NB order.belongs_to :depot cannot be trusted - read via the code:
      locn_code = Depot.find_by_depot_code(@order.depot_code).depot_short_code
    else
      locn_code = PartiesRole.find(@order.customer_party_role_id).party_name[0,7]
    end

    lt_rec = HierarchicalRecordSet.new({
             'load_id'     => @load_id,
             'locn_type'   => @order.order_type.order_type_code,
             'locn_code'   => locn_code,
             'arr_date'    => @load.shipped_date_time,
             'arr_time'    => @load.shipped_date_time,
             'dep_date'    => @load.shipped_date_time,
             'dep_time'    => @load.shipped_date_time,
             'load_status' => @load.load_status[0,1],
             'tran_date'   => Date.today,
             'revision'    => @load_o.revision_number,
             'tran_time'   => Time.now}, 'LT')
    rec_set.add_child lt_rec
    @ol_count += 1

    # ---------
    # OK record
    # -------
    load_container = @load.load_containers.first
    unless load_container.nil?
      port = VoyagePort.find(:first,
                             :select => 'voyage_ports.*,ports.country_code',
                             :joins => 'join load_voyage_ports on load_voyage_ports.voyage_port_id = voyage_ports.id
                            join voyage_port_types on voyage_port_types.id = voyage_ports.voyage_port_type_id
					   join ports on ports.id = voyage_ports.port_id',
                             :conditions => ['load_voyage_ports.load_voyage_id = ? and UPPER(voyage_port_types.voyage_port_type_code) = ?',
                                             load_voyage.id, 'ARRIVAL'])
      raise EdiOutError, "#{@err_prefix} - No Arrival VoyagePort for LoadVoyage with id: #{load_voyage.id}." if port.nil?

      ok_rec = HierarchicalRecordSet.new({
               'load_id'        => @load_id,
               'container'      => load_container.container_code,
               'stuff_date'     => @load.shipped_date_time,
               'temp_set'       => load_container.container_setting,
               'disch_port'     => port.country_code+port.port_code,
               'ship_number'    => load_voyage.voyage.voyage_code,
               'pallet_btype'   => pallet_base.edi_out_pallet_base,
               'container_ref'      => load_voyage.booking_reference, #load_voyage.voyage.vessel.vessel_code,
               'ship_line'      => PartiesRole.find(load_voyage.shipping_line_party_id).party_name[0,1],
               'ship_name'      => load_voyage.voyage.vessel_code, 
               'doc_no'         => @load_o.dispatch_consignment_number,
               'sender'         => lv_sender,
               'agent'          => lv_agent,
               'ship_sender'    => ship_sender,
               'ship_agent'     => lv_ship_agent,
               'orgzn'          => one_pallet.organization_code,
               'ctn_qty'        => @total_carton_count,
               'plt_qty'        => @total_pallet_count,
               'ryan_no_old'    => load_container.container_temperature_rhine,
               'container_type' => load_container.stack_type_code[0,1],
               'container_size' => load_container.stack_type_code[0,2],
               'seal_no'        => load_container.container_seal_code,
               'consec_no'      => load_container.cto_consec_code,
               'cto_no'         => load_container.cto_consec_code,
               'revision'    => @load_o.revision_number,
               'ryan_no'        => load_container.container_temperature_rhine2,
               'tran_date'   => Date.today,
               'tran_time'   => Time.now}, 'OK')
      lt_rec.add_child ok_rec
      @ok_count += 1
    end

    # ---------
    # OC record
    # -------
    cons_type = 'DP' == @order.order_type.order_type_code ? 'OT' : 'DO'

    oc_rec = HierarchicalRecordSet.new({
             'load_id'        => @load_id,
             'orgzn'          => one_pallet.organization_code,
             'channel'        => one_pallet.organization_code == 'TI' ? 'L' : 'E',
             'cons_no'        => @load_o.dispatch_consignment_number,
             'cons_type'      => cons_type,
             'cons_date'      => @load.shipped_date_time,
             'ctn_qty'        => @total_carton_count,
             'plt_qty'        => @total_pallet_count,
             'season'         => one_pallet.season_code,
             'client_ref'     => @order.order_customer_detail.customer_order_number,
             'order_no'       => @order.order_customer_detail.customer_order_number,
             'dest_type'      => @order.order_type.order_type_code,
             'dest_code'      => locn_code,
             'cnts_on_truck'  => @total_carton_count,
             'pallet_btype'   => pallet_base.edi_out_pallet_base,
             'tran_date'      => Date.today,
              'revision'    => @load_o.revision_number,
             'tran_time'      => Time.now}, 'OC')
    lt_rec.add_child oc_rec
    @oc_count += 1

    # ---------
    # OP record
    # ---------

    op_container = load_container.nil? ? '' : load_container.container_code

    ld_pallets = LoadOrder.find(:all,
    :select => "pallets.id, pallets.consignment_note_number, pallets.is_depot_pallet,
                pallets.pallet_number, pallets.remark, pallet_bases.edi_out_pallet_base,
                substring(cartons.variety_short_long,1,3) as marketing_variety_code, pallets.pt_product_characteristics,
                marks.brand_code, commodities.commodity_group_code,
                marketing_varieties.variety_group_code,
                pallets.cpp, cartons.organization_code carton_org, max(cartons.gtin) as gtin,
                cartons.target_market_code cart_tgt_marget,target_markets.target_market_region_code as cart_tgt_region, target_markets.target_market_country_code as cart_tgt_country,
                case when cartons.sell_by_code ='-' then ' ' else cartons.sell_by_code end as sell_by_code, pallets.pick_reference_code, cartons.puc,
                cartons.commodity_code cart_commodity_code,
                cartons.inventory_code cart_inventory_code,
                cartons.old_pack_code cart_pack,
                cartons.season_code cart_season,		
                cartons.grade_code cart_grade,
                case item_pack_products.size_ref when 'NOS' then cast(item_pack_products.actual_count as varchar) else item_pack_products.size_ref end as cart_count,
                count(cartons.id) no_cartons,
		      count(cartons.id) / cast(pallets.carton_quantity_actual as float) * 100 no_pallets,pallets.pallet_format_product_id, sum(cartons.carton_fruit_nett_mass) as mass,
			 ppecb_inspections.created_at as inspec_date",
    :joins => 'join load_details on load_details.load_order_id = load_orders.id
               join pallets on pallets.load_detail_id = load_details.id
               join cartons on cartons.pallet_id = pallets.id
               join pallet_format_products on pallet_format_products.id = pallets.pallet_format_product_id
               join pallet_bases on pallet_bases.pallet_base_code = pallet_format_products.pallet_base_code
               join marks on marks.mark_code = cartons.carton_mark_code
               join commodities on commodities.commodity_code = cartons.commodity_code
               join marketing_varieties on marketing_varieties.marketing_variety_code = substring(cartons.variety_short_long from 1 for 3)
               join extended_fgs on extended_fgs.extended_fg_code = cartons.extended_fg_code
               join fg_products on fg_products.fg_product_code = extended_fgs.fg_code
	          join target_markets on target_markets.target_market_code = cartons.target_market_code
               join item_pack_products on item_pack_products.item_pack_product_code = fg_products.item_pack_product_code
			join ppecb_inspections on ppecb_inspections.id = pallets.ppecb_inspection_id',
    :conditions => ['load_orders.id = ?', @record_map['id']],
    :group => 'pallets.id, pallets.consignment_note_number, pallets.is_depot_pallet,
                pallets.pallet_number, pallets.remark, pallet_bases.edi_out_pallet_base,
                cartons.variety_short_long, pallets.pt_product_characteristics,
                marks.brand_code, commodities.commodity_group_code,
                marketing_varieties.variety_group_code,
                pallets.cpp, pallets.carton_quantity_actual,cartons.organization_code, 
                cartons.target_market_code,target_markets.target_market_region_code,target_markets.target_market_country_code,
                cartons.sell_by_code, pallets.pick_reference_code, cartons.puc,
                cartons.commodity_code,
                cartons.inventory_code,
                cartons.old_pack_code,
                cartons.season_code,		
                cartons.grade_code,
                item_pack_products.size_ref, item_pack_products.actual_count,pallets.pallet_format_product_id,ppecb_inspections.created_at',
    #:order => 'pallets.pallet_number')
    :order => 'pallets.pallet_number,commodities.commodity_group_code, cartons.commodity_code, marketing_varieties.variety_group_code, marks.brand_code, cartons.old_pack_code, cartons.grade_code, item_pack_products.size_ref, item_pack_products.actual_count, cartons.organization_code, cartons.target_market_code,target_markets.target_market_region_code,target_markets.target_market_country_code, pallets.pick_reference_code, cartons.puc')
      prev       = ''
      tot_pall   = 100
      diffs      = {}
      seq        = 1
      max_index  = 0
      max_pall   = 0
    if 1 == 2
      EdiHelper.transform_log.write "FULL Pallet list"
      EdiHelper.transform_log.write "==================================\n"
      ld_pallets.each do |pallet|
        EdiHelper.transform_log.write "NO: #{pallet.pallet_number}\tCTN: #{sprintf('%3d', pallet.no_cartons.to_i)}\tPQTY: #{sprintf('%6.2f', pallet.no_pallets)}\t= #{pallet.no_pallets.to_i / 100.0}"
      end
      EdiHelper.transform_log.write "==================================\n"
    end
      ld_pallets.each_with_index do |pallet, index|
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
        if index == ld_pallets.length-1
          if seq > 1 && tot_pall != 100
            diff = 100 - tot_pall
            diffs[max_index] = diff
          end
        end
      end

    # If there are any pallet quantities that need to be adjusted, do that here:
      diffs.each do |k,v|
        new_tot = ld_pallets[k].no_pallets
        new_tot += v
        ld_pallets[k].no_pallets = new_tot
      end

    # Get a list of mixed pallets (those whose ids occur more than once)
    id_list = ld_pallets.map {|p| p.id }                      # Get list of ids
    hs = Hash.new(0)
    id_list.inject(hs) {|hs,a| hs[a] += 1; hs; }              # Count each id
    mixed_pallet_ids = hs.select {|k,v| v > 1 }.map {|a|a[0]} # Select ids with count > 1

    if 1 == 2
      EdiHelper.transform_log.write "MIXED Pallet list - after rounding"
      EdiHelper.transform_log.write "==================================\n"
      ld_pallets.each do |pallet|
        if mixed_pallet_ids.include? pallet.id
          EdiHelper.transform_log.write "NO: #{pallet.pallet_number}\tCTN: #{sprintf('%3d', pallet.no_cartons.to_i)}\tPQTY: #{sprintf('%3d', pallet.no_pallets)}\t= #{pallet.no_pallets / 100.0}"
        end
      end
      EdiHelper.transform_log.write "==================================\n"
    end

    # Now loop through the pallets again and create the PS records.
    prev_pallet = ''
    seq_no      = 0
    ld_pallets.each do |pallet|
      if pallet.pallet_number != prev_pallet
        seq_no = 1
      else
        seq_no += 1
      end
      prev_pallet = pallet.pallet_number

      if mixed_pallet_ids.include? pallet.id
        mixed_ind = 'Y'
      else
        mixed_ind = 'N'
      end
      # NB as is_depot_pallet is not an attribute of LoadOrder, returns as string...
      if pallet.is_depot_pallet == 't'
        intake_header = IntakeHeader.find(:first,
                        :conditions => ['consignment_note_number = ?',
                                        pallet.consignment_note_number])
        phc           = intake_header.packhouse_code
      else
        intake_header = IntakeHeadersProduction.find(:first,
                        :conditions => ['consignment_note_number = ?',
                                        pallet.consignment_note_number])
        phc           = nil
      end
      raise EdiOutError, "#{@err_prefix} - Intake header not found for pallet #{pallet.id}, consnote: #{pallet.consignment_note_number}" if intake_header.nil?

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

      #prod_char = pallet.pt_product_characteristics.nil? ? nil : pallet.pt_product_characteristics[0..2]
      prod_char = '   '   

      unit_temperature = UnitTemperature.find_by_unit_number(pallet.pallet_number)
      temp_device_id   = unit_temperature.nil? ? nil : unit_temperature.temperature_device_code
      temp_device_type = temp_device_id.nil? ? nil : 'T4'

      inventory_code = pallet.cart_inventory_code[0..1]
      inventory_code = '  ' if @change_val_for[:inventory_code_ul] && 'UL' == inventory_code && ['PL','PZ'].include?( pallet.cart_commodity_code )

      if(pallet.cpp == pallet.no_cartons)
        stack_variance = 'F'
      else 
        stack_variance = 'P'
      end

      op_rec = HierarchicalRecordSet.new({
              'load_id'          => @load_id,
              'pallet_id'        => pallet.pallet_number[-10, 9],
              'seq_no'           => seq_no,
              'cons_no'          => @load_o.dispatch_consignment_number,
              'container'        => op_container,
              'orgzn'            => pallet.carton_org,
              'comm_grp'         => pallet.commodity_group_code,
              'commodity'        => pallet.cart_commodity_code,
              'var_grp'          => pallet.variety_group_code,
              'variety'          => pallet.marketing_variety_code,
              'pack'             => pallet.cart_pack,
              'grade'            => pallet.cart_grade,
              'mark'             => pallet.brand_code,
              'size_count'       => pallet.cart_count,
              'inv_code'         => inventory_code,
              #'pick_ref'         => pallet.pick_reference,
              'pick_ref'         => Carton.decrypt_pick_ref( pallet.pick_reference_code, pallet.cart_commodity_code ),
              'farm'             => pallet.puc,
              'prod_grp'         => pallet.edi_out_pallet_base,
              'prod_char'        => prod_char,
              'targ_mkt'         => pallet.cart_tgt_marget[0..1],
              'Target_region'         => pallet.cart_tgt_region[0..2],
              'Target_country'         => pallet.cart_tgt_country[0..1],	      
              'ctn_qty'          => pallet.no_cartons.to_i,
              'plt_qty'          => pallet.no_pallets / 100.0,
              'mixed_ind'        => mixed_ind,
              'remarks'          => pallet.remark,
              'intake_date'      => intake_header.created_on,
              'orig_intake'      => intake_header.created_on,
              'order_no'         => intake_header.order_number,
              'stock_pool'       => pallet.remark.nil? || pallet.remark.blank? ? 'CE' : 'HO',
              'pallet_btype'     => pallet.edi_out_pallet_base,
              'temp_device_id'   => temp_device_id,
              'temp_device_type' => temp_device_type,
              'Sscc'             => pallet.pallet_number,
              'Orig_account'     => orig_account_code,
              'Waybill_no'       => intake_header.phytowaybill,
              'Gtin'             => pallet.gtin,
              'Packh_code'       => phc,
              'SellbyCode'       => pallet.sell_by_code,
              'dest_type'        => @order.order_type.order_type_code,
              'dest_locn'        => locn_code,
              'sender'           => lv_sender,
              'agent'            => lv_agent,
              'ship_sender'      => ship_sender,
              'ship_agent'       => lv_ship_agent,
              'shift_date'       => @load.shipped_date_time,
              'shipped_date'     => @load.shipped_date_time,
              'ship_number'      => lv_ship_number,
              'orig_cons'        => pallet.consignment_note_number,
              'tran_date'        => Date.today,
              'season'           => pallet.cart_season,	      
              'revision'         => @load_o.revision_number,
              'channel'          => pallet.carton_org == 'TI' ? 'L' : 'E',
              'tran_time'        => Time.now,
              'Stack_variance'   => stack_variance,
	      'Mass' => pallet.mass,
	      'Inspec_date' => Time.parse(pallet.inspec_date)  
              }, 'OP')

      oc_rec.add_child op_rec
      @op_count += 1
    end

    # ---------
    # BT record
    # ---------
    trailer = HierarchicalRecordSet.new({'trailer'            => 'BT',
                                         'network_address'    => 31,
                                         'batch_number'       => @out_seq,
                                         'record_count'       => 2 + @oh_count + @ol_count +
                                                                     @oc_count + @ok_count +
                                                                     @op_count,
                                         'oh_count'           => @oh_count,
                                         'ol_count'           => @ol_count,
                                         'oc_count'           => @oc_count,
                                         'ok_count'           => @ok_count,
                                         'op_count'           => @op_count,
                                         'total_carton_count' => @total_carton_count,
                                         'total_pallet_count' => @total_pallet_count
                                        }, 'BT')
    rec_set.add_child trailer
    rec_set
  end

  # Post Processing:
  #
  # The Paltrack spec has two OL records following each other - one representing the "from" and one the "to"
  # truck location. Here these have been defined as LF and LT. This method converts the LF and LT
  # records back to OL records.
  def post_process(doc)


    doc.gsub(/^L[F|T]/, 'OL')
  end

end
