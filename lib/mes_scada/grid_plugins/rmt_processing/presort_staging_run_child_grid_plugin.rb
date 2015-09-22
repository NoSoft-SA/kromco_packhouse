module MesScada::GridPlugins
  module RmtProcessing
    class PresortStagingRunChildGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env = env
        @request = request
        @parent=PresortStagingRun.find(env.session.data[:active_doc]['presort_staging_run'])
      end


      def before_cell_render_styling(column_name, cell_value, record)
        if column_name=="id"
        else
          return "<font color = 'light gray'>"  if record['status'].upcase =='CANCELLED'
          return "<font color = 'gray'>"  if record['status'].upcase =='STAGED'
          return "<font color = 'green'>"  if record['status'].upcase =='ACTIVE'
          return "<font color = 'red'>"  if record['status'].upcase =='EDITING'
        end
      end

    end
  end
end