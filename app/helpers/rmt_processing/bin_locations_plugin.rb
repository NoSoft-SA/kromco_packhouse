require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module RmtProcessingPlugins
  class BinLocationsPlugin < ApplicationHelper::GridPlugin
    def initialize(env = nil, request = nil)
      @env = env
      @request = request
    end

    def cancel_cell_rendering(column_name, cell_value, record)
      if column_name == "qty_bins_available" && (!cell_value || cell_value == "false" || cell_value.to_s.strip == "")
        return true
      else
        return false
      end
    end

    def render_cell(column_name, cell_value, record)
      if column_name=="qty_bins_available"
        column_config = {:id_value      =>record['location_code'].to_s + "@"  +record['farm_code'].to_s + "@" + record['id'].to_s,
                         :link_text     =>record['qty_bins_available'],
                         :host_and_port =>@request.host_with_port.to_s,
                         :controller    => @request.path_parameters['controller'].to_s,
                         :target_action =>'location_farm_bins'}
        popup_link    = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
        return popup_link.build_control
      end
    end

  end
end