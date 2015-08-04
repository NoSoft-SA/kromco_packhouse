class BinEnquiry < PDTTransaction
  def build_default_screen


    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_box",:name=>"bin_number",:is_required=>"true",:scan_only=>"false"}

    screen_attributes = {:auto_submit=>"true",:auto_submit_to=>"bin_scanned",:content_header_caption=>"Bin enquiry"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"submit", "B2Submit"=>"bin_scanned","B1Submit"=>"","B1Label"=>"","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = nil
    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

     return result_screen_def
  end

   def bin_enquiry
     build_default_screen
   end

  def bin_scanned
    bin_number = self.pdt_screen_def.get_control_value("bin_number")
    bin = Bin.find_by_bin_number(bin_number)

    pm_rec = PackMaterialProduct.find(bin.pack_material_product_id)
    pm_code = ""
    pm_code = pm_rec.pack_material_product_code if  pm_rec

    if !bin
      return PDTTransaction.build_msg_screen_definition(nil,nil,nil,["Bin: #{bin_number} not found"])
    end

    stock_item = StockItem.find_by_inventory_reference(bin.bin_number)
    destroyed_at_location  = stock_item.inventory_transaction.location_to

    if stock_item.destroyed
      return  PDTTransaction.build_msg_screen_definition(nil, nil, nil, ["bin(#{bin.bin_number}) no longer on stock", " It was shipped or destroyed at location: ",destroyed_at_location ])
    end

    field_configs = Array.new
    rmt_product_code = RmtProduct.find(bin.rmt_product_id).rmt_product_code
    location = StockTake.find_by_sql("select location_code from stock_items where inventory_reference = '#{bin.bin_number}'")[0]['location_code']
     field_configs[field_configs.length] = {:type=>"static_text",:name=>"bin_number:",:value=>bin.bin_number}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"location:",:value=>location}
    field_configs[field_configs.length] = {:type=>"text_line",:name=>"rmt_product_code",:value=>RmtProduct.find("#{bin.rmt_product_id}").rmt_product_code}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"track_slms",:value=>TrackSlmsIndicator.find("#{bin.track_indicator1_id}").track_slms_indicator_code}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"bin_type",:value=> pm_code }
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"tipped_date_time: ",:value=>bin.tipped_date_time}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"received_date:",:value=>bin.bin_receive_date_time}
    if   bin.production_run_rebin_id !=nil
         field_configs[field_configs.length] = {:type=>"static_text",:name=>"rebin_run_code:",:value=>ProductionRun.find("#{bin.production_run_rebin_id}").production_run_code}
    else
         field_configs[field_configs.length] = {:type=>"static_text",:name=>"rebin_run_code:"}
    end
    if bin.pack_material_product_id = nil
      field_configs[field_configs.length] = {:type=>"static_text",:name=>"product_code_bin_type",:value=>PackMaterialProduct.find("#{bin.pack_material_product_id}").pack_material_product_code}
    else
      field_configs[field_configs.length] = {:type=>"static_text",:name=>"product_code_bin_type"}
    end
    if bin.farm_id !=nil
      field_configs[field_configs.length] = {:type=>"static_text",:name=>"farm_code:",:value=>Farm.find(bin.farm_id).farm_code}
    else
        field_configs[field_configs.length] = {:type=>"static_text",:name=>"farm_code:"}
    end



    field_configs[field_configs.length] = {:type=>"static_text",:name=>"bin_weight:",:value=>bin.weight}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"orchard_code: ",:value=>bin.orchard_code}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"exit_reference:",:value=>bin.exit_ref}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"is_sample_bin:",:value=>bin.is_sample_bin}
    field_configs[field_configs.length] = {:type=>"static_text",:name=>"is_half_bin:",:value=>bin.is_half_bin}

    screen_attributes = {:auto_submit=>"false",:content_header_caption=>"bin_enquiry"}
    buttons = {"B3Label"=>"Clear" ,"B2Label"=>"", "B2Submit"=>"", "B1Submit"=>"","B1Label"=>"","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
    plugins = Array.new



    result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
    return result_screen_def
  end

end