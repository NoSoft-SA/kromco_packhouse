module MesScada::GridPlugins

  module DepotReceipts

    class DepotReceiptPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def row_cell_colouring(record)
        record.user_name = "" if ! record.user_name

        if record["mapped?"].to_s == "false"
          return :red
        else
          return :green
        end

        # if cell_value == nil ||cell_value.strip() == ""
        #   style = "<font color='black'>"
        # end
      end

      def render_cell(column_name,cell_value,record)

        if column_name.to_s == "map"
          return "missing fruit spec data"  if @missing_field
          if record["mapped?"].to_s == "false"
            return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/map_pallet_sequences/#{record["id"]}|#{record["mapped?"]}","map")
          else
            return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/map_pallet_sequences/#{record["id"]}|#{record["mapped?"]}","map")
          end
          return "map"
        elsif column_name.to_s == "pallets"
          if record["mapped?"].to_s == "false"
            return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/show_intake_header_pallets/#{record["id"]}|#{record["mapped?"]}","pallets")
          else
            return make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/show_intake_header_pallets/#{record["id"]}|#{record["mapped?"]}","pallets")
          end
        else
          if column_name != "extended_fg_code" && (cell_value == nil ||cell_value.strip() == "")
            @missing_field = true
            return "(missing)"
          else
            return record[column_name].to_s
          end

        end
        return cell_value
      end

    end

  end
end
