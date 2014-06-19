class FieldParser
     
    attr_accessor :query

  def initialize(query, parameter_fields_values_array=nil, search_engine_or_values=nil, operator_signs=nil)
      orig_query = query
      @query = query
      #@query = nil
      @parameter_fields_values_array = parameter_fields_values_array
      @search_engine_or_values = search_engine_or_values
      @operator_signs = operator_signs
      puts "YML QUERY : " + @query


      #-------------------------------------------------------------------
      #See if there is a subquery: denoted by 'SUBQSTART' and 'SUBQEND'
      #Remove the subquery, parse separately and re-insert into main query
      #-------------------------------------------------------------------
      if @query.index('SUBQSTART')
          subq_startpos = @query.index('SUBQSTART')
          subq_endpos = @query.index('SUBQEND')
          #remove the subquery, but SUBQSTART as placeholder- return the removed subquery
          subquery  = @query.slice!(subq_startpos + 9..subq_endpos + 6)
      end
      begin
        @query = process_fields(@query, @parameter_fields_values_array, @search_engine_or_values, @operator_signs)
        if subquery
           subquery.gsub!("SUBQEND","")
           subquery = process_fields(subquery, @parameter_fields_values_array, @search_engine_or_values, @operator_signs)
           @query.gsub!("SUBQSTART",subquery)
        end
      rescue
        raise MesScada::Error, "There was a problem extracting the report definition."
      end


  end
  
  def process_fields(stat, fields, search_eng_or_values, op_signs)
     where_right = FieldParser.get_where_clause(stat)
     if where_right != ""
       where = where_right.split("|splitter|")[0]
       right = where_right.split("|splitter|")[1]
       puts "PARSER WHERE : " + where
       left_pattern = /select.+(?=where)/i
       left_stat = stat.slice(left_pattern)
       
       if fields != nil
          #substitute with values
          for field in fields
            if ((where.index(field[:field_name]) != nil && field[:field_value].to_s != "" && field[:field_type].to_s != "CheckBox") || (field[:field_type].to_s == "CheckBox" && field[:is_clicked] == "true"))
              where = substitutor(where, field[:field_name],field[:field_value],field[:field_type], search_eng_or_values, op_signs)
            end
          end
          #remove null fields
          for field in fields
             if where.index(field[:field_name]) != nil
                if field[:field_value].to_s == "" || field[:field_value] == nil
                  where = remove_null(where, field[:field_name])
                else
                   if field[:field_type].to_s == "PopupDateRangeSelector"
                      test_array = field[:field_value].to_s.split("|")
                      if test_array.length == 0 || test_array.length == 1
                         where = remove_null(where, field[:field_name])
                      else
                         if test_array[0].to_s == "" || test_array[1].to_s == ""
                            where = remove_null(where, field[:field_name])
                         end
                      end
                   elsif field[:field_type].to_s == "CheckBox" && field[:is_clicked] == "false"
                     where = remove_null(where, field[:field_name])
                   end
                end
             end
          end
        end
        stat = left_stat + " where(" + where + ")" + " " + right.to_s
      else
        stat = stat
      end
      return stat
  end


  def escape_quote(val)
     if val.index("'")
        return val.gsub!("'","''")
     end

      return val
  end

  def substitutor(where,field_name,field_value,field_type, search_eng_or_values, op_signs)


   field_value = escape_quote(field_value)

    if where != nil
      index = where.index(field_name + "={" + field_name + "}")
      if field_type == "PopupDateRangeSelector"
        if index
          value_array = field_value.split("|")
          if value_array.length > 0
            if value_array.length == 2
              if value_array[0].to_s != "" && value_array[1].to_s != ""
                section_to_replace = field_name + "={" + field_name + "}"
                replacer = field_name +" between " + "'" + value_array[0].to_s + "'" + " and " +  "'" + value_array[1].to_s + "'"
                where =where.gsub(section_to_replace, replacer)
              end
            end
          end
        end
      else
        if index
          section_to_replace = field_name + "={" + field_name + "}"
          replacer = ""
          if op_signs.size != 0
             if op_signs.has_key?(field_name)
                op_val = op_signs[field_name]
                if op_val.index("IS NULL")!= nil || op_val.index("IS NOT NULL")!= nil
                    replacer = "(" + field_name + " " + op_val 
                elsif op_val.to_s != "=" && op_val.to_s != "text"
                   replacer = "(" + field_name + " " + op_val + " " + "'" + field_value + "'"
                else
                   replacer = "(" + field_name + "=" + "'" + field_value + "'" 
                end
             else
                replacer = "(" + field_name + "=" + "'" + field_value + "'"  
             end
          else
             replacer = "(" + field_name + "=" + "'" + field_value + "'" 
          end
          if search_eng_or_values.size != 0
            if search_eng_or_values.has_key?(field_name)
              or_values = search_eng_or_values[field_name]
              if or_values.index(",")!= nil
                 or_values_array = or_values.split(",")
                 or_values_array.each do |or_val|
                    replacer += " or " + field_name + "=" + "'" + or_val + "'"
                 end
                 replacer += ")"
              else
                 replacer += " or " + field_name + "=" + "'" + or_values + "'" + ")"
              end
            else
              replacer += ")"
            end
          else
            replacer += ")"
          end
          where = where.gsub(section_to_replace, replacer)
        end
      end
    end
    return where
  end
   
  def remove_null(where, field_name)
    if where != nil
      index = where.index(field_name + "={" + field_name + "}")
      if index
        section_to_remove = field_name + "={" + field_name + "}"
        replacer = "(true)"
        where = where.gsub(section_to_remove, replacer)
      end
    end
    return where
  end
  
  def FieldParser.get_where_clause(stat)
     if stat.upcase.index(" WHERE") != nil
       pattern = / +where[ |(].+/i
       stat_with_where = stat.slice(pattern)
       start_pos = stat_with_where.index("(")
       stat_with_where = stat_with_where.slice(start_pos + 1..stat_with_where.length())
       stat_with_where = stat_with_where.strip
       end_pos = FieldParser.get_where_end_bracket(stat_with_where)
       
       where_clause = stat_with_where.slice(0..end_pos - 1)
       right = stat_with_where.gsub(where_clause,"").reverse.chop.reverse
       return where_clause + "|splitter|" + right.to_s
     else
       return ""
     end
  end
  
  def FieldParser.get_where_end_bracket(where)
     index = 0
     sum = 1
     chars = where.scan(/./)
     chars.each do |char|
        if char == "("
          sum += 1
        elsif char == ")"
           sum -= 1
        end
        if sum == 0
           return index
        end
        index += 1
     end
  end
  
  def FieldParser.get_table_name(stat)
    pattern = / from +[\w].+/i
    required_part = stat.slice(pattern)
    required_part = required_part.strip.gsub(" ","|table|")
    required_part = required_part.strip.gsub(",","|table|")
    required_stat_array = required_part.split("|table|")
    table_pos = FieldParser.get_table_position(required_stat_array)
    table_name = required_stat_array[table_pos]
    return table_name
  end
  
  def FieldParser.get_table_position(stat_array)
    index = 0
    pos = 0
    stat_array.each do |item|
      if item.to_s != ""
        index += 1
      end
      if index == 2
        return pos
      end
      pos += 1
    end
  end

end
