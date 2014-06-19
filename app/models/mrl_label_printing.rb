require "rubygems"
require "active_record"
require "action_mailer"
require "lib/globals.rb"

output_msg = ""

  begin
      gem 'rails-dbi', :require => 'dbi'
    rescue Gem::LoadError
      # Swallow the error if the gem is not installed and fall back on the standard dbi gem
    end

require "dbi"

begin
    Dir.foreach("app/models") do |entry|
        if entry.index(".rb") && Globals.is_scriptable_model?(entry)
            require "app/models/" + entry
        end
    end
rescue
    puts "<font color='red'><br>load error: models not loaded correctly: " + $! + "</font>"
    return
end

output_msg += "<br><font color='green'>MODELS LOADED CORRECTLY<br>"

#printing begins here
begin
    
    ActiveRecord::Base.establish_connection(Globals.get_mes_conn_params)
    n_labels_printed  = 0
    require "net/http"
    http_conn = nil
    ip = Globals.get_label_printing_server_url
    
    mrl_result = MrlResult.find(ARGV[0].to_i)
    puts "IP: " + ip
    http_conn = Net::HTTP.new(ip, Globals.get_label_printing_server_port)
    output_msg += "SINGLE PRINTING..<br>"
    instruction = mrl_result.print_label http_conn
    
    n_printed_msg = "<strong> 1"
    output_msg += n_printed_msg + " LABEL(S) PRINTED</strong></font>"
    puts output_msg
    return instruction
rescue
    puts "<br><font color='red'>print error: mrl label printing failed: reason: " + $! + "</font>"
    raise "Mrl Label could not be printed, Reason: " + $!
ensure
    ActiveRecord::Base.remove_connection
    
end