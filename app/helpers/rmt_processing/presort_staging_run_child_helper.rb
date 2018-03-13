module RmtProcessing::PresortStagingRunChildHelper

  def build_locations_grid(data_set,can_edit,can_delete)
    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_code',:col_width=>114}
    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'qty_bins_available',:settings =>{:target_action => '', :id_column => 'id'},:col_width=>130}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_age',:col_width=>125}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id',:col_width=>125}
    set_grid_min_width(1200)
    return get_data_grid(data_set,column_configs,MesScada::GridPlugins::RmtProcessing::BinLocationsPlugin.new(self, request),true)
  end

  def build_bins_grid(data_set,can_edit,can_delete)
    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_number',:col_width=>114}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'delivery_number',:col_width=>115}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_code',:col_width=>114}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code',:column_caption=>'farm',:col_width=>75}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'commodity_code',:column_caption=>'commodity',:col_width=>90}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_variety_code',:column_caption=>'rmt_variety',:col_width=>90}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'ripe_point_code',:column_caption=>'ripe_point',:col_width=>80}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'product_class_code',:column_caption=>'product_class',:col_width=>110}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'treatment_code',:column_caption=>'treatment',:col_width=>80}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'size_code',:column_caption=>'size',:col_width=>60}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'is_half_bin',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'orchard_code',:column_caption=>'orchard',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_tipped_id',:col_width=>209}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code1',:col_width=>130}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'destination_process_var',:col_width=>140}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_status',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'sealed_ca_date_time',:col_width=>135}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_on',:col_width=>141}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id',:col_width=>66}
    set_grid_min_width(1200)
    return get_data_grid(data_set,column_configs,nil,true)
  end

  def build_edit_child_status_form(presort_staging_run_child,action,caption,is_edit = nil,is_create_retry = nil)
      session[:presort_staging_run_child_form]= Hash.new
      statuses = get_statuses(presort_staging_run_child)
      field_configs = []
      field_configs << {:field_type => 'DropDownField',
                        :field_name => 'status',:settings => {:list => statuses}, :show_label => true}

     if presort_staging_run_child.status=='CANCELLED'
       build_form(presort_staging_run_child,field_configs,nil,'presort_staging_run_child',caption,is_edit)
     else
       build_form(presort_staging_run_child,field_configs,action,'presort_staging_run_child',caption,is_edit)
     end


  end

  def get_statuses(presort_staging_run_child)
    statuses=[]
    active_child =PresortStagingRunChild.find(:first,
                                              :joins=>"join presort_staging_runs p on p.id=presort_staging_run_children.presort_staging_run_id",
                                              :conditions=>"presort_staging_run_children.status='ACTIVE' and p.status='ACTIVE' and p.presort_unit='#{presort_staging_run_child.presort_staging_run.presort_unit}'")

    if presort_staging_run_child.status ==  'EDITING' && active_child
      statuses = ['EDITING','CANCELLED']
    elsif  presort_staging_run_child.status ==  'EDITING' && !active_child
      statuses = ['EDITING','ACTIVE','CANCELLED']
    elsif  presort_staging_run_child.status ==  'ACTIVE'
      bins_staged=PresortStagingRunChild.bins_staged(presort_staging_run_child.id)[0].length
      statuses=['ACTIVE','EDITING','STAGED']  if bins_staged == 0
      statuses=['ACTIVE','STAGED']  if bins_staged > 0
    elsif   presort_staging_run_child.status ==  'CANCELLED'
      statuses = ['CANCELLED']
    else   presort_staging_run_child.status ==  'STAGED'
    statuses=['STAGED']
    end
    parent = PresortStagingRun.find(presort_staging_run_child.presort_staging_run_id)
    statuses.delete_if {|x| x == "ACTIVE"  }if  parent.status !="ACTIVE"
    return statuses
  end

 def build_presort_staging_run_child_form(presort_staging_run_child,action,caption,is_edit = nil,is_create_retry = nil)
#	--------------------------------------------------------------------------------------------------
#	Define a set of observers for each composite foreign key- in effect an observer per combo involved
#	in a composite foreign key
#	--------------------------------------------------------------------------------------------------
	session[:presort_staging_run_child_form]= Hash.new
#	---------------------------------
#	 Define fields to build form from
#	---------------------------------


    farms = FarmGroup.find_by_sql("select distinct f.id,f.farm_code,pc.product_class_code
                                        from farms f
                                        inner join farm_groups fg on f.farm_group_id=fg.id
                                        inner join presort_staging_runs r on r.farm_group_id=fg.id
                                        left join product_classes pc on r.product_class_id=pc.id
                                        where r.id= #{session[:active_doc]['presort_staging_run']}
                                        and f.id not in (select farm_id from presort_staging_run_children where presort_staging_run_id=#{session[:active_doc]['presort_staging_run']}) ")
    parent_product_class_code=farms[0].product_class_code
    if parent_product_class_code != "2L"
      farms.select do |e|
        farms.delete(e) if e.farm_code=="0P"
      end
    end
    farm_codes= farms.map{|g|[g.farm_code,g.id]}
    farm_codes.unshift("<empty>")
	 field_configs = []
    if farm_codes.length == 1 && farm_codes[0]=="<empty>"
      field_configs << {:field_type => 'LabelField',
                        :field_name => 'farm', :non_db_field=>true,
                        :settings => {:static_value =>'no farms' ,:label_caption=>'farm code'}}
      build_form(presort_staging_run_child,field_configs,nil,'presort_staging_run_child',caption,is_edit)
    else
      field_configs << {:field_type => 'DropDownField',
                        :field_name => 'farm_id', :non_db_field=>true,
                        :settings => {:list => farm_codes},:label_caption=>'farm code'}
      build_form(presort_staging_run_child,field_configs,action,'presort_staging_run_child',caption,is_edit)

    end



end


 def build_presort_staging_run_child_search_form(presort_staging_run_child,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:presort_staging_run_child_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = []
	statuses = PresortStagingRunChild.find_by_sql('select distinct status from presort_staging_run_children').map{|g|[g.status]}
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'status',
						:settings => {:list => statuses}}

	build_form(presort_staging_run_child,field_configs,action,'presort_staging_run_child',caption,false)

end



 def build_presort_staging_run_child_grid(data_set,can_edit,can_delete,grid_cmd=nil)
   presort_staging_run=PresortStagingRun.find(session[:active_doc]['presort_staging_run'])
   column_configs = []
   grid_command=nil
   farm_codes=[]
   if presort_staging_run
     farm_codes = FarmGroup.find_by_sql("select distinct f.id,f.farm_code
                                        from farms f
                                        inner join farm_groups fg on f.farm_group_id=fg.id
                                        inner join presort_staging_runs r on r.farm_group_id=fg.id
                                        where r.id= #{presort_staging_run.id}
                                        and f.id not in (select farm_id from presort_staging_run_children where presort_staging_run_id=#{presort_staging_run.id})")
   end

  if presort_staging_run.status!='CANCELLED'
    if grid_cmd
    grid_command =    {:field_type=>'link_window_field',:field_name =>'new_child_run',
                       :settings =>
                           {
                               :host_and_port =>request.host_with_port.to_s,
                               :controller =>request.path_parameters['controller'].to_s,
                               :target_action =>'new_presort_staging_run_child',
                               :link_text => 'new_child_run',
                               :id_value=>'id'
                           }}
      end
  end
   if !session[:parent]

    if can_delete
      column_configs << {:field_type => 'link_window',:field_name => 'delete presort_staging_run_child',
        :column_caption => 'Delete',
        :settings =>
           {:link_text => 'delete',
          :target_action => 'delete_presort_staging_run_child',
          :id_column => 'id',
          :null_test => "['status'].upcase == 'ACTIVE' ||
                          active_record['status'].upcase == 'CANCELLED' ||
                          active_record['status'].upcase == 'STAGED' " }}
    end
   end
  #end
   column_configs << {:field_type => 'text', :field_name => 'presort_staging_run_child_code',:col_width=>250}
  column_configs << {:field_type => 'text', :field_name => 'farm_code', :column_caption => 'Farm code'}
   if session[:parent]
     column_configs << {:field_type => 'text', :field_name => 'status',:settings =>{:target_action => 'edit_child_status', :id_column => 'id'}, :column_caption => 'Status'}
   else
     column_configs << {:field_type => 'link_window', :field_name => 'status',:settings =>{:target_action => 'edit_child_status', :id_column => 'id'}, :column_caption => 'Status'}
   end
  column_configs << {:field_type => 'link_window', :field_name => 'bins_available',:settings =>{:link_text=>'bins_available',:target_action => 'bins_available', :id_column => 'id'},:col_width=>100}
  column_configs << {:field_type => 'link_window', :field_name => 'bins_locations_available',:settings =>{:link_text=>'locations_available',:target_action => 'bins_available_locations', :id_column => 'id'},:col_width=>100}
  column_configs << {:field_type => 'link_window', :field_name => 'bins_staged',:settings =>{:link_text=>'bins_staged',:target_action => 'show_bins_staged', :id_column => 'id'},:col_width=>100}
	column_configs << {:field_type => 'text', :field_name => 'created_on', :data_type => 'date', :column_caption => 'Created on'}
	column_configs << {:field_type => 'text', :field_name => 'updated_on', :data_type => 'date', :column_caption => 'Updated on'}
	column_configs << {:field_type => 'text', :field_name => 'created_by', :column_caption => 'Created by'}
	column_configs << {:field_type => 'text', :field_name => 'completed_on', :data_type => 'date', :column_caption => 'Completed on'}
	column_configs << {:field_type => 'text', :field_name => 'updated_by', :column_caption => 'Updated by'}
  column_configs << {:field_type => 'text', :field_name => 'farm_id'}
  column_configs << {:field_type => 'text', :field_name => 'id'}

	get_data_grid(data_set,column_configs,MesScada::GridPlugins::RmtProcessing::PresortStagingRunChildGridPlugin.new(self,request),true,grid_command)
end





end
