# Masterfile. FA - Farm
class MfFarm < ActiveRecord::Base
  extend MasterfileValidator

  # The kind of validation checks available to this masterfile.
  def self.check_types
    {'farm' => 'orgzn = ? AND farm = ?'}
  end

end
