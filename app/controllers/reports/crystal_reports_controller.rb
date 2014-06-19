class Reports::CrystalReportsController < ApplicationController
 def program_name?
    "crystal reports"
 end
 
 def bypass_generic_security?
   true
 end
 
 def search_reports
  @content_header_caption = "'find reports'"
  render :inline => %{
                      <%= build_search_reports_form(@reports,"find_reports","search",false) %>
                      }, :layout => 'content'
 end
 
 def report_report_type_name_search_combo_changed
   @report_type_name = get_selected_combo_value(params)
   session[:report_search_form][:report_type_name_combo_selection] = @report_type_name
   report_number_prefix = @report_type_name + "_"
   reference_types = Report.find_by_sql("SELECT distinct reference_type FROM reports WHERE report_number like '#{report_number_prefix}%' limit 1").map{|r|[r.reference_type]}
   #puts "^^^^^^^^^^^^reports^^^^^^^^^^^^ " + reports.pop.pop.class.name.to_s
   @reference_type = reference_types[0][0] if reference_types.length > 0
   
   @reference_ids = Report.find_by_sql("select distinct reference_id from reports where reference_type = '#{@reference_type}'").map{|d|[d.reference_id]}
   @reference_ids.unshift("<empty>")
   #puts "^^^^^^^^^^^^reference_is^^^^^^^^^^^^ " + @reference_ids.length.to_s
   #	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
	   
		<%= select('report','reference_id',@reference_ids)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_report_reference_id'/>
		<%= observe_field('report_reference_id',:update => 'report_number_cell',:url => {:action => session[:report_search_form][:report_reference_id_observer][:remote_method]},:loading => "show_element('img_report_reference_id');",:complete => session[:report_search_form][:report_reference_id_observer][:on_completed_js])%>        
        
        <% @empty_report_number = select('report','report_number',["Select a value from reference_id"]) %>
        <script>
            <%= update_element_function(
              "reference_type_cell", :action=>:update,
              :content=> @reference_type
            )%>
            
         <%= update_element_function(
          "report_title_cell", :action => :update,
          :content => "")
         %>
         
         <%= update_element_function(
          "report_number_cell", :action => :update,
          :content => @empty_report_number)
         %>
        </script> 

    		}
   
 end
 
 def report_reference_id_search_combo_changed
    reference_id = get_selected_combo_value(params).to_i
   #puts "This is reference_id ==========>>> " + reference_id.to_i.to_s
    #session[:report_search_form][:reference_id_combo_selection] = reference_id
    #report_type_name = session[:report_search_form][:report_type_name_combo_selection] 
    @report_numbers = Report.find_by_sql("select distinct report_number from reports where reference_id = '#{reference_id}'").map{|g|[g.report_number]}
    @report_numbers.unshift("<empty>")
    
    #SET REPORT TITLE AS WELL
    @report_title = session[:report_search_form][:report_type_name_combo_selection] + "_" + reference_id.to_s
    
   #	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('report','report_number',@report_numbers)%>
     
     <script>
      <%= update_element_function(
         "report_title_cell", :action => :update,
         :content => @report_title)
       %>
     </script>
		}
 end
 
 def find_reports
#puts " PARAMS = " + params[:report][:created_on_date2to].to_s
      @reports = dynamic_search(params[:report] ,'reports','Report')
      
#=====================================================
#=====================================================
#=====================================================

#
#      @report_type_groups = @reports.group(["report_type"],true,true)
#      
#      @report_type_groups.each do |x|
#      puts "=========== " + x[0].report_type.report_type_name 
#      puts " "
#          @report_title_groups = x.group(["report_type","reference_id"],true,true)
#            @report_title_groups.each do |t|
#            puts "       ===========" + x[0].report_type.report_type_name + t[0].reference_id.to_s 
#            @totally_sorted_reports = t.sort_list(["report_type","reference_id","version_number"],true)
#               @totally_sorted_reports.each do |node|
#                puts "                       " + node.report_number    
#               end    
#            puts " "
#            end
#         
#      puts " "
#      end


#=====================================================
#=====================================================
#=====================================================
      render :inline => %{
                          <% @content_header_caption = "'Kromco Crystal Reports '" %> 
                          <% @tree_script = build_crystal_reports_tree(@reports) %>
                      }, :layout => 'tree'
 end
 
 def set_report_type_reprintable
 
    #SET REPRINTABLE FOR ALL REPORTS WITH report_type = params[:id] || JUST THE REPORT TYPE RECORD WITH report_type = params[:id]????
    @report_type = ReportType.find_by_report_type_name(params[:id])
    session[:report_type] = @report_type
       render :inline => %{
                       <% @tree_node_content_header = "set report type reprintable" -%>
                       <% @hide_content_pane = false %>
                       <% @is_menu_loaded_view = true %>

		               <%= build_set_report_type_reprintable_form(@report_type,'submit_report_type_reprintable','set_reprintable',false)%>

		                }, :layout => 'tree_node_content'
 end
 
 def submit_report_type_reprintable
    
     @report_type = session[:report_type]
#puts "params[:report_type] = " + params[:report_type].to_s 
 
 begin
   @report_type.update_attribute(:reprintable,params[:report_type][:reprintable])
    
    flash[:notice] = "reprintable set successfully"
 rescue
    flash[:notice] = "Error: Could not reprintable!!!"
 end
    render :inline => %{
                      
                       <% @hide_content_pane = true %>
                       <% @is_menu_loaded_view = false %>

		                }, :layout => 'tree_node_content'
 end
 
 def set_report_title_reprintable
    report_type = params[:id].split("-")[0]
    reference_id = params[:id].split("-")[1]
    #puts "report_type = " + report_type
    #puts "reference_id = " + reference_id
    @report = Report.find_all_by_report_type_and_reference_id(report_type,reference_id.to_i,:order => 'version_number DESC')[0]
    #@last_report_version = Report.find_by_sql("select * from reports where report_type ='#{report_type}' and reference_id ='#{reference_id}'")
    puts "Retrieved this many reports = " + @report.report_number.to_s
    session[:report_title_last_report_version] = @report
       render :inline => %{
                       <% @tree_node_content_header = "set report title reprintable" -%>
                       <% @hide_content_pane = false %>
                       <% @is_menu_loaded_view = true %>

		               <%= build_set_report_title_reprintable_form(@report,'submit_report_title_reprintable','set_reprintable',false)%>

		                }, :layout => 'tree_node_content'
 end
 
 def submit_report_title_reprintable
       
     @report = session[:report_title_last_report_version]
#puts "params[:report] = " + params[:report].to_s 
   puts "@report = " + @report.report_number.to_s + " == " + @report.respond_to?('reprintable').to_s
 
 begin
   @report.update_attribute(:reprintable,params[:report][:reprintable])
    
    flash[:notice] = "reprintable for the last version of this report has been set successfully"
 rescue
    flash[:notice] = "Error: Could not set reprintable for the last version of this report!!!"
 end
    render :inline => %{
                      
                       <% @hide_content_pane = true %>
                       <% @is_menu_loaded_view = false %>

		                }, :layout => 'tree_node_content'
 end
 
 def view_report
    @report = Report.find(params[:id])
    filename = @report.report_path_name +  @report.report_number + ".pdf"
    
   begin 
    @check_results = system("rundll32 url.dll,FileProtocolHandler " + filename)
    flash[:notice] = File.stat(filename).file? #@check_results.to_s
   rescue
    @freeze_flash = true
    flash[:notice] = "COULD NOT FIND REPORT - it has been moved or deleted!!!!"
   end
     render :inline => %{
                           
                       <% @hide_content_pane = true %>
                       <% @is_menu_loaded_view = true %>
                       
                       }, :layout => 'tree_node_content'
                      
 end
 
end