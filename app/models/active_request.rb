class ActiveRequest

  attr_accessor :user, :program, :function,:env

  def initialize(user, program, function,env)
         @user = user
         @program = program
         @function = function
         @env = env

  end

  @@instance = nil

  def self.set_active_request(user, program, function,env)
    @@instance =  ActiveRequest.new(user, program, function,env)
  end

  def self.get_active_request
    @@instance
  end

  def self.clear_active_request
     @@instance = nil
  end



end