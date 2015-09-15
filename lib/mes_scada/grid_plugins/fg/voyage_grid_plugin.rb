module MesScada::GridPlugins
  module Fg
    class VoyageGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env     = env
        @request = request
        calc_queries
      end
      def calc_queries
        @loads=Load.find_by_sql("select DISTINCT loads.* ,load_voyages.voyage_id from loads
                                inner join load_voyages on load_voyages.load_id=loads.id
                                inner join voyages on load_voyages.voyage_id=voyages.id
                                ")
        @pos=Status.find_all_by_status_code_and_status_type_code("TRUCK_LOADED", "loads")

        @pozitions=Status.find_by_sql("select position,status_code from statuses where status_type_code='loads' ")

      end
      #
      #def render_cell(column_name, cell_value, record)
      #  cell_value=cell_value
      #  if column_name=="delete_voyage"
      #    cell_value= make_action("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/delete_voyage/#{record['id'].to_s}",nil,"delete")
      #  end
      #  if column_name=="voyage_completed"
      #   cell_value= make_action("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/complete_voyage/#{record['id'].to_s}",nil,"complete")
      #  end
      #  if column_name=="mates"
      #    cell_value= make_action("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/mates/#{record['id'].to_s}",nil,"mates")
      #  end
      #  cell_value
      #end

      def row_cell_colouring(record)
        colour = nil
        if record['voyage_number']
          loads=@loads.find_all { |k| k.voyage_id.to_i==record.id.to_i }
          if loads.empty?
            return :red
          else
            incomplete_loads=@loads.find_all { |k| k.voyage_id.to_i==record.id.to_i && k.shipped_date_time == nil}
            return  :blue if  incomplete_loads.empty?

            status_codes=loads.map { |s| s.status }
            truck_loaded_position=@pos[0].position
            positions=[]
            shipped=[]
            for status_code in status_codes
              posi=@pozitions.find_all { |t| t.status_code=="#{status_code }" }
              positions << posi[0].position
              shipped << status_code if status_code.upcase=="SHIPPED"
            end
            if shipped.length.to_i==status_codes.length.to_i
              return  :blue
            else
              pos=[]
              for pozi in positions
                if pozi.to_i < truck_loaded_position.to_i
                  pos << pozi
                end
              end
              if pos.empty?
                return  :green
              else
                return  :orange
              end
            end

          end
          end
      end
    end
  end
end