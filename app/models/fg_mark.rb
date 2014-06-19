class FgMark < ActiveRecord::Base 
	
 
def validate 
    
    is_valid = true
    is_valid = ModelHelper::Validations.validate_combos([{:ri_mark_code => self.ri_mark_code}],self) 
    is_valid = ModelHelper::Validations.validate_combos([{:ru_mark_code => self.ru_mark_code}],self) if is_valid
    is_valid = ModelHelper::Validations.validate_combos([{:tu_mark_code => self.tu_mark_code}],self) if is_valid
    is_valid = validate_uniqueness if self.new_record?
    self.fg_mark_code = self.ri_mark_code + "_" + self.ru_mark_code + "_" + self.tu_mark_code if is_valid
    
end

  def FgMark.get_all_by_tu_org(org)
  
    query = "SELECT public.fg_marks.*
            FROM
            public.marks_organizations
            INNER JOIN public.fg_marks ON (public.marks_organizations.mark_code = public.fg_marks.tu_mark_code)
            WHERE
          (public.marks_organizations.short_description = '#{org}')"
          
    return FgMark.find_by_sql(query)
  
  end
  
  
  def FgMark.create_if_needed(ri_mark,ru_mark,tu_mark)
   
   if !fg_mark = FgMark.find_by_ri_mark_code_and_ru_mark_code_and_tu_mark_code(ri_mark, ru_mark, tu_mark)
     fg_mark = FgMark.new
     fg_mark.ri_mark_code = ri_mark
     fg_mark.ru_mark_code = ru_mark
     fg_mark.tu_mark_code = tu_mark
     fg_mark.save
   end
   
   return fg_mark.fg_mark_code
   
  
  end
  
  
  def validate_uniqueness
   
   if FgMark.find_by_ri_mark_code_and_ru_mark_code_and_tu_mark_code(self.ri_mark_code, self.ru_mark_code, self.tu_mark_code)
     errors.add_to_base("Combination of ri,tu and ru mark codes must be unique (such a <br> combination already exists in database)")
     return false
   else
    return true
   end
  
  end

end
