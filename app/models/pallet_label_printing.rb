require "rubygems"
require "active_record"
require "action_mailer"
require "lib/globals.rb"
require "config/postgres_adapter_patch"

  begin
      gem 'rails-dbi', :require => 'dbi'
    rescue Gem::LoadError
      # Swallow the error if the gem is not installed and fall back on the standard dbi gem
    end

require "dbi"

puts "BEFORE MODEL LOAD :: " + Time.now.to_s

begin
    Dir.foreach("app/models") do |entry|
      if entry.index(".rb") && entry != "carton_label_printing.rb" &&  entry != "process_outbox.rb" && entry !=  "outbox_processor.rb" && entry !=  "outbox_processor_debug.rb" && entry !=  "bin_ticket_printing.rb" && entry !=      		   "mrl_label_printing.rb" && entry != "bin_manager.rb" && entry != "pallet_label_printing.rb"
            require "app/models/" + entry
        end
    end

  Dir.foreach("app/models/pdt_transactions/pdt_business_functions") do |entry|
    if entry == "label_print_command.rb"
      require "app/models/pdt_transactions/pdt_business_functions/" + entry
      puts "loaded.................."
    end
  end
rescue
    puts "<font color='red'><br>load error: models not loaded correctly: " + $! + "</font>"
    #return
end

puts "AFTER MODEL LOAD :: " + Time.now.to_s


#printing begins here
begin

   puts "BEFORE DB CONN :: " + Time.now.to_s

    ActiveRecord::Base.establish_connection(Globals.get_mes_conn_params)
    
    puts "AFTER DB CONN :: " + Time.now.to_s
    
    require "net/http"
    http_conn = nil
    ip = Globals.get_label_printing_server_url
    port = Globals.get_label_printing_server_port
    #print_instruction = ARGV[0]
    printer = ARGV[0].to_s
    format = ARGV[1].to_s
    pallet_number = ARGV[2].to_s

    label_print_cmd = LabelPrintCommand.new(printer, format, pallet_number)
    print_instruction = label_print_cmd.print()
    puts ":: ARG 1 :: " + print_instruction
    puts "IP: " + ip
    puts "BEFORE MAKING HTTP CONN :: " + Time.now.to_s
    http_conn = Net::HTTP.new(ip, port)
    puts "AFTER MAKING HTTP CONN :: " + Time.now.to_s
    http_conn.get("/" + print_instruction,nil)
    puts "AFTER HTTP GET :: " + Time.now.to_s
    puts "::: PALLET LABEL PRINTED :::::"
    #return print_instruction
rescue
    puts "<br><font color='red'>print error: pallet label printing failed: reason: " + $! + "</font>"
 
ensure
    ActiveRecord::Base.remove_connection

end
