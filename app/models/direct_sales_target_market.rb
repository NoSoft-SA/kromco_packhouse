class DirectSalesTargetMarket < ActiveRecord::Base

  #attr_accessor :target_market_code

  belongs_to :target_market
  #	============================
  #	 Validations declarations:
  #	============================
    validates_presence_of :direct_sales_target_market_code
    validates_uniqueness_of :direct_sales_target_market_code
  #	=====================
  #	 Complex validations:
  #	=====================
  def validate
    #	first check whether combo fields have been selected
    is_valid = true
    #validates uniqueness for this record
    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:direct_sales_target_market_code=>self.direct_sales_target_market_code}], self)
    end
    if is_valid
      is_valid = set_target_market
    end
  end

  def set_target_market
    target_market = TargetMarket.find_by_target_market_name(self.direct_sales_target_market_code)
    if target_market
      self.target_market = target_market
      return true
    else
      errors.add_to_base("Field target_market_code must be selected!")
      return false
    end
  end
  
end