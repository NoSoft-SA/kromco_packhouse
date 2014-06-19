require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module Reports::ReportsPlugins

  class ListMyViewsGridPlugin < ApplicationHelper::GridPlugin
    
    def initialize(request = nil)
      @request = request
    end

    def cancel_cell_rendering(column_name,cell_value,record)
      if 'webquery' == column_name
				true
      elsif 'edit' == column_name # Only author can edit a view.
				true if record.author_id.to_s != record.current_user_id.to_s
      elsif 'delete' == column_name # Only author can delete a view if only 1 linked user.
				true if record.author_id.to_s != record.current_user_id.to_s || record.users.count > 1
      elsif column_name == 'launch' && record.webquery_only
        true
      elsif column_name == 'spreadsheet' && record.show_parameters
        true
			end
    end

    #-------------------------------------------------------------------
    #This method allows a plugin to render the cell instead of the
    #grid column. To work, the same plugin must also implmement the
    #'cancel_cell_rendering' method and return true.
    #-------------------------------------------------------------------
    def render_cell(column_name, cell_value, record)
      s = ''
      if column_name == 'webquery'
        s = "<a href=\"#\" class=\"action_link\" onclick=\"copyToClipboard('Paste this link in your spreadsheet. ','#{"http://#{@request.host_with_port}/webquery/#{record[:id]}"}');return false;\">get link</a>"
      end
      s
    end

	end

end


