module MesScada::GridPlugins

  module DepotReceipts

    class PalletSequencePlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)

        if column_name.to_s == "edit"
          if record["mapped?"].to_s == "false"
            return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/edit_pallet_sequence/#{record["id"]}","map")
          else
            return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/edit_pallet_sequence/#{record["id"]}","map")
          end
          return map_link_url
        elsif column_name.to_s == "print_labels"
          if record["header_status"] != "LOAD_RECEIVED"
            return "-"
          else
            if record["mapped?"].to_s == "false"
              return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/print_pallet_labels/#{record["id"]}","map")
            else
              return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/print_pallet_labels/#{record["id"]}","map")
            end
          end
        elsif column_name.to_s == "mapped"
          if record["mapped?"].to_s == "false"
            return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/view_pallet_sequence/#{record["id"]}","map")
          else
            return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/view_pallet_sequence/#{record["id"]}","map")
          end
          return mapped_link_url
        else

          if column_name == "commodity" ||column_name == "variety" || column_name == "grade" || column_name == "class_code" || column_name == "count" || column_name == "pack_type" || column_name == "organization" || column_name == "brand"
            if column_name != "extended_fg_code" && (cell_value == nil ||cell_value.strip() == "")
              return "(missing)"
            end
          end
          return record[column_name].to_s
        end
        return cell_value
      end

    end

  end
end
