# This class creates a file of fixed-length records from a HierarchicalRecordSet.
class TextOutTransformer < OutTransformer

  # Take the HierarchicalRecordSet and transform it into fixed-length record set
  # using the schema's rules.
  def create_doc(doc_root)
    fixed_len_rec = RawFixedLenRecord.new(EdiHelper.current_out_flow, doc_root.doc_type, nil, true)
    fixed_len_rec.populate_values( doc_root.attributes )
    s = fixed_len_rec.text_line << "\n"
    doc_root.children.each {|child| s << create_doc( child ) }
    s
  end

end
