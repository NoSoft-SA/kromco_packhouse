class Inventory::TransactionsController < ApplicationController
 
 def program_name?
    "transactions"
 end

 def bypass_generic_security?
	 true
 end

 #========================================================
 # TRANSACTION BUSINESS NAMES
 #========================================================
 def new_transaction_business_name
   return if authorise_for_web(program_name?,'create') == false
   render_new_transaction_business_name
 end

 def render_new_transaction_business_name
   render :inline => %{
		<% @content_header_caption = "'create new transaction business name'"%>

		<%= build_transaction_business_name_form(@transaction_business_name,'create_transaction_business_name','create transaction business name',false,@is_create_retry)%>

		}, :layout => 'content'
 end

 def create_transaction_business_name
#   puts "transaction_business_name_code : " + params[:transaction_business_name][:transaction_business_name_code].to_s.upcase
   begin
     business_name = params[:transaction_business_name][:transaction_business_name_code].to_s.upcase
     @transaction_business_name = TransactionBusinessName.new()
     @transaction_business_name.transaction_business_name_code = business_name
     if @transaction_business_name.save
       redirect_to_index("'transaction business name created successifully!'", "'transaction business name created'")
     else
       @is_create_retry = true
    	 render_new_transaction_business_name
     end
   rescue
     raise "transaction business name could not be created, reason : " + $!.to_s
   end
 end

 def list_transaction_business_names
   return if authorise_for_web(program_name?,'read') == false

 	if params[:page]!= nil

 		session[:transaction_business_names_page] = params['page']

		 render_list_transaction_business_name_codes

		 return
	else
		session[:transaction_business_names_page] = nil
	end

	list_query = "@transaction_business_name_pages = Paginator.new self, TransactionBusinessName.count, @@page_size,@current_page
	 @transaction_business_names = TransactionBusinessName.find(:all,
				 :limit => @transaction_business_name_pages.items_per_page,
				 :offset => @transaction_business_name_pages.current.offset)"
	session[:query] = list_query
	render_list_transaction_business_names
 end

 def render_list_transaction_business_names
   @can_edit = authorise(program_name?,'edit',session[:user_id])
  	@can_delete = authorise(program_name?,'delete',session[:user_id])
  	@current_page = session[:transaction_business_names_page] if session[:transaction_business_names_page]
  	@current_page = params['page'] if params['page']
  	@transaction_business_names =  eval(session[:query]) if !@transaction_business_names
  	
  	render :inline => %{
      <% grid            = build_transaction_business_names_grid(@transaction_business_names,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all transaction business names' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@transaction_business_name_pages) if @transaction_business_name_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
 end

 def edit_transaction_business_name
     return if authorise_for_web(program_name?,'edit')==false
     id = params['id']
     if id && @transaction_business_name = TransactionBusinessName.find(id)
        render_edit_transaction_business_name
     else

     end
  end

  def render_edit_transaction_business_name
     render :inline => %{
		<% @content_header_caption = "'edit transaction business name'"%>

		<%= build_transaction_business_name_form(@transaction_business_name,'update_transaction_business_name','update transaction business name',true,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_transaction_business_name
      begin
    	if params[:page]
    		session[:transaction_business_names_page] = params['page']
    		render_list_transaction_business_names
    		return
    	end

    		@current_page = session[:transaction_business_names_page]
    	 id = params[:transaction_business_name][:id]
    	 if id && @transaction_business_name = TransactionBusinessName.find(id)
         business_name = params[:transaction_business_name][:transaction_business_name_code].to_s.upcase
         @transaction_business_name.transaction_business_name_code = business_name
    		 if @transaction_business_name.update
    			@transaction_business_name = eval(session[:query])
    			flash[:notice] = 'transaction business name record updated!'
    			render_list_transaction_business_names
        	 else
        	     render_edit_transaction_business_name
             end
    	 end
      rescue
         handle_error("transaction business name record could not be updated")
       end
  end

  def delete_transaction_business_name
     begin
    	return if authorise_for_web(program_name?,'delete')== false
    	if params[:page]
    		session[:transaction_business_names_page] = params['page']
    		render_list_transaction_business_names
    		return
    	end
    	id = params[:id]
    	if id && transaction_business_name = TransactionBusinessName.find(id)
    		transaction_business_name.destroy
    		session[:alert] = "transaction business name record deleted."
    		render_list_transaction_business_names
    	end
      rescue
         handle_error("transaction business name record could not be deleted")
      end
  end



 #========================================================
 # TRANSACTION TYPES
 #========================================================
 def new_transaction_type
  render_new_transaction_type
 end
 
 def render_new_transaction_type
   @content_header_caption = "'create transaction types'"
   render :inline => %{ 
                      <%= build_transaction_type_form(@transaction_type,'create_transaction_type','save',false) %>
                      }, :layout => 'content'
 end
 
 def create_transaction_type
    @transaction_type = TransactionType.new(params[:transaction_type])
    
    begin
      if @transaction_type.save
        flash[:notice] = "transaction type successfully created"
        list_transaction_types
      else
        render_new_transaction_type
      end
    rescue
      flash[:notice] = "transaction type COULD NOT created"
    end
 end
 
 def list_transaction_types
   @transaction_types = TransactionType.find(:all)
      
   render_list_transaction_types
 end
 
 def render_list_transaction_types
   @can_edit = authorise(program_name?,'edit',session[:user_id])
   @can_delete = authorise(program_name?,'delete',session[:user_id])
   @content_header_caption = "'list of all outer transaction types'"
   
   render :inline => %{
      <% @child_form_caption = ["child_form3","list transaction type mmm" ]%>
      <% grid            = build_transaction_types_grid(@transaction_types,@can_edit,@can_delete) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
 end
 
 def edit_transaction_type
   @transaction_type = TransactionType.find(params[:id])
   session[:transaction_type] = @transaction_type
   @content_header_caption = "'edit transaction type'"
   
   render :template => '/inventory/transactions/edit_transaction_type.rhtml' ,:layout => 'content'
 end
 
 def update_transaction_type
    @transaction_type = session[:transaction_type]#TransactionType.find_by_transaction_type_code(params[:transaction_type][:transaction_type_code])
    @transaction_type.transaction_type_code = params[:transaction_type][:transaction_type_code]
    @transaction_type.transaction_type_description = params[:transaction_type][:transaction_type_description]
    
    begin
      @transaction_type.update
      
      flash[:notice] = "transaction type successfully updated"
      
      list_transaction_types
    rescue
    end
 end
 
 def delete_transaction_type
    @transaction_type = TransactionType.find(params[:id])
    
    begin
       @transaction_type.destroy
      
      flash[:notice] = "transaction type successfully deleted"
      
      list_transaction_types
    rescue
    end
 end
 
 def new_transaction_sub_type
    @content_header_caption = "'add a transaction sub type to transaction_type:" + session[:transaction_type].transaction_type_code + "'"
    render :inline => %{
                        <%= build_transaction_sub_type_form(@transaction_sub_type,'create_transaction_sub_type','save',nil) %>
                        },:layout => 'content'
 end
 
 def create_transaction_sub_type
   @transaction_sub_type = TransactionSubType.new
   @transaction_sub_type.transaction_sub_type_code = params[:transaction_sub_type][:transaction_sub_type_code]
   @transaction_sub_type.transaction_sub_type_description = params[:transaction_sub_type][:transaction_sub_type_description]
   @transaction_sub_type.transaction_type_id = session[:transaction_type].id
   @transaction_sub_types = session[:transaction_type].transaction_sub_types
   begin
     @transaction_sub_type.save
     
      flash[:notice] = "transaction sub type successfully created"
      
      render_list_transaction_sub_types
   rescue
      raise $!
      
      render :inline => %{
                          
                          },:layout => 'content'
   end
 end
 
 def list_transaction_sub_types
     transaction_type = TransactionType.find(params[:id])
     @transaction_sub_types = transaction_type.transaction_sub_types

   render_list_transaction_sub_types
 end
 
 def render_list_transaction_sub_types
   @can_edit = authorise(program_name?,'edit',session[:user_id])
   @can_delete = authorise(program_name?,'delete',session[:user_id])
   @content_header_caption = "'list of all transaction sub types for transaction type:" + session[:transaction_type].transaction_type_code + "'"
   
   render :inline => %{
      <% grid            = build_transaction_sub_types_grid(@transaction_sub_types,@can_edit,@can_delete) %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>
		
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
 end
 
 def delete_transaction_sub_type
    @transaction_sub_type = TransactionSubType.find(params[:id])
    @transaction_sub_types = session[:transaction_type].transaction_sub_types
    
    begin 
      @transaction_sub_type.destroy
      
      flash[:notice] = "transaction sub type successfully deleted"
      
      render_list_transaction_sub_types
    rescue
    
    end
 end
 
 def edit_transaction_sub_type
    @transaction_sub_type = TransactionSubType.find(params[:id])
    session[:transaction_sub_type] = @transaction_sub_type
    render :inline => %{
                        <%= build_transaction_sub_type_form(@transaction_sub_type,'update_transaction_sub_type','update',nil) %>
                        },:layout => 'content'
 end
 
 def update_transaction_sub_type
    @transaction_sub_type = session[:transaction_sub_type]
    @transaction_sub_type.transaction_sub_type_code = params[:transaction_sub_type][:transaction_sub_type_code]
    @transaction_sub_type.transaction_sub_type_description = params[:transaction_sub_type][:transaction_sub_type_description]
    @transaction_sub_type.transaction_type_id = session[:transaction_type].id
    @transaction_sub_types = session[:transaction_type].transaction_sub_types
    
    begin
      @transaction_sub_type.update
      flash[:notice] = "transaction sub type successfully updated"
      
      render_list_transaction_sub_types
    rescue
    end
 end
 
#-------------------------------Child Form test-----------------------------------
#  def edit_transaction_sub_type
#    @transaction_sub_type = TransactionSubType.find(params[:id])
#    session[:transaction_sub_type] = @transaction_sub_type
#    render :inline => %{
#                        <script>
#                          location.href = '/inventory/transactions/list_transaction_sub_types/5';
#                          window.parent.frames[1].location.href = '/inventory/transactions/build_subtype_child';
#                        </script>
#                        },:layout => 'content'
# end
# 
# 
# def build_subtype_child
#    
#    @transaction_sub_type = session[:transaction_sub_type]
#    render :inline => %{
#                        <%= build_transaction_sub_type_form(@transaction_sub_type,'update_transaction_sub_type','update',nil) %>
#                        },:layout => 'content'
# end
 def child_form_test
#  forecast = Forecast.find(3)
#  contr = RmtProcessing::ForecastController.new
#  @seq = contr.generate_sequence_number(forecast)
#  redirect_to :controller => 'rmt_processing/delivery' , :action => 'list_deliveries'
   @content_header_caption = "'Just testing the child_form control'"
   render :inline => %{ 
                        <%= build_child_form_test_form(@child,'child_form','child_form',nil) %>
                        },:layout => 'content'
 end
 
 def populate_top_child_form
    @transaction_types = TransactionType.find(:all)
    @child_form_caption = ["child_form2","list transaction types for child_form testing purposes!!! " ]
    
    render :inline => %{
      <% action_columns = [{:field_type => 'action',:field_name => 'view transaction types',
			:settings => 
				 {:link_text => 'view',
				:target_action => 'view_transaction_types',
				:id_column => 'id'}}]
       column_configs = gen_grid_column_configs(@transaction_types[0],action_columns,nil,nil)
    %>
      <% grid            = get_data_grid(@transaction_types,column_configs)  %>
      <% grid.caption    = '' %>
      <% @header_content = grid.build_grid_data %>
    
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
    
 end
 
 def view_transaction_types

    render :inline => %{
                        <script>
                        //alert(window.parent.frames[1]);
                          location.href = '/inventory/transactions/populate_top_child_form' ;
                          window.parent.frames[1].location.href = '/inventory/transactions/build_subtype_child/' + <%= params[:id].to_s %>;
                        </script>
                        },:layout => 'content'
 end
 
 
 def build_subtype_child
    @child_form_caption = ["child_form","view transaction type in edit mode for child_form testing purposes!!! " ]
    @transaction_type = TransactionType.find(params[:id])#session[:transaction_type]#
    render :inline => %{
                        <%= build_transaction_type_form(@transaction_type,'create_transaction_type','save',nil) %>
                        },:layout => 'content'
 end
#-----------------------------------------------------------------------------------
 
end
