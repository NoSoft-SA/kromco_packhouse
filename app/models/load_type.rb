class LoadType < ActiveRecord::Base

#	===========================
# 	Association declarations:
#	===========================

  has_many :bin_loads
  has_many :loads

#	============================
#	 Validations declarations:
#	============================
  validates_presence_of :load_type_code
#	=====================
#	 Complex validations:
#	=====================
  def validate
#	first check whether combo fields have been selected
    is_valid = true
  end

#	===========================
#	 foreign key validations:
#	===========================
#	===========================
#	 lookup methods:
#	===========================


end
