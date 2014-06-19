class  Tools::SearchEngineController < ApplicationController
 
 helper "production/reworks"
 
def program_name?
	"search_engine"
end

def bypass_generic_security?
	true
end

    def carton_search
     render :inline => %{
		<% @content_header_caption = "'search cartons'"%> 

		<%= build_carton_search_form()%>

		}, :layout => 'content'
  
  end
  
  
  def rebin_search
     render :inline => %{
		<% @content_header_caption = "'search rebins'"%> 

		<%= build_rebin_search_form()%>

		}, :layout => 'content'
  
  end
  
  
   def pallet_search
     render :inline => %{
		<% @content_header_caption = "'search pallets'"%> 

		<%= build_pallet_search_form()%>

		}, :layout => 'content'
  
  end
  
  
  def pallet_search_submit
   
   @pallets =Pallet.build_and_exec_query(params['pallet'])
   if !@pallets ||@pallets.length == 0
     redirect_to_index("No rows returned") 
     return
   end
     
   if @pallets.length == 1000
    flash[:notice]= "The resulset was limited to 1000 rows!"
   end
   
   @caption = "'pallets retuned from query'"
   
   session[:pallets_returned]= @pallets
   
    render :inline => %{
      <% grid            = build_pallets_grid(@pallets) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
   
  end

   def carton_search_submit
   
   @cartons =Carton.build_and_exec_query(params['carton'])
   if !@cartons ||@cartons.length == 0
     redirect_to_index("No rows returned") 
     return
   end
     
   if @cartons.length == 1000
    flash[:notice]= "The resulset was limited to 1000 rows!"
   end
   
   session[:cartons_returned]= @cartons
   
    render :inline => %{
      <% grid            = build_cartons_grid(@cartons) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
   
  end
  
  def selected_cartons
   put "OHJ"
  end
  
  def rebin_search_submit
   
   @rebins =Rebin.build_and_exec_query(params['rebin'])
  
   if !@rebins ||@rebins.length == 0
     redirect_to_index("No rows returned") 
     return
   end
     
   if @rebins.length == 1000
    flash[:notice]= "The resulset was limited to 1000 rows!"
   end
   
   session[:rebins_returned]= @rebins
   
    render :inline => %{
      <% grid            = build_rebins_grid(@rebins) %>
      <% grid.caption    = @caption %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
   
  end
  
  def time_search_enabled
   
   @enabled = false
   @carton = Carton.new
   if params.to_s.index("1")
     @enabled = true
   end
    
  render :inline => %{
    
     
   <script>
     img = document.getElementById('img_carton_time_search');
     if(img != null)img.style.display = 'none';
     
     <% if @enabled
         from_time_content = datetime_select('carton', 'pack_date_from')
         to_time_content = datetime_select('carton', 'pack_date_to')
        else
         from_time_content = 'disabled'
         to_time_content = 'disabled'
        end %>
        
     
     <%= update_element_function(
        "pack_date_from_cell", :action => :update,
        :content => from_time_content)%>
        
      <%= update_element_function(
        "pack_date_to_cell", :action => :update,
        :content => to_time_content)%>
        
   </script>
  }
  
  end
  
  
  def pallet_time_search_enabled
   
   @enabled = false
   @pallet = Pallet.new
   if params.to_s.index("1")
     @enabled = true
   end
    
  render :inline => %{
    
     
   <script>
     img = document.getElementById('img_pallet_pallet_time_search');
     if(img != null)img.style.display = 'none';
     
     <% if @enabled
         from_time_content = datetime_select('pallet', 'completed_date_from')
         to_time_content = datetime_select('pallet', 'completed_date_to')
        else
         from_time_content = 'disabled'
         to_time_content = 'disabled'
        end %>
        
     
     <%= update_element_function(
        "completed_date_from_cell", :action => :update,
        :content => from_time_content)%>
        
      <%= update_element_function(
        "completed_date_to_cell", :action => :update,
        :content => to_time_content)%>
        
   </script>
  }
  
  end
  
  
  def rebin_time_search_enabled
   
   @enabled = false
   @rebin = Rebin.new
   if params.to_s.index("1")
     @enabled = true
   end
    
  render :inline => %{
    
     
   <script>
     img = document.getElementById('img_rebin_rebin_time_search');
     if(img != null)img.style.display = 'none';
     
     <% if @enabled
         from_time_content = datetime_select('rebin', 'trans_date_from')
         to_time_content = datetime_select('rebin', 'trans_date_to')
        else
         from_time_content = 'disabled'
         to_time_content = 'disabled'
        end %>
        
     
     <%= update_element_function(
        "trans_date_from_cell", :action => :update,
        :content => from_time_content)%>
        
      <%= update_element_function(
        "trans_date_to_cell", :action => :update,
        :content => to_time_content)%>
        
   </script>
  }
  
  end



end
