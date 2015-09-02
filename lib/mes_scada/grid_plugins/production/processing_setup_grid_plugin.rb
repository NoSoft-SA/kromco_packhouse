module MesScada::GridPlugins

  module Production

    class ProcessingSetupGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(record)
        if record.handling_product_type_code.upcase == "REBIN"
            :blue
        else
            :brown
        end
      end

    end

  end

end