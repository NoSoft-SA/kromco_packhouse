module MesScada::GridPlugins

  module Production

    class ReworksPalletHistoriesGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end


      def render_cell(column_name,cell_value,record)

        if column_name == "diff"  && record['tablename'] == 'rw_reclassed_cartons'
               cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/view_carton_history_diff/#{record['id']}","diff")
        end
        if column_name == "diff"  && record['tablename'] == 'rw_reclassed_pallets'
          cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/view_pallet_history_diff/#{record['id']}","diff")
        end
        if column_name == "diff_to_carton" && record['tablename'] == 'rw_reclassed_cartons'
              cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/view_pallet_history_diff_to_carton/#{record['id']}","diff_to_carton")
        end
        if column_name == "diff_to_pallet"  && record['tablename'] == 'rw_reclassed_pallets'
              cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/view_pallet_history_diff_to_pallet/#{record['id']}","diff_to_pallet")
        end

        cell_value
      end

      #-------------------------------------------------------------------
      #This method allows a plugin to render the cell instead of the
      #grid column. To work, the same plugin must also implmement the
      #'cancel_cell_rendering' method and return true.
      #-------------------------------------------------------------------
      def render_cell(column_name,cell_value,record)
        # ""
        return cell_value
      end

    end

  end

end