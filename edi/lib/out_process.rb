# Control the processing of EDI output files.
class OutProcess
  include EdiSetup

  PROPOSAL_CONDITIONS = {:normal    => 'process_attempts = 0',
                         :retry     => 'process_attempts > 0',
                         :retry_now => 'retry_now = true'}


  # Load libraries and connect to database.
  def initialize(interval, mode, dir_path, join_path)
    @ar_connected    = false
    @interval        = interval
    @mode            = mode.to_sym
    @return_a_string = false

    begin
      raise "Unknown mode parameter. Expected one of \"#{PROPOSAL_CONDITIONS.keys.join('" or "')}\".
             Got \"#{mode}\"." unless PROPOSAL_CONDITIONS.keys.include? @mode

      EdiHelper.edi_out_process_dir      = dir_path
      EdiHelper.edi_out_process_join_dir = join_path

      puts "working dir: " + Dir.getwd
      puts "output dir: #{EdiHelper.edi_out_process_dir}"
      puts "join dir: #{EdiHelper.edi_out_process_join_dir}/staging" unless EdiHelper.edi_out_process_join_dir == EdiHelper.edi_out_process_dir

      puts "loading libraries..."
      load_libs
      puts "libraries loaded"

      proc_dir = "edi/logs/out"
      FileUtils.makedirs(proc_dir)
      edi_log = EdiHelper.make_edi_log(proc_dir, 'out')

      edi_log.write "loading models..."
      load_models
      edi_log.write "models loaded"

      edi_log.write "loading edi modules..."
      load_edi_modules
      edi_log.write "edi modules loaded"

      edi_log.write "setting up db connections..."
      @ar_connected = set_up_connections
      edi_log.write "db connections established"

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
  end

  # Load modules required for out flow.
  def load_edi_modules
    
    require "edi/lib/edi/out/out_transformer"

    Dir.foreach("edi/lib/edi/out") do |entry|
      next if entry == 'out_transformer.rb'
      require "edi/out/" + entry  if entry.index(".rb")
    end
    
    require "edi/lib/edi/in/in_transformer_support"

    Dir.foreach("edi/lib/edi/in") do |entry|
      next if entry == 'in_transformer_support.rb'
      require "edi/in/" + entry  if entry.index(".rb")
    end

    @out_transformers = {}
  end

  # Call take_snapshot periodically based on the desired interval.
  def run

    while (true)
      take_snapshot
      sleep @interval
    end

  rescue
    EdiHelper.edi_log.write "Exception in main edi out process.\n " + $!
    EdiHelper.edi_log.write "Exception Stacktrace = " + $!.backtrace.join("\n").to_s
  ensure
    ActiveRecord::Base.connection.disconnect!()
    ActiveRecord::Base.remove_connection
  end

  # Read the EdiOutProposal records and take a snapshot of those to be processed and work through them.
  # If the OutProcess is run in normal mode, it will pick up new proposals.
  # If run in retry mode, the snapshot is of proposals that have failed.
  def take_snapshot
    # In normal mode, first gather any proposals for immediate retry, then gather normal ones.
    if :normal == @mode
      modes = [:retry_now, :normal]
    else
      modes = [@mode]
    end

    EdiHelper.edi_log.write "EDI OUT: Starting checking loop..."
    EdiHelper.edi_log.write "(Alter the log levels in the config file and the change will apply as soon as there is a proposal to process)"
    check_log_levels

    modes.each do |mode|
      snapshot = EdiOutProposal.find(:all, :conditions => PROPOSAL_CONDITIONS[mode])

      # Before processing proposals, check if the log levels have been changed and apply them.
      if snapshot.length > 0
        check_log_levels
        snap_log_level = 2
      else
        snap_log_level = 0
      end
      EdiHelper.edi_log.write "EDI OUT: Snapshot: #{snapshot.length} #{mode} records to process...", snap_log_level
      check_time = Time.now-10
      snapshot.each do |proposal|
        starting_at = Time.now
        # If less than one second has elapsed since the last file was created,
        # delay for one second - to ensure that two files cannot be created within
        # a second (and have one be overwritten).
        if 1.0 > (starting_at - check_time)
          sleep(1)
        end

        EdiHelper.edi_log.write "Starting #{proposal.flow_type} proposal #{proposal.id} for Org: #{proposal.organization_code}, Hub: #{proposal.hub_address} at #{starting_at.to_s}."

        if send_doc(proposal)
          ending_at = Time.now
          EdiHelper.edi_log.write "Completed #{proposal.flow_type} proposal #{proposal.id} at #{ending_at.to_s}."
          EdiOutProposal.transaction do
            proposal.process_attempts += 1
            EdiOutProcessHistory.log_history_from( proposal, starting_at, ending_at, @filename)
          end
        else
          EdiHelper.edi_log.write "Could not process #{proposal.flow_type} proposal #{proposal.id}."
          EdiOutProposal.increment_counter(:process_attempts, proposal.id)
          #RAILS 2.x only: proposal.toggle(:retry_now) if proposal.retry_now
          EdiOutProposal.update_all('retry_now = false', ['id = ?', proposal.id]) if proposal.retry_now
        end
        check_time = Time.now
      end
    end
  end

  # Send the proposal to the transformer of the particular EDI flow type.
  def send_doc( proposal )
    EdiHelper.edi_log.write "Sending Proposal #{proposal.id}..."
    EdiHelper.current_out_flow    = proposal.flow_type
    EdiHelper.current_out_subdirs = proposal.out_destination_dir.split('/')

    flow_type   = EdiHelper.current_out_flow.upcase
    hub_address = proposal.hub_address
    # Find transformer class
    transformer_key = find_transformer_key(flow_type, hub_address)

    # If this flow's files should be accumulated, write the file to a "staging" subdirectory.
    EdiHelper.current_out_is_cumulative = accumulate_for?( flow_type )
    if EdiHelper.current_out_is_cumulative
      EdiHelper.current_out_subdirs.unshift( 'staging' )
      # Ensure the subdirs exist or create them:
      FileUtils.makedirs(File.join(EdiHelper.edi_out_process_join_dir, EdiHelper.current_out_subdirs)) unless @return_a_string
    else
      # Ensure the subdirs exist or create them:
      FileUtils.makedirs(File.join(EdiHelper.edi_out_process_dir, EdiHelper.current_out_subdirs)) unless @return_a_string
    end


    if @out_transformers.has_key? transformer_key
      transformer = @out_transformers[transformer_key]
    else
      transformer = load_transformer( flow_type, transformer_key )
    end

    transformer.return_a_string = @return_a_string
    res = transformer.execute( proposal )
    if res
      @filename   = transformer.filename
      @edi_string = transformer.edi_string if @return_a_string
    else
      @edi_string = transformer.edi_string if @return_a_string && transformer.edi_string != '' # Error is returned
    end

    res
  rescue
    puts "Exception in send_doc of edi out process.\n " + $!
    puts "Exception Stacktrace = " + $!.backtrace.join("\n").to_s
    log_error( proposal )
    false
  end

  # Log an error to the database and the logfile
  def log_error( proposal )
    if !($!.to_s ==   "schema validation error" || $!.to_s == "transformation error")
      options = {:flow_type   => proposal.flow_type,
                 :edi_type    => "out_proposal",
                 :action_type => 'send_doc',
                 :edi_out_proposal_id => proposal.id}

      options[:logged_on_user] = 'EDI Out'

      err_entry = EdiError.record_error( $!, options )

      EdiHelper.edi_log.write err_entry.description,2
      EdiHelper.edi_log.write err_entry.stack_trace,0
    end

  end

  # Find out which transformer to use for the specific +flow_type+ and +hub_address+.
  # Read the <tt>supported_doc_types.yaml</tt> config file.
  # If there is not an entry for the specific +hub_address+, use the "ALL" key.
  def find_transformer_key(flow_type, hub_address)
    transformers = YAML::load(File.read(EdiHelper::APP_ROOT + '/edi/config/supported_doc_types.yaml'))
    
    raise EdiProcessError, "No configuration for flow type #{flow_type.upcase}." unless transformers['OUT_FLOW_TYPES'][flow_type.upcase]

    if transformers['OUT_FLOW_TYPES'][flow_type.upcase].has_key? hub_address
      transformers['OUT_FLOW_TYPES'][flow_type.upcase][hub_address]
    else
      transformers['OUT_FLOW_TYPES'][flow_type.upcase]['ALL']
    end
  end

  # Look for the schema that matches the doc type.
  #
  # Load the transformer that corresponds to the transformer key.
  def load_transformer(flow_type, transformer_key)
#    path = "edi/in/transformers/#{flow_type}.xml"

    raise EdiProcessError, "Unable to load #{transformer_key} transformer" unless require "edi/out/transformers/#{transformer_key.underscore}"
    klass       = eval( transformer_key )
    transformer = klass.new
    @out_transformers[transformer_key] = transformer
  end

  # Check if this +flow_type+ should be accumulated into one file.
  #
  # Reads the config.yml file. Defaults to false if there is no matching entry.
  def accumulate_for?( flow_type )
    configs = YAML::load(File.read(EdiHelper::APP_ROOT + '/edi/config/config.yml'))
    configs['edi_out_accumulated'][flow_type.upcase]
  end

end
