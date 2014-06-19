class MidwareErrorLog < ActiveRecord::Base

  attr_accessor :view_bin, :skip_ip, :skip, :carton_number, :line, :bay, :view_carton, :view_pallet, :run_code, :station_code, :line_code, :flow, :object_id, :missing, :new_outbox_entry_record
  
  def create_skip_ip
     
      i= self.short_description.index(":")
      result = self.short_description[i+1,14]
      @strArray = result.split(/\s*/)
      ip = ""
      @strArray.each do |chr|
        if (chr!= ",")
          ip.concat(chr)
        end
      end
      #self.skip_ip = result
      #self.skip_ip = "test"    
      self.skip_ip = ip
      
      skip_record = Skip.find(:first, :conditions => ["ip_address = ?", ip])
      line_config_skip_record = LineConfigsSkip.find(:first, :conditions => ["skip_id = ?", skip_record.id])
      line_record = Line.find(:first, :conditions => ["line_config_id = ?", line_config_skip_record.line_config_id])
      # update
      if line_record!=nil
          self.line = line_record.line_code
      else
          self.line = ""
      end
      #update
      
      b = self.short_description.index(":")
      bay_res = self.short_description[b+1,29]
      @bArray = bay_res.split(/\s*/)
      my_array = Array.new
      @bArray.each do |ch|
        if(ch!= ",")
          my_array.push(ch)
        end
      end
      
      self.bay = my_array[my_array.length()-1]
      
  end
  
  def create_skip_ip_for_nil
      self.skip_ip = "nil"
  end
  
  def get_needed_carton_number
      cn = self.short_description.index(":")
      cn_res = self.short_description[cn+46,15]
      @cnArray = cn_res.split(/\s*/)
      c_num = ""
      @cnArray.each do |c|
          if (c == ":") 
              c_num.concat("")
          elsif(c=="<")
              c_num.concat("")
          elsif(c==",")
              c_num.concat("")
          elsif(c=="d")
              c_num.concat("")
          elsif(c=="?")
              c_num.concat("")
          elsif(c=="A")
              c_num.concat("")
          elsif(c=="a")
              c_num.concat("")
          elsif(c=="B")
              c_num.concat("")
          elsif(c=="^")
              c_num.concat("")
          elsif(c=="s")
              c_num.concat("")
          else
              c_num.concat(c)
          end
      end
      ret_num = c_num.strip
      
      return ret_num
  end
  
  def create_carton_number
      num = get_needed_carton_number
      if num == nil
          self.view_carton = ""
      elsif num == ""
          self.view_carton = ""
      else
          self.view_carton = num
      end 
  end
  
  def create_carton_number_for_nil
      self.view_carton = ""
  end
  
  def create_pallet_number
      cart_num = get_needed_carton_number
      if cart_num == nil
          self.view_pallet = ""
      elsif cart_num == ""
          self.view_pallet = ""
      else
          @cart = Carton.find(:first, :conditions =>["carton_number = ?", cart_num.to_i])
          if @cart == nil
              self.view_pallet = ""
          else
              @pallet = Pallet.find(:first, :conditions =>["id = ?", @cart.pallet_id])
              if @pallet == nil
                  self.view_pallet = ""
              else
                  self.view_pallet = @pallet.pallet_number
              end
          end
      end
      
  end
  
#----------------------------------------------------------
  def create_run_code
      i= self.short_description.index(":")
      result = self.short_description[i+1,13]
      @strArray = result.split(/\s*/)
      ip = ""
      @strArray.each do |chr|
        if (chr == ",")
          ip.concat("")
        elsif(chr == "a")
          ip.concat("")
        elsif(chr == "n")
          ip.concat("")
        else
          ip.concat(chr)
        end
      end
       req_num = ip.strip
      self.production_run_code = req_num
  end
  
  def create_run_code_for_nil
      self.production_run_code = ""
  end
 
 #----------------------------------------------------- 
  def create_station_code
      i = self.short_description.index("code")
      result = self.short_description[i+1,10]
      @strArray = result.split(/\s*/)
      @stat_code = ""
      @strArray.each do |chr|
          if(chr == "")
            @stat_code.concat("")
          elsif(chr == ":")
            @stat_code.concat("")
          elsif(chr == "c")
            @stat_code.concat("")
          elsif(chr == "o")
            @stat_code.concat("")
          elsif(chr == "d")
            @stat_code.concat("")
          elsif(chr == "e")
            @stat_code.concat("")
          else
            @stat_code.concat(chr)
          end
      end
      @req_code = @stat_code.strip
      self.station_code = @req_code
  end
  
  def create_station_code_for_nil
      self.station_code = ""
  end
#--------------------------------------------------------------


#-------------------------MISSING FLOWS--------------------------

def create_flow
 #format is  <text>:<flow + space + text>:<id>
  self.flow = self.short_description.split(":")[1].split(" ")[0]
end

def create_flow_old
    i = self.short_description.index(":")
    result = self.short_description[i+1,17]
    @array = result.split(/\s*/)
    @temp_field = ""
    @array.each do |chr|
        if(chr=="")
            @temp_field.concat("")
        elsif(chr==":")
            @temp_field.concat("")
        else
            @temp_field.concat(chr)
        end
    end
    @flow_field = @temp_field.strip
    self.flow = @flow_field
    puts "FLOW: " + @flow_field
end

def create_flow_for_nil
    self.flow = ""
end



def create_object_id
    i = self.short_description.index("id:")
    result = self.short_description[i+1,8]
    @array = result.split(/\s*/)
    @temp_field = ""
    @array.each do |chr|
        if(chr=="")
            @temp_field.concat("")
        elsif(chr=="i")
            @temp_field.concat("")
        elsif(chr=="d")
            @temp_field.concat("")
        elsif(chr==":")
            @temp_field.concat("")
        else
            @temp_field.concat(chr)
        end
    end
    @object_id_field = @temp_field.strip
    self.object_id = @object_id_field
end

def create_object_id_for_nil
    self.object_id = ""
end

def get_flow
    i = self.short_description.index(":")
    result = self.short_description[i+1,17]
    @array = result.split(/\s*/)
    @temp_field = ""
    @array.each do |chr|
        if(chr=="")
            @temp_field.concat("")
        elsif(chr==":")
            @temp_field.concat("")
        else
            @temp_field.concat(chr)
        end
    end
    @flow_field = @temp_field.strip
    return @flow_field
end

def get_object_id
    @retval = nil
    #if self.short_description.include? "Integration record of type"
    i = self.short_description.index("id:")
    result = self.short_description[i+1,8]
    @array = result.split(/\s*/)
    @temp_field = ""
    @array.each do |chr|
        if(chr=="")
            @temp_field.concat("")
        elsif(chr=="i")
            @temp_field.concat("")
        elsif(chr=="d")
            @temp_field.concat("")
        elsif(chr==":")
            @temp_field.concat("")
        else
            @temp_field.concat(chr)
        end
    end
    @object_id_field = @temp_field.strip
    @retval = @object_id_field
    #end
    return @retval
end

def create_missing

    return if self.missing!=nil

    @val = get_object_id
    if @val!=nil
        t1 = Date.today
        t2 = Date.today + 1
        @t1 = t1.strftime("%Y-%m-%d")
        @t2 = t2.strftime("%Y-%m-%d")
        #@outbox_entry_record = OutboxEntryHistory.find_by_sql("select * from outbox_entry_histories where type_code = 'pallet_completed' and record like '%#{@val}%' and created_on > '#{@t1}' and created_on < '#{@t2}'")
        @outbox_entry_record = OutboxEntryHistory.find(:first, :conditions =>['type_code = ? and created_on > ? and created_on < ? and record like ?', 'pallet_completed', @t1, @t2, '%#{@val}%'])
        @outbox_entry = OutboxEntry.find(:first, :conditions=>["record_id = ?", @val])
        if @outbox_entry_record==nil
            if @outbox_entry == nil
                self.missing = "yes"
            else
                self.missing = "no"
            end
        else
            self.missing = "no"
        end
    end
end

def calc_id
    self.id.to_s + "$" + self.object_id.to_s + "$" + self.flow.to_s
end

def create_missing_for_nil
    self.missing = ""
end

def create_field_flowing
    self.new_outbox_entry_record = "create flow"
end

def create_field_flowing_for_nil
    self.new_outbox_entry_record = ""
end

#--------------------------END OF MISSING FLOWS------------------


#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#     Bad Scans code
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def create_bad_scans_skip
    @index = self.short_description.index("skip ip")
    @result = self.short_description[@index + 1, 22]
    @string = @result.gsub(/[skip:,]/,' ')
    @array = @string.split(/\s*/)
    @skip_number = ""
    @array.each do |char|
        if(char=="")
            @skip_number.concat("")
        elsif(char==":")
            @skip_number.concat("")
        elsif(char==",")
            @skip_number.concat("")
        else
            @skip_number.concat(char)
        end
    end
    self.skip = @skip_number.strip()
end

def create_bad_scans_skip_for_nil
    self.skip = ""
end

def create_bad_scans_bay
    @index = self.short_description.index("bay number")
    @result = self.short_description[@index + 1, 14]
    @string = @result.gsub(/[baynumer:,]/,' ')
    @array = @string.split(/\s*/)
    @bay_number = ""
    @array.each do |char|
        if (char=="")
            @bay_number.concat("")
        elsif(char==",")
            @bay_number.concat("")
        elsif(char==":")
            @bay_number.concat("")
        else
            @bay_number.concat(char)
        end
    end
    self.bay = @bay_number.strip()
end

def create_bad_scans_bay_for_nil
    self.bay = ""
end

def create_bad_scans_carton_number
    @index = self.short_description.index("carton scanned")
    @end_index = self.short_description.index("button pressed")
    @result = self.short_description[@index + 1, @end_index - @index]
    @string = @result.gsub(/[cartonumbersd:,]/,' ')
    @array = @string.split(/\s*/)
    @carton_number =""
    @array.each do |char|
        if (char=="")
            @carton_number.concat("")
        elsif(char==":")
            @carton_number.concat("")
        elsif(char==",")
            @carton_number.concat("")
        elsif(char=="b")
            @carton_number.concat("")
        else
            @carton_number.concat(char)
        end
    end
    self.carton_number = @carton_number.strip()
end

def create_bad_scans_carton_number_for_nil
    self.carton_number = ""
end

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#     end of Bad Scans code
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#    Bin Tipping code
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

def create_run_code
    @index = self.short_description.index("ip")
    @end_index = self.short_description.index("and bin_id")
    @result = self.short_description[@index + 1, @end_index - @index]
    @string = @result.gsub(/[ipa:,]/,' ')
    @array = @string.split(/\s*/)
    @prod_run_code =""
    @array.each do |char|
        if(char==":")
            @prod_run_code.concat("")
        elsif(char=="")
            @prod_run_code.concat("")
        elsif(char==",")
            @prod_run_code.concat("")
        else
            @prod_run_code.concat(char)
        end
    end
    self.run_code = @prod_run_code.strip()
end

def create_run_code_for_nil
    self.run_code = ""
end


def create_bin_number
    
    @index = self.short_description.index("bin_id")
    puts @index.to_s
    @result = self.short_description[@index + 1, 26]
    @string = @result.gsub(/[bin_id:,]/,' ')
    @array = @string.split(/\s*/)
    @bin_num = ""
    @array.each do |char|
      if(char ==":")
          @bin_num.concat("")
      elsif(char=="_")
          @bin_num.concat("")
      elsif(char==",")
          @bin_num.concat("")
      else
          @bin_num.concat(char)
      end
    end
    if @bin_num != ""
        self.view_bin = @bin_num.strip()
    else
        self.view_bin = ""
    end
    
end

def bin_id
    self.id.to_s + "$" + self.view_bin.to_s
end

def create_bin_number_for_nil
    self.view_bin = ""
end

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#    end of Bin Tipping code
#:::::::::::::::::::::::::::::::::::::::::


#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#    create line code
#:::::::::::::::::::::::::::::::::::::::::

def create_line_code
    production_run = ProductionRun.find(:first, :conditions=>['production_run_code = ?', self.production_run_code])
    if production_run != nil
        self.line_code = production_run.line_code
    else
        self.line_code = ""
    end
end

def create_line_code_for_nil
    self.line_code = ""
end

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#    end create line code
#:::::::::::::::::::::::::::::::::::::::::

end
