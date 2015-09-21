module MesScada::GridPlugins
  module RmtProcessing
    class BinLocationsPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name, cell_value, record)
        if column_name=="qty_bins_available"
          return make_action("#{@request.host_with_port}/#{@request.path_parameters['controller'].to_s}/location_farm_bins?id=#{record['location_code'].to_s + "@"  +record['farm_code'].to_s + "@" + record['id'].to_s}","#{record['qty_bins_available']}")
        end
        return cell_value
      end
    end
  end
end