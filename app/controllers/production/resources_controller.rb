class  Production::ResourcesController < ApplicationController

def program_name?
	"resources"
end

def bypass_generic_security?
	true
end

#===========================================================
#PALLET LABEL STATION CODE
#===========================================================
def list_pallet_label_stations
	return if authorise_for_web(program_name?,'read') == false

	list_query = "@pallet_label_stations = PalletLabelStation.find(:all)"
	session[:query] = list_query
	render_list_pallet_label_stations
end


def render_list_pallet_label_stations
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@pallet_label_stations =  eval(session[:query]) if !@pallet_label_stations
	render :inline => %{
      <% grid            = build_pallet_label_station_grid(@pallet_label_stations,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all pallet_label_stations' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def delete_pallet_label_station
  return if authorise_for_web(program_name?,'delete')== false
  begin
	id = params[:id]
	if id && pallet_label_station = PalletLabelStation.find(id)
		pallet_label_station.destroy
		session[:alert] = " Record deleted."
		render_list_pallet_label_stations
	end
  rescue
   handle_error("pallet label station could not be deleted")
  end
end

def new_pallet_label_station
	return if authorise_for_web(program_name?,'create')== false
		render_new_pallet_label_station
end

def create_pallet_label_station
   begin
	 @pallet_label_station = PalletLabelStation.new(params[:pallet_label_station])
	 if @pallet_label_station.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_pallet_label_station
	 end
	rescue
	 handle_error("pallet label station could not be created")
	end
end

def render_new_pallet_label_station
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new pallet_label_station'"%>

		<%= build_pallet_label_station_form(@pallet_label_station,'create_pallet_label_station','create_pallet_label_station',false,@is_create_retry)%>

		}, :layout => 'content'
end

def edit_pallet_label_station
	return if authorise_for_web(program_name?,'edit')==false
	 id = params[:id]
	 if id && @pallet_label_station = PalletLabelStation.find(id)
		render_edit_pallet_label_station

	 end
end


def render_edit_pallet_label_station
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit pallet_label_station'"%>

		<%= build_pallet_label_station_form(@pallet_label_station,'update_pallet_label_station','update_pallet_label_station',true)%>

		}, :layout => 'content'
end

def update_pallet_label_station

	 id = params[:pallet_label_station][:id]
	 if id && @pallet_label_station = PalletLabelStation.find(id)
		 if @pallet_label_station.update_attributes(params[:pallet_label_station])
			@pallet_label_stations = eval(session[:query])
			render_list_pallet_label_stations
	 else
			 render_edit_pallet_label_station

		 end
	 end
 end

#=============================================================
#REBIN LABEL STATION CODE
#=============================================================
def list_rebin_label_stations
	return if authorise_for_web(program_name?,'read') == false

	list_query = "@rebin_label_stations = RebinLabelStation.find(:all)"
	session[:query] = list_query
	render_list_rebin_label_stations
end


def render_list_rebin_label_stations
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])

	@rebin_label_stations =  eval(session[:query]) if !@rebin_label_stations
	render :inline => %{
      <% grid            = build_rebin_label_station_grid(@rebin_label_stations,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all rebin_label_stations' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def delete_rebin_label_station
	return if authorise_for_web(program_name?,'delete')== false

	id = params[:id]
	if id && rebin_label_station = RebinLabelStation.find(id)
		rebin_label_station.destroy
		session[:alert] = " Record deleted."
		render_list_rebin_label_stations
	end
end

def new_rebin_label_station
	return if authorise_for_web(program_name?,'create')== false
		render_new_rebin_label_station
end

def create_rebin_label_station
   begin
	 @rebin_label_station = RebinLabelStation.new(params[:rebin_label_station])
	 if @rebin_label_station.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_rebin_label_station
	 end
   rescue
     handle_error("rebin label station could not be created")
   end
end

def render_new_rebin_label_station
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new rebin_label_station'"%>

		<%= build_rebin_label_station_form(@rebin_label_station,'create_rebin_label_station','create_rebin_label_station',false,@is_create_retry)%>

		}, :layout => 'content'
end

def edit_rebin_label_station
	return if authorise_for_web(program_name?,'edit')==false
	 id = params[:id]
	 if id && @rebin_label_station = RebinLabelStation.find(id)
		render_edit_rebin_label_station

	 end
end


def render_edit_rebin_label_station
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit rebin_label_station'"%>

		<%= build_rebin_label_station_form(@rebin_label_station,'update_rebin_label_station','update_rebin_label_station',true)%>

		}, :layout => 'content'
end

def update_rebin_label_station

	 id = params[:rebin_label_station][:id]
	 if id && @rebin_label_station = RebinLabelStation.find(id)
		 if @rebin_label_station.update_attributes(params[:rebin_label_station])
			@rebin_label_stations = eval(session[:query])
			render_list_rebin_label_stations
	 else
			 render_edit_rebin_label_station

		 end
	 end
 end


#===============================================================
#CARTON LABEL STATIONS CODE
#===============================================================
 def remove_carton_label_station
  begin
   id = params[:id]
   carton_label_station = CartonLabelStation.find(id)
    if session[:current_line_config].carton_label_stations.delete(carton_label_station)

     flash[:notice]= "carton_label_station removed from line config"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>

     },:layout => "tree_node_content"

    end

  rescue
   handle_error("carton_label_station could not be removed from line config")
  end
 end


def add_carton_label_station
  begin

    if request.get?

      render :inline => %{
       <% @tree_node_content_header = "Add carton label station" -%>
      <% @hide_content_pane = false %>
      <% @is_menu_loaded_view = true %>
      <%= build_add_carton_label_station_form("add_carton_label_station","add") %>

      },:layout => "tree_node_content"
    else

      id = params[:carton_label_station][:carton_label_station_code].to_i
      @carton_label_station = CartonLabelStation.find(id)
      #add bintip station to current line config
      if session[:current_line_config].carton_label_stations.push(@carton_label_station)

      #@node_name,@node_type,@node_id,@tree_name
       @parent_id = "carton_label_stations!root"
       @node_name = @carton_label_station.carton_label_station_code
       @node_type = "carton_label_station"
       @node_id = @carton_label_station.id.to_s
       @tree_name = "line_config"
        flash[:notice] = "carton label station added"
        render :inline => %{
          <% @is_menu_loaded_view = false %>
          <% @hide_content_pane = true %>
          <% tree_code = render_add_node_to_parent_js(@parent_id,@node_name,@node_type,@node_id,@tree_name) %>
          <% @tree_actions = tree_code %>
        },:layout => "tree_node_content"

    else
      raise @carton_label_station.errors.full_messages.to_s
    end
    end
    rescue
     handle_error("carton label station could not be added to line config",true)
    end


end
def list_carton_label_stations
	return if authorise_for_web(program_name?,'read') == false

	list_query = "@carton_label_stations = CartonLabelStation.find(:all)"
	session[:query] = list_query
	render_list_carton_label_stations
end


def render_list_carton_label_stations
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])

	@carton_label_stations =  eval(session[:query]) if !@carton_label_stations
	render :inline => %{
      <% grid            = build_carton_label_station_grid(@carton_label_stations,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all carton_label_stations' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def delete_carton_label_station
  return if authorise_for_web(program_name?,'delete')== false
  begin

	id = params[:id]
	if id && carton_label_station = CartonLabelStation.find(id)
		carton_label_station.destroy
		session[:alert] = " Record deleted."
		render_list_carton_label_stations
	end
  rescue
    handle_error("carton label station could not be deleted")
  end
end

def new_carton_label_station
	return if authorise_for_web(program_name?,'create')== false
		render_new_carton_label_station
end

def create_carton_label_station
   begin
	 @carton_label_station = CartonLabelStation.new(params[:carton_label_station])
	 if @carton_label_station.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_carton_label_station
	 end
   rescue
     handle_error("carton label station could not be created")
   end
end

def render_new_carton_label_station
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new carton_label_station'"%>

		<%= build_carton_label_station_form(@carton_label_station,'create_carton_label_station','create_carton_label_station',false,@is_create_retry)%>

		}, :layout => 'content'
end

def edit_carton_label_station
	return if authorise_for_web(program_name?,'edit')==false
	 id = params[:id]
	 if id && @carton_label_station = CartonLabelStation.find(id)
		render_edit_carton_label_station

	 end
end


def render_edit_carton_label_station
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit carton_label_station'"%>

		<%= build_carton_label_station_form(@carton_label_station,'update_carton_label_station','update_carton_label_station',true)%>

		}, :layout => 'content'
end

def update_carton_label_station

	 id = params[:carton_label_station][:id]
	 if id && @carton_label_station = CartonLabelStation.find(id)
		 if @carton_label_station.update_attributes(params[:carton_label_station])
			@carton_label_stations = eval(session[:query])
			render_list_carton_label_stations
	 else
			 render_edit_carton_label_station

		 end
	 end
 end


#==========================================================================
#BIN TIP STATIONS CODE
#==========================================================================
def list_bintip_stations
	return if authorise_for_web(program_name?,'read') == false

	list_query = "@bintip_stations = BintipStation.find(:all)"
	session[:query] = list_query
	render_list_bintip_stations
end


def render_list_bintip_stations
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])

	@bintip_stations =  eval(session[:query]) if !@bintip_stations
	render :inline => %{
      <% grid            = build_bintip_station_grid(@bintip_stations,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all bintip_stations' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def delete_bintip_station
 return if authorise_for_web(program_name?,'delete')== false
 begin

	id = params[:id]
	if id && bintip_station = BintipStation.find(id)
		bintip_station.destroy
		session[:alert] = " Record deleted."
		render_list_bintip_stations
	end
  rescue
    handle_error("bintip station could not be deleted")
  end
end


 def remove_bintip_station
  begin
   id = params[:id]
   bintip_station = BintipStation.find(id)
    if session[:current_line_config].bintip_stations.delete(bintip_station)

     flash[:notice]= "bintip station removed from line config"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>

     },:layout => "tree_node_content"

    end

  rescue
   handle_error("bintip station could not be removed from line config")
  end
 end


def add_bintip_station
  begin

    if request.get?

      render :inline => %{
       <% @tree_node_content_header = "Add bintip station" -%>
      <% @hide_content_pane = false %>
      <% @is_menu_loaded_view = true %>
      <%= build_add_bintip_station_form("add_bintip_station","add") %>

      },:layout => "tree_node_content"
    else

      id = params[:bintip_station][:bintip_station_code].to_i

      @bintip_station = BintipStation.find(id)

      if session[:current_line_config].bintip_stations.find(:first,:conditions => "bintip_station_code = '#{@bintip_station.bintip_station_code}'")
       flash[:notice]= "You have already added bintip station '#{@bintip_station.bintip_station_code}'"
        render :inline => %{
          <% @is_menu_loaded_view = false %>
          <% @hide_content_pane = true %>
        },:layout => "tree_node_content"
        return
      end

      #add bintip station to current line config
      if session[:current_line_config].bintip_stations.push(@bintip_station)

      #@node_name,@node_type,@node_id,@tree_name
       @parent_id = "bintip_stations!root"
       @node_name = @bintip_station.bintip_station_code
       @node_type = "bintip_station"
       @node_id = @bintip_station.id.to_s
       @tree_name = "line_config"
        flash[:notice] = "bintip station added"
        render :inline => %{
          <% @is_menu_loaded_view = false %>
          <% @hide_content_pane = true %>
          <% tree_code = render_add_node_to_parent_js(@parent_id,@node_name,@node_type,@node_id,@tree_name) %>
          <% @tree_actions = tree_code %>
        },:layout => "tree_node_content"

    else
      raise @bintip_station.errors.full_messages.to_s
    end
    end
    rescue
     handle_error("bintip station could not be added to line config",true)
    end


end


def new_bintip_station
	return if authorise_for_web(program_name?,'create')== false
		render_new_bintip_station
end

def create_bintip_station
  begin
	 @bintip_station = BintipStation.new(params[:bintip_station])
	 if @bintip_station.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_bintip_station
	 end
  rescue
    handle_error("bintip_station could not be created")
  end
end

def render_new_bintip_station
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new bintip_station'"%>

		<%= build_bintip_station_form(@bintip_station,'create_bintip_station','create_bintip_station',false,@is_create_retry)%>

		}, :layout => 'content'
end

def edit_bintip_station
	return if authorise_for_web(program_name?,'edit')==false
	 id = params[:id]
	 if id && @bintip_station = BintipStation.find(id)
		render_edit_bintip_station

	 end
end


def render_edit_bintip_station
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit bintip_station'"%>

		<%= build_bintip_station_form(@bintip_station,'update_bintip_station','update_bintip_station',true)%>

		}, :layout => 'content'
end

def update_bintip_station

	 id = params[:bintip_station][:id]
	 if id && @bintip_station = BintipStation.find(id)
		 if @bintip_station.update_attributes(params[:bintip_station])
			@bintip_stations = eval(session[:query])
			render_list_bintip_stations
	 else
			 render_edit_bintip_station

		 end
	 end
 end

#===========================
#Binfill sort stations code
#===========================
def add_binfill_sort_station
   begin

      @sort_station = BinfillSortStation.new
      code = BinfillSortStation.next_id(session[:current_line_config].id)
      @sort_station.gen_station_code = code
      @sort_station.binfill_sort_station_code =  "x" + code.to_s

      if session[:current_line_config].binfill_sort_stations.push(@sort_station)

       @node_name = "x" + code.to_s
       @node_type = "binfill_sort_station"
       @node_id = @sort_station.id.to_s
       @parent_node_id = "binfill_sort_stations!root"
       @tree_name = "line_config"
        flash[:notice] = "binfill sort station added"
        render :inline => %{
          <% @is_menu_loaded_view = true %>
          <% @hide_content_pane = true %>
          <% tree_code = render_add_node_to_parent_js(@parent_node_id,@node_name,@node_type,@node_id,@tree_name) %>
          <% @tree_actions = tree_code %>
        },:layout => "tree_node_content"

    else
      raise @sort_station.errors.full_messages.to_s
    end
    rescue
     handle_error("binfill sort station could not be added to line",true)
    end

end

def remove_binfill_sort_station
  begin
   id = params[:id]
   sort_station = BinfillSortStation.find(id)
    if session[:current_line_config].binfill_sort_stations.delete(sort_station)

     flash[:notice]= "binfill sort station removed from line config"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>

     },:layout => "tree_node_content"

    end

  rescue
   handle_error("binfill sort station could not be removed from line config")
  end

end




def add_drop_front
  add_drop("FRONT")
end

def add_drop_back
  add_drop("BACK")
end


#===========================================================================
#BINFILL STATION CODE
#===========================================================================
def add_binfill_station


  #-----------------------------------------------------------------------
  #Binfill station numbering for KROMCO:
  # every binfill station has an 'invisible' table- which numbers 'on' from the
  # last table - whether  a binfill table or a pack table. This means the last
  # part of barcode will always be '1a'
  #-----------------------------------------------------------------------
  begin

      drop = Drop.find(params[:id].to_i)
      @binfill_station = BinfillStation.new
      code = BinfillStation.next_id(drop.id)

      current_drop = Drop.next_id(session[:current_line_config].id)-1
      next_global_table = Table.next_global_id(session[:current_line_config].id)
      puts "next_global_table: " + next_global_table.to_s
      puts "current_drop: " + current_drop.to_s
      next_binfill_id = BinfillStation.next_id(session[:current_line_config].id)

      next_global_table = current_drop if next_global_table < current_drop
      next_global_table = next_binfill_id if next_binfill_id > next_global_table

      global_code = next_global_table

       char = "0"
       char = "" if global_code > 9

      if BinfillStation.is_alpha_numeric
        barcode = "x" + char + (global_code).to_s + "1A"
      else
        barcode = "x" + char + (global_code).to_s
      end

      location = "x" + drop.drop_code.to_s

      @binfill_station.station_gen_code = global_code
      @binfill_station.location = location

      @binfill_station.binfill_station_code = barcode


      if drop.binfill_stations.push(@binfill_station)


       @node_name = @binfill_station.binfill_station_code.to_s
       @node_type = "binfill_station"
       @node_id = drop.id.to_s + "$" + @binfill_station.id.to_s
       @tree_name = "line_config"
        flash[:notice] = "binfill station added"
        render :inline => %{
          <% @is_menu_loaded_view = true %>
          <% @hide_content_pane = true %>
          <% tree_code = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>
          <% @tree_actions = tree_code %>
        },:layout => "tree_node_content"

    else
     raise @binfill_station.errors.full_messages.to_s
    end
    rescue
     handle_error("binfill station could not be added to drop",true)
    end
end

def remove_binfill_station

 begin

   ids = params[:id].split("$")
   id = ids[1].to_i
   parent_id = ids[0].to_i

   binfill_station = BinfillStation.find(id)
   drop = Drop.find(parent_id)
    if drop.binfill_stations.delete(binfill_station)

     flash[:notice]= "binfill station removed from drop"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>

     },:layout => "tree_node_content"

    end

  rescue
   handle_error("binfill station could not be removed from drop")
  end


end

#=========================================================================
#SKIP CODE
#=========================================================================

def list_skips
	return if authorise_for_web(program_name?,'read') == false


	list_query = "@skips = Skip.find(:all)"
	session[:query] = list_query
	render_list_skips
end


def render_list_skips
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])

	@skips =  eval(session[:query]) if !@skips
	render :inline => %{
      <% grid            = build_skip_grid(@skips,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all skips' %>
      <% @header_content = grid.build_grid_data %>

      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def delete_skip
  return if authorise_for_web(program_name?,'delete')== false
  begin
	if params[:page]
		session[:skips_page] = params['page']
		render_list_skips
		return
	end
	id = params[:id]
	if id && skip = Skip.find(id)
		skip.destroy
		session[:alert] = " Record deleted."
		render_list_skips
	end
  rescue
    handle_error("skip could not be deleted")
  end
end

def new_skip
	return if authorise_for_web(program_name?,'create')== false
		render_new_skip
end

def create_skip
	 @skip = Skip.new(params[:skip])
	 if @skip.save

		 redirect_to_index("'new record created successfully'","'create successful'")
	else
		@is_create_retry = true
		render_new_skip
	 end
end

def render_new_skip
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new skip'"%>

		<%= build_skip_form(@skip,'create_skip','create_skip',false,@is_create_retry)%>

		}, :layout => 'content'
end

def edit_skip
	return if authorise_for_web(program_name?,'edit')==false
	 id = params[:id]
	 if id && @skip = Skip.find(id)
		render_edit_skip

	 end
end


def render_edit_skip
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit skip'"%>

		<%= build_skip_form(@skip,'update_skip','update_skip',true)%>

		}, :layout => 'content'
end

def update_skip

	 id = params[:skip][:id]
	 if id && @skip = Skip.find(id)
		 if @skip.update_attributes(params[:skip])
			@skips = eval(session[:query])
			render_list_skips
	 else
			 render_edit_skip

		 end
	 end
 end

 def add_skip
  begin

    if request.get?

      render :inline => %{
       <% @tree_node_content_header = "Add skip" -%>
      <% @hide_content_pane = false %>
      <% @is_menu_loaded_view = true %>
      <%= build_add_skip_form("add_skip","add") %>

      },:layout => "tree_node_content"
    else

      id = params[:skip][:skip_code].to_i
      @skip = Skip.find(id)

      if session[:current_line_config].skips.find(:first,:conditions => "skip_code = '#{@skip.skip_code}'")
       flash[:notice]= "You have already added skip '#{@skip.skip_code}'"
        render :inline => %{
          <% @is_menu_loaded_view = false %>
          <% @hide_content_pane = true %>
        },:layout => "tree_node_content"
        return
      end
      #add bintip station to current line config
      session[:current_line_config].skips.push(@skip)

      #@node_name,@node_type,@node_id,@tree_name
       @parent_id = "skips!root"
       @node_name = @skip.skip_code
       @node_type = "skip"
       @node_id = @skip.id.to_s
       @tree_name = "line_config"
        flash[:notice] = "skip added"
        render :inline => %{
          <% @is_menu_loaded_view = false %>
          <% @hide_content_pane = true %>
          <% tree_code = render_add_node_to_parent_js(@parent_id,@node_name,@node_type,@node_id,@tree_name) %>
          <% @tree_actions = tree_code %>
        },:layout => "tree_node_content"

    end
    rescue
     handle_error("bintip station could not be added to line config",true)
    end


end

 def remove_skip
  begin
   id = params[:id]
   skip = Skip.find(id)
    if session[:current_line_config].skips.delete(skip)

     flash[:notice]= "skip removed from line config"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>

     },:layout => "tree_node_content"

    end

  rescue
   handle_error("skip could not be removed from line config")
  end
 end

#=======================================================================
#SUBLINES CODE
#=======================================================================

def show_subline_config
 subline = Subline.find(params[:id].to_i)
 config = subline.line_config.line_config_code
  @freeze_flash = true
  flash[:notice]= "subline '" + subline.subline_code + "' is based on line config: <font color = blue><strong> " + config + "</strong> </font>"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>

     },:layout => "tree_node_content"
end

def remove_subline
begin
   id = params[:id]
   subline = Subline.find(id)
    if session[:current_line_config].sublines.delete(subline)

     flash[:notice]= "subline removed from line config"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>

     },:layout => "tree_node_content"

    end

  rescue
   handle_error("subline could not be removed from line config")
  end

end


def add_subline
 begin

    if request.get?

      render :inline => %{
       <% @tree_node_content_header = "Add subline" -%>
      <% @hide_content_pane = false %>
      <% @is_menu_loaded_view = true %>
      <%= build_subline_form("add_subline","add") %>

      },:layout => "tree_node_content"
    else

      subline = Subline.new
      subline.subline_code = params[:subline][:subline_code]
      subline.subline_description = params[:subline][:subline_description]
      session[:current_line_config].sublines.push(subline)

      #@node_name,@node_type,@node_id,@tree_name
       @parent_id = "sublines!root"
       @node_name = subline.subline_code
       @node_type = "subline"
       @node_id = subline.id.to_s
       @tree_name = "line_config"
        flash[:notice] = "skip added"
        render :inline => %{
          <% @is_menu_loaded_view = false %>
          <% @hide_content_pane = true %>
          <% tree_code = render_add_node_to_parent_js(@parent_id,@node_name,@node_type,@node_id,@tree_name) %>
          <% @tree_actions = tree_code %>
        },:layout => "tree_node_content"

    end
    rescue
     handle_error("bintip station could not be added to line config",true)
    end

end


#=====================================================================
#CARTON DROP CODE
#=====================================================================

def remove_drop
begin
   id = params[:id]
   drop = Drop.find(id)
    if session[:current_line_config].drops.delete(drop)

     flash[:notice]= "drop removed from line config"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>

     },:layout => "tree_node_content"

    end

  rescue
   handle_error("drop could not be removed from line config")
  end

end


#--------------------------------------------------------------------------
#Editing a carton drop will affect the station codes, so, in this case, we
#will rebuild the entire tree, since the tree's API doesn't support live
#updates of multiple nodes in a single call
#--------------------------------------------------------------------------
#def edit_carton_drop
#   begin
#      id = params[:id].to_i
#      drop = CartonDrop.find(id)
#      session[:current_carton_drop] = drop
#      @carton_drop = drop.carton_drop_code.to_s
#     render :inline => %{
#     <script>
#     val = prompt("edit carton drop code: <%= @carton_drop %>. \\n This will change the station codes belonging to it \\n The tree will be rebuild to accommodate the changes to it's structure");
#     window.location.href = "/production/resources/carton_drop_edited/" + val;
#     </script>
#     }
#
#    rescue
#     handle_error("carton drop edit failed",true)
#    end
#
#
#end
#
#def carton_drop_edited
#  begin
#  if params[:id].to_s != "null" #'id', in this case, is the value set by user in the javascript prompt
#
#    session[:current_carton_drop].carton_drop_code = params[:id]
#    ActiveRecord::Base.transaction do
#    session[:current_carton_drop].save
#    drop = session[:current_carton_drop]
#    #-----------------------------------------------------------------------------
#    #now update all the stations belonging to tables of this drop- for each table:
#    #for each station: recreate: 1) location and 2) station code
#    #-----------------------------------------------------------------------------
#
#    drop.tables.each do |table|
#      table.carton_pack_stations.each do |station|
#        old_station_code = station.station_code
#        old_location_code = station.location
#        station.location = "x" + drop.carton_drop_code.to_s + table.table_code.to_s
#        #work out the station part of the station code: this is the entire code minus the location part
#
#        station_only_code = old_station_code.slice(old_location_code.length()..old_station_code.length())
#        station.station_code = station.location + station_only_code
#        station.save
#     end
#    end
#    end
#    flash[:notice]= "carton drop code changed"
#    session[:changed_line_config_id]= session[:current_line_config].id
#    #normal 'redirect_to' method doesn't work here, because we're calling it from the inner frame
#    #we have to explicitly 'say' from which frame the url should be called- javascript is the only way
#    render :inline => %{
#
#        <script> window.parent.location.href = "/production/resources/edit_line_config"; </script>
#
#      },:layout => "tree_node_content"
#
#  else
#       render :inline => %{
#
#        <%@hide_content_pane = true %>
#        <% @is_menu_loaded_view = true %>
#
#
#      },:layout => "tree_node_content"
#
#  end
#
# rescue
#  handle_error("carton drop could not be updated")
# ensure
#  session[:current_carton_drop]= nil
# end
#
#end

 def add_drop_A
  add_drop("A")

 end

 def add_drop_B
  add_drop("B")

 end

def add_drop(side)

  begin

      @drop = Drop.new
      next_id = Drop.next_id(session[:current_line_config].id)

      code = next_id
      @drop.drop_code = code
      #hans revisist
      @drop.drop_side_code = side
      if session[:current_line_config].drops.push(@drop)

       @node_name = "drop_" + @drop.drop_code.to_s + ":" + side
       @node_type = "drop"
       @node_id = @drop.id.to_s
       @parent_node_id = "drops!root"
       @tree_name = "line_config"
        flash[:notice] = "drop added"
        render :inline => %{
          <% @is_menu_loaded_view = true %>
          <% @hide_content_pane = true %>
          <% tree_code = render_add_node_to_parent_js(@parent_node_id,@node_name,@node_type,@node_id,@tree_name) %>
          <% @tree_actions = tree_code %>
        },:layout => "tree_node_content"

    else
      raise @drop.errors.full_messages.to_s
    end
    rescue
     handle_error("carton drop could not be added to line",true)
    end
end

#============================================================
#TABLES CODE
#============================================================

def add_table

  begin

      drop = Drop.find(params[:id].to_i)
      @table = Table.new
      current_drop = Drop.next_id(session[:current_line_config].id)-1 #current largest drop id
      #-------------------------------------------------------------------------
      #Next global table means: next global table num (meaning across all tables)
      #                         that is unique. First see if the
      #-------------------------------------------------------------------------
      next_global_table = Table.next_global_id(session[:current_line_config].id)
      puts "next_global_table: " + next_global_table.to_s
      puts "current_drop: " + current_drop.to_s

      next_global_table = current_drop if next_global_table < current_drop
      next_drop_table = Table.next_id(drop.id)
      next_binfill_table_id = BinfillStation.next_id(session[:current_line_config].id)
      puts "binfill table: " + next_binfill_table_id.to_s
      next_global_table = next_binfill_table_id if next_binfill_table_id > next_global_table

      caption = ""
      if Table.number_across_drops?
        caption = next_global_table.to_s

      else
        caption = next_drop_table.to_s
      end

      code = next_drop_table
      @table.table_code = code
      @table.table_caption = caption
      drop.tables.push(@table)

       @node_name = "T" + @table.table_code.to_s + "(table_" + caption + ")"
       @node_type = "table"
       @node_id = drop.id.to_s + "$" + @table.id.to_s
       @tree_name = "line_config"
        flash[:notice] = "table added"
        render :inline => %{
          <% @is_menu_loaded_view = true %>
          <% @hide_content_pane = true %>
          <% tree_code = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>
          <% @tree_actions = tree_code %>
        },:layout => "tree_node_content"


    rescue
     handle_error("table could not be added to drop",true)
    end
end

def remove_table
begin
   ids = params[:id].split("$")
   id = ids[1]
   parent_id = ids[0]
   table = Table.find(id)
   drop = Drop.find(parent_id)

    if drop.tables.delete(table)

     flash[:notice]= "table removed from drop"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>

     },:layout => "tree_node_content"

    end

  rescue
   handle_error("table could not be removed from line config")
  end

end

#========================================================================
#PACK STATION CODE
#========================================================================

def barcode_edited
 begin
  if params[:id].to_s != "null"

    session[:current_station].station_code = 'x' + params[:id] #session[:current_station].location + params[:id]

    #----------------------------------------------
    #Make sure barcode is unique within line config
    #----------------------------------------------

    if CartonPackStation.exists_for_line_config(session[:current_line_config].id,session[:current_station].station_code)||BinfillStation.exists_for_line_config(session[:current_line_config].id,session[:current_station].station_code)

     flash[:notice]= "You already have a barcode with station code: " +  session[:current_station].station_code
     @freeze_flash = true
        render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>

      },:layout => "tree_node_content"
      session[:current_station] = nil
      return
    end

    session[:current_station].save
    flash[:notice]= "barcode updated"
    @new_text = session[:current_station].station_code
      render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>
        <% @tree_actions = render_edit_node_js(@new_text) %>


      },:layout => "tree_node_content"

  else
       render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>


      },:layout => "tree_node_content"

  end

 rescue
  handle_error("barcode could not be updated")
 ensure
  session[:current_station]= nil
 end

end

def edit_binfill_barcode
   begin
      id = params[:id].split("$")[1].to_i
      station = BinfillStation.find(id)
      session[:current_binfill_station] = station
      @barcode = station.binfill_station_code
     render :inline => %{
     <script>
     val = prompt("edit barcode: <%= @barcode %>. IGNORE THE 'x'(do not enter it)");
     window.location.href = "/production/resources/binfill_barcode_edited/" + val;
     </script>
     }

    rescue
     handle_error("barcode edit failed",true)
    end

end


def binfill_barcode_edited
 begin
  if params[:id].to_s != "null"

    session[:current_binfill_station].binfill_station_code = 'x' + params[:id] #session[:current_station].location + params[:id]
    #extract and update the 'station_gen_code' part
    station_gen_code = params[:id].slice(0..1).to_i
    session[:current_binfill_station].station_gen_code = station_gen_code
    #----------------------------------------------
    #Make sure barcode is unique within line config
    #----------------------------------------------

    if BinfillStation.exists_for_line_config( session[:current_line_config].id,session[:current_binfill_station].binfill_station_code)||CartonPackStation.exists_for_line_config( session[:current_line_config].id,session[:current_binfill_station].binfill_station_code)

     flash[:notice]= "You already have a barcode with station code: " +  session[:current_binfill_station].binfill_station_code
     @freeze_flash = true
        render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>

      },:layout => "tree_node_content"
      session[:current_binfill_station] = nil
      return
    end

    session[:current_binfill_station].save
    flash[:notice]= "barcode updated"
    @new_text = session[:current_binfill_station].binfill_station_code
      render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>
        <% @tree_actions = render_edit_node_js(@new_text) %>


      },:layout => "tree_node_content"

  else
       render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>


      },:layout => "tree_node_content"

  end

 rescue
  handle_error("barcode could not be updated")
 ensure
  session[:current_binfill_station]= nil
 end

end

#---------------------
#BINFILL SORT STATION
#--------------------
def edit_binfill_sort_station_barcode
   begin
      id = params[:id].to_i
      station = BinfillSortStation.find(id)
      session[:current_binfill_sort_station] = station
      @barcode = station.binfill_sort_station_code
     render :inline => %{
     <script>
     val = prompt("edit barcode: <%= @barcode %>. IGNORE THE 'x'(do not enter it)");
     window.location.href = "/production/resources/binfill_sort_station_barcode_edited/" + val;
     </script>
     }

    rescue
     handle_error("barcode edit failed",true)
    end

end

def binfill_sort_station_barcode_edited
 begin
  if params[:id].to_s != "null"

    session[:current_binfill_sort_station].binfill_sort_station_code = 'x' + params[:id] #session[:current_station].location + params[:id]

    #----------------------------------------------
    #Make sure barcode is unique within line config
    #----------------------------------------------

    if BinfillSortStation.exists_for_line_config( session[:current_line_config].id,session[:current_binfill_sort_station].binfill_sort_station_code)

     flash[:notice]= "You already have a barcode with station code: " +  session[:current_binfill_sort_station].binfill_sort_station_code
     @freeze_flash = true
        render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>

      },:layout => "tree_node_content"
      session[:current_binfill_sort_station] = nil
      return
    end

    session[:current_binfill_sort_station].save
    flash[:notice]= "barcode updated"
    @new_text = session[:current_binfill_sort_station].binfill_sort_station_code
      render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>
        <% @tree_actions = render_edit_node_js(@new_text) %>


      },:layout => "tree_node_content"

  else
       render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>


      },:layout => "tree_node_content"

  end

 rescue
  handle_error("barcode could not be updated")
 ensure
  session[:current_binfill_sort_station]= nil
 end

end

 def table_edited

  begin

    uval = params[:id].to_s

    if uval != "null"

     vals = params[:id].split(":")
     if  vals.length() != 2 || vals[0].to_i == 0 ||vals[1].to_i == 0
      flash[:notice]= "You must enter 2 numbers separated by a ':'. First number is table_position on drop. Second is global table number on line"
     @freeze_flash = true
        render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>

      },:layout => "tree_node_content"
      session[:current_drop] = nil
      return

    end


    table_caption = vals[1].to_i
    table_pos = vals[0].to_i


    #----------------------------------------------
    #Make sure drop is unique within line config
    #----------------------------------------------

    if Table.exists_for_line_config(session[:current_line_config].id,table_caption)

     flash[:notice]= "You already have a table : " + table_caption.to_s
     @freeze_flash = true
        render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>

      },:layout => "tree_node_content"
      session[:current_table] = nil
      return
    end

    session[:current_table].table_caption = table_caption
    session[:current_table].table_code = vals[0].to_i
    session[:current_table].save
    flash[:notice]= "table updated"
    @new_text = "T" + vals[0].to_s.upcase + "(table_" + vals[1].to_s + ")"
      render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>
        <% @tree_actions = render_edit_node_js(@new_text) %>


      },:layout => "tree_node_content"

  else
       render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>


      },:layout => "tree_node_content"

  end

 rescue
  handle_error("drop could not be updated")
 ensure
  session[:current_table]= nil
 end

end



def edit_table
   begin

      id = params[:id].split("$")[1].to_i

      @table = Table.find(id)

      session[:current_table] = @table


     render :inline => %{
     <script>
     val = prompt("edit table: <%= @table.table_code.to_s %>:<%= @table.table_caption.to_s %> (format is: <position>:<global_number>)");
     window.location.href = "/production/resources/table_edited/" + val;
     </script>
     }

    rescue
     handle_error("table edit failed",true)
    end

 end

 def edit_drop
   begin

      id = params[:id].to_i
      puts params[:id]
      drop = Drop.find(id)

      session[:current_drop] = drop
      @drop = drop.drop_code.to_s + ":" + drop.drop_side_code

      puts @drop
     render :inline => %{
     <script>
     val = prompt("edit drop: <%= @drop %>");
     window.location.href = "/production/resources/drop_edited/" + val;
     </script>
     }

    rescue
     handle_error("barcode edit failed",true)
    end

 end

 def drop_edited

  begin

    uval = params[:id].to_s

    if uval != "null"

     last_char = uval.slice(uval.length()-1,1).upcase
     sec_last_char = uval.slice(uval.length()-2,1)

     vals = params[:id].split(":")
     if !vals.length == 2||!(vals[1].upcase == "A"||vals[1].upcase == "B"||vals[1].upcase == "FRONT"||vals[1].upcase == "BACK")||vals[0].to_i == 0
      flash[:notice]= "You must enter the drop code(number) followed by ':' followed by the drop side code('A' or 'B' or 'FRONT' or 'BACK')"
     @freeze_flash = true
        render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>

      },:layout => "tree_node_content"
      session[:current_drop] = nil
      return

    end


    drop_code = vals[0].to_i
    side_code = vals[1].upcase

    #----------------------------------------------
    #Make sure drop is unique within line config
    #----------------------------------------------

    if Drop.exists_for_line_config(session[:current_line_config].id,drop_code)

     flash[:notice]= "You already have a drop with drop code: " +  session[:current_drop].drop_code
     @freeze_flash = true
        render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>

      },:layout => "tree_node_content"
      session[:current_drop] = nil
      return
    end

    session[:current_drop].drop_code = uval
    session[:current_drop].drop_side_code = side_code
    session[:current_drop].save
    flash[:notice]= "drop updated"
    @new_text = "drop_" + params[:id]
      render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>
        <% @tree_actions = render_edit_node_js(@new_text) %>


      },:layout => "tree_node_content"

  else
       render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>


      },:layout => "tree_node_content"

  end

 rescue
  handle_error("drop could not be updated")
 ensure
  session[:current_drop]= nil
 end

end



def edit_barcode
   begin
      id = params[:id].split("$")[1].to_i
      station = CartonPackStation.find(id)
      session[:current_station] = station
      @barcode = station.station_code
     render :inline => %{
     <script>
     val = prompt("edit barcode: <%= @barcode %>. IGNORE THE 'x'(do not enter it)");
     window.location.href = "/production/resources/barcode_edited/" + val;
     </script>
     }

    rescue
     handle_error("barcode edit failed",true)
    end

end


def add_pack_station

 # begin

      table = Table.find(params[:id].split("$")[1].to_i)
      @station = CartonPackStation.new
      code = CartonPackStation.next_id(table.id)

       #----------------------------------------------------------------------------
       #Kromco: station code is the table_caption (with 0 prepended if <= 9) +
       #        IF: the max station code for same table's last char is a 'A', then
       #               use: max station gen code for table + "B"
       #        ELSE:  use: next station en code + "A"
       #----------------------------------------------------------------------------
       puts "table id: " + table.id.to_s
       puts "gen code: " + (code - 1).to_s
       if code > 1
         last_stations = CartonPackStation.find_all_by_station_gen_code_and_table_id(code -1,table.id,:order => "station_code")
         if last_stations.length > 1
          last_station = last_stations[1]
         else
           last_station = last_stations[0]
         end
         last_char = last_station.station_code.slice(last_station.station_code.length() -1,1)
       else
         last_char = "B"

       end

      table_code = nil
      drop_code = ""
      if table.table_caption
        if table.table_caption <= 9
          table_code = "0" + table.table_caption.to_s
        else
          table_code = table.table_caption.to_s
        end
      else
         table_code = table.table_code.to_s
         drop_code = table.drop.drop_code.to_s
      end

      if last_char.upcase == "A" && CartonPackStation.is_alpha_numeric
        code = code -1
        barcode = "x" + drop_code + table_code + (code).to_s + "B"
      elsif last_char.upcase == "B" && CartonPackStation.is_alpha_numeric
        barcode = "x" + drop_code + table_code + (code).to_s + "A"
      else
        barcode = "x" + drop_code + table_code + (code).to_s
      end

      @station.station_code = barcode

      location = "x" + table.drop.drop_code.to_s  + table.table_code.to_s

      @station.station_gen_code = code
      @station.location = location
      @station.station_code = barcode

      if table.carton_pack_stations.push(@station)

       @node_name = @station.station_code.to_s
       @node_type = "pack_station"
       @node_id = table.id.to_s + "$" + @station.id.to_s
       @tree_name = "line_config"
        flash[:notice] = "station added"
        render :inline => %{
          <% @is_menu_loaded_view = true %>
          <% @hide_content_pane = true %>
          <% tree_code = render_add_node_js(@node_name,@node_type,@node_id,@tree_name) %>
          <% @tree_actions = tree_code %>
        },:layout => "tree_node_content"
     else
       raise @station.errors.full_messages.to_s
     end
   # rescue
    # handle_error("station could not be added to table",true)
    #end
end

def remove_pack_station
begin
   ids = params[:id].split("$")
   id = ids[1]
   parent_id = ids[0]
   station = CartonPackStation.find(id)
   table = Table.find(parent_id)

    if table.carton_pack_stations.delete(station)

     flash[:notice]= "pack station removed from table"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>

     },:layout => "tree_node_content"

    end

  rescue
   handle_error("pack station could not be removed from line config")
  end

end


#==========================================================================
#LINE CONFIGS CODE
#==========================================================================
def list_line_configs
	return if authorise_for_web(program_name?,'read') == false


	list_query = "@line_configs = LineConfig.find(:all)"
	session[:query] = list_query
	render_list_line_configs
end


def render_list_line_configs
	@can_edit = authorise(program_name?,'edit',session[:user_id])
	@can_delete = authorise(program_name?,'delete',session[:user_id])
	@line_configs =  eval(session[:query]) if !@line_configs
	render :inline => %{
      <% grid            = build_line_config_grid(@line_configs,@can_edit,@can_delete) %>
      <% grid.caption    = 'list of all line_configs' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@line_config_pages) if @line_config_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
end

def delete_line_config
  return if authorise_for_web(program_name?,'delete')== false
  begin
	if params[:page]
		session[:line_configs_page] = params['page']
		render_list_line_configs
		return
	end
	id = params[:id]
	if id && line_config = LineConfig.find(id)
		line_config.destroy
		session[:alert] = " Record deleted."
		render_list_line_configs
	end
   rescue
    handle_error("line config could not be deleted")
   end
end

def new_line_config
	return if authorise_for_web(program_name?,'create')== false
		render_new_line_config
end

def create_line_config
   begin
	 @line_config = LineConfig.new(params[:line_config])
	 if @line_config.save
         session[:current_line_config]= @line_config
		 render_line_config_tree(@line_config,@line_config.id)
	else
		@is_create_retry = true
		render_new_line_config
	 end
   rescue
     handle_error("line config could not be created")
   end
end

def render_new_line_config
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'create new line_config'"%>

		<%= build_line_config_form(@line_config,'create_line_config','next',false,@is_create_retry)%>

		}, :layout => 'content'
end

def edit_line_config
	return if authorise_for_web(program_name?,'edit')==false
	 if session[:changed_line_config_id]
	   id = session[:changed_line_config_id]
	   session[:changed_line_config_id] = nil
	 else
	  id = params[:id]
	 end

	 puts "in edit line config"
	 if id && @line_config = LineConfig.find(id)
	    session[:current_line_config] = @line_config
		render_line_config_tree(@line_config,@line_config.id)

	 end
end

def change_line_config_name
  id = params[:id]
  if request.get?
    @line_config = session[:current_line_config]

    render :inline => %{
      <% @tree_node_content_header = "Edit line config name" -%>
      <% @hide_content_pane = false %>
      <% @is_menu_loaded_view = true %>

      <%= build_line_config_form(@line_config,"change_line_config_name","save",true) %>

    },:layout => "tree_node_content"
  else
    @line_config = session[:current_line_config]

    if params[:line_config][:line_config_code].strip == ""
     render :inline => %{

        <% @hide_content_pane = true %>
        <% @is_menu_loaded_view = false %>

      },:layout => "tree_node_content"
      return

    else
      @line_config.update_attributes(params[:line_config])
      @new_text = @line_config.line_config_code
      flash[:notice]= "line config updated"
      render :inline => %{

        <% @hide_content_pane = true %>
        <% @is_menu_loaded_view = false %>
        <% @tree_actions = render_edit_node_js(@new_text) %>


      },:layout => "tree_node_content"

    end
  end


end



def render_edit_line_config
#	 render (inline) the edit template
	render :inline => %{
		<% @content_header_caption = "'edit line_config'"%>

		<%= build_line_config_form(@line_config,'update_line_config','update_line_config',true)%>

		}, :layout => 'content'
end

def update_line_config

	 id = params[:line_config][:id]
	 if id && @line_config = LineConfig.find(id)
		 if @line_config.update_attributes(params[:line_config])
			@line_configs = eval(session[:query])
			render_list_line_configs
	 else
			 render_edit_line_config

		 end
	 end
 end

 def render_line_config_tree(line_config,line_config_id)

     @line_config = line_config
     @line_config_id = line_config_id

     render :inline => %{

      <% @content_header_caption = "'configure template line: " + @line_config.line_config_code + "'" -%>

      <% @tree_script = build_line_config_tree(@line_config,@line_config_id) -%>


      },:layout => "tree"


 end
#====================================================================================
# FACILITIES CODE
#====================================================================================


#===============================
#PACKHOUSE CODE
#===============================

def edit_packhouse #only name can be edited currently
  begin
      id = params[:id]
      packhouse = Facility.find(id)
      session[:current_packhouse] = packhouse
      @name = packhouse.facility_code
     render :inline => %{
     <script>
     val = prompt("edit packhouse name: <%= @name %>.");
     window.location.href = "/production/resources/packhouse_edited/" + val;
     </script>
     }

    rescue
     handle_error("packhouse name edit failed",true)
    end


end

def packhouse_edited

 begin
  if params[:id].to_s != "null"

    session[:current_packhouse].facility_code = params[:id]
    session[:current_packhouse].save
    flash[:notice]= "packhouse name updated"
    @new_text = session[:current_packhouse].facility_code
      render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>
        <% @tree_actions = render_edit_node_js(@new_text) %>


      },:layout => "tree_node_content"

  else
       render :inline => %{

        <%@hide_content_pane = true %>
        <% @is_menu_loaded_view = true %>


      },:layout => "tree_node_content"

  end

 rescue
  handle_error("packhouse name could not be updated")
 ensure
  session[:current_packhouse]= nil
 end


end

def packhouse_added
   begin
      packouse_name = params[:id]
      if params[:id].to_s != "null"
        @packhouse = Facility.new
        type = FacilityType.find_by_facility_type_code("packhouse")
        org = session[:current_prim_manufacturer]
        session[:current_prim_manufacturer] = nil
        @packhouse.facility_type = type
        @packhouse.facility_type_code = "packhouse"
        @packhouse.organization = org
        @packhouse.facility_code = params[:id].to_s
        #add bintip station to current line config
        if @packhouse.save

          #@node_name,@node_type,@node_id,@tree_name
          @parent_id = "packhouses!root"
          @node_name = @packhouse.facility_code
          @node_type = "packhouse"
          @node_id =  @packhouse.id.to_s
          @tree_name = "facilities"
          flash[:notice] = "packhouse added"
          render :inline => %{
          <% @is_menu_loaded_view = true %>
          <% @hide_content_pane = true %>
          <% tree_code = render_add_node_to_parent_js(@parent_id,@node_name,@node_type,@node_id,@tree_name) %>
          <% tree_code += render_add_node_to_parent_js("packhouse!" + @node_id ,"lines","lines",@packhouse.id.to_s,"facilities") %>
          <% tree_code += render_add_node_to_parent_js("packhouse!" + @node_id ,"rebin label stations","rebin_label_stations","root","facilities") %>
          <% tree_code += render_add_node_to_parent_js("packhouse!" + @node_id ,"pallet label stations","pallet_label_stations","root","facilities") %>
          <% @tree_actions = tree_code %>
          },:layout => "tree_node_content"
        else
           raise @packhouse.errors.full_messages.to_s
        end
    else
       render :inline => %{
       <%@hide_content_pane = true %>
       <% @is_menu_loaded_view = true %>
        },:layout => "tree_node_content"

    end
  rescue
    handle_error("packhouse could not be added")

  end
end

def remove_packhouse
  begin
   id = params[:id]
   packhouse = Facility.find(id)
    if packhouse.destroy

     flash[:notice]= "packhouse deleted"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>

     },:layout => "tree_node_content"

    end

  rescue
   handle_error("packhouse facility could not be deleted ")
  end
 end

def add_packhouse
    begin
       org = Organization.get_all_by_role("PRIMARY_MANUFACTURER",true)[0]

       if org
         @msg = "Enter packhouse name(short description) for " + org.short_description
         session[:current_prim_manufacturer]= org

         render :inline => %{
        <script>
         val = prompt("<%= @msg %>.");
         window.location.href = "/production/resources/packhouse_added/" + val;
         </script>
        }
      else
         flash[:notice]= "Primary manufacturer not defined in database"
          render :inline => %{
           <% @freeze_flash = true %>
           <% @hide_content_pane = true %>
           <% @is_menu_loaded_view = true %>
           },:layout => "tree_node_content"

      end
    rescue
     handle_error("packhouse facility could not be added",true)
    end


end


 def define_facilities
  return if authorise_for_web('resources','read') == false

  render :inline => %{

  <% @content_header_caption = "'define facilities'" -%>

  <% @tree_script = build_facilities_tree -%>


  },:layout => "tree"




 end

 #============================================================================
 #LINE CODE
 #============================================================================

 def set_line_config

   begin

    if request.get?

      if LineConfig.count == 0
         @freeze_flash = true
         flash[:notice] = "No line configurations have been defined yet"
         render :inline => %{
          <% @hide_content_pane = true %>
          <% @is_menu_loaded_view = true %>
          },:layout => "tree_node_content"
        return
      end

      session[:current_line] = Line.find(params[:id].to_i)
      current_config = session[:current_line].line_config
      @config_header = ""
      @config_header = "(current config is: " + current_config.line_config_code + ")" if current_config
      render :inline => %{
       <% @tree_node_content_header = "set line configuration" + @config_header -%>
      <% @hide_content_pane = false %>
      <% @is_menu_loaded_view = true %>
      <%= build_set_line_config_form("set_line_config","set") %>

      },:layout => "tree_node_content"
    else

      line_config = LineConfig.find(params[:line_config][:line_config_code])
      line = session[:current_line]
      session[:current_line] = nil
      is_edit = line.line_config != nil
      old_node_id = "line_config!" + line.id.to_s + "$" + line.line_config.id.to_s if is_edit == true


      @del_code = ""
      line.line_config = line_config
      line.save

      flash[:notice] = "line config set for line"
      if is_edit
        #an edit actually requires a delete of existing node and addition of
        #new one, because the id of the node has changes, not merely it's text
        @del_code = "window.parent.RemoveNode('" + old_node_id + "');"


      end

       @parent_id = "line!" +  line.id.to_s
       @node_name = line.line_config.line_config_code
       @node_type = "line_config"
       @node_id = line.id.to_s + "$" + line.line_config.id.to_s
       @tree_name = "facilities"
        render :inline => %{
          <% @is_menu_loaded_view = false %>
          <% @hide_content_pane = true %>
          <% tree_code = render_add_node_to_parent_js(@parent_id,@node_name,@node_type,@node_id,@tree_name) %>
          <% @tree_actions = @del_code + tree_code  %>
          <% puts @tree_actions %>
        },:layout => "tree_node_content"

    end
    rescue
     handle_error("line config could not be set for line ",true)
    end



 end

 def edit_line(retry_edit = nil,line = nil)
  begin

    if request.get?||retry_edit

      if !line
       @line= Line.find(params[:id].to_i)
      else
       @line = line
      end

      render :inline => %{
       <% @tree_node_content_header = "Edit production line: " + @line.line_code -%>
      <% @hide_content_pane = false %>
      <% @is_menu_loaded_view = true %>
      <%= build_line_form(@line,"edit_line","save",true) %>

      },:layout => "tree_node_content"
    else

      if params[:line][:line_code].strip == ""
          @line = Line.find(params[:id].to_i)
          @line.line_code = params[:line][:line_code]
          @line.line_phc = params[:line][:line_phc]
          @line.is_dedicated = params[:line][:is_dedicated]
          @line.errors.add_to_base("line code cannot be empty")
          edit_line(true,@line)
        return
      end

      line_code = params[:line][:line_code]
      line_phc = params[:line][:line_phc]
      is_dedicated =  params[:line][:is_dedicated]
      @line = Line.find(params[:line][:id])
      @line.line_code = line_code
      @line.line_phc = line_phc
      @line.is_dedicated = is_dedicated
      @line.save
      @new_text = @line.line_code
      flash[:notice] = "line updated"

      #@node_name,@node_type,@node_id,@tree_name
        render :inline => %{

        <% @hide_content_pane = true %>
        <% @is_menu_loaded_view = false %>
        <% @tree_actions = render_edit_node_js(@new_text) %>


      },:layout => "tree_node_content"

    end
    rescue
     handle_error("production line could not be updated successfully",true)
    end


end

 def delete_line
  begin
   id = params[:id]
   line = Line.find(id)
   if line.destroy

     flash[:notice]= "line deleted"
     render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>
      <% @tree_actions = "window.parent.RemoveNode(null);" %>

     },:layout => "tree_node_content"

    end

  rescue
    @freeze_flash = true
    flash[:notice]= "Line could not be deleted. System reported the following exception<br>" + $!
    render :inline => %{
      <% @hide_content_pane = true %>
      <% @is_menu_loaded_view = true %>

     },:layout => "tree_node_content"

  end
 end

 def add_production_line(retry_add = nil)
  begin

    if request.get?||retry_add

      session[:current_packhouse_id] = params[:id].to_i
      render :inline => %{
       <% @tree_node_content_header = "Add production line" -%>
      <% @hide_content_pane = false %>
      <% @is_menu_loaded_view = true %>
      <%= build_line_form(@line,"add_production_line","add") %>

      },:layout => "tree_node_content"
    else

      if params[:line][:line_code].strip == ""
          @line = Line.new
          @line.line_code = params[:line][:line_code]
          @line.line_phc = params[:line][:line_phc]
          @line.is_dedicated = params[:line][:is_dedicated]
          @line.errors.add_to_base("line code cannot be empty")
          add_production_line(true)
        return
      end

      line_code = params[:line][:line_code]
      line_phc = params[:line][:line_phc]
      is_dedicated =  params[:line][:is_dedicated]
      @line = Line.new
      @line.facility_id = session[:current_packhouse_id]
      session[:current_packhouse_id]= nil
      @line.line_code = line_code
      @line.line_phc = line_phc
      @line.is_dedicated = is_dedicated
      @line.create

      #@node_name,@node_type,@node_id,@tree_name
       @parent_id = "lines!" +  @line.facility_id.to_s
       @node_name = @line.line_code
       @node_type = "line"
       @node_id = @line.id.to_s
       @tree_name = "facilities"
        flash[:notice] = "production line added"
        render :inline => %{
          <% @is_menu_loaded_view = false %>
          <% @hide_content_pane = true %>
          <% tree_code = render_add_node_to_parent_js(@parent_id,@node_name,@node_type,@node_id,@tree_name) %>
          <% @tree_actions = tree_code %>
        },:layout => "tree_node_content"

    end
    rescue
     handle_error("production line could not be added to packhouse",true)
    end


end





end
