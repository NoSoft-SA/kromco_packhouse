class Tester
  
  attr_reader :func_areas,:base_dir
  #-------------------------------------------------------------------------
  #The constructor gets a list of all functional areas, each one, containing
  #a list of all test files (one per controller)
  #-------------------------------------------------------------------------
  def initialize
    #get a list of all folders, then get a list of all
    #test files for each folder
    @base_dir = __FILE__ + '../../../test/functional/'
   
    @func_areas = Hash.new
    test_dir = Dir.new(@base_dir)
    
    folders = test_dir.entries
    
    folders.each do |folder|
      
        if !File.basename(@base_dir + folder).index(".") 
          if File.ftype(@base_dir + folder)== "directory"
          @func_areas[File.basename(folder)]= get_test_files_for_dir(folder)
          end
        end
    end
  end
  
  def get_functions(func_area,program)
  
    func_module = Inflector.camelize(func_area)
    prog_class = Inflector.camelize(program).gsub(".rb","")
    
    test_functions = Array.new
    path = @base_dir + func_area + "/" + program
    require path
    methods = eval func_module + "::" + prog_class + ".public_instance_methods"
    methods.each do |method|
      
      if method.index("test_")
        test_functions.push method
       
      end
    
    end
    
    return test_functions
    
  end
  
  
  def get_test_files_for_dir(dir)
   
    test_files = Array.new
    files = Dir.entries(@base_dir + dir)
    files.each do |file|
      f = @base_dir + dir + "/" + file
      if File.ftype(f) == "file"
        if File.basename(f).index("_test")!= nil
		   test_files.push file
		   puts file
		end
      end
    end
    
    return test_files
  end


end