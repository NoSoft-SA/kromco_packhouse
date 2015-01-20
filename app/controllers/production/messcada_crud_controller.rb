class Production::MesscadaCrudController < ApplicationController

  #MM122014 - messcada changes

  def program_name?
    "messcada_crud"
  end

  def bypass_generic_security?
    true
  end

  def reload_main_page(function_name,function_id)
    @url = "/production/messcada_crud/#{function_name}/#{function_id}";
    session[:alert] = "Record created successfully"
    render :inline => %{
                          <script>
                            window.close();
                            window.opener.frames[1].location.href = "<%=@url%>";
                          </script>
                          }, :layout => 'content'
  end

  def main_page(function_name,function_id)
    @url = "/production/messcada_crud/#{function_name}/#{function_id}";
    render :inline => %{
                          <script>
                            parent.location.href = "<%=@url%>";
                          </script>
                          }#, :layout => 'content'
  end

  def update_main_page(function_name,function_id)
    @url = "/production/messcada_crud/#{function_name}/#{function_id}";
    session[:alert] = "Record updated successfully"
    render :inline => %{
                          <script>
                            parent.frames[1].location.href = "<%=@url%>";
                          </script>
                          }#, :layout => 'content'
  end

  def update_page(function_name,function_id)
    @url = "/production/messcada_crud/#{function_name}/#{function_id}";
    session[:alert] = "Record updated successfully"
    render :inline => %{
                          <script>
                            window.close();
                            parent.frames[1].location.href = "<%=@url%>";
                          </script>
                          }#, :layout => 'content'
  end

  def reload_page(function_name,function_id,message,frame_id)
    @url = "/production/messcada_crud/#{function_name}/#{function_id}";
    @frame_id = frame_id
    session[:alert] = "#{message}"
    render :inline => %{
                          <script>
                            window.close();
                            window.opener.document.location.href = "<%=@url%>";
                            window.opener.frames[1].frames["<%=@frame_id%>"].location.reload(true);
                          </script>
                          }, :layout => 'content'
  end

  def reload_page_grids(function_name,function_id,message,frame_id)
    @url = "/production/messcada_crud/#{function_name}/#{function_id}";
    @frame_id = frame_id
    session[:alert] = "#{message}"
    render :inline => %{
                          <script>
                            window.close();
                            window.opener.frames[1].frames["<%=@frame_id%>"].location.href = "<%=@url%>";
                          </script>
                          }, :layout => 'content'
  end

  #mescada facilities

  def new_facility
    return if authorise_for_web('messcada_crud', 'create')== false
    render_new_facility
  end

  def render_new_facility
    render :inline => %{
		<% @content_header_caption = "'create new facility'"%>

		<%= build_facility_form(@facility,'create_facility','create_facility',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_facility
    begin
      @facility = MesscadaFacility.new(params[:facility])
      if @facility.save
        session[:facility_id] = @facility.id
        session[:facility_code] = @facility.code
        update_main_page("edit_facility",session[:facility_id])
      else
        @is_create_retry = true
        render_new_facility
      end
    rescue
      handle_error("facility could not be created")
    end
  end

  def list_facilities
      query = "select * from  messcada_facilities order by code"
      @facilities = MesscadaFacility.find_by_sql(query)
      render_facilities_list
  end

  def render_facilities_list
    @can_edit = true
    @can_delete = true

    render :inline => %{
      <% grid            = build_facilities_grid(@facilities,@can_edit,@can_delete,@is_select) %>
      <% grid.caption    = 'list of all facilities' %>
      <% grid.height = '200' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_facility
    session[:is_edit] = true
    id = params[:id]
    if id && @facility = MesscadaFacility.find(id)
      session[:facility_id]  = @facility.id
      session[:facility_code] = @facility.code
      render_edit_facility
    end
  end

  def render_edit_facility
    render :inline => %{
		<% @content_header_caption = "'edit facility'"%>

		<%= build_facility_form(@facility,'update_facility','update_facility',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_facility
    id = params[:facility][:id]
    if id && @facility = MesscadaFacility.find(id)
      ActiveRecord::Base.transaction do
        @facility.update_attributes(params[:facility])
        # @facility.save
      end
    end
    if @facility.errors.empty?
      update_main_page("list_facilities",session[:facility_id])
    else
      render_edit_facility
    end

  end

  def delete_facility
    begin
      id = params[:id]
      if id && facility = MesscadaFacility.find(id)
        facility.destroy_servers
        facility.destroy
        render :inline => %{
                            <script>
                            alert('Record removed');
                            window.close();
                             window.opener.frames[1].location.reload(true);
                            </script>
                               }, :layout => 'content'
      end
    rescue
      handle_error("Facility could not be deleted")
    end
  end

  def link_to_facility_code
    facility_code = params[:id]
    if facility_code && @facility = MesscadaFacility.find_by_code(facility_code)
      render_edit_facility
    end
  end

  #messcada_servers

  def new_server
    session[:belongs_to_facility] = false
    render_new_server
  end

  def add_servers
    session[:belongs_to_facility] = true
    render_new_server
  end

  def render_new_server
    render :inline => %{
		<% @content_header_caption = "'create new server'"%>

		<%= build_server_form(@server,'create_server','create_server',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_server
    begin
      @server = MesscadaServer.new(params[:server])

      if session[:belongs_to_facility]
        @server.facility_id = session[:facility_id]
        @server.facility_code = session[:facility_code]
        @server.run_before_save
      end

      if @server.save
        id = @server.id
        update_main_page("edit_server",id)
      else
        @is_create_retry = true
        render_new_server
      end
    rescue
      handle_error("server could not be created")
    end
  end

  def list_servers
    @is_select = false
    session[:is_edit] = false
    if params[:id] == "" or params[:id] == nil
      query = "select * from  messcada_servers MS order by MS.code"
    else
      query = "select * from  messcada_servers MS
              where MS.facility_id = #{params[:id]}
              order by MS.code"
      session[:is_edit] = true
    end
    @servers = MesscadaServer.find_by_sql(query)
    render_servers_list
  end

  def render_servers_list
    @can_edit = true
    @can_delete = true
    @is_edit = session[:is_edit]

    if session[:is_edit]
      session[:child_form_id]=""
      session[:child_form_header_link_field] = ""
      session[:child_form_header_link_field] = "<a style='font: bold 11px arial;text-decoration:underline;cursor:pointer;padding-bottom: 2px;padding-left: 2px;' id='#{request.host_with_port}/production/messcada_crud/add_messcada_servers' onclick='javascript:parent.call_open_window(this);' >add_existing_messcada_servers</a>"
      session[:child_form_id] = "messcada_servers"
    end

    render :inline => %{
      <% @child_form_caption = [session[:child_form_id], session[:child_form_header_link_field]] %>
      <% grid            = build_servers_grid(@servers,@can_edit,@can_delete,@is_edit,@is_select) %>
      <% grid.caption    = 'list of all servers' %>
      <% grid.height = '200' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_server
    id = params[:id]
    if id && @server = MesscadaServer.find(id)
      session[:server_id] = @server.id
      session[:server_code] = @server.code
      render_active_edit_server
    end
  end

  def render_edit_server
    id = params[:id]
    if id && @server = MesscadaServer.find(id)
      session[:server_id] = @server.id
      session[:server_code] = @server.code
    end
    if session[:is_edit]
      main_page("edit_server",id)
    else
      render_active_edit_server
    end
  end

  def render_active_edit_server
    render :inline => %{
		<% @content_header_caption = "'edit server'"%>

		<%= build_server_form(@server,'update_server','update_server',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_server

    id = params[:server][:id]
    if id && @server = MesscadaServer.find(id)
      ActiveRecord::Base.transaction do
        @server.update_attributes(params[:server])
        # @server.run_before_save
        # @server.save
      end
    end
    if @server.errors.empty?
      facility_code = @server.facility_code
      if session[:is_edit]
        update_main_page("link_to_facility_code",facility_code)
      else
        update_main_page("list_servers",nil)
      end
    else
      render_edit_server
    end

  end

  def delete_server
    begin
      id = params[:id]
      if id && server = MesscadaServer.find(id)
        server.destroy_clusters
        server.destroy
        render :inline => %{
                            <script>
                            alert('Record removed');
                            window.close();
                             window.opener.frames[1].location.reload(true);
                            </script>
                               }, :layout => 'content'
      end
    rescue
      handle_error("Server could not be deleted")
    end
  end

  def link_to_server_code
    server_code = params[:id]
    if server_code && @server = MesscadaServer.find_by_code(server_code)
      render_active_edit_server
    end
  end

  def add_messcada_servers
    @is_select = true
    session[:belongs_to_facility] = true
    query = "select * from  messcada_servers MS
            where (MS.facility_id IS NULL or MS.facility_id != #{session[:facility_id]})
            and MS.code NOT IN
            (
              select MS.code from  messcada_servers MS
              where  MS.facility_id = #{session[:facility_id]}
            )
            order by MS.code"
    @servers = MesscadaServer.find_by_sql(query)
    session[:messcada_servers] =  @servers
    render_servers_list
  end

  def selected_servers
    messcada_servers = session[:messcada_servers]
    selected_messcada_servers = selected_records?(messcada_servers,nil,nil)
    MesscadaServer.save_selected_messcada_servers(selected_messcada_servers,session[:facility_id])
    reload_main_page("link_to_facility_code",session[:facility_code])
  end

  #messcada_clusters

  def new_cluster
    render_new_cluster
  end

  def render_new_cluster
    render :inline => %{
		<% @content_header_caption = "'create new cluster'"%>

		<%= build_cluster_form(@cluster,'create_cluster','create_cluster',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_cluster
    begin
      @cluster = MesscadaCluster.new(params[:cluster])
      @cluster.server_id = session[:server_id]
      @cluster.server_code = session[:server_code]
      if @cluster.save
        server_code = @cluster.server_code
        main_page("link_to_server_code",server_code)
      else
        @is_create_retry = true
        render_new_cluster
      end
    rescue
      handle_error("cluster could not be created")
    end
  end

  def list_clusters
    session[:is_edit] = false
    if params[:id] == "" or params[:id] == nil
      query = "select * from  messcada_clusters MC order by MC.code"
    else
      query = "select * from  messcada_clusters MC
              where MC.server_id = #{params[:id]}
              order by MC.code"
      session[:is_edit] = true
    end
    @clusters = MesscadaCluster.find_by_sql(query)
    render_clusters_list
  end

  def render_clusters_list
    @can_edit = true
    @can_delete = true
    @is_edit = session[:is_edit]

    if session[:is_edit]
      session[:child_form_id]=""
      session[:child_form_header_link_field] = ""
      session[:child_form_header_link_field] = "<a style='font: bold 11px arial;text-decoration:underline;cursor:pointer;padding-bottom: 2px;padding-left: 2px;' id='#{request.host_with_port}/production/messcada_crud/add_messcada_peripherals' onclick='javascript:parent.call_open_window(this);' >add_existing_messcada_peripherals</a>"
      session[:child_form_id] = "messcada_peripherals"
    end

    render :inline => %{
      <% @child_form_caption = [session[:child_form_id], session[:child_form_header_link_field]] %>
      <% grid            = build_clusters_grid(@clusters,@can_edit,@can_delete,@is_edit,@is_select) %>
      <% grid.caption    = 'list of all clusters' %>
      <% grid.height = '200' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_cluster
    id = params[:id]
    if id && @cluster = MesscadaCluster.find(id)
      session[:cluster_id] = @cluster.id
      session[:cluster_code] = @cluster.code
      render_active_edit_cluster
    end
  end

  def render_edit_cluster
    id = params[:id]
    if id && @cluster = MesscadaCluster.find(id)
      session[:cluster_id] = @cluster.id
      session[:cluster_code] = @cluster.code
    end
    if session[:is_edit]
      main_page("edit_cluster",id)
    else
      render_active_edit_cluster
    end
  end

  def render_active_edit_cluster
    render :inline => %{
		<% @content_header_caption = "'edit cluster'"%>

		<%= build_cluster_form(@cluster,'update_cluster','update_cluster',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_cluster

    id = params[:cluster][:id]
    if id && @cluster = MesscadaCluster.find(id)
      ActiveRecord::Base.transaction do
        @cluster.update_attributes(params[:cluster])
        # @cluster.save
      end
    end
    if @cluster.errors.empty?
      server_code = @cluster.server_code
      if session[:is_edit]
        update_main_page("link_to_server_code",server_code)
      else
        update_main_page("list_clusters",nil)
      end
    else
      render_edit_cluster
    end

  end

  def delete_cluster
    begin
      id = params[:id]
      if id && cluster = MesscadaCluster.find(id)
        cluster.destroy_modules
        cluster.destroy
        render :inline => %{
                            <script>
                            alert('Record removed');
                            window.close();
                             window.opener.frames[1].location.reload(true);
                            </script>
                               }, :layout => 'content'
      end
    rescue
      handle_error("Cluster could not be deleted")
    end
  end

  def link_to_cluster_code
    cluster_code = params[:id]
    if cluster_code && @cluster = MesscadaCluster.find_by_code(cluster_code)
      render_active_edit_cluster
    end
  end

  #messcada_modules

  def new_module
    render_new_module
  end

  def render_new_module
    render :inline => %{
		<% @content_header_caption = "'create new module'"%>

		<%= build_module_form(@modules,'create_module','create_module',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_module
    begin
      @modules = MesscadaModule.new(params[:modules])
      @modules.cluster_id = session[:cluster_id]
      @modules.cluster_code = session[:cluster_code]
      if @modules.save
         cluster_code = @modules.cluster_code
         main_page("link_to_cluster_code",cluster_code)
      else
        @is_create_retry = true
        render_new_module
      end
    rescue
      handle_error("module could not be created")
    end
  end

  def list_modules
    session[:is_edit] = false
    if params[:id] == "" or params[:id] == nil
      query = "select * from  messcada_modules MM order by MM.code"
    else
      query = "select * from  messcada_modules MM
              where MM.cluster_id = #{params[:id]}
              order by MM.code"
      session[:is_edit] = true
    end
    @modules = MesscadaModule.find_by_sql(query)
    render_modules_list
  end

  def render_modules_list
    @can_edit = true
    @can_delete = true
    @is_edit = session[:is_edit]

    if session[:is_edit]
      session[:child_form_id]=""
      session[:child_form_header_link_field] = ""
      session[:child_form_header_link_field] = "<a style='font: bold 11px arial;text-decoration:underline;cursor:pointer;padding-bottom: 2px;padding-left: 2px;' id='#{request.host_with_port}/production/messcada_crud/add_messcada_peripherals' onclick='javascript:parent.call_open_window(this);' >add_existing_messcada_peripherals</a>"
      session[:child_form_id] = "messcada_peripherals"
    end

    render :inline => %{
      <% @child_form_caption = [session[:child_form_id], session[:child_form_header_link_field]] %>
      <% grid            = build_modules_grid(@modules,@can_edit,@can_delete,@is_edit,@is_select) %>
      <% grid.caption    = 'list of all modules' %>
      <% grid.height = '200' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_module
    id = params[:id]
    session[:field_name] = ""
    session[:field_value] = ""
    if id && @modules = MesscadaModule.find(id)
      session[:module_id] = @modules.id
      session[:module_code] = @modules.code
      session[:field_name] = "module_id"
      session[:field_value] = session[:module_id]
      render_active_edit_module
    end
  end

  def render_edit_module
    id = params[:id]
    session[:field_name] = ""
    session[:field_value] = ""
    if id && @modules = MesscadaModule.find(id)
      session[:module_id] = @modules.id
      session[:module_code] = @modules.code
      session[:field_name] = "module_id"
      session[:field_value] = session[:module_id]
    end
    if session[:is_edit]
      main_page("edit_module",id)
    else
      render_active_edit_module
    end
  end

  def render_active_edit_module
    render :inline => %{
		<% @content_header_caption = "'edit module'"%>

		<%= build_module_form(@modules,'update_module','update_module',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_module

    id = params[:modules][:id]
    if id && @modules = MesscadaModule.find(id)
      ActiveRecord::Base.transaction do
        @modules.update_attributes(params[:modules])
        # @modules.save
      end
    end
    if @modules.errors.empty?
      cluster_code = @modules.cluster_code
      if session[:is_edit]
        update_main_page("link_to_cluster_code",cluster_code)
      else
        update_main_page("list_modules",nil)
      end
    else
      render_edit_module
    end
  end

  def delete_module
    begin
      id = params[:id]
      if id && modules = MesscadaModule.find(id)
        modules.destroy_peripherals
        modules.destroy
        render :inline => %{
                            <script>
                            alert('Record removed');
                            window.close();
                             window.opener.frames[1].location.reload(true);
                            </script>
                               }, :layout => 'content'
      end
    rescue
      handle_error("Module could not be deleted")
    end
  end

  def link_to_module_code
    module_code = params[:id]
    if module_code && @modules = MesscadaModule.find_by_code(module_code)
      render_active_edit_module
    end
  end

  #messcada_peripherals

  def new_peripheral
    session[:belongs_to_module] = false
    render_new_peripheral
  end

  def add_peripherals
    session[:belongs_to_module] = true
    render_new_peripheral
  end

  def render_new_peripheral
    render :inline => %{
		<% @content_header_caption = "'create new peripheral'"%>

		<%= build_peripheral_form(@peripheral,'create_peripheral','create_peripheral',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_peripheral
    begin
      @peripheral = MesscadaPeripheral.new(params[:peripheral])

      if session[:belongs_to_module]
        @peripheral.module_id = session[:module_id]
        @peripheral.module_code = session[:module_code]
        @peripheral.run_before_save
      end

      if @peripheral.save
        module_code = @peripheral.module_code
        main_page("link_to_module_code",module_code)
      else
        @is_create_retry = true
        render_new_peripheral
      end
    rescue
      handle_error("peripheral could not be created")
    end
  end

  def list_peripherals
    session[:is_edit] = false
    if params[:id] == "" or params[:id] == nil
      query = "select * from  messcada_peripherals MP
              order by MP.code"
    else
      query = "select * from  messcada_peripherals MP
                where " + session[:field_name].to_s + " = '#{params[:id]}'
                order by MP.code"
      session[:is_edit] = true
    end
    @peripherals = MesscadaPeripheral.find_by_sql(query)
    render_peripherals_list
  end

  def render_peripherals_list
    @can_edit = true
    @can_delete = true
    @is_edit = session[:is_edit]
    if session[:is_edit]
      session[:child_form_id]=""
      session[:child_form_header_link_field] = ""
      session[:child_form_header_link_field] = "<a style='font: bold 11px arial;text-decoration:underline;cursor:pointer;padding-bottom: 2px;padding-left: 2px;' id='#{request.host_with_port}/production/messcada_crud/add_messcada_peripherals' onclick='javascript:parent.call_open_window(this);' >add_existing_messcada_peripherals</a>"
      session[:child_form_id] = "messcada_peripherals"
    end

    render :inline => %{
      <% @child_form_caption = [session[:child_form_id], session[:child_form_header_link_field]] %>
      <% grid            = build_peripherals_grid(@peripherals,@can_edit,@can_delete,@is_edit,@is_select) %>
      <% grid.caption    = 'list of all peripherals' %>
      <% grid.height = '200' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_peripheral
    id = params[:id]
    if id && @peripheral = MesscadaPeripheral.find(id)
      session[:peripheral_id] = @peripheral.id
      session[:peripheral_code] = @peripheral.code
      render_active_edit_peripheral
    end
  end

  def render_edit_peripheral
    id = params[:id]
    if id && @peripheral = MesscadaPeripheral.find(id)
      session[:peripheral_id] = @peripheral.id
      session[:peripheral_code] = @peripheral.code
    end
    if session[:is_edit]
      main_page("edit_peripheral",id)
    else
      render_active_edit_peripheral
    end
  end

  def render_active_edit_peripheral
    render :inline => %{
		<% @content_header_caption = "'edit peripheral'"%>

		<%= build_peripheral_form(@peripheral,'update_peripheral','update_peripheral',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_peripheral

    id = params[:peripheral][:id]
    if id && @peripheral = MesscadaPeripheral.find(id)
      ActiveRecord::Base.transaction do
        @peripheral.update_attributes(params[:peripheral])
        # @peripheral.run_before_save
        # @peripheral.save
      end
    end
    if @peripheral.errors.empty?
      module_code = @peripheral.module_code
      if session[:is_edit]
        update_main_page("link_to_module_code",module_code)
      else
        update_main_page("list_peripherals",nil)
      end
    else
      render_edit_peripheral
    end
  end

  def delete_peripheral
    begin
      id = params[:id]
      if id && peripherals = MesscadaPeripheral.find(id)
        peripherals.destroy_peripheral_printers
        peripherals.destroy
        render :inline => %{
                            <script>
                            alert('Record removed');
                            window.close();
                             window.opener.frames[1].location.reload(true);
                            </script>
                               }, :layout => 'content'
      end
    rescue
      handle_error("Peripherals could not be deleted")
    end
  end

  def link_to_peripheral_code
    peripheral_code = params[:id]
    if peripheral_code && @peripheral = MesscadaPeripheral.find_by_code(peripheral_code)
      render_active_edit_peripheral
    end
  end

  def add_messcada_peripherals
    @is_select = true
    session[:belongs_to_module] = true #???
    query = "select  * from  messcada_peripherals MP
            where (MP." + session[:field_name].to_s + " IS NULL OR  MP."  + session[:field_name].to_s +  " != '#{session[:field_value]}')
            and MP.code NOT IN
            (
                select MP.code from  messcada_peripherals MP
                where MP." + session[:field_name].to_s + " = '#{session[:field_value]}'
            )
            order by MP.code"

    @peripherals = MesscadaPeripheral.find_by_sql(query)
    session[:messcada_peripherals] =  @peripherals
    render_peripherals_list
  end

  def selected_peripherals
    messcada_peripherals = session[:messcada_peripherals]
    selected_messcada_peripherals = selected_records?(messcada_peripherals,nil,nil)
    MesscadaPeripheral.save_selected_messcada_peripherals(selected_messcada_peripherals,session[:field_name],session[:field_value])
    if session[:field_name].to_s == "module_id"
      reload_main_page("link_to_module_code",session[:module_code])
    else
      reload_main_page("link_to_" + session[:field_name].to_s + "",session[:field_value])
    end
  end

  #messcada_peripheral_printers

  def new_peripheral_printer
    render_new_peripheral_printer
  end

  def render_new_peripheral_printer
    render :inline => %{
		<% @content_header_caption = "'create new peripheral printer'"%>

		<%= build_peripheral_printer_form(@peripheral_printer,'create_peripheral_printer','create_peripheral_printer',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_peripheral_printer
    begin
      @peripheral_printer = MesscadaPeripheralPrinter.new(params[:peripheral_printer])
      @peripheral_printer.peripheral_id = session[:peripheral_id]
      @peripheral_printer.peripheral_code = session[:peripheral_code]
      if @peripheral_printer.save
        peripheral_code = @peripheral_printer.peripheral_code
        main_page("link_to_peripheral_code",peripheral_code)
      else
        @is_create_retry = true
        render_new_peripheral_printer
      end
    rescue
      handle_error("peripheral printer could not be created")
    end
  end

  def list_peripheral_printers
    session[:is_edit] = false
    if params[:id] == "" or params[:id] == nil
      query = "select MPP.*,MP.module_code,MP.cluster_code,MP.server_code,MP.facility_code from  messcada_peripheral_printers MPP
              inner join messcada_peripherals MP on MPP.peripheral_id = MP.id
              order by MPP.id"
    else
      query = "select MPP.*,MP.module_code,MP.cluster_code,MP.server_code,MP.facility_code from  messcada_peripheral_printers MPP
              inner join messcada_peripherals MP on MPP.peripheral_id = MP.id
              where MPP.peripheral_id = #{params[:id]}
              order by MPP.id"
      session[:is_edit] = true
    end
    @peripheral_printers = MesscadaPeripheral.find_by_sql(query)
    render_peripheral_printers_list
  end

  def render_peripheral_printers_list
    @can_edit = true
    @can_delete = true
    @is_edit = session[:is_edit]
    render :inline => %{
      <% grid            = build_peripheral_printers_grid(@peripheral_printers,@can_edit,@can_delete,@is_edit) %>
      <% grid.caption    = 'list of all peripheral printers' %>
      <% grid.height = '200' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_peripheral_printer
    id = params[:id]
    if id && @peripheral_printer = MesscadaPeripheralPrinter.find(id)
      session[:peripheral_printer_id] = @peripheral_printer.id
      render_active_edit_peripheral_printer
    end
  end

  def render_edit_peripheral_printer
    id = params[:id]
    if id && @peripheral_printer = MesscadaPeripheralPrinter.find(id)
      session[:peripheral_printer_id] = @peripheral_printer.id
      if session[:is_edit]
        main_page("edit_peripheral_printer",id)
      else
        render_active_edit_peripheral_printer
      end
    end
  end

  def render_active_edit_peripheral_printer
    render :inline => %{
		<% @content_header_caption = "'edit peripheral printer'"%>

		<%= build_peripheral_printer_form(@peripheral_printer,'update_peripheral_printer','update_peripheral_printer',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_peripheral_printer

    id = params[:peripheral_printer][:id]
    if id && @peripheral_printer = MesscadaPeripheralPrinter.find(id)
      ActiveRecord::Base.transaction do
        @peripheral_printer.update_attributes(params[:peripheral_printer])
        # @peripheral_printer.save
      end
    end
    if @peripheral_printer.errors.empty?
      peripheral_code = @peripheral_printer.peripheral_code
      if session[:is_edit]
        update_main_page("link_to_peripheral_code",peripheral_code)
      else
        update_main_page("list_peripheral_printers",nil)
      end
    else
      render_edit_peripheral_printer
    end
  end

  def delete_peripheral_printer
    begin
      id = params[:id]
      if id && peripheral_printers = MesscadaPeripheralPrinter.find(id)
        peripheral_printers.destroy
        render :inline => %{
                            <script>
                            alert('Record removed');
                            window.close();
                             window.opener.frames[1].location.reload(true);
                            </script>
                               }, :layout => 'content'
      end
    rescue
      handle_error("Peripheral printers could not be deleted")
    end
  end

  def link_to_peripheral_printer_code
    peripheral_printer_code = params[:id]
    if peripheral_printer_code && @peripheral_printer = MesscadaPeripheralPrinter.find_by_code(peripheral_printer_code)
      render_active_edit_peripheral_printer
    end
  end

end