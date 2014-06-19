class LabelPrintCommand

  attr_accessor :print_command_string
  
  
  def initialize(printer, format,labels_to_print = nil)
    @labels_to_print = labels_to_print
    @labels_to_print == 1 if !@labels_to_print
    @printer = printer
    @format = format
    @print_server_url = Globals.get_label_printing_server_url
    @print_command = Hash.new
      
  end

  def set_print_field(position, value)
    key = "F" + position.to_s
    @print_command[key] = value
  end

  def get_print_field(position)
    key = "F" + position.to_s
    return @print_command[key]
  end

  def fill_empty_fields()
     #---------------------------------------------------------------------------------------------
    #Make sure there are values from F0 to F<last pos>- create empty strings if there are no values
    #----------------------------------------------------------------------------------------------
    for i in 0..@print_command.keys.length() -1
      if ! get_print_field(i)
        set_print_field(i, "")
      end
    end
  end


  def build_label_cmd_string()
    @print_command = @print_command.sort {|a,b| a <=> b}
    print_label = "<ProductLabel PID=\"223\" Status=\"true\" Printer=\"#{@printer}\" MC=\"[NR]\" StartNr=\"1\" CountNr=\"#{@labels_to_print.to_s}\" F0=\"#{@format}\" "

    @print_command.each  do |key,val|
      print_label += key.to_s + "=\"" + val.to_s + "\" "
    end
    print_label += "/>"
    @print_command_string = print_label
    
  end

  #---------------------------------------------------------------------------------------------------
  #This method must be implemented by subclasses- to provide the specific data to print. For each data
  #item that should be added to the print string, clients shoul call the 'set_print_field(position, value)'
  #method to store the data item in the correct sequence in the print command
  #---------------------------------------------------------------------------------------------------
  def set_print_data(*args)
      

  end

  

  def print(*args)
    set_print_data(*args)
    fill_empty_fields
    build_label_cmd_string
    puts " The Print Command String :: " + self.print_command_string.to_s
    http_conn = Net::HTTP.new(Globals.get_label_printing_server_url, Globals.get_label_printing_server_port)
    response = http_conn.request_get("/" + self.print_command_string.to_s)
    puts response.to_s
    puts " RESPONSE BODY :: " + response.body.to_s
    return self.print_command_string.to_s
  end

end