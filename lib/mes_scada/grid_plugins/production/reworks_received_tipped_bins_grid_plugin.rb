module MesScada::GridPlugins

  module Production

    class ReworksReceivedTippedBinsGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(column_name,cell_value,record)

        record.rw_reworks_action = "" if ! record.rw_reworks_action
        if record.rw_reworks_action.upcase == "RECLASSIFIED"
          :blue
        else
          :red
        end

      end

    end

  end

end