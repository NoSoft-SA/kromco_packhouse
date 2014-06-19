class Fg::WipPalletsController < ApplicationController

  def program_name?
    "wip_pallets"
  end

  def bypass_generic_security?
    true
  end

  def filter_by_fruitspec()
    return if authorise_for_web(program_name?,'read') == false
    render_filter_by_fruitspec
  end

  def render_filter_by_fruitspec()
    render :inline => %{
      <% @content_header_caption = "'find half pallets by fruitspec'"%>

      <%= build_filter_by_fruitspec_form(@pallet,'submit_filter_by_fruitspec','submit',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def submit_filter_by_fruitspec()
    commodity_code = params[:pallet][:commodity_code].to_s
    if commodity_code.strip == "" || commodity_code.upcase.index("<EMPTY>") != nil || commodity_code.upcase.index("SELECT ") != nil
      commodity_code = " LIKE '%'"
    else
      commodity_code = "='" + commodity_code + "'"
    end
    marketing_variety_code = params[:pallet][:marketing_variety_code].to_s
    if marketing_variety_code.strip == "" || marketing_variety_code.upcase.index("<EMPTY>") != nil || marketing_variety_code.upcase.index("SELECT ") != nil
      marketing_variety_code = " LIKE '%'"
    else
      marketing_variety_code = "='" + marketing_variety_code + "'"
    end
    org_short_description = params[:pallet][:org_short_description].to_s
    if org_short_description.strip == "" || org_short_description.upcase.index("<EMPTY>") != nil || org_short_description.upcase.index("SELECT ") != nil
      org_short_description = " LIKE '%'"
    else
      org_short_description = "='" + org_short_description + "'"
    end
    target_market_code = params[:pallet][:target_market_code].to_s
    if target_market_code.strip == "" || target_market_code.upcase.index("<EMPTY>") != nil || target_market_code.upcase.index("SELECT ") != nil
      target_market_code = " LIKE '%'"
    else
      target_market_code = "='" + target_market_code + "'"
    end
    facility_code = params[:pallet][:facility_code].to_s
    if facility_code.strip == "" || facility_code.upcase.index("<EMPTY>") != nil || facility_code.upcase.index("SELECT ") != nil
      facility_code = " LIKE '%'"
    else
      facility_code = "='" + facility_code + "'"
    end
    location_code = params[:pallet][:location_code].to_s
    if location_code.strip == "" || location_code.upcase.index("<EMPTY>") != nil || location_code.upcase.index("SELECT ") != nil
      location_code = " LIKE '%'"
    else
      location_code = "='" + location_code + "'"
    end

    query = "SELECT cartons.id AS id, cartons.pallet_number, cartons.commodity_code, cartons.variety_short_long, "
    query += "cartons.organization_code, cartons.fg_product_code, cartons.farm_code, cartons.target_market_code, "
    query += "locations.location_code, facilities.facility_code "
    query += "FROM (( cartons JOIN pallets ON (pallets.id = cartons.pallet_id) JOIN stock_items ON (pallets.pallet_number = stock_items.inventory_reference) JOIN locations "
    query += "ON (stock_items.location_code = locations.location_code) JOIN facilities ON (locations.facility_id = facilities.id))) "
    query += "WHERE locations.location_code#{location_code} AND facilities.facility_code#{facility_code} AND "
    query += "cartons.commodity_code#{commodity_code} AND cartons.variety_short_long#{marketing_variety_code} AND "
    query += "cartons.target_market_code#{target_market_code} AND cartons.organization_code#{org_short_description} AND upper(pallets.build_status) = 'PARTIAL' GROUP BY "
    query += " cartons.id, cartons.pallet_number, cartons.commodity_code, cartons.variety_short_long, "
    query += " cartons.organization_code, cartons.fg_product_code, cartons.farm_code, cartons.target_market_code,"
    query += " locations.location_code, facilities.facility_code "

    session[:query] = query
    render_find_filter_by_fruitspec
  end

  def render_find_filter_by_fruitspec()
    @can_edit = authorise(program_name?,'edit',session[:user_id])
  	@can_delete = authorise(program_name?,'delete',session[:user_id])
  	query =  session[:query]

    pals = Carton.connection.select_all(query)
    @pallets = remove_duplicates(pals, true)
    session[:pallets_returned] = @pallets
    render :inline => %{
      <% grid            = build_filter_by_fruitspec_grid(@pallets,true) %>
      <% grid.caption    = 'list of all inventory receipts' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@inventory_receipts_pages) if @inventory_receipts_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end


  def remove_duplicates(pallets, key_based_access =nil)
    hash = Hash.new
    pallets_array = Array.new
    if pallets.length != 0
      pallets.each do |pallet|
        if key_based_access
          if hash.has_key?(pallet["pallet_number"]) == false
            hash.store(pallet["pallet_number"], pallet)
          end
        else
          if hash.has_key?(pallet.pallet_number) == false
            hash.store(pallet.pallet_number, pallet)
          end
        end
      end
      hash.each do |key,val|
        pallets_array.push(val)
      end
    end

    return pallets_array
  end


  #=============================
  # FILTER BY SCHEDULE
  #=============================
  def filter_by_schedule()
    return if authorise_for_web(program_name?,'read') == false
    render_filter_by_schedule
  end

  def render_filter_by_schedule()
    session[:fields] = nil if session[:fields]
    session[:fields] = Hash.new
    render :inline => %{
      <% @content_header_caption = "'find half pallets by schedule'"%>

      <%= build_filter_by_schedule_form(@pallet,'submit_filter_by_schedule','submit',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def submit_filter_by_schedule()
    production_schedule_name = params[:pallet][:production_schedule_name].to_s
    if production_schedule_name.strip == "" || production_schedule_name.upcase.index("<EMPTY>") != nil || production_schedule_name.upcase.index("SELECT ") != nil
      production_schedule_name = " LIKE '%'"
    else
      production_schedule_name = "='" + production_schedule_name + "'"
    end

    facility_code = params[:pallet][:facility_code].to_s
    if facility_code.strip == "" || facility_code.upcase.index("<EMPTY>") != nil || facility_code.upcase.index("SELECT ") != nil
      facility_code = " LIKE '%'"
    else
      facility_code = "='" + facility_code + "'"
    end
    location_code = params[:pallet][:location_code].to_s
    if location_code.strip == "" || location_code.upcase.index("<EMPTY>") != nil || location_code.upcase.index("SELECT ") != nil
      location_code = " LIKE '%'"
    else
      location_code = "='" + location_code + "'"
    end

    query = "SELECT
      public.production_runs.production_schedule_name,
      public.facilities.facility_code,
      public.locations.location_code,
      public.cartons.commodity_code,
      public.cartons.variety_short_long,
      public.cartons.organization_code,
      public.cartons.target_market_code,
      public.cartons.inventory_code,
      public.cartons.grade_code,
      public.cartons.fg_code_old,
      public.cartons.pallet_number,
      public.pallets.build_status,
      MIN(public.cartons.pack_date_time) AS pack_date_time,
      MIN(public.cartons.id) AS id
    FROM
      public.cartons
      INNER JOIN public.production_runs ON (public.cartons.production_run_id = public.production_runs.id)
      INNER JOIN public.stock_items ON (public.cartons.pallet_number = public.stock_items.inventory_reference)
      LEFT OUTER JOIN public.locations ON (public.stock_items.location_code = public.locations.location_code)
      INNER JOIN public.facilities ON (public.locations.facility_id = public.facilities.id)
      INNER JOIN public.pallets ON (public.cartons.pallet_id = public.pallets.id)
    WHERE
      UPPER(public.pallets.build_status) = 'PARTIAL' AND production_runs.production_schedule_name#{production_schedule_name}
      AND locations.location_code#{location_code} AND facilities.facility_code#{facility_code}
    GROUP BY
      public.production_runs.production_schedule_name,
      public.facilities.facility_code,
      public.locations.location_code,
      public.cartons.commodity_code,
      public.cartons.variety_short_long,
      public.cartons.organization_code,
      public.cartons.target_market_code,
      public.cartons.inventory_code,
      public.cartons.grade_code,
      public.cartons.fg_code_old,
      public.cartons.pallet_number,
      public.pallets.build_status"

    session[:query] = query
    render_find_filter_by_schedule
    #  AS carton_id
  end

  def render_find_filter_by_schedule()
    query =  session[:query]
    #puts query
    pals = Carton.connection.select_all(query)
    @pallets = remove_duplicates(pals, true)
    #@pallets = pals
    session[:pallets_returned] = @pallets
    render :inline => %{
      <% grid            = build_filter_by_schedule_grid(@pallets,true) %>
      <% grid.caption    = 'list of all inventory receipts' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@inventory_receipts_pages) if @inventory_receipts_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end


  def selected_pallets()
    @selected_pallets = selected_records?(session[:pallets_returned],nil,true)
    if @selected_pallets.length != 0
      ActiveRecord::Base.transaction do
        pick_list_type = PickListType.find_by_pick_list_type_code("WIP_RETURNS")
        pick_list = PickList.new
        pick_list.pick_list_type_id = pick_list_type.id
        pick_list.date_time = Time.now.to_formatted_s(:db)
        pick_list.quantity = @selected_pallets.length.to_i
        pick_list.create
        @selected_pallets.each do |pallet|
          pick_list_item = PickListItem.new
          pick_list_item.pick_list_id = pick_list.id
          pick_list_item.reference_id = pallet["pallet_number"]
          pick_list_item.quantity = 1
          pick_list_item.create
        end
        ## Printing of PickListReport
        
      end
    end
    session[:pallets_returned] = nil
    redirect_to_index("Pallets were received and Pick list items were successfully created")
  end


  #=================================================================
  # OBSERVER METHODS
  #=================================================================
  def pallet_commodity_code_combo_changed()
    commodity_code = get_selected_combo_value(params)
    session[:filter_by_fruitspec_form][:commodity_code_selection] = commodity_code
    @marketing_variety_codes = Pallet.find_by_sql("SELECT DISTINCT marketing_variety_code FROM marketing_varieties WHERE commodity_code ='#{commodity_code}'").map{|g|[g.marketing_variety_code]}
    @marketing_variety_codes.unshift("<empty>")
    render :inline=>%{
        <%=select('pallet','marketing_variety_code',@marketing_variety_codes) %>
    }
  end

  def pallet_facility_code_combo_changed()
    facility_code = get_selected_combo_value(params)
    session[:filter_by_fruitspec_form][:facility_code_selection] = facility_code
    facility = Facility.find_by_facility_code(facility_code)
    if facility
    @location_codes = Location.find_by_sql("SELECT DISTINCT location_code FROM locations WHERE facility_id ='#{facility.id}'").map{|g|[g.location_code]}
    else
      @location_codes = Array.new
    end
    @location_codes.unshift("<empty>")
    render :inline=>%{
        <%=select('pallet','location_code',@location_codes) %>
    }
  end

  def pallet_season_code_combo_changed()
    season_code = get_selected_combo_value(params)
    session[:fields][:season_code] = season_code
    @production_schedule_names = Pallet.get_production_schedule_names(session[:fields])
    render :inline=>%{
        <%=select('pallet','production_schedule_name',@production_schedule_names) %>
    }
  end

  def pallet_farm_code_combo_changed()
    farm_code = get_selected_combo_value(params)
    session[:fields][:farm_code] = farm_code
    @production_schedule_names = Pallet.get_production_schedule_names(session[:fields])
    render :inline=>%{
        <%=select('pallet','production_schedule_name',@production_schedule_names) %>
    }
  end

  def pallet_rmt_variety_code_combo_changed()
    rmt_variety_code = get_selected_combo_value(params)
    session[:fields][:rmt_variety_code] = rmt_variety_code
    @production_schedule_names = Pallet.get_production_schedule_names(session[:fields])
    render :inline=>%{
        <%=select('pallet','production_schedule_name',@production_schedule_names) %>
    }
  end

  def pallet_facility_two_code_combo_changed()
    facility_code = get_selected_combo_value(params)
    facility = Facility.find_by_facility_code(facility_code)
    if facility
    @location_codes = Location.find_by_sql("SELECT DISTINCT location_code FROM locations WHERE facility_id ='#{facility.id}'").map{|g|[g.location_code]}
    else
      @location_codes = Array.new
    end
    @location_codes.unshift("<empty>")
    render :inline=>%{
        <%=select('pallet','location_code',@location_codes) %>
    }
  end

end
