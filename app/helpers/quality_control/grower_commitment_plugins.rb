# To change this template, choose Tools | Templates
# and open the template in the editor.
require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module  GrowerCommitmentPlugins
    class CommitmentGridPlugin < ApplicationHelper::GridPlugin
      
      def initialize(env = nil, request = nil)
       @env = env
       @request = request
      end
      
      #---------------------------------------------------------------
      #This method allows the grid-client code to cancel the rendering
      #of a given cell
      #---------------------------------------------------------------
      def cancel_cell_rendering(column_name,cell_value,record)
        if column_name == "edit_commitment" || column_name == "remove_commitment"
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
        if(column_name == "edit_commitment")
          field_config = {:id_value      =>record["id"],
                                         :host_and_port =>@request.host_with_port.to_s,
                                         :controller    =>@request.path_parameters['controller'].to_s,
                                         :target_action => 'edit_commitment',
                                         :link_text     =>'edit'}

          popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', field_config, true, nil, self)          
        elsif(column_name == "remove_commitment")
          field_config = {:id_value      =>record["id"],
                                         :host_and_port =>@request.host_with_port.to_s,
                                         :controller    =>@request.path_parameters['controller'].to_s,
                                         :target_action => 'delete_commitment',
                                         :link_text     =>'delete'}

          popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', field_config, true, nil, self)
        end
        return popup_link.build_control
      end
      
      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)        
        if record["certificate_expiry_date"] < Time.now
          "<font color = 'orange'>"
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


  class SpayProgramResultsGridPlugin < ApplicationHelper::GridPlugin

      def initialize(env = nil, request = nil)
       @env = env
       @request = request
      end

      #---------------------------------------------------------------
      #This method allows the grid-client code to cancel the rendering
      #of a given cell
      #---------------------------------------------------------------
      def cancel_cell_rendering(column_name,cell_value,record)
        if column_name == "cultivar" || column_name == "quality_control" #|| column_name == "remove_commitment"
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
        if(column_name == "cultivar")
          return record.rmt_variety.id.to_s
        elsif(column_name == "edit_commitment")
          field_config = {:id_value      =>record["id"],
                                         :host_and_port =>@request.host_with_port.to_s,
                                         :controller    =>@request.path_parameters['controller'].to_s,
                                         :target_action => 'edit_commitment',
                                         :link_text     =>'edit'}

          popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', field_config, true, nil, self)
          return popup_link.build_control
        elsif(column_name == "remove_commitment")
          field_config = {:id_value      =>record["id"],
                                         :host_and_port =>@request.host_with_port.to_s,
                                         :controller    =>@request.path_parameters['controller'].to_s,
                                         :target_action => 'delete_commitment',
                                         :link_text     =>'delete'}

          popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', field_config, true, nil, self)
          return popup_link.build_control
        end        
      end

      #---------------------------------------------------------------
      #This method allows a user to customize the styling of a cell
      #The calling method will prepend the cell text with the styling
      #string returned by this methodd
      #---------------------------------------------------------------
      def before_cell_render_styling(column_name,cell_value,record)
        if record["spray_result"] == "FAILED"
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