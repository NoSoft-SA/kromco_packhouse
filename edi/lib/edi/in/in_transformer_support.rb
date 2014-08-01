# Module to be included by edi in transformer types (eg text, xml).
# Implements common routines.
module InTransformerSupport

  # Create a log file specifically for this transformation.
  # When called from an out transformer the log file will already exist,
  # so use that.
  def create_logger( in_or_out )
    if 'out' == in_or_out
      @logger = EdiHelper.transform_log # Already created earlier in the out flow process.
    else
      transform_log_dir = Pathname.new("edi/logs/#{in_or_out}").join(Time.now.strftime("%Y_%m_%d"), 'transformers')
      transform_log_dir.mkpath
      doc_name = @flow_type
      doc_name = @doc_name if @doc_name
      @logger = EdiHelper.make_transform_log(transform_log_dir.to_s,
                                             doc_name + "_" +
                                             Time.now.strftime("%m_%d_%Y_%H_%M_%S") +
                                             ".log", in_or_out)
    end
  end

  # Log errors to the EdiError table.
  # +type+ is typically +parse+ or +execute+.
  # +msg+ is passed in if there is no exception object.
  # +error+ is the exception.
  def handle_error(type, msg=nil, error=nil)
    options = {:flow_type   => @flow_type,
      :edi_type    => "edi_in",
      :transformer => "XmlInTransformer",
      :action_type => type,
      :edi_filename => EdiHelper.edi_in_process_file,
      :error_line_number=> self.get_file_line_number,
      :raw_text=> self.get_file_contents}

    options[:logged_on_user] = @user if @user
    options[:ip] = @ip if @ip
    options[:description] = msg unless msg.nil?
    err_entry = EdiError.record_error( error, options )

    @logger.write "#{type} error for flow_type #{@flow_type} user: #{@user} ip: #{@ip} error: #{err_entry.description}",2
    unless error.nil?
      @logger.write "stacktrace: ", 0
      @logger.write "stacktrace: #{err_entry.stack_trace}",0
    end

  end
end
