module MesScada::GridPlugins

  module Reports

    class ListMyViews < MesScada::GridPlugin

      def initialize(request = nil)
        @request = request
      end

      def render_cell(column_name, cell_value, record)
        if column_name == 'webquery'
          make_action("http://#{@request.host_with_port}/webquery/#{record['id']}", 'get link', :css_class => 'copy_webquery_link')
        else
          cell_value
        end
      end
    end

  end

end
