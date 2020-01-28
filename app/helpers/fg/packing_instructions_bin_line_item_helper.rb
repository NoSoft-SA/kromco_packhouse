module Fg::PackingInstructionsBinLineItemHelper

  def build_bins_grid(data_set,add=nil)
    column_configs                          = Array.new
    get_bin_columns(column_configs)
    @multi_select = "submit_selected_bins"
    get_data_grid(data_set,column_configs,nil,true)
  end

  def build_line_item_bins_grid(data_set,add=nil)

    column_configs                          = Array.new
    grid_command =    {:field_type=>'link_window_field',:field_name =>'bins',
                       :settings =>
                           {
                               :host_and_port =>request.host_with_port.to_s,
                               :controller =>request.path_parameters['controller'].to_s,
                               :target_action =>'select_bins',
                               :link_text => 'add bins',
                               :id_value=>'id'
                           }}
    get_bin_columns(column_configs)
    set_grid_min_width(1200)
    @multi_select = "remove_selected_bins"
    get_data_grid(data_set,column_configs,nil,true,grid_command)
  end

  def build_packing_instructions_bin_line_item_form(packing_instructions_bin_line_item, action, caption, is_edit = nil, is_create_retry = nil)
    rmt_products = PackingInstructionsBinLineItem.get_rmt_products

    # commodity_codes = ActiveRecord::Base.connection.select_all("
    #                    select distinct commodities.id,commodities.commodity_code
    #                    from commodities
    #                    join rmt_products on rmt_products.commodity_code = commodities.commodity_code
    #                    where commodities.commodity_code in ('AP','PR')").map { |x| [x['commodity_code'], x['id'].to_i] }
    # treatment_codes = ActiveRecord::Base.connection.select_all("select  distinct treatments.id, treatments.treatment_code
    #                   from treatments
    #                   join rmt_products on rmt_products.treatment_id = treatments.id").map { |x| [x['treatment_code'], x['treatment_id'].to_i] }.uniq if !packing_instructions_bin_line_item
    # product_class_codes = ActiveRecord::Base.connection.select_all("select  distinct product_classes.id, product_classes.product_class_code
    #                       from product_classes
    #                       join rmt_products on rmt_products.product_class_id = product_classes.id").map { |x| [x['product_class_code'], x['id'].to_i] }.uniq
    # size_codes = ActiveRecord::Base.connection.select_all("select  distinct sizes.id, sizes.size_code
    #                  from sizes
    #                   join rmt_products on rmt_products.size_id = sizes.id").map { |x| [x['size_code'], x['id'].to_i] }.uniq
    track_slms_indicator_codes = ["select commodity first"] if !packing_instructions_bin_line_item
    track_slms_indicator_codes = PackingInstructionsBinLineItem.get_track_slms_indicators if packing_instructions_bin_line_item

   commodity_codes, product_class_codes, size_codes, treatment_codes, varieties = get_rmt_product_lists(rmt_products)
    varieties = ActiveRecord::Base.connection.select_all("select distinct r.variety_id,r.variety_code
                from rmt_products r
                join commodities c on r.commodity_code = c.commodity_code
                where c.id=#{packing_instructions_bin_line_item['commodity_id']}
                  ").map { |x| [x['variety_code'], x['variety_id'].to_i].uniq } if packing_instructions_bin_line_item && packing_instructions_bin_line_item['commodity_id']

    treatment_codes =Treatment.find_by_sql("select distinct treatment_id,treatment_code
                                   from rmt_products
                                   where variety_id=#{packing_instructions_bin_line_item['variety_id']}
                                   order by treatment_code").map{|p|[p.treatment_code ,p.treatment_id.to_i]} if packing_instructions_bin_line_item && packing_instructions_bin_line_item['variety_id']
    treatment_codes = []  if !packing_instructions_bin_line_item || (packing_instructions_bin_line_item && !packing_instructions_bin_line_item['variety_id'])

    combos_js_for_commodity = gen_combos_clear_js_for_combos(["packing_instructions_bin_line_item_commodity_id", "packing_instructions_bin_line_item_track_slms_indicator_id"])
    commodity_observer = {:updated_field_id => "track_slms_indicator_id_cell",
                          :remote_method => 'refresh_track_slms_indicator',
                          :on_completed_js => combos_js_for_commodity["packing_instructions_bin_line_item_commodity_id"]}

    combos_js_for_variety = gen_combos_clear_js_for_combos(["packing_instructions_bin_line_item_variety_id", "packing_instructions_bin_line_item_treatment_id"])
    variety_observer = {:updated_field_id => "treatment_id_cell",
                        :remote_method => 'variety_changed',
                        :on_completed_js => combos_js_for_variety["packing_instructions_bin_line_item_variety_id"]}


    field_configs = []
#  ----------------------------------------------------------------------------------------------
#  Combo fields to represent foreign key (track_slms_indicator_id) on related table: track_slms_indicators
#  ----------------------------------------------------------------------------------------------
    field_configs << {:field_type => 'TextField',
                      :field_name => 'bin_qty'}

    #commodity_observer, variety_observer,size_observer,class_observer = get_rmt_observers

    field_configs[field_configs.length()] = {:field_type => 'DropDownField',
                                             :field_name => 'commodity_id',
                                             :settings => {
                                                 :list => commodity_codes,
                                                 :label_caption => 'commodity',
                                                 :show_label => true},
                                             :observer => commodity_observer}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'variety_id',
                      :settings => {:list => varieties},:observer=> variety_observer}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'size_id',
                      :settings => {:list => size_codes}}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'product_class_id',
                      :settings => {:list => product_class_codes}}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'treatment_id',
                      :settings => {:list => treatment_codes}}


    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'track_slms_indicator_id',
                      :settings => {:list => track_slms_indicator_codes}}

    field_configs[field_configs.length()] = {:field_type=>'TextArea',
                                             :field_name=>'remarks',
                                             :settings=>{
                                                 :cols=> 40,
                                                 :rows=>1
                                             } }



    construct_form(packing_instructions_bin_line_item, field_configs, action, 'packing_instructions_bin_line_item', caption, is_edit)

  end

  def get_rmt_observers
    combos_js_for_commodity = gen_combos_clear_js_for_combos(["packing_instructions_bin_line_item_commodity_id", "packing_instructions_bin_line_item_track_slms_indicator_id"])
    commodity_observer = {:updated_field_id => "track_slms_indicator_id_cell",
                          :remote_method => 'refresh_track_slms_indicator',
                          :on_completed_js => combos_js_for_commodity["packing_instructions_bin_line_item_commodity_id"]}

    combos_js_for_variety = gen_combos_clear_js_for_combos(["packing_instructions_bin_line_item_variety_id", "packing_instructions_bin_line_item_size_id"])
    variety_observer = {:updated_field_id => "size_id_cell",
                        :remote_method => 'variety_changed',
                        :on_completed_js => combos_js_for_variety["packing_instructions_bin_line_item_variety_id"]}

    combos_js_for_size = gen_combos_clear_js_for_combos(["packing_instructions_bin_line_item_size_id", "packing_instructions_bin_line_item_product_class_id"])
    size_observer = {:updated_field_id => "product_class_id_cell",
                          :remote_method => 'size_changed',
                          :on_completed_js => combos_js_for_size["packing_instructions_bin_line_item_size_id"]}

    combos_js_for_product_class= gen_combos_clear_js_for_combos(["packing_instructions_bin_line_item_product_class_id", "packing_instructions_bin_line_item_treatment_id"])
    product_class_observer = {:updated_field_id => "treatment_id_cell",
                        :remote_method => 'product_class_changed',
                        :on_completed_js => combos_js_for_product_class["packing_instructions_bin_line_item_product_class_id"]}


    return commodity_observer, variety_observer,size_observer,product_class_observer
  end


  def build_packing_instructions_bin_line_item_grid(data_set, can_edit, can_delete)

    column_configs = []
    action_configs = []
#  ----------------------
#  define action columns
#  ----------------------
    if can_edit
      action_configs << {:field_type => 'link_window', :field_name => 'edit packing_instructions_bin_line_item',
                         :column_caption => 'Edit',
                         :settings =>
                             {:link_text => 'edit',
                              :link_icon => 'edit',
                              :target_action => 'edit_packing_instructions_bin_line_item',
                              :id_column => 'id'}}
    end

    #if can_delete
      action_configs << {:field_type => 'action', :field_name => 'delete packing_instructions_bin_line_item',
                         :column_caption => 'Delete',
                         :settings =>
                             {:link_text => 'delete',
                              :link_icon => 'delete',
                              :target_action => 'delete_packing_instructions_bin_line_item',
                              :id_column => 'id'}}
    #end
    grid_command = {:field_type => 'link_window_field', :field_name => 'packing_instructions_bin_line_item',
                    :settings =>
                        {
                            :host_and_port => request.host_with_port.to_s,
                            :controller => request.path_parameters['controller'].to_s,
                            :target_action => 'new_packing_instructions_bin_line_item',
                            :link_text => 'new_packing_instructions_bin_line_item',
                            :id_value => 'id'
                        }}
    action_configs << {:field_type => 'separator'} if can_edit || can_delete
    column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?


    column_configs << {:field_type => 'link_window',:field_name => 'related_fg_line_items',
                       :column_caption => 'related_fg_line_items',:col_width => 120,
                       :width => 1200,
                       :settings =>
                           {:link_text => 'related_fg_line_items',
                            #:link_icon => 'bins',
                            :width => 1200,
                            :height => 250,
                            :target_action => 'list_related_fg_line_items',
                            :id_column => 'id'}}

    column_configs << {:field_type => 'link_window',:field_name => 'bins',
                       :column_caption => 'bins',
                       :settings =>
                           {:link_text => 'bins',
                            :link_icon => 'bins',
                            :width => 1200,
                            :height => 250,
                            :target_action => 'list_bin_line_item_bins',
                            :id_column => 'id'}}

    column_configs << {:field_type => 'text', :field_name => 'bin_qty', :data_type => 'integer', :column_caption => 'Bin qty', :col_width => 100}
    column_configs << {:field_type => 'text', :field_name => 'bin_line_item_code', :col_width => 140}
    column_configs << {:field_type => 'text', :field_name => 'commodity_code', :col_width => 100, :column_caption => 'commodity'}
    column_configs << {:field_type => 'text', :field_name => 'variety_code', :col_width => 100, :column_caption => 'variety'}
    column_configs << {:field_type => 'text', :field_name => 'size_code', :col_width => 100, :column_caption => 'size'}
    column_configs << {:field_type => 'text', :field_name => 'product_class_code', :col_width => 130, :column_caption => 'product_class'}
    column_configs << {:field_type => 'text', :field_name => 'treatment_code', :col_width => 100, :column_caption => 'treatment'}
    column_configs << {:field_type => 'text', :field_name => 'track_slms_indicator_code', :col_width => 140, :column_caption => 'track_slms_indicator'}
    column_configs << {:field_type => 'text', :field_name => 'remarks', :col_width => 140}
    column_configs << {:field_type => 'text', :field_name => 'id'}

    get_data_grid(data_set, column_configs, nil, true, grid_command)
  end

  private

  def get_rmt_product_lists(rmt_products)
    varieties = []
    dup_control = []
    commodity_codes = ActiveRecord::Base.connection.select_all("
                       select id,commodity_code from commodities where commodity_code in ('AP','PR')").map { |x| [x['commodity_code'], x['id'].to_i] }
    treatment_codes = []
    product_class_codes = []
    size_codes = []
    rmt_products.each do |rec|
      varieties << [rec['variety_code'], rec['variety_id'].to_i] if !dup_control.include?("#{rec['variety_code']}_#{rec['variety_id'].to_i}")
      treatment_codes << [rec['treatment_code'], rec['treatment_id'].to_i] if !dup_control.include?("treat_#{rec['treatment_code']}_#{rec['treatment_id'].to_i}")
      product_class_codes << [rec['product_class_code'], rec['product_class_id'].to_i] if !dup_control.include?("class_#{rec['product_class_code']}_#{rec['product_class_id'].to_i}")
      size_codes << [rec['size_code'], rec['size_id'].to_i] if !dup_control.include?("size_#{rec['size_code']}_#{rec['size_id'].to_i}")

      dup_control << "#{rec['variety_code']}_#{rec['variety_id'].to_i}" if !dup_control.include?("#{rec['variety_code']}_#{rec['variety_id'].to_i}")
      dup_control << "treat_#{rec['treatment_code']}_#{rec['treatment_id'].to_i}" if !dup_control.include?("treat_#{rec['treatment_code']}_#{rec['treatment_id'].to_i}")
      dup_control << "class_#{rec['product_class_code']}_#{rec['product_class_id'].to_i}" if !dup_control.include?("class_#{rec['product_class_code']}_#{rec['product_class_id'].to_i}")
      dup_control << "size_#{rec['size_code']}_#{rec['size_id'].to_i}" if !dup_control.include?("size_#{rec['size_code']}_#{rec['size_id'].to_i}")

    end
    return commodity_codes, product_class_codes, size_codes, treatment_codes, varieties
  end

  def get_bin_columns(column_configs)
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_number', :col_width => 114}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'tipped_date_time', :col_width => 126}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'sealed_ca_date_time', :col_width => 150}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'delivery_number', :col_width => 130}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_product_code', :col_width => 272}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code', :column_caption => 'farm', :col_width => 100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_code', :col_width => 209}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'pack_material_product_code', :col_width => 160}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_receive_date_time', :col_width => 150}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_status', :col_width => 100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_track_indicator_code', :col_width => 160}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code1', :col_width => 120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code2', :col_width => 120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code3', :col_width => 120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code4', :col_width => 120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code5', :col_width => 120}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_date_time', :col_width => 121}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'user_name', :col_width => 105}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'print_number', :column_caption => 'print_num', :col_width => 68}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'exit_reference_date_time', :col_width => 150}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id'}
  end


end
