module MesScada::GridPlugins
  module Fg
    class LoadGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env = env
        @request = request
        calc_queries
      end

  def calc_queries

  @load_alloc_pallets =Pallet.find_by_sql("select distinct count(pallets.*) as count,loads.id as load_id
  from pallets
  inner join load_details on pallets.load_detail_id=load_details.id
  inner join load_orders on load_details.load_order_id=load_orders.id
  inner join  loads on load_orders.load_id=loads.id
  where pallets.load_detail_id IS NOT NULL and load_orders.order_id=#{@env.session.data['order_id']} group by loads.id")

  @order_types        =OrderType.find_by_sql("select order_types.order_type_code,load_orders.load_id
  from orders
  join order_types on orders.order_type_id=order_types.id
  join load_orders on load_orders.order_id=orders.id
  where load_orders.order_id=#{@env.session.data['order_id']}")

  end

  def render_cell(column_name, cell_value, record)
    order_type= @order_types.find_all { |p| p.load_id.to_i==record['id'].to_i }
    if !order_type.empty? && (order_type[0].order_type_code.strip!="MO" || order_type[0].order_type_code.strip!="MQ")
      if column_name == "reports"
        cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/reports_and_edis/#{record['id']}","reports_and_edis")
      end
      if column_name=="edit_vehicle"
        cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/edit_vehicle/#{record['id']}","edit_vehicle")
      end
      if column_name=="edit_container"
        cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/edit_container/#{record['id']}","edit_container")
      end
      if column_name=="link_edit_voyage"
        load_voyage=LoadVoyage.find_by_load_id(record['id'])
        if load_voyage
          cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/edit_voyage/#{record['id']}","link_voyage")
        else
          cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/link_to_voyage/#{record['id']}","link_voyage")
        end
      end
      if column_name == "complete_load"
        load_status=Load.find(record['id'].to_i).load_status
        if load_status.upcase.strip=="SHIPPED"
          cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/complete_load/#{record['id']}","complete_load")
        end
      end
    end
    if column_name == "print_pick_list"
      load_pallets = @load_alloc_pallets.find_all { |p| p.load_id.to_i==record['id'].to_i }
      if !load_pallets.empty?
        cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/print_pick_list/#{record['id']}","print_pick_list")
      end
    end
    if column_name=="pallets"
      count=@load_alloc_pallets.find_all{|u|u.load_id.to_i==record['id'].to_i}
      if count.empty?
        count =0
      else
        count=count[0]['count']
      end
      cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/view_load_pallets/#{record['id']}", count.to_s)
    end
    #if column_name=="load_status"
    #  cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/load_status/#{record['id']}",record["load_status"])
    #end
      cell_value
  end






    end
  end
end