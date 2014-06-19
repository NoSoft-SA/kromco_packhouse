class FunctionalArea < ActiveRecord::Base

  has_many :programs
  
  def self.exists_for_user?(user_id,func_area_name)
  
   query = "SELECT public.programs.id FROM public.users " +
           " INNER JOIN public.program_users ON (public.users.id = public.program_users.user_id)" +
           " INNER JOIN public.programs ON (public.program_users.program_id = public.programs.id)" +
           " WHERE (public.program_users.user_id = '#{user_id}') AND " +
           " (public.programs.functional_area_name = '#{func_area_name}')"
   
   results = self.find_by_sql(query)
   
   return !(results.length == 0)
  
  end
 
  def before_update
    self.programs.each do |prog|
      prog.functional_area_name = self.functional_area_name
#=============
#Luks' Code ==
#=============  
      prog.disabled = self.disabled
      prog.is_non_web_program = self.is_non_web_program
      prog.program_functions.each do |prog_function|
        prog_function.disabled = prog.disabled
        prog_function.is_non_web_program = prog.is_non_web_program
        prog_function.update
      end
#============= 
      prog.update
    end
  
  end
end
