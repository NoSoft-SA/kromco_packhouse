module MesScada::GridPlugins

  module Production

    class RebinSetupGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(record)
        if record.rebin_label_setup == nil||record.rebin_template == nil
          :red
        else
          :green
        end
      end

    end

  end

end