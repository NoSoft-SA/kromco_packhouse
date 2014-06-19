

module Security::UsersHelper
	
   
  def build_user_form(action,submit_caption,is_edit = nil)
  	
  	field_configs = Array.new
  	pos = -1
  	if not is_edit
  	 pos += 1
  	 field_configs[pos] = {:field_type => 'DropDownField',
  	                    :field_name => 'person_id',
  	                    :settings => {:list => Person.allEmployees}}
  	 
  	 departments = Department.find_all().map {|d| [d.department_name, d.id]}
  	  pos += 1
  	  field_configs[pos] = {:field_type => 'DropDownField',
  	                    :field_name => 'department',
  	                    :settings => {:list => departments}}
  	 
  	end
  	pos += 1
  	field_configs[pos] = {:field_type => 'TextField',
  	                    :field_name => 'user_name'}
  	pos += 1
  	field_configs[pos] = {:field_type => 'PasswordField',
  	                    :field_name => 'password'}

    pos += 1
      	field_configs[pos] = {:field_type => 'TextField',
      	                    :field_name => 'email_address' }

  	
  	
  	build_form(@user,field_configs,action,'user',submit_caption,is_edit)
  	
  end


  def get_users_grid(data_set)
  	
  	column_configs = Array.new
  	
  	column_configs[0]= {:field_type => "text",:field_name => "user_name"}
  	
  	column_configs[1]= {:field_type => "action",:field_name => "delete user",
  								   :settings => 
  								   		{:link_text => "delete",
  								   		 :target_action => "delete_user",
  								   	     :id_column => "id"} }
  	
  	return get_data_grid(data_set,column_configs)
  	
  end
  
  #--------------------------------------------------------------------------------
  #Something we need to manage in this tree: 
  #Some node types in this tree: functional_areas,programs and permissions will
  #not be unique in the tree if we merely use their record ids', because the
  #same instances of such records or nodes can be shared by many users. So we need
  #something more than just record ids to provide unique node ids- best is to use
  #a session map where an incrementing number is used as key and the value is the real
  #record id of the node
  #--------------------------------------------------------------------------------
  def build_users_tree(users)
   begin
   
    session["users_tree_ids"] = Array.new
    
    menu1 = ApplicationHelper::ContextMenu.new("users","users")
    menu1.add_command("create new user",url_for(:action => "add_user"))
   
    menu2 = ApplicationHelper::ContextMenu.new("user","users")
    menu2.add_command("Delete user",url_for(:action => "delete_user"))
    menu2.add_command("Edit user",url_for(:action => "edit_user"))
    menu2.add_command("Retrieve password",url_for(:action => "get_password"))
    menu2.add_command("Add program",url_for(:action => "add_program"))
    menu2.add_command("Export permissions",url_for(:action=>"export_entire_permissions"))
    
    menu3 = ApplicationHelper::ContextMenu.new("program","users")
    menu3.add_command("Remove program",url_for(:action => "remove_program"))
    #-----------------------------------------
    #Happymore added this context menu item
    #-----------------------------------------
    
    menu3.add_command("Export permissions(Locally)",url_for(:action=>"export_permissions_locally"))
    menu3.add_command("Export permissions(Remotely)",url_for(:action=>"export_permissions_remotely"))
  
    #-----------------------------------------
    #End context menu item
    #-----------------------------------------
     
    menu4 = ApplicationHelper::ContextMenu.new("sec_group","users")
    menu4.add_command("Change security group",url_for(:action => "change_sec_group"))
     
     
    root_node = ApplicationHelper::TreeNode.new("users","users",true,"users")
    users.each do |user|
      user_node = root_node.add_child(user.user_name.chomp,"user",user.id.to_s)
      tree_data = get_progs_by_functional_area(user)
      tree_data.each do |func_area_name,programs|
        func_area_caption = func_area_name.split(",")[0]
        func_area_id = func_area_name.split(",")[1]
        func_area_node = user_node.add_child(func_area_caption,"func_area",func_area_id)
        programs.each do |program|
          prog_node = func_area_node.add_child(program[:name],"program",program[:id])
          group_name =  program[:name] + ": " + program[:sec_group][:sec_group_name]
          sec_group_node = prog_node.add_child(group_name,"sec_group",program[:sec_group][:id])
        end
      end
    end

    tree = ApplicationHelper::TreeView.new(root_node,"users")
    tree.add_context_menu(menu1)
    tree.add_context_menu(menu2)
    tree.add_context_menu(menu3)
    tree.add_context_menu(menu4)
    
    tree.render
   
    rescue
      raise "The users tree could not be rendered. Exception reported is \n" + $!
    end
  end
  
  def build_sec_group_form(action,caption)

	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["sec_group_security_group_name","sec_group_permission"])
	#Observers for search combos
	sec_group_observer  = {:updated_field_id => "permissions_cell",
					 :remote_method => 'sec_group_security_group_name_combo_changed',
					 :on_completed_js => search_combos_js["sec_group_security_group_name"]}


	sec_groups = SecurityGroup.find_by_sql('select distinct security_group_name from security_groups').map{|g|[g.security_group_name]}
	sec_groups.unshift("<empty>")
	
    permissions = ["Select a value from security group to view permissions"]
	
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'security_group_name',
						:settings => {:list => sec_groups},
						:observer => sec_group_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'permissions',
						:settings => {:list => permissions}}
 
	build_form(nil,field_configs,action,'sec_group',caption,false)

end

  def build_add_program_form(action,caption)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:add_program_form]= Hash.new 
	session[:add_program_form][:user_id] = @user_id
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["program_functional_area_name","program_program_name"])
	#Observers for search combos
	functional_area_observer  = {:updated_field_id => "program_name_cell",
					 :remote_method => 'program_functional_area_combo_changed',
					 :on_completed_js => search_combos_js["program_functional_area_name"]}

	session[:add_program_form][:program_functional_area_observer] = functional_area_observer

	functional_areas = FunctionalArea.find_by_sql('select distinct functional_area_name from functional_areas').map{|g|[g.functional_area_name]}
	functional_areas.unshift("<empty>")
	
    program_names = ["Select a value from functional_area"]
	
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'functional_area_name',
						:settings => {:list => functional_areas},
						:observer => functional_area_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'program_name',
						:settings => {:list => program_names}}
 
	build_form(nil,field_configs,action,'program',caption,false)

end


  def build_user_search_form(user,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:user_search_form]= Hash.new 
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js = gen_combos_clear_js_for_combos(["user_department_name","user_last_name","user_first_name","user_user_name"])
	#Observers for search combos
	department_name_observer  = {:updated_field_id => "last_name_cell",
					 :remote_method => 'user_department_name_search_combo_changed',
					 :on_completed_js => search_combos_js["user_department_name"]}

	session[:user_search_form][:department_name_observer] = department_name_observer

	last_name_observer  = {:updated_field_id => "first_name_cell",
					 :remote_method => 'user_last_name_search_combo_changed',
					 :on_completed_js => search_combos_js["user_last_name"]}

	session[:user_search_form][:last_name_observer] = last_name_observer

	first_name_observer  = {:updated_field_id => "user_name_cell",
					 :remote_method => 'user_first_name_search_combo_changed',
					 :on_completed_js => search_combos_js["user_first_name"]}

	session[:user_search_form][:first_name_observer] = first_name_observer

 
	department_names = User.find_by_sql('select distinct department_name from users').map{|g|[g.department_name]}
	department_names.unshift("<empty>")
	if is_flat_search
		last_names = User.find_by_sql('select distinct last_name from users').map{|g|[g.last_name]}
		last_names.unshift("<empty>")
		first_names = User.find_by_sql('select distinct first_name from users').map{|g|[g.first_name]}
		first_names.unshift("<empty>")
		user_names = User.find_by_sql('select distinct user_name from users').map{|g|[g.user_name]}
		user_names.unshift("<empty>")
		department_name_observer = nil
		last_name_observer = nil
		first_name_observer = nil
	else
		 last_names = ["Select a value from department_name"]
		 first_names = ["Select a value from last_name"]
		 user_names = ["Select a value from first_name"]
	end
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
	 field_configs = Array.new
#	----------------------------------------------------------------------------------------------
#	Define search Combo fields to represent the unique index on this table 
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'department_name',
						:settings => {:list => department_names},
						:observer => department_name_observer}
 
	field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'last_name',
						:settings => {:list => last_names},
						:observer => last_name_observer}
 
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'first_name',
						:settings => {:list => first_names},
						:observer => first_name_observer}
 
	field_configs[3] =  {:field_type => 'DropDownField',
						:field_name => 'user_name',
						:settings => {:list => user_names}}
 
	build_form(user,field_configs,action,'user',caption,false)

end

#--------------------------------------------------------------------------------
#This method restructures the user relational data  in a tree format, so
#that a user -> has many functional areas -> has many programs
#--------------------------------------------------------------------------------
def get_progs_by_functional_area(user)
  		
  		tree_data = Hash.new
  		 #if session["users_tree_ids"]== nil
  		
		if not user.nil? 
			    func_areas = Hash.new
		    	user_progs = user.program_users
				user_progs.each do |uprog| 
				    
					func_area = uprog.program.functional_area.functional_area_name
					
					func_area_uid = nil 
					if ! func_areas.has_key?(func_area)
					  #create the func area tree node id as user_id + func_area to make it unique,
					  #since func_area nodes will be repeated across users
					  func_area_uid = user.id.to_s + "_" + uprog.program.functional_area.id.to_s
					  func_areas[func_area]= func_area + "," + func_area_uid
					end
					func_area = func_areas[func_area]
					program = Hash.new
					program_name = uprog.program.program_name
					program_id = uprog.id #don't need the map in this case, we can just use the uprog id
					if uprog.program.display_name != nil
					 if uprog.program.display_name.strip.length > 1
					   program_name = uprog.program.display_name
					 end 
					end
					sec_group_name = uprog.security_group.security_group_name
					session["users_tree_ids"].push(uprog.id)
					sec_group_id = (session["users_tree_ids"].length() -1).to_s
					
					program[:name]= program_name
					program[:id]= program_id.to_s
					program[:sec_group]= Hash.new
					program[:sec_group][:sec_group_name] = sec_group_name
					program[:sec_group][:id]= sec_group_id.to_s
					
					if tree_data.has_key?(func_area)
				    	tree_data[func_area].push program
			   		else
			   		    
			   			tree_data[func_area] = Array.new
			   			tree_data[func_area].push program
			  		end
				end
				
			end
  		  return tree_data
  	end
  	

 def build_user_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'created_at'}
	column_configs[1] = {:field_type => 'text',:field_name => 'updated_at'}
	column_configs[2] = {:field_type => 'text',:field_name => 'department_name'}
	column_configs[3] = {:field_type => 'text',:field_name => 'last_name'}
	column_configs[4] = {:field_type => 'text',:field_name => 'first_name'}
	column_configs[5] = {:field_type => 'text',:field_name => 'user_name'}
  column_configs[6] = {:field_type => 'text',:field_name => 'email_address' }
	column_configs[7] = {:field_type => 'text',:field_name => 'hashed_password'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit user',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_user',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete user',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_user',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
  

#========================================
#===== Luks' request_lock code ==========
#========================================
  def build_request_lock_grid(data_set,can_delete)
  
    
	column_configs = Array.new
	column_configs[column_configs.length] = {:field_type => 'text',:field_name => 'user_id'}
	column_configs[column_configs.length] = {:field_type => 'text',:field_name => 'url'}
    
   #if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete lock',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_request_lock',
				:id_column => 'id'}}
	#end
	
   return get_data_grid(data_set,column_configs)
  end
#========================================

  def build_change_user_password_form(action,submit_caption)

  	field_configs = Array.new
  	  	
  	field_configs[field_configs.length] = {:field_type => 'PasswordField',
  	                    :field_name => 'password',
  	                    :non_db_field => true}
    
#    field_configs[field_configs.length] = {:field_type => 'PasswordField',
#  	                    :field_name => 'new_password',
#  	                    :non_db_field => true}
 
  	build_form(nil,field_configs,action,'user',submit_caption)

  end
end

