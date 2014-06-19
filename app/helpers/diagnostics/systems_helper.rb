module Diagnostics::SystemsHelper

  def build_Luks_name_form(luxolo,action,caption,is_edit = nil,is_create_retry = nil)
  
  	session[:drench_line_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
				 
	js = "\n img = document.getElementById('img_hash_object_drench_line_code');"
	js += "\n if(img != null)img.style.display = 'none';"
	
    #Observers for search combos
	drench_line_code_observer  = {:updated_field_id => "ajax_distributor_cell",
					 :remote_method => 'drench_line_drench_line_code_search_combo_changed',
					 :on_completed_js => js}

	session[:drench_line_search_form][:drench_line_code_observer] = drench_line_code_observer
  
  
     drench_line_codes = DrenchLine.find_by_sql('select distinct drench_line_code from drench_lines').map{|g|[g.drench_line_code]}
     drench_line_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	 
	  field_configs[field_configs.length] =  {:field_type => 'DropDownField',
						:field_name => 'drench_line_code',
						:settings => {:list => drench_line_codes},
						:observer => drench_line_code_observer}

     field_configs[field_configs.length()] = {:field_type => 'HiddenField',
						:field_name => 'ajax_distributor',
						:non_db_field => true}
						
#------------------
#---- building object
hash_result = HashObject.new
builder = ObjectBuilder.new

session[:drench_delivery_form] = Hash.new # The hash to be transformed into an object
session[:drench_delivery_form]['drench_line_code'] = '' 

luxolo = builder.build_hash_object(session[:drench_delivery_form])
#------------------
						
    build_form(luxolo,field_configs,action,'hash_object',caption,is_edit)
  end

end