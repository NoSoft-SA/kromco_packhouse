module Production::RunsHelper
  def build_mini_production_run_view(run,action,ignore_pack_groups = nil)

  field_configs = Array.new
  require File.dirname(__FILE__) + "/../../../app/helpers/production/run_setup_plugin.rb"

  field_configs[field_configs.length()] = {:field_type => 'LabelField',
                                           :field_name => 'production_run_code'}


  field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                            :field_name => 'farm_code'}


  field_configs[field_configs.length()] =  {:field_type => 'LabelField',
                                            :field_name => 'puc_code'}

  pc_code =PcCode.find_by_sql("select pc_codes.pc_name from pc_codes join ripe_points on ripe_points.pc_code_id=pc_codes.id where ripe_points.id=#{run.ripe_point_id} ")[0].pc_name if   run.ripe_point_id
  treatment_code=Treatment.find_by_sql("select  id,treatment_code from treatments where id = #{run.treatment_id} ")[0].treatment_code  if run.treatment_id
  size_code=Size.find_by_sql("select id,size_code  from sizes where id = #{run.size_id}")[0].size_code  if run.size_id
  ripe_point_code=RipePoint.find_by_sql("select   id,ripe_point_code from ripe_points where id = #{run.ripe_point_id}")[0].ripe_point_code  if run.ripe_point_id
  track_indicator_code = TrackIndicator.find_by_sql("select  id,track_indicator_code from track_indicators where id = #{run.track_indicator_id} ")[0].track_indicator_code  if run.track_indicator_id
  product_class_code=ProductClass.find_by_sql("select distinct product_classes.id,product_classes.product_class_code from product_classes   where id = #{run.product_class_id}")[0].product_class_code if   run.product_class_id

  field_configs << {:field_type => 'LabelField',
                    :field_name => 'treatment_id',
                    :settings => {:static_value =>treatment_code,:label_caption=>'treatment code',:show_label=>true}}

  field_configs << {:field_type => 'LabelField',
                    :field_name => 'size_id',
                    :settings => {:static_value =>size_code,:label_caption=>'size code',:show_label=>true}}

  field_configs << {:field_type => 'LabelField',
                    :field_name => 'ripe_point_id',
                    :settings => {:static_value=>ripe_point_code,:label_caption=>'ripe point code',:show_label=>true}}

  field_configs << {:field_type => 'LabelField',
                    :field_name => 'pc_code_id',
                    :settings => {:static_value=> pc_code,:show_label=>true,:label_caption=> 'pc code'}}

  field_configs << {:field_type => 'LabelField',
                    :field_name => 'product_class_id',
                    :settings => {:static_value=> product_class_code,:label_caption=>'product class code',:show_label=>true}}

  field_configs << {:field_type => 'LabelField',
                    :field_name => 'track_indicator_id',
                    :settings => {:static_value=> track_indicator_code,:show_label=>true,:label_caption=> 'track indicator code'}}
  build_form(run,field_configs,action,'production_run','back',nil,nil,nil,nil,RunSetupPlugins::RunSetupFormPlugin.new)

end
  def build_base_current_and_next_production_run_view(run,action,ignore_pack_groups = nil)
    field_configs = Array.new
    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form1",
                                             :settings =>{
                                                 :controller => 'production/runs',
                                                 :target_action => 'view_mini_run',
                                                 :width => 1200,
                                                 :height => 250,
                                                 :id_value => run.id,
                                                 :no_scroll => true
                                             }
    }
    field_configs[field_configs.length()] = {:field_type => 'Screen',
                                             :field_name => "child_form2",
                                             :settings =>{
                                                 :controller => 'production/runs',
                                                 :target_action => 'view_mini_next_run',
                                                 :width => 1200,
                                                 :height => 250,
                                                 :id_value => run.id,
                                                 :no_scroll => true
                                             }
    }
    build_form(run,field_configs,'control_line','line_selection',"")
  end


 def build_select_line_form

    lines = Line.lines_for_packhouse(Facility.active_pack_house.facility_code)
    field_configs = Array.new
    field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'line',
						:settings => {:list => lines}}



	build_form(nil,field_configs,'control_line','line_selection','next')

 end

 def build_schedule_search_form

     js = "\n img = document.getElementById('img_schedule_season');"
     js += "\n if(img != null)img.style.display = 'none';"

    schedule_observer  = {:updated_field_id => "input_variety_cell",
					 :remote_method => 'schedule_search_season_changed',
					 :on_completed_js => js}

    seasons = Season.find(:all).map{|s|s.season_code}
    varieties = ["select a value from season combo"]

     field_configs = Array.new
     field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'season',
						:settings => {:list => seasons},
						:observer => schedule_observer}

	 field_configs[1] =  {:field_type => 'DropDownField',
						  :field_name => 'input_variety',
						  :settings => {:list => varieties}}

	build_form(nil,field_configs,'schedule_search_submit','schedule','submit')

 end


 #======================
 #MIXED PALLET CRITERIA
 #======================

 def build_get_pallet_number_form()

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	field_configs = Array.new

    field_configs[0] = {:field_type => 'TextField',
						:field_name => 'pallet_number'}



	build_form(nil,field_configs,'submit_mixed_pallet_id','pallet_number','submit')

end

 def build_get_carton_number_form(action = nil,is_correction =  nil)

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
   action = 'submit_ppecb_carton_num' if !action
	field_configs = Array.new

    field_configs[0] = {:field_type => 'TextField',
						:field_name => 'carton_number'}



	build_form(nil,field_configs,action,'carton_number','submit',nil,is_correction)

end

 def build_set_inspection_carton_form()

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
   action = 'submit_ppecb_carton_num' if !action
	field_configs = Array.new

    field_configs[0] = {:field_type => 'CheckBox',
						:field_name => 'is_inspection_carton'}



	build_form(nil,field_configs,'set_inspection_carton_submit_2','carton_number','submit')

 end


 def build_remove_inspection_carton_form()

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
   action = 'remove_inspection_carton_submit'
   field_configs = Array.new

   field_configs[0] = {:field_type => 'TextField',
                       :field_name => 'inspection_ctn_to_remove'}



   build_form(nil,field_configs,action,'carton_number','remove')

 end


def build_ppecb_inspection_form(ppecb_inspection)


    js = "\n img = document.getElementById('img_ppecb_inspection_passed');"
	js += "\n if(img != null)img.style.display = 'none';"

	 level_js = "\n img = document.getElementById('img_ppecb_inspection_inspection_level_code');"
	level_js += "\n if(img != null)img.style.display = 'none';"

    passed_observer  = {:updated_field_id => "reason_cell",
					 :remote_method => 'ppecb_inspection_passed_clicked',
					 :on_completed_js => js}

	level_observer  = {:updated_field_id => "passed_cell",
					 :remote_method => 'ppecb_inspection_level_changed',
					 :on_completed_js => level_js}


#	combo lists for table: inspection_types
	reasons = PpecbReason.find(:all).map{|p|[p.reason_description]}
	reasons.unshift("<empty>")
 # ppecb_inspection.reason = "<empty>" if ! ppecb_inspection.reason
 # puts "REASON: " + ppecb_inspection.reason
	ppecb_inspection.production_run_code = ppecb_inspection.carton.production_run_code
	inspection_levels = InspectionLevel.find(:all).map{|i|[i.inspection_level_code]}

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------

	field_configs = Array.new

	field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'inspection_level_code',
						:settings => {:list => inspection_levels},
						:observer => level_observer}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'production_run_code'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'carton_number'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'pallet_number'}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'inspection_point'}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'inspector_number'}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'inspection_report'}

	field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'sample_carton_label'}

	if !ppecb_inspection.passed
	  field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'reason',
						:settings => {:list => reasons}}
    else
      #ppecb_inspection.reason = "NO REASON REQUIRED"
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'reason',
						:settings => {:css_class => "no_format"}}
    end

    if ppecb_inspection.inspection_level_code && ppecb_inspection.inspection_level_code.upcase == "DISPENSATION"

      field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'dispensation_body'}

	 field_configs[field_configs.length()] = {:field_type => 'TextField',
						:field_name => 'dispensation_certificate_number'}

      field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'passed'}
   else
     field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'dispensation_body'}

	 field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'dispensation_certificate_number'}

	 field_configs[field_configs.length()] = {:field_type => 'CheckBox',
						:field_name => 'passed',
						:observer => passed_observer}

   end


	build_form(ppecb_inspection,field_configs,'set_ppecb_inspection','ppecb_inspection','save')

end



 def build_mixed_pallet_criteria_form(mixed_pallet_criteria)

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	field_configs = Array.new

    field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'pallet_number'}

	field_configs[1] = {:field_type => 'CheckBox',
						:field_name => 'target_market_code'}

	field_configs[2] = {:field_type => 'CheckBox',
						:field_name => 'inventory_code'}

	field_configs[3] = {:field_type => 'CheckBox',
						:field_name => 'mark_code'}

	field_configs[4] = {:field_type => 'CheckBox',
						:field_name => 'sell_by_code'}

	field_configs[5] = {:field_type => 'CheckBox',
						:field_name => 'farm_code'}

	field_configs[6] = {:field_type => 'CheckBox',
						:field_name => 'product_class_code'}

	field_configs[7] = {:field_type => 'CheckBox',
						:field_name => 'grade_code'}

	field_configs[8] = {:field_type => 'CheckBox',
						:field_name => 'units_per_carton'}



	build_form(mixed_pallet_criteria,field_configs,'set_mixed_pallet_criteria','mixed_pallet_criteria','set_mixed_pallet_criteria')

end


 #===============================
 #RUN PALLETIZING CRITERIA CODE
 #==============================
 def build_palletizing_criterium_form(run_palletizing_criterium,action = nil,caption = nil,is_edit = nil,is_create_retry = nil,is_view = nil)


    #------------------------------------------------------------------------------------
    #Build a fg code observer to filter the list of available carton setups by selected
    #fg code
    #------------------------------------------------------------------------------------
	#generate javascript for the on_complete ajax event for each combo for fk table: pack_material_products
	combos_js = gen_combos_clear_js_for_combos(["run_palletizing_criteria_setup_fg_product_code","run_palletizing_criteria_setup_carton_setup_code"])

	#Observers for combos representing the key fields of fkey table: carton_setup_id
	fg_code_observer  = {:updated_field_id => "carton_setup_code_cell",
					 :remote_method => 'run_palletizing_criteria_setup_fg_product_code_changed',
					 :on_completed_js => combos_js["run_palletizing_criteria_setup_fg_product_code"]}

	carton_setups = ["select a value from fg product code"]

	fg_product_codes = FgProduct.fg_codes_for_schedule(session[:current_closed_schedule].production_schedule_name)
    fg_product_codes.unshift "<empty>"


    if run_palletizing_criterium

      carton_setups = CartonSetup.find_all_by_production_schedule_id_and_fg_product_code(session[:current_closed_schedule].id,run_palletizing_criterium.fg_product_code).map {|c|[c.carton_setup_code]}
     # carton_setups.unshift("<empty>")
    end

    carton_setup_code_observer  = {:updated_field_id => "applet_container",
					 :remote_method => 'run_palletizing_criteria_setup_carton_setup_code_changed'}

	#:on_completed_js => combos_js["run_palletizing_criteria_setup_carton_setup_code"]

	session[:run_palletizing_criteria_setup] = Hash.new if !session[:run_palletizing_criteria_setup]
	session[:run_palletizing_criteria_setup][:carton_setup_observer]= carton_setup_code_observer

#	---------------------------------
#	 Define fields to build form from
#	---------------------------------
	field_configs = Array.new

     field_configs[0] = {:field_type => 'DropDownField',
						:field_name => 'fg_product_code',
						:settings => {:list => fg_product_codes},
						:observer => fg_code_observer}

	 field_configs[1] = {:field_type => 'DropDownField',
						:field_name => 'carton_setup_code',
						:settings => {:list => carton_setups},
						:observer => carton_setup_code_observer}

	field_configs[2] = {:field_type => 'CheckBox',
						:field_name => 'target_market_code'}

	field_configs[3] = {:field_type => 'CheckBox',
						:field_name => 'inventory_code'}

	field_configs[4] = {:field_type => 'CheckBox',
						:field_name => 'mark_code'}

	field_configs[5] = {:field_type => 'CheckBox',
						:field_name => 'sell_by_code'}

	field_configs[6] = {:field_type => 'CheckBox',
						:field_name => 'farm_code'}

	field_configs[7] = {:field_type => 'CheckBox',
						:field_name => 'units_per_carton'}

	build_form(run_palletizing_criterium,field_configs,action,'run_palletizing_criteria_setup',caption,is_edit)

end

def build_complete_run_form(run)

  field_configs = Array.new


  field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'production_run_stage'}

  field_configs[1] =  {:field_type => 'CheckBox',
						:field_name => 'complete_entire_run'}

  build_form(run,field_configs,"complete_run_submit",'production_run','complete')

end


 def build_shift_form

    field_configs = Array.new

    field_configs[0] = {:field_type => 'DateTimeField',
						:field_name => 'shift_start_time'}

    field_configs[1] = {:field_type => 'DateTimeField',
						:field_name => 'shift_end_time'}


	build_form(nil,field_configs,"execute_production_run_step3",'shift','save')


 end


 def build_new_run_form(action,caption,schedule,production_run = nil)
   rmt_product_type_code=schedule.rmt_setup.rmt_product.rmt_product_type_code
   commodity_code= schedule.rmt_setup.commodity_code
   variety_code=  schedule.rmt_setup.variety_code

  is_edit = !(production_run == nil)

   session[:production_run_form]= Hash.new
   lines = Line.lines_for_packhouse(Facility.active_pack_house.facility_code)

   combos_js_for_lines = gen_combos_clear_js_for_combos(["production_run_line_code","production_run_farm_code"])
   lines_observer  = {:updated_field_id => "farm_code_cell",
                     :remote_method => 'production_line_code_changed',
                     :on_completed_js => combos_js_for_lines["production_run_line_code"]}

   combos_js = gen_combos_clear_js_for_combos(["production_run_farm_code","production_run_parent_run_code"])

	#Observers for combos representing the key fields of fkey table: carton_setup_id
	farm_observer  = {:updated_field_id => "parent_run_code_cell",
					 :remote_method => 'production_run_farm_code_changed',
					 :on_completed_js => combos_js["production_run_farm_code"]}


	farm_codes = FarmGroup.find_by_farm_group_code(schedule.farm_group_code).farms.map{|f|f.farm_code}
	farm_codes.unshift "<empty>"

   farm_code = "like '%'"
   farm_code = "= '" + production_run.farm_code + "'" if production_run && production_run.farm_code
   current_run = ""
   current_run = production_run.production_run_code if production_run && production_run.production_run_code
   parent_runs = ProductionRun.find_by_sql("select production_run_code from production_runs where production_schedule_name = '#{schedule.production_schedule_name}' and production_runs.parent_run_code is null and production_runs.child_run_code is null and production_run_status <> 'completed' and farm_code #{farm_code} ").map{|f|f.production_run_code}
	 parent_runs.unshift "<empty>"
   parent_runs.delete_if{|r|r == current_run}

  if production_run && production_run.pc_code_id==nil
    if production_run && production_run.ripe_point_id
      production_run.pc_code_id =PcCode.find_by_sql("select pc_codes.pc_name,pc_codes.id from pc_codes join ripe_points on ripe_points.pc_code_id=pc_codes.id where ripe_points.id=#{production_run.ripe_point_id} ")[0].id
    end
  end
    if !production_run
      production_run = ProductionRun.new

    elsif !production_run.parent_run_code
   end

    production_run.production_schedule_name = schedule.production_schedule_name

   field_configs = Array.new
   field_configs[0] = {:field_type => 'LabelField',
						:field_name => 'production_schedule_name'}

  field_configs[1] = {:field_type => 'LabelField',
						:field_name => 'production_run_code'}

  if production_run.new_record?
   field_configs[2] =  {:field_type => 'DropDownField',
						:field_name => 'line_code?required',
						:settings => {:list => lines},:observer=> lines_observer}


  else
   field_configs[2] = {:field_type => 'LabelField',
						:field_name => 'line_code?required'}

  end

   if schedule.farm_pack == true

	  field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'farm_code?required',
						:settings => {:list => farm_codes},
            :observer => farm_observer
            }

   end
   product_class_codes=ProductClass.find_by_sql("select distinct product_classes.id,product_classes.product_class_code
                                   from product_classes
                                   join rmt_products on rmt_products.product_class_id=product_classes.id
                                   join varieties on rmt_products.variety_id=varieties.id
                                   join rmt_varieties on   varieties.rmt_variety_id=rmt_varieties.id
                                   where rmt_varieties.rmt_variety_code='#{variety_code}'
                                   order by product_class_code").map{|p|[p.product_class_code,p.id]}
   product_class_codes.unshift("<empty>") if !product_class_codes.empty?
   treatment_codes=Treatment.find_by_sql("select distinct treatments.id,treatments.treatment_code
                                   from treatments
                                   join rmt_products on rmt_products.treatment_id=treatments.id
                                   join varieties on rmt_products.variety_id=varieties.id
                                   join rmt_varieties on   varieties.rmt_variety_id=rmt_varieties.id
                                   where rmt_varieties.rmt_variety_code='#{variety_code}'
                                   order by treatment_code").map{|p|[p.treatment_code,p.id]}
   treatment_codes.unshift("<empty>") if !treatment_codes.empty?
   size_codes=Size.find_by_sql(" select  distinct sizes.id,sizes.size_code
                                   from sizes
                                   join rmt_products on rmt_products.size_id=sizes.id
                                   join varieties on rmt_products.variety_id=varieties.id
                                   join rmt_varieties on   varieties.rmt_variety_id=rmt_varieties.id
                                   where rmt_varieties.rmt_variety_code='#{variety_code}'
                                   order by size_code").map{|p|[p.size_code,p.id]}
   size_codes.unshift("<empty>") if !size_codes.empty?
   ripe_point_codes=RipePoint.find_by_sql("select distinct ripe_points.id,ripe_points.ripe_point_code
                                   from  ripe_points
                                   join rmt_products on rmt_products.ripe_point_id=ripe_points.id
                                   join varieties on rmt_products.variety_id=varieties.id
                                   join rmt_varieties on   varieties.rmt_variety_id=rmt_varieties.id
                                   where rmt_varieties.rmt_variety_code='#{variety_code}'
                                  order by ripe_points.ripe_point_code").map{|p|[p.ripe_point_code,p.id]}
   ripe_point_codes.unshift("<empty>") if !ripe_point_codes.empty?
   track_indicator_codes=TrackIndicator.find_by_sql("select  track_indicators.id,track_indicators.track_indicator_code
                                  from track_indicators
                                  join commodities on track_indicators.commodity_code=commodities.commodity_code
                                  join rmt_varieties on track_indicators.rmt_variety_id=rmt_varieties.id
                                  where  rmt_varieties.rmt_variety_code='#{variety_code}' and commodities.commodity_code='#{commodity_code}' order by track_indicators.track_indicator_code").map{|g|[g.track_indicator_code,g.id]}
   track_indicator_codes.unshift("<empty>") if !track_indicator_codes.empty?
   pc_codes=PcCode.find_by_sql("select pc_codes.pc_name,id from pc_codes").map{|p|[p.pc_name,p.id]}
   pc_codes.unshift("<empty>") if !pc_codes.empty?
   combos_js_for_ripe_point_code = gen_combos_clear_js_for_combos(["production_run_ripe_point_id", "production_run_pc_code_id"])

   ripe_point_code_observer = {:updated_field_id => "pc_code_id_cell",
                               :remote_method =>'production_run_ripe_point_code_changed',
                               :on_completed_js => combos_js_for_ripe_point_code["production_run_ripe_point_id"]
   }
   field_configs[field_configs.length()] =  {:field_type => 'DropDownField',
						:field_name => 'parent_run_code',
						:settings => {:list => parent_runs}}

   field_configs << {:field_type => 'LabelField',
                     :field_name => 'rmt_product_type_id?',
                     :settings => {:static_value=> rmt_product_type_code,:label_caption=>'rmt product type code',:show_label=>true}}

   field_configs << {:field_type => 'LabelField',
                     :field_name => 'commodity_id',
                     :settings => {:static_value => commodity_code,:label_caption=>'commodity code',:show_label=>true}}

   field_configs << {:field_type => 'LabelField',
                     :field_name => 'variety_id',
                     :settings => {:static_value =>variety_code,:label_caption=>'rmt variety code',:show_label=>true}}

   if production_run  && production_run.production_run_status
     if production_run.production_run_status.upcase == "CONFIGURING"

       field_configs << {:field_type => 'DropDownField',
                         :field_name => 'treatment_id',
                         :settings => {:list =>treatment_codes,:label_caption=>'treatment code'}}

       field_configs << {:field_type => 'DropDownField',
                         :field_name => 'size_id',
                         :settings => {:list =>size_codes,:label_caption=>'size code'}}

       field_configs << {:field_type => 'DropDownField',
                         :field_name => 'ripe_point_id',
                         :settings => {:list =>ripe_point_codes,:label_caption=>'ripe point code'},:observer => ripe_point_code_observer}
       #if pc_code
       #
       #  field_configs << {:field_type => 'LabelField',
       #                    :field_name => 'pc_code_id',
       #                    :settings => {:label_caption=>'pc code',:static_value=> pc_code,:show_label=>true}}
       #else
       #
       #  field_configs << {:field_type => 'LabelField',
       #                    :field_name => 'pc_code_id',
       #                    :settings => {:label_caption=>'pc code'}}
       #end


       field_configs << {:field_type => 'DropDownField',
                         :field_name => 'pc_code_id',
                         :settings => {:list => pc_codes},:label_caption=>'pc_code'}

       field_configs << {:field_type => 'DropDownField',
                         :field_name => 'product_class_id',
                         :settings => {:list => product_class_codes},:label_caption=>'product class code'}

       field_configs << {:field_type => 'DropDownField',
                         :field_name => 'track_indicator_id',
                         :settings => {:list => track_indicator_codes},:label_caption=>'track indicator code'}
       else
       size_code = nil
       ripe_point_code = nil
       track_indicator_code = nil
       treatment_code=Treatment.find_by_sql("select  id,treatment_code from treatments where id = #{production_run.treatment_id} ")[0].treatment_code  if production_run.treatment_id
       size_code=Size.find_by_sql("select id,size_code  from sizes where id = #{production_run.size_id}")[0].size_code  if production_run.size_id
       ripe_point_code=RipePoint.find_by_sql("select   id,ripe_point_code from ripe_points where id = #{production_run.ripe_point_id}")[0].ripe_point_code  if production_run.ripe_point_id
       track_indicator_code = TrackIndicator.find_by_sql("select  id,track_indicator_code from track_indicators where id = #{production_run.track_indicator_id} ")[0].track_indicator_code  if production_run.track_indicator_id
       product_class_code=ProductClass.find_by_sql("select distinct product_classes.id,product_classes.product_class_code from product_classes   where id = #{production_run.product_class_id}")[0].product_class_code if   production_run.product_class_id
       pc_code =PcCode.find_by_sql("select pc_codes.pc_name from pc_codes join ripe_points on ripe_points.pc_code_id=pc_codes.id where ripe_points.id=#{production_run.ripe_point_id} ")[0].pc_name

       field_configs << {:field_type => 'LabelField',
                         :field_name => 'treatment_id',
                         :settings => {:static_value =>treatment_code,:label_caption=>'treatment code',:show_label=>true}}

       field_configs << {:field_type => 'LabelField',
                         :field_name => 'size_id',
                         :settings => {:static_value =>size_code,:label_caption=>'size code',:show_label=>true}}

       field_configs << {:field_type => 'LabelField',
                         :field_name => 'ripe_point_id',
                         :settings => {:static_value=>ripe_point_code,:label_caption=>'ripe point code',:show_label=>true}}

       field_configs << {:field_type => 'LabelField',
                         :field_name => 'pc_code_id',
                         :settings => {:static_value=> pc_code,:show_label=>true,:label_caption=> 'pc code'}}

       field_configs << {:field_type => 'LabelField',
                         :field_name => 'product_class_id',
                         :settings => {:static_value=> product_class_code,:label_caption=>'product class code',:show_label=>true}}

       field_configs << {:field_type => 'LabelField',
                         :field_name => 'track_indicator_id',
                         :settings => {:static_value=> track_indicator_code,:show_label=>true,:label_caption=> 'track indicator code'}}


     end
   else
     field_configs << {:field_type => 'DropDownField',
                       :field_name => 'treatment_id',
                       :settings => {:list =>treatment_codes,:label_caption=>'treatment code'}}

     field_configs << {:field_type => 'DropDownField',
                       :field_name => 'size_id',
                       :settings => {:list =>size_codes,:label_caption=>'size code'}}

     field_configs << {:field_type => 'DropDownField',
                       :field_name => 'ripe_point_id',
                       :settings => {:list =>ripe_point_codes,:label_caption=>'ripe point code'},:observer => ripe_point_code_observer}
     #if pc_code
     #
     #  field_configs << {:field_type => 'LabelField',
     #                    :field_name => 'pc_code_id',
     #                    :settings => {:label_caption=>'pc code',:static_value=> pc_code,:show_label=>true}}
     #else
     #
     #  field_configs << {:field_type => 'LabelField',
     #                    :field_name => 'pc_code_id',
     #                    :settings => {:label_caption=>'pc code'}}
     #end

     field_configs << {:field_type => 'DropDownField',
                       :field_name => 'pc_code_id',
                       :settings => {:list => pc_codes},:label_caption=>'pc_code'}

     field_configs << {:field_type => 'DropDownField',
                       :field_name => 'product_class_id',
                       :settings => {:list => product_class_codes},:label_caption=>'product class code'}

     field_configs << {:field_type => 'DropDownField',
                       :field_name => 'track_indicator_id',
                       :settings => {:list => track_indicator_codes},:label_caption=>'track indicator code'}


   end



  @production_run = production_run if ! @production_run
  build_form(production_run,field_configs,action,'production_run',caption)

 end



 def build_new_template_form(action,caption,template_names_list,active_template = nil)



    on_complete_js = "\n img = document.getElementById('img_templ_template_names');"
	on_complete_js += "\n if(img != null)img.style.display = 'none';"

	commodity_js = "\n img = document.getElementById('img_templ_commodity_code');"
	commodity_js += "\n if(img != null)img.style.display = 'none';"

    template_names_observer  = {:updated_field_id => "ajax_distributor_cell",
					 :remote_method => 'template_name_combo_changed',
					 :on_completed_js => on_complete_js}


	commodity_code_observer  = {:updated_field_id => "rmt_variety_code_cell",
					 :remote_method => 'template_commodity_code_changed',
					 :on_completed_js => commodity_js}

	session[:new_template_form] = Hash.new
	session[:new_template_form][:on_complete_js_for_commodity]= commodity_js

	commodity_codes = Commodity.find(:all).map{|c|[c.commodity_code]}
	variety_codes = ["select a value from commodity code"]

	farm_group_codes = FarmGroup.find_by_sql('select distinct farm_group_code from farm_groups').map{|g|[g.farm_group_code]}

    @templ = SizerTemplate.new
    if active_template

      @templ.commodity_code = active_template.commodity_code
      @templ.rmt_variety_code = active_template.rmt_variety_code
      @templ.farm_group_code = active_template.farm_group_code
      @templ.template_names = active_template.template_name
      @templ.template_name = active_template.template_name

      variety_codes = RmtVariety.find_by_sql("Select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{@templ.commodity_code}'").map{|g|[g.rmt_variety_code]}
    end

    size_codes = Size.find_by_sql("Select distinct size_code from sizes").map{|s|s.size_code}

   field_configs = Array.new


   field_configs[0] =  {:field_type => 'DropDownField',
						:field_name => 'template_names',
						:settings => {:list => template_names_list},
						:observer => template_names_observer}


   field_configs[1] =  {:field_type => 'DropDownField',
						:field_name => 'fruit_size',
						:settings => {:list => size_codes}}

   field_configs[2] = {:field_type => 'TextField',
						:field_name => 'color_sorting'}

   field_configs[3] = {:field_type => 'TextField',
						:field_name => 'template_name'}


  field_configs[4] =  {:field_type => 'DropDownField',
						:field_name => 'commodity_code',
						:settings => {:list => commodity_codes},
						:observer => commodity_code_observer}

	field_configs[5] =  {:field_type => 'DropDownField',
						:field_name => 'rmt_variety_code',
						:settings => {:list => variety_codes}}


	field_configs[6] =  {:field_type => 'DropDownField',
						:field_name => 'farm_group_code',
						:settings => {:list => farm_group_codes}}

   field_configs[7] = {:field_type => 'HiddenField',
						:field_name => 'ajax_distributor',
						:non_db_field => true}

  build_form(@templ,field_configs,action,'templ',caption)

 end

 def build_production_run_form(run,submit_action = nil)

  action = 'current_schedule_runs'
  action = submit_action if submit_action

   field_configs = Array.new
   require File.dirname(__FILE__) + "/../../../app/helpers/production/run_setup_plugin.rb"

   field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'production_schedule_name'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'production_run_number'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'production_run_code'}

   field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'parent_run_code',:settings => {:css_class => "parent_run"}} if run.parent_run_code

   field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'child_run_code',:settings => {:css_class => "child_run"}} if run.child_run_code

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'day_line_batch_code'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'line_code'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'shift_code'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'start_date_time'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'end_date_time'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'farm_code'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'account_code'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'puc_code'}

		field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'batch_code'}
  #-------24012014---------------------
  pc_code =PcCode.find_by_sql("select pc_codes.pc_name from pc_codes join ripe_points on ripe_points.pc_code_id=pc_codes.id where ripe_points.id=#{run.ripe_point_id} ")[0].pc_name if run.ripe_point_id
  treatment_code=Treatment.find_by_sql("select  id,treatment_code from treatments where id = #{run.treatment_id} ")[0].treatment_code  if run.treatment_id
  size_code=Size.find_by_sql("select id,size_code  from sizes where id = #{run.size_id}")[0].size_code  if run.size_id
  ripe_point_code=RipePoint.find_by_sql("select   id,ripe_point_code from ripe_points where id = #{run.ripe_point_id}")[0].ripe_point_code  if run.ripe_point_id
  track_indicator_code = TrackIndicator.find_by_sql("select  id,track_indicator_code from track_indicators where id = #{run.track_indicator_id} ")[0].track_indicator_code  if run.track_indicator_id
  product_class_code=ProductClass.find_by_sql("select distinct product_classes.id,product_classes.product_class_code from product_classes   where id = #{run.product_class_id}")[0].product_class_code if   run.product_class_id

  field_configs << {:field_type => 'LabelField',
                    :field_name => 'treatment_id',
                    :settings => {:static_value =>treatment_code,:label_caption=>'treatment code',:show_label=>true}}

  field_configs << {:field_type => 'LabelField',
                    :field_name => 'size_id',
                    :settings => {:static_value =>size_code,:label_caption=>'size code',:show_label=>true}}

  field_configs << {:field_type => 'LabelField',
                    :field_name => 'ripe_point_id',
                    :settings => {:static_value=>ripe_point_code,:label_caption=>'ripe point code',:show_label=>true}}

  field_configs << {:field_type => 'LabelField',
                    :field_name => 'pc_code_id',
                    :settings => {:static_value=> pc_code,:show_label=>true,:label_caption=> 'pc code'}}

  field_configs << {:field_type => 'LabelField',
                    :field_name => 'product_class_id',
                    :settings => {:static_value=> product_class_code,:label_caption=>'product class code',:show_label=>true}}

  field_configs << {:field_type => 'LabelField',
                    :field_name => 'track_indicator_id',
                    :settings => {:static_value=> track_indicator_code,:show_label=>true,:label_caption=> 'track indicator code'}}

  #--------------------------------------
  	if run && run.production_run_status == "configuring"
  	 field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'edit_run_details',
			:settings =>
				 {:link_text => 'edit',
				:target_action => 'edit_run_details',
				:id_column => 'id'}}
	end


	if run && run.production_run_status && 	(run.production_run_status.index("configuring")||run.production_run_status == "restored")
	 field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'schedule product update',
			:settings =>
				 {:image => 'refresh',
				:target_action => 'refresh_run',
				:id_column => 'id'},:html_options => {:prompt => "Are you sure you want to refresh the production run? (All pack groups and their drop-to-counts-allocation will be rebuilt)"}}
	end


	 field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'pack_groups',
			:settings =>
				 {:link_text => 'pack groups: allocate drops to counts',
				:target_action => 'list_pack_groups',
				:id_column => 'id'}}


	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'auto-set products',
			:settings =>
				 {:image => 'auto_complete_fg_allocation',
				:target_action => 'auto_complete_fg_allocation',
				:id_column => 'id'}}

	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'all pack_stations',
			:settings =>
				 {:link_text => 'allocate fg products',
				:target_action => 'allocate_fg_products',
				:id_column => 'id'}}


	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'binfill_stations: front',
			:settings =>
				 {:link_text => 'allocate rmt products',
				:target_action => 'allocate_rmt_products_side_a',
				:id_column => 'id'}}

	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'binfill_stations: back',
			:settings =>
				 {:link_text => 'allocate rmt products',
				:target_action => 'allocate_rmt_products_side_b',
				:id_column => 'id'}}

	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'binfill_sort_stations',
			:settings =>
				 {:link_text => 'allocate rmt products',
				:target_action => 'allocate_rmt_products_sorts',
				:id_column => 'id'}}

	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'bintip_criteria',
			:settings =>
				 {:link_text => 'edit bintip criteria',
				:target_action => 'edit_bintip_criteria',
				:id_column => 'id'}}


	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'pack_materials',
			:settings =>
				 {:link_text => 'edit pack materials',
				:target_action => 'edit_pack_materials',
				:id_column => 'id'}}

	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'palletizing_criteria',
			:settings =>
				 {:link_text => 'edit palletizing criteria',
				:target_action => 'palletizing_criteria_setup',
				:id_column => 'id'}}

	#-----------------------------------------------------------------------
	#Add apply sizer template link and save_to_template link in single field
	#-----------------------------------------------------------------------

	load_template_image = image_tag('loading.gif',:id => 'loading_template', :align => 'absmiddle', :border=> 0, :style=>'visibility: hidden' )
	load_template_save_image = image_tag('loading.gif',:id => 'loading_template_save', :align => 'absmiddle', :border=> 0, :style=>'visibility: hidden')

	onclick = "show_action_image(this);"
	template_link = link_to(image_tag("list_sizer_templates.png",:border => 0),{ :action => "list_sizer_templates" })
	save_to_template_link = link_to(image_tag("save_to_template.png",:border => 0,:alight => "left"),{ :action => "save_to_template" })
	new_template_link = link_to(image_tag("new_template.png",:border => 0,:alight => "left"),{ :action => "new_template" })
	filter_link = link_to(image_tag("set_template_filter_options.png",:border => 0,:alight => "left"),{ :action => "set_template_filter_options" })

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => "templates", :settings =>
						 {:static_value => template_link + "&nbsp;&nbsp;" + save_to_template_link + "&nbsp;&nbsp;" + new_template_link + "&nbsp;&nbsp;",:is_separator => false,
						 :css_class => 'no_format'}}


	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'applied_sizer_template'}

	#is_edit,nil,nil,nil,CartonSetupPlugins::CartonSetupFormPlugin.new

	build_form(run,field_configs,action,'production_run','back',nil,nil,nil,nil,RunSetupPlugins::RunSetupFormPlugin.new)

 end


 def build_production_run_view(run,action,ignore_pack_groups = nil)

   field_configs = Array.new
   require File.dirname(__FILE__) + "/../../../app/helpers/production/run_setup_plugin.rb"

   field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'production_schedule_name'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'production_run_number'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'production_run_code'}

    field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'parent_run_code'}

     field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'child_run_code'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'day_line_batch_code'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'line_code'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'shift_code'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'start_date_time'}

	field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'end_date_time'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'farm_code'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'account_code'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'puc_code'}

   pc_code =PcCode.find_by_sql("select pc_codes.pc_name from pc_codes join ripe_points on ripe_points.pc_code_id=pc_codes.id where ripe_points.id=#{run.ripe_point_id} ")[0].pc_name if   run.ripe_point_id
   treatment_code=Treatment.find_by_sql("select  id,treatment_code from treatments where id = #{run.treatment_id} ")[0].treatment_code  if run.treatment_id
   size_code=Size.find_by_sql("select id,size_code  from sizes where id = #{run.size_id}")[0].size_code  if run.size_id
   ripe_point_code=RipePoint.find_by_sql("select   id,ripe_point_code from ripe_points where id = #{run.ripe_point_id}")[0].ripe_point_code  if run.ripe_point_id
   track_indicator_code = TrackIndicator.find_by_sql("select  id,track_indicator_code from track_indicators where id = #{run.track_indicator_id} ")[0].track_indicator_code  if run.track_indicator_id
   product_class_code=ProductClass.find_by_sql("select distinct product_classes.id,product_classes.product_class_code from product_classes   where id = #{run.product_class_id}")[0].product_class_code if   run.product_class_id

   field_configs << {:field_type => 'LabelField',
                     :field_name => 'treatment_id',
                     :settings => {:static_value =>treatment_code,:label_caption=>'treatment code',:show_label=>true}}

   field_configs << {:field_type => 'LabelField',
                     :field_name => 'size_id',
                     :settings => {:static_value =>size_code,:label_caption=>'size code',:show_label=>true}}

   field_configs << {:field_type => 'LabelField',
                     :field_name => 'ripe_point_id',
                     :settings => {:static_value=>ripe_point_code,:label_caption=>'ripe point code',:show_label=>true}}

   field_configs << {:field_type => 'LabelField',
                     :field_name => 'pc_code_id',
                     :settings => {:static_value=> pc_code,:show_label=>true,:label_caption=> 'pc code'}}

   field_configs << {:field_type => 'LabelField',
                     :field_name => 'product_class_id',
                     :settings => {:static_value=> product_class_code,:label_caption=>'product class code',:show_label=>true}}

   field_configs << {:field_type => 'LabelField',
                     :field_name => 'track_indicator_id',
                     :settings => {:static_value=> track_indicator_code,:show_label=>true,:label_caption=> 'track indicator code'}}


	#:::::::::::: LUKS CHANGE - eliminates the pack_groups link from the form ::::
    if !ignore_pack_groups
	 field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'pack_groups',
			:settings =>
				 {:link_text => 'view',
				:target_action => 'view_pack_groups',
				:id_column => 'id'}}
    end


	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'pack_stations:side A',
			:settings =>
				 {:link_text => 'view allocation',
				:target_action => 'view_fg_products_side_a_allocation',
				:id_column => 'id'}}

	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'pack_stations:side B',
			:settings =>
				 {:link_text => 'view allocation',
				:target_action => 'view_fg_products_side_b_allocation',
				:id_column => 'id'}}

	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'binfill_stations:side A',
			:settings =>
				 {:link_text => 'view allocation',
				:target_action => 'view_rmt_products_side_a_allocation',
				:id_column => 'id'}}

	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'binfill_stations:side B',
			:settings =>
				 {:link_text => 'view allocation',
				:target_action => 'view_rmt_products_side_b_allocation',
				:id_column => 'id'}}

	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'binfill_sort_stations',
			:settings =>
				 {:link_text => 'view allocation',
				:target_action => 'view_rmt_products_sorts_allocation',
				:id_column => 'id'}}

	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'bintip_criteria',
			:settings =>
				 {:link_text => 'view bintip criteria',
				:target_action => 'view_bintip_criteria',
				:id_column => 'id'}}


	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'pack_materials',
			:settings =>
				 {:link_text => 'view additional usage',
				:target_action => 'view_pack_materials',
				:id_column => 'id'}}

	field_configs[field_configs.length()] = {:field_type => 'LinkField',:field_name => 'palletizing_criteria',
			:settings =>
				 {:link_text => 'view palletizing criteria',
				:target_action => 'view_palletizing_criteria_setup',
				:id_column => 'id'}}


	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'applied_sizer_template'}

	#is_edit,nil,nil,nil,CartonSetupPlugins::CartonSetupFormPlugin.new

	build_form(run,field_configs,action,'production_run','back',nil,nil,nil,nil,RunSetupPlugins::RunSetupFormPlugin.new)

 end

 #================
 #PACK GROUPS CODE
 #================

 def build_pack_groups_grid(data_set,can_edit)

	column_configs = Array.new
	 #require File.dirname(__FILE__) + "/../../../app/helpers/production/run_setup_plugin.rb"

	column_configs[0] = {:field_type => 'text',:field_name => 'pack_group_number',:column_caption => 'group_num',:col_width => 85}
	column_configs[1] = {:field_type => 'text',:field_name => 'production_run_number',:column_caption => 'run_num',:col_width => 85}
	column_configs[2] = {:field_type => 'text',:field_name => 'production_schedule_name',:col_width => 233}
	column_configs[3] = {:field_type => 'text',:field_name => 'commodity_code',:col_width => 65}
	column_configs[4] = {:field_type => 'text',:field_name => 'marketing_variety_code',:col_width => 85,:column_caption => 'variety'}
	column_configs[5] = {:field_type => 'text',:field_name => 'color_sort_percentage',:col_width => 60,:column_caption => '% color'}
	column_configs[6] = {:field_type => 'text',:field_name => 'grade_code',:col_width => 65}

#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit drops', :col_width => 112,
			:settings =>
				 {:link_text => 'set_drops_to_counts',
				:target_action => 'set_drops_to_counts',
				:id_column => 'id'}}

	else
	 column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit drops', :col_width => 112,
			:settings =>
				 {:link_text => 'view drops allocation',
				:target_action => 'view_drops_to_counts',
				:id_column => 'id'}}

	end

 return get_data_grid(data_set,column_configs,MesScada::GridPlugins::Production::PackGroupGridPlugin.new)

end

#====================
#PACK MATERIALS CODE
#====================
def build_pack_materials_grid(data_set,can_create_run)



    column_configs = Array.new

	column_configs[0] = {:field_type => 'text',:field_name => 'retail_item_pack_material_code'}
	column_configs[1] = {:field_type => 'text',:field_name => 'retail_unit_pack_material_code'}
	column_configs[2] = {:field_type => 'text',:field_name => 'trade_unit_pack_material_code'}
	column_configs[3] = {:field_type => 'text',:field_name => 'pallet_pack_material_code'}
	column_configs[4] = {:field_type => 'text',:field_name => 'fg_product_code'}
	column_configs[5] = {:field_type => 'text',:field_name => 'carton_setup_code'}
	column_configs[6] = {:field_type => 'text',:field_name => 'created_at'}



 return get_data_grid(data_set,column_configs)
end


def build_fg_run_pack_materials_form(production_run_pack_material,action,caption)


    #------------------------------------------------------------------------------------
    #Build a fg code observer to filter the list of available carton setups by selected
    #fg code
    #The key for a carton setup is: color%,grade,size cnt,org,seq no.
    #------------------------------------------------------------------------------------
    session[:run_pack_material_form]= Hash.new
	#generate javascript for the on_complete ajax event for each combo for fk table: pack_material_products
	combos_js = gen_combos_clear_js_for_combos(["production_run_pack_material_fg_product_code","production_run_pack_material_carton_setup_code"])

	#Observers for combos representing the key fields of fkey table: carton_setup_id
	fg_code_observer  = {:updated_field_id => "carton_setup_code_cell",
					 :remote_method => 'production_run_pack_material_fg_product_code_changed',
					 :on_completed_js => combos_js["production_run_pack_material_fg_product_code"]}

	session[:run_pack_material_form][:fg_code_observer] = fg_code_observer

	 run = production_run_pack_material.production_run
	 production_run_pack_material.production_schedule_name = run.production_schedule_name
     production_run_pack_material.line_code = run.line_code
     production_run_pack_material.production_run_number = run.production_run_number

	carton_setups = ["select a value from fg product code"]

	fg_product_codes = FgProduct.fg_codes_for_schedule(production_run_pack_material.production_run.production_schedule_name)
	fg_product_codes.unshift "<empty>"

	pack_materials = Product.find_all_by_product_type_code("PACK_MATERIAL").map{|p|p.product_code}
    pack_materials.unshift "<empty>"

    if !production_run_pack_material.retail_item_pack_material_code
    #  production_run_pack_material.retail_item_pack_material_code = "<empty>"
    end

    if !production_run_pack_material.retail_unit_pack_material_code
    #  production_run_pack_material.retail_unit_pack_material_code = "<empty>"
    end

    if !production_run_pack_material.trade_unit_pack_material_code
    #  production_run_pack_material.trade_unit_pack_material_code = "<empty>"
    end

    if !production_run_pack_material.pallet_pack_material_code
    #  production_run_pack_material.pallet_pack_material_code = "<empty>"
    end


    field_configs = Array.new

	field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'production_schedule_name'}

	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'production_run_number'}

	field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'line_code'}

	field_configs[3] =  {:field_type => 'LabelField',
						:field_name => 'commodity_code'}

	field_configs[4] =  {:field_type => 'LabelField',
						:field_name => 'marketing_variety_code'}

    field_configs[5] = {:field_type => 'DropDownField',
						:field_name => 'fg_product_code',
						:settings => {:list => fg_product_codes},
						:observer => fg_code_observer}

	 field_configs[6] = {:field_type => 'DropDownField',
						:field_name => 'carton_setup_code',
						:settings => {:list => carton_setups}}

    field_configs[7] = {:field_type => 'DropDownField',
						:field_name => 'retail_item_pack_material_code',
						:settings => {:list => pack_materials}}

	field_configs[8] = {:field_type => 'DropDownField',
						:field_name => 'retail_unit_pack_material_code',
						:settings => {:list => pack_materials}}

	field_configs[9] = {:field_type => 'DropDownField',
						:field_name => 'trade_unit_pack_material_code',
						:settings => {:list => pack_materials}}

	field_configs[10] = {:field_type => 'DropDownField',
						:field_name => 'pallet_pack_material_code',
						:settings => {:list => pack_materials}}


    build_form(production_run_pack_material,field_configs,action,'production_run_pack_material',caption)

end


def build_pack_group_outlet_form(pack_group_outlet,action,caption,is_edit = nil,is_create_retry = nil)

      require File.dirname(__FILE__) + "/../../../app/helpers/production/run_setup_plugin.rb"

     #data needed to show pack group context to user
     pack_group_outlet.production_schedule_name = pack_group_outlet.pack_group.production_schedule_name
     pack_group_outlet.commodity_code = pack_group_outlet.pack_group.commodity_code
     pack_group_outlet.marketing_variety_code = pack_group_outlet.pack_group.marketing_variety_code
     pack_group_outlet.line_code = pack_group_outlet.pack_group.production_run.line_code
     pack_group_outlet.color_sort_percentage = pack_group_outlet.pack_group.color_sort_percentage
     pack_group_outlet.grade_code = pack_group_outlet.pack_group.grade_code
     pack_group_outlet.production_run_number = pack_group_outlet.pack_group.production_run_number



     line = pack_group_outlet.pack_group.production_run.line

      drops = line.line_config.drops.map{|d|d.drop_code.to_s}


    drops.unshift "<empty>"
    if !pack_group_outlet.outlet1
    #  pack_group_outlet.outlet1 = "<empty>"
    end
    if !pack_group_outlet.outlet2
    #  pack_group_outlet.outlet2 = "<empty>"
    end
    if !pack_group_outlet.outlet3
    #  pack_group_outlet.outlet3 = "<empty>"
    end
    if !pack_group_outlet.outlet4
    #  pack_group_outlet.outlet4 = "<empty>"
    end
    if !pack_group_outlet.outlet5
     # pack_group_outlet.outlet5 = "<empty>"
    end
    if !pack_group_outlet.outlet6
     # pack_group_outlet.outlet6 = "<empty>"
    end
    if !pack_group_outlet.outlet7
     # pack_group_outlet.outlet7 = "<empty>"
    end
    if !pack_group_outlet.outlet8
     # pack_group_outlet.outlet8 = "<empty>"
    end
    if !pack_group_outlet.outlet9
     # pack_group_outlet.outlet9 = "<empty>"
    end
    if !pack_group_outlet.outlet10
     # pack_group_outlet.outlet10 = "<empty>"
    end
    if !pack_group_outlet.outlet11
    #  pack_group_outlet.outlet11 = "<empty>"
    end
    if !pack_group_outlet.outlet12
     # pack_group_outlet.outlet12 = "<empty>"
    end

	field_configs = Array.new



	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'production_run_number'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'line_code'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'commodity_code'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'marketing_variety_code'}

	field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'color_sort_percentage'}

    field_configs[field_configs.length()] =  {:field_type => 'LabelField',
						:field_name => 'grade_code'}

    if pack_group_outlet.size_code
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'size_code'}
    else
      field_configs[field_configs.length()] = {:field_type => 'LabelField',
						:field_name => 'standard_size_count_value'}
    end



	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet1',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet2',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet3',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet4',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet5',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet6',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet7',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet8',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet9',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet10',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet11',
						:settings => {:list => drops,:is_clearable => true}}

	field_configs[field_configs.length()] = {:field_type => 'DropDownField',
						:field_name => 'outlet12',
						:settings => {:list => drops,:is_clearable => true}}

    set_form_layout "4",nil,7

	build_form(pack_group_outlet,field_configs,action,'pack_group_outlet',caption,is_edit,nil,nil,nil,RunSetupPlugins::PackGroupOutletFormPlugin.new)

end



 def build_drops_to_counts_grid(data_set,can_edit)

   #each record is an instance of PackGroupOutlet

	column_configs = Array.new
	 #require File.dirname(__FILE__) + "/../../../app/helpers/production/run_setup_plugin.rb"

	#	----------------------
    #	define action columns
    #	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit',:col_width => 47,
			:settings =>
				 {:link_text => 'edit',
				:target_action => 'edit_drops_to_counts',
				:id_column => 'id',
				:null_test => "outlet1 == 'n.a' "}}

	end

	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'standard_size_count_value',:col_width => 50,:column_caption => 'std count'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'size_code',:col_width => 60}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet1',:col_width => 60,:column_caption => 'drop_1'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet2',:col_width => 60,:column_caption => 'drop_2'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet3',:col_width => 60,:column_caption => 'drop_3'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet4',:col_width => 60,:column_caption => 'drop_4'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet5',:col_width => 60,:column_caption => 'drop_5'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet6',:col_width => 60,:column_caption => 'drop_6'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet7',:col_width => 60,:column_caption => 'drop_7'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet8',:col_width => 60,:column_caption => 'drop_8'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet9',:col_width => 60,:column_caption => 'drop_9'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet10',:col_width => 60,:column_caption => 'drop_10'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet11',:col_width => 60,:column_caption => 'drop_11'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'outlet12',:col_width => 60,:column_caption => 'drop_12'}


 return get_data_grid(data_set,column_configs,MesScada::GridPlugins::Production::CountsDropsGridPlugin.new)

end

def build_production_run_grid(data_set,can_edit,is_active_runs_grid = nil,run_type = nil,editing_runs=nil)

	column_configs = Array.new
	 #require File.dirname(__FILE__) + "/../../../app/helpers/production/run_setup_plugin.rb"


	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'production_run_code',:col_width => 162}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'rank',:editor => :text,:col_width =>50}  if editing_runs
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'puc_code',:col_width => 70}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'farm_code',:col_width => 60}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'pc_code'}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'treatment_code'}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'size_code',}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'ripe_point_code'}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'product_class_code'}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'track_indicator_code'}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'parent_run_code',:column_caption => "parent",:col_width => 162}
  column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'child_run_code',:column_caption => "child",:col_width => 162}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'account_code',:col_width => 70}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'line_code',:col_width =>80}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'production_run_status',:col_width => 83,:column_caption => 'status'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'production_run_stage',:col_width => 83,:column_caption => 'stage'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'day_line_batch_code',:batch => 50}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'batch_code',:col_width => 90}
  column_configs[column_configs.length()] = {:field_type => 'text', :field_name => 'id', :hide => true}

#	----------------------
#	define action columns
#	----------------------

   if can_edit && can_edit == true||@clone_allowed
      if !run_type ||(run_type && run_type != 'completed_run')
		 column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'clone run',:col_width => 50,
			:settings =>
				 {:image => 'clone',
				:target_action => 'clone_production_run',
				:id_column => 'id'},:html_options => {:prompt => "Are you sure you want to clone the production run?"}}
     end
   end
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'edit run',:col_width => 50,
			:settings =>
				 {:image => 'edit',
				:target_action => 'edit_production_run',
				:id_column => 'id'}}

		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'delete run', :col_width => 50,
			:settings =>
				 {:image => 'delete',
				:target_action => 'delete_production_run',
				:id_column => 'id'},:html_options => {:prompt => "This delete will cascade to all data associated with the run. Are you sure you want to do this?"}}


	    column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'execute run', :col_width => 50,
			:settings =>
				 {:image => 'execute_run',
				:target_action => 'execute_production_run',
				:id_column => 'id'}}



	else

	 if run_type
	   view_action = "view_" + run_type
	 end

	  column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view production_run', :col_width => 50,
			:settings =>
				 {:link_text => 'view',
				:target_action => view_action,
				:id_column => 'id'}}

	  if is_active_runs_grid && run_type == 'active_run'
	     column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'reconfig run', :col_width => 60,
			:settings =>
				 {:image => 'reconfig_run',
				:target_action => 'reconfigure_run',
				:id_column => 'id'}}

	  else
	    column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'restore run', :col_width => 50,
			:settings =>
				 {:image => 'unlock',
				:target_action => 'restore_run',
				:id_column => 'id'}}
	  end
	end

 # return get_data_grid(data_set,column_configs,MesScada::GridPlugins::Production::RunEditGridPlugin.new(self,request),true,nil,:save_action => '/production/runs/update_ranked_runs')

  return get_data_grid(data_set,column_configs, MesScada::GridPlugins::Production::RunEditGridPlugin.new(self,request), true, nil, :save_action => '/production/runs/update_ranked_runs')
end


def build_production_schedule_grid(data_set,can_create_run)

    #require File.dirname(__FILE__) + "/../../../app/helpers/production/run_setup_plugin.rb"

    column_configs = Array.new

	column_configs[0] = {:field_type => 'text',:field_name => 'production_schedule_name',:col_width => 250,}
	column_configs[1] = {:field_type => 'text',:field_name => 'planned_start_date',:col_width => 140}
	column_configs[2] = {:field_type => 'text',:field_name => 'planned_end_date',:col_width => 140}
	column_configs[3] = {:field_type => 'text',:field_name => 'farm_group_code',:col_width => 135}
	column_configs[4] = {:field_type => 'text',:field_name => 'iso_week_code',:col_width => 50,:column_caption => 'week'}
	column_configs[5] = {:field_type => 'text',:field_name => 'season_code',:col_width => 80}
	column_configs[6] = {:field_type => 'text',:field_name => 'production_schedule_status_code',:col_width => 65,:column_caption => 'status'}
	column_configs[7] = {:field_type => 'text',:field_name => 'variety',:col_width => 65}
	column_configs[8] = {:field_type => 'text',:field_name => 'farm_pack',:col_width => 60}
#	----------------------
#	define action columns
#	----------------------
     if can_create_run
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'create run',:col_width => 72,
			:settings =>
				 {:link_text => 'new run',
				:target_action => 'new_run',
				:id_column => 'id'}}
	 end

	 column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'editing runs',:col_width => 72,
			:settings =>
				 {:link_text => 'editing runs',
				:target_action => 'editing_runs',
				:id_column => 'id'}}

	column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'active runs', :col_width => 72,
			:settings =>
				 {:link_text => 'active runs',
				:target_action => 'active_runs',
				:id_column => 'id'}}


	column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'completed runs', :col_width => 72,
			:settings =>
				 {:link_text => 'completed runs',
				:target_action => 'completed_runs',
				:id_column => 'id'}}

 return get_data_grid(data_set,column_configs,MesScada::GridPlugins::Production::RunSetupGridPlugin.new)
end



#==================
#PACK STATIONS CODE
#==================

def build_set_fg_product_form(pack_station,action,caption)

  field_configs = Array.new

	#generate javascript for the on_complete ajax event for each combo for fk table: pack_material_products
	combos_js = gen_combos_clear_js_for_combos(["pack_station_fg_product_code","pack_station_carton_setup_code"])

	#Observers for combos representing the key fields of fkey table: carton_setup_id
	fg_code_observer  = {:updated_field_id => "carton_setup_code_cell",
					 :remote_method => 'pack_station_fg_product_code_changed', #re-using existing handler
					 :on_completed_js => combos_js["pack_station_fg_product_code"]}


    on_complete_js = "\n img = document.getElementById('img_pack_station_carton_setup_code');"
	on_complete_js += "\n if(img != null)img.style.display = 'none';"

	session[:pack_station_form] = Hash.new
	session[:pack_station_form][:carton_setup_js]= on_complete_js

	#Observers for search combos
	carton_setup_observer  = {:updated_field_id => "ajax_distributor_cell",
					 :remote_method => 'carton_setup_combo_changed',
					 :on_completed_js => on_complete_js}


  #-----------------------------------------------------------------------
  #Find fg_codes from fg_setups that match following criteria:
  #-> stand_size_count,marketing_variety,grade_code,production_schedule
  #-----------------------------------------------------------------------

    fg_codes = FgSetup.fg_codes_for_station_link_context(pack_station,session[:current_production_run]).map{|f|f.fg_product_code}
    fg_codes.unshift "<empty>"
   # pack_station.fg_product_code = "<empty>" if !pack_station.fg_product_code
    #----------------------------------------------------------------------------------------
    #See if a carton link record has been created, if so set this record's fg to the link fg
    #----------------------------------------------------------------------------------------

    link = CartonLink.find_by_production_run_id_and_station_code(session[:current_production_run].id,pack_station.station_code)
    pack_station.fg_product_code = link.fg_product_code if link
    pack_station.carton_setup_code = link.carton_setup_code if link

    if link
      carton_setup = CartonSetup.find(link.carton_setup_id)
      pack_station.inventory_code = carton_setup.fg_setup.inventory_code
      pack_station.target_market = carton_setup.fg_setup.target_market
      pack_station.extended_fg_code = carton_setup.fg_setup.extended_fg_code
      pack_station.marking = carton_setup.fg_setup.marking
      pack_station.retailer_sell_by_code = carton_setup.fg_setup.retailer_sell_by_code
      pack_station.order_no = carton_setup.order_number
      pack_station.diameter = carton_setup.fg_setup.diameter
      pack_station.palletizing = carton_setup.pallet_setup.pallet_format_product_code.to_s + ": " + carton_setup.pallet_setup.no_of_cartons.to_s
      #pack_station.nett_mass = carton_setup.fg_setup.nett_mass
      packing_order = carton_setup.sequence_number.to_s
      packing_order = carton_setup.pack_order if carton_setup.pack_order
      pack_station.packing_order = packing_order

    end

    carton_setups = nil
    if pack_station.fg_product_code != ""
      carton_setups = CartonSetup.find_all_by_production_schedule_code_and_fg_product_code(pack_station.production_schedule_name, pack_station.fg_product_code).map {|c|[c.carton_setup_code]}
       carton_setups.unshift("<empty>")
    else
      carton_setups = ["select a value from fg product code"]
    end


	field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'production_schedule_name'}

	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'production_run_number'}


	field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'marketing_variety'}

	field_configs[3] =  {:field_type => 'LabelField',
						:field_name => 'color_percentage'}


    field_configs[4] =  {:field_type => 'LabelField',
						:field_name => 'grade'}

	field_configs[5] =  {:field_type => 'LabelField',
						:field_name => 'more_groups'}

	field_configs[6] =  {:field_type => 'LabelField',
						:field_name => 'size_count'}

    field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'station_code',:settings => {:css_class => "heading_field"}}

	field_configs[8] = {:field_type => 'DropDownField',
						:field_name => 'fg_product_code',
						:settings => {:list => fg_codes},
						:observer => fg_code_observer}

	field_configs[9] = {:field_type => 'DropDownField',
						:field_name => 'carton_setup_code',
						:settings => {:list => carton_setups},
						:observer => carton_setup_observer}

	#-----------------------------------------
	#Additional fields-related to carton setup
	#------------------------------------------
	field_configs[10] =  {:field_type => 'LabelField',
						:field_name => 'packing_order',:settings => {:css_class => "derived_field_nb"}}

	 field_configs[11] =  {:field_type => 'LabelField',
						:field_name => 'extended_fg_code',:settings => {:css_class => "derived_field"}}

	 field_configs[12] =  {:field_type => 'LabelField',
						:field_name => 'inventory_code',:settings => {:css_class => "derived_field"}}

	 field_configs[13] =  {:field_type => 'LabelField',
						:field_name => 'target_market',:settings => {:css_class => "derived_field"}}


	 field_configs[14] =  {:field_type => 'LabelField',
						:field_name => 'marking',:settings => {:css_class => "derived_field"}}

	field_configs[15] =  {:field_type => 'LabelField',
						:field_name => 'diameter',:settings => {:css_class => "derived_field"}}

	field_configs[15] =  {:field_type => 'LabelField',
						:field_name => 'diameter',:settings => {:css_class => "derived_field"}}

	field_configs[16] =  {:field_type => 'LabelField',
						:field_name => 'retailer_sell_by_code',:settings => {:css_class => "derived_field",:label_caption => "sell_by_code"}}

#	field_configs[16] =  {:field_type => 'LabelField',
#						:field_name => 'nett_mass'}

	field_configs[17] =  {:field_type => 'LabelField',
						:field_name => 'palletizing',:settings => {:css_class => "derived_field"}}

    field_configs[18] =  {:field_type => 'LabelField',
						:field_name => 'order_no',:settings => {:css_class => "derived_field"}}

	field_configs[19] =  {:field_type => 'HiddenField',
						:field_name => 'ajax_distributor',
						:non_db_field => true}

	build_form(pack_station,field_configs,action,'pack_station',caption)

end


def build_set_fg_product_for_binfill_station_form(pack_station,action,caption)

  field_configs = Array.new

	#generate javascript for the on_complete ajax event for each combo for fk table: pack_material_products
	combos_js = gen_combos_clear_js_for_combos(["pack_station_fg_product_code","pack_station_carton_setup_code"])

	#Observers for combos representing the key fields of fkey table: carton_setup_id
	fg_code_observer  = {:updated_field_id => "carton_setup_code_cell",
					 :remote_method => 'pack_station_fg_product_code_changed', #re-using existing handler
					 :on_completed_js => combos_js["pack_station_fg_product_code"]}


  #-----------------------------------------------------------------------
  #Find fg_codes from fg_setups that match following criteria:
  #-> stand_size_count,marketing_variety,grade_code,production_schedule
  #-----------------------------------------------------------------------

    fg_codes = FgSetup.fg_codes_for_binfill_station_context(session[:current_closed_schedule].production_schedule_name,pack_station.pack_group.grade_code,pack_station.pack_group.color_sort_percentage,pack_station.pack_group.marketing_variety_code).map{|f|f.fg_product_code}
    fg_codes.unshift "<empty>"
   # pack_station.fg_product_code = "<empty>" if !pack_station.fg_product_code
    #----------------------------------------------------------------------------------------
    #See if a carton link record has been created, if so set this record's fg to the link fg
    #----------------------------------------------------------------------------------------

    link = RebinLink.find_by_production_run_id_and_station_code(session[:current_production_run].id,pack_station.binfill_station_code)

    pack_station.fg_product_code = link.fg_product_code if link
    pack_station.carton_setup_code = link.carton_setup_code if link

    carton_setups = nil
    if pack_station.fg_product_code != ""
      carton_setups = CartonSetup.find_all_by_production_schedule_code_and_fg_product_code(pack_station.production_schedule_name, pack_station.fg_product_code).map {|c|[c.carton_setup_code]}
    else
      carton_setups = ["select a value from fg product code"]
    end


	field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'production_schedule_name'}

	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'production_run_number'}

	field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'marketing_variety'}

	field_configs[3] =  {:field_type => 'LabelField',
						:field_name => 'color_percentage'}

    field_configs[4] =  {:field_type => 'LabelField',
						:field_name => 'grade'}

    field_configs[5] =  {:field_type => 'LabelField',
						:field_name => 'binfill_station_code'}

	field_configs[6] = {:field_type => 'DropDownField',
						:field_name => 'fg_product_code',
						:settings => {:list => fg_codes},
						:observer => fg_code_observer}

	field_configs[7] = {:field_type => 'DropDownField',
						:field_name => 'carton_setup_code',
						:settings => {:list => carton_setups}}

	build_form(pack_station,field_configs,action,'pack_station',caption)

end


 def build_pack_stations_grid(data_set,can_edit)

	column_configs = Array.new
	 #require File.dirname(__FILE__) + "/../../../app/helpers/production/run_setup_plugin.rb"

	#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'set_fg_product', :col_width => 77,
			:settings =>
				 {:link_text => 'set_fg_product',
				:target_action => 'set_fg_product',
				:id_column => 'id',
				:null_test => "size_count == nil"}}



	end

	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'drop_side_code',:col_width => 30}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'drop_code',:col_width => 30}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'station_code',:col_width => 62}

	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'size_count',:col_width => 50}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'grade',:col_width => 37}

	    column_configs[ column_configs.length()]={:field_type=>'link_window',:field_name =>'view carton label',:col_width => 35,
                       :settings =>
                      {:id_column => 'id',
                       :null_test => "fg_product_code == nil",
                       :host_and_port =>request.host_with_port.to_s,
                       :controller =>request.path_parameters['controller'].to_s ,
                       :target_action => 'view_label_for_carton_setup',
                       :image => 'label'} }

	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'color_percentage',:col_width => 45,:column_caption => '% color'}
    column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'fg_product_code',:col_width => 315}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'carton_setup_code',:col_width => 125}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'marketing_variety',:col_width => 50,:column_caption => 'variety'}


	if can_edit
	  column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'set_rmt_product',:col_width => 120,
			:settings =>
				 {:link_text => 'set_rmt_product',
				:target_action => 'set_rmt_product_for_pack_station',
				:id_column => 'id',
				:null_test => "rebin_group == nil"}}

	end
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'rmt_product_code',:col_width => 120}
	column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'more_groups', :col_width => 100,
			:settings => {:target_action => 'view_additional_groups',
				:id_column => 'id',:can_be_empty => true,:null_test => 'additional_groups == nil'}}




 return get_data_grid(data_set,column_configs,MesScada::GridPlugins::Production::PackStationGridPlugin.new)

end

#======================
#BINFILL STATIONS CODE
#======================
def build_set_rmt_product_form(binfill_station,action,caption)

  field_configs = Array.new

  #-----------------------------------------------------------------------
  #Find rmt_codes from rebin_setups that match following criteria:
  #-> size,marketing_variety,grade_code,production_schedule
  #-----------------------------------------------------------------------

    rmt_product_codes = RebinSetup.find_all_by_production_schedule_id(session[:current_production_run].production_schedule.id).map{|f|f.rmt_product_code}
    rmt_product_codes.unshift "<empty>"
   # binfill_station.rmt_product_code = "<empty>" if !binfill_station.rmt_product_code
    #----------------------------------------------------------------------------------------
    #See if a rebin link record has been created, if so set this record's fg to the link fg
    #----------------------------------------------------------------------------------------

    link = RebinLink.find_by_production_run_id_and_station_code(session[:current_production_run].id,binfill_station.binfill_station_code)
    binfill_station.rmt_product_code = link.rmt_product_code if link

	field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'production_schedule_name'}

	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'production_run_number'}

	field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'marketing_variety'}

	field_configs[3] =  {:field_type => 'LabelField',
						:field_name => 'color_percentage'}

    field_configs[4] =  {:field_type => 'LabelField',
						:field_name => 'grade'}

	field_configs[5] =  {:field_type => 'LabelField',
						:field_name => 'more_groups'}

	field_configs[6] =  {:field_type => 'LabelField',
						:field_name => 'size'}

    field_configs[7] =  {:field_type => 'LabelField',
						:field_name => 'binfill_station_code'}

	field_configs[8] = {:field_type => 'DropDownField',
						:field_name => 'rmt_product_code',
						:settings => {:list => rmt_product_codes}}

	build_form(binfill_station,field_configs,action,'binfill_station',caption)

end


def build_set_rmt_product_for_pack_station_form(pack_station,action,caption)

  field_configs = Array.new

  #-----------------------------------------------------------------------
  #Find rmt_codes from rebin_setups that match following criteria:
  #-> size,marketing_variety,grade_code,production_schedule
  #-----------------------------------------------------------------------

    rmt_product_codes = RebinSetup.find_all_by_production_schedule_id(session[:current_production_run].production_schedule.id).map{|f|f.rmt_product_code}#RebinSetup.find_all_by_production_schedule_code_and_grade_code_and_color_percentage_and_variety_output_description_and_size(binfill_station.production_schedule_name,binfill_station.grade,binfill_station.color_percentage,binfill_station.marketing_variety,binfill_station.size).map{|f|f.rmt_product_code}
    rmt_product_codes.unshift "<empty>"

    #----------------------------------------------------------------------------------------
    #See if a rebin link record has been created, if so set this record's fg to the link fg
    #----------------------------------------------------------------------------------------

    link = CartonLink.find_by_production_run_id_and_station_code(pack_station.production_run_id,pack_station.station_code)

    pack_station.color_percentage = pack_station.rebin_group.color_sort_percentage
    pack_station.grade = pack_station.rebin_group.grade_code


	field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'production_schedule_name'}

	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'production_run_number'}

	field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'marketing_variety'}

	field_configs[3] =  {:field_type => 'LabelField',
						:field_name => 'color_percentage'}

    field_configs[4] =  {:field_type => 'LabelField',
						:field_name => 'grade'}


    field_configs[5] =  {:field_type => 'LabelField',
						:field_name => 'station_code'}

	field_configs[6] = {:field_type => 'DropDownField',
						:field_name => 'rmt_product_code',
						:settings => {:list => rmt_product_codes}}

	build_form(pack_station,field_configs,action,'pack_station',caption)

end

 def build_binfill_stations_grid(data_set,can_edit)

	column_configs = Array.new
	 #require File.dirname(__FILE__) + "/../../../app/helpers/production/run_setup_plugin.rb"

	 #	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'set_rmt_product',:col_width => 129,
			:settings =>
				 {:link_text => 'set_rmt_product',
				:target_action => 'set_rmt_product',
				:id_column => 'id',
				:null_test => "has_allocated_outlet? == false"}}

		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'set_fg_product',:col_width => 130,
			:settings =>
				 {:link_text => 'set_fg_product',
				:target_action => 'set_fg_product_for_binfill_station',
				:id_column => 'id',
				:null_test => "pack_group == nil"}}


	end

	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'drop_code',:col_width => 24}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'binfill_station_code',:col_width => 100}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'size',:col_width => 66}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'grade',:col_width => 45}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'color_percentage',:col_width => 44,:column_caption => '% color'}

	column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'more_groups', :col_width => 44,
			:settings => {:target_action => 'view_additional_groups_binfill',
				:id_column => 'id',:can_be_empty => true,:null_test => 'additional_groups == nil'}}

	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'marketing_variety',:col_width => 85,:col_width => 60,:column_caption => 'variety'}
	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'rmt_product_code',:col_width => 85,:col_width => 241}



	column_configs[column_configs.length()] = {:field_type => 'text',:field_name => 'fg_product_code',:col_width => 324}

 return get_data_grid(data_set,column_configs,MesScada::GridPlugins::Production::BinfillStationGridPlugin.new)

end

#==========================
#BINFILL SORT STATIONS CODE
#==========================

def build_set_rmt_product_form_for_sorter(binfill_sort_station,action,caption)

  field_configs = Array.new

  #------------------------------------------------------------------------------
  #Find rmt_codes from rebin_setups that match following criteria:
  #-> size,marketing_variety,grade_code,production_schedule and standard
  #size_count_from = -1 (the user selected this value at processing setup
  #to indicate that the rebin is targeted for the sorter and will not be 'dropped'
  #-------------------------------------------------------------------------------

    rmt_product_codes = RebinSetup.find_all_by_production_schedule_code_and_standard_size_count_from(binfill_sort_station.production_schedule_name,-1).map{|f|f.rmt_product_code}
    rmt_product_codes.unshift "<empty>"
  #  binfill_sort_station.rmt_product_code = "<empty>"
    #----------------------------------------------------------------------------------------
    #See if a rebin link record has been created, if so set this record's fg to the link fg
    #----------------------------------------------------------------------------------------

    link = RebinLink.find_by_production_run_id_and_station_code_and_is_sort_station(binfill_sort_station.production_run_id,binfill_sort_station.binfill_sort_station_code,true)
    binfill_sort_station.rmt_product_code = link.rmt_product_code if link

	field_configs[0] =  {:field_type => 'LabelField',
						:field_name => 'production_schedule_name'}

	field_configs[1] =  {:field_type => 'LabelField',
						:field_name => 'production_run_number'}

    field_configs[2] =  {:field_type => 'LabelField',
						:field_name => 'binfill_sort_station_code'}

	field_configs[3] = {:field_type => 'DropDownField',
						:field_name => 'rmt_product_code',
						:settings => {:list => rmt_product_codes}}

	build_form(binfill_sort_station,field_configs,action,'binfill_sort_station',caption)

end

 def build_binfill_sort_stations_grid(data_set,can_edit)

	column_configs = Array.new
	 #require File.dirname(__FILE__) + "/../../../app/helpers/production/run_setup_plugin.rb"

	column_configs[0] = {:field_type => 'text',:field_name => 'binfill_sort_station_code',:col_width => 100}

	column_configs[1] = {:field_type => 'text',:field_name => 'rmt_product_code',:col_width => 85,:col_width => 253}

#	----------------------
#	define action columns
#	----------------------
	if can_edit
		column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'set_rmt_product', :col_width => 110,
			:settings =>
				 {:link_text => 'set_rmt_product',
				:target_action => 'set_rmt_product_for_sorter',
				:id_column => 'id'}}

	end

 return get_data_grid(data_set,column_configs,MesScada::GridPlugins::Production::BinfillSortStationGridPlugin.new)

end


















end