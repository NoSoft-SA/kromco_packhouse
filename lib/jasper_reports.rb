class JasperReports
  def JasperReports.generate_report(report_name,user,params)

    params.store(:SUBREPORT_DIR,Globals.sub_report_dir + report_name + "/")

    report_parameters = ""
    params.map{|key,value| (report_parameters = report_parameters + " \"#{key}=#{value}\" ") if(key != :printer)}
    connection_string = "#{Globals.jasper_reports_conn_params[:adapter]}://#{Globals.jasper_reports_conn_params[:host]}:#{Globals.jasper_reports_conn_params[:port]}/#{Globals.jasper_reports_conn_params[:database]}?user=#{Globals.jasper_reports_conn_params[:username]}&password=#{Globals.jasper_reports_conn_params[:password]}"

    if !RUBY_PLATFORM.index('linux')
      print_command_file_name = Globals.jasper_reports_printing_component + "/" + report_name + "_" + user + "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".bat"
      file = File.new(print_command_file_name, "w")
      file.puts "cd #{Globals.jasper_reports_printing_component.gsub("/","\\")}"
      file.puts "java -jar JasperReportPrinter.jar \"#{Globals.jasper_source_reports_path}/#{report_name}\" #{report_name} \"#{params[:printer]}\" \"#{connection_string}\" #{report_parameters}"
      file.close

      result = eval "\`\"#{print_command_file_name}\"\"`"
      puts "WINDOWS PRINTING RESULT: " + result.to_s
      File.delete(print_command_file_name)
      if(result.to_s.include?("JMT Jasper error:") && (errors=result.split("JMT Jasper error:")).length > 0)
        return "JMT Jasper error: <BR>" + errors[1]
      end
    else

      print_command_file_name = Globals.jasper_reports_printing_component + "/" + report_name + "_" + user + "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".sh"
      file = File.new(print_command_file_name, "w")
      file.puts "cd #{Globals.jasper_reports_printing_component.gsub("\\","/")}"
      file.puts "#{Globals.path_to_java} -jar JasperReportPrinter.jar \"#{Globals.jasper_source_reports_path}/#{report_name}\" #{report_name} \"#{params[:printer]}\" \"#{connection_string}\" #{report_parameters}"
      file.close

      result = eval "\` sh " + print_command_file_name + "\`"
      puts "LINUX PRINTING RESULT: " + result.to_s
      result_array = result.split("\n")
      error = result_array.pop
      File.delete(print_command_file_name)
      if(result.to_s.include?("JMT Jasper error:") && (errors=result.split("JMT Jasper error:")).length > 0)
        return "JMT Jasper error: <BR>" + errors[1]
      end
    end
  end

end
