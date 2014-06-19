class QcInspectionTypeTest < ActiveRecord::Base

  #	===========================
  # 	Association declarations:
  #	===========================


  belongs_to :qc_inspection_type
  belongs_to :qc_test
  has_many   :qc_inspection_type_tests

  #	============================
  #	 Validations declarations:
  #	============================
  validates_numericality_of :sample_size
  validates_presence_of     :filter_column, :filter_value
  #	=====================
  #	 Complex validations:
  #	=====================
  def validate 
    #	first check whether combo fields have been selected
    is_valid = true
    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:qc_test_id => self.qc_test_id}],self) 
    end
    # #now check whether fk combos combine to form valid foreign keys
    # if is_valid
    #   is_valid = set_qc_test
    # end
    # if is_valid
    #   is_valid = ModelHelper::Validations.validate_combos([{:qc_inspection_type_code => self.qc_inspection_type_code}],self) 
    # end
    # #now check whether fk combos combine to form valid foreign keys
    # if is_valid
    #   is_valid = set_qc_inspection_type
    # end
  end

  #	===========================
  #	 foreign key validations:
  #	===========================
  # def set_qc_inspection_type

  #   qc_inspection_type = QcInspectionType.find_by_qc_inspection_type_code(self.qc_inspection_type_code)
  #   if qc_inspection_type != nil 
  #     self.qc_inspection_type = qc_inspection_type
  #     return true
  #   else
  #     errors.add_to_base("combination of: 'qc_inspection_type_code'  is invalid- it must be unique")
  #     return false
  #   end
  # end

  # def set_qc_test

  #   qc_test = QcTest.find_by_qc_test_type_id(self.qc_test_type_id)
  #   if qc_test != nil 
  #     self.qc_test = qc_test
  #     return true
  #   else
  #     errors.add_to_base("value of field: 'qc_test_type_id' is invalid- it must be unique")
  #     return false
  #   end
  # end

  #	===========================
  #	 lookup methods:
  #	===========================
  #	------------------------------------------------------------------------------------------
  #	Lookup methods for the foreign composite key of id field: qc_inspection_type_id
  #	------------------------------------------------------------------------------------------

  def self.get_all_qc_inspection_type_codes

    qc_inspection_type_codes = QcInspectionType.find_by_sql('select distinct qc_inspection_type_code from qc_inspection_types').map{|g|[g.qc_inspection_type_code]}
  end
end
