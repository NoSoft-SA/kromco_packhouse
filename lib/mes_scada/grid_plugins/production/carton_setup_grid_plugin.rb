module MesScada::GridPlugins

  module Production

    class CartonSetupGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)
        return cell_value
      end

      def cancel_cell_rendering(column_name, cell_value, record)

      end

      def row_cell_colouring(record)
        if column_name !="id"
          is_done = record.retail_item_setup != nil && record.retail_unit_setup != nil && record.trade_unit_setup != nil && record.fg_setup != nil && record.pallet_setup != nil
          if is_done == false
            return :red
          else
            return :green
          end
        end
      end

      # def before_cell_render_styling(column_name,cell_value,record)
      #   if column_name !="id"
      #     is_done = record.retail_item_setup != nil &&
      #         record.retail_unit_setup != nil &&
      #         record.trade_unit_setup != nil &&
      #         record.fg_setup != nil &&
      #         record.pallet_setup != nil
      #
      #     if is_done == false
      #       "<font color = 'red'>"
      #     else
      #       "<font color = 'green'>"
      #     end
      #   end
      # end
      #
      #
      # #--------------------------------------------------------------------
      # #This method is called after the grid has rendered text to the cell
      # #The plugin provider should simply simply provide html closing tags
      # #for the tags opened during 'before_cell_render_styling'
      # #----------------------------------------------
      # def after_cell_render_styling(column_name,cell_value,record)
      #   if column_name!="id"
      #     '</font>'
      #   end
      # end
      #
      # def cancel_cell_rendering(column_name,cell_value,record)
      #
      # end

    end

  end

end