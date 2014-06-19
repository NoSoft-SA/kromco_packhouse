require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module ReworksPlugins 
class ReworksReceivedCartonsPlugin < ApplicationHelper::GridPlugin
      
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
        @strong_on = false
        style = ""
        record.rw_pallet_action = "" if ! record.rw_pallet_action
        record.reworks_action = "" if ! record.reworks_action
        
        if record.reworks_action.upcase == "ALT_PACKED"
         style = "<font color = 'blue'>"
        elsif record.reworks_action.upcase == "ALT_PACKED_FROM_CARTON"
         style =  "<font color = 'indigo'>"
        elsif record.reworks_action.upcase == "RECLASSIFIED"
         style =  "<font color = 'green'>"
        elsif record.reworks_action.upcase == "SCRAPPED"
         style =  "<font color = 'gray'>"
        elsif record.rw_pallet_action && record.rw_pallet_action != ""
          style =  "<font color = 'orange'>"
        else
          style =  "<font color = 'red'>"
        end
        
        if column_name == "reworks_action"
          @strong_on = true
          style += "<strong>"
        end
        
        if column_name == "rw_pallet_action"
          @strong_on = true
          style += "<strong>"
        end
        
        return style
      end
      
      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        if @strong_on
         "</strong></font>"
        else
          "</font>"
        end
         
      end
      
    
  end
  
    class ReworksReceivedRebinsPlugin < ApplicationHelper::GridPlugin
      
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
       
        style = ""
        
        record.reworks_action = "" if ! record.reworks_action
        
        if record.reworks_action.upcase == "RECLASSIFIED"
         style =  "<font color = 'green'>"
        
        else
          style =  "<font color = 'red'>"
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

        class ReworksReceivedBinsPlugin < ApplicationHelper::GridPlugin

      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)

        style = ""

        record.reworks_action = "" if ! record.reworks_action

        if record.reworks_action.upcase == "RECLASSIFIED"
         style =  "<font color = 'green'>"
         elsif record.reworks_action.upcase == "TIPPED" || record.reworks_action.upcase == "BULK_TIPPED"
            style =  "<font color = 'blue'>"
        else
          style =  "<font color = 'red'>"
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
  
  class ReworksReceivedPalletsPlugin < ApplicationHelper::GridPlugin
      
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
        @strong_on = false
        style = ""
        
        record.reworks_action = "" if ! record.reworks_action
        
        if record.reworks_action.upcase == "ALT_PACKED"
         style = "<font color = 'blue'>"
        elsif record.reworks_action.upcase == "NEW_PALLET"
         style =  "<font color = 'green'>"
        elsif record.reworks_action.upcase == "RECLASSIFIED"
         style =  "<font color = 'green'>"
        elsif record.build_up_balance
          style =  "<font color = 'orange'>"
        else
          style =  "<font color = 'red'>"
        end
        
        if column_name == "reworks_action"
          @strong_on = true
          style += "<strong>"
        end
        
        if column_name == "build_up_balance" && record.build_up_balance
          @strong_on = true
          style =  "<font color = 'orange'>"
          style += "<strong>"
        
        end
        
        
     
        return style
      end
      
      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        if @strong_on
         "</strong></font>"
        else
          "</font>"
        end
         
      end
      
    
  end
  
  ##====================
## Luks' code  =======
##====================
  class ReworksReceivedTippedBinsPlugin < ApplicationHelper::GridPlugin
      
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
       
        style = ""
        
        record.rw_reworks_action = "" if ! record.rw_reworks_action
        
        if record.rw_reworks_action.upcase == "RECLASSIFIED"
         style =  "<font color = 'blue'>"
        
        else
          style =  "<font color = 'red'>"
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
 #==========================

class PalletHistoriesPlugin < ApplicationHelper::GridPlugin

  #---------------------------------------------------------------
  #This method allows the grid-client code to cancel the rendering
  #of a given cell
  #---------------------------------------------------------------
  def cancel_cell_rendering(column_name,cell_value,record)
    if (column_name == "diff" || column_name == "diff_to_carton" || column_name == "diff_to_pallet") && (record['tablename'] != 'rw_reclassed_cartons' && record['tablename'] != 'rw_reclassed_pallets')
      return true
    end
    return false
  end

  #-------------------------------------------------------------------
  #This method allows a plugin to render the cell instead of the
  #grid column. To work, the same plugin must also implmement the
  #'cancel_cell_rendering' method and return true.
  #-------------------------------------------------------------------
  def render_cell(column_name,cell_value,record)
    ""
  end
end

 end