class Status < ActiveRecord::Base 
	
#	===========================
# 	Association declarations:
#	===========================
  belongs_to :status_type
 
 
#	============================
#	 Validations declarations:
#	============================
	validates_presence_of :status_code,:status_type_code
#	=====================
#	 Complex validations:
#	=====================

def validate
  is_valid = true
  preceded_by = self.preceded_by
  if preceded_by ==  nil  || preceded_by == ""
    errors.add_to_base("preceded_by can not be blank")
  end


  if preceded_by != nil
   valid_preceded_values
   validate_preceded_first_value
   validate_status_code
  end

end
#	====================================
# validate uniqueness of status code
#	====================================
  def validate_status_code
    status_code = self.status_code
    status_type = self.status_type_code

    if self.new_record?
    status = Status.find_by_status_code_and_status_type_code(status_code,status_type)
      if status != nil
        errors.add_to_base("status code already exists")
      end
    end
  end


#	====================================
# validate preceded_by values
#	====================================

  def validate_preceded_first_value
    status_type = self.status_type_code
    status = Status.find_by_sql("select * from statuses where statuses.status_type_code = '#{status_type}' order by statuses.id desc " )
    if status.empty? && self.preceded_by != "EMPTY"
     errors.add_to_base("First preceded_by value should be EMPTY")
    end
  end

#	====================================
# validate preceded_by values
#	====================================

  def valid_preceded_values
     statuses = Status.find_all_by_status_type_code(self.status_type_code).map{|s| s.status_code}
     preceded_by_splits = preceded_by.strip.split(",")
     if !statuses.empty?
       for preceded_by_split in preceded_by_splits
         preceded = preceded_by_split
#        unless statuses.include?(preceded.strip)
#         errors.add_to_base("invalid value(s) in preceded_by")
#        end
      end
     end
  end


  def before_save
    self.preceded_by.gsub!(" ","")  if self.preceded_by
  end
  def before_update
    self.preceded_by.gsub!(" ","")  if self.preceded_by
  end

  def before_create
    self.preceded_by.gsub!(" ","")  if self.preceded_by
  end





end
