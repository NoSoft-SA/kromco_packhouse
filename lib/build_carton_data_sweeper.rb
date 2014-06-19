
 #---------------------------------------------------------------------
 #This file of ruby code is designed to be launched in a new process 
 #by the caller by using the 'IO.popen' method. The caller should use
 #the created io object to write to it the 'fg_setup' id, which this 
 #code will collect from standard input ($stdin). The whole idea of this
 #code/class is to build cartons labels and templates in a separate process
 #with no interference from the webserver or rails processes/threads
 #Threading- as application code- in rails is just very unstable.
 #---------------------------------------------------------------------
 
require "rubygems"
require "active_record"
require "action_mailer"

class CartonDataBuilder

 
   ActiveRecord::Base.establish_connection(:adapter => "postgresql", :host => "localhost",  :database => "kromco_mes",
                                                                :username => "postgres", :password => "postgres",:port => 5432)
   
  def CartonDataBuilder.init
  
   begin
    require File.dirname(__FILE__) + "/../app/models/marketing_variety.rb"
    require File.dirname(__FILE__) + "/../app/models/pack_material_product.rb"
    require File.dirname(__FILE__) + "/../app/models/pc_code.rb"
    require File.dirname(__FILE__) + "/../app/models/target_market.rb"
    require File.dirname(__FILE__) + "/../app/models/inventory_code.rb"
    require File.dirname(__FILE__) + "/../app/models/season.rb"
    require File.dirname(__FILE__) + "/../app/models/commodity.rb"
    require File.dirname(__FILE__) + "/../app/models/mark.rb"
    require File.dirname(__FILE__) + "/../app/models/standard_count.rb"
    require File.dirname(__FILE__) + "/../app/models/gtin.rb"
    require File.dirname(__FILE__) + "/../app/models/contact_method.rb"
    require File.dirname(__FILE__) + "/../app/models/contact_methods_party.rb"
    require File.dirname(__FILE__) + "/../app/models/standard_size_count.rb"
    require File.dirname(__FILE__) + "/../app/models/parties_postal_address.rb"
    require File.dirname(__FILE__) + "/../app/models/size.rb"
    require File.dirname(__FILE__) + "/../app/models/ripe_point.rb"
    require File.dirname(__FILE__) + "/../app/models/organization.rb"
    require File.dirname(__FILE__) + "/../app/models/party.rb"
    require File.dirname(__FILE__) + "/../app/models/postal_address.rb"
    require File.dirname(__FILE__) + "/../app/models/pallet_template.rb"
    require File.dirname(__FILE__) + "/../app/models/pallet_format_product.rb"
    require File.dirname(__FILE__) + "/../app/models/rmt_variety.rb"
    require File.dirname(__FILE__) + "/../app/models/rmt_product.rb"
    require File.dirname(__FILE__) + "/../app/models/rmt_setup.rb"                                                         
    require File.dirname(__FILE__) + "/../app/models/fg_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/carton_setup.rb"
     require File.dirname(__FILE__) + "/../app/models/item_pack_product.rb"
     require File.dirname(__FILE__) + "/../app/models/product_class.rb"
    require File.dirname(__FILE__) + "/../app/models/retail_item_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/retail_unit_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/pallet_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/pallet_label_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/trade_unit_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/production_schedule.rb"
    require File.dirname(__FILE__) + "/../app/models/carton_setup_update_timestamp.rb"
    require File.dirname(__FILE__) + "/../app/models/rmt_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/carton_template.rb"
    require File.dirname(__FILE__) + "/../app/models/carton_label_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/standard_size_count.rb"
    require File.dirname(__FILE__) + "/../app/models/extended_fg.rb"
    require File.dirname(__FILE__) + "/../app/models/fg_mark.rb"
    require File.dirname(__FILE__) + "/../app/models/gtin.rb"
    require File.dirname(__FILE__) + "/../app/models/product.rb"
    require File.dirname(__FILE__) + "/../app/models/fg_product.rb"
    require File.dirname(__FILE__) + "/model_helper.rb"
    require File.dirname(__FILE__) + "/../app/models/rails_error.rb"
    
   rescue
    puts "MODELS NOT LOADED CORRECTLY: " + $!
   end
   
  
   
  end
  
  def CartonDataBuilder.build_carton_data(fg_id)
    fg = FgSetup.find(fg_id)
    fg.build_templates_and_labels
    puts "templates BUILD!!"
    
  end
  
  
 end                                                               
 
class ActiveRecord::Base
 
  def export_attributes(target_record)
  
  self.attributes.each do |name,attr|
    
    if !(name.index("_id") || name == "id")
      if target_record.has_attribute?(name)
        if attr == nil
           eval "target_record." + name + " = nil"
        else
         eval "target_record." + name + " = '#{attr}'"
        end
      end
    end
  end

end
 
end

  def log_error(err)
  
    err_entry = RailsError.new
    err_entry.description = "Carton data sweeper failed. Reason: " + err
    err_entry.stack_trace = err.backtrace.join("\n").to_s
    err_entry.error_type = "carton_data_sweeper"
    err_entry.controller_name = "outbox_processor"
    err_entry.action_name = "process_outbox"
    err_entry.logged_on_user = "system"
    err_entry.person = nil
    err_entry.create
 
 end

 begin
 puts "initializing carton data sweeper"
 CartonDataBuilder.init
 puts "initialized. Sweeping..."
  while true
    sleep 20
    
    query = " select * from carton_setups where not exists
            (select carton_setup_id from carton_templates where carton_setups.id=carton_setup_id) or
             not exists
             (select carton_setup_id from carton_label_setups where carton_setups.id=carton_setup_id)or
             not exists
            (select carton_setup_id from pallet_templates where carton_setups.id=carton_setup_id) or
             not exists
            (select carton_setup_id from pallet_label_setups where carton_setups.id=carton_setup_id)"
            
     incomplete_carton_setups  = CartonSetup.find_by_sql(query)
    
    
    puts incomplete_carton_setups.length.to_s + " incomplete carton setups found."
    incomplete_carton_setups.each do |setup|
       puts "checking carton setup: " + setup.carton_setup_code + " (id: " + setup.id.to_s + ")..."
       if setup.fg_setup == nil
         puts "carton setup found: (" + setup.carton_setup_code + "), but no fg setup defined. \n REMEMBER to save fg_setup to complete this carton setup"
       elsif setup.pallet_setup == nil
         puts "carton setup found: (" + setup.carton_setup_code + "), but no pallet setup defined. \n REMEMBER to save pallet_setup to complete this carton setup"
       else
          puts "carton setup is complete(fg exists). Templates and labels can be build"
         # if setup.production_schedule.production_schedule_status_code == "re_opened"
          #   puts "setup " + setup.carton_setup_code + " belongs to a  schedule that is in 're_opened' state and will be ignored"
         # else
             puts "building templates and labels for carton setup: " + setup.carton_setup_code + " (id: " + setup.id.to_s + ")..."
             CartonDataBuilder.build_carton_data(setup.fg_setup.id)
             puts "templates and labels built for carton setup: " + setup.carton_setup_code 
         # end
       end
    end
    
 end 

 rescue
   puts "AN EXCEPTION OCCURRED: " + $!
   log_error($!)
   
 ensure #Someone closing the program will result in a system exit exception being raised, so we can close connection
  puts "exiting"
  ActiveRecord::Base.remove_connection
 end

                                                           