# Hansa Carton Sales (HCS).
class HcsOut < CsvOutTransformer

  # Override this method - no need for a sequence number.
  def make_next_seq_no
    @out_seq = 1
    @formatted_seq = '001'
  end

  # Override this method from OutTransformer - filename is built up differently.
  def make_file_name(proposal, type='paltrack')
    @filename = "sales_export_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
  end

  # Create a HierarchicalRecordSet from the EdiOutProposal record.
  #
  # The proposal's +record_map+ attribute contains a load_order model.
  #    CSV column headings        -> BH
  #    Load Order Carton records  -> HCS
  def create_doc_records(proposal)

    #@field_delimiter = ',' # Delimiter for csv.
    EdiHelper.transform_log.write "Transforming Hansa Carton Sales (HCS) for LoadOrder #{@record_map['id']}.."

    # Get the LoadOrder
    begin
      load_order = LoadOrder.find(@record_map['id'])
    rescue ActiveRecord::RecordNotFound => error
      raise EdiOutError, "#{@err_prefix} - LoadOrder with id #{@record_map['id']} not found."
    end

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
    trading_partner = PartiesRole.find(order.consignee_party_role_id).party_name

    load_voyage = LoadVoyage.find_by_load_id(@record_map['load_id'])
#    raise EdiOutError, "#{@err_prefix} - LoadVoyage with load_id #{@record_map['load_id']} not found." if load_voyage.nil?
    if load_voyage.nil?
      port_code = nil
    else
      port = VoyagePort.find(:first,
                             :select => 'voyage_ports.*',
                             :joins => 'join load_voyage_ports on load_voyage_ports.voyage_port_id = voyage_ports.id
                                        join voyage_port_types on voyage_port_types.id = voyage_ports.voyage_port_type_id',
                             :conditions => ['load_voyage_ports.load_voyage_id = ? and UPPER(voyage_port_types.voyage_port_type_code) = ?',
                                             load_voyage.id, 'ARRIVAL'])
      raise EdiOutError, "#{@err_prefix} - No VoyagePort for LoadVoyage with load_id #{@record_map['load_id']}." if port.nil?
      port_code = port.port_code
    end

    # ---------
    # BH record (heading)
    # ---------
    # Headings are provided by the schema's defaults. No need to set values here.
    rec_set = HierarchicalRecordSet.new({}, 'BH')

    # ----------
    # HCS record
    # ----------

    load_orders = LoadOrder.find(:all,

:select => 'cartons.carton_number, pallets.pallet_number, cartons.target_market_code, cartons.farm_code, pallets.consignment_note_number,
load_orders.dispatch_consignment_number, cartons.carton_fruit_nett_mass, cartons.track_indicator_code, load_containers.container_code,
voyages.vessel_code, voyages.voyage_code, vessels.vessel_registration_number, cartons.season_code, cartons.organization_code,
cartons.sell_by_code, load_details.id load_detail_id, cartons.grade_code, cartons.commodity_code, farms.farm_group_code,
production_runs.parent_run_code, pallets.is_depot_pallet ,extended_fgs.id, fg_marks.ri_mark_code, fg_marks.ru_mark_code,
fg_marks.fg_mark_code, fg_marks.tu_mark_code, extended_fgs.units_per_carton, extended_fgs.tu_gross_mass, extended_fgs.tu_nett_mass,
extended_fgs.ri_diameter_range, unit_pack_products.unit_pack_product_code, carton_pack_products.carton_pack_product_code,
item_pack_products.marketing_variety_code, extended_fgs.ri_weight_range, extended_fgs.extended_fg_code,
extended_fgs.ru_description AS extended_fg_ru_description, extended_fgs.old_fg_code, extended_fgs.marketing_org_code,
extended_fgs.fg_code, treatments.treatment_type_code, treatments.description AS treatment_description,
carton_pack_styles.carton_pack_style_code, carton_pack_styles.description AS carton_pack_style_description,
basic_packs.basic_pack_code, basic_packs.short_code, basic_packs.length, basic_packs.width AS basic_pack_width,
basic_packs.height AS basic_pack_height, carton_pack_types.type_code AS carton_pack_type_type_code,
carton_pack_types.description AS carton_pack_type_description, carton_pack_products.height AS carton_pack_products_height,
carton_pack_products.type_code AS carton_pack_product_type_code, unit_pack_product_types.type_code AS unit_pack_product_type_type_code,
unit_pack_product_types.description AS unit_pack_product_type_description, unit_pack_product_subtypes.subtype_code,
unit_pack_product_subtypes.description AS unit_pack_product_subtype_description,
unit_pack_products.nett_mass AS unit_pack_product_nett_mass, commodities.commodity_code, commodities.commodity_description_long,
commodities.commodity_description_short, marketing_varieties.marketing_variety_description, item_pack_products.grade_code,
item_pack_products.product_class_code, item_pack_products.standard_size_count_value, item_pack_products.size_ref,
item_pack_products.cosmetic_code_name, item_pack_products.treatment_code, item_pack_products.actual_count,
extended_fgs.created_on, extended_fgs.updated_on,rmt_setups.variety_code,incoterms.incoterm_code,currencies.currency_code, order_products.price_per_carton, loads.shipped_date_time,cartons.puc',

:joins => 'INNER JOIN load_details ON (load_orders.load_id = load_details.load_id)
INNER JOIN pallets ON (load_details.id = pallets.load_detail_id)
INNER JOIN cartons ON (pallets.id = cartons.pallet_id)
INNER JOIN production_runs ON cartons.production_run_code = production_runs.production_run_code
INNER JOIN production_schedules ON production_runs.production_schedule_id = production_schedules.id
INNER JOIN rmt_setups ON production_schedules.id = rmt_setups.production_schedule_id
INNER JOIN extended_fgs ON (cartons.extended_fg_code = extended_fgs.extended_fg_code)
INNER JOIN fg_products ON (extended_fgs.fg_code = fg_products.fg_product_code)
INNER JOIN item_pack_products ON (fg_products.item_pack_product_code = item_pack_products.item_pack_product_code)
LEFT JOIN order_products ON (item_pack_products.item_pack_product_code = order_products.item_pack_product_code) and order_products.old_fg_code = extended_fgs.old_fg_code and order_products.order_id=load_details.order_id
INNER JOIN unit_pack_products ON (fg_products.unit_pack_product_code = unit_pack_products.unit_pack_product_code)
INNER JOIN carton_pack_products ON (fg_products.carton_pack_product_code = carton_pack_products.carton_pack_product_code)
INNER JOIN fg_marks ON (extended_fgs.fg_mark_code = fg_marks.fg_mark_code)
INNER JOIN treatments ON (item_pack_products.treatment_id = treatments.id)
INNER JOIN carton_pack_styles ON (carton_pack_products.carton_pack_style_code = carton_pack_styles.carton_pack_style_code)
INNER JOIN basic_packs ON (carton_pack_products.basic_pack_code = basic_packs.basic_pack_code)
INNER JOIN commodities ON (item_pack_products.commodity_code = commodities.commodity_code)
INNER JOIN marketing_varieties ON (item_pack_products.marketing_variety_code = marketing_varieties.marketing_variety_code)
AND (item_pack_products.marketing_variety_id = marketing_varieties.id)
INNER JOIN carton_pack_types ON (carton_pack_products.type_code = carton_pack_types.type_code)
AND (carton_pack_products.carton_pack_type_id = carton_pack_types.id)
INNER JOIN farms ON (cartons.farm_code = farms.farm_code)
LEFT OUTER JOIN load_containers ON (load_orders.load_id = load_containers.load_id)
LEFT OUTER JOIN load_voyages ON (load_orders.load_id = load_voyages.load_id)
INNER JOIN orders ON (load_orders.order_id = orders.id)
LEFT OUTER JOIN currencies ON (orders.currency_id = currencies.id)
LEFT OUTER JOIN incoterms ON (orders.incoterm_id = incoterms.id)
LEFT OUTER JOIN voyages ON (load_voyages.voyage_id = voyages.id)
LEFT OUTER JOIN vessels ON (vessels.id = voyages.vessel_id)
INNER JOIN unit_pack_product_types ON (unit_pack_products.type_code = unit_pack_product_types.type_code)
INNER JOIN unit_pack_product_subtypes ON (unit_pack_products.subtype_code = unit_pack_product_subtypes.subtype_code)
LEFT JOIN loads ON loads.id = load_details.load_id',

:conditions => ['load_orders.id = ?', @record_map['id']],

:order => 'extended_fgs.extended_fg_code,cartons.puc,pallets.pallet_number desc'
    )


    load_orders.each do |record|
      #NAE 20160404 replace first digit of season with first digit of calender year
      #ucr = "#{record.season_code[-1,1]}ZA01507472C#{trading_partner}"
      ucr = "#{record.shipped_date_time[3,1]}ZA01507472CDEL#{order.order_number}S"

      count_array = LoadDetail.find_by_sql(['select count(cartons.id) FROM load_details join pallets on pallets.load_detail_id = load_details.id join cartons on cartons.pallet_id = pallets.id WHERE (load_details.id = ?)', record.load_detail_id])
      no_cartons = count_array[0].count
      #sell_by = no_cartons == 1 ? 'ndc' : record.sell_by_code
      #sell_by = record.sell_by_code == '-' ? 'ndc' : record.sell_by_code
      sell_by = record.sell_by_code == '-' ? 'ndc' : 'dc'

      line_type = record.is_depot_pallet == 't' ? 'Class1' : record.parent_run_code.nil? ? 'Class1': 'Class2'

      if record.is_depot_pallet == 't'
        account_code  = 'DEPOT'
        # intake_header = IntakeHeadersProduction.find(:first,
        #                 :conditions => ['consignment_note_number = ?',
        #                                 record.consignment_note_number])
      else
        intake_header = IntakeHeadersProduction.find(:first,
                        :conditions => ['consignment_note_number = ?',
                                        record.consignment_note_number])
        account_code  = intake_header.account_code
      end

      hcs_rec = HierarchicalRecordSet.new({
                'carton_id'                             => record.carton_number,
                'pallet_id'                             => record.pallet_number,
                'tradingpartner'                        => trading_partner,
                'extended_fg_code'                      => record.extended_fg_code,
                'target_market'                         => record.target_market_code,
                'load_no'                               => ld.load_number,
                'grower_id'                             => record.farm_code,
                'intake_consignment_id'                 => record.consignment_note_number,
                'exit_reference'                        => record.dispatch_consignment_number,
                'weight'                                => record.carton_fruit_nett_mass,
                'raw_material_type'                     => record.track_indicator_code,
                'remarks'                               => order.order_customer_detail.customer_order_number,
                'container'                             => record.container_code,
                'vessel_name'                           => record.vessel_code,
                'voyage_no'                             => record.voyage_code,
                'customerpono'                          => order.order_customer_detail.customer_order_number,
                'ucr'                                   => ucr,
                'sell_by_code'                          => sell_by,
                'fg_code'                               => record.fg_code,
                'fg_mark_code'                          => record.fg_mark_code,
                'units_per_carton'                      => record.units_per_carton,
                'tu_gross_mass'                         => record.tu_gross_mass,
                'tu_nett_mass'                          => record.tu_nett_mass,
                'ri_diameter_range'                     => record.ri_diameter_range,
                'ri_weight_range'                       => record.ri_weight_range,
                'ru_description'                        => record.extended_fg_ru_description,
                'old_fg_code'                           => record.old_fg_code,
                'marketing_org_code'                    => record.organization_code,
                'grade_code'                            => record.grade_code,
                'standard_size_count_value'             => record.standard_size_count_value,
                'commodity_code'                        => record.commodity_code,
                'ri_mark_code'                          => record.ri_mark_code,
                'ru_mark_code'                          => record.ru_mark_code,
                'tu_mark_code'                          => record.tu_mark_code,
                'unit_pack_product_code'                => record.unit_pack_product_code,
                'carton_pack_product_code'              => record.carton_pack_product_code,
                'marketing_variety_code'                => record.marketing_variety_code,
                'extended_fg_ru_description'            => record.extended_fg_ru_description,
                'treatment_type_code'                   => record.treatment_type_code,
                'treatment_description'                 => record.treatment_description,
                'carton_pack_style_code'                => record.carton_pack_style_code,
                'carton_pack_style_description'         => record.carton_pack_style_description,
                'basic_pack_code'                       => record.basic_pack_code,
                'short_code'                            => record.short_code,
                'length'                                => record.length,
                'basic_pack_width'                      => record.basic_pack_width,
                'basic_pack_height'                     => record.basic_pack_height,
                'carton_pack_type_type_code'            => record.carton_pack_type_type_code,
                'carton_pack_type_description'          => record.carton_pack_type_description,
                'carton_pack_products_height'           => record.carton_pack_products_height,
                'carton_pack_product_type_code'         => record.carton_pack_product_type_code,
                'unit_pack_product_type_type_code'      => record.unit_pack_product_type_type_code,
                'unit_pack_product_type_description'    => record.unit_pack_product_type_description,
                'subtype_code'                          => record.subtype_code,
                'unit_pack_product_subtype_description' => record.unit_pack_product_subtype_description,
                'unit_pack_product_nett_mass'           => record.unit_pack_product_nett_mass,
                'commodity_description_long'            => record.commodity_description_long,
                'commodity_description_short'           => record.commodity_description_short,
                'marketing_variety_description'         => record.marketing_variety_description,
                'product_class_code'                    => record.product_class_code,
                'size_ref'                              => record.size_ref,
                'cosmetic_code_name'                    => record.cosmetic_code_name,
                'treatment_code'                        => record.treatment_code,
                'actual_count'                          => record.actual_count,
                'hansaworld'                            => trading_partner,
                'account'                               => account_code,
                'farmsubgroup'                          => record.farm_group_code,
                'farmgroup'                             => record.farm_group_code,
                'depot_indicator'                       => record.is_depot_pallet == 't' ? 'Depot' : 'Packed_at_Kromco',
                'season'                                => record.season_code,
                'linetypedesc'                          => line_type,
                'port_of_destination'                   => port_code,
                'cultivar'                                => record.variety_code,
                'incoterm'                              => record.incoterm_code,
                'currency'                              => record.currency_code,
                'carton_price'                          => record.price_per_carton
		}, 'HCS')
      rec_set.add_child hcs_rec
    end

    rec_set
  end
end
