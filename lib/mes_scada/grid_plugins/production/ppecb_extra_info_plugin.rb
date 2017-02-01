module MesScada::GridPlugins
  module Production
    class PpecbExtraInfoPlugin < MesScada::GridPlugin
      def initialize(env = nil)
        @env     = env
      end

      def render_cell(column_name,cell_value,record)
        if(column_name == "info_value" && record['id']=='bags_or_loose')
          return @env.text_field('ppecb_inspection', 'inspection_point', {:size=>30,:value=>record[column_name]})
        end
        return cell_value
      end

    end
  end
end
