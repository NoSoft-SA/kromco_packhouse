class Product < ActiveRecord::Base
  
  belongs_to :product_type
  belongs_to :uom
  has_many :composite_products
  belongs_to :product_subtype
  
  validates_presence_of :product_code
  
  attr_accessor :quantity
  
  
  def before_save
  
    if self.is_composite
      if self.new_record? 
        composite = CompositeProduct.new
        composite.product_code = self.product_code
        self.composite_products.push composite
       else
         old_product = Product.find(self.id)
         if old_product.product_code != self.product_code
           CompositeProduct.update_all("product_code = '#{self.product_code}'","product_code = '#{old_product.product_code}'")
           CompositeProduct.update_all("childproduct_code = '#{self.product_code}'","childproduct_code = '#{old_product.product_code}'")
         end
       end
    end
    
    if self.product_subtype_code
      self.product_subtype = ProductSubtype.find_by_product_type_code_and_product_subtype_code(self.product_type_code,self.product_subtype_code)
    end
  end
  
  
  def before_destroy
    #if this product is a composite, then we need to destroy the corresponding 
    #composite record
    if self.is_composite
      self.composite_products.find(:first,:conditions => "product_code = '#{self.product_code}'").destroy
    end
  
  
  end
  
end











