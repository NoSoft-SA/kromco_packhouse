class  Services::AuthenticationController < ApplicationController
 
 
 #format example: http://localhost:3000/services/authentication/authenticate?user=hans&pwd=contact
 
 
def program_name?
	"authentication"
end

def bypass_generic_security?
	true
end

 #=====================================================================
 #This method handles both authentication and authorisation in a single
 #method call using REST as the method encoding  scheme 
 #======================================================================
 def authenticate
 
  user = params[:user]
  pwd = params[:pwd]
  program = params[:program]
  permission = params[:permission]
  
  err = false
  
  
  result = "<result>"
  error = ""
  if user == nil
    error += "user not specified. "
    err = true
  end
  if program == nil && pwd == nil
    error += "pwd not specified. "
    err = true
  end
  
  if err == true
    result += "<error>" + error + "</error>"

    render_result(result)
    return
  end
  
  authenticated = -1
  authorised = -1
  
  begin
  
  if !program
     authenticated = authentic_user?(user,pwd) 
      result += "<authenticated>" + authenticated.to_s + "</authenticated>"
  else
     if !permission
      result += "<error>permission not specified</error>"
     else
       authorised = authorise_access(program,permission,user)
       result += "<authorised>" + authorised.to_s + "</authorised>"
    end
  end
   

   render_result(result)
  rescue
    err = "An unexpected service exception occured. Reported exception: \n" + $!
    result += "<error>" + err + "</error>"
    render_result(result)
    
  end
  
 end
 
 def render_result(result)
  @result = result
  @result += "</result>"
  render :inline => %{
   <%= @result%>
  }
 
 
 end
 
 private
 def authorise_access(program,permission,user_name)
    
    
  	user = User.find(:first,:conditions => ["user_name = ?",user_name])
  	
  	
  	authorised = authorise(program,permission,user)
  	if authorised
  		return 1
  	else
  		return 0
  	end
  	
  end
  
  private
  def authentic_user?(user_name,password)
  	user = User.new({:user_name => user_name,:password => password})
  	if user.try_to_login
  		return 1
  	else
  		return 0
  	end
  		
  end
end
