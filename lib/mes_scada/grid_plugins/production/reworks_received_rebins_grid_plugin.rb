module MesScada::GridPlugins

  module Production

    class ReworksReceivedRebinsGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(column_name,cell_value,record)

        record.reworks_action = "" if ! record.reworks_action
        if record.reworks_action.upcase == "RECLASSIFIED"
          :green
        else
          :red
        end

      end

    end

  end

end