class UserDefinedReport < ActiveRecord::Base
  self.table_name = "user_defined_reports"
  
  attr_accessor :tag1, :tag2, :tag3, :tag4, :tag5, :existing_report
  
  has_and_belongs_to_many :users
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'

  #	============================
  #	 Validations declarations:
  #	============================
  validates_presence_of :user_defined_report_name
  validates_presence_of :ranking
  validates_numericality_of :ranking
  
  def validate
      is_valid = true
    
     if self.new_record? && is_valid
        validate_user_defined_report_name_and_ranking
     end
  end
  
  def cancel_clear_combo_prompts
     true
  end
  
  def validate_user_defined_report_name_and_ranking  #(user_def_rpt_name,ranking)
     msg = UserDefinedReport.validate_user_defined_report_name(self.user_defined_report_name)
     msg += UserDefinedReport.validate_ranking(self.ranking)
     #return msg
     if msg != ""
        errors.add_to_base(msg)
     end
  end
  
  def self.validate_uniqueness_of_user_defined_report_name(report_name, user_name, user_defined_report_name)
     exists = UserDefinedReport.find_by_report_name_and_user_name_and_user_defined_report_name(report_name, user_name, user_defined_report_name)
     ret = nil
     if exists != nil
        ret = true
     else
        ret = false
     end
     return ret
  end
  
  def self.get_existing_user_definded_report_names(tag_hash,user_name,report_name)
     condition = ""
     tag_hash.each do |key,v|
        if key.to_s != "existing_user_defined_report"
          if condition == ""
              condition += "strpos(tags,'#{v}') != 0"
          else
              condition += " and strpos(tags,'#{v}') != 0"
          end
        end
     end
     if condition == ""
        condition += "user_name = '#{user_name}'"
     else
        condition += " and user_name = '#{user_name}'"
     end
     
     if condition == ""
        condition += "report_name = '#{report_name}'"
     else
        condition += " and report_name = '#{report_name}'"
     end
     puts "CONDITION : " + condition
     existing_user_defined_report_names = UserDefinedReport.find_by_sql("select * from user_defined_reports where(#{condition})").map{|g| [g.user_defined_report_name]}
     existing_user_defined_report_names.unshift("<empty>")
     return existing_user_defined_report_names
  end
  
  def self.get_user_defined_report_name(hash,user_name,report_name)
     condition = ""
     hash.each do |key,val|
        if condition == ""
            if key.to_s == "existing_user_defined_report"
               condition += "user_defined_report_name = '#{val}'"
            else
               condition += "strpos(tags,'#{val}') != 0"
            end
        else
            if key.to_s == "existing_user_defined_report"
               condition += " and user_defined_report_name = '#{val}'"
            else
               condition += " and strpos(tags,'#{val}') != 0"
            end
        end
     end
     if condition == ""
        condition += "user_name = '#{user_name}'"
     else
        condition += " and user_name = '#{user_name}'"
     end
     
     if condition == ""
        condition += "report_name = '#{report_name}'"
     else
        condition += " and report_name = '#{report_name}'"
     end
     user_defined_report_name = UserDefinedReport.find_by_sql("select * from user_defined_reports where(#{condition})").map{|g| [g.user_defined_report_name]}
     return user_defined_report_name
  end
  
  def self.get_tags_list(user_name)
     list = MyTag.find_by_sql("select * from my_tags where user_name = '#{user_name}'").map{|g| [g.tag_name]}
     return list
  end
  
  def self.get_full_list_of_existing_user_defined_reports(user_name,report_name)
     full_list = UserDefinedReport.find_by_sql("select * from user_defined_reports where user_name = '#{user_name}' and report_name = '#{report_name}'").map{|g| [g.user_defined_report_name]}
     return full_list
  end
  
  def create_tags
     if self.tags != nil || self.tags != ""
        if self.tags.index(",") != nil
           @tags_array = self.tags.split(",")
           self.tag1 = @tags_array[0].to_s
           self.tag2 = "";
           self.tag3 = "";
           self.tag4 = "";
           self.tag5 = "";
           self.tag2 = @tags_array[1].to_s if @tags_array[1] != nil
           self.tag3 = @tags_array[2].to_s if @tags_array[2] != nil
           self.tag4 = @tags_array[3].to_s if @tags_array[3] != nil
           self.tag5 = @tags_array[4].to_s if @tags_array[4] != nil
        else
           self.tag1 = self.tags
           self.tag2 = "";
           self.tag3 = "";
           self.tag4 = "";
           self.tag5 = "";
        end
     else
        self.tag1 = "";
        self.tag2 = "";
        self.tag3 = "";
        self.tag4 = "";
        self.tag5 = "";
     end
  end

  # Return a string of html showing all values in the +view_state+ hash.
  def render_for_debug
    report_state_hash = YAML.load(self.view_state)

    <<-EOS
      <h3>search_fields</h3>
      #{report_state_hash[:search_fields].inspect}
      <hr />
      <h3>full_parameter_query</h3>
      #{report_state_hash[:full_parameter_query].inspect}
      <hr />
      <h3>parameter_fields_values</h3>
      #{report_state_hash[:parameter_fields_values].inspect}
      <hr />
      <h3>search_engine_or_values</h3>
      #{report_state_hash[:search_engine_or_values].inspect}
      <hr />
      <h3>search_engine_limit</h3>
      #{report_state_hash[:search_engine_limit].inspect}
      <hr />
      <h3>functions</h3>
      #{report_state_hash[:functions].inspect}
      <hr />
      <h3>search_engine_group_by_columns</h3>
      #{report_state_hash[:search_engine_group_by_columns].inspect}
      <hr />
      <h3>search_engine_order_by_columns</h3>
      #{report_state_hash[:search_engine_order_by_columns].inspect}
      <hr />
      <h3>main_table_name</h3>
      #{report_state_hash[:main_table_name].inspect}
      <hr />
      <h3>table_name</h3>
      #{report_state_hash[:table_name].inspect}
      <hr />
      <h3>report_name</h3>
      #{report_state_hash[:report_name].inspect}
      <hr />
      <h3>operator_signs</h3>
      #{report_state_hash[:operator_signs].inspect}
      <hr />
      <h3>columns_list</h3>
      #{report_state_hash[:columns_list].inspect}
      <hr />
    EOS
  end

  # Grab a single value from the report hash.
  def value_from_report_hash(key)
    report_state_hash = YAML.load(self.view_state)
    report_state_hash[key]
  end

  # Return a String SQL statement with parameters.
  def sql_statement(report_state_hash, for_webquery=false)
    statement = FieldParser.new(report_state_hash[:full_parameter_query],
                                report_state_hash[:parameter_fields_values],
                                report_state_hash[:search_engine_or_values],
                                report_state_hash[:operator_signs]).query

    if for_webquery # Always use maximum LIMIT.
      max_limit = Globals.webquery_max_rows
      if statement.upcase.index(" LIMIT ") != nil
        pattern      = / limit [0-9]+/i
        limit_clause = " LIMIT #{max_limit}"
        statement.gsub!(pattern, limit_clause)
      else
        statement << " LIMIT #{max_limit}"
      end
    else
      max_limit = Globals.search_engine_max_rows
      if report_state_hash[:search_engine_limit].to_s != ""
        if statement.upcase.index(" LIMIT ") != nil
          pattern      = / limit [0-9]+/i
          limit_clause = " LIMIT #{report_state_hash[:search_engine_limit]}"
          statement.gsub!(pattern, limit_clause)
        else
          if report_state_hash[:search_engine_limit].to_i > max_limit.to_i
            statement << " LIMIT #{max_limit}"
          else
            statement << " LIMIT #{report_state_hash[:search_engine_limit]}"
          end
        end
      else
        statement << " LIMIT #{max_limit}"
      end
    end
    statement
  end

  # Shape the parameters to look as they would after the report parameters form has been submitted.
  def setup_params(parms, for_download=false)
    report_state_hash = YAML.load(self.view_state)

    parms[:parameter_field] = {:excel_only => '0' }
    report_state_hash[:parameter_fields_values].each do |parm_set|
      parms[:parameter_field][parm_set[:field_name]] = parm_set[:field_value]
      parms[:parameter_field]["#{parm_set[:field_name]}-sign"] = report_state_hash[:operator_signs][parm_set[:field_value]]
    end
    parms[:parameter_field]['excel_only'] = for_download ? '0' : '1'
    parms['apply_functions_hidden_field'] = report_state_hash[:functions]
    parms['group_by_hidden_field']        = report_state_hash[:search_engine_group_by_columns]
    parms['order_by_hidden_field']        = report_state_hash[:search_engine_order_by_columns]
  end

  # Returns String of HTML for use in a spreadsheet.
  # The saved query is run and rendered as a table.
  def render_for_webquery( statement, group_by_columns )

    report_state_hash = YAML.load(self.view_state)
    conn              = User.connection
    recordset         = conn.select_all(Globals.cleanup_where(statement))

    if group_by_columns.nil? || group_by_columns.empty?
      if report_state_hash[:columns_list].nil? || report_state_hash[:columns_list].empty?
        if recordset.empty?
          keys = ['No records found']
        else
          keys = recordset[0].keys
        end
      else
        # Use the provided list of columns.
        keys = report_state_hash[:columns_list].map {|k| k.gsub('"', '').strip }
      end
    else
      keys = group_by_columns
      # Include the sum or count columns.
      unless recordset.empty?
        extra_cols =  recordset[0].keys - keys
        keys       += extra_cols
      end
    end

    s = "<table><tr><th>#{keys.join('</th><th>')}</th></tr>"
    recordset.each do |record|
      s << '<tr>'
      keys.each do |k|
        s << "<td>#{format_for_spreadsheet(record[k])}</td>"
      end
      s << '</tr>'
    end
    s << '</table>'
  end

  # When a spreadsheet loads this data, any numbers starting with 0 need to have "'" prefix.
  # Also if a number is too long, the spreadsheet will convert to scientific notation,
  # so we prefix long numbers with "'" too.
  def format_for_spreadsheet(str)
    if str =~ /^\d+$/ && str.length > 1
      return "'#{str}" if str.start_with?('0') || str.length > 10
    end
    str
  end
  
  private
  
  def self.validate_user_defined_report_name(user_def_rpt_name)
     if user_def_rpt_name == ""
        return "field <b>user_defined_report_name</> cannot be blank. "
     else
       return ""
     end
  end
  
  def self.validate_ranking(ranking)
     rank = ""
     if ranking == ""
       rank = "field <b>ranking</b> cannot be black. "
     else
        if ranking.class.to_s == "Fixnum"
           rank = ""
        else
           rank = "field <b>ranking</b> must be a numeric value. "
        end
     end
  end
  
end
