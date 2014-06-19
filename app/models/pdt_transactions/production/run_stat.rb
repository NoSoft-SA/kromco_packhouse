class RunStat < PDTTransactionState

 def initialize(parent)
  @parent = parent
 end

 #----------------------------------------------
 # builds the default screen for this state
 #----------------------------------------------
 def build_default_screen
#   #-----------------------------------------------
#   # Client side filtering
#   #-----------------------------------------------
#   field_configs = Array.new
#     field_configs[field_configs.length] = {:type=>"date",:name=>"start_date_time_date2from",:label=>"production",:value=>""}#,:value=>"null"
#     field_configs[field_configs.length] = {:type=>"date",:name=>"end_date_time_date2to",:label=>"end"}#,:value=>""
#     field_configs[field_configs.length] = {:type=>"text_box",:name=>"production_run_code",:label=>"run code",:value=>""}
#     field_configs[field_configs.length] = {:type=>"check_box",:name=>"production_run_status",:label=>"active"}
#
#   cascades1 = Array.new # CAN BE HASH i.e. only one cascade
#   cascades1[cascades1.length] = {:type=>'filter',
#                                  :settings=>{:target_control_name=>'farm_code',:list_field=>'farm_code',:get_list=>'get_production_runs_results',:filter_fields=>'line_code'}}
#   field_configs[field_configs.length] = {:type=>"drop_down",:name=>'line_code',:list_field=>'line_code',:label=>"sh",:get_list=>'get_production_runs_results',
#                                          :cascades=>cascades1}
#
#   cascades2 = Array.new
#   cascades2[cascades2.length] = {:type=>'filter',
#                                  :settings=>{:target_control_name=>'account_code',:list_field=>'account_code',:get_list=>'get_production_runs_results',:filter_fields=>'line_code,farm_code'}}#'drench_line_code,forecast_drench_station_code(drench_station_code)'}}
#   field_configs[field_configs.length] = {:type=>"drop_down",:name=>'farm_code',:label=>"sh",:list=>'Choose a value from line_code, ',:label=>'farm code',
#                                          :cascades=>cascades2}
#
#   field_configs[field_configs.length] = {:type=>"drop_down",:name=>'account_code',:label=>"sh",:list=>'Choose a value from farm code'}
#
#   screen_attributes = {:auto_submit=>"false",:content_header_caption=>"search production runs",:current_menu_item=>"2.2.1.1"}
#   buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Label"=>"Submit","B1Submit"=>"run_stats_submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
#   plugins = Array.new
#   #plugins[plugins.length] = {:class_name=>'LabelPlugin',:plugin_type=>'workspace',:life_cycle=>'screen',:target_pdts =>'' }
#   result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
   #-----------------------------------------------
   # Client side filtering
   #-----------------------------------------------

#   #-----------------------------------------------
#   # Server side filtering
#   #-----------------------------------------------
#   field_configs = Array.new
#     field_configs[field_configs.length] = {:type=>"date",:name=>"start_date_time_date2from",:label=>"start_date_time",:value=>""}
#     field_configs[field_configs.length] = {:type=>"date",:name=>"end_date_time_date2to",:label=>"end_date_time",:value=>""}
#     field_configs[field_configs.length] = {:type=>"text_box",:name=>"production_run_code",:label=>"run code",:value=>""}
#     field_configs[field_configs.length] = {:type=>"check_box",:name=>"production_run_status",:label=>"active"}
#
#   cascades1 = Array.new # CAN BE HASH i.e. only one cascade
#   cascades1[cascades1.length] = {:type=>'filter',
#                                  :settings=>{:target_control_name=>'farm_code',:list_field=>'farm_code',:get_list=>'get_production_runs_farm_code',:filter_fields=>'line_code',:run_at_server=>"true"}}
#   field_configs[field_configs.length] = {:type=>"drop_down",:name=>'line_code',:list_field=>'line_code',:get_list=>'get_production_runs_line_code',:run_at_server=>"true",
#                                          :cascades=>cascades1}
#
#   cascades2 = Array.new
#   cascades2[cascades2.length] = {:type=>'filter',
#                                  :settings=>{:target_control_name=>'account_code',:list_field=>'account_code',:get_list=>'get_production_runs_account_code',:filter_fields=>'line_code,farm_code',:run_at_server=>"true"}}
#   field_configs[field_configs.length] = {:type=>"drop_down",:name=>'farm_code',:list=>'Choose a value from line_code, ',:label=>'farm code',:run_at_server=>"true",
#                                          :cascades=>cascades2}
#
#   field_configs[field_configs.length] = {:type=>"drop_down",:name=>'account_code',:list=>'Choose a value from farm code'}
#
#   screen_attributes = {:auto_submit=>"false",:content_header_caption=>"search production runs",:current_menu_item=>"2.2.1.1"}
#   buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Label"=>"Submit","B1Submit"=>"run_stats_submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
#   plugins = Array.new
#   plugins[plugins.length] = {:class_name=>'LabelPlugin',:plugin_type=>'workspace',:life_cycle=>'screen',:target_pdts =>'' }
#   #plugins[plugins.length] = {:class_name=>'Test3',:plugin_type=>'workspace',:life_cycle=>'screen',:target_pdts =>'' }
#   result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
#   #-----------------------------------------------
#   # Server side filtering
#   #-----------------------------------------------

   #-----------------------------------------------
   # Replace control
   #-----------------------------------------------
   field_configs = Array.new

   cascades1 = Array.new # CAN BE HASH i.e. only one cascade
   cascades1[cascades1.length] = {:type=>'replace_control',
                                  :settings=>{:target_control_name=>'target_control_code',:remote_method=>'replace_field',:filter_fields=>'filter_code'}}
#   field_configs[field_configs.length] = {:type=>"drop_down",:name=>'filter_code',:list_field=>'line_code',:list=>'one,two,three',
#                                          :cascades=>cascades1}
#   field_configs[field_configs.length] = {:type=>"check_box",:name=>'filter_code',
#                                          :cascades=>cascades1}
   field_configs[field_configs.length] = {:type=>"text_box",:name=>'filter_code',
                                          :cascades=>cascades1}

   field_configs[field_configs.length] = {:type=>"static_text",:name=>'target_control_code',:value=>'replace'}
   field_configs[field_configs.length] = {:type=>"text_area",:name=>'arrear',:value=>'Does position work well'}

   screen_attributes = {:auto_submit=>"false",:content_header_caption=>"replace control test"}
   buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Label"=>"Submit","B1Submit"=>"run_stats_submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
   plugins = Array.new
   #plugins[plugins.length] = {:class_name=>'LabelPlugin',:plugin_type=>'workspace',:life_cycle=>'screen',:target_pdts =>'' }
   result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
 end

 def run_stats
   build_default_screen
 end

 def replace_field
#   field_configs = {:type=>"text_box",:name=>'the_replace_ment'}
   field_configs = {:type=>"date",:name=>"target_control_code",:label=>"end_date_time",:value=>""}
#field_configs = {:type=>"check_box",:name=>"production_run_status",:label=>"active"}
#field_configs = {:type=>"static_text",:name=>'target_control_code',:value=>'date type has no bative control - hadle diff'}
#field_configs = {:type=>"text_line",:name=>'line',:value=>'Le Line'}
#field_configs = {:type=>"drop_down",:name=>'le_list',:list=>'each,dou,troi'}
      return PdtScreenDefinition.gen_controls_list_xml(field_configs)#field_configs2
 end

 def run_stats_submit
   params = Hash.new
   for control in self.pdt_screen_def.controls
     if control["name"] != "production_run_status"
       params.store(control["name"],control["value"])
     else
       if control["value"] == "true"
         params.store(control["name"],"active")
       else
         params.store(control["name"],"configuring")
       end
     end
   end

   puts
   puts
   params.keys.each do |key|
     puts key.to_s + " = " + params[key].to_s
   end
   puts
   puts

   production_runs = self.parent.env.dynamic_search(params, "production_runs", "ProductionRun")
   puts "BEBUGGGING = " + production_runs[0].class.name
   if(production_runs.size > 0)
     result_set = production_runs.to_small_list#(["production_run_code","line_code"])
  #   result_set.each do |x|
  #     x.keys.each do |key|
  #       puts key.to_s + " = " + x[key.to_s]
  #     end
  #   end

     next_state = ResultSet.new(self.parent)
     next_state.result_set = result_set
     puts "1. RESULT SET SIZE = " + production_runs.length.to_s
     result_screen_def = next_state.build_default_screen.to_s

     #-----------------------------------------------------------------------
     # sets the current pdt_screen_def,which is used in next step the process
     # to determine the current program_fuction(menu_item) to invoke in the
     # next cycle
     #-----------------------------------------------------------------------
     current_screen_def = PdtScreenDefinition.new(result_screen_def,nil,nil,self.pdt_screen_def.user,self.pdt_screen_def.ip)

     next_state.pdt_screen_def = current_screen_def
     self.parent.set_active_state(next_state)

      return result_screen_def
   else
     result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,["No records were found!!!"])
     return result_screen
   end
 end
end
