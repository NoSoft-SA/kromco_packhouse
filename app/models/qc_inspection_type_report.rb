class QcInspectionTypeReport < ActiveRecord::Base
  belongs_to :qc_inspection_type
  validates_presence_of :report_name, :report_description
  validates_format_of :report_name, :with => /\A[a-zA-Z0-9_-]+\z/, :message => 'can only contain alphanumerics, "-" and "_" (no spaces!).'

end
