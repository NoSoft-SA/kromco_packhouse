class FieldParser

  attr_accessor :query

  def initialize(query, parameter_fields_values_array=nil, search_engine_or_values=nil, operator_signs=nil)
    @query                         = query
    @parameter_fields_values_array = parameter_fields_values_array
    @search_engine_or_values       = search_engine_or_values
    @operator_signs                = operator_signs

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
        @query.gsub!("SUBQSTART","#{subquery}")
      end
    rescue
      raise MesScada::Error, "There was a problem extracting the report definition."
    end
  end

  def process_fields(stat, fields, search_eng_or_values, op_signs)
    where_right = FieldParser.get_where_clause(stat)
    return stat if where_right.blank?

    where,right  = where_right.split("|splitter|")
    left_pos  = stat.index(where)
    left_stat = stat[0,left_pos-7] # -7 to compensate for WHERE( -- should change to also handle WHERE ( ...

    unless fields.nil?
      fields.each do |field|
        if ((where.include?("{#{field[:field_name]}}") && !field[:field_value].blank? && field[:field_type].to_s != "CheckBox") ||
            (field[:field_type].to_s == "CheckBox" && field[:is_clicked] == "true"))
          where = substitutor(where, field[:field_name],field[:field_value],field[:field_type], search_eng_or_values, op_signs)
        end
        if where.include?("{#{field[:field_name]}}")
          if field[:field_value].blank?
            where = remove_null(where, field[:field_name])
          else
            if field[:field_type].to_s == "PopupDateRangeSelector"
              test_array = field[:field_value].to_s.split("|")
              if test_array.length < 2 || test_array.any? {|a| a.blank? }
                where = remove_null(where, field[:field_name])
              end
            elsif field[:field_type].to_s == "CheckBox" && field[:is_clicked] == "false"
              where = remove_null(where, field[:field_name])
            end
          end
        end
      end
      stat = "#{left_stat} where(#{where}) #{right}"
    end
    stat
  end


  def escape_quote(val)
    val.gsub("'","''")
  end

  def substitutor(where,field_name,field_value,field_type, search_eng_or_values, op_signs)

    return nil if where.nil?
    field_value = escape_quote(field_value)
    section_to_replace = "#{field_name}={#{field_name}}"

    if field_type == "PopupDateRangeSelector"
      value_array = field_value.to_s.split("|")
      if value_array.length == 2
        unless value_array[0].blank? || value_array[1].blank?
          replacer = "#{field_name} between '#{value_array[0]}' and '#{value_array[1]}'"
          where.gsub!(section_to_replace, replacer)
        end
      end
    else
      replacer = "(#{field_name}='#{field_value}'"

      if op_signs.size != 0
        if op_signs.has_key?(field_name)
          op_val = op_signs[field_name]
          if op_val.index("IS NULL")!= nil || op_val.index("IS NOT NULL")!= nil
            replacer = "(" + field_name + " " + op_val
          elsif op_val.to_s != "=" && op_val.to_s != "text"
            replacer = "(" + field_name + " " + op_val + " " + "'" + field_value + "'"
          end
        end
      end

      if search_eng_or_values.size != 0
        if search_eng_or_values.has_key?(field_name)
          or_values = search_eng_or_values[field_name]
          if or_values.include?(",")
            replacer << or_values.split(",").map {|o| "or #{field_name}='#{or_val}'" }.join(' ') << ')'
          else
            replacer << " or #{field_name}='#{or_values}')"
          end
        else
          replacer << ")"
        end
      else
        replacer << ")"
      end
      where.gsub!(section_to_replace, replacer)
    end

    where
  end

  def remove_null(where, field_name)
    where.gsub!("#{field_name}={#{field_name}}", '(true)') unless where.nil?
    where
  end

  # Move the StringScanner recursively up to the FROM clause.
  def self.advance_from_select(s,arr)
    tmp = s.scan_until(/\bSUBQSTART|FROM\b/i)
    arr << tmp
    if tmp =~ /SUBQSTART\z/i || s.check_until(/\bSUBQEND\b/i)
      arr << s.scan_until(/\bSUBQEND\b/i)
      advance_from_select(s,arr)
    end
  end

  # Get the part of the query statement between SELECT and FROM.
  def self.get_select_clause_portion(query_statement)
    s = StringScanner.new(query_statement)
    portions = []
    portions << s.scan(/\bSELECT\b/i)
    if portions.first
      advance_from_select(s, portions)
    end
    portions.join
  end

  def FieldParser.get_where_clause(stat)
    return '' if stat.upcase.index(" WHERE").nil?

    stat = stat.sub(get_select_clause_portion(stat), '')
    revstr = stat.reverse
    wpos = revstr =~ /EREHW/i
    snip = revstr[0..wpos+5].reverse

    stat_with_where = snip
    start_pos       = stat_with_where.index("(")
    stat_with_where = stat_with_where.slice(start_pos + 1..stat_with_where.length())
    stat_with_where = stat_with_where.strip
    end_pos         = FieldParser.get_where_end_bracket(stat_with_where)
    where_clause    = stat_with_where.slice(0..end_pos - 1)
    right           = stat_with_where.gsub(where_clause,"").reverse.chop.reverse

    "#{where_clause}|splitter|#{right}"
  end

  def FieldParser.get_where_end_bracket(where)
    index = 0
    sum   = 1
    chars = where.scan(/./)
    chars.each do |char|
      sum += 1     if char == "("
      sum -= 1     if char == ")"
      return index if sum == 0
      index += 1
    end
  end

  def FieldParser.get_table_name(stat)
    pattern             = / from +[\w].+/i
    required_part       = stat.slice(pattern)
    required_part       = required_part.strip.gsub(" ","|table|").gsub(",","|table|")
    required_stat_array = required_part.split("|table|")
    table_pos           = FieldParser.get_table_position(required_stat_array)
    table_name          = required_stat_array[table_pos]
    return table_name
  end

  def FieldParser.get_table_position(stat_array)
    index = 0
    pos = 0
    stat_array.each do |item|
      index += 1 if item.to_s != ""
      return pos if index == 2
      pos += 1
    end
  end

end
