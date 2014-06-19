require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module RmtProcessing::GrowerGradingPlugins

  class ProductionRunGridPlugin < ApplicationHelper::GridPlugin

    # ProductionRun - cannot create a grower grading that already exists
    def cancel_cell_rendering(column_name,cell_value,record)
      if column_name == 'grower grading'
        if !record['status'].nil?
          true
        end
      end
    end

  end

  class PoolGradedSummaryGridPlugin < ApplicationHelper::GridPlugin

    # PoolGradedSummary - cannot delete if complete. Cannot uncomplete unless complete.
    def cancel_cell_rendering(column_name,cell_value,record)
      if column_name == 'delete pool_graded_summary'
        if record['status'] == PoolGradedSummary::STATUS_COMPLETE
          true
        end
      elsif column_name == 'uncomplete pool_graded_summary'
        if record['status'] != PoolGradedSummary::STATUS_COMPLETE
          true
        end
      end
    end

  end

end


