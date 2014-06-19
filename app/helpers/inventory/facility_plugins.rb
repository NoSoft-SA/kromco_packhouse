# To change this template, choose Tools | Templates
# and open the template in the editor.
require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module FacilityPlugins
    class LocationsGridPlugin < ApplicationHelper::GridPlugin

      def initialize(env = nil, request = nil)
       @env = env
       @request = request
       #@where_clause = env.session[:search_engine_where_clause].to_s
       #puts "MY WHERE CLAUSE : " + @where_clause.to_s
      end
      #---------------------------------------------------------------
      #This method allows the grid-client code to cancel the rendering
      #of a given cell
      #---------------------------------------------------------------
      def cancel_cell_rendering(column_name,cell_value,record)        
        if column_name == "unavailable" &&  (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
          return true
        else
          return false
        end
      end

      #-------------------------------------------------------------------
      #This method allows a plugin to render the cell instead of the
      #grid column. To work, the same plugin must also implmement the
      #'cancel_cell_rendering' method and return true.
      #-------------------------------------------------------------------
      def render_cell(column_name,cell_value,record)
        if column_name == "unavailable"
          link_url = @env.link_to('false', "http://" + @request.host_with_port + "/" + "inventory/facilities/control_location_availability" + "/" + record['id'].to_s , {:class=>'action_link'})
          return link_url
        end
        return ""
      end
      
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)        
        if record["unavailable"]
          "<font color = 'red'>"
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
end
