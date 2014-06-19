class  Fg::RuleController < ApplicationController
 
def program_name?
	"rule"
end

def bypass_generic_security?
	true
end
def list_rules
	return if authorise_for_web(program_name?,'read') == false 

 	if params[:page]!= nil 

 		session[:rules_page] = params['page']

		 render_list_rules

		 return 
	else
		session[:rules_page] = nil
	end

	list_query = "@rule_pages = Paginator.new self, Rule.count, @@page_size,@current_page
	 @rules = Rule.find(:all,
				 :limit => @rule_pages.items_per_page,
				 :offset => @rule_pages.current.offset,:include => :rule_type)"
	session[:query] = list_query
	render_list_rules
end


def render_list_rules
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:rules_page] if session[:rules_page]
	@current_page = params['page'] if params['page']
	@rules =  eval(session[:query]) if !@rules
	render :inline => %{
      <% grid            = build_rule_grid(@rules,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all rules' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@rule_pages) if @rule_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end
 
def search_rules_flat
	return if authorise_for_web(program_name?,'read')== false
	@is_flat_search = true
	render_rule_search_form
end

def render_rule_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  rules'"%>

		<%= build_rule_search_form(nil,'submit_rules_search','submit_rules_search',@is_flat_search)%>

		}, :layout => 'content'
end

def search_rules_hierarchy
	return if authorise_for_web(program_name?,'read')== false

	@is_flat_search = false
	render_rule_search_form(true)
end

def render_rule_search_form(is_flat_search = nil)
	session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
	render :inline => %{
		<% @content_header_caption = "'search  rules'"%>

		<%= build_rule_search_form(nil,'submit_rules_search','submit_rules_search',@is_flat_search)%>

		}, :layout => 'content'
end

def submit_rules_search
	if params['page']
		session[:rules_page] =params['page']
	else
		session[:rules_page] = nil
	end
	@current_page = params['page']
	if params[:page]== nil
		 @rules = dynamic_search(params[:rule] ,'rules','Rule')
	else
		@rules = eval(session[:query])
	end
	if @rules.length == 0
		if params[:page] == nil
			flash[:notice] = 'no records were found for the query'
			@is_flat_search = session[:is_flat_search].to_s
			render_rule_search_form
		else
			flash[:notice] = 'There are no more records'
			render_list_rules
		end

	else

		render_list_rules
	end
end

 
def delete_rule
 begin
	return if authorise_for_web(program_name?,'delete')== false
	if params[:page]
		session[:rules_page] = params['page']
		render_list_rules
		return
	end
	id = params[:id]
	if id && rule = Rule.find(id)
		rule.destroy
		session[:alert] = " Record deleted."
		render_list_rules
	end
rescue handle_error('record could not be deleted')
end
end
 
def new_rule
	return if authorise_for_web(program_name?,'create')== false
		render_new_rule
end
 
def create_rule
 begin
	 @rule = Rule.new(params[:rule])
	 if @rule.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_rule
	 end
rescue
	 handle_error('record could not be created')
end
end

def render_new_rule
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new rule'"%> 

		<%= build_rule_form(@rule,'create_rule','create_rule',false,@is_create_retry)%>

		}, :layout => 'content'
end
 
def edit_rule
	return if authorise_for_web(program_name?,'edit')==false 
	 id = params[:id]
	 if id && @rule = Rule.find(id)
		render_edit_rule

	 end
end


def render_edit_rule
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit rule'"%> 

		<%= build_rule_form(@rule,'update_rule','update_rule',true)%>

		}, :layout => 'content'
end
 
def update_rule
 begin

	if params[:page]
		session[:rules_page] = params['page']
		render_list_rules
		return
	end

		@current_page = session[:rules_page]
	 id = params[:rule][:id]
	 if id && @rule = Rule.find(id)
		 if @rule.update_attributes(params[:rule])
			@rules = eval(session[:query])
			flash[:notice] = 'record saved'
			render_list_rules
	 else
			 render_edit_rule

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
 end


 def assign_org_rule
   render :inline => %{
		<% @content_header_caption = "'assign rule to organisation'"%>

		<%= build_organization_rule_form(@organization_rule,'assign','assign')%>

		}, :layout => 'content'
 end

 def assign
   begin
     #params[:organization_rule].delete(:rule_type)
	   @organization_rule = OrganizationRule.new(params[:organization_rule])

	 if @organization_rule.save
		 redirect_to_index("'rule assigned to organization successfully'","'create successful'")
	 else
		 #raise $!
     assign_org_rule
	 end

rescue
	 handle_error('record could not be created')
end
 end

 def find_assigned_rules
   render :inline => %{
		<% @content_header_caption = "'find assigned rules'"%>

		<%= find_assigned_rules_form(@organization_rule,'submit_assigned_rules_search','search')%>

		}, :layout => 'content'
 end

 def submit_assigned_rules_search
   #breakpoint
   form_params = Hash.new
   params_array = Hash.new
   params_array.store("date_from_date2from",params[:organization_rule][:date_from_date2from])
   params_array.store("date_to_date2to",params[:organization_rule][:date_to_date2to])

   organization = Organization.find_by_short_description(params[:organization_rule][:short_description])
   if organization != nil
     organization_id = organization.id
     params_array.store("organization_id",organization_id.to_s)
   end
   rule = Rule.find_by_rule_code(params[:organization_rule][:rule_code])
   if rule != nil
     rule_id = rule.id
     params_array.store("rule_id",rule_id.to_s)
   end
      
   form_params.store(:organization_rule,params_array)

   @assigned_rules = dynamic_search(form_params[:organization_rule] ,'organization_rules','OrganizationRule',nil,'organization,rule')

   if @assigned_rules.length == 0
			flash[:notice] = 'no records were found for the query'
			find_assigned_rules
	 else

		#flash[:notice] = 'WHAAAAAAATTTTTT = ' #+ form_params[:organization_rule].class.to_s
			render_list_assigned_rules
	 end
 end

 def render_list_assigned_rules
#	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	
	render :inline => %{
      <% grid            = build_assigned_rule_grid(@assigned_rules,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of rules assigned to organisation .....' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@rule_pages) if @rule_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

 def delete_assigned_rule
   begin
	   return if authorise_for_web(program_name?,'delete')== false
	id = params[:id]
	if id && organization_rule = OrganizationRule.find(id)
		organization_rule.destroy
		session[:alert] = " Record deleted."
    @assigned_rules = eval session[:query]#OrganizationRule.find(:all)
		render_list_assigned_rules
	end
 rescue
   handle_error('record could not be deleted')
 end
 end
 
 
#	-----------------------------------------------------------------------------------------------------------
#	 search combo_changed event handlers for the unique index on this table(rules)
#	-----------------------------------------------------------------------------------------------------------
 def rule_type_code_search_combo_changed
  rule_type_code = get_selected_combo_value(params)
  rule_type = RuleType.find_by_rule_type_code(rule_type_code)
  if rule_type != nil
    rule_type_id = rule_type.id
    session[:organization_rule_form][:rule_type_code_combo_selection] = rule_type_code
    @rule_codes = Rule.find_by_sql("Select distinct rule_code from rules where rule_type_id = '#{rule_type_id}'").map{|g|[g.rule_code]}
    @rule_codes.unshift("<empty>")
  else
    @rule_codes = ["Select a value from rule_type_codes"]
  end
	
#	render (inline) the html to replace the contents of the td that contains the dropdown
	render :inline => %{
		<%= select('organization_rule','rule_code',@rule_codes)%>
		<img src = '/images/spinner.gif' style = 'display:none;' id = 'img_assign_org_rule_rule_code'/>		
		}
 end


 ########################################         #############################################
 ########################################  HENRYS #############################################
 ########################################         #############################################

 def new_force_location_rule
   	return if authorise_for_web(program_name?,'create')== false
		render_new_force_location_rule
 end

 def render_new_force_location_rule

   	render :inline => %{
		<% @content_header_caption = "'create new force loaction rule'"%>

		<%= build_force_location_rule_form(@force_location_rule,'create_force_location_rule','create_force_location_rule',false,@is_create_retry)%>

		}, :layout => 'content'
 end
def list_force_location_rule
  	return if authorise_for_web(program_name?,'read') == false

 	if params[:page]!= nil

 		session[:force_loaction_rules_page] = params['page']

	render_list_force_location_rules

		 return
	else
		session[:force_loaction_rules_page] = nil
	end

	list_query = "@force_location_rule_pages = Paginator.new self, ForceLocationRule.count, @@page_size,@current_page
	 @force_location_rules = ForceLocationRule.find(:all,
				 :limit => @force_location_rule_pages.items_per_page,
				 :offset => @force_location_rule_pages.current.offset)"
	session[:query] = list_query
	render_list_force_location_rules
end

def render_list_force_location_rules
  	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@current_page = session[:force_loaction_rules_page] if session[:force_loaction_rules_page]
	@current_page = params['page'] if params['page']
	@force_location_rules =  eval(session[:query]) if !@force_location_rules
  	
	render :inline => %{
      <% grid            = build_force_location_rule_grid(@force_location_rules,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all force location  rules' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@force_location_rule_pages) if @force_location_rule_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

 def create_force_location_rule


    begin
	 @force_location_rule = ForceLocationRule.new(params[:force_location_rule])
   puts params.to_s
   puts @force_location_rule.force_from
	 if @force_location_rule.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_force_location_rule
	 end
rescue
	 handle_error('record could not be created')
end
 end

 def edit_force_location_rule
   	return if authorise_for_web(program_name?,'edit')==false
	 id = params[:id]
   @edit_force_location_rule_id = id
	 if id && @force_location_rule = ForceLocationRule.find(id)
		render_edit_force_location_rule

	 end
 end
def render_edit_force_location_rule

   	render :inline => %{
		<% @content_header_caption = "'edit  force loaction rule'"%>

		<%= build_force_location_rule_form(@force_location_rule,'update_force_location_rule','update_force_location_rule',true,true)%>

		}, :layout => 'content'
 end

def update_force_location_rule
   begin

	if params[:page]
		session[:force_loaction_rules_page] = params['page']
		list_force_location_rule
		return
	end

		@current_page = session[:force_loaction_rules_page]

 	 id = params[:force_location_rule][:id]
	 if id && @force_location_rule = ForceLocationRule.find(id)
		 if @force_location_rule.update_attributes(params[:force_location_rule])
			@force_location_rules = eval(session[:query])
			flash[:notice] = 'record updated'
			list_force_location_rule
	 else
			 render_edit_force_location_rule

		 end
	 end
rescue
	 handle_error('record could not be saved')
end
end

def delete_force_location_rule
    begin
	   return if authorise_for_web(program_name?,'delete')== false
	id = params[:id]
	if id &&  force_location_rule = ForceLocationRule.find(id)
		force_location_rule.destroy
		session[:alert] = " Record deleted."
    @force_location_rules = ForceLocationRule.find(:all)
		render_list_force_location_rules
	end
 rescue
   handle_error('record could not be deleted')
 end
end

end
