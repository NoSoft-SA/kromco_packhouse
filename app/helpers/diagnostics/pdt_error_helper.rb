module Diagnostics::PdtErrorHelper
  
    #---------------------------View pdt errors-----------------------------------
 def view_pdt_errors_details_form(pdt_error,action)

   field_configs = Array.new

   field_configs <<{:field_type => 'LabelField', :field_name => 'user_name'}

   field_configs << {:field_type => 'LabelField', :field_name => 'created_on'}


    field_configs << {:field_type => 'LabelField', :field_name => 'menu_item'}

   field_configs << {:field_type => 'LabelField', :field_name => 'error_description'}


    field_configs << {:field_type => 'LabelField', :field_name => 'ip'}

    field_configs << {:field_type => 'LabelField', :field_name => 'mode'}

#   field_configs << {:field_type => 'LabelField', :field_name => 'stack_trace',
#                          :settings=>{  :css_class => 'stack_trace_label', :show_label => true,
#                                  :static_value=> pdt_error.stack_trace.gsub!("\n" , "<br>")}}

   field_configs << {:field_type => 'LabelField', :field_name => 'error_type'}


#     field_configs << {:field_type => 'LabelField', :field_name => 'input_xml',
#              :settings => {  :css_class => 'xml_input_label', :show_label => true,
#              :static_value => pdt_error.input_xml.gsub("<", "&lt;").gsub(">","&gt;") }}

       

    build_form(pdt_error,field_configs,nil,'pdt_errors',"back")
end


 #------------------------------pdt error search form---------------------------
 def build_pdt_error_search_form


  session[:pdt_error_form]= Hash.new

   users = User.find_by_sql("select distinct user_name from users").map { |n|[n.user_name]  }
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

   field_configs[field_configs.length()] =  {:field_type => 'TextField', :field_name => 'input_xml' }


   field_configs[field_configs.length()] =    {:field_type=>'link_window_field',
                        :field_name =>'lookup_menu_items',
                        :settings =>
                        {
                        :target_action => 'look_up_menu_items',
                        :link_text => "Lookup menu items",:id_value => 'id'}}

  build_form(@pdt_errors,field_configs,"pdt_errors_submit",'pdt_errors','submit search')
  end


 #----------------------lookup menu items---------------------------------------

 def build_look_up_menu_items_form(program_function,action,caption,is_flat_search= nil)

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


	functional_area_names = ProgramFunction.find_by_sql('select distinct functional_area_name,display_name,is_non_web_program from functional_areas ').map{|s| s.functional_area_name + (("[" + s.display_name + "]") if s.is_non_web_program).to_s}
	#functional_area_names.unshift("<empty>")

	if is_flat_search
		program_names = ProgramFunction.find_by_sql('select distinct program_name from program_functions ').map{|g|[g.display_name '+' 'g.program_name']}
		#program_names.unshift("<empty>")
		names = ProgramFunction.find_by_sql('select distinct name from program_functions').map{|g|[g.display_name '+' 'g.name']}
		#names.unshift("<empty>")
        
		functional_area_name_observer = nil
		program_name_observer = nil
	else
		 program_names = ["Select a value from functional_area_name"]
		 names = ["Select a value from program_name"]
    end
    #SELECT DISTINCT id,voyage_number FROM voyages
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


  def build_program_function_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'name'}
	column_configs[1] = {:field_type => 'text',:field_name => 'description'}
	column_configs[2] = {:field_type => 'text',:field_name => 'display_name'}
	column_configs[3] = {:field_type => 'text',:field_name => 'program_name'}
	column_configs[4] = {:field_type => 'text',:field_name => 'functional_area_name'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit program_function',
			:settings =>
				 {:link_text => 'edit',
				:target_action => 'edit_program_function',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete program_function',
			:settings =>
				 {:link_text => 'delete',
				:target_action => 'delete_program_function',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

 #------------------------ pdt errors grid ------------------------------------------
   def build_pdt_error_grid(data_set,can_edit,can_delete)
    require File.dirname(__FILE__) + "/../../../app/helpers/diagnostics/pdt_errors_plugin.rb"

  	column_configs = Array.new

          column_configs[0] = {:field_type => 'link_window',:field_name => 'view details',
                              :settings =>
                              {:link_text =>'view details',
                               :target_action => 'view_details',
                               :id_column => 'id',
                               :window_width=>990,
                               :window_height=>800}}

     column_configs[1] = {:field_type => 'text',:field_name => 'user_name'}
              column_configs[2] = {:field_type => 'text',:field_name => 'error_description'}
              column_configs[3] = {:field_type => 'text',:field_name => 'stack_trace'}
              column_configs[4] = {:field_type => 'text',:field_name => 'created_on'}
              column_configs[5] = {:field_type => 'text',:field_name => 'menu_item'}
              column_configs[6] = {:field_type => 'text',:field_name => 'error_type'}
              column_configs[7] = {:field_type => 'text',:field_name => 'mode'}
              column_configs[8] = {:field_type => 'text',:field_name => 'input_xml'}
              
 return get_data_grid(data_set,column_configs,PdtPlugins::PdtErrorsPlugin.new)

end

#---------------------------last 10 pdt errors grid ------------------------------------------
   def build_last_10_pdt_errors_grid(data_set,can_edit, can_delete)
     require File.dirname(__FILE__) + "/../../../app/helpers/diagnostics/pdt_errors_plugin.rb"
     

      column_configs = Array.new
      column_configs[0] = {:field_type => 'link_window',:field_name => 'details',
              :settings =>
                {:link_text =>'view details',
                 :target_action => 'view_details',
                 :id_column => 'id',
                 :window_width=>990,
                 :window_height=>800}}

         column_configs[1] = {:field_type => 'text',:field_name => 'user_name'}
         column_configs[2] = {:field_type => 'text',:field_name => 'error_description'}
         column_configs[3] = {:field_type => 'text',:field_name => 'stack_trace'}
         column_configs[4] = {:field_type => 'text',:field_name => 'created_on'}
         column_configs[5] = {:field_type => 'text',:field_name => 'menu_item'}
         column_configs[6] = {:field_type => 'text',:field_name => 'error_type'}
         column_configs[7] = {:field_type => 'text',:field_name => 'mode'}
         column_configs[8] = {:field_type => 'text',:field_name => 'input_xml'}
	     
         
         return get_data_grid(data_set,column_configs,PdtPlugins::PdtErrorsPlugin.new)
   end








end