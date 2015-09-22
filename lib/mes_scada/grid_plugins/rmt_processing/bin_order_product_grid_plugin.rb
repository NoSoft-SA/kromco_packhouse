module MesScada::GridPlugins
  module RmtProcessing
    class BinOrderProductGridPlugin < MesScada::GridPlugin
      def row_cell_colouring(record)
        colour = nil
        return :red if record['status'].upcase =='ORDER_PRODUCT_CREATED'
        return :red if record['status'].upcase =='LOADING'
        return :green if record['status'].upcase =='COMPLETED'
        return :green if record['status'].upcase =='LOADED'
      end
    end
  end
end