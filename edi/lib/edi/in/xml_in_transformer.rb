# Transform EDI files that come in as xml files.
class XmlInTransformer
  include InTransformerSupport

  # Create with xml in +raw_text+ and +flow_type+.
  def initialize(raw_text, flow_type, user = nil, ip = nil, doc_name = nil, in_or_out='in')
    @flow_type = flow_type
    @raw_text  = raw_text
    @xsd       = nil
    @user      = user
    @ip        = ip
    @doc_name  = doc_name
    @transformer = 

    create_logger( in_or_out )

    path = File.join("edi/in/transformers/", "#{flow_type}.xsd")
    if !File.exist?(path)
      raise EdiValidationError, "File: #{path} does not exist"
    else
      @xsd = Nokogiri::XML::Schema(File.read(path))
    end

    @xml = Nokogiri::XML( @raw_text )
  end

  # Validate the xml against the +flow_type+'s xsd schema.
  def parse
    @logger.write "Start parsing for flow_type #{@flow_type} user: #{@user} ip: #{@ip}",1

    is_ok = @xsd.valid?(@xml)
    unless is_ok
      err_msg = @xsd.validate(@xml).map { |error| error.message }.join("\n")
      handle_error( 'parse', err_msg )
    end
    
    @logger.write "End parsing for flow_type #{@flow_type} user: #{@user} ip: #{@ip}",1
    
    if is_ok
      nil
    else
      true
    end

  rescue StandardError => error
    handle_error('parse', nil, error)
    return error
  end

  # Process the xml by loading its associated transformer and calling the execute method.
  def run
    @logger.write "Start transforming flow_type #{@flow_type} user: #{@user} ip: #{@ip}",1

    require "edi/in/transformers/" + @flow_type + ".rb"
    klass = Inflector.camelize(@flow_type)
    transformer = eval klass + ".new"

    ActiveRecord::Base.transaction do
      transformer.execute( @xml )
      @logger.write "End transforming flow_type #{@flow_type} user: #{@user} ip: #{@ip}",1
      return nil
    end

  rescue StandardError => error
    handle_error('execute', nil, error)
    return error
  end

end
