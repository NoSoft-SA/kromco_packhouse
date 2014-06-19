class InventoryReceipt < ActiveRecord::Base

  attr_accessor :pack_material_type_code, :pack_material_sub_type_code, :party_type_name, :party_name
  #	===========================
  # 	Association declarations:
  #	===========================
    belongs_to :inventory_receipt_type
#    belongs_to :farm
    belongs_to :pack_material_product
    belongs_to :parties_role
    has_many :inventory_transactions
 
  #	============================
  #	 Validations declarations:
  #	============================
#    validates_presence_of :receipt_date_time
#	validates_presence_of :quantity_received
#	validates_presence_of :reference_number
#	validates_numericality_of :quantity_received
#	validates_numericality_of :quantity_on_farms
#	validates_numericality_of :reference_id
#	validates_uniqueness_of :reference_number
	
  #	=====================
  #	 Complex validations:
  #	=====================
  def validate 
     # first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#	   is_valid = ModelHelper::Validations.validate_combos([{:inventory_receipt_type_code => self.inventory_receipt_type_code}],self)
#	 end
#	 if is_valid
#	   is_valid = set_inventory_receipt_type
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
  end

  #	===========================
  #	 foreign key validations:
  #	===========================
  def set_inventory_receipt_type
    inventory_receipt_type = InventoryReceiptType.find_by_inventory_receipt_type_code(self.inventory_receipt_type_code);
    if inventory_receipt_type != nil
      self.inventory_receipt_type = inventory_receipt_type
      return true
    else
      errors.add_to_base("Field: 'inventory_receipt_type_code' is invalid- it must be unique")
      return false
    end
  end
  
  def set_farm
#    farm = Farm.find_by_farm_code(self.farm_code)
#    if farm != nil
#      self.farm = farm
#      return true
#    else
#      errors.add_to_base("Field: 'farm_code' is invalid- it must be unique")
#      return false
#    end
  end
  
  def set_pack_material_product
    pack_material_product = PackMaterialProduct.find_by_pack_material_product_code(self.pack_material_product_code)
    if pack_material_product != nil
        self.pack_material_product = pack_material_product
        return true
    else
        errors.add_to_base("combination of: 'pack_material_product_code'  is invalid- it must be unique")
        return false
    end
  end
  
  def set_parties_role
     parties_role = PartiesRole.find_by_party_type_name_and_party_name_and_role_name(self.party_type_name, self.party_name, self.parties_role_name)
     if parties_role
        self.parties_role = parties_role
        return true
     else
        errors.add_to_base("combination of: 'party_role_name' is invalid- it must be unique")
        return false
     end
  end
  
  
#  def update_changed_fields
#     changed_fields = self.changed_fields
#     if changed_fields.has_key?("farm_code")
#       farm_code = changed_fields.fetch("farm_code")[1]
#       farm = Farm.find_by_farm_code(farm_code)
#       self.farm_id = farm.id
#       self.farm_code = farm.farm_code
#     end
#     
#     if changed_fields.has_key?("truck_code")
#       self.truck_code = changed_fields.fetch("truck_code")[1]
#     end
#     
#     if changed_fields.has_key?("reference_number")
#        self.reference_number = changed_fields.fetch("reference_number")[1]
#     end
#     
#     #self.update
#  end
  
  #	===========================
  #	 lookup methods:
  #	===========================

end