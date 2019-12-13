module Fg::PackingInstructionsFgLineItemHelper

  def build_import_fgs_form(fg_line_item, action, caption, is_edit=nil, is_create_retry=nil)
    field_configs = Array.new
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                             :field_name => '',
                                             :settings => {
                                                 :is_seperator => false,
                                                 :static_value => "
                                                 PASTE Extended_fg_code	 Inventory_code 	Target_market_code  	Retailer_sell_by_code
  in this order.<BR>
                                                 Extended_fg_code Is Required.<BR>                                                                                             "
                                             }
    }
    # field_configs[field_configs.length()] = {:field_type => 'LabelField',
    #                                          :field_name => '',
    #                                          :settings => {
    #                                              :is_seperator => false,
    #                                              :static_value => "
    #  EXAMPLE <BR>
    #  AC_HCT_CI_1A_90_M2_UL_L_*T5.4**_CM2D104_GM_NONE_NONE_GEN_KRF	,S,CH	,ZVO (extended_fg_code,inventory_code ,target_market,retailer_sell_by_code)<BR>
    #  AC_HCT_CI_1A_90_M2_UL_L_*T5.4**_CM2D104_GM_NONE_NONE_GEN_KRF,S	         (extended_fg_code,inventory_code )<BR>
    #  AC_HCT_CI_1A_90_M2_UL_L_*T5.4**_CM2D104_GM_NONE_NONE_GEN_KRF	,	         ,CH (extended_fg_code ,  , target_market)<BR>
    #  AC_HCT_CI_1A_90_M2_UL_L_*T5.4**_CM2D104_GM_NONE_NONE_GEN_KRF	,       ,       ,ZVO   (extended_fg_code ,  , , retailer_sell_by_code)<BR>
    #  AC_HCT_CI_1A_90_M2_UL_L_*T5.4**_CM2D104_GM_NONE_NONE_GEN_KRF	           (extended_fg_code)<BR>"}
    # }
    field_configs[field_configs.length()] = {:field_type=>'TextArea', :field_name=>'fgs',
                                             :settings =>{
                                                 :cols=> 100,
                                                 :rows=> 20}}

    build_form(fg_line_item, field_configs, action, 'fg_line_item', caption, is_edit)
  end

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

  def get_observers(frm)
    combos_js_for_commodity = gen_combos_clear_js_for_combos(["#{frm}_commodity_code", "#{frm}_marketing_variety_code"])
    commodity_observer = {:updated_field_id => "marketing_variety_code_cell",
                          :remote_method => 'store_commodity',
                          :on_completed_js => combos_js_for_commodity["#{frm}_commodity_code"]}

    combos_js_for_marketing_variety_code = gen_combos_clear_js_for_combos(["#{frm}_marketing_variety_code", "#{frm}_brand_code"])
    marketing_variety_code_observer = {:updated_field_id => "brand_code_cell",
                          :remote_method => 'store_marketing_variety_code',
                          :on_completed_js => combos_js_for_marketing_variety_code["#{frm}_marketing_variety_code"]}

    combos_js_for_brand_code = gen_combos_clear_js_for_combos(["#{frm}_brand_code", "#{frm}_old_pack_code"])
    brand_code_observer = {:updated_field_id => "old_pack_code_cell",
                          :remote_method => 'store_brand_code',
                          :on_completed_js => combos_js_for_brand_code["#{frm}_brand_code"]}

    combos_js_for_old_pack_code = gen_combos_clear_js_for_combos(["#{frm}_old_pack_code", "#{frm}_old_fg_actual_count"])
    old_pack_code_observer = {:updated_field_id => "actual_count_cell",
                          :remote_method => 'store_old_pack_code',
                          :on_completed_js => combos_js_for_old_pack_code["#{frm}_old_pack_code"]}

    combos_js_for_actual_count = gen_combos_clear_js_for_combos(["#{frm}_actual_count", "#{frm}_old_fg_id"])
    actual_count_observer = {:updated_field_id => "old_fg_id_cell",
                          :remote_method => 'refresh_old_fg_id',
                          :on_completed_js => combos_js_for_actual_count["#{frm}_actual_count"]}

    return commodity_observer,marketing_variety_code_observer,brand_code_observer,old_pack_code_observer,actual_count_observer

  end


  def build_packing_instructions_fg_line_item_form(packing_instructions_fg_line_item,action,caption,is_edit = nil,is_create_retry = nil)
#  --------------------------------------------------------------------------------------------------
#  Define a set of observers for each composite foreign key- in effect an observer per combo involved
#  in a composite foreign key
#  --------------------------------------------------------------------------------------------------
  session[:packing_instructions_fg_line_item_form]= Hash.new

  commodity_observer,marketing_variety_code_observer,brand_code_observer,old_pack_code_observer,actual_count_observer=get_observers("packing_instructions_fg_line_item")
  mv_extended_fgs = ActiveRecord::Base.connection.select_all("select DISTINCT old_fg_code,id,marketing_variety_code,brand_code,old_pack_code,actual_count
                     FROM mv_extended_fgs ")

  session[:mv_extended_fgs] = mv_extended_fgs

  commodity_codes         = ['AP','PR']
  marketing_variety_codes = mv_extended_fgs.map{|x|x['marketing_variety_code']}.delete_if { |e| e ==nil || e=='' }.uniq
  brand_codes             = mv_extended_fgs.map{|x|x['brand_code']}.delete_if { |e| e ==nil || e=='' }.uniq
  old_pack_codes          = mv_extended_fgs.map{|x|x['old_pack_code']}.delete_if { |e| e ==nil || e=='' }.uniq
  actual_counts           = mv_extended_fgs.map{|x|x['actual_count']}.delete_if { |e| e ==nil || e=='' }.uniq
  fg_codes                = mv_extended_fgs.map{|g|[g['old_fg_code'],g['id'].to_i]}.uniq

  grade_codes = Grade.find_by_sql('select distinct grades.id,grades.grade_code from grades
                                  join extended_fgs on extended_fgs.grade_code=grades.grade_code ').map{|g|[g.grade_code,g.id.to_i]}

  marketing_orgs = ActiveRecord::Base.connection.select_all("select distinct id ,short_description
                    from organizations ").map{|g|[g['short_description'],g['id'].to_i]}

  target_market_codes = TargetMarket.find_by_sql('select distinct id,target_market_name,target_market_description from target_markets').map{
                        |g|
                          [g.target_market_name + ":" + " " + " " + g.target_market_description ,g.id.to_i]
                         }
  inventory_codes = ActiveRecord::Base.connection.select_all("select distinct id as inv_code_id,inventory_code,inventory_name
                    from inventory_codes where inventory_code is not null and inventory_name is not null").map{
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

    field_configs << {:field_type => 'DropDownField', :field_name =>'commodity_code',
                      :settings => {:label_caption=> 'commodity',:list => commodity_codes},:observer=>commodity_observer}

    field_configs << {:field_type => 'DropDownField', :field_name => 'marketing_variety_code',
                      :settings => {:label_caption=> 'marketing_variety_code',:list => marketing_variety_codes},:observer=>marketing_variety_code_observer}

    field_configs << {:field_type => 'DropDownField', :field_name => 'brand_code',
                      :settings => {:label_caption=> 'brand_code',:list => brand_codes},:observer=>brand_code_observer}

    field_configs << {:field_type => 'DropDownField', :field_name => 'old_pack_code',
                      :settings => {:label_caption=> 'old_pack_code',:list => old_pack_codes},:observer=>old_pack_code_observer}

    field_configs << {:field_type => 'DropDownField', :field_name => 'actual_count',
                      :settings => {:label_caption=> 'actual_count',:list => actual_counts},:observer=>actual_count_observer}

  field_configs << {:field_type => 'DropDownField', :field_name => 'old_fg_id',
                    :settings => {:label_caption=> 'old fg',:list => fg_codes}}

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



 def build_packing_instructions_fg_line_item_grid(data_set,can_edit,can_delete,multi_select=nil)

  column_configs = []
  action_configs = []
#  ----------------------
#  define action columns
#  ----------------------
   grid_command = nil
   if multi_select != "submit_selected_fg_line_items"
   grid_command =    {:field_type=>'link_window_field',:field_name =>'packing_instructions_fg_line_item',
                      :settings =>
                          {
                              :host_and_port =>request.host_with_port.to_s,
                              :controller =>request.path_parameters['controller'].to_s,
                              :target_action =>'new_packing_instructions_fg_line_item',
                              :link_text => 'new_packing_instructions_fg_line_item',
                              :id_value=>'id'
                          }}

      action_configs << {:field_type => 'link_window',:field_name => 'edit packing_instructions_fg_line_item',
        :column_caption => 'Edit',
        :settings =>
           {:link_text => 'edit',
          :link_icon => 'edit',
          :target_action => 'edit_packing_instructions_fg_line_item',
          :id_column => 'id'}} if can_edit


   action_configs << {:field_type => 'action',:field_name => 'delete packing_instructions_fg_line_item',
      :column_caption => 'Delete',
      :settings =>
         {:link_text => 'delete',
        :link_icon => 'delete',
        :target_action => 'delete_packing_instructions_fg_line_item',
        :id_column => 'id'}} if can_delete

   column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?

   column_configs << {:field_type => 'link_window',:field_name => 'fg_setup_for_packing_instructions_lines',
                      :column_caption => 'fg_setups',
                      :settings =>
                          {:link_text => 'fg_setups',
                           :link_icon => 'fg_setups',
                           :target_action => 'list_fg_setup_for_packing_instructions_lines',
                           :id_column => 'id'}}
   else
     column_configs << {:field_type => 'action',:field_name => 'unlink',
                        :column_caption => 'Unlink',
                        :settings =>
                            {:link_text => 'unlink',
                             :link_icon => 'delete',
                             :target_action => 'unlink_packing_instructions_fg_line_item',
                             :id_column => 'id',
                             :null_test => "['packing_instruction_bin_line_item_id'] == nil "}}

    end

   column_configs << {:field_type => 'text', :field_name => 'pallet_qty',:col_width=>80, :data_type => 'integer', :column_caption => 'pallet_qty'}
   column_configs << {:field_type => 'text', :field_name => 'retailer_sell_by_code',:col_width=>150}
   column_configs << {:field_type => 'text', :field_name => 'old_fg_code',:col_width=>150}
   column_configs << {:field_type => 'text', :field_name => 'grade_code', :column_caption => 'grade',:col_width=>70}
   column_configs << {:field_type => 'text', :field_name => 'inventory_code',:col_width=>150}
   column_configs << {:field_type => 'text', :field_name => 'target_market_code', :column_caption => 'target_market',:col_width=>200}
   column_configs << {:field_type => 'text', :field_name => 'marketing_org_code', :column_caption => 'marketing_org',:col_width=>100}
   column_configs << {:field_type => 'text', :field_name => 'commodity_code',:col_width=>150}
   column_configs << {:field_type => 'text', :field_name => 'marketing_variety_code',:col_width=>150}
   column_configs << {:field_type => 'text', :field_name => 'brand_code',:col_width=>150}
   column_configs << {:field_type => 'text', :field_name => 'old_pack_code',:col_width=>150}
   column_configs << {:field_type => 'text', :field_name => 'actual_count',:col_width=>150}
   column_configs << {:field_type => 'text', :field_name => 'packing_instruction_bin_line_item_id',:hide=>true,:col_width=>150}
   column_configs << {:field_type => 'text', :field_name => 'id',:hide=> true}

   @multi_select = multi_select

  get_data_grid(data_set,column_configs,nil,true,grid_command)
end




end
