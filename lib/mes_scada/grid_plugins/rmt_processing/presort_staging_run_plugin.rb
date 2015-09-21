module MesScada::GridPlugins
  module RmtProcessing
    class PresortStagingRunPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
      @env = env
      @request = request
      end


      def render_cell(column_name,cell_value,record)
        return cell_value
      end

      def row_cell_colouring(record)
        return :lightgray  if record['status'].upcase =='CANCELLED'
        return :gray  if record['status'].upcase =='STAGED'
        return :green  if record['status'].upcase =='ACTIVE'
        return :red  if record['status'].upcase =='EDITING'
      end

    end
  end
end