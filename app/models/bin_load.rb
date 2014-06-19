class BinLoad < ActiveRecord::Base 
	   attr_accessor :bin_order_load_id
#	===========================
# 	Association declarations:
#	===========================
    
	belongs_to :load_type
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :vehicle_empty_mass_in
	validates_presence_of :tare_mass_in
#	=====================
#	 Complex validations:
#	=====================
#def validate
##	first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:load_type_code_id => self.load_type_code_id}],self)
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_load_type
#	 end
#end

def selected_load_details(order_products,parameter_fields_values,user_name)
    ActiveRecord::Base.transaction do
      bin_load_id = self.id
      bin_order_load_id = BinOrderLoad.find_by_bin_load_id(bin_load_id).id
      for order_product in order_products
       @bin_order_load_detail =BinOrderLoadDetail.new
       @bin_order_load_detail.bin_order_load_id = bin_order_load_id
       @bin_order_load_detail.bin_order_product_id =order_product.id
        @bin_order_load_detail.save
       StatusMan.set_status("LOAD_DETAIL_CREATED",'bin_order_load_detail',@bin_order_load_detail,user_name)


    end
   end
end

def set_status(new_status)
     ActiveRecord::Base.transaction do
     self.status = new_status
     self.update
     
    end
  end


 



end
