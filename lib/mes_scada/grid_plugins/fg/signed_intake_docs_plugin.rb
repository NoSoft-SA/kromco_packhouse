module MesScada::GridPlugins
  module Fg

    class  SignedIntakeDocsPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env     = env
        @request = request
      end

      def render_cell(column_name, cell_value, record)
          if column_name=="view"
           if File.exists?(File.dirname(__FILE__) + "/../../../public/Downloads/signed_intake_docs/#{record['consignment_note_number']}.pdf")
          cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/view_signed_load_consignment/#{record['consignment_note_number']}","view_intake","view_intake")
           else
             cell_value=nil
           end

          end
        if column_name=="print"
          if File.exists?(File.dirname(__FILE__) + "/../../../public/Downloads/signed_intake_docs/#{record['consignment_note_number']}.pdf")
            cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/print_signed_load_consignment/#{record['consignment_note_number']}","print","print")
          else
            cell_value=nil
            end
          end
        cell_value
      end
    end


  end
end