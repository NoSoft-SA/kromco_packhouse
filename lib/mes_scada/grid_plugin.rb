module MesScada

  # == SlickGrid Plugin ancestor class
  #
  # Inheriting classes can override +render_cell+, +format_cell+ and
  # +row_cell_colouring+ methods if required.
  #
  # This class also implements helper functions for use in sub-classes.
  class GridPlugin

    # Populate this attribute with an array of field names that need formatting.
    # Then implement the +format_cell+ method and return format rules for the
    # relevant columns.
    attr_reader :cols_to_format

    # Change the contents of a cell.
    # If a new value is not returned, the original +cell_value+ must be returned.
    def render_cell(column_name, cell_value, record)
      cell_value
    end

    # Return a colour for text in the row.
    # Colour is returned as a symbol which matches the last part of a CSS class style
    # in <tt>public/stylesheets/grid_icons_n_colours.css</tt>.
    #
    # e.g. returning <tt>:red</tt> will lead to style +slick_row_red+ being applied to the row.
    #
    # Examples of valid colours to return:
    #   :black :blue :brown :green :gray :maroon :orange :purple :red :light_green :dark_green
    #
    # Implementing methods should examine values in the record and return +nil+ for no change
    # or one of the valid symbols.
    def row_cell_colouring(record)
      colour = nil
    end

    # Return one or more formats for a row.
    # Colour/Format is returned as a symbol (or list of symbols)
    # which match the last part of a CSS class style
    # in <tt>public/stylesheets/grid_icons_n_colours.css</tt>.
    #
    # e.g. returning <tt>:red</tt> will lead to style +slick_cell_fmt_red+ being applied to the cell.
    #
    # e.g. returning <tt>:red, :bold</tt> will lead to styles +slick_cell_fmt_red+ and +slick_cell_fmt_bold+ being applied to the cell.
    #
    # Examples of valid formats to return:
    #   :bold, :italic, :underline,
    #   :black :blue :brown :green :gray :maroon :orange :purple :red :light_green :dark_green
    #
    # Implementing methods should examine values in the record and return +nil+ for no change
    # or one of the valid symbols.
    def format_cell(column_name, cell_value, record)
      format = nil
    end

  private

    # ---------- HELPER FUNCTIONS --------------

    # Returns true if the given value is nil/falsy or is <tt>'f'</tt>.
    def falsy_check(val)
      !val | val == 'f'
    end

    # Returns true if the given value is not nil and is +true+ or <tt>'t'</tt>.
    def true_check(val)
      val && val == true || val == 't'
    end

    # Returns true if the given value is nil or an empty string.
    def blank_check(val)
      val.blank?
    end

    # Returns true if the given value is NOT nil AND NOT an empty string.
    def non_blank_check(val)
      !blank_check(val)
    end

    # Returns boolean.
    # Does case-insensitive string compare of test_value String to the array of fields.
    def any_upper_fields_match(record, fields, test_value)
      fields.any? {|f| record[f] && test_value.upcase == record[f].upcase }
    end

    # Returns boolean.
    # Does case-insensitive string compare of test_values array to the value of the field.
    def any_upper_values_match(record, field, test_values)
      test_values.any? {|v| record[field].upcase && v == record[field].upcase }
    end

    # Returns an action link for the grid.
    def make_action(href, link_text, options={})
      opts          = {:icon_name => '', :css_class => 'action_link', :prompt => ''}.merge( options )
      res           = {}
      res['href']   = href
      res['cls']    = opts[:css_class]
      res['text']   = link_text || ''
      res['icon']   = opts[:icon_name]
      res['prompt_text'] = opts[:prompt]
      res.inspect.gsub('=>', ': ')
    end

    # Returns a popup window link for the grid.
    def make_link_window(href, link_text, icon_name='')
      res         = {}
      #res['href'] = "#{host_with_port}/#{controller}/#{target}#{idp}#{window_size}"
      res['href'] = href.sub('http://', '')
      res['text'] = link_text || ''
      res['icon'] = icon_name
      res.inspect.gsub('=>', ': ')
    end
  end

end
