module MesScada::GridPlugins

  module Production

    class ProcessingSetupGridPlugin < MesScada::GridPlugin

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
        if record.handling_product_type_code.upcase == "REBIN"
            return :blue
        else
            return :brown
        end
      end

      # def before_cell_render_styling(column_name,cell_value,record)
      #   if record.handling_product_type_code.upcase == "REBIN"
      #     "<font color = 'blue'>"
      #   else
      #     "<font color = 'brown'>"
      #
      #   end
      # end
      #
      # #--------------------------------------------------------------------
      # #This method is called after the grid has rendered text to the cell
      # #The plugin provider should simply simply provide html closing tags
      # #for the tags opened during 'before_cell_render_styling'
      # #----------------------------------------------
      # def after_cell_render_styling(column_name,cell_value,record)
      #   '</font>'
      #
      # end
      #
      # def cancel_cell_rendering(column_name,cell_value,record)
      #
      # end

    end

  end

end