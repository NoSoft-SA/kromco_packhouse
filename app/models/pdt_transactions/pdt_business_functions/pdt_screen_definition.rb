require 'rexml/document'

class PdtScreenDefinition

  include REXML

  #**************************************************************************************
  # :controls - Array of hashes,each hash's keys representing the attribute of a control
  # :buttons - Hash,keys representing the attributes of the 3 buttons
  # :screen_attributes - Hash,keys representing the attributes of the screen
  #**************************************************************************************
  attr_accessor :input_xml,:menu_item,:mode,:user,:ip,:controls,:buttons,:screen_attributes

    MENUSELECT   = 0;                    # Menu select/reconfig mode
    ENTERDATA    = 1;                    # Submit Auto mode
            IDLE         = 2;                    # Enter button
            ENTER        = 3;                    # Normal transaction button
    BUTTON1      = 4;                    # Yes button clicked mode
    BUTTON2      = 5;                    # No button clicked mode
    BUTTON3      = 6;                    # Cancel button mode
    CANCEL       = 7;                    # Cancel special command mode
    REFRESH      = 8;                    # Refresh special command mode
    UNDO         = 9;                    # Undo special command mode
    SAVE_PROCESS = 12;
    LOAD_PROCESS = 11;
              CHOICE       = 10;
    REDO         = 13
    EXIT_PROCESS = 14;
    CONTROL_VALUE_REPLACE = 15

  #*********************************************************************************************
  # Parameters:
  #   1. input_xml - This is the xml string that is used to build the PdtScreenDefinition object
  #                  i.e. :controls,:buttons and :screen_attributes will all
  #                  be extracted from the relevant nodes of this structred xml to form the
  #                  PdtScreenDefinition object
  #*********************************************************************************************
  def initialize(input_xml,menu_item,mode,user,ip)
    @menu_item = menu_item#.to_s
    @mode = mode
    @user = user
    @ip = ip
    @input_xml = input_xml
    @controls = Array.new
    @buttons = Hash.new
    @screen_attributes = Hash.new

    @doc = Document.new @input_xml
    @root = @doc.root

    process_input(@root)

    @doc = nil
    @root = nil
  end


  def gen_controls_list_html_configs(web_pdt_css_styles,observers,request)
    field_configs = []
    @controls.each do |config|
      field_configs << PdtScreenDefinition.gen_control_html_config(config,web_pdt_css_styles,observers[config['name']],request)
    end
    return field_configs
  end

  def self.build_error_screen(error_msg,error_fields=[])
    error_screen_definition = "<error> <controls>"
    error_fields.each do |field|
      error_screen_definition += "<control name='#{field}'></control>"
    end
    error_screen_definition += "</controls>"
    error_screen_definition += "<message>#{error_msg}</message></error>"
  end
  #******************************************************
  # Returns the input control whose name matches the
  # parameter from the controls list of this object
  #******************************************************
  def get_control(name)
    for control in @controls
      if control["name"] == name
        return control
      end
    end
    return nil
  end

  #***************************************************************
  # Returns the value of the input control whose name matches the
  # parameter from the controls list of this object
  #***************************************************************
  def get_control_value(name)
    control = get_control(name)
    if control != nil
      return control["value"]
    end
  end

  def get_input_control(name)
    for control in @controls
      if control["name"] == name  #&& control["type"] != 'static_text' && control["type"] != 'text_line'
        return control
      end
    end
    return nil
  end

  #***************************************************************
  # Returns the value of the input control whose name matches the
  # parameter from the controls list of this object
  #***************************************************************
  def get_input_control_value(name)
    control = get_input_control(name)
    if control != nil
      return control["value"]
    end
  end

  #***************************************************************
  # Returns the id_value of the input control whose name matches the
  # parameter from the controls list of this object
  #***************************************************************
  def get_input_control_id_value(name)
    control = get_input_control(name)
    if control != nil
      return control["id_value"]
    end
  end



  #***************************************************************
  # Returns the value of the output control whose name matches the
  # parameter from the controls list of this object
  #***************************************************************get_control_value
  def get_control_value(name)
    return get_input_control_value(name)
  end

  def get_output_xml()
    @screen_attributes[:current_menu_item] = @menu_item if @menu_item
    PdtScreenDefinition.gen_screen_xml(@controls,@buttons,@screen_attributes,@plugins)
  end

  private
    def process_input(root)
      root.attributes.each do |button_attr_name, button_attr_value|
        @buttons.store(button_attr_name, button_attr_value.to_s.strip.gsub("=","^"))
      end

      root.elements.each do |element|
        # Only interested in <controls> node
        # i.e. ignore plugins
        if(element.name == "controls")
          element.attributes.each do |screen_attr_name, screen_attr_value|
            @screen_attributes.store(screen_attr_name, screen_attr_value.to_s.strip.gsub("=","^"))
          end

          element.elements.each do |control|
            field_configs = Hash.new
            control.attributes.each do |attr_name, attr_value|
              attr_value = attr_value.to_s.gsub!("!","\'") if attr_value.include?("!")
              attr_value = attr_value.to_s.gsub!("$","\"") if attr_value.include?("$")
              if(attr_name=='value' && control.attributes.include?('strip') && control.attributes['strip'] == 'false')
                field_configs.store(attr_name, attr_value.to_s.gsub("=","^"))
              else
                field_configs.store(attr_name, attr_value.to_s.strip.gsub("=","^"))
              end
            end

            #childre - build cascades array/hash and put in field_configs.store(:cascades, it)
            if(control.children.length > 0)
              for control_child in control.children
                if(control_child.name=='cascades')
                  for cascade in control_child.children
                    puts
                    settings = {}
                    cascade.attributes.each do |atr_name, atr_value|
                      atr_value = atr_value.to_s.gsub!("!","\'") if atr_value.include?("!")
                      atr_value = atr_value.to_s.gsub!("$","\"") if atr_value.include?("$")
                      settings.store(atr_name, atr_value.to_s.strip.gsub("=","^"))
                    end
                    field_configs['cascades'] = {:type=>cascade.name,:settings=>settings}
                  end
                end
              end
            end
            @controls.push(field_configs)
          end
        end
      end

      @input_xml = get_output_xml()
    end


#*********************************************************************************************
# Parameters:
#   1. field_configs - This is an array of hashes.The keys of each hash represent the configurations
#                      used by the client framework to build a control.
#
#   e.g. field_configs = Array.new
#        field_configs[field_configs.length] = {:type=>"date",:name=>"start_date_time_date2from",:label=>"start_date_time",:value=>""}
#
#                Field/Control configurations - (i):type = the type of the control/field.[Must specify]
#                                               (ii):name = the name of the control/field.This
#                                                   must be unique for input controls and the client will
#                                                   throw an exception if it isn't.Does not have to be unique
#                                                   for output controls.[Must specify]
#                                               (iii):is_required = means that when the screen containing this
#                                                    control is submitted,a valid value must be provided for
#                                                    it.[Optional]
#                                                (iv):value = this the value of the control.This will be displayed
#                                                    by the client when this controls is built and displayed.[Optional]
#                                                (v):label = This is the control's label.If this is not specified,the
#                                                   control's name will be used as the label.[Optional]
#
#   e.g. field_configs = Array.new
#        field_configs[field_configs.length] = {:type=>"drop_down",:name=>'line_code',:list_field=>'line_code',:get_list=>'get_production_runs_results',
#                                          :cascades=>cascades}
#
#                                                (vi):list = this only applies to a drop_down control.It is a comma separated
#                                                    string that represents the list for this control when the client builds
#                                                    and displays it.[Must specify when get_list is ommitted]
#                                                (vii):get_list = this only applies to a drop_down control.It is the name of the
#                                                     service to called to return the list for this control when the client builds
#                                                    and displays it.[Must specify when list is ommitted]
#                                                 (viii):list_field = this is the field in the record set return by service :get_list,
#                                                       that should be used as the control's list.[Must specify when using get_list]
#                                                 (ix):cascades - Can either be a hash(when specifying one cascade action) OR an
#                                                     Array(when specifying one/more cascade actions).These are the actions to be performed
#                                                     when a drop_drown value is selected.See below the descriptions of the keys/configs
#                                                     of a cacade are.[Optional]
#
#    e.g. cascades = Array.new
#         cascades[cascades.length] = {:type=>'filter',
#                                  :settings=>{:target_control_name=>'farm_code',:list_field=>'farm_code',:get_list=>'get_production_runs_results',:filter_fields=>'line_code'}}
#    e.g. cascades = Hash.new
#         cascades = {:type=>'filter',
#                   :settings=>{:target_control_name=>'user_process_name',:list_field=>'user_process_name',:get_list=>'get_stored_pdt_processes',:filter_fields=>'transaction_name'}}

#                Cascade configs - (i):type = The cascading action types.Can be 'filter'(filters depent drop_downs) OR
#                                     'value'(sets value of dependent control).[Must specify]
#                                  (ii):settings = These are settings for a filter_cascade.See below for description of each
#
#                                  Settings of a filter cascades - (a):target_control_name = the name of the control to be filtered
#                                                   (b):get_list = It is the name of the service to called to return the list for target
#                                                       control.
#                                                   (c):list_field = this is the field in the record set return by service :get_list,
#                                                       that should be used as the control's list.[Must specify when using get_list]
#                                                   (d):filter_fields = these are fields/column names that'll be used to filter the
#                                                     recordset before extracting the target drop_down's list.
#
# 2. buttons - This is a hash whose keys represent the 3 screen buttons' configs
#         Button configurations - (i):B1Label,(ii):B2Label,(iii):B3Label = are the cations for button1,button2 and button3 respectively.
#                                 (iv):B1Enable,(v):B2Enable and (vi):B3Enable = [value = true/false] to tell the client which buttons should be visible
#                                 (vii):B1Submit,(viii):B2Submit and (ix):B3Submit = the server-side methods to be executed when button1,button2
#                                      or button3 is clicked,respectively.
#
#    e.g. buttons = {"B3Label"=>"Clear" ,"B2Label"=>"Cancel","B1Label"=>"Submit","B1Submit"=>"run_stats_submit","B1Enable"=>"true","B2Enable"=>"false","B3Enable"=>"false" }
#
# 3. screen_attributes - A hash whose keys represent screen settings
#         Screen settings - (i):auto_submit = Tells the client whether or not it must automatically submit the screen in the absence of buttons.[value = ture/false]
#                           (ii):content_header_caption = specifies the screen's content_header_caption
#                           (iii):current_menu_item = specifies the current_menu_item
#
#    e.g. screen_attributes = {:auto_submit=>"false",:content_header_caption=>"search production runs",:current_menu_item=>"2.2.1.1"}
#
# 4. plugins - An array of plugin configs.Each plugin configs is represented in the form of a hash's keys
#        Plugin configs - (i):class_name = Is the name of the Plugin class to be created and applied to this page.
#                         (ii):plugin_type = The plugin type.[values = Screen/Workspace]
#                         (iii):life_cycle = The lifetime of a plugin
#                         (iv):target_pdts = The list of pdt's on which this plugin must apply
#
#    e.g. plugins = Array.new
#         plugins[plugins.length] = {:class_name=>'LabelPlugin',:plugin_type=>'workspace',:life_cycle=>'screen',:target_pdts =>'' }
#         plugins[plugins.length] = {:class_name=>'Test3',:plugin_type=>'workspace',:life_cycle=>'screen',:target_pdts =>'' }
#*********************************************************************************************
 def  self.gen_screen_xml(field_configs=nil,buttons=nil,screen_attributes=nil,plugins=nil)
    field_configs = Array.new if field_configs == nil
    buttons = Hash.new  if buttons == nil
    screen_attributes = Hash.new  if screen_attributes == nil
    plugins = Array.new if plugins == nil

    returnStr = "<PDTRF Status=\"true\" Msg=\"\" "
    #if buttons == nil ... should I set default button attributes e.g. 'yes'/'no'/'cancel' all set to invisible?
    if buttons.keys != nil
      buttons.keys.each do |key|
        returnStr += key.to_s + "=\"" + buttons[key].to_s.strip.gsub("=","^") + "\" "
      end
    end
    returnStr = returnStr.strip! + ">"

    returnStr += "<controls "
    #returnStr += "\n\t<controls "
    if screen_attributes.keys != nil
      screen_attributes.keys.each do |key|
        returnStr += key.to_s + "=\"" + screen_attributes[key].to_s.strip.gsub("=","^") + "\" "
      end
    end
    returnStr = returnStr.strip! + ">"

    for control in field_configs
      returnStr += self.gen_control_xml(control)
    end
    returnStr += "</controls>"

    for plugin in plugins
      returnStr += "<plugin "
      if plugin.keys != nil
        plugin.keys.each do |key|
          returnStr += key.to_s + "=\"" + plugin[key].to_s.strip.gsub("=","^") + "\" "
        end
      end
      returnStr = returnStr.strip! + "/>"
    end

    returnStr += "</PDTRF>"
    return returnStr
 end

 def self.gen_control_xml(field_configs)
    returnStr = "<control "
    cascades = nil
    if field_configs.keys != nil
      field_configs.keys.each do |key|
        if key.to_s != "cascades"
          attr_val = field_configs[key].to_s
          attr_val.gsub!("'","")
          attr_val.gsub!("\"","")
          returnStr += key.to_s + "=\"" + attr_val.strip.gsub("=","^") + "\" "
        else
          cascades = field_configs[key]
        end
      end
    end
    if cascades != nil
      returnStr = returnStr.strip! + ">" + PdtScreenDefinition.cascades(cascades) + "</control>"
    else
      returnStr = returnStr.strip! + "/>"
    end
 end

 def self.gen_controls_list_xml(field_configs)
   if(!field_configs.is_a?(Array))
     field_configs = [field_configs]
   end

   result_xml = "<controls>"
   field_configs.each do |configs|
     result_xml += PdtScreenDefinition.gen_control_xml(configs)
   end
   result_xml += "</controls>"
 end

  def PdtScreenDefinition.get_pdt_error_screen(exception,pdt_method,client_type,mode)
    if (exception.is_a?(PdtException))

      result_screen = PDTTransaction.build_msg_screen_definition(exception.pdt_errors, nil, nil, nil)
      return render_result(result_screen)
    end

    exception = exception.to_s
    remove_special_chars = exception.gsub("<", "[").gsub(">", "]").gsub("\\", "|").gsub("/", "|")
    lcd1 = "SYSTEM ERROR :"
    lcd2 = pdt_method.program_name.to_s + "(" + pdt_method.method_name.to_s + ")" if (pdt_method)
    lcd3 = "DESCRIPTION :"
    error_description = Array.new

    if(client_type=='web') && Globals.suppress_pdt_web_errors
      error_description = ["see diagnostics pdt_errors"]
    else
      while (error_description.length < 10 && remove_special_chars.length > 0 && remove_special_chars.length > 60)
        puts "remove_special_chars.length = " + remove_special_chars.length.to_s
        lcd = remove_special_chars.slice!(0, 60)
        error_description.push(lcd)
      end
      error_description.push(remove_special_chars) if (remove_special_chars.length > 0)
    end

    output_lines = [lcd1, lcd2, lcd3] + error_description

    screen_caption = "Server Exception"
    if (mode == PdtScreenDefinition.const_get("CONTROL_VALUE_REPLACE").to_s)
      error_screen_definition = "<error>" + exception + "</error>"
    else
      error_screen_definition = send_screen(output_lines, screen_caption, nil)
    end
    return error_screen_definition
  end

  #-----------------------------------------------------------------------
  # This method to build output/display error screens.It takes messages to be be
  # displayed in the output lines of the screen and returns a xml screen
  # definition.
  #-----------------------------------------------------------------------
  def PdtScreenDefinition.send_screen(output_lines=[], screen_caption=nil, plugins=nil)

    field_configs = Array.new
    for output_line in output_lines
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=>output_line.to_s}
    end
    screen_attributes = {:auto_submit=>"false", :content_header_caption=>screen_caption.to_s}
    buttons = {"B3Label"=>"Clear", "B2Label"=>"Cancel", "B1Label"=>"Submit", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
    screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return screen_def
  end


  def PdtScreenDefinition.log_pdt_error(exception,user,ip,mode,input_xml,menu_item)
    pdt_error = PdtError.new
    pdt_error.user_name = user
    pdt_error.created_on = Time.now
    pdt_error.error_description = exception.to_s
    pdt_error.stack_trace = exception.backtrace.join("\n").to_s
    pdt_error.ip = ip
    pdt_error.mode = mode.to_i
    pdt_error.input_xml = input_xml
    pdt_error.menu_item = menu_item
    pdt_error.error_type = "PdtControllerError"
    pdt_error.save
  end


  def PdtScreenDefinition.gen_control_html_config(config,web_pdt_css_styles,observer,request)
   web_pdt_css_styles = {} if(!web_pdt_css_styles)
   type = config['type']
   case type
     when 'drop_down'
       if(config['list'])
         # list = config['list'].split(',').map{|item| item.split('|')}
         list = config['list'].split(',').map{|item| [item.split('|')[0],item]}
       elsif(config['get_list'])
         params = {'request'=>request}
         remote_list = eval("PdtRemoteList.#{config['get_list']}(params)")
         list = remote_list.empty? ? [] : (remote_list[0].is_a?(Hash) ? remote_list.map{|l| l[config['list_field']]} : remote_list.map{|l| l.attributes[config['list_field']]})
       else
         list = []
       end
       # list.unshift(config['value']) if(config['value'])
       settings = {:field_type => 'DropDownField',:field_name => config['name'],
        :settings=>{:list=>list, :no_empty=>false,:css_class=>web_pdt_css_styles[:pdt_drop_down]}}
        # :settings=>{:list=>list, :no_empty=>false,:css_class=>web_pdt_css_styles[:pdt_drop_down],:html_opts => {:onchange=>"#{observer ? observer[:on_load_js] : nil}"}}}
       settings[:observer] = observer if(observer)
     when 'text_box'
       settings = {:field_type => 'TextField',:field_name => config['name'],
        :settings => {:css_class=>web_pdt_css_styles[:pdt_text_text_box]}}
        settings[:observer] = observer if(observer)
        settings[:settings][:html_opts] = {'data-scanner' => 'key248_all'} if config['scan_field']
        settings[:settings][:html_opts]['data-submit-form'] = 'submit' if config['scan_field'] && config['submit_form']
       #:html_opts => {:onchange=>"next_text_box.onfocus",:onfocus=>"this.focus();"}
     when 'text_area'
       settings = {:field_type => 'TextArea',:field_name => config['name'],
        :settings => {:css_class=>web_pdt_css_styles[:pdt_text_area]}}
     when 'date'
       settings = {:field_type => 'PopupDateTimeSelector',:field_name => config['name'],
                   :settings => {:css_class=>web_pdt_css_styles[:pdt_date_field]}}
     when 'check_box'
       settings = {:field_type => 'CheckBox',:field_name => config['name'],:settings =>{:css_class=>web_pdt_css_styles[:pdt_check_box]}}
     when 'text_line'
       settings = {:field_type => 'LabelField',:field_name => config['name'],
        :settings=>{:static_value=>config['value'],:css_class=>web_pdt_css_styles[:pdt_text_line]}}
     when 'static_text'
       # settings = {:field_type => 'LabelField',:field_name => config['name'],
       #  :settings=>{:show_label=>true,:static_value=>config['value'],:css_class=>web_pdt_css_styles[:pdt_static_text]}}
       settings = {:field_type => 'TextField',:field_name => config['name'],
                   :settings => {:css_class=>web_pdt_css_styles[:pdt_static_text],:readonly=>true}}
   end

   settings[:settings][:label_caption] = config['label'] if(config['label'])
   return settings
 end

 def self.gen_ajax_error_xml(error)
  "<error> " + error + " </error>"
 end

 private
 def self.cascades(cascades)
   puts
   puts
   puts
   returnStr = "<cascades>"
   if(cascades.kind_of?(Array))
    for cascade in cascades
      returnStr += "<" + cascade[:type].to_s + " "
      attributes = cascade[:settings]
      if attributes.keys != nil
          attributes.keys.each do |key|
          attr_val = attributes[key].to_s
          attr_val.gsub!("'","")
          attr_val.gsub!("\"","")
            returnStr += key.to_s + "='" + attr_val.to_s + "' "
          end
      end
       returnStr = returnStr.strip! + "/>"
    end
   elsif(cascades.kind_of?(Hash))
    returnStr += "<" + cascades[:type].to_s + " "
      attributes = cascades[:settings]
      if attributes.keys != nil
          attributes.keys.each do |key|
          attr_val = attributes[key].to_s
          attr_val.gsub!("'","")
          attr_val.gsub!("\"","")
            returnStr += key.to_s + "='" + attr_val.to_s + "' "
          end
      end
       returnStr = returnStr.strip! + "/>"
   end
   returnStr += "</cascades>"
   return returnStr
 end

end
