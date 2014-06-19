module Reports::CrystalReportsHelper

  def build_search_reports_form(reports,action,caption,is_edit)
  
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:report_search_form]= Hash.new
	
	#generate javascript for the on_complete ajax event for each combo
	search_combos_js_for_reports = gen_combos_clear_js_for_combos(["report_report_type","report_reference_id"])
	#Observers for search combos
	report_type_name_observer  = {:updated_field_id => "reference_id_cell",
					 :remote_method => 'report_report_type_name_search_combo_changed',
					 :on_completed_js => search_combos_js_for_reports["report_report_type"]}

	session[:report_search_form][:report_type_name_observer] = report_type_name_observer
	
	on_complete_js = "\n img = document.getElementById('img_report_reference_id');"
	on_complete_js += "\n if(img != null) img.style.display = 'none';"
	report_reference_id_observer  = {:updated_field_id => "report_number_cell",
					 :remote_method => 'report_reference_id_search_combo_changed',
					 :on_completed_js => on_complete_js}

	session[:report_search_form][:report_reference_id_observer] = report_reference_id_observer
	
  
    report_types = ReportType.find_by_sql("select * from report_types").map{|r|[r.report_type_name]}
    report_user_refs = Report.find_by_sql("select distinct report_user_ref from reports").map{|r|[r.report_user_ref]}
    puts "This list is an = " + report_types.class.name
    report_types.unshift("<empty>")
    puts "First element = " + report_types[0].to_s
    puts "last element = " + report_types[report_types.length-1].to_s
    
    reference_ids = ["Select a value from report_type"]
    report_numbers = ["Select a value from reference_id"]
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    
   field_configs = Array.new
   
   field_configs[field_configs.length] = {:field_type => "DropDownField", :field_name => "report_type",
                                          :settings => {:list => report_types},
						                  :observer => report_type_name_observer}
                                          
   field_configs[field_configs.length] = {:field_type => "LabelField", :field_name => "reference_type",
						                  :settings => {:css_class => "dark_heading_field"}}
						                  
   field_configs[field_configs.length] = {:field_type => "DropDownField", :field_name => "reference_id",
                                          :settings => {:list => reference_ids},
						                  :observer => report_reference_id_observer}					                  

   field_configs[field_configs.length] = {:field_type => "LabelField", :field_name => "report_title",
						                  :settings => {:css_class => "dark_heading_field"}}
						                  
   field_configs[field_configs.length] = {:field_type => "DropDownField", :field_name => "report_number",
                                          :settings => {:list => report_numbers}}

    field_configs[field_configs.length] = {:field_type => "DropDownField", :field_name => "report_user_ref",
                                          :settings => {:list => report_user_refs}}

   field_configs[field_configs.length] = {:field_type => "PopupDateSelector", :field_name => "created_on",
                                          :settings => {:date_textfield_id=>'created_on_date2from'}}					                  

   field_configs[field_configs.length] = {:field_type => "PopupDateSelector", :field_name => "created_on",
                                          :settings => {:date_textfield_id=>'created_on_date2to'}}					                  
                                                                                        
    build_form(reports,field_configs,action,"report",caption,is_edit)
  end
  
  def build_crystal_reports_tree(reports)
     
    begin
    
     menu1 = ApplicationHelper::ContextMenu.new("report_type","crystal_reports")
     menu1.add_command("set reprintable",url_for(:action => "set_report_type_reprintable"))
     
     menu2 = ApplicationHelper::ContextMenu.new("report_title","crystal_reports")
     menu2.add_command("set reprintable",url_for(:action => "set_report_title_reprintable"))

     menu3 = ApplicationHelper::ContextMenu.new("report","crystal_reports")
     menu3.add_command("  view report ",url_for(:action => "view_report"))
         
     root_node = ApplicationHelper::TreeNode.new("crystal_reports","reports",true,"crystal_reports")
     
 #--------------------------------------------------------------------
   if reports.length > 0
   
   
      @report_type_groups = reports.group(["report_type"],true,true)
      
      @report_type_groups.each do |report_type|
      report_type_node = root_node.add_child(report_type[0].report_type.report_type_name ,"report_type",report_type[0].report_type.report_type_name.to_s)
          @report_title_groups = report_type.group(["report_type","reference_id"],true,true)
            @report_title_groups.each do |report_title|
            title = report_type[0].report_type.report_type_name + "_" + report_title[0].reference_id.to_s
            report_title_id = report_type[0].report_type.report_type_name + "-" + report_title[0].reference_id.to_s
            report_title_node = report_type_node.add_child(title,"report_title",report_title_id)
            @totally_sorted_reports = report_title.sort_list(["report_type","reference_id","version_number"],true)
               @totally_sorted_reports.each do |report|
                report_name =  report.report_number + ".pdf"
                report_id = report.id.to_s
                report_node = report_title_node.add_child(report_name,"report",report_id)
               end    
            end
      end
   end
 #--------------------------------------------------------------------
 
 
 
     tree = ApplicationHelper::TreeView.new(root_node,"crystal_reports")
     tree.add_context_menu(menu1)
     tree.add_context_menu(menu2)
     tree.add_context_menu(menu3)
     
     tree.render
     
     
   rescue
     raise "The drench_lines tree could not be rendered. Exception reported is \n" + $!
   end
  end
  
  def build_set_report_type_reprintable_form(report_type,action,caption,is_edit)
    
    field_configs = Array.new
    
    field_configs[field_configs.length] = {:field_type => "CheckBox", :field_name => "reprintable"}					                  
                                                                                        
    build_form(report_type,field_configs,action,"report_type",caption,is_edit)
    
  end
  
  def build_set_report_title_reprintable_form(report,action,caption,is_edit)
    
    field_configs = Array.new
    #puts " last_report_version.reprintable = " + last_report_version.reprintable.to_s
    field_configs[field_configs.length] = {:field_type => "CheckBox", :field_name => "reprintable"}					                  
                                                                                        
    build_form(report,field_configs,action,"report",caption,is_edit)
    
  end
end