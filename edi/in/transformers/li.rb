class Li   < DocEventHandlers

  # Unpack the LH record. Create Order, OrderCustomerDetail, Load and LoadOrder.
  def map_header(record, command)

    # These rules are presently specific to TI (Tru-Cape) only.
    # If an LI flow comes from another organisation stop and report.
    if record.fields['organization'] != 'TI'
      raise EdiInError, "LI EDI process expects data from organization \"TI\" (Tru-Cape) only. Received: \"#{record.fields['organization']}\""
    end

    # Behaviour is very different if the order is marked for deletion.
    for_delete = record.fields['revision'] == '9'

    # If this is not the first order/load in the flow, write the total required qty to the previous order/load.
    prev_order_for_deletion = false
    if @order_id
      old_order = Order.find(@order_id)
      prev_order_for_deletion = old_order.to_be_deleted
      unless prev_order_for_deletion
        old_order.required_quantity     = @total_required_qty
        old_order.customer_memo_pad     = @memo ||= nil
        old_order.customer_order_number = @customer_order_number ||= nil
        old_order.save!
      end
      @memo                  = nil
      @customer_order_numbe  = nil
    end
    unless prev_order_for_deletion
      if @load_id
        old_load= Load.find(@load_id)
        old_load.required_quantity = @total_required_qty
        old_load.save!
      end
    end
    @total_required_qty = 0.0

    # If the order should be deleted, find it and set its status appropriately.
    if for_delete
      orders = Order.find_by_sql(["select orders.*
                from order_customer_details
                join orders on orders.id = order_customer_details.order_id
                where order_customer_details.customer_order_number = ?
                and orders.order_status <> 'SHIPPED'
                and orders.edi_li_filename LIKE 'LIETI%'
                LIMIT 1", record.fields['order_number']])
      if orders.empty?
        raise EdiInError, "Cannot find order for deletion with customer_order_number \"#{record.fields['order_number']}\", order_status <> 'SHIPPED' and edi_li_filename LIKE 'LIETI%'."
      end

      order                  = orders.first
      order.order_status     = Order::STATUS_DELETION_RECVD
      order.save!
      @order_id              = order.id
      @load_id               = nil
      @load_order_id         = nil
      @customer_order_number = nil
      return
    end

    # Create the Order record:
    # ---
    order = Order.new
    order.order_number = MesControlFile.next_seq_web(MesControlFile::ORDER).to_s
    order.order_date   = Date.today
    #order_type = OrderType.find_by_order_type_code( record.fields['destination_type'] )
    order_type = OrderType.find_by_order_type_code( 'DP' )
    if order_type.nil?
      raise EdiInError, "No order type record for order type code \"#{record.fields['destination_type']}\""
    else
      order.order_type_id = order_type.id
    end
    #for_depot = record.fields['destination_type'] == 'DP' # Depot ('CU' == Customer)

    #depot = Depot.find_by_depot_code( record.fields['destination_code'] )
    depot = Depot.find_by_depot_code( 'ETI' )
    if depot.nil?
      raise EdiInError, "No depot record for depot code \"ETI\""
    else
      order.depot_id   = depot.id
      order.depot_code = 'ETI'
      order.depot_code = 'B49' if record.fields['destination_code'] == 'TRUJHB'
    end

    order.customer_party_role_id  = Party.get_party_role_id_for record.fields['organization'], 'CUSTOMER'
    order.consignee_party_role_id = Party.get_party_role_id_for '100007', 'TRADING PARTNER' # Hard-coded Consignee! (SPECIFIC to TruCape)
    order.edi_li_filename         = EdiHelper.edi_in_process_file
    order.is_export               = record.fields['channel'] != 'L'
    order.line_of_business_code   = 'carton sales'
    order.order_status            = Order::ORDER_CREATED

    # Virtual attributes that will be set on the order_customer_detail (auto-created by order.after_save):
    @customer_order_number      = record.fields['order_number']
    order.customer_order_number = record.fields['order_number']
    order.customer_memo_pad     = @memo ||= nil

    order.save!
    order.set_status(Order::ORDER_CREATED)

    # Create the Load record:
    # ---
    ld = Load.new
    ld.load_number = MesControlFile.next_seq_web(MesControlFile::LOAD)
    ld.load_status = 'load_created'
    ld.save!

    # Create the LoadOrder record:
    # ---
    load_order           = LoadOrder.new
    load_order.load      = ld
    load_order.order     = order
    load_order.date_time = Time.now
    load_order.save!

    # Store variables:
    # ---
    @order_id       = order.id
    @load_id        = ld.id
    @load_order_id  = load_order.id

  end

  # Unpack the DH records. Build up the memo variable (for use in the OrderCustomerDetail) from the Detail Header records.
  # (DH records are generated from LD records that have all Xs in the location_code field).
  def map_detail_header(record, command)
    if record.fields['memo'].strip.length > 0
      if @memo
        @memo += "\n" + record.fields['memo'].strip 
      else
        @memo = record.fields['memo'].strip 
      end
    end
  end

  # Unpack the DT records. Build up the memo variable (for use in the OrderCustomerDetail) from the Detail Trailer records.
  # (DT records are generated from LD records that have all Xs in the location_code field and appear after the real LD records).
  def map_detail_trailer(record, command)
    if record.fields['memo'].strip.length > 0
      if @memo
        @memo += "\n" + record.fields['memo'].strip 
      else
        @memo = record.fields['memo'].strip 
      end
    end
  end

  # Unpack the LD records. Create OrderProduct and LoadDetail.
  def map_detail(record, command)

    for_delete = record.fields['revision'] == '9'
    return if for_delete # If an order is marked for deletion there is nothing to do for the detail.

    @total_required_qty += record.fields['required_quantity']

    order = Order.find(@order_id)

    # Create the OrderProduct record:
    # ---
    order_product = OrderProduct.new
    order_product.import(record.fields)

    order_product.order        = order
    #order_product.order_number = order.order_number
    # Make up the old finished goods code from
    # COMMODITY VARIETY BRAND PACK_TYPE and COUNT (with one space between each).
    order_product.old_fg_code  = "#{record.fields['commodity_code']} #{record.fields['marketing_variety_code']} " +
                                       "#{record.fields['brand_code']} #{record.fields['old_pack_code']} #{record.fields['size_ref']}"
    # Make up the season code from YEAR COMMODITY_CODE (with an underscore between them).
    order_product.season_code  = "#{Date.today.year}" #{record.fields['commodity_code']}"

    # Get the price per kg from the first matching item_pack_product:
    extended_fg = ExtendedFg.find(:first, :conditions => ['old_fg_code = ?', order_product.old_fg_code])
    if extended_fg.nil?
      raise EdiInError, "No Extended Fg for old_fg_code \"#{order_product.old_fg_code}\""
    end
    fg_product = FgProduct.find(:first, :conditions => ['fg_product_code = ?', extended_fg.fg_code])
    if fg_product.nil?
      raise EdiInError, "No FgProduct for extended_fg.fg_code \"#{extended_fg.fg_code}\""
    end
    item_pack_product = ItemPackProduct.find(:first, :conditions => ['item_pack_product_code = ?', fg_product.item_pack_product_code])
    if item_pack_product.nil?
      raise EdiInError, "No ItemPackProduct for fg_product.item_pack_product_code \"#{fg_product.item_pack_product_code}\""
    end
    #order_product.price = item_pack_product.price_per_kg

    # mapped fields handled via import:
    # order_product.required_quantity      = record.fields['instruction_quantity']
    # order_product.marketing_org          = record.fields['organization']
    # order_product.commodity_code         = record.fields['commodity']
    # order_product.marketing_variety_code = record.fields['variety']
    # order_product.old_pack_code          = record.fields['pack']
    # order_product.brand_code             = record.fields['mark']
    # order_product.size_ref               = record.fields['low_count']
    # order_product.grade_code             = record.fields['grade']
    # order_product.target_market_code     = record.fields['target_market']
    # order_product.inventory_code         = record.fields['inventory_code']
    # order_product.sequence_number        = record.fields['sequence_number']
    tm_rec = TargetMarket.find_by_target_market_name(record.fields['target_market_code'])
    inv_rec =   InventoryCode.find_by_inventory_code(record.fields['inventory_code'])

    order_product.target_market_code = tm_rec.target_market_code
    order_product.inventory_code = inv_rec.inventory_code + "_"  + inv_rec.inventory_name

    order_product.save!

    # Create the LoadDetail record:
    # ---
    load_detail = LoadDetail.new
    load_detail.import(order_product.attributes, ['id'])
    load_detail.order_product = order_product
    load_detail.load_order_id = @load_order_id
    load_detail.load_id       = @load_id
    load_detail.save!

  end

  # After the EDI doc has been fully transforemd, write the
  # total required quantity back to the last (or only) Order and Load.
  def doc_transformed(root)
    prev_order_for_deletion = false
    if @order_id
      old_order = Order.find(@order_id)
      prev_order_for_deletion = old_order.to_be_deleted
      unless prev_order_for_deletion
        old_order.required_quantity = @total_required_qty
        old_order.customer_memo_pad = @memo ||= nil
        old_order.customer_order_number = @customer_order_number ||= nil
        old_order.save!
      end
      @memo                  = nil
      @customer_order_numbe  = nil
    end

    unless prev_order_for_deletion
      if @load_id
        old_load= Load.find(@load_id)
        old_load.required_quantity = @total_required_qty
        old_load.save!
      end
    end
  end
 

end

