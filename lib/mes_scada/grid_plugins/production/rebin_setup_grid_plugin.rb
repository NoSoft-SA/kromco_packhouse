module MesScada::GridPlugins

  module Production

    class RebinSetupGridPlugin < MesScada::GridPlugin

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
        if record.rebin_label_setup == nil||record.rebin_template == nil
          return :red
        else
          return :green
        end
      end

    end

  end

end