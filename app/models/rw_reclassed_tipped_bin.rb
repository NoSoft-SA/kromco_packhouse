class RwReclassedTippedBin < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :rw_run
#	belongs_to :delivery
# 
##	============================
##	 Validations declarations:
##	============================
##	=====================
##	 Complex validations:
##	=====================
#def validate 
##	first check whether combo fields have been selected
#	 is_valid = true
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:delivery_number => self.delivery_number}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_delivery
#	 end
#	 if is_valid
#		 is_valid = ModelHelper::Validations.validate_combos([{:rw_run_start_datetime => self.rw_run_start_datetime}],self) 
#	end
#	#now check whether fk combos combine to form valid foreign keys
#	 if is_valid
#		 is_valid = set_rw_run
#	 end
#end
#
##	===========================
##	 foreign key validations:
##	===========================
#def set_rw_run
#
#	rw_run = RwRun.find_by_rw_run_start_datetime(self.rw_run_start_datetime)
#	 if rw_run != nil 
#		 self.rw_run = rw_run
#		 return true
#	 else
#		errors.add_to_base("value of field: 'rw_run_start_datetime' is invalid- it must be unique")
#		 return false
#	end
#end
# 
#def set_delivery
#
#	delivery = Delivery.find_by_delivery_number(self.delivery_number)
#	 if delivery != nil 
#		 self.delivery = delivery
#		 return true
#	 else
#		errors.add_to_base("combination of: 'delivery_number'  is invalid- it must be unique")
#		 return false
#	end
#end
# 
##	===========================
##	 lookup methods:
##	===========================
##	------------------------------------------------------------------------------------------
##	Lookup methods for the foreign composite key of id field: delivery_id
##	------------------------------------------------------------------------------------------
# 
#def self.get_all_delivery_numbers
#
#	delivery_numbers = Delivery.find_by_sql('select distinct delivery_number from deliveries').map{|g|[g.delivery_number]}
#end
#
#




end
