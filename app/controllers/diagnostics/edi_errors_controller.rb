class Diagnostics::EdiErrorsController < ApplicationController


  def program_name?
    "edi_errors"
  end

  def bypass_generic_security?
    true
  end

  def search_edi_errors
    dm_session['se_layout'] = 'content'
    @content_header_caption = "'search for edi errors'"    
    build_remote_search_engine_form("search_edi_errors.yml", "search_edi_errors_grid")
    dm_session[:redirect] = true

  end

  def search_edi_errors_grid
    @edi_errors = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    @content_header_caption="edi errors"
    render_list_edi_errors_grid
  end

  def list_edi_errors
    @edi_errors = EdiError.find_by_sql("select * from edi_errors order by created_on desc limit 100")
	render_list_edi_errors_grid
  @content_header_caption="edi errors"
  end

  def errors_today
  time=Time.now
  d=time.day
  m=time.month
  y=time.year
  start_time =Time.local("#{y}","#{m}","#{d}",00,00)
  time=time.strftime("%Y-%m-%d %H:%M:%S")
  start_time =start_time.strftime("%Y-%m-%d %H:%M:%S")
  @edi_errors = EdiError.find_by_sql("select * from edi_errors where created_on between '#{start_time}' and '#{time}' order by created_on desc ")
	render_list_edi_errors_grid
  @content_header_caption="edi errors"
  end

  def last_10_errors
     @edi_errors = EdiError.find_by_sql("select * from edi_errors  order by id  desc limit 10")
      render_list_edi_errors_grid
      @content_header_caption="edi errors"
  end

  def render_list_edi_errors_grid
    @can_edit = authorise(program_name?,'edit',session[:user_id])
            @can_delete = authorise(program_name?,'delete',session[:user_id])
            @can_cancel=  authorise(program_name?,'cancel',session[:user_id])
            render :inline => %{
            <% grid = build_edi_errors_grid(@edi_errors,@can_edit,@can_delete)%>
            <% grid.caption ='edi errors'%>
            <% @header_content = grid.build_grid_data %>
             <%= grid.render_html %>
             <%= grid.render_grid %>
          },:layout => 'content'

  end

  def view_error

     @active_record_instance=EdiError.find(params[:id].to_i)
     @table                 ="edi_errors"
     render_view_form
   end

   def render_view_form
     render :inline => %{
           <% @content_header_caption = "'#{@table}'"%>
           <%= build_view_record_form(@active_record_instance,nil,"none",@table)%>
           }, :layout => 'content'
   end

































end
