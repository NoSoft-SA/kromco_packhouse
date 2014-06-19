class TradingPartner < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================

  attr_accessor :trading_partner_name,:party_type_name
  belongs_to :currency
  belongs_to :incoterm
  belongs_to :user
  belongs_to :parties_role
  belongs_to :target_market

  validates_presence_of :parties_role_id


def set_virtual_attributes
    parties_role = PartiesRole.find(self.parties_role_id)
    self.trading_partner_name = parties_role.party_name
    self.party_type_name = parties_role.party_type_name
end


def validate
	 #is_valid = true
	# if is_valid
	#	 is_valid = ModelHelper::Validations.validate_combos([{:incoterm_id => self.incoterm_id}],self,true,true)
	#end
  #
	# if is_valid
	#	 is_valid = ModelHelper::Validations.validate_combos([{:target_market_id => self.target_market_id}],self,true,true)
	#end
  #
	# if is_valid
	#	 is_valid = ModelHelper::Validations.validate_combos([{:currency_id => self.currency_id}],self,true,true)
	#end
  #
   #if is_valid
   #    		 is_valid = ModelHelper::Validations.validate_combos([{:party_type_name => self.party_type_name},{:trading_partner_name,self.trading_partner_name}],self)
   #end
   #if is_valid
   #  if party_type_name == 'PERSON'
   #    if self.trading_partner_name.index(" ")|| !(self.trading_partner_name.index("_"))
   #      person_data = self.trading_partner_name.split(" ")
   #    elsif  self.trading_partner_name.index("_")
   #      person_data = self.trading_partner_name.split("_")
   #    end
   #
   #    if person_data.length() < 2
   #      errors.add(:trading_partner_name,"enter first_name, then a space, then last name")
   #      is_valid = false
   #    else
   #      person = Person.find_by_first_name_and_last_name(person_data[0].strip(),person_data[1].strip())
   #      if !person
   #        person = Person.create!({:first_name => person_data[0],:last_name => person_data[1]})
   #      end
   #      self.trading_partner_name.gsub!(" ","_")
   #    end
   #  else
   #    org = Organization.find_by_short_description(self.trading_partner_name)
   #    if !org
   #      org = Organization.create!({:short_description => self.trading_partner_name})
   #    end
   #
   #  end
   #
   #if is_valid
   #    parties_role = PartiesRole.find_by_party_name_and_party_type_name_and_role_name(self.trading_partner_name,self.party_type_name,'TRADING PARTNER')
   #    if !parties_role
   #     # parties_role = PartiesRole.create!({:party_type_name => self.party_type_name,:party_name => self.trading_partner_name,:role_name => 'TRADING PARTNER' })
   #      parties_role =  PartiesRole.new
   #      parties_role.party_type_name=self.party_type_name
   #      parties_role.party_name= self.trading_partner_name
   #      parties_role.role_name ='TRADING PARTNER'
   #      parties_role.save
   #    end
   #      self.parties_role_id =  parties_role.id
   #end
   #end
end

def validate_uniqueness
	 exists = TradingPartner.find_by_marketer_user_id(self.marketer_user_id)
	 if exists != nil
		errors.add_to_base("There already exists a record with the combined values of fields: 'marketer_user_id' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_incoterm

	incoterm = Incoterm.find(self.incoterm_id)
	 if incoterm != nil 
		 #self.incoterm = incoterm
		 return true
	 else
		errors.add_to_base("value of field: 'incoterm_code' is invalid- it must be unique")
		 return false
	end
end
 
def set_currency

	currency = Currency.find(self.currency_id)
	 if currency != nil 
		 #self.currency = currency
		 return true
	 else
		errors.add_to_base("value of field: 'currency_code' is invalid- it must be unique")
		 return false
	end
end
 
def set_target_market

	target_market = TargetMarket.find(self.target_market_id)
	 if target_market != nil 
		 #self.target_market = target_market
		 return true
	 else
		errors.add_to_base("combination of: 'target_market_code'  is invalid- it must be unique")
		 return false
	end
end
 

 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: target_market_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_target_market_codes

	target_market_codes = TargetMarket.find_by_sql('select distinct target_market_code from target_markets').map{|g|[g.target_market_code]}
end


 












end
