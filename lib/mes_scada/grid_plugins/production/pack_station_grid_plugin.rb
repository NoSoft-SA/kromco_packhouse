module MesScada::GridPlugins

  module Production

    class PackStationGridPlugin < MesScada::GridPlugin

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
          when "drop_code", "table_code", "station_code", "drop_side_code"
            if record.grade
              return :blue
            else
              return :gray
            end
          when "size_count", "grade", "marketing_variety", "color_percentage", "fg_product_code", "carton_setup_code"
            if record.fg_product_code
              return :green
            else
              return :red
            end
          else
            return :black
        end
      end

    end

  end

end