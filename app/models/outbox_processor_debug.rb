 
require "rubygems"
require "active_record"
require "action_mailer"
require "logger.rb"

class OutboxProcessorDebug
   
  #psexec \\software -u kromco\sysadmin -i -p 5tel5EL5 "C:\IntrackAgent.exe" CREATE 500000000000000011 PALLET 2 PACKHSE
   
  @@intrack_base_cmd = "psexec \\\\JAWAS -u kromco\\sysservices -i -p S3Rvic3s \"C:\\IntrackAgent.exe\" "
  
  #calling script must reside in Kromco mes older
  require "dbi"
  require "lib/globals.rb"
  
 def log_error(err, outbox_entry = nil)
  
  err_entry = RailsError.new
  if outbox_entry
    err_entry.description = "Outbox entry: " + outbox_entry.id.to_s + "(type: " + outbox_entry.type_code + ") could not be processed. Reported exception: " + err
  else
    err_entry.description = "Outbox processing failed. Reported exception: " + err
  end
  err_entry.stack_trace = err.backtrace.join("\n").to_s
  err_entry.error_type = "outbox_processor"
  err_entry.controller_name = "outbox_processor"
  err_entry.action_name = "process_outbox"
  err_entry.logged_on_user = "system"
  err_entry.person = nil
  err_entry.create
 
 end
 
 def get_additional_kromco_connection
#   begin
#   new_conn = DBI.connect(Globals.get_legacy_db_conn_string)
#   log_msg "additional connection made to kromco"
#   return new_conn
#   rescue
#    @conn.disconnect if @conn
#    raise "Connection to kromco data could not be established. Reported exception: <br> " + $!
#   end
 
 end
 
 def connect_to_kromco_data
#  begin
#   @conn = DBI.connect(Globals.get_odbc_legacy_db_conn_string,"sa","") if !@conn||(@conn && !@conn.connected?)
#   log_msg "connected to kromco"
#   rescue
#    @conn.disconnect if @conn
#    raise "Connection to kromco data could not be established. Reported exception: <br> " + $!
#   end
 end
 
  def connect_to_kromco_personnell_data
#  begin
#   log_msg "connecting to kromco personnell db" #get_legacy_personnell_db_conn_string
#   @personnell_conn = DBI.connect(Globals.get_odbc_legacy_personnell_db_conn_string,"sa","") if !@personnell_conn||(@personnell_conn && !@personnell_conn.connected?)
#   log_msg "connected to kromco personnell db"
#   rescue
#    @personnell_conn.disconnect if @personnell_conn
#    raise "Connection to kromco personnell db could not be established. Reported exception: <br> " + $!
#   end
 end
 
   
 def load_models
  begin
     Dir.foreach("app/models") do |entry|
       #----------------------------------------------------------------------------------------------------
       #TODO: Find out why the loading of rw_run is a problem (it required outbox_processor?- commented out)
       #-----------------------------------------------------------------------------------------------------
      if entry.index(".rb") && entry != "carton_label_printing.rb" &&  entry != "process_outbox.rb" && entry !=  "outbox_processor.rb" #&& entry != "rw_run.rb" 
        require "app/models/" + entry
        #log_msg entry + "<br>"
      end
    end
     
   rescue
    log_msg "<font color = 'red'><br>load error: models not loaded correctly: " + $! + "</font>"
    raise "models not loaded correctly: " + $!
    return
   end
 end
   
 def initialize(process_type)
   begin
    @process_type = process_type
    ActiveRecord::Base.establish_connection(Globals.get_mes_conn_params)                                                    
   #-------------------------------------------------------------------------
   #This method assumes that a method exists in this class with a name exactly
   #matching the value of entry.type
   #-------------------------------------------------------------------------
    log_msg "about to connect to kromco data"
    log_msg "loading models..."
    load_models
    #create_logger 
    log_msg "models loaded." 
    if process_type == "unprocessed"
      entries = OutboxEntry.find_by_sql("select * from outbox_entries where process_status = 0 order by id asc")
    else
      entries = OutboxEntry.find_by_sql("select * from outbox_entries where process_status > 0 order by id asc")
    end
    log_msg entries.length.to_s + " entries retrieved"
    connect_to_kromco_data
    log_msg "connected to kromco data" 
    entries.each do |entry|
    
     log_msg "processing entry: " + entry.type_code + ", " + entry.id.to_s + " ..."
      begin
          entry.transaction do
               
              #------------------------------------------------------------------
              #Make sure legacy connection is open(error in a given entry process
              #will leave the connection closed for the next entry)
              #------------------------------------------------------------------
                #connect_to_kromco_data
                #@conn['AutoCommit'] = false
                entry.record.gsub!("/"," ")
                eval entry.type_code + "(entry)"
                log_msg "integration transaction done"
                archive = OutboxEntryHistory.new
                archive.record = entry.record
                archive.sent_at = Time.now
                archive.type_code = entry.type_code
                archive.id = entry.id
                archive.record_id = entry.record_id
                archive.object_type = entry.object_type
                #archive.create
                log_msg "outbox record archived."
                #entry.destroy
                #@conn.commit
                #@conn['AutoCommit'] = true
          end 
      rescue
       
         entry.process_status += 1
         
         #entry.update
         
        #@conn.rollback if @conn && @conn.connected?
        log_msg "Error: " + $!,true
        log_error($!,entry)
       
      ensure
          
      end   
   end
   rescue
     log_error $!
     log_msg $!,true
     puts "Outbox processing failed. Reason: " + $!
   ensure
     log_msg "cleaning up: disconnecting from datasources..."
     #@conn.disconnect if @conn && @conn.connected?
     #@personnell_conn.disconnect if @personnell_conn && @personnell_conn.connected?
     ActiveRecord::Base.remove_connection
     #@logger.close if @logger
     log_msg "cleaned up!"
   end
 end
  
  #==================
  #INTEGRATION FLOWS:
  #==================
  
  def carton_new(entry)
    log_msg "in new"
    record_map = eval entry.record
    create_carton_util(record_map)
  
  end
  
  def rw_carton_new(entry)
    log_msg "in rw carton new"
    record_map = eval entry.record
    connect_to_kromco_personnell_data
    create_carton_util(record_map,true,"Carton")
  
  end
  
  
  def exec_query(query,connection = nil)
    #conn = @conn
    #conn = connection if connection
    
     #conn.prepare(query) do |sth|
       #sth.execute
     #end
    
  end
  
  def create_carton_util(record_map,is_reworks_carton = nil,carton_table_name = nil)
    #puts "NEW CREATE VERSION"
    log_msg "creating carton: " + record_map[:carton_number].to_s
    #------------------------------------------------------
    #additional lookups- not already mapped on cartn record
    #------------------------------------------------------
    label_station = CartonLabelStation.find_by_ip_address(record_map[:carton_label_station_code]).carton_label_station_code#the label station code stored on carton is the runtime ip address
    brand = Mark.find_by_mark_code(record_map[:carton_mark_code]).brand_code
    cosmetic_code = FgProduct.find_by_fg_product_code(record_map[:fg_product_code]).item_pack_product.cosmetic_code_name
    short_long_variety = record_map[:variety_short_long]
    short_long_variety = short_long_variety.slice(0..14) if short_long_variety.length > 15
    erp_cultivar = record_map[:erp_cultivar]
    if erp_cultivar.length > 15
        puts "CULTIVAR ABOUT TO BE SLICED"
         erp_cultivar = erp_cultivar.slice(0..14)
    end
     
    #puts "CULTIVAR IS: '#{erp_cultivar}'"
    
    class_record = ProductClass.find_by_product_class_code(record_map[:product_class_code])
    class_descr = class_record.product_class_description if class_record && class_record.product_class_description  
    class_descr = record_map[:product_class_code] if !class_descr
    run = ProductionRun.find(record_map[:production_run_id].to_i)
    farm_code = run.farm_code #gerrit farm variable (farm_code can be null!)
    
    run = ProductionRun.find(record_map[:production_run_id].to_i)
    season = Season.find_by_season_code(run.production_schedule.season_code).season.to_s
    
    user = nil
    
    if is_reworks_carton
      user = "0000241000"
    else
      user = record_map[:packer_number]
    end
    
    query = "INSERT INTO [KromcoData].[dbo].[#{carton_table_name}] 
	 (Carton_Id , 
	  Station,
	  Packing_Point,
	  Fruit_Type,
	  Brand,
	  Target_Market,
	  Variety,
	 [FG_Code],
	 [Quarantine],
	 [Inspect_Type],
	 [Carton_Label_Type],
	 [Pack_ID],
	 [Order_Number],
	 [Pallet_ID],
	 [Production_Schedule_No],
	 [Pack_Date],
	 [Count],
	 [Grade],
	 [Pack_Type],
	 [QC_Status],
	 [Wax_Applied],
	 [Chemical_Status],
	 [Class],
	 [Cultivar],
	 [Raw_Material_Type],
	 [PC_Code],
	 [Cold_Store_Type],
	 [Inventory_Code],
	 [Group_ID],
	 [Spray_Program],
	 [Weight],
	 [Quantity],
	 [PI],
	 [Pick_Reference],
	 [Production_Line_No],
	 [Shift],
	 [Remark],
	 [Organization],
	 [Quality_Group],
	 [Week],
	 [Season],
	 [PT_From_Location],
	 [Exit_Reference],
	 [Exit_Date],
	 [Pallet_Sequence_Number]) 
 
VALUES 
	( '#{record_map[:carton_number].to_s}',
	'#{label_station}',
	'#{record_map[:erp_pack_point]}',
	'#{record_map[:commodity_code]}',
	'#{brand}',
	'#{record_map[:target_market_code]}',
	 '#{short_long_variety}',
	'#{record_map[:fg_code_old]}',
	 null,
	 null,
	 '1', 
	 '#{record_map[:carton_pack_station_code]}',
	 '#{record_map[:order_number]}',
	 '#{record_map[:pallet_number].to_s}',
	 '#{record_map[:production_run_code]}',
	 '#{record_map[:pack_date_time].to_s}',
	 '#{record_map[:actual_size_count_code]}',
	 '#{record_map[:grade_code]}',
	 '#{record_map[:old_pack_code]}',
	 '1',
	 '#{cosmetic_code}',
	 null,
	 '#{class_descr}',
	 '#{erp_cultivar}',
	 '#{record_map[:track_indicator_code]}',
	 '#{record_map[:pc_code]}',
	 '#{record_map[:cold_store_code]}',
	 '#{record_map[:inventory_code]}',
	 null,
	 '#{record_map[:spray_program_code]}',
	 '#{record_map[:carton_fruit_nett_mass]}',
	 '1',
	 '1',
	 '#{record_map[:pick_reference]}',
	 '#{record_map[:line_code]}',
	 '#{record_map[:shift_code]}',
	 null, 
	 '#{record_map[:organization_code]}',
	 null,
	 '#{record_map[:iso_week_code]}',
	 '#{season}',
	 '#{record_map[:puc]}',
	 null,
	 null,
	 '1')"
	   
	 #execute
 #log_msg query,nil,true
	 #@conn.do(query)
	
	 log_msg "carton create."
    #--------------------------------------------
    #establish connection to KROMCO Personnell db
    #--------------------------------------------
    
     pers_query = "if not exists (select * from dbo.ActivityLog where trackingid='#{record_map[:carton_number]}')
		begin
		INSERT INTO [KromcoPMS].[dbo].[ActivityLog]  
			 ([ActivityID], 
			 [LoggingID],
			 [TrackingID],
			 [FGCode],
			 [AddLabel],
			 [AddGradeSort],
			 [AddGrade],
			 [AddPackID],
			 [ActivityLogDateTime],
			 [Processed],
			 [Line_No],
			 [PersonID]) 

		     VALUES 
			('10',
			 '#{user}',
			 '#{record_map[:carton_number]}',
			 '#{record_map[:fg_code_old]}',
			 '',
			 '',
			 '#{record_map[:grade_code]}',
			 '#{record_map[:carton_pack_station_code]}',
			 '#{record_map[:pack_date_time]}',
			 '0',
			 '#{record_map[:line_code]}',
			 SUBSTRING('#{record_map[:packer_number]}',3,5))
		end"
    
	 
	 log_msg "creating activity log record"
	 @personnell_conn.do(pers_query)
	 log_msg "activity log record created."
	 
  end
   
  
  def exec_intrack_command(command)
    #log_msg "sending intrack command: " + @@intrack_base_cmd + command
    #if system(@@intrack_base_cmd + command)
     # log_msg "intrack transaction succeeded"
    #else
      #log_msg "intrack transaction failed"
      #raise "The intrack command failed. Command_text was: " + command
    #end
  end
   
  def pallet_update(entry)
     #----------------------------------------
     #INTRACK: move(into reworks), then create
     #----------------------------------------
       
     record_map = eval entry.record
     pfp = PalletFormatProduct.find(record_map[:pallet_format_product_id].to_i)
     pallet_base = pfp.pallet_base.description
     pallet_format = pfp.stack_type.description
     brand = Mark.find_by_mark_code(record_map[:carton_mark_code]).brand_code
     marketing_variety_description = MarketingVariety.find_by_marketing_variety_code_and_commodity_code(record_map[:marketing_variety_code],record_map[:commodity_code]).marketing_variety_description.to_s
     variety_short_long = record_map[:marketing_variety_code] + "_" + marketing_variety_description
     puc = ProductionRun.find(record_map[:production_run_id].to_i).puc_code.to_s
     
     variety_short_long = variety_short_long.slice(0..14) if variety_short_long.length > 15
   
     run = ProductionRun.find(record_map[:production_run_id].to_i)
    season = Season.find_by_season_code(run.production_schedule.season_code).season.to_s
    erp_cultivar = record_map[:erp_cultivar]
    if erp_cultivar.length > 15
         erp_cultivar = erp_cultivar.slice(0..14)
    end
    #-------------------------------------------------------------------------------------------------------
    #Find the Reworks run where this pallet was manipulated, in order to determine if this is a reworks run
    #-------------------------------------------------------------------------------------------------------
     
    rw_run_id = RwReceiptPallet.find_by_pallet_id(record_map[:id].to_i).rw_run_id
    is_reworks_run = nil
    is_reworks_run = true if RwRun.find(rw_run_id).rw_run_type_code.upcase.index("REWORKS")
    
   
     query = "UPDATE [KromcoData].[dbo].[Pallet] 
	 SET 
	 [FG_Code] = '#{record_map[:fg_code_old]}',
	 [Build_Status]= '#{record_map[:process_status]}',
	 [Store]= '#{record_map[:cold_store_code]}',
	 [Final_Status]= '#{record_map[:build_status]}',
	 [Pallet_Type]= '#{pallet_base}',
	 [Oldest_Pack_Date]= '#{record_map[:oldest_pack_date_time]}',
	 [Count]= '#{record_map[:actual_size_count_code]}',
	 [Brand]= '#{brand}',
	 [Target_Market]= '#{record_map[:target_market_code]}',
	 [Grade]= '#{record_map[:grade_code]}',
	 [Variety]= '#{variety_short_long}',
	 [Pack_Type]=  '#{record_map[:old_pack_code]}',
	 [Qty]= '#{record_map[:carton_quantity_actual]}',
	 [Inventory_Code]= '#{record_map[:inventory_code]}',
	 [Pick_Reference]= '#{record_map[:pick_reference_code]}',
	 [PC_Code]= '#{record_map[:pc_code]}',
	 [Fruit_Type]= '#{record_map[:commodity_code]}',
	 [Pallet_Format]= '#{pallet_format}',
	 [Organization]= '#{record_map[:organization_code]}',
	 [Inspect_Type]= '#{record_map[:inspect_type_code]}',
	 [Cold_Store_type]= '#{record_map[:cold_store_code]}',
	 [Cultivar]='#{erp_cultivar}',
	 [Class]= '#{record_map[:class_code]}',
	 [Week]= '#{record_map[:iso_week_code]}',
	 [Season]= '#{season}',
	 [Packing_Instruction]= '#{record_map[:order_number]}',
	 [pt_product_characteristics] = '#{record_map[:pt_product_characteristics]}',
	 [remark] = '#{record_map[:remark]}'
	 WHERE
	 (Pallet_Id = '#{record_map[:pallet_number]}')"
 
      
    log_msg query,nil,true
    #@conn.do(query)
   
      
      #move is only relevant for reworks
      if is_reworks_run
        intrack_cmd = "move " + record_map[:pallet_number] + " REWORKS " + record_map[:carton_quantity_actual]
        #exec_intrack_command(intrack_cmd)
      end
         
  end 
   
   
  def pallet_new(entry,is_completed = nil)
     #----------------------------------------
     #INTRACK: move(into reworks), then create
     #----------------------------------------
      
     record_map = eval entry.record
     pfp = PalletFormatProduct.find(record_map[:pallet_format_product_id].to_i)
     pallet_base = pfp.pallet_base.description
     pallet_format = pfp.stack_type.description
     brand = Mark.find_by_mark_code(record_map[:carton_mark_code]).brand_code
     marketing_variety_description = MarketingVariety.find_by_marketing_variety_code_and_commodity_code(record_map[:marketing_variety_code],record_map[:commodity_code]).marketing_variety_description.to_s
     variety_short_long = record_map[:marketing_variety_code] + "_" + marketing_variety_description
     puc = ProductionRun.find(record_map[:production_run_id].to_i).puc_code.to_s
      
     variety_short_long = variety_short_long.slice(0..14) if variety_short_long.length > 15
     
    run = ProductionRun.find(record_map[:production_run_id].to_i)
    season = Season.find_by_season_code(run.production_schedule.season_code).season.to_s
    erp_cultivar = record_map[:erp_cultivar]
    if erp_cultivar.length > 15
         erp_cultivar = erp_cultivar.slice(0..14)
    end
   
     query = "INSERT INTO [KromcoData].[dbo].[Pallet] 
	 ( [Pallet_ID],
	 [FG_Code],
	 [Build_Status],
	 [Store],
	 [Quarantine],
	 [Inspection_Number],
	 [Consignment_Note_No],
	 [Final_Status],
	 [Pallet_Type],
	 [Oldest_Pack_Date],
	 [Print_Status],
	 [Count],
	 [Brand],
	 [Target_Market],
	 [Grade],
	 [Variety],
	 [Pack_Type],
	 [Thermocouple],
	 [Pallet_Label_Type],
	 [QC_Status],
	 [Qty],
	 [PI],
	 [Country_Origin],
	 [Inventory_Code],
	 [Pick_Reference],
	 [PC_Code],
	 [Fruit_Type],
	 [Pallet_Format],
	 [Organization],
	 [Label_Standard],
	 [Inspect_Type],
	 [Cold_Store_type],
	 [Group_ID],
	 [Cultivar],
	 [Quality_Group],
	 [Class],
	 [Spray_Program],
	 [Week],
	 [Season],
	 [Remark],
	 [Cape_Integration_PI],
	 [pt_product_characteristics],
	 [PT_From_Location_Type],
	 [PT_From_Location],
	 [Intake_Consignment_ID],
	 [Mixed_Count_SI],
	 [Exit_Reference],
	 [Exit_Date],
	 [SI_Inspection],
	 [Recool_Status],
	 [Mixed_Pallet_Indicator],
	 [Depot_Indicator],
	 [Cold_Date],
	 [Intake_Date],
	 [Original_Intake_Date],
	 [Pallet_Status],
	 [Revision],
	 [Packing_Instruction],
	 [Original_Intake_Depot],
	 [Depot_Transfer_Indicator],
	 [Account],
	 [Pallet_Sequence_Number],
	 [Load_No],
	 [Holdover],
	 [Memo_Line_No],
	 [Delivery_No],
	 [Order_No]) 
 
VALUES 
	( '#{record_map[:pallet_number].to_s}',
	 '#{record_map[:fg_code_old]}',
	 '#{record_map[:process_status]}',
	 '#{record_map[:cold_store_code]}',
	 '1', 
	 null,
	 null,
	 '#{record_map[:build_status]}',
	 '#{pallet_base}',
	 '#{record_map[:oldest_pack_date_time]}',
	 null,
	 '#{record_map[:actual_size_count_code]}',
	 '#{brand}',
	 '#{record_map[:target_market_code]}',
	 '#{record_map[:grade_code]}',
	 '#{variety_short_long}',
	 '#{record_map[:old_pack_code]}',
	 'no',
	 '1',
	 '0',
	 '#{record_map[:carton_quantity_actual]}',
	 '0',
	 'ZA',
	 '#{record_map[:inventory_code]}',
	 '#{record_map[:pick_reference_code]}',
	 '#{record_map[:pc_code]}',
	 '#{record_map[:commodity_code]}',
	 '#{pallet_format}',
	 '#{record_map[:organization_code]}',
	  null,
	 '#{record_map[:inspect_type_code]}',
	 '#{record_map[:cold_store_code]}',
	 null,
	 '#{erp_cultivar}',
	 null,
	 '#{record_map[:class_code]}',
	 null,
	 '#{record_map[:iso_week_code]}',
	 '#{season}',
	 null,
	 '1',
	 null,
	 'FA',
	 '#{puc}',
	 null,
	 '0',
	 null,
	 null,
	 null,
	 null,
	 '0',
	 null,
	 null,
	 null,
	 null,
	 null,
	 null,
	 '#{record_map[:order_number]}',
	 null,
	 null,
	 '#{record_map[:account_code]}',
	 '1',
	 null,
	 null,
	 null,
	 null,
	 null)"
  
   # log_msg query,nil,true
    #@conn.do(query)
   
    
    if !is_completed #move is only relevant for reworks
      intrack_cmd = "create " + record_map[:pallet_number] + " PALLET " + record_map[:carton_quantity_actual] + "   REWORKS" 
       exec_intrack_command(intrack_cmd)
       
      #intrack_cmd = "move " + record_map[:pallet_number] + " REWORKS " + record_map[:carton_quantity_actual]
      
      #exec_intrack_command(intrack_cmd)
      
     end
    
  end
  
  def carton_reclassified(entry)
    
    record_map = eval entry.record
    #------------------------------------------------------
    #additional lookups- not already mapped on cartn record
    #------------------------------------------------------
    label_station = CartonLabelStation.find_by_ip_address(record_map[:carton_label_station_code]).carton_label_station_code#the label station code stored on carton is the runtime ip address
    brand = Mark.find_by_mark_code(record_map[:carton_mark_code]).brand_code
    cosmetic_code = FgProduct.find_by_fg_product_code(record_map[:fg_product_code]).item_pack_product.cosmetic_code_name
    
    run = ProductionRun.find(record_map[:production_run_id].to_i)
    season = Season.find_by_season_code(run.production_schedule.season_code).season.to_s
    
    short_long_variety = record_map[:variety_short_long]
    short_long_variety = short_long_variety.slice(0..14) if short_long_variety.length > 15
    erp_cultivar = record_map[:erp_cultivar]
    if erp_cultivar.length > 15
         erp_cultivar = erp_cultivar.slice(0..14)
    end
    
     query = "UPDATE [KromcoData].[dbo].[Carton] 
     SET 
	 [Station]	 = '#{label_station}',
	 [Packing_Point]	 = '#{record_map[:erp_pack_point]}',
	 [Fruit_Type]	 = '#{record_map[:commodity_code]}',
	 [Brand]	 = '#{brand}',
	 [Target_Market]	 = '#{record_map[:target_market_code]}',
	 [Variety]	 = '#{short_long_variety}',
	 [FG_Code]	 = '#{record_map[:fg_code_old]}',
	 [Quarantine]	 = null,
	 [Inspect_Type]	 = null,
	 [Carton_Label_Type]	 = '1',
	 [Pack_ID]	 = '#{record_map[:carton_pack_station_code]}',
	 [Order_Number]	 = '#{record_map[:order_number]}',
	 [Pallet_ID]	 = '#{record_map[:pallet_number].to_s}',
	 [Production_Schedule_No]	 = '#{record_map[:production_run_code]}',
	 [Count]	 = '#{record_map[:actual_size_count_code]}',
	 [Grade]	 = '#{record_map[:grade_code]}',
	 [Pack_Type]	 = '#{record_map[:old_pack_code]}',
	 [QC_Status]	 = '',
	 [Wax_Applied]	 = '#{cosmetic_code}',
	 [Chemical_Status]	 = null,
	 [Class]	 = '#{record_map[:product_class_code]}',
	 [Cultivar]	 = '#{erp_cultivar}',
	 [Raw_Material_Type]	 = '#{record_map[:track_indicator_code]}',
	 [PC_Code]	 = '#{record_map[:pc_code]}',
	 [Cold_Store_Type]	 = '#{record_map[:cold_store_code]}',
	 [Inventory_Code]	 = '#{record_map[:inventory_code]}',
	 [Group_ID]	 = null,
	 [Spray_Program]	 = '#{record_map[:spray_program_code]}',
	 [Weight]	 =  '#{record_map[:carton_fruit_nett_mass]}',
	 [Quantity]	 = '1',
	 [PI]	 = '1',
	 [Pick_Reference]	 = '#{record_map[:pick_reference]}',
	 [Production_Line_No]	 = '#{record_map[:line_code]}',
	 [Shift]	 = '#{record_map[:shift_code]}',
	 [Remark]	 = null,
	 [Organization]	 = '#{record_map[:organization_code]}',
	 [Quality_Group]	 = null,
	 [Week]	 = '#{record_map[:iso_week_code]}',
	 [Season]	 = '#{season}',
	 [PT_From_Location]	 = '#{record_map[:puc]}',
	 [Exit_Reference]	 = null,
	 [Exit_Date]	 = null,
	 [Pallet_Sequence_Number]	 = '1' 

     WHERE 
	( [Carton_ID]	 = '#{record_map[:carton_number].to_s}')"
    
      #execute
  #    log_msg query,nil,true
	 #@conn.do(query)
     
    
  end
  
  
  def carton_pallet_ref_change(entry)
     
     record_map = eval entry.record
     
     
     if record_map[:pallet_number] == ''||record_map[:pallet_number] == '0'
      pallet_id = "reworks"
     else
      pallet_id = "'" + record_map[:pallet_number] + "'" 
     end
     
     if !kromco_carton_exists?(record_map[:carton_number])
         log_msg "connecting to personnell db..."
          connect_to_kromco_personnell_data
          log_msg "connected to personnell db"
          create_carton_util(record_map,true,"Carton")
     else
        if pallet_id != "reworks"
          query = "UPDATE [KromcoData].[dbo].[Carton] 
           SET 
	       [Pallet_ID]	 = '#{record_map[:pallet_number]}'
	        WHERE 
	        ( [Carton_ID]	 = '#{record_map[:carton_number].to_s}')"
	     else
	       query = "UPDATE [KromcoData].[dbo].[Carton] 
           SET 
	       [Pallet_ID]	 = 'reworks',
	       [Exit_Reference] = 'Scrap',
	       [Exit_Date]= '#{entry.friendly_date}'
	        WHERE 
	        ( [Carton_ID]	 = '#{record_map[:carton_number].to_s}')"
	     
	     end
	     
	     #execute
	  #  log_msg query, nil,true
	    #@conn.do(query)
	 end
	
  end
  
  
  
  
  def carton_deleted(entry)
   #--------------------------------------------------------------------------------
   #from reworks(resulting from scrap or alt_pack) - update Exit_Ref, set to 'scrap'
   #              Exit_Date, set to 'created_on' field value of outbox entry  
   #                          
   #--------------------------------------------------------------------------------
	# Gerrit 18 Jan [Pallet_Id]	 = '#{record_map[:pallet_number].to_s}',
     record_map = eval entry.record
     
     query = "UPDATE [KromcoData].[dbo].[Carton] 
     SET 
	 [Exit_Reference]	 = 'scrap',

	 [Pallet_Id]	 = 'REWORKS',
	 [Exit_Date]= '#{entry.friendly_date}'
	 WHERE 
	( [Carton_ID]	 = '#{record_map[:carton_number].to_s}')"
	
	 #execute
#	 puts "CTN scrap query: " + query
	 #@conn.do(query)
     
  end
   
  
  def log_msg(msg,is_error = nil,is_debug = nil)
   puts msg
#   if !is_error
#    @logger.info(msg)if @logger
#   else
#    @logger.error(msg)if @logger
#   end
   
  end
  
  def create_logger
#    begin
#     @logger = Logger.new('integration_logs/integration.log', 'daily')
#     @logger.level = Logger::DEBUG
#    rescue
#      puts "lOGGER COULD NOT BE CREATED"
#    ensure
#      
#    end
  end
  
  def kromco_pallet_exists?(pallet_number)
    begin
      query = "Select Pallet_Id from Pallet where Pallet_Id = '#{pallet_number}'"
      new_conn = get_additional_kromco_connection
      if new_conn.select_one(query)
        log_msg "Pallet: " + pallet_number + " exists in Kromco data, no pallet_complete transaction will be done."
        return true
      else
        return false
      end
    ensure
      new_conn.disconnect if new_conn && new_conn.connected?
    end  
      
  end
  
   def kromco_carton_exists?(carton_number)
    begin
      query = "Select Carton_Id from Carton where Carton_Id = '#{carton_number}'"
      new_conn = get_additional_kromco_connection
      if new_conn.select_one(query)
        log_msg "Carton: " + carton_number + " exists in Kromco data."
        return true
      else
       log_msg "Carton: " + carton_number + " does not exist in Kromco data."
        return false
      end
    ensure
      new_conn.disconnect if new_conn && new_conn.connected?
    end  
      
  end
   
  def pallet_completed(entry)
    #-----------------------------------------------------------
    #Create pallet record and a carton record for each of it's
    #cartons
    #INTRACK: IntrackCreate (pallet)
    #-----------------------------------------------------------
    
    
     #---------------------------------------------------------
     # See if pallet was completed before, if so, do nothing
     # (this is possible, since the same pallet can be involved
     # in many RTB and pallet_complete cycles: if an rtb integrates
     #  successfully but the complete fails, for some reason and
     #  more cycles is performed for same pallet, a list of outbox
     #  entries for the same pallet will build-up in postgres)
     #---------------------------------------------------------
     record_map = eval entry.record
      
     if kromco_pallet_exists?(record_map[:pallet_number])== true
       return
     end
    
     log_msg "connecting to personnell db..."
     connect_to_kromco_personnell_data
     log_msg "connected to personnell db"
     begin
       
       @personnell_conn['AutoCommit'] = false
      
      
       log_msg "creating kromco pallet..."
       pallet_new(entry,true)
       log_msg "kromco pallet created"
       pallet = Pallet.find(record_map[:id].to_i)
       pallet.cartons.each do |carton|
         log_msg "creating pallet carton(" + carton.id.to_s + ")..."
         create_carton_util(record_to_map(carton),false,"Carton_Palletising")
         log_msg "carton created."
       end
        
       copy_query = "Insert into carton select * from Carton_Palletising NOLOCK where pallet_id = '#{record_map[:pallet_number]}'"
       log_msg copy_query,nil,true 
      #@conn.do(copy_query)
       
       delete_query = "delete from Carton_Palletising where pallet_id = '#{record_map[:pallet_number]}'"
       log_msg delete_query,nil,true
      #@conn.do(delete_query)
       
       intrack_cmd = "create " + record_map[:pallet_number] + " PALLET " + record_map[:carton_quantity_actual] + " PACKHSE" 
       exec_intrack_command(intrack_cmd)
 
       #@personnell_conn.commit
       #@personnell_conn['AutoCommit'] = true
       
     rescue
      #@personnell_conn.rollback if @personnell_conn && @personnell_conn.connected?
      #@personnell_conn.disconnect if @personnell_conn && @personnell_conn.connected?
      raise $!
     end
     
  end
  
   def record_to_map(record)
   
     data = "{"
     record.attributes.each do |key,value|
      str_val = nil
      if value.class.to_s == "Time"||value.class.to_s == "Date"||value.class.to_s == "Timestamp"
  #------- Gerrit Fouche change 11 oct 2007
  #-- str_val = value.strftime("%d/%b/%Y %H:%M")
        str_val = value.strftime("%d/%b/%Y %H:%M:%S")
      end
       str_val = value.to_s if ! str_val
       data += ":" + key + "=> " + "'" + str_val + "', "
    end
    
    data.slice!(data.length()-2)
    data += "}"
    map = eval data
    return map
   
   end
   
  def pallet_carton_count_update(entry)
    #-----------------------------------------------------
    # Not needed- kromco data internal triggers handle this
    # Remove this flow from reworks- NB
    # INTRACK: set sec quantity
    #-----------------------------------------------------
    record_map = eval entry.record
    intrack_cmd = "move " + record_map[:pallet_number] + " REWORKS " + record_map[:carton_quantity_actual]
    #exec_intrack_command(intrack_cmd)
     
    
  end
  
  def pallet_deleted(entry)
   #-------------------------------------------
   #INTRACK: ship
   #
   #-------------------------------------------
   record_map = eval entry.record
   #----------------------------------
   #G Fouche 25 Oct 2007
   #Changed pallet_id from null to reworks   
   #----------------------------------------
    #GF 18/1 [Pallet_Id]	 = 'null'
    
    
   ctn_query = "UPDATE [KromcoData].[dbo].[Carton] 
     SET 
	
	 [Pallet_Id]	 = 'REWORKS',
	  [Exit_Reference] = 'Scrap',
	  [Exit_Date]= '#{entry.friendly_date}'
	 
	 WHERE 
	( [Pallet_ID]	 = '#{record_map[:pallet_number].to_s}')"
	
	 #execute 
	 #log_msg ctn_query,nil,true
	 #@conn.do(ctn_query)
     
     
     query = "UPDATE [KromcoData].[dbo].[Pallet] 
     SET 
	 [Exit_Reference]	 = 'reworks',
	 [Qty]	 = 0,
	 [Exit_Date]= '#{entry.friendly_date}'
	 WHERE 
	( [Pallet_ID]	 = '#{record_map[:pallet_number].to_s}')"
	
	 #execute
	 log_msg query,nil,true
	 #@conn.do(query)
     
     intrack_cmd = "ship " + record_map[:pallet_number]
     exec_intrack_command(intrack_cmd)
  
  end
   
  
  def pallet_rtb(entry)
   #----------------------------------------------------
   #Find all cartons belonging to pallet in kromco_mes
   #Delete pallet and all its cartons in kromco mes
   #----------------------------------------------------
    record_map = eval entry.record
    
    carton_query = "DELETE FROM [KromcoData].[dbo].[Carton]
             WHERE ([Pallet_ID]	 = '#{record_map[:pallet_number]}')"
   
    #@conn.do(carton_query)
    
    pallet_query = "DELETE FROM [KromcoData].[dbo].[Pallet]
             WHERE ([Pallet_ID]	 = '#{record_map[:pallet_number]}')"
   
    #@conn.do(pallet_query)
                   
  end
  
   
  def bin_tipped(entry,override_user = nil)
    #-----------------------------
    #Update kromco Bin Table
    #INTRACK: Move, then ship(bin)
    #-----------------------------
    
     record_map = eval entry.record
     run = ProductionRun.find_by_production_run_code(record_map[:production_run_code])
     farm_code = run.farm_code #gerrit farm variable (farm_code can be null!)
     track_indicator = run.production_schedule.rmt_setup.track_indicator_code
     
     
     query = "UPDATE [KromcoData].[dbo].[Bin] 
     SET  
	 [Bin_Tip_Status]	 = 'Tipped',
	 [PI_Bin_Tipping]	 = '1',
	 [Production_Schedule_No]	 = '#{record_map[:production_run_code]}',
	 [Production_Line_No]	 = '#{run.line_code}',
	 [Shift]	 = '#{run.shift_code}',
	 [Exit_Reference]	 = 'Tipped12',
	 [Exit_Date]= '#{record_map[:tipped_date_time]}'
      WHERE 
	( [Bin_ID]	 = '#{record_map[:bin_id]}')"
	
	log_msg "creating bin..."
	#@conn.execute(query)
    log_msg "bin created."
    #---------------
    #BIN TIPPED LOG
    #---------------
    
    override_user = '' if !override_user
    
    bintip_query = "INSERT INTO [KromcoData].[dbo].[Bin_Tip_Log] 
	 ( [Bin_ID],
	   [DateTime],
	   [Operator],
	   [OverrideOperator],
	   [OverrideReason],
	   [Production_Schedule_No],
	   [Line_No]) 
 
    VALUES 
	( '#{record_map[:bin_id]}',
	 '#{record_map[:tipped_date_time]}',
	 '',
	 '#{override_user}',
	 '',
	 '#{record_map[:production_run_code]}',
	 '#{record_map[:line_code]}')"
     
     log_msg "creating bintip log"
     #@conn.execute(bintip_query)
     log_msg "bintip log created"
      
     #move_cmd = "move " + record_map[:bin_id] + " PACKHSE_PRODSTAGE 1"
     #exec_intrack_command(move_cmd)
     query = "execute gf_integrate_production_schedule_data '#{run.production_run_code}','#{run.farm_code}','#{track_indicator}',#{run.line_code},'#{record_map[:bin_id]}'"
     #@conn.do query
     
     log_msg query,nil,true
     
     ship_cmd = "ship " + record_map[:bin_id]
     exec_intrack_command(ship_cmd)
     
  end
  
  def bin_tipped_invalid(entry)
    #----------------------------
    #Update kromco Bin Table
    #
    #INTRACK: Move, then ship(bin)
    #-----------------------------
     record_map = eval entry.record
     do_not_integrate = nil
     if record_map[:error_description]== "TIPD BIN:REQ OV"||record_map[:error_description]== "PV INV BIN:REQ OV"
       do_not_integrate = true
     elsif record_map[:error_description]== "NOT FND:REQ OV"||record_map[:error_description]== "Bin could not be found"
        #-----------------------------------------
        #Fetch bin from kromco data and get weight
        #----------------------------------------- 
        new_conn = nil
        new_conn = get_additional_kromco_connection
        begin
          #new_conn = get_additional_kromco_connection
          bin_query = "select * from Bin where (Bin_Id = '#{record_map[:bin_id]}')"
          log_msg bin_query
          kr_bin = new_conn.select_one(bin_query)
          if !kr_bin
            do_not_integrate = true
            log_msg "BIN not found"
          else
           #update our invalid_bin with weight retreieved from kromco
           invalid_bin = BinsTippedInvalid.find(record_map[:id])
           invalid_bin.weight = kr_bin["Weight"]
           invalid_bin.weight = 0 if !invalid_bin.weight
           log_msg "bin weight: " + kr_bin["Weight"].to_s
           invalid_bin.update
          end
         ensure
          new_conn.disconnect if new_conn && new_conn.connected?
         end
        
     end
     
     if !do_not_integrate
      overrider = record_map[:authoriser_name]
      bin_tipped(entry,overrider)
     end
     
  end
  
    def rebin_reclassified(entry)
    #---------------------------------------------
    #Create new bin and production_output records
    #INTRACK: create (rebin: intrack type is 'BIN'")
    #----------------------------------------------
    record_map = eval entry.record 
    run = ProductionRun.find(record_map[:production_run_id].to_i)
    input_rmt_product = run.production_schedule.rmt_setup.rmt_product
    input_variety = input_rmt_product.variety.rmt_variety
    erp_cultivar = input_variety.rmt_variety_code + "_" + input_variety.rmt_variety_description
    if erp_cultivar.length > 15
         erp_cultivar = erp_cultivar.slice(0..14)
    end
    rebin_product = RmtProduct.find_by_rmt_product_code(record_map[:rmt_product_code])
    pc_code = "PC" + rebin_product.ripe_point.pc_code.pc_code + "_" + rebin_product.ripe_point.pc_code.pc_name
    season = Season.find_by_season_code(run.production_schedule.season_code).season.to_s
    
    #-------------------------------------------------------------------------------------
    #production output record needs seconds as part of its 'transaction_date' field value
    #(All our date field values exclude seonds)
    #------------------------------------------------------------------------------
    prod_output_trans_date = nil
    rebin = Rebin.find(record_map[:id].to_i)
    prod_output_trans_date = rebin.date_time_created.strftime("%d/%b/%Y %H:%M:%S")
    
    query = "UPDATE [KromcoData].[dbo].[Bin] SET
	 [Bin_Type] ='#{record_map[:product_code_pm_bintype]}',
	 [Grower_ID]=  '#{record_map[:farm_id]}',
	 [Farm_ID] = '#{record_map[:farm_id]}',
	 [Orchard_ID] = '#{record_map[:orchard_code]}',
	 [Cultivar]='#{erp_cultivar}',
	 [Issued_Raw_Material_Type]= '#{record_map[:track_indicator_code]}',
	 [Current_Raw_Material_Type]= '#{record_map[:track_indicator_code]}',
	 [PC_Code]= '#{pc_code}',
	 [Weight]= '#{record_map[:weight]}',
	 [Cold_Store_Type]= '#{rebin_product.ripe_point.cold_store_type_code}',
	 [Class]= '#{record_map[:class_code]}', 
	 [Week]= '#{record_map[:iso_week_code]}',
	 [Season]=  '#{season}'
	  WHERE (Bin_Id = '#{record_map[:rebin_number]}' )"
    
	# log_msg query,nil, true
	 #@conn.do(query)
     
      prod_output_query = "UPDATE [KromcoData].[dbo].[Production_Output] 
	  set [Pack_ID]= '#{record_map[:binfill_station_code]}',
	 [Production_Schedule_No] = '#{record_map[:production_run_code]}',
	 [Class]= '#{record_map[:class_code]}',
	 [Count_1] = '#{record_map[:size_code]}',
	 [Grower_ID] = '#{run.farm_code}',
	 [Weight]= '#{record_map[:weight]}',
	 [Bin_Type] = '#{record_map[:product_code_pm_bintype]}'
	 WHERE  ([Bin_ID] = '#{record_map[:rebin_number]}')"
    	  #@conn.do(prod_output_query)
   
     
  end
  
  def rebin_new(entry)
    #---------------------------------------------
    #Create new bin and production_output records
    #INTRACK: create (rebin: intrack type is 'BIN'")
    #----------------------------------------------
    record_map = eval entry.record 
    run = ProductionRun.find(record_map[:production_run_id].to_i)
    input_rmt_product = run.production_schedule.rmt_setup.rmt_product
    input_variety = input_rmt_product.variety.rmt_variety
    erp_cultivar = input_variety.rmt_variety_code + "_" + input_variety.rmt_variety_description
    if erp_cultivar.length > 15
         erp_cultivar = erp_cultivar.slice(0..14)
    end
    rebin_product = RmtProduct.find_by_rmt_product_code(record_map[:rmt_product_code])
    pc_code = "PC" + rebin_product.ripe_point.pc_code.pc_code + "_" + rebin_product.ripe_point.pc_code.pc_name
    season = Season.find_by_season_code(run.production_schedule.season_code).season.to_s
    
    #-------------------------------------------------------------------------------------
    #production output record needs seconds as part of its 'transaction_date' field value
    #(All our date field values exclude seonds)
    #------------------------------------------------------------------------------
    prod_output_trans_date = nil
    rebin = Rebin.find(record_map[:id].to_i)
    prod_output_trans_date = rebin.transaction_date.strftime("%d/%b/%Y %H:%M:%S")
    
    query = "INSERT INTO [KromcoData].[dbo].[Bin] 
	 ( [Bin_ID],
	 [Bin_Type],
	 [Bin_Status],
	 [Bin_Tip_Status],
	 [Grower_ID],
	 [Farm_ID],
	 [Orchard_ID],
	 [Group_ID],
	 [Cultivar],
	 [Issued_Raw_Material_Type],
	 [Current_Raw_Material_Type],
	 [Delivery_No],
	 [PC_Code],
	 [Holder],
	 [Quantity],
	 [Destination],
	 [Weight],
	 [Cold_Store_Type],
	 [Drench],
	 [Print_Status],
	 [PI],
	 [PI_Bin_Tipping],
	 [PI_ReBin],
	 [Spray_Program],
	 [QC_Status],
	 [Class],
	 [Quality_Group],
	 [Sample_Bin],
	 [RM_CL2_Defects],
	 [RM_CL3_Defects],
	 [Bin_Print_DateTime],
	 [Bin_Receive_DateTime],
	 [Week],
	 [Season],
	 [Production_Schedule_No],
	 [Production_Line_No],
	 [Shift],
	 [Exit_Reference],
	 [Exit_Date],
	 [Bin_Level],
	 [BinConfirmFlag],
	 [CaColdRoom]) 
 
VALUES 
	( '#{record_map[:rebin_number]}',
	 '#{record_map[:product_code_pm_bintype]}',
	 'Not Broken',
	 'Not Tipped',
	 '#{record_map[:farm_id]}',
	 '#{record_map[:farm_id]}',
	 '#{record_map[:orchard_code]}',
	 '10',
	 '#{erp_cultivar}',
	 '#{record_map[:track_indicator_code]}',
	 '#{record_map[:track_indicator_code]}',
	 null,
	 '#{pc_code}',
	 null,
	 '1',
	 null,
	 '#{record_map[:weight]}',
	 '#{rebin_product.ripe_point.cold_store_type_code}',
	 null,
	 'Not Printed',
	 '0',
	 '0',
	 '1',
	 null,
	 'Available',
	 '#{record_map[:class_code]}',
	 null,
	 'N',
	 null,
	 null,
	 '#{record_map[:transaction_date]}',
	 '#{prod_output_trans_date}',
	  '#{record_map[:iso_week_code]}',
	 '#{season}',
	 null,
	 null,
	 null,
	 null,
	 null,
	 'Full',
	 null,
	 null)"
	 
	# log_msg query,nil, true
	 #@conn.do(query)
     
     prod_output_query = "INSERT INTO [KromcoData].[dbo].[Production_Output] 
	 ( [Pack_ID],
	 [Production_Schedule_No],
	 [Class],
	 [Count_1],
	 [Count_2],
	 [Count_3],
	 [Grower_ID],
	 [Weight],
	 [Status],
	 [Bin_Type],
	 [Bin_ID],
	 [Operator],
	 [Trans_Date]) 
 
VALUES 
	( '#{record_map[:binfill_station_code]}',
	 '#{record_map[:production_run_code]}',
	 '#{record_map[:class_code]}',
	 '#{record_map[:size_code]}',
	 null,
	 null,
	 '#{run.farm_code}',
	 '#{record_map[:weight]}',
	 'Incomplete',
	 '#{record_map[:product_code_pm_bintype]}',
	 '#{record_map[:rebin_number]}',
	 '#{record_map[:username]}',
	 '#{record_map[:date_time_created]}')"
	 
	 # log_msg query,nil,true
	  #@conn.do(prod_output_query)
   
      intrack_cmd = "create " + record_map[:rebin_number] + " BIN 1 PACKHSE" 
      exec_intrack_command(intrack_cmd)
     
  end
      
  def ppecb_inspection(entry)
   #------------------------------------------------------------------------------
   #Only new PPECB inspections must be allowed- remove edit functionality from UI
   #------------------------------------------------------------------------------
   record_map = eval entry.record
   result = ''
   if record_map[:passed].upcase == "TRUE"
     result = 'Passed'
   else
     result = 'Failed'
   end
   
   carton = Carton.find(record_map[:carton_id].to_i)
   line_number = carton.line_code
   puts "LINE NUM: " + line_number
   brand = Mark.find_by_mark_code(carton.carton_mark_code).brand_code
   
    pfd = carton.pallet.pallet_format_product
    pallet_format = pfd.stack_type.description
   
    short_long_variety = carton.variety_short_long
    short_long_variety = short_long_variety.slice(0..14) if short_long_variety.length > 15
   
   query = "INSERT INTO [KromcoData].[dbo].[PPECB_Inspect_Log] 
	 ( [Pallet_ID],           
	 [Inspector],             
	 [Inspect_Datetime],      
	 [Inspection_Point],     
	 [Inspection_Report],      
	 [Inspection_Result],      
	 [Reason],               
	 [Inspection_Type],        
	 [Carton_ID],              
	 [Production_Line_No],    
	 [Count],                 
	 [Brand],                  
	 [Target_Market],
	 [Grade],
	 [Variety],
	 [Pack_Type],
	 [Qty],
	 [Organization],
	 [Pallet_Result],
	 [Pallet_Format],
	 [PT_From_Location],
	 [Full_Plt_Qty],
	 [Fruit_type]) 
 
VALUES 
	( '#{record_map[:pallet_number]}',
	 '#{record_map[:inspector_number]}',
	 '#{record_map[:created_at]}',
	 '#{record_map[:inspection_point]}',
	 '#{record_map[:inspection_report]}',
	 '#{result}',
	 '#{record_map[:reason]}',
	 '#{record_map[:inspection_type_code]}',
	 '#{record_map[:carton_number]}',
	 '#{line_number}',
	 '#{carton.actual_size_count_code}',
	 '#{brand}',
	 '#{carton.target_market_code}',
	 '#{carton.grade_code}',
	 '#{short_long_variety}',
	 '#{carton.old_pack_code}',
	 '#{carton.pallet.carton_quantity_actual.to_s}',
	 '#{carton.organization_code}',
	 '#{result}',
	 '#{pallet_format}',
	 '#{carton.puc}',
	 '#{carton.pallet.cpp.to_s}', 
	 '#{carton.commodity_code}')"
     
     puts query
     #@conn.do(query)
  
  end
  

end