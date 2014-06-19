
class DataExporter


def initialize(table_name)

    @table_name = table_name
	@source_conn_string = "localhost"
	@source_db = "kromco_mes"
	@destination_conn_string = "localhost"
	@destination_db = "app_factory"
	@dest_user_name = "postgres"
	@dest_password = "postgres"
	@local_user_name = "postgres"
	@local_password = "postgres"

	@source_records = Array.new
	@destination_records = Array.new
end


def set_connection(is_target = nil)
	host = nil
	database = nil
	
	
	ActiveRecord::Base.remove_connection
	user_name = nil
	password = nil
	if ! is_target
		host = @source_conn_string
		database = @source_db
		user_name = @local_user_name
	    password = @local_password
	else
		host = @destination_conn_string
		database =@destination_db
		user_name = @dest_user_name
	    password = @dest_password
	end
	
	ActiveRecord::Base.establish_connection(:adapter => "postgresql", :host => host,  :database => database,
                                                                :username => user_name, :password => password,:port => 5432)
end

def export_table_data

copy_data
return paste_data #returns the list of failed records

end
private
def copy_data
	
	#set_connection

	eval "class " +  Inflector.camelize(Inflector.singularize(@table_name)) + " < ActiveRecord::Base \n end"
	#get all the data on this table
	copy_rows = nil
	
	eval "copy_rows = " + Inflector.camelize(Inflector.singularize(@table_name)) + ".find_all()"
	
	copy_rows.each do |row|
		copy = row.clone
		copy.id = row.id
		@source_records.push copy
	end
	
	ActiveRecord::Base.remove_connection
	
end

private
def paste_data

    errors = Hash.new
    begin
	 set_connection true
	
	 eval "class " +  Inflector.camelize(Inflector.singularize(@table_name)) + " < ActiveRecord::Base \n end"
	 #create a new record for each record in @copy_records
	 @source_records.each do |source_record|
	   new_record = nil
	   begin
	     eval "new_record = " + Inflector.camelize(Inflector.singularize(@table_name)) + ".new"
	     new_record.attributes = source_record.attributes
	     new_record.id = source_record.id
	     new_record.save
	   rescue
	     errors[source_record.id]= $!.message
	   end
	 end
    return errors
    ensure
        set_connection
    end
      
   end
   

end



