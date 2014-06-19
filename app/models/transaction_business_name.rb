class TransactionBusinessName < ActiveRecord::Base

  #	===========================
  # 	Association declarations:
  #	===========================
    has_many :inventory_transaction
    
 
  #	============================
  #	 Validations declarations:
  #	============================
	validates_presence_of :transaction_business_name_code
	validates_uniqueness_of :transaction_business_name_code
	
	
  #	=====================
  #	 Complex validations:
  #	=====================
  def validate 
     # first check whether combo fields have been selected
	 is_valid = true
	 
  end

  #	===========================
  #	 foreign key validations:
  #	===========================
  
  
  #	===========================
  #	 lookup methods:
  #	===========================

end