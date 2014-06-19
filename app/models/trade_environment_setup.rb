class TradeEnvironmentSetup < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
    
 
	belongs_to :production_schedule
	belongs_to :destination_country

#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :production_schedule_code
#	=====================
#	 Complex validations:
#	=====================

def TradeEnvironmentSetup.accounts_for_role_and_org(role,org)
    query = "SELECT public.accounts.*
           FROM
           public.organizations
           INNER JOIN public.parties ON (public.organizations.party_id = public.parties.id)
           INNER JOIN public.parties_roles ON (public.parties_roles.party_id = public.parties.id)
           INNER JOIN public.accounts_parties_roles ON (public.accounts_parties_roles.parties_role_id = public.parties_roles.id)
           INNER JOIN public.roles ON (public.parties_roles.role_id = public.roles.id)
           INNER JOIN public.accounts ON (public.accounts_parties_roles.account_id = public.accounts.id)
           WHERE
          (public.roles.role_name = '#{role}') AND 
          (public.organizations.short_description = '#{org}')"

     return TradeEnvironmentSetup.find_by_sql(query)

end

def TradeEnvironmentSetup.accounts_for_farm(farm)
    query = "SELECT public.accounts.*
           FROM
           public.farms
           INNER JOIN public.parties_roles ON (public.farms.parties_role_id = public.parties_roles.id)
           INNER JOIN public.accounts_parties_roles ON (public.accounts_parties_roles.parties_role_id = public.parties_roles.id)
           INNER JOIN public.accounts ON (public.accounts_parties_roles.account_id = public.accounts.id)
           WHERE
          (public.roles.role_name = '#{GROWER}') AND 
          (public.farms.farm_code = '#{farm}')"

     return TradeEnvironmentSetup.find_by_sql(query)

end


 def TradeEnvironmentSetup.next_sequence(schedule_name,org)
  
   query = "SELECT max(trade_environment_setups.sequence_number)as maxval
           FROM
           public.trade_environment_setups where 
           (trade_environment_setups.production_schedule_code = '#{schedule_name}' AND
           trade_environment_setups.organization_marketing = '#{org}')"
           
   val = connection.select_one(query)
   if val["maxval"]== nil
     return 1
   else
    return val["maxval"].to_i + 1
   end
 end
 
def before_save

  clear_combo_prompts
  self.production_schedule = ProductionSchedule.find_by_production_schedule_name(self.production_schedule_code)

end

def before_create
  clear_combo_prompts

end


def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:qc_destination_country_code => self.qc_destination_country_code}],self) 
	 end
	     
	     ModelHelper::Validations.validate_combos([{:account_code => self.account_code}],self,true) 
	     
		 is_valid = ModelHelper::Validations.validate_combos([{:mark_fruit_description => self.mark_fruit_description}],self) 
	
	 
		 is_valid = ModelHelper::Validations.validate_combos([{:mark_retail_unit_description => self.mark_retail_unit_description}],self) 
	 
	 
		 is_valid = ModelHelper::Validations.validate_combos([{:mark_trade_unit_description => self.mark_trade_unit_description}],self) 
	 
	 
		 is_valid = ModelHelper::Validations.validate_combos([{:target_market_description => self.target_market_description}],self) 
	 
	 
		 is_valid = ModelHelper::Validations.validate_combos([{:sell_by_code => self.sell_by_code}],self) 

	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_destination_country
	 end
	 
	 #if new record or if marketing org has changed, calc or recalc the sequence number
	 if is_valid && (self.new_record?||TradeEnvironmentSetup.find(self.id).organization_marketing != self.organization_marketing)
	  seq_num = TradeEnvironmentSetup.next_sequence(self.production_schedule_code,self.organization_marketing)
	  self.sequence_number = seq_num
	  self.trade_env_code = self.organization_marketing + "_" + seq_num.to_s
	 end
	
end


#	===========================
#	 foreign key validations:
#	===========================

 
def set_destination_country

	destination_country = DestinationCountry.find_by_destination_country_code(self.qc_destination_country_code)
	 if destination_country != nil 
		 self.destination_country = destination_country
		 return true
	 else
		errors.add_to_base("value of field: 'destination_country_code' is invalid- not found in database")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================



end
