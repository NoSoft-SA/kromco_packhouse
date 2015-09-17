module MesScada::GridPlugins

  module Fg

    class IntakeHeaderGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(record)
        if record["header_status"].to_s.upcase == "HEADER_CREATED" || record["header_status"].to_s.upcase == "CAPTURING_PALLETS"
          return :red
        elsif record["header_status"].to_s.upcase == "PALLETS_CAPTURED" || record["header_status"].to_s.upcase == "FRUITSPEC_MAPPED"
          return :blue
        elsif record["header_status"].to_s.upcase == "EDI_SENT" || record["header_status"].to_s.upcase == "LOAD_RECEIVED"
          return :green
        elsif record["header_status"].to_s.upcase == "EDI_RECEIVED"
          return :gray
        elsif record["header_status"].to_s.upcase == "CANCELED"
          return :gray
        end
      end

    end
  end
end
