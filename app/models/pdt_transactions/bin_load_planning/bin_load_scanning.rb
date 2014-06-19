class BinLoadScanning < PDTTransactionState
  def initialize(parent)
    @parent = parent
  end


  def build_default_screen

    rmt_product_codes  = BinOrderProduct.find_by_sql("select   bin_order_products.rmt_product_code
                                              from bin_order_products
                                              inner join bin_order_load_details on bin_order_load_details.bin_order_product_id= bin_order_products.id
                                              where bin_order_load_details.bin_order_load_id  = '#{self.parent.bin_order_load_id}'").map { |g| g.rmt_product_code }.join(",")


    rmt_product_codes        = ",                                                       ," + rmt_product_codes
          qty_remaining="not_known:rmt product not selected"
          if parent.active_rmt_product_code

         @quantity_bins_remaining = qty_bins_remaining
            qty_remaining = @quantity_bins_remaining
          end
    field_configs            = Array.new
    if   self.parent.active_rmt_product_code == nil
      field_configs[field_configs.length()] = {:type=>"drop_down", :name=>"rmt_product_code", :is_required=>"true", :list => rmt_product_codes, :value=>@parent.active_rmt_product_code.to_s}
    else
      field_configs[field_configs.length()] = {:type=>"static_text", :name=>"rmt_product_code", :value => self.parent.active_rmt_product_code}
    end
    key_in_bin_number = authorise_scan("2.3.1",'key_in_bin_number',ActiveRequest.get_active_request.user)
    if key_in_bin_number
      field_configs[field_configs.length]   = {:type=>"text_box", :name=>"bin_number", :is_required=>"true", :scan_only=>"false"}
    else
      field_configs[field_configs.length]   = {:type=>"text_box", :name=>"bin_number", :is_required=>"true", :scan_only=>"true"}
    end
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"required_product_quantity", :is_required => "false", :value=>self.parent.required_product_quantity()}
    field_configs[field_configs.length()] = {:type=>"static_text", :name=>"product_quantity_remaining", :value =>qty_remaining.to_s}

    screen_attributes                     = {:auto_submit=>"true", :auto_submit_to=>"load_bin_scanned", :content_header_caption=>"scan bins on load"}
    buttons                               = {"B3Label"=>"", "B2Label"=>"", "B1Submit"=>"load_bin_scanned", "B1Label"=>"scan_bin ", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
    plugins                               = nil
    result_screen_def                     = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)
    return result_screen_def
  end

  def qty_bins_remaining
     return  self.parent.required_product_quantity.to_i - (self.parent.scanned_bins.length() + self.parent.quantity_bins_loaded_for_products.to_i)
  end

  def load_bin_scanned
    if (error = validate) != nil
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil, error)
      return result_screen
    end

    @parent.scanned_bins.push(@bin_number)

   @quantity_bins_remaining =qty_bins_remaining
    if @quantity_bins_remaining &&  @quantity_bins_remaining == 0
      return self.parent.complete_load_trans()
    else
      build_default_screen
    end
  end
 
  def validate
    scan_bin_number = self.parent.pdt_screen_def.get_control_value("bin_number").strip
    bin             = Bin.find_by_bin_number(scan_bin_number)


    if bin == nil
      error = ["Bin number :'#{scan_bin_number}' does not exist "]
      return error
    end

    if @parent.scanned_bins.include?(bin.bin_number)
      error = ["Bin number : '#{bin.bin_number}' has already been scanned"]
      return error
    end



    delivery_id =bin.delivery_id
     if delivery_id
      error = Delivery.delivery_mrl_passed?(delivery_id)
      if error== nil
      else
        return  error
      end
     end
    
     rw_active_bin=RwActiveBin.find_by_bin_number(scan_bin_number)
    if rw_active_bin
      error = ["Bin number :'#{scan_bin_number}' is in reworks "]
      return error
    end

    on_a_tripsheet=Bin.is_on_tripsheet?(scan_bin_number)
    if on_a_tripsheet
      error = ["Bin number :'#{scan_bin_number}' is already on tripsheet: #{on_a_tripsheet} "]
      return error
    end


#    #check if bin number has been added to bin_order_product
    if bin.bin_order_load_detail_id != nil
      error = ["Bin number : '#{bin.bin_number}' has already been added to bin_order_product  '#{self.parent.active_rmt_product_code}' "]
      return error
    end
#
    if self.parent.active_rmt_product_code == nil
      selected_rmt_product = self.parent.pdt_screen_def.get_control_value("rmt_product_code").strip
      self.parent.set_active_bin_order(selected_rmt_product)
      if !parent.required_product_quantity || parent.required_product_quantity() == 0
        return ["Bin order product required qty", " has not been set!"]
      end
#
    end

    exit_reference = bin.exit_ref
    @bin_number    = bin.bin_number
    if exit_reference != nil
      error = ["Bin has an exit ref of :'#{exit_reference}'"]
      return error
    end
    stock_item=StockItem.find_by_inventory_reference( @bin_number)
    if !stock_item
       error = ["Bin can not be recieved,its not a stock item "]
      return error
    end
     rmt_product_code_rec = bin.rmt_product.rmt_product_code
     selected_rmt_product_code = self.parent.active_rmt_product_code
    failed_rmt_product = compare_products(bin)
    if !failed_rmt_product.empty?

      error = Array.new
      error[0]="The following bin cannot be received:"
         n = 2
      for element in failed_rmt_product
        error[n - 1]=element
        n =n + 1
      end


    end

  end


  def compare_products(bin)
    load_detail_rmt_product = RmtProduct.find_by_rmt_product_code(bin.rmt_product.rmt_product_code)
    selected_rmt_product    = RmtProduct.find_by_rmt_product_code(self.parent.active_rmt_product_code)
    failed_rmt_product      = Array.new
    failed_rmt_product.push("BIN: product class code='#{load_detail_rmt_product.product_class_code}'" +"   " + "EXPECTED: product class code = '#{selected_rmt_product.product_class_code}')") if  load_detail_rmt_product.product_class_code != selected_rmt_product.product_class_code

    if @parent.match_on_size
      failed_rmt_product.push("BIN: size code='#{load_detail_rmt_product.size_code}'" +"     "+ "EXPECTED: size code = '#{selected_rmt_product.size_code}'") if load_detail_rmt_product.size_code != selected_rmt_product.size_code
    end

    failed_rmt_product.push("BIN: variety code='#{load_detail_rmt_product.variety_code}'" +"     "+ "EXPECTED: variety code = '#{selected_rmt_product.variety_code}'") if  load_detail_rmt_product.variety_code != selected_rmt_product.variety_code

    failed_rmt_product.push("BIN: commodity code='#{load_detail_rmt_product.commodity_code}'" +"     " + "EXPECTED:commodity = '#{selected_rmt_product.commodity_code}'") if  load_detail_rmt_product.commodity_code != selected_rmt_product.commodity_code
    return failed_rmt_product


  end

  def complete_load
    self.parent.clear_active_state
    bin_order_load_id =self.parent.bin_order_load_id
    if !bin_order_load_id
      error = ["Enter Tripsheet number first"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil,error)
      return result_screen
    end
    if self.parent.check_for_completion(bin_order_load_id)==false
      error = ["Order not yet loaded"]
      result_screen = PDTTransaction.build_msg_screen_definition(nil, nil, nil,error)
      return result_screen
    end

    outputs = ["Required Product Quantity :" + self.parent.required_product_quantity.to_s,
               "Product Quantity Remaining : " + @quantity_bins_remaining.to_s,
               "Are you sure you want to complete the Load???", nil, nil, nil]
    return self.parent.build_choice_screen(outputs)
  end

  def yes
    complete_confirmed
  end

  def no
    complete_cancelled
  end

  def complete_confirmed
    completed =check_for_completion(self.parent.bin_load_id)
    if completed==true
      self.parent.force_completion(self.parent.bin_load_id)
    end
    self.parent.complete_load_trans()
  end

  def complete_cancelled
    build_default_screen
  end


end