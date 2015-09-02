module MesScada::GridPlugins

  module Production

    class PackGroupOutletFormPlugin < MesScada::GridPlugin
      def get_cell_css_class(field_name, record)

        case field_name
          when "color_sort_percentage"
            return "blue_label_field"
          when "grade_code"
            return "blue_label_field"
          when "size_code", "standard_size_count_value"
            return "bold_label_field"
        end

      end

    end

  end

end