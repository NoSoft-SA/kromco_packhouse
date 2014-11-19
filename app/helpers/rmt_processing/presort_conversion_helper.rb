module RmtProcessing::PresortConversionHelper

  #MM072014

  def build_new_presort_conversions_form(presort_conversions,action,caption,is_edit = nil,is_create_retry = nil)

    session[:presort_conversions_form]= Hash.new

    field_configs = []

    # 1] commodity_code {from commodities]
    # 2] rmt_variety_code [from rmt_varieties filtered by selected commodity]
    # 3] grade [from grades]
    # 4] line_type ['PRIMARY' or 'SECONDARY']
    # 5] marketing_variety_code [from marketing_varieties filtered by commodity]
    # 6] treatment_code [from treatments]
    # 7] product_class_code [from product-classes]

    commodity_code = Commodity.find_by_sql("select * from commodities").map{|g|["#{g.commodity_code} - #{g.commodity_description_long}", g.commodity_code]}
    commodity_code.unshift(["<empty>", nil])

    search_combos_js = gen_combos_clear_js_for_combos(["presort_conversions_commodity_code","presort_conversions_rmt_variety_code","presort_conversions_marketing_variety_code"])
    commodity_code_observer  = {:updated_field_id => "rmt_variety_code_cell",
                                :remote_method => 'commodity_code_search_combo_changed',
                                :on_completed_js => search_combos_js["presort_conversions_commodity_code"]}

    if commodity_code == nil#||is_create_retry
      rmt_variety_code = ["Select a value from commodity_code"]
      marketing_variety_code = ["Select a value from commodity_code"]
    else
      rmt_variety_code = RmtVariety.find_by_sql("select * from rmt_varieties where commodity_code = '#{session[:commodity_code]}'").map{|g|["#{g.rmt_variety_code} - #{g.rmt_variety_description}", g.rmt_variety_code]}
      rmt_variety_code.unshift(["<empty>", nil])

      marketing_variety_code = MarketingVariety.find_by_sql("select * from marketing_varieties where commodity_code = '#{session[:commodity_code]}'").map{|g|["#{g.marketing_variety_code} - #{g.marketing_variety_description}", g.marketing_variety_code]}
      marketing_variety_code.unshift(["<empty>", nil])

    end

    grade_code = Grade.find_by_sql("select * from grades").map{|g|["#{g.grade_code} - #{g.grade_description}", g.grade_code]}
    grade_code.unshift(["<empty>", nil])

    line_type = ["PRIMARY", "SECONDARY"]
    line_type.unshift(["<empty>", nil])

    treatment_code = Treatment.find_by_sql("select * from treatments").map{|g|["#{g.treatment_code} - #{g.description}", g.treatment_code]}
    treatment_code.unshift(["<empty>", nil])

    product_class_code = ProductClass.find_by_sql("select * from product_classes").map{|g|["#{g.product_class_code} - #{g.product_class_description}", g.product_class_code]}
    product_class_code.unshift(["<empty>", nil])

    field_configs <<  {:field_type => 'DropDownField',
                             :field_name => 'commodity_code?required',
                             :settings => {:list => commodity_code, :label_caption => 'commodity_code'},
                             :observer => commodity_code_observer}

    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'rmt_variety_code?required',
                       :settings => {:list => rmt_variety_code, :label_caption => 'rmt_variety_code'}}

    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'grade_code?required',
                       :settings => {:list => grade_code, :label_caption => 'grade_code'}}

    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'line_type?required',
                       :settings => {:list => line_type, :label_caption => 'line_type'}}

    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'marketing_variety_code?required',
                       :settings => {:list => marketing_variety_code, :label_caption => 'marketing_variety_code'}}

    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'treatment_code?required',
                       :settings => {:list => treatment_code, :label_caption => 'treatment_code'}}

    field_configs <<  {:field_type => 'DropDownField',
                       :field_name => 'product_class_code?required',
                       :settings => {:list => product_class_code, :label_caption => 'product_class_code'}}

    build_form(presort_conversions,field_configs,action,'presort_conversions',caption,is_edit)

  end

  def build_list_presort_conversions_grid(data_set,can_edit,can_delete)

    column_configs = []

    column_configs << {:field_type => 'text',:field_name => 'commodity_code', :column_caption => 'commodity_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'commodity_description_long', :column_caption => 'commodity_description', :col_width => 150}

    column_configs << {:field_type => 'text',:field_name => 'rmt_variety_code', :column_caption => 'rmt_variety_code', :col_width => 150}
    column_configs << {:field_type => 'text',:field_name => 'rmt_variety_description', :column_caption => 'rmt_variety_description', :col_width => 150}

    column_configs << {:field_type => 'text',:field_name => 'grade_code', :column_caption => 'grade_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'grade_description', :column_caption => 'grade_description', :col_width => 100}

    column_configs << {:field_type => 'text',:field_name => 'line_type', :column_caption => 'line_type', :col_width => 100}

    column_configs << {:field_type => 'text',:field_name => 'marketing_variety_code', :column_caption => 'marketing_variety_code', :col_width => 150}
    column_configs << {:field_type => 'text',:field_name => 'marketing_variety_description', :column_caption => 'marketing_variety_description', :col_width => 200}

    column_configs << {:field_type => 'text',:field_name => 'treatment_code', :column_caption => 'treatment_code', :col_width => 100}
    column_configs << {:field_type => 'text',:field_name => 'description', :column_caption => 'treatment_description', :col_width => 150}

    column_configs << {:field_type => 'text',:field_name => 'product_class_code', :column_caption => 'product_class_code', :col_width => 150}
    column_configs << {:field_type => 'text',:field_name => 'product_class_description', :column_caption => 'product_class_description', :col_width => 200}

    # column_configs << {:field_type => 'text',:field_name => 'id', :column_caption => 'id', :col_width => 100}

    column_configs << {:field_type => 'action',:field_name => 'edit_current_presort_conversions', :column_caption => 'edit', :col_width => 100,
                     :settings =>
                         {:link_text => 'edit',
                          :target_action => 'edit_current_presort_conversions',
                          :id_column => 'id'}}

    column_configs << {:field_type => 'action',:field_name => 'delete_presort_conversions', :column_caption => 'delete', :col_width => 100,
                     :settings =>
                         {:link_text => 'delete',
                          :target_action => 'delete_presort_conversions',
                          :id_column => 'id'}}

    set_grid_min_height(1110)
    hide_grid_client_controls()

    get_data_grid(data_set, column_configs, nil, true)

  end

end