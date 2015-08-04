class  Qc::QcInspectionController < ApplicationController

  # Include the layout here for any rhtml
  layout 'content'

  # Because this controller manages several different programs
  # we need to ask ProgramFunction for the actual program name given the qc_inspection_type_code (url_param).
  def program_name(qc_inspection_type_code)
    ProgramFunction.generic_program_name( 'QC', qc_inspection_type_code )
  end

  def bypass_generic_security?
    true
  end

  #*****************************************************************************
  #--------------- CURRENT SEARCH / INSPECTION --------------------------------*
  #*****************************************************************************

  # Convenience action to quickly get back to the inspection the user was working on.
  def current_qc_inspection
    return if authorise_for_web(program_name(params[:id]),'edit')== false
    qc_current_inspection = ActiveRecord::Base.connection.select_one("select * from qc_current_inspections
                                                                     where user_id = #{session[:user_id].id}
                                                                     and qc_inspection_type_code = '#{params[:id]}'")
    if qc_current_inspection.nil? || qc_current_inspection.qc_inspection_id.nil?
      redirect_to_index("'You have not yet captured an inspection for #{params[:id]}'", "''")
    else
      @qc_inspection = QcInspection.find(qc_current_inspection.qc_inspection_id)
      params[:id_value] = @qc_inspection.qc_inspection_type.qc_inspection_type_code
      params[:id]       = @qc_inspection.id
      edit_qc_inspection
    end
  end

  # Convenience action to quickly get back to the business context the user was working on.
  def current_qc_business_context_search
    return if authorise_for_web(program_name(params[:id]),'create')== false
    session[:qc_inspection_type_code] = params[:id]
    qc_current_inspection = ActiveRecord::Base.connection.select_one("select * from qc_current_inspections
                                                                     where user_id = #{session[:user_id].id}
                                                                     and qc_inspection_type_code = '#{params[:id]}'")
    if qc_current_inspection.nil? || qc_current_inspection.qc_business_context_query.nil?
      redirect_to_index("'You have not yet captured an inspection for #{params[:id]}'", "''")
    else
      dm_session[:search_engine_query_definition] = qc_current_inspection.qc_business_context_query
      session[:columns_list] = YAML.load(qc_current_inspection.columns_list)
      submit_business_context_search
    end
  end

  # Convenience action to quickly get back to the list of tests of a certain type.
  def current_qc_tests
    return if authorise_for_web(program_name(params[:id]),'edit')== false
    session[:qc_inspection_type_code] = params[:id]
    qc_current_inspection = ActiveRecord::Base.connection.select_one("select * from qc_current_inspections
                                                                     where user_id = #{session[:user_id].id}
                                                                     and qc_inspection_type_code = '#{params[:id]}'")
    if qc_current_inspection.nil? || qc_current_inspection.qc_business_context_query.nil?
      redirect_to_index("'You have not yet listed tests for #{params[:id]}'", "''")
    else
      dm_session[:search_engine_query_definition] = qc_current_inspection.qc_tests_query
      session[:columns_list] = YAML.load(qc_current_inspection.tests_columns_list)
      submit_tests_search
    end
  end

  #*****************************************************************************
  #--------------- SEARCH FOR INSPECTIONS -------------------------------------*
  #*****************************************************************************

  # Find the business data on which an inspection will take place.
  # If the parameter +with_inspection+ is true, the search will be run
  # for existing inspections.
  def search_business_context(with_inspections=false)
    return if authorise_for_web(program_name(params[:id]),'create')== false
    # Show a data miner...
    inspection_type = QcInspectionType.find_by_qc_inspection_type_code(params[:id])
    if inspection_type.nil?
      raise "Unknown Inspection Type: '#{params[:id]}'. The inspection type is not setup correctly or the menu system is not correctly defined."
    end
    data_miner = inspection_type.qc_business_context_search
    data_miner.sub!('.yml', '_active.yml') if with_inspections
    session[:qc_inspection_type_code] = inspection_type.qc_inspection_type_code
    dm_session[:parameter_fields_values] = nil
    session[:qc_inspection_exists] = with_inspections
    dm_session['se_layout'] = 'content'
    @content_header_caption = "'search'"
    dm_session[:redirect] = true
    build_remote_search_engine_form(data_miner, 'submit_business_context_search')
  end

  def submit_business_context_search
    @business_data = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    if (@business_data.length > 0)
      log_current_cusiness_context_query unless session[:qc_inspection_exists]
      render_found_business_data
    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                            </script>
                          }, :layout => 'content'
    end
  end

  def render_found_business_data
    if @business_data !=nil and @business_data.length > 0
      # @can_edit   = authorise(program_name(session[:qc_inspection_type_code]), 'edit', session[:user_id])
      # @can_delete = authorise(program_name(session[:qc_inspection_type_code]), 'delete', session[:user_id])
      @stat = dm_session[:search_engine_query_definition]
      @columns_list = dm_session[:columns_list]
      @grid_configs = dm_session[:grid_configs]
      @qc_inspection_type = QcInspectionType.find_by_qc_inspection_type_code(session[:qc_inspection_type_code])

      @for_existing_inspections = session[:qc_inspection_exists]

      render :inline => %{
      <% grid            = build_list_business_context_grid(@business_data,@stat,@columns_list, session[:qc_inspection_type_code],
                                                            @qc_inspection_type.can_re_edit_inspection, @grid_configs) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    else
      redirect_to_index("'no search result records to list'", "''")
    end
  end

  # Existing (in-progress) inspections. Use search_business_context method to do the work.
  def search_inspections
    search_business_context( true )
  end

  #*****************************************************************************
  #--------------- NEW INSPECTION ---------------------------------------------*
  #*****************************************************************************

  def new_qc_inspection
    @business_object_id      = params[:id]
    @qc_inspection_type_code = params[:id_value]
    qc_inspection_type       = QcInspectionType.find_by_qc_inspection_type_code(params[:id_value])
    @qc_inspection_type_id   = qc_inspection_type.id
    @qc_inspection           = QcInspection.new
    @qc_inspection.set_business_info( qc_inspection_type, @business_object_id )
    @qc_inspection.population_size = qc_inspection_type.population_size
    render_new_qc_inspection
  end

  def create_qc_inspection
    begin
      @qc_inspection = QcInspection.new(params[:qc_inspection])
      @qc_inspection.username = session[:user_id].user_name
      if @qc_inspection.create_inspection
        params[:id_value] = @qc_inspection.qc_inspection_type.qc_inspection_type_code
        params[:id]       = @qc_inspection.id
        edit_qc_inspection
      else
        @business_object_id      = @qc_inspection.business_object_id
        @qc_inspection_type_id   = @qc_inspection.qc_inspection_type_id
        qc_inspection_type       = QcInspectionType.find(@qc_inspection_type_id)
        @qc_inspection_type_code = qc_inspection_type.qc_inspection_type_code
        @is_create_retry = true
        render_new_qc_inspection
      end
    rescue
      handle_error('record could not be created')
    end
  end

  def render_new_qc_inspection
    #	 render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new qc_inspection'"%> 

    <%= build_qc_inspection_form(@qc_inspection,'create_qc_inspection','create_qc_inspection',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  #*****************************************************************************
  #--------------- EDIT AN INSPECTION -----------------------------------------*
  #*****************************************************************************

  def edit_qc_inspection
    id = params[:id]
    if id && @qc_inspection = QcInspection.find(id)
      @qc_inspection_type_code = @qc_inspection.qc_inspection_type.qc_inspection_type_code
      return if authorise_for_web(program_name(@qc_inspection_type_code),'edit')== false
      @show_back        = session[:qc_inspection_back_for] && session[:qc_inspection_back_for] == id.to_i
      @back_controller  = session[:qc_inspection_back_controller]
      @back_action      = session[:qc_inspection_back_action]
      @back_id          = session[:qc_inspection_back_id]
      log_current_inspection
      render_edit_qc_inspection
    end
  end

  def re_edit_qc_inspection
    id = params[:id]
    if id && @qc_inspection = QcInspection.find(id)
      @qc_inspection_type_code = @qc_inspection.qc_inspection_type.qc_inspection_type_code
      return if authorise_for_web(program_name(@qc_inspection_type_code),'edit')== false
      @qc_inspection.revert_complete
      edit_qc_inspection
    end
  end

  def render_edit_qc_inspection
    #	 render (inline) the edit template
    @show_back = false unless @show_back
    render :inline => %{
    <% @content_header_caption = "'edit qc_inspection'"%> 

    <%= build_qc_inspection_form(@qc_inspection,'update_qc_inspection','update_qc_inspection',true)%>

    }, :layout => 'content'
  end

  def update_qc_inspection
    begin
      id = params[:qc_inspection][:id]
      if id && @qc_inspection = QcInspection.find(id)
        @show_back        = session[:qc_inspection_back_for] && session[:qc_inspection_back_for] == id.to_i
        @back_controller  = session[:qc_inspection_back_controller]
        @back_action      = session[:qc_inspection_back_action]
        @back_id          = session[:qc_inspection_back_id]
        if @qc_inspection.update_attributes(params[:qc_inspection])
          @qc_inspection_type_code = @qc_inspection.qc_inspection_type.qc_inspection_type_code
          flash[:notice] = 'record saved'
          render_edit_qc_inspection
        else
          render_edit_qc_inspection
        end
      end
    rescue
      handle_error('record could not be saved')
    end
  end

  def complete_inspection
    id = params[:id]
    if id && @qc_inspection = QcInspection.find(id)
      @qc_inspection_type_code = @qc_inspection.qc_inspection_type.qc_inspection_type_code
      return if authorise_for_web(program_name(@qc_inspection_type_code),'edit')== false
      @qc_inspection_tests = @qc_inspection.qc_inspection_tests.find(:all, :order => 'inspection_test_number')
      @qc_reasons = @qc_inspection.qc_inspection_type.qc_reasons.map {|r| [r.qc_reason_description, r.id] }
      #@qc_reasons.unshift(['<empty>', nil])
#      render_complete_qc_inspection
    end
  end

  def set_completion_status
    id = params[:id]
    if id && @qc_inspection = QcInspection.find(id)
      @qc_inspection_type_code = @qc_inspection.qc_inspection_type.qc_inspection_type_code
      return if authorise_for_web(program_name(@qc_inspection_type_code),'edit')== false
      
      QcInspection.transaction do
        if @qc_inspection.update_attributes(params[:qc_inspection])
          @qc_inspection.qc_reason_ids = params[:reason_ids] #### ONLY LATER VERSIONS OF RAILS
          # params[:reason_ids].each do |reason_id|
          #   reason = QcReason.find(reason_id)
          #   @qc_inspection.qc_reasons << reason
          # end
          @qc_inspection.set_status( QcInspection::STATUS_COMPLETED )
          render :inline=>%{
            <script>
              window.opener.frames[1].location.href ='/qc/qc_inspection/edit_qc_inspection/#{id}?id_value=#{@qc_inspection_type_code}';
              window.close();
            </script>
            },:layout=>'content'
        else
          flash[:notice] = "error - #{@qc_inspection.errors.full_messages}"
      @qc_inspection_tests = @qc_inspection.qc_inspection_tests.find(:all, :order => 'inspection_test_number')
      @qc_reasons = @qc_inspection.qc_inspection_type.qc_reasons.map {|r| [r.qc_reason_description, r.id] }
          render :action => 'complete_inspection'
        end
      end
    end
  end

  #*****************************************************************************
  #--------------- INSPECTION TESTS -------------------------------------------*
  #*****************************************************************************

  def list_qc_inspection_tests
    id = params[:id]
    if id && @qc_inspection = QcInspection.find(id)
      @qc_inspection_type_code = @qc_inspection.qc_inspection_type.qc_inspection_type_code
      return if authorise_for_web(program_name(@qc_inspection_type_code),'read')== false
    else
      return
    end
    list_query = "@qc_inspection_tests = QcInspectionTest.find(:all,
           :include => {:qc_inspection_type_test => 'qc_test'},
           :order => 'inspection_test_number',
           :conditions => ['qc_inspection_id = ?', #{params[:id]}])"
    session[:inspection_tests_query] = list_query
    render_list_qc_inspection_tests
  end

  def render_list_qc_inspection_tests
    @can_edit = authorise(program_name(@qc_inspection_type_code),'edit',session[:user_id])
    @can_delete = authorise(program_name(@qc_inspection_type_code),'delete',session[:user_id])
    if @qc_inspection.status == QcInspection::STATUS_COMPLETED
      @can_edit   = false
      @can_delete = false
    end
    @qc_inspection_tests =  eval(session[:inspection_tests_query]) if !@qc_inspection_tests

    render :inline => %{
      <% grid            = build_qc_inspection_test_grid(@qc_inspection_tests,@can_edit,@can_delete)%>
      <% grid.caption    = 'Tests' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end
# {
#  "action"=>"save_inspection_test",
#  
#  "controller"=>"qc/qc_inspection",
#  
#  "samples"=>{
#   "6"=>{"annotation1_366"=>"Class", "measurement_366"=>""},
#   "7"=>{"annotation1_367"=>"Class", "measurement_367"=>""},
#   "8"=>{"annotation1_368"=>"Class", "measurement_368"=>""},
#   "9"=>{"annotation1_369"=>"Class", "measurement_369"=>""},
#   "1"=>{"measurement_361"=>"", "annotation1_361"=>"Class"},
#   "2"=>{"measurement_362"=>"", "annotation1_362"=>"Class"},
#   "3"=>{"measurement_363"=>"", "annotation1_363"=>"Class"},
#   "4"=>{"annotation1_364"=>"Class", "measurement_364"=>""},
#   "10"=>{"measurement_370"=>"", "annotation1_370"=>"Class"},
#   "5"=>{"annotation1_365"=>"Class", "measurement_365"=>""}   
#   }
#   
#  }

  def save_qc_inspection_test
    id = params[:id]
    if id && @qc_inspection_test = QcInspectionTest.find(id)
      @qc_inspection_type_code = @qc_inspection_test.qc_inspection.qc_inspection_type.qc_inspection_type_code
      return if authorise_for_web(program_name(@qc_inspection_type_code),'edit')== false
      QcInspectionTest.transaction do
        @qc_inspection_test.qc_results.each do |qc_result|
          qc_result.qc_result_measurements.each do |qc_result_measurement|
            qc_result_measurement.measurement  = params[:samples][qc_result_measurement.sample_no.to_s]["measurement_#{qc_result_measurement.id}"]
            qc_result_measurement.annotation_1 = params[:samples][qc_result_measurement.sample_no.to_s]["annotation_1_#{qc_result_measurement.id}"] unless @qc_inspection_test.cull_test
            qc_result_measurement.annotation_2 = params[:samples][qc_result_measurement.sample_no.to_s]["annotation_2_#{qc_result_measurement.id}"]
            qc_result_measurement.annotation_3 = params[:samples][qc_result_measurement.sample_no.to_s]["annotation_3_#{qc_result_measurement.id}"]
            qc_result_measurement.save!
          end
        end

        if params[:qc_inspection_test][:passed] && params[:qc_inspection_test][:passed] == 'true'
          @qc_inspection_test.passed = true
        else
          @qc_inspection_test.passed = false
        end
        @qc_inspection_test.save!

        if params[:qc_inspection_test][:complete] && params[:qc_inspection_test][:complete] == 'true'
          @qc_inspection_test.set_status QcInspectionTest::STATUS_COMPLETED
        end

        if QcInspection::STATUS_CREATED == @qc_inspection_test.qc_inspection.status
          @qc_inspection_test.qc_inspection.set_status QcInspection::STATUS_IN_PROGRESS
        end

      end

      if QcInspectionTest::STATUS_COMPLETED == @qc_inspection_test.status
        if params[:from_list] && params[:from_list] == 'y'
          url = "/qc/qc_inspection/current_qc_tests/#{@qc_inspection_type_code}"
        else
          url = "/qc/qc_inspection/edit_qc_inspection/#{@qc_inspection_test.qc_inspection.id}?id_value=#{@qc_inspection_type_code}"
        end
        render :inline=>%{
          <script>
            window.opener.frames[1].location.href ='#{url}';
            window.close();
          </script>
          },:layout=>'content'
      else
        flash[:notice] = 'Changes saved, now you can continue working or complete the test'
        edit_qc_inspection_test( params[:from_list] && params[:from_list] == 'y' )
      end

    end
  end

  def delete_qc_inspection_test
    begin
      id = params[:id]
      if id && qc_inspection_test = QcInspectionTest.find(id)
        qc_inspection_type_code = qc_inspection_test.qc_inspection.qc_inspection_type.qc_inspection_type_code
        return if authorise_for_web(program_name(qc_inspection_type_code),'delete')== false
        inspection_id = qc_inspection_test.qc_inspection_id
        qc_inspection_test.destroy
        # SET_STATUS ?
        session[:alert] = " Record deleted."
        params[:id] = inspection_id
        list_qc_inspection_tests
      end
    rescue
      handle_error('record could not be deleted')
    end
  end

  # Open a completed test for editing again.
  def re_edit_qc_inspection_test
    id = params[:id]
    if id && @qc_inspection_test = QcInspectionTest.find(id)
      @qc_inspection_type_code = @qc_inspection_test.qc_inspection.qc_inspection_type.qc_inspection_type_code
      return if authorise_for_web(program_name(@qc_inspection_type_code),'edit')== false

      @qc_inspection_test.set_status QcInspectionTest::STATUS_CREATED
      edit_qc_inspection_test
    end
  end

  # Edit a test but return to test list when done.
  def edit_qc_inspection_test_from_test_list
    edit_qc_inspection_test true
  end

  def edit_qc_inspection_test(from_list=false)
    id = params[:id]
    if id && @qc_inspection_test = QcInspectionTest.find(id)
      qc_inspection_type = @qc_inspection_test.qc_inspection.qc_inspection_type
      @qc_inspection_type_code = qc_inspection_type.qc_inspection_type_code
      @auto_complete = qc_inspection_type.auto_pass_and_complete
      return if authorise_for_web(program_name(@qc_inspection_type_code),'edit')== false
      @qc_results = @qc_inspection_test.qc_results.find(:all,
                                                        :include => 'qc_result_measurements',
                                                        :order   => 'qc_results.sample_no, qc_result_measurements.qc_measurement_code')
      @from_list = from_list
      if @qc_inspection_test.cull_test?
        if @qc_results && !@qc_results.empty?
          used_measurements = @qc_results.first.qc_result_measurements.find(:all,
                              :select => 'distinct qc_measurement_type_id').map {|r| r.qc_measurement_type_id }
        else
          used_measurements = []
        end
        @cull_measures = @qc_inspection_test.qc_inspection_type_test.qc_test.qc_measurement_types.find(:all,
                         :select => 'id, qc_measurement_code, qc_measurement_description',
                         :order => 'qc_measurement_code, qc_measurement_description').
                         map {|r| ["#{r.qc_measurement_code} - #{r.qc_measurement_description}", r.id]}
        @cull_measures.reject! {|m| used_measurements.include? m[1].to_i }
        render :template => '/qc/qc_inspection/edit_qc_inspection_cull_test.rhtml', :layout => 'content'
      else
        # otherwise renders standard rails rhtml...
        render :template => '/qc/qc_inspection/edit_qc_inspection_test.rhtml', :layout => 'content'
      end
    end
  end

  def view_qc_inspection_test
    id = params[:id]
    if id && @qc_inspection_test = QcInspectionTest.find(id)
      @qc_inspection_type_code = @qc_inspection_test.qc_inspection.qc_inspection_type.qc_inspection_type_code
      return if authorise_for_web(program_name(@qc_inspection_type_code),'view')== false
      @qc_results = @qc_inspection_test.qc_results.find(:all,
                                                        :include => 'qc_result_measurements',
                                                        :order   => 'qc_results.sample_no, qc_result_measurements.qc_measurement_code')
      # if @qc_inspection_test.cull_test?
      #   render :template => '/qc/qc_inspection/view_qc_inspection_cull_test.rhtml', :layout => 'content'
      # else
      #   render :template => '/qc/qc_inspection/view_qc_inspection_test.rhtml', :layout => 'content'
      # end
    end
  end

  # Add the selected cull measurement to the test and display it on the page.
  def add_cull_measure
    id = params[:id]
    if id && @qc_inspection_test = QcInspectionTest.find(id)
      @qc_inspection_type_code = @qc_inspection_test.qc_inspection.qc_inspection_type.qc_inspection_type_code
      return if authorise_for_web(program_name(@qc_inspection_type_code),'edit')== false
      @qc_measurement_type = QcMeasurementType.find(params[:cull_measure])
      @qc_result = @qc_inspection_test.qc_results.first

      begin
        @qc_result.add_cull_measurement( @qc_measurement_type )
        if !@qc_result.valid?
          ajax_error_alert('Validation error', nil, @qc_result)
          return
        end
        cull_measurements = @qc_result.cull_measurements( @qc_measurement_type )
        col_headers = cull_measurements.shift

        render :update do |page|
          page.insert_html :bottom, 'cull_results', :partial => 'cull_result_measurement',
                                               :object => cull_measurements[0],
                                               :locals => {:max_cols => @qc_inspection_test.max_columns_for_measurements,
                                                           :col_headers => col_headers,
                                                           :measurement_rules => @qc_inspection_test.measurement_rules}
          page << "$$('#cull_measure option[value=#{@qc_measurement_type.id}]').each(function(e) { e.remove(); })"
          page << "if ($('cull_measure').options.length == 0) {$('cull_add_form').hide();}"
        end
      rescue StandardError => error
        ajax_error_alert(nil, error, @qc_result)
      end
    end
  end

  def add_test_sample
    id = params[:id]
    if id && @qc_inspection_test = QcInspectionTest.find(id)
      @qc_inspection_type_code = @qc_inspection_test.qc_inspection.qc_inspection_type.qc_inspection_type_code
      return if authorise_for_web(program_name(@qc_inspection_type_code),'edit')== false
      no_samples = params[:no_of_samples].to_i

      if no_samples == 0 || no_samples > 10
        ajax_error_alert('Sample size must be a number greater than zero and less than 11.')
      else
        begin
        new_results = @qc_inspection_test.qc_inspection.add_samples( no_samples, @qc_inspection_test )

        render :update do |page|
          new_results.each do |result|
            page.insert_html :bottom, 'qc_test_results', :partial => 'result',
                                               :object => result,
                                               :locals => {:max_cols => @qc_inspection_test.max_columns_for_measurements,
                                                           :measurement_rules => @qc_inspection_test.measurement_rules}
          end
          page.replace_html 'qc_sample_size', @qc_inspection_test.qc_results.size
          page.visual_effect :highlight, 'qc_sample_size'
        end
        rescue StandardError => error
          ajax_error_alert(nil, error, @qc_inspection_test)
        end
      end
    end
  end

  def list_tests
    return if authorise_for_web(program_name(params[:id]),'edit')== false
    # Show a data miner...
    inspection_type = QcInspectionType.find_by_qc_inspection_type_code(params[:id])
    if inspection_type.nil?
      raise "Unknown Inspection Type: '#{params[:id]}'. The inspection type is not setup correctly or the menu system is not correctly defined."
    end
    data_miner = inspection_type.qc_business_context_search
    data_miner.sub!('.yml', '_tests.yml')
    session[:qc_inspection_type_code] = inspection_type.qc_inspection_type_code
    dm_session[:parameter_fields_values] = nil
    dm_session['se_layout'] = 'content'
    @content_header_caption = "'search'"
    dm_session[:redirect] = true
    build_remote_search_engine_form(data_miner, 'submit_tests_search')
  end

  def submit_tests_search
    @business_data = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    if (@business_data.length > 0)
      log_current_test_query
      render_found_tests
    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                            </script>
                          }, :layout => 'content'
    end
  end

  def render_found_tests
    if @business_data !=nil and @business_data.length > 0
      # @can_edit   = authorise(program_name(session[:qc_inspection_type_code]), 'edit', session[:user_id])
      # @can_delete = authorise(program_name(session[:qc_inspection_type_code]), 'delete', session[:user_id])
      @stat = dm_session[:search_engine_query_definition]
    #  @columns_list = session[:columns_list]
    @columns_list    = dm_session[:columns_list]
    @grid_configs    = dm_session[:grid_configs]
      render :inline => %{
      <% grid            = build_list_tests_grid(@business_data,@stat,@columns_list, session[:qc_inspection_type_code], @grid_configs) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    else
      redirect_to_index("'no search result records to list'", "''")
    end
  end

  #*****************************************************************************
  #--------------- INSPECTION REPORTS -----------------------------------------*
  #*****************************************************************************

  def send_qc_report
#    processing("launch_qc_report", "#{params[:id]}_#{params[:qc_inspection_id]}")
#  end

#  def launch_qc_report
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
#    rep_id, insp_id           = params[:id].split('_')
     rep_id = params[:id]
     insp_id = params[:qc_inspection_id]
    qc_inspection_type_report = QcInspectionTypeReport.find(rep_id)
    report_unit               = "reportUnit=/reports/MES/QC/#{qc_inspection_type_report.report_name}&"
    report_parameters         = "output=pdf&qc_inspection_id=#{insp_id}"
    RAILS_DEFAULT_LOGGER.info ("QCQCQC report_unit : " + report_unit.to_s)        
    RAILS_DEFAULT_LOGGER.info ("QCQCQC report_parameters : " + report_parameters.to_s)            
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)
    # job_id = params[:id]
    # report_unit ="reportUnit=/FG/recooling_job&"
    # report_parameters="output=pdf&job_id=" +"#{job_id}" 
    # redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)

  end

  # Get the current inspection record for the logged-in user and inspection type.
  def get_current_inspection_record( user_id, qc_inspection_type_code )
    ActiveRecord::Base.connection.select_one("select * from qc_current_inspections
                                              where user_id = #{user_id}
                                              and qc_inspection_type_code = '#{qc_inspection_type_code}'")
  end

  # Record the inspection that the user is currently working on.
  def log_current_inspection
    qc_current_inspection = get_current_inspection_record( session[:user_id].id, @qc_inspection_type_code )
    if qc_current_inspection.nil?
      ActiveRecord::Base.connection.execute("INSERT INTO qc_current_inspections (user_id, qc_inspection_type_code, qc_inspection_id)
                                            VALUES(#{session[:user_id].id}, '#{@qc_inspection_type_code}', #{@qc_inspection.id})")
    else
      ActiveRecord::Base.connection.execute(ActiveRecord::Base.extend_update_sql_with_request("UPDATE qc_current_inspections SET qc_inspection_id = #{@qc_inspection.id}
                                             WHERE user_id = #{session[:user_id].id} AND qc_inspection_type_code = '#{@qc_inspection_type_code}' "))
    end
  end

  # Record the last-used business context query for the inspection type / user so it can easily be re-run.
  def log_current_cusiness_context_query
    qc_current_inspection = get_current_inspection_record( session[:user_id].id, session[:qc_inspection_type_code] )
    if qc_current_inspection.nil?
      ActiveRecord::Base.connection.execute("INSERT INTO qc_current_inspections
      (user_id, qc_inspection_type_code, qc_business_context_query, columns_list)
      VALUES(#{session[:user_id].id}, '#{session[:qc_inspection_type_code]}',
            '#{dm_session[:search_engine_query_definition].gsub(/'/, "''")}', '#{session[:columns_list].to_yaml}')")
    else
      ActiveRecord::Base.connection.execute(ActiveRecord::Base.extend_update_sql_with_request("UPDATE qc_current_inspections
      SET qc_business_context_query = '#{dm_session[:search_engine_query_definition].gsub(/'/, "''")}',
          columns_list = '#{session[:columns_list].to_yaml}'
      WHERE user_id = #{session[:user_id].id} AND qc_inspection_type_code = '#{session[:qc_inspection_type_code]}' "))
    end
  end

  # Record the query for tests that the user is currently working on.
  def log_current_test_query
    qc_current_inspection = get_current_inspection_record( session[:user_id].id, session[:qc_inspection_type_code] )
    if qc_current_inspection.nil?
      ActiveRecord::Base.connection.execute("INSERT INTO qc_current_inspections
      (user_id, qc_inspection_type_code, qc_tests_query, tests_columns_list)
      VALUES(#{session[:user_id].id}, '#{session[:qc_inspection_type_code]}',
            '#{dm_session[:search_engine_query_definition].gsub(/'/, "''")}', '#{session[:columns_list].to_yaml}')")
    else
      ActiveRecord::Base.connection.execute(ActiveRecord::Base.extend_update_sql_with_request("UPDATE qc_current_inspections
      SET qc_tests_query = '#{dm_session[:search_engine_query_definition].gsub(/'/, "''")}',
          tests_columns_list = '#{session[:columns_list].to_yaml}'
      WHERE user_id = #{session[:user_id].id} AND qc_inspection_type_code = '#{session[:qc_inspection_type_code]}' "))
    end
  end

end
