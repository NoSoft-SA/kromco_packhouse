module MesScada::GridPlugins

  module Production

    class ReworksReceivedBinsGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def row_cell_colouring(record)

        record.reworks_action = "" if ! record.reworks_action
        if record.reworks_action.upcase == "RECLASSIFIED"
          return :green
        elsif record.reworks_action.upcase == "TIPPED" || record.reworks_action.upcase == "BULK_TIPPED"
          return :blue
        else
          return :red
        end

      end

    end

  end

end