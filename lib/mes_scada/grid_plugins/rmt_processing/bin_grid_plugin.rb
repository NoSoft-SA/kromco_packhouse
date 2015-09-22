module MesScada::GridPlugins
  module RmtProcessing
    class BinGridPlugin < MesScada::GridPlugin
      def row_cell_colouring(record)
        return :green if record['destroyed'] =='t'
        return :red if record['destroyed'] =='f'
      end
    end
  end
end