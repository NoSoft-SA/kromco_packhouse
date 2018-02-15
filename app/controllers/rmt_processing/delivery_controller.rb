class RmtProcessing::DeliveryController < ApplicationController

  def program_name?
    "delivery"
  end

#@scope_tester = nil
#@mrl_print_msg = ""

  def bypass_generic_security?
    true
  end


  def weigh_delivery
    return if authorise_for_web(program_name?, 'sample_bin_weighing')== false

    render :inline => %{
		<% @content_header_caption = "'weigh  deliveries'"%>

		<%= build_weigh_sample_bins_form()%>

		}, :layout => 'content'

  end


  def weigh_delivery_submit
    weight = params[:delivery][:weight]
    delivery_num = params[:delivery][:delivery_number]

    raise "no weight" if !weight || weight == ""
    raise "no delivery" if !delivery_num || delivery_num == ""

    delivery = Delivery.find_by_delivery_number(delivery_num)
    raise "delivery not found " if !delivery
    route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id('sample_bin_weigh_completed', delivery.id)

    #raise "Already weighed" if route_step.date_completed

    ActiveRecord::Base.transaction do
      #bins = Bin.find_by_delivery_id(delivery.id)

      Bin.update_all(ActiveRecord::Base.extend_set_sql_with_request("weight = #{weight}", "bins"), "delivery_id = #{delivery.id}")
      route_step.date_activated = Time.now()
      route_step.date_completed = Time.now()
      route_step.update

    end

    redirect_to_index("delivery weights set OK")

  end


  def list_deliveries
#	return if authorise_for_web(program_name?,'read') == false

    if params[:page]!= nil

      session[:deliveries_page] = params['page']

      render_list_deliveries

      return
    else
      session[:deliveries_page] = nil
    end

    list_query = "@deliveries = Delivery.find_by_sql(\"select (select track_slms_indicator_code from deliveries d join delivery_track_indicators t on t.delivery_id=d.id where d.id = od.id and t.track_indicator_type_code='RMI'), od.* from deliveries od order by od.id desc limit 100\")"
    session[:query] = list_query
    render_list_deliveries
  end


  def render_list_deliveries
    @can_edit = authorise(program_name?, 'delivery_edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delivery_delete', session[:user_id])
    @current_page = session[:deliveries_page] if session[:deliveries_page]
    @current_page = params['page'] if params['page']
    @deliveries = eval(session[:query]) if !@deliveries
    render :inline => %{
      <% grid            = build_delivery_grid(@deliveries,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all deliveries' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_deliveries_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_delivery_search_form
  end


  def search_deliveries_hierarchy
    return if authorise_for_web(program_name?, 'read')== false

    @is_flat_search = false
    render_delivery_search_form(true)
  end

  def render_delivery_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  deliveries'"%>

		<%= build_delivery_search_form(nil,'submit_deliveries_search','submit_deliveries_search',@is_flat_search)%>

		}, :layout => 'content'
  end

  def submit_deliveries_search
    if params['page']
      session[:deliveries_page] =params['page']
    else
      session[:deliveries_page] = nil
    end
    @current_page = params['page']
    if params[:page]== nil
      #---------------------
      # added code
      # ---------------------

      puts params[:delivery]['date_from(1i)'].to_s

      farm_code = params[:delivery][:farm_code]
      puc_code = params[:delivery][:puc_code]
      commodity_code = params[:delivery][:commodity_code]
      rmt_variety_code = params[:delivery][:rmt_variety_code]
      season_code = params[:delivery][:season_code]
      date_from = DateTime.civil(params[:delivery]['date_from(1i)'].to_i, params[:delivery]['date_from(2i)'].to_i, params[:delivery]['date_from(3i)'].to_i, params[:delivery]['date_from(4i)'].to_i, params[:delivery]['date_from(5i)'].to_i).strftime("%Y/%m/%d %I:%M%p")
      date_to = DateTime.civil(params[:delivery]['date_to(1i)'].to_i, params[:delivery]['date_to(2i)'].to_i, params[:delivery]['date_to(3i)'].to_i, params[:delivery]['date_to(4i)'].to_i, params[:delivery]['date_to(5i)'].to_i).strftime("%Y/%m/%d %I:%M%p")

      if session[:date_from]!=nil
        session[:date_from]=nil
      end
      if session[:date_to]!=nil
        session[:date_to] = nil
      end

      session[:date_from] = date_from
      session[:date_to] = date_to

      @deliveries = delivery_dynamic_search(farm_code, puc_code, commodity_code, rmt_variety_code, season_code)
      #----------------------
      #end added code
      #----------------------
      #@deliveries = dynamic_search(params[:delivery] ,'deliveries','Delivery')
    else
      @deliveries = eval(session[:query])
    end
    if @deliveries.length == 0
      if params[:page] == nil
        flash[:notice] = 'no records were found for the query'
        @is_flat_search = session[:is_flat_search].to_s
        render_delivery_search_form
      else
        flash[:notice] = 'There are no more records'
        render_list_deliveries
      end

    else

      render_list_deliveries
    end
  end


#=================================================================
#    dynamically search delivery method
#=================================================================

  def delivery_dynamic_search(farm_code, puc_code, commodity_code, rmt_variety_code, season_code)
    @farm_code = nil
    @puc_code = nil
    @commodity_code = nil
    @rmt_variety_code = nil
    @season_code = nil

    if (farm_code.to_s.strip()=="" || farm_code.upcase.index("SELECT A VALUE")!=nil || farm_code==nil || farm_code.to_s == "")
      @farm_code = ""
    else
      @farm_code = farm_code
    end

    if (puc_code.to_s.strip()=="" || puc_code.upcase.index("SELECT A VALUE")!=nil || puc_code==nil || puc_code.to_s == "")
      @puc_code = ""
    else
      @puc_code = puc_code
    end

    if (commodity_code.to_s.strip()=="" || commodity_code.upcase.index("SELECT A VALUE")!=nil || commodity_code==nil || commodity_code.to_s == "")
      @commodity_code = ""
    else
      @commodity_code = commodity_code
    end

    if (rmt_variety_code.to_s.strip()=="" || rmt_variety_code.upcase.index("SELECT A VALUE")!=nil || rmt_variety_code==nil || rmt_variety_code.to_s == "")
      @rmt_variety_code = ""
    else
      @rmt_variety_code = rmt_variety_code
    end

    if (season_code.to_s.strip()=="" || season_code.upcase.index("SELECT A VALUE")!=nil || season_code.to_s == "")
      @season_code = ""
    else
      @season_code = season_code
    end

    conditions = ""

    if @farm_code!=""
      conditions += "farm_code = '#{@farm_code}'"
    end
    if @puc_code!=""
      if conditions!=""
        conditions +=" and puc_code = '#{@puc_code}'"
      else
        conditions += "puc_code = '#{@puc_code}'"
      end
    end
    if @commodity_code!=""
      if conditions!=""
        conditions += " and commodity_code = '#{@commodity_code}'"
      else
        conditions +="commodity_code = '#{@commodity_code}'"
      end
    end
    if @rmt_variety_code!=""
      if conditions!=""
        conditions += " and rmt_variety_code = '#{@rmt_variety_code}'"
      else
        conditions +="rmt_variety_code = '#{@rmt_variety_code}'"
      end
    end
    if @season_code!=""
      if conditions!=""
        conditions += " and season_code = '#{@season_code}'"
      else
        conditions +="season_code = '#{@season_code}'"
      end
    end
    if conditions!=""
      conditions += " and date_delivered > '#{session[:date_from]}' and date_delivered < '#{session[:date_to]}'"
    else
      conditions += "date_delivered > '#{session[:date_from]}' and date_delivered < '#{session[:date_to]}'"
    end

    list_query = '@deliveries = Delivery.find(:all,
              :conditions=>conditions)'

    session[:query] = list_query
    @deliveries = eval(session[:query]) if !@deliveries
    return @deliveries
  end

#=================================================================
#    dynamically search delivery method
#=================================================================

  def delete_delivery
    begin
#    	list_query = "@delivery_pages = Paginator.new self, Delivery.count, @@page_size,@current_page
#	 @deliveries = Delivery.find(:all,
#				 :limit => @delivery_pages.items_per_page,
#				 :offset => @delivery_pages.current.offset)"
#
#      session[:query] = list_query
      if params[:page]
        session[:deliveries_page] = params['page']
        render_list_deliveries
        return
      end
      id = params[:id]
      if id && delivery = Delivery.find(id)
        session[:new_delivery] = delivery
        if (!(error=validate_delivery_deletion))
          delivery.destroy
          session[:alert] = " Record deleted."
          session[:new_delivery] = nil
        else
          flash[:error] = "Cannot delete this delivery, reason: #{error}"
        end
        render_list_deliveries
      end
    rescue #handle_error('record could not be deleted')
      raise $!
    end
  end

  def new_delivery
    return if authorise_for_web(program_name?, 'delivery_new')==false

    @delivery = Delivery.new
    @is_edit = false
    @is_create_retry = false

    render_new_delivery #render :template=>'rmt_processing/delivery/new_delivery.rhtml', :layout=>'content'
  end

  def render_new_uneditable
#  @content_header_caption = "'sorry, you do not permissions to create or edit delivery'"
    @show_print_tripsheet_link = should_show_print_tripsheet_link_for_delivery?(params[:id])
    @show_print_tripsheet_link = authorise(program_name?, 'delivery_print_tripsheet', session[:user_id]) if  @show_print_tripsheet_link
    render :template => 'rmt_processing/delivery/view_uneditable_delivery', :layout => 'content'
  end

  def not_editable_method
    render :inline => %{}, :layout => 'content'
  end

  def validate_spray_prog_for_rmt_variety
    return nil if (!Delivery.do_mrl_test_for_commodity(params[:delivery][:commodity_code]))

    grower_commitment_season = Season.find_by_season_code(params[:delivery][:season_code])
    season = grower_commitment_season.season if (grower_commitment_season)
    grower_commitment_farm = Farm.find_by_farm_code(params[:delivery][:farm_code])
    grower_commitment_record = GrowerCommitment.find_by_sql("select grower_commitments.id as id from grower_commitments join spray_program_results on spray_program_results.grower_commitment_id=grower_commitments.id where grower_commitments.farm_id=#{grower_commitment_farm.id} and grower_commitments.season='#{season.to_s}' and spray_program_results.rmt_variety_code='#{params[:delivery][:rmt_variety_code]}' ") if (grower_commitment_season && grower_commitment_farm)
    spray_program_result = SprayProgramResult.find_by_sql("select * from spray_program_results where grower_commitment_id=#{grower_commitment_record[0].id}").detect { |spr| (spr.rmt_variety_code==params[:delivery][:rmt_variety_code] && spr.spray_result.upcase == 'PASSED' && !spr.cancelled) } if (grower_commitment_record && grower_commitment_record.length > 0)
    if (spray_program_result)
      mrl_results = MrlResult.find_by_sql("select * from mrl_results where spray_program_result_id=#{spray_program_result.id}")
      return "Delivery could not be created. Please add atleast one mrl_result to spray_program: rmt_variety_code[#{params[:delivery][:rmt_variety_code]}],farm[#{params[:delivery][:farm_code]}] and season[#{season.to_s}]" if (mrl_results.length == 0)
      mrl_results.each do |mrl_result|
        if (mrl_result && !mrl_result.cancelled && mrl_result.mrl_result && mrl_result.mrl_result.upcase == "FAILED")
          return "Delivery could not be created. Mrl result[#{mrl_result.sample_no}] has failed"
        end
      end
      return nil
    end
    return "Delivery could not be created. Spray_program: rmt_variety_code[#{params[:delivery][:rmt_variety_code]}],farm[#{params[:delivery][:farm_code]}] and season[#{season.to_s}] has either failed or doesn't exist"
  end

  def valid_delivery?
    if (asset_item = AssetItem.find_by_asset_number(params[:delivery][:pack_material_product_code]))
      location = Location.find_by_location_code(params[:delivery][:farm_code])
      return "loaction[#{params[:delivery][:farm_code].to_s}] does not exist. Please create before using it" if !location
      if (asset_location = AssetLocation.find_by_asset_item_id_and_location_id(asset_item.id, location.id))
        if ((params[:delivery][:quantity_full_bins].to_i + params[:delivery][:quantity_partial_units].to_i + params[:delivery][:quantity_damaged_units].to_i) > asset_location.location_quantity)
          return "the sum of quantity_full_bins,quantity_partial_units,quantity_damaged_units cannot be greater than that of the quantity in asset_location[#{params[:delivery][:farm_code]}] i.e. #{asset_location.location_quantity.to_s}"
        end
      else
        return "asset_location[#{location.location_code}] does not exist for asset_item[#{params[:delivery][:pack_material_product_code]}]"
      end
    else
      return "asset_item[#{params[:delivery][:pack_material_product_code]}] does not exist"
    end
    return nil
  end

  def create_delivery
    begin
      @delivery = Delivery.new(params[:delivery])

      if session[:new_delivery]!=nil
        flash[:error] = "This delivery has been already created!"
        render_existing_new_delivery
      else
        if (errors = validate_spray_prog_for_rmt_variety)
          @is_create_retry = true
          session[:new_delivery] = nil
          @delivery.errors.add_to_base(errors)
          render_new_delivery
          return
        end

        if (params[:delivery][:rmt_product_id] == "")
          @is_create_retry = true
          @delivery.errors.add_to_base("value of field: 'rmt_product_code' cannot be empty")
          render_new_delivery
          return
        end

        if errors = valid_delivery?
          @is_create_retry = true
          session[:new_delivery] = nil
          @delivery.errors.add_to_base(errors)
          render_new_delivery
          return
        end

        @delivery.delivery_number = MesControlFile.next_seq_web(MesControlFile.const_get("INTAKE_DELIVERY_NUMBER"))
        if @delivery.create
          session[:new_delivery] = @delivery

          @delivery_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("delivery_note_captured", session[:new_delivery].id)
          if @delivery_route_step != nil
            @delivery_route_step.update_attributes({:date_activated => DateTime.now.to_formatted_s(:db), :date_completed => DateTime.now.to_formatted_s(:db)})
          end

          puts session[:new_delivery].id.to_s
          puts "++++++++++++++++++++"
          puts session[:delivery_form][:mrl_result_type_combo_selection].to_s
          puts "++++++++++++++++++++"

          #redirect_to_index("'new record created successfully'","'create successful'")
          first_for_farm_season_rmt = Delivery.find_by_sql("select * from deliveries where farm_code='#{@delivery.farm_code}' and season_code='#{@delivery.season_code}' and rmt_variety_code='#{@delivery.rmt_variety_code}'")
          if (first_for_farm_season_rmt.length > 1)
            flash[:notice] = "delivery created"
          else
            session[:alert] = "delivery created. This is the first delivery for #{@delivery.farm_code},#{@delivery.season_code},#{@delivery.rmt_variety_code}\n
                                please print mrl_labels"
            flash[:error] = "delivery created. This is the first delivery for #{@delivery.farm_code},#{@delivery.season_code},#{@delivery.rmt_variety_code}<br>
                                please print mrl_labels"
          end
          #@freeze_flash = true
          add_delivery_track_indicator
        else
          @is_create_retry = true
          session[:new_delivery] = nil
          render_new_delivery
        end
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_delivery
#	 render (inline) the edit template
#	render :inline => %{
#		<% @content_header_caption = "'create new delivery note entry'"%>
#
#		<%= build_delivery_form(@delivery,'create_delivery','create_delivery',false,@is_create_retry)%>
#
#		}, :layout => 'content'
#-----------------------------------------
    session[:delivery_track_indicators] = nil
    session[:delivery_route_steps] = nil
    session[:new_delivery] = nil
    render :template => 'rmt_processing/delivery/new_delivery.rhtml', :layout => 'content'

  end

  def render_existing_new_delivery
    if session[:new_delivery]!=nil
      @delivery = session[:new_delivery]
    else
      @delivery = Delivery.new
    end
    @is_create_retry = false
    @is_edit = true
    render :template => 'rmt_processing/delivery/new_delivery.rhtml', :layout => 'content'
  end

  def edit_delivery
    return if authorise_for_web(program_name?, 'delivery_edit')==false

    session[:new_delivery] = Delivery.find(params[:id]) #if !session[:new_delivery]
    @show_100_fruit_sample_link = should_show_100_fruit_sample_link_for_delivery?(params[:id])
    @show_print_tripsheet_link = should_show_print_tripsheet_link_for_delivery?(params[:id])
    @hundred_fruit_sample_completed = hundred_fruit_sample_completed?(params[:id])
    if !can_edit_delivery?
      @delivery_track_indicators = DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{session[:new_delivery].id}' order by id asc")
      session[:delivery_track_indicators] = @delivery_track_indicators

      @delivery_route_steps = DeliveryRouteStep.find_by_sql("select delivery_route_steps.*,route_steps.sequence_number from delivery_route_steps 	join route_steps on delivery_route_steps.route_step_id=route_steps.id where delivery_id ='#{session[:new_delivery].id}' order by route_steps.sequence_number ASC")
      session[:delivery_route_steps] = @delivery_route_steps
      @delivery = session[:new_delivery]
      @delivery.set_virtual_attributes
      render_new_uneditable
      return
    end
    id = params[:id]
    if id && @delivery = Delivery.find(id)
      #Test for bin scanning
      bin_scanning_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("sample_bin_weigh_completed", id) #??? HANS
      if false# bin_scanning_route_step!=nil && bin_scanning_route_step.date_completed!= nil
        # flash[:error] = "Editing of this delivery is not allowed since bins were scanned"
        # render_list_deliveries
      else

        if session[:new_delivery]!=nil
          session[:new_delivery] = nil
        end
        session[:new_delivery] = @delivery
        if session[:delivery_track_indicators]!=nil
          session[:delivery_track_indicators] = nil
        end
        @delivery_track_indicators = DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{@delivery.id}' order by id asc")
        session[:delivery_track_indicators] = @delivery_track_indicators

        if session[:delivery_route_steps]!=nil
          session[:delivery_route_steps] = nil
        end
        @delivery_route_steps = DeliveryRouteStep.find_by_sql("select delivery_route_steps.*,route_steps.sequence_number from delivery_route_steps 	join route_steps on delivery_route_steps.route_step_id=route_steps.id where delivery_id ='#{id}' order by route_steps.sequence_number ASC")
        session[:delivery_route_steps] = @delivery_route_steps
        @delivery.set_virtual_attributes
        render :template => 'rmt_processing/delivery/update_delivery.rhtml', :layout => 'content'
      end
    end
  end

  def should_show_100_fruit_sample_link_for_delivery?(delivery_id)
    return hundred_fruit_sample_completed?(delivery_id)
  end

  def hundred_fruit_sample_completed?(delivery_id)
    return true if((hundred_fruit_sample_completed_route_step=DeliveryRouteStep.find_by_route_step_code_and_delivery_id("100_fruit_sample_completed", delivery_id)) && hundred_fruit_sample_completed_route_step.date_completed)
    return false
  end

  def should_show_print_tripsheet_link_for_delivery?(delivery_id)
    intake_bin_scan_completed_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("intake_bin_scanning", delivery_id)
    hundred_fruit_sample_completed_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("100_fruit_sample_completed", delivery_id)
#    trip_sheet_printed_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("trip_sheet_printed",delivery_id)

    if(session[:new_delivery].commodity_code=='AP')
      return false if(!session[:new_delivery].rmt_product_id or ((DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{session[:new_delivery].id}'  and (track_indicator_type_code='STA' or track_indicator_type_code='RMI') order by id asc").length < 2)))
    end

    if(session[:new_delivery].commodity_code=='PR')
      return false if(!session[:new_delivery].rmt_product_id or DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{session[:new_delivery].id}' and (track_indicator_type_code='RMI') order by id asc").empty?)
    end

    return true if (hundred_fruit_sample_completed_route_step && intake_bin_scan_completed_route_step && hundred_fruit_sample_completed_route_step.date_completed && intake_bin_scan_completed_route_step.date_completed) #&& !trip_sheet_printed_route_step.date_completed
    return false
  end

  def render_edit_delivery
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit delivery'"%>

		<%= build_delivery_form(@delivery,'update_delivery','update_delivery',true)%>

		}, :layout => 'content'
  end

  def update_delivery
    begin

      if params[:page]
        session[:deliveries_page] = params['page']
        render_list_deliveries
        return
      end

      @current_page = session[:deliveries_page]
      id = params[:delivery][:id]
      if id && @delivery = Delivery.find(id)
        params[:delivery][:season_code] = @delivery.season_code
        params[:delivery][:rmt_variety_code] = @delivery.rmt_variety_code
        #if(!has_valid_spray_prog_for_rmt_variety?)
        # flash[:error] = "Cannot update delivery. The spray program result for this rmt_variety has not been added to grower commitment"
        # render :inline=>%{},:layout=>'content'
        # return
        #end
        #check if commodity, rmt_variety and season_code have been changed
        if session[:delivery_changed_attributes]!= nil
          session[:delivery_changed_attributes] = nil
        end

        session[:delivery_changed_attributes] = Hash.new
        if (params[:delivery][:rmt_product_id] == "")
#              @delivery.errors.add_to_base("value of field: 'rmt_product_code' cannot be empty")
          flash[:error] = "value of field: 'rmt_product_code' cannot be empty"
          params[:id] = @delivery.id
          edit_delivery
          return
        end

        if @delivery.update_attributes(params[:delivery])
          if @delivery.quantity_damaged_units!=nil
            #Test if damaged containers captured route step is already captured
            del_route_step = DeliveryRouteStep.find_by_delivery_id_and_route_step_code(session[:new_delivery].id, "36")
            if del_route_step==nil
              route_step = RouteStep.find_by_route_step_code("36")
              if route_step
                @delivery_route_step = DeliveryRouteStep.new
                @delivery_route_step.delivery_id = session[:new_delivery].id
                @delivery_route_step.route_step_code = route_step.route_step_code
                @delivery_route_step.route_step_id = route_step.id
                @delivery_route_step.delivery_number = session[:new_delivery].delivery_number
                @delivery_route_step.save
              end
            end
          end
#        			@deliveries = eval(session[:query])
          flash[:notice] = 'delivery record updated!'
#        			render_list_deliveries
          params[:id] = @delivery.id
          edit_delivery
          return
        end
#    		 end

      end
    rescue
      if($!.message=='cannot update delivery: intake_bin_scanning in progress')
        flash[:error] = $!.message
        params[:id] = @delivery.id
        edit_delivery
        return
      end
      handle_error('delivery record could not be updated')
    end
  end

  def delivery_update_confirmed
    @update_confirmed = true
    update_delivery_confirmation
  end

  def delivery_update_cancelled
    @update_confirmed = false
    update_delivery_confirmation_cancelled
  end

  def update_delivery_confirmation_cancelled
    if @update_confirmed==false
      id = session[:new_delivery].id
      if id && @delivery = Delivery.find(id)
        #Test for bin scanning
        bin_scanning_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("22", id)
        if false#bin_scanning_route_step!=nil && bin_scanning_route_step.date_completed!= nil
          # flash[:error] = "Editing of this delivery is not allowed since bins were scanned"
          # render_list_deliveries
        else

          if session[:new_delivery]!=nil
            session[:new_delivery] = nil
          end
          session[:new_delivery] = @delivery

          #session[:new_delivery_track_indicator] = nil if session[:new_delivery_track_indicator]!= nil

          if session[:delivery_track_indicators]!=nil
            session[:delivery_track_indicators] = nil
          end
          @delivery_track_indicators = DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{id}' order id asc")
          session[:delivery_track_indicators] = @delivery_track_indicators

          if session[:delivery_route_steps]!=nil
            session[:delivery_route_steps] = nil
          end
          @delivery_route_steps = DeliveryRouteStep.find_by_sql("select delivery_route_steps.*,route_steps.sequence_number from delivery_route_steps 	join route_steps on delivery_route_steps.route_step_id=route_steps.id where delivery_id ='#{id}' order by route_steps.sequence_number ASC")
          session[:delivery_route_steps] = @delivery_route_steps

          @show_100_fruit_sample_link = should_show_100_fruit_sample_link_for_delivery?(@delivery.id)
          render :template => 'rmt_processing/delivery/update_delivery.rhtml', :layout => 'content'
        end
      end
    end
  end

  def update_delivery_confirmation
    return if authorise_for_web(program_name?, 'edit')==false
    begin
      id = session[:new_delivery].id
      if id && @delivery = Delivery.find(id)
        if @update_confirmed
          puts "*************************************"
          date_delivered = session[:delivery_update][:date_delivered] #DateTime.civil(session[:delivery_update]['date_delivered(1i)'].to_i, session[:delivery_update]['date_delivered(2i)'].to_i, session[:delivery_update]['date_delivered(3i)'].to_i).strftime("%Y/%m/%d")
          date_time_picked = session[:delivery_update][:date_time_picked] #date_from = DateTime.civil(session[:delivery_update]['date_time_picked(1i)'].to_i, session[:delivery_update]['date_time_picked(2i)'].to_i, session[:delivery_update]['date_time_picked(3i)'].to_i, session[:delivery_update]['date_time_picked(4i)'].to_i, session[:delivery_update]['date_time_picked(5i)'].to_i).strftime("%Y/%m/%d %I:%M%p")
          puts date_delivered.to_s
          puts date_time_picked.to_s

          puts "***************************************"
          if @delivery.update_attributes(:rmt_product_id => session[:delivery_update][:rmt_product_id], :farm_code => session[:delivery_update][:farm_code], :pick_team => session[:delivery_update][:pick_team], :commodity_code => session[:delivery_update][:commodity_code], :rmt_variety_code => session[:delivery_update][:rmt_variety_code], :season_code => session[:delivery_update][:season_code], :delivery_number_preprinted => session[:delivery_update][:delivery_number_preprinted], :delivery_description => session[:delivery_update][:delivery_description], :truck_registration_number => session[:delivery_update][:truck_registration_number], :pack_material_product_code => session[:delivery_update][:pack_material_product_code], :date_delivered => date_delivered, :date_time_picked => date_time_picked, :quantity_full_bins => session[:delivery_update][:quantity_full_bins], :quantity_partial_units => session[:delivery_update][:quantity_partial_units], :quantity_empty_units => session[:delivery_update][:quantity_empty_units], :quantity_damaged_units => session[:delivery_update][:quantity_damaged_units], :remarks => session[:delivery_update][:remarks], :operator_override => nil, :date_override => nil) #, :orchard_preprinted=>session[:delivery_update][:orchard_preprinted]
            @delivery_track_indicator = DeliveryTrackIndicator.find_by_track_indicator_type_code_and_delivery_id("LOB", id)
            if @delivery_track_indicator!=nil
              @delivery_track_indicator.destroy
            end

            if @delivery.quantity_damaged_units!=nil
              #Test if damaged containers captured route step is already captured
              del_route_step = DeliveryRouteStep.find_by_delivery_id_and_route_step_code(session[:new_delivery].id, "36")
              if del_route_step==nil
                route_step = RouteStep.find_by_route_step_code("36")
                if route_step
                  @delivery_route_step = DeliveryRouteStep.new
                  @delivery_route_step.delivery_id = session[:new_delivery].id
                  @delivery_route_step.route_step_code = route_step.route_step_code
                  @delivery_route_step.route_step_id = route_step.id
                  @delivery_route_step.delivery_number = session[:new_delivery].delivery_number
                  @delivery_route_step.save
                end
              end
            end
#                    @deliveries = eval(session[:query])
            @deliveries = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
            flash[:notice] = 'delivery record updated!'
            list_deliveries
          end
        else
#                @deliveries = eval(session[:query])
          @deliveries = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
          flash[:error] = "delivery record could not be updated"
          list_deliveries
        end
      end
    rescue
      handle_error("delivery record could not be updated")
    end
  end


  def farm_code_changed
    farm_code = get_selected_combo_value(params)
    session[:delivery_form][:farm_code_combo_selection] = farm_code
    farm = Farm.find_by_farm_code(farm_code)
    if (farm != nil)
      puc_code = farm.remark1_ptlocation
      @puc = ""
      @puc = puc_code

      session[:delivery_form][:puc_code] = puc_code
    else
      @puc = ""
    end

    #MM102014 - add  orchard id
    @orchard_id = ["select a value from commodity_code and rmt_variety_code"]

    #	render (inline) the html to replace the contents of the td that contains the label field
    render :inline => %{
            <%= @puc_content = @puc %>
            <%= @orchard_id_content = select('delivery','orchard_id',@orchard_id,{:sorted=>true}) %>
            <script>
                <%= update_element_function("puc_code_cell", :action => :update,:content => @puc_content) %>
                <%= update_element_function("orchard_id_cell", :action => :update,:content => @orchard_id_content) %>
            </script>
        }
  end

  def rmt_product_type_code_combo_changed
    rmt_product_type_code = get_selected_combo_value(params)
    session[:delivery_form][:rmt_product_type_code_combo_selection] = rmt_product_type_code

    if authorise(program_name?, 'choose_rmt_product_code', session[:user_id])
      @rmt_product_codes = RmtProduct.find_by_sql("select rmt_product_code,id from rmt_products where variety_code='#{session[:delivery_form][:rmt_variety_code_combo_selection]}' and commodity_code='#{session[:delivery_form][:commodity_code_combo_selection]}' and rmt_product_type_code='#{session[:delivery_form][:rmt_product_type_code_combo_selection]}' ORDER BY rmt_product_code").map { |g| [g.rmt_product_code, g.id] }
    else
      @rmt_product_codes = ["<empty>"]
    end

    if ((session[:delivery_form][:ripe_point_code_combo_selection] && session[:delivery_form][:ripe_point_code_combo_selection] != "") && (session[:delivery_form][:treatment_code_combo_selection] && session[:delivery_form][:treatment_code_combo_selection] != "") && (session[:delivery_form][:ripe_point_code_combo_selection] && session[:delivery_form][:ripe_point_code_combo_selection] != ""))
      more_conditions = ""
      #sql = "select * from rmt_products where size_code = 'UNS' and product_class_code = 'OR' and ripe_point_code='#{session[:delivery_form][:ripe_point_code_combo_selection].to_s}' and treatment_code='#{session[:delivery_form][:treatment_code_combo_selection]}' and commodity_code='#{session[:delivery_form][:commodity_code_combo_selection]}' and variety_code='#{rmt_variety_code}' #{more_conditions}"
      sql = "select * from rmt_products where size_code = 'UNS' and product_class_code = 'OR' and ripe_point_code='#{session[:delivery_form][:ripe_point_code_combo_selection].to_s}' and treatment_code='#{session[:delivery_form][:treatment_code_combo_selection]}' and commodity_code='#{session[:delivery_form][:commodity_code_combo_selection]}' and variety_code='#{session[:delivery_form][:rmt_variety_code_combo_selection]}' and rmt_product_type_code='#{session[:delivery_form][:rmt_product_type_code_combo_selection]}' #{more_conditions}"
      puts "1. Search by = #{sql}"
      @advised_rmt_product_code = RmtProduct.find_by_sql(sql).map { |g| [g.rmt_product_code, g.id] }[0]
      @content = @advised_rmt_product_code[0] if (@advised_rmt_product_code && @advised_rmt_product_code.length > 0)
    end

    if (@advised_rmt_product_code)
      @rmt_product_codes.unshift(@advised_rmt_product_code)
    else
      @rmt_product_codes.unshift("<empty>")
    end

    render :inline => %{
                    <%= select('delivery', 'rmt_product_id', @rmt_product_codes,{:sorted=>true}) %>
                    <script>
                      <%= update_element_function(
                          "advised_rmt_product_code_cell", :action=>:update,
                          :content=>@content.to_s
                      )
                      %>
                    </script>
                    }
  end

  def commodity_code_changed
    commodity_code = get_selected_combo_value(params)
    session[:delivery_form][:commodity_code_combo_selection] = commodity_code
    @rmt_variety_codes = RmtVariety.find_by_sql("select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}' ORDER BY rmt_variety_code ASC").map { |g| [g.rmt_variety_code] }
    @rmt_variety_codes.unshift("<empty>")

    @season_codes = Season.find_all_by_commodity_code(commodity_code).map { |d| d.season_code }
    season = Season.find_by_sql("select seasons.season_code from seasons where seasons.commodity_code='#{commodity_code}' and (now() between seasons.start_date and seasons.end_date)")[0]
    if (season)
      @season_codes.unshift(season.season_code) if (season)
    else
      @season_codes.unshift("<empty>")
    end
    @rmt_product_ids = ['select a value from rmt_variety_code and rmt_product_type_code']

    #MM102014 - add  orchard id
    @orchard_id = ["select a value from rmt_variety_code"]

    #render inline to replace the contents of the td that contains the dropdown

    render :inline => %{
          <%= select('delivery', 'rmt_variety_code', @rmt_variety_codes,{:sorted=>true}) %>
          <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_delivery_rmt_variety_code'/>
          <%= observe_field('delivery_rmt_variety_code',:update => 'orchard_id_cell',:url => {:action => session[:delivery_form][:rmt_variety_code_observer][:remote_method]},:loading => "show_element('img_delivery_rmt_variety_code');",:complete => session[:delivery_form][:rmt_variety_code_observer][:on_completed_js])%>

          <% @content = select('delivery', 'season_code', @season_codes,{:sorted=>true})
             @orchard_id_content = select('delivery','orchard_id',@orchard_id)
             @rmt_product_id_content = select('delivery', 'rmt_product_id', @rmt_product_ids)
          %>
          <script>
              <%= update_element_function("season_code_cell", :action=>:update,:content=>@content) %>

              <%= update_element_function("orchard_id_cell", :action => :update,:content => @orchard_id_content) %>

              <%= update_element_function("rmt_product_id_cell", :action=>:update,:content=>@rmt_product_id_content) %>
          </script>
    }

  end

  def rmt_variety_code_changed
    rmt_variety_code = get_selected_combo_value(params)
    session[:delivery_form][:rmt_variety_code_combo_selection] = rmt_variety_code

    #MM102014 - add  orchard id
    farm_code = session[:delivery_form][:farm_code_combo_selection]
    puc_code = session[:delivery_form][:puc_code]
    commodity_code = session[:delivery_form][:commodity_code_combo_selection]
    @orchard_id = Orchard.find_by_sql("select distinct orchards.id,orchards.orchard_code,orchards.orchard_description from orchards
                                      inner join rmt_varieties on orchards.orchard_rmt_variety_id = rmt_varieties.id
                                      inner join commodities on rmt_varieties.commodity_id = commodities.id
                                      inner join farms on orchards.farm_id = farms.id
                                      where (parent_orchard_id is not null) and (farm_code = '#{farm_code}' and rmt_varieties.commodity_code = '#{commodity_code}' and rmt_varieties.rmt_variety_code = '#{rmt_variety_code}')").map{|g|["#{g.orchard_code} - #{g.orchard_description}", g.id]}
    @orchard_id.unshift(["<empty>", nil]) #if !@orchard_id.empty?

    # render :inline => %{
		#     <%= @orchard_id_content = select('delivery','orchard_id',@orchard_id,{:sorted=>true})
     #    %>
     #    <script>
     #      <%= update_element_function("orchard_id_cell", :action => :update,:content => @orchard_id_content) %>
     #    </script>
		# }

    render :inline => %{
        <%= select('delivery','orchard_id',@orchard_id,{:sorted=>true}) %>
        <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_delivery_orchard_id'/>
        <%= observe_field('delivery_orchard_id',:update => 'orchard_description_cell',:url => {:action => session[:delivery_form][:orchard_id_observer][:remote_method]},:loading => "show_element('img_delivery_orchard_id');",:complete => session[:delivery_form][:orchard_id_observer][:on_completed_js])%>
		}

    #if authorise(program_name?, 'choose_rmt_product_code', session[:user_id])
    #  @rmt_product_codes = RmtProduct.find_by_sql("select rmt_product_code,id from rmt_products where variety_code='#{session[:delivery_form][:rmt_variety_code_combo_selection]}' and commodity_code='#{session[:delivery_form][:commodity_code_combo_selection]}' and rmt_product_type_code='orchard_run' ORDER BY rmt_product_code").map { |g| [g.rmt_product_code, g.id] }
    #else
    #  @rmt_product_codes = ["<empty>"]
    #end
    #
    #if ((session[:delivery_form][:ripe_point_code_combo_selection] && session[:delivery_form][:ripe_point_code_combo_selection] != "") && (session[:delivery_form][:treatment_code_combo_selection] && session[:delivery_form][:treatment_code_combo_selection] != "") && (session[:delivery_form][:ripe_point_code_combo_selection] && session[:delivery_form][:ripe_point_code_combo_selection] != ""))
    #  more_conditions = ""
    #  sql = "select * from rmt_products where size_code = 'UNS' and product_class_code = 'OR' and ripe_point_code='#{session[:delivery_form][:ripe_point_code_combo_selection].to_s}' and treatment_code='#{session[:delivery_form][:treatment_code_combo_selection]}' and commodity_code='#{session[:delivery_form][:commodity_code_combo_selection]}' and variety_code='#{rmt_variety_code}' #{more_conditions}"
    #  puts "1. Search by = #{sql}"
    #  @advised_rmt_product_code = RmtProduct.find_by_sql(sql).map { |g| [g.rmt_product_code, g.id] }[0]
    #  @content = @advised_rmt_product_code[0] if (@advised_rmt_product_code && @advised_rmt_product_code.length > 0)
    #end
    #
    #if (@advised_rmt_product_code)
    #  @rmt_product_codes.unshift(@advised_rmt_product_code)
    #else
    #  @rmt_product_codes.unshift("<empty>")
    #end
    #
    #render :inline => %{
    #                <%= select('delivery', 'rmt_product_id', @rmt_product_codes,{:sorted=>true}) %>
    #                <script>
    #                  <%= update_element_function(
    #                      "advised_rmt_product_code_cell", :action=>:update,
    #                      :content=>@content.to_s
    #                  )
    #                  %>
    #                </script>
    #                }

  end

  def orchard_id_changed
    orchard_id = get_selected_combo_value(params)
    session[:delivery_form][:orchard_id_combo_selection] = orchard_id
    @orchard_description = ""
    @orchard_group_code = ""

    if(orchard_id)
      orchard = Orchard.find(orchard_id)
      @representative_orchard = orchard.representative_orchard ? orchard.representative_orchard.orchard_code : ""
      @orchard_description = orchard.orchard_description
      session[:delivery_form][:orchard_description] = @orchard_description
    end

    @rmt_product_codes = ["select a value from rmt_product_type_code above"]

    render :inline => %{
            <%= @orchard_description_content = @orchard_description %>
            <%= @rmt_product_codes_content = select('delivery','rmt_product_id',@rmt_product_codes,{:sorted=>true})%>
            <script>
                <%= update_element_function("orchard_description_cell", :action => :update,:content => @orchard_description_content) %>
                <%= update_element_function("representative_orchard_cell", :action => :update,:content => @representative_orchard) %>
                <%= update_element_function("advised_rmt_product_code_cell", :action => :update,:content => @rmt_product_codes_content) %>
            </script>
        }

  end

  def mrl_result_type_changed
    mrl_result_type = get_selected_combo_value(params)
    session[:delivery_form][:mrl_result_type_combo_selection] = mrl_result_type
    render :inline => %{}
  end

#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(deliveries)
#	-----------------------------------------------------------------------------------------------------------
  def delivery_farm_code_search_combo_changed
    farm_code = get_selected_combo_value(params)
    session[:delivery_search_form][:farm_code_combo_selection] = farm_code
    @puc_codes = Delivery.find_by_sql("select distinct puc_code from deliveries where farm_code = '#{farm_code}'").map { |g| [g.puc_code] }
    @puc_codes.unshift("<empty>")
    #render inline to replace the values of puc code dropdown
    render :inline => %{
            <%= select('delivery','puc_code', @puc_codes) %>
            <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_delivery_puc_code'/>
            <%= observe_field('delivery_puc_code', :update=>'commodity_code_cell', :url => {:action=>session[:delivery_search_form][:puc_code_observer][:remote_method]}, :loading=>"show_element('img_delivery_puc_code');", :complete=>session[:delivery_search_form][:puc_code_observer][:on_completed_js])%>
          }
  end

  def delivery_puc_code_search_combo_changed
    puc_code = get_selected_combo_value(params)
    session[:delivery_search_form][:puc_code_combo_selection] = puc_code
    farm_code = session[:delivery_search_form][:farm_code_combo_selection]
    @commodity_codes = Delivery.find_by_sql("select distinct commodity_code from deliveries where farm_code = '#{farm_code}' and puc_code = '#{puc_code}'").map { |g| [g.commodity_code] }
    @commodity_codes.unshift("<empty>")
    #render inline to replace the values of commodity code dropdown
    render :inline => %{
        <%= select('delivery','commodity_code',@commodity_codes) %>
        <img src='/images/spinner.gif' style='display:none;' id = 'img_delivery_commodity_code'/>
        <%= observe_field('delivery_commodity_code', :update=>'rmt_variety_code_cell', :url=>{:action=>session[:delivery_search_form][:commodity_code_observer][:remote_method]}, :loading=>"show_element('img_delivery_commodity_code');", :complete=>session[:delivery_search_form][:commodity_code_observer][:on_completed_js]) %>
       }
  end

  def delivery_commodity_code_search_combo_changed
    commodity_code = get_selected_combo_value(params)
    session[:delivery_search_form][:commodity_code_combo_selection] = commodity_code
    farm_code = session[:delivery_search_form][:farm_code_combo_selection]
    puc_code = session[:delivery_search_form][:puc_code_combo_selection]
    @rmt_variety_codes = Delivery.find_by_sql("select distinct rmt_variety_code from deliveries where farm_code = '#{farm_code}' and puc_code = '#{puc_code}' and commodity_code = '#{commodity_code}'").map { |g| [g.rmt_variety_code] }
    @rmt_variety_codes.unshift("<empty>")
    #render inline to replace the values of rmt variety code dropdown
    render :inline => %{
        <%= select('delivery','rmt_variety_code',@rmt_variety_codes) %>
        <img src='/images/spinner.gif' style='display:none;' id='img_delivery_rmt_variety_code'/>
        <%= observe_field('delivery_rmt_variety_code', :update=>'season_code_cell', :url=>{:action=>session[:delivery_search_form][:rmt_variety_code_observer][:remote_method]}, :loading=>"show_element('img_delivery_rmt_variety_code');", :complete=>session[:delivery_search_form][:rmt_variety_code_observer][:on_completed_js]) %>
      }
  end

  def delivery_rmt_variety_code_search_combo_changed
    rmt_variety_code = get_selected_combo_value(params)
    session[:delivery_search_form][:rmt_variety_code_combo_selection] = rmt_variety_code
    farm_code = session[:delivery_search_form][:farm_code_combo_selection]
    puc_code = session[:delivery_search_form][:puc_code_combo_selection]
    commodity_code = session[:delivery_search_form][:commodity_code_combo_selection]
    #date_from = params[:delivery][:date_delivered_from].to_formatted_s(:db)
    #date_to = params[:delivery][:date_delivered_to].to_formatted_s(:db)

    @orchard_id = Orchard.find_by_sql("select distinct orchards.id,orchards.orchard_code,orchards.orchard_description from orchards
                                      inner join rmt_varieties on orchards.orchard_rmt_variety_id = rmt_varieties.id
                                      inner join commodities on rmt_varieties.commodity_id = commodities.id
                                      inner join farm_puc_accounts on orchards.farm_id = farm_puc_accounts.farm_id
                                      where farm_code = '#{farm_code}' and puc_code = '#{puc_code}' and rmt_varieties.commodity_code = '#{commodity_code}' and rmt_varieties.rmt_variety_code = '#{rmt_variety_code}'").map{|g|["#{g.orchard_code} - #{g.orchard_description}", g.id]}
    @orchard_id.unshift("<empty>")

    @season_codes = Delivery.find_by_sql("select distinct season_code from deliveries where farm_code = '#{farm_code}' and puc_code = '#{puc_code}' and commodity_code = '#{commodity_code}' and rmt_variety_code = '#{rmt_variety_code}'").map { |g| [g.season_code] }
    @season_codes.unshift("<empty>")
    #render inline to replace the values of season code dropdown
    render :inline => %{
            <%= select('delivery','season_code',@season_codes) %>
        }
  end

#=============================================================================================================
#   Add Delivery_Track_Indicator code
#=============================================================================================================
  def set_is_first_time
    if (session[:new_delivery].delivery_track_indicators.length == 0)
      @is_first_time = true
    else
      @is_first_time = false
    end
  end

  def is_second_one?
    if (session[:new_delivery].delivery_track_indicators.length == 1)
      return true
    end
    return false
  end

  def is_third_one?
    if (session[:new_delivery].delivery_track_indicators.length == 2)
      return true
    end
    return false
  end

  def summarise_pressure_readings
    pressure_readings = ActiveRecord::Base.connection.select_all("
        SELECT deliveries.id as delivery_id,qc_result_measurements.sample_no,avg(cast(qc_result_measurements.measurement as numeric)) avg_kg
        FROM deliveries
        INNER JOIN public.qc_inspections ON (deliveries.id = public.qc_inspections.business_object_id)
        INNER JOIN public.qc_inspection_types ON (public.qc_inspections.qc_inspection_type_id = public.qc_inspection_types.id)
        INNER JOIN public.qc_inspection_tests ON (public.qc_inspection_tests.qc_inspection_id = public.qc_inspections.id)
        INNER JOIN public.qc_results ON (public.qc_results.qc_inspection_test_id = public.qc_inspection_tests.id)
        INNER JOIN public.qc_result_measurements ON (public.qc_result_measurements.qc_result_id = public.qc_results.id)
        inner join seasons on seasons.id = deliveries.season_id
        where qc_inspection_type_code = 'QTYFS'
        and qc_measurement_code like 'PRESS%'
        and qc_result_measurements.measurement is not null and deliveries.id = #{session[:new_delivery].id}
        group by deliveries.id,qc_result_measurements.sample_no
        limit 30
      ")

    if(pressure_readings.length != 30)
      raise "There needs to be 30 pressure readings.#{pressure_readings.length} have been captured for this delivery"
    end

    if(!(groups = QcPressureStandard.find(:all, :select=>"qc_pressure_standards.*,i.track_slms_indicator_code", :conditions => "qc_pressure_standards.rmt_variety_code='#{session[:new_delivery].rmt_variety_code}' ",
                                     :joins => "join track_slms_indicators i on i.id=qc_pressure_standards.track_slms_indictor_id",
                                     :order => "track_slms_indicator_code asc")).empty?)
      grp1 = pressure_readings.find_all{|p| p['avg_kg'] >= groups[0].min_value && p['avg_kg'] <= groups[0].max_value}
      grp2 = pressure_readings.find_all{|p| p['avg_kg'] >= groups[1].min_value && p['avg_kg'] <= groups[1].max_value}
      grp3 = pressure_readings.find_all{|p| p['avg_kg'] >= groups[2].min_value && p['avg_kg'] <= groups[2].max_value}
      grp4 = pressure_readings.find_all{|p| p['avg_kg'] >= groups[3].min_value && p['avg_kg'] <= groups[3].max_value}
      grp5 = pressure_readings.find_all{|p| p['avg_kg'] >= groups[4].min_value && p['avg_kg'] <= groups[4].max_value}
    else
      raise "qc_pressure_standards have not been setup for rmt_variety_code[#{session[:new_delivery].rmt_variety_code}]"
    end

    return [grp1.length,grp2.length,grp3.length,grp4.length,grp5.length]
  end

  def add_delivery_track_indicator
    set_is_first_time
    @delivery_track_indicator = DeliveryTrackIndicator.new

    if (session[:new_delivery].delivery_track_indicators.length == 1 && session[:new_delivery].commodity_code=="AP")
      @second_track_indicator = true
      ripeness_groups = TrackSlmsIndicator.find(:all, :conditions => "variety_code='#{session[:new_delivery].rmt_variety_code}' and track_indicator_type_code='STA'")
      if(!(starch_summary_results = StarchSummaryResult.find_by_delivery_id(session[:new_delivery].id)))
        flash[:error] = "Starch Summary Results must be captured first before creating a starch indicator"
        current_delivery
        return
      end
      opt_cat_count = 0
      pre_opt_cat_count = 0
      post_opt_cat_count = 0

      @starch_summary_results_label = "starch summary results<br>"
      if(opt = ripeness_groups.find{|t| t.sub_type=="OPT"})
        opt.config_data.split(",").each do |o|
          opt_cat_count += eval("starch_summary_results.cat#{o}_value").to_i
        end
      else
        ripeness_groups_error = "There is no OPT starch track indicator set up for variety(#{session[:new_delivery].rmt_variety_code})"
      end

      if(pre_opt = ripeness_groups.find{|t| t.sub_type=="PRE_OPT"})
        pre_opt.config_data.split(",").each do |p|
          pre_opt_cat_count += eval("starch_summary_results.cat#{p}_value").to_i
        end
      else
        ripeness_groups_error = "There is no PRE_OPT starch track indicator set up for variety(#{session[:new_delivery].rmt_variety_code})"
      end

      if(post_opt = ripeness_groups.find{|t| t.sub_type=="POST_OPT"})
        post_opt.config_data.split(",").each do |p|
          post_opt_cat_count += eval("starch_summary_results.cat#{p}_value").to_i
        end
      else
        ripeness_groups_error = "There is no POST_OPT starch track indicator set up for variety(#{session[:new_delivery].rmt_variety_code})"
      end

      if(ripeness_groups_error)
        flash[:error] = ripeness_groups_error
        render :inline => %{
        }, :layout => 'content'
        return
      end

      @starch_summary_results_label += "pre:    #{pre_opt_cat_count}<br>"
      @starch_summary_results_label += "opt:    #{opt_cat_count}<br>"
      @starch_summary_results_label += "post:    #{post_opt_cat_count}<br>"
      if((suggested_indicator_id = TrackSlmsIndicator.find_starch_ripeness_indicator(opt_cat_count, pre_opt_cat_count, post_opt_cat_count, session[:new_delivery].rmt_variety_id)).is_a?(String))
        flash[:error] = suggested_indicator_id
        @starch_summary_results_label += "No indicator found<br>"
      else
        suggested_indicator = TrackSlmsIndicator.find(StarchRipenessIndicatorMatchRule.find(suggested_indicator_id).match_ripeness_indicator_id)
        session[:suggested_indicator] = suggested_indicator.track_slms_indicator_code
        @delivery_track_indicator.track_slms_indicator_code = suggested_indicator.track_slms_indicator_code
        @starch_summary_results_label += "Indicator found<br>"
        @starch_summary_results_label += "#{suggested_indicator.track_slms_indicator_code}<br>"
      end
      @delivery_track_indicator.track_indicator_type_code = "STA"
      @delivery_track_indicator.variety_type = "rmt_variety"
      @suggested_track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql("select distinct track_slms_indicator_code from track_slms_indicators where track_indicator_type_code = 'STA' and variety_code='#{session[:new_delivery].rmt_variety_code}' and variety_type='rmt_variety' ").map { |g| [g.track_slms_indicator_code] }
    elsif (session[:new_delivery].delivery_track_indicators.length == 2)
      @delivery_track_indicator.track_indicator_type_code = "pressure_ripeness"
      @empty_track_indicator_type_code_list = true
      @suggested_track_slms_indicator_codes = TrackSlmsIndicator.find(:all, :conditions=>"track_indicator_type_code='pressure_ripeness'").map { |g| [g.track_slms_indicator_code] }
      @hide_variety_type = true
      begin
        groups = QcPressureStandard.find(:all, :select=>"qc_pressure_standards.*,i.track_slms_indicator_code", :conditions => "qc_pressure_standards.rmt_variety_code='#{session[:new_delivery].rmt_variety_code}' ",
                                         :joins => "join track_slms_indicators i on i.id=qc_pressure_standards.track_slms_indictor_id",
                                         :order => "track_slms_indicator_code asc")

        pressure_reading_qtys = summarise_pressure_readings
        suggested_indicator = Delivery.calc_pressure_indicator(pressure_reading_qtys, groups)
        @delivery_track_indicator.track_slms_indicator_code = suggested_indicator.track_slms_indicator_code
      rescue
        flash[:error] = $!.message
        current_delivery
        return
      end


    end

    render_add_delivery_track_indicator
  end

  def render_add_delivery_track_indicator
    @is_delivery_intake_supervisor = authorise(program_name?, 'delivery_intake_supervisor', session[:user_id])
    render :inline => %{
                <% @content_header_caption = "'add track indicator to delivery'"%>

		        <%= build_add_track_indicator_form(@delivery_track_indicator,'create_delivery_indicator','Add indicator',@is_first_time,@is_delivery_intake_supervisor, false,@is_create_retry)%>
           }, :layout => 'content'
  end

  def update_mrl_labels_printed_route_step
    if (Delivery.do_mrl_test_for_commodity(session[:new_delivery].commodity_code))
      should_update_mrl_labels_printed_route_step = true
      grower_commitment_season = Season.find(session[:new_delivery].season_id)
      grower_commitment = GrowerCommitment.find_by_sql("select grower_commitments.* from grower_commitments join spray_program_results on spray_program_results.grower_commitment_id=grower_commitments.id where grower_commitments.farm_id=#{session[:new_delivery].farm_id} and grower_commitments.season='#{grower_commitment_season.season}' and spray_program_results.rmt_variety_code='#{session[:new_delivery].rmt_variety_code}' ")[0] if (grower_commitment_season)
      #  grower_commitment = GrowerCommitment.find_by_farm_id_and_season_code(session[:new_delivery].farm_id,session[:new_delivery].season_code)
      if (grower_commitment)
        spray_program_results = SprayProgramResult.find_by_sql("select * from spray_program_results where grower_commitment_id=#{grower_commitment.id} and rmt_variety_code='#{session[:new_delivery][:rmt_variety_code]}' ")
        if (spray_program_results.length == 0)
          should_update_mrl_labels_printed_route_step = false
        else
          spray_program_results.each do |spray|
            if (spray.mrl_results.detect { |mrl| (!mrl.mrl_label_text) })
              should_update_mrl_labels_printed_route_step = false
              break
            end
          end
        end
      else
        should_update_mrl_labels_printed_route_step = false
      end
      return if !should_update_mrl_labels_printed_route_step
    end
    delivery_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("mrl_labels_printed", session[:new_delivery].id)
    delivery_route_step.update_attributes({:date_activated => DateTime.now, :date_completed => DateTime.now}) if (delivery_route_step && should_update_mrl_labels_printed_route_step)
  end

  def view_suggested_indicator
    @user_overide = UserOverride.find_by_object_identifier(params[:id])
    render :inline => %{
        <% @content_header_caption = "'view  system advised indicator'"%>
        <%= build_view_suggested_indicator_form(@user_overide,nil,'submit')%>
     }, :layout => 'content'
  end

  def create_delivery_indicator
    intake_bin_scanning=DeliveryRouteStep.find_by_delivery_id_and_route_step_code(session[:new_delivery].id, 'intake_bin_scanning')
    if(intake_bin_scanning.date_activated && !intake_bin_scanning.date_completed)
      flash[:error] = "cannot create delivery track indicator: intake_bin_scanning in progress" + @mrl_print_msg.to_s
      @freeze_flash = false
      params[:id] = session[:new_delivery].id
      edit_delivery
      return
    end

    set_is_first_time
    @delivery_track_indicator = DeliveryTrackIndicator.new(params[:delivery_track_indicator])

    @delivery_track_indicator.delivery_id = session[:new_delivery].id

    @delivery = session[:new_delivery]
    first_for_farm_season_rmt = Delivery.find_by_sql("select * from deliveries where farm_code='#{@delivery.farm_code}' and season_code='#{@delivery.season_code}' and rmt_variety_code='#{@delivery.rmt_variety_code}'")
    if (first_for_farm_season_rmt.length < 2)
      session[:alert] = "delivery created. This is the first delivery for #{@delivery.farm_code},#{@delivery.season_code},#{@delivery.rmt_variety_code}\n
                          please print mrl_labels"
      flash[:error] = "delivery created. This is the first delivery for #{@delivery.farm_code},#{@delivery.season_code},#{@delivery.rmt_variety_code}<br>
                          please print mrl_labels"
    end
    #@freeze_flash
    if (params[:delivery_track_indicator][:track_slms_indicator_code] == "")
      @delivery_track_indicator.errors.add_to_base("value of field: 'track_slms_indicator_code' is required")
      render_add_delivery_track_indicator
      return
    end

    #create a delivery track indicator record
    if session[:delivery_track_indicator_form][:first_time]== true && params[:delivery_track_indicator][:track_indicator_type_code] != "RMI"
      @delivery_track_indicator.errors.add_to_base("the first track indicator for delivery must be of type RMI")
      render_add_delivery_track_indicator
      return
    end

    if (is_second_one? && params[:delivery_track_indicator][:track_indicator_type_code] != "STA"  && session[:new_delivery].commodity_code == "AP")
      flash[:error] = "Delivery track indicator could not be saved : second track indicator must be of type STA"
      render_add_delivery_track_indicator
      return
    end

    if (is_third_one? && params[:delivery_track_indicator][:track_indicator_type_code] != "pressure_ripeness"  && session[:new_delivery].commodity_code == "AP")
      flash[:error] = "Delivery track indicator could not be saved : second track indicator must be of type pressure_ripeness"
      render_add_delivery_track_indicator
      return
    end

    track_slms_indicator = TrackSlmsIndicator.find_by_track_slms_indicator_code(params[:delivery_track_indicator][:track_slms_indicator_code])
    if (track_slms_indicator)
      @delivery_track_indicator.track_indicator_type_code = params[:delivery_track_indicator][:track_indicator_type_code]
      @delivery_track_indicator.commodity_code = session[:new_delivery].commodity_code
      @delivery_track_indicator.rmt_variety_code = session[:new_delivery].rmt_variety_code
      @delivery_track_indicator.season_code = session[:new_delivery].season_code
      @delivery_track_indicator.track_slms_indicator = track_slms_indicator
    else
      flash[:error] = "Delivery track indicator could not be saved : corresponding slms indicator record was not found [#{params[:delivery_track_indicator][:track_slms_indicator_code].to_s}]"
      render_add_delivery_track_indicator
      return
    end

    ActiveRecord::Base.transaction do
      if @delivery_track_indicator.save

        if(@delivery_track_indicator.track_indicator_type_code=="STA" && (@delivery_track_indicator.track_slms_indicator_code != session[:suggested_indicator]))
          user_overrides = UserOverride.new({:user_name=>session[:user_id].user_name,:app=>'deliveries', :app_feature=>'track_slms_indicator2', :message=>'user overrode default indicator',
                                             :user_value=>@delivery_track_indicator.track_slms_indicator_code,:object_identifier=>@delivery_track_indicator.id, :system_value=>session[:suggested_indicator]})
          user_overrides.save
        end

        DeliveryTrackIndicator.add_delivery_track_indicator_to_bins(session[:new_delivery],@delivery_track_indicator, session[:user_id].user_name)

        if (@is_first_time || !is_second_one?)
          @freeze_flash = false
          params[:id] = session[:new_delivery].id
          edit_delivery
          return
        end
        #========== delivery_sample_bins_test
        checked_1 = params[:delivery_track_indicator][:track_variable_1]
        checked_2 = params[:delivery_track_indicator][:track_variable_2]
        first_delivery_track_indicator = session[:new_delivery].delivery_track_indicators[0]
        passed_1 = first_delivery_track_indicator.track_variable_1
        passed_2 = first_delivery_track_indicator.track_variable_2

        @delivery_track_indicator.track_variable_1 = checked_1
        @delivery_track_indicator.track_variable_2 = checked_2

        # if passed_2 || session[:new_delivery].commodity_code == "PL"
        #   #create sample bins
        #
        #   else
        #     flash[:error] = "delivery_sample_bin and delivery_route_steps could not be created: sample_percentage for rmt_variety[#{session[:new_delivery].rmt_variety_code}] has not been set up"
        #     @freeze_flash = false
        #     params[:id] = session[:new_delivery].id
        #     edit_delivery
        #     return
        #   end
        #   #updating the delivery record[drench_delivery && sample_bins attributes]
        #   session[:new_delivery].update_attributes(:drench_delivery => checked_1, :sample_bins => checked_2)
        # else
        #   #this_delivery.update_attribute(:sample_bins, "FALSE")
        #   #session[:new_delivery].sample_bins = "FALSE"
        # end
        #============

        puts @delivery_track_indicator.track_variable_1.to_s
        #TESTING FOR OPERATOR OVERRIDE
        if @delivery_track_indicator.track_variable_1 != session[:rmt_variables][:drench_rmt] || @delivery_track_indicator.track_variable_2 != session[:rmt_variables][:sample_rmt]
          @delivery_track_indicator.update_attributes(:operator_override => session[:user_id].user_name, :date_override => DateTime.now)
          session[:new_delivery].update_attributes(:operator_override => session[:user_id].user_name, :date_override => DateTime.now)
        end

        if session[:delivery_track_indicators] == nil
          session[:delivery_track_indicators] = Array.new
        end

        #---

        del_track_indicators = DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{session[:new_delivery].id}' order by id asc")
        session[:delivery_track_indicators] = nil if session[:delivery_track_indicators]!=nil
        session[:delivery_track_indicators] = Array.new
        del_track_indicators.each do |record|
          session[:delivery_track_indicators].push(record)
        end


        #update delivery status of delivery record
        #            	     if session[:new_delivery].update_attribute(:delivery_status, "delivery captured")
        #register a long transaction
        session[:new_delivery].transaction do
          route_step_type = RouteStepType.find_by_route_step_type_code("rmt_delivery")
          route_steps = route_step_type.route_steps

          #check if quantity_damaged_units field is empty
          #delete this route step if quantity_damaged_units field is empty
          if session[:new_delivery].quantity_damaged_units==nil || session[:new_delivery].quantity_damaged_units == "" || session[:new_delivery].quantity_damaged_units.to_i == 0
            qd_del_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("damaged_crates_receive_yes", session[:new_delivery].id)
            if qd_del_route_step
              qd_del_route_step.destroy
            end
          end

          #updating delivery route step where route_code = delivery_captured
          # if route_steps!=nil
          #   @delivery_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("delivery_note_captured", session[:new_delivery].id) #????delivery_capture_started
          #   if @delivery_route_step != nil
          #     @delivery_route_step.update_attributes({:date_activated => DateTime.now.to_formatted_s(:db), :date_completed => DateTime.now.to_formatted_s(:db)})
          #     session[:new_delivery].update_attribute(:delivery_status, @delivery_route_step.route_step_code)
          #   end
          # end
        end
        # end of transaction

        #(spec 5) test to find if delivery is first for (season, farm, rmt_variety)
        delivery_season_farm_rmt_test = Delivery.find_by_sql("select * from deliveries where season_code = '#{session[:new_delivery].season_code}'and farm_code = '#{session[:new_delivery].farm_code}' and rmt_variety_code = '#{session[:new_delivery].rmt_variety_code}'")
        if delivery_season_farm_rmt_test.length() > 0 #&& delivery_season_farm_rmt_test.length() == 1
          update_mrl_labels_printed_route_step
        end

        #DELETING ROUTE STEPS ASSOCIATED WITH DELIVERY WHERE delivery_route_code = 'drench1 complete'
        if @delivery_track_indicator.track_variable_1 == false
          delivery_route_step_1 = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("drench_1_completed", session[:new_delivery].id)
          delivery_route_step_2 = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("drench_2_completed", session[:new_delivery].id)
          if delivery_route_step_1
            delivery_route_step_1.destroy
          end
          if delivery_route_step_2
            delivery_route_step_2.destroy
          end
        end

        #putting route steps into a session array
        if session[:delivery_route_steps]!=nil
          session[:delivery_route_steps] = nil
        end
        #@route_step_type = RouteStepType.find_by_route_step_type_code("rmt_delivery")
        @del_route_steps = DeliveryRouteStep.find_by_sql("select delivery_route_steps.*,route_steps.sequence_number from delivery_route_steps 	join route_steps on delivery_route_steps.route_step_id=route_steps.id where delivery_id ='#{session[:new_delivery].id}' order by route_steps.sequence_number ASC")
        session[:delivery_route_steps] = @del_route_steps
        #            	     end
        #end update delivery status of delivery record

        flash[:notice] = "delivery track indicator created! " + @mrl_print_msg.to_s

        @freeze_flash = false
        params[:id] = session[:new_delivery].id
        edit_delivery
      else
        @is_create_retry = true

        render_add_delivery_track_indicator
      end
    end
  end

  def add_delivery_indicator_for_captured_delivery
    if session[:new_delivery] == nil
      flash[:error] = "No track indicator can be added for no delivery information"
      @freeze_flash = false
      render :inline => %{}, :layout => 'content'
    else
      add_delivery_track_indicator
    end
  end


  def edit_delivery_track_indicator
    id = params[:id]
    puts id.to_s
    if id && @delivery_track_indicator = DeliveryTrackIndicator.find(id)
      #Testing for bin scanning
      bin_scanning_route_step = DeliveryRouteStep.find_by_delivery_id_and_route_step_code(session[:new_delivery].id, "22")
      if bin_scanning_route_step!=nil && bin_scanning_route_step.date_completed!=nil
        flash[:error] = "Editing of the indicator is not allowed since bins were scanned against this delivery"
        render_existing_new_delivery
      else
        render_edit_delivery_track_indicator
      end
    end

  end

  def render_edit_delivery_track_indicator
    @is_delivery_intake_supervisor = authorise(program_name?, 'delivery_intake_supervisor', session[:user_id])
    render :inline => %{
		<% @content_header_caption = "'edit delivery'"%>

		<%= build_edit_delivery_track_indicator_form(@delivery_track_indicator,'update_delivery_track_indicator','update_delivery_track_indicator',@is_delivery_intake_supervisor,true)%>

		}, :layout => 'content'
  end

  def update_delivery_track_indicator
    begin
#    	if params[:page]
#    		session[:deliveries_page] = params['page']
#    		render_list_deliveries
#    		return
#    	end

#    	 @current_page = session[:deliveries_page]
      id = params[:delivery_track_indicator][:id]
      if id && @delivery_track_indicator = DeliveryTrackIndicator.find(id)
        if @delivery_track_indicator.update_attributes(params[:delivery_track_indicator])
          if @delivery_track_indicator.track_indicator_type_code == "LOB"
            @track_variable_1 = nil
            @track_variable_2 = nil
            if params[:delivery_track_indicator][:track_variable_1] == "1"
              @track_variable_1 = true
            else
              @track_variable_1 = false
            end

            if params[:delivery_track_indicator][:track_variable_2] == "1"
              @track_variable_2 = true
            else
              @track_variable_2 = false
            end

            if @track_variable_1!= session[:track_slms_indicator][:track_variable_1] || @track_variable_2 != session[:track_slms_indicator][:track_variable_2]
              session[:new_delivery].update_attributes(:operator_override => session[:user_id].user_name, :date_override => DateTime.now)
              @delivery_track_indicator.update_attributes(:operator_override => session[:user_id].user_name, :date_override => DateTime.now)
            end
            puts params[:delivery_track_indicator].to_s
            puts params[:delivery_track_indicator][:track_variable_1].class.to_s
            #test for sample bin calculations
            if params[:delivery_track_indicator][:track_variable_2]== "1"
              #test if sample bins have be calculated before
              delivery_sample_bins = DeliverySampleBin.find_by_sql("select * from delivery_sample_bins where delivery_id = '#{session[:new_delivery].id}'")
              if delivery_sample_bins.length()==0 #calculate sample bins
                sample_percentage = RmtVariety.find_by_rmt_variety_code_and_commodity_code(session[:new_delivery].rmt_variety_code, session[:new_delivery].commodity_code).sample_percentage
                if sample_percentage
                  quantity_full_bins = session[:new_delivery].quantity_full_bins
                  sample_size = (sample_percentage.to_f / 100) * quantity_full_bins
                  size = sample_size.round
                  size = 1 if (size == 0)
                  array = RandomGenerator.new(size, quantity_full_bins).generate_sequence_numbers
                  if array.length()!=0
                    array.each do |number|
                      delivery_sample_bin = DeliverySampleBin.new
                      delivery_sample_bin.sample_bin_sequence_number = number
                      delivery_sample_bin.delivery_id = session[:new_delivery].id
                      delivery_sample_bin.save
                    end
                  end
                end
              end
            end
            #end of sample bins testing

            #updating the delivery record[drench_delivery && sample_bins attributes]
            session[:new_delivery].update_attributes(:drench_delivery => params[:delivery_track_indicator][:track_variable_1], :sample_bins => params[:delivery_track_indicator][:track_variable_2])
          end

          #@deliveries = eval(session[:query])
          flash[:notice] = 'delivery track indicator record updated'
          session[:delivery_track_indicators] = nil if session[:delivery_track_indicators]!= nil
          delivery_track_indicators = DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{session[:new_delivery].id}' order by id asc")
          session[:delivery_track_indicators] = delivery_track_indicators
          render_existing_new_delivery

        else
          render_edit_delivery_track_indicator

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end


  def delete_delivery_track_indicator
    begin
      return if authorise_for_web(program_name?, 'delivery_delete')== false

      ActiveRecord::Base.transaction do
        id = params[:id]
        if id && delivery_track_indicator = DeliveryTrackIndicator.find(id)
          #test for bin scanning
          bin_scanning_route_step = DeliveryRouteStep.find_by_delivery_id_and_route_step_code(session[:new_delivery].id, "22")
          if bin_scanning_route_step!=nil && bin_scanning_route_step.date_completed!=nil
            flash[:error] = "Editing of the indicator is not allowed since bins were scanned against this delivery"
            render_existing_new_delivery
          else
            delivery_track_indicator.destroy
            session[:alert] = " Delivery Track Indicator Record deleted."
            session[:delivery_track_indicators] = nil if session[:delivery_track_indicators]!= nil
            delivery_track_indicators = DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{session[:new_delivery].id}' order by id asc")
            session[:delivery_track_indicators] = delivery_track_indicators

            DeliveryTrackIndicator.delete_delivery_track_indicator_from_bins(delivery_track_indicator, session[:new_delivery], session[:user_id].user_name)

            render_existing_new_delivery
          end
        end
      end
    rescue handle_error('record could not be deleted')
    end
  end

#observers remote methods

  def indicator_track_indicator_type_code_changed
    track_indicator_type_code = get_selected_combo_value(params)
    variety_type = session[:delivery_track_indicator_form][:variety_type_combo_selection]
    session[:delivery_track_indicator_form][:track_indicator_type_code_combo_selection] = track_indicator_type_code

    if (variety_type == nil || variety_type == "")
      render :inline => %{
            <%= select('delivery_track_indicator', 'rmt_variety_code', ['<empty>']) %>
         }
    else
      @track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql("select distinct track_slms_indicator_code from track_slms_indicators where track_indicator_type_code = '#{track_indicator_type_code}' and variety_code='#{session[:new_delivery].rmt_variety_code}' and variety_type='#{variety_type}' ").map { |g| [g.track_slms_indicator_code] }
      @track_slms_indicator_codes.unshift("<empty>")
      render :inline => %{
                  <%= select('delivery_track_indicator', 'track_slms_indicator_code', @track_slms_indicator_codes) %>
                 <img src='/images/spinner.gif' style='display:none;' id='img_delivery_track_indicator_track_slms_indicator_code'/>
                  <%= observe_field('delivery_track_indicator_track_slms_indicator_code', :update=>'track_variable_1_cell', :url=>{:action=>session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:remote_method]}, :loading=>"show_element('img_delivery_track_indicator_track_slms_indicator_code');", :complete=>session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:on_completed_js])%>

                  <% @clear_check_content1 = check_box('delivery_track_indicator', 'track_variable_1')%>
                    <% @clear_check_content2 = check_box('delivery_track_indicator', 'track_variable_2',{:checked => true}) %>
                  <script>
                    <%= update_element_function(
                        "track_variable_1_cell", :action=>:update,
                        :content=>@clear_check_content1
                    )
                    %>

                    <%= update_element_function(
                        "track_variable_2_cell", :action=>:update,
                        :content=>@clear_check_content2
                    )
                    %>
                  </script>
             }
    end
  end


  def variety_type_changed
    variety_type = get_selected_combo_value(params)
    session[:delivery_track_indicator_form][:variety_type_combo_selection] = variety_type
    track_indicator_type_code = session[:delivery_track_indicator_form][:track_indicator_type_code_combo_selection]
    if (variety_type == "")
#      session[:delivery_track_indicator_form][:variety_type_combo_selection] = nil
      render :inline => %{
                <%= select('delivery_track_indicator', 'rmt_variety_code', ['<empty>']) %>
           }
      return
    elsif (variety_type == "<non_fruit>")
      @track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql("select distinct track_slms_indicator_code from track_slms_indicators where track_indicator_type_code = '#{track_indicator_type_code}'").map { |g| [g.track_slms_indicator_code] }
      @track_slms_indicator_codes.unshift("<empty>")
      render :inline => %{
                <%= select('delivery_track_indicator', 'track_slms_indicator_code', @track_slms_indicator_codes) %>
                <img src='/images/spinner.gif' style='display:none;' id='img_delivery_track_indicator_track_slms_indicator_code'/>
                <%= observe_field('delivery_track_indicator_track_slms_indicator_code', :update=>session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:updated_field_id], :url=>{:action=>session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:remote_method]}, :loading=>"show_element('img_delivery_track_indicator_track_slms_indicator_code');", :complete=>session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:on_completed_js])%>

                <% @clear_check_content1 = check_box('delivery_track_indicator', 'track_variable_1')%>
                  <% @clear_check_content2 = check_box('delivery_track_indicator', 'track_variable_2',{:checked => true}) %>
                <script>
                  <%= update_element_function(
                      "track_variable_1_cell", :action=>:update,
                      :content=>@clear_check_content1
                  )
                  %>

                  <%= update_element_function(
                      "track_variable_2_cell", :action=>:update,
                      :content=>@clear_check_content2
                  )
                  %>
                </script>
           }
      return
    end
    @track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql("select distinct track_slms_indicator_code from track_slms_indicators where track_indicator_type_code = '#{track_indicator_type_code}' and variety_code='#{session[:new_delivery].rmt_variety_code}' and variety_type='#{variety_type}' ").map { |g| [g.track_slms_indicator_code] }
    @track_slms_indicator_codes.unshift("<empty>")
    #render inline to replace the contents of the td that contains the dropdown
    render :inline => %{
                <%= select('delivery_track_indicator', 'track_slms_indicator_code', @track_slms_indicator_codes) %>
               <img src='/images/spinner.gif' style='display:none;' id='img_delivery_track_indicator_track_slms_indicator_code'/>
                <%= observe_field('delivery_track_indicator_track_slms_indicator_code', :update=>'track_variable_1_cell', :url=>{:action=>session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:remote_method]}, :loading=>"show_element('img_delivery_track_indicator_track_slms_indicator_code');", :complete=>session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:on_completed_js])%>

                <% @clear_check_content1 = check_box('delivery_track_indicator', 'track_variable_1')%>
                  <% @clear_check_content2 = check_box('delivery_track_indicator', 'track_variable_2',{:checked => true}) %>
                <script>
                  <%= update_element_function(
                      "track_variable_1_cell", :action=>:update,
                      :content=>@clear_check_content1
                  )
                  %>

                  <%= update_element_function(
                      "track_variable_2_cell", :action=>:update,
                      :content=>@clear_check_content2
                  )
                  %>
                </script>
           }
  end

  def non_supervisor_variety_type_changed
    variety_type = get_selected_combo_value(params)
    track_indicator_type_code = session[:delivery_track_indicator_form][:track_indicator_type_code_combo_selection]
    if (variety_type == "")
      render :inline => %{
                <%= select('delivery_track_indicator', 'rmt_variety_code', ['<empty>']) %>
           }
      return
    elsif (variety_type == "<non_fruit>")
      @track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql("select distinct track_slms_indicator_code from track_slms_indicators where track_indicator_type_code = '#{track_indicator_type_code}'").map { |g| [g.track_slms_indicator_code] }
      @track_slms_indicator_codes.unshift("<empty>")
      render :inline => %{
                <%= select('delivery_track_indicator', 'track_slms_indicator_code', @track_slms_indicator_codes) %>
                <img src='/images/spinner.gif' style='display:none;' id='img_delivery_track_indicator_track_slms_indicator_code'/>
                <%= observe_field('delivery_track_indicator_track_slms_indicator_code', :update=>session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:updated_field_id], :url=>{:action=>'non_supervisor_' + session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:remote_method]}, :loading=>"show_element('img_delivery_track_indicator_track_slms_indicator_code');", :complete=>session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:on_completed_js])%>
           }
      return
    end
    @track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql("select distinct track_slms_indicator_code from track_slms_indicators where track_indicator_type_code = '#{track_indicator_type_code}' and variety_code='#{session[:new_delivery].rmt_variety_code}'").map { |g| [g.track_slms_indicator_code] }
    @track_slms_indicator_codes.unshift("<empty>")
    #render inline to replace the contents of the td that contains the dropdown
    render :inline => %{
                <%= select('delivery_track_indicator', 'track_slms_indicator_code', @track_slms_indicator_codes) %>
               <img src='/images/spinner.gif' style='display:none;' id='img_delivery_track_indicator_track_slms_indicator_code'/>
                <%= observe_field('delivery_track_indicator_track_slms_indicator_code', :update=>'track_variable_1_cell', :url=>{:action=>'non_supervisor_' + session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:remote_method]}, :loading=>"show_element('img_delivery_track_indicator_track_slms_indicator_code');", :complete=>session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:on_completed_js])%>
           }
  end

  def non_supervisor_delivery_track_indicator_track_slms_indicator_code_changed
    track_slms_indicator_code = get_selected_combo_value(params)
    session[:delivery_track_indicator_form][:track_slms_indicator_code_combo_selection] = track_slms_indicator_code
    @track_slms_indicator = TrackSlmsIndicator.find_by_track_slms_indicator_code(track_slms_indicator_code)
    if (@track_slms_indicator)
      @track_variable_1 = "checked='checked'" if (@track_slms_indicator.track_variable_1)
      @val1 = 1
      @val1 = 0 if (!@track_variable_1)
      @track_variable_2 = "checked='checked'" if (@track_slms_indicator.track_variable_2)
      @val2 = 1
      @val2 = 0 if (!@track_variable_2)
    else
      @track_variable_1 = ""
      @val1 = 0
      @track_variable_2 = ""
      @val2 = 0
    end
    render :inline => %{

          <input id='delivery_track_indicator_track_variable_1' name='delivery_track_indicator[track_variable_1]' #{@track_variable_1} type='checkbox' disabled='disabled'/>
           <input name='delivery_track_indicator[track_variable_1]' type='hidden' value='<%=@val1%>' />

           <% @track_variable_2_content = "<input id='delivery_track_indicator_track_variable_2' name='delivery_track_indicator[track_variable_2]' #{@track_variable_2}  type='checkbox' disabled='disabled'/>
                                  <input name='delivery_track_indicator[track_variable_2]' type='hidden' value='#{@val2}' />"%>
          <script>
            <%= update_element_function(
                "track_variable_2_cell", :action=>:update,
                :content=>@track_variable_2_content
            )
            %>
          </script>
       }
  end

  def delivery_track_indicator_track_slms_indicator_code_changed
    track_slms_indicator_code = get_selected_combo_value(params)
    session[:delivery_track_indicator_form][:track_slms_indicator_code_combo_selection] = track_slms_indicator_code
    @track_slms_indicator = TrackSlmsIndicator.find_by_track_slms_indicator_code(track_slms_indicator_code)
    if (@track_slms_indicator)
      @track_variable_1 = @track_slms_indicator.track_variable_1
      @track_variable_2 = @track_slms_indicator.track_variable_2
    else
      @track_variable_1 = false
      @track_variable_2 = false
    end
    render :inline => %{
          <%= check_box('delivery_track_indicator', 'track_variable_1',{:checked => @track_variable_1}) %>

          <% @track_variable_2_content = check_box('delivery_track_indicator', 'track_variable_2' ,{:checked => @track_variable_2}) %>
          <script>
          if(<%=@track_variable_2%> == false) {
            alert("Notice: This track indicator requires no sample bins,are you sure you want to use it?");
          }
            <%= update_element_function(
                "track_variable_2_cell", :action=>:update,
                :content=>@track_variable_2_content
            )
            %>
          </script>
       }
  end

  def indicator_rmt_variety_code_changed
    rmt_variety_code = get_selected_combo_value(params)
    session[:delivery_track_indicator_form][:rmt_variety_code_combo_selection] = rmt_variety_code
    temp_rmt_var = RmtVariety.find_by_rmt_variety_code(rmt_variety_code)
    rmt_variety_drench = temp_rmt_var.drench_rmt if temp_rmt_var != nil
    @drench =""

    @sample = ""
    if rmt_variety_drench=="" || rmt_variety_drench==nil
      @drench = "No"
    else
      rmt_sample = temp_rmt_var.sample_percentage
      @drench = "Yes"
    end

    if rmt_sample=="" || rmt_sample==nil
      @sample = "No"
    else
      @sample = "Yes"
    end

    if session[:rmt_variables]!=nil
      session[:rmt_variables] = nil
    end

    session[:rmt_variables] = Hash.new
    session[:rmt_variables][:drench_rmt] = @drench_rmt
    session[:rmt_variables][:sample_rmt] = @sample_rmt

    track_indicator_type_code = session[:delivery_track_indicator_form][:track_indicator_type_code_combo_selection]
    commodity_code = session[:delivery_track_indicator_form][:commodity_code_combo_selection]

    @season_codes = TrackSlmsIndicator.find_by_sql("select distinct season_code from track_slms_indicators where track_indicator_type_code ='#{track_indicator_type_code}' and commodity_code = '#{commodity_code}' and rmt_variety_code = '#{rmt_variety_code}'").map { |g| [g.season_code] }
    @season_codes.unshift("<select>")

    render :inline => %{

              <%= select('delivery_track_indicator','season_code', @season_codes) %>
              <img src='/images/spinner.gif' style='display:none;' id='img_delivery_track_indicator_season_code'/>
              <%= observe_field('delivery_track_indicator_season_code', :update=>'track_slms_indicator_code_cell', :url=>{:action=>session[:delivery_track_indicator_form][:season_code_observer][:remote_method]}, :loading=>"show_element('img_delivery_track_indicator_season_code');", :complete=>session[:delivery_track_indicator_form][:season_code_observer][:on_completed_js])%>

              <script>

                  <%= update_element_function(
                      "rmt_drench_cell", :action=>:update,
                      :content=>@drench
                    )
                  %>

                  <%= update_element_function(
                        "rmt_sample_bins_cell", :action=>:update,
                        :content=>@sample
                    )
                  %>
              </script>
         }
  end


  def indicator_season_code_changed
    season_code = get_selected_combo_value(params)
    session[:delivery_track_indicator_form][:season_code_combo_selection]
    track_indicator_type_code = session[:delivery_track_indicator_form][:track_indicator_type_code_combo_selection]
    commodity_code = session[:delivery_track_indicator_form][:commodity_code_combo_selection]
    rmt_variety_code = session[:delivery_track_indicator_form][:rmt_variety_code_combo_selection]
    @track_slms_indicator_codes = TrackSlmsIndicator.find_by_sql("select distinct track_slms_indicator_code from track_slms_indicators where track_indicator_type_code = '#{track_indicator_type_code}' and commodity_code = '#{commodity_code}' and rmt_variety_code = '#{rmt_variety_code}' and season_code = '#{season_code}'").map { |g| [g.track_slms_indicator_code] }
    @track_slms_indicator_codes.unshift("<select>")

    render :inline => %{
        <%= select('delivery_track_indicator', 'track_slms_indicator_code', @track_slms_indicator_codes) %>
        <img src='/images/spinner.gif' style='display:none;' id='img_delivery_track_indicator_track_slms_indicator_code'/>
        <%= observe_field('delivery_track_indicator_track_slms_indicator_code', :update=>'ajax_distributor2_cell', :url=>{:action=>session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:remote_method]}, :loading=>"show_element('img_delivery_track_indicator_track_slms_indicator_code');", :complete=>session[:delivery_track_indicator_form][:track_slms_indicator_code_observer][:on_completed_js]) %>
    }
  end

  def indicator_track_slms_indicator_code_changed
    track_slms_indicator_code = get_selected_combo_value(params)
    session[:delivery_track_indicator_form][:track_slms_indicator_code_combo_selection] = track_slms_indicator_code
    @slms_record = TrackSlmsIndicator.find_by_track_slms_indicator_code(track_slms_indicator_code)

    if @slms_record!=nil
      if session[:track_slms_indicator]!= nil
        session[:track_slms_indicator] = nil
      end
      session[:track_slms_indicator]= Hash.new
      session[:track_slms_indicator][:track_variable_1] = @slms_record.track_variable_1
      session[:track_slms_indicator][:track_variable_2] = @slms_record.track_variable_2
    end

    #render inline
    render :inline => %{
        <% @check_1_content = check_box('slms_record', 'track_variable_1') %>
        <% @check_2_content = check_box('slms_record', 'track_variable_2') %>
        <script>
              <%= update_element_function(
                  "track_variable_1_cell", :action=>:update,
                  :content=>@check_1_content
              )
              %>

              <%= update_element_function(
                  "track_variable_2_cell", :action=>:update,
                  :content=>@check_2_content
              )
              %>
        </script>
      }
  end

#=============================================================================================================
#   End Add Delivery_Track_Indicator code
#=============================================================================================================


#=============================================================================================================
#    Allocation of drench lines
#=============================================================================================================

  def allocate_drench
    return if authorise_for_web(program_name?, 'delivery_edit')==false

    #test if drenching is allowed
    @del_track = DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id=#{session[:new_delivery].id} order by id ASC")[0] #delivery_id_and_track_indicator_type_code(session[:new_delivery].id, "LOB")
    if @del_track && @del_track.track_variable_1 == true
      #test for drench allocation
      @drench_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("drench_allocation_complete", session[:new_delivery].id)
      @dry_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("dry_line_allocated", session[:new_delivery].id)
      if @drench_route_step
        if (!@dry_route_step)
          flash[:error]= "dry_line_allocated route step is missing for this delivery"
          @freeze_flash = false
          render_existing_new_delivery
        elsif (@drench_route_step.date_completed==nil && @dry_route_step.date_completed==nil)
          session[:drench_delivery] = nil if session[:drench_delivery]!= nil
          session[:drench_delivery] = Hash.new
          session[:drench_delivery][:delivery_id] = session[:new_delivery].id
          @drench_line_codes = DrenchLine.find_by_sql("select distinct drench_line_code from drench_lines").map { |g| [g.drench_line_code] }
          @drench_line_codes.unshift(["<empty>"])
          render :template => 'rmt_processing/delivery/allocate_drench.rhtml', :layout => 'content'
          #render_allocate_drench
        else
          flash[:error]= "Drench allocation was already done for this delivery"
          @freeze_flash = false
          render_existing_new_delivery
        end
      else
        flash[:error]= "drench_allocation_complete route step is missing for this delivery" #"Delivery has not been set for drenching!"
        @freeze_flash = false
        render_list_deliveries
      end
    else
      flash[:error]= "Drenching is not allowed for this delivery. Check Track_Variable_1 of LOB indicator!"
      @freeze_flash = false
#        render_list_deliveries
      redirect_to_index()
    end
  end

  def allocate_drench_from_grid
    return if authorise_for_web(program_name?, 'edit')==false
    begin

      session[:new_delivery] = Delivery.find(params[:id])

      @del_track = DeliveryTrackIndicator.find_by_delivery_id_and_track_indicator_type_code(session[:new_delivery].id, "LOB")
      if @del_track && @del_track.track_variable_1 == true
        if session[:new_delivery]
          #test for drench allocation
          @drench_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("drench_allocation_complete", session[:new_delivery].id)
          if @drench_route_step!=nil
            if @drench_route_step.date_completed==nil
              session[:drench_delivery] = nil if session[:drench_delivery]!= nil
              session[:drench_delivery] = Hash.new
              session[:drench_delivery][:delivery_id] = session[:new_delivery].id
              @drench_line_codes = DrenchLine.find_by_sql("select distinct drench_line_code from drench_lines").map { |g| [g.drench_line_code] }
              @drench_line_codes.unshift("<select>")
              render_allocate_drench
            else
              redirect_to_index("Drench allocation was already done for this delivery")
            end
          else
            redirect_to_index("Delivery has not been set for drenching!")
          end
        else
          redirect_to_index("Delivery record not found!")
        end
      else
        flash[:error]= "Drenching is not allowed for this delivery. Check Track_Variable_1 of LOB indicator!"
        redirect_to_index()
      end
    rescue
      raise "Error: " + $!
    end
  end

  def render_allocate_drench
    render :template => 'rmt_processing/delivery/allocate_drench.rhtml', :layout => 'content'
  end

  def get_drench_station_codes
    drench_line_code = params[:drench_line_code]
    if (drench_line_code == "<select>" || drench_line_code == "")
      render :inline => %{}
    else
      @drench_line = DrenchLine.find_by_drench_line_code(drench_line_code)
      if (@drench_line.drench_line_type_code.upcase == "DRY LINE")
        render :inline => %{<table border="0">
                            <tr>
                              <td class="drench_fields" style='width: 150px;'>
                                  DRY LINE SELECTED
                              </td>
                              <td class="drench_fields">
                                <input id="dry_station_dry_line" name="drench_station[dry_line_selection]" type="checkbox" checked="checked" disabled="disabled"/>
                                <input name="drench_station[dry_line_selection]" type="hidden" value="1" />
                              </td>
                            </tr>
                           </table>}
        return
      end
      drench_id = @drench_line.id

      @drench_stations = DrenchStation.find_by_sql("select * from drench_stations where drench_line_id = '#{drench_id}'")

      render :inline => %{
        <% for drench_station in @drench_stations %>
          <% if drench_station.drench_status_code=="active" %>
            <table border="0">
              <tr>
                <td class="drench_fields">
                    <%= drench_station.drench_station_code %>
                </td>
                <td class="drench_fields">
                    <%= check_box('drench_station', drench_station.drench_station_code) %>
                </td>
              </tr>
             </table>
          <% else %>
           <table border="0">
            <tr>
              <td class="drench_fields">
                  <%= drench_station.drench_station_code %>
              </td>
              <td class="drench_fields">
                  <label class="drench_label"> deactivated </label>
              </td>
            </tr>
           </table>
        <% end %>
       <% end %>
      }
    end
  end


  def save_drench_allocations
    begin
      #-------------------------------------------
      hash = Hash.new
      hash = params[:drench_station]

      @drench_line_code = params[:drench_line][:drench_line_code]

      #Test to see if user selected drench line code
      if @drench_line_code.to_s.index("select")!= nil
        flash[:notice] = "select a drench line code please"
        @drench_line_codes = DrenchLine.find_by_sql("select distinct drench_line_code from drench_lines").map { |g| [g.drench_line_code] }
        @drench_line_codes.unshift("<select>")
        render_allocate_drench
      else
        #user selected drench line code
        #test params
        if params[:drench_station]==nil
          flash[:error] = "This drench line has no stations[select another drench line please]!"
          @drench_line_codes = DrenchLine.find_by_sql("select distinct drench_line_code from drench_lines").map { |g| [g.drench_line_code] }
          @drench_line_codes.unshift("<select>")
          render_allocate_drench
        else
          # now test for empty hash
          #            if hash.length()==0
          #                flash[:notice] = "The selected drench line is dry, there are no active station"
          #                @drench_line_codes = DrenchLine.find_by_sql("select distinct drench_line_code from drench_lines").map{|g|[g.drench_line_code]}
          #                @drench_line_codes.unshift("<select>")
          #                render_allocate_drench
          #                return
          if (hash[:dry_line_selection])
            delivery_route_step = DeliveryRouteStep.find_by_delivery_id_and_route_step_code(session[:drench_delivery][:delivery_id], "dry_line_allocated")
            if delivery_route_step != nil
              delivery_route_step.update_attributes({:date_activated => DateTime.now, :date_completed => DateTime.now})
              Delivery.update(session[:drench_delivery][:delivery_id], {:delivery_status => delivery_route_step.route_step_code})
              flash[:notice] = "Dry Line allocation done successfully!"
              @freeze_flash = false
              params[:id] = session[:drench_delivery][:delivery_id]
              edit_delivery
              return
            else
              flash[:error] = "Delivery missing rout step = dry_line_allocated"
              render :inline => %{}, :layout => 'content'
              return
            end
          else
            #hash is not nil
            #now test to see if there are selected stations
            testArray = Array.new
            hash.each do |key, value|
              if value=="1"
                testArray.push(key)
              end
            end
            #now really test for selected stations
            if testArray.length()==0
              flash[:notice] = "Select Drench stations please"
              @drench_line_codes = DrenchLine.find_by_sql("select distinct drench_line_code from drench_lines").map { |g| [g.drench_line_code] }
              @drench_line_codes.unshift("<select>")
              render_allocate_drench
            else
              #user selected stations, allocate drench
              hash.each do |key, value|
                if value=="1"
                  #copy the values of drench stations to delivery_drench_station and delivery_drench_concentrates
                  @selected_drench_station = DrenchStation.find_by_drench_station_code(key)
                  if @selected_drench_station != nil
                    @delivery_drench_station = DeliveryDrenchStation.new
                    @delivery_drench_station.delivery_id = session[:drench_delivery][:delivery_id]
                    @delivery_drench_station.drench_station_id = @selected_drench_station.id
                    @delivery_drench_station.operator_name = session[:user_id].user_name
                    @delivery_drench_station.date_drench_allocated = DateTime.now
                    @delivery_drench_station.date_drenched = DateTime.now

                    if @delivery_drench_station.save
                      @drench_concentrates = @selected_drench_station.drench_concentrates
                      if @drench_concentrates!= nil
                        @drench_concentrates.each do |concentrate|
                          @delivery_drench_concentrate = DeliveryDrenchConcentrate.new
                          @delivery_drench_concentrate.drench_station_id = @selected_drench_station.id
                          @delivery_drench_concentrate.drench_station_code = @selected_drench_station.drench_station_code
                          @delivery_drench_concentrate.drench_line_code = concentrate.drench_line_code
                          @delivery_drench_concentrate.concentrate_code = concentrate.concentrate_code
                          @delivery_drench_concentrate.drench_status_code = concentrate.drench_status_code
                          @delivery_drench_concentrate.drench_status_id = concentrate.drench_status_id
                          @delivery_drench_concentrate.concentrate_product_id = concentrate.concentrate_product_id
                          @delivery_drench_concentrate.concentrate_quantity = concentrate.concentrate_quantity
                          @delivery_drench_concentrate.uom = concentrate.uom
                          @delivery_drench_concentrate.date_created = DateTime.now
                          @delivery_drench_concentrate.delivery_drench_station_id = @delivery_drench_station.id
                          @delivery_drench_concentrate.save
                        end
                      end

                      #update delivery route step where route_step_code = 'drench_allocation_complete'
                      @delivery_route_step = DeliveryRouteStep.find_by_delivery_id_and_route_step_code(session[:drench_delivery][:delivery_id], "drench_allocation_complete")
                      if @delivery_route_step!=nil
                        @delivery_route_step.update_attributes(:date_activated => DateTime.now, :date_completed => DateTime.now)
                        Delivery.update(session[:drench_delivery][:delivery_id], {:delivery_status => @delivery_route_step.route_step_code})
                      end
                      session[:delivery_route_steps]= nil if session[:delivery_route_steps]!= nil
                      @del_route_steps = DeliveryRouteStep.find_by_sql("select delivery_route_steps.*,route_steps.sequence_number from delivery_route_steps 	join route_steps on delivery_route_steps.route_step_id=route_steps.id where delivery_id ='#{session[:drench_delivery][:delivery_id]}' order by route_steps.sequence_number ASC")
                      session[:delivery_route_steps] = @del_route_steps

                      #refresh session[:delivery_track_indicators]
                      session[:delivery_track_indicators] = nil if session[:delivery_track_indicators]!= nil
                      @del_track_indicators = DeliveryTrackIndicator.find_by_sql("select * from delivery_track_indicators where delivery_id = '#{session[:new_delivery].id}' order by id asc")
                      session[:delivery_track_indicators] = @del_track_indicators
                    end
                  end

                end
              end
              flash[:notice] = "Drench allocation done successfully!"
              @freeze_flash = false
              render_existing_new_delivery
              return
            end
          end
        end
      end

        #------------------------------------------
    rescue
      raise "Drench allocation could not be done properly: " + $!
    end
  end

#=============================================================================================================
#    Allocation of drench lines
#=============================================================================================================


#Aside code

  def farm_code_combo_changed
    farm_code = params[:farm_code]
    @puc_code = Farm.find_by_farm_code(farm_code).remark1_ptlocation
    render :inline => %{
            <%= @puc %>
        }
  end

#End Aside code


  def test_form
    #@test_field = Delivery.new
    field_extractor = FieldExtractor.new("C://testquery.yml")
    @fields = field_extractor.form_fields
    query_stat = field_extractor.query_statement
    session[:parameter_query] = nil if session[:parameter_query]!=nil
    session[:parameter_query] = query_stat

    render :inline => %{
              <% @content_header_caption = "'parameter fields form'" %>
              <%= build_parameter_fields_form(@fields,"send_parameter_fields", "ok") %>
          }, :layout => 'content'
  end

#-------------------------------------

  def export_report
#    xml_data = ""
#    file_name = "report"
#    @results = Delivery.find(:all)
#    body_elements = ["id", "farm_code","commodity_code", "season_code", "rmt_variety_code"]
#    template_file_path = "C://reports//delivery.rpt"
#    #xml_data = escape_xml_data(render_to_string(:template=>'rmt_processing/delivery/export_report.rxml', :layout=>false))
#    xml_data = render_to_string(:template=>'rmt_processing/delivery/export_report.rexml', :layout=>false)
#
#    xml_schema = CrystalReportGenerator.build_xml_schema('data', body_elements)
#    #xml_schema =""
#    send_data CrystalReportGenerator.generate_report(xml_data, xml_schema,template_file_path), :filename=>'Delivery.pdf', :type=>'pdf/application'


    IO.popen "java cp\ C:/workspace_eclipse/CrystalApp/bin/MainJFrame"

  end

#private

#parse and sanitize the xml schema
  def escape_xml_data(xml_data)
    xml_data = xml_data.gsub("\n", "")
    xml_data = xml_data.gsub("\n", "")
    xml_data = xml_data.gsub(/[\>]([ ])*[\<]/, "><")
    return xml_data

  end

#-------------------------------------


#==============================================================================
# MRL_Label Printing
#==============================================================================

  def mrl_popup_link
    @mrl_result = MrlResult.new
    @mrl_result.farm_code = session[:new_delivery].farm_code
    @mrl_result.puc_code = session[:new_delivery].puc_code
    @mrl_result.orchard_code = session[:new_delivery].orchard_code
    @mrl_result.mrl_result_type_code = session[:new_delivery].mrl_result_type

    sequence_number = nil
    mrl_results_overall = MrlResult.find_by_sql("select * from mrl_results")
    if mrl_results_overall != nil
      mrl_results_seq = MrlResult.find_by_sql("select MAX(sequence_number) AS seq_num from mrl_results")
      sequence_number = mrl_results_seq[0].seq_num.to_i + 1
    else
      sequence_number = 1
    end

    @mrl_result.sample_no = session[:new_delivery].farm_code.to_s + "/" + session[:new_delivery].rmt_variety_code.to_s + "/" + sequence_number.to_s
    render :inline => %{
        <%= build_mrl_result_form(@mrl_result,'print_mrl_label_link','print mrl result',is_edit = nil,is_create_retry = nil ) %>
    }, :layout => 'content'
  end

  def print_mrl_label_link
    farm_id = session[:new_delivery].farm_id
    rmt_variety_id = session[:new_delivery].rmt_variety_id
    season_id = session[:new_delivery].season_id
    user_name = session[:user_id].user_name
    mrl_result_type_code = session[:new_delivery].mrl_result_type
    orchard_code = session[:new_delivery].orchard_code
    puc_code = session[:new_delivery].puc_code

    @msg = genric_print_mrl_label(farm_id, rmt_variety_id, season_id, user_name, mrl_result_type_code, orchard_code, puc_code)
    if (!@msg.include? "PRINTING ERROR: ")
      delivery_route_step = DeliveryRouteStep.find_by_route_step_code_and_delivery_id("mrl_labels_printed", session[:new_delivery].id)
      delivery_route_step.update_attribute(:date_completed, DateTime.now)
      session[:new_delivery].update_attribute(:delivery_status, delivery_route_step.route_step_code)
    end
    flash[:notice]= @msg
    render :inline => %{

    }, :layout => 'content'

  end

  def genric_print_mrl_label(farm_id, rmt_variety_id, season_id, user_name, mrl_result_type_code, orchard_code, puc_code)
    puc_code = nil
    farm_code = nil
    rmt_variety_code = nil

    @mrl_print_msg = ""
    #find parent grower_commitment record
    grower_commitment_season = Season.find(season_id)
    #    grower_commitment_record = GrowerCommitment.find(:first, :conditions=>["farm_id = ? and season = ?", farm_id, grower_commitment_season.season]) if(grower_commitment_season)
    grower_commitment_record = GrowerCommitment.find_by_sql("select grower_commitments.* from grower_commitments join spray_program_results on spray_program_results.grower_commitment_id=grower_commitments.id where grower_commitments.farm_id=#{farm_id} and grower_commitments.season='#{grower_commitment_season.season}' and spray_program_results.rmt_variety_id='#{rmt_variety_id}' ")[0] if (grower_commitment_season)
    if grower_commitment_record!=nil
      #find the child spray_program_results_record
      spray_program_results_record = SprayProgramResult.find(:first, :conditions => ["grower_commitment_id = ? and rmt_variety_id = ?", grower_commitment_record.id, rmt_variety_id])

      if spray_program_results_record == nil
        #raise "A spray program results record for the rmt_variety must first be created!"
        @mrl_print_msg += "MRL Label not printed, REASON: A spray program results record for rmt_variety must first be created"

        #redirect_to_index(@mrl_print_msg)
        return @mrl_print_msg
      else
#            session[:delivery_form][:mrl_result_type_combo_selection]= session[:new_delivery].mrl_result_type
        puts "PRINTING ENTERD!!!!!!!"
        farm = Farm.find(farm_id)
        farm_code = farm.farm_code
        rmt_variety_code = RmtVariety.find(rmt_variety_id).rmt_variety_code
        msg = MrlResult.print_mrl_job(spray_program_results_record.id, mrl_result_type_code, puc_code, orchard_code, farm_code, rmt_variety_code, @mrl_print_msg, user_name)

        #@freeze_flash = false
        return msg

      end
    else
      @mrl_print_msg += "PRINTING ERROR: MRL Label could not be printed, REASON:  Grower Commitment/Mrl label data not captured yet!"
      #@freeze_flash = false
      return @mrl_print_msg
    end

  end


  def print_label_first_per_season_farm_rmt_variety
    #begin
    #get the delivery record's farm_id and rmt_variety_id
    farm_id = session[:new_delivery].farm_id
    rmt_variety_id = session[:new_delivery].rmt_variety_id
    season_id = session[:new_delivery].season_id
    @mrl_print_msg = ""
    #find parent grower_commitment record
    grower_commitment_season = Season.find(season_id)
    grower_commitment_record = GrowerCommitment.find_by_sql("select grower_commitments.* from grower_commitments join spray_program_results on spray_program_results.grower_commitment_id=grower_commitments.id where grower_commitments.farm_id=#{farm_id} and grower_commitments.season='#{grower_commitment_season.season}' and spray_program_results.rmt_variety_id='#{rmt_variety_id}' ")[0] if (grower_commitment_season)
    #      grower_commitment_record = GrowerCommitment.find(:first, :conditions=>["farm_id = ? and season = ?", farm_id, grower_commitment_season.season]) if(grower_commitment_season)
    #      grower_commitment_record = GrowerCommitment.find(:first, :conditions=>["farm_id = ? and season_id = ?", farm_id, season_id])
    if grower_commitment_record != nil
      #find the child spray_program_results_record
      spray_program_results_record = SprayProgramResult.find(:first, :conditions => ["grower_commitment_id = ? and rmt_variety_id = ?", grower_commitment_record.id, rmt_variety_id])

      if spray_program_results_record == nil
        #raise "A spray program results record for the rmt_variety must first be created!"
        @mrl_print_msg += "PRINTING ERROR: MRL Label not printed, reason: A spray program results record for rmt_variety must first be created"
      else
        inside = "PRINTING ENETERD!!!!!!!"

        @return_msg = ""
        mrl_result_type = session[:new_delivery].mrl_result_type
        puc_code = session[:new_delivery].puc_code
        orchard_code = session[:new_delivery].orchard_code
        farm_code = session[:new_delivery].farm_code
        rmt_variety_code = session[:new_delivery].rmt_variety_code

        msg = MrlResult.print_mrl_job(spray_program_results_record.id, mrl_result_type, puc_code, orchard_code, farm_code, rmt_variety_code, @return_msg, session[:user_id].user_name)
        @mrl_print_msg += msg
      end
    else
      @mrl_print_msg += "PRINTING ERROR: MRL Label could not be printed, REASON: Grower Commitment/Mrl label data not captured yet!"
    end

    return @mrl_print_msg
    # rescue
    # raise "Mrl Label could not be printed! " + inside + "  " + $!
    #end

  end

#==============================================================================
# End MRL_Label Printing
#==============================================================================

  def search_deliveries
#    return if authorise_for_web(program_name?, 'read')== false

    dm_session[:parameter_fields_values] = nil
    dm_session['se_layout'] = 'content'
    @content_header_caption = "'search delivery headers'"
    dm_session[:redirect] = true
    build_remote_search_engine_form("search_delivery_headers.yml", "submit_deliveries_search")
  end

  def submit_deliveries_search
#    puts "EVAL = " + dm_session[:search_engine_query_definition]
    @deliveries = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    if (@deliveries.length > 0)
      session[:query] = "Delivery.find_by_sql(\"#{dm_session[:search_engine_query_definition]}\")"
      render_found_deliveries
    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                            </script>
                          }, :layout => 'content'
    end
  end

  def render_found_deliveries
    if @deliveries !=nil and @deliveries.length > 0
      @can_edit = authorise(program_name?, 'delivery_edit', session[:user_id])
#      can_edit_delivery?
      @can_delete = authorise(program_name?, 'delivery_delete', session[:user_id])

      render :inline => %{
      <% grid            = build_delivery_grid(@deliveries,@can_edit,@can_delete) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    else
      redirect_to_index("'no forecast records to list'", "''")
    end
  end

  def validate_delivery_deletion
    bins = Bin.find_by_sql("select * from bins join deliveries on deliveries.id = bins.delivery_id where deliveries.delivery_number=#{session[:new_delivery].delivery_number}")
    if (bins.length > 0)
      return "'" + bins.length.to_s + " bin(s) have already been scanned for this delivery'"
    end
    return nil
  end

  def can_edit_delivery?
    bins = Bin.find_by_sql("select * from bins join deliveries on deliveries.id = bins.delivery_id where deliveries.delivery_number=#{session[:new_delivery].delivery_number}")
    if (bins.length > 0)
      @content_header_caption = "'sorry, " + bins.length.to_s + " bin(s) have already been scanned for this delivery'"
      return true
    end
    route_step = DeliveryRouteStep.find_by_delivery_id_and_route_step_code(session[:new_delivery].id, "100_fruit_sample_completed")
    if (route_step && route_step.date_completed && session[:new_delivery].rmt_product_id)
      @content_header_caption = "'sorry, 100_fruit_sample_completed has been captured and therefore cannot edit delivery'"
      return false
    end
    return true
  end

  def view_delivery
    @delivery = Delivery.find(params[:id])
    render_new_uneditable
  end

  def current_delivery
    if (session[:new_delivery])
      params[:id] = session[:new_delivery].id
      edit_delivery
    else
      flash[:notice] = 'No curent delivery'
      render :inline => %{}, :layout => 'content'
    end
  end

  def complete_100_fruit_sample
    hundred_fruit_sample_route_step = DeliveryRouteStep.find_by_delivery_id_and_route_step_code(params[:id], "100_fruit_sample_completed")
    @delivery_id = params[:id]
    if (hundred_fruit_sample_route_step)
      hundred_fruit_sample_route_step.update_attributes({:date_activated => DateTime.now, :date_completed => DateTime.now})
      Delivery.update_all(ActiveRecord::Base.extend_set_sql_with_request("delivery_status='#{hundred_fruit_sample_route_step.route_step_code}'", "deliveries"), "id=#{@delivery_id}")
      session[:alert] = '100_fruit_sample_completed route step done successfully'
      render :inline => %{
              <script>
                window.opener.frames[1].location.href = "/rmt_processing/delivery/edit_delivery/<%= @delivery_id %>";
                window.close();
              </script>
      }, :layout => 'content'
    else
      session[:alert] = '100_fruit_sample_completed route step not found'
      render :inline => %{
              <script>
                window.close();
              </script>
      }, :layout => 'content'
    end
  end

  def print_composite_report
    report_unit ="reportUnit=/reports/MES/RMT/composite_report&"
    report_parameters= "output=pdf&delivery_number=" + params[:id]
    @url = Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters

    render :inline => %{
              <script>
                window.location.href = "<%= @url %>";
              </script>
      }, :layout => 'content'
  end

  def print_tripsheet
    ActiveRecord::Base.transaction do
      @delivery = Delivery.find(params[:id])
      vehicle_job = VehicleJob.find_by_vehicle_job_number(@delivery.delivery_number.to_s)
      if (!vehicle_job)
        vehicle_job = VehicleJob.new({:transaction_business_name => "INTAKE_DELIVERY", :vehicle_job_number => @delivery.delivery_number, :date_time_loaded => Time.now})
        vehicle_job.save!

        @delivery.bins.each do |bin|
          vehicle_job_unit = VehicleJobUnit.new({:vehicle_job_id => vehicle_job.id, :unit_reference_id => bin.bin_number, :date_time_loaded => Time.now})
          vehicle_job_unit.save!
        end
        Inventory.move_stock("CREATE_TRIPSHEET", @delivery.delivery_number, "IN_TRANSIT", @delivery.bins.map { |c| c.bin_number })
        DeliveryRouteStep.update_all(ActiveRecord::Base.extend_set_sql_with_request("date_completed='#{Time.now}'", "delivery_route_steps"), "delivery_id=#{@delivery.id} and route_step_code='trip_sheet_printed'")
      end
    end

    session[:alert] = 'tripsheet successfully printed'
    report_unit ="reportUnit=/reports/MES/RMT/delivery_tripsheet&"
    report_parameters= "output=pdf&delivery_number=" + @delivery.delivery_number.to_s
    @url = Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters

    render :inline => %{
              <script>
                window.opener.frames[1].location.href = "/rmt_processing/delivery/edit_delivery/<%= @delivery.id %>";
                window.location.href = "<%= @url %>";
              </script>
      }, :layout => 'content'
  end


  def treatment_code_changed
    treatment_code = get_selected_combo_value(params)
    session[:delivery_form][:treatment_code_combo_selection] = treatment_code

    ripe_point_code = session[:delivery_form][:ripe_point_code_combo_selection]

    if authorise(program_name?, 'choose_rmt_product_code', session[:user_id])
      @rmt_product_codes = RmtProduct.find_by_sql("select rmt_product_code,id from rmt_products where variety_code='#{session[:delivery_form][:rmt_variety_code_combo_selection]}' and commodity_code='#{session[:delivery_form][:commodity_code_combo_selection]}' and rmt_product_type_code='orchard_run' ORDER BY rmt_product_code").map { |g| [g.rmt_product_code, g.id] }
    else
      @rmt_product_codes = ["<empty>"]
    end

    if ((session[:delivery_form][:rmt_variety_code_combo_selection] && session[:delivery_form][:rmt_variety_code_combo_selection].to_s != "") && (ripe_point_code && ripe_point_code != ""))
      more_conditions = ""
      #sql = "select * from rmt_products where size_code = 'UNS' and product_class_code = 'OR' and treatment_code = '#{treatment_code}' and commodity_code='#{session[:delivery_form][:commodity_code_combo_selection]}' and variety_code='#{session[:delivery_form][:rmt_variety_code_combo_selection].to_s}' and ripe_point_code='#{ripe_point_code}' #{more_conditions}"
      sql = "select * from rmt_products where size_code = 'UNS' and product_class_code = 'OR' and treatment_code = '#{treatment_code}' and commodity_code='#{session[:delivery_form][:commodity_code_combo_selection]}' and variety_code='#{session[:delivery_form][:rmt_variety_code_combo_selection].to_s}' and ripe_point_code='#{ripe_point_code}'  and rmt_product_type_code='orchard_run' #{more_conditions}"
      puts "2. Search by = #{sql}"

      @advised_rmt_product_code = RmtProduct.find_by_sql(sql).map { |g| [g.rmt_product_code, g.id] }[0]

    end

    if (@advised_rmt_product_code && @advised_rmt_product_code.length > 0)
      @content = @advised_rmt_product_code[0]
      @rmt_product_codes.unshift(@advised_rmt_product_code)
    else
      @rmt_product_codes.unshift("<empty>")
    end

    render :inline => %{
                      <%= select('delivery', 'rmt_product_id', @rmt_product_codes,{:sorted=>true}) %>
                      <script>
                        <%= update_element_function(
                            "advised_rmt_product_code_cell", :action=>:update,
                            :content=>@content.to_s
                        )
                        %>
                      </script>
                      }
  end

  def ripe_code_changed
    ripe_code = get_selected_combo_value(params)
    ripe_point = RipePoint.find_by_sql("select distinct ripe_point_code from ripe_points where cold_store_type_code = 'RA' and treatment2_code  = 'NO' and ripe_code = '#{ripe_code}'")[0]
#    @advised_ripe_point_code = ""
    @advised_ripe_point_code = ripe_point.ripe_point_code if ripe_point

    @ripe_point_codes = RipePoint.find_by_sql("select distinct ripe_point_code from ripe_points ORDER BY ripe_point_code ASC").map { |h| [h.ripe_point_code] }
    if (@advised_ripe_point_code)
      session[:delivery_form][:ripe_point_code_combo_selection] = @advised_ripe_point_code
      @ripe_point_codes.unshift(@advised_ripe_point_code)
    else
      @ripe_point_codes.unshift("<empty>")
    end

    render :inline => %{
            <%= select('delivery','ripe_point_code',@ripe_point_codes,{:sorted => true})%>
            <img src='/images/spinner.gif' style='display:none;' id='img_delivery_ripe_point_code'/>
            <%= observe_field('delivery_ripe_point_code', :update=>session[:delivery_form][:ripe_point_code_observer][:updated_field_id], :url=>{:action=>session[:delivery_form][:ripe_point_code_observer][:remote_method]}, :loading=>"show_element('img_delivery_ripe_point_code');", :complete=>session[:delivery_form][:ripe_point_code_observer][:on_completed_js]) %>

            <script>
              <%= update_element_function(
                  "advised_ripe_point_code_cell", :action=>:update,
                  :content=>@advised_ripe_point_code
              )
              %>
            </script>
    }
  end


  def ripe_point_code_changed
    ripe_point_code = get_selected_combo_value(params)
    session[:delivery_form][:ripe_point_code_combo_selection] = ripe_point_code

    treatment_code = session[:delivery_form][:treatment_code_combo_selection]
#    @rmt_product_codes = RmtProduct.find_by_sql("select rmt_product_code,id from rmt_products where variety_code='#{session[:delivery_form][:rmt_variety_code_combo_selection]}' and commodity_code='#{session[:delivery_form][:commodity_code_combo_selection]}' and rmt_product_type_code='orchard_run' ORDER BY rmt_product_code").map{|g|[g.rmt_product_code,g.id]}
#    @rmt_product_codes.unshift("<empty>")

    if authorise(program_name?, 'choose_rmt_product_code', session[:user_id])
      @rmt_product_codes = RmtProduct.find_by_sql("select rmt_product_code,id from rmt_products where variety_code='#{session[:delivery_form][:rmt_variety_code_combo_selection]}' and commodity_code='#{session[:delivery_form][:commodity_code_combo_selection]}' and rmt_product_type_code='#{session[:delivery_form][:rmt_product_type_code_combo_selection]}' ORDER BY rmt_product_code").map { |g| [g.rmt_product_code, g.id] }
    else
      @rmt_product_codes = ["<empty>"]
    end

    if ((session[:delivery_form][:rmt_variety_code_combo_selection] && session[:delivery_form][:rmt_variety_code_combo_selection].to_s != "") && (treatment_code && treatment_code != ""))
      more_conditions = ""
      sql = "select * from rmt_products where size_code = 'UNS' and product_class_code = 'OR' and treatment_code = '#{treatment_code}' and commodity_code='#{session[:delivery_form][:commodity_code_combo_selection]}' and variety_code='#{session[:delivery_form][:rmt_variety_code_combo_selection].to_s}' and ripe_point_code='#{ripe_point_code}' and rmt_product_type_code='#{session[:delivery_form][:rmt_product_type_code_combo_selection]}' #{more_conditions}"
      puts "3. Search by = #{sql}"

      @advised_rmt_product_code = RmtProduct.find_by_sql(sql).map { |g| [g.rmt_product_code, g.id] }[0]
      @content = @advised_rmt_product_code[0] if (@advised_rmt_product_code && @advised_rmt_product_code.length > 0)
    end

    if (@advised_rmt_product_code)
      @rmt_product_codes.unshift(@advised_rmt_product_code)
    else
      @rmt_product_codes.unshift("<empty>")
    end

    render :inline => %{
                      <%= select('delivery', 'rmt_product_id', @rmt_product_codes,{:sorted=>true}) %>
                      <script>
                        <%= update_element_function(
                            "advised_rmt_product_code_cell", :action=>:update,
                            :content=>@content.to_s
                        )
                        %>
                      </script>
                      }
  end

  def edit_destination_complex
    @delivery = Delivery.find(params[:id])
    render :inline => %{
      <% @content_header_caption = "'search  deliveries'"%>
      <%= build_delivery_search_form(@delivery,'update_destination_complex','update')%>
    }, :layout => 'content'
  end

  def update_destination_complex
    if session[:new_delivery] && session[:new_delivery].update_attributes(params[:delivery])
      session[:alert] = "destination complex updated successfully"
    else
      session[:alert] = "destination complex could not be updates"
    end
    render :inline => %{
            <script>
              window.opener.frames[1].location.href = "/rmt_processing/delivery/current_delivery";
              window.close();
            </script>
            }, :layout => 'content'
  end


  def capture_summary_starch_results
    @starch_summary_results = StarchSummaryResult.find_by_delivery_id(params[:id])
    render_capture_summary_starch_results
  end

  def render_capture_summary_starch_results
    render :inline => %{
		<% @content_header_caption = "'capture summary starch results'"%>

		<%= build_capture_summary_starch_results_form(@starch_summary_results)%>

		}, :layout => 'content'
  end

  def capture_summary_starch_results_submit
    if(params[:starch_summary_results].values.map{|v| v.to_i}.sum > 20)
      flash[:error] = "starch results could not be captured. Starch results add up to more than 20"
      @starch_summary_results = StarchSummaryResult.new(params[:starch_summary_results])
      render_capture_summary_starch_results
      return
    end
    if(params[:starch_summary_results].values.map{|v| v.to_i}.sum < 20)
      flash[:error] = "starch results could not be captured. Starch results add up to less than 20"
      @starch_summary_results = StarchSummaryResult.new(params[:starch_summary_results])
      render_capture_summary_starch_results
      return
    end
    if(starch_summary_results = StarchSummaryResult.find_by_delivery_id(session[:new_delivery].id))
      starch_summary_results.update_attributes(params[:starch_summary_results])
    else
      starch_summary_results = StarchSummaryResult.new(params[:starch_summary_results])
      starch_summary_results.delivery_id = session[:new_delivery].id
      starch_summary_results.save!
    end

    session[:alert] = "summary starch results captured successfully"
    render :inline => %{
        <script>
          window.close();
        </script>
		}, :layout => 'content'
  end
end
