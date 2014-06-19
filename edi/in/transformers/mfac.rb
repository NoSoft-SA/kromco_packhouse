# EDI in processor of AC (Accounts) Masterfiles
class Mfac < DocEventHandlers
  include EdiMasterfileProcessor

  # The fields that make this masterfile record unique 
  def masterfile_keys
    ['orgzn', 'acct']
  end

  # The ActiveRecord class name for this masterfile.
  def masterfile_klass
    MfAccount
  end

end

