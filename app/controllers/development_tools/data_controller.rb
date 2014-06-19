
require File.dirname(__FILE__) + '/../../../lib/data_to_user_exporter.rb'
require File.dirname(__FILE__) + '/../../../lib/app_factory.rb'

class DevelopmentTools::DataController < ApplicationController

  def admin_exceptions?
    ["create_model","export_table"]
  end


   def show_column_detail

      key = params[:id]
      @value = session[:column_details][key]
      puts @value
      render :inline => %{

      <%= @value %>

    }

   end


  def export_to_csv

   @tables = AppFactory::PostgresMetaData.get_list_of_tables(ActiveRecord::Base.connection)

   render :inline => %{
      <% @content_header_caption = \"'export table data to csv file'\" %>
      <%= create_csv_export_form(@tables) %>

    },:layout => "content"

  end


  def export_se_summary_details_grid_to_csv
   begin

    if ! dm_session[:show_records_query_definition]
     @freeze_flash = true
     redirect_to_index("SE show summary details query definition not in server memory!")
     return
    end


    pattern = / limit [0-9]+/i
    limit = Globals.se_excel_export_limit
    export_query = dm_session[:show_records_query_definition].gsub(pattern," limit #{limit}")

    recordset = ActiveRecord::Base.connection.select_all(export_query)
    puts recordset.length.to_s

    pattern = / from +[(]*[\w]+[,| ]/i
    main_table = export_query.slice(pattern).strip.split(" ")[1].delete(",").delete("(")

    file_name = main_table  +  "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".csv"


     DataToUserExporter.create_se_csv_file(recordset,file_name,dm_session[:columns_list])

    #redirect_to_index("data_exported successfully to csv")
    send_file(DataToUserExporter.download_path + file_name)
    #TODO: write script to delete files older than e.g. 10 minutes from downloads directory
    rescue
     handle_error("grid could not be exported")
    end


  end

  def export_se_grid_to_csv(send_file = true)
   begin

    if ! dm_session[:search_engine_query_definition]
     @freeze_flash = true
     redirect_to_index("SE query definition not in server memory!")
     return
    end



#    if session[:search_engine_query_definition]
#     search_query = session[:query].gsub("limit ","1000")
#    end
    pattern = / limit [0-9]+/i
    limit = Globals.se_excel_export_limit
    export_query = dm_session[:search_engine_query_definition].gsub(pattern," limit #{limit}")

    recordset = ActiveRecord::Base.connection.select_all(export_query)
    puts recordset.length.to_s


    pattern = / from +[(]*[\w]+[,| ]/i
    main_table = export_query.slice(pattern).strip.split(" ")[1].delete(",").delete("(")

    if dm_session[:csv_export_filename].nil?
      file_name = main_table  +  "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".csv"
    else
      file_name = "#{dm_session[:csv_export_filename].clone}_#{Time.now.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
      dm_session[:csv_export_filename] = nil
    end

    cols_for_export = dm_session[:columns_list]
    cols_for_export = nil if dm_session[:functions] && dm_session[:functions].length() > 0

    #handle export of group by columns

    if recordset.length() > 0 && dm_session[:group_by_columns] && dm_session[:group_by_columns].length() > 0
      cols_for_export = dm_session[:group_by_columns]
      extra_cols      = recordset[0].keys - cols_for_export
      # Do some acrobatics to get the function columns in the same sequence as they were added by the user.
      # NB This code is a bit brittle as it depends on the way columns are created in MesScada::DataMinerActions#add_group_by_columns_before_from_clause
      orig_extras  = extra_cols.map {|c| m = c.match(/\Acount|sum_|min_|max_|avg_/); "#{m[0].upcase.sub('_', '')}(#{m.post_match}"; }
      orig_seq     = dm_session[:functions].split(/,|\|/)
      new_keys     = orig_seq.map {|a| orig_extras.each_with_index {|o,i| if a.start_with?(o) then break i end; } }
      new_seq      = new_keys.map {|i| extra_cols[i] }
      cols_for_export += new_seq
    end


     DataToUserExporter.create_se_csv_file(recordset,file_name,cols_for_export)

    #redirect_to_index("data_exported successfully to csv")
    send_file(DataToUserExporter.download_path + file_name)
    #TODO: write script to delete files older than e.g. 10 minutes from downloads directory
    rescue
     handle_error("grid could not be exported")
    end
  end

  def export_grid_to_csv
   begin

    if ! session[:query]
      if !session[:cached_query]
         @freeze_flash = true
         redirect_to_index("This specific grid does not support an export. Ask IT to configure this grid for exporting")
         return
      else
         session[:query] = session[:cached_query]
      end
    end

#    if session[:search_engine_query_definition]
#     search_query = session[:query].gsub("limit ","1000")
#    end

    export_query = session[:query].gsub("@@page_size","1000")
    export_query = export_query.gsub("session[:active_page_size]","1000")
    export_query = export_query.gsub("@current_page","0")
    puts "EXP: " + export_query
    recordset = eval(export_query)
    puts recordset.length.to_s

    file_name = recordset[0].class.to_s  +  "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".csv"

    cols = columns_for_export?
     recordset=filter_export_records(recordset)

    if !cols
      if  recordset[0].class.to_s=="Hash"
        DataToUserExporter.create_se_csv_file(recordset,file_name)
      else
      DataToUserExporter.create_csv_file(recordset,file_name)
      end
    else
      DataToUserExporter.create_custom_csv_file(recordset,file_name,cols)
    end
    #redirect_to_index("data_exported successfully to csv")
    send_file(DataToUserExporter.download_path + file_name)
    #TODO: write script to delete files older than e.g. 10 minutes from downloads directory
    rescue
     handle_error("grid could not be exported")
    end
  end

  def filter_export_records(recordset)
    filter_method_name=nil
    filtered_recordset=recordset

    context=request.env['HTTP_REFERER']
    if active_filter= session[:active_csv_filter]
      if context.index(active_filter[:action_name])
         filter_method_name=active_filter[:filter_method_name]
      end
    end
    if filter_method_name
      filtered_recordset=eval(filter_method_name + "(filtered_recordset)")
    end
    return filtered_recordset
  end

  def export_to_csv_submit

    begin
    table_name = params[:exporter][:table]
    DataToUserExporter.export_table_to_csv(table_name,table_name + "_data.csv")
    #redirect_to_index("data_exported successfully to csv")
    send_file(DataToUserExporter.download_path + table_name + "_data.csv")

    rescue
      handle_error("export to csv failed")

    end
  end


  def export_table
    render :inline => %{
      <% @content_header_caption = \"'export table data to remote database'\" %>
      <%= create_table_export_form %>

    },:layout => "content"
  end

  def export_table_submit
  begin

    errors = DataExporter.new(params[:exporter][:export_table]).export_table_data
    err = ""
    if errors.length() == 0
      redirect_to_index("data exported successfully")
    else
      err = "<table><tr><td colspan = 2><strong>Table data could not be copied to remote database. The following record insertions failed</strong></td><td/></tr>"
      errors.each do |key, error|

       err += "<tr><td><strong>" + key.to_s + "</strong>&nbsp;&nbsp</td><td>" + error.to_s + "</td></tr>"
      end
      err += "</table>"

      handle_error(err)

    end
  rescue
   handle_error("Table data could not be copied to remote database")
  end
  end


end



