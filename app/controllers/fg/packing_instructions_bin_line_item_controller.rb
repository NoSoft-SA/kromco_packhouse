class  Fg::PackingInstructionsBinLineItemController < ApplicationController

def program_name?
  "order"
end

def bypass_generic_security?
  true
end

def refresh_track_slms_indicator
  commodity_id = get_selected_combo_value(params)

  if commodity_id == nil
    @track_slms_indicators = ["<empty>"]
  else
    @track_slms_indicators = TrackSlmsIndicator.find_by_sql("select distinct tslm.id,track_slms_indicator_code
                                  from track_slms_indicators tslm
                                  join commodities c on tslm.commodity_code = c.commodity_code
                                   where tslm.track_indicator_type_code='RMI' and c.id= #{commodity_id}").map{|g|[g.track_slms_indicator_code,g.id]}

    @track_slms_indicators.unshift(["<empty>"])
  end
  render :inline => %{
      <%track_slms_indicator_content     = select('packing_instructions_bin_line_item','track_slms_indicator_id',@track_slms_indicators) %>
   <script>
          <%= update_element_function("track_slms_indicator_id_cell", :action => :update,:content => track_slms_indicator_content) %>
    </script>
   }
end

def list_packing_instructions_bin_line_items
  return if authorise_for_web(program_name?,'read') == false 
  store_last_grid_url

   if params[:page]!= nil 

     session[:packing_instructions_bin_line_items_page] = params['page']

     render_list_packing_instructions_bin_line_items

     return 
  else
    session[:packing_instructions_bin_line_items_page] = nil
   end

  list_query = "select pibli.*,t.track_slms_indicator_code,v.rmt_variety_code as variety_code,s.size_code,
  p.product_class_code,treats.treatment_code,c.commodity_code
  from packing_instructions_bin_line_items pibli
  left join track_slms_indicators t on t.id=pibli.track_slms_indicator_id
  left join varieties v on v.id =pibli.variety_id
  left join sizes s on s.id=pibli.size_id
  left join product_classes p on p.id=pibli.product_class_id
  left join treatments treats on treats.id=pibli.treatment_id
  left join commodities c on c.id=pibli.commodity_id
  left join packing_instructions pi on pi.id=pibli.packing_instruction_id
  where pibli.packing_instruction_id = #{session[:active_doc]['pi']}"
  @packing_instructions_bin_line_items = ActiveRecord::Base.connection.select_all(list_query)
  session[:query] = "ActiveRecord::Base.connection.select_all(\"#{list_query}\")"
  render_list_packing_instructions_bin_line_items
end


def render_list_packing_instructions_bin_line_items
  @pagination_server = "list_packing_instructions_bin_line_items"
  @can_edit = authorise(program_name?,'edit',session[:user_id])
  @can_delete = authorise(program_name?,'delete',session[:user_id])
  @current_page = session[:packing_instructions_bin_line_items_page]
  @current_page = params['page']||= session[:packing_instructions_bin_line_items_page]
  # @packing_instructions_bin_line_items =  eval(session[:query]) if !@packing_instructions_bin_line_items
  render :inline => %{
    <% grid = build_packing_instructions_bin_line_item_grid(@packing_instructions_bin_line_items,@can_edit,@can_delete)%>
    <% grid.caption = 'List of all packing_instructions_bin_line_items'%>
    <% @header_content = grid.build_grid_data %>

    <% @pagination = pagination_links(@packing_instructions_bin_line_item_pages) if @packing_instructions_bin_line_item_pages != nil %>
    <%= grid.render_html %>
    <%= grid.render_grid %>
  },:layout => 'content'
end

def search_packing_instructions_bin_line_items_flat
  return if authorise_for_web(program_name?,'read')== false
  @is_flat_search = true 
  render_packing_instructions_bin_line_item_search_form
end

def render_packing_instructions_bin_line_item_search_form(is_flat_search = nil)
  session[:is_flat_search] = @is_flat_search
#   render (inline) the search form
  render :inline => %{
    <% @content_header_caption = "'search  packing_instructions_bin_line_items'"%> 

    <%= build_packing_instructions_bin_line_item_search_form(nil,'submit_packing_instructions_bin_line_items_search','submit_packing_instructions_bin_line_items_search',@is_flat_search)%>

    }, :layout => 'content'
end


def submit_packing_instructions_bin_line_items_search
  store_last_grid_url
  @packing_instructions_bin_line_items = dynamic_search(params[:packing_instructions_bin_line_item] ,'packing_instructions_bin_line_items','PackingInstructionsBinLineItem')
  if @packing_instructions_bin_line_items.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_packing_instructions_bin_line_item_search_form
    else
      render_list_packing_instructions_bin_line_items
  end
end


def delete_packing_instructions_bin_line_item
  return if authorise_for_web(program_name?,'delete')== false
  if params[:page]
    session[:packing_instructions_bin_line_items_page] = params['page']
    render_list_packing_instructions_bin_line_items
    return
  end
  id = params[:id]
  if id && packing_instructions_bin_line_item = PackingInstructionsBinLineItem.find(id)
    packing_instructions_bin_line_item.destroy
    session[:alert] = ' Record deleted.'
    # render_list_packing_instructions_bin_line_items
    redirect_to_last_grid
  end
  rescue
    handle_error('record could not be deleted')
end

def new_packing_instructions_bin_line_item
  return if authorise_for_web(program_name?,'create')== false
  # store_list_as_grid_url # UNCOMMENT if this action is called directly (i.e. from a menu, not from a grid)
  render_new_packing_instructions_bin_line_item
end

def create_packing_instructions_bin_line_item
   @packing_instructions_bin_line_item = PackingInstructionsBinLineItem.new(params[:packing_instructions_bin_line_item])
   @packing_instructions_bin_line_item.packing_instruction_id = session[:active_doc]['pi']
   if @packing_instructions_bin_line_item.save
     render :inline =>
                %{
            "<script>
                 alert("new record created");
                 window.close();
                 window.opener.frames[0].location.reload(true);
             </script>"
     },:layout => "content"

  else
    @is_create_retry = true
    render_new_packing_instructions_bin_line_item
   end
rescue
   handle_error('record could not be created')
end

def render_new_packing_instructions_bin_line_item
#   render (inline) the edit template
  render :inline => %{
    <% @content_header_caption = "'create new packing_instructions_bin_line_item'"%> 

    <%= build_packing_instructions_bin_line_item_form(@packing_instructions_bin_line_item,'create_packing_instructions_bin_line_item','create_packing_instructions_bin_line_item',false,@is_create_retry)%>

    }, :layout => 'content'
end

def edit_packing_instructions_bin_line_item
  return if authorise_for_web(program_name?,'edit')==false 
   id = params[:id]
   if id && @packing_instructions_bin_line_item = PackingInstructionsBinLineItem.find(id)
    render_edit_packing_instructions_bin_line_item
   end
end


def render_edit_packing_instructions_bin_line_item
#   render (inline) the edit template
  render :inline => %{
    <% @content_header_caption = "'edit packing_instructions_bin_line_item'"%> 

    <%= build_packing_instructions_bin_line_item_form(@packing_instructions_bin_line_item,'update_packing_instructions_bin_line_item','update_packing_instructions_bin_line_item',true)%>

    }, :layout => 'content'
end

def update_packing_instructions_bin_line_item
   id = params[:packing_instructions_bin_line_item][:id]
   if id && @packing_instructions_bin_line_item = PackingInstructionsBinLineItem.find(id)
     if @packing_instructions_bin_line_item.update_attributes(params[:packing_instructions_bin_line_item])
       pi = @packing_instructions_bin_line_item.packing_instruction_id
       render :inline => %{
                          <script>
                          window.close();
                         window.parent.opener.frames[0].location.href = '/fg/packing_instructions_bin_line_item/list_packing_instructions_bin_line_items';
                        </script>} and return
        else
       render_edit_packing_instructions_bin_line_item
     end
   end
rescue
   handle_error('record could not be saved')
 end

  def search_dm_packing_instructions_bin_line_items
    return if authorise_for_web(program_name?,'read')== false
    dm_session['se_layout']              = 'content'
    @content_header_caption              = "'Search Packing instructions bin line items'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form('search_packing_instructions_bin_line_items.yml', 'search_dm_packing_instructions_bin_line_items_grid')
  end


  def search_dm_packing_instructions_bin_line_items_grid
    store_last_grid_url
    @packing_instructions_bin_line_items = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    @can_edit        = authorise(program_name?, 'edit', session[:user_id])
    @can_delete      = authorise(program_name?, 'delete', session[:user_id])
    @stat            = dm_session[:search_engine_query_definition]
    @columns_list    = dm_session[:columns_list]
    @grid_configs    = dm_session[:grid_configs]

    render :inline => %{
      <% grid            = build_packing_instructions_bin_line_item_dm_grid(@packing_instructions_bin_line_items, @stat, @columns_list, @can_edit, @can_delete, @grid_configs) %>
      <% grid.caption    = 'Packing instructions bin line items' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end


#  --------------------------------------------------------------------------------
#   combo_changed event handlers for composite foreign key: treatment_id
#  ---------------------------------------------------------------------------------
def packing_instructions_bin_line_item_treatment_type_code_changed
  treatment_type_code = get_selected_combo_value(params)
  session[:packing_instructions_bin_line_item_form][:treatment_type_code_combo_selection] = treatment_type_code
  @treatment_codes = PackingInstructionsBinLineItem.treatment_codes_for_treatment_type_code(treatment_type_code)
#  render (inline) the html to replace the contents of the td that contains the dropdown 
  render :inline => %{
    <%= select('packing_instructions_bin_line_item','treatment_code',@treatment_codes)%>

    }

end


#  --------------------------------------------------------------------------------
#   combo_changed event handlers for composite foreign key: variety_id
#  ---------------------------------------------------------------------------------
def packing_instructions_bin_line_item_commodity_group_code_changed
  commodity_group_code = get_selected_combo_value(params)
  session[:packing_instructions_bin_line_item_form][:commodity_group_code_combo_selection] = commodity_group_code
  @commodity_codes = PackingInstructionsBinLineItem.commodity_codes_for_commodity_group_code(commodity_group_code)
#  render (inline) the html to replace the contents of the td that contains the dropdown 
  render :inline => %{
    <%= select('packing_instructions_bin_line_item','commodity_code',@commodity_codes)%>
    <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_packing_instructions_bin_line_item_commodity_code'/>
    <%= observe_field('packing_instructions_bin_line_item_commodity_code',:update => 'commodity_id_cell',:url => {:action => session[:packing_instructions_bin_line_item_form][:commodity_code_observer][:remote_method]},:loading => "show_element('img_packing_instructions_bin_line_item_commodity_code');",:complete => session[:packing_instructions_bin_line_item_form][:commodity_code_observer][:on_completed_js])%>
    }

end


def packing_instructions_bin_line_item_commodity_code_changed
  commodity_code = get_selected_combo_value(params)
  session[:packing_instructions_bin_line_item_form][:commodity_code_combo_selection] = commodity_code
  commodity_group_code =   session[:packing_instructions_bin_line_item_form][:commodity_group_code_combo_selection]
  @commodity_ids = PackingInstructionsBinLineItem.commodity_ids_for_commodity_code_and_commodity_group_code(commodity_code,commodity_group_code)
#  render (inline) the html to replace the contents of the td that contains the dropdown 
  render :inline => %{
    <%= select('packing_instructions_bin_line_item','commodity_id',@commodity_ids)%>
    <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_packing_instructions_bin_line_item_commodity_id'/>
    <%= observe_field('packing_instructions_bin_line_item_commodity_id',:update => 'rmt_variety_code_cell',:url => {:action => session[:packing_instructions_bin_line_item_form][:commodity_id_observer][:remote_method]},:loading => "show_element('img_packing_instructions_bin_line_item_commodity_id');",:complete => session[:packing_instructions_bin_line_item_form][:commodity_id_observer][:on_completed_js])%>
    }

end


def packing_instructions_bin_line_item_commodity_id_changed
  commodity_id = get_selected_combo_value(params)
  session[:packing_instructions_bin_line_item_form][:commodity_id_combo_selection] = commodity_id
  commodity_code =   session[:packing_instructions_bin_line_item_form][:commodity_code_combo_selection]
  commodity_group_code =   session[:packing_instructions_bin_line_item_form][:commodity_group_code_combo_selection]
  @rmt_variety_codes = PackingInstructionsBinLineItem.rmt_variety_codes_for_commodity_id_and_commodity_code_and_commodity_group_code(commodity_id,commodity_code,commodity_group_code)
#  render (inline) the html to replace the contents of the td that contains the dropdown 
  render :inline => %{
    <%= select('packing_instructions_bin_line_item','rmt_variety_code',@rmt_variety_codes)%>
    <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_packing_instructions_bin_line_item_rmt_variety_code'/>
    <%= observe_field('packing_instructions_bin_line_item_rmt_variety_code',:update => 'rmt_variety_id_cell',:url => {:action => session[:packing_instructions_bin_line_item_form][:rmt_variety_code_observer][:remote_method]},:loading => "show_element('img_packing_instructions_bin_line_item_rmt_variety_code');",:complete => session[:packing_instructions_bin_line_item_form][:rmt_variety_code_observer][:on_completed_js])%>
    }

end


def packing_instructions_bin_line_item_rmt_variety_code_changed
  rmt_variety_code = get_selected_combo_value(params)
  session[:packing_instructions_bin_line_item_form][:rmt_variety_code_combo_selection] = rmt_variety_code
  commodity_id =   session[:packing_instructions_bin_line_item_form][:commodity_id_combo_selection]
  commodity_code =   session[:packing_instructions_bin_line_item_form][:commodity_code_combo_selection]
  commodity_group_code =   session[:packing_instructions_bin_line_item_form][:commodity_group_code_combo_selection]
  @rmt_variety_ids = PackingInstructionsBinLineItem.rmt_variety_ids_for_rmt_variety_code_and_commodity_id_and_commodity_code_and_commodity_group_code(rmt_variety_code,commodity_id,commodity_code,commodity_group_code)
#  render (inline) the html to replace the contents of the td that contains the dropdown 
  render :inline => %{
    <%= select('packing_instructions_bin_line_item','rmt_variety_id',@rmt_variety_ids)%>
    <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_packing_instructions_bin_line_item_rmt_variety_id'/>
    <%= observe_field('packing_instructions_bin_line_item_rmt_variety_id',:update => 'marketing_variety_code_cell',:url => {:action => session[:packing_instructions_bin_line_item_form][:rmt_variety_id_observer][:remote_method]},:loading => "show_element('img_packing_instructions_bin_line_item_rmt_variety_id');",:complete => session[:packing_instructions_bin_line_item_form][:rmt_variety_id_observer][:on_completed_js])%>
    }

end


def packing_instructions_bin_line_item_rmt_variety_id_changed
  rmt_variety_id = get_selected_combo_value(params)
  session[:packing_instructions_bin_line_item_form][:rmt_variety_id_combo_selection] = rmt_variety_id
  rmt_variety_code =   session[:packing_instructions_bin_line_item_form][:rmt_variety_code_combo_selection]
  commodity_id =   session[:packing_instructions_bin_line_item_form][:commodity_id_combo_selection]
  commodity_code =   session[:packing_instructions_bin_line_item_form][:commodity_code_combo_selection]
  commodity_group_code =   session[:packing_instructions_bin_line_item_form][:commodity_group_code_combo_selection]
  @marketing_variety_codes = PackingInstructionsBinLineItem.marketing_variety_codes_for_rmt_variety_id_and_rmt_variety_code_and_commodity_id_and_commodity_code_and_commodity_group_code(rmt_variety_id,rmt_variety_code,commodity_id,commodity_code,commodity_group_code)
#  render (inline) the html to replace the contents of the td that contains the dropdown 
  render :inline => %{
    <%= select('packing_instructions_bin_line_item','marketing_variety_code',@marketing_variety_codes)%>
    <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_packing_instructions_bin_line_item_marketing_variety_code'/>
    <%= observe_field('packing_instructions_bin_line_item_marketing_variety_code',:update => 'marketing_variety_id_cell',:url => {:action => session[:packing_instructions_bin_line_item_form][:marketing_variety_code_observer][:remote_method]},:loading => "show_element('img_packing_instructions_bin_line_item_marketing_variety_code');",:complete => session[:packing_instructions_bin_line_item_form][:marketing_variety_code_observer][:on_completed_js])%>
    }

end


def packing_instructions_bin_line_item_marketing_variety_code_changed
  marketing_variety_code = get_selected_combo_value(params)
  session[:packing_instructions_bin_line_item_form][:marketing_variety_code_combo_selection] = marketing_variety_code
  rmt_variety_id =   session[:packing_instructions_bin_line_item_form][:rmt_variety_id_combo_selection]
  rmt_variety_code =   session[:packing_instructions_bin_line_item_form][:rmt_variety_code_combo_selection]
  commodity_id =   session[:packing_instructions_bin_line_item_form][:commodity_id_combo_selection]
  commodity_code =   session[:packing_instructions_bin_line_item_form][:commodity_code_combo_selection]
  commodity_group_code =   session[:packing_instructions_bin_line_item_form][:commodity_group_code_combo_selection]
  @marketing_variety_ids = PackingInstructionsBinLineItem.marketing_variety_ids_for_marketing_variety_code_and_rmt_variety_id_and_rmt_variety_code_and_commodity_id_and_commodity_code_and_commodity_group_code(marketing_variety_code,rmt_variety_id,rmt_variety_code,commodity_id,commodity_code,commodity_group_code)
#  render (inline) the html to replace the contents of the td that contains the dropdown 
  render :inline => %{
    <%= select('packing_instructions_bin_line_item','marketing_variety_id',@marketing_variety_ids)%>

    }

end


#  --------------------------------------------------------------------------------
#   combo_changed event handlers for composite foreign key: product_class_id
#  ---------------------------------------------------------------------------------
def packing_instructions_bin_line_item_product_class_code_changed
  product_class_code = get_selected_combo_value(params)
  session[:packing_instructions_bin_line_item_form][:product_class_code_combo_selection] = product_class_code
  @ids = PackingInstructionsBinLineItem.ids_for_product_class_code(product_class_code)
#  render (inline) the html to replace the contents of the td that contains the dropdown 
  render :inline => %{
    <%= select('packing_instructions_bin_line_item','id',@ids)%>

    }

end


#  --------------------------------------------------------------------------------
#   combo_changed event handlers for composite foreign key: commodity_id
#  ---------------------------------------------------------------------------------
#  --------------------------------------------------------------------------------
#   combo_changed event handlers for composite foreign key: size_id
#  ---------------------------------------------------------------------------------
def packing_instructions_bin_line_item_commodity_code_changed
  commodity_code = get_selected_combo_value(params)
  session[:packing_instructions_bin_line_item_form][:commodity_code_combo_selection] = commodity_code
  @size_codes = PackingInstructionsBinLineItem.size_codes_for_commodity_code(commodity_code)
#  render (inline) the html to replace the contents of the td that contains the dropdown 
  render :inline => %{
    <%= select('packing_instructions_bin_line_item','size_code',@size_codes)%>
    <img src = '/images/spinner.gif' style = 'display:none;' id = 'img_packing_instructions_bin_line_item_size_code'/>
    <%= observe_field('packing_instructions_bin_line_item_size_code',:update => 'id_cell',:url => {:action => session[:packing_instructions_bin_line_item_form][:size_code_observer][:remote_method]},:loading => "show_element('img_packing_instructions_bin_line_item_size_code');",:complete => session[:packing_instructions_bin_line_item_form][:size_code_observer][:on_completed_js])%>
    }

end


def packing_instructions_bin_line_item_size_code_changed
  size_code = get_selected_combo_value(params)
  session[:packing_instructions_bin_line_item_form][:size_code_combo_selection] = size_code
  commodity_code =   session[:packing_instructions_bin_line_item_form][:commodity_code_combo_selection]
  @ids = PackingInstructionsBinLineItem.ids_for_size_code_and_commodity_code(size_code,commodity_code)
#  render (inline) the html to replace the contents of the td that contains the dropdown 
  render :inline => %{
    <%= select('packing_instructions_bin_line_item','id',@ids)%>

    }

end


#  --------------------------------------------------------------------------------
#   combo_changed event handlers for composite foreign key: track_slms_indicator_id
#  ---------------------------------------------------------------------------------


end
