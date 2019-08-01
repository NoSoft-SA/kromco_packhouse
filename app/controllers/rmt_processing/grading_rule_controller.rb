class  RmtProcessing::GradingRuleController < ApplicationController

  def program_name?
    "grower_grading"
  end

  def is_existing_rule?
    grading_rule = CartonGradingRule.find_by_sql("select * from carton_grading_rules where
                    new_size  = '#{params[:grading_rule]['new_size']}'  and
                    new_class = '#{params[:grading_rule]['new_class']}' and
                    grade     = '#{params[:grading_rule]['grade']}'     and
                    variety   = '#{params[:grading_rule]['variety']}'   and
                    line_type = '#{params[:grading_rule]['line_type']}' and
                    size      = '#{params[:grading_rule]['size']}'      and
                    product_class_code = '#{params[:grading_rule]['product_class_code']}' and
                    carton_grading_rule_header_id = #{session[:active_doc]['rule_header']} and
                    track_slms_indicator_code     = '#{params[:grading_rule]['track_slms_indicator_code']}'
                   ")

    return true if !grading_rule.empty?
  end

  def create_carton_grading_rule
    if params[:grading_rule]['new_size'] == nil || params[:grading_rule]['new_size'] == nil || params[:grading_rule]['track_slms_indicator_code']== nil ||
       params[:grading_rule]['new_size'] == "" || params[:grading_rule]['new_size'] == "" || params[:grading_rule]['track_slms_indicator_code']==""
       flash[:error] = 'new size ,new class or new track_slms_indicator_code cannot be null '
       new_carton_grading_rule
    else
      if is_existing_rule?
        flash[:error] = 'rule already exists '
        new_carton_grading_rule
      else
      begin
        @grading_header_id = session[:active_doc]['rule_header']
        grading_header= CartonGradingRuleHeader.find(session[:active_doc]['rule_header'])
        @grading_rule = CartonGradingRule.new(:new_size => params[:grading_rule]['new_size'],
                                           :new_class => params[:grading_rule]['new_class'],
                                           :grade => params[:grading_rule]['grade'],
                                           :product_class_code => params[:grading_rule]['product_class_code'],
                                           :variety => params[:grading_rule]['variety'],
                                           :line_type => params[:grading_rule]['line_type'],
                                           :size => params[:grading_rule]['size'],
                                           :carton_grading_rule_header_id => session[:active_doc]['rule_header'],
                                           :created_by =>  "'#{session[:user_id]['user_name']}'" ,
                                           :created_at => "'#{Time.now}'" ,
                                         :track_slms_indicator_code=> params[:grading_rule]['track_slms_indicator_code']
                                              )

        if grading_header.activated
            @grading_rule.activated_at ="'#{Time.now}'"
            @grading_rule.activated = true
            @grading_rule.activated_by = "#{session[:user_id]['user_name']}"
        end
        @grading_rule.save
        flash[:notice] = 'record saved'
        render :inline => %{<script>
                                window.close();
                                window.opener.location.href = '/rmt_processing/grading_rule/list_grading_rules/<%=@grading_header_id%>';
                        </script>}, :layout=>"content"

      rescue
        handle_error('record could not be saved')
      end
    end
    end
  end

  def new_carton_grading_rule
    set_active_doc("rule_header" ,params[:id])
    rules = CartonGradingRule.find_all_by_carton_grading_rule_header_id(session[:active_doc]['rule_header'])
    @grading_rule = CartonGradingRule.new
    @grading_rule.clasi = nil
    @grading_rule.track_slms_indicator_code = rules[0]['track_slms_indicator_code'] if !rules.empty?
    render :inline => %{
		<% @content_header_caption = "'new rule'"%>
		<%= build_carton_grading_rule_form(@grading_rule,'create_carton_grading_rule','create',false,true)%>
		}, :layout => 'content'
  end

  def update_carton_grading_rule
    @grading_rule = CartonGradingRule.find(session[:active_doc]['rule'])
    set_active_doc("rule_header",@grading_rule.carton_grading_rule_header_id)
    params[:grading_rule]['track_slms_indicator_code'] = @grading_rule.track_slms_indicator_code
    if is_existing_rule?
      flash[:error] = 'rule already exists'
      params[:id] = @grading_rule.id
      edit_carton_grading_rule
      else
    begin
        @grading_header_id = session[:active_doc]['rule_header']
        if @grading_rule.update_attributes(:new_size => params[:grading_rule]['new_size'],
                                           :new_class => params[:grading_rule]['new_class'],
                                           :grade => params[:grading_rule]['grade'],
                                           :product_class_code => params[:grading_rule]['product_class_code'],
                                           :variety => params[:grading_rule]['variety'],
                                           :line_type => params[:grading_rule]['line_type'],
                                           :size => params[:grading_rule]['size'])
          @grading_rule
          flash[:notice] = 'record saved'
          render :inline => %{<script>
                                window.close();
                                window.opener.location.href = '/rmt_processing/grading_rule/list_grading_rules/<%=@grading_header_id%>';
                        </script>}, :layout=>"content"
        else
          list_grading_rules
        end
    rescue
      handle_error('record could not be saved')
    end
    end
  end

  def delete_carton_grading_rule_header
   begin
    ActiveRecord::Base.connection.execute("
                       delete from carton_grading_rules where  carton_grading_rule_header_id = #{params[:id]};
                       delete from carton_grading_rule_headers where  id = #{params[:id]};  ")
    session[:alert]  = "deleted"
    view_carton_grading_rule_headers
   rescue
     handle_error($!.message)
   end
  end

  def edit_carton_grading_rule
    @grading_rule = CartonGradingRule.find_by_sql(grading_rule_sql("where cgr.id = #{params[:id]}"))[0]
    set_active_doc("rule",params[:id])
    render_carton_edit_grading_rule_form
  end

  def render_carton_edit_grading_rule_form
    render :inline => %{
		<% @content_header_caption = "'edit rule'"%>
		<%= build_carton_grading_rule_form(@grading_rule,'update_carton_grading_rule','update',true,false)%>
		}, :layout => 'content'
  end



  def delete_carton_grading_rule
    begin
    ActiveRecord::Base.connection.execute("delete from carton_grading_rules where  id = #{params[:id]}")
    session[:alert]  = "deleted"
    params[:id] = session[:active_doc]['rule_header']
    list_grading_rules
  rescue
    handle_error($!.message)
  end
  end

  def activate_carton_grading_rule_header
    deactive_active_rule
    activate_rule_header
    view_carton_grading_rule_headers
  end

  def activate_rule_header
    activated_by=session[:user_id]['user_name']

    ActiveRecord::Base.connection.execute("
    update carton_grading_rule_headers set activated_by='#{session[:user_id]['user_name']}',activated = true,deactivated =false,
    activated_at = '#{Time.now}',deactivated_by= null ,deactivated_at = null where id = #{params[:id]};

    update carton_grading_rules set activated_by = '#{session[:user_id]['user_name']}',activated = true,deactivated =false,
    activated_at = '#{Time.now}',deactivated_by= null ,deactivated_at = null
    where carton_grading_rule_header_id = #{params[:id]};
    ")

    activated_by
  end


  def deactive_active_rule
    deactivated_by=session[:user_id]['user_name']
    ActiveRecord::Base.connection.execute("
    update carton_grading_rule_headers set deactivated_by='#{session[:user_id]['user_name']}',activated = false,
    deactivated =true,deactivated_at = '#{Time.now}',activated_at =null,activated_by =null
    where activated = true;

    update carton_grading_rules set deactivated_by = '#{session[:user_id]['user_name']}',activated_by =null,
    activated = false,deactivated =true,deactivated_at = '#{Time.now}',activated_at = null
    where activated = true;")

  end

  def is_header_active?
    status = ActiveRecord::Base.connection.select_all("select cgrh.activated from carton_grading_rule_headers cgrh
             join carton_grading_rules cgr on cgr.carton_grading_rule_header_id = cgrh.id
             where cgr.id = #{params[:id]}")[0]['activated']
    return status
  end

  def activate_carton_grading_rule(carton_grading_rule_header_id = nil)
    active  = is_header_active?
    if active
      condition = "carton_grading_rule_header_id = #{carton_grading_rule_header_id}" if carton_grading_rule_header_id
      condition = "id = #{params[:id]}" if !carton_grading_rule_header_id

      ActiveRecord::Base.connection.execute("
    update carton_grading_rules set activated_by = '#{session[:user_id]['user_name']}',activated = true,deactivated =false,
    deactivated_at = null ,activated_at = '#{Time.now}',deactivated_by=null where #{condition}")
      session[:alert]  = "activated"
      params[:id] = session[:active_doc]['rule_header']
      get_grading_rules("where cgrh.id = #{session[:active_doc]['rule_header']}")
      render_grading_rules_grid
    else
      flash[:error] = "Cannot be activated , header is not active"
      get_grading_rules("where cgrh.id = #{session[:active_doc]['rule_header']}")
      render_grading_rules_grid
    end

  end

  def deactivate_carton_grading_rule(carton_grading_rule_header_id = nil)
    condition = "carton_grading_rule_header_id = #{carton_grading_rule_header_id}" if carton_grading_rule_header_id
    condition = "id = #{params[:id]}" if !carton_grading_rule_header_id
    active = ActiveRecord::Base.connection.select_all("
           select activated from  carton_grading_rules where #{condition}")[0]['activated']
    if active==true || active=="t"
      ActiveRecord::Base.connection.execute("
    update carton_grading_rules set deactivated_by = '#{session[:user_id]['user_name']}',activated_by =null
    ,activated = false,deactivated =true,deactivated_at = '#{Time.now}',activated_at = null
    where  #{condition};")
      session[:alert]  = "deactivated"
      params[:id] = session[:active_doc]['rule_header']
      list_grading_rules
    else
      flash[:error] = "Cannot be deactivated ,not active"
      get_grading_rules("where cgrh.id = #{session[:active_doc]['rule_header']}")
      render_grading_rules_grid
    end

  end

  def bypass_generic_security?
    true
  end

  def list_grading_rules
    set_active_doc("rule_header" ,params[:id])
    get_grading_rules("where cgrh.id = #{params[:id]}")
    render_grading_rules_grid
  end

  def grading_rule_sql(condition=nil)
    grading_rule_sql = "select cgrh.file_name,s.season_code as season,cgr.size,cgr.grade,cgr.variety,cgr.track_slms_indicator_code,
     cgr.line_type,cgr.updated_by,cgr.updated_at,cgr.deactivated_at,cgr.activated,cgr.product_class_code,
     cgr.id,cgr.new_class,cgr.new_size,cgr.deactivated ,cgrh.activated as is_active_header,cgr.created_at,cgr.created_by
     ,cgr.deactivated_by ,cgr.activated_by,cgr.activated_at
     from carton_grading_rule_headers cgrh
     join carton_grading_rules cgr on cgr.carton_grading_rule_header_id = cgrh.id
     join seasons s on cgrh.season_id = s.id #{condition}"
  end

  def get_grading_rules(condition=nil)
    @grading_rules = ActiveRecord::Base.connection.select_all(grading_rule_sql(condition))
  end

  def get_grading_rule_headers(condition=nil)
    @grading_rule_headers = ActiveRecord::Base.connection.select_all("
     select s.season_code as season,cgrh.file_name,cgrh.updated_by,cgrh.updated_at,
     cgrh.deactivated_at,cgrh.activated_at,cgrh.activated,cgrh.created_by,cgrh.created_at,cgrh.id
     ,cgrh.activated_by,cgrh.deactivated_by
     from carton_grading_rule_headers cgrh
     join seasons s on cgrh.season_id = s.id
     #{condition}
     order by cgrh.id desc")
  end

  def view_new_carton_grading_rules(carton_grading_rule_header_id)
    get_grading_rules("where cgrh.id = #{carton_grading_rule_header_id}")
    render_grading_rules_grid
  end

  def view_carton_grading_rule_headers
    get_grading_rule_headers#("where cgrh.id = 24")
    render_grading_rule_headers_grid
  end

  def render_grading_rule_headers_grid
    render :inline => %{
      <% grid            = build_grading_rule_headers_grid(@grading_rule_headers) %>
      <% grid.caption    = 'Grading Rule Headers' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def render_grading_rules_grid
    render :inline => %{
      <% grid            = build_grading_rules_grid(@grading_rules) %>
      <% grid.caption    = 'Grading Rules' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def view_carton_grading_rules
    get_grading_rules
    render_grading_rules_grid
  end

  def upload_grading_rule_file
    @seasons = ActiveRecord::Base.connection.select_all("select distinct season_code,id from seasons order by season_code desc"
               ).map{|x|[x['season_code'],x['id']]}.unshift("")
    @content_header_caption = "Select File"
    @submit="/rmt_processing/grading_rule/submit_grading_file"
    render :template => '/rmt_processing/grower_grading/upload_grading_rule_file.rhtml', :layout => 'content'
  end

  def upload_pallet_sequence_production_run_file
    @submit="/logistics/reworks/submit_pallet_sequence_production_run_file"
    @correction_context = "production_run_ids"
    @content_header_caption = "Select File"
    render :template => '/logistics/reworks/upload_csv_sheet.rhtml', :layout => 'content'
    @content_header_caption = "Select File"
  end

  def submit_grading_file
    if params && params[:csv_file].blank?
      flash[:error] = "Choose a file"
      upload_grading_rule_file
      return
    end
    begin
      x = ProcessGradingRuleFile.new(params[:csv_file],session[:user_id]['user_name'],"cartons",params[:season_id]).call
      if x.is_a?String
        flash[:error] = x
        #render :template => '/rmt_processing/grower_grading/upload_grading_rule_file.rhtml', :layout => 'content'
        upload_grading_rule_file
      elsif x.is_a?Integer
        # redirect_to_index("upload successful")
        flash[:notice] = "upload successful"
        view_carton_grading_rule_headers
      end
    rescue
      raise $!
    end
  end






end