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
      if(options[:edi_type] == 'edi_in')
        err_entry.error_line_number = options[:error_line_number] if(options[:action_type] == 'parse')
        err_entry.raw_text = options[:raw_text]
      end
    end
    options.each {|k,v| err_entry.send(k.to_s+'=', v) }

    err_entry.save!

    err_entry
  end

  def after_save
    #case self.flow_type
    #  when 'ps'
        if(self.action_type == 'parse') #recipients :depot,H/O
          StatusMan.set_status("EDI_PARSE_ERROR_OCCURED", "ps_edi_errors", self, nil, nil, nil)
        elsif(self.action_type == 'execute')  #recipients :Support(jmt),H/O
          StatusMan.set_status("EDI_EXECUTE_ERROR_OCCURED", "ps_edi_errors", self, nil, nil, nil)
        elsif(self.edi_type == 'directory_processing') #recipients :Support(jmt),H/O   ....  #NO error_line_number
          StatusMan.set_status("EDI_DIRECTORY_PROCESSING_ERROR_OCCURED", "ps_edi_errors", self, nil, nil, nil)
        end
      #when 'mtdp'
      #  if(self.action_type == 'parse') #recipients :depot,H/O
      #    StatusMan.set_status("EDI_PARSE_ERROR_OCCURED", "ps_edi_errors", self, nil, nil, nil)
      #  elsif(self.action_type == 'execute')  #recipients :Support(jmt),H/O
      #    StatusMan.set_status("EDI_EXECUTE_ERROR_OCCURED", "ps_edi_errors", self, nil, nil, nil)
      #  elsif(self.edi_type == 'directory_processing') #recipients :Support(jmt),H/O   ....  #NO error_line_number
      #    StatusMan.set_status("EDI_DIRECTORY_PROCESSING_ERROR_OCCURED", "ps_edi_errors", self, nil, nil, nil)
      #  end
    #end
  end

end
