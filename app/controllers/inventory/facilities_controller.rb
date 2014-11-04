class Inventory::FacilitiesController < ApplicationController
  def program_name?
    "facilities"
  end

  def status_history
    id                                                = params[:id]
    session[:id]                                      = id
#    session["get_pallets_by_carton_static_values"].store(yml_field, static_value)
    dm_session["search_location_statuses_static_values"] = {"transaction_statuses.object_id"=>id}

    dm_session['se_layout']                              = 'content'
    @content_header_caption                           = "'select dates'"
    build_remote_search_engine_form("search_location_statuses.yml", "show_status_history")
    dm_session[:redirect] = true
  end


  def show_status_history
    statuses = ExtendedFg.connection.select_all(dm_session[:search_engine_query_definition])
    @statuses=Array.new
    for status in statuses
      if    status['object_id'].to_i == session[:id].to_i
        @statuses << status
      end
    end
    @transaction_statuses= @statuses
      render :inline => %{
		<% column_configs = []
          column_configs << {:field_type=>'text', :field_name=>'object_id', :column_caption=>'location_id'}
          column_configs << {:field_type=>'text', :field_name=>'status_code', :column_caption=>'status'}
          column_configs << {:field_type=>'text', :field_name=>'status_type_code'}
          column_configs << {:field_type=>'text', :field_name=>'username'}
          column_configs << {:field_type=>'text', :field_name=>'created_on'}
          column_configs << {:field_type=>'text', :field_name=>'id'}
          %>
      <% grid            = get_data_grid(@transaction_statuses,column_configs,nil,true) %>
      <% grid.caption    = 'transaction_statuses' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@facilities_pages) if @facilities_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'



  end


  def build_error_div(validations_error)
    valication_error_container = "
        <table id='validation_error_container' border='0' style='background: whitesmoke;font-family: verdana;font-size: 12px;border-collapse: collapse;width: 100%;height: 100px;width: 500px;border: red solid 2px;'>
          <tr style='font-weight: bold;color: white;height: 25px;background: #CC3333;'>
            <td> 1 error prohibited this record from being saved</td>
          </tr>
          <tr style='height: 10px;'>
            <td>&nbsp;&nbsp;&nbsp;The status could not be changed because:</td>
          </tr>
          <tr style='height: 75px;'>
            <td style='padding-left: 50px;'>
              <li>#{validations_error}</li>
            </td>
          </tr>
        </table>
        <script>
          flash = document.getElementById('validation_error_container').parentNode;
          flash.style.border = 'none';
          flash.style.background = 'white';
        </script>
      "
  end

  def bins
    location_id   = params[:id]
    location_code = Location.find(location_id).location_code
    code          = "@bins         =Bin.find_by_sql('select  bins.*,
                            deliveries.delivery_number,
                            pack_material_products.pack_material_product_code,
                            rmt_products.rmt_product_code,
                            farms.farm_code ,
                            production.production_run_code ,
                            production_runs.bins_tipped,
                            track_slms1.track_slms_indicator_code as indicator_code1,
                            track_slms2.track_slms_indicator_code as indicator_code2,
                            track_slms3.track_slms_indicator_code as indicator_code3,
                            track_slms4.track_slms_indicator_code as indicator_code4,
                            track_slms5.track_slms_indicator_code as indicator_code5
                            from bins
                            LEFT  JOIN stock_items ON stock_items.inventory_reference=bins.bin_number
                            LEFT OUTER JOIN deliveries ON bins.delivery_id = deliveries.id
                            LEFT OUTER JOIN rmt_products ON bins.rmt_product_id = rmt_products.id
                            LEFT OUTER JOIN farms ON bins.farm_id = farms.id
                            LEFT OUTER JOIN production_runs production ON bins.production_run_rebin_id = production.id
                            LEFT OUTER JOIN production_runs ON bins.production_run_tipped_id = production_runs.id
                            LEFT OUTER JOIN pack_material_products ON bins.pack_material_product_id = pack_material_products.id
                            LEFT  JOIN track_slms_indicators track_slms1 ON bins.track_indicator1_id = track_slms1.id
                            LEFT  JOIN track_slms_indicators track_slms2 ON bins.track_indicator2_id = track_slms2.id
                            LEFT  JOIN track_slms_indicators track_slms3 ON bins.track_indicator3_id = track_slms3.id
                            LEFT  JOIN track_slms_indicators track_slms4 ON bins.track_indicator4_id = track_slms4.id
                            LEFT  JOIN track_slms_indicators track_slms5 ON bins.track_indicator5_id = track_slms5.id
                            where stock_items.location_id = #{location_id}')"

    eval code
    session[:query] = code

code # TODO: WHAT IS THIS DOING HERE?
    render :inline => %{
      <% grid            = build_bins_grid(@bins) %>
      <% grid.caption    = 'bins for location: #{location_code}' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end

  #where (destroyed=false  or destroyed is null ) and stock_items.location_id =#{location_id}")

  def pallets
    location_id   = params[:id]
    location_code = Location.find(location_id).location_code
    @pallets      = Pallet.find_by_sql("select pallets.*
                                  from pallets
                                  inner join stock_items on stock_items.inventory_reference=pallets.pallet_number
                                  where (destroyed=false  or destroyed is null ) and stock_items.location_id =#{location_id}")
    render :inline => %{
      <% grid            = build_pallets_grid(@pallets) %>
      <% grid.caption    = 'pallets for location: #{location_code}' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end

  def set_status


    location_id        = params[:id]
    @location          = Location.find(location_id)
    session[:location] =@location
    @location.status_changed_date_time=Time.now
    @caption           = "set status for    #{@location.location_code.to_s}  "
    render :inline => %{

     <% @content_header_caption = " '#{@caption}'"%>

		<%= build_set_status_form(@location,'change_status','change_status',false,@is_create_retry)%>

		}, :layout => 'content'
  end


  def change_status
    begin
      ActiveRecord::Base.transaction do
        new_status_code           = params[:location][:location_code]
        session[:new_status_code] =new_status_code
        location                  = session[:location].location_code
        session[:status_changed_date_time] =params[:location][:status_changed_date_time]
        bins_in_location(session[:location].id) and return

      end

    rescue
       raise $!
    end
  end


  def bins_in_location(location_id)
    location_code = session[:location].location_code
    stock_items   = StockItem.find_by_sql("select * from stock_items where location_id =#{location_id} and (destroyed = false or destroyed is null)").map{|p|"'#{p.inventory_reference}'"}

    if session[:new_status_code]=="LOADING" || session[:new_status_code]=="EMPTY"

      StatusMan.set_status(session[:new_status_code], session[:location].location_type_code, session[:location], session[:user_id].user_name)
      render :inline => %{<script>
                          alert(" status changed");
                          window.opener.frames[1].location.href = '/inventory/facilities/build_list_locations_grid';
                          window.close();

                     </script>} and return
    else
      if !stock_items.empty?
        bins=Bin.get_bins(stock_items)
        session[:bins] = bins
        session[:rmt_products]=nil

      elsif stock_items.empty? && session[:new_status_code]=="OPEN"
        StatusMan.set_status(session[:new_status_code], session[:location].location_type_code, session[:location], session[:user_id].user_name)
        render :inline => %{<script>
                          alert(" status changed");
                          window.opener.frames[1].location.href = '/inventory/facilities/build_list_locations_grid';
                          window.close();
                     </script>} and return

      else
        render :inline => %{<script>
                            alert("No stock items available in location to change to that status");
                            window.close();

                             </script>} and return
      end
      if !bins.empty?
        rmt_products =Bin.group_bins_by_rmt_product(bins)

      else
        result =session[:location].change_status(session[:bins],session[:rebins],session[:rmt_products],session[:new_status_code],session[:user_id],session[:status_changed_date_time])
        if result == nil
          render :inline => %{<script>
                              alert(" status changed");
                              window.opener.frames[1].location.href = '/inventory/facilities/build_list_locations_grid';
                              window.close();
                               </script>} and return
        else
          raise result
        end

      end

      session[:rmt_products]=rmt_products
      calc_new_rmt_products
    end
  end

  def calc_new_rmt_products
    session[:rmt_products].each do |rmt_product|
      new_ripe_point_code=nil
      new_ripe_point= ActiveRecord::Base.connection.select_one("select  dest_ripe_point_code from cold_store_ripe_point_codes
                          where (orig_ripe_point_code='#{rmt_product['ripe_point_code']}' and coldstore_status_change='#{session[:new_status_code]}'  ) ")

      if new_ripe_point
        new_ripe_point_code=new_ripe_point['dest_ripe_point_code']
      end

      rmt_product['new_ripe_point_code']=new_ripe_point_code

      if new_ripe_point_code
        new_rmt_product_code = RmtProduct.find_by_sql("select rmt_product_code,id FROM rmt_products WHERE
                                             commodity_code='#{rmt_product['commodity_code']}' AND
                                             variety_code='#{rmt_product['variety_code']}' AND
                                             size_code='#{rmt_product['size_code']}' AND
                                             product_class_code='#{rmt_product['product_class_code']}' AND
                                             treatment_code='#{rmt_product['treatment_code']}' AND
                                             ripe_point_code ='#{new_ripe_point_code}'")
        if !new_rmt_product_code.empty?
          rmt_product['new_rmt_product_code'] = new_rmt_product_code[0]['rmt_product_code']
          rmt_product['new_rmt_product_id']= new_rmt_product_code[0]['id']
        end
      end

    end
    session[:rmt_products]
    render_bins_for_location
  end

  def render_bins_for_location

    @rmt_products = session[:rmt_products]
    location_code = session[:location].location_code

    render :inline => %{
            <% grid            = build_rmt_product_codes_grid(@rmt_products) %>
            <% grid.caption    = 'rmt_product_codes in : #{location_code}' %>
            <% @header_content = grid.build_grid_data %>
            <%= grid.render_html %>
            <%= grid.render_grid %>
            }, :layout => 'content'


  end

  def set_ripe_point_code

    rmt_product_id = params[:id].to_i
    for product in session[:rmt_products]
      if   product['id'].to_i ==rmt_product_id
        session[:product]=product
      end
    end

    ripe_point_id       = session[:product].ripe_point_id
    @ripe_point         = RipePoint.find(ripe_point_id)

    session[:ripe_point]=@ripe_point
    render :inline => %{
                       <% @content_header_caption = "'set ripe point for product: #{session[:product]['rmt_product_code']}'" %>
                       <%= build_set_ripe_point_code_form(@ripe_point,'update_rmt_product','save',false)%>
                       }, :layout => 'content'
  end

  def update_rmt_product
    if    (session[:product]['new_ripe_point_code'] == ""|| session[:product]['new_ripe_point_code'] == nil) && (session[:product]['new_rmt_product_code'] =="" || session[:product]['new_rmt_product_code'] ==nil)
      flash[:error] = "RECORD CANNOT BE SAVED BECAUSE  NEW_RIPE_POINT and NEW_RMT_PRODUCT CANNOT BE FOUND"
      redirect_to :controller => 'inventory/facilities', :action => 'set_ripe_point_code', :id => session[:product]['id'] and return
    elsif session[:product]['new_ripe_point_code'] == ""|| session[:product]['new_ripe_point_code'] == nil
      flash[:error] = "RECORD CANNOT BE SAVED BECAUSE EITHER NEW_RIPE_POINT CANNOT BE FOUND"
      redirect_to :controller => 'inventory/facilities', :action => 'set_ripe_point_code', :id => session[:product]['id'] and return
    elsif session[:product]['new_rmt_product_code'] =="" || session[:product]['new_rmt_product_code'] ==nil
      flash[:error] = "RECORD CANNOT BE SAVED BECAUSE  NEW_RMT_PRODUCT CANNOT BE FOUND"
      redirect_to :controller => 'inventory/facilities', :action => 'set_ripe_point_code', :id => session[:product]['id'] and return
    end

    session[:rmt_products]
    render :inline => %{<script>
                        window.opener.location.href = '/inventory/facilities/render_bins_for_location/';
                         window.close();
                      </script>}
  end

  def store_treatment_code
    session[:treatment2_code]= get_selected_combo_value(params)
    content=nil
    render :inline=> %{

                  <script>
                      <%= update_element_function(
                          "new_ripe_point_code_cell", :action=>:update,
                          :content=> "#{content}"
                      )
                      %>
                            <%= update_element_function(
                          "new_rmt_product_code_cell", :action=>:update,
                          :content=>"#{content}"
                      )
                      %>
                  </script>
        }
  end

  def create_new_ripe_point_code

    cold_store_type_id  = get_selected_combo_value(params)
    new_treatment2_code = session[:treatment2_code]
    ripe_code=session[:ripe_point].ripe_code
    product =session[:product]
    result =Location.create_new_ripe_point_code(cold_store_type_id,new_treatment2_code,ripe_code,product)

    session[:product]['new_ripe_point_code']  =result['new_ripe_point_code']
    session[:product]['new_rmt_product_code'] = result['new_rmt_product_code']
    if   result['new_rmt_product_code']!=nil
      session[:product]['new_rmt_product_id'] =result['new_rmt_product'].id
    end

     render :inline=> %{

              <script>
                  <%= update_element_function(
                      "new_ripe_point_code_cell", :action=>:update,
                      :content=> "#{result['new_ripe_point_code']}"
                  )
                  %>
                        <%= update_element_function(
                      "new_rmt_product_code_cell", :action=>:update,
                      :content=>"#{result['new_rmt_product_code']}"
                  )
                  %>
              </script>
    }


  end



  def change_location_status
    if session[:new_status_code].upcase.index("SEALED") ||  session[:new_status_code].upcase.index("SHORT")
      empty_new_rmt_codes=[]
       session[:rmt_products].each do |rmt_product|
         rmt_product.each do |key,value|
           empty_new_rmt_codes << value  if (key=='new_rmt_product_code' && (value==nil || value=="" || value=='' ))
         end
       end
      if !empty_new_rmt_codes.empty?
        flash[:error]="Status cannot be changed .One or more groups do not have a new rmt product code"
        render :inline => %{<script>
                        window.opener.location.href = '/inventory/facilities/render_bins_for_location/';
                         window.close();
                      </script>}    and return
      end

      end

        result =session[:location].change_status(session[:bins],session[:rebins],session[:rmt_products],session[:new_status_code],session[:user_id],session[:status_changed_date_time] )
        if result == nil
         render :inline => %{<script>
                            alert(" status changed");
                            window.opener.opener.frames[1].location.href = '/inventory/facilities/build_list_locations_grid';
                            window.opener.close();
                            window.close();
                             </script>} and return
        else
          raise result
          #@error = build_error_div(result)
          # render :inline=>%{<%= @error %>}, :layout=>'content'and return
        end
    end


  def new_facility
    render_new_facility
  end

  def render_new_facility

    render :inline => %{
                       <% @content_header_caption = "'create new facility'" %>
                       <%= build_facility_form(@facility,'create_facility','save',false)%>
                       }, :layout => 'content'
  end

  def find_locations
    render :inline => %{
  		<% @content_header_caption = "'find locations'"%>

  		<%= build_locations_search_form()%>

  		}, :layout => 'content'


  end

  def create_facility
    organization                 = Organization.find_by_short_description(params[:facility][:organization_code])
    @facility                    = Facility.new
    @facility.facility_code      = params[:facility][:facility_code]
    @facility.facility_type_code = params[:facility][:facility_type_code]
    @facility.organization_id    = organization.id

    begin
      @facility.save
      flash[:notice] = "'facility saved successfully'"
      #happy added the following line
      @facilities    = Facility.find(:all)
      render_list_facilities

    rescue
      raise $!
    end
  end


  def search_facilities
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search          = true
    session[:is_flat_search] = @is_flat_search
    # render (inline) the search form
    render :inline => %{
  		<% @content_header_caption = "'select facility type and org'"%>

  		<%= build_facilities_search_form(nil,'submit_facility_type_org_search','submit facility type and org search',@is_flat_search)%>

  		}, :layout => 'content'
  end

  def render_list_facilities
    #@facilities = Facility.find(:all)
    @can_edit   = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
      render :inline => %{
      <% grid            = build_facilities_grid(@facilities,@can_edit,@can_delete) %>
      <% grid.caption    = @cont_header || 'list of all facilities' %>
      <% @cont_header = nil %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
	}, :layout => 'content'
  end

  def submit_facility_type_org_search
    @facility_type_code = params[:facility][:facility_type_code]
    @org_short_desc     = params[:facility][:org]
    @cont_header        = "facilities of type \"" + @facility_type_code + "\" for org \"" + @org_short_desc + "\""
    org                 = Organization.find_by_short_description(@org_short_desc)

    sql                 = "select * from facilities"
    if !@facility_type_code.index("empty")
      sql += " where facility_type_code = '#{@facility_type_code}'"
    end

    if !@org_short_desc.index("empty")
      if sql.index("where")
        sql += "and organization_id ='#{org.id}' "
      else
        sql += " where organization_id ='#{org.id}' "
      end
    end


    @facilities = Facility.find_by_sql(sql)
    render_list_facilities
  end

  def submit_locations_search
    if params[:location]
      @location_type_code                       = params[:location][:location_type_code]
      @location_code                            = params[:location][:location_code]
      @parent_location_code                     = params[:location][:parent_location_code]

      session[:location]                        = Hash.new
      session[:location][:location_type_code]   = @location_type_code
      session[:location][:location_code]        = @location_code
      session[:location][:parent_location_code] = @parent_location_code
    else
      @location_type_code   = session[:location][:location_type_code]
      @location_code        = session[:location][:location_code]
      @parent_location_code = session[:location][:parent_location_code]

    end


    @cont_header = "found locations"


    if @location_code==""
      sql          = "select * from locations where location_code like '%%' "
    else
      sql          = "select * from locations where location_code like '%#{@location_code}%' "
    end

    if @location_type_code==""
      sql += " and location_type_code like '%%'"
    else
      sql += " and location_type_code like '#{@location_type_code}'"
    end

    if @parent_location_code.strip==""
      sql += " and parent_location_code like '%%' "
    else
      sql += " and parent_location_code like '%#{@parent_location_code}%' "
    end

    sql += " order by location_code ASC"

    puts "LOC SQL:: " + sql
    session[:locations_sql]=sql
    @locations              = Location.find_by_sql(sql )
    render_list_locations
  end

  def edit_facility
    @facility = Facility.find(params[:id])

    render_edit_facility
  end

  def render_edit_facility
    @content_header_caption = "'edit facility'"
# render :template => '/inventory/facilities/edit_facility.rhtml', :layout => 'content'

    render :inline => %{
                       <% @content_header_caption = "'edit facility'" %>
                       <%= build_facility_form(@facility,'update_facility','save',true)%>
                       }, :layout => 'content'
  end

  def update_facility
    @facility                   = Facility.find(params[:id])
    organization                = Organization.find_by_short_description(params[:organisation][:organization_code])
    facility                    = Facility.new
    facility.facility_code      = params[:facility][:facility_code]
    facility.facility_type_code = params[:facility][:facility_type_code]
    facility.organization_id    = organization.id

    begin
      @facility.update_attributes(facility.attributes)
      flash[:notice] = "'facility updated successfully'"

      #happy added the following line
      @facilities    = Facility.find(:all)
      render_list_facilities

    rescue
      raise $!
    end

  end

  def delete_facility
    @facility = Facility.find(params[:id])

    begin
      @facility.destroy
      flash[:notice] = "'facility deleted successfully'"

      #happy added the following line
      @facilities    = Facility.find(:all)
      render_list_facilities

    rescue
      raise $!
    end
  end

  def new_location
    session[:location]        = nil
    @can_control_availability = authorise(program_name?, 'control_availability', session[:user_id])
    @content_header_caption   = "'create new location'"
    render :inline=> %{
                       <%= build_location_form(@location,'create_location','create_location',false,false,@can_control_availability)  %>
                       }, :layout => 'content'
  end

  def create_location
    begin
      @location                        = Location.new
      @location.location_code          = params[:location][:location_code]
      @location.bay_code               = params[:location][:bay_code]
      @location.location_type_code     = params[:location][:location_type_code]
      @location.gln                    = params[:location][:gln]
      @location.location_barcode       = params[:location][:location_barcode]
      @location.location_status        = params[:location][:location_status]
      @location.location_maximum_units = params[:location][:location_maximum_units].to_i
      @location.storage_type           = params[:location][:storage_type]
      @location.assignment_type        = params[:location][:assignment_type]
      @location.row_number             = params[:location][:row_number]
      @location.column_number          = params[:location][:column_number]
      @location.level_number           = params[:location][:level_number]
      @location.section_number         = params[:location][:section_number]
      @location.unavailable            = params[:location][:unavailable]
      if (session[:add_location])
        parent_loc = Location.find(session[:location])
        @location.parent_location_code = parent_loc.location_code if parent_loc
      else
        @location.parent_location_code = params[:location][:parent_location_code]
      end

      if @location.save
        flash[:notice] = "'location successfully created'"
        if (session[:add_location])
          @node_name = @location.location_code
          @node_type = "location"
          @node_id   = @location.id.to_s
          @tree_name = "locations"

          render :inline => %{
                          <% @hide_content_pane = true %>
                          <% @is_menu_loaded_view = false %>

                          <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>

                          }, :layout => 'tree_node_content'
        else
          redirect_to_index()
        end
      else
        flash[:notice] = "'could not create location'"
        if (@add_location)
          render :inline => %{
                          <% @hide_content_pane = true %>
                          <% @is_menu_loaded_view = false %>
                          }, :layout => 'tree_node_content'
        else
          new_location
        end
      end
    rescue
      handle_error("Could not create Location")
    ensure
      session[:location] = nil
    end
  end

  def control_location_availability
    @location = Location.find(params[:id])
    begin
      if (@location && @location.unavailable)
        @location.update_attribute(:unavailable, false)
      else
        @location.update_attribute(:unavailable, true)
      end
      session[:alert] = "location's availability set successfully"
      if (session[:locations_sql])
        @locations = Location.find_by_sql(session[:locations_sql])
        render_list_locations
      else
        render :inline => %{}, :layout=>'content'
      end
    rescue
      handle_error("Could set the location's availability")
    end
  end

  def list_locations
    session[:current_facility] = @facility

    build_list_locations_grid
  end

  def render_list_locations
    @can_edit                           = authorise(program_name?, 'edit', session[:user_id])
    @can_delete                         = authorise(program_name?, 'delete', session[:user_id])
    @can_view_locations_storage_rules   = authorise(program_name?, 'view_locations_storage_rules', session[:user_id])
    @can_view_locations_parent_location = authorise(program_name?, 'view_locations_parent_location', session[:user_id])
    @can_view_locations_child_locations = authorise(program_name?, 'view_locations_child_locations', session[:user_id])
    @can_control_availability           = authorise(program_name?, 'control_availability', session[:user_id])

    @content_header_caption             = "'list of all locations'"

    render :inline => %{
      <% grid            = build_locations_grid(@locations,@can_edit,@can_delete,@can_view_locations_storage_rules,@can_view_locations_parent_location,@can_view_locations_child_locations,@can_control_availability) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
	}, :layout => 'content'
  end

  def build_list_locations_grid
    session[:locations_sql] = " select * from locations order by location_code asc"   if !session[:locations_sql]
    @locations              = Location.find_by_sql(session[:locations_sql])
    render_list_locations
  end


  def edit_location
    @content_header_caption   = "'edit location to facility'"
    @can_control_availability = authorise(program_name?, 'control_availability', session[:user_id])
    if !@location
      session[:location] = params[:id]
      @location          = Location.find(session[:location])
    end

    render :inline=> %{
                       <%= build_location_form(@location,'update_location','update',true,false,@can_control_availability)  %>
                       }, :layout => 'content'
  end

  def update_location
    @location                        = Location.find(session[:location])
    @location.location_code          = params[:location][:location_code]
    @location.bay_code               = params[:location][:bay_code]
    @location.location_type_code     = params[:location][:location_type_code]
    @location.gln                    = params[:location][:gln]
    @location.location_barcode       = params[:location][:location_barcode]
    @location.location_status        = params[:location][:location_status]
    @location.location_maximum_units = params[:location][:location_maximum_units].to_i
    @location.storage_type           = params[:location][:storage_type]
    @location.assignment_type        = params[:location][:assignment_type]
    @location.row_number             = params[:location][:row_number]
    @location.column_number          = params[:location][:column_number]
    @location.level_number           = params[:location][:level_number]
    @location.section_number         = params[:location][:section_number]
    @location.parent_location_code   = params[:location][:parent_location_code]
    @location.unavailable            = params[:location][:unavailable]

    begin
      @location.update
      redirect_to_index("Location updated successfully!!!")
    rescue
      flash[:notice] = "Location could not be updated : " + $!.to_s
      edit_location
    end


  end

  def delete_location
    @location = Location.find(params[:id])

    begin
      parent_location_code = @location.location_code
      id                   = @location.id.to_s

      ActiveRecord::Base.transaction do
        @location.destroy
        Location.update_all(ActiveRecord::Base.extend_set_sql_with_request("parent_location_code = Null","locations"), "parent_location_code='#{parent_location_code}'")

        flash[:notice] = "'location successfully deleted'"
        if (@remove)
          @node_name = parent_location_code
          @node_type = "location"
          @node_id   = id
          @tree_name = "locations"
          @remove    = false
          render :inline => %{
                          <% @hide_content_pane = true %>
                          <% @is_menu_loaded_view = true %>
                          <% @tree_actions = "window.parent.RemoveNode(null);" %>
                          }, :layout => 'tree_node_content'
        else
          @remove = false
          redirect_to_index()
        end
      end
    rescue
      flash[:notice] = "could not delete location'"
      if (@remove)
        @remove = false
        render :inline => %{
                        <% @hide_content_pane = true %>
                        <% @is_menu_loaded_view = false %>
                        }, :layout => 'tree_node_content'
      else
        @remove = false
        redirect_to_index("location successfully deleted")
      end
    end
  end

  def new_facility_type

  end


  def storage_rules

    @id = params[:id]
    if !@id
      @child_form_caption = ["child_form3", "&nbsp"]
      render :inline=>%{}, :layout=>'content'
    else
      location                                = Location.find(@id)
      session[:current_storage_rule_location] = location
      @location_setups                        = location.location_setups
      @child_form_caption                     = ["child_form3", "storage rules for location " + location.location_code.to_s]
      @can_edit                               = authorise(program_name?, 'storage_rule_edit', session[:user_id])
      @can_delete                             = authorise(program_name?, 'storage_rule_delete', session[:user_id])

      render :inline => %{
      <% grid            = build_location_setups_grid(@location_setups,@can_edit,@can_delete) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'


    end

  end

  def bin_storage_rules
    @location                                = Location.find(params[:id])
    @can_edit                               = authorise(program_name?, 'storage_rule_edit', session[:user_id])
    @can_delete                             = authorise(program_name?, 'storage_rule_delete', session[:user_id])

    render :inline => %{
      <% grid            = build_bin_location_setups_grid(@can_edit,@can_delete) %>
      <% grid.caption    = 'list of bin storage rule for location:#{@location.location_code}' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end

  def new_storage_rule
    return if authorise_for_web(program_name?, 'storage_rule_create') == false
    render_new_storage_rule
  end

  def new_bin_storage_rule
    return if authorise_for_web(program_name?, 'storage_rule_create') == false
    @location_id = params[:id]
    @action = 'create_bin_storage_rule'
    @caption = 'create'
    render_new_bin_storage_rule
  end

  def render_new_bin_storage_rule
    render :inline => %{
		<% @content_header_caption = "'create new bin storage rule'"%>
		<%= build_bin_location_setup_form(@bin_location_setup,@action,@caption,@is_edit,@is_create_retry)%>
		}, :layout => 'content'
  end

  def render_new_storage_rule
    render :inline => %{
		<% @content_header_caption = "'create new storage rule'"%>
		<%= build_location_setup_form(@location_setup,'create_storage_rule','save',false,@is_create_retry)%>
		}, :layout => 'content'
  end

  def create_storage_rule
    begin
      @location_setup = LocationSetup.new(params[:location_setup])
      if session[:current_storage_rule_location]
        @location_setup.location_id   = session[:current_storage_rule_location].id
        @location_setup.location_code = session[:current_storage_rule_location].location_code
      end
      if @location_setup.new_record?
        if @location_setup.save
          @url_base = "http://" + request.host_with_port + "/" + "inventory/facilities/storage_rules/" + session[:current_storage_rule_location].id.to_s

          render :inline => %{<script>
                                        alert('storage rule created');
                                        window.opener.location.href = '/inventory/facilities/storage_rules/<%= @location_setup.location_id.to_s%>';
                                        window.close();
                                </script>}


        else
          @is_create_retry = true
          render_new_storage_rule
        end
      else
        handle_error("location setup record already exists!")
      end
    rescue
      handle_error("location setup record could not be created")
    end
  end

  def create_bin_storage_rule
    begin
      @bin_location_setup = BinLocationSetup.new(params[:bin_location_setup])
      #if @bin_location_setup.new_record?
        if @bin_location_setup.save
          session[:alert] = 'storage rule created'
          render :inline => %{
            <script>
              window.opener.location.href = '/inventory/facilities/bin_storage_rules/<%= @bin_location_setup.location_id%>';
              window.close();
            </script>}
        else
          @location_id = @bin_location_setup.location_id
          @action = 'create_bin_storage_rule'
          @caption = 'create'
          @is_create_retry = true
          render_new_bin_storage_rule
        end
      #else
      #  handle_error("bin location setup record already exists!")
      #end
    rescue
      handle_error("bin location setup record could not be created")
    end
  end

  def edit_location_setup
    id = params['id']
    if id && @location_setup = LocationSetup.find(id)
      render_edit_location_setup
    end
  end

  def edit_bin_location_setup
    id = params['id']
    if id && @bin_location_setup = BinLocationSetup.find(id)
      @is_edit = true
      @action = 'update_bin_storage_rule'
      @caption = 'save'
      render_new_bin_storage_rule
    end
  end

  def render_edit_location_setup
    render :inline => %{
      <% @content_header_caption = "'edit storage rule'"%>

      <%= build_location_setup_form(@location_setup,'update_storage_rule','update',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_storage_rule
    begin
      id = params[:location_setup][:id]
      if id && @location_setup = LocationSetup.find(id)
        if @location_setup.update_attributes(params[:location_setup])

          @url_base = "http://" + request.host_with_port + "/" + "inventory/facilities/storage_rules/" + session[:current_storage_rule_location].id.to_s

          render :inline => %{<script>
                                        alert('storage rule edited');
                                        window.opener.location.href = '/inventory/facilities/storage_rules/<%= @location_setup.location_id.to_s%>';
                                        window.close();
                                </script>}

        else
          render_edit_location_setup
        end
      end
    rescue
      handle_error("location setup record not be updated")
    end
  end

  def update_bin_storage_rule
    begin
      if @bin_location_setup = BinLocationSetup.find(params[:bin_location_setup][:id])
        if @bin_location_setup.update_attributes(params[:bin_location_setup])
          session[:alert] = 'bin storage rule edited successfully'
          render :inline => %{
            <script>
              window.opener.location.href = '/inventory/facilities/bin_storage_rules/<%= @bin_location_setup.location_id%>';
              window.close();
            </script>
          }
        else
          params[:id] = @bin_location_setup.id
          edit_bin_location_setup
        end
      end
    rescue
      handle_error("bin location setup record not be updated")
    end
  end

  def delete_bin_location_setup
    begin
      if bin_location_setup = BinLocationSetup.find(params[:id])
        @location_id = bin_location_setup.location_id
        bin_location_setup.destroy
        session[:alert]     = " Record deleted."
        render :inline => %{
            <script>
              window.location.href = '/inventory/facilities/bin_storage_rules/<%= @location_id %>';
            </script>
        }, :layout => 'content'
      end
    rescue
      handle_error("Could not delete bin location setup record")
    end
  end

  def clone_bin_location_setup
    begin
      if bin_location_setup = BinLocationSetup.find(params[:id])
        attrs = bin_location_setup.attributes
        attrs.delete('id')
        new_bin_location_setup = BinLocationSetup.new(attrs)
        @location_id = new_bin_location_setup.location_id
        if new_bin_location_setup.save
          session[:alert]     = " Record cloned successfully."
          render :inline => %{
              <script>
                window.opener.close();
                window.location.href = '/inventory/facilities/bin_storage_rules/<%= @location_id %>';
              </script>
          }, :layout => 'content'
        else
          handle_error("Could not clone bin location setup record")
        end
      end
    rescue
      handle_error("Could not clone bin location setup record")
    end
  end

  def delete_location_setup
    begin
      id = params[:id]
      if id && location_setup = LocationSetup.find(id)
        location_setup.destroy
        session[:alert]     = " Record deleted."
        location            = session[:current_storage_rule_location]
        @location_setups    = location.location_setups
        @child_form_caption = ["child_form3", "storage rules for location " + location.location_code.to_s]
        @can_edit           = authorise(program_name?, 'edit', session[:user_id])
        @can_delete         = authorise(program_name?, 'delete', session[:user_id])
        render :inline => %{
      <% grid            = build_location_setups_grid(@location_setups,@can_edit,@can_delete) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
        }, :layout => 'content'
      end
    rescue

    end
  end

  def commodity_code_combo_changed
    commodity_code = get_selected_combo_value(params)
    session[:bin_location_setup_form][:commodity_code_combo_selection] = commodity_code
    @rmt_variety_codes = RmtVariety.find_by_sql("select distinct rmt_variety_code from rmt_varieties where commodity_code = '#{commodity_code}' ORDER BY rmt_variety_code ASC").map { |g| [g.rmt_variety_code] }
    @rmt_variety_codes.unshift("<empty>")

    render :inline => %{
        <%= select('bin_location_setup', 'rmt_variety_code', @rmt_variety_codes,{:sorted=>true}) %>
        <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_bin_location_setup_rmt_variety_code'/>
        <%= observe_field('bin_location_setup_rmt_variety_code',:update => 'ajax_distributor_cell',:url => {:action => session[:bin_location_setup_form][:rmt_variety_code_observer][:remote_method]},:loading => "show_element('img_bin_location_setup_rmt_variety_code');",:complete => session[:bin_location_setup_form][:rmt_variety_code_observer][:on_completed_js])%>
    }
  end

  def rmt_variety_code_combo_changed
    rmt_variety_code = get_selected_combo_value(params)
    session[:bin_location_setup_form][:rmt_variety_code_combo_selection] = rmt_variety_code
    if(session[:bin_location_setup_form][:rmt_product_type_code_combo_selection])
      @rmt_product_codes = RmtProduct.find_by_sql("select rmt_product_code from rmt_products where variety_code='#{rmt_variety_code}' and commodity_code='#{session[:bin_location_setup_form][:commodity_code_combo_selection]}' and rmt_product_type_code='#{session[:bin_location_setup_form][:rmt_product_type_code_combo_selection].strip}' ORDER BY rmt_product_code").map { |g| [g.rmt_product_code]}
      @rmt_product_codes.unshift("ALL")
    end

    render :inline => %{
      <script>
        <% if session[:bin_location_setup_form][:rmt_product_type_code_combo_selection] %>
          <%= update_element_function(
            "rmt_product_code_cell", :action => :update,
            :content => select('bin_location_setup','rmt_product_code',@rmt_product_codes))
          %>
        <% end %>
      </script>
    }
  end

  def rmt_product_type_code_combo_changed
    rmt_product_type_code = get_selected_combo_value(params)
    session[:bin_location_setup_form][:rmt_product_type_code_combo_selection] = rmt_product_type_code

    #@rmt_product_codes = RmtProduct.find_by_sql("select rmt_product_code from rmt_products where variety_code='#{session[:bin_location_setup_form][:rmt_variety_code_combo_selection]}' and commodity_code='#{session[:bin_location_setup_form][:commodity_code_combo_selection]}' and rmt_product_type_code='#{rmt_product_type_code}' ORDER BY rmt_product_code").map { |g| [g.rmt_product_code]}
    @rmt_product_codes = RmtProduct.find_by_sql("select rmt_product_code from rmt_products where rmt_product_type_code='#{rmt_product_type_code}' ORDER BY rmt_product_code").map { |g| [g.rmt_product_code]}
    @rmt_product_codes.unshift("ALL")

    render :inline => %{
      <script>
        <%= update_element_function(
          "rmt_product_code_cell", :action => :update,
          :content => select('bin_location_setup','rmt_product_code',@rmt_product_codes))
        %>
      </script>
    }
  end

  def parent_location
    child_location = Location.find(params[:id])
    @parent_location = Location.find_by_location_code(child_location.parent_location_code) if child_location.parent_location_code
    if !@parent_location
      flash[:notice] = "'location[" + child_location.location_code + "] does not have a parent'"
      submit_locations_search
    else
      @content_header_caption = "'location tree for location = " + @parent_location.location_code + "'"
      render :inline => %{
                      <% @tree_script = build_locations_tree(@parent_location) %>
                      }, :layout => 'tree'
    end
  end

  def child_locations
    session[:location]      = params[:id]
    @parent_location        = Location.find(session[:location])
    @content_header_caption = "'location tree for location = " + @parent_location.location_code + "'"
    render :inline => %{
                      <% @tree_script = build_locations_tree(@parent_location) %>
                      }, :layout => 'tree'
  end

  def add_child_location
    session[:location]        = params[:id]
    @location                 = Location.find(params[:id])
    @tree_node_content_header = "select child location"
    @hide_content_pane        = false
    @is_menu_loaded_view      = true
    render :inline => %{
                        <%= build_add_child_location_form(@location,'save_child_location','add')%>
                        }, :layout => "tree_node_content"
  end

  def save_child_location
    begin
      @parent_location = Location.find(session[:location])
      @child_location  = Location.find_by_location_code(params[:location][:location_code])
      @child_location.update_attribute(:parent_location_code, @parent_location.location_code).to_s

      flash[:notice] = "location added successfully"
      @node_name     = @child_location.location_code
      @node_type     = "location"
      @node_id       = @child_location.id.to_s
      @tree_name     = "locations"

      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = false %>

                      <% @tree_actions = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>

                      }, :layout => 'tree_node_content'

    rescue
      flash[:notice] = "could not add location"
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = false %>
                      }, :layout => 'tree_node_content'
    end
  end

  def remove_from_parent
    begin
      @child_location = Location.find(params[:id])
      @child_location.update_attribute(:parent_location_code, nil).to_s

      flash[:notice] = "location removed successfully"
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = true %>

                      <% @tree_actions = "window.parent.RemoveNode(null);" %>

                      }, :layout => 'tree_node_content'
    rescue
      puts "BBBBBBBBBBBBB " + $!.to_s
      flash[:notice] = "could not remove location from parent"
      render :inline => %{
                      <% @hide_content_pane = true %>
                      <% @is_menu_loaded_view = false %>
                      }, :layout => 'tree_node_content'
    end
  end

  def delete_and_remove_location
    @remove = true
    delete_location
  end

  def create_and_add_location
    session[:location]        = params[:id]
    @location                 = Location.find(session[:location])

    session[:add_location]    = true
    @tree_node_content_header = "create new location"
    @hide_content_pane        = false
    @is_menu_loaded_view      = true
    render :inline=> %{
                       <%= build_location_form(@location,'create_location',false,'create_location',true)  %>
                       }, :layout => 'tree_node_content'
  end

  #=============================================================
  # Observer Methods
  #=============================================================
  def season_code_combo_changed
    season_code = get_selected_combo_value(params)
    puts " :::: PARAMS :  " + params.to_s
    @location_setup = LocationSetup.new
    @location_setup.order_code = 'ALL'
    session[:location_setup_form][:season_code_combo_selection] = season_code
    puts ":::::: SEASON_CODE : " + season_code.to_s
    if season_code.to_s == "ALL"
      @orders = SeasonOrderQuantity.find_by_sql("SElECT DISTINCT customer_order_number from season_order_quantities").map { |g| [g.customer_order_number] }
    else
      @orders = SeasonOrderQuantity.find_by_sql("SElECT DISTINCT customer_order_number from season_order_quantities where season_code = '#{season_code}'").map { |g| [g.customer_order_number] }
    end
    @orders.unshift("ALL")
    render :inline=>%{
        <%=select('location_setup','order_code',@orders) %>
    }
  end

end