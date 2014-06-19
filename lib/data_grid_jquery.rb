# == JQuery DataGrid
#
module DataGridJquery

  # == DataGrid for creating javascript grid.
  #
  # Example (controller):
  #   @grid         = DataGridJquery::DataGrid.new(self, data_set, column_configs, plugin, key_based_access, special_commands)
  #   @grid.caption = 'list of my report views'
  #   @grid.grid_id = 'grid_no_2'                # Optional. Required if there are two grids on the same page.
  #
  # Example (view):
  #   <head>
  #   ..
  #   <script>
  #     <%= @grid.build_grid_data %> <!-- Returns grid rows in an array -->
  #   </script>
  #   ..
  #   </head>
  #   <body>
  #   ..
  #   <%= @grid.render_html %>       <!-- Renders the table and pager div as html -->
  #   <%= @grid.render_grid %>       <!-- Renders the javascript creating the grid -->
  #   
  # Example (controller inline render calling a helper to build the grid):
  #   render :inline => %{
  #     <% grid            = build_qc_inspection_type_grid(@qc_inspection_types,@can_edit,@can_delete)%>
  #     <% grid.caption    = 'list of all qc_inspection_types' %>
  #     <% @header_content = grid.build_grid_data %>
  #
  #     <% @pagination = pagination_links(@qc_inspection_type_pages) if @qc_inspection_type_pages != nil %>
  #     <%= grid.render_html %>
  #     <%= grid.render_grid %>
  #   }, :layout => 'content'
  #
  # === Options:
  #
  # caption:: The grid caption.
  # grid_id:: The html tag id to uniquely identify the grid.
  #           You only need to supply this if you have more than one grid in the same page/iframe - otherwise the default +jqgridid+ will suffice.
  # grouped:: Boolean.
  #           Is the grid grouped by column(s)?
  #           Defaults to false.
  # group_fields:: Array of strings corresponding to column names.
  #                Grid will be grouped by these fields if +grouped+ is true.
  # group_collapsed:: Boolean.
  #                   Is the group collapsed or expanded?
  #                   Defaults to false (expanded).
  # groupable_fields:: Array of strings corresponding to column names.
  #                    If any fields are provided, a button becomes available on the grid allowing the user to group by one of these columns.
  # group_summary_depth:: At which levels should summarised footers appear? If 0, no footers will be shown. If 1, at level of first group field.
  #                       If 2, they will be shown at level of first 2 group fields and so on.
  # group_fields_to_sum:: An Array of column names. These columns will display the sum of the column in each footer.
  # group_fields_to_count:: An Array of column names. These columns will display the number of rows in the group in each footer.
  # group_fields_to_avg:: An Array of column names. These columns will display the average of the column in each footer.
  # group_fields_to_max:: An Array of column names. These columns will display the maximum of the column in each footer.
  # group_fields_to_min:: An Array of column names. These columns will display the minimum of the column in each footer.
  # fullpage:: Boolean.
  #            Should the grid use the full height of the page?
  #            Useful in a popup window. Defaults to false.
  # reload_url:: String. 
  #              If you provide a url the user will have a button to reload the grid which will send a request to the given url.
  # height:: The desired height of the grid in pixels.
  #          You should use this instead of calling +set_grid_min_height+.
  # group_headers_colspan:: Boolean.
  #                         Should the non-group headers span the two rows or not?
  #                         Defaults to false.
  #                         Only makes sense with +group_headers+ option.
  # group_headers:: Array of hashes.
  #                 Allows you to specify group headers that appear above sets of columns.
  #                 The hash requires the following hash keys:
  #                 +start_column_name+ (String, valid column name, left-most of the group),
  #                 +number_of_columns+ (Integer, number of columns to span),
  #                 +title_text+ (String, the caption for the group of columns).
  # no_of_frozen_cols:: Integer.
  #                     The first n columns will be frozen. i.e. they remain in place during horizontal scrolling.
  #                     Defaults to 0.
  #                     NB. If a grid has frozen columns, columns cannot be dragged and dropped into a different sequence.
  #
  # Example (in a helper which calls +get_data_grid+):
  #     group_headers = [{:start_column_name => 'report_name', :number_of_columns => 3, :title_text => 'Report'},
  #                      {:start_column_name => 'fieldlist', :number_of_columns => 2, :title_text => 'Technical stuff'}]
  #
  #     get_data_grid(data_set, column_configs, nil, nil, nil, {:group_headers => group_headers,
  #                                                             :caption => 'Some new grid caption',
  #                                                             :height => 350,
  #                                                             :groupable_fields => ['report_name', 'code', 'ranking']})
  #
  # Or creating the grid directly:
  #     group_headers = [{:start_column_name => 'report_name', :number_of_columns => 3, :title_text => 'Report'},
  #                      {:start_column_name => 'fieldlist', :number_of_columns => 2, :title_text => 'Technical stuff'}]
  #     DataGridJquery::DataGrid.new(self, data_set, column_configs, plugin, key_based_access, special_commands, {:group_headers => group_headers,
  #                                                             :caption => 'Some new grid caption',
  #                                                             :height => 350,
  #                                                             :groupable_fields => ['report_name', 'code', 'ranking']})
  #
  # The same thing can be achieved by setting attributes after creating the grid (example from a controller):
  #
  #     <% grid                  = build_qc_inspection_type_grid(@qc_inspection_types,@can_edit,@can_delete)%>
  #     <% grid.group_headers    = [{:start_column_name => 'report_name', :number_of_columns => 3, :title_text => 'Report'},
  #                                 {:start_column_name => 'fieldlist', :number_of_columns => 2, :title_text => 'Technical stuff'}] %>
  #     <% grid.caption          = 'Some new grid caption' %>
  #     <% grid.height           = 350 %>
  #     <% grid.groupable_fields = ['report_name', 'code', 'ranking'] %>
  #
  # === ColumnConfig settings to note
  #
  # The following ColumnConfig settings have notable features in the grid:
  #
  # field_name:: The name of the field to be used to populate the column.
  # column_caption:: The caption for the column. Optional, if not provided the +field_name+ is used.
  # col_width/column_width:: Width in pixels for the column. Optional.
  # data_type:: The data type of the column. Optional, but useful for sorting. Useful values are 
  #             +integer+, +number+, +date+ and +boolean+.
  #             For a +boolean+ column the grid will display a checked or unchecked image
  #             centred in a narrow column.
  #
  class DataGrid
    attr_reader :stack_trace, :key_based_access,  :group_summary_depth
    attr_accessor :is_popup, :caption, :grid_id, :grouped, :group_fields, :group_collapsed,
                  :fullpage, :reload_url, :groupable_fields, :height, :group_headers,
                  :group_headers_colspan, :no_of_frozen_cols,
                  :group_fields_to_sum, :group_fields_to_count, :group_fields_to_avg,
                  :group_fields_to_max, :group_fields_to_min

    VALID_FIELD_TYPES = %w(text action checkbox frame_link link_window)
    DEFAULT_CAPTION   = 'The Grid'

# description: This helper class builds a datagrid for a collection of active records
# column_configs:     an ordered (user-defined) list of column objects that defines the columns for the grid.
#             properties for each column are:
#			  key: 'field_name' value: the name of the active record dataset field to bind the column to
#             key: 'field_type'
#             value: the type of column, can be 'text' or 'image' or 'action'
#			  key: 'column_caption' value: the display caption of the column
#             key: settings (a map of field_type specific settings)
#             if field_type is:
#                     'action':
#                        key: 'link_text' value: the link display text
#                            note: this column is used if the display text must be the same for every link
#                                  in this case, the 'field_name' value should be left empty
#                                  to use dynamic text, the 'field_name' should contain a value and
#                                  'link_text' should be empty
#                        key: 'id_field' value: the name of the id column to use to retrieve an id value to
#                                         pass into the request string
#     					 key: 'target_action' value: the target action to link to
#-------------------------------------------------------------------------------------------------------



    # This constructor does extensive error checking to ensure that all
    # passed-in configuration objects for each column contain complete and
    # correct information.
    #
    # environment::      ApplicationHelper.
    # data_set::         ActiveRecord set or Array of hashes.
    # column_configs::   Configuration for grid columns.
    # plugin::           Optional GridPlugin.
    # key_based_access:: If true, the dataset is accessed as a Hash.
    # special_commands:: Settings for building a popup link to appear with the grid.
    # options::          All the attr_accessor attributes can be set via the options.
    def initialize(environment, data_set, column_configs, plugin = nil, key_based_access = nil, special_commands = nil, options={})

      @env                   = environment
      @stack_trace           = ''
      @multi_select          = @env.multi_select.blank? ? false : true
      @multi_select_action   = @env.url_for(:action => @env.multi_select) if @multi_select
      @key_based_access      = key_based_access
      @hidden_id_column      = @env.hidden_id_column
      @special_commands      = special_commands

      @grid_id               = options[:grid_id]               || 'jqgridid'
      @caption               = options[:caption]               || DEFAULT_CAPTION
      @grouped               = options[:grouped]               || false
      @group_collapsed       = options[:group_collapsed]       || false
      @group_fields          = options[:group_fields]          || []
      @groupable_fields      = options[:groupable_fields]      || []
      @group_headers         = options[:group_headers]         || []
      @group_headers_colspan = options[:group_headers_colspan] || false
      @fullpage              = options[:fullpage]              || false
      @reload_url            = options[:reload_url]            || nil
      @height                = options[:height]                || nil
      @no_of_frozen_cols     = options[:no_of_frozen_cols]     || 0
      @group_summary_depth   = options[:group_summary_depth]   || 1
      @group_fields_to_sum   = options[:group_fields_to_sum]   || []
      @group_fields_to_count = options[:group_fields_to_count] || []
      @group_fields_to_avg   = options[:group_fields_to_avg]   || []
      @group_fields_to_max   = options[:group_fields_to_max]   || []
      @group_fields_to_min   = options[:group_fields_to_min]   || []

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
        @column_configs = column_configs
        @data_set       = data_set

        if data_set.length > 0
          @empty        = false
          @grid_columns = []

          @column_configs.each do |column_config|
            #create the correct column type and add to collection

            # Make the field name the same as the column name if there is a column name.
            column_config[:field_name] = column_config[:column_name] if column_config[:column_name]

            raise MesScada::InfoError, "DataGrid: The 'field_name' setting is empty" if column_config[:field_name].nil?
            raise MesScada::InfoError, "DataGrid: The 'field_type' setting for field: #{column_config[:field_type]} is empty" if column_config[:field_type].nil?
           
            column_config[:field_type] = column_config[:column_type] if column_config[:column_type]

            unless VALID_FIELD_TYPES.include? column_config[:field_type]
              raise MesScada::InfoError, "DataGrid: The field type: #{column_config[:field_type]} is not valid. \n It must be '#{VALID_FIELD_TYPES.join("' or '")}'."
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
                GridFrameLinkColumn.new(self, environment, column_config, @data_set[0], column_config[:field_name])
              when "checkbox"
                GridCheckBoxColumn.new(self, environment, column_config, @data_set[0], column_config[:field_name])
              else
                nil
              end

              @grid_columns.push grid_column

          end
        end

        @has_popup_link = !@special_commands.nil?
        if @has_popup_link
          @popup_link = generate_popup_link(@special_commands)
        end

    end

    def group_summary_depth=(val)
      @group_summary_depth = val.to_i
      @group_summary_depth = 0 if @group_summary_depth.nil?
    end

    # Render the html table to which the grid is attached.
    def render_html
      #TODO: show prefx here if text is image, not words...
        prefix = '' #build_prefix
      # REQUIRES: .ui-jqgrid tr.ui-row-ltr td { font-size: 11px } AND .ui-jqgrid .ui-jqgrid-htable th div { font-size: 12px }
      %Q|#{prefix}<table id="#{@grid_id}"></table><div id="#{@grid_id}pager"></div>|
    end

    # Javascript code defining the jqGrid.
    def render_grid

      # scrub quotes from the caption:
      @caption = @caption.gsub(/"|'/,'') if @caption

      @env.is_popup = @is_popup #reset value stored in session

      grid_height       = calculate_grid_height
      export_method     = build_csv_export_action
      has_group_headers = build_group_headers

      format_columns_for_js

      %Q[
        <script type="text/javascript">
        jQuery(document).ready(function () {
        var mygrid = jQuery("##{@grid_id}");

        // For Multiselect, On click of checkbox, persist the state.
        jQuery('##{@grid_id}_frozen [aria-describedby="#{@grid_id}_cm"] > input').live('click', function(e) {
          var checkstate = jQuery(e.target).prop('checked');
          var setstate   = checkstate ? 1 : 0;
          var target     = jQuery(e.target)
          var currId     = target.parents('tr').prop('id');
          target.parents('tr').toggleClass('grid_checked_row');
          jQuery('##{@grid_id} tr#' + currId).toggleClass('grid_checked_row');
          mygrid.jqGrid('setCell', currId, 'cm', setstate, '', '', false);
        });

         mygrid.jqGrid({
           data: #{@grid_id}data,
           datatype: "local",
           colNames:[#{@colnames}],
           colModel:#{@colmodel},
           caption: "#{@caption}",
           pager: '##{@grid_id}pager',
           shrinkToFit: false,
           pginput: false,
           pgbuttons: false,
           rowNum: #{Globals.search_engine_max_rows},
           viewrecords: true,
           gridview: true,
           headertitles: true,
           height: #{grid_height},
           ignoreCase: true,
          #{if !@multi_select && @no_of_frozen_cols == 0
           "sortable: true,"
            end}
           deselectAfterSort: false,
           loadonce: true,
           grouping: #{@grouped.to_s},
           groupingView: {#{if @grouped then "groupField:['#{@group_fields.join("','")}']," end}
             groupText: ['<b>{0}</b> ({1})'],
             groupSummary : [#{(['true'] * @group_summary_depth).join(',')}],
             groupColumnShow: [false]#{if @grouped then ",
             groupCollapse: #{@group_collapsed.to_s}" end}
           },
           rownumbers: #{!@grouped && @groupable_fields.empty? ? "true" : "false"},
           gridComplete: function() {
             // Remove the centre part of the pager as it is not used so there's more space for buttons on the left.
             jQuery('##{@grid_id}pager_center').remove();
             // Remove style:table_layout:fixed from row table inside the pager.
             // - Makes left and right parts of pager size their widths according to their contents.
             // - NB. This could easily fail on upgrade of jqGrid in future.
             jQuery('##{@grid_id}pager table[role=\"row\"]').css('table-layout', '');
             #{if @multi_select || @no_of_frozen_cols > 0
              "mygrid.jqGrid('setFrozenColumns');"
              end}
           },
           loadComplete: function() {
              var iCol = 1,
                  cRows = this.rows.length, iRow, row, className;

              for (iRow=0; iRow<cRows; iRow++) {
                  row = this.rows[iRow];
                  className = row.className;
                  if (jQuery.inArray('jqgrow', className.split(' ')) > 0) {
                      var x = jQuery(row.cells[iCol]).children("input:checked");
                      if (x.length>0) {
                          if (jQuery.inArray('grid_checked_row', className.split(' ')) === -1) {
                              row.className = className + ' grid_checked_row';
                          }
                      }
                  }
              }
          }
        });

        // Pager with multiple search.
        mygrid.jqGrid('navGrid','##{@grid_id}pager',
          {edit: false, add: false, del: false, refresh: false, searchtext: '', view: true}, //options
          {}, // edit options
          {}, // add options
          {}, // del options
          {multipleSearch : true, sopt:['eq','ne','lt','le','gt','ge','bw','bn','ew','en','cn','nc']}, // search options
          {zIndex: 1200}  // view options
        );

        // Buttons for pager:
        mygrid.jqGrid('navButtonAdd','##{@grid_id}pager',{
            caption:       "",
            buttonicon:    "ui-icon-transferthick-e-w",
            title:         "Reorder Columns",
            onClickButton: function (){
              jQuery("##{@grid_id}").jqGrid('columnChooser');
            }
        }).jqGrid('navSeparatorAdd','##{@grid_id}pager',{}
         )#{unless @empty
           ".jqGrid('navButtonAdd','##{@grid_id}pager',{
            caption:       \"\",
            buttonicon:    \"ui-icon-document\",
            title:         \"Export grid to CSV\",
            onClickButton: function (){
              window.location.assign(\"/development_tools/data/#{export_method}\");
            }
        })"
        end}
        #{unless @groupable_fields.empty?
         ".jqGrid('navButtonAdd','##{@grid_id}pager',{
            caption:       '',
            buttonicon:    \"ui-icon-shuffle\",
            title:         \"Select a group\",
            onClickButton: function (){
              var group_fields = ['#{@groupable_fields.join("','")}'];
              jq_grid_select_grouping('#{@grid_id}', group_fields);
            }
        })"
          end}
        #{if @grouped
         ".jqGrid('navButtonAdd','##{@grid_id}pager',{
            caption:       '',
            buttonicon:    \"ui-icon-arrow-4-diag\",
            title:         \"Toggle group expand/collapse\",
            onClickButton: function (){
              jQuery('.jqgroup', '##{@grid_id}').each(function(r,e) {mygrid.jqGrid('groupingToggle', e.id)})
            }
        })"
          end}
        #{unless @reload_url.nil? || @reload_url.blank?
         ".jqGrid('navButtonAdd','##{@grid_id}pager',{
            caption:       '',
            buttonicon:    \"ui-icon-refresh\",
            title:         \"Reload grid\",
            onClickButton: function (){
              window.location.href = '#{@reload_url}';
              //open_window_link('#{@reload_url}')
            }
        })"
        end}
        ;
        if (top.frames.length > 0) {
          mygrid.jqGrid('navButtonAdd','##{@grid_id}pager',{
              caption:       "",
              buttonicon:    "ui-icon-zoomin",
              title:         "Zoom in or out of full page size",
              id:            '#{@grid_id}zoom',
              onClickButton: function (){
                var cf = jQuery('#contentFrame', top.document);
                var isSub = ('contentFrame' !== self.name);
                var sf = null;
                if(isSub) {sf = jQuery('#'+self.name, top.frames[1].document);}
                if(jQuery(cf).hasClass('zoomout')) {
                  jQuery(cf).removeClass('zoomout');
                  if(isSub) {jQuery(sf).removeClass('zoomoutsub'); }
                  jQuery('#jqgridminimize').css('visibility', 'hidden');
                }
                else {
                  jQuery(cf).addClass('zoomout');
                  if(isSub) {jQuery(sf).addClass('zoomoutsub'); }
                  jQuery('#jqgridminimize').css('visibility', 'visible');
                }
              }
          });
        }
        #{if @multi_select
          "mygrid.jqGrid('navSeparatorAdd','##{@grid_id}pager',{}
          ).jqGrid('navButtonAdd','##{@grid_id}pager',{
            caption:       \"\",
            buttonicon:    \"ui-icon-disk\",
            title:         \"Save selection\",
            onClickButton: function (){
              var s = jQuery('##{@grid_id} [aria-describedby=\"#{@grid_id}_cm\"] > input:checked');
              if(s.length == 0) {
                alert(\"You have not selected any items to submit!\");
              }
              else {
                if(confirm('Are you sure you want to submit this selection?(' + s.length.toString() + ' items)')) {
                  var ids = [];
                  s.each(function(i, elem) {
                    var currId = jQuery(elem).parents('tr').prop('id');
                    ids.push( currId );
                  });          
                  var newform = jQuery( document.createElement('form') );
                  newform.attr('method', 'post')
                         .attr('action', '#{@multi_select_action}')
                         .append('<input type=\"hidden\" name=\"selection[list]\" value=\"['+ids.join(',')+']\" />')
                         .appendTo('body') // Required for Firefox to work.
                         .submit();
                }
              }
            }
        });"
        end}
        #{if @has_popup_link
          "mygrid.jqGrid('navSeparatorAdd','##{@grid_id}pager',{}
          ).jqGrid('navButtonAdd','##{@grid_id}pager',{
            caption:       \"#{generate_command_link_text}\", //NB caption can cause problems for display if too long...
            //caption:       \"\",
            buttonicon:    \"ui-icon-newwin\",
            title:         \"#{generate_command_link_text}\",
            onClickButton: function (){
              #{generate_command_link};
            }
        });"
        end}

        // Make the grid resizable with a grip at bottom right.
        #{ if !@fullpage
          "mygrid.jqGrid('gridResize');"
          end}

        #{if has_group_headers
          "mygrid.jqGrid('setGroupHeaders', {
            useColSpanStyle: #{@group_headers_colspan},
            groupHeaders: #{@group_headers_json}
          });"
          end}

        jQuery(window).bind('resize', function() {
            mygrid.jqGrid('setGridWidth', jQuery(window).width()-20);
        #{ if @fullpage
            "mygrid.jqGrid('setGridHeight', jQuery(window).height()-130);"
          end}
        }).trigger('resize');

        #{unless @empty
        "// setup grid print capability. Add print button to navigation bar and bind to click.
        setPrintGrid('#{@grid_id}','#{@grid_id}pager','#{@caption}');"
        end }

      });
      </script>]
    end

    # Return the grid data within html +script+ tags.
    def build_grid_data
      if @empty
        "<script type=\"text/javascript\">#{build_empty_row}</script>"
      else
        #'<script type="text/javascript">' << build_columns << build_rows << '</script>'
        "<script type=\"text/javascript\">#{build_rows}</script>"
      end
    end

  protected

    # Create a popup_link (ApplicationHelper::LinkWindowField) from settings in +sepcial_commands+.
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
        if ['link_window', 'action', 'frame_link'].include? col_config[:field_type]
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
            50
          else
            100
          end
        end
      end
    end

    # Create the js colModel as JSON
    def format_columns_for_js
      colnames = []
      colmodel = []

      # The "cm" column holds a checkbox for multiselect rows.
      if @multi_select
        colnames << %Q|<input type="checkbox" onclick="checkJqGridBoxes(event, &quot;#{@grid_id}&quot;)" />|
        col                  = {}
        col['name']          = 'cm'
        col['index']         = 'cm'
        col['width']         = 30
        col['search']        = false
        col['sortable']      = false
        col['frozen']        = true
        col['align']         = 'center'
        col['formatter']     = 'checkbox'
        col['formatoptions'] = {'disabled' => false }
        col['edittype']      = 'checkbox'
        col['editoptions']   = {'value' => '1:0' }
        colmodel << col
      end

      @column_configs.each_with_index do |col_config, index|
        if col_config[:column_caption].nil?
          colnames << (col_config[:col_name] || col_config[:field_name]) # If dataset is empty, need to build cols from fld.
        else
          colnames << col_config[:column_caption]
        end
        col             = {}
        col['name']     = col_config[:field_name]
        col['index']    = col_config[:field_name]
        col['width']    = col_width(col_config)
        sorttype        = col_sort_type(col_config)
        col['sorttype'] = sorttype unless sorttype.nil?
        col['align']    = 'right' if ['integer', 'number'].include? col_config[:data_type]

        if 'boolean' == col_config[:data_type]
          col['align']     = 'center'
          col['formatter'] = 'checkbox'
        end

        # Rules for summarising columns:
        col['summaryType'] = 'sum' if @group_fields_to_sum.include? col_config[:field_name]
        if @group_fields_to_count.include? col_config[:field_name]
          col['summaryType'] = 'count'
          col['summaryTpl']  = '<b>{0} Row(s)</b>'
        end
        if @group_fields_to_avg.include? col_config[:field_name]
          col['summaryType'] = 'avg'
          col['summaryTpl']  = '<b>Avg: {0}</b>'
        end
        if @group_fields_to_max.include? col_config[:field_name]
          col['summaryType'] = 'max'
          col['summaryTpl']  = '<b>Max: {0}</b>'
        end
        if @group_fields_to_min.include? col_config[:field_name]
          col['summaryType'] = 'min'
          col['summaryTpl']  = '<b>Min: {0}</b>'
        end

        # Don't sort or search links:
        if ['link_window', 'action', 'frame_link'].include? col_config[:field_type]
          col['align']    = 'center'
          col['search']   = false
          col['sortable'] = false
        end
        if index < @no_of_frozen_cols
          col['frozen'] = true
        end
        colmodel << col
      end
      @colnames = "'#{colnames.join("', '")}'"
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

    # Build the group headers as JSON array for use in the grid.
    def build_group_headers
      if @group_headers.empty?
        false
      else
        gh_for_json = []
        @group_headers.each do |group_header|
          gh_for_json << {'startColumnName' => group_header[:start_column_name] || group_header['start_column_name'],
                          'numberOfColumns' => group_header[:number_of_columns] || group_header['number_of_columns'],
                          'titleText' => group_header[:title_text] || group_header['title_text']
                         }
        end
        @group_headers_json = gh_for_json.to_json
        true
      end
    end

    # Returns javascript for an empty array when the dataset is empty.
    def build_empty_row
      "var #{@grid_id}data = [];"
    end

    # Returns javascript array of data rows.
    def build_rows
      row_text = "var #{@grid_id}data = "
      rows = []
      row_nr = 0
      sel_rows = (@env.grid_selected_rows || []).map { |selected_row| selected_row.id } if @multi_select
      boolean_cols = @column_configs.select {|c| c[:data_type] && c[:data_type] == 'boolean' }.map {|r| r[:field_name]}
      @data_set.each do |active_record|

        row  = {}
        row_nr += 1
        if @key_based_access
        else
          row['id'] = active_record.id if active_record.respond_to? 'id'
        end
        if @multi_select
          row['cm'] = sel_rows.include?(active_record.id) ? 1 : 0
        end

        @grid_columns.each do |grid_column|
          cell_value = grid_column.get_cell_value(active_record, row_nr)
          if @plugin
            begin
              pre_style = @plugin.before_cell_render_styling(grid_column.field_name,
                                                             cell_value,
                                                             active_record)
              post_style = @plugin.after_cell_render_styling(grid_column.field_name,
                                                             cell_value,
                                                             active_record)
            rescue
              raise MesScada::Error, "DataGrid: A plugin styling method crashed: field is '#{grid_column.field_name}'"
            end
          end

          pre_style  ||= ''
          post_style ||= ''
          if @plugin && @plugin.cancel_cell_rendering(grid_column.field_name,
                                                      cell_value,
                                                      active_record)
            begin
              rendered_cell = "#{pre_style}#{@plugin.render_cell(grid_column.field_name,
                                                              cell_value,
                                                              active_record)}#{post_style}"
            rescue
              raise MesScada::Error, "DataGrid: A plugin render_cell() method crashed: field is '#{grid_column.field_name}'."
            end

          else
            rendered_cell = "#{pre_style}#{grid_column.render_cell(active_record, row_nr)}#{post_style}"
          end

          # Alter any booleans represented by 't' or 'f' to something the jqGrid will understand.
          if boolean_cols.include? grid_column.field_name
            rendered_cell = '0' if rendered_cell == 'f'
            rendered_cell = '1' if rendered_cell == 't'
          end
          row[grid_column.field_name] = rendered_cell
        end
        rows << row
      end
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

# -----------------------------------------------------------------------------

  # Base class of all column types in the grid.
  class DataGridColumn

    attr_reader :field_name

    # Ensure the image name contains a file extension.
    def image_with_ext(image_name)
      image_name.include?('.') ? image_name : "#{image_name}.png"
    end

    # Create a column for a data grid.
    def initialize(grid, environment, column_config, active_record_prototype, field_name)

      @grid = grid

      begin
        @grid.is_popup           = nil unless @grid.is_popup # TODO: WHY????
        @html_options            = column_config[:html_options]

        @env                     = environment
        @column_config           = column_config
        @active_record_prototype = active_record_prototype
        @field_name              = field_name
        @column_type             = column_config[:field_type]

      rescue
        raise MesScada::Error, "DataGrid: The datagrid column could not be created."
      end
    end

    # Present the column definition as a string.
    def to_s
      "<DataGridColumn Field: #{@field_name}, Column_name: #{@column_config[:col_name]}, Column type: #{@column_type}, 1st row: #{@active_record_prototype.inspect}, Configs: #{@column_config.inspect}, HTML options: #{@html_options.inspect}>"
    end

    # Render the cell's value.
    def render_cell(active_record, row_nr)
      field_size = Globals.get_column_data_width || 150
      if @grid.key_based_access
        val = active_record[@field_name]
      else
        begin
          val =  eval("active_record." + @field_name)
        rescue NoMethodError
          if !@grid.key_based_access && @column_config[:use_outer_join]
            val = ''
          else
            raise MesScada::Error, "get_cell_value failed."
          end
        end
      end

      if val && @column_config[:format]
        val = Globals.currency(@env, val) if 'currency_default' == @column_config[:format]
      end

      if val.class.to_s.upcase =~ /DATE|TIME/
        val = val.strftime("%Y-%b-%d %H:%M")
      else
        val = val.to_s
      end

      if val != '' && val.length > field_size
        session = @env.session
        session[:column_details] = Hash.new unless session[:column_details]
        id = @field_name + "!" + row_nr.to_s
        session[:column_details].store(id, val)
        rec = id
        val = val.to_s.slice(0..field_size) + '@@@'
      end

      val = @env.escape_javascript(val) if val
      val = '' unless val
      val.sub!('@@@', "<a href=\"#\" onclick=\"JavaScript:show_column_detail('" + rec.to_s + "');\">...</a>")
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
        result = get_cell_value_by_key(active_record, row_nr)
      else
        result =  eval("active_record." + @field_name)
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

  # Uses the default implementation of the superclass (DataGridJquery::DataGridColumn).
  class GridTextColumn < DataGridColumn; end

  # Deprecated. Currently not used.
  class GridCheckBoxColumn < DataGridColumn; end

  # Renders a link to a popup window in a cell.
  class LinkPopUpWindow < DataGridColumn

    def initialize(grid, environment, column_config, active_record_prototype, field_name)
      super(grid, environment, column_config, active_record_prototype, field_name)

      environment.is_popup = true

      @column_config = column_config
      @grid.is_popup = true
      begin
        if @column_config[:settings].nil?
          raise MesScada::InfoError, "The settings key is empty"
        else
          @settings = @column_config[:settings]

          if @column_config[:field_name].nil?
            raise MesScada::InfoError, "The 'field_name' setting is empty, as well as the 'field_name' key. \n "
          elsif @column_config[:settings][:target_action].nil?
            raise MesScada::InfoError, "The 'target_action' setting is empty"
          end
        end

      rescue
        raise MesScada::Error, "The grid link_window column could not be created."
      end
    end

    def get_cell_value (active_record, row_nr)
      nil
    end

    def render_cell (active_record, row_nr)

      if @grid.key_based_access
        return '' if @settings[:null_test] && eval("active_record" + @settings[:null_test])
      else
        return '' if @settings[:null_test] && eval("active_record." + @settings[:null_test])
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


      if @column_config[:settings][:host_and_port].nil?
        host_with_port = @env.request.host_with_port.to_s
      else
        host_with_port = @column_config[:settings][:host_and_port]
      end

      if @column_config[:settings][:controller].nil?
        controller = @env.request.path_parameters['controller'].to_s
      else
        controller = @column_config[:settings][:controller]
      end

      if (@settings[:image])
        @settings[:link_text] = @env.image_tag(image_with_ext(@settings[:image]), :border => 0)
      end

      text = @settings[:link_text]
      idp  = id.nil? ? '' : "%#{id}"
      if text.nil? && !id.nil?
        if @grid.key_based_access
          text = active_record[@field_name]
        else
          #text = active_record.send @field_name
          text = eval("active_record.#{@field_name}")
        end
      end

      "<a style='text-decoration: underline;' id='#{host_with_port}/#{controller}/#{target}#{idp}#{window_size}' href='javascript:nothing();' onclick='javascript:parent.call_open_window(this);' >#{text}</a>"
    end

  end

  # Renders a link to a frame in a cell.
  class GridFrameLinkColumn < DataGridColumn

    def get_cell_value (active_record, row_nr)
      nil
    end

    def render_cell (active_record, row_nr)

      begin
        if active_record.nil?
          id = nil
        else
          id = active_record.send(@column_config[:settings][:id_column]) || @settingd[:id_column]
        end
        target = @column_config[:settings][:target_action].to_s

        if @column_config[:settings][:controller].nil?
          controller = @env.request.path_parameters['controller'].to_s
        else
          controller = @column_config[:settings][:controller].to_s
        end

        if @column_config[:settings][:host_and_port].nil?
          host_with_port = @env.request.host_with_port
        else
          host_with_port = @column_config[:settings][:host_and_port]
        end

        frame_id = @column_config[:settings][:frame_id].to_s

        if @column_config[:settings][:image]
          @column_config[:settings][:link_text] =  @env.image_tag(image_with_ext(@column_config[:settings][:image]), :border => 0)
        end

        if @column_config[:settings][:link_text].nil?
          #"<a style='text-decoration: underline;cursor:pointer;' onclick=javascript:top.setFrameSource('#{frame_id}','#{host_with_port}/#{controller}/#{target}/#{id}'); >#{active_record.send(@field_name)}</a>"
          "<a style='text-decoration: underline;cursor:pointer;' onclick=javascript:top.setFrameSource('#{frame_id}','#{host_with_port}/#{controller}/#{target}/#{id}'); >#{eval("active_record.#{@field_name}")}</a>"
        else
          "<a style='text-decoration: underline;cursor:pointer;' onclick=javascript:top.setFrameSource('#{frame_id}','#{host_with_port}/#{controller}/#{target}/#{id}'); >#{@column_config[:settings][:link_text]}</a>"
        end
      end
    rescue
      raise MesScada::Error, "The grid framelink could not build cell."
    end

  end

  # Renders a link to an action in a cell.
  class GridActionColumn < DataGridColumn

    def initialize(grid, environment, column_config, active_record_prototype, field_name)

      super(grid, environment, column_config, active_record_prototype, field_name)

        if @column_config[:settings] == nil
          raise MesScada::InfoError, "The settings key is empty"
        else
          @settings = @column_config[:settings]
          if @column_config[:settings][:link_text] == nil && @column_config[:field_name]== nil && @column_config[:settings][:image]== nil
            raise MesScada::InfoError, "The 'link_text' setting is empty, as well as the 'image' settings, as well as the 'field_name' key. \n One of these need a value."
          elsif @column_config[:settings][:target_action] == nil
            raise MesScada::InfoError, "The 'target_action' setting is empty"
          elsif @column_config[:settings][:id_column] == nil
            raise MesScada::InfoError, "The 'id_column'setting is empty"
          else
            if !@grid.key_based_access
              if not active_record_prototype.respond_to?(@column_config[:settings][:id_column])
                raise MesScada::InfoError, "The dataset does not contain a column with name: " + @column_config[:settings][:id_column] + "\n (the id column specified) "
              elsif @column_config[:settings][:link_text]== nil && !@column_config[:settings][:image]
                @column_config[:settings][:dynamic_link_text] = true
                # add this setting for quick reference later on
                if !@column_config[:settings][:can_be_empty] && !active_record_prototype.respond_to?(@field_name)
                  raise MesScada::InfoError, "The dataset does not contain a column with name: " + @field_name + " (the 'field_name' setting)"
                end
              end
            else
              if !eval("active_record_prototype['" + @column_config[:settings][:id_column] + "']")
                if !@column_config[:settings][:can_be_empty] && !eval("active_record_prototype['" + @field_name + "']")
                  raise MesScada::InfoError, "The dataset does not contain a column with name: " + @column_config[:settings][:id_column] + "\n (the id column specified) "
                end
              elsif @column_config[:settings][:link_text]== nil && !@column_config[:settings][:image]
                @column_config[:settings][:dynamic_link_text] = true
                # add this setting for quick reference later on
                if !@column_config[:settings][:can_be_empty] && !eval("active_record_prototype['" + @field_name + "']")
                  raise MesScada::InfoError, "The dataset does not contain a column with name: " + @field_name + " (the 'field_name' setting)"
                end
              end
            end
          end

        end

    end

    def get_cell_value(active_record, row_nr)
      if @grid.key_based_access
        return get_cell_value_by_key(active_record, row_nr)
      end

      #return '' unless active_record.respond_to?(@field_name)
      return '' unless active_record.has_attribute?(@field_name)
      return '' if @settings[:can_be_empty] && eval("active_record." + @field_name.to_s) == nil

      if @settings[:null_test]
        if eval("active_record." + @settings[:null_test])
          return ''
        end
      end

      return eval("active_record." + @field_name).to_s

    end

    def render_cell (active_record, row_nr)

      #---------------------------------------------------------------------------------------
      #do the null test : this is a piece of code that we need to evaluate against the current
      #record. if the eval returns true, we do not build the link
      #---------------------------------------------------------------------------------------

      if @settings[:null_test]
        if @grid.key_based_access
          if eval("active_record" + @settings[:null_test])
            return ''
          end
        else
          if eval("active_record." + @settings[:null_test])
            return ''
          end
        end
      end

      prompt = nil
      prompt = @html_options[:prompt] if @html_options && @html_options[:prompt]

      # Automatic confirmation prompt for delete/remove links
      unless @settings[:html_options] && @settings[:html_options][:prompt]
        if (@settings[:link_text] && (@settings[:link_text] =~ /delete|remove/)) ||
           (@settings[:image]     && (@settings[:image]     =~ /delete|remove/))
          prompt = "Are you sure you want to delete/remove this record?"
        end
      end
      link_text = nil
      cell      = ''

      if @settings[:image]
        link_text = @env.image_tag(image_with_ext(@settings[:image]), :size => "16x16", :border => 0)
      elsif @settings[:dynamic_link_text] == nil
        link_text = @settings[:link_text]
      else
        if @grid.key_based_access
          link_text = eval("active_record['" + @field_name.to_s + "']")
        else
#          link_text = eval("active_record." + @field_name.to_s) #active_record.attributes[@field_name].to_s
          link_text = active_record.send(@field_name)
        end
      end

      controller = @env.request.path_parameters['controller'].to_s
      controller = @settings[:controller] if @settings[:controller]

      onclick = "show_action_image_in_grid(this);"

      if prompt
        onclick = "if(!confirm(\"" + prompt + "\"))return false; else {show_action_image_in_grid(this);}"
      end
      row_index = row_nr - 1
      options = {:controller => controller, :action => @settings[:target_action]}
      if @grid.key_based_access
        options.store(:id, eval("active_record['" + @settings[:id_column] + "']"))
      else
        options.store(:id, eval("active_record." + @settings[:id_column]))        
      end
      options.store(:id_value, @settings[:id_value]) if @settings[:id_value]

      css_class = ['action_link']
      @html_options[:class].split(' ').each {|c| css_class << c } if @html_options && @html_options[:class]

      html_opts = {:class => css_class.join(' '), :onclick => onclick}
      @html_options.each {|k,v| html_opts[k] = v unless [:class, :prompt].include?( k ) } if @html_options

      cell = @env.link_to(link_text, options, html_opts)

      # FIXME: Hack to get around non-hide of animated gif
      if css_class.include? 'popupjs'
        cell += @env.content_tag(:span, '', :id => 'loading' + row_index.to_s, :style => 'display:none')
      else
        cell += @env.image_tag('loading.gif', :id => 'loading' + row_index.to_s, :align => 'absmiddle', :border => 0, :style => 'display:none')
      end

      cell.gsub! "\"", "'"

      cell
    end

  end

end
