class Production::RunsController < ApplicationController

  helper "production/rmt_setup"
  helper "tools/sizer_template"


  require "shift" #for some reason the new rails version(1.2.3) cannot cope well with the nested Shiftdetails class when
  require "shift_details.rb" #storing the shift object in session state. Workaround:
                  #So requiring it here, soemwhow helps the issue

  def program_name?
    "runs"
  end

  def bypass_generic_security?
    true
  end

  def production_run_rmt_variety_code_changed
    rmt_variety_id=get_selected_combo_value(params)
    @treatment_codes=Treatment.find_by_sql("select distinct treatments.id,treatments.treatment_code
                                   from treatments
                                   join rmt_products on rmt_products.treatment_id=treatments.id
                                   join varieties on rmt_products.variety_id=varieties.id
                                   join rmt_varieties on   varieties.rmt_variety_id=rmt_varieties.id
                                    where rmt_varieties.id=#{rmt_variety_id}
                                   order by treatment_code").map{|p|[p.treatment_code,p.id]}
    @treatment_codes.unshift("<empty>") if !@treatment_codes.empty?
    @size_codes=Size.find_by_sql(" select  distinct sizes.id,sizes.size_code
                                   from sizes
                                   join rmt_products on rmt_products.size_id=sizes.id
                                   join varieties on rmt_products.variety_id=varieties.id
                                   join rmt_varieties on   varieties.rmt_variety_id=rmt_varieties.id
                                   where rmt_varieties.id=#{rmt_variety_id}
                                   order by size_code").map{|p|[p.size_code,p.id]}
    @size_codes.unshift("<empty>") if !@size_codes.empty?
    @ripe_point_codes=RipePoint.find_by_sql("select distinct ripe_points.id,ripe_points.ripe_point_code
                                   from  ripe_points
                                   join rmt_products on rmt_products.ripe_point_id=ripe_points.id
                                   join varieties on rmt_products.variety_id=varieties.id
                                   join rmt_varieties on   varieties.rmt_variety_id=rmt_varieties.id
                                   where rmt_varieties.id=#{rmt_variety_id}
                                  order by ripe_points.ripe_point_code").map{|p|[p.ripe_point_code,p.id]}
    @track_indicator_codes=TrackIndicator.find_by_sql("select  track_indicators.id,track_indicators.track_indicator_code
                                                              from track_indicators
                                                              join commodities on track_indicators.commodity_code=commodities.commodity_code
                                                              join rmt_varieties on track_indicators.rmt_variety_id=rmt_varieties.id
                                where rmt_varieties.id=#{rmt_variety_id} and commodities.id=#{session[:comodity_id]} order by track_indicators.track_indicator_code").map{|g|[g.track_indicator_code,g.id]}
    @track_indicator_codes.unshift("<empty>") if !@track_indicator_codes.empty?
    @ripe_point_codes.unshift("<empty>") if !@ripe_point_codes.empty?
    render :inline => %{
    <%= treatment_content = select('production_run','treatment_id',@treatment_codes)%>
    <%= size_content =select('production_run','size_id',@size_codes)%>
    <%= ripe_point_content =select('production_run','ripe_point_id',@ripe_point_codes)%>
    <%= track_indicator_codes_content =select('production_run','track_indicator_id',@track_indicator_codes)%>

    <script>
    <%= update_element_function(
    "size_id_cell", :action => :update,
    :content => size_content) %>

    <%= update_element_function(
    "ripe_point_id_cell", :action => :update,
    :content => ripe_point_content) %>

    <%= update_element_function(
    "treatment_id_cell", :action => :update,
    :content => treatment_content) %>

    <%= update_element_function(
    "track_indicator_id_cell", :action => :update,
    :content => track_indicator_codes_content) %>

    </script>
    <%= refresh_combo_observer_no_img('production_run_ripe_point_id', 'pc_code_id_cell', 'production_run_ripe_point_code_changed') %>
    }
  end

  def production_run_ripe_point_code_changed
    ripe_point_id=get_selected_combo_value(params)
    ripe_point_id = nil if ripe_point_id=="empty"
    if ripe_point_id
    @pc_codes =PcCode.find_by_sql("select pc_codes.pc_name ,pc_codes.id from pc_codes join ripe_points on ripe_points.pc_code_id=pc_codes.id where ripe_points.id=#{ripe_point_id} ").map{|p|[p.pc_name,p.id]}
    @pc_codes.unshift("<empty>") if !@pc_codes.empty?
    else
      @pc_codes=[]
    end
    render :inline => %{
    <%= pc_name_content = select('production_run','pc_code_id',@pc_codes)%>
    <script>
      <%= update_element_function(
      "pc_code_id_cell", :action => :update,
      :content => pc_name_content) %>
    </script>
    }
  end

  def active_schedules

    list_production_schedules

  end


  def schedule_search
    render :inline => %{
		<% @content_header_caption = "'search closed schedules'"%>

		<%= build_schedule_search_form()%>

		}, :layout => 'content'

  end

  def schedule_search_season_changed

    season = get_selected_combo_value(params)
    @varieties = ProductionSchedule.find_by_sql("select distinct variety_code from production_schedules where season_code = '#{season}' and upper(production_schedule_status_code) = 'CLOSED' ").map { |s| [s.variety_code] }

    render :inline => %{
		<%= select('schedule','input_variety',@varieties)%>
  }

  end

  def schedule_search_submit

    season = params['schedule']['season']
    variety = params['schedule']['input_variety']
    if variety.index("select")
      session[:runs_schedules] = "ProductionSchedule.find_by_sql(\"select * from production_schedules where season_code = '#{season}' and variety_code = '#{variety}' and upper(production_schedule_status_code) = 'CLOSED' \")"
    else
      session[:runs_schedules] = "ProductionSchedule.find_by_sql(\"select * from production_schedules where season_code = '#{season}' and variety_code = '#{variety}' and upper(production_schedule_status_code) = 'CLOSED' \")"
    end

    list_production_schedules
    return

  end


#=========================
#MIXED PALLET CRIERIA CODE
#=========================
  def mixed_pallet_criteria
    render :inline => %{
		<% @content_header_caption = "'please enter pallet number'"%>

		<%= build_get_pallet_number_form()%>

		}, :layout => 'content'

  end

  def set_mixed_pallet_criteria

    session[:mixed_pallet_criteria].update_attributes(params['mixed_pallet_criteria'])
    redirect_to_index("mixed pallet criteria set")

  end

  def submit_mixed_pallet_id
    pallet_num = params['pallet_number']['pallet_number']
    #try to find an existing mixed pallet record, if not found
    #-> make sure pallet exists
    #-> create new mixed pallet criteria record
    @mixed_pallet_criteria = MixedPalletCriterium.find_by_pallet_number(pallet_num)
    if !@mixed_pallet_criteria
      #try to find pallet
      pallet = Pallet.find_by_pallet_number(pallet_num)
      if !pallet
        redirect_to_index("A pallet with number: " + pallet_num.to_s + " does not exist")
        return
      else
        @mixed_pallet_criteria = MixedPalletCriterium.new
        @mixed_pallet_criteria.pallet_number = pallet.pallet_number
        @mixed_pallet_criteria.pallet_id = pallet.id
        @mixed_pallet_criteria.create
      end

    end
    session[:mixed_pallet_criteria]= @mixed_pallet_criteria
    render :inline => %{
		<% @content_header_caption = "'set mixed pallet criteria'"%>

		<%= build_mixed_pallet_criteria_form(@mixed_pallet_criteria)%>

		}, :layout => 'content'


  end

#==========
#PPECB CODE
#==========


  def set_inspection_carton
    return if authorise_for_web(program_name?, 'ppecb_set_insp_ctn') == false
    render :inline => %{
		<% @content_header_caption = "'please enter carton number'"%>

		<%= build_get_carton_number_form('set_inspection_carton_submit')%>

		}, :layout => 'content'

  end

  def set_inspection_carton_submit
    puts "KK"
    carton_num = params['carton_number']['carton_number'].slice(0, 12).to_i

    @freeze_flash = true
    is_inspection_ctn = false

    #try to find carton
    carton = Carton.find_by_carton_number(carton_num)

    if !carton
      redirect_to_index("A carton with number: " + carton_num.to_s + " does not exist")
      return
    elsif !carton.pallet
      redirect_to_index("No pallet is associated with carton with number: " + carton_num.to_s)
      return
      #elsif carton.pallet.qc_status_code == "INSPECTED"
      #  inspection_cartons = carton.get_inspection_cartons

      # redirect_to_index("The owning pallet(" + carton.pallet.pallet_number.to_s + ") of this carton(" + carton.carton_number.to_s + ") has already been inspected! <BR> Inspection carton(s) is: " + inspection_cartons.join(","))
      # return
    end

    msg = "Pallet is: " + carton.pallet.pallet_number.to_s + "<BR>"
    msg += "Carton is: " + carton.carton_number.to_s + "<BR><BR>"

    inspection_carton = nil
    inspection_cartons = carton.get_inspection_cartons
    if inspection_carton = inspection_cartons.find{|c| c.to_i == carton.carton_number.to_i}

      session[:inspection_ctn]= inspection_carton
    end

    if inspection_cartons.length == 0
      msg += "This pallet has no inspection carton"
    elsif   inspection_carton
      msg += "This is an inspection carton"
      is_inspection_ctn = true
    else
      is_inspection_ctn = false
      msg += "This carton(" + carton.carton_number.to_s + ") is NOT an inspection carton"
    end

    new_inspection_ctn = 0
    new_inspection_ctn = 1 if  ! inspection_carton

    if inspection_cartons.length() + new_inspection_ctn  > 1
      msg += "<BR> All inspection carton(s) for this pallet: " + inspection_cartons.join(",")
    end



    flash[:notice] = msg
    session[:to_be_inspection_ctn] = carton



    if inspection_cartons.length() + new_inspection_ctn > 2
      remove_xtra_insp_ctns(msg)
      return
    end

    if ! is_inspection_ctn
      flash[:notice] += "<BR> Should this(carton number you entered) be an inspection carton? (check checkbox if 'yes')"

      render :inline => %{
      <% @content_header_caption = "'Tell the system whether this carton should be an inspection carton'"%>

      <%= build_set_inspection_carton_form()%>

      }, :layout => 'content'
    else
      flash[:notice] = nil
      redirect_to_index(msg)
    end



  end



  def remove_xtra_insp_ctns(msg)
    inspection_cartons = session[:to_be_inspection_ctn].get_inspection_cartons
    flash[:notice] = nil
    flash[:error] = msg
    render :inline => %{
		<% @content_header_caption = "'Remove an inspection carton. You may only have 2 inspection cartons'"%>

		<%= build_remove_inspection_carton_form()%>

		}, :layout => 'content'

  end


  def remove_inspection_carton_submit

    carton_num = params[:carton_number][:inspection_ctn_to_remove].slice(0, 12).to_i
    carton = Carton.find_by_carton_number(carton_num)

    if !carton
      redirect_to_index("Carton #{params[:carton_number][:inspection_ctn_to_remove]} not found!",nil, true,true)
      return
    end


    inspection_cartons = carton.get_inspection_cartons

    if !inspection_cartons.find{|c|c.to_i == carton_num}
      redirect_to_index("You must specify one of the inspection cartons",nil, true,true)

    else
       carton = Carton.find_by_carton_number(carton_num)
       carton.is_inspection_carton = nil
       carton.pallet.qc_status_code = "UNINSPECTED"
       carton.update
       redirect_to_index("Carton: #{carton_num} is no longer an inspection carton")


    end



  end




  def set_inspection_carton_submit_2
    curr_inspection_ctn = nil
    curr_inspection_ctn = Carton.find_by_carton_number(session[:inspection_ctn]) if session[:inspection_ctn]
    carton = session[:to_be_inspection_ctn]
    must_be_inspection_ctn = params[:carton_number]['is_inspection_carton']== "1"


    carton.transaction do
      if curr_inspection_ctn
        if curr_inspection_ctn.id == carton.id
          #------------------------------------------
          #Carton entered is the inspection carton
          #------------------------------------------
          carton.is_inspection_carton = must_be_inspection_ctn
          if !must_be_inspection_ctn
            # #New rule: there may be upto 2 inspection cartons, not only one; So: do not unset
            # previous inspection ctn
            #------------------------------------------
            #carton.is_inspection_carton = nil
            #carton.pallet.qc_status_code = "UNINSPECTED"
          end
        else
          #-------------------------------------------
          #Carton entered is not the inspection carton
          #-------------------------------------------
          if must_be_inspection_ctn
            #curr_inspection_ctn.is_inspection_carton = nil
            carton.is_inspection_carton = true
          end

        end
      else
        #-----------------------------
        #There is no inspection carton
        #-----------------------------
        if must_be_inspection_ctn
          carton.is_inspection_carton = true
         # carton.pallet.qc_status_code = "INSPECTING"

        end

      end
      carton.update
      carton.pallet.update
      curr_inspection_ctn.update if curr_inspection_ctn && curr_inspection_ctn.id != carton.id

      @freeze_flash = true
      if must_be_inspection_ctn
        redirect_to_index("Carton(" + carton.carton_number.to_s + ") IS  now an inspection carton")
      else
        redirect_to_index("Carton(" + carton.carton_number.to_s + ") IS NOT not the inspection carton")
      end
    end


  end


  def ppecb
    return if authorise_for_web(program_name?, 'ppecb') == false


    render :inline => %{
		<% @content_header_caption = "'please enter carton number'"%>

		<%= build_get_carton_number_form()%>
		<script>
		 document.getElementById('carton_number_carton_number').focus();
		</script>

		}, :layout => 'content'


  end

  def ppecb_correction
    return if authorise_for_web(program_name?, 'ppecb') == false


    render :inline => %{
		<% @content_header_caption = "'please enter carton number'"%>

		<%= build_get_carton_number_form(nil,true)%>
		<script>
		 document.getElementById('carton_number_carton_number').focus();
		</script>

		}, :layout => 'content'


  end


  def set_ppecb_inspection
    begin

      session[:ppecb_inspection].transaction do

        #-----------------------
        #Create ppecb inspection
        #-----------------------
        vals = params[:ppecb_inspection]
        session[:ppecb_inspection].passed = vals[:passed] if vals[:passed]
        session[:ppecb_inspection].inspection_point = vals[:inspection_point] if vals[:inspection_point]
        session[:ppecb_inspection].inspector_number = vals[:inspector_number] if vals[:inspector_number]
        session[:ppecb_inspection].inspection_report = vals[:inspection_report] if vals[:inspection_report]
        session[:ppecb_inspection].sample_carton_label = vals[:sample_carton_label] if vals[:sample_carton_label]
        session[:ppecb_inspection].dispensation_certificate_number = vals[:dispensation_certificate_number] if vals[:dispensation_certificate_number]
        session[:ppecb_inspection].dispensation_body = vals[:dispensation_body] if vals[:dispensation_body]
        session[:ppecb_inspection].inspection_level_code = vals[:inspection_level_code]
        puts "CK PASSED: " + params[:ppecb_inspection][:passed]
        if params[:ppecb_inspection][:passed]== "1"
          session[:ppecb_inspection].reason = nil
        else
          session[:ppecb_inspection].reason = vals[:reason] if vals[:reason]
        end


        #-----------------------------------------------------------------
        #Create fault log if this is correction + create integration flow
        #-----------------------------------------------------------------
        if session[:ppecb_inspection].corrected
          fault_log = PpecbFaultLog.new
          before_state = PpecbInspection.find(session[:ppecb_inspection].id)
          before_state.export_attributes(fault_log, true)
          fault_log.ppecb_inspection_id = before_state.id
          fault_log.create
        end


        #session[:ppecb_inspection].carton.qc_status_code = "INSPECTED"
        #session[:ppecb_inspection].carton.update


        if !session[:ppecb_inspection].inspection_level_code.upcase().index("HG")


          session[:ppecb_inspection].carton.pallet.qc_status_code = "INSPECTED"
          if session[:ppecb_inspection].passed
            session[:ppecb_inspection].carton.pallet.qc_result_status = "PASSED"
          else
            session[:ppecb_inspection].carton.pallet.qc_result_status = "FAILED"
          end


          session[:ppecb_inspection].carton.pallet.update
        end

        if session[:ppecb_inspection].save!

          session[:last_inspection]= session[:ppecb_inspection]


          redirect_to_index("ppecb inspection details saved")
        else
          puts "error ppecb"
          @ppecb_inspection = session[:ppecb_inspection]
          render :inline => %{
		<% @content_header_caption = "'set ppecb inspection details'"%>

		<%= build_ppecb_inspection_form(@ppecb_inspection)%>

		}, :layout => 'content'
        end
      end
    rescue
      handle_error("PPECB inspection could not be saved")
    end
  end


  def submit_ppecb_carton_num

    carton_num = params['carton_number']['carton_number'].chop!.to_i
    #validations:---------------------------------------------------------------------------
    #-> make sure carton exists and pallet exists and carton is the scanned-out ppecb carton
    #-> create new ppecb inspection record
    #---------------------------------------------------------------------------------------

    #try to find carton
    carton = Carton.find_by_carton_number(carton_num)
    if !carton
      redirect_to_index("A carton with number: " + carton_num.to_s + " does not exist")
      return
    elsif !carton.pallet
      redirect_to_index("No pallet is associated with carton with number: " + carton_num.to_s)
      return
    elsif carton.is_inspection_carton == nil || carton.is_inspection_carton == false
      redirect_to_index("carton with number: " + carton_num.to_s + " is not an inspection carton")
      return
    end

    @last_inspection = PpecbInspection.most_recent_inspection?(carton_num)
    if !params['carton_number']['hidden_data']
      @ppecb_inspection = PpecbInspection.new
      @ppecb_inspection.pallet_number = carton.pallet.pallet_number
      @ppecb_inspection.pallet_id = carton.pallet.id
      @ppecb_inspection.carton_number = carton.carton_number
      @ppecb_inspection.carton_id = carton.id
      @ppecb_inspection.inspection_level_code = "FIRST"

      if @last_inspection
        @ppecb_inspection.inspection_point = @last_inspection.inspection_point
        @ppecb_inspection.inspector_number = @last_inspection.inspector_number
        @ppecb_inspection.inspection_report = @last_inspection.inspection_report
        @ppecb_inspection.inspection_level_code = @last_inspection.inspection_level_code
        @ppecb_inspection.dispensation_certificate_number = @last_inspection.dispensation_certificate_number
        @ppecb_inspection.dispensation_body = @last_inspection.dispensation_body
        @ppecb_inspection.passed = @last_inspection.passed
        @ppecb_inspection.reason = @last_inspection.reason

      else
        @ppecb_inspection.inspection_point = "9000"
        @ppecb_inspection.inspection_report = "0000"

      end
    else
      if !@last_inspection
        redirect_to_index("No inspection was done yet")
        return
      else
        @last_inspection.corrected = true
        @ppecb_inspection = @last_inspection

      end
    end

    session[:ppecb_inspection]= @ppecb_inspection
    render :inline => %{
		<% @content_header_caption = "'set ppecb inspection details'"%>

		<%= build_ppecb_inspection_form(@ppecb_inspection)%>

		}, :layout => 'content'


  end

#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: inspection_type_id
#	---------------------------------------------------------------------------------
  def ppecb_inspection_inspection_type_code_changed
    inspection_type_code = get_selected_combo_value(params)
    session[:ppecb_inspection_form][:inspection_type_code_combo_selection] = inspection_type_code
    @grade_codes = PpecbInspection.grade_codes_for_inspection_type_code(inspection_type_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('ppecb_inspection','grade_code',@grade_codes)%>

		}

  end

  def edit_run_details(run = nil)
    @production_run = session[:current_production_run]
    @production_run = run if run
    @schedule = session[:current_closed_schedule]
    render :inline => %{
		<% @content_header_caption = "'edit production_run details'"%>

		<%= build_new_run_form('update_run_details','save',@schedule,@production_run)%>

		}, :layout => 'content'


  end


  def validate_production_run_details_params(line_code,production_run_details_params,new_record=nil)
    error=[]
    line=Line.find_by_line_code(line_code)
    if line.is_dedicated
     if  production_run_details_params['treatment_id']=="" || production_run_details_params['treatment_id']==nil   || production_run_details_params['treatment_id']=="<empty>"  || production_run_details_params['treatment_id']=="empty"
       error << "treatment_code is empty"
     end
     if  production_run_details_params['size_id']=="" || production_run_details_params['size_id']==nil   || production_run_details_params['size_id']=="<empty>"   || production_run_details_params['size_id']=="empty"
       error << "size_code is empty"
     end
     if  production_run_details_params['ripe_point_id']=="" || production_run_details_params['ripe_point_id']==nil   || production_run_details_params['ripe_point_id_id']=="<empty>"  || production_run_details_params['ripe_point_id_id']=="empty"
       error << "ripe_point_code is empty"
     end
     if  production_run_details_params['product_class_id']=="" || production_run_details_params['product_class_id']==nil   || production_run_details_params['product_class_id']=="<empty>"    || production_run_details_params['product_class_id']=="empty"
       error << "product_class_code is empty"
     end
     if  production_run_details_params['track_indicator_id']=="" || production_run_details_params['track_indicator_id']==nil   || production_run_details_params['track_indicator_id']=="<empty>"   || production_run_details_params['track_indicator_id']=="empty"
       error << "track_indicator_code is empty"
     end
    end
    return error
  end


  def update_run_details
    @production_run = ProductionRun.find(session[:current_production_run].id)

    error =validate_production_run_details_params(@production_run.line_code,params['production_run'])
    if !error.empty?
      flash[:error] = "record cannot be saved: <BR> #{error.join("<BR>")}"
      edit_run_details  and return
    end



    #params['production_run'][:rmt_product_type_id]=RmtProductType.find_by_rmt_product_type_code(@production_run.production_schedule.rmt_setup.rmt_product.rmt_product_type_code).id
    #params['production_run'][:commodity_id]= Commodity.find_by_commodity_code(@production_run.production_schedule.rmt_setup.commodity_code).id
    #params['production_run'][:variety_id]=  RmtVariety.find_by_rmt_variety_code(@production_run.production_schedule.rmt_setup.variety_code).id
    @production_run.transaction do
      if params['production_run']['ripe_point_id'] == nil || params['production_run']['ripe_point_id'] == ""
        else
        params['production_run'][:pc_code_id]= PcCode.find_by_sql("select pc_codes.id from pc_codes join ripe_points on ripe_points.pc_code_id=pc_codes.id where ripe_points.id=#{params['production_run']['ripe_point_id']} ")[0].id
      end
      @production_run.update_attributes(params['production_run'])
      @production_run.update_run_code

      #---------------------------------------------------------------------------------------------------------------------------------------------------
      #save child_run attribute on parent (if one is chosen) only if parent does not yet have a child run code (or has one, but has not yet been executed)
      #The child_run attribute will always be stored on parent at the point when run is executed
      #---------------------------------------------------------------------------------------------------------------------------------------------------
      if @production_run.parent_run_code
        parent_run = ProductionRun.find_by_production_run_code(@production_run.parent_run_code)
        parent_run.child_run_code = @production_run.production_run_code if !parent_run.child_run_code ||(parent_run.child_run_code && parent_run.production_run_status == "configuring")
        parent_run.update

      end
    end
    session[:commodity_id]=nil
    flash[:notice] = "run details updated"
    active_run

  end


#creating a new run from a schedule
  def new_run

    id = params[:id]
    if !Facility.active_pack_house
      flash[:notice]= "You have not defined a default packhouse in the database"
      active_schedules
      return
    end

    if id && @schedule = ProductionSchedule.find(id)
      session[:current_closed_schedule]= @schedule
      session[:current_production_run] = nil
      render_new_production_run(@schedule)
    end

  end


  def current_schedule_runs #actually current or cached editing runs


    if session[:current_closed_schedule]
      editing_runs
      return
    end

    if params[:page]!= nil

      session[:production_runs_page] = params['page']
      render_list_editing_runs

      return
    else
      if !session[:current_schedule_runs_query]
        redirect_to_index("You have not selected a 'closed' schedule yet")
        return
      end
      session[:query]= session[:current_schedule_runs_query]
      @schedule = session[:current_closed_schedule]
      render_list_editing_runs()
    end

  end


#======================
# Sizer templates code
#======================
  def save_to_template
    return if authorise_for_web('runs', 'production_run_setup') == false

    run = session[:current_production_run]
    commodity = run.production_schedule.rmt_setup.commodity_code
    variety = run.production_schedule.rmt_setup.variety_code
    farm_group = run.production_schedule.farm_group_code
    line_config = run.line.line_config.line_config_code


    @sizer_templates = SizerTemplate.find_all_by_commodity_code_and_line_config_code(commodity, line_config)
    #remove incomplete templates
    incomplete = nil
    incomplete_templates = "<strong>Some templates matched, but are incomplete and cannot be used. They are :</strong>"
    @sizer_templates.each do |template|
      if template.pack_group_templates.length == 0
        incomplete = true
        incomplete_templates += "<br> => '" + template.template_name + "'"
        @sizer_templates.delete(template)
      end
    end

    if @sizer_templates.length == 0
      msg = "<strong>No sizer template have been defined that match the active run context.</strong> The relevant fields are: <br>"
      msg += "<font color = 'green><strong> Commodity: </strong>" + commodity + "<br>"
      msg += "<font color = 'green><strong> Variety: </strong>" + variety + "<br>"
      msg += "<font color = 'green><strong> Farm Group: </strong>" + farm_group + "<br>"
      msg += "<font color = 'green><strong> Line Config: </strong>" + line_config

      @freeze_flash = true
      flash[:notice] = msg
      active_run
      return
    end

    if incomplete
      flash[:notice]= incomplete_templates
      @freeze_flash = true
    end


    render :inline => %{
      <% grid            = build_sizer_template_grid(@sizer_templates,false,false,false,true) %>
      <% grid.caption    = 'list of all <strong>applicable </strong> sizer_templates that can be saved to' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end


#Only relevant or matching templates will be listed
  def list_sizer_templates
    return if authorise_for_web('runs', 'production_run_setup') == false

    run = session[:current_production_run]
    commodity = run.production_schedule.rmt_setup.commodity_code
    variety = run.production_schedule.rmt_setup.variety_code
    farm_group = run.production_schedule.farm_group_code
    line_config = run.line.line_config.line_config_code


    @sizer_templates = SizerTemplate.find_all_by_commodity_code_and_line_config_code(commodity, line_config)
    #remove incomplete templates
    incomplete = nil
    incomplete_templates = "<strong>Some templates matched, but are incomplete and cannot be used. They are :</strong>"
    @sizer_templates.each do |template|
      if template.pack_group_templates.length == 0
        incomplete = true
        incomplete_templates += "<br> => '" + template.template_name + "'"
        @sizer_templates.delete(template)
      end
    end


    if @sizer_templates.length == 0
      msg = "<strong>No sizer template have been defined that match the active run context.</strong> The relevant fields are: <br>"
      msg += "<font color = 'green><strong> Commodity: </strong>" + commodity + "<br>"
      msg += "<font color = 'green><strong> Variety: </strong>" + variety + "<br>"
      msg += "<font color = 'green><strong> Farm Group: </strong>" + farm_group + "<br>"
      msg += "<font color = 'green><strong> Line Config: </strong>" + line_config

      @freeze_flash = true
      flash[:notice] = msg
      active_run
      return
    end

    if incomplete
      flash[:notice]= incomplete_templates
      @freeze_flash = true
    end

    @info = "Applying a template will not override any drops that you have already allocated"
    @info += "<br><font color = 'blue'>The template groups will only be applied to pack groups with matching color sort percentage and grades</font>"
    @info += "<br><font color = 'red'><strong>Applying a template will take some time. Please be patient</strong></font>"
    render :inline => %{
      <% grid            = build_sizer_template_grid(@sizer_templates,false,false,true) %>
      <% grid.caption    = 'list of all <strong>applicable </strong> sizer_templates for the current run' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end


  def apply_sizer_template

    sizer_template = SizerTemplate.find(params[:id])
    n_groups_applied = 0
    n_groups_applied = session[:current_production_run].apply_sizer_template(sizer_template)

    if n_groups_applied == 0
      @freeze_flash = true
      flash[:notice]= "None of the template pack groups could be matched with this run's pack groups"
    else

      flash[:notice] = " Template successfully mathed and applied to " + n_groups_applied.to_s + " pack groups"
    end

    active_run

  end

  def create_new_template
    begin
      new_name = params[:templ][:template_name]
      if SizerTemplate.find_by_template_name(new_name)
        flash[:error]= " A template with name: " + new_name + " already exists"
        new_template
        return
      end

      new_template = SizerTemplate.new(params[:templ])
      PackGroup.set_ignore_after_find_on(session[:current_production_run].id)
      session[:current_production_run].create_sizer_template(new_template)
      flash[:notice] = "New template: " + new_template.template_name + " created successfully"
      active_run
    rescue
      handle_error("Sizer template could not be created")
    ensure
      PackGroup.set_ignore_after_find_off(session[:current_production_run].id)
    end

  end

  def new_template

    return if authorise_for_web('runs', 'production_run_setup') == false
    run = session[:current_production_run]
    commodity = run.production_schedule.rmt_setup.commodity_code
    variety = run.production_schedule.rmt_setup.variety_code
    farm_group = run.production_schedule.farm_group_code
    line_config = run.line.line_config.line_config_code


    @sizer_templates = SizerTemplate.find_all_by_commodity_code_and_line_config_code(commodity, line_config).map { |t| [t.template_name] }
    @active_template = nil
    if run.applied_sizer_template
      @active_template = SizerTemplate.find_by_template_name(run.applied_sizer_template)
    end

    render :inline => %{
		<% @content_header_caption = "'create new template'"%>

		<%= build_new_template_form('create_new_template','create',@sizer_templates,@active_template)%>

		}, :layout => 'content'

  end

  def template_commodity_code_changed

    puts "HELLO"
    commodity_code = get_selected_combo_value(params)

    @variety_codes = RmtVariety.find_by_sql("Select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}'").map { |g| [g.rmt_variety_code] }
#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('templ','rmt_variety_code',@variety_codes)%>

		}

  end


  def template_name_combo_changed


    template_name = get_selected_combo_value(params)
    @templ = nil

    @templ = SizerTemplate.find_by_template_name(template_name)
    @commodity_codes = Commodity.find(:all).map { |c| [c.commodity_code] }
    @variety_codes = RmtVariety.find_by_sql("Select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{@templ.commodity_code}'").map { |g| [g.rmt_variety_code] }
    @complete_js = session[:new_template_form][:on_complete_js_for_commodity]
    @farm_group_codes = FarmGroup.find_by_sql('select distinct farm_group_code from farm_groups').map { |g| [g.farm_group_code] }

    render :inline => %{

    <%commodity_content = select('templ','commodity_code',@commodity_codes) + "<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_templ_commodity_code'/>"%>

    <%variety_content = select('templ','rmt_variety_code',@variety_codes)%>
	<%farm_group_content = select('templ','farm_group_code',@farm_group_codes)%>


   <script>

     <% content = text_field('templ', 'template_name')%>

     <%= update_element_function(
        "template_name_cell", :action => :update,
        :content => content) %>

   <%= update_element_function(
        "commodity_code_cell", :action => :update,
        :content => commodity_content) %>

    <%= update_element_function(
        "rmt_variety_code_cell", :action => :update,
        :content => variety_content) %>

     <%= update_element_function(
        "farm_group_code_cell", :action => :update,
        :content => farm_group_content ) %>

   </script>

    <%= observe_field('templ_commodity_code',:update => 'rmt_variety_code_cell',:url => {:action => 'template_commodity_code_changed'},:loading => "show_element('img_templ_commodity_code');",:complete => @complete_js ) %>

  }

  end


  def save_to_template_submit

    sizer_template = SizerTemplate.find(params[:id])
    n_groups_applied = 0
    n_groups_applied = session[:current_production_run].save_to_sizer_template(sizer_template)

    if n_groups_applied == 0
      @freeze_flash = true
      flash[:notice]= "None of the template pack groups could be matched with this run's pack groups"
    else

      flash[:notice] = " Template successfully saved. " + n_groups_applied.to_s + " groups were matched and updated."
    end

    active_run

  end

#===============================
#Active runs for closed schedule
#===============================


  def current_active_runs


    if session[:current_closed_schedule]
      active_runs
      return
    end

    if !session[:current_schedule_active_runs_query]
      redirect_to_index("you dont have a cached 'active runs' list")
    else
      session[:query]= session[:current_schedule_active_runs_query]
      @schedule = session[:current_closed_schedule]
      render_list_active_runs
    end
  end

  def current_completed_runs

    if session[:current_closed_schedule]
      completed_runs
      return
    end

    if !session[:current_schedule_completed_runs_query]
      redirect_to_index("you dont have a cached 'completed runs' list")
    else
      session[:query]= session[:current_schedule_completed_runs_query]
      @schedule = session[:current_closed_schedule]
      render_list_active_runs true
    end
  end

  def active_runs
    return if authorise_for_web('runs', 'production_run_setup') == false
    #begin
    if params[:page]!= nil

      session[:production_runs_page] = params['page']
      render_list_editing_runs

      return
    else
      session[:production_runs_page] = nil
    end

    if params[:id]
      @schedule = ProductionSchedule.find(params[:id])
      session[:current_closed_schedule] = @schedule
    else
      @schedule = session[:current_closed_schedule]
    end


    list_query = "@production_runs_pages = Paginator.new self, ProductionRun.count(\"production_schedule_id = '#{@schedule.id.to_s}' and production_run_status = 'active'\"), @@page_size,@current_page
	 @production_runs = ProductionRun.find_all_by_production_schedule_id_and_production_run_status('#{@schedule.id.to_s}','active',
				 :limit => @production_runs_pages.items_per_page,
				 :order => 'production_run_number',
				 :offset => @production_runs_pages.current.offset)"
    session[:query] = list_query
    session[:current_schedule_active_runs_query]= session[:query]

    render_list_active_runs
    # rescue
    #  handle_error("active runs could not be fetched for the schedule")
    # end
  end


  def completed_runs
    return if authorise_for_web('runs', 'production_run_setup') == false
    #begin
    if params[:page]!= nil

      session[:production_runs_page] = params['page']
      render_list_editing_runs

      return
    else
      session[:production_runs_page] = nil
    end

    if params[:id]
      @schedule = ProductionSchedule.find(params[:id])
      session[:current_closed_schedule] = @schedule
    else
      @schedule = session[:current_closed_schedule]
    end


    list_query = "@production_runs_pages = Paginator.new self, ProductionRun.count(\"production_schedule_id = '#{@schedule.id.to_s}' and production_run_status = 'completed'\"), @@page_size,@current_page
	 @production_runs = ProductionRun.find_all_by_production_schedule_id_and_production_run_status('#{@schedule.id.to_s}','completed',
				 :limit => @production_runs_pages.items_per_page,
				 :order => 'production_run_number',
				 :offset => @production_runs_pages.current.offset)"
    session[:query] = list_query
    session[:current_schedule_completed_runs_query]= session[:query]

    render_list_active_runs true
    # rescue
    #  handle_error("active runs could not be fetched for the schedule")
    # end
  end


  def render_list_active_runs(is_completed_runs = nil)

    @can_control_run = authorise(program_name?, 'production_run_control', session[:user_id])

    @current_page = session[:production_runs_page] if session[:producion_runs_page]

    @current_page = params['page'] if params['page']

    @production_runs = eval(session[:query]) if !@production_runs
    @clone_allowed = nil
    @clone_allowed = true if @can_control_run
    if @production_runs.length == 0
      if is_completed_runs
        redirect_to_index("There are no 'completed' runs for the selected schedule")
      else
        redirect_to_index("There are no 'active' runs for the selected schedule")
      end
      return
    end

    if is_completed_runs
      @run_type = 'completed_run'
      @caption = "list of completed runs for schedule: " + session[:current_closed_schedule].production_schedule_name
    else
      @run_type = 'active_run'
      @caption = "list of active runs for schedule: " + session[:current_closed_schedule].production_schedule_name
    end

    render :inline => %{
      <% grid            = build_production_run_grid(@production_runs,false,@can_control_run,@run_type) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@production_runs_pages) if @production_runs_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end


#==============
#Editing runs
#==============

  def editing_runs
    return if authorise_for_web('runs', 'production_run_setup') == false
    begin
      if params[:page]!= nil

        session[:production_runs_page] = params['page']
        render_list_editing_runs

        return
      else
        session[:production_runs_page] = nil
      end

      if params[:id]
        @schedule = ProductionSchedule.find(params[:id])
        session[:current_closed_schedule] = @schedule
      else
        @schedule = session[:current_closed_schedule]
      end

      list_query = "@production_runs_pages = Paginator.new self, ProductionRun.count(\"production_schedule_id = '#{@schedule.id.to_s}' and (production_run_status = 'configuring' or production_run_status = 'reconfiguring' or production_run_status = 'restored')\"), @@page_size,@current_page
	 @production_runs = ProductionRun.find_all_by_production_schedule_id_and_production_run_status('#{@schedule.id.to_s}',['configuring','reconfiguring','restored'],
				 :limit => @production_runs_pages.items_per_page,
				 :order => 'production_run_number',
				 :offset => @production_runs_pages.current.offset)"
      session[:query] = list_query
      session[:current_schedule_runs_query]= session[:query]

      render_list_editing_runs
    rescue
      handle_error("editing runs could not be fetched for the schedule")
    end
  end

  def render_list_editing_runs()

    @can_edit_run = authorise(program_name?, 'production_run_setup', session[:user_id])

    @current_page = session[:production_runs_page] if session[:producion_runs_page]

    @current_page = params['page'] if params['page']

    @production_runs = eval(session[:query]) if !@production_runs

    if @production_runs.length == 0
      redirect_to_index("There are no <strong> editing </strong >runs for the selected schedule")
      return
    end

    #@caption = "'<font color = \"brown\">list of configuring runs for schedule: " + @schedule.production_schedule_name + "</font>'"
    @caption = "list of configuring runs for schedule: " + @schedule.production_schedule_name

    render :inline => %{
      <% grid            = build_production_run_grid(@production_runs,@can_edit_run) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@production_runs_pages) if @production_runs_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end


  def active_run
    begin
      if !session[:current_production_run]
        redirect_to_index("You have not yet selected a production run or have since deleted the active run")
      else

        @production_run = session[:current_production_run].reload
        # puts "ctrl n outlets: for group 0: " + session[:current_production_run].pack_groups[0].pack_group_outlets.length().to_s
        #puts "ctrl n outlets: for group 1: " + session[:current_production_run].pack_groups[1].pack_group_outlets.length().to_s

        session[:current_closed_schedule] = @production_run.production_schedule

        if session[:current_production_run].production_run_status == "configuring"||session[:current_production_run].production_run_status == "reconfiguring"||session[:current_production_run].production_run_status == "restored"
          render_edit_production_run
        else
          view_run
        end
      end
    rescue
      handle_error("<strong>Active run couldn't be found. Propable cause: </strong> <br> The session store was manually cleared or the production run record was manually deleted from the <br> database very recently")
    end

  end


  def set_current_schedule
    @production_run = ProductionRun.find(params[:id])
    session[:current_closed_schedule] = @production_run.production_schedule
    session[:current_prod_schedule] = @production_run.production_schedule
    @info_sticker = "current production schedule is: '" + session[:current_prod_schedule].production_schedule_name + "'"
    flash[:notice] = "current schedule set to: " + session[:current_prod_schedule].production_schedule_name
    control_line @production_run.line_code
  end


  def reconfigure_run
    return if authorise_for_web(program_name?, 'production_run_control')==false
    begin

      id = params[:id]
      if id && @production_run = ProductionRun.find(id)
        @production_run.transaction do
          @production_run.set_status("reconfiguring", session[:user_id])
          @production_run.update
        end
        session[:query] = session[:current_schedule_active_runs_query]
        flash[:notice] = "Run reconfigured (find under editing runs)"
        #render_list_active_runs
        session[:current_production_run] = @production_run
        active_run
      end
    rescue
      handle_error("Production run could not be executed")
    end

  end

  def restore_run
    return if authorise_for_web(program_name?, 'production_run_control')==false
    begin

      id = params[:id]
      if id && @production_run = ProductionRun.find(id)
        @production_run.transaction do

          @production_run.set_status("restored", session[:user_id])
          @production_run.update
        end
        @production_run.production_run_stage = nil
        session[:query] = session[:current_schedule_completed_runs_query]
        flash[:notice] = "Run restored (find under editing runs)"
        render_list_active_runs true
      end
    rescue
      handle_error("Production run could not be executed")
    end

  end

  def clone_production_run
    return if authorise_for_web(program_name?, 'production_run_control')==false

    begin
      @production_run = ProductionRun.find(params[:id])
      if @production_run.production_run_status != "active" && @production_run.production_run_status != "configuring" && @production_run.production_run_status != "reconfiguring" && @production_run.production_run_status != "restored"
        redirect_to_index("Only 'active'or configuring runs can be cloned")
        return
      end

      #------------------------------------------------------------------------------------
      #RULE TO APPLY:
      # any previous runs with same day line batch code as will be calculated for this run
      # must first be closed
      #------------------------------------------------------------------------------------
      #new_batch_code = ProductionRun.get_new_day_batch_code(@production_run.line.id,@production_run.line.line_code)
      #occupying_runs = ProductionRun.get_occupying_batch_codes(new_batch_code)
      #if occupying_runs.length > 0
      #   @freeze_flash = true
      #   occ_str = "THE FOLLOWING RUNS ARE AT LEAST 7 DAYS OLD AND HAVE THE SAME DAY LINE BATCH CODE AS THIS RUN (" + new_batch_code + ")<BR>"
      #   occupying_runs.each do |occ_run|
      #      occ_str += " " + occ_run + "<BR>"
      #   end
      #   occ_str += "YOU MUST FIRST COMPLETE THE ABOVE RUN(S), BEFORE THIS RUN CAN BE EXECUTED"
      #   redirect_to_index(occ_str)
      #   return
      #end

      clone = @production_run.clone_run
      session[:current_closed_schedule] = @production_run.production_schedule
      session[:current_production_run] = clone
      flash[:notice] = "run cloned successfully. Cloned run displayed."
      active_run

    rescue
      handle_error("run could not be cloned successfuly")
    end
  end


#=================
#OLD FUNCTIONALITY
#=================
#def complete_run_submit
# begin
#
#   if params['production_run'][:complete_entire_run]== "1"
#      session[:completing_run].clear_active_devices
#      session[:completing_run].set_status("completed",session[:user_id])
#   else
#      session[:completing_run].complete_current_stage
#      if session[:completing_run].production_run_stage == "completed"
#        session[:completing_run].set_status("completed",session[:user_id])
#      end
#   end
#
#   flash[:notice]= "Completed"
#   current_active_runs
#
# rescue
#   handle_error("Run could not be completed")
# end
#end

  def is_line_open_for_restored_run(run)
    msg = ""
    if run.production_run_stage == "bintipping_only"||run.production_run_stage == "bintipping_plus"
      active_bintip_run = ProductionRun.get_active_bintipping_run_on_line(@production_run.line.id)
      if active_bintip_run
        return "Run: <font color = 'green'>" + active_bintip_run + " </font>is occupying bin tipping. <BR> Only one run at a time can occupy bin tipping. <br>You must complete the bin tipping stage of that run before you can execute(start) this run"
      end
    end

    if run.production_run_stage == "bintipping_plus"||run.production_run_stage == "carton_labeling_plus"

      active_run_code = ProductionRun.get_active_labeling_run_on_line(run.line.id)

      if active_run_code
        msg = "Carton labeling is already occupied by run: <br>" + active_run_code
        msg += "<br> To restore this run, you must first complete"
        msg += "<br> carton labeling on the other run"
        return msg
      end
    end

    return msg
  end

  def complete_run_stage

    run = ProductionRun.find(params[:id])
    #--------------------------------------------------------------------------
    #Make sure that the next stage to be entered is not occupied by another run
    #---------------------------------------------------------------------------
    if run.production_run_stage == "bintipping_only" #any other stage means labeling is already taking place for this run
      active_labeling_run_code = ProductionRun.get_active_labeling_run_on_line(run.line.id)
      if active_labeling_run_code
        flash[:notice] = "Carton labeling is already occupied by run: <br>" + active_labeling_run_code
        flash[:notice] += "<br> To complete bintipping for the selected run, you must complete"
        flash[:notice] += "<br> carton labeling on the other run"
        @freeze_flash = true
        control_line(session[:selected_line_to_control])

        return
      end
    end

    run.transaction do
      run.complete_current_stage
      if run.production_run_stage == "completed"
        run.set_status("completed", session[:user_id], true)
      end
      run.update
    end
    flash[:notice]= "Stage completed"
    control_line(session[:selected_line_to_control])

  end


  def complete_run

    run = ProductionRun.find(params[:id])
    run.transaction do
      run.clear_active_devices
      run.clear_active_carton_links
      run.clear_active_rebin_links
      run.clear_reworks_devices
      run.set_status("completed", session[:user_id], true)
      run.update
      flash[:notice]= "Run completed"
    end
    control_line(session[:selected_line_to_control])

  end


  def execute_production_run_step3
    begin
      if !@production_run
        @production_run = session[:executing_run][:run]
#    if params['shift'] #indicating we got here from shift form post
#
#       custom_start_time = Time.local(params[:shift]['shift_start_time(1i)'],params[:shift]['shift_start_time(2i)'],params[:shift]['shift_start_time(3i)'],params[:shift]['shift_start_time(4i)'])
#       custom_end_time = Time.local(params[:shift]['shift_end_time(1i)'],params[:shift]['shift_end_time(2i)'],params[:shift]['shift_end_time(3i)'],params[:shift]['shift_end_time(4i)'])
#       session[:executing_run][:shift].custom_start_time = custom_start_time.to_formatted_s(:db)
#       session[:executing_run][:shift].custom_end_time = custom_end_time.to_formatted_s(:db)
#
#       session[:executing_run][:shift].shift_type= "C"
#    end

#   @production_run.execute(session[:executing_run][:shift],session[:user_id])
# else
#  @production_run.execute(nil,session[:user_id])
      end

      @production_run.execute(nil, session[:user_id])
      #@production_run.set_status('active',session[:user_id])

      flash[:notice]= "run executed successfully"
      flash[:notice] += "<BR>Shift: #{@shift.shift_code}, foreman is #{@shift.user}" if @shift
      if session[:current_ctl_line_run]
        control_line @production_run.line_code
      else
        params[:id] = nil
        current_schedule_runs
      end
    rescue
      handle_error("Production run execution failed")
    end
  end


  def execute_production_run_step2


    #user wants to define custom shift times
    render :inline => %{
		<% @content_header_caption = "'define custom shift times'"%>

		<%= build_shift_form()%>

		}, :layout => 'content'

  end

#--------------------------------------------------------------------
#This method replaces the 'execute' and 'complete' functions
#It prompts the user to select a production line and then
#builds a 'run control' console, from which
#1) new runs can be started on the line
#2) active runs can be controlled (have their run stages manipulated
#--------------------------------------------------------------------
  def control_line(line_code = nil)
    return if authorise_for_web(program_name?, 'production_run_control')==false

    #show select line form if not shown already
    if params[:line_selection]== nil && line_code == nil
      render :inline => %{
		<% @content_header_caption = "'select line'"%>

		<%= build_select_line_form()%>

		}, :layout => 'content'
      return
    else

      @selected_line_code = line_code||params[:line_selection][:line]
      session[:selected_line_to_control]= @selected_line_code

      if @selected_line_code == nil
        redirect_to_index("no line selected")
        return
      end
    end

    #---------------------------------------------------------------------------------------
    #The 'line control' console needs various pieces of information that should be prepared
    #for it
    #----------------------------------------------------------------------------------
    set_line_control_data
    render :template => "production/runs/control_line", :layout => "content"

  end


#---------------------------------------------------------------------------------
#This method retrieves data needed by the line control console. It is:
#1) a list of all the production_runs active on the line
#2) an indication as to whether the start new run should be active on the console
#---------------------------------------------------------------------------------
  def set_line_control_data

    packhouse = Facility.active_pack_house.facility_code
    @line_id = Line.get_line_for_packhouse_and_line_code(packhouse, @selected_line_code).id
    @runs_on_line = ProductionRun.get_active_runs_for_line(@line_id)
    puts "n runs on line: " + @runs_on_line.length.to_s
  end


  def execute_run_from_ctl_line
    execute_production_run(true)
  end


  def execute_production_run(from_ctl_line = nil)
    return if authorise_for_web(program_name?, 'production_run_control')==false
    begin

      session[:current_ctl_line_run] = nil if !from_ctl_line

      id = params[:id]
      if id && @production_run = ProductionRun.find(id, :include => ["carton_links", "rebin_links"])
        warn_msg = nil
        session[:current_closed_schedule] = @production_run.production_schedule

        if @production_run.carton_links.length == 0 && @production_run.production_run_stage != "rebinning"
          warn_msg = "You have not yet linked any fg codes to carton pack stations"
#     elsif @production_run.rebin_links.length == 0
#      warn_msg = "You have not yet linked any rmt products to binfill stations"

           #validate that active carton links does not exist in active devices
        elsif clashing_pack_stations = @production_run.running_carton_links?
          warn_msg = "Another active run already uses following barcodes: <br> " + clashing_pack_stations.slice(0..300)
        elsif other_child = @production_run.get_active_child_runs()
          warn_msg = "A parent run can only have one active child. First complete (at least set to rebinning) child run: " + other_child

        elsif @production_run.parent_run_code && @production_run.child_run_code
          warn_msg = "A run cannot be both a parent and a child"
        end


        if warn_msg
          flash[:notice]= warn_msg
          if !from_ctl_line
            params[:id] = nil
            current_schedule_runs # same as 'editing runs'
          else
            control_line @production_run.line_code
          end
          return
        else
          if @production_run.production_run_status == "configuring"

            #--------------------------------------------------------------------------
            #RULE TO APPLY HERE:
            #only one run can occupy bintipping.
            #--------------------------------------------------------------------------
            active_bintip_run = ProductionRun.get_active_bintipping_run_on_line(@production_run.line.id)
            if active_bintip_run
              @freeze_flash = true
              redirect_to_index("Run: <font color = 'green'>" + active_bintip_run + " </font>is occupying bin tipping. <BR> Only one run at a time can occupy bin tipping. <br>You must complete the bin tipping stage of that run before you can execute(start) this run")
              return
            end

            #------------------------------------------------------------------------------------
            #RULE TO APPLY:
            # any previous runs with same day line batch code as will be calculated for this run
            # must first be closed
            #------------------------------------------------------------------------------------
            new_batch_code = ProductionRun.get_new_day_batch_code(@production_run.line.id, @production_run.line.line_code)

            occupying_runs = ProductionRun.get_occupying_batch_codes(new_batch_code)
            if occupying_runs.length > 0
              @freeze_flash = true
              occ_str = "THE FOLLOWING RUNS ARE AT LEAST 7 DAYS OLD AND HAVE THE SAME DAY LINE BATCH CODE AS THIS RUN (" + new_batch_code + ")<BR>"
              occupying_runs.each do |occ_run|
                occ_str += " " + occ_run + "<BR>"
              end
              occ_str += "YOU MUST FIRST COMPLETE THE ABOVE RUN(S), BEFORE THIS RUN CAN BE EXECUTED"
              redirect_to_index(occ_str)
              return
            end

            session[:executing_run] = Hash.new
            session[:executing_run][:run]= @production_run

            @shift = Shift.get_shift_details(@production_run.line_code)
            if @shift.class.to_s == "String"
              params[:id] = nil
              session[:alert] = @shift
              current_schedule_runs
              return
            end
            #session[:executing_run][:shift]= shift_details
            #session[:current_ctl_line_run] = @production_run
            #@shift_str = shift_details.shift_code
            execute_production_run_step3
            #          render :inline => %{
            #          <script>
            #            if (confirm("The current shift is: <%= @shift_str %>. Do you want to define a custome shift?"))
            #              window.location.href = "/production/runs/execute_production_run_step2";
            #            else
            #              window.location.href = "/production/runs/execute_production_run_step3";
            #         </script>
            #        }
          else #run is in reconfiguring state
            if @production_run.production_run_status == "restored"
              msg = is_line_open_for_restored_run(@production_run)
              if msg != ""
                redirect_to_index(msg)
                return
              end
            end
            session[:current_ctl_line_run] = @production_run
            execute_production_run_step3
            return
          end

          return
        end

      end
    rescue
      handle_error("Production run could not be executed")
    end
  end


  def view_active_run

    view_run("active_runs")

  end

  def view_completed_run

    view_run("completed_runs")

  end


  def view_run(back_action = nil)

    if !back_action
      back_action = session[:run_view_context] if !back_action
    end

    id = params[:id]
    @back_action = back_action
    session[:run_view_context]= @back_action

    if !id
      @production_run = session[:current_production_run]
    else
      @production_run = ProductionRun.find(id)
    end

    session[:current_production_run] = @production_run
    session[:current_closed_schedule] = session[:current_production_run].production_schedule


    render :inline => %{
		<% @content_header_caption = "'view production_run'"%>

		<%= build_production_run_view(@production_run,nil)%>

		}, :layout => 'content'

  end


  def view_pack_groups
    list_query = "@pack_groups = PackGroup.find_all_by_production_run_id('#{session[:current_production_run].id}',
				:order => 'pack_group_number')"
    session[:query] = list_query
    @pack_groups = eval(session[:query]) if !@pack_groups

    @caption = "list of pack groups for run: {session[:current_production_run].production_run_code}"

    render :inline => %{
      <% grid            = build_pack_groups_grid(@pack_groups,false) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end

  def view_drops_to_counts

    @pack_group = PackGroup.find(params[:id])
    session[:current_pack_group] = @pack_group
    list_query = "@pack_group_outlets = PackGroupOutlet.find_all_by_pack_group_id('#{params[:id]}',
				 :order => 'id')"

    @pack_group_outlets = eval(list_query)

    @caption = "Setup pack group " + session[:current_pack_group].pack_group_number.to_s + "(commodity: " + session[:current_pack_group].commodity_code + ",color percentage: " + session[:current_pack_group].color_sort_percentage.to_s + ", grade: " + session[:current_pack_group].grade_code.to_s

    render :inline => %{
      <% grid            = build_drops_to_counts_grid(@pack_group_outlets,false) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end


  def edit_production_run
    return if authorise_for_web(program_name?, 'production_run_setup')==false
    id = params[:id]
    if id && @production_run = ProductionRun.find(id, :include => "pack_groups")
      session[:current_production_run] = @production_run
      session[:current_closed_schedule] = session[:current_production_run].production_schedule
      render_edit_production_run

    end
  end


  def render_edit_production_run
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit production_run'"%>

		<%= build_production_run_form(@production_run)%>

		}, :layout => 'content'
  end


  def refresh_run
    begin
      session[:current_production_run].refresh_run
      flash[:notice]= "Schedule product update completed"

      active_run
    rescue
      handle_error("production_run refresh failed")
    end

  end

  def update_production_run
    if params[:page]
      session[:production_runs_page] = params['page']
      render_list_production_runs
      return
    end

    @current_page = session[:production_runs_page]
    id = params[:production_run][:id]
    if id && @production_run = ProductionRun.find(id)
      if params['production_run']['treatment_id'] == nil || params['production_run']['treatment_id'] == ""
      else
        params['production_run'][:pc_code_id]= PcCode.find_by_sql("select pc_codes.id from pc_codes join treatments on treatments.pc_code_id=pc_codes.id where treatments.id=#{params['production_run']['treatment_id']} ")[0].id
      end
      if @production_run.update_attributes(params[:production_run])
        @production_runs = eval(session[:query])
        render_list_production_runs
      else
        render_edit_production_run

      end
    end
  end

  def delete_production_run
    return if authorise_for_web('runs', 'production_run_setup')== false
    begin
      if params[:page]
        session[:production_runs_page] = params['page']
        render_list_production_runs
        return
      end
      id = params[:id]
      if id && production_run = ProductionRun.find(id)
        if session[:current_production_run] && session[:current_production_run].id.to_s == id
          session[:current_production_run]= nil
        end
        production_run.destroy
        session[:alert] = " Record deleted."
        @schedule = session[:current_closed_schedule]
        render_list_editing_runs
      end
    rescue
      handle_error("run could not be deleted")
    end
  end

#=============================
#RUN PALLETISING CRITERIA CODE
#=============================

  def get_existing_palletizing_criteria_setup(carton_setup_code, fg_code = nil)
    #--------------------------------------------------------------------------
    #try to find an existing record, if not found create a new one by copying
    #the values from palletising_criteria_setup (defined for a carton setup)
    #--------------------------------------------------------------------------
    #begin
    criteria = RunPalletizingCriterium.find_by_carton_setup_code_and_production_run_id(carton_setup_code, session[:current_production_run].id)
    if !criteria
      puts "No existing criteria"
      criteria = RunPalletizingCriterium.new
      schedule_id = session[:current_production_run].production_schedule.id
      puts "sched id: " + schedule_id.to_s
      puts "carton setup: " + carton_setup_code
      carton_setup_id = CartonSetup.find_by_production_schedule_id_and_carton_setup_code(schedule_id, carton_setup_code)


      carton_setup_criteria = PalletizingCriterium.find_by_carton_setup_id(carton_setup_id)
      #if record does not exist, it means that the criteria have not been overridden for the
      #carton setup, in which case the schedule-based criteria should be used
      if !carton_setup_criteria
        carton_setup_criteria = PalletCriterium.find_by_production_schedule_id(session[:current_closed_schedule].id)
      end
      carton_setup_criteria.export_attributes(criteria)
      criteria.carton_setup = CartonSetup.find(carton_setup_id)
      criteria.carton_setup_code = criteria.carton_setup.carton_setup_code
      criteria.fg_product_code = fg_code if fg_code
      criteria.production_run = session[:current_production_run]
      criteria.create
    else


    end

    return criteria
    #rescue
    # raise "Palletizing criteria could not be fetched for the selected carton setup. Reported exception: " + $!

    #end
  end

  def palletizing_criteria_setup

    session[:palletizing_view]= nil
    render_edit_palletizing_criteria

  end


  def render_edit_palletizing_criteria(run_palletizing_criteria_setup = nil, is_view = nil)
    begin
      @caption_action = "'edit palletizing criteria setup for run'"
      @run_palletizing_criteria_setup = run_palletizing_criteria_setup

      @is_edit = false

      if run_palletizing_criteria_setup && run_palletizing_criteria_setup.carton_setup
        @is_edit = true
        @caption_action = "'edit palletizing setup criteria  for carton setup: " + run_palletizing_criteria_setup.carton_setup.carton_setup_code + "'"

      end

      if is_view||session[:palletizing_view]
        @is_edit = false
        @caption_action = "'view palletizing criteria for individual carton setups'"
        @action = nil
        @caption = ""
      else
        @action = 'update_palletizing_criteria'
        @caption = 'update_palletizing_criteria'
      end

      render :inline => %{
		<% @content_header_caption = @caption_action%>

		<%= build_palletizing_criterium_form(@run_palletizing_criteria_setup,@action,@caption,@is_edit)%>

		}, :layout => 'content'
    rescue
      handle_error("palletizing criteria form could not be rendered")
    end
  end

  def update_palletizing_criteria

    begin
      id = params[:run_palletizing_criteria_setup][:id]

      run_palletizing_criterium = RunPalletizingCriterium.new(params[:run_palletizing_criteria_setup])
      if run_palletizing_criterium.valid? == false
        render_edit_palletizing_criteria(run_palletizing_criterium)
        return
      end

      if !id
        @run_palletizing_criterium = get_existing_palletizing_criteria_setup(params[:run_palletizing_criteria_setup][:carton_setup_code])
      else
        @run_palletizing_criterium = RunPalletizingCriterium.find(id)
      end

      if @run_palletizing_criterium.update_attributes(params[:run_palletizing_criteria_setup])
        flash[:notice] = "palletizing criteria updated successfully"
        active_run
        return
      else
        render_edit_palletizing_criteria
        return
      end

    rescue
      handle_error("palletizing criteria could not be updated for carton setup")
    end
  end


#==============================================
#Production schedules code
#==============================================
  def list_production_schedules

    return if authorise_for_web('runs', 'view') == false

    if session[:runs_schedules]!= nil
      render_list_production_schedules
      return
    end

    list_query = "ProductionSchedule.find_all_by_production_schedule_status_code('closed',
				 :order => 'production_schedule_name')"
    session[:query] = list_query
    session[:runs_schedules]= list_query
    render_list_production_schedules


  end

  def render_list_production_schedules(form_caption = nil)

    @can_create_run = authorise(program_name?, 'production_run_setup', session[:user_id])


    @production_schedules = eval(session[:runs_schedules]) if !@production_schedules


    @caption = "'list of active production_schedules'"
    @caption = form_caption if form_caption != nil
    render :inline => %{
      <% grid            = build_production_schedule_grid(@production_schedules,@can_create_run) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def create_production_run

    @production_run = ProductionRun.new(params[:production_run])
    error =validate_production_run_details_params(@production_run.line_code,params['production_run'])
    if !error.empty?
      flash[:error] = "record cannot be saved: <BR> #{error.join("<BR>")}"
      edit_run_details  and return
    end
    #begin
    session[:commodity_id]=nil
    if params[:page]
      session[:schedules_page] = params['page']
      render_list_production_schedules
      return
    else


      ProductionRun.transaction do
        params['production_run'][:rmt_product_type_id]=RmtProductType.find_by_rmt_product_type_code(session[:current_closed_schedule].rmt_setup.rmt_product.rmt_product_type_code).id
        params['production_run'][:commodity_id]= Commodity.find_by_commodity_code(session[:current_closed_schedule].rmt_setup.commodity_code).id
        params['production_run'][:variety_id]=  RmtVariety.find_by_rmt_variety_code(session[:current_closed_schedule].rmt_setup.variety_code).id
        if params['production_run']['ripe_point_id'] == nil || params['production_run']['ripe_point_id'] == ""
        else
          params['production_run'][:pc_code_id]= PcCode.find_by_sql("select pc_codes.id from pc_codes join ripe_points on ripe_points.pc_code_id=pc_codes.id where ripe_points.id=#{params['production_run']['ripe_point_id']} ")[0].id
        end
        @production_run = ProductionRun.new(params[:production_run])
        @production_run.parent_run_code = nil if @production_run.parent_run_code == ""

        @production_run.production_schedule = session[:current_closed_schedule]
        @production_run.production_schedule_name = session[:current_closed_schedule].production_schedule_name

        #---------------------------------------------------------------------------------------------------------------------------------------------------
        #save child_run attribute on parent (if one is chosen) only if parent does not yet have a child run code (or has one, but has not yet been executed)
        #The child_run attribute will always be stored on parent at the point when run is executed
        #---------------------------------------------------------------------------------------------------------------------------------------------------
        if @production_run.parent_run_code
          parent_run = ProductionRun.find_by_production_run_code(@production_run.parent_run_code)
          parent_run.child_run_code = @production_run.production_run_code if !parent_run.child_run_code ||(parent_run.child_run_code && parent_run.production_run_status == "configuring")
          parent_run.update

        end


        @production_run.production_run_status = "configuring"
        if @production_run.save
          session[:current_production_run]= @production_run
          @production_run.set_status("configuring", session[:user_id])
          flash[:notice] = "new run created successfully"
          render_list_production_schedules
        else
          @is_create_retry = true
          render_new_production_run(session[:current_closed_schedule])
        end
      end
    end
    #rescue
    #handle_error("production run could not be created")
    #end
  end

  def render_new_production_run(schedule)
#	 render (inline) the edit template
    @schedule = schedule
    render :inline => %{
		<% @content_header_caption = "'create new production_run'"%>

		<%= build_new_run_form('create_production_run','create',@schedule,@production_run)%>

		}, :layout => 'content'
  end


#-------------------
#PACK GROUPS CODE
#-------------------
  def current_pack_groups

    if !session[:current_production_run]
      redirect_to_index("You have not yet selected a production run")
    else
      @production_run = session[:current_production_run].reload
      if session[:current_production_run].production_run_status == "configuring"||session[:current_production_run].production_run_status == "reconfiguring"||session[:current_production_run].production_run_status == "restored"
        list_pack_groups
      else
        view_pack_groups
      end

    end

  end


  def list_pack_groups
    return if authorise_for_web('runs', 'production_run_setup') == false
    begin
      if params[:page]!= nil

        session[:pack_groups_page] = params['page']
        render_list_pack_groups

        return
      else
        session[:pack_groups_page] = nil
      end

      list_query = "@pack_groups_pages = Paginator.new self, PackGroup.count(\"production_run_id = '#{session[:current_production_run].id}'\"), @@page_size,@current_page
	 @pack_groups = PackGroup.find_all_by_production_run_id('#{session[:current_production_run].id}',
				 :limit => @pack_groups_pages.items_per_page,
				 :include => 'pack_group_outlets',
				 :order => 'pack_group_number',
				 :offset => @pack_groups_pages.current.offset)"
      session[:query] = list_query
      render_list_pack_groups
    rescue
      handle_error("pack groups could not be listed")
    end

  end


  def edit_drops_to_counts
    id = params[:id]
    @pack_group_outlet = PackGroupOutlet.find(id)

    #validate

    if @pack_group_outlet.outlet1 == "n.a"
      flash[:notice]= " You have not defined any products for this size count value"
      render_list_pack_group_outlets()
      return
    end

    line = @pack_group_outlet.pack_group.production_run.line
    if !line.line_config
      @freeze_flash = true
      flash[:notice]= "The line has not been associated with a line config yet <BR>
                     Use the 'resources' program to do this"
      render_list_pack_group_outlets()
      return
    else
      edit_pack_group_outlet
    end


  end

  def edit_pack_group_outlet
    #return if authorise_for_web(program_name,'production_run_setup')==false
    id = params[:id]
    if id && @pack_group_outlet = PackGroupOutlet.find(id)
      if @pack_group_outlet.size_code
        @size_count = @pack_group_outlet.size_code
      else
        @size_count = @pack_group_outlet.standard_size_count_value.to_s
      end
      render_edit_pack_group_outlet

    end
  end


  def render_edit_pack_group_outlet
#	 render (inline) the edit template
    @run_num = session[:current_production_run].production_run_code
    render :inline => %{
		<% @content_header_caption = "'allocate drops for count " + @size_count + ". Run: " + @run_num + " '"%>

		<%= build_pack_group_outlet_form(@pack_group_outlet,'update_pack_group_outlet','save',true)%>

		}, :layout => 'content'
  end

  def update_pack_group_outlet
    begin
      if params[:page]
        session[:pack_group_outlets_page] = params['page']
        render_list_pack_group_outlets
        return
      end

      @current_page = session[:pack_group_outlets_page]
      id = params[:pack_group_outlet][:id]
      if id && @pack_group_outlet = PackGroupOutlet.find(id)
        if @pack_group_outlet.update_attributes(params[:pack_group_outlet])
          flash[:notice] = "record saved"
          @pack_group_outlets = eval(session[:query])
          render_list_pack_group_outlets
        else
          render_edit_pack_group_outlet

        end
      end
    rescue
      handle_error("Drops could not be set to counts")
    end
  end


  def set_drops_to_counts
    return if authorise_for_web('runs', 'production_run_setup') == false

    if params[:page]!= nil

      session[:pack_group_outlets_page] = params['page']
      render_list_pack_group_outlets

      return
    else
      session[:pack_group_outlets_page] = nil
    end
    @pack_group = PackGroup.find(params[:id])
    session[:current_pack_group] = @pack_group
    list_query = "@pack_group_outlets_pages = Paginator.new self, PackGroupOutlet.count(\"pack_group_id = '#{params[:id]}'\"), 30,@current_page
	 @pack_group_outlets = PackGroupOutlet.find_all_by_pack_group_id('#{params[:id]}',
				 :limit => @pack_group_outlets_pages.items_per_page,
				 :order => 'id',
				 :offset => @pack_group_outlets_pages.current.offset)"
    session[:query] = list_query
    #session[:current_schedule_runs_query]= session[:query]

    render_list_pack_group_outlets


  end

  def render_list_pack_group_outlets()

    @can_edit_run = authorise(program_name?, 'production_run_setup', session[:user_id])

    @current_page = session[:pack_group_outlets_page] if session[:pack_group_outlets_page]

    @current_page = params['page'] if params['page']

    @pack_group_outlets = eval(session[:query]) if !@pack_group_outlets


    @caption = "Setup pack group " + session[:current_pack_group].pack_group_number.to_s + "(commodity: " + session[:current_pack_group].commodity_code + ",color percentage: " + session[:current_pack_group].color_sort_percentage.to_s + ", grade: " + session[:current_pack_group].grade_code.to_s + ")"

    render :inline => %{
      <% grid            = build_drops_to_counts_grid(@pack_group_outlets,@can_edit_run) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@pack_group_outlets_pages) if @pack_group_outlets_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

#=====================
#Bin tip criteria code
#=====================
  def edit_bintip_criteria

    can_edit = authorise('runs', 'production_run_bintip_criteria_setup', session[:user_id].user_name)
    @bintip_criteria_setup = session[:current_production_run].run_bintip_criterium
    @bintip_criteria_setup.treatment_code=true
    @bintip_criteria_setup.commodity_code=true
    @bintip_criteria_setup.variety_code=true
    @bintip_criteria_setup.class_code=true
    @bintip_criteria_setup.pc_code=true
    @bintip_criteria_setup.track_indicator_code=true
    @bintip_criteria_setup.size_code=true
    @bintip_criteria_setup.ripe_point_code=true
    render_edit_bintip_criterium !can_edit
  end

  def view_bintip_criteria
    @bintip_criteria_setup = session[:current_production_run].run_bintip_criterium
    render_edit_bintip_criterium true

  end


  def render_edit_bintip_criterium(is_view = nil)
#	 render (inline) the edit template

    @caption_action = "edit "
    @caption_action = "view " if is_view
    @action = "update_bintip_criterium"
    @action = nil if is_view
    @caption = "update_bintip_criterium"
    @caption = "" if is_view

    render :inline => %{
		<% @content_header_caption = "'edit bintip criteria for schedule: " + session[:current_production_run].production_schedule_name + "  and run: " + session[:current_production_run].production_run_number.to_s + "'"%>

		<%= build_bintip_criterium_form(@bintip_criteria_setup,@action,@caption,true,false,false)%>

		}, :layout => 'content'
  end

  def update_bintip_criterium
    id = params[:bintip_criteria_setup][:id]
    if id && @bintip_criteria_setup = RunBintipCriterium.find(id)
      if @bintip_criteria_setup.update_attributes(params[:bintip_criteria_setup])
        flash[:notice]= "bin tip criteria updated successfully for run"
        active_run
        return
      end
    end
  end

#========================================
#Pack material editing code
#========================================
  def edit_pack_materials
    return if authorise_for_web(program_name?, 'production_run_setup')==false
    begin
      id = params[:id]
      if id && @production_run = ProductionRun.find(id)
        @production_run_pack_material = ProductionRunPackMaterial.new
        @production_run_pack_material.production_run = @production_run
        render_edit_pack_materials
      end
    rescue
      handle_error("pack material edit form could not be rendered")
    end
  end

  def view_pack_materials
    list_query = "@pack_materials = ProductionRunPackMaterial.find_all_by_production_run_id('#{session[:current_production_run].id}',
				:order => 'fg_product_code')"

    @pack_materials = eval(list_query)

    @caption = "list of addition pack material usages for run: #{session[:current_production_run].production_run_code}"

    render :inline => %{
      <% grid            = build_pack_materials_grid(@pack_materials,false) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end

  def view_palletizing_criteria_setup

    session[:palletizing_view]= true
    render_edit_palletizing_criteria nil, true

  end


  def render_edit_pack_materials
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit pack material for production run'"%>

		<%= build_fg_run_pack_materials_form(@production_run_pack_material,'create_production_run_pack_material','save')%>

		}, :layout => 'content'
  end

  def create_production_run_pack_material
    begin


      if  params[:production_run_pack_material][:retail_item_pack_material_code]== "" &&
          params[:production_run_pack_material][:retail_unit_pack_material_code]== "" &&
          params[:production_run_pack_material][:trade_unit_pack_material_code]== "" &&
          params[:production_run_pack_material][:pallet_pack_material_code]== ""

        active_run
        return
      end

      @production_run_pack_material = ProductionRunPackMaterial.new(params[:production_run_pack_material])

      @production_run_pack_material.production_run = session[:current_production_run]

      if @production_run_pack_material.save

        flash[:notice] = "new pack material usage saved"
        active_run
        return
      else
        @is_create_retry = true
        render_edit_pack_materials
      end

    rescue
      handle_error("new pack material usage could not be created")
    end
  end


#======================
#Pack groups code
#======================
  def render_list_pack_groups()

    @can_edit = authorise(program_name?, 'production_run_setup', session[:user_id])

    @current_page = session[:pack_groups_page] if session[:pack_groups_page]

    @current_page = params['page'] if params['page']

    @pack_groups = eval(session[:query]) if !@pack_groups

    @caption = "list of pack groups for schedule: #{session[:current_closed_schedule].production_schedule_name} and run  #{session[:current_production_run].production_run_number}"

    render :inline => %{
      <% grid            = build_pack_groups_grid(@pack_groups,@can_edit) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@pack_groups_pages) if @pack_groups_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

#=====================================================
#FG PRODUCT ALLOCATION CODE: FG
#=====================================================

  def view_fg_products_side_a_allocation

    list_pack_stations "A", true

  end

  def view_fg_products_side_b_allocation

    list_pack_stations "B", true

  end

  def allocate_fg_products
    return if authorise_for_web('runs', 'production_run_setup') == false

    if params[:page]!= nil

      session[:pack_stations_page] = params['page']

    else
      session[:pack_stations_page] = nil
    end

    list_pack_stations

  end

  def allocate_fg_products_side_a
    return if authorise_for_web('runs', 'production_run_setup') == false

    if params[:page]!= nil

      session[:pack_stations_page] = params['page']

    else
      session[:pack_stations_page] = nil
    end

    list_pack_stations "A"

  end

  def allocate_fg_products_side_b
    return if authorise_for_web('runs', 'production_run_setup') == false

    if params[:page]!= nil

      session[:pack_stations_page] = params['page']

    else
      session[:pack_stations_page] = nil
    end

    list_pack_stations "B"

  end

  def list_pack_stations(side_code = nil, is_view = nil)

    session[:current_side]= side_code if side_code

    side_code = session[:current_side] if !side_code

    line_id = session[:current_production_run].line.id
    session[:pack_stations_page]= 0 if !session[:pack_stations_page]

    count = CartonPackStation.count_stations_for_line_and_side(line_id, side_code)

#======================================
#KEEP FOR WHEN WE DECIDE TO NEED PAGING
#==================================================================================================================================================================================================================================================
#     query = "\"SELECT
#           public.carton_pack_stations.station_code,carton_pack_stations.id,
#           public.tables.table_code as table,
#           public.carton_drops.carton_drop_code as drop,
#           public.lines.line_code
#           FROM
#           public.lines
#           INNER JOIN public.line_configs ON (public.lines.line_config_id = public.line_configs.id)
#           INNER JOIN public.carton_drops ON (public.line_configs.id = public.carton_drops.line_config_id)
#           INNER JOIN public.tables ON (public.carton_drops.id = public.tables.carton_drop_id)
#           INNER JOIN public.carton_pack_stations ON (public.tables.id = public.carton_pack_stations.table_id)
#           WHERE
#           (public.lines.id = '#{line_id}' and public.carton_drops.carton_drop_side_code = '#{side_code}') order BY carton_drop_code,table_code,station_code LIMIT " + @@page_size.to_s + " OFFSET " + session[:pack_stations_page].to_s + "\""
#===================================================================================================================================================================================================================================================


    query = "\"SELECT
           public.carton_pack_stations.station_code,carton_pack_stations.id,
           public.tables.table_code as table_code,
           public.drops.drop_code as drop_code,
           public.drops.drop_side_code,
           public.lines.line_code
           FROM
           public.lines
           INNER JOIN public.line_configs ON (public.lines.line_config_id = public.line_configs.id)
           INNER JOIN public.drops ON (public.line_configs.id = public.drops.line_config_id)
           INNER JOIN public.tables ON (public.drops.id = public.tables.drop_id)
           INNER JOIN public.carton_pack_stations ON (public.tables.id = public.carton_pack_stations.table_id)
           WHERE
           (public.lines.id = '#{line_id}') order BY drop_code,table_code,station_code \""

    @list_query = "@pack_stations = CartonPackStation.find_by_sql(" + query + ")"
    session[:query]= @list_query

    #=====================================================================================================
    #	 @list_query = "@pack_stations_pages = Paginator.new self," + count.to_s + ", @@page_size,@current_page
    #	 @pack_stations = CartonPackStation.find_by_sql(" + query + ")"
    #KEEP FOR WHEN WE NEED PAGING HERE=====================================================================
    render_list_pack_stations is_view
    #rescue
    # handle_error("pack stations could not be listed")
    #end

  end

  def view_additional_groups_binfill
    @binfill_station = session[:current_binfill_stations].find { |s| s.id.to_s == params[:id] }
    htm = "<strong><font color = 'green' size = 'larger' >Additional groups for binfill station: " + @binfill_station.binfill_station_code + "</strong></font><br>"
    i = 0
    @binfill_station.additional_groups.each do |group|
      i += 1

      htm += "<font color = 'blue'> additional group " + i.to_s + ": </font><strong>color percentage: </strong>" + group[0].to_s + "<strong>; grade: </strong>" + group[1].to_s + "<br>"
    end
    @info = htm
    flash[:notice]= " CLICK THE INFO ICON TO VIEW ADDITIONAL GROUPS"
    list_binfill_stations

  end

  def view_additional_groups
    @pack_station = session[:current_pack_stations].find { |s| s.id.to_s == params[:id] }
    htm = "<strong><font color = 'green' size = 'larger' >Additional groups for station: " + @pack_station.station_code + "</strong></font><br>"
    i = 0
    @pack_station.additional_groups.each do |group|
      i += 1

      htm += "<font color = 'blue'> additional group " + i.to_s + ": </font><strong>color percentage: </strong>" + group[0].to_s + "<strong>; grade: </strong>" + group[1].to_s + "<br>"
    end
    @info = htm

    @show_info_popup = true
    list_pack_stations
  end

  def render_list_pack_stations(is_view = nil)

    @outlets = PackGroupOutlet.find(:all, :conditions => "pack_group_outlets.production_run_id = '#{session[:current_production_run].id}' and pack_group_outlets.size_code is null",
                                    :include => "pack_group", :order => "pack_group_outlets.id")

    @carton_links = CartonLink.find_all_by_line_code_and_production_run_id(session[:current_production_run].line_code, session[:current_production_run].id)

    CartonPackStation.set_carton_links(@carton_links, session[:current_production_run].id)

    @can_edit = authorise(program_name?, 'production_run_setup', session[:user_id])
    @can_edit = false if is_view

    #CartonPackStation.set_production_run_id(session[:current_production_run].id)
    CartonPackStation.set_outlets(@outlets, session[:current_production_run].id)


    @pack_stations = eval(@list_query) if !@pack_stations
    @pack_stations.each do |station|
      station.set_product_context(session[:current_production_run].id)
    end
    session[:current_pack_stations]= @pack_stations

    @caption = "list of pack stations for line: " + session[:current_production_run].line_code + "(schedule: #{session[:current_closed_schedule].production_schedule_name}, run: #{session[:current_production_run].production_run_number})"

    render :inline => %{
      <% grid            = build_pack_stations_grid(@pack_stations,@can_edit) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def set_fg_product
    return if authorise_for_web(program_name?, 'production_run_setup')==false
    session[:current_pack_station]= nil
    begin

      @pack_station = session[:current_pack_stations].find { |s| s.id.to_s == params[:id] }
      if @pack_station

        if !@pack_station.grade
          flash[:notice]= "You have not allocated any counts to this station (its drop) "
          list_pack_stations
          return
        end

        @pack_station.production_schedule_name = session[:current_closed_schedule].production_schedule_name
        @pack_station.production_run_number = session[:current_production_run].production_run_number

        session[:current_pack_station] = @pack_station

        render_set_fg_product
      else
        raise "pack station with id: " + params[:id].to_s + " could not be found"
      end
    rescue
      handle_error("'set fg product form' could not be rendered")
    end
  end


  def set_rmt_product_for_pack_station
    return if authorise_for_web(program_name?, 'production_run_setup')==false
    session[:current_pack_station]= nil
    begin

      @pack_station = session[:current_pack_stations].find { |s| s.id.to_s == params[:id] }
      if @pack_station

        @pack_station.production_schedule_name = session[:current_closed_schedule].production_schedule_name
        @pack_station.production_run_number = session[:current_production_run].production_run_number

        session[:current_pack_station] = @pack_station

        render :inline => %{
		   <% @content_header_caption = "'allocate rmt product to pack station'"%>

		   <%= build_set_rmt_product_for_pack_station_form(@pack_station,'save_carton_link_for_rmt','save')%>

		}, :layout => 'content'
      else
        raise "pack station with id: " + params[:id].to_s + " could not be found"
      end
    rescue
      handle_error("'set rmt product form' could not be rendered")
    end

  end


  def render_set_fg_product
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'allocate fg product to pack station'"%>

		<%= build_set_fg_product_form(@pack_station,'save_carton_link','save')%>

		}, :layout => 'content'
  end


  def auto_complete_fg_allocation
    return if authorise_for_web(program_name?, 'production_run_control')==false

    if session[:current_production_run].production_run_status == "configuring"||session[:current_production_run].production_run_status == "reconfiguring"||session[:current_production_run].production_run_status == "restored"
      result = session[:current_production_run].auto_complete_fg_allocation
      flash[:notice]= result
    else
      flash[:notice]= "this action can only be done for a run that is not active"
    end

    active_run

  end


  def save_carton_link
    begin

      #-------------------------------------------------------------------------
      #See if a carton link record have already been defined. If so, save the
      #record, else create a new one
      #-------------------------------------------------------------------------
      msg = ""
      link = CartonLink.find_by_production_run_id_and_station_code(session[:current_production_run].id, session[:current_pack_station].station_code)
      if link && link.rebin_setup
        @info = "An rmt product with code: <font color = 'green'>" + link.rmt_product_code + "</font><br>"
        @info += " </font><br>has previously been allocated to this pack station (" + session[:current_pack_station].station_code + ")"
        @info += "<br> THIS RMT PRODUCT ALLOCATION HAS BEEN REMOVED BY THE SYSTEM AND REPLACED BY THE FG PRODUCT ALLOCATION"
        link.rebin_setup = nil
        link.rebin_template = nil
        link.rebin_label_setup = nil
        link.rmt_product_code = nil


        @show_info_popup = true
      end

      fg_code = params[:pack_station][:fg_product_code]


      if fg_code == ""||params[:pack_station][:carton_setup_code].index("select")||params[:pack_station][:carton_setup_code].index("empty")
        link.destroy if link
        list_pack_stations
        return
      end

      if !link
        link = CartonLink.new
        msg = "new fg product link created for station: " + session[:current_pack_station].station_code
      else
        msg = "fg product link updated for station: " + session[:current_pack_station].station_code
      end

      puts "cart setup: " + params[:pack_station][:carton_setup_code]
      carton_setup = CartonSetup.find_by_carton_setup_code_and_production_schedule_code(params[:pack_station][:carton_setup_code], session[:current_production_run].production_schedule_name)


      link.carton_setup = carton_setup
      link.carton_label_setup = carton_setup.carton_label_setup
      link.pallet_label_setup = carton_setup.pallet_label_setup
      link.pallet_template = carton_setup.pallet_template
      link.carton_template = carton_setup.carton_template
      link.production_run = session[:current_production_run]
      link.station_code = session[:current_pack_station].station_code
      link.drop_code = session[:current_pack_station].drop_code
      link.line_code = session[:current_pack_station].line_code
      link.fg_product_code = fg_code
      link.carton_setup_code = link.carton_setup.carton_setup_code
      link.drop_side_code = session[:current_side]

      if link.carton_label_setup == nil||link.pallet_label_setup == nil||link.pallet_template == nil||link.carton_template == nil
        raise "Carton or Pallet label setups is null. (Carton setup code is: " + link.carton_setup_code + ". Carton setup id is: " + link.carton_setup.id.to_s + ")"
      end

      if link.save
        #flash[:notice] = msg
        list_pack_stations
        return
      else
        @pack_station = session[:current_pack_station]
        render_set_fg_product
        return
      end

    rescue
      handle_error("fg product could not be set")
    end
  end

  def save_rebin_link_for_fg
    #begin

    #-------------------------------------------------------------------------
    #See if a rebin link record have already been defined. If so, save the
    #record, else create a new one
    #-------------------------------------------------------------------------
    msg = ""
    link = RebinLink.find_by_production_run_id_and_station_code(session[:current_production_run].id, session[:current_binfill_station].binfill_station_code)
    #if a carton setup has been associated before set it to null and inform user
    if link && link.rebin_setup
      @info = "A rmt product with code: <font color = 'green'>" + link.rmt_product_code + "</font><br>"
      @info += " </font><br>has previously been allocated to this pack station (" + session[:current_binfill_station].binfill_station_code + ")"
      @info += "<br> THIS RMT PRODUCT ALLOCATION HAS BEEN REMOVED BY THE SYSTEM AND REPLACED BY THE FG PRODUCT ALLOCATION"
      link.rebin_setup = nil
      link.rebin_template = nil
      link.rebin_label_setup = nil
      link.rmt_product_code = nil

      @show_info_popup = true
    end

    carton_setup_code = params[:pack_station][:carton_setup_code]

    if carton_setup_code == ""||carton_setup_code == nil
      link.destroy if link
      list_binfill_stations
      return
    end

    if !link
      link = RebinLink.new
      msg = "new rebin link created for fg product "
    else
      msg = "rebin link updated for fg product "
    end

    carton_setup = CartonSetup.find_by_carton_setup_code_and_production_schedule_code(params[:pack_station][:carton_setup_code], session[:current_production_run].production_schedule_name)
    puts "cs code: " + params[:pack_station][:carton_setup_code]
    link.carton_setup = carton_setup
    link.carton_label_setup = carton_setup.carton_label_setup
    link.pallet_label_setup = carton_setup.pallet_label_setup
    link.pallet_template = carton_setup.pallet_template
    link.carton_template = carton_setup.carton_template
    link.production_run = session[:current_production_run]
    link.station_code = session[:current_binfill_station].binfill_station_code
    link.drop_code = session[:current_binfill_station].drop_code
    link.line_code = session[:current_binfill_station].line_code
    link.fg_product_code = params[:pack_station][:fg_product_code]
    link.carton_setup_code = link.carton_setup.carton_setup_code
    link.drop_side_code = session[:current_side]

    if link.save
      #flash[:notice] = msg
      list_binfill_stations
      return
    else
      @pack_station = session[:current_binfill_station]
      raise link.errors.full_messages.to_s
      return
    end

    #rescue
    #handle_error("product could not be set")
    #end
  end

  def save_carton_link_for_rmt
    begin

      #-------------------------------------------------------------------------
      #See if a carton link record have already been defined. If so, save the
      #record, else create a new one
      #-------------------------------------------------------------------------
      msg = ""
      link = CartonLink.find_by_production_run_id_and_station_code(session[:current_production_run].id, session[:current_pack_station].station_code)
      #if a carton setup has been associated before set it to null and inform user
      if link && link.carton_setup
        @info = "A carton setup with code: <font color = 'green'>" + link.carton_setup_code + "</font><br> and fg_code: <font color = 'orange'>" + link.fg_product_code
        @info += " </font><br>has previously been allocated to this pack station (" + session[:current_pack_station].station_code + ")"
        @info += "<br> THIS FG ALLOCATION HAS BEEN REMOVED BY THE SYSTEM AND REPLACED BY THE RMT PRODUCT ALLOCATION"
        link.carton_setup = nil
        link.carton_template = nil
        link.carton_label_setup = nil
        link.fg_product_code = nil
        link.carton_setup_code = nil

        @show_info_popup = true
      end

      rmt_code = params[:pack_station][:rmt_product_code]

      if rmt_code == ""
        link.destroy if link
        list_pack_stations
        return
      end

      if !link
        link = CartonLink.new
        msg = "new carton link created for rmt product "
      else
        msg = "carton link updated for rmt product "
      end

      rebin_setup = RebinSetup.find_by_production_schedule_code_and_rmt_product_code(session[:current_closed_schedule].production_schedule_name, rmt_code)

      link.rebin_label_setup = rebin_setup.rebin_label_setup
      link.rebin_template = rebin_setup.rebin_template
      link.rebin_setup = rebin_setup
      link.production_run = session[:current_production_run]
      link.station_code = session[:current_pack_station].station_code
      link.drop_code = session[:current_pack_station].drop_code
      link.line_code = session[:current_pack_station].line_code
      link.rmt_product_code = rmt_code
      link.drop_side_code = session[:current_side]

      if link.save
        # flash[:notice] = msg
        list_pack_stations
        return
      else
        @pack_station = session[:current_pack_station]
        raise link.errors.full_messages.to_s
        return
      end

    rescue
      handle_error("product could not be set")
    end
  end

#===========================
#RMT PRODUCT ALLOCATION CODE
#===========================

  def view_rmt_products_side_a_allocation

    allocate_rmt_products_side_a true
  end

  def view_rmt_products_side_b_allocation

    allocate_rmt_products_side_b true
  end


  def allocate_rmt_products_side_a(is_view = nil)
    return if authorise_for_web('runs', 'production_run_setup') == false

    if params[:page]!= nil

      session[:pack_stations_page] = params['page']

    else
      session[:pack_stations_page] = nil
    end

    list_binfill_stations "FRONT", is_view

  end

  def allocate_rmt_products_side_b(is_view = nil)
    return if authorise_for_web('runs', 'production_run_setup') == false

    if params[:page]!= nil

      session[:pack_stations_page] = params['page']

    else
      session[:pack_stations_page] = nil
    end

    list_binfill_stations "BACK", is_view

  end

  def list_binfill_stations(side_code = nil, is_view = nil)

    session[:current_side]= side_code if side_code

    side_code = session[:current_side] if !side_code

    line_id = session[:current_production_run].line.id
    session[:pack_stations_page]= 0 if !session[:pack_stations_page]


#======================================
#KEEP FOR WHEN WE DECIDE TO NEED PAGING
#==================================================================================================================================================================================================================================================
#     query = "\"SELECT
#           public.carton_pack_stations.station_code,carton_pack_stations.id,
#           public.tables.table_code as table,
#           public.carton_drops.carton_drop_code as drop,
#           public.lines.line_code
#           FROM
#           public.lines
#           INNER JOIN public.line_configs ON (public.lines.line_config_id = public.line_configs.id)
#           INNER JOIN public.carton_drops ON (public.line_configs.id = public.carton_drops.line_config_id)
#           INNER JOIN public.tables ON (public.carton_drops.id = public.tables.carton_drop_id)
#           INNER JOIN public.carton_pack_stations ON (public.tables.id = public.carton_pack_stations.table_id)
#           WHERE
#           (public.lines.id = '#{line_id}' and public.carton_drops.carton_drop_side_code = '#{side_code}') order BY carton_drop_code,table_code,station_code LIMIT " + @@page_size.to_s + " OFFSET " + session[:pack_stations_page].to_s + "\""
#===================================================================================================================================================================================================================================================


    query = "\"SELECT
           public.binfill_stations.binfill_station_code,binfill_stations.id,
           public.drops.drop_code as drop_code,
           public.lines.line_code
           FROM
           public.lines
           INNER JOIN public.line_configs ON (public.lines.line_config_id = public.line_configs.id)
           INNER JOIN public.drops ON (public.line_configs.id = public.drops.line_config_id)
           INNER JOIN public.binfill_stations ON (public.binfill_stations.drop_id = public.drops.id)
           WHERE
           (public.lines.id = '#{line_id}' and public.drops.drop_side_code = '#{side_code}') order BY drop_code,binfill_station_code \""


    @list_query = "@binfill_stations = BinfillStation.find_by_sql(" + query + ")"

    render_list_binfill_stations is_view
    #rescue
    # handle_error("pack stations could not be listed")
    #end

  end

  def render_list_binfill_stations(is_view = nil)


    @outlets = PackGroupOutlet.find(:all, :conditions => "pack_group_outlets.production_run_id = '#{session[:current_production_run].id}' and pack_group_outlets.size_code is not null",
                                    :include => "pack_group", :order => "pack_group_outlets.id")

    @rebin_links = RebinLink.find_all_by_line_code_and_production_run_id_and_is_sort_station(session[:current_production_run].line_code, session[:current_production_run].id, false)

    BinfillStation.set_rebin_links(@rebin_links, session[:current_production_run].id)
    #BinfillStation.set_production_run_id(session[:current_production_run].id)

    @can_edit = authorise(program_name?, 'production_run_setup', session[:user_id])
    @can_edit = false if is_view

    BinfillStation.set_outlets(@outlets, session[:current_production_run].id)
    @binfill_stations = eval(@list_query) if !@binfill_stations
    @binfill_stations.each do |bin_station|
      bin_station.set_product_context(session[:current_production_run].id)
    end
    session[:current_binfill_stations]= @binfill_stations

    @caption = "list of binfill stations for line: " + session[:current_production_run].line_code + " :side " + session[:current_side] + "(schedule: #{session[:current_closed_schedule].production_schedule_name}, run: #{session[:current_production_run].production_run_number})"

    render :inline => %{
      <% grid            = build_binfill_stations_grid(@binfill_stations,@can_edit) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def set_rmt_product(is_view = nil)
    return if authorise_for_web(program_name?, 'production_run_setup')==false
    session[:current_binfill_station]= nil
    begin

      @binfill_station = session[:current_binfill_stations].find { |s| s.id.to_s == params[:id] }
      if @binfill_station

#	    if !@binfill_station.grade
#	      flash[:notice]= "You have not allocated any counts to this binfill station (its drop) "
#	      list_binfill_stations
#	      return
#	    end
        session[:current_binfill_station] = @binfill_station
        @binfill_station.production_schedule_name = session[:current_closed_schedule].production_schedule_name
        @binfill_station.production_run_number = session[:current_production_run].production_run_number
        @binfill_station.production_run_id = session[:current_production_run].id

        render_set_rmt_product
      else
        raise "binfill station with id: " + params[:id].to_s + " could not be found"
      end
    rescue
      handle_error("'set rmt product form' could not be rendered")
    end
  end

  def set_fg_product_for_binfill_station
    return if authorise_for_web(program_name?, 'production_run_setup')==false
    session[:current_binfill_station]= nil
    #begin

    @pack_station = session[:current_binfill_stations].find { |s| s.id.to_s == params[:id] }
    if @pack_station

      @pack_station.production_schedule_name = session[:current_closed_schedule].production_schedule_name
      @pack_station.production_run_number = session[:current_production_run].production_run_number

      session[:current_binfill_station] = @pack_station

      render :inline => %{
		   <% @content_header_caption = "'allocate fg product to binfill station'"%>

		   <%= build_set_fg_product_for_binfill_station_form(@pack_station,'save_rebin_link_for_fg','save')%>

		}, :layout => 'content'
    else
      raise "pack station with id: " + params[:id].to_s + " could not be found"
    end
    #rescue
    #handle_error("'set fg product form' could not be rendered")
    #end

  end


  def render_set_rmt_product
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'allocate rmt product to binfill station'"%>

		<%= build_set_rmt_product_form(@binfill_station,'save_rebin_link','save')%>

		}, :layout => 'content'
  end

  def save_rebin_link
    #begin

    #-------------------------------------------------------------------------
    #See if a rebin link record have already been defined. If so, save the
    #record, else create a new one
    #-------------------------------------------------------------------------
    msg = ""
    link = RebinLink.find_by_production_run_id_and_station_code(session[:current_production_run].id, session[:current_binfill_station].binfill_station_code)
    rmt_code = params[:binfill_station][:rmt_product_code]
    if rmt_code == ""
      link.destroy if link
      list_binfill_stations
      return
    end

    if link && link.carton_setup
      @info = "An fg product with code: <font color = 'green'>" + link.fg_product_code + "</font><br>"
      @info += " </font><br>has previously been allocated to this pack station (" + session[:current_binfill_station].binfill_station_code + ")"
      @info += "<br> THIS FG PRODUCT ALLOCATION HAS BEEN REMOVED BY THE SYSTEM AND REPLACED BY THE RMT PRODUCT ALLOCATION"
      link.carton_setup = nil
      link.carton_label_setup = nil
      link.pallet_label_setup = nil
      link.pallet_template = nil
      link.carton_template = nil
      link.fg_product_code = nil
      link.carton_setup_code = nil
      @show_info_popup = true
    end

    if !link
      link = RebinLink.new
      msg = "new rebin product link created "
    else
      msg = "rebin product link updated "
    end


    rebin_setup = RebinSetup.find_by_production_schedule_code_and_rmt_product_code(session[:current_closed_schedule].production_schedule_name, rmt_code)

    link.rebin_setup = rebin_setup
    link.rebin_label_setup = rebin_setup.rebin_label_setup
    link.rebin_template = rebin_setup.rebin_template
    link.production_run = session[:current_production_run]
    link.station_code = session[:current_binfill_station].binfill_station_code
    link.drop_code = session[:current_binfill_station].drop_code
    link.line_code = session[:current_binfill_station].line_code
    link.rmt_product_code = rmt_code
    link.drop_side_code = session[:current_side]
    link.is_sort_station = false
    link.save


    flash[:notice] = msg
    list_binfill_stations
    return


    #rescue
    #handle_error("fg product could not be set")
    #end
  end

#=========================
#BINFILL SORT STATION CODE
#=========================

  def view_rmt_products_sorts_allocation
    list_binfill_sort_stations true
  end


  def allocate_rmt_products_sorts
    return if authorise_for_web('runs', 'production_run_setup') == false

    list_binfill_sort_stations

  end

  def list_binfill_sort_stations(is_view = nil)

    line_id = session[:current_production_run].line.id

    query = "\"SELECT
           public.binfill_sort_stations.binfill_sort_station_code,binfill_sort_stations.id,
           public.lines.line_code
           FROM
           public.lines
           INNER JOIN public.line_configs ON (public.lines.line_config_id = public.line_configs.id)
           INNER JOIN public.binfill_sort_stations ON (public.line_configs.id = public.binfill_sort_stations.line_config_id)
           WHERE
           (public.lines.id = '#{line_id}') order BY binfill_sort_station_code \""


    @list_query = "@binfill_sort_stations = BinfillSortStation.find_by_sql(" + query + ")"

    render_list_binfill_sort_stations is_view
    #rescue
    # handle_error("pack stations could not be listed")
    #end

  end

  def render_list_binfill_sort_stations(is_view = nil)

    @rebin_links = RebinLink.find_all_by_line_code_and_production_run_id_and_is_sort_station(session[:current_production_run].line_code, session[:current_production_run].id, true)

    BinfillSortStation.set_rebin_links(@rebin_links, session[:current_production_run].id)


    @can_edit = authorise(program_name?, 'production_run_setup', session[:user_id])
    @can_edit = false if is_view


    @binfill_sort_stations = eval(@list_query) if !@binfill_sort_stations
    @binfill_sort_stations.each do |sort_station|
      sort_station.set_product_context(session[:current_production_run].id)
    end

    session[:current_binfill_sort_stations]= @binfill_sort_stations

    @caption = "list of binfill sort stations for line: " + session[:current_production_run].line_code + "(schedule: #{session[:current_closed_schedule].production_schedule_name} run: #{session[:current_production_run].production_run_number})"

    render :inline => %{
      <% grid            = build_binfill_sort_stations_grid(@binfill_sort_stations,@can_edit) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def set_rmt_product_for_sorter
    return if authorise_for_web(program_name?, 'production_run_setup')==false
    session[:current_binfill_sort_station]= nil
    begin

      @binfill_sort_station = session[:current_binfill_sort_stations].find { |s| s.id.to_s == params[:id] }
      if @binfill_sort_station

        session[:current_binfill_sort_station] = @binfill_sort_station
        @binfill_sort_station.production_schedule_name = session[:current_closed_schedule].production_schedule_name
        @binfill_sort_station.production_run_number = session[:current_production_run].production_run_number
        @binfill_sort_station.production_run_id = session[:current_production_run].id

        render_set_rmt_product_for_sorter
      else
        raise "binfill sort station with id: " + params[:id].to_s + " could not be found"
      end
    rescue
      handle_error("'set rmt product for sorter form' could not be rendered")
    end
  end


  def render_set_rmt_product_for_sorter
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'allocate rmt product to binfill sort station'"%>

		<%= build_set_rmt_product_form_for_sorter(@binfill_sort_station,'save_rebin_link_for_sorter','save')%>

		}, :layout => 'content'
  end

  def save_rebin_link_for_sorter
    begin

      #-------------------------------------------------------------------------
      #See if a rebin link record have already been defined. If so, save the
      #record, else create a new one
      #-------------------------------------------------------------------------
      msg = ""
      link = RebinLink.find_by_production_run_id_and_station_code_and_is_sort_station(session[:current_production_run].id, session[:current_binfill_sort_station].binfill_sort_station_code, true)
      rmt_code = params[:binfill_sort_station][:rmt_product_code]
      if rmt_code == ""
        list_binfill_sort_stations
        return
      end

      if !link
        link = RebinLink.new
        msg = "new rebin product link created "
      else
        msg = "rebin product link updated "
      end

      rebin_setup = RebinSetup.find_by_production_schedule_code_and_rmt_product_code(session[:current_closed_schedule].production_schedule_name, rmt_code)

      link.rebin_setup = rebin_setup
      link.rebin_label_setup = rebin_setup.rebin_label_setup
      link.rebin_template = rebin_setup.rebin_template
      link.production_run = session[:current_production_run]
      link.station_code = session[:current_binfill_sort_station].binfill_sort_station_code
      link.line_code = session[:current_binfill_sort_station].line_code
      link.rmt_product_code = rmt_code
      link.is_sort_station = true
      link.save

      #flash[:notice] = msg
      list_binfill_sort_stations
      return


    rescue
      handle_error("fg product could not be set")
    end
  end

#------------------------------------------------------------------
#Combo change event handler for pack material form: fg code changed
#------------------------------------------------------------------
  def production_run_pack_material_fg_product_code_changed
    fg_code = get_selected_combo_value(params)
    @carton_setup_codes = CartonSetup.find_all_by_production_schedule_id_and_fg_product_code(session[:current_closed_schedule].id, fg_code).map { |c| [c.carton_setup_code, c.id] }
#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('production_run_pack_material','carton_setup_code',@carton_setup_codes)%>

		}
  end

#--------------------------------------
#fg combo changed for carton link form
#--------------------------------------

  def pack_station_fg_product_code_changed
    fg_code = get_selected_combo_value(params)
    @carton_setup_codes = CartonSetup.find_all_by_production_schedule_id_and_fg_product_code_and_active(session[:current_closed_schedule].id, fg_code, true).map { |c| [c.carton_setup_code] }
    @carton_setup_codes.unshift("<empty>")
#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('pack_station','carton_setup_code',@carton_setup_codes)%>
        <%= observe_field('pack_station_carton_setup_code',:update => 'ajax_distributor_cell',:url => {:action => 'carton_setup_combo_changed'},:loading => "show_element('img_pack_station_carton_setup_code');",:complete => session[:pack_station_form][:carton_setup_js])%>

	<script>
		  <%= update_element_function(
        "packing_order_cell", :action => :update,
        :content => "") %>

     <%= update_element_function(
        "extended_fg_code_cell", :action => :update,
        :content => "") %>

     <%= update_element_function(
        "inventory_code_cell", :action => :update,
        :content => "") %>

     <%= update_element_function(
        "target_market_cell", :action => :update,
        :content => "")%>

     <%= update_element_function(
        "marking_cell", :action => :update,
        :content => "")%>

     <%= update_element_function(
        "diameter_cell", :action => :update,
        :content => "")%>

     <%= update_element_function(
        "order_no_cell", :action => :update,
        :content => "")%>

      <%= update_element_function(
        "retailer_sell_by_code_cell", :action => :update,
        :content => "")%>

     <%= update_element_function(
        "palletizing_cell", :action => :update,
        :content => "")%>

   </script>

		}
  end


  def carton_setup_combo_changed


    carton_setup_code = get_selected_combo_value(params)
    @carton_setup = nil

    @carton_setup = CartonSetup.find_by_carton_setup_code_and_production_schedule_code(carton_setup_code, session[:current_production_run].production_schedule_name) if !carton_setup_code.index("empty")||carton_setup_code.strip != ""
    puts @carton_setup.carton_setup_code if @carton_setup

    render :inline => %{


   <script>

     <%pack_order = ""
      if @carton_setup
        packing_order = @carton_setup.sequence_number.to_s
        packing_order = @carton_setup.pack_order if @carton_setup.pack_order
        pack_order = packing_order
      end %>

     <%extended_fg = ""
      if @carton_setup
        extended_fg = @carton_setup.fg_setup.extended_fg_code
      end %>

      <%inventory_code = ""
      if @carton_setup
        inventory_code = @carton_setup.fg_setup.inventory_code
      end %>

       <%target_market = ""
      if @carton_setup
        target_market =  @carton_setup.fg_setup.target_market
      end %>

      <%marking = ""
      if @carton_setup
        marking =  @carton_setup.fg_setup.marking
      end %>

      <%diameter = ""
      if @carton_setup
        diameter =  @carton_setup.fg_setup.diameter
      end %>

      <%sell_by = ""
      if @carton_setup
        sell_by =  @carton_setup.fg_setup.retailer_sell_by_code
      end %>

       <%order_no = ""
      if @carton_setup
        order_no =  @carton_setup.order_number
      end %>

     <%palletizing = ""
      if @carton_setup
         cpp = " "
         cpp = @carton_setup.pallet_setup.no_of_cartons.to_s if @carton_setup.pallet_setup.no_of_cartons
         pfp = ""
         pfp = @carton_setup.pallet_setup.pallet_format_product_code if @carton_setup.pallet_setup.pallet_format_product_code

        palletizing = pfp + ": " +  cpp
      end %>

    <%= update_element_function(
        "packing_order_cell", :action => :update,
        :content => pack_order) %>

     <%= update_element_function(
        "extended_fg_code_cell", :action => :update,
        :content => extended_fg) %>

     <%= update_element_function(
        "inventory_code_cell", :action => :update,
        :content => inventory_code) %>

     <%= update_element_function(
        "target_market_cell", :action => :update,
        :content => target_market)%>

     <%= update_element_function(
        "marking_cell", :action => :update,
        :content => marking)%>

     <%= update_element_function(
        "diameter_cell", :action => :update,
        :content => diameter)%>

     <%= update_element_function(
        "retailer_sell_by_code_cell", :action => :update,
        :content => sell_by)%>

     <%= update_element_function(
        "order_no_cell", :action => :update,
        :content => order_no)%>

    <%= update_element_function(
        "palletizing_cell", :action => :update,
        :content => palletizing)%>

   </script>
  }

  end


#---------------------------
#palletising setup form code
#---------------------------
  def run_palletizing_criteria_setup_fg_product_code_changed
    fg_code = get_selected_combo_value(params)
    session[:run_palletizing_criteria_setup][:fg_code] = fg_code
    puts "fg from fg combo: " + fg_code.to_s

    @carton_setup_codes = CartonSetup.find_all_by_production_schedule_id_and_fg_product_code(session[:current_closed_schedule].id, fg_code).map { |c| [c.carton_setup_code] }
    @carton_setup_codes.unshift("<empty>")
#	render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
		<%= select('run_palletizing_criteria_setup','carton_setup_code',@carton_setup_codes)%>
        <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_run_palletizing_criteria_setup_carton_setup_code'/>
		<%= observe_field('run_palletizing_criteria_setup_carton_setup_code',:update => 'applet_container',:url => {:action => session[:run_palletizing_criteria_setup][:carton_setup_observer][:remote_method]},:loading => "show_element('img_run_palletizing_criteria_setup_carton_setup_code');")%>
		<script>
		<%= update_element_function(
              "target_market_code_cell", :action => :update,
              :content => "") %>

        <%= update_element_function(
              "inventory_code_cell", :action => :update,
              :content => "") %>


        <%= update_element_function(
              "mark_code_cell", :action => :update,
              :content => "") %>


        <%= update_element_function(
              "sell_by_code_cell", :action => :update,
              :content => "") %>

         <%= update_element_function(
              "farm_code_cell", :action => :update,
              :content => "") %>

          <%= update_element_function(
              "units_per_carton_cell", :action => :update,
              :content => "") %>
          </script>
		}


  end

  def run_palletizing_criteria_setup_carton_setup_code_changed

    #---------------------------------------------------------------------------------------------------
    #This method uses the 'get_existing_palletizing_criteria_setup' method which will
    #fetch an existing record or create a new one(palletizing_criteria_setup record)
    #Once the record is fetched, the 'render_edit_palletizing_criteria' method is used
    #to re-generate the form- the contents of which will replace the 'applet_container' cell's contents
    #---------------------------------------------------------------------------------------------------

    carton_setup_code = get_selected_combo_value(params)
    puts "carton setup code: fok" + carton_setup_code.to_s

    if carton_setup_code == ""
      render :inline => %{
		<script> var fgh; </script>}

      return
    end
    fg_code = session[:run_palletizing_criteria_setup][:fg_code]
    puts "fg from carton combo: " + fg_code.to_s
    run_palletizing_criteria_setup = get_existing_palletizing_criteria_setup(carton_setup_code, session[:run_palletizing_criteria_setup][:fg_code])
    render_edit_palletizing_criteria(run_palletizing_criteria_setup)

  end


#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: farm_puc_account_id
#	---------------------------------------------------------------------------------
#def production_run_farm_code_changed
#	farm_code = get_selected_combo_value(params)
#	session[:production_run_form][:farm_code_combo_selection] = farm_code
#	@puc_codes = FarmPucAccount.pucs_for_farm(farm_code)
#    @puc_codes.unshift("<empty>")
##	render (inline) the html to replace the contents of the td that contains the dropdown
#	render :inline => %{
#		<%= select('production_run','puc_code',@puc_codes)%>
#		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_production_run_puc_code'/>
#		<%= observe_field('production_run_puc_code',:update => 'account_code_cell',:url => {:action => session[:production_run_form][:puc_code_observer][:remote_method]},:loading => "show_element('img_production_run_puc_code');",:complete => session[:production_run_form][:puc_code_observer][:on_completed_js])%>
#		}
#
#end

  def production_run_alt_account_changed


    use_alt = get_selected_combo_value(params)== "1"
    if session[:current_production_run]
      @production_run = session[:current_production_run]
      @production_run.use_alternate_account = use_alt

      edit_run_details(@production_run)
    else
      @production_run = ProductionRun.new
      puts "alt: " + use_alt.to_s
      @production_run.use_alternate_account = use_alt
      render_new_production_run(session[:current_closed_schedule])
    end


  end


  def production_run_puc_code_changed

    account_codes = nil
    puc_code = get_selected_combo_value(params)
    schedule = session[:current_closed_schedule]

    if schedule.farm_pack == true
      farm_code = session[:production_run_form][:farm_code_combo_selection]
      farm_code = session[:current_production_run].farm_code if !farm_code && session[:current_production_run].farm_code
      @account_codes = FarmPucAccount.accounts_for_puc_and_farm(puc_code, farm_code)
    elsif schedule.farm_group_code.upcase == "OPEN_SCHEDULE"
      @account_codes = FarmPucAccount.accounts_for_puc(puc_code)
    else
      @account_codes = FarmPucAccount.accounts_for_puc(puc_code)
    end

    render :inline => %{
		<%= select('production_run','account_code',@account_codes)%>

		}

  end

  def ppecb_inspection_level_changed
    #------------------------------------------------------------------------------------------------------------
    #If level is dispensation: change label fields: dispensation_body and dispensation_certificate_number to
    #                          text fields + change passed field to label field
    #If level is not dispensation: change label fields: dispensation_body and dispensation_certificate_number to
    #                          label fields + change passed field to check box + add observer to it
    #------------------------------------------------------------------------------------------------------------

    level = get_selected_combo_value(params)
    @ppecb_inspection = session[:ppecb_inspection]

    if level.upcase == "DISPENSATION"
      render :inline => %{
       <script>
         <%dispensation_body = text_field('ppecb_inspection', 'dispensation_body')%>
          <%= update_element_function(
              "dispensation_body_cell", :action => :update,
              :content => dispensation_body) %>

         <%dispensation_certificate = text_field('ppecb_inspection', 'dispensation_certificate_number')%>
         <%= update_element_function(
           "dispensation_certificate_number_cell", :action => :update,
           :content => dispensation_certificate) %>

         <%= update_element_function(
           "passed_cell", :action => :update,
           :content => @ppecb_inspection.passed.to_s) %>

         <%= update_element_function(
           "reason_cell", :action => :update,
           :content => "NO REASON REQUIRED") %>


       </script>
      }

    else
      render :inline => %{
      <script>
         <%dispensation_body = @ppecb_inspection.dispensation_body.to_s %>
          <%= update_element_function(
            "dispensation_body_cell", :action => :update,
            :content => dispensation_body) %>

         <%dispensation_certificate = @ppecb_inspection.dispensation_certificate_number.to_s %>
         <%= update_element_function(
           "dispensation_certificate_number_cell", :action => :update,
           :content => dispensation_certificate) %>

         <%passed = check_box('ppecb_inspection', 'passed')
          image = "<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_ppecb_inspection_passed'/>" %>
         <%= update_element_function(
           "passed_cell", :action => :update,
          :content => passed + image) %>

     </script>

      <% passed_js = "\n img = document.getElementById('img_ppecb_inspection_passed');"
	        passed_js += "\n if(img != null)img.style.display = 'none';" %>

	        <%= observe_field('ppecb_inspection_passed',:update => 'reason_cell',:url => {:action => 'ppecb_inspection_passed_clicked'},:loading => "show_element('img_ppecb_inspection_passed');",:complete => passed_js)%>
    }

    end


  end


  def production_run_farm_code_changed


    farm_code = get_selected_combo_value(params)
    schedule = session[:current_production_run].production_schedule_name if session[:current_production_run]
    schedule = session[:current_closed_schedule].production_schedule_name if !schedule
    @parent_runs = ProductionRun.find_by_sql("select production_run_code from production_runs where production_schedule_name = '#{schedule}' and production_run_status <> 'completed' and farm_code = '#{farm_code}'").map { |f| f.production_run_code }
    @parent_runs.unshift("<empty>")
    render :inline => %{
    <%= select('production_run','parent_run_code',@parent_runs)%>

		}


  end


  def ppecb_inspection_passed_clicked

    checked = get_selected_combo_value(params)
    passed = checked.class.to_s == "String" && checked === "1"
    puts "PASSED :" + passed.to_s + " and CHECKED : " + checked.to_s

    if !passed
      @reasons = PpecbReason.find(:all).map { |p| [p.reason_description] }
      @reasons.unshift("<empty")
      @ppecb_inspection = PpecbInspection.new()
      #@ppecb_inspection.reason = "<empty>"
      render :inline => %{
       <%= select('ppecb_inspection','reason',@reasons)%>

		}


    else

      render :inline => %{
		NO REASON REQUIRED
		}

    end

  end


##========================================================
## Luks' code for viewing a label for carton_setup =======
##========================================================
  def view_label_for_carton_setup
    params[:id].gsub!("!", "")

    pack_station = session[:current_pack_stations].find { |s| s.id.to_s == params[:id] }
    link = CartonLink.find_by_production_run_id_and_station_code(session[:current_production_run].id, pack_station.station_code)
    carton_setup = CartonSetup.find(link.carton_setup_id)
    puts " carton_setup_id = " + carton_setup.id.to_s
    @carton_label_preview = carton_setup.fg_setup.get_carton_label_preview
    carton_setup.fg_setup.set_label_values_for_run(session[:current_production_run], @carton_label_preview)
    render :template => "/production/carton_setup/carton_label.rhtml", :layout => 'content'
  end

##========================================================


end
