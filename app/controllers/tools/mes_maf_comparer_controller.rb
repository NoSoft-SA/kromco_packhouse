class Tools::MesMafComparerController < ApplicationController

  layout 'content'

  def program_name?
    "mes_maf_comparer"
  end

  def bypass_generic_security?
    true
  end

  def pre_sorted_bins_created_mes_vs_maf
    render :inline => %{
		<% @content_header_caption = "'compare created MES and MAF bins'"%>

		<%= build_mes_maf_bins_created_comparer_form('pre_sorted_bins_created_mes_vs_maf_submit','search')%>

		}, :layout => 'content'
  end

  def pre_sorted_bins_created_mes_vs_maf_submit

    mes_bins_created = Bin.find_by_sql("select vwbins.bin_number,vwbins.created_on from vwbins where stock_type_code = 'PRESORT' and vwbins.created_on BETWEEN '#{params['bin']['created_on_date2from']}' AND '#{params['bin']['created_on_date2to']}' order by vwbins.created_on ASC")

    http = Net::HTTP.new(Globals.bin_created_mssql_server_host, Globals.bin_created_mssql_presort_server_port)
    request = Net::HTTP::Post.new("/select")
    parameters  = {'method' => 'select', 'statement' => Base64.encode64(" SELECT distinct [Numero_palox],[Finition],[Nom_article],[Palox_poids],[Code_variete] FROM [productionv50].[dbo].[ViewpaloxKromco]
                  where  [Numero_palox] like '500%' and Presence_etiquette is not null
                  and Finition BETWEEN '#{params['bin']['created_on_date2from']}' AND '#{params['bin']['created_on_date2to']}'")}
    no_decode = false
    request.set_form_data(parameters)
    response = http.request(request)
    puts "---\n#{response.code} - #{response.message}\n---\n"
    unless no_decode
      res = response.body.split('resultset>').last.split('</res').first
      results = Marshal.load(Base64.decode64(res))
    end

    if(results.is_a?(String))
      raise "#{response.code} - #{response.message} : #{response.body.split('message>')[1].split('</').first}"
      return
    end

    ems_bins = (mes_bins_created.map{|b| b.bin_number} - results.map{|b| b['Numero_palox'].to_s})
    maf_bins = (results.map{|b| b['Numero_palox'].to_s} - mes_bins_created.map{|b| b.bin_number})

    mes_bins_created.delete_if{|del| !ems_bins.include?(del.bin_number)}
    results.delete_if{|del| !maf_bins.include?(del['Numero_palox'].to_s)}
    results = results.group_by{|a| a['Numero_palox'] }.map{|k,v| v[0]}
    results = results.sort_by{|x|x['Finition']}

    @resultset = (mes_bins_created.map{|mes_b| {'mes_bin'=>mes_b.bin_number.to_s,'maf_bin'=>nil,'created_on'=>(mes_b.created_on),'Nom_article'=>nil,'Palox_poids'=>nil,'Code_variete'=>nil}}) +
        (results.map{|maf_b| {'maf_bin'=>maf_b['Numero_palox'].to_s,'mes_bin'=>nil,'created_on'=>(maf_b['Finition']),'Nom_article'=>maf_b['Nom_article'].to_s,'Palox_poids'=>maf_b['Palox_poids'],'Code_variete'=>maf_b['Code_variete']}})


    export_resultset = @resultset.map{|y| "('#{y['mes_bin']}','#{y['created_on']}','#{y['maf_bin']}','#{y['Nom_article']}','#{y['Palox_poids']}','#{y['Code_variete']}')"}.join(",")
    session[:query] = "Bin.find_by_sql(\" select *
    from (VALUES
          #{export_resultset}
          ) as q(mes_bin,created_on,maf_bin,Nom_article,Palox_poids,Code_variete)\")"

    render :inline => %{
      <% grid = build_mes_maf_bins_created_comparer_grid(@resultset)%>
      <% @header_content = grid.build_grid_data %>
      <% grid.caption = 'MES vs MAP bins created dicreapancies' %>
      <% @pagination = pagination_links(@presort_staging_run_pages) if @presort_staging_run_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
  },:layout => 'content'
  end

  def pre_sorted_bins_tipped_mes_vs_maf
    render :inline => %{
		<% @content_header_caption = "'compare tipped MES and MAF bins'"%>

		<%= build_mes_maf_bins_tipped_comparer_form('pre_sorted_bins_tipped_mes_vs_maf_submit','search')%>

		}, :layout => 'content'
  end

  def pre_sorted_bins_tipped_mes_vs_maf_submit
    mes_bins_tipped = Bin.find_by_sql(" select bins.bin_number,bins.tipped_date_time from bins
                                        where exit_ref = 'PRESORT_BIN_TIPPED' and bins.tipped_date_time BETWEEN '#{params['bin']['tipped_at_date2from']}' AND '#{params['bin']['tipped_at_date2to']}'
                                        order by bins.tipped_date_time ASC")

    http = Net::HTTP.new(Globals.bin_tipped_mssql_server_host, Globals.bin_tipped_mssql_integration_server_port)
    request = Net::HTTP::Post.new("/select")
    parameters  = {'method' => 'select', 'statement' => Base64.encode64("select NumPalox,Apport.DateLecture from [Apport].[dbo].[Apport]
                  where lotmaf is not null and Apport.DateLecture BETWEEN '#{params['bin']['tipped_at_date2from']}' AND '#{params['bin']['tipped_at_date2to']}' order by DateLecture ASC
                  ")}
    no_decode = false
    request.set_form_data(parameters)
    response = http.request(request)
    puts "---\n#{response.code} - #{response.message}\n---\n"
    unless no_decode
      res = response.body.split('resultset>').last.split('</res').first
      results = Marshal.load(Base64.decode64(res))
    end

    if(results.is_a?(String))
      raise "#{response.code} - #{response.message} : #{response.body.split('message>')[1].split('</').first}"
      return
    end

    ems_bins = (mes_bins_tipped.map{|b| b.bin_number} - results.map{|b| b['NumPalox'].to_s})
    maf_bins = (results.map{|b| b['NumPalox'].to_s} - mes_bins_tipped.map{|b| b.bin_number})

    mes_bins_tipped.delete_if{|del| !ems_bins.include?(del.bin_number)}
    results.delete_if{|del| !maf_bins.include?(del['NumPalox'].to_s)}

    @resultset = (mes_bins_tipped.map{|mes_b| {'mes_bin'=>mes_b.bin_number.to_s,'maf_bin'=>nil,'tipped_at'=>(mes_b.tipped_date_time)}}) + (results.map{|maf_b| {'maf_bin'=>maf_b['NumPalox'].to_s,'mes_bin'=>nil,'tipped_at'=>(maf_b['DateLecture'])}})

    export_resultset = @resultset.map{|y| "('#{y['mes_bin']}','#{y['maf_bin']}','#{y['tipped_at']}')"}.join(",")
    session[:query] = "Bin.find_by_sql(\" select *
    from (VALUES
          #{export_resultset}
          ) as q(mes_bin,maf_bin,tipped_at)\")"

    render :inline => %{
      <% grid = build_mes_maf_bins_tipped_comparer_grid(@resultset)%>
      <% @header_content = grid.build_grid_data %>
      <% grid.caption = 'MES vs MAP bins tipped dicreapancies' %>
      <% @pagination = pagination_links(@presort_staging_run_pages) if @presort_staging_run_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
  },:layout => 'content'
  end

  def view_mes_bin
    @bin = Bin.find_by_bin_number(params[:id])
    @content_header_caption = "'view #{@status_type_code} record'"
    render :inline => %{
      <%= build_view_record_form(@bin, nil, "none", 'bins')%>
      }, :layout => 'content'
  end
end