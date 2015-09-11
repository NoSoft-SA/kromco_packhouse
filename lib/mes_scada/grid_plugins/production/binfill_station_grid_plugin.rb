module MesScada::GridPlugins

  module Production

    class BinfillStationGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)
        return cell_value
      end

      def cancel_cell_rendering(column_name, cell_value, record)

      end

      def row_cell_colouring(column_name, cell_value, record)
        case column_name
          when "drop_code", "binfill_station_code"
            return :blue
          when "size", "grade", "marketing_variety"
            if record.rmt_product_code
              return :green
            else
              return :red
            end
        end
      end

    end

  end

end