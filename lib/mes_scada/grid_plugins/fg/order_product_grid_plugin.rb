module MesScada::GridPlugins
  module Fg
    class OrderProductGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end



      def render_cell(column_name, cell_value, record)
        if column_name=="get_historic_pricing"
          cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/get_historic_pricing/#{record['id']}","historic_pricing")
        end
        #if !@env.session.data[:current_viewing_order]
        #  if(column_name=="price_per_carton" || column_name=="price_per_kg" || column_name=="fob")
        #    cell_value= @env.text_field('order_product', "#{record['id']}_#{column_name}", {:size=>5,:value=>record[column_name]})
        #  end
        #else
        #  if column_name=="price_per_carton"
        #    cell_value=  record['price_per_carton']
        #  elsif column_name=="price_per_kg"
        #    cell_value=  record['price_per_kg']
        #  elsif   column_name=="fob"
        #    cell_value= record['fob']
        #  end
        #end
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
          cell_value= make_action("http://#{@request.host_with_port}/"+"fg/order_product/delete_order_product" + "/" + record['id'].to_s,'delete')
        end
        cell_value
      end

    end
  end
end