module MesScada::GridPlugins
  module PartyManager
    class OrchardsGridPlugin < MesScada::GridPlugin
      def row_cell_colouring(record)
        return :red if record.parent_orchard_id
      end

      def render_cell(column_name,cell_value,record)
        return nil if(column_name == 'remove' && record['is_child_orchard'] == 'f')
        return cell_value
      end

    end
  end
end