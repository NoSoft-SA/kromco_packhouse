class BinOrder < ActiveRecord::Base

  belongs_to :parties_role, :foreign_key => 'customer_party_role_id'
  has_many :bin_order_empty_bins

#  has_many :bin_order_load_details, :dependent => :delete_all
#  has_many :bin_order_loads, :dependent => :delete_all
#  has_many :bin_loads, :dependent => :delete_all
#  has_many :bin_order_products, :dependent => :delete_all


#	===========================
# 	Association declarations:
#	===========================


#	============================
#	 Validations declarations:
#	============================
  def validate
    is_valid = true

    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:order_type_id => self.order_type_id}], self)
    end
    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:trading_partner_party_role_id => self.trading_partner_party_role_id}], self)
    end

    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:customer_party_role_id => self.customer_party_role_id}], self)
    end
  end

#	=====================
#	 Complex validations:
#	=====================
#  def find_objects
#    ActiveRecord::Base.transaction do
#      #decouple bins from load_details
#      bin_numbers=BinOrderLoadDetail.find_by_sql("select bins.* from bins
#                        inner join bin_order_load_details on bin_order_load_details.id= bins.bin_order_load_detail_id
#                        inner join bin_order_loads on bin_order_loads.id = bin_order_load_details.bin_order_load_id
#                        inner join bin_orders on bin_orders.id=bin_order_loads.bin_order_id
#                        where bin_order_loads.bin_order_id =#{ self.id.to_i}  ").map { |b| b.bin_number }
#
#
#      for bin_number in bin_numbers
#        bin            = Bin.find_by_bin_number(bin_number)
#        bin_attributes = bin.attributes
#        deleted_bin    =DeletedBin.new
#        deleted_bin.id = bin.id
#        deleted_bin.deleted_bin_order_load_detail_id =bin.bin_order_load_detail_id
#        deleted_bin.save
#        for bin_attribute in bin_attributes
#          if deleted_bin.attributes.has_key?("#{bin_attribute[0]}")
#            deleted_bin.update_attribute(:"#{bin_attribute[0]}", "#{bin_attribute[1]}")
#          end
#        end
#      end
#      if !bin_numbers.empty?
#        Bin.bulk_update({:bin_order_load_detail_id =>"null"}, 'bin_number', bin_numbers, nil)
#      end
#    end
#  end

  def archive_bin_order_objects(user_name)

    archive_bin_orders(user_name)

  end

  def archive_bin_orders(user_name)

    ActiveRecord::Base.transaction do

      deleted_bin_order    =DeletedBinOrder.new
      deleted_bin_order.id = self.id
      deleted_bin_order.save
      bin_order_attributes= self.attributes
      for bin_order_attribute in bin_order_attributes
        if deleted_bin_order.attributes.has_key?("#{bin_order_attribute[0]}")
          deleted_bin_order.update_attribute(:"#{bin_order_attribute[0]}", "#{bin_order_attribute[1]}")
        end
      end


    archive_bin_order_products(deleted_bin_order, user_name)
    archive_bin_loads_and_load_details(deleted_bin_order, user_name)
    complete_cancel

    end

  end

  def archive_bin_order_products(deleted_bin_order, user_name)
    #bin_order_products
      bin_order_products= BinOrderProduct.find_all_by_bin_order_id(self.id.to_i)
      if !bin_order_products.empty?
        for bin_order_product in bin_order_products
          deleted_bin_order_product    =DeletedBinOrderProduct.new
          deleted_bin_order_product.id =bin_order_product.id
          deleted_bin_order_product.save
          deleted_bin_order_product.deleted_bin_order_id=deleted_bin_order.id
          deleted_bin_order_product.update
          bin_order_product_attributes=bin_order_product.attributes
          for bin_order_product_attribute in bin_order_product_attributes
            if deleted_bin_order_product.attributes.has_key?("#{bin_order_product_attribute[0]}")
              deleted_bin_order_product.update_attribute(:"#{bin_order_product_attribute[0]}", "#{bin_order_product_attribute[1]}")
            end
          end
        end

      end


  end


  def archive_bin_loads_and_load_details(deleted_bin_order, user_name)
    ActiveRecord::Base.transaction do
      bin_loads = BinLoad.find_by_sql("select bin_loads.* from bin_loads
                                    inner join bin_order_loads on bin_order_loads.bin_load_id=bin_loads.id
                                    where bin_order_loads.bin_order_id='#{self.id.to_i}'")

      if !bin_loads.empty?
        for bin_load in bin_loads
          deleted_bin_load    =DeletedBinLoad.new
          deleted_bin_load.id =bin_load.id
          deleted_bin_load.save
          bin_load_attributes= bin_load.attributes
          for bin_load_attribute in bin_load_attributes
            if deleted_bin_load.attributes.has_key?("#{bin_load_attribute[0]}")
              deleted_bin_load.update_attribute(:"#{bin_load_attribute[0]}", "#{bin_load_attribute[1]}")
            end
          end
          #bin_order_loads
          bin_order_load                             =BinOrderLoad.find_by_sql("select * from bin_order_loads where bin_load_id=#{bin_load.id.to_i}")[0]
          deleted_bin_order_load                     =DeletedBinOrderLoad.new
          deleted_bin_order_load.deleted_bin_order_id=deleted_bin_order.id
          deleted_bin_order_load.deleted_bin_load_id                        =deleted_bin_load.id
          deleted_bin_order_load.id = bin_order_load.id
          deleted_bin_order_load.save

          #bin_order_load_details

          bin_order_load_details = BinOrderLoadDetail.find_by_sql("select * from bin_order_load_details where bin_order_load_id=#{bin_order_load.id}")
          if !bin_order_load_details.empty?
            for bin_order_load_detail in bin_order_load_details
              bin_order_product = BinOrderProduct.find(bin_order_load_detail.bin_order_product_id)
              deleted_bin_order_load_detail                             =DeletedBinOrderLoadDetail.new
              deleted_bin_order_load_detail.id                          =bin_order_load_detail.id
              deleted_bin_order_load_detail.deleted_bin_order_product_id=bin_order_product.id
              deleted_bin_order_load_detail.deleted_bin_order_load_id   =deleted_bin_order_load.id
              deleted_bin_order_load_detail.save
              bin_order_load_detail_attributes=bin_order_load_detail.attributes
              for bin_order_load_detail_attribute in bin_order_load_detail_attributes
                if deleted_bin_order_load_detail.attributes.has_key?("#{bin_order_load_detail_attribute[0]}")
                  deleted_bin_order_load_detail.update_attribute(:"#{bin_order_load_detail_attribute[0]}", "#{bin_order_load_detail_attribute[1]}")
                end
              end
              bins = Bin.find_all_by_bin_order_load_detail_id(bin_order_load_detail.id)
              bin_numbers=Array.new
              if !bins.empty?
                  for bin in bins

                    bin_attributes = bin.attributes
                    deleted_bin    =DeletedBin.new
                    deleted_bin.id = bin.id
                    deleted_bin.deleted_bin_order_load_detail_id =bin.bin_order_load_detail_id
                    deleted_bin.save
                    for bin_attribute in bin_attributes
                      if deleted_bin.attributes.has_key?("#{bin_attribute[0]}")
                        deleted_bin.update_attribute(:"#{bin_attribute[0]}", "#{bin_attribute[1]}")
                      end
                    end
                    bin_numbers << bin.bin_number
                  end

                    Bin.bulk_update({:bin_order_load_detail_id =>"null"}, 'bin_number', bin_numbers, nil)

             end
            end
          end


        end


      end
    end
  end

  def complete_cancel

    begin
      self.transaction do
       bin_order_load_details_query="delete from  bin_order_load_details where id IN (
                                    select bin_order_load_details.id from bin_order_load_details
                                    inner join bin_order_loads on bin_order_load_details.bin_order_load_id=bin_order_loads.id
                                    inner join bin_orders on bin_orders.id= bin_order_loads.bin_order_id
                                    where bin_order_loads.bin_order_id=#{self.id.to_i})"

       bin_order_products_query="delete from bin_order_products where id IN (select id from bin_order_products where bin_order_id=#{self.id.to_i})"

       bin_order_loads_query="delete from  bin_order_loads where id IN (select id from bin_order_loads where bin_order_id=#{self.id.to_i})"

       bin_loads_query ="delete from bin_loads where id IN(select bin_loads.id from bin_loads
                        inner join bin_order_loads on bin_order_loads.bin_load_id=bin_loads.id
                        inner join bin_orders on bin_order_loads.bin_order_id=bin_orders.id
                        where bin_orders.id=#{self.id.to_i})"

       #delete

    self.connection.execute(bin_order_load_details_query)
    self.connection.execute(bin_order_products_query)
    self.connection.execute(bin_order_loads_query)
    self.connection.execute(bin_loads_query)
    self.destroy




      end
    rescue
      raise "The order not be canceled: " + $!

    end
  end


  def set_status(new_status)
    self.status = new_status
    self.update
    return new_status
  end


  def self.qty_bins_available_for_rmt_product(rmt_product_id)

    query = "select count(bins.rmt_product_id) as available_quantity from bins INNER JOIN stock_items ON stock_items.inventory_reference =bins.bin_number
             WHERE ((stock_items.destroyed = FALSE OR stock_items.destroyed is null)  AND bins.bin_order_load_detail_id IS NULL and bins.rmt_product_id = #{rmt_product_id})"

    qty   = Bin.connection.select_one(query)['available_quantity']
    return qty

  end


  def selected_rmt_products(rmt_products, parameter_fields_value, user_name)
    ActiveRecord::Base.transaction do
      bin_order_id = self.id

      for rmt_product in rmt_products
        bin_order_products = BinOrderProduct.find_by_sql("select * from bin_order_products where bin_order_id =#{bin_order_id} AND rmt_product_code='#{rmt_product.rmt_product_code}'")
        if !bin_order_products.empty?
          for bin_order_product in bin_order_products
            if load_detail =BinOrderLoadDetail.find_by_bin_order_product_id(bin_order_product.id)
              load_detail.destroy
            end
            bin_order_product.destroy
          end
        end


        @bin_order_product                    = BinOrderProduct.new
        @bin_order_product.bin_order_id       = self.id
        #@bin_order_product.status = self.status
        @bin_order_product.rmt_product_code   =rmt_product.rmt_product_code
        @bin_order_product.commodity_code     =rmt_product.commodity_code
        @bin_order_product.rmt_variety_code   =rmt_product.rmt_variety_code
        @bin_order_product.product_class_code =rmt_product.product_class_code
        @bin_order_product.size_code          =rmt_product.size_code
        #@bin_order_product.pc_code =rmt_product.pc_code
        @bin_order_product.farm_code          = rmt_product.farm_code
        @bin_order_product.location_code      = rmt_product.location_code

        available_qty                         = BinOrder.qty_bins_available_for_rmt_product(rmt_product['id'])


        @bin_order_product.available_quantity = available_qty
        @bin_order_product.save
        StatusMan.set_status("ORDER_PRODUCT_CREATED", 'bin_order_product', @bin_order_product, user_name)

      end
    end

  end

  def order_load_status?
    bin_order_loads_status = BinOrderLoad.find_by_sql("select status from bin_order_loads where bin_order_loads.bin_order_id = '#{self.id}' ").map { |g| g.status }
    order_products_status  = BinOrderProduct.find_by_sql("select status from bin_order_products where bin_order_id = '#{self.id}'").map { |p| p.status }
    if bin_order_loads_status.include?("LOADING") ||bin_order_loads_status.include?("LOADED")|| bin_order_loads_status.include?("COMPLETE")|| order_products_status.include?("LOADING") ||order_products_status.include?("LOADED")
      return "loading"
    else
      return "bin_order_created"
    end
  end

end







