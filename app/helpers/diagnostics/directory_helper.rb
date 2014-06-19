  #require File.dirname(__FILE__) + "/../../../app/helpers/directory_management/dir_grid_plugin.rb"
module  Diagnostics::DirectoryHelper
   

 def build_directory_form(dirr,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:artist_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'dir_name1'}

   field_configs[1] = {:field_type => 'TextField',
						:field_name => 'dir_name2'}

   
   
	
	build_form(dirr,field_configs,action,'dirr',caption,is_edit)

    end
 def build_dir_grid(data_set)
    column_configs = Array.new
  require File.dirname(__FILE__) + "/../../../app/helpers/diagnostics/dir_grid_plugin.rb"
                           column_configs[0] = {:field_type => 'text',:field_name => 'type'}
                           column_configs[1] = {:field_type => 'text',:field_name => 'ffile'}
                           column_configs[2] = {:field_type => 'text',:field_name => 'difference'}
                           column_configs[3] = {:field_type => 'text',:field_name => 'file_id'}
    #if 'difference'== "Not_In_Source_Directory" ||  'difference' =="Not_Exist_Target_Directory"

     # end              

                column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'display_file_contents',
			  :settings =>
           {:link_text => 'view file contents',
          :target_action => 'display_contents',
          :id_column => 'file_id'}}

    column_configs[column_configs.length()] = {:field_type => 'link_window',:field_name => 'display_diffs',
                  :settings =>
               {:link_text => 'view differences',
              :target_action =>'view_differences',
              :null_test =>"['difference'] == 'Not_In_Source_Directory'||active_record['difference'] == 'Not_Exist_Target_Directory'||active_record['difference'] == 'Newer_in_date'||active_record['difference'] == 'Older_in_date'",
              :id_column => 'file_id'}}

                 


          get_data_grid(data_set,column_configs,DiagnosticsPlugins::DirectoryGridPlugin.new,true)
          #get_data_grid(data_set,column_configs,true)
 end


  def build_file_diffs_form

      field_configs = Array.new

                    field_configs[0] = {:field_type => 'TextField',
                                        :field_name => 'display_file_contents'}

                    field_configs[1] = {:field_type => 'LabelField',
                                        :field_name => 'display_contents'}

    build_form(nil,field_configs,nil,'file','view')
       
   end
   def build_score_entry_form
   field_configs = Array.new


	field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'club',:settings => {:static_value => session[:club]}}

	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'score'}

   field_configs[2] = {:field_type => 'TextField',
						:field_name => 'date'}


	build_form(nil,field_configs,'add_score','score','add score')


 end


  end
  






