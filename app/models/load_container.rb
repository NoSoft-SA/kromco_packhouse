class LoadContainer < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================


  belongs_to :stack_type
  belongs_to :load

#	============================
#	 Validations declarations:
#	============================
  validates_numericality_of :cargo_weight
  validates_numericality_of :container_tare_weight
#	=====================
#	 Complex validations:
#	=====================
  def validate
#	first check whether combo fields have been selected
    is_valid = true
    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:stack_type_code => self.stack_type_code}, {:id => self.id}], self)
    end
    #now check whether fk combos combine to form valid foreign keys
    if is_valid
      is_valid = set_stack_type
    end
    if is_valid
      is_valid = ModelHelper::Validations.validate_combos([{:load_number => self.load_number}], self)
    end
    #now check whether fk combos combine to form valid foreign keys
    if is_valid
      is_valid = set_load
    end
  end

#	===========================
#	 foreign key validations:
#	===========================
  def set_stack_type

    stack_type = StackType.find_by_stack_type_code_and_id(self.stack_type_code, self.id)
    if stack_type != nil
      self.stack_type = stack_type
      return true
    else
#      errors.add_to_base("combination of: 'stack_type_code' and 'id'  is invalid- it must be unique")
#      return false
    end
  end

  def set_load

    load = Load.find_by_load_number(self.load_number)
    if load != nil
      self.load = load
      return true
    else
      errors.add_to_base("value of field: 'load_number' is invalid- it must be unique")
      return false
    end
  end

#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: stack_type_id
#	------------------------------------------------------------------------------------------

  def self.get_all_stack_type_codes

    stack_type_codes = StackType.find_by_sql('select distinct stack_type_code from stack_types').map { |g| [g.stack_type_code] }
  end


  def self.get_all_ids

    ids = StackType.find_by_sql('select distinct id from stack_types').map { |g| [g.id] }
  end


  def self.ids_for_stack_type_code(stack_type_code)

    ids = StackType.find_by_sql("Select distinct id from stack_types where stack_type_code = '#{stack_type_code}'").map { |g| [g.id] }

    ids.unshift("<empty>")
  end


end
