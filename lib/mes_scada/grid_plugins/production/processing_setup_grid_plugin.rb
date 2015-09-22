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

    end

  end

end