# Pallet Stock (PF).
class PfOut < TextOutTransformer

  # Create a HierarchicalRecordSet from the EdiOutProposal record.
  #
  # The proposal's +record_map+ attribute contains a load_order model.
  #    Batch Header               -> BH
  #    Pallet Stock records       -> PF
  #    Batch Trailer              -> BT
  def create_doc_records(proposal)

    EdiHelper.transform_log.write "Transforming Load Final (PF) for #{@record_map['organization_code']}.."

    # Get the Load
    begin
      ld    = Load.find(@record_map['load_id'])
    rescue ActiveRecord::RecordNotFound => error
      raise EdiOutError, "#{@err_prefix} - Load with id #{@record_map['load_id']} not found."
    end

    # Get the Order
    begin
      order = Order.find(@record_map['order_id'])
    rescue ActiveRecord::RecordNotFound => error
      raise EdiOutError, "#{@err_prefix} - Order with id #{@record_map['order_id']} not found."
    end

    order_no = order.order_customer_detail.customer_order_number

    pallet = LoadOrder.find_by_sql(['select pallets.account_code
FROM load_orders join load_details on load_details.load_order_id = load_orders.id
 join pallets on pallets.load_detail_id = load_details.id
where load_orders.id = ?  limit 1', @record_map['id']])
    raise EdiOutError, "#{@err_prefix} - No pallets found for LoadOrder with id #{@record_map['id']}." if pallet.empty?

    ld_ord = LoadOrder.find_by_sql(['select count(cartons.id) carton_qty
FROM load_orders join load_details on load_details.load_order_id = load_orders.id
 join pallets on pallets.load_detail_id = load_details.id
 join cartons on cartons.pallet_id = pallets.id
where load_orders.id = ?', @record_map['id']])
    carton_qty = ld_ord.first.carton_qty.to_i
    raise EdiOutError, "#{@err_prefix} - No cartons found for LoadOrder with id #{@record_map['id']}." if carton_qty == 0

    # ---------
    # BH record
    # ---------
    rec_set = HierarchicalRecordSet.new({'header'          => 'BH',
                                         'network_address' => 31,
                                         'batch_number'    => @out_seq,
                                         'create_date'     => Date.today,
                                         'create_time'     => Time.now
                                        }, 'BH')
    
    # ---------
    # PF record
    # ---------
    pf_rec = HierarchicalRecordSet.new({'order_no'   => order_no,
                                        'account'    => pallet.first.account_code,
                                        'load_no'    => ld.load_number,
                                        'carton_qty' => carton_qty
                                        }, 'PF')
    rec_set.add_child pf_rec

    # ---------
    # BT record
    # ---------
    trailer = HierarchicalRecordSet.new({'trailer'         => 'BT',
                                         'network_address' => 31,
                                         'batch_number'    => @out_seq
                                        }, 'BT')
    rec_set.add_child trailer
    rec_set
  end
end
