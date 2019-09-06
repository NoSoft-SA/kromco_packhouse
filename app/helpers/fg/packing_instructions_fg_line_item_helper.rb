module Fg::PackingInstructionsFgLineItemHelper

  def build_list_fg_setup_grid(data_set,can_edit,can_delete,add)

    column_configs = []
    column_configs << {:field_type => 'text', :field_name => 'fg_product_code',:col_width=>250}
    column_configs << {:field_type => 'text', :field_name => 'fg_mark_code',:col_width=>120}
    column_configs << {:field_type => 'text', :field_name => 'retailer_org',:col_width=>100}
    column_configs << {:field_type => 'text', :field_name => 'extended_fg_code',:col_width=>200}
    column_configs << {:field_type => 'text', :field_name => 'retailer_sell_by_code',:col_width=>150}
    column_configs << {:field_type => 'text', :field_name => 'fg_code_old',:col_width=>150}
    column_configs << {:field_type => 'text', :field_name => 'marketing_org',:col_width=>100}
    column_configs << {:field_type => 'text', :field_name => 'target_market',:col_width=>200}
    column_configs << {:field_type => 'text', :field_name => 'inventory_code',:col_width=>150}
    column_configs << {:field_type => 'text', :field_name => 'marking',:col_width=>100}
    column_configs << {:field_type => 'text', :field_name => 'ri_weight_range',:col_width=>150}
    column_configs << {:field_type => 'text', :field_name => 'ri_diameter_range',:col_width=>150}
    column_configs << {:field_type => 'text', :field_name => 'gtin',:col_width=>100}
    column_configs << {:field_type => 'text', :field_name => 'remarks',:col_width=>100}
    column_configs << {:field_type => 'text', :field_name => 'id'}
    @multi_select = "submit_selected_fg_setups"
    get_data_grid(data_set,column_configs,nil,true)
  end

  def build_fg_setup_grid(data_set,can_edit,can_delete,add)

    column_configs = []
    grid_command =    {:field_type=>'link_window_field',:field_name =>'fg_setups',
                       :settings =>
                           {
                               :host_and_port =>request.host_with_port.to_s,
                               :controller =>request.path_parameters['controller'].to_s,
                               :target_action =>'select_fg_setups',
                               :link_text => 'add fg setups',
                               :id_value=>'id'
                           }}

    column_configs << {:field_type => 'text', :field_name => 'fg_product_code',:col_width=>250}
    column_configs << {:field_type => 'text', :field_name => 'fg_mark_code',:col_width=>120}
    column_configs << {:field_type => 'text', :field_name => 'retailer_org',:col_width=>100}
    column_configs << {:field_type => 'text', :field_name => 'extended_fg_code',:col_width=>200}
    column_configs << {:field_type => 'text', :field_name => 'retailer_sell_by_code',:col_width=>150}
    column_configs << {:field_type => 'text', :field_name => 'fg_code_old',:col_width=>150}
    column_configs << {:field_type => 'text', :field_name => 'marketing_org',:col_width=>100}
    column_configs << {:field_type => 'text', :field_name => 'target_market',:col_width=>200}
    column_configs << {:field_type => 'text', :field_name => 'inventory_code',:col_width=>150}
    column_configs << {:field_type => 'text', :field_name => 'marking',:col_width=>100}
    column_configs << {:field_type => 'text', :field_name => 'ri_weight_range',:col_width=>150}
    column_configs << {:field_type => 'text', :field_name => 'ri_diameter_range',:col_width=>150}
    column_configs << {:field_type => 'text', :field_name => 'gtin',:col_width=>100}
    column_configs << {:field_type => 'text', :field_name => 'remarks',:col_width=>100}
    column_configs << {:field_type => 'text', :field_name => 'id'}
    @multi_select = "remove_selected_fg_setups"
    get_data_grid(data_set,column_configs,nil,true,grid_command)
  end


  def build_packing_instructions_fg_line_item_form(packing_instructions_fg_line_item,action,caption,is_edit = nil,is_create_retry = nil)
#  --------------------------------------------------------------------------------------------------
#  Define a set of observers for each composite foreign key- in effect an observer per combo involved
#  in a composite foreign key
#  --------------------------------------------------------------------------------------------------
  session[:packing_instructions_fg_line_item_form]= Hash.new
  grade_codes = Grade.find_by_sql('select distinct grades.id,grades.grade_code from grades
                                  join extended_fgs on extended_fgs.grade_code=grades.grade_code ').map{|g|[g.grade_code,g.id.to_i]}
  fg_codes = ActiveRecord::Base.connection.select_all("select distinct extended_fgs.id as old_fg_id,extended_fgs.old_fg_code
             from extended_fgs where old_fg_code is not null limit 100").map{|g|[g['old_fg_code'],g['old_fg_id'].to_i]}

  marketing_orgs = ActiveRecord::Base.connection.select_all("select distinct id ,short_description
                    from organizations ").map{|g|[g['short_description'],g['id'].to_i]}

  target_market_codes = TargetMarket.find_by_sql('select distinct id,target_market_name,target_market_description from target_markets').map{
                        |g|
                          [g.target_market_name + ":" + " " + " " + g.target_market_description ,g.id.to_i]
                         }
  inventory_codes = ActiveRecord::Base.connection.select_all("select distinct id as inv_code_id,inventory_code,inventory_name
                    from inventory_codes").map{
                        |g|
                           [g['inventory_code'] + ":" + " " + " " + g['inventory_name'],g['inv_code_id'].to_i]
                         }

  field_configs = []
#  ---------------------------------
#   Define fields to build form from
#  ---------------------------------
  field_configs << {:field_type => 'TextField',
                    :field_name => 'pallet_qty'}

  field_configs << {:field_type => 'TextField',
                    :field_name => 'retailer_sell_by_code'}

  field_configs << {:field_type => 'DropDownField',
            :field_name => 'old_fg_id',:settings => {:label_caption=> 'old fg',:list => fg_codes}}

  field_configs << {:field_type => 'DropDownField',
                    :field_name => 'grade_id',
                    :settings => {:list => grade_codes}}

  field_configs << {:field_type => 'DropDownField',
                    :field_name => 'inventory_id',:settings => {:list => inventory_codes}}

  field_configs << {:field_type => 'DropDownField',
                    :field_name => 'target_market_id',
                    :settings => {:list => target_market_codes}}

  field_configs << {:field_type => 'DropDownField',
            :field_name => 'marketing_org_id',:settings => {:list => marketing_orgs}}

  construct_form(packing_instructions_fg_line_item,field_configs,action,'packing_instructions_fg_line_item',caption,is_edit)

end


 def build_packing_instructions_fg_line_item_search_form(packing_instructions_fg_line_item,action,caption,is_flat_search = nil)
#  --------------------------------------------------------------------------------------------------
#  Define an observer for each index field
#  --------------------------------------------------------------------------------------------------
  session[:packing_instructions_fg_line_item_search_form]= Hash.new
  #generate javascript for the on_complete ajax event for each combo
  #Observers for search combos
#  ----------------------------------------
#   Define search fields to build form from
#  ----------------------------------------
field_configs = []
  pallet_qties = PackingInstructionsFgLineItem.find_by_sql('select distinct pallet_qty from packing_instructions_fg_line_items').map{|g|[g.pallet_qty]}
  field_configs << {:field_type => 'DropDownField',
            :field_name => 'pallet_qty',
            :settings => {:list => pallet_qties}}

  construct_form(packing_instructions_fg_line_item,field_configs,action,'packing_instructions_fg_line_item',caption,false)

end



 def build_packing_instructions_fg_line_item_grid(data_set,can_edit,can_delete)

  column_configs = []
  action_configs = []
#  ----------------------
#  define action columns
#  ----------------------
   grid_command =    {:field_type=>'link_window_field',:field_name =>'packing_instructions_fg_line_item',
                      :settings =>
                          {
                              :host_and_port =>request.host_with_port.to_s,
                              :controller =>request.path_parameters['controller'].to_s,
                              :target_action =>'new_packing_instructions_fg_line_item',
                              :link_text => 'new_packing_instructions_fg_line_item',
                              :id_value=>'id'
                          }}
  if can_edit
    action_configs << {:field_type => 'link_window',:field_name => 'edit packing_instructions_fg_line_item',
      :column_caption => 'Edit',
      :settings =>
         {:link_text => 'edit',
        :link_icon => 'edit',
        :target_action => 'edit_packing_instructions_fg_line_item',
        :id_column => 'id'}}
  end

  if can_delete
    action_configs << {:field_type => 'action',:field_name => 'delete packing_instructions_fg_line_item',
      :column_caption => 'Delete',
      :settings =>
         {:link_text => 'delete',
        :link_icon => 'delete',
        :target_action => 'delete_packing_instructions_fg_line_item',
        :id_column => 'id'}}
  end
   column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?

   column_configs << {:field_type => 'link_window',:field_name => 'fg_setup_for_packing_instructions_lines',
                      :column_caption => 'fg_setups',
                      :settings =>
                          {:link_text => 'fg_setups',
                           :link_icon => 'fg_setups',
                           :target_action => 'list_fg_setup_for_packing_instructions_lines',
                           :id_column => 'id'}}


  #action_configs << {:field_type => 'separator'} if can_edit || can_delete

   column_configs << {:field_type => 'text', :field_name => 'pallet_qty',:col_width=>80, :data_type => 'integer', :column_caption => 'pallet_qty'}
   column_configs << {:field_type => 'text', :field_name => 'retailer_sell_by_code',:col_width=>150}
   column_configs << {:field_type => 'text', :field_name => 'old_fg_code',:col_width=>150}
   column_configs << {:field_type => 'text', :field_name => 'grade_code', :column_caption => 'grade',:col_width=>70}
   column_configs << {:field_type => 'text', :field_name => 'inventory_code',:col_width=>150}
   column_configs << {:field_type => 'text', :field_name => 'target_market_code', :column_caption => 'target_market',:col_width=>200}
   column_configs << {:field_type => 'text', :field_name => 'marketing_org_code', :column_caption => 'marketing_org',:col_width=>100}

  get_data_grid(data_set,column_configs,nil,true,grid_command)
end




end
