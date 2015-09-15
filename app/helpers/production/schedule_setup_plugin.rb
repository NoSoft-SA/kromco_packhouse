require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module ScheduleSetupPlugins
class ScheduleSetupGridPlugin < ApplicationHelper::GridPlugin
      
    
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
        if column_name == "id"
          return
        end
        if record.production_schedule_status_code == "active"
        "<font color = 'red'>"
        elsif record.production_schedule_status_code == "re_opened"
          "<font color = 'orange'>"
        elsif record.production_schedule_status_code == "closed"
          "<font color = 'green'>" 
       elsif record.production_schedule_status_code == "template"
          "<font color = 'blue'>" 
       elsif record.production_schedule_status_code == "completed"
          "<font color = 'gray'>" 
          
        end
      end
      
      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        '</font>' if column_name != "id"
      
      end
    
  end
 end