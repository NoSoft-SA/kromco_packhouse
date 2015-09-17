module MesScada::GridPlugins

  module Fg

    class ListIntakeHeaderGridPlugin < MesScada::GridPlugin

      def render_cell(column_name,cell_value,record)
        if(record["header_status"] == nil || record["header_status"].to_s.strip == "")
          raise "Validation error: header_status is nil for intake header[#{record["consignment_note_number"]}]"
        elsif(!IntakeHeadersProduction.can_edit?(record["header_status"].upcase) && column_name=="edit")
          return nil
        elsif(!IntakeHeadersProduction.can_change?(record["header_status"].upcase) && column_name=="change")
          return nil
        elsif(!IntakeHeadersProduction.can_cancel?(record["header_status"].upcase) && column_name=="cancel")
          return nil
        elsif(!IntakeHeadersProduction.can_mark_for_delete?(record["header_status"].upcase) && column_name=="mark_for_delete")
          return nil
        elsif(!IntakeHeadersProduction.can_delete?(record["header_status"].upcase) && column_name=="delete")
          return nil
        elsif(!IntakeHeadersProduction.can_send_edi?(record["header_status"].upcase) && column_name=="send_edi")
          return nil
        elsif(!IntakeHeadersProduction.can_print?(record["header_status"].upcase) && column_name=="print")
          return nil
        elsif(!IntakeHeadersProduction.can_view?(record["header_status"].upcase) && column_name=="view")
          return nil
        else
          return cell_value
        end
      end

      def row_cell_colouring(record)
        if record["header_status"].to_s.upcase == "INTAKE_HEADER_CREATED"
          return :red
        elsif record["header_status"].to_s.upcase == "INTAKE_HEADER_RECONFIGURING"
          return :orange
        elsif record["header_status"].to_s.upcase == "INTAKE_HEADER_MARKED_FOR_DELETION"
          return :blue
        elsif record["header_status"].to_s.upcase == "INTAKE_HEADER_ACCEPTED"
          return :green
        elsif record["header_status"].to_s.upcase == "INTAKE_HEADER_CANCELLED"
          return :gray
        end
      end
      
    end

  end
end
