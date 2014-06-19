class IsoWeek < ActiveRecord::Base 
	
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :iso_week_code
	validates_uniqueness_of :iso_week_code
#	=====================
#	 Complex validations:
#	=====================


  def validate
    if self.iso_week_code.to_i == 0
     errors.add("iso_week_code","must be a number")
     return
    end
    
    if self.iso_week_code.length == 1
       self.iso_week_code = "0" + self.iso_week_code
    end
  end

end
