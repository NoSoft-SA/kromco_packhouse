
class FieldExtractor
  attr_accessor :form_fields, :query_statement, :main_table_name, :columns_list, :grid_configs, :grid_action_columns

  def initialize(yamlfile)
      @yamlfile = yamlfile

      #RAILS_DEFAULT_LOGGER.info "YAML: " +

      @query_statement = nil
      @query = nil
      @parameter_array = Array.new
      #@fields = nil
      @tests = nil
      @fields_array = Array.new
      @list_sql = nil
      @field_name = nil
      @field_type = nil
      @form_fields = Array.new
      @grid_action_columns = Array.new
      @model = nil

      @columns_list = Array.new

      m                = YAML::load(File.read(@yamlfile))
      @fields          = m['fields']
      @query           = m['query']
      @query_statement = @query.clone
      @grid_configs    = m['grid_configs']
      @main_table_name = m['main_table_name'] || m['main_table']

      get_elements_from_file(@fields,@query)

      get_columns_list

  end

  def get_elements_from_file(fields,query)

      if fields!=nil
          sort_fields
      end

      i = query.index("(")
      if i!= nil
          unwanted_section = query[0,i]
          query = query.gsub!(unwanted_section,"")
          recursive_extractor(query)

          #Testing for fields to decide for TextBoxes Or DropDown or DateTime or Date
          if @parameter_array.size!=0
              @parameter_array.each do |p|
                  test_count = 0
                  if @fields_array.size != 0
                      @fields_array.each do |f|
                          if f.has_value?(p)
                              type = f[:field_type]
                              #caption = p
                              caption = f[:caption] #if f.has_key?("caption")
                              field_type = nil
                              list = nil
                              if type == "lookup_link"
                                @form_fields.push({:field_name=>p, :field_type=>"LookUpField", :caption=>caption,:lookup_search_file=>f[:lookup_search_file],:select_column_name=>f[:select_column_name],:lookup_search_uri=>f[:lookup_search_uri],:send_fields=>f[:send_fields],:submit_to=>f[:submit_to]})
                              elsif type == "lookup"
                                  field_type = "DropDownField"
                                  list = f[:list]
                                  #model = f.fetch(:model)
                                  @form_fields.push({:field_name=>p, :field_type=>field_type, :list=>list, :caption=>caption})
                              elsif type == "date"
                                  field_type ="DateField"
                                  @form_fields.push({:field_name=>p, :field_type=>field_type, :caption=>caption})
                              elsif type == "datetime"
                                  field_type = "DateTimeField"
                                  @form_fields.push({:field_name=>p, :field_type=>field_type, :caption=>caption})
                              elsif type == "checkbox"
                                  field_type = "CheckBox"
                                  @form_fields.push({:field_name=>p, :field_type=>field_type, :caption=>caption})
                              elsif type == "text"
                                  field_type = "TextField"
                                  @form_fields.push({:field_name=>p, :field_type=>field_type, :caption=>caption})
                              elsif type == "daterange"
                                  field_type = "PopupDateRangeSelector"
                                  @form_fields.push({:field_name=>p, :field_type=>field_type, :caption =>caption})
                              end
                              test_count = test_count + 1
                          end
                      end
                      if test_count==0
                          field_type = "TextField"
                          caption = p
                          @form_fields.push({:field_name=>p, :field_type=>field_type, :caption=>caption})
                      else
                          test_count=0
                      end
                  else
                      field_type = "TextField"
                      caption = p
                      @form_fields.push({:field_name=>p, :field_type=>field_type, :caption=>caption})
                  end

              end
          end
      else
          puts "Nothing"
      end
      #return @form_fields
  end

  def sort_fields
      @fields.each do |f|
          fields_hash = f[1]
          #NB fields_hash is a hash
          if(fields_hash.has_key?("list"))
              @field_name = fields_hash["field_name"]
              @field_type = fields_hash["field_type"]
              @list_sql = fields_hash["list"]
                #@model = fields_hash["model"]
              @caption = fields_hash["field_name"]
              @caption = fields_hash["caption"] if fields_hash.has_key?("caption")
              @fields_array.push({:field_name=>@field_name, :field_type=>@field_type, :list=>@list_sql, :caption=>@caption})
          elsif fields_hash.has_value?("action")
              @field_name = fields_hash["field_name"]
              @field_type = fields_hash["field_type"]
              @target_action = fields_hash["target_action"]
              @id_column = fields_hash["id_column"]
              if fields_hash.has_key?("link_text")
                 @link_text = fields_hash["link_text"]
                 @grid_action_columns.push({:field_name=>@field_name, :field_type=>@field_type, :target_action=>@target_action, :id_column=>@id_column, :link_text=>@link_text})
              elsif fields_hash.has_key?("image")
                 @image = fields_hash["image"]
                 @grid_action_columns.push({:field_name=>@field_name, :field_type=>@field_type, :target_action=>@target_action, :id_column=>@id_column, :image=>@image})
              else
                 @grid_action_columns.push({:field_name=>@field_name, :field_type=>@field_type, :target_action=>@target_action, :id_column=>@id_column})
              end
          else
              @field_name = fields_hash["field_name"]
              @field_type = fields_hash["field_type"]
              @caption = fields_hash["field_name"]
              @caption = fields_hash["caption"] if fields_hash.has_key?("caption")
              if fields_hash.has_key?("lookup_search_file")
                @lookup_search_file = fields_hash["lookup_search_file"]
              else
                @lookup_search_file = nil
              end
              if fields_hash.has_key?("select_column_name")
                @select_column_name = fields_hash["select_column_name"]
              else
                @select_column_name = nil
              end
              if fields_hash.has_key?("lookup_search_uri")
                @lookup_search_uri = fields_hash["lookup_search_uri"]
              else
                @lookup_search_uri = nil
              end
              if fields_hash.has_key?("send_fields")
                @send_fields = fields_hash["send_fields"]
              else
                @send_fields = nil
              end
              if fields_hash.has_key?("submit_to")
                @submit_to = fields_hash["submit_to"]
              end
              @fields_array.push({:field_name =>@field_name, :field_type=>@field_type, :caption=>@caption,:lookup_search_file=>@lookup_search_file,:select_column_name=>@select_column_name,:lookup_search_uri=>@lookup_search_uri,:send_fields=>@send_fields,:submit_to=>@submit_to})
          end
      end
  end

  def recursive_extractor(query)
      #puts @query_statement[0].to_s
      if query!=nil
          index = query.index("{")
          if index
              unwanted_section = query[0,index]
              query = query.gsub!(unwanted_section,"")
              #end_index = query.index("}")
              #field = query[0,end_index]
              first_brace = query.index("{")
              second_brace = query.index("}")
              left = query[0,first_brace]
              query = query.gsub!(left,"")
              second_second_brace = query.index("}")
              field = query[1,second_second_brace - 1]
              @parameter_array.push(field)
              f = "{" + field + "}"
              query = query.gsub!(f,"")
              recursive_extractor(query)
          end
      end
  end

  def get_columns_list
     if @query_statement.upcase.index("JOIN ") != nil
        cols_list = FieldExtractor.get_join_query_columns(@query_statement)
        cols_list.each do |col|
          @columns_list.push(col.split(".").last.strip)
        end
     else
       column_pattern = /select.+(?= from )/i
       col_phrase = @query_statement.slice(column_pattern)
       #col_phrase = col_phrase.strip
       col_phrase = col_phrase.slice(7..(col_phrase.size()-1))
       if col_phrase.strip.length > 1
         if col_phrase.index(",")!= nil
           col_phrase.split(",").each do |col|
             if col.strip.include?(' ')
               col = col.split(' ').last
             end

             @columns_list.push(col)
           end
         else
           @columns_list.push(col_phrase)
         end
       end
     end
  end

  def FieldExtractor.get_statement_between_select_and_from(stat)
     pattern = /select.+(?= from )/i
     col_phrase = stat.slice(pattern)
     return_stat = col_phrase.slice(7..(col_phrase.size()-1))
     return return_stat.strip
  end

  def FieldExtractor.get_numeric_columns(table_name)
    query = "SELECT c.oid, a.attnum, a.attname, t.typname, a.atthasdef, a.attlen, a.attnotnull"
    query += " FROM pg_class as c, pg_attribute a, pg_type t WHERE"
    query += " a.attnum > 0 and a.attrelid = c.oid and c.relname = '"  + table_name + "' and a.atttypid = t.oid order by a.attnum"

    conn = User.connection
    result = conn.select_all(query)

    columns = Array.new
    result.each do |field|
      field_data = Hash.new
      field_data[:field_name] = field["attname"]
      field_data[:type] = field["typname"]
      columns.push(field_data)
    end
    columns.sort!{|x,y| y[:field_name] <=>x[:field_name]}.reverse!
    numeric_columns = Array.new
    columns.each do |item|
      if(item[:type].to_s.upcase().index("INT2") || item[:type].to_s.upcase().index("INT4") || item[:type].to_s.upcase().index("INT8") || item[:type].to_s.upcase().index("NUMERIC")|| item[:type].to_s.upcase().index("FLOAT8"))
        if(item[:field_name].to_s.upcase().index("_ID")==nil && item[:field_name].to_s.upcase()!= "ID")
          numeric_columns.push(item[:field_name])
        end
      end
    end
    return numeric_columns
  end

  def FieldExtractor.get_table_columns(table_name)
     query = "SELECT c.oid, a.attnum, a.attname, t.typname, a.atthasdef, a.attlen, a.attnotnull"
    query += " FROM pg_class as c, pg_attribute a, pg_type t WHERE"
    query += " a.attnum > 0 and a.attrelid = c.oid and c.relname = '"  + table_name + "' and a.atttypid = t.oid order by a.attnum"

    conn = User.connection
    result = conn.select_all(query)
    columns = Array.new
    result.each do |field|
      field_data = Hash.new
      field_data[:field_name] = field["attname"]
      field_data[:type] = field["typname"]
      columns.push(field_data)
    end
    columns.sort!{|x,y| y[:field_name] <=>x[:field_name]}.reverse!
    my_columns = Array.new
    columns.each do |item|
      my_columns.push(item[:field_name])
    end
    return my_columns
  end

  def FieldExtractor.get_join_query_columns(query_statement)
    select_index = query_statement.upcase.index("SELECT ")
    from_index = query_statement.upcase.index("FROM ")
    cols_phrase = query_statement[select_index + 6, from_index - (select_index + 6)]
    column_array = cols_phrase.split(",")
    actual_columns = Array.new
    column_array.each do |column|
      if column.upcase.index(" AS ") != nil
        column_name = column.upcase.split(" AS ")[1].strip.downcase
      else
        column_name = column
      end
#      if initial_column.upcase.index( " AS ") != nil
#        column_name = initial_column.upcase.split(" AS ")[0].to_s.strip.downcase
#      else
#        column_name = initial_column
#      end
      actual_columns.push(column_name)
    end
    return actual_columns
  end

end
