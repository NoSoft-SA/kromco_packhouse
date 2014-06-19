class BinOrderProduct < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================


  belongs_to :bin_order
  belongs_to :rmt_product


#  def after_create
#    StatusMan.set_status("ORDER_PRODUCT_CREATED", 'bin_order_product', self,session[:user_id].user_name)
#  end

  def calc_and_change_statuses(required_quantity,user_name)
    ActiveRecord::Base.transaction do
      bin_count =Bin.find_by_sql("select count(bins.bin_number)as bin_count from bins
                              inner join bin_order_load_details on bin_order_load_details.id=bins.bin_order_load_detail_id
                              inner join bin_order_products on  bin_order_products.id =bin_order_load_details.bin_order_product_id
                              where bin_order_products.id = #{self.id}")[0]['bin_count'].to_i
      if bin_count >= required_quantity.to_i
        change_statuses(user_name)
      end
    end
  end


  def change_statuses(user_name)
    ActiveRecord::Base.transaction do
      change_bin_order_product_status(user_name)

#

      bin_order_load_details = BinOrderLoadDetail.find_by_sql("
                        select bin_order_load_details.* from bin_order_load_details
                        inner join bin_order_products on bin_order_products.id = bin_order_load_details.bin_order_product_id
                        inner join bin_orders on bin_orders.id=bin_order_products.bin_order_id
                        where bin_order_products.id =#{ self.id.to_i} and bin_orders.id = #{ self.bin_order_id.to_i}")
      if !bin_order_load_details.empty?
         for bin_order_load_detail in bin_order_load_details
           change_bin_order_load_details_statuses(bin_order_load_detail,user_name)
          end
      end

            bin_order_loads=BinOrderLoad.find_by_sql("
                          select bin_order_loads.* from bin_order_loads
                          inner join bin_order_load_details on bin_order_load_details.bin_order_load_id=bin_order_loads.id
                          where bin_order_load_details.bin_order_product_id=#{self.id.to_i} and bin_order_loads.status='LOADING'" )


      if !bin_order_loads.empty?
        load_details_status= Array.new
        bin_loads          = Array.new

        for bin_order_load in bin_order_loads
          bin_order_load_details=BinOrderLoadDetail.find_all_by_bin_order_load_id(bin_order_load.id)
          bin_load              =BinLoad.find(bin_order_load.bin_load_id)
          #bin_loads<<  bin_load

          if !bin_order_load_details.empty?
            for bin_order_load_detail in bin_order_load_details
              load_details_status << bin_order_load_detail.status
            end
          end
          if load_details_status.include?("LOADING") || load_details_status.include?("LOAD_DETAIL_CREATED") ||load_details_status.include?("EMPTY")
          else
            change_bin_order_loads_statuses(bin_order_load,user_name)
            change_bin_load_statuses(bin_load,user_name)
          end
          load_details_status.clear
        end
      end

      order_load_count = BinOrderLoad.find_by_sql("select COUNT(bin_order_loads.*) as order_load_count from bin_order_loads
                        inner join bin_orders on bin_order_loads.bin_order_id=bin_orders.id
                        where (bin_order_loads.status='LOADING'OR bin_order_loads.status='LOAD_CREATED')and bin_orders.id =#{self.bin_order_id}
                                                  ").map { |h| h.order_load_count }[0].to_i

      if order_load_count==0
        bin_order = BinOrder.find(self.bin_order_id)
        change_bin_order_status(bin_order,user_name)
      end
    end
  end

  def change_bin_order_load_details_statuses(bin_order_load_detail,user_name)

      StatusMan.set_status("LOADED", "bin_order_load_detail", bin_order_load_detail,user_name)
  end

  def change_bin_order_loads_statuses(bin_order_load,user_name)

    StatusMan.set_status("LOADED", "bin_order_load", bin_order_load,user_name)

  end

  def change_bin_order_status(bin_order,user_name)
    StatusMan.set_status("LOADED", "bin_order", bin_order,user_name)
  end

  def change_bin_order_product_status(user_name)
    StatusMan.set_status("LOADED", "bin_order_product", self,user_name)
  end

  def change_bin_load_statuses(bin_load,user_name)

    StatusMan.set_status("LOADED", "bin_load", bin_load,user_name)

  end

end
