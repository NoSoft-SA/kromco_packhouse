module MesScada::GridPlugins
  module Fg
    class VoyageGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env     = env
        @request = request
      end

      def render_cell(column_name, cell_value, record)

        if column_name=="complete_voyage"
          cell_value= make_action("http://#{@request.host_with_port}/"+"fg/voyage/complete_voyage" + "/" + record['id'].to_s,'complete')
        end
        cell_value
      end


    end
  end
end