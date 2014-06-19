 #!/usr/bin/env ruby
require "rubygems"
require "active_record"
require "action_mailer"
require "lib/globals.rb"

  begin
      gem 'rails-dbi', :require => 'dbi'
    rescue Gem::LoadError
      # Swallow the error if the gem is not installed and fall back on the standard dbi gem
  end

require "dbi"

output_msg = ""


  def log_error()

    err_entry = RailsError.new
    err_entry.description = "Bin ticket printing failed.Reason: " + $!
    err_entry.stack_trace = $!.backtrace.join("\n").to_s
    err_entry.error_type = "bin_ticket_printing"
    err_entry.controller_name = "ForecastController"
    err_entry.action_name = "print_bin_tickets"
    err_entry.logged_on_user = "system"
    err_entry.person = nil
    err_entry.create

  end

begin
  Dir.foreach("app/models") do |entry|
#    puts "RQUIRE : " + entry + "<br>"
    
    if entry.index(".rb") && Globals.is_scriptable_model?(entry)#&& entry!= "bin_ticket_printing" && entry!="mrl_label_printing.rb" && entry != "carton_label_printing.rb" &&  entry != "process_outbox.rb" && entry !=  "outbox_processor.rb"
      require "app/models/" + entry
    end
  end
rescue
  puts "<font color = 'red'><br>load error: models not loaded correctly: " + $! + "</font>"
  return
end

output_msg += "<br><font color = 'green'>MODELS LOADED CORRECTLY<br>"
begin

  ActiveRecord::Base.establish_connection(Globals.get_mes_conn_params('development'))
  n_tickets_printed = 0
  require "net/http"
  http_conn = nil
  ip = Globals.bin_ticket_printing_ip

  if ARGV[0].upcase()== "BATCH"
    forecast_variety_indicator = ForecastVarietyIndicator.find(ARGV[1])

    puts ip.to_s
    #hans: uncomment
    http_conn = Net::HTTP.new(ip, Globals.get_label_printing_server_port)
    output_msg += "BATCH PRINTING " + ARGV[2] + " tickets...<br>"
    
    instruction = forecast_variety_indicator.print_bin_tickets http_conn, ARGV[2]
    puts " Batch bin ticket print command(for " + ARGV[2] + " tickets) successfully sent to printer. Instruction was: <BR>" + instruction
      
  end

rescue


  puts "<br><font color = 'red'>print error: bin ticket printing failed: reason: " + $! + "</font>"
  begin
   log_error
  rescue
       puts "Error logging failed: " + $!
   end


ensure
  ActiveRecord::Base.remove_connection
end