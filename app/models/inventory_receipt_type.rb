class InventoryReceiptType < ActiveRecord::Base

  #	===========================
  # 	Association declarations:
  #	===========================
    has_many :inventory_receipts
 
  #	============================
  #	 Validations declarations:
  #	============================
	validates_presence_of :inventory_receipt_type_code
	validates_uniqueness_of :inventory_receipt_type_code
	
  #	=====================
  #	 Complex validations:
  #	=====================
  def validate 
  #	first check whether combo fields have been selected
  	 is_valid = true
  end

  #	===========================
  #	 foreign key validations:
  #	===========================
  #	===========================
  #	 lookup methods:
  #	===========================

end