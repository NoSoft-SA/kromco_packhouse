class Security::SecurityGroupsController < ApplicationController
  
  def admin_exceptions?
   ["list"]
  
  end
  
  def list
    
    render :template => "security/security_groups/list",:layout => "tree"
  
  end
  
  def clone_group
    id = params[:id]
    security_group = SecurityGroup.find(id)
    new_group=SecurityGroup.new
    new_group.security_group_name=security_group.security_group_name + "_1"
    security_permissions=security_group.security_permissions
    for permission in security_permissions
      new_group.security_permissions.push(permission)
    end
    if new_group.save
            @node_name =  new_group.security_group_name
            @node_id = new_group.id.to_s
            @node_type = "security_group"
            @tree_name = "security_groups"
            flash[:notice]= "Security group #{new_group.security_group_name} created"
            render :inline => %{
                  <% @hide_content_pane = true %>
                  <% @is_menu_loaded_view = true %>
                  <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>
                  },:layout => "tree_node_content"

          else
            @security_group = new_group
            render :template => "security/security_groups/add_group",:layout => "tree_node_content"
          end
  end
   def add_group
  
    @security_group = SecurityGroup.new
    render :template => "security/security_groups/add_group",:layout => "tree_node_content"
    
  end
  
  def edit_group
  
      id = params[:id]
      if id && @security_group = SecurityGroup.find(id)
        render :template => "security/security_groups/edit_group",:layout => "tree_node_content"
      end
  
  end
  
  def remove_permission
  
    ids = params[:id].split("!")
    sec_group = SecurityGroup.find(ids[0].to_i)
    permission = SecurityPermission.find(ids[1].to_i)
    if sec_group.security_permissions.delete(permission)
      flash[:notice] = "permission removed from group"
      render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>
      },:layout => "tree_node_content"
    
    else
      redirect_to_index("permission could not be removed from group")
    end
  end
  
  
  def add_permission
   @security_group_id = params[:id]
   @group_name = SecurityGroup.find(params[:id]).security_group_name
    render :inline => %{
      <% @tree_node_content_header = "add permission to group " + @group_name %>
      <% @is_menu_loaded_view = true %>
      <%= build_add_permission_form(@security_group_id) %>
      },:layout => "tree_node_content"
   #build_add_permission_form(security_group_id)
  
  end
  
  def add_permission_submit
    
    @security_group_id = params[:security_group][:hidden_data].to_i
    sec_group = SecurityGroup.find(@security_group_id)
    permission = SecurityPermission.find(params[:security_group][:permission])
    sec_group.security_permissions.push(permission)
    if sec_group.save
      flash[:notice] = "permission added"
      @node_name = sec_group.security_group_name + " => " + permission.security_permission
      @node_type = "permission"
      @node_id = sec_group.id.to_s + "!" + permission.id.to_s
      @tree_name = "security_groups"
      render :inline => %{
        <% @hide_content_pane = true %>
        <% @is_menu_loaded_view = false %>
        <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>
      },:layout => "tree_node_content"
    else
      redirect_to_index("Permission could not be added")
    
    end
  
  
  end
  
  
  def update_group
  
      id = params[:security_group][:id]
     
      if id && sec_group = SecurityGroup.find(id)
        begin
          
          if sec_group.update_attributes(params[:security_group])
            sec_group.save
           
            flash[:notice] = "Security group updated"
            @new_text = sec_group.security_group_name
            render :template => "security/security_groups/group_updated",:layout => "tree_node_content"
         
          end
        rescue
          session[:alert] = "An error occurred"
          raise $!
        end
      end
  
  end
  
  def delete_group
  
    id = params[:id]
   
      if id && sec_group = SecurityGroup.find(id)
        begin
          sec_group.destroy
          flash[:notice] = "Security #{sec_group.security_group_name} deleted"
          render :template => "security/security_groups/group_deleted",:layout => "tree_node_content"
        rescue
          session[:alert] = "An error occurred"
        end
      end
  
  end
  
  def create_group
    
      security_group = SecurityGroup.new(params[:security_group])
      
      if security_group.save
        @node_name =  security_group.security_group_name
        @node_id = security_group.id.to_s
        @node_type = "security_group"
        @tree_name = "security_groups"
        flash[:notice]= "Security group #{security_group.security_group_name} created"
        render :template => "security/security_groups/group_added",:layout => "tree_node_content"
      else
        @security_group = security_group
        render :template => "security/security_groups/add_group",:layout => "tree_node_content"
      end
    
  end
  
end
