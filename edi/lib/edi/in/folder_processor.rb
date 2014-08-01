# Process a folder: Gather all the files in a folder and pass them to the relevant transformers.
class FolderProcessor
  include EdiSetup

      require 'fileutils'
      require 'pathname'


    # Load flow types from the <tt>supported_doc_types.yaml</tt> file.
    # 
    # Flow types are sorted alphabetically, but with longer codes before shorter
    # codes. (+MFPO+ before +MF+). This is so that a long code does not match a
    # short code: +MFPO+ matches +MF+ first in [+MF+, +MFPO+] but matches +MFPO+
    # correctly in [+MFPO+, +MF+]. Matching takes place in matching_flow_type?
    def load_flow_types

       @transformers = YAML::load(File.read(EdiHelper::APP_ROOT + '/edi/config/supported_doc_types.yaml'))
       @transformers['IN_FLOW_TYPES'].delete_if{|key,val| val == "na" }
       # Get the list of Flow Types.
       # Sort 4-character codes before 2-character codes.
       # (Avoid matching 'MFPO' to 'MF')
       @flow_types = @transformers['IN_FLOW_TYPES'].keys.sort_by {|a| a.ljust(4,'ZZ') }


    end
     def initialize(dir_path,user,ip,interval)
         #@dir_path = dir_path
         @dir_path = Pathname.new(dir_path).expand_path
         raise EdiProcessError, "Dir \"#{@dir_path}\" does not exist" unless @dir_path.exist?
         load_flow_types
         get_config_values_for_in_process
         # if dir_path.index("/")
         #  dir_parts = @dir_path.split("/")
         # else
         #   dir_parts = @dir_path.split("\\")
         #   
         # end
         @logger = EdiHelper::edi_log
         # dir_parts.pop()
         # @error_dir = dir_parts.join("/") + "/errors/transport"

         # @completed_dir =  dir_parts.join("/") + "/transformed"

         # FileUtils.makedirs(@error_dir) if !File.exist?(@error_dir)
         # FileUtils.mkdir(@completed_dir) if !File.exist?(@completed_dir)
         @error_dir     = @dir_path.parent.join('errors', 'transport')
         @completed_dir = @dir_path.parent.join('transformed')
         @error_dir.mkpath
         @completed_dir.mkpath
         @dir_path      = @dir_path.to_s
         @error_dir     = @error_dir.to_s
         @completed_dir = @completed_dir.to_s
        
         @user = user
         @ip = ip
         @interval = interval

      end

      def run

        while (true)

          process_snapshot()
          
          sleep @interval
        end

      end

     def handle_error(file_name,flow_type)
       if !($!.to_s ==   "schema validation error" || $!.to_s == "transformation error")
          err_msg = $!.message
          err_stack = $!.backtrace
          options = {:flow_type   => flow_type,
                     :edi_type    => "directory_processing",
                     :action_type => file_name,
                     :edi_filename => file_name }

          options[:logged_on_user] = @user if @user
          options[:ip] = @ip if @ip
          begin
          err_entry = EdiError.record_error( $!, options )

          rescue ActiveRecord::StatementInvalid
            @logger.write "Logging of error to db failed.Propable reason is illegal character in file. System reported: " + $!,2
          rescue
            @logger.write "Logging of error to db failed.Reason: " + $!,2

          ensure

            @logger.write err_msg,2
            @logger.write err_stack.join("\n").to_s,0

          end
         
      end




      move_file(file_name,@error_dir)

       
     end

     def move_file(file_name,destination_folder)
       begin
        FileUtils.mv(@dir_path + "/" + file_name, destination_folder + "/" + file_name + "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + "_.txt")
       rescue
              puts "MOVE EXCEPTION: " +  $!
         end
     end

    # See if the file name starts with one of the flow types.
    #
    # Return the flow type or nil if no match.
    def matching_flow_type?(file_name)
      @flow_types.each do |flow_type|
        return flow_type.downcase if file_name =~ /^#{flow_type}/i
      end
      nil
    end

    # Take a snapshot of the files in the folder to be processed.
    # Lock the folder. Loop through the files and hand each one to its pre-processor
    # and transformer.
    def process_snapshot
      dir = Dir.new(@dir_path)
      # if Pathname.glob(@dir_path + '*.lck').size > 0
      if File.find(@dir_path,"*.lck").length() > 0  #do not process if folder is locked by some write process
        @logger.write "folder locked. waiting " + @interval.to_s + "seconds",1
        return
      else
        # Remove all directories from the list of files. Also sort the files.
        #dir_files = dir.entries.select {|f| 'file' == File.ftype(File.join(@dir_path, f)) }.sort
        timed_file  = Struct.new(:fn, :tm)
        timed_files = dir.entries.select {|f| 'file' == File.ftype(File.join(@dir_path, f)) }.map {|f| timed_file.new(f, File.mtime(File.join(@dir_path, f)) )}
        dir_files   = timed_files.sort_by {|f| f.tm }.map {|f| f.fn }.reject {|f| '.inuse' == File.extname(f) }
        @logger.write "EDI IN: new folder snapshot: processing #{dir_files.length.to_s}",1
      end

      entry_index = 0
      entry_count = dir_files.length
      dir_files.each do |e|
        begin
          if e.include?(' ')
             @logger.write "Unable to process file with a space in its name: #{e}.", 2
            next
          end
          if skip_compressed_file? e
             @logger.write "Unable to process compressed file: #{e}.", 2
            next
          end
          if bad_encoding? e
             @logger.write "Unable to process file: #{e}. Can currently only handle ASCII and UTF-8 encoded files. File moved to encoding_errors subdir.", 2
            next
          end
          check_log_levels
          if flow_type = matching_flow_type?(e)
             EdiHelper.edi_in_process_file = e
             entry_index += 1
             @logger.write "transforming file: " + e + "(#{entry_index.to_s} of #{entry_count})...",1
             transformer_class_name =  @transformers['IN_FLOW_TYPES'][flow_type.upcase]
             if(transformer_class_name == "TextIn::CsvInTransformer")
              raw_text = []
             else
               raw_text = ""
             end
             pre_processor_class_name = (flow_type + "_pre").camelize()
             pre_processor = nil
             if File.exist?("edi/in/pre_processors/" + flow_type + "_pre.rb")
               pre_processor = eval(pre_processor_class_name + ".new()")
             end

             FileUtils.touch(File.join(@dir_path, 'J&JMesEdi.lck'))
             #File.open(@dir_path + "/" + "J&JMesEdi.lck","w") {|f|} #lock the directory, so file reading is not interfered with
             #lines =  IO.readlines(@dir_path + "/" + e)
             if running_on_windows?
               f = File.new(@dir_path + "/" + e, 'r')
             else
               f = File.new(@dir_path + "/" + e, 'r', File::SYNC)
               unless f.flock(File::LOCK_EX | File::LOCK_NB) # Try to get an exclusive lock on the file (non-blocking).
                 @logger.write "Could not lock file: #{e} - probably still being written. Skipped for later processing...",2
                 next 
               end
               # Free the lock - it was only used to see if the file has been completely downloaded.
               f.flock(File::LOCK_UN)
             end
             lines = f.readlines
             f.close
             lines.each do |line|
               line.chop!() if(transformer_class_name != "TextIn::CsvInTransformer")
               if pre_processor
                 raw_text << pre_processor.before_record(line)
                 raw_text << pre_processor.process_record(line)
                 raw_text << pre_processor.after_record(line)
               else
                 raw_text << line
               end
             end

             raw_text.compact! if(transformer_class_name == "TextIn::CsvInTransformer")

             transformer = eval(transformer_class_name + ".new(raw_text,flow_type,@user,@ip,e)")
             transformer.set_file_contents(IO.readlines(@dir_path + "/" + e))
             parse_err = transformer.parse()
             raise EdiProcessError, "schema validation error" if parse_err
             run_err = transformer.run
             raise EdiProcessError, "transformation error" if run_err
             move_file(e,@completed_dir)

          elsif e =~ /^MF/ # Masterfile flow type without transformer
            unprocessable_masterfile e
          end

        rescue
           handle_error(e,flow_type)
        ensure
            FileUtils.rm @dir_path + "/" +  "J&JMesEdi.lck", :force => true #remove the lock file
        end

      end

    end

    # See if this is a compressed file.
    # Uses the Unix +file+ command, so this method always returns false on Windows.
    # Returns true if the file is a compressed file that cannot be processed, false otherwise.
    # Attempts to unzip the file and returns false if the unzip succeeds.
    def skip_compressed_file?( file_name )
      if running_on_windows?
        false # Can't run this check on Windows
      else
        path     = File.join(@dir_path, file_name)
        filetype = `file -b #{path}`.gsub(/\n/,"")

        if $?.exitstatus == 0 && filetype =~ /zip/i
          `unzip -o #{path} -d #{File.join(@dir_path, 'extracted')}`
          if $?.exitstatus == 0 && make_extracted_file_available( file_name, path )
            false # Unzip succeeded, no need to skip it.                Process!
          else
            true  # This is a zip file, but we're unable to process it. Skip!
          end
        else
          false   # file command failed or file is not a zip file.      Process!
        end
      end

    end

    # Delete the zip file and move the file extracted from the zip file to the folder that is being processed.
    # This might fail if the file within the zip does not have the same name as the zip file.
    # In this case return false and log a record of the attempt.
    def make_extracted_file_available( file_name, path )
      File.delete( path )
      fullname = File.join(@dir_path, 'extracted', file_name)
      if File.exists?(fullname)
        FileUtils.mv( fullname, path )
      true
      else
        if EdiHelper.process_dot_zip_files
          fullname = fullname.sub(/\.zip\z/i, '') # Maybe the compressed file has a zip extension.
          FileUtils.mv( fullname, path )
          true
        else
          @logger.write "file: #{path} could not be processed after it was uncompressed into 'extracted' folder.",2
          false
        end
      end
    rescue
      @logger.write "file: #{path} could not be processed after it was uncompressed into 'extracted' folder.",2
      false
    end
     
    # Check if the input file is of an encoding type we can handle.
    def bad_encoding?( file_name )
      if running_on_windows?
        false # Can't run this check on Windows
      else
        path     = File.join(@dir_path, file_name)
        filetype = `file -b #{path}`.gsub(/\n/,"")

        if $?.exitstatus == 0 && filetype =~ /ascii|utf/i
          false
        else
          @logger.write "File: #{path} is encoded as #{filetype}. Exit status is #{$?.exitstatus}.", 2
          FileUtils.mkpath(File.join(@dir_path, 'encoding_errors') )
          FileUtils.mv( path, File.join(@dir_path, 'encoding_errors', file_name) )
          true # Only process ASCII or UTF-8
        end
      end

    end

    # We have a masterfile flow without a transformer.
    # Move the file out of the in directory so it will not be processed again.
    def unprocessable_masterfile( file_name )
      path = File.join(@dir_path, file_name)
      FileUtils.mkpath(File.join(@dir_path, 'unprocessable_masterfiles') )
      FileUtils.mv( path, File.join(@dir_path, 'unprocessable_masterfiles', file_name) )
    end

    # Returns boolean: true if we are running on Windows, false otherwise.
    def running_on_windows?
      RUBY_PLATFORM =~ /mswin32/ || RUBY_PLATFORM =~ /mingw32/
    end

end

