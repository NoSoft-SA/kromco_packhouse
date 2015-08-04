# Hansa Bin Sales (HBS).
class HbsOut < CsvOutTransformer

  # Override this method - no need for a sequence number.
  def make_next_seq_no
    @out_seq = 1
    @formatted_seq = '001'
  end

  # Override this method from OutTransformer - filename is built up differently.
  def make_file_name(proposal, type='paltrack')
    @filename = "bs_sales_export_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
  end

  # Create a HierarchicalRecordSet from the EdiOutProposal record.
  #
  # The proposal's +record_map+ attribute contains a load_order model.
  #    CSV column headings     -> BH
  #    Bin Order Load records  -> HBS
  def create_doc_records(proposal)

    #@field_delimiter = ',' # Delimiter for csv.
    EdiHelper.transform_log.write "Transforming Hansa Bin Sales (HBS) for BinOrderLoad #{@record_map['id']}.."

    # Get the BinOrderLoad
    begin
      bin_order_load = BinOrderLoad.find(@record_map['id'])
    rescue ActiveRecord::RecordNotFound => error
      raise EdiOutError, "#{@err_prefix} - BinOrderLoad with id #{@record_map['id']} not found."
    end

    # Get the BinLoad
    begin
      bin_load = BinLoad.find(@record_map['bin_load_id'])
    rescue ActiveRecord::RecordNotFound => error
      raise EdiOutError, "#{@err_prefix} - BinLoad with id #{@record_map['bin_load_id']} not found."
    end

    # Get the BinOrder
    begin
      bin_order = BinOrder.find(@record_map['bin_order_id'])
    rescue ActiveRecord::RecordNotFound => error
      raise EdiOutError, "#{@err_prefix} - BinOrder with id #{@record_map['bin_order_id']} not found."
    end
    trading_partner = PartiesRole.find(bin_order.trading_partner_party_role_id).party_name

    # Get the TransactionStatus
    begin
      transaction_status = TransactionStatus.find_by_object_id_and_status_code_and_status_type_code(@record_map['id'],'COMPLETE','bin_order_load')
    rescue ActiveRecord::RecordNotFound => error
      raise EdiOutError, "#{@err_prefix} - TransactionStatus with object_id #{@record_map['id']} not found."
    end

    # GET the matching bin_order and related parties here...

    # ---------
    # BH record (heading)
    # ---------
    # Headings are provided by the schema's defaults. No need to set values here.
    rec_set = HierarchicalRecordSet.new({}, 'BH')

    # ----------
    # HBS record
    # ----------

    bin_order_loads = BinOrderLoad.find(:all,
                                        :select => "bins.bin_number, bins.season_code,cast(bins.weight as dec(5,1)) as weight,
                                        product_classes.product_class_description AS product_class_code,
                                        rmt_products.commodity_code,bins.exit_reference_date_time,
                                        rmt_products.size_code,
                                        rmt_products.variety_code||'_'|| substring(rmt_varieties.rmt_variety_description from 1 for 11) AS variety_code,
                                        track_slms_indicators.track_slms_indicator_code,
                                        farms.farm_code, farms.farm_group_code, track_slms_indicators.track_slms_indicator_code||'_'||rmt_products.rmt_product_code as product_code",
      :joins => 'INNER JOIN bin_orders on bin_orders.id = bin_order_loads.bin_order_id
                 INNER JOIN bin_order_load_details on bin_order_load_details.bin_order_load_id = bin_order_loads.id
                 INNER JOIN bin_loads on bin_loads.id = bin_order_loads.bin_load_id
                 inner JOIN bins on bins.bin_order_load_detail_id = bin_order_load_details.id
                 LEFT OUTER JOIN farms on farms.id = bins.farm_id
                 LEFT OUTER JOIN rmt_products ON rmt_products.id = bins.rmt_product_id
                 LEFT OUTER JOIN public.product_classes ON public.rmt_products.product_class_code = public.product_classes.product_class_code
		       LEFT OUTER JOIN public.varieties ON public.rmt_products.variety_id = public.varieties.id
		       LEFT OUTER JOIN public.rmt_varieties ON public.rmt_varieties.id = public.varieties.rmt_variety_id
		       LEFT OUTER JOIN track_slms_indicators ON track_slms_indicators.id = bins.track_indicator1_id',
      :conditions => ['bin_order_loads.id = ?', @record_map['id']])

    bin_order_loads.each do |record|
      hbs_rec = HierarchicalRecordSet.new({
                'load_id'                   => bin_load.bin_load_number,
                'weight'                    => record.weight,
                'class'                     => record.product_class_code,
                'fruit_type'                => record.commodity_code,
                'bin_size'                  => record.size_code,
                'bin_id'                    => record.bin_number,
                'exit_reference'            => bin_load.bin_load_number,
                'exit_date'                 => transaction_status.created_on,
                'hansaworld_customer_code'  => trading_partner,
                'tradingpartner'            => trading_partner,
                'lineofbusiness'            => 'BINSALES',
                'current_raw_material_type' => record.track_slms_indicator_code,
                'cultivar'                  => record.variety_code,
                'qty'                       => 1,
                'season'                    => record.season_code[0,4],
                'farm_id'                   => record.farm_code,
                'farmsubgroup'              => record.farm_group_code,
                'product_code'              => record.product_code		
                }, 'HBS')
      rec_set.add_child hbs_rec
    end

    rec_set

  end

end
