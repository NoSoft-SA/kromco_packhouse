module MesScada::GridPlugins
  module Fg
    class VoyagePortGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env     = env
        @request = request
        calc_queries
      end

      def calc_queries
        @del_loads=Load.find(:all)


        @loadss=Load.find_by_sql("select DISTINCT loads.* ,load_voyages.voyage_id from loads
                      inner join load_voyages on load_voyages.load_id=loads.id
                      inner join voyages on load_voyages.voyage_id=voyages.id
                       ")
        @pos=Status.find_all_by_status_code_and_status_type_code("TRUCK_LOADED", "loads")

        @pozitions=Status.find_by_sql("select position,status_code from statuses where status_type_code='loads' ")

        @pod_consignments=Load.find_by_sql(
            " select distinct loads.* ,voyage_ports.id as pod_voyage_port_id from loads
                                    inner join load_voyages on load_voyages.load_id=loads.id
                                    inner join load_voyage_ports on load_voyage_ports.load_voyage_id=load_voyages.id
                                    inner join voyage_ports on load_voyage_ports.voyage_port_id=voyage_ports.id
                                    inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
                                    where voyage_port_types.voyage_port_type_code='Arrival'
                                    ")

        @pol_consignments=Load.find_by_sql(
            " select distinct loads.* ,voyage_ports.id as pol_voyage_port_id from loads
                                              inner join load_voyages on load_voyages.load_id=loads.id
                                              inner join load_voyage_ports on load_voyage_ports.load_voyage_id=load_voyages.id
                                              inner join voyage_ports on load_voyage_ports.voyage_port_id=voyage_ports.id
                                              inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
                                                     where voyage_port_types.voyage_port_type_code='Departure'
                                                     ")
      end

      def render_cell(column_name, cell_value, record)
        cell_value=cell_value
        if column_name=="delete_voyage_port"
          cell_value= make_action("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/delete_voyage_port/#{record['id']}","delete")
        end

        if column_name=="port_type_code"
          if record['port_type_code']=="Arrival"
            cell_value= record['port_type_code'] + "(POD)"
          elsif record['port_type_code']=="Departure"
            cell_value= record['port_type_code'] + "(POL)"
          end
        end

        cell_value
      end

      def row_cell_colouring(record)
        colour = nil
        if record['port_type_code']
            if record['port_type_code']=="Arrival"
              return  :blue
            elsif record['port_type_code']=="Departure"
              return  :brown
            end
        end
      end

    end
  end
end