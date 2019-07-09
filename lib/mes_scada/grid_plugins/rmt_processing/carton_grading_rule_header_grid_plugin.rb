module MesScada::GridPlugins
  module RmtProcessing
    class CartonGradingRuleHeaderGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def row_cell_colouring(record)
        return :green if record['activated'] =='t' || record['activated'] == true
      end
    end
  end
end