class Commitment < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
 
 
	belongs_to :commitment_type
	belongs_to :grower_commitment
 
#	============================
#	 Validations declarations:
#	============================
  validates_presence_of :certificate_expiry_date
#  validates_uniqueness_of :certificate_number
#	=====================
#	 Complex validations:
#	=====================
def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	 if is_valid
		 is_valid = ModelHelper::Validations.validate_combos([{:commitment_type_code => self.commitment_type_code}],self)
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = set_commitment_type
	 end
	 if is_valid
	  is_valid = is_certificate_number_unique?
	end
	#now check whether fk combos combine to form valid foreign keys
	 if is_valid
		 is_valid = commitment_type_exists?
	 end
end

#	===========================
#	 foreign key validations:
#	===========================
def commitment_type_exists?
  commitment = Commitment.find_by_commitment_type_code_and_grower_commitment_id(self.commitment_type_code,self.grower_commitment_id)
  if(commitment != nil && (commitment.id != self.id))
    errors.add_to_base("value of field: commitment_type_code has already been added to this grower_commitment")
    return false
  end
  return true
end

def is_certificate_number_unique?
  commitment = Commitment.find_by_certificate_number_and_grower_commitment_id(self.certificate_number,self.grower_commitment_id)
  if(commitment != nil && (commitment.id != self.id))#!commitment.id && 
    errors.add_to_base("value of field: certificate_number has already been added to this grower_commitment")
    return false
  end
  return true
end
def set_commitment_type
@commitment_type_code = self.commitment_type_code
	commitment_type = CommitmentType.find_by_sql("select id from commitment_types where commitment_type_code = '{#@commitment_type_code}'")

	 if commitment_type != nil 
		 self.commitment_type_id = commitment_type
		 return true
	 else
		errors.add_to_base("value of field: 'commitment_type_code' is invalid- it must be unique")
		 return false
	end
end
 
def set_grower_commitment

	grower_commitment = GrowerCommitment.find_by_sql(self.grower_commitment.id)
	 if grower_commitment != nil 
		 self.grower_commitment = grower_commitment
		 return true
	 else
		errors.add_to_base("value of field: 'id' is invalid- it must be unique")
		 return false
	end
end
 
#	===========================
#	 lookup methods:
#	===========================



end
