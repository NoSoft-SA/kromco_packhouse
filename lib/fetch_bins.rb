
  
  def load_models
     begin
          Dir.foreach("app/models") do |entry|
            if entry.index(".rb") && entry != "carton_label_printing.rb" &&  entry != "process_outbox.rb" && entry !=  "outbox_processor.rb" && entry != "rw_run.rb" 
              require "app/models/" + entry
              puts entry + "<br>"
           end
         end
     
     rescue
      puts "<font color = 'red'><br>load error: models not loaded correctly: " + $! + "</font>"
      #raise "models not loaded correctly: " + $!
      return
   end
   
   end
   
   
   require "rubygems"
   require "active_record"
   require "globals.rb"
   
   begin
     puts "Bin manager: connecting to Kromco mes..."
     ActiveRecord::Base.establish_connection(:adapter => "postgresql", :host => "localhost",  :database => "kromco_mes",
                                                                :username => "postgres", :password => "postgres",:port => 5432)
     puts "Bin manager: connected to Kromco mes." 
     puts "Bin manager: loading models..."                                                           
     load_models
     puts "Bin manager: models loaded."   
                                                            
     run_id = ARGV[0].to_i
     
     run = Production_run.find(run_id)
     puts "Bin manager: fetching bins..."   
     BinManager.new(run).fetch_bins
     puts "Bin manager: bins fetched."   
   
   rescue
     raise "Bin fetching failed: " + $!
   end
   
   
   
   