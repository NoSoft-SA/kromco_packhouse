module MesScada::GridPlugins
  module Facilities
    class LocationsGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)
          if column_name == "unavailable"

           if record['unavailable']
             availability =record['unavailable']
           else
             availability='false'
           end
            cell_value= make_action("http://#{@request.host_with_port}/"+"inventory/facilities/control_location_availability" + "/" + record['id'].to_s,availability)
          end
        return cell_value
      end

      def row_cell_colouring(record)
        if record["unavailable"]
          return :red
        end
      end

    end
  end
end
