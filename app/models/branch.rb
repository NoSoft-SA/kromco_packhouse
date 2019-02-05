class Branch < ActiveRecord::Base

  belongs_to :invoicing_party, :class_name => 'PartiesRole', :foreign_key => 'invoicing_party_role_id'

  validates_presence_of :branch_name

  def self.for_select
    Branch.find(:all, :select => 'branch_name, id', :order => 'branch_name').map {|r| [r.branch_name, r.id] }
  end

end
