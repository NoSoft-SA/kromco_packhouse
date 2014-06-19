class Label < ActiveRecord::Base
 has_many :label_fields
 has_and_belongs_to_many :printer_formats
 belongs_to :label_type
 
 def set_fields_sequence(sequence)
  
  self.transaction do 
    for i in 0..sequence.length() -1
      label_field = LabelField.find_by_label_id_and_label_field_code(self.id,sequence[i])
      label_field.print_sequence_number = i
      label_field.save
    
    end
  
  end
 
 end
 
end
