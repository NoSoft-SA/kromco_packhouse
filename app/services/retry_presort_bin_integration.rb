require 'nokogiri'

class RetryPresortBinIntegration
  attr_reader :user_name

  def initialize(server, port, mode, debug_on = false)


    @server = server
    @port = port
    @mode = mode
    @debug_on = debug_on
    @debug_text = ""

    if @mode == nil || @server == nil || @port == nil
      raise " Server, port and mode are all required by this service"
    end

  end

  def debug_msg(msg)
    puts msg if @debug_on
    @debug_text << msg
  end


  def get_bins_to_integrate

    or_clause = (@mode==0) ? "process_attempts=0" : "process_attempts>0"
    presort_integration_retries = PresortIntegrationRetry.find(:all, :conditions => or_clause)
    return presort_integration_retries

  end


  def call
    begin
      @start_time = Time.now()
      retry_bins = get_bins_to_integrate
      @n_bins = get_bins_to_integrate.size

      debug_msg "#{retry_bins.size} bins found to integrate"
      debug_msg("\n server: " + @server + " port: " + @port)

      retry_bins.each do |retr|

        ActiveRecord::Base.transaction do


          http_conn = Net::HTTP.new(@server, @port)
          http_conn.open_timeout = 5* 60
          http_conn.read_timeout = 5* 60

          debug_msg("\n calling service for bin=#{retr.bin_number}&unit=#{retr.presort_unit}")

          report_parameters = "bin=#{retr.bin_number}&unit=#{retr.presort_unit}"
          url = "/services/pre_sorting/#{retr.event_type}?" + report_parameters
          debug_msg("\n URL: " + url)
          response = http_conn.get(url, nil)

          debug_msg("\n Received response:\n\n")

          response_xml = Nokogiri::XML(response.body.to_s)

          debug_msg("BODY:\n\n" + response.body.to_s)

          if (response_xml.root.children[0].name == 'bins')
            presort_integration_retry_history = PresortIntegrationRetryHistory.new({:presort_unit => retr.presort_unit, :event_type => retr.event_type, :process_attempts => retr.process_attempts, :bin_number => retr.bin_number, :error => retr.error})
            presort_integration_retry_history.save!

            retr.destroy
            debug_msg("logged to history")
          end
        end
      end
      @end_time = Time.now()
      write_log if @debug_on

    rescue
      err_entry = RailsError.new
      err_entry.description = $!.message
      err_entry.stack_trace = $!.backtrace.join("\n").to_s if $!
      err_entry.logged_on_user = 'presort integration retry'
      err_entry.error_type = 'presort integration retry'
      err_entry.create
      Globals.send_an_email("presort_integration_retry failure", "gerritf@kromco.co.za", err_entry.description + "\n\n StackTrace \n\n " + err_entry.stack_trace)
      raise "An unexpected error occurred. See rails error log and/or email for detail. Reported: " + err_entry.description + "\n stacktrace \n" + err_entry.stack_trace


    end


  end

  def write_log

    @ref = "\n #{@n_bins} presort re-integration attempts"
    @ref << "\n Duration: #{(@end_time - @start_time).seconds} seconds"

    # log ould have notes in html and include hash.inspect output within html comments...
    LogDataChange.create!(:user_name      => "system",
                          :ref_nos => @ref ,
                          :notes          => @debug_text,
                          :type_of_change => 'PRESORT RE-INTEGRATION SERVICE')
  end


end
