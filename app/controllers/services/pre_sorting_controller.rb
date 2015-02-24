class Services::PreSortingController < ApplicationController

  def bypass_generic_security?
    true
  end

  def get_palox_bin_presort_run(representative_bin)
    if (representative_bin['Numero_bon_apport'])
      PresortStagingRun.find_by_sql("select presort_staging_runs.*
                                     from presort_staging_runs
                                     join presort_staging_run_children on presort_staging_run_children.presort_staging_run_id=presort_staging_runs.id
                                     where presort_staging_run_children.id=#{representative_bin['Numero_bon_apport'].to_s.strip}")[0]
    else
      raise "Error:Presorted Bin:#{params[:bin]}: ViewpaloxKromco.Numero_bon_apport does not have a value"
    end
  end

  def get_aport_bin_full_rmt_product_code(nom_article, presort_run)
    if (nom_article == "Article 128")
      return "#{presort_run.rmt_variety.commodity_code}_#{presort_run.rmt_variety.rmt_variety_code}_ALL_ALL_#{presort_run.ripe_point.ripe_point_code}_128"
    else
      nom_article_components = nom_article.split('_')
      return "#{presort_run.rmt_variety.commodity_code}_#{presort_run.rmt_variety.rmt_variety_code}_#{nom_article_components[1]}_#{nom_article_components[0]}_#{presort_run.ripe_point.ripe_point_code}_#{nom_article_components[2]}"
    end
  end


  def bin_created_intergration
    #view-source:http://192.168.10.7:3000/services/pre_sorting/bin_created?bin=704
    begin

      raise "Bin:#{@created_bin} already exists in Kromco Mes db" if (Bin.find_by_bin_number(@created_bin))

      http = Net::HTTP.new(Globals.bin_created_mssql_server_host, Globals.bin_created_mssql_presort_server_port)
      request = Net::HTTP::Post.new("/select")
      parameters = {'method' => 'select', 'statement' => Base64.encode64("select * from ViewpaloxKromco where ViewpaloxKromco.Numero_palox=#{@created_bin}")}
      request.set_form_data(parameters)
      response = http.request(request)
      puts "---\n#{response.code} - #{response.message}\n---\n"

      if '200' == response.code
        res = response.body.split('resultset>').last.split('</res').first
        results = Marshal.load(Base64.decode64(res))
      else
        err = response.body.split('</message>').first.split('<message>').last
        errmsg = "SQL Integration returned an error running : select * from ViewpaloxKromco where ViewpaloxKromco.Numero_palox=#{@created_bin}. The http code is #{response.code}. Message: #{err}."
        logger.error ">>>> #{errmsg}"
        raise errmsg
        # return
      end

      if (results.empty?)
        raise "Presorted Bin:#{@created_bin} not found in View Palox"
        return
      end

      representative_bin = get_majority_weight_bin_farm(results)
      raise "multiple farms for bin[#{@created_bin}] with no matching Code_adherent_max. #{results.map { |bin| "record#{results.index(bin)+1}=(#{bin['Code_adherent']},#{bin['Code_adherent_max']})" }.join(',')}" if (!representative_bin)
      
      if (representative_bin['Palox_poids'].to_s == "")
        raise "Presorted Bin:#{@created_bin}:  Palox_poids is null"
        # return
      end

      
      palox_bin_presort_run=get_palox_bin_presort_run(representative_bin)
      aport_bin_rmt_product_code = get_aport_bin_full_rmt_product_code(representative_bin['Nom_article'], palox_bin_presort_run)
      if (!(rmt_product=RmtProduct.find_by_rmt_product_code(aport_bin_rmt_product_code)))
        raise "Error:Presorted Bin:#{@created_bin}:nom_article:#{representative_bin['Nom_article'].to_s.strip}:  rmt_product_code:'#{aport_bin_rmt_product_code}' does not exist"
      end

      if (!(farm = Farm.find_by_farm_code(representative_bin['Code_adherent_max'].to_s.strip)))
        raise "Error:Presorted Bin:#{@created_bin}: does not have a Code_adherent_max"
      end

      RAILS_DEFAULT_LOGGER.info ("POIDS representative_bin['Palox_poids']: " + representative_bin['Palox_poids'].to_s)


        if (representative_bin['Nom_article'].to_s == "Article 128" && representative_bin['Palox_poids']!="null")
          if (representative_bin['Palox_poids']==0.0)
            raise "Error:Presorted Bin:#{@created_bin}:nom_article:#{representative_bin['Nom_article'].to_s.strip}:Palox_poids:#{representative_bin['Palox_poids'].to_s.strip}' is zero"
          else
            pack_material_product = PackMaterialProduct.find_by_pack_material_product_code('KROMC')
          end
        else
          if (!(pack_material_product = PackMaterialProduct.find_by_pack_material_product_code(representative_bin['Code_article_caracteristique'])))
            raise "Error:Presorted Bin:#{@created_bin}:nom_article:#{representative_bin['Nom_article'].to_s.strip}: pack_material_product_code:'#{representative_bin['Code_article_caracteristique'].to_s.strip}' does not exist"
          end
        end


      if (results.length == 1)
        map_ps_lot_no_mix = representative_bin['Numero_lot']
      elsif (results.length > 1)
        mix_ps_bin = 'MIX_PS_BIN'
      end

      if palox_bin_presort_run.season.season.to_i == 2014
        orchard_code = representative_bin['Code_parcelle']
      else
        orchard_code = representative_bin['Code_parcelle'].split('_')[0]
      end

      ActiveRecord::Base.transaction do
        bin = Bin.new({:created_on => Time.now, :bin_number => representative_bin['Numero_palox'], :rmt_product_id => rmt_product.id, :farm_id => farm.id,
                       :orchard_code => orchard_code, :pack_material_product_id => pack_material_product.id,
                       :track_indicator1_id => palox_bin_presort_run.track_slms_indicator.id, :track_indicator2_id => representative_bin['Int_lot_libre1'], :season_code => palox_bin_presort_run.season.season_code,
                       :weight => representative_bin['Palox_poids'], :map_ps_lot_no_mix => map_ps_lot_no_mix, :mix_ps_bin => mix_ps_bin,
                       :code_cumul => representative_bin['Code_cumul'], :numero_lot_max => representative_bin['Numero_lot_max'],
                       :code_adherent_max => representative_bin['Code_adherent_max'], :coldstore_type => representative_bin['Code_frigo']
                      })

        bin.save!
        Inventory.create_stock(nil, "PRESORT", 'KROMCO', nil, "presort_bin_created", bin.bin_number, "PRESORT", [bin.bin_number.to_s])

        if (results.length > 1)
          bulk_insert = ""
          results.each do |ps_bin|
            if (!(ps_bin_farm = Farm.find_by_farm_code(ps_bin['Code_adherent'].to_s.strip)))
              raise "Error:Presorted Bin:#{@created_bin}: ps_mix_lot farm_code:'#{ps_bin['Code_adherent'].to_s.strip}' does not exist"
            end

            if (ps_bin['Poids'].to_s == "" || ps_bin['Poids'].to_s == "0.000")
              #bulk_insert += "INSERT INTO ps_mix_lots (bin_id,farm_id,ps_lot_no,ps_run_id,weight) VALUES(#{bin.id},#{ps_bin_farm.id},'#{ps_bin['Numero_lot']}',null,0);\n"
            else
              bulk_insert += "INSERT INTO ps_mix_lots (bin_id,farm_id,ps_lot_no,ps_run_id,weight) VALUES(#{bin.id},#{ps_bin_farm.id},'#{ps_bin['Numero_lot']}',null,#{ps_bin['Poids']});\n"
            end
          end
          created=ActiveRecord::Base.connection.execute(bulk_insert)
        end
  
	#NAE
	results.each do |ps_bin|
		ps_rw_insert = ""
		if ps_bin['Commentaire'].to_s.strip!=ps_bin['Numero_bon_apport'].to_s.strip then			
			ps_rw_lot=ActiveRecord::Base.connection.select_all("select * from ps_rework_lots where ps_lot_no = '#{ps_bin['Numero_lot']}'")
			if ps_rw_lot.empty?
				ps_rw_insert= "INSERT INTO public.ps_rework_lots (ps_lot_no) VALUES ('#{ps_bin['Numero_lot']}');\n"
				created=ActiveRecord::Base.connection.execute(ps_rw_insert)	      
			end
		end
	end
	#NAE
  
      end
      return nil
    rescue
      return $!.message
    end
  end

  def clear_bin_presort_integration_retries(bin_number,event_type)
    if(presort_integration_retry=PresortIntegrationRetry.find_by_bin_number_and_event_type(bin_number.strip,event_type.strip))
      presort_integration_retry_history = PresortIntegrationRetryHistory.new({:event_type=>presort_integration_retry.event_type,:process_attempts=>presort_integration_retry.process_attempts,:bin_number=>presort_integration_retry.bin_number,:error=>presort_integration_retry.error})
      presort_integration_retry_history.save!
      presort_integration_retry.destroy
    end
  end

  def bin_created
    @created_bin = params[:bin]
    if (error = bin_created_intergration)
      if(error.strip == "Bin:#{@created_bin} already exists in Kromco Mes db" )
        clear_bin_presort_integration_retries(@created_bin,'bin_created')
        render_result("<error msg=\"#{error}\" />")
      else
        render_result(handle_error(error))
      end
    else
      render_result("<bins><bin result_status=\"OK\" msg=\"created bin #{@created_bin}\" /></bins>")
    end
  end

  def bin_tipped_intergration
    #view-source:http://192.168.10.7:3000/services/pre_sorting/bin_tipped?bin=704
    begin
      raise "Bin:#{@tipped_bin} not found in Kromco Mes db" if (!(kromco_bin = Bin.find_by_bin_number(@tipped_bin)))
      raise "Bin:#{@tipped_bin} already tipped" if (kromco_bin.tipped_date_time)

      http = Net::HTTP.new(Globals.bin_tipped_mssql_server_host, Globals.bin_tipped_mssql_integration_server_port)
      request = Net::HTTP::Post.new("/select")
      parameters = {'method' => 'select', 'statement' => Base64.encode64("select Apport.* from Apport where Apport.NumPalox='#{@tipped_bin}'")}
      request.set_form_data(parameters)
      response = http.request(request)

      if '200' == response.code
        res = response.body.split('resultset>').last.split('</res').first
        results = Marshal.load(Base64.decode64(res))
      else
        err = response.body.split('</message>').first.split('<message>').last
        errmsg = "SQL Integration returned an error running: select Apport.* from Apport where Apport.NumPalox='#{@tipped_bin}'. The http code is #{response.code}. Message: #{err}."
        logger.error ">>>> #{errmsg}"
        raise errmsg
        return
      end

      if (results.empty?)
        raise "Tipped Presorted Bin:#{@tipped_bin} not found in Apport db"
        #elsif(results.is_a?(String))
        #  raise "#{response.code} - #{response.message}"
      end

      tipped_apport_bin = results[0]
      ActiveRecord::Base.transaction do
        if ((num_rows_updated = Bin.update_all(ActiveRecord::Base.extend_set_sql_with_request("tipped_date_time='#{Time.now.to_formatted_s(:db)}',exit_reference_date_time='#{Time.now.to_formatted_s(:db)}',exit_ref='PRESORT_BIN_TIPPED',ps_tipped_lot_no='#{tipped_apport_bin['LotMAF']}'", "bins"), "bin_number = '#{@tipped_bin}'")) == 0)
          raise "Error Tipped Presorted Bin:#{@tipped_bin}: could not be tipped"
        end

        Inventory.remove_stock(nil, 'BIN', 'PRESORT_BIN_TIPPED', @tipped_bin, "PRESORT", [@tipped_bin], 'KROMCO')
	
      end
      return nil
    rescue
      return $!.message
    end
  end

  def bin_tipped
    @tipped_bin = params[:bin]
    if (error = bin_tipped_intergration)
      if(error.strip == "Bin:#{@tipped_bin} already tipped" )
        clear_bin_presort_integration_retries(@tipped_bin,'bin_tipped')
        render_result("<error msg=\"#{error}\" />")
      else
        render_result(handle_error(error))
      end
    else
      render_result("<bins><bin result_status=\"OK\" msg=\"tipped bin #{@tipped_bin}\" /></bins>")
    end
  end

  def get_active_run_details
    begin
      #view-source:http://192.168.10.7:3000/services/pre_sorting/get_active_run_details
      render_result(get_active_run_info)
    rescue
      render_result(handle_error($!.message))
    end
  end

  def bins_scanned
    begin
      #view-source:http://192.168.10.7:3000/services/pre_sorting/bins_scanned?bin1=776548&bin2=783875&bin3=771442
      render_result(bins_scanned_internal(params[:bin1], params[:bin2], params[:bin3]))
    rescue
      render_result(handle_error($!.message))
    end
  end

  def override_provided
    begin
      #"GET /services/pre_sorting/override_provided?&answer=no&bin1= HTTP/1.1" 200 172
      #- -> /services/pre_sorting/override_provided?&answer=no&bin1=

      #view-source:http://192.168.10.7:3000/services/pre_sorting/override_provided?bin1=776548&bin2=783875&bin3=771442&answer=yes&user=morne
      if (params[:answer]=='yes')
        override_answer = true
        render_result(bins_scanned_internal(params[:bin1], params[:bin2], params[:bin3], override_answer))
      else
        bin_results = [{:bin_num => params[:bin1], :bin_item => 1, :status => 'OVERRIDE_CANCELLED', :msg => 'bin override has been cancelled '}]
        bin_results << {:bin_num => params[:bin2], :bin_item => 2, :status => 'OVERRIDE_CANCELLED', :msg => 'bin override has been cancelled '} if (params[:bin2])
        bin_results << {:bin_num => params[:bin3], :bin_item => 3, :status => 'OVERRIDE_CANCELLED', :msg => 'bin override has been cancelled '} if (params[:bin3])
        return render_result(gen_bins_scanned_xml(bin_results))
      end

    rescue
      render_result(handle_error($!.message))
    end
  end

  def get_majority_weight_bin_farm(bin_farms)
    if (bin_farms.length > 1)
      return bin_farms.find_all { |bin| bin['Code_adherent_max'] == bin['Code_adherent'] }.sort { |x, y| y['Poids'] <=> x['Poids'] }[0]
    end
    return bin_farms[0]
  end

  def handle_error(error, is_tree = nil, is_tree_content = nil, error_type = 'presort', render_error_view=false)
    @err_entry = super(error, is_tree, is_tree_content, error_type, render_error_view)
    if(params[:action]=="bin_created" or params[:action]=="bin_tipped")
      if(presort_integration_retry=PresortIntegrationRetry.find_by_bin_number_and_event_type(params[:bin].strip,params[:action].strip))
        presort_integration_retry.process_attempts=presort_integration_retry.process_attempts+1
        presort_integration_retry.error=error
        presort_integration_retry.update
      else
        presort_integration_retry= PresortIntegrationRetry.new({:event_type=>params[:action].strip,:bin_number=>params[:bin].strip,:error=>error})
        presort_integration_retry.create
      end
    end
    return "<error msg=\"#{error}\" />"
    #return "<error msg=\"Error Occured: Contact IT\" />"
  end

  def create_presort_log(result)
    ip = request.remote_ip if(request)
    user = session[:user_id].user_name if(session[:user_id])
    input_params = "#{params.find_all { |key, val| (key!='controller' && key!='action') }.map { |k, v| "#{k}=#{v}" }.join(",")}"
    presort_log = PresortLog.new({:action => params[:action], :input_params => input_params, :output_xml => result, :rails_error_id => (@err_entry ? @err_entry.id : nil),:user_ip=>ip,:user=>user})
    presort_log.save
  end

  def validate_active_run
    active_pre_sort_stagin_runs=PresortStagingRun.find(:all, :conditions => "status='ACTIVE' or status='active'")
    return "no active pre_sort run could be found" if (active_pre_sort_stagin_runs.empty?)
    return "more than one pre_sort run found" if (active_pre_sort_stagin_runs.length > 1)
    @active_pre_sort_stagin_run = active_pre_sort_stagin_runs[0]
    active_pre_sort_stagin_run_children=PresortStagingRunChild.find(:all, :conditions => "presort_staging_run_id=#{@active_pre_sort_stagin_run.id} and (status='ACTIVE' or status='active')")
    return "no active pre_sort child run could be found" if (active_pre_sort_stagin_run_children.empty?)
    return "more than one pre_sort child run found" if (active_pre_sort_stagin_run_children.length > 1)
    @active_pre_sort_stagin_run_child = active_pre_sort_stagin_run_children[0]
    return nil
  end

  def get_active_run_info

    #if(error=validate_active_run)
    #  return handle_error(error)
    #end

    #return handle_error("No bins available at any location") if((available_bins_farms=PresortStagingRun.get_available_locations(@active_pre_sort_stagin_run.season_id,@active_pre_sort_stagin_run.rmt_variety_id,@active_pre_sort_stagin_run.track_slms_indicator_id,@active_pre_sort_stagin_run.farm_group_id,@active_pre_sort_stagin_run.ripe_point_id)).empty?)

    #available_bins_locations = available_bins_farms[0].group_by {|a| a['location_code'] }
    #result = "\n\t<run_info run_code=\"#{@active_pre_sort_stagin_run.id}\" season=\"#{@active_pre_sort_stagin_run.season.season_code}\" variety=\"#{@active_pre_sort_stagin_run.rmt_variety.rmt_variety_code}\" slms_indicator=\"#{@active_pre_sort_stagin_run.track_slms_indicator.track_slms_indicator_code}\" run_name=\"#{@active_pre_sort_stagin_run.presort_run_code}\" n_bins_staged=\"#{@active_pre_sort_stagin_run.bins.length}\" farm=\"#{@active_pre_sort_stagin_run_child.farm.farm_code}\" />"
    #result += "\n\t<locations>"
    #available_bins_locations.each do |locn_code,locn_farms|
    #  result += "\n\t\t<location name=\"#{locn_code}\" qty_available=\"#{locn_farms.map{|grp| grp['qty_bins_available'].to_i}.inject{|sum,x| sum + x }}\" bin_age = \"#{locn_farms[0]['age']}\"/>"
    #end
    #result += "\n\t</locations>\n"
    #return result

    "<run_info />"
  end

  def forced_staging
    render :inline => %{
     		<% @content_header_caption = "'enter bin numbers to to be staged'"%>

     		<%= build_forced_staging_form("forced_staging_submit","stage")%>

     		}, :layout => 'content'
  end

  def forced_staging_submit
    session[:current_force_stage_bin_number] = params['staging']['bin1']
    @bin1 = Bin.find_by_bin_number(params['staging']['bin1'])
    session[:current_force_stage_bin_farm] = @bin1.farm_id
    bin_track_slms_indicator=TrackSlmsIndicator.find(@bin1.track_indicator1_id)

    @presort_staging_runs = PresortStagingRun.find_by_sql("
      select p.presort_run_code ,pc.product_class_code ,tm.treatment_code,sizes.size_code,ripe_points.ripe_point_code,p.id ,t.track_slms_indicator_code,r.rmt_variety_code,s.season_code
      ,p.status ,p.created_on ,p.completed_on ,p.created_by ,f.farm_group_code
      from presort_staging_runs p
      inner join presort_staging_run_children rc on rc.presort_staging_run_id=p.id
      inner join farms fm on fm.id=rc.farm_id
      inner join seasons s on p.season_id=s.id
      inner join farm_groups f on p.farm_group_id=f.id
      inner join rmt_varieties r on p.rmt_variety_id=r.id
      inner join track_slms_indicators t on p.track_slms_indicator_id=t.id
      inner join ripe_points on p.ripe_point_id=ripe_points.id
      left  join  product_classes pc on p.product_class_id=pc.id
      left  join  treatments tm on p.treatment_id=tm.id
      left  join sizes on p.size_id=sizes.id
      where fm.id='#{@bin1.farm_id}' and s.season_code='#{@bin1.season_code}' and f.id=#{@bin1.farm.farm_group.id} and r.id=#{@bin1.rmt_product.variety.rmt_variety.id}
      and t.id=#{bin_track_slms_indicator.id}
      and ripe_points.id=#{@bin1.rmt_product.ripe_point.id}
      group by pc.product_class_code ,tm.treatment_code,sizes.size_code,ripe_points.ripe_point_code,p.id ,t.track_slms_indicator_code,r.rmt_variety_code,s.season_code
      ,p.presort_run_code ,p.status ,p.created_on ,p.completed_on ,p.created_by ,f.farm_group_code
      order by p.id desc
    ")

    render :inline => %{
      <% grid = build_presort_staging_run_grid(@presort_staging_runs,@can_edit,@can_delete)%>
      <% @content_header_caption = "'select a run to stage bin:  #{@bin1.bin_number}'"%>
      <% grid.caption = 'select a run to stage this bin: #{session[:current_force_stage_bin_number]}'%>
      <% @header_content = grid.build_grid_data %>
      <% @pagination = pagination_links(@presort_staging_run_pages) if @presort_staging_run_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    },:layout => 'content'
  end

  def select_presort_staging_run
    @presort_staging_run_children = PresortStagingRunChild.find(:all,
                                                                :conditions=>"presort_staging_run_id=#{params[:id]} and (farms.id=#{session[:current_force_stage_bin_farm]} or farms.farm_code='0P')",
                                                                :select => "presort_staging_run_children.*,farms.farm_code",
                                                                :joins => "inner join farms on presort_staging_run_children.farm_id=farms.id")
    render :inline => %{
      <% grid = build_presort_staging_run_child_grid(@presort_staging_run_children)%>
      <% grid.caption = 'select a run child to stage bin: #{session[:current_force_stage_bin_number] }'%>
      <%grid.height='200'%>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@presort_staging_run_child_pages) if @presort_staging_run_child_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    },:layout => 'content'
  end

  def force_stage_bin
    pre_sort_staging_run_child=PresortStagingRunChild.find(params[:id])

    bins_validation_results =  get_stage_bins_results(pre_sort_staging_run_child.presort_staging_run,pre_sort_staging_run_child,session[:current_force_stage_bin_number], nil, nil,nil)

    if(bins_validation_results[0][:status] == "OK")
      flash[:notice] = "bin[#{session[:current_force_stage_bin_number] }] has been successfully staged against run[#{pre_sort_staging_run_child.presort_staging_run_child_code}]"
      params.delete(:id)
      params[:bin1] = session[:current_force_stage_bin_number]
      create_presort_log(gen_bins_scanned_xml(bins_validation_results))
    else
      flash[:error] = bins_validation_results[0][:msg]
    end
    # return render_result(gen_bins_scanned_xml(bins_validation_results))
    forced_staging
  end

  def bins_scanned_internal(bin1, bin2 = nil, bin3 = nil, overridden = nil)

    if (error=validate_active_run)
      return handle_error(error)
    end

    active_pre_sort_stagin_run=PresortStagingRun.find(:first, :conditions => "status='ACTIVE' or status='active'")
    active_pre_sort_stagin_run_child=PresortStagingRunChild.find(:first, :conditions => "presort_staging_run_id=#{@active_pre_sort_stagin_run.id} and (status='ACTIVE' or status='active')")

    bins_validation_results =  get_stage_bins_results(active_pre_sort_stagin_run,active_pre_sort_stagin_run_child,bin1, bin2, bin3,overridden)

    return gen_bins_scanned_xml(bins_validation_results)
  end

  def get_stage_bins_results(active_pre_sort_stagin_run,active_pre_sort_stagin_run_child,bin1, bin2, bin3,overridden)
    bin_nums = [bin1, bin2, bin3].compact
    bins_validation_results = validate_bins(bin_nums, active_pre_sort_stagin_run, active_pre_sort_stagin_run_child, overridden)
    bin_statuses = bins_validation_results.group_by { |a| a[:status] }.keys.uniq.sort

    #second condition becomes obsolete i.e. there will never be ['OK', 'OVERRIDDEN'] combination
    if ((bin_statuses.length==1 && (['OK', 'OVERRIDDEN'].include?(bin_statuses[0]))))# || (bin_statuses == ['OK', 'OVERRIDDEN'].sort))
      stage_bins(bin1, bin2, bin3, active_pre_sort_stagin_run_child, bins_validation_results)
    elsif (bin_statuses == ['OK', 'REQ_OVERRIDE'].sort)
      bins_validation_results.each do  |res_bin|
        if(res_bin[:status] == 'REQ_OVERRIDE')
          res_bin[:status] = 'FAILED'
          res_bin.store(:errs,[res_bin[:msg].sub('Start new run?', "Cannot override").to_s])
        elsif(res_bin[:status] == 'OK')
          res_bin[:status] = 'FAILED'
          res_bin.store(:errs, ["bin OK, but other bins do not have the same farm as the child_run"])
        end
      end
      log_bin_staging_errors(bins_validation_results.group_by { |a| a[:status] }['FAILED'], active_pre_sort_stagin_run_child.id)
    elsif (!bin_statuses.include?('FAILED') && bin_statuses.include?('REQ_OVERRIDE'))
      if (((overridden_bins=bins_validation_results.group_by { |a| a[:status] }['REQ_OVERRIDE'])) && overridden_bins.length > 1)
        or_clause = " bins.bin_number='#{overridden_bins.map { |b| b[:bin_num] }.join("' or bins.bin_number='")}' "
        if (Bin.find_by_sql("select distinct farms.farm_code from bins join farms on farms.id=bins.farm_id where #{or_clause}").length > 1)
          overridden_bins.map! { |ovrd_bin|
            ovrd_bin[:status] = 'FAILED'
            ovrd_bin[:errs] = ["bins farm not same as run's farm(for more than one bin- with different farms)"]
          }
          log_bin_staging_errors(bins_validation_results.group_by { |a| a[:status] }['FAILED'], active_pre_sort_stagin_run_child.id)
        end
      end
    else
      log_bin_staging_errors(bins_validation_results.group_by { |a| a[:status] }['FAILED'], active_pre_sort_stagin_run_child.id)
    end

    return bins_validation_results
  end

  def log_bin_staging_errors(bins_validation_results, active_pre_sort_stagin_run_child_id)
    err_entry = BinStagingError.new
    err_entry.presort_child_run_id = active_pre_sort_stagin_run_child_id
    err_entry.bin1 = (bin1=bins_validation_results.find { |b| b[:bin_item]==1 }) ? bin1[:bin_num] : nil
    err_entry.bin2 = (bin2=bins_validation_results.find { |b| b[:bin_item]==2 }) ? bin2[:bin_num] : nil
    err_entry.bin3 = (bin3=bins_validation_results.find { |b| b[:bin_item]==3 }) ? bin3[:bin_num] : nil
    err_entry.bin1_error = bin1 ? bin1[:errs].join("\n") : nil
    err_entry.bin2_error = bin2 ? bin2[:errs].join("\n") : nil
    err_entry.bin3_error = bin3 ? bin3[:errs].join("\n") : nil
    err_entry.create
  end

  def get_bin_attributes(results)
    attrs = {}
    if (results[:status]=='FAILED')
      attrs[:result_status] = 'ERR'
      attrs[:msg] = results[:errs].join("\n")
    else
      attrs[:result_status] = results[:status]
      attrs[:msg] = results[:msg] if (results[:msg])
    end
    return attrs
  end

  def gen_bins_scanned_xml(bin_results)

    if (error=validate_active_run)
      return handle_error(error)
    end

    #result_xml = get_active_run_info

    result_xml = ""
    result_xml += "\n\t<bins>"
    bin_results.each do |results|
      attrs = get_bin_attributes(results).map { |key, value| key.to_s + "=\"" + value.to_s + "\" " }.to_s
      result_xml += "\n\t\t<bin#{results[:bin_item]} #{attrs}/>"
    end
    result_xml += "\n\t</bins>\n"
  end

  def stage_bins(bin1, bin2, bin3, presort_staging_child_run, validation_results = nil)
    ActiveRecord::Base.transaction do
      stage_overriden_bins(presort_staging_child_run, validation_results)
      stage_ok_bins(presort_staging_child_run, validation_results)

      Inventory.move_stock('PRESORT_STAGING', presort_staging_child_run.presort_staging_run.presort_run_code, 'PRESORT_STAGING', [bin1, bin2, bin3].compact)
      create_apport_bins([bin1, bin2, bin3].compact,presort_staging_child_run)
    end
  end

  def stage_ok_bins(presort_staging_child_run, validation_results)
    if (validation_results.group_by { |a| a[:status] }.keys.include?('OK'))
      or_clause = " bins.bin_number='#{validation_results.group_by { |a| a[:status] }['OK'].map { |bn| bn[:bin_num] }.join("' or bins.bin_number='")}' "
      Bin.update_all(ActiveRecord::Base.extend_set_sql_with_request("presort_staging_run_child_id = #{presort_staging_child_run.id},presort_staging_run_id = #{presort_staging_child_run.presort_staging_run.id}", "bins"), or_clause)
    end
  end

  def stage_overriden_bins(presort_staging_child_run, validation_results)
    if (validation_results && ((overridden_bins=validation_results.group_by { |a| a[:status] }).keys.include?('OVERRIDDEN')))
      bin = Bin.find_by_bin_number(overridden_bins['OVERRIDDEN'][0][:bin_num])
      PresortStagingRun.new_activated_child(bin.farm.farm_code, 'system')

      new_presort_staging_child_run=PresortStagingRunChild.find(:all, :conditions => "presort_staging_run_id=#{presort_staging_child_run.presort_staging_run_id} and (status='ACTIVE' or status='active')")[0]
      pre_sort_staging_run_overrides = PresortStagingRunOverride.new({:old_staging_child_run_id => presort_staging_child_run.id, :new_staging_child_run_id => new_presort_staging_child_run.id, :new_farm_code => bin.farm.farm_code,
                                                                      :override_bin1_num => (bin1=overridden_bins['OVERRIDDEN'].find { |b| b[:bin_item]==1 }) ? bin1[:bin_num] : nil,
                                                                      :override_bin2_num => (bin2=overridden_bins['OVERRIDDEN'].find { |b| b[:bin_item]==2 }) ? bin2[:bin_num] : nil,
                                                                      :override_bin3_num => (bin3=overridden_bins['OVERRIDDEN'].find { |b| b[:bin_item]==3 }) ? bin3[:bin_num] : nil,
                                                                      :created_at => Time.now, :created_by => 'system'})
      pre_sort_staging_run_overrides.save!

      overridden_or_clause = " bins.bin_number='#{overridden_bins['OVERRIDDEN'].map { |bn| bn[:bin_num] }.join("' or bins.bin_number='")}' "
      Bin.update_all(ActiveRecord::Base.extend_set_sql_with_request("presort_staging_run_child_id = #{new_presort_staging_child_run.id},presort_staging_run_id = #{new_presort_staging_child_run.presort_staging_run.id}", "bins"), overridden_or_clause)
      overridden_bins['OVERRIDDEN'].map! { |ovrd_bin|
        ovrd_bin[:msg] = nil
      }
    end
  end

  def create_apport_bins(bins,presort_staging_child_run)
    apport_bins_or_clause = " bins.bin_number='#{bins.join("' or bins.bin_number='")}' "
    insert_ql = ""
    Bin.find(:all, :conditions => apport_bins_or_clause).each do |apport_bin|
      track_indicator_rec = TrackSlmsIndicator.find(apport_bin.track_indicator1_id)
      season = Season.find_by_season_code(apport_bin.season_code)

      RAILS_DEFAULT_LOGGER.info ("Time.now.to_formatted_s(:db): " + Time.now.to_formatted_s(:db))

      if(presort_staging_child_run.farm.farm_code.to_s.upcase=='0P')
        code_apporteur = "0P"
        code_parcelle = "0P"
        nom_parcelle = "0P"
      else
        code_apporteur = "#{apport_bin.farm.farm_code}"
        if season.season.to_i == 2014
          nom_parcelle = "#{apport_bin.farm.farm_code}_#{track_indicator_rec.track_slms_indicator_code}"
          code_parcelle = "#{apport_bin.farm.farm_code}_#{track_indicator_rec.track_slms_indicator_code}"
        else
          nom_parcelle = "#{apport_bin.orchard_code}_#{apport_bin.farm.farm_code}_#{track_indicator_rec.track_slms_indicator_code}"
          code_parcelle = "#{apport_bin.orchard_code}_#{apport_bin.farm.farm_code}_#{track_indicator_rec.track_slms_indicator_code}"
        end
      end

      insert_ql = insert_ql.to_s + "INSERT INTO Apport (NumPalox,DateApport,CodeParcelle,CodeVariete,
        CodeApporteur,CodeEmballage,Nombre,Poids,
        NumApport,TypeTraitement,NomParcelle,NomVariete,
        NomApporteur,CodeEspece,NomEspece,
        Partie,Year,Free_int1,Free_int2,Free_string1,
        Free_string2,Free_string3)
        VALUES('#{apport_bin.bin_number}',getdate(),'#{code_parcelle}','#{track_indicator_rec.track_slms_indicator_code}'
        ,'#{code_apporteur}','#{apport_bin.pack_material_product.pack_material_product_code}','#{apport_bin.id}','#{apport_bin.weight}'
        ,'#{apport_bin.presort_staging_run_child_id}','#{apport_bin.rmt_product.treatment_code}','#{nom_parcelle}','#{track_indicator_rec.track_slms_indicator_description}'
        ,'#{apport_bin.farm.farm_description}','#{apport_bin.rmt_product.variety.rmt_variety.commodity.commodity_code}','#{apport_bin.rmt_product.variety.rmt_variety.commodity.commodity_description_long}'
        ,'#{apport_bin.production_run_rebin_id}','#{season.season}','#{apport_bin.track_indicator2_id}','#{season.season}','#{apport_bin.rmt_product.variety.rmt_variety.rmt_variety_code}'
        ,'#{apport_bin.farm.farm_group_id}','#{apport_bin.rmt_product_id}');\n"
    end

    RAILS_DEFAULT_LOGGER.info ("insert_ql.to_s: " + insert_ql.to_s)

    #puts insert_ql
    if (!insert_ql.strip.empty?)
      http = Net::HTTP.new(Globals.bin_scanned_mssql_server_host, Globals.bin_scanned_mssql_integration_server_port)
      request = Net::HTTP::Post.new("/exec")
      parameters = {'method' => 'insert', 'statement' => Base64.encode64(insert_ql)}
      request.set_form_data(parameters)
      response = http.request(request)

      if '200' == response.code
        res = response.body.split('resultset>').last.split('</res').first
        results = Marshal.load(Base64.decode64(res))
      else
        err = response.body.split('</message>').first.split('<message>').last
        errmsg = "SQL Integration returned an error running : INSERT INTO Apport. The http code is #{response.code}. Message: #{err}."
        logger.error ">>>> #{errmsg}"
        raise errmsg
        return
      end

      #raise "#{response.code} - #{response.message}" if(results.is_a?(String) && results.upcase.include?('ERROR'))
    end
  end

  def validate_bins(bin_nums, staging_run, staging_child_run, overridden = nil)
    bins_results = []
    bin_nums.each do |bin_num|
      bin_results = {:bin_num => bin_num, :bin_item => bin_nums.index(bin_num)+1}
      if ((errs = valid_bin?(bin_num, staging_run)).empty?)
        bin = Bin.find_by_bin_number(bin_num)
        if (bin.farm.farm_code == staging_child_run.farm.farm_code || staging_child_run.farm.farm_code.to_s.upcase=='0P')
          bin_results[:status] = 'OK'
        elsif (bin.farm.farm_group_code == staging_run.farm_group.farm_group_code)
          if (!overridden)
            bin_results[:status] = 'REQ_OVERRIDE'
          else
            bin_results[:status] = 'OVERRIDDEN'
          end
          bin_results[:msg] = "bin belongs to farm [#{bin.farm.farm_code}], but child_run's farm is [#{staging_child_run.farm.farm_code}]. Start new run?"
        else
          bin_results[:errs] = ["bin's farm[#{bin.farm.farm_code}] is not part of parent's farm group[#{staging_run.farm_group.farm_group_code}]"]
          bin_results[:status] = 'FAILED'
        end
      else
        bin_results[:errs] = errs
        bin_results[:status] = 'FAILED'
      end

      bins_results.push(bin_results)
    end

    return bins_results
  end

  def bin_exists?(bin_num)
    if (Bin.find_by_bin_number(bin_num))
      return true
    end
  end

  def bin_tipped?(bin)
    return bin.tipped_date_time
  end

  def bin_already_staged?(bin)
    return bin.presort_staging_run_child_id != nil
  end

  def bin_from_RA7?(bin_num)
    if ((stock_item=StockItem.find_by_sql(" select stock_items.location_code from stock_items where inventory_reference='#{bin_num}' and (stock_type_code='BIN' or stock_type_code='bin')")[0]))
      return stock_item.location_code.include?('RA7')
    end
  end

  def bin_under_quarentine?(bin)
    treatement_code = bin.rmt_product.treatment.treatment_code
    return (treatement_code.include? 'QFA' or treatement_code.include? 'QFS')
  end

  def bin_mrl_failed?(bin)
    spray_program_results = SprayProgramResult.find_by_sql("select spray_program_results.*,grower_commitments.id as grower_commitment_id
    from spray_program_results
    join grower_commitments on grower_commitments.id=spray_program_results.grower_commitment_id
    join seasons on seasons.season=grower_commitments.season
    where grower_commitments.farm_id='#{bin.farm_id}' and seasons.season_code='#{bin.season_code}'
    and spray_program_results.rmt_variety_code='#{bin.rmt_product.variety.rmt_variety_code}' order by spray_program_results.id desc limit 1")

    if (spray_program_results.map { |spr| spr.grower_commitment_id }.uniq.length > 1)
      raise "there is more than one grower_commitment for farm:#{bin.farm.farm_code} and season:#{bin.season_code}"
    end

    spray_program_results.each do |spray_program_result|
      if (spray_program_result && spray_program_result.spray_result.to_s.upcase == 'PASSED')
        return true if (spray_program_result.mrl_results.map { |mrl| mrl.mrl_result.to_s.upcase }.find_all { |r| r !='PASSED' && r !='PENDING' }.length > 0)
      else
        return true
      end
    end

    return false
  end

  def bin_in_reworks?(bin_num)
    return true if (RwActiveBin.find_by_bin_number(bin_num))
  end

  def bin_on_bin_sale(bin)
    return bin.bin_order_load_detail_id != nil
  end

  def bin_no_longer_in_stock?(bin)
    return bin.exit_ref != nil
  end

  def valid_bin_for_run?(bin_num, staging_run)

    treatment_filter = staging_run.treatment_id ? " and rmt_products.treatment_id=#{staging_run.treatment_id}" : " and (true)"
    product_class_filter = staging_run.product_class_id  ? " and rmt_products.product_class_id=#{staging_run.product_class_id}" : " and (true)"
    size_filter = staging_run.size_id ? " and rmt_products.size_id=#{staging_run.size_id}" : " and (true)"

    bins_found = ActiveRecord::Base.connection.select_one("
    select count(bins.bin_number)
    from bins
    inner join stock_items on stock_items.inventory_reference=bins.bin_number
    inner join locations on stock_items.location_id=locations.id
    inner join rmt_products on bins.rmt_product_id=rmt_products.id
    inner join varieties on  rmt_products.variety_id=varieties.id
    inner join rmt_varieties on varieties.rmt_variety_id=rmt_varieties.id
    inner join commodities on rmt_varieties.commodity_id=commodities.id
    inner join track_slms_indicators  ON bins.track_indicator1_id = track_slms_indicators.id
    inner join seasons on bins.season_code=seasons.season_code
    inner join farms on bins.farm_id=farms.id
    inner join farm_groups on farms.farm_group_id=farm_groups.id
    inner join ripe_points on  rmt_products.ripe_point_id=ripe_points.id
    inner join stock_types on stock_items.stock_type_id=stock_types.id
    where      ( locations.location_code LIKE 'RA_6%'  OR  locations.location_code LIKE 'RA_7%' OR locations.location_code LIKE 'PRESORT%')  AND bins.bin_number='#{bin_num}' and
    seasons.id=#{staging_run.season_id} and farm_groups.id =#{staging_run.farm_group_id} and rmt_varieties.id=#{staging_run.rmt_variety_id} and track_slms_indicators.id=#{staging_run.track_slms_indicator_id}
    and ripe_points.id=#{staging_run.ripe_point_id}
    #{treatment_filter} #{product_class_filter} #{size_filter}
    ")['count'].to_i
    return true if (bins_found > 0)
    return false
  end

  def valid_bin?(bin_num, staging_run)
    if (!bin_exists?(bin_num))
      return ["bin does not exist"]
    end

    bin = Bin.find_by_bin_number(bin_num)
    errs = []
    if (bin_tipped?(bin))
      errs << "bin has already been tipped"
    end

    #if bin_already_staged?(bin)
    #  errs << "bin is already staged"
    #end

    if bin_from_RA7?(bin_num)
      errs << "bin is from RA7"
    end

    if bin_under_quarentine?(bin)
      errs << "bin is quarantined"
    end

    if bin_mrl_failed?(bin)
      errs << "mrl results for bin is 'failed'"
    end

    if bin_in_reworks?(bin_num)
      errs << "bin is in reworks"
    end

    if bin_on_bin_sale(bin)
      errs << "bin is on a bin-sale"
    end

    if bin_no_longer_in_stock?(bin)
      errs << "bin is no longer in stock"
    end

    if !valid_bin_for_run?(bin_num, staging_run)
      if (bin.season_code != staging_run.season.season_code)
        errs << "bin season_code[#{bin.season_code}] does not match that of the active staging_run season_code[#{staging_run.season.season_code}]"
      end

      if (bin.rmt_product.variety.rmt_variety != staging_run.rmt_variety)
        errs << "bin rmt_variety_code[#{bin.rmt_product.variety.rmt_variety.rmt_variety_code}] does not match that of the active staging_run rmt_variety_code[#{staging_run.rmt_variety.rmt_variety_code}]"
      end

      if ((bin_track_slms_indicator=TrackSlmsIndicator.find(bin.track_indicator1_id)) != staging_run.track_slms_indicator)
        errs << "bin track_slms_indicator_code[#{bin_track_slms_indicator.track_slms_indicator_code}] does not match that of the active staging_run track_slms_indicator_code[#{staging_run.track_slms_indicator.track_slms_indicator_code}]"
      end

      if (bin.farm.farm_group != staging_run.farm_group)
        errs << "bin farm_group_code[#{bin.farm.farm_group.farm_group_code}] does not match that of the active staging_run farm_group_code[#{staging_run.farm_group.farm_group_code}]"
      end

      if (bin.rmt_product.ripe_point != staging_run.ripe_point)
        errs << "bin ripe_point_code[#{bin.rmt_product.ripe_point.ripe_point_code}] does not match that of the active staging_run ripe_point_code[#{staging_run.ripe_point.ripe_point_code}]"
      end

      if (staging_run.treatment_id && bin.rmt_product.treatment.id != staging_run.treatment_id)
        errs << "bin treatment_code[#{bin.rmt_product.treatment.treatment_code}] does not match that of the active staging_run ripe_point_code[#{staging_run.treatment.treatment_code}]"
      end

      if (staging_run.product_class_id && bin.rmt_product.product_class.id != staging_run.product_class_id)
        errs << "bin product_class_code[#{bin.rmt_product.product_class.product_class_code}] does not match that of the active staging_run ripe_point_code[#{staging_run.product_class.product_class_code}]"
      end

      if (staging_run.size_id && bin.rmt_product.size.id != staging_run.size_id)
        errs << "bin size_code[#{bin.rmt_product.size.size_code}] does not match that of the active staging_run ripe_point_code[#{staging_run.size.size_code}]"
      end

      if (!(bin_location=Location.find(:first, :conditions => "bins.bin_number='#{bin_num}'", :joins => "join stock_items on stock_items.location_id=locations.id join bins on stock_items.inventory_reference=bins.bin_number")))
        errs << "bin does not have a location_code"
      elsif (bin_location.location_code[0..3] != 'RA_6' && bin_location.location_code[0..3] != 'RA_7' &&bin_location.location_code[0..6] != 'PRESORT')
        errs << "bin location_code[#{bin_location.location_code}] does not start with [RA_6 or RA_7 or PRESORT]"
      end

      if (bin.exit_ref)
        errs << "Bin has been destroyed. Exit_ref:#{bin.exit_ref}"
      end

      if (bin.production_run_rebin_id)
        errs << "Bin is a rebin"
      end

      if (bin.bin_order_load_detail_id)
        errs << "Bin is on a load"
      end

      if (!bin.delivery_id)
        errs << "Bin is not in a delivery"
      end

    end

    return errs
  end

  def manual_integration
    render :inline => %{
		<% @content_header_caption = "'execute integration manually'"%>

		<%= build_manual_integation_form('manual_integation_submit','submit')%>

		}, :layout => 'content'
  end

  def manual_integation_submit
    integration_flows = params[:bin]['integration_params'].split(',').map { |comp| comp.split('?') }
    @progress = []
    integration_flows.each do |integration_flow|
      if (integration_flow[0].strip == 'bin_tipped')
        @tipped_bin = integration_flow[1].split('=')[1]
        params[:bin] = @tipped_bin
        params[:action] = 'bin_tipped'
        @progress << "#{integration_flows.index(integration_flow) + 1}.Integration Flow: bin_tipped?bin=#{@tipped_bin} <br> "
        if (error = bin_tipped_intergration)
          presort_log_result = "<result>#{handle_error(error)}</result>"
          @progress << "#{error} <br><br> "
        else
          presort_log_result = "<bins><bin result_status=\"OK\" msg=\"tipped bin #{@tipped_bin}\" /></bins>"
          @progress << "bin tipped successfully <br><br> "
        end
        create_presort_log(presort_log_result)
      elsif (integration_flow[0].strip == 'bin_created')
        @created_bin = integration_flow[1].split('=')[1]
        params[:bin] = @created_bin
        params[:action] = 'bin_created'
            @progress << "#{integration_flows.index(integration_flow) + 1}.Integration Flow: bin_created?bin=#{@created_bin} <br> "
        if (error = bin_created_intergration)
          presort_log_result = "<result>#{handle_error(error)}</result>"
          @progress << "#{error} <br><br> "
        else
          presort_log_result = "<bins><bin result_status=\"OK\" msg=\"created bin #{@created_bin}\" /></bins>"
          @progress << "bin created successfully <br><br> "
        end
        create_presort_log(presort_log_result)
      else
        @progress << "#{integration_flows.index(integration_flow) + 1}. Integration Flow: Error:Malformed url <br><br> "
      end
    end

    render :inline => %{
          <% @content_header_caption = "'INTEGRATION PROGRESS'"%>

          <%= @progress.join('') %>

          }, :layout => 'content'
  end

  def render_result(result)
    @result = "<result>#{result}</result>"
    puts "Response/Result = " + @result
    create_presort_log(@result)
    render :inline => %{<%= @result %>}
  end

end