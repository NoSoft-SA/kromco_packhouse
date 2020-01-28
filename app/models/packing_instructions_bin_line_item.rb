class PackingInstructionsBinLineItem < ActiveRecord::Base

#  ===========================
#   Association declarations:
#  ===========================


  belongs_to :treatment
  belongs_to :variety
  belongs_to :packing_instruction
  belongs_to :product_class
  belongs_to :commodity
  belongs_to :size
  belongs_to :track_slms_indicator

  # def after_save
  #   if self.new_record?
  #     self.bin_line_item_code = calc_bin_line_item_code
  #     self.update
  #   end
  # end

  def calc_bin_line_item_code
    bin_line_item_query = PackingInstructionsBinLineItem.bin_line_item_list_query("where pibli.id = #{self.id}")
    bin_line_item = ActiveRecord::Base.connection.select_all(bin_line_item_query)[0]
    bin_line_item_code = "#{bin_line_item['commodity_code']}_#{bin_line_item['variety_code']}_#{bin_line_item['size_code']}_#{bin_line_item['product_class_code']}_#{bin_line_item['treatment_code']}_#{bin_line_item['track_slms_indicator_code']}"
    return bin_line_item_code.to_s
  end

  def PackingInstructionsBinLineItem.bin_line_item_list_query(condition = nil)
    list_query = "select pibli.*,t.track_slms_indicator_code,rmt_varieties.rmt_variety_code as variety_code,s.size_code,
  p.product_class_code,treats.treatment_code,c.commodity_code
  from packing_instructions_bin_line_items pibli
  left join track_slms_indicators t on t.id=pibli.track_slms_indicator_id
  left join rmt_varieties on   pibli.variety_id=rmt_varieties.id
  left join sizes s on s.id=pibli.size_id
  left join product_classes p on p.id=pibli.product_class_id
  left join treatments treats on treats.id=pibli.treatment_id
  left join commodities c on c.id=pibli.commodity_id
  left join packing_instructions pi on pi.id=pibli.packing_instruction_id
   #{condition}"
  end

  def PackingInstructionsBinLineItem.get_rmt_products
    rmt_products = ActiveRecord::Base.connection.select_all("
    select distinct rmt.variety_id,rmt.variety_code,rmt.treatment_id,rmt.treatment_code,
     rmt.product_class_id,rmt.product_class_code,
    rmt.size_id,rmt.size_code,rmt.commodity_code,c.id as commodity_id
    from rmt_products rmt
    left join commodities c on rmt.commodity_code =c.commodity_code")
  end

  def PackingInstructionsBinLineItem.get_commodities
    commodity_codes = Commodity.find_by_sql('select distinct id,commodity_code from commodities').map { |g| [g.commodity_code, g.id] }
  end

  def PackingInstructionsBinLineItem.get_product_classes
    ids = ProductClass.find_by_sql('select distinct id,product_class_code from product_classes').map { |g| [g.product_class_code, g.id] }
  end

  def PackingInstructionsBinLineItem.get_sizes
    ids = Size.find_by_sql('select distinct id,size_code from sizes').map { |g| [g.size_code, g.id] }
  end

  def PackingInstructionsBinLineItem.get_track_slms_indicators
    track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql("select distinct id,track_slms_indicator_code
                                  from track_slms_indicators
                                   where track_indicator_type_code='RMI'").map { |g| [g.track_slms_indicator_code, g.id.to_i] }
  end

  def PackingInstructionsBinLineItem.get_treatments
    treatment_codes = Treatment.find_by_sql('select distinct id,treatment_code from treatments').map { |g| [g.treatment_code, g.id] }
  end

  def PackingInstructionsBinLineItem.get_varieties
    rmt_variety_codes = Variety.find_by_sql('select distinct id,rmt_variety_code from varieties').map { |g| [g.rmt_variety_code, g.id] }
  end


#  ============================
#   Validations declarations:
#  ============================
  validates_numericality_of :bin_qty
#  =====================
#   Complex validations:
#  =====================
  def validate_uniqueness
    exists = PackingInstructionsBinLineItem.find_by_packing_instruction_id_and_commodity_id_and_treatment_id_and_product_class_id_and_size_id_and_variety_id_and_track_slms_indicator_id(self.packing_instruction_id, self.commodity_id, self.treatment_id, self.product_class_id, self.size_id, self.variety_id, self.track_slms_indicator_id)
    if exists != nil
      errors.add_to_base("There already exists a record with the combined values of fields: 'commodity,track_slms_indicator,variety,size,product_class,treatment' ")
    end
  end

  def validate

#  first check whether combo fields have been selected
    is_valid = true
    validate_uniqueness if self.new_record? && is_valid
#  if is_valid
#    is_valid = ModelHelper::Validations.validate_combos([{:treatment_type_code => self.treatment_type_code},{:treatment_code => self.treatment_code}],self)
# end
# #now check whether fk combos combine to form valid foreign keys
#  if is_valid
#    is_valid = set_treatment
#  end
#  if is_valid
#    is_valid = ModelHelper::Validations.validate_combos([{:product_class_code => self.product_class_code},{:id => self.id}],self)
# end
# #now check whether fk combos combine to form valid foreign keys
#  if is_valid
#    is_valid = set_product_class
#  end
#  if is_valid
#    is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code}],self)
# end
# #now check whether fk combos combine to form valid foreign keys
#  if is_valid
#    is_valid = set_commodity
#  end
#  if is_valid
#    is_valid = ModelHelper::Validations.validate_combos([{:track_slms_indicator_code => self.track_slms_indicator_code}],self)
# end
# #now check whether fk combos combine to form valid foreign keys
#  if is_valid
#    is_valid = set_track_slms_indicator
#  end
#  if is_valid
#    is_valid = ModelHelper::Validations.validate_combos([{:pack_date => self.pack_date}],self)
# end
# #now check whether fk combos combine to form valid foreign keys
#  if is_valid
#    is_valid = set_packing_instruction
#  end
#  if is_valid
#    is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code},{:size_code => self.size_code},{:id => self.id}],self)
# end
# #now check whether fk combos combine to form valid foreign keys
#  if is_valid
#    is_valid = set_size
#  end
#  if is_valid
#    is_valid = ModelHelper::Validations.validate_combos([{:commodity_group_code => self.commodity_group_code},{:commodity_code => self.commodity_code},{:commodity_id => self.commodity_id},{:rmt_variety_code => self.rmt_variety_code},{:rmt_variety_id => self.rmt_variety_id},{:marketing_variety_code => self.marketing_variety_code},{:marketing_variety_id => self.marketing_variety_id}],self)
# end
# #now check whether fk combos combine to form valid foreign keys
#  if is_valid
#    is_valid = set_variety
#  end
  end

#  ===========================
#   foreign key validations:
#  ===========================
  def set_treatment

    treatment = Treatment.find_by_treatment_type_code_and_treatment_code(self.treatment_type_code, self.treatment_code)
    if treatment != nil
      self.treatment = treatment
      return true
    else
      errors.add_to_base("combination of: 'treatment_type_code' and 'treatment_code'  is invalid- it must be unique")
      return false
    end
  end

  def set_variety

    variety = Variety.find_by_commodity_group_code_and_commodity_code_and_commodity_id_and_rmt_variety_code_and_rmt_variety_id_and_marketing_variety_code_and_marketing_variety_id(self.commodity_group_code, self.commodity_code, self.commodity_id, self.rmt_variety_code, self.rmt_variety_id, self.marketing_variety_code, self.marketing_variety_id)
    if variety != nil
      self.variety = variety
      return true
    else
      errors.add_to_base("combination of: 'commodity_group_code' and 'commodity_code' and 'commodity_id' and 'rmt_variety_code' and 'rmt_variety_id' and 'marketing_variety_code' and 'marketing_variety_id'  is invalid- it must be unique")
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

  def set_product_class

    product_class = ProductClass.find_by_product_class_code_and_id(self.product_class_code, self.id)
    if product_class != nil
      self.product_class = product_class
      return true
    else
      errors.add_to_base("combination of: 'product_class_code' and 'id'  is invalid- it must be unique")
      return false
    end
  end

  def set_commodity

    commodity = Commodity.find_by_commodity_code(self.commodity_code)
    if commodity != nil
      self.commodity = commodity
      return true
    else
      errors.add_to_base("combination of: 'commodity_code'  is invalid- it must be unique")
      return false
    end
  end

  def set_size

    size = Size.find_by_commodity_code_and_size_code_and_id(self.commodity_code, self.size_code, self.id)
    if size != nil
      self.size = size
      return true
    else
      errors.add_to_base("combination of: 'commodity_code' and 'size_code' and 'id'  is invalid- it must be unique")
      return false
    end
  end

  def set_track_slms_indicator

    track_slms_indicator = TrackSlmsIndicator.find_by_track_slms_indicator_code(self.track_slms_indicator_code)
    if track_slms_indicator != nil
      self.track_slms_indicator = track_slms_indicator
      return true
    else
      errors.add_to_base("combination of: 'track_slms_indicator_code'  is invalid- it must be unique")
      return false
    end
  end

#  ===========================
#   lookup methods:


end
