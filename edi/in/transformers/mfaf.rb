# EDI in processor of AF (Account Farms) Masterfiles
class Mfaf < DocEventHandlers
  include EdiMasterfileProcessor

  # The fields that make this masterfile record unique 
  def masterfile_keys
    ['orgzn', 'acct', 'farm']
  end

  # The ActiveRecord class name for this masterfile.
  def masterfile_klass
    MfAccountFarm
  end

end
