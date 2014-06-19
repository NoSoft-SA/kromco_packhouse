class  Tools::PackGroupTemplateController < ApplicationController
 
def program_name?
	"pack_group_template"
end

def bypass_generic_security?
	true
end
def list_pack_group_templates
	return if authorise_for_web('pack_group_template','read') == false 

 	if params[:page]!= nil 

 		session[:pack_group_templates_page] = params['page']

		 render_list_pack_group_templates

		 return 
	else
		session[:pack_group_templates_page] = nil
	end

	list_query = "@pack_group_template_pages = Paginator.new self, PackGroupTemplate.count, @@page_size,@current_page
	 @pack_group_templates = PackGroupTemplate.find(:all,
				 :limit => @pack_group_template_pages.items_per_page,
				 :offset => @pack_group_template_pages.current.offset)"
	session[:query] = list_query
	render_list_pack_group_templates
end


def render_list_pack_group_templates
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:pack_group_templates_page] if session[:pack_group_templates_page]
	@current_page = params['page'] if params['page']
	@pack_group_templates =  eval(session[:query]) if !@pack_group_templates
	render :inline => %{
      <% grid            = build_pack_group_template_grid(@pack_group_templates,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all pack_group_templates' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@pack_group_template_pages) if @pack_group_template_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_pack_group_templates_flat
	return if authorise_for_web('pack_group_template','read')== false
	@is_flat_search = true 
	render_pack_group_template_search_form
end

def render_pack_group_template_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  pack_group_templates'"%> 

		<%= build_pack_group_template_search_form(nil,'submit_pack_group_templates_search','submit_pack_group_templates_search',@is_flat_search)%>

		}, :layout => 'content'
end
 
 
def submit_pack_group_templates_search
	if params['page']
		session[:pack_group_templates_page] =params['page']
	else
		session[:pack_group_templates_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @pack_group_templates = dynamic_search(params[:pack_group_template] ,'pack_group_templates','PackGroupTemplate')
	else
		@pack_group_templates = eval(session[:query])
	end
	if @pack_group_templates.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_pack_group_template_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_pack_group_templates
		end

	else

		render_list_pack_group_templates
	end
end

 
def delete_pack_group_template
	return if authorise_for_web('pack_group_template','delete')== false
	if params[:page]
		session[:pack_group_templates_page] = params['page']
		render_list_pack_group_templates
		return
	end
	id = params[:id]
	if id && pack_group_template = PackGroupTemplate.find(id)
		pack_group_template.destroy
		session[:alert] = " Record deleted."
		render_list_pack_group_templates
	end
end
 
def new_pack_group_template
	return if authorise_for_web('pack_group_template','create')== false
		render_new_pack_group_template
end
 
def create_pack_group_template
	 @pack_group_template = PackGroupTemplate.new(params[:pack_group_template])
	 if @pack_group_template.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_pack_group_template
	 end
end

def render_new_pack_group_template
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new pack_group_template'"%> 

		<%= build_pack_group_template_form(@pack_group_template,'create_pack_group_template','create_pack_group_template',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_pack_group_template
	return if authorise_for_web('pack_group_template','edit')==false 
	 id = params[:id]
	 if id && @pack_group_template = PackGroupTemplate.find(id)
		render_edit_pack_group_template

	 end
end


def render_edit_pack_group_template
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit pack_group_template'"%> 

		<%= build_pack_group_template_form(@pack_group_template,'update_pack_group_template','update_pack_group_template',true)%>

		}, :layout => 'content'
end
 
def update_pack_group_template
	if params[:page]
		session[:pack_group_templates_page] = params['page']
		render_list_pack_group_templates
		return
	end

		@current_page = session[:pack_group_templates_page]
	 id = params[:pack_group_template][:id]
	 if id && @pack_group_template = PackGroupTemplate.find(id)
		 if @pack_group_template.update_attributes(params[:pack_group_template])
			@pack_group_templates = eval(session[:query])
			render_list_pack_group_templates
	 else
			 render_edit_pack_group_template

		 end
	 end
 end
 
 

end
