# EDI in processor of GU (Gtin Codes) Masterfiles
class Mfgu < DocEventHandlers
  include EdiMasterfileProcessor

  # The fields that make this masterfile record unique 
  def masterfile_keys
    ['gtin', 'seq_no', 'target_market']
  end

  # The ActiveRecord class name for this masterfile.
  def masterfile_klass
    MfProductCodeTargetMarket
  end

  def handle_record(rec,todo)

     gtin_tms = GtinTargetMarket.find_all_by_gtin_code_and_target_market_code(rec.gtin,rec.target_market)
     gtin_tms.each do |gt|
       gt.destroy()
     end

      if todo.upcase != 'D'
        gtin_tm = GtinTargetMarket.new
        gtin_tm.gtin_code = rec.gtin
        gtin_rec = Gtin.find_by_gtin_code_and_transaction_number(rec.gtin,rec.seq_no)
        if gtin_rec.nil?
          error = "Skipped creation of GTIN_TARGET_MARKETS record - GTINS record is missing: code: '#{rec.gtin}', seq: #{rec.seq_no}. Was this MFGU processed before a required MFGT file maybe?"
          EdiHelper.transform_log.write error
          EdiHelper.edi_log.write error
        else
          gtin_tm.gtin_id = gtin_rec.id
          gtin_tm.target_market_code = rec.target_market
          gtin_tm.create
        end
      end

   end

end


