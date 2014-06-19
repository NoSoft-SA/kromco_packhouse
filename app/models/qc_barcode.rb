class QcBarcode < ActiveRecord::Base
  
  #	============================
  #	 Validations declarations:
  #	============================
    validates_presence_of :pass_fail_barcode
    validates_presence_of :operator
    validates_uniqueness_of :pass_fail_barcode
  #	=====================
  #	 Complex validations:
  #	=====================
  def validate
    #	first check whether combo fields have been selected
    is_valid = true
    #validates uniqueness for this record
  end

end
