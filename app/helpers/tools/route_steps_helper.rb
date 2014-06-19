# To change this template, choose Tools | Templates
# and open the template in the editor.

module Tools::RouteStepsHelper
    def build_list_route_teps(route_step,action,caption)
      #	--------------------------------------------------------------------------------------------------
      #	Define an observer for each index field
      #	--------------------------------------------------------------------------------------------------
       on_complete_js = "\n img = document.getElementById('img_route_steps_route_step_type_code');"
       on_complete_js += "\n if(img != null)img.style.display = 'none';"


       route_step_type_code_observer  = {:updated_field_id => "ajax_distributor_cell",
               :remote_method => 'route_step_type_code_combo_changed',
               :on_complete_js => on_complete_js }


      route_step_types = RouteStepType.find_by_sql("select distinct id,route_step_type_code from route_step_types").map{|g| [g.route_step_type_code,g.id]}
      route_step_types.unshift("<empty>")

      field_configs = Array.new
      field_configs[field_configs.length] = {:field_type=>"DropDownField",:field_name=>"route_step_type_code",
                                             :observer => route_step_type_code_observer,
                                             :settings=>{:list=>route_step_types}}

      field_configs[field_configs.length()] = {:field_type => 'HiddenField',
						:field_name => 'ajax_distributor',
						:non_db_field => true}

      field_configs[field_configs.length()] = {:field_type => 'Screen',
						:field_name => "route_steps_grid_form",
						:settings =>{:target_action => 'render_route_steps_grid_form',:width => 900,:height=>300,:id_value => nil,:caption=>'ss'}}

      @submit_button_align = "left"
      set_form_layout "1",nil,nil,1
          
      build_form(route_step,field_configs,action,'route_steps',caption)
    end

    def build_route_step_form(route_step,action,caption)
      field_configs = Array.new
      field_configs[field_configs.length] = {:field_type=>"TextField",:field_name=>"route_step_code"}
      field_configs[field_configs.length] = {:field_type=>"TextField",:field_name=>"route_step_description"}
      field_configs[field_configs.length] = {:field_type=>"TextField",:field_name=>"sequence_number"}
      
      build_form(route_step,field_configs,action,'route_step',caption)
    end

    def  build_route_steps_grid(route_steps,can_edit,can_delete)
      column_configs = Array.new
      column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'route_step_code'}
      column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'route_step_description'}
      column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'sequence_number'}
    #	----------------------
    #	define action columns
    #	----------------------
      if can_edit
#        column_configs[column_configs.length()] = {:field_type => 'LinkWindowField',:field_name => 'edit route_step',
#          :settings =>
#             {:link_text => 'edit',
#            :target_action => 'edit_route_step',
#            :id_column => 'id'}}
column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'target markets',
			:settings =>
				 {:link_text => 'edit route_step',
				 :host_and_port =>request.host_with_port.to_s,
				 :controller =>request.path_parameters['controller'].to_s ,
				 :target_action => 'edit_route_step',
				 :id_column => 'id'}}
      end

      if can_delete
        column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete route_step',
          :settings =>
             {:link_text => 'delete',
            :target_action => 'delete_route_step',
            :id_column => 'id'}}
      end
      set_grid_min_width(820)
      set_grid_min_height(280)
     return get_data_grid(route_steps,column_configs)
    end
end
