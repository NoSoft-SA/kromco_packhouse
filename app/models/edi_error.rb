# This class holds errors that occur during EDI processing.
class EdiError < ActiveRecord::Base 
  belongs_to :edi_out_proposal

  # Ensure that description does not get cleared by SQL-Injection protection
  # when the record is saved. (Might be describing an SQL error)
  def fields_not_to_clean
    ["description"]
  end
	
  # Record an error by creating an EdiError instance.
  # +error+ is an Error instance but can be nil.
  # +options+ is a hash of values to update the instance's attributes.
  def self.record_error(error, options)
    err_entry = EdiError.new
    unless error.nil?
      err_entry.error_code   = error.class.name
      err_entry.description  = error.to_s
      err_entry.stack_trace  = error.backtrace.join("\n").to_s
    end
    options.each {|k,v| err_entry.send(k.to_s+'=', v) }

    err_entry.save

    err_entry
  end

end
