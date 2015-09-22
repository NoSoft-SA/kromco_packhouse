module MesScada::GridPlugins

  module Production

    class BinfillSortStationGridPlugin < MesScada::GridPlugin

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
        if record.rmt_product_code
          return :green
        else
          return :red
        end
      end

    end

  end

end