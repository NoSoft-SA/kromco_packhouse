require File.dirname(__FILE__) + '/../../../lib/app_factory.rb'
require File.dirname(__FILE__) + '/../../../lib/data_exporter.rb'

class DevelopmentTools::CrudToolsController < ApplicationController

  layout 'content'

  def admin_exceptions?
    ["create_model"]
  end

  def archive_records
    redirect_to :action => "archive_records", :controller => "development_tools/archiving"
  end

  def correct_rebin_templates

    count = 0
    templates = RebinTemplate.find(:all)
    RebinTemplate.transaction do
      templates.each do |template|
        template.rmt_product_code = template.rebin_setup.rmt_product_code
        template.update
        count += 1
      end
    end

    @freeze_flash = true
    redirect_to_index("templates updated: " + count.to_s)

  end

  def strange
    rebins = RwReceiptRebin.find(:all)
    wrongs = 0
    rights = 0
    Rebin.transaction do

      rebins.each do |rebin|

        rebin.rmt_product_code = rebin.rebin.rmt_product_code
        rebin.update

      end


      r_rebins = RwReclassedRebin.find(:all)
      r_rebins.each do |rebin|

        bin = Rebin.find_by_rebin_number(rebin.rebin_number)
        if bin == nil

          wrongs += 1
        else

          rebin.rmt_product_code = bin.rmt_product_code
          rebin.update
          rights += 1
        end
      end

    end
    @freeze_flash = true
    redirect_to_index("DONE: right: " + rights.to_s + " Wrong: " + wrongs.to_s)

  end


  def correct_reworks_rmt_codes

#     rebins = RwReceiptRebin.find(:all)
#     wrongs = 0
#      rights = 0
#     Rebin.transaction do
#
#      rebins.each do |rebin|
#       puts "before"
#         rebin.rmt_product_code = rebin.rebin.rmt_product_code
#         rebin.update
#         puts "RECeipt updated"
#     end


#       r_rebins = RwReclassedRebin.find(:all)
#      r_rebins.each do |rebin|
#         puts "before 2"
#         bin = Rebin.find_by_rebin_number(rebin.rebin_number)
#         if bin == nil
#          puts "NO rebin for: " + rebin.rebin_number.to_s
#           wrongs += 1
#         else
#          puts "UPDATED"
#           rebin.rmt_product_code = bin.rmt_product_code
#           rebin.update
#           rights += 1
#         end
#     end

    #   end
    @freeze_flash = true
    redirect_to_index("DONE: right: " + rights.to_s + " Wrong: " + wrongs.to_s)

  end

  def correct_rmt_codes

    rebins = Rebin.find(:all)
    count = 0
    no_runs = 0
    Rebin.transaction do

      rebins.each do |rebin|
        if  rebin.production_run
          comm_group = rebin.production_run.production_schedule.rmt_setup.rmt_product.commodity_group_code
          treatment_code = "STD"

          product = RmtProduct.create_if_needed("rebin", comm_group, rebin.commodity_code, rebin.marketing_variety_code, rebin.size_code, rebin.class_code, rebin.ripe_point_code, treatment_code, rebin.product_code_pm_bintype)
          rebin.rmt_product_code = product.rmt_product_code
          rebin.update
          count += 1
        else
          no_runs += 1
        end
      end
    end
    @freeze_flash = true
    redirect_to_index("DONE.Rebins updated: " + count.to_s + " no runs: " + no_runs.to_s)

  end


  def export_table
    render :inline => %{
      <% @content_header_caption = \"'export table data to remote database'\" %>
      <%= create_table_export_form %>

    }, :layout => "content"
  end

  def export_table_submit
    begin

      errors = DataExporter.new(params[:exporter][:export_table]).export_table_data
      err = ""
      if errors.length() == 0
        redirect_to_index("data exported successfully")
      else
        err = "<table><tr><td colspan = 2><strong>Table data could not be copied to remote database. The following record insertions failed</strong></td><td/></tr>"
        errors.each do |key, error|

          err += "<tr><td><strong>" + key.to_s + "</strong>&nbsp;&nbsp</td><td>" + error.to_s + "</td></tr>"
        end
        err += "</table>"

        handle_error(err)

      end
    rescue
      handle_error("Table data could not be copied to remote database")
    end
  end

  def create_model

    render :template => "development_tools/crud_tools/create_model", :layout => "content"

  end

  def create_view_helper

    render :template => "development_tools/crud_tools/create_view_helper", :layout => "content"

  end

  def create_controller

    render :template => "development_tools/crud_tools/create_controller", :layout => "content"

  end

  def save_view_helper

    msg = nil
    table = params[:model][:table_name]
    functional_area = params[:model][:functional_area]
    @code = nil
    @model_name = nil

    if params[:model][:create_file] == "0" && params[:model][:show_code]== "0" && params[:model][:create_code_file] == "0"
      @freeze_flash = true
      redirect_to_index("What's the point. PLease check one of the checkboxes")
      return
    end

    settings = AppFactory::ModelFactory.get_settings(table)

    if params[:model][:create_file]== "1"

      code_lines = AppFactory::ModelFactory.create_view_helper_file(table, functional_area)
      msg = " View helper created for model " + settings.model_name
    end

    if params[:model][:create_code_file]== "1"

      code_lines = AppFactory::ModelFactory.create_view_helper_file(table, functional_area, true)
      msg = " View helper created for model " + settings.model_name
    end

    if params[:model][:show_code]== "1"

      view_settings = AppFactory::ViewSettings.new(settings, functional_area)
      @code = AppFactory::ModelFactory.format_code_to_htm(view_settings.to_code_lines)
      @model_name = settings.model_name
      flash[:notice] = msg if msg != nil
      render :inline => %{

     <% @content_header_caption = "'generated ruby code for view helper'" %>
     <%= @code %>

     }, :layout => "content"
    else

      redirect_to_index(msg)
    end
  end

  def set_security

    render :template => "development_tools/crud_tools/set_security", :layout => "content"

  end

  def save_security_settings
    #(program_name,functional_area_name)
    program_name = Inflector.singularize(params[:model][:table_name])
    functional_area_name = params[:model][:functional_area]

    #create functional area if non existing
    if !func_area = FunctionalArea.find_by_functional_area_name(functional_area_name)

      func_area = FunctionalArea.new
      func_area.functional_area_name = functional_area_name
      func_area.create

    end

    #create program if non existing
    if !prog = Program.find_by_program_name_and_functional_area_id(program_name, func_area.id)

      prog = Program.new
      prog.program_name = program_name
      prog.display_name = Inflector.pluralize(program_name)
      prog.functional_area = func_area
      prog.functional_area_name = func_area.functional_area_name
      prog.create

    end

    #create the various prpgram functions

    functions = Array.new
    func = "list_" + Inflector.pluralize(program_name)
    functions.push func
    func = "search_" + Inflector.pluralize(program_name) + "_flat"
    functions.push func
    func = "search_" + Inflector.pluralize(program_name) + "_hierarchy"
    functions.push func
    func = "new_" + program_name
    functions.push func

    functions.each do |sec_func|
      create_prog_function(prog, sec_func)
    end

    #associate the logged-on user to the created program and security group crud_admin
    #this is to allow the logged-on user to test the created program
    sec_group = SecurityGroup.find_by_security_group_name("crud_admin")
    user = session[:user_id]
    prog_user = ProgramUser.new
    prog_user.program = prog
    prog_user.user = user
    prog_user.security_group = sec_group
    prog_user.create
    redirect_to_index("security environment created for program '#{program_name}'")

  end

  def create_prog_function(program, name)
    if !prog_func = ProgramFunction.find_by_name_and_program_id(name, program.id)
      prog_func = ProgramFunction.new
      prog_func.name = name
      prog_func.program = program
      prog_func.program_name = program.program_name
      prog_func.functional_area_name = program.functional_area.functional_area_name
      prog_func.create
    end

  end

  def save_controller

    msg = nil
    table = params[:model][:table_name]
    functional_area = params[:model][:functional_area]
    @code = nil
    @model_name = nil

    if params[:model][:create_file] == "0" && params[:model][:show_code]== "0" && params[:model][:create_code_file]== "0"
      @freeze_flash = true
      redirect_to_index("What's the point. PLease check one of the checkboxes")
      return
    end

    settings = AppFactory::ModelFactory.get_settings(table)

    if params[:model][:create_file]== "1"

      code_lines = AppFactory::ModelFactory.create_controller_file(table, functional_area)
      AppFactory::ModelFactory.save_settings(settings)
      msg = " Controller " + settings.model_name + "Controller created"
    end

    if params[:model][:create_code_file]== "1"

      code_lines = AppFactory::ModelFactory.create_controller_file(table, functional_area, true)
      msg = " Controller " + settings.model_name + "Controller created"

    end


    if params[:model][:show_code]== "1"

      controller_settings = AppFactory::ControllerSettings.new(settings, functional_area)
      @code = AppFactory::ModelFactory.format_code_to_htm(controller_settings.to_code_lines)
      @model_name = settings.model_name
      flash[:notice] = msg if msg != nil
      render :inline => %{

     <% @content_header_caption = "'generated ruby code for model:" + @model_name + "'" %>
     <%= @code %>

     }, :layout => "content"
    else

      redirect_to_index(msg)
    end
  end

  def save_model

    msg = nil
    table = params[:model][:table_name]
    @code = nil
    @model_name = nil

    if params[:model][:create_file] == "0" && params[:model][:show_code]== "0" && params[:model][:create_code_file]== "0"
      @freeze_flash = true
      redirect_to_index("What's the point. PLease check one of the checkboxes")
      return
    end

    settings = AppFactory::ModelFactory.get_settings(table)

    if params[:model][:create_file]== "1"

      AppFactory::ModelFactory.create_model_file(settings, true)
      AppFactory::ModelFactory.save_settings(settings)
      msg = " Model " + settings.model_name + " created"
    end

    if params[:model][:create_code_file]== "1"

      code_lines = AppFactory::ModelFactory.create_model_file(settings, true, true)
      msg = " Model " + settings.model_name + " created"

    end

    if params[:model][:show_code]== "1"

      @freeze_flash = false
      @code = AppFactory::ModelFactory.format_code_to_htm(settings.to_code_lines)
      @model_name = settings.model_name
      flash[:notice] = msg if msg != nil
      render :inline => %{

     <% @content_header_caption = "'generated ruby code for model:" + @model_name + "'" %>
     <%= @code %>

     }, :layout => "content"
    else

      redirect_to_index(msg)
    end
  end

  def create_yml_report
    @report_groups = DataMinerReport.find(:all, :select => 'DISTINCT group_name', :order => 'group_name').map {|r| r.group_name }.unshift('None')
  end

  def save_yml_report

    msg = nil
    model = Inflector.classify(params[:table_name])
    use_model = true
    begin
      x = model.constantize
    rescue
      use_model = false
    end

    if use_model
      @code = AppFactory::YamlMaker.make_yml_report_string( model, params[:group_name])
    else
      @code = AppFactory::YamlMaker.make_yml_report_without_model(params[:table_name], params[:group_name])
    end

    if params[:save_file]
      File.open("reports/xxxsearch_#{params[:table_name]}.yml", 'w') do |f|
        f << @code
      end
      msg = "Saved DataMiner YAML file as reports/xxxsearch_#{params[:table_name]}.yml. Be sure to tweak the content!"
    end

    if ENV['USE_CODERAY']
      #@code = CodeRay.encode(@code, :yaml, :html, :css => :style).gsub("\n", "<br />")
      @code = CodeRay.encode(@code, :yaml, :html).gsub("\n", "<br />")
    end

    flash[:notice] = msg if msg != nil
    render :inline => %{
      <% @content_header_caption = "'DataMiner YAML report for model: #{model}'" %>
      <div class='CodeRay'><pre><%= @code %></pre></div>
    }, :layout => "content"

  end

  def show_reference
    @icons = []
    File.foreach('public/stylesheets/grid_icons_n_colours.css') do |l|
      if l =~ /\A.context-menu-item\.icon-/
        s = l.split(' ')[0].sub(/\A\./,'')
        s2 = l.split('{')[1].split('}').first.strip
        @icons << [s.split('icon-').last, s2]
      end
    end
    @icons.sort!

  end

  def db_structure
    @dbstruct = DbStructure::Output.new
    render :inline => %{
      <%= @dbstruct.generate %>
    }, :layout => false
  end

  def state_changes
    render :inline => <<-EOF, :layout => 'content'
      <% @content_header_caption = "'Show state changes for model instance'" %>
      <form action="/development_tools/crud_tools/show_state_changes" method="post" onSubmit="show_element('ident_spinner');">
      <table>
      <tr><td>Model class:</td><td><%= text_field_tag :model_class %></td><td style="font-size: smaller; color: #777;">Use CamelCase - "LoadInstruction" (To get a pallet from a pallet_sequence_id, use "PalletSeq")</td></tr>
      <tr><td align="right">Id:</td><td><%= text_field_tag :id %></td><td></td></tr>
      <tr><td colspan="3"><%= submit_tag %></td></tr>
      </table>
      </form>
    EOF

  end

  def show_state_changes
    redirect_to :controller => 'tools/processes', :action => 'show_object_transactions', :model => "#{params[:model_class]}/#{params[:id]}"
  end

end



