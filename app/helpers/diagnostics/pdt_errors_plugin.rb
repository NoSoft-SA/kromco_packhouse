require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module PdtPlugins

class PdtLogsPlugin < ApplicationHelper::GridPlugin
  def initialize(menu_items_friendly_names)
    @menu_items_friendly_names = menu_items_friendly_names
  end

  #---------------------------------------------------------------
  #This method allows the grid-client code to cancel the rendering
  #of a given cell
  #---------------------------------------------------------------
  def cancel_cell_rendering(column_name,cell_value,record)
    if column_name == "menu_item"
      return true
    end
    return false
  end

  #-------------------------------------------------------------------
  #This method allows a plugin to render the cell instead of the
  #grid column. To work, the same plugin must also implmement the
  #'cancel_cell_rendering' method and return true.
  #-------------------------------------------------------------------
  def render_cell(column_name,cell_value,record)
    return cell_value +  "[#{@menu_items_friendly_names[record[:menu_item]]}]"
  end
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this method
      #---------------------------------------------------------------
 def before_cell_render_styling(column_name,cell_value,record)
        @strong_on = false
        style = ""

        record.user_name = "" if ! record.user_name

        if record.user_name.upcase == "HANS"
        style = "<font color = 'blue'>"

        elsif record.user_name.upcase == "MES"
        style =  "<font color = 'green'>"

        elsif record.user_name.upcase == "DERRICKW"
        style =  "<font color = 'purple'>"

        elsif record.user_name.upcase == "GERT"
        style =  "<font color = 'yellow'>"

        else
          style =  "<font color = 'red'>"
        end

        if column_name == "user_name"
          @strong_on = true
          style += "<strong>"
        end




        return style
      end
      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        if @strong_on
         "</strong></font>"
        else
          "</font>"
        end

      end
end

class PdtErrorsPlugin < ApplicationHelper::GridPlugin
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this method
      #---------------------------------------------------------------
 def before_cell_render_styling(column_name,cell_value,record)
        @strong_on = false
        style = ""

        record.user_name = "" if ! record.user_name

        if record.user_name.upcase == "HANS"
        style = "<font color = 'blue'>"

        elsif record.user_name.upcase == "MES"
        style =  "<font color = 'green'>"

        elsif record.user_name.upcase == "DERRICKW"
        style =  "<font color = 'purple'>"

        elsif record.user_name.upcase == "GERT"
        style =  "<font color = 'yellow'>"

        else
          style =  "<font color = 'red'>"
        end

        if column_name == "user_name"
          @strong_on = true
          style += "<strong>"
        end




        return style
      end
      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        if @strong_on
         "</strong></font>"
        else
          "</font>"
        end

      end
end

  class PdtLastTenLogsPlugin < ApplicationHelper::GridPlugin
    def initialize(menu_items_friendly_names)
      @menu_items_friendly_names = menu_items_friendly_names
    end

    #---------------------------------------------------------------
    #This method allows the grid-client code to cancel the rendering
    #of a given cell
    #---------------------------------------------------------------
    def cancel_cell_rendering(column_name,cell_value,record)
      if column_name == "menu_item"
        return true
      end
      return false
    end

    #-------------------------------------------------------------------
    #This method allows a plugin to render the cell instead of the
    #grid column. To work, the same plugin must also implmement the
    #'cancel_cell_rendering' method and return true.
    #-------------------------------------------------------------------
    def render_cell(column_name,cell_value,record)
      return cell_value +  "[#{@menu_items_friendly_names[record[:menu_item]]}]"
    end
  end
end