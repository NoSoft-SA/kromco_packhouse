require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module RunSetupPlugins

#CountsDropsGridPlugin
class RunSetupGridPlugin < ApplicationHelper::GridPlugin
      
   def before_cell_render_styling(column_name,cell_value,record)
       
      if !record.has_runs
        record.has_runs = (ProductionSchedule.num_runs_for_schedule(record.id)> 0)
      end
       
      if record.has_runs == true
           "<font color = 'green'>"
      else 
          "<font color = 'red'>"
      end
    
       
   end
   def after_cell_render_styling(column_name,cell_value,record)
        '</font>'
      
   end
      
  end
  
  class RunEditGridPlugin < ApplicationHelper::GridPlugin
      
   def before_cell_render_styling(column_name,cell_value,record)
           
           if record.production_run_status == "reconfiguring"
             "<font color = 'orange'>"
           elsif record.production_run_status == "restored"
             "<font color = 'blue'>"
           elsif record.production_run_status == "active"
             "<font color = 'green'>"
             if column_name == "production_run_stage"
              "<font color = 'green'><strong>"
             end
           else
            "<font color = 'brown'>"
           end  
   end
   def after_cell_render_styling(column_name,cell_value,record)
        '</strong></font>'
      
   end
      
  end
  
  
  class PackGroupOutletFormPlugin < ApplicationHelper::FormPlugin
     def get_cell_css_class(field_name,record)
	  
	    case field_name
	       when  "color_sort_percentage"
	           return "blue_label_field" 
	       when "grade_code"
	           return "blue_label_field" 
	       when "size_code","standard_size_count_value"  
	           return "bold_label_field"    
	    end
	
    end
 
  end
  
  #----------------------------------------------
  #Pack group plugins
  #----------------------------------------------
  class RunSetupFormPlugin < ApplicationHelper::FormPlugin
	 
	 #-------------------------------------------------------------------------
	 #This method allows client-code to set the css-class of the containing td
	 #-------------------------------------------------------------------------
	 
	 def no_outlets_defined?(record)
	   nothing_done = true
      record.pack_groups.each do |pack_group| 
       pack_group.pack_group_outlets.each do |outlet|
        if (outlet.outlet1 != nil && outlet.outlet1 != "n.a") ||(outlet.outlet2 != nil && outlet.outlet2 != "n.a")||(outlet.outlet3 != nil && outlet.outlet3 != "n.a")||(outlet.outlet4 != nil && outlet.outlet4 != "n.a")||(outlet.outlet5 != nil && outlet.outlet5 != "n.a")||(outlet.outlet6 != nil && outlet.outlet6 != "n.a")||(outlet.outlet7 != nil && outlet.outlet7 != "n.a")||(outlet.outlet8 != nil && outlet.outlet8 != "n.a")||(outlet.outlet9 != nil && outlet.outlet9 != "n.a")||(outlet.outlet10 != nil && outlet.outlet10 != "n.a")||(outlet.outlet11 != nil && outlet.outlet11 != "n.a")||(outlet.outlet12 != nil && outlet.outlet12 != "n.a")
          nothing_done = false
          break
        end
      end
	 end
	 return nothing_done
    end
	 
	 
	  def get_cell_css_class(field_name,record)
	  
	    case field_name
	       when  "pack_groups"
	         if no_outlets_defined?(record)
	           return "red_label_field" 
	         else
	           return "green_label_field" 
	         end  
	       when "pack_stations:side A"
	       
	           return "blue_label_field"
	       
	        when "pack_stations:side B"
	        
	           return "blue_label_field"
	         
	        when "binfill_stations:side A"
	        
	           return "blue_border_label_field"
	        when "binfill_stations:side B"
	        
	           return "blue_border_label_field"
	        when "binfill_sort_stations"
	        
	           return "blue_border_no_fill_label_field" 
	         
	    end
	
    end
    
    
     
	 def override_build?
	   false
	 end
	 
	 def build_control(field_name,active_record,control)
	   
	  
	 end
end
#====================
#PACK GROUPS PLUGINS
#====================

  class CountsDropsGridPlugin < ApplicationHelper::GridPlugin
      
   def before_cell_render_styling(column_name,cell_value,record)
       htm = ""
       if cell_value.to_s == "n.a"
        htm = "<font class = 'disabled_outlet'>"
       else
          if column_name == "size_code" && cell_value
            htm = "<font color = 'blue'><strong>"
            
          elsif column_name == "standard_size_count_value" && cell_value
            htm = "<font color = 'green'><strong>"
          end
          if record.outlet1 == "n.a"
            htm = "<font color = 'gray'><strong>"
          end
       end
       
       return htm
   end
   def after_cell_render_styling(column_name,cell_value,record)
        '</font>'
      
   end
      
  end


   class PackGroupGridPlugin < ApplicationHelper::GridPlugin
     
   def before_cell_render_styling(column_name,cell_value,record)
       
       htm = ""
       nothing_done = true
       record.pack_group_outlets.each do |outlet|
        if (outlet.outlet1 != nil && outlet.outlet1 != "n.a") ||(outlet.outlet2 != nil && outlet.outlet2 != "n.a")||(outlet.outlet3 != nil && outlet.outlet3 != "n.a")||(outlet.outlet4 != nil && outlet.outlet4 != "n.a")||(outlet.outlet5 != nil && outlet.outlet5 != "n.a")||(outlet.outlet6 != nil && outlet.outlet6 != "n.a")||(outlet.outlet7 != nil && outlet.outlet7 != "n.a")||(outlet.outlet8 != nil && outlet.outlet8 != "n.a")||(outlet.outlet9 != nil && outlet.outlet9 != "n.a")||(outlet.outlet10 != nil && outlet.outlet10 != "n.a")||(outlet.outlet11 != nil && outlet.outlet11 != "n.a")||(outlet.outlet12 != nil && outlet.outlet12 != "n.a")
          nothing_done = false
          break
        end
      end
      
      if nothing_done == false
       htm = "<font color = 'green'>"
      else
        htm = "<font color = 'red'>"
      end
      
      if column_name == "color_sort_percentage"||column_name == "grade_code"
        htm += "<strong>"
      end 
       
       return htm
             
   end
   def after_cell_render_styling(column_name,cell_value,record)
        '</strong></font>'
      
   end
      
  end
  
  #======================================
  #PACK STATION FG ALLOCATION GRID PLUGIN
  #======================================
  
  class PackStationGridPlugin < ApplicationHelper::GridPlugin
     
   def before_cell_render_styling(column_name,cell_value,record)
       
       case column_name
       
         when "drop_code","table_code","station_code","drop_side_code"
          if record.grade
            return "<font color = 'blue'>"
          else
            "<font color = 'gray'>"
          end
        
         when "size_count","grade","marketing_variety","color_percentage","fg_product_code","carton_setup_code"
          if record.fg_product_code
             return "<font color = 'green'>"
          else
             "<font color = 'red'>"
          end
         else
          "<font color = 'black'>"
       end
             
   end
   
   def after_cell_render_styling(column_name,cell_value,record)
       '</font>'
      
   end
      
  end
  
  class BinfillStationGridPlugin < ApplicationHelper::GridPlugin
     
   def before_cell_render_styling(column_name,cell_value,record)
       
       case column_name
       
         when "drop_code","binfill_station_code"
          # if record.grade
            return "<font color = 'blue'>"
          #else
           # "<font color = 'gray'>"
          #end
        
         when "size","grade","marketing_variety"
          if record.rmt_product_code
             return "<font color = 'green'>"
          else
             "<font color = 'red'>"
          end
       
       end
             
   end
   
   def after_cell_render_styling(column_name,cell_value,record)
        '</strong></font>'
      
   end
      
  end
  
  
  #=================================
  #BINFILL SORT STATION GRID PLUGIN
  #=================================
  
  class BinfillSortStationGridPlugin < ApplicationHelper::GridPlugin
     
   def before_cell_render_styling(column_name,cell_value,record)
       
          if record.rmt_product_code
             return "<font color = 'green'>"
          else
             "<font color = 'red'>"
          end
       
             
   end
   
   def after_cell_render_styling(column_name,cell_value,record)
        '</strong></font>'
      
   end
      
  end
  
  
  
 end
