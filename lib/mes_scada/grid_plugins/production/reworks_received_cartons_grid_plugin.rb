module MesScada::GridPlugins

  module Production

    class ReworksReceivedCartonsGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(column_name,cell_value,record)
        @strong_on = false
        record.rw_pallet_action = "" if ! record.rw_pallet_action
        record.reworks_action = "" if ! record.reworks_action
        if record.reworks_action.upcase == "ALT_PACKED"
          :blue
        elsif record.reworks_action.upcase == "ALT_PACKED_FROM_CARTON"
          :indigo
        elsif record.reworks_action.upcase == "RECLASSIFIED"
          :green
        elsif record.reworks_action.upcase == "SCRAPPED"
          :gray
        elsif record.rw_pallet_action && record.rw_pallet_action != ""
          :orange
        else
          :red
        end

        if column_name == "reworks_action"
          @strong_on = true
          style += "<strong>"
        end

        if column_name == "rw_pallet_action"
          @strong_on = true
          style += "<strong>"
        end

      end

    end

  end

end