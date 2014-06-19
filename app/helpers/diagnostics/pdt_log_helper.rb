module Diagnostics::PdtLogHelper
  
#------------------------------pdt logs grid----------------------------------
  def build_pdt_log_grid(data_set,can_edit,can_delete)
  require File.dirname(__FILE__) + "/../../../app/helpers/diagnostics/pdt_errors_plugin.rb"

	column_configs = Array.new

          column_configs[0] = {:field_type => 'link_window',:field_name => 'view details',
              :settings =>
                {:link_text =>'view details',
                 :target_action => 'view_details_logs',
                 :id_column => 'id',
                 :window_width=>780,
                 :window_height=>730}}

    column_configs[1] = {:field_type => 'text',:field_name => 'user_name'}
	column_configs[2] = {:field_type => 'text',:field_name => 'created_on'}
	column_configs[3] = {:field_type => 'text',:field_name => 'ip'}
	column_configs[4] = {:field_type => 'text',:field_name => 'mode'}
	column_configs[7] = {:field_type => 'text',:field_name => 'input_xml'}
	column_configs[6] = {:field_type => 'text',:field_name => 'output_xml'}
	column_configs[5] = {:field_type => 'text',:field_name => 'menu_item'}


 return get_data_grid(data_set,column_configs,PdtPlugins::PdtLogsPlugin.new(session[:menu_items_friendly_names]))
end

def build_rails_grid(data_set, can_edit, can_delete)

        column_configs = Array.new
        data_set.each do |record|

            if record.description!=nil
                record.description = h(truncate(record.description, Globals.get_diagnostics_truncate_size()))
            end
            if record.stack_trace!=nil
                record.stack_trace = h(truncate(record.stack_trace,Globals.get_diagnostics_truncate_size()))
            end
        end

#         column_configs[0] = {:field_type => 'action',:field_name => 'details',
#      	   :settings =>
#      		 {:link_text =>'view details',
#      		  :target_action => 'view_details',
#      		  :id_column => 'id',
#            :window_width=>780,
#            :window_height=>730}}
        column_configs[0] = {:field_type => 'link_window',:field_name => 'view details',
              :settings =>
                {:link_text =>'view details',
                 :target_action => 'view_details_logs',
                 :id_column => 'id',
                 :window_width=>780,
                 :window_height=>730}}

    	column_configs[1] = {:field_type => 'text',:field_name => 'error_type'}
    	column_configs[2] = {:field_type => 'text',:field_name => 'description'}
    	column_configs[3] = {:field_type => 'text',:field_name => 'stack_trace'}
    	column_configs[4] = {:field_type => 'text',:field_name => 'created_on'}
    	column_configs[5] = {:field_type => 'text',:field_name => 'logged_on_user'}
    	column_configs[6] = {:field_type => 'text',:field_name => 'controller_name'}
    	column_configs[7] = {:field_type => 'text',:field_name => 'action_name'}

           if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit',
			:settings =>
				 {:link_text => 'edit',
				:target_action => 'edit',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete ',
			:settings =>
				 {:link_text => 'delete',
				:target_action => 'delete',
				:id_column => 'id'}}
	end
        return get_data_grid(data_set,column_configs)
end

#--------------------------pdt log search---------------------------------------
  def build_pdt_log_search_form

  session[:pdt_log_form]= Hash.new


   users = User.find_by_sql("select distinct user_name from users").map { |e|[e.user_name]  }
   users.unshift("<empty>")



   field_configs = Array.new
   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'user_name',
						:settings => {:list => users}}


   field_configs[field_configs.length()] =  {:field_type => 'PopupDateTimeSelector',
	                     :field_name => 'created_on_from',
	                     :settings => {:date_textfield_id=>'created_date_from'}}

    field_configs[field_configs.length()] =  {:field_type => 'PopupDateTimeSelector',
	                     :field_name => 'created_on_to',
	                     :settings => {:date_textfield_id=>'created_date_to'}}


    field_configs[field_configs.length()] =  {:field_type => 'TextField',
						:field_name => 'ip'}

    field_configs[field_configs.length()] =  {:field_type => 'TextField',
						:field_name => 'menu_item'}

    field_configs[field_configs.length()] =  {:field_type => 'TextField', :field_name => 'input_xml'}

    field_configs[field_configs.length()] =  {:field_type => 'TextField', :field_name => 'output_xml'}


   field_configs[field_configs.length()] =    {:field_type=>'link_window_field',
            :field_name =>'lookup_menu_items',
                       :settings =>
                      {
                       :target_action => 'look_up_menu_items',
                       :link_text => "Lookup menu items",:id_value => 'id'}}


  build_form(@pdt_logs,field_configs,"pdt_logs_submit",'pdt_logs','submit search')
  end


#------------------------------pdt view error log errors------------------------
  def view_pdt_logs_details_form(pdt_log,action)

      field_configs = Array.new

      field_configs <<  {:field_type => 'LabelField', :field_name => 'user_name'}

      field_configs <<  {:field_type => 'LabelField', :field_name => 'created_on'}

      field_configs <<  {:field_type => 'LabelField', :field_name => 'menu_item'}

      field_configs <<  {:field_type => 'LabelField', :field_name => 'ip'}

      field_configs <<  {:field_type => 'LabelField', :field_name => 'mode'}

#      field_configs << {:field_type => 'LabelField', :field_name => 'input_xml',
#             :settings => {:css_class => 'xml_input_label', :show_label => true,
#             :static_value => pdt_log.input_xml.gsub("<", "&lt;").gsub(">","&gt;") }}
#
#      field_configs << {:field_type => 'LabelField',:field_name =>'output_xml',
#                          :settings => {:css_class => 'xml_output_label', :show_label => true,
#                                       :static_value => pdt_log.output_xml.gsub("<", "&lt;").gsub(">","&gt;") }}


     build_form(pdt_log,field_configs,nil,'pdt_logs',"back")
 end


#---------------------------last 10 pdt logs grid ------------------------------------------
   def build_last_10_pdt_logs_grid (data_set,can_edit, can_delete)
    require File.dirname(__FILE__) + "/../../../app/helpers/diagnostics/pdt_errors_plugin.rb"
 
    column_configs = Array.new

    column_configs << {:field_type => 'link_window',:field_name => 'view details',
        :settings =>
          {:link_text =>'view details',
           :target_action => 'view_details_logs',
           :id_column => 'id',
           :window_width=>780,
           :window_height=>730}}

    column_configs << {:field_type => 'text',:field_name => 'user_name'}
    column_configs[2] = {:field_type => 'text',:field_name => 'created_on'}
    column_configs[3] = {:field_type => 'text',:field_name => 'ip'}
    column_configs[4] = {:field_type => 'text',:field_name => 'mode'}
    column_configs[7] = {:field_type => 'text',:field_name => 'input_xml'}
    column_configs[6] = {:field_type => 'text',:field_name => 'output_xml'}
    column_configs[5] = {:field_type => 'text',:field_name => 'menu_item'}

    return get_data_grid(data_set,column_configs,PdtPlugins::PdtLastTenLogsPlugin.new(session[:menu_items_friendly_names]))
   end


#-----------------------look up menu items logs form -------------------------

   def build_look_up_menu_items_logs_form(program_function,action,caption,is_flat_search= nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:program_function_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["program_function_functional_area_name","program_function_program_name","program_function_name"])
	#Observers for search combos
	functional_area_name_observer  = {:updated_field_id => "program_name_cell",
					 :remote_method => 'program_function_functional_area_name_search_combo_changed',
					 :on_completed_js => search_combos_js["program_function_functional_area_name"]}

	session[:program_function_search_form][:functional_area_name_observer] = functional_area_name_observer

	program_name_observer  = {:updated_field_id => "name_cell",
					 :remote_method => 'program_function_program_name_search_combo_changed',
					 :on_completed_js => search_combos_js["program_function_program_name"]}

	session[:program_function_search_form][:program_name_observer] = program_name_observer


	functional_area_names = ProgramFunction.find_by_sql('select distinct functional_area_name,display_name,is_non_web_program from functional_areas').map{|s| s.functional_area_name + (("[" + s.display_name + "]") if s.is_non_web_program).to_s}
	functional_area_names.unshift("<empty>")
	if is_flat_search
		program_names = ProgramFunction.find_by_sql('select distinct program_name from program_functions').map{|g|[g.program_name]}
		program_names.unshift("<empty>")
		names = ProgramFunction.find_by_sql('select distinct name from program_functions').map{|g|[g.name]}
		names.unshift("<empty>")
		functional_area_name_observer = nil
		program_name_observer = nil
	else
		 program_names = ["Select a value from functional_area_name"]
		 names = ["Select a value from program_name"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'functional_area_name',
						:settings => {:list => functional_area_names},
						:observer => functional_area_name_observer}

	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'program_name',
						:settings => {:list => program_names},
						:observer => program_name_observer}

	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'name',
						:settings => {:list => names}}

	build_form(program_function,field_configs,action,'program_function',caption,false)

end

def build_user_search_form()
   user_names = User.find(:all).map{|s| [s.user_name]}
   user_names.unshift("<empty>")

   session[:pdt_log_form] = Hash.new

   field_configs = Array.new
   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                 :field_name => 'user_name',
                                 :settings => {:label_caption=>'user_name',:list => user_names}}

   build_form(@pdt_logs,field_configs,"user_name_submit",'pdt_logs','submit search')
 end
  

# def build_field(type,value,options={})
#   case type
#     when 'drop_down'
#       width = "width: #{options['width']}px;" if(options['width'])
#       return "<select style=\"#{width}\" disabled=\"disabled\">
#                  <option>#{value}</option>
#               </select>"
#     when 'text_box'
#       return "<input  disabled=\"disabled\" type=\"text\" value=\"#{value}\"/>"
#     when 'check_box'
#       return "<input disabled=\"disabled\" checked=\"checked\" type=\"checkbox\"/>" if(value.to_s == "true")
#       return "<input disabled=\"disabled\" type=\"checkbox\"/>" if(value.to_s == "false")
#     when 'text_line'
#       return "<label>#{value}<label/>"
#     when 'static_text'
#       return "<label>#{value}<label/>"
#   end
# end

end
