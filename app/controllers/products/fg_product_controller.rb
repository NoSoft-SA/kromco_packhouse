class  Products::FgProductController < ApplicationController
 
 #fix: paging fixed
 
def program_name?
	"fg_product"
end


#-----------------------
#EXTENDED FG CODE
#-----------------------
def clone_extended_fg

    return if authorise_for_web(program_name?,'fg_clone')==false
    id = params[:id]
	  if id && extended_fg = ExtendedFg.find(id)
       @extended_fg = ExtendedFg.new
       extended_fg.export_attributes(@extended_fg)
		   render_new_extended_fg

	  end


end


def list_extended_fgs
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:extended_fgs_page] = params['page']

		 render_list_extended_fgs

		 return 
	else
		session[:extended_fgs_page] = nil
	end

	list_query = "@extended_fg_pages = Paginator.new self, ExtendedFg.count, @@page_size,@current_page
	 @extended_fgs = ExtendedFg.find(:all,
				 :limit => @extended_fg_pages.items_per_page,
				 :offset => @extended_fg_pages.current.offset)"
	session[:query] = list_query
	render_list_extended_fgs
end

 
def render_list_extended_fgs
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:extended_fgs_page] if session[:extended_fgs_page]
	@current_page = params['page'] if params['page']
	@extended_fgs =  eval(session[:query]) if !@extended_fgs
	render :inline => %{
      <% grid            = build_extended_fg_grid(@extended_fgs,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all extended_fgs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@extended_fg_pages) if @extended_fg_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_extended_fgs_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_extended_fg_search_form
end

def render_extended_fg_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  extended_fgs'"%> 

		<%= build_extended_fg_search_form(nil,'submit_extended_fgs_search','submit_extended_fgs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_extended_fgs_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_extended_fg_search_form(true)
end

def render_extended_fg_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  extended_fgs'"%> 

		<%= build_extended_fg_search_form(nil,'submit_extended_fgs_search','submit_extended_fgs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_extended_fgs_search
	if params['page']
		session[:extended_fgs_page] =params['page']
	else
		session[:extended_fgs_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @extended_fgs = dynamic_search(params[:extended_fg] ,'extended_fgs','ExtendedFg')
	else
		@extended_fgs = eval(session[:query])
	end
	if @extended_fgs.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_extended_fg_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_extended_fgs
		end

	else

		render_list_extended_fgs
	end
end

 
def delete_extended_fg
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:extended_fgs_page] = params['page']
		render_list_extended_fgs
		return
	end
	id = params[:id]
	if id && extended_fg = ExtendedFg.find(id)
		extended_fg.destroy
		session[:alert] = " Record deleted."
		render_list_extended_fgs
	end
end
 
def new_extended_fg
	return if authorise_for_web(program_name?,'create')== false
		render_new_extended_fg
end
 
def create_extended_fg
	 @extended_fg = ExtendedFg.new(params[:extended_fg])
	 if @extended_fg.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_extended_fg
	 end
end

def render_new_extended_fg
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new extended_fg'"%> 

		<%= build_extended_fg_form(@extended_fg,'create_extended_fg','create_extended_fg',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_extended_fg
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @extended_fg = ExtendedFg.find(id)
		render_edit_extended_fg

	 end
end


def render_edit_extended_fg
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit extended_fg'"%> 

		<%= build_extended_fg_form(@extended_fg,'update_extended_fg','update_extended_fg',true)%>

		}, :layout => 'content'
end
 
def update_extended_fg
	if params[:page]
		session[:extended_fgs_page] = params['page']
		render_list_extended_fgs
		return
	end

	 @current_page = session[:extended_fgs_page]
	 id = params[:extended_fg][:id]
	 if id && @extended_fg = ExtendedFg.find(id)
		 if @extended_fg.update_attributes(params[:extended_fg])
			@extended_fgs = eval(session[:query])
			render_list_extended_fgs
	 else
			 render_edit_extended_fg

		 end
	 end
 end
 
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(extended_fgs)
#	-----------------------------------------------------------------------------------------------------------
def extended_fg_fg_code_search_combo_changed
	fg_code = get_selected_combo_value(params)
	session[:extended_fg_search_form][:fg_code_combo_selection] = fg_code
	@fg_mark_codes = ExtendedFg.find_by_sql("Select distinct fg_mark_code from extended_fgs where fg_code = '#{fg_code}'").map{|g|[g.fg_mark_code]}
	@fg_mark_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('extended_fg','fg_mark_code',@fg_mark_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_extended_fg_fg_mark_code'/>
		<%= observe_field('extended_fg_fg_mark_code',:update => 'units_per_carton_cell',:url => {:action => session[:extended_fg_search_form][:fg_mark_code_observer][:remote_method]},:loading => "show_element('img_extended_fg_fg_mark_code');",:complete => session[:extended_fg_search_form][:fg_mark_code_observer][:on_completed_js])%>
		}

end


def extended_fg_fg_mark_code_search_combo_changed
	fg_mark_code = get_selected_combo_value(params)
	session[:extended_fg_search_form][:fg_mark_code_combo_selection] = fg_mark_code
	fg_code = 	session[:extended_fg_search_form][:fg_code_combo_selection]
	@units_per_cartons = ExtendedFg.find_by_sql("Select distinct units_per_carton from extended_fgs where fg_mark_code = '#{fg_mark_code}' and fg_code = '#{fg_code}'").map{|g|[g.units_per_carton]}
	@units_per_cartons.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('extended_fg','units_per_carton',@units_per_cartons)%>

		}

end

#---------------------------------
#FG MARKS CODE
#---------------------------------

def bypass_generic_security?
	true
end

def list_fg_marks
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:fg_marks_page] = params['page']

		 render_list_fg_marks

		 return 
	else
		session[:fg_marks_page] = nil
	end

	list_query = "@fg_mark_pages = Paginator.new self, FgMark.count, @@page_size,@current_page
	 @fg_marks = FgMark.find(:all,
				 :limit => @fg_mark_pages.items_per_page,
				 :offset => @fg_mark_pages.current.offset)"
	session[:query] = list_query
	render_list_fg_marks
end


def render_list_fg_marks
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:fg_marks_page] if session[:fg_marks_page]
	@current_page = params['page'] if params['page']
	@fg_marks =  eval(session[:query]) if !@fg_marks
	render :inline => %{
      <% grid            = build_fg_mark_grid(@fg_marks,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all fg_marks' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@fg_mark_pages) if @fg_mark_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_fg_marks_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true 
	render_fg_mark_search_form
end

def render_fg_mark_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  fg_marks'"%> 

		<%= build_fg_mark_search_form(nil,'submit_fg_marks_search','submit_fg_marks_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_fg_marks_hierarchy
	return if authorise_for_web(program_name?,'read')== false
 
	@is_flat_search = false 
	render_fg_mark_search_form(true)
end

def render_fg_mark_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  fg_marks'"%> 

		<%= build_fg_mark_search_form(nil,'submit_fg_marks_search','submit_fg_marks_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_fg_marks_search
	if params['page']
		session[:fg_marks_page] =params['page']
	else
		session[:fg_marks_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @fg_marks = dynamic_search(params[:fg_mark] ,'fg_marks','FgMark')
	else
		@fg_marks = eval(session[:query])
	end
	if @fg_marks.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_fg_mark_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_fg_marks
		end

	else

		render_list_fg_marks
	end
end

 
def delete_fg_mark
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:fg_marks_page] = params['page']
		render_list_fg_marks
		return
	end
	id = params[:id]
	if id && fg_mark = FgMark.find(id)
		fg_mark.destroy
		session[:alert] = " Record deleted."
		render_list_fg_marks
	end
end
 
def new_fg_mark
	return if authorise_for_web(program_name?,'create')== false
		render_new_fg_mark
end
 
def create_fg_mark
	 @fg_mark = FgMark.new(params[:fg_mark])
	 if @fg_mark.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_fg_mark
	 end
end

def render_new_fg_mark
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new fg_mark'"%> 

		<%= build_fg_mark_form(@fg_mark,'create_fg_mark','create_fg_mark',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_fg_mark
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @fg_mark = FgMark.find(id)
		render_edit_fg_mark

	 end
end


def render_edit_fg_mark
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit fg_mark'"%> 

		<%= build_fg_mark_form(@fg_mark,'update_fg_mark','update_fg_mark',true)%>

		}, :layout => 'content'
end
 
def update_fg_mark
	if params[:page]
		session[:fg_marks_page] = params['page']
		render_list_fg_marks
		return
	end

		@current_page = session[:fg_marks_page]
	 id = params[:fg_mark][:id]
	 if id && @fg_mark = FgMark.find(id)
		 if @fg_mark.update_attributes(params[:fg_mark])
			@fg_marks = eval(session[:query])
			render_list_fg_marks
	 else
			 render_edit_fg_mark

		 end
	 end
 end
 
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(fg_marks)
#	-----------------------------------------------------------------------------------------------------------
def fg_mark_ri_mark_code_search_combo_changed
	ri_mark_code = get_selected_combo_value(params)
	session[:fg_mark_search_form][:ri_mark_code_combo_selection] = ri_mark_code
	@ru_mark_codes = FgMark.find_by_sql("Select distinct ru_mark_code from fg_marks where ri_mark_code = '#{ri_mark_code}'").map{|g|[g.ru_mark_code]}
	@ru_mark_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('fg_mark','ru_mark_code',@ru_mark_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_fg_mark_ru_mark_code'/>
		<%= observe_field('fg_mark_ru_mark_code',:update => 'tu_mark_code_cell',:url => {:action => session[:fg_mark_search_form][:ru_mark_code_observer][:remote_method]},:loading => "show_element('img_fg_mark_ru_mark_code');",:complete => session[:fg_mark_search_form][:ru_mark_code_observer][:on_completed_js])%>
		}

end


def fg_mark_ru_mark_code_search_combo_changed
	ru_mark_code = get_selected_combo_value(params)
	session[:fg_mark_search_form][:ru_mark_code_combo_selection] = ru_mark_code
	ri_mark_code = 	session[:fg_mark_search_form][:ri_mark_code_combo_selection]
	@tu_mark_codes = FgMark.find_by_sql("Select distinct tu_mark_code from fg_marks where ru_mark_code = '#{ru_mark_code}' and ri_mark_code = '#{ri_mark_code}'").map{|g|[g.tu_mark_code]}
	@tu_mark_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('fg_mark','tu_mark_code',@tu_mark_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_fg_mark_tu_mark_code'/>
		<%= observe_field('fg_mark_tu_mark_code',:update => 'fg_mark_code_cell',:url => {:action => session[:fg_mark_search_form][:tu_mark_code_observer][:remote_method]},:loading => "show_element('img_fg_mark_tu_mark_code');",:complete => session[:fg_mark_search_form][:tu_mark_code_observer][:on_completed_js])%>
		}

end


def fg_mark_tu_mark_code_search_combo_changed
	tu_mark_code = get_selected_combo_value(params)
	session[:fg_mark_search_form][:tu_mark_code_combo_selection] = tu_mark_code
	ru_mark_code = 	session[:fg_mark_search_form][:ru_mark_code_combo_selection]
	ri_mark_code = 	session[:fg_mark_search_form][:ri_mark_code_combo_selection]
	@fg_mark_codes = FgMark.find_by_sql("Select distinct fg_mark_code from fg_marks where tu_mark_code = '#{tu_mark_code}' and ru_mark_code = '#{ru_mark_code}' and ri_mark_code = '#{ri_mark_code}'").map{|g|[g.fg_mark_code]}
	@fg_mark_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('fg_mark','fg_mark_code',@fg_mark_codes)%>

		}

end

#==============================
#FG PRODUCTS CODE
#==============================

def list_fg_products
	return if authorise_for_web('fg_product','read') == false 

 	if params[:page]!= nil 

 		session[:fg_products_page] = params['page']

		 render_list_fg_products

		 return 
	else
		session[:fg_products_page] = nil
	end

	list_query = "@fg_product_pages = Paginator.new self, FgProduct.count, @@page_size,@current_page
	 @fg_products = FgProduct.find(:all,
				 :limit => @fg_product_pages.items_per_page,
				 :order => 'fg_product_code',
				 :offset => @fg_product_pages.current.offset)"
	session[:query] = list_query
	render_list_fg_products
end


def render_list_fg_products
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:fg_products_page] if session[:fg_products_page]
	@current_page = params['page'] if params['page']
	@fg_products =  eval(session[:query]) if !@fg_products
	render :inline => %{
      <% grid            = build_fg_product_grid(@fg_products,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all fg_products' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@fg_product_pages) if @fg_product_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>

	},:layout => 'content'
    end
 
def search_fg_products_flat
	return if authorise_for_web('fg_product','read')== false
	@is_flat_search = true 
	render_fg_product_search_form
end

def render_fg_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  fg_products'"%> 

		<%= build_fg_product_search_form(nil,'submit_fg_products_search','submit_fg_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_fg_products_hierarchy
	return if authorise_for_web('fg_product','read')== false
 
	@is_flat_search = false 
	render_fg_product_search_form(true)
end

def render_fg_product_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  fg_products'"%> 

		<%= build_fg_product_search_form(nil,'submit_fg_products_search','submit_fg_products_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_fg_products_search
	if params['page']
		session[:fg_products_page] =params['page']
	else
		session[:fg_products_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @fg_products = dynamic_search(params[:fg_product] ,'fg_products','FgProduct',true,nil,"fg_product_code")
	else
		@fg_products = eval(session[:query])
	end
	if @fg_products.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_fg_product_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_fg_products
		end

	else

		render_list_fg_products
	end
end

 
def delete_fg_product
	return if authorise_for_web('fg_product','delete')== false
	if params[:page]
		session[:fg_products_page] = params['page']
		render_list_fg_products
		return
	end
	id = params[:id]
	if id && fg_product = FgProduct.find(id)
		fg_product.destroy
		session[:alert] = " Record deleted."
		render_list_fg_products
	end
end
 
def new_fg_product
	return if authorise_for_web('fg_product','create')== false
		render_new_fg_product
end
 
def create_fg_product
	 @fg_product = FgProduct.new(params[:fg_product])
	 if @fg_product.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_fg_product
	 end
end

def render_new_fg_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new fg_product'"%> 

		<%= build_fg_product_form(@fg_product,'create_fg_product','create_fg_product',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_fg_product
	return if authorise_for_web('fg_product','edit')==false 
	 id = params[:id]
	 if id && @fg_product = FgProduct.find(id)
		render_edit_fg_product

	 end
end

def view_paging_handler

  if params[:page]
	session[:fg_products_page] = params['page']
  end
  render_list_fg_products
end


def view_fg_product
	return if authorise_for_web('fg_product','edit')==false 
	 id = params[:id]
	 if id && @fg_product = FgProduct.find(id)
		render :inline => %{
		<% @content_header_caption = "'edit fg_product'"%> 

		<%= view_fg_product(@fg_product)%>

		}, :layout => 'content'

	 end
end

def render_edit_fg_product
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit fg_product'"%> 

		<%= build_fg_product_form(@fg_product,'update_fg_product','update_fg_product',true)%>

		}, :layout => 'content'
end
 
def update_fg_product
	if params[:page]
		session[:fg_products_page] = params['page']
		render_list_fg_products
		return
	end

		@current_page = session[:fg_products_page]
	 id = params[:fg_product][:id]
	 if id && @fg_product = FgProduct.find(id)
		 if @fg_product.update_attributes(params[:fg_product])
			@fg_products = eval(session[:query])
			render_list_fg_products
	 else
			 render_edit_fg_product

		 end
	 end
 end
 
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(fg_products)
#	-----------------------------------------------------------------------------------------------------------
def fg_product_item_pack_product_code_search_combo_changed
	item_pack_product_code = get_selected_combo_value(params)
	session[:fg_product_search_form][:item_pack_product_code_combo_selection] = item_pack_product_code
	@unit_pack_product_codes = FgProduct.find_by_sql("Select distinct unit_pack_product_code from fg_products where item_pack_product_code = '#{item_pack_product_code}'").map{|g|[g.unit_pack_product_code]}
	@unit_pack_product_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('fg_product','unit_pack_product_code',@unit_pack_product_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_fg_product_unit_pack_product_code'/>
		<%= observe_field('fg_product_unit_pack_product_code',:update => 'carton_pack_product_code_cell',:url => {:action => session[:fg_product_search_form][:unit_pack_product_code_observer][:remote_method]},:loading => "show_element('img_fg_product_unit_pack_product_code');",:complete => session[:fg_product_search_form][:unit_pack_product_code_observer][:on_completed_js])%>
		}

end


def fg_product_unit_pack_product_code_search_combo_changed
	unit_pack_product_code = get_selected_combo_value(params)
	session[:fg_product_search_form][:unit_pack_product_code_combo_selection] = unit_pack_product_code
	item_pack_product_code = 	session[:fg_product_search_form][:item_pack_product_code_combo_selection]
	@carton_pack_product_codes = FgProduct.find_by_sql("Select distinct carton_pack_product_code from fg_products where unit_pack_product_code = '#{unit_pack_product_code}' and item_pack_product_code = '#{item_pack_product_code}'").map{|g|[g.carton_pack_product_code]}
	@carton_pack_product_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('fg_product','carton_pack_product_code',@carton_pack_product_codes)%>

		}

end



end
