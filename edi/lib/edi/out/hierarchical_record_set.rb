# Hierarchical record set built up by an OutTransformer implementation.
class HierarchicalRecordSet
  attr_accessor :attributes, :children, :doc_type, :parent

  # Create without children. Set attributes and the document_type.
  def initialize( attributes, doc_type )
    @attributes = attributes
    @doc_type   = doc_type
    @parent     = nil
    @children   = []
  end

  # Add a child HierarchicalRecordSet to this instance.
  def add_child( record )
    @children << record
    record.parent = self
    record
  end

  # Remove a child HierarchicalRecordSet from this instance.
  def remove_child( record )
    @children.delete( record )
    record.parent = nil
  end

  # Does this instance have at least one child?
  def has_child?
    @children != []
  end

  # For debugging, show a simplified version of the tree.
  def to_s(indent=0)
    kids = @children.length == 0 ? '' : "#{@children.length} children."
    s = "#{@doc_type}: #{@attributes.length} attributes. #{kids}"
    ind = indent+2
    @children.each {|c| s << "\n#{' '*ind}#{c.to_s(ind)}" }
    s
  end
end
