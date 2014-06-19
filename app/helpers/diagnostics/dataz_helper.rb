module Diagnostics::DatazHelper
  
  def build_bin_search_form
  
  on_complete_js = "\n img = document.getElementById('img_bins_tipped_bin_time_search');"
  on_complete_js += "\n if(img != null)img.style.display = 'none';"
  
	
    time_search_observer  = {:updated_field_id => "ajax_distributor_cell",
					 :remote_method => 'bin_time_search_enabled',
					 :on_complete_js => on_complete_js }
  
  session[:bin_form]= Hash.new
  combos_js_for_bins = "\n img = document.getElementById('img_bins_tipped_production_schedule_name');"
  combos_js_for_bins += "\n if(img != null)img.style.display = 'none';"
	#Observers
	production_schedule_name_observer  = {:updated_field_id => "production_run_code_cell",
					 :remote_method => 'bin_production_schedule_name_changed',
					 :on_completed_js => combos_js_for_bins}
					 
  #session[:bin_form][:production_schedule_name_observer] = production_schedule_name_observer
  
  line_codes = Line.find(:all).map{|f|[f.line_code]}  
  line_codes.unshift("<empty>")
  
  class_descriptions = ProductClass.find(:all).map{|c|[c.product_class_description]}
  class_descriptions.unshift("<empty>")
  
  track_indicator_codes = TrackIndicator.find(:all).map{|f|[f.track_indicator_code]}
  track_indicator_codes.unshift("<empty>")
  
  production_schedule_names = ProductionSchedule.find(:all).map{|f|[f.production_schedule_name]}
  production_schedule_names.unshift("<empty>")
  
  production_run_codes = "<empty>"
  
  @bin = BinsTipped.new
  #@bin.tipped_date_time = '2007/02/02' #AJAX
  #@bin.delivery_id = "<empty>"
  #@bin.weight = 0.0
  #@bin.farm_code = "<empty>"
 # @bin.delivery_no = "<empty>"
  #@bin.bin_receive_datetime = "<empty>"
  #@bin.tipped_in_reworks = false
  #@bin.line_code = "<empty>"
  #@bin.production_schedule_name = "<empty>"
  #@bin.track_indicator_code = "<empty>"
  
   field_configs = Array.new
    
   field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'bin_id'}
						
   field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'bin_time_search',
						:observer => time_search_observer}
   
   field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'tipped_date_time_from'}
						
	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'tipped_date_time_to'}
   
   field_configs[field_configs.length()] = {:field_type => 'HiddenField',
						:field_name => 'ajax_distributor',
						:non_db_field => true}
						
   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'production_schedule_name',
						:settings => {:list => production_schedule_names},
						:observer => production_schedule_name_observer}
   
   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'production_run_code',
						:settings => {:list => production_run_codes}}
   
   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'line_code',
						:settings => {:list => line_codes}}
						
   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'class_description',
						:settings => {:list => class_descriptions}}
   
   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'track_indicator_code',
						:settings => {:list => track_indicator_codes}}
  
  
  
    build_form(@bin,field_configs,"bin_search_submit",'bins_tipped','search')
  end
  
  def build_bins_grid(data_set,multi_select=nil)

    column_configs = Array.new
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'bin_id'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'production_schedule_name'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'line_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'tipped_date_time'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'weight'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'production_run_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => "delivery_id"}
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'class_description'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'farm_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => "delivery_no"}
	
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'track_indicator_code'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => "bin_receive_datetime"}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'tipped_in_reworks'}
#    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => "attributes['season_code']", :column_caption => 'season_code'}
#    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'id'}
#    
     column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'id',
      	   :settings => 
      		 {:link_text => 'view_bin',
      		  :target_action => 'view_bin',
      		  :id_column => 'id'}}
   
    @multi_select = "selected_rebins" if multi_select

	
 return get_data_grid(data_set,column_configs)

end
  
  
end