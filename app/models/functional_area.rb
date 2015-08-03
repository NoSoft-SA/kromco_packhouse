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

  # Return a value or the SQL keyword +NULL+ if the value is nil.
  def self.n_f(val)
    val.nil? ? 'NULL' : val
  end

  # Returns a String of SQL statements for populating another database with the exact same
  # FuncionalArea, Program and ProgramFunction settings.
  def self.export_all_as_sql
    ar = []
    FunctionalArea.find(:all, :order => 'id').each do |f|
      ar << "INSERT INTO functional_areas(functional_area_name, display_name, is_non_web_program, disabled, class_name)
            VALUES('#{f.functional_area_name}','#{n_f f.display_name}',#{n_f f.is_non_web_program},#{n_f f.disabled},'#{n_f f.class_name}');".gsub("'NULL'", 'NULL')
    end
    Program.find(:all, :order => 'id').each do |f|
      ar << <<-EOS.gsub("'NULL'", 'NULL')
      INSERT INTO programs(program_name, functional_area_id, display_name, description,
                  technology, functional_area_name, is_non_web_program, class_name,
                              disabled, is_leaf, url_component, func_area_url_component)
      SELECT '#{f.program_name}',functional_areas.id,'#{n_f f.display_name}','#{n_f f.description}',
      '#{n_f f.technology}','#{f.functional_area_name}',#{n_f f.is_non_web_program},'#{n_f f.class_name}',
      #{n_f f.disabled},#{n_f f.is_leaf},'#{n_f f.url_component}', '#{n_f f.func_area_url_component}'
      FROM functional_areas WHERE functional_area_name = '#{f.functional_area_name}';
      EOS
    end
    ProgramFunction.find(:all, :order => 'id').each do |f|
      ar << <<-EOS.gsub("'NULL'", 'NULL')
      INSERT INTO program_functions( program_id, name, description, display_name, program_name,
        functional_area_name, is_non_web_program, disabled, class_name,
        created_on, url_param, voyage_code, prog_url_component, func_area_url_component, "position")
        SELECT programs.id, '#{n_f f.name}', '#{n_f f.description}', '#{n_f f.display_name}', programs.program_name,
        functional_areas.functional_area_name, #{n_f f.is_non_web_program}, #{n_f f.disabled}, '#{n_f f.class_name}',
        localtimestamp, '#{n_f f.url_param}', '#{n_f f.voyage_code}', '#{n_f f.prog_url_component}', '#{n_f f.func_area_url_component}', #{n_f f.position}
        FROM functional_areas, programs
        WHERE functional_areas.functional_area_name = '#{f.functional_area_name}'
          AND programs.program_name = '#{f.program_name}';
      EOS
    end
    ar.join("\n")
  end

end
