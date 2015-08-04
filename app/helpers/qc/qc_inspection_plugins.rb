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

end

