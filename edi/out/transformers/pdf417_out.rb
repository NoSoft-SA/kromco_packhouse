class Pdf417Out < TextOutTransformer

  # Create a HierarchicalRecordSet from the EdiOutProposal record.
  #
  # The proposal's +record_map+ attribute contains the attributes
  # of an IntakeHeadersProduction model.
  #    IntakeHeadersProduction     -> IN
  #    `-- Gtin                    -> G
  #        `-- Pallet              -> P
  #            `-- Pallet sequence -> S
  def create_doc_records( proposal )

    EdiHelper.transform_log.write "Transforming PDF417 (PDF417) for IntakeHeadersProduction #{@record_map['id']}.."

    # Get the Load
    begin
      intake_headers_production = IntakeHeadersProduction.find(@record_map['id'])
    rescue ActiveRecord::RecordNotFound => error
      raise EdiOutError, "#{@err_prefix} - IntakeHeadersProduction with id #{@record_map['id']} not found."
    end

    pallet = Pallet.find(:first,
                         :conditions => ['pallet_number = ?',
                           intake_headers_production.representative_pallet_number] )
    raise EdiOutError, "#{@err_prefix} - No pallets for IntakeHeadersProduction with representative_pallet_number: #{intake_headers_production.representative_pallet_number}." if pallet.nil?
    carton = Carton.find(:first,
                         :conditions => ['carton_number = ?',
                           intake_headers_production.representative_carton_number] )
    raise EdiOutError, "#{@err_prefix} - No cartons for IntakeHeadersProduction with representative_carton_number: #{intake_headers_production.representative_carton_number}." if carton.nil?

    ppecb_inspection = pallet.ppecb_inspection

    # sum of all pallets.carton_quantity_actual on iph
    carton_quantity = Pallet.sum('carton_quantity_actual',
                                 :conditions => ['consignment_note_number = ?',
                                   intake_headers_production.consignment_note_number])

    # Sum of all pallets.carton_quantity_actual / cpp
    # NB This must be cast to float:
    pallet_quantity = Pallet.sum('cast(carton_quantity_actual as float) / cast(cpp as float)',
                                 :conditions => ['consignment_note_number = ?',
                                   intake_headers_production.consignment_note_number]).to_f

    pfp         = PalletFormatProduct.find(:first, :conditions => ['id = ?', pallet.pallet_format_product_id])
    raise EdiOutError, "#{@err_prefix} - No PalletFormatProduct code: #{pallet.pallet_format_product_id}." if pfp.nil?
    
    pallet_base = PalletBase.find(:first, :conditions => ['pallet_base_code = ?', pfp.pallet_base_code])
    raise EdiOutError, "#{@err_prefix} - No pallet_base code: #{pfp.pallet_base_code}." if pallet_base.nil?

    # ---------
    # I record
    # ---------

    rec_set = HierarchicalRecordSet.new({'organization_code'       => intake_headers_production.organization_code,
                                         'season'                  => pallet.season_code,
                                         'account_code'            => carton.account_code,
                                         'pack_order_number'       => intake_headers_production.order_number,
                                         'qty_cartons'             => carton_quantity,
                                         'qty_pallets'             => pallet_quantity,
                                         'consignment_note_number' => intake_headers_production.consignment_note_number,
                                         'consignment_date'        => intake_headers_production.created_on, # || Time.now,
                                         'pallet_base_code'        => pallet_base.edi_out_pallet_base,
                                         'inspection_date'         => ppecb_inspection.created_at,
                                         'inspection_point'        => intake_headers_production.inspection_point,
                                #NOTE: The paltrack spec calls for zeroes in this field if it is empty and so the schema had format="ZEROES" for the field.
                                #      However Kromco sometimes has a (legitimate) string value in this field, so the format has been removed.
                                #      A blank value is set to "0000", but a numeric value that is less than 4 characters
                                #      will not be correct => '102' -> "102 " instead of "0102" - so the data in the table must have leading zeroes in this case..
                                         'inspector_number'        => intake_headers_production.inspector_number.blank? ? '0000' : intake_headers_production.inspector_number
                                        }, 'I')

    # --------
    # G record
    # --------
    pallets = Pallet.find(:all, :select => 'cartons.gtin,pallets.pallet_format_product_id, cartons.target_market_code, target_markets.target_market_region_code, target_markets.target_market_country_code, cartons.pick_reference,
pallets.pt_product_characteristics, pallets.pallet_number, pallets.cpp, cartons.sell_by_code, cartons.puc,
count(cartons.id) no_cartons',
                          :joins => 'join cartons on cartons.pallet_id = pallets.id join target_markets on target_markets.target_market_code = cartons.target_market_code',
                          :conditions => ['pallets.consignment_note_number = ?', intake_headers_production.consignment_note_number],
                          :group => 'cartons.gtin, cartons.target_market_code, target_markets.target_market_region_code,pallets.pallet_format_product_id, target_markets.target_market_country_code, cartons.pick_reference,
pallets.pt_product_characteristics, pallets.pallet_number, pallets.cpp, cartons.sell_by_code, cartons.puc',
                          :order => 'cartons.gtin, cartons.target_market_code, cartons.pick_reference,
pallets.pt_product_characteristics, pallets.pallet_number, cartons.puc')

    gtins = pallets.map {|p| [p.gtin,
                              trimmed_target_market_code(p.target_market_code),
                              p.target_market_region_code,
                              p.target_market_country_code,
                              p.pick_reference, trimmed_prodchar(p.pt_product_characteristics)]}.uniq
    raise EdiOutError, "#{@err_prefix} - Consignment Note '#{intake_headers_production.consignment_note_number}' has cartons with blank Gtin Numbers." if gtins.any? {|a| a[0].nil? }

    gtin_recs = {}
    pallets.each do |pallet|
      gtin_arr = [pallet.gtin,
                  trimmed_target_market_code(pallet.target_market_code),
                  pallet.target_market_region_code,
                  pallet.target_market_country_code,
                  pallet.pick_reference,
                  trimmed_prodchar(pallet.pt_product_characteristics)]
      if gtin_recs[gtin_arr].nil?
        gtin_recs[gtin_arr] = []
        gtin_recs[gtin_arr] << pallet.no_cartons.to_i
        gtin_recs[gtin_arr] << pallet.no_cartons.to_i / pallet.cpp.to_f
      else
        gtin_recs[gtin_arr][0] += pallet.no_cartons.to_i
        gtin_recs[gtin_arr][1] = gtin_recs[gtin_arr][0] / pallet.cpp.to_f
      end
    end

    gtins.each do |gtin|
      g_rec = HierarchicalRecordSet.new({'gtin'                    => gtin[0],
                                         'target_market_name'      => gtin[1],
                                         'pick_reference'          => gtin[4],
                                         'product_characteristics' => gtin[5],
                                         'n_cartons'               => gtin_recs[gtin][0],
                                         'n_pallets'               => gtin_recs[gtin][1]
                                          }, 'G')
      rec_set.add_child g_rec

      prev_pallet = ''
      p_seq       = 0
      p_rec       = nil
      pallets.each do |p_pallet|
        gtin_key = [p_pallet.gtin,
                    trimmed_target_market_code(p_pallet.target_market_code),
                    p_pallet.target_market_region_code,
                    p_pallet.target_market_country_code,
                    p_pallet.pick_reference,
                    trimmed_prodchar(p_pallet.pt_product_characteristics)]
        next unless gtin_key == gtin

        # --------
        # P record
        # --------
        if prev_pallet != p_pallet.pallet_number
          p_rec = HierarchicalRecordSet.new({'depot_pallet_number' => p_pallet.pallet_number,
                                             'sell_by_code'        => p_pallet.sell_by_code,
                                             'pallet_base_code'    => p_pallet.edi_out_pallet_base,
                                              'mixed_pallet'       => p_pallet.mixed_pallet?
                                              }, 'P')
          g_rec.add_child p_rec
          p_seq = 0
        end
        prev_pallet = p_pallet.pallet_number

        # --------
        # S record
        # --------
        p_seq += 1
        s_rec = HierarchicalRecordSet.new({'pallet_sequence_number' => p_seq,
                                           'puc'                    => p_pallet.puc,
                                           #'batch_code'             => 'unknown',
                                           'seq_ctn_qty'            => p_pallet.no_cartons,
                                           'target_region'          => gtin[2],
                                           'target_country'         => gtin[3][0..1]
                                            }, 'S')
        p_rec.add_child s_rec
      end # p_pallet loop
    end # gtin loop
    rec_set
  end

  # Post Processing:
  #
  # The PDF417 string should be returned without newlines.
  def post_process(doc)
    doc.gsub("\n",'')
  end

private

  # Return the first two characters from +target_market_code+.
  def trimmed_target_market_code(target_market_code)
    target_market_code[0,2]
  end

  # Return the first two characters from +product_characteristics+ or +nil+.
  def trimmed_prodchar(pt_product_characteristics)
    pt_product_characteristics.nil? ? nil : pt_product_characteristics[0..2]
  end

end
