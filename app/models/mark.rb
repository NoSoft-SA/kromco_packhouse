class Mark < ActiveRecord::Base
 
  validates_presence_of :mark_code,:brand_code
 
 def validate 
#	first check whether combo fields have been selected
	 is_valid = true
	#validates uniqueness for this record
	 if self.new_record? && is_valid
		 validate_uniqueness
	 end
end

 def validate_uniqueness
	 exists = Mark.find_by_mark_code(self.mark_code)
	 if exists != nil 
		errors.add_to_base("There already exists a record with the combined values of fields: 'mark_code' ")
	end
 end

  def Mark.get_all_for_org(org)
  
    query = "SELECT public.marks.mark_code
              FROM
            public.marks_organizations
            INNER JOIN public.marks ON (public.marks_organizations.mark_id = public.marks.id)
            INNER JOIN public.organizations ON (public.marks_organizations.organization_id = public.organizations.id)
            WHERE
            (public.organizations.short_description = '#{org}')"
  
       return Mark.find_by_sql(query).map{|o| [o.mark_code]}
  
  
  end
  
   def Mark.get_all_for_orgs(org1,org2,org3)
  
    query = "SELECT public.marks.mark_code
              FROM
            public.marks_organizations
            INNER JOIN public.marks ON (public.marks_organizations.mark_id = public.marks.id)
            INNER JOIN public.organizations ON (public.marks_organizations.organization_id = public.organizations.id)
            WHERE
            (public.organizations.short_description = '#{org1}' OR 
             public.organizations.short_description = '#{org2}' OR
             public.organizations.short_description = '#{org3}')"
  
       return Mark.find_by_sql(query).map{|o| [o.mark_code]}
  
  end
  
end
