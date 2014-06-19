require "user.rb"

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

  #-----------------------------------------------------------------------
  # This method to build output/display error screens.It takes messages to be be
  # displayed in the output lines of the screen and returns a xml screen
  # definition.
  #-----------------------------------------------------------------------
  def send_screen(output_lines=nil, screen_caption=nil, plugins=nil)

    field_configs = Array.new
    for output_line in output_lines
      field_configs[field_configs.length] = {:type=>"text_line", :name=>"output", :value=>output_line.to_s}
    end
    screen_attributes = {:auto_submit=>"false", :content_header_caption=>screen_caption.to_s}
    buttons = {"B3Label"=>"Clear", "B2Label"=>"Cancel", "B1Label"=>"Submit", "B1Enable"=>"false", "B2Enable"=>"false", "B3Enable"=>"false"}
    screen_def = PdtScreenDefinition.gen_screen_xml(field_configs, buttons, screen_attributes, plugins)

    return screen_def
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

  #----------------------------------------
  # Handles pdt and pdt_simulator requests.
  # Public interface(http-get request with REST protocol) of the pdt server to the outside worl
  #----------------------------------------
  #Only one public - rest private
  def handle_request
    puts "Start round-trip = " + Time.now.to_s
    @is_rails_request = params[:is_rails_request]
    @mode = params[:mode]
    #    if(@mode == PdtScreenDefinition.const_get("MENUSELECT").to_s)
    #        @input_xml = "<PDTRF></PDTRF>"
    #    else
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
    puts "@input_xml i.e. Incoming xml from java = " + @input_xml.to_s
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
        error_screen_definition = send_screen(@field_configs, screen_caption, nil)
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
      if ($!.is_a?(PdtException))
        result_screen = PDTTransaction.build_msg_screen_definition($!.pdt_errors, nil, nil, nil)
        return render_result(result_screen)

#        puts "CAN IT WORK(KLAAS) : #{$!}"
#        puts "CAN IT WORK(ACTUAL MSG) : #{$!.pdt_messages.class.name}"
#        puts "CAN IT WORK(KLAAS) : #{$!.pdt_messages}"

      end

      exception = $!.to_s
#      exception += "./\\></!#\{}"
      remove_special_chars = exception.gsub("<", "[").gsub(">", "]").gsub("\\", "|").gsub("/", "|")
      puts $!.backtrace.join("\n").to_s
      lcd1 = "SYSTEM ERROR :"
      lcd2 = @pdt_method.program_name.to_s + "(" + @pdt_method.method_name.to_s + ")" if (@pdt_method)
      lcd3 = "DESCRIPTION :"
      error_description = Array.new
      while (error_description.length < 10 && remove_special_chars.length > 0 && remove_special_chars.length > 60)
        puts "remove_special_chars.length = " + remove_special_chars.length.to_s
        lcd = remove_special_chars.slice!(0, 60)
        error_description.push(lcd)
      end
      error_description.push(remove_special_chars) if (remove_special_chars.length > 0)
      output_lines = [lcd1, lcd2, lcd3] + error_description
      screen_caption = "Server Exception"
      if (@mode == PdtScreenDefinition.const_get("CONTROL_VALUE_REPLACE").to_s)
        error_screen_definition = "<error>" + exception + "</error>"
      else
        error_screen_definition = send_screen(output_lines, screen_caption, nil)
      end

      pdt_error($!)

      render_result(error_screen_definition)
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
        @result = send_screen(output_lines, screen_caption, nil)
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
      @result = send_screen(output_lines, screen_caption, nil)
      return @result
    elsif transaction_cancelled? == false
      output_lines = ["TRANSACTION CANNOT BE CANCELLED"]
      screen_caption = ""
      @result = send_screen(output_lines, screen_caption, nil)
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
            @result = send_screen(output_lines, screen_caption, nil)
          end
          persist_jsession
        else
          output_lines = ["Nothing to Undo[2]"]
          screen_caption = ""
          @result = send_screen(output_lines, screen_caption, nil)
        end
        return @result
      else
        output_lines = ["CANNOT UNDO TRANSACTION"]
        screen_caption = ""
        @result = send_screen(output_lines, screen_caption, nil)
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
    @result = result_screen #@jsession_store.get_session[:active_screen].to_s
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
      @result = send_screen(output_lines, screen_caption, nil)

      return @result if @pdt_method == nil
      #return @result = send_screen(true,"INVALID. REASON: ","UNKNOWN PDT FUNCTION = " + @menu_item) if @pdt_method == nil
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
        #@result = send_screen(true,"INVALID. REASON: ","NO AUTHORISATION")
        output_lines = ["INVALID. REASON: ", "NO AUTHORISATION"]
        screen_caption = ""
        @result = send_screen(output_lines, screen_caption, nil)

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
          #@result = send_screen(true,"NOTHING TO CANCEL ")
          output_lines = ["NOTHING TO CANCEL"]
          screen_caption = ""
          @result = send_screen(output_lines, screen_caption, nil)

          return @result
        else
          program_name = calculate_program_name()
          if authorise(program_name, 'cancel', @user) == false
            #@result = send_screen(true,"YOU DO NOT HAVE CANCEL PERMISSION ")
            output_lines = ["YOU DO NOT HAVE CANCEL PERMISSION "]
            screen_caption = ""
            @result = send_screen(output_lines, screen_caption, nil)

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
      @result = send_screen(output_lines, screen_caption, nil)
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

      @result = send_screen(output_lines, screen_caption, nil)
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
      @result = send_screen(output_lines, screen_caption, nil)
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

      @result = send_screen(output_lines, screen_caption, nil)
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
      if @pdt_method.class_name != nil && @pdt_method.class_name.strip != ""
        class_name = @pdt_method.class_name # + ".new"
      else
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
  # utility method to render the output to the
  # client i.e. either pdt or simulator.
  #---------------------------------------------
  def render_result(result)
    #----------------------
    # pdt response
    #----------------------
    puts "1. WHAT IS RESULTS ? " + result.class.name
    puts "2. WHAT IS RESULTS ? " + result.to_s
    #  result = "<PDTRF><controls content_header_caption=''></controls></PDTRF>" if result == nil || result.length == 0
    @result = result.to_s
    puts "======================================================================"
    puts @result.to_s
    puts "======================================================================"
    puts "End round-trip = " + Time.now.to_s
    render :inline => %{
                     <%= @result %>
    }
  end

end