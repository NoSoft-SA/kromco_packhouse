# Helper module for EDI process.
module EdiHelper
  require 'pathname'

  APP_ROOT = Pathname.new(File.join(File.dirname(__FILE__), '../../..')).cleanpath.to_s

  # These are models that must not be loaded by the EDI processes as they have side-effects:
  NO_LOAD_MODELS = %w{carton_label_printing.rb process_outbox.rb outbox_processor.rb
                    outbox_processor_debug.rb bin_ticket_printing.rb mrl_label_printing.rb
                    pallet_label_printing.rb rw_active_carton.rb pallet_label_printing.rb
                    mrl_result_print_command.rb send_edi_script.rb}

  # Should in-memory string be logged?
  def self.log_memory_string
    @@log_memory_string ||= false
  end

  def self.log_memory_string=(value)
    @@log_memory_string = value
  end

  # This network address (from Depot)
  def self.network_address
    @@network_address ||= '999'
  end

  def self.network_address=(value)
    @@network_address = value
  end

  # Create a log file for EDI processes.
  def self.make_edi_log( dir, type='in' )
    @@edi_log = Log.new(dir, "edi_#{type}.log", "edi_#{type}")
  end

  # Returns EDI log file
  def self.edi_log
    @@edi_log || nil
  end

  # The current EDI IN file being processed
  def self.edi_in_process_file
    @@edi_in_process_file ||= 'unknown'
  end

  def self.edi_in_process_file=(value)
    @@edi_in_process_file = value
  end

  # The EDI OUT directory
  def self.edi_out_process_dir
    @@edi_out_process_dir ||= nil
  end

  def self.edi_out_process_dir=(value)
    @@edi_out_process_dir = Pathname.new(value).expand_path
    raise EdiProcessError, "Dir \"#{@@edi_out_process_dir}\" does not exist" unless @@edi_out_process_dir.exist?
  end

  # The EDI OUT join directory
  def self.edi_out_process_join_dir
    @@edi_out_process_join_dir ||= nil
  end

  def self.edi_out_process_join_dir=(value)
    @@edi_out_process_join_dir = Pathname.new(value).expand_path
    raise EdiProcessError, "Dir \"#{@@edi_out_process_join_dir}\" does not exist" unless @@edi_out_process_join_dir.exist?
  end

  def self.current_out_subdirs
    @@current_out_subdirs ||= []
  end

  def self.current_out_subdirs=( value )
    @@current_out_subdirs = value
  end

  # The current EDI out flow type being processed
  def self.current_out_flow
    @@current_out_flow ||= 'unknown'
  end

  def self.current_out_flow=(value)
    @@current_out_flow = value
  end

  def self.current_out_is_cumulative
    @@current_out_is_cumulative ||= false
  end

  def self.current_out_is_cumulative=(value)
    @@current_out_is_cumulative = value
  end


  # Create a log file for EDI transforms.
  def self.make_transform_log( dir, name, in_or_out )
    @@transform_log = Log.new(dir, name, "transformer_#{in_or_out}")
  end

  # Returns EDI transform log file
  def self.transform_log
    @@transform_log || nil
  end

  # Called by models (eg. PDF417) to load required files after requiring this module.
  # Used for edi IN process.
  def self.load_edi_in_files_for_web_context
    require 'nokogiri'
    lib_path = 'edi/lib'
    $LOAD_PATH.unshift lib_path unless $LOAD_PATH.include? lib_path
    require 'edi/edi_errors'
    require 'edi/edi_setup'
    require 'edi/edi_field_formatter'
    require 'edi/raw_fixed_len_record'
    require 'edi/in/doc_event_handlers'
    require 'edi/in/record_padder'
    require 'edi/in/in_transformer_support'
    require 'edi/in/text_in_transformer'
    require 'edi/in/fixed_len_record'
  end

  # Called by models (eg. EdiOutProposal) to load required files after requiring this module.
  # Used for edi OUT process.
  def self.load_edi_files_for_web_context
    require 'nokogiri'
    lib_path = 'edi/lib'
    $LOAD_PATH.unshift lib_path unless $LOAD_PATH.include? lib_path
    require 'edi/edi_errors'
    require 'edi/edi_setup'
    require 'edi/edi_field_formatter'
    require 'edi/raw_fixed_len_record'
    require 'out_process'
    require 'out_process_in_memory'
  end

end
