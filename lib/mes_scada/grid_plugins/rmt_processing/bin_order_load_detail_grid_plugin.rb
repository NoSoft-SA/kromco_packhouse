module MesScada::GridPlugins
  module RmtProcessing
    class BinOrderLoadDetailGridPlugin < MesScada::GridPlugin
      def row_cell_colouring(record)
        colour = nil
        return :red if record['status'].upcase =='LOAD_DETAIL_CREATED'
        return :red if record['status'].upcase =='LOADING'
        return :blue if record['status'].upcase =='COMPLETED'
        return :green if record['status'].upcase =='LOADED'
      end
    end
  end
end