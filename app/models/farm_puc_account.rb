class FarmPucAccount < ActiveRecord::Base


 #	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :farm
	belongs_to :accounts_parties_role
	belongs_to :puc
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :farm_code
	validates_presence_of :puc_code
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:party_type_name => self.party_type_name},{:party_name => self.party_name},{:role_name => self.role_name},{:account_code => self.account_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_accounts_parties_role
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:farm_code => self.farm_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_farm
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:puc_type_code => self.puc_type_code},{:puc_code => self.puc_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_puc
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

def validate_uniqueness
	 exists = FarmPucAccount.find_by_party_type_name_and_party_name_and_role_name_and_account_code_and_puc_type_code_and_puc_code_and_farm_code(self.party_type_name,self.party_name,self.role_name,self.account_code,self.puc_type_code,self.puc_code,self.farm_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'party_type_name' and 'party_name' and 'role_name' and 'account_code' and 'puc_type_code' and 'puc_code' and 'farm_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_farm

	farm = Farm.find_by_farm_code(self.farm_code)
	 if farm != nil 
		 self.farm = farm
		 return true
	 else
		errors.add_to_base("combination of: 'farm_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_accounts_parties_role

	accounts_parties_role = AccountsPartiesRole.find_by_party_type_name_and_party_name_and_role_name_and_account_code(self.party_type_name,self.party_name,self.role_name,self.account_code)
	 if accounts_parties_role != nil 
		 self.accounts_parties_role = accounts_parties_role
		 return true
	 else
		errors.add_to_base("combination of: 'party_type_name' and 'party_name' and 'role_name' and 'account_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_puc

	puc = Puc.find_by_puc_type_code_and_puc_code(self.puc_type_code,self.puc_code)
	 if puc != nil 
		 self.puc = puc
		 return true
	 else
		errors.add_to_base("combination of: 'puc_type_code' and 'puc_code'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: farm_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_farm_codes

	farm_codes = Farm.find_by_sql('select distinct farm_code from farms').map{|g|[g.farm_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: accounts_parties_role_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_party_type_names

	party_type_names = AccountsPartiesRole.find_by_sql('select distinct party_type_name from accounts_parties_roles').map{|g|[g.party_type_name]}
end



def self.get_all_party_names

	party_names = AccountsPartiesRole.find_by_sql('select distinct party_name from accounts_parties_roles').map{|g|[g.party_name]}
end



def self.party_names_for_party_type_name(party_type_name)

	party_names = AccountsPartiesRole.find_by_sql("Select distinct party_name from accounts_parties_roles where party_type_name = '#{party_type_name}'").map{|g|[g.party_name]}

	party_names.unshift("<empty>")
 end



def self.get_all_role_names

	role_names = AccountsPartiesRole.find_by_sql('select distinct role_name from accounts_parties_roles').map{|g|[g.role_name]}
end



def self.role_names_for_party_name_and_party_type_name(party_name, party_type_name)

	role_names = AccountsPartiesRole.find_by_sql("Select distinct role_name from accounts_parties_roles where party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.role_name]}

	role_names.unshift("<empty>")
 end



def self.get_all_account_codes

	account_codes = AccountsPartiesRole.find_by_sql('select distinct account_code from accounts_parties_roles').map{|g|[g.account_code]}
end



def self.account_codes_for_role_name_and_party_name_and_party_type_name(role_name, party_name, party_type_name)

	account_codes = AccountsPartiesRole.find_by_sql("Select distinct account_code from accounts_parties_roles where role_name = '#{role_name}' and party_name = '#{party_name}' and party_type_name = '#{party_type_name}'").map{|g|[g.account_code]}

	account_codes.unshift("<empty>")
 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: puc_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_puc_type_codes

	puc_type_codes = Puc.find_by_sql('select distinct puc_type_code from pucs').map{|g|[g.puc_type_code]}
end



def self.get_all_puc_codes

	puc_codes = Puc.find_by_sql('select distinct puc_code from pucs').map{|g|[g.puc_code]}
end



def self.puc_codes_for_puc_type_code(puc_type_code)

	puc_codes = Puc.find_by_sql("Select distinct puc_code from pucs where puc_type_code = '#{puc_type_code}'").map{|g|[g.puc_code]}

	puc_codes.unshift("<empty>")
 end
 
 
 
 def FarmPucAccount.accounts_for_puc_and_farm(puc,farm)
  
  query = "SELECT distinct accounts.account_code
           FROM
           public.farm_puc_accounts
           INNER JOIN public.accounts_parties_roles ON (public.farm_puc_accounts.accounts_parties_role_id = public.accounts_parties_roles.id)
           INNER JOIN public.accounts ON (public.accounts_parties_roles.account_id = public.accounts.id)
           WHERE
           (public.farm_puc_accounts.puc_code = '#{puc}') AND 
           (public.farm_puc_accounts.farm_code = '#{farm}')"
 
   return FarmPucAccount.find_by_sql(query).map{|c|c.account_code}
 
 end
 
  def FarmPucAccount.accounts_for_puc(puc)
  
  query = "SELECT distinct accounts.account_code
           FROM
           public.farm_puc_accounts
           INNER JOIN public.accounts_parties_roles ON (public.farm_puc_accounts.accounts_parties_role_id = public.accounts_parties_roles.id)
           INNER JOIN public.accounts ON (public.accounts_parties_roles.account_id = public.accounts.id)
           WHERE
           (public.farm_puc_accounts.puc_code = '#{puc}')"
 
   return FarmPucAccount.find_by_sql(query).map{|c|c.account_code}
 
 end
 
  def FarmPucAccount.get_record_for_farm_and_marketer(farm,marketer)
    query = "SELECT public.farm_puc_accounts.puc_code,
                    public.farm_puc_accounts.account_code
                    FROM   public.farm_puc_accounts
                    WHERE
                    (role_name='MARKETER' AND
                    farm_code= '#{farm}' AND
                    party_name='#{marketer}')
                    LIMIT 1"
  
    return FarmPucAccount.find_by_sql(query)[0]
  
  end
 
 def FarmPucAccount.pucs_for_farm_group(farm_group)
 
   query = "SELECT DISTINCT 
            public.farm_puc_accounts.puc_code
            FROM
            public.farm_puc_accounts
            INNER JOIN public.farms ON (public.farm_puc_accounts.farm_id = public.farms.id)
            INNER JOIN public.farm_groups ON (public.farms.farm_group_id = public.farm_groups.id)
            WHERE
            (public.farm_groups.farm_group_code = '#{farm_group}')"
 
    return FarmPucAccount.find_by_sql(query).map{|c|c.puc_code}
    
 end
 
 def FarmPucAccount.all_pucs
  
  query = "SELECT DISTINCT 
          public.farm_puc_accounts.puc_code
          FROM
          public.farm_puc_accounts"
 
   return FarmPucAccount.find_by_sql(query).map{|c|c.puc_code}
 
 end
 
  def FarmPucAccount.pucs_for_farm(farm)
  
  query = "SELECT DISTINCT 
          public.farm_puc_accounts.puc_code
          FROM
          public.farm_puc_accounts
          WHERE
          (public.farm_puc_accounts.farm_code = '#{farm}')"
 
   return FarmPucAccount.find_by_sql(query).map{|c|c.puc_code}
 
 end
 
end
