class Services::PdtController < ApplicationController

  session :off

  def program_name?
    "pdt"
  end

  def bypass_generic_security?
    true
  end

  #------------------------------------------------------------------------------------
  # this method checks if all the required inputs are entered and in the correct format
  #------------------------------------------------------------------------------------
  def valid_inputs?()
    supported_modes = "0123456789101112131415"
    pattern = /#{@mode}/
    valid = (pattern =~ supported_modes)
    @field_configs = Array.new
    if !@mode ||(@mode && @mode.strip == "")
      #@input_errors.push("MODE ERROR: NO MODE SPECIFIED")
      @field_configs[@field_configs.length] = "MODE ERROR: NO MODE SPECIFIED"
    end

    if (valid == nil)
      #@input_errors.push("MODE ERROR: UNSUPPORTED MODE: " + @mode)
      @field_configs[@field_configs.length] = "MODE ERROR: UNSUPPORTED MODE = " + @mode
    end

    if !@input_xml ||(@input_xml && @input_xml.strip == "")
      #@input_errors.push("INPUT ERROR: NO INPUT SPECIFIED")
      @field_configs[@field_configs.length] = "INPUT ERROR: NO INPUT SPECIFIED"
    end

    if !@user||(@user && @user.strip == "")
      #@input_errors.push("USER ERROR: NO USER SPECIFIED")
      @field_configs[@field_configs.length] = "USER ERROR: NO USER SPECIFIED"
    end

    if !@ip ||(@ip && @ip.strip == "")
      #@input_errors.push("IP ERROR: NO IP SPECIFIED")
      @field_configs[@field_configs.length] = "IP ERROR: NO IP SPECIFIED"
    end

    if !@menu_item ||(@menu_item && @menu_item.strip == "")
      #@input_errors.push("MENU ITEM ERROR: NO MENU ITEM SPECIFIED")
      @field_configs[@field_configs.length] = "MENU ITEM ERROR: NO MENU ITEM SPECIFIED"
    end

    #if @field_co.size == 0
    if @field_configs.size == 0
      return true
    else
      return false
    end

  end

  def handle_pdt_exceptions
    err = $!.message.gsub("\n","")
    error_screen_definition = PdtScreenDefinition.get_pdt_error_screen(err,@pdt_method,@client_type,@mode)
    PdtScreenDefinition.log_pdt_error($!,@user,@ip,@mode,@input_xml,@menu_item)
    render_result(error_screen_definition)
  end

  def create_pdt_log(result_screen)
    #Create a Log record
    pdt_log = PdtLog.new
    pdt_log.user_name = @user
    pdt_log.created_on = Time.now
    pdt_log.ip = @ip
    pdt_log.mode = @mode.to_i
    pdt_log.input_xml = @input_xml
    pdt_log.output_xml = result_screen
    pdt_log.menu_item = @menu_item
    pdt_log.save
  end

  def pdt_error(exception)
    pdt_error = PdtError.new
    pdt_error.user_name = @user
    pdt_error.created_on = Time.now
    pdt_error.error_description = exception.to_s
    pdt_error.stack_trace = exception.backtrace.join("\n").to_s
    pdt_error.ip = @ip
    pdt_error.mode = @mode.to_i
    pdt_error.input_xml = @input_xml
    pdt_error.menu_item = @menu_item
    pdt_error.error_type = "PdtControllerError"
    pdt_error.save
  end

  def get_input_xml
    raw_xml_screen_defition = params[:input] = params[:web_pdt_screen].delete(:xml_definition)
    pdt_screen_def = PdtScreenDefinition.new(raw_xml_screen_defition, params[:menu_item], params[:mode], params[:user], params[:ip])
    params[:web_pdt_screen].keys.each do |input_control_key|
      if(raw_control = pdt_screen_def.controls.find{|c| c['name']==input_control_key.to_s})
        submitted_value = params[:web_pdt_screen][input_control_key].split('|{')[0]
        if((input_id_value = submitted_value.to_s.split('|')).length==2)
          raw_control['id_value'] = input_id_value[1]
        end
        raw_control['value'] = input_id_value[0]
      end
    end
    return pdt_screen_def.get_output_xml
  end

  def web_pdt_replace_field_search_combo_changed
    set_web_pdt_css_styles
    params[:client_type]="web"
    params[:input] = "<PDTRF></PDTRF>"
    @target_control_name = params.delete('target_control_name').gsub('web_pdt_screen_','')
    @prev_screen_xml_definition = params.delete('prev_screen_xml_definition')
    observed_field =  params.delete('observed_field')

    #===================================
    #===================================
    filter_fields = {}
    if(selected_combo_value = params.find{|k,v| v=='x'})
      selected_value = selected_combo_value[0].split('|')[0]
      params.delete(selected_value)
      params[observed_field] = selected_value

      filter_fields.store(observed_field,selected_value)
      if(selected_filter_id = selected_combo_value[0].split('|')[1])
        filter_fields.store(observed_field,selected_filter_id)
      end
    else
      render :inline=>%{}
      return
    end

    # params.delete('selected_combo_value')

    filter_fields.each do |k,v|
      params[k] = v
    end
    #===================================
    #===================================
    handle_request
  end

  def web_pdt_filter_field_search_combo_changed
    remote_list_name = params.delete('remote_list')
    observed_field =  params.delete('observed_field')
    return_column = params.delete('return_column')
    @target_control_name = params.delete('target_control_name').gsub('web_pdt_screen_','')

    filter_fields = {}
    if(selected_combo_value = params.find{|k,v| v=='x'})
      selected_value = selected_combo_value[0].split('|')[0]
      params.delete(selected_value)
      params[observed_field] = selected_value

      filter_fields.store(observed_field,selected_value)
      if(selected_filter_id = selected_combo_value[0].split('|')[1])
        filter_fields.store(observed_field,selected_filter_id)
      end
    end

    filter_fields.each do |k,v|
      params[k] = v
    end

    remote_list = eval("PdtRemoteList.#{remote_list_name}(params)")
    @list = remote_list.empty? ? [] : (remote_list[0].is_a?(Hash) ? remote_list.map{|l| l[return_column]} : remote_list.map{|l| l.attributes[return_column]})
    @list.unshift("<empty>")

#if @target_control_name had observer, create new observer and attach to @target_control_name
    render :inline => %{
		  <%= select('web_pdt_screen',@target_control_name,@list)%>
		}
  end

  def set_web_pdt_css_styles
    @web_pdt_css_styles = {}
    if request.env['HTTP_USER_AGENT'].downcase.match(/android|iphone/)
      @web_pdt_css_styles[:pdt_text_line] = "mobile_web_pdt_text_line_css_class"
      @web_pdt_css_styles[:pdt_static_text] = "mobile_web_pdt_static_text_css_class"
      @web_pdt_css_styles[:pdt_text_text_box] = "mobile_web_pdt_text_box_css_class"
      @web_pdt_css_styles[:pdt_date_field] = "mobile_web_pdt_date_field_css_class"
      @web_pdt_css_styles[:pdt_form] = "mobile_web_pdt_form_css_class"
      @web_pdt_css_styles[:pdt_drop_down] = "mobile_web_pdt_drop_down_css_class"
      @web_pdt_css_styles[:pdt_check_box] = "mobile_web_pdt_check_box_css_class"
      @web_pdt_css_styles[:pdt_text_area] = "mobile_web_text_area_css_class"

    else
      @web_pdt_css_styles[:pdt_text_line] = "pc_pdt_text_line_css_class"
      @web_pdt_css_styles[:pdt_static_text] = "pc_pdt_static_text_css_class"
      @web_pdt_css_styles[:pdt_text_text_box] = "pc_pdt_text_box_css_class"
      @web_pdt_css_styles[:pdt_date_field] = "pc_pdt_date_field_css_class"
      @web_pdt_css_styles[:pdt_form] = "pc_pdt_form_css_class"
      @web_pdt_css_styles[:pdt_check_box] = "pc_pdt_check_box_css_class"
      @web_pdt_css_styles[:pdt_text_area] = "pc_pdt_text_area_css_class"
      @web_pdt_css_styles[:pdt_drop_down] = "pc_pdt_drop_down_css_class"

    end
  end
  def handle_pdt_web_request

    set_web_pdt_css_styles

    if(params[:web_pdt_screen])

      params[:mode] = params[:web_pdt_screen].delete(:mode_submit_value)
      params[:user] = params[:web_pdt_screen].delete(:logged_on_user_submit_value)


      params[:menu_item] = params[:web_pdt_screen].delete(:web_pdt_current_menu_item_submit_value)
      params[:input] = get_input_xml

      #cascade cascade cascade cascade cascade cascade
      #cascade cascade cascade cascade cascade cascade
    else
      @client_type='web'
      render_result( "<PDTRF></PDTRF>")
      return
    end

    params[:client_type]="web"
    params[:ip] = request.remote_ip

    handle_request
  end
  #----------------------------------------
  # Handles pdt and pdt_simulator requests.
  # Public interface(http-get request with REST protocol) of the pdt server to the outside worl
  #----------------------------------------
  #Only one public - rest private
  def handle_request
    puts "Start round-trip = " + Time.now.to_s
    @client_type = params[:client_type]
    @is_rails_request = params[:is_rails_request]
    @mode = params[:mode]
    @input_xml = params[:input].to_s
    #    end
    @user = params[:user]
    @ip = params[:ip]
    @special_commands = {"1a" => "refresh", "1b" => "undo", "1c"=> "cancel", "1f"=> "redo", "1d"=> "save_process", "1e"=> "load_process", "1d.1"=> "save_process_submit", "1e.1"=> "load_process_submit", "1g"=> "exit_process", "1g.1"=> "save_process_choice_submit"}
    @instruction = nil
    @menu_item = params[:menu_item] if params[:trans_type] == nil
    @menu_item = params[:trans_type] if params[:menu_item] == nil
    @remote_method = params[:remote_method]
    @params = params
    #    params.each do |key,value|
    #      puts "Key = " + key.to_s + "   || Value = " + value.to_s
    #    end
    @jsession_store = nil
    @program = nil
    @program_function = nil
    @jsession_folder = "tmp/jsessions/"
    @jsession_store_key = @ip.to_s + "_" + @user.to_s

    puts "------------------------------------------------------------"
    puts "------------------------------------------------------------"
    puts "@input_xml i.e. Incoming xml from client = " + @input_xml.to_s
    puts "@is_rails_request = " + @is_rails_request.to_s
    puts "@mode = " + @mode.to_s
    puts "@ip = " + @ip.to_s
    puts "@menu_item = " + @menu_item.to_s
    puts "@user = " + @user.to_s
    puts "@remote_method = " + @remote_method.to_s
    puts "------------------------------------------------------------"
    puts "------------------------------------------------------------"

    begin
      #-------------------------------------------------------------------------------------------------
      # method validate_inputs() to check if all the required inputs are entered(the way they should be)
      #-------------------------------------------------------------------------------------------------
      if valid_inputs? == false
        screen_caption = "PdtFramework System exception"
        error_screen_definition = PdtScreenDefinition.send_screen(@field_configs, screen_caption, nil)
        render_result(error_screen_definition)
        return
      end

      result_screen = process_action
      if (result_screen == nil || result_screen.length == 0) && @menu_item.to_s
        if !special_command?
          raise "SYSTEM ERROR : " + @menu_item.to_s + " returned null screen"
        else
          result_screen = "<PDTRF><controls content_header_caption='no screen to show for " + @menu_item.to_s + "' ><control name='output' type='text_line' value='no screen to show' ></control></controls></PDTRF>"
        end
      end

      create_pdt_log(result_screen)

      render_result(result_screen)
    rescue
      handle_pdt_exceptions
    ensure
      ActiveRequest.clear_active_request
    end

  end

  def store_active_request

    return if special_command?

    func_area_name = FunctionalArea.find_by_functional_area_name(@program.functional_area_name).display_name
    program = func_area_name + "/" + @program.display_name
    function = @program_function.display_name if @program_function
    ActiveRequest.set_active_request(@user, program, function, "pdt")

  end

  #-----------------------------------------------
  # describes the process followed when executing
  # a request
  #-----------------------------------------------
  def process_action()
    #-----------------------------------------
    # returns an error screen definition if
    # program and program function could not
    # be retrieved
    #-----------------------------------------
    if get_program_details() != nil
      return @result
    end

    store_active_request

    #----------------------------------------
    # if program and program function were
    # retrieved successfully,check whether or
    # not they're disabled.
    #----------------------------------------
    if @pdt_method != nil #Skip this check for special commands
      if disabled? == true
        output_lines = ["INVALID. REASON: ", "PROGRAM OR PROGRAM_FUNCTION DISABLED"]
        screen_caption = ""
        @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)
        return @result
      end
    end


    get_session_store


    #-----------------------------------------
    # check if pdt_uder is allowed to use this
    # program.
    #-----------------------------------------
    if basic_authorisation != true
      return @result
    end
    #-----------------------------------------
    # checks if cancel menu was clicked
    #-----------------------------------------
    if transaction_cancelled? == true
      output_lines = ["TRANSACTION HAS BEEN CANCELLED"]
      screen_caption = ""
      @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)
      return @result
    elsif transaction_cancelled? == false
      output_lines = ["TRANSACTION CANNOT BE CANCELLED"]
      screen_caption = ""
      @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)
      return @result
    end
    #-----------------------------------------
    # checks if undo menu was clicked
    #-----------------------------------------
    if undo_called? == true
      if @jsession_store.undoable?
         @jsession_store.undo
        if @jsession_store.get_session != nil
          @result = @jsession_store.get_session[:active_screen].to_s
          if @jsession_store.get_session != nil && @jsession_store.get_session.keys.length == 0
            output_lines = ["Nothing to Undo[1]"]
            screen_caption = ""
            @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)
          end
          persist_jsession
        else
          output_lines = ["Nothing to Undo[2]"]
          screen_caption = ""
          @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)
        end
        return @result
      else
        output_lines = ["CANNOT UNDO TRANSACTION"]
        screen_caption = ""
        @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)
        return @result
      end
    else

    end

    #-----------------------------------------
    # checks if refresh menu was clicked
    #-----------------------------------------
    if refreshed_called? == true
      @jsession_store.refresh
      if (@jsession_store.get_session != nil && @jsession_store.get_session != {})
        pdt_transaction = get_transaction
        if (pdt_transaction.respond_to?('refresh'))
          # The pdt server framework deduces the menu_item to be sent back to pdt_client framework i.e. this all happens inside the PdtTransaction base class.
          # N.B. special commands are not processed by the transaction :. the menu_item is never deduced and thus stays that a special_menu_item(if one was clicked)
          #
          current_menu_item = pdt_transaction.get_current_menu_item()
          @result = pdt_transaction.refresh
#         @jsession_store.set_active_transaction(pdt_transaction)
          if (@result)
            @result.gsub!("<controls", "<controls current_menu_item='" + current_menu_item.to_s + "'") if (current_menu_item)
          else
            @result = @jsession_store.get_session[:active_screen]
          end

          if  @jsession_store != nil && @jsession_store.get_session[:active_transaction] != nil && @jsession_store.get_session[:active_transaction].is_transaction_complete == true
            @jsession_store.get_session[:active_transaction].transaction_complete
          end
        else
          @result = @jsession_store.get_session[:active_screen] #if @jsession_store.get_session != nil
        end
      end

      persist_jsession
      return @result
    end

    #-----------------------------------------
    # checks if refresh menu was clicked
    #-----------------------------------------
    if redo_called? == true
      @jsession_store.redoing
      @result = @jsession_store.get_session[:active_screen] if @jsession_store.get_session != nil

      persist_jsession
      return @result
    end

    #-----------------------------------------
    # checks if save_process menu was clicked
    #-----------------------------------------
    if save_process_called? == true
      @result = save_process()
      return @result
    end

    #-----------------------------------------
    # checks if save_submit_process button was clicked
    #-----------------------------------------
    if save_process_submit_called? == true
      @result = save_submit_process()
      return @result
    end

    #-----------------------------------------
    # checks if load_process menu was clicked
    #-----------------------------------------
    if load_process_called? == true
      @result = load_process()
      return @result
    end

    #-----------------------------------------
    # checks if load_submit_process button was clicked
    #-----------------------------------------
    if load_process_submit_called? == true
      load_submit_process()
      return @result
    end

    #-----------------------------------------
    # checks if save_process menu was clicked
    #-----------------------------------------
    if exit_process_called? == true
      @result = build_save_process_choice_screen()
      return @result
    end

    #-----------------------------------------
    # checks if save_process menu was clicked
    #-----------------------------------------
    if save_process_choice_submit_called? == true
      @result = save_process_choice_submit()
      return @result
    end

    @jsession_store.cycle

    pdt_screen_def = PdtScreenDefinition.new(@input_xml, @menu_item, @mode, @user, @ip)
    pdt_screen_def.mode = @mode
    pdt_transaction = get_transaction
    #------------------------------------
    # processes the retrieved transaction
    #------------------------------------
    result_screen = pdt_transaction.process_transaction(self, pdt_screen_def, @jsession_store, @pdt_method, @user, @params)
    #puts ".................Result screen TYPE = " + result_screen.class.name
    #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    #   if screen is packaged as hash
    #   return here - DO NOT persist to jsession
    #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    if (result_screen.kind_of?(Hash))
      if (result_screen["type"] == "error_screen")
        #        puts "#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
        #        puts "#   Error scrren found"
        #        puts "#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
        return result_screen["screen"]
      else
        result_screen = result_screen["screen"]
      end
    end
    @result = result_screen
    return @result if(@mode.to_s == PdtScreenDefinition.const_get("CONTROL_VALUE_REPLACE").to_s)
    #----------------------------------------------------------------------------------------------------------------
    # inspects the is_transaction_complete attribute of the current transaction,if there is a current transaction.If
    # if it's true,it completes the transaction.
    #----------------------------------------------------------------------------------------------------------------
    if  @jsession_store != nil && @jsession_store.get_session[:active_transaction] != nil && @jsession_store.get_session[:active_transaction].is_transaction_complete == true
      @jsession_store.get_session[:active_transaction].transaction_complete
    end
    persist_jsession

    return @result
  end

  #-------------------------------------------
  # looks up the program and program function.
  #-------------------------------------------
  def get_program_details
    #if @menu_item.length == 7
    parent_class_name = nil
    if @menu_item.occurrence_of(".") == 3
      menu_level = 3
      parts = @menu_item.split(".")
      program_name = parts[0] + "." + parts[1] + "." + parts[2]

      @program = Program.find_by_program_name(program_name)
      @program_function = ProgramFunction.find_by_name(@menu_item)

      if @program != nil && @program_function != nil
        class_name = @program_function.class_name
        class_name = @program.class_name if class_name == nil
        parent_class_name = @program.class_name
        if @mode.to_s == PdtScreenDefinition.const_get("CONTROL_VALUE_REPLACE").to_s && @remote_method != nil
          method_name = @remote_method
        else
          method_name = @program_function.display_name
        end
#        @pdt_method = PdtMethod.new(method_name,@program_function.disabled,class_name, menu_level,@program.program_name,parent_class_name)
        @pdt_method = PdtMethod.new(method_name, @program_function.disabled, class_name, menu_level, @program_function.name, parent_class_name)
      end
    else
      menu_level = 2
      @program = Program.find_by_program_name(@menu_item)
      @functional_area = FunctionalArea.find_by_functional_area_name(@program.functional_area_name) if @program != nil # **

      if @program != nil && @functional_area != nil
        class_name = @program.class_name
        class_name = @functional_area.class_name if class_name == nil
        parent_class_name = @functional_area.class_name
        if @mode.to_s == PdtScreenDefinition.const_get("CONTROL_VALUE_REPLACE").to_s && @remote_method != nil
          method_name = @remote_method
        else
          method_name = @program.display_name
        end
        @pdt_method = PdtMethod.new(method_name, @program.disabled, class_name, menu_level, @program.program_name, parent_class_name)
      end
    end
    #puts "<<<<<<<<<<<<<<<<<<<< method_name || = " + method_name.to_s
    if special_command? == false
      output_lines = ["INVALID. REASON: ", "UNKNOWN PDT FUNCTION = " + @menu_item]
      screen_caption = ""
      @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)

      return @result if @pdt_method == nil
      #return @result = PdtScreenDefinition.send_screen(true,"INVALID. REASON: ","UNKNOWN PDT FUNCTION = " + @menu_item) if @pdt_method == nil
    else
      return nil
    end

    #---------------------------------------------------
    #loads all the business classes for this transaction
    #---------------------------------------------------
    transaction_folder = Inflector.underscore(@pdt_method.class_name)
    puts " TRANS FOLDER :: " + transaction_folder.to_s
    #@pdt_method.parent_class_name = parent_class_name
    load_pdt_transaction_business_class(transaction_folder, parent_class_name) # **load_pdt_transaction_business_class(Inflector.underscore(@pdt_method.class_name).chop)
    return nil
  end

  #---------------------------------------------------------
  # check if requested program function is a special command
  #---------------------------------------------------------
  def special_command?
    if @special_commands.keys.include?(@menu_item) == false
      return false
    end
    return true
  end

  #------------------------------------------------
  # check if requested program function is disabled
  #------------------------------------------------
  def disabled?
    if @pdt_method.disabled == true
      return true
    else
      return false
    end
  end

  #-----------------------
  # returns jsession_store
  #-----------------------
  def get_session_store()
    @jsession_store = get_jsession_store
  end

  #----------------------------------------------------------------------------------------------------
  # 1. if program was retrieved successfully,checks if the user is allowed to use the requested program
  # 2. if not,checks if it is perhaps a special command(cancel).
  #-----------------------------------------------------------------------------------------------------
  def basic_authorisation()
    if @program != nil
      if basic_authorise(@program, @user) == false
        #@result = PdtScreenDefinition.send_screen(true,"INVALID. REASON: ","NO AUTHORISATION")
        output_lines = ["INVALID. REASON: ", "NO AUTHORISATION"]
        screen_caption = ""
        @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)

        return @result
      end
    else
      if @menu_item == "1.2.5" #if special command

        #------------------------------------------------------------------------
        # works out the current program i.e. the transaction that the user
        # is trying to cancel.It the checks if the user has permissions to cancel.
        # Returns true if user is successfully authorised.
        #-------------------------------------------------------------------------
        if calculate_program_name() == nil
          #@result = PdtScreenDefinition.send_screen(true,"NOTHING TO CANCEL ")
          output_lines = ["NOTHING TO CANCEL"]
          screen_caption = ""
          @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)

          return @result
        else
          program_name = calculate_program_name()
          if authorise(program_name, 'cancel', @user) == false
            #@result = PdtScreenDefinition.send_screen(true,"YOU DO NOT HAVE CANCEL PERMISSION ")
            output_lines = ["YOU DO NOT HAVE CANCEL PERMISSION "]
            screen_caption = ""
            @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)

            return @result
          end
        end
      end
    end

    return true
  end

  #---------------------------------------------------------------------------
  # retrieves the last menu request that was successfully performed by this user.
  # This is then used to get the current transaction that user is busy with.
  #---------------------------------------------------------------------------
  def calculate_program_name
    if @jsession_store.get_session != nil && @jsession_store.get_session[:active_transaction] != nil
      if @jsession_store.get_session[:active_transaction].respond_to?("get_pdt_screen_definition") == true
        return @jsession_store.get_session[:active_transaction].pdt_method.program_name.to_s
      end
    else
      i = 0
      @jsession_store.get_sessions.length.times do
        if @jsession_store.get_sessions[i] != nil && @jsession_store.get_sessions[i][:active_transaction] != nil
          if @jsession_store.get_session[:active_transaction].respond_to?("get_pdt_screen_definition") == true
            return @jsession_store.get_sessions[i][:active_transaction].pdt_method.program_name.to_s
          end
        end
        i += 1
      end
    end

    return nil
  end

  #------------------------------------------------------
  # checks if user requested to cancel transaction and if
  # transaction was actually cancelled.
  #------------------------------------------------------
  def transaction_cancelled?
    if @menu_item == "1c"
      if @jsession_store.cancelable?
        if (@jsession_store.get_session != nil && @jsession_store.get_session != {})
          pdt_transaction = get_transaction
          pdt_transaction.cancel if (pdt_transaction.respond_to?('cancel'))
        end
        @jsession_store.clear_session_session_store
        persist_jsession
        return true
      else
        return false
      end
    end

  end

  #---------------------------------------------
  # checks if user made an undo request
  #---------------------------------------------
  def undo_called?
    if @menu_item == "1b"
      return true
    else
      return false
    end
  end

  #---------------------------------------
  # checks if user made a refresh request
  #---------------------------------------
  def refreshed_called?
    if @menu_item == "1a"
      return true
    else
      return false
    end
  end

  #---------------------------------------
  # checks if user made a redo request
  #---------------------------------------
  def redo_called?
    if @menu_item == "1f"
      return true
    else
      return false
    end
  end

  #-------------------------------------------
  # checks if user made a save_process request
  #-------------------------------------------
  def save_process_called?
    if @menu_item == "1d"
      return true
    else
      return false
    end
  end

  #------------------------------
  # Builds a save_process screen
  #------------------------------
  def save_process()

    if (@jsession_store.get_session[:active_transaction] != nil)
      transaction_name = Inflector.tableize(@jsession_store.get_session[:active_transaction].class.name).chop
      #-----------------------------------------Repeated : see below --------------------
      process_number = StoredPdtProcess.find_by_sql("select max(process_number) as result_process_number from stored_pdt_processes where transaction_name='#{transaction_name}'")[0].result_process_number
      process_number = 0 if process_number == nil
      process_number = process_number.to_i + 1
      system_name = transaction_name + "_" + process_number.to_s
      #-----------------------------------------Repeated : see below --------------------

      field_configs = Array.new
      field_configs[field_configs.length] = {:type=>"static_text", :name=>"system_process_name", :label=>"system process name", :value=>system_name.to_s}
      field_configs[field_configs.length] = {:type=>"text_box", :name=>"user_process_name", :label=>"user reference"}
      buttons = {"B3Label"=>"Clear", "B2Label"=>"Cancel", "B1Label"=>"save_process", "B1Enable"=>"true", "B2Enable"=>"false", "B3Enable"=>"false"}
      screen_attributes = {:auto_submit=>"false", :content_header_caption=>"Scan full bin", :current_menu_item=>"1d.1"}
      @result = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    else
      output_lines = ["THERE IS NO PROCESS TO SAVE"]
      screen_caption = "Save Process"
      @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)
    end
  end

  #-------------------------------------------
  # checks if user made a save_process request
  #-------------------------------------------
  def save_process_submit_called?
    if @menu_item == "1d.1"
      return true
    else
      return false
    end
  end

  def save_submit_process()
    pdt_screen_def = PdtScreenDefinition.new(@input_xml, @menu_item, @mode, @user, @ip)
    system_process_name = pdt_screen_def.get_control_value("system_process_name").to_s
    user_process_name = pdt_screen_def.get_input_control_value("user_process_name").to_s
    user_process_name = system_process_name if user_process_name.strip == ""

    #-----------------------------------------Repeated : see above --------------------
    transaction_name = Inflector.tableize(@jsession_store.get_session[:active_transaction].class.name).chop
    process_number = StoredPdtProcess.find_by_sql("select max(process_number) as result_process_number from stored_pdt_processes where transaction_name='#{transaction_name}'")[0].result_process_number
    process_number = 0 if process_number == nil
    process_number = process_number.to_i + 1
    #-----------------------------------------Repeated : see above --------------------

    stored_pdt_process = StoredPdtProcess.new
    stored_pdt_process.transaction_name = transaction_name
    stored_pdt_process.user = @user
    stored_pdt_process.ip_address = @ip
    stored_pdt_process.system_process_name = system_process_name
    stored_pdt_process.user_process_name = user_process_name
    stored_pdt_process.process_number = process_number
    #--------------------------
    #jsession_store = Marshal.dump(@jsession_store)
    jsession_store = Marshal.dump(@jsession_store.get_session) #SAVE CURRENT SESSION INSTEAD

    stored_pdt_process.session_store = jsession_store
    #--------------------------

    begin
      stored_pdt_process.save!
      @jsession_store.clear_session_history
      persist_jsession
      output_lines = Array.new
      output_lines.push("Process saved successfully")
      output_lines.push("process_name = " + stored_pdt_process.user_process_name.to_s)
      screen_caption = "Process Saved"

      @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)
    rescue
      #puts $!.backtrace.join("\n").to_s
      puts $!.to_s
      raise $!
    end
  end

  #-------------------------------------------
  # checks if user made a load_process request
  #-------------------------------------------
  def load_process_called?
    if @menu_item == "1e"
      return true
    else
      return false
    end
  end

  #------------------------------
  # Builds a load_process screen
  #------------------------------
  def load_process()
    if (@jsession_store.get_session[:active_transaction] == nil)


      field_configs = Array.new
      cascades = Hash.new # CAN BE HASH i.e. when thetre's only one cascade
      cascades = {:type=>'filter',
                  :settings=>{:target_control_name=>'user_process_name', :list_field=>'user_process_name', :get_list=>'get_stored_pdt_processes_user_process_name', :filter_fields=>'transaction_name', :run_at_server=>"true"}}

      field_configs[field_configs.length] = {:type=>"drop_down", :name=>"transaction_name", :label=>"transaction name", :is_required=>'true', :get_list=>'get_stored_pdt_processes_transaction_name', :list_field=>'transaction_name',
                                             :cascades=>cascades}
      field_configs[field_configs.length] = {:type=>"drop_down", :name=>"user_process_name", :label=>"user process name", :list=>[""], :is_required=>'true'}
      buttons = {"B3Label"=>"Clear", "B2Label"=>"Cancel", "B1Label"=>"load_process", "B1Enable"=>"true", "B2Enable"=>"false", "B3Enable"=>"false"}
      screen_attributes = {:auto_submit=>"false", :content_header_caption=>"Load Process", :current_menu_item=>"1e.1"}
      @result = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
    else
      output_lines = Array.new
      output_lines.push("You're currently busy with process = " + Inflector.tableize(@jsession_store.get_session[:active_transaction].class.name).chop)
      output_lines.push("First complete or save this before loading another process")
      screen_caption = "Load Process"
      @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)
    end
  end

  #-------------------------------------------
  # checks if user made a load_process request
  #-------------------------------------------
  def load_process_submit_called?
    if @menu_item == "1e.1"
      return true
    else
      return false
    end
  end

  def load_submit_process()
    pdt_screen_def = PdtScreenDefinition.new(@input_xml, @menu_item, @mode, @user, @ip)
    transaction_name = pdt_screen_def.get_input_control_value("transaction_name").to_s
    user_process_name = pdt_screen_def.get_input_control_value("user_process_name").to_s
    stored_pdt_process = StoredPdtProcess.find_by_sql("select * from stored_pdt_processes where stored_pdt_processes.transaction_name='#{transaction_name}' and stored_pdt_processes.user_process_name='#{user_process_name}'")[0]
    stored_processes_session_store = stored_pdt_process.session_store

    begin
      #@jsession_store = Marshal.load(stored_processes_session_store)
#      @jsession_store = JSessionStore.new(@ip,persisted_lists_folder)
      puts "PITSO : " + @jsession_store_key.to_s
      @jsession_store = JSessionStore.new(@jsession_store_key, persisted_lists_folder)
      @jsession_store.set_active_session(Marshal.load(stored_processes_session_store))
      persist_jsession
      @jsession_store.refresh
      @result = @jsession_store.get_session[:active_screen] if @jsession_store.get_session != nil

      stored_pdt_process.destroy
    rescue
      raise $!
    end
  end

  #-------------------------------------------
  # checks if user made a exit_process request
  #-------------------------------------------
  def exit_process_called?
    if @menu_item == "1g"
      return true
    else
      return false
    end
  end

  #-------------------------------------------
  # checks if user has decided to save process
  # before exiting it
  #-------------------------------------------
  def save_process_choice_submit_called?
    if @menu_item == "1g.1"
      return true
    else
      return false
    end
  end

  #------------------------------------------------------------
  # screen for user to choose if they want to save the process
  # before exiting it or not
  #------------------------------------------------------------
  def build_save_process_choice_screen
    field_configs = Array.new
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=>"Do you want to save the process"}
    field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=>"before you exit it?"}

    buttons = {"B3Label"=>"", "B2Submit"=>"no", "B2Label"=>"no", "B1Submit"=>"yes", "B1Label"=>"yes", "B1Enable"=>"true", "B2Enable"=>"true", "B3Enable"=>"false"}
    screen_attributes = {:auto_submit=>"false", :content_header_caption=>"exit process?", :current_menu_item=>"1g.1"}
    @result = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, nil)
  end


  def save_process_choice_submit
    pdt_screen_def = PdtScreenDefinition.new(@input_xml, @menu_item, @mode, @user, @ip)
    if pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("BUTTON1").to_s
      @result = save_process()
    elsif pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("BUTTON2").to_s
      @jsession_store.clear_session_history
      persist_jsession
      output_lines = Array.new
      output_lines.push("Process exited successfully")
      screen_caption = "Process exited"

      @result = PdtScreenDefinition.send_screen(output_lines, screen_caption, nil)
    else
    end
  end


  #-------------------------------------------
  # works out the transaction to be processed.
  #-------------------------------------------
  def get_transaction
    if @jsession_store.get_session != nil && @jsession_store.get_session[:active_transaction] != nil
      return @jsession_store.get_session[:active_transaction]
    else

      if ! @pdt_method
        @jsession_store.clear_session_session_store

        raise "The current or last clicked menu item contains an incorrect security entry. Please correct it."
      end

      if @pdt_method && @pdt_method.class_name != nil && @pdt_method.class_name.strip != ""
        class_name = @pdt_method.class_name # + ".new"
      elsif(@pdt_method && @pdt_method.parent_class_name)
        class_name = @pdt_method.parent_class_name # + ".new"
      end


      raise "Security model exception: class_name or parent_class_name must be defined(menu_item: " + @menu_item + ")" if class_name == nil

      begin_exception_handler = " begin \n "
      end_exception_handler = "\n rescue \n  raise 'could not get transaction " + class_name.to_s + "' \n end"
      new_transation = begin_exception_handler + class_name.to_s + ".new" + end_exception_handler

      transaction = eval(new_transation)
      #      transaction = eval(class_name)ver
      return transaction
    end
  end

  #---------------------------------------------
  # action to render the output to the
  # client(pdt response) i.e. either pdt or simulator.
  #---------------------------------------------
  def render_result(result)
    @result = result.to_s
    puts "======================================================================"
    puts "======================================================================"
    puts @result.to_s
    puts "======================================================================"
    puts "End round-trip = " + Time.now.to_s
    if(@result.include?('<error>'))
      @msg = @result.gsub("<error>",'').gsub("</error>",'').gsub("\n",'')
      render :inline => %{
      <script>
        var messages = parent.document.getElementById('messages');
        messages.value = "<%=@msg%>";
      </script>
      }
      return
    end

    if(@client_type=='web' && @mode==PdtScreenDefinition.const_get("CONTROL_VALUE_REPLACE").to_s)
      @result = "<PDTRF Status='true' Msg='' B3Label='' B1Enable='false' B1Label='' B2Enable='false' B2Label='' B3Enable='false'>#{@result}</PDTRF>"
      @pdt_screen_def = PdtScreenDefinition.new(@result, @menu_item, @mode, @user, @ip)
      @prev_pdt_screen_def = PdtScreenDefinition.new(@jsession_store.get_session[:active_screen].to_s, nil, nil, @user, @ip)

      @pdt_screen_def.controls.each do |new_cntrl|
        prev = @prev_pdt_screen_def.controls.find{|prev_cntrl| prev_cntrl['name'] == new_cntrl['name']}
        replacement_index = @prev_pdt_screen_def.controls.index(prev)
        @prev_pdt_screen_def.controls[replacement_index] = new_cntrl
      end

      @xml_definition = @prev_pdt_screen_def.get_output_xml

# NB if targ_field id label/cell : must reconstruct cascades

      render :inline => %{
          <script>
            var messages = parent.document.getElementById('messages');
            messages.value = "";
          </script>

          <%
            field_configs = generate_web_pdt_field_configs(@pdt_screen_def,@web_pdt_css_styles,@prev_pdt_screen_def)
            targ_cont_config = @pdt_screen_def.controls.find{|cont| cont['name'] == @target_control_name}
            target_control_config = field_configs.find{|field_config|field_config[:field_name] == @target_control_name}
            field_configs.delete(target_control_config)
            @target_control = generate_control_to_be_replaced(target_control_config,targ_cont_config,@web_pdt_css_styles)

          %>

          <script>
            var xml_definition = document.getElementById('web_pdt_screen_xml_definition');
            xml_definition.value = "<%=@xml_definition%>";
          </script>

          <%= @target_control.build_control + generate_cascade_observer_img(target_control_config).to_s   %>
          <%= eval generate_cascade_observer(target_control_config)%>

          <script>
            var replace_control = document.getElementById('web_pdt_screen_<%=targ_cont_config['name']%>');
            if(replace_control != null) {
              replace_control.setAttribute("class","<%=@replace_control_css_class%>");
            }

          </script>

          <%field_configs.each do |rep_cntrl_config| %>

              <%cont_config = @pdt_screen_def.controls.find{|cont| cont['name'] == rep_cntrl_config[:field_name]} %>
              <%rep_cntrl = generate_control_to_be_replaced(rep_cntrl_config,cont_config,@web_pdt_css_styles) %>

              <script>
                <%= update_element_function(
                    rep_cntrl_config[:field_name]+"_cell", :action => :update,
                    :content => rep_cntrl.build_control  + generate_cascade_observer_img(rep_cntrl_config).to_s ) %>
                <%= eval generate_cascade_observer(rep_cntrl_config)%>

                var replace_control = document.getElementById('web_pdt_screen_<%=cont_config['name']%>');
                if(replace_control != null) {
                  replace_control.setAttribute("class","<%=@replace_control_css_class%>");
                }
               </script>
           <% end %>
      }, :layout => 'content'
    elsif(@client_type=='web')
      @pdt_screen_def = PdtScreenDefinition.new(@result, @menu_item, @mode, @user, @ip)
      @no_buttons = (@pdt_screen_def.buttons == nil)
      @buttons_active = (@pdt_screen_def.buttons['B1Enable'] == 'true' || @pdt_screen_def.buttons['B2Enable'] == 'true' || @pdt_screen_def.buttons['B3Enable'] == 'true') ? true : false
      required_fields = @pdt_screen_def.controls.find_all{|cont| cont.keys.include?('is_required') && cont['is_required']=='true'}
      @required_fields_js = "[]"
      @required_fields_js = "['web_pdt_screen_#{required_fields.map{|f| f['name']}.join("' ,'web_pdt_screen_")}']" if(required_fields.length > 0)

      @is_unexpected_error_screen = false
      render :inline => %{
        <script>
            var messages = parent.document.getElementById('messages');
            messages.value = "";
        </script>

        <script type="text/javascript">
          var required_fields = <%=@required_fields_js%>;

          function enterScreenSubmitClicked(evt) {
            var evt = (evt) ? evt : ((event) ? event : null);
            var node = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);

            if ((evt.keyCode == 13) && (node.type=="text"))  {
              parent.submitWebPdtScreen('enter');
              return false;
            }
          }

          function stopRKey(evt) {
            var evt = (evt) ? evt : ((event) ? event : null);
            var node = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);

            if ((evt.keyCode == 13) && (node.type=="text"))  {
              return false;
            }
          }

          <% if(@buttons_active) %>
            document.onkeypress = stopRKey;
          <% else %>
            document.onkeypress = enterScreenSubmitClicked;
          <% end %>
        </script>




        <%= build_web_pdt_screen(@pdt_screen_def,@web_pdt_css_styles) %>



        <script>

          <% @no_buttons = '@is_unexpected_error_screen.to_s' == 'true' %>

          var butt=document.getElementById('submit_button');
          butt.parentNode.style.visibility = 'hidden';

          var xml_definition = document.getElementById('web_pdt_screen_xml_definition');
          xml_definition.value = "<%=@result%>";

          var content_header_caption = parent.document.getElementById('pdt_content_header_caption');
          content_header_caption.innerHTML= "<%=@pdt_screen_def.screen_attributes['content_header_caption']%>";

          var current_menu_item = document.getElementById('web_pdt_screen_web_pdt_current_menu_item_submit_value');
          current_menu_item.value= "<%=@pdt_screen_def.screen_attributes['current_menu_item']%>";

          var logged_on_user = document.getElementById('web_pdt_screen_logged_on_user_submit_value');
          logged_on_user.value= "<%=params[:user]%>";

          var deafault_mode = document.getElementById('web_pdt_screen_mode_submit_value');
          deafault_mode.value= "1"; //enter_submit mode

          var messages = parent.document.getElementById('messages');
          messages.value = "";

          document.getElementsByTagName('form')[0].className = "<%=@web_pdt_css_styles[:pdt_form]%>";

          if("<%=@is_unexpected_error_screen%>" != 'true') {
            var button1 = parent.document.getElementById('submit_button1');
            var button2 = parent.document.getElementById('submit_button2');
            var button3 = parent.document.getElementById('submit_button3');
            if('<%=@no_buttons%>' == 'false') {
              button1.innerText = "<%=@pdt_screen_def.buttons['B1Label']%>";
              if("<%=@pdt_screen_def.buttons['B1Enable']%>" == 'true') {
                button1.style.visibility='visible';
                button1.disabled = false;
              } else {
                button1.disabled = true;
                button1.style.visibility='hidden';
              }

              button2.innerText = "<%=@pdt_screen_def.buttons['B2Label']%>";
              if("<%=@pdt_screen_def.buttons['B2Enable']%>" == 'true') {
                button2.style.visibility='visible';
                button2.disabled = false;
              } else {
                button2.disabled = true;
                button2.style.visibility='hidden';
              }

              button3.innerText = "<%=@pdt_screen_def.buttons['B3Label']%>";
              if("<%=@pdt_screen_def.buttons['B3Enable']%>" == 'true') {
                button3.style.visibility='visible';
                button3.disabled = false;
              } else {
                button3.disabled = true;
                button3.style.visibility='hidden';
              }
            } else {
              button1.style.visibility='hidden';
              button2.style.visibility='hidden';
              button3.style.visibility='hidden';
            }
          }
        </script>

      }, :layout => 'content'
    else
      render :inline => %{
                     <%= @result %>
      }
    end
  end

end