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
        # if column_name !="id"
          is_done = record.retail_item_setup != nil && record.retail_unit_setup != nil && record.trade_unit_setup != nil && record.fg_setup != nil && record.pallet_setup != nil
          if is_done == false
            return :red
          else
            return :green
          end
        end
      # end

    end

  end

end