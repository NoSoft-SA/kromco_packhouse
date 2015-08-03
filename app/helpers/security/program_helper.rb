module Security::ProgramHelper


 def build_program_form(program,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:program_form]= Hash.new
	functional_area_names = FunctionalArea.find_by_sql('select distinct functional_area_name from functional_areas').map{|g|[g.functional_area_name]}
	functional_area_names.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'program_name'}

#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (functional_area_id) on related table: functional_areas
#	-----------------------------------------------------------------------------------------------------
	field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'functional_area_name',
						:settings => {:list => functional_area_names}}


	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'display_name'}

    field_configs << {:field_type => 'TextField',
						:field_name => 'url_component'}

	field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'func_area_url_component'}


   field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'class_name'}



     field_configs[field_configs.length] = {:field_type => 'CheckBox',
						:field_name => 'is_non_web_program'}

     field_configs[field_configs.length] = {:field_type => 'CheckBox',
						:field_name => 'disabled'}

     field_configs[field_configs.length] = {:field_type => 'CheckBox',
						:field_name => 'is_leaf'}

	build_form(program,field_configs,action,'program',caption,is_edit)

end


 def build_program_search_form(program,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:program_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["program_program_name","program_functional_area_name"])
	#Observers for search combos
	program_name_observer  = {:updated_field_id => "functional_area_name_cell",
					 :remote_method => 'program_program_name_search_combo_changed',
					 :on_completed_js => search_combos_js["program_program_name"]}

	session[:program_search_form][:program_name_observer] = program_name_observer


	program_names = Program.find_by_sql('select distinct program_name from programs').map{|g|[g.program_name]}
	program_names.unshift("<empty>")
	if is_flat_search
		functional_area_names = Program.find_by_sql('select distinct functional_area_name from programs').map{|g|[g.functional_area_name]}
		functional_area_names.unshift("<empty>")
		program_name_observer = nil
	else
		 functional_area_names = ["Select a value from program_name"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'program_name',
						:settings => {:list => program_names},
						:observer => program_name_observer}

	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'functional_area_name',
						:settings => {:list => functional_area_names}}

	build_form(program,field_configs,action,'program',caption,false)

end



 def build_program_grid(data_set,can_edit,can_delete)

  column_configs = []
  action_configs = []
#  ----------------------
#  define action columns
#  ----------------------
  if can_edit
    action_configs << {:field_type => 'action',:field_name => 'edit program',
      :column_caption => 'Edit',
      :settings =>
         {:link_text => 'edit',
        :link_icon => 'edit',
        :target_action => 'edit_program',
        :id_column => 'id'}}
  end

  if can_delete
    action_configs << {:field_type => 'action',:field_name => 'delete program',
      :column_caption => 'Delete',
      :settings =>
         {:link_text => 'delete',
        :link_icon => 'delete',
        :target_action => 'delete_program',
        :id_column => 'id'}}
  end

  action_configs << {:field_type => 'separator'} if can_edit || can_delete

	action_configs << {:field_type => 'action',:field_name => 'export to remote db',
			:settings =>
				 {:link_text => 'export program',
        :link_icon => 'exec1',
        :target_action => 'export_program',
				:id_column => 'id'}}

  if can_edit
    action_configs << {:field_type => 'action',:field_name => 'reorder_prog_funcs',
        :settings =>
           {:link_text => 'Re-order program functions',
          :link_icon => 'refresh',
          :target_action => 'reorder_program_functions',
          :id_column => 'id'}}
  end


  column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?

  column_configs << {:field_type => 'text', :field_name => 'program_name', :column_caption => 'Program name', :column_width => 150}
  column_configs << {:field_type => 'text', :field_name => 'functional_area_name', :column_caption => 'Functional area name', :column_width => 150}
  column_configs << {:field_type => 'text', :field_name => 'display_name', :column_caption => 'Display name', :column_width => 150}
  column_configs << {:field_type => 'text', :field_name => 'description', :column_caption => 'Description'}
  column_configs << {:field_type => 'text', :field_name => 'technology', :column_caption => 'Technology'}
  column_configs << {:field_type => 'text', :field_name => 'is_non_web_program', :data_type => 'boolean', :column_caption => 'Is non web program'}
  column_configs << {:field_type => 'text', :field_name => 'class_name', :column_caption => 'Class name'}
  column_configs << {:field_type => 'text', :field_name => 'disabled', :data_type => 'boolean', :column_caption => 'Disabled'}
  column_configs << {:field_type => 'text', :field_name => 'is_leaf', :data_type => 'boolean', :column_caption => 'Is leaf'}
  column_configs << {:field_type => 'text', :field_name => 'url_component', :column_caption => 'Url component'}
  column_configs << {:field_type => 'text', :field_name => 'func_area_url_component', :column_caption => 'Func area url component'}

  get_data_grid(data_set,column_configs)
end

 def build_load_program_form(program,action,caption)
  #	----------------------------------------
  #	 Define search fields to build form from
  #	----------------------------------------
	 field_configs = Array.new
   field_configs[field_configs.length] = {:field_type => 'TextField',
						:field_name => 'program_settings_file'}

	build_form(program,field_configs,action,'program',caption)
 end

end
