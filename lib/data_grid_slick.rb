# == JQuery Slick Grid
#
module DataGridSlick

  class DataGrid
    attr_reader :stack_trace, :key_based_access
    attr_accessor :is_popup, :caption, :grid_id, :grouped, :group_fields, :group_collapsed,
                  :fullpage, :reload_url, :groupable_fields, :height, :width, :group_headers,
                  :group_headers_colspan, :no_of_frozen_cols,
                  :group_fields_to_sum, :group_fields_to_count, :group_fields_to_avg,
                  :group_fields_to_max, :group_fields_to_min, :show_caption, :show_header,
                  :non_selectable_ids

    VALID_FIELD_TYPES = %w(text action checkbox frame_link link_window action_collection)
    VALID_EDITORS     = [:text, :checkbox, :long_text, :date, :integer]
    DEFAULT_CAPTION   = 'The Grid'

    def initialize(environment, data_set, column_configs, plugin = nil, key_based_access = nil, special_commands = nil, options={})

      @env                   = environment
      @stack_trace           = ''
      @multi_select          = @env.multi_select.blank? ? false : true
      @multi_select_action   = @env.url_for(:action => @env.multi_select) if @multi_select
      @key_based_access      = key_based_access
      @hidden_id_column      = @env.hidden_id_column
      @special_commands      = special_commands

      @grid_id               = options[:grid_id]               || 'slickgridid'
      @caption               = options[:caption]               || DEFAULT_CAPTION
      @grouped               = options[:grouped]               || false
      @group_collapsed       = options[:group_collapsed]       || false
      @group_fields          = options[:group_fields]          || []
      @groupable_fields      = options[:groupable_fields]      || []
      @group_headers         = options[:group_headers]         || []    # NOT YET IMPLEMENTED
      @group_headers_colspan = options[:group_headers_colspan] || false # NOT YET IMPLEMENTED
      @fullpage              = options[:fullpage]              || true
      @reload_url            = options[:reload_url]            || nil
      @height                = options[:height]                || nil
      @width                 = options[:width]                 || 800
      @no_of_frozen_cols     = options[:no_of_frozen_cols]     || 0     # NOT YET IMPLEMENTED
      @group_fields_to_sum   = options[:group_fields_to_sum]   || []
      @group_fields_to_count = options[:group_fields_to_count] || []
      @group_fields_to_avg   = options[:group_fields_to_avg]   || []
      @group_fields_to_max   = options[:group_fields_to_max]   || []
      @group_fields_to_min   = options[:group_fields_to_min]   || []
      @non_selectable_ids    = options[:non_selectable_ids]    || []
      @show_caption          = options[:show_caption]          || true
      @show_header           = options[:show_header]           || true
      @editable              = options[:save_action]           || false
      @save_action           = options[:save_action]
      @no_id_field           = true
      @totcount              = 0
      @pre_selected_ids      = []

      raise MesScada::InfoError, "DataGrid: You cannot have an editable multi-select grid." if @multi_select && @editable

      #validate input data
        @empty    = true
        empty_var = nil
        empty_var = 'environment' if environment.nil?
        empty_var = 'data_set' if data_set.nil?
        empty_var = 'column_configs' if column_configs.nil?
        empty_var = 'column_configs(no data)' if column_configs.length == 0

        raise MesScada::InfoError, "DataGrid: The variable: #{empty_var} is empty." unless empty_var.nil?

        if @no_of_frozen_cols > 0 && (!@groupable_fields.empty? || @grouped)
          raise MesScada::InfoError, "DataGrid: Cannot allow grouping and frozen columns at the same time."
        end

        @plugin         = plugin
        if @plugin && !@plugin.is_a?(MesScada::GridPlugin)
          raise MesScada::InfoError, "DataGrid: The plugin \"#{@plugin.class.name}\" is not a valid MesScada::GridPlugin."
        end
        @column_configs = column_configs
        @data_set       = data_set
        has_editable_column = false

        if data_set.length > 0
          @empty        = false
          @grid_columns = []

          @column_configs.each do |column_config|
            @no_id_field = false if 'id' == column_config[:field_name] || :id == column_config[:field_name]
            #create the correct column type and add to collection

            # Make the field name the same as the column name if there is a column name.
            column_config[:field_name] = column_config[:column_name] if column_config[:column_name]

            raise MesScada::InfoError, "DataGrid: The 'field_name' setting is empty" if column_config[:field_name].nil?
            raise MesScada::InfoError, "DataGrid: The 'field_type' setting for field: #{column_config[:field_type]} is empty" if column_config[:field_type].nil?

            column_config[:field_type] = column_config[:column_type] if column_config[:column_type]

            unless VALID_FIELD_TYPES.include? column_config[:field_type]
              raise MesScada::InfoError, "DataGrid: The field type: #{column_config[:field_type]} is not valid. \n It must be '#{VALID_FIELD_TYPES.join("' or '")}'."
            end

            if column_config[:editor]
              raise MesScada::InfoError, "DataGrid: The field: #{column_config[:field_name]} is editable, but there is no save_action defined." unless @editable
              has_editable_column = true
              unless VALID_EDITORS.include? column_config[:editor]
                raise MesScada::InfoError, "DataGrid: The editor: #{column_config[:editor]} is not valid. \n It must be '#{VALID_EDITORS.join("' or '")}'."
              end
              raise MesScada::InfoError, "DataGrid: The field: #{column_config[:field_name]} is date-editable, but the data type is not a Date." if :date == column_config[:editor] && column_config[:data_type] != 'date'
              raise MesScada::InfoError, "DataGrid: The field: #{column_config[:field_name]} is checkbox-editable, but the data type is not a Boolean." if :checkbox == column_config[:editor] && column_config[:data_type] != 'boolean'
              raise MesScada::InfoError, "DataGrid: The field: #{column_config[:field_name]} is integer-editable, but the data type is not an Integer." if :integer == column_config[:editor] && column_config[:data_type] != 'integer'
            end

            # Make sure that only the last portion of the field name is used if there is a ' ' present (Only applies to data columns):
            column_config[:field_name] = column_config[:field_name].split(' ').last if column_config[:field_type] == 'text'
            # For the COLUMN name, make sure that only the last portion of the field name is used if there is a '.' present:
            column_config[:col_name] = column_config[:field_name].split('.').last

            set_column_data_type(column_config)
            # OK, we have valid enough data to attempt creation - further validation will be done
            # inside the constructors of the individual column objects
              grid_column =
              case column_config[:field_type]
              when "link_window"
                LinkPopUpWindow.new(self, environment, column_config, @data_set[0], column_config[:field_name])
              when "text"
                GridTextColumn.new(self, environment, column_config, @data_set[0], column_config[:field_name])
              when "action"
                GridActionColumn.new(self, environment, column_config, @data_set[0], column_config[:field_name])
              when "frame_link"
                raise MesScada::InfoError, "DataGrid: The field_type 'frame_link has not been implemented."
                # DataGridJquery::GridFrameLinkColumn.new(self, environment, column_config, @data_set[0], column_config[:field_name])
              when "checkbox"
                raise MesScada::InfoError, "DataGrid: The field_type 'checkbox has been deprecated. Set the column's data_type to 'boolean'"
              when "action_collection"
                GridActionCollectionColumn.new(self, environment, column_config, @data_set[0], column_config[:field_name], @plugin)
              else
                nil
              end

              @grid_columns.push grid_column

          end
        end

        if @editable && !has_editable_column
          @editable = false
        end

        @has_popup_link = !@special_commands.nil?
        if @has_popup_link
          @popup_link = generate_popup_link(@special_commands)
        end

    end

    # Returns javascript defining grouping formatter functions.
    def js_for_grouping_formatters
      <<EOS
  // --- Grouping formatters
  function avgTotalsFormatter(totals, columnDef) {
    var val = totals.avg && totals.avg[columnDef.field];
    if (val != null) {
      return "avg: " + Math.round(val);
    }
    return "";
  }

  function sumTotalsFormatter(totals, columnDef) {
    var val = totals.sum && totals.sum[columnDef.field];
    if (val != null) {
      return "total: " + ((Math.round(parseFloat(val)*100)/100));
    }
    return "";
  }

  function maxTotalsFormatter(totals, columnDef) {
    var val = totals.max && totals.max[columnDef.field];
    if (val != null) {
      return "max: " + ((Math.round(parseFloat(val)*100)/100));
    }
    return "";
  }

  function minTotalsFormatter(totals, columnDef) {
    var val = totals.min && totals.min[columnDef.field];
    if (val != null) {
      return "min: " + ((Math.round(parseFloat(val)*100)/100));
    }
    return "";
  }

  function cntTotalsFormatter(totals, columnDef) {
    var val = totals.group.count; // && totals.cnt[columnDef.field];
    if (val != null) {
      return "count: " + ((Math.round(parseFloat(val)*100)/100));
    }
    return "null";
  }
EOS
    end

    # Create aggregators item for SlickGrid setGrouping.
    def js_aggregators
      ags = []
      ags += @group_fields_to_sum.map   { |a| "new Slick.Data.Aggregators.Sum('#{a}')" }
      ags += @group_fields_to_count.map { |a| "new Slick.Data.Aggregators.Sum('#{a}')" }
      ags += @group_fields_to_avg.map   { |a| "new Slick.Data.Aggregators.Avg('#{a}')" }
      ags += @group_fields_to_min.map   { |a| "new Slick.Data.Aggregators.Min('#{a}')" }
      ags += @group_fields_to_max.map   { |a| "new Slick.Data.Aggregators.Max('#{a}')" }
      if ags.empty?
        ''
      else
        "grid_aggregators = [
          #{ags.join(",\n")}
        ];"
      end
    end

    # Return javascript string for SlickGrid grouping.
    def js_set_grouping
      ags = js_aggregators
      case @group_collapsed
      when TrueClass, FalseClass
        collapsed = @group_collapsed ? ', collapsed: true' : ''
        collapsed_level = nil
      else
        raise MesScada::Error, "group_collapsed value must be true/false or an integer for the level to collapse at. Value is #{@group_collapsed}." unless @group_collapsed.is_a? Integer
        collapsed_level = @group_collapsed
        collapsed = nil
      end
      if @group_fields.length == 1
        g_start = "dataView.setGrouping("
        g_end   = ");"
      else
        g_start = "dataView.setGrouping([\n"
        g_end   = "]);"
      end
      colours = ['green', 'blue', 'orange', 'purple', 'red']
      js_ags = ags.blank? ? '' : ",
        aggregators: grid_aggregators,
        aggregateCollapsed: true"
      ar = []
      @group_fields.each_with_index do |grp_fld, index|
        if collapsed_level
          if index < collapsed_level
            collapse_rule = ''
          else
            collapse_rule = ', collapsed: true'
          end
        else
          collapse_rule = collapsed
        end
        ar << "{\ngetter: '#{grp_fld}',\nformatter: function (g) {\nreturn g.value + '  <span style=\"color:#{colours[index]}\">(' + g.count + ')</span>';\n}#{js_ags}#{collapse_rule}\n}"
      end
      g_start << ar.join(",\n") << g_end
    end

    # Render the html table to which the grid is attached.
    def render_html
      # scrub quotes from the caption:
      @caption      = @caption.gsub(/"|'/,'').gsub('_',' ') if @caption
      @caption      = '&nbsp;' if @caption.blank?
      export_method = build_csv_export_action

      buttons = ''
      menu = []
      unless @empty
        buttons << "<button id=\"#{@grid_id}zoomer\" onClick=\"zoomGridButtonClick();\" title='Zoom grid'><img src='/images/grid_icons/zoom.png' width='16' height='16' /></button>"
        menu << 'viewrow'
        menu << 'sep'
        menu << 'exports'
        menu << 'sep'
        menu << 'settings'
        if @grouped || !@groupable_fields.empty?
          menu << 'sep'
          menu << 'groups'
        end
        if @multi_select
          menu << 'sep'
          menu << 'multiselect'
          menu << 'savemulti'
        end
        if @editable
          menu << 'sep'
          menu << 'savechanges'
        end
      end

      unless @reload_url.blank?
        menu << 'reload'
      end
      buttons << "<button id='#{@grid_id}context' title='Grid options'><img src='/images/grid_icons/ui_menu_blue.png' width='16' height='16' /></button>" unless menu.empty?
      if @has_popup_link
        unless @empty && @popup_link.hide_if_no_grid_data
          buttons << "<button style='vertical-align:bottom;color:#333;text-transform:capitalize;' onClick=\"#{generate_command_link};\">#{generate_command_link_text}</button>"
        end
      end
      buttons << "<input type='text' id='#{@grid_id}search' placeholder='Search...' style='width:100px;margin-left:5px;margin-right:5px;vertical-align:top;' />" unless @empty

      # Shortcut buttons for grid header
      popup = "<span class='btnpopup'>"
      popup << "<button title='Export csv' onClick=\"downloadSlickGrid('#{@grid_id}','#{@caption.gsub('&nbsp;','grid_contents').gsub(/[\/:*?"\\<>\|\r\n]/i, '-')}');\"><img src='/images/grid_icons/csv_text.png' width='16' height='16' /></button>"
      popup << "<button title='Save filter settings' onClick=\"saveLocSlickGrid('#{@grid_id}','#{@caption}');\"><img src='/images/grid_icons/filter_large.png' width='16' height='16' /></button>"
      popup << "<button title='Apply filter settings' onClick=\"getLocSlickGrid('#{@grid_id}','#{@caption}');\"><img src='/images/grid_icons/wand.png' width='16' height='16' /></button>"
      popup << "<button title='Save column settings' onClick=\"saveLocSlickGridCols('#{@grid_id}');\"><img src='/images/grid_icons/application_tile_horizontal.png' width='16' height='16' /></button>"
      popup << "<button title='Apply column settings' onClick=\"getLocSlickGridCols('#{@grid_id}');\"><img src='/images/grid_icons/wand.png' width='16' height='16' /></button>"
      if @multi_select
        popup << "<button id='#{@grid_id}savemulti' title='Save selection' onClick=\"returnMultiSelectIdsFromGrid('#{@grid_id}','#{@multi_select_action}');\"><img src='/images/grid_icons/disk.png' width='16' height='16' /></button>"
      end
      if @editable
        popup << "<button id='#{@grid_id}savechanges' title='Save changes' onClick=\"returnChangesFromGrid('#{@grid_id}','#{@save_action}');\"><img src='/images/grid_icons/disk.png' width='16' height='16' /></button>"
      end
      popup << "</span>"
      if 0 == @totcount
        head2 = "<div class='sgrdhead'>#{buttons} <span id='#{@grid_id}status-label' class='sgrheadlbl'>There are no rows to display</span></div>"
      else
        head2 = "<div class='sgrdhead'>#{buttons} <span class='sgrBubble'>#{popup}<span id='#{@grid_id}status-label' class='sgrheadlbl'>Showing all rows (#{@totcount})</span></span></div>"
      end

      if @show_caption
        if @caption == '&nbsp;'
          header = "<div id='#{@grid_id}_caption' class='jmt_slick_caption ui-widget-header ui-corner-top ui-helper-clearfix'>#{head2}</div>"
        else
          header = "<div id='#{@grid_id}_caption' class='jmt_slick_caption ui-widget-header ui-corner-top ui-helper-clearfix'>#{head2}<label style='border:thin solid #fff;padding:6px 4px;border-radius:6px;vertical-align:middle;text-transform:capitalize;overflow:hidden;'>#{@caption}</label></div>"
        end
      else
        header = ''
      end

      make_context_button(menu)

      if @fullpage
        %Q|#{header}<div id="#{@grid_id}" class="jmt_slick_grid slk_fullpage"></div>|
      else
        %Q|#{header}<div id="#{@grid_id}Container" class="jmt_slick_container" style="width:#{@width}px;height:#{calculate_grid_height}px;"><div id="#{@grid_id}" class="jmt_slick_grid" style="height:100%;width:100%;"></div></div>|
      end
    end

    def context_item(item)
      return "\"sep#{Time.now.usec}\": \"---------\"" if item == 'sep'

      if 'groups' == item
        if @groupable_fields.empty?
          changegrp = ''
        else
          changegrp = ', "changegrp": {"name": "Change grouping", "icon": "changegrp"}'
        end
        return <<EOS
        "sub_grp": {
          "name": "Groups",
          "items": {
             "expand": {"name": "Expand all groups", "icon": "expand"},
             "sep_grp": "---------",
             "collapse": {"name": "Collapse all groups", "icon": "collapse"}#{changegrp}
          }
        }
EOS
      end

      if 'settings' == item
        return <<EOS
        "sub_set": {
          "name": "Settings",
          "items": {
             "savefilter": {"name": "Save filter settings", "icon": "filter"},
             "loadfilter": {"name": "Apply saved filter", "icon": "apply"},
             "sep_set": "---------",
             "savecols": {"name": "Save column settings", "icon": "columns"},
             "loadcols": {"name": "Apply saved column settings", "icon": "apply"}
          }
        }
EOS
      end

      if 'exports' == item
        return <<EOS
        "sub_exp": {
          "name": "Export",
          "items": {
             "export": {"name": "CSV", "icon": "excel"},
             "tocsv": {"name": "CSV (with filter and column settings)", "icon": "csv"},
             "print": {"name": "Print", "icon": "print"}
          }
        }
EOS
      end

      if 'multiselect' == item
        return <<EOS
        "sub_msl": {
          "name": "Multi-select",
          "items": {
             "selectedids": {"name": "Show only selected rows", "icon": "check"},
             "sep_grp": "---------",
             "unselectedids": {"name": "Show rows as before", "icon": "uncheck"},
             "sep_grp2": "---------",
             "invertselectedids": {"name": "Invert selection", "icon": "reverse"}
          }
        }
EOS
      end

      icon = case item
             when 'viewrow'
               'report'
             when 'export'
               'excel'
             when 'tocsv'
               'csv'
             when 'print'
               'print'
             when 'savemulti'
               'save'
             when 'savechanges'
               'save'
             when 'reload'
               'refresh'
             else
               item
             end
      label = case item
             when 'viewrow'
               'View selected row'
             when 'export'
               'Export to csv'
             when 'tocsv'
               'Dump grid to csv'
             when 'print'
               'Print grid'
             when 'savemulti'
               'Save selection'
             when 'savechanges'
               'Save changes'
             when 'reload'
               'Reload grid'
              else
                item
              end
      "\"#{item}\": {name: \"#{label}\", icon: \"#{icon}\"}"
    end

    def make_context_button(menu)
      if menu.empty?
        @context_menu = ''
      else
        export_method = build_csv_export_action
        @context_menu = %Q@
   jQuery.contextMenu({
        selector: '##{@grid_id}context',
        trigger: 'left',
        callback: function(key, options) {
          switch(key) {
            case 'viewrow':
              viewRowGridButtonClick('#{@grid_id}','#{@caption}');
              break;
            case 'export':
              window.location.assign('/development_tools/data/#{export_method}');
              break;
            case 'tocsv':
              downloadSlickGrid('#{@grid_id}','#{@caption.gsub('&nbsp;','grid_contents').gsub(/[\/:*?"\\<>\|\r\n]/i, '-')}');
              break;
            case 'print':
              printSlickGrid('#{@grid_id}','#{@caption}');
              break;
            case 'savefilter':
              saveLocSlickGrid('#{@grid_id}','#{@caption}');
              break;
            case 'loadfilter':
              getLocSlickGrid('#{@grid_id}','#{@caption}');
              break;
            case 'savecols':
              saveLocSlickGridCols('#{@grid_id}');
              break;
            case 'loadcols':
              getLocSlickGridCols('#{@grid_id}');
              break;
            case 'savemulti':
              returnMultiSelectIdsFromGrid('#{@grid_id}','#{@multi_select_action}');
              break;
            case 'savechanges':
              returnChangesFromGrid('#{@grid_id}','#{@save_action}');
              break;
            case 'reload':
              window.location.href = '#{@reload_url}';
              break;
            case 'expand':
              expandCollapseGrid('#{@grid_id}',true);
              break;
            case 'collapse':
              expandCollapseGrid('#{@grid_id}',false);
              break;
            case 'changegrp':
              changeGridGrouping('#{@grid_id}',[#{@groupable_fields.map {|f| "'#{f}'" }.join(',')}]);
              break;
            case 'selectedids':
              filterSelectedIds('#{@grid_id}',true);
              break;
            case 'unselectedids':
              filterSelectedIds('#{@grid_id}',false);
              break;
            case 'invertselectedids':
              invertSelectedIds('#{@grid_id}');
              break;
            default:
              alert(key);
          }
        },
        items: {
        #{menu.map {|m| context_item(m) }.join(",\n")}
        }
    });
        @
      end
    end

    # Javascript code defining the SlickGrid.
    def render_grid

      @env.is_popup = @is_popup #reset value stored in session

      format_columns_for_js

      if @is_popup && !@show_caption # If no caption, display the zoom button in the column header for row number.
        zoomer = '<button onClick=\"zoomGridButtonClick();\" title="Zoom grid"><img src="/images/grid_icons/zoom.png" width="10" height="10" /></button>'
      else
        zoomer = ''
      end

      %Q[
        <script type="text/javascript">
        jQuery(document).ready(function () {
        if(!inSubFrame()) {jQuery('##{@grid_id}zoomer').remove(); } // Only display the zoom button in a subframe of the content frame.
        var searchString = '';
        var mygrid;
        var grid_aggregators = [];
        var multiSelectStore = {
          ids: []
        };

        #{@context_menu}

  var options = {
    enableCellNavigation: true,
    explicitInitialization: true,
    #{if @editable
    'editable: true, autoEdit: true, enableTextSelectionOnCells: false,'
    else
    'autoEdit: false, enableTextSelectionOnCells: true,'
    end}
    multiSelect: #{@multi_select},
    syncColumnCellResize: true,
    enableColumnReorder: true,
    multiColumnSort: true
  };

    // --- Columns
  var columns = #{@colmodel}
  // Change string-def of formatter to the real thing:
  for(var i = 0; i < columns.length; i++) {
    if(columns[i].editor === 'text_editor') {
      columns[i].editor = Slick.Editors.Text;
    }
    if(columns[i].editor === 'long_text_editor') {
      columns[i].editor = Slick.Editors.LongText;
    }
    if(columns[i].editor === 'checkbox_editor') {
      columns[i].editor = Slick.Editors.Checkbox;
    }
    if(columns[i].editor === 'date_editor') {
      columns[i].editor = Slick.Editors.Date;
    }
    if(columns[i].editor === 'integer_editor') {
      columns[i].editor = Slick.Editors.Integer;
    }
    if(columns[i].formatter === 'text') {
      columns[i].formatter = slickTextFormatter;
    }
    if(columns[i].formatter === 'delimited_1000') {
      columns[i].formatter = slickDelimitedFormatter;
    }
    if(columns[i].formatter === 'delimited_1000_4') {
      columns[i].formatter = slickDelimitedFormatter4;
    }
    if(columns[i].formatter === 'default_currency') {
      columns[i].formatter = slickCurrencyFormatter;
    }
    if(columns[i].formatter === 'default_currency_4') {
      columns[i].formatter = slickCurrencyFormatter4;
    }
    if(columns[i].formatter === 'bool') {
      columns[i].formatter = slickBooleanFormatter;
    }
    if(columns[i].formatter === 'link') {
      columns[i].formatter = slickLinkFormatter;
    }
    if(columns[i].formatter === 'link_window') {
      columns[i].formatter = slickLinkPopUpFormatter;
    }
    if(columns[i].formatter === 'action_collection') {
      columns[i].formatter = slickActionCollectionFormatter;
    }
    if(columns[i].groupTotalsFormatter === 'sumTotalsFormatter') {
      columns[i].groupTotalsFormatter = sumTotalsFormatter;
    }
    if(columns[i].groupTotalsFormatter === 'cntTotalsFormatter') {
      columns[i].groupTotalsFormatter = cntTotalsFormatter;
    }
    if(columns[i].groupTotalsFormatter === 'avgTotalsFormatter') {
      columns[i].groupTotalsFormatter = avgTotalsFormatter;
    }
    if(columns[i].groupTotalsFormatter === 'maxTotalsFormatter') {
      columns[i].groupTotalsFormatter = maxTotalsFormatter;
    }
    if(columns[i].groupTotalsFormatter === 'minTotalsFormatter') {
      columns[i].groupTotalsFormatter = minTotalsFormatter;
    }
  }
  #{js_for_grouping_formatters}

  #{if @multi_select
   "var checkboxSelector = new Slick.CheckboxSelectColumn({
      cssClass: 'slick-cell-checkboxsel'
    });
    columns.unshift(checkboxSelector.getColumnDefinition()); // add  unfiltered:true,
    columns[0]['unfiltered'] = true;"
    end}


    var RowNumberFormatter = function(row, cell, value, columnDef, dataContext) {
      return row + 1 + ' ';
    };

    #{if @grouped || !@groupable_fields.empty?
      "#{js_aggregators}
      var groupItemMetadataProvider = new Slick.Data.GroupItemMetadataProvider();
      "
      end}

    #{if @grouped
      "function groupBySomething() {
          #{js_set_grouping}
      }
      // Grouped - place an empty column on the left so the group header does not display with the styling of the real 1st column.
      columns.unshift({id:'colSpacer', name:'', field: 'cs', width:0, cannotTriggerInsert:true, resizable:false, selectable:false, sortable:false, unfiltered:true});
      var dataView = new Slick.Data.DataView();"
    else
      "var dataView = new Slick.Data.DataView();

    columns.unshift({id:'rowNumber', name:'#{zoomer}', field: 'rn', formatter:RowNumberFormatter, behavior:'select', cssClass:'cell-selection', width:40, cannotTriggerInsert:true, resizable:false, unselectable:true, sortable:false, unfiltered:true, cssClass: 'ui-state-default jqgrid-rownum slk_cell_right_align'});
      "
    end}

    // --- DataView
    //var dataView = new Slick.Data.DataView({ inlineFilters: true });

    mygrid = new Slick.Grid("##{@grid_id}", dataView, columns, options);

    #{if @grouped || !@groupable_fields.empty?
    "// register the group item metadata provider to add expand/collapse group handlers
    mygrid.registerPlugin(groupItemMetadataProvider);"
    end}

  #{if @multi_select
    "mygrid.setSelectionModel(new Slick.RowSelectionModel({selectActiveRow: false}));
     mygrid.registerPlugin(checkboxSelector);"
    elsif @editable
    "mygrid.setSelectionModel(new Slick.CellSelectionModel());"
    else
    "mygrid.setSelectionModel(new Slick.RowSelectionModel());"
    end}
    mygrid.registerPlugin( new Slick.AutoTooltips({ enableForHeaderCells: true }) );

    // Make the grid respond to DataView change events.
    dataView.onRowCountChanged.subscribe(function (e, args) {
      mygrid.updateRowCount();
      mygrid.render();
    });

    dataView.onRowsChanged.subscribe(function (e, args) {
      mygrid.invalidateRows(args.rows);
      mygrid.render();
    });

    dataView.getItemMetadata = function (row) {
      var item = dataView.getItem(row);

      if (item === undefined) {
        return null;
      }

      // overrides for grouping rows
      if (item.__group) {
        return groupItemMetadataProvider.getGroupRowMetadata(item);
      }

      // overrides for totals rows
      if (item.__groupTotals) {
        return groupItemMetadataProvider.getTotalsRowMetadata(item);
      }

      // Get value from row_colour & return as cssClass
      if (item.row_colour !== '') {
          return { cssClasses: item.row_colour }
      }

      return {};
    }

    mygrid.onSort.subscribe(function (e, args) {
      gridSorter(args.sortCols, dataView);
    });

    jQuery("##{@grid_id}").data('slickgrid', mygrid);       // Store a ref to the grid
    jQuery("##{@grid_id}").data('slickgridView', dataView); // Store a ref to the grid's dataView
    jQuery("##{@grid_id}").data('slickgridSelectedIds', multiSelectStore); // Store a ref to the grid's selected ids
    jQuery("##{@grid_id}").data('groupAggregators', grid_aggregators); // Store a ref to the grid's group aggregators


    var filterPlugin = new Ext.Plugins.HeaderFilter({sortAvailable: false});

    // This event is fired when a filter is selected
    filterPlugin.onFilterApplied.subscribe(function (e,args) {
        dataView.refresh();
        mygrid.resetActiveCell();
        showStatusCounts('#{@grid_id}');
    });

    mygrid.registerPlugin(filterPlugin);

    function gridSorter(sortCols, dataview) {
      dataview.sort(function (row1, row2) {
        for (var i = 0, l = sortCols.length; i < l; i++) {
            var field = sortCols[i].sortCol.field;
            var sign = sortCols[i].sortAsc ? 1 : -1;
            var x = row1[field], y = row2[field];
            var result = (x < y ? -1 : (x > y ? 1 : 0)) * sign;
            if (result != 0) {
                return result;
            }
        }
        return 0;
      }, true);
    }

    var columnpicker = new Slick.Controls.ColumnPicker(columns, mygrid, {selSortButtons: true, uiButtons:true});

    // wire up the search textbox to apply the filter to the model
    jQuery('##{@grid_id}search').keyup(function (e) {
      //Slick.GlobalEditorLock.cancelCurrentEdit();

      // clear on Esc
      if (e.which == 27) {
        this.value = "";
      }

      searchString = this.value;
      updateFilter();
    });

    function updateFilter() {
      dataView.setFilterArgs({
        searchString: searchString
      });
      dataView.refresh();
      showStatusCounts('#{@grid_id}');
    }

    // Filter the data (using underscore's _.contains)
    function filter(item, args) {
        // Show selected ids only in multiselect grid. See if this row's id is one of the selected ids.
        if (args.selectedIds) {
          return _.contains(multiSelectStore.ids, item.id);
        }

        // Get columns, but exclude non-filterable ones.
        var columns = [];
        jQuery.each(mygrid.getColumns(), function(i,val) {
          if(!val.unfiltered) { columns.push(val); }
        });

        var value = true;
        var searchHit = false;

        for (var i = 0; i < columns.length; i++) {
            var col = columns[i];
            var filterValues = col.filterValues;

            if (filterValues && filterValues.length > 0) {
                value = value & _.contains(filterValues, item[col.field]);
            }
        }
        if(value && args.searchString != '') {
          for (var i = 0; i < columns.length; i++) {
              var col = columns[i];
              if (String(item[col.field]).toLowerCase().indexOf(args.searchString.toLowerCase()) !== -1) {
                searchHit = true;
              }
          }
          return searchHit;
        }
        return value;
    }

    // --- Update grid
    dataView.beginUpdate();
    try {
      dataView.setItems(#{@grid_id}data);
    } catch (e) {
       if (String(e).indexOf('unique') !== -1) {
          alert('Unable to completely build the grid. Some rows will be missing. The error message is "'+e+'"');
       } else {
          // cannot handle this exception, so rethrow
          alert('Unable to build the grid. The error message is "'+e+'"');
          throw e;
       }
    }
    dataView.setFilterArgs({
      searchString: searchString
    });
    dataView.setFilter(filter);
    #{if @grouped
      "groupBySomething();"
    end}
    dataView.endUpdate();
    mygrid.init();
  #{if @multi_select
      s = "var onSelectedRowIdsChanged = dataView.syncGridSelection(mygrid, true, true);\n"
      s << "onSelectedRowIdsChanged.subscribe(function(e, syncObj) {multiSelectStore.ids = syncObj.ids;});"
      s << "\nmygrid.setSelectedRows(dataView.mapIdsToRows([#{@pre_selected_ids.join(',')}]));" unless @pre_selected_ids.empty?
      s
    else
      "dataView.syncGridSelection(mygrid, true);"
    end}

        // --- RESIZE WINDOW + GRID...
         jQuery(window).bind('resize', function() {
            resizeSlickGrid('#{@grid_id}', mygrid);
         }).trigger('resize');

        jQuery('##{@grid_id}Container').resizable({
          handles: 'se',
          resize: function( event, ui ) {
            resizeSlickGrid('#{@grid_id}', mygrid);
          }
        });
      jQuery('##{@grid_id}_caption').width(jQuery('##{@grid_id}').width());

    });
  </script>]

    end

    # Return the grid data within html +script+ tags.
    def build_grid_data
      if @empty
        "<script type=\"text/javascript\">#{build_empty_row}</script>"
      else
        "<script type=\"text/javascript\">#{build_rows}</script>"
      end
    end

  protected

    # Create a popup_link (ApplicationHelper::LinkWindowField) from settings in +special_commands+.
    def generate_popup_link(special_commands)
      settings = nil
      if special_commands[:settings]
        settings = special_commands[:settings]
      else
        settings = special_commands
      end

      settings[:host_and_port] = @env.request.host_with_port unless settings[:host_and_port]
      settings[:controller]    = @env.request.path_parameters['controller'] unless settings[:controller]
      if settings[:image]
        img_name               = @settings[:image].include?('.') ? @settings[:image] : "#{@settings[:image]}.png"
        settings[:image]       = @env.image_tag(img_name, :border => 0)
      end

      ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', settings, true, self)
    end

    # Return the popup_link from generate_popup_link as a popup.
    def generate_command
      @popup_link.build_control
    end

    # Return the popup_link text from generate_popup_link.
    def generate_command_link_text
      @popup_link.get_link_text
    end

    # Return the popup_link action from generate_popup_link.
    def generate_command_link
      @popup_link.link_only
    end

    # Returns a string for js to know how to sort the column correctly based on the config's data_type.
    def col_sort_type(col_config)
      case col_config[:data_type]
      when 'integer'
        'int'
      when 'number'
        'float'
      when 'date'
        'date'
      else
        nil
      end
    end

    # Returns an integer size for the column width based on the config's data_type.
    def col_width(col_config)
      if col_config[:col_width] || col_config[:column_width]
        col_config[:col_width] || col_config[:column_width]
      else
        if ['link_window', 'action', 'frame_link', 'action_collection'].include? col_config[:field_type]
          60
        else
          case col_config[:data_type]
          when 'integer'
            50
          when 'number'
            80
          when 'date'
            120
          when 'boolean'
            80
          else
            100
          end
        end
      end
    end

    # Create the js colModel as JSON
    def format_columns_for_js
      colnames       = []
      colmodel       = []
      cols_to_format = []
      unless @plugin.nil?
        cols_to_format = @plugin.cols_to_format || []
      end

      @column_configs.each_with_index do |col_config, index|
        next if col_config[:hide] # Hide column, but retain data in rows.

        if col_config[:column_caption].nil?
          colname = (col_config[:col_name] || col_config[:field_name]) # If dataset is empty, need to build cols from fld.
        else
          colname = col_config[:column_caption]
        end
        col             = {}
        col['name']       = colname
        col['field']      = col_config[:field_name]
        col['id']         = col_config[:field_name]
        col['sortable']   = true
        col['selectable'] = true
        col['cssClass']   = 'slk_cell_right_align' if ['integer', 'number'].include? col_config[:data_type]
        col['width']      = col_width(col_config)

        col['editor']     = 'text_editor'      if col_config[:editor] && :text      == col_config[:editor]
        col['editor']     = 'long_text_editor' if col_config[:editor] && :long_text == col_config[:editor]
        col['editor']     = 'checkbox_editor'  if col_config[:editor] && :checkbox  == col_config[:editor]
        col['editor']     = 'date_editor'      if col_config[:editor] && :date      == col_config[:editor]
        col['editor']     = 'integer_editor'   if col_config[:editor] && :integer   == col_config[:editor]

        col['groupTotalsFormatter'] = 'sumTotalsFormatter' if @group_fields_to_sum.include?(col_config[:field_name])
        col['groupTotalsFormatter'] = 'cntTotalsFormatter' if @group_fields_to_count.include?(col_config[:field_name])
        col['groupTotalsFormatter'] = 'avgTotalsFormatter' if @group_fields_to_avg.include?(col_config[:field_name])
        col['groupTotalsFormatter'] = 'maxTotalsFormatter' if @group_fields_to_max.include?(col_config[:field_name])
        col['groupTotalsFormatter'] = 'minTotalsFormatter' if @group_fields_to_min.include?(col_config[:field_name])

        col['formatter']  = col_config[:format] unless col_config[:format].nil?
        # Check if a plugin has implemented a cell formatter for this field.
        col['formatter']  = 'text' if cols_to_format.include?(col_config[:field_name])

        if 'action' == col_config[:field_type]
          col['formatter']  = 'link'
          col['cssClass']   = 'slk_cell_centre_align'
          col['unfiltered'] = true
          col['sortable']   = false
          col['dynlink']    = true if col_config[:settings] && !col_config[:settings][:dynamic_link_text].nil? && col_config[:settings][:image].blank?
        end
        if 'link_window' == col_config[:field_type]
          col['formatter']  = 'link_window'
          col['cssClass']   = 'slk_cell_centre_align'
          col['unfiltered'] = true
          col['sortable']   = false
          col['dynlink']    = true if col_config[:settings] && col_config[:settings][:link_text].blank? && col_config[:settings][:image].blank?
        end
        if 'action_collection' == col_config[:field_type]
          col['formatter']  = 'action_collection'
          col['cssClass']   = 'slk_cell_centre_align'
          col['unfiltered'] = true
          col['sortable']   = false
        end
        if 'boolean' == col_config[:data_type]
          col['cssClass']  = 'slk_cell_centre_align'
          col['formatter'] = 'bool' #'SlickBooleanFormatter'
        end

        colmodel << col
      end
      @colmodel = colmodel.to_json
    end

    # Returns an ApplicationHelper::LinkWindowField from generate_command in a div.
    def build_prefix
      @has_popup_link ? "<div>#{generate_command}</div>" : ''
    end

    # Export to CSV uses a different action depending on the value of
    # +se_grid_type+.
    def build_csv_export_action
      case @env.se_grid_type
      when 'se_grid'
        'export_se_grid_to_csv'
      when 'se_summary_details_grid'
        'export_se_summary_details_grid_to_csv'
      else
        "export_grid_to_csv"
      end
    end

    # Helpers can set the min height of the grid.
    # The values are for a legacy grid, so adapt the value to this grid's requirements.
    def calculate_grid_height
      if @height.nil?
        if @env.grid_min_height.to_i < 350
          @env.grid_min_height.to_i - 40
        else
          350
        end
      else
        @height
      end
    end

    # Returns javascript for an empty array when the dataset is empty.
    def build_empty_row
      "var #{@grid_id}data = [];"
    end

    # Returns javascript array of data rows.
    def build_rows
      row_text  = "var #{@grid_id}data = "
      rows      = []
      row_nr    = 0
      sel_rows  = (@env.grid_selected_rows || []).map { |selected_row| selected_row.id } if @multi_select
      int_cols  = @column_configs.select {|c| c[:data_type] && c[:data_type] == 'integer' }.map {|r| r[:field_name]}
      num_cols  = @column_configs.select {|c| c[:data_type] && c[:data_type] == 'number' }.map {|r| r[:field_name]}
      bool_cols = @column_configs.select {|c| c[:data_type] && c[:data_type] == 'boolean' }.map {|r| r[:field_name]}

      cols_to_format = []
      unless @plugin.nil?
        cols_to_format = @plugin.cols_to_format || []
      end

      @data_set.each do |active_record|

        row  = {}
        row_nr += 1
        if @key_based_access
          row['id'] = row_nr if @no_id_field
        else
          if active_record.respond_to? 'id'
            row['id'] = active_record.id
          else
            row['id'] = row_nr
          end
        end
        if @multi_select
          this_id = active_record['id']
          @pre_selected_ids << this_id if sel_rows.include?(this_id)      ||
                                          sel_rows.include?(this_id.to_i) ||
                                          sel_rows.include?(this_id.to_s)
          unless @non_selectable_ids.empty?
            row['not_multiselectable'] = @non_selectable_ids.any? {|a| a == this_id      ||
                                                                       a == this_id.to_i ||
                                                                       a == this_id.to_s } ? 'Y' : 'N'
          end
        end

        row_colour = ''
        if @plugin
          # Plugin row colouring:
          begin
            row_colour = @plugin.row_cell_colouring(active_record)
          rescue
            raise MesScada::Error, "DataGrid: A plugin styling method crashed when getting the row colour."
          end
        end

        row['row_colour'] = row_colour.blank? ? '' : "slick_row_#{row_colour}"

        col_formats = {}

        @grid_columns.each do |grid_column|
          if @plugin
            # Plugin cell content rendering:
            begin
              cell_value    = grid_column.render_cell(active_record, row_nr)
              rendered_cell = @plugin.render_cell(grid_column.field_name, cell_value, active_record)
            rescue
              raise MesScada::Error, "DataGrid: A plugin 'render_cell' method crashed: field is '#{grid_column.field_name}'."
            end

            # Plugin cell formatting:
            if cols_to_format.include?(grid_column.field_name)
              begin
                cell_fmt = @plugin.format_cell(grid_column.field_name, cell_value, active_record)
                case
                when cell_fmt.kind_of?(Symbol)
                  col_formats[grid_column.field_name] = "slick_cell_fmt_#{cell_fmt}" unless cell_fmt.blank?
                when cell_fmt.kind_of?(Array)
                  col_formats[grid_column.field_name] = cell_fmt.map {|a| "slick_cell_fmt_#{a}" }.join(' ') unless cell_fmt.empty?
                end
              rescue
                raise MesScada::Error, "DataGrid: A plugin 'format_cell' method crashed: field is '#{grid_column.field_name}'."
              end
            end
          else
            rendered_cell = grid_column.render_cell(active_record, row_nr)
          end

          rendered_cell = '' if rendered_cell.nil?
          if [Time, Date, DateTime].any? {|k| rendered_cell.kind_of?( k ) }
            row[grid_column.field_name] = rendered_cell.to_s
          elsif rendered_cell.blank?
            row[grid_column.field_name] = rendered_cell
          else # Change cells with integer/number data type from Strings so they sort correctly.
            if int_cols.include?(grid_column.field_name)
              row[grid_column.field_name] = rendered_cell.to_i
            elsif num_cols.include?(grid_column.field_name)
              begin
                row[grid_column.field_name] = Float(rendered_cell) # If field already formatted by plugin etc, then return String.
              rescue
                row[grid_column.field_name] = rendered_cell
              end
            elsif bool_cols.include?(grid_column.field_name)
              row[grid_column.field_name] = ['t','true','y','yes','0'].include?(rendered_cell) ? true : false
            else
              row[grid_column.field_name] = rendered_cell
            end
          end
        end
        row['cell_format_rules'] = col_formats.empty? ? '' : col_formats.inspect.gsub('=>', ': ')
        rows << row
      end
      @totcount = row_nr
      row_text << rows.to_json << ";"
    end

    private

    # Set a column's data type to number, date or text.
    def set_column_data_type(column_config)
      if column_config[:field_type]== "text"
        #use first row
        if @key_based_access
          attr = @data_set[0][column_config[:field_name]]
        else
          raise MesScada::InfoError, 'This grid should define KEY_BASED_ACCESS for a non-ActiveRecord dataset.' if @data_set[0].attributes.nil?
          attr = @data_set[0].attributes[column_config[:field_name]]
        end
        column_config[:data_type] = case attr.class.to_s.upcase
        when "FIXNUM"
          'integer'
        when "BIGDECIMAL", "FLOAT"
          'number'
        when "DATE", "TIMESTAMP", "DATETIME", "TIME"
          'date'
        else
          column_config[:data_type] || 'text'
        end
      else
        column_config[:data_type] = "text"
      end
    end

  end

  #-------------------------------------------------------------------------------------------------

  # Base class of all column types in the grid.
  class DataGridColumn

    attr_reader :field_name, :col_type

    # Create a column for a data grid.
    def initialize(grid, environment, column_config, active_record_prototype, field_name)

      @grid                    = grid
      @col_type                = 'text'
      @grid.is_popup           = nil unless @grid.is_popup
      @html_options            = column_config[:html_options]
      @env                     = environment
      @column_config           = column_config
      @active_record_prototype = active_record_prototype
      @field_name              = field_name
      @column_type             = column_config[:field_type]
    rescue
      raise MesScada::Error, "DataGrid: The datagrid column could not be created."
    end

    # Present the column definition as a string.
    def to_s
      "<DataGridColumn Field: #{@field_name}, Column_name: #{@column_config[:col_name]}, Column type: #{@column_type}, 1st row: #{@active_record_prototype.inspect}, Configs: #{@column_config.inspect}, HTML options: #{@html_options.inspect}>"
    end

    # Render the cell's value.
    def render_cell(active_record, row_nr)
      field_size = Globals.get_column_data_width || 150

      val = get_cell_value(active_record, row_nr)

      # Format dates and times consistently as variants of yyyy-mm-dd hh:mm.
      # Convert any other data type to string.
      if val.kind_of?(Date)
        val = val.strftime("%Y-%m-%d")
      elsif val.kind_of?(Time) || val.kind_of?(DateTime)
        if 0 == val.hour && 0 == val.min
          val = val.strftime("%Y-%m-%d")
        else
          val = val.strftime("%Y-%m-%d %H:%M")
        end
      else
        val = val.to_s
      end

      # If :truncate is true, shorten the field value if it is too long.
      if @column_config[:truncate] && val.length > field_size
        val = val.slice(0..field_size) + '...'
      end

      val = @env.escape_javascript(val)
      val
    rescue
      raise MesScada::Error, "render_cell failed."
    end

    # Get the cell value from the record hash.
    def get_cell_value_by_key(record, row_nr)
      record[@field_name]
    rescue
      raise MesScada::Error, "get_cell_value by key failed."
    end

    # Get the value of a cell from an ActiveRecord row or call get_cell_value_by_key to get it from a Hash.
    def get_cell_value(active_record, row_nr)
      if @grid.key_based_access
        get_cell_value_by_key(active_record, row_nr)
      else
        eval("active_record." + @field_name)
      end
    rescue NoMethodError
      if !@grid.key_based_access && @column_config[:use_outer_join]
        return ''
      else
        raise MesScada::Error, "get_cell_value failed."
      end
    rescue
      raise MesScada::Error, "get_cell_value failed."
    end

  end

  #-------------------------------------------------------------------------------------------------

  # Uses the default implementation of the superclass (DataGridSlick::DataGridColumn).
  class GridTextColumn < DataGridColumn; end

  #-------------------------------------------------------------------------------------------------

  # Renders a link to an action in a cell.
  class GridActionColumn < DataGridColumn

    def initialize(grid, environment, column_config, active_record_prototype, field_name)

      super(grid, environment, column_config, active_record_prototype, field_name)

      @col_type = 'action'
      @settings = @column_config[:settings]

      raise MesScada::InfoError, "The settings key is empty" if @settings.nil?
      if @settings[:link_text].nil? && @column_config[:field_name]== nil && @settings[:image].nil?
        raise MesScada::InfoError, "The 'link_text' setting is empty, as well as the 'image' settings, as well as the 'field_name' key. \n One of these need a value."
      end
      raise MesScada::InfoError, "The 'target_action' setting is empty" if @settings[:target_action].nil?
      raise MesScada::InfoError, "The 'id_column'setting is empty" if @settings[:id_column].nil?

      if @grid.key_based_access
        if !eval("active_record_prototype['#{@settings[:id_column]}']")
          if !@settings[:can_be_empty] && !eval("active_record_prototype['#{@field_name}']")
            raise MesScada::InfoError, "The dataset does not contain a column with name: #{@settings[:id_column]}\n (the id column specified) "
          end
        elsif @settings[:link_text].nil? && @settings[:image].nil?
          @settings[:dynamic_link_text] = true
          # add this setting for quick reference later on
          if !@settings[:can_be_empty] && !eval("active_record_prototype['#{@field_name}']")
            raise MesScada::InfoError, "The dataset does not contain a column with name: #{@field_name} (the 'field_name' setting)"
          end
        end
      else
        if not active_record_prototype.respond_to?(@settings[:id_column])
          raise MesScada::InfoError, "The dataset does not contain a column with name: #{@settings[:id_column]}\n (the id column specified) "
        elsif @settings[:link_text]== nil && !@settings[:image]
          @settings[:dynamic_link_text] = true
          # add this setting for quick reference later on
          if !@settings[:can_be_empty] && !active_record_prototype.respond_to?(@field_name)
            raise MesScada::InfoError, "The dataset does not contain a column with name: #{@field_name} (the 'field_name' setting)"
          end
        end
      end
    end

    def get_cell_value(active_record, row_nr)
      return get_cell_value_by_key(active_record, row_nr) if @grid.key_based_access

      return '' unless active_record.has_attribute?(@field_name)
      return '' if @settings[:can_be_empty] && eval("active_record.#{@field_name}").nil?
      return '' if @settings[:null_test]    && eval("active_record.#{@settings[:null_test]}")

      active_record.send(@field_name).to_s
    end

    def render_cell (active_record, row_nr)
      res = {}

      # Do the null test. If it is true, return an empty result.
      if @grid.key_based_access
        return res if @settings[:null_test] && eval("active_record" + @settings[:null_test])
      else
        return res if @settings[:null_test] && eval("active_record." + @settings[:null_test])
      end

      prompt = nil
      prompt = @html_options[:prompt] if @html_options && @html_options[:prompt]

      # Automatic confirmation prompt for delete/remove links
      #unless @settings[:html_options] && @settings[:html_options][:prompt]
      if prompt.nil?
        if (@settings[:link_text] && (@settings[:link_text] =~ /delete|remove/i)) ||
          (@settings[:image]     && (@settings[:image]     =~ /delete|remove/i))
          prompt = "Are you sure you want to delete/remove this record?"
        end
      end
      link_text = ''
      icon      = ''
      cell      = ''

      if @settings[:image]
        icon      = @settings[:image]
      elsif @settings[:dynamic_link_text].nil?
        link_text = @settings[:link_text]
      else
        if @grid.key_based_access
          link_text = eval("active_record['#{@field_name}']")
        else
          link_text = active_record.send(@field_name)
        end
      end

      controller = @env.request.path_parameters['controller'].to_s
      controller = @settings[:controller] if @settings[:controller]

      row_index = row_nr - 1
      options = {:controller => controller, :action => @settings[:target_action]}
      if @settings[:name_id_as_key]
        if @grid.key_based_access
          options.store(:key, eval("active_record['#{@settings[:id_column]}']"))
        else
          options.store(:key, active_record.send(@settings[:id_column]))
        end
      else
        if @grid.key_based_access
          options.store(:id, eval("active_record['#{@settings[:id_column]}']"))
        else
          options.store(:id, active_record.send(@settings[:id_column]))
        end
      end
      options.store(:id_value, @settings[:id_value]) if @settings[:id_value]

      css_class = ['action_link']
      @html_options[:class].split(' ').each {|c| css_class << c } if @html_options && @html_options[:class]

      html_opts = {:class => css_class.join(' ')}
      @html_options.each {|k,v| html_opts[k] = v unless [:class, :prompt].include?( k ) } if @html_options

      res['href'] = @env.url_for(options)
      res['cls']  = html_opts.delete(:class)
      res['opts'] = html_opts.nil? ? '' : '{' +html_opts.map {|k,v| "\"#{k}\": \"#{v}\"" }.join(', ') + '}' # map to strings...
      res['text'] = link_text || ''
      res['icon'] = icon
      res['prompt_text'] = prompt || ''
      res.inspect.gsub('=>', ': ')
    end

  end

  #-------------------------------------------------------------------------------------------------

  # Renders a link to a popup window in a cell.
  class LinkPopUpWindow < DataGridColumn

    def initialize(grid, environment, column_config, active_record_prototype, field_name)

      super(grid, environment, column_config, active_record_prototype, field_name)

      @col_type = 'link_window'

      environment.is_popup = true

      @column_config = column_config
      @grid.is_popup = true
      @settings      = @column_config[:settings]

      raise MesScada::InfoError, "The settings key is empty" if @settings.nil?
      raise MesScada::InfoError, "The 'field_name' setting is empty, as well as the 'field_name' key. \n " if @column_config[:field_name].nil?
      raise MesScada::InfoError, "The 'target_action' setting is empty" if @settings[:target_action].nil?

    rescue
      raise MesScada::Error, "The grid link_window column could not be created."
    end

    def get_cell_value(active_record, row_nr)
      nil
    end

    def render_cell(active_record, row_nr)
      res = {}

      # Do the null test. If it is true, return an empty result.
      if @grid.key_based_access
        return res if @settings[:null_test] && eval("active_record" + @settings[:null_test])
      else
        return res if @settings[:null_test] && eval("active_record." + @settings[:null_test])
      end

      if active_record.is_a? Hash
        id = active_record[@settings[:id_column]]
      else
        id = active_record.send @settings[:id_column]
      end
      target      = @settings[:target_action].to_s
      window_size = "!1000"
      window_size = "!#{@settings[:window_width]}" if @settings[:window_width]

      height = "500"
      height = @settings[:window_height].to_s if @settings[:window_height]
      window_size << ":#{height}!"


      if @settings[:host_and_port].nil?
        host_with_port = @env.request.host_with_port.to_s
      else
        host_with_port = @settings[:host_and_port]
      end

      if @settings[:controller].nil?
        controller = @env.request.path_parameters['controller'].to_s
      else
        controller = @settings[:controller]
      end

      text = @settings[:link_text]

      if (@settings[:image])
        icon = @settings[:image]
        text = ''
      else
        icon = ''
      end

      idp  = id.nil? ? '' : "%#{id}"
      if text.nil? && !id.nil?
        if @grid.key_based_access
          text = active_record[@field_name]
        else
          text = eval("active_record.#{@field_name}")
        end
      end

      res['href'] = "#{host_with_port}/#{controller}/#{target}#{idp}#{window_size}"
      res['text'] = text || ''
      res['icon'] = icon
      res.inspect.gsub('=>', ': ')
    end

  end

  # Renders a context menu list of links/texts/separators in a cell.
  class GridActionCollectionColumn < DataGridColumn

    COLLECTION_VALID_FIELD_TYPES = %w(text action link_window separator sub_menu)

    def initialize(grid, environment, column_config, active_record_prototype, field_name, plugin)

      column_config[:column_caption] = 'Actions' if column_config[:column_caption].nil?
      super(grid, environment, column_config, active_record_prototype, field_name)

      @plugin   = plugin
      @col_type = 'action_collection'

      raise MesScada::InfoError, "The settings key is empty for a GridActionCollectionColumn"       if @column_config[:settings].nil?
      raise MesScada::InfoError, "The settings key has no actions for a GridActionCollectionColumn" if @column_config[:settings][:actions].nil?
      @actions        = @column_config[:settings][:actions]
      @action_columns = []
      @actions.each do |action_config|
        action_config[:field_name] = action_config[:column_name] if action_config[:column_name]

        raise MesScada::InfoError, "DataGrid: The 'field_name' setting is empty" if action_config[:field_name].nil? && action_config[:field_type] != 'separator'
        raise MesScada::InfoError, "DataGrid: The 'field_type' setting for field: #{action_config[:field_type]} is empty" if action_config[:field_type].nil?

        action_config[:field_type] = action_config[:column_type] if action_config[:column_type]

        unless COLLECTION_VALID_FIELD_TYPES.include? action_config[:field_type]
          raise MesScada::InfoError, "DataGrid ActionCollection: The field type: #{action_config[:field_type]} is not valid. \n It must be '#{COLLECTION_VALID_FIELD_TYPES.join("' or '")}'."
        end

        grid_column =
          case action_config[:field_type]
          when "link_window"
            LinkPopUpWindow.new(grid, environment, action_config, active_record_prototype, action_config[:field_name])
          when "text"
            GridTextColumn.new(grid, environment, action_config, active_record_prototype, action_config[:field_name])
          when "action"
            GridActionColumn.new(grid, environment, action_config, active_record_prototype, action_config[:field_name])
          when "sub_menu"
            GridSubMenuColumn.new(grid, environment, action_config, active_record_prototype, action_config[:field_name])
          when 'separator'
            'separator'
          else
            nil
          end
        @action_columns << grid_column
      end

    end

    def get_cell_value (active_record, row_nr)
      nil
    end

    def render_cell (active_record, row_nr)
      rendered_actions = []
      @action_columns.each_with_index do |action, index|
        if action == 'separator'
          rendered_actions << {'type' => 'separator', 'body' => '"---"'} unless rendered_actions.empty?
          next
        end

        if @plugin
          # Plugin cell content rendering: NB! This should only be used to change text or href. (Classes etc don't apply)
          begin
            cell_value = action.render_cell(active_record, row_nr)
            link = @plugin.render_cell(@actions[index][:field_name], cell_value, active_record)
          rescue
            raise MesScada::Error, "DataGrid: A plugin 'render_cell' method crashed: field is '#{grid_column.field_name}'."
          end
        else
          link = action.render_cell(active_record, row_nr)
        end
        next if link.blank?
        if @actions[index][:settings] && @actions[index][:settings][:link_icon]
          link.sub!('"icon": ""', "\"icon\": \"#{@actions[index][:settings][:link_icon]}\"")
        end
        link = "\"#{link}\"" if @actions[index][:field_type] == 'text'
        rendered_actions << {'type' => action.col_type, 'body' => link}
        if @actions[index][:field_type] == 'sub_menu'
          rendered_actions.last['caption'] = action.menu_caption
        end
      end

      s = '['
      rendered_actions.each do |ra|
        if ra['type'] == 'sub_menu'
          s << "{\"type\": \"#{ra['type']}\",\"caption\":\"#{ra['caption']}\",\"body\":#{ra['body']}},"
        else
          s << "{\"type\": \"#{ra['type']}\",\"body\":#{ra['body']}},"
        end
      end
      s == '[' ? '' : s[0..-2] << ']'
    end

  end

  # Renders a submenu for an ActionCollection.
  class GridSubMenuColumn < DataGridColumn
    attr_reader :menu_caption

    COLLECTION_VALID_FIELD_TYPES = %w(text action link_window separator sub_menu)

    def initialize(grid, environment, column_config, active_record_prototype, field_name)

      column_config[:column_caption] = 'SubMenu' if column_config[:column_caption].nil?
      super(grid, environment, column_config, active_record_prototype, field_name)

      @menu_caption = column_config[:column_caption]
      @col_type     = 'sub_menu'

      raise MesScada::InfoError, "The settings key is empty for a GridSubMenuColumn" if @column_config[:settings].nil?
      raise MesScada::InfoError, "The settings key has no actions for a GridSubMenuColumn" if @column_config[:settings][:actions].nil?
      @actions        = @column_config[:settings][:actions]
      @action_columns = []
      @actions.each do |action_config|
        action_config[:field_name] = action_config[:column_name] if action_config[:column_name]

        raise MesScada::InfoError, "DataGrid: The 'field_name' setting is empty" if action_config[:field_name].nil? && action_config[:field_type] != 'separator'
        raise MesScada::InfoError, "DataGrid: The 'field_type' setting for field: #{action_config[:field_type]} is empty" if action_config[:field_type].nil?

        action_config[:field_type] = action_config[:column_type] if action_config[:column_type]

        unless COLLECTION_VALID_FIELD_TYPES.include? action_config[:field_type]
          raise MesScada::InfoError, "DataGrid ActionCollection: The field type: #{action_config[:field_type]} is not valid. \n It must be '#{COLLECTION_VALID_FIELD_TYPES.join("' or '")}'."
        end

        grid_column =
          case action_config[:field_type]
          when "link_window"
            LinkPopUpWindow.new(grid, environment, action_config, active_record_prototype, action_config[:field_name])
          when "text"
            GridTextColumn.new(grid, environment, action_config, active_record_prototype, action_config[:field_name])
          when "action"
            GridActionColumn.new(grid, environment, action_config, active_record_prototype, action_config[:field_name])
          when "sub_menu"
            GridSubMenuColumn.new(grid, environment, action_config, active_record_prototype, action_config[:field_name])
          when 'separator'
            'separator'
          else
            nil
          end
        @action_columns << grid_column
      end

    end

    def get_cell_value (active_record, row_nr)
      nil
    end

    def render_cell (active_record, row_nr)
      rendered_actions = []
      @action_columns.each_with_index do |action, index|
        if action == 'separator'
          rendered_actions << {'type' => 'separator', 'body' => '"---"'} unless rendered_actions.empty?
          next
        end

        if @plugin
          # Plugin cell content rendering: NB! This should only be used to change text or href. (Classes etc don't apply)
          begin
            cell_value = action.render_cell(active_record, row_nr)
            link = @plugin.render_cell(@actions[index][:field_name], cell_value, active_record)
          rescue
            raise MesScada::Error, "DataGrid: A plugin 'render_cell' method crashed: field is '#{grid_column.field_name}'."
          end
        else
          link = action.render_cell(active_record, row_nr)
        end
        next if link.blank?
        if @actions[index][:settings] && @actions[index][:settings][:link_icon]
          link.sub!('"icon": ""', "\"icon\": \"#{@actions[index][:settings][:link_icon]}\"")
        end
        link = "\"#{link}\"" if @actions[index][:field_type] == 'text' # .... to sub...
        rendered_actions << {'type' => action.col_type, 'body' => link}
        if @actions[index][:field_type] == 'sub_menu'
          rendered_actions.last['caption'] = action.menu_caption
        end
      end

      s = '['
      rendered_actions.each do |ra|
        s << "{\"type\": \"#{ra['type']}\",\"body\":#{ra['body']}},"
      end
      s[0..-2] << ']'
    end

  end

end
