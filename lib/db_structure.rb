module DbStructure

  class Column
    attr_accessor :name, :sql_type, :default, :null

    def initialize( adapter_column )
      @name     = adapter_column.name
      @sql_type = adapter_column.sql_type
      @default  = adapter_column.default.nil? ? 'no default' : adapter_column.default
      @null     = adapter_column.null ? 'NULL' : 'NOT NULL'
      @type     = adapter_column.type

      @opts  = []
      @opts << ", :null => false"                            unless adapter_column.null
      if [:string, :text].include? adapter_column.type
        @opts << ", :default => '#{adapter_column.default}'" if adapter_column.default
      else
        @opts << ", :default => #{adapter_column.default}"   if adapter_column.default
      end
      @opts << ", :precision => #{adapter_column.precision}" if adapter_column.precision
      @opts << ", :scale => #{adapter_column.scale}"         if adapter_column.scale
      @opts << ", :limit => #{adapter_column.limit}"         if adapter_column.limit && adapter_column.type == :string && adapter_column.limit != 255
    end

    def <=>(other)
      @name <=> other.name
    end
  end

  class Table
    attr_accessor :name

    def initialize(name)
      @name = name
    end

    # Returns an array of columns in the table.
    def columns
      ActiveRecord::Base.connection.columns(@name).map {|c| Column.new(c) }
    end

  end

  class Output

    # Returns a sorted array of Table objects for a given database connection.
    def initialize
      @tables = []
      ActiveRecord::Base.connection.tables.each do |t|
        @tables << Table.new(t)
      end
      @tables = @tables.sort_by {|t| t.name }
    end

    def generate
      db_name   = ActiveRecord::Base.configurations[RAILS_ENV]['database'] || ActiveRecord::Base.configurations[RAILS_ENV]['url']
      table_str = ''
      key_str   = ''
      prev_l    = ''
      @tables.each do |table|
        table_str << "<tr><th colspan=\"4\"><a name=\"#{table.name}\">#{table.name}</a></th></tr>\n"
        table.columns.sort.each do |column|
          table_str << "<tr class=\"data\">\n"
          table_str << "  <td><strong>#{column.name}</strong></td><td><i>#{column.sql_type}</i></td><td>#{column.null}</td><td>#{column.default}</td>\n"
          table_str << "</tr>\n"
        end
        table_str << "<tr><td colspan=\"4\">&nbsp;</td></tr>\n"
        if table.name[0,1] != prev_l
          prev_l = table.name[0,1]
          key_str << "<li class=\"letter\"><b>#{table.name[0,1].upcase}</b></li>"
        end
        key_str << "<li><a href='##{table.name}'>#{table.name}</a></li>"
      end

      <<EOS
<!doctype html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>#{db_name} db: Tables with sorted fields</title>
    <link rel="shortcut icon" type="image/x-icon" href="/favicon.ico">
    <style type="text/css">
      body { font-family: Arial, Helvetica, sans-serif; }
      table {border-collapse:collapse;} td {padding: 0 12px; color: #444;} th, .letter {border: 1px solid #487d48; background: #7ad37a url(/stylesheets/jskr1/images/ui-bg_gloss-wave_55_7ad37a_500x100.png) 50% 50% repeat-x; color: #fff; font-weight: bold; text-align:left; padding:4px 10px; font-size:120%;} tr.data:hover {background:#90EE90;} #navigation { height: 300px; overflow-y: auto; border: thin solid #333; margin-top: 10px; padding-right: 10px; } #navigation li:hover { background: #90EE90; } #navigation ul { list-style: none; padding:0 10px; } #navigation a {text-decoration: none; } .tables_list {float:left;} h2 {margin:0;padding:0;} div.rightbox {float:left;margin-left:20px;} div.fixbox {position:fixed;} strong {padding-left:10px;} .backlink {padding-left:10px;font-size:smaller;text-decoration: none;}
    </style>
    <script type="text/javascript">
    var loading_pic = window.parent.document.getElementById("content_loading_gif");;
    if (loading_pic !== null) { loading_pic.style.visibility = "hidden"; }
    loading_pic = window.parent.document.getElementById("l3_db structure_loading_img");
    if (loading_pic !== null) { loading_pic.style.visibility = "hidden"; }
    </script>
  </head>
  <body>

    <div id="content">
      <h2>Tables in <em>#{db_name}</em> with fields sorted alphabetically</h2>
      <br />
      <div class="tables_list">
        <table>
          #{table_str}
        </table>
      </div>

      <div class="rightbox">
        <div class="fixbox">
          <strong>#{db_name}</strong>
          <br />
          <div id="navigation">
            <ul>
              #{key_str}
            </ul>
          </div>
        </div>
      </div>
    </div>

  </body>
</html>
EOS
    end

  end

  class TableSqlDecorator

    def initialize(model)
      @model = model
    end

    def value_for_sql_string(type, value)
      return 'NULL' if value.nil?
      case type # string, datetime, boolean, integer, date, decimal, text
      when :string, :text
        "'#{value}'"
      when :date
        "'#{value}'"
      when :datetime
        "'#{value.xmlschema}'"
      else # :integer, :decimal
        value
      end
    end

    # Simple method to create an insert statement for a model instance.
    # NB. This does not handle the case where an id needs to be looked up
    #     from another table.
    # TODO: pass join info into options for building up values from select.
    def insert_sql(options = {})
      ignore_fields        = Array(options[:ignore_fields]) << 'id'
      model_class          = @model.class
      columns              = []
      values               = []
      column_names         = model_class.column_names.dup

      colhash = model_class.columns_hash
      column_names.each do |k|
        v = colhash[k]
        if v.nil?
          colhash.each {|_,nv| if nv.name == k then v = nv; break; end }
        end
        next if ignore_fields.include?(v.name)
        next if v.name.end_with? '_id' && options[:no_ids]
        next unless column_names.include? v.name

        columns << k
        values  << value_for_sql_string(v.type, @model[k])
      end

      s = "INSERT INTO #{@model.class.table_name} (#{columns.join(', ')})\n"
      s << "VALUES(#{values.join(', ')});\n"
    end

  end


end
