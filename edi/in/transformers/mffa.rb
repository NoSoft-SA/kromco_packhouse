# EDI in processor of FA (Farms) Masterfiles
class Mffa < DocEventHandlers
  include EdiMasterfileProcessor

  # The fields that make this masterfile record unique 
  def masterfile_keys
    ['orgzn', 'farm']
  end

  # The ActiveRecord class name for this masterfile.
  def masterfile_klass
    MfFarm
  end

end

