# Extend masterfile models with this module to provide valildation in them.
#
# === Example:
#
#   class MfAccount < ActiveRecord::Base
#     extend MasterfileValidator
#   
#     def self.check_types
#       {'account' => 'orgzn = ? AND acct = ?'}
#     end
#   
#   end
module MasterfileValidator

  # Does a masterfile record exist with the supplied +values+?
  #
  # Calls check_types on the masterfile model class to get a hash of types of checks and which conditions to use in the find.
  # Returns a boolean and a message string. The message contains the validation error if the validation fails.
  def masterfile_has?( check_type, values )
    checks = self.check_types
    return false, "Masterfile #{self.name} has no check named #{check_type}." unless checks.keys.include? check_type
    condition = checks[check_type]
    return false, "Masterfile #{self.name} requires #{condition.scan( /\?/).size} values for check named #{check_type}." unless condition.scan( /\?/).size == values.size

    begin
      res = self.find(:first, :conditions => [condition, *values])
    rescue ActiveRecord::StatementInvalid => error
      s = condition.gsub('?') { values.shift}
      return false, "Masterfile #{self.name} encountered an SQL error for check named #{check_type} with conditions '#{s}': " << error
    end
    if res.nil?
      s = condition.gsub('?') { values.shift}
      return false, "Masterfile #{self.name} does not have an entry for '#{s}' for check named #{check_type}."
    else
      return true, ''
    end
  end

end
