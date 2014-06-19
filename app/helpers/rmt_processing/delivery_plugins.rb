# To change this template, choose Tools | Templates
# and open the template in the editor.
require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module DeliveryPlugins
    class DeliveriesGridPlugin < ApplicationHelper::GridPlugin     
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)        
        if record["delivery_status"] == "delivery_note_captured"
          "<font color = 'red'>"
        elsif record["delivery_status"] == "100_fruit_sample_completed "
          "<font color = 'blue'>"
        elsif record["delivery_status"] == "intake_bin_scan_completed"
          "<font color = 'green'>"
        elsif record["delivery_status"] == "arrived_at_complex "
          "<font color = 'grey'>"
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
