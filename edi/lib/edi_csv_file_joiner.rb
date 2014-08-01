# Join several edi output csv files into one new one.
class EdiCsvFileJoiner
  include EdiSetup

  # Set attributes, load libraries and models. Make a logfile. Connect to the database.
  def initialize( in_dir, out_dir, flow_type )
    @in_dir    = Pathname.new(in_dir).expand_path
    @out_dir   = Pathname.new(out_dir).expand_path
    @flow_type = flow_type.upcase

    puts "Loading libraries..."
    load_libs
    puts "Libraries loaded"
    
    proc_dir = "edi/logs/join"
    FileUtils.makedirs(proc_dir)
    @edi_log = EdiHelper.make_edi_log(proc_dir, 'join')
    
    begin
      @edi_log.write "Loading models..."
      load_models
      @edi_log.write "Models loaded"

      @edi_log.write "Setting up db connections..."
      @ar_connected = set_up_connections
      @edi_log.write "db connections established"

    rescue StandardError => error
      @edi_log.write "Exception in edi join initialize process.\n " << error, 2
      @edi_log.write "Exception Stacktrace = " + error.backtrace.join("\n").to_s
      raise
    end
  end

  def file_prefix
    @flow_type
  end

  # Set this to true in inherited class if each csv file has a header.
  def has_header
    false
  end

  # Fail if dir is locked.
  #
  # Check the input folder for a lock file. If one is encountered, raise an exception.
  # There should only be one copy of the joiner processing a directory at one time.
  def fail_if_dir_locked
    if Pathname.glob(@in_dir + '*.lck').size > 0
      raise EdiProcessError, 'Input folder is locked. Unable to process. NB. More than one instance cannot process the same folder.'
    end
  end

  # Read all the files in the specified directory.
  # Call combine_files to do the coarse combining.
  # Call move_file to move the combined file to its destination.
  def run
    fail_if_dir_locked

    begin
      # Lock dir before processing any files.
      FileUtils.touch(File.join(@in_dir, 'J&JMesEdi.lck'))

      files = []
      Find.find(@in_dir) do |f|
        if File.file?(f) && File.basename(f).start_with?(file_prefix)
          files << [File.dirname(f), File.extname(f), f]
        end
      end

      if files.empty?
        @edi_log.write "No #{@flow_type} files to process in #{@in_dir}."
        return true
      end
      @edi_log.write "Joining #{files.size} files..."

      grouped_files = files.group_by { |file_array| [file_array[0], file_array[1]] }
      @edi_log.write "#{grouped_files.size} groups of files..."
      @file_set = []
      grouped_files.each do |group, files|
        @files = files.map { |f| f[2] }.sort

        @edi_log.write "Processing group of #{@files.size} files..."

        new_file_name = make_new_file_name(@files[0])

        ext = group[1]
        @outfile  = Tempfile.new('edi_joining')
        @trailers = []
        if has_header
          File.foreach(@files[0]) {|line| @first_header = line; break; }
          @outfile << @first_header
        end

        combine_files

        @outfile.close

        move_file( @files[0], @outfile, new_file_name )

        @edi_log.write "Deleting files..."
        @files.each { |f| @edi_log.write "Deleting #{f}..."; File.delete(f); }
        @edi_log.write "Deleted files."

      end
      @edi_log.write "Joining complete."

      completed_ok = true

    rescue StandardError => error
      @edi_log.write "Exception in main edi join process.\n " << error, 2
      @edi_log.write "Exception Stacktrace = " + error.backtrace.join("\n").to_s
      completed_ok = false

    ensure
      FileUtils.rm( File.join( @in_dir, 'J&JMesEdi.lck'), :force => true) #remove the lock file
    end
    completed_ok
  end

  # Make the new filename with a new sequence number.
  def make_new_file_name( file_name )
    #"#{File.basename(file_name)[0,5]}#{sprintf('%03d', @out_seq)}#{File.extname(file_name)}"
    "#{file_prefix}_#{Time.now.strftime('%Y%m%d-%H%M%S')}#{File.extname(file_name)}"
  end

  # Move the new combined file to the output directory.
  # Checks +from_dir_file+ path to see if it has any subdirs below the +in_dir+.
  # If there are any, retains them in the output path when moving the +out_file+.
  # Writes +out_file+ to the new dir as +new_file_name+.
  #
  # Dirs:
  # * If +in_dir+ is <tt>/edi/staging</tt> and +out_dir+ is <tt>/edi/out</tt>
  # * AND +from_dir_file+ is <tt>/edi/staging/org_ftp/somefile.abc</tt>
  # * AND +new_file_name+ is <tt>a_file.abc</tt>
  # * THEN the file will be moved to <tt>/edi/out/org_ftp/a_file.abc</tt>
  def move_file( from_dir_file, out_file, new_file_name )
    @edi_log.write "Moving file #{new_file_name}..."
    # Move the Tempfile to the final dir.
    this_dir = File.dirname(from_dir_file)
    subdir   = this_dir.sub(@in_dir.to_s, '')
    if subdir.index('/') == 0
      subdir = subdir.reverse.chop.reverse
    end
    FileUtils.makedirs(File.join(@out_dir, subdir)) # Ensure the path exists...
    FileUtils.mv(out_file.path, File.join(@out_dir, subdir, new_file_name))
    FileUtils.chmod(0666, File.join(@out_dir, subdir, new_file_name))
    @edi_log.write "created file #{new_file_name} in #{File.join(@out_dir, subdir)}."
    write_joiner_history( new_file_name )
  end

  # Write EdiOutJoinerHistory records.
  #
  # Records which out files are joined in this new file.
  def write_joiner_history( new_file_name )
    @file_set.each do |f|
      EdiOutJoinerHistory.create( :flow_type           => @flow_type,
                                  :edi_joined_filename => new_file_name,
                                  :edi_out_filename    => f )
    end
  end

  # Read all the files and add their content to the new combined file.
  #
  # If the csv file has a header, the frst row of the first file is retained, all others are discarded.
  def combine_files
    @files.each do |f|
      @edi_log.write "Combining #{f}..."
      @file_set << File.basename(f)

      first = true
      File.foreach(f) do |line|
        if first && has_header
          first = false
          next
        end
        @outfile << line
      end
    end
  end

end

