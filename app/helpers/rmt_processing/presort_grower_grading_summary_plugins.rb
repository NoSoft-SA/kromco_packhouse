require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module RmtProcessingPlugins

  #class ProductionRunGridPlugin < ApplicationHelper::GridPlugin
  #
  #  def cancel_cell_rendering(column_name,cell_value,record)
  #    if column_name == 'delete'
  #      if !record['status'].nil?
  #        true
  #      end
  #    end
  #  end
  #
  #end

  class PresortGrowerGradingSummaryPlugin < ApplicationHelper::GridPlugin

    # PoolGradedSummary - cannot delete if complete. Cannot uncomplete unless complete.
    def cancel_cell_rendering(column_name,cell_value,record)
      if column_name == 'delete'
        if record['status'] == "COMPLETE"
          return true
        else
          return false
        end
      elsif column_name == 'uncomplete'
        if record['status'] == "COMPLETE"
          return true
        else
          return false
        end
      end
    end



  end

end


