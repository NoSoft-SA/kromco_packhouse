# Methods shared by the in and out EDI processes as well as the file joiner.
module EdiSetup

  # Load ActiveRecord and other gems. Load extensions.
  def load_libs( silent=false)
    # Check if the rails version has changed without these gem versions changing:
#    env = File.foreach('config/environment.rb').select {|l| l=~ /RAILS_GEM/ }
    #    ruby 1.8.6 requires block for foreach!
    env = []
    File.foreach('config/environment.rb') {|l| env << l if l =~ /RAILS_GEM/ }
    rails_version_ok = false
    env.each do |rv_line|
      rails_version_ok = rv_line.include?( '1.2.3' ) && (rv_line =~ /^\s*#/) == nil
    end
    raise EdiProcessError, "EDI Engine is loading a different version of Rails libraries." unless rails_version_ok

    puts "loading gems" unless silent
    require "rubygems"
    # Specific versions of rails gems to load:
    gem 'activerecord',  '= 1.15.3'
    gem 'actionmailer',  '= 1.3.3'
    gem 'actionpack',    '= 1.13.3'
    gem 'activesupport', '= 1.4.2'

    require "active_record"
    # require "active_record/version"
    # puts ActiveRecord::VERSION::STRING
    require "action_mailer"

    # If present, use the rails-dbi gem instead of the dbi gem.
    # The rails-dbi gem does not use ver 2.0.1 of the Deprecated gem which conflicts with
    # ActiveRecord's deprecated calls.
    # "gem ... :require ... " bombed in windows: ruby 1.8.6, gem 1.3.1
    begin
      gem 'rails-dbi'#, :require => 'dbi'
    rescue Gem::LoadError
      # Swallow the error if the gem is not installed and fall back on the standard dbi gem
    end
    require "dbi"


    require "logger.rb"
    puts "loading extensions" unless silent
    require "lib/extensions.rb"
    require "lib/globals.rb"
    require "lib/model_helper.rb"
    require "lib/masterfile_validator"    
  end

  # Connect to the database
  def set_up_connections
    EdiHelper::edi_log.write "connecting to db.."
    ActiveRecord::Base.establish_connection(Globals.get_mes_conn_params)
    EdiHelper::edi_log.write "connected to db"  
    true
  end

  def load_inventory_model
    require "lib/inventory"
  end

  def load_comparer_tool
    require "lib/comparer.rb"
  end

  def load_status_man
    require "status_man/lib/status_change_event_handler"
    require "status_man/lib/status_man"
  end

  # Load the rails app's models with the exception of those that have side-effects when loaded.
  # (See EdiHelper constant NO_LOAD_MODELS for a list of non-loaded models)
  # (See EdiHelper constant MODULE_MODELS for a list of modules that must be loaded first)
  def load_models
    # Pre-load modules that may be included by models.
    EdiHelper::MODULE_MODELS.each do |entry|
      require "app/models/#{entry}" if File.exists?("app/models/#{entry}")
    end

    # Load the models.
    Dir.foreach("app/models") do |entry|
      if entry.index(".rb") && !EdiHelper::NO_LOAD_MODELS.include?( entry )
        require "app/models/" + entry
      end
    end

  rescue StandardError => error
    raise EdiProcessError, "Models not loaded correctly: " << error
  end

  # Read the config file and set log levels appropriately.
  def check_log_levels
    configs = YAML::load(File.read(EdiHelper::APP_ROOT + '/edi/config/config.yml'))
    configs['log_levels'].each {|k,v| Globals.log_levels[k] = v }
    configs['console_log_levels'].each {|k,v| Globals.console_log_levels[k] = v }
  end

  # Read the config file and set helper attributes appropriately.
  def get_config_values
    configs = YAML::load(File.read(EdiHelper::APP_ROOT + '/edi/config/config.yml'))
    EdiHelper.network_address = configs['network_address']
    EdiHelper.log_memory_string = configs['log_memory_string'] || false
  end

  # Read the config file and set helper attributes appropriately.
  def get_config_values_for_in_process
    configs = YAML::load(File.read(EdiHelper::APP_ROOT + '/edi/config/config.yml'))
    EdiHelper.process_dot_zip_files = configs['process_dot_zip_files'] || false
  end

end
