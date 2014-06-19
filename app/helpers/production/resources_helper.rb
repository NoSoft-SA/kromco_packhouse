module Production::ResourcesHelper
 
 
 #=============================================================
 #PALLET LABEL STATION
 #=============================================================
 def build_pallet_label_station_form(pallet_label_station,action,caption,is_edit = nil,is_create_retry = nil)

    codes = Facility.find_all_by_facility_type_code("packhouse").map{|g|[g.facility_code]}
	field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'pallet_label_station_code'}

    if is_edit == false					
	 field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'packhouse_code',
						:settings => {:list => codes}}
	else
	 field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'packhouse_code'}
	end
 
	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'ip_address'}

	build_form(pallet_label_station,field_configs,action,'pallet_label_station',caption,is_edit)

end

def build_pallet_label_station_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'pallet_label_station_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'ip_address'}
	column_configs[2] = {:field_type => 'text',:field_name => 'packhouse_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit pallet_label_station',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_pallet_label_station',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete pallet_label_station',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_pallet_label_station',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 #=================================================================
 #REBIN LABEL STATION CODE
 #=================================================================
 def build_rebin_label_station_form(rebin_label_station,action,caption,is_edit = nil,is_create_retry = nil)

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    codes = Facility.find_all_by_facility_type_code("packhouse").map{|g|[g.facility_code]}
	field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'rebin_label_station_code'}
	
	if is_edit == false					
	 field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'packhouse_code',
						:settings => {:list => codes}}
	else
	 field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'packhouse_code'}
	end
	

	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'ip_address'}

	build_form(rebin_label_station,field_configs,action,'rebin_label_station',caption,is_edit)

end
 

def build_rebin_label_station_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'rebin_label_station_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'ip_address'}
	column_configs[2] = {:field_type => 'text',:field_name => 'packhouse_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit rebin_label_station',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_rebin_label_station',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete rebin_label_station',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_rebin_label_station',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

 #===============================================================================
 #CARTON LABEL STATION CODE
 #===============================================================================
 
 def build_carton_label_station_form(carton_label_station,action,caption,is_edit = nil,is_create_retry = nil)

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------

    codes = Facility.find_all_by_facility_type_code("packhouse").map{|g|[g.facility_code]}
  
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'carton_label_station_code'}
						
	 if is_edit == false					
	 field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'packhouse_code',
						:settings => {:list => codes}}
	else
	 field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'packhouse_code'}
	end

	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'ip_address'}

    field_configs[3] = {:field_type => 'CheckBox',
						:field_name => 'is_reworks_station'}

	build_form(carton_label_station,field_configs,action,'carton_label_station',caption,is_edit)

end
 
 def build_carton_label_station_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'carton_label_station_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'ip_address'}
	column_configs[2] = {:field_type => 'text',:field_name => 'packhouse_code'}
  column_configs[3] = {:field_type => 'text',:field_name => 'is_reworks_station'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit carton_label_station',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_carton_label_station',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete carton_label_station',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_carton_label_station',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 def build_add_carton_label_station_form(action,caption)
    
    codes = CartonLabelStation.find(:all).map {|g|[g.carton_label_station_code,g.id]}
    field_configs = Array.new
	field_configs[0] = {:field_type => 'DropDownField',
						:field_name => 'carton_label_station_code',
						:settings => {:list => codes}}


	build_form(nil,field_configs,action,'carton_label_station',caption)
 
 
 
 end
 
 
 #==================================================================================
 #BINTIP STATION CODE
 #==================================================================================
 
 
 def build_add_bintip_station_form(action,caption)
    
    codes = BintipStation.find(:all).map {|g|[g.bintip_station_code,g.id]}
    field_configs = Array.new
	field_configs[0] = {:field_type => 'DropDownField',
						:field_name => 'bintip_station_code',
						:settings => {:list => codes}}


	build_form(nil,field_configs,action,'bintip_station',caption)
 
 
 
 end
 
 
 
  def build_bintip_station_form(bintip_station,action,caption,is_edit = nil,is_create_retry = nil)

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    codes = Facility.find_all_by_facility_type_code("packhouse").map{|g|[g.facility_code]}
	field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'bintip_station_code'}
						
	 if is_edit == false					
	 field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'packhouse_code',
						:settings => {:list => codes}}
	else
	 field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'packhouse_code'}
	end

	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'ip_address'}

	build_form(bintip_station,field_configs,action,'bintip_station',caption,is_edit)

end
 
def build_bintip_station_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'bintip_station_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'ip_address'}
	column_configs[2] = {:field_type => 'text',:field_name => 'packhouse_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit bintip_station',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_bintip_station',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete bintip_station',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_bintip_station',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end
 
 #====================================================================================
 #LINE CONFIG CODE
 #====================================================================================
  def build_line_config_form(line_config,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:line_config_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'line_config_code'}

	build_form(line_config,field_configs,action,'line_config',caption,is_edit)

end
 
 def build_line_config_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'line_config_code'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit line_config',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_line_config',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete line_config',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_line_config',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

#=====================================================================
#SKIP CODE
#=====================================================================
 def build_skip_form(skip,action,caption,is_edit = nil,is_create_retry = nil)


   codes = Facility.find_all_by_facility_type_code("packhouse").map{|g|[g.facility_code]}

	session[:skip_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'skip_code'}
    
     if is_edit == false					
	 field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'packhouse_code',
						:settings => {:list => codes}}
	else
	 field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'packhouse_code'}
	end
	field_configs[2] = {:field_type => 'TextField',
						:field_name => 'skip_description'}

	field_configs[3] = {:field_type => 'TextField',
						:field_name => 'number_of_bays'}
						
	field_configs[4] = {:field_type => 'TextField',
						:field_name => 'ip_address'}

	build_form(skip,field_configs,action,'skip',caption,is_edit)

end

 def build_skip_grid(data_set,can_edit,can_delete)

	column_configs = Array.new
	column_configs[0] = {:field_type => 'text',:field_name => 'skip_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'packhouse_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'skip_description'}
	column_configs[3] = {:field_type => 'text',:field_name => 'number_of_bays'}
	column_configs[4] = {:field_type => 'text',:field_name => 'ip_address'}
#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit skip',
			:settings => 
				 {:link_text => 'edit',
				:target_action => 'edit_skip',
				:id_column => 'id'}}
	end

	if can_delete
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete skip',
			:settings => 
				 {:link_text => 'delete',
				:target_action => 'delete_skip',
				:id_column => 'id'}}
	end
 return get_data_grid(data_set,column_configs)
end

def build_add_skip_form(action,caption)

    codes = Skip.find(:all).map {|g|[g.skip_code,g.id]}
    field_configs = Array.new
	field_configs[0] = {:field_type => 'DropDownField',
						:field_name => 'skip_code',
						:settings => {:list => codes}}


	build_form(nil,field_configs,action,'skip',caption)
 


end


#======================================================================
#SUBLINES CODE
#======================================================================

def build_subline_form(action,caption)

	line_config_codes = LineConfig.find_by_sql('select distinct line_config_code from line_configs').map{|g|[g.line_config_code]}
	line_config_codes.unshift("<empty>")
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = Array.new
	 field_configs[0] = {:field_type => 'TextField',
						:field_name => 'subline_code'}

	 field_configs[1] = {:field_type => 'TextField',
						:field_name => 'subline_description'}

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (line_config_id) on related table: line_configs
#	----------------------------------------------------------------------------------------------
	field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'line_config_code',
						:settings => {:list => line_config_codes}}
 
	build_form(nil,field_configs,action,'subline',caption)

end


 def build_line_config_tree(line_config,line_config_id)
 
 line_config_code = line_config.line_config_code
 
 menu1 = ApplicationHelper::ContextMenu.new("line_config","line_config")
 menu1.add_command("change name",url_for(:action => "change_line_config_name"))
 #menu1.add_command("clone config",url_for(:action => "clone_line_config_name"))
 
 #sub components
 menu1.add_command("add bintip station",url_for(:action => "add_bintip_station"))
 menu1.add_command("add carton label station",url_for(:action => "add_carton_label_station"))
 menu1.add_command("add drop to side A",url_for(:action => "add_drop_A"))
 menu1.add_command("add drop to side B",url_for(:action => "add_drop_B"))
 #menu1.add_command("add sizer",url_for(:action => "add_sizer"))
 menu1.add_command("add drop to front",url_for(:action => "add_drop_front"))
 menu1.add_command("add drop to back",url_for(:action => "add_drop_back"))
 menu1.add_command("add skip",url_for(:action => "add_skip"))
 menu1.add_command("add subline",url_for(:action => "add_subline"))
 menu1.add_command("add binfill sort station",url_for(:action => "add_binfill_sort_station"))
 
 menu2 = ApplicationHelper::ContextMenu.new("bintip_station","line_config")
 menu2.add_command("remove bintip station",url_for(:action => "remove_bintip_station"))
  
 menu4 = ApplicationHelper::ContextMenu.new("binfill_station","line_config")
 menu4.add_command("remove binfill station",url_for(:action => "remove_binfill_station"))
 menu4.add_command("edit barcode",url_for(:action => "edit_binfill_barcode"))
 
 menu5 = ApplicationHelper::ContextMenu.new("skip","line_config")
 menu5.add_command("remove skip",url_for(:action => "remove_skip"))
 
 menu6 = ApplicationHelper::ContextMenu.new("subline","line_config")
 menu6.add_command("remove subline",url_for(:action => "remove_subline"))
 menu6.add_command("show line config",url_for(:action => "show_subline_config"))
 
 menu7 = ApplicationHelper::ContextMenu.new("drop","line_config")
 menu7.add_command("remove drop",url_for(:action => "remove_drop"))
 menu7.add_command("add table",url_for(:action => "add_table"))
 menu7.add_command("edit drop",url_for(:action => "edit_drop"))
 menu7.add_command("add binfill station",url_for(:action => "add_binfill_station"))
 
 menu8 = ApplicationHelper::ContextMenu.new("table","line_config")
 menu8.add_command("remove table",url_for(:action => "remove_table"))
 menu8.add_command("edit table",url_for(:action => "edit_table"))
 menu8.add_command("add pack station",url_for(:action => "add_pack_station"))
 
 menu9 = ApplicationHelper::ContextMenu.new("pack_station","line_config")
 menu9.add_command("remove station",url_for(:action => "remove_pack_station"))
 menu9.add_command("edit barcode",url_for(:action => "edit_barcode"))
 
 menu10 = ApplicationHelper::ContextMenu.new("carton_label_station","line_config")
 menu10.add_command("remove station",url_for(:action => "remove_carton_label_station"))
 
 menu11 = ApplicationHelper::ContextMenu.new("binfill_sort_station","line_config")
 menu11.add_command("remove binfill sort station",url_for(:action => "remove_binfill_sort_station"))
 menu11.add_command("edit barcode",url_for(:action => "edit_binfill_sort_station_barcode"))  
  
  root_node = ApplicationHelper::TreeNode.new(line_config_code,"line_config",true,"line_config",line_config_id.to_s)
  bintip_stations_node = root_node.add_child("bintip_stations","bintip_stations","root")
  #add bintip stations to container node
   line_config.bintip_stations.each do |bintip_station|
    bintip_stations_node.add_child(bintip_station.bintip_station_code,"bintip_station",bintip_station.id.to_s)
   end
 
  carton_label_stations_node = root_node.add_child("carton_label_stations","carton_label_stations","root")
  line_config.carton_label_stations.each do |carton_label_station|
   carton_label_stations_node.add_child(carton_label_station.carton_label_station_code,"carton_label_station",carton_label_station.id.to_s)
  
  end
  
#  #-------------------------------------------------------------------------------
#  #Build a single list of carton drops and binfill drops, sorted by the respective
#  #drop codes
#  #------------------------------------------------------------------------------
#  bdrops = line_config.binfill_drops.map{|bd|bd}
#  cdrops = line_config.carton_drops.map{|cd|cd}
#  drops = cdrops.concat(bdrops)
#  
#  drops.sort!{|x,y|
#   if x.class.to_s == "CartonDrop" && y.class.to_s == "BinfillDrop"
#     x.carton_drop_code <=> y.binfill_drop_code
#  elsif x.class.to_s == "CartonDrop" && y.class.to_s == "CartonDrop"
#    x.carton_drop_code <=> y.carton_drop_code
#  elsif x.class.to_s == "BinfillDrop" && y.class.to_s == "BinfillDrop"
#    x.binfill_drop_code <=> y.binfill_drop_code
#  else
#    x.binfill_drop_code <=> y.carton_drop_code
#  end
#  }
  
  drops_node = root_node.add_child("drops","drops","root")
  line_config.drops.each do |drop|
    
     drop_node = drops_node.add_child("drop_" + drop.drop_code.to_s + ":" + drop.drop_side_code.upcase,"drop",drop.id.to_s)
      drop.tables.each do |table|
         node_name = "T" + table.table_code.to_s + "(table_" + table.table_caption.to_s + ")"
         node_name = "T" + table.table_code.to_s if !table.table_caption
         table_node = drop_node.add_child(node_name,"table",drop.id.to_s + "$" + table.id.to_s)
         table.carton_pack_stations.each do |station|
           table_node.add_child(station.station_code.to_s,"pack_station",table.id.to_s + "$" + station.id.to_s)
         end
      end
     
      drop.binfill_stations.each do |binfill_station|
        drop_node.add_child(binfill_station.binfill_station_code.to_s,"binfill_station",drop.id.to_s + "$" + binfill_station.id.to_s)
      end
  end
  
  #root_node.add_child("sizers","sizers","sizers")
  skips_node = root_node.add_child("skips","skips","root")
  line_config.skips.each do |skip|
   skips_node.add_child(skip.skip_code.to_s,"skip",skip.id.to_s)
  end
  #binfill sort stations
  binfill_sort_stations_node = root_node.add_child("binfill_sort_stations","binfill_sort_stations","root")
  line_config.binfill_sort_stations.each do |binfill_sort_station|
    binfill_sort_stations_node.add_child(binfill_sort_station.binfill_sort_station_code,"binfill_sort_station",binfill_sort_station.id.to_s)
  end
  

   
  sublines_node = root_node.add_child("sublines","sublines","root")
  line_config.sublines.each do |subline|
    sublines_node.add_child(subline.subline_code,"subline", subline.id.to_s)
  
  end
  

#  packhouses_node = root_node.add_child("packhouses","packhouses")
#  stores_node = root_node.add_child("stores","stores")
#  #list of packhouses
#  packhouses = Facility.get_packhouses
#  packhouses.each do |packhouse|
#    packhouse_node = packhouses_node.add_child(packhouse.facility_code,"packhouse",packhouse.id.to_s)
#  
#  end
  
  tree = ApplicationHelper::TreeView.new(root_node,"line_config")
  
  tree.add_context_menu(menu1)
  tree.add_context_menu(menu2)
  tree.add_context_menu(menu4)
  tree.add_context_menu(menu5)
  tree.add_context_menu(menu6)
  tree.add_context_menu(menu7)
  tree.add_context_menu(menu8)
  tree.add_context_menu(menu9)
  tree.add_context_menu(menu10)
  tree.add_context_menu(menu11)
  
  tree.render
 
 
 end
 
 #=========================================================
 # FACILITIES CODE
 #=========================================================
 
 def build_line_form(line,action,caption,is_edit = nil)
 
    field_configs = Array.new
	field_configs[0] = {:field_type => 'TextField',
						:field_name => 'line_code'}
	
	field_configs[1] = {:field_type => 'TextField',
						:field_name => 'line_phc'}

	build_form(line,field_configs,action,'line',caption,is_edit)
 
 
 end
 
 def build_set_line_config_form(action,caption)
 
     line_config_codes = LineConfig.find_by_sql('select distinct line_config_code,id from line_configs').map{|g|[g.line_config_code,g.id]}
	
 
	 field_configs = Array.new
	

#	----------------------------------------------------------------------------------------------
#	Combo fields to represent foreign key (line_config_id) on related table: line_configs
#	----------------------------------------------------------------------------------------------
	field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'line_config_code',
						:settings => {:list => line_config_codes}}
 
	build_form(nil,field_configs,action,'line_config',caption)
 
 
 
 
 end
 
 
 
 
 def build_facilities_tree
 

  menu1 = ApplicationHelper::ContextMenu.new("packhouses","facilities")
  menu1.add_command("add packhouse",url_for(:action => "add_packhouse"))
 
  menu2 = ApplicationHelper::ContextMenu.new("packhouse","facilities")
  menu2.add_command("remove packhouse",url_for(:action => "remove_packhouse"))
  menu2.add_command("change name",url_for(:action => "edit_packhouse"))
  menu2.add_command("add production line",url_for(:action => "add_production_line"))
 
  menu3 = ApplicationHelper::ContextMenu.new("line","facilities")
  menu3.add_command("edit line",url_for(:action => "edit_line"))
  menu3.add_command("delete line",url_for(:action => "delete_line"))
  menu3.add_command("set line config",url_for(:action => "set_line_config"))
 
  root_node = ApplicationHelper::TreeNode.new("facilities","facilities",true,"facilities")
  packhouses_node = root_node.add_child("packhouses","packhouses","root")
  stores_node = root_node.add_child("stores","stores")
  #list of packhouses
  packhouses = Facility.get_packhouses
   
  packhouses.each do |packhouse|
    prod_resources = packhouse.production_resources
    packhouse_node = packhouses_node.add_child(packhouse.facility_code,"packhouse",packhouse.id.to_s)
    lines_node = packhouse_node.add_child("lines","lines",packhouse.id.to_s)
    prod_resources.each do|prod_resource|
     if prod_resource.resource_type_code == "line"
      line_node = lines_node.add_child(prod_resource.line.line_code,"line",prod_resource.line.id.to_s)
      if prod_resource.line.line_config
        
        line_node.add_child(prod_resource.line.line_config.line_config_code,"line_config",prod_resource.line.id.to_s + "," + prod_resource.line.line_config.id.to_s)
      end
     end
    end
    rebin_label_stations_node = packhouse_node.add_child("rebin label stations","rebin_label_stations")
    prod_resources.each do |prod_resource|
     if prod_resource.rebin_label_station
      rebin_label_stations_node.add_child(prod_resource.rebin_label_station.rebin_label_station_code,"rebin_label_station",prod_resource.rebin_label_station.id.to_s)
     end
    end
    pallet_label_stations_node = packhouse_node.add_child("pallet label stations","pallet_label_stations")
    prod_resources.each do |prod_resource|
     if prod_resource.pallet_label_station
      pallet_label_stations_node.add_child(prod_resource.pallet_label_station.pallet_label_station_code,"pallet_label_station",prod_resource.pallet_label_station.id.to_s)
     end
    end
  end
  
  tree = ApplicationHelper::TreeView.new(root_node,"facilities")
   tree.add_context_menu(menu1)
   tree.add_context_menu(menu2)
   tree.add_context_menu(menu3)
  tree.render
 
 end
 
 
 end