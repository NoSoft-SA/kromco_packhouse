# Masterfile. GT - Product Code
class MfProductCode < ActiveRecord::Base
  extend MasterfileValidator

  # The kind of validation checks available to this masterfile.
  def self.check_types
    {'gtin' => 'gtin = ?',
     'gtin_by_date' => 'gtin = ? AND date_strt <= ? AND date_end >= ?'}
  end

end
