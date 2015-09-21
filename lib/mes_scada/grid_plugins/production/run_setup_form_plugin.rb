module MesScada::GridPlugins

  module Production

    class RunSetupFormPlugin < MesScada::GridPlugin

      def no_outlets_defined?(record)
        nothing_done = true
        record.pack_groups.each do |pack_group|
          pack_group.pack_group_outlets.each do |outlet|
            if (outlet.outlet1 != nil && outlet.outlet1 != "n.a") ||(outlet.outlet2 != nil && outlet.outlet2 != "n.a")||(outlet.outlet3 != nil && outlet.outlet3 != "n.a")||(outlet.outlet4 != nil && outlet.outlet4 != "n.a")||(outlet.outlet5 != nil && outlet.outlet5 != "n.a")||(outlet.outlet6 != nil && outlet.outlet6 != "n.a")||(outlet.outlet7 != nil && outlet.outlet7 != "n.a")||(outlet.outlet8 != nil && outlet.outlet8 != "n.a")||(outlet.outlet9 != nil && outlet.outlet9 != "n.a")||(outlet.outlet10 != nil && outlet.outlet10 != "n.a")||(outlet.outlet11 != nil && outlet.outlet11 != "n.a")||(outlet.outlet12 != nil && outlet.outlet12 != "n.a")
              nothing_done = false
              break
            end
          end
        end
        return nothing_done
      end

      def get_cell_css_class(field_name, record)

        case field_name
          when "pack_groups"
            if no_outlets_defined?(record)
              return "red_label_field"
            else
              return "green_label_field"
            end
          when "pack_stations:side A"

            return "blue_label_field"

          when "pack_stations:side B"

            return "blue_label_field"

          when "binfill_stations:side A"

            return "blue_border_label_field"
          when "binfill_stations:side B"

            return "blue_border_label_field"
          when "binfill_sort_stations"

            return "blue_border_no_fill_label_field"

        end

      end


      def override_build?
        false
      end

      def build_control(field_name, active_record, control)

      end
    end

  end

end