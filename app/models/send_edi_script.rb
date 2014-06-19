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
    err_entry.description = "edi could not be sent.Reason: " + $!
    err_entry.stack_trace = $!.backtrace.join("\n").to_s
    err_entry.error_type = "send edi script"
    err_entry.controller_name = "send edi script"
    err_entry.action_name = "send_edi"
    err_entry.logged_on_user = "system"
    err_entry.person = nil
    err_entry.create

  end

begin
  puts "loading models"
  Dir.foreach("app/models") do |entry|
#    puts "RQUIRE : " + entry + "<br>"
    
    if entry.index(".rb") && Globals.is_scriptable_model?(entry)
      require "app/models/" + entry
    end
  end
rescue
  puts "<font color = 'red'><br>load error: models not loaded correctly: " + $! + "</font>"
  return
end



begin

     puts "connecting to db.."
     ActiveRecord::Base.establish_connection(Globals.get_mes_conn_params('development'))
     puts "connected to db.."
     org = ARGV[0]
    flow_name =   ARGV[1]
    EdiOutProposal.send_doc( {'organization_code' => org}, flow_name)
    puts "edi(#{flow_name}) sent for org #{org} "


rescue


  puts "edi send failed: reason: " + $! + "</font>"
  begin
   log_error
  rescue
       puts "Error logging failed: " + $!
   end


ensure
  ActiveRecord::Base.remove_connection
end