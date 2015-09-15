module MesScada::GridPlugins
  module Fg
    class OrderCustomerGridPlugin < MesScada::GridPlugin

        def initialize(env = nil, request = nil)
          @env = env
          @request = request
        end

        def render_cell(column_name, cell_value, record)
          cell_value=cell_value
          if column_name=="customer_contact_name"
            cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/get_customer_addendum_report/#{record['id']}",record['customer_contact_name'])
          end
          cell_value
        end

    end
  end
end