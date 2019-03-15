module MesScada::GridPlugins
  module PartyManager
    class PartyAddressesGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(record)
          return :green if(record.edited == true || record.edited == 't' || record.edited == 'true' || record.edited == '1')
      end

    end
  end
end