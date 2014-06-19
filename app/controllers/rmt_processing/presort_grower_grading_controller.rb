class  RmtProcessing::PresortGrowerGradingController < ApplicationController
  layout 'content'


  def program_name?
    "presort_grower_grading"
  end

  def bypass_generic_security?
    true
  end

  def complete_grading
    return if authorise_for_web(program_name?,'edit')==false
    id = params[:id]
    if id && @pool_graded_summary = PoolGradedPsSummary.find(id)
      @pool_graded_summary.status = "GRADED"
      @pool_graded_summary.save!
      params[:id]=@pool_graded_summary.id
      flash[:notice] = 'PoolGraded Summary graded'
      edit_pool_graded_ps_summary
    end
  end

  def preview_ps_grades
  @ps_grades = "http://172.16.16.1:8080/jasperserver/flow.html?_flowId=viewReportFlow&reportUnit=/Presort/ps_grower_grading&j_username=jasperadmin&j_password=jasperadmin&output=pdf&pool_graded_ps_summary_id=#{params[:id]}"
  render :inline => %{
      <script>
        window.resizeTo(1200,800);
        window.location.href= "<%= @ps_grades %>";
      </script>
    }
  end

  def get_maf_ps_binss(ps_summary,refresh=nil)
    #view-source:http://192.168.10.7:3000/services/pre_sorting/bin_created?bin=704
    begin

      @lot_number=ps_summary.maf_lot_number
      http = Net::HTTP.new(Globals.bin_created_mssql_server_host, Globals.bin_created_mssql_presort_server_port)
      request = Net::HTTP::Post.new("/select")
      parameters  = {'method' => 'select', 'statement' => Base64.encode64("
      select Numero_lot as maf_lot_number,Code_adherent as maf_farm_code,Code_clone as maf_rmt_code,
      Nom_article as maf_article,Nom_calibre as maf_count,Poids as maf_weight,Poids_total_calibre as maf_lot_weight,
      Nb_palox as maf_infeed_bin_qty
      FROM [productionv50].[dbo].[Viewlotapportresultatagreage]
      WHERE Numero_lot = #{@lot_number}
      ORDER BY Numero_lot,Num_couleur,Num_calibre
      ")}

      request.set_form_data(parameters)
      response = http.request(request)
      puts "---\n#{response.code} - #{response.message}\n---\n"

      if '200' == response.code
        res     = response.body.split('resultset>').last.split('</res').first
        results = Marshal.load(Base64.decode64(res))
      else
        err = response.body.split('</message>').first.split('<message>').last
        errmsg = "SQL Integration returned an error running \"select Numero_lot as maf_lot_number,Code_adherent as maf_farm_code,Code_clone as maf_rmt_code,
      Nom_article as maf_article,Nom_calibre as maf_count,Poids as maf_weight,Poids_total_calibre as maf_lot_weight,
      Nb_palox as maf_infeed_bin_qty
      FROM [productionv50].[dbo].[Viewlotapportresultatagreage]
      WHERE Numero_lot = #{@lot_number}
      ORDER BY Numero_lot,Num_couleur,Num_calibre \". The http code is #{response.code}. Message: #{err}."

        logger.error ">>>> #{errmsg}"
        raise errmsg
        return
      end

        raise "no bins  Palox"  if(results.empty?)

      maf_pool_graded_ps_bins=results
      if refresh
        delete_pool_graded_ps_summary_bins(pool_graded_ps_summary_id)
      end
      maf_pool_graded_ps_bins=File.open("C:/projects/docs 2014/kromco/ps_grading/pool_graded_ps_bins.csv").readlines
      maf_pool_graded_ps_bins.delete_at(0)

      maf_pool_graded_ps_bins.each do |maf_bin|
        maf_bin_attr=maf_bin.split(",")
        maf_article=maf_bin_attr[2].split("_")
        inmemory_maf_bin=PoolGradedPsBin.new(:pool_graded_ps_summary_id=>pool_graded_ps_summary_id,:maf_farm_code=>maf_bin_attr[0],:maf_rmt_code=>maf_bin_attr[1],:maf_article=>maf_bin_attr[2],
                                             :maf_count=>maf_bin_attr[3],:graded_count=>maf_bin_attr[3],:maf_weight=>maf_bin_attr[4],:maf_class=>maf_article[0],:graded_class=>maf_article[0],:maf_colour=>maf_article[1],:graded_colour=>maf_article[1],
                                             :created_by=>ActiveRequest.get_active_request.user)
        maf_pool_graded_ps_bin_recordset << inmemory_maf_bin
      end
         rescue
    return $!.message
    end
  end

  def delete_ps_bin
    session[:ps_bin_id]=params[:id]
    render :inline => %{
                       <script>
                         if(confirm("Are you sure you want to delete?") == true)
                            window.location = "/rmt_processing/presort_grower_grading/confirm_delete_ps_bin";
                         else
                            window.location = "/rmt_processing/presort_grower_grading/cancel_delete_ps_bin";
                         end
                       </script>}

  end


  def confirm_delete_ps_bin
    pool_graded_ps_summary=PoolGradedPsSummary.find(session[:active_doc]['ps_summary'])
    ps_bin=PoolGradedPsBin.find(session[:ps_bin_id])
    ps_bin.destroy
    maf_total_lot_weight = PoolGradedPsBin.find_by_sql("select SUM(maf_weight) as maf_weight from pool_graded_ps_bins where pool_graded_ps_summary_id=#{session[:active_doc]['ps_summary']}")[0]['maf_weight']
    if !maf_total_lot_weight
      pool_graded_ps_summary.update_attribute(:maf_total_lot_weight, sprintf('%0.2f',0.0 ).to_f)
    else
      pool_graded_ps_summary.update_attribute(:maf_total_lot_weight, sprintf('%0.2f',maf_total_lot_weight ).to_f)
    end
    @pool_graded_ps_summary_id = session[:active_doc]['ps_summary']
    session[:ps_bin_id]=nil

    render :inline => %{<script>
                             alert('ps_bin deleted');
                             window.location.href = "/rmt_processing/presort_grower_grading/crud_ps_bins/<%= @pool_graded_ps_summary_id %>";
                       </script>}
  end

  def cancel_delete_ps_bin
    session[:ps_bin_id]=nil
    @pool_graded_ps_summary_id = session[:active_doc]['ps_summary']
    render :inline => %{<script>
                            alert('DELETE CANCELLED');
                            window.location.href = "/rmt_processing/presort_grower_grading/crud_ps_bins/<%= @pool_graded_ps_summary_id %>";
                      </script>}, :layout => "content"
  end

  def add_line
    @is_create_retry
    render :inline => %{
<% @content_header_caption = "'add line'"%>

<%= build_new_pool_graded_ps_bin_line_form(@pool_graded_ps_bin,'create_new_ps_bin_line','add_line',false,@is_create_retry)%>

}, :layout => 'content'
  end

  def validate_ps_bin_params(params_ps_bin)
    error = nil
    if params_ps_bin['maf_weight'] ==""    || params_ps_bin['maf_weight']         == nil ||
       params_ps_bin['maf_class']  ==""    || params_ps_bin['maf_class']          == nil ||
       params_ps_bin['maf_colour'] ==""    ||  params_ps_bin['maf_colour']        == nil ||
       params_ps_bin['maf_count']  ==""    ||  params_ps_bin['maf_count']         == nil ||
       params_ps_bin['maf_weight'] ==""    ||  params_ps_bin['maf_weight']        == nil ||
       params_ps_bin['maf_article_count']==""  || params_ps_bin['maf_article_count']  == nil
      error = "all fields are required"
    else
      error=  "maf weight should be numeric" if !params_ps_bin['maf_weight'].is_numeric?
    end


      return error
    end



  def create_new_ps_bin_line
    if error=validate_ps_bin_params(params[:ps_bin])
      flash[:error]  = error
      add_line   and return
    end
    pool_graded_ps_summary=PoolGradedPsSummary.find(session[:active_doc]['ps_summary'])
    params[:ps_bin]['maf_article']=params[:ps_bin]['maf_class'].to_s + "_"  + params[:ps_bin]['maf_colour'].to_s + "_" + params[:ps_bin]['maf_article_count'].to_s
    ps_bin=PoolGradedPsBin.new(params[:ps_bin])
    ps_bin.pool_graded_ps_summary_id=session[:active_doc]['ps_summary']
    if ps_bin.save
      ps_bin.graded_weight = params[:maf_weight]
      maf_total_lot_weight = PoolGradedPsBin.find_by_sql("select SUM(maf_weight) as maf_weight from pool_graded_ps_bins where pool_graded_ps_summary_id=#{session[:active_doc]['ps_summary']}")[0]['maf_weight']
      pool_graded_ps_summary.update_attribute(:maf_total_lot_weight, sprintf('%0.2f',maf_total_lot_weight ).to_f)
      @pool_graded_ps_summary_id=session[:active_doc]['ps_summary']
      render :inline => %{<script>
                             alert('new line created');
                             window.close();
                             window.opener.location.href = "/rmt_processing/presort_grower_grading/crud_ps_bins/<%= @pool_graded_ps_summary_id %>";
                       </script>}
    else
      @is_create_retry = true
      add_line
    end

  end

  def save_pool_graded_ps_bins
    session[:ps_bin_id]=params[:id]
    session[:ps_bin_params] =params[:ps_bins]
    render :inline => %{
                       <script>
                         if(confirm("Are you sure you want to save?") == true)
                            window.location = "/rmt_processing/presort_grower_grading/confirm_save_pool_graded_ps_bins";
                         else
                            window.location = "/rmt_processing/presort_grower_grading/cancel_save_pool_graded_ps_bins";
                         end
                       </script>}

  end


  def confirm_save_pool_graded_ps_bins
    @pool_graded_ps_summary = PoolGradedPsSummary.find(session[:active_doc]['ps_summary'])
    PoolGradedPsSummary.transaction do
      @pool_graded_ps_summary.pool_graded_ps_bins.each do |pool_graded_ps_bin|
        pool_graded_ps_bin.graded_class  = session[:ps_bin_params][pool_graded_ps_bin.id.to_s]['graded_class']
        pool_graded_ps_bin.graded_colour = session[:ps_bin_params][pool_graded_ps_bin.id.to_s]['graded_colour']
        pool_graded_ps_bin.graded_count  = session[:ps_bin_params][pool_graded_ps_bin.id.to_s]['graded_count']
        pool_graded_ps_bin.graded_weight = session[:ps_bin_params][pool_graded_ps_bin.id.to_s]['graded_weight']
        pool_graded_ps_bin.save!
      end
      session[:total_adjusted_weight]=session[:ps_bin_params]['total_graded_weight_hidden_field']
    end
    render :inline => %{<script>
                             alert('bins_edited');
                             window.location.href = "/rmt_processing/presort_grower_grading/crud_ps_bins/<%= @pool_graded_ps_summary.id %>";
                       </script>}
  end



  def cancel_save_pool_graded_ps_bins
    session[:ps_bin_params]=nil
    @pool_graded_ps_summary_id = session[:active_doc]['ps_summary']
    flash[:error] =  'save cancelled'
    render :inline => %{<script>
                            window.location.href = "/rmt_processing/presort_grower_grading/crud_ps_bins/<%= @pool_graded_ps_summary_id %>";
                      </script>}, :layout => "content"
  end




  def crud_ps_bins(pool_graded_ps_summary_id=nil)
      @pool_graded_ps_summary = PoolGradedPsSummary.find(pool_graded_ps_summary_id || params[:id])

    @pool_graded_ps_bins  = @pool_graded_ps_summary.pool_graded_ps_bins.find(:all, :order => 'maf_class,maf_colour,maf_count')#:conditions => [ "maf_class <> (?)", 'SA']
    set_active_doc("ps_summary",@pool_graded_ps_summary.id)
      total_calculated_weight= sprintf('%0.2f',0.0 ).to_f
      pesage_maf_weight = sprintf('%0.2f',0.0 ).to_f
      pesage_record= @pool_graded_ps_summary.pool_graded_ps_bins.find(:all, :conditions => [ "maf_class = (?)", 'pesage'])
      pesage_maf_weight =pesage_record[0]['maf_weight']  if !pesage_record.empty?
    @pool_graded_ps_bins.each do |bin|
      if bin.graded_weight==0  ||   bin.graded_weight== nil || bin.graded_weight== sprintf('%0.2f',0.0 ).to_f
        bin.graded_weight=sprintf('%0.2f',0.0 ).to_f
        bin.weight_adjusted_plus = sprintf('%0.2f',0.0 ).to_f
        bin.weight_adjusted_minus = sprintf('%0.2f',0.0 ).to_f
        bin.total_calculated_weight  = sprintf('%0.2f',0.0 ).to_f

        total_calculated_weight=total_calculated_weight + sprintf('%0.2f',bin.maf_weight).to_f
      else
        weight_diff=bin.graded_weight - bin.maf_weight
        if weight_diff > 0
          bin.weight_adjusted_plus   = sprintf('%0.2f',weight_diff ).to_f
        else
          bin.weight_adjusted_minus  = sprintf('%0.2f',weight_diff.abs ).to_f
        end
        bin.weight_adjusted_plus = sprintf('%0.2f',0.0 ).to_f if bin.weight_adjusted_plus==nil
        bin.weight_adjusted_minus = sprintf('%0.2f',0.0 ).to_f if bin.weight_adjusted_minus==nil
        total_calculated_weight=total_calculated_weight + bin.graded_weight
      end

    end

      round_check = sprintf('%0.2f',@pool_graded_ps_summary.maf_total_lot_weight).to_f - total_calculated_weight
      maf_calculated_mass =sprintf('%0.2f',@pool_graded_ps_summary.maf_total_lot_weight).to_f  +  pesage_maf_weight  + round_check
      waste_weight = sprintf('%0.2f',@pool_graded_ps_summary.rmt_bin_weight).to_f  -  maf_calculated_mass
      @pool_graded_ps_bins.each do |bin|
        bin.total_calculated_weight = total_calculated_weight
        bin.round_check =sprintf('%0.2f',round_check).to_f
        bin.maf_weight= sprintf('%0.2f',bin.maf_weight).to_f
        bin.rmt_bin_weight =@pool_graded_ps_summary.rmt_bin_weight
        bin.pesage_maf_weight = printf('%0.2f',pesage_maf_weight).to_f
        bin.maf_total_lot_weight = printf('%0.2f',@pool_graded_ps_summary.maf_total_lot_weight).to_f
        bin.waste_weight= waste_weight
      end


      session[:total_adjusted_weight] =nil
    @pool_graded_ps_bin_ids=[]
    @pool_graded_ps_bins.map{|p| @pool_graded_ps_bin_ids << p.id }
    @refresh_main = !pool_graded_ps_summary_id.nil?
   # if @pool_graded_ps_summary.complete?
   #   render :template => '/rmt_processing/presort_grower_grading/crud_ps_bins_view.rhtml'
   #end
  end

  def list_maf_ps_bins
    @maf_ps_bins = session[:maf_ps_bins]
    render_list_maf_ps_bins
  end

  def refresh_pool_graded_ps_bins
      session[:refresh_ps_bins] =true
      session[:refresh_ps]=nil
      pool_graded_ps_summary = PoolGradedPsSummary.find(session[:active_doc]['ps_summary'])
      maf_results=PoolGradedPsBin.get_maf_ps_bins(pool_graded_ps_summary,true)
      session[:maf_ps_bins] = maf_results[0]
      session[:maf_totals]={'maf_tipped_lot_qty'=> maf_results[1],'maf_total_lot_weight'=> maf_results[2]}
      confirm_submit_or_cancel_maf_bins
  end

  def render_list_maf_ps_bins
    @pagination_server = ""
    @current_page = session[:presort_grower_grading_page]
    @current_page = params['page']||= session[:ppresort_grower_grading_page]
    render :inline => %{
		<% grid = build_maf_ps_bins_grid(@maf_ps_bins)%>
		<% grid.caption = ' bins data'%>
    <%grid.height='700'%>
		<% @header_content = grid.build_grid_data %>
		<% @pagination = pagination_links(@presort_grower_grading_pages) if @presort_grower_grading_pages != nil %>
		<%= grid.render_html %>
		<%= grid.render_grid %>
	},:layout => 'content'
  end



  def import_maf_ps_lot
    @pool_graded_ps_summary =PoolGradedPsSummary.find(params[:id])
    set_active_doc("ps_summary",@pool_graded_ps_summary.id)
    mes_ps_bins=PoolGradedPsBin.find_all_by_pool_graded_ps_summary_id(params[:id])
    if mes_ps_bins.empty? && !session[:refresh_ps_bins]
      #session[:maf_ps_bins]=PoolGradedPsBin.get_maf_ps_bins(@pool_graded_ps_summary.id)
      maf_results=PoolGradedPsBin.get_maf_ps_bins(@pool_graded_ps_summary)
      session[:maf_ps_bins] = maf_results[0]
      session[:maf_totals]={'maf_tipped_lot_qty'=> maf_results[1],'maf_total_lot_weight'=> maf_results[2]}
      compare_num_maf_farms_with_mes_farms(@pool_graded_ps_summary.maf_lot_number)
      @is_edit=nil
    else
      session[:maf_ps_bins]=mes_ps_bins
      @is_edit=true
    end

    render_import_maf_ps_lot
  end

   def compare_num_maf_farms_with_mes_farms(maf_lot_number)
     maf_farms_count = session[:maf_ps_bins].group_by{|a|a.maf_farm_code}
     mes_farm_count  = ActiveRecord::Base.connection.execute("select distinct count(f.farm_code) as  mes_farm_count from pool_graded_ps_farms f
                       inner join pool_graded_ps_summaries s on f.pool_graded_ps_summary_id=s.id
                       where s.maf_lot_number='#{maf_lot_number}'")
     maf_rmt_codes    = session[:maf_ps_bins].group_by{|a|a.maf_rmt_code}
     session[:warning]=nil
     if maf_farms_count.length.to_i != mes_farm_count[0][0].to_i
       session[:warning]="the number of farms in maf and mes for this lot are different"
     elsif maf_rmt_codes.length.to_i != mes_farm_count[0][0].to_i
       session[:warning]="the number of rmt_codes in maf and farms in  mes for this lot are different"
     end
   end

  def render_import_maf_ps_lot
   if !@is_edit
     @pool_graded_ps_summary.maf_tipped_lot_qty =  session[:maf_totals]['maf_tipped_lot_qty']
     @pool_graded_ps_summary.maf_total_lot_weight= sprintf('%0.2f',session[:maf_totals]['maf_total_lot_weight'])
     render :inline => %{
    <% @content_header_caption = "'MAF extracted pool graded bins data'"%>

    <%= build_maf_extracted_bins_form(@pool_graded_ps_summary,'confirm_submit_or_cancel_maf_bins','accept/cancel',@is_edit)%>

    }, :layout => 'content'
   else
     render :inline => %{
    <% @content_header_caption = "'MAF extracted pool graded bins data'"%>

    <%= build_maf_extracted_bins_form(@pool_graded_ps_summary,'refresh_pool_graded_ps_bins','refresh',@is_edit)%>

    }, :layout => 'content'
    end

  end

  def confirm_submit_or_cancel_maf_bins
    render :inline => %{
                       <script>
                         if(confirm("Are you sure you want to import bins from maf?") == true)
                            window.location = "/rmt_processing/presort_grower_grading/submit_maf_extracted_bins";
                         else
                            window.location = "/rmt_processing/presort_grower_grading/cancel_import_of_maf_bins";
                         end
                       </script>}
  end

  def cancel_import_of_maf_bins
    session[:maf_ps_bins]=nil
    session[:refresh_ps_bins] =nil
    session[:warning]=nil
    render :inline => %{<script>
                            alert('import cancelled');
                            window.close();
                      </script>}, :layout => "content"
  end

  def submit_maf_extracted_bins
    pool_graded_ps_summary=PoolGradedPsSummary.find(session[:active_doc]['ps_summary'])
    ActiveRecord::Base.transaction do
    begin
      session[:maf_ps_bins].each do |bin|
        pool_graded_ps_bin=PoolGradedPsBin.new(
            :pool_graded_ps_summary_id=>bin.pool_graded_ps_summary_id,
            :maf_farm_code=>bin.maf_farm_code,
            :maf_rmt_code=>bin.maf_rmt_code,
            :maf_article=>bin.maf_article,
            :maf_article_count=>bin.maf_article_count,
            :maf_weight=>bin.maf_weight,
            :maf_class=>bin.maf_class,
            :maf_colour=>bin.maf_colour,
            :maf_count=>bin.maf_count,
            :created_by=>bin.created_by)
        pool_graded_ps_bin.save
      end
    pool_graded_ps_summary.maf_tipped_lot_qty =  session[:maf_totals]['maf_tipped_lot_qty']
    pool_graded_ps_summary.maf_total_lot_weight=  sprintf('%0.2f',session[:maf_totals]['maf_total_lot_weight'])

      pool_graded_ps_summary.update
    rescue
     return $!
    end
    end
    session[:maf_totals] = nil
    session[:refresh_ps]=nil
    session[:maf_ps_bins]= nil
    session[:refresh_ps_bins] =nil
    render :inline => %{<script>
                            alert('import of maf bins successful');
                            window.close();
                      </script>}, :layout => "content"
  end

  def refresh_presort_grading
    if session[:active_doc]
      pool_graded_ps_summary =PoolGradedPsSummary.find(session[:active_doc]['ps_summary'])
      if pool_graded_ps_summary
      else
        redirect_to_index("no active ps lot")
      end
    else
      redirect_to_index("no active ps lot")
    end
    render :inline => %{
                       <script>
                         if(confirm("Refresh is going to recreate this ps summary and you have to import maf bins again ?") == true)
                            window.location = "/rmt_processing/presort_grower_grading/ok_cancel_refresh_ps_summary";
                         else
                            window.location = "/rmt_processing/presort_grower_grading/cancel_refresh_ps_summary";
                         end
                       </script>}
  end

  def  ok_cancel_refresh_ps_summary
        pool_graded_ps_summary =PoolGradedPsSummary.find(session[:active_doc]['ps_summary'])
        session[:refresh_ps] =true
        session[:active_doc]['ps_summary']= nil
        get_pool_graded_ps_summary_rec(pool_graded_ps_summary.maf_lot_number)
        create_presort_grading
  end

  def cancel_refresh_ps_summary
    flash[:message]="refresh cancelled"
    current_ps_lot
  end


  def uncomplete_pool_graded_summary
    return if authorise_for_web(program_name?,'edit')==false
    id = params[:id]
    if id && @pool_graded_summary = PoolGradedPsSummary.find(id)
      @pool_graded_summary.status = "STATUS_IN_PROGRESS"
      @pool_graded_summary.save!
      params[:id]=@pool_graded_summary.id
      flash[:notice] = 'PoolGraded Summary can now be modified'
      edit_pool_graded_ps_summary
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
      if id && pool_graded_summary = PoolGradedPsSummary.find(id)
        pool_graded_summary.destroy
        set_active_doc("ps_summary",nil)
        session[:alert] = " Record deleted."
        render_list_pool_graded_summaries
      end
    rescue
      handle_error('record could not be deleted')
    end
  end


  def find_presort_grading
    return if authorise_for_web(program_name?,'read')== false
    @is_flat_search = true
    session[:pool_graded_ps_summary]=[]
    render_pool_graded_summary_search_form
  end

  def render_pool_graded_summary_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
    #   render (inline) the search form
    render :inline => %{
    <% @content_header_caption = "'search pool_graded_ps_summaries'"%>

    <%= build_pool_graded_ps_summary_search_form(nil,'submit_pool_graded_summaries_search','submit_pool_graded_summaries_search',@is_flat_search)%>

    }, :layout => 'content'
  end


  def submit_pool_graded_summaries_search
    @pool_graded_summaries = dynamic_search(params[:pool_graded_summary] ,'pool_graded_ps_summaries','PoolGradedPsSummary')
    if @pool_graded_summaries.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_pool_graded_summary_search_form
    else
      render_list_pool_graded_summaries
    end
  end

  def render_list_pool_graded_summaries
    @pagination_server = "list_pool_graded_ps_summaries"
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

  def current_ps_lot
    if session[:active_doc]
      ps_lot =PoolGradedPsSummary.find(session[:active_doc]['ps_summary'])
      if ps_lot
        redirect_to :action => 'edit_pool_graded_ps_summary', :id => ps_lot.id
      else
        redirect_to_index("no active ps lot")
      end
    else
      redirect_to_index("no active ps lot")
    end


  end

  def create_presort_grading
    return if authorise_for_web(program_name?, 'create')== false
    render_get_ps_lot_number_form
  end

  def render_get_ps_lot_number_form
    if session[:refresh_ps]
      @content = "'ps summary deleted refresh to get another one'"
    else
      @content = "'create pool_graded_ps_summary'"
    end

    render :inline => %{
    <% @content_header_caption = "'find ps lot number'"%>

    <%= build_find_ps_lot_number_form(@ps_lot,'submit_lot_number','submit_lot_number',true)%>

    }, :layout => 'content'
  end

  def validate_ps_lot_number(ps_lot_number)
     return "Provide a valid lot number"  if ps_lot_number=="" || ps_lot_number == nil

     pool_graded_ps_summary = PoolGradedPsSummary.find_by_maf_lot_number(ps_lot_number)
     if pool_graded_ps_summary
       return "Pool Graded Ps Summary already exists for the PS LOT number"
     else
       return nil
     end

  end


  def submit_lot_number
    #session[:refresh_ps]=nil

    if error=validate_ps_lot_number( params[:ps_lot][:ps_lot_number])
      flash[:error]  = error
      render_get_ps_lot_number_form   and return
    end

    msg = get_pool_graded_ps_summary_rec( params[:ps_lot][:ps_lot_number])
    if msg
      redirect_to_index("cannot create ps_summary record without matching bins")   and return
    end
     if session[:refresh_ps] ==true
       create_presort_grower_grading_ps_summary  and return
     else
       redirect_to :action => 'edit_pool_graded_ps_summary'  and return
     end
    # Edit the summary...

  rescue
    handle_error('record could not be created')
  end

  def get_pool_graded_ps_summary_rec(ps_lot_number)
    pool_graded_ps_summary = PoolGradedPsSummary.create_from(ps_lot_number,session[:refresh_ps])
    if pool_graded_ps_summary.empty?
    msg = "no bins found with that lot number"
    else
      msg = nil
    end
      session[:pool_graded_ps_summary]= pool_graded_ps_summary
    return msg
  end


  def edit_pool_graded_ps_summary
    if session[:pool_graded_ps_summary].empty?
      @presort_grower_grading_ps_summary=PoolGradedPsSummary.find(params[:id])
      @is_edit=true
      set_active_doc("ps_summary",@presort_grower_grading_ps_summary.id)
    else
      @presort_grower_grading_ps_summary=session[:pool_graded_ps_summary][0]
      @is_edit=nil
    end
    render :inline => %{
    <% @content_header_caption = "'create presort grower grading'"%>

    <%= build_create_presort_grading_form(@presort_grower_grading_ps_summary,'ok_cancel_create_ps_summary','create_presort_grower_grading_ps_summary',@is_edit)%>

    }, :layout => 'content'
  end


  def ok_cancel_create_ps_summary
    render :inline => %{
                       <script>
                         if(confirm("Are you sure you want to create the ps summary and farms?") == true)
                            window.location = "/rmt_processing/presort_grower_grading/create_presort_grower_grading_ps_summary";
                         else
                            window.location = "/rmt_processing/presort_grower_grading/cancel_create_ps_summary";
                         end
                       </script>}
  end

  def cancel_create_ps_summary
    session[:maf_ps_bins]=nil
    session[:warning]=nil
    session[:pool_graded_ps_summary]=[]
    redirect_to_index("Create Ps Summary Cancelled")
  end

  def create_presort_grower_grading_ps_summary
    ActiveRecord::Base.transaction do

    @pool_graded_ps_summary=session[:pool_graded_ps_summary][0]
    @pool_graded_ps_summary.save

    pool_graded_ps_farms=session[:pool_graded_ps_summary][1]
    if !pool_graded_ps_farms.empty?
      pool_graded_ps_farms.each do |farm|
       farm.pool_graded_ps_summary_id = @pool_graded_ps_summary.id
       farm.save
      end
    end

    end
    session[:pool_graded_ps_summary]=[]
    session[:refresh_ps]=nil
    set_active_doc("ps_summary",@pool_graded_ps_summary.id)
    redirect_to :action => 'edit_pool_graded_ps_summary' ,:id => @pool_graded_ps_summary.id
  end


end