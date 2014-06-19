 #----------------------------------------------------
 # Implentation of the deep copy for the JSessionStore
 #----------------------------------------------------
  def deep_copy(source_class)
    self_persisted = Marshal.dump(source_class)
    return copy = Marshal.load(self_persisted)
  end
 #----------------------------------------------------


class JSessionStore

 def initialize(jsession_store_key,persisted_lists_folder)
   @jsession_store_key = jsession_store_key
   @persisted_lists_folder = persisted_lists_folder
  new_session_list
  @active_session = nil
  @undoable = true
  @cancelable = true
  @session_max = 8
  #______________________
  # 2. AMENDMENT
  #______________________
  #@redo_sessions = Array.new
  @redo_sessions = PersistedList.new(0,@jsession_store_key,"redo_sessions",@persisted_lists_folder)
  #______________________
 end

 def new_session_list
  #@sessions = [Hash.new,Hash.new,Hash.new,Hash.new]
  @sessions = PersistedList.new(4,@jsession_store_key,"sessions",@persisted_lists_folder)
 end

 #----------------------------------------
 # Sets the topmost session in the list to
 # active_session and returns it
 #----------------------------------------
 def get_session
  @sessions = new_session_list if !@sessions
  @active_session = @sessions[0] if !@active_session
  @active_session
 end

   #-----------------------------------------------------------------------------------------------
   # Called when a new normal (i.e. not special transaction like undo or refresh or cancel)
   # transaction is about to start. Take the topmost item, copy it, and assign the copied
   # item to active_session
   # ----------------------------------------------------------------------------------------------
 def cycle
  @active_session = deep_copy(@sessions[0])

 end

 #------------------------------------------
 # Stes both cancellable & undoable to false
 #------------------------------------------
 def set_cannot_cancel
  @cancelable = false
  set_cannot_undo
 end
 def set_cannot_undo
  @undoable = false
 end

 def cancelable?
  return @cancelable
 end

 def undoable?
  return  @undoable
 end

 #______________________
# 6. AMENDMENT
#______________________
 def redoing
  #@sessions.unshift(@redo_sessions.shift) if @redo_sessions.size > 0 #When using a ruby array
  if @redo_sessions.size > 0
    redo_session = @redo_sessions.shift
#    puts "________________________________________"
#    puts "________________________________________"
#    puts " REDO = " + redo_session.class.name
#    puts "________________________________________"
#    puts "________________________________________"
    #@sessions.unshift(redo_session) #if @redo_sessions.size > 0 #Done in persist_session - else have @redo = true & amend persist_session
    @active_session = redo_session
  end
  #@active_session = @sessions[0]
 end

 #------------------------------------------
 # removes the frontmost session item in the
 # sessions list
 #------------------------------------------
 def undo
  @undo = true
  #@redo_sessions.unshift(Marshal.load(@sessions.shift)) if @sessions.size != 0 #If using ruby array - must load this before shifting it in
  @redo_sessions.unshift(@sessions.shift) if @sessions.size != 0 #If using PersistedList - just shif it NB.it'll be persisted to db
  @active_session = @sessions[0]

#______________________
# 3. AMENDMENT
#______________________
#@redo_sessions.unshift(@active)
#puts "Populating @redo_sessions............"
#@redo_sessions.each do |s|
#            if s != nil && s[:active_transaction] != nil
#            print s[:active_transaction].class.name + "  : "
#            puts s[:active_transaction].get_pdt_screen_definition.menu_item.to_s
#            puts "\n"
#            end
#          end
#puts "............Populating @redo_sessions"
#______________________
 end

 def clear_redos
#   puts "1.CLEARING REDOS ....CLEARING REDOS ....CLEARING REDOS ....CLEARING REDOS ....CLEARING REDOS ....CLEARING REDOS ...."
   @redo_sessions.clear_list
   @redo_sessions = PersistedList.new(0,@jsession_store_key,"redo_sessions",@persisted_lists_folder)
#   puts "2.CLEARING REDOS ....CLEARING REDOS ....CLEARING REDOS ....CLEARING REDOS ....CLEARING REDOS ....CLEARING REDOS ...."
 end
 #------------------------------------------

 #------------------------------------------
 # Prints the active_tranaction.class_name
 # and menu_item - for testing purposes
 #------------------------------------------
 def print_sessions msg
         puts msg + "________________\n"
        if @sessions != nil
         @sessions.each do |s|
            if s != nil && s[:active_transaction] != nil
            print s[:active_transaction].class.name + "  : "
            puts s[:active_transaction].get_pdt_screen_definition.menu_item.to_s
            puts "\n"
            end
          end
        end
         puts "_________________"
 end
 #------------------------------------------

 def refresh
  @refreshed = true
 end

#-------------------------------------------------------------
# make a copy of  @active_session and add it to the
# front of  the sessions list- IF undo() or cancel or refresh()
# was not called on session store instance
#-------------------------------------------------------------
 def persist_session
  #print_sessions "PERSIST BEFORE:"
   if !@refreshed && !@undo || (@refreshed && get_session[:active_transaction].respond_to?('refresh') && !get_session[:active_transaction].is_transaction_complete)
     #new_sessison = deep_copy(@active_session)
     new_sessison = @active_session # Happy ammends
     #new_sessison = nil if @active_session != nil && @active_session.empty? # BAD BAD BAD NEWS!!!!!!!!!!
     @sessions.unshift(new_sessison)
   end
     @undo = nil
     @refreshed = nil

     @active_session = nil#??????????????????? - very correct i.e. I made a copy of the @active_session and put it in @sessions[0](unsift)
                                                                   # I must now kill this @active_session to avoid duplication.The next time
                                                                   # a call is made i.e. get_session() is called.It'll just set @active_session=@sessions[0]
                                                                   #and shift it.

     #Therefore,in using PersistedList,unshift DOES NOT put @active_session in list.list_item.position=0 OR when a call is made i.e. get_session() is called
     # @active_session=@sessions[0] i.e. @sessions[0] is NOT retrieved successfully

     #----------------------------------------
     # Start removing sessions from the oldest
     # when the number reaches 8 sessions
     #----------------------------------------
#     if @sessions.length > @session_max
#       @sessions.pop
#     end
     #----------------------------------------
     #print_sessions "PERSIST AFTER:"
 end
#-------------------------------------------------------------
  #Method to get rid of unneeded data just before persist
  def clean
    @active_session = nil
    #code for data to be cleaned goes here
  end

 def clear_session_session_store
  #@active_session = Hash.new
  #@sessions = new_session_list

  @undoable = true
  @cancelable = true
  @active_session = nil
  @sessions.clear_list
  @redo_sessions.clear_list
  @sessions = new_session_list
 end

 def clear_session_history
  @undoable = true
  @cancelable = true
  @active_session = nil
  @sessions.clear_list
  @redo_sessions.clear_list
 end
#---------------------------------------
# Returns the sessions list
#---------------------------------------
 def get_sessions
   return @sessions
 end
#---------------------------------------
def set_active_session(session)
  @active_session = session
end

 def set_result_screen(screen)
  @active_session[:active_screen] = screen
 end

 def set_active_transaction(pdt_transaction)
   @active_session[:active_transaction] = pdt_transaction
 end

 def set_input_pdt_screen_def(input_pdt_screen_def)
  @active_session[:input_pdt_screen_def] = input_pdt_screen_def
 end

 def set_active_pdt_screen_def(active_pdt_screen_def)
  @active_session[:active_pdt_screen_def] = active_pdt_screen_def
 end

 def set_active_transaction_class_name(transaction_class_name)
  @active_session[:active_transaction_class_name] =  transaction_class_name
 end

end