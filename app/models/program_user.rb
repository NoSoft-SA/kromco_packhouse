class ProgramUser < ActiveRecord::Base
	
	belongs_to :program
	belongs_to :user
	belongs_to :security_group
	
end

