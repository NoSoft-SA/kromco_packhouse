module MesScada::GridPlugins
  module Fg
    class PalletsGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env     = env
        @request = request
      end

      def render_cell(column_name, cell_value, record)
        if !@env.session.data[:current_viewing_order]
          if(column_name=="remarks1" || column_name=="remarks2" || column_name=="remarks3" || column_name=="remarks4" || column_name=="remarks5")
            cell_value= @env.text_field('load_pallet', "#{record['id']}_#{column_name}", {:size=>30,:value=>record[column_name]})
          end
        else
          if column_name=="remarks1"
            cell_value =  record['remarks1']
          elsif column_name=="remarks2"
            cell_value =  record['remarks2']
          elsif column_name=="remarks3"
            cell_value =  record['remarks3']
          elsif column_name=="remarks4"
            cell_value =  record['remarks4']
          elsif column_name=="remarks5"
            cell_value =  record['remarks5']
          end
        end
        return cell_value
      end

      def row_cell_colouring(record)
        if record['holdover_quantity'] !=nil
          if record['holdover_quantity'] > 0
            return :orange
            if record['actual_quantity'] == record['required_quantity']
              return :green
            end
          else
            return :red
          end
        end
     end

    end
  end
end