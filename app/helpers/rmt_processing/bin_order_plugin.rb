require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module RmtProcessingPlugins
  class BinOrderGridPlugin < ApplicationHelper::GridPlugin


    #---------------------------------------------------------------
    #This method allows a user to customize the styling of a cell
    #The calling method will prepend the cell text with the styling
    #string returned by this method
    #---------------------------------------------------------------


    def before_cell_render_styling(column_name, cell_value, record)


       return "<font color = 'red'>" if record['order_status'].upcase =='BIN_ORDER_CREATED'
       return "<font color = 'brown'>" if record['order_status'].upcase =='RETURNED'
       return "<font color = 'blue'>" if record['order_status'].upcase =='COMPLETED'
       return "<font color = 'green'>" if record['order_status'].upcase =='LOADED'
       return "<font color = 'blue'>" if record['order_status'].upcase =='TRUCK_LOADED'
#      if record['load_status']!= nil
#         if record['load_status'].upcase =='LOAD_CREATED'
#          style = "<font color = 'red'>"
#        else record['load_status'].upcase =='TRUCK_LOADED'
#          style =  "<font color = 'green'>"
#               end
#
#      end

    end


    def after_cell_render_styling(column_name, cell_value, record)

      "</strong></font>"

    end


  end

end


