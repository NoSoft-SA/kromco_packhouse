require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module IssuePlugins
class IssuePlugin < ApplicationHelper::GridPlugin
      
      def cancel_cell_rendering(column_name,cell_value,record)
        false
      end
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
        if record.status == "opened"||record.status == "paused"
        "<font color = 'orange'>"
        elsif record.status == "completed"
          "<font color = 'green'>"
        elsif record.status == "rejected"
          "<font color = 'gray'>"
        elsif record.status == "in work"
          "<font color = 'blue'>"
        elsif record.status == "listed"
          "<font color = 'gray'>"
        else
         "<font color = 'red'>"
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
  
  class TodoGridPlugin < ApplicationHelper::GridPlugin
      
      def cancel_cell_rendering(column_name,cell_value,record)
        false
      end
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
         
         
         if record.completed && column_name == "description"
           @strike_on = true
           "<font color = 'green'><strike>"     
         elsif record.completed && column_name != "description"
           "<font color = 'green'>"
         elsif record.complete_by < Time.now
            "<font color = 'red'>"
         else
           "<font color = 'blue'>"
         end
         
        
      end
      
      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        if @strike_on
         @strike_on = false
        '</strike></font>'
         
        else
          "</font>"
        end 
      
      end
      
    
  end
  
  
  
 end