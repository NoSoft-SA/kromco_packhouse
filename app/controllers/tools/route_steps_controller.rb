class Tools::RouteStepsController < ApplicationController
  def program_name?
    "route_steps"
  end

  def bypass_generic_security?
    true
  end

  def list_route_steps
#    if params[:id]
      @can_edit = authorise(program_name?,'edit',session[:user_id])
      @can_delete = authorise(program_name?,'delete',session[:user_id])
      @current_page = session[:mrl_results_page] if session[:mrl_results_page]
      @current_page = params['page'] if params['page']
      @route_steps =  eval(session[:query]) if !@route_steps

       if @route_steps.length() != 0
        render :inline => %{
      <% grid            = build_route_steps_grid(@route_steps,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of route_steps' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@route_steps_pages) if @route_steps_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
       else
         clear_route_steps_grid
       end
#    else
#      search_route_steps
#    end
  end

  def search_route_steps
    session[:route_step_type] = nil
      render :inline=>%{
          <% @content_header_caption = "'route_steps'"%>
          <%= build_list_route_teps(@route_steps,nil,'')%>
      }, :layout=>'content'
  end

  def render_route_steps_grid_form
    render :inline => %{
                        <%
                                  field_config =
                                            {:id_value =>nil,
                                            :link_text=>'add_route_step',
                                            :host_and_port =>request.host_with_port.to_s,
                                            :controller => request.path_parameters['controller'].to_s,
                                            :target_action=>'add_route_step'}


                          popup_link = ApplicationHelper::LinkWindowField.new(nil,nil, 'none','none','none',field_config,true,nil,self)
                        @child_form_caption = ["route_steps_grid_form","route steps " + popup_link.build_control]
                        %>
                      }, :layout=>'content'
  end

  def route_step_type_code_combo_changed
    route_step_type_code = get_selected_combo_value(params)
    session[:route_step_type] = route_step_type_code
    session[:route_step_type] = nil if session[:route_step_type] == ""
    if session[:route_step_type]
      list_query = "@route_steps_pages = Paginator.new self, MrlResult.count, @@page_size,@current_page
         @route_steps = RouteStep.find(:all, :conditions =>['route_step_type_id = ?', '#{session[:route_step_type]}'],
               :limit => @route_steps_pages.items_per_page,
               :offset => @route_steps_pages.current.offset)"
        session[:query] = list_query
     render :inline=>%{
      <script>
        img = document.getElementById('img_route_steps_route_step_type_code');
        if(img != null)img.style.display = 'none';
        window.frames[0].location.href ='/tools/route_steps/list_route_steps/<%=session[:route_step_type]%>';
      </script>
      },:layout=>'content'
    else
      render :inline=>%{
      <script>
        img = document.getElementById('img_route_steps_route_step_type_code');
        if(img != null)img.style.display = 'none';
        window.frames[0].location.href ='/tools/route_steps/clear_route_steps_grid';
      </script>
      },:layout=>'content'
    end
  end

  def clear_route_steps_grid
    session[:alert] = "no route steps"
    render :inline=>%{},:layout=>'content'
  end

  def add_route_step
    if !session[:route_step_type]
      session[:alert] = "please select a route step type"
       render :inline=>%{
          <script>
            window.close();
          </script>
      },:layout=>'content'
    else
      @caption = "add"
      @action = 'submit_add_route_step'
      new_route_steps
    end    
  end

  def new_route_steps
    route_step_type = RouteStepType.find(session[:route_step_type])
    @content_header_caption = "'adding route step type to rout step type[#{route_step_type.route_step_type_code}]'"
    render :inline=>%{<%= build_route_step_form(@route_step,@action,@caption)%>},:layout=>'content'
  end

  def edit_route_step
#    session[:alert] = params[:id].to_s + " | " + params[:id].class.name
    @caption = "save"
    @action = 'submit_edit_route_step'
    @route_step = RouteStep.find(params[:id])
    session[:route_step] = params[:id]
    new_route_steps
  end

  def delete_route_step
      route_step = RouteStep.find(params[:id])
      if route_step.destroy
        session[:alert] = 'route_step deleted successfully'
      else
        session[:alert] = 'could not delete route_step record'
      end
        params[:id] = session[:route_step_type]
        list_route_steps
    end

  def submit_add_route_step
    @route_step = RouteStep.new(params[:route_step])
    route_step_type = RouteStepType.find(session[:route_step_type])
    if route_step_type
      @route_step.route_step_type = route_step_type
      if @route_step.save
        session[:alert] = "route step record created successfully"
        list_query = "@route_steps_pages = Paginator.new self, MrlResult.count, @@page_size,@current_page
         @route_steps = RouteStep.find(:all, :conditions =>['route_step_type_id = ?', '#{session[:route_step_type]}'],
               :limit => @route_steps_pages.items_per_page,
               :offset => @route_steps_pages.current.offset)"
        session[:query] = list_query
        
        render :inline=>%{
          <script>
            window.opener.frames[1].frames[0].location.href ='/tools/route_steps/list_route_steps/<%=session[:route_step_type]%>';
            window.close();
          </script>
      },:layout=>'content'
      else
        add_route_step
      end
    else
      session[:alert] = "'Could not create route step record - please select rout step type'"
        render :inline=>%{
          <script>
            window.close();
          </script>
      },:layout=>'content'
    end
  end

  def submit_edit_route_step    
    @route_step = RouteStep.find(session[:route_step])
    if @route_step
      if @route_step.update_attributes(params[:route_step])
        session[:alert] = "route step record edited successfully"
        list_query = "@route_steps_pages = Paginator.new self, MrlResult.count, @@page_size,@current_page
         @route_steps = RouteStep.find(:all, :conditions =>['route_step_type_id = ?', '#{session[:route_step_type]}'],
               :limit => @route_steps_pages.items_per_page,
               :offset => @route_steps_pages.current.offset)"
        session[:query] = list_query

        render :inline=>%{
          <script>
            window.opener.frames[1].frames[0].location.href ='/tools/route_steps/list_route_steps/<%=session[:route_step_type]%>';
            window.close();
          </script>
      },:layout=>'content'
      else
        add_route_step
      end
    else
      session[:alert] = "colud not edit record"
      render :inline=>%{
          <script>
            window.close();
          </script>
      },:layout=>'content'
    end
  end
end
