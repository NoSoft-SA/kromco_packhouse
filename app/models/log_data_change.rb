class LogDataChange < ActiveRecord::Base

  # notes may well include SQL statements. Don't check for SQL injection.
  def fields_not_to_clean
    ['notes']
  end

end
