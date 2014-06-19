class NewOutboxRecord 
  
  
  def initialize(type,record)
    begin
      @type = type
      @record = record
    
      create_entry(record,type)
    
    rescue
      raise "Outbox record for type: " + type + " and id: " + record.id.to_s + "could not be created. Reason: " + $!
    ensure
      @file.close if @file
    end
     
  end
   
  def create_entry(record,type)
    begin
      outbox_entry = OutboxEntry.new
      outbox_entry.type_code = type
      outbox_entry.process_status = 0
      outbox_entry.record_id = record.id
      outbox_entry.object_type = record.class.to_s
    
      data = "{"
      record.attributes.each do |key,value|
        str_val = nil
        if value.class.to_s == "Time"||value.class.to_s == "Date"
          str_val = value.strftime("%d/%b/%Y %H:%M:%S")
        end
        #-----------------------------------------------------------------------------------------
        #See if field is 'class_code' or 'product_class_code'.If so, replace code with description
        #-----------------------------------------------------------------------------------------
        if key.upcase == "CLASS_CODE"||key.upcase == "PRODUCT_CLASS_CODE"
          if value && value.strip!= ""
            class_record = ProductClass.find_by_product_class_code(value)
            str_val = class_record.product_class_description if class_record && class_record.product_class_description
          end
        end

        #------------------------------------------------------------------------------------------------------------
        #if record is a carton and it's production run is a child run,set production run code and id to parent and
        #  change the carton_pack_station_code as follows:
        #  -> take 2nd and 3rd char, convert to int, and add 50 to it
        #  -> if the new number is bigger than 99, set process_status to 1
        #  -  else, replace the 2nd and 3rd character of cps with the new number
        #-------------------------------------------------------------------------------------------------------------
        if record.class.to_s.index("Carton")||record.class.to_s.index("Rebin")
          if key == "carton_pack_station_code" || key == "production_run_id"|| key == "production_run_code"
            if record.production_run_id
              run = ProductionRun.find(record.production_run_id)
              if run.parent_run_code
                if key == "carton_pack_station_code"
                  station_code = record.carton_pack_station_code
                  num = station_code.slice(1..2).to_i + 50
                  new_station_code = station_code.slice(0..0) + num.to_s + station_code.slice(3..4)
                  str_val = new_station_code
                  if num > 99
                    outbox_entry.process_status = 50
                  end
                elsif key == "production_run_id"
                  parent_run = ProductionRun.find_by_production_run_code(run.parent_run_code)
                  str_val = parent_run.id.to_s
                elsif key == "production_run_code"
                  str_val = run.parent_run_code
                end

              end
            end
          end
        end

        str_val = value.to_s if ! str_val
        data += ":" + key + "=> " + "\"" + str_val + "\", "
      end

       if record.respond_to?("load_no") && record.load_no
        if !record.attributes.has_key?("load_no")
          data += ":load_no => " + "\"" + record.load_no + "\", "
        end
      end
      #------------------------------------------------
      #Add support for virtual attribute 'location_code
      #------------------------------------------------
      if record.respond_to?("location_code") && record.location_code
        if !record.attributes.has_key?("location_code")
          data += ":location_code => " + "\"" + record.location_code + "\", "
        end
      end
    
      data.slice!(data.length()-2)
      data += "}"
      outbox_entry.record = data
      outbox_entry.create
      puts "outbox entry created"
    rescue
      puts "outbox err: " + $!
      raise "create entry failed: Reason: " + $!
    end
  end
  
  #  def create_file
  #   begin
  #    file_name = Time.now.strftime("%m_%d_%Y_%H_%M_%S") + "_" +  @type +  @record.id.to_s
  #    if  not File.exist?(@@outbox_dir)
  #	   Dir.mkdir(@@outbox_dir)
  #	end
  #    @file = File.new(@@outbox_dir + "/" + file_name,"w")
  #   rescue
  #    raise "create file failed. Reason: " + $!
  #   end
  #  end
  
   
  
end
