require "app_factory.rb"
class DataToUserExporter
   
  @@download_path = 'public/downloads/'
  def DataToUserExporter.download_path
    return @@download_path
  end
  
  def DataToUserExporter.get_model_data(table_name)
   begin 
   model = Inflector.camelize(Inflector.singularize(table_name))
   records = eval model + ".find(:all)"
   rescue
     raise "model data retrieval failed. Reported exception: \n" + $!
   end
  end
  
  def DataToUserExporter.export_table_to_csv(table_name,file_name)
    begin
    
    records = DataToUserExporter.get_model_data(table_name)
    raise "The table is empty" if records.length == 0
    DataToUserExporter.create_csv_file(records,file_name)
    rescue
      raise "Data could not be exported to csv. Reported exception: \n " + $!
    end
  end
   
   
  def DataToUserExporter.create_custom_csv_file(recordset,file_name,columns)
    begin
    lines = Array.new
    #use 'FileUtil.write_lines_to_file(full_path,lines)' to create the file
    #create each csv record as a comma separated string
    header = ""
    record_nr = 0
    
    recordset.each do |record|
      line = ""
      
      columns.each do |col|

        #create headers if this is the first record
        if col.class.to_s == "Array"	 
          name = col[0]
          caption = name
          caption = col[1] if col[1]
        else
          col.strip!()
          name = col
          caption = col
        end
        
        value = eval "record." + name.downcase
        value = " " if !value
        value = value.to_s
        value = "'" + value if col == "pallet_number"||col == "inventory_reference"
        if record_nr == 0
          header << caption << ","
        end
        
       
        line << value.to_s.gsub("\n","") << ","
        
      end
     
      if record_nr == 0
        header = header.slice(0..header.length()-2)
        lines.push header
      end
      line = line.slice(0..line.length()-2)
      lines.push line
      record_nr += 1
    end
    
    AppFactory::FileUtil.write_lines_to_file(@@download_path + file_name,lines)
    
    rescue
      raise "Csv file writer failed. Reported exception: \n" + $!
    end
  end
  
  def DataToUserExporter.create_se_csv_file(recordset,file_name,columns = nil)
    begin
    lines = Array.new
    #use 'FileUtil.write_lines_to_file(full_path,lines)' to create the file
    #create each csv record as a comma separated string
    header = ""
    record_nr = 0
    
    if !columns ||(columns && columns.length() == 0)
       recordset.each do |record|
         line = ""
         record.each do |name,value|
           #create headers if this is the first record
            if record_nr == 0
             header << name.to_s << ","
            end
            value = value.to_s
            value = "'" + value if name == "pallet_number"||name == "inventory_reference"
            line << value.gsub("\n","") << ","
         end
         if record_nr == 0
           header = header.slice(0..header.length()-2)
           lines.push header
         end
         line = line.slice(0..line.length()-2)
         lines.push line
         record_nr += 1
       end
    else
      recordset.each do |record|
         line = ""
         columns.each do |coll|
           col = coll.downcase
             col.strip!() if col.class.to_s != "Array"
            if col.index(".")
             col = col.split(".")[1].strip()
           end
           #create headers if this is the first record
             value = record[col]
             if record_nr == 0
             header << col.to_s << ","
            end

            value = value.to_s
            value = "'" + value if col == "pallet_number"||col == "inventory_reference"
            line << value.to_s.gsub("\n","") << ","
         end
         if record_nr == 0
           header = header.slice(0..header.length()-2)
           lines.push header
         end
         line = line.slice(0..line.length()-2)
         lines.push line
         record_nr += 1
       end
    end
    
    AppFactory::FileUtil.write_lines_to_file(@@download_path + file_name,lines)
    
    rescue
      raise "Csv file writer failed. Reported exception: \n" + $!
    end
  end
  
  def DataToUserExporter.create_csv_file(recordset,file_name)
    begin
    lines = Array.new
    #use 'FileUtil.write_lines_to_file(full_path,lines)' to create the file
    #create each csv record as a comma separated string
    header = ""
    record_nr = 0
    
    recordset.each do |record|
      line = ""
      
      record.attributes.each do |name,value|
        #create headers if this is the first record
       
        if record_nr == 0
          header += name.to_s + ","
        end
        value = value.to_s
        value = "'" + value if name == "pallet_number"||name == "inventory_reference"
        line << value.gsub("\n","") << ","
        
      end


      if record_nr == 0
        header = header.slice(0..header.length()-2)
        lines.push header
      end
      line = line.slice(0..line.length()-2)
      lines.push line
      record_nr += 1
    end
    
    AppFactory::FileUtil.write_lines_to_file(@@download_path + file_name,lines)
    
    rescue
      raise "Csv file writer failed. Reported exception: \n" + $!
    end
  end

end