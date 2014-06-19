class Security::PermissionsController < ApplicationController

  def admin_exceptions?
  		["list","add"]
  end
  
  
  def program_name?
   "permissions"
  end
  
  
  def bypass_generic_security?
	false
   end
  
  def list
 
   @permissions = SecurityPermission.find(:all)
    render :template => "security/permissions/list",:layout => "content"
  end
  
  def add
  
    @permission = SecurityPermission.new
     render :template => "security/permissions/add",:layout => "content"
    
  end
  
  def create
    
      permission = SecurityPermission.new(params[:permission])
      if permission.save
        redirect_to_index("Permission #{permission.security_permission} created","permission created")
      end
    
  end
  
  
  def delete_permission
      id = params[:id]
   
      if id && permission = SecurityPermission.find(id)
        begin
          permission.destroy
          session[:alert] = "Permission #{permission.security_permission} deleted"
        rescue
          session[:alert] = "Can't delete that permission"
        end
      end
       @permissions = SecurityPermission.find(:all)
       render :template => "security/permissions/list",:layout => "content"
  
  end
  
  
end
