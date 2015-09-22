module MesScada::GridPlugins
  module Fg
    class PpecbGridPlugin < MesScada::GridPlugin
      def row_cell_colouring(record)
        if ((record['repacked_pallet_number'].to_s.strip == '') && (record['selected_for_intake'].to_s=='1' || record['selected_for_intake'].to_s=='t' || record['selected_for_intake'].to_s=='true'))
          return :orange
        elsif ((record['repacked_pallet_number'].to_s.strip == '') && (record['passed'].to_s=='1' || record['passed'].to_s=='t' || record['passed'].to_s=='true'))
          return :green
        elsif (record['repacked_pallet_number'].to_s.strip != '')
          return :blue
        else
          return :red
        end
      end

      def render_cell(column_name,cell_value,record)
        if(column_name == "print" && (record['repacked_pallet_number'].to_s.strip == ''))
          return nil
        elsif(column_name == "reinspect" && (record['exit_ref'].to_s.upcase.strip == 'SCRAPPED'))
          return nil
        end
        return cell_value
      end

    end
  end
end