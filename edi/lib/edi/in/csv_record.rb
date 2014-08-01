require File.dirname(__FILE__) + "/text_record"

class CsvRecord < TextRecord
  attr_accessor :delimiter, :record_values

  def initialize(raw_text,field_descriptors,record_type,delimiter)
    @delimiter = delimiter
    @record_values = raw_text.split(@delimiter)
    super(raw_text,field_descriptors,record_type)
  end
  
  def next_field_value(cursor_pos,size)
    @record_values[cursor_pos]
  end
end