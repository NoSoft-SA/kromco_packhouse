class  Fg::VoyageController < ApplicationController
 
def program_name?
	"voyage"
end

def bypass_generic_security?
	true
end

def clone_voyage
  voyage=Voyage.find(params[:id])
  session[:voyage_to_b_cloned]=voyage
  session[:clone_voyage]=true
  render_clone_voyage
end
def render_clone_voyage
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'clone voyage'"%>

		<%= build_clone_voyage_form(@voyage,'create_clone','create_voyage',false,@is_create_retry)%>

		}, :layout => 'content'
end
def create_clone
   if params[:voyage][:voyage_code] == "" || params[:voyage][:voyage_code] == nil
     flash[:error]= "voyage code  is required"
      render :inline => %{<script>
                                  window.location.href = '/fg/voyage/render_clone_voyage';
                </script>} and return
   end

    #existing_voyage=Voyage.find_by_sql("select * from voyages where vessel_id=#{session[:voyage_to_b_cloned].vessel_id} and
    #and voyage_number='#{params[:voyage][:voyage_number]}'
    #and vessel_code='#{session[:voyage_to_b_cloned].vessel_code}' and voyage_code='#{session[:voyage_to_b_cloned].voyage_code}'
    #")


    voyage=Voyage.new
    session[:voyage_to_b_cloned].export_attributes(voyage,true)
    voyage.voyage_code=params[:voyage][:voyage_code]
    if voyage.save
      list_voyages
    end



   end

#----------------------------------

def complete_old_voyages
  return if authorise_for_web(program_name?,'create')== false
  render :inline => %{
  		<% @content_header_caption = "'complete voyages'"%>

  		<%= build_complete_voyage_form(@voyage,'complete_voyages','complete_voyages',false,@is_create_retry)%>

  		}, :layout => 'content'
end

def complete_voyage
  voyage_id=params[:id]
  ActiveRecord::Base.connection.execute("update voyages set status='COMPLETED' where id=#{voyage_id.to_i}")
    session[:alert]="voyage completed"
  list_voyages and return
end

def complete_voyages
  if params[:voyage]['complete_voyages_older_than_n_days']==nil || params[:voyage]['complete_voyages_older_than_n_days']=="" || params[:voyage]['complete_voyages_older_than_n_days']==''
    flash[:error]="enter  number of days "
    complete_old_voyages and return

  end

  if params[:voyage]['complete_voyages_older_than_n_days'].to_i==0
    flash[:error]="enter a a number"
    complete_old_voyages and return
  end
  days=params[:voyage]['complete_voyages_older_than_n_days']
  ActiveRecord::Base.connection.execute("update voyages set status='COMPLETED' where id in
  (select voyages.id
  from voyages
  inner join voyage_ports on voyage_ports.voyage_id=voyages.id
  inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
  where voyage_port_types.voyage_port_type_code='Arrival' and ((CURRENT_DATE - voyage_ports.arrival_date) > '#{days}') ) ")
  @voyages=Voyage.find_by_sql("select voyages.*
  from voyages
  inner join voyage_ports on voyage_ports.voyage_id=voyages.id
  inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
  where voyage_port_types.voyage_port_type_code='Arrival' and ((CURRENT_DATE - voyage_ports.arrival_date) > '#{days}')")
  session[:alert]="voyages completed"
  render_list_voyages and return
end





#=================================================================================================

def voyage_port_type_changed
  voyage_port_type_id= get_selected_combo_value(params)
      if voyage_port_type_id== ""

      else
      voyage_port_type_code=VoyagePortType.find(voyage_port_type_id.to_i).voyage_port_type_code
      if voyage_port_type_code=="Departure"
        session[:is_destination_port]=true
      else
        session[:is_destination_port]=false
      end
        render :inline => %{
      <% is_destination_port = select('voyage_port','voyage_port_type_id',@voyage_port_type_ids) %>


     <script>
      <%= update_element_function(
          "is_destination_port_cell", :action => :update,
          :content => is_destination_port_content) %>


     </script>
    }
      end
end
def list_voyages
	return if authorise_for_web(program_name?,'read') == false 
 	if params[:page]!= nil
     		session[:voyages_page] = params['page']
		 render_list_voyages
     return 
	else
		session[:voyages_page] = nil
	end

	#list_query = "@voyage_pages = Paginator.new self, Voyage.count,5,@current_page
	# @voyages = Voyage.find(:all, :order=>'id desc',
	#			 :limit => @voyage_pages.items_per_page,
	#			 :offset => @voyage_pages.current.offset)"
	#session[:query] = list_query
  voyages =   Voyage.find_by_sql("select * from voyages order by id desc")
  @voyages=[]
  for voyage in voyages
    if voyage.status && voyage.status.upcase=="COMPLETED"
    else
      @voyages << voyage

    end
  end
	render_list_voyages
end

def render_list_voyages
	@pagination_server = "list_voyages"
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:voyages_page]
	@current_page = params['page']||= session[:voyages_page]
	render :inline => %{
      <% grid            = build_voyage_grid(@voyages,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all voyages' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@voyage_pages) if @voyage_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

 
def search_voyages_flat
  @content_header_caption = "'find voyage'"
      dm_session['se_layout'] = 'content'
      build_remote_search_engine_form("search_voyages.yml","render_voyages_grid")
      dm_session[:redirect] = true
end

def render_search_voyages

  @voyages = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
  render_list_voyages
end

def render_voyages_grid
 voyagess = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
 voyages=voyagess.group(['voyage_code','voyage_number','vessel_code'],nil,nil)
 @voyages=[]
  for voyage in voyages
    if voyage[0].status && voyage[0].status.upcase=="COMPLETED"
    else
      @voyages << voyage[0]
    end
  end
 render_list_voyages

end



def render_voyage_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  voyages'"%> 

		<%= build_voyage_search_form(nil,'submit_voyages_search','submit_voyages_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_voyages_search
	@voyages = dynamic_search(params[:voyage] ,'voyages','Voyage')
	if @voyages.length == 0
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_voyage_search_form
		else
			render_list_voyages
	end
end


 
def delete_voyage

	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:voyages_page] = params['page']
		list_voyages
		return
	end
	id = params[:id]
	if id && voyage = Voyage.find(id)
		voyage.destroy
		session[:alert] = " Record deleted."
		list_voyages
	end

end
 
def new_voyage
	return if authorise_for_web(program_name?,'create')== false
	render_new_voyage
end
 
def create_voyage
 begin
	 @voyage = Voyage.new(params[:voyage])
   @voyage.status="active"
	 if @voyage.save

       voyage_id = @voyage['id']    #store the id in session if in database do as that 
       session[:voyage_id] = voyage_id

		 render_edit_voyage
	else
		@is_create_retry = true
		render_new_voyage
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_voyage
#	 render (inline) the edit template
    session[:edit_voyage]==true
	render :inline => %{
		<% @content_header_caption = "'create new voyage'"%> 

		<%= build_voyage_form(@voyage,'create_voyage','create_voyage',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_voyage
	return if authorise_for_web(program_name?,'edit')==false
	 if @voyage = Voyage.find( params[:id])
       session[:voyage_id] =  params[:id]
       if @voyage.status==nil || @voyage.status.upcase=="ACTIVE"
         session[:edit_voyage]=true
       else
         session[:edit_voyage]=nil
       end
		render_edit_voyage

	 end
end


def render_edit_voyage
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit voyage'"%> 

		<%= build_voyage_form(@voyage,'update_voyage','update_voyage',true)%>

		}, :layout => 'content'
end
 
def update_voyage
 begin

	 id = params[:voyage][:id]
	 if id && @voyage = Voyage.find(id)
		 if @voyage.update_attributes(params[:voyage])
			#@voyages = eval(session[:query])
			flash[:notice] = 'record saved'
			render_edit_voyage
	 else
			 render_edit_voyage

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end
 
def list_voyage_ports
	return if authorise_for_web(program_name?,'read') == false

  @voyage_ports = VoyagePort.find_by_sql("select voyage_ports.*,ports.port_code,voyage_port_types.voyage_port_type_code as port_type_code
                                            from voyage_ports inner join ports on voyage_ports.port_id=ports.id
                                            inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
                                            where voyage_ports.voyage_id=#{params[:id]} order by voyage_ports.id desc")
	render_list_voyage_ports
end


def render_list_voyage_ports
  @id = session[:voyage_id]
  @child_dynamic_caption = "field_config =
                        {:id_value =>@id,
                        :link_text=>'new_voyage_port',
                        :host_and_port =>request.host_with_port.to_s,
                        :controller => request.path_parameters['controller'].to_s,
                        :target_action=>'new_voyage_port'}


      popup_link = ApplicationHelper::LinkWindowField.new(nil,nil, 'none','none','none',field_config,true,nil,self)

 @child_form_caption = ['child_form1','voyage ports for this voyage ' + popup_link.build_control]"
  if(!@voyage_ports.empty?)
      @can_edit = authorise(program_name?,'edit',session[:user_id])
      @can_delete = authorise(program_name?,'delete',session[:user_id])

      if session[:edit_voyage]==nil
        render :inline => %{

              <% grid            = build_voyage_port_grid(@voyage_ports,@can_edit,@can_delete) %>
              <% grid.caption    = 'list of all voyages ports' %>
              <% grid.height = '200' %>
              <% @header_content = grid.build_grid_data %>

              <%= grid.render_html %>
              <%= grid.render_grid %>
              }, :layout => 'content'
      else
          render :inline => %{
                  <%
                    eval(@child_dynamic_caption)
                  %>

              <% grid            = build_voyage_port_grid(@voyage_ports,@can_edit,@can_delete) %>
              <% grid.caption    = 'list of all voyages ports' %>
              <% grid.height = '200' %>
              <% @header_content = grid.build_grid_data %>

              <%= grid.render_html %>
              <%= grid.render_grid %>
              }, :layout => 'content'
      end

  else
      render :inline => %{
          <%
            eval(@child_dynamic_caption)
          %>
      },:layout => 'content'
    end
end

  def list_load_voyages
      return if authorise_for_web(program_name?,'read') == false
      @load_voyages = LoadVoyage.find_all_by_voyage_id(params[:id])
      render_list_load_voyages
  end

 def render_list_load_voyages
  @id = session[:voyage_id]
  @child_dynamic_caption = "field_config =
                        {:id_value =>@id,
                        :link_text=>'new_load_voyage',
                        :host_and_port =>request.host_with_port.to_s,
                        :controller => request.path_parameters['controller'].to_s,
                        :target_action=>'new_load_voyage'}


      popup_link = ApplicationHelper::LinkWindowField.new(nil,nil, 'none','none','none',field_config,true,nil,self)

 @child_form_caption = ['child_form2','load voyages for this voyage ' + popup_link.build_control]"

  if(!@load_voyages.empty?)
      @can_edit = authorise(program_name?,'edit',session[:user_id])
      @can_delete = authorise(program_name?,'delete',session[:user_id])
    if session[:edit_voyage]==nil
      render :inline => %{

            <% grid            = build_load_voyage_grid(@load_voyages,@can_edit,@can_delete) %>
            <% grid.height   = '200' %>
            <% grid.caption    = 'list of all load voyages' %>
            <% @header_content = grid.build_grid_data %>

            <%= grid.render_html %>
            <%= grid.render_grid %>
            }, :layout => 'content'
   else
      render :inline => %{
          <%
            eval(@child_dynamic_caption)
          %>
      <% grid            = build_load_voyage_grid(@load_voyages,@can_edit,@can_delete) %>
      <% grid.height   = '200' %>
      <% grid.caption    = 'list of all load voyages' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    end
  else
      render :inline => %{
          <%
            eval(@child_dynamic_caption)
          %>
      },:layout => 'content'
    end
end
# =========================
# voyage ports begins here
# =========================
  def new_voyage_port
      return if authorise_for_web(program_name?,'create')== false
          render_new_voyage_port
  end


  def render_new_voyage_port
      render :inline => %{
          <% @content_header_caption = "'create new voyage_port'"%>

          <%= build_voyage_port_form(@voyage_port,'create_voyage_port','create_voyage_port',false,@is_create_retry)%>

          }, :layout => 'content'
  end

def create_voyage_port
 begin
         if   params[:voyage_port]['port_id']== ""
           else
         params[:voyage_port]['port_code']=Port.find(params[:voyage_port]['port_id'].to_i).port_code
         end
         @voyage_port = VoyagePort.new(params[:voyage_port])
         @voyage_port.voyage_id = session[:voyage_id]
      if @voyage_port.save
     render :inline =>
		 %{
            "<script>alert("new record created"); window.close(); window.opener.frames[1].frames[0].location.reload(true);</script>"

     },:layout => "content"
	else
		@is_create_retry = true
		render_new_voyage_port
      end

rescue
	 handle_error('record could not be created')
end
 end

  def edit_voyage_port
      return if authorise_for_web(program_name?,'edit')==false
      @child_form_caption = ["child_form1","edit_voyage_port"]
        id = params[:id]
      if id && @voyage_port = VoyagePort.find(id)
          render_edit_voyage_port

         else
    render :inline => %{},:layout => "content"
    end
   end

  def render_edit_voyage_port
  #	 render (inline) the edit template
      render :inline => %{
          <% @content_header_caption = "'edit voyage_port'"%>

          <%= build_voyage_port_form(@voyage_port,'update_voyage_port','update_voyage_port',true)%>

          }, :layout => 'content'
  end

  def update_voyage_port
   begin
     id = params[:voyage_port][:id]
       if id && @voyage_port = VoyagePort.find(id)
           if @voyage_port.update_attributes(params[:voyage_port])
             # @voyage_ports = eval(session[:query])
              flash[:notice] = 'record saved'
              render :inline => %{
              <script>
              window.opener.frames[1].frames[0].location.reload(true);
              alert('voyage port edited');
              window.close();
              </script>
                 }

              else
           render_edit_voyage_port

           end
       end
  rescue
       handle_error('record could not be saved')
  end
  end

def edit_voyage_port_from_popup
  @submit_to = "update_voyage_port_from_popup"
	edit_voyage_port
end

def delete_voyage_port
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:voyage_ports_page] = params['page']
		render_list_voyage_ports
		return
	end
	id = params[:id]
	if id && voyage_port = VoyagePort.find(id)
		voyage_port.destroy
		session[:alert] = " Record deleted."
		render_list_voyage_ports
	end
rescue handle_error('record could not be deleted')
end
end

 def render_find_voyages_search
  @voyages = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    render :inline => %{
      <% grid            = build_voyage_grid(@voyage,true) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end

  

  #=========================
  # load voyage begins here    (2)
  #=========================
  def new_load_voyage
      return if authorise_for_web(program_name?,'create')== false
          render_new_load_voyage
  end

  def create_load_voyage
    begin
                
      @load_voyage = LoadVoyage.new(params[:load_voyage])
      @load_voyage.voyage_id = session[:voyage_id]
       if @load_voyage.save

   render :inline =>
		 %{
                   "<script>alert("new record created"); window.close(); window.opener.frames[1].frames[1].location.reload(true);</script>"

     },:layout => "content"
	else
		@is_create_retry = true
		render_new_load_voyage
	 end
rescue
	 handle_error('record could not be created')
end
end

  def render_new_load_voyage
  #	 render (inline) the edit template
      render :inline => %{
          <% @content_header_caption = "'create new load_voyage'"%>

          <%= build_load_voyage_form(@load_voyage,'create_load_voyage','create_load_voyage',false,@is_create_retry)%>

          }, :layout => 'content'
  end

  def edit_load_voyage_from_popup
    @submit_to = "update_load_voyages_from_popup"
    edit_load_voyage
  end

  def edit_load_voyage
	return if authorise_for_web(program_name?,'edit')==false
     @child_form_caption = ["child_form2","edit_load_voyage"]
	 id = params[:id]

	 if id && @load_voyage = LoadVoyage.find(id)
		render_edit_load_voyage
    else
    render :inline => %{},:layout => "content"
    end
  end

  def render_edit_load_voyage
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit load_voyage'"%>

		<%= build_load_voyage_form(@load_voyage,'update_load_voyage','update_load_voyage',true)%>

		}, :layout => 'content'
  end

  #====================== update load voyage =======================
  #  Take note of the frames numbers on refreshing the updated form
  #  for 2nd frame change the values to frames[1].location[1]
  #=================================================================
  def update_load_voyage
 begin

	 id = params[:load_voyage][:id]
	 if id && @load_voyage = LoadVoyage.find(id)
		 if @load_voyage.update_attributes(params[:load_voyage])
			flash[:notice] = 'record saved'
            render :inline => %{
        <script>
        window.opener.frames[1].frames[1].location.reload(true);
        alert('load voyage edited');
        window.close();
        </script>
           }

	 else
	  render_edit_load_voyage

	end
 end
rescue
	 handle_error('record could not be saved')
end
 end

 def delete_load_voyage
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:load_voyages_page] = params['page']
		render_list_load_voyages
		return
	end
	id = params[:id]
	if id && load_voyage = LoadVoyage.find(id)
		load_voyage.destroy
		session[:alert] = " Record deleted."
		render_list_load_voyages
	end
rescue handle_error('record could not be deleted')
end
end

  def find_voyage
    build_remote_search_engine_form("search_voyages.yml","render_voyages_grid")
    dm_session[:redirect] = true
  end



  def view_details
    id = params[:id]
	 if id && @voyages = Voyage.find(id)
		render :inline => %{
		<% @content_header_caption = "'view complete voyages details'"%>

		<%= view_voyages_details_form(@voyages,'view_paging_handler_voyages')%>

		}, :layout => 'content'

	 end
end

 def view_paging_handler_voyages
      if params[:page]
           session[:voyages_page] = params['page']
        end
      render_list_voyages
  end

 def list_load_voyage_ports
  id = params[:id]
   @load_voyage_id = id
    if id == nil
      id = session[:load_voyage_id]
    end
   load_voyage = LoadVoyage.find_by_sql("select * from load_voyages where id = '#{id}'")[0]
   load_voyage_id = load_voyage.id
   session[:load_voyage_id] = load_voyage_id

   voyage_id = load_voyage.voyage_id
   session[:voyage_id] = voyage_id

   voyage_port = VoyagePort.find_by_sql("select * from voyage_ports where voyage_id = '#{voyage_id}' order by id desc" )[0]
   voyage_port_id = voyage_port.id
   session[:voyage_port_id] = voyage_port_id

#   @voyage_ports = LoadVoyagePort.find_by_sql("select * from load_voyage_ports join voyage_ports on load_voyage_ports.voyage_port_id= voyage_ports.id
#                                               where  load_voyage_ports.load_voyage_id = '#{load_voyage_id}'")
  @voyage_ports= LoadVoyagePort.find_by_sql(
  "select load_voyage_ports.id,load_voyage_ports.voyage_port_id,load_voyage_ports.load_voyage_id,voyage_ports.port_id,voyage_ports.port_sequence,voyage_ports.quay,
   voyage_ports.voyage_id,voyage_ports.voyage_port_type_id,voyage_ports.departure_date,voyage_ports.arrival_date,voyage_ports.departure_open_stack,
   voyage_ports.departure_close_stack,voyage_ports.port_code
   from load_voyage_ports join voyage_ports on load_voyage_ports.voyage_port_id= voyage_ports.id where  load_voyage_ports.load_voyage_id = '#{load_voyage_id}'")
	render_list_load_voyage_ports
 end
  def render_list_load_voyage_ports
    @pagination_server = "list_voyage_ports"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:voyage_ports_page]
    @current_page = params['page']||= session[:voyage_ports_page]
    @voyage_ports =  eval(session[:query]) if !@voyage_ports

    render :inline => %{
      <% grid            = build_load_voyage_port_grid(@voyage_ports,@can_edit,@can_delete) %>
      <% grid.caption    = 'voyage ports' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@voyage_port_pages) if @voyage_port_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def add_new_voyage_ports
    return if authorise_for_web(program_name?,'read') == false
    load_voyage_id = session[:load_voyage_id]
    voyage_id = session[:voyage_id]

    @voyage_ports = VoyagePort.find_by_sql("select * from voyage_ports
                        where voyage_id = '#{voyage_id}' and voyage_ports.id
                        not in (select voyage_port_id from load_voyage_ports where load_voyage_id = '#{load_voyage_id}') order by id desc ")
    render_list_load_voyage_ports_popup
  end

  def render_list_load_voyage_ports_popup
       @pagination_server = "list_voyage_ports"
       @can_edit = authorise(program_name?, 'edit', session[:user_id])
       @can_delete = authorise(program_name?, 'delete', session[:user_id])
       @current_page = session[:voyage_ports_page]
       @current_page = params['page']||= session[:voyage_ports_page]
       @voyage_ports =  eval(session[:query]) if !@voyage_ports
       render :inline => %{
      <% grid            = build_load_voyage_port_popup_grid(@voyage_ports,@can_edit,@can_delete) %>
      <% grid.caption    = 'voyage ports' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@voyage_port_pages) if @voyage_port_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def remove_voyage_port_from_popup
    id = params[:id].to_i
   load_voyage_port = LoadVoyagePort.find_by_sql("select * from load_voyage_ports where id = ' #{id}' order by id desc")[0]
   load_voyage_port.destroy
  
       render :inline => %{
                      <script>
                        alert('load voyage removed');
                        window.opener.location.href = '/fg/voyage/list_load_voyage_ports ';
                        window.close();
                      </script>
                        }, :layout => 'content'
 end

  def select_voyage_port
   v_id = params[:id]
  
   load_voyage_id = session[:load_voyage_id]
   load_voyage = LoadVoyage.find(load_voyage_id)
   session[:load_voyage_id] = load_voyage_id
   voyage_port = VoyagePort.find_by_sql("select * from voyage_ports where id = '#{v_id }' order by id desc")[0]
   voyage_port_id = voyage_port.id
   @voyage_port_id = voyage_port_id
   
   @load_voyage_port = LoadVoyagePort.new
   @load_voyage_port.load_voyage_id = load_voyage_id.to_i
   @load_voyage_port.voyage_port_id = v_id.to_i
   @load_voyage_port.save

        render :inline => %{
                          <script>
                            alert('load voyage port created!!!!');
                            window.opener.location.href = '/fg/voyage/list_load_voyage_ports ';
                            window.close();
                          </script>
                            }, :layout => 'content'

  end
                       
end
