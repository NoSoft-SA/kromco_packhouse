class QcInspectionType < ActiveRecord::Base
  has_many :qc_reasons, :dependent => :destroy
  has_many :qc_inspection_type_reports, :dependent => :destroy
  has_many :qc_inspection_type_tests, :dependent => :destroy
  has_many :qc_tests, :through => :qc_inspection_type_test

  validates_presence_of :qc_inspection_type_code, :qc_inspection_type_description, :qc_business_context_search,
                        :qc_business_context_type_table_name, :qc_filter_context_search, :population_size

  # qc_filter_context_search is an SQL statement. Don't check for SQL injection.
  def fields_not_to_clean
    ['qc_filter_context_search']
  end

end
