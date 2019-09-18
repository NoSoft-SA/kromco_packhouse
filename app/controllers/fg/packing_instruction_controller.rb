class  Fg::PackingInstructionController < ApplicationController

def program_name?
  "order"
end

def bypass_generic_security?
  true
end


def active_packing_instruction
  if session[:active_doc] && session[:active_doc]['pi']
    redirect_to :controller => 'fg/packing_instruction', :action => 'edit_packing_instruction', :id => session[:active_doc]['pi'] and return
  else
    render :inline=>%{<script> alert('no current packing instruction'); </script>}, :layout=>'content'
  end
end

def list_packing_instructions
  return if authorise_for_web(program_name?,'read') == false 
  store_last_grid_url

   if params[:page]!= nil 

     session[:packing_instructions_page] = params['page']

     render_list_packing_instructions

     return 
  else
    session[:packing_instructions_page] = nil
  end

  list_query = "select pi.*, tp.contact_name as trading_partner,st.shift_type_code as shift_type
                from packing_instructions pi
                left join trading_partners tp on pi.trading_partner_id=tp.id
                left join shift_types st on pi.shift_type_id = st.id
                order by pi.id desc limit 100"
  @packing_instructions = ActiveRecord::Base.connection.select_all(list_query)
  session[:query] = "ActiveRecord::Base.connection.select_all(\"#{list_query}\")"

  render_list_packing_instructions
end


def render_list_packing_instructions
  @pagination_server = "list_packing_instructions"
  @can_edit = authorise(program_name?,'edit',session[:user_id])
  @can_delete = authorise(program_name?,'delete',session[:user_id])
  @current_page = session[:packing_instructions_page]
  @current_page = params['page']||= session[:packing_instructions_page]
  render :inline => %{
    <% grid = build_packing_instruction_grid(@packing_instructions,@can_edit,@can_delete)%>
    <% grid.caption = 'List of all packing_instructions'%>
    <% @header_content = grid.build_grid_data %>

    <% @pagination = pagination_links(@packing_instruction_pages) if @packing_instruction_pages != nil %>
    <%= grid.render_html %>
    <%= grid.render_grid %>
  },:layout => 'content'
end


def render_packing_instruction_search_form(is_flat_search = nil)
  session[:is_flat_search] = @is_flat_search
#   render (inline) the search form
  render :inline => %{
    <% @content_header_caption = "'search  packing_instructions'"%> 

    <%= build_packing_instruction_search_form(nil,'submit_packing_instructions_search','submit_packing_instructions_search',@is_flat_search)%>

    }, :layout => 'content'
end


def submit_packing_instructions_search
  store_last_grid_url
  @packing_instructions = dynamic_search(params[:packing_instruction] ,'packing_instructions','PackingInstruction')
  if @packing_instructions.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_packing_instruction_search_form
    else
      render_list_packing_instructions
  end
end

def delete_packing_instruction
  return if authorise_for_web(program_name?,'delete')== false
  if params[:page]
    session[:packing_instructions_page] = params['page']
    render_list_packing_instructions
    return
  end
  id = params[:id]
  if id && packing_instruction = PackingInstruction.find(id)
    bin_line_items = ActiveRecord::Base.connection.select_one("
                     select count(id)  as items from packing_instructions_bin_line_items
                     where packing_instruction_id = #{id}")['items']
    fg_line_items = ActiveRecord::Base.connection.select_one("
                     select count(id)  as items from packing_instructions_fg_line_items
                     where packing_instruction_id = #{id}")['items']
    if bin_line_items.to_i > 0 || fg_line_items.to_i > 0
      session[:alert] = ' Record cannot be deleted. bin line items and fg line items are depended on it. Delete them first'
      redirect_to_last_grid
    else
      packing_instruction.destroy
      session[:alert] = ' Record deleted.'
      redirect_to_last_grid
    end
  end
  rescue
    handle_error('record could not be deleted')
end

def new_packing_instruction
  return if authorise_for_web(program_name?,'create')== false
  # store_list_as_grid_url # UNCOMMENT if this action is called directly (i.e. from a menu, not from a grid)
  render_new_packing_instruction
end

def create_packing_instruction_code
  shift_type_code = ShiftType.find(params[:packing_instruction]['shift_type_id']).shift_type_code
  #trading_partner =  ActiveRecord::Base.connection.select_one("select contact_name from trading_partners")['contact_name']
  code = shift_type_code + "_" + params[:packing_instruction]['pack_date'].to_s
  return code
end

def create_packing_instruction
   @packing_instruction = PackingInstruction.new(params[:packing_instruction])
   @packing_instruction.packing_instruction_code = create_packing_instruction_code
   if @packing_instruction.save
     set_active_doc("pi",@packing_instruction.id)
     render :inline => %{<script>
                          alert('packing instruction created');
                          window.close();
                         window.parent.opener.frames[1].location.href = '/fg/packing_instruction/list_packing_instructions';
                        </script>}, :layout=>"content"
  else
    @is_create_retry = true
    render_new_packing_instruction
   end
rescue
   handle_error('record could not be created')
end

def render_new_packing_instruction
#   render (inline) the edit template
  render :inline => %{
    <% @content_header_caption = "'create new packing_instruction'"%> 

    <%= build_packing_instruction_form(@packing_instruction,'create_packing_instruction','create_packing_instruction',false,@is_create_retry)%>

    }, :layout => 'content'
end

def edit_packing_instruction
  return if authorise_for_web(program_name?,'edit')==false 
   id = params[:id]
   if id && @packing_instruction = PackingInstruction.find(id)
     set_active_doc("pi",@packing_instruction.id)
     render_edit_packing_instruction
   end
end


def render_edit_packing_instruction
#   render (inline) the edit template
  render :inline => %{
    <% @content_header_caption = "'edit packing_instruction'"%> 

    <%= build_packing_instruction_form(@packing_instruction,'update_packing_instruction','update_packing_instruction',true)%>

    }, :layout => 'content'
end

def update_packing_instruction
   id = params[:packing_instruction][:id]
   if id && @packing_instruction = PackingInstruction.find(id)
     if @packing_instruction.update_attributes(params[:packing_instruction])
      params[:id] = @packing_instruction.id
      flash[:notice] = 'record saved'
      edit_packing_instruction
   else
       render_edit_packing_instruction
     end
   end
rescue
   handle_error('record could not be saved')
 end

  def search_dm_packing_instructions
    return if authorise_for_web(program_name?,'read')== false
    dm_session['se_layout']              = 'content'
    @content_header_caption              = "'Search Packing instructions'"
    dm_session[:redirect]                = true
    build_remote_search_engine_form('search_packing_instructions.yml', 'submit_search_dm_packing_instructions_grid')
  end

  def submit_search_dm_packing_instructions_grid
    @packing_instructions = ActiveRecord::Base.connection.select_all(dm_session[:search_engine_query_definition])
    render_list_packing_instructions
  end


  def search_dm_packing_instructions_grid
    store_last_grid_url
    @can_edit        = authorise(program_name?, 'edit', session[:user_id])
    @can_delete      = authorise(program_name?, 'delete', session[:user_id])
    @stat            = dm_session[:search_engine_query_definition]
    @columns_list    = dm_session[:columns_list]
    @grid_configs    = dm_session[:grid_configs]

    render :inline => %{
      <% grid            = build_packing_instruction_dm_grid(@packing_instructions, @stat, @columns_list, @can_edit, @can_delete, @grid_configs) %>
      <% grid.caption    = 'Packing instructions' %>
      <% @header_content = grid.build_grid_data %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
    }, :layout => 'content'
  end


#  --------------------------------------------------------------------------------
#   combo_changed event handlers for composite foreign key: trading_partner_id
#  ---------------------------------------------------------------------------------
#  --------------------------------------------------------------------------------
#   combo_changed event handlers for composite foreign key: shift_type_id
#  ---------------------------------------------------------------------------------
def packing_instruction_shift_type_code_changed
  shift_type_code = get_selected_combo_value(params)
  session[:packing_instruction_form][:shift_type_code_combo_selection] = shift_type_code
  @ids = PackingInstruction.ids_for_shift_type_code(shift_type_code)
#  render (inline) the html to replace the contents of the td that contains the dropdown 
  render :inline => %{
    <%= select('packing_instruction','id',@ids)%>

    }

end




end
