module MesScada::GridPlugins
  module RmtProcessing
    class PresortGrowerGradingSummaryPlugin < MesScada::GridPlugin

      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)
        if column_name=="delete"
          cell_value= make_action("http://#{@request.host_with_port}/"+"rmt_processing/presort_grower_grading/delete_pool_graded_summary" + "/" + record['id'].to_s,'delete')   if record['status'] != "COMPLETE"
        end
        return cell_value
      end

    end
  end
end