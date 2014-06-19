class PdtLog < ActiveRecord::Base 
	
  #	===========================
  # 	Association declarations:
  #	===========================
  attr_accessor :created_on_from,:created_on_to,:time_search
 
 
  #	============================
  #	 Validations declarations:
  #	============================
	validates_numericality_of :mode
  #	=====================
  #	 Complex validations:
  #	=====================
  def validate
    #	first check whether combo fields have been selected
    is_valid = true
  end

  def PdtLog.build_and_exec_query(params,session = nil)

    params['menu_item'] = params['menu_item'].split("[")[0] if params['menu_item']!= ""
    
    query = " SELECT  public.pdt_logs.* FROM public.pdt_logs
                                  WHERE (public.pdt_logs.menu_item LIKE '#{params['menu_item']}%'"

    from_time = nil
    to_time = nil
    started = true

    puts params.to_s
    if params['created_date_from']!= "" && params['created_date_to'] != ""
      query += " AND " if started

      query += "public.pdt_logs.created_on between '#{params['created_date_from']}' AND  '#{params['created_date_to']}'"
      started = true
    end

    if params['user_name']  != ""
      query += " AND " if started
      query += " public.pdt_logs.user_name = '#{params[:user_name]}' "
      started = true
    end



    if params['ip'] && params['ip'] != ""
      query += " AND " if started
      query += " public.pdt_logs.ip = '#{params[:ip]}' "
      started = true
    end


    if params['input_xml']  != ""
      query += " AND " if started
      query += " public.pdt_logs.input_xml LIKE '%#{params['input_xml'].gsub("''","").gsub("""", "")}%'"
      started = true
    end


    if params['output_xml']  != ""
      query += " AND " if started
      query += " public.pdt_logs.output_xml LIKE '%#{params['output_xml'].gsub("''","").gsub("""", "")}%'"
      started = true
    end
     
    query += ") LIMIT 100"

    puts query
    if started

      session[:cached_query] = "PdtLog.find_by_sql(\"" + query + "\")"  if session
      return PdtLog.find_by_sql(query)
    else
      return nil
    end
  end


 
end
