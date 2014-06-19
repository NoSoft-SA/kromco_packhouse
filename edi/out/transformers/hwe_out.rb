# Hansa World Enterprise (HWE).
class HweOut < CsvOutTransformer

  # Override this method - no need for a sequence number.
  def make_next_seq_no
    @out_seq = 1
    @formatted_seq = '001'
  end

  # Override this method from OutTransformer - filename is built up differently.
  def make_file_name(proposal, type='paltrack')
    @filename = "item_export_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
  end

  # Create a HierarchicalRecordSet from the EdiOutProposal record.
  #
  # The proposal's +record_map+ attribute contains the organisation code.
  #    CSV column headings  -> BH
  #    Extended FG records  -> HWE
  def create_doc_records(proposal)

    EdiHelper.transform_log.write "Transforming Hansa World Enterprise (HWE).."

    # ---------
    # BH record (heading)
    # ---------
    # Headings are provided by the schema's defaults. No need to set values here.
    rec_set = HierarchicalRecordSet.new({}, 'BH')

    # ----------
    # HWE record
    # ----------
    extended_fgs = ExtendedFg.find(:all,
    :select => '
      extended_fgs.extended_fg_code,
      extended_fgs.grade_code,
      extended_fgs.marketing_org_code,
      extended_fgs.old_fg_code,
      extended_fgs.tu_nett_mass,
      extended_fgs.units_per_carton,
      fg_products.carton_pack_product_code,
      fg_products.unit_pack_product_code,
      item_pack_products.actual_count,
      item_pack_products.basic_pack_code,
      item_pack_products.cosmetic_code_name,
      item_pack_products.marketing_variety_code,
      item_pack_products.product_class_code,
      item_pack_products.size_ref,
      carton_pack_styles.description carton_pack_style_description,
      commodities.commodity_description_long,
      marketing_varieties.marketing_variety_description,
      fg_marks.ri_mark_code,
      fg_marks.ru_mark_code,
      fg_marks.tu_mark_code,
      basic_packs.short_code,
      unit_pack_products.nett_mass unit_pack_product_nett_mass,
      unit_pack_product_types.description unit_pack_product_type_description',

    :joins => '
      INNER JOIN fg_products ON fg_products.fg_product_code = extended_fgs.fg_code
      INNER JOIN item_pack_products ON (item_pack_products.item_pack_product_code = fg_products.item_pack_product_code
           AND item_pack_products.id = fg_products.item_pack_product_id)
      INNER JOIN carton_pack_products ON (carton_pack_products.carton_pack_product_code = fg_products.carton_pack_product_code
           AND carton_pack_products.id = fg_products.carton_pack_product_id)
      INNER JOIN carton_pack_styles ON (carton_pack_styles.carton_pack_style_code = carton_pack_products.carton_pack_style_code
           AND carton_pack_styles.id = carton_pack_products.carton_pack_style_id)
      INNER JOIN commodities ON commodities.commodity_code = extended_fgs.commodity_code
      INNER JOIN marketing_varieties ON (marketing_varieties.marketing_variety_code = item_pack_products.marketing_variety_code
           AND marketing_varieties.id = item_pack_products.marketing_variety_id)
      INNER JOIN fg_marks ON fg_marks.fg_mark_code = extended_fgs.fg_mark_code
      INNER JOIN basic_packs ON basic_packs.basic_pack_code = item_pack_products.basic_pack_code
      INNER JOIN unit_pack_products ON (unit_pack_products.unit_pack_product_code = fg_products.unit_pack_product_code
           AND unit_pack_products.id = fg_products.unit_pack_product_id)
      INNER JOIN unit_pack_product_types ON (unit_pack_product_types.type_code = unit_pack_products.type_code
           AND unit_pack_product_types.id = unit_pack_products.unit_pack_product_type_id)',

    :conditions => ['extended_fgs.created_on > ? or  extended_fgs.updated_on > ?', 1.day.ago, 1.day.ago])
    #:conditions => ['extended_fgs.id > ? AND  extended_fgs.id < ?', 59,70])

    extended_fgs.each do |record|

      varsize           = record.size_ref == 'NOS' ? record.actual_count : record.size_ref
      unit_pp_nett_mass = record.unit_pack_product_nett_mass.nil? ? '' : record.unit_pack_product_nett_mass << 'Kg'

      innerpackdesc = case record.unit_pack_product_type_description
      when 'Tray'
        '(Tray)'
      when 'Bag'
        "(#{record.units_per_carton}x#{unit_pp_nett_mass}Bag)"
      else
        ' '
      end

      description    = [record.commodity_description_long,
                       record.marketing_variety_description,
                       record.tu_mark_code,
                       record.short_code,
                       record.carton_pack_style_description,
                       varsize,
                       record.product_class_code,
                       record.grade_code,
                       record.cosmetic_code_name,
                       innerpackdesc,
                       record.tu_nett_mass].join(' ') << ' Kg'

      classification = ['FG',
                        record.marketing_variety_code,
                        record.product_class_code,
                        record.grade_code,
                        record.actual_count,
                        record.basic_pack_code,
                        record.cosmetic_code_name,
                        record.size_ref,
                        record.units_per_carton,
                        record.unit_pack_product_code,
                        record.carton_pack_product_code,
                        record.marketing_org_code,
                        record.ri_mark_code,
                        record.ru_mark_code,
                        record.tu_mark_code].join(',')

      hwe_rec = HierarchicalRecordSet.new({
                'fg_item_description'  => description,
                'fg_item_code'         => record.extended_fg_code,
                'alternate_code'       => record.old_fg_code,
                'classification'       => classification
                }, 'HWE')

      rec_set.add_child hwe_rec

    end

    rec_set
  end
end
