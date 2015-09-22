module MesScada::GridPlugins

  module Tools

    class CountsDropsTemplateGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)
        return cell_value
      end

      def cancel_cell_rendering(column_name, cell_value, record)

      end

      def row_cell_colouring(record)

      end

      # def before_cell_render_styling(column_name,cell_value,record)
      #   if column_name == "standard_size_count_value"
      #     return "<font color = 'blue'>"
      #   elsif column_name == "size_code"
      #     return "<font color = 'indigo'>"
      #   elsif column_name.index("outlet") && cell_value && cell_value != "n.a"
      #     return "<font color = 'green'>"
      #   else
      #     return "<font color = 'gray'>"
      #   end
      #
      # end
      # def after_cell_render_styling(column_name,cell_value,record)
      #   "</font>"
      #
      # end

    end

  end

end