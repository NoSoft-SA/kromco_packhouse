module MesScada::GridPlugins

  module Qc

    class ListQcInspectionTest < MesScada::GridPlugin

      def render_cell(column_name, cell_value, record)
        case
        when column_name == 'delete qc_inspection_test' && falsy_check(record['optional'])
          ''
        when column_name == 'edit qc_inspection_test' && record['status'] == QcInspectionTest::STATUS_COMPLETED
          ''
        when column_name == 're-edit qc_inspection_test' && record['status'] != QcInspectionTest::STATUS_COMPLETED
          ''
        when column_name == 'edit_orchard_fields' && falsy_check(record['dropdown'])
            ''
        else
          cell_value
        end
      end

      def row_cell_colouring(record)
        case record['status']
        when QcInspectionTest::STATUS_CREATED
          :orange
        when QcInspectionTest::STATUS_COMPLETED
          if record['passed']
            :green
          else
            :red
          end
        else
          nil
        end
      end

    end

  end

end
