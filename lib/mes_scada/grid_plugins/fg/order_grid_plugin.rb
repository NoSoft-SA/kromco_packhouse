module MesScada::GridPlugins
  module Fg
    class OrderGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env     = env
        @request = request
      end

      def render_cell(column_name, cell_value, record)
        if column_name=="test_upgrade" && (@env.session.data[:mo_and_mq_orders_not_ready]==true &&(record.order_type_code.strip=="MO" || record.order_type_code.strip=="MQ"))
          cell_value= make_action("http://#{@request.host_with_port}/"+"fg/order/test_upgrade_prelim_order" + "/" +record['id'].to_s,'test_upgrade')
        end
        if column_name=="upgrade_order"  && (record.order_type_code.strip=="MO" || record.order_type_code.strip=="MQ") && (record['not_all_pallets_is_stock']==nil || record['not_all_pallets_is_stock']==false || record['not_all_pallets_is_stock']=="f")
          cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/upgrade_order/#{record['id']}","upgrade_order")
        end
        cell_value
      end



      def row_cell_colouring(record)
        colour = nil
        return :purple          if record['order_type_code'] && record['order_type_code'].strip.upcase =='MO'
        return :blue            if record['order_type_code'] && record['order_type_code'].strip.upcase =='MQ'
        return :blue            if record['order_status'].upcase =='SHIPPED'
        return :brown           if record['order_status'].upcase =='RETURNED'
        return :magenta         if record['order_status'].upcase == Order::STATUS_DELETION_RECVD
        if record['load_status']!= nil
          if record['load_status'].upcase =='LOAD_CREATED'
            return :red
          elsif record['load_status'].upcase =='TRUCK_LOADED'
            return :green
          else
            return :orange
          end
        else
          return :black
        end


      end

    end
  end
end