module MesScada::GridPlugins

  module Production

    class RebinSetupGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)
        return cell_value
      end

      def cancel_cell_rendering(column_name, cell_value, record)

      end

      def row_cell_colouring(record)
        if record.rebin_label_setup == nil||record.rebin_template == nil
          return :red
        else
          return :green
        end
      end

      # def before_cell_render_styling(column_name,cell_value,record)
      #   font = ""
      #   if record.rebin_label_setup == nil||record.rebin_template == nil
      #     font = "<font color = 'red'>"
      #   else
      #     font = "<font color = 'green'>"
      #   end
      #
      #   if  record.standard_size_count_from == nil||record.standard_size_count_from == -1
      #     font += "<strong>"
      #   end
      #
      #   return font
      #
      # end
      #
      # #--------------------------------------------------------------------
      # #This method is called after the grid has rendered text to the cell
      # #The plugin provider should simply simply provide html closing tags
      # #for the tags opened during 'before_cell_render_styling'
      # #----------------------------------------------
      # def after_cell_render_styling(column_name,cell_value,record)
      #   '</strong></font>'
      #
      # end
      #
      # def cancel_cell_rendering(column_name,cell_value,record)
      #
      # end

    end

  end

end