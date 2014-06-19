require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module RmtProcessingPlugins
  class BinGridPlugin < ApplicationHelper::GridPlugin


    #---------------------------------------------------------------
    #This method allows a user to customize the styling of a cell
    #The calling method will prepend the cell text with the styling
    #string returned by this method
    #---------------------------------------------------------------


    def before_cell_render_styling(column_name, cell_value, record)

      if column_name!= "id"
          if record['destroyed'] =='t'
            return "<font color = 'green'>"
          end
          if record['destroyed'] =='f'
            return "<font color = 'red'>"
          end
      end

    end

    def after_cell_render_styling(column_name, cell_value, record)
        if column_name!= "id"
            "</strong></font>"
         end
    end
  end
  end