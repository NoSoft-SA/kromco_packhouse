class Gtin < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
	belongs_to :mark
	belongs_to :grade
	belongs_to :standard_size_count
	belongs_to :organization
	belongs_to :target_market
    
    
    validates_presence_of :transaction_number
	
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:grade_code => self.grade_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_grade
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:mark_code => self.mark_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_mark
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commodity_code => self.commodity_code},{:old_pack_code => self.old_pack_code},{:actual_count => self.actual_count}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:organization_code => self.organization_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	
	 if is_valid
		 is_valid = set_organization
	 end
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:target_market_code => self.target_market_code}],self) 
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_target_market
	 end
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end


def before_save
  
 # self.gtin_code = self.organization_code + "_" + self.commodity_code + "_" + self.marketing_variety_code + "_" + self.old_pack_code +
 #                 "_" + self.mark_code + "_" + self.actual_count.to_s + "_" + self.grade_code + "_" + self.inventory_code

end


def validate_uniqueness
	 exists = Gtin.find_by_transaction_number_and_organization_code_and_commodity_code_and_marketing_variety_code_and_old_pack_code_and_mark_code_and_actual_count_and_grade_code_and_inventory_code(self.transaction_number,self.organization_code,self.commodity_code,self.marketing_variety_code,self.old_pack_code,self.mark_code,self.actual_count,self.grade_code,self.inventory_code)
	 if exists != nil
		errors.add_to_base("There already exists a record with the combined values of fields: 'organization_code' and 'commodity_code' and 'marketing_variety_code' and 'old_pack_code' and 'mark_code' and 'actual_count' and 'grade_code' and 'inventory_code' ")
	end
end
#	===========================
#	 foreign key validations:
#	===========================
def set_mark

	mark = Mark.find_by_mark_code(self.mark_code)
	 if mark != nil 
		 self.mark = mark
		 self.brand_code = mark.brand_code
		 return true
	 else
		errors.add_to_base("combination of: 'mark_code'  is invalid- it must be unique")
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
 
def set_standard_size_count

 #-------------------------------------------------------------------------------------
 #Ref to std size count cannot be set- Kromco cannot control the order and values
 #of fields set on gtin
 #-------------------------------------------------------------------------------------
#	standard_size_count = StandardSizeCount.find_by_commodity_code_and_old_pack_code_and_actual_count(self.commodity_code,self.old_pack_code,self.actual_count)
#	 if standard_size_count != nil 
#		 self.standard_size_count = standard_size_count
#		 return true
#	 else
#		errors.add_to_base("combination of: 'commodity_code' and 'old_pack_code' and 'actual_count'  is invalid- it must be unique")
#		 return false
#	end
end
 
def set_organization
   puts "in set org"
	organization = Organization.find_by_short_description(self.organization_code)
	 if organization != nil 
		 self.organization = organization
		 return true
	 else
		errors.add_to_base("combination of: 'organization_code'  is invalid- it must be unique")
		 return false
	end
end
 
def set_target_market

	target_market = TargetMarket.find_by_target_market_name(self.target_market_code)
	 if target_market != nil 
		 self.target_market = target_market
		 return true
	 else
		errors.add_to_base("combination of: 'target_market_name'  is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================
#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: mark_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_mark_codes

	mark_codes = Mark.find_by_sql('select distinct mark_code from marks').map{|g|[g.mark_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: grade_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_grade_codes

	grade_codes = Grade.find_by_sql('select distinct grade_code from grades').map{|g|[g.grade_code]}
end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: standard_size_count_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_commodity_codes

	commodity_codes = StandardSizeCount.find_by_sql('select distinct commodity_code from standard_size_counts').map{|g|[g.commodity_code]}
end



def self.get_all_old_pack_codes

	old_pack_codes = StandardSizeCount.find_by_sql('select distinct old_pack_code from standard_size_counts').map{|g|[g.old_pack_code]}
end



def self.old_pack_codes_for_commodity_code(commodity_code)

	old_pack_codes = StandardSizeCount.find_by_sql("Select distinct old_pack_code from standard_size_counts where commodity_code = '#{commodity_code}'").map{|g|[g.old_pack_code]}

	old_pack_codes.unshift("<empty>")
 end



def self.get_all_actual_counts

	actual_counts = StandardSizeCount.find_by_sql('select distinct actual_count from standard_size_counts').map{|g|[g.actual_count]}
end



def self.actual_counts_for_old_pack_code_and_commodity_code(old_pack_code, commodity_code)

	actual_counts = StandardSizeCount.find_by_sql("Select distinct actual_count from standard_size_counts where old_pack_code = '#{old_pack_code}' and commodity_code = '#{commodity_code}'").map{|g|[g.actual_count]}

	actual_counts.unshift("<empty>")
 end



#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: organization_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_short_descriptions

	short_descriptions = Organization.find_by_sql('select distinct short_description from organizations').map{|g|[g.short_description]}
end

#	------------------------------------------------------------------------------------------
#	Lookup methods for the foreign composite key of id field: target_market_id
#	------------------------------------------------------------------------------------------
 
def self.get_all_target_market_names

	target_market_names = TargetMarket.find_by_sql('select distinct target_market_name from target_markets').map{|g|[g.target_market_name]}
end


def self.get_gtin_by_code(gtin_code)
   query = "SELECT
            *
            FROM
            public.gtins
            WHERE
            (now() < public.gtins.date_to and now() > public.gtins.date_from) AND
            (public.gtins.gtin_code = '#{gtin_code}')"

#            puts "????QUERY : " + query

           return Gtin.find_by_sql(query)[0]


end




def self.get_gtin(created_on,organization_code,commodity_code,marketing_variety_code,brand_code,old_pack_code,actual_size_count_code,inventory_code_short,grade_code)
  query = "SELECT
            public.gtins.gtin_code
            FROM
            public.gtins
            WHERE
            (('#{created_on}' < public.gtins.date_to and '#{created_on}' > public.gtins.date_from)AND
            (public.gtins.organization_code = '#{organization_code}') AND
            (public.gtins.commodity_code = '#{commodity_code}') AND
            (public.gtins.marketing_variety_code = '#{marketing_variety_code}') AND
            (public.gtins.old_pack_code = '#{old_pack_code}') AND
            (public.gtins.brand_code = '#{brand_code}') AND
            (public.gtins.actual_count = '#{actual_size_count_code}') AND
            (public.gtins.grade_code = '#{grade_code}') AND
            (public.gtins.inventory_code = '#{inventory_code_short}'))"

#            puts "????QUERY : " + query

            gtin = Gtin.connection.select_one(query)
            if gtin
              gtin = gtin['gtin_code']
            end

            return gtin


end



end
