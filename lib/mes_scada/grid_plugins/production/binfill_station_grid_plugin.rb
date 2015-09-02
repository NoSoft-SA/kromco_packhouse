module MesScada::GridPlugins

  module Production

    class BinfillStationGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(column_name, cell_value, record)
        case column_name
          when "drop_code", "binfill_station_code"
            :blue
          when "size", "grade", "marketing_variety"
            if record.rmt_product_code
              :green
            else
              :red
            end
        end
      end

    end

  end

end