module Diagnostics::ComparerHelper
def build_test_compare_tool_form(comparer,action, caption, is_edit = nil, is_create_retry = nil)
  field_configs = Array.new
  field_configs << {:field_type => 'LinkWindowField', :field_name => '',
                                             :settings => {
                                                     :controller =>"diagnostics/comparer",
                                                     :target_action => 'get_parameters', :link_text => "comparer_tool"
                                                   }}
   build_form(comparer, field_configs,nil, 'comparer', caption, is_edit)
end

end
