require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module FgPlugins
  class SearchOrderGridPlugin < ApplicationHelper::GridPlugin


    #---------------------------------------------------------------
    #This method allows a user to customize the styling of a cell
    #The calling method will prepend the cell text with the styling
    #string returned by this method
    #---------------------------------------------------------------


    def before_cell_render_styling(column_name, cell_value, record)
      style = ""

       return "<font color = 'blue'>" if record['order_status'].upcase =='SHIPPED'
       return "<font color = 'brown'>" if record['order_status'].upcase =='RETURNED'
       return "<font color = 'magenta'>" if record['order_status'].upcase == Order::STATUS_DELETION_RECVD

    end


    def after_cell_render_styling(column_name, cell_value, record)

      "</font>"

    end


  end

end


# =begin