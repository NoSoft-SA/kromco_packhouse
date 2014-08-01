# Create an EDI output file from a single EdiOutProposal record.
#
# Nothing is persisted. The EdiOutProposal is created in memory, and the run method returns a string.
class OutProcessInMemory < OutProcess

  # Load libraries.
  def initialize
    @return_a_string = true
    @ar_connected    = false
    @interval        = 1
    @mode            = :normal

    load_libs( true )

    proc_dir = "edi/logs/out"
    FileUtils.makedirs(proc_dir)
    edi_log = EdiHelper.make_edi_log(proc_dir, 'out')

    load_edi_modules

    get_config_values

  rescue StandardError => error
    if edi_log
      edi_log.write  "Exception in main edi out process.\n " << error
      edi_log.write "Exception Stacktrace = " << error.backtrace.join("\n").to_s
    else
      puts "Exception in main edi out process.\n " << error
      puts "Exception Stacktrace = " << error.backtrace.join("\n").to_s
    end
    raise 'Unable to continue.'
  end

  # Run the edi out process for an in-memory proposal and return the result in a string.
  def run( proposal, log_level=2 )
    @edi_string = 'unknown'
    starting_at = Time.now

    # Set the logging levels. This should usually be for errors only.
    %w{edi_out transformer_out}.each do |log_type|
      Globals.log_levels[log_type]         = log_level
      Globals.console_log_levels[log_type] = log_level
    end

    EdiHelper.edi_log.write "Starting #{proposal.flow_type} proposal #{proposal.id} at #{starting_at.to_s}."

    if send_doc(proposal)
      ending_at = Time.now
      EdiHelper.edi_log.write "Completed #{proposal.flow_type} proposal #{proposal.id} at #{ending_at.to_s}."
      EdiOutProcessHistory.log_history_from( proposal, starting_at, ending_at, nil, true)
    else
      EdiHelper.edi_log.write "Could not process #{proposal.flow_type} proposal #{proposal.id}."
    end

    EdiHelper.edi_log.write( "In-memory string for #{proposal.flow_type} proposal #{proposal.id}:\n#{@edi_string}", 2) if EdiHelper.log_memory_string
    @edi_string
  end

end
