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
    #     if(self.action_type == 'parse') #recipients :depot,H/O
    #       StatusMan.set_status("EDI_PARSE_ERROR_OCCURED", "ps_edi_errors", self, nil, nil, nil)
    #     elsif(self.action_type == 'execute')  #recipients :Support(jmt),H/O
    #       StatusMan.set_status("EDI_EXECUTE_ERROR_OCCURED", "ps_edi_errors", self, nil, nil, nil)
    #     elsif(self.edi_type == 'directory_processing') #recipients :Support(jmt),H/O   ....  #NO error_line_number
    #       StatusMan.set_status("EDI_DIRECTORY_PROCESSING_ERROR_OCCURED", "ps_edi_errors", self, nil, nil, nil)
    #     end
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


  # List of EDI Errors linked to their models.
  # +specs+ is an Array of Hashes and +where_clause+ is an optional where clause.
  #
  # Each Hash has the following keys:
  # :name        describes the transaction type.
  # :model       the model class name
  # :table       the table name
  # :ref         the field to display as the reference
  # :error_id    (OPTIONAL) field to use if the error id field on the model is not 'edi_error_id'
  # :extra_where (OPTIONAL) extra where clause to refine the query.
  #
  # Example:
  # specs << {:name        => 'Receipt Bank Charges',
  #           :model       => 'CustomerReceipt',
  #           :table       => 'customer_receipts',
  #           :ref         => 'cashbook_ref_no',
  #           :error_id    => 'bank_charges_edi_error_id',
  #           :extra_where => "invoice_type = 'CUSTOMER'"}
  def self.build_list_query(specs, where_clause)
    queries = []
    specs.each do |spec|
      queries <<
        "SELECT '#{spec[:name]}' AS trans_type, '#{spec[:model]}' AS model,
        #{spec[:table]}.id AS model_id, #{spec[:ref]} AS ref_no,
        #{spec[:error_id] || 'edi_error_id'} AS id, error_code,
        edi_errors.created_on, edi_errors.description, edi_out_proposal_id
        FROM #{spec[:table]}
        JOIN edi_errors ON edi_errors.id = #{spec[:table]}.#{spec[:error_id] || 'edi_error_id'}
        JOIN edi_out_proposals ON edi_out_proposals.id = edi_errors.edi_out_proposal_id
        WHERE edi_error_id IS NOT NULL#{spec[:extra_where].nil? ? '' : ' AND '+spec[:extra_where]}"
    end

    qry = <<-EOQ
    SELECT all_together.trans_type, all_together.ref_no, all_together.description,
    all_together.model, all_together.model_id, all_together.id, all_together.error_code,
    all_together.created_on, all_together.edi_out_proposal_id,
    model || '_' || CAST(model_id AS character varying) AS model_and_id
    FROM (
    #{queries.join("\nUNION ALL\n")}
    ) AS all_together
    #{where_clause}
    ORDER BY 7 DESC
    EOQ

    qry
  end

end
