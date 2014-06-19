# Masterfile. AC - Account
class MfAccount < ActiveRecord::Base
  extend MasterfileValidator

  # The kind of validation checks available to this masterfile.
  def self.check_types
    {'account' => 'orgzn = ? AND acct = ?'}
  end

end
