require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module ProccSetupPlugins 
class ProccSetupGridPlugin < ApplicationHelper::GridPlugin

      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
        if record.handling_product_type_code.upcase == "REBIN"
        "<font color = 'blue'>"
        else 
          "<font color = 'brown'>"
       
        end
      end
      
      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        '</font>'
      
      end

  end
 end