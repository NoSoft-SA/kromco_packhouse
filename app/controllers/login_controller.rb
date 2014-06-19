

class LoginController < ApplicationController

  layout "home"
  
  
  
  def logged_in
  	
  	
  end
  
  def progress_test
    
    for i in 1..10000
     
     puts "hello hans eks nou by nommer " + i.to_s
    
    end
    
    redirect_to_index("server test task completed")
  
  end
  
  

  
  def login()
     
#    if params[:id] && params[:id]== "messages"
#      messages
#      return
#    end
    
    
    if session[:user_id]!= nil
      flash[:notice] = " A user from this browser is already logged in"
      render :template => "login/index",:layout => "home"
      return
    end
    
    if request.get?
      puts "login try"
      reset_session
      puts "session reset"
      session[:user_id] = nil
      puts session[:user_id].to_s
      @user = User.new
      flash[:notice] = "Please log in"
       
    else
     
      @user = User.new(params[:user])
      logged_in_user = @user.try_to_login
    
      if logged_in_user
          puts "logged in: " + logged_in_user.to_s
        session[:user_id] = logged_in_user
        
       # TasksThread.Process_tasks_queue #start the tasks processing thread
       
      	redirect_to(:action => "logged_in")
      	
      else
        puts "invalid user"
        flash[:notice] = "Invalid user/password combination"
      end
    end
  end
  
  # Add a new user to the database.
  
  def denied
  	
  	puts "in denied"
  	flash[:notice] = "You don't have permission to perform this action"
  	
  	#@page_title = "Access Denied!"
  	render :template => "login/denied",:layout => "content"
  end
  
  def index
  	@page_title = session[:page_title] if session[:page_title] != nil
  	session[:page_title]= nil
  end
  
  	
#  def add_user
#    
#   # authorise "users","admin"
#    #puts "menu js from add_user: " + @menus_js
#    
#    if request.get?
#      @user = User.new
#    else
#      @user = User.new(params[:user])
#      user= params[:user]
#      pid = user[:person_id].to_i
#      person = Person.find(pid)
#      @user.person = person
#      if @user.save
#        redirect_to_index("User #{@user.user_name} created")
#      end
#    end
#  end

  # Delete the user with the given ID from the database.
  # The model raises an exception if we attempt to delete
  # the last user.
#  def delete_user
#    id = params[:id]
#    if id && user = User.find(id)
#      begin
#        user.destroy
#        flash[:notice] = "User #{user.user_name} deleted"
#      rescue
#        flash[:notice] = "Can't delete that user"
#      end
#    end
#    redirect_to(:action => :list_users)
#  end
#
#  # List all the users.
#  def list_users
#
#    @users = User.find(:all)
#    
#  end

  # Log out by clearing the user entry in the session. We then
  # redirect to the #login action.
  def logout
     if session[:user_id]
        lock = RequestLock.find_by_user_id(session[:user_id].user_name)
        lock.destroy if lock
      end
     reset_session
     puts "session reset"
     session[:user_id] = nil
    puts "logged out"
    #flash[:notice] = "Logged out"
    redirect_to(:action => "login")
  end
end
