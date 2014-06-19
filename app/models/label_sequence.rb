
def build_class(label)
  fields = label.label_fields
  return if fields == nil || fields.length == 0
  code = "class LabelSequence \n"
  attr_reader = "attr_reader :fields, "  
  attr_writer = "attr_writer "  
  fields_set_method = "def set_fields \n @fields = Array.new"
  i = 0
  fields.each do |field|
    i += 1
    attr_reader += ":field_" + i.to_s + "," 
     attr_writer += ":field_" + i.to_s + "," 
     fields_set_method += "\n @fields.push({'field_" + i.to_s + "' => '" + field.label_field_code + "'})"
     fields_set_method += "\n self.field_" + i.to_s + " = '" + field.label_field_code + "'" 
  end
  
  attr_reader = attr_reader.slice(0,attr_reader.length() -1)
  attr_writer = attr_writer.slice(0,attr_writer.length() -1)
  code += attr_reader + "\n" + attr_writer + "\n\n" + fields_set_method + "\nend\nend"
  puts code
  eval code
end

class LabelSequence
  
  #----------------------------------------------------------
  #The constructor call the build_class method defines outside
  #this class which will add some methods to this class: getters
  #and setters for each label field
  #----------------------------------------------------------
  def initialize(label)
    
    build_class(label)
    if label.label_fields != nil ||label.label_fields.length > 0
      set_fields
    end
    
    
  end 
  def errors
  
  end
end