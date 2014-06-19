   require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

   module DiagnosticsPlugins
   class DirectoryGridPlugin < ApplicationHelper::GridPlugin


      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this method
      #---------------------------------------------------------------


        
   def before_cell_render_styling(column_name,cell_value,record)

        style = ""

        record['type']= "" if ! record['type']

        if record['type'] == ".rb"
         style = "<font color = 'red'>"
        elsif record['type'] == ".js"
         style =  "<font color = 'blue'>"
        elsif record['type'] == ".yml"
         style =  "<font color = 'brown'>"
        elsif record['type']  == ".xml"
           style =  "<font color = 'green'>"
        elsif record['type']  == ".rhtml"
           style =  "<font color = 'purple'>"
        elsif record['type']  == ".css"
           style =  "<font color = 'black'>"
        else
          style =  "<font color = 'orange'>"
        end

        if column_name == "type"
          @strong_on = true
          style += "<strong>"
        end

        
        return style
      end

       def after_cell_render_styling(column_name,cell_value,record)

         "</strong></font>"
        
       end

      
      



end
    end
#=end
# =begin  