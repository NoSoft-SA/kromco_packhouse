require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module RebinSetupPlugins
class RebinSetupGridPlugin < ApplicationHelper::GridPlugin
      
    
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
        font = ""
        if record.rebin_label_setup == nil||record.rebin_template == nil
         font = "<font color = 'red'>"
        else 
          font = "<font color = 'green'>"
        end
        
        if  record.standard_size_count_from == nil||record.standard_size_count_from == -1
          font += "<strong>"
        end
        
        return font
        
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