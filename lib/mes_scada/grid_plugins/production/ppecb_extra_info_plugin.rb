module MesScada::GridPlugins
  module Production
    class PpecbExtraInfoPlugin < MesScada::GridPlugin
      def initialize(env = nil)
        @env     = env
      end

      # def render_cell(column_name,cell_value,record)
      #   if(column_name == "menu_item")
      #     return cell_value +  "[#{@menu_items_friendly_names[record[:menu_item]]}]"
      #   end
      #
      #   return "" #cell_value= @env.text_field('ppecb_inspection', 'inspection_point', {:size=>30,:value=>record[column_name]})
      # end

    end
  end
end
