module MesScada::GridPlugins

  module Production

    class BinfillSortStationGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(column_name, cell_value, record)
        if record.rmt_product_code
          :green
        else
          :red
        end

      end

    end

  end

end