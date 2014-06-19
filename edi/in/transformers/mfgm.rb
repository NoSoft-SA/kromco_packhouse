# EDI in processor of GM (Gtin Codes) Masterfiles
# (This updates the same file as GU, but with very little data)
class Mfgm < DocEventHandlers
  include EdiMasterfileProcessor

  # The fields that make this masterfile record unique 
  def masterfile_keys
    ['gtin', 'seq_no', 'target_market']
  end

  # The ActiveRecord class name for this masterfile.
  def masterfile_klass
    MfProductCodeTargetMarket
  end
  # Provides a hash of attribute names with the values to be used when the input record has a nil value.
  #
  # +seq_no+ in the input file is blank, but should be treated as 1.
  def masterfile_defaults
    {'seq_no' => 1}
  end

end

