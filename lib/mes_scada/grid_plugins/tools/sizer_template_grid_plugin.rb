module MesScada::GridPlugins

  module Tools

    class SizerTemplateGridPlugin < MesScada::GridPlugin

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
      #   if column_name == "template_name"
      #     return "<font color = 'blue'>"
      #   else
      #     return "<font color = 'black'>"
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