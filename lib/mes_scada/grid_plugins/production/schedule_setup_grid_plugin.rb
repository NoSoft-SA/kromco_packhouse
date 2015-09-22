module MesScada::GridPlugins

  module Production

    class ScheduleSetupGridPlugin < MesScada::GridPlugin

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
        # color = nil
        case record['production_schedule_status_code']
          when "active"
            return :red
          when "re_opened"
            return :orange
          when "closed"
            return :green
          when "template"
            return :blue
          when "completed"
            return :gray
          else
            return :black
        end
      end

    end

  end

end
