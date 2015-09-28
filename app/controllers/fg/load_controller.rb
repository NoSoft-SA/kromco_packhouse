class Fg::LoadController < ApplicationController

  def program_name?
    "load"
  end

  def bypass_generic_security?
    true
  end

  def voyage
    load_voyage=LoadVoyage.find_by_load_id(params[:id])
    if load_voyage
      edit_voyage
    else
      link_to_voyage
    end
  end



  def reports_and_edis
    @load=Load.find(params[:id])
    render :inline => %{
          <% @content_header_caption = "'reports and edis'"%>
          <%= build_load_reports_form( @load,'','',false)%>
          }, :layout => 'content' and return
  end

  def edit_pallet
    id = params[:id].to_i
    @pallet = Pallet.find("#{id}")
    session[:pallet_id]= id
    render :inline => %{
		<% @content_header_caption = "'edit pallet'"%>

		<%= build_edit_pallet_form(@pallet,'update_pallet','update_pallet',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def update_pallet
    id = session[:pallet_id].to_i
    @pallet = Pallet.find("#{id}")
    @pallet.update_attributes({:remarks1, "#{params[:pallet][:remarks1]}",
                               :remarks2, "#{params[:pallet][:remarks2]}",
                               :remarks3, "#{params[:pallet][:remarks3]}",
                               :remarks4, "#{params[:pallet][:remarks4]}",
                               :remarks5, "#{params[:pallet][:remarks5]}"})
    if @pallet.save
      render :inline => %{<script>
                             alert('pallet edited');
                             window.opener.location.reload(true);
                             window.close();

                       </script>}

    end

  end

  def view_load_pallets2
    @load=Load.find(params[:id])
    set_active_doc("loads",params[:id])

    render :inline => %{
            <% @content_header_caption = "'#{@caption}'" %>
            <%= build_view_load_pallets_form(@load)%>

            }, :layout => 'content'
  end



  def view_load_pallets
    id = params[:id].to_i
    set_active_doc("loads",params[:id])
    load_status=Load.find(session[:active_doc]['loads']).load_status
    pallets_query="select pallets.*
                                    from pallets
                                    inner join load_details on pallets.load_detail_id=load_details.id
                                    inner join load_orders on load_details.load_order_id=load_orders.id
                                    inner join  loads on load_orders.load_id=loads.id
                  where loads.id=#{id}   "
    pallets = Pallet.find_by_sql(pallets_query)
    @pallets =[]
    oderz ={}
    if !pallets.empty?
      for o in pallets
        @pallets << o if !oderz.has_key?(o['pallet_number'])
        oderz[o['pallet_number']]=[o['pallet_number']]
      end
    end
    session[:load_pallets]=@pallets
    session[:query]=  "ActiveRecord::Base.connection.select_all(\"#{pallets_query}\")"

    session[:load_id] = id
    if !session[:current_viewing_order]
      if ( load_status.upcase =='SHIPPED' ||  load_status.upcase =='COMPLETED' )
        @multi_select=nil

      else
      @multi_select="deallocated_pallets"
        end
  else
    @multi_select=nil
  end


    render_view_pallets
  end

  def  edit_pallets_remarks
    id = params[:id].to_i
    set_active_doc("loads",params[:id])

    pallets = Pallet.find_by_sql("select pallets.*
                                    from pallets
                                    inner join load_details on pallets.load_detail_id=load_details.id
                                    inner join load_orders on load_details.load_order_id=load_orders.id
                                    inner join  loads on load_orders.load_id=loads.id
                                    where loads.id=#{id}   ")
    @pallets =[]
    oderz ={}
    if !pallets.empty?
      for o in pallets
        @pallets << o if !oderz.has_key?(o['pallet_number'])
        oderz[o['pallet_number']]=[o['pallet_number']]
      end
    end
    session[:load_pallets]=@pallets
    session[:query]= @pallets
    session[:load_id] = id
    @use_jq_grid = true
    if @use_jq_grid
      render :template => "fg/loads/edit_pallet_remarks", :layout => "content"
    else
    @pagination_server = "list_load_details"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:load_details_page]
    @current_page = params['page']||= session[:load_details_page]
    @pallets = eval(session[:query]) if !@pallets
    render :inline => %{
      <% grid            = build_edit_pallets_grid(@pallets) %>
      <% grid.caption    = "'Edit Pallet Remarks'" %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@order_pages) if @order_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
      end
  end

  def render_view_pallets
    @pagination_server = "list_load_details"
    @can_edit = authorise(program_name?, 'edit', session[:user_id])
    @can_delete = authorise(program_name?, 'delete', session[:user_id])
    @current_page = session[:load_details_page]
    @current_page = params['page']||= session[:load_details_page]
    @pallets = eval(session[:query]) if !@pallets

    @use_jq_grid = true
    if @use_jq_grid
      render :template => "fg/loads/list_load_pallets", :layout => "content"
    else
      render :inline => %{
  		<% @content_header_caption = "'pallets '"%>
  		<% grid = build_pallets_grid(@pallets ,@can_edit,@can_delete,@multi_select)%>
  		<% @header_content = grid.build_grid_style %>
  		<% @header_content += grid.build_grid_data %>

  		<% @pagination = pagination_links(@load_detail_pages) if @load_detail_pages != nil %>
  		<script>
  		<%= grid.render_grid %>
  		</script>
  	}, :layout => 'content'
    end
  end

  def update_edited_load_pallets

    remarks_edits = grid_edited_values_to_array(params)

    Pallet.transaction do
      remarks_edits.each do |remark_edit|
          pallet_id= remark_edit[:id]
          remark_edit.delete_if { |key, value| key == :id }
          remarks = remark_edit.map{|remark_name,value|
            if(value.to_s.strip.length > 0)
              "#{remark_name}='#{value}'"
            else
              "#{remark_name}=NULL"
            end
          }
          Pallet.update_all(ActiveRecord::Base.extend_set_sql_with_request(remarks.join(','),"pallets"),"id = '#{pallet_id}'")
         end

    end
   @load_id= session[:active_doc]['loads']
    render :inline => %{<script>
                                  //window.parent.location.href = '/fg/load/edit_pallets_remarks/<%=@load_id%>';
                                  window.parent.close();
                            </script>}
 end

  def reload_pallets_form
    view_load_pallets
  end

  def deallocated_pallets
    load_pallets = session[:load_pallets]
    selected_pallets = selected_records?(load_pallets, nil)
    load_id=session[:load_id]
    order=Order.find_by_sql("select orders.* from orders inner join load_orders on load_orders.order_id=orders.id where load_orders.load_id=#{load_id}")[0]
    pallet_numbers=selected_pallets.map { |l| "'#{l.pallet_number}'" }.join(",")
    ActiveRecord::Base.transaction do
      load_details=LoadDetail.find_by_sql("select load_details.* from load_details inner join pallets on pallets.load_detail_id=load_details.id where pallets.pallet_number in (#{pallet_numbers})")

      Pallet.find_by_sql(ActiveRecord::Base.extend_update_sql_with_request("UPDATE pallets SET target_market_code=orig_target_market_code, orig_target_market_code = null WHERE pallet_number in (#{pallet_numbers}) and orig_target_market_code is not null"))
      Pallet.find_by_sql(ActiveRecord::Base.extend_update_sql_with_request("UPDATE pallets SET load_detail_id = null,remarks1 = null,  remarks2 = null,  remarks3 = null,  remarks4 = null,  remarks5 = null WHERE pallet_number in (#{pallet_numbers})"))

      for load_detail in load_details
        li_pallets =Pallet.find_all_by_load_detail_id(load_detail.id)
        if li_pallets.empty?
          load_detail.destroy
        end
      end

      order_pallet_nums=Pallet.find_by_sql("select pallets.* from pallets
                                                         join load_details on (pallets.load_detail_id = load_details.id)
                                                         join loads on (loads.id = load_details.load_id)
                                                         join load_orders on (loads.id = load_orders.load_id)
                                                         where load_orders.order_id = '#{order.id}'").map { |p| p.pallet_number }
      if order_pallet_nums.empty?
        order.downgrade_orders([order])
      end
    end
    @order_id=order.id
    render :inline => %{<script>
                  alert('pallets deallocated');
                  window.parent.opener.frames[1].location.href = '/fg/order/edit_order/<%=@order_id.to_s%>';
                  window.parent.close();
          </script>}, :layout => "content"


  end

  def create_loads
    @order = session[:order]

    @load = @order.create_loads
    if @load.load_status == "LOAD_CREATED"
      set_active_doc("loads",@load.id)
      render :inline => %{
                        <script>
                        alert('LOAD_CREATED');
                          window.close();
                        window.opener.frames[1].location.reload(true);
                        </script>
                           }, :layout => 'content'
    else
      flash[:notice] = "Load_could not be created"
    end
  end

  def edit_voyage
    return if authorise_for_web(program_name?, 'edit')==false
    load=Load.find(params[:id])
    #@load_voyage=LoadVoyage.find_by_load_id(session[:active_load]['id'])
    order_id=LoadOrder.find_by_load_id(load.id).order_id
    list_query=("SELECT load_voyages.id,load_voyages.customer_reference,load_voyages.booking_reference,load_voyages.exporter_certificate_code ,load_voyages.shipping_line_party_id,
              load_voyages.shipping_agent_party_role_id,load_voyages.shipper_party_role_id,load_voyages.exporter_party_role_id,voyages.voyage_code,load_voyages.memo_pad
                ,load_voyages.voyage_id
                    FROM loads
                    inner join  load_orders on load_orders.load_id=loads.id
                    left join load_voyages on load_voyages.load_id=loads.id
                    left join parties_roles as parties_sl on load_voyages.shipping_line_party_id=parties_sl.id
                    left join parties_roles as parties_sa on load_voyages.shipping_agent_party_role_id=parties_sa.id
                    left join parties_roles as parties_s on load_voyages.shipper_party_role_id=parties_s.id
                    left join parties_roles as parties_e on load_voyages.exporter_party_role_id=parties_e.id
                    left join voyages on load_voyages.voyage_id=voyages.id
                    where load_voyages.load_id =#{load.id}")
    @load_voyage=LoadVoyage.find_by_sql(list_query)[0]
    #pols=ActiveRecord::Base.connection.select_all("
    #select distinct ports.port_code,ports.id as pol_voyage_port_id
    # from voyage_ports
    # inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
    # inner join ports on voyage_ports.port_id=ports.id
    # inner join voyages on voyage_ports.voyage_id=voyages.id
    # inner join load_voyages on  load_voyages.voyage_id=voyages.id
    # inner join load_voyage_ports on load_voyage_ports.load_voyage_id=load_voyages.id
    # inner join loads on load_voyages.load_id=loads.id
    # inner join load_orders on load_orders.load_id=loads.id
    #where load_voyages.load_id=#{load.id}  and  voyage_port_types.voyage_port_type_code='Departure'  ")

    pols=ActiveRecord::Base.connection.select_all("select ports.port_code,ports.id as pol_voyage_port_id,load_voyages.id,load_orders.load_id,voyage_ports.port_id from voyage_ports
    inner join load_voyage_ports on  load_voyage_ports.voyage_port_id=voyage_ports.id
    inner join load_voyages on load_voyage_ports.load_voyage_id=load_voyages.id
    inner join load_orders on load_voyages.load_id=load_orders.load_id
    inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
    inner join ports on voyage_ports.port_id=ports.id
    where load_orders.load_id=#{load.id} and  voyage_port_types.voyage_port_type_code='Departure'")

    if !pols.empty?
      pol_voyage_port_id=pols[0]['pol_voyage_port_id']
      @load_voyage['pol_voyage_port_id']=pol_voyage_port_id
    else
      @load_voyage['pol_voyage_port_id']=nil
    end

    #pods=ActiveRecord::Base.connection.select_all("
    #    select distinct ports.port_code,ports.id as pod_voyage_port_id
    #         from voyage_ports
    #         inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
    #         inner join ports on voyage_ports.port_id=ports.id
    #         inner join voyages on voyage_ports.voyage_id=voyages.id
    #         inner join load_voyages on  load_voyages.voyage_id=voyages.id
    #         inner join load_voyage_ports on load_voyage_ports.load_voyage_id=load_voyages.id
    #         inner join loads on load_voyages.load_id=loads.id
    #         inner join load_orders on load_orders.load_id=loads.id
    #    where load_voyages.load_id=#{load.id}  and  voyage_port_types.voyage_port_type_code='Arrival' ")
    #      if !pods.empty?
    #        pod_voyage_port_id=pods[0]['pod_voyage_port_id']
    #        @load_voyage['pod_voyage_port_id']=pod_voyage_port_id
    #      else
    #        @load_voyage['pod_voyage_port_id']=nil
    #      end
    #----------------------------------
    pods=ActiveRecord::Base.connection.select_all("select ports.port_code,ports.id as pod_voyage_port_id,load_voyages.id,load_orders.load_id,voyage_ports.port_id from voyage_ports
          inner join load_voyage_ports on  load_voyage_ports.voyage_port_id=voyage_ports.id
          inner join load_voyages on load_voyage_ports.load_voyage_id=load_voyages.id
          inner join load_orders on load_voyages.load_id=load_orders.load_id
          inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
          inner join ports on voyage_ports.port_id=ports.id
          where load_orders.load_id=#{load.id} and voyage_port_types.voyage_port_type_code='Arrival'")
    if !pods.empty?
      pod_voyage_port_id=pods[0]['pod_voyage_port_id']
      @load_voyage['pod_voyage_port_id']=pod_voyage_port_id
    else
      @load_voyage['pod_voyage_port_id']=nil
    end
    #==========================================

    session[:active_load_voyage]=@load_voyage
    session[:active_load]=load
    session[:active_order_id]=order_id
    render_edit_load_load_voyage

  end

  def render_edit_load_load_voyage

    render :inline => %{
  		<% @content_header_caption = "'edit load_voyage'"%>

  		<%= build_load_voyage_form(@load_voyage,'update_load_load_voyage','update_load_voyage',true,true)%>

  		}, :layout => 'content'
  end

  def update_load_load_voyage


    ActiveRecord::Base.transaction do
      @load_id= session[:active_load].id
      load_voyage=session[:active_load_voyage]
      if  params[:load_voyage]['voyage_code']=="" || params[:load_voyage]['shipping_line_party_id']== "" ||params[:load_voyage]['shipping_agent_party_role_id']== "" || params[:load_voyage]['shipper_party_role_id']== "" || params[:load_voyage]['exporter_party_role_id']== "" || params[:load_voyage]['pol_voyage_port_id']== "" || params[:load_voyage]['pod_voyage_port_id']== ""
        flash[:error]= "shipping line,shipping agent,shipper and exporter are required "
        redirect_to :controller => 'fg/load', :action => 'edit_voyage', :id => @load_id and return


      end

      voyage=Voyage.find_by_voyage_code(params[:load_voyage]['voyage_code'].to_s)
      if load_voyage.voyage_id.to_i == voyage.id.to_i
        voyage=voyage
      else
        voyage=Voyage.find_by_voyage_code(params[:load_voyage]['voyage_code'].to_s)
      end

      old_v_port= VoyagePort.find_by_port_id_and_voyage_id(load_voyage.pol_voyage_port_id, load_voyage.voyage_id)
      voyage_port=VoyagePort.find_by_port_id_and_voyage_id(params[:load_voyage]['pol_voyage_port_id'], voyage.id)

      if old_v_port.id.to_s==voyage_port.id.to_s
      else
        old_v_port= old_v_port
        voyage_port= voyage_port
        load_voyage_port1=LoadVoyagePort.find_by_sql("select * from load_voyage_ports where load_voyage_id=#{load_voyage.id} and voyage_port_id=#{old_v_port.id}")[0]
        load_voyage_port1.load_voyage_id = load_voyage.id
        load_voyage_port1.voyage_port_id = voyage_port.id
        load_voyage_port1.update
      end

      old_v2_port= VoyagePort.find_by_port_id_and_voyage_id(load_voyage.pod_voyage_port_id, load_voyage.voyage_id)
      pod_voyage_port=VoyagePort.find_by_port_id_and_voyage_id(params[:load_voyage]['pod_voyage_port_id'], voyage.id)
      if  old_v2_port.id.to_s==pod_voyage_port.id.to_s
      else
        old_v2_port = old_v2_port
        pod_voyage_port = pod_voyage_port
        load_voyage_port=LoadVoyagePort.find_by_sql("select * from load_voyage_ports where load_voyage_id=#{load_voyage.id} and voyage_port_id=#{old_v2_port.id}")[0]
        load_voyage_port.load_voyage_id = load_voyage.id
        load_voyage_port.voyage_port_id = pod_voyage_port.id
        load_voyage_port.update
      end

      #----------------------------------------------------------------------------------------------------
      lvoyage_fields=[]
      params[:load_voyage].delete("pol_voyage_port_id")
      params[:load_voyage].delete("pod_voyage_port_id")
      params[:load_voyage].delete("voyage_code")

      for attr in params[:load_voyage]
        if attr[1]==nil || attr[1]=="" || attr[1]== ""
        else
          if attr[1].is_a?(Numeric)
            lvoyage_fields << attr[0] + "= " + attr[1].to_s
          else
            lvoyage_fields << attr[0] + "= " + "'#{attr[1]}'"
          end
        end

      end
      lvoyage_fields=lvoyage_fields.join(",")
      begin
        @order_id=session[:active_order_id]
        id = params[:load_voyage][:id]
        if id && @load_voyage = LoadVoyage.find(id)
          if  ActiveRecord::Base.connection.execute("update load_voyages set #{lvoyage_fields},voyage_id=#{voyage.id} where id=#{id}")

            flash[:notice] = 'record saved'

            render :inline => %{<script>
                  alert('load voyage edited');
               window.opener.frames[1].location.reload(true);
                    window.close();
            </script>}

          else
            render_edit_load_load_voyage

          end
        end
      rescue
        handle_error('record could not be saved')
      end
    end
  end

  def link_to_voyage
    load=Load.find(params[:id])
    order_id=LoadOrder.find_by_load_id(load.id).order_id
    session[:active_order_id]=order_id
    session[:active_load]=load
    return if authorise_for_web(program_name?, 'create')== false
    render_new_load_voyage
  end

  def render_new_load_voyage

    render :inline => %{
              <% @content_header_caption = "'create new load_voyage'"%>

              <%= build_load_voyage_form(@load_voyage,'create_load_voyage','create_load_voyage',false,@is_create_retry)%>

              }, :layout => 'content'
  end


  def create_load_voyage

    @load_id =session[:active_load].id
    @order_id=session[:active_order_id]
    if params[:load_voyage]['voyage_code']==nil || params[:load_voyage]['voyage_code']=="" || params[:load_voyage]['shipping_line_party_id']== "" ||params[:load_voyage]['shipping_agent_party_role_id']== "" || params[:load_voyage]['shipper_party_role_id']== "" || params[:load_voyage]['exporter_party_role_id']== "" || params[:load_voyage]['pol_voyage_port_id']== "" || params[:load_voyage]['pod_voyage_port_id']== ""
      flash[:error]= "voyage_code,shipping line,shipping agent,shipper and exporter are required"
      redirect_to :controller => 'fg/load', :action => 'link_to_voyage', :id => @load_id and return

    end
    begin
      @load_voyage_port = LoadVoyagePort.new

      voyage=Voyage.find_by_voyage_code(params[:load_voyage]['voyage_code'].to_s)
      @load_voyage = LoadVoyage.new
      @load_voyage.customer_reference=params[:load_voyage]['customer_reference']
      @load_voyage.exporter_certificate_code=params[:load_voyage]['exporter_certificate_code']
      @load_voyage.shipping_line_party_id=params[:load_voyage]['shipping_line_party_id']
      @load_voyage.shipping_agent_party_role_id=params[:load_voyage]['shipping_agent_party_role_id']
      @load_voyage.shipper_party_role_id =params[:load_voyage]['shipper_party_role_id']
      @load_voyage.exporter_party_role_id=params[:load_voyage]['exporter_party_role_id']
      @load_voyage.memo_pad= params[:load_voyage]['memo_pad']
      @load_voyage.booking_reference=params[:load_voyage]['booking_reference']
      @load_voyage.voyage_id = voyage.id
      @load_voyage.load_id = session[:active_load].id
      @load_voyage.save

      pol_voyage_port=VoyagePort.find_by_port_id_and_voyage_id(params[:load_voyage]['pol_voyage_port_id'], voyage.id)
      @load_voyage_port = LoadVoyagePort.new
      @load_voyage_port.load_voyage_id = @load_voyage.id
      @load_voyage_port.voyage_port_id = pol_voyage_port.id
      @load_voyage_port.save


      pod_voyage_port=VoyagePort.find_by_port_id_and_voyage_id(params[:load_voyage]['pod_voyage_port_id'], voyage.id)
      @load_voyage_port = LoadVoyagePort.new
      @load_voyage_port.load_voyage_id = @load_voyage.id
      @load_voyage_port.voyage_port_id = pod_voyage_port.id
      if  @load_voyage_port.save
        render :inline => %{<script>
                             alert('load voyage created');
                              window.opener.frames[1].location.reload(true);
                              window.close();
                              </script>}
      else
        params[:id]=session[:active_load].id
        link_to_voyage
      end
    rescue
      handle_error('record could not be created')
    end
  end


  def lookup_pol
    voyage_code = params[:id]
    voyage_id =Voyage.find_by_voyage_code(params[:id]).id
    @voyage_ports = VoyagePort.find_by_sql("SELECT distinct voyage_ports.id,ports.port_code,port_id FROM voyage_ports inner join ports on voyage_ports.port_id=ports.id where voyage_ports.voyage_id='#{voyage_id}'").map { |g| [g.port_code, g.id] }

    pols =VoyagePort.find_by_sql("select distinct ports.port_code,ports.id
            from voyage_ports
            inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
            inner join ports on voyage_ports.port_id=ports.id
            inner join voyages on voyage_ports.voyage_id=voyages.id
            where (voyage_ports.voyage_id=#{voyage_id} and  voyage_port_types.voyage_port_type_code='Departure' and (voyages.status ='active' or voyages.status IS NULL))")

    @pols =pols.map { |g| [g.port_code, g.id] }
    @pols.unshift("") if !@pols.empty?
    @pods =VoyagePort.find_by_sql("select distinct ports.port_code,ports.id
            from voyage_ports
            inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
            inner join ports on voyage_ports.port_id=ports.id
            inner join voyages on voyage_ports.voyage_id=voyages.id
            where (voyage_ports.voyage_id=#{voyage_id} and voyage_port_types.voyage_port_type_code='Arrival' and (voyages.status ='active' or voyages.status IS NULL))").map { |g| [g.port_code, g.id] } #and voyage_ports.is_destination_port IS TRUE)
    @pods.unshift("") if !@pods.empty?

    #option_text={}
    #option_values={}
    #  difau=[]
    #for opt in @pols
    #   if  opt== ""
    #      options['text']= opt
    #       option_values['value']=opt
    #   else
    #     if  opt[1]==@pols[0][1]
    #       difau << opt[1]
    #       option_values['value'] =  opt[1]
    #       option_text['text'] = opt[0]
    #      else
    #       option_values['value']  =opt[1]
    #       option_text['text']  = opt[0]
    #      end
    #   end
    #end

    render :inline => %{
  		  <script>

        var pol = window.opener.document.getElementById('pol_voyage_port_id_cell');
        var old_pol = pol.childNodes[0];

        var new_pol = document.createElement("select");
        new_pol.setAttribute('name','load_voyage[pol_voyage_port_id]');
        <% for opt in @pols%>
          var the_option = document.createElement("option");
            <% if  opt== "" %>
                  the_option.value = "<%= opt   %>";
                  the_option.text = "<%= opt %>";
               <% else %>
             <% if  opt[1]==@pols[0][1] %>
                   the_option.selected=true;
                  the_option.value = "<%= opt[1]   %>";
                  the_option.text = "<%= opt[0] %>";
                <% else %>
                 the_option.value = "<%= opt[1] %>";
                 the_option.text = "<%= opt[0] %>";
               <% end %>
            <% end %>

          new_pol.add(the_option , null);
        <% end %>

          pol.replaceChild(new_pol,old_pol);


        var pod = window.opener.document.getElementById('pod_voyage_port_id_cell');
        var old_pod = pod.childNodes[0];

        var new_pod = document.createElement("select");
        new_pod.setAttribute('name','load_voyage[pod_voyage_port_id]');
        <% for optn in  @pods%>
          var the_option = document.createElement("option");
         <% if  optn== "" %>
            the_option.value = "<%= optn   %>";
             the_option.text = "<%= optn %>";
            <% else %>
              <% if  optn[1]==@pods[0][1] %>
                     the_option.selected=true;
                     the_option.value = "<%= optn[1] %>";
                     the_option.text = "<%= optn[0] %>";
               <% else %>
                       the_option.value = "<%= optn[1] %>";
                       the_option.text = "<%= optn[0] %>";
               <% end %>
           <% end %>
          new_pod.add(the_option , null);
         <% end %>

          pod.replaceChild(new_pod,old_pod);


  window.close();
  </script>

  		}, :layout => 'content'
  end


  def edit_load_voyage
    return if authorise_for_web(program_name?, 'edit_load_container') == false
    load_id = params[:id]
    order_id = LoadOrder.find_by_sql("SELECT order_id from load_orders WHERE load_id = '#{ load_id }'")
    @order_id = Order.find("#{order_id[0].attributes['order_id']}").id
    @load_voyage =LoadVoyage.find_by_load_id(load_id)
    session[:load_voyage]= @load_voyage
    session[:load_id] =load_id
    if !@load_voyage
      render :inline => %{
                          <script>
                           alert( "There is no load_container for this load");
                           window.close();
                            </script>
                            } and return
    end
    render :inline => %{
          <% @content_header_caption = "'edit load voyage'"%>
          <%= build_edit_booking_ref_form( @load_voyage,'confirm_edit_voyage','update_voyage',true)%>
          }, :layout => 'content' and return
  end

  def confirm_edit_voyage
    session[:load_voyage].update_attributes_state(params[:load_voyage])
    @load_id =session[:load_id]
    changed = session[:load_voyage].changed_fields?
    changed_msg = build_changed_field_msg(changed)

    if changed_msg == "" || changed_msg== nil
      flash[:error]= "You did not change anything"

      render :inline => %{<script>
                                  window.location.href = '/fg/load/edit_load_voyage/<%=@load_id%>';
                </script>} and return
    else
      update_voyage
    end
  end

  def update_voyage
    begin
      ActiveRecord::Base.transaction do
        session[:load_voyage].update_attributes!({:booking_reference => params[:load_voyage]['booking_reference']})
      end
    rescue

      @error = build_error_div($!.to_s)
      render :inline => %{<%= @error %>}, :layout => 'content'and return

    end
    flash[:notice] = 'record saved'
    render :inline => %{<script>
                                  alert('booking reference edited');
                                  window.close();
                            </script>} and return
  end


  def edit_vehicle
    return if authorise_for_web(program_name?, 'edit') == false
    load_id = params[:id]
    order_id = LoadOrder.find_by_sql("SELECT order_id from load_orders WHERE load_id = '#{ load_id }'")
    @order_id = Order.find("#{order_id[0].attributes['order_id']}").id
    @load_vehicle =LoadVehicle.find_by_load_id(load_id)
    if !@load_vehicle
      render :inline => %{
                              <script>
                               alert( "There is no vehicle for this load");
                               window.close();
                                </script>
                                } and return
    end
    for param in @load_vehicle.attributes
      if param[0]=='haulier_party_id'
        if param[1]==nil || param[1]==""
        else
          haulier =PartiesRole.find(param[1].to_i).party_name
          @load_vehicle['haulier']=haulier
        end
      end
    end
    session[:load_vehicle]= @load_vehicle
    session[:load_id]=load_id

    render :inline => %{
          <% @content_header_caption = "'edit vehicle'"%>
          <%= build_edit_vehicle_form( @load_vehicle,'confirm_edit_vehicle','update_vehicle',true)%>
          }, :layout => 'content' and return

  end

  def confirm_edit_vehicle
    for param in params[:load_vehicle]
      if param[0]=='haulier'
        if param[0]=="" || param[0]==nil
        else
          haulier_id =PartiesRole.find_by_sql("select id from parties_roles where party_name='#{param[1]}'")[0]['id']
          params[:load_vehicle]['haulier_party_id']=haulier_id
        end
      end
    end
    session[:load_vehicle].update_attributes_state(params[:load_vehicle])
    @load_id =session[:load_id]
    changed = session[:load_vehicle].changed_fields?
    changed_msg = build_changed_field_msg(changed)

    if changed_msg == "" || changed_msg== nil
      flash[:error]= "You did not change anything"

      render :inline => %{<script>
                                  //window.location.href = '/fg/load/edit_vehicle/<%=@load_id%>';
               window.opener.frames[1].frames[1].location.reload(true);

                </script>} and return
    else
      update_vehicle
    end
  end

  def update_vehicle
    begin
      ActiveRecord::Base.transaction do
        session[:load_vehicle].update_attributes!({:vehicle_number => params[:load_vehicle]['vehicle_number'], :haulier_party_id => params[:load_vehicle]['haulier_party_id']})
      end
    rescue

      @error = build_error_div($!.to_s)
      render :inline => %{<%= @error %>}, :layout => 'content'and return

    end
    flash[:notice] = 'record saved'
    render :inline => %{<script>
                                  alert('vehicle successfully edited!');
                                  window.close();
                            </script>} and return
  end


  def edit_container
    return if authorise_for_web(program_name?, 'edit') == false
    load_id = params[:id]
    order_id = LoadOrder.find_by_sql("SELECT order_id from load_orders WHERE load_id = '#{ load_id }'")
    @order_id = Order.find("#{order_id[0].attributes['order_id']}").id
    session[:load_id]= load_id
    @load_container =LoadContainer.find_by_load_id(load_id)
    if @load_container
      session[:load_container_id] = @load_container.id
      session[:load_container_before_state] = @load_container.to_map_str
      session[:load_container] = @load_container

    else
      render :inline => %{
                          <script>
                           alert( "There is no load_container for this load");
                           window.close();
                            </script>
                            } and return
    end

    render :inline => %{
          <% @content_header_caption = "'edit container'"%>
          <%= build_edit_container_form(@load_container,'update_container','update_container',true)%>
          }, :layout => 'content'
  end

  def update_container
    session[:load_container].update_attributes_state(params[:load_container])
    confirm_change
  end

  def confirm_change
    changed = session[:load_container].changed_fields?
    changed_msg = build_changed_field_msg(changed)
    @load_id =session[:load_id]

    if changed_msg == "" || changed_msg== nil
      flash[:error]= "You did not change anything"
      redirect_to :controller => 'fg/load', :action => 'edit_container', :id => @load_id and return


    end
    @msg = "Are you sure you want to change the following  " + changed_msg


    render :inline => %{
   <script>
     if (confirm("<%=@msg%>") == true)
        {window.location.href = "/fg/load/update_container_confirmed";}
     else
       {window.location.href = "/fg/load/update_container_cancelled";}
  </script>
    } and return
  end

  def update_container_confirmed


    begin
      ActiveRecord::Base.transaction do
        if  session[:load_container_id] != nil
          @load_container = LoadContainer.find(session[:load_container_id])
          @load_container.update_attributes!({
                                                 :container_code => session[:load_container]['container_code'],
                                                 :container_seal_code => session[:load_container]['container_seal_code'],
                                                 :container_temperature_rhine => session[:load_container]['container_temperature_rhine'],
                                                 :container_temperature_rhine2 => session[:load_container]['container_temperature_rhine2'],
                                                 :cto_consec_code => session[:load_container]['cto_consec_code'],
                                                 :stack_type_code => session[:load_container]['stack_type_code']
                                             })
        end

        after_state_of_container =@load_container.to_map_str
        load_vehicle_change_logs = LoadVehicleChangeLog.new
        load_vehicle_change_logs.load_container_id=@load_container.id if @load_container
        load_vehicle_change_logs.user_name =session[:user_id].user_name
        load_vehicle_change_logs.created_on =Time.now
        load_vehicle_change_logs.before_state =session[:load_container_before_state]
        load_vehicle_change_logs.after_state =after_state_of_container
        load_vehicle_change_logs.save
      end
    rescue

      @error = build_error_div($!.to_s)
      render :inline => %{<%= @error %>}, :layout => 'content'and return
    end
    flash[:notice] = 'record saved'
    render :inline => %{<script>
                                  alert('container edited');
                                  window.close();
                            </script>}
  end

  def update_container_cancelled
    session[:load_container] = nil
    session[:load_id] = nil
    session[:load_container_id] = nil
    session[:load_container_before_state] = nil
    render :inline => %{<script>
                              alert('EDITING CONTAINER CANCELLED');
                              window.close();
                            </script>}
  end

  def print_pick_list
    load_id = params[:id]
    load_order_id = LoadOrder.find_by_sql("SELECT id FROM load_orders WHERE load_id = '#{load_id}'")
    load_order_id = load_order_id[0]['id']
    report_unit ="reportUnit=/reports/MES/FG/pick_slip&"
    report_parameters="output=pdf&load_order_id=" +"#{load_order_id}"
    redirect_to_path(Globals.get_jasper_server_report_server_ip + Globals.get_jasper_server + report_unit +Globals.get_jasperserver_username_password + report_parameters)
  end


  def complete_load
    return if authorise_for_web(program_name?, 'complete_load')== false

    id = params[:id].to_i

    @load = Load.find(id)
    order_id = LoadOrder.find_by_sql("SELECT order_id from load_orders WHERE load_id = '#{ @load.id}'")
    @order = Order.find("#{order_id[0].attributes['order_id']}")
    @order_id = @order.id

    message = @load.complete_load
    if message == nil
      render :inline => %{
                                  <script>
                                   alert('Load completed');
                                   window.opener.location.href = '/fg/load/render_loads/<%= @order_id.to_s%>';
                                   window.close();
                                  </script>
                                    }, :layout => 'content'
    else

      flash[:error]= message
      render :inline => %{
                          <script>
                            window.opener.location.href = '/fg/load/render_loads/<%= @order_id.to_s%>';
                           window.close();
                          </script>
                            } and return
    end


  end

  def choose_container
    render :inline => %{
		<% @content_header_caption = "'create new load'"%>

		<%= build_choose_container_form(@load,'create_container','create_container',false,@is_create_retry)%>

		}, :layout => 'content'

  end

  def load_status
    load_id = params[:id]

    @load_status_histories =TransactionStatus.find_by_sql("select transaction_statuses.*,loads.load_number
              from transaction_statuses
              join loads on loads.id =transaction_statuses.object_id
              WHERE object_id=#{load_id} and status_type_code='loads' ORDER BY transaction_statuses.created_on")
    render :inline => %{
      <% grid            = build_load_status_histories_grid(@load_status_histories) %>
      <% grid.caption    = 'load_status_histories' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@load_status_histories_pages) if @load_status_histories_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end


  def update_load_voyage

    @load_voyage = LoadVoyage.find_by_load_id(session['load_id'])

    if @load_voyage.update_attributes(params[:load_voyage])
      #@load_voyages = eval(session[:query])

      flash[:notice] = 'record saved'
      render :inline => "<script>window.close()</script>", :layout => 'content'
    else
      flash[:notice] = 'record not saved'
    end
  end

  def choose_voyage

    session['load_id'] = params[:id]
    if @load_voyage = LoadVoyage.find_by_load_id(params[:id])
      render :inline => %{
          <% @content_header_caption = "'select load_voyage'"%>
          <%= build_load_voyage_form(@load_voyage,'update_load_voyage','update_load_voyage',true,@is_create_retry)%>
          }, :layout => 'content'
    else
      render :inline => %{
          <% @content_header_caption = "'select load_voyage'"%>
          <%= build_choose_voyage_form(@load_voyage,'selected_voyage','selected_voyage',false,@is_create_retry)%>
          }, :layout => 'content'
    end

  end

  def selected_voyage

    if params[:voyage][:voyage_id] == ""
      render :inline => "<script>history.back()</script>"
    else
      voyage_number = params[:voyage][:voyage_id]
      if voyage_number == nil
      else
        @load_voyage = LoadVoyage.new
        @load_voyage.load_id = session['load_id']
        @load_voyage.voyage_id = voyage_number
        @load_voyage.save!

        session['load_voyage_id'] = @load_voyage.id
        render :inline => %{
            <% @content_header_caption = "'select load_voyage'"%>
            <%= build_load_voyage_form(@load_voyage,'update_load_voyage','update_load_voyage',true,@is_create_retry)%>
            }, :layout => 'content'

      end
    end
  end

  def loads
    id = params[:id]
    session['order_id'] = id
    render_loads
  end

  def render_loads
    order_id = params[:id].to_i
    session[:order_id] = order_id

    @content_header_caption = "'manage loads'"
    render :inline => %{
		<%= build_loads_form(@load,'','',true) %> }, :layout => 'content'
  end

  def list_loads

    order_id = params[:id].to_i

    return if authorise_for_web(program_name?, 'read') == false

    if order_id
      #list_query = "SELECT loads.* FROM loads, load_orders WHERE (public.loads.id = public.load_orders.load_id) AND (public.load_orders.order_id = '#{order_id.to_s}')"

      list_query=("SELECT load_orders.id as pick_list_number,voyages.voyage_code,loads.* ,load_voyages.customer_reference,load_voyages.booking_reference,load_voyages.exporter_certificate_code ,load_voyages.customer_reference,load_voyages.booking_reference,load_voyages.exporter_certificate_code ,
      parties_sl.party_name as shipping_line,parties_sa.party_name as shipping_agent,parties_s.party_name as shipper,parties_e.party_name as exporter,load_voyages.memo_pad
      FROM loads
      inner join  load_orders on load_orders.load_id=loads.id
      left join load_voyages on load_voyages.load_id=loads.id
      left join parties_roles as parties_sl on load_voyages.shipping_line_party_id=parties_sl.id
      left join parties_roles as parties_sa on load_voyages.shipping_agent_party_role_id=parties_sa.id
      left join parties_roles as parties_s on load_voyages.shipper_party_role_id=parties_s.id
      left join voyages on load_voyages.voyage_id=voyages.id
      left join parties_roles as parties_e on load_voyages.exporter_party_role_id=parties_e.id
      where load_orders.order_id =#{order_id}")
      loads=ActiveRecord::Base.connection.select_all(list_query)
      if !loads.empty?
        #pols=ActiveRecord::Base.connection.select_all("
        #   select distinct ports.port_code,ports.id as pol_voyage_port_id,load_voyages.id,load_voyages.load_id
        #   from voyage_ports
        #   inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
        #   inner join ports on voyage_ports.port_id=ports.id
        #   inner join voyages on voyage_ports.voyage_id=voyages.id
        #   inner join load_voyages on  load_voyages.voyage_id=voyages.id
        #   inner join load_voyage_ports on load_voyage_ports.load_voyage_id=load_voyages.id
        #   inner join loads on load_voyages.load_id=loads.id
        #   inner join load_orders on load_orders.load_id=loads.id
        #    where (load_orders.order_id =#{order_id} and voyage_port_types.voyage_port_type_code='Departure' )
        #     order by load_voyages.id desc ")

        pols=ActiveRecord::Base.connection.select_all("select ports.port_code,ports.id as pol_voyage_port_id,load_voyages.id,load_orders.load_id,voyage_ports.port_id from voyage_ports
              inner join load_voyage_ports on  load_voyage_ports.voyage_port_id=voyage_ports.id
              inner join load_voyages on load_voyage_ports.load_voyage_id=load_voyages.id
              inner join load_orders on load_voyages.load_id=load_orders.load_id
              inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
              inner join ports on voyage_ports.port_id=ports.id
              where load_orders.order_id=#{order_id} and voyage_port_types.voyage_port_type_code='Departure'")


        if !pols.empty?
          for ld in loads
            pol=pols.find_all { |p| p.load_id.to_i==ld['id'].to_i }
            if !pol.empty?
              pol=pol[0]['port_code']
              ld['pol']=pol
            else
              ld['pol']=nil
            end
          end
        end

        #pods=ActiveRecord::Base.connection.select_all("select distinct ports.port_code,ports.id as pod_voyage_port_id,load_voyages.id,load_orders.load_id
        #           from voyage_ports
        #           inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
        #           inner join ports on voyage_ports.port_id=ports.id
        #           inner join voyages on voyage_ports.voyage_id=voyages.id
        #           inner join load_voyages on  load_voyages.voyage_id=voyages.id
        #           inner join loads on load_voyages.load_id=loads.id
        #           inner join load_voyage_ports on load_voyage_ports.load_voyage_id=load_voyages.id
        #           inner join load_orders on load_orders.load_id=loads.id
        #      where (load_orders.order_id =#{order_id} and voyage_port_types.voyage_port_type_code='Arrival' )
        #     order by load_voyages.id desc")

        pods=ActiveRecord::Base.connection.select_all("select ports.port_code,ports.id as pod_voyage_port_id,load_voyages.id,load_orders.load_id,voyage_ports.port_id from voyage_ports
      inner join load_voyage_ports on  load_voyage_ports.voyage_port_id=voyage_ports.id
      inner join load_voyages on load_voyage_ports.load_voyage_id=load_voyages.id
      inner join load_orders on load_voyages.load_id=load_orders.load_id
      inner join voyage_port_types on voyage_ports.voyage_port_type_id=voyage_port_types.id
      inner join ports on voyage_ports.port_id=ports.id
      where load_orders.order_id=#{order_id} and voyage_port_types.voyage_port_type_code='Arrival'")
        for lod in loads
          pod=pods.find_all { |p| p.load_id.to_i==lod['id'].to_i }
          if !pod.empty?
            pod=pod[0]['port_code']
            lod['pod']=pod
          else
            lod['pod']=nil
          end
        end

        #if !pods.empty?
        #  pod=pods[0]['port_code']
        #  loads[0]['pod']=pod
        #else
        #    loads[0]['pod']=nil
        #end

        @loads =[]
        oderz ={}
        if !loads.empty?
          for o in loads
            @loads << o if !oderz.has_key?(o['id'])
            oderz[o['id']]=[o['id']]
          end
        end
      else
        @loads=[]
      end

    end

    session[:order_id]= order_id
    #session[:query]   = list_query
    render_list_loads
  end

  def render_list_loads
    order_id = session[:order_id].to_i
    order_number = Order.find(order_id).order_number
    if !@loads.empty?
      load_number = @loads[0]['load_number']
    end


    render :inline => %{
      <% grid            = build_load_grid(@loads,@can_edit,@can_delete) %>
      <% grid.caption    = 'loads' %>
      <% @header_content = grid.build_grid_data %>

      <% @pagination = pagination_links(@load_pages) if @load_pages != nil %>
      <%= grid.render_html %>
      <%= grid.render_grid %>
      }, :layout => 'content'
  end

  def search_loads_flat
    return if authorise_for_web(program_name?, 'read')== false
    @is_flat_search = true
    render_load_search_form
  end

  def render_load_search_form(is_flat_search = nil)
    session[:is_flat_search] = @is_flat_search
#	 render (inline) the search form
    render :inline => %{
		<% @content_header_caption = "'search  loads'"%>

		<%= build_load_search_form(nil,'submit_loads_search','submit_loads_search',@is_flat_search)%>

		}, :layout => 'content'
  end

  def submit_loads_search
    @loads = dynamic_search(params[:load], 'loads', 'Load')

    if @loads.length == 0
      flash[:notice] = 'no records were found for the query'
      @is_flat_search = session[:is_flat_search].to_s
      render_load_search_form
    else
      render_list_loads
    end
  end


  def delete_load
    return if authorise_for_web(program_name?, 'delete')== false
    load = Load.find(params[:id])
    @load_order = LoadOrder.find_by_load_id(load.id)
    if get_load_pallets(@load_order.id).to_i > 0
      render :inline => %{
           <script>
           alert('load cannot be deleted, pallets are allocated');
           window.close();
           </script>
              }, :layout => 'content' and return
    end
    load.destroy
    render :inline => %{<script>
        window.opener.location.href = '/fg/order/edit_order/<%= @load_order.order_id.to_s%>';
        window.close();
      </script>}, :layout => "content"

  end

  def get_load_pallets(load_order_id)
    pallets =Pallet.find_by_sql("select  count(pallets.*) as pallets
                                     from pallets
                                     inner join load_details on pallets.load_detail_id=load_details.id
                                     inner join load_orders on load_details.load_order_id=load_orders.id
                                     inner join  loads on load_orders.load_id=loads.id
                                    where pallets.load_detail_id IS NOT NULL and load_details.load_order_id=#{load_order_id} ")[0]['pallets']
  end

  def new_load
    return if authorise_for_web(program_name?, 'create')== false
    render_new_load
  end

  def render_new_load
#	 render (inline) the edit template
    render :inline => %{
		<% @content_header_caption = "'create new load'"%>

		<%= build_load_form(@load,'create_load','create_load',false,@is_create_retry)%>

		}, :layout => 'content'
  end

  def edit_load
    return if authorise_for_web(program_name?, 'edit')==false
    id = params[:id]
    if id && @load = Load.find(id)
      render_edit_load
    end
  end


  def render_edit_load
    id = params[:id].to_i
    @load = Load.find(id)
    session[:load_id] = id
    load_number = @load.load_number

    render :inline => %{
		<% @content_header_caption = "'edit load' + '  ' + '#{load_number}'"%>

		<%= build_edit_load_form(@load,'update_load','ok',true)%>

		}, :layout => 'content'
  end

  def update_load

    load_id = session[:load_id].to_i
    required_quantity = params[:load][:required_quantity].to_i
    @load = Load.find("#{load_id}")

    @load_order = LoadOrder.find_by_sql("SELECT * from load_orders WHERE load_id = '#{@load.id}'")
    @load_order = @load_order[0]
    total_required_quantity = @load.required_quantity

    if required_quantity <total_required_quantity
      flash[:error]="Require an amount equal or more than the stored quantity"
      redirect_to :controller => 'fg/load', :action => 'render_edit_load', :id => @load.id and return

    else
      @load.update_attribute(:required_quantity, "#{required_quantity}")

    end

    render :inline => %{<script>
                             window.close();
                             alert('load edited');
                              window.opener.location.reload(true);
                              </script>}
  end

  def build_error_div(validations_error)
    valication_error_container = "
        <table id='validation_error_container' border='0' style='background: whitesmoke;font-family: verdana;font-size: 12px;border-collapse: collapse;width: 100%;height: 100px;width: 500px;border: red solid 2px;'>
          <tr style='font-weight: bold;color: white;height: 25px;background: #CC3333;'>
            <td> 1 error prohibited this record from being saved</td>
          </tr>
          <tr style='height: 10px;'>
            <td>&nbsp;&nbsp;&nbsp;The record could not be saved because:</td>
          </tr>
          <tr style='height: 75px;'>
            <td style='padding-left: 50px;'>
              <li>#{validations_error}</li>
            </td>
          </tr>
        </table>
        <script>
          flash = document.getElementById('validation_error_container').parentNode;
          flash.style.border = 'none';
          flash.style.background = 'white';
        </script>
      "
  end

end
