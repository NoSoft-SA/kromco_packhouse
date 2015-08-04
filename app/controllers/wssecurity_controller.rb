class WssecurityController < ApplicationController
	
  #http://localhost:3000/wssecurity/service.wsdl
	
  #wsdl_service_name 'Backend'
  web_service_api WssecurityApi
  web_service_scaffold :invoke

  def authorise_access(program,permission,user_name)
    

    
  	user = User.find(:first,:conditions => ["user_name = ?",user_name])
  	
  	#puts "ws  is: " + user.user_name
  	authorised = authorise(program,permission,user)
  	if authorised
  		return 1
  	else
  		return 0
  	end
  	
  end
  
  def authenticate(user_name,password)
  	user = User.new({:user_name => user_name,:password => password})
  	if user.try_to_login
  		return 1
  	else
  		return 0
  	end
  		
  end
  
end
