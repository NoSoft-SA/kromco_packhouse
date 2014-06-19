class OrderProduct < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================


  belongs_to :order
  belongs_to :order_product_type
  has_one :load_detail



  #attr_accessor :subtotal
 def sub_total
    @sub_total= self.price * self.required_quantity
  end

  #
  #   subtotal for each product in an order,
  #   displayed on the grid
  #
  def fields_not_to_clean
    ["cartons_lookup_sql"]
  end

  
end
