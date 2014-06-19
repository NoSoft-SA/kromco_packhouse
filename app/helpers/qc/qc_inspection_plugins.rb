require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module Qc::QcInspectionPlugins

  # Plugin for QTYFS form.
  class FormPluginQtyfs

    # Add extra field configs to the QTYFS form.
    def self.customize_configs( field_configs, qc_inspection, options={} )
        field_configs << {:field_type=>'LinkField',:field_name =>'fta_test_values',
                       :settings =>
                      {
                       :host_and_port => options[:request].host_with_port.to_s,
                       :controller    => options[:request].path_parameters['controller'].sub('qc_inspection', 'qc_plugin'),
                       :target_action => 'get_qtyfs_fta_test_values',
                       :id_column=>'id',
                       :link_text => 'import Pressure and Diameter values'}}
        field_configs << {:field_type=>'LinkField',:field_name =>'rfm_test_values',
                       :settings =>
                      {
                       :host_and_port => options[:request].host_with_port.to_s,
                       :controller    => options[:request].path_parameters['controller'].sub('qc_inspection', 'qc_plugin'),
                       :target_action => 'get_qtyfs_rfm_test_values',
                       :id_column=>'id',
                       :link_text => 'import Sugar values'}}
    end

  end

  class ListQcInspectionTestGridPlugin < ApplicationHelper::GridPlugin

    def cancel_cell_rendering(column_name,cell_value,record)
      if column_name == 'delete qc_inspection_test'
        if !record['optional'] || record['optional']== 'f'
          true
        end
      elsif column_name == 'edit qc_inspection_test' && record['status'] == QcInspectionTest::STATUS_COMPLETED
        true
      elsif column_name == 're-edit qc_inspection_test' && record['status'] != QcInspectionTest::STATUS_COMPLETED
        true
      elsif column_name == 'passed' || column_name == 'optional' # Booleans
        if cell_value == 'f' || cell_value == 't'
          true
        end
      end
    end

    #-------------------------------------------------------------------
    #This method allows a plugin to render the cell instead of the
    #grid column. To work, the same plugin must also implmement the
    #'cancel_cell_rendering' method and return true.
    #-------------------------------------------------------------------
    def render_cell(column_name, cell_value, record)
      s = ''
      if column_name == 'passed' || column_name == 'optional'
        if cell_value == 'f'
          s = 'false'
        end
        if cell_value == 't'
          s = 'true'
        end
      end
      s
    end

    def before_cell_render_styling(column_name,cell_value,record)
      color = case record['status']
              when QcInspectionTest::STATUS_CREATED then "orange"
              when QcInspectionTest::STATUS_COMPLETED
                if record['passed']
                  "green"
                else
                  "red"
                end
              else "black"
              end
      "<font color = '#{color}'>"
    end

    #--------------------------------------------------------------------
    #This method is called after the grid has rendered text to the cell
    #The plugin provider should simply simply provide html closing tags
    #for the tags opened during 'before_cell_render_styling'
    #----------------------------------------------
    def after_cell_render_styling(column_name,cell_value,record)
      '</font>'
    end
  end

  class ListBusinessContextGridPlugin < ApplicationHelper::GridPlugin

    def cancel_cell_rendering(column_name,cell_value,record)
      if column_name == 're_edit' && record['status'] != QcInspection::STATUS_COMPLETED
        true
      end
    end

    # #-------------------------------------------------------------------
    # #This method allows a plugin to render the cell instead of the
    # #grid column. To work, the same plugin must also implmement the
    # #'cancel_cell_rendering' method and return true.
    # #-------------------------------------------------------------------
    # def render_cell(column_name, cell_value, record)
    # end

    # def before_cell_render_styling(column_name,cell_value,record)
    # end

    # #--------------------------------------------------------------------
    # #This method is called after the grid has rendered text to the cell
    # #The plugin provider should simply simply provide html closing tags
    # #for the tags opened during 'before_cell_render_styling'
    # #----------------------------------------------
    # def after_cell_render_styling(column_name,cell_value,record)
    # end
  end

end

