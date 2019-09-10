class PackingInstructionsFgLineItem < ActiveRecord::Base

#  ===========================
#   Association declarations:
#  ===========================


  belongs_to :target_market
  belongs_to :grade
  belongs_to :packing_instruction

#  ============================
#   Validations declarations:
#  ============================
  validates_numericality_of :pallet_qty
#  =====================
#   Complex validations:
#  =====================
#
  def validate_uniqueness
    exists = PackingInstructionsFgLineItem.find_by_packing_instruction_id_and_retailer_sell_by_code_and_old_fg_id_and_grade_id_and_inventory_id_and_target_market_id_and_marketing_org_id(self.packing_instruction_id, self.retailer_sell_by_code, self.old_fg_id, self.grade_id, self.inventory_id, self.target_market_id, self.marketing_org_id)
    if exists != nil
      errors.add_to_base("There already exists a record with the combined values of fields: 'retailer_sell_by_code,old_fg_code,grade,inventory,target_market,marketing_org' and 'customer_party_role_id' ")
    end
  end

  def validate
#  first check whether combo fields have been selected
    is_valid = true
    validate_uniqueness
#  if is_valid
#    is_valid = ModelHelper::Validations.validate_combos([{:grade_code => self.grade_code}],self)
# end
# #now check whether fk combos combine to form valid foreign keys
#  if is_valid
#    is_valid = set_grade
#  end
#  if is_valid
#    is_valid = ModelHelper::Validations.validate_combos([{:pack_date => self.pack_date}],self)
# end
# #now check whether fk combos combine to form valid foreign keys
#  if is_valid
#    is_valid = set_packing_instruction
#  end
#  if is_valid
#    is_valid = ModelHelper::Validations.validate_combos([{:target_market_code => self.target_market_code}],self)
# end
# #now check whether fk combos combine to form valid foreign keys
#  if is_valid
#    is_valid = set_target_market
#  end
  end

#  ===========================
#   foreign key validations:
#  ===========================
  def set_target_market

    target_market = TargetMarket.find_by_target_market_code(self.target_market_code)
    if target_market != nil
      self.target_market = target_market
      return true
    else
      errors.add_to_base("combination of: 'target_market_code'  is invalid- it must be unique")
      return false
    end
  end

  def set_grade

    grade = Grade.find_by_grade_code(self.grade_code)
    if grade != nil
      self.grade = grade
      return true
    else
      errors.add_to_base("combination of: 'grade_code'  is invalid- it must be unique")
      return false
    end
  end

  def set_packing_instruction

    packing_instruction = PackingInstruction.find_by_pack_date(self.pack_date)
    if packing_instruction != nil
      self.packing_instruction = packing_instruction
      return true
    else
      errors.add_to_base("value of field: 'pack_date' is invalid- it must be unique")
      return false
    end
  end

#  ===========================
#   lookup methods:
#  ===========================
#  ------------------------------------------------------------------------------------------
#  Lookup methods for the foreign composite key of id field: target_market_id
#  ------------------------------------------------------------------------------------------

  def self.get_all_target_market_codes

    target_market_codes = TargetMarket.find_by_sql('select distinct target_market_code from target_markets').map { |g| [g.target_market_code] }
  end


#  ------------------------------------------------------------------------------------------
#  Lookup methods for the foreign composite key of id field: grade_id
#  ------------------------------------------------------------------------------------------

  def self.get_all_grade_codes

    grade_codes = Grade.find_by_sql('select distinct grade_code from grades').map { |g| [g.grade_code] }
  end


end
