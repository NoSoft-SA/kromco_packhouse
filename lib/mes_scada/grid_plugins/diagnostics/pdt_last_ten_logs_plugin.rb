module MesScada::GridPlugins
  module Diagnostics
    class PdtLastTenLogsPlugin < MesScada::GridPlugin
      def initialize(menu_items_friendly_names)
        @menu_items_friendly_names = menu_items_friendly_names
      end

      def render_cell(column_name,cell_value,record)
        if(column_name == "menu_item")
          return cell_value +  "[#{@menu_items_friendly_names[record[:menu_item]]}]"
        end

        return cell_value
      end

      def row_cell_colouring(record)

        record.user_name = "" if ! record.user_name

        if record.user_name.upcase == "HANS"
          return :blue
        elsif record.user_name.upcase == "MES"
          return :green
        elsif record.user_name.upcase == "DERRICKW"
          return :purple
        elsif record.user_name.upcase == "GERT"
          return :yellow
        else
          return :red
        end
      end

    end
  end
end
