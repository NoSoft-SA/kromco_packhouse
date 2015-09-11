module MesScada::GridPlugins

  module Production

    class ScheduleSetupGridPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)
        return cell_value
      end

      def cancel_cell_rendering(column_name, cell_value, record)

      end


      # def render_cell(column_name, cell_value, record)
      #   case
      #     when column_name == "id"
      #       ''
      #     else
      #       cell_value
      #   end
      # end

      def row_cell_colouring(record)
        # color = nil
        case record['production_schedule_status_code']
          when "active"
            return :red
          when "re_opened"
            return :orange
          when "closed"
            return :green
          when "template"
            return :blue
          when "completed"
            return :gray
          else
            return :black
        end
      end

      # #---------------------------------------------------------------
      # def before_cell_render_styling(column_name,cell_value,record)
      #   if column_name == "id"
      #     return
      #   end
      #   if record.production_schedule_status_code == "active"
      #     "<font color = 'red'>"
      #   elsif record.production_schedule_status_code == "re_opened"
      #     "<font color = 'orange'>"
      #   elsif record.production_schedule_status_code == "closed"
      #     "<font color = 'green'>"
      #   elsif record.production_schedule_status_code == "template"
      #     "<font color = 'blue'>"
      #   elsif record.production_schedule_status_code == "completed"
      #     "<font color = 'gray'>"
      #
      #   end
      # end
      # #
      # # #--------------------------------------------------------------------
      # # #This method is called after the grid has rendered text to the cell
      # # #The plugin provider should simply simply provide html closing tags
      # # #for the tags opened during 'before_cell_render_styling'
      # # #----------------------------------------------
      # def after_cell_render_styling(column_name,cell_value,record)
      #   '</font>' if column_name != "id"
      #
      # end
      #
      # def cancel_cell_rendering(column_name,cell_value,record)
      #
      # end

    end

  end

end
