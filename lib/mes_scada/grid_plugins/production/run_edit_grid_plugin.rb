module MesScada::GridPlugins

  module Production

    class RunEditGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env     = env
        @request = request
      end

      def cancel_cell_rendering(column_name, cell_value, record)
        if (column_name=="rank")
          return true
        end
      end

      def render_cell(column_name, cell_value, record)
        if (column_name=="rank")
          return @env.text_field('run', "#{record['id']}_#{column_name}", {:size =>2, :value => record[column_name]})
        end
      end

      def row_cell_colouring(record)
        case record['production_run_status']
          when "reconfiguring"
            :orange
          when "restored"
            :blue
          when "active"
            :green
          else
            :brown
        end
      end
    end
  end
end