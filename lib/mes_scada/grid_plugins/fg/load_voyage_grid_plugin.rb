module MesScada::GridPlugins
  module Fg
    class LoadVoyageGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env     = env
        @request = request
      end

      def render_cell(column_name, cell_value, record)
        cell_value=cell_value
        if  column_name=="lv_order_number"
          order=Order.find(record['order_id'].to_i)
          cell_value= make_action("http://#{@request.host_with_port}/"+"fg/order/lv_edit_order" + "/" + order.id.to_s,record['lv_order_number'])
        end
        cell_value
      end

    end
  end
end
