
#require "digest/sha1"



class User < ActiveRecord::Base

  # The plain-text password, which is not stored
  # in the database
  attr_accessor :password, :menus_js
  
  # We never allow the hashed password to be
  # set from a form
  attr_accessible :user_name, :password

  validates_uniqueness_of :user_name
  validates_presence_of   :user_name, :password
	
  belongs_to :person
  has_many :program_users,:dependent => :destroy
  belongs_to :department
  has_one :user_message,:dependent => :destroy
  has_many :data_miner_reports, :foreign_key => 'author_id'
  has_and_belongs_to_many :user_defined_reports
  has_many :trading_partners

  # Return the User with the given name and
  # plain-text password
  def self.login(user_name, password)
    
    puts "user_name: " + user_name
    puts "password is: " + password
    
    
    hashed_password = hash_password(password || "")
    puts "hashed password is: " + hashed_password
    user = find(:first,:conditions => "user_name = '#{user_name}' and hashed_password = '#{hashed_password}'")
    #(:first,
    #    :conditions => ["user_name = '#{user_name}' and hashed_password = '#{hashed_password}'"])
    puts "user not found: " + (user == nil).to_s
    return user
    #    if users.length == 1
    #      puts "user found "
    #      return users[0]
    #    else
    #      puts "user not found "
    #      return nil
    #    end
  end

  # Log in if the name and password (after hashing)
  # match the database, or if the name matches
  # an entry in the database with no password
  def try_to_login
    
    User.login(self.user_name, self.password)#||
    #User.find_by_user_name(user_name)
  end
  
  # When a new User is created, it initially has a
  # plain-text password. We convert this to an SHA1 hash
  # before saving the user in the database.
  def before_create
    self.hashed_password = User.hash_password(self.password)
    puts "USER: before create"
  end
  
  def before_update
    self.hashed_password = User.hash_password(self.password)
  end

  def before_save
    puts "USER: BEFORE SAVE"
  end
  
  def get_clear_password
    Base64.decode64(self.hashed_password)
   
  end
   
  before_destroy :dont_destroy_hans

  # Don't delete 'hans' from the database
  def dont_destroy_hans
    raise "Can't destroy hans" if self.user_name == 'hans'
  end

  # Clear out the plain-text password once we've
  # saved this row. This stops it being made available
  # in the session
  def after_create
    @password = nil
  end

  private

  def self.hash_password(password)
    #Digest::SHA1.hexdigest(password)
    Base64.encode64(password)
  end
  
  
 
end

