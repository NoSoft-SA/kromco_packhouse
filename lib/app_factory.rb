
#---------------------------------------------
#Adding reverse iteration to the array class
#----------------------------------------------

 RAILS_ROOT = "" if !defined? RAILS_ROOT

class Array

   def iterate_back(start_pos)

    rev_list = self.reverse
    new_pos = self.length - start_pos
    for i in new_pos  ..self.length-1
      yield rev_list[i]
    end
 
   end
end

module AppFactory

class PostgresMetaData
 
 
 def PostgresMetaData.get_first_non_pk_index(index_set)
  
  index_pos = -1
  index_set.each do |index|
    index_pos += 1
    if index["indisprimary"]== "f"
      return index_pos
    end
  end
 end
 
 def PostgresMetaData.get_unique_index_def(columns,connection,table_id)
   begin
      index_query = "SELECT * from pg_index where indrelid = " + table_id.to_s
      index_cols = Array.new
      result = connection.select_all(index_query)
      
      if result == nil ||result.length < 2
        return nil
      else 
        atts_in_index = result[PostgresMetaData.get_first_non_pk_index(result)]["indkey"].split(" ")
        atts_in_index.each do |att|
          if columns.length < att.to_i() 
            err = "Query: '" + index_query + "' returned (as second resultset row) a value in the \n" 
            err +=       " 'indkey' array field, that defines a column position that does not exist in the table \n" +
            err +=       ". To solve this problem, you could force a re-order fields command on the table to re-synchonize\n" +
            err +=      " the index field positions as defined in indkey with the real positions of fields on the table."
            raise err
          end
          index_cols.push(columns[(att.to_i() -1)][:field_name])
        end
        
        return index_cols
      end
    rescue
      raise "An error occurred while trying to fetch index information for table id: " + table_id +
            "Exception reported: \n" + $!
    end
   
      
  end
  
  def PostgresMetaData.get_list_of_tables(connection)
  
    query = "SELECT relname FROM pg_class WHERE relname !~ '^(pg_|sql_)' AND relkind = 'r' order by relname"
    result = connection.select_all(query).map{|g|[g["relname"]]}
    return result
  
  end
  
  def PostgresMetaData.get_column_defs(table_name,connection)
    begin
        sql = "SELECT c.oid, a.attnum, a.attname, t.typname,a.atthasdef, a.attlen, a.attnotnull FROM pg_class as c, pg_attribute a, pg_type t WHERE a.attnum > 0 and a.attrelid = c.oid and c.relname = '" + table_name + "' and a.atttypid = t.oid order by a.attnum"
        result = connection.select_all(sql)
        table_id = result[0]["oid"]
        columns = Array.new
        result.each do |field| 
          field_name = field["attname"]
         
          field_data = Hash.new 
          field_data[:type]= field["typname"]
          field_data[:oid]= field["oid"]
          field_data[:length] = field["attlen"].to_s
          if field["attnotnull"].to_s == "t"
            field_data[:not_null]= true
          else
             field_data[:not_null]= false
          end
          
          field_data[:field_name]= field_name
          
          if field["atthasdef"].to_s == "t"
            field_data[:is_pk]= true
          else
            field_data[:is_pk]= false
          end
          
          columns.push(field_data)
         
        end
        return columns
    rescue
     raise "Meta data could not be retreived for table: " + table_name + "\n Exception reported is : \n" + $!
    end
  return columns
  
  end

  def PostgresMetaData.exists?(table_name,connection)
      begin
        sql = "SELECT oid FROM pg_class  WHERE relname = '" + table_name + "'"
        result = connection.select_all(sql)
        return (result != nil && result.length > 0)
      rescue
        raise "The function: 'PostgresMetaData.exists?' failed for table: " + table_name +
              ". Reported exception: \n " + $!
      end
  end
 
end

class FileUtil

  def FileUtil.make_directory(path)
  
    build_dirs(make_dir_list(path))
  
  end
  
  def FileUtil.write_lines_to_file(full_path,lines)
   puts "in write lines to file. path is: " + full_path 
    begin
        create_file(full_path)
        file = File.new(full_path,"w")
        lines.each do |line| file.puts line + "\n" end
        file.close
     rescue
       raise "File: " + full_path + " could not be created. Exception reported is: \n" + $!
     end
  end
  
  #------------------------------------------------------------------------
  #This is propably the most useful method of this class:
  #It takes a path to a file as argument, and will build the entire set of
  #directories included in the path string- should they be missing
  #Then it will create the file in the bottom-most directory
  #-------------------------------------------------------------------------
  
  def FileUtil.create_file(full_path)
  
    if not File.exists?(full_path)
      file_data = strip_file_from_path(full_path)
      puts file_data[:dir_path]
     FileUtil.make_directory(file_data[:dir_path]) if file_data[:dir_path] != nil
     File.new(full_path, "w").close()
    end
    
  end
  
  def FileUtil.strip_file_from_path(path)
  
    path = path.reverse
    file_start = path.index("/")
    
    if file_start != nil
	    file =  path.slice(0,file_start) 
	     stripped_path = path.reverse.slice(0,path.length - file.length)
    else
	    file = path
	     stripped_path = nil
   end
    
    return {:dir_path => stripped_path, :file => file}
   
  end
  
  
  def FileUtil.make_dir_list(path,list = nil)

    if list == nil
      list = Array.new
    end

    dir_start_pos = path.index("/") 
    if path[0,1] == "/"
	   dir_start_pos += 1
    else
	 dir_start_pos = 0
    end

    remainder = path.slice(dir_start_pos,path.length)
    dir_end_pos = remainder.index("/") 
    if dir_end_pos == nil
	 dir_end_pos = path.length
    end	
    curr_dir_str = path.slice(dir_start_pos,dir_end_pos)
    list.push curr_dir_str
    rest_path = path.slice(dir_end_pos +1 ,path.length)
    return list if rest_path ==nil
 
    make_dir_list rest_path,list

end

def FileUtil.build_dirs(dir_list)

  dir_str = ""
  
  return if dir_list == nil||dir_list.length == 0
  
        n = dir_list.length
	  for i in 0..n-1
		  dir_str += dir_list[i] 
		  dir_str += "/" if i < dir_list.length() -1
		  if  not File.exist?(dir_str) 
			    Dir.mkdir(dir_str)
		  end
	  end
end
end


class ViewSettings

  def initialize(model_settings,functional_area)
    
    raise "model_settings cannot be null" if model_settings == nil
    @model_settings = model_settings
    @functional_area = functional_area
    @code_lines = Array.new
    
  end
  
  #-------------------------------------------------------------------------------------
  #This method generates the 'build_grid' code- that is the 'client' code that uses
  #the grid class (defined in application_helper) to construct the active_widgets
  #grid control
  #------------------------------------------------------------------------------------
  def gen_grid_code
    lines = Array.new
    @code_lines.push " def build_" + @model_settings.model_var_name + "_grid(data_set,can_edit,can_delete)\n"
    #for now all column types will be text, except the two action columns, edit and delete
    @code_lines.push "\tcolumn_configs = []"
    lines = Array.new

    #----------------------------
    #now build the action columns
    #----------------------------
    #edit column
    lines.push "#\t----------------------"
    lines.push "#\tdefine action columns"
    lines.push "#\t----------------------"
    lines.push "\tif can_edit"
    field_def = "\t\tcolumn_configs << {:field_type => 'action',:field_name => 'edit " + @model_settings.model_var_name + "',\n"
    field_def += "\t\t\t:column_caption => 'Edit',\n"
    field_def += "\t\t\t:settings => \n\t\t\t\t {:link_text => 'edit',\n\t\t\t\t:target_action => 'edit_" + @model_settings.model_var_name + "',\n\t\t\t\t"
    field_def += ":id_column => 'id'}}"
    lines.push field_def
    lines.push "\tend\n"

    #delete column

    lines.push "\tif can_delete"
    field_def = "\t\tcolumn_configs << {:field_type => 'action',:field_name => 'delete " + @model_settings.model_var_name + "',\n"
    field_def += "\t\t\t:column_caption => 'Delete',\n"
    field_def += "\t\t\t:settings => \n\t\t\t\t {:link_text => 'delete',\n\t\t\t\t:target_action => 'delete_" + @model_settings.model_var_name + "',\n\t\t\t\t"
    field_def += ":id_column => 'id'}}"
    lines.push field_def
    #lines.push "\tend\n\ return get_data_grid(data_set,column_configs)\nend\n"
    lines.push "\tend\n"

    field_index = 0

    @model_settings.table_columns.each do |column|
      next if ['created_at', 'updated_at'].include? column[:field_name]
      type = nil
      field_name = column[:field_name]
      if field_name!= "id"
        if field_name.index("_id")!= nil
          type = "fkey"
        else
          case column[:type]
            # most types will be text fields, the only exceptions are: date types and bit types
          when "timestamp"
            type = "text"
          else
            type = "text"
          end
        end

        data_type = case column[:type]
                    when 'date', 'timestamp'
                      ", :data_type => 'date'"
                    when 'bool'
                      ", :data_type => 'boolean'"
                    when 'int', 'int4'
                      ", :data_type => 'integer'"
                    when 'numeric'
                      ", :data_type => 'number'"
                    else
                      nil
                    end

        if type == "fkey" #this field is a foreign key, so it must be expanded to the key fields on the related table
          #-------------------DEPRECATED-------------------------------------------------"
          #generate a set of field_defs-one per key in the related index
          #assoc_table = @model_settings.associated_tables[field_name]
          #lines.push "#\t----------------------------------------------------------------------------------------------"
          #lines.push "#\tfields to represent foreign key (" + field_name + ") on related table: " + assoc_table[:table_name] 
          #lines.push "#\t----------------------------------------------------------------------------------------------"

          #index_fields = assoc_table[:index_fields]
          #index_fields.each do |index_field|

          # field_def = "\tcolumn_configs[" + field_index.to_s + "] = {:field_type => 'text',:field_name => '" + index_field + "'}"
          # field_index += 1
          # lines.push(field_def) 
          #end
          #lines.push " "
        else
          field_def = "\tcolumn_configs << {:field_type => 'text', :field_name => '#{field_name}'#{data_type}, :column_caption => '#{Inflector.humanize(field_name)}'}"
          lines.push(field_def)
          field_index += 1
        end
      end
    end

    lines.push("\n\tget_data_grid(data_set,column_configs)\nend\n")

    return lines

  rescue
    raise "The 'gen_grid_code' method failed: Reported exception: \n" + $!
  end
  
  #-------------------------------------------------------------------------------------
  #This method generates the 'build_grid' code for a dataminer search result grid.
  #------------------------------------------------------------------------------------
  def gen_dm_grid_code
    @code_lines.push <<EOC


  def build_#{@model_settings.model_var_name}_dm_grid(data_set, stat, columns_list, can_edit, can_delete, grid_configs)

    column_configs = []

    # ----------------------
    # define action columns
    # ----------------------
    if can_edit
      column_configs << {:field_type => 'action',:field_name => 'edit #{@model_settings.model_var_name}',
        :column_caption => 'Edit',
        :settings =>
      {:link_text => 'edit',
        :target_action => 'edit_#{@model_settings.model_var_name}',
        :id_column => 'id'}}
    end

    if can_delete
      column_configs << {:field_type => 'action',:field_name => 'delete #{@model_settings.model_var_name}',
        :column_caption => 'Delete',
        :settings =>
      {:link_text => 'delete',
        :target_action => 'delete_#{@model_settings.model_var_name}',
        :id_column => 'id'}}
    end

    # Build all other columns from the dataminer yml file.
    build_generic_column_configs(data_set, column_configs, stat, columns_list, grid_configs)

    # Get any other datagrid options from the grid_configs...
    opts = build_grid_options_from_grid_configs(grid_configs)

    get_data_grid(data_set, column_configs, nil, true, nil, opts)
  end
EOC
    
  rescue
    raise "The 'gen_dm_grid_code' method failed: Reported exception: \n" + $!
  end

  def to_code_lines
    
    begin
      @code_lines = Array.new
      @code_lines.push "module " + Inflector.camelize(@functional_area) + "::" + @model_settings.model_name + "Helper"
      @code_lines.push " "
      gen_form_code
      @code_lines.push " "
      gen_search_form_code
      @code_lines.push("\n\n").concat(gen_grid_code)
      gen_dm_grid_code
      @code_lines.push "end"
      return @code_lines
    rescue
      raise "Code generation for view_helper failed. Reported excepton: \n" + $!
    end
  end
  
  def gen_form_code
   
   begin
      @code_lines.push " "
      @code_lines.push " def build_" + @model_settings.model_var_name + "_form(" + @model_settings.model_var_name + ",action,caption,is_edit = nil,is_create_retry = nil)"
      @code_lines.push "#\t--------------------------------------------------------------------------------------------------"
      @code_lines.push "#\tDefine a set of observers for each composite foreign key- in effect an observer per combo involved"  
      @code_lines.push "#\tin a composite foreign key"
      @code_lines.push "#\t--------------------------------------------------------------------------------------------------"
     
      interactive_combo_lines = Array.new
      session_code  = "\tsession[:" + @model_settings.model_var_name + "_form]= Hash.new"
      
      @code_lines.push session_code
    
      @model_settings.associated_tables.each do |table_name,assoc_table|
         
          if assoc_table[:index_fields] != nil 
            puts "a bit further"
            if assoc_table[:index_fields].length() > 1
              puts "quite a bit further"
              @code_lines.push "\t#generate javascript for the on_complete ajax event for each combo for fk table: " + assoc_table[:table_name]
              @code_lines.concat(build_combo_js_gens(assoc_table[:table_name]))
              @code_lines.push "\t#Observers for combos representing the key fields of fkey table: " + table_name
           
              observers_code = build_combo_observers(assoc_table)
            
              interactive_combo_lines.concat(observers_code)
            
              interactive_combo_lines.concat(build_get_combo_lists(assoc_table[:table_name],assoc_table[:index_fields]))
            elsif assoc_table[:index_fields].length()== 1
              @code_lines.push build_simple_lookup_snippet(assoc_table[:index_fields][0],nil,assoc_table[:table_name])  
            end
          else
            field_name = find_lookup_field(assoc_table)
            @code_lines.push build_simple_lookup_snippet(field_name,nil,assoc_table[:table_name])if field_name != nil
          end
      end
     
      @code_lines.concat(interactive_combo_lines)
      @code_lines.push "#\t---------------------------------"
      @code_lines.push "#\t Define fields to build form from"
      @code_lines.push "#\t---------------------------------"
      
      @code_lines.concat(gen_field_configs_code)
      #build_form(golfer,field_configs,"'" + action + "'",'golfer',action,is_edit)
      
      @code_lines.push "\tbuild_form(" + @model_settings.model_var_name + ",field_configs," +
                 "action,'" + @model_settings.model_var_name + "',caption,is_edit)"
                 
      @code_lines.push "\nend"
      return @code_lines
   rescue
    raise "Form_helper code could not be generated for table: " + @model_settings.table_name + 
           "\n Reported exception: " + $!
   end
  end
 
 def gen_search_form_code
     
   begin
      @code_lines.push " "
      @code_lines.push " def build_" + @model_settings.model_var_name + "_search_form(" + @model_settings.model_var_name + ",action,caption,is_flat_search = nil)"
      @code_lines.push "#\t--------------------------------------------------------------------------------------------------"
      @code_lines.push "#\tDefine an observer for each index field"  
      @code_lines.push "#\t--------------------------------------------------------------------------------------------------"
      
      interactive_combo_lines = Array.new
      session_code  = "\tsession[:" + @model_settings.model_var_name + "_search_form]= Hash.new "
      
      @code_lines.push session_code
      
      @code_lines.push "\t#generate javascript for the on_complete ajax event for each combo"
      @code_lines.concat(build_search_combo_js_gen(@model_settings.index_fields))
      @code_lines.push "\t#Observers for search combos"
           
      observers_code = build_search_combo_observers
            
      interactive_combo_lines.concat(observers_code)
            
      interactive_combo_lines.concat(build_get_search_combo_lists(@model_settings.index_fields))
      
      @code_lines.concat(interactive_combo_lines)
      @code_lines.push "#\t----------------------------------------"
      @code_lines.push "#\t Define search fields to build form from"
      @code_lines.push "#\t----------------------------------------"
       
      @code_lines.concat(gen_search_field_configs_code)
      
     
      @code_lines.push "\tbuild_form(" + @model_settings.model_var_name + ",field_configs," +
                 "action,'" + @model_settings.model_var_name + "',caption,false)"
                 
      @code_lines.push "\nend"
      return @code_lines
   rescue
    raise "Search Form_helper code could not be generated for table: " + @model_settings.table_name + 
           "\n Reported exception: " + $!
   end
  end
  
  def find_lookup_field(assoc_table)
  #find the first field that is not the pk
    lookup_field = nil
    assoc_table[:columns].each do |field|
     if field[:is_pk]== false
      lookup_field = field[:field_name]
      break
     end
   end
   return lookup_field
  end
 #-----------------------------------------------------------------------------------
 #This method generates the set of field-config definitions from the table
 #metadata to pass to the 
 #'build_form' method of the application helper- which will generate the actual HTML
 #form. The fields that will be build
 #have two 'sources':
 #1) The native fields on the table self- i.e all non foreign key fields
 #2) The composite fields on the foreign key table- they become a set of 
 #   hierarchically related combo-lists. The hierarchy is determined by the
 #   order of the fields in the foreign key index on the foreign table
 #-----------------------------------------------------------------------------------
  def gen_field_configs_code
    begin
    lookups = Hash.new
    lines = Array.new
    lines.push "\t field_configs = []"
    field_index = 0
    
    @model_settings.table_columns.each do |column|
      next if ['created_at', 'updated_at'].include? column[:field_name]
      type = nil
      field_name = column[:field_name]
      puts "type is: " + column[:type]
      puts "field name is: " + field_name
      if field_name!= "id"
        if field_name.index("_id")!= nil
          type = "DropDownField"
        else
          case column[:type]
        # most types will be text fields, the only exceptions are: date types and bit types
            when "date"
              type = "PopupDateSelector"
            when "timestamp"
              type = "PopupDateTimeSelector "
            when "boolean","bool","bit"
              type = "CheckBox"
            else
              type = "TextField"
          end
       end
       #add basic info- same for all field types
                   
  	   #add additional info, for special types
  	 
  	   if type == "DropDownField" # && @model_settings.associated_tables && @model_settings.associated_tables[field_name] # Uncomment this to generate despite lack of associated model.
  	      
  	       
  	     raise "There is no associated model for #{field_name}." unless @model_settings.associated_tables && @model_settings.associated_tables[field_name]
  	     assoc_table = @model_settings.associated_tables[field_name]
  	     #generate a set of field_defs-one per key in the related index
  	     if assoc_table[:index_fields]!= nil
  	         puts "index fields not nil"
  	         assoc_table = @model_settings.associated_tables[field_name]
  	         lines.push "#\t----------------------------------------------------------------------------------------------"
  	         lines.push "#\tCombo fields to represent foreign key (" + field_name + ") on related table: " + assoc_table[:table_name] 
  	         lines.push "#\t----------------------------------------------------------------------------------------------"
  	     
  	         index_fields = assoc_table[:index_fields]
  	         index_fields.each do |index_field|
  	             #field_def = "\tfield_configs[" + field_index.to_s + "] =  {:field_type => '" + type + "',\n" 
  	             field_def = "\tfield_configs << {:field_type => '" + type + "',\n" 
  	             combo_field_def = field_def + "\t\t\t\t\t\t:field_name => '" + index_field + "',\n"
  	             combo_field_def += "\t\t\t\t\t\t:settings => {:list => " + Inflector.pluralize(index_field) + "},\n"
  	      
  	             if index_field !=  index_fields[index_fields.length()-1] #last item doesn't get observer
  	               combo_field_def += "\t\t\t\t\t\t:observer => " + index_field + "_observer}"
  	             else
  	               combo_field_def = combo_field_def.slice(0, combo_field_def.length() -2) + "}"
  	             end
  	             field_index += 1
  	             lines.push(combo_field_def) 
  	             lines.push " "
  	         end
       else #for related single-field lookup
           puts "index fields is nil"
           lookup_field = find_lookup_field(@model_settings.associated_tables[field_name])
           if lookup_field != nil
  	         lines.push "#\t----------------------------------------------------------------------------------------------------"
  	         lines.push "#\tCombo field to represent foreign key (" + field_name + ") on related table: " + assoc_table[:table_name] 
  	         lines.push "#\t-----------------------------------------------------------------------------------------------------"
              field_def = "\tfield_configs << {:field_type => '" + type + "',\n" 
  	         field_def += "\t\t\t\t\t\t:field_name => '" + lookup_field + "',\n"
  	         field_def += "\t\t\t\t\t\t:settings => {:list => " + Inflector.pluralize(lookup_field) + "}}\n"
  	      
  	         field_index += 1
  	         lines.push(field_def) 
  	         lines.push " "
  	       end
       end
     else
      #any field that is part of a composite foreign key must be ignored here
      
      if is_fkey_field(field_name) == false
        puts "normal field: " + field_name
        field_def = "\tfield_configs << {:field_type => '" + type + "',\n"
        field_def += "\t\t\t\t\t\t:field_name => '" + field_name + "'}\n" 
        lines.push(field_def)
        field_index += 1
        
      end
     end
    end
   end
   puts "returning"
   return lines
   rescue
     raise "method: 'gen_field_configs_code' failed. Reported exception :\n" + $! 
   end
 end
 
 
 #-------------------------------------------------------------------------------
 #This method assumes that the table consists of two fields: 1) the rails
 #id field, which is the PK field and a second field. Since no secondary index
 #has been defined on this table, we'll build a single dropdown form to search
 #this table by this single, second field
 #-------------------------------------------------------------------------------
 def build_single_field_search_config
    
    lines = Array.new
    #find the first, non id field
    field = nil
    @model_settings.table_columns.each do |col|
      if col[:field_name].index("_id") == nil && col[:field_name] != "id"
        field = col[:field_name]
        break
      end
    end
    return [] if field == nil
    
    lines.push "field_configs = []"
    lines.push  build_simple_lookup_snippet(field)
    
     
    type = "DropDownField"
    field_def = "\tfield_configs << {:field_type => '" + type + "',\n" 
  	field_def += "\t\t\t\t\t\t:field_name => '" + field + "',\n"
  	field_def += "\t\t\t\t\t\t:settings => {:list => " + Inflector.pluralize(field) + "}}\n"
  	
  	lines.push field_def  
  	return lines
  	
 end
 
 def gen_search_field_configs_code
    begin
      
      return build_single_field_search_config if @model_settings.index_fields == nil
      
      lines = Array.new
      lines.push "\t field_configs = []"
      field_index = 0
    
  	 
  	     lines.push "#\t----------------------------------------------------------------------------------------------"
  	     lines.push "#\tDefine search Combo fields to represent the unique index on this table "
  	     lines.push "#\t----------------------------------------------------------------------------------------------"
  	     
  	     index_fields = @model_settings.index_fields
  	     index_fields.each do |index_field|
  	       type = "DropDownField"
  	       field_def = "\tfield_configs << {:field_type => '" + type + "',\n" 
  	       combo_field_def = field_def + "\t\t\t\t\t\t:field_name => '" + index_field + "',\n"
  	       combo_field_def += "\t\t\t\t\t\t:settings => {:list => " + Inflector.pluralize(index_field) + "},\n"
  	      
  	       if index_field !=  index_fields[index_fields.length()-1] #last item doesn't get observer
  	         combo_field_def += "\t\t\t\t\t\t:observer => " + index_field + "_observer}"
  	       else
  	         combo_field_def = combo_field_def.slice(0, combo_field_def.length() -2) + "}"
  	       end
  	       field_index += 1
  	       lines.push(combo_field_def) 
  	       lines.push " "
  	     end
       
    return lines
   rescue
    raise "Method 'gen_search_field_configs_code' failed. Reported exception: \n" + $!
   end
 end
 
 def is_fkey_field(field)
  begin
  found = false
  puts "fucking field is: " + field
  @model_settings.associated_tables.each do |key,table|
   
    if table[:index_fields] != nil
     puts "has index"
     puts "table is: " + table[:friendly_name] + ", field is: " + field
#     if table[:friendly_name] == "unit_pack_product_type" && field.to_s == "unit_pack_type_code"
#      breakpoint
#     end
      if table[:index_fields].find{ |item| field.to_s == item.to_s}
        puts "field " + field + " is a fkey field "
        found =true
        break
      end
    else #this is for related tables, without a secondary index, should only be if it's a single column lookup table
      if field == "unit_pack_subtype_code"
       breakpoint
      end
      if table[:columns].find{ |item| field.to_s == item[:field_name].to_s}
        found =true
        break
      end
    end
  end
  puts "is_fkey for field: " + field + " is " + found.to_s
  return found
  rescue
   raise "method: 'is_fkey_field' failed: Reported exception: \n" + $!
  end
 end

  #----------------------------------------------------------------------
  #This method builds a line of  list retrieval code
  #e.g 'clubs = clubs_for_country(golfer_status.country)
  #----------------------------------------------------------------------
  def build_interactive_combo_list_query(index_fields,index_field_position,table_name)
    begin
        lines = Array.new
        field_plural = Inflector.pluralize(index_fields[index_field_position])
        method_name = "\t\t" +  field_plural + " = " + @model_settings.model_name + "." + field_plural + "_for_"
        # iterate from the position just before the current position to
        # the first position of the passed-in index_fields (and add each field to the method name)
        query_fields = index_fields.reverse
        new_pos = index_fields.length - index_field_position
        params = "("
        for i in new_pos  ..index_fields.length-1
          params += @model_settings.model_var_name + "." + Inflector.singularize(table_name) + "." + query_fields[i]
          method_name += query_fields[i] 
          if i < index_fields.length-1
              method_name += "_and_"
              params += ", "
          end
        end
    
        params += ")"
        lines.push(method_name + params)
     rescue
      raise "Method: 'build_interactive_combo_list_query' failed. Reported exception: \n " + $!
     end
  
  end
  #----------------------------------------------------------------------------------------------
  #This method generates the code that retrieve the various lists for a given composite key
  #----------------------------------------------------------------------------------------------
  def build_get_combo_lists(table_name,index_fields)
    begin
        puts "in build get como lists"
        lines = Array.new
        lines.push "#\tcombo lists for table: " + table_name + "\n"
        index_fields.each do |field|
          lines.push "\t" + Inflector.pluralize(field) + " = nil " 
        end
    
        lines.push " "
    
        model = Inflector.camelize(Inflector.singularize(table_name)) 
        var_name = @model_settings.model_var_name
        lines.push "\t" + Inflector.pluralize(index_fields[0]) + " = " + @model_settings.model_name + ".get_all_" + Inflector.pluralize(index_fields[0]) 
    
        lines.push "\tif " + var_name + " == nil||is_create_retry"
        for i in 1..index_fields.length() -1
          lines.push "\t\t " + Inflector.pluralize(index_fields[i]) + " = [\"Select a value from " + index_fields[i -1] + "\"]" 
        end 
    
        lines.push "\telse"
      
        #build the set of lists queries
        for i in 1..index_fields.length() -1
          lists_code = build_interactive_combo_list_query(index_fields,i,table_name)
          lines.concat(lists_code)
        end
        
        lines.push "\tend"
        return lines
      rescue
        raise "method: build_get_combo_lists failed. Reported exception: \n" + $! 
      end
   
  end
  
  def build_simple_lookup_snippet(field_name,not_first = nil,table_name = nil)
    
    owner = @model_settings.model_name
    if table_name == nil 
      table_name = @model_settings.table_name
    else
       owner = Inflector.camelize(Inflector.singularize(table_name))
    end
    
    plural = Inflector.pluralize(field_name)
    line = "\t" + plural + " = " + owner  
    line += ".find_by_sql('select distinct " + field_name + " from " + table_name + "').map{|g|[g." + field_name + "]}"
    # if not_first
    #   line += "\n\t\t" + plural + ".unshift(\"<empty>\")"
    # else
    #    line += "\n\t" + plural + ".unshift(\"<empty>\")"
    # end
    return line
 
 end
 
  def build_get_search_combo_lists(index_fields)
    begin
        
        return [] if index_fields == nil
        lines = Array.new
        
        lines.push " "
    
        model = @model_settings.model_name
        var_name = @model_settings.model_var_name
        lines.push(build_simple_lookup_snippet(index_fields[0]))
        lines.push "\tif is_flat_search"
        for i in 1..index_fields.length() -1
         lines.push("\t" +  build_simple_lookup_snippet(index_fields[i],true))
         
        end
        
        for i in 0..index_fields.length() -1
          if i < index_fields.length() -1
            lines.push("\t\t" +  index_fields[i] + "_observer = nil")
          end
        end
        
        lines.push "\telse"
        for i in 1..index_fields.length() -1
          lines.push "\t\t " + Inflector.pluralize(index_fields[i]) + " = [\"Select a value from " + index_fields[i -1] + "\"]" 
        end 
        lines.push "\tend"
        return lines
      rescue
        raise "method: build_get_search_combo_lists failed. Reported exception: \n" + $! 
      end
   
  end
  #----------------------------------------------------------------------------------
  #This method generates, for each composite foreign key in the model, a line of code
  #that uses the 'gen_combos_clear_js_for_combos' helper method to generate java
  #script that manages the 'on-complete' ajax event interactions between combos
  #on the client browser
  #-----------------------------------------------------------------------------------
  def build_combo_js_gens(table_name)
   
    begin
        lines = Array.new
        
        @model_settings.associated_tables.each do |table_name,assoc_table|
         
          line = nil
         
          if assoc_table[:index_fields] != nil 
            if assoc_table[:index_fields].length > 1
              line = "\tcombos_js_for_" + assoc_table[:table_name] + " = gen_combos_clear_js_for_combos(["
              assoc_table[:index_fields].each do |key_field|
                line += "\"" + @model_settings.model_var_name + "_" + key_field + "\","
              end
             end
        end
        line = line.slice(0,line.length() -1) + "])" if line != nil
        lines.push line if line != nil
      end
         return lines
      rescue
        raise "method:  build_combo_js_gens  failed. Reported exception: \n " + $!
      end
  end
  
  #-----------------------------------------------------------
  # Generate on_complete javascript for search combo observers
  #-----------------------------------------------------------
    def build_search_combo_js_gen(index_fields)
      begin
        return [] if index_fields == nil
        line = nil
        line = "\tsearch_combos_js = gen_combos_clear_js_for_combos(["
        index_fields.each do |key_field|
           line += "\"" + @model_settings.model_var_name + "_" + key_field + "\","
         end
        
        line = line.slice(0,line.length() -1) + "])"
        
         return [line]#return as array
      rescue
        raise "method:  build_search_combo_js_gen  failed. Reported exception: \n " + $!
      end
  end
  
  #-------------------------------------------------------------------------------------
  #This method generates, for a given composite foreign key in the model, a line of code
  #that defines an observer for each combo\field in the key that can filter a dependant
  #combo
  #-------------------------------------------------------------------------------------
  def build_combo_observers(associated_table)
    begin
        
        return [] if associated_table == nil||associated_table[:index_fields]== nil
        lines = Array.new
        
  	   fields = associated_table[:index_fields]
  	   for i in 0.. fields.length() - 2 do
  	     line = "\t" + fields[i] + "_observer  = {:updated_field_id => \"" + fields[i + 1] + "_cell\","
  	     line += "\n\t\t\t\t\t :remote_method => '" + @model_settings.model_var_name + "_" + fields[i] + "_changed',"
  	     line += "\n\t\t\t\t\t :on_completed_js => combos_js_for_" + associated_table[:table_name] + " [\"" + @model_settings.model_var_name + "_" + fields[i] + "\"]}"
  	     line += "\n"
  	     lines.push line
  	     session_code = "\tsession[:" + @model_settings.model_var_name + "_form][:" + fields[i] + "_observer] = " + fields[i] + "_observer\n" 
  	     
  	     lines.push(session_code)
  	     
  	   end
     
      return lines
    rescue
      raise "method: build_combo_observers failed. Reported exception: \n " + $!
    end
  	
  end
  
  def build_search_combo_observers()
    begin
        
        return [] if @model_settings.index_fields == nil
        lines = Array.new
        
  	   fields = @model_settings.index_fields
  	   for i in 0.. fields.length() - 2 do
  	     line = "\t" + fields[i] + "_observer  = {:updated_field_id => \"" + fields[i + 1] + "_cell\","
  	     line += "\n\t\t\t\t\t :remote_method => '" + @model_settings.model_var_name + "_" + fields[i] + "_search_combo_changed',"
  	     line += "\n\t\t\t\t\t :on_completed_js => search_combos_js[\"" + @model_settings.model_var_name + "_" + fields[i] + "\"]}"
  	     line += "\n"
  	     lines.push line
  	     session_code = "\tsession[:" + @model_settings.model_var_name + "_search_form][:" + fields[i] + "_observer] = " + fields[i] + "_observer\n" 
  	     
  	     lines.push(session_code)
  	     
  	   end
     
      return lines
    rescue
      raise "method: build_seach_combo_observers failed. Reported exception: \n " + $!
    end
  	
  end
  
  
end


#---------------------------------------------------------------------------
#This class builds CRUD controller functions: add,edit,delete and find
#for a given database table. It receives an instance of the ModelSettings
#class as input
#----------------------------------------------------------------------------
class ControllerSettings
  
  #------------------------------------------------------------------------------------------
  #construction parameters:
  #'included_functions' is an optional hash with the following keys
  # 'edit','create','delete': A 'true' value indicates that code should be
  # generated for the function.
  # 
  #
  #
  #------------------------------------------------------------------------------------------
  def initialize(model_settings,functional_area,included_functions = nil,program_name = nil)
  
    raise " The 'model_settings' constructor argument cannot be null" if model_settings == nil
    
    @functional_area = functional_area
    @path = functional_area + "/" + model_settings.model_var_name + "/"
    @model_settings = model_settings
    @included_functions = included_functions
    
    
  end
  
  #--------------------------------------------------------------------------------------------
  #This method adds the security & navigation link entries in the database that is
  #needed for both security and navigation purposes
  #The functional area must be in existence. This method will add 
  #new records to the following tables:
  # table:programs (related to the given functional area)
  # table: program_functions (related to the created program)
  #
  #note: security for this program needs to be defined externally, by using the
  #      security application. For these CRUD applications, the existing
  #      db_groups could be used (table_add,table_edit,table_view,table_delete,table_admin)
  #      The security app allows one to add a user to a program with a defined
  #      security group (which contain a set of permissions). If you need more combinations
  #      than provided in the pre-defined groups, simply create more groups, e.g. table_view_edit
  #----------------------------------------------------------------------------------------------
  def create_app_environment
    
   
  end
  
  def to_code_lines
  
    lines = Array.new
    lines.push "class  " + Inflector.camelize(@functional_area) + "::" + @model_settings.model_name + "Controller < ApplicationController"
    lines.push " "
    lines.push "def program_name?"
    lines.push "\t\"" + @model_settings.model_var_name + "\""
    lines.push "end\n"
    lines.push "def bypass_generic_security?"
    lines.push "\ttrue"
    lines.push "end"
    lines.concat(generate_list_entity_code)
    lines.push " "
    lines.concat(generate_search_entity_flat())
    lines.push " "
    lines.concat(generate_search_entity_hierarchy()) if @model_settings.index_fields != nil
    lines.push " "
    lines.concat(generate_submit_entity_search())
    lines.push " "
    lines.push generate_delete_entity #text is returned here, not an array
    lines.push " "
    lines.concat(generate_create_entity_code)
    lines.push " "
    lines.concat(generate_save_created_entity_code)
    lines.push " "
    lines.concat(generate_update_entity_code)
    lines.push " "
    lines.concat(generate_save_updated_entity_code)
    lines.push " "
    lines.push generate_dataminer_search
    lines.push " "
    lines.push generate_dataminer_search_results
    lines.push " "
    lines.concat(gen_dynamic_combos_handlers)#if @model_settings.index_fields != nil
    lines.push " "
    lines.concat(gen_dynamic_search_combos_handlers) if @model_settings.index_fields != nil
    lines.push "\nend"
    return lines
    
  end
  
  def generate_dataminer_search
    single = @model_settings.model_var_name
    plural = Inflector.pluralize(single)
    human  = Inflector.humanize(plural)
    str = <<EOC
  def search_dm_#{plural}
    return if authorise_for_web(program_name?,'read')== false
    dm_session['se_layout']              = 'content'
    @content_header_caption              = "'Search #{human}'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form('search_#{plural}.yml', 'search_dm_#{plural}_grid')
  end
EOC
    str
  end
  
  def generate_dataminer_search_results
    single = @model_settings.model_var_name
    plural = Inflector.pluralize(single)
    human  = Inflector.humanize(plural)
    str = <<EOC
  def search_dm_#{plural}_grid
    @#{plural} = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    @can_edit        = authorise(program_name?, 'edit', session[:user_id])
    @can_delete      = authorise(program_name?, 'delete', session[:user_id])
    @stat            = dm_session[:search_engine_query_definition]
    @columns_list    = dm_session[:columns_list]
    @grid_configs    = dm_session[:grid_configs]

    render :inline => %{
      <% grid            = build_#{single}_dm_grid(@#{plural}, @stat, @columns_list, @can_edit, @can_delete, @grid_configs) %>
      <% grid.caption    = '#{human}' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end
EOC
    str
  end
  #----------------------------------------------------------------------------------
  #This method generates, for each associated table, a set of combo handlers.
  # a combo handler is needed for each combo, except the last one in an index field
  #collection,because each handler method has to filter the next combo in the
  #composite key hierarchy of the foreign key (that the combo is part of)
  #----------------------------------------------------------------------------------
  def gen_dynamic_combos_handlers
  
  lines = Array.new
  @model_settings.associated_tables.each do |key,assoc_table|
    if assoc_table[:index_fields]!= nil
      lines.push "#\t--------------------------------------------------------------------------------"
      lines.push "#\t combo_changed event handlers for composite foreign key: " + key
      lines.push "#\t---------------------------------------------------------------------------------"
      for i in 0..assoc_table[:index_fields].length() -2 #as said, ignore the last field- it doesn't need handler
        lines.concat(gen_combo_changed_handler(assoc_table,i))
        lines.push "\n"
      end
    end
  end
  
  return lines
  
  end
  
 def gen_dynamic_search_combos_handlers
    
    return [] if @model_settings.index_fields == nil
    
    lines = Array.new
  
    lines.push "#\t-----------------------------------------------------------------------------------------------------------"
    lines.push "#\t search combo_changed event handlers for the unique index on this table(" + @model_settings.table_name + ")"
    lines.push "#\t-----------------------------------------------------------------------------------------------------------"
    for i in 0..@model_settings.index_fields.length() -2 #as said, ignore the last field- it doesn't need handler
      lines.concat(gen_search_combo_changed_handler(@model_settings.index_fields,i))
      lines.push "\n"
    end
    
    return lines
  
  end
  
  #-----------------------------------------------------------------------------------------------
  #This method generates inline rendering for a dynamic combo according to the following algorithm:
  #-> If: the current combo has an index position (in index_fields collection) of '< (coll.length -1)
  #   then, the next field, in the collection, needs to have it's combo,observer and loader image
  #   replaced
  #-> Else: the next field, in the collection, only needs to have it's combo replaced 
  #------------------------------------------------------------------------------------------
  def gen_combo_rendering(index_fields,curr_field_pos,is_search_combo = nil)
    begin
      var_name = index_fields[curr_field_pos + 1]
      comment = "\#\trender (inline) the html to replace the contents of the td that contains the dropdown \n"
      line = comment + "\trender :inline => %{\n"
      line += "\t\t<%= select('" + @model_settings.model_var_name + "','" + var_name + "',@" + Inflector.pluralize(var_name) + ")%>\n"
      if curr_field_pos < index_fields.length() -2
        line += "\t\t<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_" + @model_settings.model_var_name + "_" + var_name + "'/>\n"
        if is_search_combo
           line += gen_search_combo_observer(index_fields,curr_field_pos)
        else
          line += gen_combo_observer(index_fields,curr_field_pos)
        end
      end
      line += "\n\t\t}"
      return line
    rescue
      raise "combo rendering code genertion failed: Reported exception: \n " + $!
    end
    
  end
  
  def gen_combo_observer(index_fields,curr_field_pos)
   begin
      observe_field = index_fields[curr_field_pos + 1]
      replace_field = index_fields[curr_field_pos + 2]
      puts  "of: " + observe_field.to_s + replace_field.to_s 
      session_var = "session[:" + @model_settings.model_var_name + "_form][:" + observe_field + "_observer]"
      #<%= observe_field('golfer_club',:update => "status_cell",:url => 
      #{:action => session[:golfer_form][:club_observer][:remote_method]},:loading => "show_element('img_golfer_club');", 
      #:complete => session[:golfer_form][:club_observer][:on_completed_js] )%>
      line = "\t\t<%= observe_field('" + @model_settings.model_var_name + "_" + observe_field + "',:update => "
      line += "'" + replace_field + "_cell',:url => {:action => " + session_var + "[:remote_method]},:loading => "
      line += "\"show_element('img_" + @model_settings.model_var_name + "_" + observe_field + "');\","
      line += ":complete => " + session_var + "[:on_completed_js])%>"
      return line
    rescue
      raise "method 'gen_combo_observer' failed. Reported exception: \n" + $!
    end
  end
  
   def gen_search_combo_observer(index_fields,curr_field_pos)
   begin
      observe_field = index_fields[curr_field_pos + 1]
      replace_field = index_fields[curr_field_pos + 2]
     
      session_var = "session[:" + @model_settings.model_var_name + "_search_form][:" + observe_field + "_observer]"
    
      line = "\t\t<%= observe_field('" + @model_settings.model_var_name + "_" + observe_field + "',:update => "
      line += "'" + replace_field + "_cell',:url => {:action => " + session_var + "[:remote_method]},:loading => "
      line += "\"show_element('img_" + @model_settings.model_var_name + "_" + observe_field + "');\","
      line += ":complete => " + session_var + "[:on_completed_js])%>"
      return line
    rescue
      raise "method 'gen_search_combo_observer' failed. Reported exception: \n" + $!
    end
  end
  #-------------------------------------------------------------------------------
  #This method generates a controller handler method for a combo that has changed
  #------------------------------------------------------------------------------- 
  def gen_combo_changed_handler(assoc_table,field_pos)
    begin
      lines = Array.new
      fields = assoc_table[:index_fields]
      lines.push "def " + @model_settings.model_var_name + "_" + fields[field_pos] + "_changed"
      lines.push "\t" + fields[field_pos] + " = get_selected_combo_value(params)"
      #code to store selected value in session
      lines.push "\tsession[:" + @model_settings.model_var_name + "_form][:" + fields[field_pos] + "_combo_selection] = " + fields[field_pos]
      #get the values of all the fields with lower indice than the current field
      params = "("
      method = "\t@" + Inflector.pluralize(fields[(field_pos + 1)]) + " = "
      method += @model_settings.model_name + "." + Inflector.pluralize(fields[(field_pos + 1)]) + "_for_"                    
      vars = Array.new
      session_var = "\tsession[:" + @model_settings.model_var_name + "_form][:"
   
      fields.iterate_back(field_pos + 1) do |curr_field|
        lines.push "\t" + curr_field + " = " + session_var + curr_field + "_combo_selection]" if curr_field != fields[field_pos]
        params += curr_field + ","
        method += curr_field + "_and_"
      end
    
      method =  method.slice(0,method.length()-5)
      params =  params.slice(0,params.length()-1)
    
      lines.push method + params + ")"
      lines.push gen_combo_rendering(assoc_table[:index_fields],field_pos)
      
      lines.push "\nend"
       return lines
    rescue
    raise "Method: 'gen_combo_changed_handler' failed for table: " + assoc_table[:table_name] + 
           "and field: " + assoc_table[:index_fields][field_pos] + ". Reported exception: \n " + $!
            
    end
    
    end
  
   def build_lookup_snippet(index_field_position,index_fields,lookup_table_name)
 
    field = index_fields[index_field_position]
    field_plural = Inflector.pluralize(field)
  
    # iterate from the position just before the current position to
    # the first position of the passed-in index_fields (and add each field to the method name)
    query_fields = index_fields.reverse
    new_pos = index_fields.length - index_field_position
    params = "("
    for i in new_pos  ..index_fields.length-1
      params += query_fields[i]
      
       if i < index_fields.length-1
          params += ", "
       end
    end
    
    params += ")"
    
    line=  "\t@" + field_plural + " = " + Inflector.camelize(Inflector.singularize(lookup_table_name))
    line += ".find_by_sql(\"Select distinct " + field + " from " + lookup_table_name 
    line += " where "
    #    '#{country}'
    for i in new_pos  ..index_fields.length-1
      line += query_fields[i] + " = '\#{" + query_fields[i] + "}'"
      line += " and " if i < index_fields.length-1
    end
    
    line += "\").map{|g|[g." + field + "]}\n"
    # line += ( "\t@" + field_plural + ".unshift(\"<empty>\")\n")
    return line
 
 end
 
  #-------------------------------------------------------------------------------------
  #This method generates a controller handler method for a search combo that has changed
  #------------------------------------------------------------------------------------- 
  def gen_search_combo_changed_handler(index_fields,field_pos)
    begin
      lines = Array.new
      fields = index_fields
      lines.push "def " + @model_settings.model_var_name + "_" + fields[field_pos] + "_search_combo_changed"
      lines.push "\t" + fields[field_pos] + " = get_selected_combo_value(params)"
      #code to store selected value in session
      lines.push "\tsession[:" + @model_settings.model_var_name + "_search_form][:" + fields[field_pos] + "_combo_selection] = " + fields[field_pos]
      #get the values of all the fields with lower indice than the current field
     
      session_var = "\tsession[:" + @model_settings.model_var_name + "_search_form][:"
   
      fields.iterate_back(field_pos + 1) do |curr_field|
        lines.push "\t" + curr_field + " = " + session_var + curr_field + "_combo_selection]" if curr_field != fields[field_pos]
      end
    
      lines.push(build_lookup_snippet(field_pos + 1,index_fields,@model_settings.table_name))
     
      lines.push gen_combo_rendering(index_fields,field_pos,true)
      
      lines.push "\nend"
       return lines
    rescue
    raise "Method: 'gen_search_combo_changed_handler' failed for table: " + assoc_table[:table_name] + 
           "and field: " + assoc_table[:index_fields][field_pos] + ". Reported exception: \n " + $!
            
    end
    
    end
    
  def generate_search_entity_rendering
  
    lines = Array.new
    
     method_name = "render_" + @model_settings.model_var_name
     var = Inflector.pluralize(@model_settings.model_var_name)
     lines.push "def " + method_name + "_search_form(is_flat_search = nil)"
     lines.push "\tsession[:is_flat_search] = @is_flat_search"
     line = "#\t render (inline) the search form\n"
     line += "\trender :inline => %{\n"
     line += "\t\t<% @content_header_caption = \"'search  " + var + "'\"%> \n\n"
     line += "\t\t<%= build_" + @model_settings.model_var_name + "_search_form(nil,'submit_" + var + "_search','submit_" + var + "_search',@is_flat_search)%>\n"
     line += "\n\t\t}, :layout => 'content'"
     line += "\nend"
     lines.push line
     return lines
  
  end
  
  def generate_search_entity_flat
     lines = Array.new
     
     #flat search
      var = Inflector.pluralize(@model_settings.model_var_name)
      method_name = "search_" +  var 
     lines.push "def " + method_name + "_flat"
     lines.push "\treturn if authorise_for_web(program_name?,'read')== false"
     
     lines.push "\t@is_flat_search = true "
     lines.push "\trender_" + @model_settings.model_var_name + "_search_form"
     lines.push "end\n"
     lines.concat(generate_search_entity_rendering())
     
     
     return lines
     
  end
  
   def generate_search_entity_hierarchy
     lines = Array.new
     
     #flat search
      var = Inflector.pluralize(@model_settings.model_var_name)
      method_name = "search_" +  var 
      lines.push "def " + method_name + "_hierarchy"
      lines.push "\treturn if authorise_for_web(program_name?,'read')== false"
      lines.push " "
      lines.push "\t@is_flat_search = false "
     lines.push "\trender_" + @model_settings.model_var_name + "_search_form(true)"
     lines.push "end\n"
     #lines.concat(generate_search_entity_rendering())
     
     
     return lines
     
  end
  
  def generate_create_entity_code
    
     lines = Array.new
     method_name = "new_" + Inflector.underscore(@model_settings.model_name)
     lines.push "def " + method_name 
     lines.push "\treturn if authorise_for_web(program_name?,'create')== false"
     #lines.push "\t @" + Inflector.underscore(@model_settings.model_name) + " = " + @model_settings.model_name + ".new"
     #lines.push "\t render :template => '" + @path + method_name + "', :layout => 'content'"
      lines.push "\t\trender_new_" + Inflector.underscore(@model_settings.model_name) 
     lines.push "end"
     return lines
  
  end
  
  def generate_submit_entity_search
  
     lines = Array.new
     #flat search
      var_name = Inflector.pluralize(@model_settings.model_var_name)
      method_name = var_name + "_search" 
     lines.push "def submit_" + method_name 
   
    
     lines.push "\t@" + var_name + " = dynamic_search(params[:" +@model_settings.model_var_name + "] ,'" + var_name + "','" + @model_settings.model_name + "')" 
    
    
	 lines.push "\tif @" + var_name + ".length == 0"
	 lines.push "\t\t\tflash[:notice] = 'no records were found for the query'"
	 lines.push "\t\t\t@is_flat_search = session[:is_flat_search].to_s"
	 lines.push "\t\t\trender_" + @model_settings.model_var_name + "_search_form"
	 lines.push "\t\telse"

	 lines.push "\t\t\trender_list_" + var_name
	
     lines.push "\tend"
     lines.push "end\n"
     
     return lines
     
 
  end
  
  def generate_delete_entity
 
    line = "def delete_" + @model_settings.model_var_name + "\n"
#    line += " begin\n"
    line += "\treturn if authorise_for_web(program_name?,'delete')== false\n"
    #if params[:page]
	# session[:program_functions_page] = params['page']
	# render_list_program_functions 
	# return
	#end
    line += "\tif params[:page]\n"
    line += "\t\tsession[:" + @model_settings.table_name + "_page] = params['page']\n"
    line += "\t\trender_list_" + @model_settings.table_name + "\n\t\treturn\n\tend\n"
    
    line += "\tid = params[:id]\n"
    line += "\tif id && " + @model_settings.model_var_name + " = " + @model_settings.model_name + ".find(id)\n"
    line += "\t\t" + @model_settings.model_var_name + ".destroy\n"
    line += "\t\tsession[:alert] = ' Record deleted.'\n"
    #line += "#\t\t update in-memory recordset\n"
    #line += "\t\t@" + Inflector.pluralize(@model_settings.model_var_name) + " = session[:" + Inflector.pluralize(@model_settings.model_var_name) + "]\n"
    #line += "\t\t delete_record(@" + Inflector.pluralize(@model_settings.model_var_name) + ",id)\n"
    #line += "\t\tsession[:" + Inflector.pluralize(@model_settings.model_var_name) + "] = @" + Inflector.pluralize(@model_settings.model_var_name) + "\n"
    #line += "\t\trender_list_" + Inflector.pluralize(@model_settings.model_var_name) + "\n\tend\nrescue\n\thandle_error('record could not be deleted')\nend\nend"
    line += "\t\trender_list_#{Inflector.pluralize(@model_settings.model_var_name)}\n"
    line += "\tend\n\trescue"
    line += "\n\t\thandle_error('record could not be deleted')\nend"
    return line
  end
  
  def generate_save_created_entity_code
   
     lines = Array.new
     method_name = "create_" + Inflector.underscore(@model_settings.model_name)
     var_name = Inflector.underscore(@model_settings.model_name)
     lines.push "def " + method_name
#     lines.push " begin"
     lines.push "\t @" + var_name + " = " + @model_settings.model_name + ".new(params[:"  + var_name + "])"                        
     lines.push "\t if @" + var_name + ".save"
     #lines.push "\t#update in-memory list- if it exists"
     #lines.push "\t\tif session[:" + Inflector.pluralize(var_name) + "]"
     #lines.push "\t\t\t session[:" + Inflector.pluralize(var_name) + "].push @" + var_name 
     #lines.push "\t\tend" 
     lines.push "\t\t redirect_to_index(\"new record created successfully\",\"'create successful'\")"
     lines.push "\telse"
     lines.push "\t\t@is_create_retry = true"
     #lines.push "\t\t render :template => '" + @path + "new_" + var_name + "', :layout => 'content'"
     lines.push "\t\trender_new_" + var_name
     lines.push "\t end"
     lines.push "rescue"
     lines.push "\t handle_error('record could not be created')"
#     lines.push "end"
     lines.push "end\n"
     lines.push generate_create_entity_rendering
  
  end
  
  def generate_update_entity_code
  
    lines = Array.new
    var_name = Inflector.underscore(@model_settings.model_name)
    method_name = "edit_" + var_name
    lines.push "def " + method_name
    lines.push "\treturn if authorise_for_web(program_name?,'edit')==false "
    lines.push "\t id = params[:id]"
    lines.push "\t if id && @" + var_name + " = " + Inflector.camelize(var_name) + ".find(id)"
    #lines.push "\t\t render :template => '" + @path + method_name + "',:layout => 'content'"
    lines.push "\t\trender_edit_" + var_name + "\n"
    lines.push "\t end"
    lines.push "end\n\n"
    lines.push generate_update_entity_rendering
   
  end

  
  def generate_list_entity_rendering

    var =  Inflector.pluralize(@model_settings.model_var_name)
    line = "def render_list_" + var + "\n"
    line += "\t@pagination_server = \"list_" + @model_settings.table_name + "\"\n"
    #can_edit = authorise(program_name?,'edit',session[:user_id])
    line += "\t@can_edit = authorise(program_name?,'edit',session[:user_id])\n"
    line += "\t@can_delete = authorise(program_name?,'delete',session[:user_id])\n"
    #@current_page = session[:program_functions_page] if session[:program_functions_page]
    #@current_page = params['page'] if params['page']
    line += "\t@current_page = session[:" + @model_settings.table_name + "_page]\n"
    line += "\t@current_page = params['page']||= session[:" + @model_settings.table_name + "_page]\n"
    #@program_functions = eval(session[:query]) if !@program_functions
    line += "\t@" + @model_settings.table_name + " =  eval(session[:query]) if !@" + @model_settings.table_name + "\n"
    line += "\trender :inline => %{\n"
    line += "\t\t<% grid = build_" + @model_settings.model_var_name + "_grid(@" + var + ",@can_edit,@can_delete)%>\n"
    line += "\t\t<% grid.caption = 'list of all " + var + "'%>\n"
    line += "\t\t<% @header_content = grid.build_grid_data %>\n\n"
    #<% @pagination = pagination_links(@golfer_pages)if @golfer_pages != nil %>
    line += "\t\t<% @pagination = pagination_links(@" + @model_settings.model_var_name + "_pages) if @"
    line += @model_settings.model_var_name + "_pages != nil %>\n"
    line += "\t\t<%= grid.render_html %>\n\t\t<%= grid.render_grid %>\n"
    line += "\t},:layout => 'content'\nend"

  end
  
  
    def generate_create_entity_rendering
    
     var = @model_settings.model_var_name
     line = "\def render_new_" + var + "\n"
     
     line += "#\t render (inline) the edit template\n"
     line += "\trender :inline => %{\n"
     line += "\t\t<% @content_header_caption = \"'create new " + var + "'\"%> \n\n"
     line += "\t\t<%= build_" + var + "_form(@" + var + ",'create_" + var + "','create_" + var +"',false,@is_create_retry)%>\n"
     line += "\n\t\t}, :layout => 'content'"
     line += "\nend"
     return line
  	 
  end
  
  def generate_update_entity_rendering
    
     var = @model_settings.model_var_name
     line = "\def render_edit_" + var + "\n"
     line += "#\t render (inline) the edit template\n"
     line += "\trender :inline => %{\n"
     line += "\t\t<% @content_header_caption = \"'edit " + var + "'\"%> \n\n"
     line += "\t\t<%= build_" + var + "_form(@" + var + ",'update_" + var + "','update_" + var +"',true)%>\n"
     line += "\n\t\t}, :layout => 'content'"
     line += "\nend"
     return line
  	 
  end
  
  def generate_save_updated_entity_code
  
    lines = Array.new
    var_name = Inflector.underscore(@model_settings.model_name)
    method_name = "update_" + var_name
    lines.push "def " + method_name
#    lines.push " begin\n"
    #line = "\tif params[:page]\n"
    #line += "\t\tsession[:" + @model_settings.table_name + "_page] = params['page']\n"
    #line += "\t\trender_list_" + @model_settings.table_name + "\n\t\treturn\n\tend\n"
    #lines.push line
    #lines.push "\t\t@current_page = session[:" + @model_settings.table_name + "_page]"
    
    lines.push "\t id = params[:" + var_name + "][:id]"
    lines.push "\t if id && @" + var_name + " = " + Inflector.camelize(var_name) + ".find(id)" 
    lines.push "\t\t if @" + var_name + ".update_attributes(params[:" + var_name + "])"
    #lines.push "#\t\tupdate the in-memory recordset- to save db call"
    #lines.push "\t\t\tupdate_record(session[:" + Inflector.pluralize(var_name) + "],@" + var_name + ".attributes,id)"
    #@golfers = session[:golfers]
	#render_list_golfers
	lines.push "\t\t\t@" + @model_settings.table_name + " = eval(session[:query])"
	lines.push "\t\t\tflash[:notice] = 'record saved'"
	lines.push "\t\t\trender_list_" + @model_settings.table_name
    lines.push "\t\ else"
    lines.push "\t\t\t render_edit_" + var_name
    lines.push "\t\t end"
    lines.push "\t end"
    lines.push "rescue"
    lines.push "\t handle_error('record could not be saved')"
 #   lines.push "end"
    
    lines.push " end"
    return lines
         
  end
  
  def generate_list_entity_code
    
     lines = Array.new
     var_name = Inflector.pluralize(Inflector.underscore(@model_settings.model_name))
     method_name = "list_" + var_name
     
     lines.push "def " + method_name
    
     lines.push "\treturn if authorise_for_web(program_name?,'read') == false "
     lines.push "\n \tif params[:page]!= nil \n"
     lines.push " \t\tsession[:" + @model_settings.table_name + "_page] = params['page']\n"
     lines.push "\t\t render_list_" + @model_settings.table_name 
     lines.push "\n\t\t return \n\telse\n\t\tsession[:" + @model_settings.table_name + "_page] = nil\n\tend"
    
     query_text = "\n\tlist_query = \"@" + @model_settings.model_var_name + "_pages = Paginator.new self, " + @model_settings.model_name 
     query_text += ".count, @@page_size,@current_page"
     lines.push query_text
     line = "\t @" + var_name + " = " + @model_settings.model_name  + ".find(:all,\n"
     line += "\t\t\t\t :limit => @" + @model_settings.model_var_name + "_pages.items_per_page,\n"
     line += "\t\t\t\t :offset => @" + @model_settings.model_var_name + "_pages.current.offset)\""
     lines.push line
     lines.push "\tsession[:query] = list_query"
     
     #lines.push " \t render :template => '" + @path + method_name + "', :layout => 'content'"
     lines.push "\trender_list_" + var_name
     lines.push "end\n\n"
     lines.push generate_list_entity_rendering
     
  end
  

end


class ModelFactory
  
  #@@models_settings_path = File.dirname(__FILE__) + '../../app/models/'
  @@models_settings_path = File.join(RAILS_ROOT, 'app', 'models')
  #--------------------------------------------------------------------------------
  #This method exists mainly to allow a modelSettings class to persist it's
  #state. This method will first check whether an instance of the ModelSetting
  #class with the name of the input table exists. If so it uses ruby's serializing
  #capabilities to load the instance; otherwise it creates a new instance, which
  #will infer many model settings from database metadata
  #---------------------------------------------------------------------------------
  def ModelFactory.get_settings(table_name,force_create = nil)
   
    settings = load_settings(table_name)
 
    if settings == nil||force_create
       
       settings = ModelSettings.new(table_name)
     
    end
    
    return settings
  end
  
 
  
  #-------------------------------------------------------------------------------
  #This method calls itself recursively to format a line of code with font colors
  #and styling- i.e. it will insert multiple formatting into the single line
  #--------------------------------------------------------------------------------
   def ModelFactory.to_htm_line(code)
   
    end_pos = 0
    found = false
    color = ""
    bold = ""
    is_var = false
    single_end_condition = false
    bold_end = ""
    pos = 10000
    tpos = 0
    terminate_char = " "
   
     if tpos = code.index("class ")
      single_format = true
      pos = tpos
      color = "'gray'"
      bold = "<strong>"
      bold_end = "</strong>"
    end
    
     if tpos = code.index("module ")
      single_format = true
      pos = tpos
      color = "'gray'"
      bold = "<strong>"
      bold_end = "</strong>"
    end
      
   if tpos = code.index("def ")
      single_format = false
      terminate_char = "\n"
      single_end_condition = true
      pos = tpos
      color = "'purple'"
      bold = "<strong>"
      bold_end = "</strong>"
    end
    
    if tpos = code.index(":") 
     if code[tpos+1..tpos+1]!= ":"
       if  tpos < pos
         single_format = false
         is_var = true
          pos = tpos
          color = "'brown'"
          bold = ""
          bold_end = ""
       end
     end
    end
    if tpos = code.index("@") 
      if    tpos < pos
      single_format = false
       pos = tpos
       color = "'blue'"
       is_var = true
       bold = ""
       bold_end = ""
     end
    end
    if tpos = code.index("#") 
     if    tpos < pos
       single_end_condition = true
       terminate_char = "\n"
       pos = tpos
       color = "'green'"
       bold = ""
       bold_end = ""
     end
    end
    if tpos = code.index("if ") 
      if tpos < pos
       single_format = false
       pos = tpos
       color = "'purple'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
     if tpos = code.index("else") 
      if tpos < pos
       pos = tpos
       color = "'purple'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
    if tpos = code.index("end ") 
      if  tpos < pos
      single_format = false
       pos = tpos
       color = "'purple'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
     if tpos = code.index("\tend") 
      if  tpos < pos
       pos = tpos
       color = "'purple'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
      if tpos = code.index("\tend\t") 
      if  tpos < pos
       pos = tpos
       color = "'purple'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
      if tpos = code.index("\tend\n") 
      if  tpos < pos
       single_format = false
       pos = tpos
       color = "'purple'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
    if tpos = code.index("\nend") 
      if  tpos < pos
       pos = tpos
       color = "'purple'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
      if tpos = code.index("end\t") 
      if  tpos < pos
       pos = tpos
       color = "'purple'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
    if tpos = code.index("end\n") 
      if  tpos < pos
       pos = tpos
       color = "'purple'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
      if tpos = code.index(" end") 
      if  tpos < pos
       pos = tpos
       color = "'purple'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
    if tpos = code.index(" in ") 
     if    tpos < pos
       pos = tpos
       color = "'blue'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
    if tpos = code.index("each") 
     if  tpos < pos
       pos = tpos
       color = "'blue'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
    if tpos = code.index(" do ") 
      if    tpos < pos
       pos = tpos
       color = "'blue'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
   if tpos = code.index("\"") 
      if    tpos < pos && ! single_end_condition
       terminate_char = "\""
      
       pos = tpos
       color = "'orange'"
       bold = ""
       bold_end = ""
     end
    end
      if tpos = code.index("'") 
      if    tpos < pos && ! single_end_condition
       single_format = false
       terminate_char = "'"
       pos = tpos
       color = "'orange'"
       bold = ""
       bold_end = ""
     end
    end

    if tpos = code.index("return") 
      if    tpos < pos
      
       pos = tpos
       color = "'blue'"
       bold = "<strong>"
       bold_end = "</strong>"
     end
    end
    if pos < 10000
      right_part = code.slice(pos,code.length)
      terminate = false
      for i in 1..right_part.length() -1
        char = right_part[i..i].to_s 
	
        if !single_end_condition 
          if  char == terminate_char||char == ","||char == "\n"
            terminate = true
            end_pos = i + 1
	     end
	    else
	      if  char == terminate_char||char == "\n"
            terminate = true
            end_pos = i + 1
	     end
	    end
	    if  terminate == false && is_var && (char == "]"||char == "[" ||char == "."||char == ")")
	      terminate = true
	      end_pos = i
	    end
	    if terminate
         
	      found = true
          break
         
       end
      end
      end_pos = 0 if single_format 
      end_pos = code.length if end_pos == 0
   
      remainder = code.slice((end_pos + pos) ,(code.length()-(end_pos + pos))) if  found && single_format == false
      
      plain_text = ""
      if pos > 0
	      plain_text = code.slice(0,pos)
	      
      end
      code = plain_text + "<font color = " + color + ">" + bold  + code.slice(pos,end_pos) + bold_end + "</font>"
      
      code += to_htm_line(remainder) if remainder != nil
    end
    
   return code
      
  end
  
  #---------------------------------------------------------------------------------------
  #This method generate an html document that formats the code with color and style, while
  #retaining the spacing and layout of the code
  #---------------------------------------------------------------------------------------
  def ModelFactory.format_code_to_htm(code)

    htm = "<div class='CodeRay'><pre>"
    if ENV['USE_CODERAY']
      #str = CodeRay.encode(code.join("\n"), :ruby, :html, :css => :style, :tab_width => 2).gsub("\n", "<br />")
      str = CodeRay.encode(code.join("\n"), :ruby, :html, :tab_width => 2).gsub("\n", "<br />")
      htm << str
    else
      code.each do |line|
        htm += to_htm_line(line) + "\n"
      end
    end

    htm << "</pre></div>"
    
  end
  
  def ModelFactory.create_model_file(model_settings,ignore_confirmation = true,create_code_file = nil)
  
    code_lines = model_settings.to_code_lines(ignore_confirmation)
    path = model_settings.model_file_path
    
    path = model_settings.model_file_path.slice(0,model_settings.model_file_path.length() - 3) + "_code_gen.rb" if create_code_file != nil
    FileUtil.write_lines_to_file(path,code_lines)
    
  end
  
  def ModelFactory.create_controller_file(table_name,functional_area,create_code_file = nil)
    
    model_settings = ModelFactory.get_settings(table_name)
   
    model_settings.functional_area = functional_area
    path = model_settings.controller_file_path
    path = model_settings.controller_file_path.slice(0,model_settings.controller_file_path.length() - 3) + "_code_gen.rb" if create_code_file != nil
    controller_settings = ControllerSettings.new(model_settings,functional_area)
    code_lines = controller_settings.to_code_lines
    FileUtil.write_lines_to_file(path,code_lines)
    return code_lines #for convenience
  end
  
  def ModelFactory.create_view_helper_file(table_name,functional_area,create_code_file = nil)
    
    model_settings = ModelFactory.get_settings(table_name)
    model_settings.functional_area = functional_area
    path = model_settings.helper_file_path
    path = model_settings.helper_file_path.slice(0,model_settings.helper_file_path.length() - 3) + "_code_gen.rb" if create_code_file != nil
   
    view_settings = ViewSettings.new(model_settings,functional_area)
    code_lines = view_settings.to_code_lines
    FileUtil.write_lines_to_file(path,code_lines)
    return code_lines #for convenience
  end
  
  
  def ModelFactory.save_settings(model_settings)
    #File.open(@@models_settings_path + model_settings.model_name, "w+") do |f|
    File.open(File.join(@@models_settings_path, model_settings.model_name), "w+") do |f|
    Marshal.dump(model_settings, f)
    end
  end
  
  def ModelFactory.load_settings(name)
     settings = nil
     if File.exists?(File.join(@@models_settings_path,  name))
          File.open(File.join(@@models_settings_path,  name)) do |f|  
            settings = Marshal.load(f)  
          end  
     end
     return settings
  end

end


#----------------------------------------------------------------------------------
#The ModelSettings class helps with the creation of active record model
#objects. It uses database metadata to infer various model associations
#and declarations. This class is also useful for building forms
#-----------------------------------------------------------------------------------
 class ModelSettings
  
   # @@models_path = File.dirname(__FILE__) + '../../app/models/'
   # @@views_path = File.dirname(__FILE__) + '../../app/views/'
   # @@view_helpers_path = File.dirname(__FILE__) + '../../app/helpers/'
   # @@controllers_path = File.dirname(__FILE__) + '../../app/controllers/'
   @@models_path       = File.join(RAILS_ROOT, 'app','models')
   @@views_path        = File.join(RAILS_ROOT, 'app','views')
   @@view_helpers_path = File.join(RAILS_ROOT, 'app','helpers')
   @@controllers_path  = File.join(RAILS_ROOT, 'app','controllers')
  
   attr_reader :associated_tables,:index_fields,:table_columns, :unique_fields,:associated_tables,:numeric_fields,:model_file_path,:view_file_path,:model_name,:table_name,:model_var_name,
               :code_lines,:helper_file_path,:view_create_path,:view_created_path,:view_edit_path,:view_updated_path,:view_list_path,:view_search_path,:controller_file_path
   
  public
 
  def functional_area=(func_area)
  
   # @helper_file_path = @@view_helpers_path + func_area + "/" + @model_var_name + "_helper.rb"
   # @controller_file_path = @@controllers_path + func_area + "/" + @model_var_name + "_controller.rb"
   @helper_file_path     = File.join(@@view_helpers_path, func_area, @model_var_name + "_helper.rb")
   @controller_file_path = File.join(@@controllers_path,  func_area, @model_var_name + "_controller.rb")
   
   #several views- normally one file per controller method
   # @view_create_path = @@views_path  + func_area + "/" + "create_" + @model_var_name + ".rb"
   # @view_created_path = @@views_path  + func_area + "/" + @model_var_name + "_created.rb"
   # @view_edit_path = @@views_path  + func_area + "/" + "edit_" + @model_var_name + ".rb"
   # @view_updated_path = @@views_path  + func_area + "/" + @model_var_name + "_updated.rb"
   # @view_list_path = @@views_path  + func_area + "/" + "list_" + @table_name + ".rb"
   # @view_search_path = @@views_path  + func_area + "/" + "search_" + @table_name + ".rb" 
   @view_create_path  = File.join(@@views_path, func_area, "create_" + @model_var_name + ".rb")
   @view_created_path = File.join(@@views_path, func_area, @model_var_name + "_created.rb")
   @view_edit_path    = File.join(@@views_path, func_area, "edit_" + @model_var_name + ".rb")
   @view_updated_path = File.join(@@views_path, func_area, @model_var_name + "_updated.rb")
   @view_list_path    = File.join(@@views_path, func_area, "list_" + @table_name + ".rb")
   @view_search_path  = File.join(@@views_path, func_area, "search_" + @table_name + ".rb" )
   
  end
   
  def initialize(table_name)
  
   begin
  #RAILS_DEFAULT_LOGGER.info ">>> In init." 
      @table_name = table_name
      @model_var_name = Inflector.singularize(table_name)
      @model_name = Inflector.camelize(table_name).singularize
      @model = nil
   
      #@model_file_path = @@models_path + Inflector.singularize(@table_name) + ".rb"
      @model_file_path = File.join(@@models_path, Inflector.singularize(@table_name) + ".rb")
     
      #validation definer arrays
      @required_fields = Hash.new
      @unique_fields = Hash.new
      @required_associations = Hash.new
      #this holds the list of inferred associations 
      @associated_tables = Hash.new
   
      #these hold the actual, declared association definitions
      @has_one_declarations = Hash.new
      @has_many_declarations = Hash.new
      @belongs_to_declarations = Hash.new
      @lookup_definitions = Hash.new
      @attr_accessors = Hash.new #needed as 'natural' fields to represent/map to foreign keys
      @after_find_statements = Array.new
      @fk_validations = Hash.new
      
      @numeric_fields = Hash.new
      @code_lines = nil
 
      create_active_record_instance(build_initial_model)
      
      @table_columns = PostgresMetaData.get_column_defs(table_name,@model.connection)
      puts "in init"
      @index_fields = PostgresMetaData.get_unique_index_def(@table_columns,@model.connection,@table_columns[0][:oid])
    
      infer_model_settings
    rescue
      raise "Model settings for table: " + table_name + " could not be initialized. Exception reported: \n" + $!
    end
  end
  
  private
  def build_initial_model
     
    lines = Array.new
    lines.push "class " + @model_name + " < ActiveRecord::Base"
    lines.push "end"
    return lines
    
  end
  
  def find_lookup_field(assoc_table)
  #find the first field that is not the pk
    lookup_field = nil
    assoc_table[:columns].each do |field|
     if field[:is_pk]== false
      lookup_field = field[:field_name]
      break
     end
   end
   return lookup_field
  end
  
  #--------------------------------------------------------------
  # This method takes the various settings hashes and generates
  # the code as lines of text in the form of an array. The method:
  # 'FileUtil.write_lines_to_file' can then be used to create the
  # actual model file
  #--------------------------------------------------------------
  public
  def to_code_lines (ignore_confirmation = nil)
      file_lines = Array.new
     begin
        file_lines.push "class " + @model_name + " < ActiveRecord::Base "
        
        file_lines.push "\t" 
        file_lines.push "#\t==========================="
        file_lines.push "# \tAssociation declarations:"
        file_lines.push "#\t==========================="
        @has_one_declarations.each do |key, decl| file_lines.push "\t" + decl end
        file_lines.push " "
        @has_many_declarations.each do |key, decl| file_lines.push "\t" + decl end
        file_lines.push " "
        @belongs_to_declarations.each do |key, decl| file_lines.push "\t" + decl end
        file_lines.push " "
        file_lines.push "#\t============================"
        file_lines.push "#\t Validations declarations:"
        file_lines.push "#\t============================"
        @required_fields.each do | key,decl| file_lines.push "\t" + decl end
        @unique_fields.each do |key,decl| file_lines.push "\t" + decl end
        @numeric_fields.each do |key,decl| file_lines.push "\t" + decl end
        #----Deprecated-2june 2006--------------------------------------
       # file_lines.push "#\t========================================="
       # file_lines.push "#\t Attribute accessors: (for foreign keys)"
       # file_lines.push "#\t========================================="
       # @attr_accessors.each do |key,val|
       #   file_lines.push "\t" + val 
       # end
       #
       # file_lines.push "#\t============================================================"
       # file_lines.push "#\t After find loaders(loading of accessors from foreign key tables) "
       # file_lines.push "#\t============================================================"
       # file_lines.push "def after_find\n"
       # @after_find_statements.each do |statement|
       # file_lines.push "\t" + statement
       # end
       # file_lines.push " end\n"
        # #------end deprecation----------------------------------------
       
        #if @index_fields != nil && @index_fields.length > 0
        
          file_lines.push "#\t====================="
          file_lines.push "#\t Complex validations:"
          file_lines.push "#\t====================="
          file_lines.push "def validate "
          file_lines.push "#\tfirst check whether combo fields have been selected"
          file_lines.push "\t is_valid = true"
          
          @fk_validations.keys.each do |assoc_table|
           
            file_lines.push "\t if is_valid"
            line = "\t\t is_valid = ModelHelper::Validations.validate_combos(["
            @fk_validations[assoc_table].each do |field|
              line += "{:" + field + " => self." + field + "},"
            end
            line = line.slice(0,line.length() -1) + "],self) \n\tend"
            file_lines.push line
            file_lines.push "\t#now check whether fk combos combine to form valid foreign keys"
            file_lines.push "\t if is_valid"
            file_lines.push "\t\t is_valid = set_" + assoc_table 
            file_lines.push "\t end"
          end
          
          
          if @index_fields != nil && @index_fields.length > 0
         
            file_lines.push "\t#validates uniqueness for this record"
            file_lines.push "\t if self.new_record? && is_valid"
            file_lines.push "\t\t validate_uniqueness\n\t end"
            file_lines.push "end\n"
            file_lines.concat(build_validate_uniqueness_method)
              
          else
             file_lines.push "end\n"
          end
          
        
        
             
          file_lines.push "#\t==========================="
          file_lines.push "#\t foreign key validations:"
          file_lines.push "#\t==========================="
        
          file_lines.concat(build_fkey_validations)
           
        
        file_lines.push "#\t==========================="
        file_lines.push "#\t lookup methods:"
        file_lines.push "#\t==========================="
        
        @associated_tables.each do |key,lookup_table_def|
            if lookup_table_def[:index_fields] != nil
              file_lines.concat(build_lookup_code(lookup_table_def))
              
            end
        end
     
        file_lines.push "\n\n"
        file_lines.push "end"
        @code_lines = file_lines
        return file_lines
        rescue
        raise "Code could not be generated for model: " + @model_name + ". Reported exception: \n" + $!
        end
     
  end
  
  #---------------------------------------------------------
  #This method creates the model file from the initial model
  #and then loads the first record as instance- using a bit
  #of reflection
  #---------------------------------------------------------
  private
   def create_active_record_instance(code_lines)
     begin
     puts "model path is: " + @model_file_path
      if File.exists?(@model_file_path)== false
        FileUtil.write_lines_to_file(@model_file_path,code_lines)
      end
      @model = eval(@model_name + ".new")
     rescue
       raise "An instance of model: " + @model_name + " could not be created. Exception reported is: \n" + $!
     end
   end
 
 #--------------------------------------------------------------------
 #This method infers from the model the various settings, specifically:
 # -> associations (including lookup tables)
 # -> numeric fields
 # -> required fields
 #---------------------------------------------------------------------
 private
 def infer_model_settings
    #lookup tables and associated tables
    begin
     
        get_associated_table_defs
        #other settings
        @table_columns.each do |col|
          if col[:field_name].index("_id") == nil && col[:field_name] != "id"
            if col[:type] == "int4"
              @numeric_fields[col[:field_name]]= "validates_numericality_of :" + col[:field_name]
            end
            if col[:not_null] == true
              @required_fields[col[:field_name]]= "validates_presence_of :" + col[:field_name] unless ['created_at', 'updated_at'].include?(col[:field_name])
            end
          end
        end 
    rescue
      raise "Setting could not be inferred for model: " + @model_name + " Reported exception: \n" + $!
    end
 end
 
 def build_fkey_validations
  
  fkey_validation_lines = Array.new
  @associated_tables.keys.each do |table_name|
    lines = Array.new
    var_name = Inflector.singularize(@associated_tables[table_name][:table_name])
    lines.push "def set_" + var_name + "\n"
    line = "\t" + var_name + " = " + Inflector.camelize(var_name) + ".find_by_"
    params = "("
    unique_fields_str = ""
    if @associated_tables[table_name][:index_fields] != nil && @associated_tables[table_name][:index_fields].length > 0
      @associated_tables[table_name][:index_fields].each do |field|
        
        line += field + "_and_"
        params += "self." + field + ","
        unique_fields_str += "'" + field + "' and "
      end
      unique_fields_str = unique_fields_str.slice(0,unique_fields_str.length() - 4)
      params = params.slice(0,params.length()-1)
      line = line.slice(0,line.length() - 5) + params + ")"
      lines.push line
      lines.push "\t if " + var_name +" != nil "
      lines.push "\t\t self." + var_name + " = " + var_name
      lines.push "\t\t return true"
      lines.push "\t else"
    
      lines.push "\t\terrors.add_to_base(\"combination of: " + unique_fields_str + " is invalid- it must be unique\")"
      lines.push "\t\t return false"
      lines.push "\tend\nend"
      fkey_validation_lines.concat(lines)
      fkey_validation_lines.push " "
      
    else #for a relation to a simple (i.e. single-field, no index defined) lookup table
        field = find_lookup_field(@associated_tables[table_name])
        if field != nil
          line += field + "(" + "self." + field + ")"
          unique_fields_str += "'" + field + "'"
          lines.push line
          lines.push "\t if " + var_name +" != nil "
          lines.push "\t\t self." + var_name + " = " + var_name
          lines.push "\t\t return true"
          lines.push "\t else"
          lines.push "\t\terrors.add_to_base(\"value of field: " + unique_fields_str + " is invalid- it must be unique\")"
          lines.push "\t\t return false"
          lines.push "\tend\nend"
          fkey_validation_lines.concat(lines)
          fkey_validation_lines.push " "
        end
    end
  end
  return fkey_validation_lines 
 end
 
 
 
 def build_validate_uniqueness_method
 
    lines = Array.new
    lines.push "def validate_uniqueness"
    line = "\t exists = " + @model_name + ".find_by_"
    params = "("
    unique_fields_str = ""
    @index_fields.each do |field|
      line += field + "_and_"
      params += "self." + field + ","
      unique_fields_str += "'" + field + "' and "
    end
    unique_fields_str = unique_fields_str.slice(0,unique_fields_str.length() - 4)
    params = params.slice(0,params.length()-1)
    line = line.slice(0,line.length() - 5) + params + ")"
    lines.push line
    lines.push "\t if exists != nil "
    lines.push "\t\terrors.add_to_base(\"There already exists a record with the combined values of fields: " + unique_fields_str + "\")"
    lines.push "\tend\nend"
    
    
 end
    

 private
 #---------------------------------------------------------------------------
 #This method generates a single lookup method from the perspective of a
 #specific index field in the collection of index fields: e.g. if the lookup
 #table name is 'countries' and the index fields
 #collection contains fields: 'country', 'club' and 'status' and the
 #index position is 2, the generated method would be:
 #'def statuses_for_club_and_country(club,country)
 #--------------------------------------------------------------------------
  def build_lookup_method(index_field_position,index_fields,lookup_table_name)
 
    lines = Array.new
    field = index_fields[index_field_position]
    field_plural = Inflector.pluralize(field)
  
    method_name = "def self." + field_plural + "_for_"
    # iterate from the position just before the current position to
    # the first position of the passed-in index_fields (and add each field to the method name)
    query_fields = index_fields.reverse
    new_pos = index_fields.length - index_field_position
    params = "("
    for i in new_pos  ..index_fields.length-1
      params += query_fields[i]
      method_name += query_fields[i] 
       if i < index_fields.length-1
          method_name += "_and_"
          params += ", "
       end
    end
    
    params += ")"
    lines.push(method_name + params + "\n")
    line=  "\t" + field_plural + " = " + Inflector.camelize(Inflector.singularize(lookup_table_name))
    line += ".find_by_sql(\"Select distinct " + field + " from " + lookup_table_name 
    line += " where "
    #    '#{country}'
    for i in new_pos  ..index_fields.length-1
      line += query_fields[i] + " = '\#{" + query_fields[i] + "}'"
      line += " and " if i < index_fields.length-1
    end 
    
    line += "\").map{|g|[g." + field + "]}"
    lines.push(line+ "\n")
    # lines.push( "\t" + field_plural + ".unshift(\"<empty>\")")
    lines.push(" end")
 
 end
 
 def build_simple_lookup_method(field_name,table_name)
  
  lines = Array.new
  plural = Inflector.pluralize(field_name)
  lines.push "def self.get_all_" + plural + "\n"
  sql = "\t" + plural + " = " + Inflector.camelize(Inflector.singularize(table_name))
  sql += ".find_by_sql('select distinct " + field_name + " from " + table_name + "').map{|g|[g." + field_name + "]}"
  lines.push(sql + "\nend")
  return lines
 
 end
 #---------------------------------------------------------------------------
 #This method generates a set of methods to provide lookup data.
 #The methods are built from the set of index fields in the following manner:
 #-> It is assumed that a strict hierarchy exists between the index fields
 #   according to their ordinal position in the 'index_fields' array
 #-> The first index field is used to generate a 'get_all' list
 #-> For each successive item, a method is built that combines all the
 #   preceding fields as query parameters for that method
 #---------------------------------------------------------------------------
  def build_lookup_code(column_def)
    begin
      lines = Array.new
      #build the first 'get_all' method
      index_fields = column_def[:index_fields]
      table_name = column_def[:table_name]
      index_pos = 0
      lines.push "#\t------------------------------------------------------------------------------------------"
      lines.push "#\tLookup methods for the foreign composite key of id field: " + column_def[:fkey_field_name] 
      lines.push "#\t------------------------------------------------------------------------------------------"
      lines.push " "
      for i in 0  ..index_fields.length-1
        simple_lines = build_simple_lookup_method(index_fields[i],table_name) 
        simple_lines.push "\n\n"
        lines.concat(simple_lines)
        if i > 0
          complex_lines = build_lookup_method(i,index_fields,table_name) 
          complex_lines.push "\n\n"
          lines.concat(complex_lines)
        end
      end
      
      return lines
      
    rescue
      raise "Lookup data retrieval code generation failed for column: " + column_def[:friendly_name] + " for model: " + @model_name + "\n Reported exception: " + $!
    end
  return lines
 
 end
   
 #--------------------------------------------------------------------------------
 #This method looks for any fields of this model that indicates- via its name-
 #a relation to another table. It queries the database meta data to verify the
 #existence of such a related table and , if found, builds up a hash of
 #values that describe the relation- this is done for all related (fkey) fields
 #The only kinds of associations that can be picked up from the table definition
 #are associations that this table is dependant on, they are:
 #-> The 'belongs_to' association. This association can be a simple or complex
 #   lookup (complex meaning 'more than one field defines the lookup)
 #   Other association types, i.e. the independant types, namely:
 #   -> "has one" or "has many" cannot be inferred, because their key fields
 #      are not defined on this table, but on the dependant one.
 #   These (latter) types must be explicitly defined by the user, without
 #   any help from inference (could, however, be validated)
 #---------------------------------------------------------------------------------
 private
 def get_associated_table_defs
  begin 
      @table_columns.each do |col|
          assoc_table = nil  
          
          if col[:field_name].index("_id") != nil && col[:type] == "int4" 
            assoc_table = Inflector.pluralize(col[:field_name].slice(0,col[:field_name].index("_id")))
            if PostgresMetaData.exists?(assoc_table,@model.connection)
           
              @associated_tables[col[:field_name]] = get_association_def(col,assoc_table)
            end
          end
      end
   rescue 
      raise "get_associated_table_defs method failed. Exception reported: \n" + $!
   end
  end
 
 #------------------------------------------------------------------------------
 #This method assumes the existence of the associated table with name defined with
 #argument 'assoc_table' that is associated via field with the same name as 
 #'assoc_table', but with  '_id' appended to it. 
 #This method builds up a hash with values that describe the association
 #Additionally, this method adds three declarations for any field pointing to
 #a related table:
 # - > validates_associated <related entity>
 # - > validates_presence_of <related entity >
 # ->  belongs_to <related entity>  
 #------------------------------------------------------------------------------
 private
 def get_association_def(column_def,assoc_table)
   begin
      
      assoc_table_def = Hash.new
      assoc_table_def[:friendly_name] = Inflector.singularize(assoc_table)
      assoc_table_def[:fkey_field_name] = column_def[:field_name] 
      assoc_table_def[:table_name] =  assoc_table
      puts "assoc table is: " + assoc_table
  
      @belongs_to_declarations[assoc_table_def[:fkey_field_name]] = "belongs_to :" + assoc_table_def[:friendly_name]
      @required_associations[assoc_table_def[:fkey_field_name]] = "validates_associated :" + assoc_table_def[:friendly_name]
      
      #we already know the related table exists
      assoc_table_def[:columns] = PostgresMetaData.get_column_defs(assoc_table,@model.connection)
      #get the index fields- not the primary key, but secondary 'real' key, (since rails uses a mere serial) 
      # get the table_id- needed to find the index- from any column_def- use e.g. first one
      #(all columns carry the id of the parent table as the :oid symbol 
      
      table_id = assoc_table_def[:columns][0][:oid]
      assoc_table_def[:index_fields] = PostgresMetaData.get_unique_index_def(assoc_table_def[:columns],@model.connection,table_id)
      #A set of hierarchically-related lookup fields will be built according to the order of
      #the index fields
      #populate the '@attr_accessors' from the index fields: a set will be build from the
      #index_fields list for every foreign key- the whole idea is to represent these
      #'natural' fields as a hierarchically related set of attributes directly on the
      #model, so that a very usable UI could be generated from the single model
      
      if assoc_table_def[:index_fields] != nil && assoc_table_def[:index_fields].length > 0 
        @fk_validations[Inflector.singularize(assoc_table)] = assoc_table_def[:index_fields]
      else
        #for simple lookup table- i.e single field, no index
        fields = Array.new
        lookup_field = find_lookup_field(assoc_table_def)
        if lookup_field != nil
          fields.push lookup_field
          @fk_validations[Inflector.singularize(assoc_table)] = fields
        end
        
       #-------------DEPRECATED--2 JUNE 2005-------------------------------------------------------------
       # assoc_table_def[:index_fields].each do |attr|
       #   if @attr_accessors.has_key?(attr)||@table_columns.find {|col| col[:field_name] == attr}
       #     raise "This model already has an attribute or accessor called: " + attr + " .\n" +
       #           "Since this model is de-normalized, you must ensure that fields on foreign key tables are not named the same as " +
       #           " fields on other related foreign key tables or as fields on the parent table" 
       #   else
       #     @attr_accessors[attr] = "attr_accessor :" + attr 
       #     #after find statements for this foreign key- needed to populate the fkey accessors after a find
       #     fkey_class = Inflector.camelize(assoc_table)
       #     @after_find_statements.push "@" + attr + " = self." + Inflector.singularize(assoc_table) + "." + attr
       #   end
       #end
       #------------------END DEPRECATION-----------------------------------------------------------------------------------
      end
      rescue
        raise "The association details for related table: " + assoc_table + " could not be retrieved (for model: " + @model_name + ").Reported exception: \n" + $! 
      end
  return assoc_table_def
 end
 end

  class YamlMaker

    # For a +belongs_to+ association, prefer just the columns that
    # end with _code or _name.
    def self.get_preferred_cols( cols )
      cols.select {|c| c.end_with?( '_code' ) || c.end_with?( '_name' ) }
    end

    # Make a yml file for DataMiner.
    # Takes a classname as a string.
    # Returns a string that can be saved as a yml report file and will
    # run a reasonable query for the class taking into account all +belongs_to+ relations.
    # BUT the yml file WILL require plenty of tweaking!
    def self.make_yml_report_string( for_class, group_name=nil )
      model_class  = for_class.constantize
      column_names = model_class.column_names.dup
      column_names = column_names.delete_if {|c| c.end_with?('_id') || c == 'created_at' || c == 'updated_at' }
      tn           = model_class.table_name
      joins        = []
      sels         = []
      wheres       = []
      grid_configs = {'column_widths' => {}, 'data_types' => {}, 'column_captions' => {}}

      colhash = model_class.columns_hash
      column_names.each do |k|
        v = colhash[k]
        if v.nil?
          colhash.each {|_,nv| if nv.name == k then v = nv; break; end }
        end
        next if v.name.end_with? '_id'
        next unless column_names.include? v.name

        if :integer == v.type
          grid_configs['data_types'][v.name] = 'integer'
        end
        if :boolean == v.type
          grid_configs['data_types'][v.name] = 'boolean'
        end
        if :date == v.type
          grid_configs['data_types'][v.name] = 'date'
        end
        grid_configs['column_captions'][v.name] = Inflector.humanize(v.name)
        wheres << "#{tn}.#{v.name}={#{tn}.#{v.name}}" unless 'id' == v.name || :boolean == v.type
      end

      assoc_lookups = {}
      assocs        = model_class.reflect_on_all_associations(:belongs_to)

      assocs.each do |assoc|
        next if assoc.options[:polymorphic]
        cols = assoc.klass.column_names.dup
        cols.delete_if {|c| c.end_with?( '_id') || 'id' == c }
        preferred_cols = get_preferred_cols cols
        next if preferred_cols.empty?

        atn = assoc.klass.table_name
        joins << "JOIN #{atn} ON #{atn}.id = #{tn}.#{assoc.primary_key_name}"
        tmp = preferred_cols.map {|c| "#{atn}.#{c}" } unless preferred_cols.empty?
        tmp.each {|t| sels << t }

        preferred_cols.each do |pcol|
          assoc_lookups[pcol] = "SELECT DISTINCT #{pcol} FROM #{atn} ORDER BY #{pcol}"
        end

        assoc.klass.columns_hash.each do |k,v|
          next if v.name.end_with?( '_id') || 'id' == v.name
          next unless preferred_cols.include? v.name
          if :integer == v.type
            grid_configs['data_types'][v.name] = 'integer'
          end
          if :boolean == v.type
            grid_configs['data_types'][v.name] = 'boolean'
          end
          grid_configs['column_captions'][v.name] = Inflector.humanize(v.name)
        end
      end
      # Reflect on has_many relations too?...
      # Turn belongs_to fields into lookup queries in fields...

      xtra_sel = sels.empty? ? nil : ", #{sels.join(', ')}"
      join_str = joins.empty? ? nil : joins.join(' ')

      sels.each {|c| wheres << "#{c}={#{c}}" }
      where_clause = wheres.join(' AND ')
      fields = "fields:\n"
      wheres.each_with_index do |wh, index|
        fld  = wh.split('=').first
        fldc = fld.split('.').last
        str  =  "  field#{index+1}:\n"
        str << "    field_name: #{fld}\n"
        str << "    caption: #{Inflector.humanize(wh.split('.').last.chop)}\n"
        if assoc_lookups[fldc]
          str << "    field_type: lookup\n"
          str << "    list: #{assoc_lookups[fldc]}\n"
        else
          str << "    field_type: text\n"
        end
        fields << str
      end
      grid_str = "grid_configs:\n  column_widths:\n  data_types:\n"
      grid_configs['data_types'].each {|k,v| grid_str << "    #{k}: #{v}\n" }
      grid_str << "  column_captions:\n"
      grid_configs['column_captions'].each {|k,v| grid_str << "    #{k}: #{v}\n" }
      grid_str << <<EOS
#NB. The following lines provide a hint of what other options are possible
#    for manipulating the grid presentation. The field names are fictitious.
#    Delete or use whatever applies. These must remain part of the grid_configs hash.
#    (Frozen columns and grouping cannot be used together)
#  caption: This is a report
#  no_of_frozen_cols: 3
#  group_summary_depth: 2
#  groupable_fields:
#    - code1
#    - code2
#    - code3
#  group_fields_to_sum:
#    - quantity
#  group_fields_to_count:
#    - id
#  group_fields_to_min:
#    - start_date
#  group_fields_to_max:
#    - end_date
#  grouped: true
#  group_fields:
#    - code1
#    - code2
#  group_headers_colspan: true
#  group_headers:
#    - start_column_name: code1
#      number_of_columns: 3
#      title_text: Codes
#   -  start_column_name: total_qty
#      number_of_columns: 2
#      title_text: Totals
EOS

      sql = "SELECT #{column_names.map {|c|"#{tn}.#{c}"}.join(', ')}#{xtra_sel} FROM #{tn} #{join_str} WHERE(#{where_clause})"
      grp_name = group_name.nil? || group_name == 'None' ? nil : "default_report_index_group_name: #{group_name}\n"
      "query: #{sql}\nmain_table_name: #{tn}\n#{grp_name}\n#{grid_str}\n\n#{fields}"
    end
 end

end
