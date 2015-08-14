module MesScada::GridPlugins
  module RmtProcessing
    class DeliveriesGridPlugin < MesScada::GridPlugin
      def initialize(env = nil, request = nil)
        @env = env
        @request = request
      end

      def render_cell(column_name,cell_value,record)
        return cell_value
      end

      def row_cell_colouring(record)
        if record["unavailable"]
          return :red
        end

        if record["delivery_status"] == "delivery_note_captured"
          return :red
        elsif record["delivery_status"] == "100_fruit_sample_completed "
          return :blue
        elsif record["delivery_status"] == "intake_bin_scan_completed"
          return :green
        elsif record["delivery_status"] == "arrived_at_complex "
          return :grey
        end
      end

    end
  end
end
