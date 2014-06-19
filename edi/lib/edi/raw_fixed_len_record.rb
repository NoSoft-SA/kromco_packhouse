# Fixed length record with the ability to read and write field values.
class RawFixedLenRecord
  include EdiFieldFormatter

  attr_reader :text_line
  attr_reader :fields

  # Create a record based on the +flow_type+ and +record_type+.
  # If the text_line is nil, the record is created using the record_type
  # and spaces up to the required length. Any default values are then applied.
  # If +must_have_size+ is set, RecordPadder will raise an exception if there is no
  # matching entry in the record_sizes.yml config file.
  def initialize(flow_type, record_type, text_line=nil, must_have_size=false)
    @copy_without_format = false
    @flow_type           = flow_type.upcase
    @record_type         = record_type
    @text_line           = text_line.nil? ? record_type : text_line
    @set_defaults        = text_line.nil?
    @text_line           = @text_line.ljust(RecordPadder.required_record_length(flow_type,
                                                                        record_type,
                                                                        @text_line.length,
                                                                        must_have_size))
    build_field_definitions
  end

  # Read the transformer schema for this flow type and make an array of
  # field names with their associated offset and length.
  # If the text_line was blank, any default values specified in the schema
  # are applied to the record.
  def build_field_definitions
    flow_type = @flow_type.downcase
    path = "edi/in/transformers/" + flow_type + ".xml"
    if !File.exist?(path)
      raise EdiProcessError "RawFixedLenRecord [Flow: '#{@flow_type}', Rec: '#{@record_type}']: File: " + path + " does not exist"
    else
      File.open( path ) do |file|
        @xml_doc = Nokogiri::XML(file)
      end
      raise EdiProcessError, "RawFixedLenRecord [Flow: '#{@flow_type}', Rec: '#{@record_type}']: Schema: " + path + " is of type: " + @xml_doc.root["name"] + ". You asked for: " + flow_type if @xml_doc.root["name"] != flow_type
    end
    field_nodes = @xml_doc.xpath(".//record[@identifier='#{@record_type}']/fields/field")

    @fields = []
    offset  = 0
    field_nodes.each do |field_node|
      fn  = field_node['name']
      len = field_node['size'].to_i
      fmt = field_node['format']
      @fields << [fn, offset, len, fmt]
      offset += len
      # Set the default value
      if @set_defaults && field_node.attributes['default']
        self[fn] = field_node.attributes['default'].to_s
      end
    end
  end

  # Is the field name present in this record?
  def has_field?( field_name )
    !@fields.assoc( field_name ).nil?
  end

  # Get the value of a given field
  def []( field_name )
    fn, offset, len = *@fields.assoc( field_name )
    raise EdiProcessError, "RawFixedLenRecord [Flow: '#{@flow_type}', Rec: '#{@record_type}']: Unknown field '#{field_name}'." if fn.nil? # AND log...
    @text_line[offset, len]
  end

  # Set the value of a given field.
  # If the length of the value does not match the expected length,
  # the value is not set and an error is logged. No exception is raised.
  # If the field definition has a format, the +raw_value+ is transformed first
  # by the EdiFieldFormatter using the format string.
  def []=( field_name, raw_value )
    fn, offset, len, fmt = *@fields.assoc( field_name )
    if @copy_without_format
      value = raw_value
    else
      value = format_edi_field( raw_value, len, fmt )
    end
    raise EdiProcessError, "RawFixedLenRecord [Flow: '#{@flow_type}', Rec: '#{@record_type}']: Unknown field '#{field_name}'." if fn.nil? # AND log...
    if value.length != len
      EdiHelper::edi_log.write "RawFixedLenRecord: Value not set: Field length for '#{field_name}' incorrect for record '#{@record_type}'. Was #{value.length}, expected #{len}.", 1
    else
      @text_line[offset, len] = value #if value.length == len # Don't alter if lengths do not match... (LOG IT)
    end
  end

  # Copy all matching field values from another record. (Except the first (record type) field).
  # Optionally pass in an array of field names to be ignored (not copied)
  def populate_with_values_from( other_record, ignore_fields = [] )
    @copy_without_format = true
    @fields.each do |field|
      next if ignore_fields.include? field[0]
      self[field[0]] = other_record[field[0]] if other_record.has_field?( field[0] ) && field[1] > 0
    end
    @copy_without_format = false
    @text_line
  end

  # Populate values
  def populate_values( attributes )
    attributes.each do |key, value|
      self[key] = value if has_field?( key )
    end
  end

end
