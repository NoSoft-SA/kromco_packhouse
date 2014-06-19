class BinsTipped < ActiveRecord::Base
  self.table_name = "bins_tipped"
  
#:::::::::LUKS CHANGE - ADDED ALL THE FOOLWING CODE:::::::::  
  attr_accessor :bin_time_search,:tipped_date_time_from,:tipped_date_time_to
  
    def BinsTipped.build_and_exec_query(params,session=nil)
    
    
     query = "    SELECT  public.bins_tipped.* FROM
           public.bins_tipped
           WHERE ("
           
      #----------------
      #Add conditions
      #----------------
      
      #NB: look at 'execute_production_run_step3'
      #pack date
      from_time = nil
      to_time = nil
      started = false
      
      puts params.to_s
      if params.key?('tipped_date_time_from(1i)')
       
         from_time = Time.local(params['tipped_date_time_from(1i)'],params['tipped_date_time_from(2i)'],params['tipped_date_time_from(3i)'],params['tipped_date_time_from(4i)'],params['tipped_date_time_from(5i)']).to_formatted_s(:db)
         to_time = Time.local(params['tipped_date_time_to(1i)'],params['tipped_date_time_to(2i)'],params['tipped_date_time_to(3i)'],params['tipped_date_time_to(4i)'],params['tipped_date_time_to(5i)']).to_formatted_s(:db)
         query += "public.bins_tipped.tipped_date_time > '#{from_time}' AND public.bins_tipped.tipped_date_time < '#{to_time}'"
         started = true
      end
      
      #bin_id(textbox)
      if params['bin_id'] && params['bin_id'].strip != ""
        query += " AND " if started
        query += " public.bins_tipped.bin_id = '#{params['bin_id']}' "
        started = true
      end
      
      #production_schedule_name
      if params['production_schedule_name']  != ""
        query += " AND " if started
        query += " public.bins_tipped.production_schedule_name = '#{params[:production_schedule_name]}' "
        started = true
      end
      
       #production_run_code
      if params['production_run_code'] != ""
        query += " AND " if started
        query += " public.bins_tipped.production_run_code = '#{params['production_run_code']}' "
        started = true
      end
      
        #line_code
      if params['line_code']  != ""
        query += " AND " if started
        query += " public.bins_tipped.line_code = '#{params['line_code']}' "
        started = true
      end
      
             #class_description
      if params['class_description']  != ""
        query += " AND " if started
        query += " public.bins_tipped.class_description = '#{params['class_description']}' "
        started = true
      end
             #track_indicator_code
      if params['track_indicator_code']  != ""
        query += " AND " if started
        query += " public.bins_tipped.track_indicator_code = '#{params['track_indicator_code']}' "
        started = true
      end


      query += ") LIMIT 1000"
       
      
      if started
       session[:cached_query] = "BinsTipped.find_by_sql(\"" + query + "\")"  if session
       return BinsTipped.find_by_sql(query)
      else
       return nil
      end
       
  end
  
end
