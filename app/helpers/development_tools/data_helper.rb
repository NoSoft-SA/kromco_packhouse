 
module DevelopmentTools::DataHelper
    
   def create_csv_export_form(tables)
      
      field_configs = Array.new
      field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'table',
						:settings => {:list => tables}}
  	  
       	build_form(nil,field_configs,"export_to_csv_submit",'exporter',"export to csv",false,false,true)
   
   end
   
     def create_table_export_form
    
      field_configs = Array.new
      field_configs[0] = {:field_type => 'TextField',
  	                      :field_name => 'export_table'}
  	  
       	build_form(nil,field_configs,"export_table_submit",'exporter',"export")
   
   end
   
   
end
