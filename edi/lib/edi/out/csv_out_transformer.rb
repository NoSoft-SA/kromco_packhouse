# This class creates a file of comma-separated values records from a HierarchicalRecordSet.
class CsvOutTransformer < OutTransformer
  include EdiFieldFormatter

  # Take the HierarchicalRecordSet and transform it into comma-separated values record set
  # using the schema's rules.
  def create_doc(doc_root)
    schema = record_schema( EdiHelper.current_out_flow, doc_root.doc_type )
    @csv_record_types ||= []
    @csv_record_types << doc_root.doc_type unless @csv_record_types.include? doc_root.doc_type
    s = make_csv_record( schema, doc_root.attributes ) << "\n"
    doc_root.children.each {|child| s << create_doc( child ) }
    s
  end

  # Return the +fields+ from the schema for this record type.
  def record_schema( flow_type, record_type )
    @record_schemas ||= {}
    @record_schemas[record_type] ||=
    begin
      path = "edi/in/transformers/#{flow_type.downcase}.xml"
      if !File.exist?(path)
        raise EdiProcessError, "CsvOutTransformer [Flow: '#{flow_type}', Rec: '#{record_type}']: File: #{path} does not exist"
      else
        xml_doc = nil
        File.open( path ) do |file|
          xml_doc = Nokogiri::XML(file)
        end
        raise EdiProcessError, "CsvOutTransformer [Flow: '#{flow_type}', Rec: '#{record_type}']: Schema: #{path} is of type: #{xml_doc.root["name"]}. You asked for: #{flow_type}" if xml_doc.root["name"] != flow_type
      end
      xml_doc.xpath(".//record[@identifier='#{record_type}']/fields/field")
    end
  end

  # Using the schema list of fields, build up a row of comma-separated values.
  def make_csv_record( schema, attributes )
    fields = []
    schema.each do |field|
      if field['type'] && field['type'] =~ /number/i
        fields << get_field_value( field, attributes[field['name']] )
      else
        fields << %Q|"#{get_field_value( field, attributes[field['name']])}"|
      end
    end
    fields.join(@field_delimiter)
  end

  # If the field is nil, return the default value.
  def get_field_value(field, value )
    if value.nil? && field['default']
      format_field( field, field['default'] )
    else
      format_field( field, value )
    end
  end

  # If the schema includes a format for the field apply it.
  def format_field( field, value )
    if field['format']
      format_edi_field( value, field['length'], field['format'] )
    else
      value
    end
  end

  # Validate the edi document against its schema.
  def validate(doc)
    header_type, line_type = @csv_record_types
    doc.each_with_index do |line, index|
      if 0 == index
        validate_csv_line( line, header_type )
      else
        validate_csv_line( line, line_type )
      end
    end
    true
  end

  # Validate one line from the csv output.
  def validate_csv_line( line, record_type )
    schema = record_schema( EdiHelper.current_out_flow, record_type )
    values = line.chomp.split(@field_delimiter)
    schema.each_with_index do |field, index|
      if values[index].nil? || '' == values[index] || '""' == values[index]
        raise EdiValidationError, "value required for field: #{field.to_s}" unless field['required'] && 'false' == field['required']
      end
    end
  end

  # Append <tt>.csv</tt> to the filename.
  def make_file_name(proposal, type='paltrack')
    super
    @filename << '.csv'
  end

end

