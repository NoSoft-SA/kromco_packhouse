
class Diagnostics

  @@palletizing_log_path = '//henry//share//palletizing_log//palletizing_log//skip_'
                        
  
  #@@palletizing_log_path = File.dirname(__FILE__) + '../palletizing_log/palletizing_log/skip_'
    
  def Diagnostics.download_path
      return @@palletizing_log_path
  end

#*****************Daily Avtivity Queries***********************************************
  def Diagnostics.total_cartons_printed(yesterday,tomorrow)
    Carton.count_by_sql("select count(*) from cartons where pack_date_time >'#{yesterday}' and pack_date_time <'#{tomorrow}'")
  end
  
  def Diagnostics.total_cartons_packed(yesterday,tomorrow)
    Carton.count_by_sql("select count(*) from cartons where pallet_id is not NULL and pack_date_time >'#{yesterday}' and pack_date_time <'#{tomorrow}'")
  end
  
  def Diagnostics.total_pallets_palletized(today,tomorrow)
    Pallet.count_by_sql("select count(*) from pallets where process_status = 'PALLETIZED' and date_time_completed >'#{today}' and date_time_completed <'#{tomorrow}'")
  end
  
  def Diagnostics.total_bins_tipped(today,tomorrow)
    BinsTipped.count_by_sql("select count(*) from bins_tipped where tipped_date_time >'#{today}' and tipped_date_time <'#{tomorrow}'") + BinsTippedInvalid.count_by_sql("select count(tipped_date_time) from bins_tipped_invalid where tipped_date_time >'#{today}' and tipped_date_time <'#{tomorrow}'" )
  end
  
  def Diagnostics.total_rebins_printed(today,tomorrow)
    Rebin.count_by_sql("select count(*) from rebins where rebin_status = 'printed' and transaction_date >'#{today}' and transaction_date <'#{tomorrow}'")
  end
  
#*****************error activity Queries***********************************************
   def Diagnostics.server_errors(today,tomorrow)
    MidwareErrorLog.count_by_sql("select count(*) from midware_error_logs where error_date_time >'#{today}' and error_date_time <'#{tomorrow}'")
   end

#*****************reworks activity Queries***********************************************
   def Diagnostics.cartons_scraped(today,tomorrow)
    RwScrapCarton.count_by_sql("select count(*) from rw_scrap_cartons where rw_scrap_datetime >'#{today}' and rw_scrap_datetime <'#{tomorrow}'")
   end
   
   def Diagnostics.cartons_repacked(today,tomorrow)
    RwCarton.count_by_sql("select count(*) from rw_cartons where date_time_created >'#{today}' and date_time_created <'#{tomorrow}'")
   end
   
   def Diagnostics.cartons_reclassified(today,tomorrow)
    RwReclassedCarton.count_by_sql("select count(*) from rw_reclassed_cartons where date_time_created >'#{today}' and date_time_created <'#{tomorrow}'")
   end
   
   def Diagnostics.pallets_scrapped(today,tomorrow)
    RwScrapPallet.count_by_sql("select count(*) from rw_scrap_pallets where rw_scrap_datetime >'#{today}' and rw_scrap_datetime <'#{tomorrow}'")
   end
   
   def Diagnostics.pallets_reclassified(today,tomorrow)
    RwReclassedPallet.count_by_sql("select count(*) from rw_reclassed_pallets where date_time_created >'#{today}' and date_time_created <'#{tomorrow}'")
   end
   
   def Diagnostics.pallets_repacked(today,tomorrow)
    RwPallet.count_by_sql("select count(*) from rw_pallets where date_time_created >'#{today}' and date_time_created <'#{tomorrow}'")
   end
   
   def Diagnostics.rebins_scraped(today,tomorrow)
    RwScrapRebin.count_by_sql("select count(*) from rw_scrap_rebins where rw_scrap_datetime >'#{today}' and rw_scrap_datetime <'#{tomorrow}'")
   end
   
   def Diagnostics.rebins_reclassified(today,tomorrow)
    RwReclassedRebin.count_by_sql("select count(*) from rw_reclassed_rebins where date_time_created >'#{today}' and date_time_created <'#{tomorrow}'")
   end
   
 #-------------[ INTEGRATION QUERIES ]----------------------------------
   def Diagnostics.missing_flows(today,tomorrow)
    MidwareErrorLog.count_by_sql("select count(*) from midware_error_logs where error_date_time > '#{today}' and error_date_time < '#{tomorrow}' and mw_type = 'integration' and short_description LIKE '%Integration record of type%'")
   end
   
   def Diagnostics.error_flows(today,tomorrow)
    #RailsError.count_by_sql("select count(DISTINCT description) from rails_errors where created_on > '#{today}' and created_on < '#{tomorrow}' and error_type = 'outbox_processor'")
    OutboxEntry.count_by_sql("select count(*) from outbox_entries where process_status > 0 ")
   end
   
   def Diagnostics.problem_flows(type_code)
    if type_code == "all"
      "@outbox_entry_pages = Paginator.new self, OutboxEntry.count, @@page_size,@current_page
	         @outbox_entries = OutboxEntry.find(:all,
	         :conditions =>['process_status > ? ', 0])"
    else
    "@outbox_entry_pages = Paginator.new self, OutboxEntry.count, @@page_size,@current_page
	         @outbox_entries = OutboxEntry.find(:all,
	         :conditions =>['type_code = ? and process_status > ? ', '#{type_code}', 0],
			 :limit => @outbox_entry_pages.items_per_page,
			 :offset => @outbox_entry_pages.current.offset)"
    end
   end
   
 def Diagnostics.pallet_cartons(pallet_number)
    "@pallet_cartons = Carton.find_all_by_pallet_number(#{pallet_number})"
   end
end