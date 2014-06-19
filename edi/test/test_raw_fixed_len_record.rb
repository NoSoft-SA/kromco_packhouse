require File.dirname(__FILE__) + '/test_helpers'

class RawFixedLenRecordTest < Test::Unit::TestCase
  def test_blank_flow
    rec = RawFixedLenRecord.new('PO', 'OP')
    assert rec.text_line =~ /OP\s+/
  end
  def test_blank_flow_length
    rec = RawFixedLenRecord.new('PO', 'OP')
    assert rec.text_line.length == 605, "Excpected 605, got #{rec.text_line.length}."
  end
  def test_blank_flow_should_have_field
    rec = RawFixedLenRecord.new('PO', 'OP')
    assert rec.has_field? 'load_id'
  end
  def test_blank_flow_should_not_have_field
    rec = RawFixedLenRecord.new('PO', 'OP')
    assert !rec.has_field?( 'load_id_misspelled' )
  end
end
