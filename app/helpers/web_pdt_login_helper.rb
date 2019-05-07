module WebPdtLoginHelper
  def build_web_pdt_menus(func_areas)
    @hide_labels=true

    #	--------------------------------------------------------------------------------------------------
    #	Define an observer for each index field
    #	--------------------------------------------------------------------------------------------------
    session[:web_pdt_search_form]= Hash.new
    #generate javascript for the on_complete ajax event for each combo
    search_combos_js = gen_combos_clear_js_for_combos(["web_pdt_func_area","web_pdt_prog", "web_pdt_prog_func","web_pdt_dummy"])
    #Observers for search combos
    func_area_observer  = {:updated_field_id => "web_pdt_prog",
                               :remote_method => 'web_pdt_func_area_search_combo_changed',
                               :on_completed_js => search_combos_js["web_pdt_func_area"]}
    session[:web_pdt_search_form][:func_area_observer] = func_area_observer

    prog_observer  = {:updated_field_id => "web_pdt_prog_func",
                               :remote_method => 'web_pdt_prog_search_combo_changed',
                               :on_completed_js => search_combos_js["web_pdt_prog"]}
    session[:web_pdt_search_form][:prog_observer] = prog_observer

    prog_func_observer  = {:updated_field_id => "web_pdt_dummy",
                               :remote_method => 'web_pdt_prog_func_search_combo_changed',
                               :on_completed_js => search_combos_js["web_pdt_prog_func"]}
    session[:web_pdt_search_form][:prog_func_observer] = prog_func_observer




    special_combos_js = gen_combos_clear_js_for_combos(["web_pdt_special_menus","web_pdt_dummy"])
    #Observers for search combos
    special_menus_observer  = {:updated_field_id => "web_pdt_dummy",
                           :remote_method => 'web_pdt_special_menus_search_combo_changed',
                           :on_completed_js => special_combos_js["web_pdt_special_menus"]}
    session[:web_pdt_search_form][:special_menus_observer] = special_menus_observer


    special_menus = [['1a[Refresh]','1a'],
                     ['1b[Undo]','1b'],
                     ['1c[Cancel]','1c'],
                     ['1d[Save Process]','1d'],
                     ['1e[Load Process]','1e'],
                     ['1f[Redo]','1f'],
                     ['1g[Exit Process]','1g'],
                     ['Log off','log_off']]

    field_configs = []
    field_configs <<  {:field_type => 'DropDownField',
                         :field_name => 'func_area',
                         :settings => {:list => func_areas,:show_label=>false,:css_class=>session[:pdt_menu_css_class]},
                         :observer => func_area_observer}
    field_configs <<  {:field_type => 'DropDownField',
                         :field_name => 'prog',
                         :settings => {:list => [],:show_label=>false,:css_class=>session[:pdt_menu_css_class]},
                         :observer => prog_observer}
    field_configs <<  {:field_type => 'DropDownField',
                         :field_name => 'prog_func',
                         :settings => {:list => [],:show_label=>false,:css_class=>session[:pdt_menu_css_class]},
                         :observer => prog_observer}

    field_configs <<  {:field_type => 'DropDownField',
                         :field_name => 'special_menus',
                         :settings => {:list => special_menus,:show_label=>false,:css_class=>session[:pdt_menu_css_class],:html_opts=>{:style=>'background-color: #A4A4A4;'}},
                         :observer => special_menus_observer}
    field_configs <<  {:field_type => 'HiddenField',
                         :field_name => 'dummy'}

    # build_form(nil,field_configs,nil,'web_pdt','',false)
    construct_form(nil, field_configs, nil, 'web_pdt', '', false, :table_layout => false, :id => 'pdt_nav_form')
  end

end
