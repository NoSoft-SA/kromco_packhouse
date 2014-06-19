class SampleTransferPallet < PDTTransactionState

  def initialize(parent)
   @parent = parent
  end
  
  def build_default_screen
   field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"test",:label=>"delivery number",:value=>"*************************"}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"test",:label=>"delivery number",:value=>"The Transitioning to "}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"test",:label=>"delivery number",:value=>"another transaction was done successfully"}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"test",:label=>"delivery number",:value=>"*************************"}

   screen_attributes = {:auto_submit=>"false",:content_header_caption=>"transit to process test"}
   buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Label"=>"Submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
   plugins = nil
   screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end
  
  def sample_transfer_pallet     
       return build_default_screen
  end

  def sample_transfer_pallet_submit

    field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"test",:label=>"delivery number",:value=>"*************************"}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"test",:label=>"delivery number",:value=>"We are now in a "}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"test",:label=>"delivery number",:value=>"completely new transaction"}
      field_configs[field_configs.length] = {:type=>"text_line",:name=>"test",:label=>"delivery number",:value=>"*************************"}

   screen_attributes = {:auto_submit=>"false",:content_header_caption=>"transit to process test"}
   buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Label"=>"Submit","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
   plugins = nil
   result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
  end
end