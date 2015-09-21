module MesScada::GridPlugins

  module Production

    class CountsDropsGridPlugin < MesScada::GridPlugin

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
        if cell_value.to_s == "n.a"
          return :black
        else
          if column_name == "size_code" && cell_value
           return :blue
          elsif column_name == "standard_size_count_value" && cell_value
           return :green
          else
           return :gray
          end
        end
      end

    end

  end

end