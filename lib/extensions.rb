require 'date'
require 'lib/globals.rb'
require 'lib/app_factory.rb'

class DateTime

  def to_time
    Time.local(year, month, day, hour, min, sec)
  end

end

class File
  def self.find(dir, filename="*.*", subdirs=true)
    Dir[subdirs ? File.join(dir.split(/\\/), "**", filename) : File.join(dir.split(/\\/), filename)]
  end
end

class Log


  def initialize(dir_path, file_name, log_type, timestamp = nil, date_stamp = nil)

    @path = dir_path + "/" + file_name
    @path += "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") if timestamp
    @path += "_" + Time.now.strftime("%Y_%m_%d") if date_stamp
    @log_type = log_type
  end

  #----------------------------------------------------------
  #0 or null: verbose
  #1: info
  #2: critical
  #----------------------------------------------------------
  def write(text, log_level = nil)
    text = Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ":   " + text
    log_level = 0 if !log_level
    config_level = 0
    if Globals.get_log_level(@log_type)
      config_level = Globals.get_log_level(@log_type)
    end

    if log_level >= config_level
      File.open(@path, "a") do |f|
        f.puts text
      end
    end

    console_log_config_level = 0
    if Globals.get_console_log_level(@log_type)
      console_log_config_level = Globals.get_console_log_level(@log_type)
    end
    puts text if log_level >= console_log_config_level

  end

end


class String

  require "parsedate.rb"
  include ParseDate

  def remove_right(n_chars, min_length = nil)

    num = self.to_s
    number = num.slice(0..(num.length()-(1+ n_chars)))
    if min_length && min_length > number.length()
      return num
    else
      return number
    end

  end

  def to_datetime

    date_parts = parsedate(self)
    return Time.local(date_parts[0], date_parts[1], date_parts[2], date_parts[3], date_parts[4], date_parts[5], date_parts[6], date_parts[7])

  end

  def pad(num_digits)
    self.ljust(num_digits)

    # extra_digits = num_digits - self.length
    # return self if extra_digits <= 0

    # padding = " "
    # for i in 1..extra_digits-1
    #   padding += " "
    # end

    # return self + padding

  end

  def is_numeric?
    begin
      Float self
      true
    rescue
      false
    end
  end


  def occurrence_of(search_char)
    # Same as: self.scan(/./).select {|c| c == search_char}.count
    begin
      a = self.scan(/./)
      counter = 0
      a.each do |c|
        if c.to_s == search_char
          counter += 1
        end
      end
      return counter
    rescue
      return 0
    end
  end

end
class Array
  attr_accessor :groups

  def sort_list(criteria, key_based_access = nil)
    code = ""
    criteria.each do |c|
      if key_based_access
        code += " if x['" + c + "'] && y['" + c + "']\n "
        code += "result = x['" + c + "'] <=> y['" + c + "'] if result == 0 \n"
        code += " elsif x['" + c + "']\n"
        code += "result = -1 if result == 0\n"
        code += "else \n"
        code += "result = 1 if result == 0\n"
        code += "end\n"
      else
        code += " if x." + c + " && y." + c + "\n "
        code += "result = x." + c + " <=> y." + c + " if result == 0\n"
        code += " elsif x." + c + "\n"
        code += "result = -1 if result == 0\n"
        code += "else \n"
        code += "result = 1 if result == 0\n"
        code += "end\n"
      end

    end

    code = "self.sort!{|x,y| result = 0\n" + code + "\n result}"
    puts code
    eval code
  end


  def group(group_criteria, key_based_access = nil, sort = nil)
    @list = self
    @group_criteria = group_criteria
    @groups = Array.new
    @key_based_access = key_based_access

    sort_list(group_criteria, key_based_access) if sort
    extract_group
    return @groups

  end

  def group_as_string

    @groups.each do |g|
      puts "GROUP: " + g.to_s
    end
  end

  def extract_group(start_pos = 1)
    current_group = nil
    added = false
    if !current_group
      current_group = Array.new
      current_group.push(@list[start_pos -1])
    end

    for i in start_pos..@list.length() -1
      if compare(@list[i-1], @list[i])
        current_group.push(@list[i])
      else
        @groups.push(current_group)
        added = true
        extract_group(i+1)
        break
      end
    end
    @groups.push(current_group) if !added
  end

  def compare(previous_item, current_item)
    failed = false
    @group_criteria.each do |c|
      if !@key_based_access
        failed = !(eval "previous_item." + c + " == current_item." + c)
      else
        failed = !(eval "previous_item['" + c + "'] == current_item['" + c + "']")
      end
      break if failed
    end
    return !failed
  end

  def to_small_list(columns_to_include=nil)
    if (columns_to_include==nil)
      if (self[0].kind_of? ActiveRecord::Base)
        self.collect do |x|
          x.id.to_s
        end
      elsif self[0].kind_of?(Hash)
        self.collect do |x|
          x["id"]
        end
      else
        raise "Only Active Record/Hash instances supported"
      end
    else
      record_hash = Hash.new
      if (self[0].kind_of? ActiveRecord::Base || self[0].kind_of?(Hash))
        self.collect do |x|
          for column in columns_to_include
            record_hash.store(column.to_s, x[column.to_s])
          end
          record_hash
        end
      else
        raise "Only Active Record/Hash instances supported"
      end
    end
  end
end


class Float

  def Float.round_float(n_digits, value)

    return ((value).* 10**n_digits).round.to_f/10**n_digits

  end

end


class Integer

  def remove_right(n_chars, min_length = nil)

    num = self.to_s
    number = num.slice(0..(num.length()-(1+ n_chars)))
    if min_length && min_length > number.length()
      return num
    else
      return number.to_i
    end

  end


  def to_fixed_length_s(num_digits, number)

    extra_digits = num_digits - number.to_s.length
    return number.to_s if extra_digits <= 0

    padding = "0" * extra_digits
    # padding = "0"
    # for i in 1..extra_digits-1
    #   padding += "0"
    # end

    # return number.to_s + padding
    return number.to_s << padding

  end

  def to_padded_s(length)

    curr_length = self.to_s.length()
    return self.to_s if curr_length >= length

    digits_needed = length - curr_length

    padded = "0" * digits_needed
    # padded = ""
    # for i in 1..digits_needed
    #   padded += "0"
    # end

    return padded + self.to_s

  end

end


class ActiveRecord::Base


  before_validation :clear_combo_prompts
  before_save :trim_attribute_values, :set_request_details
  before_update :log_changes
  before_create :set_request_details_for_create
  before_update :set_request_details
  before_destroy :log_changes

  attr_accessor :unchanged_fields, :changed_fields

  def  log_changes
    if self.new_record?
      else
      if Globals.tables_to_be_logged_in_changed_logs.include?(self.class.to_s.tableize)
          record_before = {}
          record_after  = {}
          changed_fields=self.changed_fields?
          if !changed_fields.empty?
            changed_fields.each do |key,val|
              record_before[key]=val[0]
              record_after[key]=val[1]
            end
          end
          ChangeLog.create_log(record_before,record_after,self,options = {})
        end
      end

  end


  def authorise(program, permission, user)
    begin
      user = User.find_by_user_name(user)

      query = "SELECT
               public.security_permissions.id
               FROM
               public.security_groups_security_permissions
               INNER JOIN public.security_groups ON (public.security_groups_security_permissions.security_group_id = public.security_groups.id)
                INNER JOIN public.security_permissions ON (public.security_groups_security_permissions.security_permission_id = public.security_permissions.id)
                INNER JOIN public.program_users ON (public.security_groups.id = public.program_users.security_group_id)
                INNER JOIN public.programs ON (public.program_users.program_id = public.programs.id)
                WHERE
                (public.program_users.user_id = #{user.id}) AND
                (public.security_permissions.security_permission = '#{permission}') AND
                (public.programs.program_name = '#{program}')"

      @val  = User.connection.select_one(query)

      return @val != nil
    rescue
      puts "Authorisation exception: " + $!.to_s
      return false
    end
  end

  def cancel_clear_combo_prompts
    false
  end

  def update_attribute_sanitised(params)
      to_update={}
      for para  in params
        if  self.attributes.has_key?("#{para[0]}") && para[0] != 'id'
          to_update[para[0]]  =  para[1]
        end
      end
      self.update_attributes(to_update)
  end

  def import_request_fields(user_db_action)
    if ActiveRequest.get_active_request
      eval "self." + user_db_action + " = '" + ActiveRequest.get_active_request.user + "'" if self.respond_to?(user_db_action)

      self.affected_by_program = ActiveRequest.get_active_request.program if self.respond_to?("affected_by_program")
      self.affected_by_function = ActiveRequest.get_active_request.function if self.respond_to?("affected_by_function")
      self.affected_by_env = ActiveRequest.get_active_request.env if self.respond_to?("affected_by_env")
    else
      eval "self." + user_db_action + " = nil" if self.respond_to?(user_db_action)
      self.affected_by_program = nil if self.respond_to?("affected_by_program")
      self.affected_by_function = nil if self.respond_to?("affected_by_function")
      self.affected_by_env= nil if self.respond_to?("affected_by_env")
    end
  end

  def set_request_details
    if !self.new_record?
      import_request_fields("updated_by")
    end

  end

  def set_request_details_for_create
    import_request_fields("created_by")

  end

  def self.extend_set_sql_with_request(update_sql, table_name)

    #return update_sql if  !ActiveRequest.get_active_request


    cols = AppFactory::PostgresMetaData.get_column_defs(table_name, ActiveRecord::Base.connection)
    request_part = ","

    updated_by = ""
    if cols.find { |c| c[:field_name] == "updated_by" }
      val = ActiveRequest.get_active_request.user if ActiveRequest.get_active_request
      val ||= ""
      updated_by = "updated_by = '" + val + "'"
    end

    affected_by_program = ""
    if cols.find { |c| c[:field_name] == "affected_by_program" }
      val = ActiveRequest.get_active_request.program  if ActiveRequest.get_active_request
      val ||= ""
      affected_by_program = "affected_by_program = '" + val + "'"
    end

    affected_by_function = ""
    if  cols.find { |c| c[:field_name] == "affected_by_function" }
      val = ActiveRequest.get_active_request.function  if ActiveRequest.get_active_request
      val ||= ""
      affected_by_function = "affected_by_function ='" + val + "'"
    end

    affected_by_env = ""
    if cols.find { |c| c[:field_name] == "affected_by_env" }
      val = ActiveRequest.get_active_request.env if ActiveRequest.get_active_request
      val ||= ""
      affected_by_env = "affected_by_env = '" + val + "'"
    end

    updated_at = ""
    updated_at = "updated_at = '" + Time.now.to_formatted_s(:db) + "'" if cols.find { |c| c[:field_name] == "updated_at" }


    request_part += updated_by + "," if updated_by  != ""
    request_part += affected_by_program + "," if affected_by_program!= ""
    request_part += affected_by_env + "," if  affected_by_env   != ""
    request_part += affected_by_function + "," if affected_by_function   != ""
    request_part += updated_at + "," if updated_at != ""

    request_part.slice!(request_part.length() -1, 1)


    return update_sql + request_part

  end

  def self.extend_update_sql_with_request(update_sql)

    #return update_sql if  !ActiveRequest.get_active_request

    set_pattern = /\s+set\s+/i

    main_table_pattern = /\s*update\s+(\w+)\s+/i
    main_table_pattern =~ update_sql
    table_name = $1

    cols = AppFactory::PostgresMetaData.get_column_defs(table_name, ActiveRecord::Base.connection)
    request_part = " set  "

    updated_by = ""
    if cols.find { |c| c[:field_name] == "updated_by" }
      val = ActiveRequest.get_active_request.user if ActiveRequest.get_active_request
      val ||= ""
      updated_by = "updated_by = '" + val + "'"
    end

    affected_by_program = ""
    if cols.find { |c| c[:field_name] == "affected_by_program" }
      val = ActiveRequest.get_active_request.program  if ActiveRequest.get_active_request
      val ||= ""
      affected_by_program = "affected_by_program = '" + val + "'"
    end

    affected_by_function = ""
    if  cols.find { |c| c[:field_name] == "affected_by_function" }
      val = ActiveRequest.get_active_request.function if ActiveRequest.get_active_request
      val ||= ""
      affected_by_function = "affected_by_function ='" + val + "'"
    end

    affected_by_env = ""
    if cols.find { |c| c[:field_name] == "affected_by_env" }
      val = ActiveRequest.get_active_request.env   if ActiveRequest.get_active_request
      val ||= ""
      affected_by_env = "affected_by_env = '" + val + "'"
    end

    updated_at = ""
    updated_at = "updated_at = '" + Time.now.to_formatted_s(:db) + "'" if cols.find { |c| c[:field_name] == "updated_at" }


    request_part += updated_by + ", " if updated_by != ""
    request_part += affected_by_program + ", " if affected_by_program  != ""
    request_part += affected_by_env + ", " if  affected_by_env  != ""
    request_part += affected_by_function + ", " if affected_by_function  != ""
    request_part += updated_at + ", " if updated_at != ""

    request_part.slice!(request_part.length() -1, 1)


    extended_sql = update_sql.gsub(set_pattern, request_part)
    return extended_sql

  end


  def trim_attribute_values
    self.attributes.each do |key, value|
      eval "self." + key + ".to_s.strip!"
    end
  end

  def to_map
    map = Hash.new
    self.attributes.each do |key, value|
      map[key] = value
    end
    return map
  end


  def to_map_str

    data = "{"
    self.attributes.each do |key, value|
      str_val = nil
      if value.class.to_s == "Time"||value.class.to_s == "Date"
        str_val = value.strftime("%d/%b/%Y %H:%M:%S")
      end


      str_val = value.to_s if !str_val
      data += ":" + key + "=> " + "\"" + str_val + "\", "
    end

    data.slice!(data.length()-2)
    data += "}"
    return data

  end


  def changed_fields?(ignore_fields = nil)

    self.changed_fields = nil
    self.unchanged_fields = nil

    if self.id == nil
      return nil
    end

    changed_field_names = Array.new
    old_state = eval self.class.to_s + ".find(" + self.id.to_s + ")"
    list = Hash.new
    self.attributes.each do |name, value|
      if !(old_state.has_attribute?(name)== nil && old_state.attributes[name]== nil)
        if old_state.has_attribute?(name) && value.to_s != old_state.attributes[name].to_s
          if ignore_fields && !(ignore_fields.find { |i| i == name })
            list.store(name, [old_state.attributes[name].to_s, value.to_s])
            #puts "CHANGED: " + name
          elsif !ignore_fields
            list.store(name, [old_state.attributes[name].to_s, value.to_s])
            #puts "CHANGED 2: " + name
          end
        end
      end
    end


    changed_field_names = list.keys
    #now get unchanged fields- the differenc between the changed list and the complete list
    self.changed_fields = list
    all_fields = self.attributes.keys
    self.unchanged_fields = all_fields.delete_if { |a| changed_field_names.find { |c| c==a } }

    return list
  end

  def clear_combo_prompts
    # puts "CLEAR COMBO"
    @cc_count = 0 if not @cc_count
    if @cc_count == 0
      @cc_count = 1
    else
      return
    end

    return if self.cancel_clear_combo_prompts == true
    #clear all 'select a value from' field values
    ignore_fields = fields_not_to_clean
    self.attributes.each do |key, value|
      #puts "key " + key + " val: " + value.to_s.upcase
      ignore = false
      if ignore_fields != nil
        ignore = ignore_fields.find { |field| field.to_s.upcase == key.to_s.upcase }
        puts "ignore"
      end
      if ignore == false
        if value.to_s.upcase.index("SELECT ")!= nil||value.to_s == "<empty>"||value.to_s.strip == ""
          #puts "cleared: " + value.to_s
          eval "self." + key + " = nil"

        end
        #sql injection check
        if value.to_s != "<empty>"
          if  value.to_s.upcase.index("INSERT")!= nil||value.to_s.upcase.index("UPDATE")!= nil||value.to_s.upcase.index("EXEC")||value.to_s.index("--")!= nil||value.to_s.index("or 1")!= nil||value.to_s.index("<")!= nil||value.to_s.index(">")!= nil

            #eval "self." + key + " = nil"
            #puts "injection attempt " + value.to_s
            #errors.add_to_base("You attempted to populate a field with a sql command syntax. <> Due to a security risk this cannot be allowed")
          end
        end
      end
    end

  end

  def fields_not_to_clean
    nil
  end

  def update_attributes_state(params)
    params.each do |key, val|
      if val == ""|| val == "<empty>"
        params[key] = nil
      end
    end
    self.attributes= params

  end


  #---------------------------------------------------------------
  #This method takes a hash of values and copies it to an instance
  #of AR. NB: the field types must match
  #
  #---------------------------------------------------------------
  def import(data_hash, exclusion_list = nil)

    data_hash.each do |key, val|
      if exclusion_list && exclusion_list.find { |f| f==key }
        next
      end

      if !self.respond_to?(key)
        next
      end

      #eval "self." + key + " = '#{val}'"
      self.send(key + "=", val)

    end


  end

  def export_attributes(target_record, copy_ids = nil, ignore_fields = nil)

    self.attributes.each do |name, attr|

      if ignore_fields
        if ignore_fields.find { |f| f == name }
          next
        end
      end

      if !((name.index("_id")&& !copy_ids)|| name == "id")
        if target_record.has_attribute?(name)
          if attr == nil

            eval "target_record." + name + " = nil"
          else
#            if attr.class.to_s == "String"
#              attr.gsub!("'","\'")
#              attr.gsub!("\"","\'")
#
#            end

            target_record.send(name + "=", attr)
            #eval "target_record." + name + " = \"#{attr}\""

          end
        end
      end
    end

  end

end


class Hash

  def method_missing(name, *args)
    key = nil
    if name.to_s.index("=") #mutator
      key = name.to_s.chop
      if self.has_key?(key)
        self[key] = args[0]
      end
    else #accessor
      if self.has_key?(name.to_s)
        return self[name.to_s]
      end
    end
  end


  def export_attributes(target_record, copy_ids = nil, ignore_fields = nil)

    self.each do |name, attr|

      if ignore_fields
        if ignore_fields.find { |f| f == name }
          next
        end
      end

      if !((name.index("_id")&& !copy_ids)|| name == "id")
        if target_record.has_attribute?(name)
          if attr == nil

            eval "target_record." + name + " = nil"
          else

            target_record.send(name + "=", attr)
          end
        end
      end
    end

  end

end
