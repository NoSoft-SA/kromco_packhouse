class InventoryIssueType < ActiveRecord::Base

  #	===========================
  # 	Association declarations:
  #	===========================
    has_many :inventory_issues
 
  #	============================
  #	 Validations declarations:
  #	============================
	validates_presence_of :inventory_issue_type_code
	validates_uniqueness_of :inventory_issue_type_code
	
  #	=====================
  #	 Complex validations:
  #	=====================
  def validate 
  #	first check whether combo fields have been selected
  	 is_valid = true
  end

  #	===========================
  #	 foreign key validations:
  #	===========================
  #	===========================
  #	 lookup methods:
  #	===========================

end