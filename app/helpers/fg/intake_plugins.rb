require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module IntakePlugins
class GtinCheckGridPlugin < ApplicationHelper::GridPlugin


      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
        if !record["gtin_found"]
          "<font color = 'red'>"
        elsif record["gtin_found"] && !record["gtin_tm"]
          "<font color = 'orange'>"
        elsif record["gtin_found"] && record["gtin_tm"]
          "<font color = 'green'>"       
        end
      end

      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        '</font>'
      end
  end

  class ListIntakeHeaderGridPlugin < ApplicationHelper::GridPlugin
      def cancel_cell_rendering(column_name,cell_value,record)
        if(record["header_status"] == nil || record["header_status"].to_s.strip == "")
          raise "Validation error: header_status is nil for intake header[#{record["consignment_note_number"]}]"
        elsif(!IntakeHeadersProduction.can_edit?(record["header_status"].upcase) && column_name=="edit")
          true
        elsif(!IntakeHeadersProduction.can_change?(record["header_status"].upcase) && column_name=="change")
          true
        elsif(!IntakeHeadersProduction.can_cancel?(record["header_status"].upcase) && column_name=="cancel")
          true
        elsif(!IntakeHeadersProduction.can_mark_for_delete?(record["header_status"].upcase) && column_name=="mark_for_delete")
          true
        elsif(!IntakeHeadersProduction.can_delete?(record["header_status"].upcase) && column_name=="delete")
          true
        elsif(!IntakeHeadersProduction.can_send_edi?(record["header_status"].upcase) && column_name=="send_edi")
          true
        elsif(!IntakeHeadersProduction.can_print?(record["header_status"].upcase) && column_name=="print")
          true
        elsif(!IntakeHeadersProduction.can_view?(record["header_status"].upcase) && column_name=="view")
          true
        end
      end

      def before_cell_render_styling(column_name,cell_value,record)


         color = case record['header_status']
           when "INTAKE_HEADER_CREATED"  then "red"
           when "INTAKE_HEADER_RECONFIGURING" then "orange"
           when "INTAKE_HEADER_ACCEPTED" then "green"
           when "INTAKE_HEADER_MARKED_FOR_DELETION" then "blue"
           when "INTAKE_HEADER_CANCELLED" then "gray"
           else "black"

          end

         "<font color = '#{color}'>"

      end

      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        '</font>'

      end
  end
  
 end