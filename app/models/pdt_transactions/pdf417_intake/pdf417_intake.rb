# To change this template, choose Tools | Templates
# and open the template in the editor.

class Pdf417Intake < PDTTransaction


  def scan_pdf417

    build_default_screen
  end


  def build_default_screen
    field_configs = Array.new
   
    field_configs[field_configs.length] = {:type=>'text_box',:name=>'barcode1',:is_required=>'true', :strip=>false}
    field_configs[field_configs.length] = {:type=>'text_box',:name=>'barcode2',:is_required=>'false', :strip=>false}
    field_configs[field_configs.length] = {:type=>'text_box',:name=>'barcode3',:is_required=>'false', :strip=>false}
    field_configs[field_configs.length] = {:type=>'text_box',:name=>'barcode4',:is_required=>'false', :strip=>false}

    buttons = {:B1Label=>"Submit",:B1Enable=>"true",:B1Submit => "scan_pdf417_submit"}
    screen_attributes ={:content_header_caption=>"pdf417 intake",:auto_submit=>"false"}
    plugins=nil
    result_screen = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

  end

  def all_barcodes_scanned?
    errors = []
    if @num_barcodes > 1 && @barcode2.strip().length() == 0
      errors.push("barcorde 2 not scanned")
    end

    if @num_barcodes > 2 && @barcode3.strip().length() == 0
      errors.push("barcorde 3 not scanned")
    end

    if @num_barcodes > 3 && @barcode4.strip().length() == 0
      errors.push("barcorde 4 not scanned")
    end

    if(errors.length > 0)
      return errors
    end

    return nil
  end

  def check_barcodes_scan_order
    errors = []

    if @num_barcodes > 0 && @barcode1.slice(127..127).to_i != 1
      errors.push("barcorde #{@barcode1.slice(127..127).to_i} is scanned at field 1")
    end

    if @num_barcodes > 1 && @barcode2.slice(127..127).to_i != 2
      errors.push("barcorde #{@barcode2.slice(127..127).to_i} is scanned at field 2")
    end

    if @num_barcodes > 2 && @barcode3.slice(127..127).to_i != 3
      errors.push("barcorde #{@barcode3.slice(127..127).to_i} is scanned at field 3")
    end

    if @num_barcodes > 3 && @barcode3.slice(127..127).to_i != 4
      errors.push("barcorde #{@barcode3.slice(127..127).to_i} is scanned at field 2")
    end

    if(errors.length > 0)
      return errors
    end

    return nil
  end

  def validation_errors?
    @barcode1 =  self.pdt_screen_def.get_control_value("barcode1")
    @barcode2 =  self.pdt_screen_def.get_control_value("barcode2")
    @barcode3 =  self.pdt_screen_def.get_control_value("barcode3")
    @barcode4 =  self.pdt_screen_def.get_control_value("barcode4")

     RAILS_DEFAULT_LOGGER.info("barcode1_start"+@barcode1+"barcode1_end")
     RAILS_DEFAULT_LOGGER.info("barcode2_start"+@barcode2+"barcode2_end")
     RAILS_DEFAULT_LOGGER.info("barcode3_start"+@barcode3+"barcode3_end")
     RAILS_DEFAULT_LOGGER.info("barcode4_start"+@barcode4+"barcode4_end")
     
    @raw_text = ""

     if @barcode1.slice(0..1) != "IN"
       return PDTTransaction.build_msg_screen_definition(nil,nil,nil,["Barcode must contain", "the intake header"])
     else
      
       @num_barcodes = @barcode1.slice(128..128).to_i
       if @num_barcodes == 1
         @raw_text = @barcode1
       else

         if(error = all_barcodes_scanned?)
          error.unshift("Please scan all barcodes")
          return PDTTransaction.build_msg_screen_definition(nil,nil,nil,error)
         end

         if(error = check_barcodes_scan_order)
          error.unshift("Please scan barcodes in the correct order")
          return PDTTransaction.build_msg_screen_definition(nil,nil,nil,error)
         end

         @raw_text = @barcode1
         @raw_text += @barcode2.slice(144..@barcode2.length()) if(@barcode2.length > 0)
         @raw_text += @barcode3.slice(144..@barcode3.length()) if(@barcode3.length > 0)
         @raw_text += @barcode4.slice(144..@barcode4.length()) if(@barcode4.length > 0)

         #if @barcode2.strip().length() == 0
         #  return PDTTransaction.build_msg_screen_definition(nil,nil,nil,["You must scan both barcodes"])
         #else
         #  if @barcode1.slice(127..127).to_i == 2
         #    return PDTTransaction.build_msg_screen_definition(nil,nil,nil,["You must scan barcode1 first"])
         #  else
         #    @raw_text = @barcode1 + @barcode2.slice(144..@barcode2.length())
         #  end
         #
         #end
       end
     end
    puts
    puts
    puts
    puts "==============RAW-RAW : #{@raw_text}=================="
    puts
        puts
        puts
     return nil
  end

   def scan_pdf417_submit
    error_screen = validation_errors?
    return error_screen if error_screen

     require "edi/lib/edi/edi_helper"
     EdiHelper.load_edi_in_files_for_web_context
   
     RAILS_DEFAULT_LOGGER.info("pdf417_start"+@raw_text+"pdf417_end")

     transformer = TextIn::TextTransformer.new(@raw_text,"pdf417",self.pdt_screen_def.user,self.pdt_screen_def.ip)


     
     parse_err = transformer.parse
     puts "PARSE ERROR: " + parse_err if parse_err
      return  PDTTransaction.build_msg_screen_definition(nil,nil,nil,["doc in barcode failed schema validation","contact IT"]) if parse_err
     

     
      map_err = transformer.run
      puts "MAP ERROR: " + map_err if map_err
     
     return  PDTTransaction.build_msg_screen_definition(nil,nil,nil,["doc in barcode could not be mapped","contact IT"]) if map_err
    

     return  PDTTransaction.build_msg_screen_definition(nil,nil,nil,["header mapped successfully"])

  end



end
