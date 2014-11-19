class RmtProcessing::PresortConversionController < ApplicationController

  #MM072014

  def program_name?
    "presort_conversions"
  end

  def bypass_generic_security?
    true
  end

  def  new_presort_conversions
    #return if authorise_for_web(program_name?,'read')== false
    render_new_presort_conversions
  end

  def render_new_presort_conversions
    render :inline => %{
    <% @content_header_caption = "'new presort conversions'"%>

    <%= build_new_presort_conversions_form(@presort_conversions,'save_presort_conversions','save_presort_conversions',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def save_presort_conversions
    if params[:presort_conversions]['commodity_code'] == "" or params[:presort_conversions]['grade_code'] == "" or params[:presort_conversions]['line_type'] == "" or params[:presort_conversions]['marketing_variety_code'] == "" or params[:presort_conversions]['treatment_code'] == "" or params[:presort_conversions]['rmt_variety_code'] == "" or params[:presort_conversions]['product_class_code'] == ""
      flash[:notice] = 'Record not saved missing some required fields'
      render_new_presort_conversions
    else
      begin
          @presort_conversions_result = CartonPresortConversion.new(params[:presort_conversions])
          if @presort_conversions_result.save
            @current_presort_conversion = true
            session[:alert] = "presort conversion record updated."
            edit_presort_conversions
          else
            @is_create_retry = true
            flash[:notice] = "There already exists a carton presort conversion record with the commodity_code, rmt_variety_code ,grade_code , line_type , marketing_variety_code ,treatment_code and product_class_code"
            render_new_presort_conversions
          end
        rescue
          handle_error('record could not be saved - duplicate carton_presort_conversions_key')
      end
    end
  end

  def edit_presort_conversions
    query = "select carton_presort_conversions.*,commodities.commodity_description_long,rmt_varieties.rmt_variety_description,marketing_varieties.marketing_variety_description,grades.grade_description,treatments.description,product_classes.product_class_description
            from carton_presort_conversions
            inner join commodities on carton_presort_conversions.commodity_code = commodities.commodity_code
            inner join rmt_varieties on carton_presort_conversions.rmt_variety_code = rmt_varieties.rmt_variety_code
            inner join marketing_varieties on carton_presort_conversions.marketing_variety_code = marketing_varieties.marketing_variety_code
            inner join grades on carton_presort_conversions.grade_code = grades.grade_code
            inner join treatments on carton_presort_conversions.treatment_code = treatments.treatment_code
            inner join product_classes on carton_presort_conversions.product_class_code = product_classes.product_class_code
            "
    conn = User.connection
    @presort_conversions = conn.select_all(query)
    render_list_presort_conversions
  end

  def commodity_code_search_combo_changed

    commodity_code = get_selected_combo_value(params)
    session[:commodity_code] = commodity_code

    # @commodity_codes = Commodity.find_by_sql("select * from commodities where commodity_code = '#{commodity_code}'").map{|g|["#{g.commodity_code} - #{g.commodity_description_long}", g.commodity_code]}
    # @commodity_codes.unshift(["<empty>", nil])
    # commodity_code_content = select('presort_conversions','commodity_code',@commodity_codes)
    # <%= update_element_function("commodity_code_cell", :action => :update,:content => commodity_code_content) %>

    @rmt_variety_code = RmtVariety.find_by_sql("select * from rmt_varieties where commodity_code = '#{commodity_code}'").map{|g|["#{g.rmt_variety_code} - #{g.rmt_variety_description}", g.rmt_variety_code]}
    @rmt_variety_code.unshift(["<empty>", nil]) if !@rmt_variety_code.empty?

    @marketing_variety_code = MarketingVariety.find_by_sql("select * from marketing_varieties where commodity_code = '#{commodity_code}'").map{|g|["#{g.marketing_variety_code} - #{g.marketing_variety_description}", g.marketing_variety_code]}
    @marketing_variety_code.unshift(["<empty>", nil]) if !@marketing_variety_code.empty?

    render :inline => %{
		<%=
        rmt_variety_code_content = select('presort_conversions','rmt_variety_code',@rmt_variety_code)
        marketing_variety_code_content = select('presort_conversions','marketing_variety_code',@marketing_variety_code)
    %>
    <script>
        <%= update_element_function("rmt_variety_code_cell", :action => :update,:content => rmt_variety_code_content) %>
        <%= update_element_function("marketing_variety_code_cell", :action => :update,:content => marketing_variety_code_content) %>

    </script>
		}

  end

  def render_list_presort_conversions
    @can_edit = authorise(program_name?,'edit',session[:user_id])
    @can_delete = authorise(program_name?,'delete',session[:user_id])
    render :inline => %{
      <% grid            = build_list_presort_conversions_grid(@presort_conversions,@can_edit,@can_delete) %>
      <% grid.caption    = 'presort conversions list' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def edit_current_presort_conversions
    session[:presort_conversions_id] = params[:id]
    if session[:presort_conversions_id] && @presort_conversions = CartonPresortConversion.find(session[:presort_conversions_id])
      @current_presort_conversion = true
      session[:commodity_code] = @presort_conversions.commodity_code
      render_edit_presort_conversions
    end
  end

  def render_edit_presort_conversions
    render :inline => %{
    <% @content_header_caption = "'edit presort conversions'"%>

    <%= build_new_presort_conversions_form(@presort_conversions,'update_presort_conversions','update_presort_conversions',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def update_presort_conversions
    presort_conversions_id = session[:presort_conversions_id]
    if presort_conversions_id && current_carton_presort_conversion = CartonPresortConversion.find(presort_conversions_id)
      begin
        current_carton_presort_conversion.update_attribute_sanitised(params[:presort_conversions])
        session[:alert] = "presort conversion record updated."
      rescue
        handle_error('record could not be updated - duplicate carton_presort_conversions_key')
      end
    end
    edit_presort_conversions
  end

  def delete_presort_conversions
    begin
      presort_conversions_id = params[:id]
      if presort_conversions_id && carton_presort_conversion = CartonPresortConversion.find(presort_conversions_id)
        carton_presort_conversion.destroy
        session[:alert] = "presort conversion record deleted."
      end
    rescue
      handle_error('record could not be deleted')
    end
    edit_presort_conversions
  end

  def search_for_presort_conversions
    render_search_presort_conversions
  end

  def render_search_presort_conversions
    render :inline => %{
    <% @content_header_caption = "'search presort conversions'"%>

    <%= build_new_presort_conversions_form(@presort_conversions,'search_presort_conversions','search_presort_conversions',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def search_presort_conversions
    query_conditions = []
    query_conditions << " and carton_presort_conversions.commodity_code = '#{params[:presort_conversions]['commodity_code']}'" if params[:presort_conversions]['commodity_code'] != ""
    query_conditions << " and carton_presort_conversions.line_type = '#{ params[:presort_conversions]['line_type']}'" if params[:presort_conversions]['line_type'] != ""
    query_conditions << " and carton_presort_conversions.marketing_variety_code = '#{params[:presort_conversions]['marketing_variety_code']}'" if params[:presort_conversions]['marketing_variety_code'] != ""
    query_conditions << " and carton_presort_conversions.treatment_code =  '#{params[:presort_conversions]['treatment_code']}'" if params[:presort_conversions]['treatment_code'] != ""
    query_conditions << " and carton_presort_conversions.rmt_variety_code = '#{params[:presort_conversions]['rmt_variety_code']}'" if params[:presort_conversions]['rmt_variety_code'] != ""
    query_conditions << " and carton_presort_conversions.product_class_code = '#{params[:presort_conversions]['product_class_code']}'" if params[:presort_conversions]['product_class_code'] != ""

    query = "select carton_presort_conversions.*,commodities.commodity_description_long,rmt_varieties.rmt_variety_description,marketing_varieties.marketing_variety_description,grades.grade_description,treatments.description,product_classes.product_class_description
              from carton_presort_conversions
              inner join commodities on carton_presort_conversions.commodity_code = commodities.commodity_code
              inner join rmt_varieties on carton_presort_conversions.rmt_variety_code = rmt_varieties.rmt_variety_code
              inner join marketing_varieties on carton_presort_conversions.marketing_variety_code = marketing_varieties.marketing_variety_code
              inner join grades on carton_presort_conversions.grade_code = grades.grade_code
              inner join treatments on carton_presort_conversions.treatment_code = treatments.treatment_code
              inner join product_classes on carton_presort_conversions.product_class_code = product_classes.product_class_code
              where carton_presort_conversions.id is not null
              #{query_conditions}
    "

    conn = User.connection
    @presort_conversions = conn.select_all(query)
    render_list_presort_conversions
  end

end