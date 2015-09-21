module MesScada::GridPlugins

  module Production

    class CartonSetupFormPlugin < ApplicationHelper::FormPlugin

      #-------------------------------------------------------------------------
      #This method allows client-code to set the css-class of the containing td
      #-------------------------------------------------------------------------
      def get_cell_css_class(field_name,record)

        case field_name
          when  "retail_item_setup"
            if record.retail_item_setup
              return "green_label_field"
            else
              return "red_label_field"
            end

          when  "carton_setup_code"
            return "blue_border_label_field"

          when  "retail_unit_setup"
            if record.retail_unit_setup
              return "green_label_field"
            else
              return "red_label_field"
            end

          when  "trade_unit_setup"
            if record.trade_unit_setup
              return "green_label_field"
            else
              return "red_label_field"
            end

          when  "fg_setup"
            if record.fg_setup
              return "green_label_field"
            else
              return "red_label_field"
            end

          when  "pallet_setup"
            if record.pallet_setup
              return "green_label_field"
            else
              return "red_label_field"
            end

          when  "palletizing_criteria_setup"
            if record.palletizing_criterium
              return "green_label_field"
            else
              return "red_label_field"
            end

        end

      end

      def override_build?
        true
      end

      def build_control(field_name,active_record,control)

        if field_name == "trade_unit_setup" && !active_record.retail_item_setup
          if !active_record.retail_unit_setup
            return "dependent on retail item setup and retail unit setup"
          else
            return "dependent on retail item"
          end

        elsif field_name == "trade_unit_setup" && !active_record.retail_unit_setup
          return "dependent on retail unit setup"

        elsif field_name == "retail_item_setup" && !active_record.grade_code
          return "dependent on grade (not yet set)"

        elsif field_name == "retail_unit_setup" && !active_record.retail_item_setup
          return "dependent on retail item setup"

        elsif field_name == "pallet_setup" && !active_record.trade_unit_setup
          return "dependent on trade unit setup"

        elsif field_name == "fg_setup" && (!active_record.retail_item_setup ||!active_record.trade_unit_setup ||!active_record.retail_unit_setup)

          deps = "dependent on setups: "
          deps += "retail item," if !active_record.retail_item_setup
          deps += "retail unit," if !active_record.retail_unit_setup
          deps += "trade unit," if !active_record.trade_unit_setup

          return deps.slice(0,deps.length()-1)
        else
          return nil
        end
      end

    end

  end

end