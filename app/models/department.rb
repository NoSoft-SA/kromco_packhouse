class Department < ActiveRecord::Base
 has_one :department_message
 has_many :users
end
