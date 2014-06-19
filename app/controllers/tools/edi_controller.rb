class  Tools::EdiController < ApplicationController
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
    require 'nokogiri'
    require 'edi/lib/edi/edi_helper'
    require 'edi/lib/edi/in/record_padder'
    require 'edi/lib/edi/edi_field_formatter'
    require 'edi/lib/edi/raw_fixed_len_record'

    uploaded_io  = params[:edi_file]
    flow_type    = params[:flow_type]
    @fname       = File.basename(uploaded_io.original_filename)
    #csv_file    = FasterCSV.new(uploaded_io.tempfile, :headers => true) if csv...
    if uploaded_io.respond_to? :tempfile
      @content    = File.read(uploaded_io.tempfile)
    else
      @content    = uploaded_io.read
    end

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

  end

end
