class Reports::ReportsController < ApplicationController
  layout 'content'

  def program_name?
    "reports"
  end

  def bypass_generic_security?
    true
  end

  def report_index
    return unless authorise_for_web(program_name?, 'search_engine') # Search engine same level of permission as report_index

    DataMinerReport.sync_reports

    if params[:page] != nil
      session[:data_miner_report_page] = params['page']
      render_report_index
      return
    else
      session[:data_miner_report_page] = nil
    end

    list_query = "@data_miner_report_pages = Paginator.new self, DataMinerReport.count, @@page_size,@current_page
  	     @data_miner_reports = DataMinerReport.find(:all, :order => 'group_name, report_name',
  	                :limit=>@data_miner_report_pages.items_per_page,
  	                :offset=>@data_miner_report_pages.current.offset)"
    session[:query] = list_query
    render_report_index
  end

  def render_report_index
    @can_edit     = authorise('reports', 'edit', session[:user_id])
    @can_delete   = authorise('reports', 'delete', session[:user_id])
    @current_page = session[:data_miner_report_page] if session[:data_miner_report_page]
    @current_page = params['page'] if params['page']
    @data_miner_reports = eval(session[:query]) if !@data_miner_reports


    render :inline => %{
      <% grid                     = build_data_miner_reports_grid(@data_miner_reports,@can_edit,@can_delete)%>
      <% grid.caption             = 'Reports' %>
      <% grid.group_fields        = ['group_name'] %>
      <% grid.grouped             = true %>
      <% @header_content          = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_data_miner_report
    return if authorise_for_web('reports', 'edit')==false
    id = params[:id]
    if id && @data_miner_report = DataMinerReport.find(id)
      render_edit_data_miner_report
    end
  end

  def render_edit_data_miner_report
    render :inline => %{
    		<% @content_header_caption = "'edit report'"%>
    		<%= build_data_miner_report_form(@data_miner_report,'update_data_miner_report','update_data_miner_report',true)%>
		}, :layout => 'content'
  end

  def update_data_miner_report
    begin
      if params[:page]
        session[:data_miner_report_page] = params['page']
        render_report_index
        return
      end

      @current_page = session[:data_miner_report_page]
      id = params[:data_miner_report][:id]
      if id && @data_miner_report = DataMinerReport.find(id)
        if @data_miner_report.update_attributes(params[:data_miner_report])
          @data_miner_reports = eval(session[:query])
          flash[:notice] = 'report record updated'
          render_report_index
        else
          render_edit_data_miner_report
        end
      end
    rescue
      handle_error("record could not be updated, reason : " + $!)
    end
  end

  #===============================================
  #  My View Code
  #===============================================

  def new_tag
    #return if authorise_for_web('tags','create')==false
#	  render_new_tag
  end

  def render_new_tag
    render :inline => %{
	      <% @content_header_caption = "'create new tag'" %>
	      <%= build_tag_form(@tag,'create_tag', 'create_tag',false,@is_create_retry)%>
	   }, :layout=>'content'
  end

  def create_tag
    begin
      @tag = MyTag.new(params[:tag])
      @tag.user_name = session[:user_id].user_name
      if @tag.save
        redirect_to_index("The report tag has been created successifully!")
      else
        @is_create_retry = true
        render_new_tag
      end

    rescue
      handle_error("Your tag could not be created")
    end
  end

  def list_tags
    if params[:page] != nil
      session[:tags_page] = params['page']
      render_list_tags
      return
    else
      session[:tags_page] = nil
    end

    list_query = "@my_tag_pages = Paginator.new self, MyTag.count, @@page_size,@current_page
	     @my_tags = MyTag.find(:all, :conditions=>['user_name = ?', session[:user_id].user_name],
	                :limit=>@my_tag_pages.items_per_page,
	                :offset=>@my_tag_pages.current.offset)"
    session[:query] = list_query
    render_list_tags
  end

  def render_list_tags
    @can_edit = authorise('reports', 'edit', session[:user_id])
    @can_delete = authorise('reports', 'delete', session[:user_id])
    @current_page = session[:tags_page] if session[:tags_page]
    @current_page = params['page'] if params['page']
    @my_tags = eval(session[:query]) if !@my_tags

      render :inline => %{
        <% grid            = build_my_tags_grid(@my_tags,@can_edit,@can_delete)%>
        <% grid.caption    = 'list of my tags' %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
    	}, :layout => 'content'
  end

  def edit_tag
    return if authorise_for_web('reports', 'edit')==false
    id = params[:id]
    if id && @tag = MyTag.find(id)

      render_edit_tag
    end
  end

  def render_edit_tag
    render :inline => %{
    		<% @content_header_caption = "'edit tag'"%>
    		<%= build_tag_form(@tag,'update_tag','update_tag',true)%>
		}, :layout => 'content'
  end

  def update_tag
    begin
      if params[:page]
        session[:tags_page] = params['page']
        render_list_tags
        return
      end

      @current_page = session[:tags_page]
      id = params[:tag][:id]
      tag_name = params[:tag][:tag_name]
      if id && @tag = MyTag.find(id)
        if @tag.update_attributes(params[:tag])
          @my_tags = eval(session[:query])
          flash[:notice] = 'tag record updated'
          render_list_tags
        else
          render_edit_tag
        end
      end
    rescue
      handle_error("record could not be updated, reason : " + $!)
    end
  end

  def delete_tag
    begin
      return if authorise_for_web('reports', 'delete')== false
      if params[:page]
        session[:tags_page] = params['page']
        render_list_tags
        return
      end
      id = params[:id]
      if id && tag = MyTag.find(id)
        tag.destroy
        session[:alert] = "tag record deleted."
        render_list_tags
      end
    rescue
      handle_error('record could not be deleted, reason : ' + $!)
    end
  end

  # Saving report as MY View
  def save_as_view
    session[:tags] = nil if session[:tags] != nil
    session[:tags] = Hash.new
    render :inline=> %{
            <% @url_base = "http://" + request.host_with_port + "/" + "reports/reports/render_save_as_view" %>
            <script>
               window.open("<%=@url_base%>", "save_as_view","width=850,height=400,top=200,left=200,toolbar=1,menubar=1,status=1,scrollbars=1,resizable=1");
            </script>

         }, :layout=>'content'
    #render_save_as_view
  end

  def render_save_as_view
    @user_defined_report = UserDefinedReport.new if !@user_defined_report
    @tag_list = UserDefinedReport.get_tags_list(session[:user_id].user_name)
    @tag_list.unshift("<empty>")
    #TODO: FIX: on edit, existing_reports get only same report...
    @existing_reports_list = UserDefinedReport.get_full_list_of_existing_user_defined_reports(session[:user_id].user_name, dm_session[:report_name])
    @existing_reports_list.unshift("<empty>")

    render :template=> 'reports/reports/new_user_defined_report_form.rhtml', :layout=>'content'
  end

  def save_report_as_view
    begin
      user_defined_report_name = params['user_defined_report']['user_defined_report_name']
      report_name = dm_session[:report_name]
      user_name = session[:user_id].user_name
      ranking = params['user_defined_report']['ranking']
      tags = ""
      # session[:tags].each do |k, v|
      #   if k.to_s != "existing_user_defined_report" && v.to_s.index("<empty>") == nil && v.to_s != ""
      #     if tags == ""
      #       tags += v.to_s
      #     else
      #       tags += "," + v.to_s
      #     end
      #   end
      # end
      report_state = prepare_dumped_object

      test_uniqueness_of_defined_report_name = UserDefinedReport.validate_uniqueness_of_user_defined_report_name(report_name, user_name, user_defined_report_name)

      if test_uniqueness_of_defined_report_name == true
        session[:user_defined_report_params] = nil if session[:user_defined_report_params] != nil
        session[:user_defined_report_params] = Hash.new
        session[:user_defined_report_params][:report_name] = report_name
        session[:user_defined_report_params][:user_defined_report_name] = user_defined_report_name
        session[:user_defined_report_params][:user_name] = user_name
        session[:user_defined_report_params][:ranking] = ranking
        session[:user_defined_report_params][:tags] = tags
        session[:user_defined_report_params][:report_state] = report_state
        render :inline=> %{
                  <script>
                       if (confirm("The view name already exists. Do you want to override id?.")== true) {
                           window.location.href = '/reports/reports/user_defined_report_name_override_confirmed';
                       }else {
                           window.location.href = '/reports/reports/user_defined_report_name_override_cancelled';
                           //history.back();
                       }
                  </script>
             }
      else
        # TODO: Get report from id passed in or stored in session... (Need to handle call from reports, my view, all view & lookup too?
        report = DataMinerReport.find_by_report_name(report_name)
        @user_defined_report = UserDefinedReport.new
        @user_defined_report.report_name = report_name
        @user_defined_report.user_name = user_name
        @user_defined_report.author_id = session[:user_id].id
        @user_defined_report.user_defined_report_name = user_defined_report_name
        @user_defined_report.ranking = ranking
        @user_defined_report.tags = tags
        #@user_defined_report.report_state = report_state
        @user_defined_report.view_state = report_state
        if report
          @user_defined_report.report_id  = report.id
          @user_defined_report.code       = report.code
          @user_defined_report.fieldlist  = report.fieldlist
          @user_defined_report.group_name = report.group_name
        end

        if @user_defined_report.save
          @user_defined_report.users << User.find([session[:user_id].id])
          redirect_to_index("report view has been created successifully!")
        else
          render_save_as_view
        end

      end
    rescue
      handle_error("report view could not be saved, reason : " + $!)
    end
  end

  def user_defined_report_name_override_confirmed
    begin

      report_name = session[:user_defined_report_params][:report_name]
      user_defined_report_name = session[:user_defined_report_params][:user_defined_report_name]
      user_name = session[:user_defined_report_params][:user_name]
      ranking = session[:user_defined_report_params][:ranking]
      tags = session[:user_defined_report_params][:tags]
      report_state = session[:user_defined_report_params][:report_state]
        report = DataMinerReport.find_by_report_name(report_name)
        if report
          report_id  = report.id
          code       = report.code
          fieldlist  = report.fieldlist
          group_name = report.group_name
        else
          report_id  = nil
          code       = nil
          fieldlist  = nil
          group_name = nil
        end

      if report_name && user_name && user_defined_report_name && @user_defined_report = UserDefinedReport.find_by_report_name_and_user_name_and_user_defined_report_name(report_name, user_name, user_defined_report_name)
        #if @user_defined_report.update_attributes(:report_name=>report_name, :user_defined_report_name=>user_defined_report_name, :user_name=>user_name, :ranking=>ranking, :tags=>tags, :report_state=>report_state)
        if @user_defined_report.update_attributes(:report_name=>report_name, :user_defined_report_name=>user_defined_report_name, :user_name=>user_name, :ranking=>ranking, :tags=>tags, :view_state=>report_state,
          :report_id => report_id, :code => code, :fieldlist => fieldlist, :group_name => group_name)
          redirect_to_index("report view has been updated successifully!")
        else
          render_save_as_view
        end
      end

    rescue
      handle_error("Report view could not be saved, reason : " + $!)
    end
  end

  def user_defined_report_name_override_cancelled
    @user_defined_report = UserDefinedReport.new
    render_save_as_view
  end

  def prepare_dumped_object
    dumped_object = Hash.new
    dumped_object[:search_fields] = dm_session[:search_fields]
    dumped_object[:full_parameter_query] = dm_session[:full_parameter_query]
    dumped_object[:parameter_fields_values] = dm_session[:parameter_fields_values]
    dumped_object[:search_engine_or_values] = dm_session[:search_engine_or_values]
    dumped_object[:search_engine_limit] = dm_session[:search_engine_limit]
    dumped_object[:functions] = dm_session[:functions]
    dumped_object[:search_engine_group_by_columns] = dm_session[:search_engine_group_by_columns]
    dumped_object[:search_engine_order_by_columns] = dm_session[:search_engine_order_by_columns]
    dumped_object[:main_table_name] = dm_session[:main_table_name]
    dumped_object[:table_name] = dm_session[:table_name]
    dumped_object[:report_name] = dm_session[:report_name]
    dumped_object[:operator_signs] = dm_session[:operator_signs]
    dumped_object[:columns_list] = dm_session[:columns_list] if dm_session[:columns_list]
    # marshalled_object = Marshal.dump(dumped_object)
    # return marshalled_object
    dumped_object.to_yaml
  end

  def list_all_views
    return unless authorise_for_web(program_name?, 'all_report_views')
    if params[:page] != nil
      session[:all_user_defined_report_page] = params['page']
      render_list_all_views
      return
    else
      session[:all_user_defined_report_page] = nil
    end

    list_query = "@user_defined_report_pages = Paginator.new self, UserDefinedReport.count, @@page_size,@current_page
  	     @user_defined_reports = UserDefinedReport.find(:all, :select => 'id, report_name, user_defined_report_name, user_name, ranking, tags,
         code, fieldlist, group_name, updated_at, show_parameters, webquery_only, parameter_values,
         function_values, grouping_values, order_by_values',
  	                :order=> 'report_name, user_defined_report_name, user_name',
  	                :limit=>@user_defined_report_pages.items_per_page,
  	                :offset=>@user_defined_report_pages.current.offset)"
    session[:query] = list_query
    render_list_all_views
  end

  def list_my_views
    if params[:page] != nil
      session[:user_defined_report_page] = params['page']
      render_list_my_views
      return
    else
      session[:user_defined_report_page] = nil
    end

  	     #@user_defined_reports = UserDefinedReport.find(:all, :conditions=>['user_name = ?', session[:user_id].user_name],
    list_query = "@user = User.find(#{session[:user_id].id})
         @user_defined_report_pages = Paginator.new self, UserDefinedReport.count, @@page_size,@current_page
  	     @user_defined_reports = @user.user_defined_reports.find(:all,
                                 :select => 'id, report_name, user_defined_report_name, user_name, ranking, tags,
                                             code, fieldlist, author_id, group_name, updated_at, show_parameters, webquery_only, parameter_values,
         function_values, grouping_values, order_by_values, #{session[:user_id].id} current_user_id',
  	                :order=> 'report_name, user_defined_report_name, ranking',
  	                :limit=>@user_defined_report_pages.items_per_page,
  	                :offset=>@user_defined_report_pages.current.offset)"
    session[:query] = list_query
    render_list_my_views
  end

  # Download a WebQuery (.iqy) file.
  def download_iqy
    id = params[:id]
    if id && user_defined_report = UserDefinedReport.find(id)
      s = "WEB\n1\nhttp://#{request.host_with_port}/webquery/#{params[:id]}"
      send_data s, :filename => "#{user_defined_report.report_name}.iqy", :type => 'text/plain'
    else
      render :text => "Unable to download the file - view not found.'"
    end
  end

  def render_list_all_views
    @can_edit     = authorise('reports', 'edit', session[:user_id])
    @can_delete   = authorise('reports', 'delete', session[:user_id])
    @current_page = session[:all_user_defined_report_page] if session[:all_user_defined_report_page]
    @current_page = params['page'] if params['page']
    @user_defined_reports = eval(session[:query]) if !@user_defined_reports

      render :inline => %{
        <% grid                 = build_all_views_grid(@user_defined_reports,@can_edit,@can_delete)%>
        <% grid.caption         = 'list of all report views (grouped by report_name)' %>
        <% grid.group_fields    = ['report_name'] %>
        <% grid.grouped         = true %>
        <% grid.group_collapsed = true %>
        <% @header_content      = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
  end

  def render_list_my_views
    @can_edit = authorise('reports', 'edit', session[:user_id])
    @can_delete = authorise('reports', 'delete', session[:user_id])
    @current_page = session[:user_defined_report_page] if session[:user_defined_report_page]
    @current_page = params['page'] if params['page']
    @user_defined_reports = eval(session[:query]) if !@user_defined_reports

      # @multi_select = 'some_or_other_action'
      # @grid_selected_rows = []
      # @grid_selected_rows << @user_defined_reports[0]
      render :inline => %{
        <% grid            = build_my_views_grid(@user_defined_reports,@can_edit,@can_delete)%>
        <% grid.caption    = 'list of my report views' %>
      <%# grid.group_fields     = ['code', 'report_name'] %>
      <%# grid.grouped          = true %>
      <%# grid.groupable_fields = ['report_name', 'code', 'ranking'] %>

      <%# grid.group_summary_depth  = 2 %>
      <%# grid.group_fields_to_sum   = ['ranking'] %>
      <%# grid.group_fields_to_count = ['ranking'] %>
      <%# grid.group_fields_to_avg   = ['ranking'] %>
      <%# grid.group_fields_to_max   = ['ranking'] %>
      <%# grid.group_fields_to_min   = ['ranking'] %>

      <%# grid.group_headers = [{:start_column_name => 'report_name', :number_of_columns => 3, :title_text => 'Report'},
                               {:start_column_name => 'fieldlist', :number_of_columns => 2, :title_text => 'Arbitrary'}] %>
      <%# grid.group_headers_colspan = true %>
      <%# grid.no_of_frozen_cols = 2 %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
        }, :layout => 'content'
  end

  # Work with UserDefinedReports - all views.
  def edit_all_view
    return if authorise_for_web('reports', 'edit')==false
    id = params[:id]
    session[:view_report_id] = nil if session[:view_report_id] != nil
    session[:view_report_id] = id
    if id && @user_defined_report = UserDefinedReport.find(id)
      render_edit_all_view
    end
  end

  def render_edit_all_view

    @user_defined_report = UserDefinedReport.find(session[:view_report_id]) if !@user_defined_report
    # @user_defined_report.create_tags
    @linked_users = @user_defined_report.user_ids
    @users = User.find_by_sql("select users.id, users.first_name, users.last_name
from programs
join program_users on program_users.program_id = programs.id
join users on users.id = program_users.user_id
where programs.program_name = 'reports'
order by users.last_name, users.first_name").map {|u| ["#{u.first_name} #{u.last_name}", u.id] }
    # session[:tags] = nil if session[:tags] != nil
    # session[:tags] = Hash.new
    # session[:tags][:tag1] = @user_defined_report.tag1
    # session[:tags][:tag2] = @user_defined_report.tag2
    # session[:tags][:tag3] = @user_defined_report.tag3
    # session[:tags][:tag4] = @user_defined_report.tag4
    # session[:tags][:tag5] = @user_defined_report.tag5
    dm_session[:report_name] = nil if dm_session[:report_name] != nil
    dm_session[:report_name] = @user_defined_report.report_name
    # @tag_list = UserDefinedReport.get_tags_list(session[:user_id].user_name)
    # @tag_list.unshift("<empty>")
    @existing_reports_list = [@user_defined_report.user_defined_report_name, "<empty>"]

    render :template=> 'reports/reports/edit_user_defined_report_all_form.rhtml', :layout=>'content'
  end

  def update_all_view
    begin
      if params[:page]
        session[:user_defined_report_page] = params['page']
        render_list_all_views
        return
      end

      @current_page            = session[:user_defined_report_page]
      id                       = params['id']
      user_defined_report_name = params[:user_defined_report][:user_defined_report_name]
      user_name                = session[:user_id].user_name
      ranking                  = params[:user_defined_report][:ranking]
      code                     = params[:user_defined_report][:code]
      group_name               = params[:user_defined_report][:group_name]
      fieldlist                = params[:user_defined_report][:fieldlist]
      show_parameters          = params[:user_defined_report][:show_parameters]
      webquery_only            = params[:user_defined_report][:webquery_only]
      tags                     = ""
      # session[:tags].each do |k, v|
      #   if k.to_s != "existing_user_defined_report" && v.to_s.index("<empty>") == nil && v.to_s != ""
      #     if tags == ""
      #       tags += v.to_s
      #     else
      #       tags += "," + v.to_s
      #     end
      #   end
      # end
      if id && @user_defined_report = UserDefinedReport.find(id)
        if params[:linked_users].nil? || params[:linked_users].empty?
          @user_defined_report.errors.add_to_base('The view must be linked to at least one user')
          render_edit_all_view
          return
        end
        ids = params[:linked_users].map {|i| i.to_i }
        @user_defined_report.user_ids = ids
        if @user_defined_report.update_attributes(:user_defined_report_name=>user_defined_report_name,
                                                  :ranking=>ranking,
                                                  :tags=>tags,
                                                  :user_name=>user_name,
                                                  :code => code,
                                                  :group_name => group_name,
                                                  :fieldlist => fieldlist,
                                                  :show_parameters => show_parameters,
                                                  :webquery_only => webquery_only)
          @user_defined_reports = eval(session[:query])
          flash[:notice] = 'user defined report record updated'
          render_list_all_views
        else
          render_edit_all_view
        end
      end

    rescue
      handle_error("The report view could not be updated, reason : " + $!)
    end
  end

  def delete_all_view
    begin
      return if authorise_for_web('reports', 'delete')== false
      if params[:page]
        session[:user_defined_report_page] = params['page']
        render_list_all_views
        return
      end
      id = params[:id]
      if id && user_defined_report = UserDefinedReport.find(id)
        user_defined_report.destroy
        session[:alert] = "report view record deleted."
        render_list_all_views
      end
    rescue
      handle_error('record could not be deleted, reason : ' + $!)
    end
  end

  def edit_my_view
    return if authorise_for_web('reports', 'edit')==false
    id = params[:id]
    session[:view_report_id] = nil if session[:view_report_id] != nil
    session[:view_report_id] = id
    if id && @user_defined_report = UserDefinedReport.find(id)
      render_edit_my_view
    end
  end

  # Work with UserDefinedReports - my views.
  def render_edit_my_view

    @user_defined_report = UserDefinedReport.find(session[:view_report_id]) if !@user_defined_report
    @linked_users = @user_defined_report.user_ids
    @users = User.find_by_sql("select users.id, users.first_name, users.last_name
from programs
join program_users on program_users.program_id = programs.id
join users on users.id = program_users.user_id
where programs.program_name = 'reports'
order by users.last_name, users.first_name").map {|u| ["#{u.first_name} #{u.last_name}", u.id] }
    # @user_defined_report.create_tags
    # session[:tags] = nil if session[:tags] != nil
    # session[:tags] = Hash.new
    # session[:tags][:tag1] = @user_defined_report.tag1
    # session[:tags][:tag2] = @user_defined_report.tag2
    # session[:tags][:tag3] = @user_defined_report.tag3
    # session[:tags][:tag4] = @user_defined_report.tag4
    # session[:tags][:tag5] = @user_defined_report.tag5
    dm_session[:report_name] = nil if dm_session[:report_name] != nil
    dm_session[:report_name] = @user_defined_report.report_name
    # @tag_list = UserDefinedReport.get_tags_list(session[:user_id].user_name)
    # @tag_list.unshift("<empty>")
    @existing_reports_list = [@user_defined_report.user_defined_report_name, "<empty>"]

    render :template=> 'reports/reports/edit_user_defined_report_form.rhtml', :layout=>'content'
  end

  def update_my_view
    begin
      if params[:page]
        session[:user_defined_report_page] = params['page']
        render_list_my_views
        return
      end


      @current_page = session[:user_defined_report_page]
      id = params['id']
      #puts "ID is : " + id.to_s
      user_defined_report_name = params[:user_defined_report][:user_defined_report_name]
      user_name = session[:user_id].user_name
      ranking = params[:user_defined_report][:ranking]
      code                     = params[:user_defined_report][:code]
      group_name               = params[:user_defined_report][:group_name]
      fieldlist                = params[:user_defined_report][:fieldlist]
      show_parameters          = params[:user_defined_report][:show_parameters]
      webquery_only            = params[:user_defined_report][:webquery_only]
      tags = ""
      # session[:tags].each do |k, v|
      #   if k.to_s != "existing_user_defined_report" && v.to_s.index("<empty>") == nil && v.to_s != ""
      #     if tags == ""
      #       tags += v.to_s
      #     else
      #       tags += "," + v.to_s
      #     end
      #   end
      # end
      if id && @user_defined_report = UserDefinedReport.find(id)
        if params[:linked_users].nil? || params[:linked_users].empty?
          @user_defined_report.errors.add_to_base('The view must be linked to at least one user')
          render_edit_my_view
          return
        end
        ids = params[:linked_users].map {|i| i.to_i }
        @user_defined_report.user_ids = ids
        if @user_defined_report.update_attributes(:user_defined_report_name=>user_defined_report_name,
                                                  :ranking=>ranking,
                                                  :tags=>tags,
                                                  :user_name=>user_name,
                                                  :code => code,
                                                  :group_name => group_name,
                                                  :fieldlist => fieldlist,
                                                  :show_parameters => show_parameters,
                                                  :webquery_only => webquery_only)
          @user_defined_reports = eval(session[:query])
          flash[:notice] = 'user defined report record updated'
          render_list_my_views
        else
          render_edit_my_view
        end
      end

    rescue
      handle_error("The report view could not be updated, reason : " + $!)
    end
  end

  def delete_my_view
    begin
      return if authorise_for_web('reports', 'delete')== false
      if params[:page]
        session[:user_defined_report_page] = params['page']
        render_list_my_views
        return
      end
      id = params[:id]
      if id && user_defined_report = UserDefinedReport.find(id)
        user_defined_report.destroy
        session[:alert] = "report view record deleted."
        render_list_my_views
      end
    rescue
      handle_error('record could not be deleted, reason : ' + $!)
    end
  end

  # Download a view as csv file.
  def download_my_view
    launch_my_view( true )
  end

  # Launch a view. If the +show_parameters flag is set, prompt for parameters else run the report and display the grid.
  def launch_my_view( for_download=false)
    begin
      id = params[:id]
      if id && @user_defined_report = UserDefinedReport.find(id)
        # report_state = @user_defined_report.report_state
        # report_state_hash = Marshal.load(report_state)
        report_state = @user_defined_report.view_state
        report_state_hash = YAML.load(report_state)

        clear_dm_session()

        dm_session[:search_fields]                  = report_state_hash[:search_fields]
        dm_session[:full_parameter_query]           = report_state_hash[:full_parameter_query]
        dm_session[:parameter_fields_values]        = report_state_hash[:parameter_fields_values]
        dm_session[:search_engine_or_values]        = report_state_hash[:search_engine_or_values]
        dm_session[:search_engine_limit]            = report_state_hash[:search_engine_limit]
        dm_session[:functions]                      = report_state_hash[:functions]
        dm_session[:search_engine_group_by_columns] = report_state_hash[:search_engine_group_by_columns]
        dm_session[:search_engine_order_by_columns] = report_state_hash[:search_engine_order_by_columns]
        dm_session[:main_table_name]                = report_state_hash[:main_table_name]
        dm_session[:table_name]                     = report_state_hash[:table_name]
        dm_session[:report_name]                    = report_state_hash[:report_name]
        dm_session[:operator_signs]                 = report_state_hash[:operator_signs]
        dm_session[:columns_list]                   = report_state_hash[:columns_list]

        dm_session[:redirect_method]                = nil
        dm_session[:redirect]                       = nil

        if @user_defined_report.show_parameters
          relaunch_search_form(@user_defined_report.user_defined_report_name)
        else
          parms = {}
          @user_defined_report.setup_params(parms, for_download)
          # logger.info ">>>> parms: #{parms.inspect}"
          # logger.info ">>> PRE statement = #{@user_defined_report.sql_statement(report_state_hash)}"
          statement = apply_functions(@user_defined_report.sql_statement(report_state_hash), parms)
          # logger.info ">>> POST statement = #{statement}"
          #if statement.upcase.index(" JOIN") == nil
          if statement =~ / JOIN/i
            dm_session[:table_name] = @user_defined_report.value_from_report_hash(:main_table_name)
          else
            table_name = FieldParser.get_table_name(statement)
            dm_session[:table_name] = table_name
          end

          where_clause = ''
          if dm_session[:grid_type] == "summary"
            #if statement.upcase.index(" WHERE") != nil
            if statement =~ / WHERE/i
              where_clause = FieldParser.get_where_clause(statement).split("|splitter|")[0].to_s
            end
          end

          #puts "WHERE CLAUSE : #{where_clause}  %%%"
          dm_session[:search_engine_where_clause] = nil if dm_session[:search_engine_where_clause] != nil
          dm_session[:search_engine_where_clause] = where_clause
          # logger.info ">>> SQL: #{statement}"
          dm_session[:search_engine_query_definition]    = statement
          #dm_session[:search_engine_query_definition]    = apply_functions(@user_defined_report.sql_statement(report_state_hash))
          dm_session[:search_engine_grid_action_columns] = []
          dm_session[:search_engine_multi_select]        = nil

          if for_download
            dm_session[:csv_export_filename] = @user_defined_report.user_defined_report_name || @user_defined_report.report_name
            #render :text => "TEST"
            #@url_base = "http://#{request.host_with_port}/development_tools/data/export_se_grid_to_csv"
            #export_se_grid_to_csv
            redirect_to :controller => 'development_tools/data', :action => 'export_se_grid_to_csv'
          else
            if dm_session[:grid_type] == "summary"
              render_summary_grid("http://#{request.host_with_port}#{request.request_uri}", @user_defined_report.user_defined_report_name)
            else   
              render_generic_grid("http://#{request.host_with_port}#{request.request_uri}", @user_defined_report.user_defined_report_name)
            end
          end   
        end

      end
    rescue
      handle_error("The report view could not be launched, reason : " + $!)
    end
  end

  # Observers
  def tag1_combo_changed
    tag_value = params['tag1']
    #session[:tags][:tag1] = tag_value if tag_value.index("<empty>") == nil
    if tag_value != ""
      session[:tags][:tag1] = tag_value
    else
      session[:tags][:tag1] = ""
    end
    @existing_reports_list = UserDefinedReport.get_existing_user_definded_report_names(session[:tags], session[:user_id].user_name, dm_session[:report_name])
    render :inline=>%{
	       <%= select('user_defined_report', 'existing_report', @existing_reports_list) %>
	       <%=image_tag 'spinner.gif', :id=>'img_existing_reports', :style=>'display:none;'%>
	       <%= observe_field "user_defined_report_existing_report", :update=>"report_name_td", :url=>{:action=>"existing_reports_combo_changed"}, :before=>"Element.show('img_existing_reports')", :complete=>"Element.hide('img_existing_reports')", :with=>"'existing_report='+value" %>
	   }
  end

  def tag2_combo_changed
    tag_value = params['tag2']
    if tag_value != ""
      session[:tags][:tag2] = tag_value
    else
      session[:tags][:tag2] = ""
    end
    @existing_reports_list = UserDefinedReport.get_existing_user_definded_report_names(session[:tags], session[:user_id].user_name, dm_session[:report_name])
    render :inline=>%{
	       <%= select('user_defined_report', 'existing_report', @existing_reports_list) %>
	       <%=image_tag 'spinner.gif', :id=>'img_existing_reports', :style=>'display:none;'%>
	       <%= observe_field "user_defined_report_existing_report", :update=>"report_name_td", :url=>{:action=>"existing_reports_combo_changed"}, :before=>"Element.show('img_existing_reports')", :complete=>"Element.hide('img_existing_reports')", :with=>"'existing_report='+value" %>
	   }
  end

  def tag3_combo_changed
    tag_value = params['tag3']
    #session[:tags][:tag3] = tag_value if tag_value.index("<empty>") == nil
    if tag_value != ""
      session[:tags][:tag3] = tag_value
    else
      session[:tags][:tag3] = ""
    end
    @existing_reports_list = UserDefinedReport.get_existing_user_definded_report_names(session[:tags], session[:user_id].user_name, dm_session[:report_name])
    render :inline=>%{
	       <%= select('user_defined_report', 'existing_report', @existing_reports_list) %>
	       <%=image_tag 'spinner.gif', :id=>'img_existing_reports', :style=>'display:none;'%>
	       <%= observe_field "user_defined_report_existing_report", :update=>"report_name_td", :url=>{:action=>"existing_reports_combo_changed"}, :before=>"Element.show('img_existing_reports')", :complete=>"Element.hide('img_existing_reports')", :with=>"'existing_report='+value" %>
	   }
  end

  def tag4_combo_changed
    tag_value = params['tag4']
    #session[:tags][:tag4] = tag_value if tag_value.index("<empty>") == nil
    if tag_value != ""
      session[:tags][:tag4] = tag_value
    else
      session[:tags][:tag4] = ""
    end
    @existing_reports_list = UserDefinedReport.get_existing_user_definded_report_names(session[:tags], session[:user_id].user_name, dm_session[:report_name])
    render :inline=>%{
	       <%= select('user_defined_report', 'existing_report', @existing_reports_list) %>
	       <%=image_tag 'spinner.gif', :id=>'img_existing_reports', :style=>'display:none;'%>
	       <%= observe_field "user_defined_report_existing_report", :update=>"report_name_td", :url=>{:action=>"existing_reports_combo_changed"}, :before=>"Element.show('img_existing_reports')", :complete=>"Element.hide('img_existing_reports')", :with=>"'existing_report='+value" %>
	   }
  end

  def tag5_combo_changed
    tag_value = params['tag5']
    #session[:tags][:tag5] = tag_value if tag_value.index("<empty>") == nil
    if tag_value != ""
      session[:tags][:tag5] = tag_value
    else
      session[:tags][:tag5] = ""
    end
    @existing_reports_list = UserDefinedReport.get_existing_user_definded_report_names(session[:tags], session[:user_id].user_name, dm_session[:report_name])
    render :inline=>%{
	       <%= select('user_defined_report', 'existing_report', @existing_reports_list) %>
	       <%=image_tag 'spinner.gif', :id=>'img_existing_reports', :style=>'display:none;'%>
	       <%= observe_field "user_defined_report_existing_report", :update=>"report_name_td", :url=>{:action=>"existing_reports_combo_changed"}, :before=>"Element.show('img_existing_reports')", :complete=>"Element.hide('img_existing_reports')", :with=>"'existing_report='+value" %>
	   }
  end

  def existing_reports_combo_changed
    existing_user_defined_report_value = params['existing_report']
    session[:tags][:existing_user_defined_report] = existing_user_defined_report_value if existing_user_defined_report_value != ""
    @user_defined_rpt_value = UserDefinedReport.get_user_defined_report_name(session[:tags], session[:user_id].user_name, dm_session[:report_name])
    render :inline=>%{
	       <%= text_field('user_defined_report', 'user_defined_report_name', :value=>@user_defined_rpt_value) %>
	   } 
  end 

  # Reload a grid from a dataminer report.
  def reload_generic_grid
    conn                    = User.connection
    @recordset              = conn.select_all(Globals.cleanup_where(dm_session[:final_statement]))
    @stat                   = dm_session[:search_engine_query_definition]
    @columns_list           = dm_session[:columns_list]
    @grid_configs           = dm_session[:grid_configs]
    @se_grid_action_columns = dm_session[:search_engine_grid_action_columns]
    @multi_sel              = dm_session[:search_engine_multi_select]

    @se_summary_details_grid = false
    @se_grid = true
      render :inline => %{

      <% grid            = build_generic_grid(@recordset, @stat, @columns_list,@se_grid_action_columns,@multi_sel, @grid_configs)%>
        <% grid.caption    = 'view results' if grid.caption == DataGridJquery::DataGrid::DEFAULT_CAPTION %>
        <% grid.fullpage   = true %>
        <% grid.reload_url = "http://#{request.host_with_port}/reports/reports/reload_generic_grid" %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
        <%= grid.render_grid %>
      }, :layout=>'content'
  end

  def reorder_data_miner_report_columns
    return if authorise_for_web('reports', 'edit')==false
    @data_miner_report = DataMinerReport.find(params[:id])
    @columns           = @data_miner_report.columns_in_order
  end

  def apply_data_miner_column_order
    @data_miner_report = DataMinerReport.find(params[:id])
    has_change         = false
    unless params[:re_ordered_list].blank?
      new_order = params[:re_ordered_list].split(',').map {|a| a.sub('col_','').to_i }
      new_order.each_with_index do |a,i|
        if a != i
          has_change = true
          break
        end
      end
    end

    if has_change
      @data_miner_report.re_order_query( new_order )
      flash[:notice]                 = 'report column sequence has been changed'
      flash[:keep_flash_on_redirect] = true
      redirect_to :controller => 'reports/reports', :action => 'report_index'
    else
      flash[:error] = 'Nothing to do: you did not re-order any columns'
      redirect_to :controller => 'reports/reports', :action => 'report_index'
    end

  end
end

