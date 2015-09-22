module MesScada::GridPlugins

  module Production

    class ReworksReceivedTippedBinsGridPlugin < MesScada::GridPlugin

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

        record.rw_reworks_action = "" if ! record.rw_reworks_action
        if record.rw_reworks_action.upcase == "RECLASSIFIED"
          return :blue
        else
          return :red
        end

      end

    end

  end

end