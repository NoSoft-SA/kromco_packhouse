
class MarkPallet < PDTTransaction
def mark_pallet
  
 build_default_screen
end



 def build_default_screen
   #-----------------------------------------------
   # Client side filtering
   #-----------------------------------------------
   field_configs = Array.new
  #   field_configs[field_configs.length] = {:type=>"date",:name=>"start_date_time_date2from",:label=>"production_schedfretyasre",:value=>""}
  #   field_configs[field_configs.length] = {:type=>"date",:name=>"end_date_time_date2to",:label=>"end",:value=>""}
     field_configs[field_configs.length] = {:type=>"text_box",:name=>"pallet_number",:label=>"scan pallet",:value=>"",:is_required=>true}
 #    field_configs[field_configs.length] = {:type=>"check_box",:name=>"production_run_status",:label=>"active"}

  # cascades1 = Array.new # CAN BE HASH i.e. only one cascade
 #  cascades1[cascades1.length] = {:type=>'filter',
 ##                                 :settings=>{:target_control_name=>'farm_code',:list_field=>'farm_code',:get_list=>'get_production_runs_results',:filter_fields=>'line_code'}}
 #  field_configs[field_configs.length] = {:type=>"drop_down",:name=>'line_code',:list_field=>'line_code',:label=>"sh",:get_list=>'get_production_runs_results',
#                                          :cascades=>cascades1}

#   cascades2 = Array.new
#   cascades2[cascades2.length] = {:type=>'filter',
#                                  :settings=>{:target_control_name=>'account_code',:list_field=>'account_code',:get_list=>'get_production_runs_results',:filter_fields=>'line_code,farm_code'}}#'drench_line_code,forecast_drench_station_code(drench_station_code)'}}
#   field_configs[field_configs.length] = {:type=>"drop_down",:name=>'farm_code',:label=>"sh",:list=>'Choose a value from line_code, ',:label=>'farm code',
 #                                         :cascades=>cascades2}

 #  field_configs[field_configs.length] = {:type=>"drop_down",:name=>'account_code',:label=>"sh",:list=>'Choose a value from farm code'}

   screen_attributes = {:auto_submit=>"false",:content_header_caption=>"mark_pallet"}
   buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Label"=>"Submit","B1Submit"=>"mark_pallet_submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
   plugins = Array.new
   #plugins[plugins.length] = {:class_name=>'LabelPlugin',:plugin_type=>'workspace',:life_cycle=>'screen',:target_pdts =>'' }
   result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)

 end
def mark_pallet_submit()
 

 pallet_number = self.pdt_screen_def.get_input_control_value("pallet_number")

 extracted_pallet_num = PDTFunctions.extract_pallet_num(pallet_number)

    #if extracted_pallet_num.kind_of?(Fixnum) || extracted_pallet_num.kind_of?(Bignum)
    if !extracted_pallet_num.upcase.include?("INVALID")

       pallet_record =  Pallet.find_by_pallet_number(extracted_pallet_num)
       if(pallet_record != nil)


         if pallet_record.load_detail_id


            load =  pallet_record.load_detail.load_order.load
            status = load.load_status
            status =  pallet_record.load_detail.load_order.order.order_status if ! status
            if status.upcase() == "SHIPPED"
              additonal_lines_array = ["PALLET : "+extracted_pallet_num.to_s+" ALREADY SHIPPED " ]
              result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
              self.set_transaction_complete_flag
              return result_screen
            end
             pallet_record.unset_holdover
             additonal_lines_array = ["PALLET :  "+extracted_pallet_num.to_s+" REMOVED FROM LOAD" ]
             result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
             return result_screen
         else
             additonal_lines_array = ["PALLET :  "+extracted_pallet_num.to_s+" NOT ON A LOAD/HOLDOVER" ]
             result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
             return result_screen
         end


       else
         
        additonal_lines_array = ["PALLET :  "+extracted_pallet_num.to_s+" NOT FOUND " +extracted_pallet_num.to_s]
        result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
        return result_screen
       end

    else
      additonal_lines_array = ["INVALID PALLET:  ",extracted_pallet_num ]
      result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,additonal_lines_array)
      return result_screen
    end
  return nil
  end

end

