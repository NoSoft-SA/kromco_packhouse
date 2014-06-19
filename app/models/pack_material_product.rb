class PackMaterialProduct < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================


  belongs_to :marketing_variety
  belongs_to :product
  belongs_to :pack_material_type
  belongs_to :pack_material_sub_type
  belongs_to :basic_pack
  belongs_to :carton_pack_product
  belongs_to :unit_pack_product

  validates_uniqueness_of :pack_material_product_code

  validates_presence_of :start_date, :end_date,
                        :pack_material_product_code


  def after_save


  end

  def before_create

    product = Product.new
    product.product_code = self.pack_material_product_code
    type = ProductType.find_by_product_type_code("PACK_MATERIAL")
    product.product_type = type
    product.product_type_code = "PACK_MATERIAL"

    if ! subtype = ProductSubtype.find_by_product_subtype_code_and_product_type_code(self.pack_material_type_code, "PACK_MATERIAL")
      subtype = ProductSubtype.new
      subtype.product_type_code = "PACK_MATERIAL"
      subtype.product_type = ProductType.find_by_product_type_code("PACK_MATERIAL")
      subtype.product_subtype_code = self.pack_material_type_code
      subtype.create
    end

    product.product_subtype = subtype
    product.product_subtype_code = self.pack_material_type_code
    product.create
    self.product = product

  end


  def before_update

    #-------------------------------------------------------------------------------------------
    #If the product code changed we need to:
    # 1) change the product code in the product table
    # 2) change the product code of the this product where-ever it occurs in composite products
    #-------------------------------------------------------------------------------------------

    old_product = PackMaterialProduct.find(self.id)
    if old_product.pack_material_product_code != self.pack_material_product_code
      self.product.product_code = self.pack_material_product_code
      CompositeProduct.update_all("product_code = '#{self.pack_material_product_code}'", "product_code = '#{old_product.pack_material_product_code}'")
      CompositeProduct.update_all("childproduct_code = '#{self.pack_material_product_code}'", "childproduct_code = '#{old_product.pack_material_product_code}'")

    end

    #-----------------------------------------------------------------------------------------------------------
    #The user may have assigned a new subtype for the pack material, in which case
    #we need to update the product's subtype (and even create a new subtype if not existing in product_subtypes)
    #------------------------------------------------------------------------------------------------------------

    if !subtype = ProductSubtype.find_by_product_subtype_code_and_product_type_code(self.pack_material_type_code, "PACK_MATERIAL")
      subtype = ProductSubtype.new
      subtype.product_type_code = "PACK_MATERIAL"
      subtype.product_type = ProductType.find_by_product_type_code("PACK_MATERIAL")
      subtype.product_subtype_code = self.pack_material_type_code
      subtype.create
    end

    self.product.product_subtype = subtype
    self.product.product_subtype_code = self.pack_material_type_code
    self.product.update


  end

  def validate


    #--------------------------------------
    #SET AT-ALL-TIMES REQUIRED FOREIGN KEYS
    #--------------------------------------

    is_valid = set_pack_material_type

    if is_valid
      is_valid = set_pack_material_sub_type
    end

    #get config info
    config = PackMaterialProductConfig.find_by_pack_material_sub_type_id(self.pack_material_sub_type.id)

    #--------------------------------------
    #SET CONFIGURABLE REQUIRED FOREIGN KEYS
    #--------------------------------------

    if config.basic_pack_code && config.basic_pack_code > 0
      if is_valid && config.basic_pack_code == 2 #required
        is_valid = ModelHelper::Validations.validate_combos([{:basic_pack_code => self.basic_pack_code}], self)
      else
        ModelHelper::Validations.validate_combos([{:basic_pack_code => self.basic_pack_code}], self, true)
      end
      #now check whether fk combos combine to form valid foreign keys
      if is_valid && self.basic_pack_code
        is_valid = set_basic_pack
      end
    end


    #upc
    if self.pack_material_product_code == "RU" && config.pls_pack_code && config.pls_pack_code > 0
      if is_valid && config.pls_pack_code == 1
        is_valid = ModelHelper::Validations.validate_combos([{:unit_pack_product_code => self.unit_pack_product_code}], self)
      else
        ModelHelper::Validations.validate_combos([{:unit_pack_product_code => self.unit_pack_product_code}], self, true)
      end
      #now check whether fk combos combine to form valid foreign keys
      if is_valid
        is_valid = set_unit_pack_product
      end
    end


    if  self.pack_material_product_code == "TU"
      if is_valid
        is_valid = ModelHelper::Validations.validate_combos([{:carton_pack_product_code => self.carton_pack_product_code}], self)
      end
      #now check whether fk combos combine to form valid foreign keys
      if is_valid
        is_valid = set_carton_pack_product
      end
    end

    if config.commodity_code && config.commodity_code > 0
      if is_valid && config.commodity_code == 2 && config.marketing_variety_code && config.marketing_variety_code == 2
        is_valid = ModelHelper::Validations.validate_combos([{:commodity_group_code => self.commodity_group_code}, {:commodity_code => self.commodity_code}, {:marketing_variety_code => self.marketing_variety_code}], self)
      elsif  is_valid && config.marketing_variety_code && config.marketing_variety_code == 1
        ModelHelper::Validations.validate_combos([{:commodity_group_code => self.commodity_group_code}, {:commodity_code => self.commodity_code}, {:marketing_variety_code => self.marketing_variety_code}], self, true)
      elsif config.commodity_code == 2
        is_valid = ModelHelper::Validations.validate_combos([{:commodity_group_code => self.commodity_group_code}, {:commodity_code => self.commodity_code}], self)
      else
        ModelHelper::Validations.validate_combos([{:commodity_group_code => self.commodity_group_code}, {:commodity_code => self.commodity_code}], self, true)
      end

      #now check whether fk combos combine to form valid foreign keys
      if is_valid && self.marketing_variety_code
        is_valid = set_marketing_variety
      end

      self.inventory_code = self.pack_material_type_code + "-" + self.pack_material_sub_type_code + "-" + PackMaterialProduct.next_id.to_s if self.new_record? && is_valid

    end

    ModelHelper::Validations.validate_combos([{:old_pack_code => self.old_pack_code}], self, true)
    ModelHelper::Validations.validate_combos([{:product_co_use => self.product_co_use}], self, true)
    ModelHelper::Validations.validate_combos([{:product_alternative => self.product_alternative}], self, true)


    #------------------------------
    #SET CONFIGURABLE NON-FK FIELDS
    #------------------------------

    integer_fields = ['fruit_mass_nett', 'dimension_length_mm', 'dimension_width_mm', 'dimension_height_mm']
    #now check whether fk combos combine to form valid foreign keys

    config.attributes.each do |key, value|
      if value && value == 2
        if !self.attributes[key] && key != "id"
          errors.add(key, ": you must enter a value")
        end
        if integer_fields.find { |f| f == key.to_s }
          if value == 0
            errors.add(key, ": you must enter a value")
          end
        end
      end

    end


    #validates uniqueness for this record
    if self.new_record? && is_valid
      validate_uniqueness
    end
  end

  def PackMaterialProduct.next_id
    query = "select last_value from pack_material_products_id_seq"
    return connection.select_all(query)[0]["last_value"].to_i + 1

  end

  def validate_uniqueness
    exists = PackMaterialProduct.find_by_pack_material_type_code_and_pack_material_product_code(self.pack_material_type_code, self.pack_material_product_code)
    if exists != nil
      errors.add_to_base("There already exists a record with the combined values of fields: 'pack_material_type_code' and 'pack_material_product_code' ")
    end
  end

#	===========================
#	 foreign key validations:
#	===========================
  def set_pack_material_sub_type

    pack_material_sub_type = PackMaterialSubType.find_by_pack_material_subtype_code_and_pack_material_type_id(self.pack_material_sub_type_code, self.pack_material_type.id)
    if pack_material_sub_type != nil
      self.pack_material_sub_type = pack_material_sub_type
      return true
    else
      errors.add_to_base("pack_material_sub_type_code is invalid- not found in db")
      return false
    end
  end

  def set_marketing_variety

    marketing_variety = MarketingVariety.find_by_commodity_group_code_and_commodity_code_and_marketing_variety_code(self.commodity_group_code, self.commodity_code, self.marketing_variety_code)
    if marketing_variety != nil
      self.marketing_variety = marketing_variety
      return true
    else
      errors.add_to_base("combination of: 'commodity_group_code' and 'commodity_code' and 'marketing_variety_code'  is invalid- it must be unique")
      return false
    end
  end

  def set_basic_pack

    basic_pack = BasicPack.find_by_basic_pack_code(self.basic_pack_code)
    if basic_pack != nil
      self.basic_pack = basic_pack
      return true
    else
      errors.add_to_base("value of field: 'basic_pack_code' is invalid")
      return false
    end
  end


  def set_unit_pack_product

    unit_pack_product = UnitPackProduct.find_by_unit_pack_product_code(self.unit_pack_product_code)
    if unit_pack_product != nil
      self.unit_pack_product = unit_pack_product
      return true
    else
      errors.add_to_base("unit_pack_product_code is invalid- not found in database")
      return false
    end
  end

  def set_carton_pack_product

    carton_pack_product = CartonPackProduct.find_by_carton_pack_product_code(self.carton_pack_product_code)
    if carton_pack_product != nil
      self.carton_pack_product = carton_pack_product
      return true
    else
      errors.add_to_base("carton_pack_product is invalid- not found in database")
      return false
    end
  end


  def set_pack_material_type

    pack_material_type = PackMaterialType.find_by_pack_material_type_code(self.pack_material_type_code)
    if pack_material_type != nil
      self.pack_material_type = pack_material_type
      return true
    else
      errors.add_to_base("value of field: 'pack_material_type_code' is invalid- it must be unique")
      return false
    end
  end

#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: marketing_variety_id
#	------------------------------------------------------------------------------------------

  def self.get_all_commodity_group_codes

    commodity_group_codes = MarketingVariety.find_by_sql('select distinct commodity_group_code from marketing_varieties').map { |g| [g.commodity_group_code] }
  end


  def self.get_all_commodity_codes

    commodity_codes = MarketingVariety.find_by_sql('select distinct commodity_code from marketing_varieties').map { |g| [g.commodity_code] }
  end


  def self.commodity_codes_for_commodity_group_code(commodity_group_code)

    commodity_codes = MarketingVariety.find_by_sql("Select distinct commodity_code from marketing_varieties where commodity_group_code = '#{commodity_group_code}'").map { |g| [g.commodity_code] }

    commodity_codes.unshift("<empty>")
  end


  def self.get_all_marketing_variety_codes

    marketing_variety_codes = MarketingVariety.find_by_sql('select distinct marketing_variety_code from marketing_varieties').map { |g| [g.marketing_variety_code] }
  end


  def self.marketing_variety_codes_for_commodity_code_and_commodity_group_code(commodity_code, commodity_group_code)

    marketing_variety_codes = MarketingVariety.find_by_sql("Select distinct marketing_variety_code from marketing_varieties where commodity_code = '#{commodity_code}' and commodity_group_code = '#{commodity_group_code}'").map { |g| [g.marketing_variety_code] }

    marketing_variety_codes.unshift("<empty>")
  end


#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: product_id
#	------------------------------------------------------------------------------------------

  def self.get_all_product_codes

    product_codes = Product.find_by_sql('select distinct product_code from products').map { |g| [g.product_code] }
  end


end
