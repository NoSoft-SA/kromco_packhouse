module MesScada::GridPlugins

  module Production

    class ReworksReceivedPalletsGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(column_name,cell_value,record)

        @strong_on = false
        record.reworks_action = "" if ! record.reworks_action

        if record.reworks_action.upcase == "ALT_PACKED"
          :blue
        elsif record.reworks_action.upcase == "NEW_PALLET"
          :green
        elsif record.reworks_action.upcase == "RECLASSIFIED"
          :green
        elsif record.build_up_balance
          :orange
        else
          :red
        end

        if column_name == "reworks_action"
          @strong_on = true
          # style += "<strong>"
        end

        if column_name == "build_up_balance" && record.build_up_balance
          @strong_on = true
          :orange
          # style += "<strong>"
        end

      end

    end

  end

end