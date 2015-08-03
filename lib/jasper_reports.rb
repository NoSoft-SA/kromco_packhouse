class JasperReports

  # Generate a Jasper report.
  # Note special optional parameters:
  # - :keep_file - if this is present, the script used to run the report will not be deleted. Useful while debugging.
  # - :top_level_dir - When set, this string will become part of the report dir before the report name.
  #                    This allows for storing two versions of a report and deciding at runtime which to execute.
  #                    e.g. between jasper_reports/otion1/the_report/the_report.jasper
  #                         and     jasper_reports/otion2/the_report/the_report.jasper
  #                    params[:top_level_dir] = 'option2'
  #
  def self.generate_report(report_name, user, params)

    keep_file              = params.delete(:keep_file)
    top_level_dir          = params.delete(:top_level_dir) || ''
    params[:SUBREPORT_DIR] = "#{File.join(Globals.sub_report_dir, top_level_dir, report_name)}/"
    report_parameters      = params.reject{|k,v| :printer == k}.map {|k,v| "\"#{k}=#{v}\""}.join(' ')

    conn_params        = Globals.jasper_reports_conn_params
    connection_string  = "#{conn_params[:adapter]}://"
    connection_string << "#{conn_params[:host]}:"
    connection_string << "#{conn_params[:port]}/"
    connection_string << "#{conn_params[:database]}?"
    connection_string << "user=#{conn_params[:username]}&"
    connection_string << "password=#{conn_params[:password]}"

    script_ext              = RUBY_PLATFORM.index('linux') ? '.sh' : '.bat'
    print_command_file_name = File.join(Globals.jasper_reports_printing_component,
                                        "#{report_name}_#{user}_#{Time.now.strftime("%m_%d_%Y_%H_%M_%S")}#{script_ext}")

    report_dir = "#{Globals.jasper_source_reports_path}/#{top_level_dir.blank? ? '' : top_level_dir + '/'}#{report_name}"

    File.open(print_command_file_name, "w") do |f|
      f.puts "cd #{Globals.jasper_reports_printing_component}"
      f.puts "java -jar JasperReportPrinter.jar \"#{report_dir}\" #{report_name} \"#{params[:printer]}\"" <<
             " \"#{connection_string}\" #{report_parameters}"
    end

    if RUBY_PLATFORM.index('linux')
      result = eval "\` sh #{print_command_file_name}\`"
    else
      result = eval "\`\"#{print_command_file_name}\"\"`"
    end

    File.delete(print_command_file_name) unless keep_file

    if(result.to_s.include?("JMT Jasper error:") && (errors=result.split("JMT Jasper error:")).length > 0)
      return "JMT Jasper error: <BR>" + errors[1]
    end
  end

end
