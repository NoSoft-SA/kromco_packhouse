
require "digest/sha1"



class User < ActiveRecord::Base

  # The plain-text password, which is not stored
  # in the database
  attr_accessor :password, :menus_js

  # We never allow the hashed password to be
  # set from a form
  attr_accessible :user_name, :password,:person_id,:branch_id,:last_name,:first_name,:department_id

  validates_uniqueness_of :user_name
  validates_presence_of   :user_name, :password

  belongs_to :person
  belongs_to :branch
  has_many :program_users,:dependent => :destroy
  belongs_to :department
  has_one :user_message,:dependent => :destroy
  has_many :data_miner_reports, :foreign_key => 'author_id'
  has_and_belongs_to_many :user_defined_reports

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

  def initials
    first = self.first_name.nil? ? '' : self.first_name[0,1].upcase
    last  = self.last_name.nil?  ? '' : self.last_name[0,1].upcase
    "#{first}#{last}"
  end

  # When a new User is created, it initially has a
  # plain-text password. We convert this to an SHA1 hash
  # before saving the user in the database.
  def before_create
    self.hashed_password = User.hash_password(self.password)
    puts "USER: before create"
  end

  def before_update
    self.hashed_password = User.hash_password(self.password) unless password.blank?
  end

  def before_save
    puts "USER: BEFORE SAVE"
    get_person_record
  end

  def get_person_record
    person = nil
    self.person = Person.find_by_first_name_and_last_name(self.first_name,self.last_name)

    if self.new_record? && !self.person
      person = Person.new
      person.first_name = self.first_name
      person.last_name = self.last_name
      person.abbr_name = self.first_name + "_" + self.last_name
      person.save!
      self.person = person

    end

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

  def self.for_select(with_branch=false)
    if with_branch
      User.find(:all, :select => 'id, first_name, last_name, branch_id', :order => 'last_name, first_name').map do |u|
        if u.branch_id.nil?
          ["#{u.first_name} #{u.last_name}", u.id]
        else
          ["#{u.first_name} #{u.last_name} (#{u.branch.branch_name})", u.id]
        end
      end
    else
      User.find(:all, :select => 'id, first_name, last_name', :order => 'last_name, first_name').map {|u| ["#{u.first_name} #{u.last_name}", u.id] }
    end
  end

  def full_name
    [first_name, last_name].join(' ')
  end

  private

  def self.hash_password(password)
   # Digest::SHA1.hexdigest(password)
    Base64.encode64(password)
  end

end

