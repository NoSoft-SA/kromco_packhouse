module MesScada::GridPlugins

  module Production

    class PackStationGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(column_name, cell_value, record)
        case column_name
          when "drop_code", "table_code", "station_code", "drop_side_code"
            if record.grade
              :blue
            else
              :gray
            end
          when "size_count", "grade", "marketing_variety", "color_percentage", "fg_product_code", "carton_setup_code"
            if record.fg_product_code
              :green
            else
              :red
            end
          else
            :black
        end
      end

    end

  end

end