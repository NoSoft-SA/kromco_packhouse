class PackingInstruction < ActiveRecord::Base

#  ===========================
#   Association declarations:
#  ===========================


  belongs_to :trading_partner
  belongs_to :shift_type

#  ============================
#   Validations declarations:
#  ============================
#  =====================
#   Complex validations:
#  =====================
def validate
   is_valid = true
   if self.new_record? && is_valid
     validate_uniqueness
   end
end

  def validate_uniqueness
   exists = PackingInstruction.find_by_pack_date_and_shift_type_id(self.pack_date,self.shift_type_id)
	 if exists != nil
		errors.add_to_base("There already exists a record with the combined values of fields: 'pack date and shift type' ")
	 end
  end

#  ===========================
#   foreign key validations:
#  ===========================
def set_trading_partner

  trading_partner = TradingPartner.find_by_currency_id(self.currency_id)
   if trading_partner != nil 
     self.trading_partner = trading_partner
     return true
   else
    errors.add_to_base("combination of: 'currency_id'  is invalid- it must be unique")
     return false
  end
end

def set_shift_type

  shift_type = ShiftType.find_by_shift_type_code_and_id(self.shift_type_code,self.id)
   if shift_type != nil 
     self.shift_type = shift_type
     return true
   else
    errors.add_to_base("combination of: 'shift_type_code' and 'id'  is invalid- it must be unique")
     return false
  end
end

#  ===========================
#   lookup methods:
#  ===========================
#  ------------------------------------------------------------------------------------------
#  Lookup methods for the foreign composite key of id field: trading_partner_id
#  ------------------------------------------------------------------------------------------

def self.get_all_currency_ids

  currency_ids = TradingPartner.find_by_sql('select distinct currency_id from trading_partners').map{|g|[g.currency_id]}
end



#  ------------------------------------------------------------------------------------------
#  Lookup methods for the foreign composite key of id field: shift_type_id
#  ------------------------------------------------------------------------------------------

def self.get_all_shift_type_codes

  shift_type_codes = ShiftType.find_by_sql('select distinct id,shift_type_code from shift_types').map{|g|[g.shift_type_code,g['id']]}
end

  def self.get_trading_partners
    trading_partners = ActiveRecord::Base.connection.select_all("select id,contact_name from trading_partners").map{|x|[x['contact_name'],x['id']]}
  end



def self.get_all_ids

  ids = ShiftType.find_by_sql('select distinct id from shift_types').map{|g|[g.id]}
end



def self.ids_for_shift_type_code(shift_type_code)

  ids = ShiftType.find_by_sql("Select distinct id from shift_types where shift_type_code = '#{shift_type_code}'").map{|g|[g.id]}

 end






end