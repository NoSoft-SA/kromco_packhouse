module MesScada::GridPlugins

  module Production

    class CountsDropsGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(column_name, cell_value, record)
        if cell_value.to_s == "n.a"
          :black
        else
          if column_name == "size_code" && cell_value
            :blue
          elsif column_name == "standard_size_count_value" && cell_value
            :green
          else
            :gray
          end
        end
      end

    end

  end

end