class LabelField < ActiveRecord::Base
  has_many :label_fields,
           :order => "print_sequence_number"
end
