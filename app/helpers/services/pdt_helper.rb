module Services::PdtHelper
  def generate_cascade_observer_img(target_control)
    img = ""
    if target_control[:observer] != nil
      img = "<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_web_pdt_screen_" + target_control[:field_name] + "'/>"
    end
    return img
  end

  def generate_cascade_observer(target_control)#,pdt_screen_def,prev_pdt_screen_def=nil)
    # observer_settings = generate_observer(pdt_screen_def,target_control,prev_pdt_screen_def)
    observer = ""
    if target_control[:observer] != nil
      extra_params= ""
      if(target_control[:observer][:extra_params])
        extra_params = "+'#{target_control[:observer][:extra_params].map{|k,v| "&#{k}=#{v}"}.join}'"
      end
      observer = "observe_field('web_pdt_screen_#{target_control[:field_name]}', :with=>\"encodeURIComponent(value)+'=x'#{extra_params}\",:update => '#{target_control[:observer][:updated_field_id]}',:url => {:action => \"#{target_control[:observer][:remote_method]}\"},:loading => \"show_element('img_web_pdt_screen_#{target_control[:field_name]}');\",:complete => \"#{target_control[:observer][:on_completed_js]}\")"
    end
    return observer


    #
    # observer_settings = generate_observer(pdt_screen_def,target_control)
    # if target_control[:observer] != nil
    #   if(target_control[:observer][:extra_params])
    #     extra_params = "+'#{target_control[:observer][:extra_params].map{|k,v| "&#{k}=#{v}"}.join}'"
    #   end
    #   observer = observe_field('web_pdt_screen_#{target_control[:field_name]}',
    #                                 :update   => target_control[:observer][:updated_field_id],
    #                                 :url      => {:action => target_control[:observer][:remote_method]},
    #                                 :complete => target_control[:observer][:on_completed_js],
    #                                 :with     => "encodeURIComponent(value)+'=x'#{extra_params}",
    #                                 :loading  => "show_element('img_web_pdt_screen_" + target_control[:field_name] + "');")
    #  end
  end

  def get_clear_js_for_combos(root_control,cascade_controls,level,combos_to_clear)
    level += 1
    child_casc_cntrl = cascade_controls.find{|cont| (cont['cascades'][:settings]['filter_fields'] && cont['cascades'][:settings]['filter_fields'].include?(root_control['name']) && cont['cascades'][:settings]['filter_fields'].split(',').length == level)}
    if(child_casc_cntrl)
      combos_to_clear += ",web_pdt_screen_#{child_casc_cntrl['name']}"
      return get_clear_js_for_combos(child_casc_cntrl,cascade_controls,level,combos_to_clear)
    end
    combos_to_clear += ",web_pdt_screen_#{root_control['cascades'][:settings]['target_control_name']}"
    return combos_to_clear
  end

  def generate_observer(pdt_screen_def,casc_cont,prev_pdt_screen_def=nil)
    clear_js_for_combos = {}
    onload_js_for_combos = {}

    (cascade_controls = pdt_screen_def.controls.find_all{|cont| cont.keys.include?('cascades')}).each do |casc_cntl|
      if(casc_cntl['cascades'][:type] == 'filter')
        if(casc_cntl['cascades'][:settings]['filter_fields'].split(',').length == 1)
          level = 1
          combos_to_clear = "web_pdt_screen_#{casc_cntl['name']}"
          combos_to_clear += get_clear_js_for_combos(casc_cntl,cascade_controls,level,"")
          clear_js_for_combos.store(combos_to_clear,gen_combos_clear_js_for_combos(combos_to_clear.split(',')))
        end
      end
    end

    observer = nil
    if(prev_pdt_screen_def)
      target_control_type = prev_pdt_screen_def.controls.find{|cont| cont['name']==casc_cont['cascades'][:settings]['target_control_name']}['type']
    else
      target_control_type = pdt_screen_def.controls.find{|cont| cont['name']==casc_cont['cascades'][:settings]['target_control_name']}['type']
    end

    onload_js_for_combo = (casc_cont['cascades'][:settings]['filter_fields'].split(',')-[casc_cont['name']]).map{|f| [f,"web_pdt_screen_#{f}"]}
    if(casc_cont['cascades'][:type] == 'filter')

      #generate javascript for the on_complete ajax event for each combo
      search_combos_js = clear_js_for_combos.find{|k,v| k.include?("web_pdt_screen_#{casc_cont['name']}")}[1]
      observer  = {:updated_field_id => (target_control_type=="static_text") ? "#{casc_cont['cascades'][:settings]['target_control_name']}_cell" : "web_pdt_screen_#{casc_cont['cascades'][:settings]['target_control_name']}",
                   :remote_method => 'web_pdt_filter_field_search_combo_changed',
                   :extra_params=>{:remote_list=>casc_cont['cascades'][:settings]['get_list'],
                                   # :filter_fields=>casc_cont['cascades'][:settings]['filter_fields'],
                                   :return_column=>casc_cont['cascades'][:settings]['list_field'],
                                   :observed_field=>casc_cont['name'],
                                   :target_control_name=>casc_cont['cascades'][:settings]['target_control_name']},
                   :on_load_js => onload_js_for_combo,
                   :on_completed_js => search_combos_js["web_pdt_screen_#{casc_cont['name']}"]}


    elsif(casc_cont['cascades'][:type] == 'replace_control')
      search_combos_js = gen_combos_clear_js_for_combos(["web_pdt_screen_#{casc_cont['name']}","web_pdt_screen_#{casc_cont['cascades'][:settings]['target_control_name']}"])
      updated_field_id = (target_control_type=="static_text") ? "#{casc_cont['cascades'][:settings]['target_control_name']}_cell" : "web_pdt_screen_#{casc_cont['cascades'][:settings]['target_control_name']}"
      observer  = {:updated_field_id => updated_field_id,
                   :remote_method => 'web_pdt_replace_field_search_combo_changed',
                   :extra_params=>{:mode=>PdtScreenDefinition.const_get("CONTROL_VALUE_REPLACE").to_s,
                                   :user=>params[:user],
                                   :ip=>params[:ip],
                                   :menu_item=>pdt_screen_def.screen_attributes['current_menu_item'],
                                   :remote_method=>casc_cont['cascades'][:settings]['remote_method'],
                                   :observed_field=>casc_cont['name'],
                                   # :filter_fields=>casc_cont['cascades'][:settings]['filter_fields'],
                                   # :prev_screen_xml_definition=>pdt_screen_def.get_output_xml,
                                   :target_control_name=>casc_cont['cascades'][:settings]['target_control_name']},
                   # :updated_field_id=>updated_field_id},
                   :on_load_js => onload_js_for_combo,
                   :on_completed_js => search_combos_js["web_pdt_screen_#{casc_cont['name']}"]}

    end
    return observer
  end

  def generate_web_pdt_field_configs(pdt_screen_def,web_pdt_css_styles,prev_pdt_screen_def=nil)
    observers = {}
    observer = nil
    pdt_screen_def.controls.find_all{|cont| cont.keys.include?('cascades')}.each do |casc_cont|
      observer = generate_observer(pdt_screen_def,casc_cont,prev_pdt_screen_def)
      observers.store(casc_cont['name'],observer)
    end

    # get list for drop_downs
    # pdt_screen_def.controls.push({'name'=>'start_date_time_date2from','type'=>'date','value'=>'','label'=>'start_date_time'})
    # pdt_screen_def.controls.push({'name'=>'end_date_time_date2to','type'=>'date','value'=>'2015-12-25','label'=>'end_date_time'})
    # pdt_screen_def.controls.push({'name'=>'textus','type'=>'text_area','value'=>'texto','label'=>'texto'})
    # pdt_screen_def.controls.push({'type'=>"check_box",'name'=>"valid",'label'=>"valid?", 'value'=>false})

    field_configs = pdt_screen_def.gen_controls_list_html_configs(web_pdt_css_styles,observers,request)
    return field_configs
  end

  def build_web_pdt_screen_configs(pdt_screen_def,web_pdt_css_styles)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
    # session[:web_pdt_screen_search_form]= Hash.new

    field_configs = generate_web_pdt_field_configs(pdt_screen_def,web_pdt_css_styles)

    field_configs <<  {:field_type => 'HiddenField',
                       :field_name => 'web_pdt_current_menu_item_submit_value'}
    field_configs <<  {:field_type => 'HiddenField',
                       :field_name => 'mode_submit_value'}
    field_configs <<  {:field_type => 'HiddenField',
                       :field_name => 'logged_on_user_submit_value'}
    field_configs <<  {:field_type => 'HiddenField',
                       :field_name => 'xml_definition'}


    return field_configs

  end

  def build_web_pdt_screen(pdt_screen_def,web_pdt_css_styles)
    begin
      field_configs = build_web_pdt_screen_configs(pdt_screen_def,web_pdt_css_styles)
    rescue
      PdtScreenDefinition.log_pdt_error($!,@user,@ip,@mode,@input_xml,@menu_item)
      error_screen_def = PdtScreenDefinition.get_pdt_error_screen($!,@pdt_method,@client_type,@mode)
      pdt_screen_def = PdtScreenDefinition.new(error_screen_def, @menu_item, @mode, @user, @ip)
      field_configs = build_web_pdt_screen_configs(pdt_screen_def,web_pdt_css_styles)
      @is_unexpected_error_screen = true
    end

    attrs={'web_pdt_current_menu_item_submit_value'=>nil, 'mode_submit_value'=>nil,
           'logged_on_user_submit_value'=>nil,'xml_definition'=>nil,}
    pdt_screen_def.controls.map{|cont|  attrs.store(cont['name'],cont['value'])}
    @object_builder = ObjectBuilder.new
    @web_pdt_screen = @object_builder.build_arbitrary_object('WebPdtScreen',attrs)

    pdt_screen_def.controls.find_all{|cont| cont['type']=='date'}.each do |cntrl|
      eval("@web_pdt_screen.#{cntrl['name']} = DateTime.parse('#{cntrl['value']}') ") if(cntrl['value'].to_s.strip != "")
    end

    pdt_screen_def.controls.find_all{|cont| cont['type']=='check_box'}.each do |cntrl|
      if(cntrl['value'].to_s == "true" || cntrl['value'].to_s == "t")
        eval("@web_pdt_screen.#{cntrl['name']} = 1")
      elsif(cntrl['value'].to_s == "false" || cntrl['value'].to_s == "f")
        eval("@web_pdt_screen.#{cntrl['name']} = 0")
      end
    end

    build_form(@web_pdt_screen,field_configs,'handle_pdt_web_request','web_pdt_screen','',false)
  end

  def generate_control_to_be_replaced(field_config,control_config,web_pdt_css_styles)
    controls_to_be_replaced = []
    attrs = {control_config['name']=>control_config['value']}
    @object_builder = ObjectBuilder.new
    @web_pdt_screen = @object_builder.build_arbitrary_object('WebPdtScreen',attrs)
    @active_record_var_name = 'web_pdt_screen'
    @active_record = @web_pdt_screen
    env = ApplicationHelper::Form.new(self, @web_pdt_screen, [field_config], '', @active_record_var_name, '')

      case field_config[:field_type]
      when 'PopupDateRangeSelector'
          control = MesScada::FormComponents::PopupDateRangeSelector.new(env, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
      when "PopupDateSelector" #Henry
          control = MesScada::FormComponents::PopupDateSelector.new(env, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
      when "PopupDateTimeSelector"
          control = MesScada::FormComponents::PopupDateTimeSelector.new(env, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
      when "CheckBox"
          control = MesScada::FormComponents::CheckBox.new(env, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        when "TextField"
          # field_config[:settings][:html_opts] = {:onchange=>"alert('sobhuza');"}
          @replace_control_css_class = web_pdt_css_styles[:pdt_text_text_box]
          # field_config[:settings][:show_label] = true
          control = MesScada::FormComponents::TextField.new(env, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
      when "LabelField"
          # @replace_control_css_class = web_pdt_css_styles[:pdt_text_line]
          # control = MesScada::FormComponents::StaticField.new(env, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        field_config[:settings][:readonly] = true
        @replace_control_css_class = web_pdt_css_styles[:pdt_static_text]
        control = MesScada::FormComponents::TextField.new(env, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
      when "TextArea"
          @replace_control_css_class = web_pdt_css_styles[:pdt_text_area]
          control = MesScada::FormComponents::TextArea.new(env, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
      when "DateField"
          @replace_control_css_class = web_pdt_css_styles[:pdt_date_field]
          control = MesScada::FormComponents::DateField.new(env, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
      when "DateTimeField"
          @replace_control_css_class = web_pdt_css_styles[:pdt_date_field]
          control = MesScada::FormComponents::DateTimeField.new(env, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        when "DropDownField"
          # field_config[:settings][:html_opts] = {:onfocus=>"alert('sobhuza');"}
          @replace_control_css_class = web_pdt_css_styles[:pdt_drop_down]
          control = MesScada::FormComponents::DropDownField.new(env, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
      else
      raise "cannot create unknown field. passed-in type was: " + field_config[:field_type].to_s
      end

    # puts " control : #{control.build_control}"
    return control
  end
end