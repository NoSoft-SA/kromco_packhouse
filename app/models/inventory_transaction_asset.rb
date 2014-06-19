class InventoryTransactionAsset < ActiveRecord::Base

    #attr_accessor :transaction_type_code, :transaction_business_name_code
  #	===========================
  # 	Association declarations:
  #	===========================
    has_many :inventory_transaction_locations
 
  #	============================
  #	 Validations declarations:
  #	============================
	validates_presence_of :asset_number
	validates_presence_of :asset_type_id
	validates_presence_of :quantity
#	validates_presence_of :current_location
	validates_numericality_of :asset_type_id
	validates_numericality_of :quantity
	validates_numericality_of :party_role_id
	validates_presence_of :inventory_transaction_id
	validates_numericality_of :inventory_transaction_id
	
  #	=====================
  #	 Complex validations:
  #	=====================
  def validate 
     # first check whether combo fields have been selected
	 is_valid = true
#	 if is_valid
#	   is_valid = ModelHelper::Validations.validate_combos([{:stock_type_code => self.stock_type_code}],self) 
#	 end
#	 if is_valid
#	   is_valid = set_stock_type
#	 end
#	 
#	 if is_valid
#	   is_valid = ModelHelper::Validations.validate_combos([{:location_code => self.location_code}],self)
#	 end
#	 if is_valid
#	   is_valid = set_location
#	 end 
	 
  end

  #	===========================
  #	 foreign key validations:
  #	===========================
#  def set_stock_type
#    stock_type = StockType.find_by_stock_type(self.stock_type_code);
#    if stock_type != nil
#      self.stock_type = stock_type
#      return true
#    else
#      errors.add_to_base("Field: 'stock_type_code' is invalid- it must be unique")
#      return false
#    end
#  end
#  
#  def set_location
#    location = Location.find_by_location_code(self.location_code)
#    if location != nil
#      self.location = location
#      return true
#    else
#      errors.add_to_base("Field: 'location_code' is invalid- it must be unique")
#      return false
#    end
#  end
 
  
  
  #	===========================
  #	 lookup methods:
  #	===========================

end