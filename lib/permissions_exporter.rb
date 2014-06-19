class PermissionsExporter

    def initialize(host,database,username,password,prog_user_id,prog_name,selected_user,prog_id)
        @remote_connection_string = host
        @remote_db = database
        @remote_username = username
        @remote_password = password
        @program_user_id = prog_user_id
        @program_name = prog_name
        @selected_user = selected_user
        @program_id = prog_id
        
        @program_users_table = "program_users"
        @programs_table = "programs"
        @functional_areas_table = "functional_areas"
        @program_functions_table = "program_functions"
        
        @source_permissions = Array.new
        @source_programs = Array.new
        @source_functional_areas = Array.new
        @source_program_functions = Array.new
        
        @test_user = Array.new
        @test_prog = Array.new
    end
    
    
    def export_data
        copy_permission
        return save_permission
    end
    
    private
    def copy_permission
        eval "class " + Inflector.camelize(Inflector.singularize(@program_users_table)) + "< ActiveRecord::Base \n end"
        
        permission_rows = nil
        #prog_user_id = session[:program_user_export].fetch("program_user_id")
        puts @program_user_id.to_s
        eval "permission_rows = " + Inflector.camelize(Inflector.singularize(@program_users_table)) + ".find(:all, :conditions=>['id = ?', '#{@program_user_id}'])"
        
        if permission_rows.length()!=0
            permission_rows.each do |permission|
                copy_perm = permission.clone
                copy_perm.id = permission.id
                @source_permissions.push copy_perm
            end
        end
        
        eval "class " + Inflector.camelize(Inflector.singularize(@programs_table)) + "< ActiveRecord::Base \n end"
        program_rows = nil
        #program_name = session[:program_user_export].fetch("prog_name")
        eval "program_rows = " + Inflector.camelize(Inflector.singularize(@programs_table)) + ".find(:all, :conditions=>['program_name = ?','#{@program_name}'])"
        if program_rows.length()!=0
            program_rows.each do |row|
                copy = row.clone
                copy.id = row.id
                @source_programs.push copy
            end
        end
        
        
        eval "class " + Inflector.camelize(Inflector.singularize(@program_functions_table)) + "< ActiveRecord::Base \n end"
        prog_functions = nil
        eval  "prog_functions = " + Inflector.camelize(Inflector.singularize(@program_functions_table)) + ".find(:all, :conditions=>['program_id = ?', '#{@program_id}'])"
        if prog_functions.length()!=0
            prog_functions.each do |prog_func|
                copy_prog_func = prog_func.clone
                copy_prog_func.id = prog_func.id
                @source_program_functions.push copy_prog_func
            end
        end
        
        
        eval "class " + Inflector.camelize(Inflector.singularize(@functional_areas_table)) + "< ActiveRecord::Base \n end"
        func_areas = nil
        eval "func_areas = " + Inflector.camelize(Inflector.singularize(@functional_areas_table)) + ".find(:all, :conditions=>['functional_area_name = ?', '#{program_rows[0].functional_area_name}'])"
        if func_areas.length()!=0
            func_areas.each do |func|
                copy_func = func.clone
                copy_func.id = func.id
                @source_functional_areas.push copy_func
            end
        end
        
    end
    
    private
    def save_permission
        errors = Hash.new
        begin
            conn = PGconn.connect(@remote_connection_string,5432,"","",@remote_db,@remote_username,@remote_password)
            
            puts @source_permissions[0].program_id.to_s
            #username = session[:program_user_export].fetch("selected_user")
            test_user = conn.exec("select * from users where user_name = '#{@selected_user}'")
            test_user.each do |user|
                @test_user.push user[0]
            end
            u_id = @test_user[0].to_i
            
            #prog_name = session[:program_user_export].fetch("prog_name")
            test_program = conn.exec("select * from programs where program_name = '#{@program_name}'")
            test_program.each do |prog|
                @test_prog.push test_program[0][0]
            end
            
            if @test_prog.length()!= 0 #Testing to see if program is in programs table
                prog_id = @test_prog[0].to_i
                test_permission = conn.exec("select * from program_users where user_id = '#{u_id}' and program_id = '#{prog_id}' and security_group_id = '#{@source_permissions[0].security_group_id}'")
                test_array = Array.new
                test_permission.each do |perm|
                    test_array.push test_permission[0][0]
                end
                if test_array.length()!=0
                    errors.store("exists", "permissions")
                else
                    #save directly to program_users table
                    begin
                        p_name = ""
                        func_name = ""
                        conn.exec("insert into program_users(user_id, program_id, security_group_id, program_name, functional_area_name) values('#{u_id}', '#{prog_id}', '#{@source_permissions[0].security_group_id}', '#{p_name}', '#{func_name}')")
                    rescue
                        errors["insert_program_user"] = $!.message
                    end
                end
            else
                #program not in programs table
                begin
                    test_functional_area = conn.exec("select * from functional_areas where functional_area_name = '#{@source_functional_areas[0].functional_area_name}'")
                    func_array = Array.new
                    test_functional_area.each do |func_area|
                        func_array.push test_functional_area[0][0]
                    end
                    
                    if func_array.length()!=0
                        func_area_id = func_array[0].to_i
                        p_name = ""
                        func_name = ""
                        conn.exec("insert into programs(program_name, functional_area_id, display_name, description, technology, functional_area_name) values('#{@source_programs[0].program_name}', '#{func_area_id}', '#{@source_programs[0].display_name}', '#{@source_programs[0].description}', '#{@source_programs[0].technology}', '#{@source_programs[0].functional_area_name}')")
                        #looking for program_id
                        test_prog = conn.exec("select * from programs where program_name = '#{@program_name}'")
                        prog_array = Array.new
                        test_prog.each do |prog|
                            prog_array.push prog[0]
                        end
                        prog_id = prog_array[0]
                        conn.exec("insert into program_users(user_id, program_id, security_group_id, program_name, functional_area_name) values('#{u_id}', '#{prog_id}', '#{@source_permissions[0].security_group_id}', '#{p_name}', '#{func_name}')")
                        #create a new record for each record in @source_program_functions and save to remote database
                        recent_program = conn.exec("select * from programs where program_name = '#{@source_programs[0].program_name}'")
                        @source_program_functions.each do |source_prog_func|
                            begin
                                conn.exec("insert into program_functions (program_id, name, description, display_name, program_name, functional_area_name, created_on) values('#{recent_program[0][0]}', '#{source_prog_func.name}', '#{source_prog_func.description}', '#{source_prog_func.display_name}', '#{source_prog_func.program_name}', '#{source_prog_func.functional_area_name}', '#{source_prog_func.created_on}')")
                            rescue
                                errors[source_prog_func.name] = $!.message
                            end
                        end
                    else
                        conn.exec("insert into functional_areas(functional_area_name, display_name) values('#{@source_functional_areas[0].functional_area_name}', '#{@source_functional_areas[0].display_name}')")
                        new_func_area = conn.exec("select * from functional_areas where functional_area_name = '#{@source_functional_areas[0].functional_area_name}'")
                        new_func_array = Array.new
                        new_func_area.each do |func|
                            new_func_array.push new_func_area[0][0]
                        end
                        func_area_id = new_func_array[0].to_i
                        p_name = ""
                        func_name = ""
                        conn.exec("insert into programs(program_name, functional_area_id, display_name, description, technology, functional_area_name) values('#{@source_programs[0].program_name}', '#{func_area_id}', '#{@source_programs[0].display_name}', '#{@source_programs[0].description}', '#{@source_programs[0].technology}', '#{@source_programs[0].functional_area_name}')")
                        conn.exec("insert into program_users(user_id, program_id, security_group_id, program_name, functional_area_name) values('#{u_id}', '#{prog_id}', '#{@source_permissions[0].security_group_id}', '#{p_name}', '#{func_name}')")
                        #create a new record for each record in @source_program_functions and save to remote database
                        recent_program = conn.exec("select * from programs where program_name = '#{@source_programs[0].program_name}'")
                        @source_program_functions.each do |source_prog_func|
                            begin
                                conn.exec("insert into program_functions (program_id, name, description, display_name, program_name, functional_area_name, created_on) values('#{recent_program[0][0]}', '#{source_prog_func.name}', '#{source_prog_func.description}', '#{source_prog_func.display_name}', '#{source_prog_func.program_name}', '#{source_prog_func.functional_area_name}', '#{source_prog_func.created_on}')")
                            rescue
                                errors[source_prog_func.name] = $!.message
                            end
                        end
                    end
                rescue
                    errors["insert_everything"] = $!.message
                end
            end
            
            return errors
        ensure
        
        end
    end

end