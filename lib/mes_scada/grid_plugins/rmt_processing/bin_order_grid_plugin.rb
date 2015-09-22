 module MesScada::GridPlugins
   module RmtProcessing
     class BinOrderGridPlugin < MesScada::GridPlugin
       def row_cell_colouring(record)
         colour = nil
         return :red      if record['order_status'].upcase =='BIN_ORDER_CREATED'
         return :brown    if record['order_status'].upcase =='RETURNED'
         return :blue     if record['order_status'].upcase =='COMPLETED'
         return :green    if record['order_status'].upcase =='LOADED'
         return :blue     if record['order_status'].upcase =='TRUCK_LOADED'
       end
     end
    end
  end






