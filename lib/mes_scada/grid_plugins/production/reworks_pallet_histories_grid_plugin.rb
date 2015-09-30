module MesScada::GridPlugins

  module Production

    class ReworksPalletHistoriesGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      #---------------------------------------------------------------
      #This method allows the grid-client code to cancel the rendering
      #of a given cell
      #---------------------------------------------------------------
      def cancel_cell_rendering(column_name,cell_value,record)
        if (column_name == "diff" || column_name == "diff_to_carton" || column_name == "diff_to_pallet") && (record['tablename'] != 'rw_reclassed_cartons' && record['tablename'] != 'rw_reclassed_pallets')
          return true
        end
        return false
      end

      #-------------------------------------------------------------------
      #This method allows a plugin to render the cell instead of the
      #grid column. To work, the same plugin must also implmement the
      #'cancel_cell_rendering' method and return true.
      #-------------------------------------------------------------------
      def render_cell(column_name,cell_value,record)
        ""
        return cell_value
      end

    end

  end

end