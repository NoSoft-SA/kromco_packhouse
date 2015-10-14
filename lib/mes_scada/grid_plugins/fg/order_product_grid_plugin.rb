module MesScada::GridPlugins
  module Fg
    class OrderProductGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env = env
        @request = request
        calc_queries
      end

      def calc_queries
        @load_details=LoadDetail.find_by_sql("select ld.id,op.id as order_product_id from load_details ld
                                   join order_products op on ld.order_product_id=op.id
                                   where op.order_id=#{@env.session.data[:active_doc]['order']}")
      end



      def render_cell(column_name, cell_value, record)

        if column_name=="get_historic_pricing"
          cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/get_historic_pricing/#{record['id']}","historic_pricing")
        end
        if column_name=="price_histories"
          cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/price_histories/#{record['id']}","price_histories")
        end
        if column_name=="subtotal"
          if record['price_per_carton']==nil
            subtotal=0
          else
            subtotal=record['price_per_carton'] * record['carton_count']
          end
          cell_value= subtotal
        end
        if column_name=="delete"
          load_details=@load_details.find_all { |p| p.order_product_id.to_i==record.id.to_i }

          cell_value= make_action("http://#{@request.host_with_port}/"+"fg/order_product/delete_order_product" + "/" + record['id'].to_s,'delete')  if load_details.empty?
          cell_value= nil if !load_details.empty?
        end
        cell_value
      end

    end
  end
end