class QualityControl::GrowerCommitmentController < ApplicationController

  def program_name?
    "grower_commitment"
  end

  def bypass_generic_security?
    true
  end

  def active_delivery_commitment
       if !session[:new_delivery]
             redirect_to_index("there is no active delivery")
         return
       end

        query = "SELECT
                  grower_commitments.*
                FROM
                  public.grower_commitments,
                  public.spray_program_results
                WHERE
                  spray_program_results.grower_commitment_id = grower_commitments.id AND
                  grower_commitments.farm_code = '#{session[:new_delivery].farm_code}' AND
                  grower_commitments.season = '#{session[:new_delivery].season.season}' AND
                  spray_program_results.rmt_variety_code = '#{session[:new_delivery].rmt_variety_code}';"


         commitments =     GrowerCommitment.find_by_sql(query)
         if commitments.length > 0
           commitment = commitments[0]
           params[:id] = commitment.id.to_s
           @content_header_caption = "edit active delivery grower commitment"
           edit_grower_commitment
           return
         else
            flash[:notice] = "No relevant grower commitment found for season: '#{session[:new_delivery].season.season} , farm: '#{session[:new_delivery].farm_code}' and rmt variety: '#{session[:new_delivery].rmt_variety_code}' "
            render :inline => %{}, :layout => 'content'
         end



  end


  def print_mrl_result
#    return if authorise_for_web(program_name?, 'grower_commitment_print_mrl_results')==false

    generic_printer                       = RmtProcessing::DeliveryController.new()
    mrl_result                            = MrlResult.find_by_id(params[:id])

    farm_id                               = mrl_result.spray_program_result.grower_commitment.farm_id
    rmt_variety_id                        = mrl_result.spray_program_result.rmt_variety.id
    season_id                             = mrl_result.spray_program_result.grower_commitment.season_id
    mrl_result_type_code                  = mrl_result.mrl_result_type_code
    orchard_code                          = mrl_result.orchard_code
    puc_code                              = mrl_result.puc_code
#puts session[:user_id].user_name.to_s

#@mrl_result_msg =  generic_printer.genric_print_mrl_label(farm_id,rmt_variety_id,season_id,session[:user_id].user_name.to_s,mrl_result_type_code,orchard_code,puc_code)
#-----------
    mrl_label_page1_report                ="reportUnit=/RMT/mrl_label_page1&"
    mrl_label_page1_report_parameters     = "output=pdf&mrl_result_id=" + mrl_result.id.to_s
    @mrl_label_page1_url                  = Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + mrl_label_page1_report +Globals.get_jasperserver_username_password + mrl_label_page1_report_parameters


    mrl_label_page2_report                ="reportUnit=/RMT/mrl_label_page2&"
    mrl_label_page2_report_parameters     = "output=pdf&mrl_result_id=" + mrl_result.id.to_s
    @mrl_label_page2_url                  = Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + mrl_label_page2_report +Globals.get_jasperserver_username_password + mrl_label_page2_report_parameters


    mrl_label_page3_report                ="reportUnit=/RMT/mrl_label_page3&"
    mrl_label_page3_report_parameters     = "output=pdf&mrl_result_id=" + mrl_result.id.to_s
    @mrl_label_page3_url                  = Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + mrl_label_page3_report +Globals.get_jasperserver_username_password + mrl_label_page3_report_parameters

    mrl_result.update_attribute("mrl_label_text","printed at : " + Time.now.to_formatted_s(:db).to_s)
#-----------
    spray_program_results                 = SprayProgramResult.find_all_by_grower_commitment_id(mrl_result.spray_program_result.grower_commitment.id)
#puts "mrl_result.spray_program_result.grower_commitment.id = " + mrl_result.spray_program_result.grower_commitment.id.to_s
    update_mrl_labels_printed_route_steps = true
#spray_program_results.map{|o| puts "spray_program_results = " + o.id.to_s}
    spray_program_results.each do |spray|
      spray.mrl_results.each do |mrl|
#    puts "mrl_result_id = "  + mrl.id.to_s
#    puts "mrl_result_type_code = "  + mrl.mrl_result_type_code.to_s
        if (!mrl.cancelled && !mrl.mrl_label_text)
          update_mrl_labels_printed_route_steps = false
          break
        end
      end
    end
    mrl_data_capture_delivery_route_steps = DeliveryRouteStep.find_by_sql("SELECT delivery_route_steps.*,deliveries.id as delivery_id
    FROM delivery_route_steps
    JOIN deliveries ON delivery_route_steps.delivery_id=deliveries.id
      JOIN seasons on seasons.season_code=deliveries.season_code
      JOIN grower_commitments ON grower_commitments.farm_id=deliveries.farm_id
    where grower_commitments.farm_id=#{mrl_result.spray_program_result.grower_commitment.farm_id} and grower_commitments.season='#{mrl_result.spray_program_result.grower_commitment.season}' and delivery_route_steps.route_step_code='mrl_labels_printed'") #.map{|o| [o.id,o.route_step_code,o.delivery_id]}
#  puts " update_mrl_labels_printed_route_steps = " + update_mrl_labels_printed_route_steps.to_s
#  mrl_data_capture_delivery_route_steps.map{|f| puts "mrl_data_capture_delivery_route_step = " + f.to_s}
    if (mrl_data_capture_delivery_route_steps.length > 0 && update_mrl_labels_printed_route_steps)
      DeliveryRouteStep.bulk_update({:date_activated=>"'#{Time.now}'", :date_completed=>"'#{Time.now}'"}, "id", mrl_data_capture_delivery_route_steps.map { |r| r.id })
      mrl_data_capture_delivery_route_steps.map { |rs| Delivery.update(rs.delivery_id, {:delivery_status=>rs.route_step_code}) }
    end
    render :inline => %{<script>
                      window.location.href = "<%=@mrl_label_page1_url%>";
                      window.open("<%= @mrl_label_page2_url %>","","width=800,height=500,top=200,left=0,toolbar=0,menubar=0,status=0,scrollbars=0,resizable=0");
                      window.opener.open("<%= @mrl_label_page3_url %>","","width=800,height=500,top=200,left=0,toolbar=0,menubar=0,status=0,scrollbars=0,resizable=0");
                      this.window.opener.location.reload(true);
                    </script>
      }, :layout => 'content' 
  end

  def edit_spray_program_result
    return if authorise_for_web(program_name?, 'grower_commitment_edit')==false
    id = params[:id]
    if id && @spray_program_result = SprayProgramResult.find(id)
#      @is_create_retry = false
      @is_edit = true
      render_edit_spray_program_result

    end
  end


  def render_edit_spray_program_result
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit spray_program_result'"%> 

		<%= build_spray_program_result_form(@spray_program_result,'update_spray_program_result','update_spray_program_result',@is_edit,@is_create_retry)%>

		}, :layout => 'content'
  end


  def new_spray_program_result
    return if authorise_for_web(program_name?, 'grower_commitment_edit')==false
    session[:grower_commitment_id] = params[:id]
    render_new_spray_program_result
  end

  def create_spray_program_result
    begin

      @spray_program_result                      = SprayProgramResult.new(params[:spray_program_result])
      @spray_program_result.grower_commitment_id = session[:grower_commitment_id]
      if @spray_program_result.save
        render :inline => %{
            <script>
              //window.opener.frames[1].frames[1].location.reload();
              window.opener.frames[1].location.href = '/quality_control/grower_commitment/edit_grower_commitment/<%=@spray_program_result.grower_commitment_id%>';
              window.close();
            </script>
		}, :layout => 'content'
        # redirect_to_index("'new record created successfully'","'create successful'")
      else
        @is_create_retry = true
        render_new_spray_program_result
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def cancel_spray_program_result
    session[:current_spray_program_result] = params[:id]
    render :inline => %{
		<% @content_header_caption = "'capture cancel reason'"%>

		<%= build_cancel_spray_program_form(@spray_program_result,'submit_cancel_spray_program','cancel_spray_program')%>

		}, :layout => 'content'
  end

  def update_spray_program_result

    @spray_program_result                      = SprayProgramResult.find_by_id(params[:spray_program_result][:id])
    @spray_program_result.spray_result_comment = params[:spray_program_result][:spray_result_comment]
    if @spray_program_result.update
      session[:alert] = 'The item was updated'
      render :inline =>%{
	 <script>
    window.close();
   </script>
	}, :layout => 'content'
    else
      @spray_program_result = nil
      render :inline => %{<script>alert("we could not update the spray program result sorry")</script>}
    end

  end

  def cancel_mrl_result
    @mrl_result                     = MrlResult.find_by_id(session[:capture_cancel_mrl_result_reason_id])
    @mrl_result.cancelled           = true
    @mrl_result.cancelled_reason    = params[:mrl_result][:cancelled_reason]
    @mrl_result.cancelled_user_name = session[:user_id].user_name
    @mrl_result.cancelled_date_time =Time.now.strftime("%Y/%m/%d/%H:%M:%S")

    if @mrl_result.cancelled_reason && @mrl_result.cancelled_reason.to_s.strip != "" && @mrl_result.update
      render :inline =>%{
      <script>
      alert("The mrl result has been cancelled")
      this.window.opener.location.reload(true);
      window.opener.opener.frames[1].location.reload();
      this.window.close();
      </script>
      }, :layout => 'content'
    else
      @is_create_retry = true
      @mrl_result.errors.add_to_base("value of field: 'reason' you must specify a reason")
      params[:id] = session[:capture_cancel_mrl_result_reason_id]
      capture_cancel_mrl_result_reason
    end
  end

  def submit_cancel_spray_program
    @spray_program_result                     = SprayProgramResult.find(session[:current_spray_program_result])
    @spray_program_result.cancelled           = true
    @spray_program_result.cancelled_reason    = params[:spray_program_result][:cancelled_reason]
    @spray_program_result.cancelled_user_name = session[:user_id].user_name
    @spray_program_result.cancelled_date_time =Time.now.strftime("%Y/%m/%d/%H:%M:%S")
    @grower_commitment_id                     = @spray_program_result.grower_commitment.id
    if @spray_program_result.cancelled_reason && @spray_program_result.cancelled_reason.to_s.strip != "" && @spray_program_result.update
      session[:current_spray_program_result] = nil
      render :inline =>%{

      <script>
      alert("The spray_program_result has been cancelled")
      window.opener.parent.frames[1].location.href = '/quality_control/grower_commitment/edit_grower_commitment/<%=@grower_commitment_id%>';
      window.close();
      </script>
      }, :layout => 'content'
    else
      @is_create_retry = true
      @spray_program_result.errors.add_to_base("value of field: 'reason' you must specify a reason")
      params[:id] = session[:current_spray_program_result]
      cancel_spray_program_result
    end
  end

  def render_edit_mrl_result
#	 render (inline) the edit template

    render :inline => %{
		<% @content_header_caption = "'edit mrl_result'"%> 

		<%= build_mrl_result_form(@mrl_result,'update_mrl_result','update_mrl_result',true)%>

		}, :layout => 'content'
  end

  def capture_cancel_mrl_result_reason
#if session[:capture_cancel_mrl_result_reason_id] == nil
    session[:capture_cancel_mrl_result_reason_id] = params[:id]
#end
    render_capture_cancel_mrl_result_reason
  end

  def render_capture_cancel_mrl_result_reason
    i=0
    render :inline => %{
        <%@content_header_caption = "'capture cancel reason'"%>
		<%= build_mrl_cancel_reason_form(@mrl_result,'cancel_mrl_result','cancel_mrl_result',@is_create_retry)%>

		}, :layout => 'content'
  end

#  def update_mrl_result
#    begin
#
#      if params[:page]
#        session[:mrl_results_page] = params['page']
#        render_list_mrl_results
#        return
#      end
#
#      @current_page = session[:mrl_results_page]
#      id            = params[:mrl_result][:id]
#      if id && @mrl_result = MrlResult.find(id)
#        if @mrl_result.update_attributes(params[:mrl_result])
#          @mrl_results   = eval(session[:query])
#          flash[:notice] = 'record saved'
#          render :inline =>%{
#	<%= close_popupwindow_from_nested_reload_parent_frame2 %>
#	}, :layout => 'content'
#        else
#          render_edit_mrl_result
#
#        end
#      end
#    rescue
#      handle_error('record could not be saved')
#    end
#  end

#  def edit_mrl_result
#    return if authorise_for_web(program_name?, 'grower_commitment_edit')==false
#    id = params[:id]
#    if id && @mrl_result = MrlResult.find(id)
#      @mrl_result.farm_code = @mrl_result.set_farm_code(@mrl_result.spray_program_result.id)
#      render_edit_mrl_result
#
#    end
#  end

  def render_new_spray_program_result
#	 render (inline) the edit template
    @grower_commitment      = GrowerCommitment.find(session[:grower_commitment_id])
    @content_header_caption = "'create new spray_program_result'"
    @content_header_caption = "'add spray program result for grower #{@grower_commitment.farm_code} and season #{@grower_commitment.season} '" if @grower_commitment.farm_code and @grower_commitment.season
    puts "@content_header_caption = " + @content_header_caption
    render :inline => %{
        <%= build_spray_program_result_form(@spray_program_result,'create_spray_program_result','create_spray_program_result',false,@is_create_retry)%>
        }, :layout => 'content'
  end

  def edit_mrl_result
    @is_create_retry = false
    @is_edit = true
    @action = 'update_mrl_result'
    @caption = 'update_mrl_result'
    @mrl_result = MrlResult.find(params[:id])
    @mrl_result.set_farm_code(session[:grower_commitment_id])
    session[:mrl_result_id] = params[:id]
    render_new_mrl_result
  end

  def update_mrl_result
    @grower_commitment_id = session[:grower_commitment_id]
    if @mrl_result = MrlResult.find(session[:mrl_result_id])
      session[:mrl_result_id] = nil
      if @mrl_result.update_attributes(params[:mrl_result])
        @spray_program_result_id = @mrl_result.spray_program_result_id
#        window.opener.frames[1].location.href = '/quality_control/grower_commitment/render_spray_results/<%=@grower_commitment_id%>';
      render :inline =>%{
	        <script>
            window.opener.parent.frames[1].location.href = '/quality_control/grower_commitment/edit_grower_commitment/<%=@grower_commitment_id%>';
            window.location.href = '/quality_control/grower_commitment/list_mrl_results/<%=@spray_program_result_id%>';
          </script>
	        }, :layout => 'content'
      else
        edit_mrl_result
      end
    else
    end    
  end

  def new_mrl_result
    return if authorise_for_web(program_name?, 'grower_commitment_edit')==false

    session[:spray_program_result_id] = params[:id]
    @action = 'create_mrl_result'
    @caption = 'create_mrl_result'
    render_new_mrl_result
  end

  def grower_commitment_print
    puts "I have printed"
    render :inline =>%{
	<%= close_popupwindow_from_nested_reload_parent_frame2 %>
	}, :layout => 'content'
  end

  def render_new_mrl_result
#	 render (inline) the edit template
#
    spray_program_result = SprayProgramResult.find(session[:spray_program_result_id])
    not_cancelled_mrl_result = spray_program_result.mrl_results.detect() { |mrl_result| ((!mrl_result.cancelled)) } if spray_program_result.mrl_results

    if @mrl_result == nil
      @mrl_result = MrlResult.new()
      @mrl_result.set_puc_code(session[:grower_commitment_id])
      @mrl_result.set_farm_code(session[:grower_commitment_id])
      @mrl_result.generate_sample_no(session[:spray_program_result_id])

    end

    @mrl_result.mrl_result_type_code = not_cancelled_mrl_result.mrl_result_type_code if (not_cancelled_mrl_result)
    
    render :inline => %{
		<% @content_header_caption = "'create new mrl_result'"%> 

		<%= build_mrl_result_form(@mrl_result,@action,@caption,@is_edit,@is_create_retry)%>

		}, :layout => 'content'
  end

  def generate_sequence_number(id)

    ids =id
    if MrlResult.find_by_sql("select max(sequence_number) as sequence_number from mrl_results where  spray_program_result_id = #{ids}   ") != nil
      max_sequence_number_arra = MrlResult.find_by_sql("select max(sequence_number) as sequence_number from mrl_results where  spray_program_result_id = #{ids} ")
      max_sequence_number      = max_sequence_number_arra[0].sequence_number.to_i + 1

    else
      max_sequence_number = 1
    end

    return max_sequence_number
  end

  def create_mrl_result
    begin
      @mrl_result                         = MrlResult.new(params[:mrl_result])
#      puts "stomers : " + params[:mrl_result][:mr_result].class.to_s
#      if(!params[:mrl_result][:mr_result] || params[:mrl_result][:mr_result] == "")
#        @mrl_result.errors.add_to_base("value of field: 'mrl_result' is invalid- it cannot be empty")
#        render_new_mrl_result
#        return
#      end
      
      @mrl_result.spray_program_result_id = session[:spray_program_result_id]
      @mrl_result.sequence_number         = generate_sequence_number(session[:spray_program_result_id])
      @mrl_result.set_puc_code(session[:grower_commitment_id])
      @mrl_result.set_farm_code(session[:grower_commitment_id])
      @mrl_result.sample_no = @mrl_result.generate_sample_no(session[:spray_program_result_id]).to_s
      @grower_commitment_id = session[:grower_commitment_id]
      if @mrl_result.save

        render :inline =>%{
	        <script>
            window.opener.parent.frames[1].location.href = '/quality_control/grower_commitment/edit_grower_commitment/<%=@grower_commitment_id%>';
            window.close();
          </script>
	}, :layout => 'content'

        # redirect_to_index("'new record created successfully'","'create successful'")
      else
        @is_create_retry = true
        params[:id] = session[:spray_program_result_id]
        @action = 'create_mrl_result'
        @caption = 'create_mrl_result'
        render_new_mrl_result
      end
    rescue
      handle_error('record could not be created')
    end
  end


  def new_commitment
    return if authorise_for_web(program_name?, 'grower_commitment_edit')==false
    session[:grower_commitment_id] = params[:id]
    render_new_commitment

  end

  def render_new_commitment


#	 render (inline) the edit template

    render :inline => %{
		<% @content_header_caption = "'create new commitment'"%> 
        
		<%= build_commitment_form(@commitment,'create_commitment','create_commitment',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def create_commitment
    begin
      @commitment = Commitment.new(params[:commitment])
      puts "i want save "+session[:grower_commitment_id_final].to_s
      @grower_commitment_id            = session[:grower_commitment_id]
      @commitment.grower_commitment_id = @grower_commitment_id
      @commitment.transaction_date     = Time.now.strftime("%Y/%m/%d/%H:%M:%S")
      if @commitment.save
        render :inline => %{
            <script>
              //window.opener.frames[1].location.reload();
              window.opener.frames[1].location.href = '/quality_control/grower_commitment/edit_grower_commitment/<%=@grower_commitment_id%>';
              window.close();
            </script>
		}, :layout => 'content'
      else
        @is_create_retry = true

        render_new_commitment
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_list_mrl_results

    @can_edit = authorise(program_name?,'grower_commitment_edit',session[:user_id])
    @is_view = true if(session[:grower_commitment_mode] == 'view')
    @can_print_mrl_results = authorise(program_name?, 'grower_commitment_print_mrl_results', session[:user_id])
    @current_page = session[:mrl_results_page] if session[:mrl_results_page]
    @current_page = params['page'] if params['page']
    @mrl_results = eval(session[:query]) if !@mrl_results

    grower_commitment = SprayProgramResult.find(params[:id]).grower_commitment #@mrl_results[0].spray_program_result.grower_commitment if @mrl_results.length > 0
    @grower_commitment_id = grower_commitment.id if grower_commitment
    @can_cancel = true
    if (grower_commitment && grower_commitment.mrl_data_capture_date_time != nil)
      @can_cancel = false
      @can_edit = false
    end

    if @mrl_results.length() != 0
      render :inline => %{
      <% grid            = build_mrl_result_grid(@mrl_results,@can_edit,@is_view,@can_cancel,@can_print_mrl_results) %>
      <% grid.caption    = 'list of all mrl_results' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@mrl_result_pages) if @mrl_result_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    else
      session[:alert] = "There were no records found create a mrl result"
      render :inline => %{
      <script>
      window.opener.frames[1].location.reload();//href = '/quality_control/grower_commitment/edit_grower_commitment/<%=@grower_commitment_id.to_s%>';
      this.window.close();
      </script>
      }, :layout => 'content'
    end
  end

  def list_mrl_results
    @spray_program_result_id = params[:id]
    session[:spray_program_result_id] = params[:id]
    
    if params[:page]!= nil

      session[:mrl_results_page] = params['page']

      render_list_mrl_results

      return
    else
      session[:mrl_results_page] = nil
    end

    list_query      = "@mrl_result_pages = Paginator.new self, MrlResult.count, @@page_size,@current_page
	 @mrl_results = MrlResult.find(:all, :conditions =>['spray_program_result_id = ? and cancelled   IS NOT true ', '#{@spray_program_result_id}'],
				 :limit => @mrl_result_pages.items_per_page,
				 :offset => @mrl_result_pages.current.offset)"
    session[:query] = list_query
    render_list_mrl_results
  end


  def list_grower_commitments

    if params[:page]!= nil

      session[:grower_commitments_page] = params['page']

      render_list_grower_commitments

      return
    else
      session[:grower_commitments_page] = nil
    end

    list_query      = "@grower_commitment_pages = Paginator.new self, GrowerCommitment.count, @@page_size,@current_page
	 @grower_commitments = GrowerCommitment.find(:all,
				 :limit => @grower_commitment_pages.items_per_page,
				 :offset => @grower_commitment_pages.current.offset)"
    session[:query] = list_query
    render_list_grower_commitments
  end

  def find_grower_commitment
    @is_flat_search         = true;
    @content_header_caption = "Fire"
    render :inline => %{
		<% @content_header_caption = "'find grower commitment'"%>
		<%= find_grower_commitment(nil,'submit_grower_commitments_search','submit_grower_commitments_searchs',@is_flat_search)%>
	}, :layout => 'content'
  end

  def render_list_grower_commitments
    @can_edit   = authorise(program_name?, 'grower_commitment_edit', session[:user_id])
    @can_delete = authorise(program_name?, 'grower_commitment_delete', session[:user_id])
    @current_page = session[:grower_commitments_page] if session[:grower_commitments_page]
    @current_page = params['page'] if params['page']
    @grower_commitments = eval(session[:query]) if !@grower_commitments
    render :inline => %{
      <% grid            = build_grower_commitment_grid(@grower_commitments,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all grower_commitments' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@grower_commitment_pages) if @grower_commitment_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_grower_commitments_flat
    @is_flat_search = true
    render_grower_commitment_search_form
  end

  def render_grower_commitment_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  grower_commitments'"%> 

		<%= build_grower_commitment_search_form(nil,'submit_grower_commitments_search','submit_grower_commitments_search',@is_flat_search)%>

		}, :layout => 'content'
  end

  def render_list_grower_commitment_searh_hier
    @can_edit   = authorise(program_name?, 'grower_commitment_edit', session[:user_id])
    @can_delete = authorise(program_name?, 'grower_commitment_delete', session[:user_id])
    @current_page = session[:grower_commitments_page] if session[:grower_commitments_page]

    @current_page = params['page'] if params['page']

    @grower_commitment = eval(session[:query]) if !@grower_commitment

    if @grower_commitment.length() < 0 || @grower_commitment.length() > 0
      render :inline => %{
      <% grid            = build_grower_commitment_grid(@grower_commitments,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of grower_commitment records' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    else
      render :inline => %{
		<% @content_header_caption = "'No grower commitment records found'"%>
		
	}, :layout => 'content'
    end
  end

  def submit_grower_commitments_search
    @from_date   = params[:from]
    @to_date     = params[:to]
    @farm_code   = params[:grower_commitment][:farm_code]
    @season = params[:grower_commitment][:season]

    if params['page']

      session[:grower_commitments_page]= params['page']

    else
      session[:grower_commitments_page] = nil

    end
    @current_page = params['page']
    if params[:page] == nil

      @grower_commitments = dynamic_search(params[:grower_commitment], 'grower_commitments', 'GrowerCommitment')
    else

    end
    render_list_grower_commitment_searh_hier
  end

  def delete_grower_commitment
    begin
      return if authorise_for_web(program_name?, 'grower_commitment_delete')== false
      if params[:page]
        session[:grower_commitments_page] = params['page']
        render_list_grower_commitments
        return
      end
      id = params[:id]
      if id && grower_commitment = GrowerCommitment.find(id)
        if (grower_commitment.grower_commitment_data_capture_date_time == nil && grower_commitment.mrl_data_capture_date_time == nil)
          grower_commitment.destroy
          session[:alert] = " Record deleted."
        else
          flash[:error] = "Cannot delete record: grower commitment has already been completed"
        end
        render_list_grower_commitments
      end
    rescue #handle_error('record could not be deleted')
      raise $!
    end
  end

  def new_grower_commitment
    return if authorise_for_web(program_name?, 'grower_commitment_new')==false
    render_new_grower_commitment
    session[:grower_commitment_id] = params[:id]
  end

  def create_grower_commitment
    begin

      @grower_commitment                  = GrowerCommitment.new(params[:grower_commitment])
      @grower_commitment.transaction_date = Time.now.strftime("%Y/%m/%d/%H:%M:%S")
      if @grower_commitment.save
        session[:grower_commitment_id_final] = @grower_commitment.id
        params[:id] = @grower_commitment.id
        edit_grower_commitment

#		 redirect_to_index("'new record created successfully'","'create successful'")
      else
        @is_create_retry = true
        render_new_grower_commitment
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_grower_commitment
#	 render (inline) the edit template
#@child_form_caption = ["child_form2","Henry's child form"]

    render :inline => %{
		<% @content_header_caption = "'create new grower_commitment'"%> 

		<%= build_grower_commitment_form(@grower_commitment,'create_grower_commitment','create_grower_commitment',false,false,false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_grower_commitment
    return if authorise_for_web(program_name?, 'grower_commitment_edit')==false
    id                             = params[:id]
    session[:grower_commitment_mode] = 'edit'
    session[:grower_commitment_id] = id
    if id && @grower_commitment = GrowerCommitment.find(id)
      @action = 'update_grower_commitment'
      @caption = 'update_grower_commitment'
      @is_edit = true
      render_edit_grower_commitment
    end
  end

  def view_grower_commitment
    id                             = params[:id]
    session[:grower_commitment_mode] = 'view'
    session[:grower_commitment_id] = id
    if id && @grower_commitment = GrowerCommitment.find(id)
      @caption = ''
      @is_edit = false
      render_edit_grower_commitment
    end
  end

  def render_edit_commitment
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit commitment'"%> 

		<%= build_commitment_form(@commitment,'update_commitment','update_commitment',true)%>
		

		}, :layout => 'content'
  end

  def update_commitment
    begin

      if params[:page]
        session[:commitments_page] = params['page']
        render_list_commitments
        return
      end

      @current_page         = session[:commitments_page]
      @grower_commitment_id = session[:grower_commitment_id]
      id                    = params[:commitment][:id]

      if id && @commitment = Commitment.find(id)
        if @commitment.update_attributes(params[:commitment])
          render :inline => %{
                <script>
                  window.opener.frames[1].location.href = '/quality_control/grower_commitment/edit_grower_commitment/<%=@grower_commitment_id%>';
                  window.close();
                </script>
            }, :layout => 'content'
        else
          render_edit_commitment

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

  def edit_commitment
    return if authorise_for_web(program_name?, 'grower_commitment_edit')==false

    id = params[:id]
    if id && @commitment = Commitment.find_by_id(id)

      render_edit_commitment

    end
  end


  def render_commitment_form

    puts params[:id]

    @grower_commitment_id_for_commitment = params[:id]
    session[:grower_commitment_id_final] = params[:id]

    begin

      @can_edit = authorise(program_name?,'grower_commitment_edit',session[:user_id])
      @can_delete = authorise(program_name?,'grower_commitment_delete',session[:user_id])
      @commitment = Commitment.find(:all, :conditions =>['grower_commitment_id = ?', @grower_commitment_id_for_commitment])
      @add_commitment = true if (GrowerCommitment.find(@grower_commitment_id_for_commitment).commitment_document_delivered)
      @add_commitment = false if(session[:grower_commitment_mode] == 'view')
      @is_view = true if(session[:grower_commitment_mode] == 'view')
      # end
    rescue
    end

#render :template => "quality_control/grower_commitment/edit_grower_commitment", :layout => "content"
    render :inline => %{
    <%
      field_config =
           {:id_value      =>@grower_commitment_id_for_commitment,
            :link_text     =>'new_commitment',
            :host_and_port =>request.host_with_port.to_s,
            :controller    => request.path_parameters['controller'].to_s,
            :target_action =>'new_commitment',
            :link_type=> 'child_form'}

      popup_link = ApplicationHelper::LinkWindowField.new(nil, nil, 'none', 'none', 'none', field_config, true, nil, self)
      the_link = popup_link.build_control if(@add_commitment)

      @child_form_caption = ["commitment_form", "commitments " + the_link.to_s] %>

      <% grid            = build_list_commitment_grid(@commitment,@can_edit,@can_delete,@is_view) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@mrl_result_pages) if @mrl_result_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'

  end

  def delete_commitment
    begin
      return if authorise_for_web(program_name?, 'grower_commitment_delete')== false
      id = params[:id]
      if id && commitment = Commitment.find(id)
        commitment.destroy
        session[:alert] = " Record deleted."
        render :inline => %{
            <script>
              window.opener.frames[1].location.href = '/quality_control/grower_commitment/edit_grower_commitment/<%=session[:grower_commitment_id]%>';
              window.close();
            </script>
		}, :layout => 'content'
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def test_show_add_spray_result_link(id)
    list_commitment_types = Commitment.find_by_sql("select * from commitments where grower_commitment_id = #{id} and (commitment_type_code  = 'Sedex' or  commitment_type_code = 'Globalgap' ) and(certificate_expiry_date > '#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}')")
    if list_commitment_types.length() >1
#    puts "SHOW = " + list_commitment_types.length().to_s
      return true
    else
      false
    end
  end

  def render_spray_results

    @grower_commitment_id = params[:id]
    @add_spray_results = true if (GrowerCommitment.find(@grower_commitment_id).spray_program_document_delivered)
    @spray_program_result       = SprayProgramResult.find_by_sql("select * from spray_program_results where grower_commitment_id =#@grower_commitment_id")
    @show_add_spray_result_link = (test_show_add_spray_result_link(@grower_commitment_id) && @add_spray_results)
    @is_view = true if(session[:grower_commitment_mode] == 'view')
    render :template => "quality_control/grower_commitment/edit_spray_program", :layout => "content"
  end

  def render_edit_grower_commitment

    puts @grower_commitment.id
    session[:grower_commitment]         = @grower_commitment

    @can_complete_spray_program_results = true
    spray_program_results               = SprayProgramResult.find_all_by_grower_commitment_id(@grower_commitment.id)
    failed_spray_program                = spray_program_results.detect() { |spray_prog| ((spray_prog.spray_result.upcase == 'FAILED') && (!spray_prog.cancelled)) }
    passed_spray_program_result         = spray_program_results.detect { |spray_prog| ((spray_prog.spray_result.upcase == 'PASSED') && (!spray_prog.cancelled)) }
#puts "failed_spray_program = " + failed_spray_program.class.to_s
#puts "spray_program_results = " + spray_program_results.length.to_s
    if (!passed_spray_program_result || failed_spray_program)
      @can_complete_spray_program_results = false
    end
#puts "See link??? = " + @can_complete_spray_program_results.to_s
    mrl_results = nil
    if (@can_complete_spray_program_results)
      @can_complete_mrl_results = true
      spray_program_results     = SprayProgramResult.find_all_by_grower_commitment_id(@grower_commitment.id)
      mrl_result_num            = 0
      failed_mrl_results        = 0
      passed_mrl_results        = 0
      cancelled_mrl_results = 0
      spray_program_results.each do |spray_program_result|
#        spray_program_result.mrl_results.each do |mrl_result|
        mrl_results = MrlResult.find_all_by_spray_program_result_id(spray_program_result.id)
        mrl_results.each do |mrl_result|
          mrl_result_num += 1
          cancelled_mrl_results += 1 if mrl_result.cancelled
          if (mrl_result && !mrl_result.cancelled && mrl_result.mrl_result && mrl_result.mrl_result.upcase == "FAILED")
            @can_complete_mrl_results = false
            failed_mrl_results        += 1
          elsif (mrl_result && !mrl_result.cancelled && mrl_result.mrl_result && (mrl_result.mrl_result.upcase == "PASSED" || mrl_result.mrl_result.upcase == "PENDING"))
            passed_mrl_results += 1
          end
        end
      end

      if (mrl_result_num == 0 || (cancelled_mrl_results == mrl_results.length))
        @can_complete_mrl_results = false
      end

      if (passed_mrl_results == 0 || failed_mrl_results > 0)
        @can_complete_spray_program_results = false
      end
    end

##	 render (inline) the edit template
    render :inline => %{ <%= build_grower_commitment_form(@grower_commitment,@action,@caption,@can_complete_spray_program_results, @can_complete_mrl_results,@is_edit)%>}, :layout =>'content'

  end

  def update_grower_commitment
    begin
      @action = 'update_grower_commitment'
      @caption = 'update_grower_commitment'
      @is_edit = true
      
      if params[:page]

        session[:grower_commitments_page] = params['page']
        render_list_grower_commitments
        return
      end


      @current_page = session[:grower_commitments_page]
      id            = params[:grower_commitment][:id]


      if id && @grower_commitment = GrowerCommitment.find(id)

        if @grower_commitment.update_attributes(params[:grower_commitment])
          flash[:notice] = 'record updated'
          render_edit_grower_commitment
        else
          render_edit_grower_commitment

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: season_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: farm_id
#	---------------------------------------------------------------------------------

  def grower_commitment_farm_code_changed
    farm_code = get_selected_combo_value(params)
    if farm_code != ""
      @seasons = GrowerCommitment.find_by_sql("select distinct season from grower_commitments where farm_code = '#{farm_code}'").map { |g| [g.season] }
    else
      @seasons = ["<empty>"]
    end
    render :inline => %{<%= select('grower_commitment','season',@seasons) %>}

  end

  def grower_commitment_id_changed
    id                                                    = get_selected_combo_value(params)
    session[:grower_commitment_form][:id_combo_selection] = id
    @farm_codes                                           = GrowerCommitment.farm_codes_for_id(id)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
    render :inline => %{
		<%= select('grower_commitment','farm_code',@farm_codes)%>

		}

  end

#def spray_program_result_rmt_variety_code_changed
#	rmt_variety_code = get_selected_combo_value(params)
#if rmt_variety_code.to_s != ""
#
#	session[:spray_program_result_form][:rmt_variety_combo_selection] = rmt_variety_code
#	@protocol = SprayProgram.find_by_sql("select * from spray_programs").map{|program_code|[program_code.spray_program_code]}
#	@protocol.unshift("<empty>")
#	else
#	@protocol = ["<empty>"]
#	end
#
##	render (inline) the html to replace the contents of the td that contains the dropdown
#	render :inline => %{
#		<%= select('spray_program_result','spray_program_code',@protocol)%>
#<%= observe_field('spray_program_result_spray_program_code',:update => 'spray_result_cell',:url => {:action => session[:spray_program_result_form][:spray_program_code_observer][:remote_method]},:complete => session[:spray_program_result_form][:spray_program_code_observer][:on_completed_js])%>
#
#		}
#end

  def spray_program_spray_program_code_changed
    spray_program_code                                                       = get_selected_combo_value(params)
    session[:spray_program_result_form][:spray_program_code_combo_selection] = spray_program_code
    @spray_result                                                            =["<empty>", "passed", "failed"]
    render :inline => %{
		<%= select('spray_program_result','spray_result',@spray_result)%>


		}
  end

  def spray_program_result_commodity_code_changed
    commodity_code                                                       = get_selected_combo_value(params)
    session[:spray_program_result_form][:commodity_code_combo_selection] = commodity_code
    @rmt_variety_codes                                                   = SprayProgramResult.rmt_variety_codes_for_commodity_code(commodity_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
    render :inline => %{
		<%= select('spray_program_result','rmt_variety_code',@rmt_variety_codes)%>
		}

  end

  def complete_spray_program_results
    return if authorise_for_web(program_name?, 'grower_commitment_edit')==false

    @id = params[:id]
    render :inline=> %{
                      <script>
                          if (confirm("Are you sure all spray program result data have been correctly captured?") == true){
                              window.location.href = "/quality_control/grower_commitment/complete_spray_program_results_yes/<%=@id%>";
                          }else {

                              window.location.href = "/quality_control/grower_commitment/complete_spray_program_results_no";
                          }

                      </script>
                  }
  end

  def complete_spray_program_results_no
    render :inline=> %{
        <script>
          window.close();
        </script>
    }
  end

  def complete_spray_program_results_yes
    begin
      ActiveRecord::Base.transaction do
        @grower_commitment = GrowerCommitment.find(params[:id])
#        spray_program_results = SprayProgramResult.find_all_by_grower_commitment_id(params[:id])
#        if(spray_program_results.length == 0)
#          session[:alert] = "Cannot complete: you must have atleast 1 spray_program_result"
#          render :inline=> %{
#              <script>
#                window.close();
#              </script>
#          },:layout=>'content'
#          return
#        elsif((spray_program = (spray_program_results.detect() { |spray_prog| spray_prog.spray_result.upcase == 'FAILED'})) != nil)
#          session[:alert] = "Cannot complete: spray program id=#{spray_program.id} has failed"
#          render :inline=> %{
#              <script>
#                window.close();
#              </script>
#          },:layout=>'content'
#          return
#        end

        @grower_commitment.update_attribute(:grower_commitment_data_capture_date_time, Time.now)

        grower_commitment_data_captured_delivery_route_steps = DeliveryRouteStep.find_by_sql("SELECT delivery_route_steps.*,deliveries.id as delivery_id
            FROM delivery_route_steps
            JOIN deliveries ON delivery_route_steps.delivery_id=deliveries.id
              JOIN seasons on seasons.season_code=deliveries.season_code
                JOIN grower_commitments ON grower_commitments.farm_id=deliveries.farm_id
            where grower_commitments.farm_id=#{@grower_commitment.farm_id} and grower_commitments.season='#{@grower_commitment.season}' and delivery_route_steps.route_step_code='grower_commitment_data_captured'") #.map{|o| [o.id,o.route_step_code,o.delivery_id]}
        
        if (grower_commitment_data_captured_delivery_route_steps.length > 0)
#          puts "Updating grower_commitment_data_captured_delivery_route_steps for deliveries : " + grower_commitment_data_captured_delivery_route_steps.map{|d| d.delivery_id}.join(";")
          DeliveryRouteStep.bulk_update({:date_activated=>"'#{Time.now}'", :date_completed=>"'#{Time.now}'"}, "id", grower_commitment_data_captured_delivery_route_steps.map { |r| r.id }) #:date_activated=>"'#{Time.now}'",
          grower_commitment_data_captured_delivery_route_steps.map { |rs| Delivery.update(rs.delivery_id, {:delivery_status=>rs.route_step_code}) }
        end

        render :inline => %{
                  <script>
                    window.opener.frames[1].location.href = "/quality_control/grower_commitment/edit_grower_commitment/<%= @grower_commitment.id%>";
                    window.close();
                  </script>
          }, :layout => 'content'
      end
    rescue
      raise $!
    end
  end

  def complete_mrl_results
    return if authorise_for_web(program_name?, 'grower_commitment_edit')==false

    @id = params[:id]
    render :inline=> %{
                      <script>
                          if (confirm("Are you sure all mrl result data have been correctly captured?") == true){
                              window.location.href = "/quality_control/grower_commitment/complete_mrl_results_yes/<%=@id%>";
                          }else {

                              window.location.href = "/quality_control/grower_commitment/complete_mrl_results_no";
                          }

                      </script>
                  }
  end

  def complete_mrl_results_no
    render :inline=> %{
        <script>
          window.close();
        </script>
    }
  end

  def complete_mrl_results_yes
    begin
      ActiveRecord::Base.transaction do
        @grower_commitment = GrowerCommitment.find(params[:id])
        @grower_commitment.update_attribute(:mrl_data_capture_date_time, Time.now)

        mrl_data_capture_delivery_route_steps = DeliveryRouteStep.find_by_sql("SELECT delivery_route_steps.*,deliveries.id as delivery_id
            FROM delivery_route_steps
            JOIN deliveries ON delivery_route_steps.delivery_id=deliveries.id
              JOIN seasons on seasons.season_code=deliveries.season_code
              JOIN grower_commitments ON grower_commitments.farm_id=deliveries.farm_id
            where grower_commitments.farm_id=#{@grower_commitment.farm_id} and grower_commitments.season='#{@grower_commitment.season}' and delivery_route_steps.route_step_code='mrl_data_capture_completed'") #.map{|o| [o.id,o.route_step_code,o.delivery_id]}
        if (mrl_data_capture_delivery_route_steps.length > 0)
          DeliveryRouteStep.bulk_update({:date_activated=>"'#{Time.now}'", :date_completed=>"'#{Time.now}'"}, "id", mrl_data_capture_delivery_route_steps.map { |r| r.id }) #:date_activated=>"'#{Time.now}'",
          mrl_data_capture_delivery_route_steps.map { |rs| Delivery.update(rs.delivery_id, {:delivery_status=>rs.route_step_code}) }
        end
        render :inline => %{
              <script>
                window.opener.frames[1].location.href = "/quality_control/grower_commitment/edit_grower_commitment/<%= @grower_commitment.id %>";
                window.close();
              </script>
      }, :layout => 'content'
      end
    rescue
      raise $!
    end
#    end
  end

  def re_open_mrl_results
    begin
      ActiveRecord::Base.transaction do
        @grower_commitment = GrowerCommitment.find(params[:id])
        @grower_commitment.update_attribute(:mrl_data_capture_date_time, "NULL")

        mrl_data_capture_delivery_route_steps = DeliveryRouteStep.find_by_sql("SELECT delivery_route_steps.*,deliveries.id as delivery_id
            FROM delivery_route_steps
            JOIN deliveries ON delivery_route_steps.delivery_id=deliveries.id
              JOIN seasons on seasons.season_code=deliveries.season_code
              JOIN grower_commitments ON grower_commitments.farm_id=deliveries.farm_id
            where grower_commitments.farm_id=#{@grower_commitment.farm_id} and grower_commitments.season='#{@grower_commitment.season}' and delivery_route_steps.route_step_code='mrl_data_capture_completed'") #.map{|o| [o.id,o.route_step_code,o.delivery_id]}
        if (mrl_data_capture_delivery_route_steps.length > 0)
          DeliveryRouteStep.bulk_update({:date_completed=>"NULL"}, "id", mrl_data_capture_delivery_route_steps.map { |r| r.id }) #:date_activated=>"'#{Time.now}'",
          mrl_data_capture_delivery_route_steps.map { |rs| Delivery.update(rs.delivery_id, {:delivery_status=>rs.route_step_code}) }
        end
        render :inline => %{
              <script>
                window.opener.frames[1].location.href = "/quality_control/grower_commitment/edit_grower_commitment/<%= @grower_commitment.id %>";
                window.close();
              </script>
      }, :layout => 'content'
      end
    rescue
      raise $!
    end
#    end
  end
end
