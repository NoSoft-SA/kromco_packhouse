module Fg::PackingInstructionsBinLineItemHelper


 def build_packing_instructions_bin_line_item_form(packing_instructions_bin_line_item,action,caption,is_edit = nil,is_create_retry = nil)
    rmt_products = PackingInstructionsBinLineItem.get_rmt_products

    commodity_codes = rmt_products.map{|x|[x['commodity_code'],x['commodity_id'].to_i]}.uniq
    treatment_codes = rmt_products.map{|x|[x['treatment_code'],x['treatment_id'].to_i]}.uniq
    product_class_codes = rmt_products.map{|x|[x['product_class_code'],x['product_class_id'].to_i]}.uniq
    size_codes = rmt_products.map{|x|[x['size_code'],x['size_id'].to_i]}.uniq
    varieties = rmt_products.map{|x|[x['variety_code'],x['variety_id'].to_i]}.uniq
    track_slms_indicator_codes = ["select commodity first"] if !packing_instructions_bin_line_item
    track_slms_indicator_codes = PackingInstructionsBinLineItem.get_track_slms_indicators if packing_instructions_bin_line_item

    field_configs = []
#  ----------------------------------------------------------------------------------------------
#  Combo fields to represent foreign key (track_slms_indicator_id) on related table: track_slms_indicators
#  ----------------------------------------------------------------------------------------------
  field_configs << {:field_type => 'TextField',
            :field_name => 'bin_qty'}

    combos_js_for_commodity = gen_combos_clear_js_for_combos(["packing_instructions_bin_line_item_commodity_id", "packing_instructions_bin_line_item_track_slms_indicator_id"])
    commodity_observer = {:updated_field_id => "track_slms_indicator_id_cell",
                          :remote_method => 'refresh_track_slms_indicator',
                          :on_completed_js => combos_js_for_commodity["packing_instructions_bin_line_item_commodity_id"]}

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'commodity_id',
                                             :settings => {
                                                 :list => commodity_codes,
                                                 :label_caption => 'commodity',
                                                 :show_label => true},
                                             :observer => commodity_observer}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'track_slms_indicator_id',
                      :settings => {:list => track_slms_indicator_codes}}

  field_configs << {:field_type => 'DropDownField',
            :field_name => 'variety_id',
            :settings => {:list => varieties}}

  field_configs << {:field_type => 'DropDownField',
            :field_name => 'size_id',
            :settings => {:list => size_codes}}

  field_configs << {:field_type => 'DropDownField',
            :field_name => 'product_class_id',
            :settings => {:list => product_class_codes}}

  field_configs << {:field_type => 'DropDownField',
            :field_name => 'treatment_id',
            :settings => {:list => treatment_codes}}

  construct_form(packing_instructions_bin_line_item,field_configs,action,'packing_instructions_bin_line_item',caption,is_edit)

end



 def build_packing_instructions_bin_line_item_grid(data_set,can_edit,can_delete)

  column_configs = []
  action_configs = []
#  ----------------------
#  define action columns
#  ----------------------
  if can_edit
    action_configs << {:field_type => 'link_window',:field_name => 'edit packing_instructions_bin_line_item',
      :column_caption => 'Edit',
      :settings =>
         {:link_text => 'edit',
        :link_icon => 'edit',
        :target_action => 'edit_packing_instructions_bin_line_item',
        :id_column => 'id'}}
  end

  if can_delete
    action_configs << {:field_type => 'action',:field_name => 'delete packing_instructions_bin_line_item',
      :column_caption => 'Delete',
      :settings =>
         {:link_text => 'delete',
        :link_icon => 'delete',
        :target_action => 'delete_packing_instructions_bin_line_item',
        :id_column => 'id'}}
  end
   grid_command =    {:field_type=>'link_window_field',:field_name =>'packing_instructions_bin_line_item',
                      :settings =>
                          {
                              :host_and_port =>request.host_with_port.to_s,
                              :controller =>request.path_parameters['controller'].to_s,
                              :target_action =>'new_packing_instructions_bin_line_item',
                              :link_text => 'new_packing_instructions_bin_line_item',
                              :id_value=>'id'
                          }}
  action_configs << {:field_type => 'separator'} if can_edit || can_delete
  column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?
  column_configs << {:field_type => 'text', :field_name => 'bin_qty', :data_type => 'integer', :column_caption => 'Bin qty',:col_width=>100}
   column_configs << {:field_type => 'text', :field_name => 'commodity_code' ,:col_width=>100,:column_caption=>'commodity'}
   column_configs << {:field_type => 'text', :field_name => 'track_slms_indicator_code' ,:col_width=>140,:column_caption=>'track_slms_indicator'}
  column_configs << {:field_type => 'text', :field_name => 'variety_code' ,:col_width=>100,:column_caption=>'variety'}
  column_configs << {:field_type => 'text', :field_name => 'size_code' ,:col_width=>100,:column_caption=>'size'}
  column_configs << {:field_type => 'text', :field_name => 'product_class_code' ,:col_width=>130,:column_caption=>'product_class'}
  column_configs << {:field_type => 'text', :field_name => 'treatment_code' ,:col_width=>100,:column_caption=>'treatment'}
   column_configs << {:field_type => 'text', :field_name => 'id' }

   get_data_grid(data_set,column_configs,nil,true,grid_command)
end



end
