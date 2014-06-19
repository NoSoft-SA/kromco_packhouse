module QualityControl::GrowerCommitmentHelper

def build_cancel_spray_program_form(spray_program,action,caption)
  field_configs = Array.new

	field_configs[field_configs.length()] = {:field_type => 'TextArea',
						:field_name => 'cancelled_reason',
						:settings => {:cols => 50,:rows => 7}}

  build_form(spray_program,field_configs,action,'spray_program_result',caption)
end

def  build_mrl_cancel_reason_form(mrl_result,action,caption,is_create_retry)
session[:mrl_result_cancel_form]= Hash.new
 field_configs = Array.new
 
	field_configs[field_configs.length()] = {:field_type => 'TextArea',
						:field_name => 'cancelled_reason',
						:settings => {:cols => 50,:rows => 7}}

build_form(mrl_result,field_configs,action,'mrl_result',caption,is_edit = nil,is_create_retry = nil)
end

def build_mrl_result_grid(data_set,can_edit,is_view,can_cancel,can_print_mrl_results)

farm_code = GrowerCommitment.find(session[:grower_commitment_id]).farm_code  
data_set.each do |row|

@orchard_code = row.orchard_code
row.farm_code  =  farm_code
if row.mrl_label_text == nil
row.label_printed = "no"
else
row.label_printed = "yes"
end

end

 require  "app/helpers/quality_control/quality_control_plugins.rb"
	column_configs = Array.new
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'sample_no', :col_width=> 71}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'farm_code', :col_width=> 84}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'orchard_code', :col_width=> 99}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'created_on', :col_width=> 134}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'label_printed',:column_caption => 'label_printed?', :col_width=> 88}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'mrl_result', :col_width=> 76}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'mrl_result_type_code', :col_width=> 151}




#	----------------------
#	define action columns
#	----------------------


  if(can_edit && !is_view)
    column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit_mrl_result', :col_width=> 35,
			:settings =>
				 {:image => 'edit',
          :target_action => 'edit_mrl_result',
				 :id_column => 'id'}}
  end

	if(can_cancel && !is_view)
   	column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'cancel_mrl_result', :col_width=> 35,
			:settings => 
				 {:image => 'cancel',
				 :host_and_port =>request.host_with_port.to_s,
				 :controller =>request.path_parameters['controller'].to_s ,
				 :target_action => 'capture_cancel_mrl_result_reason',
				 :id_column => 'id'}}
  end

  if(can_edit || can_print_mrl_results)
    column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'print_mrl_result', :col_width=> 35,
    :settings =>
       {:image => 'printer',
       :host_and_port =>request.host_with_port.to_s,
       :controller =>request.path_parameters['controller'].to_s ,
       :target_action => 'print_mrl_result',
       :id_column => 'id'}}
  end
  	
 return get_data_grid(data_set,column_configs,QualityControlPlugins::MrlResultGridPlugin.new)
end


def build_mrl_result_form(mrl_result,action,caption,is_edit = nil,is_create_retry = nil )
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:mrl_result_form]= Hash.new

	mrl_result_types_codes = MrlResultType.find_by_sql("select  * from mrl_result_types ").map{|mrl_result_type|[mrl_result_type.mrl_result_type_code]}
	mrl_result_types_codes.unshift("<empty>")


#    mrl_result_codes.unshift("<empty>")

#	---------------------------------|
#	Define fields to build form from |
#	---------------------------------|




	 field_configs = Array.new
     field_configs[field_configs.length()] = {:field_type => 'LabelField',
                      						  :field_name => "farm_code"}

     field_configs[field_configs.length()] = {:field_type => 'LabelField',
                      						  :field_name => "puc_code",
                      						  :settings => {:label_caption => "puc"}}


     field_configs[field_configs.length()] = {:field_type => 'LabelField',
                      						  :field_name => "sample_no"}


  if(mrl_result.mrl_result_type_code)
    mrl_result_types_codes = [mrl_result.mrl_result_type_code]
     field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                   :field_name => 'mrl_result_type_code',
                                   :settings => {:list => mrl_result_types_codes,:label_caption =>"mrl_result_type",:no_empty=>true}}
  else
    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                   :field_name => 'mrl_result_type_code',
                                   :settings => {:list => mrl_result_types_codes,:label_caption =>"mrl_result_type"}}
  end

  if !is_edit #session[:new_delivery] == nil
    mrl_result_codes = ["PENDING"]
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                  :field_name => 'orchard_code'}

#    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
#                                   :field_name => 'mrl_result_type_code',
#                                   :settings => {:list => mrl_result_types_codes,:label_caption =>"mrl_result_type"}}
  else
    mrl_result_codes = ["PENDING", "FAILED", "PASSED"]
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                   :field_name => "orchard_code"}

#    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
#                                 :field_name => 'mrl_result_type_code'}

   end

   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						                       :field_name => 'mrl_result',
						                       :settings => {:list => mrl_result_codes,:no_empty=>true}}


	build_form(mrl_result,field_configs,action,'mrl_result',caption,is_edit)

end
 def build_spray_program_result_form(spray_program_result,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:spray_program_result_form]= Hash.new
	combos_js_for_rmt_varieties = gen_combos_clear_js_for_combos(["spray_program_result_commodity_code","spray_program_result_rmt_variety_code","spray_program_spray_program_code"])

	commodity_code_observer  = {:updated_field_id => "rmt_variety_code_cell",
					            :remote_method => 'spray_program_result_commodity_code_changed',
					            :on_completed_js => combos_js_for_rmt_varieties ["spray_program_result_commodity_code"]}
					 
	session[:spray_program_result_form][:commodity_code_observer] = commodity_code_observer
    spray_program_code_observer  = {:updated_field_id => "spray_result_cell",
					              :remote_method => 'spray_program_spray_program_code_changed',
  					              :on_completed_js => combos_js_for_rmt_varieties ["spray_program_spray_program_code"]}				 

    session[:spray_program_result_form][:spray_program_code_observer] = spray_program_code_observer

	commodity_codes = nil 
	rmt_variety_codes = nil 
	spray_result_list = ["<empty>"]
  spray_program_code = ["<empty>"]
  commodity_codes = SprayProgramResult.get_all_commodity_codes_for_season(GrowerCommitment.find(session[:grower_commitment_id]).season)
	commodity_codes.unshift("<empty>")
	if spray_program_result == nil||is_create_retry
		 rmt_variety_codes = ["<empty>"]
	else
		rmt_variety_codes = SprayProgramResult.rmt_variety_codes_for_commodity_code(spray_program_result.rmt_variety.commodity_code)
    end
    protocols = SprayProgram.find_by_sql("select * from spray_programs").map{|program_code|[program_code.spray_program_code]}
    spray_results = ["PASSED","FAILED"]
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (rmt_variety_id) on related table: rmt_varieties
#	----------------------------------------------------------------------------------------------
if spray_program_result != nil

if  is_create_retry == nil
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                      						 :field_name => "commodity_code"}
                      						   
                      						   
                      						   
                      						   
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                      						 :field_name => "rmt_variety_code"}
                      						 
                      						 
                          						   
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                      						 :field_name => "spray_program_code",
                      						 :settings =>{:label_caption =>"protocol"}}
                      						 

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                      						 :field_name => "spray_result"}


 
			field_configs[field_configs.length()] = {:field_type => 'TextArea',
						:field_name => 'spray_result_comment'}
else
field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'rmt_variety_code',
						:settings => {:list => rmt_variety_codes}}
 


						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'spray_program_code',
						:settings => {:list => protocols,:label_caption =>"protocol"}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'spray_result',
						:settings => {:list => spray_results}}					
						
	field_configs[field_configs.length()] = {:field_type => 'TextArea',
						:field_name => 'spray_result_comment'}
	end					

			
else
field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}
 
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'rmt_variety_code',
						:settings => {:list => rmt_variety_codes}}
 


						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'spray_program_code',
						:settings => {:list => protocols,:label_caption =>"protocol"}}
						
	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'spray_result',
						:settings => {:list => spray_results}}
						
	field_configs[field_configs.length()] = {:field_type => 'TextArea',
						:field_name => 'spray_result_comment'}
end



#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (grower_commitment_id) on related table: grower_commitments
#	-----------------------------------------------------------------------------------------------------

 
	build_form(spray_program_result,field_configs,action,'spray_program_result',caption,is_edit)

end
 
 def build_commitment_form(commitment,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
session[:commitment_form]= Hash.new

commitment_type_codes = CommitmentType.find_by_sql("select distinct(commitment_type_code) from commitment_types").map{|x| [x.commitment_type_code]}
commitment_type_codes.unshift("<empty>")



#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (grower_commitment_id) on related table: grower_commitments
#	-----------------------------------------------------------------------------------------------------


    if commitment != nil && is_create_retry != true
        field_configs[field_configs.length()] = {:field_type => 'LabelField',
                       						 :field_name => "commitment_type_code"}

    else
        field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                            :field_name => 'commitment_type_code',
                            :settings => {:list => commitment_type_codes}}
    end
  
	field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'online_test_completed'}

#  if(!is_edit)
    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                   :field_name => 'certificate_number'}
#  else
#    field_configs[field_configs.length()] = {:field_type => 'LabelField',
#						                     :field_name => 'certificate_number'}
#  end
	field_configs[field_configs.length()] = {:field_type => 'TextField',
					                         :field_name => 'accreditation_body'}

#	field_configs[field_configs.length()] = {:field_type => 'DateTimeField',
#						                     :field_name => 'certificate_expiry_date'}
    field_configs[field_configs.length()] = {:field_type=>'PopupDateSelector', :field_name=>'certificate_expiry_date'}
						
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                       						 :field_name => "transaction_date"}
                       						 
    field_configs[field_configs.length()] = {:field_type => 'TextField',
						                     :field_name => 'variable_1'}
 
	field_configs[field_configs.length()] = {:field_type => 'TextField',
					                       	 :field_name => 'variable_2'} 
            						 
#	----------------------------------------------------------------------------------------------------
#	Combo field to represent foreign key (commitment_type_id) on related table: commitment_types
#	-----------------------------------------------------------------------------------------------------   
	build_form(@commitment,field_configs,action,'commitment',caption,is_edit)

end

def find_grower_commitment(grower_commitment,action,caption,is_flat_search = nil)


	farm_code = GrowerCommitment.get_all_distinct_farms_from_grower_commitment
	farm_code.unshift("<empty>")
	seasons = Season.find_by_sql("select distinct season from seasons").map { |g| [g.season] }

  field_configs = Array.new

  field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                  :field_name => 'farm_code',
                                  :settings => {:list => farm_code}}

  field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                  :field_name => 'season',
                                  :settings => {:list => seasons}}

  field_configs[field_configs.length()] = {:field_type =>'PopupDateRangeSelector',
          :field_name =>'transaction_date'}

  build_form(grower_commitment,field_configs,action,'grower_commitment',caption,false)
end

 def build_grower_commitment_form(grower_commitment,action,caption,can_complete_spray_program_results, can_complete_mrl_results,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:grower_commitment_form]= Hash.new
	farm_codes = Farm.find_by_sql("select distinct(farm_code) from farms").reject{|x| x.farm_code.to_s.strip == ""}.map{|f| [f.farm_code]}
  seasons = Season.find_by_sql("select distinct(season) from seasons").map{|s| [s.season]}

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (farm_id) on related table: farms
#	----------------------------------------------------------------------------------------------
  if(!is_edit && grower_commitment)
    field_configs[field_configs.length()] =  {:field_type => 'LabelField',:field_name => 'farm_code'}

    field_configs[field_configs.length()] =  {:field_type => 'LabelField',:field_name => 'season'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',:field_name => 'commitment_document_delivered'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',:field_name => 'spray_program_document_delivered'}

    date = grower_commitment.transaction_date.strftime("%Y/%m/%d %H:%M:%S") if grower_commitment.transaction_date
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                       						 :field_name => "transaction_date",:settings=>{:static_value=>date.to_s, :show_label=>true}}
    
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                   :field_name => 'variable_1'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
					                       	 :field_name => 'variable_2'}
  else
    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                    :field_name => 'farm_code',
                                    :settings => {:list => farm_codes}}

    field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
                                    :field_name => 'season',
                                    :settings => {:list => seasons}}

    field_configs[field_configs.length()] = {:field_type => 'CheckBox',
                                 :field_name => 'commitment_document_delivered'}

    field_configs[field_configs.length()] = {:field_type => 'CheckBox',
                                 :field_name => 'spray_program_document_delivered'}

    date = grower_commitment.transaction_date.strftime("%Y/%m/%d %H:%M:%S") if grower_commitment && grower_commitment.transaction_date
    field_configs[field_configs.length()] = {:field_type => 'LabelField',
                       						 :field_name => "transaction_date",:settings=>{:static_value=>date.to_s, :show_label=>true}}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
                                   :field_name => 'variable_1'}

    field_configs[field_configs.length()] = {:field_type => 'TextField',
					                       	 :field_name => 'variable_2'}
  end

  if(is_edit && grower_commitment.grower_commitment_data_capture_date_time)
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
					                       	 :field_name => 'grower_commitment_data',
                                   :settings =>{:show_label=>true,:static_value => "completed",
                                   :css_class => 'iframe_table_rows_td'}}
    else
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
					                       	 :field_name => 'grower_commitment_data',
                                   :settings =>{:show_label=>true,:static_value => "not completed",
                                   :css_class => 'iframe_table_rows_td_red'}}
    end

    if(is_edit && grower_commitment.mrl_data_capture_date_time)
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
					                       	 :field_name => 'mrl_data',
                                   :settings =>{:show_label=>true,:static_value => "completed",
                                   :css_class => 'iframe_table_rows_td'}}
    else
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
					                       	 :field_name => 'mrl_data',
                                   :settings =>{:show_label=>true,:static_value => "not completed",
                                   :css_class => 'iframe_table_rows_td_red'}}
    end

   num_controls = 9
  if is_edit || grower_commitment != nil #grower_commitment != nil and is_create_retry != true
    if(is_edit && can_complete_spray_program_results && grower_commitment.grower_commitment_data_capture_date_time == nil)
      num_controls += 1
      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                                   :field_name => '',
                                                   :settings => {
                                                           :target_action => 'complete_spray_program_results',
                                                           :link_text => "complete spray program results",
                                                           :id_value => grower_commitment.id.to_s
                                                   }}
    elsif(is_edit && can_complete_mrl_results && grower_commitment.grower_commitment_data_capture_date_time != nil && grower_commitment.mrl_data_capture_date_time == nil)
      num_controls += 1
      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                                   :field_name => '',
                                                   :settings => {
                                                           :target_action => 'complete_mrl_results',
                                                           :link_text => "complete mrl results",
                                                           :id_value => grower_commitment.id.to_s
                                                   }}
    end

    if(is_edit && can_complete_mrl_results && grower_commitment.grower_commitment_data_capture_date_time != nil && grower_commitment.mrl_data_capture_date_time != nil)
      num_controls += 1
      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                                   :field_name => '',
                                                   :settings => {
                                                           :target_action => 're_open_mrl_results',
                                                           :link_text => "re-open mrl results",
                                                           :id_value => grower_commitment.id.to_s
                                                   }}
    end
    
   field_configs[field_configs.length()] = {:field_type => 'Screen',
                                :field_name => "commitment_form",
                                :settings =>{:target_action => "render_commitment_form",
                                            :width=>980,
                                :id_value =>grower_commitment.id,
                                :request => request}}


      field_configs[field_configs.length()] = {:field_type => 'Screen',
                                :field_name => "list_spray_results_form",
                                :settings =>{:target_action => "render_spray_results",
                                            :width=>980,
                                :id_value =>grower_commitment.id,
                                :request => request}}
  end
	     
      set_form_layout('1',nil,nil,num_controls)
     set_submit_button_align('left')
	build_form(grower_commitment,field_configs,action,'grower_commitment',caption,is_edit)

end
 
 
 def build_grower_commitment_search_form(grower_commitment,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:grower_commitment_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = Array.new
	farm_codes = GrowerCommitment.find_by_sql('select distinct farm_code from grower_commitments').map{|g|[g.farm_code]}
	farm_codes.unshift("<empty>")
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'farm_code',
						:settings => {:list => farm_codes}}

	build_form(grower_commitment,field_configs,action,'grower_commitment',caption,false)

end



 def build_grower_commitment_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'farm_code',:column_caption=>'farm', :col_width=> 48}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'season', :col_width=> 50}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'commitment_document_delivered', :col_width=> 45}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'transaction_date', :col_width=> 134}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'variable_1', :col_width=> 55}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'variable_2', :col_width=> 55}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'grower_commitment_data_capture_date_time', :col_width=> 134}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'mrl_data_capture_date_time', :col_width=> 134}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit_ grower_commitment', :col_width=> 35,
			:settings => 
				 {:image => 'edit',
				:target_action => 'edit_grower_commitment',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete_grower_commitment', :col_width=> 35,
			:settings => 
				 {:image => 'delete',
				:target_action => 'delete_grower_commitment',
				:id_column => 'id'}}
  end

  column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view_grower_commitment', :col_width=> 35,
			:settings =>
				 {:image => 'view',
				:target_action => 'view_grower_commitment',
				:id_column => 'id'}}
   
 return get_data_grid(data_set,column_configs)
end

 def build_list_commitment_grid(data_set,can_edit,can_delete,is_view)

   require "app/helpers/quality_control/grower_commitment_plugins.rb"

  column_configs = Array.new
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'certificate_number', :col_width=> 99}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'accreditation_body', :col_width=> 99}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'variable_1', :col_width=> 55}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'variable_2', :col_width=> 55}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'commitment_type_code', :col_width=> 99}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'online_test_completed', :col_width=> 41}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'certificate_expiry_date', :col_width=> 134}
#	----------------------
#	define action columns
#	----------------------
	if can_edit && !is_view
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit_commitment', :col_width=> 35,
			:settings =>
				 {:image => 'edit',
				:target_action => 'edit_commitment',
				:id_column => 'id'}}
	end

	if can_delete && !is_view
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'remove_commitment', :col_width=> 35,
			:settings => 
				 {:image => 'delete',
				:target_action => 'delete_commitment',
				:id_column => 'id'}}
	end
  set_grid_min_height 130
 return get_data_grid(data_set,column_configs,GrowerCommitmentPlugins::CommitmentGridPlugin.new(self,request))
 end
end
