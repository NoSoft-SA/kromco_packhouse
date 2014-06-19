
 

class BinManager
  
   require "dbi"
   require "lib/globals.rb"
   require "parsedate.rb"
   include ParseDate
   
 def connect_to_kromco_data
  begin
   puts "connecting"
   @conn = DBI.connect(Globals.get_odbc_legacy_db_conn_string,"SA","")
   puts "connected to kromco"
   rescue
    @conn.disconnect if @conn
    raise "Connection to kromco data could not be established. Reported exception: <br> " + $!
   end
 end
 
  
  def initialize(production_run)
   begin
   
   @production_run = production_run
   connect_to_kromco_data
   
   puts "connected to kromco data..."
   rescue
    @conn.disconnect if @conn
    puts $!
    raise "Connection to legacy bin store could not be established. Reported exception: <br> " + $!
   end
  end
   
  private
  def create_bin(legacy_bin)
  
   if Bin.find_by_bin_id(legacy_bin["Bin_ID"])
    puts "Bin already exists"
    return
   end
     
   bin = Bin.new
   bin.production_schedule_name = @production_run.production_schedule.production_schedule_name
   bin.production_run = @production_run
   bin.production_run_code = @production_run.production_run_code
   bin.bin_id = legacy_bin["Bin_ID"] 
   bin.line_code = @production_run.line_code
   bin.farm_code = @production_run.farm_code if @production_run.farm_code
   bin.treatment_code = legacy_bin["Spray_Program"]
   bin.treatment_type_code = "PRE_HARVEST"
   bin.product_class_code = legacy_bin["Class"]
   bin.class_description = legacy_bin["Class"] #new field
   bin.farm_code = legacy_bin["Farm_ID"] #new field
   #-----------------------------------------------------------------------------------------------
   #Use parse date to try to force a sensible conversion from Mssql to standard db date formatting
   #-----------------------------------------------------------------------------------------------
   
   received_date = legacy_bin["Bin_Receive_DateTime"].to_s
   date_parts = parsedate(received_date)
   bin.bin_receive_datetime = Time.local(date_parts[0],date_parts[1],date_parts[2],date_parts[3],date_parts[4],date_parts[5],date_parts[6],date_parts[7])
   
   #bin.bin_receive_datetime = legacy_bin["Bin_Receive_DateTime"]#new field
   bin.delivery_no = legacy_bin["Delivery_No"]
   bin.variety_code = legacy_bin["Cultivar"]
   bin.commodity_code = legacy_bin["Fruit_Type"]
   bin.pc_code = legacy_bin["PC_Code"]
   bin.track_indicator_code = legacy_bin["Current_Raw_Material_Type"] #new field
   bin.cold_store_code = legacy_bin["Cold_Store_Type"]
   if legacy_bin["Weight"]
     bin.weight = legacy_bin["Weight"]
   else
     bin.weight = 0
   end
   bin.create
   return bin
  
  end
  
  
  public
  def get_bins
   begin
    query = build_fetch_query
    puts "about to fetch bins"
    @legacy_bins = @conn.select_all(query)
    puts @legacy_bins.length.to_s + " bins fetched from kromco data" if @legacy_bins
    Bin.delete_all("line_code = '#{@production_run.line_code}'")
    @legacy_bins.each do |legacy_bin|
       create_bin(legacy_bin)
       #puts "bin created. id : " + legacy_bin["Bin_ID"].to_s
    end 
    puts "bins created"
    
   rescue
    raise "Bins could not be fetched from kromco legacy database. Reported exception: <br>" + $!
   ensure
    if @conn
      @conn.disconnect
    end
   end
  end
  
  
  
  public
  def get_bin(bin_id)
   begin
    query = build_fetch_query(bin_id)
    puts query
    puts "about to fetch bin with id: " + bin_id
    @legacy_bin = @conn.select_one(query)
    bin = nil
    if @legacy_bin
       puts "legacy bin found"
       if bin = create_bin(@legacy_bin) 
           puts "bin created. id : " + @legacy_bin["Bin_ID"].to_s
          if @legacy_bin['MRL'] && @legacy_bin['MRL'] == "MRL FAILED OR NOT DONE"
            puts "mrl failure"
            return "MRL FAILED|NOT DONE"
          else
            return nil
          end
       else
        return nil
       end
      
    else
      puts "legacy bin not found."
    end 
    
    
   rescue
    raise "Bin could not be fetched from kromco legacy database. Reported exception: <br>" + $!
   ensure
    if @conn && @conn.connected?
      @conn.disconnect
    end
   end
  end
   
  private
  def build_fetch_query(bin_id = nil)
  
   criteria = @production_run.run_bintip_criterium
   rmt_setup = @production_run.production_schedule.rmt_setup
   season = @production_run.production_schedule.season_code.split("_")[0]
   
   #----------------------------
   #REAL QUERY
   #   query = "Select * from dbo.Bin INNER JOIN dbo.Cultivar on dbo.Bin.Cultivar = dbo.Cultivar.Cultivar where(exit_reference = 0  "
   #   query += " and Season = '#{season}' and Bin_Receive_DateTime is not null "
   #----------------------------
   
   query = "Select B.*, "
   query += " ISNULL ((SELECT TOP 1 mrl_Results FROM dbo.MRL_Test_Results WHERE dbo.MRL_Test_Results.season "
   query += " = b.Season AND dbo.MRL_Test_Results.cultivar = b.Cultivar AND dbo.MRL_Test_Results.farm = " 
   query += " b.Farm_ID AND mrl_Results <> 'failed' ORDER BY created_Date DESC), 'MRL FAILED OR NOT DONE') AS MRL "
   query += " FROM dbo.Bin B INNER JOIN dbo.Cultivar C ON B.Cultivar = C.Cultivar where( "
   query += " B.Season = '#{season}' and B.Bin_Receive_DateTime is not null and B.Exit_Date is null"
   
   if !criteria
     criteria = @production_run.production_schedule.bintip_criterium
   end
    
   
   #FARM_CODE
   if criteria.farm_code 
     if @production_run.farm_code #farm_pack could be 'off'
       farm_code = @production_run.farm_code
       query += " AND B.Farm_Id like '" + farm_code + "%'"
     end
   end
   
   #TREATMENT_CODE
   if criteria.treatment_code
     treatment_code = rmt_setup.treatment_code
     query += " AND B.Spray_Program = '#{treatment_code}'"
     
   end
   
   #COMMODITY_CODE
   if criteria.commodity_code
     commodity_code = rmt_setup.commodity_code
     query += " AND C.Fruit_Type = '#{commodity_code}'"
   end
    
   #CLASS_CODE
   if criteria.class_code
   
     class_code = rmt_setup.product_class_code
     class_descr = ProductClass.find_by_product_class_code(class_code).product_class_description
     query += " AND B.Class = '#{class_descr}'"
   end
   
    #PC_CODE
   if criteria.pc_code
     pc_code = "PC" + rmt_setup.rmt_product.ripe_point.pc_code.pc_code + "_" + rmt_setup.rmt_product.ripe_point.pc_code.pc_name
     query += " AND B.PC_Code = '#{pc_code}'"
   end
   
   #TRACK_INDICATOR_CODE
   if criteria.track_indicator_code
     track_indicator = rmt_setup.track_indicator_code
     query += " AND B.Current_Raw_Material_Type = '#{track_indicator}'"
   end
   
    #COLD_STORE_CODE
   if criteria.cold_store_code
     cold_store_code = rmt_setup.cold_store_code
     query += " AND B.Cold_Store_Type = '#{cold_store_code}'"
   end
   
    #INPUT_VARIETY_CODE
   if criteria.variety_code
     variety_code = rmt_setup.variety_code 
     query += " AND B.Cultivar like '" + variety_code + "_%'"
   end
   
    if bin_id
     query += " AND B.Bin_Id = '#{bin_id}'"
   end
   
   query += ")"
   puts query
   
   return query
   
  end
  
end