class CartonPresortConversion < ActiveRecord::Base

  #MM072014

  belongs_to :commodities
  belongs_to :rmt_varieties
  belongs_to :grades
  belongs_to :marketing_varieties
  belongs_to :treatments
  belongs_to :product_classes

  validates_presence_of :commodity_code
  validates_presence_of :rmt_variety_code
  validates_presence_of :grade_code
  validates_presence_of :line_type
  validates_presence_of :marketing_variety_code
  validates_presence_of :treatment_code
  validates_presence_of :product_class_code

  def validate
    if self.new_record?
      validate_uniqueness
    end
  end

  def validate_uniqueness
    exists = CartonPresortConversion.find_by_commodity_code_and_rmt_variety_code_and_grade_code_and_line_type_and_marketing_variety_code_and_treatment_code_and_product_class_code(self.commodity_code,self.rmt_variety_code,self.grade_code,self.line_type,self.marketing_variety_code,self.treatment_code,self.product_class_code)
    if exists != nil
      errors.add_to_base("There already exists a carton presort conversion record with the commodity_code, rmt_variety_code ,grade_code , line_type , marketing_variety_code ,treatment_code and product_class_code")
    end
  end

  def before_save

  end

  def after_destroy

  end

end