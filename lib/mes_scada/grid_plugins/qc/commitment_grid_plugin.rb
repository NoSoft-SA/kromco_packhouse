module MesScada::GridPlugins
  module Qc
    class CommitmentGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def row_cell_colouring(record)
        if record["certificate_expiry_date"] < Time.now
          return :orange
        end
      end
    end
  end
end
