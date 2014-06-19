class QcReason < ActiveRecord::Base

  belongs_to :qc_inspection_type
  has_and_belongs_to_many :qc_inspections

  validates_presence_of :qc_reason_code, :qc_reason_description

end
