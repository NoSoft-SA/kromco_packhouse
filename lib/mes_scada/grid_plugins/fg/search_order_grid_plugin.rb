module MesScada::GridPlugins
  module Fg
    class SearchOrderGridPlugin < MesScada::GridPlugin





      def row_cell_colouring(record)
        colour = nil
        return :blue  if record['order_status'].upcase =='SHIPPED'
        return :brown  if record['order_status'].upcase =='RETURNED'
        return :magenta if record['order_status'].upcase == Order::STATUS_DELETION_RECVD

      end

    end
  end
end