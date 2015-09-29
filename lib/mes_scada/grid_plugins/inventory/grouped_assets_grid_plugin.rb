module MesScada::GridPlugins

  module Inventory

    class GroupedAssetsGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)
        if column_name == "print_report" && (record["transaction_type_code"] == "move_asset_quantity")
          return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/view_bins_moved_report/#{record["id"]}","bins moved report")
        elsif column_name == "print_report" && (record["transaction_type_code"] == "add_asset_quantity")
          return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/view_bins_added_report/#{record["id"]}","bins added report")
        elsif column_name == "print_report" && (record["transaction_type_code"] == "remove_asset_quantity")
          return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/view_bins_removed_report/#{record["id"]}","bins removed report ")
        end
        return cell_value
      end

    end

  end
end
