 #!/usr/bin/env ruby

 require "rubygems"
 require "active_record"
 require "action_mailer"


 $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '../lib'))

# Change to the root of the rails app and work relative to that
Dir.chdir(Pathname(File.join(File.dirname(__FILE__), '../..')).cleanpath)


 require "lib/globals.rb"
 require "lib/extensions.rb"

   begin
      gem 'rails-dbi', :require => 'dbi'
    rescue Gem::LoadError
      # Swallow the error if the gem is not installed and fall back on the standard dbi gem
   end


require "dbi"
  
 output_msg = ""
   
   begin
     Dir.foreach("app/models") do |entry|
      if entry.index(".rb") && Globals.is_scriptable_model?(entry)
        #puts "loading: " + entry
        begin
          require "app/models/" + entry
        rescue
          puts "load failed: " + entry + " Reason: " + $!
        end
        #puts "loaded"
      end
     end
     
   rescue
    puts "<font color = 'red'><br>load error: models not loaded correctly: " + $! + "</font>"
    puts $!.backtrace.join("\n")
    #raise "models not loaded correctly: " + $!
    return
   end
   
   output_msg += "<br><font color = 'green'>MODELS LOADED CORRECTLY<br>"
   begin
   
     ActiveRecord::Base.establish_connection(Globals.get_mes_conn_params('development'))

     user = nil


     n_labels_printed = 0
     require "net/http"
     http_conn = nil
     ip = Globals.reworks_ip
     
     if ARGV[0].upcase == "BATCH"
        user = ARGV[3] if ARGV[3]
        run_code = ARGV[1].split("__")[0]
        farm_code = ARGV[1].split("__")[1]
        puc = ARGV[1].split("__")[2]

       cartons = RwActiveCarton.find_all_by_production_run_code_and_rw_active_pallet_id_and_farm_code_and_puc(run_code,ARGV[2].to_i,farm_code,puc)
	   
	   if cartons.length() > 0
	     run = cartons[0].rw_run
	     if run.carton_printing_ip
	       ip = run.carton_printing_ip
	     end
	   end
	   puts "IP:" + ip
	   http_conn = Net::HTTP.new(ip, 2080)
	   output_msg += "BATCH PRINTING " + cartons.length().to_s + " cartons...<br>"
       cartons.each do |carton|
        instruction = carton.print_label http_conn,user
        n_labels_printed += 1
        log = CartonLabelLog.new
        log.label_instruction = instruction
        log.print_type = "reworks batch"
        log.progress = n_labels_printed.to_s + " of " + cartons.length.to_s
        log.create
       end
     
     else
        user = ARGV[1] if ARGV[1]
       carton = RwActiveCarton.find(ARGV[0].to_i)
        run = carton.rw_run
	     if run.carton_printing_ip
	       ip = run.carton_printing_ip
	     end
	   puts "IP:" + ip
       http_conn = Net::HTTP.new(ip, 2080)
       output_msg += "SINGLE PRINTING...<br>"
       instruction = carton.print_label http_conn,user
       log = CartonLabelLog.new
        log.label_instruction = instruction
        log.print_type = "reworks single"
        log.progress = " "
        log.create
     end
     
     n_printed_msg = "<strong> 1"
     n_printed_msg = "<strong> " + n_labels_printed.to_s if n_labels_printed > 1
     
     output_msg += n_printed_msg + " lABEL(S) PRINTED<strong></font>"
     output_msg += "<br><strong>|" + n_labels_printed.to_s + "</strong>" if ARGV[0].upcase == "BATCH"
     puts output_msg
   rescue
     puts "<br><font color = 'red'>print error: label printing failed: reason: " + $! + "</font>"
     puts $!.backtrace.join("\n")
     #raise "label printing failed: reason: " + $!
   ensure
    ActiveRecord::Base.remove_connection
   
   end