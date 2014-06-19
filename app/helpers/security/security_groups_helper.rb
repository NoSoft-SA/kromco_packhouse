module Security::SecurityGroupsHelper

  def build_sec_group_form(action,submit_caption,send_id = nil)
  	
  	field_configs = Array.new
  	
  	field_configs[0] = {:field_type => 'TextField',
  	                    :field_name => 'security_group_name'}  	                                    
  	build_form(@security_group,field_configs,action,'security_group',submit_caption,send_id)
  	
  end

  def build_add_permission_form(security_group_id)
  
    field_configs = Array.new
      
     permissions = SecurityPermission.find_all().map {|d| [d.security_permission, d.id]}
  	 field_configs[0] = {:field_type => 'DropDownField',
  	                    :field_name => 'permission',
  	                    :settings => {:list => permissions}}
  
    build_form(nil,field_configs,'add_permission_submit','security_group','save',nil,security_group_id)
  
  end
  
def build_security_groups_tree
  
    menu1 = ApplicationHelper::ContextMenu.new("security_groups","security_groups")
    menu1.add_command("Create new security group",url_for(:action => "add_group"))
    
    menu2 = ApplicationHelper::ContextMenu.new("security_group","security_groups")
    menu2.add_command("Delete group",url_for(:action => "delete_group"))
    menu2.add_command("Edit group",url_for(:action => "edit_group"))
    menu2.add_command("Add permission",url_for(:action => "add_permission"))
    menu2.add_command("Clone group",url_for(:action => "clone_group"))

    menu3 = ApplicationHelper::ContextMenu.new("permission","security_groups")
    menu3.add_command("remove permission",url_for(:action => "remove_permission"))


    root_node = ApplicationHelper::TreeNode.new("security_groups","security_groups",true,"security_groups")
    
    #find all security groups and add, for each group:
    #   -> find all permisions and add
    sec_groups = SecurityGroup.find(:all)
    sec_groups.each do |sec_group|
      sec_group_node = root_node.add_child(sec_group.security_group_name,"security_group",sec_group.id.to_s)
      permissions = sec_group.security_permissions
      if permissions != nil
        permissions.each do |permission|
          sec_group_node.add_child(sec_group.security_group_name + " => " + permission.security_permission,"permission",sec_group.id.to_s + "!" + permission.id.to_s)
        end
      end
    end
   

    tree = ApplicationHelper::TreeView.new(root_node,"security_groups")
    tree.add_context_menu(menu1)
    tree.add_context_menu(menu2)
    tree.add_context_menu(menu3)

    
    return tree.render
  
  
  end





end
