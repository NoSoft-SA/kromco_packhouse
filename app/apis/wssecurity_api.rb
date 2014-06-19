class WssecurityApi < ActionWebService::API::Base
	
  api_method :authorise_access,
             :expects => [{:program => :string},{:permission => :string},{:user_name => :string}],
             :returns => [:int]
  
  api_method :authenticate,:expects => [{:user_name => :string},{:password => :string}],
             :returns => [:int]
             
end
