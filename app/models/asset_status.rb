class AssetStatus < ActiveRecord::Base

  #	===========================
  # 	Association declarations:
  #	===========================
    belongs_to :status
    belongs_to :asset_item
    
    attr_accessor :status_code
 
  #	============================
  #	 Validations declarations:
  #	============================
	validates_presence_of :status_id
	validates_presence_of :asset_item_id
	validates_numericality_of :quantity_damaged
	
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
 
 def create_status_code
   self.status_code = self.status.status_code
 end
  
  
  #	===========================
  #	 lookup methods:
  #	===========================

end