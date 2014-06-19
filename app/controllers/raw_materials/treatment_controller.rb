class  RawMaterials::TreatmentController < ApplicationController
 
def program_name?
	"treatment"
end

def bypass_generic_security?
	true
end

#===================
#SPRAY PROGRAM CODE
#===================
def list_spray_programs
	return if authorise_for_web(program_name?,'read_spray_program') == false 

 	if params[:page]!= nil 

 		session[:spray_programs_page] = params['page']

		 render_list_spray_programs

		 return 
	else
		session[:spray_programs_page] = nil
	end

	list_query = "@spray_program_pages = Paginator.new self, SprayProgram.count, @@page_size,@current_page
	 @spray_programs = SprayProgram.find(:all,
				 :limit => @spray_program_pages.items_per_page,
				 :offset => @spray_program_pages.current.offset)"
	session[:query] = list_query
	render_list_spray_programs
end


def render_list_spray_programs
	@can_edit = authorise(program_name?,'edit_spray_program',session[:user_id])
	@can_delete = authorise(program_name?,'delete_spray_program',session[:user_id])
	@current_page = session[:spray_programs_page] if session[:spray_programs_page]
	@current_page = params['page'] if params['page']
	@spray_programs =  eval(session[:query]) if !@spray_programs
	render :inline => %{
      <% grid            = build_spray_program_grid(@spray_programs,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all spray_programs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@spray_program_pages) if @spray_program_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_spray_programs_flat
	return if authorise_for_web(program_name?,'read_spray_program')== false
	@is_flat_search = true 
	render_spray_program_search_form
end

def render_spray_program_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  spray_programs'"%> 

		<%= build_spray_program_search_form(nil,'submit_spray_programs_search','submit_spray_programs_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_spray_programs_search
	if params['page']
		session[:spray_programs_page] =params['page']
	else
		session[:spray_programs_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @spray_programs = dynamic_search(params[:spray_program] ,'spray_programs','SprayProgram')
	else
		@spray_programs = eval(session[:query])
	end
	if @spray_programs.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_spray_program_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_spray_programs
		end

	else

		render_list_spray_programs
	end
end

 
def delete_spray_program
  begin
	return if authorise_for_web(program_name?,'delete_spray_program')== false
	if params[:page]
		session[:spray_programs_page] = params['page']
		render_list_spray_programs
		return
	end
	id = params[:id]
	if id && spray_program = SprayProgram.find(id)
		spray_program.destroy
		session[:alert] = " Record deleted."
		render_list_spray_programs
	end
  rescue
   handle_error("spray program could not be deleted")
  end
end
 
def new_spray_program
	return if authorise_for_web(program_name?,'create_spray_program')== false
		render_new_spray_program
end
 
def create_spray_program
  begin
	 @spray_program = SprayProgram.new(params[:spray_program])
	 if @spray_program.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_spray_program
	 end
  rescue
   handle_error("spray program could not be created")
  end
end

def render_new_spray_program
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new spray_program'"%> 

		<%= build_spray_program_form(@spray_program,'create_spray_program','create_spray_program',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_spray_program
	return if authorise_for_web(program_name?,'edit_spray_program')==false 
	 id = params[:id]
	 if id && @spray_program = SprayProgram.find(id)
		render_edit_spray_program

	 end
end


def render_edit_spray_program
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit spray_program'"%> 

		<%= build_spray_program_form(@spray_program,'update_spray_program','update_spray_program',true)%>

		}, :layout => 'content'
end
 
def update_spray_program
  begin
	if params[:page]
		session[:spray_programs_page] = params['page']
		render_list_spray_programs
		return
	end

		@current_page = session[:spray_programs_page]
	 id = params[:spray_program][:id]
	 if id && @spray_program = SprayProgram.find(id)
		 if @spray_program.update_attributes(params[:spray_program])
			@spray_programs = eval(session[:query])
			render_list_spray_programs
	 else
			 render_edit_spray_program

		 end
	 end
  rescue
   handle_error("spray program could not be updated")
  end
 end

#==============
#PC CODES CODE
#==============
def list_pc_codes
	return if authorise_for_web(program_name?,'read_pc_code') == false 

 	if params[:page]!= nil 

 		session[:pc_codes_page] = params['page']

		 render_list_pc_codes

		 return 
	else
		session[:pc_codes_page] = nil
	end

	list_query = "@pc_code_pages = Paginator.new self, PcCode.count, @@page_size,@current_page
	 @pc_codes = PcCode.find(:all,
				 :limit => @pc_code_pages.items_per_page,
				 :offset => @pc_code_pages.current.offset)"
	session[:query] = list_query
	render_list_pc_codes
end


def render_list_pc_codes
	@can_edit = authorise(program_name?,'edit_pc_code',session[:user_id])
	@can_delete = authorise(program_name?,'delete_pc_code',session[:user_id])
	@current_page = session[:pc_codes_page] if session[:pc_codes_page]
	@current_page = params['page'] if params['page']
	@pc_codes =  eval(session[:query]) if !@pc_codes
	render :inline => %{
      <% grid            = build_pc_code_grid(@pc_codes,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all pc_codes' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@pc_code_pages) if @pc_code_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_pc_codes_flat
	return if authorise_for_web(program_name?,'read_pc_code')== false
	@is_flat_search = true 
	render_pc_code_search_form
end

def render_pc_code_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  pc_codes'"%> 

		<%= build_pc_code_search_form(nil,'submit_pc_codes_search','submit_pc_codes_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_pc_codes_hierarchy
	return if authorise_for_web(program_name?,'read_pc_code')== false
 
	@is_flat_search = false 
	render_pc_code_search_form(true)
end

def render_pc_code_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  pc_codes'"%> 

		<%= build_pc_code_search_form(nil,'submit_pc_codes_search','submit_pc_codes_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_pc_codes_search
	if params['page']
		session[:pc_codes_page] =params['page']
	else
		session[:pc_codes_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @pc_codes = dynamic_search(params[:pc_code] ,'pc_codes','PcCode')
	else
		@pc_codes = eval(session[:query])
	end
	if @pc_codes.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_pc_code_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_pc_codes
		end

	else

		render_list_pc_codes
	end
end

 
def delete_pc_code
  begin
	return if authorise_for_web(program_name?,'delete_pc_code')== false
	if params[:page]
		session[:pc_codes_page] = params['page']
		render_list_pc_codes
		return
	end
	id = params[:id]
	if id && pc_code = PcCode.find(id)
		pc_code.destroy
		session[:alert] = " Record deleted."
		render_list_pc_codes
	end
   rescue
   handle_error("pc code could not be deleted")
  end
end
 
def new_pc_code
	return if authorise_for_web(program_name?,'create_pc_code')== false
		render_new_pc_code
end
 
def create_pc_code
  begin
	 @pc_code = PcCode.new(params[:pc_code])
	 if @pc_code.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_pc_code
	 end
  rescue
   handle_error("pc code could not be created")
  end
end

def render_new_pc_code
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new pc_code'"%> 

		<%= build_pc_code_form(@pc_code,'create_pc_code','create_pc_code',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_pc_code
	return if authorise_for_web(program_name?,'edit_pc_code')==false
	 id = params[:id]
	 if id && @pc_code = PcCode.find(id)
		render_edit_pc_code

	 end
end


def render_edit_pc_code
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit pc_code'"%> 

		<%= build_pc_code_form(@pc_code,'update_pc_code','update_pc_code',true)%>

		}, :layout => 'content'
end
 
def update_pc_code
  begin
	if params[:page]
		session[:pc_codes_page] = params['page']
		render_list_pc_codes
		return
	end

		@current_page = session[:pc_codes_page]
	 id = params[:pc_code][:id]
	 if id && @pc_code = PcCode.find(id)
		 if @pc_code.update_attributes(params[:pc_code])
			@pc_codes = eval(session[:query])
			render_list_pc_codes
	 else
			 render_edit_pc_code

		 end
	 end
  rescue
   handle_error("pc code could not be updated")
  end
 end


#===================
#COSMETIC CODES CODE
#===================
def list_cosmetic_codes
	return if authorise_for_web(program_name?,'read_cosmetic_code') == false 

 	if params[:page]!= nil 

 		session[:cosmetic_codes_page] = params['page']

		 render_list_cosmetic_codes

		 return 
	else
		session[:cosmetic_codes_page] = nil
	end

	list_query = "@cosmetic_code_pages = Paginator.new self, CosmeticCode.count, @@page_size,@current_page
	 @cosmetic_codes = CosmeticCode.find(:all,
				 :limit => @cosmetic_code_pages.items_per_page,
				 :offset => @cosmetic_code_pages.current.offset)"
	session[:query] = list_query
	render_list_cosmetic_codes
end


def render_list_cosmetic_codes
	@can_edit = authorise(program_name?,'edit_cosmetic_code',session[:user_id])
	@can_delete = authorise(program_name?,'delete_cosmetic_code',session[:user_id])
	@current_page = session[:cosmetic_codes_page] if session[:cosmetic_codes_page]
	@current_page = params['page'] if params['page']
	@cosmetic_codes =  eval(session[:query]) if !@cosmetic_codes
	render :inline => %{
      <% grid            = build_cosmetic_code_grid(@cosmetic_codes,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all cosmetic_codes' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@cosmetic_code_pages) if @cosmetic_code_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_cosmetic_codes_flat
	return if authorise_for_web(program_name?,'read_cosmetic_code')== false
	@is_flat_search = true 
	render_cosmetic_code_search_form
end

def render_cosmetic_code_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  cosmetic_codes'"%> 

		<%= build_cosmetic_code_search_form(nil,'submit_cosmetic_codes_search','submit_cosmetic_codes_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_cosmetic_codes_hierarchy
	return if authorise_for_web(program_name?,'read_cosmetic_code')== false
 
	@is_flat_search = false 
	render_cosmetic_code_search_form(true)
end

def render_cosmetic_code_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  cosmetic_codes'"%> 

		<%= build_cosmetic_code_search_form(nil,'submit_cosmetic_codes_search','submit_cosmetic_codes_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_cosmetic_codes_search
	if params['page']
		session[:cosmetic_codes_page] =params['page']
	else
		session[:cosmetic_codes_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @cosmetic_codes = dynamic_search(params[:cosmetic_code] ,'cosmetic_codes','CosmeticCode')
	else
		@cosmetic_codes = eval(session[:query])
	end
	if @cosmetic_codes.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_cosmetic_code_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_cosmetic_codes
		end

	else

		render_list_cosmetic_codes
	end
end

 
def delete_cosmetic_code
  begin
	return if authorise_for_web(program_name?,'delete_cosmetic_code')== false
	if params[:page]
		session[:cosmetic_codes_page] = params['page']
		render_list_cosmetic_codes
		return
	end
	id = params[:id]
	if id && cosmetic_code = CosmeticCode.find(id)
		cosmetic_code.destroy
		session[:alert] = " Record deleted."
		render_list_cosmetic_codes
	end
  rescue
   handle_error("cosmetic code could not be deleted")
  end
end
 
def new_cosmetic_code
	return if authorise_for_web(program_name?,'create_cosmetic_code')== false
		render_new_cosmetic_code
end
 
def create_cosmetic_code
  begin
	 @cosmetic_code = CosmeticCode.new(params[:cosmetic_code])
	 if @cosmetic_code.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_cosmetic_code
	 end
  rescue
   handle_error("cosmetic code could not be created")
  end
end

def render_new_cosmetic_code
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new cosmetic_code'"%> 

		<%= build_cosmetic_code_form(@cosmetic_code,'create_cosmetic_code','create_cosmetic_code',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_cosmetic_code
	return if authorise_for_web(program_name?,'edit_cosmetic_code')==false 
	 id = params[:id]
	 if id && @cosmetic_code = CosmeticCode.find(id)
		render_edit_cosmetic_code

	 end
end


def render_edit_cosmetic_code
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit cosmetic_code'"%> 

		<%= build_cosmetic_code_form(@cosmetic_code,'update_cosmetic_code','update_cosmetic_code',true)%>

		}, :layout => 'content'
end
 
def update_cosmetic_code
  begin
	if params[:page]
		session[:cosmetic_codes_page] = params['page']
		render_list_cosmetic_codes
		return
	end

		@current_page = session[:cosmetic_codes_page]
	 id = params[:cosmetic_code][:id]
	 if id && @cosmetic_code = CosmeticCode.find(id)
		 if @cosmetic_code.update_attributes(params[:cosmetic_code])
			@cosmetic_codes = eval(session[:query])
			render_list_cosmetic_codes
	 else
			 render_edit_cosmetic_code

		 end
	 end
  rescue
   handle_error("cosmetic code could not be updated")
  end
 end
#====================
#COLD STORE TYPE CODE
#====================
def list_cold_store_types
	return if authorise_for_web(program_name?,'read_cold_store_type') == false 

 	if params[:page]!= nil 

 		session[:cold_store_types_page] = params['page']

		 render_list_cold_store_types

		 return 
	else
		session[:cold_store_types_page] = nil
	end

	list_query = "@cold_store_type_pages = Paginator.new self, ColdStoreType.count, @@page_size,@current_page
	 @cold_store_types = ColdStoreType.find(:all,
				 :limit => @cold_store_type_pages.items_per_page,
				 :offset => @cold_store_type_pages.current.offset)"
	session[:query] = list_query
	render_list_cold_store_types
end


def render_list_cold_store_types
	@can_edit = authorise(program_name?,'edit_cold_store_type',session[:user_id])
	@can_delete = authorise(program_name?,'delete_cold_store_type',session[:user_id])
	@current_page = session[:cold_store_types_page] if session[:cold_store_types_page]
	@current_page = params['page'] if params['page']
	@cold_store_types =  eval(session[:query]) if !@cold_store_types
	render :inline => %{
      <% grid            = build_cold_store_type_grid(@cold_store_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all cold_store_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@cold_store_type_pages) if @cold_store_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_cold_store_types_flat
	return if authorise_for_web(program_name?,'read_cold_store_type')== false
	@is_flat_search = true 
	render_cold_store_type_search_form
end

def render_cold_store_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  cold_store_types'"%> 

		<%= build_cold_store_type_search_form(nil,'submit_cold_store_types_search','submit_cold_store_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_cold_store_types_hierarchy
	return if authorise_for_web(program_name?,'read_cold_store_type')== false
 
	@is_flat_search = false 
	render_cold_store_type_search_form(true)
end

def render_cold_store_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  cold_store_types'"%> 

		<%= build_cold_store_type_search_form(nil,'submit_cold_store_types_search','submit_cold_store_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_cold_store_types_search
	if params['page']
		session[:cold_store_types_page] =params['page']
	else
		session[:cold_store_types_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @cold_store_types = dynamic_search(params[:cold_store_type] ,'cold_store_types','ColdStoreType')
	else
		@cold_store_types = eval(session[:query])
	end
	if @cold_store_types.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_cold_store_type_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_cold_store_types
		end

	else

		render_list_cold_store_types
	end
end

 
def delete_cold_store_type
  begin
	return if authorise_for_web(program_name?,'delete_cold_store_type')== false
	if params[:page]
		session[:cold_store_types_page] = params['page']
		render_list_cold_store_types
		return
	end
	id = params[:id]
	if id && cold_store_type = ColdStoreType.find(id)
		cold_store_type.destroy
		session[:alert] = " Record deleted."
		render_list_cold_store_types
	end
 rescue
   handle_error("cold store type could not be deleted")
  end
end
 
def new_cold_store_type
	return if authorise_for_web(program_name?,'create_cold_store_type')== false
		render_new_cold_store_type
end
 
def create_cold_store_type
  begin
	 @cold_store_type = ColdStoreType.new(params[:cold_store_type])
	 if @cold_store_type.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_cold_store_type
	 end
  rescue
   handle_error("cold store type could not be created")
  end
end

def render_new_cold_store_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new cold_store_type'"%> 

		<%= build_cold_store_type_form(@cold_store_type,'create_cold_store_type','create_cold_store_type',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_cold_store_type
	return if authorise_for_web(program_name?,'edit_cold_store_type')==false 
	 id = params[:id]
	 if id && @cold_store_type = ColdStoreType.find(id)
		render_edit_cold_store_type

	 end
end


def render_edit_cold_store_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit cold_store_type'"%> 

		<%= build_cold_store_type_form(@cold_store_type,'update_cold_store_type','update_cold_store_type',true)%>

		}, :layout => 'content'
end
 
def update_cold_store_type
  begin
	if params[:page]
		session[:cold_store_types_page] = params['page']
		render_list_cold_store_types
		return
	end

		@current_page = session[:cold_store_types_page]
	 id = params[:cold_store_type][:id]
	 if id && @cold_store_type = ColdStoreType.find(id)
		 if @cold_store_type.update_attributes(params[:cold_store_type])
			@cold_store_types = eval(session[:query])
			render_list_cold_store_types
	 else
			 render_edit_cold_store_type

		 end
	 end
   rescue
   handle_error("cold store type could not be updated")
  end
 end


#==================
#RIPE POINT CODE
#==================
def list_ripe_points
	return if authorise_for_web(program_name?,'read_ripe_point') == false 

 	if params[:page]!= nil 

 		session[:ripe_points_page] = params['page']

		 render_list_ripe_points

		 return 
	else
		session[:ripe_points_page] = nil
	end

	list_query = "@ripe_point_pages = Paginator.new self, RipePoint.count, @@page_size,@current_page
	 @ripe_points = RipePoint.find(:all,
				 :limit => @ripe_point_pages.items_per_page,
				 :offset => @ripe_point_pages.current.offset)"
	session[:query] = list_query
	render_list_ripe_points
end


def render_list_ripe_points
	@can_edit = authorise(program_name?,'edit_ripe_point',session[:user_id])
	@can_delete = authorise(program_name?,'delete_ripe_point',session[:user_id])
	@current_page = session[:ripe_points_page] if session[:ripe_points_page]
	@current_page = params['page'] if params['page']
	@ripe_points =  eval(session[:query]) if !@ripe_points
	render :inline => %{
      <% grid            = build_ripe_point_grid(@ripe_points,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all ripe_points' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@ripe_point_pages) if @ripe_point_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_ripe_points_flat
	return if authorise_for_web(program_name?,'read_ripe_point')== false
	@is_flat_search = true 
	render_ripe_point_search_form
end

def render_ripe_point_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  ripe_points'"%> 

		<%= build_ripe_point_search_form(nil,'submit_ripe_points_search','submit_ripe_points_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_ripe_points_hierarchy
	return if authorise_for_web(program_name?,'read_ripe_point')== false
 
	@is_flat_search = false 
	render_ripe_point_search_form(true)
end

def render_ripe_point_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  ripe_points'"%> 

		<%= build_ripe_point_search_form(nil,'submit_ripe_points_search','submit_ripe_points_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_ripe_points_search
	if params['page']
		session[:ripe_points_page] =params['page']
	else
		session[:ripe_points_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @ripe_points = dynamic_search(params[:ripe_point] ,'ripe_points','RipePoint')
	else
		@ripe_points = eval(session[:query])
	end
	if @ripe_points.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_ripe_point_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_ripe_points
		end

	else

		render_list_ripe_points
	end
end

 
def delete_ripe_point
  begin
	return if authorise_for_web(program_name?,'delete_ripe_point')== false
	if params[:page]
		session[:ripe_points_page] = params['page']
		render_list_ripe_points
		return
	end
	id = params[:id]
	if id && ripe_point = RipePoint.find(id)
		ripe_point.destroy
		session[:alert] = " Record deleted."
		render_list_ripe_points
	end
   rescue
   handle_error("ripe point could not be deleted")
  end
end
 
def new_ripe_point
	return if authorise_for_web(program_name?,'create_ripe_point')== false
		render_new_ripe_point
end
 
def create_ripe_point
  begin
	 @ripe_point = RipePoint.new(params[:ripe_point])
	 if @ripe_point.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_ripe_point
	 end
  rescue
   handle_error("ripe point could not be created")
  end
end

def render_new_ripe_point
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new ripe_point'"%> 

		<%= build_ripe_point_form(@ripe_point,'create_ripe_point','create_ripe_point',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_ripe_point
	return if authorise_for_web(program_name?,'edit_ripe_point')==false
	 id = params[:id]
	 if id && @ripe_point = RipePoint.find(id)
		render_edit_ripe_point
	 end
end

def view_ripe_point
	 id = params[:id]
	 if id && @ripe_point = RipePoint.find(id)
		render :inline => %{
		<% @content_header_caption = "'edit ripe_point'"%>

		<%= build_ripe_point_view_form(@ripe_point)%>

		}, :layout => 'content'
	 end
end


def render_edit_ripe_point
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit ripe_point'"%> 

		<%= build_ripe_point_form(@ripe_point,'update_ripe_point','update_ripe_point',true)%>

		}, :layout => 'content'
end
 
def update_ripe_point
  begin
	if params[:page]
		session[:ripe_points_page] = params['page']
		render_list_ripe_points
		return
	end

		@current_page = session[:ripe_points_page]
	 id = params[:ripe_point][:id]
	 if id && @ripe_point = RipePoint.find(id)
		 if @ripe_point.update_attributes(params[:ripe_point])
			@ripe_points = eval(session[:query])
			render_list_ripe_points
	 else
			 render_edit_ripe_point

		 end
	 end
  rescue
   handle_error("ripe point could not be updated")
  end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: cold_store_type_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: pc_code_id
#	---------------------------------------------------------------------------------
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: treatment_id
#	---------------------------------------------------------------------------------
def ripe_point_treatment_type_code_changed
	treatment_type_code = get_selected_combo_value(params)
	session[:ripe_point_form][:treatment_type_code_combo_selection] = treatment_type_code
	@treatment_codes = RipePoint.treatment_codes_for_treatment_type_code(treatment_type_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('ripe_point','treatment_code',@treatment_codes)%>

		}

end


def ripe_point_treatment2_type_code_changed
	treatment_type_code = get_selected_combo_value(params)
	session[:ripe_point_form][:treatment2_type_code_combo_selection] = treatment_type_code
	@treatment_codes = RipePoint.treatment_codes_for_treatment_type_code(treatment_type_code)
#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('ripe_point','treatment2_code',@treatment_codes)%>

		}

end


 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(ripe_points)
#	-----------------------------------------------------------------------------------------------------------
def ripe_point_treatment_code_search_combo_changed
	treatment_code = get_selected_combo_value(params)
	session[:ripe_point_search_form][:treatment_code_combo_selection] = treatment_code
	@cold_store_type_codes = RipePoint.find_by_sql("Select distinct cold_store_type_code from ripe_points where treatment_code = '#{treatment_code}'").map{|g|[g.cold_store_type_code]}
	@cold_store_type_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('ripe_point','cold_store_type_code',@cold_store_type_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_ripe_point_cold_store_type_code'/>
		<%= observe_field('ripe_point_cold_store_type_code',:update => 'pc_code_code_cell',:url => {:action => session[:ripe_point_search_form][:cold_store_type_code_observer][:remote_method]},:loading => "show_element('img_ripe_point_cold_store_type_code');",:complete => session[:ripe_point_search_form][:cold_store_type_code_observer][:on_completed_js])%>
		}

end


def ripe_point_cold_store_type_code_search_combo_changed
	cold_store_type_code = get_selected_combo_value(params)
	session[:ripe_point_search_form][:cold_store_type_code_combo_selection] = cold_store_type_code
	treatment_code = 	session[:ripe_point_search_form][:treatment_code_combo_selection]
	@pc_code_codes = RipePoint.find_by_sql("Select distinct pc_code_code from ripe_points where cold_store_type_code = '#{cold_store_type_code}' and treatment_code = '#{treatment_code}'").map{|g|[g.pc_code_code]}
	@pc_code_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('ripe_point','pc_code_code',@pc_code_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_ripe_point_pc_code_code'/>
		<%= observe_field('ripe_point_pc_code_code',:update => 'ripe_point_code_cell',:url => {:action => session[:ripe_point_search_form][:pc_code_code_observer][:remote_method]},:loading => "show_element('img_ripe_point_pc_code_code');",:complete => session[:ripe_point_search_form][:pc_code_code_observer][:on_completed_js])%>
		}

end


def ripe_point_pc_code_code_search_combo_changed
	pc_code_code = get_selected_combo_value(params)
	session[:ripe_point_search_form][:pc_code_code_combo_selection] = pc_code_code
	cold_store_type_code = 	session[:ripe_point_search_form][:cold_store_type_code_combo_selection]
	treatment_code = 	session[:ripe_point_search_form][:treatment_code_combo_selection]
	@ripe_point_codes = RipePoint.find_by_sql("Select distinct ripe_point_code from ripe_points where pc_code_code = '#{pc_code_code}' and cold_store_type_code = '#{cold_store_type_code}' and treatment_code = '#{treatment_code}'").map{|g|[g.ripe_point_code]}
	@ripe_point_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('ripe_point','ripe_point_code',@ripe_point_codes)%>

		}

end


#====================
#TREATMENT TYPES CODE
#====================
def list_treatment_types
	return if authorise_for_web(program_name?,'read_treatment_type') == false 

 	if params[:page]!= nil 

 		session[:treatment_types_page] = params['page']

		 render_list_treatment_types

		 return 
	else
		session[:treatment_types_page] = nil
	end

	list_query = "@treatment_type_pages = Paginator.new self, TreatmentType.count, @@page_size,@current_page
	 @treatment_types = TreatmentType.find(:all,
				 :limit => @treatment_type_pages.items_per_page,
				 :offset => @treatment_type_pages.current.offset)"
	session[:query] = list_query
	render_list_treatment_types
end


def render_list_treatment_types
	@can_edit = authorise(program_name?,'edit_treatment_type',session[:user_id])
	@can_delete = authorise(program_name?,'delete_treatment_type',session[:user_id])
	@current_page = session[:treatment_types_page] if session[:treatment_types_page]
	@current_page = params['page'] if params['page']
	@treatment_types =  eval(session[:query]) if !@treatment_types
	render :inline => %{
      <% grid            = build_treatment_type_grid(@treatment_types,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all treatment_types' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@treatment_type_pages) if @treatment_type_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_treatment_types_flat
	return if authorise_for_web(program_name?,'read_treatment_type')== false
	@is_flat_search = true 
	render_treatment_type_search_form
end

def render_treatment_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  treatment_types'"%> 

		<%= build_treatment_type_search_form(nil,'submit_treatment_types_search','submit_treatment_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_treatment_types_hierarchy
	return if authorise_for_web(program_name?,'read_treatment_type')== false
 
	@is_flat_search = false 
	render_treatment_type_search_form(true)
end

def render_treatment_type_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  treatment_types'"%> 

		<%= build_treatment_type_search_form(nil,'submit_treatment_types_search','submit_treatment_types_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_treatment_types_search
	if params['page']
		session[:treatment_types_page] =params['page']
	else
		session[:treatment_types_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @treatment_types = dynamic_search(params[:treatment_type] ,'treatment_types','TreatmentType')
	else
		@treatment_types = eval(session[:query])
	end
	if @treatment_types.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_treatment_type_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_treatment_types
		end

	else

		render_list_treatment_types
	end
end

 
def delete_treatment_type
  begin
	return if authorise_for_web(program_name?,'delete_treatment_type')== false
	if params[:page]
		session[:treatment_types_page] = params['page']
		render_list_treatment_types
		return
	end
	id = params[:id]
	if id && treatment_type = TreatmentType.find(id)
		treatment_type.destroy
		session[:alert] = " Record deleted."
		render_list_treatment_types
	end
   rescue
   handle_error("treatment type could not be deleted")
  end
end
 
def new_treatment_type
	return if authorise_for_web(program_name?,'create_treatment_type')== false
		render_new_treatment_type
end
 
def create_treatment_type
  begin
	 @treatment_type = TreatmentType.new(params[:treatment_type])
	 if @treatment_type.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_treatment_type
	 end
  rescue
   handle_error("treatment type code could not be created")
  end
end

def render_new_treatment_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new treatment_type'"%> 

		<%= build_treatment_type_form(@treatment_type,'create_treatment_type','create_treatment_type',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_treatment_type
	return if authorise_for_web(program_name?,'edit_treatment_type')==false 
	 id = params[:id]
	 if id && @treatment_type = TreatmentType.find(id)
		render_edit_treatment_type

	 end
end


def render_edit_treatment_type
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit treatment_type'"%> 

		<%= build_treatment_type_form(@treatment_type,'update_treatment_type','update_treatment_type',true)%>

		}, :layout => 'content'
end
 
def update_treatment_type
  begin
	if params[:page]
		session[:treatment_types_page] = params['page']
		render_list_treatment_types
		return
	end

		@current_page = session[:treatment_types_page]
	 id = params[:treatment_type][:id]
	 if id && @treatment_type = TreatmentType.find(id)
		 if @treatment_type.update_attributes(params[:treatment_type])
			@treatment_types = eval(session[:query])
			render_list_treatment_types
	 else
			 render_edit_treatment_type

		 end
	 end
  rescue
   handle_error("treatment type could not be updated")
  end
 end


#===============
#TREATMENTS CODE
#===============

def list_treatments
	return if authorise_for_web(program_name?,'read_treatment') == false 

 	if params[:page]!= nil 

 		session[:treatments_page] = params['page']

		 render_list_treatments

		 return 
	else
		session[:treatments_page] = nil
	end

	list_query = "@treatment_pages = Paginator.new self, Treatment.count, @@page_size,@current_page
	 @treatments = Treatment.find(:all,
				 :limit => @treatment_pages.items_per_page,
				 :offset => @treatment_pages.current.offset)"
	session[:query] = list_query
	render_list_treatments
end


def render_list_treatments
	@can_edit = authorise(program_name?,'edit_treatment',session[:user_id])
	@can_delete = authorise(program_name?,'delete_treatment',session[:user_id])
	@current_page = session[:treatments_page] if session[:treatments_page]
	@current_page = params['page'] if params['page']
	@treatments =  eval(session[:query]) if !@treatments
	render :inline => %{
      <% grid            = build_treatment_grid(@treatments,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all treatments' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@treatment_pages) if @treatment_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_treatments_flat
	return if authorise_for_web(program_name?,'read_treatment')== false
	@is_flat_search = true 
	render_treatment_search_form
end

def render_treatment_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  treatments'"%> 

		<%= build_treatment_search_form(nil,'submit_treatments_search','submit_treatments_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def search_treatments_hierarchy
	return if authorise_for_web(program_name?,'read_treatment')== false
 
	@is_flat_search = false 
	render_treatment_search_form(true)
end

def render_treatment_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  treatments'"%> 

		<%= build_treatment_search_form(nil,'submit_treatments_search','submit_treatments_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
def submit_treatments_search
	if params['page']
		session[:treatments_page] =params['page']
	else
		session[:treatments_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @treatments = dynamic_search(params[:treatment] ,'treatments','Treatment')
	else
		@treatments = eval(session[:query])
	end
	if @treatments.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_treatment_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_treatments
		end

	else

		render_list_treatments
	end
end

 
def delete_treatment
  begin
	return if authorise_for_web(program_name?,'delete_treatment')== false
	if params[:page]
		session[:treatments_page] = params['page']
		render_list_treatments
		return
	end
	id = params[:id]
	if id && treatment = Treatment.find(id)
		treatment.destroy
		session[:alert] = " Record deleted."
		render_list_treatments
	end
   rescue
   handle_error("treatment could not be deleted")
  end
end
 
def new_treatment
	return if authorise_for_web(program_name?,'create_treatment')== false
		render_new_treatment
end
 
def create_treatment
  begin
	 @treatment = Treatment.new(params[:treatment])
	 if @treatment.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_treatment
	 end
  rescue
   handle_error("treatment could not be created")
  end
end

def render_new_treatment
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new treatment'"%> 

		<%= build_treatment_form(@treatment,'create_treatment','create_treatment',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_treatment
	return if authorise_for_web(program_name?,'edit_treatment')==false 
	 id = params[:id]
	 if id && @treatment = Treatment.find(id)
		render_edit_treatment

	 end
end


def render_edit_treatment
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit treatment'"%> 

		<%= build_treatment_form(@treatment,'update_treatment','update_treatment',true)%>

		}, :layout => 'content'
end
 
def update_treatment
  begin
	if params[:page]
		session[:treatments_page] = params['page']
		render_list_treatments
		return
	end

		@current_page = session[:treatments_page]
	 id = params[:treatment][:id]
	 if id && @treatment = Treatment.find(id)
		 if @treatment.update_attributes(params[:treatment])
			@treatments = eval(session[:query])
			render_list_treatments
	 else
			 render_edit_treatment

		 end
	 end
  rescue
   handle_error("treatment could not be updated")
  end
 end
 
#	--------------------------------------------------------------------------------
#	 combo_changed event handlers for composite foreign key: treatment_type_id
#	---------------------------------------------------------------------------------
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(treatments)
#	-----------------------------------------------------------------------------------------------------------
def treatment_treatment_type_code_search_combo_changed
	treatment_type_code = get_selected_combo_value(params)
	session[:treatment_search_form][:treatment_type_code_combo_selection] = treatment_type_code
	@treatment_codes = Treatment.find_by_sql("Select distinct treatment_code from treatments where treatment_type_code = '#{treatment_type_code}'").map{|g|[g.treatment_code]}
	@treatment_codes.unshift("<empty>")

#	render (inline) the html to replace the contents of the td that contains the dropdown 
	render :inline => %{
		<%= select('treatment','treatment_code',@treatment_codes)%>

		}

end



end
