class ProgramExporter

    def initialize(host,database,username,password, record_id)
        @source_connection_string = "localhost"
        @destination_connection_string = host
        @source_db = "kromco_mes"
        @destination_db = database
        @table_name = "programs"
        @record_id = record_id
        @local_username = "postgres"
        @local_password = "caroline"
        @remote_username = username
        @remote_password = password
        
        @program_functions_table = "program_functions"
        @functional_areas_table = "functional_areas"
        
        @source_programs = Array.new
        @source_program_functions = Array.new
        @source_functional_areas = Array.new
        
        @prog_test = Array.new
    end
    
    def set_connection(is_target = nil)
        server_machine = nil
        server_database = nil
        server_username = nil
        server_password = nil
        
        #ActiveRecord::Base.remove_connection
        
        if !is_target
            server_machine = @source_connection_string
            server_database = @source_db
            server_username = @local_username
            server_password = @local_password
        else
            server_machine = @destination_connection_string
            server_database = @destination_db
            server_username = @remote_username
            server_password = @remote_password
        end
        
        #ActiveRecord::Base.establish_connection(:adapter => "postgresql", :host => server_machine,  :database => server_database,
        #                                                        :username => server_username, :password => server_password,:port => 5432)
        
    end
    
    def export_data
        copy_program
        return save_data
    end
    
    private
    def copy_program
        eval "class " + Inflector.camelize(Inflector.singularize(@table_name)) + "< ActiveRecord::Base \n end"
        
        program_rows = nil
        
        eval "program_rows = " + Inflector.camelize(Inflector.singularize(@table_name)) + ".find(:all, :conditions=>['id =?','#{@record_id}'])"
        
        eval "class " + Inflector.camelize(Inflector.singularize(@program_functions_table)) + "< ActiveRecord::Base \n end"
        
        prog_functions_rows = nil
        
        eval "prog_functions_rows = " + Inflector.camelize(Inflector.singularize(@program_functions_table)) + ".find(:all, :conditions=>['program_id = ?','#{@record_id}'])"
        
        #copying functional areas from source database
        eval "class " + Inflector.camelize(Inflector.singularize(@functional_areas_table)) + "< ActiveRecord::Base \n end"
        
        func_areas = nil
        
        eval "func_areas = " + Inflector.camelize(Inflector.singularize(@functional_areas_table)) + ".find(:all, :conditions=>['functional_area_name = ?', '#{program_rows[0].functional_area_name}'])"
        
        puts program_rows.length().to_s
        
        if program_rows.length()!=0 
            program_rows.each do |row|
                copy = row.clone
                copy.id = row.id
                @source_programs.push copy
            end
        end
        
        if prog_functions_rows.length()!=0
            prog_functions_rows.each do |prog|
                copy_prog_func = prog.clone
                copy_prog_func.id = prog.id
                @source_program_functions.push copy_prog_func
            end
        end
        
        if func_areas.length()!=0
            func_areas.each do |func|
                copy_func = func.clone
                copy_func.id = func.id
                @source_functional_areas.push copy_func
            end
        end
        
        puts @destination_db.to_s
        
        #ActiveRecord::Base.remove_connection
        
    end
    
    private
    def save_data
        errors = Hash.new
        begin
            conn = PGconn.connect(@destination_connection_string,5432,"","",@destination_db,@remote_username,@remote_password)
            
            puts @source_programs[0].program_name
            test_program = conn.exec("select * from programs where program_name ='#{@source_programs[0].program_name}'")
            
            test_program.each do |row|
                @prog_test.push test_program[0][1]
            end
            
            if @prog_test.length()!=0
                errors.store("exists", "program")
            else
                #saving functional area data
                test_func_area = conn.exec("select * from functional_areas where functional_area_name = '#{@source_functional_areas[0].functional_area_name}'")
                func_array = Array.new
                test_func_area.each do |func|
                    func_array.push test_func_area[0][1]
                end
                if func_array.length()==0
                    @source_functional_areas.each do |source_func_area|
                        begin
                            conn.exec("insert into functional_areas(functional_area_name, display_name) values('#{source_func_area.functional_area_name}', '#{source_func_area.display_name}')")
                        rescue
                            errors[source_func_area.functional_area_name] = $!.message
                        end
                    end
                end
                
                #save program into remote programs table
                new_functional_area = conn.exec("select * from functional_areas where functional_area_name = '#{@source_functional_areas[0].functional_area_name}'")
                @source_programs.each do |source_program|
                    begin
                        conn.exec("insert into programs(program_name, functional_area_id, display_name, description, technology, functional_area_name) values('#{source_program.program_name}', '#{new_functional_area[0][0]}', '#{source_program.display_name}', '#{source_program.description}', '#{source_program.technology}', '#{source_program.functional_area_name}')")
                    rescue
                        errors[@source_programs[0].program_name] = $!.message
                    end
                end
                
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
            
            return errors
        ensure
        
        end
        
    end

end