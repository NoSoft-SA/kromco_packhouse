class ProgramUser < ActiveRecord::Base
	
	belongs_to :program
	belongs_to :user
	belongs_to :security_group


  def self.selected_programs_def(selected_programs_def,user_id)

    sec_group_id = SecurityGroup.find_by_security_group_name("basic_user").id

    query = ""
    selected_programs_def.each { |object|
      query += "insert into program_users (program_id,user_id,security_group_id)
                values(#{object.id},#{user_id},#{sec_group_id});
                "
    }
    ActiveRecord::Base.connection.execute(query)
  end

  def self.selected_export_permissions_def(selected_programs_def,user_id,selected_user_id)

    query = ""
    selected_programs_def.each { |object|
      target_user_programs = ProgramUser.find_by_sql("select * from program_users where user_id = #{selected_user_id} and program_id = #{object.id}")
      sec_group_id = SecurityGroup.find_by_security_group_name("#{object.security_group_name}").id
      if target_user_programs.length > 0
        query += "update program_users set security_group_id = #{sec_group_id} where program_id = #{object.id} and user_id = #{selected_user_id};" if sec_group_id != target_user_programs[0].security_group_id
      else
        query += "insert into program_users (program_id,user_id,security_group_id)
                  values(#{object.id},#{selected_user_id},#{sec_group_id});"
      end
    }
    ActiveRecord::Base.connection.execute(query) if query.to_s != ""
  end

end

