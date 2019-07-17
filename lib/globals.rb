class Globals

  @@log_levels = {}
  @@console_log_levels = {}

  def Globals.get_grading_csv_file_configs_folder
    Dir.getwd + "/public/uploads/csv_file_configs"
  end

  def Globals.get_grading_rule_folder
    Dir.getwd + "/public/uploads/rmt_processing/grower_grading/grading_rules"
  end

  if RUBY_VERSION < '1.8.7'
    def self.log_levels
      @@log_levels
    end
    def self.log_levels=(val)
      @@log_levels = val
    end
    def self.console_log_levels
      @@console_log_levels
    end
    def self.console_log_levels=(val)
      @@console_log_levels = val
    end
  else
    cattr_accessor :log_levels, :console_log_levels
  end



  def Globals.get_presort_unit_from_lot_number(lot_nr)

    if lot_nr.to_i >= 10000
      return 1
    else
      2
    end

  end

  def Globals.tables_to_be_logged_in_changed_logs
    return ["orders","voyages","people","messcada_people_view_messcada_rfid_allocations"]
  end

  def Globals.tms_for_tu_mass_printing
    ["FE","NI"]
  end

  def Globals.properties?
    if !@properties
      File.open("config/appp_factory.yml") do |file|
        @properties = YAML.load(file)
      end
    end
  end

  def Globals.jasper_reports_pdf_downloads
    Dir.getwd + "/public/downloads/pdf"
  end


  @@domain = nil
  def Globals.get_domain
    @@domain
  end

  def Globals.get_column_captions

    {"remarks1"=>"remarks_1",
     "remarks2" =>"remarks_2" ,
     "remarks3" => "remarks_3" ,
     "remarks4" =>  "remarks_4",
     "remarks5" => "remarks_5"}

  end

  def self.reworks_server_port
    "234"
  end

  def Globals.bin_ticket_printer_names
    ['PRN-01','PRN-02','PRN-03','PRN-05','PRN-16']
  end

  def Globals.reworks_printer_name
    "PRN-01"
  end

  def Globals.get_jasper_server_report_server_ip
    "http://127.0.0.1:3000"
  end

  def Globals.get_jasper_server
    "/jasperserver/flow.html?_flowId=viewReportFlow&"
  end

  def Globals.get_jasperserver_username_password
    "j_username=jasperadmin&j_password=jasperadmin&"
  end

  # Get the log level for a specific log type.
  # Log Levels for logging to file.
  def Globals.get_log_level(log_type)
    if @@log_levels[log_type]
      @@log_levels[log_type]
    else
      case log_type
        when "edi_in"
          0
        when  "transformer_in"
          0
        when "edi_out"
          0
        when  "transformer_out"
          2
        else
          0
      end
    end
  end


  # Get the log level for a specific log type.
  # Log Levels for logging to console.
  def Globals.get_console_log_level(log_type)
    if @@console_log_levels[log_type]
      @@console_log_levels[log_type]
    else
      case log_type
        when "edi_in"
          0
        when  "transformer_in"
          0
        when "edi_out"
          0
        when  "transformer_out"
          2
        else
          0
      end
    end
  end

  def Globals.enable_logging
    true
  end

  def Globals.set_domain(domain)
    @@domain =  domain
  end

  def Globals.pdf417_max_size
    1400
  end


  def Globals.get_column_data_width
    150
  end

  def Globals.get_diagnostics_truncate_size
    2000
  end

  def Globals.get_mesware_ip
    "172.16.16.1"
  end

  def Globals.reworks_ip
    "172.16.35.7"
  end

  def Globals.se_excel_export_limit
    150000
  end

  def Globals.security_configs
    "public/security_configs/"
  end

    def self.currency(env, value)
      env.number_to_currency(value, :unit => "R", :separator => ",", :delimiter => "")
    end

    # Commas as thousands separators for currency. Can be called from models or controllers.
    def self.delimited_currency(value, unit='R', delimiter=',', no_decimals=2)
      val      = value.blank? ? 0.0 : value
      parts    = sprintf("#{unit}%.#{no_decimals}f", val).split('.')
      parts[0] = parts.first.reverse.gsub(%r{([0-9]{3}(?=([0-9])))}, "\\1#{delimiter}").reverse
      parts.join('.')
    end

    # Takes a Numeric and returns a string without trailing zeroes.
    # 6.03 => "6.03".
    # 6.0  => "6".
    def self.format_without_trailing_zeroes(numeric_value)
      s    = sprintf('%f', numeric_value)
      i, f = s.to_i, s.to_f
      i == f ? i.to_s : f.to_s
    end

  def Globals.mrl_printer_ip
    "172.16.16.14"
  end

  def Globals.bin_ticket_printing_ip
    "192.168.50.101"
  end

  def Globals.get_pdt_simulator_config
    return "C:/pdt/"
  end

  def Globals.get_reports_location
      "reports"
  end

  def Globals.search_engine_max_rows
    2000
  end

  def Globals.get_crystal_reports_server_ip
    "172.16.16.14"
  end

  def Globals.get_crystal_reports_server_port
    8080
  end

  def Globals.get_crystal_reports_server
    "/CrystalReportsServer/index.jsp?"
  end

  def Globals.get_label_printing_server_url
    "172.16.16.1"
  end

  def Globals.get_label_printing_server_port
    3001
  end

  #=====================
  # Happymore
  #=====================

  #=====================
  # Luks
  #=====================
  def Globals.pdt_server_url
    "http://172.16.16.14:3000"
  end
  def Globals.pdt_simulator_client_server
      "http://192.168.50.110:3000"
  end

  def Globals.get_legacy_db_conn_string
    # {:adapter => "sqlserver", :host => "172.16.16.14",  :database => "KromcoData", :username => "sa"}
    host = "172.16.16.14"
    database = "KromcoData"
    username = "sa"
    password = ""
    #Password=#{password};
    return "DBI:ADO:Provider=SQLOLEDB;Data Source=#{host};Initial Catalog=#{database};User Id=#{username};Password = ''"
    #return "DBI:ODBC:Driver={SQLServer};Server=#{host};Database=#{database};Uid=#{username};Pwd=''"
  end

  def Globals.get_odbc_legacy_db_conn_string
    # {:adapter => "sqlserver", :host => "172.16.16.14",  :database => "KromcoData", :username => "sa"}
    #host = "172.16.16.14"
    #database = "KromcoData"
    #username = "sa"
    #password = ""
    #Password=#{password};
    #return "DBI:ADO:Provider=SQLOLEDB;Data Source=#{host};Initial Catalog=#{database};User Id=#{username};Password = ''"
    return "DBI:ODBC:KromcoData"
  end

  def Globals.get_odbc_legacy_personnell_db_conn_string
    return "DBI:ODBC:kromco_personnell_sql"
  end

  def Globals.get_legacy_personnell_db_conn_string
    host = "172.16.16.14"
    database = "KromcoPMS"
    username = "sa"
    password = ""
    #Password=#{password};
    return "DBI:ADO:Provider=SQLOLEDB;Data Source=#{host};Initial Catalog=#{database};User Id=#{username};Password = ''"

  end

  def Globals.get_odbc_intrack_db_conn_string
    "DBI:ODBC:intrack_sql"
  end

#  def Globals.get_mes_conn_params
#   return {:adapter => "postgresql", :host => "172.16.16.15",  :database => "kromco_mes", :username => "ruby_scripts",:password => "ruby_scripts",:port => 5432}
#
#  end

# Get the db connection parameters from the app's database.yml file
  def Globals.get_mes_conn_params(env='edi')
    config = YAML.load(File.read('config/database.yml'))[env]
    return {:adapter => config['adapter'],
            :host => config['host'],
     :database => config['database'],
            :username => config['username'],
            :password => config['password'],
     :port     => config['port']}

  end

  def Globals.get_mes2_conn_params
    return {:adapter => "postgresql", :host => "172.16.16.15",  :database => "kromco_mes", :username => "reworks_complete",:password => "reworks_complete",:port => 5432}

  end


  def Globals.models_to_exclude_from_scripts
    ["mrl_label_printing.rb","carton_label_printing.rb", "process_outbox.rb","outbox_processor.rb",
     "mf_account.rb","mf_account_farm.rb","mf_farm.rb","mf_product_code.rb","mf_product_code_target_market.rb","pallet_label_printing.rb",
     "carton_label_printing.rb","bin_ticket_printing.rb","mrl_label_printing.rb","send_edi_script.rb"]
  end

  def Globals.is_scriptable_model?(model_name)
    if(Globals.models_to_exclude_from_scripts.include?(model_name))
      return false
    end
    return true
  end

  #def Globals.get_bin_weighing_application_server
  # "http://172.16.16.44"
  #end

  def Globals.get_bin_weighing_application_name
    "SampleBinWeighingApp"
  end

  def Globals.get_bin_weighing_application_port
    ""
  end

  def Globals.create_grouped_assets_script_input_data
    "farm_bins.csv"
  end

  def Globals.create_grouped_assets_script_params
    return {:adapter=>"postgresql",
            :username=>"postgres",
            :password=>"postgres",
            :database=>"kromco_mes",
            :host=>"172.16.16.15",
            :port => 5432}
  end

  def Globals.jasper_reports_conn_params
    config = YAML.load(File.read('config/database.yml'))[ENV['RAILS_ENV']]
    {:adapter  => "jdbc:postgresql",
     :username => "postgres",
     :password => "postgres",
     :database => config['database'],
     :host     => config['host'],
     :port     => config['port']}
  end

  #_________________________
  #No need to change this i.e. the reporting server comes with this project
  def Globals.jasper_reports_printing_component
    File.join(Dir.getwd, 'jmt_reporting_server')
  end

  def Globals.jasper_reports_printer_name
#    actual printer_name = \\ace\jmt_printer
    "\\\\darth\\Canon iR2200-3300 PCL5e"
  end

  def Globals.jasper_source_reports_path
    #Path to intake.jasper
    Dir.getwd + "/jasper_resources"
  end

  def Globals.intake_sub_report_dir
    #Path to intake_subreport1.jasper
    Dir.getwd + "/jasper_resources/"
  end

  def Globals.pdf417_sub_report_data_source_dir
    #Path to intake_subreport1.jasper's xml data source(xml file) N.B. is created and deleted of the fly
    Dir.getwd + "/jasper_xml/"
  end

  def Globals.bin_ticket_printer_name
    "PRN-06"
  end

# Remove extraneous "and (true)" phrases from an SQL statement.
  def self.cleanup_where(statement)
    statement.gsub(/and\s+\(true\)/, '')
  end
#_________________________

# Returns an Integer - the maximum number of rows that a webquery can return
# for use in Excel.
  def Globals.webquery_max_rows
       1048576
  end

  def Globals.fta_reports_path
    Dir.getwd + "/public/fta_reports"
  end

  def Globals.sub_report_dir
    Dir.getwd + "/jasper_resources/"
  end

  def Globals.pdt_device_menus_path
    "/opt/jmt/mwserver/config/mes/mobile"
  end

  def Globals.pdt_simulator_menus_path
    "/opt/jmt/apache-tomcat-7.0.27/webapps/PDTSimulator"
  end

  def Globals.default_alerts_email_recipients
    "lmatoti@gmail.com"
  end

  def Globals.path_to_java
    "/usr/bin/java"
  end

  def Globals.signed_intake_docs
    Dir.getwd + "/public/downloads/signed_intake_docs/"
  end

  def Globals.ms_sql_presort_server_port
    #database:
    #adapter: mssql
    #url: jdbc:jtds:sqlserver://192.168.10.28/PRESORT
    #username: sa
    #password: cmsadmin.

    8081
  end

  def Globals.ms_sql_integration_server_port
    #database:
    #adapter: mssql
    #url: jdbc:jtds:sqlserver://192.168.10.28/APPORT_INTEGRATION
    #username: sa
    #password: cmsadmin.

    8082
  end

  def Globals.pdt_presort_staging_ip
    '192.168.50.101'
  end

  def Globals.pdt_presort_staging_port
    300
  end

  def Globals.ms_sql_server_host
    '172.16.16.1'
  end

  def Globals.bin_created_mssql_presort_server_port
    8087
  end

  def Globals.bin_tipped_mssql_integration_server_port
    8086
  end

  def Globals.bin_scanned_mssql_integration_server_port
    8086
  end

  def Globals.bin_created_mssql_server_host
    '172.16.16.1'
  end

  def Globals.bin_tipped_mssql_server_host
    '172.16.16.1'
  end

  def Globals.bin_scanned_mssql_server_host
    '172.16.16.1'
  end

  def Globals.suppress_pdt_web_errors

  end

  # Returns the next Friday from a given date.
  # If the given date is a Friday, that date is returned, not the following one.
  def self.this_or_next_friday(dt=Date.today)
    (dt..(dt+6)).find {|d| d.cwday == 5 }
  end

  # Translate characters that cause problems in filenames to '-'
  # (Note this is quite strict - it uses Windows restrictions. For Linux, '/' is the main problem
  def self.safe_name_for_file(fname)
    fname.gsub(/[\/:*?"\\<>\|\r\n]/i, '-')
  end

  # Create a string representation of a table with tabs between columns.
  # keys is an array of Symbols and recs is an Array of hashes
  # indexed by String representations of the Symbols.
  # e.g. Globals.make_test_table([:name, :age], [{'name => 'John', 'age' => 21}, {'name' => 'Jack', 'age' => 22}])
  # gives:
  #   Name Age
  #   ---- ---
  #   John  21
  # Albert  22
  #
  # NB. Make sure the keys are sensible -- they will be used as the column headers
  def self.make_text_table(keys, recs)
    rowdef = Struct.new(*keys) do
      def check_max(max)
        values.each_with_index do |val, index|
          max[index] = val.to_s.length if val.to_s.length > max[index]
        end
      end
    end

    header     = rowdef.members.map {|m| m.to_s.gsub('_', ' ').capitalize }
    maxlengths = header.map {|m| m.length+2 }
    underline  = header.map {|m| '-'*m.length }

    rows       = []
    recs.each do |rec|
      vals = keys.map {|k| rec[k.to_s] || rec[k] } # Try to index with a String. If that returns nil, try the Symbol.
      row  = rowdef.new(*vals)
      row.check_max(maxlengths)
      rows << row
    end

    format = maxlengths.map {|m| "%#{m}s" }.join("\t") << "\n"
    s = ''
    s << sprintf(format, *header)
    s << sprintf(format, *underline)
    rows.each do |row|
      s << sprintf(format, *row.values)
    end
    s
  end

  # Simple wrapper for sending an email for calling from script/runner. e.g.
  # cron job: cd ~/kromco_packhouse && script/runner -e production 'Globals.send_an_email( "TEST", "eg@eg.com", "Something happened")'
  def self.send_an_email(subject, recipients, body)
    GenericMailer.deliver_vanilla_mail(:subject    => subject,
                                       :recipients => recipients,
                                       :text       => body)
  end

  # Get the column names from an SQL statement.
  def self.list_of_cols_from_stat(stat)
    # Grab everything between SELECT and the last FROM. NB. This will fail if there is a subquery in the WHERE clause or in a JOIN.
    # Regex is modified by m for multiline and i for case insensitive.
    match = stat.match(/\A\s*select\s?(.+)(\sfrom\s)/mi)
    # Need to strip FUNCTION(field,1,2) out, but NOT COUNT(id)
    # If there is a match, replace any functions that may include commas, then split columns by commas and return an array of the last word in each column.
    # Function regex:
    # \w+        Start with words (SUBSTR)
    # \s?        Might be a space or tab or two between the function name and parenthesis
    # \(         Match an open parenthesis
    # [^\)]+?    The ( can be followed by 1 or more of any character except ")"
    # ,{1}       There must be exactly one ","
    # .+?        ...followed by one or more of any character
    # \)         ...and ending with a closing parenthesis
    match.nil? ? nil : match[1].gsub(/\w+\s?\([^\)]+?,{1}.+?\)/, 'HIDEFUNC').split(',').map {|c| c.split('.').last.split(' ').last }
  end

  # Escapes single quotes in a string for passing to a db.
  # e.g. sql_quotes("One o'clock') => "One o''clock".
  def self.sql_quotes(s)
    s.gsub(/\\/, '\&\&').gsub(/'/, "''")
  end

  def Globals.starch_result_categories
    {:cat1_value=>"5%",:cat2_value=>"10%",:cat3_value=>"20%",:cat4_value=>"25%",
     :cat5_value=>"30%",:cat6_value=>"40%",:cat7_value=>"60%",:cat8_value=>"70%",:cat9_value=>"80%"}
  end
end

