# Methods added to this helper will be available to all templates in the application.
require "lib/globals.rb"

module ApplicationHelper
  include MesScada::FormComponents

  #@@crystal_report_url = "http://luxolo:8080/CrystalReportsServer/index.jsp?"
  @@crystal_report_url = Globals.get_crystal_reports_server_ip + ":" + Globals.get_crystal_reports_server_port.to_s + Globals.get_crystal_reports_server

  def authorise(program, permission, user)
    begin
      user = User.find_by_user_name(user) if user.class.to_s == "String"

      query = "SELECT
               public.security_permissions.id
               FROM
               public.security_groups_security_permissions
               INNER JOIN public.security_groups ON (public.security_groups_security_permissions.security_group_id = public.security_groups.id)
                INNER JOIN public.security_permissions ON (public.security_groups_security_permissions.security_permission_id = public.security_permissions.id)
                INNER JOIN public.program_users ON (public.security_groups.id = public.program_users.security_group_id)
                INNER JOIN public.programs ON (public.program_users.program_id = public.programs.id)
                WHERE
                (public.program_users.user_id = #{user.id}) AND
                (public.security_permissions.security_permission = '#{permission}') AND
                (public.programs.program_name = '#{program}')"

      @val  = User.connection.select_one(query)

      return @val != nil
    rescue

      return false
    end
  end
  #  if !Globals.enable_logging
  #    def puts(val)
  #    end
  #
  #  end


  #   MY_PAGINATION_OPTIONS = {
  #         :name => :page,
  #         :window_size => 2,
  #         :always_show_anchors => true,
  #         :link_to_current_page => false,
  #         :params => {}
  # }
    # Replace a combo's observer after the combo has been recreated.

def refresh_combo_observer(observed_field, update_cell, action)
  s = image_tag('spinner.gif', :style => 'display:none;', :id => "img_#{observed_field}")
  s << observe_field(observed_field,
      :update   => update_cell,
      :url      => {:action => action },
      :loading  => "show_element('img_#{observed_field}');",
      :complete => "Element.hide('img_#{observed_field}');")
 puts "REFRESH COMBO" + s
  s
end

  def refresh_combo_observer_no_img(observed_field, update_cell, action)
  s = observe_field(observed_field,
      :update   => update_cell,
      :url      => {:action => action }
     )


 puts "REFRESH COMBO" + s
  s

end

  def dm_session
    session[:dm_lookup_session] = {} if !session[:dm_lookup_session]

    if(!session[:dm_lookup_instance])
      session[:dataminer] = {} if !session[:dataminer]
      return session[:dataminer]
    else
      return session[:dm_lookup_session]
    end
  end

  def pagination_links(paginator, options={}, html_options={})
    name = options[:name] || ApplicationController::MY_PAGINATION_OPTIONS[:name]
    params = (options[:params] || ApplicationController::MY_PAGINATION_OPTIONS[:params]).clone
    params[:action] =@pagination_server if @pagination_server

    html_options[:style] ||= ''
    html_options[:style] << 'text-decoration:underline;font-size:inherit;'
    pagination_links_each(paginator, options) do |n|
      params[name] = n
      link_to(n.to_s, params, html_options)
    end
  end


  def build_view_mode_form(field_configs)
    ###field_configs
    new_configs=Array.new
    for config in field_configs
      if config[:field_type]=="LabelField"
        new_configs << config
      end
      if config[:field_type]=="TextArea"
         config[:field_type]="LabelField"
        new_configs << config
      end
      if config[:field_type]=="PopupDateSelector"
         config[:field_type]="LabelField"
        new_configs << config
      end
      if config[:field_type]=="TextField"
         config[:field_type]="LabelField"
        new_configs << config
      end
    if config[:field_type]=="LinkWindowField"
        new_configs << config
      end
     if config[:field_type]=="CheckBox"
         config[:field_type]="LabelField"
        new_configs << config
     end
      if config[:field_type]=="LinkField"
        new_configs << config
      end
      if config[:field_type]=="Screen"
        new_configs << config
      end
      if config[:field_type]=="DropDownField"
        config[:field_type]="LabelField"
        new_configs << config
      end

    end
    return new_configs
  end

  def refresh_window(levels_down, frame_id, message = nil, close_popup = nil)
    if !message
      message = "null"
    else
      message = "'" + message + "'"
    end

    if !close_popup
      close_popup = "null"
    else
      close_popup = "'" + close_popup.to_s + "'"
    end

    js =  " <script>refresh_window(#{levels_down},'#{frame_id}',#{message},#{close_popup});</script>"
    return js
  end

  def is_popup
    # puts "IS POPUP VAL: " + session[:is_popup].to_s
    return session[:is_popup]
  end

  def is_popup=(val)
    # puts "SETTING IS_POPUP TO: " + val.to_s
    session[:is_popup] = val
  end


  def periodically_call_remote(options = {})
    variable = options[:variable] ||= 'poller'
    frequency = options[:frequency] ||= 10
    code = "#{variable} = new PeriodicalExecuter(function()
  {#{remote_function(options)}}, #{frequency})"
    javascript_tag(code)
  end


  def se_grid_type
    if @se_grid
      return 'se_grid'
    elsif @se_summary_details_grid
      return 'se_summary_details_grid'
    else
      return nil
    end

  end

  def domain

    Globals.get_domain.to_s
  end

  def cancel_action

    @cancel_action
  end


  #
  #  Henry hidden_id_column
  #
  def hidden_id_column
    return @hidden_id_column
  end

  def hidden_id_column=(val)
    @hidden_id_column = val

  end

  # end hidden_id_column
  def multi_select
    return @multi_select
  end

  # For multiselect grids, set @grid_selected_rows to an array of models and
  # rows with matching ids will be pre-selected in the grid.
  def grid_selected_rows
    return @grid_selected_rows
  end

  def multi_select=(val)
    @multi_select = val

  end

  def submit_button_align
    @submit_button_align
  end

  def set_submit_button_align(val)
    @submit_button_align = val
  end


  def set_form_layout(controls_per_column = nil, hide_labels = nil, start_from_position = nil, end_at_position = nil, second_layout = nil)
    @layout = controls_per_column
    @second_layout = second_layout

    @hide_labels = hide_labels
    @start_from_position = 0
    @start_from_position = start_from_position - 1 if start_from_position
    @end_at_position = end_at_position
  end

  def second_layout
    @second_layout
  end


  def hide_labels?
    @hide_labels
  end

  def end_at_position
    @end_at_position
  end

  def start_from_position?
    val = @start_from_position
    val = 0 if !@start_from_position
    return val
  end

  def form_layout
    @layout
  end

  def form_layout=(value)
    @layout = value
  end

  #   def msg_url
  #    "\"" + domain + "login/messages\""
  #
  #  end

  def login_url
    "\"" + domain + "login/login\""
  end

  def logout_url
    "\"" + domain + "login/logout\""
  end

  def login_url_single_quote
    "\'" + domain + "login/login\'"

  end

  def logout_url_single_quote
    "\'" + domain + "login/logout\'"

  end


  def  set_grid_min_width(val)
    @grid_min_width = val.to_s
  end

  def grid_min_width
    if @grid_min_width
      @grid_min_width
    else
      "780"
    end
  end

  def set_grid_min_height(val)
     @grid_min_height = val.to_s
  end

  def grid_min_height
    if @grid_min_height
      @grid_min_height
    else
      "350"
    end
  end

  def hide_grid_client_controls
    warn "[DEPRECATION] 'hide_grid_client_controls' is deprecated. It does not need to be called at all."
  end

  #-----------------------------------------------------------------------------------------------------------------
  #description: This helper method builds a form from a set of configuration parameters. It's purpose
  #             is productivity: it allows you to build an active record data form, without writing any html
  #input variables:
  #   active_record: the active record instance for which this form is build
  #   field_configs:	the list of field configuration maps (one for each field) for the form. Keys for each map are:
  #               key: 'field_type'
  #				values: 'TextField','TextArea','HiddenField','PasswordField','DateField'
  #                       'DropDownField'
  #               key: 'settings'. Keys depend on field type.
  #               values: a map of field specific settings. If field type is:
  #                      'TextArea', then
  #                       	keys are: 'cols' (value: integer) and 'rows' (value: integer)
  #                      'DropDownField', then
  #                      		key is: 'list' (value is map, where keys are id's and values display values)
  #              key: 'field_name'
  #              value: the name of the active record field
  #   target_action: the name of the controller action to submit the form to
  #   active_record_var_name: the name of the active record instance variable, as defined in the
  #                        controller that created the view that created this form
  #   submit_caption: the text to display on the form's submit button
  #-------------------------------------------------------------------------------------------------------------------


  def build_form(active_record, field_configs, target_action, active_record_var_name, submit_caption,
                 send_id = nil, hidden_field_data = nil, hide_spinner = nil, non_db_form = nil, plugin = nil, javascript_inject=nil)

    if send_id
      field_configs.push({:field_type => "HiddenField", :field_name => "id"})
    elsif hidden_field_data != nil
      puts "in elsif hidden field"
      field_configs.push({:field_type => "HiddenField", :field_name => "hidden_data", :settings => {:hidden_field_data => hidden_field_data}})
    end


    Form.new(self, active_record, field_configs, target_action, active_record_var_name, submit_caption,
             non_db_form, hide_spinner, plugin, javascript_inject).build_form

  end

  # Alias for build_form. Wraps a call to build_form. Uses options hash for optional parameters
  def construct_form(active_record, field_configs, target_action, active_record_var_name, submit_caption, send_id, options={})

    build_form(active_record, field_configs, target_action, active_record_var_name, submit_caption, send_id,
               options[:hidden_field_data],
               options[:hide_spinner],
               options[:non_db_form],
               options[:plugin],
               options[:javascript_inject])
  end

  # Return a DataGridSlick::DataGrid for displaying a SlickGrid grid.
  def get_data_grid(data_set, column_configs, plugin = nil, key_based_access = nil, special_commands = nil, options = {})
    DataGridSlick::DataGrid.new(self, data_set, column_configs, plugin, key_based_access, special_commands, options)
  end

  # def get_data_grid(data_set, column_configs, plugin = nil, key_based_access = nil, special_commands = nil, options = {})
  #   DataGridSlick::DataGrid.new(self, data_set, column_configs, plugin, key_based_access, special_commands, options)
  # end

  #-----------------------------------------------
  #  Happymore Sibamba
  #-----------------------------------------------

  def build_parameter_fields_form(fields, action, caption)

    field_configs = Array.new
    config_index = 0
    fields.each do |f|
      if f.has_key?(:list)
        list                = f.fetch(:list)
        field_type          = f.fetch(:field_type)
        field_name          = f.fetch(:field_name)
        if list.class == Array
          field_caption = f.fetch(:caption)
          dropdown_list = list
          field_configs[config_index] = {:field_type => 'lookup', :field_name => field_caption,
                                         :settings   => {:list => dropdown_list}}
        else
          dropdown_list       = []
          dropdown_field_name = nil

          if list.index('*') || list.count(',') > 1
            raise("The form could not be built because a lookup field returns more than two columns. <BR> Re-define the file")
          else
            conn                = User.connection
            results             = conn.select_all(list)

            # Get the list of fields (between SELECT [DISTINCT] and FROM)...
            fieldlist           = list.sub(/select\s+(?:distinct)?\s*/i, '').sub(/\sfrom.*/i, '')

            # Get the column names of each field...
            fields              = fieldlist.split(',').map {|a| a.strip.split(' ').last.split('.').last }
            dropdown_field_name = fields.last

            if results.nil?
              dropdown_list << "<empty>"
            else
              results.each do |record|
                if fields.size == 2
                  dropdown_list << [record[fields[0]], record[fields[1]]]
                else
                  dropdown_list << record[fields[0]]
                end 
              end
            end

            field_configs[config_index] = {:field_type => field_type, :field_name => dropdown_field_name,
                                           :settings   => {:list => dropdown_list}}
          end
        end
      else
        field_type = f.fetch(:field_type)
        field_name = f.fetch(:field_name)
        field_configs[config_index] = {:field_type=>field_type, :field_name =>field_name}
      end
      config_index = config_index + 1
    end

    #        field_configs[field_configs.length()] = {:field_type=>'link_window_field',:field_name =>'view results',
    #                       :settings =>
    #                      {
    #                       :host_and_port =>request.host_with_port.to_s,
    #                       :controller =>request.path_parameters['controller'].to_s ,
    #                       :target_action => 'send_parameter_fields',
    #                       :link_text => 'view results'}}

    dm_session[:parameter_fields]= nil if dm_session[:parameter_fields]!=nil
    dm_session[:parameter_fields] = field_configs

    build_form(nil, field_configs, action, 'search_form', caption, nil, nil, nil, nil, nil)

  end

  #-----------------------------------------------------------------------------------------------
  #This method returns the javascript for the 'on_complete' event for an
  #observer for a single combo
  #. The javascript generation
  #involves the following:
  #   For every dependant combo (i.e with an array index higher than the
  #   current item- i.e. the combo to clear when this one is clicked),
  #   except the one with the next index:
  #   -> an array is generated
  #       with the following form: [<name of combo>,<name of dependant combo>
  #   -> The list of arrays is then packaged inside a container array
  #   -> A call is made to the 'clear_combos()' function, passing in the
  #      container array. An example of the generated script:
  #   -> The visibility of the 'spinner.gif' image with the name <combo_name> + '_' loading.gif'
  #      is set to 'hidden'
  #      ---------------------------------------------------------------------------
  #      to_clears = [['select2','select1'],['select3','select2']];
  #      clear_combos(to_clears);
  #      document.getElementById('select2_loading_gif').style.visibility = 'hidden'
  #      ---------------------------------------------------------------------------
  #----------------------------------------------------------------------------------------------
  def gen_combos_clear_js_for_combos(combos)

    combos_js = Hash.new
    i = 0
    combos.each do |combo|
      #generate a sublist from the current position to end of list
      if i < combos.length() -2
        subset = combos.slice(i..(combos.length() -1))
        puts combo
        combos_js[combo] = gen_combos_clear_js_for_combo(subset)
      elsif i < combos.length() -1
        img = "img_" + combo
        js = "\n img = document.getElementById('" + img + "');"
        js += "\n if(img != null)img.style.display = 'none';"
        combos_js[combo]= js
      end

      i += 1
    end

    return combos_js
  end


  def gen_combos_clear_js_for_combo(combos)

    i = 0
    js = "to_clears = ["

    combos.each do |combo|
      if i > 1

        js += "['" + combos[i] + "','" + combos[i - 1] + "'],"
      end
      i += 1
    end
    js = js.slice(0, (js.length - 1))
    js += "];"
    js += "\n clear_combos(to_clears);"
    img = "img_" + combos[0]
    js += "\n img = document.getElementById('" + img + "');"
    js += "\n if(img != null)img.style.display = 'none';"

    return js

  end



  #-------------------------------------------------------------
  #This class implements a plugin mechanism whereby a user can
  #implement custom rendering of a grid cell
  #-------------------------------------------------------------
  class GridPlugin

    #---------------------------------------------------------------
    #This method allows the grid-client code to cancel the rendering
    #of a given cell
    #---------------------------------------------------------------
    def cancel_cell_rendering(column_name, cell_value, record)
      false
    end

    #-------------------------------------------------------------------
    #This method allows a plugin to render the cell instead of the
    #grid column. To work, the same plugin must also implmement the
    #'cancel_cell_rendering' method and return true.
    #-------------------------------------------------------------------
    def render_cell(column_name, cell_value, record)
      ""
    end

    #---------------------------------------------------------------
    #This method allows a user to customize the styling of a cell
    #The calling method will prepend the cell text with the styling
    #string returned by this methodd
    #---------------------------------------------------------------
    def before_cell_render_styling(column_name, cell_value, record)

      ""
    end

    #--------------------------------------------------------------------
    #This method is called after the grid has rendered text to the cell
    #The plugin provider should simply simply provide html closing tags
    #for the tags opened during 'before_cell_render_styling'
    #----------------------------------------------
    def after_cell_render_styling(column_name, cell_value, record)
      ""

    end


  end


  class FormPlugin

    #-------------------------------------------------------------------------
    #This method allows client-code to set the css-class of the containing td
    #-------------------------------------------------------------------------
    def get_cell_css_class(field_name, record)
      return nil
    end

    def get_field_css_class(field_name, record)
      return
    end

    def override_build?
      false
    end

    def build_control(field_name, active_record, control)


    end

  end


  class Form

    attr_reader :trace, :env, :active_record, :plugin, :is_popup, :field_configs
    attr_writer :trace

    def is_popup=(val)
      #puts "WRTING IS POPUP: " + val.to_s
      @is_popup = val
      @env.is_popup = val
    end

    def incremenent_field_index
      @curr_field_index += 1
    end

    def end_at_position
      @end_at_position
    end

    def hide_labels?
      hide = self.env.hide_labels?
      val = @curr_field_index
      if self.env.start_from_position? > 0 && hide

        if val < self.env.start_from_position?
          hide = false
        else
          hide = (@curr_field_index - self.env.start_from_position?) > 0
        end
      end

      return hide
    end

    def current_field_index?
      val = @curr_field_index
      if self.env.start_from_position?
        if val < self.env.start_from_position?
          val = 0
        else
          val = @curr_field_index - self.env.start_from_position?
        end
      end
      #puts "INDEX: " +  val.to_s
      return val
    end

    def next_separator_id
      @curr_separator += 1
      return "separator" + @curr_separator.to_s

    end

    def layout
      @layout
    end


    def cells_in_row?

      if @layout
        if !@cells_in_row
          @cells_in_row = @layout.slice(0..0).to_i
        end
        return @cells_in_row
      else
        return nil
      end

    end

    def reset_layout
      @layout = @env.form_layout
      @cells_in_row = nil

    end


    def initialize(environment, active_record, field_configs, target_action, active_record_var_name, submit_caption,
                   non_db_form = false, hide_spinner = nil, plugin = nil, javascript_inject=nil)

      @layout = environment.form_layout
      @end_at_position = environment.end_at_position
      @submit_button_align = environment.submit_button_align

      @hide_labels = environment.hide_labels?
      @curr_field_index = 0
      @curr_separator = 0
      #validate
      empty_var = nil
      @non_db_form = non_db_form
      @plugin = plugin

      @suppress_submit_spinner = hide_spinner
      #if active_record == nil
      #	empty_var = "active record"
      #end
      if field_configs == nil
        empty_var = "field_configs"
      end
      #if target_action == nil
      #	empty_var = "target_action"
      #end
      if active_record_var_name == nil
        empty_var = "active_record_var_name"
      end
      if submit_caption == nil
        empty_var = "submit_caption"
      end

      raise "The form class constructor requires parameter: " + empty_var + " , which is empty." if empty_var != nil

      @active_record = active_record
      @field_configs = field_configs
      @form_fields = nil
      @active_record_var_name = active_record_var_name
      @target_action = target_action
      @submit_caption = submit_caption
      @env = environment #this is to have an access point to the application helper
      @trace = ""
      @js_inject = javascript_inject
    end

    def build_form

      stage = "'building form header'"
      # begin
        form_string = build_header

        stage = "'building form fields'"
        @field_configs.each do |field_config|
          field = build_field(field_config)

          form_string += field.construct

        end
        stage = "'building form footer'"
        form_string += build_footer
      # rescue
      #   raise "The form could not be build correctly. Stage: " + stage + " failed. Form built trace is: \n" + @trace + ".\n Exception reported: \n " + $!
      # end
    end


    def build_field(field_config)

      @trace += "\n build_field entered"
      raise "field_config is null!" if field_config == nil
      incremenent_field_index
      case field_config[:field_type]
        when 'PopupDateRangeSelector'
          @trace += "\n creating PopUpDateRangeSelector"
          return MesScada::FormComponents::PopupDateRangeSelector.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        when "PopupDateSelector" #Henry
          @trace += "\n creating PopUpDateSelector"
          return MesScada::FormComponents::PopupDateSelector.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        when "PopupDateTimeSelector"
          @trace += "\n creating PopUpDateTimeSelector"
          return MesScada::FormComponents::PopupDateTimeSelector.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        when "link_window_field", "LinkWindowField", "LinkField_PopupWindow"
          @trace += "\n creating linkwindow field"
          return MesScada::FormComponents::LinkWindowField.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        when "CheckBox"
          @trace += "\n creating check box field"
          return MesScada::FormComponents::CheckBox.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        when "Screen", "ChildForm" #Luks
          @trace += "\n creating Screen field"
          #return ChildForm.new(self,@active_record,field_config[:field_name],field_config[:field_type],@active_record_var_name,field_config[:settings],field_config[:non_db_field],field_config[:observer])
          return MesScada::FormComponents::Screen.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        when "TextField"
          @trace += "\n creating text field"
          return MesScada::FormComponents::TextField.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        when "LabelField"
          @trace += "\n creating label field"
          return MesScada::FormComponents::StaticField.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        when "TextArea"
          @trace += "\n creating text area field"
          return MesScada::FormComponents::TextArea.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])

        when "HiddenField"
          @trace += "\n creating hidden field"
          return MesScada::FormComponents::HiddenField.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])

        when 'PasswordField'
          @trace += "\n creating password field"
          return MesScada::FormComponents::PasswordField.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])

        when "DateField"
          @trace += "\n creating date field"
          return MesScada::FormComponents::DateField.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])

        when "DateTimeField"
          @trace += "\n creating datetime field"
          return MesScada::FormComponents::DateTimeField.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])

#        when "LinkField_PopupWindow"
#          @trace += "\n creating link field"
#          return LinkWindowField.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        when "LinkField"
          @trace += "\n creating link field"
          return MesScada::FormComponents::LinkField.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])

        when "DropDownField"
          @trace += "\n creating dropdown field"
          return MesScada::FormComponents::DropDownField.new(self, @active_record, field_config[:field_name], field_config[:field_type], @active_record_var_name, field_config[:settings], field_config[:non_db_field], field_config[:observer])
        else
          raise "cannot create unknown field. passed-in type was: " + field_config[:field_type].to_s
      end
    end

    def build_header
      begin
        header = ""
        @trace += "\n method: 'build_header' entered."
        @trace += "\n      active_record_var_name is: " + @active_record_var_name
        header = @js_inject if @js_inject

        #if @non_db_field
        errs = nil
        if @active_record.respond_to?("errors")
          errs = @env.error_messages_for @active_record_var_name
        end

        header += errs if errs != nil
        @trace += "\n section: 'error messages for' completed. "
        #end

        if @suppress_submit_spinner == nil || @suppress_submit_spinner == false
          header += @env.form_tag({:action=> @target_action}, {:onSubmit=>"show_element('ident_spinner');"})
        else
          header += @env.form_tag({:action=> @target_action})
        end
        @trace += "\n section: 'form_tag' completed. "
        header +=  "<table>"
        @trace += "\n method: 'build_header' exited"
        return header
      rescue
        raise "The header for the form could not be created correctly.\n The output text is: " + header + ". \n The exception reported is: " + $!
      end
    end

    def build_footer


        expand_sep_script = ""
        @submit_button_align = "right" if !@submit_button_align

        footer = "<tr><td>" if @submit_button_align == "left"
        footer = "<tr><td></td><td>" if @submit_button_align == "right"
        if @curr_separator > 0
          expand_sep_script = " onclick = 'expand_all();document.forms[0].submit();'"
          footer += "<button " + expand_sep_script + " id = 'submit_button'>" + @submit_caption + "</button>" if @target_action != nil
        else
          footer += "<button id = 'submit_button'>" + @submit_caption + "</button>" if @target_action != nil
        end
        footer += @env.image_tag("spinner.gif", :align => 'absmiddle', :border=> 0, :id=>"ident_spinner", :style=>"display: none;")

        onclick = "tree_content = document.getElementById('tree_node_content');"
        onclick += "if(tree_content)tree_content.innerHTML = ''; else "
        onclick += "window.parent.clear_content();"
        footer +=  "&nbsp;" + @env.image_tag("cancel.png", :align => 'absmiddle', :border=> 0, :onclick => onclick) if @target_action != nil
        sep_script = ""
        if @curr_separator > 0
          sep_script = "<script> n_separators = " + @curr_separator.to_s + ";</script>"

        end
        footer += "</td></tr></table>" + sep_script + '</form>' #@env.end_form_tag

    end


  end

  # Close the popup window, alert a message (if not nil) and reload the content frame.
  # Called from within a subframe.
  def close_popup_reload_main_window(msg)
    close_popup_window( msg, :reload => true, :opener => true )
  end

  # Close the popup window, alert a message (if not nil) and reload the content frame.
  # Called from within contentFrame.
  def close_popup_reload_content_frame(msg)
    close_popup_window( msg, :reload => true )
  end

  # Close a popup window. If msg is provided an alert will be shown before the window closes.
  # options:
  # has_no_popup:: If true, will not call <tt>window.close()</tt>.
  #                Although somewhat illogical given the name of the method, this allows it to be used in more situations.
  # reload:: If true, will reload a frame.
  # opener:: If true, will reload the window opener (only if sub_frame_id is not provided).
  # new_href:: If set, will load this url in a frame.
  # sub_frame_id:: If set will reload or load a subframe of +contentFrame+ with matching id.
  #                If not set, will reload or load +contentFrame+.
  def close_popup_window(msg=nil, options={})
    stmts = []
    stmts << "alert('#{msg}');" unless msg.nil?
    stmts << 'window.close();' unless options[:has_no_popup]
    if options[:reload] && options[:reload] == true
      if options[:sub_frame_id]
        stmts << "reloadFrame('#{options[:sub_frame_id]}');"
      elsif options[:opener]
        stmts << 'window.opener.location.reload(true);'
      else
        stmts << 'reloadFrame();'
      end
    elsif options[:new_href]
      if options[:sub_frame_id]
        stmts << "loadFrame('#{options[:new_href]}', '#{options[:sub_frame_id]}');"
      else
        stmts << "loadFrame('#{options[:new_href]}');"
      end
    end
    "<script>#{stmts.join}</script>"
  end

  #-----------------------------------
  #  This method is used to close the popup window
  #  when there are inner iframe(s) in content area frame.
  #  The inner iframe is referenced by passing in the iframe number
  #  as 'frame_number' parameter. On closure of the popup window the
  #  iframe is reloaded.
  #-----------------------------------
  def close_popup_reload_child_window_by_pos(msg, frame_number)
    "<script>alert(\"#{msg}\");window.close();window.opener.frames[1].frames[" + frame_number.to_s + "].location.reload(true);</script>"
  end

  #---------------------------------------------------------
  # This method is used to close the popup window and load
  # the inner iframe referenced by 'frame_pos' parameter by
  # pointing its location.href to 'href' parameter.
  #---------------------------------------------------------
  # def close_popup_load_child_window(msg, frame_pos, href)
  #   "<script>alert(\"#{msg}\");window.close();window.opener.frames[1].frames[" + frame_pos.to_s + "].location.href=\"#{href}\";</script>"
  # end
  # NEW version: - using js code from utils.js:
  def close_popup_load_child_window(msg, frame_pos, href)
    #"<script>alert(\"#{msg}\");window.close();window.opener.frames[1].frames[" + frame_pos.to_s + "].location.href=\"#{href}\";</script>"
 #   "<script>alert(\"#{msg}\");window.close();loadFrame('#{href}', '#{frame_pos}');</script>"
    close_popup_window( msg, :new_href => href, :sub_frame_id => frame_pos )
  end

#FIXME: reloadFrame javascript function is not in use. (CALLED FROM app/controllers/fg/voyage_controller.rb)
  # def close_popup_reload_child_window_by_id(msg, frame_id)
  #   #"<script>window.close(); alert(\"#{msg}\"); window.opener.reloadFrame('" + frame_id.to_s + "')</script>"
  #   "<script>alert(\"#{msg}\"); window.close(); window.opener.reloadFrame('" + frame_id.to_s + "')</script>"
  # end

  # NEW version: - using js code from utils.js:
  def close_popup_reload_child_window_by_id(msg, frame_id)
   # "<script>alert(\"#{msg}\"); window.close(); reloadFrame('#{frame_id}')</script>"
    close_popup_window( msg, :reload => true, :sub_frame_id => frame_id )
  end





  class ContextMenu

    #@@images_file_root =  File.dirname(__FILE__) + '../../../public/images/trees/'
    @@images_file_root =  'public/images/trees/'
    @@images_url_root = "/images/trees/"


    def initialize(menu_name, group_name, is_popup = nil)


      @is_popup = is_popup
      @is_popup = false if !@is_popup

      if menu_name == nil
        raise "menu name cannot be null for a context menu"
      end

      @commands = Array.new
      @node_type = menu_name
      @menu_id = "menu_" + menu_name
      @tree_name = group_name

    end

    def add_command(caption, target_action)

      puts "target action: " + target_action
      if caption == nil
        raise "menu caption is null"
      elsif target_action == nil
        raise "menu target_action is null"
      end

      command = Hash.new
      command[:caption] = "'" + caption + "'"
      command[:target_action] = "'" + target_action + "'"
      @commands.push command

    end

    def render

      menu = nil
      #  begin

      menu = "popup_commands = " + @is_popup.to_s + ";"

      menu += @menu_id + " = new Array; \n";
      menu += @menu_id + "['node_type'] = '" + @node_type + "'; \n"
      menu+= @menu_id + "['commands'] = new Array; \n"


      if @commands.length == 0
        raise "menu " + @menu_id + " has no commands defined for it"
      end

      cmd_index = 0
      @commands.each do |cmd|
        cmd_str = @menu_id + "['commands'][" + cmd_index.to_s + "]= new Array; \n"
        cmd_str += @menu_id + "['commands'][" + cmd_index.to_s + "]['caption'] = " + cmd[:caption] + "; \n"
        cmd_str += @menu_id + "['commands'][" + cmd_index.to_s + "]['target_action'] = " + cmd[:target_action] + "; \n"
        #add appropriate image
        image_file_path = @@images_file_root + @tree_name + "/menus/" + @node_type + "/" + cmd[:caption].delete("'")+ ".png"
        image_file_path.gsub!(" ", "_")
        image_url = @@images_url_root + @tree_name + "/menus/" + @node_type + "/" + cmd[:caption].delete("'") + ".png"
        image_url.gsub!(" ", "_")


        image_url = "/images/menu/transparent.png" if not File.exists?(image_file_path)

        cmd_str += @menu_id + "['commands'][" + cmd_index.to_s + "]['image'] = '" + image_url + "'; \n"

        menu += cmd_str
        cmd_index += 1
      end

      menu += "Context_Menu_definitions['" + @menu_id + "']= " + @menu_id + "; \n"

      #   rescue
      #  raise "The context menu with name: " + @menu_id + " could not be rendered." +
      #      ". Exception reported: \n" + $! + "\n .Generated script is: " +  menu
      #   end

      return menu

    end

  end


  def render_add_node_js(node_name, node_type, node_id, tree_name)

    node_added_js = "window.parent.AddNode(null, '/images/trees/" + tree_name + "/" + node_type + ".png','/images/trees/" + tree_name + "/" + node_type + ".png','" + node_name + "','" + node_type + "','" + node_id + "');"
    puts "node add script is: " + node_added_js
    return node_added_js
  end

  def render_add_node_to_parent_js(parent, node_name, node_type, node_id, tree_name)

    node_added_js = "window.parent.AddNode('" + parent + "', '/images/trees/" + tree_name + "/" + node_type + ".png','/images/trees/" + tree_name + "/" + node_type + ".png','" + node_name + "','" + node_type + "','" + node_id + "');"
    puts "node add script is: " + node_added_js
    return node_added_js
  end


  def render_edit_node_js(new_text)
    edit_node_js = "window.parent.EditNode(null,'" + new_text + "');"
    return edit_node_js
  end

  class TreeView


    def initialize(root_node, name)

      @context_menus = Array.new
      @root_node = root_node
      @name = name
      if !@root_node.is_root
        raise "The root node must be created with the 'is_root' constructor argument set to true"
      end
      raise "root node cannot be null. " if @root_node == nil


    end

    def add_context_menu(context_menu)
      @context_menus.push context_menu
    end

    #--------------------------------------------------------------------------------------------------
    #The javascript for the treeview is rendered in the following order:
    #1) the context menus
    #2) the tree data
    #3) this method assumes that the scripting context has been taken care of by the
    #   layout page dedicated for trees- i.e. such a page should establish the following
    #   context within which this 'render' method will generate script:
    #   -> The <script> tags
    #   -> The function declaration to hold the generated script; this function (e.g. 'create_tree()')
    #      should be called by the html 'body onload()' event
    #   -> the call to 'initialise' before the function declaration
    #---------------------------------------------------------------------------------------------------
    def render(sort = true)
      tree_script = ""
      tree_nodes_script = ""
      begin
        # get the script for the menus
        if @context_menus.length > 0
          tree_script = ""
          @context_menus.each do |menu|
            tree_script += menu.render
          end
        end

        #get the script for the tree

        #the call 'render' on the root_node will result in a recurcive call to all
        #nodes in the hierarchy- all appending to a single script string variable
        tree_nodes_script += @root_node.render(nil, "",sort)
        tree_script += tree_nodes_script

      rescue
        raise "The treeview could not be rendered. Exception reported: \n" + $!
      end
      return tree_script
    end


  end


  class TreeNode

    #@@images_file_root =  File.dirname(__FILE__) + '../../../public/images/trees/'
    @@images_file_root =  'public/images/trees/'
    @@images_url_root = "/images/trees/"

    @@node_index = 0

    attr_reader :is_root,:node_name


    def initialize(node_caption, node_type, is_root, tree_name, node_id = nil)

      empty = nil
      empty = "node_caption" if node_caption == nil
      empty = "node_type" if node_type == nil
      empty = "is_root" if is_root == nil
      empty = "tree_name" if tree_name == nil

      raise "The constructor parameter: " + empty + " is null for the treenode." if empty != nil


      @tree_name = tree_name
      @is_root = is_root
      @node_name = node_caption
      @node_type = node_type

      @closed_image_url = @@images_url_root + @tree_name + "/" + @node_type + ".png"
      closed_image_file_path = @@images_file_root + @tree_name + "/" + @node_type + ".png"


      @closed_image_url = "/images/menu/transparent.png" if not File.exists?(closed_image_file_path)


      @opened_image_url = @@images_url_root + @tree_name + "/" + @node_type + "_opened.png"
      opened_image_file_path = @@images_file_root + @tree_name + "/" + @node_type + "_opened.png"

      @opened_image_url = @closed_image_url if not File.exists?(opened_image_file_path)
      #special case if root folder
      if is_root
        if not File.exists?(closed_image_file_path)
          @closed_image_url = "/images/trees/folder_closed.gif"
          @opened_image_url = "/images/trees/folder_open.gif"
        end
      end

      @node_js_var_name = nil
      @node_id = node_id if node_id != nil


    end

    def add_child(node_name, node_type, node_id = nil)

      begin
        child= TreeNode.new(node_name, node_type, false, @tree_name, node_id)
        if @children == nil
          @children = Array.new
        end

        @children.push child
        return child
      rescue
        raise "The child node could not be added. Exception reported: \n" + $!
      end
    end

    #------------------------------------------------------------------------------------
    #The recursive render method creates the javascript for the node it represents and
    #appends the generated line of script to total tree data script
    #It then forwards the call to each of it's children
    #------------------------------------------------------------------------------------
    def render(parent_node_var_name, tree_script,sort = true)
      begin

        tree_script += render_node_only(parent_node_var_name)

        @children.sort!{|a,b| a.node_name <=> b.node_name} if @children && sort
        if @children != nil && @children.length > 0
          @children.each do |child|
            tree_script = child.render(@node_js_var_name, tree_script,sort)
          end
        end
      rescue

        raise "The node with name: " + @node_name + " could not be rendered. Exception reported: \n " + $! +
                ".\n Generated script is: \n " + tree_script
      end
      return tree_script


    end

    def render_node_only(parent_node_var_name)
      script = ""
      begin
        if @is_root
          root_id = "root"
          root_id = @node_id.to_s if @node_id

          script = "tree_node = CreateTreeItem( rootCell,'" + @closed_image_url +
                  "','" + @opened_image_url + "','" + @node_name + "','" + @node_type + "','" + root_id + "'); \n"
          @node_js_var_name = "tree_node"
        else
          @@node_index += 1
          node_var = @node_type + "_" + (@@node_index).to_s
          node_id = nil
          if @node_id == nil
            node_id = node_var
          else
            node_id = @node_id
          end

          script = node_var + " = CreateTreeItem(" + parent_node_var_name + ",'" + @closed_image_url +
                  "','" + @opened_image_url + "','" + @node_name + "','" + @node_type + "','" + node_id + "'); \n"

          @node_js_var_name = node_var

        end
      rescue
        raise "The actual rendering for node: " + @node_name + " failed. Exception reported: \n" + $! +
                "\n .Generated script for this node: " + script
      end

      return script

    end

  end
  # Henry Log_viewer_html_converter
  class Log_viewer_html_converter
    # classifies the line as a input or output line
    def classify (line)
      arrays =  line.split(" ")
      arrays[1].gsub(":", "")
      if (arrays[1].gsub(":", "") == "INPUT")
        return x = Input.new(arrays)
      else
        return y = Output.new(arrays)
      end
    end

    def pair_input_w_output(array_loggertype)
      input_not_matced = Array.new
      count  = 0

      for i in 0...array_loggertype.length
        # tests if its an input class instance
        if (array_loggertype[i].class.to_s =="ApplicationHelper::Input")


          begin
            # matches the input with output
            # it it uses the input index plus 1 to get the output index

            if (array_loggertype[i+1].input_type.to_s =="OUTPUT:" and array_loggertype [i].match_code().to_s == array_loggertype[i+1].match_code().to_s)

              array_loggertype[i].matched_item_index = count+1

              array_loggertype[i+1].matched_to = count

              count = count +1
            else
              # if the output isnt a match with  the input
              # it will be added to an unmatched array
              array_loggertype[i].index_if_trans = i
              input_not_matced.push(array_loggertype[i])
              count = count +1

            end
          rescue
          end
        else
          # tests if the  item hasnt been matched


          if (array_loggertype[i].matched_to.to_s == "")

            for internal in 0...array_loggertype.length
              # runs through an array of unmatched items
              if (array_loggertype[internal].class.to_s == "ApplicationHelper::Input" and array_loggertype[internal].match_code().to_s == array_loggertype[i].match_code().to_s)
                if (array_loggertype[internal].matched_item_index.to_s == "")
                  #***********************************************************************
                  # test if there are more than one match
                  if (array_loggertype[internal].match_code().to_s.length > 1)
                    array_loggertype[internal].matched_item_index = i.to_s
                    array_loggertype[i].OOS_info = "<span class='out_of_sync'>[_OUT_OF_SYNC_]</span>"
                  else
                  end
                  #***********************************************************************
                else

                  for nm in 0...input_not_matced.length
                    # matches unmatched items

                    if (input_not_matced[nm].match_code.to_s == array_loggertype[internal].match_code().to_s and input_not_matced[nm].matched_item_index.to_s == "" and array_loggertype[i].matched_to.to_s == "")

                      array_loggertype[input_not_matced[nm].index_if_trans.to_i].matched_item_index = i

                      array_loggertype[i].matched_to = input_not_matced[nm].index_if_trans.to_i

                      array_loggertype[i].OOS_info = "<span class='out_of_sync'>[_OUT_OF_SYNC_]</span>"
                    end
                  end
                  # if the item has more than match
                  if (array_loggertype[internal].match_code().to_s.length > 1)
                    array_loggertype[internal].matched_item_index = array_loggertype[internal].matched_item_index.to_s+"@"+ i.to_s
                    array_loggertype[i].OOS_info = "<span class='out_of_sync'>[_OUT_OF_SYNC_]</span>"
                  end
                end
              end
            end
          end
          count  = count + 1
        end
      end
    end

    # scans the string insearch for a match of passed number
    def contains_cartin_number(output_td, testnumber)


      begin_highlight = '<span style="background-color:lightgreen">'
      end_highlight = '</span>'


      if (output_td.action_1.to_s.include?(testnumber.to_s))
        begin_index = output_td.action_1.to_s.index(testnumber.to_s)
        number_extacted =  output_td.action_1[begin_index, testnumber.to_s.length]
        first_element_removed =  output_td.action_1.to_s[0, begin_index]
        after_number_elements =  output_td.action_1.to_s[begin_index+testnumber.to_s.length, output_td.action_1.to_s.length-begin_index+testnumber.to_s.length+1]
        output_td.action_1=  first_element_removed+ begin_highlight +testnumber.to_s+end_highlight+ after_number_elements

      end
    end

    def build_html(array_loggertype, id, carton_number)


      # the error time being seperated into
      # minutes and hours
      @mid_query = MidwareErrorLog.find(id)
      error_time  = @mid_query.error_date_time.to_s
      short_description  =@mid_query.short_description

      @mid_query_time = @mid_query.error_date_time.strftime("%H:%M%:")
      @mid_query_time_split =@mid_query_time.split(":")
      time_h  =  @mid_query_time_split[0].to_i
      time_min = @mid_query_time_split[1].to_i


      html ="<html><head><%= stylesheet_link_tag 'error_log.css' %><title>Kromco Admin Popup</title></head><body><table class='table_error_info'><tr><td>Error time</td><td>"+error_time+"</td></tr><tr><td>Short Description</td><td>"+ short_description+"</td></tr><table><table border=1>"
      array_loggertype.each do |item|
        time_a = item.time.split(":")
        # here the time gets placed into categories so that it shows the errors 1 min before and 1min after
        time_min_p = time_min+1
        time_min_m = time_min-1
        time_h_p = time_h
        time_h_m = time_h
        if (time_min.to_i-1 == -1)
          time_min_m = 59
          if (time_h_m != 1)
            time_h_m = time_h_m -1
          end
        end
        if (time_min.to_i+1 == 60)
          time_min_p  = 0

          time_h_p = time_h_p +1
        end

        # checks the time of the input instance and that it has a match
        if (item.class.to_s == "ApplicationHelper::Input" and item.matched_item_index.to_s != "")

          # checks  if the item has multiple matches
          number_match  =  item.matched_item_index.to_s.split("@")

          if (number_match.length == 1)

            if (time_h.to_i == time_a[0].to_i and time_min.to_i == time_a[1].to_i)
              contains_cartin_number(array_loggertype[item.matched_item_index.to_i], carton_number)
              html +=   "<tr class='tr1'><td  class='td1' >"+item.to_s+"</td><td border=1 class='td1_output'>"+array_loggertype[item.matched_item_index.to_i].to_s+"</td></tr>"
            end

            if (time_h_m == time_a[0].to_i and time_min_m.to_i == time_a[1].to_i)
              contains_cartin_number(array_loggertype[item.matched_item_index.to_i], carton_number)
              html +=   "<tr><td  class='td2_input' >"+item.to_s+"</td><td class='td2_output' >"+array_loggertype[item.matched_item_index.to_i].to_s+"</td></tr>"
            end

            if (time_h_p == time_a[0].to_i and time_min_p.to_i == time_a[1].to_i)
              contains_cartin_number(array_loggertype[item.matched_item_index.to_i], carton_number)
              html +=   "<tr><td class='td2_input' >"+item.to_s+"</td><td class='td2_output' >"+array_loggertype[item.matched_item_index.to_i].to_s+"</td></tr>"
            end
          else

            # this is for elements that have more than one match
            html_mi = "<table border=1>"

            for nr in 0...number_match.length
              time_a =  array_loggertype[number_match[nr].to_i].time.split(":")
              contains_cartin_number(array_loggertype[number_match[nr].to_i], carton_number)
              html_mi +=   "<tr><td class='multiple_outputs' >"+array_loggertype[number_match[nr].to_i].to_s+"</td></tr>"

            end

            if (time_h.to_i == time_a[0].to_i and time_min.to_i == time_a[1].to_i)
              contains_cartin_number(array_loggertype[item.matched_item_index.to_i], carton_number)
              html_mi +="</table>"
              html += "<tr><td class='multiple_input_precise' >"+item.to_s+"</td><td border=1>"+html_mi+"</td></tr>"
            end
            if (time_h.to_i == time_a[0].to_i and time_min_m.to_i == time_a[1].to_i)
              contains_cartin_number(array_loggertype[item.matched_item_index.to_i], carton_number)
              html_mi +="</table>"
              html += "<tr><td class='multiple_input' >"+item.to_s+"</td><td border=1>"+html_mi+"</td></tr>"
            end
            if (time_h.to_i == time_a[0].to_i and time_min_p.to_i == time_a[1].to_i)
              contains_cartin_number(array_loggertype[item.matched_item_index.to_i], carton_number)
              html_mi +="</table>"
              html += "<tr><td class='multiple_input' >"+item.to_s+"</td><td border=1>"+html_mi+"</td></tr>"
            end


          end


        else
          if (item.class.to_s == "ApplicationHelper::Input" and item.matched_item_index.to_s == "")

            if (time_h.to_i == time_a[0].to_i and time_min.to_i == time_a[1].to_i)
              html +=   "<tr class='tr1'><td  class='td1' >"+item.to_s+"</td><td border=1 class='td1_output'>"+"This Input does not have an Output"+"</td></tr>"
            end
            if (time_h_m == time_a[0].to_i and time_min_m.to_i == time_a[1].to_i)
              html +=   "<tr><td  class='td2_input' >"+item.to_s+"</td><td class='td2_output' >"+"This Input does not have an Output"+"</td></tr>"
            end

            if (time_h_p == time_a[0].to_i and time_min_p.to_i == time_a[1].to_i)
              html +=   "<tr><td class='td2_input' >"+item.to_s+"</td><td class='td2_output' >"+"This Input does not have an Output"+"</td></tr>"
            end

          end
        end


        #****
      end
      #####*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/

      html +="</table><body></html>"
      #   puts html
      return html
      #  f = File.open("html.txt","w")
      #  f.print html
      #  f.close

    end

    def print_paired_items(array_loggertype)

      array_loggertype.each do |item|
        begin
          if (item.class.to_s == "Input")
            #     puts item.to_s+" "+array_loggertype[item.matched_item_index].to_s

          else

          end
        rescue

        end
      end


    end

    # scans the output line for the '<' '>' elements so that it can be replaced with ?

    # and replaces empty spaces in the '<>' with @ so when line gets splitted up it will stay as one
    # piece
    def format_line_special_1(line)
      active_line  = line

      if (line.include?("OUTPUT:") == true)
        count_oc  = 0
        oc_index = 0
        for char in 0...line.length


          if (line[char, 1] == ":")
            count_oc = count_oc +1
            # after the third occurances of the ':' the '<' will appear
            # we need to know where the '<' starts so the correct segment can
            # be extracted and blank spaces can be replaced with '@'

            if (count_oc == 3)
              oc_index  = char

            end
          end

        end
        first_oc = false

        for element in oc_index...line.length

          if (line[element, 1] == "<" and first_oc != true)
            begin_index = element
            first_oc = true
          end
        end
        end_index = active_line.rindex('>')

        if (begin_index < oc_index)
          puts "there is fault with the index"

        end

        extracted_info = active_line.slice(begin_index, end_index)

        extracted_onfo = extracted_info.gsub!("<", " ")
        extracted_info = extracted_info.gsub(">", " ")
        #  extracted_info = extracted_info.gsub("/"," ")


        active_line =  active_line.slice(0, oc_index+1)

      else

        #  begin_index = active_line.index('<')
        #  puts begin_index
        #  end_index = active_line.rindex('>')
        #  puts end_index
        #  extracted_info = active_line.slice(begin_index,end_index)
        #  active_line =  active_line.chomp( extracted_info)
      end
      # replaces empty spaces with  @ and scale down over populated '@@@' to a normal state '@'
      # removes '<>' from the string so that the html doesnt display it as a tag

      if (begin_index != nil and end_index != nil)
        extracted_info =   extracted_info.gsub(" ", "@")
        extracted_info = extracted_info.gsub("@@@", "@")
        active_line =  active_line.gsub("<", "?")
        active_line = active_line.gsub(">", "?")
        active_line = active_line+extracted_info

      end

      return active_line

    end

    def read_log_file(file_name, id, carton_number)
      line_count = 0
      file_path = file_name
      array_loggertype = Array.new
      file = File.new(file_path, "r")

      # reads from the file specified
      if (file)
        one_line_row ="";
        html = ""
        file = File.new(file_path, "r")
        file.each do |line|
          line_count += 1
          test_type_line  =  format_line_special_1(line)
          if (test_type_line.length != nil)
            array_loggertype.push(classify(test_type_line))
          end

          #f = File.open("html.txt","w")
          #f.print html
          #f.close
        end
        pair_input_w_output(array_loggertype)
        build_html(array_loggertype, id, carton_number)
      end
    end
  end
  # end Henry Log_viewer_html_converter
  # Henry Output, part of the Log_viewer_html_converter
  class Output
    attr_accessor :time, :input_type, :action_1, :action2_item, :action_event, :screen, :screen_info, :matched_to, :OOS_info, :array_length

    def initialize(arrays)

      @time =  reformat_time(arrays[0])

      @input_type =   arrays[1]

      @action_1 =  arrays[2]

      @action2_item =  arrays[3]

      @action_event = arrays[4]

      @screen =  arrays[5]

      @screen_info =  arrays[6]

      @array_length = arrays.length

      @matched_to = ""
      @OOS_info = ""
    end

    def match_code()
      if (@arrays_length == 5)
        scan @action_1
      else
        scan  = @action_1
      end
      begin_index = scan.index('(')
      end_index =scan.index(')')
      nr = scan[begin_index, end_index]
      nr  =nr.gsub("(", "")
      nr  =nr.gsub(")", "")
      nr  =nr.gsub(",", "")


      if (nr.length == 5)
        begin_index2 = @action2_item.index('(')
        end_index2 =@action2_item.index(')')
        nr2 = scan[begin_index2, end_index2]
        nr2  =nr.gsub("(", "")
        nr2  =nr.gsub(")", "")
        nr2  =nr.gsub(",", "")
        return nr+nr2
      end

      if (nr.length > 0 and nr != nil)
        nr[nr.length]
        nr = nr[0, nr.length]
        return nr
      else

        scan = @action_event

        begin_index = scan.index('(')
        end_index =scan.index(')')
        nr = scan[begin_index, end_index]
        nr = nr.gsub("(", "")
        nr = nr.gsub(")", "")

        return nr
      end

    end


    def to_s
      extra_info = ""
      if (@screen_info == nil)

        if (@screen != nil)

          extra_info += " "+@screen.gsub("@", " ").to_s.gsub("/", "")
        else

          extra_info += " "+@action_event.gsub("@", " ").to_s.gsub("/", "")
          #    puts extra_info

        end
      else
        # puts "long out"


        extra_info +=" "+@screen+" "+@screen_info.gsub("@", " ").to_s.gsub("/", "")
      end
      if (@array_length == 5)
        return @time.to_s+" "+@input_type+" "+@action_1+" "+@action2_item+" "+extra_info+@OOS_info
      else
        return @time.to_s+" "+@input_type+" "+@action_1+" "+@action2_item+" "+@action_event+extra_info+@OOS_info
      end

    end

    def reformat_time(unf_time)
      return unf_time.gsub("h", ":")

    end
  end
  # end Henry Output, part of the Log_viewer_html_converter
  # Henry Input, part of the Log_viewer_html_converter
  class Input
    attr_accessor :time, :input_type, :action_1, :action2_item, :action_event, :mass, :matched_item_index, :index_if_trans, :array_length

    def initialize (arrays)
      @array_length = arrays.length
      @time =  reformat_time(arrays[0])
      @input =   arrays[1]


      @action_1 =   input_ref(arrays[2])

      @action2_item =  arrays[3]
      @action_event = arrays[4]

      if (arrays.length == 6)
        @mass = arrays[5]

      end
      @matced_item_index  =""
      @index_if_trans = nil
    end

    def input_ref(fire)
      fire = fire.gsub("<", "?")
      fire = fire.gsub(">", "?")

      return fire

    end

    # extracts code that will be used for matching
    def match_code()

      if (@arrays_length == 4)

        scan  = @action_1
      else
        scan  = @action_1
      end
      begin_index = scan.index("(")
      end_index =scan.index(")")
      nr = scan[begin_index, end_index]
      nr  =nr.gsub("(", "")
      nr  =nr.gsub(")", "")
      nr  =nr.gsub(",", "")

      if (nr.length == 5)

        begin_index2 = @action2_item.index('(')
        end_index2 =@action2_item.index(')')
        nr2 = scan[begin_index2, end_index2]
        nr2  =nr.gsub("(", "")
        nr2  =nr.gsub(")", "")
        nr2  =nr.gsub(",", "")
        return nr+nr2
      end

      if (nr.length ==12 or nr.length == 14 or nr.length == 28)

        return nr

      end

      if (nr.length == 13 and nr != nil)
        nr[nr.length-1]
        nr = nr.slice(0, 12)
        return nr
      else
        scan = @action_event

        begin_index = scan.index("(")
        end_index =scan.index(")")
        nr = scan[begin_index, end_index]
        nr = nr.gsub("(", "")
        nr = nr.gsub(")", "")

        return nr
      end

    end

    def to_s
      extra_info  =""
      if (@mass != nil)
        extra_info += " "+@mass
      end
      if (@action_event != nil)

        extra_info += " "+@action_event
      else
      end

      return @time.to_s+" "+@input+" "+@action_1+" "+@action2_item+" "+extra_info #+" "+@action_event
    end

    def reformat_time(unf_time)
      return unf_time.gsub("h", ":")

    end

  end



  # ------------
  # LUKS CODE --
  # ------------
  # -----------------------
  # LUKS Child_Grid CODE --
  # -----------------------

  def gen_grid_column_configs(active_record_instance, action_columns, exclude_columns, additional_columns)
    column_configs = Array.new

    if exclude_columns == nil
      exclude_columns = Array.new
    end

    type_name = Inflector.singularize(active_record_instance.class.table_name.to_s)

    #generating a list of type=>text column_configs
    for column in active_record_instance.attribute_names()
      if column != 'id' && !exclude_columns.include?(column)
        column_configs[column_configs.length] = {:field_type => 'text', :field_name => column}
      end
    end

    if additional_columns != nil
      for additional_column in additional_columns
        column_configs[column_configs.length] = additional_column
      end
    end

    if action_columns != nil
      for action_column in action_columns
        #to make sure  :target_action => 'edit_' and :target_action => 'delete_' are mot repeated
        # HANS ????????
        if action_column[:settings][:target_action] != ('edit_' + type_name) && action_column[:settings][:target_action] != ('delete_' + type_name)
          column_configs[column_configs.length] = action_column
        end
      end
    end

    #generating a list of edit and delete action column_configs
    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'edit ' + type_name,
                                               :settings =>
                                                       {:link_text => 'edit',
                                                        :target_action => 'edit_' + type_name,
                                                        :id_column => 'id'}}

    column_configs[column_configs.length()] = {:field_type => 'action', :field_name => 'delete ' + type_name,
                                               :settings =>
                                                       {:link_text => 'delete',
                                                        :target_action => 'delete_' + type_name,
                                                        :id_column => 'id'}}


    return column_configs
  end

  #-----------------------------------------------------------------------
  #-----------------------------------------------------------------------
  def generate_report_parameters(parameters_hash)
    parameters_hash.keys.each do |k|
      @@crystal_report_url += k + "=" + parameters_hash[k].to_s + "&"
    end

    return @@crystal_report_url.chop!
  end


  #======================================================================
  # HAPPYMORE'S CODE
  #======================================================================

  def build_file_structure_form(tree, root_node_name)
    begin
      tree_builder = ReportTreeBuilder.new

      menu1 = ApplicationHelper::ContextMenu.new("leaf", "reports")
      menu1.add_command("view_report_parameter_form", url_for(:action => "build_happymores_form"))

      root_node = ApplicationHelper::TreeNode.new(root_node_name, "reports", true, "reports")

      tree_builder.display_tree(tree, root_node)

      tree = ApplicationHelper::TreeView.new(root_node, "reports")
      tree.add_context_menu(menu1)

      tree.render

    rescue
      raise "The report tree could not be rendered. Exception reported is \n" + $!
    end
  end

  def generate_form(record, action, caption, model_name)
    build_view_record_form(record, action, caption, model_name)
  end



   def build_view_record_form(record,action,caption,model_name)
    field_configs = Array.new
    attributes = record.attributes
    config_index = 0
    parent_model_names = ParentModels.new(model_name).get_parent_model_names_by_ids
    record.attributes.each do |key,val|
      if key.to_s.index("_id")!= nil
        if (val !=nil || val.to_s.strip() !="")
          if(parent_model_name=parent_model_names[key])
            text = "view " + key.to_s.gsub("_id","") + "_record"
            id = "parent-" + model_name.to_s + "-" + parent_model_name + "-" + val.to_s
          else
            text = "view " + key.to_s.gsub("_id","") + "_record"
            id = "parent-" + model_name.to_s + "-" + key.to_s.gsub("_id","") + "-" + val.to_s
          end
          link_select = link_to(text, "http://" + request.host_with_port + "/" + "reports/reports/view_object_form_link_field/" + id , {:class=>'action_link'})
          field_configs[config_index] = {:field_type=>'LabelField', :field_name=>key.to_s, :settings=>{:static_value=>link_select,:is_separator=>false}}
        else
          field_configs[config_index] = {:field_type=>'LabelField', :field_name=>key.to_s}
        end
      else
        field_configs[config_index] = {:field_type=>'LabelField', :field_name=>key.to_s}
      end
      config_index += 1
    end

    @child_models_array = ChildModels.new(model_name).child_models_array
    if @child_models_array.length()!= 0
      parent_id = record.id
      @child_models_array.each do |relationship|
        if(relationship.has_key?(:class_name))
          child = Inflector.tableize(relationship[:class_name])
          text = "view " + Inflector.singularize(relationship[:table])
        else
          child = relationship[:table]
          text = "view " + child.to_s
        end
        foreign_key = "-" + relationship[:foreign_key] if(relationship[:foreign_key])
        id = "child-" + model_name.to_s + "-" + child.to_s + "-" + parent_id.to_s + "#{foreign_key}"
        link_select = link_to(text, "http://" + request.host_with_port + "/" + "reports/reports/view_object_form_link_field/" + id, {:class=>'action_link'})
        field_configs[field_configs.length()] = {:field_type=>'LabelField', :field_name=>child.to_s, :settings=>{:static_value=>link_select,:is_separator=>false}}
      end
    end
    field_configs.sort!{|x,y| x[:field_name]<=>y[:field_name]}
    build_form(record,field_configs,action,model_name,caption)
  end



  def build_generic_grid(recordset, stat, columns_list=nil, se_grid_action_columns=nil, multi_sel=nil, grid_configs=nil)
    if columns_list && columns_list.length - columns_list.uniq.length > 4
      columns_list = columns_list.uniq # JS workaround for UNION queries...
    end
    if grid_configs && grid_configs['column_widths']
      column_widths = grid_configs['column_widths']
    else
      column_widths = {}
    end
    if grid_configs && grid_configs['column_captions']
      column_captions = grid_configs['column_captions']
    else
      column_captions = {}
    end
    if grid_configs && grid_configs['data_types']
      data_types = grid_configs['data_types']
    else
      data_types = {}
    end
    if grid_configs && grid_configs['formats']
      formats = grid_configs['formats']
    else
      formats = {}
    end
    if grid_configs && grid_configs['hidden']
      hidden = grid_configs['hidden']
    else
      hidden = {}
    end
    if grid_configs && grid_configs['colour_rules']
      colour_rules = grid_configs['colour_rules']
    else
      colour_rules = {}
    end

    column_configs = Array.new
    keys = recordset[0].keys
    column_index = 0
    #session = recordset.session
    if (columns_list != nil && columns_list.length > 0) && (stat.to_s.upcase().index("SUM(") == nil && stat.to_s.upcase().index("COUNT(") == nil && stat.to_s.upcase().index("AVG(") == nil && stat.to_s.upcase().index("MAX(") == nil && stat.to_s.upcase().index("MIN(") == nil )  #&& stat.to_s.upcase.index("JOIN ") == nil)
      columns_list.each do |col|
        if col.index(".")
          col = col.split(".")[1].strip()
        end
        column_configs[column_index] = {:field_type=>'text', :field_name=>col.to_s.strip}
        column_configs[column_index][:column_width]   = column_widths[col.to_s.strip] if column_widths[col.to_s.strip]
        column_configs[column_index][:data_type]      = data_types[col.to_s.strip] if data_types[col.to_s.strip]
        column_configs[column_index][:column_caption] = column_captions[col.to_s.strip] if column_captions[col.to_s.strip]
        column_configs[column_index][:format]         = formats[col.to_s.strip] if formats[col.to_s.strip]
        column_configs[column_index][:colour_rules]   = colour_rules[col.to_s.strip] if colour_rules[col.to_s.strip]
        column_configs[column_index][:hide]           = true if hidden[col.to_s.strip]
        column_index += 1
      end
    else
      if columns_list.nil? || columns_list.empty?
        keys.each do |key|
          column_configs << {:field_type => 'text', :field_name => key.to_s}
          column_configs.last[:column_width]   = column_widths[key.to_s] if column_widths[key.to_s]
          column_configs.last[:data_type]      = data_types[key.to_s] if data_types[key.to_s]
          column_configs.last[:column_caption] = column_captions[key.to_s] if column_captions[key.to_s]
          column_configs.last[:format]         = formats[key.to_s] if formats[key.to_s]
          column_configs.last[:colour_rules]   = colour_rules[key.to_s] if colour_rules[key.to_s]
          column_configs.last[:hide]           = true if hidden[key.to_s]
        end
      else
        # Try to manage aggregate queries and non-active record datasets in a reasonable manner
        temp   = (0..columns_list.length-1).map {|n| nil}
        fields = keys
        columns_list.each_with_index do |col, index|
          if fields.delete(col).nil?  # The column might not match exactly in the dataset - e.g. Count(id)
            col = col.split(' ').last # FieldExtractor can sometimes munge column names for joined queries. Should ideally fix at source.
            next if fields.delete(col).nil?
          end
          temp[index] = {:field_type => 'text', :field_name => col.to_s.strip}
          bare_col = col.split('.').last.strip.split(' ').last
          temp[index][:column_width]   = column_widths[bare_col]   if column_widths[bare_col]
          temp[index][:data_type]      = data_types[bare_col]      if data_types[bare_col]
          temp[index][:column_caption] = column_captions[bare_col] if column_captions[bare_col]
          temp[index][:format]         = formats[bare_col]         if formats[bare_col]
          temp[index][:colour_rules]   = colour_rules[bare_col]    if colour_rules[bare_col]
          temp[index][:hide]           = true                      if hidden[bare_col]
        end
        # Go through all the fields in the dataset that were not matched in the columns list and place them
        # in the array in a first-come-first-served manner.
        fields.each do |key|
          index = temp.index( nil )
          temp[index] = {:field_type => 'text', :field_name => key.to_s}
          temp[index][:column_width]   = column_widths[key.to_s] if column_widths[key.to_s]
          temp[index][:data_type]      = data_types[key.to_s] if data_types[key.to_s]
          temp[index][:column_caption] = column_captions[key.to_s] if column_captions[key.to_s]
          temp[index][:format]         = formats[key.to_s] if formats[key.to_s]
          temp[index][:colour_rules]   = colour_rules[key.to_s] if colour_rules[key.to_s]
          temp[index][:hide]           = true if hidden[key.to_s]
        end
        # Update the column_configs with the (hopefully) correctly-sequenced columns.
        temp.each {|t| column_configs << t }
      end
    end

    if dm_session[:full_parameter_query] &&  (dm_session[:functions] == nil || dm_session[:functions] == "")  #dm_session[:full_parameter_query].upcase.index(" GROUP BY ")
      if (columns_list && columns_list.include?( 'id') && recordset[0]['id'].is_numeric? && !recordset[0]['id'].include?('_'))
        column_configs[column_configs.length()] = {:field_type=>'action', :field_name=>'view_details', :column_width => 120,
          :settings=>{:link_text=>'view details',
            :target_action=>'view_details',
            :id_column=>'id'}}
      end
    end


    if se_grid_action_columns != nil && se_grid_action_columns.length > 0
      se_grid_action_columns.each do |action_column|
        field_name = action_column[:field_name]
        target_action = action_column[:target_action]
        #puts target_action.to_s
        id_column = action_column[:id_column]
        if action_column[:link_text] != nil
          column_configs[column_configs.length()] = {:field_type=>'action', :field_name=>field_name,
            :settings=>{:link_text=>action_column[:link_text].to_s,
              :target_action=>target_action.to_s,
              :id_column=>id_column.to_s
          }}
        elsif action_column[:image] != nil
          column_configs[column_configs.length()] = {:field_type=>'action', :field_name=>field_name,
            :settings=>{:image=>action_column[:image],
              :target_action=>target_action,
              :id_column=>id_column
          }}
        else
          column_configs[column_configs.length()] = {:field_type=>'action', :field_name=>field_name,
            :settings=>{
            :target_action=>target_action,
            :id_column=>id_column
          }}
        end
      end
    end

    # Get any other datagrid options from the grid_configs...
    opts = build_grid_options_from_grid_configs(grid_configs)

    get_data_grid(recordset,column_configs,nil,true, nil, opts)
  end

  # Examine the grid_configs hash and extract options to pass on to the grid constructor.
  def build_grid_options_from_grid_configs(grid_configs={})
    opts = {}
    if grid_configs
      opts[:caption]               = grid_configs['caption']               if grid_configs['caption']
#      opts[:no_of_frozen_cols]     = grid_configs['no_of_frozen_cols']     if grid_configs['no_of_frozen_cols']
#      opts[:group_summary_depth]   = grid_configs['group_summary_depth']   if grid_configs['group_summary_depth']
      opts[:groupable_fields]      = grid_configs['groupable_fields']      || []
      opts[:group_fields_to_sum]   = grid_configs['group_fields_to_sum']   || []
      opts[:group_fields_to_count] = grid_configs['group_fields_to_count'] || []
      opts[:group_fields_to_avg]   = grid_configs['group_fields_to_avg']   || []
      opts[:group_fields_to_max]   = grid_configs['group_fields_to_max']   || []
      opts[:group_fields_to_min]   = grid_configs['group_fields_to_min']   || []
#      opts[:group_headers]         = grid_configs['group_headers']         || []
#      opts[:group_headers_colspan] = grid_configs['group_headers_colspan'] || false
      opts[:group_fields]          = grid_configs['group_fields']          || []
      opts[:grouped]               = grid_configs['grouped']               || false
    end
    opts
  end


  # Add columns to column_configs based on a column list or the keys of the dataset.
  # Applies grid_configs such as column width, data type and caption.
  # Pass in the dataset, the column configs array, the query statement, columns list and grid configs.
  def build_generic_column_configs(data_set, column_configs, stat, columns_list, grid_configs=nil)

    if grid_configs && grid_configs['column_widths']
      column_widths = grid_configs['column_widths']
    else
      column_widths = {}
    end
    if grid_configs && grid_configs['column_captions']
      column_captions = grid_configs['column_captions']
    else
      column_captions = {}
    end
    if grid_configs && grid_configs['data_types']
      data_types = grid_configs['data_types']
    else
      data_types = {}
    end
    if grid_configs && grid_configs['formats']
      formats = grid_configs['formats']
    else
      formats = {}
    end
    if grid_configs && grid_configs['hidden']
      hidden = grid_configs['hidden']
    else
      hidden = {}
    end
    if grid_configs && grid_configs['colour_rules']
      colour_rules = grid_configs['colour_rules']
    else
      colour_rules = {}
    end

    if (columns_list != nil && columns_list.length > 0) &&
      (stat.to_s.upcase().index("SUM(")   == nil &&
       stat.to_s.upcase().index("COUNT(") == nil &&
       stat.to_s.upcase().index("AVG(")   == nil &&
       stat.to_s.upcase().index("MAX(")   == nil &&
       stat.to_s.upcase().index("MIN(")   == nil)
      columns_list.each do |col|
        column_configs << {:field_type => 'text', :field_name => col.to_s.strip}
        bare_col = col.split('.').last.strip.split(' ').last
        column_configs.last[:column_width]   = column_widths[bare_col]   if column_widths[bare_col]
        column_configs.last[:data_type]      = data_types[bare_col]      if data_types[bare_col]
        column_configs.last[:column_caption] = column_captions[bare_col] if column_captions[bare_col]
        column_configs.last[:format]         = formats[bare_col]         if formats[bare_col]
        column_configs.last[:colour_rules]   = colour_rules[bare_col]    if colour_rules[bare_col]
        column_configs.last[:hide]           = true                      if hidden[bare_col]
      end
    else
      if columns_list.nil?
        data_set[0].keys.each do |key|
          column_configs << {:field_type => 'text', :field_name => key.to_s}
          column_configs.last[:column_width]   = column_widths[key.to_s] if column_widths[key.to_s]
          column_configs.last[:data_type]      = data_types[key.to_s] if data_types[key.to_s]
          column_configs.last[:column_caption] = column_captions[key.to_s] if column_captions[key.to_s]
          column_configs.last[:format]         = formats[key.to_s] if formats[key.to_s]
          column_configs.last[:colour_rules]   = colour_rules[key.to_s] if colour_rules[key.to_s]
          column_configs.last[:hide]           = true if hidden[key.to_s]
        end
      else
        # Try to manage aggregate queries and non-active record datasets in a reasonable manner
        temp   = (0..columns_list.length-1).map {|n| nil}
        if data_set.empty?
          temp = columns_list.map {|c| c }
        else
          fields = data_set[0].keys
          columns_list.each_with_index do |col, index|
            if fields.delete(col).nil?  # The column might not match exactly in the dataset - e.g. Count(id)
              col = col.split(' ').last # FieldExtractor can sometimes munge column names for joined queries. Should ideally fix at source.
              next if fields.delete(col).nil?
            end
            temp[index] = {:field_type => 'text', :field_name => col.to_s.strip}
            bare_col = col.split('.').last.strip.split(' ').last
            temp[index][:column_width]   = column_widths[bare_col]   if column_widths[bare_col]
            temp[index][:data_type]      = data_types[bare_col]      if data_types[bare_col]
            temp[index][:column_caption] = column_captions[bare_col] if column_captions[bare_col]
            temp[index][:format]         = formats[bare_col]         if formats[bare_col]
            temp[index][:colour_rules]   = colour_rules[bare_col]    if colour_rules[bare_col]
            temp[index][:hide]           = true                      if hidden[bare_col]
          end
          # Go through all the fields in the dataset that were not matched in the columns list and place them
          # in the array in a first-come-first-served manner.
          fields.each do |key|
            index = temp.index( nil )
            temp[index] = {:field_type => 'text', :field_name => key.to_s}
            temp[index][:column_width]   = column_widths[key.to_s] if column_widths[key.to_s]
            temp[index][:data_type]      = data_types[key.to_s] if data_types[key.to_s]
            temp[index][:column_caption] = column_captions[key.to_s] if column_captions[key.to_s]
            temp[index][:format]         = formats[key.to_s] if formats[key.to_s]
            temp[index][:colour_rules]   = colour_rules[key.to_s] if colour_rules[key.to_s]
            temp[index][:hide]           = true if hidden[key.to_s]
          end
        end
        # Update the column_configs with the (hopefully) correctly-sequenced columns.
        temp.each {|t| column_configs << t }
      end
    end

  end


    # Display a dataminer grid without any actions. Actions can be included if they have been placed in the session.
    # Pass a grid plugin class to instantiate that plugin for the grid.
    def build_standard_dm_grid(data_set, stat, columns_list, can_edit, can_delete, grid_configs, grid_plugin_class=nil)

      grid_plugin = grid_plugin_class.nil? ? nil : grid_plugin_class.new

      column_configs = []

      if session[:std_grid_actions]
        column_configs << {:field_type => 'action_collection',
                           :field_name => 'actions',
                           :settings   => {:actions => session[:std_grid_actions]}}
        session[:std_grid_actions] = nil
      end

      # Build all other columns from the dataminer yml file.
      build_generic_column_configs(data_set, column_configs, stat, columns_list, grid_configs)

      # Get any other datagrid options from the grid_configs...
      opts = build_grid_options_from_grid_configs(grid_configs)

      get_data_grid(data_set, column_configs, grid_plugin, true, nil, opts)
    end


  def build_lookups_grid(recordset,select_column_name,looked_up_field,submit_to=nil)
    column_configs = Array.new
    keys = recordset[0].keys

    looked_up_field = looked_up_field + "&submit_to=#{submit_to}" if(submit_to)
    column_configs << {:field_type => 'action',:field_name => 'select',
			:settings =>
				 {:link_text => 'select',
				:target_action => 'submit_looked_up_selection',
				:id_column => select_column_name,
				:name_id_as_key => true,
        :id_value=>looked_up_field}}

    keys.each do |key|
       column_configs << {:field_type=>'text', :field_name=>key.to_s}
    end

    return get_data_grid(recordset,column_configs,nil,true)

  end

  #*******************************
  #****** PdtLogs and PdtErrors **
  #*******************************
  def build_field(type,value,options={})
   case type
     when 'drop_down'
       width = "width: #{options['width']}px;" if(options['width'])
       return "<select style=\"#{width}\">
                  <option>#{value}</option>
               </select>"
     when 'text_box'
       return "<input style=\"\" type=\"text\" value=\"#{value}\"/>"
     when 'check_box'
       return "<input checked=\"checked\" type=\"checkbox\"/>" if(value.to_s == "true")
       return "<input type=\"checkbox\"/>" if(value.to_s == "false")
     when 'text_line'
       return "<label>#{value}<label/>"
     when 'static_text'
       return "<label>#{value}<label/>"
   end
 end

  def maximise_window_screen
    "<script type=\"text/javascript\">
      window.moveTo(0,0);
      window.resizeTo(screen.availWidth,screen.availHeight);
    </script>"
  end

  def build_intake_email_logs_trail_grid(email_logs)
#    require File.dirname(__FILE__) + "/../../app/helpers/inventory/intake_header_plugins.rb"
    column_configs = Array.new
    ["attachment_content","process_name","status_code","created_on","alert_code","recipients","message","subject","attachment_path"].each do |key|
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => key.to_s}
    end

    #return get_data_grid(email_logs, column_configs,IntakeHeaderPlugins::IntakesEmailLogsGridPlugin.new(self,request),true)
    return get_data_grid(email_logs, column_configs,nil,true)
  end

  def build_missing_mf_records_grid(records)
    column_configs = Array.new

    records[0].keys.each do |key|
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => key.to_s} if(key != 'id' && key != 'dependent_fields')
    end

    column_configs << {:field_type => 'link_window', :field_name => 'view_mf_record',
                                             :settings =>
                                             {:link_text => 'view',
                                              :target_action => 'view_mf_record',
                                              :id_column => 'record_id',
                                              :window_width =>1100,
                                              :window_height =>650}}

    @multi_select = "create_missing_master_file" if(@is_select_missing_mf)

    return get_data_grid(records, column_configs,nil,true)
  end

  def build_manage_missing_mf_grid(missing_mfs)
    column_configs = Array.new

    missing_mfs[0].keys.each do |key|
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => key.to_s} if(key != 'id' && key != 'dependent_fields'  && key != 'extra_look_up_fields')
    end

    column_configs << {:field_type => 'link_window', :field_name => 'view_mf_records',
                                             :settings =>
                                             {:link_text => 'view',
                                              :target_action => 'view_mf_records',
                                              :id_column => 'id',
                                              :window_width =>1100,
                                              :window_height =>650}}

    @multi_select = @action if(@is_select_missing_mf)

    return get_data_grid(missing_mfs, column_configs,IntakeHeaderPlugins::MissingMasterFilesGridPlugin.new,true)
# TOBECOME:    get_data_grid(missing_mfs, column_configs,MesScada::GridPlugins::Logistics::LogisticsGridPlugin.new,true)
  end

  def build_email_report_to_depot_form(process_alert_def,action,caption)

    field_configs = []

    field_configs << {:field_type=>'TextArea', :field_name=>'email_recipients'}
    field_configs << {:field_type=>'TextArea', :field_name=>'email_message'}

    build_form(process_alert_def,field_configs,action,'process_alert_definition',caption)
  end

  def build_printer_selection_form( printer_type )

    printers         = Printer.find(:all,:conditions=>"print_service='Jasper'").map { |p| [p.friendly_name] }
    printer_type_key = printer_type.to_sym
    @printer         = Printer.new

    field_configs    = Array.new

    if session[printer_type_key]
      printer                = Printer.find_by_system_name(session[printer_type_key])
      @printer.friendly_name = printer.friendly_name
    end

    field_configs << {:field_type => 'HiddenField',
                      :field_name => 'printer_type',
                      :settings => {:hidden_field_data => printer_type}}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'friendly_name',
                      :settings => {:list => printers}}

    build_form(@printer, field_configs, 'set_printer_submit', 'printer', 'save')

  end


  # Make a lookup link to a dataminer report. For use in views.
  # Options:
  # lookup_search_file::     Dataminer yml file to use for lookup (without .yml extension).
  # select_column_name::     Column to return from dataminer query.
  # active_record_var_name:: Singular form of model's table name.
  # looked_up_field::        Field name in the view (i.e. model_name_attribute_name)
  # send_fields::            OPTIONAL.
  def make_lookup_link(options)
    send_fields = options.delete(:send_fields)
    if send_fields.nil?
      on_click = 'javascript:parent.call_open_window(this);'
    else
      on_click = "javascript:send_fields_to_popup_window(this,&quot;#{send_fields}&quot;);"
    end
    url = "#{request.host_with_port}/reports/reports/launch_lookup_form?#{options.map {|k,v| "#{k}=#{v}" }.join('&amp;')}"
    link_to('lookup', '#',
            :id      => url,
            :onclick => on_click,
            :style   => 'text-decoration:underline;cursor:pointer;padding-bottom:2px')
  end

  # Return a String format of a floating point number with commas and two decimals.
  def two_decimals(f)
    sprintf('%.2f', f).gsub(/(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/, '\1,\2')
  end

  def expand_and_collapse_all_collapses
    "<div class='collapseAlls'>
      #{content_tag(:p, link_to('expand all', '#', :class => 'stdlink expand_all_collapses'))}
      #{content_tag(:p, link_to('collapse all', '#', :class => 'stdlink collapse_all_collapses'))}
    </div>"
  end

  # Helper for forms that need to fill in either org or person.
  def org_or_person_for_form(model, show_hide_url, is_edit, is_create_retry, autocomplete_url=nil)
    party_types    = [[Party::ORGANIZATION],[Party::PERSON]]
    default_is_org = true

    if model && model.parties_role_id
      parties_role   = model.populate_virtual_attrs
      party_types    = [parties_role.party_type_name]
      default_is_org = party_types.first == Party::ORGANIZATION
    elsif is_create_retry
      default_is_org = model.party_type_name == Party::ORGANIZATION
    end

    field_configs = []

    if is_edit
      # Show as labels
      field_configs << {:field_type => 'LabelField', :field_name => 'party_type_name', :settings => {:label_caption => 'party type'}}

      if default_is_org
        field_configs << {:field_type => 'LabelField', :field_name => 'organisation_name'}
      else
        field_configs << {:field_type => 'LabelField', :field_name => 'first_name'}
        field_configs << {:field_type => 'LabelField', :field_name => 'last_name'}
      end
    else
      field_configs << {:field_type => 'DropDownField',
        :field_name => 'party_type_name',
        :settings => {:list => party_types, :no_empty => true, :label_caption => 'party type',
                      :html_opts => {'data-url' => show_hide_url,
                      #:html_opts => {'data-url' => "http://#{request.host_with_port}/party_manager/customer/show_hide_person_org",
                      :class => 'select_observable'}}}

      if default_is_org
        field_configs << {:field_type => 'TextField',
          :field_name => 'organisation_name',
          :settings => { :label_css_class => 'org_type', :autocomplete_url => autocomplete_url}}

        field_configs << {:field_type => 'TextField',
          :field_name => 'first_name',
          :settings => { :html_opts => {:style => 'display:none'}, :label_css_class => 'person_type hide_me'}}

        field_configs << {:field_type => 'TextField',
          :field_name => 'last_name',
          :settings => { :html_opts => {:style => 'display:none'}, :label_css_class => 'person_type hide_me'}}
      else
        field_configs << {:field_type => 'TextField',
          :field_name => 'organisation_name',
          :settings => { :html_opts => {:style => 'display:none'}, :label_css_class => 'org_type hide_me'}}

        field_configs << {:field_type => 'TextField',
          :field_name => 'first_name',
          :settings => { :label_css_class => 'person_type'}}

        field_configs << {:field_type => 'TextField',
          :field_name => 'last_name',
          :settings => { :label_css_class => 'person_type'}}
      end
    end

    field_configs
  end

  def show_boolean(val)
    if val
      '<span class="bool_check"></span>'
    else
      '<span class="bool_uncheck"></span>'
    end
  end

  # Format help text for display in a form.
  # Use like this:
  #
  # field_configs << help_block(str)
  #
  # - where str contains whatever string you want to display (can be formatted using HTML).
  def help_block(help_text)
    show_hide = %Q|</table>
    <a href="#" onclick="var ht = document.getElementById('help_text'); if(ht.style.display === 'none') { ht.style.display = 'block';ht.text = 'Hide';} else {ht.style.display = 'none';};return false"><img src="/images/info.png" style="vertical-align:text-bottom"> Toggle help text</a>
    <div id="help_text" style="display : none;background-color:aliceblue;">#{help_text}</div><table>|

    {:field_type => 'LabelField',
     :field_name => 'ht',
     :settings   => {:static_value => show_hide,
                     :non_dbfield  => true,
                     :show_label   => false,
                     :css_class    => 'unbordered_label_field'}}
  end

end
