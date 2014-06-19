# To change this template, choose Tools | Templates
# and open the template in the editor.
require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module InventoryPlugins
    class GroupedAssetsGridPlugin < ApplicationHelper::GridPlugin
      
      def initialize(env = nil, request = nil)
       @env = env
       @request = request
      end
      
      #---------------------------------------------------------------
      #This method allows the grid-client code to cancel the rendering
      #of a given cell
      #---------------------------------------------------------------
      def cancel_cell_rendering(column_name,cell_value,record)      
        if column_name == "print_report" && (record["transaction_type_code"] == "move_asset_quantity" || record["transaction_type_code"] == "add_asset_quantity" || record["transaction_type_code"] == "remove_asset_quantity")
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
        if(record["transaction_type_code"] == "move_asset_quantity")
          field_config = {:id_value      =>record["id"],
                                         :host_and_port =>@request.host_with_port.to_s,
                                         :controller    =>@request.path_parameters['controller'].to_s,
                                         :target_action => 'view_bins_moved_report',
                                         :link_text     =>'bins moved report'}

          popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', field_config, true, nil, self)
        elsif(record["transaction_type_code"] == "add_asset_quantity")
          field_config = {:id_value      =>record["id"],
                                         :host_and_port =>@request.host_with_port.to_s,
                                         :controller    =>@request.path_parameters['controller'].to_s,
                                         :target_action => 'view_bins_added_report',
                                         :link_text     =>'bins added report'}

          popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', field_config, true, nil, self)
        elsif(record["transaction_type_code"] == "remove_asset_quantity")
          field_config = {:id_value      =>record["id"],
                                         :host_and_port =>@request.host_with_port.to_s,
                                         :controller    =>@request.path_parameters['controller'].to_s,
                                         :target_action => 'view_bins_removed_report',
                                         :link_text     =>'bins removed report'}

          popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', field_config, true, nil, self)
        end
        return popup_link.build_control
      end         
  end
end