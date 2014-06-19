# Base for EDI Out Transformers.
# Transformer types inherit from this class and implement at least create_doc.
# Specific transformers inherit from a Transformer type and implement create_doc_records, and optionally post_process.
class OutTransformer

  attr_accessor :return_a_string
  attr_reader   :filename, :edi_string

  def initialize
    @edi_string          = ''
    @return_a_string     = false
    @field_delimiter     = '|' # Delimiter for csv.
  end

  # Transform records into an EDI out flow.
  #
  # Calls make_next_seq_no, make_file_name, create_logger, get_record_map,
  # create_doc_records, create_doc, validate, post_process and send_doc.
  def execute( proposal )
    @flow_type  = proposal.flow_type
    # Prefix to use in transforms when raising exceptions as the first part of the error message:
    @err_prefix = "Flow: #{@flow_type.upcase} transform error"

    completed_ok   = false
    @seq_increased = false
    begin
      make_next_seq_no
      make_file_name( proposal )
      create_logger

      EdiHelper.transform_log.write 'Starting transform..'

      get_record_map( proposal )

      EdiHelper.transform_log.write 'Create hierarchy records'
      hierarchy_recs = create_doc_records( proposal )

      # puts hierarchy_recs # Show a summary of the hierarchy for debugging purposes.

      EdiHelper.transform_log.write 'Create doc from hierarchy records'
      doc = create_doc( hierarchy_recs )

      EdiHelper.transform_log.write 'Validate doc against transform xml'
      return false unless validate( doc )

      EdiHelper.transform_log.write 'Post-processing doc'
      @edi_string = post_process( doc )

      unless @return_a_string
        EdiHelper.transform_log.write 'Send doc'
        send_doc
      end

      EdiHelper.transform_log.write 'File has been sent. Performing final tasks such as writing edi file name to model.'
      begin
        file_sent( proposal, @filename )
      rescue StandardError => error
        EdiHelper.edi_log.write 'An error occurred during "file_sent". *** NB. This is just being logged, the EDI send was successfully concluded. ***', 2
        log_error( proposal, error )
      end


      EdiHelper.transform_log.write 'Transform ended.'
      completed_ok = true

    rescue StandardError => error
      log_error( proposal, error )
      @edi_string = "Error: #{error}" if @return_a_string
      # Move the sequence number back
      if @seq_increased
        # NB!!!! If this call fails it will raise another exception.
        EdiHelper.edi_log.write "Attempting to rollback sequence number from #{@out_seq}...", 2
        new_seq = MesControlFile.prev_seq_edi(MesControlFile.const_get("EDI_#{@flow_type.upcase}"), @out_seq)
        EdiHelper.edi_log.write "Rollback of sequence number succeeded. Now #{new_seq}.", 2
      end
      completed_ok = false
    end
    completed_ok
  end

  # Log an error to the database and the logfile
  def log_error( proposal, error )
    options = {:flow_type   => proposal.flow_type,
               :edi_type    => "out_proposal",
               :action_type => 'execute',
               :transformer => self.class.name,
               :edi_out_proposal_id => proposal.id}

    options[:logged_on_user] = 'EDI Out'

    err_entry = EdiError.record_error( error, options )

    EdiHelper.edi_log.write err_entry.description, 2
    # Not generally interested in a stack trace
    log_level = error.is_a?( EdiOutError ) || error.is_a?( EdiValidationError ) ? 0 : 2
    EdiHelper.edi_log.write err_entry.stack_trace, log_level
    begin
      EdiHelper.edi_log.write 'Calling transformer to write error instance to model.'
      record_error_instance( proposal, err_entry )
    rescue StandardError => error
      EdiHelper.edi_log.write "ERROR when calling transformer to write error instance: #{error}", 2
    end
  end

  # Send the EDI document out.
  def send_doc
    if EdiHelper.current_out_is_cumulative
      File.open(File.join(EdiHelper.edi_out_process_join_dir, EdiHelper.current_out_subdirs, @filename), 'w') {|f| f.puts @edi_string }
    else
      File.open(File.join(EdiHelper.edi_out_process_dir, EdiHelper.current_out_subdirs, @filename), 'w') {|f| f.puts @edi_string }
    end
  end

  # Validate the edi document against its schema.
  def validate(doc)
    raw_text = doc.gsub("\n", '')
    tfr = TextIn::TextTransformer.new(raw_text, @flow_type, nil, nil, nil, 'out')
    res = tfr.parse
    res.nil? # parse returns nil on success
  end

  # Get the EDI proposal record map
  def get_record_map( proposal )
    @record_map = YAML.load( proposal.record_map )
  end

  # Call MesControlFile.next_seq_edi to get the sequence number for this doc type.
  #
  # If the flow type will be accumulated into one file later, fix the seq no to 1.
  def make_next_seq_no
    if EdiHelper.current_out_is_cumulative || @return_a_string
      @out_seq = 1
    else
      @out_seq = MesControlFile.next_seq_edi(MesControlFile.const_get("EDI_#{@flow_type.upcase}"))
      @seq_increased = true
    end
    @formatted_seq = sprintf('%03d', @out_seq)
  end

  # Create a logger for the current out flow EDI proposal being processed.
  def create_logger
    transform_log_dir = Pathname.new("edi/logs/out").join(Time.now.strftime("%Y_%m_%d"), 'transformers')
    transform_log_dir.mkpath
    EdiHelper.make_transform_log(transform_log_dir.to_s,
                                  @filename + "_" +
                                  Time.now.strftime("%m_%d_%Y_%H_%M_%S") +
                                  ".log", 'out')
  end

  # Paltrack rules for writing an edi out file name.
  #
  # Build up filename as OOxxxyyy.zzz
  #   Where OO  = flow_type
  #         xxx = Network address (FROM_depot; e.g. 999 = Test Depot)
  #         yyy = Sequence number to keep the filename unique (000 - 999)
  #         zzz = Hub address (TO_depot; e.g. 006 = IHS)
  # For a cumulative process (where the files will be accumulated into one later),
  # the sequence number (+yyy+) is replaced with the current date and time.
  def make_paltrack_file_name( proposal )
    if EdiHelper.current_out_is_cumulative
      @filename = "#{@flow_type.upcase}#{EdiHelper.network_address}#{Time.now.strftime('%Y%m%d-%H%M%S')}.#{proposal.hub_address}"
    else
      @filename = "#{@flow_type.upcase}#{EdiHelper.network_address}#{@formatted_seq}.#{proposal.hub_address}"
    end
  end

  # --- v METHODS FOR OVERRRIDE v ---

  # Build up the output file name.
  #
  # This method can be overridden per transformer if required.
  # (Defaults to calling make_paltrack_file_name. If type is not 'paltrack',
  # build the filename as flow_type and seq: PO001)
  def make_file_name(proposal, type='paltrack')
    if type == 'paltrack'
      make_paltrack_file_name(proposal)
    else
      @filename = @flow_type.upcase << @formatted_seq
    end
  end

  # Create a HierarchicalRecordSet from the EdiOutProposal record.
  #
  # This method is implemented by each specific document type transformer.
  def create_doc_records(proposal)
    puts "create_doc_records Not implemented"
  end

  # Take the HierarchicalRecordSet and transform it into the desired record set
  # using the schema's rules.
  #
  # This method is implemented by each of the transformer types (eg. TextOutTransformer).
  def create_doc(doc_records)
    puts "create_doc Not implemented"
  end

  # Perform any processing of the record set that may be required after it has been transformed.
  #
  # This method is optionally implemented by each specific document type transformer when required.
  def post_process(doc)
    doc
  end

  # File has been sent. Perform tasks such as writing the filename to the model that the transformation is based on.
  # Any other processing that depends on a successful transformation can also be done here.
  #
  # NB An error raised within this method will be logged, but at this stage the EDI file has been generated
  #    and the transformation is deemed to be successful.
  #
  # This method is optionally implemented by each specific document type transformer when required.
  # If the table_and_attribute_names method is implemented, there should be no need to override this method.
  def file_sent( proposal, filename )
    table_name, file_field, err_field = table_and_attribute_names
    unless table_name.blank? || file_field.blank? || err_field.blank?
      upd = "UPDATE #{table_name} SET #{file_field} = '#{filename}', #{err_field} = NULL WHERE id = #{proposal.record_id}"
      ActiveRecord::Base.connection.execute(upd)
    end
  end

  # An error has been logged to edi_errors table. This method gives the transformer the opportunity to write
  # the id of the edi_error to the model.
  #
  # NB An error raised within this method will just be logged but not written to the edi_errors table.
  #
  # This method is optionally implemented by each specific document type transformer when required.
  # If the table_and_attribute_names method is implemented, there should be no need to override this method.
  def record_error_instance( proposal, err_entry )
    table_name, file_field, err_field = table_and_attribute_names
    unless table_name.blank? || err_field.blank?
      upd = "UPDATE #{table_name} SET #{err_field} = #{err_entry.id} WHERE id = #{proposal.record_id}"
      ActiveRecord::Base.connection.execute(upd)
    end
  end

  # Names for table, edi_file_name and edi_error_id.
  # If this method is implemented, the base definitions of +file_sent+ and +record_error_instance+
  # will write the edi file name and the id of an edi error to the given table.
  #
  # Returns an array of strings: table_name, edi_file_name attribute and edi_error_id attribute.
  #
  # This method is optionally implemented by each specific document type transformer when required.
  def table_and_attribute_names
    #e.g. ['orders', 'edi_file_name', 'edi_error_id']
    []
  end 

  # --- ^ METHODS FOR OVERRRIDE ^ ---

end
