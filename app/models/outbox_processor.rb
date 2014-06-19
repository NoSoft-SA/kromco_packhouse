require "rubygems"
require "active_record"
require "action_mailer"
require "logger.rb"
require "lib/extensions.rb"
require "lib/inventory.rb"

  begin
      gem 'rails-dbi', :require => 'dbi'
    rescue Gem::LoadError
      # Swallow the error if the gem is not installed and fall back on the standard dbi gem
    end

require "dbi"

class OutboxProcessor

  @@disable_Logging = false


  if @@disable_Logging
    def puts(val)
    end

  end

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
    begin
      new_conn = DBI.connect(Globals.get_odbc_legacy_db_conn_string, "sa", "")
      #log_msg"additional connection made to kromco"
      return new_conn
    rescue
      @conn.disconnect if @conn
      raise "Connection to kromco data could not be established. Reported exception: <br> " + $!
    end

  end


  def connect_to_kromco_data
    begin
      @conn = DBI.connect(Globals.get_odbc_legacy_db_conn_string, "sa", "") if !@conn||(@conn && !@conn.connected?)
      #log_msg"connected to kromco"
    rescue
      @conn.disconnect if @conn
      raise "Connection to kromco data could not be established. Reported exception: <br> " + $!
    end
  end

  def connect_to_intrack_data
    begin
      @intrack_conn = DBI.connect(Globals.get_odbc_intrack_db_conn_string, "sa", "") if !@intrack_conn||(@intrack_conn && !@intrack_conn.connected?)
      #log_msg"connected to kromco"
    rescue
      @intrack_conn.disconnect if @intrack_conn
      raise "Connection to kromco data could not be established. Reported exception: <br> " + $!
    end
  end


  def connect_to_kromco_personnell_data
    begin
      #log_msg"connecting to kromco personnell db" #get_legacy_personnell_db_conn_string
      @personnell_conn = DBI.connect(Globals.get_odbc_legacy_personnell_db_conn_string, "sa", "") if !@personnell_conn||(@personnell_conn && !@personnell_conn.connected?)
      #log_msg"connected to kromco personnell db"
    rescue
      @personnell_conn.disconnect if @personnell_conn
      raise "Connection to kromco personnell db could not be established. Reported exception: <br> " + $!
    end
  end


  def load_models
    begin
      Dir.foreach("app/models") do |entry|
        #----------------------------------------------------------------------------------------------------
        #TODO: Find out why the loading of rw_run is a problem (it required outbox_processor?- commented out)
        #-----------------------------------------------------------------------------------------------------
        if entry.index(".rb") && Globals.is_scriptable_model?(entry)#if entry.index(".rb") && entry != "carton_label_printing.rb" && entry != "process_outbox.rb" && entry != "outbox_processor.rb" && entry != "outbox_processor_debug.rb" && entry != "bin_ticket_printing.rb" && entry != "mrl_label_printing.rb" && entry != "pallet_label_printing.rb" && entry != "mrl_result_print_command.rb" #&& entry != "rw_run.rb"
          #log_msg entry + "<br>"
          require "app/models/" + entry

        end
      end

    rescue
      #log_msg"<font color = 'red'><br>load error: models not loaded correctly: " + $! + "</font>"
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
      log_msg "about to connect to kromco data"
      connect_to_kromco_data
      log_msg "connected to kromco data"
      entries.each do |entry|
        log_msg "processing entry: " + entry.type_code + ", " + entry.id.to_s + " ..."
        begin
          entry.transaction do
            @current_entry = entry
            #------------------------------------------------------------------
            #Make sure legacy connection is open(error in a given entry process
            #will leave the connection closed for the next entry)
            #------------------------------------------------------------------
            connect_to_kromco_data
            @conn['AutoCommit'] = false
            #                entry.record.gsub!("/"," ")
            eval entry.type_code + "(entry)"
            log_msg "integration transaction done"
            archive = OutboxEntryHistory.new
            archive.record = entry.record
            archive.sent_at = Time.now
            archive.type_code = entry.type_code
            archive.id = entry.id
            archive.record_id = entry.record_id
            archive.object_type = entry.object_type
            archive.intrack_cmd = entry.intrack_cmd
            archive.create
            log_msg "outbox record archived."
            entry.destroy
            @conn.commit
            @conn['AutoCommit'] = true
          end
        rescue

          entry.process_status += 1

          entry.update

          @conn.rollback if @conn && @conn.connected?
          log_msg "Error: " + $!, true
          log_error($!, entry)

        ensure

        end
      end
    rescue
      log_error $!
      #log_msg$!,true
      puts "Outbox processing failed. Reason: " + $!
    ensure
      #log_msg"cleaning up: disconnecting from datasources..."
      @conn.disconnect if @conn && @conn.connected?
      @intrack_conn.disconnect if @intrack_conn && @intrack_conn.connected?
      @personnell_conn.disconnect if @personnell_conn && @personnell_conn.connected?
      puts "disconnect gf"
      ActiveRecord::Base.connection.disconnect!()
      ActiveRecord::Base.remove_connection
      #@logger.close if @logger
      #log_msg"cleaned up!"
    end
  end

  #==================
  #INTEGRATION FLOWS:
  #==================

  def carton_new(entry)
    #log_msg"in new"
    record_map = eval entry.record
    create_carton_util(record_map)

  end

  def rw_carton_new(entry)
    #log_msg"in rw carton new"
    record_map = eval entry.record
    connect_to_kromco_personnell_data
    create_carton_util(record_map, true, "Carton")

  end


  def exec_query(query, connection = nil)
    conn = @conn
    conn = connection if connection

    conn.prepare(query) do |sth|
      sth.execute
    end

  end


  def kromco_intake_accepted(entry)

    record_map = eval entry.record
    representative_pallet = Pallet.find_by_pallet_number(record_map[:representative_pallet_number])
    representative_carton = Carton.find_by_carton_number(record_map[:representative_carton_number].to_i)

    total_ctns_query = "select count(*) from cartons inner join pallets on (cartons.pallet_id = pallets.id) where pallets.consignment_note_number = '#{record_map[:consignment_note_number]}'"
    total_carton_count = Pallet.connection.select_one(total_ctns_query)['count']
    total_pallets_query = "select count(*) from pallets  where pallets.consignment_note_number = '#{record_map[:consignment_note_number]}'"
    total_pallets_count = Pallet.connection.select_one(total_pallets_query)['count']
    ppecb_inspection =  representative_pallet.ppecb_inspection

    query = "insert into Intake_Consignment
          (
          Account,
          Account_int,
          Arrival_Date,
          Arrival_Time,
          Batch_Eval_Quantity, 
          Bill_Of_Entry_Number,
          Cape_Integration_PI,
          Carrier,
          Carton_Quantity_Doc,
          Carton_Quantity_On_Truck,
          Channel,
          Client_Ref,
          Client_Reference,
          Dispatch_Process_Indicator,
          Document_Date,
          Document_Number,
          Document_Status,
          Document_Type,
          Endorse1,
          Endorse2,
          Endorse3,
          Endorse4,
          Evaluation_FROM_No,
          Evaluation_TO_Number,
          Farm_ind,
          From_Location_Code,
          From_Location_Type,
          Full_Pallet_Document,
          Fully_Loaded,
          Handling_Point,
          Inc_Pallet_Document,
          Inspection,
          Inspection_Point,
          Inspection_Report,
          Inspection_Time,
          Inspector,
          Inspector_Flag,
          Instruction_Type,
          Load_Id,
          Load_Name,
          Load_Reference,
          Load_Type,
          Location_Code,
          Location_Type,
          Master_Order_Number,
          Message_Number,
          Orchard,
          Order_No,
          Organization,
          Original_Intake_Date,
          Original_Intake_Depot,
          Pallet_Base_Type,
          Pallet_Quantity_Doc,
          Pallet_Quantity_On_Truck,
          Parent_Farm,
          PhytoWaybill,
          PI, Rail_Date,
          Record_Type,
          Reference_Number,
          Revision_Number,
          Season,
          SellByCode,
          Ship_Number,
          Temperature,
          Temperature1,
          Temperature2,
          Temperature3,
          Temperature4,
          Transaction_Date,
          Transaction_Time,
          Transaction_User,
          Transmission_Flag,
          Transport_Type,
          Trip_Number,
          Truck_Level,
          Truck_Number,
          Truck_Type
          )
          values (
           '#{representative_pallet.account_code}' ,
           1 ,
           '#{record_map[:created_on]}' ,
           '#{record_map[:created_on]}' ,
           '' ,
           '' ,
           1 ,
           'OWN' ,
           #{total_carton_count} ,
           #{total_carton_count} ,
           'E' ,
           '' ,
           '' ,
           '' ,
           '#{record_map[:created_on]}' ,
            '#{record_map[:consignment_note_number]}' ,
           'G' ,
           '#{record_map[:intake_type_code]}' ,
           '' ,
           '' ,
           '' ,
           '' ,
           '' ,
           '' ,
           1 ,
           'KROMCO' ,
           'DP' ,
           #{total_carton_count} ,
           '' ,
           '' ,
           0 ,
           '#{representative_pallet.inspect_type_code}' ,
           '#{record_map[:inspection_point]}' ,
           '' ,
           '#{ppecb_inspection.created_at.strftime("%d/%b/%Y %H:%M:%S")}' ,
            '#{record_map[:inspector_number]}' ,
           'Y' ,
           '' ,
           '#{record_map[:consignment_note_number]}' ,
           '' ,
           'KROMCO' ,
           'S' ,
           'KROMCO' ,
           'DP' ,
           '' ,
           0 ,
           '' ,
           '#{record_map[:order_number]}' ,
           '#{representative_pallet.organization_code}' ,
           '#{record_map[:created_on]}' ,
           'KROMCO' ,
           '' ,
           #{total_pallets_count} ,
           #{total_pallets_count} ,
           '#{representative_carton.puc}' ,
           '#{record_map[:phytowaybill]}' ,
           0 ,
           '#{record_map[:created_on]}' ,
           'IC' ,
           '#{record_map[:order_number]}' ,
           '#{record_map[:revision_number]}' ,
           '#{representative_pallet.season_code}' ,
           '#{representative_carton.sell_by_code}' ,
           '' ,
           '99.99' ,
           '99.99' ,
           '99.99' ,
           '99.99' ,
           '99.99' ,
           '#{record_map[:created_on]}' ,
           '#{record_map[:created_on]}' ,
           'KROMCO' ,
           'N' ,
           'T' ,
           '' ,
           'P' ,
           'KROMCO' ,
           'F')"

    puts query
    @conn.do(query)

    consignment_pallets = Pallet.find_all_by_consignment_note_number(record_map[:consignment_note_number])
    for cons_pallet in consignment_pallets
      cons_query = "update pallet
	                set
                    consignment_note_no='#{record_map[:consignment_note_number]}',
                     intake_consignment_id='#{record_map[:consignment_note_number]}'
	                 where pallet_id='#{cons_pallet.pallet_number}'"

      @conn.do(cons_query)
    end


  end


  def create_depot_carton(record_map, is_reworks_carton = nil, carton_table_name = nil, pallet = nil)
    #puts "NEW CREATE VERSION"
    #log_msg"creating carton: " + record_map[:carton_number].to_s
    #------------------------------------------------------
    #additional lookups- not already mapped on cartn record
    #------------------------------------------------------
    label_station = ""
    brand = Mark.find_by_mark_code(record_map[:carton_mark_code]).brand_code
    cosmetic_code = FgProduct.find_by_fg_product_code(record_map[:fg_product_code]).item_pack_product.cosmetic_code_name
    standard_size_count = FgProduct.find_by_fg_product_code(record_map[:fg_product_code]).item_pack_product.standard_size_count_value
    short_long_variety = record_map[:variety_short_long]
    short_long_variety = short_long_variety.slice(0..14) if short_long_variety.length > 15
    erp_cultivar = record_map[:erp_cultivar]
    if erp_cultivar.length > 15
      #  puts "CULTIVAR ABOUT TO BE SLICED"
      erp_cultivar = erp_cultivar.slice(0..14)
    end

    #puts "CULTIVAR IS: '#{erp_cultivar}'"

    class_record = ProductClass.find_by_product_class_code(record_map[:product_class_code])
    class_descr = class_record.product_class_description if class_record && class_record.product_class_description
    class_descr = record_map[:product_class_code] if !class_descr
    run =
            farm_code = ""
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
	 [Pallet_Sequence_Number],extended_fg_code,standard_size_count_value,
	 [Qc_Status_Code],[Qc_Result_Status],[Sell_By_Code])

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
	 '1','#{record_map[:extended_fg_code]}',#{standard_size_count},
	 '#{record_map[:qc_status_code]}','#{record_map[:qc_result_status]}',
	 '#{record_map[:sell_by_code]}')"

    #execute
    #log_msg query,nil,true
    @conn.do(query)

    #log_msg"carton create."
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


    #log_msg"creating activity log record"
    @personnell_conn.do(pers_query)
    #log_msg"activity log record created."

  end

  def create_carton_util(record_map, is_reworks_carton = nil, carton_table_name = nil)
    #puts "NEW CREATE VERSION"
    #log_msg"creating carton: " + record_map[:carton_number].to_s
    #------------------------------------------------------
    #additional lookups- not already mapped on cartn record
    #------------------------------------------------------
    label_station_rec = CartonLabelStation.find_by_ip_address(record_map[:carton_label_station_code])
    label_station=""
    label_station =  label_station_rec.carton_label_station_code if label_station_rec
    #the label station code stored on carton is the runtime ip address
    brand = Mark.find_by_mark_code(record_map[:carton_mark_code]).brand_code
    cosmetic_code = FgProduct.find_by_fg_product_code(record_map[:fg_product_code]).item_pack_product.cosmetic_code_name
    standard_size_count = FgProduct.find_by_fg_product_code(record_map[:fg_product_code]).item_pack_product.standard_size_count_value
    short_long_variety = record_map[:variety_short_long]
    short_long_variety = short_long_variety.slice(0..14) if short_long_variety.length > 15
    erp_cultivar = record_map[:erp_cultivar]
    if erp_cultivar.length > 15
      #  puts "CULTIVAR ABOUT TO BE SLICED"
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
	 [Pallet_Sequence_Number],extended_fg_code,standard_size_count_value,
	 [Qc_Status_Code],[Qc_Result_Status],[Sell_By_Code])

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
	 '1','#{record_map[:extended_fg_code]}',#{standard_size_count},
	 '#{record_map[:qc_status_code]}','#{record_map[:qc_result_status]}',
	 '#{record_map[:sell_by_code]}')"

    #puts query
#execute
    #log_msg query,nil,true
    @conn.do(query)

    #log_msg"carton create."
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


    #log_msg"creating activity log record"
    @personnell_conn.do(pers_query)
    #log_msg"activity log record created."

  end


  def exec_intrack_command(command)
    #log_msg"sending intrack command: " + @@intrack_base_cmd + command
    if @current_entry
      if !@current_entry.intrack_cmd
        @current_entry.intrack_cmd = command
      else
        @current_entry.intrack_cmd += command
      end
    end

    if result = system(@@intrack_base_cmd + command)
      @current_entry.intrack_cmd += " result: " + result.to_s + "; \n" if @current_entry
      #log_msg"intrack transaction succeeded"
    else
      #log_msg"intrack transaction failed"
      @current_entry.intrack_cmd += " result: null; \n"
      raise "The intrack command failed. Command_text was: " + command if @current_entry
    end
  end

  def pallet_update(entry)
    #----------------------------------------
    #INTRACK: move(into reworks), then create
    #----------------------------------------

    record_map = eval entry.record

    #-------------------------------
    #return if pallet has no cartons
    #-------------------------------
    count_query = "select count(*) as ctn_count from cartons where pallet_number = '#{record_map[:pallet_number]}'"
    puts count_query
    return if Pallet.connection.select_one(count_query)['ctn_count'].to_s == "0"
    puts "passed"

    pfp = PalletFormatProduct.find_by_pallet_format_product_code(record_map[:pallet_format_product_code])
    pallet_base = pfp.pallet_base.description
    pallet_format = pfp.stack_type.description
    brand = Mark.find_by_mark_code(record_map[:carton_mark_code]).brand_code
    marketing_variety_description = MarketingVariety.find_by_marketing_variety_code_and_commodity_code(record_map[:marketing_variety_code], record_map[:commodity_code]).marketing_variety_description.to_s
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

    rw_run_id = RwReceiptPalletsHistory.find_by_pallet_id(record_map[:id].to_i).rw_run_id
    is_reworks_run = nil
    is_reworks_run = true if RwRun.find(rw_run_id).rw_run_type_code.upcase.index("REWORKS")

    sell_by = get_sell_by_for_pallet(record_map[:id])

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
	 [remark] = '#{record_map[:remark]}',
	 [Qc_Status_Code] = '#{record_map[:qc_status_code]}',
	 [Sell_By_Code]= '#{sell_by}',
	 [Qc_Result_Status] = '#{record_map[:qc_result_status]}'
	 WHERE
	 (Pallet_Id = '#{record_map[:pallet_number]}')"


    #log_msg query,nil,true
    @conn.do(query)
    #GERRIT WAS UITGECOMMENT WEER TERUG GESIT AGV VELDE WAT NIE VANAF TRIGGERS OPDATUM GEBRING WORD NIE.

    #move is only relevant for reworks
    if is_reworks_run
      intrack_cmd = "move " + record_map[:pallet_number] + " REWORKS " + record_map[:carton_quantity_actual]
      #exec_intrack_command(intrack_cmd)
    end

  end


  def get_sell_by_for_pallet(pallet_id)

    #query = "select sell_by_code from cartons where pallet_id = #{pallet_id} order by id asc limit 1 "
    #Postgres ignore index, query quicker retruning all records without limit 1
    query = "select sell_by_code from cartons where pallet_id = #{pallet_id} order by id asc "
    #log_msg query,nil,true
    #  return Carton.connection.select_one(query)['sell_by_code']
    #
    return Carton.connection.select_all(query)[0]['sell_by_code']
  end

  #select_all

  def depot_pallet_new(pallet, header)

    #----------------------------------------
    #INTRACK: move(into reworks), then create
    #----------------------------------------

    #production_schedule = consignment note, location = header's location , depot_indicator
    puts "depot_pallet_new-record_map"
    record_map = record_to_map(pallet)

    pfp = PalletFormatProduct.find(record_map[:pallet_format_product_id].to_i)
    pallet_base = pfp.pallet_base.description
    pallet_format = pfp.stack_type.description
    brand = Mark.find_by_mark_code(record_map[:carton_mark_code]).brand_code
    marketing_variety_description = MarketingVariety.find_by_marketing_variety_code_and_commodity_code(record_map[:marketing_variety_code], record_map[:commodity_code]).marketing_variety_description.to_s
    variety_short_long = record_map[:marketing_variety_code] + "_" + marketing_variety_description

    oldest_carton = pallet.get_oldest_carton

    puc =  oldest_carton.puc

    variety_short_long = variety_short_long.slice(0..14) if variety_short_long.length > 15


    season = pallet.season_code
    erp_cultivar = record_map[:erp_cultivar]
    if erp_cultivar.length > 15
      erp_cultivar = erp_cultivar.slice(0..14)
    end

    sell_by = get_sell_by_for_pallet(record_map[:id])

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
	 [Order_No],[Qc_Status_Code],[Qc_Result_Status],[Sell_By_Code])

VALUES
	( '#{record_map[:pallet_number].to_s}',
	 '#{record_map[:fg_code_old]}',
	 '#{record_map[:process_status]}',
	 '#{record_map[:cold_store_code]}',
	 '1',
	 null,
	 '#{header.consignment_note_number.to_s}',
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
	 #{header.consignment_note_number.to_s},
	 '0',
	 null,
	 null,
	 null,
	 null,
	 '0',
	 1,
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
	 null,
	 '#{record_map[:qc_status_code]}',
	 '#{record_map[:qc_result_status]}','#{sell_by}')"

    puts query
    @conn.do(query)


  end

  def pallet_new(entry, is_completed = nil)

    #----------------------------------------
    #INTRACK: move(into reworks), then create
    #----------------------------------------

    record_map = eval entry.record
    pfp = PalletFormatProduct.find(record_map[:pallet_format_product_id].to_i)
    pallet_base = pfp.pallet_base.description
    pallet_format = pfp.stack_type.description

    load_no = record_map[:load_no]
    load_no = nil if load_no == ""

    if load_no
      load_no = "\'#{load_no}\'"
    else
      load_no = "null"
    end
    brand = Mark.find_by_mark_code(record_map[:carton_mark_code]).brand_code
    marketing_variety_description = MarketingVariety.find_by_marketing_variety_code_and_commodity_code(record_map[:marketing_variety_code], record_map[:commodity_code]).marketing_variety_description.to_s
    variety_short_long = record_map[:marketing_variety_code] + "_" + marketing_variety_description
    puc = ProductionRun.find(record_map[:production_run_id].to_i).puc_code.to_s

    variety_short_long = variety_short_long.slice(0..14) if variety_short_long.length > 15

    run = ProductionRun.find(record_map[:production_run_id].to_i)
    season = Season.find_by_season_code(run.production_schedule.season_code).season.to_s
    erp_cultivar = record_map[:erp_cultivar]
    if erp_cultivar.length > 15
      erp_cultivar = erp_cultivar.slice(0..14)
    end

    sell_by = get_sell_by_for_pallet(record_map[:id])

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
	 
	 [Holdover],
	 [Memo_Line_No],
	 [Delivery_No],
	 [Order_No],[Qc_Status_Code],[Qc_Result_Status],[Sell_By_Code])

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
	 '#{record_map[:qc_status_code]}',
	 '#{record_map[:qc_result_status]}','#{sell_by}')"


    @conn.do(query)


    if !is_completed #move is only relevant for reworks
      trans_id = nil
      trans_name = "REWORKS"
      location_code = "REWORKS"


      if record_map[:location_code] && record_map[:location_code].to_s != ""
        trans_name = "buildup_create_pallet"
        location_code = record_map[:location_code]
      else
        rw_pallet =  RwPallet.find_by_pallet_number(record_map[:pallet_number], :order=>"id DESC")
        trans_id = rw_pallet.rw_run_id.to_s if rw_pallet
      end
      intrack_cmd = "create " + record_map[:pallet_number] + " PALLET " + record_map[:carton_quantity_actual] +  " " + location_code
      exec_intrack_command(intrack_cmd)

      Inventory.create_stock(nil, "PALLET", nil, nil, trans_name, trans_id, location_code, [record_map[:pallet_number]])
      #intrack_cmd = "move " + record_map[:pallet_number] + " REWORKS " + record_map[:carton_quantity_actual]

      #exec_intrack_command(intrack_cmd)

    end

  end

  def carton_reclassified(entry)

    record_map = eval entry.record
    #------------------------------------------------------
    #additional lookups- not already mapped on cartn record
    #------------------------------------------------------
    label_station = CartonLabelStation.find_by_ip_address(record_map[:carton_label_station_code]).carton_label_station_code #the label station code stored on carton is the runtime ip address
    brand = Mark.find_by_mark_code(record_map[:carton_mark_code]).brand_code
    cosmetic_code = FgProduct.find_by_fg_product_code(record_map[:fg_product_code]).item_pack_product.cosmetic_code_name
    standard_size_count = FgProduct.find_by_fg_product_code(record_map[:fg_product_code]).item_pack_product.standard_size_count_value
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
	 [Pack_Date]	 = '#{record_map[:pack_date_time]}',
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
     [standard_size_count_value]	 = #{standard_size_count},
     [extended_fg_code]	 = '#{record_map[:extended_fg_code]}',
	 [PT_From_Location]	 = '#{record_map[:puc]}',
	 [Pallet_Sequence_Number]	 = '1',
	 [Sell_By_Code] = '#{record_map[:sell_by_code]}'

     WHERE
	( [Carton_ID]	 = '#{record_map[:carton_number].to_s}')"

    #execute
    log_msg query, nil, true
    @conn.do(query)


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
      #G Fouche 13/01/2010 interwarehouse kan dit skep
      # connect_to_kromco_personnell_data
      #log_msg"connected to personnell db"
      # create_carton_util(record_map,true,"Carton")
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
	       [Pallet_ID]	 = 'REWORKS',
	       [Exit_Reference] = 'Scrap',
	       [Exit_Date]= '#{entry.friendly_date}'
	        WHERE
	        ( [Carton_ID]	 = '#{record_map[:carton_number].to_s}')"

      end

      #execute
      #log_msg query, nil,true
      @conn.do(query)
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
    @conn.do(query)

  end


  def log_msg(msg, is_error = nil, is_debug = nil)
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
        #log_msg"Pallet: " + pallet_number + " exists in Kromco data, no pallet_complete transaction will be done."
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
        #log_msg"Carton: " + carton_number + " exists in Kromco data."
        return true
      else
        #log_msg"Carton: " + carton_number + " does not exist in Kromco data."
        return false
      end
    ensure
      new_conn.disconnect if new_conn && new_conn.connected?
    end

  end

  def pallet_completed(entry)
    #----------------------------------------------------
    #This is the flow created by palletizing. Since we moved the point of integration forward to first oflload vehicle I/W, the flow is disabled- IW will
    #call pallet_completed_1
    #-----------------------------------------------------
  end

  def pallet_exist_in_intrack?(pallet_num)

    query = "select lotid  from lotbaselog where lotid='#{pallet_num}'"
    connect_to_intrack_data
    if @intrack_conn.select_one(query)
      return true
    else
      return false
    end

  end


  def create_kromco_intake_consignment(intake_header, header_map)
    #-----------------------------------
    #questions:
    #           -> intake_headers.DP?
    #--------------------------------------
    query = "insert into Intake_Consignment
      (Account, Account_int, Arrival_Date, Arrival_Time, Batch_Eval_Quantity, Bill_Of_Entry_Number, Cape_Integration_PI, Carrier, Carton_Quantity_Doc, Carton_Quantity_On_Truck, Channel, Client_Ref, Client_Reference, Dispatch_Process_Indicator, Document_Date, Document_Number, Document_Status, Document_Type, Endorse1, Endorse2, Endorse3, Endorse4, Evaluation_FROM_No, Evaluation_TO_Number, Farm_ind, From_Location_Code, From_Location_Type, Full_Pallet_Document, Fully_Loaded, Handling_Point, Inc_Pallet_Document, Inspection, Inspection_Point, Inspection_Report, Inspection_Time, Inspector, Inspector_Flag, Instruction_Type, Load_Id, Load_Name, Load_Reference, Load_Type, Location_Code, Location_Type, Master_Order_Number, Message_Number, Orchard, Order_No, Organization, Original_Intake_Date, Original_Intake_Depot, Pallet_Base_Type, Pallet_Quantity_Doc, Pallet_Quantity_On_Truck, Parent_Farm, PhytoWaybill, PI, Rail_Date, Record_Type, Reference_Number, Revision_Number, Season, SellByCode, Ship_Number, Temperature, Temperature1, Temperature2, Temperature3, Temperature4, Transaction_Date, Transaction_Time, Transaction_User, Transmission_Flag, Transport_Type, Trip_Number, Truck_Level, Truck_Number, Truck_Type)
        values (
         '#{intake_header.account_code}' ,
         1 ,
         '#{header_map[:created_on]}' ,
         '#{header_map[:created_on]}' ,
         '' ,
         '' ,
         0 ,
         '#{intake_header.carrier.to_s}' ,
         #{intake_header.qty_cartons.to_s} ,
         '#{intake_header.qty_cartons.to_s}' ,
         '#{intake_header.channel.to_s}' ,
         '' ,
         '' ,
         0 ,
         '#{header_map[:created_on]}' ,
         '#{intake_header.consignment_note_number}' ,
         'G' ,
         '#{intake_header.inspection_type_code}' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         1 ,
         'KROMCO' ,
         'DP' ,
         #{intake_header.qty_cartons.to_s} ,
         '' ,
         '' ,
         0 ,
         '#{intake_header.inspection_type_code.to_s}' ,
         '#{intake_header.inspection_point.to_s}' ,
         '' ,
         '#{intake_header.inspection_date.to_s}' ,
         '#{intake_header.inspector_number.to_s}' ,
         'Y' ,
         '' ,
         '#{intake_header.consignment_note_number.to_s}' ,
         '' ,
         'KROMCO' ,
         'S' ,
         'KROMCO' ,
         'DP' ,
         '' ,
         '0' ,
         '' ,
         '#{intake_header.order_number}' ,
         '#{intake_header.organization_code}' ,
         '#{header_map[:created_on]}' ,
         'KROMCO' ,
         '' ,
         #{intake_header.qty_pallets.to_s} ,
         #{intake_header.qty_pallets.to_s} ,
         '#{intake_header.puc_code}' ,
         '#{intake_header.phytowaybill}' ,
         0 ,
         '#{header_map[:created_on]}' ,
         'IC' ,
         '#{intake_header.order_number}' ,
         1 ,
         #{intake_header.season.to_s} ,
         '#{intake_header.sell_by_code}' ,
         '' ,
         '99.99' ,
         '99.99' ,
         '99.99' ,
         '99.99' ,
         '99.99' ,
         '#{header_map[:created_on]}' ,
         '#{header_map[:created_on]}' ,
         'KROMCO' ,
         'N' ,
         'T' ,
         '' ,
         'P' ,
         'KROMCO' ,
         'F'
        )"

    @conn.do(query)
    puts "Intake_Consignment"
    query = "insert into Depot_Pallet_Receipts_OC
        (Account, Allow_Code, Allow_Del, Batch, Channel, Client_Ref, Cnts_On_truck, Cons_Count, Cons_Date, Cons_No, Cons_Status, Cons_Type, Ctn_Qty, Dest_Code, Dest_Type, Endorse1, Endorse2, Endorse3, Endorse4, Full_Pallet, Grower_Alloc, Inc_Pallet, Kromco_Revision, Liner_Bd, Load_Id, Locn_Code, Mesg_No, Mix_Cnt_pals, Order_No, Orgzn, Pallet_Btype, Pals_Damage, Pals_Sundry, Pals_Unstable, Plas_Cover, Plt_Qty, Pro_No, Receipt_ID, Record_Type, Repack_Flag, Revision, Season, Spoor_Load, Temperature, Tran_Date, Tran_Time, Tran_User, Xmit_Flag)
        values (
         '#{intake_header.account_code}' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '#{intake_header.qty_cartons.to_s}' ,
         '' ,
         '#{intake_header.season.to_s}' ,
         '#{intake_header.consignment_note_number}' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         0 ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '' ,
         '#{intake_header.qty_pallets.to_s}' ,
         '' ,
         '' ,
         'OC' ,
         '' ,
         '0' ,
         '#{intake_header.season.to_s}' ,
         '' ,
         '99.9' ,
         '' ,
          '#{intake_header.season.to_s}',
         '' ,
         'N' ) "


    @conn.do query
    puts "Depot_Pallet_Receipts_OC"
    create_kromco_pallet_sequences(intake_header, header_map)

  end


  def create_kromco_pallet_sequences(intake_header, header_map)

    mapped_pallet_sequences = MappedPalletSequence.find_all_by_intake_header_id(intake_header.id)

    for mapped_pallet_sequence in mapped_pallet_sequences

      record_map = record_to_map(mapped_pallet_sequence)
      commodity_group = Commodity.find_by_commodity_code(mapped_pallet_sequence.commodity).commodity_group_code

      query = "insert into DEPOT_PALLET_RECEIPTS
                (Act_Var, Agent, Channel, Combo_Pallet_id, Comm_Grp, Commodity, Cons_No, Cont_Split, Container, Country, Ctn_Qty, Dest_Locn, Dest_Type, Expiry, Farm, File_Status, Grade, GTIN, Intake_Date, Inv_Code, Load_Id, Locn_Code, Mark, Mesg_No, Mixed_Ind, Order_No, Orgzn, Orig_Cons, Orig_Depot, Orig_Intake, Pack, Pallet_Btype, Pallet_Error, Pallet_Id, Pick_Ref, Plt_Qty, Position, Prod_Char, Prod_Grp, Reason, Receipt_ID, Record_Type, Remarks, Revision, SellByCode, Sender, Seq_No, Shift, Shift_Date, Ship_Agent, Ship_Number, Ship_Sender, Shipped_Date, Size_Count, Stock_Pool, Store, Sub_Var, Targ_Mkt, Temp_Device_id, Temp_Device_type, Temperature, Tran_Date, Tran_Time, Tran_User, Unit_Type, Var_Grp, Variety, WayBill_Code, Xmit_Flag)
                values (
                 '' ,
                 '' ,
                 '#{mapped_pallet_sequence.channel}' ,
                 '' ,
                 '#{commodity_group}' ,
                 '#{mapped_pallet_sequence.commodity}' ,
                  '#{intake_header.consignment_note_number}' ,
                 'N' ,
                 '' ,
                 'ZA' ,
                 #{mapped_pallet_sequence.seq_ctn_qty.to_s} ,
                 '' ,
                 'DP' ,
                 '' ,
                 '#{mapped_pallet_sequence.puc}' ,
                 'COMPLETE' ,
                 '#{mapped_pallet_sequence.grade}' ,
                 '' ,
                 '' ,
                 '#{mapped_pallet_sequence.inventory_code}' ,
                 '' ,
                 '' ,
                 '#{mapped_pallet_sequence.brand}' ,
                 '' ,
                 '' ,
                 '' ,
                 '#{mapped_pallet_sequence.organization}',
                 '' ,
                 '' ,
                 '' ,
                 '#{mapped_pallet_sequence.pack_type}' ,
                 '' ,
                 0 ,
                 '#{mapped_pallet_sequence.depot_pallet_number.to_s}' ,
                 '#{mapped_pallet_sequence.pick_reference}' ,
                 1 ,
                 '' ,
                 '' ,
                 '' ,
                 '' ,
                 '#{mapped_pallet_sequence.intake_header_id.to_s}' ,
                 'OP' ,
                 '' ,
                 '0' ,
                 '' ,
                 '' ,
                 '#{mapped_pallet_sequence.pallet_sequence_number.to_s}'  ,
                 '' ,
                 '' ,
                 '' ,
                 '' ,
                 '' ,
                 '' ,
                 '#{mapped_pallet_sequence.count}' ,
                 '' ,
                 '' ,
                 '' ,
                 '#{mapped_pallet_sequence.target_market}' ,
                 '' ,
                 '' ,
                 99.99 ,
                 '#{record_map['captured_date_time']}' ,
                 '' ,
                 '' ,
                 'P' ,
                 '' ,
                 '#{mapped_pallet_sequence.variety}' ,
                 '' ,
                 '' )"

      puts query
      @conn.do query
      puts "insert into DEPOT_PALLET_RECEIPTS"
    end


  end


  def receive_intake_header(entry)

    record_map = eval entry.record

    header = IntakeHeader.find(record_map[:id].to_i)
    create_kromco_intake_consignment(header, record_map)
    pallets = Pallet.find_all_by_consignment_note_number(header.consignment_note_number)
    puts "n pallets: " + pallets.length().to_s
    raise "no pallets found for consignment: " + header.consignment_note_number if pallets.length() == 0
    for pallet in pallets
      receive_depot_pallet(pallet, header)
    end


  end


  def receive_depot_pallet(pallet, header)
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


    location = header.location_code
    location = "" if !location

    if kromco_pallet_exists?(pallet.pallet_number.to_s)== true
      puts "PALLET: " + pallet.pallet_number.to_s + " EXISTS"

      #production_schedule = consignment note, location = header's location , depot_indicator

      #intrack_cmd = "move " + record_map[:pallet_number] + " " +  location + " " + record_map[:carton_quantity_actual]
      #  intrack_cmd = "create " + record_map[:pallet_number] + " PALLET " + record_map[:carton_quantity_actual] + " " + location
      # exec_intrack_command(intrack_cmd)


      if !pallet_exist_in_intrack?(pallet.pallet_number.to_s)
        intrack_cmd = "create " + pallet.pallet_number.to_s + " PALLET " + pallet.pallet_number.to_s + " " + location
        puts "PALLET: " + pallet.pallet_number.to_s + " does not exist in intrack. Will be created"
        puts intrack_cmd

        Inventory.create_stock(nil, "PALLET", nil, nil, "DEPOT_RECEIPTS", header.consignment_note_number.to_s, location, [pallet.pallet_number.to_s])
      else


        intrack_cmd = "move " + pallet.pallet_number.to_s + " " + location + " " + pallet.pallet_number.to_s
        puts intrack_cmd

        Inventory.move_stock("DEPOT_RECEIPTS", header.consignment_note_number, location, [pallet.pallet_number.to_s])

        puts "PALLET: " + pallet.pallet_number.to_s + " exist in intrack. Will be created"
      end
      exec_intrack_command(intrack_cmd)
      puts intrack_cmd
      return
    end

    puts "PALLET: " + pallet.pallet_number.to_s + " DOES NOT EXISTS"


    #-------------------------------
    #return if pallet has no cartons
    #-------------------------------
    count_query = "select count(*) as ctn_count from cartons where pallet_number = '#{pallet.pallet_number.to_s}'"
    puts count_query
    return if Pallet.connection.select_one(count_query)['ctn_count'].to_s == "0"


    log_msg "connecting to personnell db..."
    connect_to_kromco_personnell_data
    log_msg "connected to personnell db"
    begin

      @personnell_conn['AutoCommit'] = false


      log_msg "creating depot pallet..."
      depot_pallet_new(pallet, header)
      log_msg "kromco pallet created"


      #pallet.cartons.each do |carton|
      #log_msg"creating depot carton(" + carton.id.to_s + ")..."
      #create_carton_util(record_to_map(carton),false,"Carton_Palletising")
      #log_msg"carton created."1
      #end

      #puts "cartons created"

      #copy_query = "Insert into carton select * from Carton_Palletising NOLOCK where pallet_id = '#{record_map[:pallet_number]}'"
      #log_msg copy_query,nil,true
      #@conn.do(copy_query)

      #delete_query = "delete from Carton_Palletising where pallet_id = '#{record_map[:pallet_number]}'"
      #log_msgdelete_query,nil,true
      #@conn.do(delete_query)

      #---------------------------------------------------------------
      #If record exists in intrack, do move, else do create
      #---------------------------------------------------------------
      if !pallet_exist_in_intrack?(pallet.pallet_number)
        intrack_cmd = "create " + pallet.pallet_number + " PALLET " + pallet.carton_quantity_actual.to_s+ " " + location
        puts "PALLET: " + pallet.pallet_number + " does not exist in intrack. Will be created"
      else

        intrack_cmd = "create " + pallet.pallet_number + " PALLET " + pallet.carton_quantity_actual.to_s + " " + location
        puts "PALLET: " + pallet.pallet_number + " does not exist in intrack. Will be created"
      end
      exec_intrack_command(intrack_cmd)

      Inventory.create_stock(nil, "PALLET", nil, nil, "depot_receipts", header.consignment_note_number.to_s, location, [pallet.pallet_number.to_s])

      @personnell_conn.commit
      @personnell_conn['AutoCommit'] = true

    rescue
      @personnell_conn.rollback if @personnell_conn && @personnell_conn.connected?
      @personnell_conn.disconnect if @personnell_conn && @personnell_conn.connected?
      raise $!
    end

  end

  def pallet_completed_1(entry)
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

    location = ""
    location = record_map[:location_code] if record_map[:location_code]
    puts "LOCATION: " + location

    if kromco_pallet_exists?(record_map[:pallet_number])== true
      puts "PALLET: " + record_map[:pallet_number] + " EXISTS"

      #production_schedule = consignment note, location = header's location , depot_indicator

      #intrack_cmd = "move " + record_map[:pallet_number] + " " +  location + " " + record_map[:carton_quantity_actual]
      #  intrack_cmd = "create " + record_map[:pallet_number] + " PALLET " + record_map[:carton_quantity_actual] + " " + location
      # exec_intrack_command(intrack_cmd)


      if !pallet_exist_in_intrack?(record_map[:pallet_number])
        intrack_cmd = "create " + record_map[:pallet_number] + " PALLET " + record_map[:carton_quantity_actual] + " " + location
        puts "PALLET: " + record_map[:pallet_number] + " does not exist in intrack. Will be created"
        puts intrack_cmd
        trans_id =  record_map[:production_run_id]
        Inventory.create_stock(nil, "PALLET", nil, nil, "palletizing", trans_id, location, [record_map[:pallet_number]])
      else


        intrack_cmd = "move " + record_map[:pallet_number] + " " + location + " " + record_map[:carton_quantity_actual]
        puts intrack_cmd

        Inventory.move_stock("palletizing", record_map[:production_run_id], location, [record_map[:pallet_number]])

        puts "PALLET: " + record_map[:pallet_number] + " exist in intrack. Will be created"
      end
      exec_intrack_command(intrack_cmd)
      puts intrack_cmd
      return
    end

    puts "PALLET: " + record_map[:pallet_number] + " DOES NOT EXISTS"

    pallet = Pallet.find(record_map[:id].to_i)


    #-------------------------------
    #return if pallet has no cartons
    #-------------------------------
    count_query = "select count(*) as ctn_count from cartons where pallet_number = '#{pallet.pallet_number}'"
    return if Pallet.connection.select_one(count_query)['ctn_count'].to_s == "0"


    #log_msg"connecting to personnell db..."
    connect_to_kromco_personnell_data
    #log_msg"connected to personnell db"
    begin

      @personnell_conn['AutoCommit'] = false


      parent_run_id = nil
      parent_run_code = nil

      run = ProductionRun.find(pallet.production_run_id)

      if run.parent_run_code
        parent_run = ProductionRun.find_by_production_run_code(run.parent_run_code)
        parent_run_id = parent_run.id
        parent_run_code = run.parent_run_code
      end

      pallet.production_run_id = parent_run_id if parent_run_id

      log_msg "creating kromco pallet..."
      pallet_new(entry, true)
      log_msg "kromco pallet created"

      parent_run_id = nil
      parent_run_code = nil
      run = nil

      pallet.cartons.each do |carton|
        run = ProductionRun.find(carton.production_run_id)
        if run.parent_run_code
          parent_run = ProductionRun.find_by_production_run_code(run.parent_run_code)
          parent_run_id = parent_run.id
          parent_run_code = run.parent_run_code
        end
        if parent_run_id
          station_code = carton.carton_pack_station_code
          num = station_code.slice(1..2).to_i + 50
          new_station_code = station_code.slice(0..0) + num.to_s + station_code.slice(3..4)

          if num > 99
            entry.process_status = 50
            raise "invalid carton pack station: " + new_station_code + " for carton: " + carton.carton_number.to_s
          end
          carton.carton_pack_station_code = new_station_code
          carton.production_run_id = parent_run_id
          carton.production_run_code = parent_run_code
        end
        #log_msg"creating pallet carton(" + carton.id.to_s + ")..."
        create_carton_util(record_to_map(carton), false, "Carton_Palletising")
        #log_msg"carton created."
      end

      puts "cartons created"

      copy_query = "Insert into carton select * from Carton_Palletising NOLOCK where pallet_id = '#{record_map[:pallet_number]}'"
      #log_msg copy_query,nil,true
      @conn.do(copy_query)

      delete_query = "delete from Carton_Palletising where pallet_id = '#{record_map[:pallet_number]}'"
      #log_msgdelete_query,nil,true
      @conn.do(delete_query)

      #---------------------------------------------------------------
      #If record exists in intrack, do move, else do create
      #---------------------------------------------------------------
      if !pallet_exist_in_intrack?(record_map[:pallet_number])
        intrack_cmd = "create " + record_map[:pallet_number] + " PALLET " + record_map[:carton_quantity_actual] + " " + location
        puts "PALLET: " + record_map[:pallet_number] + " does not exist in intrack. Will be created"
      else
        #intrack_cmd = "move " + record_map[:pallet_number] + " " +  location + " " + record_map[:carton_quantity_actual]
        #puts "PALLET: " + record_map[:pallet_number] + " exists in intrack. Will only be moved"
        intrack_cmd = "create " + record_map[:pallet_number] + " PALLET " + record_map[:carton_quantity_actual] + " " + location
        puts "PALLET: " + record_map[:pallet_number] + " does not exist in intrack. Will be created"
      end
      exec_intrack_command(intrack_cmd)
      trans_id = record_map[:production_run_id]
      Inventory.create_stock(nil, "PALLET", nil, nil, "palletizing", trans_id, location, [record_map[:pallet_number]])

      @personnell_conn.commit
      @personnell_conn['AutoCommit'] = true

    rescue
      @personnell_conn.rollback if @personnell_conn && @personnell_conn.connected?
      @personnell_conn.disconnect if @personnell_conn && @personnell_conn.connected?
      raise $!
    end

  end

  def record_to_map(record)

    data = "{"
    record.attributes.each do |key, value|
      str_val = nil
      if value.class.to_s == "Time"||value.class.to_s == "Date"||value.class.to_s == "Timestamp"
        #------- Gerrit Fouche change 11 oct 2007
        #-- str_val = value.strftime("%d/%b/%Y %H:%M")
        str_val = value.strftime("%d/%b/%Y %H:%M:%S")
      end
      str_val = value.to_s if !str_val
      str_val.gsub!("'", "")
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

    count_query = "select count(*) as ctn_count from Carton where Pallet_Id = '#{record_map[:pallet_number]}'"
    return if @conn.select_one(count_query)['ctn_count'].to_s == "0"

    query = "UPDATE [KromcoData].[dbo].[Pallet]
     SET
	 [Exit_Reference]	 = 'REWORKS',
	 [Qty]	 = 0,
	 [Exit_Date]= '#{entry.friendly_date}'
	 WHERE
	( [Pallet_ID]	 = '#{record_map[:pallet_number].to_s}')"

    #execute
    #log_msg query,nil,true
    @conn.do(query)

    intrack_cmd = "ship " + record_map[:pallet_number]
    exec_intrack_command(intrack_cmd)
    trans_id = RwReceiptPallet.find_by_pallet_number(record_map[:pallet_number], :order=>"id DESC").rw_run_id
    Inventory.remove_stock(nil, "PALLET", "REWORKS", trans_id, "REWORKS", [record_map[:pallet_number]])
  end


  def pallet_rtb(entry)
    #----------------------------------------------------
    #Find all cartons belonging to pallet in kromco_mes
    #Delete pallet and all its cartons in kromco mes
    #----------------------------------------------------
    record_map = eval entry.record

    #carton_query = "DELETE [KromcoData].[dbo].[Carton] FROM Carton INNER JOIN Pallet ON Carton.Pallet_ID = Pallet.Pallet_ID WHERE (Carton.[Pallet_ID]	 = '#{record_map[:pallet_number]}' and (Carton.Exit_Reference IS NULL) AND (Pallet.Load_No IS NULL) AND (Pallet.Intake_Consignment_ID IS NULL))"
    carton_query = "DELETE [KromcoData].[dbo].[Carton] FROM Carton INNER JOIN Pallet ON Carton.Pallet_ID = Pallet.Pallet_ID WHERE (Carton.[Pallet_ID]	 = '#{record_map[:pallet_number]}' and (Carton.Exit_Reference IS NULL) AND (Pallet.Load_No IS NULL) )"


    @conn.do(carton_query)

    #pallet_query = "DELETE FROM [KromcoData].[dbo].[Pallet] WHERE (Pallet.[Pallet_ID]	 = '#{record_map[:pallet_number]}'and exit_reference is null) and (Pallet.Exit_Reference IS NULL) AND (Pallet.Load_No IS NULL) AND (Pallet.Intake_Consignment_ID IS NULL)"
    pallet_query = "DELETE FROM [KromcoData].[dbo].[Pallet] WHERE Pallet.[Pallet_ID]	 = '#{record_map[:pallet_number]}' and (Pallet.Exit_Reference IS NULL) AND (Pallet.Load_No IS NULL) "
    @conn.do(pallet_query)

  end


  ##====================
  ## Luks' code  =======
  ##====================
  def tipped_bin_reclassified(entry)

    record_map = eval entry.record

    query = "UPDATE [KromcoData].[dbo].[Bin]
     SET
	 [Production_Schedule_No]	 = '#{record_map[:production_run_code]}',
	 [Production_Line_No]	 = '#{record_map[:line_code]}'
      WHERE
	( [Bin_ID]	 = '#{record_map[:bin_id]}')"

    log_msg "creating bin..."
    @conn.execute(query)
  end

  def bin_tipped(entry, override_user = nil)
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
    @conn.execute(query)
    #log_msg"bin created."
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

    #log_msg"creating bintip log"
    @conn.execute(bintip_query)
    #log_msg"bintip log created"

    #move_cmd = "move " + record_map[:bin_id] + " PACKHSE_PRODSTAGE 1"
    #exec_intrack_command(move_cmd)
    query = "execute gf_integrate_production_schedule_data '#{run.production_run_code}','#{run.farm_code}','#{track_indicator}',#{run.line_code},'#{record_map[:bin_id]}'"
    @conn.do query

    #log_msg query,nil,true

    ship_cmd = "ship " + record_map[:bin_id]
    exec_intrack_command(ship_cmd)
    #trans_id = RwReceiptBin.find_by_bin_number(record_map[:bin_id],:order=>"id DESC").rw_run_id
    #Inventory.remove_stock(nil, "BIN", "REWORKS", trans_id, "REWORKS", [record_map[:bin_id]])

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
        #log_msgbin_query
        kr_bin = new_conn.select_one(bin_query)
        if !kr_bin
          do_not_integrate = true
          #log_msg"BIN not found"
        else
          #update our invalid_bin with weight retreieved from kromco
          invalid_bin = BinsTippedInvalid.find(record_map[:id])
          invalid_bin.weight = kr_bin["Weight"]
          invalid_bin.weight = 0 if !invalid_bin.weight
          #log_msg"bin weight: " + kr_bin["Weight"].to_s
          invalid_bin.update
        end
      ensure
        new_conn.disconnect if new_conn && new_conn.connected?
      end

    end

    if !do_not_integrate
      overrider = record_map[:authoriser_name]
      bin_tipped(entry, overrider)
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

    #log_msg query,nil, true
    @conn.do(query)

    prod_output_query = "UPDATE [KromcoData].[dbo].[Production_Output]
	  set [Pack_ID]= '#{record_map[:binfill_station_code]}',
	 [Production_Schedule_No] = '#{record_map[:production_run_code]}',
	 [Class]= '#{record_map[:class_code]}',
	 [Count_1] = '#{record_map[:size_code]}',
	 [Grower_ID] = '#{run.farm_code}',
	 [Weight]= '#{record_map[:weight]}',
	 [Bin_Type] = '#{record_map[:product_code_pm_bintype]}'
	 WHERE  ([Bin_ID] = '#{record_map[:rebin_number]}')"
    @conn.do(prod_output_query)


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

    #log_msg query,nil, true
    @conn.do(query)

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

    #log_msg query,nil,true
    @conn.do(prod_output_query)

    intrack_cmd = "create " + record_map[:rebin_number] + " BIN 1 PACKHSE"
    exec_intrack_command(intrack_cmd)
    trans_id = run.id.to_s
    Inventory.create_stock(nil, "REBIN", nil, nil, "bin_tipping", trans_id, "PACKHSE", [record_map[:rebin_number]])

  end


  def pallet_qc_reset(entry)

    record_map = eval entry.record
    query = "UPDATE [KromcoData].[dbo].Pallet SET
            Qc_Status_Code = 'UNINSPECTED',
            Qc_Result_Status = null
            WHERE (Pallet_Id = '#{record_map[:pallet_number]}')"

    #puts query
    @conn.do(query)

    carton_query = "UPDATE [KromcoData].[dbo].Carton SET
            Qc_Status_Code = 'UNINSPECTED',
            Qc_Result_Status = null
            WHERE (Pallet_Id = '#{record_map[:pallet_number]}')"

    #puts carton_query
    @conn.do(carton_query)
  end


  def ppecb_correction(entry)
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


    query = "UPDATE [KromcoData].[dbo].[PPECB_Inspect_Log] SET
	 [Inspector] = '#{record_map[:inspector_number]}',
	 [Inspect_Datetime] = '#{record_map[:created_at]}',
	 [Inspection_Point] = '#{record_map[:inspection_point]}',
	 [Inspection_Report]=  '#{record_map[:inspection_report]}',
	 [Inspection_Result] = '#{result}',
	 [Reason] = '#{record_map[:reason]}',
	 [Pallet_Result] = '#{result}',
	 [Inspection_Level] = '#{record_map[:inspection_level]}',
	 [Dispensation_Certificate_Number] = '#{record_map[:dispensation_certificate_number]}',
	 [Dispensation_Body] = '#{record_map[:dispensation_body]}'
	 WHERE (Postgres_Id = #{record_map[:id]})"

    puts query
    @conn.do(query)

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
    #puts "CARTON: " + carton.id.to_s
    #puts "LINE: " + line_number
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
	 [Fruit_type],
	 [Postgres_Id],
	 [Inspection_Level],
	 [Dispensation_Certificate_Number],
	 [Dispensation_Body])

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
	 '#{carton.commodity_code}',
	  #{record_map[:id]},
	  '#{record_map[:inspection_level_code]}',
	  '#{record_map[:dispensation_certificate_number]}',
	  '#{record_map[:dispensation_body]}')"


    puts query
    @conn.do(query)

  end


end