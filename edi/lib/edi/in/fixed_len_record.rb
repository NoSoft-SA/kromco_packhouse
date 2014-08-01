require File.dirname(__FILE__) + "/text_record"

class FixedLenRecord < TextRecord
  
  def next_field_value(cursor_pos,size)
    @raw_text.slice(cursor_pos..cursor_pos-1 + size)
  end
end

