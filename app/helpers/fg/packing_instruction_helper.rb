module Fg::PackingInstructionHelper


 def build_packing_instruction_form(packing_instruction,action,caption,is_edit = nil,is_create_retry = nil)
#  --------------------------------------------------------------------------------------------------
#  Define a set of observers for each composite foreign key- in effect an observer per combo involved
#  in a composite foreign key
#  --------------------------------------------------------------------------------------------------
  session[:packing_instruction_form]= Hash.new

  shift_type_codes = PackingInstruction.get_all_shift_type_codes
  trading_partners = PackingInstruction.get_trading_partners
#  ---------------------------------
#   Define fields to build form from
#  ---------------------------------
   field_configs = []

  field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'packing_instruction_code'}

  field_configs << {:field_type => 'DropDownField',
                    :field_name => 'shift_type_id',
                    :settings => {:list => shift_type_codes}}

  field_configs << {:field_type => 'DropDownField',
                    :field_name => 'trading_partner_id',
                    :settings => {:list => trading_partners}}

  field_configs << {:field_type => 'PopupDateTimeSelector',
            :field_name => 'pack_date'}

  field_configs << {:field_type => 'TextField',
            :field_name => 'pack_priority'}

    field_configs << {:field_type => 'PopupDateTimeSelector',
                      :field_name => 'ship_date'}
#  ----------------------------------------------------------------------------------------------
#  Combo fields to represent foreign key (shift_type_id) on related table: shift_types
#  ----------------------------------------------------------------------------------------------
  field_configs << {:field_type => 'TextField',
            :field_name => 'remarks'}

    #field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'du', :non_db_field => true, :settings => {:is_separator => false, :static_value => '', :css_class => "borderless_label_field"}}
    field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                             :field_name => '',
                                             :settings => {
                                                 :controller => 'fg/packing_instructions_fg_line_item',
                                                 :target_action => 'create_multi_fg_line_items',
                                                 :link_text => "create fg line items",
                                                 :id_value => packing_instruction.id
                                             }}

    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form3",
                                             :settings =>{
                                                 :controller => 'fg/packing_instructions_bin_line_item',
                                                 :target_action => 'list_packing_instructions_bin_line_items',
                                                 :width => 1200,
                                                 :height => 150,
                                                 :id_value => packing_instruction.id,
                                                 :no_scroll => true
                                             }
    } if packing_instruction

    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form2",
                                             :settings =>{
                                                 :controller => 'fg/packing_instructions_fg_line_item',
                                                 :target_action => 'list_packing_instructions_fg_line_items',
                                                 :width => 1200,
                                                 :height => 150,
                                                 :id_value => packing_instruction.id,
                                                 :no_scroll => true
                                             }
    } if packing_instruction
    @submit_button_align = "left"
    set_form_layout "2", nil, 1, 8

  construct_form(packing_instruction,field_configs,action,'packing_instruction',caption,is_edit)

end


 def build_packing_instruction_search_form(packing_instruction,action,caption,is_flat_search = nil)
#  --------------------------------------------------------------------------------------------------
#  Define an observer for each index field
#  --------------------------------------------------------------------------------------------------
  session[:packing_instruction_search_form]= Hash.new
  #generate javascript for the on_complete ajax event for each combo
  #Observers for search combos
#  ----------------------------------------
#   Define search fields to build form from
#  ----------------------------------------
field_configs = []
  pack_dates = PackingInstruction.find_by_sql('select distinct pack_date from packing_instructions').map{|g|[g.pack_date]}
  field_configs << {:field_type => 'DropDownField',
            :field_name => 'pack_date',
            :settings => {:list => pack_dates}}

  construct_form(packing_instruction,field_configs,action,'packing_instruction',caption,false)

end



 def build_packing_instruction_grid(data_set,can_edit,can_delete)

  column_configs = []
  action_configs = []
#  ----------------------
#  define action columns
#  ----------------------
   grid_command =    {:field_type=>'action',:field_name =>'packing_instruction',
                      :settings =>
                          {
                              :host_and_port =>request.host_with_port.to_s,
                              :controller =>request.path_parameters['controller'].to_s,
                              :target_action =>'new_packing_instruction',
                              :link_text => 'new_packing_instruction',
                              :id_value=>'id'
                          }}
  if can_edit
    action_configs << {:field_type => 'action',:field_name => 'edit packing_instruction',
      :column_caption => 'Edit',
      :settings =>
         {:link_text => 'edit',
        :link_icon => 'edit',
        :target_action => 'edit_packing_instruction',
        :id_column => 'id'}}
  end

    action_configs << {:field_type => 'action',:field_name => 'delete packing_instruction',
      :column_caption => 'Delete',
      :settings =>
         {:link_text => 'delete',
        :link_icon => 'delete',
        :target_action => 'delete_packing_instruction',
        :id_column => 'id'}}

  #action_configs << {:field_type => 'separator'} if can_edit || can_delete

  column_configs << {:field_type => 'action_collection', :field_name => 'actions', :settings => {:actions => action_configs}} unless action_configs.empty?
   column_configs << {:field_type => 'text', :field_name => 'packing_instruction_code', :column_caption => 'Shift type code',:column_width => 200}
   column_configs << {:column_width => 200,:field_type => 'text', :field_name => 'trading_partner', :column_caption => 'Trading partner'}
   column_configs << {:field_type => 'text', :field_name => 'shift_type', :column_caption => 'Shift type'}
  column_configs << {:field_type => 'text', :field_name => 'pack_date', :data_type => 'date', :column_caption => 'Pack date'}
  column_configs << {:field_type => 'text', :field_name => 'ship_date', :data_type => 'date', :column_caption => 'Ship date'}
  column_configs << {:field_type => 'text', :field_name => 'pack_priority', :column_caption => 'Pack priority'}
  column_configs << {:field_type => 'text', :field_name => 'remarks', :column_caption => 'Remarks'}
   column_configs << {:field_type => 'text', :field_name => 'pi_id'}

   column_configs << {:field_type => 'text', :field_name => 'id'}

  get_data_grid(data_set,column_configs,nil,true,grid_command)
end


end
