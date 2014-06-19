require File.dirname(__FILE__) + '/../../../app/helpers/application_helper.rb'
module SizerTemplatePlugins


  class CountsDropsTemplateGridPlugin < ApplicationHelper::GridPlugin
      
   def before_cell_render_styling(column_name,cell_value,record)
      if column_name == "standard_size_count_value"
        return "<font color = 'blue'>"
      elsif column_name == "size_code"
        return "<font color = 'indigo'>"
      elsif column_name.index("outlet") && cell_value && cell_value != "n.a"
        return "<font color = 'green'>"
      else
         return "<font color = 'gray'>"
      end
      
   end
   def after_cell_render_styling(column_name,cell_value,record)
        "</font>"
      
   end
      
  end


  class SizerTemplateGridPlugin < ApplicationHelper::GridPlugin
      
   def before_cell_render_styling(column_name,cell_value,record)
      if column_name == "template_name"
        return "<font color = 'blue'>"
      else
       return "<font color = 'black'>"
      end
      
   end
   def after_cell_render_styling(column_name,cell_value,record)
        "</font>"
      
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
  
  class SizerTemplateFormPlugin < ApplicationHelper::FormPlugin
     def get_cell_css_class(field_name,record)
	  
	    case field_name
	       when  "pack_groups"
	           if record.pack_group_templates.length > 0
	             return "green_label_field" 
	           else
	             return "red_label_field" 
	           end
	
           end
 
      end
  
 end 

   class PackGroupTemplateGridPlugin < ApplicationHelper::GridPlugin
     
   def before_cell_render_styling(column_name,cell_value,record)
       
        return "<font color = 'blue'>"
    
             
   end
   def after_cell_render_styling(column_name,cell_value,record)
        
      "</font>"
   end
      
  end
  
  
  
 end
