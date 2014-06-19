
require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module DepotReceiptsPlugins

 class IntakeHeaderGridPlugin < ApplicationHelper::GridPlugin
      
      
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)


         color = case record['header_status']
           when "EDI_RECEIVED"  then "gray"
           when "CANCELED" then "lightgray"
           when "HEADER_CREATED","CAPTURING_PALLETS" then "red"
           when "PALLETS_CAPTURED","FRUITSPEC_MAPPED" then "blue"
           when "EDI_SENT", "LOAD_RECEIVED" then "green"
           else "orange"
               
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


  class DepotReceiptPlugin < ApplicationHelper::GridPlugin
    
    def initialize(env = nil, request = nil)
      @env = env
      @request = request
    end
      
      #---------------------------------------------------------------
      #This method allows the grid-client code to cancel the rendering
      #of a given cell
      #---------------------------------------------------------------
      def cancel_cell_rendering(column_name,cell_value,record)
#        if column_name == "show_records"
#          return true
#        else
#          return false
#        end
         return true
      end
      
      #-------------------------------------------------------------------
      #This method allows a plugin to render the cell instead of the
      #grid column. To work, the same plugin must also implmement the
      #'cancel_cell_rendering' method and return true. 
      #-------------------------------------------------------------------
      def render_cell(column_name,cell_value,record)
        #puts " COL NAME IS :::: " + column_name.to_s
        if column_name.to_s == "map"
          return "missing fruit spec data"  if @missing_field
          map_link_url = ""
          if record["mapped?"].to_s == "false"
            map_link_url = @env.link_to("map", "http://" + @request.host_with_port + "/" + "FG/depot_receipts/map_pallet_sequences" + "/" + record["id"].to_s + "!" + record["mapped?"].to_s  , {:class=>'red_link'})
          else
            map_link_url = @env.link_to("map", "http://" + @request.host_with_port + "/" + "FG/depot_receipts/map_pallet_sequences" + "/" + record["id"].to_s + "!" + record["mapped?"].to_s , {:class=>'green_link'})
          end
          return map_link_url
        elsif column_name.to_s == "pallets"
          pallets_link_url = ""
          if record["mapped?"].to_s == "false"
            pallets_link_url = @env.link_to("pallets", "http://" + @request.host_with_port + "/" + "FG/depot_receipts/show_intake_header_pallets" + "/" + record["id"].to_s + "!" + record["mapped?"].to_s , {:class=>'red_link'})
          else
            pallets_link_url = @env.link_to("pallets", "http://" + @request.host_with_port + "/" + "FG/depot_receipts/show_intake_header_pallets" + "/" + record["id"].to_s + "!" + record["mapped?"].to_s , {:class=>'green_link'})
          end
          return pallets_link_url
        else
           if column_name != "extended_fg_code" && (cell_value == nil ||cell_value.strip() == "")
             @missing_field = true
             return "(missing)"
           else
             return record[column_name].to_s
           end

        end
      end
      
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
        if record["mapped?"].to_s == "false"
          style = "<font color='red'>"
        else
          style = "<font color='green'>"
        end

        if cell_value == nil ||cell_value.strip() == ""
          style = "<font color='black'>"
        end
        return style
      end
      
      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        style_close = "</font>"
       
      end

  end


  class PalletSequencePlugin < ApplicationHelper::GridPlugin
    def initialize(env = nil, request = nil)
      @env = env
      @request = request
    end

      #---------------------------------------------------------------
      #This method allows the grid-client code to cancel the rendering
      #of a given cell
      #---------------------------------------------------------------
      def cancel_cell_rendering(column_name,cell_value,record)
#        if column_name == "show_records"
#          return true
#        else
#          return false
#        end
         return true
      end

      #-------------------------------------------------------------------
      #This method allows a plugin to render the cell instead of the
      #grid column. To work, the same plugin must also implmement the
      #'cancel_cell_rendering' method and return true.
      #-------------------------------------------------------------------
      def render_cell(column_name,cell_value,record)
        #puts " COL NAME IS :::: " + column_name.to_s
        if column_name.to_s == "edit"
          map_link_url = ""
          if record["mapped?"].to_s == "false"
            map_link_url = @env.link_to("edit", "http://" + @request.host_with_port + "/" + "FG/depot_receipts/edit_pallet_sequence" + "/" + record["id"].to_s , {:class=>'red_link'})
          else
            map_link_url = @env.link_to("edit", "http://" + @request.host_with_port + "/" + "FG/depot_receipts/edit_pallet_sequence" + "/" + record["id"].to_s , {:class=>'green_link'})
          end
          return map_link_url
        elsif column_name.to_s == "print_labels"
          if record["header_status"] != "LOAD_RECEIVED"
            return "-"
          else
            pallets_link_url = ""
            if record["mapped?"].to_s == "false"
              pallets_link_url = @env.link_to("print", "http://" + @request.host_with_port + "/" + "FG/depot_receipts/print_pallet_labels" + "/" + record["id"].to_s, {:class=>'red_link'})
            else
              pallets_link_url = @env.link_to("print", "http://" + @request.host_with_port + "/" + "FG/depot_receipts/print_pallet_labels" + "/" + record["id"].to_s, {:class=>'green_link'})
            end
            return pallets_link_url
          end
        elsif column_name.to_s == "mapped"
          mapped_link_url = ""
          if record["mapped?"].to_s == "false"
            mapped_link_url = @env.link_to("view", "http://" + @request.host_with_port + "/" + "FG/depot_receipts/view_pallet_sequence" + "/" + record["id"].to_s, {:class=>'red_link'})
          else
            mapped_link_url = @env.link_to("view", "http://" + @request.host_with_port + "/" + "FG/depot_receipts/view_pallet_sequence" + "/" + record["id"].to_s, {:class=>'green_link'})
          end
          return mapped_link_url
        else

          if column_name == "commodity" ||column_name == "variety" || column_name == "grade" || column_name == "class_code" || column_name == "count" || column_name == "pack_type" || column_name == "organization" || column_name == "brand"
            if column_name != "extended_fg_code" && (cell_value == nil ||cell_value.strip() == "")
                return "(missing)"

             end
          end
           return record[column_name].to_s
        end
      end

      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
        if(record["iso_week"].to_i < 0 || record["iso_week"].to_i > 52)
          style = "<font color='red' style='font-weight: bold;'>"
        elsif record["mapped?"].to_s == "false"
          style = "<font color='red'>"
        else
          style = "<font color='green'>"
        end

        if column_name == "commodity" ||column_name == "variety" || column_name == "grade" || column_name == "class_code" || column_name == "count" || column_name == "pack_type" || column_name == "organization" || column_name == "brand"
          if cell_value == nil ||cell_value.strip() == ""
            style = "<font color='black'>"
          end
        end

        return style
        
        
      end

      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        "</font>"
      end

  end

end
