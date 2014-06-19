module QualityControlPlugins
  class MrlResultGridPlugin < ApplicationHelper::GridPlugin
        #---------------------------------------------------------------
        #This method allows a user to customize the styling of a cell
        #The calling method will prepend the cell text with the styling
        #string returned by this method
        #---------------------------------------------------------------
   def before_cell_render_styling(column_name,cell_value,record)
          @strong_on = false
          style = ""
          if record.mrl_result.to_s.upcase == "PASSED"
          style = "<font color = 'orange'>"

          elsif record.mrl_result.to_s.upcase == "FAILED"
          style =  "<font color = 'red'>"

          elsif record.mrl_result.to_s.upcase == "PENDING"
          style =  "<font color = '#F660AB'>"

          elsif !record.mrl_result || record.mrl_result.to_s.strip == ""
          style =  "<font color = 'black'>"

          return style
        end
    end
 end
end