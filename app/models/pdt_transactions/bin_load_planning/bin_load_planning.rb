class BinLoadPlanning < PDTTransaction
  attr_accessor :bin_order_load_id, :scanned_bins, :active_rmt_product_code, :active_bin_order_product_id, :active_bin_order_load_id, :active_order_product_id
  attr_accessor :quantity_bins_remaining, :active_bin_order_id, :active_bin_order_load_detail_id, :rmt_product_id ,:match_on_size

  def initialize()

  end

  def build_default_screen
    field_configs                       = Array.new
    field_configs[field_configs.length] = {:type=>"text_box", :name=>"tripsheet_number", :is_required=>"true", :required_type=>"number", :scan_field => true, :submit_form => true}

    screen_attributes                   = {:auto_submit=>"true", :auto_submit_to=>"tripsheet_submit", :content_header_caption=>"enter_tripsheet_number"}
    buttons                             = {"B3Label"=>"", "B2Label"=>"", "B1Submit"=>"tripsheet_submit", "B1Label"=>"submit", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
    plugins                             = nil
    result_screen_def                   = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    return result_screen_def
  end

  def enter_tripsheet
    build_default_screen
  end

def check_for_completion(bin_load_id)
     bin_order_loads =BinOrderLoad.find_by_sql("select distinct bin_order_loads.* from bin_order_loads
                    inner join bin_order_load_details on bin_order_load_details.bin_order_load_id=bin_order_loads.id
                    where bin_order_load_details.bin_order_load_id='#{bin_load_id}' ")
     bin_order_loads_ids =Array.new
     if !bin_order_loads.empty?
       for  bin_order_load in bin_order_loads
         bin_order_loads_ids << "id =" + bin_order_load.id.to_s
       end
       bin_order_loads_ids_join =bin_order_loads_ids.join(" OR ")
     bin_order_loads_statuses=BinOrderLoad.find_by_sql("select status from bin_order_loads where #{bin_order_loads_ids_join}").map{|g|g.status}
     bin_order=BinOrder.find(bin_order_loads[0].bin_order_id)

     if   bin_order_loads_statuses.include?("LOAD_DETAIL_CREATED")||  bin_order_loads_statuses.include?("EMPTY")|| bin_order.status=="BIN_ORDER_CREATED" || bin_order.status =="EMPTY"
          return false
     end

    for bin_order_load in bin_order_loads
     is_order_load_complete= order_load_complete?(bin_order_load)
     if  is_order_load_complete == false
       return false
     end
    end
    order_products_status = BinOrderProduct.find_by_sql("select status from bin_order_products where bin_order_id = '#{bin_order.id}'").map{|p|p.status}
    if  order_products_status.include?("LOADING") ||order_products_status.include?("ORDER_PRODUCT_CREATED")||order_products_status.include?("EMPTY")
      return false
    end

    return true
     end
  return false


  end

  def complete_load_msg
    outputs = ["Order products are loaded and",
               "Bin order load details are loaded" ,
               "Do you want to manually complete the load", nil, nil, nil]
    return build_choice_screen(outputs)
  end

   def yes
    complete_confirmed
  end

  def no
    complete_cancelled
  end

def complete_confirmed
      force_completion(@bin_order_load_id)
  end

  def complete_cancelled
    build_default_screen
  end


  def tripsheet_submit
    tripsheet_entered = self.pdt_screen_def.get_control_value("tripsheet_number").strip
    bin_order_load    = BinOrderLoad.find_by_sql("select * from bin_order_loads where id = '#{tripsheet_entered}' order by id desc  ")[0]

    if bin_order_load == nil
      return PDTTransaction.build_msg_screen_definition("Load Order Not Found ", nil, nil, nil)
    end
    @match_on_size = BinOrder.find(bin_order_load.bin_order_id).match_on_size
    bin_status = bin_order_load.status
    if bin_status.upcase == "LOADED"
      return PDTTransaction.build_msg_screen_definition("Order Already Loaded !!", nil, nil, nil)
    elsif check_for_completion(tripsheet_entered)==true
      @bin_order_load_id = bin_order_load.id
      return complete_load_msg
    else
      @scanned_bins      = Array.new
      @bin_order_load_id = bin_order_load.id

      next_state         = BinLoadScanning.new(self)
      self.set_active_state(next_state)
      return next_state.build_default_screen
    end

  end



  def required_product_quantity
    if @active_rmt_product_code == nil
      return nil
    else
      sum_ordered_products = BinOrderProduct.find_by_sql("select bin_order_products.required_quantity as required_quantity  from bin_order_products   join bin_orders on bin_order_products.bin_order_id = bin_orders.id
                          join  bin_order_loads on bin_orders.id = bin_order_loads.bin_order_id   join bin_order_load_details on  bin_order_loads.id = bin_order_load_details.bin_order_load_id
                          where bin_order_loads.id = '#{self.bin_order_load_id.to_i}' and bin_order_products.rmt_product_code = '#{self.active_rmt_product_code}' and bin_order_load_details.id = #{self.active_bin_order_load_detail_id.to_s}")[0]
      @required_quantity   = sum_ordered_products.required_quantity
      return @required_quantity
    end
  end

  def quantity_bins_loaded_for_products
     bin_order_product =BinOrderProduct.find(self.active_bin_order_product_id)
     bin_order_id = BinOrder.find(bin_order_product.bin_order_id).id
    product_count = Bin.find_by_sql(" select count(bins.bin_number) as product_loaded from bins
                    inner join bin_order_load_details on bins.bin_order_load_detail_id = bin_order_load_details.id
                    inner join bin_order_products on bin_order_products.id = bin_order_load_details.bin_order_product_id
                    inner join bin_orders on bin_orders.id=bin_order_products.bin_order_id
                    where bin_order_products.id = #{self.active_bin_order_product_id} and bin_orders.id =#{bin_order_id.to_i}  ")[0]
    @quantity     = product_count.product_loaded
    return @quantity

  end

  def get_order_product_record
    order_product_record     = BinOrderProduct.find_by_sql("select bin_order_products.id from bin_order_products join bin_orders on bin_order_products.bin_order_id = bin_orders.id join bin_order_loads on bin_orders.id = bin_order_loads.bin_order_id
            where bin_order_products.rmt_product_code = '#{self.active_rmt_product_code}' and  bin_order_loads.id = '#{self.bin_order_load_id.to_i}' ")[0]
    @order_product_record_id = order_product_record.id
    return @order_product_record_id


  end

  def set_active_bin_order(selected_rmt_product)
    @active_rmt_product_code = selected_rmt_product
    get_order_product_record()
    @active_bin_order_product_id     = @order_product_record_id

    bin_order_load_details           = BinOrderLoadDetail.find_by_sql("  SELECT
                                                    bin_order_load_details.id
                                                    FROM
                                                    bin_order_load_details
                                                    INNER JOIN bin_order_loads ON (bin_order_loads.id = bin_order_load_details.bin_order_load_id)
                                                    INNER JOIN bin_order_products ON (bin_order_loads.bin_order_id = bin_order_products.bin_order_id)
                                                    AND (bin_order_products.id = bin_order_load_details.bin_order_product_id)

                                                    where bin_order_load_details.bin_order_product_id = '#{self.active_bin_order_product_id}' and bin_order_loads.id = '#{self.bin_order_load_id.to_i}'")[0]

    @active_bin_order_load_detail_id = bin_order_load_details.id

  end

  def order_complete?
    bin_order_loads_status = BinOrderLoad.find_by_sql("select status from bin_order_loads where bin_order_loads.bin_order_id = '#{@active_bin_order_id}' ").map{|g|g.status}
    order_products_status = BinOrderProduct.find_by_sql("select status from bin_order_products where bin_order_id = '#{@active_bin_order_id}'").map{|p|p.status}
    if bin_order_loads_status.include?("LOADING") ||bin_order_loads_status.include?("LOAD_CREATED")|| bin_order_loads_status.include?("EMPTY")|| order_products_status.include?("LOADING") ||order_products_status.include?("ORDER_PRODUCT_CREATED")
      return false
    else
      return true
    end
  end

  def order_load_complete?(bin_order_load)
    bin_order_load_details_status = BinOrderLoadDetail.find_by_sql("select status from bin_order_load_details where bin_order_load_details.bin_order_load_id = '#{bin_order_load.id}'").map{|g|g.status}
    if  bin_order_load_details_status.include?("LOADING") || bin_order_load_details_status.include?("LOAD_DETAIL_CREATED")||  bin_order_load_details_status.include?("EMPTY")
      return false
    else
      return true
    end

  end
  def force_completion(bin_order_load_id)
    bin_order_loads =BinOrderLoad.find_by_sql("select distinct bin_order_loads.* from bin_order_loads
                    inner join bin_order_load_details on bin_order_load_details.bin_order_load_id=bin_order_loads.id
                    where bin_order_load_details.bin_order_load_id='#{bin_order_load_id}' ")
    bin_order=BinOrder.find(bin_order_loads[0].bin_order_id)    
   ActiveRecord::Base.transaction do
    for bin_order_load in bin_order_loads
      StatusMan.set_status("LOADED", "bin_order_load", bin_order_load,self.pdt_screen_def.user)
      StatusMan.set_status("LOADED", "bin_load", bin_order_load.bin_load,self.pdt_screen_def.user)
    end
    StatusMan.set_status("LOADED", "bin_order", bin_order,self.pdt_screen_def.user)

   end
    set_transaction_complete_flag
    result        = [" Bin order load completed successfully "]
    result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, result)
    return result_screen
end


  def complete_load_trans(partial = nil)
    rmt_product     = RmtProduct.find_by_sql("select * from rmt_products where rmt_products.rmt_product_code = '#{self.active_rmt_product_code}' order by rmt_products.id ")[0]
    @rmt_product_id = rmt_product.id
    ActiveRecord::Base.transaction do
     @active_bin_order_id  =  BinOrderLoad.find(self.bin_order_load_id).bin_order_id
    load_details =  BinOrderLoadDetail.find_by_sql("
                    select bin_order_load_details.* from bin_order_load_details
                    inner join bin_order_products on bin_order_products.id = bin_order_load_details.bin_order_product_id
                    inner join bin_orders on bin_orders.id=bin_order_products.bin_order_id
                    where bin_order_products.id =#{@active_bin_order_product_id.to_i} and bin_orders.id = #{ @active_bin_order_id.to_i}")

      if partial == nil
        for load_detail in  load_details
          StatusMan.set_status("LOADED", "bin_order_load_detail", load_detail,self.pdt_screen_def.user)
        end

      else
        for load_detail in  load_details
          StatusMan.set_status("LOADING", "bin_order_load_detail", load_detail,self.pdt_screen_def.user)
        end

      end

      bin_order_loads=BinOrderLoad.find_by_sql("
                      select bin_order_loads.* from bin_order_loads
                      inner join bin_order_load_details on bin_order_load_details.bin_order_load_id=bin_order_loads.id
                      where bin_order_load_details.bin_order_product_id=#{@active_bin_order_product_id.to_i}")

      if partial != nil
        for   bin_order_load in bin_order_loads
        StatusMan.set_status("LOADING", "bin_order_load", bin_order_load,self.pdt_screen_def.user)
        StatusMan.set_status("LOADING", "bin_load", bin_order_load.bin_load,self.pdt_screen_def.user)
        end

      else
         for  bin_order_load in bin_order_loads
           is_order_load_complete= order_load_complete?(bin_order_load)
           if  is_order_load_complete == true
              StatusMan.set_status("LOADED", "bin_order_load", bin_order_load,self.pdt_screen_def.user)
              StatusMan.set_status("LOADED", "bin_load", bin_order_load.bin_load,self.pdt_screen_def.user)
          else
              StatusMan.set_status("LOADING", "bin_order_load", bin_order_load,self.pdt_screen_def.user)
              StatusMan.set_status("LOADING", "bin_load", bin_order_load.bin_load,self.pdt_screen_def.user)
          end
         end


      end

      bin_order_product = BinOrderProduct.find_by_sql("select * from bin_order_products where bin_order_products.id = '#{self.active_bin_order_product_id}' ")[0]
      if partial == nil
        StatusMan.set_status("LOADED", "bin_order_product", bin_order_product,self.pdt_screen_def.user)
      else
        StatusMan.set_status("LOADING", "bin_order_product", bin_order_product,self.pdt_screen_def.user)
      end

      bin_orders = BinOrder.find_by_sql("select * from bin_orders where bin_orders.id = '#{@active_bin_order_id}' order by bin_orders.id desc  ")[0]
      if partial != nil
        StatusMan.set_status("LOADING", "bin_order", bin_orders,self.pdt_screen_def.user)
      else
        is_order_complete =  order_complete?
        if is_order_complete == true
          StatusMan.set_status("LOADED", "bin_order", bin_orders,self.pdt_screen_def.user)
        else
          StatusMan.set_status("LOADING", "bin_order", bin_orders,self.pdt_screen_def.user)
        end
      end

#      bins = self.scanned_bins.map{|num| "'" + num + "'"}  #==>> Add string quotes
      Bin.bulk_update({:bin_order_load_detail_id =>"#{self.active_bin_order_load_detail_id.to_i}"}, 'bin_number', self.scanned_bins)
      Inventory.move_stock('BIN_SALES',@active_bin_order_id.to_s, "IN_TRANSIT", self.scanned_bins)




    end
    self.set_transaction_complete_flag
    result        = [" '#{self.scanned_bins.length()}' Bins added to bin_order_product :'#{self.active_rmt_product_code}' successfully "]
    result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, result)
    return result_screen
  end
end
