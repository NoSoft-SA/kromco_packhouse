module RmtProcessing::PresortStagingRunHelper

  def build_locations_grid(data_set,can_edit,can_delete)
    require File.dirname(__FILE__) + "/../../../app/helpers/rmt_processing/bin_locations_plugin.rb"
    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_code',:col_width=>114}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'link_window', :field_name => 'qty_bins_available',:settings =>{:target_action => '', :id_column => 'id'},:col_width=>130}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'age',:column_caption=>'bin_age',:col_width=>125}
    set_grid_min_width(1200)
    return get_data_grid(data_set,column_configs,RmtProcessingPlugins::BinLocationsPlugin.new(self,request),true)
  end

  def build_bins_grid(data_set,can_edit,can_delete)
    #require File.dirname(__FILE__) + "/../../../app/helpers/rmt_processing/bin_plugins.rb"
    column_configs = Array.new
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'bin_number',:col_width=>114}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'delivery_number',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'location_code',:col_width=>114}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'farm_code',:column_caption=>'farm',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'commodity_code',:col_width=>105}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rmt_variety_code',:col_width=>121}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'ripe_point_code',:col_width=>50}
    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'size',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'is_half_bin',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'orchard_code',:column_caption=>'orchard',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'production_run_tipped_id',:col_width=>209}
    #column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'presort_staging_run_child_code',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'indicator_code1',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'destination_process_var',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'rebin_status',:col_width=>100}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'sealed_ca_date_time',:col_width=>104}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'created_on',:col_width=>141}
    column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id',:col_width=>66}
    set_grid_min_width(1200)
    return get_data_grid(data_set,column_configs,nil,true)
  end

  def build_edit_presort_staging_run_form(presort_staging_run,action,caption,is_edit = nil,is_create_retry = nil)
    session[:presort_staging_run_form]= Hash.new


#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
    field_configs = []
    statuses = get_statuses(presort_staging_run)
    if presort_staging_run.status=='EDITING'

      rmt_variety_codes=RmtVariety.find(:all).map{|p|[p.rmt_variety_code,p.id]}
      season_codes=Season.find(:all).map{|p|[p.season_code,p.id]}
      track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql('select  id,track_slms_indicator_code from track_slms_indicators').map{|g|[g.track_slms_indicator_code,g.id]}
      farm_groups = FarmGroup.find_by_sql('select  id,farm_group_code from farm_groups').map{|g|[g.farm_group_code,g.id]}
      ripe_point_codes=RipePoint.find_by_sql("select  id,ripe_point_code from ripe_points").map{|p|[p.ripe_point_code,p.id]}
      combos_js_for_rmt_variety_code = gen_combos_clear_js_for_combos(["presort_staging_run_rmt_variety_id", "presort_staging_run_season_id"])
      rmt_variety_code_observer = {:updated_field_id => "season_id_cell",
                                   :remote_method =>'staging_run_rmt_variety_code_changed',
                                   :on_completed_js => combos_js_for_rmt_variety_code["presort_staging_run_rmt_variety_id"]
      }

      #link_values=calc_link_values(presort_staging_run)
      field_configs << {:field_type => 'LabelField',
                        :field_name => 'presort_run_code', :show_label => true}

      field_configs << {:field_type => 'DropDownField',
                        :field_name => 'status',:settings => {:list => statuses}, :show_label => true}

      field_configs << {:field_type => 'DropDownField',
                        :field_name => 'rmt_variety_id?required',
                        :settings => {:list => rmt_variety_codes,:label_caption=>'rmt variety code'},:observer => rmt_variety_code_observer}

      field_configs << {:field_type => 'DropDownField',
                        :field_name => 'ripe_point_id?required',
                        :settings => {:list => ripe_point_codes,:label_caption=>'ripe point code'}}

      field_configs << {:field_type => 'DropDownField',
                        :field_name => 'season_id?required',
                        :settings => {:list => season_codes,:label_caption=>'season code'}}

      field_configs << {:field_type => 'DropDownField',
                        :field_name => 'track_slms_indicator_id?required',
                        :settings => {:list => track_slms_indicator_codes},:label_caption=>'track slms indicator code'}

      field_configs << {:field_type => 'DropDownField',
                        :field_name => 'farm_group_id?required',
                        :settings => {:list => farm_groups},:label_caption=>'farm group code'}

      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings   => {
                                               :host_and_port =>request.host_with_port.to_s,
                                               :target_action => 'bins_available',
                                               :link_text     => "bins_available",#link_values['bins_available'].to_s,
                                               :id_value      => presort_staging_run.id  } }

      #field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'cop', :non_db_field=>true, :settings => { :is_separator => false, :static_value => '', :css_class => "borderless_label_field"}}


      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings   => {
                                               :host_and_port =>request.host_with_port.to_s,
                                               :target_action => 'bins_available_locations',
                                               :link_text     => "bins_available_locations",#link_values['bins_available_locations'].to_s,
                                               :id_value      => presort_staging_run.id  } }

      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings   => {
                                               :host_and_port =>request.host_with_port.to_s,
                                               :target_action => 'show_bins_staged',
                                               :link_text     => "bins_staged",#link_values['bins_staged'].to_s,
                                               :id_value      => presort_staging_run.id  } }


      field_configs[field_configs.length()] = {:field_type => 'Screen',
                                               :field_name =>"child_form1",
                                               :settings   =>{
                                               :controller    =>"rmt_processing/presort_staging_run_child",
                                               :target_action => 'list_presort_staging_run_children',
                                               :width         => 1000, :height =>300,
                                               :id_value      => presort_staging_run.id.to_s,
                                               :no_scroll     => true}}


    else
      season_code=Season.find(presort_staging_run.season_id).season_code
      farm_group_code = FarmGroup.find(presort_staging_run.farm_group_id).farm_group_code
      rmt_variety_code=RmtVariety.find(presort_staging_run.rmt_variety_id).rmt_variety_code
      track_slms_indicator_code = TrackSlmsIndicator.find(presort_staging_run.track_slms_indicator_id).track_slms_indicator_code
      ripe_point_code=RipePoint.find(presort_staging_run.ripe_point_id).ripe_point_code

      #link_values=calc_link_values(presort_staging_run)

      field_configs << {:field_type => 'LabelField',
                        :field_name => 'presort_run_code', :show_label => true}

      #field_configs << {:field_type => 'LabelField',
      #                  :field_name => 'status', :show_label => true}
      field_configs << {:field_type => 'DropDownField',
                        :field_name => 'status',:settings => {:list => statuses}, :show_label => true}

      field_configs << {:field_type => 'LabelField',
                        :field_name => 'rmt_variety_id',
                        :settings => {:label_caption=>'rmt variety code',:static_value =>rmt_variety_code, :show_label => true}}

      field_configs << {:field_type => 'LabelField',
                        :field_name => 'ripe_point_id',
                        :settings => {:label_caption => 'ripe point code',:static_value=>ripe_point_code, :show_label => true}}

      field_configs << {:field_type => 'LabelField',
                        :field_name => 'season_id',
                        :settings => {:label_caption=>'season code',:static_value =>season_code, :show_label => true}}

      field_configs << {:field_type => 'LabelField',
                        :field_name => 'track_slms_indicator_id',
                        :settings => {:label_caption=>'track slms indicator code',:static_value =>track_slms_indicator_code, :show_label => true}}

      field_configs << {:field_type => 'LabelField',
                        :field_name => 'farm_group_id',
                        :settings => {:label_caption=>'farm group code',:static_value =>farm_group_code, :show_label => true} }

      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings   => {
                                                   :host_and_port =>request.host_with_port.to_s,
                                                   :target_action => 'bins_available',
                                                   :link_text     => 'bins_available',#link_values['bins_available'].to_s,
                                                   :id_value      => presort_staging_run.id  } }

      #field_configs[field_configs.length()] = {:field_type => 'LabelField', :field_name => 'cop', :non_db_field=>true, :settings => { :is_separator => false, :static_value => '', :css_class => "borderless_label_field"}}


      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings   => {
                                                   :host_and_port =>request.host_with_port.to_s,
                                                   :target_action => 'bins_available_locations',
                                                   :link_text     => 'bins_available_locations',#link_values['bins_available_locations'].to_s,
                                                   :id_value      => presort_staging_run.id  } }

      field_configs[field_configs.length()] = {:field_type => 'LinkWindowField',
                                               :field_name => '',
                                               :settings   => {
                                                   :host_and_port =>request.host_with_port.to_s,
                                                   :target_action => 'show_bins_staged',
                                                   :link_text     => 'bins_staged',#link_values['bins_staged'].to_s,
                                                   :id_value      => presort_staging_run.id  } }

      field_configs[field_configs.length()] = {:field_type => 'Screen',
                                               :field_name =>"child_form1",
                                               :settings   =>{
                                                   :controller    =>"rmt_processing/presort_staging_run_child",
                                                   :target_action => 'list_presort_staging_run_children',
                                                   :width         => 1000, :height =>300,
                                                   :id_value      => presort_staging_run.id.to_s,
                                                   :no_scroll     => true}}

    end

    if presort_staging_run.status
      @submit_button_align = "left"
      set_form_layout "2", nil,1,10
    end
    #if presort_staging_run.status=='EDITING'
      build_form(presort_staging_run,field_configs,action,'presort_staging_run',caption,is_edit)
    #else
    #  build_form(presort_staging_run,field_configs,nil,'presort_staging_run',caption,is_edit)
    #end

  end

  def get_statuses(presort_staging_run)
    statuses=[]
    active_run =PresortStagingRun.find_by_status("ACTIVE")
    #if presort_staging_run.id==active_run.id
    #  statuses = ['ACTIVE','EDITING','CANCELLED']
    if presort_staging_run.status ==  'EDITING' && active_run
      statuses = ['EDITING','CANCELLED']
    elsif  presort_staging_run.status ==  'EDITING' && !active_run
      statuses = ['EDITING','ACTIVE','CANCELLED']
    elsif  presort_staging_run.status ==  'ACTIVE'
      bins_staged=PresortStagingRun.bins_staged(presort_staging_run.id)[0].length
      active_children=PresortStagingRunChild.active_chidren(presort_staging_run.id).length
      if bins_staged == 0  && (active_children == 0 )
        statuses=['ACTIVE','EDITING','STAGED']
      else
        statuses=['ACTIVE','STAGED']
      end
    else   presort_staging_run.status ==  'STAGED'
    statuses=['STAGED']
    end
    return statuses
  end

  def calc_link_values(presort_staging_run)
    link_values={}
    link_values['bins_available']=PresortStagingRun.get_bins_available(presort_staging_run.season_id,presort_staging_run.rmt_variety_id,presort_staging_run.track_slms_indicator_id,presort_staging_run.farm_group_id,presort_staging_run.ripe_point_id)[0].length
    link_values['bins_available_locations']=PresortStagingRun.count_available_locations(presort_staging_run.season_id,presort_staging_run.rmt_variety_id,presort_staging_run.track_slms_indicator_id,presort_staging_run.farm_group_id,presort_staging_run.ripe_point_id).length
    link_values['bins_staged']=PresortStagingRun.bins_staged(presort_staging_run.id)[0].length
    return  link_values
  end
 
 def build_presort_staging_run_form(presort_staging_run,action,caption,is_edit = nil,is_create_retry = nil)

	session[:presort_staging_run_form]= Hash.new

  rmt_variety_codes=RmtVariety.find(:all).map{|p|[p.rmt_variety_code,p.id]}
  season_codes=Season.find(:all).map{|p|[p.season_code,p.id]}
  track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql("select  id,track_slms_indicator_code from track_slms_indicators where track_indicator_type_code='RMI'").map{|g|[g.track_slms_indicator_code,g.id]}
  farm_groups = FarmGroup.find_by_sql('select  id,farm_group_code from farm_groups').map{|g|[g.farm_group_code,g.id]}
  ripe_point_codes=RipePoint.find_by_sql("select  id,ripe_point_code from ripe_points").map{|p|[p.ripe_point_code,p.id]}
  combos_js_for_rmt_variety_code = gen_combos_clear_js_for_combos(["presort_staging_run_rmt_variety_id", "presort_staging_run_season_id"])
  rmt_variety_code_observer = {:updated_field_id => "season_id_cell",
                          :remote_method =>'staging_run_rmt_variety_code_changed',
                          :on_completed_js => combos_js_for_rmt_variety_code["presort_staging_run_rmt_variety_id"]
  }

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	 field_configs = []

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'rmt_variety_id?required',
                      :settings => {:list => rmt_variety_codes,:label_caption=>'rmt variety code'},:observer => rmt_variety_code_observer}

   field_configs << {:field_type => 'DropDownField',
                     :field_name => 'ripe_point_id?required',
                     :settings => {:list => ripe_point_codes,:label_caption=>'ripe point code'}}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'season_id?required',
                      :settings => {:list => season_codes,:label_caption=>'season code'}}

	 field_configs << {:field_type => 'DropDownField',
						:field_name => 'track_slms_indicator_id?required',
						:settings => {:list => track_slms_indicator_codes},:label_caption=>'track slms indicator code'}

    field_configs << {:field_type => 'DropDownField',
                      :field_name => 'farm_group_id?required',
                      :settings => {:list => farm_groups},:label_caption=>'farm group code'}

	build_form(presort_staging_run,field_configs,action,'presort_staging_run',caption,is_edit)

end
 
 
 def build_presort_staging_run_search_form(presort_staging_run,action,caption,is_flat_search = nil)
#	--------------------------------------------------------------------------------------------------
#	Define an observer for each index field
#	--------------------------------------------------------------------------------------------------
	session[:presort_staging_run_search_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo
	#Observers for search combos
#	----------------------------------------
#	 Define search fields to build form from
#	----------------------------------------
field_configs = []
	presort_run_codes = PresortStagingRun.find_by_sql('select distinct presort_run_code from presort_staging_runs').map{|g|[g.presort_run_code]}
	field_configs << {:field_type => 'DropDownField',
						:field_name => 'presort_run_code',
						:settings => {:list => presort_run_codes}}

	build_form(presort_staging_run,field_configs,action,'presort_staging_run',caption,false)

end

 def build_presort_staging_run_grid(data_set,can_edit,can_delete)
   require File.dirname(__FILE__) + "/../../../app/helpers/rmt_processing/presort_staging_run_plugin.rb"
	column_configs = []
#	----------------------
#	define action columns
#	----------------------
   if can_edit
     column_configs << {:field_type => 'action',:field_name => 'edit presort_staging_run',
                        :column_caption => 'Edit',
                        :settings =>
                            {:link_text => 'edit',
                             :target_action => 'edit_presort_staging_run',
                             :id_column => 'id'}}
   end

   if can_delete
     column_configs << {:field_type => 'action',:field_name => 'delete presort_staging_run',
                        :column_caption => 'Delete',
                        :settings =>
                            {:link_text => 'delete',
                             :target_action => 'delete_presort_staging_run',
                             :id_column => 'id',
                             :null_test => "['status'].upcase == 'ACTIVE' ||
                                              active_record['status'].upcase == 'CANCELLED' ||
                                              active_record['status'].upcase == 'STAGED' " }}
   end
	column_configs << {:field_type => 'text', :field_name => 'presort_run_code', :column_caption => 'Pre sort run code',:col_width=>180}
	column_configs << {:field_type => 'text', :field_name => 'status', :column_caption => 'Status'}
  column_configs << {:field_type => 'text', :field_name => 'rmt_variety_code'}
  column_configs << {:field_type => 'text', :field_name => 'ripe_point_code',:col_width=>50}
  column_configs << {:field_type => 'text', :field_name => 'track_slms_indicator_code'}
  column_configs << {:field_type => 'text', :field_name => 'farm_group_code'}
  column_configs << {:field_type => 'text', :field_name => 'season_code'}
	column_configs << {:field_type => 'text', :field_name => 'created_on', :data_type => 'date', :column_caption => 'Created on'}
	column_configs << {:field_type => 'text', :field_name => 'completed_on', :data_type => 'date', :column_caption => 'Completed on'}
	column_configs << {:field_type => 'text', :field_name => 'created_by', :column_caption => 'Created by'}
	column_configs << {:field_type => 'text', :field_name => 'updated_on', :data_type => 'date', :column_caption => 'Updated on'}
	column_configs << {:field_type => 'text', :field_name => 'updated_by', :column_caption => 'Updated by'}

   column_configs << {:field_type => 'link_window', :field_name => 'available_bins',:settings =>{:link_text=>'bins_available',:target_action => 'bins_available', :id_column => 'id'},:col_width=>57}
   column_configs << {:field_type => 'link_window', :field_name => 'bins_locations_available',:settings =>{:link_text=>'bins_locations_available',:target_action => 'bins_available_locations', :id_column => 'id'},:col_width=>57}
   column_configs << {:field_type => 'link_window', :field_name => 'bins_staged',:settings =>{:link_text=>'bins_staged',:target_action => 'show_bins_staged', :id_column => 'id'},:col_width=>57}

   column_configs << {:field_type => 'link_window', :field_name => 'active_child_runs',:settings =>{:controller => 'rmt_processing/presort_staging_run_child',:link_text=>'active_children',:target_action => 'parent_active_child_runs', :id_column => 'id'},:col_width=>57}
   column_configs << {:field_type => 'link_window', :field_name => 'editing_child_runs',:settings =>{:controller => 'rmt_processing/presort_staging_run_child',:link_text=>'editing_children',:target_action => 'parent_editing_child_runs', :id_column => 'id'},:col_width=>57}
   column_configs << {:field_type => 'link_window', :field_name => 'staged_child_runs',:settings =>{:controller => 'rmt_processing/presort_staging_run_child',:link_text=>'staged_children',:target_action => 'parent_staged_child_runs', :id_column => 'id'},:col_width=>57}
   #column_configs << {:field_type => 'link_window', :field_name => 'child_runs',:settings =>{:target_action => '', :id_column => 'id'},:col_width=>57}

   get_data_grid(data_set,column_configs,RmtProcessingPlugins::PresortStagingRunPlugin.new(self,request),true)

 end




end
