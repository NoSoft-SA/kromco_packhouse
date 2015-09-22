module MesScada::GridPlugins
  module Fg
    class LoadDetailGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env = env
        @request = request
        calc_queries
      end

      def calc_queries
        @alloc_pallets =Pallet.find_by_sql("select count(pallets.*) as count,load_details.id as load_detail_id
                                      from pallets
                                      inner join load_details on pallets.load_detail_id=load_details.id
                                      inner join load_orders on load_details.load_order_id=load_orders.id
                                      inner join  loads on load_orders.load_id=loads.id
                                      where pallets.allocated IS TRUE and load_orders.load_id=#{@env.session.data[:active_doc]['loads']} group by load_details.id ")
        @load_alloc_pallets =Pallet.find_by_sql("select count(pallets.*) as count,loads.id as load_id
                                      from pallets
                                      inner join load_details on pallets.load_detail_id=load_details.id
                                      inner join load_orders on load_details.load_order_id=load_orders.id
                                      inner join  loads on load_orders.load_id=loads.id
                                      where pallets.allocated IS TRUE and load_orders.order_id=#{@env.session.data['order_id']} group by loads.id ")
        @shipd_pallets =Pallet.find_by_sql("select count(pallets.*) as count,load_details.id as load_detail_id
                                      from pallets
                                      inner join load_details on pallets.load_detail_id=load_details.id
                                      inner join load_orders on load_details.load_order_id=load_orders.id
                                      inner join  loads on load_orders.load_id=loads.id
                                      where  pallets.shipped IS TRUE and load_orders.load_id=#{@env.session.data[:active_doc]['loads']} group by load_details.id ")
      end
      def render_cell(column_name, cell_value, record)
        cell_value=cell_value
        if column_name=="pallets"
          count=@load_alloc_pallets.find_all{|u|u.load_id.to_i==record['id'].to_i}
          if count.empty?
            count =0
          else
            count=count[0]['count']
          end
           cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/view_load_pallets/#{record['id']}", count)
        end

        if column_name=="quantity_available"
          order    =Order.find(@request.session[:active_doc]['orders'].to_i)
          query = record.final_se_query_def
          if query==nil
            quantity_available =0
            cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/cal_quantity_available/#{record['id']}", quantity_available)
          else
            q                  = query.split("from")
            select_clause      ="select count(*) as quantity_available from "
            q2                 = select_clause + q[1]
            q3                 =q2.split("GROUP")
            new_query          =q3[0]
            qq="select distinct pallets.pallet_number ,pallet_sequences.packed_tm_group,pallet_sequences.mark_code, item_pack_products.item_pack_product_code ,commodities.commodity_code,varieties.variety_code, size_counts.size_count_code,grades.grade_code ,fg_products.pack_code from  pallet_sequences left join pallets on pallet_sequences.pallet_id=pallets.id left join stock_items on stock_items.inventory_reference=pallets.pallet_number left join locations on locations.id=stock_items.location_id  left join fg_products on pallet_sequences.fg_product_id=fg_products.id left join item_pack_products on fg_products.item_pack_product_id=item_pack_products.id left join varieties on item_pack_products.variety_id=varieties.id left join commodities on varieties.commodity_id=commodities.id left join size_counts on item_pack_products.size_count_code=size_counts.size_count_code  left join grades on item_pack_products.grade_code=grades.grade_code  left join parties_roles AS parties_s on pallets.supplier_party_role_id=parties_s.id
                where(commodities.commodity_code= '#{record.commodity_code}' and pallet_sequences.packed_tm_group='#{record.packed_tm_group}' and pallet_sequences.mark_code='#{record.mark_code}' and
                varieties.variety_code='#{record.variety_code}' and size_counts.size_count_code='#{record.size_count_code}' and grades.grade_code='#{record.grade_code}'
                AND pallets.load_detail_id is null and pallets.exit_ref IS NULL AND (pallets.shipped IS FALSE OR pallets.shipped IS NULL )AND (pallets.qc_result_status ='PASSED' )
                AND (pallets.intake_headers_production_id IS NOT NULL) AND pallets.qc_status_code ='INSPECTED' AND pallets.error_status IS NULL AND
                (pallets.allocated IS FALSE OR pallets.allocated IS NULL)AND pallets.consignment_note_number IS NOT NULL)"
            quantity_available =ActiveRecord::Base.connection.select_all(qq)
            quantity_available=quantity_available.length
            cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/cal_quantity_available/#{record['id']}", quantity_available)
          end
        end

        if column_name=="quantity_allocated"
          count=@alloc_pallets.find_all{|u|u.load_detail_id.to_i==record.id.to_i}
          if count.empty?
            count =0
          else
            count=count[0]['count']
          end
          cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/li_load_pallets_allocated/#{record['id']}", count)
        end
        if column_name=="quantity_shipped"
          count=@shipd_pallets.find_all{|u|u.load_detail_id.to_i==record.id.to_i}
          if count.empty?
            count =0
          else
            count=count[0]['count']
          end
          cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/li_detail_pallets_shipped/#{record['id']}", count)
        end
        cell_value
      end
    end
  end
end