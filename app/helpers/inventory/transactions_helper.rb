module Inventory::TransactionsHelper


  #===============================================================
  # TRANSACTION BUSINESS NAMES
  #===============================================================
  def build_transaction_business_name_form(transaction_business_name,action,caption, is_edit=nil,is_create_retry=nil)
    field_configs = Array.new

	  field_configs[field_configs.length()] = {:field_type=>'TextField', :field_name=>'transaction_business_name_code'}
	 
	  build_form(transaction_business_name,field_configs,action,'transaction_business_name',caption,is_edit)
  end

  def build_transaction_business_names_grid(data_set,can_edit,can_delete)

    	column_configs = Array.new
    	column_configs[0] = {:field_type => 'text',:field_name => 'transaction_business_name_code', :col_width=> 396}

      #	----------------------
      #	define action columns
      #	----------------------
        
      if can_edit
        column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit transaction business name',
          :settings =>
             {:link_text => 'edit',
            :target_action => 'edit_transaction_business_name',
            :id_column => 'id'}}
      end

      if can_delete
        column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete transaction business name',
          :settings =>
             {:link_text => 'delete',
            :target_action => 'delete_transaction_business_name',
            :id_column => 'id'}}
      end
      	
      return get_data_grid(data_set,column_configs)
   end

  

  #===============================================================
  # TRANSACTION TYPES
  #===============================================================
  def build_transaction_type_form(transaction_type,action,caption,is_edit)
    field_configs = Array.new
    
    field_configs[field_configs.size] = {:field_name => 'transaction_type_code', :field_type => 'TextField'}
    field_configs[field_configs.size] = {:field_name => 'transaction_type_description', :field_type => 'TextField'}
 
    
    build_form(transaction_type,field_configs,action,'transaction_type',caption,is_edit)
  end
  
  def build_transaction_types_grid(data_set,can_edit,can_delete)
     column_configs = Array.new
     
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'transaction_type_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'transaction_type_description'}
	
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_transaction_type',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_transaction_type',
				:id_column => 'id'}}
	end
	
	return get_data_grid(data_set,column_configs)
  end
  
  def build_transaction_sub_type_form(transaction_sub_type,action,caption,is_edit)
     transaction_type_code = session[:transaction_type].transaction_type_code
     field_configs = Array.new
    
    field_configs[field_configs.size] = {:field_name => 'transaction_type_code', :field_type => 'LabelField',
                                          :non_db_field => true,
                                          :settings =>{:static_value => transaction_type_code,
                                          :show_label => true}}
    field_configs[field_configs.size] = {:field_name => 'transaction_sub_type_code', :field_type => 'TextField'}
    field_configs[field_configs.size] = {:field_name => 'transaction_sub_type_description', :field_type => 'TextField'}
    
    build_form(transaction_sub_type,field_configs,action,'transaction_sub_type',caption)
  end
  
  def build_transaction_sub_types_grid(data_set,can_edit,can_delete)
    column_configs = Array.new
     
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'transaction_sub_type_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'transaction_sub_type_description'}
	
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_transaction_sub_type',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_transaction_sub_type',
				:id_column => 'id'}}
    end
  
  
	return get_data_grid(data_set,column_configs)
  end
  
#-------------------------------Child Form test-----------------------------------
  def build_child_form_test_form(child_form,action,caption,is_edit)
    field_configs = Array.new
    
    field_configs[field_configs.size] = {:field_name => 'transaction_type_code', :field_type => 'TextField'}
    
#     field_configs[field_configs.length()] = {:field_type => 'ChildForm',
#						:field_name => "child_form2",
#						:settings =>{:target_action => 'populate_top_child_form',
#						             :id_value => '5',
#						             :request => request}}
      field_configs[field_configs.length()] = {:field_type => 'Screen',
						:field_name => "child_form2",
						:settings =>{:target_action => 'populate_top_child_form',
						             :id_value => nil,
						             :request => request}}	
						             
						             
	 field_configs[field_configs.length()] = {:field_type => 'Screen',
						:field_name => "child_form",
						:settings =>{:target_action => nil,
						             :id_value => nil,
						             :request => request}}
						             
    
						             					             
#    field_configs[field_configs.length()] = {:field_type => 'ChildForm',
#						:field_name => "child_form3",
#						:settings =>{:target_action => 'new_transaction_type',
#						             :id_value => nil,
#						             :request => request}}	
    
    build_form(child_form,field_configs,action,'transaction_type',caption)
  end
#-----------------------------------------------------------------------------------
end