module MesScada::GridPlugins

  module Production

    class ReworksReceivedBinsGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(column_name,cell_value,record)

        record.reworks_action = "" if ! record.reworks_action
        if record.reworks_action.upcase == "RECLASSIFIED"
          :green
        elsif record.reworks_action.upcase == "TIPPED" || record.reworks_action.upcase == "BULK_TIPPED"
          :blue
        else
          :red
        end

      end

    end

  end

end