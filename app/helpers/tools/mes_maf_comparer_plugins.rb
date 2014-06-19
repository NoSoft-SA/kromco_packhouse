require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'

module MesMafComparerPlugins
  class MesMafBinsComparerGridPlugin  < ApplicationHelper::GridPlugin
    def cancel_cell_rendering(column_name,cell_value,record)
      if column_name == "view_bin" && !record['mes_bin']
        return true
      end
      return false
    end
  end
end
