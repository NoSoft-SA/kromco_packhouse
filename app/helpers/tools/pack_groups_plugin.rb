require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module PackGroupsConfigPlugins

class PackGroupsConfigGridPlugin < ApplicationHelper::GridPlugin
      
      
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
      
        if record.size
        "<font color = 'blue'><strong>"
        else
          "<font color = 'green'>"
        end
      end
      
      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        '</strong></font>'
      
      end
      
    
  end
 
end
