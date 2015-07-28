class Globals

  @@log_levels = {}
  @@console_log_levels = {}

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

  def Globals.tables_to_be_logged_in_changed_logs
    return ["orders","voyages","people","messcada_people_view_messcada_rfid_allocations"]
  end

  def Globals.properties?
    if !@properties
       File.open("config/appp_factory.yml") do |file|
        @properties = YAML.load(file)
      end
    end
  end

  def Globals.path_to_java
    "java"
  end

  @@domain = nil
  def Globals.get_domain
    @@domain
  end

  def Globals.get_column_captions

       {"remarks1"=>"holdover",
        "remarks2" =>"carton_quantity" ,
        "remarks3" => "extended_fg" ,
        "remarks4" =>  "remarks_4",
        "remarks5" => "remarks_5"}

    end

  def self.reworks_server_port
    "234"
  end


  def Globals.reworks_printer_name

    "PRN-01"
  end

  def Globals.get_jasper_server_report_server_ip
    "http://172.16.16.44"
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



   def Globals.get_column_data_width
     150
   end

   def Globals.get_diagnostics_truncate_size
     2000
   end

   def Globals.get_mesware_ip
    "192.168.10.8"
    end

    def Globals.reworks_ip
    "192.168.10.179"
    end

    def Globals.se_excel_export_limit
     5000
    end

    #=====================
    # Happymore
    #=====================

    def Globals.mrl_printer_ip
      "192.168.10.179"
    end

    def Globals.mrl_label_printer_name
      "PRN-01"
    end

    def Globals.mrl_label_print_format
      "E2"
    end

    def Globals.bin_ticket_printing_ip
      "172.16.16.2"
    end

    def Globals.get_pdt_simulator_config
      return "C:/pdt/"
    end

    def Globals.get_reports_location
      "reports"
    end

    def Globals.currency(env, value)
      env.number_to_currency(value, :unit => "R", :separator => ",", :delimiter => "")
    end

     def Globals.search_engine_max_rows
      4000
    end

     # Returns an Integer - the maximum number of rows that a webquery can return
     # for use in Excel.
     def Globals.webquery_max_rows
      10000
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
      "192.168.10.179"
    end


    def Globals.get_label_printing_server_port
      2080
    end

    #=====================
    # Happymore
    #=====================

    #=====================
    # Luks
    #=====================
    def Globals.pdt_server_url
      "http://192.168.10.7:3000"
    end
    def Globals.pdt_simulator_client_server
      "http://192.168.50.17:3000"
    end
    #=====================
    # Luks
    #=====================

  def Globals.get_legacy_db_conn_string
  # {:adapter => "sqlserver", :host => "172.16.16.14",  :database => "KromcoData",dbc_legacy_personnell_db_conn_string :username => "sa"}
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
   return "DBI:ODBC:kromco_sql"
  end

   def Globals.get_odbc_legacy_personnell_db_conn_string
    return "DBI:ODBC:kromco_intrack"
  end

   def Globals.get_odbc_intrack_db_conn_string
     "DBI:ODBC:kromco_sql"
   end

  def Globals.get_legacy_personnell_db_conn_string
      host = "172.16.16.14"
      database = "KromcoPMS"
      username = "sa"
      password = ""
      #Password=#{password};
   return "DBI:ADO:Provider=SQLOLEDB;Data Source=#{host};Initial Catalog=#{database};User Id=#{username};Password = ''"

  end

  # Get the db connection parameters from the app's database.yml file
  def Globals.get_mes_conn_params(env='edi')
    config = YAML.load(File.read('config/database.yml'))[env]
   return {:adapter => config['adapter'],
           :host => config['host'],
           :database => config['database'],
           :username => config['username'],
           :password => config['password'],
           :port => config['port']}

  end

  # Get the db connection parameters from the app's database.yml file
  # Format for use in DBI connection. <tt>conn = DBI.connect(*Globals.get_mes_conn_params_for_dbi)</tt>
  def Globals.get_mes_conn_params_for_dbi(env='edi')
    config = YAML.load(File.read('config/database.yml'))[env]
    adapter = config['adapter'] == 'postgresql' ? 'Pg' : config['adapter']
    port = config['port'] ? ":#{config['port']}" : nil
    return "dbi:#{adapter}:#{config['database']}:#{config['host']}#{port}", config['username'], config['password']
  end

  def Globals.get_mes2_conn_params
   return {:adapter => "postgresql", :host => "192.168.10.179",  :database => "kromco_mes_live", :username => "postgres",:password => "postgres",:port => 5432}

  end

  def Globals.security_configs
    "public/security_configs/"
  end

  def Globals.models_to_exclude_from_scripts
     ["mrl_label_printing.rb","carton_label_printing.rb", "process_outbox.rb","outbox_processor.rb",
       "mf_account.rb","mf_account_farm.rb","mf_farm.rb","mf_product_code.rb","mf_product_code_target_market.rb","pallet_label_printing.rb",
       "carton_label_printing.rb","bin_ticket_printing.rb","mrl_label_printing.rb","send_edi_script.rb"
     ]
  end

  def Globals.is_scriptable_model?(model_name)
    if(Globals.models_to_exclude_from_scripts.include?(model_name))
      return false
    end
    return true
  end

  def Globals.get_bin_weighing_application_server
    "http://localhost"
  end

  def Globals.get_bin_weighing_application_name
    "SampleBinWeighingApp"
  end

  def Globals.get_bin_weighing_application_port
    "8080"
  end

  def Globals.jasper_reports_conn_params
   return {:adapter=>"jdbc:postgresql",
           :username=>"postgres",
           :password=>"postgres",
           :database=>"kromco_local",
           :host=>"localhost",
           :port => 5432}
  end

  def Globals.jasper_reports_printing_component
     Dir.getwd + "/jmt_reporting_server"
  end

  def Globals.signed_intake_docs
    Dir.getwd + "/public/downloads/signed_intake_docs/"
  end

  def Globals.jasper_reports_pdf_downloads
       Dir.getwd + "/public/downloads/pdf"
  end

  def Globals.jasper_reports_printer_name
#    actual printer_name = \\ace\jmt_printer
    "\\\\darth\\Canon iR2200-3300 PCL5e"
  end

  def Globals.jasper_source_reports_path
    #Path to intake.jasper
    Dir.getwd + "/jasper_resources"
  end

  def self.sub_report_dir
    Dir.getwd + "/jasper_resources/"
  end

   def Globals.intake_sub_report_dir
     #Path to intake_subreport1.jasper
     Dir.getwd + "/jasper_resources/"
  end

  def Globals.pdf417_sub_report_data_source_dir
    #Path to intake_subreport1.jasper's xml data source(xml file) N.B. is created and deleted of the fly
    Dir.getwd + "/jasper_xml/"
  end

  def Globals.pdf417_max_size
	  200
  end

  def Globals.get_alerts_server_port
    "80"
  end


  def Globals.get_alerts_server
    "exporter"
  end


  # Remove extraneous "and (true)" phrases from an SQL statement.
  def self.cleanup_where(statement)
    statement.gsub(/and\s+\(true\)/i, '')
  end

  # Takes two values and checks if both are blank or both are filled-in.
  # Options hash has messages to return for either condition:
  #
  # * :both_blank_msg
  # * :both_filled_in_msg
  def self.validate_either_or_choice(choice1, choice2, options)
    return options[:both_blank_msg]     if choice1.blank? && choice2.blank?
    return options[:both_filled_in_msg] if !choice1.blank? && !choice2.blank?
    nil
  end

  # Calls validate_either_or_choice after first checking if any choices are nil.
  # Options hash includes a message to return in the case of one nil choice and
  # the other choice blank:
  #
  # * only_one_and_blank_msg
  def self.validate_either_or_choice_with_optional_value(choice1, choice2, options)
    if choice1.nil? || choice2.nil?
      return nil if options[:only_one_and_blank_msg].nil? || (choice1.nil? && choice2.nil?)
      return options[:only_one_and_blank_msg] if choice1.nil? && choice2.blank? || choice1.blank? && choice2.nil?
      return nil
    end
    validate_either_or_choice(choice1, choice2, options)
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

  def Globals.bin_ticket_printer_name
    "PRN-01"
  end

  def Globals.bin_created_mssql_presort_server_port
    8080
  end

  def Globals.bin_tipped_mssql_integration_server_port
    3002
  end

  def Globals.bin_scanned_mssql_integration_server_port
    3002
  end

  def Globals.bin_created_mssql_server_host
    '192.168.50.17'
  end

  def Globals.bin_tipped_mssql_server_host
    '192.168.50.17'
  end

  def Globals.bin_scanned_mssql_server_host
    '192.168.50.17'
  end

  def Globals.suppress_pdt_web_errors

  end
end
