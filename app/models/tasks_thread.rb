class TasksThread

#============================================================================
# This class manages a thread that runs in the background to perform any
# time consuming tasks- delegating these to subprocesses.
# Note: after considerable trial and error threading within the context of a
# Rails app proved unstable. Unpredictable things happen when using active record 
# objects within the current Rails App process space. Code running inside a separate
# process using active active record as an independent (from 'web' rails)
# library does seem to work nicely. Communication with such processes happen
# via the IO object created with ruby's 'popen' method.
#============================================================================
  @@fg_updated = true
  @@carton_builder_process = nil
  def TasksThread.get_tasks_queue
  
    return @@background_tasks_queue
  
  end
  #----------------------------------------------------------------------
  #Create thread to handle any long-running tasks that should be done 
  #asynchronously- for which the user should not wait.Also create a 
  #mutex that should be used for synchronized access to shared resources
  #----------------------------------------------------------------------
  
  @@background_tasks_queue = Array.new 
  @@task_thread_started = false
  @@mutex = Mutex.new
  
  def TasksThread.Process_tasks_queue
   
   #return if @@task_thread_started == true
   
   @@fg_updated = true
   
   #system("ruby -e 'puts $:'")
   
   Thread.new(){
   
   begin
   @@task_thread_started = true
    while true
      sleep 2
      if !@@background_tasks_queue.empty?
        task = nil
        @@mutex.synchronize {
          task = @@background_tasks_queue.shift }
          begin
            if task[:task_type] == "create_carton_templates_and_labels"
              puts "before require"
              
              @@carton_builder_process = IO.popen("ruby 'lib/build_carton_data.rb'","r+") if ! @@carton_builder_process
              #-----------------------------------------------------------------------------------
              #Write data to the pipe: the receiving process can read the data from standard input 
              #-----------------------------------------------------------------------------------
              @@carton_builder_process.puts task[:fg_setup_id]
              
              puts "build complete"
            else
             puts "wrong task"
            end
           
         rescue
            raise $!
           
         ensure
           
         end
          
      else
         puts "code not called"
      end
    end
   
   
   rescue
     puts " EXCEPTION: " + $!
     #puts $!.backtrace.to_s
   end
  }
  end

  
  def TasksThread.tasks_thread_started?
    @@task_thread_started
  end

  def TasksThread.get_mutex
    @@mutex
  end

  def TasksThread.fg_updated?
    @@fg_updated
  end

end