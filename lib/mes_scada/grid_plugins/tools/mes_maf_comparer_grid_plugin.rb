module MesScada::GridPlugins

  module Tools

    class MesMafComparerGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)
        return cell_value
      end

      def cancel_cell_rendering(column_name, cell_value, record)
        if column_name == "view_bin" && !record['mes_bin']
          return true
        end
        return false
      end

      def row_cell_colouring(record)

      end

    end

  end

end