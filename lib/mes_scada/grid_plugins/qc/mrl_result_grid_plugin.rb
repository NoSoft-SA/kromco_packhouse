module MesScada::GridPlugins
  module Qc
    class MrlResultGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(record)

        if record.mrl_result.to_s.upcase == "FAILED"
          return :red
        elsif record.mrl_result.to_s.upcase == "PASSED"
          return :orange
        elsif record.mrl_result.to_s.upcase == "PENDING"
          return :purple
        end
        return :black
      end
      
    end

  end
end
