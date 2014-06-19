class MappedPalletSequence < ActiveRecord::Base

  attr_accessor :mapped, :intake_header_number

  validates_presence_of :intake_header_id
  validates_presence_of :depot_pallet_id
  validates_presence_of :depot_pallet_number
  validates_presence_of :organization
  validates_presence_of :commodity
  validates_presence_of :variety
  validates_presence_of :grade
  validates_presence_of :count
  validates_presence_of :brand
  validates_presence_of :pack_type
  validates_presence_of :extended_fg_code
  validates_presence_of :fg_code_old
  validates_presence_of :mark_code


  def pc_code
    self.pick_reference.slice(2,1) if self.pick_reference
  end

  def validate
    is_valid = true
    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:mark_code=>self.mark_code}], self)
    end
    if is_valid
      is_valid = set_mark_code
    end
#    if is_valid
#      is_valid = ModelHelper::Validations.validate_combos([{:item_pack_product_code=>self.item_pack_product_code}], self)
#    end
#    if is_valid
#      is_valid = set_item_pack_product_code
#    end

    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:extended_fg_code=>self.extended_fg_code}], self)
    end
    if is_valid
      is_valid = set_extended_fg_code
    end
    if is_valid
      is_valid = set_fg_product_code
    end
  end

  def set_mark_code
    if self.mark_code.to_s == ""
      self.mark_code = nil
      return true
    else
      return true
    end
  end

  def set_item_pack_product_code
    if self.item_pack_product_code.to_s == ""
      self.item_pack_product_code = nil
      return false
    else
      return true
    end
  end

  def set_extended_fg_code
    if self.extended_fg_code.to_s.upcase.index("SELECT VALUES FROM") != nil || self.extended_fg_code.to_s == ""
      self.errors.add_to_base("you must select extended_fg_code please!")
      return false
    else
      
      return true
    end
  end

  def set_fg_product_code
    extended_fg = ExtendedFg.find_by_extended_fg_code(self.extended_fg_code)
    if extended_fg
      self.fg_product_code = extended_fg.fg_code
      puts "fg_product_code has been set!"
      return true
    else
      errors.add_to_base("Fg product code can't be blank")
      return false
    end
  end

  def self.get_record_by_fruitspecs(commodity, variety, grade, count, brand, pack_type, organization,class_code,header_id)
    mapped_pallet_seq = self.find_by_commodity_and_variety_and_grade_and_count_and_brand_and_pack_type_and_organization_and_class_code_and_intake_header_id(commodity, variety, grade, count, brand, pack_type, organization,class_code,header_id)
    return mapped_pallet_seq
  end

end
