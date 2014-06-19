class PDTTransaction
   attr_accessor  :pdt_screen_def, :pdt_method, :is_transaction_complete, :is_repeat_process
   attr_reader :env ,:scratch_pad,:params

 def initialize()
  @pdt_screen_def = nil
  @jsession_store = nil
  @result_template = nil
  @pdt_method = nil
  @active_state =  nil
  @controller = nil
  @result_screen = nil
  @cancellable = true
  @undoable = true

  @scratch_pad = Hash.new
 end

 def clear_pdt_environment
   @env = nil
 end

 #service methods are all public

 def self.print_report(report_name,params,user)
      params.store(:load_instruction_id,self.id)
      params.store(:SUBREPORT_DIR,Globals.sub_report_dir)

      if !RUBY_PLATFORM.index('linux')

        params[:OUT_FILE_NAME] = params[:OUT_FILE_NAME].gsub("/","\\") if(params[:OUT_FILE_NAME])

        report_parameters = ""
        params.map{|key,value| (report_parameters = report_parameters + " \"#{key}=#{value}\" ") if(key != :printer)}
        connection_string = "#{Globals.jasper_reports_conn_params[:adapter]}://#{Globals.jasper_reports_conn_params[:host]}:#{Globals.jasper_reports_conn_params[:port]}/#{Globals.jasper_reports_conn_params[:database]}?user=#{Globals.jasper_reports_conn_params[:username]}&password=#{Globals.jasper_reports_conn_params[:password]}"

        print_command_file_name = Globals.jasper_reports_printing_component + "/" + report_name + "_" + user + "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".bat"
        file = File.new(print_command_file_name, "w")
        file.puts "cd #{Globals.jasper_reports_printing_component.gsub("/","\\")}"
        file.puts "java -jar JasperReportPrinter.jar \"#{Globals.jasper_source_reports_path}\" #{report_name} \"#{params[:printer]}\" \"#{connection_string}\" #{report_parameters}"
        file.close

        result = eval "\`\"#{print_command_file_name}\"\"`"
        puts "WINDOWS PRINTING RESULT: " + result.to_s
        #File.delete(print_command_file_name)
        return result if(result.to_s.include?("JMT Jasper error:") || result.to_s.include?("Printing Error:"))
      else

        params[:OUT_FILE_NAME] = params[:OUT_FILE_NAME].gsub("\\","/") if(params[:OUT_FILE_NAME])

        report_parameters = ""
        params.map{|key,value| (report_parameters = report_parameters + " \"#{key}=#{value}\" ") if(key != :printer)}
        connection_string = "#{Globals.jasper_reports_conn_params[:adapter]}://#{Globals.jasper_reports_conn_params[:host]}:#{Globals.jasper_reports_conn_params[:port]}/#{Globals.jasper_reports_conn_params[:database]}?user=#{Globals.jasper_reports_conn_params[:username]}&password=#{Globals.jasper_reports_conn_params[:password]}"

        print_command_file_name = Globals.jasper_reports_printing_component + "/" + report_name + "_" + user + "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".sh"
        file = File.new(print_command_file_name, "w")
        file.puts "cd #{Globals.jasper_reports_printing_component.gsub("\\","/")}"
        file.puts "#{Globals.path_to_java} -jar JasperReportPrinter.jar \"#{Globals.jasper_source_reports_path}\" #{report_name} \"#{params[:printer]}\" \"#{connection_string}\" #{report_parameters}"
        file.close

        result = eval "\` sh " + print_command_file_name + "\`"
        puts "LINUX PRINTING RESULT: " + result.to_s
        result_array = result.split("\n")
        error = result_array.pop
        #File.delete(print_command_file_name)
        return result if(result.to_s.include?("JMT Jasper error:") || result.to_s.include?("Printing Error:"))
      end
 end

 def set_temp_record(key,value)
   @scratch_pad.store(key, value)
 end

 def clear_active_state
   @active_state = nil
 end

 def get_temp_record(key)
   @scratch_pad[key]
 end
 # Call this to delete the current trans and all it's resources
 # It will call transaction done on the current transaction or active_state
 def set_transaction_complete_flag()
   @is_transaction_complete = true
 end

 def set_repeat_process_flag
  @is_repeat_process = true
 end

 def should_repeat_process?
   return true if @is_repeat_process
   return false
 end

 def is_process_complete?
   return true if @is_transaction_complete
   return false
 end

#--------------------------------------------------------------
# completes a transaction i.e. clear session state and notifies
# the active state or itself that it has completed
#--------------------------------------------------------------
 def transaction_complete
   @jsession_store.clear_session_session_store
   if @active_state !=  nil
      @active_state.transaction_done()
   else
     transaction_done()
   end

   #--------------------------------------
   # makes sure that once the process terminates
   # and is supposed to be repeated, it sets
   # the inital state again
   #--------------------------------------

   # N.B. The initial state is set when a user initiates
   # a xaction for the 1st time by requesting the initial
   # screen by clicking a menu leaf.
   #
   #
   if @is_repeat_process
     @initial_session[:active_transaction].is_repeat_process = false
     @initial_session[:active_transaction].is_transaction_complete = false
     @jsession_store.set_active_session(@initial_session)
     puts @initial_session[:active_screen].to_s
   end
 end

 def set_cannot_undo()
  @jsession_store.set_cannot_undo
 end

 def set_cannot_cancel()
  @jsession_store.set_cannot_cancel
 end

#----------------------------------------------------------------
# takes a msg as a string,divides it into the specified number
# of lines each of the specified length NB. this array is then
# used as outputs for some screen.
#----------------------------------------------------------------
 def PDTTransaction.build_msg_output_lines(msg=nil,line_max=nil,num_lines=nil)
   if line_max != nil && num_lines != nil
     outputs = Array.new(num_lines)
     i = 0
     while(msg.size != 0)
        outputs[i] = msg.slice!(0..line_max)
        outputs[i].chop!.chop! if msg.size == 0
      i += 1
     end
   else
     outputs = [msg]
   end

  return outputs
 end

#------------------------------------------------------------------------------------------------
# uses build_msg_output_lines() to construct a pdt_screen_definition objectbuild_msg_output_lines
# for the returned outputs
#------------------------------------------------------------------------------------------------
  def PDTTransaction.build_msg_screen_definition(msg=nil,line_max=nil,num_lines=nil,additonal_lines_array=nil)
     outputs = build_msg_output_lines(msg,line_max,num_lines)
     outputs = additonal_lines_array + outputs if additonal_lines_array != nil

     field_configs = Array.new
     for output_line in outputs
       field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>output_line.to_s}
     end
     screen_attributes = {:auto_submit=>"false",:content_header_caption=>""}
     buttons = {"B3Label"=>"Cancel" ,"B2Label"=>"No","B1Label"=>"Yes","B1Enable"=>"false","B2Enable"=>"false","B3Enable"=>"false" }
     screen_xml = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,nil)
     return screen_xml
  end

#-----------------------------------------------------------------
# builds a pdt choice(Yes/No) screen with the prompt msg,if one
# is provided.
#-----------------------------------------------------------------
 def build_choice_screen(prompt_msg_array=nil,screen_attributes=nil,plugins=nil)
   outputs = [nil,nil,nil,nil,nil,nil,nil]

   if prompt_msg_array.class.name == "Array"
     index = 6
     msg_array_size = prompt_msg_array.length - 1
     (prompt_msg_array.length).times do
       outputs[index] = prompt_msg_array[msg_array_size]
       index -= 1
       msg_array_size -= 1
     end
   end

   field_configs = Array.new
   for output_line in outputs
     field_configs[field_configs.length] = {:type=>"text_line",:name=>"output",:value=>output_line.to_s}
   end

   buttons = {"B3Label"=>"Cancel" ,"B2Submit"=>"no","B2Label"=>"no","B1Submit"=>"yes","B1Label"=>"yes","B1Enable"=>"true","B2Enable"=>"true","B3Enable"=>"false" }
   result_screen_def = PdtScreenDefinition.gen_screen_xml(field_configs,buttons,screen_attributes,plugins)
   return result_screen_def
 end

 # Used to create the pdt_method for a transaction when transitioning to it directly(i.e NOT through the UI) from another transaction
 #
 #N.B. When executing a state from the UI/menu_structure,the pdt_method is create automatically by the pdt_controller.However,when executing/transition_to a state from
 # another state of a different transaction/process....client developer WILL have to create this pdt_method as it is neccessary for transaction&state class loading purposes.
 #
# def self.create_pdt_method(display_name)
##     menu_level = 2 #What about program_functions??????
##     program = Program.find_by_program_name(menu_item)
##     functional_area = FunctionalArea.find_by_functional_area_name(program.functional_area_name) if program != nil # **
##     pdt_method = nil
##     if program != nil && functional_area != nil
##       class_name = program.class_name
##       class_name = functional_area.class_name if class_name == nil
##       pdt_method = PdtMethod.new(program.display_name,program.disabled,class_name, menu_level,program.program_name,program.class_name)
##     end
##     return pdt_method
#    program = Program.find_by_display_name(display_name)
#    if(program)
#      menu_item = program.program_name
#      menu_level = 2
#      functional_area = FunctionalArea.find_by_functional_area_name(program.functional_area_name)
#
#      class_name = program.class_name
#      class_name = functional_area.class_name if class_name == nil
#      parent_class_name = functional_area.class_name
#      method_name = program.display_name
#      pdt_method = PdtMethod.new(method_name,program.disabled,class_name, menu_level,program.program_name, parent_class_name)
#    else
#      program_function = ProgramFunction.find_by_display_name(display_name)
#      menu_item = program_function.name
#      menu_level = 3
#      parts = menu_item.split(".")
#      program_name = parts[0] + "." + parts[1] + "." + parts[2]
#
#      program = Program.find_by_program_name(program_name)
#      program_function = ProgramFunction.find_by_name(menu_item)
#
#      class_name = program_function.class_name
#      class_name = program.class_name if class_name == nil
#      parent_class_name = program.class_name
#
#      method_name = program_function.display_name
#
#      pdt_method = PdtMethod.new(method_name,program_function.disabled,class_name, menu_level,program.program_name,parent_class_name)
#    end
##    puts "------------------- pdt_method.program_name = " + pdt_method.program_name.to_s
##    puts "------------------- pdt_method.parent_class_name = " + pdt_method.parent_class_name.to_s
##    puts "------------------- pdt_method.class_name = " + pdt_method.class_name.to_s
#    return pdt_method
#  end

 def get_current_menu_item
   return @jsession_store.get_session[:active_transaction].pdt_method.program_name.to_s if(@jsession_store.get_session[:active_transaction]!=nil && self.class.name != @jsession_store.get_session[:active_transaction].class.name)
   if @pdt_method
     return @pdt_method.program_name
   end
   return nil
 end

 def repeat_process

   self.set_transaction_complete_flag

   @initial_session = get_first_session
   if(@initial_session != nil && @initial_session[:input_pdt_screen_def] != nil && @initial_session[:active_screen] != nil)
     set_temp_record("result_screen" ,clear_screen_values(@initial_session[:active_screen]))
     set_temp_record("current_menu_item", @initial_session[:input_pdt_screen_def].menu_item)
     else
       set_temp_record("result_screen" ,clear_screen_values(@pdt_screen_def.input_xml))
       set_temp_record("current_menu_item", @pdt_screen_def.menu_item)
   end
 end

 def friendly_name
   return self.class.name
 end
#--------------------------------------------------
# defines the process that each transaction goes
# through
#
# This method serves internal infrastructure only.Not
# to be used by clients.
#--------------------------------------------------
 def process_transaction(env,input_pdt_screen_def,jsession_store,pdt_method,user,params)
#   begin
   @params = params
   @env = env
   @jsession_store = jsession_store
   @pdt_method = pdt_method
   @pdt_screen_def = input_pdt_screen_def
   @user = user
   @new_transation_activated = false
   #______________________
   # 1. AMENDMENT
   #______________________

   temp = @jsession_store.get_sessions[0]
   temp[:active_screen] = input_pdt_screen_def.input_xml
   @jsession_store.get_sessions.update(0,temp)
   #______________________
   object_to_route_to?()

   @jsession_store.set_input_pdt_screen_def(input_pdt_screen_def)

   result_screen = route_request()
   current_menu_item = get_current_menu_item()
#   current_menu_item = @jsession_store.get_session[:active_transaction].pdt_method.program_name.to_s if(@jsession_store.get_session[:active_transaction]!=nil && self.class.name != @jsession_store.get_session[:active_transaction].class.name)

   if(should_repeat_process?)
     repeat_process
     result_screen = get_temp_record("result_screen")
     current_menu_item = get_temp_record("current_menu_item")
   end

   result_screen.gsub!("<controls", "<controls current_menu_item='" + current_menu_item.to_s + "'")
   @jsession_store.set_result_screen(result_screen) if @object_to_route_to.pdt_screen_def.mode.to_s != PdtScreenDefinition.const_get("CONTROL_VALUE_REPLACE").to_s
   @jsession_store.set_active_transaction(self) if @new_transation_activated == false && @object_to_route_to.pdt_screen_def.mode.to_s != PdtScreenDefinition.const_get("CONTROL_VALUE_REPLACE").to_s
#   @env = nil
   clear_pdt_environment 
   @scratch_pad = Hash.new
   return result_screen
#  rescue
#    #LOG into PdtErrors table
#    exception =  "ERROR OCCURED IN PDTTransaction :" + "1." + $!.to_s
#    exception += "2." + pdt_error(exception)
#    msg = exception
#    additonal_lines_array=nil
#    result_screen = PDTTransaction.build_msg_screen_definition(msg,33,8,additonal_lines_array)
#
#    return hash_error_screen(result_screen)
#  end
 end

 def hash_error_screen(screen_def)
    #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    #   if Error occured package screen as hash
    #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    error_hash_format = Hash.new
    error_hash_format.store("type", "error_screen")
    error_hash_format.store("screen", screen_def)
    return error_hash_format
 end

 def pdt_error(exception)
   begin
    pdt_error = PdtError.new
    pdt_error.user = @user
    pdt_error.created_on = Time.now
    pdt_error.error_description = ""
    pdt_error.stack_trace = exception#.backtrace.join("\n").to_s
    if@input_pdt_screen_def != nil
      pdt_error.ip = @input_pdt_screen_def.ip
      pdt_error.mode = @input_pdt_screen_def.mode.to_i
      pdt_error.input_xml = @input_pdt_screen_def.input_xml
      pdt_error.menu_item = @input_pdt_screen_def.menu_item
    end
    pdt_error.error_type = "PDTTransactionError"
    pdt_error.save
    return ""
   rescue
     ekseption = $!.to_s
     return ekseption
   end
 end

  def set_active_state(state)
   state_class_name = Inflector.underscore(state.class.name) + ".rb"
   pdt_transaction_folder = "app/models/pdt_transactions/" + Inflector.underscore(self.class.name)

   if Dir.entries(pdt_transaction_folder).include?(state_class_name) || state == nil
     @active_state = state
   else
    raise ".. Sorry,this state[" + state_class_name + "] DOES NOT belong to this transaction."
   end
  end

  def transit_to_process(transaction_class_name)
   begin_exception_handler = " begin \n "
   end_exception_handler = "\n rescue \n  raise 'could not transition to process " + transaction_class_name.to_s + "' \n end"
   new_transation = begin_exception_handler + transaction_class_name.to_s + ".new" + end_exception_handler

   active_transaction = eval(new_transation)
   #   active_transaction = eval(transaction_class_name + ".new")
   #---------- setting the pdt menthod------
   program = Program.find_by_class_name(transaction_class_name)
    if(program)
      menu_item = program.program_name
      menu_level = 2
      functional_area = FunctionalArea.find_by_functional_area_name(program.functional_area_name)

      class_name = program.class_name
      class_name = functional_area.class_name if class_name == nil
      parent_class_name = functional_area.class_name
      method_name = program.display_name
      active_transaction.pdt_method = PdtMethod.new(method_name,program.disabled,class_name, menu_level,program.program_name, parent_class_name)
    else
      program_function = ProgramFunction.find_by_class_name(transaction_class_name)
      menu_item = program_function.name
      menu_level = 3
      parts = menu_item.split(".")
      program_name = parts[0] + "." + parts[1] + "." + parts[2]

      program = Program.find_by_program_name(program_name)
      program_function = ProgramFunction.find_by_name(menu_item)

      class_name = program_function.class_name
      class_name = program.class_name if class_name == nil
      parent_class_name = program.class_name

      method_name = program_function.display_name

      active_transaction.pdt_method = PdtMethod.new(method_name,program_function.disabled,class_name, menu_level,program.program_name,parent_class_name)
    end
   #---------- setting the pdt menthod------
   @new_transation_activated = true
   @jsession_store.set_active_transaction(active_transaction)
   return active_transaction
  end

  def get_active_state()
    return @active_state
  end

  #----------------------------------------------------
  # return the input values,entered by the user,from
  # the previus screen.
  #----------------------------------------------------
  def get_previous_input()
   if @jsession_store != nil

     for session in @jsession_store.get_sessions
      if session[:active_transaction] != nil
         if session[:active_transaction].pdt_screen_def.inputs['Input1'][:value].strip != "" || session[:active_transaction].pdt_screen_def.inputs['Input2'][:value].strip != "" ||session[:active_transaction].pdt_screen_def.inputs['Input3'][:value].strip != ""
           return session[:active_transaction].pdt_screen_def.inputs
         end
      end
     end
   end

   return nil
  end

 def get_pdt_screen_definition
   return @pdt_screen_def
 end


  def extract_actual_program_name(program_name)
    if(program_name.occurrence_of(".") == 3)
      menu_level = 3
      parts = program_name.split(".")
      program_name = parts[0] + "." + parts[1] + "." + parts[2]
    end
    return program_name
  end
  #----------------------------------------------------------------------
  # authorises the pdt_user against the permission set by the client
  # developer i.e. permission is set by overriding permission?()
  #----------------------------------------------------------------------



  def authorise
     tmp_permission = @object_to_route_to.permission?
      if tmp_permission == "yes"
        permision_name = @pdt_method.method_name
         return @env.authorise(extract_actual_program_name(@pdt_method.program_name),permision_name,@user)
      elsif  tmp_permission == nil
         return true
      else
        permision_name = tmp_permission
        return @env.authorise(extract_actual_program_name(@pdt_method.program_name),permision_name,@user)
      end

   end


 private
 def object_to_route_to?
   @object_to_route_to = @active_state
     if @object_to_route_to == nil
       if default_state_class? != nil
       file_to_load = Inflector.tableize(default_state_class?).chop + ".rb"
       parent = self
         begin_exception_handler = " begin \n "
         end_exception_handler = "\n rescue \n  raise 'this file [" + file_to_load.to_s + "] could not be loaded' \n end"
         klaas = begin_exception_handler + default_state_class?.to_s + ".new(parent)" + end_exception_handler
         #puts klaas.to_s
         @object_to_route_to = eval(klaas)
         self.set_active_state(@object_to_route_to)
       else
       @object_to_route_to = self
       end
     end

   return @object_to_route_to
   end

  #---------------------------------------------------------------------------------------------------------------------------------
  # validates :
  # 1. if the program_function can be applied to @object_to_route_to at this point of the transaction, if @object_to_route_to exists
  # 2. if @object_to_route_to doesn't exist,check if the program_function can be applied to the transaction object
  #    at this point of the transaction
  # 3. the pdt_user's permissions for the current program_function
  #
  # returns an appropriate error screen if any of the above do not hold.
  #----------------------------------------------------------------------------------------------------------------------------------
  def validate_method(mthod_to_route_to)
  #if @object_to_route_to == nil,look inside self to see if state method doesn't have this method
  if(@object_to_route_to.respond_to?(mthod_to_route_to) == false )

#     msg = "action [ " + mthod_to_route_to + "() ] cannot be executed at this point of the process [ " + @object_to_route_to.class.name + " ]"
     msg = ["The active transation is - #{@object_to_route_to.friendly_name}",
            "You cannot do a #{mthod_to_route_to} now",
            "unless you clear the active transaction first"
           ]
     result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,msg)
     return result_screen
  end
  return nil
  end

  #-------------------------------------------------------------------------------
  # route_request will call an actual
  # method (e.g. 'scan bin' corresponding to
  # a menu item, e.g. 1.2.3.4)implementing
  # the business logic for transaction- this method will
  # return the xml screen as a string- to be sent for display
  # on PDT
  #-------------------------------------------------------------------------------
   def route_request()
#     begin
       if @object_to_route_to.authorise() == false
         msg = "No authorisation"
         additonal_lines_array=nil
         result_screen = PDTTransaction.build_msg_screen_definition(nil,nil,nil,["No authorisation"])
         return result_screen
       end
       @object_to_route_to.pdt_screen_def = @pdt_screen_def
       is_screen_submission = true
       #puts "MODE TO ROUTE TO i.e. from java = " + @object_to_route_to.pdt_screen_def.mode.to_s
       if @object_to_route_to.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("BUTTON1").to_s
        # puts "@object_to_route_to.pdt_screen_def.screen_attributes[B1Submit] = " + @object_to_route_to.pdt_screen_def.buttons["B1Submit"].to_s
         method_to_route_to = @object_to_route_to.pdt_screen_def.buttons["B1Submit"]
       elsif @object_to_route_to.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("BUTTON2").to_s
         method_to_route_to = @object_to_route_to.pdt_screen_def.buttons["B2Submit"]
       elsif @object_to_route_to.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("BUTTON3").to_s
         method_to_route_to = @object_to_route_to.pdt_screen_def.buttons["B3Submit"]
       elsif @object_to_route_to.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("ENTERDATA").to_s
       #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
       #  what about ENTERDATA - Automatic screen submissions????
       #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#         method_to_route_to  = @pdt_method.method_name + "_submit"
        raise "auto_submit_to action missing. Please contact IT!!!" if @object_to_route_to.pdt_screen_def.screen_attributes["auto_submit_to"] == nil
        method_to_route_to  = @object_to_route_to.pdt_screen_def.screen_attributes["auto_submit_to"]
       else#handle menu selections and automatic only
         method_to_route_to  = @pdt_method.method_name
         is_screen_submission = false
       end

       if(is_screen_submission)
         if(!@object_to_route_to.can_redo)
           @jsession_store.clear_redos
         end
       end

       if method_to_route_to == nil
         msg = "../app/models/pdt_transaction.rb:326:in `route_request'  got nil,might have expected a string"
         additonal_lines_array=nil
         result_screen = PDTTransaction.build_msg_screen_definition(msg,35,7,additonal_lines_array)
         return hash_error_screen(result_screen)
       end

       if ! (error = validate_method(method_to_route_to))
         result_screen_def = @object_to_route_to.send(method_to_route_to)
         return result_screen_def
       else
         if  @object_to_route_to.pdt_screen_def.mode.to_s == PdtScreenDefinition.const_get("CONTROL_VALUE_REPLACE").to_s
           return "<error></error>"
         else
           return hash_error_screen(error)
         end
       end
#     rescue
#       puts $!
#       puts $!.backtrace.join("\n").to_s
#     end
   end

  protected
  #Intended to be overriden
  #----------------------------------------------------------
  # notifies itself that the transaction is now complete
  #----------------------------------------------------------
   def transaction_done
     puts "........." + self.class.name + " has been notified"
   end

   def yes()
   end

   def no()
   end

  #-----------------------------------------------------------
  # allows the client developer to override this method and
  # define a default/initial sate class.If not overriden,it
  # just returns nil,which will then indicate that no
  # default state has been set by client developer
  #-----------------------------------------------------------
   def default_state_class?()
      return nil
   end

  #----------------------------------------------------------
  # If authorisation is needed derived class must override
  # this method and return the name of the permission or
  # return "yes"- in which case the program function_name is
  #  treated as the permission name...alse it returns nil
  #  which indicates no authorisation needed
  #----------------------------------------------------------
   def permission?()
      return nil
   end

   #______________________
   # 3. AMENDMENT
   #______________________
   def can_redo
     false
   end
   #______________________

  def get_first_session
     first_item = nil
     second_item = nil
     count = 0
     if(@jsession_store)
       @jsession_store.get_sessions.each do |list_item|
         if(list_item != nil)
           second_item = first_item
           first_item = list_item
         else
           break
         end
  #       puts "get_persisted_object = " + list_item.to_s
          count += 1
       end
     end
     if(first_item != nil && first_item[:input_pdt_screen_def] != nil && first_item[:active_screen] != nil)
       return first_item
     else
       return second_item
     end
  end

  def clear_screen_values(screen_xml)
    screen_def = PdtScreenDefinition.new(screen_xml, nil, nil, nil, nil)
    screen_def.controls.each do |control|
      if(control['type'] == "text_box") #|| control['type'] == "drop_down"
        control['value'] = ""
      end
    end
    return screen_def.get_output_xml
  end
end
