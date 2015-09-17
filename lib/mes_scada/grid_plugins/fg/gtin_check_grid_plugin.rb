module MesScada::GridPlugins

  module Fg

    class GtinCheckGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(record)
        if !record["gtin_found"]
          return :red
        elsif record["gtin_found"] && !record["gtin_tm"]
          return :orange
        elsif record["gtin_found"] && record["gtin_tm"]
          return :green
        end
      end

    end
  end
end
