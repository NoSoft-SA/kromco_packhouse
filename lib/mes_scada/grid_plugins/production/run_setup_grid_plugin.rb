module MesScada::GridPlugins

  module Production

    class RunSetupGridPlugin < MesScada::GridPlugin

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
        if !record.has_runs
          record.has_runs = (ProductionSchedule.num_runs_for_schedule(record.id)> 0)
        end
        case record.has_runs
          when "true"
            return :green
          else
            return :red
        end
      end
    end

  end

end

