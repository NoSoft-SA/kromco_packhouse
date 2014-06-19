# Masterfile. GU - Gtin
class MfProductCodeTargetMarket < ActiveRecord::Base
  extend MasterfileValidator

  # The kind of validation checks available to this masterfile.
  def self.check_types
    {'gtin' => 'gtin = ?',
     'mkt_gtin' => 'gtin = ? AND target_market = ?'}
  end

end
