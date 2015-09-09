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

      def before_cell_render_styling(column_name, cell_value, record)
        if !record.has_runs
          record.has_runs = (ProductionSchedule.num_runs_for_schedule(record.id)> 0)
        end

        if record.has_runs == true
          "<font color = 'green'>"
        else
          "<font color = 'red'>"
        end

      end
      def after_cell_render_styling(column_name, cell_value, record)
        '</font>'

      end

      def cancel_cell_rendering(column_name,cell_value,record)

      end


    end

  end

end

