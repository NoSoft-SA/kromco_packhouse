module MesScada::GridPlugins
  module Diagnostics
    class PdtErrorsPlugin < MesScada::GridPlugin

      def row_cell_colouring(record)
        record.user_name = "" if ! record.user_name

        if record.user_name.upcase == "HANS"
          return :blue
        elsif record.user_name.upcase == "MES"
          return :green
        elsif record.user_name.upcase == "DERRICKW"
          return :purple
        elsif record.user_name.upcase == "GERT"
          return :yellow
        else
          return :red
        end
      end
    end
  end
end
