module MesScada::GridPlugins

  module Production

    class ReworksReceivedPalletsGridPlugin < MesScada::GridPlugin

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
        record.reworks_action = "" if ! record.reworks_action

        if record.reworks_action.upcase == "ALT_PACKED"
          return :blue
        elsif record.reworks_action.upcase == "NEW_PALLET"
          return :green
        elsif record.reworks_action.upcase == "RECLASSIFIED"
          return :green
        elsif record.build_up_balance
          return :orange
        else
          return :red
        end

        # if column_name == "reworks_action"
        #   @strong_on = true
        #   # style += "<strong>"
        # end
        #
        # if column_name == "build_up_balance" && record.build_up_balance
        #   @strong_on = true
        #   :orange
        #   # style += "<strong>"
        # end

      end

    end

  end

end