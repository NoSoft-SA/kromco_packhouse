class AssetItem < ActiveRecord::Base
   
#  attr_accessor :reference_number, :transaction_business_name_code, :transaction_type_code, :farm_code, :truck_code, :asset_type_code, :receipt, :receipt_reference_number
  attr_accessor :pack_material_type_code, :pack_material_sub_type_code, :pack_material_product_code, :owner_type, :owner , :ownership
  #	===========================
  # 	Association declarations:
  #	===========================
    belongs_to :asset_type
    belongs_to :inventory_transaction
    has_many :inventory_transaction_assets
    has_many :asset_locations,:dependent => :destroy
    belongs_to :parties_role
    #has_many :asset_maintenance_logs
 
  #	============================
  #	 Validations declarations:
  #	============================
#	validates_presence_of :asset_number
#	validates_presence_of :asset_type_id
#	validates_presence_of :quantity
#	validates_numericality_of :asset_type_id
#	validates_numericality_of :quantity
#	validates_numericality_of :parties_role_id
#	validates_uniqueness_of :asset_number
#	validates_presence_of :party_name
#	validates_presence_of :parties_role_name

  def set_virtual_attributes
    self.owner = self.party_name
    self.owner_type = PartiesRole.find_by_party_name_and_role_name(self.party_name,"ASSET_OWNER").party_type_name
    self.pack_material_product_code = self.asset_number
    pack_material_product = PackMaterialProduct.find_by_pack_material_product_code(self.asset_number)
    self.pack_material_sub_type_code = pack_material_product.pack_material_sub_type_code
    self.pack_material_type_code = pack_material_product.pack_material_type_code
    self.ownership = pack_material_product.ownership
  end
  #	=====================
  #	 Complex validations:
  #	=====================
  def validate 
#     # first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#	   is_valid = ModelHelper::Validations.validate_combos([{:asset_type_code => self.asset_type_code}],self)
#	 end
#	 if is_valid
#	   is_valid = set_asset_type
#	 end
#
##	 if is_valid
##	   is_valid = ModelHelper::Validations.validate_combos([{:location_code => self.location_code}],self)
##	 end
##	 if is_valid
##	   is_valid = set_location
##	 end
#     if is_valid
#        is_valid = set_parties_role
#     end
#	 
  end

  #	===========================
  #	 foreign key validations:
  #	===========================
  def set_asset_type
    asset_type = AssetType.find_by_asset_type_code(self.asset_type_code);
    if asset_type != nil
      self.asset_type = asset_type
      return true
    else
      errors.add_to_base("Field: 'asset_type_code' is required pleased")
      return false
    end
  end
  
#  def set_location
#    location = Location.find_by_location_code(self.location_code)
#    if location != nil
#      self.location = location
#      return true
#    else
#      errors.add_to_base("Field: 'location_code' is invalid- it must be unique")
#      return false
#    end
#  end
  
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
  
  def update_changed_fields
    changed_fields = self.changed_fields
    if changed_fields != nil && changed_fields.length > 0
      if changed_fields.has_key?("parties_role_name")
        parties_role_name = changed_fields.fetch("parties_role_name")[1]
        parties_role = PartiesRole.find_by_party_type_name_and_party_name_and_role_name(self.party_type_name, self.party_name, parties_role_name)
        self.parties_role = parties_role
        self.party_name = self.party_name
      end
    end
  end
 
  
  
  #	===========================
  #	 lookup methods:
  #	===========================

end