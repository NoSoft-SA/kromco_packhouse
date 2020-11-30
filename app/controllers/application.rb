require "rubygems"
require "fileutils"
#require "rufus/decision"
require "app/models/pdt_transactions/pdt_business_functions/jsession_store.rb"
require "app/models/pdt_transactions/pdt_business_functions/pdt_transaction.rb"
require "app/models/pdt_transactions/pdt_business_functions/pdt_transaction_state.rb"
require "app/models/pdt_transactions/pdt_business_functions/pdt_screen_definition.rb"
require "app/models/pdt_transactions/pdt_business_functions/pdt_method.rb"
require "app/models/pdt_transactions/pdt_business_functions/pallet_sequence_navigator.rb"
require "app/models/pdt_transactions/pdt_business_functions/pdt_functions.rb"
require "app/models/pdt_transactions/pdt_business_functions/label_print_command.rb"
require "app/models/pdt_transactions/pdt_business_functions/print_pallet_label_base.rb"
require "app/models/pdt_transactions/pdt_business_functions/sessions.rb"
require "lib/globals.rb"
require "lib/extensions.rb"
require "status_man/lib/status_change_event_handler.rb"
require "status_man/lib/status_man.rb"
require "lib/kromco_app_services.rb"
require "app/models/pdt_transactions/pdt_business_functions/pdt_remote_list.rb"

class ApplicationController < ActionController::Base
  include Kromco::ComparerServices
  include Kromco::ReworksServices
  include Kromco::EdiServices
  include MesScada::DataMinerActions

  MY_PAGINATION_OPTIONS = {
    :name                 => :page,
    :window_size          => 2,
    :always_show_anchors  => true,
    :link_to_current_page => false,
    :params               => {}
  }

  @@page_size = 500


  def jsession_folder
    "tmp/jsessions/"
  end

  def persisted_lists_folder
    "tmp/persisted_lists/"
  end

  def rufus_wrapper (rule_filename, parameters)
    table_ruf= Rufus::DecisionTable.new(rule_filename)
    return table_ruf.transform(parameters)
  end

  before_filter :configure_charsets, :check_login, :except => [:list_load_voyages,:move_presort_bin, :list_voyage_ports, :list_load_details, :render_list_order_products, :progress, :progress_test, :start_tasks_thread, :login, :messages, :invoke, :invoke_submit, :invoke_method_params, :wsdl, :api, :authenticate, :integrate, :symbol_pdt_6800, :handle_request, :get_bin, :get_bin_info, :get_delivery_info, :can_bin_be_tipped, :get_run_treatment_codes, :get_run_ripe_point_codes, :get_run_track_indicator_codes, :set_user_message, :list_forecasts, :list_drenches, :list_drench_lines, :list_drench_concentrates, :list_concentrate_product_types, :get_production_runs_results, :get_stored_pdt_processes, :get_production_runs_farm_code, :get_production_runs_line_code, :get_production_runs_account_code, :get_stored_pdt_processes_user_process_name, :get_stored_pdt_processes_transaction_name, :get_temperature_device_type_list, :get_unit_type_list, :get_pallet_format_product_codes, :update_run_stats, :valid_trip_sheet, :complete_delivery, :valid_bin, :list_qc_inspection_types, :list_qc_reasons, :list_qc_inspection_type_tests, :list_qc_measurement_types, :list_qc_inspection_tests, :edit_qc_inspection, :render_commitment_form, :list_spray_results_form, :get_loading_vehicle_numbers, :get_offload_tripsheets, :change_password, :change_user_password, :webquery, :fta_reports_index, :view_last_fta_report, :search_fta_reports, :view_last_rfm_report, :search_rfm_reports, :print_current_fta_report, :view_fta_report, :print_current_rfm_report, :view_rfm_report, :submit_search_rfm_reports_search, :send_parameter_fields, :submit_search_fta_reports_search, :submit_search_rfm_reports_search, :get_active_run_details, :bins_scanned, :override_provided, :bin_tipped, :bin_created, :list_servers, :list_clusters, :list_modules, :list_peripherals, :list_peripheral_printers, :pdt_login, :pdt_logout, :web_pdt_func_area_search_combo_changed, :web_pdt_prog_search_combo_changed, :web_pdt_special_menus_search_combo_changed, :web_pdt_prog_func_search_combo_changed, :handle_web_pdt_request, :handle_pdt_web_request, :web_pdt_filter_field_search_combo_changed, :web_pdt_replace_field_search_combo_changed]
  after_filter :clear_lock, :except => [:list_load_voyages,:move_presort_bin, :list_voyage_ports, :list_load_details, :render_list_order_products, :progress, :progress_test, :start_tasks_thread, :login, :messages, :invoke, :invoke_submit, :invoke_method_params, :wsdl, :api, :authenticate, :integrate, :symbol_pdt_6800, :handle_request, :get_bin, :get_bin_info, :get_delivery_info, :can_bin_be_tipped, :get_run_treatment_codes, :get_run_ripe_point_codes, :get_run_track_indicator_codes, :set_user_message, :update_run_stats, :list_qc_inspection_types, :list_qc_reasons, :list_qc_inspection_type_tests, :list_qc_measurement_types, :list_qc_inspection_tests, :edit_qc_inspection, :render_commitment_form, :list_spray_results_form, :webquery, :get_active_run_details, :bins_scanned, :override_provided, :bin_tipped, :bin_created, :list_servers, :list_clusters, :list_modules, :list_peripherals, :list_peripheral_printers, :pdt_login, :pdt_logout, :web_pdt_func_area_search_combo_changed, :web_pdt_prog_search_combo_changed, :web_pdt_special_menus_search_combo_changed, :web_pdt_prog_func_search_combo_changed, :handle_web_pdt_request, :handle_pdt_web_request, :web_pdt_filter_field_search_combo_changed, :web_pdt_replace_field_search_combo_changed]


  def set_active_doc(doc_type, doc_id)
    if session[:active_doc]==nil
      session[:active_doc]={}
    end
    session[:active_doc][doc_type]=doc_id
  end

  def get_active_doc(doc_type)
    return session[:active_doc][doc_type] if (session[:active_doc])
  end

  def export_grid_selection_to_csv(recordset, file_base_name, cols=nil)
    begin


      file_name = file_base_name + "_" + Time.now.strftime("%m_%d_%Y_%H_%M_%S") + ".csv"


      DataToUserExporter.create_se_csv_file(recordset, file_name, cols)

      #redirect_to_index("data_exported successfully to csv")
      send_file(DataToUserExporter.download_path + file_name)
        #TODO: write script to delete files older than e.g. 10 minutes from downloads directory
    rescue
      handle_error("grid selection could not be exported")
    end
  end


  def configure_charsets
    #@response.headers["Content-Type"] = "text/html; charset=utf-8"
    response.headers["Content-Type"] = "text/html; charset=utf-8"
    # Set connection charset. MySQL 4.0 doesn't support this so it
    # will throw an error, MySQL 4.1 needs this
    suppress(ActiveRecord::StatementInvalid) do
      ActiveRecord::Base.connection.execute 'SET CLIENT_ENCODING TO UTF8'
    end
  end

  def clear_lock
    if @mylock
      if session[:user_id]
        lock = RequestLock.find_by_user_id(session[:user_id].user_name)
        lock.destroy if lock
      end
    end
    store_request_info(true) #clear active request
  end

  def delete(dir, controller)
    @msg = "Are you sure you want to delete?  "


    render :inline => %{
   <script>
     if (confirm("<%=@msg%>") == true)
        {window.location.href = "/#{dir}/#{controller}/delete_confirmed";}
     else
       {window.location.href = "/#{dir}/#{controller}/delete_cancelled";}
  </script>
    }

  end

  def confirm_edit_create?(obj, params)
    obj.update_attributes_state(params)
    changed = obj.changed_fields?
    changed_msg = build_changed_field_msg(changed)

    if changed_msg == "" || changed_msg== nil
      return msg= "You did not change anything"
    else
      return nil
    end
  end


  def build_changed_field_msg(changed_fields, bulk_update=nil)
    changed_msg = ""
    if changed_fields && changed_fields.length > 0
      changed_msg = "\\nChanged fields: \\n"
      changed_fields.each do |field_name, values|
        if bulk_update
          changed_msg += field_name + "  " + "  changed to:" + values[1] + ")\\n"
        else

          if values[0]==nil || values[0]==""
            values[0]="nil"
          end
          if values[1]==nil || values[1]==""
            values[1]="nil"
          end
          changed_msg += field_name + "  (was:  " + values[0] + "  changed to:" + values[1] + ")\\n"
        end
      end
    end
    return changed_msg
  end

  def build_changed_bin_field_msg(changed_fields)
    changed_msg = ""
    if changed_fields && changed_fields.length > 0
      changed_msg = "\\nChanged fields: \\n"
      changed_fields.each do |field_name, values|
        if field_name == "farm_code"
          if values[0] == "" || values[0] ==0
            value1 = "null"
          else

            value1 = Farm.find(values[0].to_i).farm_code
          end
          if values[1] == "" || values[1] ==0

            value2 = "null"
          else
            value2 = Farm.find(values[1].to_i).farm_code
          end


        elsif field_name == "production_run_tipped_code"
          if values[0] == "" || values[0] ==0
            value1 = "null"
          else

            value1 = ProductionRun.find(values[0].to_i).production_run_code
          end
          if values[1] == "" || values[1] ==0

            value2 = "null"
          else
            value2 = ProductionRun.find(values[1].to_i).production_run_code
          end


        elsif field_name == "track_indicator5_code"
          if values[0] == "" || values[0] ==0
            value1 = "null"

          else
            value1 = TrackSlmsIndicator.find(values[0].to_i).track_slms_indicator_code
          end
          if values[1] == "" || values[0] ==0
            value2 = "null"

          else
            value2 = TrackSlmsIndicator.find(values[1].to_i).track_slms_indicator_code
          end



        elsif field_name == "track_indicator4_code"
          if values[0] == "" || values[0] ==0
            value1 = "null"

          else
            value1 = TrackSlmsIndicator.find(values[0].to_i).track_slms_indicator_code
          end
          if values[1] == "" || values[1] ==0

            value2 = "null"
          else
            value2 = TrackSlmsIndicator.find(values[1].to_i).track_slms_indicator_code
          end



        elsif field_name == "track_indicator3_code"
          if values[0] == "" || values[0] ==0
            value1 ="null"
          else

            value1 = TrackSlmsIndicator.find(values[0].to_i).track_slms_indicator_code
          end
          if values[1] == ""|| values[1] ==0

            value2 = "null"
          else
            value2 = TrackSlmsIndicator.find(values[1].to_i).track_slms_indicator_code
          end



        elsif field_name == "track_indicator2_code"
          if (values[0]=="" || values[0] ==0.to_i)
            value1 = "null"
          else
            value1 = TrackSlmsIndicator.find(values[0].to_i).track_slms_indicator_code

          end
          if (values[1] == "" || values[1] ==0.to_i)
            value2 = "null"
          else

            value2 = TrackSlmsIndicator.find(values[1].to_i).track_slms_indicator_code
          end



        elsif field_name == "track_indicator1_code"
          if (values[0] == "" || values[0] ==0.to_i)
            value1 = "null"
          else

            value1 = TrackSlmsIndicator.find(values[0].to_i).track_slms_indicator_code
          end
          if (values[1] == ""|| values[1] ==0.to_i)
            value2 = "null"
          else

            value2 = TrackSlmsIndicator.find(values[1].to_i).track_slms_indicator_code
          end



        elsif field_name == "production_run_rebin_code"
          if (values[0] == "" || values[0] ==0.to_i)
            value1 = "null"
          else

            value1 = ProductionRun.find(values[0].to_i).production_run_code
          end
          if (values[1] == "" || values[1] ==0.to_i)
            value2 = "null"
          else

            value2 = ProductionRun.find(values[1].to_i).production_run_code
          end




        elsif field_name == "rebin_track_indicator_code_code"
          if (values[0] == "")
            value1 = "null"
          else

            value1 = TrackIndicator.find_by_track_indicator_code(values[0].to_s).track_indicator_code
          end
          if (values[1] == "")
            value2 = "null"
          else

            value2 = TrackIndicator.find_by_track_indicator_code(values[1].to_s).track_indicator_code
          end



        elsif field_name == "rmt_product_code"
          if (values[0] == "" || values[0] ==0.to_i)
            value1 = "null"
          else

            value1 = RmtProduct.find(values[0].to_i).rmt_product_code
          end
          if (values[1] == "" || values[1] ==1)
            value2 = "null"
          else

            value2 = RmtProduct.find(values[1].to_i).rmt_product_code
          end



        elsif field_name == "pack_material_product_code"
          if (values[0] == "" || values[0] ==0.to_i)
            value1 = "null"
          else

            value1 = PackMaterialProduct.find(values[0].to_i).pack_material_product_code
          end
          if (values[1] == "" || values[1] ==0.to_i)
            value2 = "null"
          else

            value2 = PackMaterialProduct.find(values[1].to_i).pack_material_product_code
          end
        else
          value1 = values[0]
          value2 =values[1]
        end

        changed_msg += field_name + "  (was:  " + value1 + "  changed to:" + value2 + ")\\n"
      end

    end
    return changed_msg
  end

  def get_lock
    lock_url = nil
    if session[:user_id]
      lock = RequestLock.find_by_user_id(session[:user_id].user_name)
      if lock
        lock_url = lock.url
      else
        lock         = RequestLock.new
        lock.url     = request.path
        lock.user_id = session[:user_id].user_name
        lock.create
        @mylock = true
      end
    end
    return lock_url

  end

  def set_charset
    @headers["Content-Type"] = "text/html; charset=utf-8"
  end


  def self.domain
    return @@domain
  end

  def columns_for_export?

    cols = session["custom_export_columns"]
    session["custom_export_columns"] = nil if cols
    return cols

  end

  # Set the notice if a parameter is given, then redirect back
  # to the current controller's +index+ action
  def redirect_to_index(msg = nil, caption = nil, freeze = nil, err = nil)
    if flash[:notice]
      flash[:notice] += msg if msg
    else
      if err
        flash[:error] = msg if msg
      else
        flash[:notice] = msg if msg
      end
    end

    @freeze_flash = true if freeze != nil
    session[:page_title] = @page_title
    @content_header_caption = caption if caption
    render :template => "login/index", :layout => "content"
  end

  def selected_rows?
    #list = eval params['selection']['list']
    list = ids_from_multi_select_grid_params
    if list.length > 0
      return list
    else
      return nil
    end
  end

  def selected_records?(recordset, selected_rows = nil, key_based_access = nil)
    selected_rows = selected_rows? if !selected_rows
    return nil if !selected_rows
    selection = Array.new
    selected_rows.each do |id|
      if key_based_access
        if record = recordset.find { |r| r['id'] == id.to_s.strip }
          selection.push record
        end
      else
        if record = recordset.find { |r| r.id == id }
          selection.push record
        end
      end
    end

    return selection

  end

  # Close a popup window from an RJS AJAX <tt>render :update</tt> response.
  # If a msg is provided it will be shown in an alert.
  # If reload_content_frame is true, the page loaded in the +contentFrame+ iframe will be reloaded.
  #
  # Call like this in a controller action:
  #
  #     render :update |page| do
  #       controller.close_ajax_popup_window( page, 'Something to say in an alert' )
  #     end
  def close_ajax_popup_window( page, msg=nil, reload_content_frame=true )
    page.call 'alert', msg if msg
    page.call 'close'
    page << 'window.opener.frames[1].location.reload(true);' if reload_content_frame
  end

  def rescue_action_in_public(exception) # Public: request came from another ip, not localhost.

    handle_error("An unexpected exception occurred")

  end


  # JS preference - code to allow use of normal Rails error handling while in development mode
  # but still clear the request lock.
  if ENV['RAILS_ENV'] == 'development'
    def rescue_action_with_clear_lock(exception)
      clear_lock
      rescue_action_locally_orig( exception )
    end
    alias_method :rescue_action_locally_orig, :rescue_action_locally
    alias_method :rescue_action_locally, :rescue_action_with_clear_lock
  else
    def rescue_action_locally(exception) # Locally: request originated from localhost.
      handle_error("An unexpected exception occurred")
    end
  end


  def handle_error(error, is_tree = nil, is_tree_content = nil, error_type = 'rails web program', render_error_view=true)
    begin

      err_type = 'exception'
      err_text = $!.nil? ? nil : $!.message
      clear_lock
      show_stack_trace = true

      if $!.is_a? MesScada::InfoError
        error            = $!.message
        show_stack_trace = false
        err_type         = 'error'
      elsif $!.is_a?( ActiveRecord::StatementInvalid ) && $!.message.include?('violates foreign key constraint')
        show_stack_trace = false
        err_type         = 'error'
        err_arr          = err_text.split( 'table' ).map {|r| r.strip.split('"')[1] }
        err_text         = "The #{Inflector.humanize(Inflector.singularize(err_arr[1]))} record is required by a #{Inflector.humanize(Inflector.singularize(err_arr.last))} record."

        #       RuntimeError: ERROR	C23503	Mupdate or delete on table "commodities" violates foreign key constraint "fk_counts_to_commodities" on table "standard_counts"	DKey (id)=(6) is still referenced from table "standard_counts". Fri_triggers.c	L3580	Rri_ReportViolation: DELETE FROM commodities WHERE "id" = 6
      end

      if ENV['RAILS_ENV'] == 'development'
        send_mail  = false
      else
        send_mail  = false
      end
      error_detail = ''
      error_detail << "<br><font size = '2px' color = 'black'>The system reported the following #{err_type}.</font> <br> " + err_text.gsub('<', '&lt;').gsub('>', '&gt;') if $! != nil

      error_detail << "<br><br><font size = '2px'>stack trace: <BR></font><font color = 'red' size = 'smaller'>" + $!.backtrace.join("<BR>") + "</font>" if $! != nil && show_stack_trace == true

      flash[:error] = "<font size = '3px' color = 'red'>#{error}</font><br>#{error_detail}" if error
      header_caption = "'Error occurred'" if header_caption == nil
      #---------
      #log to db
      #---------
      err_entry = RailsError.new
      err_entry.description = error + error_detail if error
      err_entry.stack_trace = $!.backtrace.join("\n").to_s if $!
      #      puts "ERROR: " + err_entry.description + " STACK: " + err_entry.stack_trace
      err_entry.logged_on_user = session[:user_id].user_name if  session[:user_id]
      err_entry.person = session[:user_id].person.last_name + "," + session[:user_id].person.first_name if  session[:user_id]
      err_entry.error_type      = error_type
      err_entry.controller_name = params[:controller]
      err_entry.action_name     = params[:action]
      err_entry.create

      #-----------
      #send email
      #-----------
      if send_mail && $! && error
        err_entry.html_stacktrace = $!.backtrace.join("<br>").to_s
        email                     = RailsErrorMail.create_set_error_details(err_entry)
        email.set_content_type("text/html")
        RailsErrorMail.deliver(email)
      end

      if(render_error_view)
        if request.xhr? # Send Internal System Error code for AJAX call.
          render :nothing => true, :status => 500
        else
          if is_tree
            render :template => "login/tree_error", :layout => false
          elsif is_tree_content

            @tree_node_content_header_caption = header_caption
          else

            @content_header_caption = header_caption
            render :template => "login/index", :layout => "content"
          end

        end
      else
        return err_entry
      end
    rescue
      raise "The exception handling mechanism failed. Reported exception is <br> " + $!
    end

  end

  def handle_error_silently(error = nil)
    begin

      show_stack_trace = false
      send_mail        = false
      error_detail     = ""
      error_detail = ".<br><font size = '2px' color = 'black'>The system reported the following exception.</font> <br> " + $! if $! != nil

      error_detail += "<br><br><font size = '2px'>stack trace: <BR></font><font color = 'red' size = 'smaller'>" + $!.backtrace.to_s + "</font>" if $! != nil && show_stack_trace == true

      #---------
      #log to db
      #---------
      err_entry = RailsError.new
      err_entry.description = error + error_detail if error
      err_entry.stack_trace = $!.backtrace.join("\n").to_s if $!
      err_entry.logged_on_user  = "system"
      err_entry.person          = "system"
      err_entry.error_type      = "rails back-end service"
      err_entry.controller_name = params[:controller]
      err_entry.action_name     = params[:action]
      err_entry.create

      #-----------
      #send email
      #-----------
      if send_mail && $!
        err_entry.html_stacktrace = $!.backtrace.join("<br>").to_s
        email                     = RailsErrorMail.create_set_error_details(err_entry)
        email.set_content_type("text/html")
        RailsErrorMail.deliver(email)
      end

    rescue
      raise "The exception handling mechanism failed. Reported exception is <br> " + $!
    end

  end

  def index

  end

  #---------------------------------------------------------------------------------------------------------------
  #This method is called before any action of any controller is called- it's a filter
  #(except when the login controller is called). Processing is reasonably complex:
  #This method firstly checks whether the current session (for requesting user) contains
  #a value for the key: 'user_id'- which is an instance of the user class
  #if not, it means the user has not logged on, so the request is redirected to
  #the 'login' action of the login controller. (that method will render a logon screen
  #and, if successful, the 'logged in' action will be called)
  #If the user has logged-in, this method will then either render the logged-in view or
  #it will attempt to do generic authorisation.
  #The former will always happen directly after a user has just logged-in. (the action
  #intercepted will be 'logged-in') In this case the view ('logged-in') being rendered, creates
  #an empty iframe inside the 'home' layout template(inside the '@contents_for_page' variable). Just before the
  #the rendering the javascript that defines the 3-level menu structure- tailored for the
  #logged-on user- is build from the database security data. The urls contained in the 3rd level
  #of the menus will load inside the internal frame, so that the menu and 'home' (master page for site)
  #is never re-rendered, but remains on the client- except if the session expires.
  #The latter (authorisation) will occur for any request subsequent to the 'logged-in' request, except
  #for the 'denied' or 'logged-out' requests- since these are internal requests that never
  #requires authorisatio- if authorisation fails, the 'denied' request will be redirected to
  #---------------------------------------------------------------------------------------------------------------


  def check_login
    @@domain = "http://" + request.host_with_port + "/"
    Globals.set_domain(@@domain)

    flash[:notice]= nil unless flash[:keep_flash_on_redirect]
    flash[:notice_icon]= nil unless flash[:keep_flash_on_redirect]
    unless session[:user_id]

      flash[:notice] = "Please log in"
      store_request_info(true)
      redirect_to("/login/login")
    else
      if (params[:action]!= "logout" && params[:action]!= "denied")

        if params[:action]== "logged_in"
          store_request_info(true)

          build_menus_for_user
          @user_name = session[:user_id].user_name

          render(:template => "login/logged_in")
        else
          # lock = request.xhr? ? nil : get_lock
          # NB. This could be simplified to just: if request.xhr? || request.get?
          #     - but then all GET links that change data will need to be altered to use :method => :post..
          if request.xhr? || (request.request_parameters["action"]                    &&
                              request.get?                                            &&
                             (request.request_parameters["action"].include?('list')   ||
                              request.request_parameters["action"].include?('search') ||
                              request.request_parameters["action"].include?('view')))
            lock = nil
            # logger.debug ">>> NOLOCK: #{request.request_parameters["action"]}"
          else
            lock = get_lock
            # logger.debug ">>>   LOCK: #{request.request_parameters["action"]}"
          end
          if lock && params[:action]!= "list_request_locks" && params[:action]!= "delete_request_lock"
            redirect_to_index("Transaction with url: " + lock + " is still busy")
            return
          end
          store_request_info()
          generic_authorise
        end
      elsif params[:action]== "logout"
        store_request_info(true)
        clear_lock
      end
    end
  end


  def store_request_info(clear_info = nil)
    if !clear_info
      ActiveRequest.set_active_request(session[:user_id].user_name, params[:controller], params[:action], "web")
    else
      ActiveRequest.clear_active_request
    end

  end

  def bypass_generic_security?
    return false
  end

  #------------------------------------------------------------------------------------
  #This method is called by the before filter method 'check_login' on
  #discovery that the user sending the request-for-action from the brower
  #has already been logged-in. This method uses the 'authorise' method
  #of this class to do a kind of catch-all authorisation, i.e. for all
  #the methods within the controller destined to handle the incoming request
  #(which is, of cource, a subclass of this class). To do this, this method
  #needs to know the name of the program to which the handling controller
  #belongs, that is, the name as defined in the security model in db- i.e. 'programmes'
  #The handling controller must provide the name by overriding the 'program_name?'
  #method. Generic authorisation looks to find an 'admin' security permission
  #in the security_group that is associated with the logged-on user for the current program.
  #The handling(sub-classing) controller can by-pass generic authorisation
  #by declaring a list of 'exceptions', that is, a list of controller-method
  #names for which generic authorisation will be ignored at runtime. The intent
  # behind side-stepping authorisation in this way, should be to implemenet more
  #specific authorisation in certain controller methods by using the authorisation API
  #----------------------------------------------------------------------------------------
  def generic_authorise
    return if bypass_generic_security? == true
    exceptions = admin_exceptions?
    program    = program_name?
    match      = false
    if exceptions != nil
      match = exceptions.find { |exc| exc == params[:action] }
    end

    if  match == false || exceptions == nil

      if program != nil

        authorise_for_web program, "admin"
      end
    end
  end

  #virtual method
  def program_name?
    return self.class.to_s.split("::")[1].underscore().gsub("_controller", "")

  end

  #virtual method
  def admin_exceptions?

  end


  def convert_menus_to_js (menu_data)

    all_programs = Program.find(:all, :include => "program_functions", :order => "programs.id,program_functions.position,program_functions.id")

    #base_dir =  File.dirname(__FILE__)+ '../../../public'
    base_dir     = 'public'

    menus_js     = "var menu_structure = new MenuStructure();"
    func_areas   = menu_data.keys.sort

    func_areas.each do |func_area_item|

      #add outer tab as functional area
      func_area, func_area_caption = func_area_item.split(',')
      func_area_caption          ||= func_area
      func_area_image              = func_area.gsub(" ", "_")
      outer_image                  = "/images/menu/#{func_area_image}/#{func_area_image}.png"
      outer_image                  = "/images/menu/transparent.png" if not File.exists?(base_dir + outer_image)



      menus_js   += " menu_structure.AddTab('#{func_area_caption}',' ','#{outer_image}');"
      #add inner tabs as programs for the functional area
      prog_items = menu_data[func_area_item]

      prog_items.each do |prog_item|

        prog, prog_caption = prog_item.split(',')
        prog_caption ||= prog
        prog_image  = prog.gsub(" ", "_")
        inner_image = "/images/menu/#{func_area_image}/#{prog_image}/#{prog_image}.png"
        inner_image = "/images/menu/transparent.png" if not File.exists?(base_dir + inner_image)

        menus_js       += " menu_structure.OuterTabs['#{func_area_caption}'].AddTab('#{prog_caption}',' ','#{inner_image}');"
        #now add the third level menus
        program_rec    = all_programs.find { |p| p.program_name == prog }
        prog_functions = program_rec.program_functions

        prog_functions.each do |function|
          display_name = function.display_name
          display_name = function.name.gsub("_", " ") if display_name.blank?
          display_name_image = display_name.gsub(" ", "_")
          l3_image           = "/images/menu/#{func_area_image}/#{prog_image}/#{display_name_image}.png"
          l3_image = "/images/menu/transparent.png" if not File.exists?(base_dir + l3_image)

          func_prog     = program_rec.url_component || prog
          func_area_val = program_rec.func_area_url_component || func_area
          func_area_val = function.func_area_url_component if function.func_area_url_component

          func_prog = function.prog_url_component if function.prog_url_component

          url  = "#{@@domain}#{func_area_val}/#{func_prog}/#{function.name}"
          url << "/" << function.url_param if function.url_param
          menus_js += " menu_structure.OuterTabs['#{func_area_caption}'].Tabs['#{prog_caption}'].AddTab('#{display_name}','#{url}','#{l3_image}');"
        end

      end

    end


    return menus_js

  end

  def build_menus_for_user

    menus = Hash.new
    user  = session[:user_id]

    if not user.nil?
      if user.menus_js == nil
        user_progs = user.program_users.find(:all, :include => {'program' => 'functional_area'}, :order => "program_users.program_id")


        user_progs.each do |uprog|
          if !uprog.program.functional_area.is_non_web_program
            func_area = uprog.program.functional_area.functional_area_name
            if uprog.program.functional_area.display_name != nil
              if uprog.program.functional_area.display_name.length > 1
                func_area = func_area + "," + uprog.program.functional_area.display_name
              end
            end

            program_name = uprog.program.program_name

            if uprog.program.display_name != nil
              if uprog.program.display_name.strip.length > 1
                program_name = program_name + "," + uprog.program.display_name
              end
            end

            if menus.has_key?(func_area)
              menus[func_area].push program_name
            else
              menus[func_area] = Array.new
              menus[func_area].push program_name
            end
          end
        end

        @menus_js     = convert_menus_to_js(menus)
        user.menus_js = @menus_js
      else
        @menus_js = user.menus_js
      end

    end
  end

  #-------------------------------------------------------------------------------
  #This method authorises a request by a user to perform a given action
  #param: program:
  #       a program as listed in the 'programs' table.
  #       a user is linked to one or more programs via the users_programs table
  #       permission:
  #       a permission as listed in the 'security_permission' table
  #       one or more permissions are grouped as a security group, which in turn
  #       is linked to one or more users and one programme_user record.
  #       So, to authorise, this method does the following:
  #       1) 	It looks at the 'programs_users' table to see whether the
  #           logged-on user is associated with the 'program' (input parameter)
  #       2) If not, authorisation fails. Else, it looks at the associated
  #          security group, and from there, at all the individual permissions
  #          belonging to the group. IF the passed-in 'permission' parameter
  #          can be matched with any one of the security permissions, belonging
  #          to the group, authorisation succeeds.
  #--------------------------------------------------------------------------------


  # Check authorisation. Program parameter can be a String or an array of Strings if the permission can be in any one of the programs.
  def authorise(program, permission, user)
    programs = Array(program)
    user     = User.find_by_user_name(user) if user.is_a? String

    query = "SELECT
             public.security_permissions.id
             FROM
             public.security_groups_security_permissions
             INNER JOIN public.security_groups ON (public.security_groups_security_permissions.security_group_id = public.security_groups.id)
              INNER JOIN public.security_permissions ON (public.security_groups_security_permissions.security_permission_id = public.security_permissions.id)
              INNER JOIN public.program_users ON (public.security_groups.id = public.program_users.security_group_id)
              INNER JOIN public.programs ON (public.program_users.program_id = public.programs.id)
              WHERE
              (public.program_users.user_id = #{user.id}) AND
              (public.security_permissions.security_permission = '#{permission}') AND
              (public.programs.program_name IN ( '#{programs.join("','")}') )"

    val  = User.connection.select_one(query)

    !val.nil?

  rescue
    false
  end

  #-----------------------------------------------------------
  #This method checks whether a user is associated with a given
  #program
  #-----------------------------------------------------------
  def basic_authorise(program, user)
    begin
      user = User.find_by_user_name(user) if user.class.to_s == "String"
      program = Program.find_by_program_name(program) if program.class.to_s == "String"
      #puts "-----( " + program.id.to_s + "," + user.id.to_s + " )-------"
      record = ProgramUser.find_by_program_id_and_user_id(program.id, user.id)

      return record != nil
    rescue

      return false
    end
  end


  def authorise_for_web(program, permission)

    user = session[:user_id]

    authorised = authorise(program, permission, user)

    redirect_to :action => "denied", :controller => "/login" unless authorised
    authorised
  end

  # For when you just need to know if the user is authorised or not
  # without automatically redirecting to the denied page.
  def authorise_without_redirect(program, permission)
    user = session[:user_id]

    authorise(program, permission, user)
  end

  # The logged-in User must belong to one of the given departments.
  def authorise_by_department(*department_names)
    dept = session[:user_id].department.department_name.upcase

    if department_names.map {|a| a.upcase}.include?(dept)
      true
    else
      s = department_names.to_sentence(:connector => 'or')
      flash[:extra_message] = "This action can only be performed by someone in the #{s} department."
      redirect_to :action => "denied", :controller => "/login"
      false
    end
  end

  #utility methods needed by all controllers for request parameter processing
  def get_selected_combo_value(request_params)

    request_params.each do |key, val|
      if key != "action" && key != "controller"
        return key
      end
    end

    nil # Return nil if there are no parameters other than controller/action...
  end

  def delete_record(recordset, id)

    return if recordset == nil

    match = recordset.find { |r| r.id.to_s == id.to_s }

    recordset.delete(match)


  end

  def update_record(recordset, new_vals, record_id)

    return if recordset == nil

    match = recordset.find { |r| r.id.to_s == record_id.to_s }

    match.attributes = new_vals


  end


  def dynamic_search(request_paramz, table_name, model_name, paginate = true, includes = nil, order = nil, page_size = nil)
    request_params = request_paramz.clone # Luks change
    begin
      main_table      = table_name
      from_tables     = table_name
      fk_field_tables = Hash.new

      if includes
        from_tables       += ", "
        fk_tables         = includes.gsub("'", "")
        pluralized_tables = fk_tables.split(",")
        #remove the list of fields from each table
        tables_only_list  = Array.new
        pluralized_tables.each do |p|
          table_parts = p.split("(")
          tables_only_list.push(table_parts[0])
          if table_parts.length() > 1
            fields = table_parts[1].gsub("(", "").gsub(")", "").split("|")
            fields.each do |f|
              fk_field_tables.store(f, table_parts[0].pluralize)
            end
          end

        end
        fk_tables   = tables_only_list.map { |p| p.pluralize() }.join(",")
        from_tables += fk_tables
        includes    = "[" + tables_only_list.map { |m| "\'" + m + "\'" }.join(",") + "]"
      end




      if page_size
        session[:active_page_size]= page_size
      else
        session[:active_page_size]= @@page_size
      end

      return if request_params == nil

      all_empty               = true

      popupdate_search_string =""
      added_date              = false
      request_params.each do |date_key, date_value|
        if fk_field_tables
          if fk_field_tables.has_key?(date_key + "date2from")
            table_name = fk_field_tables[date_key + "date2from"]

          elsif fk_field_tables.has_key?(date_key + "date2to")
            table_name = fk_field_tables[date_key + "date2to"]
          end
        end

        if  date_key.include?("_date2from") && date_value.to_s.length() > 0
          added_date = true
          popupdate_search_string += table_name+"."+date_key.to_s.gsub("_date2from", "")+" >= '"+ date_value.to_s + "'  and "
          #  request_params.delete("transaction_date_date_to")
          request_params.delete(date_key)
          all_empty = false
          added_date = true
        elsif date_key.include?("_date2to") && date_value.to_s.length() > 0
          popupdate_search_string += table_name+"."+date_key.to_s.gsub("_date2to", "")+" <= '"+ date_value.to_s + "'  and "
          request_params.delete(date_key)
          # request_params.delete("transaction_date_date_from")
          all_empty = false
          added_date = true
        end
        #end

      end
      table_name = main_table

      params     = ""
      var        = Inflector.singularize(table_name)
      if added_date
        popupdate_search_string = popupdate_search_string.reverse.slice(popupdate_search_string.reverse.index("dna")+3, popupdate_search_string.length()).reverse+" and "

      end
      code  = "@" + table_name + " = " + model_name + ".find(:all,:conditions => \""+popupdate_search_string
      count = "@count = " + model_name + ".count_by_sql(\"select count(*) from " + from_tables + " where(" + popupdate_search_string


      request_params.each do |key, value|
        if fk_field_tables
          if fk_field_tables.has_key?(key)
            table_name = fk_field_tables[key]
          end
        end

        if not (value == nil ||value.to_s.strip()==""||value.to_s == "" || value.to_s.upcase().index("SELECT A VALUE")!= nil)
          code      += table_name + "." + key + " = '\#{" + key.to_s + "}' and "
          count     += table_name + "." + key + " = '\#{" + key.to_s + "}' and "
          params    += key + " = '" + request_params[key].to_s + "'\n"
          all_empty = false
        end
      end

      table_name = main_table
      if all_empty


        code  = "@" + table_name + " = " + model_name + ".find(:all"
        count = ""
        count = "@count = " + model_name + ".count" if paginate
        if paginate
          code += ","
          code += ":limit => @" + var + "_pages.items_per_page,"
          code += " :offset => @" + var + "_pages.current.offset"
          code += ",:order =>'" + order + "'" if order
          if includes != nil
            code += ",:include => " + includes
          end
          code += ")"
        else
          pager = ""
          if includes != nil
            code += ",:include => " + includes
          end
          code += ")"
        end
      else


        code  = code.slice(0, code.length()-5) + "\""

        count = count.slice(0, count.length()-5) + ")\")"

        if paginate
          code += ","
          code += ":limit => @" + var + "_pages.items_per_page,"
          code += " :offset => @" + var + "_pages.current.offset"
          code += ",:order =>'" + order + "'" if order
          if includes != nil
            code += ",:include => " + includes
          end
          code += ")"
        else
          if includes != nil
            code += ",:include => " + includes
          end
          code += ")"
        end
      end


      count = "" if !paginate

      #define pager
      pager = ""
      eval params + "\n" + count
      pager = "\n@" + var + "_pages = Paginator.new self,"
      pager += "@count, session[:active_page_size],@current_page\n"
      #puts "pager: " + pager
      eval pager if paginate


      eval code


      session[:query] = params + "\n" + count + pager + code

      return eval("@" + table_name)

    rescue

      raise $!

    end

  end

  #==========================
  #   Luks' jsession code ===
  #==========================

  #-------------------------------------------------------------------------------
  # This program implement session state for the pdt_environment
  # It loads and persist @jsesson_store into a .jss file with the same name as the
  # client's address
  #
  # @jsession_store is stored inside application controller
  # in order to make sure that it is stored in an object
  # that will have a new instance for each user(http) request
  #--------------------------------------------------------------------------------
  def get_jsession_store
    raise "jsession key is null!" if !@jsession_store_key
    begin

      if @jsession_store == nil #@jsesion doesn't exist
        if jsession_exist?
          #---------------------------------------------------------------------------------------------------------------------------
          # When loading sessions from session state,I check the last pdt program that this user persisted
          # If I find somethig,I call load_pdt_transaction_business_class() to load all the classes(i.e. transaction and state classes)
          # that the user used in their previous session
          #---------------------------------------------------------------------------------------------------------------------------
          pdt_running_program = PdtRunningProgram.find_by_user_and_pdt_client_ip(@user, @ip) if @user && @ip
          load_pdt_transaction_business_class(pdt_running_program.program, pdt_running_program.parent_class_name) if pdt_running_program!= nil
          #---------------------------------------------------------------------------------------------------------------------------

          File.open(jsession_folder + @jsession_store_key + ".jss") do |f|
            @jsession_store = load_jsession(f)
          end
        else
          @jsession_store = JSessionStore.new(@jsession_store_key, persisted_lists_folder)
        end
      end

      return @jsession_store
    rescue
      raise "jsession store could not be retrieved " + $!
    end
  end

  #---------------------------------------------------
  # load the existing (or create new if
  # not existing) session_store_file with the value of
  # @jsession_store.
  #---------------------------------------------------
  def load_jsession(file)
    session_hash = Marshal.load(file)
  end

  def jsession_exist?
    val = File.exists?(jsession_folder + @jsession_store_key + ".jss")
    return val
  end

  def persist_jsession
    return if @mode == PdtScreenDefinition.const_get("CONTROL_VALUE_REPLACE").to_s
    @jsession_store.persist_session

    #------------------------------------------------------------------------------------------------------
    # Before persisting the session,check if the user has a current running program/process
    #------------------------------------------------------------------------------------------------------
    pdt_running_program = PdtRunningProgram.find_by_user_and_pdt_client_ip(@user, @ip)
    if @jsession_store.get_session != nil && @jsession_store.get_session[:active_transaction] != nil && @jsession_store.get_session[:active_transaction].pdt_method != nil
      program           = Inflector.underscore(@jsession_store.get_session[:active_transaction].pdt_method.class_name)
      parent_class_name = Inflector.underscore(@jsession_store.get_session[:active_transaction].pdt_method.parent_class_name)
    else
      program           = nil
      parent_class_name = nil
    end
    #------------------------------------------------------------------------------------------------------
    @jsession_store.clean
    File.open(jsession_folder + @jsession_store_key + ".jss", "w+") do |f|
      Marshal.dump(@jsession_store, f)
    end

    #------------------------------------------------------------------------------------------------------
    # Before persisting the session,record into the db the program that the user is running in this session
    # either updating the previuos running_program or creating a new one
    #------------------------------------------------------------------------------------------------------
    if @jsession_store.get_session != nil && @jsession_store.get_session[:active_transaction] != nil
      if pdt_running_program == nil
        pdt_running_program                   = PdtRunningProgram.new
        pdt_running_program.user              = @user
        pdt_running_program.program           = program
        pdt_running_program.parent_class_name = parent_class_name
        pdt_running_program.pdt_client_ip     = @ip

        begin
          pdt_running_program.save
        rescue
          raise "pdt_running_program could bot be saved : " + $!
        end
      else
        begin
          pdt_running_program.update_attributes(:program => program, :parent_class_name => parent_class_name)
        rescue
          raise "pdt_running_program could bot be updated : " + $!
        end
      end
    end
    #------------------------------------------------------------------------------------------------------
  end

  #------------------------------------------------------------------------------------------------------
  # This method takes in a transaction class_name,goes through it's folder and loads the PDTTransaction
  # and all the PDTTrancasctionStates that belong to that transaction
  #------------------------------------------------------------------------------------------------------
  def load_pdt_transaction_business_class(transaction, parent_class_name)
    begin
      pdt_transaction_folder = "app/models/pdt_transactions/" + transaction
      pdt_parent_transaction_folder = "app/models/pdt_transactions/" + parent_class_name if parent_class_name
      if File.exists?(pdt_transaction_folder)
        Dir.foreach(pdt_transaction_folder) do |entry|
          if File.stat(pdt_transaction_folder + "/" + entry).directory? == false
            #puts "loading ..... " + pdt_transaction_folder + "/"+ entry
            require pdt_transaction_folder + "/"+ entry
          end
        end
      else
        if parent_class_name != nil
          if File.exists?(pdt_parent_transaction_folder)
            Dir.foreach(pdt_parent_transaction_folder) do |entry|
              if File.stat(pdt_parent_transaction_folder + "/" + entry).directory? == false
                #puts "loading ..... " + pdt_transaction_folder + "/"+ entry
                require pdt_parent_transaction_folder + "/"+ entry
              end
            end
          end
        end
      end
    rescue
      raise "pdt_transaction_business_class not loaded correctly: " + $!
      return
    end
  end

  #==========================


  #================================
  #   START OF HAPPYMORE'S CODE
  #================================
  def test_permission(program, permission)

    user       = session[:user_id]

    authorised = authorise(program, permission, user)

  end


  # This seems to be the equivalent of:
  # hash.merge!( Hash[*ret.split('!')] )
  def re_hash(ret, hash)
    if ret!=nil
      ret = "$" + ret
      key_point = ret.index("!")
      if key_point
        mykey = ret[1, key_point-1]
        unwanted_key = ret[0, key_point+1]
        ret = ret.gsub!(unwanted_key, "")
        ret = "$" + ret
        value_point = ret.index("!")
        if value_point
          myvalue = ret[1, value_point-1]
          unwanted_value = ret[0, value_point+1]
          hash.store(mykey, myvalue)
          ret = ret.gsub!(unwanted_value, "")
        else
          myvalue = ret.gsub!("$", "")
          hash.store(mykey, myvalue)
          ret = nil
        end
        re_hash(ret, hash)
      end
    end
  end

  def non_dm_detail
    record_id = params[:id]
    @record = nil
    @caption = "view details of " + @table_name.to_s + " record"
    begin
      eval "@record = " + Inflector.camelize(Inflector.singularize(@table_name)) + ".find(:first, :conditions=>['id=?', '#{record_id}'])"
    rescue
      if $!.class.to_s == "NameError"
        begin
          eval "@record = " + Inflector.camelize(@table_name) + ".find(:first, :conditions=>['id=?', '#{record_id}'])"
        rescue
          raise "Model not known!"
        end
      end
    end
    if @record==nil
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

  def view_object_form_link_field
    @id = params[:id]

    render :inline => %{
  	   <% @url = "http://" + request.host_with_port + "/" + "reports/reports/view_in_opener/" + @id %>
  	   <script>
          another_window = window.open("<%=@url%>", "<%=@id%>","width=800,height=400,top=200,left=200,toolbar=yes,menubar=yes,status=yes,scrollbars=yes,resizable=no,dialog=yes" );
          if (window.focus) {
            another_window.focus()
          }
       </script>
       <script>
          history.back()
       </script>
  	 }
  end


  def close_opened_window
    render :inline => %{
  	   <script>
  	     window.close()
  	   </script>
  	 }
  end

  def view_child_records

  end

  #===============================
  #   End Happymore's code
  #===============================


  def ajax_error_alert(msg, error=nil, model=nil)
    s = ''
    if error.nil?
      s = msg || 'Unknown error!'
      if model && model.errors
        s << "\n" << model.errors.full_messages.to_s
      end
    else
      s = error.message
      if model && model.errors
        s << "\n" << model.errors.full_messages.to_s
      end
    end

    render :update do |page|
      page << "alert('#{escape_javascript(s)}')"
    end
  end

  #=====================================================
  #== Added by Luks                                 ====
  #== N.B. maybe code should move to dynamic_search ====
  #=====================================================
  def nullify_empty_foreign_id_params_before_create(params)
    params.each do |key, val|
      params[key] = nil if (params[key] == "")
    end
  end

  def remove_empty_foreign_id_search_params_before_dynamic_search(params)
    params.each do |key, val|
      params.delete(key) if (params[key] == "")
    end

  end


  #*******************************
  #****** PdtLogs and PdtErrors i**
  #*******************************
  def extract_menu_tree(menu_item)
    menu_item_components = menu_item.split('.')
    level = menu_item_components.length - 1
    tree = {}
    case level
      when 0
        tree.store(:functional_area, "&#060 empty &#062")
        tree.store(:program, "&#060 empty &#062")
        tree.store(:program_function, "&#060 empty &#062")
        tree.store(:special_menu, menu_item)
      when 2
        tree.store(:functional_area, "#{menu_item_components[0]}.#{menu_item_components[1]}")
        tree.store(:program, menu_item)
        tree.store(:program_function, "&#060 empty &#062")
        tree.store(:special_menu, "&#060 empty &#062")
      when 3
        tree.store(:functional_area, level = "#{menu_item_components[0]}.#{menu_item_components[1]}")
        tree.store(:program, "#{menu_item_components[0]}.#{menu_item_components[1]}.#{menu_item_components[2]}")
        tree.store(:program_function, menu_item)
        tree.store(:special_menu, "&#060 empty &#062")
      else
        tree.store(:functional_area, "&#060 empty &#062")
        tree.store(:program, "&#060 empty &#062")
        tree.store(:program_function, "&#060 empty &#062")
        tree.store(:special_menu, "&#060 empty &#062")
    end
    return tree
  end

  def load_menu_items_friendly_names
    if (!session[:menu_items_friendly_names])
      session[:menu_items_friendly_names] = {'1a' => 'Refresh', '1b' => 'Undo', '1c' => 'Cancel', '1d' => 'Save Process', '1d.1' => 'Save Process Submit', '1e' => 'Load Process', '1e.1' => 'Load Process Submit', '1f' => 'Redo', '1g' => 'Exit Process', '1g.1' => 'Confirm Exit Process'}
      functional_areas = FunctionalArea.find_by_sql("select functional_area_name,display_name from functional_areas where is_non_web_program is true").map { |g| session[:menu_items_friendly_names].store(g.functional_area_name, g.display_name) }
      programs = Program.find_by_sql("select program_name,display_name from programs where is_non_web_program is true").map { |g| session[:menu_items_friendly_names].store(g.program_name, g.display_name) }
      program_functions = ProgramFunction.find_by_sql("select name,display_name from program_functions where is_non_web_program is true").map { |g| session[:menu_items_friendly_names].store(g.name, g.display_name) }
    end
  end


  # To check the params of an AJAX call, use this action which will show the params used in the request.
  def test_ajax
    render :text => "alert('#{params.inspect} ');", :layout => false
  end

  def processing(processing_action, id)
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'	  
    @uri = "/#{request.request_parameters['controller']}/#{processing_action}/?id=#{id}"
    render :inline => %{
      <!--<script> window.resizeTo(500,350) </script>-->
      <img id='processing_img' src= "/images/processing.gif" style="position: relative; top: 20px;left: 150px;" />
      <div id='decoy'> </div>

      <script>
        function makeAjaxCall(uri) {

          new Ajax.Updater('decoy', uri, {asynchronous:true,
               evalScripts:true,
               onComplete:function(request){var processing_img = document.getElementById('processing_img');processing_img.style.position='absolute';processing_img.style.visibility = 'hidden';},
               method: 'get',
               insertion: Insertion.Bottom
             });

        }

        makeAjaxCall("<%= @uri %>");
      </script>
    }, :layout => 'content'
  end

  # Ask user to set the printer choice.
  # The default is to set the session's :intake_printer key, but if an id parameter
  # is supplied the session's key will be the id as a symbol ('admin_printer' => :admin_printer).
  def set_printer
    @content_header_caption = "'select a printer'"
    if params[:id]
      @printer_type = params[:id]
    else
      @printer_type = 'intake_printer'
    end

    render :inline => %{
                        <%= build_printer_selection_form(@printer_type)%>
                        }, :layout => 'content'
  end

  def set_printer_submit
    printer_name = params['printer']['friendly_name']
    printer = Printer.find_by_friendly_name(printer_name)
    printer_type = params[:printer][:printer_type]

    session[printer_type.to_sym] = printer.system_name

    redirect_to_index("printer set to: " + printer_name + "   (system name is: " + printer.system_name + ")")

  end

  def stop_active_print_job(printing_ip, printing_server_port, printer_name)
    require 'net/http'
    Net::HTTP.start(printing_ip, printing_server_port) do |http|
      begin
        response = http.get("<StopBulkPrint PID=\"692\" Printer=\"#{printer_name}\" />", nil)
      rescue #EOFError
        flash[:notice] = "Print cancelled"
        @content_header_caption = "'Printing cancelled'"
        render :inline => %{
        }, :layout => 'content'
      end
    end
  end

  # Take a query and convert it to return values for a particular id.
  def shape_query_for_id(statement, for_id, table_name=nil)
    idname = table_name.nil? ? 'id' : "#{table_name}.id"
    shape_query_for_new_where(statement, "where(#{idname} = #{for_id})")
  end

  # Take a query and convert it use a new WHERE clause.
  def shape_query_for_new_where(statement, where_clause)
    statement.sub(/where\s*\(.+\)/i, where_clause)
  end

  # Returns an array of Integer ids by manipulating the params returned
  # from a multiselect grid.
  def ids_from_multi_select_grid_params( format=:integers )
    if :strings == format
      params[:selection][:list].gsub(/\[|\]/, '').split(',').map {|r| r }
    else
      params[:selection][:list].gsub(/\[|\]/, '').split(',').map {|r| r.to_i }
    end
  end

  # Sets the @grid_selected_rows for a multi_select grid.
  # Pass an array of ids (String or Integer)
  def pre_select_ids_for_multi_select_grid( ids )
    row_identifier      = Struct.new(:id)
    @grid_selected_rows = ids.map {|i| row_identifier.new(i.to_i) }
  end

  def show_or_hide_person_org_names(party_type, model_name)
    if party_type == Party::ORGANIZATION
      render :text => "jQuery('##{model_name}_organisation_name').show();jQuery('.org_type').show();jQuery('##{model_name}_first_name').hide();jQuery('##{model_name}_last_name').hide();jQuery('.person_type').hide();", :layout => false
    else
      render :text => "jQuery('##{model_name}_organisation_name').hide();jQuery('.org_type').hide();jQuery('##{model_name}_first_name').show();jQuery('##{model_name}_last_name').show();jQuery('.person_type').show();", :layout => false
    end
  end

  # Save the current URL. Call this before listing a grid.
  def store_last_grid_url
    session[:last_grid_url] = request.request_parameters
  end

  # Return the last_grid_url.
  def last_grid_url
    url_for( session[:last_grid_url] )
  end

  # Store any url for listing a grid. With no parameters will default to list_ action for the current controller.
  # If the option :unless_already_set is true, it will only set the session var if the existing url is for a different controller.
  def store_list_as_grid_url(options={})
    url_parts  = request.request_uri.split('/')
    url_parts.pop if url_parts.last.is_numeric? # remove optional id
    url_parts.pop                               # remove action
    url_parts.shift if url_parts.first.blank?   # remove blank element representing leading '/'
    controller = options[:controller] || url_parts.join('/')
    action     = options[:action]     || "list_#{url_parts.last.pluralize}"

    return if options[:unless_already_set] && session[:last_grid_url] && session[:last_grid_url]['controller'] == controller

    session[:last_grid_url] = {'action' => action, 'controller' => controller}
  end

  # Redirect to the saved URL. Call this typically after an update to return to the grid that provided the edit link.
  def redirect_to_last_grid
    # Ensure flash notice is not discarded by the check_login action.
    flash[:keep_flash_on_redirect] = true unless flash[:notice].nil?

    if session[:last_grid_url].nil?
      redirect_to_index
    else
      redirect_to session[:last_grid_url]
    end
  end

  # Action that a form can post to to return to a grid.
  def return_to_grid
    redirect_to_last_grid
  end

  # Action clicked in child form. Load new page in Content frame.
  def render_content_from_frame(href)
    render :inline=>%{
      <%= close_popup_window( nil, :new_href => '#{href}', :has_no_popup => true ) %>
    }, :layout => 'content'
  end

  # Implement a version of escape_javascript to have it available in controllers.
  def make_str_javascript(str)
    str.gsub('\\','\0\0').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
  end

  # Convert the parameters of saved changes from a grid to an Array of Hashes:
  # [{:id => 1, :editable_column1 => 'value', :editable_column2 => 'value'}, {:id => ...}]
  def grid_edited_values_to_array(params)
    eval(params[:grid_values]).map do |row|
      row.each do |k,v|
        if :id != k
          row[k] = v.nil? ? v : v.gsub('%27', "'").gsub('%22', '"') # JS turned single quotes into %27 and double quotes into %22.
        end
      end
    end
  end

end
