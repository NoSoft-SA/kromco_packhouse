class  PartyManager::TransporterController < ApplicationController

  def program_name?
    "farm"
  end

  def bypass_generic_security?
    true
  end

  def list_transporters
    return if authorise_for_web(program_name?,'read') == false
    store_last_grid_url

    if params[:page]!= nil

      session[:transporters_page] = params['page']

      render_list_transporters

      return
    else
      session[:transporters_page] = nil
    end

    list_query = "@transporter_pages = Paginator.new self, Transporter.count, @@page_size,@current_page
   @transporters = Transporter.find(:all, :select=>'transporters.*, p.party_name as haulier, cmp.contact_method_code as contact_number',
         :limit => @transporter_pages.items_per_page,
         :joins => \"join parties_roles p on p.id=transporters.haulier_parties_role_id
                    left outer join contact_methods_parties cmp on (cmp.party_name = p.party_name and cmp.party_type_name = p.party_type_name and cmp.contact_method_type_code='Mobile' )\",
         :offset => @transporter_pages.current.offset)"
    session[:query] = list_query
    render_list_transporters
  end


  def render_list_transporters
    @pagination_server = "list_transporters"
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:transporters_page]
    @current_page = params['page']||= session[:transporters_page]
    @transporters =  eval(session[:query]) if !@transporters
    render :inline => %{
    <% grid = build_transporter_grid(@transporters,@can_edit,@can_delete)%>
    <% grid.caption = 'List of all transporters'%>
    <% @header_content = grid.build_grid_data %>

    <% @pagination = pagination_links(@transporter_pages) if @transporter_pages != nil %>
    <%= grid.render_html %>
    <%= grid.render_grid %>
  },:layout => 'content'
  end

  def search_transporters_flat
    return if authorise_for_web(program_name?,'read')== false
    @is_flat_search = true
    render_transporter_search_form
  end

  def render_transporter_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#   render (inline) the search form
    render :inline => %{
    <% @content_header_caption = "'search  transporters'"%>

    <%= build_transporter_search_form(nil,'submit_transporters_search','submit_transporters_search',@is_flat_search)%>

    }, :layout => 'content'
  end


  def submit_transporters_search
    store_last_grid_url
    @transporters = dynamic_search(params[:transporter] ,'transporters','Transporter')
    if @transporters.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_transporter_search_form
    else
      render_list_transporters
    end
  end


  def delete_transporter
    return if authorise_for_web(program_name?,'delete')== false
    if params[:page]
      session[:transporters_page] = params['page']
      render_list_transporters
      return
    end
    id = params[:id]
    if id && transporter = Transporter.find(id)
      transporter.destroy
      session[:alert] = ' Record deleted.'
      # render_list_transporters
      redirect_to_last_grid
    end
  rescue
    handle_error('record could not be deleted')
  end

  def new_transporter
    return if authorise_for_web(program_name?,'create')== false
    # store_list_as_grid_url # UNCOMMENT if this action is called directly (i.e. from a menu, not from a grid)
    render_new_transporter
  end

  def create_transporter
    @transporter = Transporter.new(params[:transporter])
    if @transporter.save
      # redirect_to_index("new record created successfully","'create successful'")
      flash[:notice] = 'new record created successfully'
      render :inline => %{  <script>
                            window.close();
                             window.opener.frames[1].location.reload(true);
                            </script>
                        }, :layout => 'content'
    else
      @is_create_retry = true
      render_new_transporter
    end
  rescue
    handle_error('record could not be created')
  end

  def render_new_transporter
#   render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new transporter'"%>

    <%= build_transporter_form(@transporter,'create_transporter','create_transporter',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def haulier_search_combo_changed
    haulier_id = get_selected_combo_value(params)
    @contact_number = ''
    if haulier_id
      haulier_contact = PartiesRole.find(:first, :select => "cmp.contact_method_code",
                                         :conditions => "cmp.contact_method_type_code='Mobile' and parties_roles.id=#{haulier_id}",
                                         :joins => "join contact_methods_parties cmp on (cmp.party_name = parties_roles.party_name and cmp.party_type_name = parties_roles.party_type_name)")
      @contact_number = haulier_contact.contact_method_code if(haulier_contact)

    end
    render :inline => %{
      <%= @contact_number %>
   }
  end

  def edit_transporter
    return if authorise_for_web(program_name?,'edit')==false
    id = params[:id]
    if id && @transporter = Transporter.find(:first,:select=>"transporters.*, cmp.contact_method_code as contact_number", :conditions=>"transporters.id=#{id}",
                                             :joins=>"join parties_roles p on p.id=transporters.haulier_parties_role_id
                    left outer join contact_methods_parties cmp on (cmp.party_name = p.party_name and cmp.party_type_name = p.party_type_name and cmp.contact_method_type_code='Mobile' )")
      render_edit_transporter
    end
  end

  def list_transporter_rates
    @child_form_caption = ["rates", "transporter rates"]
    return if authorise_for_web(program_name?,'read') == false
    store_last_grid_url

    if params[:page]!= nil

      session[:transporter_rates_page] = params['page']

      render_list_transporter_rates

      return
    else
      session[:transporter_rates_page] = nil
    end

    list_query = "@transporter_rate_pages = Paginator.new self, TransporterRate.count, @@page_size,@current_page
   @transporter_rates = TransporterRate.find(:all,:select=>'transporter_rates.*, c.city_name, c.city_code',:conditions=>'transporter_id=#{params[:id]}',
         :joins => 'join cities c on c.id=transporter_rates.city_id',
         :limit => @transporter_rate_pages.items_per_page,
         :offset => @transporter_rate_pages.current.offset)"
    session[:query] = list_query
    render_list_transporter_rates
  end

  def render_list_transporter_rates
    @pagination_server = "list_transporter_rates"
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:transporter_rates_page]
    @current_page = params['page']||= session[:transporter_rates_page]
    @transporter_rates =  eval(session[:query]) if !@transporter_rates
    render :inline => %{
    <% grid = build_transporter_rate_grid(@transporter_rates,@can_edit,@can_delete)%>
    <% grid.caption = 'List of all transporter_rates'%>
    <% @header_content = grid.build_grid_data %>
    <% @pagination = pagination_links(@transporter_rate_pages) if @transporter_rate_pages != nil %>
    <%= grid.render_html %>
    <%= grid.render_grid %>
  },:layout => 'content'
  end

  def new_transporter_rate
    return if authorise_for_web(program_name?,'create')== false
    # store_list_as_grid_url # UNCOMMENT if this action is called directly (i.e. from a menu, not from a grid)
    @transporter_rate = TransporterRate.new({:transporter_id=>params[:id]})
    render_new_transporter_rate
  end

  def create_transporter_rate
    @transporter_rate = TransporterRate.new(params[:transporter_rate])
    if @transporter_rate.save
      # redirect_to_index("new record created successfully","'create successful'")
      flash[:notice] = 'new record created successfully'
      render :inline => %{  <script>
                            window.close();
                             window.opener.frames[0].location.reload(true);
                            </script>
                        }, :layout => 'content'
    else
      @is_create_retry = true
      render_new_transporter_rate
    end
  rescue
    handle_error('record could not be created')
  end

  def render_new_transporter_rate
#   render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new transporter_rate'"%>

    <%= build_transporter_rate_form(@transporter_rate,'create_transporter_rate','create_transporter_rate',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def render_edit_transporter
#   render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit transporter'"%>

    <%= build_transporter_form(@transporter,'update_transporter','update_transporter',true)%>

    }, :layout => 'content'
  end

  def update_transporter
    id = params[:transporter][:id]
    if id && @transporter = Transporter.find(id)
      if @transporter.update_attributes(params[:transporter])
        # @transporters = eval(session[:query])
        flash[:notice] = 'record saved'
        # render_list_transporters
        redirect_to_last_grid
      else
        render_edit_transporter
      end
    end
  rescue
    handle_error('record could not be saved')
  end

  def search_dm_transporters
    return if authorise_for_web(program_name?,'read')== false
    dm_session['se_layout']              = 'content'
    @content_header_caption              = "'Search Transporters'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form('search_transporters.yml', 'search_dm_transporters_grid')
  end


  def search_dm_transporters_grid
    store_last_grid_url
    @transporters = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    @can_edit        = authorise(program_name?, 'edit', session[:user_id])
    @can_delete      = authorise(program_name?, 'delete', session[:user_id])
    @stat            = dm_session[:search_engine_query_definition]
    @columns_list    = dm_session[:columns_list]
    @grid_configs    = dm_session[:grid_configs]

    render :inline => %{
      <% grid            = build_transporter_dm_grid(@transporters, @stat, @columns_list, @can_edit, @can_delete, @grid_configs) %>
      <% grid.caption    = 'Transporters' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end

  def edit_transporter_rate
    return if authorise_for_web(program_name?,'edit')==false
    id = params[:id]
    if id && @transporter_rate = TransporterRate.find(id)
      render_edit_transporter_rate
    end
  end


  def render_edit_transporter_rate
#   render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit transporter_rate'"%>

    <%= build_transporter_rate_form(@transporter_rate,'update_transporter_rate','update_transporter_rate',true)%>

    }, :layout => 'content'
  end

  def update_transporter_rate
    begin
      id = params[:transporter_rate][:id]
      if id && @transporter_rate = TransporterRate.find(id)
        old_rate = @transporter_rate.rate
        if @transporter_rate.update_attribute(:rate, params[:transporter_rate][:rate])
          if(old_rate != params[:transporter_rate][:rate].to_d)
            LogDataChange.create!(:user_name => session[:user_id].user_name,
                                  :ref_nos => @transporter_rate.transporter.parties_role.party_name,
                                  :notes          => "#{@transporter_rate.city.id},#{old_rate},#{params[:transporter_rate][:rate].to_d}",
                                  :type_of_change => 'TRANSPORTER_RATE_CHANGE')
          end

          flash[:notice] = 'record saved'
          render :inline => %{
                            <script>
                             window.close();
                             window.opener.frames[0].location.reload(true);
                            </script>
                        }, :layout => 'content'
        else
          render_edit_transporter_rate
        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

  def delete_transporter_rate
    return if authorise_for_web(program_name?,'delete')== false
    if params[:page]
      session[:transporter_rates_page] = params['page']
      render_list_transporter_rates
      return
    end
    id = params[:id]
    if id && transporter_rate = TransporterRate.find(id)
      transporter_rate.destroy
      session[:alert] = ' Record deleted.'
      # render_list_transporter_rates
      redirect_to_last_grid
    end
  rescue
    handle_error('record could not be deleted')
  end

  def view_rate_change_logs
    data_changes = LogDataChange.find(:all,:conditions=>"type_of_change='TRANSPORTER_RATE_CHANGE' and t.id=#{params[:id]}",
                                          :select=>"log_data_changes.notes ||','|| log_data_changes.created_at as changes",
                                          :joins=>"join parties_roles p on p.party_name=ref_nos
                                                   join transporters t on t.haulier_parties_role_id=p.id",:order => "log_data_changes.created_at desc")

    @rate_change_logs = []
    data_changes.each do |m|
      vals = m.changes.split(',')
      city = City.find(vals[0])
      @rate_change_logs << {'city_code' => city.city_code, 'city_name' => city.city_name, 'rate_from' => vals[1], 'rate_to' => vals[2], 'created_at' => vals[3]}
    end

    render :inline => %{
    <% grid = build_rate_change_logs_grid(@rate_change_logs)%>
    <% @header_content = grid.build_grid_data %>
    <% grid.group_fields     = ['city_code'] %>
    <% grid.grouped      = true %>
    <% grid.height      = '400' %>
    <%= grid.render_html %>
    <%= grid.render_grid %>
    }, :layout => 'content'
  end

end
