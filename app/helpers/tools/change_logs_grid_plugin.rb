require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module ToolsPlugins

    class ChangeLogsGridPlugin < ApplicationHelper::GridPlugin
      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end
      #def render_cell(column_name, cell_value, record)
      #  if record['action']=="delete"
      #     cell_value = nil if column_name=="record_before"
      #     cell_value = nil if column_name=="record_after"
      #     cell_value = nil if column_name=="compare"
      #  elsif record['action']=="edit"
      #    cell_value = nil if column_name=="deleted_record"
      #  end
      #  return cell_value
      #end

      def cancel_cell_rendering(column_name,cell_value,record)


        if column_name=="compare"
          if record['action']=="edit"
            return true
          end
        end
        if column_name=="deleted_record"
          if record['action']=="delete"
            return true
          end
        end


      end

      def render_cell(column_name,cell_value,record)
        if column_name=="deleted_record"
          column_config = {:id_value => record['id'],
                           :link_text => "view",
                           :host_and_port => @request.host_with_port.to_s,
                           :controller => @request.path_parameters['controller'].to_s,
                           :target_action => "view_change_log_deleted_record"}
          popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
          return popup_link.build_control
        end
        if column_name=="compare"
          column_config = {:id_value => record['id'],
                           :link_text => "compare",
                           :host_and_port => @request.host_with_port.to_s,
                           :controller => @request.path_parameters['controller'].to_s,
                           :target_action => 'compare_change_logs'}
          popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', column_config, true, nil, self)
          return popup_link.build_control
        end

      end


    end



end