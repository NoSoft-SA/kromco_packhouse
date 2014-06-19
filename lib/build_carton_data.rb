
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

class CartonDataBuilder

  ActiveRecord::Base.establish_connection(:adapter => "postgresql", :host => "localhost",  :database => "mes_local_v20",
                                                                :username => "postgres", :password => "postgres",:port => 5432)
   
 
  def CartonDataBuilder.init
  
   begin
    require File.dirname(__FILE__) + "/../app/models/marketing_variety.rb"
    require File.dirname(__FILE__) + "/../app/models/pack_material_product.rb"
    require File.dirname(__FILE__) + "/../app/models/pc_code.rb"
    require File.dirname(__FILE__) + "/../app/models/commodity.rb"
    require File.dirname(__FILE__) + "/../app/models/mark.rb"
    require File.dirname(__FILE__) + "/../app/models/standard_count.rb"
    require File.dirname(__FILE__) + "/../app/models/gtin.rb"
    require File.dirname(__FILE__) + "/../app/models/standard_size_count.rb"
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
    require File.dirname(__FILE__) + "/../app/models/retail_item_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/retail_unit_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/pallet_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/pallet_label_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/trade_unit_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/production_schedule.rb"
    require File.dirname(__FILE__) + "/../app/models/rmt_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/carton_template.rb"
    require File.dirname(__FILE__) + "/../app/models/carton_label_setup.rb"
    require File.dirname(__FILE__) + "/../app/models/standard_size_count.rb"
    require File.dirname(__FILE__) + "/../app/models/gtin.rb"
   rescue
    puts "models not loaded correctly: " + $!
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

exit_prog = false
while exit_prog == false
  sleep 0.5
  input = $stdin.gets
  if input.to_s.upcase.index("Q")
    exit_prog = true
  else
    fg_id = input.to_i
    CartonDataBuilder.init
    CartonDataBuilder.build_carton_data(fg_id)
  end
end


                                                           