class ResultSet < PDTTransactionState
attr_accessor :current_index, :result_set

 def initialize(parent)
  @parent = parent
  @current_index = 0
 end

 #----------------------------------------------
 # builds the default screen for this state
 #----------------------------------------------
 def build_default_screen
   production_runs = Array.new
   for id in @result_set
     production_run = ProductionRun.find(id.to_s)
     production_runs.push(production_run)
   end
   field_configs = Array.new
   if production_runs.length > 0
     field_configs[field_configs.length] = {:type=>"static_text",:name=>"run_code",:value=>production_runs[@current_index].production_run_code}
     field_configs[field_configs.length] = {:type=>"static_text",:name=>"bins_tipped_weight",:value=>production_runs[@current_index].bins_tipped_weight}
     field_configs[field_configs.length] = {:type=>"static_text",:name=>"cartons_printed",:value=>production_runs[@current_index].cartons_printed}
     field_configs[field_configs.length] = {:type=>"static_text",:name=>"pallets_completed",:value=>production_runs[@current_index].pallets_completed}
     if(@current_index == 0)
        buttons = {"B3Label"=>"Clear" ,"B2Label"=>"next","B2Submit"=>"next_item","B1Label"=>"back","B1Submit"=>"back","B1Enable"=>"false","B2Enable"=>"true","B3Enable"=>"false" }
     elsif (@current_index == production_runs.length - 1)
        buttons = {"B3Label"=>"Clear" ,"B2Label"=>"next","B2Submit"=>"next_item","B1Label"=>"back","B1Submit"=>"back","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
     else
       buttons = {"B3Label"=>"Clear" ,"B2Label"=>"next","B2Submit"=>"next_item","B1Label"=>"back","B1Submit"=>"back","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }
     end
   end
   screen_attributes = {:auto_submit=>"false",:content_header_caption=>"navigate production runs"}
   plugins = nil
   result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
 end

 def back
   @current_index -= 1
   if(@current_index < 0)
     @current_index = 0
   end
   build_default_screen
 end

  def next_item
    @current_index += 1
    if(@current_index > @result_set.length - 1)
      @current_index = @result_set.length - 1
    end
    build_default_screen
  end
  
end