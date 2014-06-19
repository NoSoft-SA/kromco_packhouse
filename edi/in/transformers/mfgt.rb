# EDI in processor of GT (Product Codes) Masterfiles
class Mfgt < DocEventHandlers
  include EdiMasterfileProcessor

  # The fields that make this masterfile record unique 
  def masterfile_keys
    ['gtin', 'tranno']
  end

  # The ActiveRecord class name for this masterfile.
  def masterfile_klass
    MfProductCode
  end

  # Provides a hash of attribute names with the values to be used when the input record has a nil value.
  #
  # +date_end+ is set to a far-future date to ensure that comparisons to +date_end+ will always succeed.
  # +inv_code+ is set to 'UL' if not provided.
  def masterfile_defaults
    {'date_end' => Date.new(2090,1,1), 'inv_code' => 'UL'}
  end

  def handle_record(rec,todo)

     gtin = Gtin.find_by_gtin_code_and_transaction_number(rec.gtin,rec.tranno)
     gtin.destroy() if gtin

      if todo.upcase != 'D'
        gtin = Gtin.new
        gtin.gtin_code =  rec.gtin
        gtin.date_from =  rec.date_strt
        gtin.date_to = rec.date_end
        gtin.organization_code = rec.orgzn
        gtin.commodity_code = rec.commodity
        gtin.old_pack_code =  rec.pack
        gtin.grade_code = rec.grade
        gtin.mark_code = rec.mark
        gtin.inventory_code = rec.inv_code
        gtin.target_market_code = rec.targ_mkt

        gtin.transaction_number = rec.tranno
        gtin.marketing_variety_code =  rec.variety
        gtin.actual_count = rec.size_count

        gtin.brand_code = rec.mark
        gtin.create
      end

   end

end

