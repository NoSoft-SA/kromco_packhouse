module MesScada

  # Actions to mix in to ApplicationController
  module DataMinerActions

    # Returns the dataminer hash from the session.
    # If the session has a key named :dm_lookup_instance,
    # use the hash with key :dm_lookup_session
    # else use the hash with key :dataminer.
    def dm_session
      session[:dm_lookup_session] = {} if !session[:dm_lookup_session]

      if(!session[:dm_lookup_instance])
        session[:dataminer] = {} if !session[:dataminer]
        return session[:dataminer]
      else
        return session[:dm_lookup_session]
      end
    end

    def launch_lookup_form
      session[:dm_lookup_instance] = true

      dm_session["#{params[:lookup_search_file]}_default_values"] = {}
      params.each do |param_key,param_val|
        if(param_key.include?('default_val_'))
          dm_session["#{params[:lookup_search_file]}_default_values"][param_key.gsub('default_val_','')] = param_val
        end
      end

      dm_session["#{params[:lookup_search_file]}_static_values"] = {}
      params.reject{|key,value| (!key.include?("parameter_field_"))}.map{|key,value|
        dm_session["#{params[:lookup_search_file]}_static_values"].store(key.gsub("parameter_field_",""),value.to_s)
      }

      if(params['active_record_var_name'])
        params.reject{|key,value| (!key.include?("#{params['active_record_var_name']}_"))}.map{|key,value|
          dm_session["#{params[:lookup_search_file]}_static_values"].store(key.gsub("#{params['active_record_var_name']}_",""),value.to_s)
        }
      end

      ###puts "dm_session[#{params[:lookup_search_file]}_static_values] : " + dm_session["#{params[:lookup_search_file]}_static_values"].map{|key,value| "[" + key.to_s + "=>" + value.to_s + "],"}.to_s + "}"
      #    session[:dm_lookup_instance] = true
      session[:current_dm_lookup_instance] = true
      @select_column_name                  = params[:select_column_name]
      @looked_up_field                     = params[:looked_up_field]
      @submit_to                           = params[:submit_to]if(params[:submit_to])

      dm_session[:parameter_fields_values] = nil
      dm_session['se_layout']              = 'content'
      @content_header_caption              = "'search lookups'"
      dm_session[:redirect]                = true

      @submit_search_action                = "submit_lookup_search"
      build_remote_search_engine_form("#{params[:lookup_search_file]}.yml", @submit_search_action)
      session[:dm_lookup_instance] = false
    end

    def submit_lookup_search

      if(session[:method_overrides] && session[:method_overrides]['submit_lookup_search'])
        redirect_to :controller => session[:method_overrides]['submit_lookup_search']
        return
      end


      @records = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
      if (@records.length > 0)
        dm_session[:query] = "ActiveRecord.find_by_sql(\"#{dm_session[:search_engine_query_definition]}\")"
        render_lookups_list
      else
        session[:current_dm_lookup_instance] = false
        render :inline => %{
                             <script>
                               alert('no records were found');
                               window.close();
                             </script>
        }, :layout => 'content'
      end
      session[:dm_lookup_instance] = false
    end

    def render_lookups_list
      @select_column_name = dm_session[:select_column_name]
      @looked_up_field = dm_session[:looked_up_field]
      @submit_to = dm_session[:submit_to]
      dm_session[:submit_to] = nil

      render :inline => %{

          <% grid            = build_lookups_grid(@records,@select_column_name,@looked_up_field,@submit_to)%>
          <% grid.caption    = '' %>
          <% @header_content = grid.build_grid_data %>

          <%= grid.render_html %>
          <%= grid.render_grid %>
      }, :layout=>'content'
    end

    def submit_looked_up_selection
      session[:current_dm_lookup_instance] = false
      session[:dm_lookup_instance] = false
      id_value = params[:id_value].split("&")
      #@submission = params[:id]
      @submission = params[:key].gsub("\"","\\\"")
      @looked_up_field = id_value[0]
      if(id_value.length > 1)
        @redirect_submit_to = "#{id_value[1].split("=")[1]}?id=#{@submission}"
      end

      render :inline => %{
           <script>
            if(window.opener.frames[1] != null && window.opener.frames[1].document.getElementById("<%=@looked_up_field%>") != null) {
              window.opener.frames[1].document.getElementById("<%=@looked_up_field%>").value = "<%=@submission%>";
            }else if(window.opener.document != null && window.opener.document.getElementById("<%=@looked_up_field%>")  != null) {
              window.opener.document.getElementById("<%=@looked_up_field%>").value = "<%=@submission%>";
            }else if(window.opener.frames[1] != null && window.opener.frames[1].frames[0] != null && window.opener.frames[1].frames[0].document.getElementById("<%=@looked_up_field%>") != null) {
              //The form with lookup field lives inside tree_content wich lives inside content
              window.opener.frames[1].frames[0].document.getElementById("<%=@looked_up_field%>").value = "<%=@submission%>";
            }else {
              alert("could not update field: <%=@looked_up_field%>");
            }

            if("<%=@redirect_submit_to%>" != "") {
              window.location.href ="<%=@redirect_submit_to%>";
            } else {
              window.close();
            }
           </script>
      }, :layout => 'content'
    end

    def build_remote_search_engine_form(report_name, redirect_to = nil)
      @report_file_name            = report_name.sub(".yml", "")
      @report_file                 = Globals.get_reports_location + "/" + report_name
      dm_session[:report_name]     = @report_file_name
      dm_session[:redirect_method] = nil if dm_session[:redirect_method] != nil
      if redirect_to != nil
        dm_session[:redirect_method] = redirect_to.to_s
      end
      build_parameters_form(@report_file)
    end


    # "Search Engine" list of reports in a tree structure.
    # See report_index in ReportsController.
    def file_structure
      return if authorise_for_web(program_name?, 'search_engine')== false
      @root_file     = Globals.get_reports_location
      #_______________________________________________________________
      tree_builder   = ReportTreeBuilder.new
      @tree          = tree_builder.build_tree(@root_file) # Store in session state to rebuild location of selected file
      dm_session[:tree] = @tree
      #________________________________________________________________

      render :inline => %{
                         <%  @content_header_caption = "'#{@root_file}'" %>
                         <% @tree_script = build_file_structure_form(@tree,@tree[0].values[0]) %>
      }, :layout => 'tree'
    end

    def build_report_parameters_form

      #   tree_builder = ReportTreeBuilder.new

      # id = params[:id].to_i

      this_report = DataMinerReport.find(params[:id])
      url         = File.join(Globals.get_reports_location, this_report.filename)
      if !File.exists? url
        render :inline => %{
              <script>
                alert("This report no longer exists on disk. Filename is '#{url}'");
                window.location.href = "/reports/reports/report_index";
              </script>
        }
        return
      end
      permission  = File.basename(url, '.yml')

      # url = tree_builder.get_file_location(dm_session[:tree],params[:id].to_s)
      # permission               = url.split("/").reverse[0].split(".")[0]
      dm_session[:report_name] = nil if dm_session[:report_name] != nil
      dm_session[:report_name] = permission
      @report_file_name        = permission

      dm_session[:redirect]        = false
      dm_session[:redirect_method] = nil
      dm_session['se_layout']      = 'tree_node_content' #TODO: Find out what this does....

      #----------Generic method --- By Happy
      build_parameters_form(url)
      #--------------------end-----------------------------
    end

    def build_happymores_form

      tree_builder = ReportTreeBuilder.new

      # id = params[:id].to_i


      url = tree_builder.get_file_location(dm_session[:tree],params[:id].to_s)
      permission = url.split("/").reverse[0].split(".")[0]
      dm_session[:report_name] = nil if dm_session[:report_name] != nil
      dm_session[:report_name] = permission
      @report_file_name = permission

      dm_session[:redirect] = false
      dm_session[:redirect_method] = nil
      dm_session['se_layout'] = 'tree_node_content'

      #return if authorise_for_web(program_name?,permission + "_rpt")== false

      #----------Generic method --- By Happy
      build_parameters_form(url)
      #--------------------end-----------------------------
    end


    # Remove all parameters from the dm_session that might interfere
    # with the current form being built for DM parameters.
    def clear_dm_params
      dm_session[:parameter_fields_values]        = nil
      dm_session[:search_engine_group_by_columns] = nil
      dm_session[:search_engine_order_by_columns] = nil
      dm_session[:search_engine_or_values]        = nil
      dm_session[:functions]                      = nil
      dm_session[:search_engine_limit]            = nil
    end

    def clear_dm_session
      clear_dm_params
      redirect_method = dm_session[:redirect_method]
      layout          = dm_session['se_layout']
      report          = dm_session[:report_name]
      redirect        = dm_session[:redirect]

      if report
        default_vals_key = report + "_" + "default_values"
        static_vals_key  = report + "_" + "static_values"
        default_values   = dm_session[default_vals_key]
        static_values    = dm_session[static_vals_key]
      end

      dm_session[:dataminer]         = nil
      dm_session[:dm_lookup_session] = nil

      dm_session[:redirect_method]   = redirect_method
      dm_session['se_layout']        = layout
      dm_session[:redirect]          = redirect

      if report
        dm_session[:report_name]     = report
        dm_session[default_vals_key] = default_values
        dm_session[static_vals_key]  = static_values
      end

    end

    def build_parameters_form(url)

      clear_dm_session

      field_extractor      = FieldExtractor.new(url)
      RAILS_DEFAULT_LOGGER.info("YAML: " + url)
      @fields              = field_extractor.form_fields
      @main_table_name     = field_extractor.main_table_name
      @grid_action_columns = field_extractor.grid_action_columns

      query_stat                                     = field_extractor.query_statement
      dm_session[:parameter_query]                   = nil if dm_session[:parameter_query] != nil
      dm_session[:parameter_query]                   = query_stat
      dm_session[:full_parameter_query]              = query_stat.clone

      dm_session[:main_table_name]                   = nil if dm_session[:main_table_name] != nil
      dm_session[:main_table_name]                   = @main_table_name

      dm_session[:search_fields]                     = nil if dm_session[:search_fields] != nil
      dm_session[:search_fields]                     = @fields

      dm_session[:search_engine_grid_action_columns] = nil if dm_session[:search_engine_grid_action_columns] != nil
      dm_session[:search_engine_grid_action_columns] = @grid_action_columns

      dm_session[:columns_list]                      = nil if dm_session[:columns_list] != nil
      dm_session[:columns_list]                      = field_extractor.columns_list

      dm_session[:grid_configs]                      = nil if dm_session[:grid_configs] != nil
      dm_session[:grid_configs]                      = field_extractor.grid_configs

      if @fields.length == 0
        statement = FieldParser.new(query_stat,nil).query
        ###puts statement
        if statement.index("=")==nil
          if statement.index("(")!=nil
            statement = statement.gsub!("(","");
          end
          if statement.upcase().index("WHERE")!=nil
            statement = statement.gsub!("where","")
          end
          if statement.index("$")!=nil
            statement = statement.gsub!("$","")
          end
        end
        if statement.upcase().index("LIMIT")==nil
          statement += " limit 100"
        end

        #conn = User.connection
        #@results = conn.select_all(statement)
        #dm_session[:search_engine_query_definition] = statement

        from_index = statement.to_s.upcase().index("FROM")
        left_side  = statement[0,from_index+4]
        right_side = statement[from_index+4, statement.size()-from_index+4]

        table_name = nil

        if right_side.to_s.index("(")==nil
          if right_side.to_s.upcase().index("LIMIT")!=nil
            limit_index = right_side.to_s.upcase().index("LIMIT")
            table_name = right_side[0, limit_index].strip()
          else
            table_name = right_side.strip()
          end
        else
          right_side = right_side.strip()
          where_index = right_side.to_s.upcase().index("WHERE")
          table_name = right_side[0, where_index].strip()
        end
        #puts table_name.to_s
        dm_session[:table_name] = table_name

        dm_session[:search_engine_query_definition] = nil if dm_session[:search_engine_query_definition] != nil
        dm_session[:search_engine_query_definition] = dm_session[:full_parameter_query]

        if(session[:dm_lookup_instance] == true)
          dm_session[:select_column_name] = @select_column_name
          dm_session[:looked_up_field] = @looked_up_field
          dm_session[:submit_to] = @submit_to if(@submit_to)
          #                redirect_to("/reports/reports/submit_lookup_search")
          submit_lookup_search
          return
        end
        #http://localhost:3000/reports/reports/render_generic_grid/<%=@holder%>
        render :inline=> %{
                     <% @content_header_caption = "'view results'"%>
                     <% @url_base = "http://" + request.host_with_port + "/" + "reports/reports/render_generic_grid" %>
                     <script>
                       if(window.parent.stop_spinner) {
                         window.parent.stop_spinner();
                       }
                         window.open("<%=@url_base%>", "results","width=850,height=400,top=200,left=200,toolbar=1,menubar=1,status=1,scrollbars=1,resizable=1" );
                        </script>

        }, :layout=>'content'
      else
        build_parameter_fields_form(@fields)
      end

    end

    # Get the field value from parameters for use in send_parameter_fields.
    def get_field_value_from_parameter_fields(params, field)
      field_value     = nil
      parameter_field = params['parameter_field']
      case field[:field_type]

        # --- DateTime ---
      when "DateTimeField"
        if parameter_field[:"#{field[:field_name]}-sign"].to_s == "IS NULL" ||
          parameter_field[:"#{field[:field_name]}-sign"].to_s == "IS NOT NULL"
          field_value = parameter_field[:"#{field[:field_name]}-sign"]
        else
          field_value = DateTime.civil(parameter_field[:"#{field[:field_name]}(1i)"].to_i,
                                       parameter_field[:"#{field[:field_name]}(2i)"].to_i,
                                       parameter_field[:"#{field[:field_name]}(3i)"].to_i,
                                       parameter_field[:"#{field[:field_name]}(4i)"].to_i,
                                       parameter_field[:"#{field[:field_name]}(5i)"].to_i).strftime("%Y/%m/%d %I:%M%p")
        end

        # --- Date ---
      when "DateField"
        if parameter_field[:"#{field[:field_name]}-sign"].to_s == "IS NULL" ||
          parameter_field[:"#{field[:field_name]}-sign"].to_s == "IS NOT NULL"
          field_value = parameter_field[:"#{field[:field_name]}-sign"]
        else
          field_value = DateTime.civil(parameter_field[:"#{field[:field_name]}(1i)"].to_i,
                                       parameter_field[:"#{field[:field_name]}(2i)"].to_i,
                                       parameter_field[:"#{field[:field_name]}(3i)"].to_i).strftime("%Y/%m/%d")
        end

        # --- DropDown ---
      when "DropDownField"
        if (parameter_field[:"#{field[:field_name]}-sign"].to_s == "IS NULL" ||
            parameter_field[:"#{field[:field_name]}-sign"].to_s == "IS NOT NULL")
          field_value = parameter_field[:"#{field[:field_name]}-sign"]
        else
          field_value = parameter_field[:"#{field[:field_name]}"]
        end
        # --- Text ---
      when "TextField"
        if (parameter_field[:"#{field[:field_name]}-sign"].to_s == "IS NULL" ||
            parameter_field[:"#{field[:field_name]}-sign"].to_s == "IS NOT NULL")
          field_value = parameter_field[:"#{field[:field_name]}-sign"]
        else
          field_value = parameter_field[:"#{field[:field_name]}"]
        end

        # --- PopupDate ---
      when "PopupDateRangeSelector"
        from      = ""
        to        = ""
        from_name = field[:field_name].to_s + "_datefrom"
        to_name   = field[:field_name].to_s + "_dateto"
        if params[from_name]
          from += params[from_name]
        end
        if params[to_name]
          to += params[to_name]
        end
        field_value = "#{from}|#{to}"
      else
        field_value = parameter_field[:"#{field[:field_name]}"]
      end
      field_value
    end

    def send_parameter_fields

      session[:dm_lookup_instance]    = true if(params['parameter_field'][:looked_up_field])
      if Digest::SHA1.hexdigest(dm_session[:parameter_query]) != params[:parameter_field][:hash_check]
        raise MesScada::InfoError, "You have launched a different lookup or report before completing this one. Please start again."
      end

      dm_session[:select_column_name] = params['parameter_field'][:select_column_name]
      dm_session[:looked_up_field]    = params['parameter_field'][:looked_up_field]
      dm_session[:submit_to]          = params['parameter_field'][:submit_to] if(params['parameter_field'][:submit_to])
      dm_session[:csv_export_filename]= params['parameter_field'][:user_defined_report_name] unless params['parameter_field'][:user_defined_report_name].blank?

      if dm_session[:parameter_fields].length == 0
        redirect_to_index("No parameter values send!")
        return
      end

      dm_session[:parameter_fields_values] = nil if dm_session[:parameter_fields_values]!=nil
      dm_session[:parameter_fields_values] = []
      dm_session[:operator_signs]          = {}

      # Get field values & operator signs & update session.
      dm_session[:parameter_fields].each do |field|
        field_value = get_field_value_from_parameter_fields(params, field)

        if ['DateTimeField', 'DateField', 'DropDownField', 'TextField'].include? field[:field_type]
          dm_session[:operator_signs][field[:field_name]] = params['parameter_field'][:"#{field[:field_name]}-sign"]
        end

        hashed_field_value = {:field_name => field[:field_name], :field_value => field_value, :field_type => field[:field_type]}
        if(field[:field_type] == "CheckBox")
          hashed_field_value.store(:is_clicked,params['parameter_field'][:"#{field[:field_name]}_is_clicked"])
          dm_session[:"#{field[:field_name]}_is_clicked"] = true if(params['parameter_field'][:"#{field[:field_name]}_is_clicked"] == 'true')
        end
        dm_session[:parameter_fields_values].push(hashed_field_value)
      end

      #puts "COLUMNS LIST LENGTH : " + dm_session[:columns_list].length.to_s + " First Col : " + dm_session[:columns_list][1].to_s
      #puts "LIMIT PARAMETER FIELD : " + params['parameter_field']['search_engine_limit'].to_s
      @excel_only = params['parameter_field']['excel_only'].nil? ? false : (params['parameter_field']['excel_only'].to_i == 1)
      #puts "EXCEL ONLY : " + params['parameter_field']['excel_only'].to_s
      dm_session[:search_engine_limit] = nil if dm_session[:search_engine_limit] != nil
      dm_session[:search_engine_limit] = params['parameter_field']['search_engine_limit'].to_s

      #===================================================
      # Get Or Values and Store them in dm_session
      #===================================================
      get_or_values

      statement = FieldParser.new(dm_session[:parameter_query],
                                  dm_session[:parameter_fields_values],
                                  dm_session[:search_engine_or_values],
                                  dm_session[:operator_signs]).query
      # puts "AFTER NULL FIELDS REMOVED " + statement

      # puts "QUERY STAT AFTER TEST FOR NO ARGUMENTS IN WHERE : " + statement.to_s
      #puts dm_session[:operator_signs].length.to_s

      # getting the name of table
      if statement.upcase.index(" JOIN") == nil
        table_name = FieldParser.get_table_name(statement)
        dm_session[:table_name] = table_name
      else
        dm_session[:table_name] = dm_session[:main_table_name] || dm_session[:main_table]
      end


      #============================

      #---------------------------------------
      #  applying calculations
      #---------------------------------------

      statement = apply_functions(statement, params)

      #---------------------------------------
      #  end applying calculations
      #---------------------------------------

      ###puts statement.to_s

      #--------------------------------------------------
      # Inserting the limit clause if not defined
      #--------------------------------------------------

      # if statement.to_s.upcase().index("LIMIT ") == nil
      #   statement = statement << "  LIMIT 1000"
      # end
      max_limit = Globals.search_engine_max_rows
      if dm_session[:search_engine_limit].to_s != ""
        if statement.upcase.index(" LIMIT ") != nil
          pattern      = / limit [0-9]+/i
          limit_clause = "limit #{dm_session[:search_engine_limit]}"
          statement    = statement.gsub(pattern, limit_clause)
        else
          if dm_session[:search_engine_limit].to_i > max_limit.to_i
            statement = statement << " LIMIT " << max_limit.to_s
          else
            statement = statement << " LIMIT " << dm_session[:search_engine_limit].to_s
          end
        end
      else
        statement = statement << " LIMIT " << max_limit.to_s
      end
      ###puts "AFTER LIMIT ADDED " + statement
      ###puts statement

      #--------------------------------------------------
      # end Inserting the limit clause if not defined
      #--------------------------------------------------

      #--------------------------------------------------
      # Extract the where clause and store it in dm_session
      # state. for further queries if the statement involves
      # functions
      #--------------------------------------------------
      query_stat   = statement
      where_clause = ""
      # if dm_session[:grid_type] == "summary"
      #   where_clause += extract_where_clause(query_stat)
      # end
      if dm_session[:grid_type] == "summary"
        if statement.upcase.index(" WHERE") != nil
          where_clause = FieldParser.get_where_clause(statement).split("|splitter|")[0].to_s
        end
      end

      ###puts "WHERE CLAUSE : #{where_clause}  %%%"
      dm_session[:search_engine_where_clause] = nil if dm_session[:search_engine_where_clause] != nil
      dm_session[:search_engine_where_clause] = where_clause

      #executing the query
      ###puts "FINAL SEARCH ENGINE QUERY : #{statement}"
      conn = User.connection
      #@results = conn.select_all(statement)
      dm_session[:resultset]                      = nil if dm_session[:resultset] != nil
      #dm_session[:resultset] = @results
      dm_session[:search_engine_query_definition] = nil if dm_session[:search_engine_query_definition] != nil
      dm_session[:search_engine_query_definition] = statement

      # @info = "<font color = 'green'>FINAL SQL STATEMENT: </font><br> " + dm_session[:search_engine_query_definition]
      # a     = dm_session[:parameter_fields_values]
      # b     = 2
      @redirect_method = dm_session[:redirect_method]
      @redirect_method = params['parameter_field'][:submit_search_action] if(params['parameter_field'][:submit_search_action])

      # Set the url to be called.
      if dm_session[:redirect] == true
        if @excel_only
          @url_base = "http://#{request.host_with_port}/development_tools/data/export_se_grid_to_csv"
        else
          @url_base = "http://#{request.host_with_port}/#{params[:controller]}/#{@redirect_method}"
        end
        ###puts "REDIRECT METHOD : " + @redirect_method.to_s
      else
        ###puts params[:controller].to_s + "/" + params[:action].to_s
        if @excel_only
          @url_base = "http://#{request.host_with_port}/development_tools/data/export_se_grid_to_csv"
        else
          if dm_session[:grid_type] == "summary"
            @url_base    = "http://#{request.host_with_port}/reports/reports/render_summary_grid"
            @window_name =  ''
          else
            @url_base    = "http://#{request.host_with_port}/reports/reports/render_generic_grid"
            @window_name = ''
          end
        end
      end
      render :template=>'reports/reports/send_parameter_fields', :layout=> 'content'
    end

    #//==========================
    #  Apply functions
    #=============================

    def apply_functions(statement, parms)
      stat       = statement
      from_index = statement.to_s.upcase().index("FROM")
      left_stat  = statement[0,from_index]
      right_stat = statement[from_index, statement.size()-from_index]

      #logger.info ">>> PARMS: #{parms.inspect}"
      func_hidden_value     = parms['apply_functions_hidden_field'].to_s
      group_by_hidden_value = parms['group_by_hidden_field'].to_s
      ###puts"&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
      ###puts func_hidden_value.to_s + "    "  + group_by_hidden_value.to_s
      ###puts"&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
      # logger.info ">>> &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
      # logger.info ">>> #{func_hidden_value}    #{group_by_hidden_value}"
      # logger.info ">>> &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"

      # Clearing functions dm_session if any
      dm_session[:functions] = nil if dm_session[:functions] != nil
      dm_session[:functions] = func_hidden_value
      # end

      stat = add_functions(stat, func_hidden_value.to_s)
      ###puts "FUNCTIONS APPLIED : " + stat
      #logger.info ">>> FUNCTIONS APPLIED : #{stat}"


      dm_session[:search_engine_group_by_columns] = nil if dm_session[:search_engine_group_by_columns] != nil
      dm_session[:search_engine_group_by_columns] = group_by_hidden_value
      #group by columns
      dm_session[:group_by_columns] = Array.new
      if(group_by_hidden_value != "" )
        # If the yml file has an existing order by clause we need to remove it first.
        # Otherwise the db will choke.
        existing_order_by_pos = stat.index( /order\s+by/i )                            # Where does the order by start?
        if existing_order_by_pos
          end_order_by_pos = stat.index( /limit|group/i ) || stat.length               # where does the order by end?
          stat.slice!(existing_order_by_pos, (end_order_by_pos-existing_order_by_pos)) # Remove the order by clause from the query.
        end
        if(stat.to_s.upcase().index("GROUP BY")!= nil)
          group_by_index = stat.upcase().index("GROUP BY")
          right_of_group_by = stat[group_by_index+8, stat.size()-(group_by_index+8)]
          if(right_of_group_by.size() > 2) # cater for limit clause as well
            if right_of_group_by.to_s.upcase().index("LIMIT ") == nil
              if(group_by_hidden_value.index(",")!=nil)
                cols = group_by_hidden_value.split(",")
                cols.each do |col|
                  stat += "," + col
                  dm_session[:group_by_columns].push(col)
                end
              else
                stat += "," + group_by_hidden_value
                dm_session[:group_by_columns].push(group_by_hidden_value)
              end
            else
              left_part = stat[0, group_by_index + 8]
              limit_index = right_of_group_by.to_s.upcase().index("LIMIT")
              right_with_limit = right_of_group_by[limit_index, right_of_group_by.size()-(limit_index + 1)]
              left_without_limit = right_of_group_by[0, limit_index]
              if group_by_hidden_value.index(",") != nil
                cols = group_by_hidden_value.split(",")
                if left_without_limit.index(",") != nil
                  cols.each do |col|
                    left_without_limit += "," + col
                    dm_session[:group_by_columns].push(col)
                  end
                else
                  left_without_limit += "," + group_by_hidden_value
                  dm_session[:group_by_columns].push(group_by_hidden_value)
                end
              end
              stat = left_part + " " + left_without_limit + " " + right_with_limit
            end
          else
            if(group_by_hidden_value.index(",")!=nil)
              cols = group_by_hidden_value.split(",")
              index = 0
              cols.each do |col|
                if index == 0
                  stat += " " + col
                else
                  stat += "," + col
                end
                dm_session[:group_by_columns].push(col)
                index += 1
              end
            else
              stat += " " + group_by_hidden_value
              dm_session[:group_by_columns].push(group_by_hidden_value)
            end
          end
        else
          # consider also the case when the LIMIT clause is present
          if stat.to_s.upcase().index("LIMIT ") == nil
            stat += " GROUP BY "
            if(group_by_hidden_value.index(",")!=nil)
              cols = group_by_hidden_value.split(",")
              index = 0
              cols.each do |col|
                if index == 0
                  stat += " " + col
                else
                  stat += "," + col
                end
                dm_session[:group_by_columns].push(col)
                index += 1
              end
            else
              stat += " " + group_by_hidden_value
              dm_session[:group_by_columns].push(group_by_hidden_value)
            end
          else
            limit_index = stat.to_s.upcase().index("LIMIT ")
            right_with_limit = stat[limit_index, stat.to_s.size()-(limit_index)]
            left_part = stat[0, limit_index]
            left_part += " GROUP BY"
            if(group_by_hidden_value.index(",")!=nil)
              cols = group_by_hidden_value.split(",")
              index = 0
              cols.each do |col|
                if index == 0
                  left_part += " " + col
                else
                  left_part += "," + col
                end
                dm_session[:group_by_columns].push(col)
                index += 1
              end
            else
              left_part += " " + group_by_hidden_value
              dm_session[:group_by_columns].push(group_by_hidden_value)
            end
            stat = left_part + " " + right_with_limit
          end
        end
      end

      #=======================================================

      #======================================================
      # Order by clause implementation
      #=======================================================
      dm_session[:order_by_columns] = Array.new
      order_by_columns = parms['order_by_hidden_field'].to_s
      dm_session[:search_engine_order_by_columns] = nil if dm_session[:search_engine_order_by_columns] != nil
      dm_session[:search_engine_order_by_columns] = order_by_columns
      if order_by_columns != ""
        order_by_cols_array = order_by_columns.split(",")
        if stat.upcase.index("LIMIT ") != nil
          limit_index = stat.upcase.index("LIMIT ")
          left_stat = stat[0,limit_index]
          right_stat = stat[limit_index, stat.size-limit_index]
          order_by_string = " order by "
          index = 0
          order_by_cols_array.each do |col|
            if index == 0
              order_by_string += col
            else
              order_by_string += "," + col
            end
            dm_session[:order_by_columns].push(col)
            index += 1
          end
          left_stat += order_by_string
          stat = left_stat + " " + right_stat
        else # no limi clause
          order_by_string = " order by "
          index = 0
          order_by_cols_array.each do |col|
            if index == 0
              order_by_string += col
            else
              order_by_string += "," + col
            end
            dm_session[:order_by_columns].push(col)
            index += 1
          end
          stat += order_by_string
        end
        #cleaning order by columns by putting them in group by columns if statement contains functions like SUM, COUNT, AVG, MAX, MIN
        #if stat.upcase.index("SUM(") != nil || stat.upcase.index("COUNT(")!= nil || stat.upcase.index("AVG(") != nil || stat.upcase.index("MAX(") != nil || stat.upcase.index("MIN(") !=nil
        if stat.upcase.index("ORDER BY") != nil
          columns = Array.new
          order_by_cols_array.each do |col|
            if col.index("DESC") != nil || col.index("ASC") != nil
              my_col = col.to_s.split[0]
              columns.push(my_col)
            else
              columns.push(col)
            end
          end
          if stat.upcase.index("GROUP BY") != nil
            #first add the columns to the group by clause
            group_by_index = stat.upcase.index("GROUP BY")
            order_by_index = stat.upcase.index("ORDER BY")
            cols_stat = stat[group_by_index + 8, order_by_index - (group_by_index + 8)]
            left_stat = stat[0, group_by_index + 8]
            right_stat = stat[order_by_index, stat.size - order_by_index]
            columns.each do |col|
              if cols_stat.index(col.to_s) == nil
                cols_stat += "," + col
              end
            end
            stat = left_stat + " " + cols_stat + " " + right_stat
            # second add the columns before the from clause
            select_index = stat.upcase.index("SELECT")
            from_index = stat.upcase.index("FROM ")
            cols_phrase = stat[select_index + 6, from_index -(select_index + 6)]
            ###puts "AYO BAYO: " + cols_phrase
            #logger.info ">>> AYO BAYO: #{cols_phrase}"
            left_stat = stat[0, select_index + 6]
            right_stat = stat[from_index, stat.size - from_index]
            columns.each do |col|
              if cols_phrase.index(col)==nil
                cols_phrase += "," + col
              end
            end
            stat = left_stat + " " + cols_phrase + " " + right_stat
          else # no group by clause
            order_by_index = stat.upcase.index("ORDER BY")
            left_stat = stat[0, order_by_index]
            right_stat = stat[order_by_index, stat.size - order_by_index]
            group_by_stat = " group by "
            index = 0
            columns.each do |col|
              if index == 0
                group_by_stat += col
              else
                group_by_stat += "," + col
              end
              index += 1
            end
            stat = left_stat + " " + group_by_stat + " " + right_stat
            # add the columns before the from clause
            select_index = stat.upcase.index("SELECT")
            from_index = stat.upcase.index("FROM ")
            cols_phrase = stat[select_index + 6, from_index -(select_index + 6)]
            left_stat = stat[0, select_index + 6]
            right_stat = stat[from_index, stat.size - from_index]
            columns.each do |col|
              if cols_phrase.index(col)==nil
                cols_phrase += "," + col
              end
            end
            stat = left_stat + " " + cols_phrase + " " + right_stat
          end
        end
      end

      ###puts "QUERY STATEMENT AFTER ORDER BY: " + stat
      #logger.info ">>> QUERY STATEMENT AFTER ORDER BY: #{stat}"

      #=======================================================

      #PUTTING THE SEARCH VARIABLES IN dm_session IF WHERE CLAUSE IS PRESENT
      if stat.upcase.index(" WHERE") != nil
        if stat.to_s.index("=") != nil || stat.to_s.index("<") != nil || stat.to_s.index(">") != nil || stat.to_s.index("<=") != nil || stat.to_s.index(">=") != nil
          where_index = stat.upcase().index("WHERE")
          right_of_where = stat[where_index, (stat.size()-where_index)]
          if(right_of_where.index("(")!=nil && right_of_where.index(")")!=nil)
            first_brace = right_of_where.index("(")
            sec_brace = right_of_where.index(")")
            if right_of_where.to_s.upcase().index(" OR")!= nil
              first_or_index = right_of_where.upcase().index(" OR")
              or_stat = right_of_where[(first_or_index+3), ((sec_brace - first_or_index)-1)]
              or_arguments_array = or_stat.to_s.split(/or|and|AND|OR/)
              dm_session[:or_arguments] = Array.new
              or_arguments_array.each do |arg_or|
                #puts arg_or.to_s
                dm_session[:or_arguments].push(arg_or)
              end
              and_stat = right_of_where[first_brace+1, ((first_or_index - first_brace)-1)]
              and_arguments_array = and_stat.to_s.split(/and|or |AND|OR/)
              dm_session[:and_arguments] = Array.new
              and_arguments_array.each do |arg|
                #puts arg.to_s
                dm_session[:and_arguments].push(arg)
              end
            else
              and_stat = right_of_where[first_brace+1, sec_brace-1]
              and_arguments_array = and_stat.to_s.split(/and|or |AND|OR/)
              dm_session[:and_arguments] = Array.new
              and_arguments_array.each do |arg|
                #puts arg.to_s
                dm_session[:and_arguments].push(arg)
              end
            end

          end
        end
      end

      # adding group by columns before the from clause
      stat = add_group_by_columns_before_from_clause(stat)


      # Finalizing the statement: Check if Group by is present and any function is present.
      # if group by is present and no function : add the id field before the from clause and also in group by clause
      stat = add_id_column_if_no_function(stat)

      ###puts stat
      #logger.info ">>> #{stat}"

      dm_session[:final_statement] = stat

      # from_mush = stat
      # if from_mush.upcase().index("WHERE")
      #   from_mush = from_mush.upcase().split("WHERE")[0]

      # end

      # column_pattern = /select.+(?= from )/i
      # col_phrase = from_mush.slice(column_pattern)
      # col_phrase.strip!
      # col_phrase = col_phrase.slice(7..(col_phrase.size()-1)).strip

      if func_hidden_value  &&    func_hidden_value != ""
        # if stat.to_s.upcase().index("COUNT(") != nil || stat.to_s.upcase().index("SUM(") != nil || stat.to_s.upcase().index("AVG(") != nil || stat.to_s.upcase().index("MAX(") != nil || stat.to_s.upcase().index("MIN(") != nil || (stat.to_s.upcase.index(" GROUP BY") != nil) # && (col_phrase.to_s.upcase.index(".ID") == nil || col_phrase.to_s.upcase.index(" ID")==nil || col_phrase.to_s.upcase.index(",ID")==nil || col_phrase.to_s.upcase.index("ID,")==nil))
        dm_session[:grid_type] = "summary"
      else
        dm_session[:grid_type] = "normal"
      end

      return stat
    end

    #//==========================
    #  end Apply functions
    #=============================

    def get_or_values

      dm_session[:search_engine_or_values] = nil if dm_session[:search_engine_or_values] != nil
      dm_session[:search_engine_or_values] = Hash.new

      dm_session[:parameter_fields].each do |para|
        field = "hidden-#{para[:field_name]}"
        if params[field] != nil && params[field].to_s != ""
          dm_session[:search_engine_or_values][para[:field_name]] = params[field].to_s
        end
      end

    end

    def apply_or_values(stat)
      where_right                          = FieldParser.get_where_clause(stat)
      where                                = where_right.split("|splitter|")[0]
      right                                = where_right.split("|splitter|")[1]
      left_pattern                         = /select.+(?=where)/i
      left_stat                            = stat.slice(left_pattern)

      or_part                              = ""

      dm_session[:search_engine_or_values] = nil if dm_session[:search_engine_or_values] != nil
      dm_session[:search_engine_or_values] = Hash.new

      dm_session[:parameter_fields].each do |para|
        field = "hidden-"
        field += para[:field_name].to_s
        if params[field] != nil && params[field].to_s != ""
          #dm_session[:search_engine_or_values].push({:field_name=>para[:field_name].to_s, :field_value=>params[field].to_s})
          dm_session[:search_engine_or_values][para[:field_name]] = params[field].to_s
          if params[field].to_s.index(",") != nil
            or_values = params[field].to_s.split(",")
            or_values.each do |or_value|
              if or_part == ""
                or_part += "(" + para[:field_name].to_s + "=" + "'" + or_value.to_s + "'"
              else
                or_part += " or " + para[:field_name].to_s + "=" + "'" + or_value.to_s + "'"
              end
              #where += " or " + para[:field_name].to_s + "=" + "'" + or_value.to_s + "'"
            end
          else
            #where += " or " + para[:field_name].to_s + "=" + "'" + params[field].to_s + "'"
            or_part += "(" + para[:field_name].to_s + "=" + "'" + params[field].to_s + "'"
          end
        end
      end
      if or_part != ""
        or_part += ")"
      end
      if or_part != ""
        where += " or " + or_part
      end
      where = " where(" + where + ")"
      stat = left_stat + where + " " + right.to_s
    end

    def add_functions(stat, func_string)
      if func_string != ""
        stat_between_select_and_from = FieldExtractor.get_statement_between_select_and_from(stat)
        if func_string.index("|") != nil
          functions_array = func_string.split("|")
          #column         = func_string.split("|")[1]
          from_index      = stat.upcase.index("FROM ")
          right_part      = stat[from_index, stat.size - from_index]
          left_part       = stat[0,from_index]
          select_index    = stat.upcase.index("SELECT ")
          select_part     = stat[select_index, 6]
          #func_part      = function.to_s + "(" + column.to_s + ") as " + function.to_s + "_" + column.to_s
          func_part       = ""

          functions_array.each do |func|
            if func_part == ""
              if func.index("*") == nil
                func_name = func.split("(")[0]
                col_name  = func.split("(")[1].gsub(")","").strip
                func_part += func + " AS " + func_name + "_" + col_name.gsub(".","_")
              else
                func_part += func
              end
            else
              if func.index("*") == nil
                func_name = func.split("(")[0]
                col_name  = func.split("(")[1].gsub(")","").strip
                func_part += ", " + func + " AS " + func_name + "_" + col_name.gsub(".","_")
              else
                func_part += ", " + func
              end
            end
          end
          if stat_between_select_and_from.length > 1
            func_part += "," + stat_between_select_and_from
          end
          stat = select_part + " " + func_part + " " + right_part
        else
          function     = func_string
          from_index   = stat.upcase.index("FROM ")
          right_part   = stat[from_index, stat.size - from_index]
          left_part    = stat[0,from_index]
          select_index = stat.upcase.index("SELECT ")
          select_part  = stat[select_index, 6]
          #func_part   = function.to_s + "(*)"
          func_part    = function
          if stat_between_select_and_from.length > 1
            func_part += "," + stat_between_select_and_from
          end
          stat = select_part + " " + func_part + " " + right_part
        end
      end
      return stat
    end

    def add_group_by_columns_before_from_clause(stat)
      if dm_session[:group_by_columns].length != 0
        from_index      = stat.upcase.index("FROM ")
        right_part      = stat[from_index,stat.size - from_index]
        left_part       = stat[0,from_index]
        select_index    = left_part.upcase.index("SELECT ")
        right_of_select = left_part[select_index +6,left_part.size - (select_index+6)]
        cols_array      = Array.new
        if right_of_select.index(",") != nil
          right_of_select.split(",").each do |c|
            cols_array.push(c)
          end
        else
          cols_array.push(right_of_select)
        end
        left_select = left_part[0,select_index + 6]
        group_stat  = ""

        dm_session[:group_by_columns].each do |c|
          if group_stat == ""
            group_stat += c.to_s
          else
            group_stat += "," + c.to_s
          end
        end

        cols_array.each do |c_a|
          if %w|COUNT SUM MAX MIN AVG|.any? {|a| c_a.upcase.include?("#{a}(") }
            # Provide column heading for summarised fields if not provided.
            # This is for clarity, but also to avoid issues with having identical column names in the recordset hash.
            if c_a.upcase.index("COUNT(").nil? && !c_a.strip.include?(' ')
              column_alias = c_a.strip.split(/\(|\)/).map {|a| a.downcase }.join('_')
              c_a << ' ' << column_alias
            end

            if group_stat == ""
              group_stat += c_a.to_s
            else
              group_stat += "," +c_a.to_s
            end
          end
        end
        stat = left_select + " " + group_stat + " " + right_part
      end
      return stat
    end

    def add_id_column_if_no_function(stat)
      if stat.to_s.upcase().index("SUM(") == nil && stat.to_s.upcase().index("COUNT(") == nil && stat.to_s.upcase().index("AVG(") == nil && stat.to_s.upcase().index("MAX(") == nil && stat.to_s.upcase().index("MIN(") == nil && stat.to_s.upcase.index("JOIN ") == nil && stat.to_s.upcase.index("GROUP BY") == nil
        # FIRST: add the id column before the from clause first
        select_index     = stat.to_s.upcase.index("SELECT ")
        from_index       = stat.to_s.upcase.index("FROM ")
        required_section = stat[select_index + 6, from_index - (select_index + 6)]
        left             = stat[0, select_index + 6]
        right            = stat[from_index, stat.to_s.size - from_index]
        if required_section.to_s.index("*") == nil
          unless list_of_cols_from_stat(stat).include?('id') # Check if there is a column named "id"...
            if required_section.to_s.gsub(/\s/,"").size > 0
              required_section += "," + "id "
            else
              required_section += " id "
            end
          end
          stat = left + " " + required_section + " " + right
          dm_session[:columns_list].push("id") if ! dm_session[:columns_list].find{|c|c == "id"}
        end
        # end adding id column before the from clause
      end
      return stat
    end

    def operator_sign_changed
      ###puts params.to_s
      @sign_combo = ""
      params.keys.each do |key|
        if key.to_s.index("-sign")!= nil
          @sign_combo = key.to_s
        end
      end
      @combo_name = @sign_combo.to_s.split("-")[0]
      hiddenField = "hidden=" + @combo_name.to_s
      ###puts dm_session[hiddenField].length.to_s
      if (params[@sign_combo] == "like" || params[@sign_combo]=="text")
        render :inline=>%{
         <%= text_field('parameter_field',@combo_name) %>
         <% @image_name = "img-#{@combo_name}" %>
         <% puts @image_name %>
       }
      elsif (params[@sign_combo]=="is null" || params[@sign_combo]=="is not null")
        render :inline=>%{
          <%= text_field('parameter_field',@combo_name,:disabled=>true) %>
        }
      else
        @list = dm_session[hiddenField]
          render :inline=>%{
           <%= select('parameter_field',@combo_name,@list) %>
        }
      end
    end

    def datetime_operator_sign_changed
      @sign_date = ""
      params.keys.each do |key|
        if key.to_s.index("sign")!=nil
          @sign_date = key.to_s
        end
      end
      @datetime_name = @sign_date.split("-")[0]
      if (params[@sign_date]=="is null" || params[@sign_date]=="is not null")
        render :inline=>%{
       <%= text_field('parameter_field', @datetime_name, :disabled=>true) %>
        }
      else
        @type = dm_session[@sign_date]
        if @type=="DateField"
          render :inline => %{
         <%= date_select('parameter_field',@datetime_name,:start_year=>1995)%>
          }
        elsif @type=="DateTimeField"
          render :inline => %{
         <%= datetime_select('parameter_field',@datetime_name,:start_year=>1995)%>
          }
        end
      end
      ###puts params.to_s
    end

    def extract_where_clause(query_statement)
      ret_string = ""
      if query_statement.to_s.upcase().index("WHERE") != nil
        stat              = query_statement
        where_index       = stat.to_s.upcase().index("WHERE")
        left_part         = stat[0,where_index + 5]
        right_part        = stat.gsub(left_part, "")
        first_brace_index = right_part.to_s.index("(")
        end_brace_index   = right_part.to_s.index(")")
        where_part        = right_part.to_s[first_brace_index +1, end_brace_index - first_brace_index-1]
        ret_string        += where_part
        ###puts "# " + where_part + " #"
      end
      return ret_string
    end


    def render_generic_grid(reload_url=nil, caption=nil)
      conn                    = User.connection
      @recordset              = conn.select_all(Globals.cleanup_where(dm_session[:search_engine_query_definition]))
      @stat                   = dm_session[:search_engine_query_definition]
      @columns_list           = dm_session[:columns_list]
      @grid_configs           = dm_session[:grid_configs]
      @se_grid_action_columns = dm_session[:search_engine_grid_action_columns]
      @multi_sel              = dm_session[:search_engine_multi_select]
      @reload_url             = reload_url || "http://#{request.host_with_port}/reports/reports/reload_generic_grid"
      @caption                = caption || 'view results'
      # logger.info ">>> query: #{dm_session[:search_engine_query_definition].inspect}"
      # logger.info ">>> cols: #{dm_session[:columns_list].inspect}"
      # logger.info ">>> action: #{dm_session[:search_engine_grid_action_columns].inspect}"

      if @recordset.length == 0
        render :inline => %{
              <script>
                 alert("No records found");
                 window.parent.close();
              </script>
        }
      else
        @se_summary_details_grid = false
        @se_grid = true

        render :inline => %{

          <% grid            = build_generic_grid(@recordset, @stat, @columns_list,@se_grid_action_columns,@multi_sel, @grid_configs)%>
          <% grid.caption    = @caption if grid.caption == DataGridJquery::DataGrid::DEFAULT_CAPTION %>
          <% grid.fullpage   = true %>
          <% grid.reload_url = @reload_url %>
          <% @header_content = grid.build_grid_data %>

          <%= grid.render_html %>
          <%= grid.render_grid %>
        }, :layout=>'content'
      end
    end

    def render_generic_show_records_grid
      dm_session[:columns_list] = nil if dm_session[:columns_list] != nil
      conn                      = User.connection
      @recordset                = conn.select_all(Globals.cleanup_where(dm_session[:show_records_query_definition].to_s))
      if @recordset.length == 0
        render :inline => %{
            <script>
               alert("No records found");
               window.parent.close();
            </script>
        }
      else
        @se_grid = false
        @se_summary_details_grid = true

        render :inline => %{
                <% grid            = build_generic_show_records_grid(@recordset)%>
                <% grid.caption    = 'view results' %>
                <% grid.fullpage   = true %>
                <% @header_content = grid.build_grid_data %>

                <%= grid.render_html %>
                <%= grid.render_grid %>
        }, :layout => 'content'
      end
    end

    def render_summary_grid(reload_url=nil, caption=nil)
      statement   = dm_session[:search_engine_query_definition]
      conn        = User.connection
      @recordset  = conn.select_all(Globals.cleanup_where(dm_session[:search_engine_query_definition]))
      @reload_url = reload_url || "http://#{request.host_with_port}/reports/reports/reload_generic_grid"
      if @recordset.length == 0
        render :inline => %{
            <script>
               alert("No records found");
               window.parent.close();
            </script>
        }
      else
        @se_summary_details_grid = false
        @se_grid = true
        @caption = caption || 'view summary results'

        render :inline => %{
              <% grid            = build_summary_grid(@recordset)%>
              <% grid.caption    = @caption %>
              <% grid.fullpage   = true %>
              <% grid.reload_url = @reload_url %>
              <% @header_content = grid.build_grid_data %>

              <%= grid.render_html %>
              <%= grid.render_grid %>
        }, :layout => 'content'
      end
    end

    def clear_search_form
      dm_session[:parameter_fields_values] = nil
      ###puts "PUCA : #{dm_session[:report_name]}"
      dm_session[dm_session[:report_name] + "_default_values"] = nil if(dm_session[:report_name])
      #dm_session[dm_session[:report_name] + "_static_values"] = nil if(dm_session[:report_name]) # NO, No, Not static values!!!!
      dm_session[:redirect]        = true
      dm_session[:redirect_method] = params[:id]
      relaunch_search_form
    end

    def relaunch_search_form(user_defined_report_name=nil)
      dm_session[:parameter_query]      = dm_session[:full_parameter_query]
      dm_session[:full_parameter_query] = dm_session[:full_parameter_query].clone
      @report_file_name                 = dm_session[:report_name]
      build_parameter_fields_form(dm_session[:search_fields], user_defined_report_name)
    end

    def build_parameter_fields_form(fields, user_defined_report_name=nil)

      field_configs = Array.new
      config_index  = 0
      fields.each do |f|
        if f.has_key?(:list)
          list            = f.fetch(:list)
          field_type      = f.fetch(:field_type)
          field_name      = f.fetch(:field_name)
          field_caption   = f.fetch(:caption)
          list_sorted     = f.fetch(:sorted, false)
          list_searchable = f[:searchable].nil? ? true : f[:searchable]
          if list.class == Array
            dropdown_list = list
            field_configs[config_index] = {:field_type => field_type, :field_name => field_name, :list => dropdown_list, :caption => field_caption, :sorted => list_sorted, :searchable => list_searchable}
          else
          dropdown_list = []
          if list.index('*') || list.count(',') > 1
            raise("The form could not be built because a lookup field returns more than two columns. <BR> Re-define the file")
          else
            conn      = User.connection
            results   = conn.select_all(list)
            # Get the list of fields (between SELECT [DISTINCT] and FROM)...
            fieldlist = list.sub(/select\s+(?:distinct)?\s*/i, '').sub(/\sfrom.*/i, '')

            # Get the column names of each field...
            fields    = fieldlist.split(',').map {|a| a.strip.split(' ').last.split('.').last }

            if results.nil?
              dropdown_list << "<empty>"
            else
              results.each do |record|
                if fields.size == 2
                  dropdown_list << [record[fields[0]], record[fields[1]]]
                else
                  dropdown_list << record[fields[0]]
                end
              end
            end

            field_configs[config_index] = {:field_type => field_type, :field_name => field_name, :list => dropdown_list, :caption => field_caption, :sorted => list_sorted, :searchable => list_searchable}
            end
          end
        else
          field_type                  = f.fetch(:field_type)
          field_name                  = f.fetch(:field_name)
          field_caption               = f.fetch(:caption)
          field_configs[config_index] = {:field_type=>field_type, :field_name =>field_name, :caption=>field_caption}
          field_configs[config_index].store(:lookup_search_file,f.fetch(:lookup_search_file)) if(f.has_key?(:lookup_search_file))
          field_configs[config_index].store(:select_column_name,f.fetch(:select_column_name)) if(f.has_key?(:select_column_name))
          field_configs[config_index].store(:lookup_search_uri,f.fetch(:lookup_search_uri)) if(f.has_key?(:lookup_search_uri))
          field_configs[config_index].store(:send_fields,f.fetch(:send_fields)) if(f.has_key?(:send_fields))
          field_configs[config_index].store(:submit_to,f.fetch(:submit_to)) if(f.has_key?(:submit_to))
        end

        #-----------------------------------------------
        #          1. Luks data miner Addtion                  ----
        #-----------------------------------------------
        if (dm_session[@report_file_name + "_static_values"])
          if((field_name_partitions = field_name.split('.')).length == 2)
            field_name = field_name_partitions[1]
          end
          if (dm_session[@report_file_name + "_static_values"].has_key?(field_name.to_s))
            field_configs[config_index][:static_value] = dm_session[@report_file_name + "_static_values"][field_name]
            ###puts "STATIC VALUE FOUND  === " + field_configs[config_index][:static_value].to_s
          end
        end

        #-----------------------------------------------
        #          2. hans data miner Addtion                  ----
        #-----------------------------------------------
        if (dm_session[@report_file_name + "_default_values"])

          if (dm_session[@report_file_name + "_default_values"].has_key?(field_name.to_s))
            field_configs[config_index][:field_value] = dm_session[@report_file_name + "_default_values"][field_name]
            ###puts "DEFAULT VALUE FOUND  === " + field_configs[config_index][:field_value].to_s
            dm_session[:parameter_fields_values] = Array.new if !dm_session[:parameter_fields_values] ||dm_session[:parameter_fields_values].length() == 0
            dm_session[:parameter_fields_values].push(field_configs[config_index])
          end

        end
        #-----------------------------------------------
        #          2. Luks data miner Addtion                  ----
        #-----------------------------------------------
        config_index = config_index + 1
      end

      dm_session[:parameter_fields] = nil if dm_session[:parameter_fields] != nil
      dm_session[:parameter_fields] = field_configs
      @user_defined_report_name     = user_defined_report_name
      layout                        = 'tree_node_content'
      layout                        = dm_session['se_layout'] if dm_session['se_layout']
      render :template=>'reports/reports/generic_parameter_fields_search_form', :layout=> layout

    end


    def view_details
      record_id = params[:id]
      @table_name = nil
      if dm_session[:main_table_name] != nil
        @table_name = dm_session[:main_table_name]
      elsif dm_session[:main_table] != nil
        @table_name = dm_session[:main_table]
      else
        @table_name = dm_session[:table_name]
      end
      @record  = nil
      @caption = "view details of " + @table_name.to_s + " record"
      begin
        @record = Inflector.camelize(Inflector.singularize(@table_name)).constantize.find(:first, :conditions=>['id=?', record_id])
      rescue NameError
        begin
          @record = Inflector.camelize(@table_name).constantize.find(:first, :conditions=>['id=?', record_id])
        rescue
          raise "Model \n#{@table_name}\n not known!"
        end
      end
      if @record.nil?
        flash[:notice] = "no record(s) found"
        render :inline => %{
        <% @content_header_caption = "'no record(s) found'"%>

        }, :layout => 'content'
      else
        render :inline => %{
      <% @content_header_caption = "'#{@caption}'"%>

      <%= build_view_record_form(@record,'return_to_grid','back',@table_name)%>

        }, :layout => 'content'
      end
    end

    def view_details_on_child_grid
      record_id   = params[:id]
      @table_name = dm_session[:child_table]
      @record     = nil
      @caption    = "view details of " + @table_name.to_s + " record"
      begin
        @record = Inflector.camelize(Inflector.singularize(@table_name)).constantize.find(:first, :conditions=>['id=?', record_id])
      rescue NameError
        begin
          @record = Inflector.camelize(@table_name).constantize.find(:first, :conditions=>['id=?', record_id])
        rescue
          raise "Model \n#{@table_name}\n not known!"
        end
      end
      if @record.nil?
        flash[:notice] = "no record(s) found"
        render :inline => %{
        <% @content_header_caption = "'no record(s) found'"%>

        }, :layout => 'content'
      else
        render :inline => %{
        <% @content_header_caption = "'#{@caption}'"%>

        <%= build_view_record_form(@record,'close_opened_window','close',@table_name)%>

        }, :layout => 'content'
      end
    end

    def show_records
      id          = params[:id]
      ###puts id.to_s + " THIS IS ID FROM SHOW RECORDS"
      test_conn   = User.connection
      @table_name = dm_session[:table_name]

      where_clause_string = ""
      original_where      = dm_session[:search_engine_where_clause].to_s
      group_by_where      = ""

      if id.to_s != ""
        if id.index("!") != nil
          cols_array = id.split("!")
          cols_array.each do |col_val|
            column = col_val.split("-3457-")[0]
            value  = col_val.split("-3457-")[1]
            value  = value.to_s.gsub("se2345se"," ") if value.to_s.index("se2345se") != nil
            if group_by_where == ""
              group_by_where += column.to_s + " = " + "'" +  value.to_s + "'"
            else
              group_by_where += " and " + column.to_s + " = " + "'" +  value.to_s + "'"
            end

          end
        else
          column = id.to_s.split("-3457-")[0]
          value  = id.to_s.split("-3457-")[1]
          value  = value.to_s.gsub("se2345se"," ") if value.to_s.index("se2345se") != nil
          if group_by_where == ""
            group_by_where += column.to_s + " = " + "'" +  value.to_s + "'"
          else
            group_by_where += " and " + column.to_s + " = " + "'" +  value.to_s + "'"
          end

        end
      end

      if original_where != "" || group_by_where != ""
        if original_where != ""
          where_clause_string += "((" + original_where.to_s + ")"
        else
          where_clause_string += "((true)"
        end
        if group_by_where != ""
          where_clause_string += " and (" + group_by_where.to_s + ")"
        else
          where_clause_string += " and (true)"
        end
        where_clause_string += ")"
      end


      #puts "THIS IS SUMMARY WHERE CLAUSE : " + where_clause_string
      #puts "THIS IS SUMMARY TABLE NAME : " + @table_name.to_s
      my_query = ""
      if where_clause_string == ""
        my_query += "select * from " + @table_name
      else
        my_query += "select * from " + @table_name + " where" + where_clause_string
      end
      ###puts my_query
      # if my_query.to_s.upcase.index("LIMIT ") == nil
      #   my_query += " LIMIT 1000"
      # end
      my_query << " LIMIT #{Globals.search_engine_max_rows || 1000}"
      ###puts my_query

      dm_session[:show_records_query_definition] = nil if dm_session[:show_records_query_definition] != nil
      dm_session[:show_records_query_definition] = my_query
      #dm_session[:search_engine_query_definition] = my_query
      render :inline=> %{
          <% @url_base = "http://" + request.host_with_port + "/" + "reports/reports/render_generic_show_records_grid" %>

          <script>
             window.open("<%=@url_base%>", "records","width=850,height=400,top=200,left=200,toolbar=1,menubar=1,status=1,scrollbars=1,resizable=1" );
          </script>
          <script>
             history.back()
          </script>
      }, :layout=>'content'
    end

    def view_in_opener
      ids                  = params[:id].to_s.split("-")
      @identifier          = ids[0]
      @previous_model_name = ids[1]
      @model_name          = Inflector.tableize(ids[2])
      @record_id           = ids[3]
      @record_instance     = nil
      @caption             = nil
      if @identifier.to_s.upcase().strip() == "PARENT"
        if (@model_name.to_s.upcase().strip()!= @previous_model.to_s.upcase().strip())
          @caption = "view details of " + @model_name.to_s + " record belonging to " + @previous_model_name.to_s + " record"
        else
          @caption = "view details of " + @model_name.to_s + " record"
        end
        begin
          @record_instance = Inflector.camelize(Inflector.singularize(@model_name)).constantize.find(:first, :conditions=>['id=?', @record_id])
        rescue ActiveRecord::StatementInvalid
          @record_instance = nil
        end
        if @record_instance==nil
          flash[:notice]="no record(s) found"
          render :inline=>%{
           <% @content_header_caption = "'no record(s) found'"%>
          }, :layout=>'content'
        else
          render :inline => %{
            <% @content_header_caption = "'#{@caption}'"%>

            <%= build_view_record_form(@record_instance,'close_opened_window','close',@model_name)%>

          }, :layout => 'content'
       end
     else
       dm_session[:columns_list] = nil if dm_session[:columns_list] != nil
       @child_records = nil
       if(ids.size > 4)
        @parent_id = ids[4]
       else
       @parent_id = Inflector.singularize(@previous_model_name).to_s + "_id"
       end
       if @model_name.to_s.strip()=="track_slms_indicators"
         if @parent_id.to_s.strip() == "rmt_variety_id"
           @parent_id = "variety_id"
         end
       end

       begin
         @child_records = Inflector.camelize(Inflector.singularize(@model_name)).constantize.find(:all, :conditions=>["#{@parent_id}=?", @record_id])
       rescue StandardError => e
         # Check if this is a HABTM relationship.
         if e.message.include?(' does not exist') # Might be a HABTM relationship if the xyz_id column is not on the table.
           @child_records = Inflector.camelize(Inflector.singularize(@previous_model_name)).constantize.find(:first, :conditions=>["id=?", @record_id]).send(@model_name)
         else
           raise
         end
       end

       @caption = "list of " + @model_name.to_s + " records belonging to " + @previous_model_name.to_s + " record"
       if @child_records.length()==0
         flash[:notice]="no record(s) found"
         render :inline=>%{
           <% @content_header_caption = "'no record(s) found'"%>
         }, :layout=>'content'
       else
         dm_session[:child_table] = @model_name

          render :inline => %{
            <% grid            = build_child_records_grid(@child_records)%>
            <% grid.caption    = '#{@caption}' %>
            <% grid.fullpage   = true %>
            <% @header_content = grid.build_grid_data %>

            <%= grid.render_html %>
            <%= grid.render_grid %>
          }, :layout => 'content'
        end
      end
    end

    def return_to_grid
      #dm_session[:search_engine_query_definition] = dm_session[:temporary_search_engine_query_definition]
      @stat                   = dm_session[:search_engine_query_definition]
      @columns_list           = dm_session[:columns_list]
      @grid_configs           = dm_session[:grid_configs]
      @se_grid_action_columns = dm_session[:search_engine_grid_action_columns]
      conn                    = User.connection
      @recordset              = nil
      if dm_session[:grid_type] == "summary"
        @recordset = conn.select_all(Globals.cleanup_where(dm_session[:show_records_query_definition]))
        render_generic_show_records_grid
      else
        @recordset = conn.select_all(Globals.cleanup_where(dm_session[:search_engine_query_definition]))

        render :inline => %{
                <% grid            = build_generic_grid(@recordset, @stat, @columns_list,@se_grid_action_columns, nil, @grid_configs)%>
                <% grid.caption    = 'view results' if grid.caption == DataGridJquery::DataGrid::DEFAULT_CAPTION %>
                <% grid.fullpage   = true %>
                <% grid.reload_url = "http://#{request.host_with_port}/reports/reports/reload_generic_grid" %>
                <% @header_content = grid.build_grid_data %>

                <%= grid.render_html %>
                <%= grid.render_grid %>
        }, :layout => 'content'
      end

    end

    # Return a table from the results of executing a MyView report.
    # For use in supplying a webquery to a spreadsheet.
    # To see what the saved report looks like, add ?debug=true to the end of the url
    def webquery
      id         = params[:id]
      debug_mode = params[:debug]
      if id && user_defined_report = UserDefinedReport.find(id)
        if debug_mode
          render :text => user_defined_report.render_for_debug
        else
          report_state      = user_defined_report.view_state
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
          dm_session[:main_table_name]                = report_state_hash[:main_table_name] || report_state_hash[:main_table]
          dm_session[:table_name]                     = report_state_hash[:table_name]
          dm_session[:report_name]                    = report_state_hash[:report_name]
          dm_session[:operator_signs]                 = report_state_hash[:operator_signs]
          dm_session[:columns_list]                   = report_state_hash[:columns_list]

          dm_session[:redirect_method]                = nil
          dm_session[:redirect]                       = nil

          parms = {}
          user_defined_report.setup_params(parms)
          statement = apply_functions(user_defined_report.sql_statement(report_state_hash, true), parms)
          if statement =~ / JOIN/i
            dm_session[:table_name] = user_defined_report.value_from_report_hash(:main_table_name) ||
              user_defined_report.value_from_report_hash(:main_table)
          else
            table_name = FieldParser.get_table_name(statement)
            dm_session[:table_name] = table_name
          end

          where_clause = ''
          if dm_session[:grid_type] == "summary" && statement =~ / WHERE/i
            where_clause = FieldParser.get_where_clause(statement).split("|splitter|")[0].to_s
          end

          dm_session[:search_engine_where_clause]        = nil if dm_session[:search_engine_where_clause] != nil
          dm_session[:search_engine_where_clause]        = where_clause
          dm_session[:search_engine_query_definition]    = statement
          #dm_session[:search_engine_query_definition]    = apply_functions(@user_defined_report.sql_statement(report_state_hash))
          dm_session[:search_engine_grid_action_columns] = []
          dm_session[:search_engine_multi_select]        = nil
          # if dm_session[:grid_type] == "summary"
          #   render_summary_grid("http://#{request.host_with_port}#{request.request_uri}")
          # else
          #   render_generic_grid("http://#{request.host_with_port}#{request.request_uri}")
          # end
          render :text => user_defined_report.render_for_webquery( statement, dm_session[:group_by_columns] )
        end
      else
        render :text => %{
        <table><tr><th>An error occurred</th></tr>
        <tr><td>Could not find saved view with id = '#{id}'.</td></tr>
        </table>
        }
      end
    end
    # Read a dataminer yml file and return its query and grid configs.
    def retrieve_search_engine_query_with_configs(report_name)
      report_file_name = report_name.sub(".yml", "")
      report_file      = Globals.get_reports_location + "/" + report_name
      yml              = YAML::load(File.read(report_file))
      stat             = yml['query'].gsub("\n", ' ')
      grid_configs     = yml['grid_configs']
      columns_list     = list_of_cols_from_stat(stat)
      return stat, grid_configs, columns_list
    end

    # Read a dataminer yml file and return its query.
    # Usually you'll want to set the dataminer session variables for the grid.
    # If not, make +set_grid_configs+ false.
    def retrieve_search_engine_query(report_name, set_grid_configs=true)
      stat, grid_configs, columns_list = retrieve_search_engine_query_with_configs(report_name)
      if set_grid_configs
        dm_session[:grid_configs] = grid_configs
        dm_session[:columns_list] = columns_list
      end
      stat
    end

    # Get the column names from an SQL statement.
    def list_of_cols_from_stat(stat)
      # colarr = stat.gsub(/\(SUBQSTART.+?SUBQEND\)/, 'SUBQUERY_PLACEHOLDER').split(/\A\s*select\s/i)
      # return nil if colarr.length < 2
      # colarr = colarr[1].split(/\sfrom\s/i)
      # return nil if colarr.length < 2
      # colarr = colarr[0].split(',')
      # colarr.map {|c| c.split('.').last.split(' ').last }

      # Grab everything between SELECT and the last FROM. NB. This will fail if there is a subquery in the WHERE clause or in a JOIN.
      # Regex is modified by m for multiline and i for case insensitive.
      match = stat.match(/\A\s*select\s?(.+)(\sfrom\s)/mi)
      # Need to strip FUNCTION(field,1,2) out, but NOT COUNT(id)
      # If there is a match, replace any functions that may include commas, then split columns by commas and return an array of the last word in each column.
      # Function regex:
      # \w+        Start with words (SUBSTR)
      # \s?        Might be a space or tab or two between the function name and parenthesis
      # \(         Match an open parenthesis
      # [^\)]+?    The ( can be followed by 1 or more of any character except ")"
      # ,{1}       There must be exactly one ","
      # .+?        ...followed by one or more of any character
      # \)         ...and ending with a closing parenthesis
      match.nil? ? nil : match[1].gsub(/\w+\s?\([^\)]+?,{1}.+?\)/, 'HIDEFUNC').split(',').map {|c| c.split('.').last.split(' ').last }
    end

    # ------------
    # Excel export
    # ------------
    # See notes in dev tools | show_reference action for more information.
    def render_excel_in_sheets(filename)
      s = render_to_string('shared/xls_xml_sheet')
      send_data s, :filename => filename, :type => 'application/vnd.ms-excel'
    end

  end # DataMinerActions

end
