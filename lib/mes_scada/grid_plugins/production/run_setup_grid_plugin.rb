module MesScada::GridPlugins

  module Production

    class RunSetupGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(record)
        if !record.has_runs
          record.has_runs = (ProductionSchedule.num_runs_for_schedule(record.id)> 0)
        end
        case record.has_runs
          when "true"
            :green
          else
            :red
        end
      end

    end

  end

end

