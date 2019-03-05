class WebPdtLoginController < ApplicationController
  layout "web_pdt"

  def index
    render :inline => %{}, :layout => 'content'
  end

  def pdt_login

    if request.env['HTTP_USER_AGENT'].downcase.match(/android|iphone/)
      session[:pdt_menu_css_class] = "mobile_web_pdt_menu"
      session[:pdt_content_header_css_class] = "mobile_web_pdt_content_header"
      session[:pdt_content_css_class] = "mobile_web_pdt_content"
      session[:pdt_content_container_css_class] = "mobile_web_pdt_content_container"
      session[:pdt_messages_css_class] = "mobile_web_pdt_messages"
      session[:pdt_messages_cols] = "38"
      session[:pdt_button_css_class] = "mobile_web_pdt_button_css_class"
      session[:pdt_field_css_class] = "mobile_web_pdt_field_css_class"
      session[:pdt_text_line_css_class] = "mobile_web_pdt_text_line_css_class"
      session[:pdt_busy_sinner] = "mobile_web_busy_sinner_css_class"
    else
      session[:pdt_menu_css_class] = "pc_web_pdt_menu"
      session[:pdt_content_header_css_class] = "pc_web_pdt_content_header"
      session[:pdt_content_css_class] = "pc_web_pdt_content"
      session[:pdt_content_container_css_class] = "pc_web_pdt_content_container"
      session[:pdt_messages_css_class] = "pc_web_pdt_messages"
      session[:pdt_messages_cols] = "35"
      session[:pdt_button_css_class] = "pc_pdt_button_css_class"
      session[:pdt_field_css_class] = "pc_pdt_field_css_class"
      session[:pdt_text_line_css_class] = "pc_pdt_text_line_css_class"
      session[:pdt_busy_sinner] = "pc_pdt_busy_sinner_css_class"
    end


    if session[:pdt_user_id]!= nil
      # flash[:notice] = " A user from this browser is already logged in"
      # redirect_to_index
      pdt_logged_in
      return
    end

    if request.get?
      session[:pdt_user_id] = nil
      @user = User.new
      @web_pdt_notice = "Please log in"
    else
      @user = User.new(params[:user])
      logged_in_user = @user.try_to_login

      if logged_in_user
        session[:pdt_user_id] = logged_in_user
        pdt_logged_in
      else
        puts "invalid user"
        @web_pdt_notice = "Invalid user/password combination"
      end
    end
  end

  def pdt_logged_in

    @func_areas = FunctionalArea.find(:all, :conditions => "program_users.user_id=#{session[:pdt_user_id].id} and programs.is_non_web_program is true",
                                      :select=>"distinct functional_areas.*",
                                      :joins => "join programs on programs.functional_area_id=functional_areas.id
                                                 join program_users on program_users.program_id=programs.id").map{|f| ["#{f.functional_area_name}[#{f.display_name}]",f.functional_area_name]}

    render :template => "web_pdt_login/pdt_logged_in",:layout => 'rmd_layout' # "content"
  end

  def pdt_logout
    session[:pdt_user_id]= nil
    render :inline=>%{
          <script>
               {window.location.href = "/web_pdt_login/pdt_login";}
          </script>
      }
  end

  def web_pdt_func_area_search_combo_changed
    func_area = get_selected_combo_value(params)
    session[:web_pdt_search_form][:func_area_combo_selection] = func_area
    @programs = Program.find_all_by_functional_area_name(func_area).map{|p| ["#{p.program_name}[#{p.display_name}]",p.program_name]}
    @programs.unshift(["<empty>",])
    render :inline=>%{
        <%=select('web_pdt','prog',@programs) %>
        <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_web_pdt_prog'/>
        <%= observe_field('web_pdt_prog', :update=>'prog_func_cell', :url => {:action=>session[:web_pdt_search_form][:prog_observer][:remote_method]}, :loading=>"show_element('img_web_pdt_prog');", :complete=>session[:web_pdt_search_form][:prog_observer][:on_completed_js])%>
        <script>
          var prog_menu_dropdown = document.getElementById('web_pdt_prog');
          expandDropDown(prog_menu_dropdown);

          <%= update_element_function(
          "web_pdt_prog_func", :action => :update,
          :content =>select('web_pdt','prog_func',['<empty>']))%>
        </script>
    }
  end

  def web_pdt_prog_search_combo_changed
    prog = get_selected_combo_value(params)
    if(prog.to_s=='')
      render :inline=>%{

        }
      return
    elsif(prog && (@program=Program.find(:first,:select=>"programs.*",:conditions=>"programs.program_name='#{prog}'")) && @program.is_leaf)
      if session[:pdt_user_id]== nil
        pdt_logout
        return
      end
      # <%=select('web_pdt','prog_func',['<empty>']) %>
      render :inline=>%{
        <script>
          var content_frame=document.getElementById('content_frame');
          onMenuSelectedScreenSubmit(content_frame,'<%=session[:pdt_user_id].user_name%>','<%=@program.program_name%>');
          submitWebPdtScreen('menu');
        </script>
      }
    else
      session[:web_pdt_search_form][:prog_combo_selection] = prog
      @program_functions = ProgramFunction.find_all_by_program_name(prog).map{|p| ["#{p.name}[#{p.display_name}]",p.name]}
      @program_functions.unshift(["<empty>"])
      render :inline=>%{
          <%=select('web_pdt','prog_func',@program_functions) %>
          <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_web_pdt_prog_func'/>
          <%= observe_field('web_pdt_prog_func', :update=>'dummy_cell', :url => {:action=>session[:web_pdt_search_form][:prog_func_observer][:remote_method]}, :loading=>"show_element('img_web_pdt_prog_func');", :complete=>session[:web_pdt_search_form][:prog_func_observer][:on_completed_js])%>

          <script>
            var prog_func_menu_dropdown = document.getElementById('web_pdt_prog_func');
            expandDropDown(prog_func_menu_dropdown);
          </script>
      }
    end
  end

  def web_pdt_prog_func_search_combo_changed
    prog_func = get_selected_combo_value(params)
    session[:web_pdt_search_form][:prog_func_combo_selection] = prog_func
    if session[:pdt_user_id]== nil
      pdt_logout
      return
    elsif(prog_func.to_s=='')
      render :inline=>%{
        <%=hidden_field('web_pdt','dummy')%>
      }
      return
    end

    render :inline=>%{
      <%=hidden_field('web_pdt','dummy')%>

        <script>
          var content_frame=document.getElementById('content_frame');
          onMenuSelectedScreenSubmit(content_frame,'<%=session[:pdt_user_id].user_name%>','<%=session[:web_pdt_search_form][:prog_func_combo_selection]%>');
          submitWebPdtScreen('menu');
        </script>
    }
  end

  def web_pdt_special_menus_search_combo_changed
    @special_menu = get_selected_combo_value(params)
    if(@special_menu=='log_off' || !session[:pdt_user_id])
      pdt_logout
    elsif(@special_menu.to_s=='')
      render :inline=>%{
        <%=hidden_field('web_pdt','dummy')%>
      }
    else
      render :inline=>%{
        <%=hidden_field('web_pdt','dummy')%>

        <script>
          var content_frame=document.getElementById('content_frame');
          onPdtSpecialMenuClicked(content_frame,'<%=session[:pdt_user_id].user_name%>','<%=@special_menu%>');

          var current_menu_item = content_frame.contentDocument.getElementById('web_pdt_screen_web_pdt_current_menu_item_submit_value');
          current_menu_item.value= "<%=@special_menu%>";

          submitWebPdtScreen('menu');
        </script>

      }
    end
  end
end
