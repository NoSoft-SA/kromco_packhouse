module MesScada::GridPlugins

  module Production

    class CartonSetupGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(record)
        if column_name !="id"
          is_done = record.retail_item_setup != nil && record.retail_unit_setup != nil && record.trade_unit_setup != nil && record.fg_setup != nil && record.pallet_setup != nil
          if is_done == false
            :red
          else
            :green
          end
        end
      end

    end

  end

end