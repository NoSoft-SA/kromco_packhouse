class Security::UsersController < ApplicationController

  layout "content"

  def program_name?
    "users"
  end

  def admin_exceptions?
    #["add_user"]
  end

  # List all the users.
  def find_users

    #display a form that will allow a user to search hierarchically by
    #department,lastname,firstname,user
    render :template => "security/users/find_users",:layout => "content"
  end

  #--------------------------------------------------------------------------
  #Associate a program with a user:
  #Show form to allow a user to select a program and a security group
  #--------------------------------------------------------------------------
  def add_program

    @user_id = params[:id]
    render :template => "security/users/add_program",:layout => "tree_node_content"
  end


  #------------------------------------------------------------------------------
  #Slight trickiness here: We cannot simply always remove the program node on the
  #tree: if the program to be deleted is the one and only program node under a
  #functional area node, we should, instead, delete the functional area node- which
  #will destroy the program node along with it
  #------------------------------------------------------------------------------
  def remove_program
    begin
      id = params[:id].to_i
      prog_user = ProgramUser.find(id)

      user_id = prog_user.user.id
      func_area_name = prog_user.program.functional_area.functional_area_name
      @node_id = "func_area!" + user_id.to_s + "_" + prog_user.program.functional_area.id.to_s
      if prog_user.destroy
        flash[:notice]= "program access removed for user"

        if !FunctionalArea.exists_for_user?(user_id,func_area_name)
          #get the functional area node id


          render :inline => %{
            <% @hide_content_pane = true %>
            <% @is_menu_loaded_view = true %>
            <% @tree_actions = "window.parent.RemoveNode('" + @node_id + "');" %>
          },:layout => "tree_node_content"

        else

          render :inline => %{
            <% @hide_content_pane = true %>
            <% @is_menu_loaded_view = true %>
            <% @tree_actions = "window.parent.RemoveNode(null);" %>
          },:layout => "tree_node_content"
        end
      else
        redirect_to_index("program access could not be removed for user")
      end
    rescue

      handle_error("Program access could not be removed for user",true)
    end
  end


  def get_unique_id(record_id)
    match = session["users_tree_ids"].find{|i| i == record_id }
    return (session["users_tree_ids"].rindex(match)).to_s
  end

  def create_unique_id(record_id)
    session["users_tree_ids"].push record_id
    return (session["users_tree_ids"].length() - 1).to_s
  end

  def get_record_id(unique_id)
    return session["users_tree_ids"][unique_id]
  end

  def change_sec_group
    #build_sec_group_form(action,caption)
    prog_user_id = get_record_id(params[:id].to_i)
    prog_user = ProgramUser.find(prog_user_id)
    @user_name = prog_user.user.user_name
    @prog_name = prog_user.program.program_name
    @freeze_flash = true
    flash[:notice] = "The permission field data is only shown for viewing purposes"
    session[:prog_user] = prog_user_id
    render :template => "security/users/change_sec_group",:layout => "tree_node_content"

  end


  def change_sec_group_submit

    @sec_group_name = params[:sec_group][:security_group_name]

    prog_user = ProgramUser.find(session[:prog_user])
    @program_name = prog_user.program.program_name
    sec_group = SecurityGroup.find_by_security_group_name(@sec_group_name)
    prog_user.security_group = sec_group
    if prog_user.save
      flash[:notice]= "security group saved"
      render :template => "security/users/sec_group_changed",:layout => "tree_node_content"
    else
      redirect_to_index("The security group update failed")
    end
  end

  #---------------------------------------------------------------------------------
  #Create a new program_user association
  #use the simple read_access group as the default security group in the association
  #---------------------------------------------------------------------------------
  def add_program_submit
    begin

      user = User.find(session[:add_program_form][:user_id].to_i)

      prog_name = params[:program][:program_name]
      func_area_name = params[:program][:functional_area_name]

      program = Program.find_by_program_name_and_functional_area_name(prog_name,func_area_name)
      sec_group = SecurityGroup.find_by_security_group_name("basic_user")

      #create the associative record
      prog_user = ProgramUser.new
      prog_user.user = user
      prog_user.security_group = sec_group
      prog_user.program = program

      #we need to know if the user has an existing program with the functional area
      #of the newly added program- if not we need to create the functional area tree node on the client
      if ! FunctionalArea.exists_for_user?(user.id,func_area_name)

        @create_func_area = true
        @func_area_parent_id = "user!" + user.id.to_s
        @func_area_node_name = func_area_name
        @func_area_node_type = "func_area"
        @func_area_node_id = user.id.to_s + "_" + prog_user.program.functional_area.id.to_s


        @tree_name = "users"
      end

      if prog_user.create

        #-----------------------------------------------------------------------------------
        #slightly tricky part here is to 're-create' the javascript parent id - that is, the
        #id of the functional area to which this program belong. The normal addition mode
        #to a tree node is simply a child node addition. In this case a node is added to
        #a completely unrelared parent node to the one that issued the addition command
        #-----------------------------------------------------------------------------------
        parent_record_id = FunctionalArea.find_by_functional_area_name(func_area_name).id
        @parent_id = "func_area!" + user.id.to_s + "_" + parent_record_id.to_s

        @node_name = program.program_name
        @node_type = "program"
        @node_id = prog_user.id.to_s #this will be unique- can use record id as is
        @tree_name = "users"

        #----------------------------------------------------------------------------------------
        #Second slightly tricky part is that we need to add a second node- the default security
        #group to the program that we just added
        #----------------------------------------------------------------------------------------
        @parent_prog_id =  "program!" + @node_id
        @sec_group_id = create_unique_id(prog_user.id)
        @sec_group_name = @node_name + ": " + prog_user.security_group.security_group_name

        flash[:notice] = "Access to program '#{@node_name}' granted for user"
        render :template => "security/users/program_added",:layout => "tree_node_content"
      else
        redirect_to_index("Program access could not be granted to user")
      end
    rescue
      handle_error("Program access could not be created for user",true)
    end
  end


  def edit_user

    id = params[:id]
    if request.get?
      @user = User.find(id)
      #    puts "PUTSA : " + session[:user_id].to_s
      #    if(@user != session[:user_id])
      #      flash[:error] = "You cannot change this user's details"
      #      render :inline=>%{<% @page_title = "Edit User" -%>
      #                        <% @hide_content_pane = true %>
      #                        <% @is_menu_loaded_view = true %>
      #      },:layout=>'tree_node_content'
      #      return
      #    end
      render :template => "security/users/edit_user",:layout => "tree_node_content"
    else
      @user = User.find(id)

      if @user.update_attributes(params[:user])
        @user.email_address=params[:user][:email_address]
        @user.update
        @new_text = @user.user_name
        flash[:notice]= "user updated"
        render :template => "security/users/user_edited",:layout => "tree_node_content"

      end
    end
  end

  def delete_user
    id = params[:id]

    if id && user = User.find(id)
      begin
        user.destroy
        #session[:alert] = "User #{user.user_name} deleted"
      rescue
        handle_error("user could not be deleted",true)
        return
      end
    end
    flash[:notice]= "user deleted"
    render :template => "security/users/user_deleted",:layout => "tree_node_content"
  end

  def get_password

    id = params[:id]
    user = User.find(id)
    password = user.get_clear_password

    flash[:notice]= "password is: " + password
    render :inline => %{
      <% @freeze_flash = true %>
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>

    },:layout => "tree_node_content"


  end

  def add_user

    begin

      if request.get?
        @user = User.new
        render :template => "security/users/add_user",:layout => "tree_node_content"
      else

        @user                 = User.new(params[:user])
        user                  = params[:user]
        pid                   = user[:person_id].to_i
        person                = Person.find(pid)
        @user.person          = person
        @user.first_name      = person.first_name
        @user.last_name       = person.last_name
        department            = Department.find(user[:department])
        @user.department      = department
        @user.department_name = department.department_name
        @user.email_address   = params[:user][:email_address]
        #find and set the department,first_name and lastname attributes

        if @user.save
          #@node_name,@node_type,@node_id,@tree_name
          @node_name = @user.user_name
          @node_type = "user"
          @node_id = @user.id.to_s
          @tree_name = "users"
          flash[:notice] = "user added"
          render :template => "security/users/user_added",:layout => "tree_node_content"
        end
      end
    rescue
      handle_error("new user could not be created",true)
    end
  end

  def find_users_submit
    begin
      session[:users] = nil
      @users = dynamic_search(params[:user] ,'users','User',false,"")

      if @users.length == 0

        flash[:notice] = 'no records were found for the query'
        render :template => "security/users/find_users",:layout => "content"

      else

        #session[:users] = @users
        #@users = session[:users]
        render :template => "security/users/list_users",:layout => "tree"
      end
    rescue
      raise "Users query failed: Exception is: \n" + $!
    end
  end

  #----------------------------------------------------
  #combo changed event handler for change sec group form
  #-----------------------------------------------------
  def sec_group_security_group_name_combo_changed

    sec_group = get_selected_combo_value(params)


    @permissions = SecurityGroup.permissions_for_group(sec_group)

    #  render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
      <%= select(nil,nil,@permissions)%>

    }

  end

  #------------------------------------------------
  #combo changed event handler for add_program form
  #------------------------------------------------
  def program_functional_area_combo_changed

    functional_area = get_selected_combo_value(params)
    session[:add_program_form][:functional_area_combo_selection] = functional_area

    @programs = Program.find_all_by_functional_area_name(functional_area).map{|g|[g.program_name]}

    #  render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
      <%= select('program','program_name',@programs)%>

    }

  end




  #  -----------------------------------------------------------------------------------------------------------
  #   search combo_changed event handlers for the unique index on this table(users)
  #  -----------------------------------------------------------------------------------------------------------
  def user_department_name_search_combo_changed
    department_name = get_selected_combo_value(params)
    session[:user_search_form][:department_name_combo_selection] = department_name
    @last_names = User.find_by_sql("Select distinct last_name from users where department_name = '#{department_name}'").map{|g|[g.last_name]}
    @last_names.unshift("<empty>")

    #  render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
      <%= select('user','last_name',@last_names)%>
      <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_user_last_name'/>
      <%= observe_field('user_last_name',:update => 'first_name_cell',:url => {:action => session[:user_search_form][:last_name_observer][:remote_method]},:loading => "show_element('img_user_last_name');",:complete => session[:user_search_form][:last_name_observer][:on_completed_js])%>
    }

  end


  def user_last_name_search_combo_changed
    last_name = get_selected_combo_value(params)
    session[:user_search_form][:last_name_combo_selection] = last_name
    department_name =   session[:user_search_form][:department_name_combo_selection]
    @first_names = User.find_by_sql("Select distinct first_name from users where last_name = '#{last_name}' and department_name = '#{department_name}'").map{|g|[g.first_name]}
    @first_names.unshift("<empty>")

    #  render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
      <%= select('user','first_name',@first_names)%>
      <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_user_first_name'/>
      <%= observe_field('user_first_name',:update => 'user_name_cell',:url => {:action => session[:user_search_form][:first_name_observer][:remote_method]},:loading => "show_element('img_user_first_name');",:complete => session[:user_search_form][:first_name_observer][:on_completed_js])%>
    }

  end


  def user_first_name_search_combo_changed
    first_name = get_selected_combo_value(params)
    session[:user_search_form][:first_name_combo_selection] = first_name
    last_name =   session[:user_search_form][:last_name_combo_selection]
    department_name =   session[:user_search_form][:department_name_combo_selection]
    @user_names = User.find_by_sql("Select distinct user_name from users where first_name = '#{first_name}' and last_name = '#{last_name}' and department_name = '#{department_name}'").map{|g|[g.user_name]}
    @user_names.unshift("<empty>")

    #  render (inline) the html to replace the contents of the td that contains the dropdown
    render :inline => %{
      <%= select('user','user_name',@user_names)%>

    }

  end


  #::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  #       Happymore's code starts here
  #::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

  def export_permissions_locally
    begin
      id = params[:id].to_i
      if session[:program_user_export]==nil
        session[:program_user_export] = Hash.new
      else
        session[:program_user_export]=nil
        session[:program_user_export] = Hash.new
      end
      session[:program_user_export].store("prog_user_id",id)
      session[:program_user_export].store("locally","yes")
      @usernames = User.find(:all).map{|g| [g.user_name]}
      render :template=> "/security/users/select_user.rhtml", :layout=>'tree_node_content'

    rescue
      handle_error("Permissions could not be exported!")
    end
  end

  def export_permissions_remotely
    begin
      id = params[:id].to_i
      if session[:program_user_export]==nil
        session[:program_user_export] = Hash.new
      else
        session[:program_user_export]=nil
        session[:program_user_export] = Hash.new
      end
      session[:program_user_export].store("prog_user_id",id)
      session[:program_user_export].store("remotely","yes")

      if session[:connection_params] == nil
        session[:connection_params] = Hash.new
        #session[:connection_params].store("record_id", id)
        @host = ""
        @db = ""
        @uname = ""
        @pword = ""
        @rec_id = id
        render :template=>'/security/users/export_permissions_connections.rhtml',:layout=>'tree_node_content'

      else
        if session[:connection_params].has_key?("host") and session[:connection_params].has_key?("db") and session[:connection_params].has_key?("uname") and session[:connection_params].has_key?("pword")
          @host = session[:connection_params].fetch("host")
          @db = session[:connection_params].fetch("db")
          @uname = session[:connection_params].fetch("uname")
          @pword = session[:connection_params].fetch("pword")
          render :inline=> %{
            <script>
            if (confirm("Do you want to use these connection settings?.\\n Host: '#{@host}'\\n Database: '#{@db}'\\n Username: '#{@uname}'\\n Password: '#{@pword}'")== true) {
            window.location.href = '/security/users/params_usage_confirmed';
                           }else {
            window.location.href = '/security/users/params_usage_unconfirmed';
                           }
            </script>
          }

        else
          @host = ""
          @db = ""
          @uname = ""
          @pword = ""
          @rec_id = id
          render :template=>'/security/users/export_permissions_connections.rhtml',:layout=>'tree_node_content'
        end
      end

    rescue
      handle_error("Permissions could not be exported!")
    end
  end

  def params_usage_confirmed
    @host = session[:connection_params].fetch("host")
    @db = session[:connection_params].fetch("db")
    @uname = session[:connection_params].fetch("uname")
    @pword = session[:connection_params].fetch("pword")
    #@rec_id = id
    render :template=>'/security/users/export_permissions_connections.rhtml',:layout=>'tree_node_content'
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

    render :template=>'/security/users/export_permissions_connections.rhtml',:layout=>'tree_node_content'
  end

  def select_user
    #begin
    dest_string = params[:host]
    db = params[:database]
    uname = params[:username]
    pword = params[:password]

    if dest_string=="" || db=="" ||uname=="" ||pword==""

      flash[:notice] = "Fill in all boxes for connection parameters please!"

      render :template=>'/security/users/export_permissions_connections.rhtml',:layout=>'tree_node_content'

    else
      #session[:connection_params].store("record_id", id) if !session[:connection_params].has_key?("record_id")
      session[:connection_params].store("host", dest_string)
      session[:connection_params].store("db", db)
      session[:connection_params].store("uname", uname)
      session[:connection_params].store("pword", pword)


      conn_test = PGconn.connect(dest_string,5432,"","",db,uname,pword)
      @remote_users = conn_test.exec("select * from users")
      @usernames = Array.new
      @remote_users.each do |row|
        @usernames.push row[1]
      end
      render :template=>'/security/users/select_user.rhtml',:layout=>'tree_node_content'
    end

    #rescue
    #    raise "Could not connect to remote server"
    #end
  end


  def export
    if session[:program_user_export].has_key?("locally")
      prog_user_id = session[:program_user_export].fetch("prog_user_id")
      prog_user = ProgramUser.find(prog_user_id)

      prog_name = prog_user.program.program_name
      func_area_name = prog_user.program.functional_area.functional_area_name
      sec_group = prog_user.security_group.security_group_name

      username = params[:users]

      test_user = User.find(:first, :conditions=>["user_name = ?",params[:users]])

      if test_user
        confirm = ProgramUser.find(:first, :conditions=>['user_id = ? and program_id = ? and security_group_id = ?', test_user.id.to_i, prog_user.program_id.to_i, prog_user.security_group_id.to_i])

        if confirm

          flash[:notice] = "User is already entitled to these permissions!"
          render :inline => %{
            <% @hide_content_pane = true %>
            <% @is_menu_loaded_view = true %>

          },:layout => "tree_node_content"
        else
          u_id = test_user.id
          prog_id = prog_user.program_id
          sec_group_id = prog_user.security_group_id

          new_prog_user = ProgramUser.new
          new_prog_user.user_id = u_id.to_i
          new_prog_user.program_id = prog_id.to_i
          new_prog_user.security_group_id = sec_group_id.to_i
          if new_prog_user.save
            flash[:notice] = "Permissions exported successifully!"
            render :inline => %{
              <% @hide_content_pane = true %>
              <% @is_menu_loaded_view = true %>

            },:layout => "tree_node_content"
          end
        end
      end
    elsif session[:program_user_export].has_key?("remotely")
      #remotely
      host = session[:connection_params].fetch("host")
      db = session[:connection_params].fetch("db")
      uname = session[:connection_params].fetch("uname")
      pword = session[:connection_params].fetch("pword")

      session[:program_user_export].store("selected_user",params[:users])

      prog_user_id = session[:program_user_export].fetch("prog_user_id")
      prog_user = ProgramUser.find(prog_user_id)
      prog_id = prog_user.program_id
      prog_name = prog_user.program.program_name
      func_area_name = prog_user.program.functional_area.functional_area_name
      sec_group = prog_user.security_group.security_group_name

      #session[:program_user_export].store("program_user_id", prog_user_id)
      session[:program_user_export].store("prog_name", prog_name)
      prog_user_id = session[:program_user_export].fetch("prog_user_id")
      prog_name = session[:program_user_export].fetch("prog_name")
      selected_user = session[:program_user_export].fetch("selected_user")

      errors = PermissionsExporter.new(host,db,uname,pword,prog_user_id,prog_name,selected_user,prog_id).export_data
      if errors.length()==0
        redirect_to_index("Permissions exported successifully!")
      elsif errors.has_key?("exists")
        flash[:notice] = "These permissions are already entitled to the selected user"
        render :inline => %{
          <% @hide_content_pane = true %>
          <% @is_menu_loaded_view = true %>

        },:layout => "tree_node_content"
      else
        flash[:notice] = "Permissions could not be exported"
        render :inline => %{
          <% @hide_content_pane = true %>
          <% @is_menu_loaded_view = true %>

        },:layout => "tree_node_content"
      end
    end
  end

  #======================================
  # export entire user permissions
  #======================================

  def export_entire_permissions
    begin
      id = params[:id].to_i
      if session[:entire_permissions]==nil
        session[:entire_permissions] = Hash.new
      else
        session[:entire_permissions] =nil
        session[:entire_permissions] = Hash.new
      end
      session[:entire_permissions].store("user_id",id)
      @usernames = User.find(:all, :order => 'user_name').map{|g| [g.user_name]}
      render :template=> "/security/users/select_user_template.rhtml", :layout=>'tree_node_content'

    rescue
      handle_error("Permissions could not be exported!")
    end
  end

  def export_all_locally
    begin
      user_id = session[:entire_permissions].fetch("user_id")
      @program_users = ProgramUser.find(:all, :conditions=>["user_id = ?", user_id])
      selected_username = params[:users]
      @selected_user = User.find(:first, :conditions=>["user_name = ?", selected_username])
      # for each program_user in @program_users, test if the selected user is entitled to the permission
      @program_users.each do |prog_user|
        test = ProgramUser.find(:first, :conditions=>["user_id = ? and program_id = ? and security_group_id = ?",@selected_user.id.to_i, prog_user.program_id.to_i, prog_user.security_group_id.to_i])
        if not test
          @new_program_user = ProgramUser.new
          @new_program_user.user_id = @selected_user.id.to_i
          @new_program_user.program_id = prog_user.program_id.to_i
          @new_program_user.security_group_id = prog_user.security_group_id.to_i
          @new_program_user.save
        end
      end
      #@users = session[:users]
      flash[:notice] = "Permissions exported successifully!"
      #render :template => "security/users/list_users",:layout => "tree"

      render :inline => %{
        <% @hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>

      },:layout => "tree_node_content"
    rescue
      handle_error("Permissions could not be exported!")
    end
  end

  #======================================
  # end export entire user permissions
  #======================================


  #::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  #       Happymore's code ends here
  #::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

  #========================================
  #===== Luks' request_lock code ==========
  #========================================
  def list_request_locks

    if params[:page]!= nil

      session[:request_locks_page] = params['page']

      render_list_request_locks

      return
    else
      session[:request_locks_page] = nil
    end

    list_query = "@request_lock_pages = Paginator.new self, RequestLock.count, @@page_size,@current_page
   @request_locks = RequestLock.find(:all,
         :limit => @request_lock_pages.items_per_page,
         :offset => @request_lock_pages.current.offset)"
    session[:query] = list_query
    render_list_request_locks
  end


  def render_list_request_locks
    @current_page = session[:request_locks_page] if session[:request_locks_page]
    @current_page = params['page'] if params['page']
    @request_locks =  eval(session[:query]) if !@request_locks
    render :inline => %{
      <% grid            = build_request_lock_grid(@request_locks,@can_delete) %>
      <% grid.caption    = 'list of all request_locks' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@request_lock_pages) if @request_lock_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end

  def delete_request_lock
    begin
      if params[:page]
        session[:request_locks_page] = params['page']
        render_list_request_locks
        return
      end
      id = params[:id]
      if id && request_lock = RequestLock.find(id)
        request_lock.destroy
        session[:alert] = " Record deleted."
        render_list_request_locks
      end
    rescue
      #handle_error('record could not be deleted',true)
      flash[:notice] =  $!
      render :inline => %{}, :layout => 'content'
    end
  end
  #========================================

  def change_password
    render :inline => %{
      <%=build_change_user_password_form("change_user_password","change_password")%>
    }, :layout => 'content'
  end

  def change_user_password
    @user = session[:user_id]
    if @user.update_attributes(params[:user])
      session[:alert]= "user password changed"
      render :inline => %{
        <script>
        window.close();
        </script>
      }, :layout => 'content'
    end
  end
end
