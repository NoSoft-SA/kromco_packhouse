module MesScada::GridPlugins

  module Production

    class ScheduleSetupGridPlugin < MesScada::GridPlugin

      def render_cell(column_name, cell_value, record)
        case
          when column_name == "id"
            ''
          else
            cell_value
        end
      end

      def row_cell_colouring(record)
        case record['production_schedule_status_code']
          when "active"
            :red
          when "re_opened"
            :orange
          when "closed"
            :green
          when "template"
            :blue
          when "completed"
            :gray
          else
            :black
        end
      end

    end

  end

end
