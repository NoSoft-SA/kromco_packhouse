module MesScada::GridPlugins

  module Production

    class PackGroupGridPlugin < MesScada::GridPlugin

      def row_cell_colouring(column_name, cell_value, record)
        nothing_done = true
        record.pack_group_outlets.each do |outlet|
          if (outlet.outlet1 != nil && outlet.outlet1 != "n.a") ||(outlet.outlet2 != nil && outlet.outlet2 != "n.a")||(outlet.outlet3 != nil && outlet.outlet3 != "n.a")||(outlet.outlet4 != nil && outlet.outlet4 != "n.a")||(outlet.outlet5 != nil && outlet.outlet5 != "n.a")||(outlet.outlet6 != nil && outlet.outlet6 != "n.a")||(outlet.outlet7 != nil && outlet.outlet7 != "n.a")||(outlet.outlet8 != nil && outlet.outlet8 != "n.a")||(outlet.outlet9 != nil && outlet.outlet9 != "n.a")||(outlet.outlet10 != nil && outlet.outlet10 != "n.a")||(outlet.outlet11 != nil && outlet.outlet11 != "n.a")||(outlet.outlet12 != nil && outlet.outlet12 != "n.a")
            nothing_done = false
            break
          end
        end

        if nothing_done == false
          :green
        else
          :red
        end
      end

    end

  end

end