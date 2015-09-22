module MesScada::GridPlugins
  module RmtProcessing
    class BinOrderLoadGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def row_cell_colouring(record)
        colour = nil
        return :red if record['status'].upcase =='LOAD_CREATED'
        return :red if record['status'].upcase =='LOADING'
        return :blue if record['status'].upcase =='COMPLETE'
        return :green if record['status'].upcase =='LOADED'
      end

      def cancel_cell_rendering(column_name, cell_value, record)
        if column_name == "delete" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
          if record['status'].upcase=='LOAD_CREATED'
            return true
          end
        end
      end
      def render_cell(column_name, cell_value, record)
        cell_value=cell_value
        if column_name=="delete"
          cell_value= make_link_window("http://#{@request.host_with_port}/"+"#{@request.path_parameters['controller']}/delete_bin_load/#{record['id']}", 'delete')
        end
        return cell_value
      end


    end
  end
end