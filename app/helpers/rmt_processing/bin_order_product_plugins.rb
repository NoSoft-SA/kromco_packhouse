 require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

   module RmtProcessingPlugins
   class BinOrderProductGridPlugin < ApplicationHelper::GridPlugin


      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this method
      #---------------------------------------------------------------



   def before_cell_render_styling(column_name,cell_value,record)


       return "<font color = 'red'>" if record['status'].upcase =='ORDER_PRODUCT_CREATED'
       return "<font color = 'red'>" if record['status'].upcase =='LOADING'
       return "<font color = 'green'>" if record['status'].upcase =='COMPLETED'
       return "<font color = 'green'>" if record['status'].upcase =='LOADED'




      end

       def after_cell_render_styling(column_name,cell_value,record)

         "</strong></font>"

       end






end
    end
#=end
# =begin