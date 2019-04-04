class  Tools::EdiController < ApplicationController

  # require 'uri'
  require 'cgi'

  layout 'content'

  def program_name?
    "edi"
  end

  def bypass_generic_security?
    true
  end

  def list_org_hubs
    render_list_edi_org_hubs
  end

  def render_list_edi_org_hubs
    @edi_org_hubs = EdiOrgHub.find(:all, :order => 'organization_code, flow_type')
    render :inline => %{
      <% grid            = build_edi_org_hub_grid(@edi_org_hubs,true,true) %>
      <% grid.caption    = "List of all EDI Organisation default hub addresses (Reguired for #{EdiOutDestination::NEED_ORG_HUBS_FOR.join(', ')})" %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_edi_org_hub
    return if authorise_for_web(program_name?,'edit')==false 
    id = params[:id]
    if id && @edi_org_hub = EdiOrgHub.find(id)
      render_edit_edi_org_hub

    end
  end

  def render_edit_edi_org_hub
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit EdI Org Hub'"%> 

    <%= build_edi_org_hub_form(@edi_org_hub,'update_edi_org_hub','update_edi_org_hub',true)%>

    }, :layout => 'content'
  end

  def update_edi_org_hub
    begin
      id = params[:edi_org_hub][:id]
      if id && @edi_org_hub = EdiOrgHub.find(id)
        if @edi_org_hub.update_attributes(params[:edi_org_hub])
          flash[:notice] = 'record saved'
          render_list_edi_org_hubs
        else
          render_edit_edi_org_hub
        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

  def delete_edi_org_hub
    begin
      return if authorise_for_web(program_name?,'delete')== false
      if params[:page]
        session[:edi_org_hubs_page] = params['page']
        render_list_edi_org_hubs
        return
      end
      id = params[:id]
      if id && edi_org_hub = EdiOrgHub.find(id)
        edi_org_hub.destroy
        session[:alert] = " Record deleted."
        render_list_edi_org_hubs
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_edi_org_hub
    return if authorise_for_web(program_name?,'create')== false
    render_new_edi_org_hub
  end

  def create_edi_org_hub
    begin
      @edi_org_hub = EdiOrgHub.new(params[:edi_org_hub])
      if @edi_org_hub.save
        # flash[:notice] = "Created edi_org_hub:<br> #{@edi_org_hub.flow_type}/#{@edi_org_hub.organization_code}/#{@edi_org_hub.hub_address} "
        # render_list_edi_org_hubs
        @freeze_flash = true
        redirect_to_index("Created edi_org_hub:<br> #{@edi_org_hub.flow_type}/#{@edi_org_hub.organization_code}/#{@edi_org_hub.hub_address} ") 
      else
        @is_create_retry = true
        render_new_edi_org_hub
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_edi_org_hub
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new edi_org_hub'"%> 

    <%= build_edi_org_hub_form(@edi_org_hub,'create_edi_org_hub','create_edi_org_hub',false,@is_create_retry)%>

    }, :layout => 'content'
  end

# -----------------------------------------------------
  def list_edi_out_destinations
    if params[:page]!= nil 
      session[:edi_out_destinations_page] = params['page']
      render_list_treatments
      return 
    else
      session[:edi_out_destinations_page] = nil
    end

    list_query = "@edi_out_destinations = EdiOutDestination.find(:all, :order => 'organization_code, flow_type, hub_address')"
         session[:query] = list_query
         render_list_edi_out_destinations
  end

  def render_list_edi_out_destinations
    @edi_out_destinations =  eval(session[:query]) if !@edi_out_destinations
    render :inline => %{
      <% grid            = build_edi_out_destination_grid(@edi_out_destinations,true,true) %>
      <% grid.caption    = 'list of all EDI Output destinations' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_edi_out_destination
    return if authorise_for_web(program_name?,'edit')==false 
    id = params[:id]
    if id && @edi_out_destination = EdiOutDestination.find(id)
      render_edit_edi_out_destination

    end
  end

  def render_edit_edi_out_destination
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit EdI Out Destination'"%> 

    <%= build_edi_out_destination_form(@edi_out_destination,'update_edi_out_destination','update_edi_out_destination',true)%>

    }, :layout => 'content'
  end

  def update_edi_out_destination
    begin
      id = params[:edi_out_destination][:id]
      if id && @edi_out_destination = EdiOutDestination.find(id)
        if @edi_out_destination.update_attributes(params[:edi_out_destination])
          flash[:notice] = 'record saved'
          render_list_edi_out_destinations
        else
          render_edit_edi_out_destination
        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

  def delete_edi_out_destination
    begin
      return if authorise_for_web(program_name?,'delete')== false
      if params[:page]
        session[:edi_out_destinations_page] = params['page']
        render_list_edi_out_destinations
        return
      end
      id = params[:id]
      if id && edi_out_destination = EdiOutDestination.find(id)
        edi_out_destination.destroy
        session[:alert] = " Record deleted."
        render_list_edi_out_destinations
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_edi_out_destination
    return if authorise_for_web(program_name?,'create')== false
    render_new_edi_out_destination
  end

  def create_edi_out_destination
    begin
      @edi_out_destination = EdiOutDestination.new(params[:edi_out_destination])
      if @edi_out_destination.save
        # flash[:notice] = "Created edi_out_destination:<br> #{@edi_out_destination.flow_type}/#{@edi_out_destination.organization_code}/#{@edi_out_destination.hub_address} "
        # render_list_edi_out_destinations
        @freeze_flash = true
        redirect_to_index("Created edi_out_destination:<br> #{@edi_out_destination.flow_type}/#{@edi_out_destination.organization_code}/#{@edi_out_destination.hub_address} ") 
      else
        @is_create_retry = true
        render_new_edi_out_destination
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_edi_out_destination
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new edi_out_destination'"%> 

    <%= build_edi_out_destination_form(@edi_out_destination,'create_edi_out_destination','create_edi_out_destination',false,@is_create_retry)%>

    }, :layout => 'content'
  end
 
  def search_edi_out_destinations_flat
    return if authorise_for_web(program_name?,'read')== false
    @is_flat_search = true 
    render_edi_out_destination_search_form
  end

  def render_edi_out_destination_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
    #	 render (inline) the search form
    render :inline => %{
    <% @content_header_caption = "'search  edi_out_destinations'"%> 

    <%= build_edi_out_destination_search_form(nil,'submit_edi_out_destinations_search','submit_edi_out_destinations_search',@is_flat_search)%>

    }, :layout => 'content'
  end

  def submit_edi_out_destinations_search
    if params['page']
      session[:edi_out_destinations_page] =params['page']
    else
      session[:edi_out_destinations_page] = nil
    end
    @current_page = params['page']
    if params[:page]== nil
      @edi_out_destinations = dynamic_search(params[:edi_out_destination] ,'edi_out_destinations','EdiOutDestination')
    else
      @edi_out_destinations = eval(session[:query])
    end
    if @edi_out_destinations.length == 0
      if params[:page] == nil
        flash[:notice] = 'no records were found for the query'
        @is_flat_search = session[:is_flat_search].to_s
        render_edi_out_destination_search_form
      else
        flash[:notice] = 'There are no more records'
        render_list_edi_out_destinations
      end

    else

      render_list_edi_out_destinations
    end
  end

# -----------------------------------------------------

  def list_edi_org_flows
    render_list_edi_org_flows
  end

  def render_list_edi_org_flows
    @edi_org_flows = EdiOrgFlow.find(:all, :order => 'organization_code, flow_type')
    render :inline => %{
      <% grid            = build_edi_org_flow_grid(@edi_org_flows,true,true) %>
      <% grid.caption    = 'list of EDI Organisation/flows (Only the flows that are not required need to be listed)' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_edi_org_flow
    return if authorise_for_web(program_name?,'edit')==false 
    id = params[:id]
    if id && @edi_org_flow = EdiOrgFlow.find(id)
      render_edit_edi_org_flow

    end
  end

  def render_edit_edi_org_flow
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit EdI Org Flow'"%> 

    <%= build_edi_org_flow_form(@edi_org_flow,'update_edi_org_flow','update_edi_org_flow',true)%>

    }, :layout => 'content'
  end

  def update_edi_org_flow
    begin
      id = params[:edi_org_flow][:id]
      if id && @edi_org_flow = EdiOrgFlow.find(id)
        if @edi_org_flow.update_attributes(params[:edi_org_flow])
          flash[:notice] = 'record saved'
          render_list_edi_org_flows
        else
          render_edit_edi_org_flow
        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

  def delete_edi_org_flow
    begin
      return if authorise_for_web(program_name?,'delete')== false
      if params[:page]
        session[:edi_org_flows_page] = params['page']
        render_list_edi_org_flows
        return
      end
      id = params[:id]
      if id && edi_org_flow = EdiOrgFlow.find(id)
        edi_org_flow.destroy
        session[:alert] = " Record deleted."
        render_list_edi_org_flows
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_edi_org_flow
    return if authorise_for_web(program_name?,'create')== false
    render_new_edi_org_flow
  end

  def create_edi_org_flow
    begin
      @edi_org_flow = EdiOrgFlow.new(params[:edi_org_flow])
      if @edi_org_flow.save
        @freeze_flash = true
        redirect_to_index("Created edi_org_flow:<br> #{@edi_org_flow.flow_type}/#{@edi_org_flow.organization_code} ") 
      else
        @is_create_retry = true
        render_new_edi_org_flow
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_edi_org_flow
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new edi_org_flow'"%> 

    <%= build_edi_org_flow_form(@edi_org_flow,'create_edi_org_flow','create_edi_org_flow',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def view_edi_file
    @chosen_flow ||= nil
    transformers = YAML::load(File.read(RAILS_ROOT + '/edi/config/supported_doc_types.yaml'))
    flow_types   = transformers['IN_FLOW_TYPES'].keys
    flow_types   += transformers['OUT_FLOW_TYPES'].keys
    @flow_types  = flow_types.uniq.sort_by {|a| a.ljust(4,'ZZ') }
    @flow_types.unshift 'Choose flow type'
  end


  def   display_edi_file_content(file_content,flow_type)

    require 'nokogiri'
    require 'edi/lib/edi/edi_helper'
    require 'edi/lib/edi/in/record_padder'
    require 'edi/lib/edi/edi_field_formatter'
    require 'edi/lib/edi/raw_fixed_len_record'


    @content = file_content

    fixrec = Struct.new(:rec_type, :colnames, :data)

    @content_arr = @content.split("\n")
    @records     = []
    prev_rec_type = ''
    this_rec      = nil
    did_first     = false
    munge_recs    = ['PO', 'RL'].include? flow_type
    @content_arr.each_with_index do |line, index|
      rec_type = line[0,2]
      if 'MT' == flow_type && 3 == index
        rec_type = 'LP'
        line[0,2] = rec_type
      end
      if munge_recs && rec_type == 'OL'
        if did_first
          rec_type  = 'LT'
          did_first = false
        else
          rec_type  = 'LF'
          did_first = true
        end
      end
      rfl = RawFixedLenRecord.new(flow_type, rec_type, line)
      if prev_rec_type != rec_type
        @records << this_rec.clone unless this_rec.nil?
        this_rec = fixrec.new(rec_type, rfl.fields.map {|fld| fld[0] }, [])
        prev_rec_type = rec_type
      end
      hs = {}
      rfl.fields.each {|fld| hs[fld[0]] = rfl[fld[0]] }
      this_rec.data << hs
    end
    @records << this_rec.clone unless this_rec.nil?
    render :action => 'display_edi_file', :layout => 'content'

  end



  #-----------------------------------------------------------------------------------------------------------
  #Use this method to provide a friendly display of a system provided,remote edi_file
  #input: expects an 'id_value'  url param that separates the flow_type and full path to the file via the '!' character
  #E.g. to configure a link:
  #  column_configs[column_configs.length()] = {:field_type => 'action',:field_name => 'view_edi_file',
  #  :settings =>
  #    {:link_text => 'view',
  #     :target_action => 'display_server_edi_file',
  #     :controller => 'tools/edi',
  #     :id_value => 'PS!../jmt/ftp/FTP-01/transformed/PS016744.0UI'}}
  #------------------------------------------------------------------------------------------------------------
  def  display_server_edi_file


       url_params = params[:id_value].split("!")
       flow_type = url_params[0]
       file_path =   url_params[1]

       content = File.read(file_path)

       return display_edi_file_content(content,flow_type)



  end





  def display_edi_file


    if params[:flow_type] == 'Choose flow type'
      flash[:notice] = 'Choose a flow'
      view_edi_file
      render :action => 'view_edi_file'
      return
    end
    if params[:edi_file].blank?
      flash[:notice] = 'Choose a file'
      @chosen_flow = params[:flow_type]
      view_edi_file
      render :action => 'view_edi_file'
      return
    end


    uploaded_io  = params[:edi_file]
    flow_type    = params[:flow_type]
    @fname       = File.basename(uploaded_io.original_filename)
    #csv_file    = FasterCSV.new(uploaded_io.tempfile, :headers => true) if csv...
    if uploaded_io.respond_to? :tempfile
      @content    = File.read(uploaded_io.tempfile)
    else
      @content    = uploaded_io.read
    end

    return display_edi_file_content(@content,flow_type)


  end

  #MM052016 - Create web tool to search files by name or contents
  def search_edi_file_by_name
    session[:file_path] = Globals.configured_edi_root_search_path(false)
    render_search_edi_file_by_name
  end

  def render_search_edi_file_by_name
    render :inline => %{
    <% @content_header_caption = "'search edi file by name'"%>

    <%= build_search_edi_file_by_name_form(@edi_files,'find_files_by_name','find_files_by_name',false)%>

    }, :layout => 'content'
  end

  #MM062017 - Search archive
  def search_archived_edi_file_by_name
    session[:file_path] = Globals.configured_edi_root_search_path(true)
    render_search_edi_file_by_name
  end

  def render_search_archived_edi_file_by_name
    render :inline => %{
    <% @content_header_caption = "'search archived edi file by name'"%>

    <%= build_search_edi_file_by_name_form(@edi_files,'find_files_by_name','find_files_by_name',false)%>

    }, :layout => 'content'
  end

  def view_file
    id_value = CGI.unescape(params[:id]).gsub("=",".")
    file_name = id_value.split("&")[0].to_s
    directories = id_value.split("&")[1].split(",").join("/")
    flow_type = get_file_type(file_name).upcase
    @fname       = file_name
    full_path = "#{session[:file_path].to_s}/#{directories}/#{file_name}"
    if File.file?("#{full_path}")
      @content    = File.read(full_path)
      return display_edi_file_content(@content,flow_type)
    else
      flash[:notice] = "Edi view_file error: #{full_path} is not a file"
      render :inline => %{}, :layout => 'content'
    end
  end

  def render_reworks_find_files_by_name
   file_name = ActiveRecord::Base.connection.select_one("select edi_doc_name from rw_runs where id = #{params[:id]}")['edi_doc_name']
   session[:file_path] = Globals.configured_edi_root_search_path(false)
   @edi_files = []
   file_name = "\*#{params[:edi_files][:file_name]}\*" if params[:edi_files]
   file_name = "\*#{file_name}\*" if file_name
   base_dir  = File.expand_path(session[:file_path].to_s) << "/"
   files     = Dir[File.join(base_dir, '**', file_name)]

   modified_date_files={}
   edi_files = []
   modified_dates = []
   files.map {|f| f.sub(base_dir, '')}.each do |file|
     modified_date = File.mtime(File.join(session[:file_path].to_s, file))
     file_size = Float.round_float(1,(File.size(File.join(session[:file_path].to_s, file)) / 1024))
     id_value      = "#{File.basename(file)}&#{File.dirname(file).gsub('/',',')}".gsub("./","").gsub(".","=")
     folder_type   = get_folder_type(file)
     file_type = get_file_type(File.basename(file))

     if file_name

       if modified_date_files.empty?
         t = modified_date.to_date
         modified_date_files[file] = modified_date
         modified_dates << modified_date
       else
         if modified_date  && (modified_date > modified_dates[0])
           modified_dates.delete_at(0)
           modified_dates << modified_date
           modified_date_files.clear
           modified_date_files[file] = modified_date
         end
       end
       edi_files << { 'id'            => CGI.escape(id_value),
                      'file_path'     => file,
                      'file_name'     => File.basename(file),
                      'folder_type'   => folder_type,
                      'file_type'     => file_type,
                      'file_size'     => file_size,
                      'modified_date' => modified_date.strftime("%Y-%m-%d %H:%M:%S")} if modified_date_files.keys.include?(file)

     end
   end
   # @edi_files = edi_files
   # render_edi_files
    params[:id] = edi_files[0]['id']
    view_file
  rescue
    handle_error("search edi file by name could not be created")
  end

  def find_files_by_name(file_name=nil)
    @edi_files = []
    file_name = "\*#{params[:edi_files][:file_name]}\*" if params[:edi_files]
    file_name = "\*#{file_name}\*" if file_name
    base_dir  = File.expand_path(session[:file_path].to_s) << "/"
    puts "EDI SEARCH DIR: " + base_dir
    files     = Dir[File.join(base_dir, '**', file_name)]

    files.map {|f| f.sub(base_dir, '')}.each do |file|
      modified_date = File.mtime(File.join(session[:file_path].to_s, file))
      file_size = Float.round_float(1,(File.size(File.join(session[:file_path].to_s, file)) / 1024))
      id_value      = "#{File.basename(file)}&#{File.dirname(file).gsub('/',',')}".gsub("./","").gsub(".","=")
      folder_type   = get_folder_type(file)
      file_type = get_file_type(File.basename(file))
      @edi_files << {'id'            => CGI.escape(id_value),
                    'file_path'     => file,
                    'file_name'     => File.basename(file),
                    'folder_type'   => folder_type,
                    'file_type'     => file_type,
                    'file_size'     => file_size,
                    'modified_date' => modified_date.strftime("%Y-%m-%d %H:%M:%S")}
    end
    render_edi_files
  rescue
    handle_error("search edi file by name could not be created")
  end

  def get_folder_type(file_path)
    ['transformed','encoding_errors','errors'].each do |folder_type|
      return folder_type if file_path.include?(folder_type)
    end
    ''
  end

  def get_file_type(file_name)
    if file_name.include?("MTDP")
      return "MTDP"
    else
      return file_name[0..1].upcase
    end
  end

  def render_edi_files
    render :inline => %{
      <% grid            = build_edi_files_grid(@edi_files) %>
      <% grid.caption    = 'edi files' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def download_file
    id_value = CGI.unescape(params[:id]).gsub("=",".")
    file_name = id_value.split("&")[0].to_s
    directories = id_value.split("&")[1].split(",").join("/")
    full_path = "#{session[:file_path].to_s}/#{directories}/#{file_name}"
    if File.file?("#{full_path}")
      @content    = File.read(full_path)
      launch_file_name = "#{file_name}_#{Time.now.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
      store_csv_file("#{Globals.configured_edi_download_path}/#{launch_file_name}",@content)
      launch_csv(launch_file_name)
    else
      flash[:notice] = "Edi download_file error: #{full_path} is not a file"
      render :inline => %{}, :layout => 'content'
    end
  end

  def view_raw_file
    id_value = CGI.unescape(params[:id]).gsub("=",".")
    file_name = id_value.split("&")[0].to_s
    directories = id_value.split("&")[1].split(",").join("/")
    full_path = "#{session[:file_path].to_s}/#{directories}/#{file_name}"
    if File.file?("#{full_path}")
      @content    = File.read(full_path)
      launch_file_name = "#{file_name}_#{Time.now.strftime("%m_%d_%Y_%H_%M_%S")}.txt"
      store_csv_file("#{Globals.configured_edi_download_path}/#{launch_file_name}",@content)
      launch_csv(launch_file_name)
    else
      flash[:notice] = "Edi download_file error: #{full_path} is not a file"
      render :inline => %{}, :layout => 'content'
    end
  end

  def store_csv_file(full_path,lines)
    File.open(full_path,"w") {|f| f.puts lines.to_a.join("\n") }
  rescue
    raise MesScada::InfoError, "File: #{full_path} could not be created. Exception reported is: \n" + $!
  end

  def launch_csv(file_name)
    begin
      @outfile_to_launch = "/downloads/edi/" + "#{file_name}"
      render :inline => %{
                  <script>
                    window.resizeTo(1200,800);
                    window.location.href= "<%=@outfile_to_launch%>";
                  </script>
                }, :layout => 'content'

    rescue
      flash[:error] = $!
      render :inline => %{}, :layout => 'content'
    end
  end

  def search_edi_file_by_contents
    session[:file_path] = Globals.configured_edi_root_search_path(false)
    render_search_edi_file_by_contents
  end

  def render_search_edi_file_by_contents
    render :inline => %{
    <% @content_header_caption = "'search edi file by contents'"%>

    <%= build_search_edi_file_by_contents_form(@edi_file_contents,'find_files_by_contents','find_files_by_contents',false)%>

    }, :layout => 'content'
  end

  def search_archived_edi_file_by_contents
    session[:file_path] = Globals.configured_edi_root_search_path(true)
    render_search_archived_edi_file_by_contents
  end

  def render_search_archived_edi_file_by_contents
    render :inline => %{
    <% @content_header_caption = "'search archived edi file by contents'"%>

    <%= build_search_edi_file_by_contents_form(@edi_file_contents,'find_files_by_contents','find_files_by_contents',false)%>

    }, :layout => 'content'
  end

  def find_files_by_contents
    files = []
    file_contents = []
    directories = []
    begin
      file_name = "'#{params[:edi_file_contents][:file_contents]}'"
      linux_command = "cd #{session[:file_path].to_s} &&  grep -hrn  #{file_name} . -l "
      files = `#{linux_command}`.split("\n")
      files.each do |file|
        split_files = file.reverse.split("/",2)
        edi_file = split_files[0].reverse.to_s
        directories = split_files[1].reverse.to_s.split("/") if split_files[1] != nil
        modified_date = `stat -c '%y' "#{session[:file_path].to_s}/#{file}"`
        id_value = "#{edi_file}&#{directories.join(',')}".gsub("./","").gsub(".","=")
        folder_type = get_folder_type(file)
        file_type = get_file_type(edi_file)
        file_contents.push('id' => CGI.escape(id_value),
                           'file_path' => file,
                           'file_name' => edi_file,
                           'folder_type' => folder_type,
                           'file_type' => file_type,
                           'modified_date' => modified_date.to_datetime.strftime("%Y-%m-%d %H:%M:%S"))
      end
      @file_contents = file_contents
      render_edi_contents
    rescue
      handle_error("search edi file by name could not be created")
    end
  end

  def render_edi_contents
    render :inline => %{
      <% grid            = build_edi_contents_grid(@file_contents) %>
      <% grid.caption    = 'edi contents' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  #MM082017 - edi file search tools: results grid: add 2 menu items:
  # 1] copy_file_to_tmp (onclick copy file to 'temp' directory 2 levels upward from current directory- create temp dir if not existing)
  # 2] re_drop_file(copy file to 'receive' dir- use a configured path in globals)
  def copy_file_to_tmp
    id_value = CGI.unescape(params[:id]).gsub("=",".")
    file_name = id_value.split("&")[0].to_s
    directories = id_value.split("&")[1].split(",").join("/")
    full_path = "#{session[:file_path].to_s}/#{directories}/#{file_name}"
    tmp_path = Globals.configured_edi_tmp_path
    FileUtils.makedirs(tmp_path) # Create dir if it does not exist.
    tmp_file = "#{tmp_path}/#{file_name}"
    linux_command = "cp #{full_path} #{tmp_file}"
    `#{linux_command}`
    session[:alert] = "file copied successfully"
    render :inline => %{}, :layout => 'content'
  end

  def re_drop_file
    id_value = CGI.unescape(params[:id]).gsub("=",".")
    file_name = id_value.split("&")[0].to_s
    directories = id_value.split("&")[1].split(",").join("/")
    full_path = "#{session[:file_path].to_s}/#{directories}/#{file_name}"
    # tmp_path = "#{Globals.configured_edi_receive_path}/#{directories}"
    tmp_path = Globals.configured_edi_receive_path
    FileUtils.makedirs(tmp_path) # Create dir(s) if it does not exist.
    tmp_file = "#{tmp_path}/#{file_name}"
    linux_command = "cp #{full_path} #{tmp_file}"
    `#{linux_command}`
    session[:alert] = "file copied successfully"
    render :inline => %{}, :layout => 'content'
  end

end
