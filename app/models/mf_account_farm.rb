# Masterfile. AF - AccountFarm
class MfAccountFarm < ActiveRecord::Base
  extend MasterfileValidator

  # The kind of validation checks available to this masterfile.
  def self.check_types
    {'farm' => 'orgzn = ? AND acct = ? AND farm = ?'}
  end

end
