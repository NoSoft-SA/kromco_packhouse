class  Qc::QcSetupController < ApplicationController

  def program_name?
    "qc_setup"
  end

  def bypass_generic_security?
    true
  end

  #*****************************************************************************
  #--------------- QC INSPECTION TYPES ----------------------------------------*
  #*****************************************************************************

  # Return the query used for displaying the inspection types grid.
  def query_for_qc_inspection_types
    "@qc_inspection_type_pages = Paginator.new self, QcInspectionType.count, @@page_size,@current_page
     @qc_inspection_types = QcInspectionType.find(:all,
         :order => 'qc_inspection_type_code',
         :limit => @qc_inspection_type_pages.items_per_page,
         :offset => @qc_inspection_type_pages.current.offset)"
  end

  def list_qc_inspection_types
    return if authorise_for_web(program_name?,'read') == false 

    if params[:page]!= nil 
      session[:qc_inspection_types_page] = params['page']
      render_list_qc_inspection_types
      return 
    else
      session[:qc_inspection_types_page] = nil
    end

    session[:query] = query_for_qc_inspection_types
    render_list_qc_inspection_types
  end


  def render_list_qc_inspection_types
    @pagination_server = "list_qc_inspection_types"
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:qc_inspection_types_page]
    @current_page = params['page']||= session[:qc_inspection_types_page]
    @qc_inspection_types =  eval(session[:query]) if !@qc_inspection_types

    render :inline => %{
      <% grid            = build_qc_inspection_type_grid(@qc_inspection_types,@can_edit,@can_delete)%>
      <% grid.caption    = 'List of all qc_inspection_types' %>
      <% @header_content = grid.build_grid_data %>

    <% @pagination = pagination_links(@qc_inspection_type_pages) if @qc_inspection_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_qc_inspection_types
    return if authorise_for_web(program_name?,'read')== false
    @is_flat_search = true 
    render_qc_inspection_type_search_form
  end

  def render_qc_inspection_type_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
    #	 render (inline) the search form
    render :inline => %{
    <% @content_header_caption = "'search  qc_inspection_types'"%> 

    <%= build_qc_inspection_type_search_form(nil,'submit_qc_inspection_types_search','submit_qc_inspection_types_search',@is_flat_search)%>

    }, :layout => 'content'
  end

  def submit_qc_inspection_types_search
    @qc_inspection_types = dynamic_search(params[:qc_inspection_type] ,'qc_inspection_types','QcInspectionType')
    if @qc_inspection_types.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_qc_inspection_type_search_form
    else
      render_list_qc_inspection_types
    end
  end


  def delete_qc_inspection_type
    begin
      return if authorise_for_web(program_name?,'delete')== false
      if params[:page]
        session[:qc_inspection_types_page] = params['page']
        render_list_qc_inspection_types
        return
      end
      id = params[:id]
      if id && qc_inspection_type = QcInspectionType.find(id)
        qc_inspection_type.destroy
        session[:alert] = " Record deleted."
        render_list_qc_inspection_types
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_qc_inspection_type
    return if authorise_for_web(program_name?,'create')== false
    render_new_qc_inspection_type
  end

  def create_qc_inspection_type
    begin
      @qc_inspection_type = QcInspectionType.new(params[:qc_inspection_type])
      if @qc_inspection_type.save
        session[:alert] = "new record created successfully"
        session[:query] = query_for_qc_inspection_types
        
        render :inline=>%{
          <script>
            window.opener.frames[1].location.href ='/qc/qc_setup/list_qc_inspection_types';
            window.close();
          </script>
      },:layout=>'content'
      else
        @is_create_retry = true
        render_new_qc_inspection_type
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_qc_inspection_type
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new qc_inspection_type'"%> 

    <%= build_qc_inspection_type_form(@qc_inspection_type,'create_qc_inspection_type','create_qc_inspection_type',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def maintain_qc_inspection_type
    render :inline => %{
    <% @content_header_caption = "'edit inspection type'"%> 

    <%= maintain_qc_inspection_type(#{params[:id]}) %>

    }, :layout => 'content'

  end

  def edit_qc_inspection_type
    return if authorise_for_web(program_name?,'edit')==false 
    id = params[:id]
    if id && @qc_inspection_type = QcInspectionType.find(id)
      render_edit_qc_inspection_type
    end
  end

  def render_edit_qc_inspection_type
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit qc_inspection_type'"%> 

    <%= build_qc_inspection_type_form(@qc_inspection_type,'update_qc_inspection_type','update_qc_inspection_type',true)%>

    }, :layout => 'content'
  end

  def update_qc_inspection_type
    begin

      id = params[:qc_inspection_type][:id]
      if id && @qc_inspection_type = QcInspectionType.find(id)
        if @qc_inspection_type.update_attributes(params[:qc_inspection_type])
          @qc_inspection_types = eval(session[:query])
          flash[:notice] = 'record saved'
          render :inline=>%{
            <script>
              window.parent.location.href ='/qc/qc_setup/list_qc_inspection_types';
            </script>
            },:layout=>'content'
        else
          render_edit_qc_inspection_type
        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

  #*****************************************************************************
  #--------------- QC REASONS -------------------------------------------------*
  #*****************************************************************************

  def query_for_qc_reasons(cond='', paginate=true)
    if paginate
    "@qc_reason_pages = Paginator.new self, QcReason.count, @@page_size,@current_page
     @qc_reasons = QcReason.find(:all,
         :select => 'qc_reasons.id, qc_reasons.qc_reason_code,
                     qc_reasons.qc_reason_description, qc_reasons.qc_inspection_type_id,
                     qc_inspection_types.qc_inspection_type_code, qc_inspection_types.qc_inspection_type_description',
         :joins => 'join qc_inspection_types on qc_inspection_types.id = qc_reasons.qc_inspection_type_id',
         :order => 'qc_inspection_types.qc_inspection_type_code, qc_reasons.qc_reason_code',
         :limit => @qc_reason_pages.items_per_page #{cond},
         :offset => @qc_reason_pages.current.offset)"
    else
    "@qc_reasons = QcReason.find(:all,
         :select => 'qc_reasons.id, qc_reasons.qc_reason_code,
                     qc_reasons.qc_reason_description, qc_reasons.qc_inspection_type_id,
                     qc_inspection_types.qc_inspection_type_code, qc_inspection_types.qc_inspection_type_description',
         :order => 'qc_inspection_types.qc_inspection_type_code, qc_reasons.qc_reason_code',
         :joins => 'join qc_inspection_types on qc_inspection_types.id = qc_reasons.qc_inspection_type_id' #{cond})"
    end
  end

  def list_qc_reasons
    return if authorise_for_web(program_name?,'read') == false 

    if params[:page]!= nil 
      session[:qc_reasons_page] = params['page']
      render_list_qc_reasons
      return 
    else
      session[:qc_reasons_page] = nil
    end

    @in_child = !params[:id].nil?
    if @in_child
      @qc_inspection_type_id = params[:id]
      cond = ", :conditions => ['qc_inspection_type_id = ?', #{params[:id]}]"
      list_query = query_for_qc_reasons(cond, false)
      session[:reason_query] = list_query
    else
      list_query = query_for_qc_reasons
      session[:query] = list_query
    end
    render_list_qc_reasons
  end


  def render_list_qc_reasons
    @can_edit          = authorise(program_name?,'edit',session[:user_id])
    @can_delete        = authorise(program_name?,'delete',session[:user_id])
    if @in_child
      @qc_reason_pages = nil
      @qc_reasons      = eval(session[:reason_query]) if !@qc_reasons
    else
      @pagination_server = "list_qc_reasons"
      @current_page      = session[:qc_reasons_page]
      @current_page      = params['page']||= session[:qc_reasons_page]
      @qc_reasons        = eval(session[:query]) if !@qc_reasons
    end

    render :inline => %{
    <% @child_form_caption = ["child_form2","Possible Reasons for this type"] %>
      <% grid            = build_qc_reason_grid(@qc_reasons,@can_edit,@can_delete)%>
      <% grid.caption    = 'List of all qc_reasons' %>
      <% @header_content = grid.build_grid_data %>

    <% @pagination = pagination_links(@qc_reason_pages) if @qc_reason_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_qc_reasons
    return if authorise_for_web(program_name?,'read')== false
    @is_flat_search = true 
    render_qc_reason_search_form
  end

  def render_qc_reason_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
    #	 render (inline) the search form
    render :inline => %{
    <% @content_header_caption = "'search  qc_reasons'"%> 

    <%= build_qc_reason_search_form(nil,'submit_qc_reasons_search','submit_qc_reasons_search',@is_flat_search)%>

    }, :layout => 'content'
  end

  def submit_qc_reasons_search
    @qc_reasons = dynamic_search(params[:qc_reason] ,'qc_reasons','QcReason',false,'qc_inspection_type')
    if @qc_reasons.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_qc_reason_search_form
    else
      render_list_qc_reasons
    end
  end


  def delete_qc_reason
    begin
      return if authorise_for_web(program_name?,'delete')== false
      if params[:page]
        session[:qc_reasons_page] = params['page']
        render_list_qc_reasons
        return
      end
      id = params[:id]
      if id && qc_reason = QcReason.find(id)
        @qc_inspection_type_id = qc_reason.qc_inspection_type_id
        qc_reason.destroy
        session[:alert] = " Record deleted."
        @in_child = (params[:id_value] && params[:id_value] == 'child')
        render_list_qc_reasons
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_qc_reason
    return if authorise_for_web(program_name?,'create')== false
    @qc_inspection_type_id = params[:id] if params[:id]
    render_new_qc_reason
  end

  def create_qc_reason
    begin
      if params[:qc_reason][:qc_inspection_type_id] != ''
        qc_inspection_type = QcInspectionType.find(params[:qc_reason][:qc_inspection_type_id])
      else
        qc_inspection_type = nil
      end
      is_child = params[:qc_reason].delete(:is_child_form)
      if qc_inspection_type.nil?
        @is_create_retry = true
        session[:alert] = "Inspection Type must be chosen."
        render_new_qc_reason
      else
        @qc_reason = QcReason.new(params[:qc_reason])
        if @qc_reason.save
          session[:alert] = "new record created successfully"
          cond = ",:conditions => ['qc_inspection_type_id = ?', #{@qc_reason.qc_inspection_type_id}]"
          #session[:query] = query_for_qc_reasons(cond)
          
          if is_child && is_child == 'Y'
            render :inline=>%{
              <script>
                window.opener.frames[1].frames[1].location.href ='/qc/qc_setup/list_qc_reasons/#{@qc_reason.qc_inspection_type_id}';
                window.close();
              </script>
              },:layout=>'content'
          else
            render :inline=>%{
              <script>
                window.opener.frames[1].location.href ='/qc/qc_setup/list_qc_reasons';
                window.close();
              </script>
              },:layout=>'content'
          end
        else
          @is_create_retry = true
          render_new_qc_reason
        end
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_qc_reason
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new qc_reason'"%> 

    <%= build_qc_reason_form(@qc_reason,'create_qc_reason','create_qc_reason',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def edit_qc_reason
    return if authorise_for_web(program_name?,'edit')==false 
    id = params[:id]
    if id && @qc_reason = QcReason.find(id)
      @qc_inspection_type_id = @qc_reason.qc_inspection_type_id if params[:id_value] && params[:id_value] == 'child'
      render_edit_qc_reason
    end
  end


  def render_edit_qc_reason
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit qc_reason'"%> 

    <%= build_qc_reason_form(@qc_reason,'update_qc_reason','update_qc_reason',true)%>

    }, :layout => 'content'
  end

  def update_qc_reason
    begin
      is_child = params[:qc_reason].delete(:is_child_form)
      id = params[:qc_reason][:id]
      if id && @qc_reason = QcReason.find(id)
        if @qc_reason.update_attributes(params[:qc_reason])
          flash[:notice] = 'record saved'
          @in_child = is_child == 'Y'
          if @in_child
            @qc_reasons = eval(session[:reason_query])
            @qc_inspection_type_id = @qc_reason.qc_inspection_type_id
          else
            @qc_reasons = eval(session[:query])
          end
          render_list_qc_reasons
        else
          render_edit_qc_reason

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

  #*****************************************************************************
  #--------------- QC INSPECTION TYPE TESTS -----------------------------------*
  #*****************************************************************************

  def query_for_qc_inspection_type_tests(cond='', paginate=true)
    # NB. The select is required, otherwise the id values get mixed-up.
    if paginate
      "@qc_inspection_type_test_pages = Paginator.new self, QcInspectionTypeTest.count, @@page_size,@current_page
       @qc_inspection_type_tests = QcInspectionTypeTest.find(:all,
           :select => 'qc_inspection_type_tests.id, qc_inspection_type_tests.sample_size,
                       qc_inspection_type_tests.filter_column, qc_inspection_type_tests.filter_value,
                       qc_tests.qc_test_code, qc_tests.qc_test_description, optional',
           :joins => 'join qc_inspection_types on qc_inspection_types.id = qc_inspection_type_tests.qc_inspection_type_id
                      join qc_tests on qc_tests.id = qc_inspection_type_tests.qc_test_id',
           :order => 'qc_inspection_type_tests.qc_inspection_type_id, qc_tests.qc_test_code',
           :limit => @qc_inspection_type_test_pages.items_per_page #{cond},
           :offset => @qc_inspection_type_test_pages.current.offset)"
    else
      "@qc_inspection_type_tests = QcInspectionTypeTest.find(:all,
           :select => 'qc_inspection_type_tests.id, qc_inspection_type_tests.sample_size,
                       qc_inspection_type_tests.filter_column, qc_inspection_type_tests.filter_value,
                       qc_tests.qc_test_code, qc_tests.qc_test_description, optional',
           :order => 'qc_inspection_type_tests.qc_inspection_type_id, qc_tests.qc_test_code',
           :joins => 'join qc_inspection_types on qc_inspection_types.id = qc_inspection_type_tests.qc_inspection_type_id
                      join qc_tests on qc_tests.id = qc_inspection_type_tests.qc_test_id' #{cond})"
    end
  end

  def list_qc_inspection_type_tests
    return if authorise_for_web(program_name?,'read') == false 

    if params[:page]!= nil 
      session[:qc_inspection_type_tests_page] = params['page']
      render_list_qc_inspection_type_tests
      return 
    else
      session[:qc_inspection_type_tests_page] = nil
    end

    @in_child = !params[:id].nil?
    if @in_child
      @qc_inspection_type_id = params[:id]
      cond = ",:conditions => ['qc_inspection_type_id = ?', #{params[:id]}]"
      list_query = query_for_qc_inspection_type_tests(cond, false)
      session[:inspection_type_test_query] = list_query
    else
      list_query = query_for_qc_inspection_type_tests
      session[:query] = list_query
    end
    render_list_qc_inspection_type_tests
  end

  def render_list_qc_inspection_type_tests
    @can_edit   = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    if @in_child
      @qc_inspection_type_test_pages = nil
      @qc_inspection_type_tests      = eval(session[:inspection_type_test_query]) if !@qc_inspection_type_tests
    else
      @pagination_server        = "list_qc_inspection_type_tests"
      @current_page             = session[:qc_inspection_type_tests_page]
      @current_page             = params['page']||= session[:qc_inspection_type_tests_page]
      @qc_inspection_type_tests =  eval(session[:query]) if !@qc_inspection_type_tests
    end

    render :inline => %{
      <% @child_form_caption = ["child_form3","Tests for this type"] %>
        <% grid            = build_qc_inspection_type_test_grid(@qc_inspection_type_tests,@can_edit,@can_delete) %>
        <% grid.caption    = 'List of all qc_inspection_type_tests' %>
        <% @header_content = grid.build_grid_data %>

        <%= grid.render_html %>
      <% @pagination = pagination_links(@qc_inspection_type_test_pages) if @qc_inspection_type_test_pages != nil %>
        <%= grid.render_grid %>
      }, :layout => 'content'
  end
 
  def delete_qc_inspection_type_test
    begin
      return if authorise_for_web(program_name?,'delete')== false
      if params[:page]
        session[:qc_inspection_type_tests_page] = params['page']
        render_list_qc_inspection_type_tests
        return
      end
      id = params[:id]
      if id && qc_inspection_type_test = QcInspectionTypeTest.find(id)
        @qc_inspection_type_id = qc_inspection_type_test.qc_inspection_type_id
        qc_inspection_type_test.destroy
        session[:alert] = " Record deleted."
        @in_child = (params[:id_value] && params[:id_value] == 'child')
        render_list_qc_inspection_type_tests
      end
    rescue
      handle_error('record could not be deleted')
    end
  end
 
  def new_qc_inspection_type_test
    return if authorise_for_web(program_name?,'create')== false
    @qc_inspection_type_id = params[:id]
    render_new_qc_inspection_type_test
  end

  def create_qc_inspection_type_test
    begin
      qc_inspection_type = QcInspectionType.find(params[:qc_inspection_type_test][:qc_inspection_type_id])
      is_child = params[:qc_inspection_type_test].delete(:is_child_form)
      @qc_inspection_type_id = params[:qc_inspection_type_test][:qc_inspection_type_id] unless qc_inspection_type.nil?
      if qc_inspection_type.nil?
        @is_create_retry = true
        session[:alert] = "Inspection Type must be chosen."
          render_new_qc_inspection_type_test
      elsif params[:qc_inspection_type_test][:qc_test_id] == "" || params[:qc_inspection_type_test][:qc_test_id] == ''
        @is_create_retry = true
        session[:alert] = "Test must be chosen."
          render_new_qc_inspection_type_test
      else
        @qc_inspection_type_test = QcInspectionTypeTest.new(params[:qc_inspection_type_test])
        if @qc_inspection_type_test.save
            session[:alert] = "new record created successfully"
            cond = ",:conditions => ['qc_inspection_type_id = ?', #{@qc_inspection_type_test.qc_inspection_type_id}]"
            
          if is_child && is_child == 'Y'
            render :inline=>%{
              <script>
                window.opener.frames[1].frames[2].location.href ='/qc/qc_setup/list_qc_inspection_type_tests/#{@qc_inspection_type_test.qc_inspection_type_id}';
                window.close();
              </script>
              },:layout=>'content'
          else
            render :inline=>%{
              <script>
                window.opener.frames[1].location.href ='/qc/qc_setup/list_qc_inspection_type_tests';
                window.close();
              </script>
              },:layout=>'content'
          end
        else
          @is_create_retry = true
          render_new_qc_inspection_type_test
        end
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_qc_inspection_type_test
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new qc_inspection_type_test'"%> 

    <%= build_qc_inspection_type_test_form(@qc_inspection_type_test,'create_qc_inspection_type_test','create_qc_inspection_type_test',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def edit_qc_inspection_type_test
    return if authorise_for_web(program_name?,'edit')==false 
    id = params[:id]
    if id && @qc_inspection_type_test = QcInspectionTypeTest.find(id)
      @qc_inspection_type_id = @qc_inspection_type_test.qc_inspection_type_id if params[:id_value] && params[:id_value] == 'child'
      render_edit_qc_inspection_type_test
    end
  end


  def render_edit_qc_inspection_type_test
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit qc_inspection_type_test'"%> 

    <%= build_qc_inspection_type_test_form(@qc_inspection_type_test,'update_qc_inspection_type_test','update_qc_inspection_type_test',true)%>

    }, :layout => 'content'
  end

  def update_qc_inspection_type_test
    begin
      is_child = params[:qc_inspection_type_test].delete(:is_child_form)
      id = params[:qc_inspection_type_test][:id]
      if id && @qc_inspection_type_test = QcInspectionTypeTest.find(id)
        if @qc_inspection_type_test.update_attributes(params[:qc_inspection_type_test])
          flash[:notice] = 'record saved'
          @in_child = is_child == 'Y'
          if @in_child
            @qc_inspection_type_tests = eval(session[:inspection_type_test_query])
            @qc_inspection_type_id = @qc_inspection_type_test.qc_inspection_type_id
          else
            @qc_inspection_type_tests = eval(session[:query])
          end
          render_list_qc_inspection_type_tests
        else
          render_edit_qc_inspection_type_test

        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end


  #*****************************************************************************
  #--------------- QC INSPECTION TYPE REPORTS ---------------------------------*
  #*****************************************************************************

  def list_qc_inspection_type_reports
    return if authorise_for_web(program_name?,'read') == false 

      @qc_inspection_type_id = params[:id]
      cond = ""
      list_query = "@qc_inspection_type_reports = QcInspectionTypeReport.find(:all,
         :select => 'qc_inspection_type_reports.id, qc_inspection_type_reports.report_name,
                     qc_inspection_type_reports.report_description, qc_inspection_type_reports.qc_inspection_type_id,
                     qc_inspection_types.qc_inspection_type_code, qc_inspection_types.qc_inspection_type_description',
         :order => 'qc_inspection_types.qc_inspection_type_code, qc_inspection_type_reports.report_name',
         :joins => 'join qc_inspection_types on qc_inspection_types.id = qc_inspection_type_reports.qc_inspection_type_id',
         :conditions => ['qc_inspection_type_id = ?', #{params[:id]}])"
      session[:qc_it_report_query] = list_query
    render_list_qc_inspection_type_reports
  end

  def render_list_qc_inspection_type_reports
    @can_edit          = authorise(program_name?,'edit',session[:user_id])
    @can_delete        = authorise(program_name?,'delete',session[:user_id])
    @qc_inspection_type_reports      = eval(session[:qc_it_report_query]) if !@qc_inspection_type_reports

    render :inline => %{
    <% @child_form_caption = ["child_form4","Reports to be launched from this inspection type"] %>
      <% grid            = build_qc_inspection_type_report_grid(@qc_inspection_type_reports,@can_edit,@can_delete)%>
      <% grid.caption    = 'List of all qc_inspection_type_reports' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def delete_qc_inspection_type_report
    return if authorise_for_web(program_name?,'delete')== false
    id = params[:id]
    if id && qc_inspection_type_report = QcInspectionTypeReport.find(id)
      @qc_inspection_type_id = qc_inspection_type_report.qc_inspection_type_id
      qc_inspection_type_report.destroy
      session[:alert] = " Record deleted."
      @in_child = (params[:id_value] && params[:id_value] == 'child')
      render_list_qc_inspection_type_reports
    end
  rescue
    handle_error('record could not be deleted')
  end

  def new_qc_inspection_type_report
    return if authorise_for_web(program_name?,'create')== false
    @qc_inspection_type_id = params[:id] if params[:id]
    render_new_qc_inspection_type_report
  end

  def create_qc_inspection_type_report
    if params[:qc_inspection_type_report][:qc_inspection_type_id] != ''
      qc_inspection_type = QcInspectionType.find(params[:qc_inspection_type_report][:qc_inspection_type_id])
    else
      qc_inspection_type = nil
    end
    @qc_inspection_type_id = params[:qc_inspection_type_report][:qc_inspection_type_id]
    if qc_inspection_type.nil?
      @is_create_retry = true
      session[:alert] = "Inspection Type must be chosen."
      render_new_qc_inspection_type_report
    else
      @qc_inspection_type_report = QcInspectionTypeReport.new(params[:qc_inspection_type_report])
      if @qc_inspection_type_report.save
        session[:alert] = "new record created successfully"
        
        render :inline=>%{
          <script>
            window.opener.frames[3].location.href ='/qc/qc_setup/list_qc_inspection_type_reports/#{@qc_inspection_type_report.qc_inspection_type_id}';
            window.close();
          </script>
          },:layout=>'content'
      else
        @is_create_retry = true
        render_new_qc_inspection_type_report
      end
    end
  rescue
    handle_error('record could not be created')
  end

  def render_new_qc_inspection_type_report
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new qc_inspection_type_report'"%> 

    <%= build_qc_inspection_type_report_form(@qc_inspection_type_report,'create_qc_inspection_type_report','create_qc_inspection_type_report',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def edit_qc_inspection_type_report
    return if authorise_for_web(program_name?,'edit')==false 
    id = params[:id]
    if id && @qc_inspection_type_report = QcInspectionTypeReport.find(id)
      @qc_inspection_type_id = @qc_inspection_type_report.qc_inspection_type_id
      render_edit_qc_inspection_type_report
    end
  end


  def render_edit_qc_inspection_type_report
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit qc_inspection_type_report'"%> 

    <%= build_qc_inspection_type_report_form(@qc_inspection_type_report,'update_qc_inspection_type_report','update_qc_inspection_type_report',true)%>

    }, :layout => 'content'
  end

  def update_qc_inspection_type_report
    id = params[:qc_inspection_type_report][:id]
    if id && @qc_inspection_type_report = QcInspectionTypeReport.find(id)
      @qc_inspection_type_id = @qc_inspection_type_report.qc_inspection_type_id
      if @qc_inspection_type_report.update_attributes(params[:qc_inspection_type_report])
        flash[:notice] = 'record saved'
        @qc_inspection_type_reports = eval(session[:qc_it_report_query])
        render_list_qc_inspection_type_reports
      else
        render_edit_qc_inspection_type_report
      end
    end
  rescue
    handle_error('record could not be saved')
  end


  #*****************************************************************************
  #--------------- QC TESTS ---------------------------------------------------*
  #*****************************************************************************

  # Return the query used for displaying the tests grid.
  def query_for_qc_tests
    "@qc_test_pages = Paginator.new self, QcTest.count, @@page_size,@current_page
     @qc_tests = QcTest.find(:all,
           :limit => @qc_test_pages.items_per_page,
           :order => 'qc_test_code',
           :offset => @qc_test_pages.current.offset)"
  end

  def list_qc_tests
    return if authorise_for_web(program_name?,'read') == false 

    if params[:page]!= nil 
      session[:qc_tests_page] = params['page']
      render_list_qc_tests
      return 
    else
      session[:qc_tests_page] = nil
    end

    session[:query] = query_for_qc_tests
    render_list_qc_tests
  end

  def render_list_qc_tests
    @pagination_server = "list_qc_tests"
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:qc_tests_page]
    @current_page = params['page']||= session[:qc_tests_page]
    @qc_tests =  eval(session[:query]) if !@qc_tests

    render :inline => %{
      <% grid            = build_qc_test_grid(@qc_tests,@can_edit,@can_delete)%>
      <% grid.caption    = 'List of all qc_tests' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@qc_test_pages) if @qc_test_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_qc_tests
    return if authorise_for_web(program_name?,'read')== false
    @is_flat_search = true 
    render_qc_test_search_form
  end

  def render_qc_test_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
    #	 render (inline) the search form
    render :inline => %{
    <% @content_header_caption = "'search  qc_tests'"%> 

    <%= build_qc_test_search_form(nil,'submit_qc_tests_search','submit_qc_tests_search',@is_flat_search)%>

    }, :layout => 'content'
  end


  def submit_qc_tests_search
    @qc_tests = dynamic_search(params[:qc_test] ,'qc_tests','QcTest')
    if @qc_tests.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_qc_test_search_form
    else
      render_list_qc_tests
    end
  end


  def delete_qc_test
    begin
      return if authorise_for_web(program_name?,'delete')== false
      if params[:page]
        session[:qc_tests_page] = params['page']
        render_list_qc_tests
        return
      end
      id = params[:id]
      if id && qc_test = QcTest.find(id)
        qc_test.destroy
        session[:alert] = " Record deleted."
        render_list_qc_tests
      end
    rescue handle_error('record could not be deleted')
    end
  end

  def new_qc_test
    return if authorise_for_web(program_name?,'create')== false
    render_new_qc_test
  end

  def create_qc_test
    begin
      @qc_test = QcTest.new(params[:qc_test])
      if @qc_test.save
        session[:alert] = "new record created successfully"
        session[:query] = query_for_qc_inspection_types
        
        render :inline=>%{
          <script>
            window.opener.frames[1].location.href ='/qc/qc_setup/list_qc_tests';
            window.close();
          </script>
      },:layout=>'content'
      else
        @is_create_retry = true
        render_new_qc_test
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_qc_test
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new qc_test'"%> 

    <%= build_qc_test_form(@qc_test,'create_qc_test','create_qc_test',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def maintain_qc_test
    render :inline => %{
    <% @content_header_caption = "'edit test'"%> 

    <%= maintain_qc_test(#{params[:id]}) %>

    }, :layout => 'content'

  end

  def edit_qc_test
    return if authorise_for_web(program_name?,'edit')==false 
    id = params[:id]
    if id && @qc_test = QcTest.find(id)
      render_edit_qc_test
    end
  end


  def render_edit_qc_test
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit qc_test'"%> 

    <%= build_qc_test_form(@qc_test,'update_qc_test','update_qc_test',true)%>

    }, :layout => 'content'
  end

  def update_qc_test
    begin

      id = params[:qc_test][:id]
      if id && @qc_test = QcTest.find(id)
        if @qc_test.update_attributes(params[:qc_test])
          @qc_tests = eval(session[:query])
          flash[:notice] = 'record saved'
          render :inline=>%{
            <script>
              window.parent.location.href ='/qc/qc_setup/list_qc_tests';
            </script>
            },:layout=>'content'
        else
          render_edit_qc_test
        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

  #*****************************************************************************
  #--------------- QC MEASUREMENT TYPES ---------------------------------------*
  #*****************************************************************************
#NAE 2016-02-29 ADD ANNOTATION 4 AND 5 CODE
  def query_for_qc_measurement_types(cond='', paginate=true)
    if paginate
    "@qc_measurement_type_pages = Paginator.new self, QcMeasurementType.count, @@page_size,@current_page
     @qc_measurement_types = QcMeasurementType.find(:all,
         :select => 'qc_measurement_types.id, qc_measurement_types.qc_measurement_code,
                     qc_measurement_types.qc_measurement_description, qc_measurement_types.qc_test_id,
                     qc_measurement_types.test_uom, qc_measurement_types.test_criteria,
                     qc_measurement_types.test_method, 
		           qc_measurement_types.annotation_1_label, qc_measurement_types.annotation_1_field_type, qc_measurement_types.annotation_1_possible_values,
                     qc_measurement_types.annotation_2_label, qc_measurement_types.annotation_2_field_type, qc_measurement_types.annotation_2_possible_values, 
		           qc_measurement_types.annotation_3_label, qc_measurement_types.annotation_3_field_type, qc_measurement_types.annotation_3_possible_values,
		           qc_measurement_types.annotation_4_label, qc_measurement_types.annotation_4_field_type, qc_measurement_types.annotation_4_possible_values,
		           qc_measurement_types.annotation_5_label, qc_measurement_types.annotation_5_field_type, qc_measurement_types.annotation_5_possible_values,
                     qc_tests.qc_test_code, qc_tests.qc_test_description',
         :joins => 'join qc_tests on qc_tests.id = qc_measurement_types.qc_test_id',
         :order => 'qc_tests.qc_test_code, qc_measurement_types.qc_measurement_code',
         :limit => @qc_measurement_type_pages.items_per_page #{cond},
         :offset => @qc_measurement_type_pages.current.offset)"
    else
    "@qc_measurement_types = QcMeasurementType.find(:all,
         :select => 'qc_measurement_types.id, qc_measurement_types.qc_measurement_code,
                     qc_measurement_types.qc_measurement_description, qc_measurement_types.qc_test_id,
                     qc_measurement_types.test_uom, qc_measurement_types.test_criteria,
                     qc_measurement_types.test_method, 
		           qc_measurement_types.annotation_1_label, qc_measurement_types.annotation_1_field_type, qc_measurement_types.annotation_1_possible_values,
   			      qc_measurement_types.annotation_2_label, qc_measurement_types.annotation_2_field_type, qc_measurement_types.annotation_2_possible_values, 
			      qc_measurement_types.annotation_3_label, qc_measurement_types.annotation_3_field_type, qc_measurement_types.annotation_3_possible_values,
		           qc_measurement_types.annotation_4_label, qc_measurement_types.annotation_4_field_type, qc_measurement_types.annotation_4_possible_values,
		           qc_measurement_types.annotation_5_label, qc_measurement_types.annotation_5_field_type, qc_measurement_types.annotation_5_possible_values,			      
                     qc_tests.qc_test_code, qc_tests.qc_test_description',
         :order => 'qc_tests.qc_test_code, qc_measurement_types.qc_measurement_code',
         :joins => 'join qc_tests on qc_tests.id = qc_measurement_types.qc_test_id' #{cond})"
    end
  end

  def list_qc_measurement_types
    return if authorise_for_web(program_name?,'read') == false 

    if params[:page]!= nil 
      session[:qc_measurement_types_page] = params['page']
      render_list_qc_measurement_types
      return 
    else
      session[:qc_measurement_types_page] = nil
    end

    @in_child = !params[:id].nil?
    if @in_child
      @qc_test_id = params[:id]
      cond = ", :conditions => ['qc_test_id = ?', #{params[:id]}]"
      list_query = query_for_qc_measurement_types(cond, false)
      session[:measurement_type_query] = list_query
    else
      list_query = query_for_qc_measurement_types
      session[:query] = list_query
    end
    render_list_qc_measurement_types
  end


  def render_list_qc_measurement_types
    @can_edit          = authorise(program_name?,'edit',session[:user_id])
    @can_delete        = authorise(program_name?,'delete',session[:user_id])
    if @in_child
      @qc_measurement_type_pages = nil
      @qc_measurement_types      = eval(session[:measurement_type_query]) if !@qc_measurement_types
    else
      @pagination_server = "list_qc_measurement_types"
      @current_page      = session[:qc_measurement_types_page]
      @current_page      = params['page']||= session[:qc_measurement_types_page]
      @qc_measurement_types        = eval(session[:query]) if !@qc_measurement_types
    end

    render :inline => %{
      <% grid            = build_qc_measurement_type_grid(@qc_measurement_types,@can_edit,@can_delete)%>
      <% grid.caption    = 'Possible MeasurementTypes for this type' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@qc_measurement_type_pages) if @qc_measurement_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def delete_qc_measurement_type
    begin
      return if authorise_for_web(program_name?,'delete')== false
      if params[:page]
        session[:qc_measurement_types_page] = params['page']
        render_list_qc_measurement_types
        return
      end
      id = params[:id]
      if id && qc_measurement_type = QcMeasurementType.find(id)
        @qc_test_id = qc_measurement_type.qc_test_id
        qc_measurement_type.destroy
        session[:alert] = " Record deleted."
        @in_child = (params[:id_value] && params[:id_value] == 'child')
        render_list_qc_measurement_types
      end
    rescue
      handle_error('record could not be deleted')
    end
  end

  def new_qc_measurement_type
    return if authorise_for_web(program_name?,'create')== false
    @qc_test_id = params[:id] if params[:id]
    render_new_qc_measurement_type
  end

  def create_qc_measurement_type
    begin
      qc_test = QcTest.find(params[:qc_measurement_type][:qc_test_id])
      @qc_test_id = qc_test.id
      is_child = params[:qc_measurement_type].delete(:is_child_form)
      if qc_test.nil?
        @is_create_retry = true
        session[:alert] = "Inspection Type must be chosen."
        render_new_qc_measurement_type
      else
        @qc_measurement_type = QcMeasurementType.new(params[:qc_measurement_type])
        if @qc_measurement_type.save
          session[:alert] = "new record created successfully"
          cond = ",:conditions => ['qc_test_id = ?', #{@qc_measurement_type.qc_test_id}]"
          #session[:query] = query_for_qc_measurement_types(cond)
          
          if is_child && is_child == 'Y'
            render :inline=>%{
              <script>
                window.opener.frames[1].frames[1].location.href ='/qc/qc_setup/list_qc_measurement_types/#{@qc_measurement_type.qc_test_id}';
                window.close();
              </script>
              },:layout=>'content'
          else
            render :inline=>%{
              <script>
                window.opener.frames[1].location.href ='/qc/qc_setup/list_qc_measurement_types';
                window.close();
              </script>
              },:layout=>'content'
          end
        else
          @is_create_retry = true
          render_new_qc_measurement_type
        end
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_qc_measurement_type
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new qc_measurement_type'"%> 

    <%= build_qc_measurement_type_form(@qc_measurement_type,'create_qc_measurement_type','create_qc_measurement_type',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def edit_qc_measurement_type
    return if authorise_for_web(program_name?,'edit')==false 
    id = params[:id]
    if id && @qc_measurement_type = QcMeasurementType.find(id)
      @qc_test_id = @qc_measurement_type.qc_test_id if params[:id_value] && params[:id_value] == 'child'
      render_edit_qc_measurement_type
    end
  end


  def render_edit_qc_measurement_type
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit qc_measurement_type'"%> 

    <%= build_qc_measurement_type_form(@qc_measurement_type,'update_qc_measurement_type','update_qc_measurement_type',true)%>

    }, :layout => 'content'
  end

  def update_qc_measurement_type
    begin
      is_child = params[:qc_measurement_type].delete(:is_child_form)
      id = params[:qc_measurement_type][:id]
      if id && @qc_measurement_type = QcMeasurementType.find(id)
        if @qc_measurement_type.update_attributes(params[:qc_measurement_type])
          session[:alert] = 'record saved'
#          flash[:notice] = 'record saved'
          @in_child = is_child == 'Y'
          if @in_child
            @qc_measurement_types = eval(session[:measurement_type_query])
            @qc_test_id = @qc_measurement_type.qc_test_id
          else
            @qc_measurement_types = eval(session[:query])
          end
          render_list_qc_measurement_types
        else
          @qc_test_id = @qc_measurement_type.qc_test_id
          render_edit_qc_measurement_type
        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

end
