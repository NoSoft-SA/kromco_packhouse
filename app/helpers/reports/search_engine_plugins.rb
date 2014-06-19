 
require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module SearchEnginePlugins

  class SearchEngineGridPlugin < ApplicationHelper::GridPlugin
      
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
        if column_name == "show_records"
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
        if column_name == "show_records"
          id_string = ""
          text = "show records"
          keys = record.keys
          keys.each do |key|
            val = ""
            if record[key].to_s.index(" ")!= nil
              val = record[key].to_s.gsub(" ","se2345se")
            else
              val = record[key].to_s
            end
            if key.to_s.upcase().index("COUNT") == nil && key.to_s.upcase().index("AVG") == nil && key.to_s.upcase().index("SUM") == nil && key.to_s.upcase().index("MIN") == nil && key.to_s.upcase().index("MAX") == nil
              if id_string != ""
                id_string += "!" + key.to_s + "-3457-" + val
              else
                id_string += key.to_s + "-3457-" + val
              end
            end
          end

          link_url = @env.link_to(text, "http://" + @request.host_with_port + "/" + "reports/reports/show_records" + "?id=" + id_string , {:class=>'action_link'})
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
        ""
      end
      
      #--------------------------------------------------------------------
      #This method is called after the grid has rendered text to the cell
      #The plugin provider should simply simply provide html closing tags
      #for the tags opened during 'before_cell_render_styling'
      #----------------------------------------------
      def after_cell_render_styling(column_name,cell_value,record)
        ""
      
      end
  end

end