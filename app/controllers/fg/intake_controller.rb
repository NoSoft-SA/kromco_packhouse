class Fg::IntakeController < ApplicationController
  def program_name?
    "intake"
  end

  def bypass_generic_security?
    true
  end

  def set_printer
     @content_header_caption = "'select a printer'"

     render :inline => %{
                        <%= build_printer_selection_form()%>
                        }, :layout => 'content'
  end
 

  def set_printer_submit
    printer_name = params['printer']['friendly_name']
    printer = Printer.find_by_friendly_name(printer_name)


    session[:intake_printer] =  printer.system_name

    redirect_to_index("printer set to: " + printer_name + "   (system name is: " + printer.system_name + ")")

  end

  def new_intake
    session[:intake_mode] = "new"
    @content_header_caption = "'create new intake(consignment)'"
    @submit_caption = 'create_intake'
    @submit_action = 'create_intake'
    @is_edit = false
    render_intake
  end

  def render_intake
    session[:is_view] = false
    render :inline => %{
                        <%= build_intake_form(@intake_headers_production,@submit_action,@submit_caption,@is_edit,@is_create_retry)%>
                        }, :layout => 'content'
  end

  def intake_location_type_code_search_combo_changed
    location_type_code = get_selected_combo_value(params)
    session[:intake_search_form][:location_type_code_combo_selection] = location_type_code
    @location_codes = Location.find_by_sql("select distinct location_code from locations where location_type_code = '#{location_type_code}'").collect { |l| [l.location_code] }
    @location_codes.unshift("<empty>")
    render :inline => %{
                          <%= select('intake_headers_production','location_code',@location_codes) %>
                        }
  end

  def create_intake
    begin
      @intake_headers_production = IntakeHeadersProduction.new(params[:intake_headers_production])
      @intake_headers_production.intake_header_number = MesControlFile.next_seq_web(MesControlFile::PRODUCTION_INTAKE)
      @intake_headers_production.revision_number = 1
      @intake_headers_production.intake_type_code = "FI"
      if @intake_headers_production.save
        @intake_headers_production.change_header_status('INTAKE_HEADER_CREATED', session[:user_id].user_name)
        @intake_headers_production.update
        render_edit_intake
      else
        @is_create_retry = true
        new_intake
      end
    rescue
      handle_error("intake record could not be created")
    end
  end

  def render_edit_intake
    session[:intake_mode] = "edit"
    @is_edit = true
    @content_header_caption = "'edit intake(consignment)'"
    @submit_caption = 'accept_consignment'
    @submit_action = 'accept_consignment'
    session[:intake_headers_production] = @intake_headers_production
    ###@intake_headers_production.set_header_status('INTAKE_HEADER_ACCEPTED',session[:user_id].user_name)##TEST
    render_intake
  end

  def show_representative_pallets
    header_marketing_org = Organization.find_by_short_description(session[:intake_headers_production].organization_code)
    #-----<instance> organization.need_gtin_check?
    @has_gtin_check_rule = header_marketing_org.need_gtin_check?
    #end method

    #<instance> IntakeHeadersProduction.find_intake_pallets
    query = ""
    #---written back as input-output parammeter
    @intake_header_pallets = session[:intake_headers_production].find_intake_pallets(query)
    #--end method#--
    session[:intake_header_pallets_query] = query
#puts "consignment apllets tyhwiri = " + session[:intake_header_pallets_query].to_s
    url =  request.host_with_port + "/" + request.path_parameters['controller'].to_s + "/import_pallets/" + session[:intake_headers_production].id.to_s #params[:id].to_s#add action and id
    #--------------
    if !session[:is_view]
      link = "<a style='text-decoration:underline;cursor:pointer;' href='http://#{url}' />import pallets"
    else
      link = ""
    end
    #--------------
    @child_form_caption = ["consignment_pallets", "pallets for this consignment " + link]

    #-------------------------------------
    # <instance>IntakeHeadersProduction.calc_missing_gtin_pallets
    #----------------------------------
    session["#{session[:intake_headers_production].intake_header_number}_invalid_pallets"] = Hash.new

    if (@intake_header_pallets.length > 0)
      if (@has_gtin_check_rule)
        session["#{session[:intake_headers_production].intake_header_number}_invalid_pallets"] = session[:intake_headers_production].calc_missing_gtin_pallets(@intake_header_pallets)
      end
     
#      puts "session[#{session[:intake_headers_production].intake_header_number}_invalid_pallets][:tm] = " + session["#{session[:intake_headers_production].intake_header_number}_invalid_pallets"][:tm].to_s
#      puts "session[#{session[:intake_headers_production].intake_header_number}_invalid_pallets][:gtin] = " + session["#{session[:intake_headers_production].intake_header_number}_invalid_pallets"][:gtin].to_s
      #method end#
      @is_view = session[:is_view]
      render :inline => %{
      <% grid            = build_list_intake_header_pallets_grid(@intake_header_pallets,@is_view,@has_gtin_check_rule) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    else
      render :inline => %{
                            <script>
                              alert('no records were found');
                            </script>
                          }, :layout => 'content'
    end
  end

  def find_gtin
    query = session[:intake_header_pallets_query]
    @intake_header_pallets = ActiveRecord::Base.connection.select_all(query)
    selected_con_pallet = nil
    if (@intake_header_pallets.length > 0)
      @intake_header_pallets.each do |con_pallet|
        if (con_pallet["id"].to_s == params[:id].to_s)
          selected_con_pallet = con_pallet
          break
        end
      end
    end

    search_criteria = Hash.new
#    search_criteria[""] = session[:intake_headers_production].created_on.to_s
    search_criteria["organization_code"] = session[:intake_headers_production].organization_code.to_s
    search_criteria["commodity_code"] = selected_con_pallet["commodity_code"].to_s
    search_criteria["marketing_variety_code"] = selected_con_pallet["variety_short_long"].split("_")[0].to_s
    search_criteria["brand_code"] = selected_con_pallet["brand_code"].to_s
    search_criteria["old_pack_code"] = selected_con_pallet["old_pack_code"].to_s
    search_criteria["actual_count"] = selected_con_pallet["actual_size_count_code"].to_s
    search_criteria["grade_code"] = selected_con_pallet["grade_code"].to_s
    search_criteria["inventory_code"] = selected_con_pallet["inventory_code"].split('_')[0].to_s
#    puts "WTF? = " + selected_con_pallet["inventory_code"].to_s
    session[:gtin_search_criteria] = search_criteria
    @the_url =  "http://" + request.host_with_port + "/" + request.path_parameters['controller'].to_s + "/show_representative_pallets/" +session[:intake_headers_production].consignment_note_number
    render :inline=>%{
                      <script> alert("you can go to raw_materials/track_indicators/search_gtins to find this gtin search"); window.location.href="<%=@the_url%>";</script>}, :layout=>'content'
#    search_criteria["mark_code"] =
#    search_criteria[""] = selected_con_pallet["inventory_code"].split('_')[0].to_s

#    puts "FOUND IT = " + selected_con_pallet["id"].to_s
  end

  def log_pallet_document(pallet_id,doc_number,doc_type,action)
    pallet_document_log = PalletDocumentLog.new({:pallet_id=>pallet_id,:document_number=>doc_number,:document_type=>doc_type,:program_name=>'intake_header_production',:created_at=>Time.new().to_formatted_s(:db),:user_name=>session[:user_id].user_name,:action=>action})
    pallet_document_log.save
  end
  
  def remove_intake_header_pallet
    pallet = Pallet.find(params[:id])
    if (pallet.pallet_number != session[:intake_headers_production].representative_pallet_number)
      params[:id] = pallet.consignment_note_number
      log_pallet_document(pallet.id,session[:intake_headers_production].consignment_note_number,session[:intake_headers_production].intake_type_code,'PALLET_REMOVED')
      pallet.update_attribute(:consignment_note_number, nil)      
      show_representative_pallets
    else
#      intake_document_pallets = Pallet.find_by_sql("select * from pallets where consignment_note_number = '#{session[:intake_headers_production].consignment_note_number}'")
#      intake_document_pallets.each do |doc_pallet|
#        log_pallet_document(doc_pallet.id,session[:intake_headers_production].consignment_note_number,session[:intake_headers_production].intake_type_code,'PALLET_REMOVED')
#      end
      ActiveRecord::Base.connection.execute("insert into pallet_document_logs (pallet_id,document_number,document_type,program_name,user_name,created_at,action)
                      select pallets.id, '#{session[:intake_headers_production].consignment_note_number}', '#{session[:intake_headers_production].intake_type_code}','intake_header_production','#{session[:user_id].user_name}','#{Time.new().to_formatted_s(:db)}','PALLET_REMOVED'
                     from pallets where pallets.consignment_note_number = '#{session[:intake_headers_production].consignment_note_number}'")
      num_rows_updated = Pallet.update_all(ActiveRecord::Base.extend_set_sql_with_request("consignment_note_number = Null","pallets"), "consignment_note_number = '#{session[:intake_headers_production].consignment_note_number}'")
      puts "updated these rows = " + num_rows_updated.to_s
      session[:intake_headers_production].representative_pallet_number = nil
      session[:intake_headers_production].representative_carton_number = nil
      session[:intake_headers_production].update
      @the_url =  "http://" + request.host_with_port + "/" + request.path_parameters['controller'].to_s + "/edit_intake/" + session[:intake_headers_production].id.to_s
      render :inline=>%{
                          <script>
                           window.parent.location.href="<%=@the_url%>";
                          </script>
                        }, :layout=>'content'
    end
  end

  def import_pallets
    dm_session[:parameter_fields_values] = nil
    @intake_headers_production = IntakeHeadersProduction.find(params[:id])
    session[:intake_headers_production] = @intake_headers_production

    static_field_recs = OrganizationRule.get_rules(@intake_headers_production.organization_code.to_s, 'intake_pallet_match', true)

    dm_session["get_pallets_by_carton_static_values"] = {"pallets.is_depot_pallet"=>@intake_headers_production.depot_pallet.to_s, "cartons.organization_code"=>@intake_headers_production.organization_code.to_s,"pallets.account_code"=>@intake_headers_production.account_code.to_s} #,"test_field2" => "test field2 static","test_field3" => "test field3 static"}
    current_header_rep_pallet = get_current_header_rep_pallet
    for static_field_rec in static_field_recs
      yml_field = static_field_rec.rule_code
      yml_field =   static_field_rec.description + "." + static_field_rec.rule_code if static_field_rec.description
      static_value =  current_header_rep_pallet[static_field_rec.rule_code]
      dm_session["get_pallets_by_carton_static_values"].store(yml_field, static_value)

    end

    build_remote_search_engine_form("get_pallets_by_carton.yml", "render_consignment_pallets_grid")
    dm_session[:redirect] = true
  end

  def render_consignment_pallets_grid
    pallets_to_import_rec_set = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    filtered_rec_set = apply_org_rules_filters(pallets_to_import_rec_set)
    @duplicate_free_rep_pallet_rec_set = remove_duplicates(filtered_rec_set)
    session[:import_pallet_rec_set] = @duplicate_free_rep_pallet_rec_set
    @multi_select = true
    flash[:error] = @err_pallets_msg if @err_pallets_msg
    render_consignment_pallet_selection_grid
#    render :inline=>%{<script>window.close();window.opener.frames[1].location.href="http://localhost:3000/fg/intake/list_intake_header_pallets";</script>},:layout=>'content'
  end

  def submit_selected_pallets
    @selected_pallets = selected_records?(session[:import_pallet_rec_set], nil, true)
    num_rows_updated = Pallet.update_all(ActiveRecord::Base.extend_set_sql_with_request("consignment_note_number = Null","pallets"), "consignment_note_number = '#{session[:intake_headers_production].consignment_note_number}' and pallet_number != '#{session[:intake_headers_production].representative_pallet_number}'")
    puts "dropped pallets = " + num_rows_updated.to_s
    pallet_ids = Array.new
    @selected_pallets.each do |selected_pallet|
      puts "selected_pallet = " + selected_pallet["id"].to_s
      pallet_ids.push(selected_pallet["id"].to_s)
    end
    Pallet.bulk_update({:consignment_note_number=>"'"+session[:intake_headers_production].consignment_note_number.to_s+"'"}, "id", pallet_ids, nil)
    @intake_headers_production = session[:intake_headers_production]
    render_edit_intake
  end

  def get_current_header_rep_pallet
    intake_header_pallets = ActiveRecord::Base.connection.select_all(session[:intake_header_pallets_query])
    intake_header_pallets.each do |header_pallet|
      if (header_pallet.pallet_number.to_s == session[:intake_headers_production].representative_pallet_number.to_s)
        return header_pallet
      end
    end
    return nil
  end

  def apply_org_rules_filters(pallets_to_import_rec_set)
    @err_pallets_msg = nil
    filtered_pallets_to_import_rec_set = Array.new
    organization_rules = OrganizationRule.get_rules(session[:intake_headers_production].organization_code, 'intake_pallet_match')
    current_header_rep_pallet = get_current_header_rep_pallet
    pallets_to_import_rec_set.each do |pallet_to_import|
      all_rules_passed = true
      organization_rules.each do |org_rule|
        if (current_header_rep_pallet.send(org_rule) != pallet_to_import.send(org_rule))
          all_rules_passed = false
          break
        end
      end

      if ((pallet_to_import.rw_run_id != nil)  || (pallet_to_import.ppecb_inspection_id == nil))
        @err_pallets_msg = "The following pallets were left out from the list of pallets: <BR>" if !@err_pallets_msg
        @err_pallets_msg += "<BR>#{pallet_to_import.pallet_number}: "
        if pallet_to_import.rw_run_id != nil
          @err_pallets_msg += " pallet is active in reworks"
#        elsif pallet_to_import.date_time_offloaded == nil
#          @err_pallets_msg += " pallet has not been offloaded yet"
        elsif pallet_to_import.ppecb_inspection_id == nil
          @err_pallets_msg += " pallet has not been inspected yet"
        end
#          pallets_to_import_rec_set.delete(pallet_to_import)
      else
        if (all_rules_passed)
          filtered_pallets_to_import_rec_set.push(pallet_to_import)
#          puts " 3 PASSED = " + pallet_to_import.ppecb_inspection_id.class.to_s + "  ||   " + pallet_to_import.pallet_number.to_s
        end
      end
    end
    return filtered_pallets_to_import_rec_set
  end

  def view_representative_carton
    @view_object = Carton.find_by_carton_number(params[:id])
    render_view_object_form
  end

  def view_representative_pallet
    @view_object = Pallet.find_by_pallet_number(params[:id])
    render_view_object_form
  end

  def render_view_object_form
    render :inline => %{
                        <%= build_view_carton_pallet_form(@view_object,nil,'')%>
                       }, :layout=>'content'
  end

  def representative_pallet_search
    dm_session[:parameter_fields_values] = nil
    @intake_headers_production = IntakeHeadersProduction.find(params[:id])
    dm_session["get_pallets_by_carton_static_values"] = {"pallets.is_depot_pallet"=>@intake_headers_production.depot_pallet.to_s, "cartons.organization_code"=>@intake_headers_production.organization_code.to_s} #,"pallets.account_code"=>@intake_headers_production.account_code.to_s,"test_field2" => "test field2 static","test_field3" => "test field3 static"}
#    if(@intake_headers_production.account_code && @intake_headers_production.account_code.to_s != "" )
#      session["get_pallets_by_carton_static_values"].store("pallets.account_code",@intake_headers_production.account_code.to_s)
#    end
    build_remote_search_engine_form("get_pallets_by_carton.yml", "render_representative_pallets_grid")
    dm_session[:redirect] = true
  end

  def render_representative_pallets_grid
    rep_pallet_rec_set = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    filtered_rep_pallet_rec_set = representative_pallet_filters(rep_pallet_rec_set)
    @duplicate_free_rep_pallet_rec_set = remove_duplicates(filtered_rep_pallet_rec_set)
    @multi_select = nil
    flash[:error] = @err_pallets_msg if @err_pallets_msg
    render_consignment_pallet_selection_grid
  end

  def render_consignment_pallet_selection_grid
    if (@duplicate_free_rep_pallet_rec_set.length > 0 && @duplicate_free_rep_pallet_rec_set[0].keys != nil)
      #================================
      #===========weekend work=========
      #================================
      session[:duplicate_free_rep_pallet_rec_set] = @duplicate_free_rep_pallet_rec_set
      #================================
      #===========weekend work=========
      #================================
      render :inline => %{
      <% grid            = build_consigment_pallet_s_grid(@duplicate_free_rep_pallet_rec_set,@multi_select) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    else
      render :inline => %{
                            <script>
                              alert('no pallet records were found');
                            </script>
                          }, :layout => 'content'
    end
  end

  def representative_pallet_filters(rec_set)
    filtered_rec_set = Array.new
    examined = 0
    @err_pallets_msg = nil
    rec_set.each do |rec|
      examined += 1
#      puts "pallet_number to be examined = " + rec.pallet_number.to_s
      if ((rec.rw_run_id == nil)  && (rec.ppecb_inspection_id != nil))
        filtered_rec_set.push(rec)
      else
        @err_pallets_msg = "The following pallets were left out from the list of pallets: <BR>" if !@err_pallets_msg
        @err_pallets_msg += "<BR>#{rec.pallet_number}: "
        if rec.rw_run_id != nil
          @err_pallets_msg += " pallet is active in reworks"
#        elsif rec.date_time_offloaded == nil
#          @err_pallets_msg += " pallet has not been offloaded yet"
        elsif rec.ppecb_inspection_id == nil
          @err_pallets_msg += " pallet has not been inspected yet"
        end
#        puts "re is a = " + rec.class.name#cool
#        puts "pallet_number in grid = " + rec.pallet_number.to_s
      end
    end
#    puts "Examined recs = " + examined.to_s
    return filtered_rec_set
  end

  def remove_duplicates(rec_set)
    temp = Array.new
    filtered_rec_set = Array.new
    rec_set.each do |rec|
#      puts "checking this dup = " + rec.pallet_number.to_s
      if (!temp.include?(rec.pallet_number))
#        puts "     didn't find any dup for = " + rec.pallet_number.to_s
        temp.push(rec.pallet_number)
        filtered_rec_set.push(rec)
      end
    end
    return filtered_rec_set
  end

  def select_representative_pallet
    #================================
    #===========weekend work=========
    #================================
    @msg = "Are you sure you want to select a pallet ?(exixting pallets for this header will be removed) : " + params[:id]
    session[:selected_pallet_number] = params[:id]
    session[:duplicate_free_rep_pallet_rec_set].each do |rec|
      if (rec.pallet_number == params[:id])
        session[:selected_carton_number] = rec.carton_number
        session[:selected_season_code] = rec.season_code
        break
      end
    end
    #================================
    #===========weekend work=========
    #================================
    render :inline => %{
                        <script>
                           if (confirm("<%=@msg%>") == true)
                              {window.location.href = "/fg/intake/representative_pallet_confirmed";}
                           else
                             {window.location.href = "/fg/intake/representative_pallet_canceled";}
                        </script>
                      }
  end

#================================
#===========weekend work=========
#================================
  def representative_pallet_confirmed
    pallet = Pallet.find_by_pallet_number(session[:selected_pallet_number])
    ppecb_inspection = PpecbInspection.find(pallet.ppecb_inspection_id)
    session[:intake_headers_production].representative_pallet_number = session[:selected_pallet_number]
    session[:intake_headers_production].representative_carton_number = session[:selected_carton_number]
    session[:intake_headers_production].inspector_number = ppecb_inspection.inspector_number.to_s
    session[:intake_headers_production].inspection_point = ppecb_inspection.inspection_point.to_s
    session[:intake_headers_production].account_code = pallet.account_code

    if (session[:intake_headers_production].consignment_note_number)
      num_rows_updated = Pallet.update_all(ActiveRecord::Base.extend_set_sql_with_request("consignment_note_number = Null","pallets"), "consignment_note_number = '#{session[:intake_headers_production].consignment_note_number}'")
      puts "updated these rows = " + num_rows_updated.to_s
    end

    consignment_note_number = get_consignment_note_number()
    session[:intake_headers_production].consignment_note_number = consignment_note_number
    Pallet.update_all(ActiveRecord::Base.extend_set_sql_with_request("consignment_note_number = '#{consignment_note_number}'","pallets"), "pallet_number = '#{session[:selected_pallet_number]}'")

    begin
      session[:intake_headers_production].update
      @id = session[:intake_headers_production].id.to_s
      render :inline => %{
                   <script>
                      window.close();
                      window.opener.frames[1].location.href="/fg/intake/edit_intake/<%=@id%>";
                      //alert("rep pallet was set successfully");
                   </script>
                          }
    rescue
      raise $!
    end
    #<%= close_popup_reload_child_window_by_id("rep pallet was set successfully","contentFrame") %>
  end

  def get_consignment_note_number
    consignment_note_number = ""
    if (session[:intake_headers_production].organization_code == "CA")
      consignment_note_number += "I"
    elsif (session[:intake_headers_production].organization_code == "KR") #org_short_description??????????????
      consignment_note_number += "A"
    else
      consignment_note_number += "L"
    end
    consignment_note_number += "031"
    consignment_note_number += session[:selected_season_code].slice((session[:selected_season_code].length-1)..(session[:selected_season_code].length-1))
#    consignment_note_number += session[:selected_season_code].to_s[session[:selected_season_code].length-1].to_s
    marketing_seq = get_marketing_org_sequences(session[:intake_headers_production].organization_code, "MARKETER").to_padded_s(5)
    if (marketing_seq)
      consignment_note_number += marketing_seq.to_s
    else
      raise "Error : Could not retrieve marketing_org_sequence for organization = " + session[:intake_headers_production].organization_code
    end
    return consignment_note_number
  end

  def get_marketing_org_sequences(org_name, role_name)
    if (sequence = MesControlFile.next_org_seq_web(org_name, role_name))
      return sequence
    else
      org = Organization.find_by_short_description(org_name)
      if (!org.parent_org_short_description)
        return nil
      else
        return get_marketing_org_sequences(org.parent_org_short_description, role_name)
      end
    end
  end

#================================
#===========weekend work=========
#================================

  def representative_pallet_canceled
    render_representative_pallets_grid
  end

  def find_intake
    dm_session[:parameter_fields_values] = nil
    dm_session['se_layout'] = 'content'
    @content_header_caption = "'search intake headers'"
    dm_session[:redirect] = true
    build_remote_search_engine_form("search_intake_headers.yml", "find_intake_submit")

  end

  def list_intake_headers
    render :inline => %{
      <% grid            = build_list_intake_headers_production_grid(@intake_headers_productions) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def find_intake_submit
    if  dm_session[:search_engine_query_definition]
      session[:query] = "ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])"
      @intake_headers_productions = eval(session[:query])


      if (@intake_headers_productions.length > 0)
        list_intake_headers
      else
        render :inline => %{
                            <script>
                              alert('no records were found');
                            </script>
                          }, :layout => 'content'
      end

    else
      recent_intakes
    end
  end


  def edit_intake
    @intake_headers_production = IntakeHeadersProduction.find(params[:id])
    render_edit_intake
  end

  def current_intake
    @intake_headers_production = session[:intake_headers_production]
    if (session[:intake_mode] == "edit")
      render_edit_intake
    elsif (session[:intake_mode] == "view")
      params[:id] = @intake_headers_production.id
      view_intake
    else
      render :inline=>%{<script> alert('no current intake'); </script>}, :layout=>'content'
    end
  end

  def cancel_intake
    delete_intake
  end

  def delete_intake

    begin
      @intake_headers_production = IntakeHeadersProduction.find(params[:id])
#      intake_document_pallets = Pallet.find_by_sql("select * from pallets where consignment_note_number = '#{@intake_headers_production.consignment_note_number}'")
#      intake_document_pallets.each do |doc_pallet|
#        log_pallet_document(doc_pallet.id,@intake_headers_production.consignment_note_number,@intake_headers_production.intake_type_code,'INTAKE_HEADER_REMOVED')
#      end
      ActiveRecord::Base.connection.execute("insert into pallet_document_logs (pallet_id,document_number,document_type,program_name,user_name,created_at,action)
                      select pallets.id, '#{@intake_headers_production.consignment_note_number}', '#{@intake_headers_production.intake_type_code}','intake_header_production','#{session[:user_id].user_name}','#{Time.new().to_formatted_s(:db)}','PALLET_REMOVED'
                     from pallets where pallets.consignment_note_number = '#{@intake_headers_production.consignment_note_number}'")
      Pallet.update_all(ActiveRecord::Base.extend_set_sql_with_request("consignment_note_number = NULL","pallets"), "consignment_note_number = '#{@intake_headers_production.consignment_note_number}'")
      @intake_headers_production.update_attribute(:header_status,"INTAKE_HEADER_CANCELED")
      @intake_headers_production.update_attribute(:exit_ref,"CANCELED")
      @intake_headers_production.update_attribute(:exit_date_time,Time.new().to_formatted_s(:db))
#      @intake_headers_production.destroy
      find_intake_submit
    rescue
      session[:alert] = "intake header could not be deleted : "
      find_intake_submit
    end
  end

  def mark_for_delete
    @intake_headers_production = IntakeHeadersProduction.find(params[:id])
    RwRun.receive_intake_header(@intake_headers_production, "INTAKE_HEADER_MARKED_FOR_DELETION", session[:user_id].user_name)
    find_intake_submit
  end

  def view_intake
    session[:is_view] = true
    session[:intake_mode] = "view"
    @intake_headers_production = IntakeHeadersProduction.find(params[:id]) if !@intake_headers_production
    session[:intake_headers_production] = @intake_headers_production
    render :inline => %{
                        <%= build_view_intake_form(@intake_headers_production,"","")%>
                        }, :layout => 'content'
  end

  def print_intake_from_grid
      id = params[:id]
      @intake_production= IntakeHeadersProduction.find(id)
      errors = print_intake_document
      if(errors)
        flash[:error] = "Could not print Document : " + errors.to_s
      else
        flash[:notice] = "Document printed successfully."
      end
      @intake_headers_productions = eval(session[:query])
      list_intake_headers
  end

  def get_intake_report
    id = params[:id]
    @intake_production= IntakeHeadersProduction.find(id)
    consignment_note_number =  @intake_production.consignment_note_number
    report_unit ="reportUnit=/reports/MES/FG/first_intake&"
    report_parameters="output=pdf&consignment_note_number="+ "#{consignment_note_number}"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)
  end
  
  def print_intake
    id = params[:id]
      @intake_production= IntakeHeadersProduction.find(id)
      errors = print_intake_document
      if(errors)
        flash[:error] = "Could not print Document : " + errors.to_s
        render :inline => %{}, :layout => 'content'
      else
        session[:alert] = "Document printed successfully."
        render :inline => %{
          <script>
            window.close();
          </script>
          }, :layout => 'content'
      end
  end



  def print_intake_document
    return "Printer not specified. Please set printer." if(!session[:intake_printer])

    consignment_note_number =  @intake_production.consignment_note_number

    edi_string = EdiOutProposal.make_edi_string(@intake_production, 'pdf417')

    if(!edi_string.include?("Error"))
      header = edi_string.slice!(0, 144)
      barcode_strings = Array.new
      while(edi_string.length > Globals.pdf417_max_size)
       barcode_string = edi_string.slice!(0,Globals.pdf417_max_size)
       barcode_strings.push(barcode_string)
      end
      barcode_strings.push(edi_string) if edi_string.length > 0
      header[128] = barcode_strings.length.to_s
      barcode_strings.map!{ |bc| header[127] = (barcode_strings.index(bc) + 1).to_s;header + bc}

      the_time = Time.now
      data_source_file = "intake_header_#{@intake_production.id}_#{the_time.month}_#{the_time.day}_#{the_time.hour}_#{the_time.min}_#{the_time.sec}"
      barcodes_file_name = Globals.pdf417_sub_report_data_source_dir + data_source_file + ".xml"

      require 'nokogiri'
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.PDF417 {
          xml.BARCODES {
            barcode_strings.each do |r|
             xml.BARCODE r
           end
          }
        }
      end
      File.open(barcodes_file_name,"w") do |f|
       f.write(builder.to_xml)
       f.close
      end

      out_file_type = "PDF"
      out_file_name = "intake_#{Time.now.strftime("%m_%d_%Y_%H_%M_%S")}"
      out_file_path = Globals.jasper_reports_pdf_downloads + "/#{out_file_name}"
      @err = JasperReports.generate_report('intake',session[:user_id].user_name,{:consignment_note_number=>consignment_note_number,:MODE=>"PRINT",:OUT_FILE_NAME=>out_file_path,:OUT_FILE_TYPE=>out_file_type,:printer=>session[:intake_printer],:SUBREPORT_DATA_SOURCE=>Globals.pdf417_sub_report_data_source_dir + data_source_file})

      puts "ERRORZ: " + @err.to_s # A031050138
      #File.delete(barcodes_file_name)
      return @err if(@err)
      else
      return "Could not print Document : " + edi_string
    end
    return nil
  end
  
  def change_intake
    @intake_headers_production = IntakeHeadersProduction.find(params[:id])
    ActiveRecord::Base.transaction do
      RwRun.receive_intake_header(@intake_headers_production, "INTAKE_HEADER_RECONFIGURING", session[:user_id].user_name)
    end
    render_edit_intake
  end

  def send_edi
    @intake_headers_production = IntakeHeadersProduction.find(params[:id])
    @intake_headers_production.send_edi(session[:user_id].user_name)
    flash[:notice] = "EDI Proposal created successfully"
    find_intake_submit
  end

  def accept_consignment
    Pallet.transaction do
      @valid_consigment = nil
      if (session[:intake_headers_production] != nil && session[:intake_headers_production].intake_header_number != nil && session[:intake_headers_production].representative_pallet_number != nil)
        num_pallets_without_gtins = session["#{session[:intake_headers_production].intake_header_number}_invalid_pallets"][:gtin]
        num_pallets_without_gtin_tm = session["#{session[:intake_headers_production].intake_header_number}_invalid_pallets"][:tm]
        if (num_pallets_without_gtins && num_pallets_without_gtins > 0)
          @valid_consigment = "there are #{num_pallets_without_gtins} pallets requiring gtins,for which gtins could not be found.\n"
        end
        if (num_pallets_without_gtin_tm && num_pallets_without_gtin_tm > 0)
          @valid_consigment = "there are #{num_pallets_without_gtin_tm} pallets with gtins,for which target_markets could not be found."
        end
      else
        @valid_consigment = "Consignment must have atleast one pallet associated with it"
      end

      if (@valid_consigment != nil)
        @the_url =  "http://" + request.host_with_port + "/" + request.path_parameters['controller'].to_s + "/edit_intake/" +session[:intake_headers_production].id.to_s
        render :inline => %{<script>alert("<%=@valid_consigment%>");window.location.href="<%=@the_url%>";</script>}, :layout=>"content"
      else


        if !session[:intake_headers_production].update_attributes(params[:intake_headers_production])
          current_intake
          return
        end

        session[:intake_headers_production].user = session[:user_id].user_name
        session[:intake_headers_production].change_header_status("INTAKE_HEADER_ACCEPTED", session[:user_id].user_name)


        flash[:notice] = "header accepted successfully"
        session[:intake_mode] = "view"
        session[:is_view] = true
        current_intake

      end
    end

  end

  def process_history
    id = params[:id]
    @intake_header_productions_statusses = IntakeHeaderProductionStatus.find_all_by_intake_header_production_id(id, :order=>"id DESC")
#    @intake_header_productions_statusses = IntakeHeaderStatus.find_all_by_intake_header_id(id,:order=>"id DESC")
    render :inline => %{
      <% grid            = build_list_intake_header_productions_statusses_grid(@intake_header_productions_statusses) %>
      <% grid.caption    = 'process history' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def recent_intakes
    session[:query] = "IntakeHeadersProduction.find(:all, :order=>\"updated_on DESC limit 100\")"
    @intake_headers_productions = eval(session[:query])
#    dm_session[:search_engine_query_definition] = nil
    @caption = "'list of most recent intakes'"
    list_intake_headers
  end

end
