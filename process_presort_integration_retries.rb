# ruby script/runner -e production 'load "process_presort_integration_retries.rb"' 0 192.168.50.17 3000 1
# ruby script/runner -e production 'load "process_presort_integration_retries.rb"' 1 192.168.50.17 3000 1

server = ARGV[3]
port = ARGV[4]
mode = ARGV[2].to_i
err = "ERROR: Please provide a value for port" if(!ARGV[4])
err = "ERROR: Please provide a value for server" if(!ARGV[3])
err = "ERROR: Please provide a value for mode" if(!ARGV[2])
err = "ERROR: Please provide a valid mode i.e. 0 or 1" if(![0,1].include?(mode.to_i))

if(err)
  puts err
  exit
end

time_interval = (!ARGV[5]) ? 5 : ARGV[5].to_i
or_clause = (mode==0) ? "process_attempts=0" : "process_attempts>0"

begin
  while (true)
    presort_integration_retries = PresortIntegrationRetry.find(:all,:conditions=>or_clause)
    presort_integration_retries.each do |retr|
      # begin
      ActiveRecord::Base.transaction do
        http_conn = Net::HTTP.new(server, port)
        http_conn.open_timeout = 5* 60
        http_conn.read_timeout = 5* 60
        report_parameters = "bin=#{retr.bin_number}&unit=#{retr.presort_unit}"
        response = http_conn.get("/services/pre_sorting/#{retr.event_type}?" + report_parameters, nil)

        require 'nokogiri'
        response_xml = Nokogiri::XML(response.body.to_s)
        if(response_xml.root.children[0].name == 'bins')
          presort_integration_retry_history = PresortIntegrationRetryHistory.new({:presort_unit=>retr.presort_unit, :event_type=>retr.event_type,:process_attempts=>retr.process_attempts,:bin_number=>retr.bin_number,:error=>retr.error})
          presort_integration_retry_history.save!

          retr.destroy
        end
      end
    end

    puts "execution done[#{Time.now}]: going to sleep"
    sleep(time_interval.minutes)
  end
rescue
  err_entry = RailsError.new
  err_entry.description = $!.message
  err_entry.stack_trace = $!.backtrace.join("\n").to_s if $!
  err_entry.logged_on_user = 'presort integration retry'
  err_entry.error_type = 'presort integration retry'
  err_entry.create
end
