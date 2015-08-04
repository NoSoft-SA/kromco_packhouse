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


  def Globals.reworks_printer_name
    "PRN-01"
  end

  def Globals.get_jasper_server_report_server_ip
    "http://172.16.16.1:8080"
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


  def Globals.currency(env, value)
    env.number_to_currency(value, :unit => "R", :separator => ",", :delimiter => "")
  end









  def Globals.get_jasper_server
    "/jasperserver/flow.html?_flowId=viewReportFlow&"
  end

  def Globals.get_jasperserver_username_password
    "j_username=jasperadmin&j_password=jasperadmin&"
  end










  def Globals.mrl_printer_ip
    "172.16.16.14"
  end

  def Globals.bin_ticket_printing_ip
    "172.16.16.1"
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
    2080
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
    "http://localhost:3000"
  end

  def Globals.suppress_pdt_web_errors
    false
  end
  #=====================
  # Luks
  #=====================

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
            :port => config['port']}

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
    return {:adapter=>"jdbc:postgresql",
            :username=>"postgres",
            :password=>"postgres",
            :database=>"kromco_mes",
            :host=>"172.16.16.15",
            :port => 5432}

  end
  #_________________________
  #No need to change this i.e. the reporting server comes with this project
  def Globals.jasper_reports_printing_component
    Dir.getwd + "/jmt_reporting_server"
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

  #def Globals.pdf417_max_size
  #  200
  #end
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
    65000
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
    "/home/jre1.6.0_25/bin/java"
  end

  def Globals.signed_intake_docs
    Dir.getwd + "/public/downloads/signed_intake_docs/"
  end

  def Globals.currency(env, value)
    env.number_to_currency(value, :unit => "", :separator => ",", :delimiter => "")
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

  def Globals.ms_sql_server_host
    '172.16.16.1'
  end

  def Globals.bin_created_mssql_presort_server_port
    8085
  end

  def Globals.bin_tipped_mssql_integration_server_port
    8084
  end

  def Globals.bin_scanned_mssql_integration_server_port
    8084
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

end
