module MesScada::GridPlugins

  module Production

    class ReworksReceivedCartonsGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)
        return cell_value
      end

      def cancel_cell_rendering(column_name, cell_value, record)

      end

      def row_cell_colouring(column_name,cell_value,record)
        @strong_on = false
        record.rw_pallet_action = "" if ! record.rw_pallet_action
        record.reworks_action = "" if ! record.reworks_action
        if record.reworks_action.upcase == "ALT_PACKED"
          return :blue
        elsif record.reworks_action.upcase == "ALT_PACKED_FROM_CARTON"
          return :indigo
        elsif record.reworks_action.upcase == "RECLASSIFIED"
          return :green
        elsif record.reworks_action.upcase == "SCRAPPED"
          return :gray
        elsif record.rw_pallet_action && record.rw_pallet_action != ""
          return :orange
        else
          return :red
        end

        # if column_name == "reworks_action"
        #   @strong_on = true
        #   style += "<strong>"
        # end
        #
        # if column_name == "rw_pallet_action"
        #   @strong_on = true
        #   style += "<strong>"
        # end

      end

    end

  end

end