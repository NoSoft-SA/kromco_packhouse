class Fg::PackingInstructionsFgLineItemController < ApplicationController

  def program_name?
    "order"
  end

  def bypass_generic_security?
    true
  end

  def get_old_fgs_list(old_fgs)
    old_fgs_list = ActiveRecord::Base.connection.select_all("
                  select id,old_fg_code from extended_fgs where old_fg_code in (#{old_fgs.join(',')})")
  end

  def get_grades_list(grades)
    grades_list = ActiveRecord::Base.connection.select_all("
                  select id,grade_code from grades where grade_code in (#{grades.join(',')})")
  end

  def get_tms_list(tms)
    tms_list = ActiveRecord::Base.connection.select_all("
                  select id,target_market_name
                  from target_markets where target_market_name in (#{tms.join(',')})")
  end

  def submit_fgs
     recs = params[:fg_line_item]['fgs'].split(/\n/)
     grades, grades_list, insert_values, old_fgs, old_fgs_list, tms, tms_list = get_fg_line_item_lists
     assign_fg_line_item_values(grades, old_fgs, recs, tms)
     if grades.empty? && old_fgs.empty? && tms.empty?
       flash[:error]= "List not formatted correctly; old_fgs,grades and tms not found"
       redirect_to :controller => 'fg/packing_instructions_fg_line_item', :action => 'create_multi_fg_line_items', :id => session[:active_doc]['pi']
       return
     elsif old_fgs.empty?
       flash[:error]= "old_fg_code is require"
       redirect_to :controller => 'fg/packing_instructions_fg_line_item', :action => 'create_multi_fg_line_items', :id => session[:active_doc]['pi']
       return
     end
     grades_list, old_fgs_list, tms_list = populate_fg_line_item_lists(grades, old_fgs, tms)

     structure_insert_fg_line_item_values_script(grades_list, insert_values, old_fgs_list, recs, tms_list)

     ActiveRecord::Base.connection.execute("
       insert into packing_instructions_fg_line_items(old_fg_id,grade_id,target_market_id,packing_instruction_id)
       VALUES #{insert_values.join(',')}") if !insert_values.empty?

     reload_packing_instruction_form
 end

  def assign_fg_line_item_values(grades, old_fgs, recs, tms)
    recs.each do |rec|
      old_fg = rec.split(",")[0].strip if rec.split(",")[0]
      grade = rec.split(",")[1].strip if rec.split(",")[1]
      tm = rec.split(",")[2].strip if rec.split(",")[2]

      old_fgs << "'#{old_fg}'" if old_fg
      grades << "'#{grade}'" if grade
      tms << "'#{tm}'" if tm

    end
  end

  def reload_packing_instruction_form
    render :inline => %{<script>
      alert('fg line items created');
      window.opener.frames[1].location.href = '/fg/packing_instruction/edit_packing_instruction/<%=#{session[:active_doc]['pi']}%>';
      window.close();
      </script>}, :layout => "content"
  end

  def create_multi_fg_line_items
    set_active_doc("pi",params[:id])
    render_import_fgs_form
  end

  def render_import_fgs_form
    render :inline => %{
  		<% @content_header_caption = "'Enter fg_old_code,grade_code,target_market'"%>

  		<%= build_import_fgs_form(@fg_line_item,'submit_fgs','submit',false,@is_create_retry)%>

  		}, :layout => 'content'
  end

  def unlink_packing_instructions_fg_line_item

  end

  def submit_selected_fg_line_items
    selected_fg_line_items = selected_records?(session[:fg_line_items], nil, true)
    unselected_fg_line_items = []
    session[:fg_line_items].each do |li|
      unselected_fg_line_items << li['id'] if li['packing_instruction_bin_line_item_id'] && !selected_fg_line_items.map{|x|x['id']}.include?(li['id'])
    end

    selected_now = selected_fg_line_items.map{|x|x['id']} - session[:selected_fg_line_item_ids]

    ActiveRecord::Base.connection.execute("update packing_instructions_fg_line_items
                                           set packing_instruction_bin_line_item_id = #{session[:active_doc]['fg_line_item_id']}
                                           where packing_instructions_fg_line_items.id in (#{selected_now.join(',')})") if !selected_now.empty?

    ActiveRecord::Base.connection.execute("update packing_instructions_fg_line_items
                                           set packing_instruction_bin_line_item_id = null
                                           where packing_instructions_fg_line_items.id in (#{unselected_fg_line_items.join(',')})") if !unselected_fg_line_items.empty?



    render :inline =>
               %{
            "<script>
                 alert("fg_line_items linked");
                 window.close();
                 window.opener.frames[0].location.reload(true);
             </script>"
     }, :layout => "content"
  end

  def render_related_fg_line_items
    list_query = bin_fg_line_item_list_query()
    @multi_select = "submit_selected_fg_line_items"
    @packing_instructions_fg_line_items = ActiveRecord::Base.connection.select_all(list_query)
    @grid_selected_rows = []
    session[:selected_fg_line_item_ids] = []
    @packing_instructions_fg_line_items.map do |x|
      @grid_selected_rows << x if x['packing_instruction_bin_line_item_id']
      session[:selected_fg_line_item_ids] << x['id'] if x['packing_instruction_bin_line_item_id']
    end
    session[:query] = "ActiveRecord::Base.connection.select_all(\"#{list_query}\")"
    session[:fg_line_items] = @packing_instructions_fg_line_items
    render_list_packing_instructions_fg_line_items
  end

  def bin_fg_line_item_list_query()
    list_query = " select pifgi.*,g.grade_code,exf.old_fg_code,o.short_description as marketing_org_code,
                 tm.target_market_name || ':' || tm.target_market_description as target_market_code,
                 inv.inventory_code || ':' || inv.inventory_name as inventory_code
                 from packing_instructions_fg_line_items pifgi
                 left join grades g on pifgi.grade_id = g.id
                 left join extended_fgs exf on pifgi.old_fg_id = exf.id
                 left join organizations o on pifgi.marketing_org_id = o.id
                 left join target_markets tm on pifgi.target_market_id = tm.id
                 left join inventory_codes inv on pifgi.inventory_id = inv.id
                 left join packing_instructions pi on pi.id=pifgi.packing_instruction_id
                 where pi.id = #{session[:active_doc]['pi']} and
                 (pifgi.packing_instruction_bin_line_item_id is null OR
                  pifgi.packing_instruction_bin_line_item_id = #{session[:active_doc]['fg_line_item_id']}) "
  end

  def refresh_old_fg_id
    actual_count = get_selected_combo_value(params)

    if actual_count == nil
      @old_fgs = ["select actual_count "]
    else
      session[:actual_count] = actual_count
      @old_fgs = ActiveRecord::Base.connection.select_all(
          "
      select DISTINCT old_fg_code,id FROM mv_extended_fgs
      where commodity_code='#{session[:commodity_code]}' and marketing_variety_code='#{session[:marketing_variety_code]}'
      and brand_code ='#{session[:brand_code]}'
      and old_pack_code='#{session[:old_pack_code]}'
      and actual_count='#{actual_count}'").map { |g| [g['old_fg_code'], g['id'].to_i] }.uniq

      @old_fgs.unshift(["<empty>"])
    end
    render :inline => %{
      <%x_content     = select('packing_instructions_fg_line_item','old_fg_id',@old_fgs) %>
   <script>
          <%= update_element_function("old_fg_id_cell", :action => :update,:content => x_content) %>
    </script>
   }
  end

  def store_old_pack_code
    old_pack_code = get_selected_combo_value(params)

    if old_pack_code == nil
      @actual_counts = ["select old pack"]
    else
      session[:old_pack_code] = old_pack_code
      @actual_counts = session[:mv_extended_fgs].map { |x| x['actual_count'] }.delete_if { |e| e == nil || e == '' }.uniq
      @actual_counts.unshift(["<empty>"])
    end
    render :inline => %{
      <%x_content     = select('packing_instructions_fg_line_item','actual_count',@actual_counts) %>
   <script>
          <%= update_element_function("actual_count_cell", :action => :update,:content => x_content) %>
    </script>
    <%= refresh_combo_observer_no_img('packing_instructions_fg_line_item_actual_count', 'old_fg_id_cell', 'refresh_old_fg_id') %>
   }
  end

  def store_brand_code
    brand_code = get_selected_combo_value(params)

    if brand_code == nil
      @old_pack_codes = ["select brand code "]
    else
      session[:brand_code] = brand_code
      @old_pack_codes = session[:mv_extended_fgs].map { |x| x['old_pack_code'] }.delete_if { |e| e == nil || e == '' }.uniq
      @old_pack_codes.unshift(["<empty>"])
    end
    render :inline => %{
      <%x_content     = select('packing_instructions_fg_line_item','old_pack_code',@old_pack_codes) %>
   <script>
          <%= update_element_function("old_pack_code_cell", :action => :update,:content => x_content) %>
    </script>
    <%= refresh_combo_observer_no_img('packing_instructions_fg_line_item_old_pack_code', 'actual_count_cell', 'store_old_pack_code') %>
   }
  end

  def store_marketing_variety_code
    marketing_variety_code = get_selected_combo_value(params)

    if marketing_variety_code == nil
      @brand_codes = ["select marketing_variety_code "]
    else
      session[:marketing_variety_code] = marketing_variety_code
      @brand_codes = session[:mv_extended_fgs].map { |x| x['brand_code'] }.delete_if { |e| e == nil || e == '' }.uniq
      @brand_codes.unshift(["<empty>"])
    end
    render :inline => %{
      <%x_content     = select('packing_instructions_fg_line_item','brand_code',@brand_codes) %>
   <script>
          <%= update_element_function("brand_code_cell", :action => :update,:content => x_content) %>
    </script>
    <%= refresh_combo_observer_no_img('packing_instructions_fg_line_item_brand_code', 'old_pack_code_cell', 'store_brand_code') %>
   }
  end

  def store_commodity
    commodity_code = get_selected_combo_value(params)

    if commodity_code == nil
      @marketing_variety_codes = ["select commodity code "]
    else
      session[:commodity_code] = commodity_code
      @marketing_variety_codes = session[:mv_extended_fgs].map { |x| x['marketing_variety_code'] }.delete_if { |e| e == nil || e == '' }.uniq
      @marketing_variety_codes.unshift(["<empty>"])
    end
    render :inline => %{
      <%m_content     = select('packing_instructions_fg_line_item','marketing_variety_code',@marketing_variety_codes) %>
      <script>
          <%= update_element_function("marketing_variety_code_cell", :action => :update,:content => m_content) %>
      </script>
          <%= refresh_combo_observer_no_img('packing_instructions_fg_line_item_marketing_variety_code', 'brand_code_cell', 'store_marketing_variety_code') %>
    }
  end

  def remove_selected_fg_setups
    selected_fg_setups = selected_records?(session[:fg_setups], nil, true)
    remove_fg_line_item_fg_setups(selected_fg_setups)
    fg_setup_for_packing_instructions_lines
    @add = true
    session[:alert] = "fg setup removed"
    render_fg_setup_grid
  end

  def remove_fg_line_item_fg_setups(selected_fg_setups)
    values = []
    selected_fg_setups.each do |fg_line|
      values << "(fg_setup_id = #{fg_line['id']} and packing_instructions_fg_line_item_id=#{session[:active_doc]['fg_line_item']})"
    end
    ActiveRecord::Base.connection.execute("delete from fg_setup_for_packing_instructions_lines where #{values.join(' OR ')}")
  end

  def submit_selected_fg_setups
    selected_fg_setups = selected_records?(session[:fg_setups], nil, true)
    create_fg_line_item_fg_setups(selected_fg_setups)
    session[:fg_setups]
    render :inline => %{<script>
                             //window.location.href= "/rmt_processing/bin_load/edit_order_load/<%=@bin_load_id.to_s%>";
                              window.close();
                              window.opener.location.reload(true);
                            </script>}
  end

  def create_fg_line_item_fg_setups(selected_fg_setups)
    values = []
    selected_fg_setups.each do |fg_line|
      values << "(#{fg_line['id']},#{session[:active_doc]['fg_line_item']})"
    end
    ActiveRecord::Base.connection.execute("insert into
  fg_setup_for_packing_instructions_lines(fg_setup_id,packing_instructions_fg_line_item_id)
  VALUES #{values.join(',')}")
  end

  def list_fg_setup_for_packing_instructions_lines
    set_active_doc("fg_line_item", params[:id])
    fg_setup_for_packing_instructions_lines
    @add = true
    render_fg_setup_grid
  end

  def fg_setup_for_packing_instructions_lines
    @fg_setups = ActiveRecord::Base.connection.select_all("
               select distinct fgs.*
               from fg_setups fgs
               join fg_setup_for_packing_instructions_lines fgs_pil on fgs_pil.fg_setup_id = fgs.id and
                fgs_pil.packing_instructions_fg_line_item_id  = #{session[:active_doc]['fg_line_item']}
                                                          ")
    session[:fg_setups] = @fg_setups
  end

  def select_fg_setups
    fg_line_item = get_fg_line_item
    fg_setups_where_clause = get_fg_setup_where_clause(fg_line_item)
    get_fg_setups(fg_setups_where_clause)
    @add = true
    render_list_fg_setup_grid
  end

  def render_list_fg_setup_grid
    render :inline => %{
    <% grid = build_list_fg_setup_grid(@fg_setups,@can_edit,@can_delete,@add)%>
    <% grid.caption = 'fg setups'%>
    <% @header_content = grid.build_grid_data %>
    <%= grid.render_html %>
    <%= grid.render_grid %>
  }, :layout => 'content'
  end


  def render_fg_setup_grid
    render :inline => %{
    <% grid = build_fg_setup_grid(@fg_setups,@can_edit,@can_delete,@add)%>
    <% grid.caption = 'fg setups'%>
    <% @header_content = grid.build_grid_data %>
    <%= grid.render_html %>
    <%= grid.render_grid %>
  }, :layout => 'content'
  end

  def get_fg_setups(fg_setups_where_clause)
    @fg_setups = ActiveRecord::Base.connection.select_all("
               select distinct * from fg_setups where (#{fg_setups_where_clause})
               and id not in (
                select fg_setup_id from fg_setup_for_packing_instructions_lines where
                packing_instructions_fg_line_item_id  = #{session[:active_doc]['fg_line_item']}
               )
                                       ")
    session[:fg_setups] = @fg_setups
  end

  def get_fg_setup_where_clause(fg_line_item)
    where = "retailer_sell_by_code #{fg_line_item['retailer_sell_by_code']} and
            inventory_code        #{fg_line_item['inventory_code']} and
            target_market         #{fg_line_item['target_market_name']} and
            marketing_org         #{fg_line_item['marketing_org']} and
            fg_code_old           #{fg_line_item['old_fg_code']} "
  end

  def get_fg_line_item
    fg_line_item = PackingInstructionsFgLineItem.find_by_sql("
                 select pifgi.*,exf.old_fg_code,o.short_description as marketing_org,
                 tm.target_market_name,inv.inventory_code as inventory_code
                 from packing_instructions_fg_line_items pifgi
                 left join extended_fgs exf on pifgi.old_fg_id = exf.id
                 left join organizations o on pifgi.marketing_org_id = o.id
                 left join target_markets tm on pifgi.target_market_id = tm.id
                 left join inventory_codes inv on pifgi.inventory_id = inv.id
                 where pifgi.id = #{session[:active_doc]['fg_line_item']}")[0]
    col_values = {}

    col_values['old_fg_code'] = "like '%'"
    if !fg_line_item['old_fg_code'] || fg_line_item['old_fg_code'] == ''
    else
      col_values['old_fg_code'] = "= '#{fg_line_item['old_fg_code']}'"
    end

    col_values['marketing_org'] = "like '%'"
    if !fg_line_item['marketing_org'] || fg_line_item['marketing_org'] == ''
    else
      col_values['marketing_org'] = "= '#{fg_line_item['marketing_org']}'"
    end

    col_values['target_market_name'] = "like '%'"
    if !fg_line_item['target_market_name'] || fg_line_item['target_market_name'] == ''
    else
      col_values['target_market_name'] = "= '#{fg_line_item['target_market_name']}'"
    end

    col_values['inventory_code'] = "like '%'"
    if !fg_line_item['inventory_code'] || fg_line_item['inventory_code'] == ''
    else
      col_values['inventory_code'] = "= '#{fg_line_item['inventory_code']}'"
    end

    col_values['retailer_sell_by_code'] = "like '%'"
    if !fg_line_item['retailer_sell_by_code'] || fg_line_item['retailer_sell_by_code'] == ''
    else
      col_values['retailer_sell_by_code'] = "= '#{fg_line_item['retailer_sell_by_code']}'"
    end

    return col_values

  end

  def list_packing_instructions_fg_line_items(condition = nil)
    return if authorise_for_web(program_name?, 'read') == false
    store_last_grid_url

    if params[:page] != nil

      session[:packing_instructions_fg_line_items_page] = params['page']

      render_list_packing_instructions_fg_line_items

      return
    else
      session[:packing_instructions_fg_line_items_page] = nil
    end

    list_query = fg_line_item_list_query("pi.id = #{session[:active_doc]['pi']}")
    @multi_select = nil
    @packing_instructions_fg_line_items = ActiveRecord::Base.connection.select_all(list_query)
    session[:query] = "ActiveRecord::Base.connection.select_all(\"#{list_query}\")"
    render_list_packing_instructions_fg_line_items
  end


  def render_list_packing_instructions_fg_line_items
    @pagination_server = "list_packing_instructions_fg_line_items"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:packing_instructions_fg_line_items_page]
    @current_page = params['page'] ||= session[:packing_instructions_fg_line_items_page]
    @packing_instructions_fg_line_items = eval(session[:query]) if !@packing_instructions_fg_line_items
    render :inline => %{
    <% grid = build_packing_instructions_fg_line_item_grid(@packing_instructions_fg_line_items,@can_edit,@can_delete,@multi_select)%>
    <% grid.caption = 'List of all packing_instructions_fg_line_items'%>
    <% @header_content = grid.build_grid_data %>

    <% @pagination = pagination_links(@packing_instructions_fg_line_item_pages) if @packing_instructions_fg_line_item_pages != nil %>
    <%= grid.render_html %>
    <%= grid.render_grid %>
  }, :layout => 'content'
  end

  def search_packing_instructions_fg_line_items_flat
    return if authorise_for_web(program_name?, 'read') == false
    @is_flat_search = true
    render_packing_instructions_fg_line_item_search_form
  end

  def render_packing_instructions_fg_line_item_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#   render (inline) the search form
    render :inline => %{
    <% @content_header_caption = "'search  packing_instructions_fg_line_items'"%> 

    <%= build_packing_instructions_fg_line_item_search_form(nil,'submit_packing_instructions_fg_line_items_search','submit_packing_instructions_fg_line_items_search',@is_flat_search)%>

    }, :layout => 'content'
  end

  def delete_packing_instructions_fg_line_item
    return if authorise_for_web(program_name?, 'delete') == false
    if params[:page]
      session[:packing_instructions_fg_line_items_page] = params['page']
      render_list_packing_instructions_fg_line_items
      return
    end
    id = params[:id]
    if id && packing_instructions_fg_line_item = PackingInstructionsFgLineItem.find(id)
      fg_setups = ActiveRecord::Base.connection.select_one("
                  select count(id) as setups from fg_setup_for_packing_instructions_lines where
                  packing_instructions_fg_line_item_id  = #{id}")['setups']
      if fg_setups.to_i > 0
        session[:alert] = ' Record cannot be deleted.Delete fg_setups first'
        render_list_packing_instructions_fg_line_items
      else
        packing_instructions_fg_line_item.destroy
        session[:alert] = ' Record deleted.'
        render_list_packing_instructions_fg_line_items
      end
    end
  rescue
    handle_error('record could not be deleted')
  end

  def new_packing_instructions_fg_line_item
    return if authorise_for_web(program_name?, 'create') == false
    # store_list_as_grid_url # UNCOMMENT if this action is called directly (i.e. from a menu, not from a grid)
    render_new_packing_instructions_fg_line_item
  end

  def create_packing_instructions_fg_line_item
    @packing_instructions_fg_line_item = PackingInstructionsFgLineItem.new(
        :old_fg_id => params[:packing_instructions_fg_line_item]['old_fg_id'],
        :marketing_org_id => params[:packing_instructions_fg_line_item]['marketing_org_id'],
        :grade_id => params[:packing_instructions_fg_line_item]['grade_id'],
        :target_market_id => params[:packing_instructions_fg_line_item]['target_market_id'],
        :inventory_id => params[:packing_instructions_fg_line_item]['inventory_id'],
        :packing_instruction_id => params[:packing_instructions_fg_line_item]['packing_instruction_id'],
        :pallet_qty => params[:packing_instructions_fg_line_item]['pallet_qty'],
        :retailer_sell_by_code => params[:packing_instructions_fg_line_item]['retailer_sell_by_code'],
        :packing_instruction_id => session[:active_doc]['pi'],
        :commodity_code => params[:packing_instructions_fg_line_item]['commodity_code'],
        :marketing_variety_code => params[:packing_instructions_fg_line_item]['marketing_variety_code'],
        :brand_code => params[:packing_instructions_fg_line_item]['brand_code'],
        :old_pack_code => params[:packing_instructions_fg_line_item]['old_pack_code'],
        :actual_count => params[:packing_instructions_fg_line_item]['actual_count']
    )
    if @packing_instructions_fg_line_item.save
      render :inline =>
                 %{
            "<script>
                 alert("new record created");
                 window.close();
                 window.opener.frames[1].location.reload(true);
             </script>"
     }, :layout => "content"
    else
      @is_create_retry = true
      render_new_packing_instructions_fg_line_item
    end
  rescue
    handle_error('record could not be created')
  end

  def render_new_packing_instructions_fg_line_item
#   render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'create new packing_instructions_fg_line_item'"%> 

    <%= build_packing_instructions_fg_line_item_form(@packing_instructions_fg_line_item,'create_packing_instructions_fg_line_item','create_packing_instructions_fg_line_item',false,@is_create_retry)%>

    }, :layout => 'content'
  end

  def edit_packing_instructions_fg_line_item
    return if authorise_for_web(program_name?, 'edit') == false
    id = params[:id]
    if id && @packing_instructions_fg_line_item = PackingInstructionsFgLineItem.find(id)
      render_edit_packing_instructions_fg_line_item
    end
  end


  def render_edit_packing_instructions_fg_line_item
#   render (inline) the edit template
    render :inline => %{
    <% @content_header_caption = "'edit packing_instructions_fg_line_item'"%> 

    <%= build_packing_instructions_fg_line_item_form(@packing_instructions_fg_line_item,'update_packing_instructions_fg_line_item','update_packing_instructions_fg_line_item',true)%>

    }, :layout => 'content'
  end

  def update_packing_instructions_fg_line_item
    id = params[:packing_instructions_fg_line_item][:id]
    if id && @packing_instructions_fg_line_item = PackingInstructionsFgLineItem.find(id)
      if @packing_instructions_fg_line_item.update_attributes(
          :old_fg_id => params[:packing_instructions_fg_line_item]['old_fg_id'],
          :marketing_org_id => params[:packing_instructions_fg_line_item]['marketing_org_id'],
          :grade_id => params[:packing_instructions_fg_line_item]['grade_id'],
          :target_market_id => params[:packing_instructions_fg_line_item]['target_market_id'],
          :inventory_id => params[:packing_instructions_fg_line_item]['inventory_id'],
          :pallet_qty => params[:packing_instructions_fg_line_item]['pallet_qty'],
          :retailer_sell_by_code => params[:packing_instructions_fg_line_item]['retailer_sell_by_code'],
          :commodity_code => params[:packing_instructions_fg_line_item]['commodity_code'],
          :marketing_variety_code => params[:packing_instructions_fg_line_item]['marketing_variety_code'],
          :brand_code => params[:packing_instructions_fg_line_item]['brand_code'],
          :old_pack_code => params[:packing_instructions_fg_line_item]['old_pack_code'],
          :actual_count => params[:packing_instructions_fg_line_item]['actual_count']
      )
        render :inline =>
                   %{
                    "<script>
                       alert(" record updated");
                       window.close();
                       window.parent.opener.frames[1].location.href = '/fg/packing_instructions_fg_line_item/list_packing_instructions_fg_line_items';
                    </script>"
     }, :layout => "content"
      else
        render_edit_packing_instructions_fg_line_item
      end
    end
  rescue
    handle_error('record could not be saved')
  end

  def search_dm_packing_instructions_fg_line_items
    return if authorise_for_web(program_name?, 'read') == false
    dm_session['se_layout'] = 'content'
    @content_header_caption = "'Search Packing instructions fg line items'"
    dm_session[:redirect] = true
    build_remote_search_engine_form('search_packing_instructions_fg_line_items.yml', 'search_dm_packing_instructions_fg_line_items_grid')
  end


  def search_dm_packing_instructions_fg_line_items_grid
    store_last_grid_url
    @packing_instructions_fg_line_items = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @stat = dm_session[:search_engine_query_definition]
    @columns_list = dm_session[:columns_list]
    @grid_configs = dm_session[:grid_configs]

    render :inline => %{
      <% grid            = build_packing_instructions_fg_line_item_dm_grid(@packing_instructions_fg_line_items, @stat, @columns_list, @can_edit, @can_delete, @grid_configs) %>
      <% grid.caption    = 'Packing instructions fg line items' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end


  def fg_line_item_list_query(condition = nil)
    list_query = " select pifgi.*,g.grade_code,exf.old_fg_code,o.short_description as marketing_org_code,
                 tm.target_market_name || ':' || tm.target_market_description as target_market_code,
                 inv.inventory_code || ':' || inv.inventory_name as inventory_code
                 from packing_instructions_fg_line_items pifgi
                 left join grades g on pifgi.grade_id = g.id
                 left join extended_fgs exf on pifgi.old_fg_id = exf.id
                 left join organizations o on pifgi.marketing_org_id = o.id
                 left join target_markets tm on pifgi.target_market_id = tm.id
                 left join inventory_codes inv on pifgi.inventory_id = inv.id
                 left join packing_instructions pi on pi.id=pifgi.packing_instruction_id
                  where #{condition}
                order by pifgi.id desc"
  end

  def structure_insert_fg_line_item_values_script(grades_list, insert_values, old_fgs_list, recs, tms_list)
    duplicate_control = []
    recs.each do |rec|
      old_fg = rec.split(",")[0].strip if rec.split(",")[0]
      grade = rec.split(",")[1].strip if rec.split(",")[1]
      tm = rec.split(",")[2].strip if rec.split(",")[2]

      old_fg_id = old_fgs_list.find_all { |x| x['old_fg_code'] == old_fg }[0] if (old_fg && old_fg.length > 0) && !old_fgs_list.empty?
      old_fg_id = old_fg_id['id'] if old_fg_id

      grade_id = grades_list.find_all { |x| x['grade_code'] == grade }[0] if (grade  && grade.length > 0)&& !grades_list.empty?
      grade_id = grade_id['id'] if grade_id

      tm_id = tms_list.find_all { |x| x['target_market_name'] == tm }[0] if (tm && tm.length > 0 ) && !tms_list.empty?
      tm_id =tm_id['id'] if tm_id



      old_fg_id = "null" if !old_fg_id
      grade_id = "null" if !grade_id
      tm_id = "null" if !tm_id

      insert_values << "(#{old_fg_id},#{grade_id},#{tm_id},#{session[:active_doc]['pi']})" if !duplicate_control.include?("#{old_fg_id}_#{grade}_#{tm_id}")
      duplicate_control << "#{old_fg_id}_#{grade}_#{tm_id}" if !duplicate_control.include?("#{old_fg_id}_#{grade}_#{tm_id}")
    end
  end

  def populate_fg_line_item_lists(grades, old_fgs, tms)
    old_fgs_list = get_old_fgs_list(old_fgs) if !old_fgs.empty?
    grades_list = get_grades_list(grades) if !grades.empty?
    tms_list = get_tms_list(tms) if !tms.empty?
    return grades_list, old_fgs_list, tms_list
  end

  def get_fg_line_item_lists
    old_fgs_list = []
    grades_list = []
    tms_list = []

    insert_values = []
    old_fgs = []
    grades = []
    tms = []
    return grades, grades_list, insert_values, old_fgs, old_fgs_list, tms, tms_list
  end


#  --------------------------------------------------------------------------------
#   combo_changed event handlers for composite foreign key: target_market_id
#  ---------------------------------------------------------------------------------
#  --------------------------------------------------------------------------------
#   combo_changed event handlers for composite foreign key: grade_id
#  ---------------------------------------------------------------------------------


end
