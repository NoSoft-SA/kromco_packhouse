# Control the processing of EDI input files.
class InProcess
  include EdiSetup

  require "fileutils"
  def initialize(dir_path, interval)
    @ar_connected = false
    begin

      puts "working dir: " + Dir.getwd

      puts "loading libraries..."
      load_libs
      puts "libraries loaded"

      proc_dir = "edi/logs/in/" +  Time.now.strftime("%Y_%m_%d")
      FileUtils.makedirs(proc_dir)
      edi_log = EdiHelper.make_edi_log(proc_dir)
      edi_log.write "loading models..."

      load_models
      edi_log.write "models loaded"
      edi_log.write "loading edi modules..."

      load_edi_modules
      edi_log.write "edi modules loaded"
      edi_log.write "setting up db connections..."

      @ar_connected = set_up_connections
      edi_log.write " db connections established"

      edi_log.write "processing edi-in docs in dir: " + dir_path + "..."
      FolderProcessor.new(dir_path,"ed_in_proc","1.2.3",interval).run()

    rescue
      puts "Exception in main edi in process.\n " + $!
      puts "Exception Stacktrace = " + $!.backtrace.join("\n").to_s
      if edi_log
        edi_log.write  "Exception in main edi in process.\n " + $!
        edi_log.write "Exception Stacktrace = " + $!.backtrace.join("\n").to_s
      end
    ensure
      if @ar_connected
        ActiveRecord::Base.connection.disconnect!()
        ActiveRecord::Base.remove_connection
      end
    end


  end

  def load_edi_modules
    
    require "edi/lib/edi/in/in_transformer_support"

    Dir.foreach("edi/lib/edi/in") do |entry|
      next if entry == 'in_transformer_support'
      require "edi/lib/edi/in/" + entry  if entry.index(".rb")
    end

    Dir.foreach("edi/in/transformers") do |entry|
      require "edi/in/transformers/" + entry  if entry.index(".rb")
    end

    Dir.foreach("edi/in/pre_processors") do |entry|
      require "edi/in/pre_processors/" + entry  if entry.index(".rb")
    end

  end

  def get_pre_processor()

  end

end

