module MesScada

  # Actions to mix in to ApplicationController
  module FormComponents

  class FormField

    # Ensure the image name contains a file extension.
    def image_with_ext(image_name)
      image_name.include?('.') ? image_name : "#{image_name}.png"
    end

    def initialize (form, active_record, field_name, field_type, active_record_var_name, settings, non_db_field = false, observer = nil, environment = nil)

      if field_name.index("?required")
        field_name = field_name.slice(0, field_name.index("?required"))
        @required_field = true
      end

      if form
        form.is_popup = nil if !form.is_popup
      end

      @is_separator = false
      @form = form
      @css_class = nil
      if @form
        @env = form.env
      elsif environment
        @env = environment
      end
      @active_record = active_record
      @observer = observer
      @form.trace += "\n inside form field base contructor (field type is: " + field_type + ", field name is: " + field_name + ")" if @form
      #validate
      empty_var = nil

      if field_name == nil
        empty_var = "field_name"
      end
      if field_type == nil
        empty_var = "field_type"
      end

      if active_record_var_name == nil
        empty_var = "active_record_var_name"
      end

      raise "The form field constructor requires parameter: " + empty_var + " , which is empty." if empty_var != nil

      @non_db_field = non_db_field
      @field_name = field_name

      @field_type = field_type
      @active_record_var_name = active_record_var_name


      @settings = settings
      if @settings != nil
        @label_css = @settings[:label_css_class]
        if @settings[:label_caption]!= nil
          @label_caption = @settings[:label_caption]
        end
        if @settings[:css_class]!= nil
          @css_class = @settings[:css_class]
        end
      end

      @ouput_html = nil

      @form.trace += "\n checking for attribute with fieldname as key" if @form

      #make sure the field exist in the active record instance

      if  non_db_field == false && related_field == nil #indicates whether this field belongs to a related table
        if not active_record.attributes.has_key?(field_name)
          @form.trace += "\n matching attribute not found" if @form
          raise_error("The active record instance does not contain a field with name: " + field_name, "constructor")
        end
      end

      @form.trace += "\n exiting form field base contructor" if @form

    end

    def raise_error(message, method)
      @form.trace += "\n 'raise' method entered"
      err = message + "\n . class is: " + self.class.to_s + ". method is: " + method + ". field is: " + @field_name + ". field type is: " + @field_type
      @form.trace += "\n 'raise' method exited"
      raise err
    end

    def construct

      # begin
        observer = ""
        css_class = ""
        user_css = nil
        if @form.plugin != nil
          user_css = @form.plugin.get_cell_css_class(@field_name, @form.active_record)
        end
        @css_class =  user_css if user_css != nil
        css_class = " class = '" + @css_class + "'" if @css_class != nil
        loading_gif = ""
        if @observer != nil
          # observer = @env.observe_field(@active_record_var_name + "_" + @field_name,
          #                               :update => @observer[:updated_field_id],
          #                               :url => {:action => @observer[:remote_method]}, :complete => @observer[:on_completed_js], :loading => "show_element('img_" + @active_record_var_name + "_" + @field_name + "');")
          observer = @env.observe_field(@active_record_var_name + "_" + @field_name,
                                        :update   => @observer[:updated_field_id],
                                        :url      => {:action => @observer[:remote_method]},
                                        :complete => @observer[:on_completed_js],
                                        :with     => "encodeURIComponent(value)+'=x'",
                                        :loading  => "show_element('img_" + @active_record_var_name + "_" + @field_name + "');")
        end
        if observer != ""
          loading_gif =  "<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_" + @active_record_var_name + "_" + @field_name + "'/>"
        end

        if @is_separator

          sep_id = @form.next_separator_id
          @output_html = "<td onclick = 'hide_separator(this);' " + css_class + " id = '" + sep_id + "'>" + construct_control + "<img id = '" + sep_id + "_img' src = '/images/expanded.png' </img></td>"

        else
          width = ""
          if self.class.to_s.index("Screen")
              w = "'900px'"
              #h = nil #"'300px'"
              h = "'300px'"
              w =  "'" + @settings[:width].to_s + "px'" if @settings[:width]
              h =  "'" + @settings[:height].to_s + "px'" if @settings[:height]

              width = " width = #{w} height = #{h}"
              #width = " width = #{w} #{h.nil? ? '' : "height = #{h}"}"
          end
          @output_html = "<td " + css_class + " valign=\"top\" id = '" + @field_name + "_cell'"  " #{width}>" + construct_control + loading_gif + observer + "</td>"
        end
      # rescue
      #   raise_error "The control could not be rendered correctly. \n  The exception reported is: " + $!, "build_control"
      # end

      #------------------------------------------------------------------
      #Layout for fields:
      #-> default layout is to have every field in it's own row
      #-> other layouts specifies(via 'cells_inrow?') method
      #   how many fields should be placed next to each other in a row
      #-------------------------------------------------------------------
      open_tag = ""
      closing_tag = ""

      if @form.cells_in_row?

        if is_new_row?(@form.cells_in_row?, @form.current_field_index?)
          open_tag = "<tr>"
          closing_tag = ""
        elsif is_last_cell?(@form.cells_in_row?, @form.current_field_index?)
          closing_tag = "</tr>"
          if @form.end_at_position == @form.current_field_index?
            closing_tag += "</table><table>"
            #apply second layout if provided, else: reset layout
            if !@env.second_layout
              @env.set_form_layout("1", false, @form.current_field_index?, @form.field_configs.length() -1)
            else
              controls_per_column = "1"
              controls_per_column = @env.second_layout[:controls_per_column] if @env.second_layout[:controls_per_column]
              hide_labels = false
              hide_labels = @env.second_layout[:hide_labels] if @env.second_layout[:hide_labels]

              end_at_position = @form.field_configs.length() -1
              end_at_position = @env.second_layout[:end_at_position] if @env.second_layout[:end_at_position]
              @env.set_form_layout(controls_per_column, hide_labels, @form.current_field_index?, end_at_position)


            end
            @form.reset_layout
          end
        end
      else
        open_tag = "<tr>"
        closing_tag = "</tr>"
      end


      open_tag + build_label + @output_html + closing_tag

    end

    def is_new_row?(cells_per_row, curr_index)
      iteration = (curr_index/cells_per_row).round
      local_index = curr_index - (iteration * cells_per_row)
      return local_index == 1
    end

    def is_last_cell?(cells_per_row, curr_index)
      iteration = (curr_index/cells_per_row).round
      local_index = curr_index - (iteration * cells_per_row)
      return local_index == 0
    end

    def build_label
      if @form.hide_labels?
        return ""
      end

      if @settings && @settings[:hide_label]
        return ""
      end

      label_css = ""

      if @field_type != "HiddenField"
        if @required_field
          label_css = "required_field"
          label_css = @label_css if @label_css
          if !@label_caption
            "<td class = '#{label_css}'>#{@field_name.gsub('_', ' ').sub(/ id$/, '')}</td>"
          else
            "<td class = '#{label_css}'>#{@label_caption.to_s}</td>"
          end
        else
          label_css = ""
          label_css = " class = '#{@label_css}' " if @label_css
          if !@label_caption
            "<td #{label_css}>#{@field_name.gsub('_', ' ').sub(/ id$/, '')}</td>"
          else
            "<td #{label_css}>#{@label_caption.to_s}</td>"
          end
        end
      else
        ""
      end
    end


    #==========================================================================================
    #This method determines who should build the control? A plugin,if registered,or the control
    #If a plugin is registered and answers 'true' to 'override_build?' method and if the
    # build_control method doesn't return nil, the control's
    #===================================================================================
    def construct_control
      override = false
      plugin_val = nil
      if @form.plugin != nil
        if @form.plugin.override_build?
          override = true
          plugin_val = @form.plugin.build_control(@field_name, @form.active_record, self)
          if !plugin_val
            override = false
          end
        end
      end

      if override == false
        build_control
      else
        return plugin_val
      end

    end

    def build_control


    end


  end

  class TextField < FormField

    def self.build_look_up_url_configs(env,lookup_configs)
      submit_to = ""
      if(lookup_configs.has_key?(:submit_to) && lookup_configs[:submit_to])
        submit_to = "&submit_to=#{lookup_configs[:submit_to]}"
      end

      active_record_var_name = ""
      if(lookup_configs[:active_record_var_name])
       active_record_var_name = "&active_record_var_name=#{lookup_configs[:active_record_var_name]}"
      end

      if(lookup_configs.has_key?(:lookup_search_uri) && lookup_configs[:lookup_search_uri])
        if(lookup_configs[:send_fields])
          if(lookup_configs[:active_record_var_name])
            send_fields = lookup_configs[:send_fields].split(',').map{|send_field| lookup_configs[:active_record_var_name] + "_" + send_field}.join(',')
          else
            send_fields = lookup_configs[:send_fields].split(',').map{|send_field| "parameter_field_" + send_field}.join(',')
          end
          return {:url=>"/#{lookup_configs[:lookup_search_uri]}?#{submit_to}&looked_up_field=#{lookup_configs[:field_name]}#{active_record_var_name}",:send_fields=>send_fields}
        else
          return {:url=>"/#{lookup_configs[:lookup_search_uri]}?#{submit_to}&looked_up_field=#{lookup_configs[:field_name]}#{active_record_var_name}"}
        end
      end

      #=====================
      #=====================
      default_values = ""
      if(lookup_configs[:lookup_search_file] && lookup_configs[:default_values])
        default_values = lookup_configs[:default_values].map{|key,value| "default_val_" + key.to_s + "=" + value.to_s + "&"}.to_s
      end
      #=====================
      #=====================

      if(lookup_configs[:send_fields])
        if(lookup_configs[:active_record_var_name])
          send_fields = lookup_configs[:send_fields].split(',').map{|send_field| lookup_configs[:active_record_var_name] + "_" + send_field}.join(',')
        else
          send_fields = lookup_configs[:send_fields].split(',').map{|send_field| "parameter_field_" + send_field}.join(',')
        end
        return {:url=>"/reports/reports/launch_lookup_form?lookup_search_file=#{lookup_configs[:lookup_search_file].to_s}#{submit_to}&#{default_values}select_column_name=#{lookup_configs[:select_column_name].to_s}#{active_record_var_name}&looked_up_field=#{lookup_configs[:field_name]}",:send_fields=>send_fields}
      else
        return {:url=>"/reports/reports/launch_lookup_form?lookup_search_file=#{lookup_configs[:lookup_search_file].to_s}#{submit_to}&#{default_values}select_column_name=#{lookup_configs[:select_column_name].to_s}#{active_record_var_name}&looked_up_field=#{lookup_configs[:field_name]}"}
      end
    end

    def self.build_look_up_link(env,lookup_configs)
      host_and_port = env.request.host + ":" + env.request.port.to_s
      url_configs = build_look_up_url_configs(env,lookup_configs)
      if(url_configs[:send_fields])
        return " <div title='lookup' style='background-image: url(/images/tlo_podmenu.gif); display: inline-table;border: #a9a9a9 solid 1px;margin-top: 3px;margin-left: -8px;'><a style='cursor:pointer;' id='#{host_and_port}#{url_configs[:url]}' onclick='javascript:send_fields_to_popup_window(this,\"#{url_configs[:send_fields]}\");' ><img alt='lookup' src='/images/lookup.png' HEIGHT=\"16\" WIDTH=\"20\" /></a></div>"
      else
        return " <div title='lookup' style='background-image: url(/images/tlo_podmenu.gif); display: inline-table;border: #a9a9a9 solid 1px;margin-top: 3px;margin-left: -8px;'><a style='cursor:pointer;' id='#{host_and_port}#{url_configs[:url]}' onclick='javascript:parent.call_open_window(this);' ><img alt='lookup' src='/images/lookup.png' HEIGHT=\"16\" WIDTH=\"20\" /></a> </div>"
      end

    end


    def build_control

      lookup_link = ""
      if(@settings && @settings[:lookup])
        if(@settings[:lookup_search_uri])
          lookup_link += TextField.build_look_up_link(@env,{:lookup_search_uri=>@settings[:lookup_search_uri],:default_values=>@settings[:default_values],:send_fields=>@settings[:send_fields],:active_record_var_name=>@active_record_var_name,:submit_to=>@settings[:submit_to]})
        elsif(@settings[:lookup_search_file] && @settings[:select_column_name])
          lookup_link += TextField.build_look_up_link(@env,{:lookup_search_file=>@settings[:lookup_search_file],:default_values=>@settings[:default_values],:send_fields=>@settings[:send_fields],:select_column_name=>@settings[:select_column_name],:field_name=>@active_record_var_name + "_" + @field_name,:active_record_var_name=>@active_record_var_name,:submit_to=>@settings[:submit_to]})
        end
      end

      html_opts = {}
      html_opts.merge!(@settings[:html_opts]) if @settings && @settings[:html_opts]
      html_opts[:size]     = @settings[:size] if @settings && @settings[:size]
      html_opts[:readonly] = 'readonly'       if @settings && @settings[:readonly]
      @env.text_field(@active_record_var_name, @field_name, html_opts) + lookup_link
      # if @settings && @settings[:size]
      #   @env.text_field(@active_record_var_name, @field_name, "size" => @settings[:size]) + lookup_link
      # else
      #   @env.text_field(@active_record_var_name, @field_name) + lookup_link
      # end

    end

  end

  class CheckBox < FormField


    def build_control

      @env.check_box(@active_record_var_name, @field_name)
    end

  end

  class LinkField < FormField

    def build_control

      if @settings[:link_text]== nil
        @settings[:dynamic_link_text] = true
      end

      link_text = nil
      cell = ''
      #--------------------------------------------------------------------------------------------
      #Build an image tage (instead of 'link_text') if an image was provided with 'settings[:image]
      #--------------------------------------------------------------------------------------------
      if @settings[:image]
        link_text = @env.image_tag(image_with_ext(@settings[:image]), :border => 0)
      elsif @settings[:dynamic_link_text] == nil
        link_text = @settings[:link_text]
      else
        link_text = @active_record.attributes[@field_name].to_s
      end

      css_class = "action_link"
      css_class << " popupjs" if @settings[:dialog_popup]

      if @form.plugin
        user_css_class = @form.plugin.get_field_css_class(@field_name, @active_record)
        css_class = user_css_class if user_css_class
      end

      if @settings[:id_column]||@settings[:id_value]
        if @settings[:id_column]
          id_val = eval "@active_record." + @settings[:id_column]
        elsif @settings[:id_value]
          id_val = @settings[:id_value]
        end
      end
      controller =  @env.request.path_parameters['controller'].to_s
      controller = @settings[:controller] if @settings[:controller]

      if @settings[:dialog_popup]
        if @settings && @settings[:prompt]
          # To cancel a dialog popup we need to set a value for the listener to check. A simple "return false" will not work.
          onclick = "if(confirm(\"" + @settings[:prompt] + "\")) {jQuery(this).data(\"checks\", {doPopup: true});} else {jQuery(this).data(\"checks\", {doPopup: false});}"
        else
          onclick = ''
        end
      else
        onclick = "show_action_image(this);"

        if @settings && @settings[:prompt]
          onclick = "if(!confirm(\"" + @settings[:prompt] + "\"))return false; else {show_action_image(this);}"
        end
      end

      html_opts = {:class => css_class, :onclick => onclick}
      html_opts.merge!(@settings[:html_options]) if @settings[:html_options]

      if id_val
        cell = @env.link_to(link_text, {:controller => controller, :action => @settings[:target_action], :id => id_val}, html_opts)
      else
        cell = @env.link_to(link_text, {:controller => controller, :action => @settings[:target_action]}, html_opts)
      end


      cell += @env.image_tag('loading.gif', :id => 'form_link_loading_img', :align => 'absmiddle', :border=> 0, :style=>'visibility: hidden')
      cell.gsub! "\"", "'"

      return cell
    end

  end

  # Henry PopupDateRangeSelector
  # Example:
  #         field_configs[field_configs.length()] = {:field_type =>'PopupDateRangeSelector',
  #         :field_name =>'transaction_date'}
  #
  class PopupDateRangeSelector < FormField
    def build_control

      initialdate = "";

      %Q|<label class='date_range_from'>From:</label>
         <input id="#{@field_name}_date2from" size="20" name="#{@active_record_var_name}[#{@field_name}_date2from]" value="#{initialdate}" class="datepicker_from" />
        </br><label class='date_range_to'>To:</label>
         <input id="#{@field_name}_date2to" size="20" name="#{@active_record_var_name}[#{@field_name}_date2to]" value="#{initialdate}" class="datepicker_to" /> |

    end
  end

  # PopupDateSelector
  class PopupDateSelector < FormField
    def build_control

      @settings ||= {}
      @settings[:date_textfield_id] = @field_name if !@settings[:date_textfield_id]

      initialdate = "";
      initialdate = @active_record.send(@field_name) unless @active_record.nil?
      initialdate = initialdate.strftime("%Y-%m-%d") if (initialdate.to_s.length > 0)

      %Q|<input id="#{@settings[:date_textfield_id]}" size="20" name="#{@active_record_var_name}[#{@settings[:date_textfield_id]}]" value="#{initialdate}" class="datepicker" />|
    end
  end

  class PopupDateTimeSelector < FormField
    def build_control

      @settings ||= {}
      @settings[:date_textfield_id] = @field_name if !@settings[:date_textfield_id]

      initialdate = "";
      initialdate = @active_record.send(@field_name) unless @active_record.nil?
      #initialdate = initialdate.strftime("%Y-%m-%d %H:%M:%S") if (initialdate.to_s.length > 0)
      initialdate = initialdate.strftime("%Y-%m-%d %H:%M:%S") if (initialdate.to_s.length > 0)

      %Q|<input id="#{@settings[:date_textfield_id]}" size="20" name="#{@active_record_var_name}[#{@settings[:date_textfield_id]}]" value="#{initialdate}" class="datetimepicker" />|
    end
  end


  class PopupLink < FormField

    def build_control

      if @settings[:link_text]== nil
        @settings[:dynamic_link_text] = true
      end

      link_text = nil
      cell = ''
      #--------------------------------------------------------------------------------------------
      #Build an image tage (instead of 'link_text') if an image was provided with 'settings[:image]
      #--------------------------------------------------------------------------------------------
      if @settings[:image]
        link_text = @env.image_tag(image_with_ext(@settings[:image]), :border => 0)
      elsif @settings[:dynamic_link_text] == nil
        link_text = @settings[:link_text]
      else
        link_text = @active_record.attributes[@field_name].to_s
      end

      css_class = "action_link"
      css_class = @settings[:css_class] if @settings[:link_text]

      if @form && @form.plugin
        user_css_class = @form.plugin.get_field_css_class(@field_name, @active_record)
        css_class = user_css_class if user_css_class
      end

      css_code ="class ='" + css_class + "' "
      css_code = "" if @settings[:css_class] == "none"

      cell = "<a " + css_code + " href = \"javascript:show_context_menu('" + @settings[:menu_name] + "!" + @settings[:link_value] + "');\" >" + link_text + "</a>"
      puts cell

      #cell.gsub! "\"","'"

      return cell
    end

  end

   class StaticField < FormField

    attr_accessor :is_separator

    def initialize (form, active_record, field_name, field_type, active_record_var_name, settings, non_db_field, observer)
      super(form, active_record, field_name, field_type, active_record_var_name, settings, non_db_field, observer)

      @css_class = "label_field" if !@css_class && ((settings!= nil && settings[:static_value] == nil)||settings== nil)

      if @settings && @settings[:static_value]
        if settings[:is_separator]
          @is_separator = true
        end
        @static_value = settings[:static_value]
        @show_label = settings[:show_label]
        @css_class = "heading_field" if !@css_class
      end

      # Replacement setting must be in the form of an array of from and to strings.
      # e.g. ["\n", '<br />'] - to change newlines to HTML linebreaks.
      if @settings && @settings[:replace] && @settings[:replace].kind_of?( Array )
        @replace = @settings[:replace]
      end
    end

    def build_label

      if @static_value && !@show_label
        "<td/>"
      else
        super
      end

    end

    def build_control
      value = ""
      if @static_value
        value = @static_value.to_s
      elsif @form.active_record
        value = eval("@form.active_record." + @field_name + ".to_s")
      end

      # Use the settings[:replace] array values to do a gsub.
      value.gsub!(*@replace) if @replace

      return value
    end

   end

  class TextArea < FormField
    #Settings: cols and rows - add defaults
    @cols = 1
    @rows = 5

    #override base class constructor
    def initialize (env, active_record, field_name, field_type, active_record_var_name, settings, non_db_field, observer)
      super(env, active_record, field_name, field_type, active_record_var_name, settings, non_db_field, observer)

      if @settings != nil
        if settings[:cols]!= nil
          @cols = settings[:cols]
        end
        if settings[:rows]!= nil
          @rows = settings[:rows]
        end
      end

    end


    def build_control

      @env.text_area(@active_record_var_name, @field_name, {:cols => @cols, :rows => @rows})
    end


  end

  class HiddenField < FormField

    def build_control
      if @settings != nil

        if @settings[:hidden_field_data]!= nil
          options = {:value => @settings[:hidden_field_data]}
          if @non_db_field
            @env.hidden_field(nil, @field_name, options)
          else
            @env.hidden_field(@active_record_var_name, @field_name, options)
          end
        end
      else
        if @non_db_field
          @env.hidden_field(nil, @field_name)
        else
          @env.hidden_field(@active_record_var_name, @field_name)
        end
      end
    end


  end

  class PasswordField < FormField

    def build_control

      @env.password_field(@active_record_var_name, @field_name)
    end


  end

  class DateField < FormField

    def build_control

      @env.date_select(@active_record_var_name, @field_name)
    end


  end

  class DateTimeField < FormField

    def build_control

      @env.datetime_select(@active_record_var_name, @field_name)
    end


  end

  class DropDownField < FormField
    #setings: list
    #The attribute passed into the select method must be the same as the field
    #of the model object that needs to be set from the user's selected value

    #override base costructor
    def initialize (env, active_record, field_name, field_type, active_record_var_name, settings, non_db_field, observer)
      super(env, active_record, field_name, field_type, active_record_var_name, settings, non_db_field, observer)

      @form.trace += "\n entering 'DropDownField' contructor"

      err = nil
      if settings == nil
        err = "settings is empty"
      elsif settings[:list]== nil
        err = "settings must include a list for the 'list' key"
      elsif settings[:list].length <= 0
        #err = "the 'list' has no values"
      end

      raise_error(err, "initialize") if err != nil
      @form.trace += "\n exiting 'DropDownField' contructor"

    end

    def build_control(re_attempt = nil)
      @form.trace += "\n entering 'DropDownField' 'build_control' method"

      @settings[:list].delete_if { |e| e =="<empty>" } if  @settings[:list].class.to_s == "Array"

      #sort the list before binding

      if @settings[:list].class.to_s == "Array" ||@settings[:list].class.to_s == "Hash"
        @settings[:list].sort! do |x, y|
          if x.class.to_s == "Array" && y.class.to_s == "Array"
            x[0] && y[0] ? x[0] <=> y[0] : 0    # Sort on 1st element of array.
          elsif x.class.to_s == "String" && y.class.to_s == "String"
            if (x.to_i > 0 && y.to_i > 0)
              x.to_i <=> y.to_i                 # Sort integers
            else
              x <=> y                           # Sort strings
            end
          else
            0                                   # Sort as if x & y are equal
          end
        end
      end

      opt = {:sorted => true}
      html_opts = {}
      html_opts.merge!(@settings[:html_opts]) if @settings && @settings[:html_opts]
      # If setting no_empty is not set, prompt with <empty> or with the prompt provided in settings.
      if @settings[:is_clearable] # Display an empty selection for an edit record.
        # --------------------------------------------------------------------------------------------------------
        # NB currently this does not work as expected - Rails provides a blank prompt, ignoring the prompt string.
        # --------------------------------------------------------------------------------------------------------
        opt[:include_blank] = @settings[:prompt] || '&lt;empty&gt;' unless @settings[:no_empty]
      else
        opt[:prompt] = @settings[:prompt] || '&lt;empty&gt;' unless @settings[:no_empty]
      end

      @env.select(@active_record_var_name, @field_name, @settings[:list], opt, html_opts)

    rescue
      if $!.to_s === "cannot convert nil into String"
        puts " in clear list"
        #--------------------------------------------
        #We have a null value in the list, find and
        #replace the null value with an empty string
        #and re-attempt to build the list
        #--------------------------------------------
        if !re_attempt
          @settings[:list].delete_if { |a| a[0] == nil } if  @settings[:list].class.to_s == "Array"
          build_control true
        end
      else
        raise $!
      end
    end

  end

  class LinkWindowField < FormField


    def build_control

      @settings[:link_type] = "popup" if !@settings[:link_type]
      link_text = get_link_text
      target = get_target

      controller = get_controller

      host = get_host

      window_size = get_window_size


      extra_styling = "#{@settings[:extra_styling]}" if(@settings[:extra_styling])
      link = case @settings[:link_type]
        when nil, "popup"
          # puts "THIS IS FROM LINKFIELD"
          @form.is_popup = true if @form
          #"<a   style='text-decoration:underline;cursor:pointer;padding-bottom:200px' id='"+ host+"/"+controller+"/"+target+"" "' onclick='javascript:parent.call_open_window(this);' >"+link_text+"</a>"
          "<a style='#{extra_styling}text-decoration:underline;cursor:pointer;padding-bottom:2px' id='"+ host+"/"+controller+"/" + target+ window_size + "' onclick='javascript:parent.call_open_window(this);' >"+link_text+"</a>"
        when "iframe"

          val = "<label style='text-decoration: underline;cursor:pointer;' onclick='javascript:top.setFrameSource(&#39;"+ @settings[:frame_id].to_s+"&#39;,&#39;"+host+"/"+controller+"/"+target+"/"+@id.to_s+"&#39;);' >"+link_text+"</label>"
          puts "FRAME: " + val
          return val
        when "child_form"
          @form.is_popup = true if @form
          "<a style='text-decoration:underline;cursor:pointer;padding-bottom: 2px;padding-left: 2px;' id='"+ host+"/"+controller+"/"+target+ window_size + "' onclick='javascript:parent.call_open_window(this);' >"+link_text+"</a>"
        else
          raise "unknown link_type: " + @settings[:link_type]
      end

      return link

    end

    # Return just the javascript action to be called.
    def link_only
      @settings[:link_type] = "popup" if @settings[:link_type].nil?
      target                = get_target
      controller            = get_controller
      host                  = get_host
      window_size           = get_window_size

      case @settings[:link_type]
      when nil, "popup"
        "open_window_link('#{host}/#{controller}/#{target}#{window_size}')"
      when "iframe"
        "top.setFrameSource('&#39;#{@settings[:frame_id].to_s}&#39;,&#39;#{host}/#{controller}/#{target}/#{@id.to_s}&#39')"
      when "child_form"
        "open_window_link('#{host}/#{controller}/#{target}#{window_size}')"
      else
        raise "unknown link_type: #{@settings[:link_type]}"
      end
    end


    def get_target

      target =  @settings[:target_action].to_s
      if       @settings[:id_column]
        @id =   @active_record.attributes[@settings[:id_column]].to_s
        if @id == nil||@id.strip.to_s == ""
          raise "id is null for specified id column: " + @settings[:id_column]
        end
        target += "%" + @id
      elsif @settings[:id_value]
        target += "%" + @settings[:id_value].to_s
      end

      return target
    end


    def get_controller
      if (@settings[:controller] == nil)
        if (@env.request.path_parameters['controller'])
          controller =    @env.request.path_parameters['controller'].to_s
        else
          controller = @settings[:controller]
        end
      else
        controller =   @settings[:controller].to_s
      end
      return controller
    end


    def get_host
      if (@settings[:host_and_port] == nil)
        host_with_port = @env.request.host_with_port
      else
        host_with_port = @settings[:host_and_port]
      end
    end


    def get_link_text
      if !@settings[:link_text]== nil && !@settings[:image]
        link_text = @active_record.attributes[@field_name].to_s #dynamic link text
      elsif (@settings[:link_text])
        link_text = @settings[:link_text].to_s
      elsif @settings[:image]
        link_text = @env.image_tag(image_with_ext(@settings[:image]), :border => 0)
      end

    end


    def get_window_size
      window_size = "!"
      if (@settings[:window_width] != nil)
        window_size +=@settings[:window_width].to_s
      else
        window_size +=""+"1024"
      end

      if (@settings[:window_height] != nil)
        window_size +=":"+@settings[:window_height].to_s
      else
        window_size +=":"+"500"
      end
    end



  end

  class Screen < FormField

    def build_label
      ""
    end

       def build_control
      @form.trace += "\n constructing child form"
      if @settings != nil
        @settings[:request] = @form.env.request if !@settings[:request]

        if  @settings[:request]

          @settings[:request] = request = @settings[:request]

          host_with_port = request.host_with_port
          host_with_port = @settings[:host_with_port] if @settings[:host_with_port]
          url =  host_with_port

          if @settings[:controller]
            url += "/" + @settings[:controller] + "/"
            new_url = url
          else
            url += request.path

            url_components = url.split('/')
            #if request has param[:id] remove it
            url_components.pop if request.request_parameters['id'] != nil #to remove the :id
            url_components.pop #to remove the method
            new_url = ""
            for url_component in url_components
              new_url += url_component + "/"
            end
          end


          if @settings[:target_action]
            child_form_target_url = 'http://' + new_url + @settings[:target_action]

            if @settings[:id_value] != nil
              child_form_target_url += "/" + @settings[:id_value].to_s
            end
          else
            child_form_target_url = nil
          end


          child_form_style = "style='"
          @output_html = "<div id='" + @field_name.to_s + "' "

          if @settings[:show_content_header_caption_order] == nil || @settings[:show_content_header_caption_order]
            @output_html += " class='child_form_header_caption' "
          end
          @output_html += "></div><div class = 'ChildPanel' id='child_panel_#{@field_name}'><iframe "

          if @settings[:css_class]
            @output_html += "class='" + @settings[:css_class] + "' "
          else
            @output_html += "class='child_form' "
          end




          @output_html << "id ='" + @field_name.to_s + "_iframe' name = '" << @field_name.to_s + "_iframe' " << "  width = '100%' height = '100%' frameborder=\"#{@settings[:border].to_s }\" "
          if child_form_target_url
            @output_html += "src='" + child_form_target_url + "' "
          end



          child_form_style += ""
           if @settings[:no_scroll]
           child_form_style += "overflow: auto; overflow-x:hidden;"
           end
          @output_html += child_form_style + "'></iframe></div>"
          #puts "OUTPUT = " + child_form_target_url if child_form_target_url
#          puts "OUTPUT = " + @output_html

          @form.trace += "\n constructing child form 4"
        end

      end

      height = @settings[:height] ? @settings[:height] : '300px'



      script =
          %{


          <script>

          jQuery(function() {
            jQuery('#child_panel_#{@field_name}').css('height', '#{height}');
            jQuery( ".ChildPanel" ).resizable({
              animate: true, animateEasing: 'swing', animateDuration: 500
            });
          });
          </script>}


      return @output_html  + script
    end

  end

  end
end
