class InventoryIssue < ActiveRecord::Base

  attr_accessor :pack_material_type_code, :pack_material_sub_type_code, :party_type_name, :party_name
  #	===========================
  # 	Association declarations:
  #	===========================
    belongs_to :inventory_issue_type
#    belongs_to :farm
    belongs_to :pack_material_product
    belongs_to :parties_role
    has_many :inventory_transactions
 
  #	============================
  #	 Validations declarations:
  #	============================
#    validates_presence_of :reference_number
#	validates_presence_of :issue_date_time
#	validates_presence_of :parties_role_name
#	validates_presence_of :pack_material_product_code
#	validates_presence_of :quantity_issued
#	validates_numericality_of :quantity_issued
#	validates_numericality_of :quantity_on_farms_new
#	validates_presence_of :truck_code
#	#validates_presence_of :picklist_id
#	#validates_numericality_of :picklist_id
#
#  #	=====================
#  #	 Complex validations:
#  #	=====================
#  def validate
#     # first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#	   is_valid = ModelHelper::Validations.validate_combos([{:inventory_issue_type_code => self.inventory_issue_type_code}],self)
#	 end
#	 if is_valid
#	   is_valid = set_inventory_issue_type
#	 end
#
#	 if is_valid
#	   is_valid = ModelHelper::Validations.validate_combos([{:farm_code => self.farm_code}],self)
#	 end
#	 if is_valid
#	   is_valid = set_farm
#	 end
#
#	 if is_valid
#	   is_valid = ModelHelper::Validations.validate_combos([{:pack_material_product_code => self.pack_material_product_code}],self)
#	 end
#	 if is_valid
#	   is_valid = set_pack_material_product
#	 end
#
#	 if is_valid
#	    is_valid = ModelHelper::Validations.validate_combos([{:parties_role_name => self.parties_role_name}],self)
#	 end
#	 if is_valid
#	    is_valid = set_parties_role
#	 end
#
#  end
#
#  #	===========================
#  #	 foreign key validations:
#  #	===========================
#  def set_inventory_issue_type
#    inventory_issue_type = InventoryIssueType.find_by_inventory_issue_type_code(self.inventory_issue_type_code);
#    if inventory_issue_type != nil
#      self.inventory_issue_type = inventory_issue_type
#      return true
#    else
#      errors.add_to_base("Field: 'inventory_issue_type_code' is invalid- it must be unique")
#      return false
#    end
#  end
#
#  def set_farm
#    farm = Farm.find_by_farm_code(self.farm_code)
#    if farm != nil
#      self.farm = farm
#      return true
#    else
#      errors.add_to_base("Field: 'farm_code' is invalid- it must be unique")
#      return false
#    end
#  end
#
#  def set_pack_material_product
#    pack_material_product = PackMaterialProduct.find_by_pack_material_product_code(self.pack_material_product_code)
#    if pack_material_product != nil
#        self.pack_material_product = pack_material_product
#        return true
#    else
#        errors.add_to_base("combination of: 'pack_material_product_code'  is invalid- it must be unique")
#        return false
#    end
#  end
#
#  def set_parties_role
#     parties_role = PartiesRole.find_by_party_type_name_and_party_name_and_role_name(self.party_type_name, self.party_name, self.parties_role_name)
#     if parties_role
#        self.parties_role = parties_role
#        return true
#     else
#        errors.add_to_base("combination of: 'party_role_name' is invalid- it must be unique")
#        return false
#     end
#  end
  
  
  
  #	===========================
  #	 lookup methods:
  #	===========================

end