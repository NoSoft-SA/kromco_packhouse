class  RmtProcessing::GrowerGradingController < ApplicationController

  # Include the layout here for any rhtml
  layout 'content'
 
  def program_name?
    "grower_grading"
  end

  def bypass_generic_security?
    true
  end

  def apply_bin_grading_rules
    @pool_graded_summary_id = params[:id]
    pool_graded_rebins = ActiveRecord::Base.connection.select_all("
                         select pgr.* from  pool_graded_rebins pgr where pool_graded_summary_id=#{params[:id]} ")

    PoolGradedSummary.transaction do
        ActiveRecord::Base.connection.select_all("
         update pool_graded_rebins set graded_class = '3' ,graded_size = '120',automatic_rule = true,
         rule_applied_at='#{Time.now}',rule_applied_by = '#{session[:user_id].user_name}'
         where id in (#{pool_graded_rebins.map{|x|x['id']}.join(',')})")
    end
    pool_graded_rebins
    render :inline=>%{
      <script>
        alert("rebins updated");
        window.opener.frames[1].location.href ='/rmt_processing/grower_grading/edit_pool_graded_summary/#{@pool_graded_summary_id}';
        window.close();
      </script>
      },:layout=>'content'
  end

  def apply_grading_rules(rule_cartons)
    @pool_graded_summary = PoolGradedSummary.find(params[:id])
    pool_graded_cartons = ActiveRecord::Base.connection.select_one("select count(distinct id ) as num_of_ctns from pool_graded_cartons
                         where pool_graded_summary_id= #{params[:id]}")['num_of_ctns']
    changed = {}
    updated_carton_nums = []
    rules = []
    PoolGradedSummary.transaction do
      rule_cartons.each do |rule,cartons|
        ActiveRecord::Base.connection.execute("
         update pool_graded_cartons set graded_class = '#{rule['new_class']}' ,graded_size = '#{rule['new_size']}',
         grading_applied =true,carton_grading_rule_id=#{rule['carton_grading_rule_id']},rule_applied_at='#{Time.now}',
         rule_applied_by = '#{session[:user_id].user_name}'
         where id in (#{cartons.map{|x|x['id']}.join(',')})")
        changed[cartons.map{|x|x['id']}.join(",")] = [rule['new_class'],rule['new_size']]
        cartons.each do |c|
          updated_carton_nums << c['id'] if !updated_carton_nums.include?(c['id'])
        end
        rules << rule['id'] if !rules.include?(rule['id'])
      end
      changed
    end
     if updated_carton_nums.length < pool_graded_cartons.to_i
       msg = "#{updated_carton_nums.length} cartons updated out of #{pool_graded_cartons}"
     else
       msg = "updated"
     end
    render :inline=>%{
      <script>
        alert("#{msg}");
        window.opener.frames[1].location.href ='/rmt_processing/grower_grading/edit_pool_graded_summary/#{@pool_graded_summary.id}';
        window.close();
      </script>
      },:layout=>'content'
  end

  def get_matched_cartons
    pool_graded_cartons = ActiveRecord::Base.connection.select_all("
         select distinct pgs.season_code,pgf.track_slms_indicator_code,pgc.*
        from pool_graded_summaries pgs
        left join pool_graded_farms pgf on pgf.pool_graded_summary_id = pgs.id
        join pool_graded_cartons pgc on pgc.pool_graded_summary_id = pgs.id
        where pgs.id = #{params[:id]} ")
    active_rules = get_active_rules
    rule_cartons = {}
    # #----test---------
    # pool_graded_ctns_list = pool_graded_cartons.map{ |a|
    #   "#{a['actual_size_count_code']};#{a['variety_short_long']};#{a['grade_code']};#{a['line_type']};#{a['season']};#{a['track_slms_indicator_code']}"
    # }
    # rules_list = active_rules.map{ |rule|
    #   "#{rule['size']};#{rule['variety']};#{rule['grade']};#{rule['line_type']};#{rule['season_code']};#{rule['track_slms_indicator_code']}"
    # }
    # unmatched_ctns = []
    # pool_graded_ctns_list.each do |ctn|
    #   unmatched_ctns << ctn if !rules_list.include?(ctn)
    # end
    # unmatched_ctns_num = unmatched_ctns.length
    # puts "-----------------CTNS-----------------------------"
    #      pool_graded_ctns_list.each do |ctn|
    #        puts "#{ctn}"
    #      end
    # puts "--------------------------------------------------"
    # puts "--------------------------------------------------"
    # puts "--------------------------------------------------"
    # puts "--------------------------------------------------"
    # puts "--------------------------------------------------"
    # puts "-----------------RULES----------------------------"
    #      rules_list.each do |rule|
    #        puts "#{rule}"
    #      end
    #
    #  unmatched_ctns_num



    # ----------------
    updated_all =[]
    active_rules.each do |rule|
      updated= []

      matched_cartons = pool_graded_cartons.find_all{|a|
        a['standard_size_count_value']==rule['standard_size_count_value'] &&
        a['variety_short_long']==rule['variety'] &&
        a['grade_code']==rule['grade'] && a['line_type']==rule['line_type'] &&
        a['season_code']==rule['season'] &&  a['track_slms_indicator_code']==rule['track_slms_indicator_code'] &&
        a['carton_grading_rule_id'].to_s != rule['id'].to_s}
      rule_cartons[rule] = matched_cartons if !matched_cartons.empty?

      get_cartons_where_rule_has_already_been_applied(pool_graded_cartons, rule, updated_all)
    end
    if !rule_cartons.empty?
      apply_grading_rules(rule_cartons)
    else
      msg = "The active rules already applied to the current cartons" if !updated_all.empty?
      msg = "NO matching rules where found!" if rule_cartons.empty? && updated_all.empty?
      render :inline=>%{
      <script>
        alert('#{msg}');
        window.close();
      </script>
      },:layout=>'content'
    end

  end

  def get_active_rules
    active_rules = ActiveRecord::Base.connection.select_all("
     select distinct s.season_code as season,cgr.standard_size_count_value,cgr.grade,cgr.variety,cgr.track_slms_indicator_code,
     cgr.line_type,cgr.updated_by,cgr.updated_at,cgr.deactivated_at,cgr.activated,cgr.class as clasi,cgr.id as carton_grading_rule_id,
     cgr.id,cgr.new_class,cgr.new_size,cgr.deactivated ,cgrh.activated as is_active_header,cgr.created_at,cgr.created_by
     from carton_grading_rule_headers cgrh
     join carton_grading_rules cgr on cgr.carton_grading_rule_header_id = cgrh.id
     join seasons s on cgrh.season_id = s.id where cgrh.activated = true and cgr.activated =true ")
    return active_rules
  end
 
  # Get a list of un-graded production runs to display in a grid for choosing.
  # Production Runs with bin count and weight summarised per production_run, farm_code & track_slms_indicator_code.
  def new_grading
    return if authorise_for_web(program_name?, 'create')== false
    render_production_run_search_form
  end

  def render_production_run_search_form
    session[:is_flat_search] = true
    #   render (inline) the search form
    render :inline => %{
    <% @content_header_caption = "'find ungraded production run'"%> 

    <%= build_production_run_search_form(nil,'submit_production_run_search','submit_production_run_search',true)%>

    }, :layout => 'content'
  end
 
  def submit_production_run_search
    conditions = []
    unless params[:production_run][:production_run_code].blank?
      conditions << " AND production_runs.production_run_code LIKE '%#{params[:production_run][:production_run_code]}%' "
    end
    # unless params[:production_run][:farm_code] == ""
    #   conditions << " AND farms.farm_code = '#{params[:production_run][:farm_code]}' "
    # end
    # unless params[:production_run][:track_slms_indicator_code] == ""
    #   conditions << " AND track_slms_indicators.track_slms_indicator_code = '#{params[:production_run][:track_slms_indicator_code]}' "
    # end

    query = "SELECT unioned.production_schedule_name, unioned.production_run_code, unioned.season_code,
    unioned.status, SUM(unioned.bin_count) as bin_count, SUM(unioned.bin_mass) as bin_mass
    FROM (
    SELECT production_runs.production_schedule_name, production_runs.production_run_code,
    bins.season_code, pool_graded_summaries.status, COUNT(bins.*) as bin_count, SUM(bins.weight) as bin_mass
    FROM bins
    JOIN production_runs on production_runs.id = bins.production_run_tipped_id
    LEFT OUTER JOIN pool_graded_summaries on pool_graded_summaries.production_run_code = production_runs.production_run_code
    WHERE (production_runs.grower_grading_status is null OR  production_runs.grower_grading_status = 'GRADING IN PROGRESS')
    AND (production_runs.is_depot_run is null OR production_runs.is_depot_run = false)
    AND production_runs.parent_run_code is null
    <conditions>
    GROUP BY production_runs.production_schedule_name, production_runs.production_run_code,
    bins.season_code, pool_graded_summaries.status

    UNION ALL

    SELECT production_runs.production_schedule_name, production_runs.production_run_code,
    bins.season_code, null as status, COUNT(bins.*) as bin_count, SUM(bins.weight) as bin_mass
    FROM bins
    JOIN production_runs child_runs on child_runs.id = bins.production_run_tipped_id
    JOIN production_runs on production_runs.child_run_code = child_runs.production_run_code
    WHERE (production_runs.grower_grading_status is null OR  production_runs.grower_grading_status = 'GRADING IN PROGRESS')
    AND (production_runs.is_depot_run is null OR production_runs.is_depot_run = false)
    AND production_runs.parent_run_code is null
    AND production_runs.child_run_code is not null
    <conditions>
    GROUP BY production_runs.production_schedule_name, production_runs.production_run_code,
    bins.season_code

    ) unioned
    GROUP BY unioned.production_schedule_name, unioned.production_run_code,
    unioned.season_code, unioned.status
    ORDER BY unioned.production_schedule_name, unioned.production_run_code,
    unioned.season_code".gsub('<conditions>', conditions.join(' '))

    conn = User.connection
    @production_runs = conn.select_all(query)

    if @production_runs.length == 0
      flash[:notice] = 'no records were found for the query'
      render_production_run_search_form
    else
      render_list_production_runs
    end
  end

  def render_list_production_runs
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    render :inline => %{
      <% grid            = build_production_run_grid(@production_runs,@can_edit,@can_delete) %>
      <% grid.caption    = 'choose ungraded production run' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def create_pool_graded_summary
    production_run_code = params[:id]
    @pool_graded_summary = PoolGradedSummary.create_from(production_run_code)

    # Edit the summary...
    redirect_to :action => 'edit_pool_graded_summary', :id => @pool_graded_summary.id

  rescue
    handle_error('record could not be created')
  end

  def search_pool_graded_summaries_flat
    return if authorise_for_web(program_name?,'read')== false
    @is_flat_search = true 
    render_pool_graded_summary_search_form
  end

  def render_pool_graded_summary_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
    #   render (inline) the search form
    render :inline => %{
    <% @content_header_caption = "'search pool_graded_summaries'"%> 

    <%= build_pool_graded_summary_search_form(nil,'submit_pool_graded_summaries_search','submit_pool_graded_summaries_search',@is_flat_search)%>

    }, :layout => 'content'
  end
 
 
  def submit_pool_graded_summaries_search
    @pool_graded_summaries = dynamic_search(params[:pool_graded_summary] ,'pool_graded_summaries','PoolGradedSummary')
    if @pool_graded_summaries.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_pool_graded_summary_search_form
    else
      render_list_pool_graded_summaries
    end
  end

  def list_pool_graded_summaries
    return if authorise_for_web(program_name?,'read') == false 

    if params[:page]!= nil 
      session[:pool_graded_summaries_page] = params['page']
      render_list_pool_graded_summaries
      return 
    else
      session[:pool_graded_summaries_page] = nil
    end

    list_query = "@pool_graded_summary_pages = Paginator.new self, PoolGradedSummary.count, @@page_size,@current_page
     @pool_graded_summaries = PoolGradedSummary.find(:all,
           :limit => @pool_graded_summary_pages.items_per_page,
           :offset => @pool_graded_summary_pages.current.offset)"
    session[:query] = list_query
    render_list_pool_graded_summaries
  end

  def render_list_pool_graded_summaries
    @pagination_server = "list_pool_graded_summaries"
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @current_page = session[:pool_graded_summaries_page]
    @current_page = params['page']||= session[:pool_graded_summaries_page]
    @pool_graded_summaries =  eval(session[:query]) if !@pool_graded_summaries

    render :inline => %{
      <% grid            = build_pool_graded_summary_grid(@pool_graded_summaries,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all pool_graded_summaries' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@pool_graded_summary_pages) if @pool_graded_summary_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end
 
  def edit_pool_graded_summary
    return if authorise_for_web(program_name?,'edit')==false 
    id = params[:id]
    if id && @pool_graded_summary = PoolGradedSummary.find(id)
      render_edit_pool_graded_summary
    end
  end

  def render_edit_pool_graded_summary
    #   render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit pool_graded_summary'"%> 

    <%= build_pool_graded_summary_form(@pool_graded_summary,'update_pool_graded_summary','update_pool_graded_summary',true)%>

    }, :layout => 'content'
  end
 
  def update_pool_graded_summary
    # Nothing to do - re-show the form.
    return if authorise_for_web(program_name?,'edit')==false 
    id = params[:pool_graded_summary][:id]
    if id && @pool_graded_summary = PoolGradedSummary.find(id)
      flash[:notice] = 'nothing to update'
      render_edit_pool_graded_summary
    end
  end

  # def cull_grading
  #   pool_graded_summary = PoolGradedSummary.find(params[:id])

  #   # Find or create the QcInspection related to this pool summary.
  #   qc_inspection = pool_graded_summary.make_or_get_cull( PoolGradedSummary::QCINSPECTION_TYPE, session[:user_id].user_name )

  #   #Save the return url in session so QC can return to Grower Grading.
  #   session[:qc_inspection_back_controller] = "rmt_processing/grower_grading"
  #   session[:qc_inspection_back_action]     = "edit_pool_graded_summary"
  #   session[:qc_inspection_back_id]         = pool_graded_summary.id
  #   session[:qc_inspection_back_for]        = qc_inspection.id
  #   # Hand over to the QcInspectionController.
  #   redirect_to :controller      => 'qc/qc_inspection',
  #               :action          => 'edit_qc_inspection',
  #               :id              => qc_inspection.id
  # end
 
  def summarise_rebins( pool_graded_summary_id=nil )
    @pool_graded_summary = PoolGradedSummary.find(pool_graded_summary_id || params[:id])
    #@pool_graded_rebins  = @pool_graded_summary.pool_graded_rebins.find(:all, :order => 'class_code, size_code, graded_class')
    @pool_graded_rebins = PoolGradedRebin.find_by_sql("select (DATE(rule_applied_at) -  DATE(updated_at)) as auto_rule_age ,pool_graded_rebins.* from pool_graded_rebins
                          where pool_graded_summary_id =#{@pool_graded_summary.id} order by class_code, size_code, graded_class")
    @refresh_main = !pool_graded_summary_id.nil?

    #@data_set = [{:status=>'Shipped',:date=>Time.now},{:task=>'Paid',:date=>''},{:task=>'Returned',:date=>'2011-03-11 14:48:18'}]
    if @pool_graded_summary.complete?
      render :template => '/rmt_processing/grower_grading/summarise_rebins_view.rhtml'
    end
  end
 
  def summarise_cartons
    @pool_graded_summary = PoolGradedSummary.find(params[:id])
    # @pool_graded_cartons = @pool_graded_summary.pool_graded_cartons.find(:all, :order => 'actual_size_count_code, product_class_code,
    #                                                 fg_code_old, variety_short_long, grade_code, line_type')
    #
    @pool_graded_cartons = PoolGradedCarton.find_by_sql("select (DATE(rule_applied_at) -  DATE(updated_at)) as auto_rule_age ,* from pool_graded_cartons where  pool_graded_summary_id =#{@pool_graded_summary.id}
                           order by actual_size_count_code,standard_size_count_value, product_class_code,fg_code_old, variety_short_long, grade_code, line_type")
    @summary = {}
    @pool_graded_cartons.each do |carton|
      key = "#{carton.organization_code}, #{carton.grade_code}"
      @summary[key] ||= [0,0,0,0,0.0]
      @summary[key][0] += carton.qty_not_inspected
      @summary[key][1] += carton.qty_inspected-carton.qty_failed
      @summary[key][2] += carton.qty_failed
      @summary[key][3] += carton.cartons_quantity
      @summary[key][4] += carton.schedule_weight
    end
    if @pool_graded_summary.complete?
      render :template => '/rmt_processing/grower_grading/summarise_cartons_view.rhtml'
    end
  end
 
  # Show a "Report" of the grading figures for checking purposes.
  # PoolGradedSummary#summarise_to_detail will validate rebins and cartons
  # Then populate PoolGradedDetail and update the PoolGradedSummary status.
  def preview_grading
    @pool_graded_summary = PoolGradedSummary.find(params[:id])
    begin
      @pool_graded_summary.summarise_to_detail
      @carton_count = @pool_graded_summary.pool_graded_cartons.sum('cartons_quantity') || 0

      prod_run = ProductionRun.find(:first, :conditions => ['production_run_code = ?', @pool_graded_summary.production_run_code])
      sample_bin = Bin.find(:first, :conditions => ['production_run_tipped_id = ?', prod_run.id])
      @track_slms_indicator = TrackSlmsIndicator.find(sample_bin.track_indicator1_id)
      # @track_slms_indicator = TrackSlmsIndicator.find(:first)

      @pool_graded_details = @pool_graded_summary.grouped_detail
      @g_totals            = @pool_graded_details.pop # Last line has grand totals - percentage and weight
      @totals              = @pool_graded_details.pop # Second last line has totals per class - percentage and weight
      @total1              = @g_totals[1]
      @total2              = @g_totals[2]
#      @pool_graded_culls   = @pool_graded_summary.pool_graded_culls
      @class_2_perc        = @totals[2].to_f
      @class_3_perc        = @totals[3].to_f

    rescue StandardError => e
      redirect_to_index("Grower grading can not be previewed. #{e.message}","'Unable to preview'")
    end
  end

  def save_pool_graded_rebins
    @pool_graded_summary = PoolGradedSummary.find(params[:id])
    PoolGradedSummary.transaction do
      @pool_graded_summary.pool_graded_rebins.each do |pool_graded_rebin|
        pool_graded_rebin.graded_class  = params[:rebins][pool_graded_rebin.id.to_s]['graded_class']
        pool_graded_rebin.graded_size   = params[:rebins][pool_graded_rebin.id.to_s]['graded_size']
        pool_graded_rebin.graded_weight = params[:rebins][pool_graded_rebin.id.to_s]['graded_weight']
        pool_graded_rebin.save!
      end
    end

    render :inline=>%{
      <script>
        window.opener.frames[1].location.href ='/rmt_processing/grower_grading/edit_pool_graded_summary/#{@pool_graded_summary.id}';
        window.close();
      </script>
      },:layout=>'content'

  rescue ActiveRecord::RecordInvalid => error
    flash[:error] = error.to_s
    summarise_rebins
    @pool_graded_rebins.each do |pool_graded_rebin|
      pool_graded_rebin.graded_class  = params[:rebins][pool_graded_rebin.id.to_s]['graded_class']
      pool_graded_rebin.graded_size   = params[:rebins][pool_graded_rebin.id.to_s]['graded_size']
      pool_graded_rebin.graded_weight = params[:rebins][pool_graded_rebin.id.to_s]['graded_weight']
    end
    render :action => 'summarise_rebins'

  rescue
    handle_error('could not save rebins')
  end

  def split_rebin
    pool_graded_rebin = PoolGradedRebin.find(params[:id])
    pool_graded_rebin.split_rebin
    summarise_rebins( pool_graded_rebin.pool_graded_summary_id )
    render :action => 'summarise_rebins'
  end

  def delete_rebin
    pool_graded_rebin = PoolGradedRebin.find(params[:id])
    id         = pool_graded_rebin.pool_graded_summary_id
    PoolGradedRebin.transaction do
      pool_graded_summary = PoolGradedSummary.find( id )
      pool_graded_summary.status = PoolGradedSummary::STATUS_IN_PROGRESS
      pool_graded_summary.save!
      pool_graded_rebin.destroy
    end

    summarise_rebins( id )
    render :action => 'summarise_rebins'
  end

  def save_pool_graded_cartons
    @pool_graded_summary = PoolGradedSummary.find(params[:id])
    PoolGradedSummary.transaction do
      @pool_graded_summary.pool_graded_cartons.each do |pool_graded_carton|
        pool_graded_carton.graded_class    = params[:cartons][pool_graded_carton.id.to_s]['graded_class']
        pool_graded_carton.graded_size     = params[:cartons][pool_graded_carton.id.to_s]['graded_size']
        pool_graded_carton.grading_applied = params[:cartons][pool_graded_carton.id.to_s]['grading_applied']
        pool_graded_carton.save!
      end
    end

    render :inline=>%{
      <script>
        window.opener.frames[1].location.href ='/rmt_processing/grower_grading/edit_pool_graded_summary/#{@pool_graded_summary.id}';
        window.close();
      </script>
      },:layout=>'content'

  rescue ActiveRecord::RecordInvalid => error
    flash[:error] = error.to_s
    summarise_cartons
    @pool_graded_cartons.each do |pool_graded_carton|
      pool_graded_carton.graded_class    = params[:cartons][pool_graded_carton.id.to_s]['graded_class']
      pool_graded_carton.graded_size     = params[:cartons][pool_graded_carton.id.to_s]['graded_size']
      pool_graded_carton.grading_applied = params[:cartons][pool_graded_carton.id.to_s]['grading_applied']
    end
    render :action => 'summarise_cartons'

  rescue
    handle_error('could not save cartons')
  end

  def complete_grading
    @pool_graded_summary = PoolGradedSummary.find(params[:id])
    if @pool_graded_summary.status != PoolGradedSummary::STATUS_GRADED &&  @pool_graded_summary.status != PoolGradedSummary::STATUS_COMPLETE
      raise "The grading must be previewed first."
    end
    @pool_graded_summary.summarise_to_detail # Re-summarise to make sure.
    @pool_graded_summary.complete_grading
    flash[:notice] = 'Grading is complete. The report can be generated.'
    render_edit_pool_graded_summary
  rescue StandardError => e
    if e.message =~ /Cannot|previewed/
      flash[:notice] = e.message
      render_edit_pool_graded_summary
    else
      redirect_to_index("Grower grading can not be completed. #{e.message}","'Unable to complete'")
    end
  end

  def delete_pool_graded_summary
    begin
      return if authorise_for_web(program_name?,'delete')== false
      if params[:page]
        session[:pool_graded_summaries_page] = params['page']
        render_list_pool_graded_summaries
        return
      end
      id = params[:id]
      if id && pool_graded_summary = PoolGradedSummary.find(id)
        pool_graded_summary.destroy
        session[:alert] = " Record deleted."
        render_list_pool_graded_summaries
      end
    rescue
      handle_error('record could not be deleted')
    end
  end

  def uncomplete_pool_graded_summary
    return if authorise_for_web(program_name?,'edit')==false 
    id = params[:id]
    if id && @pool_graded_summary = PoolGradedSummary.find(id)
      @pool_graded_summary.status = PoolGradedSummary::STATUS_IN_PROGRESS
      @pool_graded_summary.save!
      flash[:notice] = 'PoolGraded Summary can now be modified'
      render_edit_pool_graded_summary
    end
  end

  def report_grading
    redirect_to_index("Report has not yet been implemented.")
  end

  def list_pool_graded_farms
    return if authorise_for_web(program_name?,'read') == false 

    list_query = "@pool_graded_farms = PoolGradedFarm.find(:all,
           :conditions => ['pool_graded_summary_id = ?', params[:id]])"
    session[:query] = list_query
    render_list_pool_graded_farms
  end

  def render_list_pool_graded_farms
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    @pool_graded_farms =  eval(session[:query]) if !@pool_graded_farms

    render :inline => %{
      <% grid            = build_pool_graded_farm_grid(@pool_graded_farms,@can_edit,@can_delete) %>
      <% grid.caption    = 'Farms' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  # ---------------------------------------------------------------------------
  # Combo change actions for search form:
  # ---------------------------------------------------------------------------

  def season_search_combo_changed
    season_code = get_selected_combo_value(params)
   #session[:pool_graded_summary_search_form][:report_type_name_combo_selection] = @report_type_name
    @production_schedule_names = PoolGradedSummary.find_by_sql("select distinct production_schedule_name from pool_graded_summaries where season_code = '#{season_code}'").map{|g|[g.production_schedule_name]}
    @production_schedule_names.unshift("<empty>")
    render :inline => %{
      <%= select('pool_graded_summary','production_schedule_name',@production_schedule_names)%>
	   
      <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_pool_graded_summary_production_schedule_name'/>
      <%= observe_field('pool_graded_summary_production_schedule_name', :update => 'production_run_code_cell',
                        :url => {:action => session[:pool_graded_summary_search_form][:production_schedule_name_observer][:remote_method]},
                        :loading => "show_element('img_pool_graded_summary_production_schedule_name');",
                        :complete => session[:pool_graded_summary_search_form][:production_schedule_name_observer][:on_completed_js])%>        
        
        <% @empty_run = select('pool_graded_summary','production_run_code',["Select a value from production_schedule_name"]) %>
        <script>
         <%= update_element_function(
          "production_run_code_cell", :action => :update,
          :content => @empty_run)
         %>
        </script> 
      }
  end

  def production_schedule_name_search_combo_changed
    production_schedule_name = get_selected_combo_value(params)
    @production_run_codes = PoolGradedSummary.find_by_sql("select distinct production_run_code from pool_graded_summaries where production_schedule_name = '#{production_schedule_name}'").map{|g|[g.production_run_code]}
    @production_run_codes.unshift("<empty>")
    render :inline => %{
      <%= select('pool_graded_summary','production_run_code',@production_run_codes)%>
      }
  end

  private

  def get_cartons_where_rule_has_already_been_applied(pool_graded_cartons, rule, updated_all)
    updated = pool_graded_cartons.find_all { |a|
      a['standard_size_count_value'] == rule['standard_size_count_value'] &&
          a['variety_short_long'] == rule['variety'] && a['grade_code'] == rule['grade'] && a['line_type'] == rule['line_type'] &&
          a['season'] == rule['season_code'] && a['track_slms_indicator_code'] == rule['track_slms_indicator_code'] &&
          a['carton_grading_rule_id'].to_s == rule['id'].to_s }
    updated.each do |ctn|
      updated_all << ctn
    end
  end

end
