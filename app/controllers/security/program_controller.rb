class Security::ProgramController < ApplicationController

  def program_name?
    "program"
  end

  def list_programs


    return if authorise_for_web('program', 'read') == false

    query = "@program_pages = Paginator.new self, Program.count, @@page_size,params['page']
	        @programs = Program.find(:all,
			 :limit => @program_pages.items_per_page,
			 :offset => @program_pages.current.offset)"
    @programs = eval(query)
    session[:query]= query
    render_list_programs
  end


  def render_list_programs
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])

    render :inline => %{
      <% grid            = build_program_grid(@programs,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all programs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@program_pages) if @program_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_programs_flat
    return if authorise_for_web('program', 'read')== false
    @is_flat_search = true
    render_program_search_form
  end

  def render_program_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  programs'"%> 

		<%= build_program_search_form(nil,'submit_programs_search','submit_programs_search',@is_flat_search)%>

		}, :layout => 'content'
  end

  def search_programs_hierarchy
    return if authorise_for_web('program', 'read')== false

    @is_flat_search = false
    render_program_search_form(true)
  end

  def render_program_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  programs'"%> 

		<%= build_program_search_form(nil,'submit_programs_search','submit_programs_search',@is_flat_search)%>

		}, :layout => 'content'
  end

  def submit_programs_search
    #session[:programs] = nil
    @program_pages = Paginator.new self, Program.count, 20, params['page']
    if params[:page]== nil
      @programs = dynamic_search(params[:program], 'programs', 'Program')
    else
      @programs = eval(session[:query])
    end
    if @programs.length == 0
      if params[:page] == nil
        flash[:notice] = 'no records were found for the query'
        @is_flat_search = session[:is_flat_search].to_s
        render_program_search_form
      else
        flash[:notice] = 'There are no more records'
        render_list_programs
      end
    else
      #session[:programs] = @programs
      #@programs = session[:programs]
      render_list_programs
    end
  end


  def delete_program
    return if authorise_for_web('program', 'delete')== false
    begin
      id = params[:id]
      if id && program = Program.find(id)
        program.destroy
        session[:alert] = " Record deleted."
#		 update in-memory recordset
        #@programs = session[:programs]
        # delete_record(@programs,id)
        #session[:programs] = @programs
        render_list_programs
      end
    rescue
      msg = "Program could not be deleted. The following exception was reported b the system: <br> " + $!
      handle_error(msg)
    end
  end

  def new_program
    return if authorise_for_web('program', 'create')== false
    render_new_program
  end

  def create_program
    @program = Program.new(params[:program])
    if @program.save
      #update in-memory list- if it exists
      #if session[:programs]
      #	 session[:programs].push @program
      #end
      redirect_to_index("'new record created successfully'", "'create successful'")
    else
      @is_create_retry = true
      render_new_program
    end
  end

  def render_new_program
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new program'"%> 

		<%= build_program_form(@program,'create_program','create_program',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_program
    return if authorise_for_web('program', 'edit')==false
    id = params[:id]
    if id && @program = Program.find(id)
      render_edit_program

    end
  end


  def render_edit_program
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'edit program'"%> 

		<%= build_program_form(@program,'update_program','update_program',true)%>

		}, :layout => 'content'
  end

  def update_program
    id = params[:program][:id]
    if id && @program = Program.find(id)
      if @program.update_attributes(params[:program])

        @programs = eval(session[:query])
        render_list_programs
      else
        render_edit_program

      end
    end
  end


#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(programs)
#	-----------------------------------------------------------------------------------------------------------
  def program_program_name_search_combo_changed
    program_name = get_selected_combo_value(params)
    session[:program_search_form][:program_name_combo_selection] = program_name
    @functional_area_names = Program.find_by_sql("Select distinct functional_area_name from programs where program_name = '#{program_name}'").map { |g| [g.functional_area_name] }
    @functional_area_names.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
    render :inline => %{
		<%= select('program','functional_area_name',@functional_area_names)%>

		}

  end


#================================================================================================================
#    Export program to remote connection
#================================================================================================================

  def export_to_remote_connection
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]

    if session[:program_id] ==nil
      session[:program_id] = Hash.new
      session[:program_id].store("record_id", id)
    else
      session[:program_id] = nil
      session[:program_id] = Hash.new
      session[:program_id].store("record_id", id)
    end

    if session[:connection_params] == nil
      session[:connection_params] = Hash.new
      #session[:connection_params].store("record_id", id)
      @host = ""
      @db = ""
      @uname = ""
      @pword = ""
      @rec_id = id
      render :template=>'/security/program/export_to_remote_connection.rhtml', :layout=>'content'

    else
      if session[:connection_params].has_key?("host") and session[:connection_params].has_key?("db") and session[:connection_params].has_key?("uname") and session[:connection_params].has_key?("pword")
        @host = session[:connection_params].fetch("host")
        @db = session[:connection_params].fetch("db")
        @uname = session[:connection_params].fetch("uname")
        @pword = session[:connection_params].fetch("pword")
        render :inline=> %{
	                <script>
	                     if (confirm("Do you want to use these connection settings?.\\n Host: '#{@host}'\\n Database: '#{@db}'\\n Username: '#{@uname}'\\n Password: '#{@pword}'")== true) {
	                         window.location.href = '/security/program/params_usage_confirmed';
	                     }else {
	                         window.location.href = '/security/program/params_usage_unconfirmed';
	                     }
	                </script>
	           }

      else
        @host = ""
        @db = ""
        @uname = ""
        @pword = ""
        @rec_id = id
        render :template=>'/security/program/export_to_remote_connection.rhtml', :layout=>'content'
      end
    end
  end

  def params_usage_confirmed
    @host = session[:connection_params].fetch("host")
    @db = session[:connection_params].fetch("db")
    @uname = session[:connection_params].fetch("uname")
    @pword = session[:connection_params].fetch("pword")
    @rec_id = id
    render :template=>'/security/program/export_to_remote_connection.rhtml', :layout=>'content'
  end

  def params_usage_unconfirmed
    @host = ""
    @db = ""
    @uname = ""
    @pword = ""
    #@rec_id = id
    session[:connection_params]=nil
    session[:connection_params] = Hash.new
    #session[:connection_params].store("record_id", id)

    render :template=>'/security/program/export_to_remote_connection.rhtml', :layout=>'content'
  end


  def export_to_remote
    host = params[:host]
    db = params[:database]
    uname = params[:username]
    pword = params[:password]



    rec_id = session[:program_id].fetch("record_id")


    if host=="" || db=="" ||uname=="" ||pword==""

      flash[:notice] = "Fill in all boxes for connection parameters please!"

      render :template=>'/security/program/export_to_remote_connection.rhtml', :layout=>'content'

    else
      #session[:connection_params].store("record_id", id) if !session[:connection_params].has_key?("record_id")
      session[:connection_params].store("host", host)
      session[:connection_params].store("db", db)
      session[:connection_params].store("uname", uname)
      session[:connection_params].store("pword", pword)

      errors = ProgramExporter.new(host, db, uname, pword, rec_id).export_data
      if errors.length()== 0
        redirect_to_index("program exported successfully")

      elsif errors.has_key?("exists")
        flash[:notice] = "PROGRAM ALREADY IN THE REMOTE DATABASE!"
        #@programs = session[:programs] if !@programs
        render_list_programs

      else
        flash[:notice] = "Program could not be exported!"
      end
    end
  end

#===============================================================================================================
#    End Export program to remote connection
#===============================================================================================================

  def export_program
    begin
      program = Program.find(params[:id])
      program_functions = ProgramFunction.find_all_by_program_id(program.id)
      File.open(Globals.security_configs + "/program_settings/" + program.program_name + "_settings.yml", "w+") do |out|
        YAML.dump([program.functional_area, [program, program_functions]], out)
#        YAML.dump(program.functional_area,out)
      end
      redirect_to_index("'program [#{program.program_name}] exported successfully '", "'export successful'")
    rescue
      redirect_to_index("'program could not be exported #{$!.to_s}'", "'export unsuccessful'")
    end
  end

  def load_program
    render :inline=>%{
     <% @content_header_caption = "'load program'"%>

		<%= build_load_program_form(@program,'load_program_submit','load')%>

		}, :layout => 'content'
  end

  def load_program_submit
    begin
      file_name = Globals.security_configs + "program_settings/" + params[:program][:program_settings_file].to_s + ".yml"
      File.open(file_name, "r+") do |infile|
        settings = YAML.load(infile)
        ActiveRecord::Base.transaction do
          @functional_area = FunctionalArea.new(settings[0].attributes)
          @functional_area.save if !FunctionalArea.exists?(:functional_area_name=>settings[0].attributes['functional_area_name'])
          @program = Program.new(settings[1][0].attributes)
          @program.save if !Program.exists?(:program_name=>@program.program_name, :functional_area_name=>@functional_area.functional_area_name)
        end

        settings[1][1].each do |prog_func|
          @program_function = ProgramFunction.new(prog_func.attributes)
          @program_function.save if !ProgramFunction.exists?(:program_name=>@program.program_name, :functional_area_name=>@functional_area.functional_area_name, :name=>@program_function.name)
        end
      end
      redirect_to_index("'program [#{params[:program][:program_settings_file].to_s}] imported successfully'", "'import successful'")
    rescue
      redirect_to_index("'program could not be imported #{$!.to_s}'", "'imxport unsuccessful'")
    end
  end

  def reorder_program_functions
    @program = Program.find(params[:id])
    @program_functions = @program.program_functions.find(:all, :order => 'position')
    render :template=>'/security/program/reorder_program_functions.rhtml', :layout=>'content'
  end

  def apply_program_function_order
    @program = Program.find(params[:id])
    new_order = nil
    unless params[:re_ordered_list].blank?
      new_order = params[:re_ordered_list].split(',').map {|a| a.sub('id_','').to_i }
    end

    if new_order
      @program.re_order_funcs( new_order )
      flash[:notice]                 = 'Program functions have been reordered'
    else
      flash[:error] = 'Nothing to do: you did not re-order any program functions'
    end
    list_programs
  end

end
